extends RefCounted
## Kullanıcı senaryoları: kaydet / sil / paylaşım kodu (dışa-içe aktar) ve temizleme.
## Dosyalar user://scenarios/u_*.json; Scenarios bunları "user" türüyle listeler.

const Scenarios = preload("res://scripts/scenarios.gd")
const WorldData = preload("res://scripts/world_data.gd")
const Loc = preload("res://scripts/loc.gd")

const DIR := "user://scenarios"
const CODE_PREFIX := "AOD1."
const MAX_ITEMS := 40
const MAX_EVENTS := 40
const MAX_TRANSFER := 400
const MAX_CUSTOM := 8
const HEX := "#0123456789abcdefABCDEF"
const MAX_GARRISON := 60
const FX_TYPES := ["war", "peace", "ally", "xstab", "xgold", "xtroops", "cede", "break", "vassal", "embargo", "free", "leader", "rename", "xtech", "cabinet"]
const OBJ_TYPES := ["survive", "own_provinces", "alliances", "no_war", "cease_war", "stability", "eliminate", "gdp_share", "bloc_members"]

static var _countries: Array = []


## Senaryo çağları: oyundaki bütün dönemler (tarihî savaşlar, alternatif tarihler, Hikâye Modu çağları); "" = Dünya 2027
static func valid_era(id) -> bool:
	if typeof(id) != TYPE_STRING or id == "":
		return false
	var Eras = load("res://scripts/eras.gd")
	return not Eras.get_era(id).is_empty()


static var era := ""                      # düzenleyici açıkken: düzenlenen senaryonun çağı
static var _era_cache: Dictionary = {}


## Çağın yeniden kurulmuş geçici dünyası: {"countries": [{en, tr}], "provs": [{id, name, en, tr}], "owner_en": {pid: en}}
static func era_info(eid: String) -> Dictionary:
	if _era_cache.has(eid):
		return _era_cache[eid]
	var Eras = load("res://scripts/eras.gd")
	var GS = load("res://scripts/game_state.gd")
	var prev: String = Eras.current
	Eras.prepare(eid)
	var g = GS.new()
	g.new_world(7)
	Eras.restructure(g, eid)
	var info := {"countries": [], "provs": []}
	for c in g.countries:
		if c.alive and not c.is_rebel:
			info["countries"].append({"en": String(c.name_en), "tr": String(c.name)})
	for p in g.provinces:
		var o = g.countries[p.owner] if p.owner >= 0 else null
		info["provs"].append({"id": int(p.id), "name": String(p.name), "en": String(o.name_en) if o != null else "", "tr": String(o.name) if o != null else ""})
	if prev != "":
		Eras.prepare(prev)
	else:
		Eras.clear()
	_era_cache[eid] = info
	return info


## Tüm (2027) ülke adları: doğrulama için; çağdan bağımsız
static func _base_countries() -> Array:
	if _countries.is_empty():
		var w = WorldData.instance()
		for c in w.raw.get("countries", []):
			_countries.append({"en": String(c["name_en"]), "tr": String(c["name"])})
	return _countries


## [{en, name}] — ada göre sıralı (Türkçe ad; İngilizce arayüzde İngilizce ad). Düzenleyici bir çağdaysa o çağın ülkeleri.
static func countries() -> Array:
	var base: Array = era_info(era)["countries"] if era != "" else _base_countries()
	var lang_tr: bool = Loc.lang == "tr"
	var out: Array = base.duplicate()
	out.sort_custom(func(a, b): return (a["tr"] if lang_tr else a["en"]) < (b["tr"] if lang_tr else b["en"]))
	for k in extra_names.keys():
		out.append({"en": k, "tr": String(extra_names[k])})
	return out


static var extra_names: Dictionary = {}    # custom_N -> ad (düzenleyici doldurur)


static func country_label(en: String) -> String:
	if en.begins_with("custom_"):
		return String(extra_names.get(en, en))
	if Loc.lang != "tr":
		return en
	for c in countries():
		if c["en"] == en:
			return c["tr"]
	return en


static func valid_country(en) -> bool:
	if typeof(en) != TYPE_STRING:
		return false
	if en.begins_with("custom_") and en.substr(7).is_valid_int() and int(en.substr(7)) < MAX_CUSTOM:
		return true
	for c in _base_countries():
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
	if not code.begins_with(CODE_PREFIX) or code.length() > 240000:
		return {}
	var rest: String = code.substr(CODE_PREFIX.length())
	var dot: int = rest.find(".")
	if dot < 1:
		return {}
	var size: int = int(rest.substr(0, dot))
	if size < 10 or size > 700000:
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


static func _hex(v, fallback: String = "#555555") -> String:
	var t: String = _s(v, 9)
	if t.length() < 4 or t.length() > 9 or not t.begins_with("#"):
		return fallback
	for ch in t:
		if not HEX.contains(ch):
			return fallback
	return t


static func _flag(v) -> String:
	var t: String = _s(v, 600)
	for ch in t:
		if not (ch.is_valid_identifier() or "0123456789|:,.#*-_ ".contains(ch) or ch.to_lower() != ch.to_upper()):
			return ""
	return t


## Yeni devletler, silah/sınıf adları, envanter, teknoloji, ülke adı-bayrak değişimleri
static func _sanitize_custom(d: Dictionary) -> Dictionary:
	var out := {}
	var cs: Array = []
	var raw_c = d.get("custom", [])
	if typeof(raw_c) == TYPE_ARRAY:
		for c in raw_c:
			if cs.size() >= MAX_CUSTOM or typeof(c) != TYPE_DICTIONARY:
				continue
			var pids: Array = []
			var rp = c.get("pids", [])
			if typeof(rp) == TYPE_ARRAY:
				for q in rp:
					if typeof(q) in [TYPE_INT, TYPE_FLOAT] and pids.size() < 300:
						pids.append(int(q))
			if pids.is_empty():
				continue
			var e := {"name": _s(c.get("name", ""), 40), "leader": _s(c.get("leader", ""), 40), "pids": pids,
				"colors": [_hex((c.get("colors", []) as Array)[0] if typeof(c.get("colors", [])) == TYPE_ARRAY and (c.get("colors", []) as Array).size() > 0 else ""),
					_hex((c.get("colors", []) as Array)[1] if typeof(c.get("colors", [])) == TYPE_ARRAY and (c.get("colors", []) as Array).size() > 1 else ""),
					_hex((c.get("colors", []) as Array)[2] if typeof(c.get("colors", [])) == TYPE_ARRAY and (c.get("colors", []) as Array).size() > 2 else "")],
				"flag": _flag(c.get("flag", "")),
				"troops": clampi(int(c.get("troops", 30000)), 1000, 5000000),
				"tech": clampf(float(c.get("tech", 0.5)), 0.0, 1.0),
				"aggression": clampf(float(c.get("aggression", 0.5)), 0.0, 1.0),
				"doctrine": clampi(int(c.get("doctrine", 0)), 0, 9),
				"gold_mult": clampf(float(c.get("gold_mult", 1.0)), 0.0, 10.0),
				"war": bool(c.get("war", false)), "play": bool(c.get("play", false)), "week": clampi(int(c.get("week", 0)), 0, 1000)}
			if c.has("capital"):
				e["capital"] = int(c["capital"])
			if e["name"] == "":
				e["name"] = "Yeni Devlet"
			cs.append(e)
	if not cs.is_empty():
		out["custom"] = cs
	var wp := {}
	var rw = d.get("weapons", {})
	if typeof(rw) == TYPE_DICTIONARY:
		for id in rw.keys():
			if wp.size() >= 120 or typeof(rw[id]) != TYPE_DICTIONARY or not String(id).is_valid_identifier():
				continue
			var w := {}
			if rw[id].has("name"):
				w["name"] = _s(rw[id]["name"], 40)
			if rw[id].has("cost"):
				w["cost"] = clampf(float(rw[id]["cost"]), 0.1, 10.0)
			if rw[id].has("pow"):
				w["pow"] = clampf(float(rw[id]["pow"]), 0.2, 5.0)
			if not w.is_empty():
				wp[String(id)] = w
	if not wp.is_empty():
		out["weapons"] = wp
	var ct := {}
	var rc = d.get("cats", {})
	if typeof(rc) == TYPE_DICTIONARY:
		for k in ["inf", "tank", "afv", "arty", "air", "sub"]:
			if rc.has(k) and _s(rc[k], 30) != "":
				ct[k] = _s(rc[k], 30)
	if not ct.is_empty():
		out["cats"] = ct
	var inv := {}
	var ri = d.get("inv", {})
	if typeof(ri) == TYPE_DICTIONARY:
		for cn in ri.keys():
			if inv.size() >= 30 or not valid_country(cn) or typeof(ri[cn]) != TYPE_DICTIONARY:
				continue
			var m := {}
			for wid in ri[cn].keys():
				if m.size() < 60 and String(wid).is_valid_identifier() and typeof(ri[cn][wid]) in [TYPE_INT, TYPE_FLOAT]:
					m[String(wid)] = clampi(int(ri[cn][wid]), 0, 1000000)
			if not m.is_empty():
				inv[cn] = m
	if not inv.is_empty():
		out["inv"] = inv
	var tm := _num_map(d.get("tech", {}), 0.0, 1.0)
	if not tm.is_empty():
		out["tech"] = tm
	var dm := _num_map(d.get("doctrine", {}), 0.0, 9.0)
	if not dm.is_empty():
		for k in dm.keys():
			dm[k] = int(dm[k])
		out["doctrine"] = dm
	var cn := {}
	var rcn = d.get("cab_names", {})
	if typeof(rcn) == TYPE_DICTIONARY:
		for role in ["def", "for", "int", "fin", "hlt", "spy"]:
			if rcn.has(role) and _s(rcn[role], 40) != "":
				cn[role] = _s(rcn[role], 40)
	if not cn.is_empty():
		out["cab_names"] = cn
	var cev: Array = []
	var rce = d.get("cab_events", [])
	if typeof(rce) == TYPE_ARRAY:
		for e in rce:
			if cev.size() >= 30 or typeof(e) != TYPE_DICTIONARY or _s(e.get("q", ""), 500) == "":
				continue
			var opts: Array = []
			var ro = e.get("o", [])
			if typeof(ro) == TYPE_ARRAY:
				for o in ro:
					if opts.size() >= 4 or typeof(o) != TYPE_DICTIONARY or _s(o.get("t", ""), 40) == "":
						continue
					var eff := {}
					var re = o.get("e", {})
					if typeof(re) == TYPE_DICTIONARY:
						for k in ["g", "stab", "cyb", "ind", "log", "tech", "troops", "unrest", "aggr", "dev"]:
							if re.has(k) and typeof(re[k]) in [TYPE_INT, TYPE_FLOAT]:
								eff[k] = clampf(float(re[k]), -10.0, 10.0)
					opts.append({"t": _s(o["t"], 40), "r": _s(o.get("r", ""), 300), "e": eff})
			if opts.is_empty():
				continue
			var role2: String = String(e.get("role", "def"))
			if not ["def", "for", "int", "fin", "hlt", "spy"].has(role2):
				role2 = "def"
			cev.append({"turn": clampi(int(e.get("turn", 1)), 0, 1000), "role": role2, "who": _s(e.get("who", ""), 40), "role_text": _s(e.get("role_text", ""), 40),
				"q": _s(e["q"], 500), "o": opts})
		cev.sort_custom(func(a, b): return int(a["turn"]) < int(b["turn"]))
	if not cev.is_empty():
		out["cab_events"] = cev
	var rn := {}
	var rr = d.get("rename", {})
	if typeof(rr) == TYPE_DICTIONARY:
		for cn2 in rr.keys():
			if rn.size() >= 40 or not valid_country(cn2) or typeof(rr[cn2]) != TYPE_DICTIONARY:
				continue
			var r := {}
			if _s(rr[cn2].get("name", ""), 40) != "":
				r["name"] = _s(rr[cn2]["name"], 40)
			if _s(rr[cn2].get("leader", ""), 40) != "":
				r["leader"] = _s(rr[cn2]["leader"], 40)
			if rr[cn2].has("color"):
				r["color"] = _hex(rr[cn2]["color"])
			if rr[cn2].has("color2"):
				r["color2"] = _hex(rr[cn2]["color2"])
			if rr[cn2].has("color3"):
				r["color3"] = _hex(rr[cn2]["color3"])
			if _flag(rr[cn2].get("flag", "")) != "":
				r["flag"] = _flag(rr[cn2]["flag"])
			if not r.is_empty():
				rn[cn2] = r
	if not rn.is_empty():
		out["rename"] = rn
	return out


static func sanitize(d: Dictionary) -> Dictionary:
	var out := {"id": new_id(), "kind": "user"}
	out["name"] = _s(d.get("name", ""), 40)
	if out["name"] == "":
		return {}
	out["sub"] = _s(d.get("sub", ""), 60)
	out["blurb"] = _s(d.get("blurb", ""), 300)
	out["intro"] = _s(d.get("intro", ""), 400)
	var sug: Array = []
	for c in d.get("suggest", []):
		if valid_country(c) and sug.size() < 4:
			sug.append(c)
	if sug.is_empty():
		return {}
	out["suggest"] = sug
	if valid_era(d.get("era", "")):
		out["era"] = String(d["era"])
	var yr: int = int(d.get("year", 0)) if typeof(d.get("year", 0)) in [TYPE_INT, TYPE_FLOAT] and not out.has("era") else 0
	if yr >= 1800 and yr <= 2100:
		out["year"] = yr
	var trs: Array = []
	var raw_t = d.get("transfer", [])
	if typeof(raw_t) == TYPE_ARRAY:
		for t in raw_t:
			if trs.size() >= MAX_TRANSFER or typeof(t) != TYPE_ARRAY or t.size() < 3:
				continue
			if not (typeof(t[0]) in [TYPE_INT, TYPE_FLOAT]) or not valid_country(t[1]) or not valid_country(t[2]):
				continue
			trs.append([int(t[0]), t[1], t[2], "own", _s(t[4] if t.size() > 4 else "", 40)])
	if not trs.is_empty():
		out["transfer"] = trs
	var gars: Array = []
	var raw_g = d.get("garrison", [])
	if typeof(raw_g) == TYPE_ARRAY:
		for g in raw_g:
			if gars.size() >= MAX_GARRISON or typeof(g) != TYPE_ARRAY or g.size() < 3:
				continue
			if not (typeof(g[0]) in [TYPE_INT, TYPE_FLOAT]) or not valid_country(g[1]) or not (typeof(g[2]) in [TYPE_INT, TYPE_FLOAT]):
				continue
			gars.append([int(g[0]), g[1], clampi(int(g[2]), 0, 5000000), _s(g[3] if g.size() > 3 else "", 40)])
	if not gars.is_empty():
		out["garrison"] = gars
	out.merge(_sanitize_custom(d))
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
	var tm := _num_map(d.get("troops_mult", {}), 0.1, 5.0)
	if not tm.is_empty():
		out["troops_mult"] = tm
	var gm := _num_map(d.get("treasury_mult", {}), 0.0, 10.0)
	if not gm.is_empty():
		out["treasury_mult"] = gm
	var sm := _num_map(d.get("stability", {}), -60.0, 40.0)
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
	var evs: Array = []
	var raw_e = d.get("events", [])
	if typeof(raw_e) == TYPE_ARRAY:
		for e in raw_e:
			if evs.size() >= MAX_EVENTS or typeof(e) != TYPE_DICTIONARY:
				continue
			var txt: String = _s(e.get("t", ""), 220)
			var fxs: Array = []
			var raw_fx = e.get("fx", [])
			if typeof(raw_fx) == TYPE_ARRAY:
				for f in raw_fx:
					if typeof(f) != TYPE_ARRAY or f.size() < 2 or fxs.size() >= 3:
						continue
					var ft: String = String(f[0])
					if ft == "cabinet":
						if f.size() >= 3 and String(f[2]).contains("|") and _s(f[2], 60) != "":
							fxs.append([ft, "*", _s(f[2], 60)])
						continue
					if not FX_TYPES.has(ft) or not valid_country(f[1]):
						continue
					if ft == "cede":
						if f.size() >= 4 and valid_country(f[2]) and f[1] != f[2]:
							var cp = f[3]
							if typeof(cp) == TYPE_ARRAY:
								var ids: Array = []
								for q in cp:
									if typeof(q) in [TYPE_INT, TYPE_FLOAT] and ids.size() < 200:
										ids.append(int(q))
								if not ids.is_empty():
									fxs.append([ft, f[1], f[2], ids])
							elif String(cp) == "all":
								fxs.append([ft, f[1], f[2], "all"])
					elif ft in ["war", "peace", "ally", "break", "vassal", "embargo"]:
						if f.size() >= 3 and valid_country(f[2]) and f[1] != f[2]:
							fxs.append([ft, f[1], f[2]])
					elif ft == "free":
						fxs.append([ft, f[1]])
					elif ft in ["leader", "rename", "cabinet"]:
						if f.size() >= 3 and _s(f[2], 40) != "":
							fxs.append([ft, f[1], _s(f[2], 40)])
					elif f.size() >= 3:
						var lim := 60.0 if ft == "xstab" else (40.0 if ft == "xgold" else (50.0 if ft == "xtech" else 90.0))
						fxs.append([ft, f[1], clampf(float(f[2]), -lim, lim)])
			if txt == "" and fxs.is_empty():
				continue
			evs.append({"turn": clampi(int(e.get("turn", 1)), 0, 1000), "t": txt, "fx": fxs})
		evs.sort_custom(func(a, b): return int(a["turn"]) < int(b["turn"]))
	if not evs.is_empty():
		out["events"] = evs
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
	var en_ev := {}
	var evl: Array = out.get("events", [])
	for i in evl.size():
		en_ev[str(i)] = String(evl[i].get("t", ""))
	out["en"] = {"name": out["name"], "sub": out.get("sub", ""), "blurb": out.get("blurb", ""), "intro": out.get("intro", ""), "objectives": en_obj, "events": en_ev}
	return out
