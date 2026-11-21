#!/usr/bin/env python3
"""Age of Doctrine merkez sunucu (hub): ana liste + oda açıcı. Yalnızca Python standart kütüphanesi.

Oyuncular odayı KENDİ telefonunda kurmaz; bu sunucuda kurulur. Böylece herkes (mobil veri dahil) yalnızca dışarı doğru
bağlanır: port yönlendirme, UPnP, kod derdi yok.

  GET  /servers   → açık odalar (en az 1 oyuncusu olanlar)
  POST /create    {"name","era","scenario","max","pass","secs","fog","ver"} → {"ip","port"}  (oda süreci başlatır)
  POST /register, /remove  → oda süreçlerinin kendi duyurusu (yalnızca yerel makineden)
  GET  /health

Çalıştırma (kur.sh bunu systemd ile yapar):
  python3 hub.py --public-host 203.0.113.5 --godot /opt/godot/godot --project /opt/aod
"""
import argparse, json, os, re, secrets, subprocess, sys, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TTL = 90.0
MAX_BODY = 4096
servers = {}            # token -> duyuru kaydı (odalar kendini bildirir)
rooms = {}              # port -> {"proc","ip","t","name"}
lock = threading.Lock()
A = None
SAFE = re.compile(r"^[a-z0-9_]{0,24}$")


def clean(s, n=40):
    return str(s)[:n].replace("<", " ").replace(">", " ")


def server_ver():
    try:
        t = open(os.path.join(A.project, "scripts", "info_sheets.gd"), encoding="utf-8").read()
        return re.search(r'UPDATE_VER\s*:?=\s*"([^"]+)"', t).group(1)
    except Exception:
        return ""


def reap():
    """Biten süreçleri ve eski duyuruları temizler."""
    now = time.time()
    with lock:
        for p in [p for p, r in rooms.items() if r["proc"].poll() is not None]:
            rooms.pop(p, None)
            for t in [t for t, v in servers.items() if v["port"] == p]:
                servers.pop(t, None)
        for t in [t for t, v in servers.items() if now - v["t"] > TTL]:
            servers.pop(t, None)


def free_port():
    lo, hi = A.port_lo, A.port_hi
    for p in range(lo, hi, 2):          # port ve port+1 (ping) birlikte kullanılır
        if p not in rooms:
            return p
    return 0


def create_room(b, ip):
    name = clean(b.get("name", "Oda"), 24).strip() or "Oda"
    era = str(b.get("era", ""))
    scn = str(b.get("scenario", ""))
    if not SAFE.match(era) or not SAFE.match(scn):
        return 400, {"err": "geçersiz çağ/senaryo"}
    try:
        mx = max(2, min(12, int(b.get("max", 4))))
        secs = max(0.0, min(600.0, float(b.get("secs", 120))))
        fog = max(0, min(2, int(b.get("fog", 0))))
    except Exception:
        return 400, {"err": "geçersiz sayı"}
    pw = clean(b.get("pass", ""), 16)
    sv = server_ver()
    if sv and str(b.get("ver", "")) != sv:
        return 409, {"err": "ver", "server_ver": sv}
    reap()
    with lock:
        if len(rooms) >= A.max_rooms:
            return 503, {"err": "dolu"}
        if sum(1 for r in rooms.values() if r["ip"] == ip) >= A.per_ip:
            return 429, {"err": "çok fazla oda"}
        port = free_port()
        if not port:
            return 503, {"err": "dolu"}
        cmd = [A.godot, "--headless", "--path", A.project, "-s", "server/dedicated.gd", "--",
               "--name", name, "--era", era, "--scn", scn, "--port", str(port), "--secs", str(secs), "--max", str(mx),
               "--fog", str(fog), "--ver", sv, "--master", "http://127.0.0.1:%d" % A.port, "--region", A.region,
               "--idle", str(A.idle)]
        if pw:
            cmd += ["--pass", pw]
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            return 500, {"err": "başlatılamadı: %s" % e}
        rooms[port] = {"proc": proc, "ip": ip, "t": time.time(), "name": name}
    return 200, {"ip": A.public_host, "port": port}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, obj):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(b)

    def _body(self):
        n = int(self.headers.get("Content-Length", "0") or 0)
        if n <= 0 or n > MAX_BODY:
            return None
        try:
            return json.loads(self.rfile.read(n))
        except Exception:
            return None

    def _ip(self):
        return self.headers.get("X-Forwarded-For", self.client_address[0]).split(",")[0].strip()

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/health":
            reap()
            return self._send(200, {"ok": True, "rooms": len(rooms), "ver": server_ver()})
        if path != "/servers":
            return self._send(404, {"err": "yok"})
        reap()
        with lock:
            out = [{k: v[k] for k in ("name", "era", "players", "max", "ip", "port", "pass", "ver", "region")}
                   for v in servers.values() if v["players"] > 0]
        out.sort(key=lambda s: (-s["players"], s["name"]))
        self._send(200, out)

    def do_POST(self):
        b = self._body()
        if b is None:
            return self._send(400, {"err": "gövde"})
        ip = self._ip()
        if self.path == "/create":
            code, obj = create_room(b, ip)
            return self._send(code, obj)
        local = self.client_address[0] in ("127.0.0.1", "::1")
        if not local:
            return self._send(403, {"err": "yalnızca yerel"})
        if self.path == "/register":
            tok = str(b.get("token", ""))
            try:
                port = int(b.get("port", 0))
                if port not in rooms:
                    raise ValueError
                with lock:
                    if tok not in servers:
                        tok = secrets.token_hex(12)
                    servers[tok] = {"name": clean(b.get("name", "Oda")), "era": clean(b.get("era", ""), 20),
                                    "players": max(0, min(64, int(b.get("players", 0)))), "max": max(1, min(64, int(b.get("max", 6)))),
                                    "ip": A.public_host, "port": port, "pass": bool(b.get("pass", False)),
                                    "ver": clean(b.get("ver", ""), 16), "region": clean(b.get("region", ""), 16), "t": time.time()}
            except Exception:
                return self._send(400, {"err": "geçersiz"})
            return self._send(200, {"token": tok})
        if self.path == "/remove":
            with lock:
                servers.pop(str(b.get("token", "")), None)
            return self._send(200, {"ok": True})
        self._send(404, {"err": "yok"})


def main():
    global A
    ap = argparse.ArgumentParser()
    ap.add_argument("--public-host", required=True, help="Oyuncuların bağlanacağı genel IP/alan adı")
    ap.add_argument("--godot", default="godot")
    ap.add_argument("--project", default=".")
    ap.add_argument("--port", type=int, default=8780)
    ap.add_argument("--ports", default="47400-47499", help="oda UDP port aralığı (her oda port ve port+1 kullanır)")
    ap.add_argument("--max-rooms", type=int, default=8)
    ap.add_argument("--per-ip", type=int, default=2)
    ap.add_argument("--idle", type=int, default=600, help="oda boş kalınca kaç sn sonra kapanır")
    ap.add_argument("--region", default="TR")
    A = ap.parse_args()
    A.port_lo, A.port_hi = [int(x) for x in A.ports.split("-")]
    threading.Thread(target=lambda: [(reap(), time.sleep(5)) for _ in iter(int, 1)], daemon=True).start()
    print("hub hazır: :%d  genel adres=%s  sürüm=%s" % (A.port, A.public_host, server_ver()), flush=True)
    ThreadingHTTPServer(("0.0.0.0", A.port), H).serve_forever()


if __name__ == "__main__":
    main()
