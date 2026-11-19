extends RefCounted
## Dönem bakan portre havuzları (yüzsüz sticker siluetler): assets/icons/pt_<set>_<n>_c.png
## kind: m sivil, o asker (savunma), h hekim (sağlık), s casus. Boş dönerse çağıran eski çizime/modern sete döner.

static func _r(pref: String, idx: Array) -> Array:
	var out := []
	for i in idx:
		out.append("pt_%s_%d" % [pref, i])
	return out


## Her sette 6'lık düzen: 1-3 sivil, 4-5 asker, 6 hekim.
static func _pre(pref: String, off: int) -> Dictionary:
	return {"m": _r(pref, [off + 1, off + 2, off + 3]), "o": _r(pref, [off + 4, off + 5]), "h": _r(pref, [off + 6]), "s": []}


static func _w1(off: int) -> Dictionary:
	return {"m": _r("w1", [off + 1, off + 4]), "o": _r("w1", [off + 2, off + 3]), "h": _r("w1", [off + 5]), "s": _r("w1", [off + 6])}


static func pool(fam: String, culture: String, kind: String) -> Array:
	var d: Dictionary = _pick_set(fam, culture)
	if d.is_empty():
		return []
	var l: Array = d.get(kind, [])
	if l.is_empty() and kind in ["h", "s"]:
		l = d.get("m", [])
	return l


static func _pick_set(fam: String, c: String) -> Dictionary:
	var islam := c in ["turk", "lev", "gulf", "pers"]
	match fam:
		"pre":
			if islam: return _pre("pre_isl", 0)
			if c in ["west", "slav"]: return _pre("pre_eu", 0)
			if c == "easia": return _pre("pre_easia", 0)
			if c in ["sasia", "seasia"]: return _pre("pre_sasia", 0)
			if c == "afr": return _pre("pre_afla", 0)
			if c in ["latam", "pac"]: return _pre("pre_afla", 6)
		"ww1":
			if islam: return _w1(6)
			if c in ["west", "slav", "latam", "easia"]: return _w1(0)
			return _w1(12)
		"ww2":
			if c in ["west", "latam"]:
				return {"m": _r("w2", [1]), "o": _r("w2", [2, 3, 4, 8]), "h": [], "s": []}
			if c == "slav":
				return {"m": _r("w2", [1]), "o": _r("w2", [5, 2, 3, 4]), "h": [], "s": []}
			if c == "easia":
				return {"m": _r("w2", [7, 1]), "o": _r("w2", [6, 2, 3]), "h": [], "s": []}
			return {"m": _r("w2", [1]), "o": _r("w2", [8, 3, 4, 2]), "h": [], "s": []}
		"cold":
			if c in ["west", "latam"]:
				return {"m": _r("cw", [1, 2]), "o": _r("cw", [3]), "h": [], "s": _r("cw", [2])}
			if c == "slav":
				return {"m": _r("cw", [2, 1]), "o": _r("cw", [3]), "h": [], "s": _r("cw", [2])}
			if islam:
				return {"m": _r("cw", [4, 1]), "o": _r("cw", [3]), "h": [], "s": []}
			if c == "afr":
				return {"m": _r("cw", [5, 1]), "o": _r("cw", [3]), "h": [], "s": []}
			if c in ["easia", "seasia"]:
				return {"m": _r("cw", [6, 1]), "o": _r("cw", [3, 6]), "h": [], "s": []}
			if c == "pac":
				return {"m": _r("cw", [1, 5]), "o": _r("cw", [3]), "h": [], "s": []}
			return {"m": _r("cw", [1]), "o": _r("cw", [3]), "h": [], "s": []}
	return {}


## Devlet başkanı büstleri (yüzsüz sticker): fam "" = modern. Boş dönerse çağıran kod çizimine döner.
static func head(fam: String, c: String) -> Array:
	var islam := c in ["turk", "lev", "gulf", "pers"]
	match fam:
		"pre":
			if islam: return _r("hs_isl", [1, 2, 3, 4, 6])
			return _hs("hs_eu", "hs_ea", "hs_af", c)
		"ww1":
			if islam: return _r("hs_ww", [3])
			if c == "easia": return _r("hs_ww", [4])
			if c == "slav": return _r("hs_ww", [1, 5])
			return _r("hs_ww", [6, 3, 1])
		"ww2":
			if c == "easia": return _r("hs_ww", [4, 3])
			if c == "slav": return _r("hs_ww", [5, 3])
			if c in ["west", "latam"]: return _r("hs_ww", [2, 3])
			return _r("hs_ww", [3, 2])
		"cold":
			if c == "slav": return _r("hs_cw", [5, 1])
			if c in ["west", "latam"]: return _r("hs_cw", [1])
			if c in ["easia", "seasia"]: return _r("hs_cw", [2])
			if islam: return _r("hs_cw", [4])
			if c == "afr": return _r("hs_cw", [6, 3])
			return _r("hs_cw", [3, 1])
		"":
			if c in ["gulf", "lev", "pers"]: return _r("hs_md", [2])
			if c == "easia": return _r("hs_md", [3])
			if c == "afr": return _r("hs_md", [4])
			if c == "latam": return _r("hs_md", [5])
			if c in ["sasia", "seasia"]: return _r("hs_md", [6])
			return _r("hs_md", [1])
	return []


static func _hs(eu: String, ea: String, af: String, c: String) -> Array:
	if c in ["west", "slav"]: return _r(eu, [1, 2, 3, 5, 6])
	if c == "easia": return _r(ea, [1, 2, 3, 4, 5, 6])
	if c == "sasia": return _r(af, [3, 5])
	if c == "afr": return _r(af, [1, 4, 6])
	return _r(af, [2, 6, 1])
