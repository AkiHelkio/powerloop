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
write-host "All available tenants:" -foreground cyan
$data | select Name, DefaultDomainName, @{n="TenantId";e={$_.TenantId.Guid}} | ft -a

# Select one by ps1 param:
$selected = @($data | where { $_.Name -like "*$TenantName*" })
if ($selected.count -gt 0){
  # Provide debug:
  write-host "Filtered results:" -foreground cyan
  $selected | select Name, DefaultDomainName |ft -a
  if ($selected.count -eq 1) {
    write-host "Continue with connection to tenant (y) ?" -foreground yellow
    $c = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($c.Character -eq "y") {
      # Open new connection window
      Start-Process powershell -ArgumentList "-noexit",".\new-tenantsession.ps1 -TenantDomainName $($selected.DefaultDomainName)"
    }
  }
  else {
    write-host "Multiple search results. Please specify which name to connect to" -foreground yellow
  }
}
else {
  write-host "No tenant found with filter" -foreground red
}

