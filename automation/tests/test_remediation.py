"""Tests for automation.troubleshooting.remediation."""
from __future__ import annotations

import sys

from automation.troubleshooting.health_check import check_port, find_free_port
from automation.troubleshooting.remediation import (
    decide_remediation,
    restart_local_process,
    run_ansible_playbook,
    run_powershell_script,
)


def test_decide_remediation_restart_when_process_down():
    assert decide_remediation({"process_running": False, "port_open": True}) == "restart_local_process"


def test_decide_remediation_restart_when_port_closed():
    assert decide_remediation({"process_running": True, "port_open": False}) == "restart_local_process"


def test_decide_remediation_no_action_when_healthy():
    assert decide_remediation({"process_running": True, "port_open": True}) == "no_action"


def test_decide_remediation_no_action_when_unknown():
    assert decide_remediation({}) == "no_action"


def test_restart_local_process_starts_http_server_and_recovers():
    port = find_free_port()
    start_command = [sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"]

    result = restart_local_process(
        start_command=start_command,
        port=port,
        host="127.0.0.1",
        wait_seconds=8.0,
        poll_interval=0.1,
    )
    process = result.pop("process")
    try:
        assert result["success"] is True
        assert check_port("127.0.0.1", port, timeout=1.0) is True
        assert result["recovery_time_seconds"] >= 0
    finally:
        process.kill()
        process.wait(timeout=5)


def test_run_ansible_playbook_missing_binary_returns_error_not_raise():
    # ansible-playbook is not expected to be on PATH on this Windows dev box;
    # the important contract is "never raises", regardless of environment.
    result = run_ansible_playbook("nonexistent-playbook.yml")
    assert result["success"] is False
    assert "error" in result or result["returncode"] is not None


def test_run_powershell_script_missing_script_returns_error_not_raise():
    result = run_powershell_script("this-script-does-not-exist.ps1")
    assert result["success"] is False
