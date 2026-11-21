#!/usr/bin/env python3
"""Age of Doctrine ana liste (master) sunucusu: yalnızca sunucu rehberi tutar, oyunu taşımaz.

Çalıştırma:  python3 master_server.py [port]      (varsayılan 8780)
Uç noktalar:
  POST /register   gövde JSON: {"name","era","players","max","port","pass","ver","region","token"} → {"token": ...}
                   Aynı sunucu 30 sn'de bir tekrar çağırır (heartbeat). 90 sn çağırmayan listeden düşer.
  POST /remove     {"token"}
  GET  /servers    → [{"name","era","players","max","ip","port","pass","ver","region"}, ...]
Bağımlılık yok (yalnızca Python standart kütüphanesi). Üretimde bir ters vekil (nginx/Caddy) arkasında HTTPS ile açın.
"""
import json, sys, time, secrets
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TTL = 90.0
MAX_BODY = 4096
MAX_SERVERS = 2000
PER_IP = 8
servers = {}   # token -> kayıt


def clean(s, n=40):
    return str(s)[:n].replace("<", " ").replace(">", " ")


def prune():
    now = time.time()
    for t in [t for t, v in servers.items() if now - v["t"] > TTL]:
        del servers[t]


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

    def do_GET(self):
        if self.path.split("?")[0] != "/servers":
            return self._send(404, {"err": "yok"})
        prune()
        out = [{k: v[k] for k in ("name", "era", "players", "max", "ip", "port", "pass", "ver", "region")} for v in servers.values()]
        out.sort(key=lambda s: (-s["players"], s["name"]))
        self._send(200, out)

    def do_POST(self):
        b = self._body()
        if b is None:
            return self._send(400, {"err": "gövde"})
        prune()
        ip = self.headers.get("X-Forwarded-For", self.client_address[0]).split(",")[0].strip()
        if self.path == "/register":
            tok = str(b.get("token", ""))
            if tok not in servers:
                if len(servers) >= MAX_SERVERS or sum(1 for v in servers.values() if v["ip"] == ip) >= PER_IP:
                    return self._send(429, {"err": "çok fazla sunucu"})
                tok = secrets.token_hex(12)
            try:
                port = int(b.get("port", 47320))
                if not (1024 <= port <= 65535):
                    raise ValueError
                servers[tok] = {"name": clean(b.get("name", "Sunucu")), "era": clean(b.get("era", ""), 20), "players": max(0, min(64, int(b.get("players", 0)))),
                                "max": max(1, min(64, int(b.get("max", 6)))), "ip": ip, "port": port, "pass": bool(b.get("pass", False)),
                                "ver": clean(b.get("ver", ""), 16), "region": clean(b.get("region", ""), 16), "t": time.time()}
            except Exception:
                return self._send(400, {"err": "geçersiz"})
            return self._send(200, {"token": tok})
        if self.path == "/remove":
            servers.pop(str(b.get("token", "")), None)
            return self._send(200, {"ok": True})
        self._send(404, {"err": "yok"})


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8780
    ThreadingHTTPServer(("0.0.0.0", port), H).serve_forever()
