# İkon paketi 13 (Gemini) — yeni özellikler (harekâtlar, odak ağacı, din, para, sandbox)

## Gemini istemi
```
Create ONE image: a clean 8 columns x 4 rows grid of 32 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text, NO letters or numbers, NO real flags, NO real organisation logos or emblems; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a soldier silhouette creeping under a crescent moon with glowing night-vision goggles, 2) three tanks in a wedge formation breaking through a line with a big forward arrow, 3) a stone castle surrounded by a ring of small tents with a cannon firing at the wall, 4) two big curved pincer arrows closing around a small town on a map, 5) an inflatable decoy tank with a radio antenna and a faded ghost outline behind it, 6) a small crown linked by a chain to a larger golden crown above it, 7) a white flag on a pole waving above a dropped rifle, 8) a hooded spy figure holding a magnifying glass and a sealed envelope
Row 2: 9) a tree-shaped skill-tree diagram with glowing round nodes and a target ring at the top, 10) a stack of gold coins next to a small factory with a smoking chimney, 11) crossed swords over a shield with a star, 12) a handshake over a small globe with an olive branch, 13) a columned parliament building with a small heart above it, 14) a small church with a bell tower and a cross, 15) a mosque with a big dome, a minaret and a crescent moon, 16) a temple with a tiered roof and a pink lotus flower in front
Row 3: 17) a simple shrine with two candles and a sun symbol, 18) two open hands holding a glowing book above a small dove, 19) a throne and a ballot box separated by a lightning bolt, 20) a banknote and a coin with two circular exchange arrows, 21) a wooden sandbox with a toy tank, a small shovel and a bucket, 22) a wall calendar with a golden hourglass in front of it, 23) a paint brush painting a colorful province-shaped map piece, 24) a puzzle piece of land passing from one hand to another hand
Row 4: 25) a treasure chest of gold with an arrow moving into an open hand, 26) a small bird flying out of an opened cage carrying a tiny banner, 27) a cargo ship with a red prohibition circle in front of it, 28) a rolled treaty scroll with two wax seals and a quill pen, 29) a white dove with an olive branch above a snapped sword, 30) a network of connected eyes joined by glowing lines, 31) a folder stamped with a red seal and a magnifying glass over it, 32) a yellow radiation warning triangle on a small missile silo
```

## Kesme
`python3 tools/slice_icons.py sayfa13.png 8 4 --set=pack13 --tiles`

Kodda bu adlarla otomatik kullanılır: dosya yoksa eski kod ikonlarına düşer. (op_*: harekât listesi, focus_*: odak sekmesi, vassal/regime/faith: barış şartları.)

## Liste
| Dosya | Konu |
|---|---|
| `op_night_c.png` | a soldier silhouette creeping under a crescent moon with glowing night-vision goggles |
| `op_armor_c.png` | three tanks in a wedge formation breaking through a line with a big forward arrow |
| `op_siege_c.png` | a stone castle surrounded by a ring of small tents with a cannon firing at the wall |
| `op_encircle_c.png` | two big curved pincer arrows closing around a small town on a map |
| `op_deception_c.png` | an inflatable decoy tank with a radio antenna and a faded ghost outline behind it |
| `vassal_c.png` | a small crown linked by a chain to a larger golden crown above it |
| `surrender_c.png` | a white flag on a pole waving above a dropped rifle |
| `spy_send_c.png` | a hooded spy figure holding a magnifying glass and a sealed envelope |
| `focus_c.png` | a tree-shaped skill-tree diagram with glowing round nodes and a target ring at the top |
| `focus_eco_c.png` | a stack of gold coins next to a small factory with a smoking chimney |
| `focus_mil_c.png` | crossed swords over a shield with a star |
| `focus_dip_c.png` | a handshake over a small globe with an olive branch |
| `focus_pol_c.png` | a columned parliament building with a small heart above it |
| `faith_christian_c.png` | a small church with a bell tower and a cross |
| `faith_islam_c.png` | a mosque with a big dome, a minaret and a crescent moon |
| `faith_dharmic_c.png` | a temple with a tiered roof and a pink lotus flower in front |
| `faith_other_c.png` | a simple shrine with two candles and a sun symbol |
| `faith_c.png` | two open hands holding a glowing book above a small dove |
| `regime_c.png` | a throne and a ballot box separated by a lightning bolt |
| `currency_c.png` | a banknote and a coin with two circular exchange arrows |
| `sandbox_c.png` | a wooden sandbox with a toy tank, a small shovel and a bucket |
| `year_c.png` | a wall calendar with a golden hourglass in front of it |
| `map_paint_c.png` | a paint brush painting a colorful province-shaped map piece |
| `transfer_c.png` | a puzzle piece of land passing from one hand to another hand |
| `tribute_c.png` | a treasure chest of gold with an arrow moving into an open hand |
| `release_state_c.png` | a small bird flying out of an opened cage carrying a tiny banner |
| `embargo_ship_c.png` | a cargo ship with a red prohibition circle in front of it |
| `treaty_scroll_c.png` | a rolled treaty scroll with two wax seals and a quill pen |
| `dove_peace_c.png` | a white dove with an olive branch above a snapped sword |
| `spy_net_c.png` | a network of connected eyes joined by glowing lines |
| `intel_report_c.png` | a folder stamped with a red seal and a magnifying glass over it |
| `radiation_warn_c.png` | a yellow radiation warning triangle on a small missile silo |
