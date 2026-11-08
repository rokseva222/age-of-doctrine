extends RefCounted
## Kurgusal milis, isyancı grup, paralı asker şirketi ve gizli hücre isimleri.
## Her isim, ülkenin kültürüne göre üretilir; Rusya, Türkiye, Tayvan, Japonya ve ABD için ayrı havuzlar vardır.
## Tamamen uydurmadır; gerçek örgüt, şirket ya da hareket adı kullanılmaz.

const Sil = preload("res://scripts/silhouette.gd")

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


static func _pool(c) -> Dictionary:
	if c != null and SPECIAL.has(c.name_en):
		return SPECIAL[c.name_en]
	var cul: String = Sil.culture_for(c) if c != null else "west"
	return POOLS.get(cul, POOLS["west"])


static func make(c, rng: RandomNumberGenerator, kind: String) -> String:
	var p: Dictionary = _pool(c)
	var a: String = p["a"][rng.randi_range(0, p["a"].size() - 1)]
	var b: String = p["b"][rng.randi_range(0, p["b"].size() - 1)]
	if kind == "rebel":
		return "%s %s" % [a, b]
	var t: Array = TYPE[kind]
	# paralı şirket ve gizli hücre: simge + tür ("Çelik Kılıç Güvenlik Hizmetleri")
	return "%s %s" % [a, t[rng.randi_range(0, t.size() - 1)]]


## Kullanılmış adlara numara ekler ("Kuzey Kurtları 2").
static func unique(base: String, used: Dictionary) -> String:
	var n: int = used.get(base, 0) + 1
	used[base] = n
	return base if n == 1 else "%s %d" % [base, n]
