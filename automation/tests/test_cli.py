"""Tests for automation.cli.main -- exercised via click.testing.CliRunner
(no real subprocess/CLI invocation needed)."""
from __future__ import annotations

import json
import socket
import sys

from click.testing import CliRunner

from automation.cli.main import cli
from automation.troubleshooting.health_check import find_free_port


def test_cli_help():
    runner = CliRunner()
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "health-check" in result.output
    assert "inventory" in result.output
    assert "incident" in result.output
    assert "report" in result.output


def test_cli_health_check_json_unhealthy():
    port = find_free_port()  # nothing listening
    runner = CliRunner()
    result = runner.invoke(cli, ["health-check", "--port", str(port), "--json"])
    assert result.exit_code == 1
    payload = json.loads(result.output)
    assert payload["healthy"] is False


def test_cli_health_check_healthy():
    port = find_free_port()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("127.0.0.1", port))
    server.listen(1)
    try:
        runner = CliRunner()
        result = runner.invoke(cli, ["health-check", "--port", str(port)])
        assert result.exit_code == 0
        assert "HEALTHY" in result.output
    finally:
        server.close()


def test_cli_incident_run_end_to_end(tmp_path):
    port = find_free_port()
    start_command = f'"{sys.executable}" -m http.server {port} --bind 127.0.0.1'
    report_path = tmp_path / "incident.md"

    runner = CliRunner()
    result = runner.invoke(
        cli,
        [
            "incident",
            "run",
            "--port",
            str(port),
            "--problem",
            "nginx unavailable",
            "--start-command",
            start_command,
            "--wait-seconds",
            "8",
            "--report-path",
            str(report_path),
        ],
    )

    assert result.exit_code == 0, result.output
    assert "RESOLVED" in result.output or report_path.read_text(encoding="utf-8").find("RESOLVED") >= 0
    assert report_path.exists()

    # Best-effort cleanup: kill whatever process is now listening on `port`.
    import psutil

    for proc in psutil.process_iter(["pid", "cmdline"]):
        try:
            cmdline = " ".join(proc.info.get("cmdline") or [])
            if "http.server" in cmdline and str(port) in cmdline:
                proc.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue


def test_cli_report_from_json(tmp_path):
    incident_path = tmp_path / "incident.json"
    incident_path.write_text(
        json.dumps(
            {
                "id": 17,
                "host": "linux-web-02",
                "environment": "dev",
                "problem": "nginx unavailable",
                "status": "RESOLVED",
            }
        ),
        encoding="utf-8",
    )

    runner = CliRunner()
    result = runner.invoke(cli, ["report", "--from-json", str(incident_path)])
    assert result.exit_code == 0
    assert "Incident #17" in result.output


def test_cli_report_requires_exactly_one_source():
    runner = CliRunner()
    result = runner.invoke(cli, ["report"])
    assert result.exit_code != 0
    assert "exatamente uma op" in result.output


def test_cli_report_incident_id_without_db_fails_gracefully():
    runner = CliRunner()
    result = runner.invoke(cli, ["report", "--incident-id", "1"])
    assert result.exit_code == 2
    assert "indispon" in result.output.lower()
