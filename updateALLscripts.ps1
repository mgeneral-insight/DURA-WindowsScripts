#! Make sure App config files update

. c:\scripts\insight\functions.ps1
$scriptPath = "C:\scripts\insight"
$tempPath = "$scriptPath\temp"

if (!(Test-Path -Path $tempPath)) {
    New-Item -ItemType Directory -Force -Path $tempPath
}

Remove-Item -Path "$tempPath\*" -Recurse -Force
Invoke-WebRequest -Uri "https://github.com/mgeneral-insight/DURA-WindowsScripts/archive/refs/heads/main.zip" -OutFile "$tempPath\repository.zip"
Expand-Archive -Path "$tempPath\repository.zip" -DestinationPath $tempPath -Force
Remove-Item -Path "$tempPath\repository.zip" -Force

Move-Item -Path "$tempPath\DURA-WindowsScripts-main\*" -Destination $tempPath -Force
Remove-Item -Path "$tempPath\DURA-WindowsScripts-main" -Force -Recurse

$scripts = Get-ChildItem -Path "$tempPath" -File
foreach ($script in $scripts) {
    if (!(Test-Path -Path "$scriptPath\$script")) {
        LogMessage -message "$script doesn't exist, creating"
        Copy-Item -Path "$tempPath\$script" -Destination $scriptPath
    } else {
        $LatestHash = (Get-FileHash -Path "$tempPath\$script").Hash
        $CurrentHash = (Get-FileHash -Path "$scriptPath\$script").Hash
        if ($CurrentHash -ne $LatestHash) {
            LogMessage -message "$script is outdated, updating"
            Copy-Item -Path "$tempPath\$script" -Destination "$scriptPath\$script" -Recurse -Force
        } else {
            LogMessage -Message "$script is up to date."
        }
    }
}

$dirs = (get-ChildItem -path $tempPath -directory).name
foreach ($dir in $dirs) {
    if (!(Test-Path -Path "$scriptPath\$dir")) { New-Item -ItemType Directory -Force -Path $scriptPath\$dir }
    $scripts = (Get-ChildItem -Path "$tempPath\$dir\*" -File -Exclude _*).Name
    foreach ($script in $scripts) {
        if (!(Test-Path -Path "$scriptPath\$dir\$script")) {
            LogMessage -message "$dir\$script doesn't exist, creating"
            Copy-Item -Path "$tempPath\$dir\$script" -Destination "$scriptPath\$dir"
        } else {
            $LatestHash = (Get-FileHash -Path "$tempPath\$dir\$script").Hash
            $CurrentHash = (Get-FileHash -Path "$scriptPath\$dir\$script").Hash
            if ($CurrentHash -ne $LatestHash) {
                LogMessage -message "$dir\$script is outdated, updating"
                Copy-Item -Path "$tempPath\$dir\$script" -Destination "$scriptPath\$dir\$script" -Recurse -Force
            } else {
                LogMessage -Message "$dir\$script is up to date."
            }
        }
    }
}
 
Remove-Item -Path "$tempPath\*" -Recurse -Force