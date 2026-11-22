# Ekibimizi Tanıyın — Rok Games Studios Instagram story üreticisi

1080x1920 dikey PNG story kareleri üretir: üstte Rok Games logosu + "EKİBİMİZİ TANIYIN" + "ROK GAMES STUDIOS", ortada ekip kartları, altta "Age of Doctrine" ve "Yakında · Google Play" etiketi.

Gereken: Python 3 + Pillow (ek paket yok). Yazı tipleri oyunun `assets/fonts/` klasöründen okunur (Big Shoulders Bold, Instrument Sans, IBM Plex Mono).

## Kullanım

```bash
python3 store/team_story/make_story.py                      # varsayılan team.json (yer tutucu isimler)
python3 store/team_story/make_story.py benim_ekip.json      # kendi dosyan
python3 store/team_story/make_story.py team.json --only grup    # yalnızca toplu kare
python3 store/team_story/make_story.py team.json --only tekli   # yalnızca üye başına kareler
python3 store/team_story/make_story.py team.json --out baska/klasor --prefix v2_
```

Çıktılar `store/team_story/out/` altına yazılır:

- `grup.png` — tüm ekip tek karede (8'den fazla üye varsa `grup_1.png`, `grup_2.png` ... sayfalara bölünür)
- `uye_01_isim-soyisim.png`, `uye_02_...png` — her üye için ayrı story ("tek üye = bir story")

Düzen üye sayısına göre otomatik seçilir: 1 üye = büyük tek kart; 2–4 üye = dikey liste; 5–8 üye = 2 sütunlu ızgara (tek kalan kart ortalanır).

## team.json biçimi

```json
{
  "members": [
    {
      "name": "Ad Soyad",
      "role": "Kurucu & Oyun Tasarımcısı",
      "photo": "photos/ad_soyad.jpg",
      "bio_short": "İstersen tek cümlelik kısa tanıtım.",
      "focus": [0.5, 0.2]
    }
  ]
}
```

- `name` (zorunlu): varsayılan olarak Türkçe kurallı BÜYÜK HARFE çevrilir (i → İ, ı → I). Kapatmak için `config.json` içinde `"name_case": "as_is"`.
- `role`: unvan / statü. Boşsa "Unvan" yazar.
- `photo`: dosya yolu (team.json'ın bulunduğu klasöre göre ya da mutlak yol). Boş bırakılır ya da dosya bulunamazsa baş harfli yer tutucu daire çizilir (uyarı verir). Fotoğraf otomatik kare kırpılır (varsayılan: yatay ortada, dikeyde yukarı ağırlıklı), daireye maskelenir, ince çerçeve eklenir. EXIF dönüklüğü düzeltilir.
- `bio_short` (isteğe bağlı): tekli karede kutu içinde, 2–4 üyelik listede yer varsa görünür; ızgarada görünmez.
- `focus` (isteğe bağlı): bu üyenin kırpma konumu `[x, y]` (0 = sol/üst, 1 = sağ/alt). Yüz kesiliyorsa ayarla.

Bir dizi (`[ {...}, {...} ]`) da kabul edilir. İsteğe bağlı olarak team.json'a `"config": {...}` ekleyip ayarları o ekip için değiştirebilirsin.

Çok uzun isim/unvanlar otomatik küçültülür, gerekirse iki satıra bölünür; son çare olarak "…" ile kısaltılır. Boş/eksik fotoğraf ya da isim betiği çökertmez.

## config.json — ayarlar

Metinleri ve görünümü buradan değiştir (betiği düzenlemene gerek yok):

| Anahtar | Anlamı |
|---|---|
| `title`, `subtitle` | Üst başlık ve alt başlık |
| `game_name` | Altta büyük görünen oyun adı |
| `badge` | Alttaki etiket, örn. `"YAKINDA · GOOGLE PLAY"` → yayınlanınca `"GOOGLE PLAY'DE"`; boş bırakırsan gizlenir |
| `footer_note` | Oyun adının altına isteğe bağlı kısa cümle |
| `member_label` | Tekli karede "PERSONEL 02 / 05" etiketi (boş = gizli) |
| `show_index` | Kartlardaki 01, 02... numaraları |
| `name_case` | `upper` ya da `as_is` |
| `photo_shape` | `circle` ya da `rounded` (hafif köşeli kare) |
| `photo_focus` | Varsayılan kırpma konumu `[0.5, 0.2]` |
| `safe_top`, `safe_bottom` | Instagram arayüzünün kapattığı üst/alt pay (px) |
| `logo`, `logo_height` | Logo dosyası ve yüksekliği |
| `colors` | Renkler (varsayılanlar oyunun `theme_kit.gd` renkleri: BG `#0b0e12`, PAPER `#ece6d6`, RED `#e5482f` ...) |

## Logonun kaynağı

Repoda ayrı bir Rok Games logo PNG'si yok. `assets/brand/emblem.png` ve `wordmark.png` Age of Doctrine'in kendi markası (kırmızı yıldızlı rütbe arması), Rok Games'in değil. Rok Games logosu (altıgen içinde "ROK") yalnızca stüdyo açılış videosunda var: `assets/brand/rok_intro.ogv` (oyunda `scripts/menu.gd` içindeki `INTRO_PATH` ile oynatılıyor).

Logo bu videodan ffmpeg ile alındı, yeniden çizilmedi:

1. `ffmpeg -ss 6.5 -i assets/brand/rok_intro.ogv -frames:v 1` ile 6.5. saniyedeki kare (logo tam boyda ve net) -> `assets/rok_intro_frame_6.5s.png` (ham kare, 1280x720).
2. Logo çevresi kırpıldı (386x399 px) ve koyu zemin parlaklığından saydamlık (alfa) maskesi çıkarıldı; renk oyunun PAPER rengi (`#ece6d6`) -> `assets/rok_logo.png`. Koyu zeminde videodakiyle aynı görünür; açık zeminde kullanma.

Daha yüksek çözünürlüklü/vektör orijinal logon varsa `assets/rok_logo.png` yerine koy (şeffaf PNG), `config.json`'daki `logo` yolu aynı kalabilir.

## Dosyalar

- `make_story.py` — üretici betik
- `team.json` — varsayılan örnek (3 yer tutucu üye)
- `config.json` — metin/görünüm ayarları
- `examples/` — 1, 3, 6 ve uzun-metin (8 üye) test dosyaları
- `photos/` — fotoğrafları buraya koyabilirsin
- `assets/` — logo ve ham video karesi
- `out/` — üretilen PNG'ler
