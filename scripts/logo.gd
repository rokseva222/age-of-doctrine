extends Control
## Marka: sabit görseller (assets/brand/emblem.png + wordmark.png). Kod yalnızca yerleştirir.
## vertical=true: üstte amblem, altta yazı (açılış). false: solda amblem, sağda yazı (menü).

var vertical := true
var show_text := true
var spin := 0.0
var intro := 1.0                 # 0..1 (saydamlık)
var emblem_scale := 1.0

static var _em: Texture2D
static var _wm: Texture2D


static func emblem_tex() -> Texture2D:
	if _em == null:
		_em = load("res://assets/brand/emblem.png")
	return _em


static func wordmark_tex() -> Texture2D:
	if _wm == null:
		_wm = load("res://assets/brand/wordmark.png")
	return _wm


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if intro < 1.0:
		set_process(true)
	else:
		set_process(false)


func _process(_d: float) -> void:
	queue_redraw()


func _fit(tex: Texture2D, max_w: float, max_h: float) -> Vector2:
	var s := minf(max_w / tex.get_width(), max_h / tex.get_height())
	return Vector2(tex.get_width(), tex.get_height()) * s


func _draw() -> void:
	var em := emblem_tex()
	var wm := wordmark_tex()
	var col := Color(1, 1, 1, intro)
	if not show_text:
		var es := _fit(em, size.x, size.y) * emblem_scale
		draw_texture_rect(em, Rect2((size - es) * 0.5, es), false, col)
		return
	if vertical:
		var gap := size.y * 0.07
		var wsz := _fit(wm, size.x * 0.98, size.y * 0.24)
		var esz := _fit(em, size.x, size.y - wsz.y - gap) * emblem_scale
		var top := (size.y - esz.y - gap - wsz.y) * 0.5
		draw_texture_rect(em, Rect2(Vector2((size.x - esz.x) * 0.5, top), esz), false, col)
		draw_texture_rect(wm, Rect2(Vector2((size.x - wsz.x) * 0.5, top + esz.y + gap), wsz), false, col)
	else:
		var esz2 := _fit(em, size.y, size.y) * emblem_scale
		var gap2 := size.y * 0.22
		var wsz2 := _fit(wm, size.x - esz2.x - gap2, size.y * 0.78)
		draw_texture_rect(em, Rect2(Vector2(0, (size.y - esz2.y) * 0.5), esz2), false, col)
		draw_texture_rect(wm, Rect2(Vector2(esz2.x + gap2, (size.y - wsz2.y) * 0.5), wsz2), false, col)
