# Age of Doctrine – Google Play yayın rehberi (Rok Games Studios, kişisel hesap)

## 0. Önce bilmen gerekenler
- **Kişisel hesap kuralı:** 13 Kasım 2023'ten sonra açılan kişisel hesaplar, yayına çıkmadan önce **kapalı testte en az 12 test kullanıcısını kesintisiz 14 gün** tutmalı, sonra Play Console'dan "üretim erişimi"ne başvurmalı. (Kaynak: Google Play Console Yardım, "Yeni kişisel hesaplar için test gereksinimleri".) Yayın tarihini bu 14 gün belirler; doğrulama biter bitmez kapalı testi başlat.
- **Hedef API seviyesi:** Bağımsız bir kaynağa göre Google Play, 31 Ağustos 2026'dan beri yeni uygulama ve güncellemelerde **Android 16 (API 36) hedeflemesini** şart koşuyor. Godot 4.3'ün Android şablonu muhtemelen bu seviyeyi hedeflemiyor. Resmî "Target API level requirements" sayfasından güncel şartı kontrol et; gerekirse **Godot'u güncelle** (API 36 hedefleyen sürüm) ve projeyi yeniden içe aktarıp test et.
- **Paket adı yayından sonra değişmez.** `export_presets.cfg` içinde şu an `com.rokgames.ageofdoctrine` (yayından sonra değişmez; farklı istiyorsan yayından ÖNCE değiştir).

## 1. İmza anahtarı (bir kez, sakla!)
```
keytool -genkeypair -v -keystore rokgames-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
- Anahtar dosyasını ve parolayı güvenli yerde yedekle; **projeye ya da zip'e koyma**.
- Play Console'da "Play Uygulama İmzalama"yı kullan (varsayılan). Bu anahtar "yükleme anahtarı" olur.

## 2. AAB üretimi (Godot)
1. Godot > Proje > **Android Derleme Şablonunu Yükle** (gradle için gerekli; Android SDK ve JDK de kurulu olmalı: Editör Ayarları > Dışa Aktar > Android).
2. Dışa Aktar > Android ön ayarı: gradle derlemesi ve **AAB** zaten seçili. Paket adını güncelle; "Release" anahtar dosyası, kullanıcı ve parolayı gir.
3. `version/code` her yüklemede artmalı (1, 2, 3…), `version/name` görünen sürümdür.
4. "Dışa Aktar" > `.aab` dosyasını üret. Mimari: yalnızca arm64 (64-bit) seçili.
5. Önce bir cihazda APK olarak dene (gradle'ı kapatıp APK ile dışa aktarabilirsin).

## 3. Play Console'da uygulama oluştur
- Uygulama adı: Age of Doctrine · Dil: Türkçe · Tür: Oyun · Ücretsiz.
- **Mağaza girişi:** `store/listing_tr.md` (isteğe bağlı `listing_en.md`).
- **Görseller:** simge `store/art/icon_512.png`, öne çıkan görsel `store/art/feature_1024x500.png`, telefon ekran görüntüleri `store/screens/` (1920×1080, en az 2, en çok 8).
- **Gizlilik politikası:** `store/privacy_policy.html` dosyasını herkese açık bir adreste yayınla (GitHub Pages ya da Google Sites gibi) ve adresi forma gir. Dosyadaki e-posta alanını doldur.

## 4. Form yanıtları (öneriler; soruları kendin doğrula)
- **Reklam var mı:** Hayır.
- **Veri güvenliği:** Veri toplanmıyor ve paylaşılmıyor (internet izni yok, hesap yok, analiz yok). Kayıtlar yalnızca cihazda.
- **Hedef kitle:** 13+ (çocuklara yönelik değil). "Aile" programına girme.
- **İçerik derecelendirme (IARC) anketi:** Şiddet: soyut savaş stratejisi, kan ve gerçekçi şiddet görüntüsü yok; kumar, uygunsuz dil, alkol/uyuşturucu yok; kullanıcılar arası etkileşim ve konum paylaşımı yok. Sonuç derecelendirmeyi anket belirler.
- **Hassas içerik notu:** Gerçek ülkeler ve devlet başkanı adları yalnızca metindir; fotoğraf yok. Terör benzeri yapılar kurgusaldır. Tarihî modlarda nefret sembolü kullanılmaz.
- **İzinler:** Uygulama hiçbir özel izin istemiyor.

## 5. Kapalı test (14 gün sayacı)
1. Test > **Kapalı test** kanalı oluştur, `.aab` yükle.
2. Test kullanıcılarını e-posta listesi ya da Google Grubu ile ekle; kullanıcılar **bağlantıdan katılıp (opt-in) uygulamayı yüklemeli**.
3. En az 12 kişiyi **14 gün boyunca kesintisiz** katılmış tut; garanti için 15–20 kişi topla. Testçiler uygulamayı gerçekten açıp oynasın; kısa geri bildirim iste.
4. 14 gün dolunca Play Console Pano'dan **üretim erişimi için başvur**; Google incelemesini bekle.
5. Onaylanınca üretim kanalına çıkar; ülkeleri ve fiyatı (ücretsiz) seç.

## 6. Yayın öncesi kontrol listesi
- [ ] Paket adı güncellendi, imza anahtarı yedeklendi
- [ ] Hedef API seviyesi güncel şartı karşılıyor
- [ ] AAB gerçek cihazda sorunsuz açılıyor (menü, yeni oyun, tur geçme, kayıt/yükleme, ses)
- [ ] Gizlilik politikası adresi çalışıyor ve e-posta dolu
- [ ] Mağaza metinleri ve görseller yüklendi
- [ ] Veri güvenliği, içerik derecelendirme, hedef kitle formları dolduruldu
- [ ] Kapalı test: 12+ kişi, 14 gün
