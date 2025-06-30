$app = "VMTools"
$appName = "VMWare Tools"
$updateString = "C:\IT\$app.exe /S /l "c:\IT\$app_install.txt" /v "/qn REBOOT=R""
function currentVersionCMD = { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version }
$installerPath = "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe"
$latestVersion = ((Get-ItemProperty $installerPath).VersionInfo).ProductVersion 
