# İkon paketi 8 (Gemini) — yeni kipler: Osmanlı/Timur çağı, seferberlik, ilişkiler, geçiş hakkı, BM oylaması, sınır olayları

Paket 1-7 ile aynı stil. **Tek görselde 32 ikon**, 8 sütun x 4 satır. Animasyonlu sahneler kodla çizilen piksel-art (görsel gerekmez); bu paket sadece **ikon** asset'idir.

## Gemini istemi
```
Create ONE image: a clean 8 columns x 4 rows grid of 32 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text, NO letters or numbers, NO real flags, NO real organisation logos or emblems; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a janissary in a tall white felt cap with a back flap, holding a long matchlock musket, 2) a steppe horse archer on a galloping horse with a plain banner, aiming a bow, 3) a red telephone beside a missile and a ticking clock, tense cold-war mood, 4) a feather quill writing on a scroll beside a small map and a lit candle, 5) a big war drum with a call-up poster, soldiers marching out of a town gate, 6) a war drum with flames and a long marching column of soldiers behind it, 7) two clenched fists clashing with red sparks, 8) two hands almost touching with a blue frost snowflake between them
Row 2: 9) two hands shaking with a small green leaf above, 10) two firmly clasped hands under a golden ring and glow, 11) an open border gate with a column of small soldiers passing through and a green light, 12) a closed striped barrier gate with a sentry and a red stop light, 13) one marching column splitting into two arrows going different ways, 14) a raised hand holding a green card with a white check mark, 15) a raised hand holding a red card with a white cross, 16) an open palm holding a blank grey card
Row 3: 17) a semicircular assembly hall with rows of seats and a podium under a blue globe emblem (generic, not the real UN logo), 18) a bell with a small blue globe and a red notification dot, 19) two small soldier silhouettes facing each other across a striped border pole with tension sparks, 20) a hand giving a torn piece of a map to another hand, 21) a table with two chairs over a thin border line and a white dove, 22) a bird-beaked plague doctor mask with a hat, greenish mist around it, 23) an empty bowl beside dry wheat stalks on cracked earth, 24) a huge medieval bombard cannon on a wooden carriage with smoke
Row 4: 25) a long galley ship with oars and a triangular lateen sail, 26) a matchlock musket with a glowing smoking fuse, 27) a recurve bow with an arrow and a leather quiver, 28) a round felt tent with smoke from the roof and a banner pole, 29) a domed palace with two slender towers at sunset (generic, no religious symbols), 30) three camels loaded with goods walking in a line, 31) a tall pole topped with a golden ornament and hanging horse-tail tassels, 32) a decree scroll with a red wax seal and a feather
```

## Kesme
`python3 tools/slice_icons.py sayfa8.png 8 4 --set=pack8 --tiles` → `assets/icons/<ad>_c.png`
Dosya yoksa oyun kodla çizilen/eski ikona döner; bu yüzden istediğin kadarını sonradan ekleyebilirsin.

## Liste
| Dosya | Konu |
|---|---|
| `era_ott1520_c.png` | a janissary in a tall white felt cap with a back flap, holding a long matchlock musket |
| `era_tim1380_c.png` | a steppe horse archer on a galloping horse with a plain banner, aiming a bow |
| `era_cw62_c.png` | a red telephone beside a missile and a ticking clock, tense cold-war mood |
| `mode_story_c.png` | a feather quill writing on a scroll beside a small map and a lit candle |
| `mobilize_c.png` | a big war drum with a call-up poster, soldiers marching out of a town gate |
| `mob_active_c.png` | a war drum with flames and a long marching column of soldiers behind it |
| `rel_hostile_c.png` | two clenched fists clashing with red sparks |
| `rel_cold_c.png` | two hands almost touching with a blue frost snowflake between them |
| `rel_warm_c.png` | two hands shaking with a small green leaf above |
| `rel_close_c.png` | two firmly clasped hands under a golden ring and glow |
| `passage_grant_c.png` | an open border gate with a column of small soldiers passing through and a green light |
| `passage_deny_c.png` | a closed striped barrier gate with a sentry and a red stop light |
| `army_split_c.png` | one marching column splitting into two arrows going different ways |
| `vote_yes_c.png` | a raised hand holding a green card with a white check mark |
| `vote_no_c.png` | a raised hand holding a red card with a white cross |
| `vote_abstain_c.png` | an open palm holding a blank grey card |
| `un_hall_c.png` | a semicircular assembly hall with rows of seats and a podium under a blue globe emblem (generic, not the real UN logo) |
| `un_notice_c.png` | a bell with a small blue globe and a red notification dot |
| `border_clash_c.png` | two small soldier silhouettes facing each other across a striped border pole with tension sparks |
| `border_cede_c.png` | a hand giving a torn piece of a map to another hand |
| `border_talk_c.png` | a table with two chairs over a thin border line and a white dove |
| `plague_c.png` | a bird-beaked plague doctor mask with a hat, greenish mist around it |
| `famine_c.png` | an empty bowl beside dry wheat stalks on cracked earth |
| `bombard_c.png` | a huge medieval bombard cannon on a wooden carriage with smoke |
| `galley_c.png` | a long galley ship with oars and a triangular lateen sail |
| `matchlock_c.png` | a matchlock musket with a glowing smoking fuse |
| `horse_archer_c.png` | a recurve bow with an arrow and a leather quiver |
| `yurt_c.png` | a round felt tent with smoke from the roof and a banner pole |
| `palace_domes_c.png` | a domed palace with two slender towers at sunset (generic, no religious symbols) |
| `caravan_c.png` | three camels loaded with goods walking in a line |
| `war_standard_c.png` | a tall pole topped with a golden ornament and hanging horse-tail tassels |
| `decree_c.png` | a decree scroll with a red wax seal and a feather |
