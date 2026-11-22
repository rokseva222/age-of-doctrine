# alt_axis62: "Mihver Dünyası, 1962" — Mihver Devletleri savaşı kazandı (kurgusal, alternatif tarih). Kullanım: python3 tools/data/gen_alt_axis62.py
import json, copy
BASE = json.load(open("data/eras/alt_cuba_hot.json"))
d = copy.deepcopy(BASE)
RU_W = [228,229,230,231,232,233,234,235,248,249,250,257,258,260,262,266,267,269,271,272,273,274,275,276,277,278,279,280,281,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,1110,1116,1117,1356,1357,1358,1359,1360,1361,1362,1384,1385,1386,1387,1388,1389,1390,1513,1625,1626,1627,1628,1629,1656,1657,1658,1659,1671,1672,1673,1674,1675,1676,1677,1678,1679,1725,1726,1727,1728,1738,1739,1740,1741,1842,1843,1844,1845,1846,1847,1848,1849,1850,1851,1852,1853,1854,1856,1857,1858,1859,1860,1861,1862,1863,1864,1865,1866,1867,1868,1869,1870,2122,2123,2124,2125,2126,2127,2128,2129,2454,2455,2456,2457,2458,2459,2460,2461,2462,2463,2636,2637,2638,2639,2640,2641,2642,2667,2668,2669,2670,2671,2672,2685,2686,2687,2688,2689,2690,2691,2692,2693,2694,2695,2718,2719,2720,2721,2722,2723,2724,2735,2736,2737,2738,2739]
RU_E = [236,238,239,240,241,251,252,253,256,261,270,1855]
US_EAST = [72,73,74,75,76,77,78,85,86,87,88,89,90,91,92,93,94,95,96,97,98,111,112,113,115,116,117,118,119]
US_ISL = [83,100,120,121,1813,1821,1831]
US_MID = [68,69,70,71,79,81,82,84,101,102,104,105,106,107,108,109,110,114]
US_WEST = [67,80,99,103]

d["id"] = "alt_axis62"
d["name"] = "Mihver Dünyası"
d["sub"] = "1962 – Alternatif"
d["base"] = "cw62"
d["icon"] = "flag"
d["mood"] = "tense"
d["start_year"] = 1962
d["start_doy"] = 120
d["blurb"] = "Mihver Devletleri savaşı kazandı. Almanya Avrupa'yı ve Rusya'nın batısını, Japonya Pasifik'i ve Sibirya'nın doğusunu elinde tutuyor; Amerika ikiye bölündü, Kayalık Dağlar'da kırılgan bir tarafsız bölge kaldı. Berlin'de yaşlanan rejimin ardıl kavgası, Tokyo'da genişleme hırsı: iki imparatorluk arasındaki soğuk savaş her an sıcağa dönebilir."
d["suggest"] = ["Germany", "Japan", "United Kingdom", "Russia", "Italy"]
sc = d["setup"]
sc["blocs"] = [{"name": "Mihver Düzeni", "members": ["Germany", "Italy", "Hungary", "Romania", "Bulgaria", "Spain"], "emblem": {"shape": 0, "inner": 2, "symbol": "star", "c1": "7a1f1f", "c2": "1b1b1b", "c3": "ece6d6"}}]
sc["wars"] = []
sc["truce"] = []
sc["cold"] = [["Germany", "Japan"]]
sc["intro"] = "1962: Dünya Mihver'in. Berlin ile Tokyo arasındaki sınır Rus topraklarında ve Kuzey Amerika'da çiziliyor; kimse bu bölünmenin kalıcı olduğundan emin değil."
sc["stability"] = {"Russia": -12, "Germany": -3}
sc["rename"] = {
    "Germany": {"name": "Büyük Alman Reich'ı", "leader": "Reich Şansölyesi|Martin Holz", "color": "5a1010"},
    "Russia": {"name": "Rus Kalıntı Devleti", "leader": "Başkan|Aleksandr Voronov", "color": "6b6b3a"},
    "Japan": {"name": "Japon İmparatorluğu"},
}
sc["transfer"] = [[p, "Russia", "Germany", "own"] for p in RU_W] + [[p, "Russia", "Japan", "own"] for p in RU_E]
sc["custom"] = [
    {"name": "Reich Amerikası", "pids": US_EAST, "capital": 95, "tech": 0.7, "aggression": 0.1, "colors": ["5a1010", "1b1b1b", "ece6d6"], "war": False, "leader": "Reich Valisi|Karl Brenner", "troops": 140000, "gold_mult": 1.2, "play": False, "flag": "A:de"},
    {"name": "Japon Pasifik Devletleri", "pids": US_WEST + US_ISL, "capital": 80, "tech": 0.7, "aggression": 0.1, "colors": ["f4efe4", "bc002d", "1b1b1b"], "war": False, "leader": "Genel Vali|Hiroshi Kondo", "troops": 110000, "gold_mult": 1.2, "play": False, "flag": "A:jp"},
    {"name": "Kayalık Dağlar Tarafsız Bölgesi", "pids": US_MID, "capital": 104, "tech": 0.6, "aggression": 0.1, "colors": ["2f4f4f", "c9b98a", "ece6d6"], "war": False, "leader": "Başkan|Samuel Whitaker", "troops": 60000, "gold_mult": 1.0, "play": False, "flag": "I:alt_neutral_zone"},
]
d["events"] = [
    {"y": 1962, "m": 7, "t": "Berlin'de yaşlanan Führer'in sağlığı hakkında söylentiler artıyor; ardıl kavgası saray koridorlarına taştı.", "fx": [["stab", "Germany", -4]]},
    {"y": 1962, "m": 10, "t": "Kayalık Dağlar sınırında Alman ve Japon devriyeleri karşılaştı; Tarafsız Bölge'de gerginlik yükseldi.", "fx": [["stab", "Japan", -2]]},
    {"y": 1963, "m": 2, "t": "Sibirya'daki Rus direniş grupları Alman ve Japon karakollarına saldırdı; iki imparatorluk birbirini suçluyor.", "fx": [["stab", "Russia", -3]]},
]
d["objectives"] = {
    "*": [{"id": "o1", "type": "survive", "text": "Bir yıl ayakta kal", "turns": 52}, {"id": "o2", "type": "alliances", "text": "3 müttefik edin", "n": 3, "required": False}],
    "Germany": [{"id": "g1", "type": "stability", "text": "İstikrarı 50 üzerinde tut", "n": 50}, {"id": "g2", "type": "cease_war", "text": "Japonya ile savaş çıkmasını önle", "with": "Japan"}],
    "Japan": [{"id": "j1", "type": "stability", "text": "İstikrarı 50 üzerinde tut", "n": 50}, {"id": "j2", "type": "cease_war", "text": "Almanya ile savaş çıkmasını önle", "with": "Germany"}],
    "United Kingdom": [{"id": "u1", "type": "stability", "text": "İstikrarı 50 üzerinde tut", "n": 50}],
}
d["en"] = {
    "name": "The Axis World", "sub": "1962 – Alternate",
    "blurb": "The Axis won the war. Germany holds Europe and western Russia, Japan holds the Pacific and eastern Siberia; America has been split in two with a fragile neutral zone left in the Rockies. In Berlin the ageing regime fights over succession, in Tokyo ambition grows: the cold war between the two empires can turn hot at any moment.",
    "setup_intro": "1962: The world belongs to the Axis. The border between Berlin and Tokyo is being drawn across Russian lands and North America, and nobody is sure the division will last.",
    "events": {"0": "Rumours about the ageing Führer's health grow in Berlin; the succession struggle has spilled into the palace corridors.",
               "1": "German and Japanese patrols met on the Rocky Mountain border; tension rises in the Neutral Zone.",
               "2": "Russian resistance groups in Siberia attacked German and Japanese outposts; the two empires blame each other."},
    "objectives": {"o1": "Survive one year", "o2": "Make 3 allies", "g1": "Keep stability above 50", "g2": "Prevent war with Japan", "j1": "Keep stability above 50", "j2": "Prevent war with Germany", "u1": "Keep stability above 50"},
}
json.dump(d, open("data/eras/alt_axis62.json", "w"), ensure_ascii=False, indent=1)
open("data/eras/alt_axis62.json", "a").write("\n")
idx = json.load(open("data/eras/index.json"))
if "alt_axis62" not in idx:
    idx.insert(idx.index("alt_berlin_hot") + 1, "alt_axis62")
    open("data/eras/index.json", "w").write(json.dumps(idx, ensure_ascii=False))
print("ok", len(sc["transfer"]))
