# Menu example
A interactive and reusable menu example

Provide a data array, a header array and a column to filter from.

- Write letters to filter the data
- ESC = Stop loop and exit to shell
- ENTER = return selected filtered value
- BACKSPACE = remove letter from search query

## example usage

Example menu without any switches will use get-verb as dummy data.

```powershell
import-module ..\..\imports\menulib.psm1 -Force
Start-ThereCanOnlyBeOneMenu
```

#### Example with processes

Search from current processes by column name with a customized header:

```powershell
import-module ..\..\imports\menulib.psm1 -Force
$header = @("id","Name","Version","Company")
$data = @(ps | select $header)
$searchcolumn = "Name"
$result = Start-ThereCanOnlyBeOneMenu -Data $data -Header $header -SearchColumn "Name"
```

##### Example output:
```
```