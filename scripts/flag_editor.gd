extends RefCounted
## Katmanlı bayrak editörü. Sonuç flags.gd'nin okuduğu kısa tanım dizgesidir ("H:#aa0000,#ffffff|C:.5,.5,.2,#00aa00").
## Katmanlar alttan üste çizilir; her katmanın türü, rengi ve konumu/boyutu ayarlanır; canlı önizleme gösterilir.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Flags = preload("res://scripts/flags.gd")
const Icons = preload("res://scripts/icons.gd")

# tür -> [ad, [[anahtar, etiket, min, max, adım, varsayılan], ...], renk sayısı]
const TYPES := {
	"H": ["Yatay şeritler", [["n", "Şerit sayısı", 1, 5, 1, 3]], 5],
	"V": ["Dikey şeritler", [["n", "Şerit sayısı", 1, 5, 1, 3]], 5],
	"R": ["Dikdörtgen", [["x0", "Sol", 0.0, 1.0, 0.01, 0.0], ["y0", "Üst", 0.0, 1.0, 0.01, 0.0], ["x1", "Sağ", 0.0, 1.0, 0.01, 0.5], ["y1", "Alt", 0.0, 1.0, 0.01, 0.5]], 1],
	"C": ["Daire", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.5], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["r", "Yarıçap", 0.02, 0.6, 0.01, 0.22]], 1],
	"O": ["Halka", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.5], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["r", "Yarıçap", 0.05, 0.6, 0.01, 0.28], ["w", "Kalınlık", 0.01, 0.2, 0.01, 0.05]], 1],
	"S": ["Yıldız", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.5], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["r", "Boyut", 0.03, 0.5, 0.01, 0.2], ["n", "Köşe sayısı", 4, 12, 1, 5]], 1],
	"K": ["Haç", [["cx", "Yatay konum", 0.0, 1.0, 0.01, 0.4], ["cy", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["w", "Kalınlık", 0.04, 0.4, 0.01, 0.14]], 1],
	"L": ["Çizgi / çapraz", [["x0", "Başlangıç x", 0.0, 1.0, 0.01, 0.0], ["y0", "Başlangıç y", 0.0, 1.0, 0.01, 0.0], ["x1", "Bitiş x", 0.0, 1.0, 0.01, 1.0], ["y1", "Bitiş y", 0.0, 1.0, 0.01, 1.0], ["w", "Kalınlık", 0.03, 0.6, 0.01, 0.2]], 1],
	"T": ["Üçgen", [["x", "Uç noktası x", 0.0, 1.0, 0.01, 0.5], ["y", "Uç noktası y", 0.0, 1.0, 0.01, 0.5]], 1],
	"M": ["Hilal", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.4], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["r", "Boyut", 0.05, 0.5, 0.01, 0.25], ["rot", "Dönüş (°)", -180.0, 180.0, 5.0, 0.0]], 1],
	"Y": ["Sembol (kılıç, taç, kalkan…)", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.5], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["size", "Boyut", 0.1, 1.0, 0.01, 0.45]], 1],
	"Z": ["Güneş (ışınlı)", [["x", "Yatay konum", 0.0, 1.0, 0.01, 0.5], ["y", "Dikey konum", 0.0, 1.0, 0.01, 0.5], ["r", "Boyut", 0.05, 0.5, 0.01, 0.22], ["n", "Işın sayısı", 8, 24, 1, 16]], 1],
	"D": ["Eşkenar dörtgen", [["w", "Genişlik", 0.2, 1.0, 0.01, 0.7]], 1],
}

## Simge kitaplığından bayrağa uygun semboller
const SYMBOLS := [["sword", "Kılıç"], ["swords", "Çapraz kılıçlar"], ["star", "Yıldız"], ["crown", "Taç"], ["shield", "Kalkan"], ["anchor", "Çapa"], ["castle", "Kale"],
	["wheat", "Buğday"], ["flame", "Alev"], ["globe", "Küre"], ["plane", "Uçak"], ["tank", "Tank"], ["bolt", "Şimşek"], ["target", "Hedef"], ["handshake", "El sıkışma"],
	["skull", "Kafatası"], ["trophy", "Kupa"], ["factory", "Fabrika"]]

## Bayrak amblemi seti (assets/icons/fl_<ad>.png, beyaz siluet; renge boyanır). Dosyası olanlar listelenir; hiçbiri yoksa eski simgeler.
const EMBLEMS := [["hammer_sickle", "Orak ve çekiç"], ["hammer", "Çekiç"], ["sickle", "Orak"], ["star5", "Yıldız"], ["crescent", "Hilal"], ["crescent_star", "Hilal ve yıldız"],
	["eagle", "Kartal"], ["eagle2", "Çift başlı kartal"], ["lion", "Aslan"], ["crown", "Taç"], ["sword", "Kılıç"], ["swords", "Çapraz kılıçlar"], ["shield", "Kalkan"], ["anchor", "Çapa"],
	["wheat", "Buğday başağı"], ["laurel", "Defne çelengi"], ["olive", "Zeytin dalı"], ["gear", "Çark"], ["sun", "Güneş"], ["dragon", "Ejderha"], ["wolf", "Bozkurt"], ["bear", "Ayı"],
	["fist", "Yumruk"], ["tower", "Kule"], ["trident", "Üç dişli mızrak"], ["torch", "Meşale"], ["book", "Kitap"], ["oak", "Meşe yaprağı"], ["cross", "Haç"], ["lily", "Zambak"],
	["star6", "Altı köşeli yıldız"], ["star8", "Sekiz köşeli yıldız"], ["maple", "Akçaağaç yaprağı"], ["palm", "Palmiye"], ["cedar", "Sedir"], ["rose", "Gül"], ["horse", "At"], ["falcon", "Şahin"],
	["elephant", "Fil"], ["snake", "Yılan"], ["axe", "Balta"], ["spear", "Mızrak"], ["helmet", "Miğfer"], ["globe", "Küre"], ["mountain", "Dağ"]]


static func _symbol_set() -> Array:
	var out: Array = []
	for e in EMBLEMS:
		if Icons.pick("fl_" + String(e[0]), "") != "":
			out.append(["fl_" + String(e[0]), e[1]])
	return out if not out.is_empty() else SYMBOLS


const PRESETS := [
	["Düz", [["R", ["#c8102e"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}]]],
	["Yatay üç şerit", [["H", ["#d52b1e", "#ffffff", "#0039a6"], {"n": 3}]]],
	["Dikey üç şerit", [["V", ["#0055a4", "#ffffff", "#ef4135"], {"n": 3}]]],
	["İskandinav haçı", [["R", ["#0b3d91"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["K", ["#ffd200"], {"cx": 0.36, "cy": 0.5, "w": 0.16}]]],
	["Hilal ve yıldız", [["R", ["#e30a17"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["M", ["#ffffff"], {"x": 0.4, "y": 0.5, "r": 0.26, "rot": 0.0}], ["S", ["#ffffff"], {"x": 0.58, "y": 0.5, "r": 0.1, "n": 5}]]],
	["Yeşil, hilal ve kılıç", [["R", ["#0a6c3a"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["M", ["#ffffff"], {"x": 0.5, "y": 0.4, "r": 0.2, "rot": -90.0}], ["Y", ["#ffffff"], {"x": 0.5, "y": 0.68, "size": 0.3, "icon": "swords"}]]],
	["Kırmızı, taç ve yıldız", [["R", ["#c8102e"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["Y", ["#f2c200"], {"x": 0.5, "y": 0.42, "size": 0.42, "icon": "crown"}], ["S", ["#f2c200"], {"x": 0.5, "y": 0.8, "r": 0.08, "n": 5}]]],
	["Daire (güneş)", [["R", ["#ffffff"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["C", ["#bc002d"], {"x": 0.5, "y": 0.5, "r": 0.3}]]],
	["Üçgen ve yıldız", [["H", ["#009a44", "#fcd116"], {"n": 2}], ["T", ["#ce1126"], {"x": 0.5, "y": 0.5}], ["S", ["#ffffff"], {"x": 0.16, "y": 0.5, "r": 0.1, "n": 5}]]],
	["Çapraz", [["R", ["#012169"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0}], ["L", ["#ffffff"], {"x0": 0.0, "y0": 0.0, "x1": 1.0, "y1": 1.0, "w": 0.22}], ["L", ["#ffffff"], {"x0": 0.0, "y0": 1.0, "x1": 1.0, "y1": 0.0, "w": 0.22}]]],
]

class Preview extends Control:
	var spec := ""

	func _init() -> void:
		custom_minimum_size = Vector2(300, 200)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, Vector2(size.x, size.x / Flags.ASPECT))
		if r.size.y > size.y:
			r = Rect2(Vector2.ZERO, Vector2(size.y * Flags.ASPECT, size.y))
		Flags._draw_layers(self, r, Flags._parse(spec) if spec != "" else [])
		draw_rect(r, Color(1, 1, 1, 0.25), false, 1.0)

var root: Node
var layers: Array = []     # [tür, [renkler], {parametreler}]
var _preview: Preview
var _list: VBoxContainer
var _on_done: Callable
var _sheet


static func open(parent: Node, initial_spec: String, on_done: Callable) -> void:
	var e = load("res://scripts/flag_editor.gd").new()
	e.root = parent
	e._on_done = on_done
	e.layers = from_spec(initial_spec)
	if e.layers.is_empty():
		e.layers = _copy_layers(PRESETS[1][1])
	e._build()


static func _copy_layers(src: Array) -> Array:
	var out: Array = []
	for l in src:
		out.append([l[0], (l[1] as Array).duplicate(), (l[2] as Dictionary).duplicate()])
	return out


static func _f(v: float) -> String:
	return ("%.2f" % v).rstrip("0").rstrip(".") if absf(v - roundf(v)) > 0.001 else str(int(roundf(v)))


## Katman listesi → flags.gd dizgesi
static func to_spec(ls: Array) -> String:
	var parts: PackedStringArray = []
	for l in ls:
		var t: String = l[0]
		var cols: Array = l[1]
		var p: Dictionary = l[2]
		match t:
			"H", "V":
				var n: int = clampi(int(p.get("n", 3)), 1, 5)
				var cs: PackedStringArray = []
				for i in n:
					cs.append(String(cols[i % cols.size()]))
				parts.append("%s:%s" % [t, ",".join(cs)])
			"R":
				parts.append("R:%s,%s,%s,%s,%s" % [_f(p.x0), _f(p.y0), _f(p.x1), _f(p.y1), cols[0]])
			"C":
				parts.append("C:%s,%s,%s,%s" % [_f(p.x), _f(p.y), _f(p.r), cols[0]])
			"O":
				parts.append("O:%s,%s,%s,%s,%s" % [cols[0], _f(p.w), _f(p.x), _f(p.y), _f(p.r)])
			"S":
				parts.append("S:%s,%s,%s,%s,%d,-90" % [_f(p.x), _f(p.y), _f(p.r), cols[0], int(p.n)])
			"K":
				parts.append("K:%s,%s,%s,%s" % [cols[0], _f(p.w), _f(p.cx), _f(p.cy)])
			"L":
				parts.append("L:%s,%s,%s,%s,%s,%s,%s" % [cols[0], _f(p.w), _f(p.x0), _f(p.y0), _f(p.x1), _f(p.y1)])
			"M":
				parts.append("M:%s,%s,%s,%s,%d" % [cols[0], _f(p.x), _f(p.y), _f(p.r), int(p.rot)])
			"Y":
				parts.append("Y:%s,%s,%s,%s,%s" % [cols[0], String(p.get("icon", "star")), _f(p.x), _f(p.y), _f(p.size)])
			"Z":
				parts.append("S:%s,%s,%s,%s,%d,-90|C:%s,%s,%s,%s" % [_f(p.x), _f(p.y), _f(p.r), cols[0], int(p.n), _f(p.x), _f(p.y), _f(float(p.r) * 0.62), cols[0]])
			"T":
				parts.append("P:%s,0,0,%s,%s,0,1" % [cols[0], _f(p.x), _f(p.y)])
			"D":
				var hw: float = float(p.w) / 2.0
				parts.append("P:%s,0.5,%s,%s,0.5,0.5,%s,%s,0.5" % [cols[0], _f(0.5 - 0.45), _f(0.5 + hw), _f(0.5 + 0.45), _f(0.5 - hw)])
	return "|".join(parts)


## Dizgeyi katmanlara geri çevirir (yalnızca bu editörün ürettiği biçimler; tanınmayan parçalar atlanır)
static func from_spec(spec: String) -> Array:
	var out: Array = []
	for part in spec.split("|", false):
		var i := part.find(":")
		if i < 0:
			continue
		var t := part.substr(0, i)
		var a: PackedStringArray = part.substr(i + 1).split(",", false)
		match t:
			"H", "V":
				var cols: Array = []
				for c in a:
					cols.append(c.split("*")[0])
				out.append([t, cols, {"n": cols.size()}])
			"R":
				if a.size() >= 5:
					out.append(["R", [a[4]], {"x0": float(a[0]), "y0": float(a[1]), "x1": float(a[2]), "y1": float(a[3])}])
			"C":
				if a.size() >= 4:
					out.append(["C", [a[3]], {"x": float(a[0]), "y": float(a[1]), "r": float(a[2])}])
			"O":
				if a.size() >= 5:
					out.append(["O", [a[0]], {"w": float(a[1]), "x": float(a[2]), "y": float(a[3]), "r": float(a[4])}])
			"S":
				if a.size() >= 4:
					out.append(["S", [a[3]], {"x": float(a[0]), "y": float(a[1]), "r": float(a[2]), "n": int(a[4]) if a.size() > 4 else 5}])
			"K":
				if a.size() >= 4:
					out.append(["K", [a[0]], {"w": float(a[1]), "cx": float(a[2]), "cy": float(a[3])}])
			"L":
				if a.size() >= 6:
					out.append(["L", [a[0]], {"w": float(a[1]), "x0": float(a[2]), "y0": float(a[3]), "x1": float(a[4]), "y1": float(a[5])}])
			"M":
				if a.size() >= 5:
					out.append(["M", [a[0]], {"x": float(a[1]), "y": float(a[2]), "r": float(a[3]), "rot": float(a[4])}])
			"Y":
				if a.size() >= 5:
					out.append(["Y", [a[0]], {"icon": a[1], "x": float(a[2]), "y": float(a[3]), "size": float(a[4])}])
			"P":
				if a.size() == 7 and a[1] == "0" and a[2] == "0":
					out.append(["T", [a[0]], {"x": float(a[3]), "y": float(a[4])}])
	return out


func _build() -> void:
	_sheet = Sheet.open(root, Loc.t("Bayrak editörü"), 860, true, true, Loc.t("Katmanları üst üste dizerek bayrağını çiz"))
	_preview = Preview.new()
	_sheet.body.add_child(_preview)
	var ph := HFlowContainer.new()
	ph.add_theme_constant_override("h_separation", 6)
	ph.add_theme_constant_override("v_separation", 6)
	for pr in PRESETS:
		var b := TK.button(Loc.t(pr[0]), "ghost", "", Vector2(0, 46), 15)
		var preset: Array = pr[1]
		b.pressed.connect(func():
			layers = _copy_layers(preset)
			_refresh())
		ph.add_child(b)
	_sheet.body.add_child(TK.t(Loc.t("Hazır şablonlar"), "kicker", TK.MUTED))
	_sheet.body.add_child(ph)
	_sheet.body.add_child(HSeparator.new())
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_sheet.body.add_child(_list)
	var add := HFlowContainer.new()
	add.add_theme_constant_override("h_separation", 6)
	add.add_theme_constant_override("v_separation", 6)
	_sheet.body.add_child(TK.t(Loc.t("Katman ekle"), "kicker", TK.MUTED))
	for t in TYPES.keys():
		var tt: String = t
		var b2 := TK.button("+ " + Loc.t(TYPES[t][0]), "", "", Vector2(0, 46), 15)
		b2.pressed.connect(func():
			if layers.size() >= 10:
				return
			var p := {}
			for pr2 in TYPES[tt][1]:
				p[pr2[0]] = pr2[5]
			if tt == "Y":
				p["icon"] = "swords"
			var cols: Array = []
			for i in int(TYPES[tt][2]):
				cols.append(["#ffffff", "#c8102e", "#0b3d91", "#fcd116", "#009a44"][i % 5])
			layers.append([tt, cols, p])
			_refresh())
		add.add_child(b2)
	_sheet.body.add_child(add)
	_sheet.add_button("Uygula", func():
		_on_done.call(to_spec(layers)), "gold", true, "check", 160)
	_sheet.add_button("Bayrağı sıfırla (otomatik)", func():
		_on_done.call(""), "", true, "", 240)
	_sheet.add_button("Kapat", func(): pass, "", true, "x", 130)
	_refresh()


func _refresh() -> void:
	_preview.spec = to_spec(layers)
	_preview.queue_redraw()
	for ch in _list.get_children():
		_list.remove_child(ch)
		ch.queue_free()
	for i in layers.size():
		var idx: int = i
		var l: Array = layers[i]
		var t: String = l[0]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		var nm := TK.t("%d. %s" % [i + 1, Loc.t(TYPES[t][0])], "bodyb", TK.GOLD)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		for cp_i in (l[1] as Array).size():
			var ci: int = cp_i
			var cb := ColorPickerButton.new()
			cb.edit_alpha = false
			cb.color = Color.html(String(l[1][ci]))
			cb.custom_minimum_size = Vector2(56, 44)
			cb.color_changed.connect(func(c: Color):
				layers[idx][1][ci] = "#" + c.to_html(false)
				_preview.spec = to_spec(layers)
				_preview.queue_redraw())
			head.add_child(cb)
		var up := TK.button("▲", "ghost", "", Vector2(48, 44), 15)
		up.disabled = i == 0
		up.pressed.connect(func():
			var tmp = layers[idx]
			layers[idx] = layers[idx - 1]
			layers[idx - 1] = tmp
			_refresh())
		head.add_child(up)
		var dn := TK.button("▼", "ghost", "", Vector2(48, 44), 15)
		dn.disabled = i == layers.size() - 1
		dn.pressed.connect(func():
			var tmp2 = layers[idx]
			layers[idx] = layers[idx + 1]
			layers[idx + 1] = tmp2
			_refresh())
		head.add_child(dn)
		var rm := TK.button("✕", "danger", "", Vector2(48, 44), 15)
		rm.pressed.connect(func():
			layers.remove_at(idx)
			_refresh())
		head.add_child(rm)
		box.add_child(head)
		for pr in TYPES[t][1]:
			var key: String = pr[0]
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			var lb := TK.t(Loc.t(pr[1]), "small", TK.MUTED)
			lb.custom_minimum_size = Vector2(150, 0)
			hb.add_child(lb)
			var sl := HSlider.new()
			sl.min_value = float(pr[2])
			sl.max_value = float(pr[3])
			sl.step = float(pr[4])
			sl.value = float(l[2].get(key, pr[5]))
			sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sl.custom_minimum_size = Vector2(0, 36)
			var vl := TK.t(_f(sl.value), "small", TK.TEXT)
			vl.custom_minimum_size = Vector2(46, 0)
			sl.value_changed.connect(func(v: float):
				vl.text = _f(v)
				layers[idx][2][key] = v
				if key == "n" and (t == "H" or t == "V"):
					var cols2: Array = layers[idx][1]
					while cols2.size() < int(v):
						cols2.append(["#ffffff", "#c8102e", "#0b3d91", "#fcd116", "#009a44"][cols2.size() % 5])
					while cols2.size() > int(v):
						cols2.pop_back()
					_refresh()
					return
				_preview.spec = to_spec(layers)
				_preview.queue_redraw())
			hb.add_child(sl)
			hb.add_child(vl)
			box.add_child(hb)
		if t == "Y":
			var cur: String = String(l[2].get("icon", "star"))
			var syms: Array = _symbol_set()
			var grid := GridContainer.new()
			grid.columns = 5
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			for k in syms.size():
				var sname: String = syms[k][0]
				var bt := Button.new()
				bt.custom_minimum_size = Vector2(0, 76)
				bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				bt.tooltip_text = Loc.t(syms[k][1])
				TK.style_button(bt, "gold" if sname == cur else "ghost")
				var iv := TK.IconView.new()
				iv.icon = sname
				iv.color = Color(0.08, 0.08, 0.1) if sname == cur else Color(0.93, 0.93, 0.9)
				iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
				iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
				bt.add_child(iv)
				bt.pressed.connect(func():
					layers[idx][2]["icon"] = sname
					_preview.spec = to_spec(layers)
					_preview.queue_redraw()
					_refresh())
				grid.add_child(bt)
			box.add_child(grid)
		_list.add_child(box)
		_list.add_child(HSeparator.new())
