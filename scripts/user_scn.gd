extends RefCounted
## Kullanıcı senaryoları: kaydet / sil / paylaşım kodu (dışa-içe aktar) ve temizleme.
## Dosyalar user://scenarios/u_*.json; Scenarios bunları "user" türüyle listeler.

const Scenarios = preload("res://scripts/scenarios.gd")
const WorldData = preload("res://scripts/world_data.gd")
const Loc = preload("res://scripts/loc.gd")

const DIR := "user://scenarios"
const CODE_PREFIX := "AOD1."
const MAX_ITEMS := 40
const OBJ_TYPES := ["survive", "own_provinces", "alliances", "no_war", "cease_war", "stability", "eliminate", "gdp_share", "bloc_members"]

static var _countries: Array = []


## [{en, name}] — ada göre sıralı (Türkçe ad; İngilizce arayüzde İngilizce ad)
static func countries() -> Array:
	if _countries.is_empty():
		var w = WorldData.instance()
		for c in w.raw.get("countries", []):
			_countries.append({"en": String(c["name_en"]), "tr": String(c["name"])})
	var lang_tr: bool = Loc.lang == "tr"
	var out: Array = _countries.duplicate()
	out.sort_custom(func(a, b): return (a["tr"] if lang_tr else a["en"]) < (b["tr"] if lang_tr else b["en"]))
	return out


static func country_label(en: String) -> String:
	if Loc.lang != "tr":
		return en
	for c in countries():
		if c["en"] == en:
			return c["tr"]
	return en


static func valid_country(en) -> bool:
	if typeof(en) != TYPE_STRING:
		return false
	for c in countries():
		if c["en"] == en:
			return true
	return false


static func new_id() -> String:
	return "u_%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]


static func list_ids() -> Array:
	var out: Array = []
	var da := DirAccess.open(DIR)
	if da != null:
		for f in da.get_files():
			if f.begins_with("u_") and f.ends_with(".json"):
				out.append(f.get_basename())
	out.sort()
	return out


static func load_one(id: String) -> Dictionary:
	var f := "%s/%s.json" % [DIR, id]
	if not FileAccess.file_exists(f):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(f))
	return d if d is Dictionary else {}


static func save(d: Dictionary) -> bool:
	var id := String(d.get("id", ""))
	if not id.begins_with("u_"):
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var f := FileAccess.open("%s/%s.json" % [DIR, id], FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.close()
	Scenarios.reload()
	return true


static func remove(id: String) -> void:
	if not id.begins_with("u_"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s.json" % [DIR, id]))
	Scenarios.reload()


# ------------------------------------------------------------------ paylaşım kodu

static func export_code(d: Dictionary) -> String:
	var clean: Dictionary = d.duplicate(true)
	clean.erase("id")
	var raw: PackedByteArray = JSON.stringify(clean).to_utf8_buffer()
	var packed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
	return "%s%d.%s" % [CODE_PREFIX, raw.size(), Marshalls.raw_to_base64(packed).replace("+", "-").replace("/", "_")]


## Kodu çöz → temizlenmiş senaryo (yeni id ile) ya da {} (geçersizse)
static func import_code(code: String) -> Dictionary:
	code = code.strip_edges()
	if not code.begins_with(CODE_PREFIX) or code.length() > 60000:
		return {}
	var rest: String = code.substr(CODE_PREFIX.length())
	var dot: int = rest.find(".")
	if dot < 1:
		return {}
	var size: int = int(rest.substr(0, dot))
	if size < 10 or size > 200000:
		return {}
	var b64: String = rest.substr(dot + 1).replace("-", "+").replace("_", "/")
	var packed: PackedByteArray = Marshalls.base64_to_raw(b64)
	if packed.is_empty():
		return {}
	var raw: PackedByteArray = packed.decompress(size, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != size:
		return {}
	var d = JSON.parse_string(raw.get_string_from_utf8())
	if not (d is Dictionary):
		return {}
	return sanitize(d)


# ------------------------------------------------------------------ temizleme (dışarıdan gelen veriye güvenme)

static func _s(v, maxlen: int) -> String:
	return String(v).strip_edges().substr(0, maxlen) if typeof(v) in [TYPE_STRING, TYPE_STRING_NAME] else ""


static func _pairs(arr) -> Array:
	var out: Array = []
	if typeof(arr) != TYPE_ARRAY:
		return out
	for p in arr:
		if out.size() >= MAX_ITEMS:
			break
		if typeof(p) == TYPE_ARRAY and p.size() >= 2 and valid_country(p[0]) and valid_country(p[1]) and p[0] != p[1]:
			out.append([p[0], p[1]])
	return out


static func _num_map(m, lo: float, hi: float) -> Dictionary:
	var out := {}
	if typeof(m) != TYPE_DICTIONARY:
		return out
	for k in m.keys():
		if out.size() >= MAX_ITEMS:
			break
		if valid_country(k) and typeof(m[k]) in [TYPE_INT, TYPE_FLOAT]:
			out[k] = clampf(float(m[k]), lo, hi)
	return out


static func sanitize(d: Dictionary) -> Dictionary:
	var out := {"id": new_id(), "kind": "user"}
	out["name"] = _s(d.get("name", ""), 40)
	if out["name"] == "":
		return {}
	out["sub"] = _s(d.get("sub", ""), 60)
	out["blurb"] = _s(d.get("blurb", ""), 300)
	out["intro"] = _s(d.get("intro", ""), 300)
	var sug: Array = []
	for c in d.get("suggest", []):
		if valid_country(c) and sug.size() < 4:
			sug.append(c)
	if sug.is_empty():
		return {}
	out["suggest"] = sug
	out["wars"] = _pairs(d.get("wars", []))
	out["embargo"] = _pairs(d.get("embargo", []))
	out["cold"] = _pairs(d.get("cold", []))
	var blocs: Array = []
	var raw_blocs = d.get("blocs", [])
	if typeof(raw_blocs) == TYPE_ARRAY:
		for b in raw_blocs:
			if blocs.size() >= 4 or typeof(b) != TYPE_DICTIONARY:
				continue
			var mem: Array = []
			for m in b.get("members", []) if typeof(b.get("members", [])) == TYPE_ARRAY else []:
				if valid_country(m) and mem.size() < 40 and not mem.has(m):
					mem.append(m)
			if mem.size() >= 2 and _s(b.get("name", ""), 40) != "":
				blocs.append({"name": _s(b["name"], 40), "members": mem})
	out["blocs"] = blocs
	var tm := _num_map(d.get("troops_mult", {}), 0.5, 2.0)
	if not tm.is_empty():
		out["troops_mult"] = tm
	var gm := _num_map(d.get("treasury_mult", {}), 0.3, 3.0)
	if not gm.is_empty():
		out["treasury_mult"] = gm
	var sm := _num_map(d.get("stability", {}), -40.0, 20.0)
	if not sm.is_empty():
		out["stability"] = sm
	var objs: Array = []
	var raw_o = d.get("objectives", {})
	var star = raw_o.get("*", []) if typeof(raw_o) == TYPE_DICTIONARY else []
	if typeof(star) == TYPE_ARRAY:
		var i := 0
		for o in star:
			if objs.size() >= 8 or typeof(o) != TYPE_DICTIONARY or not OBJ_TYPES.has(String(o.get("type", ""))):
				continue
			var t: String = String(o["type"])
			var e := {"id": "o%d" % i, "type": t, "text": _s(o.get("text", ""), 120)}
			i += 1
			if t in ["cease_war"]:
				if not valid_country(o.get("with", null)):
					continue
				e["with"] = o["with"]
			elif t == "eliminate":
				if not valid_country(o.get("country", null)):
					continue
				e["country"] = o["country"]
			elif t in ["survive", "no_war"]:
				e["turns"] = clampi(int(o.get("turns", 52)), 1, 1000)
			elif t == "gdp_share":
				e["pct"] = clampf(float(o.get("pct", 5)), 0.1, 60.0)
			else:
				e["n"] = clampi(int(o.get("n", 1)), 1, 200)
			if not bool(o.get("required", true)):
				e["required"] = false
			if e["text"] == "":
				e["text"] = describe(e, "tr")
			objs.append(e)
	if not objs.is_empty():
		out["objectives"] = {"*": objs}
	var dl: int = clampi(int(d.get("deadline", 0)), 0, 1000)
	if dl > 0:
		out["deadline"] = dl
	return out


# ------------------------------------------------------------------ hedef metni

static func describe(o: Dictionary, lang: String) -> String:
	var tr: bool = lang == "tr"
	match String(o.get("type", "")):
		"survive":
			return ("%d hafta ayakta kal" if tr else "Survive %d weeks") % int(o.turns)
		"no_war":
			return ("%d hafta savaşsız kal" if tr else "Stay out of war for %d weeks") % int(o.turns)
		"own_provinces":
			return ("%d eyalete ulaş" if tr else "Reach %d provinces") % int(o.n)
		"alliances":
			return ("%d müttefik edin" if tr else "Make %d allies") % int(o.n)
		"stability":
			return ("İstikrarı %d üzerinde tut" if tr else "Keep stability above %d") % int(o.n)
		"bloc_members":
			return ("Bloğunda %d üyeye ulaş" if tr else "Reach %d bloc members") % int(o.n)
		"gdp_share":
			return ("Dünya GSYH payını %%%d yap" if tr else "Reach %d%% of world GDP") % int(o.pct)
		"cease_war":
			return ("%s ile barış yap" if tr else "Make peace with %s") % _name(String(o.get("with", "")), lang)
		"eliminate":
			return ("%s devletini yok et" if tr else "Eliminate %s") % _name(String(o.get("country", "")), lang)
	return ""


static func _name(en: String, lang: String) -> String:
	if lang != "tr":
		return en
	for c in countries():
		if c["en"] == en:
			return c["tr"]
	return en


## Düzenleyici verisini yayın biçimine çevirir: İngilizce blok da eklenir
static func finalize(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var en_obj := {}
	var objs = out.get("objectives", {}).get("*", [])
	for o in objs:
		en_obj[String(o["id"])] = describe(o, "en")
	out["en"] = {"name": out["name"], "sub": out.get("sub", ""), "blurb": out.get("blurb", ""), "intro": out.get("intro", ""), "objectives": en_obj}
	return out
