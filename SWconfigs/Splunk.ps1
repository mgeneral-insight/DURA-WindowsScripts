$app = "Splunk" 
$appName = "Splunk Universal Forwarder" 
$updateString = 'Start-Process msiexec.exe -Wait -ArgumentList "/i C:\IT\Splunk.msi","AGREETOLICENSE=yes","/quiet"'
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "UniversalForwarder").version }
$installerPath = "\\AZNCWV078\IT-Packages\Application Install Packages\Splunk\Latest\*.msi"
$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\Splunk\Latest\CurrentVersion.txt"
