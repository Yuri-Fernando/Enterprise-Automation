"""Composite 'service' status check.

For this local/demo scope, a "service" is modeled as a local process bound
to a TCP port (see demo_incident.py for a fully runnable example: a
`python -m http.server` process listening on a port). This mirrors how a
real systemd/Windows service would be checked (process alive + port
listening) without requiring an actual OS service to be installed.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from automation.troubleshooting.health_check import check_port, is_process_running


def check_service_status(
    service_name: str,
    host: str = "127.0.0.1",
    port: Optional[int] = None,
    process_name: Optional[str] = None,
    pid: Optional[int] = None,
    timeout: float = 1.0,
) -> dict:
    """Return the status ("up"/"down") of a simulated local service,
    evaluated from its process liveness and/or listening port."""
    port_open = check_port(host=host, port=port, timeout=timeout) if port is not None else None
    process_running = (
        is_process_running(name_contains=process_name, pid=pid)
        if (process_name is not None or pid is not None)
        else None
    )

    checks = [c for c in (port_open, process_running) if c is not None]
    is_up = bool(checks) and all(checks)

    return {
        "service_name": service_name,
        "host": host,
        "port": port,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "port_open": port_open,
        "process_name": process_name,
        "process_running": process_running,
        "status": "up" if is_up else "down",
    }
