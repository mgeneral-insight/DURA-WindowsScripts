$ScriptPath = "C:\Scripts\Insight"


function LogMessage {
    param (
        [string]$Message,
        [string]$LogFile,
        [bool]$Err
    )
    $TimeStamp = Get-Date
    $LogEntry = "$TimeStamp - $Message"
    if ($Err) { Write-Host $LogEntry -ForegroundColor Red }
    else { Write-Host $LogEntry }
    Add-Content -Path $LogFile -Value $LogEntry -Append
}
function UpdateScript {
    param (
        [string]$ScriptName
    )
    if (!(Test-Path -path "$ScriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/$ScriptName" -OutFile "$ScriptPath\temp\$ScriptName"
    $LatestHash = Get-FileHash -Path "$ScriptPath\temp\$ScriptName"
    if (!(Test-Path -Path "$ScriptPath\$ScriptName")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = Get-FileHash -Path "$ScriptPath\$ScriptName"
    }
    if ($CurrentHash -ne $LatestHash) {
        Write-Host "Running script is not latest version, updating and restarting script."
        Copy-Item -Path "$ScriptPath\temp\$ScriptName" -Destination "$ScriptPath\$ScriptName" -Recurse
    }
}
function UpdateFunctions {
    if (!(Test-Path -path "$ScriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/functions.ps1" -OutFile "$ScriptPath\temp\functions.ps1"
    $LatestHash = Get-FileHash -Path "$ScriptPath\temp\functions.ps1"
    if (!(Test-Path -Path "$ScriptPath\functions.ps1")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = Get-FileHash -Path "$ScriptPath\functions.ps1"
    }
    if ($CurrentHash -ne $LatestHash) {
        Write-Host "Running script is not latest version, updating and restarting script."
        Copy-Item -Path "$ScriptPath\temp\functions.ps1" -Destination "$ScriptPath\functions.ps1" -Recurse
    }

}
