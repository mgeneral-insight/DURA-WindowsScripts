$scriptPath = "C:\scripts\insight"
$callStack = Get-PSCallStack
if ($callStack | Where-Object ScriptName) {
    $topLevelscriptPath = ($callStack | Where-Object ScriptName).ScriptName[-1]
    $topLevelScript = (Get-Item -Path $topLevelscriptPath).Name
    $topLevelScriptBase = (Get-Item -Path $topLevelscriptPath).BaseName
}

function LogMessage {
    param (
        [string]$Message,
        [string]$Severity = "Info"
    )
    $TimeStamp = Get-Date
    if (!(Test-Path -path "$scriptPath\Logs")) { $path = New-Item -Path "$scriptPath\Logs" -ItemType Directory }
    $LFTimeStamp = Get-Date -Format "yyyyMMdd"
    if (!($LogFile) { $LogFile = "$scriptPath\Logs\$LFTimeStamp-$topLevelScriptBase.log" }
    $Severity = "[$Severity]"
    $LogEntry = "$TimeStamp : $Severity : $Message"
    if ($Severity -eq "[Error]") { Write-Host "$LogEntry" -ForegroundColor Red }
    elseif ($Severity -eq "[Warn]") { Write-Host "$LogEntry" -ForegroundColor Yellow }
    elseif ($Severity -eq "[Info]") { Write-Host "$LogEntry" }
    Add-Content -Path $LogFile -Value $LogEntry 

}

function UpdateScript {
    if (!(Test-Path -path "$scriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/$topLevelScript" -OutFile "$scriptPath\temp\$topLevelScript" -ErrorVariable DownloadFail
    if ($DownloadFail) { 
        LogMessage -Message "Failed to check for updates, Exiting" -Severity Error
        Exit 1
    }
    $LatestHash = (Get-FileHash -Path "$scriptPath\temp\$topLevelScript").Hash
    if (!(Test-Path -Path "$scriptPath\$topLevelScript")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = (Get-FileHash -Path "$scriptPath\$topLevelScript").Hash
    }
    if ($CurrentHash -ne $LatestHash) {
        LogMessage -Message "$topLevelScript is not latest version, updating and restarting script."
        Copy-Item -Path "$scriptPath\temp\$topLevelScript" -Destination "$scriptPath\$topLevelScript" -Recurse
        & $topLevelscriptPath
        exit
        #! Verify script restarts with updated code
    } else {
        LogMessage -Message "$topLevelScript is up to date."
    }
    Remove-Item -Path "$scriptPath\temp\$topLevelScript" -Force
}

function UpdateFunctions {
    if (!(Test-Path -path "$scriptPath\temp")) { $path = New-Item -Path "$scriptPath\temp" -ItemType Directory }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mgeneral-insight/DURA-WindowsScripts/main/functions.ps1" -OutFile "$scriptPath\temp\functions.ps1"
    $LatestHash = (Get-FileHash -Path "$scriptPath\temp\functions.ps1").Hash
    if (!(Test-Path -Path "$scriptPath\functions.ps1")) {
        $CurrentHash = "NULL"
    } else {
        $CurrentHash = (Get-FileHash -Path "$scriptPath\functions.ps1").Hash
    }
    if ($CurrentHash -ne $LatestHash) {
        LogMessage -message "Functions.ps1 is not latest version, updating and restarting script."
        Copy-Item -Path "$scriptPath\temp\functions.ps1" -Destination "$scriptPath\functions.ps1" -Recurse
    } else {
        LogMessage -Message "Functions.ps1 is up to date."
    }
    Remove-Item -Path "$scriptPath\temp\functions.ps1"
}
