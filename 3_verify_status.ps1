<#
.SYNOPSIS
    killSlop // VERIFICATION
    
.DESCRIPTION
    Post-execution status check.
    1. Audits execution logs.
    2. Scans for residual processes.
    3. Validates service configuration.

.NOTES
    PROJECT: killSlop
    VERSION: 0.0.1
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

$LogPath = "C:\DefenderKill\killSlop_log.txt"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   killSlop v0.0.1 // VERIFICATION" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. LOG AUDIT
if (Test-Path $LogPath) {
    Write-Host "[INFO] LOG FILE RETRIEVED:" -ForegroundColor Gray
    Get-Content $LogPath | Select-Object -Last 5 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
} else {
    Write-Warning "[WARN] LOG FILE NOT FOUND."
}

# 2. PROCESS AUDIT
Write-Host "`n[INFO] SCANNING MEMORY..." -ForegroundColor Gray
$Procs = Get-Process -Name "MsMpEng", "NisSrv", "MsSense" -ErrorAction SilentlyContinue

if ($Procs) {
    Write-Host "[FAIL] ACTIVE PROCESSES DETECTED:" -ForegroundColor Red
    $Procs | Format-Table Id, ProcessName, CPU -AutoSize
} else {
    Write-Host "[PASS] MEMORY CLEAN." -ForegroundColor Green
}

# 3. SERVICE CONFIGURATION AUDIT
Write-Host "`n[INFO] AUDITING SERVICE CONFIGURATION..." -ForegroundColor Gray
$Services = @("WinDefend", "Sense", "WdFilter", "WdNisSvc", "SgrmBroker", "MDCoreSvc", "webthreatdefusersvc", "SenseCncProxy")

foreach ($SvcName in $Services) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    
    if ($Svc) {
        $RegStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName" -ErrorAction SilentlyContinue).Start
        
        $Str = "   {0,-15} | STATE: {1,-10} | START_TYPE: {2}" -f $SvcName, $Svc.Status, $RegStart
        
        if ($Svc.Status -eq 'Running' -or $RegStart -ne 4) {
            Write-Host $Str -ForegroundColor Red
        } else {
            Write-Host $Str -ForegroundColor Green
        }
    } else {
        Write-Host ("   {0,-15} | NOT INSTALLED" -f $SvcName) -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "VERIFICATION COMPLETE." -ForegroundColor Cyan
Pause
