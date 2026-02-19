<#
.SYNOPSIS
    killSlop // VERIFICATION

.DESCRIPTION
    Post-execution status check (SOTA).
    1. Deep Log Audit (Heuristic Analysis).
    2. Scans for residual processes.
    3. Validates service configuration matches target state (Disabled/4).

.NOTES
    PROJECT: killSlop
    VERSION: 0.1.1
#>

$LogPath = "C:\DefenderKill\killSlop_log.txt"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   killSlop v0.1.1 // VERIFICATION (DEEP DIVE)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. DEEP LOG AUDIT
if (Test-Path $LogPath) {
    Write-Host "[INFO] ANALYZING LOG INTEGRITY..." -ForegroundColor Gray
    $LogContent = Get-Content $LogPath

    $Errors = $LogContent | Where-Object { $_ -match "ERROR" -or $_ -match "FAIL" -or $_ -match "FATAL" -or $_ -match "Exception" }
    $Success = $LogContent | Where-Object { $_ -match "Service Disabled" -or $_ -match "Policy Applied" }

    if ($Errors) {
        Write-Host "[WARN] ANOMALIES DETECTED IN LOGS:" -ForegroundColor Yellow
        $Errors | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    } else {
        Write-Host "[PASS] LOGS CLEAN (No recorded errors)." -ForegroundColor Green
    }

    Write-Host "   - Operations Logged: $($LogContent.Count)" -ForegroundColor Gray
    Write-Host "   - Successful Actions: $($Success.Count)" -ForegroundColor Gray
} else {
    Write-Warning "[WARN] LOG FILE NOT FOUND ($LogPath)."
}

# 2. PROCESS AUDIT
Write-Host "`n[INFO] SCANNING MEMORY RESIDUE..." -ForegroundColor Gray
$Procs = Get-Process -Name "MsMpEng", "NisSrv", "MsSense", "MpCmdRun", "SecurityHealthSystray" -ErrorAction SilentlyContinue

if ($Procs) {
    Write-Host "[FAIL] ACTIVE THREAT HANDLERS DETECTED:" -ForegroundColor Red
    $Procs | Format-Table Id, ProcessName, CPU, NPM -AutoSize
    Write-Host "   -> CRITICAL: Kernel bypass may have failed." -ForegroundColor Red
} else {
    Write-Host "[PASS] MEMORY CLEAN (No Defender processes)." -ForegroundColor Green
}

# 3. SERVICE CONFIGURATION AUDIT
Write-Host "`n[INFO] AUDITING KERNEL SERVICE CONFIGURATION..." -ForegroundColor Gray
# SYNC-REQUIRED: This list is mirrored in 2_kill_defender.ps1.
# Any modification there MUST be reflected here and vice versa.
$Services = @(
    "WinDefend",   # Antivirus Service
    "Sense",       # Advanced Threat Protection
    "WdFilter",    # Mini-Filter
    "WdNisSvc",    # Network Inspection Service
    "WdNisDrv",    # Network Inspection Driver
    "wscsvc",      # Security Center
    "SgrmBroker",  # System Guard Broker
    "SgrmAgent",   # System Guard Agent
    "MDCoreSvc",   # Microsoft Defender Core (24H2)
    "webthreatdefusersvc", # Web Threat Defense (24H2)
    "SenseCncProxy" # Defender for Endpoint C&C (24H2)
)

$StartTypeMap  = @{ 0 = 'Boot'; 1 = 'System'; 2 = 'Automatic'; 3 = 'Manual'; 4 = 'Disabled' }
$CountDisabled = 0
$CountRunning  = 0
$CountMissing  = 0

foreach ($SvcName in $Services) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue

    $StatusStr = "MISSING"
    $StartType = "UNKNOWN"
    $Color = "DarkGray"

    if ($Svc) {
        $RegStart = $null
        try {
            # Direct Registry Query for Truth regarding Start Type
            $RegStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName" -ErrorAction Stop).Start
            if ($null -ne $RegStart) {
                $mapped = $StartTypeMap[[int]$RegStart]
                $StartType = if ($null -ne $mapped) { $mapped } else { "UNKNOWN($RegStart)" }
            } else { $StartType = "MISSING" }
        } catch {
            $StartType = "ACCESS_DENIED/MISSING"
        }

        $StatusStr = $Svc.Status

        if ($Svc.Status -eq 'Running' -or ($null -ne $RegStart -and $RegStart -ne 4)) {
            $Color = "Red" # Failed state
            if ($Svc.Status -eq 'Running') { $CountRunning++ }
        } elseif ($RegStart -eq 4) {
            $Color = "Green" # Compliance
            $CountDisabled++
        }
    } else {
        $CountMissing++
    }

    Write-Host ("   {0,-22} | STATE: {1,-10} | START_TYPE: {2}" -f $SvcName, $StatusStr, $StartType) -ForegroundColor $Color
}

$Total    = $Services.Count
$SummaryColor = if ($CountRunning -gt 0) { "Red" } else { "Green" }
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ("   SUMMARY: {0}/{1} DISABLED | {2} RUNNING (ALERT) | {3} MISSING" -f $CountDisabled, $Total, $CountRunning, $CountMissing) -ForegroundColor $SummaryColor
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "VERIFICATION CYCLE COMPLETE." -ForegroundColor Cyan
Pause
