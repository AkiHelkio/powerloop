<#
.SYNOPSIS
Connects to o365 tenant domain with own credentials
#>
[CmdletBinding()]
param(
[String]$TenantDomainName=""
)
$Host.UI.RawUI.WindowTitle = "o365 Connection to '$TenantDomainName'"
write-host "Connecting to: '$TenantDomainName'"

$credentials = get-credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid?DelegatedOrg=$TenantDomainName -Credential $credentials -Authentication Basic -AllowRedirection
Import-PSSession $Session
