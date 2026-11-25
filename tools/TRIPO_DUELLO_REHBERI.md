# Tripo ile düello karakterleri

Hedef: Warband/Bannerlord tadında yönlü kılıç düellosu için iki iskeletli şövalye, bir kılıç, bir kalkan ve (isteğe bağlı) arena.
Dosyalar `assets/duel/` klasörüne konur. Oyun bu dosyaları görünce kendiliğinden kullanır; yoksa basit şekillerle çizer.

## Dosya şartları
| Dosya | Ne | Not |
|---|---|---|
| `knight_player.glb` | Oyuncu şövalyesi, **iskeletli (rigged)** | T-pozundan rig edilmiş, insansı iskelet |
| `knight_foe.glb` | Rakip şövalye, **iskeletli** | Farklı zırh/renk (ör. koyu kırmızı, miğferli) |
| `sword.glb` | Kılıç | Kabzası orijinde, bıçak +Y yönünde ya da fark etmez; ben hizalarım |
| `shield.glb` | Kalkan (isteğe bağlı) | |
| `arena.glb` | Arena (isteğe bağlı) | Yoksa basit zemin ve sur çizilir |

- Biçim: `.glb`. Karakter en çok ~15.000 üçgen, doku en çok 1024x1024. Telefon için hafif tut.
- Karakterler **T-pozunda** olsun, yüzleri +Z'ye (ileriye) baksın. Tripo'da rig sonrası "T-pose" çıktı al.
- Silahı karakterin eline **gömme**; kılıç ve kalkan ayrı dosya olsun (ben ele bağlarım). Karakter silahsız üretilsin.

## Tripo adımları
1. Text-to-model (ya da bir görselden) ile karakteri üret, en iyi sonucu seç.
2. **Rig** (otomatik iskelet) uygula, insansı (humanoid) seç.
3. İndir: `GLB`. (Animasyon indirmen şart değil; kol hareketlerini kodla veririm. İstersen Tripo'nun bekleme/hasar alma animasyonlarını da ekle.)

## İstemler (İngilizce yaz)

Oyuncu şövalyesi:
```
medieval knight in full plate armor with a simple open helmet and a dark blue tabard, T-pose, arms straight out to the sides, symmetrical, stylized low poly game character, no weapon, no shield, neutral standing pose, clean topology
```

Rakip şövalye:
```
medieval warrior in dark red and black armor with a closed helmet and a leather cloak, T-pose, arms straight out to the sides, symmetrical, stylized low poly game character, no weapon, no shield, clean topology
```

Kılıç:
```
medieval arming sword, straight double-edged steel blade, simple crossguard, leather wrapped grip, round pommel, low poly game asset, single object
```

Kalkan:
```
round wooden viking shield with a steel boss in the center and a metal rim, painted red and white, low poly game asset, single object
```

Arena (isteğe bağlı):
```
small medieval duel arena inside a stone castle courtyard, round sand floor, stone walls with banners, low poly stylized game environment, no characters
```

## Animasyon nasıl çalışacak
Yönlü düelloda her vuruş ve siper kolun duruşuyla gösterilir (sol, üst, sağ, saplama). Bu duruşları kodla iskelet kemiklerine
veririm; hazır animasyon klibi aramak gerekmez. Sende hazır klip varsa (Mixamo gibi) şu adlarla ekleyebilirsin; olanı kullanır, olmayanı koda bırakır:
`idle`, `hit` (hasar alma), `stagger` (sendeleme), `death`, `victory`.
