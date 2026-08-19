"""Tests for automation.troubleshooting.service_check."""
from __future__ import annotations

import os
import socket

from automation.troubleshooting.health_check import find_free_port
from automation.troubleshooting.service_check import check_service_status


def test_service_up_when_port_and_process_ok():
    port = find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        result = check_service_status("demo-svc", host="127.0.0.1", port=port, pid=os.getpid())
        assert result["status"] == "up"
        assert result["port_open"] is True
        assert result["process_running"] is True
    finally:
        server.close()


def test_service_down_when_port_closed():
    port = find_free_port()
    result = check_service_status("demo-svc", host="127.0.0.1", port=port, timeout=0.5)
    assert result["status"] == "down"
    assert result["port_open"] is False


def test_service_down_when_no_checks_requested():
    result = check_service_status("demo-svc", host="127.0.0.1")
    assert result["status"] == "down"
    assert result["port_open"] is None
    assert result["process_running"] is None
