#!/usr/bin/env python3
"""Osmanlı çağları: ott1299 (Osmanlı'nın Kuruluşu) ve ott1453 (İstanbul'un Fethi). Harita/silah/isim tablolarını tim1380'den miras alır.
Üretir: data/eras/ott1299.json, data/eras/ott1453.json (index.json'a eklenmeli)."""
import json, copy
ROOT = "/home/claude/age-of-doctrine/data/eras/"
B = json.load(open(ROOT + "tim1380.json"))
O = json.load(open("/tmp/orig_owner.json"))
G = json.load(open("/tmp/grp.json"))

def mil(p, t, a, ar, s):
    return {"personnel": p, "tank": t, "afv": a, "arty": ar, "air": 0, "sub": s}

def df(name, color, leader, gdp, m):
    return {"name": name, "color": color, "leader": leader, "gdp": gdp, "mil": m}

def rest(spl, over):
    ov = set(e[0] for e in over)
    return [e for e in spl if not (isinstance(e[0], int) and e[0] in ov)]

SEEN = set()
KEEP = set()

def mv(pids, src, dst):
    # bölünmüş eyaletin parçaları grubuyla birlikte taşınır: yalnız grup kimliği yazılır
    out = []
    for p in pids:
        g = G[str(p)]
        if g in SEEN or g in KEEP: continue
        SEEN.add(g)
        out.append([g, src if src else O[str(g)], dst, "own"])
    return out

def rng(a, b): return list(range(a, b + 1))

def base_defs(): return copy.deepcopy(B["defs"])

def ev(y, m, t, fx=None): return {"y": y, "m": m, "t": t, "fx": fx or []}
def obj(i, typ, text, **kw):
    d = {"id": i, "type": typ, "text": text}; d.update(kw); return d

LOOK = copy.deepcopy(B["look"])
ERAS = []
CAP53 = dict(B["capital"])
CAP99 = dict(B["capital"]); CAP99["Turkey"] = 426; CAP99["Montenegro"] = 428; CAP99["Azerbaijan"] = 766

# =============================================================== 1453
d = base_defs()
d["Turkey"] = df("Osmanlı Devleti", "b83a3a", "Sultan|II. Mehmed (Fatih)", 34, mil(110000, 9000, 30000, 60, 35))
d["Greece"] = df("Bizans İmparatorluğu (Son Günler)", "7a4a9a", "İmparator|XI. Konstantinos Palaiologos", 5, mil(9000, 1000, 600, 45, 22))
d["Egypt"]["leader"] = "Sultan|İnal"
d["North Macedonia"] = df("Karamanoğulları", "6a9a5a", "Bey|II. İbrahim", 5, mil(18000, 2000, 5000, 5, 5))
d["Montenegro"] = df("Anadolu Beylikleri (Candar, Dulkadir, Trabzon)", "a06a4a", "Bey|İsmail Candaroğlu", 5, mil(20000, 2000, 6000, 5, 0))
d["Serbia"] = df("Sırp Despotluğu", "7a8fb0", "Despot|Đurađ Branković", 5, mil(25000, 4000, 2000, 5, 0))
d["Hungary"]["leader"] = "Kral|V. László"
d["Poland"]["leader"] = "Kral|IV. Kazimierz"
d["Lithuania"]["leader"] = "Büyük Dük|Kazimieras"
d["Russia"]["leader"] = "Büyük Knez|II. Vasili"
d["France"]["leader"] = "Kral|VII. Charles"
d["United Kingdom"]["leader"] = "Kral|VI. Henry"
d["Germany"]["leader"] = "İmparator|III. Friedrich"
d["Spain"]["leader"] = "Kral|II. Juan"
d["Portugal"]["leader"] = "Kral|V. Afonso"
d["Italy"]["leader"] = "Doge|Francesco Foscari"
d["Denmark"]["leader"] = "Kral|I. Christian"
d["Sweden"]["leader"] = "Kral|Karl Knutsson"
d["China"]["leader"] = "İmparator|Jingtai"
d["Japan"]["leader"] = "Şogun|Ashikaga Yoshimasa"
d["South Korea"]["leader"] = "Kral|Danjong"
d["Ethiopia"]["leader"] = "Negus|Zara Yaqob"
d["Uzbekistan"]["name"] = "Timurlular (Maveraünnehir)"; d["Uzbekistan"]["leader"] = "Sultan|Ebu Said"
d["Iran"]["name"] = "Timurlular (Herat ve Horasan)"; d["Iran"]["leader"] = "Sultan|Ebu'l-Kasım Babür"
d["Azerbaijan"]["name"] = "Kara Koyunlu"; d["Azerbaijan"]["leader"] = "Sultan|Cihan Şah"
d["Kazakhstan"]["name"] = "Özbek Ulusu ve Altın Orda mirası"; d["Kazakhstan"]["leader"] = "Han|Ebu'l-Hayr"
d["India"]["name"] = "Delhi Sultanlığı (Lodiler)"; d["India"]["leader"] = "Sultan|Behlül Lodi"
d["Afghanistan"]["name"] = "Kabil ve Kandahar Beylikleri"; d["Afghanistan"]["leader"] = "Mirza|Yerel Mirzalar"
d["Myanmar"]["leader"] = "Kral|Ava Hanedanı"; d["Thailand"]["leader"] = "Kral|Ayutthaya Hanedanı"
d["Vietnam"]["leader"] = "İmparator|Le Nhan Tong"
d["Cyprus"]["leader"] = "Kral|II. Jean"
d["Bosnia and Herz."]["leader"] = "Kral|Stefan Toma"
SEEN.clear(); KEEP.clear(); KEEP.update({G["1954"], G["432"], G["435"]})
split53 = []
split53 += mv([429, 1962, 425, 433, 437, 1955, 1966, 1967], "Turkey", "Turkey")
split53 += mv(rng(1452, 1458) + rng(2518, 2527), "Bulgaria", "Turkey")
split53 += mv([1304, 1305, 1306, 1307, 1308, 1309, 2415, 2417], "Greece", "Turkey")
split53 += mv([1311, 2416, 2418, 2419], "Greece", "Italy")
split53 += mv(rng(1717, 1720) + rng(2710, 2713), "North Macedonia", "Turkey")
EV53 = [
    ev(1453, 5, "29 Mayıs: Konstantinopolis düştü. Fatih Sultan Mehmed surları top ateşiyle yardı; XI. Konstantinos son imparator olarak surlarda öldü. Bin yıllık Doğu Roma tarihe karışıyor.", [["stab", "Greece", -40], ["stab", "Turkey", 6]]),
    ev(1453, 7, "Castillon Muharebesi: Yüzyıl Savaşları sona erdi; Fransa İngilizleri kıta Avrupası'ndan kovdu.", [["stab", "France", 6], ["stab", "United Kingdom", -6]]),
    ev(1455, 8, "Gutenberg İncili basıldı: matbaa Avrupa'da hızla yayılıyor.", [["stab", "Germany", 2]]),
    ev(1456, 7, "Belgrad Kuşatması: Hunyadi János Fatih'in ordusunu Tuna kıyısında durdurdu.", [["war", "Turkey", "Hungary"], ["stab", "Turkey", -4]]),
    ev(1456, 8, "Hunyadi János salgında öldü; Macar savunması başsız kaldı.", [["stab", "Hungary", -8]]),
    ev(1459, 6, "Sırp Despotluğu'nun başkenti Smederevo düştü; Sırbistan Osmanlı eyaleti oldu.", [["war", "Turkey", "Serbia"], ["stab", "Serbia", -30]]),
    ev(1460, 5, "Mora Despotluğu fethedildi; Palaiologos hanedanı Yunanistan'dan silindi.", [["stab", "Greece", -20]]),
    ev(1461, 8, "Trabzon Rum İmparatorluğu teslim oldu; Candaroğulları da son buldu.", [["stab", "Montenegro", -25]]),
    ev(1464, 8, "Papa II. Pius haçlı seferi için Ancona'da bekliyor ama hastalanıp öldü; ordu dağıldı.", [["stab", "Italy", -4]]),
    ev(1468, 6, "Karaman Beyi II. İbrahim öldü; oğulları arasında taht kavgası Osmanlı'ya kapıyı açıyor.", [["stab", "North Macedonia", -18]]),
]
EV53_EN = [
    "29 May: Constantinople has fallen. Sultan Mehmed II broke the walls with cannon fire; Constantine XI died on the ramparts as the last emperor. A thousand years of the Eastern Roman Empire come to an end.",
    "Battle of Castillon: the Hundred Years' War is over; France has driven the English from the continent.",
    "The Gutenberg Bible is printed: the printing press spreads fast across Europe.",
    "Siege of Belgrade: John Hunyadi stops Mehmed's army on the Danube.",
    "John Hunyadi dies in an epidemic; Hungary's defence is left without a head.",
    "Smederevo, the capital of the Serbian Despotate, falls; Serbia becomes an Ottoman province.",
    "The Despotate of the Morea is conquered; the Palaiologos dynasty vanishes from Greece.",
    "The Empire of Trebizond surrenders; the Candaroğlu beylik also comes to an end.",
    "Pope Pius II waits in Ancona for a crusade but falls ill and dies; the army disperses.",
    "Karaman Bey Ibrahim II dies; a succession fight among his sons opens the door for the Ottomans.",
]
OB53 = {
    "*": [obj("o1", "survive", "İki yıl ayakta kal", turns=104), obj("o2", "alliances", "2 müttefik edin", n=2)],
    "Turkey": [obj("t1", "own_capital", "Konstantinopolis'i fethet", country="Greece"), obj("t2", "own_provinces", "Devleti büyüt: 70 eyalete ulaş", n=70, required=False),
               obj("t3", "eliminate", "Sırp Despotluğu'nu ilhak et", country="Serbia", required=False)],
    "Greece": [obj("g1", "survive", "Kuşatmaya dayan: 26 hafta ayakta kal", turns=26), obj("g2", "alliances", "Venedik veya Papalık ile ittifak kur", n=1)],
    "Hungary": [obj("h1", "alliances", "2 müttefik edin", n=2), obj("h2", "stability", "İstikrarı 50 üzerinde tut", n=50, required=False)],
    "North Macedonia": [obj("k1", "own_provinces", "Karaman'ı büyüt: 12 eyalete ulaş", n=12)],
}
OB53_EN = {"o1": "Survive two years", "o2": "Make 2 allies", "t1": "Conquer Constantinople", "t2": "Grow the state: reach 70 provinces", "t3": "Annex the Serbian Despotate",
           "g1": "Withstand the siege: stay alive for 26 weeks", "g2": "Ally with Venice or the Papacy", "h1": "Make 2 allies", "h2": "Keep stability above 50", "k1": "Expand Karaman: reach 12 provinces"}
ERAS.append({
    "id": "ott1453", "name": "İstanbul'un Fethi", "sub": "Nisan 1453 – Surların Önünde", "base": "tim1380", "family": "pre", "icon": "crown", "mood": "war",
    "start_year": 1453, "start_doy": 96,
    "blurb": "Genç Fatih Sultan Mehmed, 80 bin kişilik ordusu ve dev toplarıyla Konstantinopolis surlarının önünde. Kentte yalnızca birkaç bin savunmacı, bir de Cenevizli yardımcı kuvvetler var. Ya bin yıllık başkent düşecek, ya Osmanlı ordusu surların dibinde kalacak.",
    "suggest": ["Turkey", "Greece", "Hungary", "Italy", "North Macedonia", "Poland", "Egypt", "France"],
    "look": LOOK, "defs": d, "capital": CAP53, "split": split53 + rest(B["split"], split53),
    "setup": {"blocs": [{"name": "Konstantinopolis'in Savunması", "members": ["Greece", "Italy"],
                         "emblem": {"shape": 1, "inner": 1, "symbol": "shield", "c1": "7a4a9a", "c2": "ece6d6", "c3": "7a4a9a"}}],
              "wars": [["Turkey", "Greece"]],
              "truce": [["Turkey", "Hungary", 156], ["Turkey", "Serbia", 150], ["Egypt", "Azerbaijan", 40], ["Spain", "Portugal", 40]],
              "troops_mult": {"Turkey": 1.1},
              "intro": "Nisan 1453: Fatih Sultan Mehmed Edirne'den çıktı, Konstantinopolis'i kuşattı. Şehir iki kat sur ve zincirle kapalı Haliç'e güveniyor; ama Osmanlı topları ve donanması surların ve limanın kaderini belirleyecek."},
    "inherit_until": [1380, 1],
    "events": EV53,
    "objectives": OB53,
    "en": {"name": "The Fall of Constantinople", "sub": "April 1453 – Before the Walls",
           "blurb": "Young Sultan Mehmed II stands before the walls of Constantinople with an army of 80,000 and giant cannon. Only a few thousand defenders and some Genoese auxiliaries hold the city. Either the thousand-year capital falls, or the Ottoman army breaks itself against the walls.",
           "setup_intro": "April 1453: Sultan Mehmed II marched from Edirne and besieged Constantinople. The city trusts its double walls and the chained Golden Horn, but Ottoman cannon and fleet will decide the fate of walls and harbour.",
           "events": {str(i): t for i, t in enumerate(EV53_EN)}, "objectives": OB53_EN},
})

# =============================================================== 1299
d = base_defs()
d["Turkey"] = df("Osmanlı Beyliği", "b83a3a", "Bey|Osman Gazi", 3, mil(9000, 700, 2200, 0, 0))
d["Greece"] = df("Bizans İmparatorluğu", "7a4a9a", "İmparator|II. Andronikos Palaiologos", 8, mil(13000, 1500, 1200, 30, 25))
d["Montenegro"] = df("Batı Anadolu Beylikleri (Germiyan, Saruhan, Aydın, Karesi, Menteşe)", "a06a4a", "Bey|Yakup Germiyanoğlu", 6, mil(25000, 2500, 7000, 5, 8))
d["North Macedonia"] = df("Karamanoğulları ve Güney Beylikleri", "6a9a5a", "Bey|Mehmed Karamanoğlu", 4, mil(14000, 1500, 4000, 0, 3))
d["Azerbaijan"] = df("İlhanlı Devleti", "5a7aa0", "İlhan|Gazan Han", 40, mil(120000, 14000, 40000, 25, 0))
d["Iran"] = df("İlhanlı Horasan ve Kirman Valilikleri", "3a7a5a", "Vali|İlhanlı Emirleri", 14, mil(45000, 5000, 12000, 5, 0))
d["Uzbekistan"] = df("Çağatay Hanlığı", "d0a030", "Han|Duva", 10, mil(60000, 8000, 30000, 0, 0))
d["Kazakhstan"] = df("Altın Orda", "a8803a", "Han|Toktu", 24, mil(140000, 12000, 110000, 5, 0))
d["Kyrgyzstan"] = df("Ögedey Ulusu (Kaydu Mirası)", "8a6a4a", "Han|Kaydu", 4, mil(30000, 2000, 25000, 0, 0))
d["Mongolia"]["name"] = "Moğol Yurdu (Doğu Moğolları)"; d["Mongolia"]["leader"] = ""
d["China"] = df("Yuan Hanedanı", "c04a3a", "İmparator|Temür Kağan", d["China"]["gdp"], d["China"]["mil"])
d["Egypt"]["leader"] = "Sultan|Nasır Muhammed"
d["India"]["name"] = "Delhi Sultanlığı (Halacılar)"; d["India"]["leader"] = "Sultan|Alaeddin Halacı"
d["Hungary"]["leader"] = "Kral|III. András"; d["Poland"]["leader"] = "Kral|II. Venceslav"
d["Lithuania"]["leader"] = "Büyük Dük|Vytenis"; d["Russia"]["leader"] = "Büyük Knez|III. Andrey"
d["France"]["leader"] = "Kral|IV. Philippe"; d["United Kingdom"]["leader"] = "Kral|I. Edward"
d["Germany"]["leader"] = "Kral|I. Albrecht"; d["Spain"]["leader"] = "Kral|IV. Fernando"
d["Portugal"]["leader"] = "Kral|Dinis"; d["Italy"]["leader"] = "Doge|Pietro Gradenigo"
d["Denmark"]["leader"] = "Kral|V. Erik Menved"; d["Sweden"]["leader"] = "Kral|Birger Magnusson"
d["Japan"]["name"] = "Kamakura Şogunluğu"; d["Japan"]["leader"] = "Naip|Hojo Sadatoki"
d["South Korea"]["leader"] = "Kral|Chungnyeol"; d["Vietnam"]["leader"] = "İmparator|Trần Anh Tông"
d["Serbia"]["name"] = "Sırp Krallığı"; d["Serbia"]["leader"] = "Kral|Stefan Milutin"
d["Bulgaria"]["name"] = "Bulgar Çarlığı"; d["Bulgaria"]["leader"] = "Çar|Çaka"
d["Georgia"]["leader"] = "Kral|VIII. Davit"
d["Cyprus"]["name"] = "Kıbrıs Krallığı (Lüzinyan)"; d["Cyprus"]["leader"] = "Kral|II. Henri"
d["Romania"]["name"] = "Eflak ve Tatar Sınır Beylikleri"; d["Romania"]["leader"] = "Voyvoda|Eflak Beyleri"
d["Bosnia and Herz."]["leader"] = "Ban|Kotromanić Hanedanı"; d["Albania"]["leader"] = "Prens|Arnavut Beyleri"
d["Myanmar"]["name"] = "Myinsaing ve Pegu (Birmanya)"; d["Myanmar"]["leader"] = "Kral|Myinsaing Kardeşleri"
d["Thailand"]["name"] = "Sukhothai Krallığı"; d["Thailand"]["leader"] = "Kral|Sukhothai Hanedanı"
d["Ethiopia"]["leader"] = "Negus|Süleymanî Hanedanı"; d["Morocco"]["leader"] = "Sultan|Merînî Hanedanı"; d["Algeria"]["leader"] = "Sultan|Zeyyanî Hanedanı"; d["Tunisia"]["leader"] = "Sultan|Hafsî Hanedanı"
d["Yemen"]["leader"] = "Sultan|Resûlî Hanedanı"; d["Laos"]["leader"] = "Kral|Hanedan"; d["Cambodia"]["leader"] = "Kral|Hanedan"; d["Malaysia"]["leader"] = "Raja|Pasai Hanedanı"; d["Brunei"]["leader"] = "Sultan|Hanedan"
for k, nm in (("Bahmanî Sultanlığı", None),):
    pass
SEEN.clear(); KEEP.clear(); KEEP.update({426, 438})
split99 = []
# Batı Anadolu beylikleri
split99 += mv([428, 1961, 1959, 1958, 1960, 1970, 1968, 1962, 429], "Turkey", "Montenegro")
# Bizans Bitinya
split99 += mv([427, 1957], "Turkey", "Greece")
# İlhanlı Anadolu (iç ve doğu)
split99 += mv([431, 1956, 436, 425, 432, 433, 435, 437, 1954, 1955, 1966, 1967, 1969], "Turkey", "Azerbaijan")
EV99 = [
    ev(1299, 12, "Gazan Han Suriye'de Memlükleri yendi; Şam İlhanlıların eline geçti.", [["war", "Azerbaijan", "Egypt"], ["stab", "Egypt", -8]]),
    ev(1302, 7, "Bafeus Muharebesi: Osman Bey Bizans ordusunu ezdi; Bitinya'nın kapıları açıldı.", [["stab", "Greece", -8], ["stab", "Turkey", 10]]),
    ev(1303, 4, "Şakhab Muharebesi: Memlükler İlhanlıların Suriye ilerleyişini kesin olarak durdurdu.", [["stab", "Azerbaijan", -6], ["stab", "Egypt", 8]]),
    ev(1307, 10, "Fransa Kralı IV. Philippe Tapınak Şövalyelerini tutuklattı.", [["stab", "France", 3]]),
    ev(1308, 6, "Anadolu Selçuklu Sultanlığı fiilen sona erdi; Anadolu beylikler ve İlhanlı valileri arasında bölüşülüyor.", [["stab", "Turkey", 5]]),
    ev(1310, 8, "Hospitaller Şövalyeleri Rodos'u ele geçirdi.", [["stab", "Italy", 2]]),
    ev(1316, 1, "Delhi Sultanı Alaeddin Halacı öldü; saltanat sarsılıyor.", [["stab", "India", -12]]),
    ev(1324, 6, "Osman Gazi vefat etti; yerine oğlu Orhan Bey geçti.", [["stab", "Turkey", 4]]),
    ev(1326, 4, "Orhan Bey Bursa'yı fethetti; Osmanlı ilk büyük başkentine kavuştu.", [["war", "Turkey", "Greece"], ["stab", "Greece", -10]]),
    ev(1331, 3, "İznik teslim oldu; Bitinya'nın kalbi Osmanlı'ya geçti.", [["stab", "Greece", -10]]),
]
EV99_EN = [
    "Ghazan Khan defeats the Mamluks in Syria; Damascus falls to the Ilkhanate.",
    "Battle of Bapheus: Osman Bey crushes the Byzantine army; the gates of Bithynia open.",
    "Battle of Shaqhab: the Mamluks finally halt the Ilkhanid advance into Syria.",
    "King Philip IV of France has the Knights Templar arrested.",
    "The Seljuk Sultanate of Rum effectively ends; Anatolia is divided between beyliks and Ilkhanid governors.",
    "The Knights Hospitaller seize Rhodes.",
    "Sultan Alauddin Khalji of Delhi dies; the sultanate begins to tremble.",
    "Osman Gazi dies; his son Orhan Bey succeeds him.",
    "Orhan Bey conquers Bursa; the Ottomans gain their first great capital.",
    "Nicaea surrenders; the heart of Bithynia passes to the Ottomans.",
]
OB99 = {
    "*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156), obj("o2", "alliances", "1 müttefik edin", n=1)],
    "Turkey": [obj("t1", "own_provinces", "Beyliği büyüt: 8 eyalete ulaş", n=8), obj("t2", "own_capital", "Konstantinopolis'i fethet", country="Greece", required=False),
               obj("t3", "alliances", "2 müttefik edin", n=2, required=False)],
    "Greece": [obj("g1", "own_provinces", "Bitinya'yı elinde tut: 10 eyaleti koru", n=10)],
    "Azerbaijan": [obj("a1", "cease_war", "Memlüklerle barış yap", with_="Egypt")],
}
# cease_war alanı "with"
OB99["Azerbaijan"][0]["with"] = OB99["Azerbaijan"][0].pop("with_")
OB99_EN = {"o1": "Survive three years", "o2": "Make 1 ally", "t1": "Grow the beylik: reach 8 provinces", "t2": "Conquer Constantinople", "t3": "Make 2 allies",
           "g1": "Hold Bithynia: keep 10 provinces", "a1": "Make peace with the Mamluks"}
ERAS.append({
    "id": "ott1299", "name": "Osmanlı'nın Kuruluşu", "sub": "1299 – Söğüt'ten Bursa'ya", "base": "tim1380", "family": "pre", "icon": "crown", "mood": "war",
    "start_year": 1299, "start_doy": 150,
    "blurb": "Anadolu Selçuklu'nun çöküşünden sonra Moğol baskısı altındaki Anadolu'da küçük bir uç beyliği: Osman Bey'in Söğüt'ü. Önünde Bizans, yanında rakip beylikler, arkasında İlhanlı gölgesi var. Küçük bir sınır beyi bir cihan devleti kurabilir mi?",
    "suggest": ["Turkey", "Greece", "Azerbaijan", "Egypt", "Kazakhstan", "Montenegro", "Hungary"],
    "look": LOOK, "defs": d, "capital": CAP99, "split": split99 + rest(B["split"], split99),
    "setup": {"blocs": [], "wars": [["Azerbaijan", "Egypt"], ["Kazakhstan", "Azerbaijan"]],
              "truce": [["Turkey", "Greece", 104], ["Turkey", "Montenegro", 52], ["Turkey", "Azerbaijan", 80], ["Spain", "Portugal", 40]],
              "troops_mult": {"Turkey": 1.2}, "treasury_mult": {"Turkey": 1.5},
              "intro": "1299: Selçuklu Sultanlığı can çekişiyor, İlhanlılar Anadolu'yu valilerle yönetiyor. Söğüt'ün uç beyi Osman, ganimet ve gaza ile küçük topraklarını büyütmek istiyor; karşısında Bizans'ın Bitinya kaleleri ve komşu beyliklerin rekabeti var."},
    "inherit_until": [1380, 1],
    "events": EV99,
    "objectives": OB99,
    "en": {"name": "Rise of the Ottomans", "sub": "1299 – From Söğüt to Bursa",
           "blurb": "After the collapse of the Seljuk Sultanate of Rum, a small frontier beylik rises in Mongol-dominated Anatolia: Osman Bey's Söğüt. Byzantium lies ahead, rival beyliks on every side, the shadow of the Ilkhanate behind. Can a small border chief found a world empire?",
           "setup_intro": "1299: the Seljuk sultanate is dying and the Ilkhanate rules Anatolia through governors. Osman, frontier bey of Söğüt, wants to enlarge his small lands by raids and holy war; ahead lie the Byzantine fortresses of Bithynia and the rivalry of neighbouring beyliks.",
           "events": {str(i): t for i, t in enumerate(EV99_EN)}, "objectives": OB99_EN},
})
for e in ERAS:
    json.dump(e, open(ROOT + e["id"] + ".json", "w"), ensure_ascii=False, indent=1)
idx = json.load(open(ROOT + "index.json"))
for e in ERAS:
    if e["id"] not in idx: idx.append(e["id"])
json.dump(idx, open(ROOT + "index.json", "w"), ensure_ascii=False)
print("ok", [e["id"] for e in ERAS])
