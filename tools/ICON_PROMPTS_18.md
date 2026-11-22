# İkon paketi 18-19 + bayrak (Gemini)

## Paket 18 — çağ kartı resimleri (20 adet, era_ott1299 ile aynı stil)
Kesme: `python3 tools/slice_icons.py sayfa.png --blobs --set=pack18` → assets/icons/era_<çağ>_c.png (menüde çağ seçiminde otomatik görünür)

```
Create ONE image: a clean 5 columns x 4 rows grid of 20 separate round illustrated badges on a plain solid flat magenta (#FF00FF) background, equal size, with a clear magenta gap between badges (badges must not touch). Each badge is a circular cartoon scene illustration, like a sticker for a mobile strategy game: hand-drawn comic style, bold dark outlines, warm saturated but slightly muted colors, soft flat shading, a small foreground figure or vehicle with a simple background landscape, the scene cropped into a circle with a thin light outline. NO text, NO letters, NO numbers, NO real national flags (use plain colored banners), NO logos; the magenta must not appear inside the badges. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) 1994 First Chechen War: a Russian soldier with an AK beside a BTR armored carrier in a snowy ruined city with mountains behind, 2) 1994 Chechen resistance: a bearded mountain fighter with a rifle on a rocky Caucasus slope, a green banner, 3) 1999 Second Chechen War: a modern Russian tank and a helicopter over a ruined city at dusk, 4) Caucasus resistance: fighters moving through a misty mountain forest, 5) 1974 Cyprus landing: a landing craft and soldiers coming ashore on a sunny Mediterranean beach, paratroopers in the sky
Row 2: 6) 1914 Ottoman neutrality: an Ottoman officer in a fez looking over the Bosphorus with a dreadnought anchored peacefully, 7) 1914 Britain stays out: a British bowler-hat diplomat at the White Cliffs of Dover watching distant smoke over the sea, 8) 1914 the Triple Alliance holds: an Italian Alpine soldier with a feathered hat beside an Austro-Hungarian soldier in the Alps, 9) 1914 the Schlieffen plan works: WW1 German infantry in spiked helmets marching toward a distant Eiffel Tower, 10) 1914 peace in Sarajevo: an open vintage motorcar with a calm crowd and doves on a stone bridge
Row 3: 11) 1917 the Tsar holds: a Russian imperial guard in a fur hat before onion-domed palace and a parade, 12) 1941 Moscow-Berlin axis: a WW2 Soviet T-34 and a German Panzer side by side facing west, 13) 1944 plot against Hitler: an officer leaving a briefcase under a map table in a wooden barracks, 14) 1942 Ankara chooses a side: a Turkish WW2 soldier with a rifle on a Bosphorus hilltop, ships below, 15) 1941 Japan turns north: Japanese WW2 tanks and infantry in snowy Siberian taiga
Row 4: 16) 1940 the Maginot line holds: a concrete French bunker with a gun turret and a WW2 French soldier, 17) 1940 Spain joins the Axis: WW2 troops and artillery on the Rock of Gibraltar coast, 18) 1962 missile crisis explodes: a nuclear missile launching from a Caribbean palm-tree island, warships offshore, 19) 1969 Sino-Soviet war: tanks clashing on a frozen river border in winter, 20) 1961 Berlin war: tanks facing each other at a checkpoint beside a concrete wall at night
```
(21. ikon `era_alt_axis62` için tek istem: "a single round illustrated badge in the same style: 1962 alternate world where the Axis won — a futuristic grey jet over a divided North America with a mountain neutral zone", aynı komutla `--start=20` ile kes.)

## Paket 19 — İnşa / kaynak ara ikonu (1 adet, bld_* sticker stili)
Kesme: `python3 tools/slice_icons.py sayfa.png --blobs --set=pack19` → assets/icons/build_c.png ("Bina kur", "Kaynak ara", "Toplu işlemler" düğmeleri)

```
Create ONE image: a single game icon sticker centered on a plain solid flat magenta (#FF00FF) background: a construction hammer crossed with a wrench in front of a small half-built brick wall with a wooden scaffold, cartoon sticker style for a mobile strategy game, bold dark outlines, warm muted colors, soft flat shading, a thick white sticker border around the whole shape. NO text, NO letters; the magenta must not appear inside the icon.
```

## Bayrak — Kayalık Dağlar Tarafsız Bölgesi (alt_axis62)
Dosya: assets/flags/era_alt_neutral_zone.png (480x320 PNG, 3:2)

```
A flat vector-style national flag, exact 3:2 rectangle, filling the whole image edge to edge with no border, no shadow, no waving, no background: a fictional 1960s "Rocky Mountain Neutral Zone" flag — horizontal bands of pine green over white over sky blue, with a simple white-and-grey mountain-peak silhouette inside a gold circle at the center. Simple bold shapes, no text, no letters.
```
