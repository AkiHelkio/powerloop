<#
.SYNOPSIS
library of menu functions for 'Start-ActiveMenu'
#>
function Select-DatasetRowFormat {
  <#
  .SYNOPSIS
  A dataset to string format widths by columns
  .DESCRIPTION
  input a dataset with a header and padding width.
  finds out the column max widths and creates a row format
  returns a array of objects containing format positions:
  '{0,column1Length}'
  '{1,column2length}'
  #>
  [CmdletBinding()]
  param(
  [Array]$data = @(),
  [Array]$header = @(),
  [int]$Padding = 1
  )
  
  function Limit-ReferenceWidths {
    <#
      .SYNOPSIS
      Subfunction; only to be used with primary function
      .DESCRIPTION
      Decrease the max width until sum of widths fit the screen properly.
    #>
    [CmdletBinding()]
    param(
      [object]$ReferenceArray,
      [int]$Padding
    )
    write-debug "ReferenceWidths need limiting"
    # WindowWidth
    $WindowWidth = $host.UI.RawUI.WindowSize.Width
    
    # Count the sum of the max column widths
    $sum = $($references |select -expand MaxWidth | Measure-Object -Sum).sum
    $result = $WindowWidth - $sum - $($Padding * ($header.count -1))
    
    write-debug "Current sum is $sum .. result is $result"
    
    if ( $result -lt 0 ) {
      # reduce max value of MaxWidths values:
      $ReferenceArray | sort MaxWidth,header | select -last 1 | foreach { $_.MaxWidth -= 1 }
      # Recheck:
      $ReferenceArray = Limit-ReferenceWidths -ReferenceArray $ReferenceArray -Padding $Padding
    }
    return $ReferenceArray
  }
  
  # - - - Begin  - - -

  # create reference array
  $references = @()
  foreach ( $h in $header ) {
    $references += new-object psobject -property @{
      "Values"=@($data |select -expand $h);
      "Header"=$h;
      "MaxWidth"=0;
      "Position"="";
    }
  }
  write-debug "Determining maxWidths"
  # Count MaxWidth by value lengths
  foreach ( $ref in $references ) {
    $ref.MaxWidth = $ref.values | foreach { ([string]$($_)).length } | sort | select -last 1
  }
  
  # Limit the width of the columns to fit the screen using nested function calls
  $references = Limit-ReferenceWidths -ReferenceArray $references -Padding $Padding
  
  # Create padding string:
  $i = 0
  $Pads = ""
  while ( $i -lt $Padding ) {
    $Pads += " "
    $i += 1
  }
  
  # Create final positions by provided header order
  $i = 0
  $formatrow = @()
  foreach ( $h in $header ) {
    $references | where { $_.Header -eq $h } | foreach {
      $_.Position = "{$i,$($_.MaxWidth)}";
      $formatrow += $_.Position
    }
    $i += 1
  }
  # Return a format reference row for usage elsewhere:
  return [String]$($formatrow -join $Pads)
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
  entire data set columns. Calls other functions
  to keep column widths aligned properly
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
  $inforows = 6          # Padding to keep info rows on top
  $height = $host.ui.RawUI.WindowSize.height - $inforows
  if ($FilterRows.count -gt $height){
    $upto = $FilterRows.count - $height
    $FilterRows = 0..$($FilterRows.count - $upto) | foreach { $FilterRows[$_] }
  }
  # Provide a dummy header if no data
  if ( $FilterRows.count -gt 0 ) {
    # Ensure widths are correct and provide a row reference:
    $rowformat = Select-DatasetRowFormat -Data $FilterRows -Header $header
  }
  else {
    $rowformat = ""
    $i = 0
    $header | foreach { $rowformat += "{$i} "; $i++ }
  }
  # Actual print of data:
  write-host ("Info.............: '{0}'" -f $infotext) -foreground $infocolor
  write-host ("Searching for....: '{0}'" -f $searchString)
  write-host ("$rowformat" -f $header)
  foreach ( $row in $FilterRows ) {
    $srow = @()
    foreach ( $h in $header ) {
      $srow += [String]$($row.$h)
    }
    write-host ("$rowformat" -f $srow) -foreground "white"
  }
}
function Write-SimpleData {
  <#
  .SYNOPSIS
  A quick and dirty row print
  #>
  [CmdletBinding()]
  param(
    [Array]$data,
    [Array]$header
  )
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
  $export = @()
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
      # Allow filter between 0 and maxresults
      if ($selection.count -gt 0 -and $selection.count -le $MaxResults) {
        $loop = $false
        # Force the return value to use array:
        $export = @(0..($MaxResults -1) | foreach { $selection[$_] })
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