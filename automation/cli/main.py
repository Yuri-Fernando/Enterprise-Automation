"""Automation Controller CLI.

Entry point for the Python automation trilha: local health checks, AWS
inventory, the self-healing incident flow, and incident reporting.

Usage:
    python -m automation.cli --help
    python -m automation.cli health-check --port 8000
    python -m automation.cli inventory --region sa-east-1
    python -m automation.cli incident run --port 8000 --process-name http.server \\
        --start-command "python -m http.server 8000"
    python -m automation.cli report --from-json incident.json
"""
from __future__ import annotations

import json
import shlex
import sys
from typing import Optional

import click

from automation.inventory.aws_inventory import get_inventory
from automation.orchestrator import run_self_healing
from automation.reports.incident_report import (
    DatabaseUnavailableError,
    fetch_incident_by_id,
    fetch_recent_incidents,
    render_incident_json,
    render_incident_markdown,
    render_incidents_summary_markdown,
    save_report,
)
from automation.troubleshooting.health_check import run_health_check


@click.group()
@click.version_option(package_name=None, prog_name="automation-controller")
def cli() -> None:
    """Enterprise Cloud Automation & Infrastructure Platform -- Automation Controller."""


@cli.command("health-check")
@click.option("--host", default="127.0.0.1", show_default=True, help="Host to check.")
@click.option("--port", type=int, default=None, help="TCP port to check.")
@click.option("--process-name", default=None, help="Substring to match against running process name/cmdline.")
@click.option("--pid", type=int, default=None, help="Specific PID to check instead of process-name.")
@click.option("--timeout", type=float, default=1.0, show_default=True, help="Per-check timeout in seconds.")
@click.option("--json", "as_json", is_flag=True, help="Print raw JSON instead of a human summary.")
def health_check_cmd(host: str, port: Optional[int], process_name: Optional[str], pid: Optional[int], timeout: float, as_json: bool) -> None:
    """Run a local health check (port reachability and/or process liveness)."""
    result = run_health_check(host=host, port=port, process_name=process_name, pid=pid, timeout=timeout)
    if as_json:
        click.echo(json.dumps(result, indent=2))
    else:
        status = "HEALTHY" if result["healthy"] else ("UNKNOWN" if result["healthy"] is None else "UNHEALTHY")
        click.echo(f"[{status}] host={result['host']} port={result['port']} process_running={result['process_running']}")

    if result["healthy"] is False:
        sys.exit(1)


@cli.command("inventory")
@click.option("--region", default="sa-east-1", show_default=True, help="AWS region to inventory.")
@click.option("--json", "as_json", is_flag=True, help="Print raw JSON instead of a table.")
def inventory_cmd(region: str, as_json: bool) -> None:
    """List AWS EC2/RDS inventory for a region (real AWS credentials via boto3)."""
    try:
        data = get_inventory(region=region)
    except Exception as exc:  # noqa: BLE001 - surfaced as a friendly CLI error
        click.echo(f"Falha ao consultar inventário AWS: {exc}", err=True)
        sys.exit(1)

    if as_json:
        click.echo(json.dumps(data, indent=2, default=str))
        return

    click.echo(f"Inventory for region={data['region']} (generated_at={data['generated_at']})")
    for resource_type in ("ec2", "rds"):
        items = data.get(resource_type, [])
        click.echo(f"\n{resource_type.upper()} ({len(items)}):")
        for item in items:
            click.echo(f"  - {item['id']}  type={item.get('instance_type')}  state={item.get('state')}  name={item.get('name')}")


@cli.group("incident")
def incident_group() -> None:
    """Self-healing incident flow (detect -> diagnose -> remediate -> validate -> report)."""


@incident_group.command("run")
@click.option("--host", default="127.0.0.1", show_default=True)
@click.option("--port", type=int, default=None, help="TCP port the service should be listening on.")
@click.option("--process-name", default=None, help="Substring to identify the target process.")
@click.option("--pid", type=int, default=None)
@click.option("--environment", default="dev", show_default=True)
@click.option("--problem", default=None, help="Human description of the problem (defaults to an auto-generated label).")
@click.option(
    "--remediation",
    type=click.Choice(["local_process", "ansible", "powershell"]),
    default="local_process",
    show_default=True,
)
@click.option("--start-command", default=None, help="Shell-quoted command to (re)start the local process, e.g. \"python -m http.server 8000\".")
@click.option("--playbook-path", default=None, help="Ansible playbook path (remediation=ansible).")
@click.option("--script-path", default=None, help="PowerShell script path (remediation=powershell).")
@click.option("--wait-seconds", type=float, default=10.0, show_default=True)
@click.option("--report-format", type=click.Choice(["markdown", "json", "none"]), default="markdown", show_default=True)
@click.option("--report-path", default=None, help="If set, also write the report to this file.")
def incident_run_cmd(
    host: str,
    port: Optional[int],
    process_name: Optional[str],
    pid: Optional[int],
    environment: str,
    problem: Optional[str],
    remediation: str,
    start_command: Optional[str],
    playbook_path: Optional[str],
    script_path: Optional[str],
    wait_seconds: float,
    report_format: str,
    report_path: Optional[str],
) -> None:
    """Run the full self-healing incident flow and print/save the incident report."""
    parsed_start_command = shlex.split(start_command) if start_command else None

    incident = run_self_healing(
        host=host,
        port=port,
        process_name=process_name,
        pid=pid,
        environment=environment,
        problem=problem,
        remediation=remediation,
        start_command=parsed_start_command,
        playbook_path=playbook_path,
        script_path=script_path,
        wait_seconds=wait_seconds,
    )

    if report_format == "markdown":
        rendered = render_incident_markdown(incident)
    elif report_format == "json":
        rendered = render_incident_json(incident)
    else:
        rendered = None

    if rendered is not None:
        click.echo(rendered)
    if report_path and rendered is not None:
        saved_path = save_report(rendered, report_path)
        click.echo(f"Report saved to {saved_path}")

    if incident["status"] != "RESOLVED":
        sys.exit(1)


@cli.command("report")
@click.option("--from-json", "from_json_path", default=None, help="Render a report from a local incident JSON file.")
@click.option("--incident-id", type=int, default=None, help="Fetch a single incident by id from MySQL.")
@click.option("--recent", type=int, default=None, help="Fetch the N most recent incidents from MySQL.")
@click.option("--format", "output_format", type=click.Choice(["markdown", "json"]), default="markdown", show_default=True)
@click.option("--output", "output_path", default=None, help="If set, write the report to this file instead of stdout.")
def report_cmd(from_json_path: Optional[str], incident_id: Optional[int], recent: Optional[int], output_format: str, output_path: Optional[str]) -> None:
    """Generate an incident report from a JSON file or from MySQL."""
    if sum(x is not None for x in (from_json_path, incident_id, recent)) != 1:
        raise click.UsageError("Forneça exatamente uma opção: --from-json, --incident-id ou --recent.")

    try:
        if from_json_path:
            with open(from_json_path, "r", encoding="utf-8") as handle:
                data = json.load(handle)
            rendered = render_incident_json(data) if output_format == "json" else render_incident_markdown(data)
        elif incident_id is not None:
            data = fetch_incident_by_id(incident_id)
            rendered = render_incident_json(data) if output_format == "json" else render_incident_markdown(data)
        else:
            rows = fetch_recent_incidents(limit=recent)
            rendered = json.dumps(rows, indent=2, default=str) if output_format == "json" else render_incidents_summary_markdown(rows)
    except DatabaseUnavailableError as exc:
        click.echo(f"Banco de dados indisponível: {exc}", err=True)
        sys.exit(2)
    except (FileNotFoundError, LookupError) as exc:
        click.echo(str(exc), err=True)
        sys.exit(1)

    if output_path:
        saved_path = save_report(rendered, output_path)
        click.echo(f"Report saved to {saved_path}")
    else:
        click.echo(rendered)


if __name__ == "__main__":  # pragma: no cover
    cli()
