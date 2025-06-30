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
#! Update Apps Dir

### Functions
function GetAppConfig {
    if (!($app)) {
        clear-host
        write-host "---------- Insight Application Updater ----------"
        if ($checkOnly) { write-host "Select software to update from list below:" }
        else { write-host "Select software to check for updates from list below:" }
        $allApps = Get-ChildItem -Path "C:\scripts\insight\updateSW\*" -Exclude _* -File
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
        if (!(test-path -path "C:\scripts\insight\updateSW\$app.ps1")) {
            write-host "Error: Application Configuration file not found:  C:\scripts\insight\updateSW\$app.ps1 "
            exit 1
        } else {
            return "C:\scripts\insight\updateSW\$app.ps1"
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
function updateVersion {
    Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' } }
    $installerExt = (get-item -path $installerPath).extension
    Copy-Item -Path $installerPath -Destination "\\$server\c$\IT\$app.$extension" -force
    Invoke-Command -ComputerName $server -ScriptBlock { $updateString }
}

### Run Script
$appConfigFile = GetAppConfig
. $appConfigFile
LogMessage -message ----- START -----
Clear-Host
if ($checkOnly) { write-host "This script will check if updates are required for $appName. The latest version is $latestVersion."}
else { Write-Host "This script will update $appName to the latest version: $latestVersion" }

if ($batch) {
    $inFile = "C:\scripts\InFiles\update$app.csv"
    $outFile = "C:\scripts\OutFiles\$app-Install-$date.csv"
    $date = Get-Date -Format MMddyyyy-HHMMss
    if (!(test-path -path $inFile)) { 
        write-host "ERROR: Input file not found, create a the file $infile and populate it with a list of servers"
        exit 1
    }
    $inServers = Get-Content -Path $inFile
    Write-Host "Batch mode dectected, this script will run on the following servers defined in $inFile"
    if ($checkOnly) { write-host "Running in Check Only mode, only checking if update is needed. No changes will be made on the servers.`r`n" }
    $inServers
    while ("y","n" -notcontains $deploy) { $deploy = Read-Host -Prompt "`r`nDo you want to continue (y/n)?" }
    if ($deploy -eq "n") { exit 1 }
    $email = Read-Host "Enter email address to send report to (press enter to skip)"
    $report = @()
    foreach ($server in $inServers) {
        if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
            $out = "ERROR: Failed to Ping" 
            LogMessage -message "$server - Failed to Ping" -Severity Error
        } else { 
            $currentVersion = checkVersion
            if ($currentVersion -eq "NotInstalled") {
                $out = "Not Installed"
                LogMessage -message "$server - $appName is not installed." -Severity Warn
            } elseif ($currentVersion -eq "Current") {
                $out = "Latest Version Already Installed"
                LogMessage -message "$server - $appName is already up to date."
            } else {
                # update Required
                if ($checkOnly) { 
                    LogMessage -message "$server - Update Needed, Current Version: $currentVersion" 
                    $out = "Update Needed"
                }
                else {
                    LogMessage -message "$server - Outdated, attempting update. Current Version $currentVersion"
                    updateVersion
                    $afterVersion = checkVersion
                    if ($afterVersion -eq "Current") {
                        $out = "Update Succeeded"
                        LogMessage -message "$server - $appName Update Succeeded"
                    } elseif ($afterVersion -eq "NotInstalled") {
                        $out = "ERROR: $appName not detected on server after update"
                        LogMessage -message "$server - $appName not detected on server after update" -Severity Error
                    } else {
                        $out = "ERROR: Update Failed"
                        LogMessage -message "$server - Update Failed"
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
    $From = "Insight-Automations@duracell.com"
    $Subject = "$appName Update Report - $Date"
    $Body = "Attached is the Update Report `r`n $email"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    if ($email) { Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile }
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
} else {
    # Single Server Mode
    if (!($server)) { $server = Read-Host -Prompt "Enter Server Name" }
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        LogMessage -message "$server - Failed to Ping" -Severity Error
    } else { 
        $currentVersion = checkVersion
        if ($currentVersion -eq "NotInstalled") {
            LogMessage -message "$server - $appName is not installed." -Severity Warn
        } elseif ($currentVersion -eq "Current") {
            LogMessage -message "$server - $appName is already up to date."
        } else {
            # update Required
            if ($checkOnly) { 
                LogMessage -message "$server - Update Needed, Current Version: $currentVersion" 
            }
            else {
                LogMessage -message "$server - Outdated, attempting update. Current Version $currentVersion"
                updateVersion
                $afterVersion = checkVersion
                if ($afterVersion -eq "Current") {
                    LogMessage -message "$server - $appName Update Succeeded"
                } elseif ($afterVersion -eq "NotInstalled") {
                    LogMessage -message "$server - $appName not detected on server after update" -Severity Error
                } else {
                    LogMessage -message "$server - Update Failed"
                }
            }
        }
    }
}
