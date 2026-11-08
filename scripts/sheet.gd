extends Control
## Modal pencere: karartma + "dosya" paneli (üstte krem şerit, büyük harf başlık, alt düğme satırı).

const TK = preload("res://scripts/theme_kit.gd")
const Icons = preload("res://scripts/icons.gd")

signal closed

var panel: PanelContainer
var body: VBoxContainer
var footer: HFlowContainer
var title_lbl: Label
var can_close := true
var _closing := false


static func open(parent: Node, title: String, width: float = 640.0, tall: bool = false, closable: bool = true, kicker: String = ""):
	var s = new()
	parent.add_child(s)
	s._build(title, width, tall, closable, kicker)
	return s


func _build(title: String, width: float, tall: bool, closable: bool, kicker: String) -> void:
	can_close = closable
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.06, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if can_close and ev is InputEventMouseButton and ev.pressed:
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var d := TK.dossier()
	panel = d.panel
	var vp := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(minf(width * 1.08, vp.x - 40.0), 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var v: VBoxContainer = d.body
	var head := HBoxContainer.new()
	head_box = head
	head.add_theme_constant_override("separation", 12)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", -4)
	if kicker != "":
		tv.add_child(TK.t(kicker, "kicker"))
	title_lbl = TK.t(title, "h3", TK.TEXT)
	tv.add_child(title_lbl)
	head.add_child(tv)
	if closable:
		var x := TK.icon_button("x", 56, "ghost")
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		x.pressed.connect(close)
		head.add_child(x)
	v.add_child(head)
	v.add_child(TK.hsep())
	if tall:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(0, clampf(vp.y * 0.6, 240.0, 560.0))
		body = VBoxContainer.new()
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_constant_override("separation", 10)
		scroll.add_child(body)
		v.add_child(scroll)
	else:
		body = VBoxContainer.new()
		body.add_theme_constant_override("separation", 12)
		v.add_child(body)
	footer = HFlowContainer.new()
	footer.alignment = FlowContainer.ALIGNMENT_END
	footer.add_theme_constant_override("h_separation", 12)
	v.add_child(footer)
	modulate = Color(1, 1, 1, 0)
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


var head_box: HBoxContainer


## Başlığın soluna renkli ikon koyar (yeni ikon yoksa fallback kullanılır; ikisi de yoksa hiçbir şey eklemez).
func set_icon(name: String, fallback: String = "", px: float = 64.0) -> void:
	var n: String = Icons.pick(name, fallback)
	if n == "" or head_box == null:
		return
	var iv := TK.IconView.new()
	iv.icon = n
	iv.color = TK.GOLD
	iv.stroke = 2.0
	iv.custom_minimum_size = Vector2(px, px)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_box.add_child(iv)
	head_box.move_child(iv, 0)


func add_text(text: String, size: int = 24, color: Color = TK.TEXT) -> Label:
	var l := TK.t(text, "body", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(l)
	return l


func add_button(text: String, cb: Callable, kind: String = "", close_after: bool = true, icon: String = "", min_w: float = 150.0) -> Button:
	var b := TK.button(text, kind, icon, Vector2(min_w, 60))
	b.pressed.connect(func():
		if close_after:
			close()
		cb.call())
	footer.add_child(b)
	return b


func close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.12)
	tw.tween_callback(queue_free)
