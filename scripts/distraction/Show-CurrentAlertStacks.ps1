<#
.SYNOPSIS
show random alerts to simulate monitoring output
.DESCRIPTION
Provide a battlescreen to simulate a live CLI session with interactive logs.
Interactive output with the possibility to execute
arbitrary commands without any real meaning.
Makes the console screen to look like you're doing
something important.

#>
[CmdletBinding()]
param()
#Global variables:
$loglevels = @(
  @{"text"="Debug"; "color"="gray";},
  @{"text"="Info"; "color"="white";},
  @{"text"="Warning"; "color"="cyan";},
  @{"text"="Error"; "color"="yellow";},
  @{"text"="Fatal"; "color"="red";}
)
$stats = @{
  "refreshRate"=100;
}
$global_ConsoleRows = @()

function New-RandomLogRow {
  $level = $loglevels[$(get-random -min 0 -max ($loglevels.count))]
  
  $verbs = get-verb
  $verb = $verbs[$(get-random -min 0 -max $($verbs.count -1))].Verb
  $Group = $verbs[$(get-random -min 0 -max $($verbs.count -1))].Group
  $debugstring = "{0}{1}" -f (random -min 10000000 -max 90000000).toString('X8'), (random -min 10000000 -max 90000000).toString('X8')
  
  $msg = ("{0} {1} {2}" -f $Group,$verb,$debugstring)
  return $(New-LogRow -LogLevel $level -Message $msg)
}
function New-LogRow {
  <#
  .DESCRIPTION
  create a log string with its own show function and embedded color property
  #>
  param(
    [object]$LogLevel,
    [String]$Message
  )
  $stats.$($level.text) += 1
  $timestamp = $(get-date ).toString('yyyy-MM-dd HH:mm:ss')
  $format = "[{0}][{1,-7}] {2}"
  $logtext = $($format -f $timestamp,$LogLevel.text,$Message)
  $logtext = Add-Member -InputObject $logtext NoteProperty -Name color -Value $loglevel.color -PassThru
  $logtext = Add-Member -InputObject $logtext ScriptMethod -Name "show" -Value {
    write-host $this -foreground $this.color
  } -PassThru
  return $logtext
}

function New-LogRowStack {
  $rows = @()
  $height = $Host.UI.RawUI.WindowSize.height -1
  0..$height | foreach { $rows += New-RandomLogRow }
  return $rows
}
function Remove-CommandChar {
  param(
    [String]$command
  )
  # Remove char from end of searchstring:
  $len = $command.length
  if ($len -gt 1){
    $command = @(0..($len -2) | foreach { $command[$_] }) -join ""
  }
  else {
    $command = ""
  }
  return $command
}
function Show-CurrentScreen {
  param(
    [Array]$rows = @(),
    [String]$command
  )
  $startpoint_Y = 3
  $x = 5
  $MaxHeight = $Host.UI.RawUI.WindowSize.Height -9
  $maxIdx = $MaxHeight -= $rows.count
  if ($maxIdx -lt 0 ) {
    $maxIdx = $maxIdx * -1
  }
  $rows = @($maxIdx..$($rows.count -1) | foreach { $rows[$_] })
  $y = $startpoint_Y
  $rows |foreach { 
    $msg = Assert-MsgRow -Msg $_ -x $x -y $y
    Write-StringToScreenLocation -message $msg -x $x -y $y;
    $y++;
  }
  return $rows
}
function Assert-MsgRow {
  param(
    [String]$msg,
    [int]$x,
    [int]$y
  )
  $pad_x = $Host.UI.RawUI.WindowSize.Width - $x - $msg.length
  0..$pad_x | foreach { $msg += " " }
  return $msg
}
function Show-ConsoleRow {
  param(
    [String]$command
  )
  $msg = "live console> $command"
  #write-to bottom:
  $y = $Host.UI.RawUI.WindowSize.Height -3
  $x = 5
  # The amount of clear space needed to pad to right:
  $msg = Assert-MsgRow -Msg $msg -x $x -y $y
  # Actual write
  Write-StringToScreenLocation -message $msg -x $x -y $y
}
function Show-InfoRow {
  param(
    [object]$Stats=@{}
  )
  $statitems = @($Stats.keys | foreach { "$_ : $($Stats.$_)" })
  $msg = ($statitems -join ", ")
  $msg = "[ stats ] $msg"
  #write-to bottom:
  $y = $Host.UI.RawUI.WindowSize.Height -4
  $x = 5
  # The amount of clear space needed to pad to right:
  $msg = Assert-MsgRow -Msg $msg -x $x -y $y
  # Actual write
  Write-StringToScreenLocation -message $msg -x $x -y $y
}

function Write-StringToScreenLocation {
  param(
    [string]$message,
    [int]$x=0,
    [int]$y=0
  )
  $Host.UI.RawUI.CursorPosition = New-object System.Management.Automation.Host.Coordinates $x, $y
  $Host.UI.Write($message)
}



# Generate a range of characters
$charRange = @([int]$([char]"A")..[int]$([char]"Z") |foreach { [char]$_})
# Recast console rows
$global_ConsoleRows = New-LogRowStack
cls
$continue = $true
Show-ConsoleRow -Command ""
Show-InfoRow -Stats $stats
while($continue) {
  if ([console]::KeyAvailable) {
    $input = [System.Console]::ReadKey('NoEcho,IncludeKeyDown')
    if ( $charRange -contains $input.key ) {
      $command += ([String]$input.key).tolower()
    }
    else {
      switch ( $input.key) {
        Escape { $continue = $false }
        Enter {
          $level = @{"text"="Action"; "color"="Green";}
          $global_ConsoleRows += $(New-LogRow -LogLevel $level -message $command)
          $command = ""
        }
        Spacebar { $command += " " }
        Backspace { $command = Remove-CommandChar -command $command }
        # Refreshrate can be increased or decreased
        DownArrow { $stats.refreshRate += 10 }
        UpArrow { $stats.refreshRate -= 10 }
      }
    }
    # if any key pressed. try to draw to bottom
    Show-ConsoleRow -Command $command
  }
  else {
    $global_ConsoleRows = Show-CurrentScreen -rows $global_ConsoleRows -command $command
    Show-InfoRow -Stats $stats
    $global_ConsoleRows += New-RandomLogRow
    sleep -m $stats.refreshRate
  }
}
