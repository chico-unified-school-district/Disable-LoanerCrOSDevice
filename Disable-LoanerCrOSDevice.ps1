<#
.SYNOPSIS
 Queries Aeries (MSSQL) for Chromebooks marked as loaners and disables those devices in Google Workspace via gam.exe.

.DESCRIPTION
 This script:
 - Queries an Aeries (SIS) database for Chromebook records flagged as loaners.
 - Looks up each Chromebook in Google Workspace using gam.exe.
 - Disables the ChromeOS device in Google Workspace (unless run with -WhatIf).
 The script expects dbatools and CommonScriptFunctions modules to be available and gam.exe to be reachable on the system.

.PARAMETER SQLServer
 The SQL Server instance name or network address hosting the Aeries database. (Required, string)

.PARAMETER SQLDatabase
 The name of the Aeries database. (Required, string)

.PARAMETER SQLCredential
 PSCredential object for authenticating to the SQL Server (username/password). Use Get-Credential to create this. (Required, PSCredential)

.PARAMETER WhatIf
 Switch to perform a dry-run. When present, actions that would disable devices are not executed. Use this to validate results before making changes. (Switch)

.EXAMPLE
 # Dry run: show which devices would be disabled without calling gam.exe
 $cred = Get-Credential
 .\Disable-LoanerCrOSDevice.ps1 -SQLServer "sqlserver\instance" -SQLDatabase "AeriesDB" -SQLCredential $cred -WhatIf

.EXAMPLE
 # Live run: perform actions (ensure service account and gam are configured)
 $cred = Get-Credential
 .\Disable-LoanerCrOSDevice.ps1 -SQLServer "sqlserver\instance" -SQLDatabase "AeriesDB" -SQLCredential $cred

.EXAMPLE
 # Run with Verbose to get more output
 .\Disable-LoanerCrOSDevice.ps1 -SQLServer "sqlserver\instance" -SQLDatabase "AeriesDB" -SQLCredential $cred -Verbose

.INPUTS
 System.Data.DataRow — rows returned by the SQL query (via New-SqlOperation).

.OUTPUTS
 Writes log messages and progress to the console. The script does not return structured objects by default (it writes PSCustomObjects when looking up device info).

.NOTES
 - Required modules: dbatools (for New-SqlOperation) and CommonScriptFunctions (script helper functions).
 - Ensure gam.exe is installed and the service account used by gam is delegated with Chrome device management scope.
 - The script sets $gam = 'C:\GAM7\gam.exe' by default. Modify that variable in the script or place gam.exe on PATH to override.
 - Do not store credentials in source control. Use a secured account with least privilege.
 - Test with -WhatIf in a staging environment before running in production.
 - Run scheduled tasks under a service account that has network access and permission to run gam.exe.

.LINK
 https://github.com/jay0lee/GAM

.AUTHOR
Justin Cooper

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
 [Alias('wi')]
 [switch]$WhatIf
)

function Get-SqlData ($sqlParams) {
 begin { $sql = Get-Content -Path .\sql\disable.sql -Raw }
 process {
  $data = New-SqlOperation @sqlParams -Query $sql
  Write-Host ('{0},Count: {1}' -f $MyInvocation.MyCommand.Name, @($data).count)
  $data
 }
}

function Disable-GDevice {
 process {
  $msg = $MyInvocation.MyCommand.Name, $_.barCode
  if ($_.status -eq 'DISABLED') { return (Write-Verbose ('{0},{1},CrOS Device already disabled' -f $msg)) }
  Write-Host ('{0},{1},{2}' -f (logDate), $MyInvocation.MyCommand.Name, $_.barCode) -F Blue
  Write-Host "& $gam update cros $($_.id) action disable" -F Blue
  if (!$WhatIf) { (& $gam update cros $_.id action disable) *>$null }
 }
}

function Get-CrosDev {
 begin { $crosFields = 'deviceId,status,serialNumber' }
 process {
  $msg = $MyInvocation.MyCommand.Name, $_.barCode
  Write-Verbose ('{0},{1}' -f $msg)
  # Write-Verbose "& $gam print cros query `"asset_id: $($_.barCode)`" fields $crosFields"
  ($dev = & $gam print cros query "asset_id: $($_.barCode)" fields $crosFields | ConvertFrom-Csv) *>$null
  if (!$dev) { return (Write-Verbose ('{0},{1}, CrOS device not found' -f $msg)) }
  $obj = [PSCustomObject]@{
   sn      = $_.sn
   barCode = $_.barCode
   dts     = $_.dts
   id      = $dev.deviceId
   status  = $dev.status
  }
  $obj
  Write-Verbose ($obj | Out-String)
 }
}

function logDate { Get-Date -Format o }

if ($WhatIf) { Show-TestRun }

Import-Module -Name CommonScriptFunctions, dbatools

$sqlParams = @{
 Server     = $SQLServer
 Database   = $SQLDatabase
 Credential = $SQLCredential
}

$gam = 'C:\GAM7\gam.exe'

Get-SqlData $sqlParams | Get-CrosDev | Disable-GDevice