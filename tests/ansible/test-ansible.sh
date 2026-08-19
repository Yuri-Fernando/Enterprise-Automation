#!/usr/bin/env bash
# =============================================================================
# tests/ansible/test-ansible.sh
#
# Local lint/syntax checks for ansible/ that work on Windows:
#   1. `yamllint` over every *.yml/*.yaml file under ansible/ — always runs,
#      pure-Python, no POSIX dependency.
#   2. `ansible-playbook --syntax-check` for every playbook under
#      ansible/playbooks/ — attempted, but on native Windows Python the
#      `ansible` CLI itself fails to import (os.get_blocking is POSIX-only,
#      see README.md in this directory), so this step is expected to be
#      SKIPPED locally on Windows and to run for real only on Linux/WSL or
#      in the GitHub Actions Ubuntu runner (already the documented decision
#      in PROJECT_LOG.md for ansible-lint/checkov).
#
# Never runs playbooks for real (no `ansible-playbook` without
# --syntax-check / --check, no `ansible-playbook --check` against real
# hosts) — this is a static check only.
#
# Usage:
#   bash tests/ansible/test-ansible.sh
#
# Exit code: 0 if yamllint passed (and syntax-check passed when available),
# 1 if either found real errors. A skipped syntax-check does not fail the run.
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANSIBLE_ROOT="$REPO_ROOT/ansible"

FAIL_COUNT=0

echo "== Ansible static tests =="
echo "Root: $ANSIBLE_ROOT"
echo

# --------------------------------------------------------------- yamllint
if command -v yamllint >/dev/null 2>&1; then
  echo "-- yamllint (all *.yml/*.yaml under ansible/)"
  yaml_files=$(find "$ANSIBLE_ROOT" -type f \( -name "*.yml" -o -name "*.yaml" \))
  if [ -z "$yaml_files" ]; then
    echo "   No YAML files found yet under ansible/. SKIP."
  else
    yamllint_output=$(yamllint -d "{extends: default, rules: {line-length: {max: 160}, truthy: disable}}" "$ANSIBLE_ROOT" 2>&1)
    yamllint_status=$?
    if [ $yamllint_status -eq 0 ]; then
      echo "   PASS — no lint issues found"
    else
      echo "   FAIL"
      echo "$yamllint_output" | sed 's/^/     /'
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
else
  echo "-- yamllint: not installed, SKIP (pip install yamllint)"
fi
echo

# --------------------------------------------------------- syntax-check
echo "-- ansible-playbook --syntax-check (ansible/playbooks/*.yml)"
if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "   ansible-playbook not found on PATH. SKIP."
else
  # Windows note: on native Windows Python, `import ansible.cli` fails with
  # "AttributeError: module 'os' has no attribute 'get_blocking'" because
  # that call is POSIX-only. Detect that specific failure mode and report a
  # clean SKIP instead of a wall of traceback.
  probe_output=$(ansible-playbook --version 2>&1)
  if echo "$probe_output" | grep -qi "get_blocking"; then
    echo "   SKIP — ansible CLI cannot run on this Python/OS (os.get_blocking is POSIX-only)."
    echo "   This is expected on native Windows; runs for real in WSL/Linux/CI (Ubuntu runner)."
    echo "   See tests/ansible/README.md."
  else
    playbooks=$(find "$ANSIBLE_ROOT/playbooks" -maxdepth 1 -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null)
    if [ -z "$playbooks" ]; then
      echo "   No playbooks found yet under ansible/playbooks/. SKIP."
    else
      for pb in $playbooks; do
        name="${pb#"$ANSIBLE_ROOT"/}"
        echo "   -- $name"
        out=$(ansible-playbook --syntax-check -i "$ANSIBLE_ROOT/inventory/hosts.example.ini" "$pb" 2>&1)
        status=$?
        if [ $status -eq 0 ]; then
          echo "      PASS"
        else
          echo "      FAIL"
          echo "$out" | sed 's/^/        /'
          FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
      done
    fi
  fi
fi
echo

echo "== Summary =="
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: FAIL ($FAIL_COUNT check(s) failed)"
  exit 1
fi

echo "RESULT: PASS (see SKIP notes above for checks that need CI/WSL to run for real)"
exit 0
