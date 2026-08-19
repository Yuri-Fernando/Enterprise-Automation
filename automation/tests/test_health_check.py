"""Tests for automation.troubleshooting.health_check."""
from __future__ import annotations

import os
import socket
import sys

from automation.troubleshooting import health_check as hc


def test_find_free_port_returns_bindable_port():
    port = hc.find_free_port()
    assert isinstance(port, int)
    assert 0 < port < 65536


def test_check_port_true_when_listening():
    port = hc.find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        assert hc.check_port("127.0.0.1", port, timeout=1.0) is True
    finally:
        server.close()


def test_check_port_false_when_closed():
    port = hc.find_free_port()  # bound then released -- nothing listening
    assert hc.check_port("127.0.0.1", port, timeout=0.5) is False


def test_is_process_running_by_pid_current_process():
    assert hc.is_process_running(pid=os.getpid()) is True


def test_is_process_running_unknown_pid_is_false():
    # A PID astronomically unlikely to exist.
    assert hc.is_process_running(pid=999_999) is False


def test_is_process_running_by_name_python_current_interpreter():
    # The current interpreter process should match its own executable name.
    exe_name = os.path.basename(sys.executable).lower().replace(".exe", "")
    assert hc.is_process_running(name_contains=exe_name) is True


def test_is_process_running_requires_pid_or_name():
    try:
        hc.is_process_running()
    except ValueError:
        pass
    else:
        raise AssertionError("expected ValueError when neither pid nor name_contains is provided")


def test_run_health_check_no_checks_requested_is_none():
    result = hc.run_health_check(host="127.0.0.1")
    assert result["healthy"] is None
    assert result["port_open"] is None
    assert result["process_running"] is None


def test_run_health_check_healthy_when_port_open_and_process_alive():
    port = hc.find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        result = hc.run_health_check(host="127.0.0.1", port=port, pid=os.getpid())
        assert result["healthy"] is True
        assert result["port_open"] is True
        assert result["process_running"] is True
    finally:
        server.close()


def test_run_health_check_unhealthy_when_port_closed():
    port = hc.find_free_port()
    result = hc.run_health_check(host="127.0.0.1", port=port, timeout=0.5)
    assert result["healthy"] is False
    assert result["port_open"] is False
