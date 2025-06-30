$app = "VMTools"
$appName = "VMWare Tools"
$updateString = 'start-process -filepath "C:\IT\VMTools.exe" -argumentlist "/S","/l 'c:\IT\vmtools_install.txt'","/v","/qn REBOOT=R" -wait'
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version }
$installerPath = "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe"
$latestVersion = ((Get-ItemProperty $installerPath).VersionInfo).ProductVersion 
 