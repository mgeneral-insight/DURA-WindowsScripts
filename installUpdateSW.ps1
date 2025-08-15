param (
    $app,
    [switch]$batch, 
    $server,
    [switch]$checkOnly 
)
$LFTimeStamp = Get-Date -Format "yyyyMMdd"
$LogFile = "c:\scripts\Insight\Logs\$LFTimeStamp-updateSW_$app.log"
. c:\scripts\insight\functions.ps1
UpdateScript 

function UpdateConfigs {
    $tempDir = "C:\scripts\insight\temp"
    $configDir = "C:\scripts\insight\SWconfigs"
    if (!(Test-Path -Path "$configDir")) { New-Item -ItemType Directory -Force -Path $configDir }
    if (!(Test-Path -Path "$tempDir")) { New-Item -ItemType Directory -Force -Path $configDir }
    else { Remove-Item -Path "$tempDir\*" -Recurse -Force }

    Invoke-WebRequest -Uri "https://github.com/mgeneral-insight/DURA-WindowsScripts/archive/refs/heads/main.zip" -OutFile "$tempDir\repository.zip"
    Expand-Archive -Path "$tempDir\repository.zip" -DestinationPath $tempDir -Force
    Remove-Item -Path "$tempDir\repository.zip" -Force
    Move-Item -Path "$tempDir\DURA-WindowsScripts-main\*" -Destination $tempDir -Force
    Remove-Item -Path "$tempDir\DURA-WindowsScripts-main" -Force -Recurse
    $configs = (Get-ChildItem -Path "$tempDir\SWconfigs\*" -File -Exclude _*).Name
    foreach ($config in $configs) {
        if (!(Test-Path -Path "$configDir\$config")) {
            LogMessage -message "SWconfigs\$config doesn't exist, creating"
            Copy-Item -Path "$tempDir\SWconfigs\$config" -Destination "$configDir"
        } else {
            $LatestHash = (Get-FileHash -Path "$tempDir\SWconfigs\$config").Hash
            $CurrentHash = (Get-FileHash -Path "$configDir\$config").Hash
            if ($CurrentHash -ne $LatestHash) {
                LogMessage -message "SWconfigs\$config is outdated, updating"
                Copy-Item -Path "$tempDir\SWconfigs\$config" -Destination "$configDir\$config" -Recurse -Force
            } else {
                LogMessage -Message "SWconfigs\$config is up to date."
            }
        }
    }
}
UpdateConfigs

### Functions
function GetAppConfig {
    if (!($app)) {
        if ($checkOnly) { write-host "Select software to update from list below:" }
        else { write-host "Select software to check for updates from list below:" }
        $allApps = Get-ChildItem -Path "C:\scripts\insight\SWconfigs\*" -Exclude _* -File
        $i=0
        $appSelector = @{}
        foreach ($appFile in $allApps) {
            $i++
            . $appFile.FullName
            write-host "$i) $appName"
            $appSelector.Add( $i, $appFile.FullName)
        }
        Do { [int]$selection = Read-Host "Choose an option (1-$i)" }
        Until (1..$i -contains $selection)
        $configFile = $appSelector[$selection]
        return "$configFile"
    } else {
        if (!(test-path -path "C:\scripts\insight\SWconfigs\$app.ps1")) {
            write-host "Error: Application Configuration file not found:  C:\scripts\insight\SWconfigs\$app.ps1 "
            exit 1
        } else {
            return "C:\scripts\insight\SWconfigs\$app.ps1"
        }
    }
}
function checkVersion {
    $cVersion = currentVersionCMD
    if (!($cVersion)) { 
        return "NotInstalled"
    }
    else {
        if ($cVersion -eq $latestVersion) {
            return "Current"
        } else {
            return "$cVersion"
        }
    }
}
function updateSW {
    Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' } }
    $installerExt = (get-item -path $installerPath).extension
    $installerExt
    $installFile = $app + $installerExt
    $installFile
    Copy-Item -Path $installerPath -Destination "\\$server\c$\IT\$installFile" -force
    if (!($updateString)) { $updateString = $installString }
    Invoke-Command -ComputerName $server -ScriptBlock { $updateString }
}
function installSW {
    Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' } }
    $installerExt = (get-item -path $installerPath).extension
    $installFile = $app + $installerExt
    Copy-Item -Path $installerPath -Destination "\\$server\c$\IT\$installFile" -force
    Invoke-Command -ComputerName $server -ScriptBlock { $installString }
}


### Run Script
LogMessage -message ----- START -----
Clear-Host
get-content -raw c:\scripts\insight\logo.txt
write-host "This script will check if the software you select is installed on the server, and prompt to install or upgrade the software if necessary"

$appConfigFile = GetAppConfig
. $appConfigFile

if (!($batch)) { 
    $getBatch = read-host -prompt "Do you want to run this on multiple servers at the same time? (y/N)" 
    if ($getBatch -eq "y") { 
        $batch = $true 
        read-host "Press ENTER to open Notepad, enter server names (1 per line), save and close notepad"
        $inFile = "C:\scripts\InFiles\install$app.csv"
        #! Remove Old InFile?
        & notepad.exe $inFile
        read-host "Press ENTER when server list is updated and saved."
    }
}

if ($batch) {
    $date = Get-Date -Format MMddyyyy-HHMMss
    $outFile = "C:\scripts\OutFiles\$app-Install-$date.csv"
    if (!(test-path -path $inFile)) { 
        write-host "ERROR: Input file not found, create a the file $infile and populate it with a list of servers"
        exit 1
    }
    $inServers = Get-Content -Path $inFile
    Write-Host "This script will run on the following servers defined in $inFile, please verify server list is correct."
    $inServers
    while ("y","n" -notcontains $deploy) { $deploy = Read-Host -Prompt "`r`nDo you want to continue (y/n)?" }
    if ($deploy -eq "n") { exit 1 }
    while ("y","n" -notcontains $autoInstall) { $autoInstall = Read-Host -Prompt "Do you want to automatically INSTALL $appName if it is missing on the server? (y/n)" }
    while ("y","n" -notcontains $autoUpdate) { $autoUpdate = Read-Host -Prompt "Do you want to automatically UPDATE $appName if it is not the current version? (y/n)" }

    $emailTo = Read-Host "Enter email address to send report to (press enter to skip)"
    $report = @()
    foreach ($server in $inServers) {
        if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
            $out = "ERROR: Failed to Ping" 
            LogMessage -message "$server - Failed to Ping" -Severity Error
        } else { 
            $currentVersion = checkVersion
            if ($currentVersion -eq "Current") {
                $out = "Latest Version Already Installed"
                LogMessage -message "$server - $appName is already up to date."
            } elseif ($currentVersion -eq "NotInstalled") {
                $out = "Not Installed"
                LogMessage -message "$server - $appName is not installed." -Severity Warn
                if ($autoInstall) { 
                    LogMessage -message "$server - Attempting to install $appName..."
                    installSW 
                    $afterVersion = checkVersion
                    if ($afterVersion -eq "Current") {
                        LogMessage -message "$server - $appName Successfully Installed"
                        $out = "Installed Successfully"
                    } else {
                        LogMessage -message "$server - ERROR: $appName Failed to Install." -Severity ERROR
                        $out = "ERROR: Install FAILED"
                    }
                }
            } else {
                # update Required
                $out = "Update Required, Current Version: $currentVersion"
                LogMessage -message "$server - Update Required, Current Version $currentVersion"
                if ($autoUpdate) {
                    LogMessage -message "$server - Attempting to Update $appName..."
                    updateSW
                    $afterVersion = checkVersion
                    if ($afterVersion -eq "Current") {
                        LogMessage -message "$server - $appName Successfully Updated"
                        $out = "Updated Successfully"
                    } else {
                        LogMessage -message "$server - ERROR: $appName Failed to Update." -Severity ERROR
                        $out = "ERROR: Update FAILED, Current Version: $afterVersion"
                    }
                }
            }
        }
        $report += [pscustomobject][ordered] @{
            "Server"=$server;
            "InitialVersion"=$currentVersion;
            "FinalVersion"=$afterVersion;
            "Note"=$out;
        }
    }
    $report | Export-Csv -NoTypeInformation $outfile
    $emailAttachments = $outfile
    $emailSubject = "$appName Install/Upgrade Report"
    $emailBody = "See attached for report"
    sendEmail
} else {
    # Single Server Mode
    if (!($server)) { $server = Read-Host -Prompt "Enter Server Name" }
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        LogMessage -message "$server - Failed to Ping" -Severity Error #! LogMessage or write-host
    } else { 
        $currentVersion = checkVersion
        if ($currentVersion -eq "Current") {
            LogMessage -message "$server - $appName is already up to date."
        } elseif ($currentVersion -eq "NotInstalled") {
            # Not Instaled
            LogMessage -message "$server - $appName is not installed." -Severity Warn
            while ("y","n" -notcontains $performInstall) { $performInstall = Read-Host -Prompt "Do you want to attempt to install $appName on $server ? (y/n)" }
            if ($performInstall -eq "y") {
                installSW 
                $afterVersion = checkVersion
                if ($afterVersion -eq "Current") {
                    LogMessage -message "$server - $appName Successfully Installed"
                } else {
                    LogMessage -message "$server - ERROR: $appName Failed to Install." -Severity ERROR
                }
            }
        } else {
            # update Required
            LogMessage -message "$appName is Outdated. Current Installed Version: $currentVersion  Latest Version: $latestVersion"
            while ("y","n" -notcontains $performUpdate) { $performUpdate = read-host -prompt "Do you want to attempt to Update $appName on $server to $latestVersion? (y/n)" }
            if ($performUpdate -eq "y") {
                LogMessage -message "$server - Attempting to Update $appName..."
                updateSW
                $afterVersion = checkVersion
                if ($afterVersion -eq "Current") {
                    LogMessage -message "$server - $appName Successfully Updated"
                } else {
                    LogMessage -message "$server - ERROR: $appName Failed to Update." -Severity ERROR
                }
            }
        }
    }
}