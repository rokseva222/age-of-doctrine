extends RefCounted
## Kabine kartı penceresi: solda yüzsüz siluet portre, sağda bakanın sorusu ve seçenekler.
## Seçimden sonra sonuç özeti gösterilir. Riskli seçeneklerde ☠ uyarısı vardır.

const TK = preload("res://scripts/theme_kit.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Sil = preload("res://scripts/silhouette.gd")
const Names = preload("res://scripts/names.gd")

const STAT_ICON := {"mit": "shield", "g": "coins", "stab": "stability", "cyb": "hacker", "ind": "industry", "log": "truck", "tech": "flask",
	"troops": "infantry", "unrest": "unrest", "aggr": "flag", "dev": "city", "nbstab": "spy", "elect": "ballot"}


## Pencereyi açar ve sheet nesnesini döndürür (closed sinyali beklenebilir).
static func open(ui, gs, card: Dictionary, rng: RandomNumberGenerator, on_fatal: Callable):
	var me = gs.countries[gs.player]
	var role: String = card.role
	var mn: Array = Cabinet.minister_of(me, role, gs.turn)
	var title: String = Cabinet.ROLE_TITLE[role]
	var sh = ui._open_sheet(card.get("title", "Kabine toplantısı"), 980, false, false, "%s  /  %s" % [Names.date_string(gs.turn), me.name])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	sh.body.add_child(row)
	# --- portre
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", TK.line_box(Color(0, 0, 0, 0.25), TK.LINE))
	row.add_child(pc)
	var pt = Sil.new()
	pt.style = card.get("style", Sil.style_for(me))
	pt.culture = Sil.culture_for(me) if role != "trd" else Sil.CULTURES[absi(hash(mn[0])) % Sil.CULTURES.size()]
	pt.seed_name = mn[0]
	pt.female = mn[1]
	pt.role = role
	pt.tint = me.color
	pt.custom_minimum_size = Vector2(230, 276)
	pc.add_child(pt)
	# --- sağ
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	right.add_child(TK.t(title if mn[0] != "" else "Kabine üyesi", "kicker", TK.GOLD))
	var nm: String = mn[0] if mn[0] != "" else title
	var nl := TK.t(nm, "h2", TK.TEXT)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(nl)
	right.add_child(TK.hsep())
	var q := TK.t(Cabinet.fill(gs, card.q, rng), "body", TK.TEXT)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.add_theme_font_size_override("font_size", 25)
	q.custom_minimum_size = Vector2(560, 0)
	right.add_child(q)
	var opts := VBoxContainer.new()
	opts.add_theme_constant_override("separation", 8)
	right.add_child(opts)
	var done := false
	for opt in card.o:
		var fatal: float = Cabinet.fatal_chance(gs, opt)
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 70)
		var hb := TK.row_layout(b, 14)
		var tl := TK.t(opt.t, "bodyb", TK.TEXT)
		tl.add_theme_font_size_override("font_size", 23)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tl.clip_text = true
		tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(tl)
		# etkilenen alanlar: yalnızca simge (yön gizli, Reigns tarzı)
		var keys: Array = opt.e.keys()
		if opt.has("gamble"):
			for gk in ["win", "lose"]:
				for k2 in opt.gamble[gk]:
					if not keys.has(k2):
						keys.append(k2)
		for k in keys:
			var iv := TK.IconView.new()
			iv.icon = STAT_ICON.get(k, "star")
			iv.color = TK.MUTED
			iv.custom_minimum_size = Vector2(26, 26)
			iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(iv)
		if opt.has("gamble"):
			var dice := TK.t("%%%d" % int(round(float(opt.gamble.p) * 100.0)), "kicker", TK.GOLD)
			dice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(dice)
		if fatal > 0.0:
			var sk := TK.IconView.new()
			sk.icon = "skull"
			sk.color = TK.RED
			sk.custom_minimum_size = Vector2(30, 30)
			sk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(sk)
		TK.ignore_mouse(hb)
		var o: Dictionary = opt
		b.pressed.connect(func():
			if done:
				return
			done = true
			ui._click()
			_resolve(ui, gs, sh, right, card, o, fatal, rng, on_fatal))
		opts.add_child(b)
	return sh


static func _resolve(ui, gs, sh, right: VBoxContainer, card: Dictionary, opt: Dictionary, fatal: float, rng: RandomNumberGenerator, on_fatal: Callable) -> void:
	var died := fatal > 0.0 and rng.randf() < fatal
	for ch in right.get_children():
		if ch is VBoxContainer and ch.get_child_count() > 0 and ch.get_child(0) is Button:
			ch.queue_free()
	var res: Dictionary = Cabinet.resolve(gs, rng, card, opt) if not died else {"r": "", "chips": []}
	var chips: Array = res.chips
	var rt := TK.t(res.r if not died else opt.fatal.text, "body", TK.RED_TEXT if died else TK.TEXT)
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.add_theme_font_size_override("font_size", 25)
	right.add_child(TK.spacer(0, 6))
	var head_txt := "Karar uygulandı"
	if died:
		head_txt = "Kader anı"
	elif opt.has("gamble"):
		head_txt = "Şans güldü" if res.get("win", true) else "Olmadı"
	right.add_child(TK.t(head_txt, "kicker", TK.GOLD if (not died and res.get("win", true)) else TK.RED_TEXT))
	right.add_child(rt)
	if not died and not chips.is_empty():
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 20)
		fl.add_theme_constant_override("v_separation", 8)
		for c in chips:
			var ch2 := TK.chip(c.ic, c.txt, TK.GREEN if c.good else TK.RED_TEXT, TK.GREEN if c.good else TK.RED_TEXT)
			fl.add_child(ch2)
		right.add_child(fl)
	if ui.sfx != null:
		ui.sfx.play("stamp" if not died else "lose", 0.8)
	gs.state_changed.emit()
	sh.can_close = true
	sh.add_button("Tamam", func():
		if died:
			on_fatal.call(opt.fatal.text), "gold" if not died else "danger", true, "check", 200)
