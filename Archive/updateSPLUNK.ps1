param ([switch]$batch, $server)
. c:\scripts\insight\functions.ps1
UpdateScript 

$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\Splunk\Latest\CurrentVersion.txt"
$date = Get-Date -Format MMddyyyy-HHMMss
$infilepath = "C:\scripts\InFiles\SplunkUpgrade.csv"
$infile = Get-Content -Path $infilepath
$outfile = "C:\scripts\OutFiles\SplunkUpgrade-$date.csv"
Clear-Host
Write-Host "This script will upgrade Splunk to the latest version: $latestVersion"

if ($batch) {
    Write-Host "-batch mode dectected, this script will run on the following servers defined in $infilepath`r`n"
    $infile
    while ("y","n" -notcontains $deploy) { $deploy = Read-Host -Prompt "`r`nDo you want to continue (y/n)?" }
    if ($deploy -eq "n") { exit 1}
    $email = Read-Host "Enter email address to send report to"
    $report = @()
    foreach ($server in $infile) {
        $server
        if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
            $out = "ERROR: Could not ping" 
            $SplunkPre = "ERROR"
            $SplunkPost = "ERROR"

        } else {
            $SplunkPre = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "UniversalForwarder").version
            if (!($SplunkPre)) { 
                $out = "ERROR: Splunk not installed"
            }
            else {
                if ($SplunkPre -eq $latestVersion) { 
                    $out = "Update Not Required"
                }
                else {
                    Write-Host "- Upgrade Required"
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' }
                    }
                    Write-Host "- Copying Installer"
                    Copy-Item -Path "\\AZNCWV078\IT-Packages\Application Install Packages\Splunk\Latest\*.msi" -Destination \\$server\c$\IT\Splunk.msi
                    Write-Host "- Starting Install"
                    Invoke-Command -ComputerName $server -ScriptBlock { 
#                        Copy-Item -Path "\\AZNCWV078\IT-Packages\Application Install Packages\Splunk\Latest\*.msi" -Destination "c:\IT\Splunk.msi"
#                        Unblock-File -path "c:\IT\Splunk.msi"
                        $SPLUNKarg = '/i C:\IT\Splunk.msi AGREETOLICENSE=yes /quiet'
                        Start-Process msiexec.exe -Wait -ArgumentList $SPLUNKarg
                    }
                    Write-Host "- Install Complete"
                    $SplunkPost = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "UniversalForwarder").version
                    if ($SplunkPost -ne $latestVersion) { $out = "ERROR: Upgrade Failed" }
                    else { $out = "SUCCESS: Upgrade succeeded" }
                }
            }
        }
        Write-Host "- $out"
        $report += [pscustomobject][ordered] @{
            "Server"=$server;
            "InitialVersion"=$SplunkPre;
            "FinalVersion"=$SplunkPost;
            "Note"=$out;
        } 
    }
    $report | Export-Csv -NoTypeInformation $outfile
    $From = "SplunkUpgrade@duracell.com"
    $Subject = "Splunk Upgrade Report - $Date"
    $Body = "Attached is the Upgrade Report"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile

} elseif (!($batch)) {
    if (!($server)) { $server = Read-Host -Prompt "Enter Server Name" }
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        Write-Host "ERROR: Could not ping $server" 
        exit 1
    }
    $SplunkPre = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "UniversalForwarder").version
    if (!($SplunkPre)) {  Write-Host "ERROR: Splunk not installed on $server" }
    else {
        Write-Host "Current Version installed on $server is $SplunkPre"
        if ($SplunkPre -eq $latestVersion) { 
            Write-Host "Splunk is at the current verision, Update Not Required"
        } else {
            Write-Host "Update Required, attempting to upgrade Splunk..."
            Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' }}
            Copy-Item -Path "\\AZNCWV078\IT-Packages\Application Install Packages\Splunk\Latest\*.msi" -Destination \\$server\c$\IT\Splunk.msi
            Invoke-Command -ComputerName $server -ScriptBlock { 
                $SPLUNKarg = '/i C:\IT\Splunk.msi AGREETOLICENSE=yes /quiet'
                Start-Process msiexec.exe -Wait -ArgumentList $SPLUNKarg
            }
            Write-Host "Installer finished, verifying upgrade was successful..."
            Start-Sleep -Seconds 5
            $SplunkPost = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "UniversalForwarder").version
            if ($SplunkPost -ne $latestVersion) { Write-Host "ERROR: Upgrade Failed" -ForegroundColor Red }
            else { Write-Host "SUCCESS: Upgrade succeeded" -ForegroundColor Green }
        }
    }
}