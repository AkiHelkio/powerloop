<#
.SYNOPSIS
library of menu functions for 'Start-ActiveMenu'
#>
function Get-DatasetFilter {
  <#
  .DESCRIPTION
  gets dataset
  finds out the columns, gets the max widths
  prepares a filter out row which keeps the data in order.
  returns a string of '{0,column1Lengthmax}{1,column2length}etc.'
  #>
  [CmdletBinding()]
  param(
    [Array]$data=@()
  )
  
}
function Read-HostKey {
  [CmdletBinding()]
  param()
  $input = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  return New-Object psobject -property @{
    "Key"       = $input.VirtualKeyCode;
    "Character" = $input.Character
  }
}

function Show-MenuTexts {
  <#
  .DESCRIPTION
  Show menu and search results from filterRows
  with a pretty print header fields instead of
  entire data set columns
  #>
  [CmdletBinding()]
  param(
    [Array]$FilterRows=@(),
    [Array]$header=@(),
    [String]$infotext="",
    [String]$infocolor="cyan",
    [String]$searchString=""
  )
  cls
  # Ditch data which will not fit the screen:
  $inforows = 5          # Padding to keep info rows on top
  $height = $host.ui.RawUI.WindowSize.height - $inforows
  if ($FilterRows.count -gt $height){
    $upto = $FilterRows.count - $height
    $FilterRows = 0..$($FilterRows.count - $upto) | foreach { $FilterRows[$_] }
  }
  write-host ("Info.............: '{0}'" -f $infotext) -foreground $infocolor
  write-host ("Searching for....: '{0}'" -f $searchString)
  foreach ( $row in $FilterRows ) {
    $srow = @()
    foreach ( $h in $header ) {
      $srow += [String]$($row.$h)
    }
    write-host $($srow -join ", ") -foreground "white"
  }
}
function Start-ActiveMenu {
  <#
  .SYNOPSIS
  The main menu which will provide a filter feature by column

  .DESCRIPTION
  Basic specs:
    Provide a data array, a header array and a column to filter from.
    Write letters to filter the data
    ESC = Stop loop and exit to shell
    ENTER = return selected filtered value
    BACKSPACE = remove letter from search query
  #>
  [CmdletBinding()]
  param(
    [Array]$Data=@(get-verb | select Verb | sort Verb),
    [Array]$Header=@("Verb"),
    [String]$SearchColumn="Verb",
    [int]$MaxResults=1
  )

  $KeyCode = @{
    "ESC"       = 27;
    "ENTER"     = 13;
    "BACKSPACE" = 8;
    "A"         = 65;
    "Z"         = 90;
  }
  
  $loop = $true       # keep looping
  $infotext = ""      # used for row of text between loops
  $infocolor = "Cyan" # color for info row
  $searchString = ""  # the query searchString
  $export = ""
  while ($loop) {
    # Force selection into an array
    $selection = @($data | where { $_.$SearchColumn -like "*$searchString*" })
    # print everything necessary after screen clearing
    Show-MenuTexts -FilterRows $selection `
    -header $header `
    -infotext $infotext `
    -infocolor $infocolor `
    -searchString $searchString
    
    # read the input:
    $input = Read-HostKey
    
    # Determine action
    
    if ($input.key -eq $KeyCode.ESC) {
      # Quit
      $loop = $false
      write-host "Have a nice day :)" -foreground cyan
    }
    elseif ($input.key -eq $KeyCode.BACKSPACE) {
      # Remove char from end of searchstring:
      $len = $searchString.length
      if ($len -gt 1){
        $searchString = @(0..($len -2) | foreach { $searchString[$_] }) -join ""
      }
      else {
        $searchString = ""
      }
    }
    elseif ($input.key -eq $KeyCode.ENTER) {
        if ($selection.count -gt 0 -and $selection.count -le $MaxResults) {
          $loop = $false
          # Force the return value to use the filtered value:
          $export = 0..($MaxResults -1) | foreach { $selection[$_] }
        }
        elseif ($selection.count -eq 0){
          $infotext = "Nothing to select from search"
          $infocolor = "Red"
        }
        else {
          $infotext = "Multiple selections. Exceeded max results: ($MaxResults)"
          $infocolor = "Yellow"
        }
    }
    # letters from A to Z contain the input keycode?
    elseif ($($KeyCode.A)..$($KeyCode.Z) -contains $input.key){
      # normal lowercase letters
      # Add the character to searchString:
      $searchString += [String]$($input.Character)
      $infotext = ""
      $infocolor = "cyan"
    }
  }
  return $export
}