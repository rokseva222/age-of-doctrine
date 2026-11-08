#!/usr/bin/env python3
"""Alternatif tarih çağları üretici: data/eras/alt_*.json (+ index.json güncellemesi).
Her çağ bir temel çağın (ww1 / ww2 / cw62) haritasını, tablolarını ve lider zincirini miras alır;
yalnızca başlangıç düzeni (ittifak, savaş, çarpanlar), olaylar ve hedefler değişir.
Çalıştır: python3 tools/data/gen_alt.py"""
import json, os, copy

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
US = "United States of America"; UK = "United Kingdom"; RU = "Russia"

def emb(shape, inner, sym, c1, c2, c3):
    return {"shape": shape, "inner": inner, "symbol": sym, "c1": c1, "c2": c2, "c3": c3}

BASES = {
    "ww1": {"start_year": 1914, "start_doy": 212, "family": "ww1", "icon": "helmet_ww1", "mood": "war",
        "look": {"shadow": [0.09, 0.07, 0.05], "mid": [0.56, 0.45, 0.29], "light": [0.96, 0.90, 0.74], "amount": 0.38, "vignette": 0.18, "grain": 0.012},
        "blocs": [
            {"name": "İtilaf Devletleri", "members": [UK, "France", RU, "Serbia", "Belgium", "Japan", "Canada", "Australia", "New Zealand", "South Africa"], "emblem": emb(5, 1, "shield", "2f4f9a", "ece6d6", "2f4f9a")},
            {"name": "Merkezi Güçler", "members": ["Germany", "Austria", "Turkey", "Bulgaria"], "emblem": emb(4, 1, "crown", "6d6f78", "e3a92b", "e3a92b")}],
        "wars": [["Austria", "Serbia"], ["Germany", "Russia"], ["Germany", "France"], ["Germany", "Belgium"], [UK, "Germany"], ["Austria", "Russia"], ["Japan", "Germany"]],
        "truce": []},
    "ww2": {"start_year": 1939, "start_doy": 243, "family": "ww2", "icon": "helmet_ww2", "mood": "war",
        "look": {"shadow": [0.05, 0.07, 0.06], "mid": [0.36, 0.42, 0.31], "light": [0.90, 0.90, 0.82], "amount": 0.30, "vignette": 0.14, "grain": 0.010},
        "blocs": [
            {"name": "Müttefik Devletler", "members": [UK, "France", "Poland", "Australia", "New Zealand", "Canada", "South Africa"], "emblem": emb(1, 1, "shield", "2f4f9a", "ece6d6", "2f4f9a")},
            {"name": "Mihver Devletleri", "members": ["Germany", "Italy", "Japan", "Slovakia"], "emblem": emb(4, 1, "bolt", "5d6068", "ece6d6", "e5482f")}],
        "wars": [["Germany", "Poland"], [UK, "Germany"], ["France", "Germany"], ["Australia", "Germany"], ["New Zealand", "Germany"], ["Canada", "Germany"], ["South Africa", "Germany"], ["Japan", "China"]],
        "truce": [["Germany", RU, 90]]},
    "cw62": {"start_year": 1962, "start_doy": 290, "family": "cold", "icon": "helmet", "mood": "war",
        "look": {"shadow": [0.06, 0.07, 0.09], "mid": [0.42, 0.45, 0.42], "light": [0.93, 0.9, 0.83], "amount": 0.28, "vignette": 0.14, "grain": 0.01},
        "blocs": [
            {"name": "Kuzey Atlantik İttifakı", "members": [US, "Canada", UK, "France", "Germany", "Italy", "Belgium", "Netherlands", "Luxembourg", "Denmark", "Norway", "Iceland", "Portugal", "Greece", "Turkey"], "emblem": emb(0, 2, "star", "2f4f9a", "ece6d6", "2f4f9a")},
            {"name": "Varşova Paktı", "members": [RU, "Poland", "Czechia", "Hungary", "Romania", "Bulgaria", "Albania"], "emblem": emb(4, 1, "star", "b53a2e", "e3a92b", "e3a92b")}],
        "wars": [], "truce": []},
}

ERAS = []

def alt(id, base, name, sub, blurb, intro, suggest, en, wars=None, add_wars=None, blocs=None, truce=None, extra=None,
        events=None, ev_en=None, objectives=None, obj_en=None, inherit_exclude=None, inherit_until=None, free=False, icon=None, cold=None):
    b = BASES[base]
    setup = {
        "blocs": copy.deepcopy(blocs if blocs is not None else b["blocs"]),
        "wars": copy.deepcopy(wars if wars is not None else b["wars"] + (add_wars or [])),
        "truce": copy.deepcopy(truce if truce is not None else b["truce"]),
        "intro": intro,
    }
    if cold: setup["cold"] = cold
    for k, v in (extra or {}).items(): setup[k] = v
    d = {"id": id, "name": name, "sub": sub, "base": base, "family": b["family"], "pack": "alt", "icon": icon or b["icon"], "mood": b["mood"],
         "start_year": b["start_year"], "start_doy": b["start_doy"], "blurb": blurb, "suggest": suggest, "look": b["look"], "setup": setup}
    if free: d["free"] = True
    if inherit_exclude is not None or inherit_until is not None:
        d["inherit_until"] = inherit_until or [9999, 1]
        if inherit_exclude: d["inherit_exclude"] = inherit_exclude
    d["events"] = events or []
    d["objectives"] = objectives
    en = dict(en)
    en["setup_intro"] = en.pop("intro")
    en["events"] = {str(i): t for i, t in enumerate(ev_en or [])}
    en["objectives"] = obj_en
    d["en"] = en
    ERAS.append(d)

def obj(oid, typ, text, **kw):
    o = {"id": oid, "type": typ, "text": text}; o.update(kw); return o

def ev(y, m, t, fx=None): return {"y": y, "m": m, "t": t, "fx": fx or []}

# =============================================================== I. DÜNYA SAVAŞI
CP_NO_TURKEY = [copy.deepcopy(BASES["ww1"]["blocs"][0]), copy.deepcopy(BASES["ww1"]["blocs"][1])]
CP_NO_TURKEY[1]["members"] = ["Germany", "Austria", "Bulgaria"]
alt("alt_ott_neutral", "ww1", "Osmanlı Tarafsız", "Ağustos 1914 – Alternatif",
    "Enver Paşa'nın savaş yanlıları geri adım attı: İstanbul tarafsız kaldı. Boğazlar kapalı, Rusya'nın tahılı çıkamıyor, İtilaf ve Merkezî Güçler Osmanlı'yı kendi safına çekmeye çalışıyor.",
    "Ağustos 1914: Osmanlı Devleti tarafsızlığını ilan etti. Berlin de Londra da İstanbul'a tekliflerle geliyor; Boğazlar kimin eline geçerse savaşın seyri değişebilir.",
    ["Turkey", "Germany", RU, UK, "Austria", "Bulgaria"],
    {"name": "Ottoman Neutrality", "sub": "August 1914 – Alternate", "blurb": "The war faction around Enver Pasha backed down: Istanbul stayed neutral. The Straits are shut, Russian grain cannot get out, and both blocs court the Ottomans.", "intro": "August 1914: the Ottoman Empire has declared neutrality. Berlin and London both arrive in Istanbul with offers; whoever wins the Straits may change the course of the war."},
    blocs=CP_NO_TURKEY, free=True,
    inherit_exclude=["Osmanlı Devleti Karadeniz", "Çanakkale"],
    events=[ev(1914, 11, "Boğazlar kapalı kalırken Rusya'nın tahıl ihracatı çöktü; Petrograd'da ekmek kuyrukları büyüyor.", [["stab", RU, -4]]),
            ev(1915, 3, "İtilaf İstanbul'a Boğazlar ve toprak vaatleri sundu; Merkezî Güçler de karşı teklif hazırladı.", []),
            ev(1916, 6, "Osmanlı hükûmeti tarafsızlık politikasını sürdürüyor; ticaret limanlarında altın akıyor.", [["stab", "Turkey", 4]])],
    ev_en=["With the Straits closed, Russian grain exports collapsed; bread queues grow in Petrograd.", "The Entente offered Istanbul the Straits and territory; the Central Powers prepared a counter-offer.", "The Ottoman government keeps its neutrality; gold flows into its trading ports."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156), obj("o2", "alliances", "3 müttefik edin", n=3, required=False)],
        "Turkey": [obj("t1", "no_war", "İki yıl savaşsız kal", turns=104), obj("t2", "stability", "İstikrarı 60 üzerinde tut", n=60)]},
    obj_en={"o1": "Survive three years", "o2": "Make 3 allies", "t1": "Stay out of war for two years", "t2": "Keep stability above 60"})

alt("alt_britain_out", "ww1", "Londra Seyirci", "Ağustos 1914 – Alternatif",
    "Kabine Belçika için savaşmayı reddetti: Britanya tarafsız. Fransa ve Rusya Almanya'ya tek başına karşı; Kayzer'in orduları Paris'e doğru ilerliyor.",
    "Ağustos 1914: Britanya Kabinesi Belçika'nın işgaline rağmen tarafsız kalmayı seçti. Kanal'ın ötesindeki donanma limanda; kıta kendi kaderine terk edildi.",
    ["Germany", "France", RU, "Austria", UK, "Belgium"],
    {"name": "London Stays Out", "sub": "August 1914 – Alternate", "blurb": "The Cabinet refused to fight for Belgium: Britain is neutral. France and Russia face Germany alone, and the Kaiser's armies are marching on Paris.", "intro": "August 1914: Despite the invasion of Belgium, the British Cabinet chose neutrality. The fleet stays in port; the continent is left to its fate."},
    blocs=[{**copy.deepcopy(BASES["ww1"]["blocs"][0]), "members": [m for m in BASES["ww1"]["blocs"][0]["members"] if m != UK]}, copy.deepcopy(BASES["ww1"]["blocs"][1])],
    wars=[w for w in BASES["ww1"]["wars"] if UK not in w],
    extra={"stability": {"France": -6, "Belgium": -8}, "troops_mult": {"Germany": 1.1}},
    inherit_exclude=["Çanakkale", "ABD, Almanya"], inherit_until=[1915, 1],
    events=[ev(1914, 9, "Marne hattında Alman ilerleyişi sürüyor; Fransız hükûmeti Bordeaux'ya taşınmaya hazırlanıyor.", [["stab", "France", -6]]),
            ev(1915, 4, "Londra'da savaş yanlıları sokağa çıktı: kamuoyu Kabine'yi savaşa girmeye çağırıyor.", [["stab", UK, -5]])],
    ev_en=["The German advance along the Marne continues; the French government prepares to move to Bordeaux.", "War advocates take to London's streets: public opinion urges the Cabinet to enter the war."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "France": [obj("f1", "own_capital", "Paris'i elinde tut", country="France"), obj("f2", "alliances", "3 müttefik edin", n=3)],
        "Germany": [obj("g1", "own_capital", "Paris'i ele geçir", country="France"), obj("g2", "eliminate", "Belçika'yı yok et", country="Belgium", required=False)],
        UK: [obj("u1", "no_war", "İki yıl savaşsız kal", turns=104), obj("u2", "gdp_share", "Dünya GSYH payını %6'ya çıkar", pct=6, required=False)]},
    obj_en={"o1": "Survive three years", "f1": "Hold Paris", "f2": "Make 3 allies", "g1": "Take Paris", "g2": "Eliminate Belgium", "u1": "Stay out of war for two years", "u2": "Raise world GDP share to 6%"})

IT_CP = copy.deepcopy(BASES["ww1"]["blocs"])
IT_CP[1]["members"] = ["Germany", "Austria", "Turkey", "Bulgaria", "Italy"]
alt("alt_italy_central", "ww1", "Üçlü İttifak Sağlam", "Ağustos 1914 – Alternatif",
    "İtalya 1914'te ittifakını bozmadı ve Merkezî Güçler'in yanında savaşa girdi. Alpler'den Akdeniz'e kadar yeni bir cephe açıldı; Fransız güneyi tehlikede.",
    "Ağustos 1914: Roma Üçlü İttifak'a sadık kaldı. İtalyan orduları Fransa sınırına yöneldi; Akdeniz'de İtilaf donanması tek başına.",
    ["Italy", "France", "Germany", UK, "Austria", RU],
    {"name": "The Triple Alliance Holds", "sub": "August 1914 – Alternate", "blurb": "Italy never broke its alliance in 1914 and entered the war with the Central Powers. A new front opens from the Alps to the Mediterranean; southern France is in danger.", "intro": "August 1914: Rome stayed loyal to the Triple Alliance. Italian armies turn toward the French border; the Entente fleet stands alone in the Mediterranean."},
    blocs=IT_CP, add_wars=[["Italy", "France"], ["Italy", UK], ["Italy", "Serbia"]],
    extra={"troops_mult": {"Italy": 1.1}},
    inherit_exclude=["İtalya, Avusturya-Macaristan'a"],
    events=[ev(1915, 5, "İtalyan birlikleri Fransız Alpleri'nde ilerliyor; İtilaf yedek kuvvetleri güneye kaydırıyor.", [["stab", "France", -4]])],
    ev_en=["Italian troops advance in the French Alps; the Entente shifts reserves south."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "Italy": [obj("i1", "own_provinces", "40 eyalete ulaş", n=40)],
        "France": [obj("f1", "own_capital", "Paris'i elinde tut", country="France")]},
    obj_en={"o1": "Survive three years", "i1": "Reach 40 provinces", "f1": "Hold Paris"})

alt("alt_schlieffen", "ww1", "Schlieffen Planı Tutuyor", "Ağustos 1914 – Alternatif",
    "Marne'da sonuç değişti: Alman kuvvetleri Paris çevresine ulaştı. Fransa çöküşün eşiğinde, Britanya Seferî Kuvvetleri denize sıkıştı; savaş kısa mı sürecek, yoksa Rusya'ya mı kayacak?",
    "Eylül 1914: Marne'daki karşı taarruz başarısız oldu. Alman kolları Paris'in kapılarında; hükûmet kaçıyor.",
    ["France", "Germany", UK, RU, "Belgium"],
    {"name": "The Schlieffen Plan Works", "sub": "August 1914 – Alternate", "blurb": "The outcome at the Marne changed: German forces reached the outskirts of Paris. France is on the brink; the British Expeditionary Force is pinned to the sea.", "intro": "September 1914: the counter-offensive on the Marne failed. German columns stand at the gates of Paris; the government is fleeing."},
    extra={"troops_mult": {"Germany": 1.25, "France": 0.75, "Belgium": 0.6}, "stability": {"France": -18, "Belgium": -10, "Germany": 6}},
    inherit_exclude=["Verdun"],
    events=[ev(1914, 10, "Paris kuşatma altında: Fransız hükûmeti Bordeaux'dan müzakere sinyalleri veriyor.", [["stab", "France", -8]]),
            ev(1915, 2, "Britanya Seferî Kuvvetleri Kanal limanlarından tahliye ediliyor.", [["stab", UK, -4]])],
    ev_en=["Paris is besieged: the French government signals openness to talks from Bordeaux.", "The British Expeditionary Force is being evacuated from the Channel ports."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "France": [obj("f1", "own_capital", "Paris'i elinde tut", country="France"), obj("f2", "cease_war", "Almanya ile barış yap", **{"with": "Germany"})],
        "Germany": [obj("g1", "own_capital", "Paris'i ele geçir", country="France"), obj("g2", "cease_war", "Rusya ile barış yap", **{"with": RU}, required=False)]},
    obj_en={"o1": "Survive three years", "f1": "Hold Paris", "f2": "Make peace with Germany", "g1": "Take Paris", "g2": "Make peace with Russia"})

ALL_COLD = [["Germany", "France"], ["Austria", "Serbia"], [RU, "Austria"], [RU, "Germany"], [UK, "Germany"]]
alt("alt_no_sarajevo", "ww1", "Saraybosna'da Barış", "Haziran 1914 – Alternatif",
    "Arşidük sağ kurtuldu. Avrupa hâlâ silahlanıyor, ittifaklar sağlam ama tetik çekilmedi. Savaşı sen mi başlatacaksın, yoksa barışı mı koruyacaksın?",
    "Ağustos 1914: Saraybosna suikastı başarısız oldu. Avrupa'nın başkentleri gergin ama savaşsız; kriz diplomasiyle yönetiliyor.",
    ["Germany", "Austria", RU, UK, "France", "Serbia"],
    {"name": "Peace in Sarajevo", "sub": "June 1914 – Alternate", "blurb": "The Archduke survived. Europe is still arming and the alliances hold, but the trigger was never pulled. Will you start the war, or keep the peace?", "intro": "August 1914: the Sarajevo assassination failed. Europe's capitals are tense but at peace; the crisis is being managed by diplomacy."},
    wars=[], truce=[], cold=ALL_COLD, extra={"stability": {"Austria": -4, RU: -4}},
    events=[ev(1914, 12, "Balkanlar'da yeni bir silahlanma yarışı: Sırbistan ve Avusturya sınırlarda mevzilendi.", []),
            ev(1915, 6, "Viyana-Belgrad hattında bir sınır olayı: ordular alarma geçti.", [["stab", "Serbia", -3]])],
    ev_en=["A new Balkan arms race: Serbia and Austria dig in along the border.", "A border incident on the Vienna–Belgrade line: armies are on alert."],
    objectives={"*": [obj("o1", "no_war", "Üç yıl savaşsız kal", turns=156), obj("o2", "alliances", "4 müttefik edin", n=4, required=False)],
        "Germany": [obj("g1", "gdp_share", "Dünya GSYH payını %8'e çıkar", pct=8)]},
    obj_en={"o1": "Stay at peace for three years", "o2": "Make 4 allies", "g1": "Raise world GDP share to 8%"})

alt("alt_tsar_holds", "ww1", "Çar Ayakta", "Ağustos 1914 – Alternatif",
    "Rusya'da devrim hiç patlamadı. Çar'ın hükûmeti reform yaptı, ordu ikmali düzeldi; Doğu Cephesi'nde Alman ve Avusturya ordularının ağır bir rakibi var.",
    "Ağustos 1914: Rusya'da seferberlik beklenenden düzenli ilerliyor; Çar II. Nikolay ordunun başında.",
    [RU, "Germany", "Austria", "Turkey", "France", UK],
    {"name": "The Tsar Holds", "sub": "August 1914 – Alternate", "blurb": "The revolution in Russia never erupted. The Tsar's government reformed, army supply improved; on the Eastern Front, the German and Austrian armies face a heavy opponent.", "intro": "August 1914: Russian mobilization is proceeding more smoothly than expected; Nicholas II is at the head of the army."},
    extra={"troops_mult": {RU: 1.15}, "stability": {RU: 10}},
    inherit_exclude=["Rusya'da Şubat", "Rusya'da Ekim", "Brest-Litovsk"],
    events=[ev(1916, 6, "Brusilov taarruzunun başarısı çarlık rejimini güçlendirdi; Duma savaş bütçesini onayladı.", [["stab", RU, 5]])],
    ev_en=["The success of the Brusilov offensive strengthened the Tsarist regime; the Duma approved the war budget."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        RU: [obj("r1", "own_capital", "Berlin'i ele geçir", country="Germany"), obj("r2", "stability", "İstikrarı 60 üzerinde tut", n=60, required=False)],
        "Germany": [obj("g1", "cease_war", "Rusya ile barış yap", **{"with": RU})]},
    obj_en={"o1": "Survive three years", "r1": "Take Berlin", "r2": "Keep stability above 60", "g1": "Make peace with Russia"})

# =============================================================== II. DÜNYA SAVAŞI
AX_RU = copy.deepcopy(BASES["ww2"]["blocs"])
AX_RU[1]["members"] = ["Germany", "Italy", "Japan", "Slovakia", RU]
alt("alt_axis_ussr", "ww2", "Moskova–Berlin Ekseni", "Eylül 1939 – Alternatif",
    "Stalin Hitler'le kalıcı ittifak yaptı. Doğu güvende, Batı yalnız: Britanya ve Fransa iki devle birden karşı karşıya.",
    "Eylül 1939: Molotov–Ribbentrop anlaşması ittifaka dönüştü. Sovyet ve Alman orduları ortak planlarla Polonya'yı paylaşıyor.",
    ["United Kingdom", "Germany", RU, "United States of America", "France", "Japan"],
    {"name": "The Moscow–Berlin Axis", "sub": "September 1939 – Alternate", "blurb": "Stalin made a lasting alliance with Hitler. The East is safe and the West is alone: Britain and France face two giants at once.", "intro": "September 1939: the Molotov–Ribbentrop pact has turned into an alliance. Soviet and German armies carve up Poland under joint plans."},
    blocs=AX_RU, truce=[["Japan", RU, 400]], add_wars=[[RU, "Poland"]],
    inherit_exclude=["Barbarossa", "SSCB ile"],
    events=[ev(1940, 6, "Moskova ve Berlin ortak bir ekonomik anlaşma imzaladı; Sovyet petrolü Alman tanklarını besliyor.", [["stab", "Germany", 3]]),
            ev(1941, 4, "Sovyet birlikleri Balkanlar'a ilerliyor; Londra ve Washington telaşta.", [["stab", UK, -3]])],
    ev_en=["Moscow and Berlin signed a joint economic deal; Soviet oil fuels German tanks.", "Soviet troops advance into the Balkans; London and Washington are alarmed."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        UK: [obj("u1", "alliances", "3 müttefik edin", n=3), obj("u2", "own_capital", "Berlin'i ele geçir", country="Germany", required=False)],
        "Germany": [obj("g1", "own_capital", "Londra'yı ele geçir", country=UK)]},
    obj_en={"o1": "Survive three years", "u1": "Make 3 allies", "u2": "Take Berlin", "g1": "Take London"})

alt("alt_hitler_dead", "ww2", "Hitler'e Suikast", "Eylül 1939 – Alternatif",
    "Berlin'de bir bomba patladı: Hitler öldü. Ordu iktidarı devraldı, Almanya Polonya'dan çekilmeyi tartışıyor. Dünya bir nefeste barış ile savaş arasında.",
    "Eylül 1939: Hitler suikastta öldü. Generaller yönetimi ele geçirdi; Polonya'daki harekât durdu ama kapılar henüz kapanmadı.",
    ["Germany", "Poland", UK, "France", RU, "Italy"],
    {"name": "The Plot Against Hitler", "sub": "September 1939 – Alternate", "blurb": "A bomb went off in Berlin: Hitler is dead. The army took power and Germany debates withdrawing from Poland. The world holds its breath between peace and war.", "intro": "September 1939: Hitler died in an assassination. The generals took over; the Polish operation has stalled, but the doors are not yet closed."},
    extra={"stability": {"Germany": -30}, "troops_mult": {"Germany": 0.9}},
    inherit_exclude=["Polonya düştü", "Danimarka ve Norveç", "Batı'da büyük taarruz", "Fransa'nın düşüşü", "Britanya Muharebesi"],
    events=[ev(1939, 10, "Berlin'de askerî konsey ateşkes teklif etti; Londra ve Paris şartlarını açıklıyor.", [["peace", "Germany", UK], ["peace", "Germany", "France"]]),
            ev(1940, 3, "Almanya'da siyasi hizipler çatışıyor; ordunun iktidarı kalıcı mı olacak?", [["stab", "Germany", -6]])],
    ev_en=["The military council in Berlin offered a ceasefire; London and Paris state their terms.", "Political factions clash in Germany: will army rule last?"],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156), obj("o2", "no_war", "Bir yıl savaşsız kal", turns=52, required=False)],
        "Germany": [obj("g1", "stability", "İstikrarı 55 üzerinde tut", n=55), obj("g2", "cease_war", "Britanya ile barış yap", **{"with": UK})],
        "Poland": [obj("p1", "own_capital", "Varşova'yı elinde tut", country="Poland")]},
    obj_en={"o1": "Survive three years", "o2": "Stay out of war for a year", "g1": "Keep stability above 55", "g2": "Make peace with Britain", "p1": "Hold Warsaw"})

TR_ALLY = copy.deepcopy(BASES["ww2"]["blocs"])
TR_ALLY[0]["members"] = TR_ALLY[0]["members"] + ["Turkey", "Greece", "Yugoslavia"]
TR_ALLY[0]["members"] = [m for m in TR_ALLY[0]["members"] if m != "Yugoslavia"]
alt("alt_turkey_allies", "ww2", "Ankara Safını Seçti", "Eylül 1939 – Alternatif",
    "Türkiye ve Yunanistan Müttefikler'e katıldı. Balkanlar'da yeni bir cephe, Akdeniz'de güçlü bir üs: Berlin ve Roma güney kanadı için endişeli.",
    "Eylül 1939: Ankara Londra ve Paris'le ittifak imzaladı. Boğazlar Müttefik gemilerine açık; Balkanlar'da seferberlik başladı.",
    ["Turkey", "Germany", UK, "Italy", "Greece", RU],
    {"name": "Ankara Chooses a Side", "sub": "September 1939 – Alternate", "blurb": "Turkey and Greece joined the Allies. A new front in the Balkans, a strong base in the Mediterranean: Berlin and Rome are worried about their southern flank.", "intro": "September 1939: Ankara signed an alliance with London and Paris. The Straits are open to Allied ships; mobilization has begun in the Balkans."},
    blocs=TR_ALLY, extra={"troops_mult": {"Turkey": 1.15}, "treasury_mult": {"Turkey": 1.3}},
    inherit_exclude=["Türkiye sembolik"],
    events=[ev(1941, 4, "Balkanlar'da Alman hazırlıkları başladı; Türk ordusu sınırda tetikte.", [["stab", "Turkey", -2]])],
    ev_en=["German preparations begin in the Balkans; the Turkish army is on alert at the border."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "Turkey": [obj("t1", "own_provinces", "Ordunu büyüt: 40 eyalete ulaş", n=40), obj("t2", "alliances", "4 müttefik edin", n=4)]},
    obj_en={"o1": "Survive three years", "t1": "Grow the army: reach 40 provinces", "t2": "Make 4 allies"})

alt("alt_japan_north", "ww2", "Japonya Kuzeye", "Eylül 1939 – Alternatif",
    "Japon ordusu Çin'e saplanmak yerine Sibirya'ya döndü: Halhin Gol'un devamı gerçek bir savaşa dönüştü. Sovyet Uzak Doğu'su ve Moğol bozkırı yeniden ateşte.",
    "Eylül 1939: Kwantung Ordusu Sovyet sınırını aştı. Moskova iki cepheli savaşa hazırlıksız yakalandı.",
    ["Japan", RU, "China", "United States of America", "Germany"],
    {"name": "Japan Turns North", "sub": "September 1939 – Alternate", "blurb": "Instead of sinking into China, the Japanese army turned toward Siberia: the sequel to Khalkhin Gol became a real war. The Soviet Far East and the Mongolian steppe are on fire.", "intro": "September 1939: the Kwantung Army crossed the Soviet border. Moscow was caught unprepared for a two-front war."},
    add_wars=[["Japan", RU]], truce=[["Germany", RU, 90]], inherit_exclude=["Japonya Sovyet"], extra={"stability": {RU: -6}},
    events=[ev(1940, 3, "Sibirya demiryolu boyunca ağır çarpışmalar: Moskova takviye yetiştirmeye çalışıyor.", [["stab", RU, -3]])],
    ev_en=["Heavy fighting along the Trans-Siberian railway: Moscow scrambles to bring reinforcements."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "Japan": [obj("j1", "own_provinces", "35 eyalete ulaş", n=35)],
        RU: [obj("r1", "cease_war", "Japonya ile barış yap", **{"with": "Japan"}), obj("r2", "own_capital", "Berlin'i ele geçir", country="Germany", required=False)]},
    obj_en={"o1": "Survive three years", "j1": "Reach 35 provinces", "r1": "Make peace with Japan", "r2": "Take Berlin"})

alt("alt_maginot", "ww2", "Fransa Hattı Tutuyor", "Eylül 1939 – Alternatif",
    "Fransız generalleri Ardenler'i savunmaya aldı: Almanya'nın hızlı zaferi kolay değil. Batı Cephesi yeniden siper savaşına dönüyor.",
    "Eylül 1939: Fransız ordusu yeniden yapılandı, yedekler Ardenler'de. Berlin'de planlar yeniden yazılıyor.",
    ["France", "Germany", UK, "Poland", "Italy"],
    {"name": "The Line Holds", "sub": "September 1939 – Alternate", "blurb": "French generals fortified the Ardennes: a quick German victory will not be easy. The Western Front is turning back into trench warfare.", "intro": "September 1939: the French army has been reorganized with reserves in the Ardennes. Plans are being rewritten in Berlin."},
    extra={"troops_mult": {"France": 1.35, "Germany": 0.9}, "stability": {"France": 8}},
    inherit_exclude=["Fransa'nın düşüşü", "Batı'da büyük taarruz"],
    events=[ev(1940, 5, "Batı Cephesi'nde Alman taarruzu Ardenler'de durdu; savaş uzun sürecek gibi.", [["stab", "Germany", -4]])],
    ev_en=["The German offensive stalled in the Ardennes on the Western Front; the war looks set to be long."],
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "France": [obj("f1", "own_capital", "Berlin'i ele geçir", country="Germany"), obj("f2", "alliances", "3 müttefik edin", n=3, required=False)],
        "Germany": [obj("g1", "own_capital", "Paris'i ele geçir", country="France")]},
    obj_en={"o1": "Survive three years", "f1": "Take Berlin", "f2": "Make 3 allies", "g1": "Take Paris"})

SP_AX = copy.deepcopy(BASES["ww2"]["blocs"])
SP_AX[1]["members"] = ["Germany", "Italy", "Japan", "Slovakia", "Spain"]
alt("alt_spain_axis", "ww2", "İspanya Mihver'de", "Eylül 1939 – Alternatif",
    "Franco Hitler'in teklifini kabul etti: İspanya Mihver'de. Cebelitarık kuşatma altında, Atlantik'te yeni denizaltı üsleri açılıyor.",
    "Eylül 1939: Madrid Berlin'le ittifak yaptı. Cebelitarık sınırında İspanyol topçusu mevzilendi.",
    ["Spain", UK, "Germany", "France", "Portugal"],
    {"name": "Spain Joins the Axis", "sub": "September 1939 – Alternate", "blurb": "Franco accepted Hitler's offer: Spain is in the Axis. Gibraltar is under siege and new U-boat bases are opening on the Atlantic.", "intro": "September 1939: Madrid allied with Berlin. Spanish artillery has taken positions on the Gibraltar border."},
    blocs=SP_AX, add_wars=[["Spain", UK], ["Spain", "Portugal"]], inherit_exclude=[],
    extra={"troops_mult": {"Spain": 1.15}},
    objectives={"*": [obj("o1", "survive", "Üç yıl ayakta kal", turns=156)],
        "Spain": [obj("s1", "own_provinces", "30 eyalete ulaş", n=30)],
        UK: [obj("u1", "alliances", "3 müttefik edin", n=3)]},
    obj_en={"o1": "Survive three years", "s1": "Reach 30 provinces", "u1": "Make 3 allies"})

# =============================================================== SOĞUK SAVAŞ
alt("alt_cuba_hot", "cw62", "Füze Krizi Patlıyor", "Ekim 1962 – Alternatif",
    "Karantina çöktü: ABD Küba'ya çıkarma yapıyor, Sovyetler Türkiye'deki Jüpiter füzelerine karşılık verdi. Dünya nükleer savaşın eşiğinde — ve bu sefer geri adım yok.",
    "Ekim 1962: Diplomasi iflas etti. Küba'da çatışma başladı, Karadeniz'de Sovyet ve Türk birlikleri karşı karşıya.",
    [US, RU, "Cuba", "Turkey", "United Kingdom"],
    {"name": "The Missile Crisis Explodes", "sub": "October 1962 – Alternate", "blurb": "The quarantine collapsed: the US is landing on Cuba and the Soviets have retaliated against the Jupiter missiles in Turkey. The world stands at the edge of nuclear war — and this time nobody blinks.", "intro": "October 1962: diplomacy has failed. Fighting has begun in Cuba, and Soviet and Turkish forces face off on the Black Sea."},
    add_wars=[[US, "Cuba"], [RU, "Turkey"]], cold=[[US, RU]],
    extra={"stability": {US: -6, RU: -6, "Cuba": -10}},
    events=[ev(1962, 11, "Küba'da ağır çarpışmalar sürüyor; BM Güvenlik Konseyi olağanüstü toplandı.", [["stab", "Cuba", -6]]),
            ev(1962, 12, "Moskova ve Washington arasında sıcak hat yeniden açıldı: ateşkes görüşmeleri başlıyor.", [["stab", US, 3], ["stab", RU, 3]])],
    ev_en=["Heavy fighting continues in Cuba; the UN Security Council has met in emergency session.", "The hotline between Moscow and Washington reopened: ceasefire talks begin."],
    objectives={"*": [obj("o1", "survive", "Bir yıl ayakta kal", turns=52), obj("o2", "alliances", "3 müttefik edin", n=3, required=False)],
        "Cuba": [obj("c1", "own_capital", "Havana'yı elinde tut", country="Cuba")],
        "Turkey": [obj("t1", "cease_war", "SSCB ile barış yap", **{"with": RU}), obj("t2", "stability", "İstikrarı 50 üzerinde tut", n=50)],
        US: [obj("a1", "cease_war", "SSCB ile savaş çıkmasını önle", **{"with": RU})]},
    obj_en={"o1": "Survive one year", "o2": "Make 3 allies", "c1": "Hold Havana", "t1": "Make peace with the USSR", "t2": "Keep stability above 50", "a1": "Prevent war with the USSR"})

alt("alt_sino_soviet", "cw62", "Çin–Sovyet Savaşı", "Ekim 1962 – Alternatif",
    "Komünist dünya yarıldı: Ussuri'de başlayan sınır çatışması 1962'de tam çaplı savaşa dönüştü. NATO bu yarılmayı fırsata çevirebilir mi?",
    "Ekim 1962: Pekin ve Moskova arasındaki kopuş silaha döküldü. Sibirya sınırında iki ordu karşı karşıya.",
    ["China", RU, US, "India", "Japan"],
    {"name": "The Sino-Soviet War", "sub": "October 1962 – Alternate", "blurb": "The communist world split: the border clash on the Ussuri became a full-scale war in 1962. Can NATO turn the rift into an opportunity?", "intro": "October 1962: the break between Beijing and Moscow has turned to arms. Two armies face each other on the Siberian border."},
    add_wars=[["China", RU]], inherit_exclude=["Küba krizi", "Sovyet füzeleri"], extra={"stability": {"China": -5, RU: -4}},
    events=[ev(1963, 2, "Kuzey Çin'de Sovyet zırhlıları ilerliyor; Pekin yedek kuvvet seferber etti.", [["stab", "China", -4]])],
    ev_en=["Soviet armor advances in northern China; Beijing mobilizes reserves."],
    objectives={"*": [obj("o1", "survive", "İki yıl ayakta kal", turns=104)],
        "China": [obj("c1", "cease_war", "SSCB ile barış yap", **{"with": RU})],
        RU: [obj("r1", "own_capital", "Pekin'i ele geçir", country="China")],
        US: [obj("a1", "alliances", "5 müttefik edin", n=5)]},
    obj_en={"o1": "Survive two years", "c1": "Make peace with the USSR", "r1": "Take Beijing", "a1": "Make 5 allies"})

alt("alt_berlin_hot", "cw62", "Berlin Sıcak Savaşı", "Ekim 1962 – Alternatif",
    "Berlin ablukası tırmandı ve ilk kurşunlar atıldı. Şehir ikiye bölünmüş, orduların karşılıklı mevzilendiği Avrupa nükleer cephenin tam ortasında.",
    "Ekim 1962: Sovyet kuvvetleri Batı Berlin'e giriş yollarını kapattı. Almanya sınırında NATO ve Varşova Paktı mevzilendi.",
    ["Germany", RU, US, "Poland", UK, "France"],
    {"name": "The Berlin War", "sub": "October 1962 – Alternate", "blurb": "The Berlin blockade escalated and the first shots were fired. The divided city and the armies lined up across Europe sit at the heart of the nuclear front.", "intro": "October 1962: Soviet forces have shut the access routes to West Berlin. NATO and the Warsaw Pact have taken positions on the German border."},
    add_wars=[[RU, "Germany"], ["Poland", "Germany"]], inherit_exclude=["Küba krizi", "Sovyet füzeleri"], cold=[[US, RU]], extra={"stability": {"Germany": -6}},
    events=[ev(1962, 12, "Berlin'de hava köprüsü yeniden kuruldu; ABD ve Britanya ortak bir plan açıkladı.", [["stab", "Germany", 3]])],
    ev_en=["The Berlin airlift was re-established; the US and Britain announced a joint plan."],
    objectives={"*": [obj("o1", "survive", "İki yıl ayakta kal", turns=104)],
        "Germany": [obj("g1", "own_capital", "Berlin'i elinde tut", country="Germany"), obj("g2", "cease_war", "SSCB ile barış yap", **{"with": RU}, required=False)],
        RU: [obj("r1", "own_capital", "Bonn'u ele geçir", country="Germany")]},
    obj_en={"o1": "Survive two years", "g1": "Hold Berlin", "g2": "Make peace with the USSR", "r1": "Take the western German capital"})


# ------------------------------------------------------------------ yaz
os.makedirs(os.path.join(ROOT, "data/eras"), exist_ok=True)
ids = ["cw62"]
for d in ERAS:
    with open(os.path.join(ROOT, "data/eras/%s.json" % d["id"]), "w", encoding="utf8") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
    ids.append(d["id"])
with open(os.path.join(ROOT, "data/eras/index.json"), "w", encoding="utf8") as f:
    json.dump(ids, f, ensure_ascii=False)
print(len(ERAS), "alternatif çağ yazıldı")
