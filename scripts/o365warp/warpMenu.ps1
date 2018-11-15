<#
.SYNOPSIS
Simulates a warp to tenant o365 exchange with primary account credentials
#>
[CmdletBinding()]
param(
  [String]$Mode="Production"
)

if ($Mode -eq "Test") {
# Import example functions. Disable on actual usage
import-module .\DummyMsolFunctions.psm1 -Force
}
else {
import-module msonline -Force
}
import-module ..\..\imports\menulib.psm1 -Force

# Ask your creds:
$creds = Get-Credential

# Create connection to your cloud
Connect-MsolService -Credential $creds

# List your partner contracts and determine specs for menu
$data = Get-MsolPartnerContract
$data = $data | select Name, DefaultDomainName, @{n="TenantId";e={$_.TenantId.Guid}}
$header = @("Name","DefaultDomainName","TenantId")
$searchcolumn = "Name"

$loop = $true
while ($loop) {
  $result = @(Start-ActiveMenu -Data $data -Header $header -SearchColumn $searchcolumn -MaxResults 1)
  if ($result.count -eq 1){
    # Provide debug:
    $result = $result[0]
    write-host "Your filtered result is: '$($result.DefaultDomainName)'" -foreground cyan
    write-host "Continue with connection to tenant (y) ?" -foreground yellow
    $c = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($c.Character -eq "y") {
      # Open new connection window
      Start-Process powershell -ArgumentList "-noexit",".\new-tenantsession.ps1 -TenantDomainName $($result.DefaultDomainName) -Mode Test"
    }
  }
  else {
    write-host "No tenant found with filter" -foreground red
    write-host "Continue searching? (y/n)" -foreground yellow
    $c = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($c.Character -ne "y") {
      $loop = $false
    }
  }
}

