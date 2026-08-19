"""Tests for automation.troubleshooting.network_check."""
from __future__ import annotations

import socket

from automation.troubleshooting import network_check as nc
from automation.troubleshooting.health_check import find_free_port


def test_resolve_dns_literal_ip_is_true():
    assert nc.resolve_dns("127.0.0.1") is True


def test_resolve_dns_localhost_is_true():
    assert nc.resolve_dns("localhost") is True


def test_resolve_dns_invalid_host_is_false():
    assert nc.resolve_dns("this-host-does-not-exist.invalid", timeout=1.0) is False


def test_check_connectivity_open_port():
    port = find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        result = nc.check_connectivity("127.0.0.1", port, timeout=1.0)
        assert result["dns_resolved"] is True
        assert result["port_open"] is True
    finally:
        server.close()


def test_check_connectivity_closed_port():
    port = find_free_port()
    result = nc.check_connectivity("127.0.0.1", port, timeout=0.5)
    assert result["port_open"] is False


def test_check_connectivity_without_resolve():
    port = find_free_port()
    result = nc.check_connectivity("127.0.0.1", port, timeout=0.5, resolve=False)
    assert result["dns_resolved"] is None
