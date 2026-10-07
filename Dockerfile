# Automation Controller image — packages automation/ (CLI + Prometheus
# exporter) so helm/automation-controller/ has something real to deploy.
# Until this change, the Helm chart referenced
# ghcr.io/yuri-fernando/automation-controller:0.1.0 and probed
# /healthz+/ready on :8080, but no Dockerfile/process in the repo actually
# built or served that — see CHANGELOG.md.
#
# Not published to a registry (no CI job pushes this — see README "o que
# NÃO foi feito"). Built and scanned locally/in CI only, for the Trivy/SBOM
# and Kyverno-admission gates (see security/ and policies/).

FROM python:3.11-slim AS base

# --- Deterministic, minimal runtime image -----------------------------
WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir --no-compile -r requirements.txt \
    && rm -rf /root/.cache/pip

COPY automation/ ./automation/
# automation/reports/slo_report.py's DEFAULT_DEMO_DATA_PATH resolves to
# <repo_root>/dashboard/js/data.example.json — needed so the exporter's
# demo-mode fallback (no MySQL reachable) has data to serve.
COPY dashboard/js/data.example.json ./dashboard/js/data.example.json

# Non-root user (required by policies/kyverno/require-nonroot-and-limits.yaml
# — runAsNonRoot: true — and checked again at the Pod level in k8s).
RUN addgroup --system --gid 10001 app \
    && adduser --system --uid 10001 --gid 10001 --no-create-home app \
    && chown -R app:app /app
USER app:app

EXPOSE 8080

# No HEALTHCHECK instruction: liveness/readiness are owned by the
# Kubernetes probes in helm/automation-controller/templates/deployment.yaml
# (/healthz, /ready), not by Docker itself, to avoid two independent and
# potentially-disagreeing health signals.

ENTRYPOINT ["python", "-m", "automation.cli.main", "metrics-serve"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
