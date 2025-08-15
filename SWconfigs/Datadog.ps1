$app = "Datadog" 
$appName = "Datadog Agent" 
$updateString = 'Start-Process msiexec.exe -Wait -ArgumentList "/i C:\IT\Datadog.msi","/QN","/l*vx c:\IT\DataDog_Upgrade_Log.txt"'
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Datadog Agent").version }
$installerPath = "\\AZNCWV078\IT-Packages\Application Install Packages\Datadog\Latest\*.msi"
$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\Datadog\Latest\CurrentVersion.txt"
