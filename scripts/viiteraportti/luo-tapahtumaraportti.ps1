[CmdletBinding()]
param (
  [string]$tapahtumat = "",
  [switch]$output
)
Begin {
  # tarkastetaan
  if ($tapahtumat.length -lt 1) {
    write-output "Määritä polku Osuuspankin tilitapahtumat csv -tiedostoon komennon ensimmäisenä argumenttina`nEsim: .\luo-tapahtumaraportti.ps1 tapahtumat.csv"
    exit 1
  }
  if (!$(Test-path $tapahtumat)) {
    write-output "Tiedostoa $tapahtumat ei löytynyt!"
    exit 1
  }
  # ladataan csv muistiin käyttäen kovakoodattua otsaketta.
  $csvdata = import-csv $tapahtumat -Delimiter ";" -Encoding UTF7 -Header "Kirjauspäivä","Arvopäivä","Eurot","Laji","Selitys","Saaja","Tilinumero","Viite","Viesti","Arkistointitunnus"
  # korjataan otsake pois
  $csvdata = 1..($csvdata.count-1) | foreach { $csvdata[$_] }
  # kaapataan kaikki uniikit rivit joissa on viite:
  $uniikit_viitteet = $($csvdata | where { $_.viite -ne "" } | select -Unique viite -ExpandProperty viite)
}
Process {
  # raportti lista:
  $raportti = @()
  $i = 0
  #Käsitellään uniikkien kaikki arvot:
  foreach ($viite in $uniikit_viitteet) {
    $i++
    write-progress -activity "Käsitellään ja summataan uniikkeja viitteitä" -status "Summataan: $viite" -PercentComplete (($i / $uniikit_viitteet.count)*100)
    # hae csvdatasta kaikki jossa on viite 'viite n'
    $viiterivit = $csvdata | where { $_.Viite -eq $viite }
    # muunnetaan tekstinä olevat pilkulliset eurot microsoftin ymmärtämään muotoon, konvertoidaan liukuluvuksi ja summataan:
    $summa = $viiterivit | select @{n="eurot";e={$_.Eurot.replace(",",".") -as [float] }} | select -expand Eurot | Measure-Object -Sum | select -expand sum
    # tallennetaan summatut per viite
    $raportti += New-Object PSObject -Property @{
      Viite = $viite
      Summa = $summa
      Saajat = $($viiterivit | select -expand Saaja | select -unique) -join ","  # jos ueasmpi saaja, yhdistä pilkulla
    }
  }
}
End {
  if ($output) {
    return $raportti
  }
  else {
    write-host "Luotu raportti raportti.csv"
    $raportti | export-csv -path "raportti.csv" -delimiter ";" -Encoding UTF8 -NoTypeinformation
  }
}
