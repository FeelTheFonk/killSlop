<#
.SYNOPSIS
    killSlop // PREPARATION
    
.DESCRIPTION
    System preparation sequence.
    1. Validates Administrative Privileges.
    2. Enforces Windows 11 24H2 Safety Checks (Safe Mode PIN limitation).
    3. Verifies Tamper Protection Status.
    4. Generates System Restore Point.
    5. Stages Payload to C:\DefenderKill.
    6. Injects RunOnce Trigger with Asterisk (*) for Safe Mode Execution.
    7. Configures Boot Configuration Data (BCD) for Safe Boot Network.

.NOTES
    PROJECT: killSlop
    VERSION: 0.0.1
    PLATFORM: Windows 11 (23H2 / 24H2)
#>

# CONFIGURATION
$ErrorActionPreference = "Stop"
$PayloadSource = Join-Path $PSScriptRoot "2_kill_defender.ps1"
$StagingDir = "C:\DefenderKill"
$StagingPath = Join-Path $StagingDir "2_kill_defender.ps1"

# 0. PRIVILEGE CHECK
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "FATAL: Administrative privileges required."
    Exit
}

Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   killSlop v0.0.1 // PREPARATION" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. 24H2 SAFETY INTERLOCK
Write-Host "[WAIT] INITIATING SAFETY INTERLOCK (WINDOWS 11 24H2)..." -ForegroundColor Yellow
Write-Host "NOTICE: Windows 11 24H2 may disable Hello PIN in Safe Mode."
Write-Host "REQ-1: Valid Password for Microsoft/Local Account (PIN IS NOT SUFFICIENT)."
Write-Host "REQ-2: Tamper Protection DISABLED via Windows Security UI."
Write-Host ""
$UserAck = Read-Host "TYPE 'I HAVE MY PASSWORD' TO CONFIRM PRE-REQUISITES"

if ($UserAck -ne "I HAVE MY PASSWORD") {
    Write-Warning "ABORTED: Safety interlock triggered. Code 0xUSER_CANCEL."
    Exit
}

# 2. TAMPER PROTECTION VERIFICATION
Write-Host "[INFO] VERIFYING TAMPER PROTECTION STATUS..." -ForegroundColor Gray
try {
    $MpStatus = Get-MpComputerStatus
    if ($MpStatus.IsTamperProtected -eq $true) {
        Write-Host "[FAIL] TAMPER PROTECTION IS ACTIVE." -ForegroundColor Red
        Write-Host "ACTION: Disable manually in Windows Security > Virus & Threat Protection." -ForegroundColor Red
        Exit
    }
    Write-Host "[PASS] TAMPER PROTECTION IS DISABLED." -ForegroundColor Green
}
catch {
    Write-Warning "[WARN] UNABLE TO QUERY MPSTATUS. ASSUMING MANUAL VERIFICATION."
}

# 3. SYSTEM SNAPSHOT
Write-Host "[INFO] GENERATING RESTORE POINT..." -ForegroundColor Gray
try {
    Checkpoint-Computer -Description "Checkpoint_killSlop_v0.0.1" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "[PASS] RESTORE POINT CREATED." -ForegroundColor Green
}
catch {
    Write-Warning "[WARN] RESTORE POINT CREATION FAILED. PROCEEDING AT OWN RISK."
}

# 4. PAYLOAD DEPLOYMENT
Write-Host "[INFO] DEPLOYING PAYLOAD..." -ForegroundColor Gray
if (!(Test-Path $StagingDir)) { New-Item -ItemType Directory -Path $StagingDir | Out-Null }
Copy-Item -Path $PayloadSource -Destination $StagingPath -Force
Write-Host "[PASS] PAYLOAD STAGED: $StagingPath" -ForegroundColor Green

# 5. REGISTRY INJECTION (SAFE MODE VECTOR)
Write-Host "[INFO] INJECTING RUNONCE TRIGGER..." -ForegroundColor Gray
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$Command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Maximized -File $StagingPath"
# Asterisk (*) forces execution in Safe Mode
Set-ItemProperty -Path $RegPath -Name "*killSlop_Payload" -Value $Command
Write-Host "[PASS] INJECTION SUCCESSFUL." -ForegroundColor Green

# 6. BOOT CONFIGURATION
Write-Host "[INFO] CONFIGURING BOOT SEQUENCE (SAFEMODE_NETWORK)..." -ForegroundColor Gray
& bcdedit.exe /set "{current}" safeboot network | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] BCD MODIFICATION FAILED." -ForegroundColor Red
    Exit
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Magenta
Write-Host "   SYSTEM REBOOT INITIATED" -ForegroundColor Magenta
Write-Host "======================================================================" -ForegroundColor Magenta
Start-Sleep -Seconds 5
Restart-Computer -Force
