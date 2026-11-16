extends Button
## OptionButton yerine dokunmatik dostu seçici: basınca tam ekran listeli bir pencere açar.
## Küçük açılır menü kaydırırken parmağın değdiği öğeyi seçtiği için bu sınıf kullanılır.
## OptionButton ile aynı temel API: add_item, set_item_metadata, get_item_metadata, select, clear, selected, item_count, item_selected.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")

signal item_selected(index: int)

var selected := -1
var item_count := 0
var title := "Seç"
var _texts: Array = []
var _meta: Array = []


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_font_override("font", TK.disp(1))
	add_theme_font_size_override("font_size", 26)
	TK.style_button(self, "")
	pressed.connect(_open)


func clear() -> void:
	_texts.clear()
	_meta.clear()
	item_count = 0
	selected = -1
	text = ""


func add_item(t: String, _id: int = -1) -> void:
	_texts.append(t)
	_meta.append(null)
	item_count = _texts.size()
	if selected < 0:
		select(0)


func set_item_metadata(i: int, m) -> void:
	if i >= 0 and i < _meta.size():
		_meta[i] = m


func get_item_metadata(i: int):
	return _meta[i] if i >= 0 and i < _meta.size() else null


func get_item_text(i: int) -> String:
	return String(_texts[i]) if i >= 0 and i < _texts.size() else ""


func select(i: int) -> void:
	selected = i
	text = (get_item_text(i) + "   ▾") if i >= 0 else ""


func _sheet_parent() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_signal("closed") and "body" in n:
			return n.get_parent()
		n = n.get_parent()
	return get_tree().root


func _open() -> void:
	if _texts.is_empty():
		return
	var sh = Sheet.open(_sheet_parent(), title, 700, true, true, "Seçim")
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.55, 240.0, 560.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	sc.add_child(box)
	if _texts.size() > 8:
		sh.body.add_child(TK.search_field(box, "Ara..."))
	sh.body.add_child(sc)
	for i in _texts.size():
		var idx: int = i
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 60)
		var hb := TK.row_layout(b, 14)
		var l := TK.t(String(_texts[i]), "bodyb", TK.GOLD if i == selected else TK.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(l)
		TK.ignore_mouse(hb)
		b.pressed.connect(func():
			sh.close()
			select(idx)
			item_selected.emit(idx))
		box.add_child(b)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)
