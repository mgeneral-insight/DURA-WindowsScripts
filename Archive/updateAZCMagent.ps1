param ([switch]$batch, $server)
. c:\scripts\insight\functions.ps1
UpdateScript 

$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\AzureConnectedMachineAgent\CurrentVersion.txt"
$date = Get-Date -Format MMddyyyy-HHMMss
$outfile = "C:\scripts\OutFiles\AZCMUpgrade-$date.csv"
LogMessage -message "----- START -----"
Clear-Host
Write-Host "This script will upgrade Azure Connected Machine Agent to the latest version: $latestVersion"


function CheckVersion {
    $currentVersion = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "Azure Connected Machine Agent").version
    if (!($currentVersion)) { return "NotInstalled" }
    elseif ($latestVersion -ne $currentVersion) { return "Outdated" } 
    elseif ($latestVersion -eq $currentVersion) { return "Current" } 
    else { return "Unknown" }
}

function UpdateVersion {
    Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' }}
    Copy-Item -Path "\\azncwv078\IT-Packages\Application Install Packages\AzureConnectedMachineAgent\*.msi" -Destination \\$server\c$\IT\AZCMagent.msi
    Invoke-Command -ComputerName $server -ScriptBlock { 
        $InstallArg = '/i C:\IT\AZCMagent.msi /qn /l*v "C:\IT\azcmagentupgradesetup.log"'
        Start-Process msiexec.exe -Wait -ArgumentList $InstallArg
    }
}


if ($batch) {
    $infilepath = "C:\scripts\InFiles\AZCMUpgrade.csv"
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
        Write-Progress -Id 0 -Activity 'Upgrading AZCM Agent' -Status "Processing $($i) of $serverCount" -CurrentOperation $server -PercentComplete (($i/$serverCount) * 100)
        if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) {
            LogMessage -message "$server - Failed to ping" -Severity Error
            $result = "ERROR: Failed to connect"
        } else {
            $updateRequired = CheckVersion
            if ($updateRequired -eq "Outdated") {
                LogMessage -message "$server - Update Required, attempting to upgrade"
                UpdateVersion
                $checkUpgrade = CheckVersion
                if ($checkUpgrade -eq "Current") {
                    LogMessage -message "$server - Upgrade Successful"
                    $result = "Upgraded Successfully"
                } elseif ($checkUpgrade -eq "Outdated") {
                    LogMessage -message "$server - Upgrade UNSUCCESSFUL" -Severity Error
                    $result = "ERROR: Upgrade Failed"
                }
            } elseif ($updateRequired -eq "Current") {
                LogMessage -message "$server - Update NOT Required, latest version already installed"
                $result = "Upgrade not required"
            } elseif ($updateRequired -eq "NotInstalled") {
                LogMessage -message "$server - AZCM Agent not installed, skipping." -Severity Warn
                $result = "Not Installed"
            }
        }
        $report += [pscustomobject][ordered] @{
            "Server"=$server;
            "Result"=$result;
        } 
    }
    $report | Export-Csv -NoTypeInformation $outfile
    $From = "Insight-Automations@duracell.com"
    $Subject = "AZCM Agent Upgrade Report - $Date"
    $Body = "Attached is the Upgrade Report"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    if ($email) { Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile }
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
} else {
    if (!($server)) {$server = Read-Host -Prompt "Enter Server Name"}
    LogMessage -message "Single Server Mode : Server $server"
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        LogMessage -message "ERROR: Can not ping $server" -Severity Error 
        exit 1
    }
    $updateRequired = CheckVersion
    if ($updateRequired -eq "Outdated") {
        LogMessage -message "Update Required, attempting to upgrade"
        UpdateVersion
        $checkUpgrade = CheckVersion
        if ($checkUpgrade -eq "Current") {
            LogMessage -message "Upgrade Successful"
        } elseif ($checkUpgrade -eq "Outdated") {
            LogMessage -message "Upgrade UNSUCCESSFUL" -Severity Error
        }
    } elseif ($updateRequired -eq "Current") {
        LogMessage -message "Update NOT Required, latest version already installed"
    } elseif ($updateRequired -eq "NotInstalled") {
        LogMessage -message "AZCM Agent is not currently installed" -Severity Warn
        while ("y","n" -notcontains $install) { $install = Read-Host -Prompt "`r`nDo you want to install AZCM Agent on $server (y/n)?" }
        if ($deploy -eq "n") { 
            LogMessage -message "User chose not to install AZCM Agent."
            exit 1 
        }
        LogMessage -message "Installing AZCM Agent"
        UpdateVersion
        $checkUpgrade = CheckVersion
        if ($checkUpgrade -eq "Current") {
            LogMessage -message "Install Successful"
        } elseif ($checkUpgrade -eq "NotInstalled") {
            LogMessage -message "Install UNSUCCESSFUL" -Severity Error
        }
    }
}
LogMessage -message "----- END -----"
