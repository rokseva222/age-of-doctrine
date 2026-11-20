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

def mvg(gids, dst, src=None):
    # doğrudan grup kimliğiyle aktarım (src verilmezse bugünkü sahibi)
    out = []
    for g in gids:
        if g in SEEN: continue
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
CAP53 = dict(B["capital"]); CAP53["Azerbaijan"] = 459

# =============================================================== 1453
d = base_defs()
d["Turkey"] = df("Osmanlı Devleti", "b83a3a", "Sultan|II. Mehmed (Fatih)", 34, mil(110000, 9000, 30000, 60, 35))
d["Greece"] = df("Bizans İmparatorluğu (Son Günler)", "7a4a9a", "İmparator|XI. Konstantinos Palaiologos", 5, mil(9000, 1000, 600, 45, 22))
d["Egypt"]["leader"] = "Sultan|İnal"      # Mart 1453'te Çakmak'ın yerine geçti
d["North Macedonia"] = df("Karamanoğulları", "6a9a5a", "Bey|II. İbrahim", 5, mil(18000, 2000, 5000, 5, 5))
# Montenegro = Anadolu'daki bağımsız/yarı bağımsız beylikler: Candaroğulları (Kastamonu-Sinop), Trabzon Rum İmp., Dulkadir, Akkoyunlu (Amid)
d["Montenegro"] = df("Anadolu Beylikleri (Candar, Trabzon, Dulkadir, Ak Koyunlu)", "a06a4a", "Bey|İsmail Candaroğlu", 5, mil(20000, 2000, 6000, 5, 0))
d["Serbia"] = df("Sırp Despotluğu", "7a8fb0", "Despot|Đurađ Branković", 5, mil(25000, 4000, 2000, 5, 0))
d["Greece"]["name"] = "Bizans İmparatorluğu ve Mora Despotluğu"
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
d["South Korea"]["name"] = "Joseon Krallığı"; d["South Korea"]["leader"] = "Kral|Danjong"
d["Ethiopia"]["leader"] = "Negus|Zara Yaqob"
d["Uzbekistan"]["name"] = "Timurlular (Maveraünnehir)"; d["Uzbekistan"]["leader"] = "Sultan|Ebu Said"
d["Iran"]["name"] = "Timurlular (Herat ve Horasan)"; d["Iran"]["leader"] = "Sultan|Ebu'l-Kasım Babür"
d["Azerbaijan"]["name"] = "Kara Koyunlu"; d["Azerbaijan"]["leader"] = "Sultan|Cihan Şah"
d["Kazakhstan"]["name"] = "Özbek Ulusu ve Altın Orda mirası"; d["Kazakhstan"]["leader"] = "Han|Ebu'l-Hayr"
d["India"]["name"] = "Delhi Sultanlığı (Lodiler)"; d["India"]["leader"] = "Sultan|Behlül Lodi"
d["Afghanistan"]["name"] = "Kabil ve Kandahar Beylikleri"; d["Afghanistan"]["leader"] = "Mirza|Yerel Mirzalar"
d["Myanmar"]["leader"] = "Kral|Ava Hanedanı"; d["Thailand"]["leader"] = "Kral|Ayutthaya Hanedanı"
d["Vietnam"]["name"] = "Dai Viet (Lê)"; d["Vietnam"]["leader"] = "İmparator|Le Nhan Tong"
d["Cyprus"]["leader"] = "Kral|II. Jean"
d["Bosnia and Herz."]["name"] = "Bosna Krallığı ve Hersek"; d["Bosnia and Herz."]["leader"] = "Kral|Stefan Toma"
d["Albania"]["name"] = "Arnavut Lezhë Birliği ve Zeta"; d["Albania"]["leader"] = "Prens|İskender Bey (Gjergj Kastrioti)"
d["Romania"]["leader"] = "Voyvoda|II. Vladislav (Eflak)"
d["Georgia"]["leader"] = "Kral|VIII. Giorgi"
d["Kyrgyzstan"]["leader"] = "Han|II. Esen Buka"
d["Mongolia"]["leader"] = "Han|Esen Taişi (Oyrat)"
d["Sri Lanka"]["leader"] = "İmparator|Mallikarjuna Raya"
d["Nepal"]["leader"] = "Sultan|II. Alâeddin Ahmed Şah"
d["Bangladesh"]["leader"] = "Sultan|Nasırüddin Mahmud Şah"
d["Andorra"]["leader"] = "Kral|V. Alfonso"
d["Malta"]["name"] = "Napoli Krallığı (Aragon)"; d["Malta"]["leader"] = "Kral|I. Alfonso"
d["Belgium"]["leader"] = "Dük|İyi Philippe"
d["Morocco"]["leader"] = "Sultan|II. Abdülhak"
d["Algeria"]["leader"] = "Sultan|Abdülvâdî Hanedanı"
d["Tunisia"]["leader"] = "Sultan|Ebu Amr Osman"
d["Malaysia"]["name"] = "Malakka Sultanlığı"; d["Malaysia"]["leader"] = "Sultan|Muzaffer Şah"
d["Indonesia"]["leader"] = "Maharaja|Majapahit Hanedanı"
d["Peru"]["leader"] = "Sapa Inka|Pachacuti"; d["Mexico"]["leader"] = "Tlatoani|I. Moctezuma"
d["Mali"]["leader"] = "Mansa|Keita Hanedanı"; d["Yemen"]["leader"] = "Sultan|Resûlî Hanedanı"
SEEN.clear(); KEEP.clear(); KEEP.update({G["1954"], G["432"], G["435"]})
split53 = []
# Osmanlı: Anadolu'nun batısı/ortası, Trakya-Makedonya-Teselya-Epir, Bulgaristan, Üsküp ve Dobruca (1411'den beri Osmanlı)
split53 += mv([429, 1962, 425, 433, 437, 1955, 1966, 1967], "Turkey", "Turkey")
split53 += mv(rng(1452, 1458) + rng(2518, 2527), "Bulgaria", "Turkey")
split53 += mv([1304, 1305, 1306, 1307, 1308, 2415, 2417], "Greece", "Turkey")
split53 += mvg([1076], "Turkey")                       # Dobruca (Köstence-Tulça)
split53 += mv(rng(1717, 1720) + rng(2710, 2713), "North Macedonia", "Turkey")
split53 += mvg([1666], "Turkey")                       # Avlonya-Ergiri: 1417-1419'dan beri Osmanlı (Arvanid sancağı)
# Venedik/Ceneviz/Floransa/Hospitalierler: Girit, Kiklad-On İki Ada, Kuzey Ege (Gattilusi, Sakız) ve Atina (Acciaiuoli, Osmanlı haraçgüzarı)
split53 += mv([1311, 2416, 2418, 2419, 1309], "Greece", "Italy")
split53 += mvg([439], "Montenegro")                    # Diyarbakır: Eylül 1452'de Uzun Hasan Amid'i aldı (Akkoyunlu)
split53 += mvg([1773, 1774], "Bosnia and Herz.")       # Nikşiç, Pljevlja: Hersek (Stjepan Vukčić Kosača)
split53 += mvg([1775], "Albania")                      # Podgorica/Zeta: Lezhë Birliği ve Venedik himayesi (Crnojević)
split53 += mvg([458, 459, 472, 474], "Azerbaijan")     # Tebriz, Batı Azerbaycan, Zencan, Hamedan: Cihan Şah'ın Kara Koyunlu çekirdeği (başkent Tebriz)
split53 += mvg([1459], "Hungary")                      # Bačka-Banat: Macar Krallığı
split53 += mvg([1071, 1072, 1075, 1081], "Hungary")    # Erdel, Banat, Maramureş: Macar Krallığı
EV53 = [
    (1453, 5, "29 Mayıs: Konstantinopolis düştü. Fatih Sultan Mehmed surları top ateşiyle yardı; XI. Konstantinos son imparator olarak surlarda öldü. Bin yıllık Doğu Roma tarihe karışıyor.",
     [["stab", "Greece", -40], ["stab", "Turkey", 6]],
     "29 May: Constantinople has fallen. Sultan Mehmed II broke the walls with cannon fire; Constantine XI died on the ramparts as the last emperor. A thousand years of the Eastern Roman Empire come to an end."),
    (1453, 7, "17 Temmuz'da Castillon Muharebesi: Fransız topçusu İngiliz ordusunu bozguna uğrattı; Yüzyıl Savaşları'nın son büyük çarpışması kazanıldı.",
     [["stab", "France", 6], ["stab", "United Kingdom", -6]],
     "Battle of Castillon (17 July): French artillery routs the English army, the last great battle of the Hundred Years' War."),
    (1453, 10, "19 Ekim: Bordeaux teslim oldu; İngilizler Calais dışında kıta Avrupası'ndan atıldı ve Yüzyıl Savaşları sona erdi.",
     [["peace", "France", "United Kingdom"]],
     "19 October: Bordeaux surrenders; the English are driven from the continent except Calais and the Hundred Years' War ends."),
    (1455, 3, "Gutenberg'in 42 satırlık İncili tamamlandı: matbaa Avrupa'da hızla yayılıyor.",
     [["stab", "Germany", 2]],
     "The 42-line Gutenberg Bible is completed: the printing press spreads fast across Europe."),
    (1456, 6, "4 Haziran: Osmanlı ordusu Atina'yı aldı; Floransalı Acciaiuoli Dükalığı'nın son kalesi Akropolis 1458'de teslim olacak.",
     [["stab", "Italy", -3]],
     "4 June: the Ottoman army takes Athens; the Acropolis, last stronghold of the Florentine Acciaiuoli duchy, will surrender in 1458."),
    (1456, 7, "Belgrad Kuşatması: Hunyadi János ve Capistrano'lu Giovanni Fatih'in ordusunu Tuna kıyısında durdurdu (4-22 Temmuz).",
     [["war", "Turkey", "Hungary"], ["stab", "Turkey", -4]],
     "Siege of Belgrade: John Hunyadi and John of Capistrano stop Mehmed's army on the Danube (4-22 July)."),
    (1456, 8, "11 Ağustos: Hunyadi János kamptaki salgında öldü; Macar savunması başsız kaldı.",
     [["stab", "Hungary", -8]],
     "11 August: John Hunyadi dies in the plague that broke out in the camp; Hungary's defence is left without a head."),
    (1459, 6, "20 Haziran: Sırp Despotluğu'nun başkenti Smederevo teslim oldu; Sırbistan Osmanlı eyaleti oldu.",
     [["war", "Turkey", "Serbia"], ["stab", "Serbia", -30]],
     "20 June: Smederevo, capital of the Serbian Despotate, surrenders; Serbia becomes an Ottoman province."),
    (1460, 5, "29 Mayıs: Mistra teslim oldu; Mora Despotluğu Osmanlı'ya geçti (son kale Salmenikon 1461'de düştü). Palaiologos hanedanının son kolu İtalya'ya kaçtı.",
     [["stab", "Greece", -20]],
     "29 May: Mystras surrenders and the Despotate of the Morea passes to the Ottomans (the last fortress, Salmenikon, falls in 1461). The last Palaiologoi flee to Italy."),
    (1461, 8, "Yaz 1461: Sinop teslim olunca Candaroğulları son buldu; 15 Ağustos'ta Trabzon Rum İmparatorluğu da teslim oldu.",
     [["stab", "Montenegro", -25]],
     "Summer 1461: Sinope surrenders and the Candar beylik comes to an end; on 15 August the Empire of Trebizond surrenders too."),
    (1464, 6, "Karaman Beyi II. İbrahim öldü; oğulları arasındaki taht kavgası Osmanlı'ya kapıyı açıyor.",
     [["stab", "North Macedonia", -18]],
     "Karaman Bey Ibrahim II dies; a succession fight among his sons opens the door for the Ottomans."),
    (1464, 8, "14 Ağustos: II. Pius, haçlı ordusunu toplamaya çalıştığı Ancona'da öldü; sefer dağıldı.",
     [["stab", "Italy", -4]],
     "14 August: Pope Pius II dies at Ancona while trying to gather the crusading army; the expedition collapses."),
    (1468, 6, "Konya Osmanlı'ya katıldı: Karamanoğulları'nın merkezi elden gitti.",
     [["stab", "North Macedonia", -12]],
     "Konya is annexed by the Ottomans: the Karamanid heartland is lost."),
]
EV53_EN = [e[4] for e in EV53]
EV53 = [ev(e[0], e[1], e[2], e[3]) for e in EV53]
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
              "wars": [["Turkey", "Greece"], ["France", "United Kingdom"]],
              "truce": [["Turkey", "Hungary", 80], ["Turkey", "Serbia", 150], ["Egypt", "Azerbaijan", 40], ["Spain", "Portugal", 40]],
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
# Aydın ve Saruhan 1299'da henüz kurulmamıştı (1300-1313); Germiyan, Karesi, Menteşe, Hamid ve Eşrefoğulları vardı
d["Montenegro"] = df("Batı Anadolu Beylikleri (Germiyan, Karesi, Menteşe, Hamid)", "a06a4a", "Bey|Yakup Germiyanoğlu", 6, mil(25000, 2500, 7000, 5, 8))
d["North Macedonia"] = df("Karamanoğulları ve Kilikya Ermenileri", "6a9a5a", "Bey|Güneri Bey (Karamanoğlu)", 4, mil(14000, 1500, 4000, 0, 3))
d["Azerbaijan"] = df("İlhanlı Devleti", "5a7aa0", "İlhan|Gazan Han", 40, mil(120000, 14000, 40000, 25, 0))
d["Iran"] = df("İlhanlı Horasan ve Kirman Valilikleri", "3a7a5a", "Vali|İlhanlı Emirleri", 14, mil(45000, 5000, 12000, 5, 0))
d["Uzbekistan"] = df("Çağatay Hanlığı", "d0a030", "Han|Duva", 10, mil(60000, 8000, 30000, 0, 0))
d["Kazakhstan"] = df("Altın Orda", "a8803a", "Han|Toktu", 24, mil(140000, 12000, 110000, 5, 0))
d["Kyrgyzstan"] = df("Ögedey Ulusu (Kaydu Mirası)", "8a6a4a", "Han|Kaydu", 4, mil(30000, 2000, 25000, 0, 0))
d["Mongolia"]["name"] = "Moğol Yurdu (Doğu Moğolları)"; d["Mongolia"]["leader"] = ""
d["China"] = df("Yuan Hanedanı", "c04a3a", "İmparator|Temür Kağan", d["China"]["gdp"], d["China"]["mil"])
d["Egypt"]["leader"] = "Sultan|Nasır Muhammed"
d["India"]["name"] = "Delhi Sultanlığı (Halacılar)"; d["India"]["leader"] = "Sultan|Alâeddin Halacı"
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
d["Bosnia and Herz."]["leader"] = "Ban|Kotromanić Hanedanı"
d["Albania"]["name"] = "Anjou Arnavutluğu, Epir ve Teselya"; d["Albania"]["leader"] = "Despot|I. Thomas (Epir)"
d["Myanmar"]["name"] = "Myinsaing ve Pegu (Birmanya)"; d["Myanmar"]["leader"] = "Kral|Myinsaing Kardeşleri"
d["Thailand"]["name"] = "Sukhothai Krallığı"; d["Thailand"]["leader"] = "Kral|Sukhothai Hanedanı"
d["Ethiopia"]["leader"] = "Negus|Süleymanî Hanedanı"; d["Morocco"]["leader"] = "Sultan|Merînî Hanedanı"; d["Algeria"]["leader"] = "Sultan|Zeyyanî Hanedanı"; d["Tunisia"]["leader"] = "Sultan|Hafsî Hanedanı"
d["Yemen"]["leader"] = "Sultan|Resûlî Hanedanı"; d["Cambodia"]["leader"] = "Kral|III. Indravarman"; d["Malaysia"]["leader"] = "Raja|Pasai Hanedanı"; d["Brunei"]["leader"] = "Sultan|Hanedan"
# 1380'den kalan, 1299'da var olmayan devletler ve liderler
d["Afghanistan"]["leader"] = "Melik|Fahreddin Kart"
d["Sri Lanka"]["name"] = "Güney Hindistan Hanedanları (Pandya, Hoysala)"; d["Sri Lanka"]["leader"] = "Kral|Kulaşekara Pandya"
d["Nepal"]["name"] = "Dekkan Hanedanları (Yadava, Kakatiya)"; d["Nepal"]["leader"] = "Raja|Ramachandra Yadava"
d["Bangladesh"]["name"] = "Bengal (Lahnavti Sultanlığı)"; d["Bangladesh"]["leader"] = "Sultan|Rükneddin Keykâvus"
d["Pakistan"]["leader"] = "Emir|Sümre Hanedanı"
d["Belgium"]["name"] = "Flandre Kontluğu"; d["Belgium"]["leader"] = "Kont|Guy de Dampierre"
d["Malta"]["leader"] = "Kral|II. Carlo (Anjou)"; d["Andorra"]["leader"] = "Kral|II. Jaume"
d["Mali"]["leader"] = "Mansa|Sakura"; d["Indonesia"]["leader"] = "Maharaja|Raden Vijaya"
d["Laos"]["name"] = "Lao Müangları"; d["Laos"]["leader"] = "Kral|Yerel Hanedanlar"
SEEN.clear(); KEEP.clear()
split99 = []
# Bizans: Bitinya (Bursa) 1326'ya dek Bizans'tı; Ege kıyısı Türkmen beylikleri
split99 += mvg([427], "Greece")                       # Bursa-İznik (Bitinya), Çanakkale, Balıkesir, Kütahya
split99 += mvg([428, 429, 436], "Montenegro")         # İzmir-Manisa, Antalya-Muğla, Denizli-Isparta
# Konya: Selçuklu sultanı (III. Keykubad, İlhanlı kuklası) ve İlhanlı garnizonu; Karamanoğulları Konya'yı 1300'den sonra tuttu/yitirdi
split99 += mvg([431, 425, 432, 433, 435, 437, 434], "Azerbaijan")
split99 += mvg([458, 459, 472], "Azerbaijan")         # Tebriz, Batı Azerbaycan, Zencan: İlhanlı çekirdeği (başkent Tebriz)
# Balkanlar: Epir ve Teselya bağımsız Rum despotlukları; Atina/Mora/Girit-Ege Latin ve Venedik egemenliğinde
split99 += mvg([1304, 1307], "Albania")
split99 += mvg([1308, 1309, 1311], "Italy")
split99 += mvg([1071, 1072, 1075, 1081], "Hungary")  # Erdel, Banat, Maramureş
EV99 = [
    (1299, 9, "28 Eylül: Osman Bey İnegöl'ü kuşattı; Yarhisar gibi çevredeki Bizans kaleleri de akıncıların hedefi oldu.",
     [["stab", "Turkey", 3]],
     "28 September: Osman Bey besieges İnegöl; Byzantine forts around Yarhisar become targets for his raiders."),
    (1299, 12, "22 Aralık: Gazan Han Humus yakınında Memlükleri yendi; Şam kısa süreliğine İlhanlıların eline geçti.",
     [["war", "Azerbaijan", "Egypt"], ["stab", "Egypt", -8]],
     "22 December: Ghazan Khan defeats the Mamluks near Homs; Damascus briefly falls to the Ilkhanate."),
    (1302, 7, "27 Temmuz: Koyunhisar (Bafeus) Muharebesi: Osman Bey Bizans ordusunu ezdi; Bitinya'nın kapıları açıldı.",
     [["war", "Turkey", "Greece"], ["stab", "Greece", -8], ["stab", "Turkey", 10]],
     "27 July: Battle of Bapheus (Koyunhisar): Osman Bey crushes the Byzantine army; the gates of Bithynia open."),
    (1303, 4, "Mercüssuffer (Şakhab) Muharebesi: Memlükler İlhanlıların Suriye ilerleyişini kesin olarak durdurdu.",
     [["stab", "Azerbaijan", -6], ["stab", "Egypt", 8]],
     "Battle of Marj al-Saffar (Shaqhab): the Mamluks finally halt the Ilkhanid advance into Syria."),
    (1307, 10, "13 Ekim: Fransa Kralı IV. Philippe Tapınak Şövalyeleri'ni topluca tutuklattı.",
     [["stab", "France", 3]],
     "13 October: King Philip IV of France has the Knights Templar arrested en masse."),
    (1308, 6, "II. Mesud'un ölümüyle Anadolu Selçuklu hanedanı sona erdi; Anadolu beylikler ve İlhanlı valileri arasında bölüşülüyor.",
     [["stab", "Turkey", 5]],
     "With the death of Mesud II the Seljuk dynasty of Rum ends; Anatolia is divided between beyliks and Ilkhanid governors."),
    (1310, 8, "15 Ağustos: Hospitalier Şövalyeleri Rodos'un fethini tamamladı.",
     [["stab", "Italy", 2]],
     "15 August: the Knights Hospitaller complete their conquest of Rhodes."),
    (1316, 1, "Delhi Sultanı Alâeddin Halacı öldü; saltanat sarsılıyor.",
     [["stab", "India", -12]],
     "Sultan Alauddin Khalji of Delhi dies; the sultanate begins to tremble."),
    (1324, 6, "Osman Gazi vefat etti (kaynaklarda 1323-1326 arasında değişir); yerine oğlu Orhan Bey geçti.",
     [["stab", "Turkey", 4]],
     "Osman Gazi dies (sources give dates between 1323 and 1326); his son Orhan Bey succeeds him."),
    (1326, 4, "6 Nisan: Orhan Bey Bursa'yı fethetti; Osmanlı ilk büyük başkentine kavuştu.",
     [["war", "Turkey", "Greece"], ["stab", "Greece", -10]],
     "6 April: Orhan Bey conquers Bursa; the Ottomans gain their first great capital."),
    (1331, 3, "2 Mart: İznik teslim oldu; Bitinya'nın kalbi Osmanlı'ya geçti.",
     [["stab", "Greece", -10]],
     "2 March: Nicaea surrenders; the heart of Bithynia passes to the Ottomans."),
]
EV99_EN = [e[4] for e in EV99]
EV99 = [ev(e[0], e[1], e[2], e[3]) for e in EV99]
OB99 = {
    "*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156), obj("o2", "alliances", "1 müttefik edin", n=1)],
    "Turkey": [obj("t1", "own_provinces", "Beyliği büyüt: 8 eyalete ulaş", n=8), obj("t2", "own_capital", "Konstantinopolis'i fethet", country="Greece", required=False),
               obj("t3", "alliances", "2 müttefik edin", n=2, required=False)],
    "Greece": [obj("g1", "own_provinces", "Bizans topraklarını koru: en az 8 eyaleti elinde tut", n=8)],
    "Azerbaijan": [obj("a1", "cease_war", "Memlüklerle barış yap", with_="Egypt")],
}
# cease_war alanı "with"
OB99["Azerbaijan"][0]["with"] = OB99["Azerbaijan"][0].pop("with_")
OB99_EN = {"o1": "Survive three years", "o2": "Make 1 ally", "t1": "Grow the beylik: reach 8 provinces", "t2": "Conquer Constantinople", "t3": "Make 2 allies",
           "g1": "Defend Byzantium: hold at least 8 provinces", "a1": "Make peace with the Mamluks"}
CAP99 = dict(B["capital"]); CAP99["Turkey"] = 426; CAP99["Montenegro"] = 428; CAP99["Azerbaijan"] = 459; CAP99["North Macedonia"] = 1964
ERAS.append({
    "id": "ott1299", "name": "Osmanlı'nın Kuruluşu", "sub": "1299 – Söğüt'ten Bursa'ya", "base": "tim1380", "family": "pre", "icon": "crown", "mood": "war",
    "start_year": 1299, "start_doy": 150,
    "blurb": "Anadolu Selçuklu'nun çöküşünden sonra Moğol baskısı altındaki Anadolu'da küçük bir uç beyliği: Osman Bey'in Söğüt'ü. Önünde Bizans, yanında rakip beylikler, arkasında İlhanlı gölgesi var. Küçük bir sınır beyi bir cihan devleti kurabilir mi?",
    "suggest": ["Turkey", "Greece", "Azerbaijan", "Egypt", "Kazakhstan", "Montenegro", "Hungary"],
    "look": LOOK, "defs": d, "capital": CAP99, "split": split99 + rest(B["split"], split99),
    "setup": {"blocs": [], "wars": [["Azerbaijan", "Egypt"], ["Kazakhstan", "Azerbaijan"]],
              "truce": [["Turkey", "Greece", 104], ["Turkey", "Montenegro", 52], ["Turkey", "Azerbaijan", 80], ["Spain", "Portugal", 40]],
              "troops_mult": {"Turkey": 1.2}, "treasury_mult": {"Turkey": 1.5},
              "intro": "1299: Selçuklu Sultanı III. Alâeddin Keykubad İlhanlıların elinde bir kukla; Anadolu'yu İlhanlı valileri ve Türkmen beylikler paylaşıyor. Söğüt'ün uç beyi Osman, ganimet ve gaza ile küçük topraklarını büyütmek istiyor; karşısında Bizans'ın Bitinya kaleleri ve komşu beyliklerin rekabeti var."},
    "inherit_until": [1380, 1],
    "events": EV99,
    "objectives": OB99,
    "en": {"name": "Rise of the Ottomans", "sub": "1299 – From Söğüt to Bursa",
           "blurb": "After the collapse of the Seljuk Sultanate of Rum, a small frontier beylik rises in Mongol-dominated Anatolia: Osman Bey's Söğüt. Byzantium lies ahead, rival beyliks on every side, the shadow of the Ilkhanate behind. Can a small border chief found a world empire?",
           "setup_intro": "1299: the Seljuk Sultan Kayqubad III is a puppet of the Ilkhanate; Anatolia is shared between Ilkhanid governors and Turkmen beyliks. Osman, frontier bey of Söğüt, wants to enlarge his small lands by raids and holy war; ahead lie the Byzantine fortresses of Bithynia and the rivalry of neighbouring beyliks.",
           "events": {str(i): t for i, t in enumerate(EV99_EN)}, "objectives": OB99_EN},
})
for e in ERAS:
    json.dump(e, open(ROOT + e["id"] + ".json", "w"), ensure_ascii=False, indent=1)
idx = json.load(open(ROOT + "index.json"))
for e in ERAS:
    if e["id"] not in idx: idx.append(e["id"])
json.dump(idx, open(ROOT + "index.json", "w"), ensure_ascii=False)
print("ok", [e["id"] for e in ERAS])
