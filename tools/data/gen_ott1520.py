# -*- coding: utf-8 -*-
"""Osmanlı Çağı: Eylül 1520 – Kanuni Sultan Süleyman tahta çıkıyor. data/eras/ott1520.json üretir."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from pre_common import *
from pre_arsenal import ottoman_1520

defs = {}
absorb = {}
split = []

def poly(host, tr, en, color, leader, gdp, m, abs_=None):
    defs[host] = D(tr, en, color, leader, gdp, m)
    if abs_:
        absorb[host] = list(abs_)

# ---------------------------------------------------------------- Akdeniz ve Avrupa
poly("Turkey", "Osmanlı Devleti", "Ottoman Empire", "b83a3a", "Padişah|I. Süleyman", 60, mil(150000, 25000, 40000, 600, 250),
     ["Greece", "Bulgaria", "Serbia", "North Macedonia", "Albania", "Bosnia and Herz.", "Kosovo", "Montenegro", "Syria", "Lebanon", "Israel", "Palestine", "Jordan", "Egypt"])
poly("Spain", "Habsburg Hanedanı", "House of Habsburg", "c9a227", "İmparator|V. Karl", 70, mil(120000, 14000, 8000, 900, 220),
     ["Austria", "Slovenia", "Netherlands", "Belgium", "Luxembourg", "Andorra", "Liechtenstein"])
poly("France", "Fransa Krallığı", "Kingdom of France", "4f74b8", "Kral|I. François", 55, mil(90000, 16000, 6000, 700, 120))
poly("Germany", "Kutsal Roma Prenslikleri", "Holy Roman Princes", "8e8a7a", "Seçmen Prens|Bilge Frederik", 45, mil(70000, 9000, 3000, 500, 20), ["Switzerland"] if False else None)
poly("Switzerland", "İsviçre Konfederasyonu", "Swiss Confederacy", "d04a4a", "Landammann|Kantonlar Meclisi", 8, mil(25000, 500, 200, 60, 0))
poly("Italy", "İtalyan Devletleri", "Italian States", "5f9c6a", "Doge|Antonio Grimani", 50, mil(60000, 8000, 5000, 500, 260),
     ["Cyprus", "N. Cyprus", "San Marino", "Monaco"])
poly("Malta", "Aziz Yuhanna Şövalyeleri", "Knights of St John", "c0392b", "Büyük Üstat|Villiers de L'Isle-Adam", 3, mil(6000, 600, 0, 120, 30))
poly("Portugal", "Portekiz Krallığı", "Kingdom of Portugal", "2f6f4f", "Kral|I. Manuel", 14, mil(30000, 3000, 1500, 400, 190), ["Cabo Verde", "São Tomé and Principe", "Guinea-Bissau"])
poly("United Kingdom", "İngiltere Krallığı", "Kingdom of England", "d98ca0", "Kral|VIII. Henry", 20, mil(30000, 4000, 1500, 250, 80))
poly("Ireland", "İrlanda Lordlukları", "Irish Lordships", "3f8a4f", "Lord|Gaelik Beyler", 3, mil(12000, 800, 500, 0, 0))
poly("Denmark", "Danimarka-Norveç", "Denmark-Norway", "b04545", "Kral|II. Christian", 12, mil(25000, 2500, 800, 250, 60), ["Norway", "Iceland", "Greenland"])
poly("Sweden", "İsveç", "Sweden", "3c6fb0", "Naip|Sten Sture", 6, mil(18000, 1500, 500, 150, 30), ["Finland"])
poly("Poland", "Polonya-Litvanya", "Poland-Lithuania", "b04a4a", "Kral|I. Zygmunt", 22, mil(50000, 9000, 12000, 300, 0), ["Lithuania", "Belarus"])
poly("Hungary", "Macaristan ve Bohemya", "Hungary and Bohemia", "7a5aa0", "Kral|II. Lajos", 18, mil(40000, 7000, 8000, 300, 10), ["Slovakia", "Croatia", "Czechia"])
poly("Russia", "Moskova Büyük Knezliği", "Grand Duchy of Moscow", "5a7a4a", "Büyük Knez|III. Vasili", 16, mil(60000, 12000, 8000, 250, 0))
poly("Latvia", "Livonya Tarikatı", "Livonian Order", "b9b9a8", "Üstat|Wolter von Plettenberg", 3, mil(8000, 1200, 200, 60, 0), ["Estonia"])
poly("Romania", "Eflak ve Boğdan", "Wallachia and Moldavia", "b0a05a", "Voyvoda|Neagoe Basarab", 6, mil(30000, 3000, 6000, 40, 0), ["Moldova"])
poly("Georgia", "Gürcü Krallıkları", "Georgian Kingdoms", "a05a7a", "Kral|Gürcü Hanedanları", 4, mil(15000, 3000, 2000, 30, 0))
poly("Ukraine", "Kırım Hanlığı ve Bozkır", "Crimean Khanate and Steppe", "c08a3c", "Han|I. Mehmed Giray", 5, mil(40000, 2000, 30000, 30, 10))

# ---------------------------------------------------------------- Ortadoğu
poly("Iran", "Safevî Devleti", "Safavid Empire", "3a7a5a", "Şah|I. İsmail", 22, mil(70000, 20000, 15000, 150, 10), ["Iraq", "Azerbaijan", "Armenia"])
poly("Afghanistan", "Kâbil Beyliği", "Principality of Kabul", "8a7a3a", "Emir|Babür", 4, mil(15000, 3000, 6000, 20, 0))
poly("Uzbekistan", "Şeybânî Özbek Hanlığı", "Shaybanid Khanate", "d0a030", "Han|Köçkünçü Han", 8, mil(45000, 6000, 20000, 40, 0), ["Tajikistan", "Turkmenistan"])
poly("Kazakhstan", "Kazak Hanlığı ve Bozkır Hanlıkları", "Kazakh Khanate and Steppe Khanates", "a8803a", "Han|Kasım Han", 5, mil(60000, 3000, 40000, 10, 0), ["Kyrgyzstan"])
poly("Mongolia", "Moğol Hanlıkları", "Mongol Khanates", "8f6a3a", "Han|Dayan Han", 3, mil(50000, 4000, 30000, 0, 0))
poly("Saudi Arabia", "Arap Kabile Emirlikleri", "Arabian Emirates", "b09a5a", "Emir|Kabile Şeyhleri", 3, mil(20000, 500, 8000, 0, 0))
poly("Yemen", "Tahirî ve Zeydî Yemen", "Tahirid and Zaydi Yemen", "6a9a6a", "Sultan|Âmir bin Abdülvehhab", 3, mil(15000, 600, 3000, 20, 6))
poly("Oman", "Umman", "Oman", "9a5a4a", "İmam|Ömân Seçilmiş İmamı", 2, mil(8000, 200, 1000, 10, 15))
poly("United Arab Emirates", "Hürmüz Krallığı", "Kingdom of Hormuz", "6a7aa0", "Şah|Türan Şah", 4, mil(6000, 300, 500, 40, 30), ["Qatar", "Bahrain", "Kuwait"])

# ---------------------------------------------------------------- Kuzey Afrika
poly("Algeria", "Cezayir (Barbaros)", "Algiers (Barbarossa)", "d05a3a", "Beylerbeyi|Barbaros Hayreddin", 3, mil(10000, 1200, 2000, 80, 40))
poly("Tunisia", "Hafsîler", "Hafsids", "8a9a5a", "Sultan|Mevlây Hasan", 3, mil(12000, 800, 4000, 40, 15), ["Libya"])
poly("Morocco", "Vattasîler ve Sa'dîler", "Wattasids and Saadis", "6a8a4a", "Sultan|Muhammed eş-Şeyh", 5, mil(20000, 1200, 6000, 40, 10), ["W. Sahara"])

# ---------------------------------------------------------------- Güney ve Doğu Asya
poly("China", "Ming İmparatorluğu", "Ming Empire", "d6b25e", "İmparator|Zhengde", 140, mil(800000, 60000, 80000, 4000, 400))
poly("Japan", "Sengoku Japonyası", "Sengoku Japan", "e2a53a", "Şogun|Ashikaga Yoshitane", 35, mil(150000, 20000, 5000, 0, 200))
poly("South Korea", "Joseon Krallığı", "Joseon Korea", "c8c8d0", "Kral|Jungjong", 12, mil(60000, 8000, 5000, 400, 100), ["North Korea"])
poly("India", "Delhi Sultanlığı (Lodî)", "Delhi Sultanate (Lodi)", "5a9a8a", "Sultan|İbrahim Lodî", 55, mil(100000, 6000, 20000, 60, 0))
poly("Sri Lanka", "Vijayanagara İmparatorluğu", "Vijayanagara Empire", "c05a2a", "İmparator|Krişnadevaraya", 40, mil(120000, 12000, 20000, 150, 30))
poly("Bangladesh", "Bengal Sultanlığı", "Bengal Sultanate", "7a9a3a", "Sultan|Nusret Şah", 15, mil(40000, 2000, 8000, 40, 40))
poly("Pakistan", "Sind ve Multan Beylikleri", "Sindh and Multan", "9aa05a", "Emir|Şah Hüseyin Arğun", 8, mil(25000, 1500, 6000, 10, 6))
poly("Nepal", "Dekkan Sultanlıkları (Bahmanî mirası)", "Deccan Sultanates", "7a5a9a", "Sultan|Kutb Şah", 20, mil(50000, 4000, 10000, 60, 0))
poly("Bhutan", "Tibet ve Himalaya", "Tibet and the Himalayas", "a0507a", "Gyalpo|Phagmodrupa Hanedanı", 3, mil(18000, 1500, 3000, 0, 0))
poly("Maldives", "Maldiv Sultanlığı", "Maldives Sultanate", "5a9aa0", "Sultan|Hasan IX", 1, mil(3000, 0, 0, 5, 20))
poly("Myanmar", "Toungoo ve Ava (Birmanya)", "Toungoo and Ava (Burma)", "b06a3a", "Kral|Mingyinyo", 10, mil(45000, 3000, 6000, 40, 20))
poly("Thailand", "Ayutthaya Krallığı", "Kingdom of Ayutthaya", "9a3a5a", "Kral|Ramathibodi II", 9, mil(50000, 3000, 6000, 40, 30))
poly("Vietnam", "Dai Viet (Le Hanedanı)", "Dai Viet (Le Dynasty)", "b0903a", "İmparator|Le Tuong Duc", 12, mil(60000, 3000, 5000, 30, 60), ["Laos"] if False else None)
poly("Laos", "Lan Xang Krallığı", "Lan Xang", "a05a2a", "Kral|Photisarath", 3, mil(20000, 600, 400, 10, 0))
poly("Cambodia", "Khmer Krallığı", "Khmer Kingdom", "8a6aa0", "Kral|Ang Chan", 4, mil(20000, 800, 500, 10, 10))
poly("Malaysia", "Malay Sultanlıkları (Malakka mirası)", "Malay Sultanates", "5aa08a", "Sultan|Mahmud Şah", 8, mil(20000, 300, 400, 80, 50), ["Singapore"])
poly("Brunei", "Brunei Sultanlığı", "Brunei Sultanate", "c0a03a", "Sultan|Bolkiah", 2, mil(5000, 100, 100, 20, 30))
poly("Indonesia", "Demak ve Nusantara Sultanlıkları", "Demak and Nusantara Sultanates", "a07a3a", "Sultan|Trenggana", 18, mil(50000, 500, 2000, 80, 150), ["Timor-Leste"])
poly("Philippines", "Filipin Beylikleri", "Philippine Polities", "6aa06a", "Datu|Konfederasyon", 3, mil(15000, 0, 0, 5, 20))
poly("Taiwan", "Tayvan Toplulukları", "Taiwanese Communities", "7aa08a", "Şef|Yerli Konseyi", 1, mil(4000, 0, 0, 0, 6))
poly("Papua New Guinea", "Melanezya ve Pasifik Toplulukları", "Melanesia and Pacific Communities", "8a8a6a", "Şef|Yerli Konseyi", 2, mil(10000, 0, 0, 0, 30),
     ["Solomon Is.", "Vanuatu", "Fiji", "Micronesia", "Marshall Is.", "Palau", "Nauru", "Kiribati", "Tuvalu", "Samoa", "Tonga"])
poly("Australia", "Aborjin Toplulukları", "Aboriginal Communities", "9a7a5a", "Şef|Yerli Konseyi", 2, mil(8000, 0, 0, 0, 5), ["New Zealand"])

# ---------------------------------------------------------------- Afrika
poly("Ethiopia", "Etiyopya İmparatorluğu", "Ethiopian Empire", "5a8a5a", "Negus|Lebna Dengel", 8, mil(60000, 4000, 8000, 10, 0), ["Eritrea"])
poly("Somalia", "Adal Sultanlığı ve Somali Şehirleri", "Adal Sultanate and Somali Cities", "a0803a", "Sultan|Ebubekir bin Muhammed", 3, mil(25000, 800, 6000, 10, 8), ["Somaliland", "Djibouti"])
poly("Sudan", "Funj Sultanlığı", "Funj Sultanate", "9a6a4a", "Sultan|Amara Dunqas", 4, mil(20000, 1000, 4000, 0, 0), ["S. Sudan"])
poly("Chad", "Bornu İmparatorluğu", "Bornu Empire", "7a6a4a", "Mai|İdris Katarkamabi", 3, mil(25000, 1500, 5000, 0, 0), ["Central African Rep."])
poly("Mali", "Songhay İmparatorluğu", "Songhai Empire", "c0a05a", "Askia|Askia Muhammed", 8, mil(50000, 3000, 8000, 0, 0), ["Mauritania", "Burkina Faso", "Niger", "Guinea", "Gambia", "Senegal", "Sierra Leone", "Liberia"])
poly("Nigeria", "Hausa Şehirleri ve Benin Krallığı", "Hausa City-States and Benin", "8a5a3a", "Oba|Esigie", 6, mil(30000, 1500, 4000, 0, 0), ["Cameroon", "Benin", "Togo"])
poly("Ghana", "Akan Devletleri", "Akan States", "c09a3a", "Şef|Akan Konseyi", 4, mil(15000, 0, 500, 0, 0), ["Côte d'Ivoire"])
poly("Dem. Rep. Congo", "Kongo Krallığı", "Kingdom of Kongo", "5a7a5a", "Manikongo|I. Afonso", 5, mil(25000, 0, 200, 0, 0), ["Congo", "Gabon", "Angola", "Eq. Guinea"])
poly("Tanzania", "Kilwa ve Swahili Kıyısı", "Kilwa and the Swahili Coast", "6a9a8a", "Sultan|Swahili Şehir Meclisi", 4, mil(10000, 0, 500, 20, 25), ["Kenya", "Comoros"])
poly("Uganda", "Bunyoro-Kitara ve Büyük Göller", "Bunyoro-Kitara and the Great Lakes", "7a8a4a", "Omukama|Bunyoro Hanedanı", 3, mil(20000, 0, 500, 0, 0), ["Rwanda", "Burundi"])
poly("Zimbabwe", "Mutapa ve Güney Afrika Krallıkları", "Mutapa and Southern African Kingdoms", "8a7a4a", "Mwene|Mutapa Mahenji", 4, mil(20000, 0, 500, 0, 0),
     ["Mozambique", "Zambia", "Malawi", "Botswana", "Namibia", "South Africa", "Lesotho", "eSwatini"])
poly("Madagascar", "Madagaskar Krallıkları", "Kingdoms of Madagascar", "7a8a9a", "Kral|Yerel Hanedanlar", 3, mil(12000, 0, 0, 0, 15), ["Mauritius", "Seychelles"])

# ---------------------------------------------------------------- Amerika
poly("Mexico", "Aztek Üçlü İttifakı", "Aztec Triple Alliance", "3a8a5a", "Tlatoani|II. Moctezuma", 8, mil(60000, 0, 0, 0, 0))
poly("Guatemala", "Maya Şehir Devletleri", "Maya City-States", "5a9a6a", "Halach Uinic|Şehir Konseyleri", 3, mil(25000, 0, 0, 0, 5), ["Belize", "Honduras", "El Salvador", "Nicaragua", "Costa Rica", "Panama"])
poly("Peru", "İnka İmparatorluğu", "Inca Empire", "c05a3a", "Sapa Inka|Huayna Capac", 9, mil(80000, 0, 0, 0, 10), ["Ecuador", "Bolivia", "Chile"])
poly("Colombia", "Muisca ve Karayip Şeflikleri", "Muisca and Caribbean Chiefdoms", "7a9a5a", "Zipa|Muisca Konfederasyonu", 3, mil(20000, 0, 0, 0, 5), ["Venezuela", "Guyana", "Suriname"])
poly("Brazil", "Tupi ve Guarani Toplulukları", "Tupi and Guarani Peoples", "4a9a4a", "Şef|Yerli Konseyi", 3, mil(30000, 0, 0, 0, 10), ["Paraguay", "Uruguay", "Argentina"])
poly("Cuba", "Antiller (Taíno ve İspanyol Üsleri)", "The Antilles (Taino and Spanish Outposts)", "6aa08a", "Cacique|Diego Colón", 3, mil(8000, 0, 0, 5, 12),
     ["Haiti", "Dominican Rep.", "Jamaica", "Bahamas", "Barbados", "Trinidad and Tobago", "Antigua and Barb.", "Dominica", "Grenada", "Saint Lucia", "St. Kitts and Nevis", "St. Vin. and Gren."])
poly("United States of America", "Kuzey Amerika Konfederasyonları", "North American Confederacies", "6a8a5a", "Şef|Konfederasyon Meclisi", 4, mil(30000, 0, 0, 0, 10))
poly("Canada", "Algonkin ve Irokua Toplulukları", "Algonquian and Iroquois Peoples", "5a8a8a", "Şef|Konfederasyon Meclisi", 3, mil(20000, 0, 0, 0, 10))

# ---------------------------------------------------------------- bölünmeler
# Habsburg İtalya: Napoli ve Sicilya (Aragon) ve Sardinya
for pid in (545, 541, 542, 543, 544, 555, 547, 548):
    split.append([pid, "Italy", "Spain", "own"])
# Yemen ve Hicaz: Hicaz Osmanlı'nın
split += [[835, "Saudi Arabia", "Turkey", "own"], [836, "Saudi Arabia", "Turkey", "own"]]
# Portekiz Goa'sı
split.append([55, "India", "Portugal", "own"])
# Dekkan ve Güney Hindistan
for pid in (56, 57, 58, 59, 51):
    split.append([pid, "India", "Sri Lanka", "own"])
for pid in (66, 54):
    split.append([pid, "India", "Nepal", "own"])
split.append([36, "India", "Bangladesh", "own"])
# Nepal'in kendi eyaletleri Tibet'e (Nepal sahibi Dekkan'ı tutar)
for pid in NAMES["Nepal"]["provs"]:
    split.append([pid, "Nepal", "Bhutan", "own"])
# Tibet
split += [[1, "China", "Bhutan", "own"], [25, "China", "Bhutan", "own"]]
# Ukrayna kuzeyi Polonya-Litvanya'ya (step Kırım Hanlığı'nda kalır)
for pid in (682, 683, 684, 685, 686, 688, 689):
    split.append([pid, "Ukraine", "Poland", "own"])
# Rusya: yalnızca Moskova çekirdeği + Kuzey Rusya Moskova'da; doğu/güney/Sibirya step hanlıklarına
RUS_CORE = {"Moskova", "Tver", "Yaroslavl", "Ryazan", "Nijniy Novgorod", "Vologda", "Smolensk", "Bryansk", "Sankt Petersburg", "Leningrad", "Pskov",
            "Karelia", "Arkhangel'sk", "Murmansk", "Nenets", "Komi", "Kirov", "Voronezh"}
for pid in NAMES["Russia"]["provs"]:
    if PROVS[pid]["name"] not in RUS_CORE:
        split.append([pid, "Russia", "Kazakhstan", "own"])

capital = {"Turkey": 423, "Iran": 459, "Russia": 277, "Sri Lanka": 59, "Nepal": 66, "Bhutan": 1, "Bangladesh": 36, "Ukraine": 693, "Poland": 689}

era = {
    "id": "ott1520", "name": "Osmanlı Çağı", "sub": "Eylül 1520 – Kanuni Süleyman", "family": "pre", "icon": "crown", "mood": "war",
    "start_year": 1520, "start_doy": 263,
    "blurb": "Yavuz Sultan Selim öldü; genç Süleyman tahtta. Habsburglar, Fransa, Safevîler, Moskova, Ming ve Dekkan sultanlıkları dünyayı paylaşıyor. Yeniçeri fitilli tüfekleri, kuşatma topları ve kadırgalarla bir imparatorluğun çağı başlıyor.",
    "suggest": ["Turkey", "Spain", "Iran", "France", "Poland", "Russia", "Italy", "China", "Hungary", "Uzbekistan"],
    "look": {"shadow": [0.10, 0.07, 0.04], "mid": [0.58, 0.44, 0.26], "light": [0.97, 0.89, 0.70], "amount": 0.42, "vignette": 0.20, "grain": 0.014},
    "arsenal": None, "absorb": absorb, "split": split, "capital": capital, "defs": defs,
    "setup": {
        "blocs": [],
        "wars": [],
        "truce": [["Turkey", "Hungary", 52], ["Turkey", "Iran", 40], ["Turkey", "Italy", 60], ["Spain", "France", 10]],
        "intro": "Eylül 1520: Yavuz Sultan Selim vefat etti, yirmi altı yaşındaki Süleyman Osmanlı tahtına çıkıyor. Avrupa'da Habsburglar ile Valois Fransa'sı kapışmaya hazırlanıyor; doğuda Safevî Şah İsmail Tebriz'de Osmanlı'yı gözlüyor.",
    },
    "pop_f": {"Europe": 0.12, "Asia": 0.09, "Africa": 0.05, "North America": 0.015, "South America": 0.02, "Oceania": 0.01},
    "gdp_default": 0.008,
    "nukes": [], "carriers": {},
}
era["arsenal"] = ottoman_1520()
era["arsenal"]["new"] = [k for k, v in era["arsenal"]["gate"].items() if v > 0]
era["split"] = split

EV = [
    (1520, 11, "Stockholm Kanlı Banyosu: Danimarka Kralı II. Christian İsveç soylularını idam ettirdi; ülkede isyan kıvılcımı çaktı.", [["stab", "Sweden", -10]]),
    (1521, 3, "Magellan seferi Filipin adalarına ulaştı; Avrupa'nın Pasifik'e açılan yolu belirdi.", []),
    (1521, 4, "Worms Meclisi: Martin Luther imparatorun huzuruna çıktı; Almanya'da Reform fırtınası büyüyor.", [["stab", "Germany", -6]]),
    (1521, 5, "Habsburg–Valois savaşı başladı: V. Karl ile I. François İtalya için silaha sarıldı.", [["war", "Spain", "France"]]),
    (1521, 8, "Osmanlı ordusu Belgrad'ı kuşattı ve aldı; Macaristan'ın kapısı açıldı.", [["war", "Turkey", "Hungary"]]),
    (1521, 8, "Cortés, Tenochtitlan'ı ele geçirdi; Aztek İttifakı çöktü.", [["war", "Spain", "Mexico"], ["stab", "Mexico", -35]]),
    (1522, 12, "Rodos şövalyelerle yaptığı altı aylık direnişin ardından Osmanlı'ya teslim oldu.", [["war", "Turkey", "Malta"]]),
    (1523, 6, "Gustav Vasa İsveç'in kralı ilan edildi; Kalmar Birliği fiilen dağıldı.", [["war", "Sweden", "Denmark"]]),
    (1524, 5, "Safevî Şahı İsmail vefat etti; yerine küçük oğlu Tahmasp geçti, Kızılbaş beyleri çekişiyor.", [["stab", "Iran", -12]]),
    (1525, 2, "Pavia Muharebesi: Fransa Kralı I. François esir düştü.", [["stab", "France", -15]]),
    (1526, 4, "Panipat Muharebesi: Babür, Delhi Sultanı İbrahim Lodî'yi yendi; Hindistan'da Babür Devleti doğuyor.", [["war", "Afghanistan", "India"], ["stab", "India", -30]]),
    (1526, 8, "Mohaç Meydan Muharebesi: Macar ordusu bir saatte dağıldı, Kral II. Lajos öldü.", [["stab", "Hungary", -40]]),
    (1527, 5, "Roma Yağması: V. Karl'ın askerleri Roma'yı yağmaladı; İtalya sarsıldı.", [["stab", "Italy", -15]]),
    (1529, 9, "Osmanlı ordusu Viyana önlerinde: Habsburg başkenti kuşatıldı.", [["war", "Turkey", "Spain"]]),
    (1529, 12, "Adal Sultanlığı'nda Ahmed Gran, Habeş topraklarına büyük bir akın başlattı.", [["war", "Somalia", "Ethiopia"]]),
    (1532, 11, "Pizarro İnka İmparatoru Atahualpa'yı Cajamarca'da tuzağa düşürdü.", [["war", "Spain", "Peru"], ["stab", "Peru", -30]]),
    (1534, 12, "Osmanlı Bağdat'ı aldı; Irak Safevîlerin elinden çıktı.", [["war", "Turkey", "Iran"]]),
    (1538, 9, "Preveze Deniz Muharebesi: Barbaros Hayreddin Paşa Haçlı donanmasını yendi, Akdeniz Osmanlı gölü oldu.", [["war", "Turkey", "Italy"]]),
    (1541, 8, "Budin Osmanlı eyaleti ilan edildi; Macaristan üç parçaya bölündü.", [["stab", "Hungary", -15]]),
    (1547, 4, "Barış: Osmanlı ile Habsburglar arasında beş yıllık ateşkes imzalandı.", [["peace", "Turkey", "Spain"]]),
    (1556, 1, "V. Karl tahttan çekildi; imparatorluk Habsburg'un iki koluna bölündü.", [["stab", "Spain", -8]]),
    (1559, 4, "Cateau-Cambrésis Antlaşması: Habsburg–Valois savaşları sona erdi.", [["peace", "Spain", "France"]]),
    (1565, 5, "Malta Kuşatması başladı: Osmanlı donanması Aziz Yuhanna Şövalyelerinin adasını çevirdi.", [["war", "Turkey", "Malta"]]),
    (1566, 9, "Kanuni Sultan Süleyman Zigetvar'da hayatını kaybetti.", [["stab", "Turkey", -8]]),
]
era["events"] = [{"y": y, "m": m, "t": t, "fx": fx} for y, m, t, fx in EV]
era["leaders"] = {"horizon": 1566, "chain": {
    "Spain": [[1556, 1, "Kral|II. Felipe"]],
    "France": [[1547, 3, "Kral|II. Henri"]],
    "United Kingdom": [[1547, 1, "Kral|VI. Edward"], [1553, 7, "Kraliçe|I. Mary"], [1558, 11, "Kraliçe|I. Elizabeth"]],
    "Iran": [[1524, 5, "Şah|I. Tahmasp"]],
    "Russia": [[1533, 12, "Büyük Knez|IV. İvan"], [1547, 1, "Çar|IV. İvan"]],
    "Poland": [[1548, 4, "Kral|II. Zygmunt August"]],
    "Turkey": [[1566, 9, "Padişah|II. Selim"]],
    "Afghanistan": [[1530, 12, "Padişah|Hümayun"]],
    "Hungary": [[1526, 8, "Kral|I. Ferdinand"]],
    "Uzbekistan": [[1533, 1, "Han|Ubeydullah Han"]],
}}
era["objectives"] = {
    "*": [
        {"id": "o1", "type": "survive", "turns": 260, "text": "Beş yıl boyunca ayakta kal"},
        {"id": "o2", "type": "alliances", "n": 3, "text": "3 müttefik edin"},
        {"id": "o3", "type": "stability", "n": 55, "text": "İstikrarı 55 üzerinde tut", "required": False},
    ],
    "Turkey": [
        {"id": "t1", "type": "own_capital", "country": "Hungary", "text": "Macaristan'ın başkentini (Budin) al"},
        {"id": "t2", "type": "own_capital", "country": "Austria", "text": "Viyana'yı fethet", "required": False},
        {"id": "t3", "type": "hold_choke", "choke": "bosphorus", "text": "Boğazlar'a hâkim ol"},
    ],
    "Spain": [
        {"id": "s1", "type": "own_capital", "country": "France", "text": "Paris'e hâkim ol"},
        {"id": "s2", "type": "own_provinces", "n": 70, "text": "70 eyalete ulaş"},
    ],
    "Iran": [
        {"id": "i1", "type": "own_capital", "country": "Iraq", "text": "Bağdat'ı elinde tut"},
        {"id": "i2", "type": "alliances", "n": 2, "text": "2 müttefik edin"},
    ],
}
EN = {
    "name": "Age of the Ottomans", "sub": "September 1520 – Suleiman the Magnificent",
    "blurb": "Selim the Grim is dead; young Suleiman takes the throne. Habsburgs, Valois France, the Safavids, Muscovy, Ming China and the Deccan sultanates divide the world. Janissary matchlocks, siege cannon and galleys open the age of an empire.",
    "setup_intro": "September 1520: Sultan Selim has died and twenty-six-year-old Suleiman ascends the Ottoman throne. The Habsburgs and Valois France prepare to fight over Italy; in the east Shah Ismail watches the Ottomans from Tabriz.",
    "events": {str(i): e[2] for i, e in enumerate(EV)},  # Türkçe metin İngilizce arayüzde de gösterilir (aşağıda çevrilir)
    "objectives": {"o1": "Stay alive for five years", "o2": "Make 3 allies", "o3": "Keep stability above 55", "t1": "Take Hungary's capital (Buda)", "t2": "Conquer Vienna",
                   "t3": "Control the Straits", "s1": "Dominate Paris", "s2": "Reach 70 provinces", "i1": "Hold Baghdad", "i2": "Make 2 allies"},
}
EN_EVENTS = [
    "Stockholm Bloodbath: Christian II of Denmark executed Swedish nobles; a revolt is brewing.",
    "Magellan's expedition reaches the Philippines.",
    "Diet of Worms: Martin Luther stands before the emperor; the Reformation storm grows in Germany.",
    "The Habsburg–Valois war begins: Charles V and Francis I take up arms for Italy.",
    "The Ottoman army besieges and takes Belgrade; the gate to Hungary is open.",
    "Cortés takes Tenochtitlan; the Aztec Alliance collapses.",
    "Rhodes surrenders to the Ottomans after a six-month defence by the Knights.",
    "Gustav Vasa is proclaimed King of Sweden; the Kalmar Union is effectively dissolved.",
    "Shah Ismail of Persia dies; his young son Tahmasp succeeds and the Qizilbash beys quarrel.",
    "Battle of Pavia: Francis I of France is taken prisoner.",
    "Battle of Panipat: Babur defeats Ibrahim Lodi, the Sultan of Delhi; the Mughal state is born.",
    "Battle of Mohács: the Hungarian army is destroyed in an hour and King Louis II dies.",
    "Sack of Rome: Charles V's troops plunder the city; Italy is shaken.",
    "The Ottoman army stands before Vienna: the Habsburg capital is besieged.",
    "In Adal, Ahmad Gran launches a great invasion of Ethiopia.",
    "Pizarro ambushes the Inca emperor Atahualpa at Cajamarca.",
    "The Ottomans take Baghdad; Iraq passes from the Safavids.",
    "Battle of Preveza: Barbarossa defeats the Holy League fleet; the Mediterranean becomes an Ottoman lake.",
    "Buda is made an Ottoman province; Hungary is split in three.",
    "Peace: a five-year truce is signed between the Ottomans and the Habsburgs.",
    "Charles V abdicates; the Habsburg inheritance is split into two branches.",
    "Treaty of Cateau-Cambrésis ends the Habsburg–Valois wars.",
    "The Siege of Malta begins: the Ottoman fleet surrounds the Knights' island.",
    "Suleiman the Magnificent dies at Szigetvár.",
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
