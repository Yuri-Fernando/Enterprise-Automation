"""Basic network connectivity checks: DNS resolution and TCP port
reachability, both with short/configurable timeouts so a check never hangs
the caller (CLI, health checks, self-healing demo)."""
from __future__ import annotations

import socket
from datetime import datetime, timezone

from automation.troubleshooting.health_check import check_port


def resolve_dns(hostname: str, timeout: float = 2.0) -> bool:
    """Return True if `hostname` resolves to an IP address within timeout.

    An already-resolved literal IP (e.g. "127.0.0.1") also resolves True.
    """
    old_timeout = socket.getdefaulttimeout()
    socket.setdefaulttimeout(timeout)
    try:
        socket.gethostbyname(hostname)
        return True
    except socket.gaierror:
        return False
    finally:
        socket.setdefaulttimeout(old_timeout)


def check_connectivity(host: str, port: int, timeout: float = 2.0, resolve: bool = True) -> dict:
    """Check DNS resolution (optional) and TCP port reachability for
    host:port, with a short timeout so the check stays fast."""
    result = {
        "host": host,
        "port": port,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "dns_resolved": None,
        "port_open": None,
    }
    if resolve:
        result["dns_resolved"] = resolve_dns(host, timeout=timeout)
    result["port_open"] = check_port(host=host, port=port, timeout=timeout)
    return result
