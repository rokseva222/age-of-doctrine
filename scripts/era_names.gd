extends RefCounted
## Tarihî kiplerde dönem adları: eyalet/şehir adları, kabine unvanları ve dönemin gerçek devlet adamları.
## Veri: data/era_names.json  { "<era>": {"role_titles": {rol: unvan}, "prov_names": {bugünkü ad: dönem adı}, "cabinet": {name_en: {rol: "Ad|f"}}} }
## Alternatif çağlar (alt_*) base çağının tablolarını kullanır; "pre" ailesi için "pre" anahtarı ortak tabandır.

const EraExt = preload("res://scripts/era_ext.gd")

static var _data: Dictionary = {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open("res://data/era_names.json", FileAccess.READ)
	if f == null:
		return
	var j = JSON.parse_string(f.get_as_text())
	f.close()
	if j is Dictionary:
		_data = j


## Bir çağın tablosu: önce çağın kendisi, sonra base'i, sonra ailesi ("pre"/"ww1"/...) birleştirilir (özel olan üstte).
static func table(era: String) -> Dictionary:
	_load()
	if era == "":
		return {}
	var chain: Array = []
	var id := era
	var guard := 0
	while id != "" and guard < 5:
		chain.append(id)
		id = String(EraExt.raw(id).get("base", "")) if EraExt.has_era(id) else ""
		guard += 1
	var fam: String = String(EraExt.raw(era).get("family", "")) if EraExt.has_era(era) else era
	if fam != "" and not chain.has(fam):
		chain.append(fam)
	var out := {"role_titles": {}, "prov_names": {}, "cabinet": {}, "titles_by": {}}
	chain.reverse()
	for k in chain:
		var t: Dictionary = _data.get(k, {})
		for sec in out.keys():
			var src: Dictionary = t.get(sec, {})
			for key in src:
				if sec == "cabinet" or sec == "titles_by":
					var cur: Dictionary = out[sec].get(key, {})
					cur.merge(src[key], true)
					out[sec][key] = cur
				else:
					out[sec][key] = src[key]
	return out


## Eyalet adlarını döneme çevirir (yeni oyun ve kayıt yüklemede, dünya kurulduktan sonra).
static func apply(gs, era: String) -> int:
	var pn: Dictionary = table(era).get("prov_names", {})
	if pn.is_empty():
		return 0
	var n := 0
	for p in gs.provinces:
		if pn.has(p.name):
			var nm: String = String(pn[p.name])
			p.name = nm
			p.city = nm
			n += 1
	return n


## Unvan: önce ülkeye özel ("titles_by": {name_en: {rol: unvan}}), sonra çağın genel unvanı
static func role_title(era: String, role: String, default: String, name_en: String = "") -> String:
	var t: Dictionary = table(era)
	var by: Dictionary = t.get("titles_by", {}).get(name_en, {})
	if by.has(role):
		return String(by[role])
	return String(t.get("role_titles", {}).get(role, default))


## Dönemin gerçek devlet adamı: "Ad|f" ya da "" (yoksa rastgele üretilir)
static func real_minister(era: String, name_en: String, role: String) -> String:
	return String(table(era).get("cabinet", {}).get(name_en, {}).get(role, ""))
