function Clear-SessionData {
 Write-Verbose 'Clearing session and module data'
 Get-Module -name *tmp* | Remove-Module -Confirm:$false -Force
 Get-PSSession | Remove-PSSession -Confirm:$false
}