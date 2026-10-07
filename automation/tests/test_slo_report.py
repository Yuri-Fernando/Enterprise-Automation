"""Tests for automation.reports.slo_report.

Uses the project's own demo dataset (dashboard/js/data.example.json) as a
real fixture — the exact numbers asserted below were computed by hand from
that file's `incidents` array, not mocked.
"""
from __future__ import annotations

from automation.reports.slo_report import (
    DEFAULT_DEMO_DATA_PATH,
    build_slo_report,
    compute_availability_sli,
    compute_error_budget,
    compute_mttr,
    load_incidents_from_json,
    render_slo_markdown,
)

# dashboard/js/data.example.json has 5 incidents: 4 RESOLVED (recovery_time_seconds
# 13, 27, 95, 42) and 1 OPEN (recovery_time_seconds null).
EXPECTED_MTTR = round((13 + 27 + 95 + 42) / 4, 3)  # 44.25
EXPECTED_AVAILABILITY = round(4 / 5, 4)  # 0.8


def test_load_incidents_from_demo_json():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    assert len(incidents) == 5
    assert sum(1 for i in incidents if i["status"] == "RESOLVED") == 4
    assert sum(1 for i in incidents if i["status"] == "OPEN") == 1


def test_compute_mttr_matches_hand_computed_value():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    assert compute_mttr(incidents) == EXPECTED_MTTR


def test_compute_mttr_none_when_no_resolved_incidents():
    assert compute_mttr([{"status": "OPEN", "recovery_time_seconds": None}]) is None
    assert compute_mttr([]) is None


def test_compute_availability_sli_matches_hand_computed_value():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    assert compute_availability_sli(incidents) == EXPECTED_AVAILABILITY


def test_compute_availability_sli_none_when_no_incidents():
    assert compute_availability_sli([]) is None


def test_compute_error_budget_consumed_equals_open_incidents():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    budget = compute_error_budget(incidents, availability_slo_target=0.95)
    assert budget["total_events"] == 5
    assert budget["consumed_failures"] == 1  # the one OPEN incident
    assert budget["allowed_failures"] == round(5 * 0.05, 4)  # 0.25
    # consumed (1) > allowed (0.25) -> budget exhausted for this toy SLO target
    assert budget["remaining_failures"] < 0


def test_build_slo_report_end_to_end_against_demo_dataset():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    report = build_slo_report(incidents, mttr_target_seconds=60.0, availability_slo_target=0.75)

    assert report.total_incidents == 5
    assert report.resolved_incidents == 4
    assert report.open_incidents == 1
    assert report.mttr_seconds == EXPECTED_MTTR
    assert report.mttr_met is True  # 44.25s <= 60s target
    assert report.availability_sli == EXPECTED_AVAILABILITY
    assert report.availability_met is True  # 0.8 >= 0.75 target


def test_render_slo_markdown_contains_key_numbers():
    incidents = load_incidents_from_json(DEFAULT_DEMO_DATA_PATH)
    report = build_slo_report(incidents)
    rendered = render_slo_markdown(report)

    assert "# SLI/SLO Report" in rendered
    assert "44.25s" in rendered
    assert "80.00%" in rendered
    assert "MTTD" in rendered  # honest disclosure of what is NOT measured


def test_render_slo_markdown_handles_no_data_gracefully():
    report = build_slo_report([])
    rendered = render_slo_markdown(report)
    assert "_sem dados_" in rendered
