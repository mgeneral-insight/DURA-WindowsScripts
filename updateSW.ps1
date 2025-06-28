param (
    $app,
    [switch]$batch, 
    $server
)
$LFTimeStamp = Get-Date -Format "yyyyMMdd"
$LogFile = c:\scripts\Insight\Logs\$LFTimeStamp-updateSW_$app.log
. c:\scripts\insight\functions.ps1
UpdateScript 
#! Update Apps Dir

### Functions
function GetAppVars {
    if (!($app)) {
        clear-host
        write-host "---------- Insight Application Updater ----------"
        write-host "Select software to update from list below:"
        $allApps = Get-ChildItem -Path "C:\scripts\insight\installSW" -file
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
        return "$appSelector[$selection]"

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

#! ---
function updateVersion {
    Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' } }
    Copy-Item -Path $installerPath -Destination "\\$server\c$\IT\$app.exe"

    Invoke-Command -ComputerName $server -ScriptBlock { $updateString }
}
#!

### Static Variables
$date = Get-Date -Format MMddyyyy-HHMMss
$outFile = "C:\scripts\OutFiles\$app-Install-$date.csv"
$inFile = "C:\scripts\InFiles\install-$app.csv"

### Run Script
$appConfigFile = GetAppVars
. $appConfigFile

LogMessage -message ----- START -----
Clear-Host
Write-Host "This script will update $appName to the latest version: $latestVersion"

if ($batch) {
    $inServers = Get-Content -Path $inFile
    Write-Host "Batch mode dectected, this script will run on the following servers defined in $inFile`r`n"
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
    $Body = "Attached is the Update Report"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    if ($email) { Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile }
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
} else {
    # Single Server Mode
}
