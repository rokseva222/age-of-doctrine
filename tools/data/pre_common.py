# -*- coding: utf-8 -*-
"""Osmanlı Çağı (1520) ve Timur (1380) dönemleri için ortak yardımcılar: silah tabloları, doğrulama, JSON yazımı."""
import json, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
WORLD = json.load(open(os.path.join(ROOT, "data", "world.json"), encoding="utf-8"))
NAMES = {c["name_en"]: c for c in WORLD["countries"]}
PROVS = {p["id"]: p for p in WORLD["provinces"]}


def mil(pers, heavy, light, guns, ships):
    return {"personnel": pers, "tank": heavy, "afv": light, "arty": guns, "air": 0, "sub": ships}


def D(name, en, color, leader, gdp, m, flag=None):
    d = {"name": name, "color": color, "leader": leader, "gdp": gdp, "mil": m, "_en": en}
    if flag:
        d["flag"] = flag
    return d


def validate(era):
    """Dönem tanımını world.json'a karşı doğrular; kapsanmayan ülkeleri döndürür."""
    hosts = set(era["defs"].keys())
    covered = set(hosts)
    problems = []
    for h, lst in era["absorb"].items():
        if h not in NAMES:
            problems.append("host yok: " + h)
        for n in lst:
            if n not in NAMES:
                problems.append("emilen yok: " + n)
            if n in covered:
                problems.append("iki kez kapsanıyor: " + n)
            covered.add(n)
        if h not in hosts:
            problems.append("emen host için defs yok: " + h)
    for h in hosts:
        if h not in NAMES:
            problems.append("defs host yok: " + h)
    for s in era["split"]:
        pid, src, dst, kind = s
        if src not in NAMES or dst not in NAMES:
            problems.append("split ülke yok: %s" % (s,))
            continue
        if pid not in NAMES[src]["provs"]:
            problems.append("split eyalet %s %s ülkesinin değil" % (pid, src))
        if dst not in hosts:
            problems.append("split hedefi host değil: %s" % dst)
    for cn, pid in era["capital"].items():
        if cn not in hosts:
            problems.append("capital host değil: " + cn)
    # absorbe edilen ülke aynı anda split hedefi olamaz
    absorbed = {n for lst in era["absorb"].values() for n in lst}
    for s in era["split"]:
        if s[2] in absorbed or s[1] in absorbed and False:
            problems.append("split hedefi emilmiş: %s" % (s,))
    missing = [n for n in NAMES if n not in covered]
    return problems, missing


def clean_defs(defs):
    out = {}
    for k, v in defs.items():
        v = dict(v)
        v.pop("_en", None)
        out[k] = v
    return out


def write_era(era, en_extra):
    path = os.path.join(ROOT, "data", "eras", era["id"] + ".json")
    out = dict(era)
    out["defs"] = clean_defs(era["defs"])
    json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    # İngilizce arayüz: dönem devlet adları ve unvanlar i18n/en.json "exact" tablosuna eklenir
    ex = {}
    for k, v in era["defs"].items():
        ex[v["name"]] = v["_en"]
        title, _, nm = v["leader"].partition("|")
        if nm:
            ex.setdefault(title, en_extra.get("titles", {}).get(title, title))
    ex.update(en_extra.get("exact", {}))
    p = os.path.join(ROOT, "data", "i18n", "en.json")
    d = json.load(open(p, encoding="utf-8"))
    n_new = 0
    for k, v in ex.items():
        if k not in d["exact"]:
            d["exact"][k] = v
            n_new += 1
    json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    return path, n_new
