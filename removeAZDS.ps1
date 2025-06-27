param ([switch]$batch, $server)
. c:\scripts\insight\functions.ps1
UpdateScript 

$date = Get-Date -Format MMddyyyy-HHMMss
$outfile = "C:\scripts\OutFiles\AZDS_Remove-$date.csv"
LogMessage -message "----- START -----"
Clear-Host
Write-Host "This script will REMOVE Azure Data Studio"

### Functions ###
function checkInstall {
    $package = Invoke-Command -ComputerName $server -ScriptBlock { Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6591F69E-6588-4980-81ED-C8FCBD7EC4B8}_is1" }
    if ($package -eq "true") { return "Installed" }
    else { return "NOTInstalled"}
}

function removeAZDS {
    Invoke-Command -ComputerName $server -ScriptBlock { & 'C:\Program Files\Azure Data Studio\unins000.exe' /SILENT }
}
### /Functions ###

if ($batch) {
    $infilepath = "C:\scripts\InFiles\removeAZDS.csv"
    $infile = Get-Content -Path $infilepath
    if (!(Test-path -path $infilepath)) {
        LogMessage -message "Input file not found, please create $infilepath and add server list to it." -Severity Error
        exit 1
    }

    LogMessage -message "Batch Mode, Running on the following servers:"
    LogMessage -message $infile
    while ("y","n" -notcontains $deploy) { $deploy = Read-Host -Prompt "`r`nDo you want to continue (y/n)?" }
    if ($deploy -eq "n") { exit 1 }
    $email = Read-Host "Enter email address to send report to (press Enter to skip report)"
    $report = @()
    $serverCount = $infile.Count
    $i = 0
    foreach ($server in $infile) {
        $i++
        Write-Progress -Id 0 -Activity 'Removing Azure Data Studio' -Status "Processing $($i) of $serverCount" -CurrentOperation $server -PercentComplete (($i/$serverCount) * 100)
        if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) {
            LogMessage -message "$server - Failed to ping" -Severity Error
            $result = "ERROR: Failed to connect"
        } else {
            $checkInstall = checkInstall
            if ($checkInstall -eq "NOTInstalled") {
                LogMessage -message "$server - Azure Data Studio is NOT installed, skipping."
                $result = "Not Installed"
            } elseif ($checkInstall -eq "Installed") {
                $processrunning = get-process -Name "AzureDataStudio" -ComputerName $server -ErrorAction SilentlyContinue
                if ($processrunning) { 
                    LogMessage -message "$server - Azure Data Studio is currently running, skipping" -Severity Warn
                    $result = "Process running, skipping" 
                } else {
                    LogMessage -message "$server - Attempting to uninstall Azure Data Studio"
                    removeAZDS
                    $checkInstallafter = checkInstall
                    if ($checkInstallafter -eq "NOTInstalled") {
                        LogMessage -message "$server - Uninstall Successful"
                        $result = "Uninstalled Successfully"
                    } elseif ($checkInstallafter -eq "Installed") {
                        LogMessage -message "$server - Uninstall UNSUCCESSFUL" -Severity Error
                        $result = "ERROR: Uninstall Failed"
                    }
                }
            }
        }
        $report += [pscustomobject][ordered] @{
            "Server"=$server;
            "Result"=$result;
        } 
    }
    $report | Export-Csv -NoTypeInformation $outfile
    $From = "Insight-Automations@duracell.com"
    $Subject = "Azure Data Studio Removal Report - $Date"
    $Body = "Attached is the Removal Report"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    if ($email) { Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile }
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
} else {
    ### Non-Batch Mode
    if (!($server)) {$server = Read-Host -Prompt "Enter Server Name"}
    LogMessage -message "Single Server Mode : Server $server"
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        LogMessage -message "ERROR: Can not ping $server" -Severity Error 
        exit 1
    }
    $checkInstall = checkInstall
    if ($checkInstall -eq "NOTInstalled") {
        LogMessage -message "AZDS is not currently installed" -Severity Warn
        exit 1
    } elseif ($checkInstall -eq "Installed") {
        $processrunning = get-process -Name "AzureDataStudio" -ComputerName $server -ErrorAction SilentlyContinue
        if ($processrunning) { 
            LogMessage -message "AZDS is currently running, skipping" -Severity Warn
        } else {
            LogMessage -message "Attempting to Uninstall Azure Data Studio"
            removeAZDS
            $checkInstallafter = checkInstall
            if ($checkInstallafter -eq "NOTInstalled") {
                LogMessage -message "Uninstall Successful"
            } elseif ($checkInstallafter -eq "Installed") {
                LogMessage -message "Uninstallation UNSUCCESSFUL" -Severity Error
            }
        }
    }
}
LogMessage -message "----- END -----"
