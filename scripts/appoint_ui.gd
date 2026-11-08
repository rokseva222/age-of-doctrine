extends RefCounted
## Bakan atama penceresi: 3 aday. En usta pahalı, en acemi ucuz (ama riskli), ortadaki orta.

const TK = preload("res://scripts/theme_kit.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Sil = preload("res://scripts/silhouette.gd")
const Names = preload("res://scripts/names.gd")
const Macro = preload("res://scripts/macro.gd")


static func open(ui, gs, role: String):
	var me = gs.countries[gs.player]
	var sh = ui._open_sheet("Kabine değişikliği", 1020, false, false, "%s  /  %s" % [Names.date_string(gs.turn), me.name])
	var intro: Label = sh.add_text(Cabinet.vacancy_text(gs, role), 24, TK.TEXT)
	intro.custom_minimum_size = Vector2(700, 0)
	var cands: Array = Cabinet.candidates(gs, role)
	var done := false
	for cd in cands:
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 128)
		var hb := TK.row_layout(b, 16)
		var pt = Sil.new()
		pt.style = Sil.style_for(me)
		pt.culture = Sil.culture_for(me)
		pt.seed_name = cd.n
		pt.female = cd.f
		pt.role = role
		pt.tint = me.color
		pt.custom_minimum_size = Vector2(92, 110)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(pt)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 2)
		var nm := TK.t(cd.n, "h3", TK.TEXT)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tv.add_child(nm)
		var bio := TK.t(cd.bio, "small", TK.MUTED)
		bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio.custom_minimum_size = Vector2(380, 0)
		tv.add_child(bio)
		var fx := TK.t(Cabinet.ROLE_FX[role][cd.q] + ("   ·   skandal riski" if cd.q == 0 else ""), "kicker", TK.GREEN if cd.q > 0 else TK.RED_TEXT)
		tv.add_child(fx)
		hb.add_child(tv)
		var rv := VBoxContainer.new()
		rv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rv.custom_minimum_size = Vector2(170, 0)
		rv.add_theme_constant_override("separation", 4)
		var stars := HBoxContainer.new()
		stars.add_theme_constant_override("separation", 2)
		stars.alignment = BoxContainer.ALIGNMENT_END
		for i in 3:
			var st := TK.IconView.new()
			st.icon = "star"
			st.color = TK.GOLD if i <= cd.q else Color(1, 1, 1, 0.14)
			st.custom_minimum_size = Vector2(26, 26)
			stars.add_child(st)
		rv.add_child(stars)
		var ql := TK.t(Cabinet.Q_NAME[cd.q], "kicker", TK.MUTED)
		ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rv.add_child(ql)
		var cl := TK.t(Macro.money(cd.cost) if cd.cost > 0.5 else "Ücretsiz", "value", TK.GOLD if cd.afford else TK.RED_TEXT)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cl.add_theme_font_size_override("font_size", 24)
		rv.add_child(cl)
		hb.add_child(rv)
		TK.ignore_mouse(hb)
		if not cd.afford:
			b.disabled = true
		var cand: Dictionary = cd
		b.pressed.connect(func():
			if done:
				return
			done = true
			ui._click()
			Cabinet.appoint(gs, role, cand)
			gs.state_changed.emit()
			sh.can_close = true
			sh.close())
		sh.body.add_child(b)
	return sh
