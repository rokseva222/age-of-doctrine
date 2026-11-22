# İkon paketi 16 (Gemini) — modern/savaş gemisi sınıfları + hava sınıfları (uc_* rozet stili)

Mevcut uc_* setiyle (uc_destroyer, uc_carrier, uc_sub…) AYNI stil: lacivert daire rozet, krem halka, krem siluet.
**Paket 15'in yerine geçer** (onun 4 ikonu da burada; paket 15'i ayrıca üretme).

Kesme: `python3 tools/slice_icons.py sayfa.png 5 3 --set=pack16`
Çıktı: assets/icons/uc_<ad>_c.png — oyun bunları OTOMATİK kullanır (kod değişikliği gerekmez):
- Donanma: Soğuk Savaş/Modern çağlarda filo satırları ve panel (kruvazör, firkateyn, korvet, karakol, füze botu, nakliye, çıkarma gemisi); WW1/WW2 çağlarında torpido botu, ağır/hafif kruvazör, eskort.
- Hava: hava köprüsü (nakliye uçağı), İHA, keşif uçağı kanat simgeleri.

```
Create ONE image: a clean 5 columns x 3 rows grid of 15 separate round badge icons on a plain solid flat magenta (#FF00FF) background, equal size, with a clear gap between badges. Every badge is a perfect circle filled with deep navy blue (#12254A) with a thin cream (#F2E9CF) ring just inside the edge, and a single bold cream-colored flat silhouette in the middle (no other colors, no shading, no gradients, no outline details beyond tiny cut-out windows/lines in navy), exactly like a minimal military unit-class emblem. Ships are in strict side view on a flat waterline (a short cream waterline stripe is allowed), aircraft in side or top view, all centered, large, readable at 48 px. NO text, NO letters, NO numbers, NO flags, NO logos; the magenta must not appear inside the badges. Fill the grid left-to-right, top-to-bottom in exactly this order:
Row 1: 1) a modern military sealift cargo transport ship: long hull, stern ramp, deck stacked with containers and vehicles, small bridge at the rear, 2) a modern amphibious assault ship: wide flat flight deck, small island on the right, a helicopter on deck, 3) a modern frigate: sleek low hull, one gun on the bow, round radar dome mast, small helicopter pad at the stern, 4) a modern guided-missile cruiser: long hull, boxy missile launchers on deck, two tall radar masts, gun on the bow, 5) a modern corvette: small short hull, one gun, compact mast, a small missile rack
Row 2: 6) a small fast patrol boat: tiny hull with a pointed bow, a small gun and a short mast, a little wake, 7) a missile boat: small fast hull with four angled anti-ship missile canisters on the deck and a small radar, 8) a landing ship: boxy hull with an open bow ramp and a tank silhouette on the deck, 9) a WW1-era torpedo boat: very small narrow hull, one thin funnel, a gun forward and a torpedo tube, 10) a WW2 heavy cruiser: long hull, three big gun turrets (two forward, one aft), tall bridge tower, two funnels
Row 3: 11) a WW2 light cruiser: long slim hull, four smaller gun turrets, tall bridge, two funnels, 12) a WW2 escort destroyer: small narrow hull, one forward gun, a funnel and depth-charge racks at the stern, 13) a modern military drone (UAV): long thin fuselage, high-aspect straight wings, V-tail, a camera bulb under the nose, side view, 14) a modern airborne radar surveillance plane: a jet airliner-shaped fuselage with a large round radar dome on top, side view, 15) a modern military airlift transport aircraft: fat fuselage, high wing, four engines, T-tail, open rear cargo ramp, side view
```

Kontrol: kesince `python3 tools/shot_icons.gd`/oyunda Filolar panelinden bak; arka plan temizlenmezse bana ham sayfayı ver.
