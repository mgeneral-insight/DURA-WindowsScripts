param($server, [switch]$AcceptAll, [switch]$AutoReboot)
. c:\scripts\insight\functions.ps1
UpdateScript 

function Pass-Parameters {
    Param ([hashtable]$NamedParameters)
    return ($NamedParameters.GetEnumerator()|%{"-$($_.Key) `"$($_.Value)`""}) -join " "
}
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-NoExit -File `"" + $MyInvocation.MyCommand.Path + "`" " + (Pass-Parameters $MyInvocation.BoundParameters) + " " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

clear-host 
get-content -raw c:\scripts\insight\logo.txt

while (!($server)) { 
    Write-Host "This script will check for updates for the input server, and ask if you would like to apply them"
    $serv = Read-Host -Prompt "Enter Server Name" 
    if (!(Test-Connection $serv -Count 1 -ErrorAction SilentlyContinue)) { Write-Host "ERROR: Can not ping $serv" -ForegroundColor Red }
    else { $server = $serv }
}
$server = $server.ToUpper()
$dc = [System.Net.Dns]::GetHostName()
if ($server.StartsWith("AZ")) { if ("azncwv042" -ne $dc) { Write-Host "Detected $server is an Azure server, please run this script on AZNCWV042" -ForegroundColor Red; exit 1 } } 
#!
elseif ($server.StartsWith("AAR")) { if ("aarwvddur001" -ne $dc) { Write-Host "Detected $server is an Aarscot server, please run this script on AARWVDDUR001" -ForegroundColor Red; exit 1 } }
#!
elseif ($server.StartsWith("HEI")) { if ("heiwvddur001" -ne $dc) { Write-Host "Detected $server is a Heist server, please run this script on HEIWVDDUR001" -ForegroundColor Red; exit 1 } }
#!
elseif ($server.StartsWith("CNDG")) { if ("cndgwvddur001" -ne $dc) { Write-Host "Detected $server is a DongGuan server, please run this script on CNDGWVDDUR001" -ForegroundColor Red; exit 1 } }
#!
elseif ($server.StartsWith("CNNC")) { if ("cnncwvddur001" -ne $dc) { Write-Host "Detected $server is a Nanchang server, please run this script on CNNCWVDDUR001" -ForegroundColor Red; exit 1 } }
#!
else { if ("LGGAWV052" -ne $dc) { Write-Host "Detected $server is a North America server, please run this script on LGGAWV052" -ForegroundColor Red; exit 1 } }

$updates = Get-WindowsUpdate -ComputerName $server -ErrorAction SilentlyContinue
$updates
Write-Host " "
if (!($updates)) { 
    write-host "No Updates Available" -ForegroundColor Green
    exit
}
if ($AcceptAll) { $apply = "y" } 
while("y","n" -notcontains $apply) { $apply = Read-Host "Do you want to apply ALL of the above updates (y/n)?" }
if ($apply -eq "y") {
    if ($AutoReboot) { $reboot = "y" }
    while("y","n" -notcontains $reboot) { $reboot = Read-Host "Do you want to automatically reboot server, if required, after updates are complete (y/n)?" }
    Get-WindowsUpdate -ComputerName $server -AcceptAll -Install -IgnoreReboot -IgnoreRebootRequired -ErrorVariable WUError
    write-host "Waiting for Windows Updates to complete..."
    $updaterunning = get-wujob -ComputerName $server
    Do {start-sleep -seconds 15}
    Until ($updaterunning.State -eq 3 -or $null -eq $updaterunning)
    Write-Host "Windows Updates Completed"
    Start-Sleep -Seconds 15
    $rebootreq = (Get-WURebootStatus -ComputerName $server).RebootRequired
    if ($rebootreq -eq $true) {
        if ($reboot -eq "Y") {
            Write-Host "Rebooting Server"
            Restart-Computer -ComputerName $server -Force
            Start-Sleep -Seconds 30
            Write-Host "Waiting for server to come back up..."
            Do {Start-Sleep -Seconds 10}
            While(!(Test-Connection -ComputerName $server -ErrorAction Ignore)) 
            Write-Host "...Server is back up."
        }
        elseif ($reboot -eq "N") {
            Write-Host "A Reboot is Required, Please Restart the Server Manually." -ForegroundColor Yellow
        }
    }
    elseif ($rebootreq -eq $false) {
            Write-Host "Updates completed, Reboot not required" -ForegroundColor green
    }       
}


