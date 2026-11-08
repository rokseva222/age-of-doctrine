#!/usr/bin/env python3
"""work/<lang>_new.tsv (idx<TAB>çeviri) -> doğrula -> tools/i18n/<lang>_extra.tsv'ye (TR anahtar<TAB>çeviri) ekle.
Kullanım: python3 tools/i18n/work/merge.py es"""
import re, sys, os
here = os.path.dirname(os.path.abspath(__file__))
lang = sys.argv[1]
todo = {}
for ln in open(os.path.join(here, "todo.tsv"), encoding="utf8"):
    p = ln.rstrip("\n").split("\t")
    todo[int(p[0])] = (p[1], p[2])
tok = lambda s: sorted(re.findall(r"%[-+0-9.]*[a-z%]|\{[a-z]+\}|\\n", s))
done, bad = {}, []
for ln in open(os.path.join(here, "%s_new.tsv" % lang), encoding="utf8"):
    ln = ln.rstrip("\n")
    if "\t" not in ln: continue
    i, t = ln.split("\t", 1)
    if not i.isdigit() or int(i) not in todo: continue
    i = int(i); tr, en = todo[i]
    if tok(t) != tok(en) and tok(t) != tok(tr):
        bad.append((i, en, t)); continue
    done[i] = t
xp = os.path.join(here, "..", "%s_extra.tsv" % lang)
have = set()
if os.path.exists(xp):
    for ln in open(xp, encoding="utf8"):
        if "\t" in ln: have.add(ln.split("\t", 1)[0])
n = 0
with open(xp, "a", encoding="utf8") as f:
    for i, t in sorted(done.items()):
        k = todo[i][0]
        if k in have: continue
        f.write("%s\t%s\n" % (k, t)); n += 1
miss = [i for i in todo if i not in done]
print(lang, "eklendi", n, "eksik", len(miss), "hatalı", len(bad))
for b in bad[:10]: print("  HATALI", b)
