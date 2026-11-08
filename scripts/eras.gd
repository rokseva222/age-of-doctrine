extends RefCounted
## Tarihî oyun kipleri: 1. Dünya Savaşı (Ağustos 1914) ve 2. Dünya Savaşı (Eylül 1939).
## Senaryo değil, ayrı bir kip: dönem imparatorlukları (sömürgeleriyle), dönem silahları, dönem tarihi,
## dönem ittifakları ve dönemin renklerine çekilmiş harita/arayüz.
## Harita aynı eyalet verisini kullanır; dönemin devletleri bugünkü ülkelerin eyaletleri birleştirilerek kurulur.
## Lider isimleri yalnızca metindir (fotoğraf/sembol yok).

const Macro = preload("res://scripts/macro.gd")
const Names = preload("res://scripts/names.gd")
const Flags = preload("res://scripts/flags.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Scenarios = preload("res://scripts/scenarios.gd")
const EraLeaders = preload("res://scripts/era_leaders.gd")
const EraEvents = preload("res://scripts/era_events.gd")
const Loc = preload("res://scripts/loc.gd")
const DataUtil = preload("res://scripts/data_util.gd")
const EraExt = preload("res://scripts/era_ext.gd")
const Objectives = preload("res://scripts/objectives.gd")

static var current := ""

const LIST := [
	{"id": "ww1", "name": "I. Dünya Savaşı", "sub": "Ağustos 1914", "start_year": 1914, "start_doy": 212,
		"blurb": "Saraybosna'daki suikastın ardından Avrupa'nın bütün diplomasisi çöküyor. İtilaf ile Merkezi Güçler siperlere gömülecek; makineli tüfek, ağır top ve ilk tanklar savaşın yüzünü değiştirecek.",
		"suggest": ["Germany", "United Kingdom", "France", "Russia", "Austria", "Turkey", "Italy", "United States of America"],
		"look": {"shadow": [0.09, 0.07, 0.05], "mid": [0.56, 0.45, 0.29], "light": [0.96, 0.90, 0.74], "amount": 0.38, "vignette": 0.18, "grain": 0.012}},
	{"id": "ww2", "name": "II. Dünya Savaşı", "sub": "Eylül 1939", "start_year": 1939, "start_doy": 243,
		"blurb": "Almanya Polonya'ya saldırıyor; Britanya ve Fransa savaş ilan ediyor. Zırhlı kamalar, bombardıman uçakları ve denizaltı savaşı. Savaş bütün kıtalara yayılabilir.",
		"suggest": ["Germany", "United Kingdom", "Russia", "United States of America", "Japan", "France", "Italy", "Poland"],
		"look": {"shadow": [0.05, 0.07, 0.06], "mid": [0.36, 0.42, 0.31], "light": [0.90, 0.90, 0.82], "amount": 0.30, "vignette": 0.14, "grain": 0.010}},
]

# ------------------------------------------------------------------ dönem devletleri

# host (bugünkü ülkenin name_en'i) -> birleştirilen bugünkü ülkeler (tüm eyaletleriyle)
const ABSORB := {
	"ww2": {
		"Germany": ["Austria", "Czechia"],
		"Russia": ["Ukraine", "Belarus", "Georgia", "Armenia", "Azerbaijan", "Kazakhstan", "Uzbekistan", "Turkmenistan", "Tajikistan", "Kyrgyzstan"],
		"United Kingdom": ["India", "Pakistan", "Bangladesh", "Sri Lanka", "Myanmar", "Malaysia", "Singapore", "Brunei", "Sudan", "S. Sudan", "Kenya", "Uganda",
			"Tanzania", "Nigeria", "Ghana", "Sierra Leone", "Gambia", "Zambia", "Zimbabwe", "Malawi", "Botswana", "Lesotho", "eSwatini", "Somaliland", "Cyprus",
			"N. Cyprus", "Malta", "Jamaica", "Bahamas", "Barbados", "Belize", "Guyana", "Trinidad and Tobago", "Fiji", "Palestine", "Israel", "Jordan", "Kuwait",
			"Bahrain", "Qatar", "United Arab Emirates", "Maldives", "Antigua and Barb.", "Dominica", "Grenada", "Saint Lucia", "St. Kitts and Nevis",
			"St. Vin. and Gren.", "Solomon Is.", "Tonga", "Mauritius", "Seychelles", "Kiribati", "Tuvalu"],
		"Australia": ["Papua New Guinea"], "South Africa": ["Namibia"], "New Zealand": ["Samoa"],
		"France": ["Algeria", "Tunisia", "Morocco", "Mauritania", "Mali", "Niger", "Chad", "Senegal", "Guinea", "Côte d'Ivoire", "Burkina Faso", "Benin", "Gabon",
			"Congo", "Central African Rep.", "Cameroon", "Togo", "Madagascar", "Comoros", "Djibouti", "Vietnam", "Laos", "Cambodia", "Syria", "Lebanon", "Vanuatu"],
		"Italy": ["Libya", "Eritrea", "Ethiopia", "Somalia", "Albania"],
		"Japan": ["South Korea", "North Korea", "Taiwan", "Palau", "Micronesia", "Marshall Is.", "Nauru"],
		"Netherlands": ["Indonesia", "Suriname"],
		"Belgium": ["Dem. Rep. Congo", "Rwanda", "Burundi"],
		"Portugal": ["Angola", "Mozambique", "Guinea-Bissau", "Cabo Verde", "São Tomé and Principe", "Timor-Leste"],
		"Spain": ["W. Sahara", "Eq. Guinea"],
		"United States of America": ["Philippines"],
		"Denmark": ["Greenland"],
		"Romania": ["Moldova"],
		"Serbia": ["Croatia", "Slovenia", "Bosnia and Herz.", "Montenegro", "North Macedonia", "Kosovo"],
	},
	"ww1": {
		"Germany": ["Tanzania", "Cameroon", "Togo", "Namibia", "Rwanda", "Burundi", "Nauru"],
		"Austria": ["Hungary", "Czechia", "Slovakia", "Slovenia", "Croatia", "Bosnia and Herz."],
		"Turkey": ["Syria", "Iraq", "Lebanon", "Jordan", "Palestine", "Israel", "Saudi Arabia", "Yemen"],
		"Russia": ["Ukraine", "Belarus", "Estonia", "Latvia", "Lithuania", "Finland", "Moldova", "Georgia", "Armenia", "Azerbaijan", "Kazakhstan", "Uzbekistan",
			"Turkmenistan", "Tajikistan", "Kyrgyzstan"],
		"United Kingdom": ["Ireland", "India", "Pakistan", "Bangladesh", "Sri Lanka", "Myanmar", "Malaysia", "Singapore", "Brunei", "Egypt", "Sudan", "S. Sudan",
			"Kenya", "Uganda", "Nigeria", "Ghana", "Sierra Leone", "Gambia", "Zambia", "Zimbabwe", "Malawi", "Botswana", "Lesotho", "eSwatini", "Somaliland",
			"Cyprus", "N. Cyprus", "Malta", "Jamaica", "Bahamas", "Barbados", "Belize", "Guyana", "Trinidad and Tobago", "Fiji", "Kuwait", "Bahrain", "Qatar",
			"United Arab Emirates", "Maldives", "Antigua and Barb.", "Dominica", "Grenada", "Saint Lucia", "St. Kitts and Nevis", "St. Vin. and Gren.",
			"Solomon Is.", "Tonga", "Mauritius", "Seychelles", "Kiribati", "Tuvalu"],
		"Australia": ["Papua New Guinea"], "New Zealand": ["Samoa"],
		"France": ["Algeria", "Tunisia", "Morocco", "Mauritania", "Mali", "Niger", "Chad", "Senegal", "Guinea", "Côte d'Ivoire", "Burkina Faso", "Benin", "Gabon",
			"Congo", "Central African Rep.", "Madagascar", "Comoros", "Djibouti", "Vietnam", "Laos", "Cambodia", "Vanuatu"],
		"Italy": ["Libya", "Eritrea", "Somalia"],
		"Japan": ["South Korea", "North Korea", "Taiwan", "Palau", "Micronesia", "Marshall Is."],
		"Netherlands": ["Indonesia", "Suriname"],
		"Belgium": ["Dem. Rep. Congo"],
		"Portugal": ["Angola", "Mozambique", "Guinea-Bissau", "Cabo Verde", "São Tomé and Principe", "Timor-Leste"],
		"Spain": ["W. Sahara", "Eq. Guinea"],
		"United States of America": ["Philippines"],
		"Denmark": ["Greenland", "Iceland"],
		"Serbia": ["North Macedonia", "Kosovo"],
	},
}

# eyalet düzeyinde aktarım: [eyalet adı, bugünkü ülke, hedef host, "own" (mülkiyet) | "occ" (işgal)]
const SPLIT := {
	"ww2": [["L'viv", "Ukraine", "Poland", "own"], ["Rivne", "Ukraine", "Poland", "own"], [1385, "Belarus", "Poland", "own"], [1387, "Belarus", "Poland", "own"],
		[788, "Poland", "Germany", "own"], [790, "Poland", "Germany", "own"], [791, "Poland", "Germany", "own"], [792, "Poland", "Germany", "own"],
		[5, "China", "Japan", "own"], [6, "China", "Japan", "own"], [7, "China", "Japan", "own"], [2, "China", "Japan", "own"],
		[18, "China", "Japan", "occ"], [17, "China", "Japan", "occ"], [16, "China", "Japan", "occ"], [15, "China", "Japan", "occ"],
		[13, "China", "Japan", "occ"], [14, "China", "Japan", "occ"], [26, "China", "Japan", "occ"],
		[32, "China", "United Kingdom", "own"], [31, "China", "United Kingdom", "own"]],
	"ww1": [["Greater Poland", "Poland", "Germany", "own"], ["Pomeranian", "Poland", "Germany", "own"], ["Lower Silesian", "Poland", "Germany", "own"],
		["Warmian-Masurian", "Poland", "Germany", "own"], [785, "Poland", "Germany", "own"], [791, "Poland", "Germany", "own"], [792, "Poland", "Germany", "own"],
		[797, "Poland", "Germany", "own"], ["Łódź", "Poland", "Russia", "own"], [795, "Poland", "Russia", "own"], [789, "Poland", "Russia", "own"],
		["Lublin", "Poland", "Russia", "own"], ["Lesser Poland", "Poland", "Austria", "own"], [787, "Poland", "Austria", "own"],
		["L'viv", "Ukraine", "Austria", "own"], ["Bozen", "Italy", "Austria", "own"],
		[504, "France", "Germany", "own"],
		[1071, "Romania", "Austria", "own"], [1072, "Romania", "Austria", "own"], [1075, "Romania", "Austria", "own"], [1081, "Romania", "Austria", "own"],
		[1079, "Romania", "Austria", "own"], [1459, "Serbia", "Austria", "own"],
		[32, "China", "United Kingdom", "own"], [31, "China", "United Kingdom", "own"]],
}

# dönem başkentleri: host (bugünkü ülke adı) -> başkent eyalet id'si
const CAPITAL := {
	"ww1": {"Turkey": 423, "Russia": 257, "Brazil": 184},
	"ww2": {"China": 20, "Brazil": 184},
}

# host tanımları: ad, renk, bayrak (flag_db kısa tanımı), lider, bloc, asker/silah, hedef GSYH (milyar $)
const DEFS := {
	"ww2": {
		"Germany": {"name": "Almanya", "color": "5d6068", "flag": "H:k,w,#ce1126", "leader": "Reich Şansölyesi|Adolf Hitler", "gdp": 330,
			"mil": {"personnel": 3700000, "tank": 3200, "afv": 4000, "arty": 9000, "air": 3600, "sub": 57}},
		"Russia": {"name": "SSCB", "color": "b53a2e", "flag": "R:0,0,1,1,#cc0000|S:.14,.2,.09,#ffd700", "leader": "Genel Sekreter|Josef Stalin", "gdp": 380,
			"mil": {"personnel": 3000000, "tank": 15000, "afv": 5000, "arty": 25000, "air": 9000, "sub": 165}},
		"United Kingdom": {"name": "Britanya İmparatorluğu", "color": "d98ca0", "leader": "Başbakan|Neville Chamberlain", "gdp": 330,
			"mil": {"personnel": 1700000, "tank": 600, "afv": 3000, "arty": 2200, "air": 1900, "sub": 58}},
		"France": {"name": "Fransa", "color": "4f74b8", "leader": "Başbakan|Édouard Daladier", "gdp": 190,
			"mil": {"personnel": 5000000, "tank": 2900, "afv": 1500, "arty": 10000, "air": 1500, "sub": 78}},
		"Italy": {"name": "İtalya", "color": "5f9c6a", "leader": "Başbakan|Benito Mussolini", "gdp": 130,
			"mil": {"personnel": 1700000, "tank": 1500, "afv": 600, "arty": 7000, "air": 1700, "sub": 115}},
		"Japan": {"name": "Japon İmparatorluğu", "color": "e2a53a", "leader": "İmparator|Hirohito", "gdp": 150,
			"mil": {"personnel": 2500000, "tank": 1800, "afv": 800, "arty": 6000, "air": 2100, "sub": 60}},
		"United States of America": {"name": "ABD", "color": "7fa65a", "leader": "Başkan|Franklin D. Roosevelt", "gdp": 900,
			"mil": {"personnel": 340000, "tank": 400, "afv": 400, "arty": 1500, "air": 1800, "sub": 55}},
		"China": {"name": "Çin Cumhuriyeti", "color": "d6b25e", "flag": "R:0,0,1,1,#de2910|R:0,0,.5,.5,#002b7f|C:.25,.25,.1,w", "leader": "Başkomutan|Çan Kay-şek", "gdp": 90,
			"mil": {"personnel": 2000000, "tank": 100, "afv": 50, "arty": 1500, "air": 300, "sub": 0}},
		"Poland": {"name": "Polonya", "color": "b04a4a", "leader": "Cumhurbaşkanı|Ignacy Mościcki", "gdp": 32,
			"mil": {"personnel": 1000000, "tank": 880, "afv": 100, "arty": 4000, "air": 400, "sub": 5}},
		"Serbia": {"name": "Yugoslavya Krallığı", "color": "7a8fb0", "flag": "H:#0c4076,w,#c6363c", "leader": "Naip|Prens Paul", "gdp": 14,
			"mil": {"personnel": 700000, "tank": 100, "afv": 50, "arty": 3000, "air": 400, "sub": 4}},
		"Netherlands": {"name": "Hollanda", "color": "e08a3c", "leader": "Kraliçe|Wilhelmina", "gdp": 28, "mil": {"personnel": 280000, "tank": 20, "afv": 30, "arty": 700, "air": 150, "sub": 20}},
		"Belgium": {"name": "Belçika", "color": "8f6bb0", "leader": "Kral|III. Leopold", "gdp": 20, "mil": {"personnel": 650000, "tank": 270, "afv": 200, "arty": 1200, "air": 250, "sub": 0}},
		"Spain": {"name": "İspanya", "color": "a07a50", "leader": "Caudillo|Francisco Franco", "gdp": 20, "mil": {"personnel": 700000, "tank": 100, "afv": 100, "arty": 2000, "air": 500, "sub": 12}},
		"Turkey": {"name": "Türkiye", "color": "5ba08c", "leader": "Cumhurbaşkanı|İsmet İnönü", "gdp": 15, "mil": {"personnel": 1000000, "tank": 60, "afv": 100, "arty": 2000, "air": 250, "sub": 9}},
		"Romania": {"name": "Romanya", "color": "b0a05a", "leader": "Kral|II. Carol", "gdp": 14, "mil": {"personnel": 1000000, "tank": 100, "afv": 80, "arty": 2500, "air": 300, "sub": 1}},
		"Canada": {"name": "Kanada", "color": "e6a2b5", "leader": "Başbakan|William Lyon Mackenzie King", "gdp": 45, "mil": {"personnel": 10000, "tank": 10, "afv": 50, "arty": 100, "air": 100, "sub": 0}},
		"Australia": {"name": "Avustralya", "color": "e6a2b5", "leader": "Başbakan|Robert Menzies", "gdp": 28, "mil": {"personnel": 80000, "tank": 0, "afv": 30, "arty": 200, "air": 150, "sub": 0}},
		"New Zealand": {"name": "Yeni Zelanda", "color": "e6a2b5", "leader": "Başbakan|Michael Joseph Savage", "gdp": 8, "mil": {"personnel": 25000, "tank": 0, "afv": 0, "arty": 60, "air": 30, "sub": 0}},
		"South Africa": {"name": "Güney Afrika", "color": "cf8aa0", "leader": "Başbakan|Jan Smuts", "gdp": 10, "mil": {"personnel": 50000, "tank": 0, "afv": 20, "arty": 100, "air": 100, "sub": 0}},
		"Denmark": {"name": "Danimarka", "color": "c75c5c", "leader": "Başbakan|Thorvald Stauning", "gdp": 7, "mil": {"personnel": 15000, "tank": 0, "afv": 10, "arty": 60, "air": 50, "sub": 0}},
		"Sweden": {"name": "İsveç", "color": "6a9ac0", "leader": "Başbakan|Per Albin Hansson", "gdp": 22, "mil": {"personnel": 400000, "tank": 200, "afv": 100, "arty": 1000, "air": 300, "sub": 20}},
		"Finland": {"name": "Finlandiya", "color": "9ac0c0", "leader": "Cumhurbaşkanı|Kyösti Kallio", "gdp": 7, "mil": {"personnel": 300000, "tank": 30, "afv": 20, "arty": 800, "air": 120, "sub": 5}},
		"Hungary": {"name": "Macaristan", "color": "c7a24a", "leader": "Naip|Miklós Horthy", "gdp": 8, "mil": {"personnel": 300000, "tank": 100, "afv": 100, "arty": 800, "air": 150, "sub": 0}},
		"Bulgaria": {"name": "Bulgaristan", "color": "7aa05a", "leader": "Çar|III. Boris", "gdp": 4, "mil": {"personnel": 150000, "tank": 40, "afv": 30, "arty": 600, "air": 100, "sub": 0}},
		"Greece": {"name": "Yunanistan", "color": "6a9ad0", "leader": "Başbakan|Ioannis Metaxas", "gdp": 6, "mil": {"personnel": 430000, "tank": 0, "afv": 20, "arty": 700, "air": 80, "sub": 6}},
		"Norway": {"name": "Norveç", "color": "b86a6a", "leader": "Kral|VII. Haakon", "gdp": 5, "mil": {"personnel": 50000, "tank": 0, "afv": 10, "arty": 100, "air": 60, "sub": 9}},
		"Portugal": {"name": "Portekiz", "color": "8aa05a", "leader": "Başbakan|António de Oliveira Salazar", "gdp": 6, "mil": {"personnel": 80000, "tank": 10, "afv": 20, "arty": 300, "air": 60, "sub": 3}},
		"Iran": {"name": "İran", "color": "b0a070", "leader": "Şah|Rıza Pehlevi", "gdp": 8, "mil": {"personnel": 120000, "tank": 30, "afv": 20, "arty": 400, "air": 100, "sub": 0}},
		"Egypt": {"name": "Mısır", "color": "c4b070", "leader": "Kral|Faruk", "gdp": 6, "mil": {"personnel": 40000, "tank": 0, "afv": 20, "arty": 100, "air": 60, "sub": 0}},
		"Iraq": {"name": "Irak", "color": "a89070", "leader": "Kral|II. Faysal", "gdp": 3, "mil": {"personnel": 40000, "tank": 0, "afv": 10, "arty": 80, "air": 60, "sub": 0}},
		"Saudi Arabia": {"name": "Suudi Arabistan", "color": "98b070", "leader": "Kral|Abdülaziz", "gdp": 2, "mil": {"personnel": 20000, "tank": 0, "afv": 0, "arty": 30, "air": 10, "sub": 0}},
		"Thailand": {"name": "Tayland", "color": "a67a9a", "leader": "Başbakan|Plaek Phibunsongkhram", "gdp": 5, "mil": {"personnel": 60000, "tank": 30, "afv": 20, "arty": 200, "air": 150, "sub": 4}},
		"Brazil": {"name": "Brezilya", "color": "5aa070", "leader": "Başkan|Getúlio Vargas", "gdp": 35, "mil": {"personnel": 120000, "tank": 10, "afv": 20, "arty": 300, "air": 200, "sub": 3}},
		"Argentina": {"name": "Arjantin", "color": "7ab0d0", "leader": "Başkan|Roberto Ortiz", "gdp": 30, "mil": {"personnel": 100000, "tank": 0, "afv": 20, "arty": 300, "air": 200, "sub": 3}},
		"Mexico": {"name": "Meksika", "color": "9aa86a", "leader": "Başkan|Lázaro Cárdenas", "gdp": 14, "mil": {"personnel": 60000, "tank": 0, "afv": 10, "arty": 100, "air": 100, "sub": 0}},
		"Mongolia": {"name": "Moğolistan", "color": "c08a6a", "leader": "Başbakan|Khorloogiin Choibalsan", "gdp": 1, "mil": {"personnel": 40000, "tank": 100, "afv": 50, "arty": 100, "air": 100, "sub": 0}},
		"Ireland": {"name": "İrlanda", "color": "5aaa6a", "leader": "Taoiseach|Éamon de Valera", "gdp": 3, "mil": {"personnel": 20000, "tank": 0, "afv": 10, "arty": 30, "air": 10, "sub": 0}},
		"Slovakia": {"name": "Slovak Devleti", "color": "8aa0c0", "leader": "Cumhurbaşkanı|Jozef Tiso", "gdp": 4, "mil": {"personnel": 50000, "tank": 30, "afv": 20, "arty": 200, "air": 50, "sub": 0}},
	},
	"ww1": {
		"Germany": {"name": "Alman İmparatorluğu", "color": "6d6f78", "flag": "H:k,w,#ce1126", "leader": "İmparator|II. Wilhelm", "gdp": 245,
			"mil": {"personnel": 3800000, "tank": 0, "afv": 20, "arty": 9000, "air": 250, "sub": 28}},
		"Austria": {"name": "Avusturya-Macaristan", "color": "d4c05a", "flag": "H:k,#fcd116", "leader": "İmparator|I. Franz Joseph", "gdp": 100,
			"mil": {"personnel": 2300000, "tank": 0, "afv": 10, "arty": 4000, "air": 40, "sub": 6}},
		"Turkey": {"name": "Osmanlı İmparatorluğu", "color": "6fa882", "leader": "Sultan|V. Mehmed Reşad", "gdp": 40,
			"mil": {"personnel": 800000, "tank": 0, "afv": 0, "arty": 2000, "air": 5, "sub": 0}},
		"Russia": {"name": "Rus İmparatorluğu", "color": "7d9a5a", "leader": "Çar|II. Nikolay", "gdp": 230,
			"mil": {"personnel": 3400000, "tank": 0, "afv": 30, "arty": 7000, "air": 250, "sub": 30}},
		"United Kingdom": {"name": "Britanya İmparatorluğu", "color": "d98ca0", "leader": "Başbakan|H. H. Asquith", "gdp": 280,
			"mil": {"personnel": 900000, "tank": 0, "afv": 80, "arty": 1800, "air": 110, "sub": 60}},
		"France": {"name": "Fransa", "color": "4f74b8", "leader": "Cumhurbaşkanı|Raymond Poincaré", "gdp": 130,
			"mil": {"personnel": 3700000, "tank": 0, "afv": 40, "arty": 5000, "air": 160, "sub": 62}},
		"Italy": {"name": "İtalya", "color": "8fb070", "leader": "Kral|III. Vittorio Emanuele", "gdp": 90,
			"mil": {"personnel": 1400000, "tank": 0, "afv": 10, "arty": 2000, "air": 100, "sub": 20}},
		"Japan": {"name": "Japon İmparatorluğu", "color": "e2a53a", "leader": "İmparator|Taişo", "gdp": 70,
			"mil": {"personnel": 800000, "tank": 0, "afv": 0, "arty": 1500, "air": 30, "sub": 12}},
		"United States of America": {"name": "ABD", "color": "7fa65a", "leader": "Başkan|Woodrow Wilson", "gdp": 600,
			"mil": {"personnel": 100000, "tank": 0, "afv": 10, "arty": 500, "air": 30, "sub": 30}},
		"Serbia": {"name": "Sırbistan", "color": "b87a6a", "leader": "Kral|I. Petar", "gdp": 5, "mil": {"personnel": 250000, "tank": 0, "afv": 0, "arty": 500, "air": 5, "sub": 0}},
		"Belgium": {"name": "Belçika", "color": "8f6bb0", "leader": "Kral|I. Albert", "gdp": 25, "mil": {"personnel": 200000, "tank": 0, "afv": 10, "arty": 400, "air": 20, "sub": 0}},
		"Bulgaria": {"name": "Bulgaristan", "color": "7aa05a", "leader": "Çar|Ferdinand", "gdp": 5, "mil": {"personnel": 300000, "tank": 0, "afv": 0, "arty": 700, "air": 10, "sub": 0}},
		"Romania": {"name": "Romanya", "color": "b0a05a", "leader": "Kral|I. Carol", "gdp": 10, "mil": {"personnel": 500000, "tank": 0, "afv": 0, "arty": 1000, "air": 10, "sub": 0}},
		"Greece": {"name": "Yunanistan", "color": "6a9ad0", "leader": "Kral|I. Konstantinos", "gdp": 6, "mil": {"personnel": 200000, "tank": 0, "afv": 0, "arty": 400, "air": 10, "sub": 0}},
		"Montenegro": {"name": "Karadağ", "color": "a07a8a", "leader": "Kral|I. Nikola", "gdp": 1, "mil": {"personnel": 40000, "tank": 0, "afv": 0, "arty": 80, "air": 0, "sub": 0}},
		"China": {"name": "Çin Cumhuriyeti", "color": "d6b25e", "flag": "H:#de2910,#ffd700,#002b7f,w,k", "leader": "Başkan|Yuan Shikai", "gdp": 100,
			"mil": {"personnel": 500000, "tank": 0, "afv": 0, "arty": 500, "air": 5, "sub": 0}},
		"Netherlands": {"name": "Hollanda", "color": "e08a3c", "leader": "Kraliçe|Wilhelmina", "gdp": 15, "mil": {"personnel": 200000, "tank": 0, "afv": 0, "arty": 300, "air": 10, "sub": 10}},
		"Spain": {"name": "İspanya", "color": "a07a50", "leader": "Kral|XIII. Alfonso", "gdp": 20, "mil": {"personnel": 200000, "tank": 0, "afv": 0, "arty": 400, "air": 10, "sub": 2}},
		"Sweden": {"name": "İsveç", "color": "6a9ac0", "leader": "Kral|V. Gustaf", "gdp": 8, "mil": {"personnel": 150000, "tank": 0, "afv": 0, "arty": 300, "air": 10, "sub": 12}},
		"Norway": {"name": "Norveç", "color": "b86a6a", "leader": "Kral|VII. Haakon", "gdp": 3, "mil": {"personnel": 60000, "tank": 0, "afv": 0, "arty": 100, "air": 5, "sub": 6}},
		"Denmark": {"name": "Danimarka", "color": "c75c5c", "leader": "Kral|X. Christian", "gdp": 4, "mil": {"personnel": 50000, "tank": 0, "afv": 0, "arty": 100, "air": 5, "sub": 6}},
		"Portugal": {"name": "Portekiz", "color": "8aa05a", "leader": "Başkan|Manuel de Arriaga", "gdp": 4, "mil": {"personnel": 60000, "tank": 0, "afv": 0, "arty": 100, "air": 5, "sub": 2}},
		"Canada": {"name": "Kanada", "color": "e6a2b5", "leader": "Başbakan|Robert Borden", "gdp": 25, "mil": {"personnel": 3000, "tank": 0, "afv": 0, "arty": 50, "air": 0, "sub": 0}},
		"Australia": {"name": "Avustralya", "color": "e6a2b5", "leader": "Başbakan|Joseph Cook", "gdp": 15, "mil": {"personnel": 5000, "tank": 0, "afv": 0, "arty": 50, "air": 0, "sub": 2}},
		"New Zealand": {"name": "Yeni Zelanda", "color": "e6a2b5", "leader": "Başbakan|William Massey", "gdp": 3, "mil": {"personnel": 3000, "tank": 0, "afv": 0, "arty": 20, "air": 0, "sub": 0}},
		"South Africa": {"name": "Güney Afrika", "color": "cf8aa0", "leader": "Başbakan|Louis Botha", "gdp": 6, "mil": {"personnel": 8000, "tank": 0, "afv": 0, "arty": 40, "air": 0, "sub": 0}},
		"Iran": {"name": "Pers Devleti", "color": "b0a070", "leader": "Şah|Ahmed Şah Kaçar", "gdp": 4, "mil": {"personnel": 30000, "tank": 0, "afv": 0, "arty": 50, "air": 0, "sub": 0}},
		"Switzerland": {"name": "İsviçre", "color": "c07a7a", "leader": "Federal Konsey|Başkanı", "gdp": 8, "mil": {"personnel": 250000, "tank": 0, "afv": 0, "arty": 400, "air": 10, "sub": 0}},
		"Thailand": {"name": "Siyam", "color": "a67a9a", "leader": "Kral|Vajiravudh", "gdp": 3, "mil": {"personnel": 50000, "tank": 0, "afv": 0, "arty": 100, "air": 0, "sub": 0}},
		"Brazil": {"name": "Brezilya", "color": "5aa070", "leader": "Başkan|Hermes da Fonseca", "gdp": 20, "mil": {"personnel": 60000, "tank": 0, "afv": 0, "arty": 100, "air": 5, "sub": 0}},
		"Argentina": {"name": "Arjantin", "color": "7ab0d0", "leader": "Başkan|Victorino de la Plaza", "gdp": 25, "mil": {"personnel": 40000, "tank": 0, "afv": 0, "arty": 100, "air": 5, "sub": 0}},
	},
}

# ittifaklar (başlangıçta kurulu) ve başlangıç savaşları
const SETUP := {
	"ww2": {
		"blocs": [
			{"name": "Müttefik Devletler", "members": ["United Kingdom", "France", "Poland", "Australia", "New Zealand", "Canada", "South Africa"],
				"emblem": {"shape": 1, "inner": 1, "symbol": "shield", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Mihver Devletleri", "members": ["Germany", "Italy", "Japan", "Slovakia"],
				"emblem": {"shape": 4, "inner": 1, "symbol": "bolt", "c1": "5d6068", "c2": "ece6d6", "c3": "e5482f"}},
		],
		"wars": [["Germany", "Poland"], ["United Kingdom", "Germany"], ["France", "Germany"], ["Australia", "Germany"], ["New Zealand", "Germany"],
			["Canada", "Germany"], ["South Africa", "Germany"], ["Japan", "China"]],
		"truce": [["Germany", "Russia", 90]],
		"intro": "1 Eylül 1939: Alman orduları Polonya sınırını aştı. Britanya ve Fransa savaşa girdi; Uzakdoğu'da Japonya Çin'le savaşıyor.",
	},
	"ww1": {
		"blocs": [
			{"name": "İtilaf Devletleri", "members": ["United Kingdom", "France", "Russia", "Serbia", "Belgium", "Japan", "Canada", "Australia", "New Zealand", "South Africa"],
				"emblem": {"shape": 5, "inner": 1, "symbol": "shield", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Merkezi Güçler", "members": ["Germany", "Austria", "Turkey", "Bulgaria"],
				"emblem": {"shape": 4, "inner": 1, "symbol": "crown", "c1": "6d6f78", "c2": "e3a92b", "c3": "e3a92b"}},
		],
		"wars": [["Austria", "Serbia"], ["Germany", "Russia"], ["Germany", "France"], ["Germany", "Belgium"], ["United Kingdom", "Germany"],
			["Austria", "Russia"], ["Japan", "Germany"]],
		"truce": [],
		"intro": "Ağustos 1914: Saraybosna'daki suikast zincirleme ittifakları harekete geçirdi. Avrupa mobilizasyona girdi; siperler kazılıyor.",
	},
}

# bugünkü -> dönem nüfus çarpanı (kıta)
const POP_F := {
	"ww2": {"Europe": 0.85, "North America": 0.55, "Asia": 0.38, "Africa": 0.20, "South America": 0.30, "Oceania": 0.40},
	"ww1": {"Europe": 0.75, "North America": 0.45, "Asia": 0.32, "Africa": 0.15, "South America": 0.25, "Oceania": 0.35},
}
const GDP_DEFAULT := {"ww2": 0.022, "ww1": 0.018}
const COLONY_W := 0.35


## Tüm çağlar: yerleşik + data/eras
static func all() -> Array:
	var out: Array = LIST.duplicate()
	out.append_array(EraExt.listing())
	return out


static func get_era(id: String) -> Dictionary:
	for e in all():
		if e["id"] == id:
			return e
	return {}


## Tablo erişimi: önce JSON çağı (ve base zinciri), sonra yerleşik sabitler
static func _t(key: String, id: String):
	var cur := id
	for i in 6:
		if EraExt.has_era(cur):
			var d: Dictionary = EraExt.raw(cur)
			if d.has(key):
				return d[key]
			cur = String(d.get("base", ""))
			if cur == "":
				break
		else:
			match key:
				"absorb": return ABSORB.get(cur, {})
				"split": return SPLIT.get(cur, [])
				"capital": return CAPITAL.get(cur, {})
				"defs": return DEFS.get(cur, {})
				"setup": return SETUP.get(cur, {"blocs": [], "wars": [], "truce": [], "intro": ""})
				"pop_f": return POP_F.get(cur, {})
				"gdp_default": return GDP_DEFAULT.get(cur, 0.02)
			break
	match key:
		"absorb": return {}
		"split": return []
		"capital": return {}
		"defs": return {}
		"setup": return {"blocs": [], "wars": [], "truce": [], "intro": ""}
		"pop_f": return {"Europe": 0.7, "North America": 0.5, "Asia": 0.4, "Africa": 0.25, "South America": 0.35, "Oceania": 0.4}
		"gdp_default": return 0.02
	return null


## Kural ailesi ("ww1" / "ww2" / "cold" / "" = modern): çağa özel kural farkları için
static func family(id: String = "") -> String:
	if id == "":
		id = current
	if id == "":
		return ""
	return EraExt.family(id) if EraExt.has_era(id) else id


## Çağa özgü ek alanlar (JSON): carriers, nukes, mood, icon
static func field(key: String, default = null, id: String = ""):
	if id == "":
		id = current
	return EraExt.field(id, key, default)


# ------------------------------------------------------------------ statik ayarlar (yükleme için de kullanılır)

static func prepare(id: String) -> void:
	current = id
	var e: Dictionary = get_era(id)
	if e.is_empty():
		clear()
		return
	Arsenal.set_era(id)
	Macro.era_on = true
	var mil: Dictionary = {}
	var DF: Dictionary = _t("defs", id)
	for n in DF:
		mil[n] = DF[n]["mil"]
	Macro.era_mil = mil
	Names.start_year = int(e["start_year"])
	Names.start_doy = int(e["start_doy"])
	var fl: Dictionary = {}
	for n2 in DF:
		if DF[n2].has("flag"):
			fl[n2] = DF[n2]["flag"]
	Flags.set_era_specs(fl)


static func clear() -> void:
	current = ""
	Arsenal.set_era("")
	Macro.era_on = false
	Macro.era_mil = {}
	Names.start_year = 2027
	Names.start_doy = 0
	Flags.set_era_specs({})


# ------------------------------------------------------------------ dünyayı döneme çevir

static func restructure(gs, id: String) -> void:
	var idx: Dictionary = {}
	for c in gs.countries:
		idx[c.name_en] = c.id
	var orig: Array = []           # eyalet -> bugünkü sahibi
	for p in gs.provinces:
		orig.append(p.owner)
	var host_of: Dictionary = {}   # bugünkü ülke id -> host id
	var ABS: Dictionary = _t("absorb", id)
	for h in ABS:
		var hid: int = int(idx.get(h, -1))
		if hid < 0:
			continue
		for n in ABS[h]:
			var cid: int = int(idx.get(n, -1))
			if cid >= 0:
				host_of[cid] = hid
	# 1) eyalet düzeyinde aktarım (tam ülke birleştirmeden önce)
	var moved: Dictionary = {}
	for s in _t("split", id):
		var src: int = int(idx.get(s[1], -1))
		var dst: int = int(idx.get(s[2], -1))
		if src < 0 or dst < 0:
			continue
		var hit := false
		for p in gs.provinces:
			var match_: bool = (p.id == int(s[0])) if typeof(s[0]) == TYPE_INT else (p.name == s[0])
			if orig[p.id] == src and match_ and not moved.has(p.id):
				hit = true
				moved[p.id] = true
				if s[3] == "own":
					_own(gs, p, dst)
				else:
					p.controller = dst
		if not hit:
			push_warning("Eras.SPLIT eşleşmedi: %s" % [s])
	# 2) tam ülke birleştirme
	var group: Dictionary = {}     # eyalet -> host
	for p in gs.provinces:
		if moved.has(p.id) and p.owner != orig[p.id]:
			group[p.id] = p.owner
		elif host_of.has(p.owner) and not moved.has(p.id):
			var hh: int = host_of[p.owner]
			_own(gs, p, hh)
			group[p.id] = hh
		else:
			group[p.id] = p.owner
	for cid2 in host_of:
		var ac = gs.countries[cid2]
		ac.alive = false
	# 3) nüfus ve GSYH ölçekleri
	var pop_f: Dictionary = _t("pop_f", id)
	var DEFS_ID: Dictionary = _t("defs", id)
	var raw: Dictionary = {}
	for p in gs.provinces:
		var h2: int = int(group[p.id])
		var w: float = 1.0 if (orig[p.id] == h2 or not host_of.has(orig[p.id]) and not moved.has(p.id)) else COLONY_W
		if moved.has(p.id) and p.owner != orig[p.id]:
			w = 0.8
		raw[h2] = float(raw.get(h2, 0.0)) + p.gdp * w
	for p in gs.provinces:
		var h3: int = int(group[p.id])
		var hc = gs.countries[h3]
		var oc = gs.countries[orig[p.id]]
		var w2: float = 1.0 if (orig[p.id] == h3 or not host_of.has(orig[p.id]) and not moved.has(p.id)) else COLONY_W
		if moved.has(p.id) and p.owner != orig[p.id]:
			w2 = 0.8
		var d: Dictionary = DEFS_ID.get(hc.name_en, {})
		var f: float
		if d.has("gdp") and float(raw.get(h3, 0.0)) > 0.0:
			f = float(d["gdp"]) * 1000.0 / float(raw[h3])
		else:
			f = float(_t("gdp_default", id))
		p.gdp = p.gdp * w2 * f
		p.pop = p.pop * float(pop_f.get(oc.continent, 0.4))
	# 4) isim, renk, lider
	for n3 in DEFS_ID:
		var cid3: int = int(idx.get(n3, -1))
		if cid3 < 0:
			continue
		var c = gs.countries[cid3]
		var d3: Dictionary = DEFS_ID[n3]
		c.name = d3["name"]
		c.color = Color(d3["color"])
		c.leader = d3.get("leader", "")
	var CAP: Dictionary = _t("capital", id)
	for cap_name in CAP:
		var ccid: int = int(idx.get(cap_name, -1))
		var cpid: int = int(CAP[cap_name])
		if ccid >= 0 and gs.provinces[cpid].owner == ccid:
			var oc2 = gs.countries[ccid]
			if oc2.capital >= 0:
				gs.provinces[oc2.capital].is_capital = false
			oc2.capital = cpid
			gs.provinces[cpid].is_capital = true
	# 5) güç ve ordular yeniden kurulur
	gs.refresh_stats()
	for c2 in gs.countries:
		c2.pop = 0.0
		c2.gdp = 0.0
	for p in gs.provinces:
		if p.owner >= 0:
			gs.countries[p.owner].pop += p.pop
			gs.countries[p.owner].gdp += p.gdp
	var has_prov: Dictionary = {}
	for pp in gs.provinces:
		if pp.owner >= 0:
			has_prov[pp.owner] = true
	for c5 in gs.countries:
		if c5.alive and not c5.is_rebel and not has_prov.has(c5.id):
			c5.alive = false
	for c4 in gs.countries:
		if not c4.alive:
			c4.owned_ids = []
	gs.rebuild_after_era()


static func _own(gs, p, host: int) -> void:
	var was: bool = p.is_capital
	p.owner = host
	p.controller = host
	p.core = host
	p.home = host
	if was:
		p.is_capital = false


## Dönemin ittifakları, savaşları ve tarihi (oyun başlarken çağrılır; oyuncu seçildikten sonra)
static func start(gs, id: String) -> void:
	var st: Dictionary = _t("setup", id)
	var intro: String = String(st["intro"])
	if Loc.lang != "tr" and EraExt.has_era(id) and (EraExt.raw(id).get("en", {}) as Dictionary).has("setup_intro"):
		intro = DataUtil.loc_text(intro, String(EraExt.raw(id)["en"]["setup_intro"]))
	var sc: Dictionary = (st as Dictionary).duplicate(true)
	sc["intro"] = intro
	Scenarios.apply_dict(gs, sc, true)
	var odef: Dictionary = {"id": id}
	if EraExt.has_era(id) and EraExt.raw(id).has("objectives"):
		odef["objectives"] = EraExt.raw(id)["objectives"]
		odef["en"] = EraExt.raw(id).get("en", {})
	Objectives.begin(gs, odef)
	var idx: Dictionary = gs.macro_idx
	for t in st["truce"]:
		var a: int = int(idx.get(t[0], -1))
		var b: int = int(idx.get(t[1], -1))
		if a >= 0 and b >= 0:
			gs.countries[a].truce[b] = gs.turn + int(t[2])
			gs.countries[b].truce[a] = gs.turn + int(t[2])


static func look(id: String) -> Dictionary:
	return get_era(id).get("look", {})


## Tarihî lider zinciri: bu tarihte rastgele lider değişimi kapalı mı?
static func leader_chain_active(turn: int) -> bool:
	if current == "":
		return false
	return EraLeaders.chain_active(current, int(Names.year_month(turn)[0]))


## Her tur çağrılır; ayın ilk turunda tarihî liderleri değiştirir.
static func leaders_tick(gs) -> void:
	if current == "" or gs.turn <= 0:
		return
	EraEvents.tick(gs, current, Names.year_month(gs.turn - 1), Names.year_month(gs.turn))
	var changed: Array = EraLeaders.tick(gs, current, Names.year_month(gs.turn - 1), Names.year_month(gs.turn))
	for cid in changed:
		var c = gs.countries[cid]
		var ld: Array = Macro.leader_of(c)
		var close: bool = gs.player >= 0 and (c.enemies.has(gs.player) or c.allies.has(gs.player) or gs.neighbor_countries(gs.player).has(c.id))
		if close:
			gs.post_news("%s'de yeni lider: %s %s göreve başladı." % [c.name, ld[0], ld[1]], -1, "info")


## Eski kayıtlar için: dönemin başlangıç lideri + o tarihe kadarki tarihî değişimler.
static func leader_at(id: String, name_en: String, turn: int) -> String:
	var cur: String = String((_t("defs", id) as Dictionary).get(name_en, {}).get("leader", ""))
	var ym: Array = Names.year_month(turn)
	var key: int = int(ym[0]) * 12 + int(ym[1]) - 1
	for e in EraLeaders.chain_of(id).get(name_en, []):
		if int(e[0]) * 12 + int(e[1]) - 1 <= key:
			cur = String(e[2])
	return cur
