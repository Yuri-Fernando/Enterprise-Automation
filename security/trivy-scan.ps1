# =============================================================================
# security/trivy-scan.ps1 — PowerShell equivalent of trivy-scan.sh.
# See that file's header comment for full behavior/exit-code rationale.
#
# Usage:
#   pwsh security/trivy-scan.ps1
#   pwsh security/trivy-scan.ps1 -FsOnly
# =============================================================================
param(
    [switch]$FsOnly,
    [switch]$SkipImageBuild
)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ImageTag = "automation-controller:trivy-scan"
$SbomDir = Join-Path $RepoRoot "security\sbom"
$Fail = $false

if (-not (Get-Command trivy -ErrorAction SilentlyContinue)) {
    Write-Error "trivy executable not found on PATH."
    exit 2
}

New-Item -ItemType Directory -Force -Path $SbomDir | Out-Null

Write-Host "== Trivy: $(trivy --version | Select-Object -First 1) =="

Write-Host "`n-- 1/3: Filesystem scan (vulnerabilities + Dockerfile/Helm/K8s misconfigurations) --"
# terraform/ excluded -- already covered by Checkov. See trivy-scan.sh's
# comment for the full rationale.
trivy fs --scanners vuln,misconfig --severity CRITICAL,HIGH,MEDIUM,LOW --skip-dirs terraform --exit-code 0 $RepoRoot |
    Tee-Object -FilePath (Join-Path $SbomDir "trivy-fs-report.txt")

trivy fs --scanners vuln --severity CRITICAL --exit-code 1 --quiet --skip-dirs terraform $RepoRoot | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   CRITICAL filesystem vulnerabilities found -- see trivy-fs-report.txt above."
    $Fail = $true
} else {
    Write-Host "   No CRITICAL filesystem vulnerabilities."
}

if (-not $FsOnly) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Warning "docker not found on PATH -- skipping image scan + SBOM."
    } else {
        Write-Host "`n-- 2/3: Container image scan ($ImageTag) --"
        if (-not $SkipImageBuild) {
            docker build -t $ImageTag -f (Join-Path $RepoRoot "Dockerfile") $RepoRoot
        }
        trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --exit-code 0 $ImageTag |
            Tee-Object -FilePath (Join-Path $SbomDir "trivy-image-report.txt")

        trivy image --severity CRITICAL --exit-code 1 --quiet $ImageTag | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   CRITICAL image vulnerabilities found -- see trivy-image-report.txt above."
            $Fail = $true
        } else {
            Write-Host "   No CRITICAL image vulnerabilities."
        }

        Write-Host "`n-- 3/3: SBOM generation (CycloneDX via trivy) --"
        trivy image --format cyclonedx --output (Join-Path $SbomDir "automation-controller.cdx.json") $ImageTag
        Write-Host "   SBOM written to security/sbom/automation-controller.cdx.json"

        if (Get-Command syft -ErrorAction SilentlyContinue) {
            syft $ImageTag -o ("spdx-json=" + (Join-Path $SbomDir "automation-controller.spdx.json")) | Out-Null
            Write-Host "   SBOM written to security/sbom/automation-controller.spdx.json (syft, SPDX format)"
        } else {
            Write-Warning "syft not found on PATH -- skipping the SPDX-format SBOM."
        }
    }
}

if ($Fail) {
    Write-Host "`nRESULT: FAIL (CRITICAL findings present)"
    exit 1
}
Write-Host "`nRESULT: PASS (no CRITICAL findings)"
exit 0
