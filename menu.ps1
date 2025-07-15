. c:\scripts\insight\functions.ps1
UpdateScript

clear-host
get-content -raw c:\scripts\insight\logo.txt
Write-Host @"
Select a task to perform:

1) Check for Windows Updates on a Server
2) Configure New Windows Server
3) Install Software (CBP/Qualys/Splunk/DataDog/nCentral) on Windows Server
4) Check Software Version on Windows Server
5) Update Software on Windows Server
6) Move a Server to Carbon Black Protection Bypass Policy
7) Force Qualys Scan
8) Create gMSA Account
9) Update Azure Connected Machine Agent

"@

Do { $selection = Read-Host "Choose an option (1-9)" }
Until (1..9 -contains $selection)

if ($selection -eq "1") { & "c:\scripts\insight\updateWIN.ps1" } 
elseif ($selection -eq "2") { & "c:\scripts\insight\configureVM.ps1" } 
elseif ($selection -eq "3") { & "c:\scripts\insight\installSW.ps1" }
elseif ($selection -eq "4") { & "C:\scripts\insight\updateSW.ps1" } 
elseif ($selection -eq "5") { & "C:\Scripts\insight\upgradeSplunk.ps1" } 
elseif ($selection -eq "6") { & "C:\Scripts\insight\CBPdisable.ps1" } 
elseif ($selection -eq "7") { & "C:\Scripts\insight\forceQualysScan.ps1" } 
elseif ($selection -eq "8") { & "C:\Scripts\Insight\CreategMSAAccount.ps1" } 
elseif ($selection -eq "9") { & "C:\Scripts\Insight\updateAZMCagent.ps1" }
