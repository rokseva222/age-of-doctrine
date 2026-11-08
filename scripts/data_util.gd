extends RefCounted
## JSON veri yardımcıları (senaryo ve çağ dosyaları). Godot JSON'u her sayıyı float okur; tam sayı olanları int'e çevirir.
const Loc = preload("res://scripts/loc.gd")

static func read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	var js := JSON.new()
	if js.parse(txt) != OK:
		push_warning("JSON hatası %s satır %d: %s" % [path, js.get_error_line(), js.get_error_message()])
		return null
	return norm(js.data)


static func norm(v):
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if is_equal_approx(v, round(v)) and absf(v) < 1.0e9 else v
		TYPE_ARRAY:
			var a: Array = []
			for x in v:
				a.append(norm(x))
			return a
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = norm(v[k])
			return d
	return v


## id listesi dosyası: ["a","b"] -> her biri dir/<id>.json
static func read_index(dir: String) -> Array:
	var idx = read_json(dir + "/index.json")
	return idx if idx is Array else []


## Dile göre metin: lang tr ise orijinal, aksi halde (varsa) en bloğu.
static func pick_en(d: Dictionary, key: String, lang: String) -> String:
	var en := ""
	if d.has("en") and (d["en"] as Dictionary).has(key):
		en = String(d["en"][key])
	return loc_text(String(d.get(key, "")), en)


## Veri dosyalarındaki metin: Türkçe kaynak, İngilizce blok, diğer diller için çeviri tablosu (Türkçe kaynak anahtarlı)
static func loc_text(tr: String, en: String) -> String:
	if Loc.lang == "tr":
		return tr
	if Loc.lang != "en":
		var r: String = Loc.translate(tr)
		if r != "":
			return r
	return en if en != "" else tr
