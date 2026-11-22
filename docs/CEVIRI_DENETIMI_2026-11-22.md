# Çeviri denetimi (2026-11-22, Play Store öncesi)

Tetikleyici: test kullanıcısı Jacob Briggs "İngilizceye geçtim ama bazı yerlerde Almancaya dönüyor" dedi. Dil kaydı ve OS-dili mantığı doğru
çalışıyor (seçim `Settings.language` ile kaydediliyor, sahne yeniden yüklenince okunuyor). Asıl neden: **çevirisi olmayan Türkçe metinler**
(ü/ö/ç/ş harfleri yüzünden Almanca sanılmış olabilir). Bulunan ve giderilenler:

- WW1, WW2, Soğuk Savaş 1962, Osmanlı 1520, Timur 1380 tarihî an kartlarının (825 metin) İngilizcesi hiç yokmuş → `data/moments/*.json` içine "en" tabloları eklendi.
  Diğer 11 dil bu kartlarda İngilizceye düşer (Türkçe değil).
- Kodda olup dil paketlerinde eksik kalan ~70 arayüz metni (bayrak amblemleri, rejim açıklamaları/eylemleri, hava filosu adı, sunucu listesi hataları vb.) 13 dilde eklendi (`tools/i18n/add_20261122.py`, `tools/i18n_merge_add.py`).
- İngilizcede Türkçe kalmış unvanlar (Padişah, Dük, Büyük Üstat, Seçmen Prens…) düzeltildi.
- `Loc.pair(tr, en)`: politika/odak/savaş odası/bağımsızlık/geçit/günlük görev tablolarında "TR yoksa EN" seçimi artık önce dil paketinden çeviri arıyor → Almanca vb. dillerde İngilizce yerine kendi dili.
- Senaryo olay kartları (14 senaryo) TR + EN tablosuyla yazıldı; doğrulayıcı (`tools/validate_data.gd`) artık moment dosyalarını da denetliyor.

Araçlar: `python3 tools/i18n_audit.py [--list-missing]` (eksik/boş/yer-tutucu/Türkçe-kalan raporu), `godot --headless -s tools/loc_check.gd` (13 dilde örnek çeviri testi).

## Bilinen kalan boşluklar (Türkçe görünmez; İngilizceye düşer)
- Tarihî an kartları, senaryo olayları, çağ/senaryo adları-açıklamaları: yalnız TR + EN (diğer 11 dil EN görür).
- `grand_op.gd` haber şablonları, `independence.gd` içindeki bazı haber cümleleri, `militias.gd` isyancı grup adları: EN.
- Lider adları Türkçe yazımla ("Çan Kay-şek", "Lukaşenko") — özel isim, çevrilmedi.
