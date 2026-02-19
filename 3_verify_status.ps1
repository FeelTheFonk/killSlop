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
    VERSION: 0.0.1
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Verification tool intended for console output")]
param()

$LogPath = "C:\DefenderKill\killSlop_log.txt"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   killSlop v0.0.1 // VERIFICATION (DEEP DIVE)" -ForegroundColor Cyan
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
    Write-Host "   - Sucessful Actions: $($Success.Count)" -ForegroundColor Gray
} else {
    Write-Warning "[WARN] LOG FILE NOT FOUND ($LogPath)."
}

# 2. PROCESS AUDIT
Write-Host "`n[INFO] SCANNING MEMORY RESIDUE..." -ForegroundColor Gray
$Procs = Get-Process -Name "MsMpEng", "NisSrv", "MsSense" -ErrorAction SilentlyContinue

if ($Procs) {
    Write-Host "[FAIL] ACTIVE THREAT HANDLERS DETECTED:" -ForegroundColor Red
    $Procs | Format-Table Id, ProcessName, CPU, NPM -AutoSize
    Write-Host "   -> CRITICAL: Kernel bypass may have failed." -ForegroundColor Red
} else {
    Write-Host "[PASS] MEMORY CLEAN (No Defender processes)." -ForegroundColor Green
}

# 3. SERVICE CONFIGURATION AUDIT
Write-Host "`n[INFO] AUDITING KERNEL SERVICE CONFIGURATION..." -ForegroundColor Gray
# Synchronized List with 2_kill_defender.ps1
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

foreach ($SvcName in $Services) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue

    $StatusStr = "MISSING"
    $StartType = "UNKNOWN"
    $Color = "DarkGray"

    if ($Svc) {
        try {
            # Direct Registry Query for Truth regarding Start Type
            $RegStart = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$SvcName" -ErrorAction Stop).Start
            $StartType = $RegStart
        } catch {
            $StartType = "ACCESS_DENIED/MISSING"
        }

        $StatusStr = $Svc.Status

        if ($Svc.Status -eq 'Running' -or ($RegStart -ne 4 -and $null -ne $RegStart)) {
            $Color = "Red" # Failed state
        } elseif ($RegStart -eq 4) {
            $Color = "Green" # Compliance
        }
    }

    Write-Host ("   {0,-20} | STATE: {1,-10} | START_TYPE: {2}" -f $SvcName, $StatusStr, $StartType) -ForegroundColor $Color
}

Write-Host ""
Write-Host "VERIFICATION CYCLE COMPLETE." -ForegroundColor Cyan
Pause
