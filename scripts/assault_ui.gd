extends RefCounted
const Loc = preload("res://scripts/loc.gd")
## Taarruz harekâtı penceresi: hedef bilgisi, kuvvet seçimi, harekât türü, tahmini üstünlük.
## Emir verilince ordular hedefe yürür; sonuç "Turu Geç" sonrası haber/rapor ekranında görünür.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const SceneArt = preload("res://scripts/scene_art.gd")


static func open(ui, gs, pid: int, on_done: Callable) -> void:
	var p = gs.provinces[pid]
	var oc = gs.countries[p.controller if p.controller >= 0 else p.owner]
	var near: Array = gs.armies_near(pid, 6)
	var st := {"sel": {}, "op": "assault", "frac": 1.0}
	# en yakın ve en güçlü orduyu önceden seç
	var best = null
	for e in near:
		if best == null or e.hops < best.hops or (e.hops == best.hops and e.army.size > best.army.size):
			best = e
	if best != null:
		st.sel[best.army.id] = true
	var sh = ui._open_sheet("Taarruz harekâtı", 1020, false, true, "%s  /  %s" % [oc.name, p.name])
	var ui_parts := {}
	var banner = SceneArt.make("assault", 132)
	sh.body.add_child(banner)
	var target_row := HBoxContainer.new()
	sh.body.add_child(target_row)
	sh.body.add_child(TK.hsep())
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 22)
	sh.body.add_child(mid)
	# sol: kuvvetler + tahmin
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(430, 0)
	mid.add_child(left)
	left.add_child(TK.t("Kuvvetler (dokunarak seç)", "kicker"))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 188)
	var force_box := VBoxContainer.new()
	force_box.add_theme_constant_override("separation", 4)
	force_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(force_box)
	left.add_child(sc)
	var frac_row: HBoxContainer = TK.slider_row("Gönderilen", 1.0, func(v: float):
		st.frac = v
		if ui_parts.has("odds"):
			_render(ui, gs, pid, near, st, ui_parts), 0.1, 1.0, 0.05)
	(frac_row.get_child(0) as Label).custom_minimum_size = Vector2(130, 0)
	left.add_child(frac_row)
	var odds_box := VBoxContainer.new()
	odds_box.add_theme_constant_override("separation", 6)
	left.add_child(odds_box)
	mid.add_child(TK.vsep())
	# sağ: harekât türü
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(right)
	right.add_child(TK.t("Harekât türü", "kicker"))
	var ops_box := VBoxContainer.new()
	ops_box.add_theme_constant_override("separation", 6)
	right.add_child(ops_box)
	var go: Button = sh.add_button("Harekâtı başlat", func():
		var ids: Array = st.sel.keys()
		var res: Dictionary = gs.player_launch_assault(pid, ids, st.op, st.frac)
		on_done.call(res), "danger", true, "swords", 280)
	sh.add_button("Vazgeç", func(): pass, "ghost", true, "", 150)
	ui_parts.merge({"banner": banner, "target": target_row, "force": force_box, "scroll": sc, "odds": odds_box, "ops": ops_box, "go": go})
	_render(ui, gs, pid, near, st, ui_parts)


static func _selected(near: Array, st: Dictionary) -> Array:
	var out: Array = []
	for e in near:
		if st.sel.has(e.army.id):
			out.append(e.army)
	return out


static func _clear(n: Node) -> void:
	for ch in n.get_children():
		n.remove_child(ch)
		ch.queue_free()


static func _render(ui, gs, pid: int, near: Array, st: Dictionary, parts: Dictionary) -> void:
	var p = gs.provinces[pid]
	var armies: Array = _selected(near, st)
	var sea_ids := {}
	for e0 in near:
		if e0.get("sea", false):
			sea_ids[e0.army.id] = true
	var all_sea: bool = not armies.is_empty() and armies.all(func(a): return sea_ids.has(a.id))
	var any_sea: bool = armies.any(func(a): return sea_ids.has(a.id))
	if not gs.op_available(st.op, p, armies, st.frac):
		st.op = "assault"
	var est: Dictionary = gs.assault_estimate(pid, armies, "landing" if all_sea else st.op, st.frac)
	if parts.has("banner"):
		parts.banner.kind = SceneArt.for_op(st.op)
	var sc: ScrollContainer = parts.scroll
	var keep_scroll: int = sc.scroll_vertical
	for k in ["target", "force", "odds", "ops"]:
		_clear(parts[k])
	var redo := func():
		_render(ui, gs, pid, near, st, parts)
	# --- hedef
	var tr: HBoxContainer = parts.target
	var holder = gs.countries[est.holder]
	var fl := TK.flag_rect(holder, Vector2(66, 44))
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.add_child(fl)
	tr.add_child(TK.spacer(16, 0))
	var cells: Array = [
		["Savunan", Macro.num(est.def) if est.def > 0 else "Boş", TK.TEXT],
		["Eyalet savunması", "%d" % p.defense, TK.TEXT],
		["Kuşatma süresi", "%d hf" % p.siege_needed(), TK.TEXT],
		["Gelir", Macro.money(p.rev()) + Loc.t("/hf"), TK.GOLD],
	]
	for i in cells.size():
		if i > 0:
			tr.add_child(TK.vsep())
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 0 if i == 0 else 22)
		m.add_theme_constant_override("margin_right", 22)
		m.add_child(TK.stat(cells[i][0], cells[i][1], cells[i][2]))
		tr.add_child(m)
	# --- kuvvetler
	var fb: VBoxContainer = parts.force
	if near.is_empty():
		var l := TK.t("Yakında ordun yok. Ordularını hedefe 6 eyalet mesafeye getir ya da yeni birlik kur.", "small", TK.RED_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fb.add_child(l)
	for e in near:
		var a = e.army
		var on: bool = st.sel.has(a.id)
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 56)
		TK.row_select(b, on, TK.PAPER)
		var hb := TK.row_layout(b, 12)
		var ck := TK.IconView.new()
		ck.icon = "check" if on else "plus"
		ck.color = TK.GREEN if on else TK.FAINT
		ck.custom_minimum_size = Vector2(24, 24)
		ck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ck)
		var nm := TK.t(gs.provinces[a.prov].name, "bodyb", TK.TEXT)
		nm.add_theme_font_size_override("font_size", 22)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(nm)
		var sz := TK.t(Macro.num(a.size), "mono", TK.GOLD)
		sz.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(sz)
		var eta := TK.t("Deniz" if e.get("sea", false) else "%d hf" % e.hops, "mono", TK.BLUE if e.get("sea", false) else TK.MUTED)
		eta.custom_minimum_size = Vector2(52, 0)
		eta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		eta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(eta)
		TK.ignore_mouse(hb)
		var aid: int = a.id
		b.pressed.connect(func():
			ui._click()
			if st.sel.has(aid):
				st.sel.erase(aid)
			else:
				st.sel[aid] = true
			redo.call())
		fb.add_child(b)
	sc.set_deferred("scroll_vertical", keep_scroll)
	# --- harekât türü
	var ob: VBoxContainer = parts.ops
	for op in gs.OP_ORDER:
		if not gs.op_available(op, p, armies, st.frac):
			continue
		var o: Dictionary = gs.OPS[op]
		var cost: float = gs.op_cost(op)
		var can: bool = gs.countries[gs.player].gold >= cost
		var on2: bool = st.op == op
		var b2 := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 84)
		TK.row_select(b2, on2, TK.PAPER)
		var h2 := TK.row_layout(b2, 12)
		var ic := TK.IconView.new()
		ic.icon = o.icon
		ic.color = TK.PAPER if on2 else TK.MUTED
		ic.custom_minimum_size = Vector2(30, 30)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h2.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_theme_constant_override("separation", -2)
		var nl := TK.t(o.name, "caps", TK.TEXT if can else TK.FAINT)
		nl.add_theme_font_size_override("font_size", 26)
		v.add_child(nl)
		var d := TK.t(o.desc, "small", TK.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 16)
		v.add_child(d)
		h2.add_child(v)
		var cl := TK.t("Ücretsiz" if cost <= 0.0 else Macro.money(cost), "mono", TK.GOLD if can else TK.RED_TEXT)
		cl.add_theme_font_size_override("font_size", 18)
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h2.add_child(cl)
		TK.ignore_mouse(h2)
		b2.disabled = not can
		b2.pressed.connect(func():
			ui._click()
			st.op = op
			redo.call())
		ob.add_child(b2)
	# --- tahmin
	var xb: VBoxContainer = parts.odds
	xb.add_child(TK.t("Tahmini üstünlük", "kicker"))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 3)
	var ratio: float = clampf(est.ratio, 0.04, 0.96) if not armies.is_empty() else 0.0
	var ca := ColorRect.new()
	ca.color = TK.GREEN if ratio >= 0.5 else TK.ORANGE
	ca.custom_minimum_size = Vector2(0, 18)
	ca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ca.size_flags_stretch_ratio = maxf(ratio, 0.001)
	var cd := ColorRect.new()
	cd.color = TK.RED
	cd.custom_minimum_size = Vector2(0, 18)
	cd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cd.size_flags_stretch_ratio = maxf(1.0 - ratio, 0.001)
	if armies.is_empty():
		ca.color = TK.PANEL_HI
		cd.color = TK.PANEL_HI
		ca.size_flags_stretch_ratio = 1.0
		cd.size_flags_stretch_ratio = 1.0
	bar.add_child(ca)
	bar.add_child(cd)
	xb.add_child(bar)
	var verdict := ""
	var vcol: Color = TK.MUTED
	if armies.is_empty():
		verdict = "En az bir ordu seç."
	elif est.empty:
		verdict = "Savunmasız: ordu yürür, kuşatma başlar."
		vcol = TK.GREEN
	else:
		var r: float = est.ratio
		if r >= 0.72:
			verdict = "Ezici üstünlük"
			vcol = TK.GREEN
		elif r >= 0.58:
			verdict = "Üstünlük"
			vcol = TK.GREEN
		elif r >= 0.45:
			verdict = "Dengeli: şansa bağlı"
			vcol = TK.GOLD
		elif r >= 0.3:
			verdict = "Zor: kayıp ağır olabilir"
			vcol = TK.ORANGE
		else:
			verdict = "Çok riskli: yenilgi bekleniyor"
			vcol = TK.RED_TEXT
	var vl := TK.t(verdict, "caps", vcol)
	vl.add_theme_font_size_override("font_size", 30)
	vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # uzun dillerde sol sütunu şişirip harekât listesini ezmesin
	xb.add_child(vl)
	if not armies.is_empty() and not est.empty:
		var ml := TK.t("Taarruz %sK  /  Savunma %sK" % [Macro.num(est.ap / 1000.0), Macro.num(est.dp / 1000.0)], "mono", TK.MUTED)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		xb.add_child(ml)
	if any_sea:
		var cap_l := TK.t("Amfibi çıkarma: taşıma kapasitesi %s asker" % Macro.num(gs.landing_cap(gs.player)), "small", TK.BLUE)
		cap_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		xb.add_child(cap_l)
	(parts.go as Button).disabled = armies.is_empty()
