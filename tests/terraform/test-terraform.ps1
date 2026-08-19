<#
.SYNOPSIS
    Lightweight, no-cost static checks for the Terraform code in terraform/.

.DESCRIPTION
    PowerShell equivalent of test-terraform.sh, for native Windows use
    (no Git Bash required). Runs, per module/environment directory:
      1. `terraform fmt -check -diff`
      2. `terraform validate` (after a local `terraform init -backend=false`)

    Deliberately does NOT run `terraform plan` or `terraform apply` (see
    PROJECT_LOG.md: "Nenhum terraform apply automatico nesta fase").

    `terraform init` needs internet access to download the AWS provider.
    If it cannot finish within -InitTimeoutSeconds, validate is reported
    as SKIP for that directory instead of failing the whole run.

.PARAMETER InitTimeoutSeconds
    Max seconds to wait for `terraform init` per directory. Default 60.

.EXAMPLE
    pwsh -File tests/terraform/test-terraform.ps1
#>

param(
    [int]$InitTimeoutSeconds = 60
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Resolve-Path (Join-Path $scriptDir "..\..")
$tfRoot    = Join-Path $repoRoot "terraform"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "terraform executable not found on PATH."
    exit 2
}

Write-Host "== Terraform static tests =="
Write-Host "Terraform: $((terraform -version | Select-Object -First 1))"
Write-Host "Root: $tfRoot"
Write-Host "Init timeout per directory: $InitTimeoutSeconds s (offline environments will SKIP validate)"
Write-Host ""

$results   = New-Object System.Collections.Generic.List[object]
$failCount = 0
$skipCount = 0
$dirCount  = 0

$targetDirs = @()
$targetDirs += Get-ChildItem -Path (Join-Path $tfRoot "modules") -Directory -ErrorAction SilentlyContinue
$targetDirs += Get-ChildItem -Path (Join-Path $tfRoot "environments") -Directory -ErrorAction SilentlyContinue
$targetDirs = $targetDirs | Sort-Object FullName

foreach ($dir in $targetDirs) {
    $relName = $dir.FullName.Substring($tfRoot.Length).TrimStart('\', '/')
    $tfFiles = Get-ChildItem -Path $dir.FullName -Filter "*.tf" -File -ErrorAction SilentlyContinue

    if (-not $tfFiles -or $tfFiles.Count -eq 0) {
        Write-Host "-- $relName : no *.tf files yet, skipping (likely still being built by another track)"
        $results.Add([pscustomobject]@{ Dir = $relName; Fmt = "-"; Validate = "-"; Note = "no .tf files" })
        $skipCount++
        continue
    }

    $dirCount++
    Write-Host "-- $relName"

    Push-Location $dir.FullName
    try {
        # --- fmt ---------------------------------------------------------
        $fmtOutput = & terraform fmt -check -diff -no-color 2>&1
        $fmtExit = $LASTEXITCODE
        if ($fmtExit -eq 0) {
            Write-Host "   fmt:      PASS"
            $fmtResult = "PASS"
        } else {
            Write-Host "   fmt:      FAIL (files not formatted per 'terraform fmt')"
            $fmtOutput | ForEach-Object { Write-Host "     $_" }
            $fmtResult = "FAIL"
            $failCount++
        }

        # --- validate (needs providers -> needs init) ---------------------
        $initJob = Start-Job -ScriptBlock {
            param($path)
            Set-Location $path
            terraform init -backend=false -input=false -no-color 2>&1
        } -ArgumentList $dir.FullName

        $completed = Wait-Job $initJob -Timeout $InitTimeoutSeconds
        if (-not $completed) {
            Stop-Job $initJob | Out-Null
            Write-Host "   validate: SKIP (terraform init timed out — likely no internet access to the Terraform Registry)"
            $validateResult = "SKIP"
            $skipCount++
        } else {
            $initOutput = Receive-Job $initJob
            $initExit = $initJob.State -eq "Completed"
            Remove-Job $initJob -Force | Out-Null

            if (-not $initExit) {
                Write-Host "   validate: SKIP (terraform init failed — likely no internet access to the Terraform Registry)"
                $initOutput | Select-Object -Last 5 | ForEach-Object { Write-Host "     $_" }
                $validateResult = "SKIP"
                $skipCount++
            } else {
                $validateOutput = & terraform validate -no-color 2>&1
                $validateExit = $LASTEXITCODE
                if ($validateExit -eq 0) {
                    Write-Host "   validate: PASS"
                    $validateResult = "PASS"
                } else {
                    Write-Host "   validate: FAIL"
                    $validateOutput | ForEach-Object { Write-Host "     $_" }
                    $validateResult = "FAIL"
                    $failCount++
                }
            }
        }

        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $dir.FullName ".terraform")
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $dir.FullName ".terraform.lock.hcl")

        $results.Add([pscustomobject]@{ Dir = $relName; Fmt = $fmtResult; Validate = $validateResult; Note = "" })
    } finally {
        Pop-Location
    }
    Write-Host ""
}

Write-Host "== Summary =="
$results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Directories checked: $dirCount | fmt/validate FAILs: $failCount | SKIPPED (no .tf or offline): $skipCount"

if ($failCount -gt 0) {
    Write-Host "RESULT: FAIL"
    exit 1
}

Write-Host "RESULT: PASS"
exit 0
