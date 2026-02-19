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
    VERSION: 0.0.3
    PLATFORM: Windows 11 (Safe Mode)
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "C:\DefenderKill\killSlop_log.txt"

# --- LOGGING SUBSYSTEM ---
function Write-KillSlopLog {
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

    Write-KillSlopLog "Adjusting ACLs for: $KeyPath" "ACL" "DarkGray"
    try {
        # Get Localized Administrators Group Name via SID (S-1-5-32-544)
        $AdminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
        $Admin = $AdminSID.Translate([System.Security.Principal.NTAccount])

        # Open Key with TakeOwnership Right
        $RegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($KeyPath.Replace("HKLM:\", ""), [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
        $ACL = $RegKey.GetAccessControl()

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
        Write-KillSlopLog "ACL Modification Failed: $_" "ERR" "Yellow"
    }
}

# --- MAIN EXECUTION BLOCK ---
try {
    if (!(Test-Path (Split-Path $LogPath))) {
        New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
    }
    Start-Transcript -Path $LogPath -Append | Out-Null

    # 0. PRIVILEGE ESCALATION
    $Definition = @"
    using System;
    using System.Runtime.InteropServices;
    public class TokenManipulator {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
        [DllImport("kernel32.dll", ExactSpelling = true)]
        internal static extern IntPtr GetCurrentProcess();
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
        [DllImport("advapi32.dll", SetLastError = true)]
        internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        internal struct TokPriv1Luid {
            public int Count;
            public long Luid;
            public int Attr;
        }
        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
        public static bool EnablePrivilege(string privilege) {
            try {
                bool retVal;
                TokPriv1Luid tp = new TokPriv1Luid();
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
            } catch (Exception) {
                return false;
            }
        }
    }
"@
    try {
        Add-Type -TypeDefinition $Definition -PassThru | Out-Null
    }
    catch {
        $LoaderErrors = $_.Exception.LoaderExceptions | ForEach-Object { $_.Message }
        Write-KillSlopLog "COMPILATION ERROR: $_" "FATAL" "Red"
        if ($LoaderErrors) {
            Write-KillSlopLog "Loader Details: $LoaderErrors" "FATAL" "Red"
        }
        throw $_
    }
    [TokenManipulator]::EnablePrivilege("SeTakeOwnershipPrivilege") | Out-Null
    [TokenManipulator]::EnablePrivilege("SeRestorePrivilege") | Out-Null
    Write-KillSlopLog "Privileges Escalated (SeTakeOwnership, SeRestore)" "INIT" "Magenta"

    Write-KillSlopLog "=== killSlop v0.0.3 INITIATED ===" "INIT" "Magenta"

    # 1. SERVICE CONFIGURATION
    Write-KillSlopLog "Configuring Services..." "PROC" "Cyan"
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
                Write-KillSlopLog "Service Disabled: $Svc" "OK" "Green"
            } catch {
                Write-KillSlopLog "Failed to Disable: $Svc ($_)" "FAIL" "Red"
            }
        } else {
            Write-KillSlopLog "Service Not Found: $Svc" "SKIP" "DarkGray"
        }
    }

    # 2. TASK CONFIGURATION
    Write-KillSlopLog "Configuring Scheduled Tasks..." "PROC" "Cyan"
    $TaskRoot = "\Microsoft\Windows\Windows Defender"
    try {
        Get-ScheduledTask -TaskPath "$TaskRoot\*" -ErrorAction Stop | Disable-ScheduledTask | Out-Null
        Write-KillSlopLog "Tasks Disabled." "OK" "Green"
    } catch {
        Write-KillSlopLog "Task Scheduler Unavailable (Safe Mode Expected): $_" "WARN" "Yellow"
    }

    # 3. POLICY CONFIGURATION
    Write-KillSlopLog "Configuring Group Policies..." "PROC" "Cyan"
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
            Write-KillSlopLog "Policy Applied: $Key\$Val" "POL" "Yellow"
        }
    }

}
catch {
    Write-KillSlopLog "CRITICAL RUNTIME ERROR: $_" "FATAL" "Red"
}
finally {
    # 4. RESTORATION & EGRESS
    Write-KillSlopLog "Restoring Boot Configuration..." "PROC" "Cyan"
    & bcdedit.exe /deletevalue "{current}" safeboot
    if ($LASTEXITCODE -ne 0) {
        Write-KillSlopLog "BCD RESTORE FAILED (LASTEXITCODE=$LASTEXITCODE). Manual restore required." "WARN" "Yellow"
    }

    Write-KillSlopLog "=== PROTOCOL COMPLETE. REBOOTING. ===" "EXIT" "Magenta"
    Stop-Transcript | Out-Null
    Start-Sleep -Seconds 3
    Restart-Computer -Force
}
