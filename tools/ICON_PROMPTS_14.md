# İkon paketi 14 (Gemini) — modern silah modelleri (modele özel simgeler)

## Gemini istemi
```
Create ONE image: a clean 8 columns x 4 rows grid of 32 separate game icons on a plain solid flat magenta (#FF00FF) background. Each icon sits inside its own dark navy rounded square tile, equal sizes, with a small gap between tiles. Style: Small colorful flat mobile-strategy-game icon in the style of World Empire 2027 / Age of Civilizations II: simple bold cartoon shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold), clean dark outline, soft flat shading with one simple highlight, no realistic detail, centered, readable at 48 px. NO labels, NO text, NO letters or numbers, NO real flags, NO real organisation logos or emblems; the magenta must not appear inside the icons. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a Western heavy main battle tank with a flat angular turret, thermal sight box and long smooth gun, desert tan color, 2) an older 1960s Western battle tank with a rounded cast turret and a long gun, olive green, 3) a German-style main battle tank with a wedge-shaped turret and a long gun, olive and black camouflage, 4) a Russian-style main battle tank with a low round turret, a long gun, and a row of road wheels, dark green, 5) a futuristic unmanned-turret main battle tank with a flat low turret and sloped armor, dark grey, 6) a modern Chinese-style main battle tank with a wide angular turret and reactive armor, green digital camo, 7) an Israeli-style heavy tank with a rear-engine hull, a boxy turret and slat armor, sand color, 8) a sleek modern Korean-style main battle tank with a low profile turret and long gun, dark olive
Row 2: 9) a French-style modern main battle tank with a sloped turret and a long gun, sand and green camouflage, 10) a stealth fifth-generation fighter jet with a single engine, faceted body and twin tails, flying, grey, 11) a twin-engine heavy air superiority fighter with twin vertical tails, flying, light grey, 12) a single-engine lightweight multirole fighter with a bubble canopy and a belly intake, flying, light grey, 13) a twin-engine stealth fighter with swept wings and twin tails, flying, grey-blue, 14) a large twin-engine heavy fighter with a long stinger tail and twin tails, flying, light blue-grey, 15) a delta-wing canard fighter jet with twin tails and a single bubble canopy, flying, grey, 16) an attack helicopter with a chin cannon, stub wings with missiles and a tandem cockpit, olive
Row 3: 17) a medium combat drone with a V-tail, a pusher propeller and two small missiles under the wings, white, 18) a small delta-wing kamikaze drone with a warhead nose and a rear propeller, launched from a rack, 19) a sleek unmanned combat jet drone with swept wings and a single tail, flying, grey, 20) a rugged straight-wing ground attack jet with wing pylons loaded with rockets, flying, green camouflage, 21) a cold war delta-wing fighter jet with a nose intake cone, flying, silver, 22) a wheeled truck carrying a box launcher firing a long-range rocket with a smoke trail, olive, 23) a truck with a block of 40 rocket tubes angled to the sky firing a salvo, green, 24) a tracked self-propelled howitzer with a big turret and a long barrel at high angle, green
Row 4: 25) a wheeled self-propelled howitzer on a big 8x8 truck with a long barrel, sand color, 26) a heavy tracked vehicle with a huge box launcher of thermobaric rockets and a fireball, dark green, 27) a tracked infantry fighting vehicle with a small turret and a low sloped hull, green, 28) a tracked infantry fighting vehicle with a turret with a cannon and missile pod, sand color, 29) a modern wheeled 8x8 armored vehicle with a remote weapon station, olive, 30) an old armored personnel carrier with a boxy hull and a machine gun on the roof, olive, 31) a black nuclear submarine with a sail and a rounded bow, surfacing with water splashing, 32) a small conventional submarine with a thin sail and a teardrop hull, dark grey-blue
```

## Kesme
`python3 tools/slice_icons.py sayfa14.png 8 4 --set=pack14 --tiles`

Her simge birden çok silaha karşılık gelir (örn. m_t72 = T-55/T-72/T-90...). Eşleşme scripts/arsenal.gd içindeki MODERN_ICON tablosundadır; dosya yoksa sınıf simgesine düşer.

## Liste
| Dosya | Konu |
|---|---|
| `m_abrams_c.png` | a Western heavy main battle tank with a flat angular turret, thermal sight box and long smooth gun, desert tan color |
| `m_patton_c.png` | an older 1960s Western battle tank with a rounded cast turret and a long gun, olive green |
| `m_leopard_c.png` | a German-style main battle tank with a wedge-shaped turret and a long gun, olive and black camouflage |
| `m_t72_c.png` | a Russian-style main battle tank with a low round turret, a long gun, and a row of road wheels, dark green |
| `m_t14_c.png` | a futuristic unmanned-turret main battle tank with a flat low turret and sloped armor, dark grey |
| `m_type99_c.png` | a modern Chinese-style main battle tank with a wide angular turret and reactive armor, green digital camo |
| `m_merkava_c.png` | an Israeli-style heavy tank with a rear-engine hull, a boxy turret and slat armor, sand color |
| `m_k2_c.png` | a sleek modern Korean-style main battle tank with a low profile turret and long gun, dark olive |
| `m_leclerc_c.png` | a French-style modern main battle tank with a sloped turret and a long gun, sand and green camouflage |
| `m_f35_c.png` | a stealth fifth-generation fighter jet with a single engine, faceted body and twin tails, flying, grey |
| `m_f15_c.png` | a twin-engine heavy air superiority fighter with twin vertical tails, flying, light grey |
| `m_f16_c.png` | a single-engine lightweight multirole fighter with a bubble canopy and a belly intake, flying, light grey |
| `m_su57_c.png` | a twin-engine stealth fighter with swept wings and twin tails, flying, grey-blue |
| `m_su27_c.png` | a large twin-engine heavy fighter with a long stinger tail and twin tails, flying, light blue-grey |
| `m_rafale_c.png` | a delta-wing canard fighter jet with twin tails and a single bubble canopy, flying, grey |
| `m_apache_c.png` | an attack helicopter with a chin cannon, stub wings with missiles and a tandem cockpit, olive |
| `m_tb2_c.png` | a medium combat drone with a V-tail, a pusher propeller and two small missiles under the wings, white |
| `m_kamikaze_c.png` | a small delta-wing kamikaze drone with a warhead nose and a rear propeller, launched from a rack |
| `m_kizilelma_c.png` | a sleek unmanned combat jet drone with swept wings and a single tail, flying, grey |
| `m_su25_c.png` | a rugged straight-wing ground attack jet with wing pylons loaded with rockets, flying, green camouflage |
| `m_mig21_c.png` | a cold war delta-wing fighter jet with a nose intake cone, flying, silver |
| `m_himars_c.png` | a wheeled truck carrying a box launcher firing a long-range rocket with a smoke trail, olive |
| `m_grad_c.png` | a truck with a block of 40 rocket tubes angled to the sky firing a salvo, green |
| `m_spg_c.png` | a tracked self-propelled howitzer with a big turret and a long barrel at high angle, green |
| `m_spg_wheeled_c.png` | a wheeled self-propelled howitzer on a big 8x8 truck with a long barrel, sand color |
| `m_tos_c.png` | a heavy tracked vehicle with a huge box launcher of thermobaric rockets and a fireball, dark green |
| `m_bmp_c.png` | a tracked infantry fighting vehicle with a small turret and a low sloped hull, green |
| `m_bradley_c.png` | a tracked infantry fighting vehicle with a turret with a cannon and missile pod, sand color |
| `m_wheeled_c.png` | a modern wheeled 8x8 armored vehicle with a remote weapon station, olive |
| `m_apc_old_c.png` | an old armored personnel carrier with a boxy hull and a machine gun on the roof, olive |
| `m_sub_nuke_c.png` | a black nuclear submarine with a sail and a rounded bow, surfacing with water splashing |
| `m_sub_diesel_c.png` | a small conventional submarine with a thin sail and a teardrop hull, dark grey-blue |
