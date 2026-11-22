#!/usr/bin/env python3
"""assets/flags/era_<slug>.png dosyası bulunan her bayrağı oyuna bağlar (data/era_flags.json, formables.json).
Kullanım: python3 tools/wire_flags.py   (proje kökünde)"""
import json, os, re
M = json.load(open('tools/flag_map.json'))
ef = json.load(open('data/era_flags.json'))
raw_ef = open('data/era_flags.json').read()
fm_raw = open('data/formables.json').read()
done = []
for slug, v in M.items():
    if not os.path.exists('assets/flags/era_%s.png' % slug):
        continue
    for era, key in v['uses']:
        if era == 'form':
            fd = json.loads(fm_raw)
            for x in fd:
                if x['id'] == key:
                    old = json.dumps(x['flag'], ensure_ascii=False)
                    if old in fm_raw:
                        fm_raw = fm_raw.replace(old, json.dumps('I:' + slug), 1)
        elif era in ef:
            ef[era][key] = 'I:' + slug
    done.append(slug)
json.dump(ef, open('data/era_flags.json', 'w'), ensure_ascii=False, indent=1 if raw_ef.startswith('{\n ') else None)
open('data/formables.json', 'w').write(fm_raw)
print('bağlandı:', len(done), done)
