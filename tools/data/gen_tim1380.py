# -*- coding: utf-8 -*-
"""Timur Çağı: Haziran 1380 – Timur Horasan seferlerine çıkıyor. data/eras/tim1380.json üretir."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from pre_common import *
from pre_arsenal import timurid_1380

defs = {}
absorb = {}
split = []

def poly(host, tr, en, color, leader, gdp, m, abs_=None):
    defs[host] = D(tr, en, color, leader, gdp, m)
    if abs_:
        absorb[host] = list(abs_)

# ---------------------------------------------------------------- Timur'un dünyası (Orta Asya, İran, Hindistan)
poly("Uzbekistan", "Timur'un Maveraünnehir'i", "Timur's Transoxiana", "d0a030", "Emir|Timur", 14, mil(60000, 10000, 40000, 30, 0), ["Tajikistan", "Turkmenistan"])
poly("Kazakhstan", "Altın Orda (Toktamış)", "Golden Horde (Tokhtamysh)", "a8803a", "Han|Toktamış", 20, mil(150000, 12000, 120000, 20, 0), ["Ukraine"])
poly("Kyrgyzstan", "Moğulistan Hanlığı", "Moghulistan", "8a6a4a", "Han|Kamer ed-Din", 4, mil(30000, 2000, 25000, 0, 0))
poly("Mongolia", "Kuzey Yuan (Moğollar)", "Northern Yuan (Mongols)", "8f6a3a", "Han|Uskhal Han", 4, mil(50000, 4000, 40000, 0, 0))
poly("Iran", "Muzafferîler ve Serbedârlar", "Muzaffarids and Sarbadars", "3a7a5a", "Şah|Şah Şücâ", 14, mil(45000, 5000, 12000, 20, 0))
poly("Afghanistan", "Kartlar (Herat)", "Kart Dynasty (Herat)", "8a7a3a", "Melik|Gıyaseddin Pir Ali", 6, mil(30000, 3000, 8000, 10, 0))
poly("Azerbaijan", "Celâyirliler ve Kara Koyunlu", "Jalayirids and Kara Koyunlu", "5a7aa0", "Sultan|Hüseyin Celâyir", 14, mil(40000, 5000, 14000, 20, 0), ["Iraq", "Kuwait"])
poly("Georgia", "Gürcü Krallığı", "Kingdom of Georgia", "a05a7a", "Kral|VII. Bagrat", 5, mil(25000, 4000, 3000, 10, 0), ["Armenia"])
poly("India", "Delhi Sultanlığı (Tuğluk)", "Delhi Sultanate (Tughlaq)", "5a9a8a", "Sultan|Firuz Şah Tuğluk", 70, mil(120000, 6000, 20000, 20, 0))
poly("Sri Lanka", "Vijayanagara İmparatorluğu", "Vijayanagara Empire", "c05a2a", "İmparator|I. Harihara", 25, mil(80000, 5000, 15000, 10, 20))
poly("Nepal", "Bahmanî Sultanlığı", "Bahmani Sultanate", "7a5a9a", "Sultan|II. Muhammed Şah", 20, mil(50000, 3000, 12000, 20, 0))
poly("Bhutan", "Tibet ve Himalaya", "Tibet and the Himalayas", "a0507a", "Gyalpo|Phagmodrupa Hanedanı", 3, mil(15000, 1000, 3000, 0, 0))
poly("Bangladesh", "Bengal Sultanlığı (İlyas Şahî)", "Bengal Sultanate", "7a9a3a", "Sultan|İskender Şah", 15, mil(40000, 1000, 8000, 10, 30))
poly("Pakistan", "Sind ve Multan Beylikleri", "Sindh and Multan", "9aa05a", "Emir|Samma Hanedanı", 8, mil(25000, 1000, 6000, 5, 4))
poly("Maldives", "Maldiv Sultanlığı", "Maldives Sultanate", "5a9aa0", "Sultan|Hasan", 1, mil(3000, 0, 0, 0, 15))

# ---------------------------------------------------------------- Anadolu ve Ortadoğu
poly("Turkey", "Osmanlı Beyliği", "Ottoman Beylik", "b83a3a", "Bey|I. Murad", 12, mil(40000, 5000, 14000, 20, 20))
poly("North Macedonia", "Karamanoğulları", "Karamanids", "6a9a5a", "Bey|II. Alaeddin Ali", 5, mil(18000, 2000, 5000, 5, 5))
poly("Montenegro", "Doğu Anadolu Beylikleri (Eretna, Dulkadir, Ak Koyunlu)", "Eastern Anatolian Beyliks", "a06a4a", "Bey|Kadı Burhaneddin", 5, mil(20000, 2000, 6000, 5, 0))
poly("Greece", "Bizans İmparatorluğu", "Byzantine Empire", "7a4a9a", "İmparator|V. Ioannes Palaiologos", 8, mil(12000, 1500, 1000, 40, 25))
poly("Egypt", "Memlük Sultanlığı", "Mamluk Sultanate", "c0a03a", "Sultan|II. Şaban (Atabeg Barkuk)", 24, mil(90000, 12000, 18000, 40, 40),
     ["Syria", "Lebanon", "Israel", "Palestine", "Jordan"])
poly("Saudi Arabia", "Arap Kabile Emirlikleri", "Arabian Emirates", "b09a5a", "Emir|Kabile Şeyhleri", 3, mil(18000, 400, 8000, 0, 0))
poly("Yemen", "Resûlî Yemen", "Rasulid Yemen", "6a9a6a", "Sultan|El-Eşref II. İsmail", 4, mil(15000, 600, 3000, 5, 6))
poly("Oman", "Umman", "Oman", "9a5a4a", "İmam|Nebhanî Hanedanı", 2, mil(8000, 200, 1000, 0, 15))
poly("United Arab Emirates", "Hürmüz Krallığı", "Kingdom of Hormuz", "6a7aa0", "Şah|Hürmüz Meliki", 4, mil(6000, 300, 500, 5, 30), ["Qatar", "Bahrain"])

# ---------------------------------------------------------------- Avrupa
poly("Germany", "Kutsal Roma İmparatorluğu", "Holy Roman Empire", "8e8a7a", "Kral|IV. Wenzel", 40, mil(50000, 9000, 1500, 30, 10), ["Austria", "Slovenia", "Czechia", "Liechtenstein", "Luxembourg", "Switzerland"])
poly("France", "Fransa Krallığı", "Kingdom of France", "4f74b8", "Kral|V. Charles", 40, mil(60000, 14000, 2500, 40, 30), ["Monaco"])
poly("United Kingdom", "İngiltere Krallığı", "Kingdom of England", "d98ca0", "Kral|II. Richard", 18, mil(35000, 5000, 1500, 30, 40))
poly("Ireland", "İrlanda Lordlukları", "Irish Lordships", "3f8a4f", "Lord|Gaelik Beyler", 3, mil(10000, 600, 400, 0, 0))
poly("Spain", "Kastilya Krallığı", "Crown of Castile", "c9a227", "Kral|I. Juan", 22, mil(40000, 8000, 3000, 20, 30))
poly("Andorra", "Aragon Tacı", "Crown of Aragon", "d05a5a", "Kral|IV. Pedro", 16, mil(25000, 4000, 2000, 15, 60))
poly("Portugal", "Portekiz Krallığı", "Kingdom of Portugal", "2f6f4f", "Kral|I. Fernando", 7, mil(15000, 2500, 1500, 10, 25), ["Cabo Verde"])
poly("Italy", "İtalyan Şehir Devletleri (Venedik, Cenova, Milano, Papalık)", "Italian City-States", "5f9c6a", "Doge|Andrea Contarini", 45, mil(40000, 6000, 3000, 40, 160), ["San Marino"])
poly("Malta", "Napoli Krallığı (Anjou)", "Kingdom of Naples", "5a7aa0", "Kraliçe|I. Giovanna", 10, mil(15000, 2500, 1500, 10, 25))
poly("Belgium", "Burgonya ve Flandre", "Burgundy and Flanders", "8f6bb0", "Dük|Cesur Philippe", 18, mil(18000, 3000, 800, 15, 20), ["Netherlands"])
poly("Cyprus", "Kıbrıs Krallığı (Lüzinyan)", "Kingdom of Cyprus", "8a7ab0", "Kral|II. Peter", 3, mil(5000, 600, 300, 5, 15), ["N. Cyprus"])
poly("Denmark", "Danimarka ve Norveç", "Denmark and Norway", "b04545", "Kraliçe|Margrethe (naip)", 10, mil(18000, 2000, 500, 10, 50), ["Norway", "Iceland"])
poly("Sweden", "İsveç", "Sweden", "3c6fb0", "Kral|Albrecht", 6, mil(15000, 1500, 400, 5, 20), ["Finland"])
poly("Poland", "Polonya Krallığı", "Kingdom of Poland", "b04a4a", "Kral|I. Louis (Lajos)", 14, mil(30000, 5000, 3000, 10, 0))
poly("Hungary", "Macaristan Krallığı", "Kingdom of Hungary", "7a5aa0", "Kral|I. Lajos", 15, mil(40000, 6000, 8000, 15, 5), ["Slovakia", "Croatia"])
poly("Lithuania", "Litvanya Büyük Dukalığı", "Grand Duchy of Lithuania", "5a8a6a", "Büyük Dük|Jogaila (Jagiełło)", 12, mil(45000, 6000, 8000, 10, 0), ["Belarus"])
poly("Russia", "Moskova Büyük Dukalığı", "Grand Duchy of Moscow", "5a7a4a", "Büyük Knez|Dimitri Donskoy", 10, mil(40000, 7000, 3000, 5, 0))
poly("Greenland", "Novgorod Cumhuriyeti", "Novgorod Republic", "9a9a7a", "Posadnik|Veçe Meclisi", 8, mil(25000, 3000, 1500, 5, 5))
poly("Latvia", "Livonya ve Cermen Şövalyeleri", "Livonian and Teutonic Orders", "b9b9a8", "Üstat|Cermen Tarikatı", 6, mil(15000, 3000, 500, 15, 10), ["Estonia"])
poly("Romania", "Eflak ve Boğdan", "Wallachia and Moldavia", "b0a05a", "Voyvoda|I. Mircea", 5, mil(20000, 2000, 4000, 5, 0), ["Moldova"])
poly("Bulgaria", "Bulgar Çarlıkları (Tırnovo, Vidin)", "Bulgarian Tsardoms", "8a9a5a", "Çar|Ivan Şişman", 4, mil(18000, 2500, 2000, 5, 0))
poly("Serbia", "Sırp Devletleri (Lazar)", "Serbian Principalities (Lazar)", "7a8fb0", "Knez|Lazar Hrebeljanović", 5, mil(25000, 4000, 2000, 5, 0), ["Kosovo"])
poly("Bosnia and Herz.", "Bosna Krallığı", "Kingdom of Bosnia", "a0507a", "Kral|I. Tvrtko", 4, mil(20000, 2500, 1500, 5, 5))
poly("Albania", "Arnavut Beylikleri", "Albanian Principalities", "a03a3a", "Prens|Karl Thopia", 3, mil(10000, 800, 1500, 0, 5))

# ---------------------------------------------------------------- Kuzey Afrika
poly("Morocco", "Merînîler", "Marinids", "6a8a4a", "Sultan|Ebu'l-Abbas Ahmed", 8, mil(30000, 2000, 8000, 5, 15), ["W. Sahara"])
poly("Algeria", "Abdülvâdîler (Tlemsen)", "Zayyanids (Tlemcen)", "d05a3a", "Sultan|Ebu Hammu II", 4, mil(15000, 1000, 5000, 5, 6))
poly("Tunisia", "Hafsîler", "Hafsids", "8a9a5a", "Sultan|II. Ebu'l-Abbas", 5, mil(18000, 1200, 5000, 10, 15), ["Libya"])

# ---------------------------------------------------------------- Doğu ve Güneydoğu Asya
poly("China", "Ming İmparatorluğu", "Ming Empire", "d6b25e", "İmparator|Hongwu", 150, mil(1000000, 60000, 100000, 3000, 500))
poly("Japan", "Muromachi Japonyası", "Muromachi Japan", "e2a53a", "Şogun|Ashikaga Yoshimitsu", 28, mil(100000, 15000, 3000, 0, 120))
poly("South Korea", "Goryeo Krallığı", "Goryeo", "c8c8d0", "Kral|U", 10, mil(50000, 5000, 4000, 100, 60), ["North Korea"])
poly("Myanmar", "Ava ve Pegu (Birmanya)", "Ava and Pegu (Burma)", "b06a3a", "Kral|I. Swasawke", 8, mil(35000, 2000, 5000, 5, 15))
poly("Thailand", "Ayutthaya Krallığı", "Kingdom of Ayutthaya", "9a3a5a", "Kral|Borommaracha I", 8, mil(40000, 2000, 5000, 5, 20))
poly("Vietnam", "Dai Viet (Tran)", "Dai Viet (Tran)", "b0903a", "İmparator|Tran Phe De", 10, mil(45000, 2000, 4000, 10, 50))
poly("Laos", "Lan Xang Krallığı", "Lan Xang", "a05a2a", "Kral|Fa Ngum Hanedanı", 3, mil(18000, 400, 400, 0, 0))
poly("Cambodia", "Khmer Krallığı", "Khmer Kingdom", "8a6aa0", "Kral|Hanedan", 4, mil(18000, 600, 400, 0, 6))
poly("Malaysia", "Malay Sultanlıkları", "Malay Sultanates", "5aa08a", "Raja|Parameswara", 6, mil(15000, 200, 300, 10, 40), ["Singapore"])
poly("Brunei", "Brunei Sultanlığı", "Brunei Sultanate", "c0a03a", "Sultan|Muhammed Şah", 2, mil(4000, 80, 80, 5, 20))
poly("Indonesia", "Majapahit İmparatorluğu", "Majapahit Empire", "a07a3a", "Maharaja|Hayam Wuruk", 18, mil(50000, 400, 2000, 20, 120), ["Timor-Leste"])
poly("Philippines", "Filipin Beylikleri", "Philippine Polities", "6aa06a", "Datu|Konfederasyon", 3, mil(12000, 0, 0, 0, 15))
poly("Taiwan", "Tayvan Toplulukları", "Taiwanese Communities", "7aa08a", "Şef|Yerli Konseyi", 1, mil(3000, 0, 0, 0, 5))
poly("Papua New Guinea", "Melanezya ve Pasifik Toplulukları", "Melanesia and Pacific Communities", "8a8a6a", "Şef|Yerli Konseyi", 2, mil(8000, 0, 0, 0, 25),
     ["Solomon Is.", "Vanuatu", "Fiji", "Micronesia", "Marshall Is.", "Palau", "Nauru", "Kiribati", "Tuvalu", "Samoa", "Tonga"])
poly("Australia", "Aborjin Toplulukları", "Aboriginal Communities", "9a7a5a", "Şef|Yerli Konseyi", 2, mil(6000, 0, 0, 0, 5), ["New Zealand"])

# ---------------------------------------------------------------- Afrika
poly("Ethiopia", "Etiyopya (Süleymanî Hanedanı)", "Ethiopia (Solomonic Dynasty)", "5a8a5a", "Negus|I. Dawit", 8, mil(50000, 3000, 6000, 0, 0), ["Eritrea"])
poly("Somalia", "Ifat ve Adal Sultanlıkları", "Ifat and Adal Sultanates", "a0803a", "Sultan|Sa'd ed-Din Hanedanı", 3, mil(20000, 500, 5000, 0, 6), ["Somaliland", "Djibouti"])
poly("Sudan", "Nubya Krallıkları", "Nubian Kingdoms", "9a6a4a", "Kral|Dongola Hanedanı", 3, mil(15000, 800, 3000, 0, 0), ["S. Sudan"])
poly("Chad", "Kanem-Bornu", "Kanem-Bornu", "7a6a4a", "Mai|Kanem Hanedanı", 3, mil(20000, 1200, 4000, 0, 0), ["Central African Rep."])
poly("Mali", "Mali İmparatorluğu", "Mali Empire", "c0a05a", "Mansa|II. Mari Cata", 8, mil(40000, 2500, 6000, 0, 0), ["Mauritania", "Guinea", "Gambia", "Guinea-Bissau", "Senegal", "Sierra Leone", "Liberia"])
poly("Niger", "Songhay ve Mossi Devletleri", "Songhai and Mossi States", "b0905a", "Şia|Songhay Hanedanı", 5, mil(25000, 1000, 4000, 0, 0), ["Burkina Faso"])
poly("Nigeria", "Hausa Şehirleri ve Benin Krallığı", "Hausa City-States and Benin", "8a5a3a", "Oba|Benin Hanedanı", 6, mil(25000, 1000, 3000, 0, 0), ["Cameroon", "Benin", "Togo"])
poly("Ghana", "Akan Devletleri", "Akan States", "c09a3a", "Şef|Akan Konseyi", 4, mil(12000, 0, 400, 0, 0), ["Côte d'Ivoire"])
poly("Dem. Rep. Congo", "Kongo ve Luba Devletleri", "Kongo and Luba States", "5a7a5a", "Manikongo|Kongo Hanedanı", 5, mil(20000, 0, 200, 0, 0), ["Congo", "Gabon", "Angola", "Eq. Guinea", "São Tomé and Principe"])
poly("Tanzania", "Kilwa ve Swahili Kıyısı", "Kilwa and the Swahili Coast", "6a9a8a", "Sultan|Kilwa Hanedanı", 5, mil(10000, 0, 400, 5, 30), ["Kenya", "Comoros"])
poly("Uganda", "Bunyoro-Kitara ve Büyük Göller", "Bunyoro-Kitara and the Great Lakes", "7a8a4a", "Omukama|Bunyoro Hanedanı", 3, mil(18000, 0, 400, 0, 0), ["Rwanda", "Burundi"])
poly("Zimbabwe", "Büyük Zimbabve ve Güney Afrika", "Great Zimbabwe and Southern Africa", "8a7a4a", "Mwene|Zimbabve Hanedanı", 5, mil(18000, 0, 300, 0, 0),
     ["Mozambique", "Zambia", "Malawi", "Botswana", "Namibia", "South Africa", "Lesotho", "eSwatini"])
poly("Madagascar", "Madagaskar Krallıkları", "Kingdoms of Madagascar", "7a8a9a", "Kral|Yerel Hanedanlar", 3, mil(10000, 0, 0, 0, 10), ["Mauritius", "Seychelles"])

# ---------------------------------------------------------------- Amerika
poly("Mexico", "Mexica Şehir Devletleri", "Mexica City-States", "3a8a5a", "Tlatoani|Acamapichtli Hanedanı", 6, mil(40000, 0, 0, 0, 0))
poly("Guatemala", "Maya Şehir Devletleri", "Maya City-States", "5a9a6a", "Halach Uinic|Şehir Konseyleri", 3, mil(20000, 0, 0, 0, 5), ["Belize", "Honduras", "El Salvador", "Nicaragua", "Costa Rica", "Panama"])
poly("Peru", "İnka Şefliği (Cusco)", "Inca Chiefdom (Cusco)", "c05a3a", "Sapa Inka|Inti Roca Hanedanı", 6, mil(30000, 0, 0, 0, 5), ["Ecuador", "Bolivia", "Chile"])
poly("Colombia", "Muisca ve Karayip Şeflikleri", "Muisca and Caribbean Chiefdoms", "7a9a5a", "Zipa|Muisca Konfederasyonu", 3, mil(18000, 0, 0, 0, 5), ["Venezuela", "Guyana", "Suriname"])
poly("Brazil", "Tupi ve Guarani Toplulukları", "Tupi and Guarani Peoples", "4a9a4a", "Şef|Yerli Konseyi", 3, mil(25000, 0, 0, 0, 8), ["Paraguay", "Uruguay", "Argentina"])
poly("Cuba", "Antiller (Taíno Şeflikleri)", "The Antilles (Taino Chiefdoms)", "6aa08a", "Cacique|Taíno Şefleri", 3, mil(8000, 0, 0, 0, 10),
     ["Haiti", "Dominican Rep.", "Jamaica", "Bahamas", "Barbados", "Trinidad and Tobago", "Antigua and Barb.", "Dominica", "Grenada", "Saint Lucia", "St. Kitts and Nevis", "St. Vin. and Gren."])
poly("United States of America", "Kuzey Amerika Konfederasyonları", "North American Confederacies", "6a8a5a", "Şef|Konfederasyon Meclisi", 4, mil(25000, 0, 0, 0, 8))
poly("Canada", "Algonkin ve Irokua Toplulukları", "Algonquian and Iroquois Peoples", "5a8a8a", "Şef|Konfederasyon Meclisi", 3, mil(18000, 0, 0, 0, 8))

# ---------------------------------------------------------------- bölünmeler
# Anadolu (Turkey eyaletleri): Osmanlı: Bursa, İzmir, Bolu, Ankara, Afyon, Denizli
for pid in (434, 429, 430):
    split.append([pid, "Turkey", "North Macedonia", "own"])          # Karamanoğulları
for pid in (432, 433, 437, 435, 425):
    split.append([pid, "Turkey", "Montenegro", "own"])               # Doğu Anadolu beylikleri
split.append([423, "Turkey", "Greece", "own"])                       # Konstantinopolis
for pid in (420, 424, 440, 441, 439):
    split.append([pid, "Turkey", "Azerbaijan", "own"])               # Kara Koyunlu / Celâyirli
for pid in (421, 422):
    split.append([pid, "Turkey", "Egypt", "own"])                    # Memlük Halep
# kayıp ev sahipleri: Karaman ve Doğu beyliklerinin kendi (Balkan) eyaletleri Sırbistan'a
for host in ("North Macedonia", "Montenegro"):
    for pid in NAMES[host]["provs"]:
        split.append([pid, host, "Serbia", "own"])
# Hicaz Memlük'ün
split += [[835, "Saudi Arabia", "Egypt", "own"], [836, "Saudi Arabia", "Egypt", "own"]]
# Hindistan: Dekkan
for pid in (56, 57, 58, 59, 51):
    split.append([pid, "India", "Sri Lanka", "own"])
for pid in (66, 54):
    split.append([pid, "India", "Nepal", "own"])
split.append([36, "India", "Bangladesh", "own"])
for pid in NAMES["Nepal"]["provs"]:
    split.append([pid, "Nepal", "Bhutan", "own"])
split += [[1, "China", "Bhutan", "own"], [25, "China", "Bhutan", "own"], [0, "China", "Kyrgyzstan", "own"]]
# Napoli ve Sicilya/Sardinya
for pid in (545, 541, 542, 543, 544, 555):
    split.append([pid, "Italy", "Malta", "own"])
for pid in (547, 548):
    split.append([pid, "Italy", "Andorra", "own"])
# İspanya: Aragon
for pid in (645, 646, 647, 650):
    split.append([pid, "Spain", "Andorra", "own"])
# Ukrayna: kuzey ve batı Litvanya/Polonya'ya; step Altın Orda'da (Kazakhstan emer)
for pid in (682, 683, 684, 685, 686, 688):
    split.append([pid, "Ukraine", "Lithuania", "own"])
split.append([689, "Ukraine", "Poland", "own"])
# Rusya: Moskova çekirdeği, Novgorod toprakları, Litvanya sınırı; kalan doğu/güney/Sibirya Altın Orda'ya
MOS = {"Moskova", "Tver", "Yaroslavl", "Ryazan", "Nijniy Novgorod", "Kirov"}
NOV = {"Sankt Petersburg", "Leningrad", "Pskov", "Karelia", "Arkhangel'sk", "Murmansk", "Nenets", "Komi", "Vologda"}
LIT = {"Smolensk", "Bryansk"}
for pid in NAMES["Russia"]["provs"]:
    nm = PROVS[pid]["name"]
    if nm in MOS:
        continue
    split.append([pid, "Russia", "Greenland" if nm in NOV else ("Lithuania" if nm in LIT else "Kazakhstan"), "own"])
# Grönland'ın kendi eyaleti Danimarka'ya
for pid in NAMES["Greenland"]["provs"]:
    split.append([pid, "Greenland", "Denmark", "own"])

capital = {"Turkey": 427, "Uzbekistan": 847, "North Macedonia": 434, "Montenegro": 433, "Greece": 423, "Egypt": 378, "Iran": 477, "Azerbaijan": 766,
           "Sri Lanka": 59, "Nepal": 66, "Bhutan": 1, "Bangladesh": 36, "Kazakhstan": 250, "Greenland": 233, "Kyrgyzstan": 0, "Malta": 545,
           "Andorra": 645, "Russia": 277, "Lithuania": 271, "Poland": 689, "Spain": 657, "Afghanistan": None}
capital = {k: v for k, v in capital.items() if v is not None}

era = {
    "id": "tim1380", "name": "Timur Çağı", "sub": "Haziran 1380 – Demir Topal", "family": "pre", "icon": "crown", "mood": "war",
    "start_year": 1380, "start_doy": 160,
    "blurb": "Moğol dünyası parçalandı. Semerkant'ta Timur kendi imparatorluğunu kuruyor; Altın Orda, Memlükler, Osmanlı Beyliği, Ming ve Delhi sultanlığı karşısında bir bozkır emiri bütün Asya'yı sarsabilir.",
    "suggest": ["Uzbekistan", "Kazakhstan", "Turkey", "Egypt", "China", "Russia", "Azerbaijan", "India", "Poland", "Italy"],
    "look": {"shadow": [0.10, 0.07, 0.05], "mid": [0.55, 0.42, 0.27], "light": [0.95, 0.87, 0.68], "amount": 0.44, "vignette": 0.22, "grain": 0.016},
    "arsenal": None, "absorb": absorb, "split": split, "capital": capital, "defs": defs,
    "setup": {
        "blocs": [],
        "wars": [["Kazakhstan", "Russia"], ["Kazakhstan", "Lithuania"]],
        "truce": [["Egypt", "Azerbaijan", 40], ["Spain", "Portugal", 40], ["France", "United Kingdom", 30]],
        "intro": "Haziran 1380: Barlas beyi Timur, Semerkant'ta Çağatay hanları adına hüküm sürüyor. Moğol dünyası dağılmış; Altın Orda Rus knezliklerini cezalandırmaya hazırlanıyor, İran ve Horasan ise gelmekte olan bir fatihin gölgesinde bekliyor.",
    },
    "pop_f": {"Europe": 0.10, "Asia": 0.075, "Africa": 0.045, "North America": 0.012, "South America": 0.018, "Oceania": 0.008},
    "gdp_default": 0.007,
    "nukes": [], "carriers": {},
}
era["arsenal"] = timurid_1380()
era["arsenal"]["new"] = [k for k, v in era["arsenal"]["gate"].items() if v > 0]

EV = [
    (1380, 9, "Kulikovo Meydan Muharebesi: Moskova Knezi Dimitri, Altın Orda ordusuna karşı ilk büyük zaferini kazandı.", [["war", "Russia", "Kazakhstan"]]),
    (1381, 4, "Timur Horasan seferini başlattı; Herat'a doğru ilerleyen ordu Kartlar'ı kuşattı.", [["war", "Uzbekistan", "Afghanistan"]]),
    (1382, 8, "Toktamış Moskova'yı yaktı; Rus knezlikleri yeniden Altın Orda'ya vergi ödüyor.", [["stab", "Russia", -20]]),
    (1382, 11, "Macar-Polonya Kralı I. Lajos öldü; birlik dağılıyor.", [["stab", "Hungary", -10], ["stab", "Poland", -10]]),
    (1385, 8, "Krewo Birliği: Litvanya Dükü Jogaila Polonya Kraliçesi Jadwiga ile evlenerek iki devleti birleştirmeye gidiyor.", [["ally", "Poland", "Lithuania"]]),
    (1386, 11, "Timur Gürcistan ve Azerbaycan seferinde: Tiflis ele geçirildi.", [["war", "Uzbekistan", "Georgia"]]),
    (1387, 12, "İsfahan Timur'a direnince şehir halkı kılıçtan geçirildi; İran beylikleri korku içinde.", [["war", "Uzbekistan", "Iran"], ["stab", "Iran", -25]]),
    (1389, 6, "Kosova Meydan Muharebesi: Sultan I. Murad ile Knez Lazar'ın orduları karşılaştı; her iki lider de hayatını kaybetti.", [["war", "Turkey", "Serbia"], ["stab", "Serbia", -20]]),
    (1391, 6, "Kondurça Muharebesi: Timur, Toktamış'ın ordusunu bozkırda dağıttı.", [["war", "Uzbekistan", "Kazakhstan"]]),
    (1392, 8, "Joseon Hanedanı kuruldu: General Yi Seong-gye Goryeo tahtına çıktı.", [["stab", "South Korea", -10]]),
    (1395, 4, "Terek Muharebesi: Altın Orda'nın gücü kırıldı, Saray yakıldı.", [["stab", "Kazakhstan", -35]]),
    (1396, 9, "Niğbolu Muharebesi: Yıldırım Bayezid Haçlı ordusunu Tuna'da ezdi.", [["war", "Turkey", "Hungary"]]),
    (1398, 3, "Ming İmparatoru Hongwu vefat etti; veliaht torunu ile amcası arasında taht kavgası kaçınılmaz.", [["stab", "China", -12]]),
    (1398, 12, "Timur Delhi'yi aldı; Tuğluk Sultanlığı çöktü, şehir günlerce yağmalandı.", [["war", "Uzbekistan", "India"], ["stab", "India", -35]]),
    (1399, 7, "Ming'de Yongle Savaşı başladı: Prens Zhu Di, yeğeninin tahtına karşı ayaklandı.", [["stab", "China", -15]]),
    (1400, 10, "Timur Halep'i, ardından Şam'ı aldı; Memlük ordusu bozguna uğradı.", [["war", "Uzbekistan", "Egypt"], ["stab", "Egypt", -25]]),
    (1401, 6, "Bağdat Timur'un ordusunun önünde düştü.", [["stab", "Azerbaijan", -30]]),
    (1402, 7, "Ankara Muharebesi: Timur, Yıldırım Bayezid'i yendi ve esir aldı; Osmanlı Fetret Devri'ne girdi.", [["war", "Uzbekistan", "Turkey"], ["stab", "Turkey", -40]]),
    (1403, 3, "Yıldırım Bayezid esaret altında hayatını kaybetti; oğulları taht için çekişiyor.", [["stab", "Turkey", -10]]),
    (1404, 11, "Timur Çin seferi için Semerkant'tan yola çıktı; kışın Otrar'da hastalandı.", [["war", "Uzbekistan", "China"]]),
    (1405, 2, "Timur Otrar'da vefat etti; imparatorluğu oğulları ve torunları arasında bölünüyor.", [["stab", "Uzbekistan", -25]]),
]
era["events"] = [{"y": y, "m": m, "t": t, "fx": fx} for y, m, t, fx in EV]
era["leaders"] = {"horizon": 1405, "chain": {
    "Turkey": [[1389, 6, "Sultan|I. Bayezid (Yıldırım)"], [1403, 3, "Sultan|Süleyman Çelebi"], [1413, 7, "Sultan|I. Mehmed"]],
    "France": [[1380, 9, "Kral|VI. Charles"]],
    "China": [[1398, 6, "İmparator|Jianwen"], [1402, 7, "İmparator|Yongle"]],
    "Egypt": [[1382, 11, "Sultan|Barkuk"], [1399, 6, "Sultan|Ferec"]],
    "Hungary": [[1387, 3, "Kral|Zsigmond"]],
    "Poland": [[1384, 10, "Kraliçe|Jadwiga"]],
    "Lithuania": [[1386, 3, "Büyük Dük|II. Władysław Jagiełło"], [1392, 8, "Büyük Dük|Vytautas"]],
    "Russia": [[1389, 5, "Büyük Knez|I. Vasili"]],
    "United Kingdom": [[1399, 9, "Kral|IV. Henry"]],
    "Iran": [[1384, 6, "Emir|Zeynelabidin"]],
    "Kazakhstan": [[1395, 4, "Han|Timur Kutluğ"]],
    "India": [[1388, 9, "Sultan|II. Gıyaseddin Tuğluk"]],
    "Germany": [[1400, 8, "Kral|Rupert"]],
}}
era["objectives"] = {
    "*": [
        {"id": "o1", "type": "survive", "turns": 260, "text": "Beş yıl boyunca ayakta kal"},
        {"id": "o2", "type": "alliances", "n": 2, "text": "2 müttefik edin"},
        {"id": "o3", "type": "stability", "n": 55, "text": "İstikrarı 55 üzerinde tut", "required": False},
    ],
    "Uzbekistan": [
        {"id": "t1", "type": "own_capital", "country": "Iran", "text": "İran'ın merkezini fethet"},
        {"id": "t2", "type": "own_capital", "country": "India", "text": "Delhi'yi al"},
        {"id": "t3", "type": "own_capital", "country": "Turkey", "text": "Ankara'ya hâkim ol", "required": False},
        {"id": "t4", "type": "eliminate", "country": "Kazakhstan", "text": "Altın Orda'yı yık", "required": False},
    ],
    "Kazakhstan": [
        {"id": "k1", "type": "own_capital", "country": "Russia", "text": "Moskova'dan haraç tahsil et: şehri kontrol et"},
        {"id": "k2", "type": "cease_war", "with": "Uzbekistan", "text": "Timur ile barış yap"},
    ],
    "Turkey": [
        {"id": "o4", "type": "own_provinces", "n": 20, "text": "20 eyalete ulaş"},
        {"id": "o5", "type": "own_capital", "country": "Greece", "text": "Konstantinopolis'i al"},
    ],
    "Egypt": [
        {"id": "e1", "type": "own_capital", "country": "Syria", "text": "Şam'ı elinde tut"},
    ],
}
EN = {
    "name": "Age of Timur", "sub": "June 1380 – The Iron Lame",
    "blurb": "The Mongol world has shattered. In Samarkand, Timur builds his own empire; against the Golden Horde, the Mamluks, the Ottoman beylik, Ming China and the Delhi Sultanate, a steppe emir may shake all of Asia.",
    "setup_intro": "June 1380: Timur of the Barlas, ruling Samarkand in the name of Chagatai khans. The Mongol world is fragmented; the Golden Horde prepares to punish the Russian princes while Persia and Khorasan wait in the shadow of a conqueror to come.",
    "objectives": {"o1": "Stay alive for five years", "o2": "Make 2 allies", "o3": "Keep stability above 55", "t1": "Conquer the heart of Persia", "t2": "Take Delhi",
                   "t3": "Dominate Ankara", "t4": "Destroy the Golden Horde", "k1": "Collect tribute from Moscow: control the city", "k2": "Make peace with Timur",
                   "o4": "Reach 20 provinces", "o5": "Take Constantinople", "e1": "Hold Damascus"},
}
EN_EVENTS = [
    "Battle of Kulikovo: Dmitri of Moscow wins a first great victory against the Golden Horde.",
    "Timur begins his Khorasan campaign; his army besieges the Kartid capital Herat.",
    "Tokhtamysh burns Moscow; the Russian principalities again pay tribute to the Horde.",
    "Louis I of Hungary and Poland dies; the union begins to dissolve.",
    "Union of Krewo: Jogaila of Lithuania marries Queen Jadwiga of Poland, binding the two states.",
    "Timur campaigns in Georgia and Azerbaijan; Tbilisi falls.",
    "Isfahan resists Timur and is put to the sword; the Persian beyliks tremble.",
    "Battle of Kosovo: the armies of Sultan Murad I and Prince Lazar meet; both leaders die.",
    "Battle of the Kondurcha: Timur scatters Tokhtamysh's army on the steppe.",
    "The Joseon dynasty is founded: General Yi Seong-gye takes the Goryeo throne.",
    "Battle of the Terek: the power of the Golden Horde is broken and Sarai burned.",
    "Battle of Nicopolis: Bayezid the Thunderbolt crushes a Crusader army on the Danube.",
    "Emperor Hongwu of the Ming dies; a succession quarrel between his grandson and uncle is inevitable.",
    "Timur takes Delhi; the Tughlaq Sultanate collapses and the city is plundered for days.",
    "The Jingnan War begins in the Ming: Prince Zhu Di rises against his nephew's throne.",
    "Timur takes Aleppo and then Damascus; the Mamluk army is routed.",
    "Baghdad falls before Timur's army.",
    "Battle of Ankara: Timur defeats and captures Bayezid; the Ottomans enter the Interregnum.",
    "Bayezid dies in captivity; his sons quarrel over the throne.",
    "Timur sets out from Samarkand to invade China; he falls ill at Otrar in winter.",
    "Timur dies at Otrar; his empire is divided among sons and grandsons.",
]
EN["events"] = {str(i): t for i, t in enumerate(EN_EVENTS)}
era["en"] = EN

if __name__ == "__main__":
    probs, missing = validate(era)
    for p in probs:
        print("SORUN:", p)
    print("kapsanmayan:", missing)
    if not probs and not missing:
        path, n = write_era(era, {"titles": {}})
        print("yazıldı", path, "yeni i18n:", n)
