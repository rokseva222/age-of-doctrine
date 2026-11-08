# İkon paketi 2 (Gemini) — olaylar, ekonomi, gizli harekât, dönemler

Paket 1 ile aynı stil. Tek görselde 48 ikon, 8 sütun x 6 satır.

## Gemini istemi
```
Create ONE image: a clean 8 columns x 6 rows grid of 48 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) megaphone / loudspeaker (propaganda), 2) round black bomb with lit fuse (sabotage), 3) secret agent: fedora hat, sunglasses, raised collar, 4) orange fiery explosion burst, 5) paratrooper with open parachute, 6) amphibious landing craft with ramp, 7) nuclear mushroom cloud, 8) white flag on a pole (surrender / ceasefire)
Row 2: 9) classical bank building with columns and dollar sign, 10) bag of money with dollar sign, 11) red downward arrow chained to a coin (debt), 12) computer microchip (semiconductor), 13) stack of steel ingots / iron bars, 14) gas flame over a pipeline valve (natural gas), 15) yellow radiation barrel (uranium), 16) pickaxe and ore rocks (mining)
Row 3: 17) green virus particle (epidemic), 18) cracked ground with a collapsing building (earthquake), 19) waves flooding a house (flood), 20) cracked dry earth under a hot sun (drought), 21) raised clenched fist (protest), 22) tank in front of a broken crown (coup), 23) group of people with bundles walking (refugees), 24) storm cloud with lightning and rain
Row 4: 25) white dove with olive branch (peace), 26) treaty document with pen and red seal, 27) round conference table with flags (summit), 28) ballot box with a vote paper (election), 29) passport booklet with stamp, 30) military medal with ribbon, 31) golden laurel wreath (victory), 32) modern combat helmet
Row 5: 33) WW1 steel helmet (Brodie/Stahlhelm style, neutral), 34) WW2 steel helmet, neutral, 35) WW1 biplane, 36) WW2 four-engine bomber, 37) big battleship with large gun turrets, 38) squad of three soldiers marching, 39) horse head (cavalry), 40) trench with sandbags and barbed wire
Row 6: 41) balance scale (stability), 42) gear with factory silhouette, 43) military supply truck (logistics), 44) science flask with glowing liquid (research / technology), 45) hooded hacker with laptop (cyber attack), 46) angry crowd with torches (unrest), 47) modern city skyline (development), 48) wall calendar page (date / turn)
```

## Kesme
`python3 tools/slice_icons.py sayfa2.png 8 6 --set=pack2 --tiles` → `assets/icons/<ad>_c.png`
(Karesiz üretirse `--tiles` olmadan.) Dosyalar kopyalanınca bana haber ver; olay kartları, ekonomi/ticaret listeleri, gizli harekât düğmeleri, dönem menüsü ve harita rozetlerine bağlarım.

## Liste
| Dosya | Konu | Nerede kullanılacak |
|---|---|---|
| `megaphone_c.png` | megaphone / loudspeaker (propaganda) | Propaganda |
| `bomb_c.png` | round black bomb with lit fuse (sabotage) | Sabotaj |
| `spy_c.png` | secret agent: fedora hat, sunglasses, raised collar | Casusluk |
| `explosion_c.png` | orange fiery explosion burst | Topçu yağmuru |
| `paratrooper_c.png` | paratrooper with open parachute | Hava indirme harekâtı |
| `landing_c.png` | amphibious landing craft with ramp | Deniz çıkarması |
| `nuke_c.png` | nuclear mushroom cloud | Nükleer tehdit/olay |
| `white_flag_c.png` | white flag on a pole (surrender / ceasefire) | Barış/ateşkes |
| `bank_c.png` | classical bank building with columns and dollar sign | Maliye, bütçe |
| `money_bag_c.png` | bag of money with dollar sign | Gelir/ödül |
| `debt_c.png` | red downward arrow chained to a coin (debt) | Borç/açık |
| `chip_c.png` | computer microchip (semiconductor) | Teknoloji, ticaret |
| `steel_c.png` | stack of steel ingots / iron bars | Sanayi malı |
| `gas_c.png` | gas flame over a pipeline valve (natural gas) | Enerji |
| `uranium_c.png` | yellow radiation barrel (uranium) | Nükleer |
| `mine_c.png` | pickaxe and ore rocks (mining) | Kaynak |
| `virus_c.png` | green virus particle (epidemic) | Salgın kartı |
| `earthquake_c.png` | cracked ground with a collapsing building (earthquake) | Deprem olayı |
| `flood_c.png` | waves flooding a house (flood) | Sel olayı |
| `drought_c.png` | cracked dry earth under a hot sun (drought) | Kuraklık olayı |
| `protest_c.png` | raised clenched fist (protest) | Protesto kartı |
| `coup_c.png` | tank in front of a broken crown (coup) | Darbe riski |
| `refugees_c.png` | group of people with bundles walking (refugees) | Mülteci olayı |
| `storm_c.png` | storm cloud with lightning and rain | Fırtına olayı |
| `dove_c.png` | white dove with olive branch (peace) | Barış teklifi |
| `treaty_c.png` | treaty document with pen and red seal | Anlaşma/ittifak |
| `summit_c.png` | round conference table with flags (summit) | Zirve |
| `ballot_c.png` | ballot box with a vote paper (election) | Seçim/lider değişimi |
| `passport_c.png` | passport booklet with stamp | Vize/elçilik |
| `medal_c.png` | military medal with ribbon | Zafer/rütbe |
| `laurel_c.png` | golden laurel wreath (victory) | Zafer ekranı |
| `helmet_c.png` | modern combat helmet | Modern dönem |
| `helmet_ww1_c.png` | WW1 steel helmet (Brodie/Stahlhelm style, neutral) | I. Dünya Savaşı dönemi |
| `helmet_ww2_c.png` | WW2 steel helmet, neutral | II. Dünya Savaşı dönemi |
| `biplane_c.png` | WW1 biplane | 1914 hava gücü |
| `bomber_c.png` | WW2 four-engine bomber | 1939 hava gücü |
| `battleship_c.png` | big battleship with large gun turrets | Donanma |
| `infantry_c.png` | squad of three soldiers marching | Ordu rozeti |
| `cavalry_c.png` | horse head (cavalry) | 1914 ordu |
| `trench_c.png` | trench with sandbags and barbed wire | Siper/savunma |
| `stability_c.png` | balance scale (stability) | İstikrar göstergesi |
| `industry_c.png` | gear with factory silhouette | Sanayi göstergesi |
| `truck_c.png` | military supply truck (logistics) | Lojistik |
| `flask_c.png` | science flask with glowing liquid (research / technology) | Teknoloji |
| `hacker_c.png` | hooded hacker with laptop (cyber attack) | Siber saldırı |
| `unrest_c.png` | angry crowd with torches (unrest) | Huzursuzluk |
| `city_c.png` | modern city skyline (development) | Kalkınma |
| `calendar_c.png` | wall calendar page (date / turn) | Tarih/tur |
