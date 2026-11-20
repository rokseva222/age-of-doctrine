extends RefCounted
## Kurgusal milis, isyancı grup, paralı asker şirketi ve gizli hücre isimleri.
## Her isim, ülkenin kültürüne göre üretilir; Rusya, Türkiye, Tayvan, Japonya ve ABD için ayrı havuzlar vardır.
## Tamamen uydurmadır; gerçek örgüt, şirket ya da hareket adı kullanılmaz.

const Sil = preload("res://scripts/silhouette.gd")
const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const Loc = preload("res://scripts/loc.gd")

# Eski çağ (Osmanlı 1520, Timur 1380): "şirket/hizmetleri" yok; bölük, alay, ocak, sancak
const PRE_POOL := {"a": ["Kara Kartal", "Demir Kılıç", "Kızıl Atlı", "Bozkurt", "Çelik Yay", "Gümüş Kalkan", "Altın Mızrak", "Kara Şahin", "Yeşil Sancak", "Dağ Aslanı", "Tuna Kurdu", "Kervan Muhafızı", "Akıncı", "Yörük", "Tuğ"],
	"b": ["Ordusu", "Ayaklanması", "Sancağı", "Bayrağı", "Hareketi"]}
const PRE_TYPE := {
	"rebel": ["Ordusu", "Ayaklanması", "Sancağı", "Bayrağı"],
	"merc": ["Bölüğü", "Alayı", "Ocağı", "Sancağı", "Cemaati"],
	"cell": ["Cemiyeti", "Kardeşliği", "Gizli Ocağı", "Derneği"],
}
const WW_TYPE := {
	"merc": ["Gönüllü Taburu", "Müfrezesi", "Lejyonu", "Komando Müfrezesi", "Taburu"],
	"cell": ["Komitesi", "Hücresi", "Yeraltı Ağı", "Gölge Cephesi"],
}

# a: niteleyici / yer, b: simge (hayvan, doğa, nesne). Sonra tür eki gelir.
const POOLS := {
	"west": {"a": ["Özgürlük", "Vatansever", "Kızıl Kanyon", "Preri", "Nehir", "Bayrak", "Kuzey Yıldızı", "Demir Vadi", "Çam Ormanı", "Altın Kıyı"],
		"b": ["Korucuları", "Nöbetçileri", "Kurtları", "Kartalları", "Gönüllüleri", "Atlıları"]},
	"slav": {"a": ["Kuzey", "Kızıl Şafak", "Volga", "Taiga", "Ural", "Çelik", "Kar Fırtınası", "Beyaz Kuğu", "Don", "Karpat"],
		"b": ["Kurtları", "Ayıları", "Gönüllüleri", "Yoldaşları", "Kazakları", "Hayaletleri"]},
	"turk": {"a": ["Bozkır", "Altay", "Çelik", "Kuzey", "Demir", "Tuna", "Kafkas", "Dağ", "Yörük", "Tuğ"],
		"b": ["Atlıları", "Kartalları", "Börüleri", "Yiğitleri", "Akıncıları", "Nöbetçileri"]},
	"gulf": {"a": ["Çöl", "Kum Fırtınası", "İnci", "Hurma", "Kızıl Kum", "Vaha", "Şahin", "Karakum"],
		"b": ["Kılıcı", "Şahinleri", "Muhafızları", "Develeri", "Atlıları", "Nöbetçileri"]},
	"lev": {"a": ["Sedir", "Fenike", "Akdeniz", "Dağ", "Zeytin Gölgesi", "Kervan", "Kıyı", "Antik Yol"],
		"b": ["Kardeşliği", "Muhafızları", "Gönüllüleri", "Kartalları", "Nöbetçileri"]},
	"pers": {"a": ["Zagros", "Elburz", "Simurg", "Kuzey Rüzgârı", "Lale", "Dağ", "Hazar", "Aslan"],
		"b": ["Aslanları", "Muhafızları", "Gönüllüleri", "Kartalları", "Yoldaşları"]},
	"sasia": {"a": ["Himalaya", "Ganj", "Safran", "Kaplan", "Muson", "Lotus", "Karakurum", "Delta"],
		"b": ["Kaplanları", "Gönüllüleri", "Muhafızları", "Nöbetçileri", "Fil Süvarileri"]},
	"easia": {"a": ["Bambu", "Ejder", "Sis Dağı", "Gümüş Turna", "Yeşim", "Kuzey Denizi", "Kızıl Lotus", "Pagoda"],
		"b": ["Muhafızları", "Hücresi", "Kardeşliği", "Kaplanları", "Gölgeleri"]},
	"seasia": {"a": ["Orman", "Mekong", "Adalar", "Mercan", "Muson", "Pirinç", "Tapınak", "Nehir"],
		"b": ["Kaplanları", "Gönüllüleri", "Muhafızları", "Gölgeleri", "Kurtuluşçuları"]},
	"afr": {"a": ["Savan", "Aslan Yürekliler", "Nil", "Kalahari", "Baobab", "Kızıl Toprak", "Büyük Vadi", "Sahel"],
		"b": ["Kartalları", "Gönüllüleri", "Muhafızları", "Savaşçıları", "Nöbetçileri"]},
	"latam": {"a": ["Kondor", "And", "Yağmur Ormanı", "Jaguar", "Pampa", "Kızıl Vadi", "Kaktüs", "Gümüş Dağ"],
		"b": ["Gerillaları", "Muhafızları", "Gönüllüleri", "Atlıları", "Nöbetçileri"]},
	"pac": {"a": ["Mercan", "Okyanus", "Dalga", "Hindistan Cevizi", "Volkan", "Kıyı", "Çapa"],
		"b": ["Muhafızları", "Gönüllüleri", "Kürekçileri", "Nöbetçileri"]},
}

# ülkeye özel havuzlar (kültür havuzunun yerine geçer)
const SPECIAL := {
	"Russia": {"a": ["Kuzey Ayısı", "Beyaz Kuğu", "Kızıl Kar", "Ural Hayaleti", "Sibirya", "Buzkıran", "Tundra", "Çelik Kutup"],
		"b": ["Gönüllü Taburu", "Kazak Bölüğü", "Yoldaşlar Birliği", "Tugayı", "Volkodav Müfrezesi"]},
	"Turkey": {"a": ["Dağ Kartalı", "Çelik Yörük", "Kuzey Yiğidi", "Bozkır", "Demir Kağan", "Kızıl Kayalık", "Tuna Akıncısı", "Kuzey Rüzgârı"],
		"b": ["Birliği", "Tugayı", "Müfrezesi", "Alayı", "Gönüllüleri"]},
	"Taiwan": {"a": ["Yeşim Ada", "Bambu Perdesi", "Sisli Dağ", "Gümüş Dalga", "Kırlangıç", "Mavi Boğaz", "Orkide"],
		"b": ["Direniş Hücresi", "Savunma Gönüllüleri", "Ada Muhafızları", "Gölge Birliği"]},
	"Japan": {"a": ["Kuzey Yıldızı", "Gölge Ronin", "Şogun Mirası", "Kiri", "Gümüş Turna", "Ay Kılıcı", "Sakura Fırtınası"],
		"b": ["Dojo Birliği", "Cephesi", "Muhafız Birliği", "Hareketi", "Klan Ordusu"]},
	"United States of America": {"a": ["Liberty Vadisi", "Kızıl Kanyon", "Preri Kurdu", "Yıldızlı Nehir", "Çelik Sınır", "Altın Eyalet", "Vatansever Nöbet"],
		"b": ["Milisleri", "Korucuları", "Gönüllü Taburu", "Kuvvetleri", "Muhafızları"]},
}

const TYPE := {
	"rebel": ["Cephesi", "Hareketi", "Ordusu", "Birliği", "Direnişi"],
	"merc": ["Güvenlik Hizmetleri", "Özel Harekât Şirketi", "Askerî Danışmanlık", "Savunma Hizmetleri", "Taktik Grup"],
	"cell": ["Hücresi", "Yeraltı Ağı", "Komitesi", "Gölge Cephesi", "Fedai Grubu"],
}


## Üretilen grup adları Türkçe sözcüklerden kurulur; Türkçe dışındaki dillerde İngilizce karşılığı gösterilir.
const EN := {
	"Ada Muhafızları": "Island Guards",
	"Adalar": "Islands",
	"Akdeniz": "Mediterranean",
	"Akıncı": "Raider",
	"Akıncıları": "Raiders",
	"Alayı": "Regiment",
	"Altay": "Altai",
	"Altın Eyalet": "Golden State",
	"Altın Kıyı": "Gold Coast",
	"Altın Mızrak": "Golden Spear",
	"And": "Andes",
	"Antik Yol": "Ancient Road",
	"Askerî Danışmanlık": "Military Consulting",
	"Aslan": "Lion",
	"Aslan Yürekliler": "Lionhearts",
	"Aslanları": "Lions",
	"Atlıları": "Horsemen",
	"Ay Kılıcı": "Moon Blade",
	"Ayaklanması": "Uprising",
	"Ayıları": "Bears",
	"Bambu": "Bamboo",
	"Bambu Perdesi": "Bamboo Curtain",
	"Baobab": "Baobab",
	"Bayrak": "Banner",
	"Bayrağı": "Banner",
	"Beyaz Kuğu": "White Swan",
	"Birliği": "Union",
	"Bozkurt": "Grey Wolf",
	"Bozkır": "Steppe",
	"Buzkıran": "Icebreaker",
	"Bölüğü": "Company",
	"Börüleri": "Wolves",
	"Büyük Vadi": "Great Valley",
	"Cemaati": "Congregation",
	"Cemiyeti": "Society",
	"Cephesi": "Front",
	"Dalga": "Wave",
	"Dağ": "Mountain",
	"Dağ Aslanı": "Mountain Lion",
	"Dağ Kartalı": "Mountain Eagle",
	"Delta": "Delta",
	"Demir": "Iron",
	"Demir Kağan": "Iron Khagan",
	"Demir Kılıç": "Iron Sword",
	"Demir Vadi": "Iron Valley",
	"Derneği": "Association",
	"Develeri": "Camel Riders",
	"Direniş Hücresi": "Resistance Cell",
	"Direnişi": "Resistance",
	"Dojo Birliği": "Dojo Union",
	"Don": "Don",
	"Ejder": "Dragon",
	"Elburz": "Alborz",
	"Fedai Grubu": "Fedayeen Group",
	"Fenike": "Phoenician",
	"Fil Süvarileri": "Elephant Cavalry",
	"Ganj": "Ganges",
	"Gerillaları": "Guerrillas",
	"Gizli Ocağı": "Secret Circle",
	"Gölge Birliği": "Shadow Union",
	"Gölge Cephesi": "Shadow Front",
	"Gölge Ronin": "Shadow Ronin",
	"Gölgeleri": "Shadows",
	"Gönüllü Taburu": "Volunteer Battalion",
	"Gönüllüleri": "Volunteers",
	"Gümüş Dalga": "Silver Wave",
	"Gümüş Dağ": "Silver Mountain",
	"Gümüş Kalkan": "Silver Shield",
	"Gümüş Turna": "Silver Crane",
	"Güvenlik Hizmetleri": "Security Services",
	"Hareketi": "Movement",
	"Hayaletleri": "Ghosts",
	"Hazar": "Caspian",
	"Himalaya": "Himalaya",
	"Hindistan Cevizi": "Coconut",
	"Hurma": "Date Palm",
	"Hücresi": "Cell",
	"Jaguar": "Jaguar",
	"Kafkas": "Caucasus",
	"Kaktüs": "Cactus",
	"Kalahari": "Kalahari",
	"Kaplan": "Tiger",
	"Kaplanları": "Tigers",
	"Kar Fırtınası": "Snowstorm",
	"Kara Kartal": "Black Eagle",
	"Kara Şahin": "Black Falcon",
	"Karakum": "Karakum",
	"Karakurum": "Karakoram",
	"Kardeşliği": "Brotherhood",
	"Karpat": "Carpathian",
	"Kartalları": "Eagles",
	"Kazak Bölüğü": "Cossack Company",
	"Kazakları": "Cossacks",
	"Kervan": "Caravan",
	"Kervan Muhafızı": "Caravan Guard",
	"Kiri": "Kiri",
	"Klan Ordusu": "Clan Army",
	"Komando Müfrezesi": "Commando Detachment",
	"Komitesi": "Committee",
	"Kondor": "Condor",
	"Korucuları": "Rangers",
	"Kum Fırtınası": "Sandstorm",
	"Kurtları": "Wolves",
	"Kurtuluşçuları": "Liberators",
	"Kuvvetleri": "Forces",
	"Kuzey": "Northern",
	"Kuzey Ayısı": "Northern Bear",
	"Kuzey Denizi": "North Sea",
	"Kuzey Rüzgârı": "North Wind",
	"Kuzey Yiğidi": "Northern Valor",
	"Kuzey Yıldızı": "North Star",
	"Kürekçileri": "Oarsmen",
	"Kılıcı": "Sword",
	"Kırlangıç": "Swallow",
	"Kıyı": "Coastal",
	"Kızıl Atlı": "Red Rider",
	"Kızıl Kanyon": "Red Canyon",
	"Kızıl Kar": "Red Snow",
	"Kızıl Kayalık": "Red Rock",
	"Kızıl Kum": "Red Sand",
	"Kızıl Lotus": "Red Lotus",
	"Kızıl Toprak": "Red Earth",
	"Kızıl Vadi": "Red Valley",
	"Kızıl Şafak": "Red Dawn",
	"Lale": "Tulip",
	"Lejyonu": "Legion",
	"Liberty Vadisi": "Liberty Valley",
	"Lotus": "Lotus",
	"Mavi Boğaz": "Blue Strait",
	"Mekong": "Mekong",
	"Mercan": "Coral",
	"Milisleri": "Militia",
	"Muhafız Birliği": "Guard Union",
	"Muhafızları": "Guardians",
	"Muson": "Monsoon",
	"Müfrezesi": "Detachment",
	"Nehir": "River",
	"Nil": "Nile",
	"Nöbetçileri": "Sentinels",
	"Ocağı": "Hearth",
	"Okyanus": "Ocean",
	"Ordusu": "Army",
	"Orkide": "Orchid",
	"Orman": "Forest",
	"Pagoda": "Pagoda",
	"Pampa": "Pampas",
	"Pirinç": "Rice",
	"Preri": "Prairie",
	"Preri Kurdu": "Prairie Wolf",
	"Safran": "Saffron",
	"Sahel": "Sahel",
	"Sakura Fırtınası": "Sakura Storm",
	"Sancağı": "Standard",
	"Savan": "Savanna",
	"Savaşçıları": "Warriors",
	"Savunma Gönüllüleri": "Defense Volunteers",
	"Savunma Hizmetleri": "Defense Services",
	"Sedir": "Cedar",
	"Sibirya": "Siberia",
	"Simurg": "Simurgh",
	"Sis Dağı": "Mist Mountain",
	"Sisli Dağ": "Misty Mountain",
	"Taburu": "Battalion",
	"Taiga": "Taiga",
	"Taktik Grup": "Tactical Group",
	"Tapınak": "Temple",
	"Tugayı": "Brigade",
	"Tuna": "Danube",
	"Tuna Akıncısı": "Danube Raider",
	"Tuna Kurdu": "Danube Wolf",
	"Tundra": "Tundra",
	"Tuğ": "Horsetail Standard",
	"Ural": "Ural",
	"Ural Hayaleti": "Ural Ghost",
	"Vaha": "Oasis",
	"Vatansever": "Patriot",
	"Vatansever Nöbet": "Patriot Watch",
	"Volga": "Volga",
	"Volkan": "Volcano",
	"Volkodav Müfrezesi": "Wolfhound Detachment",
	"Yağmur Ormanı": "Rainforest",
	"Yeraltı Ağı": "Underground Network",
	"Yeşil Sancak": "Green Standard",
	"Yeşim": "Jade",
	"Yeşim Ada": "Jade Island",
	"Yiğitleri": "Braves",
	"Yoldaşlar Birliği": "Comrades' Union",
	"Yoldaşları": "Comrades",
	"Yörük": "Nomad",
	"Yıldızlı Nehir": "Starry River",
	"Zagros": "Zagros",
	"Zeytin Gölgesi": "Olive Shade",
	"Çam Ormanı": "Pine Forest",
	"Çapa": "Anchor",
	"Çelik": "Steel",
	"Çelik Kutup": "Steel Pole",
	"Çelik Sınır": "Steel Border",
	"Çelik Yay": "Steel Bow",
	"Çelik Yörük": "Steel Nomad",
	"Çöl": "Desert",
	"Özel Harekât Şirketi": "Special Operations Company",
	"Özgürlük": "Freedom",
	"İnci": "Pearl",
	"Şahin": "Falcon",
	"Şahinleri": "Falcons",
	"Şogun Mirası": "Shogun's Legacy"
}

static func _w(w: String) -> String:
	if Loc.lang == "tr":
		return w
	return EN.get(w, w)


static func _pool(c) -> Dictionary:
	if c != null and SPECIAL.has(c.name_en):
		return SPECIAL[c.name_en]
	var cul: String = Sil.culture_for(c) if c != null else "west"
	return POOLS.get(cul, POOLS["west"])


static func _fam() -> String:
	return Eras.family() if Macro.era_on else ""


static func make(c, rng: RandomNumberGenerator, kind: String) -> String:
	var fam: String = _fam()
	if fam == "pre":
		var a0: String = PRE_POOL["a"][rng.randi_range(0, PRE_POOL["a"].size() - 1)]
		var t0: Array = PRE_TYPE[kind]
		return "%s %s" % [_w(a0), _w(t0[rng.randi_range(0, t0.size() - 1)])]
	var p: Dictionary = _pool(c)
	var a: String = p["a"][rng.randi_range(0, p["a"].size() - 1)]
	var b: String = p["b"][rng.randi_range(0, p["b"].size() - 1)]
	if kind == "rebel":
		return "%s %s" % [_w(a), _w(b)]
	var t: Array = WW_TYPE[kind] if (fam == "ww1" or fam == "ww2") and WW_TYPE.has(kind) else TYPE[kind]
	# paralı şirket ve gizli hücre: simge + tür ("Çelik Kılıç Güvenlik Hizmetleri")
	return "%s %s" % [_w(a), _w(t[rng.randi_range(0, t.size() - 1)])]


## Kullanılmış adlara numara ekler ("Kuzey Kurtları 2").
static func unique(base: String, used: Dictionary) -> String:
	var n: int = used.get(base, 0) + 1
	used[base] = n
	return base if n == 1 else "%s %d" % [base, n]
