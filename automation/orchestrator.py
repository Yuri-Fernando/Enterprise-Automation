"""Self-healing orchestrator.

Wires together the troubleshooting building blocks (automation/troubleshooting/)
into the incident flow described in escopo.md:

    Health Check detecta falha
        -> Coleta diagnostico (network + disk + service)
        -> Executa remediation (restart do processo local, ou Ansible/PowerShell)
        -> Valida recuperacao (health check de novo)
        -> Gera relatorio do incidente

This mirrors escopo.md's "Incident #017" example (nginx down -> restart via
Ansible -> HTTP 200 -> RESOLVED), but the default remediation path uses a
local process restart so the whole flow is runnable on a laptop with zero
external infrastructure (see demo_incident-style usage in
automation/tests/test_orchestrator.py). Ansible/PowerShell remediation can be
selected instead when `remediation="ansible"` or `remediation="powershell"`
is passed.
"""
from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Optional, Sequence

from automation.troubleshooting.disk_check import check_disk_usage
from automation.troubleshooting.health_check import run_health_check
from automation.troubleshooting.network_check import check_connectivity
from automation.troubleshooting.remediation import (
    decide_remediation,
    restart_local_process,
    run_ansible_playbook,
    run_powershell_script,
)
from automation.troubleshooting.service_check import check_service_status


def _diagnose(host: str, port: Optional[int], process_name: Optional[str], pid: Optional[int]) -> dict:
    """Collect diagnostic data once a failure is suspected: service status,
    network reachability and local disk usage. Mirrors escopo.md's "Coleta
    logs + CPU + RAM + portas" step (disk stands in for the resource-usage
    signal in this local/demo scope)."""
    diagnosis = check_service_status(
        service_name=process_name or "service",
        host=host,
        port=port,
        process_name=process_name,
        pid=pid,
    )
    diagnosis["network"] = check_connectivity(host=host, port=port, resolve=False) if port else None
    diagnosis["disk"] = check_disk_usage()
    return diagnosis


def _root_cause(diagnosis: dict) -> str:
    if diagnosis.get("process_running") is False:
        return "process stopped"
    if diagnosis.get("port_open") is False:
        return "port unreachable / service not listening"
    if diagnosis.get("disk", {}).get("alert"):
        return "disk usage above threshold"
    return "unknown"


def run_self_healing(
    host: str = "127.0.0.1",
    port: Optional[int] = None,
    process_name: Optional[str] = None,
    pid: Optional[int] = None,
    environment: str = "dev",
    problem: Optional[str] = None,
    remediation: str = "local_process",
    start_command: Optional[Sequence[str]] = None,
    stop_process=None,
    playbook_path: Optional[str] = None,
    script_path: Optional[str] = None,
    wait_seconds: float = 10.0,
) -> dict:
    """Run the full detect -> diagnose -> remediate -> validate -> report
    self-healing flow and return an incident dict matching the `incidents`
    table contract (see database/schema.sql).

    `remediation` selects the remediation strategy:
      - "local_process" (default): restart a local subprocess (`start_command`
        is required), used by the fully-local demo/tests.
      - "ansible": run `run_ansible_playbook(playbook_path)`.
      - "powershell": run `run_powershell_script(script_path)`.
    """
    started_at = time.monotonic()
    created_at = datetime.now(timezone.utc).isoformat()

    # 1. Detect: health check
    detection = run_health_check(host=host, port=port, process_name=process_name, pid=pid)
    problem_label = problem or f"{process_name or 'service'} unavailable on {host}" + (f":{port}" if port else "")

    if detection.get("healthy"):
        # Nothing to heal -- short-circuit with a RESOLVED/no-op incident.
        return {
            "host": host,
            "environment": environment,
            "problem": problem_label,
            "root_cause": None,
            "action": "no_action (already healthy)",
            "validation": "health check passed on first attempt",
            "recovery_time_seconds": 0,
            "status": "RESOLVED",
            "created_at": created_at,
            "detection": detection,
            "diagnosis": None,
            "remediation_result": None,
        }

    # 2. Diagnose
    diagnosis = _diagnose(host=host, port=port, process_name=process_name, pid=pid)
    root_cause = _root_cause(diagnosis)

    # 3. Decide + remediate
    action_plan = decide_remediation(diagnosis)
    remediation_result: dict
    action_label: str

    if action_plan == "no_action":
        remediation_result = {"action": "no_action", "success": True}
        action_label = "no action required"
    elif remediation == "ansible":
        if not playbook_path:
            raise ValueError("playbook_path é obrigatório quando remediation='ansible'")
        remediation_result = run_ansible_playbook(playbook_path)
        action_label = f"restart via Ansible ({playbook_path})"
    elif remediation == "powershell":
        if not script_path:
            raise ValueError("script_path é obrigatório quando remediation='powershell'")
        remediation_result = run_powershell_script(script_path)
        action_label = f"restart via PowerShell ({script_path})"
    else:
        if not start_command or port is None:
            raise ValueError("start_command e port são obrigatórios quando remediation='local_process'")
        remediation_result = restart_local_process(
            start_command=start_command,
            port=port,
            host=host,
            stop_process=stop_process,
            wait_seconds=wait_seconds,
        )
        action_label = f"restart local process ({' '.join(str(c) for c in start_command)})"

    # 4. Validate
    validation = run_health_check(host=host, port=port, process_name=process_name, pid=pid)
    recovery_time_seconds = round(time.monotonic() - started_at, 3)
    resolved = bool(remediation_result.get("success")) and bool(validation.get("healthy") in (True, None))
    status = "RESOLVED" if resolved else "OPEN"
    validation_label = (
        f"health check {'passed' if validation.get('healthy') else 'still failing'} after remediation"
    )

    return {
        "host": host,
        "environment": environment,
        "problem": problem_label,
        "root_cause": root_cause,
        "action": action_label,
        "validation": validation_label,
        "recovery_time_seconds": recovery_time_seconds,
        "status": status,
        "created_at": created_at,
        "detection": detection,
        "diagnosis": diagnosis,
        "remediation_result": {k: v for k, v in remediation_result.items() if k != "process"},
    }
