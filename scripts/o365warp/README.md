# o365warp
A example for creating a o365 connection to tenants within the primary account.
Reduces the need to know specific tenant passwords by delegating the primary account to access all tenants.

### Files:
- `README.md`, this file
- `.\new-tenantsession.ps1` the actual delegated connection
- `.\DummyMsolFunctions.psm1` a library for local testing. Use context 'Test'.
- `.\warp.ps1` basic script functionality with a cli parameter
- `.\warpMenu.ps1` script with a menu search

### Data flow


```
 .\warp.ps1 -Tenant mytenant
           |
  [Login]  +  --> msonline
           |
      list +  <-- Tenant list from msonline
           |
       [filter] --> if only one --> Open new window with filtered result
           |                              |
           |                .\new-tenantsession.ps1 -TenantDomainName result
          else              +------------------------------------+
           |                |     [Login] + --> o365Exchange     |
          Alert             |             + Do additional tasks  |
                            |             + Leave session open   |
                            +------------------------------------+
```


#### Examples with menu

Main loop with dummy data

```
Info.............: ''
Searching for....: ''
                  Name                      DefaultDomainName                         TenantId
        Common Company         common.company.onmicrosoft.com 0113B5A0-0998-21EA-15E2-02CA31A3
          Data Company           data.company.onmicrosoft.com 046269EE-12D5-16C2-060C-03E47BAC
     Lifecycle Company      lifecycle.company.onmicrosoft.com 0433651C-1629-0C31-2181-0187AEC8
    Diagnostic Company     diagnostic.company.onmicrosoft.com 03C43373-12A7-16EA-0FB9-043C4021
Communications Company communications.company.onmicrosoft.com 01106C71-05B6-0701-133B-019822D7
      Security Company       security.company.onmicrosoft.com 00F4FDBB-1E2C-22E0-14DB-04603926
         Other Company          other.company.onmicrosoft.com 0389BAEA-082B-0916-192B-036AFF8E
No tenant found with filter
Continue searching? (y/n)
```

Example search result:

```
Info.............: ''
Searching for....: 'data'
        Name            DefaultDomainName                         TenantId
Data Company data.company.onmicrosoft.com 03309B3D-0A32-1A70-0F74-02AE1F24
Your filtered result is: 'data.company.onmicrosoft.com'
Continue with connection to tenant (y) ?
```