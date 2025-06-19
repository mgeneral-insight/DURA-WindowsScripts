$ScriptPath = "C:\Scripts\Insight"
$callStack = Get-PSCallStack
if ($callStack | Where-Object ScriptName) {
    $topLevelScriptPath = ($callStack | Where-Object ScriptName).ScriptName[-1]
    $topLevelScript = (Get-Item -Path $topLevelScriptPath).Name
    $topLevelScriptBase = (Get-Item -Path $topLevelScriptPath).BaseName
}

function LogMessage {
    param (
        [string]$Message,
        [string]$Severity = "Info"
    )
    $TimeStamp = Get-Date
    if (!(Test-Path -path "$ScriptPath\Logs")) { $path = New-Item -Path "$scriptPath\Logs" -ItemType Directory }
    $LFTimeStamp = Get-Date -Format "yyyyMMdd"
    $LogFile = "$ScriptPath\Logs\$LFTimeStamp-$topLevelScriptBase.log"
    $Severity = "[$Severity]"
    $LogEntry = "$TimeStamp : $Severity : $Message"
    if ($Severity -eq "Error") { Write-Host $LogEntry -ForegroundColor Red }
    elseif ($Severity -eq "Warn") { Write-Host $LogEntry -ForegroundColor Yellow }
    elseif ($Severity -eq "Info") { Write-Host $LogEntry }
    Add-Content -Path $LogFile -Value $LogEntry -Append

}
function UpdateScript {
    param (
        [string]$ScriptName
    )
    if (!(Test-Path -path "$ScriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/$ScriptName" -OutFile "$ScriptPath\temp\$ScriptName"
    $LatestHash = (Get-FileHash -Path "$ScriptPath\temp\$ScriptName").Hash
    if (!(Test-Path -Path "$ScriptPath\$ScriptName")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = (Get-FileHash -Path "$ScriptPath\$ScriptName").Hash
    }
    if ($CurrentHash -ne $LatestHash) {
        Write-Host "Running script is not latest version, updating and restarting script."
        Copy-Item -Path "$ScriptPath\temp\$ScriptName" -Destination "$ScriptPath\$ScriptName" -Recurse
    }
}
function UpdateFunctions {
    if (!(Test-Path -path "$ScriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/functions.ps1" -OutFile "$ScriptPath\temp\functions.ps1"
    $LatestHash = (Get-FileHash -Path "$ScriptPath\temp\functions.ps1").Hash
    if (!(Test-Path -Path "$ScriptPath\functions.ps1")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = (Get-FileHash -Path "$ScriptPath\functions.ps1").Hash
    }
    if ($CurrentHash -ne $LatestHash) {
        Write-Host "Running script is not latest version, updating and restarting script."
        Copy-Item -Path "$ScriptPath\temp\functions.ps1" -Destination "$ScriptPath\functions.ps1" -Recurse
    }
}
