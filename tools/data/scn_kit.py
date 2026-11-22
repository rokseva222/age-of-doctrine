"""Senaryo olay kartları için kısa yazım yardımcıları. Her metin 'TR || EN' biçiminde verilir.
Çıktı: data/scn_moments/<senaryo_id>.json  ({"moments": [...], "moments_en": {tr: en}}). Senaryoya scenarios.gd _with_moments bindirir."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from moment_kit import Kit

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")


def P(s):
    a, b = s.split(" || ")
    return (a.strip(), b.strip())


class Scn:
    def __init__(self, sid):
        self.sid = sid
        self.k = Kit()
        self.ms = []

    def o(self, label, res, fx, desc=""):
        """seçenek: label 'TR || EN', res (sonuç haberi) 'TR || EN', fx listesi, desc isteğe bağlı kısa açıklama"""
        d = desc if desc else label
        return self.k.opt(P(label), P(d), fx, P(res), False)

    def r(self, text, *opts, minor=False):
        """minor=True: yan aktör; seçeneği ne olursa olsun tarihî varsayılan etkiler de uygulanır (keep_default)"""
        if minor:
            for o in opts:
                o["keep_default"] = True
        return self.k.role(P(text), *opts)

    def m(self, id, turn, title, text, dfx, roles=None, icon="warning", scene="crisis", major=True, requires=None, forbid=None):
        t = P(title)
        self.k.title_en[t[0]] = t[1]
        self.ms.append(self.k.moment("%s_%s" % (self.sid, id), t, P(text), roles or {}, dfx, turn=turn, icon=icon, scene=scene, major=major, requires=requires, forbid=forbid))

    def save(self):
        os.makedirs(os.path.join(ROOT, "data/scn_moments"), exist_ok=True)
        with open(os.path.join(ROOT, "data/scn_moments/%s.json" % self.sid), "w", encoding="utf-8") as f:
            json.dump({"moments": self.ms, "moments_en": self.k.en}, f, ensure_ascii=False, indent=1)
            f.write("\n")
        return len(self.ms)
