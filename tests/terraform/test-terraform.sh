#!/usr/bin/env bash
# =============================================================================
# tests/terraform/test-terraform.sh
#
# Lightweight, no-cost static checks for the Terraform code in terraform/:
#   1. `terraform fmt -check -diff` on every module/environment directory.
#   2. `terraform validate` on every module/environment directory that has
#      at least one *.tf file (init'd locally with -backend=false so it
#      never touches remote state or AWS).
#
# Deliberately does NOT run `terraform plan` or `terraform apply` — see
# PROJECT_LOG.md decision "Nenhum terraform apply automático nesta fase".
#
# `terraform validate` needs provider plugins, so this script runs
# `terraform init -backend=false -input=false` first. That step needs
# internet access to download the AWS provider from the Terraform
# Registry; if it can't complete within TIMEOUT_SECS (offline sandbox,
# firewalled CI runner, etc.) the directory is reported as VALIDATE=SKIP
# rather than failing the whole run. `terraform fmt` never needs network
# and always runs.
#
# Usage:
#   bash tests/terraform/test-terraform.sh
#
# Exit code: 0 if no FAIL (fmt or validate) was recorded, 1 otherwise.
# SKIP does not fail the run.
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_ROOT="$REPO_ROOT/terraform"
TIMEOUT_SECS="${TF_TEST_INIT_TIMEOUT:-60}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform executable not found on PATH." >&2
  exit 2
fi

echo "== Terraform static tests =="
echo "Terraform: $(terraform -version | head -1)"
echo "Root: $TF_ROOT"
echo "Init timeout per directory: ${TIMEOUT_SECS}s (offline environments will SKIP validate)"
echo

declare -a RESULTS=()
FAIL_COUNT=0
SKIP_COUNT=0
PASS_COUNT=0
DIR_COUNT=0

# Collect every directory under terraform/modules/* and
# terraform/environments/* that directly contains at least one *.tf file.
# (environments/{dev,staging,prod} may still be empty while another track
# is populating them in parallel — those are skipped, not failed.)
mapfile -t TARGET_DIRS < <(
  {
    find "$TF_ROOT/modules" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
    find "$TF_ROOT/environments" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
  } | sort
)

for dir in "${TARGET_DIRS[@]}"; do
  name="${dir#"$TF_ROOT"/}"
  tf_file_count=$(find "$dir" -maxdepth 1 -name "*.tf" | wc -l | tr -d ' ')

  if [ "$tf_file_count" -eq 0 ]; then
    echo "-- $name: no *.tf files yet, skipping (likely still being built by another track)"
    RESULTS+=("SKIP|$name|no .tf files")
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  DIR_COUNT=$((DIR_COUNT + 1))
  echo "-- $name"

  # --- fmt ------------------------------------------------------------
  fmt_output=$(cd "$dir" && terraform fmt -check -diff -no-color 2>&1)
  fmt_status=$?
  if [ $fmt_status -eq 0 ]; then
    echo "   fmt:      PASS"
    fmt_result="PASS"
  else
    echo "   fmt:      FAIL (files not formatted per 'terraform fmt')"
    echo "$fmt_output" | sed 's/^/     /'
    fmt_result="FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # --- validate (needs providers -> needs init) ------------------------
  init_log=$(mktemp)
  ( cd "$dir" && timeout "$TIMEOUT_SECS" terraform init -backend=false -input=false -no-color ) >"$init_log" 2>&1
  init_status=$?

  if [ $init_status -ne 0 ]; then
    echo "   validate: SKIP (terraform init could not complete — likely no internet access to the Terraform Registry in this environment)"
    tail -5 "$init_log" | sed 's/^/     /'
    validate_result="SKIP"
    SKIP_COUNT=$((SKIP_COUNT + 1))
  else
    validate_output=$(cd "$dir" && terraform validate -no-color 2>&1)
    validate_status=$?
    if [ $validate_status -eq 0 ]; then
      echo "   validate: PASS"
      validate_result="PASS"
    else
      echo "   validate: FAIL"
      echo "$validate_output" | sed 's/^/     /'
      validate_result="FAIL"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
  rm -f "$init_log"
  # Clean up local init artifacts so the working tree stays clean for git.
  rm -rf "$dir/.terraform" "$dir/.terraform.lock.hcl"

  RESULTS+=("$fmt_result/$validate_result|$name|fmt=$fmt_result validate=$validate_result")
  if [ "$fmt_result" = "PASS" ] && { [ "$validate_result" = "PASS" ] || [ "$validate_result" = "SKIP" ]; }; then
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
  echo
done

echo "== Summary =="
printf '%s\n' "${RESULTS[@]}" | column -t -s '|' 2>/dev/null || printf '%s\n' "${RESULTS[@]}"
echo
echo "Directories checked: $DIR_COUNT | fmt/validate FAILs: $FAIL_COUNT | SKIPPED (no .tf or offline): $SKIP_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi

echo "RESULT: PASS"
exit 0
