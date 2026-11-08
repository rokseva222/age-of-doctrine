extends RefCounted
## Kodla çizilen vektör ikonlar (24x24 ızgara). Hiçbir görsel dosya kullanılmaz.

const NAMES := ["coins", "sword", "swords", "shield", "news", "users", "globe", "menu", "play", "pause", "fast", "fast3", "x",
	"flag", "crown", "handshake", "skull", "star", "check", "plus", "minus", "info", "save", "folder", "search", "chev_l", "chev_r",
	"chev_d", "chev_u", "gear", "trophy", "target", "factory", "flame", "home", "lock", "trend", "hourglass", "anchor", "volume",
	"mute", "book", "map", "siren", "power", "refresh", "castle", "plane", "ship", "tank", "wheat", "bolt", "scroll",
	"rifle", "afv", "arty", "jet", "heli", "drone", "sub", "missile", "radar", "cyber", "med", "shield_star", "badge", "eye", "oil", "trade", "embassy", "sanction", "gavel", "briefcase"]


static func _tr(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x, y) * (r.size.x / 24.0)


static func _pts(r: Rect2, arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, arr.size(), 2):
		out.append(_tr(r, arr[i], arr[i + 1]))
	return out


static func _line(ci: CanvasItem, r: Rect2, arr: Array, col: Color, w: float, closed: bool = false) -> void:
	var p := _pts(r, arr)
	if closed:
		p.append(p[0])
	var ww := w * r.size.x / 24.0
	ci.draw_polyline(p, col, ww, true)
	# yuvarlak uçlar / köşeler
	var rad := ww * 0.5
	for q in p:
		ci.draw_circle(q, rad, col)


static func _fill(ci: CanvasItem, r: Rect2, arr: Array, col: Color) -> void:
	var p := _pts(r, arr)
	var tri := Geometry2D.triangulate_polygon(p)
	if tri.is_empty():
		return
	for i in range(0, tri.size(), 3):
		ci.draw_colored_polygon(PackedVector2Array([p[tri[i]], p[tri[i + 1]], p[tri[i + 2]]]), col)


static func _circle(ci: CanvasItem, r: Rect2, cx: float, cy: float, rad: float, col: Color, w: float, filled: bool = false) -> void:
	var c := _tr(r, cx, cy)
	var rr := rad * r.size.x / 24.0
	if filled:
		ci.draw_circle(c, rr, col)
	else:
		ci.draw_arc(c, rr, 0.0, TAU, 40, col, w * r.size.x / 24.0, true)


static func _arc(ci: CanvasItem, r: Rect2, cx: float, cy: float, rad: float, a0: float, a1: float, col: Color, w: float) -> void:
	var ww := w * r.size.x / 24.0
	var c := _tr(r, cx, cy)
	var rr := rad * r.size.x / 24.0
	ci.draw_arc(c, rr, deg_to_rad(a0), deg_to_rad(a1), 28, col, ww, true)
	for a in [a0, a1]:
		ci.draw_circle(c + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * rr, ww * 0.5, col)


static func _rect(ci: CanvasItem, r: Rect2, x: float, y: float, w: float, h: float, col: Color, sw: float, filled: bool = false, rad: float = 2.0) -> void:
	var s := r.size.x / 24.0
	var rect := Rect2(_tr(r, x, y), Vector2(w, h) * s)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(rad * s))
	sb.anti_aliasing = true
	if filled:
		sb.bg_color = col
	else:
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = col
		sb.set_border_width_all(maxi(1, int(round(sw * s))))
	ci.draw_style_box(sb, rect)


static func _star_pts(cx: float, cy: float, ro: float, ri: float, n: int = 5, rot: float = -90.0) -> Array:
	var out: Array = []
	for i in n * 2:
		var a := deg_to_rad(rot + i * 180.0 / n)
		var rr := ro if i % 2 == 0 else ri
		out.append(cx + cos(a) * rr)
		out.append(cy + sin(a) * rr)
	return out


static var _tex: Dictionary = {}


## assets/icons/<ad>.png (beyaz, şeffaf; renge boyanır) veya <ad>_c.png (renkli, boyanmaz) varsa kod çizimi yerine kullanılır
static func _texture(name: String) -> Array:
	if _tex.has(name):
		return _tex[name]
	var res: Array = [null, false]
	for suffix in ["", "_c"]:
		var path := "res://assets/icons/%s%s.png" % [name, suffix]
		if ResourceLoader.exists(path):
			res = [load(path), suffix == "_c"]
			break
	_tex[name] = res
	return res


## Yeni (Gemini) ikon dosyası geldiyse onu, gelmediyse yedek ikon adını döndürür.
static func pick(name: String, fallback: String) -> String:
	return name if _texture(name)[0] != null else fallback


static func draw(ci: CanvasItem, name: String, r: Rect2, col: Color, w: float = 2.2) -> void:
	var tx: Array = _texture(name)
	if tx[0] != null:
		ci.draw_texture_rect(tx[0], r, false, Color(1, 1, 1, col.a) if tx[1] else col)
		return
	_draw_code(ci, name, r, col, w)


static func _draw_code(ci: CanvasItem, name: String, r: Rect2, col: Color, w: float = 2.2) -> void:
	match name:
		"coins":
			_circle(ci, r, 12, 12, 8.5, col, w)
			_circle(ci, r, 12, 12, 4.6, col, w * 0.8)
			_line(ci, r, [12, 9.2, 12, 14.8], col, w * 0.8)
		"sword":
			_sword(ci, r, Vector2(19.5, 4.5), Vector2(5, 19), col, w)
		"swords":
			_sword(ci, r, Vector2(20, 4), Vector2(6, 18), col, w)
			_sword(ci, r, Vector2(4, 4), Vector2(18, 18), col, w)
		"shield":
			_line(ci, r, [12, 3, 20, 6, 20, 12.5, 12, 21, 4, 12.5, 4, 6], col, w, true)
		"news":
			_rect(ci, r, 3.5, 4.5, 17, 15, col, w)
			_line(ci, r, [7, 9, 17, 9], col, w * 0.9)
			_line(ci, r, [7, 13, 17, 13], col, w * 0.9)
			_line(ci, r, [7, 16.2, 12, 16.2], col, w * 0.9)
		"users":
			_circle(ci, r, 9, 8.5, 3.4, col, w)
			_arc(ci, r, 9, 20, 6.5, 180, 360, col, w)
			_circle(ci, r, 17, 9.5, 2.6, col, w * 0.9)
			_arc(ci, r, 17, 19, 4.4, 200, 340, col, w * 0.9)
		"globe":
			_circle(ci, r, 12, 12, 9, col, w)
			_line(ci, r, [3, 12, 21, 12], col, w * 0.8)
			var el: Array = []
			for i in 25:
				var a := TAU * i / 24.0
				el.append(12 + cos(a) * 4.2)
				el.append(12 + sin(a) * 9)
			_line(ci, r, el, col, w * 0.8, true)
		"menu":
			_line(ci, r, [4, 7, 20, 7], col, w)
			_line(ci, r, [4, 12, 20, 12], col, w)
			_line(ci, r, [4, 17, 20, 17], col, w)
		"play":
			_fill(ci, r, [7, 4.5, 19.5, 12, 7, 19.5], col)
		"pause":
			_rect(ci, r, 6, 5, 4.2, 14, col, w, true, 1.2)
			_rect(ci, r, 13.8, 5, 4.2, 14, col, w, true, 1.2)
		"fast":
			_fill(ci, r, [4, 5, 12, 12, 4, 19], col)
			_fill(ci, r, [12, 5, 20, 12, 12, 19], col)
		"fast3":
			_fill(ci, r, [2, 6, 8.5, 12, 2, 18], col)
			_fill(ci, r, [8.5, 6, 15, 12, 8.5, 18], col)
			_fill(ci, r, [15, 6, 21.5, 12, 15, 18], col)
		"x":
			_line(ci, r, [6, 6, 18, 18], col, w)
			_line(ci, r, [18, 6, 6, 18], col, w)
		"flag":
			_line(ci, r, [6, 3.5, 6, 21], col, w)
			_fill(ci, r, [6, 4.5, 19.5, 4.5, 15.5, 8.8, 19.5, 13, 6, 13], col)
		"crown":
			_line(ci, r, [3.5, 18.5, 4.8, 7.5, 9, 12, 12, 5, 15, 12, 19.2, 7.5, 20.5, 18.5], col, w, true)
		"handshake":
			_line(ci, r, [2.5, 10, 7, 6.5, 12, 8.5], col, w)
			_line(ci, r, [21.5, 10, 17, 6.5, 12, 8.5], col, w)
			_line(ci, r, [2.5, 10, 4.5, 14, 9, 18.5, 12, 18.2, 14.5, 15.5], col, w)
			_line(ci, r, [21.5, 10, 19.5, 14, 15, 18.5, 12, 18.2], col, w)
			_line(ci, r, [9, 12, 12.5, 15, 15, 12, 12, 8.5], col, w)
		"skull":
			_arc(ci, r, 12, 10.5, 7.5, 150, 390, col, w)
			_line(ci, r, [5.9, 14.2, 7.5, 15.5, 7.5, 19, 16.5, 19, 16.5, 15.5, 18.1, 14.2], col, w)
			_circle(ci, r, 9, 11, 1.9, col, w, true)
			_circle(ci, r, 15, 11, 1.9, col, w, true)
			_line(ci, r, [10.8, 19, 10.8, 16.6], col, w * 0.7)
			_line(ci, r, [13.2, 19, 13.2, 16.6], col, w * 0.7)
		"star":
			_line(ci, r, _star_pts(12, 12.5, 9, 4, 5), col, w, true)
		"check":
			_line(ci, r, [5, 12.5, 10, 17.5, 19, 7], col, w * 1.15)
		"plus":
			_line(ci, r, [12, 5, 12, 19], col, w)
			_line(ci, r, [5, 12, 19, 12], col, w)
		"minus":
			_line(ci, r, [5, 12, 19, 12], col, w)
		"info":
			_circle(ci, r, 12, 12, 9, col, w)
			_line(ci, r, [12, 11, 12, 16.5], col, w)
			_circle(ci, r, 12, 7.8, 1.2, col, w, true)
		"save":
			_line(ci, r, [4.5, 4.5, 16.5, 4.5, 19.5, 7.5, 19.5, 19.5, 4.5, 19.5], col, w, true)
			_line(ci, r, [8, 4.5, 8, 9, 15, 9, 15, 4.5], col, w * 0.9)
			_line(ci, r, [8, 19.5, 8, 14, 16, 14, 16, 19.5], col, w * 0.9)
		"folder":
			_line(ci, r, [3, 6.5, 9, 6.5, 11, 9, 20.5, 9, 20.5, 19, 3, 19], col, w, true)
		"search":
			_circle(ci, r, 10.5, 10.5, 6.6, col, w)
			_line(ci, r, [15.5, 15.5, 20.5, 20.5], col, w * 1.1)
		"chev_l":
			_line(ci, r, [14.5, 5.5, 8, 12, 14.5, 18.5], col, w * 1.1)
		"chev_r":
			_line(ci, r, [9.5, 5.5, 16, 12, 9.5, 18.5], col, w * 1.1)
		"chev_d":
			_line(ci, r, [5.5, 9, 12, 15.5, 18.5, 9], col, w * 1.1)
		"chev_u":
			_line(ci, r, [5.5, 15, 12, 8.5, 18.5, 15], col, w * 1.1)
		"gear":
			var g: Array = []
			for i in 16:
				var a := TAU * i / 16.0
				var rr := 9.3 if (i % 2 == 0) else 7.3
				g.append(12 + cos(a) * rr)
				g.append(12 + sin(a) * rr)
			_line(ci, r, g, col, w * 0.9, true)
			_circle(ci, r, 12, 12, 3, col, w)
		"trophy":
			_line(ci, r, [7, 4, 17, 4, 17, 10, 12, 14.5, 7, 10], col, w, true)
			_line(ci, r, [7, 6, 3.8, 6, 4.5, 10, 7.5, 11.5], col, w * 0.9)
			_line(ci, r, [17, 6, 20.2, 6, 19.5, 10, 16.5, 11.5], col, w * 0.9)
			_line(ci, r, [12, 14.5, 12, 18.5], col, w)
			_line(ci, r, [8, 20, 16, 20], col, w)
		"target":
			_circle(ci, r, 12, 12, 9, col, w)
			_circle(ci, r, 12, 12, 5, col, w)
			_circle(ci, r, 12, 12, 1.5, col, w, true)
		"factory":
			_line(ci, r, [3.5, 20, 3.5, 11, 9, 14, 9, 8.5, 14.5, 12, 14.5, 7, 20.5, 7, 20.5, 20], col, w, true)
		"flame":
			_line(ci, r, [12, 3, 17.5, 9.5, 18, 14.5, 15, 19.5, 12, 20.5, 9, 19.5, 6, 14.5, 7, 10.5, 9.5, 12.5, 10, 8], col, w, true)
		"home":
			_line(ci, r, [3.5, 11.5, 12, 4, 20.5, 11.5], col, w)
			_line(ci, r, [6, 10, 6, 20, 18, 20, 18, 10], col, w)
			_line(ci, r, [10, 20, 10, 14.5, 14, 14.5, 14, 20], col, w * 0.9)
		"lock":
			_rect(ci, r, 5, 10.5, 14, 10, col, w)
			_arc(ci, r, 12, 10.5, 4.6, 180, 360, col, w)
			_circle(ci, r, 12, 15.5, 1.3, col, w, true)
		"trend":
			_line(ci, r, [3.5, 17, 9, 11.5, 13, 15, 20.5, 6.5], col, w)
			_line(ci, r, [15, 6.5, 20.5, 6.5, 20.5, 12], col, w)
		"hourglass":
			_line(ci, r, [6, 3.5, 18, 3.5, 18, 7, 12, 12, 18, 17, 18, 20.5, 6, 20.5, 6, 17, 12, 12, 6, 7], col, w, true)
		"anchor":
			_circle(ci, r, 12, 5.5, 2.3, col, w)
			_line(ci, r, [12, 8, 12, 20.5], col, w)
			_line(ci, r, [8, 11.5, 16, 11.5], col, w)
			_arc(ci, r, 12, 14, 8, 20, 160, col, w)
		"volume":
			_line(ci, r, [4, 9.5, 8, 9.5, 12.5, 5.5, 12.5, 18.5, 8, 14.5, 4, 14.5], col, w, true)
			_arc(ci, r, 12.5, 12, 4.5, -45, 45, col, w)
			_arc(ci, r, 12.5, 12, 8, -45, 45, col, w)
		"mute":
			_line(ci, r, [4, 9.5, 8, 9.5, 12.5, 5.5, 12.5, 18.5, 8, 14.5, 4, 14.5], col, w, true)
			_line(ci, r, [16.5, 9.5, 21.5, 14.5], col, w)
			_line(ci, r, [21.5, 9.5, 16.5, 14.5], col, w)
		"book":
			_line(ci, r, [12, 6.5, 12, 20, 4, 18, 4, 4.5, 12, 6.5, 20, 4.5, 20, 18, 12, 20], col, w, true)
		"map":
			_line(ci, r, [3.5, 6, 9, 4, 15, 6.5, 20.5, 4.5, 20.5, 18, 15, 20, 9, 17.5, 3.5, 19.5], col, w, true)
			_line(ci, r, [9, 4, 9, 17.5], col, w * 0.8)
			_line(ci, r, [15, 6.5, 15, 20], col, w * 0.8)
		"siren":
			_arc(ci, r, 12, 16, 6, 180, 360, col, w)
			_line(ci, r, [6, 16, 6, 19.5, 18, 19.5, 18, 16], col, w)
			_line(ci, r, [12, 3, 12, 5], col, w)
			_line(ci, r, [4.5, 6.5, 6, 8], col, w)
			_line(ci, r, [19.5, 6.5, 18, 8], col, w)
		"power":
			_arc(ci, r, 12, 13, 7.5, -55, 235, col, w)
			_line(ci, r, [12, 3.5, 12, 11.5], col, w)
		"refresh":
			_arc(ci, r, 12, 12, 7.5, -40, 250, col, w)
			_line(ci, r, [17.2, 3.5, 17.8, 8, 13.5, 8.6], col, w)
		"castle":
			_line(ci, r, [4, 20, 4, 8, 7, 8, 7, 10, 9.5, 10, 9.5, 8, 14.5, 8, 14.5, 10, 17, 10, 17, 8, 20, 8, 20, 20], col, w, true)
			_line(ci, r, [10, 20, 10, 15, 14, 15, 14, 20], col, w * 0.9)
		"plane":
			_line(ci, r, [3, 13, 21, 4, 15, 20, 12.5, 14, 3, 13], col, w, true)
			_line(ci, r, [21, 4, 12.5, 14], col, w * 0.8)
		"ship":
			_line(ci, r, [3, 14.5, 21, 14.5, 18, 20, 6, 20], col, w, true)
			_line(ci, r, [12, 4, 12, 14.5], col, w)
			_fill(ci, r, [12.8, 5, 18, 12.5, 12.8, 12.5], col)
		"tank":
			_rect(ci, r, 3.5, 12.5, 17, 6.5, col, w, false, 3.2)
			_rect(ci, r, 8, 8, 8, 4.5, col, w, false, 1.5)
			_line(ci, r, [16, 10, 21.5, 10], col, w)
		"wheat":
			_line(ci, r, [12, 21, 12, 5], col, w)
			for i in 3:
				var y := 9.0 + i * 3.8
				_line(ci, r, [12, y + 2, 7.5, y - 1.5], col, w * 0.9)
				_line(ci, r, [12, y + 2, 16.5, y - 1.5], col, w * 0.9)
		"bolt":
			_line(ci, r, [13.5, 3, 6, 13.5, 11.5, 13.5, 10.5, 21, 18, 10, 12.5, 10], col, w * 0.9, true)
		"scroll":
			_line(ci, r, [7, 4.5, 18, 4.5, 18, 17.5, 7, 17.5], col, w)
			_arc(ci, r, 7, 19, 2.5, -90, 90, col, w)
			_line(ci, r, [10.5, 9, 15, 9], col, w * 0.9)
			_line(ci, r, [10.5, 12.5, 15, 12.5], col, w * 0.9)
		"rifle":
			_line(ci, r, [2.5, 16, 5, 11.5, 13, 11.5, 13, 14, 8.5, 14, 7, 17], col, w * 0.9, true)
			_line(ci, r, [13, 12.6, 22, 12.6], col, w)
			_line(ci, r, [15.5, 10.2, 15.5, 11.5], col, w * 0.8)
			_line(ci, r, [10.5, 14, 9.6, 19.5], col, w)
		"afv":
			_line(ci, r, [3, 16, 4.5, 10.5, 15.5, 10.5, 21, 14, 21, 16], col, w, true)
			for cx in [7.0, 12.0, 17.0]:
				_circle(ci, r, cx, 17.6, 2.2, col, w * 0.9)
			_line(ci, r, [9.5, 10.5, 10.5, 7.5, 15, 7.5, 15, 10.5], col, w * 0.9)
		"arty":
			_line(ci, r, [5, 15, 19.5, 5.5], col, w * 1.6)
			_circle(ci, r, 8.5, 17, 3.6, col, w)
			_line(ci, r, [3, 20.5, 15, 20.5], col, w)
		"jet":
			_line(ci, r, [12, 2.5, 13.8, 9, 21.5, 14.5, 21.5, 16.5, 13.8, 14.5, 13, 19.5, 16, 21, 16, 22, 12, 21, 8, 22, 8, 21, 11, 19.5, 10.2, 14.5, 2.5, 16.5, 2.5, 14.5, 10.2, 9], col, w * 0.85, true)
		"heli":
			_line(ci, r, [3, 5, 21, 5], col, w)
			_line(ci, r, [12, 5, 12, 8], col, w)
			_rect(ci, r, 5.5, 8, 10.5, 7, col, w, false, 3.5)
			_line(ci, r, [16, 10.5, 21.5, 8.5], col, w)
			_line(ci, r, [6.5, 18, 16.5, 18], col, w)
			_line(ci, r, [8, 15, 8, 18], col, w * 0.8)
			_line(ci, r, [14, 15, 14, 18], col, w * 0.8)
		"drone":
			_line(ci, r, [2.5, 11.5, 12, 9.5, 21.5, 11.5], col, w)
			_line(ci, r, [12, 9.5, 12, 18], col, w * 1.3)
			_line(ci, r, [9.5, 18.5, 12, 16.5, 14.5, 18.5], col, w)
			_circle(ci, r, 12, 9.5, 1.6, col, w, true)
		"sub":
			_rect(ci, r, 2.5, 11, 19, 6.5, col, w, false, 3.2)
			_rect(ci, r, 9.5, 7.2, 5, 3.8, col, w * 0.9, false, 1.2)
			_line(ci, r, [13, 7.2, 13, 4, 16, 4], col, w * 0.9)
			_line(ci, r, [20, 11, 22, 9.5], col, w * 0.9)
			_line(ci, r, [20, 17.5, 22, 19], col, w * 0.9)
		"missile":
			_line(ci, r, [10, 7, 10, 17, 14, 17, 14, 7, 12, 2.5], col, w * 0.9, true)
			_line(ci, r, [10, 14, 7, 19, 10, 17.4], col, w * 0.9)
			_line(ci, r, [14, 14, 17, 19, 14, 17.4], col, w * 0.9)
			_line(ci, r, [12, 18.5, 12, 22], col, w)
		"radar":
			_arc(ci, r, 12, 12.5, 8, 195, 345, col, w)
			_line(ci, r, [12, 12.5, 12, 20], col, w)
			_line(ci, r, [8, 20.5, 16, 20.5], col, w)
			_arc(ci, r, 12, 12.5, 4.2, 215, 325, col, w * 0.8)
		"cyber":
			_rect(ci, r, 3, 4.5, 18, 12, col, w, false, 2.0)
			_line(ci, r, [9.5, 8, 7, 10.5, 9.5, 13], col, w * 0.9)
			_line(ci, r, [14.5, 8, 17, 10.5, 14.5, 13], col, w * 0.9)
			_line(ci, r, [12.8, 7.5, 11.2, 13.5], col, w * 0.8)
			_line(ci, r, [12, 16.5, 12, 19.5], col, w)
			_line(ci, r, [8, 19.5, 16, 19.5], col, w)
		"med":
			_line(ci, r, [9, 3.5, 15, 3.5, 15, 9, 20.5, 9, 20.5, 15, 15, 15, 15, 20.5, 9, 20.5, 9, 15, 3.5, 15, 3.5, 9, 9, 9], col, w, true)
		"shield_star":
			_line(ci, r, [12, 2.5, 20, 5.5, 20, 12.5, 12, 21.5, 4, 12.5, 4, 5.5], col, w, true)
			_fill(ci, r, _star_pts(12, 11.5, 4.6, 1.9), col)
		"badge":
			_circle(ci, r, 12, 12, 9, col, w)
			_fill(ci, r, _star_pts(12, 12.2, 5.4, 2.3, 6), col)
		"eye":
			_line(ci, r, [2.5, 12, 7, 7, 12, 5.5, 17, 7, 21.5, 12, 17, 17, 12, 18.5, 7, 17], col, w * 0.9, true)
			_circle(ci, r, 12, 12, 3.2, col, w)
			_circle(ci, r, 12, 12, 1.1, col, w, true)
		"oil":
			_line(ci, r, [12, 3, 17.5, 11, 18.5, 15, 16.5, 19.5, 12, 21, 7.5, 19.5, 5.5, 15, 6.5, 11], col, w * 0.95, true)
			_line(ci, r, [9, 15.5, 10, 17.5], col, w * 0.8)
		"trade":
			_line(ci, r, [4, 9, 19, 9], col, w)
			_line(ci, r, [15.5, 5.5, 19.5, 9, 15.5, 12.5], col, w)
			_line(ci, r, [20, 15.5, 5, 15.5], col, w)
			_line(ci, r, [8.5, 12, 4.5, 15.5, 8.5, 19], col, w)
		"embassy":
			_line(ci, r, [3, 20.5, 21, 20.5], col, w)
			_line(ci, r, [3.5, 10.5, 12, 6, 20.5, 10.5], col, w, true)
			for cx2 in [7.0, 12.0, 17.0]:
				_line(ci, r, [cx2, 11.5, cx2, 19.5], col, w)
			_line(ci, r, [12, 6, 12, 2.5, 16.5, 3.8, 12, 5], col, w * 0.8)
		"sanction":
			_circle(ci, r, 12, 12, 8.5, col, w)
			_line(ci, r, [6, 6, 18, 18], col, w)
		"gavel":
			_line(ci, r, [4, 20.5, 14, 20.5], col, w)
			_line(ci, r, [9.5, 6, 15, 11.5], col, w * 1.8)
			_line(ci, r, [13, 4, 18.5, 9.5], col, w * 1.8)
			_line(ci, r, [13, 12, 19.5, 18.5], col, w)
		"briefcase":
			_rect(ci, r, 3, 8, 18, 12, col, w, false, 2.0)
			_line(ci, r, [9, 8, 9, 5.5, 15, 5.5, 15, 8], col, w)
			_line(ci, r, [3, 13.5, 21, 13.5], col, w * 0.8)
		_:
			_circle(ci, r, 12, 12, 8, col, w)


static func _sword(ci: CanvasItem, r: Rect2, tip: Vector2, hilt: Vector2, col: Color, w: float) -> void:
	var dir := (tip - hilt).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	var guard := hilt + (tip - hilt) * 0.28
	_line(ci, r, [hilt.x, hilt.y, tip.x, tip.y], col, w)
	_line(ci, r, [guard.x - nrm.x * 3.2, guard.y - nrm.y * 3.2, guard.x + nrm.x * 3.2, guard.y + nrm.y * 3.2], col, w)
	_circle(ci, r, hilt.x - dir.x * 1.2, hilt.y - dir.y * 1.2, 1.1, col, w, true)
