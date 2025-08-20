$app = "Datadog" 
$appName = "Datadog Agent" 
$installArg = '/i C:\IT\Datadog.msi /QN /l*vx "c:\IT\DataDog_Install_Log.txt"'
$installString = "Start-Process msiexec.exe -Wait -ArgumentList $using:installArg"
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Datadog Agent").version }
$installerPath = "\\AZNCWV078\IT-Packages\Application Install Packages\Datadog\Latest\*.msi"
$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\Datadog\Latest\CurrentVersion.txt"
