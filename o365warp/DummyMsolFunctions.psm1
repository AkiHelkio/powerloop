<#
DummyMsolFunctions.psm1.
Simulate msol functionality without actually connecting or needing subscription to o365
#>
function Connect-MsolService {
  param(
    [object]$Credential
  )
  return "Connected"
}
function Get-RandomObjectID {
  $id = @(
    (random -min 10000000 -max 90000000).toString('X8'),
    (random -min 1000 -max 9000).toString('X4'),
    (random -min 1000 -max 9000).toString('X4'),
    (random -min 1000 -max 9000).toString('X4'),
    (random -min 10000000 -max 90000000).toString('X8')
  )
  return [String]$($id -join "-")
}
function Get-MsolPartnerContract {
  # Generate dummy tenants from verb group names:
  $data = @(get-verb |select -expand Group | select -Unique | foreach {
    new-object psobject -property @{
      "ExtensionData"     = "DummyDataObject";
      "ContractType"      = "SupportPartnerContract";
      "Name"              = "$($_) Company";
      "DefaultDomainName" = "$($_).company.onmicrosoft.com".toLower();
      "ObjectId"          = Get-RandomObjectID;
      "PartnerContext"    = Get-RandomObjectID;
      "TenantId"          = new-object psobject -property @{
        "Guid" = Get-RandomObjectID;
      }
    }
  })
  return $data
}