#!/usr/bin/env bash
# =============================================================================
# tests/terraform/test-kyverno-policies.sh
#
# Real `kyverno test` run of policies/kyverno/require-nonroot-and-limits.yaml
# against two fixture Pods (policies/kyverno/testdata/):
#   - pod-compliant.yaml: mirrors the actual Pod spec this project's own
#     helm/automation-controller chart produces (image, resources from
#     values.yaml, runAsNonRoot matching the non-root USER in the repo-root
#     Dockerfile) -- both rules must PASS.
#   - pod-violation.yaml: the same Pod with no securityContext/resources --
#     both rules must FAIL (this is what proves the policy actually blocks
#     something, not just a policy that trivially never matches).
#
# Before this test existed, this policy was committed but never evaluated
# against anything (see policies/README.md's "próximo passo" note and
# PROJECT_LOG.md) -- it could have silently stopped matching Pods (a typo
# in `match.resources.kinds`, etc.) and nobody would notice.
#
# Usage:
#   bash tests/terraform/test-kyverno-policies.sh
#
# Requires `kyverno` (the CLI) on PATH (https://kyverno.io/docs/kyverno-cli/).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v kyverno >/dev/null 2>&1; then
  echo "ERROR: kyverno executable not found on PATH (https://kyverno.io/docs/kyverno-cli/)." >&2
  exit 2
fi

echo "== Kyverno policy tests =="
kyverno version 2>&1 | head -1
echo

cd "$REPO_ROOT" || exit 2

output=$(kyverno test policies/kyverno/testdata 2>&1)
echo "$output"
echo

if echo "$output" | grep -qE "tests failed$" && ! echo "$output" | grep -qE "^Test Summary: .* 0 tests failed$"; then
  echo "RESULT: FAIL"
  exit 1
fi

if ! echo "$output" | grep -q "Test Summary:"; then
  echo "RESULT: FAIL (no test summary produced -- kyverno test likely errored before running)"
  exit 1
fi

echo "RESULT: PASS"
exit 0
