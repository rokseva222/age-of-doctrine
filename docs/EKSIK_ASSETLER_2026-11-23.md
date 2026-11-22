# Eksik asset taraması (2026-11-23)

Araç: `godot --headless --path . -s tools/asset_audit.gd` (silah ikonları; liste /tmp/missing_items.txt) + kod/veri taramaları.

## Tamam
- Modern, WW1, WW2 silah modelleri: 329/329 model özel ikonlu (x_<id>).
- Bayraklar: bugünkü 200 ülke + tüm çağlar görselli (2 istisna aşağıda). Kod ikonlarında ne png ne çizimi olan ad yok. Ses efektleri eksiksiz. Portre havuzları var.
- Gemi sınıfı rozetleri (pack 16) eklendi.

## Eksik / geliştirilebilir (öncelik sırasıyla)
1. Soğuk Savaş 1962 silahları: 52 model ortak ikon kullanıyor (46 eşlenmiş, 6 genel) — tank/uçak/denizaltı/piyade/top/zırhlı.
2. Ortaçağ/erken çağ silahları (1299/1380/1453/1520): 71 model ortak ikon (süvari, piyade, top, gemi).
3. Müzik: ortaçağ çağlarının (ott1299, tim1380, ott1453, ott1520), Çeçen savaşlarının (ch94/99) kendi parçası yok; genel barış/savaş parçası çalıyor.
4. Bayrak: `era_alt_neutral_zone.png` (alt_axis62 tarafsız bölge). Vektör çizilen: tim1380 İsviçre ve Ukrayna.
5. Çağ seçim ikonları: ch94, ch94c, ch99, ch99c, cw74 ve 15 alt_* çağı genel ikon (kask/alt_history/çıkarma) kullanıyor.
6. "Kaynak ara/İnşa" için özel `build` (çekiç) ikonu yok; coins yedeği.
7. Play Store: ekran görüntüleri 16 Kasım'dan (mal pazarı, askerlik düzeni, senaryo editörü yok); Android 13 tek renkli (monochrome) uygulama ikonu yok; tablet görüntüleri yok.
8. Yazı tipi: Çince/Japonca/Korece/Arapça/Farsça/Hintçe için sistem yazı tipine güveniyor (pakette yok); eski/özel Android cihazlarda kutucuk çıkabilir.
