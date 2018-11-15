import-module ..\..\imports\menulib.psm1 -Force
$header = @("id","Name","ProductVersion","Company")
$data = @(ps | select $header)
$searchcolumn = "Name"
return @(Start-ActiveMenu -Data $data -Header $header -SearchColumn "Name")