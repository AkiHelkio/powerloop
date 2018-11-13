<#
.SYNOPSIS
async menu example

#>

# Using words from get-verb as example data:
$data = @(get-verb | select -expand Verb | sort )

$loop = $true       # keep looping
$infotext = ""      # used for row of text between loops
$infocolor = "Cyan" # color for info row
$searchString = ""  # the query searchString
$export = ""
while ($loop) {
  cls
  # Force selection into an array
  $selection = @($data | where { $_ -like "*$searchString*" })
  # print everything necessary after screen clearing
  write-host $( $selection -join ", " )  # prettyer print
  write-host ("info: '{0}'" -f $infotext) -foreground $infocolor
  write-host ("Search is: '{0}'" -f $searchString)
  # read the input:
  $input = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  $key = $input.VirtualKeyCode
  # ESC
  if ($key -eq 27) {
    # ESC
    $loop = $false
    write-host "Have a nice day :)" -foreground cyan
  }
  elseif ($key -eq 8) {
    # backspace
    # Remove char from end of searchstring:
    $len = $searchString.length
    if ($len -gt 1){
      $searchString = @(0..($len -2) | foreach { $searchString[$_] }) -join ""
    }
    else {
      $searchString = ""
    }
  }
  elseif ($key -eq 13) {
    # Enter
    if ($selection.count -eq 1) {
      $loop = $false
      # Force the return value to use the filtered value:
      write-host ("Selected: {0}" -f $selection[0])
      $export = $selection[0]
    }
    elseif ($selection.count -eq 0){
      $infotext = "Nothing to select from search"
      $infocolor = "Red"
    }
    else {
      $infotext = "Multiple selections. Please choose only one"
      $infocolor = "Yellow"
    }
  }
  elseif (65..90 -contains $key){
    # normal lowercase letters
    # Add the character to searchString:
    $searchString += [String]$($input.Character)
    $infotext = ""
    $infocolor = "cyan"
  }
}
return $export
