"""SLI/SLO and MTTR reporting.

Defines the Service Level Indicators this project can actually measure from
data it already produces (the `incidents` table contract — see
database/schema.sql and automation/reports/incident_report.py), compares them
against a declared Service Level Objective, and renders both as Markdown.

Deliberately scoped to what is measurable today:

  - MTTR (Mean Time To Recovery): mean `recovery_time_seconds` across
    RESOLVED incidents. Real, computed from the same field the orchestrator
    (automation/orchestrator.py) already records.
  - Availability SLI: proportion of incidents that reached RESOLVED out of
    all incidents opened in the period (a resolved-rate proxy for
    availability — this project has no uptime/heartbeat time series to
    compute true uptime-percentage availability, so this is documented as a
    proxy, not invented as something more precise than the data supports).

Explicitly NOT computed (would require data this project does not capture):
  - MTTD (Mean Time To Detect) — `detection` timestamps exist in-memory
    during a single `run_self_healing()` call but are not persisted with a
    "problem started at" timestamp, so detection latency can't be measured
    from historical incidents.
  - True uptime-percentage availability — would need a continuous
    heartbeat/synthetic-check time series, not just incident records.

Two data sources are supported, mirroring automation/reports/incident_report.py:
  1. A list of incident dicts already in memory (unit tests, exporter).
  2. `dashboard/js/data.example.json` ("incidents" key) for the same offline
     demo-mode the dashboard itself uses when there is no MySQL running.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEFAULT_DEMO_DATA_PATH = os.path.join(_REPO_ROOT, "dashboard", "js", "data.example.json")

# --- SLO targets -------------------------------------------------------
# Declared targets for this portfolio lab (see docs/observability/slo.md for
# rationale). Kept as module-level defaults so the CLI/exporter/tests all
# agree on the same numbers unless a caller explicitly overrides them.
DEFAULT_MTTR_TARGET_SECONDS = 60.0
DEFAULT_AVAILABILITY_SLO = 0.95  # 95% of opened incidents must reach RESOLVED


@dataclass
class SLOReport:
    total_incidents: int
    resolved_incidents: int
    open_incidents: int
    availability_sli: Optional[float]
    availability_slo_target: float
    availability_met: Optional[bool]
    mttr_seconds: Optional[float]
    mttr_target_seconds: float
    mttr_met: Optional[bool]
    error_budget_total_events: int
    error_budget_allowed_failures: float
    error_budget_consumed_failures: int
    error_budget_remaining_failures: float
    error_budget_remaining_ratio: Optional[float]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_incidents": self.total_incidents,
            "resolved_incidents": self.resolved_incidents,
            "open_incidents": self.open_incidents,
            "availability_sli": self.availability_sli,
            "availability_slo_target": self.availability_slo_target,
            "availability_met": self.availability_met,
            "mttr_seconds": self.mttr_seconds,
            "mttr_target_seconds": self.mttr_target_seconds,
            "mttr_met": self.mttr_met,
            "error_budget_total_events": self.error_budget_total_events,
            "error_budget_allowed_failures": self.error_budget_allowed_failures,
            "error_budget_consumed_failures": self.error_budget_consumed_failures,
            "error_budget_remaining_failures": self.error_budget_remaining_failures,
            "error_budget_remaining_ratio": self.error_budget_remaining_ratio,
        }


def load_incidents_from_json(path: str = DEFAULT_DEMO_DATA_PATH) -> List[Dict[str, Any]]:
    """Load the `incidents` array from a dashboard-style demo JSON file
    (default: dashboard/js/data.example.json, the same file the dashboard's
    own demo mode reads)."""
    with open(path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload.get("incidents", [])


def compute_mttr(incidents: List[Dict[str, Any]]) -> Optional[float]:
    """Mean Time To Recovery across RESOLVED incidents with a numeric
    recovery_time_seconds. Returns None if there is no such incident
    (nothing to average — distinct from a true 0s MTTR)."""
    samples = [
        float(i["recovery_time_seconds"])
        for i in incidents
        if i.get("status") == "RESOLVED" and i.get("recovery_time_seconds") is not None
    ]
    if not samples:
        return None
    return round(sum(samples) / len(samples), 3)


def compute_availability_sli(incidents: List[Dict[str, Any]]) -> Optional[float]:
    """Resolved-rate proxy for availability: RESOLVED / total incidents
    opened. Returns None if there are no incidents at all (undefined, not
    100%/0%)."""
    if not incidents:
        return None
    resolved = sum(1 for i in incidents if i.get("status") == "RESOLVED")
    return round(resolved / len(incidents), 4)


def compute_error_budget(
    incidents: List[Dict[str, Any]],
    availability_slo_target: float = DEFAULT_AVAILABILITY_SLO,
) -> Dict[str, Any]:
    """Classic SRE error-budget math applied to incident counts instead of
    request counts (this project has no per-request telemetry):

        allowed_failures  = total_events * (1 - slo_target)
        consumed_failures = incidents still OPEN (i.e. not RESOLVED)
        remaining         = allowed_failures - consumed_failures

    A negative `remaining` means the error budget for the period is
    exhausted (SLO breached)."""
    total = len(incidents)
    consumed = sum(1 for i in incidents if i.get("status") != "RESOLVED")
    allowed = round(total * (1 - availability_slo_target), 4)
    remaining = round(allowed - consumed, 4)
    remaining_ratio = round(remaining / allowed, 4) if allowed > 0 else None
    return {
        "total_events": total,
        "allowed_failures": allowed,
        "consumed_failures": consumed,
        "remaining_failures": remaining,
        "remaining_ratio": remaining_ratio,
    }


def build_slo_report(
    incidents: List[Dict[str, Any]],
    mttr_target_seconds: float = DEFAULT_MTTR_TARGET_SECONDS,
    availability_slo_target: float = DEFAULT_AVAILABILITY_SLO,
) -> SLOReport:
    total = len(incidents)
    resolved = sum(1 for i in incidents if i.get("status") == "RESOLVED")
    open_count = total - resolved

    mttr = compute_mttr(incidents)
    availability = compute_availability_sli(incidents)
    budget = compute_error_budget(incidents, availability_slo_target)

    return SLOReport(
        total_incidents=total,
        resolved_incidents=resolved,
        open_incidents=open_count,
        availability_sli=availability,
        availability_slo_target=availability_slo_target,
        availability_met=(availability >= availability_slo_target) if availability is not None else None,
        mttr_seconds=mttr,
        mttr_target_seconds=mttr_target_seconds,
        mttr_met=(mttr <= mttr_target_seconds) if mttr is not None else None,
        error_budget_total_events=budget["total_events"],
        error_budget_allowed_failures=budget["allowed_failures"],
        error_budget_consumed_failures=budget["consumed_failures"],
        error_budget_remaining_failures=budget["remaining_failures"],
        error_budget_remaining_ratio=budget["remaining_ratio"],
    )


def render_slo_markdown(report: SLOReport) -> str:
    def fmt_bool(value: Optional[bool]) -> str:
        if value is None:
            return "_sem dados_"
        return "✅ atingido" if value else "❌ violado"

    def fmt_pct(value: Optional[float]) -> str:
        return "_sem dados_" if value is None else f"{value * 100:.2f}%"

    def fmt_secs(value: Optional[float]) -> str:
        return "_sem dados_" if value is None else f"{value:.2f}s"

    lines = [
        "# SLI/SLO Report",
        "",
        f"- **Incidentes no período:** {report.total_incidents} "
        f"({report.resolved_incidents} RESOLVED / {report.open_incidents} OPEN)",
        "",
        "## Availability (proxy: taxa de resolução)",
        f"- SLI medido: {fmt_pct(report.availability_sli)}",
        f"- SLO alvo: {fmt_pct(report.availability_slo_target)}",
        f"- Status: {fmt_bool(report.availability_met)}",
        "",
        "## MTTR (Mean Time To Recovery)",
        f"- MTTR medido: {fmt_secs(report.mttr_seconds)}",
        f"- Alvo: {fmt_secs(report.mttr_target_seconds)}",
        f"- Status: {fmt_bool(report.mttr_met)}",
        "",
        "## Error budget",
        f"- Eventos no período: {report.error_budget_total_events}",
        f"- Falhas permitidas pelo SLO: {report.error_budget_allowed_failures}",
        f"- Falhas consumidas (incidentes não resolvidos): {report.error_budget_consumed_failures}",
        f"- Restante: {report.error_budget_remaining_failures} "
        f"({fmt_pct(report.error_budget_remaining_ratio)} do orçamento)"
        if report.error_budget_remaining_ratio is not None
        else f"- Restante: {report.error_budget_remaining_failures}",
        "",
        "_MTTD e disponibilidade real (uptime %) não são calculados — este "
        "projeto não persiste timestamp de início do problema nem uma série "
        "temporal de heartbeat/synthetic-check. Ver docstring de "
        "`automation/reports/slo_report.py`._",
    ]
    return "\n".join(lines) + "\n"
