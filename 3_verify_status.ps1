$ErrorActionPreference="SilentlyContinue"
$P=Get-Process -Name "MsMpEng","NisSrv","MsSense","MpCmdRun","SecurityHealthSystray"
if($P){Exit 1}
$V="WinDefend","Sense","WdFilter","WdNisSvc","WdNisDrv","wscsvc","SgrmBroker","SgrmAgent","MDCoreSvc","webthreatdefusersvc","SenseCncProxy"
foreach($s in $V){
$Svc=Get-Service -Name $s
if($Svc.Status -eq 'Running'){Exit 1}
$R=(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$s").Start
if($R -ne 4){Exit 1}
}
Exit 0
