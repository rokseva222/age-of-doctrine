extends SceneTree
## Senaryo/çağ JSON doğrulayıcı.
## Kullanım: godot --headless --path . -s tools/validate_data.gd -- [dosya.json ...]   (boşsa data/scenarios ve data/eras altındaki hepsi)
const DataUtil = preload("res://scripts/data_util.gd")
const SC = preload("res://scripts/scenarios.gd")

const OBJ_FIELDS := {
	"own_provinces": ["n"], "own_province": ["province"], "own_capital": ["country"], "eliminate": ["country"],
	"survive": ["turns"], "cease_war": ["with"], "no_war": ["turns"], "alliances": ["n"], "stability": ["n"],
	"gdp_share": ["pct"], "bloc_members": ["n"], "hold_choke": ["choke"],
}
const FX_TYPES := ["war", "peace", "ally", "stab"]
const SYMBOLS := ["star", "sword", "swords", "shield", "crown", "globe", "anchor", "plane", "bolt", "flame", "castle", "wheat", "tank", "handshake", "target", "skull", "trophy", "factory"]

var names := {}      # name_en -> true
var prov_ids := {}
var prov_names := {}
var errs := 0
var warns := 0
var cur := ""


func _init() -> void:
	var w = DataUtil.read_json("res://data/world.json")
	for c in w["countries"]:
		names[String(c["name_en"])] = true
	for p in w["provinces"]:
		prov_ids[int(p["id"])] = true
		prov_names[String(p["name"])] = int(prov_names.get(String(p["name"]), 0)) + 1
	var files: Array = []
	for a in OS.get_cmdline_user_args():
		if a.ends_with(".json"):
			files.append(a)
	if files.is_empty():
		for d in ["res://data/scenarios", "res://data/eras"]:
			for f in DirAccess.get_files_at(d):
				if f.ends_with(".json") and f != "index.json":
					files.append("%s/%s" % [d, f])
	for f in files:
		_file(f)
	print("---- hata=%d uyarı=%d dosya=%d" % [errs, warns, files.size()])
	quit(1 if errs > 0 else 0)


func E(msg: String) -> void:
	errs += 1
	print("HATA  [%s] %s" % [cur, msg])


func W(msg: String) -> void:
	warns += 1
	print("uyarı [%s] %s" % [cur, msg])


func _country(n, where: String) -> void:
	if typeof(n) != TYPE_STRING or not names.has(String(n)):
		E("%s: bilinmeyen ülke '%s'" % [where, str(n)])


func _prov(p, where: String) -> void:
	if typeof(p) == TYPE_STRING:
		if not prov_names.has(p):
			E("%s: bilinmeyen eyalet adı '%s'" % [where, p])
		elif int(prov_names[p]) > 1:
			W("%s: '%s' adında birden çok eyalet var, kimlik kullan" % [where, p])
	elif typeof(p) in [TYPE_INT, TYPE_FLOAT]:
		if not prov_ids.has(int(p)):
			E("%s: bilinmeyen eyalet kimliği %s" % [where, str(p)])
	else:
		E("%s: eyalet türü geçersiz" % where)


func _pairs(arr, where: String, ext = true) -> void:
	if typeof(arr) != TYPE_ARRAY:
		E("%s: dizi olmalı" % where)
		return
	for pr in arr:
		if typeof(pr) != TYPE_ARRAY or pr.size() < 2:
			E("%s: çift olmalı" % where)
			continue
		_country(pr[0], where)
		_country(pr[1], where)
		if pr[0] == pr[1]:
			E("%s: aynı ülke iki kez" % where)


func _color(s, where: String) -> void:
	if typeof(s) != TYPE_STRING or s.length() != 6 or not s.is_valid_hex_number(false):
		E("%s: renk 'rrggbb' olmalı (%s)" % [where, str(s)])


func _emblem(e, where: String) -> void:
	if typeof(e) != TYPE_DICTIONARY:
		E("%s: emblem sözlük olmalı" % where)
		return
	if e.has("symbol") and not SYMBOLS.has(String(e["symbol"])):
		E("%s: bilinmeyen sembol %s" % [where, str(e["symbol"])])
	for k in ["c1", "c2", "c3"]:
		if e.has(k):
			_color(e[k], where + "." + k)


func _blocs(arr, where: String) -> void:
	if typeof(arr) != TYPE_ARRAY:
		E("%s: dizi olmalı" % where)
		return
	var seen := {}
	for b in arr:
		if typeof(b) != TYPE_DICTIONARY or not b.has("name") or not b.has("members"):
			E("%s: blok {name,members} olmalı" % where)
			continue
		var mem: Array = []
		if typeof(b["members"]) == TYPE_STRING:
			if b["members"] != "NATO":
				E("%s: bilinmeyen blok kısayolu %s" % [where, b["members"]])
			mem = SC.NATO
		else:
			mem = b["members"]
			for m in mem:
				_country(m, where + ".members")
		if mem.size() < 2:
			E("%s: blokta en az 2 üye olmalı (%s)" % [where, b["name"]])
		for m in mem:
			if seen.has(m):
				W("%s: %s birden çok blokta" % [where, str(m)])
			seen[m] = true
		if b.has("emblem"):
			_emblem(b["emblem"], where + ".emblem")


func _events_en(d: Dictionary, n: int, where: String) -> void:
	var en: Dictionary = d.get("en", {})
	var ev: Dictionary = en.get("events", {})
	for i in n:
		if not ev.has(str(i)):
			W("%s: en.events['%d'] eksik" % [where, i])


func _objectives(d: Dictionary, where: String) -> void:
	var ob = d.get("objectives", {})
	if typeof(ob) != TYPE_DICTIONARY:
		E("%s: objectives sözlük olmalı" % where)
		return
	var en_obj: Dictionary = d.get("en", {}).get("objectives", {})
	for key in ob.keys():
		if key != "*":
			_country(key, where + "." + str(key))
		if typeof(ob[key]) != TYPE_ARRAY:
			E("%s.%s: liste olmalı" % [where, str(key)])
			continue
		var ids := {}
		var req := 0
		for o in ob[key]:
			if typeof(o) != TYPE_DICTIONARY:
				E("%s.%s: hedef sözlük olmalı" % [where, str(key)])
				continue
			var id := String(o.get("id", ""))
			var t := String(o.get("type", ""))
			if id == "":
				E("%s.%s: hedefte id yok" % [where, str(key)])
			if ids.has(id):
				E("%s.%s: tekrarlı hedef id '%s'" % [where, str(key), id])
			ids[id] = true
			if not OBJ_FIELDS.has(t):
				E("%s.%s.%s: bilinmeyen tür '%s'" % [where, str(key), id, t])
				continue
			for f in OBJ_FIELDS[t]:
				if not o.has(f):
					E("%s.%s.%s: '%s' alanı eksik" % [where, str(key), id, f])
			if t in ["own_capital", "eliminate"] and o.has("country"):
				_country(o["country"], "%s.%s.%s" % [where, str(key), id])
			if t == "cease_war" and o.has("with"):
				_country(o["with"], "%s.%s.%s" % [where, str(key), id])
			if t == "own_province" and o.has("province"):
				_prov(o["province"], "%s.%s.%s" % [where, str(key), id])
			if not o.has("text") or String(o["text"]) == "":
				E("%s.%s.%s: Türkçe 'text' yok" % [where, str(key), id])
			if not en_obj.has(id):
				W("%s.%s: en.objectives['%s'] eksik" % [where, str(key), id])
			if bool(o.get("required", true)):
				req += 1
		if req == 0 and not ob[key].is_empty():
			W("%s.%s: zorunlu hedef yok, zafer asla gelmez" % [where, str(key)])


func _events(arr, where: String, scn: bool) -> void:
	if typeof(arr) != TYPE_ARRAY:
		E("%s: dizi olmalı" % where)
		return
	for i in arr.size():
		var ev = arr[i]
		if typeof(ev) != TYPE_DICTIONARY or not ev.has("t"):
			E("%s[%d]: {t,fx} olmalı" % [where, i])
			continue
		if scn and not ev.has("turn"):
			E("%s[%d]: 'turn' yok" % [where, i])
		if not scn and (not ev.has("y") or not ev.has("m")):
			E("%s[%d]: 'y' ve 'm' yok" % [where, i])
		for fx in ev.get("fx", []):
			if typeof(fx) != TYPE_ARRAY or fx.size() < 2 or not FX_TYPES.has(String(fx[0])):
				E("%s[%d]: geçersiz fx %s" % [where, i, str(fx)])
				continue
			_country(fx[1], "%s[%d].fx" % [where, i])
			if fx[0] == "stab":
				if fx.size() < 3:
					E("%s[%d]: stab için değer yok" % [where, i])
			elif fx.size() < 3:
				E("%s[%d]: %s için iki ülke gerek" % [where, i, str(fx[0])])
			else:
				_country(fx[2], "%s[%d].fx" % [where, i])


func _file(path: String) -> void:
	cur = path.get_file()
	var d = DataUtil.read_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		E("geçerli JSON sözlüğü değil")
		return
	var id := String(d.get("id", ""))
	if id == "" or id != path.get_file().get_basename():
		E("id '%s' dosya adıyla uyuşmuyor" % id)
	for k in ["name", "sub", "blurb"]:
		if String(d.get(k, "")) == "":
			E("'%s' eksik" % k)
	if typeof(d.get("en", null)) != TYPE_DICTIONARY:
		E("'en' bloğu yok")
	else:
		for k in ["name", "sub", "blurb"]:
			if String(d["en"].get(k, "")) == "":
				W("en.%s eksik" % k)
	for c in d.get("suggest", []):
		_country(c, "suggest")
	if path.contains("/eras/"):
		_era(d)
	else:
		_scenario(d)
	_objectives(d, "objectives")
	var evs = d.get("events", [])
	if typeof(evs) == TYPE_ARRAY:
		_events_en(d, evs.size(), "events")


func _scenario(d: Dictionary) -> void:
	if not (String(d.get("kind", "")) in ["real", "fiction"]):
		E("kind 'real' ya da 'fiction' olmalı")
	if String(d.get("intro", "")) == "":
		W("intro boş")
	if d.get("suggest", []).is_empty():
		E("suggest boş")
	_blocs(d.get("blocs", []), "blocs")
	for k in ["wars", "embargo", "cold"]:
		if d.has(k):
			_pairs(d[k], k)
	for k in ["cyber", "doctrine", "troops_mult", "treasury_mult", "stability", "rename"]:
		if d.has(k):
			if typeof(d[k]) != TYPE_DICTIONARY:
				E("%s sözlük olmalı" % k)
				continue
			for c in d[k].keys():
				_country(c, k)
	for k in ["troops_mult"]:
		for c in d.get(k, {}).keys():
			var v := float(d[k][c])
			if v < 0.5 or v > 2.0:
				E("troops_mult %s aralık dışı" % c)
	for c in d.get("treasury_mult", {}).keys():
		var v2 := float(d["treasury_mult"][c])
		if v2 < 0.3 or v2 > 3.0:
			E("treasury_mult %s aralık dışı" % c)
	for c in d.get("stability", {}).keys():
		var v3 := float(d["stability"][c])
		if v3 < -40 or v3 > 20:
			E("stability %s aralık dışı" % c)
	for c in d.get("doctrine", {}).keys():
		var v4 := int(d["doctrine"][c])
		if v4 < 0 or v4 > 5:
			E("doctrine %s 0..5 olmalı" % c)
	for k in ["budget_war", "cyber_budget"]:
		for c in d.get(k, []):
			_country(c, k)
	for r in d.get("rename", {}).values():
		if typeof(r) == TYPE_DICTIONARY and r.has("color"):
			_color(r["color"], "rename.color")
	for f in d.get("factions", []):
		if typeof(f) != TYPE_DICTIONARY or not f.has("name") or not f.has("from"):
			E("faction {name,from} olmalı")
			continue
		for fr in f["from"]:
			if typeof(fr) != TYPE_ARRAY or fr.size() < 2:
				E("faction.from [ülke,sayı] olmalı")
				continue
			_country(fr[0], "faction.from")
		for c in f.get("colors", []):
			_color(c, "faction.colors")
	for tr in d.get("transfer", []):
		if typeof(tr) != TYPE_ARRAY or tr.size() < 3:
			E("transfer [eyalet,eski,yeni,tür] olmalı")
			continue
		_prov(tr[0], "transfer")
		_country(tr[1], "transfer")
		_country(tr[2], "transfer")
		if tr.size() > 3 and not (String(tr[3]) in ["own", "occ"]):
			E("transfer türü own/occ olmalı")
	_events(d.get("events", []), "events", true)
	if d.has("deadline") and int(d["deadline"]) < 8:
		E("deadline çok küçük")


func _era(d: Dictionary) -> void:
	for k in ["start_year", "start_doy"]:
		if not d.has(k):
			E("'%s' eksik" % k)
	if d.has("start_doy") and (int(d["start_doy"]) < 0 or int(d["start_doy"]) > 365):
		E("start_doy 0..365")
	var base := String(d.get("base", ""))
	if base != "" and not (base in ["ww1", "ww2"]) and not FileAccess.file_exists("res://data/eras/%s.json" % base):
		E("base '%s' bulunamadı" % base)
	var fam := String(d.get("family", ""))
	if fam == "" and base == "":
		W("family yok (ww1/ww2/cold)")
	for host in d.get("absorb", {}).keys():
		_country(host, "absorb")
		for m in d["absorb"][host]:
			_country(m, "absorb." + str(host))
	for tr in d.get("split", []):
		if typeof(tr) != TYPE_ARRAY or tr.size() < 3:
			E("split [eyalet,eski,yeni,tür] olmalı")
			continue
		_prov(tr[0], "split")
		_country(tr[1], "split")
		_country(tr[2], "split")
	for c in d.get("capital", {}).keys():
		_country(c, "capital")
		_prov(d["capital"][c], "capital." + str(c))
	for c in d.get("defs", {}).keys():
		_country(c, "defs")
		var df = d["defs"][c]
		if typeof(df) != TYPE_DICTIONARY:
			E("defs.%s sözlük olmalı" % c)
			continue
		if df.has("color"):
			_color(df["color"], "defs.%s.color" % c)
		if df.has("leader") and not String(df["leader"]).contains("|"):
			W("defs.%s.leader 'Unvan|İsim' biçiminde olmalı" % c)
	var su = d.get("setup", {})
	if typeof(su) == TYPE_DICTIONARY:
		_blocs(su.get("blocs", []), "setup.blocs")
		if su.has("wars"):
			_pairs(su["wars"], "setup.wars")
		for t in su.get("truce", []):
			if typeof(t) == TYPE_ARRAY and t.size() >= 2:
				_country(t[0], "setup.truce")
				_country(t[1], "setup.truce")
	_events(d.get("events", []), "events", false)
	var ld = d.get("leaders", {})
	if typeof(ld) == TYPE_DICTIONARY:
		for c in ld.get("chain", {}).keys():
			_country(c, "leaders.chain")
			for it in ld["chain"][c]:
				if typeof(it) != TYPE_ARRAY or it.size() < 3:
					E("leaders.chain.%s: [yıl,ay,'Unvan|İsim']" % c)
	for c in d.get("carriers", {}).keys():
		_country(c, "carriers")
	for c in d.get("nukes", []):
		_country(c, "nukes")
