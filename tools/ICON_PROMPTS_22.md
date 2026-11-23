# İkon paketi 22 (Gemini) — çakışan ikonları ayıran 8 yeni rozet (uc_* stili)

Sorun: aynı ikon birden fazla yerde kullanılıyordu (ör. Çok Oyunculu = Online = Dünya paneli = Ticaret sekmesi → hepsi "globe").
Mevcut resimlerle çözülenler koda zaten bağlandı (aşağıdaki tablo). Bu paket sadece resmi OLMAYAN 8 yeri kapatır.
Kesme: `python3 tools/slice_icons.py sayfa.png 4 2 --set=pack22`
Çıktı: assets/icons/<ad>_c.png — oyun OTOMATİK kullanır (Icons.pick): mp_multi, mp_online, mp_hotseat, howto, world2027, shop, people, cabinet.
Sıra (4 sütun x 2 satır): 1) mp_multi  2) mp_online  3) mp_hotseat  4) howto / 5) world2027  6) shop  7) people  8) cabinet

```
Create ONE image: a clean 4 columns x 2 rows grid of 8 separate round badge icons on a plain solid flat magenta (#FF00FF) background, equal size, with a clear gap between badges. Every badge is a perfect circle filled with deep navy blue (#12254A) with a thin cream (#F2E9CF) ring just inside the edge, and a single bold cream-colored flat silhouette in the middle (no other colors, no shading, no gradients, no outline details beyond tiny cut-out lines in navy), exactly like a minimal military unit-class emblem, large and readable at 48 px. NO text, NO letters; the magenta must not appear inside the badges. Do NOT draw a globe or world map in any of them.
Row 1: 1) two game controllers or two opposing flags crossing over a small versus lightning bolt (multiplayer menu), 2) a smartphone with three curved wifi signal arcs above it and a small crown (online play), 3) a single phone being handed from one open hand to another hand (pass-and-play on the same phone), 4) an open book with a question mark and a small lit lightbulb (how to play).
Row 2: 5) a calendar page with a tank, a jet and a missile silhouette standing in front of it (the modern world scenario), 6) a market stall awning over a shopping basket with a star (store), 7) three standing citizen figures side by side, the middle one slightly taller (the people / public opinion), 8) a ministerial briefcase with a small star seal and two stacked folders (cabinet).
```

## Çakışma raporu (neyin yerine ne bağlandı)

| Yer | Eskiden | Şimdi | Durum |
|---|---|---|---|
| Menü: Çok Oyunculu | globe | mp_multi (yoksa summit) | yeni prompt #1 |
| Çok Oyunculu → Online | globe | mp_online (yoksa radio_tower) | yeni prompt #2 |
| Çok Oyunculu → Aynı Telefon | users | mp_hotseat (yoksa users) | yeni prompt #3 |
| HUD: Dünya paneli | globe | globe (değişmedi, tek kullanan) | — |
| Politika sekmesi: Ticaret | globe | trade | mevcut resim |
| HUD: Politika | tank | politics | mevcut resim |
| HUD: Savaşlar + Dünya paneli Savaşlar sekmesi | swords | war_declared | mevcut resim |
| Politika: Cepheler | swords | war_room | mevcut resim |
| HUD: İlişkiler | handshake | diplomacy | mevcut resim |
| Politika: İttifak + Dünya paneli İttifaklar | handshake | alliance_shield | mevcut resim |
| HUD: Başkent | target | capital | mevcut resim |
| Politika: Odak | target | focus | mevcut resim |
| Menü: Günlük Meydan Okuma | target | daily_challenge | mevcut resim |
| Menü: Tarihî Savaşlar | hourglass | chronicle | mevcut resim |
| Menü: Bağımsızlık Yolu | flag | independence | mevcut resim |
| Politika: Envanter | shield | arsenal | mevcut resim |
| Menü: Nasıl Oynanır | book | howto (yoksa hint) | yeni prompt #4 |
| Menü: Dünya 2027 | book | world2027 (yoksa year) | yeni prompt #5 |
| Menü: Mağaza | coins (Bütçe ile aynı) | shop (yoksa money_bag) | yeni prompt #6 |
| Politika: Halk | flag | people (yoksa flag) | yeni prompt #7 |
| Politika: Kabine | badge | cabinet (yoksa badge) | yeni prompt #8 |

Bilerek aynı bırakılanlar: Bütçe sekmesi = coins (gelir ikonuyla tutarlı), Silah Alımı = tank, silhouette.gd'deki Dışişleri rolü = globe (rol rozeti, ayrı bağlam).
