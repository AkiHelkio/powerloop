# o365warp
A example for creating a o365 connection to tenants within the primary account.
Reduces the need to know specific tenant passwords by delegating the primary account to access all tenants.

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
