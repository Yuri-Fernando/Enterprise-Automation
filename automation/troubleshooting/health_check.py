"""Local health checks: TCP port reachability and process liveness.

Used by the self-healing demo (see demo_incident.py) and by the
`health-check` subcommand of the Automation Controller CLI
(automation/cli/controller.py). No AWS or network calls are made here --
these are pure local OS-level checks (socket + psutil).
"""
from __future__ import annotations

import socket
from datetime import datetime, timezone
from typing import Optional

try:
    import psutil
except ImportError:  # pragma: no cover - psutil is a declared runtime dependency
    psutil = None


def check_port(host: str = "127.0.0.1", port: int = 80, timeout: float = 1.0) -> bool:
    """Return True if a TCP connection to host:port succeeds within timeout."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        result = sock.connect_ex((host, port))
        return result == 0
    finally:
        sock.close()


def find_free_port(host: str = "127.0.0.1") -> int:
    """Ask the OS for a free TCP port (bind to port 0) and return it."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind((host, 0))
        return sock.getsockname()[1]


def _process_alive(pid: int) -> bool:
    try:
        proc = psutil.Process(pid)
        return proc.status() != psutil.STATUS_ZOMBIE
    except psutil.NoSuchProcess:
        return False


def is_process_running(name_contains: Optional[str] = None, pid: Optional[int] = None) -> bool:
    """Return True if a process matching `pid`, or whose name/cmdline
    contains `name_contains` (case-insensitive), is currently running.

    Provide at least one of `pid` or `name_contains`.
    """
    if psutil is None:
        raise RuntimeError("psutil is required for process checks. Install with: pip install psutil")

    if pid is not None:
        return psutil.pid_exists(pid) and _process_alive(pid)

    if not name_contains:
        raise ValueError("Provide either pid or name_contains")

    needle = name_contains.lower()
    for proc in psutil.process_iter(["pid", "name", "cmdline"]):
        try:
            info = proc.info
            name = (info.get("name") or "").lower()
            cmdline = " ".join(info.get("cmdline") or []).lower()
            if needle in name or needle in cmdline:
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
    return False


def run_health_check(
    host: str = "127.0.0.1",
    port: Optional[int] = None,
    process_name: Optional[str] = None,
    pid: Optional[int] = None,
    timeout: float = 1.0,
) -> dict:
    """Run a composite health check (port and/or process) and return a
    normalized result dict.

    `healthy` is True only if every requested check passed, False if any
    failed, or None if no checks were requested (nothing to evaluate).
    """
    result = {
        "host": host,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "port": port,
        "port_open": None,
        "process_name": process_name,
        "pid": pid,
        "process_running": None,
        "healthy": None,
    }

    checks = []
    if port is not None:
        result["port_open"] = check_port(host=host, port=port, timeout=timeout)
        checks.append(result["port_open"])
    if process_name is not None or pid is not None:
        result["process_running"] = is_process_running(name_contains=process_name, pid=pid)
        checks.append(result["process_running"])

    result["healthy"] = all(checks) if checks else None
    return result
