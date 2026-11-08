extends RefCounted
## Tur geçişi ekranları: yükleniyor ekranı ve "Cihan Bülteni" haber/rapor ekranı.

const TK = preload("res://scripts/theme_kit.gd")
const Names = preload("res://scripts/names.gd")
const Macro = preload("res://scripts/macro.gd")

const PRIORITY := {
	"war_player": 100, "lost_player": 95, "capture_player": 90, "rebel_player": 85, "war": 70, "elim": 65,
	"capture": 60, "peace": 58, "alliance": 50, "battle": 45, "event_player": 40, "rebel": 35, "event": 30,
	"cyber": 25, "rank": 20, "info": 10,
}
const TIPS := [
	"Yapay zekâ devletleri hamlelerini yapıyor...",
	"Ordular ilerliyor, muharebeler çözülüyor...",
	"Ekonomi, bütçe ve ticaret hesaplanıyor...",
	"Diplomasi ve ittifaklar değerlendiriliyor...",
	"Cihan Bülteni basılıyor...",
]


# ------------------------------------------------------------------ yükleniyor

class Loading extends Control:
	var bar_fill: ColorRect
	var status: Label
	var _v := 0.0
	var _w := 520.0

	func _apply(x: float) -> void:
		_v = x
		bar_fill.size = Vector2(_w * x, 6)

	func set_step(v: float, text: String) -> void:
		status.text = text
		var tw := create_tween()
		tw.tween_method(_apply, _v, v, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	func close() -> void:
		queue_free()


static func loading(parent: Control, next_turn: int) -> Loading:
	var o := Loading.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(bg)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(o._w, 0)
	c.add_child(v)
	var k := TK.t("Age of Doctrine  /  Tur sonu", "kicker", TK.MUTED)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	var d := TK.t(Names.date_string(next_turn), "h2", TK.TEXT)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	v.add_child(TK.spacer(0, 14))
	var track := ColorRect.new()
	track.color = TK.PANEL_HI
	track.custom_minimum_size = Vector2(o._w, 6)
	v.add_child(track)
	o.bar_fill = ColorRect.new()
	o.bar_fill.color = TK.PAPER
	o.bar_fill.position = Vector2.ZERO
	o.bar_fill.size = Vector2(0, 6)
	track.add_child(o.bar_fill)
	o.status = TK.t(TIPS[0], "small", TK.MUTED)
	o.status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(o.status)
	o.modulate = Color(1, 1, 1, 0)
	parent.add_child(o)
	o.create_tween().tween_property(o, "modulate:a", 1.0, 0.15)
	return o


# ------------------------------------------------------------------ haber / rapor ekranı

class Report extends Control:
	signal closed
	var _done := false

	func close() -> void:
		if _done:
			return
		_done = true
		closed.emit()
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)


static func snapshot(gs) -> Dictionary:
	var c = gs.countries[gs.player]
	return {"gold": c.gold, "troops": c.troops, "prov": c.prov_owned, "net": gs.net_income(c)}


static func _paper_label(text: String, size: int, col: Color, bold := false, wrap := false) -> Label:
	var l := TK.t(text, "bodyb" if bold else "body", col)
	l.add_theme_font_size_override("font_size", size)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func _dark(c: Color) -> Color:
	return c.darkened(0.35)


static func build_report(ui, gs, before: Dictionary, on_focus: Callable) -> Report:
	var rep := Report.new()
	rep.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rep.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.06, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rep.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rep.add_child(center)
	var vp: Vector2 = ui.root.get_viewport_rect().size
	var W := minf(1160.0, vp.x - 40.0)
	var H := minf(640.0, vp.y - 40.0)
	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(W, H)
	paper.add_theme_stylebox_override("panel", TK.box(Color("e9e2d0"), Color("b9b09a"), 3, 2, 1, Vector4(28, 16, 28, 18)))
	center.add_child(paper)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	paper.add_child(root)
	var ink := Color("1c1812")
	var ink2 := Color("5a5446")
	# --- künye
	var mast := HBoxContainer.new()
	var ml := TK.t("Cihan Bülteni", "h1", ink)
	ml.add_theme_font_size_override("font_size", 58)
	mast.add_child(ml)
	mast.add_child(TK.fill())
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", -4)
	var dl := TK.t(Names.date_string(gs.turn), "h3", ink)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mv.add_child(dl)
	var sl := TK.t("Sayı %d  /  haftalık baskı" % gs.turn, "kicker", ink2)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sl.add_theme_color_override("font_color", ink2)
	mv.add_child(sl)
	mast.add_child(mv)
	root.add_child(mast)
	var r1 := ColorRect.new()
	r1.color = ink
	r1.custom_minimum_size = Vector2(0, 3)
	root.add_child(r1)
	# --- haberler
	var items: Array = []
	var fought := {}
	for b in gs.turn_battles:
		fought[b.prov] = true
	for n in gs.news_log:
		# oyuncunun muharebeleri zaten harp raporunda; aynı haberi iki kez gösterme
		if n.turn == gs.turn and not (n.kind == "battle" and fought.has(n.prov)):
			items.append(n)
	var idx := 0
	for n in items:
		n["_o"] = idx
		idx += 1
	items.sort_custom(func(a, b):
		var pa: int = PRIORITY.get(a.kind, 15)
		var pb: int = PRIORITY.get(b.kind, 15)
		if pa != pb:
			return pa > pb
		return a["_o"] < b["_o"])
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# sol sütun: manşet + diğer haberler
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var head_prov := -1
	if items.is_empty():
		var e := _paper_label("Bu hafta dünyada büyük bir gelişme yaşanmadı.", 34, ink, true, true)
		left.add_child(e)
	else:
		var top: Dictionary = items[0]
		head_prov = top.prov
		var info: Array = ui._news_info(top.kind, top.get("ic", ""))
		var tag := TK.stamp(info[0], _dark(info[1]))
		tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var thb := HBoxContainer.new()
		thb.add_theme_constant_override("separation", 12)
		var tic := TK.IconView.new()
		tic.icon = info[2]
		tic.custom_minimum_size = Vector2(52, 52)
		tic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thb.add_child(tic)
		thb.add_child(tag)
		left.add_child(thb)
		left.add_child(_paper_label(top.text, 34, ink, true, true))
		var r2 := ColorRect.new()
		r2.color = Color("b9b09a")
		r2.custom_minimum_size = Vector2(0, 1)
		left.add_child(r2)
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 10)
		lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(lv)
		left.add_child(sc)
		for i in range(1, mini(items.size(), 12)):
			var n: Dictionary = items[i]
			var inf: Array = ui._news_info(n.kind, n.get("ic", ""))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			var nic := TK.IconView.new()
			nic.icon = inf[2]
			nic.custom_minimum_size = Vector2(30, 30)
			nic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			nic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(nic)
			var k := TK.t(inf[0], "kicker", _dark(inf[1]))
			k.add_theme_color_override("font_color", _dark(inf[1]))
			k.custom_minimum_size = Vector2(104, 0)
			row.add_child(k)
			row.add_child(_paper_label(n.text, 22, ink, false, true))
			lv.add_child(row)
		if items.size() == 1:
			lv.add_child(_paper_label("Başka önemli haber yok.", 22, ink2))
	# sağ sütun: harp raporu + hazine
	var vr := ColorRect.new()
	vr.color = Color("b9b09a")
	vr.custom_minimum_size = Vector2(1, 0)
	body.add_child(vr)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.custom_minimum_size = Vector2(350, 0)
	body.add_child(right)
	var rk := TK.t("Harp raporu", "kicker", ink2)
	rk.add_theme_color_override("font_color", ink2)
	right.add_child(rk)
	var rsc := ScrollContainer.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(rv)
	right.add_child(rsc)
	var any_war := false
	for b in gs.turn_battles:
		any_war = true
		var mine_att: bool = b.att == gs.player
		var won: bool = b.att_won == mine_att
		var col: Color = Color("1f6b3a") if won else Color("a3321f")
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var st := TK.stamp("ZAFER" if won else "YENİLGİ", col)
		h.add_child(st)
		var pn := _paper_label(b.name, 22, ink, true)
		pn.clip_text = true
		pn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		pn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(pn)
		rv.add_child(h)
		var my_loss: int = b.att_loss if mine_att else b.def_loss
		var foe_loss: int = b.def_loss if mine_att else b.att_loss
		var foe_name: String = b.def_name if mine_att else b.att_name
		var kind := "Taarruz" if mine_att else "Savunma"
		var op_txt := ""
		if mine_att and gs.OPS.has(b.op) and b.op != "assault":
			op_txt = "  (%s)" % gs.OPS[b.op].name
		rv.add_child(_paper_label("%s%s: %s karşısında. Kayıp: sen %s, karşı taraf %s." % [kind, op_txt, foe_name, Macro.num(my_loss), Macro.num(foe_loss)], 18, ink2, false, true))
	# süren kuşatmalar
	for p in gs.provinces:
		if p.siege > 0 and p.siege_by == gs.player and p.controller != gs.player:
			any_war = true
			var sg := _paper_label("Kuşatma: %s  %d/%d" % [p.name, p.siege, p.siege_needed()], 20, Color("8a5a12"), true, true)
			rv.add_child(sg)
	if not any_war:
		rv.add_child(_paper_label("Bu hafta çatışma olmadı.", 20, ink2, false, true))
	right.add_child(TK.hsep(0.6))
	var hk := TK.t("Hazine ve ordu", "kicker", ink2)
	hk.add_theme_color_override("font_color", ink2)
	right.add_child(hk)
	var after := snapshot(gs)
	right.add_child(_delta_row("Kasa", Macro.money(after.gold), after.gold - before.gold, true, ink, true))
	right.add_child(_delta_row("Asker", Macro.num(after.troops), after.troops - before.troops, false, ink, false))
	right.add_child(_delta_row("Eyalet", "%d" % after.prov, after.prov - before.prov, false, ink, false))
	# --- alt şerit
	var r3 := ColorRect.new()
	r3.color = ink
	r3.custom_minimum_size = Vector2(0, 2)
	root.add_child(r3)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	foot.alignment = BoxContainer.ALIGNMENT_END
	if head_prov >= 0:
		var bm := TK.button("Haritada göster", "", "map", Vector2(260, 60), 17)
		bm.pressed.connect(func():
			ui._click()
			rep.close()
			on_focus.call(head_prov))
		foot.add_child(bm)
	var bc := TK.button("Devam", "good", "check", Vector2(220, 60), 19)
	bc.pressed.connect(func():
		ui._click()
		rep.close())
	foot.add_child(bc)
	root.add_child(foot)
	rep.modulate = Color(1, 1, 1, 0)
	ui.root.add_child(rep)
	rep.create_tween().tween_property(rep, "modulate:a", 1.0, 0.2)
	return rep


static func _delta_row(cap: String, val: String, delta: float, money: bool, ink: Color, higher_good: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var dic := TK.IconView.new()
	dic.icon = {"Kasa": "money_bag", "Asker": "infantry", "Eyalet": "city"}.get(cap, "coins")
	dic.custom_minimum_size = Vector2(32, 32)
	dic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(dic)
	var c := _paper_label(cap, 22, Color("5a5446"))
	c.custom_minimum_size = Vector2(78, 0)
	h.add_child(c)
	var v := TK.t(val, "value", ink)
	v.add_theme_font_size_override("font_size", 26)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var txt := ""
	var col := Color("5a5446")
	if absf(delta) >= 0.5:
		var sign := "+" if delta > 0 else "-"
		txt = sign + (Macro.money(absf(delta)) if money else Macro.num(absf(delta)))
		col = Color("1f6b3a") if delta > 0 else Color("a3321f")
	var d := TK.t(txt, "mono", col)
	d.add_theme_color_override("font_color", col)
	h.add_child(d)
	return h
