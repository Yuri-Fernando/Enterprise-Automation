"""Incident/execution report generation.

Renders a normalized incident dict (the same field contract used by the
`incidents` table in database/schema.sql: host, environment, problem,
root_cause, action, validation, recovery_time_seconds, status, created_at)
into Markdown and JSON, and can pull incidents from MySQL when the DB is
reachable.

Two data sources are supported:

1. In-memory dict (or list of dicts) -- used by the orchestrator and by unit
   tests, no DB required.
2. MySQL via `mysql-connector-python` -- used by the CLI `report` command
   when the operator wants a report for an incident already persisted in
   the database. If the driver is not installed, or the DB is unreachable,
   a clear (non-crashing) error is raised as `DatabaseUnavailableError` so
   callers (CLI) can show a friendly message instead of a traceback.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

try:
    import mysql.connector  # type: ignore
    from mysql.connector import Error as MySQLError  # type: ignore
except ImportError:  # pragma: no cover - driver is optional
    mysql = None  # type: ignore
    MySQLError = Exception  # type: ignore


INCIDENT_FIELDS = (
    "id",
    "host",
    "environment",
    "problem",
    "root_cause",
    "action",
    "validation",
    "recovery_time_seconds",
    "status",
    "created_at",
    "resolved_at",
)


class DatabaseUnavailableError(RuntimeError):
    """Raised when the MySQL backend cannot be reached (driver missing,
    connection refused, credentials missing, etc.). Callers should show
    this message to the operator instead of a raw traceback."""


@dataclass
class DBConfig:
    host: str = field(default_factory=lambda: os.environ.get("MYSQL_HOST", "127.0.0.1"))
    port: int = field(default_factory=lambda: int(os.environ.get("MYSQL_PORT", "3306")))
    user: str = field(default_factory=lambda: os.environ.get("MYSQL_USER", "automation_app"))
    password: str = field(default_factory=lambda: os.environ.get("MYSQL_PASSWORD", ""))
    database: str = field(default_factory=lambda: os.environ.get("MYSQL_DATABASE", "caterpillar_automation"))


def normalize_incident(data: Dict[str, Any]) -> Dict[str, Any]:
    """Fill in any missing fields from the `incidents` table contract with
    None/defaults so templates never KeyError on a partial dict."""
    normalized = {key: data.get(key) for key in INCIDENT_FIELDS}
    if normalized.get("created_at") is None:
        normalized["created_at"] = datetime.now(timezone.utc).isoformat()
    if normalized.get("status") is None:
        normalized["status"] = "OPEN"
    return normalized


def render_incident_markdown(data: Dict[str, Any]) -> str:
    """Render a single incident dict as Markdown, matching the format used
    in escopo.md's "Incident #017" example."""
    incident = normalize_incident(data)
    incident_id = incident.get("id")
    title = f"Incident #{incident_id}" if incident_id is not None else "Incident"

    lines = [
        f"# {title}",
        "",
        f"- **Host:** {incident['host']}",
        f"- **Environment:** {incident['environment']}",
        f"- **Problem:** {incident['problem']}",
        f"- **Root cause:** {incident['root_cause'] or '_not diagnosed_'}",
        f"- **Action:** {incident['action'] or '_no remediation executed_'}",
        f"- **Validation:** {incident['validation'] or '_not validated_'}",
    ]
    if incident["recovery_time_seconds"] is not None:
        lines.append(f"- **Recovery time:** {incident['recovery_time_seconds']}s")
    lines.append(f"- **Status:** {incident['status']}")
    lines.append(f"- **Created at:** {incident['created_at']}")
    if incident.get("resolved_at"):
        lines.append(f"- **Resolved at:** {incident['resolved_at']}")
    lines.append("")
    return "\n".join(lines)


def render_incident_json(data: Dict[str, Any]) -> str:
    """Render a single incident dict as pretty-printed JSON."""
    return json.dumps(normalize_incident(data), indent=2, default=str, ensure_ascii=False)


def render_incidents_summary_markdown(incidents: List[Dict[str, Any]]) -> str:
    """Render a Markdown table summarizing multiple incidents (used by the
    `report` CLI command when listing recent incidents)."""
    if not incidents:
        return "# Incident Report\n\nNo incidents found.\n"

    header = "| ID | Host | Environment | Problem | Status | Recovery (s) | Created at |"
    sep = "|----|------|-------------|---------|--------|---------------|------------|"
    rows = [header, sep]
    for raw in incidents:
        incident = normalize_incident(raw)
        rows.append(
            "| {id} | {host} | {environment} | {problem} | {status} | {recovery} | {created_at} |".format(
                id=incident.get("id", "-"),
                host=incident["host"],
                environment=incident["environment"],
                problem=incident["problem"],
                status=incident["status"],
                recovery=incident["recovery_time_seconds"] if incident["recovery_time_seconds"] is not None else "-",
                created_at=incident["created_at"],
            )
        )
    return "# Incident Report\n\n" + "\n".join(rows) + "\n"


def save_report(content: str, path: str) -> str:
    """Write `content` to `path`, creating parent directories if needed.
    Returns the path written (convenience for CLI callers)."""
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)
    return path


def _get_connection(config: Optional[DBConfig] = None):
    if mysql is None:
        raise DatabaseUnavailableError(
            "mysql-connector-python não está instalado. Instale com: "
            "pip install mysql-connector-python (ou use um relatório a partir de um dict em memória)."
        )
    cfg = config or DBConfig()
    try:
        return mysql.connector.connect(
            host=cfg.host,
            port=cfg.port,
            user=cfg.user,
            password=cfg.password,
            database=cfg.database,
            connection_timeout=5,
        )
    except MySQLError as exc:
        raise DatabaseUnavailableError(f"Não foi possível conectar ao MySQL ({cfg.host}:{cfg.port}): {exc}") from exc


def fetch_incident_by_id(incident_id: int, config: Optional[DBConfig] = None) -> Dict[str, Any]:
    """Fetch a single incident by id from MySQL. Raises
    `DatabaseUnavailableError` if the DB/driver is unavailable, or
    `LookupError` if no incident matches the id."""
    connection = _get_connection(config)
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM incidents WHERE id = %s", (incident_id,))
        row = cursor.fetchone()
        cursor.close()
    finally:
        connection.close()

    if row is None:
        raise LookupError(f"Incident #{incident_id} não encontrado")
    return row


def fetch_recent_incidents(limit: int = 10, config: Optional[DBConfig] = None) -> List[Dict[str, Any]]:
    """Fetch the `limit` most recent incidents from MySQL, newest first.
    Raises `DatabaseUnavailableError` if the DB/driver is unavailable."""
    connection = _get_connection(config)
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM incidents ORDER BY created_at DESC LIMIT %s", (limit,))
        rows = cursor.fetchall()
        cursor.close()
    finally:
        connection.close()
    return rows


def insert_incident(data: Dict[str, Any], config: Optional[DBConfig] = None) -> int:
    """Insert an incident dict into MySQL and return the new row id. Raises
    `DatabaseUnavailableError` if the DB/driver is unavailable."""
    incident = normalize_incident(data)
    connection = _get_connection(config)
    try:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO incidents
                (host, environment, problem, root_cause, action, validation,
                 recovery_time_seconds, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                incident["host"],
                incident["environment"],
                incident["problem"],
                incident["root_cause"],
                incident["action"],
                incident["validation"],
                incident["recovery_time_seconds"],
                incident["status"],
            ),
        )
        connection.commit()
        new_id = cursor.lastrowid
        cursor.close()
    finally:
        connection.close()
    return new_id
