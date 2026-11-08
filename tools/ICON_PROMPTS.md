# İkon üretim paketi (Gemini) — World Empire tarzı, renkli

Hedef: World Empire 2027 / Age of Civilizations gibi **küçük, renkli, düz çizgi-film ikonlar** (tank, uçak, gemi, tüfek, bayrak...). Kodla çizilen beyaz çizgi ikonların yerine geçer.

## Tek görselde hepsi (51 nesne ikonu)
Gemini'ye şunu yapıştırın (tek görsel üretir):
```
Create ONE image: a clean 8 columns x 7 rows grid of 51 separate game icons on a plain solid flat magenta (#FF00FF) background. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. Each icon sits centered in its own equal square cell with generous padding; NO cell borders, NO labels, NO text, NO cast shadows on the background, NO gradients on the background, the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order (the last cells stay empty):
Row 1: 1) stack of coins, 2) single sword, 3) two crossed swords, 4) heater shield, 5) newspaper / bulletin, 6) group of three people (population), 7) globe with meridians, 8) flag on a pole
Row 2: 9) crown, 10) handshake, 11) skull, 12) five-point star, 13) trophy cup, 14) crosshair target, 15) factory with chimneys, 16) flame
Row 3: 17) house, 18) padlock, 19) rising trend arrow chart, 20) hourglass, 21) ship anchor, 22) open book, 23) folded map, 24) alarm siren light
Row 4: 25) castle / fortress, 26) fighter plane top view, 27) warship side view, 28) main battle tank side view, 29) wheat ear (food), 30) lightning bolt, 31) scroll / decree, 32) assault rifle side view
Row 5: 33) armoured personnel carrier (wheeled) side view, 34) self-propelled howitzer side view, 35) modern jet fighter side view, 36) attack helicopter side view, 37) military drone (UAV) top view, 38) submarine side view, 39) ballistic missile upright, 40) radar dish
Row 6: 41) shield with circuit / binary lock (cyber defence), 42) medical cross with heartbeat, 43) shield with a star (defence ministry), 44) police / interior ministry badge, 45) eye (intelligence), 46) oil drop / barrel, 47) two opposing arrows with cargo crate, 48) embassy building with flag
Row 7: 49) circle with diagonal bar over coin (sanction), 50) judge gavel, 51) briefcase (finance)
```
Sonra: `python3 tools/slice_icons.py sayfa.png 8 7 --set=objects` → ikonlar magenta arka plandan temizlenip kesilir, `assets/icons/<ad>_c.png` olarak kaydedilir. Oyun bu dosyaları bulunca kodla çizilen ikonun yerine kullanır (renkli ikonlar boyanmaz).

Gemini 51 ikonu birden karıştırırsa aynı istemi 2-3 parçaya bölün (ör. 4x4) ve `--start=N` ile kesin: `python3 tools/slice_icons.py s2.png 4 4 --set=objects --start=16`.

## Kodla kalan arayüz ikonları
menu, play, pause, fast, fast3, x, plus, minus, check, info, save, folder, search, chev_*, gear, volume, mute, power, refresh gibi düğme ikonları renk/duruma göre boyandığı için kodla çizilmeye devam eder (renkli yapmayın).

## Ana stil cümlesi (tek tek üretirseniz her istemin başına)
```
Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px, transparent or solid magenta background, single icon
```

## İkon listesi (tek tek üretmek isterseniz)
| Dosya adı | Konu |
|---|---|
| `coins_c.png` | stack of coins |
| `sword_c.png` | single sword |
| `swords_c.png` | two crossed swords |
| `shield_c.png` | heater shield |
| `news_c.png` | newspaper / bulletin |
| `users_c.png` | group of three people (population) |
| `globe_c.png` | globe with meridians |
| `flag_c.png` | flag on a pole |
| `crown_c.png` | crown |
| `handshake_c.png` | handshake |
| `skull_c.png` | skull |
| `star_c.png` | five-point star |
| `trophy_c.png` | trophy cup |
| `target_c.png` | crosshair target |
| `factory_c.png` | factory with chimneys |
| `flame_c.png` | flame |
| `home_c.png` | house |
| `lock_c.png` | padlock |
| `trend_c.png` | rising trend arrow chart |
| `hourglass_c.png` | hourglass |
| `anchor_c.png` | ship anchor |
| `book_c.png` | open book |
| `map_c.png` | folded map |
| `siren_c.png` | alarm siren light |
| `castle_c.png` | castle / fortress |
| `plane_c.png` | fighter plane top view |
| `ship_c.png` | warship side view |
| `tank_c.png` | main battle tank side view |
| `wheat_c.png` | wheat ear (food) |
| `bolt_c.png` | lightning bolt |
| `scroll_c.png` | scroll / decree |
| `rifle_c.png` | assault rifle side view |
| `afv_c.png` | armoured personnel carrier (wheeled) side view |
| `arty_c.png` | self-propelled howitzer side view |
| `jet_c.png` | modern jet fighter side view |
| `heli_c.png` | attack helicopter side view |
| `drone_c.png` | military drone (UAV) top view |
| `sub_c.png` | submarine side view |
| `missile_c.png` | ballistic missile upright |
| `radar_c.png` | radar dish |
| `cyber_c.png` | shield with circuit / binary lock (cyber defence) |
| `med_c.png` | medical cross with heartbeat |
| `shield_star_c.png` | shield with a star (defence ministry) |
| `badge_c.png` | police / interior ministry badge |
| `eye_c.png` | eye (intelligence) |
| `oil_c.png` | oil drop / barrel |
| `trade_c.png` | two opposing arrows with cargo crate |
| `embassy_c.png` | embassy building with flag |
| `sanction_c.png` | circle with diagonal bar over coin (sanction) |
| `gavel_c.png` | judge gavel |
| `briefcase_c.png` | briefcase (finance) |
