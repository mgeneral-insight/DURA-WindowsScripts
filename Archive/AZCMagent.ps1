$app = "AZCMagent" 
$appName = "Azure Connected Machine Agent" 
$InstallArg = '/i C:\IT\AZCMagent.msi /qn /l*v "C:\IT\azcmagentupgradesetup.log"'
$updateString = "Start-Process msiexec.exe -Wait -ArgumentList $InstallArg"
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Azure Connected Machine Agent").version } # Command to run on server to get current version (NO QUOTES)
$installerPath = "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe" 
$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\AzureConnectedMachineAgent\CurrentVersion.txt"
