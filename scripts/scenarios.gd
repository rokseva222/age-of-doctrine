extends RefCounted
## Senaryolar: gerçek dünya krizleri ve kurgusal modern senaryolar.
## Ülke adları world.json'daki name_en alanıdır. Kurgusal gruplar tamamen uydurmadır; gerçek örgüt/sembol kullanılmaz.

const Macro = preload("res://scripts/macro.gd")
const Emblem = preload("res://scripts/emblem.gd")
const DataUtil = preload("res://scripts/data_util.gd")
const Loc = preload("res://scripts/loc.gd")
const Objectives = preload("res://scripts/objectives.gd")

const KIND_ORDER := ["free", "real", "fiction", "user"]
const USER_DIR := "user://scenarios"
const DATA_DIR := "res://data/scenarios"

static var _raw_ext: Array = []
static var _loaded := false
static var _cache: Array = []
static var _cache_lang := "?"

const NATO := ["United States of America", "Canada", "United Kingdom", "France", "Germany", "Italy", "Spain", "Portugal", "Netherlands",
	"Belgium", "Luxembourg", "Denmark", "Norway", "Iceland", "Poland", "Czechia", "Slovakia", "Hungary", "Romania", "Bulgaria", "Greece",
	"Turkey", "Albania", "Croatia", "Slovenia", "Montenegro", "North Macedonia", "Estonia", "Latvia", "Lithuania", "Finland", "Sweden"]

const LIST := [
	{"id": "free", "kind": "free", "name": "Dünya 2027", "sub": "Serbest oyun",
		"blurb": "Başlangıçta savaş yok. Haritadaki 200 ülkeden birini seç; bütçeni, ordunu ve ittifaklarını kendin kur.",
		"suggest": []},
	# ---------------- gerçek dünya krizleri
	{"id": "ukr", "kind": "real", "name": "Doğu Cephesi", "sub": "Rusya – Ukrayna",
		"blurb": "Avrupa'nın en büyük kara savaşı sürüyor. Rusya kitlesel ordusuyla, Ukrayna Batı desteğiyle direniyor; siber ve lojistik hatlar cephe kadar önemli.",
		"suggest": ["Ukraine", "Russia", "Poland", "Turkey", "Germany"],
		"wars": [["Russia", "Ukraine"]],
		"blocs": [{"name": "Kuzey Atlantik İttifakı", "members": "NATO", "emblem": {"shape": 0, "inner": 2, "symbol": "star", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Toplu Güvenlik Paktı", "members": ["Russia", "Belarus", "Armenia", "Kazakhstan", "Kyrgyzstan", "Tajikistan"],
				"emblem": {"shape": 2, "inner": 1, "symbol": "shield", "c1": "b0402a", "c2": "ece6d6", "c3": "b0402a"}}],
		"budget_war": ["Russia", "Ukraine"],
		"intro": "Doğu Cephesi: Rusya ile Ukrayna arasında geniş çaplı savaş sürüyor. Batı ülkeleri Ukrayna'ya ekonomik ve askerî destek veriyor."},
	{"id": "twn", "kind": "real", "name": "Boğaz Krizi", "sub": "Çin – Tayvan",
		"blurb": "Çin, Tayvan Boğazı'nda deniz ve hava ablukası başlattı. ABD ve Japonya'nın müdahalesi ve yarı iletken tedariki dünya ekonomisini belirleyecek.",
		"suggest": ["Taiwan", "China", "United States of America", "Japan", "South Korea"],
		"ally_first": true,
		"blocs": [{"name": "Pasifik Savunma Hattı", "members": ["Taiwan", "United States of America", "Japan", "South Korea", "Philippines", "Australia"],
				"emblem": {"shape": 1, "inner": 1, "symbol": "anchor", "c1": "2f6fa8", "c2": "ece6d6", "c3": "2f6fa8"}},
			{"name": "Avrasya Ortaklığı", "members": ["China", "Russia", "North Korea"],
				"emblem": {"shape": 3, "inner": 1, "symbol": "star", "c1": "b0402a", "c2": "e3a92b", "c3": "b0402a"}}],
		"wars": [["China", "Taiwan"]],
		"embargo": [["China", "United States of America"]],
		"budget_war": ["China", "Taiwan"],
		"intro": "Boğaz Krizi: Çin donanması Tayvan'ı kuşattı. Yarı iletken tedarik zinciri kesildi; ABD ve müttefikleri hazırlık yapıyor."},
	{"id": "irn", "kind": "real", "name": "Körfez Ateşi", "sub": "İran – İsrail – ABD",
		"blurb": "İran ile İsrail doğrudan savaşta; ABD İsrail'in yanında. Hürmüz Boğazı ve petrol akışı tehdit altında, siber saldırılar şebekeleri vuruyor.",
		"suggest": ["Iran", "Israel", "United States of America", "Saudi Arabia", "Turkey"],
		"ally_first": true,
		"blocs": [{"name": "Atlantik Güvenlik Ortaklığı", "members": ["United States of America", "Israel"],
				"emblem": {"shape": 5, "inner": 1, "symbol": "shield", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Direniş Ekseni", "members": ["Iran", "Syria"],
				"emblem": {"shape": 6, "inner": 2, "symbol": "flame", "c1": "2f8f83", "c2": "ece6d6", "c3": "2f8f83"}}],
		"wars": [["Iran", "Israel"]],
		"budget_war": ["Iran", "Israel", "United States of America"],
		"cyber": {"Iran": 30, "Israel": 30},
		"intro": "Körfez Ateşi: İran füze ve İHA salvolarıyla İsrail'i vurdu; ABD bölgeye donanma gönderdi."},
	{"id": "ind", "kind": "real", "name": "Himalaya Gölgesi", "sub": "Hindistan – Pakistan",
		"blurb": "Keşmir sınırında çatışma tam savaşa döndü. Çin Pakistan'ın arkasında, Rusya Hindistan'a silah akıtıyor; iki nükleer ülke arasında zaman daralıyor.",
		"suggest": ["India", "Pakistan", "China", "Russia", "United States of America"],
		"ally_first": true,
		"blocs": [{"name": "Karakurum Ortaklığı", "members": ["Pakistan", "China"], "emblem": {"shape": 2, "inner": 1, "symbol": "crown", "c1": "5db86e", "c2": "ece6d6", "c3": "5db86e"}}],
		"wars": [["India", "Pakistan"]],
		"budget_war": ["India", "Pakistan"],
		"intro": "Himalaya Gölgesi: Hindistan ve Pakistan sınır boyunca birbirine ateş açtı. Her iki başkentte olağanüstü hâl ilan edildi."},
	{"id": "kor", "kind": "real", "name": "38. Paralel", "sub": "Kuzey Kore – Güney Kore",
		"blurb": "Kuzey Kore topçusu Seul'ü menzile aldı. Dünyanın en yoğun silahlı sınırında hava gücü ve siber savaş belirleyici.",
		"suggest": ["South Korea", "North Korea", "United States of America", "Japan", "China"],
		"ally_first": true,
		"blocs": [{"name": "Pasifik Savunma Birliği", "members": ["South Korea", "United States of America", "Japan"],
				"emblem": {"shape": 0, "inner": 1, "symbol": "anchor", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Kuzey Ekseni", "members": ["North Korea", "China", "Russia"],
				"emblem": {"shape": 3, "inner": 1, "symbol": "star", "c1": "b0402a", "c2": "ece6d6", "c3": "b0402a"}}],
		"wars": [["North Korea", "South Korea"]],
		"budget_war": ["North Korea", "South Korea"],
		"intro": "38. Paralel: Kuzey Kore sınır boyunca topçu ateşi açtı. Güney Kore ve ABD savunma planlarını devreye aldı."},
	{"id": "cau", "kind": "real", "name": "Kafkas Düğümü", "sub": "Azerbaycan – Ermenistan",
		"blurb": "Karabağ sonrası gerilim yeniden alevlendi. Türkiye Azerbaycan'ın, Rusya Ermenistan'ın yanında; koridor ve enerji hatları tehlikede.",
		"suggest": ["Azerbaijan", "Armenia", "Turkey", "Russia", "Iran"],
		"blocs": [{"name": "Hazar Anadolu Hattı", "members": ["Azerbaijan", "Turkey"], "emblem": {"shape": 6, "inner": 2, "symbol": "star", "c1": "2f8f83", "c2": "e3a92b", "c3": "2f8f83"}}],
		"wars": [["Azerbaijan", "Armenia"]],
		"budget_war": ["Azerbaijan", "Armenia"],
		"intro": "Kafkas Düğümü: Azerbaycan ve Ermenistan sınırında yeniden büyük çatışma başladı."},
	# ---------------- kurgusal modern senaryolar
	{"id": "kara", "kind": "fiction", "name": "Kara Sancak", "sub": "Kurgusal: aşırılıkçı yeniden doğuş",
		"blurb": "Suriye ve Irak'ın çölünde, kurgusal bir aşırılıkçı yapı olan Kara Sancak Hilafeti birkaç eyaleti ele geçirip hızla büyüyor. Bölgedeki devletler tek tek çözülürken kimin müdahale edeceği belirsiz.",
		"suggest": ["Turkey", "Syria", "Iraq", "Iran", "Israel"],
		"factions": [{"name": "Kara Sancak Hilafeti", "leader": "Halife|Ebu Zeyd el-Kerrar", "from": [["Syria", 3], ["Iraq", 3]], "dir": "east", "troops": 55000, "tech": 0.2, "doctrine": 4,
				"colors": ["1c1f24", "e58a3a", "ece6d6"], "pattern": 2, "aggression": 1.0}],
		"intro": "Kara Sancak: Çöl kuşağında yeni bir aşırılıkçı yapı ortaya çıktı ve Suriye ile Irak'ın doğusunu ele geçirdi."},
	{"id": "reich", "kind": "fiction", "name": "Yeni Reich", "leader": "Lider|Konrad Hallstein", "sub": "Kurgusal: otoriter yeniden diriliş",
		"blurb": "Almanya'nın doğusunda, kurgusal bir otoriter hareket olan Yeni Reich ayrılıp modern bir ordu kurdu. Avrupa'nın demokrasileri tek cephede birleşmek zorunda. (Gerçek tarihî semboller kullanılmaz.)",
		"suggest": ["Germany", "Poland", "France", "Czechia", "United Kingdom"],
		"blocs": [{"name": "Avrupa Savunma Çemberi", "members": ["Germany", "Poland", "France", "Czechia", "Netherlands", "Denmark"],
				"emblem": {"shape": 1, "inner": 1, "symbol": "shield", "c1": "2f4f9a", "c2": "e3a92b", "c3": "2f4f9a"}}],
		"factions": [{"name": "Yeni Reich", "from": [["Germany", 5]], "dir": "east", "troops": 50000, "tech": 0.85, "doctrine": 1,
				"colors": ["3a3f47", "e3a92b", "ece6d6"], "pattern": 1, "aggression": 1.0}],
		"intro": "Yeni Reich: Almanya'nın doğusunda otoriter bir ayrılıkçı yapı ilan edildi. Avrupa başkentleri olağanüstü toplandı."},
	{"id": "balt", "kind": "fiction", "name": "Baltık Kıvılcımı", "sub": "Kurgusal: kuzeyde büyük savaş",
		"blurb": "Rusya, Estonya ve Letonya'ya karşı sınır ihlalini gerekçe göstererek harekete geçti. NATO maddesi devrede: kuzeyde başlayan kıvılcım tüm kıtaya yayılabilir.",
		"suggest": ["Russia", "Estonia", "Poland", "Finland", "Germany"],
		"ally_first": true,
		"blocs": [{"name": "Kuzey Atlantik İttifakı", "members": "NATO", "emblem": {"shape": 0, "inner": 2, "symbol": "star", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}},
			{"name": "Toplu Güvenlik Paktı", "members": ["Russia", "Belarus", "Armenia", "Kazakhstan", "Kyrgyzstan", "Tajikistan"],
				"emblem": {"shape": 2, "inner": 1, "symbol": "shield", "c1": "b0402a", "c2": "ece6d6", "c3": "b0402a"}}],
		"wars": [["Russia", "Estonia"], ["Russia", "Latvia"]],
		"budget_war": ["Russia", "Estonia", "Latvia", "Poland", "Finland", "Germany"],
		"intro": "Baltık Kıvılcımı: Rus birlikleri Estonya ve Letonya sınırını geçti. NATO ortak savunma maddesini devreye aldı."},
	{"id": "napol", "kind": "fiction", "name": "İmparatorun Dönüşü", "sub": "Kurgusal: Napolyon çağı geri dönüyor",
		"blurb": "Fransa'da karizmatik bir general, 'Yeni İmparatorluk'u ilan edip ordunun bir kısmıyla Paris çevresini ele geçirdi. Devrim ruhu ve imparatorluk özlemi bir araya geldi; Avrupa bir kez daha nefesini tutuyor.",
		"suggest": ["France", "Germany", "Spain", "United Kingdom", "Italy"],
		"factions": [{"name": "Yeni İmparatorluk", "leader": "İmparator|Bonifaz Delmar", "from": [["France", 6]], "dir": "near", "troops": 45000, "tech": 0.9, "doctrine": 1,
				"colors": ["2f4f9a", "e3a92b", "ece6d6"], "pattern": 4, "aggression": 1.0}],
		"intro": "İmparatorun Dönüşü: Fransa'da general önderliğinde Yeni İmparatorluk ilan edildi; ordu ikiye bölündü."},
	{"id": "siber", "kind": "fiction", "name": "Sessiz Savaş", "sub": "Kurgusal: siber çağ, silahsız cephe",
		"blurb": "Topçu ateşi yok, ama dünya savaşta. Süper güçler birbirinin şebekelerini, limanlarını ve borsalarını vuruyor; ambargolar tırmanıyor. Fabrikaların ve lojistiğin güvenliği ordudan önemli.",
		"suggest": ["United States of America", "China", "Russia", "Germany", "Israel"],
		"embargo": [["United States of America", "China"], ["United States of America", "Russia"], ["Germany", "Russia"], ["France", "Russia"],
			["United Kingdom", "Russia"], ["Japan", "China"], ["India", "China"]],
		"cold": [["United States of America", "China"], ["United States of America", "Russia"], ["China", "India"], ["Russia", "United Kingdom"],
			["Israel", "Iran"], ["Japan", "China"], ["Germany", "Russia"], ["South Korea", "North Korea"]],
		"cyber": {"United States of America": 35, "China": 35, "Russia": 35, "Israel": 30, "Iran": 25, "North Korea": 30, "United Kingdom": 25, "Germany": 20},
		"doctrine": {"United States of America": 5, "China": 5, "Russia": 5, "Israel": 5, "United Kingdom": 5, "North Korea": 5, "Iran": 5},
		"cyber_budget": ["United States of America", "China", "Russia", "Israel", "United Kingdom", "Iran", "North Korea", "Germany", "Japan", "India"],
		"intro": "Sessiz Savaş: Büyük güçler arasında açık savaş yok; ama şebekeler, limanlar ve borsalar siber saldırı altında."},
]


## Dış senaryoları yeniden okur (editörde kayıttan sonra)
static func reload() -> void:
	_loaded = false
	_cache_lang = "?"


static func _load_ext() -> void:
	if _loaded:
		return
	_loaded = true
	_raw_ext = []
	for id in DataUtil.read_index(DATA_DIR):
		var d = DataUtil.read_json("%s/%s.json" % [DATA_DIR, id])
		if d is Dictionary and d.has("id"):
			_raw_ext.append(d)
	var da := DirAccess.open(USER_DIR)
	if da != null:
		var files := da.get_files()
		files.sort()
		for f in files:
			if f.ends_with(".json"):
				var u = DataUtil.read_json(USER_DIR + "/" + f)
				if u is Dictionary and u.has("id") and u.has("name"):
					u["kind"] = "user"
					_raw_ext.append(u)


static func _localized(d: Dictionary) -> Dictionary:
	var c: Dictionary = d.duplicate()
	for k in ["name", "sub", "blurb", "intro"]:
		c[k] = DataUtil.pick_en(d, k, Loc.lang)
	if not c.has("sub"):
		c["sub"] = ""
	if not c.has("blurb"):
		c["blurb"] = ""
	if not c.has("suggest"):
		c["suggest"] = []
	return c


## Tüm senaryolar: yerleşik + data/scenarios + kullanıcı senaryoları (tür sırasına göre)
static func all() -> Array:
	_load_ext()
	if _cache_lang == Loc.lang:
		return _cache
	_cache_lang = Loc.lang
	var pool: Array = LIST.duplicate()
	for d in _raw_ext:
		pool.append(_localized(d))
	var out: Array = []
	for kd in KIND_ORDER:
		for sc in pool:
			if String(sc["kind"]) == kd:
				out.append(sc)
	_cache = out
	return out


static func get_sc(id: String) -> Dictionary:
	for s in all():
		if s["id"] == id:
			return s
	return {}


## Kullanıcı senaryosu mu (silinebilir/düzenlenebilir)
static func is_user(id: String) -> bool:
	return String(get_sc(id).get("kind", "")) == "user"


static func apply(gs, id: String) -> void:
	var sc: Dictionary = get_sc(id)
	if sc.is_empty() or id == "free":
		return
	apply_dict(gs, sc, false)
	Objectives.begin(gs, sc)


static func apply_dict(gs, sc: Dictionary, force_ally_first: bool) -> void:
	gs.setup_mode = true
	_apply_dict(gs, sc, force_ally_first)
	gs.setup_mode = false


static func _apply_dict(gs, sc: Dictionary, force_ally_first: bool) -> void:
	var idx: Dictionary = gs.macro_idx
	_transfers(gs, sc, idx)
	if sc.get("ally_first", false) or force_ally_first:
		_blocs(gs, sc, idx)
		_wars(gs, sc, idx)
	else:
		_wars(gs, sc, idx)
		_blocs(gs, sc, idx)
	# kurgusal gruplar (savaş + müttefiklerin çağrılması)
	for f in sc.get("factions", []):
		gs.create_faction(f)
	for e in sc.get("embargo", []):
		var a: int = int(idx.get(e[0], -1))
		var b: int = int(idx.get(e[1], -1))
		if a >= 0 and b >= 0:
			gs.countries[a].embargo.append(b)
			gs.countries[b].embargo.append(a)
	for e2 in sc.get("cold", []):
		var a2: int = int(idx.get(e2[0], -1))
		var b2: int = int(idx.get(e2[1], -1))
		if a2 >= 0 and b2 >= 0:
			gs.cold.append([a2, b2])
	for n in sc.get("cyber", {}):
		var cid: int = int(idx.get(n, -1))
		if cid >= 0:
			gs.countries[cid].cyber = minf(100.0, gs.countries[cid].cyber + float(sc["cyber"][n]))
	for n2 in sc.get("doctrine", {}):
		var cid2: int = int(idx.get(n2, -1))
		if cid2 >= 0:
			gs.countries[cid2].doctrine = int(sc["doctrine"][n2])
	for n3 in sc.get("budget_war", []):
		var cid3: int = int(idx.get(n3, -1))
		if cid3 >= 0 and cid3 != gs.player:
			gs.countries[cid3].budget = Macro.PRESETS["war"].duplicate()
		elif cid3 >= 0:
			gs.countries[cid3].budget = Macro.PRESETS["war"].duplicate()
	for n4 in sc.get("cyber_budget", []):
		var cid4: int = int(idx.get(n4, -1))
		if cid4 >= 0:
			Macro.set_budget(gs.countries[cid4], "cyber", 22)
	_modifiers(gs, sc, idx)
	Macro.prime(gs)
	gs.post_news(sc.get("intro", ""), -1, "war")
	gs.armies_changed.emit()
	gs.state_changed.emit()


static func _wars(gs, sc: Dictionary, idx: Dictionary) -> void:
	for w in sc.get("wars", []):
		var a: int = int(idx.get(w[0], -1))
		var b: int = int(idx.get(w[1], -1))
		if a >= 0 and b >= 0:
			gs.declare_war(a, b, false)
			gs.deploy_front(a)
			gs.deploy_front(b)


static func _blocs(gs, sc: Dictionary, idx: Dictionary) -> void:
	for b in sc.get("blocs", []):
		var names: Array = NATO if typeof(b["members"]) == TYPE_STRING else b["members"]
		var ids: Array = []
		for n in names:
			var cid: int = int(idx.get(n, -1))
			if cid >= 0 and gs.countries[cid].alliance < 0:
				ids.append(cid)
		if ids.size() < 2:
			continue
		var em: Dictionary
		if b.has("emblem"):
			em = (b["emblem"] as Dictionary).duplicate()
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(String(b["name"]))
			em = Emblem.random_emblem(rng)
		var bid: int = gs.create_bloc(ids[0], b["name"], em)
		for i in range(1, ids.size()):
			gs.bloc_add(bid, ids[i])


## Eyalet aktarımı: [eyalet id|ad, bugünkü sahip, yeni sahip, "own"|"occ"]
static func _transfers(gs, sc: Dictionary, idx: Dictionary) -> void:
	var moved := false
	for t in sc.get("transfer", []):
		var src: int = int(idx.get(String(t[1]), -1))
		var dst: int = int(idx.get(String(t[2]), -1))
		if src < 0 or dst < 0:
			continue
		var hit := false
		for p in gs.provinces:
			var m: bool = (p.id == int(t[0])) if (typeof(t[0]) == TYPE_INT) else (p.name == String(t[0]))
			if m and p.owner == src:
				hit = true
				if String(t[3] if t.size() > 3 else "own") == "own":
					var was: bool = p.is_capital
					p.owner = dst
					p.controller = dst
					p.core = dst
					p.home = dst
					if was:
						p.is_capital = false
				else:
					p.controller = dst
		if hit:
			moved = true
		else:
			push_warning("Scenarios.transfer eşleşmedi: %s" % [t])
	if moved:
		gs.refresh_stats()
		for c in gs.countries:
			if c.alive and not c.is_rebel and c.capital >= 0 and gs.provinces[c.capital].owner != c.id:
				c.capital = c.owned_ids[0] if not c.owned_ids.is_empty() else -1
				if c.capital >= 0:
					gs.provinces[c.capital].is_capital = true
			if c.alive and not c.is_rebel and c.owned_ids.is_empty():
				c.alive = false


## Ordu/kasa/istikrar çarpanları, isim-renk-lider değişimi
static func _modifiers(gs, sc: Dictionary, idx: Dictionary) -> void:
	for n in sc.get("rename", {}):
		var ci: int = int(idx.get(n, -1))
		if ci < 0:
			continue
		var r: Dictionary = sc["rename"][n]
		if r.has("name"):
			gs.countries[ci].name = String(r["name"])
		if r.has("color"):
			gs.countries[ci].color = Color(String(r["color"]))
		if r.has("leader"):
			gs.countries[ci].leader = String(r["leader"])
	for n2 in sc.get("troops_mult", {}):
		var c2: int = int(idx.get(n2, -1))
		if c2 < 0:
			continue
		var m2: float = clampf(float(sc["troops_mult"][n2]), 0.3, 3.0)
		gs.countries[c2].base_troops = int(gs.countries[c2].base_troops * m2)
		for a in gs.armies.values():
			if a.owner == c2:
				a.size = maxi(500, int(a.size * m2))
	for n3 in sc.get("treasury_mult", {}):
		var c3: int = int(idx.get(n3, -1))
		if c3 >= 0:
			gs.countries[c3].gold *= clampf(float(sc["treasury_mult"][n3]), 0.2, 4.0)
	for n4 in sc.get("stability", {}):
		var c4: int = int(idx.get(n4, -1))
		if c4 >= 0:
			gs.countries[c4].stability = clampf(gs.countries[c4].stability + float(sc["stability"][n4]), 5.0, 100.0)
