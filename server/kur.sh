#!/usr/bin/env bash
# Age of Doctrine merkez sunucu kurulumu (Ubuntu 22.04/24.04 veya Debian 12, root olarak).
#   sudo bash kur.sh            -> genel IP otomatik bulunur
#   sudo bash kur.sh 203.0.113.5  (ya da alan adı)
# Yaptığı: Godot 4.3 (başsız) + oyun deposu + hub servisi (systemd) + güvenlik duvarı.
# Gereken: 2 GB RAM'li bir VPS (her oda ~190 MB). Açılması gereken portlar: 8780/tcp, 47400-47499/udp.
set -euo pipefail
[ "$(id -u)" = "0" ] || { echo "root olarak çalıştır: sudo bash kur.sh"; exit 1; }

PUBLIC_HOST="${1:-$(curl -fsS https://api.ipify.org)}"
GODOT_TAG="4.3-stable"
REPO="https://github.com/rokseva222/age-of-doctrine"
MAX_ROOMS="${MAX_ROOMS:-6}"
echo ">> Genel adres: $PUBLIC_HOST"

apt-get update -y
apt-get install -y python3 git unzip curl ufw ca-certificates

if [ ! -x /opt/godot/godot ]; then
  mkdir -p /opt/godot
  curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_TAG}_linux.x86_64.zip" -o /tmp/godot.zip
  unzip -o /tmp/godot.zip -d /opt/godot
  mv /opt/godot/Godot_v${GODOT_TAG}_linux.x86_64 /opt/godot/godot
  chmod +x /opt/godot/godot
fi

if [ -d /opt/aod/.git ]; then
  git -C /opt/aod pull --ff-only
else
  git clone --depth 1 "$REPO" /opt/aod
fi
echo ">> Oyun kaynakları içe aktarılıyor (ilk seferde ~1-2 dk)..."
(cd /opt/aod && timeout 900 /opt/godot/godot --headless --path . --import >/dev/null 2>&1 || true)

cat > /etc/systemd/system/aod-hub.service <<UNIT
[Unit]
Description=Age of Doctrine merkez sunucu
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/aod/server/hub.py --public-host ${PUBLIC_HOST} --godot /opt/godot/godot --project /opt/aod --max-rooms ${MAX_ROOMS}
Restart=always
RestartSec=3
KillMode=control-group
User=root

[Install]
WantedBy=multi-user.target
UNIT

# Her gece depoyu güncelle (yeni sürüm çıkınca yeni odalar yeni kodla açılır); boşken hub'ı yeniden başlat.
cat > /etc/systemd/system/aod-update.service <<UNIT
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'cd /opt/aod && git pull --ff-only && /opt/godot/godot --headless --path . --import >/dev/null 2>&1; true'
UNIT
cat > /etc/systemd/system/aod-update.timer <<UNIT
[Timer]
OnCalendar=*-*-* 04:30:00
Persistent=true
[Install]
WantedBy=timers.target
UNIT

ufw allow OpenSSH
ufw allow 8780/tcp
ufw allow 47400:47499/udp
ufw --force enable

systemctl daemon-reload
systemctl enable --now aod-hub.service aod-update.timer
sleep 3
echo
curl -fsS http://127.0.0.1:8780/health && echo
echo
echo "=== KURULUM TAMAM ==="
echo "Hub adresi:  http://${PUBLIC_HOST}:8780"
echo "Bu adresi bana (Claude'a) söyle; oyuna ekleyip yeni sürüm çıkarayım."
echo "(Barındırma firmasının güvenlik duvarı/Security List panelinde de 8780/tcp ve 47400-47499/udp açık olmalı.)"
