# İkon paketi 9 (Gemini) — uçak gemisi saldırısı ve diplomasi ekranı

Paket 1-8 ile aynı stil. **Tek görselde 8 ikon**, 8 sütun x 1 satır. Uçak gemisi saldırı animasyonu kodla çizilen piksel-art (görsel gerekmez); bu paket yalnızca **ikon**.

## Gemini istemi
```
Create ONE image: a clean 8 columns x 1 row strip of 8 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text, NO letters or numbers, NO real flags, NO real organisation logos or emblems; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) an aircraft carrier seen from the side with a jet launching off the deck in a burst of flame, a bomb explosion on a distant coast, 2) an aircraft carrier with a green ready light and a jet on the deck, 3) an aircraft carrier in a dry dock with a crane and an hourglass, 4) a fighter jet climbing steeply on a catapult flame trail, 5) a round negotiation table with two chairs, a globe and two plain pennants (blue and gold, no real flags), 6) a gold-ribboned gift chest with coins spilling out, handed across a border line, 7) two shaking hands with a small rising green arrow above them, 8) a red barrier gate lifting open with cargo ships passing through
```

## Kesme
`python3 tools/slice_icons.py sayfa9.png 8 1 --set=pack9 --tiles` → `assets/icons/<ad>_c.png`

## Liste
| Dosya | Konu |
|---|---|
| `carrier_strike_c.png` | an aircraft carrier seen from the side with a jet launching off the deck in a burst of flame, a bomb explosion on a distant coast |
| `carrier_ready_c.png` | an aircraft carrier with a green ready light and a jet on the deck |
| `carrier_refit_c.png` | an aircraft carrier in a dry dock with a crane and an hourglass |
| `jet_launch_c.png` | a fighter jet climbing steeply on a catapult flame trail |
| `diplomacy_c.png` | a round negotiation table with two chairs, a globe and two plain pennants (blue and gold, no real flags) |
| `gift_c.png` | a gold-ribboned gift chest with coins spilling out, handed across a border line |
| `improve_rel_c.png` | two shaking hands with a small rising green arrow above them |
| `embargo_lift_c.png` | a red barrier gate lifting open with cargo ships passing through |
