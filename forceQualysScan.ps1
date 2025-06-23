. c:\scripts\insight\functions.ps1
UpdateScript

if (!($server)) { $server = Read-Host -Prompt "Enter Server Name" }
if (!(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue)) { 
    Write-Host "ERROR: Could not ping $server" 
    exit 1
}
$key = "HKLM:\Software\Qualys\QualysAgent\ScanOnDemand\Vulnerability"
$valueName = "ScanOnDemand"
$value = 1

Invoke-Command -ComputerName $server -ScriptBlock {
    Set-ItemProperty -Path $using:key -Name $using:valueName -Value $using:value -Type DWord
}