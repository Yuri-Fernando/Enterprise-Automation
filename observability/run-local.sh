#!/usr/bin/env bash
# =============================================================================
# observability/run-local.sh
#
# Stages prometheus/, grafana/, loki/, promtail/ config into a local,
# non-cloud-synced directory and runs `docker compose up -d` against this
# stack with OBS_CONFIG_DIR pointing at the staged copy.
#
# Why: this repo can live on a Google Drive/OneDrive-synced drive. Docker
# Desktop's bind mounts of config files/dirs under that kind of virtual
# mount are unreliable on this project's own dev machine (confirmed:
# Prometheus/Loki/Promtail each failed with "is a directory" / "not a
# directory" OCI mount errors reading their config from the synced path,
# while the exact same files staged under /c/tmp mounted and loaded fine).
# See the top-of-file comment in docker-compose.yml.
#
# If your checkout is NOT on a synced drive, you don't need this script —
# plain `docker compose -f observability/docker-compose.yml up -d` works.
#
# Usage:
#   bash observability/run-local.sh [up|down|logs|ps] [extra docker compose args...]
#   OBS_STAGE_DIR=/c/tmp/my-stack bash observability/run-local.sh up -d
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_DIR="${OBS_STAGE_DIR:-/c/tmp/enterprise-automation-observability}"
ACTION="${1:-up}"
shift || true

mkdir -p "$STAGE_DIR"
for dir in prometheus grafana loki promtail; do
  rm -rf "$STAGE_DIR/$dir"
  cp -r "$SCRIPT_DIR/$dir" "$STAGE_DIR/$dir"
done

export OBS_CONFIG_DIR="$STAGE_DIR"

case "$ACTION" in
  up)
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d "$@"
    ;;
  down)
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" down "$@"
    ;;
  logs)
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" logs "$@"
    ;;
  ps)
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" ps "$@"
    ;;
  *)
    echo "Usage: $0 [up|down|logs|ps] [extra docker compose args...]" >&2
    exit 2
    ;;
esac
