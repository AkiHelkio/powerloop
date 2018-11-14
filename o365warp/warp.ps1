<#
.SYNOPSIS
Simulates a warp to tenant o365 exchange with primary account credentials
#>
[CmdletBinding()]
param(
  [Parameter(Position=0,mandatory=$true)]
  [String]$TenantName
)

# Import example functions. Disable on actual usage
import-module .\DummyMsolFunctions.psm1

# Ask your creds:
$creds = Get-Credential

# Create connection to your cloud
Connect-MsolService -Credential $creds

# List your partner contracts
$data = Get-MsolPartnerContract
# Show them
$data | select Name, DefaultDomainName, @{n="TenantId";e={$_.TenantId.Guid}} | ft -a

# Select one by ps1 param:
$selected = $data | where { $_.Name -like "*$TenantName*" } | select -first 1
if ($selected -ne $null){
  # Open new connection window
  write-host "Filtered result" -foreground cyan
  $selected |ft -a
  write-host "Continue (y) ?" -foreground yellow
  $c = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  if ($c.Character -eq "y") {
    Start-Process powershell -ArgumentList "-noexit",".\new-tenantsession.ps1 -TenantDomainName $($selected.DefaultDomainName)"
  }
}
else {
  write-host "No tenant found with filter" -foreground red -background black
}

