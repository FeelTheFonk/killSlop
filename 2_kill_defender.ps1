<#
.SYNOPSIS
    killSlop // PAYLOAD
    
.DESCRIPTION
    Executed within Safe Mode environment.
    1. Seizes ownership of system-protected registry keys (ACL Bypass).
    2. Modifies start type of target services to 'Disabled' (4).
    3. Disables scheduled maintenance tasks.
    4. Injects Group Policy overrides.
    5. Restores normal boot configuration.
    
.NOTES
    PROJECT: killSlop
    VERSION: 0.0.1
    PLATFORM: Windows 11 (Safe Mode)
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "C:\DefenderKill\killSlop_log.txt"

# --- LOGGING SUBSYSTEM ---
function Write-Log {
    param ( [string]$Message, [string]$Level = "INFO", [string]$Color = "Gray" )
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Time] [$Level] $Message"
    Add-Content -Path $LogPath -Value $Line
    Write-Host $Message -ForegroundColor $Color
}

# --- ACL BYPASS SUBSYSTEM ---
function Grant-RegistryAccess {
    param ( [string]$KeyPath )
    if (!(Test-Path $KeyPath)) { return }
    
    Write-Log "Adjusting ACLs for: $KeyPath" "ACL" "DarkGray"
    try {
        # Open Key with TakeOwnership Right
        $RegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath.Replace("HKLM:\", ""), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
        $ACL = $RegKey.GetAccessControl()
        $Admin = New-Object System.Security.Principal.NTAccount("Administrators")
        
        # Take Ownership
        $ACL.SetOwner($Admin)
        $RegKey.SetAccessControl($ACL)
        
        # Grant Full Control
        $RegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath.Replace("HKLM:\", ""), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
        $ACL = $RegKey.GetAccessControl()
        $Rule = New-Object System.Security.AccessControl.RegistryAccessRule($Admin, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $ACL.SetAccessRule($Rule)
        $RegKey.SetAccessControl($ACL)
    }
    catch {
        Write-Log "ACL Modification Failed: $_" "ERR" "Yellow"
    }
}

# --- MAIN EXECUTION BLOCK ---
try {
    Start-Transcript -Path $LogPath -Append | Out-Null
    Write-Log "=== killSlop v0.0.1 INITIATED ===" "INIT" "Magenta"

    # 1. SERVICE CONFIGURATION
    Write-Log "Configuring Services..." "PROC" "Cyan"
    $TargetServices = @(
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

    foreach ($Svc in $TargetServices) {
        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$Svc"
        if (Test-Path $RegPath) {
            Grant-RegistryAccess -KeyPath $RegPath
            try {
                Set-ItemProperty -Path $RegPath -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
                Write-Log "Service Disabled: $Svc" "OK" "Green"
            } catch {
                Write-Log "Failed to Disable: $Svc ($_)" "FAIL" "Red"
            }
        } else {
            Write-Log "Service Not Found: $Svc" "SKIP" "DarkGray"
        }
    }

    # 2. TASK CONFIGURATION
    Write-Log "Configuring Scheduled Tasks..." "PROC" "Cyan"
    $TaskRoot = "\Microsoft\Windows\Windows Defender"
    Get-ScheduledTask -TaskPath "$TaskRoot\*" | Disable-ScheduledTask | Out-Null
    Write-Log "Tasks Disabled." "OK" "Green"

    # 3. POLICY CONFIGURATION
    Write-Log "Configuring Group Policies..." "PROC" "Cyan"
    $PolicyPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
    )
    foreach ($Path in $PolicyPaths) { 
        if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } 
    }

    $Overrides = @{
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" = @{
            "DisableAntiSpyware"=1; "DisableRealtimeMonitoring"=1; "DisableAntiVirus"=1; "ServiceKeepAlive"=0
        };
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" = @{
            "DisableBehaviorMonitoring"=1; "DisableOnAccessProtection"=1; "DisableScanOnRealtimeEnable"=1; "DisableIOAVProtection"=1
        };
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" = @{
            "SpynetReporting"=0; "SubmitSamplesConsent"=2
        }
    }

    foreach ($Key in $Overrides.Keys) {
        foreach ($Val in $Overrides[$Key].Keys) {
            Set-ItemProperty -Path $Key -Name $Val -Value $Overrides[$Key][$Val] -Type DWord
            Write-Log "Policy Applied: $Key\$Val" "POL" "Yellow"
        }
    }

}
catch {
    Write-Log "CRITICAL RUNTIME ERROR: $_" "FATAL" "Red"
}
finally {
    # 4. RESTORATION & EGRESS
    Write-Log "Restoring Boot Configuration..." "PROC" "Cyan"
    & bcdedit.exe /deletevalue "{current}" safeboot
    
    Write-Log "=== PROTOCOL COMPLETE. REBOOTING. ===" "EXIT" "Magenta"
    Stop-Transcript | Out-Null
    Start-Sleep -Seconds 3
    Restart-Computer -Force
}
