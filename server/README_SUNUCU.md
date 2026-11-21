# Age of Doctrine — Sunucu Kurulumu

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
