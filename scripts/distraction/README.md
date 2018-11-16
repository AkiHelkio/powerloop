# Distractions
A distraction simulation for log analysis

`Show-CurrentAlertStacks.ps1` introduces an alternative console output view for interactive output.

Instead of writing with '\r' and nonewline. Example:

```powershell
write-host "live console> $command`r" -nonewline
```

The approach is to flush the screen once and then start printing into specific locations with `System.Management.Automation.Host.Coordinates` and

`$Host.UI.RawUI.CursorPosition`

Additional whitespace clearing is implemented into the rows themselves.

### Example output
```


     [2018-11-16 23:17:02][Warning] Lifecycle Enter 03E501B102F26984   
     [2018-11-16 23:17:03][Fatal  ] Lifecycle Enter 00FF42460184AAC3   
     [2018-11-16 23:17:03][Fatal  ] Security Unprotect 02D74A3402DB9F0E
     [2018-11-16 23:17:03][Warning] Lifecycle Expand 01E9E53D04413862  
     [2018-11-16 23:17:03][Fatal  ] Lifecycle Group 04848FA9020574D1   
     [2018-11-16 23:17:03][Fatal  ] Security Assert 0100CC1D047EC473   
     [2018-11-16 23:17:03][Warning] Common Disable 02DCF3DE01D37B5F    
     [2018-11-16 23:17:04][Info   ] Lifecycle Restart 043A9C6602FA582B 
     [2018-11-16 23:17:04][Debug  ] Common Switch 01C6FDD501CD8C17     

     [ stats ] refreshRate : 100 
     live console> command example
     
     
```