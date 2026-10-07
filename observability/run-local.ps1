# =============================================================================
# observability/run-local.ps1 — PowerShell equivalent of run-local.sh.
# See that file's header comment for why this staging step exists
# (Docker Desktop bind mounts under a cloud-synced drive are unreliable).
#
# Usage:
#   pwsh observability/run-local.ps1 -Action up
#   pwsh observability/run-local.ps1 -Action down
# =============================================================================
param(
    [ValidateSet("up", "down", "logs", "ps")]
    [string]$Action = "up",

    [string]$StageDir = "$env:SystemDrive\tmp\enterprise-automation-observability",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $StageDir)) {
    New-Item -ItemType Directory -Path $StageDir -Force | Out-Null
}

foreach ($dir in @("prometheus", "grafana", "loki", "promtail")) {
    $dest = Join-Path $StageDir $dir
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Path (Join-Path $ScriptDir $dir) -Destination $dest
}

$env:OBS_CONFIG_DIR = $StageDir

$composeFile = Join-Path $ScriptDir "docker-compose.yml"

switch ($Action) {
    "up"    { docker compose -f $composeFile up -d @ExtraArgs }
    "down"  { docker compose -f $composeFile down @ExtraArgs }
    "logs"  { docker compose -f $composeFile logs @ExtraArgs }
    "ps"    { docker compose -f $composeFile ps @ExtraArgs }
}
