"""Tests for automation.reports.incident_report -- in-memory dict path only
(no MySQL required). DB-backed functions are tested for their "unavailable"
fallback contract."""
from __future__ import annotations

import json
import os

import pytest

from automation.reports.incident_report import (
    DatabaseUnavailableError,
    fetch_incident_by_id,
    normalize_incident,
    render_incident_json,
    render_incident_markdown,
    render_incidents_summary_markdown,
    save_report,
)

SAMPLE_INCIDENT = {
    "id": 17,
    "host": "linux-web-02",
    "environment": "dev",
    "problem": "nginx unavailable",
    "root_cause": "service stopped",
    "action": "restart via Ansible",
    "validation": "HTTP 200",
    "recovery_time_seconds": 13,
    "status": "RESOLVED",
    "created_at": "2026-08-19T12:00:00+00:00",
}


def test_normalize_incident_fills_missing_fields():
    normalized = normalize_incident({"host": "h1", "environment": "dev", "problem": "x"})
    assert normalized["status"] == "OPEN"
    assert normalized["created_at"] is not None
    assert normalized["root_cause"] is None


def test_render_incident_markdown_matches_escopo_example():
    rendered = render_incident_markdown(SAMPLE_INCIDENT)
    assert "# Incident #17" in rendered
    assert "linux-web-02" in rendered
    assert "nginx unavailable" in rendered
    assert "service stopped" in rendered
    assert "restart via Ansible" in rendered
    assert "HTTP 200" in rendered
    assert "13s" in rendered
    assert "RESOLVED" in rendered


def test_render_incident_json_round_trips():
    rendered = render_incident_json(SAMPLE_INCIDENT)
    parsed = json.loads(rendered)
    assert parsed["host"] == "linux-web-02"
    assert parsed["status"] == "RESOLVED"


def test_render_incidents_summary_markdown_empty():
    rendered = render_incidents_summary_markdown([])
    assert "No incidents found" in rendered


def test_render_incidents_summary_markdown_table():
    rendered = render_incidents_summary_markdown([SAMPLE_INCIDENT])
    assert "| ID | Host |" in rendered
    assert "linux-web-02" in rendered


def test_save_report_writes_file(tmp_path):
    target = tmp_path / "nested" / "incident-17.md"
    content = render_incident_markdown(SAMPLE_INCIDENT)
    saved_path = save_report(content, str(target))
    assert os.path.exists(saved_path)
    with open(saved_path, "r", encoding="utf-8") as handle:
        assert "Incident #17" in handle.read()


def test_fetch_incident_by_id_raises_database_unavailable_without_driver_or_server():
    # mysql-connector-python is not installed in this environment, and even
    # if it were, no MySQL server is reachable at 127.0.0.1:3306 in CI/tests
    # -- either way this must raise a clean DatabaseUnavailableError, never
    # crash with an unhandled exception.
    with pytest.raises(DatabaseUnavailableError):
        fetch_incident_by_id(1)
