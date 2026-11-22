#!/usr/bin/env python3
"""WW1 (1914-1923) çağına ek tarihî an kartları. data/moments/ww1.json'a ekler (yinelenen id atlanır). Çalıştır: python3 tools/data/gen_more_ww1.py"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from moment_kit import Kit

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
FILE = os.path.join(ROOT, "data/moments/%s.json" % os.environ.get("ERA", "ww1"))
k = Kit()
NEW = []

def P(s):
    a, b = s.split(" || ")
    return (a.strip(), b.strip())

def O(t, d, r, fx, keep=False):
    return k.opt(P(t), P(d), fx, P(r), keep)

def R(text, *opts):
    return k.role(P(text), *opts)

def M(id, y, m, title, text, dfx, roles, icon="warning", scene="crisis", major=True):
    t = P(title)
    NEW.append(k.moment(id, t, P(text), roles, dfx, y=y, m=m, icon=icon, scene=scene, major=major))

def save():
    d = json.load(open(FILE, encoding="utf-8"))
    have = {m["id"] for m in d["moments"]}
    add = [m for m in NEW if m["id"] not in have]
    d["moments"] += add
    d.setdefault("en", {}).update(k.en)
    d["moments"].sort(key=lambda m: (m["y"], m["m"]))
    json.dump(d, open(FILE, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    print(os.path.basename(FILE), "eklendi:", len(add), "toplam:", len(d["moments"]))
