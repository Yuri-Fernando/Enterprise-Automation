"""Disk usage checks with a configurable alert threshold."""
from __future__ import annotations

import shutil
from datetime import datetime, timezone


def check_disk_usage(path: str = "/", threshold_percent: float = 90.0) -> dict:
    """Return disk usage stats for `path` and whether usage meets/exceeds
    `threshold_percent`."""
    usage = shutil.disk_usage(path)
    percent_used = round((usage.used / usage.total) * 100, 2) if usage.total else 0.0
    return {
        "path": path,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "total_bytes": usage.total,
        "used_bytes": usage.used,
        "free_bytes": usage.free,
        "percent_used": percent_used,
        "threshold_percent": threshold_percent,
        "alert": percent_used >= threshold_percent,
    }
