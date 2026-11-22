extends RefCounted
## Ülke formlama ekranı: oyuncunun ülkesinin kurabileceği tarihî devletler, ilerleme çubuğu ve "Formla" düğmesi.

const Loc = preload("res://scripts/loc.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Formables = preload("res://scripts/formables.gd")
const Eras = preload("res://scripts/eras.gd")


static func open(ui, gs) -> void:
	if gs == null or gs.player < 0:
		return
	var me = gs.countries[gs.player]
	var sh = ui._open_sheet("Ülke formla", 860, true, true, me.name)
	var list: Array = Formables.available(gs)
	if Eras.current != "":
		sh.body.add_child(_wrap("Ülke formlama yalnızca günümüz haritasında kullanılabilir."))
	elif me.formed != "":
		sh.body.add_child(_wrap("%s zaten formlandı." % me.name))
	elif list.is_empty():
		sh.body.add_child(_wrap("%s için formlanabilecek bir devlet yok." % me.name))
	else:
		sh.body.add_child(_wrap("Bir devletin tarihî topraklarının yeterli kısmını ele geçirince o devleti formlayabilirsin: ülke adı ve bayrağı değişir, o topraklar öz toprak sayılır, istikrar ve hazine artar."))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, clampf(ui.get_viewport().get_visible_rect().size.y * 0.5, 200.0, 480.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	sc.add_child(box)
	sh.body.add_child(sc)
	for f in list:
		var pr: Dictionary = Formables.progress(gs, f)
		var pnl := PanelContainer.new()
		pnl.add_theme_stylebox_override("panel", TK.box(Color(0, 0, 0, 0.22), TK.LINE, 4, 1, 12))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		pnl.add_child(v)
		v.add_child(TK.t(f.name, "bodyb", TK.TEXT))
		v.add_child(_wrap(f.desc))
		var pb := ProgressBar.new()
		pb.min_value = 0.0
		pb.max_value = float(maxi(pr.need, 1))
		pb.value = minf(float(pr.have), pb.max_value)
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 14)
		var col: Color = TK.GREEN if pr.ok else TK.BLUE
		pb.add_theme_stylebox_override("background", TK.box(Color(0, 0, 0, 0.35), TK.LINE, 2, 1, 0))
		pb.add_theme_stylebox_override("fill", TK.box(col, col, 2, 0, 0))
		v.add_child(pb)
		v.add_child(TK.t("%d / %d eyalet gerekli (toplam %d)" % [pr.have, pr.need, pr.total], "small", col))
		if not pr.ok:
			var mo: Array = Formables.missing_by_owner(gs, f)
			var parts: Array = []
			for e in mo.slice(0, 6):
				parts.append("%s (%d)" % [e[0], e[1]])
			if not parts.is_empty():
				v.add_child(_wrap(Loc.t("Alınacak yerler (elinde tutan ülke): %s") % ", ".join(parts)))
		var b := TK.button("Formla" if pr.ok else "Henüz yetmiyor", "gold" if pr.ok else "ghost", "flag", Vector2(0, 52), 16)
		b.disabled = not pr.ok
		var fd: Dictionary = f
		b.pressed.connect(func():
			ui._click()
			var err: String = Formables.form(gs, fd)
			if err != "":
				ui.toast(err)
			else:
				ui.toast("%s ilan edildi!" % fd.name)
				ui.refresh_top()
				ui.hide_dialog())
		v.add_child(b)
		var mb := TK.button("Haritada göster", "blue", "map", Vector2(0, 46), 15)
		mb.pressed.connect(func():
			ui._click()
			ui.hide_dialog()
			ui.action.emit("form_view", fd.id))
		v.add_child(mb)
		box.add_child(pnl)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


static func _wrap(text: String) -> Label:
	var l := TK.t(text, "small", TK.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
