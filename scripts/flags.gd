extends RefCounted
## Bayrak çizici: flag_db.gd'deki kısa tanımları vektör olarak çizer (görsel dosya yok).

const DB = preload("res://scripts/flag_db.gd")

const COL := {
	"w": "ffffff", "k": "141414", "r": "ce1126", "b": "0b3d91", "n": "002b7f", "l": "5bb5e8", "g": "009a44",
	"y": "fcd116", "o": "ff8200", "p": "6a1b9a", "m": "8a1538", "c": "00a3a3", "e": "9a9a9a", "t": "d4a017", "u": "7a4a21",
}
const ASPECT := 1.5

static var _cache: Dictionary = {}
static var era_specs: Dictionary = {}      # name_en -> flag_db kısa tanımı (tarihî dönem bayrakları)


static var _tex: Dictionary = {}           # iso -> Texture2D (gerçek bayrak görselleri; yoksa kodla çizilir)


## Gerçek ülke bayrağı görseli (assets/flags, flag-icons, MIT). Tarihî dönem ve isyancı bayrakları kodla çizilir.
static func _texture_for(c):
	if c.is_rebel or (not era_specs.is_empty() and era_specs.has(c.name_en)):
		return null
	var k: String = _key(c).to_lower()
	if k.length() != 2:
		return null
	if _tex.has(k):
		return _tex[k]
	var t = null
	var path := "res://assets/flags/%s.png" % k
	if ResourceLoader.exists(path):
		t = load(path)
	_tex[k] = t
	return t


static func set_era_specs(d: Dictionary) -> void:
	era_specs = d
	_cache.clear()


static func _color(s: String) -> Color:
	s = s.strip_edges()
	if s.begins_with("#"):
		return Color.html(s)
	if COL.has(s):
		return Color.html("#" + COL[s])
	return Color.MAGENTA


static func _key(c) -> String:
	if c.is_rebel:
		return "~" + c.name
	var k: String = c.iso
	if k == "" or k == "-99":
		k = c.a3
	return k


static func _parse(spec: String) -> Array:
	var layers: Array = []
	for part in spec.split("|", false):
		var idx := part.find(":")
		if idx < 0:
			continue
		var t := part.substr(0, idx)
		var args: PackedStringArray = part.substr(idx + 1).split(",", false)
		match t:
			"H", "V":
				var cols: Array = []
				var ws: Array = []
				var tot := 0.0
				for a in args:
					var cw := a.split("*")
					cols.append(_color(cw[0]))
					var wv := float(cw[1]) if cw.size() > 1 else 1.0
					ws.append(wv)
					tot += wv
				layers.append({"t": t, "cols": cols, "ws": ws, "tot": tot})
			"R":
				layers.append({"t": "R", "r": Rect2(float(args[0]), float(args[1]), float(args[2]) - float(args[0]), float(args[3]) - float(args[1])), "col": _color(args[4])})
			"C":
				layers.append({"t": "C", "p": Vector2(float(args[0]), float(args[1])), "r": float(args[2]), "col": _color(args[3])})
			"S":
				var n := int(args[4]) if args.size() > 4 else 5
				var rot := float(args[5]) if args.size() > 5 else -90.0
				layers.append({"t": "S", "p": Vector2(float(args[0]), float(args[1])), "r": float(args[2]), "col": _color(args[3]), "n": n, "rot": rot})
			"P":
				var pts := PackedVector2Array()
				for i in range(1, args.size() - 1, 2):
					pts.append(Vector2(float(args[i]), float(args[i + 1])))
				layers.append({"t": "P", "polys": _clip_poly(pts), "col": _color(args[0])})
			"L":
				var w := float(args[1])
				var a := Vector2(float(args[2]), float(args[3]))
				var b := Vector2(float(args[4]), float(args[5]))
				layers.append({"t": "P", "polys": _clip_poly(_line_poly(a, b, w)), "col": _color(args[0])})
			"K":
				var w2 := float(args[1])
				var cx := float(args[2])
				var cy := float(args[3])
				var v := _clip_poly(_line_poly(Vector2(cx, -0.5), Vector2(cx, 1.5), w2))
				var h := _clip_poly(_line_poly(Vector2(-0.5, cy), Vector2(1.5, cy), w2))
				layers.append({"t": "P", "polys": v + h, "col": _color(args[0])})
			"O":
				layers.append({"t": "O", "w": float(args[1]), "p": Vector2(float(args[2]), float(args[3])), "r": float(args[4]), "col": _color(args[0])})
			"G":
				layers.append({"t": "G", "r": Rect2(float(args[0]), float(args[1]), float(args[2]) - float(args[0]), float(args[3]) - float(args[1])), "cols": int(args[4]), "rows": int(args[5]), "sr": float(args[6]), "col": _color(args[7])})
			"UJ":
				layers.append({"t": "UJ", "r": Rect2(float(args[0]), float(args[1]), float(args[2]) - float(args[0]), float(args[3]) - float(args[1]))})
	return layers


## Kalın çizgiyi (bayrak oranında) çokgene çevirir; koordinatlar yine 0..1.
static func _line_poly(a: Vector2, b: Vector2, w: float) -> PackedVector2Array:
	var pa := Vector2(a.x * ASPECT, a.y)
	var pb := Vector2(b.x * ASPECT, b.y)
	var d := (pb - pa)
	var n := Vector2(-d.y, d.x).normalized() * (w * 0.5)
	var ext := d.normalized() * 0.0
	var q := [pa - n - ext, pb - n + ext, pb + n + ext, pa + n - ext]
	var out := PackedVector2Array()
	for v in q:
		out.append(Vector2(v.x / ASPECT, v.y))
	return out


static func _clip_poly(pts: PackedVector2Array) -> Array:
	var sq := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	if pts.size() < 3:
		return []
	var res := Geometry2D.intersect_polygons(pts, sq)
	var out: Array = []
	for r in res:
		if Geometry2D.is_polygon_clockwise(r) == false or true:
			out.append(r)
	return out


static func _generated(c) -> Array:
	var h: int = absi(hash(_key(c)))
	var base: Color = c.color
	var dark := base.darkened(0.5)
	var light := base.lightened(0.55)
	var layers: Array = []
	match h % 4:
		0:
			layers.append({"t": "H", "cols": [base, light, dark], "ws": [1.0, 1.0, 1.0], "tot": 3.0})
		1:
			layers.append({"t": "V", "cols": [dark, base, dark], "ws": [1.0, 2.0, 1.0], "tot": 4.0})
		2:
			layers.append({"t": "R", "r": Rect2(0, 0, 1, 1), "col": base})
			layers.append({"t": "P", "polys": _clip_poly(_line_poly(Vector2(0, 1), Vector2(1, 0), 0.5)), "col": dark})
		_:
			layers.append({"t": "R", "r": Rect2(0, 0, 1, 1), "col": dark})
			layers.append({"t": "C", "p": Vector2(0.5, 0.5), "r": 0.3, "col": base})
	if c.is_rebel:
		layers = [{"t": "R", "r": Rect2(0, 0, 1, 1), "col": Color(0.09, 0.09, 0.11)},
			{"t": "S", "p": Vector2(0.5, 0.5), "r": 0.3, "col": Color(0.85, 0.15, 0.2), "n": 5, "rot": -90.0}]
	else:
		layers.append({"t": "S", "p": Vector2(0.5, 0.5), "r": 0.2, "col": Color(1, 1, 1, 0.9), "n": 5, "rot": -90.0})
	return layers


static func layers_for(c) -> Array:
	if not era_specs.is_empty() and era_specs.has(c.name_en) and not c.is_rebel:
		var ek: String = "E:" + c.name_en
		if not _cache.has(ek):
			_cache[ek] = _parse(era_specs[c.name_en])
		return _cache[ek]
	var k := _key(c)
	if _cache.has(k):
		return _cache[k]
	var layers: Array
	if DB.FLAGS.has(k) and not c.is_rebel:
		layers = _parse(DB.FLAGS[k])
	else:
		layers = _generated(c)
	_cache[k] = layers
	return layers


static func _star(center: Vector2, r: float, n: int, rot_deg: float) -> PackedVector2Array:
	var ri := r * (0.382 if n <= 5 else (0.577 if n == 6 else 0.62))
	var out := PackedVector2Array()
	for i in n * 2:
		var a := deg_to_rad(rot_deg + i * 180.0 / n)
		var rr := r if i % 2 == 0 else ri
		out.append(center + Vector2(cos(a), sin(a)) * rr)
	return out


## Bayrağı rect içine çizer.
static func draw(ci: CanvasItem, rect: Rect2, c, _radius: float = 0.0) -> void:
	var tex = _texture_for(c)
	if tex != null:
		ci.draw_texture_rect(tex, rect, false)
	else:
		_draw_layers(ci, rect, layers_for(c))
	ci.draw_rect(rect, Color(0, 0, 0, 0.45), false, 1.0)
	ci.draw_rect(rect.grow(-1.0), Color(1, 1, 1, 0.12), false, 1.0)


static func _draw_layers(ci: CanvasItem, rect: Rect2, layers: Array) -> void:
	var o := rect.position
	var sz := rect.size
	for L in layers:
		match L.t:
			"H":
				var y := 0.0
				for i in L.cols.size():
					var hh: float = L.ws[i] / L.tot
					var r := Rect2(o.x, o.y + y * sz.y, sz.x, hh * sz.y + 0.6)
					ci.draw_rect(r, L.cols[i])
					y += hh
			"V":
				var x := 0.0
				for i in L.cols.size():
					var ww: float = L.ws[i] / L.tot
					var r2 := Rect2(o.x + x * sz.x, o.y, ww * sz.x + 0.6, sz.y)
					ci.draw_rect(r2, L.cols[i])
					x += ww
			"R":
				var rr: Rect2 = L.r
				ci.draw_rect(Rect2(o + rr.position * sz, rr.size * sz), L.col)
			"C":
				ci.draw_circle(o + L.p * sz, L.r * sz.y, L.col)
			"O":
				ci.draw_arc(o + L.p * sz, L.r * sz.y, 0.0, TAU, 36, L.col, maxf(L.w * sz.y, 1.0), true)
			"S":
				var star := _star(o + L.p * sz, L.r * sz.y, L.n, L.rot)
				ci.draw_colored_polygon(star, L.col)
			"P":
				for poly in L.polys:
					var pts := PackedVector2Array()
					for v in poly:
						pts.append(o + v * sz)
					if pts.size() >= 3:
						ci.draw_colored_polygon(pts, L.col)
			"G":
				var gr: Rect2 = L.r
				for iy in L.rows:
					for ix in L.cols:
						var fx: float = (ix + 0.5) / L.cols
						var fy: float = (iy + 0.5) / L.rows
						var p := Vector2(gr.position.x + gr.size.x * fx, gr.position.y + gr.size.y * fy)
						ci.draw_colored_polygon(_star(o + p * sz, L.sr * sz.y, 5, -90.0), L.col)
			"UJ":
				_draw_uj(ci, Rect2(o + L.r.position * sz, L.r.size * sz))


static func _draw_uj(ci: CanvasItem, r: Rect2) -> void:
	var blue := Color("#012169")
	var red := Color("#c8102e")
	ci.draw_rect(r, blue)
	var tl := r.position
	var br := r.end
	var tr := Vector2(br.x, tl.y)
	var bl := Vector2(tl.x, br.y)
	var u := minf(r.size.x / 1.5, r.size.y) # birim: yükseklik
	# beyaz çaprazlar (kırpma: dikdörtgen içinde)
	var wdt := u * 0.18
	_clipped_line(ci, r, tl, br, wdt, Color.WHITE)
	_clipped_line(ci, r, tr, bl, wdt, Color.WHITE)
	_clipped_line(ci, r, tl, br, wdt * 0.4, red)
	_clipped_line(ci, r, tr, bl, wdt * 0.4, red)
	var c := r.get_center()
	ci.draw_rect(Rect2(c.x - u * 0.2, r.position.y, u * 0.4, r.size.y), Color.WHITE)
	ci.draw_rect(Rect2(r.position.x, c.y - u * 0.2, r.size.x, u * 0.4), Color.WHITE)
	ci.draw_rect(Rect2(c.x - u * 0.12, r.position.y, u * 0.24, r.size.y), red)
	ci.draw_rect(Rect2(r.position.x, c.y - u * 0.12, r.size.x, u * 0.24), red)


static func _clipped_line(ci: CanvasItem, r: Rect2, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * (w * 0.5)
	var poly := PackedVector2Array([a - n, b - n, b + n, a + n])
	var rp := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for q in Geometry2D.intersect_polygons(poly, rp):
		ci.draw_colored_polygon(q, col)
