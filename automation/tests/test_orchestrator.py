"""Tests for automation.orchestrator (the self-healing incident flow).

Uses a real local `python -m http.server` process as the "service" so the
full detect -> diagnose -> remediate -> validate flow runs end-to-end
without any external infrastructure, mirroring escopo.md's Incident #017
narrative (nginx down -> restart -> HTTP 200 -> RESOLVED).
"""
from __future__ import annotations

import socket
import sys

from automation.orchestrator import run_self_healing
from automation.troubleshooting.health_check import find_free_port


def test_self_healing_already_healthy_short_circuits():
    port = find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        incident = run_self_healing(host="127.0.0.1", port=port, environment="dev")
        assert incident["status"] == "RESOLVED"
        assert incident["action"].startswith("no_action")
        assert incident["recovery_time_seconds"] == 0
    finally:
        server.close()


def test_self_healing_restarts_down_service_and_resolves():
    port = find_free_port()  # nothing listening yet -- service is "down"
    start_command = [sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"]

    incident = run_self_healing(
        host="127.0.0.1",
        port=port,
        environment="dev",
        problem="nginx unavailable",
        remediation="local_process",
        start_command=start_command,
        wait_seconds=8.0,
    )

    process = incident["remediation_result"].get("pid")
    try:
        assert incident["status"] == "RESOLVED"
        assert incident["root_cause"] in ("process stopped", "port unreachable / service not listening")
        assert incident["action"].startswith("restart local process")
        assert incident["recovery_time_seconds"] >= 0
        assert incident["problem"] == "nginx unavailable"
        assert incident["host"] == "127.0.0.1"
        assert incident["environment"] == "dev"
    finally:
        if process:
            import psutil

            try:
                psutil.Process(process).kill()
            except psutil.NoSuchProcess:
                pass


def test_self_healing_ansible_requires_playbook_path():
    port = find_free_port()
    try:
        run_self_healing(
            host="127.0.0.1",
            port=port,
            environment="dev",
            remediation="ansible",
        )
    except ValueError as exc:
        assert "playbook_path" in str(exc)
    else:
        raise AssertionError("expected ValueError when playbook_path is missing")
