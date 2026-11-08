#!/usr/bin/env python3
"""QA düzeltmeleri: başkentler, şehir-devleti enclave'leri, deniz bağlantıları, isim/yazım hataları. data/world.json'u yerinde yamar (id'ler sabit)."""
import json, re
W = 'data/world.json'
w = json.load(open(W))
P = w['provinces']; C = w['countries']
cn = {c['id']: c for c in C}
byname = {c['name_en']: c for c in C}
log = []

def setp(i, name=None, city=None):
    p = P[i]
    if name is not None: p['name'] = name
    if city is not None: p['city'] = city

def cap(country, pid, name=None, city=None):
    byname[country]['capital'] = pid
    setp(pid, name, city)

# --- başkentler
cap('Tanzania', 578)
setp(803, 'Ontario', 'Ottawa')
cap('Australia', 1024, 'Canberra', 'Canberra')
setp(598, 'Naypyidaw', 'Naypyidaw')
cap('Chad', 1196, "N'Djamena", "N'Djamena"); setp(984, None, 'Maroua')
setp(1290, 'Juba', 'Juba')
cap('Central African Rep.', 1596, 'Bangui', 'Bangui')
setp(1598, None, 'Ramallah')
setp(1693, 'Banjul', 'Banjul')
setp(1796, 'Nassau', 'Nassau')
setp(1792, 'Belmopan', 'Belmopan')
cap('South Africa', 564, 'Pretoria', 'Pretoria')
cap('Kazakhstan', 1121, 'Astana', 'Astana'); setp(1118, 'Akmola', 'Kokshetau')
setp(1790, None, 'Bandar Seri Begawan')
setp(1812, None, 'Tarawa'); setp(1817, None, 'Victoria'); setp(1821, None, 'Majuro'); setp(1832, None, 'Yaren')

# --- şehir-devleti / başkent enclave'leri: (çevreleyen, enclave, çevreleyen yeni ad, şehir, enclave adı, şehir, ülke)
ENC = [
    (450, 457, 'Brandenburg', 'Potsdam', 'Berlin', 'Berlin', 'Germany'),
    (447, 452, 'Niedersachsen', 'Hannover', 'Bremen', 'Bremen', None),
    (341, 343, 'Oromia', 'Adama', 'Addis Ababa', 'Addis Ababa', 'Ethiopia'),
    (881, 887, 'Selangor', 'Shah Alam', 'Kuala Lumpur', 'Kuala Lumpur', 'Malaysia'),
    (1068, 1070, 'Koulikoro', 'Koulikoro', 'Bamako', 'Bamako', 'Mali'),
    (608, 618, 'Gyeonggi', 'Suwon', 'Seul', 'Seul', 'South Korea'),
    (842, 854, 'Taşkent Vilayeti', 'Taşkent', 'Taşkent', 'Taşkent', 'Uzbekistan'),
    (1039, 1041, 'Tillabéri', 'Tillabéri', 'Niamey', 'Niamey', 'Niger'),
    (1389, 1390, 'Minsk Bölgesi', 'Maladzyechna', 'Minsk', 'Minsk', 'Belarus'),
    (1107, 1120, 'Almatı Bölgesi', 'Konaev', 'Almatı', 'Almatı', None),
    (1437, 1438, 'Vientiane Eyaleti', 'Vientiane', 'Vientiane', 'Vientiane', 'Laos'),
    (864, 865, 'Pasco', 'Cerro de Pasco', 'Lima', 'Lima', 'Peru'),
]
for s, e, sn, sc, en, ec, ctry in ENC:
    setp(s, sn, sc); setp(e, en, ec)
    if ctry: cap(ctry, e)

# --- tarihsel bir adı yanlış olan birkaç ülke/eyalet
byname['Taiwan']['name'] = 'Tayvan'
setp(251, 'Magadan', None)
setp(1518, 'Sjælland', None)
setp(905, 'Huambo', None)

# --- yazım/artefakt temizliği
FIX = {"llorin": "Ilorin", "lafia": "Lafia", "SALTA": "Salta", "Ciego de Ávila ili": "Ciego de Ávila", "Haumbo": "Huambo", "Cambi": "Jambi",
       "Ketta": "Quetta", "Chichlayo": "Chiclayo", "Safakes": "Sfax", "Bsikra": "Biskra", "Stunt Treng": "Stung Treng", "Mıkolayiv": "Mykolaiv",
       "Sanliurfa": "Şanlıurfa", "Diyarbakir": "Diyarbakır", "Agri": "Ağrı", "F.C.T.": "İslamabad", "Saidu": "Peşaver", "Northern Areas": "Gilgit-Baltistan",
       "Bükreș": "Bükreş"}
for p in P:
    for k in ('name', 'city'):
        v = p[k]
        if v in FIX: p[k] = FIX[v]
        elif v:
            v2 = v.replace('`', "'")
            v2 = re.sub(r"([A-Za-zÀ-ÿ])'(\s|$)", r"\1\2", v2)   # Rus sondaki kesme (Tyumen')
            v2 = v2.replace('ș', 'ş').replace('ț', 'ţ')
            if v2 != v: p[k] = v2

# --- başkent eyaletinin adı = şehir adı (Oppland -> Oslo gibi)
for c in C:
    p = P[c['capital']]
    if p['city'] and p['name'] != p['city']:
        p['name'] = p['city']

# --- yalnızca yön sözcüğü olan adlar: şehir adı, yoksa ülke + yön
COMP = {'Kuzey', 'Güney', 'Doğu', 'Batı', 'Merkez', 'Kuzeybatı', 'Güneybatı', 'Güneydoğu', 'Kuzeydoğu'}
for p in P:
    if p['name'] in COMP:
        if p['city'] and p['city'] != p['name']:
            p['name'] = p['city']
        else:
            p['name'] = '%s %s' % (cn[p['c']]['name'], p['name'])

# --- deniz bağlantıları (karşılıklı)
def pid(country, *names):
    for p in P:
        if cn[p['c']]['name_en'] == country and p['name'] in names:
            return p['id']
    raise SystemExit('bulunamadı: %s %s' % (country, names))
def link(a, b):
    if b not in P[a]['sea']: P[a]['sea'].append(b)
    if a not in P[b]['sea']: P[b]['sea'].append(a)
    if b in P[a]['nb']: pass
pairs = [(100, 80), (83, 67), (60, 59), (548, 546), (548, 545), (649, 648), (1337, 1334), (1518, pid('Denmark', 'Midtjylland')), (874, pid('Malaysia', 'Johor')),
         (879, pid('Malaysia', 'Johor')), (1140, pid('Netherlands', 'Amsterdam')), (1311, pid('Greece', 'Atina', 'Attiki'))]
for a, b in pairs:
    link(a, b)
json.dump(w, open(W, 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok')
