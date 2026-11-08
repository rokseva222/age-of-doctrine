extends Control
## Yüzsüz siluet portre (kodla çizilir). Yüz özelliği yok: bölgeyi başlık/kıyafet ve renk paleti anlatır.
##   us: takım elbise + kırmızı kravat      eu: takım elbise + mavi kravat
##   ru: kürk kulaklıklı şapka (ushanka)    me: ghutra + agal (Orta Doğu başlığı)
##   asia: dik yakalı (mandarin) ceket       sa: Güney Asya, yakalı ceket + kasket
##   af: takım elbise + desenli fular
## Rol: def (kasket + apolet), for/int/fin/hlt/spy (köşe rozetinde ikon).

const TK = preload("res://scripts/theme_kit.gd")
const Icons = preload("res://scripts/icons.gd")

const ROLE_ICON := {"def": "shield_star", "for": "globe", "int": "badge", "fin": "coins", "hlt": "med", "spy": "eye", "amb": "embassy", "pm": "crown", "trd": "money_bag", "spt": "trophy", "ele": "ballot"}

var style := "eu"
var culture := ""                         # "west","slav","turk","gulf","lev","pers","sasia","easia","seasia","afr","latam","pac"
var seed_name := ""                       # aynı isim -> aynı varyant
var female := false
var role := "for"
var tint := Color(0.35, 0.4, 0.5)
var anim := 0.0

const INK := Color(0.055, 0.062, 0.08)
const HAIR := Color(0.15, 0.16, 0.2)
const PAPER := Color(0.86, 0.84, 0.77)


const CULTURES := ["west", "slav", "turk", "gulf", "lev", "pers", "sasia", "easia", "seasia", "afr", "latam", "pac"]
const W_SET := ["United States of America", "Canada", "United Kingdom", "Ireland", "Australia", "New Zealand", "Germany", "Austria", "Switzerland", "Liechtenstein", "Luxembourg",
	"Netherlands", "Belgium", "France", "Monaco", "Italy", "San Marino", "Malta", "Spain", "Andorra", "Portugal", "Greece", "Cyprus", "N. Cyprus", "Israel", "Turkey",
	"Japan", "South Korea", "Czechia", "Slovakia", "Hungary", "Romania", "Bulgaria", "Serbia", "Croatia", "Bosnia and Herz.", "Montenegro", "Slovenia", "North Macedonia",
	"Kosovo", "Albania", "Georgia", "Armenia", "Greenland", "Iceland"]
const SLAV_SET := ["Russia", "Belarus", "Ukraine", "Moldova", "Poland", "Estonia", "Latvia", "Lithuania", "Sweden", "Norway", "Denmark", "Finland"]
const TURK_SET := ["Azerbaijan", "Kazakhstan", "Uzbekistan", "Kyrgyzstan", "Turkmenistan"]
const GULF_SET := ["Saudi Arabia", "United Arab Emirates", "Qatar", "Kuwait", "Bahrain", "Oman", "Yemen"]
const LEV_SET := ["Egypt", "Syria", "Lebanon", "Jordan", "Iraq", "Palestine", "Libya", "Tunisia", "Algeria", "Morocco", "Sudan", "W. Sahara", "Mauritania"]
const PERS_SET := ["Iran", "Afghanistan", "Pakistan", "Tajikistan"]
const SASIA_SET := ["India", "Bangladesh", "Sri Lanka", "Nepal", "Bhutan", "Maldives"]
const EASIA_SET := ["China", "Mongolia", "Taiwan", "North Korea", "Singapore"]
const SEASIA_SET := ["Indonesia", "Malaysia", "Brunei", "Thailand", "Laos", "Cambodia", "Myanmar", "Vietnam", "Philippines", "Timor-Leste"]


## Ülkenin portre kültürü (12 gruptan biri). Doku yoksa çağıran eski kod çizimine döner.
static func culture_for(c) -> String:
	var n: String = c.name_en
	if n in W_SET: return "west"
	if n in SLAV_SET: return "slav"
	if n in TURK_SET: return "turk"
	if n in GULF_SET: return "gulf"
	if n in LEV_SET: return "lev"
	if n in PERS_SET: return "pers"
	if n in SASIA_SET: return "sasia"
	if n in EASIA_SET: return "easia"
	if n in SEASIA_SET: return "seasia"
	match str(c.continent):
		"Africa": return "afr"
		"Oceania": return "pac"
		"South America", "North America": return "latam"
		"Asia": return "sasia"
	return "west"


static func _count(culture: String, kind: String) -> int:
	var n := 0
	while n < 6 and Icons._texture("pt_%s_%s%d" % [culture, kind, n + 1])[0] != null:
		n += 1
	return n


func _portrait_tex() -> Texture2D:
	if culture == "":
		return null
	var kind := "o" if role == "def" else ("f" if female else "m")
	var cnt := _count(culture, kind)
	if cnt == 0:
		return null
	var v: int = absi(hash(seed_name + role)) % cnt + 1
	return Icons._texture("pt_%s_%s%d" % [culture, kind, v])[0]


static func style_for(c) -> String:
	var n: String = c.name_en
	if n in ["United States of America"]:
		return "us"
	if n in ["Russia", "Belarus"]:
		return "ru"
	if n in ["China", "Japan", "South Korea", "North Korea", "Taiwan", "Vietnam", "Mongolia", "Thailand", "Laos", "Cambodia", "Myanmar", "Singapore", "Philippines", "Brunei", "Timor-Leste"]:
		return "asia"
	if n in ["India", "Pakistan", "Bangladesh", "Sri Lanka", "Nepal", "Bhutan", "Maldives", "Indonesia", "Malaysia", "Afghanistan"]:
		return "sa"
	if n in ["Iran", "Iraq", "Syria", "Saudi Arabia", "United Arab Emirates", "Qatar", "Kuwait", "Bahrain", "Oman", "Yemen", "Jordan", "Lebanon", "Egypt", "Libya", "Tunisia", "Algeria", "Morocco", "Palestine", "Sudan", "Somalia", "N. Cyprus"]:
		return "me"
	if c.continent == "Africa":
		return "af"
	return "eu"


func _ell(cx: float, cy: float, rx: float, ry: float, n: int = 40) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return out


func _poly(pts: Array, col: Color) -> void:
	var p := PackedVector2Array()
	for q in pts:
		p.append(_t(q))
	if Geometry2D.triangulate_polygon(p).is_empty():
		return
	draw_colored_polygon(p, col)


func _poly_p(p: PackedVector2Array, col: Color) -> void:
	var q := PackedVector2Array()
	for v in p:
		q.append(_t(v))
	if Geometry2D.triangulate_polygon(q).is_empty():
		return
	draw_colored_polygon(q, col)


var _s := 1.0
var _o := Vector2.ZERO


func _t(v) -> Vector2:
	return _o + Vector2(v[0], v[1]) * _s if v is Array else _o + (v as Vector2) * _s


func _mirror(pts: Array) -> Array:
	var out: Array = []
	for i in range(pts.size() - 1, -1, -1):
		out.append([100.0 - pts[i][0], pts[i][1]])
	return out


func _draw() -> void:
	_s = minf(size.x / 100.0, size.y / 120.0)
	_o = Vector2((size.x - 100.0 * _s) * 0.5, (size.y - 120.0 * _s) * 0.5)
	# arka plan: ülke rengi, koyu; merkezde yumuşak ışık
	draw_rect(Rect2(Vector2.ZERO, size), tint.darkened(0.55))
	for k in 5:
		var r := 62.0 - k * 9.0
		draw_circle(_t(Vector2(50, 52)), r * _s, Color(tint.r, tint.g, tint.b, 0.10 + k * 0.035))
	# ince çapraz çizgiler (resmî evrak dokusu)
	for i in range(-6, 14):
		var x := i * 14.0
		draw_line(_t(Vector2(x, 0)), _t(Vector2(x + 120, 120)), Color(1, 1, 1, 0.025), 1.5 * _s)
	var ptex: Texture2D = _portrait_tex()
	if ptex != null:
		var side: float = minf(size.x, size.y * 1.02)
		var hv: int = absi(hash(seed_name + "|v"))
		var k: float = 0.88 + float(hv % 7) * 0.03          # aynı dokuyu paylaşan kişiler biraz farklı görünsün
		var rx: float = (size.x - side) * 0.5
		var r: Rect2 = Rect2(rx, size.y - side, side, side)
		var flip: bool = (hv / 7) % 2 == 1                  # yatay çevir
		if flip:
			draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(ptex, r, false, Color(k, k, k, 1.0))
		if flip:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_badge()
		return
	var hat_cap: bool = role == "def" and style not in ["ru", "me"]
	# --- saç / arka katman
	if style == "me":
		_ghutra_back()
	if female and style != "me":
		_poly([[30, 42], [27, 62], [26, 86], [38, 88], [40, 62]], HAIR)
		_poly([[70, 42], [73, 62], [74, 86], [62, 88], [60, 62]], HAIR)
	# --- gövde
	_poly([[4, 120], [6, 100], [22, 87], [41, 80], [59, 80], [78, 87], [94, 100], [96, 120]], INK)
	# omuz ışığı
	draw_polyline(PackedVector2Array([_t(Vector2(8, 99)), _t(Vector2(22, 88)), _t(Vector2(41, 81.5))]), Color(1, 1, 1, 0.16), 1.4 * _s, true)
	draw_polyline(PackedVector2Array([_t(Vector2(92, 99)), _t(Vector2(78, 88)), _t(Vector2(59, 81.5))]), Color(1, 1, 1, 0.10), 1.4 * _s, true)
	# boyun
	_poly([[43, 62], [57, 62], [58.5, 83], [41.5, 83]], INK.lightened(0.03))
	# yaka / kravat
	match style:
		"asia":
			_poly([[39.5, 74], [60.5, 74], [62, 90], [38, 90]], INK.lightened(0.08))
			draw_line(_t(Vector2(50, 90)), _t(Vector2(50, 120)), Color(1, 1, 1, 0.12), 1.2 * _s)
			for by in [96.0, 104.0, 112.0]:
				draw_circle(_t(Vector2(50, by)), 1.4 * _s, Color(0.85, 0.7, 0.3, 0.8))
		"sa":
			_poly([[40, 76], [60, 76], [62, 92], [38, 92]], INK.lightened(0.08))
			for by2 in [98.0, 106.0, 114.0]:
				draw_circle(_t(Vector2(50, by2)), 1.4 * _s, Color(0.85, 0.7, 0.3, 0.8))
		"me":
			_poly([[41, 80], [50, 98], [59, 80]], PAPER.darkened(0.1))
		_:
			_poly([[41, 80], [50, 102], [59, 80]], PAPER)
			var tc := Color(0.82, 0.2, 0.15) if style == "us" else (Color(0.2, 0.36, 0.68) if style == "eu" else Color(0.9, 0.7, 0.2))
			_poly([[47, 84], [53, 84], [55, 106], [50, 113], [45, 106]], tc)
			_poly([[46.5, 80.5], [53.5, 80.5], [52.5, 85], [47.5, 85]], tc.darkened(0.25))
			if style == "af":
				for i in 3:
					draw_line(_t(Vector2(43 + i * 5.5, 82)), _t(Vector2(41 + i * 6.5, 100)), Color(0.95, 0.75, 0.2, 0.85), 1.6 * _s)
	# --- apolet (savunma)
	if role == "def":
		for sx in [0, 1]:
			var x0: float = 14.0 if sx == 0 else 70.0
			_poly([[x0, 90], [x0 + 16, 86], [x0 + 16, 94], [x0, 98]], HAIR.lightened(0.05))
			var gc := Color(0.86, 0.7, 0.28, 0.9)
			for gi in 3:
				draw_line(_t(Vector2(x0 + 4 + gi * 4, 90.5 - gi * 1.0)), _t(Vector2(x0 + 4 + gi * 4, 96.5 - gi * 1.0)), gc, 1.3 * _s)
	# --- baş
	var hx := 50.0
	var rx := 14.0 if female else 15.0
	var ry := 18.0 if female else 19.0
	_poly_p(_ell(hx, 48, rx, ry), INK)
	# kulak çıkıntıları
	_poly_p(_ell(hx - rx, 50, 2.4, 4.2, 14), INK)
	_poly_p(_ell(hx + rx, 50, 2.4, 4.2, 14), INK)
	# yüz yok: yalnızca hafif rim ışığı
	draw_arc(_t(Vector2(hx, 48)), ry * _s * 0.92, deg_to_rad(215), deg_to_rad(325), 18, Color(1, 1, 1, 0.14), 1.4 * _s, true)
	# --- başlık / saç
	match style:
		"ru":
			_ushanka()
		"me":
			_ghutra_front()
		"sa":
			_hair_short()
			_poly([[33, 34], [67, 34], [64, 22], [36, 22]], PAPER.darkened(0.05))      # kasket (topi)
			_poly([[33, 34], [67, 34], [66, 37], [34, 37]], PAPER.darkened(0.3))
		_:
			if not hat_cap:
				_hair_short()
	if hat_cap:
		_peaked_cap()
	_badge()


func _badge() -> void:
	var bs := 26.0 * _s
	var bc := _t(Vector2(84, 105))
	draw_circle(bc, bs * 0.62, Color(0.08, 0.09, 0.11, 0.95))
	draw_arc(bc, bs * 0.62, 0, TAU, 32, Color(0.93, 0.9, 0.82, 0.95), 1.8 * _s, true)
	Icons.draw(self, ROLE_ICON.get(role, "star"), Rect2(bc - Vector2(bs, bs) * 0.36, Vector2(bs, bs) * 0.72), Color(0.93, 0.9, 0.82), 2.2)


func _hair_short() -> void:
	if female:
		_poly_p(_ell(50, 38, 18.5, 17), HAIR)
		_poly_p(_ell(50, 52, 13, 15), INK)       # yüzü yeniden aç
		_poly_p(_ell(50, 33, 15.5, 8), HAIR)
		return
	_poly([[34.5, 46], [34, 32], [40, 25], [50, 22.5], [60, 25], [66, 32], [65.5, 46], [62, 36], [50, 31], [38, 36]], HAIR)


func _peaked_cap() -> void:
	_poly_p(_ell(50, 31, 20, 11), HAIR.lightened(0.04))
	_poly([[30, 38], [70, 38], [75, 43], [25, 43]], HAIR.darkened(0.2))
	_poly([[31, 33], [69, 33], [70, 38], [30, 38]], PAPER.darkened(0.55))
	draw_circle(_t(Vector2(50, 33.5)), 2.6 * _s, Color(0.86, 0.7, 0.28))
	draw_arc(_t(Vector2(50, 30)), 19.0 * _s, deg_to_rad(205), deg_to_rad(335), 16, Color(1, 1, 1, 0.12), 1.2 * _s, true)


func _ushanka() -> void:
	var fur := Color(0.36, 0.34, 0.31)
	_poly_p(_ell(50, 32, 22.5, 15), fur)
	_poly([[28, 38], [72, 38], [73, 46], [27, 46]], fur.darkened(0.15))
	_poly([[27, 38], [28, 62], [37, 70], [41, 52], [37, 44]], fur.darkened(0.08))
	_poly([[73, 38], [72, 62], [63, 70], [59, 52], [63, 44]], fur.darkened(0.08))
	var st := PackedVector2Array()
	for v in _star(50, 33, 4.6, 2.0):
		st.append(_t(v))
	draw_colored_polygon(st, Color(0.84, 0.2, 0.15))
	draw_arc(_t(Vector2(50, 30)), 21.0 * _s, deg_to_rad(205), deg_to_rad(335), 16, Color(1, 1, 1, 0.16), 1.4 * _s, true)


func _star(cx: float, cy: float, ro: float, ri: float) -> Array:
	var out: Array = []
	for i in 10:
		var a := deg_to_rad(-90.0 + i * 36.0)
		var rr := ro if i % 2 == 0 else ri
		out.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr))
	return out


func _ghutra_back() -> void:
	var cloth := PAPER
	_poly_p(_ell(50, 38, 22.5, 20), cloth)
	_poly([[28, 42], [22, 62], [22, 84], [38, 82], [36, 58]], cloth.darkened(0.08))
	_poly([[72, 42], [78, 62], [78, 84], [62, 82], [64, 58]], cloth.darkened(0.12))
	var chk := Color(0.72, 0.2, 0.18, 0.55)
	for i in 5:
		draw_line(_t(Vector2(24 + i * 1.5, 50 + i * 7)), _t(Vector2(36 + i * 0.3, 52 + i * 6)), chk, 1.1 * _s)
		draw_line(_t(Vector2(76 - i * 1.5, 50 + i * 7)), _t(Vector2(64 - i * 0.3, 52 + i * 6)), chk, 1.1 * _s)


func _ghutra_front() -> void:
	var cloth := PAPER
	# yüz penceresi içeride kalsın diye başı bez üstüne yeniden çiz
	_poly_p(_ell(50, 52, 13.2, 17), INK)
	# alın bezi
	_poly([[30, 36], [38, 28], [50, 25], [62, 28], [70, 36], [64, 36], [50, 30], [36, 36]], cloth)
	# agal (siyah çift halka)
	for k in 2:
		draw_arc(_t(Vector2(50, 30 + k * 3.6)), 21.5 * _s, deg_to_rad(188), deg_to_rad(352), 24, Color(0.05, 0.05, 0.06), 2.4 * _s, true)
	# omuz üzerine dökülen bez
	_poly([[26, 74], [37, 84], [30, 92], [20, 90]], cloth.darkened(0.06))
	_poly([[74, 74], [63, 84], [70, 92], [80, 90]], cloth.darkened(0.12))
