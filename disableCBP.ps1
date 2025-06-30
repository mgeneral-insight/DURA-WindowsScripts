. c:\scripts\insight\functions.ps1
UpdateScript

function introdu {
    Clear-Host
    Write-Host "This script will attempt to move the specified machine into the Local Approval (bypass) policy in Carbon Black Protection."
    Write-Host "Local Approval (bypass) policy will not block any applications from being run."
    Write-Host "Any files created while the host is in Local Approval (bypass) policy will still be allowed to run when the machine is put back in High Enforcement (blocking)"
    Write-Host ""
    Write-Host "The server will only be put in Local Approval (bypass) for 8 hours, after which it will be moved back to High Enforcement (Blocking)"
    Write-Host ""
}

introdu
$toolserv = "AZNCWV078"

while (!($server)) { 
    $serv = Read-Host -Prompt "Enter Server Name to put into Local Approval (bypass) Policy" 
    if (!(Test-Connection $serv -Count 1 -ErrorAction SilentlyContinue)) { Write-Host "ERROR: Can not ping $serv." -ForegroundColor Red }
    else { $server = $serv.ToUpper() }
}

#Invoke-Command -ComputerName $server -ScriptBlock {
#    if (!(Test-Path 'C:\IT')) { $path = New-Item -Path 'C:\' -Name 'IT' -ItemType 'directory' }
#    if (!(Test-Path 'C:\IT\exes')) { $path = New-Item -Path 'C:\IT\' -Name 'exes' -ItemType 'directory' }
#}
#if (!(Test-Path "\\$server\c$\IT\exes\CBPEnforcementChange.exe")) { Copy-Item -Path "\\AZNCWV078\IT-Packages\Tools\CBPEnforcementChange.exe" -Destination \\$server\c$\IT\exes\CBPEnforcementChange.exe }

$curpol1 = Invoke-Command -ComputerName $toolserv -ArgumentList $server -ScriptBlock {
    Param ($server)
    H:\IT-Packages\Tools\CBPEnforcementChange.exe list host=$server
}

$curpol2 = $curpol1 | Where-Object {$_ -match 'policyName'}
$curpol = $curpol2.TrimStart().Split(':')[1].trim()

if ( $curpol -like "*VISIBILITY*" ) { Write-Host "`r`n $server is currently in VISIBILITY policy, nothing is being blocked." }
elseif ( $curpol -eq "Local Approval Policy" ) { Write-Host "`r`n $server is currently in LOCAL APPROVAL POLICY, nothing is being blocked." }
elseif ( $curpol -like "*HIGH ENFORCEMENT*" ) { 
    Write-Host "`r`n $server is currently in HIGH ENFORCEMENT, BLOCKING IS ACTIVE."
    while ("y","n" -notcontains $deploy) { $deploy = Read-Host -Prompt "`r`nDo you want to move this server to Local Approval Policy for 8 hours? (y/n)" }
    if ($deploy -eq "n") { exit 1}
    elseif ($deploy -eq "y") {
        $chgpol = Invoke-Command -ComputerName $toolserv -ArgumentList $server -ScriptBlock {
            Param ($server)
            H:\IT-Packages\Tools\CBPEnforcementChange.exe move host=$server
        }
        $curpol111 = Invoke-Command -ComputerName $toolserv -ArgumentList $server -ScriptBlock {
            Param ($server)
            H:\IT-Packages\Tools\CBPEnforcementChange.exe list host=$server
        }
        $curpol112 = $curpol111 | Where-Object {$_ -match 'policyName'}
        $curpol11 = $curpol112.TrimStart().Split(':')[1].trim()
        if ( $curpol11 -eq "Local Approval Policy" ) { Write-Host "Success: $server is now in LOCAL APPROVAL POLICY, nothing is currently being blocked." -ForegroundColor Green }
        else { Write-Host "ERROR: Could not verify $server changed to Local Approval Policy." -ForegroundColor Red }

        
    }   
}
