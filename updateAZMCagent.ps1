param ([switch]$batch, $server)

$latestVersion = Get-Content -Path "\\azncwv078\IT-Packages\Application Install Packages\AzureConnectedMachineAgent\CurrentVersion.txt"
$date = Get-Date -Format MMddyyyy-HHMMss
$infilepath = "C:\scripts\InFiles\AZMCUpgrade.csv"
$infile = Get-Content -Path $infilepath
$outfile = "C:\scripts\OutFiles\AZMCUpgrade-$date.csv"
Clear-Host
Write-Host "This script will upgrade Azure Machine Connected Agent to the latest version: $latestVersion"

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
            $vmtools = "ERROR"
            $vmtools2 = "ERROR"
            $out
        } else {
            $vmtools = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version
            if (!($vmtools)) { 
                $out = "ERROR: VMWare Tools not installed"
                $out
            }
            else {
                if ($vmtools -eq $latestVMtools) { 
                    $out = "Update Not Required"
                    $out
                }
                else {
                    Invoke-Command -ComputerName $server -ScriptBlock {
                        if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' }
                    }
                    Copy-Item -Path "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe" -Destination "\\$server\c$\IT\VMTools.exe"
                    Invoke-Command -ComputerName $server -ScriptBlock { C:\IT\VMTools.exe /S /l "c:\IT\vmtools_install.txt" /v "/qn REBOOT=R" }
                    Start-Sleep -Seconds 5
                    $vmtools2 = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version
                    if ($vmtools2 -ne $latestVMtools) { $out = "ERROR: Upgrade Failed" }
                    else { $out = "SUCCESS: Upgrade succeeded" }
                }
            }
        }
        $report += [pscustomobject][ordered] @{
            "Server"=$server;
            "InitialVersion"=$vmtools;
            "FinalVersion"=$vmtools2;
            "Note"=$out;
        } 
    }
    $report | Export-Csv -NoTypeInformation $outfile
    $From = "VMToolsUpgrade@duracell.com"
    $Subject = "VMWare Tools Upgrade Report - $Date"
    $Body = "Attached is the Upgrade Report"
    $SMTPServer = "smtp.duracell.com"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $email -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile
    Send-MailMessage -From $From -to "michael.general@insight.com" -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Attachments $outfile

} elseif (!($batch)) {
    if (!($server)) { $server = Read-Host -Prompt "Enter Server Name" }
    if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
        Write-Host "ERROR: Can not ping $serv" -ForegroundColor Red 
        exit 1
    }
    $vmtools = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version
    if (!($vmtools)) { write-host "ERROR: VMware Tools not installed on $server." -ForegroundColor Red }
    else {
        Write-Host "Current version of VMware Tools installed on $server is $vmtools"
        if ($vmtools -eq $latestVMtools) {
            Write-Host "VMWare tools are at current version, Upgrade not required"
        } else {
            Write-Host "Upgrade Required, Attempting to upgrade VMware Tools" 
            Invoke-Command -ComputerName $server -ScriptBlock { if (!(Test-Path 'C:\IT')) { New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' } }
            Copy-Item -Path "\\azncwv078\IT-Packages\Application Install Packages\VMware Tools\latest\*.exe" -Destination "\\$server\c$\IT\VMTools.exe"
            Invoke-Command -ComputerName $server -ScriptBlock { C:\IT\VMTools.exe /S /l "c:\IT\vmtools_install.txt" /v "/qn REBOOT=R" }
            Write-Host "Installer finished, verifying upgrade was successful..."
            Start-Sleep -Seconds 5
            $vmtools2 = (Get-WmiObject -Class win32_product -ComputerName $server | Where-Object Name -eq "VMware Tools").version
            if ($vmtools2 -ne $latestVMtools) { write-host "Upgrade was UNSUCCESSFUL" -ForegroundColor Red }
            else { Write-Host "Upgrade Successful" -ForegroundColor Green }
        }
    }
}