# Age of Doctrine — Sunucu Kurulumu

## 0) Merkezi sunucu (önerilen — oyuncular hiçbir ayar yapmaz)

Odalar oyuncunun telefonunda değil, internette duran bir sunucuda açılır. Herkes yalnızca dışarı doğru bağlandığı için
mobil veri / ev modemi / port yönlendirme sorunu olmaz. Odayı kuran çıksa da oda açık kalır; boş kalınca kapanır.

1. 2 GB RAM'li bir VPS al (Ubuntu 22.04/24.04). Barındırma panelinde **8780/tcp** ve **47400-47499/udp** portlarını aç.
2. Sunucuya SSH ile bağlanıp: `curl -fsSL https://raw.githubusercontent.com/rokseva222/age-of-doctrine/main/server/kur.sh | sudo bash`
3. Betik sonunda yazdığı **Hub adresini** (`http://IP:8780`) `server/hub.json` dosyasına `{"url": "http://IP:8780"}` olarak yaz ve depoya gönder.
   Oyun bu adresi çalışırken oradan okur; **uygulamayı güncellemek gerekmez**.
4. Kontrol: `curl http://IP:8780/health` → `{"ok": true, ...}`. Günlük: `journalctl -u aod-hub -f`.

Sunucu her gece depoyu günceller; yeni sürüm yayınlayınca oyuncuların sürümüyle sunucu sürümü aynı olmalıdır
(sürüm farklıysa oyun "Sunucu sürümü X. Oyunu güncelle." der). Aynı anda en çok 6 oda (`MAX_ROOMS=8 sudo -E bash kur.sh` ile artırılır).

İki parça vardır:

1. **Oyun sunucusu** (bu klasördeki `dedicated.gd`): bir odayı tutar, turları işler.
2. **Ana liste (master) sunucusu** (`master_server.py`): yalnızca "hangi sunucular açık" rehberi. İsteğe bağlı; yoksa kodla/LAN ile katılınır.

## 1) Oyun sunucusu (bilgisayar ya da VPS)

Godot 4.3 yeterli (başsız çalışır). Oyun klasöründe:

```
godot --headless --path . -s server/dedicated.gd -- \
  --name "TR Resmi #1" --era ww1 --port 47320 --secs 120 --max 6 \
  --region EU --master https://liste.adresiniz
```

| Parametre | Anlamı |
|---|---|
| `--name` | Listede görünen ad |
| `--era` | boş = Dünya 2027; `ww1`, `ww2`, `cw62`, `ott1453` … |
| `--port` | Oyun portu (UDP). **Port+1 de (UDP) açık olmalı:** ping sorgusu için |
| `--secs` | Tur süresi (sn). `0` = herkes hazır olana kadar bekler |
| `--max` | En çok oyuncu (2–6) |
| `--pass` | Şifre (boş = herkese açık) |
| `--master` | Ana liste adresi (boş = listede görünmez; kodla katılınır) |
| `--region` | Listede görünen konum (TR, EU, US …) |
| `--upnp` | `1` yazarsan yönlendiricide UDP portu (ve port+1) otomatik açılır (evdeki PC için) |

İlk bağlanan oyuncu **kurucu** olur; ülkeler seçilince «Oyunu başlat»a basar.

Güvenlik duvarı/NAT: `--port` ve `--port+1` UDP portlarını yönlendirin. LAN'da (aynı Wi-Fi) gerekmez.

## 2) Ana liste sunucusu

```
python3 server/master_server.py 8780
```

Bağımlılık yok. İnternete açarken Caddy/nginx arkasında HTTPS kullanın. Sunucular 30 sn'de bir kendini bildirir, 90 sn bildirmeyen listeden düşer.
Oyuna adres vermek için `scripts/net_master.gd` içindeki `MASTER_URL` sabitini değiştirin.

## Telefonla oda kurmak
Oyunda Çok Oyunculu → Online → **Oda kur**. Telefon hem sunucu hem oyuncu olur; uygulama açık kalmalı. Aynı Wi-Fi'dakiler LAN listesinde görür; uzaktakiler **kodla** (ya da IP:port ile) katılır — ev modeminde port yönlendirme gerekir. Kalıcı odalar için bilgisayar/VPS önerilir.

## Sunucu listesi nasıl dolar? (üç yol)

1. **LAN**: Aynı Wi-Fi'daki odalar otomatik görünür (hiçbir kurulum gerekmez).
2. **Sabit topluluk sunucuları**: `server/servers.json` dosyasına sunucunun adresini yaz ve depoya gönder; oyun bu listeyi
   `raw.githubusercontent.com` üzerinden çeker (ana liste sunucusu olmadan çalışır). Örnek:
   `[{"name": "TR Resmi", "ip": "203.0.113.5", "port": 47320, "region": "TR", "era": ""}]`
   Oyuncu sayısı ve ping, oyun tarafından sunucudan canlı alınır.
3. **Ana liste sunucusu (dinamik)**: odaların kendiliğinden listeye düşmesi için `server/master_server.py` bir yerde çalışmalı.
   - Render.com: depoyu bağla → "New Blueprint" → `render.yaml` hazır (ücretsiz plan). Verilen `https://....onrender.com`
     adresini oyunda *Çok Oyunculu → Online* ekranının altındaki "Liste sunucusu adresi" alanına yaz
     ya da `scripts/net_master.gd` içindeki `MASTER_URL` sabitine koyup yeni sürüm çıkar.
   - Kendi sunucun: `docker build -f server/Dockerfile.master -t aod-master server && docker run -p 8780:8780 aod-master`
     (önüne Caddy/nginx ile HTTPS koy).
   - Sunucu programı `--master https://adresin --region EU` ile listeye kendini bildirir.

### Kayıtlı oyunlar

Her tur sonunda oda `server/saves/` klasörüne kaydedilir (`<kimlik>.dat` oyun durumu, `<kimlik>.json` liste özeti). Oda boş kalıp kapansa,
sunucu yeniden başlasa ya da gece güncellemesi gelse de oyun kaybolmaz: oyuncular **Online → Kayıtlı oyunlarım → Devam et** ile aynı
koltuğa (cihaz kodu) geri döner; hub odayı kayıttan yeniden açar. Kayıttan açılan odada ilk oyuncu girince diğerleri için 4 dk beklenir
(hepsi dönerse hemen başlar); dönmeyenin ülkesini yapay zekâ yönetir, geri gelince koltuğunu alır. Oyun bitince kayıt silinir; 45 gündür
oynanmayan kayıtlar da silinir. Kaydı yedeklemek için `server/saves/` klasörünü kopyalamak yeter.
