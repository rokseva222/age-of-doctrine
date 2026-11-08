# Age of Doctrine (AoD)

Jeopolitik ve kaynak yönetimi odaklı büyük strateji oyunu (Godot 4.3, GDScript). Gerçek dünya haritası, gerçek asker sayıları ve isimli silahlar, makro bütçe/politika (mikro yönetim yok), siber/lojistik/sanayi savaşı, ticaret ve ambargo. Mobil için tasarlandı (yatay ekran).

## Oyun kipleri
- **Serbest oyun (Dünya 2027)** ve **senaryolar**: gerçek (Rusya–Ukrayna, Çin–Tayvan, İran–İsrail/ABD, Hindistan–Pakistan, Kore, Kafkasya) ve kurgusal modern senaryolar (Kara Sancak, Yeni Reich, Baltık Kıvılcımı, İmparatorun Dönüşü, Sessiz Savaş). Kurgusal gruplar uydurma adlar taşır.
- **İttifaklar**: oyun başında/içinde kur, adlandır, amblemini kendin tasarla (şekil, desen, simge, 3 renk).
- **Tarihî Savaşlar** (ana menüde ayrı giriş): I. Dünya Savaşı (Ağustos 1914) ve II. Dünya Savaşı (Eylül 1939). Dönem imparatorlukları (sömürgeleriyle), dönem silahları ve haftalık geliştirme kapıları, dönem ittifakları (İtilaf/Merkezi Güçler, Müttefikler/Mihver) ve dönemin renklerine çekilmiş harita/arayüz (`shaders/era_grade.gdshader`). Lider isimleri yalnızca metindir; fotoğraf ve sembol kullanılmaz.
- Güncel lider isimleri `data/leaders.json` (Kasım 2026, kaynak: Wikipedia devlet başkanları listesi).

## Çalıştırma
1. Godot 4.3 ile `project.godot` dosyasını aç (ilk açılışta yazı tipini içe aktarır).
2. F5 ile oyna.

## Google Play
Mağaza paketi `store/` klasöründe: metinler, gizlilik politikası, görseller, ekran görüntüleri ve `release_guide.md` (adım adım yayın rehberi). Görselleri yeniden üretmek için `python3 tools/make_store_art.py` (ekran görüntüleri `tools/shot_store.gd` ile 1920x1080'de alınır).

## Android
Proje > Dışa Aktar > Android. `export_presets.cfg` içindeki paket adını (`com.rokgames.ageofdoctrine`) kendi adınla değiştir, imza anahtarını tanımla.

## Varlıklar
- Bayraklar, ikonlar, logo, menüler, **animasyonlu sahne afişleri** (`scripts/scene_art.gd`) ve **yüzsüz silüet portreler** (`scripts/silhouette.gd`) çalışma anında **kodla çizilir**.
- **İkonlar**: `assets/icons/<ad>.png` (beyaz, şeffaf glif; renge boyanır) veya `<ad>_c.png` (renkli) varsa kodla çizilen ikonun yerine kullanılır. Gemini istemi ve tek sayfa kesici: `tools/ICON_PROMPTS.md`, `python3 tools/slice_icons.py sayfa.png 8 7` (koyu karelere yerleştirilmiş sayfa için `--tiles`; şu an oyundaki 51 renkli ikon bu yolla kesildi). Paket 2 (olaylar/ekonomi/dönemler, 48): `tools/ICON_PROMPTS_2.md`, `--set=pack2`; paket 3 (binalar/birimler/lojistik/durum, 48): `tools/ICON_PROMPTS_3.md`, `--set=pack3`.
- **Rastgele olaylar**: 15 tür (altın, kriz, maden, gönüllü, deprem, salgın, sel, kuraklık, fırtına, protesto, darbe girişimi, mülteci, hasat, bilimsel atılım, zirve); her haber kaydı `ic` (ikon) taşır ve bülten/geçmiş/gazetede gösterilir. Test: `tools/event_test.gd`.
- Müzik ve ses efektleri **Python (numpy/scipy) ile sentezlenir** ve `assets/audio/` altına .ogg olarak yazılır (sample/lisanslı kayıt yok). Yeniden üretmek için: `cd tools/audio && python3 make_music.py` (menü, barış, savaş, 1. DS, 2. DS; döngüsel) ve `python3 make_sfx.py` (30 efekt: tik-tak, teleks, top, uçak, siren, sonar, mühür...). ffmpeg (libvorbis) gerekir; ardından `godot --headless --import`.
- Dışarıdan yalnızca: Rubik yazı tipi (OFL lisansı, `assets/fonts/OFL.txt`) ve Natural Earth harita verisi (kamu malı, işlenmiş hâli `data/world.json`).
- Veri hattı: `tools/data/build_world.py` (Natural Earth 10m dosyalarından `world.json` üretir).

## Oynanış akışı
- Oyun **tur tabanlıdır**: sağ üstteki "Turu geç" düğmesi (Boşluk/Enter) bir hafta ilerletir. Yükleniyor ekranından sonra "Cihan Bülteni" haber ve harp raporu ekranı açılır (`scripts/turn_ui.gd`).
- **Taarruz**: savaştığın ülkenin eyaletine dokun → "Taarruz". Yakındaki orduları seç, harekât türünü belirle (kara taarruzu, topçu/hava hazırlığı, siber harp, yıldırım), tahmini üstünlüğü gör, emri ver (`scripts/assault_ui.gd`, mantık `game_state.gd: OPS, player_launch_assault`). Sonuç ve kayıplar tur sonu raporunda görünür.

## Kabine kartları, isimler ve gizli harekât
- **Kabine kartları** (`scripts/cabinet.gd`, `cabinet_ui.gd`, Ayarlar'dan kapatılabilir): bakanlar (savunma, dışişleri, içişleri, maliye, sağlık, istihbarat, büyükelçi) karar sorar; bazı seçimler oyunu bitirebilir.
- **İsimler**: `data/cabinet.json` gerçek bakanlar (Kasım 2026, yalnızca metin; `tools/merge_cabinet.py` ile birleştirilir). Gerçek isimler 2-4 oyun yılı geçerlidir; sonra (ve tarihî kiplerde / isim bulunmayan görevlerde) `scripts/name_gen.gd` ülkenin isim kültürüne göre deterministik rastgele isim üretir. Liderler de yılda ~%10 olasılıkla değişir.
- **İstihbarat sekmesi** (Politika): casusluk, propaganda, sabotaj, elçilik; başarı şansı siber güce ve teknolojiye bağlıdır (`game_state.gd: player_covert`).

## Kayıt yuvaları, paralı asker, bildirim
- **Kayıt**: otomatik kayıt (yuva 0) + 3 elle yuva; Ayarlar'dan otomatik kayıt açılıp kapatılır. Menüde "Devam" yuvaları listeler.
- **Asker gönderme**: ordu seçip hedefe dokununca kaydırıcıyla kaç askerin yola çıkacağı seçilir (%25/50/75/100). Saldırıda da aynı oran vardır.
- **Otomatik asker atama** (Ayarlar): tur boyunca emir vermezsen savaştaki boş ordular en iyi cephe hedeflerine kendiliğinden gider.
- **Paralı asker**: Politika > Cepheler. Ülkenin kültürüne göre rastgele isim alır (`scripts/militias.gd`; Rusya, Türkiye, Tayvan, Japonya, ABD… için ayrı havuzlar).
- **Bildirim** (yalnızca Android, yalnızca devam eden oyun varsa, 5 saatte bir): "Android Notification Scheduler" eklentisi gerekir.
  AssetLib'den kur (Android Notification Scheduler) → Project Settings > Plugins'ten etkinleştir → Android export şablonunda `POST_NOTIFICATIONS` iznini aç.
  Eklenti yoksa oyun sorunsuz çalışır, bildirim sessizce atlanır (`scripts/notifier.gd`).

## Diller
- Arayüz dilleri: Türkçe (kaynak), English, Deutsch, Español, Français, Italiano, Português, Русский, العربية, فارسی, 中文, 日本語, 한국어, हिन्दी. İlk açılışta cihaz diline göre seçilir; Ayarlar > Dil'den değiştirilir (oyun otomatik kaydedilip arayüz yeniden kurulur).
- Haritadaki ülke adları Türkçede Türkçe, diğer tüm dillerde İngilizcedir.
- Motor: `scripts/loc.gd` (Godot çeviri kancası + şablon eşleştirme). Paketler `data/i18n/<dil>.json`; kaynak çeviri dosyaları `tools/i18n/<dil>_*.txt` (`id|metin`) ve `<dil>_extra.tsv`; `python3 tools/i18n_build.py` ile derlenir. Eksik metin: seçili dil → İngilizce → Türkçe.
- Kapsam: tüm diller için temel arayüz (menü, ayarlar, savaş, diplomasi, bildirimler, haber başlıkları) çevrildi; kabine kartları, tarihî savaşlar ve senaryo metinleri şimdilik yalnızca İngilizce+Türkçe.
- Yeni metin eklerken `python3 tools/i18n_extract.py` ile `items.tsv` yenilenir. Eksik çeviri taraması: `LANG_SHOT=en godot ... -s tools/playthrough.gd` sonunda `/tmp/loc_misses.txt` yazar.
- Arapça/Farsça sistem yazı tipi yedeği ve yerleşim yansıtması (RTL) Godot tarafından otomatik uygulanır; CJK ve Devanagari için cihazın sistem yazı tipi kullanılır.

## Tarihî dönemlerde liderler
I. ve II. Dünya Savaşı kiplerinde liderler rastgele değişmez; `scripts/era_leaders.gd` içindeki gerçek halef zinciri tarihine göre işler (örn. Türkiye WW2: İsmet İnönü → Mayıs 1950 Celal Bayar; WW1: V. Mehmed Reşad → VI. Mehmed → Atatürk → İnönü). Zincir bitince (WW1 için 1940, WW2 için 1952) rastgele halefiyet devam eder. Modern dünya ve kurgusal senaryolarda liderler/seçimler rastgele kalır. Oyuncunun kendi ülkesi zincire tabi değildir.

## Yeni özellikler (BM, çıkarma, bayraklar)
- **Birleşmiş Milletler** (Dünya paneli > BM): 11 önerge (ateşkes, yeniden inşa fonu, insani yardım, barış gücü, kalkınma programı, egemenlik garantisi, yaptırım, silah ambargosu, uluslararası soruşturma, silahsızlanma, ortak harekât). Tüm ülkeler oy verir, salt çoğunlukla karar alınır, **veto yoktur**. Tarihî kiplerde Ekim 1945'ten itibaren. Yapay zekâ da zaman zaman ateşkes/yardım önergesi verir. Kod: `scripts/un.gd`.
- **Amfibi çıkarma**: deniz bağlantısı olan düşman eyaletine kıyıdaki ordular çıkarma yapar (taarruz −15 yüzde, savunma +10 yüzde, kapasite donanma gücüne bağlı). Kod: `game_state.gd` (OPS.landing, armies_near, player_launch_assault).
- **Gerçek ülke bayrakları**: `assets/flags/*.png` (flag-icons, MIT lisansı; `LICENSE-flag-icons.txt`). Tarihî dönem bayrakları ve isyancı gruplar kodla çizilmeye devam eder.
- **İlişki görünümü** (World Empire tarzı): sağ paneldeki el sıkışma düğmesi haritayı seçili ülkeye göre boyar (sarı seçili, mavi müttefik, kırmızı savaş, mor ateşkes). Ülke kartındaki "İlişkiler" düğmesi o ülkenin savaş, ittifak ve ateşkeslerini listeler.
- **Elle konuşlandırma**: elle gönderilen birlikler otomatik komuttan muaf kalır (`Army.hold`).
- **Tarihî liderler**: `scripts/era_leaders.gd` (WW1/WW2 gerçek halef zinciri).

## Ses
- `scripts/sfx.gd` ses yöneticisidir: menüde `menu`, oyunda barışta `peace`, savaşta (bitişten sonra 20 sn tutarak) `war` + savaş ambiyansı, tarihî kiplerde `ww1`/`ww2` müziği; parçalar arasında çapraz geçiş yapar. Her hafta saat tik-takı, habere göre top/siren/mühür/telsiz efektleri çalar. Ayarlardaki Müzik ve Ses efektleri sürgüleri geçerlidir.
- Tüm sesler aynı algısal seviyeye normalleştirilir (`dsp.py: LEVELS`); efektler arasında seviye farkı yoktur.
- Test: `godot --headless --path . -s tools/audio_test.gd` ve `tools/audio_flow.gd`.

## Testler (başsız)
- `godot --headless --path . -s tools/sim_test.gd -- <tohum> <tur>`: tüm ülkeler yapay zekâ, denge ve hız
- `godot --headless --path . -s tools/save_test.gd`: kayıt/yükleme turu
- `godot --headless --path . -s tools/era_test.gd`: tarihî kipler (katalog doğrulama, 80 tur, kayıt/yükleme)
- `godot --headless --path . -s tools/scn_test.gd`, `bloc_test.gd`, `bot_test.gd`: senaryolar, ittifaklar, yapay zekâ turları
- `xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/shot_ui.gd`: arayüz ekran görüntüleri

## Notlar
- Natural Earth'ün sınır tercihleri (Filistin, Kosova, Batı Sahra, Somaliland, K. Kıbrıs vb. ayrı birim) korunmuştur; ticari yayın öncesi bunları hedef pazara göre gözden geçir.
- Dengeleme ilk sürümdür.

## Marka (sabit)
Logo `assets/brand/emblem.png`, yazı `assets/brand/wordmark.png` (şeffaf PNG). Oyun (`scripts/logo.gd`), uygulama ikonu ve Play Store görselleri (`python3 tools/make_store_art.py`) bunlardan üretilir; değiştirme.

- **Kabine kadrosu**: oyuncunun 6 bakanı (`c.cab`) görev süresi dolunca/istifa/skandal/azil/seçim kaybı ile boşalır; `appoint_ui.gd` 3 aday sunar (Acemi ucuz+skandal riskli, Kıdemli orta, Usta pahalı+haftalık bonus). Politika paneli "Kabine" sekmesi. Gerçek isimli bakanlara asla skandal yazılmaz. Test: `tools/cabinet_test.gd`, görsel: `tools/shot_cab2.gd`.
- **Nişe kartlar** (`cabinet.gd` CARDS): Seçim Gecesi (takvimli, kaybedersen lider+kabine değişir), Gölge Tüccarı (şans sandıkları, `gamble`), Dünya Kupası/Olimpiyat (dört yılda bir, `yr`/`months`), Muhbir (komşuda darbe/sızıntı, `nbstab`).
- **Kültürlü portreler**: `tools/ICON_PROMPTS_4.md`, `--set=pack4`/`raw60`; `assets/icons/pt_<kültür>_<m|f|o><n>_c.png`; `Sil.culture_for(c)` 12 kültüre eşler, isme göre varyant seçilir.

### Tarihî olaylar, nükleer, hedefler, barış şartları (yeni)
- **Etkileşimli öğretici** (`scripts/tutorial.gd`): ilk oyunda otomatik açılır, 18 adımda harita, ordu, tur, politika, kabine, savaş, taarruz, fetih, barış, ittifak, BM, nükleer ve kayıt/hedefleri anlatır; eylem adımları oyuncu yapınca kendiliğinden ilerler, ilgili düğme vurgulanır. Menü → «Öğretici» ile tekrar açılır.
- **Tarihî olay zincirleri** (`scripts/era_events.gd`): WW1/WW2 senaryolarında 37 tarihli olay (savaş ilanları, ateşkesler, ittifaklar) doğru ay-yılda tetiklenir; oyuncu korunur.
- **Yapay zekâ amfibi çıkarması**: karadan yol yoksa deniz bağlantısı olan hedeflere çıkarma dener (`_ai_try_landing`).
- **Nükleer saldırı**: WW2'de ABD (Temmuz 1945'ten), modern çağda nükleer güçler. Hedef ordunun %80'i yok olur; 26 hafta yaptırım, istikrar -10, hedefin müttefikleri savaş açabilir; 26 hafta bekleme.
- **Barış şartları**: barış masasında eyaletlere ek olarak *savaş tazminatı* (rakip kasasının yarısı), *silahsızlandırma* (rakip orduları yarıya), *tampon bölge* (78 hafta ateşkes) seçilebilir; maliyet savaş puanından düşer.
- **Hedefler ve başarımlar** (`scripts/goals.gd`): ilk 5 adımlık öğretici hedef zinciri + 14 başarım; duraklatma menüsünde "Hedefler ve başarımlar". Kalıcıdır (`Settings.ach`). Google Play Games için `Goals.external_unlock = func(id): ...` kancası var (eklenti bağlanınca başarım kimliğini oraya yönlendir).
- **Mobil varsayılan arayüz ölçeği**: telefonda ekran genişliği (mm) ve DPI'dan 1.0–1.3 arası otomatik.
- **İkon paketi 5** (`tools/ICON_PROMPTS_5.md`, `--set=pack5`): BM önergeleri, barış şartları, komutan, başarım madalyaları vb. 32 ikon; dosyalar gelince BM önerge satırlarında otomatik kullanılır (yoksa eski ikonlar).
- **Komutanlar**: büyük muharebe kazanan ordular komutan çıkarır (Sv 1–5, her seviye +%5 savaş gücü); ordu kartında görünür, birleşmede yüksek seviye korunur, kayıtta saklanır.
- **Hava harekâtı**: taarruz harekâtı olarak seçilir (WW1'de yok); etkisi hava gücü üstünlüğüne göre ölçeklenir (savunma −%20'ye kadar).
- **Dünya tepkisi / koalisyon** (fetih sürtünmesi): fetihler tepkiyi artırır (nükleer +40), zamanla söner; 50'yi aşınca komşular ve büyük güçler oyuncuya savaş açar. Hedefler sayfasında göstergesi var.
- **Yeni harekâtlar** (taarruz penceresinde): Donanma Bombardımanı (kıyı eyaleti, donanma üstünlüğüne bağlı), Füze Saldırısı (yalnız modern çağ), Hava İndirme (savunma/evde-savunma bonusunu yok sayar; WW2+), Özel Kuvvet Baskını (≤25.000 asker, +%18 taarruz, düşük kayıp; WW2+). Hava Harekâtı da hava üstünlüğüne göre ölçeklenir.
- **İkon paketi 5** kesildi ve eklendi (BM önerge satırları vb. kullanıyor).
- **Sahne afişleri**: varsayılan olarak kodla çizilen piksel-art animasyonlar (`scripts/pixel_scenes.gd`, 16 sahne: kara/deniz/hava harekâtları, siber, casusluk, yaptırım, ticaret, ittifak, savaş, barış). İsteğe bağlı: `assets/scenes/<ad>.jpg` (Gemini; `tools/SCENE_PROMPTS.md`, `tools/slice_scenes.py`) varsa o görsel kullanılır.

## Genel QA turu (öğretici sonrası)
- **Düzeltmeler:** ölü ülkenin yabancı eyaletleri kontrol etmesi, ittifak+savaş çakışması, WW1/WW2 kayıtlarında nüfus/GSYH, zorluk/senaryo-ülkesi/ordu-geri-çekilme alanlarının kayda yazılması, başkent yeniden atama, ittifak bitince ordunun eve dönmesi, API doğrulamaları, WW1/WW2'de siber içerik kapısı, WW1'de Polonya.
- **Veri:** tools/patch_world_qa.py ile başkentler (Dodoma, Ottawa, Canberra, Naypyidaw, N'Djamena, Bangui...), şehir-devleti enclave'leri (Berlin, Seul, Addis Ababa, Kuala Lumpur, Bamako, Minsk, Taşkent, Niamey, Almatı, Vientiane, Lima...), deniz bağlantıları (Hawaii, Alaska, Andaman, Sardinya, Kanarya, Azorlar, Sjælland, Sabah/Sarawak, Curaçao, Girit), yazım hataları. Dönem aktarımları (Mançurya, Hong Kong, Polonya paylaşımı, Alsace-Lorraine, Transilvanya) eyalet kimliğiyle yeniden yazıldı.
- **Denge:** AI düşman yığınından yol bulmuyor (intihar saldırıları azaldı), ittifak çözülmesi 4× yavaş, savaş ilanı sıklığı ~%40 azaltıldı, sıkışan ordu yok olmak yerine geri çekiliyor, blitz zayıflatıldı, op kayıp etkisi gerçek, zorluk çarpanları [0.7,0.9,1.2], hava gücü ağırlığı yarıya indi.
- Üst çubuk dar ekranlarda (16:9, UI ölçeği 1.3) taşmıyor.

## Dünya krizleri (scripts/crises.gd)
- Oyun ortasında (45. haftadan sonra, ~100 haftada bir) tüm ülkeleri hafifçe etkileyen krizler: salgın (WW1'de İspanyol Gribi), mali çöküş, kıtlık, enerji şoku (modern/WW2).
- **Hafif tasarım:** gelir kaybı en çok ~%9, istikrar kaybı haftada ≤0.3 (tabanlı: oyuncu 40, AI 30); isyanlar zaten yüksekse (istikrar <45) kriz başlamaz; zorluk şiddeti [0.6, 0.8, 1.0] ile çarpar; 10–18 hafta sürer, sonra 60 hafta soğuma.
- Oyuncuya kısa bir kabine kartı sorulur: «Acil önlem paketi» (etki %35'e iner, kasa bedeli), «Kemer sıkma» (%65), «Bekle» (tam etki). Önlem alan oyuncu kriz bitince +3 istikrar alır. Kabine ayarı kapalı olsa da kart çıkar.
- Kayıt/yüklemede saklanır; test: tools/crisis_test.gd.

## Ada ülkeleri ve uçak gemileri
- **Deniz seferi (oyuncu):** ada ülkelerine yalnızca sen denizden saldırırsın (amfibi çıkarma); yapay zekâ ada saldırısı başlatmaz. İlk çıkarmadan sonra sefer otomatik sistemle (Ayarlar → otomatik emir) kara savaşı gibi sürer: ordular kıyıya ilerler, takviye çıkarma yapar, çıkarılan ordu karada kendiliğinden ilerler. Savaş bitince sefer kapanır. (`sea_campaign`)
- **Uçak gemisi grupları** (`scripts/carriers.gd`): Modern ve WW2'de başlangıç gemileri gerçek sayılara göre (ABD 11/7, Çin 3, Japonya 2/8, Türkiye 1...); WW1'de yok. Oyuncu Politika → Envanter'den satın alır (maliyet ≈ 14 haftalık gelir, 3–14 milyar $; bakım gideri; en çok 8; teknoloji ≥ %35). Etkileri: çıkarma kapasitesi +3000/gemi, çıkarma saldırısı +%4/gemi (en çok +%20), deniz gücü +0.8/gemi, kıyıdaki düşman eyaletine **Uçak gemisi saldırısı** (ordu göndermeden; savunan ordunun %10–40'ı, 3 hafta bekleme).
- Testler: tools/island_test.gd, tools/carrier_test.gd.

## Günlük ve haftalık görevler (scripts/missions.gd)
- Cihaz takvimine göre her gün 3 (kolay/orta/zor) ve her hafta 3 görev yenilenir; aynı gün herkes için aynıdır (tohumlu). Türler: tur oyna, emir ver, muharebe, fetih, ittifak, BM önergesi, barış, savaş ilanı, çıkarma.
- İlerleme, hangi oyunda oynanırsa oynansın oyun istatistiklerinden otomatik birikir (main.gd `_track_missions`). Ödül Komutan Puanı (Çavuş → Mareşal, 10 rütbe) ve üst üste gün serisidir; oyun gücüne etkisi yoktur.
- Menü → «Hedefler ve başarımlar» ekranının üstünde görünür. Kalıcıdır (Settings: missions, xp, streak). Testler: tools/missions_test.gd, tools/missions_game_test.gd.

## Yeni içerik (senaryo motoru, Büyük Harekât, Bağımsızlık Yolu)
- **Veri güdümlü senaryolar/çağlar:** `data/scenarios/*.json`, `data/eras/*.json` (şema: `docs/DATA_SCHEMA.md`). Doğrulama: `godot --headless --path . -s tools/validate_data.gd`. 8 yeni senaryo + "Soğuk Savaş 1962" çağı (cw62). Üreticiler: `tools/data/gen_cw62.py`, `gen_scn.py`.
- **Senaryo oluşturucu:** menü → "Senaryo oluştur"; senaryolar `user://scenarios/u_*.json`, paylaşım kodu `AOD1…`.
- **Hedef motoru:** `scripts/objectives.gd` (own_provinces, own_capital, eliminate, survive, cease_war, no_war, alliances, stability, gdp_share, bloc_members).
- **Büyük Harekât:** ülke ilişkileri ekranından; pahalı, uzun bekleme süreli, olasılıkları gösterilen birleşik harekât (`scripts/grand_op.gd`).
- **Bağımsızlık Yolu:** ayrı oyun kipi (`scripts/independence*.gd`): Kıvılcım → Ayaklanma → Müzakere → Devlet Kurma → Konsolidasyon; kurgusal hareket, ideolojiye bağlı yabancı destek (şartlarıyla), karar kartları. Lansman penceresinde (2027-03-01'e kadar) açanlara "Kurucu Erişimi" kalıcı verilir; sonra ücretli.
- **Play ürün kimlikleri (ek):** `mode_indep`, `era_cw62`, `scn_<id>` (yeni 8 senaryo).
- Yeni metinlerin çevirisi şimdilik TR+EN.

## Amiral gemisi özellikleri (v2)
- **Alternatif Tarih Paketi** (`tools/data/gen_alt.py`, `data/eras/alt_*.json`): 15 "ya olsaydı" çağı (WW1: Osmanlı tarafsız [ücretsiz örnek], İngiltere savaş dışı, İtalya Merkez'de, Schlieffen başarılı, Saraybosna yok, Çar tutunur; WW2: Mihver–SSCB, Hitler suikastı, Türkiye Müttefik'te, Japonya kuzeye, Maginot aşılmaz, İspanya Mihver'de; Soğuk Savaş: Küba sıcak, Çin–SSCB bloku, Berlin sıcak). `base` ile ana çağın haritasını/olaylarını (ayrışma tarihine kadar) miras alır. Play ürünü: `era_pack_alt` (alt_ott_neutral ücretsiz).
- **Stratejik Geçitler** (`scripts/chokepoints.gd`): 9 boğaz/kanal; kontrolcü serbest/ücretli/düşmana kapalı/herkese kapalı seçer; haftalık gelir çarpanı (Macro.calc), YZ de kullanır; hedef türü `hold_choke`.
- **Günlük Meydan Okuma** (`scripts/daily.gd`, `daily_ui.gd`): her gün aynı ülke + tohum + "günün çarpıtması", 52 hafta, ilerleme tabanlı skor; günde ilk bitirişte AP + seri. Gerçek sıralama tablosu yok (ileride Play Games).
- **Siyasi sistem** (`scripts/politics.gd`): rejim türleri, seçim/darbe/halk protestosu kartları, reform eylemleri (demokratikleştir, merkezileştir, sıkıyönetim).
- **Savaş Odası** (`scripts/war_room.gd`, `war_room_ui.gd`): ≤6 aşamalı çok cepheli harekât planı, otomatik öneri, sırayla yürütme, sinematik kartlar.
- Testler: alt_test, choke_test, daily_test, pol_test, wroom_test. İkon istemleri: tools/ICON_PROMPTS_6.md (geçit/rejim/Savaş Odası/meydan okuma), ICON_PROMPTS_7.md (Bağımsızlık Yolu).
