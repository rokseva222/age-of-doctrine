# İkon paketi 3 (Gemini) — binalar, birimler, lojistik, siyaset/durum

Paket 1 ve 2 ile aynı stil. Tek görselde 48 ikon, 8 sütun x 6 satır.

## Gemini istemi
```
Create ONE image: a clean 8 columns x 6 rows grid of 48 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a harbor with a crane and a cargo ship (port), 2) an airbase with runway and control tower, 3) an oil pumpjack on a hill (oil well), 4) a farm barn with a silo and wheat field, 5) a power plant with smoking chimneys and a lightning bolt, 6) a nuclear power plant with two cooling towers, 7) a university building with columns and a graduation cap, 8) a hospital building with a red cross
Row 2: 9) a government palace with a flag on the dome (capital), 10) a concrete bunker with a slit window, 11) military barracks building with a flag, 12) an arsenal weapon depot: crates of rifles and shells, 13) an oil refinery with tanks and a flare stack, 14) a dam with water flowing through it, 15) a railway track with a signal, 16) a stone fortress wall with towers
Row 3: 17) marine soldier in a blue-grey uniform with a rifle, 18) special forces operator in a balaclava with night-vision goggles, 19) multiple rocket launcher truck (MLRS), 20) anti-aircraft gun pointing to the sky, 21) stealth bomber flying wing in dark grey, 22) aircraft carrier with planes on the deck, 23) modern destroyer warship with missile launchers, 24) electronic warfare jammer: antenna with radio waves
Row 4: 25) big cargo ship with colorful containers, 26) steam and diesel freight train, 27) wooden supply crate with a stencilled star, 28) red fuel barrel with a drop symbol, 29) ammunition box with bullets, 30) satellite with solar panels in orbit, 31) radio tower with signal waves, 32) convoy of two military trucks
Row 5: 33) two shields joined together (alliance), 34) three flags on one pole (bloc), 35) crate with a red prohibited sign (embargo), 36) helping hands passing a food box (aid), 37) new recruit with a green plus sign (recruitment), 38) veteran soldier with gold chevron stars, 39) propaganda poster on a wall with a raised fist, 40) golden coin pouch with an arrow to a crown (tribute)
Row 6: 41) red warning triangle with exclamation mark, 42) castle surrounded by besieging arrows (siege), 43) flag with a chain and padlock (occupied), 44) map piece with a green plus arrow (annexation), 45) broken chain over a flag (independence), 46) crossed rifles with a white flag (ceasefire), 47) helmet with two upward green arrows (reinforcement), 48) soldier with a backward arrow (retreat)
```

## Kesme
`python3 tools/slice_icons.py sayfa3.png 8 6 --set=pack3 --tiles` → `assets/icons/<ad>_c.png`
Dosyalar kopyalanınca haber ver; bina/birim/lojistik ikonlarını harita rozetlerine, envanter ve diplomasi ekranlarına bağlarım.

## Liste
| Dosya | Konu |
|---|---|
| `port_c.png` | a harbor with a crane and a cargo ship (port) |
| `airbase_c.png` | an airbase with runway and control tower |
| `oil_well_c.png` | an oil pumpjack on a hill (oil well) |
| `farm_c.png` | a farm barn with a silo and wheat field |
| `power_plant_c.png` | a power plant with smoking chimneys and a lightning bolt |
| `nuclear_plant_c.png` | a nuclear power plant with two cooling towers |
| `university_c.png` | a university building with columns and a graduation cap |
| `hospital_c.png` | a hospital building with a red cross |
| `capital_c.png` | a government palace with a flag on the dome (capital) |
| `bunker_c.png` | a concrete bunker with a slit window |
| `barracks_c.png` | military barracks building with a flag |
| `arsenal_c.png` | an arsenal weapon depot: crates of rifles and shells |
| `refinery_c.png` | an oil refinery with tanks and a flare stack |
| `dam_c.png` | a dam with water flowing through it |
| `railway_c.png` | a railway track with a signal |
| `fortress_c.png` | a stone fortress wall with towers |
| `marines_c.png` | marine soldier in a blue-grey uniform with a rifle |
| `special_forces_c.png` | special forces operator in a balaclava with night-vision goggles |
| `mlrs_c.png` | multiple rocket launcher truck (MLRS) |
| `aa_gun_c.png` | anti-aircraft gun pointing to the sky |
| `stealth_bomber_c.png` | stealth bomber flying wing in dark grey |
| `carrier_c.png` | aircraft carrier with planes on the deck |
| `destroyer_c.png` | modern destroyer warship with missile launchers |
| `jammer_c.png` | electronic warfare jammer: antenna with radio waves |
| `cargo_ship_c.png` | big cargo ship with colorful containers |
| `train_c.png` | steam and diesel freight train |
| `crate_c.png` | wooden supply crate with a stencilled star |
| `fuel_c.png` | red fuel barrel with a drop symbol |
| `ammo_c.png` | ammunition box with bullets |
| `satellite_c.png` | satellite with solar panels in orbit |
| `radio_tower_c.png` | radio tower with signal waves |
| `convoy_c.png` | convoy of two military trucks |
| `alliance_shield_c.png` | two shields joined together (alliance) |
| `bloc_c.png` | three flags on one pole (bloc) |
| `embargo_c.png` | crate with a red prohibited sign (embargo) |
| `aid_c.png` | helping hands passing a food box (aid) |
| `recruit_c.png` | new recruit with a green plus sign (recruitment) |
| `veteran_c.png` | veteran soldier with gold chevron stars |
| `poster_c.png` | propaganda poster on a wall with a raised fist |
| `tribute_c.png` | golden coin pouch with an arrow to a crown (tribute) |
| `warning_c.png` | red warning triangle with exclamation mark |
| `siege_c.png` | castle surrounded by besieging arrows (siege) |
| `occupied_c.png` | flag with a chain and padlock (occupied) |
| `annex_c.png` | map piece with a green plus arrow (annexation) |
| `independence_c.png` | broken chain over a flag (independence) |
| `ceasefire_c.png` | crossed rifles with a white flag (ceasefire) |
| `reinforce_c.png` | helmet with two upward green arrows (reinforcement) |
| `retreat_c.png` | soldier with a backward arrow (retreat) |
