[CmdletBinding()]
param (
  [string]$tapahtumat = ""
)
Begin {
  # tarkastetaan
  if ($tapahtumat.length -lt 1) {
    write-output "Määritä polku Osuuspankin tilitapahtumat csv -tiedostoon komennon ensimmäisenä argumenttina`nEsim: .\luo-raportti.ps1 tapahtumat.csv"
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
    # hae csvdatasta kaikki jossa on viite 'viite n' ja summaa sarakkeen arvot
    $viiterivit = $csvdata | where { $_.Viite -eq $viite }
    $summa = $viiterivit | select -expand Eurot | Measure-Object -Sum |select -expand Sum
    # tallennetaan summatut per viite
    $raportti += New-Object PSObject -Property @{
      Viite = $viite
      Summa = $summa
      Saajat = $($viiterivit | select -expand Saaja | select -unique) -join ","
    }
  }
}
End {
  write-host "Luotu raportti raportti.csv"
  $raportti | export-csv -path "raportti.csv" -delimiter ";" -Encoding UTF8 -NoTypeinformation
  return $raportti
}
