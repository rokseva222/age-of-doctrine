extends Control
## Filo bayrağı: oyuncunun tasarladığı bayrak (flags.gd tanım dizgesi); yoksa ülkenin bayrağı.

const Flags = preload("res://scripts/flags.gd")

static var _cache: Dictionary = {}

var spec := ""
var country = null


static func _layers(spec: String) -> Array:
	if not _cache.has(spec):
		if _cache.size() > 64:
			_cache.clear()
		_cache[spec] = Flags._parse(spec)
	return _cache[spec]


## Bir CanvasItem üzerine filo bayrağını çizer (spec boşsa ülke bayrağı)
static func draw_on(ci: CanvasItem, rect: Rect2, spec_: String, country_) -> void:
	if spec_ == "":
		if country_ != null:
			Flags.draw(ci, rect, country_)
		return
	Flags._draw_layers(ci, rect, _layers(spec_))
	ci.draw_rect(rect, Color(0, 0, 0, 0.45), false, 1.0)
	ci.draw_rect(rect.grow(-1.0), Color(1, 1, 1, 0.12), false, 1.0)


func _init() -> void:
	custom_minimum_size = Vector2(120, 80)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(size.x, size.x / Flags.ASPECT))
	if r.size.y > size.y:
		r = Rect2(Vector2.ZERO, Vector2(size.y * Flags.ASPECT, size.y))
	draw_on(self, r, spec, country)
