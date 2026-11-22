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
var on_cancel: Callable = Callable()  ## X'e / boşluğa dokunarak kapatınca çağrılır (vazgeçme)
var _closing := false
var _dim: ColorRect


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
	_dim = dim
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.06, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if can_close and ((ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed)):
			cancel())
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
		var kl := TK.t(kicker, "kicker")
		kl.clip_text = true
		kl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tv.add_child(kl)
	title_lbl = TK.t(title, "h3", TK.TEXT)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(title_lbl)
	head.add_child(tv)
	if closable:
		var x := TK.icon_button("x", 56, "ghost")
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		x.pressed.connect(cancel)
		head.add_child(x)
	v.add_child(head)
	v.add_child(TK.hsep())
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tall_min = clampf(vp.y * 0.6, 240.0, 560.0) if tall else 0.0
	scroll.custom_minimum_size = Vector2(0, _tall_min)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10 if tall else 12)
	scroll.add_child(body)
	v.add_child(scroll)
	body.minimum_size_changed.connect(_refit)
	footer = HFlowContainer.new()
	footer.alignment = FlowContainer.ALIGNMENT_END
	footer.add_theme_constant_override("h_separation", 12)
	v.add_child(footer)
	_refit()
	modulate = Color(1, 1, 1, 0)
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


var head_box: HBoxContainer
var scroll: ScrollContainer


## Sayfalı editörler: pencere her sayfada ekranı doldurur (sayfa değişince boy/alt düğmeler zıplamasın)
func fill_height() -> void:
	_tall_min = 100000.0
	_refit()

var _tall_min := 0.0
var _fit_pending := false


## İçerik ekrandan uzunsa gövde kaydırılır; kısaysa panel içeriği kadar kalır (başlık ve alt düğmeler hep görünür).
func _refit() -> void:
	if _fit_pending:
		return
	_fit_pending = true
	_do_refit.call_deferred()


func _do_refit() -> void:
	_fit_pending = false
	if not is_inside_tree() or scroll == null:
		return
	var vp := get_viewport_rect().size
	_wrap_long_labels(body, panel.custom_minimum_size.x - 60.0)
	var chrome: float = panel.get_combined_minimum_size().y - scroll.get_combined_minimum_size().y
	var avail: float = maxf(120.0, vp.y - 24.0 - chrome)
	var want: float = maxf(_tall_min, body.get_combined_minimum_size().y)
	scroll.custom_minimum_size = Vector2(0, minf(want, avail))


## Koruma: sarmalanmamış uzun bir yazı paneli ekrandan taşırmasın (gövdedeki tüm Label'lar taranır).
static func _wrap_long_labels(n: Node, limit: float) -> void:
	for ch in n.get_children():
		if ch is Label and ch.autowrap_mode == TextServer.AUTOWRAP_OFF and ch.get_minimum_size().x > limit:
			ch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif ch is RichTextLabel and not ch.fit_content and ch.get_minimum_size().x > limit:
			ch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif ch is Button and not ch.clip_text and ch.get_child_count() == 0 and ch.get_minimum_size().x > limit:
			ch.clip_text = true
			ch.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if not (ch is ScrollContainer):
			_wrap_long_labels(ch, limit)


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


func cancel() -> void:
	if _closing:
		return
	if on_cancel.is_valid():
		on_cancel.call()
	close()


func close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	# solma sürerken (0,12 sn) arkadaki düğmeleri engellemesin: tıklama alttaki menüye geçsin
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _dim != null:
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel != null:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.12)
	tw.tween_callback(queue_free)
