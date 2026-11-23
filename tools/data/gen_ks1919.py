#!/usr/bin/env python3
"""Kurtuluş Savaşı 1919 çağı: data/eras/ks1919.json (+ index.json). Taban: ww1 (tablolar kopyalanıp 1919'a göre düzeltilir).
Çalıştır: python3 tools/data/gen_ks1919.py   (ww1 tabloları ks1919_ww1_*.json olarak yanında durur)"""
import json, os, copy

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
defs = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ks1919_ww1_defs.json")))
absb = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "ks1919_ww1_absorb.json")))
UK = "United Kingdom"; US = "United States of America"

# ---- 1919 düzeni: Orta Doğu ve Avrupa
absb["Turkey"] = []
absb["Austria"] = []
absb[UK] = absb[UK] + ["Iraq", "Jordan", "Palestine", "Israel", "Tanzania"]
absb["France"] = absb["France"] + ["Syria", "Lebanon", "Cameroon", "Togo"]
absb["Belgium"] = ["Rwanda", "Burundi"]
absb["South Africa"] = ["Namibia"]
absb["Australia"] = absb["Australia"] + ["Nauru"]
absb["Germany"] = []
absb["Russia"] = ["Ukraine", "Belarus", "Kazakhstan", "Uzbekistan", "Turkmenistan", "Tajikistan", "Kyrgyzstan"]
absb["Serbia"] = ["Croatia", "Slovenia", "Bosnia and Herz.", "Montenegro", "North Macedonia", "Kosovo"]
absb["Romania"] = ["Moldova"]

# ---- eyalet aktarımı: [eyalet, bugünkü sahip, yeni sahip, own|occ]
split = [
    [[228], "Russia", "Germany", "own"],
    [32, "China", UK, "own"], [31, "China", UK, "own"],
    # Yunan işgali: İzmir + Manisa (15 Mayıs 1919)
    [428, "Turkey", "Greece", "own"],
    # Fransız bölgesi: Kilikya, Antep, Urfa, Maraş
    [[430], "Turkey", "France", "own"], [[1963], "Turkey", "France", "own"], [[1965], "Turkey", "France", "own"],
    [422, "Turkey", "France", "own"], [[421], "Turkey", "France", "own"], [[1950], "Turkey", "France", "own"],
    # İtalyan bölgesi: Antalya, Muğla
    [429, "Turkey", "Italy", "own"],
    # İstanbul (Doğu Trakya dâhil) ve Samsun İngiliz işgali altında
    [423, "Turkey", UK, "occ"], [[425], "Turkey", UK, "occ"],
    # Doğu: Kars Ermenistan Cumhuriyeti'nde
    [420, "Turkey", "Armenia", "own"],
]

capital = {"Turkey": 431, "Russia": 257, "Brazil": 184}

# ---- devletler (1919)
D = defs
del D["Austria"]; del D["Montenegro"]
D["Turkey"] = {"name": "Ankara Hükûmeti (Millî Mücadele)", "color": "c85a4a", "leader": "Heyet-i Temsiliye Başkanı|Mustafa Kemal Paşa", "gdp": 14,
    "mil": {"personnel": 60000, "tank": 0, "afv": 0, "arty": 180, "air": 2, "sub": 0}}
D["Russia"] = {"name": "Sovyet Rusya", "color": "b53a2e", "flag": "R:0,0,1,1,#cc0000|S:.14,.2,.09,#ffd700", "leader": "Başkan|Vladimir Lenin", "gdp": 120,
    "mil": {"personnel": 3000000, "tank": 0, "afv": 40, "arty": 4000, "air": 100, "sub": 8}}
D["Germany"] = {"name": "Weimar Almanyası", "color": "6d6f78", "leader": "Cumhurbaşkanı|Friedrich Ebert", "gdp": 140,
    "mil": {"personnel": 400000, "tank": 0, "afv": 0, "arty": 800, "air": 20, "sub": 0}}
D[UK].update({"leader": "Başbakan|David Lloyd George", "name": "Birleşik Krallık", "mil": {"personnel": 1500000, "tank": 200, "afv": 200, "arty": 3000, "air": 800, "sub": 100}})
D["France"].update({"leader": "Başbakan|Georges Clemenceau", "mil": {"personnel": 1800000, "tank": 1500, "afv": 400, "arty": 6000, "air": 1500, "sub": 60}})
D["Italy"].update({"leader": "Başbakan|Francesco Nitti", "mil": {"personnel": 1000000, "tank": 0, "afv": 20, "arty": 2500, "air": 300, "sub": 40}})
D["Japan"].update({"leader": "Başbakan|Hara Takashi"})
D[US].update({"leader": "Başkan|Woodrow Wilson", "mil": {"personnel": 300000, "tank": 100, "afv": 100, "arty": 1500, "air": 400, "sub": 80}})
D["Serbia"] = {"name": "Sırp-Hırvat-Sloven Krallığı", "color": "b87a6a", "leader": "Kral|I. Petar", "gdp": 14,
    "mil": {"personnel": 300000, "tank": 0, "afv": 0, "arty": 700, "air": 10, "sub": 0}}
D["Greece"] = {"name": "Yunanistan", "color": "6a9ad0", "leader": "Başbakan|Eleftherios Venizelos", "gdp": 8,
    "mil": {"personnel": 220000, "tank": 0, "afv": 0, "arty": 550, "air": 30, "sub": 0}}
D["Bulgaria"].update({"leader": "Çar|III. Boris"})
D["Romania"].update({"leader": "Kral|I. Ferdinand"})
D["Belgium"].update({"leader": "Kral|I. Albert"})
D["Iran"].update({"leader": "Şah|Ahmed Şah Kaçar"})
D["Saudi Arabia"].update({"name": "Necid Emirliği"})
D["Poland"] = {"name": "Polonya", "color": "c9506a", "leader": "Devlet Başkanı|Józef Piłsudski", "gdp": 22,
    "mil": {"personnel": 600000, "tank": 0, "afv": 20, "arty": 1200, "air": 100, "sub": 0}}
D["Armenia"] = {"name": "Ermenistan Cumhuriyeti", "color": "a0507a", "leader": "Başbakan|Alexander Khatisian", "gdp": 1,
    "mil": {"personnel": 40000, "tank": 0, "afv": 0, "arty": 120, "air": 0, "sub": 0}}
D["Georgia"] = {"name": "Gürcistan Demokratik Cumhuriyeti", "color": "6aa08a", "leader": "Başkan|Noe Jordania", "gdp": 1,
    "mil": {"personnel": 30000, "tank": 0, "afv": 0, "arty": 60, "air": 0, "sub": 0}}
D["Azerbaijan"] = {"name": "Azerbaycan Cumhuriyeti", "color": "7a9a5a", "leader": "Başbakan|Nasib bey Yusifbeyli", "gdp": 2,
    "mil": {"personnel": 30000, "tank": 0, "afv": 0, "arty": 70, "air": 0, "sub": 0}}
for k in ("Hungary", "Czechia"):
    pass

setup = {
    "blocs": [{"name": "İtilaf Devletleri", "members": [UK, "France", "Italy", "Greece", "Belgium", "Japan", "Serbia", "Romania", "Poland", "Canada", "Australia", "New Zealand", "South Africa"],
        "emblem": {"shape": 5, "inner": 1, "symbol": "shield", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}}],
    "wars": [],
    "truce": [["Turkey", UK, 365], ["Turkey", "France", 365], ["Turkey", "Italy", 365]],
    "intro": "19 Mayıs 1919: Mondros Mütarekesi'nden sonra İstanbul İtilaf işgalinde; dört gün önce Yunan ordusu İzmir'e çıktı. Mustafa Kemal Paşa Samsun'da, Anadolu'da bir direniş örgütlemeye çalışıyor. Ya istiklal, ya ölüm.",
}

events = [
    {"y": 1919, "m": 6, "t": "Amasya Genelgesi: 'Vatanın bütünlüğü, milletin istiklali tehlikededir.' Anadolu'da direniş örgütleniyor.", "fx": [["stab", "Turkey", 3]]},
    {"y": 1919, "m": 8, "t": "Erzurum Kongresi toplandı: Doğu vilayetleri Millî Mücadele'de birleşti.", "fx": [["stab", "Turkey", 3]]},
    {"y": 1919, "m": 9, "t": "Sivas Kongresi: Anadolu ve Rumeli Müdafaa-i Hukuk Cemiyetleri tek çatıda toplandı; manda fikri reddedildi.", "fx": [["stab", "Turkey", 4]]},
    {"y": 1919, "m": 11, "t": "ABD Senatosu Versay Antlaşması'nı reddetti: Wilson'un manda planları çöktü.", "fx": [["stab", "United States of America", -3]]},
    {"y": 1920, "m": 1, "t": "Misak-ı Millî kabul edildi: Anadolu'nun ve Doğu Trakya'nın bölünmezliği ilan edildi.", "fx": [["stab", "Turkey", 3]]},
    {"y": 1920, "m": 3, "t": "İtilaf İstanbul'u resmen işgal etti, Meclis-i Mebusan basıldı; milletvekilleri Malta'ya sürülüyor.", "fx": [["stab", "Turkey", -3]]},
    {"y": 1920, "m": 4, "t": "Türkiye Büyük Millet Meclisi Ankara'da açıldı: 'Hâkimiyet kayıtsız şartsız milletindir.'", "fx": [["stab", "Turkey", 6]]},
    {"y": 1920, "m": 6, "t": "Güney Cephesi: Maraş, Antep ve Urfa halkı Fransız işgaline direniyor.", "fx": [["stab", "France", -3]]},
    {"y": 1920, "m": 9, "t": "Doğu Cephesi: Kâzım Karabekir'in ordusu Ermenistan'a karşı harekete geçti.", "fx": []},
    {"y": 1920, "m": 12, "t": "Gümrü Antlaşması: Doğu Cephesi kapandı, Kars Türkiye'ye döndü.", "fx": [["peace", "Turkey", "Armenia"], ["stab", "Turkey", 3]]},
    {"y": 1921, "m": 1, "t": "I. İnönü Muharebesi: Düzenli ordu Yunanlıları geri püskürttü.", "fx": [["stab", "Turkey", 5], ["stab", "Greece", -3]]},
    {"y": 1921, "m": 3, "t": "Moskova Antlaşması: Sovyet Rusya ile Ankara arasında dostluk ve yardım.", "fx": [["stab", "Turkey", 2]]},
    {"y": 1921, "m": 10, "t": "Ankara Antlaşması: Fransa Kilikya'yı boşaltmayı kabul etti.", "fx": [["peace", "Turkey", "France"], ["stab", "Turkey", 2]]},
    {"y": 1922, "m": 11, "t": "Saltanat kaldırıldı: Osmanlı hanedanının hükümdarlığı sona erdi.", "fx": [["stab", "Turkey", 4]]},
]

objectives = {
    "*": [{"id": "o1", "type": "survive", "text": "Dört yıl ayakta kal", "turns": 208},
          {"id": "o2", "type": "alliances", "text": "2 müttefik edin", "n": 2, "required": False}],
    "Turkey": [{"id": "t1", "type": "own_province", "province": 428, "text": "İzmir'i geri al"},
               {"id": "t2", "type": "own_province", "province": 430, "text": "Adana ve Kilikya'yı kurtar", "required": False},
               {"id": "t3", "type": "own_province", "province": 1949, "text": "Kars'ı geri al", "required": False},
               {"id": "t4", "type": "stability", "text": "İstikrarı 45 üzerinde tut", "n": 45}],
    "Greece": [{"id": "g1", "type": "own_province", "province": 428, "text": "İzmir'i elinde tut"},
               {"id": "g2", "type": "stability", "text": "İstikrarı 45 üzerinde tut", "n": 45}],
    "France": [{"id": "f1", "type": "own_province", "province": 430, "text": "Kilikya'yı elinde tut", "required": False},
               {"id": "f2", "type": "stability", "text": "İstikrarı 50 üzerinde tut", "n": 50}],
    "Italy": [{"id": "i1", "type": "own_province", "province": 429, "text": "Antalya bölgesini elinde tut", "required": False},
              {"id": "i2", "type": "stability", "text": "İstikrarı 45 üzerinde tut", "n": 45}],
    "Armenia": [{"id": "a1", "type": "own_province", "province": 420, "text": "Kars'ı elinde tut"}],
}

en = {
    "name": "War of Independence", "sub": "May 1919 – Turkey",
    "blurb": "May 1919: Istanbul is occupied by the Entente, Greece has landed at Izmir, France and Italy hold the south. Mustafa Kemal lands at Samsun to organise a resistance in Anatolia. Independence or death.",
    "setup_intro": "19 May 1919: after the Armistice of Mudros Istanbul is under Entente occupation; four days ago a Greek army landed at Izmir. Mustafa Kemal Pasha is at Samsun, trying to build a resistance in Anatolia. Independence or death.",
    "events": {
        "0": "Amasya Circular: 'The independence of the nation is in danger.' Resistance is organised across Anatolia.",
        "1": "The Erzurum Congress convened: the eastern provinces united in the national struggle.",
        "2": "Sivas Congress: the Anatolian and Rumelian defence-of-rights societies merged; the idea of a mandate was rejected.",
        "3": "The US Senate rejected the Treaty of Versailles: Wilson's mandate plans collapsed.",
        "4": "The National Pact was adopted: the indivisibility of Anatolia and Eastern Thrace was proclaimed.",
        "5": "The Entente formally occupied Istanbul and raided the Ottoman parliament; deputies are exiled to Malta.",
        "6": "The Grand National Assembly opened in Ankara: 'Sovereignty belongs unconditionally to the nation.'",
        "7": "Southern Front: the people of Maraş, Antep and Urfa are resisting the French occupation.",
        "8": "Eastern Front: Kâzım Karabekir's army moved against Armenia.",
        "9": "Treaty of Gümrü: the Eastern Front closed and Kars returned to Turkey.",
        "10": "First Battle of İnönü: the new regular army threw the Greeks back.",
        "11": "Treaty of Moscow: friendship and aid between Soviet Russia and Ankara.",
        "12": "Treaty of Ankara: France agreed to evacuate Cilicia.",
        "13": "The sultanate was abolished: the Ottoman dynasty's rule came to an end.",
    },
    "objectives": {"o1": "Survive four years", "o2": "Make 2 allies", "t1": "Recapture Izmir", "t2": "Liberate Adana and Cilicia",
        "t3": "Take back Kars", "t4": "Keep stability above 45", "g1": "Hold Izmir", "g2": "Keep stability above 45",
        "f1": "Hold Cilicia", "f2": "Keep stability above 50", "i1": "Hold the Antalya region", "i2": "Keep stability above 45", "a1": "Hold Kars"},
}

era = {
    "id": "ks1919", "name": "Kurtuluş Savaşı", "sub": "Mayıs 1919 – Türkiye", "base": "ww1", "family": "ww1", "icon": "uprising_banner", "mood": "war",
    "start_year": 1919, "start_doy": 138,
    "blurb": "Mayıs 1919: İstanbul İtilaf işgalinde, Yunan ordusu İzmir'e çıktı, güneyi Fransa ve İtalya tuttu. Mustafa Kemal Samsun'a çıkıp Anadolu'da direniş örgütlüyor. Ya istiklal, ya ölüm.",
    "suggest": ["Turkey", "Greece", "France", "Italy", "United Kingdom", "Armenia"],
    "look": {"shadow": [0.09, 0.07, 0.05], "mid": [0.56, 0.45, 0.29], "light": [0.96, 0.9, 0.74], "amount": 0.38, "vignette": 0.18, "grain": 0.012},
    "absorb": absb, "split": split, "capital": capital, "defs": D, "setup": setup, "free": True,
    "inherit_until": [9999, 1],
    "events": events, "objectives": objectives, "en": en,
}
p = os.path.join(ROOT, "data/eras/ks1919.json")
json.dump(era, open(p, "w"), ensure_ascii=False, indent=1)
ip = os.path.join(ROOT, "data/eras/index.json")
idx = json.load(open(ip))
if "ks1919" not in idx:
    idx.insert(idx.index("cw62") if "cw62" in idx else 0, "ks1919")
    json.dump(idx, open(ip, "w"), ensure_ascii=False)
print("ok", p)
