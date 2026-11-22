# Wikimedia Commons'tan bayrakları indirir. Kullanım: PowerShell'de bu klasörde:  .\indir_bayraklar.ps1
# Çıktı: .\bayraklar\era_<ad>.png  ve  _kaynak.txt (hangi dosya seçildi; yanlış olanları kontrol et)
$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$out = Join-Path $PSScriptRoot 'bayraklar'
New-Item -ItemType Directory -Force $out | Out-Null
$h = @{ 'User-Agent' = 'AgeOfDoctrineFlagFetch/1.0 (hobby game project)' }
$rows = Import-Csv (Join-Path $PSScriptRoot 'bayrak_listesi.csv') -Encoding UTF8
foreach ($r in $rows) {
  $dest = Join-Path $out ("era_" + $r.slug + ".png")
  if (Test-Path $dest) { continue }
  try {
    $q = [uri]::EscapeDataString($r.query)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srlimit=8&format=json&srsearch=$q"
    $res = Invoke-RestMethod $api -Headers $h
    $hit = $res.query.search | Where-Object { $_.title -match '\.svg$' } | Select-Object -First 1
    if (-not $hit) { Write-Host "YOK:  $($r.slug)  ($($r.query))"; continue }
    $name = $hit.title -replace '^File:', ''
    $url = "https://commons.wikimedia.org/wiki/Special:FilePath/" + [uri]::EscapeDataString($name) + "?width=960"
    Invoke-WebRequest $url -OutFile $dest -Headers $h
    Add-Content (Join-Path $out '_kaynak.txt') ("era_" + $r.slug + ".png <- " + $name)
    Write-Host "OK:   $($r.slug) <- $name"
  } catch { Write-Host "HATA: $($r.slug)  $_" }
  Start-Sleep -Milliseconds 800
}
Write-Host "Bitti. 'bayraklar' klasörünü zipleyip bana at."
