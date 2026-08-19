"""Remediation actions for diagnosed problems.

Two remediation styles are supported:

1. Local process restart (`restart_local_process`) -- used by the
   self-healing demo (demo_incident.py): stop the failed process (if a
   handle is provided) and start a fresh one from a known command, polling
   until the target port responds again.
2. Delegated remediation via Ansible/PowerShell (`run_ansible_playbook`,
   `run_powershell_script`) -- runs the external tool via subprocess. If the
   tool is not installed, a clear, non-crashing error is returned instead of
   raising, so the CLI works even without Ansible/PowerShell available
   (e.g. on a bare Linux CI runner without pwsh, or a Windows box without
   Ansible/WSL).
"""
from __future__ import annotations

import shutil
import subprocess
import time
from typing import List, Optional, Sequence

from automation.troubleshooting.health_check import check_port


def restart_local_process(
    start_command: Sequence[str],
    port: int,
    host: str = "127.0.0.1",
    stop_process=None,
    wait_seconds: float = 10.0,
    poll_interval: float = 0.2,
    **popen_kwargs,
) -> dict:
    """Start `start_command` as a subprocess and poll `host:port` until it
    responds or `wait_seconds` elapses.

    `stop_process` (optional) is a subprocess.Popen-like object (anything
    with `.kill()`/`.terminate()` and `.wait()`) that is terminated first if
    still alive, modelling a "kill the broken instance, start a clean one"
    remediation. Returns success flag, the new process object/pid and the
    measured recovery time in seconds (wall clock from the start of this
    call until the port responds, or until timeout).
    """
    started_at = time.monotonic()

    if stop_process is not None:
        _terminate_quietly(stop_process)

    new_process = subprocess.Popen(list(start_command), **popen_kwargs)

    deadline = time.monotonic() + wait_seconds
    recovered = False
    while time.monotonic() < deadline:
        if check_port(host=host, port=port, timeout=0.5):
            recovered = True
            break
        time.sleep(poll_interval)

    recovery_time_seconds = round(time.monotonic() - started_at, 3)

    return {
        "action": f"restarted local process: {' '.join(str(c) for c in start_command)}",
        "success": recovered,
        "pid": new_process.pid,
        "process": new_process,
        "recovery_time_seconds": recovery_time_seconds,
    }


def _terminate_quietly(process) -> None:
    try:
        if hasattr(process, "kill"):
            process.kill()
        elif hasattr(process, "terminate"):
            process.terminate()
        if hasattr(process, "wait"):
            process.wait(timeout=5)
    except Exception:
        pass


def run_ansible_playbook(playbook_path: str, extra_args: Optional[List[str]] = None) -> dict:
    """Run `ansible-playbook <playbook_path>` via subprocess.

    Returns a result dict; a missing `ansible-playbook` binary is reported
    in the result (success=False, error=<hint>) rather than raised.
    """
    return _run_external_tool(
        binary="ansible-playbook",
        args=[playbook_path, *(extra_args or [])],
        not_found_hint="ansible-playbook não encontrado — rode via WSL ou CI",
    )


def run_powershell_script(script_path: str, extra_args: Optional[List[str]] = None) -> dict:
    """Run a PowerShell script via `pwsh` (falls back to `powershell.exe`
    if `pwsh` is not on PATH). Missing tooling is reported, not raised."""
    binary = "pwsh" if shutil.which("pwsh") else "powershell"
    return _run_external_tool(
        binary=binary,
        args=["-File", script_path, *(extra_args or [])],
        not_found_hint="pwsh/powershell.exe não encontrado — rode via WSL ou CI",
    )


def _run_external_tool(binary: str, args: List[str], not_found_hint: str) -> dict:
    command = [binary, *args]
    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=300)
        return {
            "success": completed.returncode == 0,
            "command": command,
            "returncode": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except FileNotFoundError:
        return {
            "success": False,
            "command": command,
            "returncode": None,
            "error": not_found_hint,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "success": False,
            "command": command,
            "returncode": None,
            "error": f"timeout after {exc.timeout}s running {binary}",
        }


def decide_remediation(diagnosis: dict) -> str:
    """Given a diagnosis dict (as produced by health/service checks), decide
    which remediation action to take.

    Simple rule-based decision matching the self-healing demo scenario: if
    the process is confirmed down or the port is confirmed closed, restart
    the local process; otherwise no action is needed.
    """
    process_running = diagnosis.get("process_running")
    port_open = diagnosis.get("port_open")
    if process_running is False or port_open is False:
        return "restart_local_process"
    return "no_action"
