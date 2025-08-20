$app = "nCentral" # Short Application Name (No Spaces), should be name of file.
$appName = "nCentral Agent" # Long Application Name
$updateString = 'C:\IT\$app.exe /S /l "c:\IT\$app_install.txt" /v "/qn REBOOT=R"' # Command to run on server to update application
function currentVersionCMD { (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Windows Agent").version }
$installerPath = "\\AZNCWV078\IT-Packages\Application Install Packages\NCentral\WindowsAgentSetup.exe" # Path to shared install file
$latestVersion = ((Get-ItemProperty $installerPath).VersionInfo).ProductVersion 
#$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\Splunk\Latest\CurrentVersion.txt"
