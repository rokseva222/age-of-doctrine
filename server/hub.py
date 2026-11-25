#!/usr/bin/env python3
"""Age of Doctrine merkez sunucu (hub): ana liste + oda açıcı. Yalnızca Python standart kütüphanesi.

Oyuncular odayı KENDİ telefonunda kurmaz; bu sunucuda kurulur. Böylece herkes (mobil veri dahil) yalnızca dışarı doğru
bağlanır: port yönlendirme, UPnP, kod derdi yok.

  GET  /servers   → açık odalar (en az 1 oyuncusu olanlar)
  POST /create    {"name","era","scenario","max","pass","secs","fog","ver"} → {"ip","port"}  (oda süreci başlatır)
  GET  /saves?token=T  → bu cihazın koltuğu olan kayıtlı oyunlar (oda her tur sonunda kaydedilir)
  POST /resume    {"id","token","ver"} → kayıtlı oyunu yeniden açar (ya da açıksa adresini verir) → {"ip","port"}
  POST /delsave   {"id","token"} → kaydı siler
  POST /register, /remove  → oda süreçlerinin kendi duyurusu (yalnızca yerel makineden)
  GET  /health

Çalıştırma (kur.sh bunu systemd ile yapar):
  python3 hub.py --public-host 203.0.113.5 --godot /opt/godot/godot --project /opt/aod
"""
import argparse, json, os, re, secrets, subprocess, sys, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TTL = 90.0
MAX_BODY = 131072        # kullanıcı senaryosu kodu (sıkıştırılmış) taşıyabilsin
servers = {}            # token -> duyuru kaydı (odalar kendini bildirir)
rooms = {}              # port -> {"proc","ip","t","name"}
lock = threading.Lock()
A = None
updating = False        # güncelleme sürerken yeni oda açılmaz
SAFE = re.compile(r"^[a-z0-9_]{0,24}$")
ID_OK = re.compile(r"^[a-z0-9_]{1,40}$")          # kayıt kimliği
TOK_OK = re.compile(r"^[0-9A-Za-z]{8,32}$")        # cihaz kodu (koltuk)
SAVE_TTL = 45 * 86400                              # bu kadar gündür oynanmayan kayıt silinir
_last_purge = 0.0
CODE_OK = re.compile(r"^AOD1\.[0-9]{1,7}\.[A-Za-z0-9_\-=]{1,90000}$")   # kullanıcı senaryosu paylaşım kodu


def clean(s, n=40):
    return str(s)[:n].replace("<", " ").replace(">", " ")


def server_ver():
    try:
        t = open(os.path.join(A.project, "scripts", "info_sheets.gd"), encoding="utf-8").read()
        return re.search(r'UPDATE_VER\s*:?=\s*"([^"]+)"', t).group(1)
    except Exception:
        return ""


def save_path(i, ext):
    return os.path.join(A.savedir, i + ext)


def read_meta(i):
    try:
        with open(save_path(i, ".json"), encoding="utf-8") as fh:
            m = json.load(fh)
        return m if isinstance(m, dict) else None
    except Exception:
        return None


def delete_save_files(i):
    for ext in (".dat", ".json", ".tmp", ".json.tmp"):
        try:
            os.remove(save_path(i, ext))
        except OSError:
            pass


def purge_saves():
    """Uzun süredir oynanmayan kayıtları siler (en çok günde bir tarama gibi seyrek çalışır)."""
    global _last_purge
    now = time.time()
    if now - _last_purge < 3600:
        return
    _last_purge = now
    try:
        names = [n[:-5] for n in os.listdir(A.savedir) if n.endswith(".json")]
    except OSError:
        return
    with lock:
        live = {r.get("save") for r in rooms.values()}
    for i in names:
        m = read_meta(i)
        if m is None or (now - float(m.get("saved", 0)) > SAVE_TTL and i not in live):
            if ID_OK.match(i):
                delete_save_files(i)


def live_port(i):
    """Bu kayıt şu an açık bir odada mı? Açıksa portu döner."""
    with lock:
        for p, r in rooms.items():
            if r.get("save") == i and r["proc"].poll() is None:
                return p
        for v in servers.values():
            if v.get("save") == i and v["port"] in rooms:
                return v["port"]
    return 0


def reap():
    """Biten süreçleri ve eski duyuruları temizler."""
    purge_saves()
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
    name = clean(b.get("name", "Oda"), 24).strip().lstrip("-").strip() or "Oda"
    era = str(b.get("era", ""))
    scn = str(b.get("scenario", ""))
    if not SAFE.match(era) or not SAFE.match(scn):
        return 400, {"err": "geçersiz çağ/senaryo"}
    code = str(b.get("scn_code", ""))
    if code and not CODE_OK.match(code):
        return 400, {"err": "geçersiz senaryo kodu"}
    try:
        mx = max(2, min(12, int(b.get("max", 4))))
        secs = max(0.0, min(600.0, float(b.get("secs", 120))))
        fog = max(0, min(2, int(b.get("fog", 0))))
    except Exception:
        return 400, {"err": "geçersiz sayı"}
    pw = clean(b.get("pass", ""), 16).lstrip("-")
    sv = server_ver()
    if sv and str(b.get("ver", "")) != sv:
        return 409, {"err": "ver", "server_ver": sv}
    reap()
    with lock:
        if updating:
            return 503, {"err": "update"}
        if len(rooms) >= A.max_rooms:
            return 503, {"err": "dolu"}
        # aynı kişinin içinde kimse kalmamış eski odaları (odadan çıkınca arkada kalanlar) kapat; yeni oda kurabilsin
        now = time.time()
        for p, r in list(rooms.items()):
            if r["ip"] != ip or now - r["t"] < 20:
                continue
            live = [v for v in servers.values() if v["port"] == p]
            if live and all(v["players"] > 0 for v in live):
                continue
            try:
                r["proc"].terminate()
            except Exception:
                pass
            rooms.pop(p, None)
            for t in [t for t, v in servers.items() if v["port"] == p]:
                servers.pop(t, None)
        if sum(1 for r in rooms.values() if r["ip"] == ip) >= A.per_ip:
            return 429, {"err": "çok fazla oda"}
        port = free_port()
        if not port:
            return 503, {"err": "dolu"}
        cmd = [A.godot, "--headless", "--path", A.project, "-s", "server/dedicated.gd", "--",
               "--name", name, "--era", era, "--scn", scn, "--port", str(port), "--secs", str(secs), "--max", str(mx),
               "--fog", str(fog), "--ver", sv, "--master", "http://127.0.0.1:%d" % A.port, "--region", A.region,
               "--idle", str(A.idle), "--savedir", A.savedir]
        if pw:
            cmd += ["--pass", pw]
        if code:
            cdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scn_codes")
            os.makedirs(cdir, exist_ok=True)
            cpath = os.path.join(cdir, "%d.txt" % port)
            with open(cpath, "w") as fh:
                fh.write(code)
            cmd += ["--scnfile", cpath]
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            return 500, {"err": "başlatılamadı: %s" % e}
        rooms[port] = {"proc": proc, "ip": ip, "t": time.time(), "name": name}
    return 200, {"ip": A.public_host, "port": port}


def my_saves(token):
    out = []
    try:
        names = [n[:-5] for n in os.listdir(A.savedir) if n.endswith(".json")]
    except OSError:
        return out
    for i in names:
        m = read_meta(i)
        if not m or token not in (m.get("seats") or {}):
            continue
        out.append({"id": i, "name": clean(m.get("name", "Oda"), 24), "era": clean(m.get("era", ""), 20), "turn": int(m.get("turn", 0)),
                    "seat": clean((m.get("seats") or {}).get(token, ""), 40), "players": len(m.get("seats") or {}),
                    "saved": int(m.get("saved", 0)), "live": bool(live_port(i)), "ver": clean(m.get("ver", ""), 16)})
    out.sort(key=lambda s: -s["saved"])
    return out


def resume_room(b, ip):
    i = str(b.get("id", ""))
    tok = str(b.get("token", ""))
    if not ID_OK.match(i) or not TOK_OK.match(tok):
        return 400, {"err": "geçersiz"}
    m = read_meta(i)
    if not m or tok not in (m.get("seats") or {}):
        return 404, {"err": "kayıt yok"}
    sv = server_ver()
    if sv and str(b.get("ver", "")) != sv:
        return 409, {"err": "ver", "server_ver": sv}
    reap()
    p = live_port(i)
    if p:
        return 200, {"ip": A.public_host, "port": p}      # oda zaten açık: herkes aynı odaya girer
    with lock:
        if updating:
            return 503, {"err": "update"}
        if len(rooms) >= A.max_rooms:
            return 503, {"err": "dolu"}
        port = free_port()
        if not port:
            return 503, {"err": "dolu"}
        cmd = [A.godot, "--headless", "--path", A.project, "-s", "server/dedicated.gd", "--",
               "--resume", i, "--savedir", A.savedir, "--port", str(port), "--ver", sv,
               "--master", "http://127.0.0.1:%d" % A.port, "--region", A.region, "--idle", str(A.idle)]
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            return 500, {"err": "başlatılamadı: %s" % e}
        rooms[port] = {"proc": proc, "ip": ip, "t": time.time(), "name": clean(m.get("name", "Oda"), 24), "save": i}
    return 200, {"ip": A.public_host, "port": port}


def delete_save(b):
    i = str(b.get("id", ""))
    tok = str(b.get("token", ""))
    if not ID_OK.match(i) or not TOK_OK.match(tok):
        return 400, {"err": "geçersiz"}
    m = read_meta(i)
    if not m or tok not in (m.get("seats") or {}):
        return 404, {"err": "kayıt yok"}
    p = live_port(i)
    if p:
        with lock:
            r = rooms.pop(p, None)
        if r:
            try:
                r["proc"].terminate()
            except Exception:
                pass
    delete_save_files(i)
    return 200, {"ok": True}


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
        return self.client_address[0]      # X-Forwarded-For güvenilmez (hub doğrudan internete açık)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/health":
            reap()
            return self._send(200, {"ok": True, "rooms": len(rooms), "ver": server_ver()})
        if path == "/saves":
            q = self.path.split("?", 1)[1] if "?" in self.path else ""
            tok = ""
            for kv in q.split("&"):
                if kv.startswith("token="):
                    tok = kv[6:]
            if not TOK_OK.match(tok):
                return self._send(400, {"err": "geçersiz"})
            return self._send(200, my_saves(tok))
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
        if self.path == "/resume":
            code, obj = resume_room(b, ip)
            return self._send(code, obj)
        if self.path == "/delsave":
            code, obj = delete_save(b)
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
                                    "ver": clean(b.get("ver", ""), 16), "region": clean(b.get("region", ""), 16), "t": time.time(),
                                    "save": (str(b.get("save", "")) if ID_OK.match(str(b.get("save", ""))) else "")}
            except Exception:
                return self._send(400, {"err": "geçersiz"})
            return self._send(200, {"token": tok})
        if self.path == "/remove":
            with lock:
                servers.pop(str(b.get("token", "")), None)
            return self._send(200, {"ok": True})
        self._send(404, {"err": "yok"})


def git(*a, timeout=120):
    return subprocess.run(["git", "-C", A.project] + list(a), capture_output=True, text=True, timeout=timeout)


def updater():
    """Depoda yeni sürüm varsa (ve oda yokken) çeker; hub.py değiştiyse kendini yeniden başlatır.
    Böylece yeni uygulama sürümü yayınlanınca sunucu da birkaç dakika içinde aynı sürüme geçer."""
    global updating
    hub_file = os.path.abspath(__file__)
    try:
        h0 = open(hub_file, "rb").read()
    except Exception:
        h0 = b""
    while True:
        time.sleep(150)
        try:
            if A.no_update or not os.path.isdir(os.path.join(A.project, ".git")):
                continue
            git("fetch", "--quiet", timeout=60)
            local = git("rev-parse", "HEAD").stdout.strip()
            remote = git("rev-parse", "@{u}").stdout.strip()
            if not local or not remote or local == remote:
                continue
            reap()
            with lock:
                busy = len(rooms) > 0
                if not busy:
                    updating = True
            if busy:
                continue            # odalar boşalınca çekeriz
            print("güncelleniyor %s -> %s" % (local[:7], remote[:7]), flush=True)
            r = git("pull", "--ff-only", timeout=180)
            print(r.stdout.strip(), r.stderr.strip(), flush=True)
            if r.returncode == 0:
                try:
                    subprocess.run([A.godot, "--headless", "--path", A.project, "--import"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=600)
                except Exception as e:
                    print("içe aktarma uyarısı:", e, flush=True)
                try:
                    h1 = open(hub_file, "rb").read()
                except Exception:
                    h1 = h0
                if h1 != h0:
                    print("hub.py değişti, yeniden başlatılıyor", flush=True)
                    os.execv(sys.executable, [sys.executable] + sys.argv)
            updating = False
        except Exception as e:
            print("güncelleme hatası:", e, flush=True)
            updating = False


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
    ap.add_argument("--savedir", default="", help="oda kayıtlarının klasörü (varsayılan: server/saves)")
    ap.add_argument("--no-update", action="store_true", help="otomatik git güncellemesini kapat")
    A = ap.parse_args()
    A.port_lo, A.port_hi = [int(x) for x in A.ports.split("-")]
    if not A.savedir:
        A.savedir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "saves")
    os.makedirs(A.savedir, exist_ok=True)
    threading.Thread(target=lambda: [(reap(), time.sleep(5)) for _ in iter(int, 1)], daemon=True).start()
    threading.Thread(target=updater, daemon=True).start()
    print("hub hazır: :%d  genel adres=%s  sürüm=%s" % (A.port, A.public_host, server_ver()), flush=True)
    ThreadingHTTPServer(("0.0.0.0", A.port), H).serve_forever()


if __name__ == "__main__":
    main()
