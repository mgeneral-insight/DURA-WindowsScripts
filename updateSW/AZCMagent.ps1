$app = "AZCMagent" # Short Application Name (No Spaces), should be name of file.
$appName = "Azure Connected Machine Agent" # Long Application Name
$InstallArg = '/i C:\IT\AZCMagent.msi /qn /l*v "C:\IT\azcmagentupgradesetup.log"'
$updateString = "Start-Process msiexec.exe -Wait -ArgumentList $InstallArg"
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Azure Connected Machine Agent").version } # Command to run on server to get current version (NO QUOTES)
$installerPath = "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe" # Path to shared install file
$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\AzureConnectedMachineAgent\CurrentVersion.txt"
