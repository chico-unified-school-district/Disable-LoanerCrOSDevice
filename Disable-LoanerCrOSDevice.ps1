<# 
.SYNOPSIS
 Queries Aeries for Chromebooks marked as loaners and disables them via gam.exe.
.DESCRIPTION
 Run with Test and/or Log switches as well as common parameters
.EXAMPLE
 Update-LoanerCBs.ps1 -SISCOnnection server\database -SISCredential $sisCredObject
.EXAMPLE
 Update-LoanerCBs.ps1 -SISCOnnection server\database -SISCredential $sisCredObject -WhatIf -Verbose
.INPUTS
 SQL data
.OUTPUTS
 Log Messages
.NOTES
 Thanks Wendy Kwo for the nice SQL Statements!
 Thank you Jay Lee for gam.exe!
 https://github.com/jay0lee/GAM
#>

[cmdletbinding()]
param ( 
 # SQL server name
 [Parameter(Mandatory = $True)]
 [Alias('SISServer')]
 [string]$SQLServer,
 # SQL database name
 [Parameter(Mandatory = $True)]
 [Alias('SISDatabase', 'SISDB')]
 [string]$SQLDatabase,
 # Aeries SQL user account with SELECT permission to STU table 
 [Parameter(Mandatory = $True)]
 [Alias('SISCred')]
 [System.Management.Automation.PSCredential]$SQLCredential,
 [switch]$WhatIf
)

Clear-Host; $error.clear() # Clear Screen and $error.

# Variables
$gamExe = '.\lib\gam-64\gam.exe'

# Imported Functions
. .\lib\Add-Log.ps1 # Format Log entries
. .\lib\Invoke-SqlCommand.ps1 # Useful function for querying SQL and returning results

# Processing
$crosFields = "deviceId,status,serialNumber"

# Disable
Write-Host "Check for devices to Disable" -Fore Green
$disableQuery = Get-Content -Path .\sql\disable.sql -Raw
$disableLoaners = Invoke-SqlCommand -Server $SQLServer -Database $SQLDatabase -Cred $SQLCredential -Query $disableQuery

foreach ($dev in $disableLoaners) {
 $sn = $dev.serialNumber
 $barCode = $dev.BarCode
 ($crosDev = & $gamExe print cros query "id: $sn" fields $crosFields | ConvertFrom-CSV) *>$null # *>$null suppresses noisy output
 $id = $crosDev.deviceId

 Write-Debug "Process $sn"
 if ($crosDev.status -eq "ACTIVE") {
  # If cros device set to 'active' then disable
  Add-Log disable "$sn,$barCode" -Whatif:$WhatIf
  if (!$WhatIf) { & $gamExe update cros $id action disable *>$null }`
  
 }
 else { Write-Verbose "$sn,Skipping. Already Disabled" }
}