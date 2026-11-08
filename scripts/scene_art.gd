extends Control
## Animasyonlu sahne afişleri. Varsayılan: kodla çizilen piksel-art sahneler (scripts/pixel_scenes.gd, dosya gerekmez).
## assets/scenes/<ad>.jpg varsa o görsel yavaş kamera hareketiyle gösterilir (isteğe bağlı).
## kind: assault | barrage | blitz | naval | air | missile | paradrop | special | landing | cyber | spy | sanction | trade | alliance | war | peace (summit/nuke/embargo takma ad)

const TK = preload("res://scripts/theme_kit.gd")
const Pixel = preload("res://scripts/pixel_scenes.gd")

const IMG_ALIAS := {"summit": "alliance", "nuke": "war", "embargo": "sanction"}
const FIRE := ["assault", "barrage", "blitz", "naval", "air", "missile", "paradrop", "special", "landing", "war"]
const SCAN := ["cyber", "spy"]
static var _tex_cache: Dictionary = {}

var kind := "assault"
var t := 0.0
var animate := true
var _px = null
var _acc := 0.0


static func _tex_for(k: String) -> Texture2D:
	var key: String = IMG_ALIAS.get(k, k)
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := "res://assets/scenes/%s.jpg" % key
	var tx: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[key] = tx
	return tx


static func make(k: String, h: float = 150.0) -> Control:
	var sc = load("res://scripts/scene_art.gd").new()
	sc.kind = k
	sc.custom_minimum_size = Vector2(0, h)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sc


static func for_op(op: String) -> String:
	match op:
		"assault", "barrage", "cyber", "blitz", "air", "naval", "missile", "paradrop", "special", "landing":
			return op
	return "assault"


func _ready() -> void:
	clip_contents = true
	_px = Pixel.new()
	set_process(animate)


func _process(delta: float) -> void:
	t += delta
	_acc += delta
	if _acc >= 1.0 / 20.0:        # piksel sanat 8 kare/sn'de hareket eder; 20 Hz yeniden çizim yeter
		_acc = 0.0
		queue_redraw()


func _draw() -> void:
	var tx: Texture2D = _tex_for(kind)
	if tx != null:
		_draw_image(tx)
	else:
		var k: String = IMG_ALIAS.get(kind, kind)
		_px.draw(self, k, t)
	_draw_frame()


func _draw_frame() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.14), false, 1.5)
	var pts := PackedVector2Array([Vector2(0, size.y * 0.7), Vector2(size.x, size.y * 0.7), Vector2(size.x, size.y), Vector2(0, size.y)])
	draw_polygon(pts, PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35)]))


# ------------------------------------------------------------ görsel sahne (Gemini) + hafif efektler

func _draw_image(tx: Texture2D) -> void:
	var ts: Vector2 = tx.get_size()
	var cover: float = maxf(size.x / ts.x, size.y / ts.y)
	var zoom: float = cover * (1.07 + 0.035 * sin(t * 0.22))          # yavaş yaklaşma/uzaklaşma
	var dim: Vector2 = ts * zoom
	var slack: Vector2 = dim - size
	var pan := Vector2(sin(t * 0.11) * 0.5, cos(t * 0.09) * 0.25) * slack * 0.6
	draw_texture_rect(tx, Rect2((size - dim) * 0.5 + pan, dim), false)
	var seed_t: float = t
	if FIRE.has(kind):
		# ara sıra namlu/patlama ışığı + yükselen kıvılcım ve duman
		var fl: float = maxf(0.0, sin(seed_t * 2.3) * sin(seed_t * 0.7 + 1.0))
		if fl > 0.55:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.55, 0.2, (fl - 0.55) * 0.35))
		for i in 16:
			var f: float = fposmod(i * 0.173 + seed_t * (0.035 + 0.01 * (i % 3)), 1.0)
			var px: float = fposmod(i * 0.377 + sin(seed_t * 0.3 + i) * 0.02, 1.0) * size.x
			var py: float = size.y * (1.0 - f)
			var a: float = sin(f * PI) * 0.5
			draw_circle(Vector2(px, py), 1.2 + (i % 3) * 0.9, Color(1.0, 0.72, 0.35, a))
	elif SCAN.has(kind):
		var sy: float = fposmod(seed_t * 0.28, 1.0) * size.y
		draw_rect(Rect2(0, sy, size.x, 3.0), Color(0.3, 1.0, 0.55, 0.22))
		draw_rect(Rect2(0, sy - 10.0, size.x, 10.0), Color(0.3, 1.0, 0.55, 0.06))
		if sin(seed_t * 9.0) > 0.96:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 1.0, 0.6, 0.06))
	else:
		# sakin sahneler: yumuşak ışık geçişi ve süzülen toz
		var bx: float = fposmod(seed_t * 0.045, 1.4) * (size.x + size.y) - size.y * 0.7
		var poly := PackedVector2Array([Vector2(bx, 0), Vector2(bx + size.y * 0.55, 0), Vector2(bx + size.y * 0.1, size.y), Vector2(bx - size.y * 0.45, size.y)])
		draw_polygon(poly, PackedColorArray([Color(1, 0.95, 0.75, 0.0), Color(1, 0.95, 0.75, 0.10), Color(1, 0.95, 0.75, 0.0), Color(1, 0.95, 0.75, 0.10)]))
		for i in 10:
			var f2: float = fposmod(i * 0.211 + seed_t * 0.02, 1.0)
			draw_circle(Vector2(fposmod(i * 0.43 + f2 * 0.1, 1.0) * size.x, size.y * (1.0 - f2)), 1.4, Color(1, 0.95, 0.8, sin(f2 * PI) * 0.45))
