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
  if ($_.status -eq "DISABLED") { return (Write-Verbose ('{0},{1},CrOS Device already disabled' -f $msg)) }
  Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, $_.barCode) -F Blue
  Write-Host "& $gam update cros $($_.id) action disable" -F Blue
  if (!$WhatIf) { (& $gam update cros $_.id action disable) *>$null }
 }
}

function Get-CrosDev {
 begin { $crosFields = "deviceId,status,serialNumber" }
 process {
  $msg = $MyInvocation.MyCommand.Name, $_.barCode
  Write-Verbose ('{0},{1}' -f $msg)
  # Write-Verbose "& $gam print cros query `"asset_id: $($_.barCode)`" fields $crosFields"
  ($dev = & $gam print cros query "asset_id: $($_.barCode)" fields $crosFields | ConvertFrom-CSV) *>$null
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

Show-TestRun

Import-Module -Name CommonScriptFunctions, dbatools

$sqlParams = @{
 Server                 = $SQLServer
 Database               = $SQLDatabase
 Credential             = $SQLCredential
}

$gam = '.\bin\gam.exe'

Get-SqlData $sqlParams | Get-CrosDev | Disable-GDevice