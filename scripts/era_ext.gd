extends RefCounted
## data/eras/*.json: JSON ile tanımlanan ek tarihî çağlar. eras.gd, era_events.gd, era_leaders.gd, arsenal.gd bu kayıttan okur.
## Şema: docs/DATA_SCHEMA.md. Çağlar `base` ile başka bir çağın tablolarını miras alabilir.

const DataUtil = preload("res://scripts/data_util.gd")
const Loc = preload("res://scripts/loc.gd")

const DIR := "res://data/eras"

static var _raw: Dictionary = {}
static var _order: Array = []
static var _loaded := false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_raw = {}
	_order = []
	for id in DataUtil.read_index(DIR):
		var d = DataUtil.read_json("%s/%s.json" % [DIR, id])
		if d is Dictionary and d.has("id"):
			_raw[String(d["id"])] = d
			_order.append(String(d["id"]))


static func reload() -> void:
	_loaded = false
	load_all()


static func ids() -> Array:
	load_all()
	return _order


static func has_era(id: String) -> bool:
	load_all()
	return _raw.has(id)


static func raw(id: String) -> Dictionary:
	load_all()
	return _raw.get(id, {})


static func field(id: String, key: String, default = null):
	var r: Dictionary = raw(id)
	if r.has(key):
		return r[key]
	# alternatif çağlar bu alanları ext olan base'inden alır
	if key in ["nukes", "carriers", "mood", "icon"] and has_era(String(r.get("base", ""))):
		return field(String(r["base"]), key, default)
	return default


static func base_of(id: String) -> String:
	return String(raw(id).get("base", ""))


## Menü kartı için (eras.gd LIST ile aynı biçim), dile göre
static func listing() -> Array:
	load_all()
	var out: Array = []
	for id in _order:
		var d: Dictionary = _raw[id]
		out.append({"id": id, "name": DataUtil.pick_en(d, "name", Loc.lang), "sub": DataUtil.pick_en(d, "sub", Loc.lang),
			"start_year": int(d.get("start_year", 1900)), "start_doy": int(d.get("start_doy", 0)),
			"blurb": DataUtil.pick_en(d, "blurb", Loc.lang), "suggest": d.get("suggest", []),
			"look": d.get("look", {"shadow": [0.06, 0.07, 0.08], "mid": [0.42, 0.44, 0.40], "light": [0.92, 0.90, 0.84], "amount": 0.30, "vignette": 0.14, "grain": 0.010}),
			"icon": String(d.get("icon", "helmet")), "ext": true})
	return out


## Dönem olayları (dile göre metin)
static func events(id: String) -> Array:
	var d: Dictionary = raw(id)
	var out: Array = []
	var evs: Array = d.get("events", [])
	for i in evs.size():
		var e: Dictionary = (evs[i] as Dictionary).duplicate()
		e["era"] = id
		var en_t := ""
		if d.has("en") and (d["en"] as Dictionary).has("events") and (d["en"]["events"] as Dictionary).has(str(i)):
			en_t = String(d["en"]["events"][str(i)])
		e["t"] = DataUtil.loc_text(String(e.get("t", "")), en_t)
		out.append(e)
	return out


static func chain(id: String) -> Dictionary:
	var l = raw(id).get("leaders", {})
	return l.get("chain", {}) if l is Dictionary else {}


static func horizon(id: String) -> int:
	var l = raw(id).get("leaders", {})
	return int(l.get("horizon", -1)) if l is Dictionary else -1


## Silah tablosu: ya başka bir çağın anahtarı (String) ya da tam tablo (Dictionary); yoksa base'inki
static func arsenal(id: String):
	var cur := id
	for i in 6:
		var d: Dictionary = raw(cur)
		if d.has("arsenal"):
			return d["arsenal"]
		cur = String(d.get("base", ""))
		if cur == "":
			return null
		if not has_era(cur):
			return cur
	return null


## Paket adı ("alt" = Alternatif Tarih Paketi) ve ücretsiz örnek bayrağı
static func pack(id: String) -> String:
	return String(raw(id).get("pack", ""))


static func is_free(id: String) -> bool:
	return bool(raw(id).get("free", false))


## "leaders" alanı olmayan alternatif çağ, lider zincirini base'inden alır: zincirin geçerli olduğu ilk çağı döndürür
static func leaders_src(id: String) -> String:
	var cur := id
	for i in 6:
		if not has_era(cur):
			return cur
		if raw(cur).has("leaders"):
			return cur
		var b := String(raw(cur).get("base", ""))
		if b == "":
			return cur
		cur = b
	return cur


## Bu çağın ait olduğu "aile" ("ww1", "ww2", "cold" ...): kural farkları için. Belirtilmemişse çağın kimliği
static func family(id: String) -> String:
	return String(raw(id).get("family", id))
