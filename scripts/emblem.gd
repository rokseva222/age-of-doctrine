extends Control
## İttifak amblemi: kodla çizilir. Oyuncu şekil, iç desen, simge ve üç renk seçer.
## emblem = {"shape": int, "inner": int, "symbol": String, "c1": html, "c2": html, "c3": html}

const Icons = preload("res://scripts/icons.gd")

const SHAPES := ["Daire", "Kalkan", "Altıgen", "Elmas", "Sekizgen", "Rozet", "Güneş", "Kare"]
const INNERS := ["Düz", "İç çerçeve", "İç daire"]
const SYMBOLS := ["fl_hammer_sickle", "fl_star5", "fl_crescent_star", "fl_eagle", "fl_eagle2", "fl_lion", "fl_crown", "fl_sword", "fl_swords", "fl_shield", "fl_anchor", "fl_wheat", "fl_laurel", "fl_olive", "fl_gear", "fl_sun", "fl_dragon", "fl_wolf", "fl_bear", "fl_fist", "fl_tower", "fl_trident", "fl_torch", "fl_book", "fl_oak", "fl_cross", "fl_lily", "fl_hammer", "fl_sickle", "fl_crescent", "fl_star6", "fl_star8", "fl_maple", "fl_palm", "fl_cedar", "fl_rose", "fl_horse", "fl_falcon", "fl_elephant", "fl_snake", "fl_axe", "fl_spear", "fl_helmet", "fl_globe", "fl_mountain"]
## Yapay zekâ ittifakları için tarafsız semboller (ideolojik/dinî olanlar yok)
const RANDOM_SYMBOLS := ["fl_star5", "fl_eagle", "fl_lion", "fl_crown", "fl_sword", "fl_swords", "fl_shield", "fl_anchor", "fl_wheat", "fl_laurel", "fl_olive", "fl_gear", "fl_sun", "fl_wolf", "fl_bear", "fl_tower", "fl_trident", "fl_torch", "fl_oak", "fl_star8", "fl_maple", "fl_palm", "fl_cedar", "fl_rose", "fl_horse", "fl_falcon", "fl_elephant", "fl_axe", "fl_spear", "fl_helmet", "fl_globe", "fl_mountain"]
## Eski kayıtlı/hazır amblemlerdeki simge adları yeni siluetlere yönlenir
const LEGACY := {"star": "fl_star5", "sword": "fl_sword", "swords": "fl_swords", "shield": "fl_shield", "crown": "fl_crown", "anchor": "fl_anchor", "wheat": "fl_wheat", "flame": "fl_torch", "castle": "fl_tower", "globe": "fl_sun", "bolt": "fl_gear", "factory": "fl_gear", "skull": "fl_wolf"}
const PALETTE := ["e5482f", "e58a3a", "e3a92b", "5db86e", "2f8f83", "5ba4e0", "2f4f9a", "a98be0", "b0486e", "ece6d6", "9aa2ad", "20262e", "0b0e12"]

var emblem: Dictionary = {}


static func default_emblem() -> Dictionary:
	return {"shape": 1, "inner": 1, "symbol": "fl_star5", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"}


static func random_emblem(rng: RandomNumberGenerator, base: Color = Color.WHITE) -> Dictionary:
	var c1: String = PALETTE[rng.randi_range(0, 8)]
	var c2: String = PALETTE[rng.randi_range(9, 11)]
	if base != Color.WHITE:
		c1 = base.darkened(0.25).to_html(false)
	return {"shape": rng.randi_range(0, SHAPES.size() - 1), "inner": rng.randi_range(0, 2),
		"symbol": RANDOM_SYMBOLS[rng.randi_range(0, RANDOM_SYMBOLS.size() - 1)], "c1": c1, "c2": c2, "c3": c1}


static func _poly(shape: int, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		1:  # kalkan
			pts = PackedVector2Array([c + Vector2(-0.85, -0.9) * r, c + Vector2(0.85, -0.9) * r, c + Vector2(0.85, 0.05) * r,
				c + Vector2(0.55, 0.55) * r, c + Vector2(0.0, 1.0) * r, c + Vector2(-0.55, 0.55) * r, c + Vector2(-0.85, 0.05) * r])
		2:  # altıgen
			for i in 6:
				pts.append(c + Vector2.from_angle(deg_to_rad(60.0 * i - 90.0)) * r)
		3:  # elmas
			pts = PackedVector2Array([c + Vector2(0, -1.0) * r, c + Vector2(0.8, 0) * r, c + Vector2(0, 1.0) * r, c + Vector2(-0.8, 0) * r])
		4:  # sekizgen
			for i in 8:
				pts.append(c + Vector2.from_angle(deg_to_rad(45.0 * i - 22.5)) * r)
		5:  # rozet (beşgen)
			for i in 5:
				pts.append(c + Vector2.from_angle(deg_to_rad(72.0 * i - 90.0)) * r)
		6:  # güneş (12 uçlu yıldız)
			for i in 24:
				var rr: float = r if i % 2 == 0 else r * 0.80
				pts.append(c + Vector2.from_angle(deg_to_rad(15.0 * i - 90.0)) * rr)
		7:  # kare
			pts = PackedVector2Array([c + Vector2(-0.82, -0.82) * r, c + Vector2(0.82, -0.82) * r, c + Vector2(0.82, 0.82) * r, c + Vector2(-0.82, 0.82) * r])
		_:  # daire
			for i in 40:
				pts.append(c + Vector2.from_angle(TAU * i / 40.0) * r)
	return pts


static func draw_in(ci: CanvasItem, rect: Rect2, e: Dictionary, alpha: float = 1.0) -> void:
	if e.is_empty():
		return
	var s: float = minf(rect.size.x, rect.size.y)
	var c: Vector2 = rect.position + rect.size * 0.5
	var r: float = s * 0.46
	var c1 := Color(e.get("c1", "2f4f9a"))
	var c2 := Color(e.get("c2", "ece6d6"))
	var c3 := Color(e.get("c3", "2f4f9a"))
	c1.a = alpha
	c2.a = alpha
	c3.a = alpha
	var shape: int = int(e.get("shape", 0))
	var outline: PackedVector2Array = _poly(shape, c, r)
	ci.draw_colored_polygon(outline, c2)
	var o2 := outline.duplicate()
	o2.append(outline[0])
	ci.draw_polyline(o2, c1, maxf(s * 0.045, 1.2), true)
	var inner: int = int(e.get("inner", 0))
	var ir := r * 0.8
	if inner == 1:
		ci.draw_colored_polygon(_poly(shape, c, ir), c1)
	elif inner == 2:
		ci.draw_circle(c, ir * 0.82, c1)
	else:
		ci.draw_colored_polygon(_poly(shape, c, ir), c1)
	var sym: String = e.get("symbol", "fl_star5")
	sym = LEGACY.get(sym, sym)
	var isz: float = s * (0.46 if inner != 0 else 0.5)
	var col := c2 if inner != 0 else c2
	Icons.draw(ci, sym, Rect2(c - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), col, 2.6)
	if inner == 0:
		# düz: ince iç çizgi
		var o3 := _poly(shape, c, r * 0.9)
		o3.append(o3[0])
		ci.draw_polyline(o3, c3, maxf(s * 0.02, 1.0), true)


func _draw() -> void:
	draw_in(self, Rect2(Vector2.ZERO, size), emblem)


func set_emblem(e: Dictionary) -> void:
	emblem = e
	queue_redraw()
