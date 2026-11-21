extends Control
## Online oyuncu şeridi: her insan oyuncunun bayrağı ve durumu (turu bitirdi / oynuyor / yapay zekâ / ayrıldı),
## tur geri sayımı ve kısa olay akışı ("X turu geçti", "Y ayrıldı"...). Ekranın üstünde, üst çubuğun altında durur.

const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")

const FEED_MAX := 5
const FEED_SECS := 7.0

var net = null
var top_y := 80.0
var _strip: PanelContainer
var _flow: HFlowContainer
var _timer_lbl: Label
var _feed: VBoxContainer
var _left := -1.0
var _grace := false
var _blink := 0.0
var _lbl_t := 0.0
var _sig := ""


func setup(n, top: float) -> void:
	net = n
	top_y = top
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	col.offset_top = top_y + 8.0
	col.offset_left = 16.0
	col.offset_right = -16.0
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)
	_strip = PanelContainer.new()
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_theme_stylebox_override("panel", TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.92), TK.LINE, 4, 1, 0, Vector4(12, 6, 12, 6)))
	holder.add_child(_strip)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 16)
	_strip.add_child(h)
	_flow = HFlowContainer.new()
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override("h_separation", 12)
	_flow.add_theme_constant_override("v_separation", 4)
	_flow.custom_minimum_size = Vector2(120, 0)
	h.add_child(_flow)
	_timer_lbl = TK.t("", "small", TK.TEXT)
	_timer_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_timer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_timer_lbl)
	var fh := CenterContainer.new()
	fh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(fh)
	_feed = VBoxContainer.new()
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_theme_constant_override("separation", 4)
	fh.add_child(_feed)
	refresh()


func _gs():
	return net.gs_client if net != null else null


## Bir insan ülkesinin durumu: [kısa yazı, renk]
func _state(cid: int) -> Array:
	var connected := false
	for p in net.players.values():
		if int(p.cid) == cid:
			connected = true
	var afk: bool = net.afk_ids.has(cid)
	if afk and not connected:
		return [Loc.t("AYRILDI"), TK.RED_TEXT]
	if afk:
		return [Loc.t("YZ"), TK.PURPLE]
	if net.waiting.has(cid):
		return [Loc.t("OYNUYOR"), TK.ORANGE]
	return [Loc.t("HAZIR"), TK.GREEN]


## Şeridi sunucudan gelen son duruma göre yeniden çizer.
func refresh() -> void:
	var g = _gs()
	if g == null or net == null:
		return
	var humans: Array = g.net_humans
	_left = net.deadline_left
	_grace = net.deadline_grace
	var sig := "%s|%s|%s|%s" % [str(humans), str(net.waiting), str(net.afk_ids), str(net.players.size())]
	if sig != _sig:
		_sig = sig
		for c in _flow.get_children():
			c.queue_free()
		var shown := 0
		for cid in humans:
			var ci: int = int(cid)
			if ci < 0 or ci >= g.countries.size() or not g.countries[ci].alive:
				continue
			shown += 1
			var st: Array = _state(ci)
			var v := VBoxContainer.new()
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_theme_constant_override("separation", 0)
			var fr := PanelContainer.new()
			fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sb := TK.box(Color(0, 0, 0, 0), st[1], 3, 3, 0, Vector4(0, 0, 0, 0))
			fr.add_theme_stylebox_override("panel", sb)
			var fl := TK.flag_rect(g.countries[ci], Vector2(54, 36))
			fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fr.add_child(fl)
			v.add_child(fr)
			var tl := TK.t(String(st[0]), "kicker", st[1])
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tl.add_theme_font_size_override("font_size", 14)
			tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(tl)
			if ci == net.my_cid:
				fr.add_theme_stylebox_override("panel", TK.box(Color(1, 1, 1, 0.06), st[1], 3, 3, 0, Vector4(0, 0, 0, 0)))
			_flow.add_child(v)
		# şerit genişliği: bayrak sayısına göre, ekrana sığmazsa alt satıra sarar
		var maxw: float = maxf(get_viewport_rect().size.x - 420.0, 200.0)
		_flow.custom_minimum_size.x = minf(maxf(shown, 1) * 84.0 + 12.0, maxw)
	_update_label()


func _update_label() -> void:
	if net == null:
		return
	if _left < 0.0:
		_timer_lbl.text = ""
		_timer_lbl.visible = false
		return
	_timer_lbl.visible = true
	var s: int = int(ceil(_left))
	var tm := "%d:%02d" % [s / 60, s % 60]
	var me_waiting: bool = net.waiting.has(net.my_cid)
	var txt: String
	if _grace:
		txt = (Loc.t("Otomatik geçiş: %s") if me_waiting else Loc.t("Bekleme: %s")) % tm
	else:
		txt = Loc.t("Tur süresi: %s") % tm
	_timer_lbl.text = txt
	var col: Color = TK.TEXT
	if _left <= 15.0:
		col = TK.RED_TEXT
	elif _grace and me_waiting:
		col = TK.ORANGE
	_timer_lbl.add_theme_color_override("font_color", col)


func _process(delta: float) -> void:
	if _left > 0.0:
		_left = maxf(_left - delta, 0.0)
	_lbl_t += delta
	if _lbl_t >= 0.25:
		_lbl_t = 0.0
		_update_label()


## Olay akışına bir satır ekler. kind: ready, afk, back, left, grace, diplo, info
func add_note(kind: String, cid: int, text: String = "") -> void:
	var g = _gs()
	if g == null:
		return
	var nm := ""
	if cid >= 0 and cid < g.countries.size():
		nm = String(g.countries[cid].name)
	var msg := ""
	var col: Color = TK.TEXT
	match kind:
		"ready":
			msg = Loc.t("%s turu geçti") % nm
			col = TK.GREEN
		"afk":
			msg = Loc.t("%s sürede dönmedi, yapay zekâ devraldı") % nm
			col = TK.PURPLE
		"back":
			msg = Loc.t("%s oyuna döndü") % nm
			col = TK.BLUE
		"left":
			msg = Loc.t("%s oyundan ayrıldı, yapay zekâ devraldı") % nm
			col = TK.RED_TEXT
		"grace":
			msg = Loc.t("Geri sayım başladı: süre dolunca tur otomatik işlenir")
			col = TK.ORANGE
		"diplo":
			msg = text
			col = TK.TEXT
		_:
			msg = text
	if msg == "":
		return
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.9), TK.LINE, 3, 1, 0, Vector4(10, 4, 12, 4)))
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)
	if cid >= 0 and cid < g.countries.size() and kind != "grace":
		var fl := TK.flag_rect(g.countries[cid], Vector2(36, 24))
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fl)
	var l := TK.t(msg, "small", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lf: Font = l.get_theme_font("font")
	var lfs: int = l.get_theme_font_size("font_size")
	var lw: float = lf.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs).x + 6.0 if lf != null else 400.0
	l.custom_minimum_size = Vector2(minf(lw, maxf(get_viewport_rect().size.x - 220.0, 240.0)), 0)
	h.add_child(l)
	_feed.add_child(row)
	while _feed.get_child_count() > FEED_MAX:
		_feed.get_child(0).queue_free()
		_feed.remove_child(_feed.get_child(0))
	var tw := row.create_tween()
	tw.tween_interval(FEED_SECS)
	tw.tween_property(row, "modulate:a", 0.0, 0.6)
	tw.tween_callback(row.queue_free)
