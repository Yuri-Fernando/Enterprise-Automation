"""Tests for automation.troubleshooting.disk_check."""
from __future__ import annotations

import os

from automation.troubleshooting.disk_check import check_disk_usage


def test_check_disk_usage_basic_fields():
    root = os.path.abspath(os.sep)  # e.g. "C:\\" on Windows, "/" on POSIX
    result = check_disk_usage(path=root)
    assert result["path"] == root
    assert result["total_bytes"] > 0
    assert 0 <= result["percent_used"] <= 100
    assert result["free_bytes"] + result["used_bytes"] <= result["total_bytes"] + 1  # allow rounding


def test_check_disk_usage_alert_flag_low_threshold():
    root = os.path.abspath(os.sep)
    result = check_disk_usage(path=root, threshold_percent=0.0)
    assert result["alert"] is True


def test_check_disk_usage_alert_flag_high_threshold():
    root = os.path.abspath(os.sep)
    result = check_disk_usage(path=root, threshold_percent=100.1)
    assert result["alert"] is False
