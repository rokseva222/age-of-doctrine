#!/usr/bin/env python3
"""Kıbrıs Harekâtı 1974 çağı ("Ayşe Tatile Çıkıyor"): data/eras/cw74.json + data/moments/cw74.json üretir.
cw62 (Soğuk Savaş) çağının haritasını/silah tablosunu miras alır; 1974 devletleri, liderleri ve olayları kendine aittir.
Çalıştır: python3 tools/data/gen_cw74.py"""
import json, os, copy

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
def rd(p): return json.load(open(os.path.join(ROOT, p), encoding="utf-8"))
def wr(p, d):
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write("\n")

US = "United States of America"; UK = "United Kingdom"; RU = "Russia"; TR = "Turkey"; GR = "Greece"; CY = "Cyprus"; NC = "N. Cyprus"
base = rd("data/eras/cw62.json")

# ---------------------------------------------------------------- devletler (1974)
absorb = copy.deepcopy(base["absorb"])
absorb[UK] = ["Seychelles", "Belize", "Antigua and Barb.", "Dominica", "Saint Lucia", "St. Kitts and Nevis", "St. Vin. and Gren.",
              "Solomon Is.", "Kiribati", "Tuvalu"]
absorb["Spain"] = ["W. Sahara"]
absorb["Australia"] = ["Papua New Guinea"]
absorb.pop("Pakistan", None)
absorb.pop("Jordan", None)
absorb["Israel"] = ["Palestine"]

defs = copy.deepcopy(base["defs"])
def setd(n, **kw):
    defs.setdefault(n, {}).update(kw)
setd(US, leader="Başkan|Richard Nixon", gdp=4300)
setd(RU, name="SSCB", leader="Genel Sekreter|Leonid Brejnev", gdp=2100,
     mil=dict(personnel=3700000, tank=42000, afv=40000, arty=34000, air=11000, sub=420))
setd(UK, leader="Başbakan|Harold Wilson", gdp=560)
setd("France", leader="Cumhurbaşkanı|Valéry Giscard d'Estaing", gdp=700)
setd("Germany", leader="Şansölye|Helmut Schmidt", gdp=700)
setd("China", leader="Başkan|Mao Zedong", gdp=720)
setd("Cuba", leader="Başbakan|Fidel Castro", gdp=22)
setd("Japan", leader="Başbakan|Kakuei Tanaka", gdp=1300)
setd("India", leader="Başbakan|Indira Gandhi", gdp=620)
setd("Serbia", leader="Başkan|Josip Broz Tito", gdp=190)
setd("Czechia", leader="Cumhurbaşkanı|Ludvík Svoboda", gdp=140)
setd("Poland", leader="Birinci Sekreter|Edward Gierek", gdp=210)
setd("Italy", leader="Başbakan|Mariano Rumor", gdp=560)
setd("Egypt", name="Mısır", leader="Cumhurbaşkanı|Enver Sedat", gdp=70)
setd("Liechtenstein", leader="Devlet Konseyi Başkanı|Erich Honecker", gdp=70)
setd("Brunei", leader="Devlet Başkanı|Nguyễn Văn Thiệu", gdp=8)
setd("Vietnam", leader="Genel Sekreter|Lê Duẩn", gdp=6)
setd(TR, name="Türkiye", color="c8444a", leader="Başbakan|Bülent Ecevit", gdp=85,
     mil=dict(personnel=480000, tank=2000, afv=1200, arty=3000, air=400, sub=14))
setd(GR, name="Yunanistan", color="4a88cc", leader="Cumhurbaşkanı|Fedon Gizikis", gdp=55,
     mil=dict(personnel=160000, tank=900, afv=600, arty=1500, air=330, sub=8))
setd(CY, name="Kıbrıs Cumhuriyeti", color="c09a6a", leader="Cumhurbaşkanı|Nikos Sampson", gdp=2.2,
     mil=dict(personnel=14000, tank=40, afv=60, arty=120, air=0, sub=0))
setd(NC, name="Kıbrıs Türk Yönetimi", color="b8574f", leader="Başkan|Rauf Denktaş", gdp=0.35,
     mil=dict(personnel=6000, tank=0, afv=30, arty=40, air=0, sub=0))

setup = copy.deepcopy(base["setup"])
setup["wars"] = [["Vietnam", "Brunei"]]
setup["cold"] = [[US, RU], [TR, GR]]
setup["stability"] = {CY: -14, GR: -12, TR: -3}
setup["intro"] = ("15 Temmuz 1974: Atina cuntasının desteklediği Millî Muhafız Ordusu Makarios'u devirdi, Nikos Sampson 'cumhurbaşkanı' oldu. "
                  "Garantör Türkiye, İngiltere ve Yunanistan; Ecevit hükümeti Londra'dan eli boş döndü. Adaya çıkarma kararı verilecek mi?")

leaders = {"horizon": 1978, "chain": {
    US: [[1974, 8, "Başkan|Gerald Ford"], [1977, 1, "Başkan|Jimmy Carter"]],
    RU: [],
    UK: [[1976, 4, "Başbakan|James Callaghan"]],
    "Germany": [],
    "Japan": [[1974, 12, "Başbakan|Takeo Miki"]],
    "Italy": [[1974, 11, "Başbakan|Aldo Moro"]],
    "China": [[1976, 10, "Başkan|Hua Guofeng"]],
    TR: [[1974, 11, "Başbakan|Sadi Irmak"], [1975, 4, "Başbakan|Süleyman Demirel"], [1977, 6, "Başbakan|Bülent Ecevit"]],
    GR: [[1974, 8, "Başbakan|Konstantinos Karamanlis"]],
    CY: [[1974, 8, "Cumhurbaşkanı|Glafkos Klerides"], [1974, 12, "Cumhurbaşkanı|Makarios III"], [1977, 9, "Cumhurbaşkanı|Spyros Kyprianou"]],
    "Egypt": [],
}}
leaders["chain"] = {k: v for k, v in leaders["chain"].items() if v}

# ---------------------------------------------------------------- dönem olayları: (y, m, tr, en, fx)
EV = [
 (1974, 7, "Atina'daki cunta Kıbrıs'ta 'Enosis' için Makarios'u devirdi; ada diplomatik kasırganın ortasında.",
           "Athens' junta toppled Makarios to force 'Enosis' on Cyprus; the island is at the centre of a diplomatic storm.", [["stab", CY, -4]]),
 (1974, 8, "Watergate: Nixon istifa etti, Gerald Ford ABD başkanı oldu.", "Watergate: Nixon resigned and Gerald Ford became US president.", [["stab", US, -3]]),
 (1974, 8, "Yunanistan'da cunta çöktü; Karamanlis Paris'ten dönüp hükümeti kurdu.", "The Greek junta collapsed; Karamanlis returned from Paris to form a government.", [["stab", GR, 8]]),
 (1974, 9, "Ecevit koalisyonu dağıldı: Türkiye'de hükümet krizi başladı.", "Ecevit's coalition broke up: a government crisis begins in Turkey.", [["stab", TR, -4]]),
 (1974, 9, "Etiyopya'da İmparator Haile Selassie devrildi.", "In Ethiopia, Emperor Haile Selassie was deposed.", [["stab", "Ethiopia", -12]]),
 (1974, 11, "Yunanistan'da cuntadan sonraki ilk serbest seçim: Karamanlis'in Yeni Demokrasi Partisi kazandı.", "Greece's first free election after the junta: Karamanlis's New Democracy won.", [["stab", GR, 5]]),
 (1975, 4, "Saygon düştü: Vietnam Savaşı Kuzey'in zaferiyle bitti.", "Saigon fell: the Vietnam War ended in a Northern victory.", [["peace", "Vietnam", "Brunei"], ["stab", "Brunei", -30]]),
 (1975, 4, "Lübnan'da iç savaş patlak verdi.", "Civil war broke out in Lebanon.", [["stab", "Lebanon", -15]]),
 (1975, 8, "Helsinki Nihai Senedi imzalandı: Doğu-Batı arasında sınırların dokunulmazlığı kabul edildi.", "Helsinki Final Act signed: East and West accept the inviolability of borders.", [["stab", US, 1], ["stab", RU, 1]]),
 (1975, 11, "Franco öldü; İspanya'da demokrasiye geçiş başlıyor.", "Franco died; Spain's transition to democracy begins.", [["stab", "Spain", -4]]),
 (1976, 8, "Sismik-1 krizi: Ege'de petrol arama gemisi yüzünden Türkiye ve Yunanistan yeniden savaşın eşiğinde.", "Sismik-1 crisis: a research ship in the Aegean brings Turkey and Greece close to war again.", [["stab", TR, -2], ["stab", GR, -2]]),
 (1976, 9, "Mao Zedong öldü; Çin'de iktidar mücadelesi başladı.", "Mao Zedong died; a power struggle begins in China.", [["stab", "China", -8]]),
 (1977, 6, "Ecevit seçimleri kazanıp yeniden başbakan oldu; Kıbrıs 'ulusal dava' olarak seçim kampanyasının merkezinde.", "Ecevit won the election and became prime minister again; Cyprus was at the heart of the 'national cause' campaign.", [["stab", TR, 3]]),
]
ev_tr = [{"y": y, "m": m, "t": t, "fx": fx} for y, m, t, _, fx in EV]
ev_en = {str(i): e for i, (_, _, _, e, _) in enumerate(EV)}

# ---------------------------------------------------------------- hedefler
OBJ = {
 "*": [{"id": "k1", "type": "survive", "turns": 104, "text": "İki yıl boyunca ayakta kal"},
       {"id": "k2", "type": "alliances", "n": 3, "text": "3 müttefik edin", "required": False}],
 TR: [{"id": "kt1", "type": "own_province", "province": 1747, "text": "Lefkoşa'yı ele geçir"},
      {"id": "kt2", "type": "own_province", "province": 2748, "text": "Gazimağusa (Maraş) bölgesini al", "required": False},
      {"id": "kt3", "type": "stability", "n": 50, "text": "İstikrarı 50 üzerinde tut", "required": False}],
 GR: [{"id": "kg1", "type": "cease_war", "with": TR, "text": "Türkiye ile savaşa girme (barışı koru)"},
      {"id": "kg2", "type": "stability", "n": 45, "text": "Cunta sonrası istikrarı 45 üzerine çıkar"}],
 CY: [{"id": "kc1", "type": "own_capital", "country": CY, "text": "Lefkoşa'yı elinde tut"},
      {"id": "kc2", "type": "stability", "n": 40, "text": "İstikrarı 40 üzerinde tut", "required": False}],
 NC: [{"id": "kn1", "type": "own_capital", "country": NC, "text": "Gazimağusa'yı elinde tut"},
      {"id": "kn2", "type": "own_province", "province": 1747, "text": "Lefkoşa'yı Türk bölgesine kat", "required": False}],
 UK: [{"id": "ku1", "type": "no_war", "turns": 52, "text": "52 hafta savaşa girmeden Kıbrıs'ta arabuluculuk yap"}],
 US: [{"id": "ka1", "type": "no_war", "turns": 52, "text": "NATO'nun iki üyesini savaştırmadan 52 hafta geçir"}],
 RU: [{"id": "kr1", "type": "alliances", "n": 6, "text": "6 müttefik edin"}],
}
OBJ_EN = {"k1": "Survive two years", "k2": "Make 3 allies", "kt1": "Capture Nicosia", "kt2": "Take the Famagusta (Maraş) area",
          "kt3": "Keep stability above 50", "kg1": "Stay out of war with Turkey (keep the peace)", "kg2": "Raise post-junta stability above 45",
          "kc1": "Hold Nicosia", "kc2": "Keep stability above 40", "kn1": "Hold Famagusta", "kn2": "Add Nicosia to the Turkish zone",
          "ku1": "Mediate on Cyprus for 52 weeks without going to war", "ka1": "Keep two NATO members from war for 52 weeks", "kr1": "Make 6 allies"}

era = {
 "id": "cw74", "name": "Ayşe Tatile Çıkıyor", "sub": "Temmuz 1974 – Kıbrıs Harekâtı", "base": "cw62", "family": "cold",
 "icon": "landing", "mood": "war", "start_year": 1974, "start_doy": 196,
 "blurb": "15 Temmuz 1974: Atina cuntası Kıbrıs'ta darbe yaptı, Makarios devrildi. Ecevit Londra'dan eli boş döndü; Yunanistan, İngiltere, ABD ve SSCB sahnede. Ayşe tatile çıkacak mı, ada ikiye bölünecek mi?",
 "suggest": [TR, GR, CY, UK, US, NC],
 "look": base["look"],
 "arsenal": dict(base["arsenal"], gate={}),
 "absorb": absorb, "split": base["split"], "capital": base["capital"],
 "defs": defs, "setup": setup,
 "pop_f": {"Europe": 0.88, "North America": 0.65, "Asia": 0.58, "Africa": 0.35, "South America": 0.5, "Oceania": 0.6},
 "gdp_default": 0.06,
 "nukes": [US, RU, UK, "France", "China", "India"],
 "carriers": {US: 14, UK: 1, "France": 2, RU: 0},
 "vassals": [[NC, TR]],
 "events": ev_tr, "leaders": leaders, "objectives": OBJ,
 "inherit_until": [1974, 7],
 "en": {
  "name": "Ayşe Goes on Holiday", "sub": "July 1974 – Operation Cyprus",
  "blurb": "15 July 1974: Athens' junta staged a coup on Cyprus and Makarios was overthrown. Ecevit returned from London empty-handed; Greece, Britain, the US and the USSR are on stage. Will 'Ayşe' go on holiday — and will the island be split in two?",
  "setup_intro": "15 July 1974: the National Guard, backed by the Athens junta, overthrew Makarios and Nikos Sampson became 'president'. Guarantor Turkey, Britain and Greece are on edge; Ecevit's government came back from London empty-handed. Will a landing on the island be ordered?",
  "events": ev_en, "objectives": OBJ_EN},
}
wr("data/eras/cw74.json", era)

# ---------------------------------------------------------------- tarihî anlar
EN = {}
def T(tr, en):
    EN[tr] = en
    return tr

def mk(id, y, m, title, text, roles, default_fx, icon="landing", scene="pre_landing", major=True, requires=None, forbid=None):
    d = {"id": id, "y": y, "m": m, "title": title[0], "scene": scene, "icon": icon, "text": text[0], "major": major,
         "default_fx": default_fx, "roles": roles}
    EN[title[0]] = title[1]; EN[text[0]] = text[1]
    if requires: d["requires"] = requires
    if forbid: d["forbid"] = forbid
    return d

def role(text, *options):
    EN[text[0]] = text[1]
    return {"text": text[0], "options": list(options)}

def opt(t, d, fx, r, keep=False):
    for p in (t, d, r): EN[p[0]] = p[1]
    o = {"t": t[0], "d": d[0], "fx": fx, "r": r[0]}
    if keep: o["keep_default"] = True
    return o

M = []
LAND_FX = [["war", TR, CY, "solo"], ["war", NC, CY, "solo"], ["troops", NC, 120], ["buff", TR, "att", 1.3, 10], ["xstab", TR, 10], ["rel", TR, US, -20], ["rel", TR, GR, -25],
           ["rel", TR, UK, -5], ["stab", CY, -10], ["flag", "cy74_landing"]]

M.append(mk("cy74_darbe", 1974, 7, ("Ayşe Tatile Çıkıyor", "Ayşe Goes on Holiday"),
  ("15 Temmuz 1974: Atina cuntasının desteklediği Millî Muhafız Ordusu Makarios'u devirdi; Nikos Sampson 'cumhurbaşkanı' ilan edildi. Ada Yunanistan'la birleşmenin (Enosis) eşiğinde. Zürih-Londra anlaşmalarının garantörleri Türkiye, İngiltere ve Yunanistan.",
   "15 July 1974: the National Guard, backed by Athens' junta, overthrew Makarios and Nikos Sampson was declared 'president'. The island is on the brink of union with Greece (Enosis). The guarantors of the Zurich-London agreements are Turkey, Britain and Greece."),
  {
   TR: role(("Ecevit Londra'dan eli boş döndü: İngiltere ortak müdahaleyi reddetti. Garantörlük hakkın Zürih ve Londra anlaşmalarından geliyor. Ordu Mersin'de hazır, donanma limanda; Genelkurmay 'Ayşe' kod adlı çıkarma planını masaya koydu.",
                 "Ecevit came back from London empty-handed: Britain refused a joint intervention. Your guarantor right comes from the Zurich and London agreements. The army is ready at Mersin, the fleet in port; the General Staff has tabled the landing plan code-named 'Ayşe'."),
      opt(("Ayşe tatile çıksın (tarihî)", "Let Ayşe go on holiday (historical)"), ("Girne'ye çıkarma; Kıbrıs'la savaş", "Landing at Kyrenia; war with Cyprus"), LAND_FX,
          ("20 Temmuz sabahı Türk birlikleri Girne açıklarında; Kıbrıs Barış Harekâtı başladı.", "On the morning of 20 July Turkish forces are off Kyrenia; the Cyprus Peace Operation has begun.")),
      opt(("Son bir diplomasi turu", "One last round of diplomacy"), ("Cenevre görüşmeleri; savaş ilanı yok", "Geneva talks; no declaration of war"),
          [["rel", TR, UK, 15], ["rel", TR, GR, -10], ["xstab", TR, -2], ["flag", "cy74_diplo"]],
          ("Ankara Londra ve Washington'ın arabuluculuğunu bekliyor; adada çatışmalar sürüyor.", "Ankara waits for London and Washington to mediate; fighting continues on the island.")),
      opt(("Bekle", "Wait"), ("Darbe kendiliğinden çökene kadar", "Until the coup collapses on its own"),
          [["xstab", TR, -8], ["stab", CY, -8], ["flag", "cy74_diplo"]],
          ("Ankara bekledi; adada Türk köylerine yönelik saldırı haberleri ülkede öfke yarattı.", "Ankara waited; reports of attacks on Turkish villages on the island caused anger at home."))),
   GR: role(("Cunta darbeyi kendi eliyle yaptı; Türk çıkarması kapıda ve Yunan ordusu Türkiye ile savaşa hazır değil. Cunta lideri İoannidis'in ayakta kalma şansı azalıyor.",
             "The junta staged the coup itself; a Turkish landing is at the door and the Greek army is not ready for war with Turkey. Junta leader Ioannidis's hold on power is slipping."),
      opt(("Cunta düşsün, Karamanlis dönsün", "Let the junta fall, bring back Karamanlis"), ("Demokrasiye dönüş", "Return to democracy"),
          [["xstab", GR, 15], ["peace", GR, TR], ["rel", GR, US, 10], ["flag", "cy74_karamanlis"]],
          ("Cunta çöktü; Karamanlis Paris'ten Atina'ya döndü.", "The junta collapsed; Karamanlis flew back from Paris to Athens.")),
      opt(("Seferberlik ve Ege'de savaş", "Mobilise and go to war in the Aegean"), ("Türkiye'ye savaş ilan et", "Declare war on Turkey"),
          [["war", GR, TR], ["mob", GR, 8], ["buff", GR, "def", 1.1, 13], ["xstab", GR, -10]],
          ("Yunanistan seferberlik ilan etti; Ege'de savaş rüzgârı esiyor.", "Greece declared mobilisation; the winds of war blow over the Aegean.")),
      opt(("Kıbrıs'a takviye gönder", "Reinforce Cyprus"), ("Enosis'te ısrar", "Insist on Enosis"),
          [["troops", CY, 30], ["rel", GR, TR, -20], ["xstab", GR, -3]],
          ("Atina adaya gizlice takviye gönderiyor; Ankara'da gerilim tırmanıyor.", "Athens secretly sends reinforcements; tension rises in Ankara."))),
   CY: role(("Millî Muhafız Ordusu iktidarı aldı ama Makarios yaşıyor ve Londra'da. Türk çıkarması her an gelebilir; Türk Kıbrıslılar kuzey ve Lefkoşa'daki mahallelerde tehdit altında.",
             "The National Guard has seized power but Makarios is alive and in London. A Turkish landing may come any moment; Turkish Cypriots in the north and the Nicosia quarters are under threat."),
      opt(("Savunmayı örgütle", "Organise the defence"), ("Girne-Lefkoşa hattı", "The Kyrenia–Nicosia line"),
          [["troops", CY, 40], ["buff", CY, "def", 1.2, 10], ["xstab", CY, -3]],
          ("Millî Muhafız birlikleri Girne dağlarında mevzilendi.", "National Guard units dug in on the Kyrenia range.")),
      opt(("BM Güvenlik Konseyi'ne başvur", "Appeal to the UN Security Council"), ("Uluslararası baskı çağır", "Call for international pressure"),
          [["rel", CY, US, 10], ["rel", CY, RU, 10], ["stab", CY, -3]],
          ("Güvenlik Konseyi olağanüstü toplandı; Moskova ve Washington adanın birliğinden yana.", "The Security Council met in emergency session; Moscow and Washington back the island's unity.")),
      opt(("Türk Kıbrıslılarla uzlaş", "Reach out to the Turkish Cypriots"), ("Gerilimi düşür", "Lower the tension"),
          [["stab", CY, 5], ["rel", CY, NC, 20], ["rel", CY, TR, 8]],
          ("Lefkoşa'da Türk mahallelerine güvence verildi; gerilim bir an düştü.", "Assurances were given to the Turkish quarters in Nicosia; tension eased for a moment."))),
   UK: role(("Garantör sensin ama Wilson hükümeti ortak müdahaleyi reddetti; Akrotiri ve Dhekelia'daki Egemen Üsler'in güvenliği öncelik. Washington Londra'dan arabuluculuk bekliyor.",
             "You are a guarantor but Wilson's government refused a joint intervention; the safety of the Sovereign Base Areas at Akrotiri and Dhekelia comes first. Washington expects London to mediate."),
      opt(("Cenevre'de arabuluculuk", "Mediate in Geneva"), ("Üç garantör konferansı", "Conference of the three guarantors"),
          [["rel", UK, TR, 5], ["rel", UK, GR, 5], ["xstab", UK, 2]],
          ("Dışişleri Bakanı Callaghan Cenevre'de üç garantörü bir araya getirmeye çalışıyor.", "Foreign Secretary Callaghan tries to bring the three guarantors together in Geneva.")),
      opt(("Türkiye ile ortak müdahale", "Join Turkey in an intervention"), ("Garantörlüğü kullan", "Use the guarantor right"),
          [["ally", UK, TR], ["war", UK, CY, "solo"], ["xstab", UK, -4], ["rel", UK, GR, -20]],
          ("Londra ve Ankara ortak müdahale kararı aldı; NATO şokta.", "London and Ankara agreed a joint intervention; NATO is in shock.")),
      opt(("Egemen Üslere çekil", "Fall back to the Sovereign Bases"), ("Tarafsız kal", "Stay neutral"),
          [["xstab", UK, 1], ["rel", UK, TR, -5]],
          ("İngiliz birlikleri üslere çekildi; Ankara'da Londra'ya tepki büyüyor.", "British troops withdrew to their bases; resentment of London grows in Ankara."))),
   US: role(("Kissinger: NATO'nun iki üyesi savaşın eşiğinde, Soğuk Savaş'ın güney kanadı çöküyor. Watergate yüzünden Beyaz Saray zayıf; Kongre Türkiye'ye silah ambargosu için hazırlanıyor.",
             "Kissinger: two NATO members are on the verge of war and the southern flank of the Cold War is crumbling. The White House is weak because of Watergate; Congress is preparing an arms embargo on Turkey."),
      opt(("Türkiye'ye baskı: ambargo tehdidi", "Pressure Turkey: threaten an embargo"), ("Silah yardımını kes", "Cut arms aid"),
          [["rel", US, TR, -25], ["rel", US, GR, 10], ["xstab", US, 1]],
          ("Washington Ankara'ya silah yardımını keseceğini bildirdi.", "Washington told Ankara it would cut off arms aid.")),
      opt(("Sessiz diplomasi", "Quiet diplomacy"), ("Arabuluculuğu İngiltere'ye bırak", "Leave mediation to Britain"),
          [["rel", US, UK, 5], ["rel", US, TR, 3]],
          ("Kissinger telefon diplomasisiyle iki başkent arasında mekik dokuyor.", "Kissinger shuttles between the two capitals by telephone.")),
      opt(("Cuntaya destek: Enosis'e göz yum", "Back the junta: tolerate Enosis"), ("Güney kanadı sabitle", "Stabilise the southern flank"),
          [["rel", US, GR, 15], ["rel", US, TR, -20], ["stab", GR, 4]],
          ("Washington Atina cuntasına dokunmadı; Ankara'da Amerikan karşıtlığı yükseliyor.", "Washington left the Athens junta alone; anti-American feeling rises in Ankara."))),
   RU: role(("Moskova adanın bağlantısız kalmasından yana; NATO'nun Doğu Akdeniz'e yerleşmesinden çekiniyor. Makarios'un Sovyet dostluğu eski bir dosya.",
             "Moscow favours a non-aligned island and fears NATO settling the Eastern Mediterranean. Makarios's friendship with the Soviets is a long-standing file."),
      opt(("Makarios'u destekle", "Support Makarios"), ("BM'de bağımsızlık savunusu", "Defend independence at the UN"),
          [["rel", RU, CY, 25], ["rel", RU, TR, -5], ["rel", RU, GR, -5]],
          ("Moskova Kıbrıs'ın bağımsızlığını savunan sert bir bildiri yayımladı.", "Moscow issued a sharp statement defending Cyprus's independence.")),
      opt(("Türkiye ile yakınlaş", "Court Turkey"), ("Ankara'yı Washington'dan uzaklaştır", "Pull Ankara away from Washington"),
          [["rel", RU, TR, 20], ["rel", RU, US, -3]],
          ("Kremlin Ankara'ya ekonomik işbirliği teklif etti.", "The Kremlin offered Ankara economic cooperation.")),
      opt(("İzle", "Watch"), ("Müdahale etme", "Do not intervene"), [["xstab", RU, 1]], ("Moskova gelişmeleri uzaktan izliyor.", "Moscow watches from a distance.")),
   )},
  [["war", TR, CY, "solo"], ["war", NC, CY, "solo"], ["troops", NC, 300], ["rel", TR, US, -15], ["rel", TR, GR, -20], ["stab", CY, -10], ["stab", GR, -4], ["flag", "cy74_landing"]]))

M.append(mk("cy74_gec", 1974, 8, ("Sabır Tükendi", "Patience Runs Out"),
  ("Diplomasi sonuç vermedi; adada Türk mahallelerine baskılar sürüyor. Ankara'da 'şimdi ya da hiç' sesleri yükseldi.",
   "Diplomacy led nowhere; pressure on Turkish quarters continues on the island. In Ankara the cry is 'now or never'."),
  {TR: role(("Müzakere yolu kapanıyor. Ordunun hazırlığı sürüyor; ama ABD ve Britanya baskısı da artıyor.",
             "The negotiation path is closing. The army's preparations continue, but pressure from the US and Britain is rising too."),
      opt(("Şimdi çıkarma", "Land now"), ("Girne'ye çıkarma", "Landing at Kyrenia"), LAND_FX,
          ("Türk birlikleri geç kalmış bir çıkarmayla Girne'de karaya çıktı.", "Turkish forces went ashore at Kyrenia in a delayed landing.")),
      opt(("Müzakereye devam", "Keep negotiating"), ("Çıkarma yok", "No landing"), [["xstab", TR, -5], ["rel", TR, US, 5]],
          ("Ankara müzakere masasında kalıyor; kamuoyunda hoşnutsuzluk büyüyor.", "Ankara stays at the table; public discontent grows.")))},
  [["war", TR, CY, "solo"], ["war", NC, CY, "solo"], ["troops", NC, 300], ["rel", TR, US, -10], ["stab", CY, -8], ["flag", "cy74_landing"]],
  requires=["cy74_diplo"], forbid=["cy74_landing"]))

M.append(mk("cy74_cenevre", 1974, 8, ("Cenevre Çöktü: İkinci Harekât", "Geneva Collapses: the Second Operation"),
  ("Cenevre'de iki turlu görüşme çöktü. Türk birlikleri kıyı şeridinde tutunmuş, Türkiye ikinci aşamaya hazır. Yunanistan'da Karamanlis hükümeti NATO'nun askerî kanadından çekilmeyi tartışıyor.",
   "Two rounds of talks in Geneva collapsed. Turkish forces hold a coastal bridgehead and Turkey is ready for a second phase. In Greece Karamanlis's government is debating leaving NATO's military wing."),
  {TR: role(("Cenevre'de federasyon önerin reddedildi; Rum yönetimi Türk bölgesinde kalan kasabalarda baskıyı artırdı. Ordu ikinci aşama için emir bekliyor.",
             "Your federation proposal was rejected in Geneva; the Greek-Cypriot side stepped up pressure on remaining Turkish towns. The army awaits orders for a second phase."),
      opt(("İkinci harekât: Gazimağusa'ya kadar", "Second operation: push to Famagusta"), ("Adanın yaklaşık %36'sı", "About 36% of the island"),
          [["buff", TR, "att", 1.25, 6], ["xstab", TR, 5], ["rel", TR, US, -10], ["rel", TR, UK, -5], ["rel", TR, GR, -10], ["flag", "cy74_phase2"]],
          ("14 Ağustos: ikinci harekât başladı; Türk birlikleri Gazimağusa'ya doğru ilerliyor.", "14 August: the second operation began; Turkish forces advance on Famagusta.")),
      opt(("Mevzileri koru, Cenevre'ye dön", "Hold what you have, return to Geneva"), ("Diplomatik yol", "Diplomatic track"),
          [["rel", TR, US, 10], ["rel", TR, UK, 5], ["xstab", TR, -3]],
          ("Ankara ikinci harekâtı erteledi; Kissinger rahat bir nefes aldı.", "Ankara postponed the second operation; Kissinger breathed a sigh of relief."))),
   GR: role(("Karamanlis hükümeti Türkiye ile savaşı kaldıramaz; ama kamuoyu NATO'dan hıncını çıkarmak istiyor.", "Karamanlis's government cannot afford war with Turkey, but public opinion wants to punish NATO."),
      opt(("NATO'nun askerî kanadından çekil", "Leave NATO's military wing"), ("Yunan kamuoyunun talebi", "A demand of Greek opinion"),
          [["rel", GR, US, -20], ["xstab", GR, 10], ["rel", GR, TR, -5], ["flag", "cy74_nato_exit"]],
          ("Atina NATO'nun askerî kanadından çekildi; Washington Yunan lobisiyle karşı karşıya.", "Athens left NATO's military wing; Washington is up against the Greek lobby.")),
      opt(("NATO'da kal, diplomasiye yüklen", "Stay in NATO and lean on diplomacy"), ("Batı ile bağı koru", "Keep the Western link"),
          [["rel", GR, US, 10], ["xstab", GR, -5]],
          ("Karamanlis sakin kalmayı seçti; muhalefet sokakları doldurdu.", "Karamanlis chose calm; the opposition filled the streets."))),
   CY: role(("Türk birlikleri kuzeyde yerleşti; Klerides Cenevre'de pazarlıkta. Ordunun morali düşük.", "Turkish troops are settled in the north; Clerides bargains in Geneva. The army's morale is low."),
      opt(("Müzakereyi sürdür", "Keep negotiating"), ("Ateşkes için baskı", "Push for a ceasefire"), [["stab", CY, 3], ["rel", CY, US, 8]],
          ("Klerides Cenevre'de ateşkes için uğraşıyor.", "Clerides works for a ceasefire in Geneva.")),
      opt(("Direniş: yeni cephe hattı", "Resist: a new front line"), ("Lefkoşa'yı savun", "Defend Nicosia"), [["buff", CY, "def", 1.2, 8], ["troops", CY, 25], ["stab", CY, -4]],
          ("Millî Muhafız Lefkoşa çevresinde yeni hatlar kurdu.", "The National Guard built new lines around Nicosia."))),
   US: role(("Kongre, Türkiye'ye silah ambargosu için oy hazırlığında. Dışişleri Bakanlığı iki NATO müttefiki arasında köprü arıyor.", "Congress is preparing an arms embargo vote against Turkey. The State Department looks for a bridge between two NATO allies."),
      opt(("Ambargoyu destekle", "Back the embargo"), ("Kongre ile hareket et", "Move with Congress"), [["rel", US, TR, -20], ["rel", US, GR, 10]],
          ("Beyaz Saray Kongre'nin ambargo girişimine karşı koymadı.", "The White House did not resist Congress's embargo drive.")),
      opt(("Ambargoyu engelle", "Block the embargo"), ("NATO bütünlüğü", "NATO cohesion"), [["rel", US, TR, 12], ["rel", US, GR, -8], ["xstab", US, -2]],
          ("Ford yönetimi ambargoyu engellemek için Kongre'ye ricada bulundu.", "The Ford administration lobbied Congress to block the embargo.")))},
  [["buff", TR, "att", 1.25, 6], ["troops", NC, 80], ["rel", GR, US, -15], ["stab", GR, 8], ["stab", CY, -8], ["rel", TR, GR, -10], ["flag", "cy74_phase2"]],
  requires=["cy74_landing"]))

M.append(mk("cy74_ateskes", 1974, 9, ("Yeşil Hat: Ada İkiye Bölündü", "The Green Line: The Island Is Divided"),
  ("Silahlar sustu. Yaklaşık 160–200 bin Rum güneye, 45 bin Türk kuzeye göç etti; BM gözetiminde Yeşil Hat adayı ikiye böldü.",
   "The guns fell silent. Roughly 160–200 thousand Greek Cypriots fled south and 45 thousand Turkish Cypriots moved north; the UN-patrolled Green Line cut the island in two."),
  {TR: role(("Ateşkes hattı oturdu. Kuzey Türk denetiminde; ABD ve Britanya federal çözüm istiyor, Rumlar hâlâ müzakereye yanaşmıyor.", "The ceasefire line has set. The north is under Turkish control; the US and Britain want a federal solution, the Greek side still refuses to talk."),
      opt(("Ateşkesi kabul et, kazanımı koru", "Accept the ceasefire, keep the gains"), ("Barış", "Peace"), [["peace", TR, CY], ["peace", NC, CY], ["xstab", TR, 5], ["flag", "cy74_ceasefire"]],
          ("Kıbrıs'ta ateşkes yürürlükte; Türk bayrağı Girne'de dalgalanıyor.", "The ceasefire holds; the Turkish flag flies at Kyrenia.")),
      opt(("Harekâta devam: Larnaka ve Limasol", "Fight on: Larnaca and Limassol"), ("Tüm ada baskısı", "Pressure for the whole island"),
          [["buff", TR, "att", 1.2, 8], ["rel", TR, US, -15], ["rel", TR, UK, -10], ["xstab", TR, -3], ["stab", CY, -10]],
          ("Ankara ateşkesi tanımadı; ilerleyiş güneye doğru sürüyor.", "Ankara ignored the ceasefire; the advance continues south.")),
      opt(("Federasyon önerisi sun", "Propose a federation"), ("Barış + müzakere", "Peace plus negotiation"), [["peace", TR, CY], ["peace", NC, CY], ["rel", TR, UK, 10], ["rel", TR, US, 10], ["flag", "cy74_ceasefire"]],
          ("Ankara iki toplumlu federasyon önerdi; Londra ve Washington ilgi gösterdi.", "Ankara proposed a bi-communal federation; London and Washington showed interest."))),
   CY: role(("Yüz binlerce mülteci güneyde çadırlarda. Klerides Türkiye ile ateşkesi kabul etmek zorunda mı?", "Hundreds of thousands of refugees are in tents in the south. Does Clerides have to accept the ceasefire with Turkey?"),
      opt(("Ateşkesi kabul et", "Accept the ceasefire"), ("Savaşı durdur", "Stop the war"), [["peace", CY, TR], ["peace", CY, NC], ["stab", CY, -8], ["flag", "cy74_ceasefire"]],
          ("Rum yönetimi ateşkesi kabul etti; mülteci krizi başladı.", "The Greek-Cypriot administration accepted the ceasefire; the refugee crisis begins.")),
      opt(("Direnişi sürdür", "Keep fighting"), ("Ateşkesi reddet", "Reject the ceasefire"), [["buff", CY, "def", 1.2, 8], ["stab", CY, -5]],
          ("Lefkoşa ateşkesi reddetti; çatışmalar sürüyor.", "Nicosia rejected the ceasefire; fighting continues."))),
   GR: role(("Atina savaşa giremedi; Kıbrıs'ta bölünme kalıcı görünüyor. Karamanlis kamuoyuna ne söyleyecek?", "Athens could not go to war; the partition of Cyprus looks permanent. What will Karamanlis tell the public?"),
      opt(("Diplomatik zafer ara", "Seek a diplomatic win"), ("BM ve AB'ye başvur", "Turn to the UN and Europe"), [["xstab", GR, 3], ["rel", GR, UK, 5]],
          ("Karamanlis Kıbrıs'ı uluslararası alana taşıdı.", "Karamanlis took Cyprus to the international stage.")),
      opt(("Öfke: Türkiye'ye karşı cephe", "Anger: a front against Turkey"), ("Ege'de askerî hazırlık", "Military build-up in the Aegean"), [["rel", GR, TR, -15], ["troops", GR, 15], ["xstab", GR, -3]],
          ("Yunanistan Ege adalarını silahlandırıyor; Ankara tepkili.", "Greece is arming the Aegean islands; Ankara reacts angrily.")))},
  [["peace", TR, CY], ["peace", NC, CY], ["stab", CY, -15], ["flag", "cy74_ceasefire"]],
  requires=["cy74_landing"], forbid=["cy74_ceasefire"]))

M.append(mk("cy74_makarios", 1974, 12, ("Makarios Döndü, Kongre Ambargo Dedi", "Makarios Returns, Congress Says Embargo"),
  ("7 Aralık'ta Makarios adaya döndü. Ardından ABD Kongresi, Türkiye'ye silah yardımının kesilmesini öngören kararı kabul etti; ambargo Şubat 1975'te yürürlüğe girecek.",
   "On 7 December Makarios returned to the island. Then the US Congress passed a measure cutting arms aid to Turkey; the embargo takes effect in February 1975."),
  {TR: role(("Ambargo ordunun yedek parça ve mühimmat hattını tehdit ediyor. Ankara'da ABD üslerinin kapatılması tartışılıyor.", "The embargo threatens the army's spare-parts and ammunition pipeline. Ankara debates closing US bases."),
      opt(("Sert yanıt: üsleri kısıtla", "Hard response: restrict the bases"), ("Amerikan üsleri askıya", "Suspend US facilities"), [["rel", TR, US, -25], ["xstab", TR, 5], ["rel", TR, RU, 10], ["flag", "cy74_us_bases"]],
          ("Ankara ABD'nin üs faaliyetlerini kısıtlama kararı aldı.", "Ankara decided to restrict US base activities.")),
      opt(("Kongre'yi diplomasiyle ikna et", "Win Congress over with diplomacy"), ("Lobi çalışması", "Lobbying"), [["rel", TR, US, 5], ["xstab", TR, -2]],
          ("Ankara Washington'da lobi faaliyetini artırdı.", "Ankara stepped up lobbying in Washington.")),
      opt(("SSCB ile yakınlaş", "Move closer to the USSR"), ("Çok yönlü dış politika", "Multi-directional foreign policy"), [["rel", TR, RU, 25], ["rel", TR, US, -15]],
          ("Ankara Moskova'ya yönelik açılım sinyalleri verdi.", "Ankara signalled an opening to Moscow."))),
   US: role(("Kongre ambargoyu dayattı; Başkan Ford veto etti ama Meclis aştı. Türkiye'nin tepkisi sert olabilir.", "Congress forced the embargo; President Ford vetoed but was overridden. Turkey's reaction may be harsh."),
      opt(("Ambargoyu uygula", "Enforce the embargo"), ("Kongre kararı", "Congress's decision"), [["rel", US, TR, -15], ["rel", US, GR, 8]],
          ("ABD ambargoyu uyguluyor; Ankara öfkeli.", "The US enforces the embargo; Ankara is furious.")),
      opt(("Esnetmeye çalış", "Seek flexibility"), ("Yürütme yetkisi", "Executive latitude"), [["rel", US, TR, 8], ["xstab", US, -2]],
          ("Beyaz Saray ambargoyu esnetmek için yollar arıyor.", "The White House looks for ways to soften the embargo."))),
   CY: role(("Makarios adaya döndü ama ada artık bölünmüş. Cumhurbaşkanlığı koltuğu geri verildi.", "Makarios is back but the island is divided. The presidency was restored to him."),
      opt(("Makarios yönetimini yeniden kur", "Rebuild Makarios's rule"), ("Meşru yönetim", "The legitimate government"), [["xstab", CY, 8], ["rel", CY, GR, 10]],
          ("Makarios Lefkoşa'da coşkuyla karşılandı.", "Makarios was welcomed with enthusiasm in Nicosia.")),
      opt(("Federasyon pazarlığı", "Bargain over a federation"), ("Viyana görüşmeleri", "Vienna talks"), [["rel", CY, TR, 8], ["rel", CY, NC, 10], ["xstab", CY, -2]],
          ("Rum liderliği federasyon görüşmelerine ilk kez yeşil ışık yaktı.", "The Greek-Cypriot leadership gave the green light to federation talks for the first time.")))},
  [["rel", TR, US, -20], ["stab", CY, 8], ["rel", CY, TR, -5]], requires=["cy74_landing"]))

M.append(mk("cy74_federe", 1975, 2, ("Kıbrıs Türk Federe Devleti", "The Turkish Federated State of Cyprus"),
  ("13 Şubat 1975: Kuzeyde Kıbrıs Türk Federe Devleti ilan edildi; başkan Rauf Denktaş. ABD'nin Türkiye'ye silah ambargosu yürürlüğe girdi.",
   "13 February 1975: the Turkish Federated State of Cyprus was proclaimed in the north under Rauf Denktaş. The US arms embargo on Turkey took effect."),
  {NC: role(("Kuzey fiilen ayrı bir idare. Ankara'nın desteğiyle bir federe devlet ilan etmek bölünmeyi kalıcılaştırır ama Rumlar da adanın tamamını temsil iddiasında.", "The north is effectively a separate administration. A federated state with Ankara's backing would make partition permanent, but the Greek side claims to represent the whole island."),
      opt(("Federe Devleti ilan et (tarihî)", "Proclaim the Federated State (historical)"), ("Anayasal çerçeve", "A constitutional framework"), [["xstab", NC, 8], ["rel", NC, TR, 15], ["rel", NC, CY, -15]],
          ("Lefkoşa'nın kuzeyinde Kıbrıs Türk Federe Devleti ilan edildi.", "The Turkish Federated State of Cyprus was proclaimed north of Nicosia.")),
      opt(("Bekle: tek devlet çatısı", "Wait: one-state umbrella"), ("Viyana'da federasyon", "Federation at Vienna"), [["rel", NC, CY, 5], ["xstab", NC, -3]],
          ("Denktaş federasyon görüşmeleri için zaman kazanıyor.", "Denktaş buys time for federation talks."))),
   TR: role(("Kuzey Kıbrıs Federe Devleti'ni ilan etmek üzere. Ambargo yürürlükte, tepki beklenmeli.", "The north is about to proclaim a Federated State. The embargo is in force, so reaction should be expected."),
      opt(("Federe Devleti destekle", "Back the Federated State"), ("Ankara'nın bayrağı", "Ankara's flag"), [["rel", TR, NC, 15], ["rel", TR, CY, -10], ["xstab", TR, 3]],
          ("Ankara Federe Devlet'in ilanını destekledi.", "Ankara backed the proclamation of the Federated State.")),
      opt(("Frenle: federasyon çerçevesi", "Brake: a federal framework"), ("Viyana", "Vienna"), [["rel", TR, UK, 5], ["rel", TR, US, 5]],
          ("Ankara 'federal çözüm' mesajını güçlendirdi.", "Ankara strengthened its 'federal solution' message.")))},
  [["rel", NC, CY, -15], ["stab", CY, -4]], requires=["cy74_landing"]))

M.append(mk("cy74_uslerin", 1975, 7, ("Türkiye ABD Üslerini Kapattı", "Turkey Closes US Bases"),
  ("26 Temmuz 1975: Ambargoya karşılık Türkiye ABD'nin üs faaliyetlerini askıya aldı (İncirlik hariç). NATO'nun güney kanadı sarsıldı.",
   "26 July 1975: in response to the embargo Turkey suspended US facilities (except Incirlik). NATO's southern flank is shaken."),
  {TR: role(("Üsler Amerikan elektronik istihbaratı için can damarı. Kapatmak Washington'a mesajdır ama Türkiye'yi de yalnızlaştırır.", "The bases are a lifeline for US signals intelligence. Closing them sends Washington a message but isolates Turkey too."),
      opt(("Üsleri askıya al (tarihî)", "Suspend the bases (historical)"), ("Kararlı mesaj", "A firm message"), [["rel", TR, US, -20], ["xstab", TR, 4], ["rel", TR, RU, 8]],
          ("Ankara Amerikan üslerini askıya aldı; Moskova memnun.", "Ankara suspended US bases; Moscow is pleased.")),
      opt(("Üsleri açık tut", "Keep the bases open"), ("İkili ilişki", "Bilateral ties"), [["rel", TR, US, 8], ["xstab", TR, -3]],
          ("Ankara üsleri açık tutarak Kongre'ye baskıyı sürdürdü.", "Ankara kept the bases open and kept pressure on Congress.")))
   , US: role(("Üsler kapanırsa Sovyetler hakkındaki elektronik dinleme ağı ciddi hasar görür. Ambargoyu kaldırmak için Kongre'ye gidebilirsin.", "If the bases close, the electronic listening net on the Soviets is badly damaged. You can go to Congress to lift the embargo."),
      opt(("Ambargoyu kaldır (kısmen)", "Lift the embargo (partly)"), ("Üsler için tavizi kabul et", "Concede for the bases"), [["rel", US, TR, 25], ["xstab", US, -2], ["rel", US, GR, -8]],
          ("Kongre ambargoyu kısmen kaldırdı; Türkiye üslerle ilgili tutumunu yumuşattı.", "Congress partly lifted the embargo; Turkey softened its stance on the bases.")),
      opt(("Sürdür", "Hold firm"), ("İlkeli duruş", "A principled stand"), [["rel", US, TR, -10], ["rel", US, GR, 5]],
          ("Washington ambargoyu sürdürüyor; Ankara üslerde kararlı.", "Washington keeps the embargo; Ankara stands firm on the bases.")))},
  [["rel", TR, US, -15], ["xstab", TR, 3]], major=False, requires=["cy74_landing"]))

M.append(mk("cy74_makarios_oldu", 1977, 8, ("Makarios Öldü", "Makarios Died"),
  ("3 Ağustos 1977: Başpiskopos Makarios kalp krizinden öldü; Rum tarafında yeni lider Spyros Kiprianu. Ada hâlâ bölünmüş.",
   "3 August 1977: Archbishop Makarios died of a heart attack; Spyros Kyprianou is the new leader on the Greek side. The island remains divided."),
  {}, [["stab", CY, -6]], major=False))

for m_ in M:
    for rname, r_ in m_["roles"].items():
        if rname == TR:
            continue
        for o_ in r_["options"]:
            if o_["t"] not in ("Direnişi sürdür",):
                o_["keep_default"] = True
doc = {"moments": M, "en": EN}
wr("data/moments/cw74.json", doc)

# ---------------------------------------------------------------- dönem adları (sömürge/rejim adı)
cn = rd("data/era_colony_names.json")
cn["cw74"] = {"Burkina Faso": "Yukarı Volta", "Benin": "Dahomey", "Zimbabwe": "Rodezya", "Dem. Rep. Congo": "Zaire", "Libya": "Libya Arap Cumhuriyeti",
              "Cambodia": "Khmer Cumhuriyeti", "Myanmar": "Birmanya", "Bangladesh": "Bangladeş", "Iran": "İran İmparatorluğu", "Congo": "Kongo Halk Cumhuriyeti"}
wr("data/era_colony_names.json", cn)

idx = rd("data/eras/index.json")
if "cw74" not in idx:
    idx.insert(idx.index("cw62") + 1, "cw74")
    open(os.path.join(ROOT, "data/eras/index.json"), "w", encoding="utf-8").write(json.dumps(idx, ensure_ascii=False))
print("tamam:", len(M), "an,", len(EV), "olay,", len(EN), "çeviri")
