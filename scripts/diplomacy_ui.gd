extends RefCounted
## Diplomasi ekranı: ülkelerle ilişki kademeleri, ilişki geliştirme (elçi / hediye / anlaşma), ittifak, geçiş izni, barış.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const Icons = preload("res://scripts/icons.gd")
const Formables = preload("res://scripts/formables.gd")

const FILTERS := ["Komşular", "Müttefikler", "Savaşta", "Tümü"]
static var _filter := 0


static func tier_color(r: float) -> Color:
	if r < 25.0:
		return TK.RED_TEXT
	if r < 50.0:
		return TK.MUTED
	if r < 75.0:
		return TK.BLUE
	return TK.GREEN


static func _bar(r: float) -> Control:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = r
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 14)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.add_theme_stylebox_override("background", TK.box(Color(0, 0, 0, 0.35), TK.LINE, 2, 1, 0))
	pb.add_theme_stylebox_override("fill", TK.box(tier_color(r), tier_color(r), 2, 0, 0))
	return pb


## Liste ya da (focus >= 0 ise) ülke ayrıntısı açar.
static func open(ui, gs, focus: int = -1) -> void:
	if gs == null or gs.player < 0:
		return
	if focus >= 0 and focus != gs.player:
		_detail(ui, gs, focus)
	else:
		_list(ui, gs)


static func _candidates(gs) -> Array:
	var me: int = gs.player
	var out: Array = []
	var nbs: Array = gs.neighbor_countries(me)
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.id == me:
			continue
		match _filter:
			0:
				if not nbs.has(c.id):
					continue
			1:
				if not gs.is_allied(me, c.id):
					continue
			2:
				if not gs.at_war(me, c.id):
					continue
		out.append(c)
	out.sort_custom(func(a, b): return gs.relation_of(me, a.id) > gs.relation_of(me, b.id) if _filter != 3 else a.prov_owned > b.prov_owned)
	return out


static func _list(ui, gs) -> void:
	var sh = ui._open_sheet("Diplomasi", 900, true, true, "İlişkiler")
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	sh.body.add_child(chips)
	for i in FILTERS.size():
		var idx: int = i
		var b := TK.button(FILTERS[i], "gold" if _filter == i else "ghost", "", Vector2(0, 48), 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			ui._click()
			_filter = idx
			_list(ui, gs))
		chips.add_child(b)
	sh.body.add_child(TK.spacer(0, 6))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, clampf(ui.get_viewport().get_visible_rect().size.y * 0.5, 220.0, 520.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	sc.add_child(box)
	sh.body.add_child(TK.search_field(box, "Ülke ara..."))
	sh.body.add_child(sc)
	var list: Array = _candidates(gs)
	if list.is_empty():
		box.add_child(TK.t("Bu listede ülke yok.", "small", TK.FAINT))
	for c in list:
		var cid: int = c.id
		var r: float = gs.relation_of(gs.player, cid)
		var rb := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
		var hb := TK.row_layout(rb, 12)
		var fl := TK.flag_rect(c, Vector2(48, 32))
		fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(fl)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_theme_constant_override("separation", 2)
		var nm := TK.t(c.name, "bodyb", TK.TEXT)
		nm.clip_text = true
		v.add_child(nm)
		v.add_child(_bar(r))
		hb.add_child(v)
		var tl := TK.t(gs.relation_tier_name(gs.player, cid), "small", tier_color(r))
		tl.custom_minimum_size = Vector2(110, 0)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(tl)
		TK.ignore_mouse(hb)
		rb.pressed.connect(func():
			ui._click()
			_detail(ui, gs, cid))
		box.add_child(rb)
	if not Formables.available(gs).is_empty():
		sh.add_button("Ülke formla", func(): ui.FormationUI.open(ui, gs), "gold", true, "flag", 170)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


static func _detail(ui, gs, cid: int) -> void:
	var c = gs.countries[cid]
	var me: int = gs.player
	var r: float = gs.relation_of(me, cid)
	var sh = ui._open_sheet(c.name, 900, true, true, "Diplomasi")
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	var fl := TK.flag_rect(c, Vector2(84, 56))
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(fl)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	var ld: Array = Macro.leader_of(c)
	if ld[1] != "":
		var ll := TK.t("%s: %s" % [ld[0], ld[1]], "bodyb", TK.TEXT)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(ll)
	var tier := TK.t("%s  (%d / 100)" % [gs.relation_tier_name(me, cid), int(r)], "h3", tier_color(r))
	info.add_child(tier)
	info.add_child(_bar(r))
	var st := ""
	if gs.at_war(me, cid):
		st = "Savaştasınız"
	elif gs.is_allied(me, cid):
		st = "Müttefiksiniz"
	else:
		var tl: int = int(gs.countries[me].truce.get(cid, -1)) - gs.turn
		if tl > 0:
			st = "Ateşkes: %d hafta" % tl
		elif gs.has_passage(me, cid):
			st = "Geçiş izni var"
	if st != "":
		var sl := TK.t(st, "small", TK.MUTED)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(sl)
	head.add_child(info)
	sh.body.add_child(head)
	sh.body.add_child(TK.hsep())
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, clampf(ui.get_viewport().get_visible_rect().size.y * 0.42, 200.0, 440.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	sc.add_child(box)
	sh.body.add_child(sc)

	box.add_child(TK.t("İlişkileri geliştir", "kicker", TK.GOLD))
	var war: bool = gs.at_war(me, cid)
	for kind in gs.DIPLO_ACTS.keys():
		var k: String = kind
		var act: Dictionary = gs.DIPLO_ACTS[k]
		var left: int = gs.diplo_left(k, cid)
		var cost: float = gs.diplo_cost(k)
		var rb := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
		var hb := TK.row_layout(rb, 12)
		var ic: TK.IconView = TK.IconView.new()
		ic.icon = Icons.pick(act.icon, "handshake")
		ic.color = Color.WHITE
		ic.custom_minimum_size = Vector2(40, 40)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(TK.t(act.name, "bodyb", TK.TEXT))
		var sub := "+%d ilişki   /   %s" % [int(act.rel), Macro.money(cost)]
		if left > 0:
			sub = "%d hafta sonra tekrar" % left
		var sb := TK.t(sub, "small", TK.MUTED)
		sb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(sb)
		hb.add_child(tv)
		TK.ignore_mouse(hb)
		rb.disabled = war or left > 0
		rb.pressed.connect(func():
			ui._click()
			var e: String = gs.player_improve_relations(cid, k)
			ui.toast(e if e != "" else "%s: ilişkiler gelişti." % c.name)
			_detail(ui, gs, cid))
		box.add_child(rb)

	box.add_child(TK.spacer(0, 6))
	box.add_child(TK.t("Anlaşmalar", "kicker", TK.BLUE))
	if war:
		box.add_child(_act_btn(ui, "Barış teklif et", "good", "handshake", func(): ui.action.emit("peace", cid), sh))
	elif gs.is_allied(me, cid):
		box.add_child(_act_btn(ui, "İttifakı boz", "ghost", "x", func(): ui.action.emit("break_alliance", cid), sh))
	else:
		var need: float = gs.RELATION_ALLIANCE_MIN
		var al := TK.button("İttifak teklif et" + ("" if r >= need else "  (en az %d ilişki)" % int(need)), "blue", "handshake", Vector2(0, 56), 17)
		al.disabled = r < need
		al.pressed.connect(func():
			ui._click()
			var e2: String = gs.player_propose_alliance(cid)
			ui.toast(e2 if e2 != "" else "İttifak kuruldu!")
			_detail(ui, gs, cid))
		box.add_child(al)
		if not gs.has_passage(me, cid):
			box.add_child(_act_btn(ui, "Geçiş izni iste", "", Icons.pick("passage_grant", "flag"), func():
				var e3: String = gs.player_request_passage(cid)
				ui.toast(e3 if e3 != "" else "Geçiş izni verildi (26 hafta).")
				_detail(ui, gs, cid), sh, false))
		var tl2: int = int(gs.countries[me].truce.get(cid, -1)) - gs.turn
		if tl2 <= 0:
			box.add_child(_act_btn(ui, "Savaş ilan et", "danger", "sword", func(): ui.action.emit("war", cid), sh))
	sh.add_button("Haritada göster", func(): ui.action.emit("rel_view", cid), "blue", true, "handshake", 230)
	sh.add_button("Ülke özeti", func(): ui.show_relations(cid), "ghost", true, "", 170)
	sh.add_button("Liste", func(): _list(ui, gs), "ghost", true, "", 130)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 130)


static func _act_btn(ui, text: String, kind: String, icon: String, cb: Callable, sh, close: bool = true) -> Button:
	var b := TK.button(text, kind, icon, Vector2(0, 56), 17)
	b.pressed.connect(func():
		ui._click()
		if close:
			sh.close()
		cb.call())
	return b
