"""Tests for automation.metrics.exporter.

Starts a real HTTP server (no mocking of the exporter's own logic) bound to
an OS-assigned free port, and makes real HTTP GET requests against it —
mirroring the existing pattern in automation/tests/test_orchestrator.py
(real local server/process instead of mocks).
"""
from __future__ import annotations

import threading
import urllib.error
import urllib.request

import pytest

from automation.metrics.exporter import build_registry, collect_dataset, run_server
from automation.troubleshooting.health_check import find_free_port
from prometheus_client import generate_latest


@pytest.fixture()
def exporter_server():
    port = find_free_port()
    server = run_server(host="127.0.0.1", port=port)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{port}"
    finally:
        server.shutdown()
        thread.join(timeout=5)


def _get(url: str) -> tuple[int, str]:
    with urllib.request.urlopen(url, timeout=5) as response:
        return response.status, response.read().decode("utf-8")


def test_collect_dataset_falls_back_to_demo_json_without_mysql():
    incidents, executions, used_mysql = collect_dataset()
    assert used_mysql is False  # no MySQL running in the test environment
    assert len(incidents) == 5
    assert len(executions) == 5


def test_build_registry_exposes_expected_metric_families():
    registry = build_registry()
    text = generate_latest(registry).decode("utf-8")

    assert "automation_incidents_total" in text
    assert 'automation_incidents_total{status="RESOLVED"} 4.0' in text
    assert 'automation_incidents_total{status="OPEN"} 1.0' in text
    assert "automation_executions_total" in text
    assert "automation_mttr_seconds 44.25" in text
    assert "automation_slo_availability_ratio 0.8" in text
    assert "automation_data_source 0.0" in text  # demo JSON, not MySQL


def test_healthz_endpoint(exporter_server):
    status, body = _get(f"{exporter_server}/healthz")
    assert status == 200
    assert body == "ok"


def test_ready_endpoint(exporter_server):
    status, body = _get(f"{exporter_server}/ready")
    assert status == 200
    assert body == "ready"


def test_metrics_endpoint_serves_prometheus_text_format(exporter_server):
    status, body = _get(f"{exporter_server}/metrics")
    assert status == 200
    assert "automation_incidents_total" in body
    assert "automation_mttr_seconds" in body


def test_unknown_path_returns_404(exporter_server):
    with pytest.raises(urllib.error.HTTPError) as exc_info:
        urllib.request.urlopen(f"{exporter_server}/nope", timeout=5)
    assert exc_info.value.code == 404


import urllib.error  # noqa: E402 (used only in the 404 test above)
