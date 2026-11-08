# Sahne afişleri (Gemini) — 2 görsel, 16 sahne

Harekât, diplomasi ve ticaret pencerelerinin üstündeki afişleri koddan çizilenlerin yerine Gemini görselleriyle değiştiriyoruz.
Oyun görseli yavaş yaklaşma/uzaklaşma, duman-kıvılcım, tarama çizgisi, ışık geçişi gibi hafif efektlerle canlandırır (video gerekmez).
Panel 2:1 yatay; afiş ince şerit olarak kırpıldığı için ana konu panelin **orta bandında** olmalı (istemde yazıyor).

## Sayfa A (askerî harekâtlar) — istem
```
Create ONE square image (as high resolution as possible, 2048x2048 or larger): a clean grid of 8 separate wide scene illustrations, 2 columns x 4 rows, on a plain solid flat magenta (#FF00FF) background. Each scene sits inside its own dark navy rounded rectangle panel with a thin dark border; every panel has the same size and a 2:1 wide aspect ratio (twice as wide as tall), with a small gap between panels. Style: bold flat vector poster illustration for a mobile grand-strategy war game (World Empire 2027 / Age of Civilizations II feel): simple strong shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold) with dramatic lighting, clean dark outlines, soft flat shading, atmospheric depth with 3 layers (foreground, midground, distant background), cinematic composition. IMPORTANT: keep the main subject centered in the middle horizontal band of each panel, leaving the top and bottom thirds as calm sky/ground (the picture will be cropped into a thin wide banner). Faceless generic soldiers only, NO real flags, NO swastikas or hate symbols, NO real logos, NO text, NO letters, NO numbers, NO watermark; the magenta must not appear inside the panels. Fill the grid left-to-right, top-to-bottom in exactly this order:
1) ground assault: a column of olive-green tanks and infantry advancing across a wheat field at dawn, dust and smoke behind them
2) artillery barrage: a battery of howitzers firing at dusk with bright muzzle flashes, shells streaking across an orange sky
3) blitzkrieg: a very fast armored column racing along a road in a dust cloud under a stormy sky, motion blur streaks
4) naval bombardment: two grey battleships firing a broadside at night over dark sea, orange gun flashes lighting the water
5) air operation: a formation of bomber aircraft flying over a coastline with searchlight beams and flak puffs in a twilight sky
6) missile strike: several missiles rising on bright smoke trails from a launcher at dusk, a radar dish in the background
7) airborne drop: many paratroopers with round parachutes descending over farmland at sunrise, transport planes above
8) special forces raid: three dark silhouettes in night-vision green tones moving along a wall toward a compound, searchlight and fog
```

## Sayfa B (çıkarma, siber, diplomasi, ticaret, savaş, barış) — istem
```
Create ONE square image (as high resolution as possible, 2048x2048 or larger): a clean grid of 8 separate wide scene illustrations, 2 columns x 4 rows, on a plain solid flat magenta (#FF00FF) background. Each scene sits inside its own dark navy rounded rectangle panel with a thin dark border; every panel has the same size and a 2:1 wide aspect ratio (twice as wide as tall), with a small gap between panels. Style: bold flat vector poster illustration for a mobile grand-strategy war game (World Empire 2027 / Age of Civilizations II feel): simple strong shapes, saturated but slightly muted military colors (olive green, khaki, steel blue, brick red, gold) with dramatic lighting, clean dark outlines, soft flat shading, atmospheric depth with 3 layers (foreground, midground, distant background), cinematic composition. IMPORTANT: keep the main subject centered in the middle horizontal band of each panel, leaving the top and bottom thirds as calm sky/ground (the picture will be cropped into a thin wide banner). Faceless generic soldiers only, NO real flags, NO swastikas or hate symbols, NO real logos, NO text, NO letters, NO numbers, NO watermark; the magenta must not appear inside the panels. Fill the grid left-to-right, top-to-bottom in exactly this order:
1) amphibious landing: landing craft with open ramps unloading soldiers onto a beach at dawn, splashes and smoke, warships on the horizon
2) cyber attack: a dark world map made of glowing green circuit lines and falling binary rain, a red warning triangle over one region, a padlock in the center
3) espionage: a mysterious figure in a trench coat and hat under a street lamp in a rainy night street handing over an envelope, long shadows
4) sanctions and embargo: cargo ships and crates stopped behind a large red barrier gate and chains at a harbor at dusk
5) trade: a busy harbor with cranes, stacked colorful containers and a large cargo ship leaving at golden hour
6) alliance: two firm handshakes of silhouetted allies in front of a row of generic plain colored pennants (blue, green, gold, red; no real flags), warm light
7) war: a burning city skyline at night with smoke columns, searchlights and a blood-red sky, a few small silhouettes of tanks in the foreground
8) peace: a white dove carrying an olive branch over a rebuilt town and green hills at sunrise, golden rays of light
```

## Kesme
```
python3 tools/slice_scenes.py sayfaA.png A
python3 tools/slice_scenes.py sayfaB.png B
```
→ `assets/scenes/<ad>.jpg` (1024x512). Adlar: A = assault, barrage, blitz, naval, air, missile, paradrop, special; B = landing, cyber, spy, sanction, trade, alliance, war, peace.
Eşleme: `summit` (zirve) → alliance, `nuke` → war, `embargo` → sanction görselini kullanır. Dosya yoksa eski kodlu afiş görünür.

## İpuçları
- Gemini 2K/4K çıktı verirse seç. Küçük çıkarsa (ör. 1024) yine çalışır ama afiş telefonda biraz yumuşak görünür.
- Bir sahne beğenilmezse sadece onu başka bir görselde yeniden ürettirip tek panelini kesebiliriz.
- Panel sayısı 8 çıkmazsa (Gemini birleştirirse) kesici "bulunan panel" sayısını yazar; bana söyle.
