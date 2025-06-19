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
