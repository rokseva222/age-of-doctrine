# İkon paketi 5 (Gemini) — BM, barış şartları, komutanlar, olay/başarım ikonları

Paket 1-4 ile aynı stil. **Tek görselde 32 ikon**, 8 sütun x 4 satır.

## Gemini istemi
```
Create ONE image: a clean 8 columns x 4 rows grid of 32 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text, NO letters or numbers, NO real flags, NO real organisation logos or emblems; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a soldier in a light-blue helmet and vest holding an olive branch (peacekeeper, generic, no emblem), 2) a grand assembly hall with columns and a round dome, small flags in front (world assembly, generic), 3) a construction crane lifting bricks over half-built houses (reconstruction), 4) a green seedling growing out of a stack of gold coins next to a small factory (development), 5) a shield with a golden seal stamp and two joined hands in front (guarantee), 6) a magnifying glass over a stack of documents with a checkmark (investigation), 7) a rifle snapped in half with a green downward arrow (disarmament), 8) an open treasure chest full of gold coins with an arrow pointing to a hand (reparations)
Row 2: 9) two plain flags on either side of a dotted line with a red no-entry sign in the middle (buffer zone), 10) a flag pin planted on a military token with a small padlock (hold position), 11) a general in a peaked cap with gold shoulder stars and a medal ribbon (general), 12) a jet fighter dropping a bomb above a red target ring (air strike), 13) a folded map half covered by grey fog clouds with a question mark (fog of war), 14) a glowing yellow light bulb above a small signpost (hint), 15) a newspaper page with a big old date, a sepia photo and a bold headline bar (chronicle), 16) a stone bust of a statesman on a pedestal with a laurel wreath (leader)
Row 3: 17) four small round flags connected by lines in a network (relations), 18) a red sealed envelope with a crossed sword and a wax seal (declaration of war), 19) a line of warships forming a chain across the sea with a red stop sign (naval blockade), 20) a railway track with a red broken gap and sparks (cut supply line), 21) a glowing yellow lightning bolt over an oil drop (energy), 22) a cogwheel with an atom symbol in the middle (technology), 23) a manila folder stamped with a red CONFIDENTIAL stripe (no readable text, only a stripe) and a keyhole (intel report), 24) a mine cart full of ore and coal on rails (resources)
Row 4: 25) a bronze medal on a blue ribbon with a number-free star (bronze medal), 26) a silver medal on a blue ribbon with a star (silver medal), 27) a gold medal on a red ribbon with a star (gold medal), 28) five gold stars in an arc on a dark blue circle (five stars), 29) a broken chain around a crate with a green check (sanctions lifted), 30) a yellow and black radiation hazard trefoil sign (radiation), 31) an old railway carriage with a white flag on its roof (armistice carriage), 32) a grey battleship deck with a table, a document and a pen (surrender signing)
```

## Kesme
`python3 tools/slice_icons.py sayfa5.png 8 4 --set=pack5 --tiles` → `assets/icons/<ad>_c.png`
Dosyalar kopyalanınca oyun bunları BM önergelerinde, barış şartlarında ve başarımlarda otomatik kullanır (dosya yoksa eski ikonlar görünür).

## Liste
| Dosya | Konu |
|---|---|
| `un_peacekeeper_c.png` | a soldier in a light-blue helmet and vest holding an olive branch (peacekeeper, generic, no emblem) |
| `assembly_hall_c.png` | a grand assembly hall with columns and a round dome, small flags in front (world assembly, generic) |
| `rebuild_c.png` | a construction crane lifting bricks over half-built houses (reconstruction) |
| `develop_c.png` | a green seedling growing out of a stack of gold coins next to a small factory (development) |
| `guarantee_c.png` | a shield with a golden seal stamp and two joined hands in front (guarantee) |
| `probe_c.png` | a magnifying glass over a stack of documents with a checkmark (investigation) |
| `disarm_c.png` | a rifle snapped in half with a green downward arrow (disarmament) |
| `reparations_c.png` | an open treasure chest full of gold coins with an arrow pointing to a hand (reparations) |
| `buffer_zone_c.png` | two plain flags on either side of a dotted line with a red no-entry sign in the middle (buffer zone) |
| `hold_position_c.png` | a flag pin planted on a military token with a small padlock (hold position) |
| `general_c.png` | a general in a peaked cap with gold shoulder stars and a medal ribbon (general) |
| `airstrike_c.png` | a jet fighter dropping a bomb above a red target ring (air strike) |
| `fog_of_war_c.png` | a folded map half covered by grey fog clouds with a question mark (fog of war) |
| `hint_c.png` | a glowing yellow light bulb above a small signpost (hint) |
| `chronicle_c.png` | a newspaper page with a big old date, a sepia photo and a bold headline bar (chronicle) |
| `leader_bust_c.png` | a stone bust of a statesman on a pedestal with a laurel wreath (leader) |
| `relations_c.png` | four small round flags connected by lines in a network (relations) |
| `war_declared_c.png` | a red sealed envelope with a crossed sword and a wax seal (declaration of war) |
| `blockade_c.png` | a line of warships forming a chain across the sea with a red stop sign (naval blockade) |
| `supply_cut_c.png` | a railway track with a red broken gap and sparks (cut supply line) |
| `energy_c.png` | a glowing yellow lightning bolt over an oil drop (energy) |
| `tech_c.png` | a cogwheel with an atom symbol in the middle (technology) |
| `intel_report_c.png` | a manila folder stamped with a red CONFIDENTIAL stripe (no readable text, only a stripe) and a keyhole (intel report) |
| `mine_cart_c.png` | a mine cart full of ore and coal on rails (resources) |
| `medal_bronze_c.png` | a bronze medal on a blue ribbon with a number-free star (bronze medal) |
| `medal_silver_c.png` | a silver medal on a blue ribbon with a star (silver medal) |
| `medal_gold_c.png` | a gold medal on a red ribbon with a star (gold medal) |
| `five_stars_c.png` | five gold stars in an arc on a dark blue circle (five stars) |
| `sanction_lift_c.png` | a broken chain around a crate with a green check (sanctions lifted) |
| `radiation_c.png` | a yellow and black radiation hazard trefoil sign (radiation) |
| `armistice_car_c.png` | an old railway carriage with a white flag on its roof (armistice carriage) |
| `surrender_deck_c.png` | a grey battleship deck with a table, a document and a pen (surrender signing) |
