#!/usr/bin/env bash
# =============================================================================
# tests/terraform/test-opa-policies.sh
#
# Real conftest evaluation of policies/opa/terraform_tags.rego against two
# committed Terraform-plan JSON fixtures (policies/opa/testdata/):
#   - plan_compliant.json: a real `terraform show -json` plan generated for
#     terraform/environments/dev against LocalStack (no real AWS cost/
#     credentials — see PROJECT_LOG.md), with every taggable resource
#     correctly tagged via terraform/providers.tf's default_tags.
#   - plan_violation.json: the exact same plan with one resource's
#     `tags_all` replaced by a map missing Environment/Project/ManagedBy —
#     built by mutating the compliant fixture, not hand-written, so the
#     JSON shape matches what Terraform actually emits.
#
# This is the regression test for a real bug found and fixed in this
# policy: it originally required lowercase tag keys
# ("project"/"environment"/"managed_by") that never match this project's
# actual (capitalized) tags, so the policy always "passed" vacuously
# against real plans — not because tagging was correct, but because the
# check could never match anything. This test fails loudly if that
# regresses (fixture 1 must PASS, fixture 2 must FAIL).
#
# Usage:
#   bash tests/terraform/test-opa-policies.sh
#
# Requires `conftest` on PATH (https://www.conftest.dev/install/).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
POLICY_DIR="$REPO_ROOT/policies/opa"
TESTDATA_DIR="$POLICY_DIR/testdata"

if ! command -v conftest >/dev/null 2>&1; then
  echo "ERROR: conftest executable not found on PATH (https://www.conftest.dev/install/)." >&2
  exit 2
fi

echo "== OPA/conftest policy tests =="
echo "conftest: $(conftest --version)"
echo "policies: $POLICY_DIR"
echo

FAIL_COUNT=0

cd "$REPO_ROOT" || exit 2

echo "-- plan_compliant.json (expected: PASS)"
if conftest test --all-namespaces -p policies/opa "policies/opa/testdata/plan_compliant.json"; then
  echo "   PASS (as expected)"
else
  echo "   FAIL -- expected this compliant fixture to pass conftest, it did not"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo

echo "-- plan_violation.json (expected: FAIL / deny triggered)"
if conftest test --all-namespaces -p policies/opa "policies/opa/testdata/plan_violation.json"; then
  echo "   FAIL -- expected this violating fixture to be denied, conftest passed it instead"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "   PASS (deny correctly triggered, as expected)"
fi
echo

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: FAIL ($FAIL_COUNT assertion(s) failed)"
  exit 1
fi

echo "RESULT: PASS"
exit 0
