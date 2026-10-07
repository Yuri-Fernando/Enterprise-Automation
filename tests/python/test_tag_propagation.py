"""Static test: every taggable resource in terraform/modules/* must
propagate the caller-supplied tags/labels variable, not just hardcode its
own Name tag.

This is a real regression test for cost/tagging hygiene (audit item
"custo/tagging/budget" — see PROJECT_LOG.md): tagging is what lets
terraform/modules/budget's AWS Budgets cost_filter (TagKeyValue on the
Project tag) actually attribute spend to this project instead of to
"everything in the account". If a future resource is added with a literal
`tags = { Name = "..." }` instead of `tags = merge(var.tags, { ... })`, the
budget filter silently stops seeing it. This test catches that by parsing
the real .tf files in the repo (regex over the actual main.tf contents,
not a hand-copied snapshot), so it stays accurate as modules change.

Does NOT use terraform plan/apply (no AWS needed) — this is a source-level
convention check, deliberately cheap and always-on.
"""
from __future__ import annotations

import pathlib
import re

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
MODULES_DIR = REPO_ROOT / "terraform" / "modules"

# aws_budgets_budget and a couple of other resource types genuinely don't
# support a `tags` argument in the AWS provider — not a convention
# violation, just not taggable. Exclude the *module directories* that are
# known to be fully non-taggable rather than guessing per-resource.
NON_TAGGABLE_MODULES = {"budget"}

TAGS_LINE_RE = re.compile(r"^\s*tags\s*=\s*(.+)$")
LABELS_LINE_RE = re.compile(r"^\s*labels\s*=\s*(.+)$")


def _aws_module_dirs():
    return [
        d for d in MODULES_DIR.iterdir()
        if d.is_dir() and d.name not in NON_TAGGABLE_MODULES and d.name != "gcp"
    ]


def test_every_aws_module_has_at_least_one_taggable_resource():
    """Sanity check that this test isn't vacuously passing because it
    found zero `tags = ` lines anywhere (e.g. a path typo)."""
    total_tags_lines = 0
    for module_dir in _aws_module_dirs():
        main_tf = module_dir / "main.tf"
        if not main_tf.exists():
            continue
        for line in main_tf.read_text(encoding="utf-8").splitlines():
            if TAGS_LINE_RE.match(line):
                total_tags_lines += 1
    assert total_tags_lines > 5, (
        f"expected multiple `tags = ...` lines across terraform/modules/*, found {total_tags_lines} "
        "-- did the module layout change?"
    )


def test_every_aws_module_tags_line_propagates_var_tags():
    violations = []
    for module_dir in _aws_module_dirs():
        main_tf = module_dir / "main.tf"
        if not main_tf.exists():
            continue
        for lineno, line in enumerate(main_tf.read_text(encoding="utf-8").splitlines(), start=1):
            match = TAGS_LINE_RE.match(line)
            if not match:
                continue
            expr = match.group(1)
            if "var.tags" not in expr:
                violations.append(f"{module_dir.name}/main.tf:{lineno}: {line.strip()!r}")

    assert not violations, (
        "found `tags = ...` assignment(s) that do not propagate var.tags "
        "(breaks cost attribution via terraform/modules/budget's "
        "TagKeyValue cost_filter):\n" + "\n".join(violations)
    )


def test_gcp_module_labels_propagate_var_labels():
    """The GCP module uses GCP's `labels` (lowercase) instead of AWS
    `tags`, but the same propagation convention applies — see
    terraform/modules/gcp/README.md's tagging-convention section."""
    gcp_main_tf = MODULES_DIR / "gcp" / "main.tf"
    assert gcp_main_tf.exists(), "terraform/modules/gcp/main.tf not found -- did the module move?"

    content = gcp_main_tf.read_text(encoding="utf-8")

    # locals.common_labels must itself merge var.labels (the indirection
    # every `labels = local.common_labels` line below relies on).
    assert re.search(r"common_labels\s*=\s*merge\(var\.labels", content), (
        "terraform/modules/gcp/main.tf's common_labels local no longer merges var.labels"
    )

    violations = []
    for lineno, line in enumerate(content.splitlines(), start=1):
        match = LABELS_LINE_RE.match(line)
        if not match:
            continue
        expr = match.group(1)
        if "local.common_labels" not in expr and "var.labels" not in expr:
            violations.append(f"gcp/main.tf:{lineno}: {line.strip()!r}")

    assert not violations, (
        "found `labels = ...` assignment(s) in the GCP module that don't propagate "
        "var.labels / local.common_labels:\n" + "\n".join(violations)
    )


def test_providers_tf_default_tags_match_budget_cost_filter_key():
    """terraform/providers.tf's default_tags key the budget module filters
    on (var.cost_filter_tag_key, default "Project") must actually be one
    of the keys providers.tf applies account-wide — otherwise the budget
    would filter on a tag that's never present and silently track $0."""
    providers_tf = (REPO_ROOT / "terraform" / "providers.tf").read_text(encoding="utf-8")
    budget_variables_tf = (MODULES_DIR / "budget" / "variables.tf").read_text(encoding="utf-8")

    default_match = re.search(r'cost_filter_tag_key"\s*\{\s*description[^}]*?default\s*=\s*"([^"]+)"', budget_variables_tf, re.S)
    assert default_match, "could not find cost_filter_tag_key's default in terraform/modules/budget/variables.tf"
    default_tag_key = default_match.group(1)

    assert re.search(rf"\b{re.escape(default_tag_key)}\s*=\s*var\.", providers_tf), (
        f"terraform/providers.tf's default_tags block no longer sets a '{default_tag_key}' key — "
        "terraform/modules/budget's cost_filter_tag_key default is now stale"
    )
