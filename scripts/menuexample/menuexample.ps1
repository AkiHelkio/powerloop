import-module ..\..\imports\menulib.psm1 -Force
$header = @("id","Name","Version","Company")
$data = @(ps | select $header)
$searchcolumn = "Name"
$result = Start-ThereCanOnlyBeOneMenu -Data $data -Header $header -SearchColumn "Name"