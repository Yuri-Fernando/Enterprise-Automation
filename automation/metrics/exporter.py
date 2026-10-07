"""Prometheus metrics HTTP exporter for the Automation Controller.

Exposes `/metrics` (Prometheus text exposition format), `/healthz` and
`/ready` on a single port, so the same binary that already backs
`helm/automation-controller/templates/deployment.yaml` (which probes
`/healthz`/`/ready` on port 8080 but, until this change, had no process
actually serving them) can run as a real container.

Data source (same graceful-fallback pattern as database/ and dashboard/):
  1. MySQL, via automation/reports/incident_report.py, when
     MYSQL_HOST/MYSQL_USER/... env vars point at a reachable database
     (see database/docker-compose.yml).
  2. dashboard/js/data.example.json (demo mode) otherwise — the same file
     the static dashboard already falls back to when there is no backend.

Metrics exposed:
  - automation_incidents_total{status}            Gauge
  - automation_executions_total{tool,status}       Gauge
  - automation_mttr_seconds                        Gauge (see slo_report.py)
  - automation_slo_availability_ratio               Gauge
  - automation_slo_error_budget_remaining_ratio     Gauge
  - automation_data_source                          Gauge (1=mysql, 0=demo-json)

Run directly:
    python -m automation.metrics.exporter --port 8080

Or via the CLI:
    python -m automation.cli metrics-serve --port 8080
"""
from __future__ import annotations

import json
import logging
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Dict, List, Tuple

from prometheus_client import CollectorRegistry, Gauge, generate_latest, CONTENT_TYPE_LATEST

from automation.reports.incident_report import DatabaseUnavailableError, fetch_recent_incidents
from automation.reports.slo_report import DEFAULT_DEMO_DATA_PATH, build_slo_report

logger = logging.getLogger(__name__)


def _load_demo_dataset(path: str = DEFAULT_DEMO_DATA_PATH) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def collect_dataset(demo_path: str = DEFAULT_DEMO_DATA_PATH) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]], bool]:
    """Return (incidents, executions, used_mysql).

    Tries MySQL first (if reachable); falls back to the demo JSON dataset
    for both incidents and executions (executions have no MySQL read path
    in this codebase yet, so they always come from the demo dataset — this
    is a known, documented limitation, not a bug: see README/CHANGELOG).
    """
    demo = _load_demo_dataset(demo_path)
    executions = demo.get("executions", [])

    try:
        incidents = fetch_recent_incidents(limit=1000)
        used_mysql = True
    except DatabaseUnavailableError:
        incidents = demo.get("incidents", [])
        used_mysql = False

    return incidents, executions, used_mysql


def build_registry(demo_path: str = DEFAULT_DEMO_DATA_PATH) -> CollectorRegistry:
    """Build a fresh CollectorRegistry populated with a point-in-time
    snapshot of incidents/executions metrics. A fresh registry per scrape
    avoids stale-series/duplicate-registration issues and keeps this
    exporter stateless (correct for a demo/lab exporter scraped every
    `scrape_interval`, per observability/prometheus/prometheus.yml)."""
    registry = CollectorRegistry()
    incidents, executions, used_mysql = collect_dataset(demo_path)

    incidents_total = Gauge(
        "automation_incidents_total",
        "Number of incidents by status.",
        ["status"],
        registry=registry,
    )
    status_counts: Dict[str, int] = {}
    for incident in incidents:
        status = incident.get("status") or "UNKNOWN"
        status_counts[status] = status_counts.get(status, 0) + 1
    for status, count in status_counts.items():
        incidents_total.labels(status=status).set(count)

    executions_total = Gauge(
        "automation_executions_total",
        "Number of automation executions by tool and status.",
        ["tool", "status"],
        registry=registry,
    )
    exec_counts: Dict[Tuple[str, str], int] = {}
    for execution in executions:
        key = (execution.get("tool") or "unknown", execution.get("status") or "unknown")
        exec_counts[key] = exec_counts.get(key, 0) + 1
    for (tool, status), count in exec_counts.items():
        executions_total.labels(tool=tool, status=status).set(count)

    slo = build_slo_report(incidents)

    mttr_gauge = Gauge("automation_mttr_seconds", "Mean Time To Recovery across RESOLVED incidents.", registry=registry)
    if slo.mttr_seconds is not None:
        mttr_gauge.set(slo.mttr_seconds)

    availability_gauge = Gauge(
        "automation_slo_availability_ratio",
        "Resolved-rate availability SLI (RESOLVED / total incidents).",
        registry=registry,
    )
    if slo.availability_sli is not None:
        availability_gauge.set(slo.availability_sli)

    budget_gauge = Gauge(
        "automation_slo_error_budget_remaining_ratio",
        "Remaining error budget ratio (1.0 = full budget, <0 = SLO breached).",
        registry=registry,
    )
    if slo.error_budget_remaining_ratio is not None:
        budget_gauge.set(slo.error_budget_remaining_ratio)

    source_gauge = Gauge(
        "automation_data_source",
        "1 if metrics were sourced from MySQL, 0 if from the demo JSON dataset.",
        registry=registry,
    )
    source_gauge.set(1 if used_mysql else 0)

    return registry


class _MetricsHandler(BaseHTTPRequestHandler):
    demo_path = DEFAULT_DEMO_DATA_PATH

    def _send(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802 (stdlib naming convention)
        if self.path.startswith("/metrics"):
            registry = build_registry(self.demo_path)
            self._send(200, generate_latest(registry), CONTENT_TYPE_LATEST)
        elif self.path.startswith("/healthz"):
            self._send(200, b"ok", "text/plain")
        elif self.path.startswith("/ready"):
            self._send(200, b"ready", "text/plain")
        else:
            self._send(404, b"not found", "text/plain")

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        logger.debug("%s - %s", self.address_string(), format % args)


def run_server(host: str = "0.0.0.0", port: int = 8080, demo_path: str = DEFAULT_DEMO_DATA_PATH) -> ThreadingHTTPServer:
    """Start the exporter HTTP server. Returns the server instance (caller
    decides whether to `serve_forever()` or run it in a background thread,
    e.g. for tests — see automation/tests/test_metrics_exporter.py)."""
    handler_cls = type("_BoundMetricsHandler", (_MetricsHandler,), {"demo_path": demo_path})
    server = ThreadingHTTPServer((host, port), handler_cls)
    return server


def main() -> None:  # pragma: no cover - thin CLI wrapper
    import argparse

    parser = argparse.ArgumentParser(description="Automation Controller Prometheus exporter")
    parser.add_argument("--host", default=os.environ.get("METRICS_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("METRICS_PORT", "8080")))
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    server = run_server(host=args.host, port=args.port)
    logger.info("Serving /metrics, /healthz, /ready on %s:%s", args.host, args.port)
    server.serve_forever()


if __name__ == "__main__":  # pragma: no cover
    main()
