extends RefCounted
## Çok dilli arayüz. Oyunun kaynak metinleri Türkçedir; başka bir dil seçilince metinler Godot'nun çeviri kancası
## (Translation._get_message) üzerinden çalışırken çevrilir: Label/Button gibi her Control metni otomatik geçer.
## Dil paketi: data/i18n/<kod>.json  ->  {"exact": {"Türkçe şablon": "Hedef"}, "months": [...], "units": {...}, "dec": ".", "thou": ","}
## Şablonlar %s, %d, %.1f ve {ad} yer tutucuları içerir; eşleşen metindeki değerler çevrilmiş şablona yerleştirilir.
## Eksik metin: seçili dil -> İngilizce -> Türkçe (orijinal).

const LANGS := [
	["tr", "Türkçe"], ["en", "English"], ["de", "Deutsch"], ["es", "Español"], ["fr", "Français"], ["it", "Italiano"],
	["pt", "Português"], ["ru", "Русский"], ["ar", "العربية"], ["fa", "فارسی"], ["zh", "中文"], ["ja", "日本語"], ["ko", "한국어"], ["hi", "हिन्दी"],
]
const MONTHS_TR := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

static var lang := "tr"
static var months: Array = MONTHS_TR
static var units := {"tr": " tr", "mr": " mr", "mn": " mn"}
static var dec := ","
static var thou := "."
static var rtl := false
static var _exact: Dictionary = {}
static var _tmpl: Array = []            # [{re, out(Array of parts), lit(int)}]
static var _index: Dictionary = {}      # kelime -> [şablon dizini]
static var _frag: Array = []            # [[tr, hedef]] uzunluktan kısaya
static var _en_names: Dictionary = {}
static var _tokens: Dictionary = {}
static var _cache: Dictionary = {}
static var debug := false
static var misses: Dictionary = {}
static var _tr_obj = null
static var _word_re: RegEx = null


const LocTr = preload("res://scripts/loc_tr.gd")


static func available() -> Array:
	var out: Array = []
	for l in LANGS:
		if l[0] == "tr" or FileAccess.file_exists("res://data/i18n/%s.json" % l[0]) or ResourceLoader.exists("res://data/i18n/%s.json" % l[0]):
			out.append(l)
	return out


static func native_name(code: String) -> String:
	for l in LANGS:
		if l[0] == code:
			return l[1]
	return code


static func _read(code: String) -> Dictionary:
	var p := "res://data/i18n/%s.json" % code
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	var v = JSON.parse_string(f.get_as_text())
	return v if typeof(v) == TYPE_DICTIONARY else {}


## Sistem dilinden ya da kayıtlı seçimden dil seçer ve uygular.
static func setup(saved: String) -> String:
	var code := saved
	if code == "":
		code = OS.get_locale_language()
		if code == "zh":
			code = "zh"
	var ok := false
	for l in available():
		if l[0] == code:
			ok = true
	if not ok:
		code = "en" if available().any(func(l): return l[0] == "en") else "tr"
	apply(code)
	return code


static func apply(code: String) -> void:
	lang = code
	_exact = {}
	_tmpl = []
	_index = {}
	_frag = []
	_tokens = {}
	_en_names = {}
	_cache = {}
	months = MONTHS_TR
	units = {"tr": " tr", "mr": " mr", "mn": " mn"}
	dec = ","
	thou = "."
	rtl = code == "ar" or code == "fa"
	if _tr_obj != null:
		TranslationServer.remove_translation(_tr_obj)
		_tr_obj = null
	if code == "tr":
		TranslationServer.set_locale("tr")
		return
	var en: Dictionary = _read("en") if code != "en" else {}
	var pack: Dictionary = _read(code)
	var src: Dictionary = {}
	for k in en.get("exact", {}):
		src[k] = en["exact"][k]
	for k in pack.get("exact", {}):
		if str(pack["exact"][k]) != "":
			src[k] = pack["exact"][k]
	months = pack.get("months", en.get("months", MONTHS_TR))
	units = pack.get("units", en.get("units", units))
	dec = pack.get("dec", en.get("dec", "."))
	thou = pack.get("thou", en.get("thou", ","))
	_tokens = pack.get("tokens", en.get("tokens", {}))
	_en_names = (en if code != "en" else _read("en")).get("exact", {})
	_build(src)
	_tr_obj = LocTr.new()
	_tr_obj.locale = code
	TranslationServer.add_translation(_tr_obj)
	TranslationServer.set_locale(code)


static func _build(src: Dictionary) -> void:
	var ph := RegEx.new()
	ph.compile("%[-+0-9.]*[sdf]|%%|\\{[a-z_]+\\}")
	_word_re = RegEx.new()
	_word_re.compile("[^\\W\\d_]{4,}")
	var long_keys: Array = []
	for key in src:
		var tgt: String = str(src[key])
		var ms: Array = ph.search_all(key)
		var has := false
		for m in ms:
			if m.get_string() != "%%":
				has = true
		if not has:
			_exact[key] = tgt.replace("%%", "%") if key.find("%%") >= 0 else tgt
			if key.length() >= 10:
				long_keys.append(key)
			continue
		# şablon: kaynak -> regex
		var pat := "^"
		var last := 0
		var names: Array = []
		var n_groups := 0
		var lit := 0
		for m in ms:
			var seg: String = key.substr(last, m.get_start() - last)
			pat += _esc(seg)
			lit += seg.length()
			var tok: String = m.get_string()
			last = m.get_end()
			if tok == "%%":
				pat += "%"
			elif tok.begins_with("{"):
				pat += "(.+?)"
				n_groups += 1
				names.append(tok.substr(1, tok.length() - 2))
			elif tok.ends_with("d"):
				pat += "([-+]?\\d+)"
				n_groups += 1
				names.append("")
			elif tok.ends_with("f"):
				pat += "([-+]?[\\d\\.,]+)"
				n_groups += 1
				names.append("")
			else:
				pat += "(.+?)"
				n_groups += 1
				names.append("")
		var tail: String = key.substr(last)
		pat += _esc(tail) + "$"
		lit += tail.length()
		var re := RegEx.new()
		if re.compile("(?s)" + pat) != OK:
			continue
		# hedef: parçalar [metin | grup indeksi]
		var out: Array = []
		var seq := 0
		var tl := 0
		for m2 in ph.search_all(tgt):
			out.append(tgt.substr(tl, m2.get_start() - tl))
			tl = m2.get_end()
			var tk: String = m2.get_string()
			if tk == "%%":
				out.append("%")
			elif tk.begins_with("{"):
				var nm: String = tk.substr(1, tk.length() - 2)
				var gi: int = names.find(nm)
				out.append(maxi(gi, 0))
			else:
				out.append(seq)
				seq += 1
		out.append(tgt.substr(tl))
		var idx := _tmpl.size()
		_tmpl.append({"re": re, "out": out, "lit": lit, "n": n_groups})
		# dizin: kaynağın en uzun sabit kelimesi
		var best := ""
		for wm in _word_re.search_all(_strip(key, ph)):
			if wm.get_string().length() > best.length():
				best = wm.get_string()
		if best == "":
			best = "*"
		if not _index.has(best):
			_index[best] = []
		_index[best].append(idx)
	# kodda önceden BÜYÜK HARF yazılmış Türkçe etiketler için büyük harfli eşleşmeler
	for key in _exact.keys():
		if key.length() <= 40 and key.find("\n") < 0:
			var k2: String = key.replace("i", "İ").replace("ı", "I").to_upper()
			if k2 != key and not _exact.has(k2):
				_exact[k2] = str(_exact[key]).to_upper()
	long_keys.sort_custom(func(a, b): return a.length() > b.length())
	for k in long_keys:
		_frag.append([k, _exact[k]])


static func _strip(key: String, ph: RegEx) -> String:
	return ph.sub(key, " ", true)


static func _esc(s: String) -> String:
	var out := ""
	for ch in s:
		if "\\.^$|?*+()[]{}".find(ch) >= 0:
			out += "\\" + ch
		else:
			out += ch
	return out


## Metni seçili dile çevirir; çeviri yoksa boş döner.
static func translate(s: String) -> String:
	if lang == "tr" or s == "":
		return ""
	var hit = _cache.get(s)
	if hit != null:
		return hit
	var r := _translate(s)
	if r == "" and debug:
		misses[s] = true
	if _cache.size() > 6000:
		_cache.clear()
	_cache[s] = r
	return r


static func _translate(s: String) -> String:
	var e = _exact.get(s)
	if e != null:
		return e
	# şablon adayları: metindeki kelimelere göre
	var cand: Dictionary = {}
	if _word_re != null:
		for wm in _word_re.search_all(s):
			var lst = _index.get(wm.get_string())
			if lst != null:
				for i in lst:
					cand[i] = true
	var lst2 = _index.get("*")
	if lst2 != null:
		for i in lst2:
			cand[i] = true
	var best = null
	var best_lit := -1
	var best_m = null
	for i in cand:
		var t: Dictionary = _tmpl[i]
		if t.lit <= best_lit:
			continue
		var m: RegExMatch = t.re.search(s)
		if m != null:
			best = t
			best_lit = t.lit
			best_m = m
	if best != null:
		var out := ""
		for part in best.out:
			if typeof(part) == TYPE_INT:
				var g: String = best_m.get_string(part + 1) if part + 1 <= best.n else ""
				var tg: String = translate(g)
				out += tg if (tg != "" and not g.is_valid_int()) else g
			else:
				out += part
		return out
	# çok satırlı metin: satır satır çevir
	if s.find("\n") >= 0:
		var parts := s.split("\n")
		var any := false
		var outl: PackedStringArray = []
		for ln in parts:
			var tl := translate(ln) if ln.strip_edges() != "" else ""
			if tl != "":
				any = true
				outl.append(tl)
			else:
				outl.append(ln)
		if any:
			return "\n".join(outl)
	# ayraçlı bileşik metin: "Ülke / Şehir", "a · b"
	for sep in ["  /  ", " / ", "   ·   ", "  ·  ", " · ", ", ", " - ", ": "]:
		if s.find(sep) > 0:
			var ps := s.split(sep)
			var anyc := false
			var outp: PackedStringArray = []
			for pt in ps:
				var tp := translate(pt) if pt.strip_edges() != "" else ""
				if tp != "":
					anyc = true
					outp.append(tp)
				else:
					outp.append(pt)
			if anyc:
				return sep.join(outp)
	# parça parça: bilinen uzun ifadeleri değiştir, sonra birim jetonları
	var r := s
	var changed := false
	if s.length() >= 10:
		for pr in _frag:
			if r.find(pr[0]) >= 0:
				r = r.replace(pr[0], pr[1])
				changed = true
	for tk in _tokens:
		if r.find(tk) >= 0:
			r = r.replace(tk, _tokens[tk])
			changed = true
	return r if changed else ""


## Metni doğrudan çevirir (Control dışı çizimler için); yoksa aynısı.
static func t(s: String) -> String:
	var r := translate(s)
	if r == "":
		r = s
	if lang != "tr" and r.contains("%"):
		r = pct_fix(r)
	return r


static var _pct_re: RegEx = null


## Türkçe yazım "%26" → diğer dillerde "26%"
static func pct_fix(s: String) -> String:
	if _pct_re == null:
		_pct_re = RegEx.new()
		_pct_re.compile("(?<![\\w%])%(\\d+(?:[.,]\\d+)?)(?![\\w%])")
	return _pct_re.sub(s, "$1%", true)


## Yüzde yazımı: Türkçede "%26", diğer dillerde "26%"
static func pct(v: int) -> String:
	return "%%%d" % v if lang == "tr" else "%d%%" % v


## Haritadaki ülke adı: yalnızca Türkçede Türkçe, diğer tüm dillerde İngilizce.
static func map_name(name_tr: String, name_en: String) -> String:
	if lang == "tr":
		return name_tr
	var e = _en_names.get(name_tr)
	return str(e) if e != null else name_en


static func ucase(s: String) -> String:
	if lang == "tr":
		return s.replace("i", "İ").replace("ı", "I").to_upper()
	return s.to_upper()
