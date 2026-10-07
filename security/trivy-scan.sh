#!/usr/bin/env bash
# =============================================================================
# security/trivy-scan.sh
#
# Real Trivy scans of this repository:
#   1. Filesystem scan (vulnerabilities in requirements.txt/lockfiles +
#      misconfigurations in Dockerfile/terraform/kubernetes manifests).
#   2. Container image scan of automation-controller:local (built from the
#      repo-root Dockerfile) -- OS packages + Python dependencies baked
#      into the image.
#   3. SBOM generation via `trivy sbom`/syft for the same image, written to
#      security/sbom/ as a versioned artifact (see that directory's README
#      for why it's committed instead of only generated in CI).
#
# Exit code: non-zero if Trivy finds a CRITICAL vulnerability (same
# hard-fail severity policy as .checkov.yaml for Terraform), 0 otherwise.
# HIGH/MEDIUM/LOW are reported but do not fail the run -- same soft-fail
# rationale as security-scan.yml's Checkov job.
#
# Usage:
#   bash security/trivy-scan.sh                 # fs + image + sbom
#   bash security/trivy-scan.sh --fs-only        # skip image build/scan
#   SKIP_IMAGE_BUILD=1 bash security/trivy-scan.sh   # scan existing image, don't rebuild
#
# Requires `trivy` and (unless --fs-only) `docker` + `syft` on PATH.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_TAG="automation-controller:trivy-scan"
SBOM_DIR="$REPO_ROOT/security/sbom"
FS_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --fs-only) FS_ONLY=1 ;;
  esac
done

if ! command -v trivy >/dev/null 2>&1; then
  echo "ERROR: trivy executable not found on PATH (https://aquasecurity.github.io/trivy/latest/getting-started/installation/)." >&2
  exit 2
fi

echo "== Trivy: $(trivy --version | head -1) =="
mkdir -p "$SBOM_DIR"
FAIL=0

echo
echo "-- 1/3: Filesystem scan (vulnerabilities + Dockerfile/Helm/K8s misconfigurations) --"
# terraform/ is deliberately excluded from Trivy's misconfig pass: it's
# already covered by Checkov (.checkov.yaml + security-scan.yml, with a
# severity policy tuned specifically for this project's modules) --
# running a second, differently-tuned IaC scanner over the same files
# would just produce a second, conflicting opinion on the same resources
# without adding real coverage. Trivy's job here is what Checkov doesn't
# cover: dependency vulnerabilities, the Dockerfile, and the Helm/K8s
# manifests.
trivy fs --scanners vuln,misconfig --severity CRITICAL,HIGH,MEDIUM,LOW \
  --skip-dirs terraform --exit-code 0 "$REPO_ROOT" \
  | tee "$SBOM_DIR/trivy-fs-report.txt"

if trivy fs --scanners vuln --severity CRITICAL --exit-code 1 --quiet --skip-dirs terraform "$REPO_ROOT" >/dev/null 2>&1; then
  echo "   No CRITICAL filesystem vulnerabilities."
else
  echo "   CRITICAL filesystem vulnerabilities found -- see trivy-fs-report.txt above."
  FAIL=1
fi

if [ "$FS_ONLY" -eq 0 ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "WARNING: docker not found on PATH -- skipping image scan + SBOM (fs scan above still ran)." >&2
  else
    echo
    echo "-- 2/3: Container image scan ($IMAGE_TAG) --"
    if [ "${SKIP_IMAGE_BUILD:-0}" -ne 1 ]; then
      docker build -t "$IMAGE_TAG" -f "$REPO_ROOT/Dockerfile" "$REPO_ROOT"
    fi
    trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --exit-code 0 "$IMAGE_TAG" \
      | tee "$SBOM_DIR/trivy-image-report.txt"

    if trivy image --severity CRITICAL --exit-code 1 --quiet "$IMAGE_TAG" >/dev/null 2>&1; then
      echo "   No CRITICAL image vulnerabilities."
    else
      echo "   CRITICAL image vulnerabilities found -- see trivy-image-report.txt above."
      FAIL=1
    fi

    echo
    echo "-- 3/3: SBOM generation (CycloneDX via trivy) --"
    trivy image --format cyclonedx --output "$SBOM_DIR/automation-controller.cdx.json" "$IMAGE_TAG"
    echo "   SBOM written to security/sbom/automation-controller.cdx.json"

    if command -v syft >/dev/null 2>&1; then
      syft "$IMAGE_TAG" -o spdx-json="$SBOM_DIR/automation-controller.spdx.json" >/dev/null
      echo "   SBOM written to security/sbom/automation-controller.spdx.json (syft, SPDX format)"
    else
      echo "   syft not found on PATH -- skipping the SPDX-format SBOM (CycloneDX above still generated)." >&2
    fi
  fi
fi

echo
if [ "$FAIL" -eq 1 ]; then
  echo "RESULT: FAIL (CRITICAL findings present)"
  exit 1
fi
echo "RESULT: PASS (no CRITICAL findings)"
exit 0
