extends RefCounted
## Filo eylemlerinin diyalogları (kıyı bombardımanı, torpido, gemiye bin, karaya çık). Kart düğmeleri ui.gd'de, emirler fleets.gd'de.

const Fleets = preload("res://scripts/fleets.gd")
const Seas = preload("res://scripts/seas.gd")
const Macro = preload("res://scripts/macro.gd")
const Icons = preload("res://scripts/icons.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const FleetFlag = preload("res://scripts/fleet_flag.gd")
const FlagEditor = preload("res://scripts/flag_editor.gd")

const MAX_BUTTONS := 4


static func _cancel() -> Dictionary:
	return {"text": "Vazgeç", "cb": func(): pass, "kind": "ghost"}


## Kıyı bombardımanı: hedef eyalet seç (arg >= 0: doğrudan bu eyalet)
static func bombard(ui, gs, f, done: Callable, pid: int = -1) -> void:
	if pid >= 0:
		_do_bombard(ui, gs, f, pid, done)
		return
	var targets: Array = Fleets.bombard_targets(gs, f)
	if targets.is_empty():
		ui.toast("Bombalanacak düşman kıyı eyaleti yok: filoyu düşman kıyısına bitişik bir denize götür.")
		return
	if f.cd > gs.turn:
		ui.toast("Filo hazırlanıyor (%d hafta)." % (f.cd - gs.turn))
		return
	targets.sort_custom(func(a, b):
		var sa: int = gs.armies[a].size if gs.armies.has(a) and gs.armies[a].owner != f.owner else 0
		var sb: int = gs.armies[b].size if gs.armies.has(b) and gs.armies[b].owner != f.owner else 0
		return sa > sb)
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, targets.size()):
		var q: int = targets[i]
		var a = gs.armies.get(q)
		var label: String = gs.provinces[q].name
		if a != null and a.owner != f.owner:
			label = "%s (%s asker)" % [gs.provinces[q].name, Macro.compact(float(a.size))]
		btns.append({"text": label, "kind": "danger", "icon": Icons.pick("bombard", "ship"), "cb": func(): _do_bombard(ui, gs, f, q, done)})
	ui.show_dialog("Kıyı bombardımanı", "Filo kıyıdaki orduyu ve savunmayı topa tutar; bombalanan eyalette kuşatma hızlanır. Bedel: %s; filo %d hafta bekler." % [Macro.money(Fleets.bombard_cost(gs, f.owner)), Fleets.BOMBARD_CD], btns, "carrier", "")


static func _do_bombard(ui, gs, f, pid: int, done: Callable) -> void:
	var r: Dictionary = Fleets.player_bombard(gs, f.id, pid)
	if r.err != "":
		ui.toast(r.err)
		return
	ui.toast(("Kıyı bombardımanı: düşman %s asker kaybetti." % Macro.num(int(r.killed))) if int(r.killed) > 0 else "Kıyı bombardımanı: hedefte ordu yoktu, kıyı tesisleri vuruldu.")
	done.call()


static func torpedo(ui, gs, f, done: Callable) -> void:
	var r: Dictionary = Fleets.player_torpedo(gs, f.id)
	if r.err != "":
		ui.toast(r.err)
		return
	if int(r.cargo) > 0:
		ui.toast("Torpido isabet etti: düşman %d güç ve %s asker kaybetti." % [int(round(float(r.hit))), Macro.num(int(r.cargo))])
	else:
		ui.toast("Torpido isabet etti: düşman %d güç kaybetti." % int(round(float(r.hit))))
	done.call()


## Limandaki ordu için "Gemiye bin": nakliye filosu (tümü / yarısı) ya da yakındaki bir filoya
static func embark(ui, gs, pid: int, done: Callable) -> void:
	var a = gs.armies.get(pid)
	if a == null or a.owner != gs.player:
		return
	var cap: int = gs.landing_cap(gs.player)
	var btns: Array = [_cancel()]
	btns.append({"text": "Nakliye filosu: tümü", "kind": "gold", "icon": Icons.pick("cargo_ship", "ship"), "cb": func(): _do_embark(ui, gs, pid, 0, -1, done)})
	if a.size >= 400:
		btns.append({"text": "Nakliye filosu: yarısı", "kind": "", "icon": Icons.pick("cargo_ship", "ship"), "cb": func(): _do_embark(ui, gs, pid, a.size / 2, -1, done)})
	var zs: Array = Seas.coast_zones(gs, pid)
	var added := 0
	for f in Fleets.fleets_of(gs, gs.player):
		if f.kind == "sub" or not zs.has(f.zone) or added >= 2 or Fleets.cargo_cap(gs, f) - f.cargo < 500:
			continue
		var fid: int = f.id
		btns.append({"text": "Filoya bin: %s" % Fleets.kind_name(f.kind), "kind": "", "icon": Icons.pick(Fleets.kind_icon(f.kind), "ship"), "cb": func(): _do_embark(ui, gs, pid, 0, fid, done)})
		added += 1
	ui.show_dialog("Gemiye bin", "%s eyaletindeki ordun (%s asker) gemiye binecek. Nakliye filosu otomatik kurulur ya da yakındaki bir filona binersin; denizdeki ordu düşman filosuna karşı savunmasızdır. Taşıma kapasiten: %s asker." % [gs.provinces[pid].name, Macro.num(a.size), Macro.num(cap)], btns, "carrier", "")


static func _do_embark(ui, gs, pid: int, count: int, fid: int, done: Callable) -> void:
	var before: int = 0
	for f in gs.fleets.values():
		before += f.cargo if f.owner == gs.player else 0
	var e: String = Fleets.embark(gs, pid, count, fid)
	if e != "":
		ui.toast(e)
		return
	var after: int = 0
	var last = null
	for f in gs.fleets.values():
		if f.owner == gs.player:
			after += f.cargo
			if f.cargo > 0 and (last == null or f.id > last.id):
				last = f
	ui.toast("Ordu gemiye bindi: %s asker denizde." % Macro.num(after - before))
	done.call(last)


## Filo kartından "Ordu bindir": filonun bitişiğindeki kendi limanlarındaki ordular
static func fleet_embark(ui, gs, f, done: Callable) -> void:
	var cands: Array = []
	for pid in Seas.provs_of(gs, f.zone):
		var a = gs.armies.get(pid)
		if a != null and a.owner == f.owner and gs.provinces[pid].controller == f.owner:
			cands.append(pid)
	if cands.is_empty():
		ui.toast("Bu denize bitişik, ordulu bir limanın yok: filoyu ordunun bulunduğu kıyıya götür.")
		return
	cands.sort_custom(func(x, y): return gs.armies[x].size > gs.armies[y].size)
	var room: int = Fleets.cargo_cap(gs, f) - f.cargo
	if room < 1:
		ui.toast("Filonun taşıma kapasitesi dolu.")
		return
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS - 1, cands.size()):
		var q: int = cands[i]
		var fid: int = f.id
		btns.append({"text": "%s: %s asker" % [gs.provinces[q].name, Macro.compact(float(mini(gs.armies[q].size, room)))], "kind": "gold", "icon": Icons.pick("uc_inf", "users"), "cb": func(): _do_embark(ui, gs, q, 0, fid, done)})
	ui.show_dialog("Ordu bindir", "Kıyıdaki ordun bu filoya biner (kapasite: %s asker). Filo hareket edince ordu onunla birlikte denizde gider." % Macro.num(room), btns, "carrier", "")


static func debark(ui, gs, f, done: Callable, pid: int = -1) -> void:
	if pid >= 0:
		_do_debark(ui, gs, f, pid, done)
		return
	var targets: Array = Fleets.debark_targets(gs, f)
	if f.cargo <= 0:
		ui.toast("Filoda asker yok.")
		return
	if targets.is_empty():
		ui.toast("Çıkarma için bu denize bitişik düşman ya da dost bir kıyı eyaleti yok.")
		return
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, targets.size()):
		var q: int = targets[i]
		var hostile: bool = gs.at_war(gs.player, gs.provinces[q].controller if gs.provinces[q].controller >= 0 else gs.provinces[q].owner)
		btns.append({"text": ("%s (düşman)" if hostile else "%s (dost liman)") % gs.provinces[q].name, "kind": "danger" if hostile else "good", "icon": Icons.pick("landing", "swords"), "cb": func(): _do_debark(ui, gs, f, q, done)})
	ui.show_dialog("Karaya çıkar", "%s asker kıyıya çıkarılacak. Düşman kıyısına çıkarma bedeli %s; çıkarma savunmaya karşı savaşır (taşıma kapasitesi: %s)." % [Macro.num(f.cargo), Macro.money(gs.op_cost("landing")), Macro.num(gs.landing_cap(gs.player))], btns, "carrier", "")


static func _do_debark(ui, gs, f, pid: int, done: Callable) -> void:
	var e: String = Fleets.debark(gs, f.id, pid)
	if e != "":
		ui.toast(e)
		return
	ui.toast("Ordu %s kıyısına çıkarıldı." % gs.provinces[pid].name)
	done.call(null)


# ------------------------------------------------------------------ filo komutanlığı (ad, bayrak, gemiler, duruş, eşlik, bölme)

static func _ship_icon(kind: String) -> String:
	match kind:
		"sub":
			return Icons.pick("uc_sub", "sub")
		"carrier":
			return Icons.pick("uc_carrier", "ship")
		"transport":
			return Icons.pick("cargo_ship", "ship")
		"air":
			return Icons.pick("uc_jet", "jet")
	return Icons.pick("uc_ship", "ship")


static func _sbtn(ui, sh, text: String, icon: String, kind: String, cb: Callable) -> void:
	var b := TK.button(text, kind, icon, Vector2(0, 72), 17)
	b.pressed.connect(func():
		ui._click()
		cb.call())
	sh.body.add_child(b)


static func manage(ui, gs, f, done: Callable) -> void:
	if f == null or not gs.fleets.has(f.id) or f.owner != gs.player:
		return
	var fid: int = f.id
	var oc = gs.countries[f.owner]
	var sh = ui._open_sheet("Filo komutanlığı", 780, true, true, Loc.t(Fleets.kind_name(f.kind)) + "  /  " + Seas.name_of(f.zone))
	# başlık: bayrak + ad
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	var fv := FleetFlag.new()
	fv.spec = f.flag
	fv.country = oc
	fv.custom_minimum_size = Vector2(168, 112)
	head.add_child(fv)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var le := LineEdit.new()
	le.text = Fleets.display_name(gs, f)
	le.placeholder_text = Loc.t("Filo adı")
	le.max_length = 28
	le.custom_minimum_size = Vector2(0, 64)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(le)
	var save_name := func():
		var nm: String = le.text.strip_edges()
		var dflt: String = Fleets.default_display(gs, f)
		Fleets.rename(gs, fid, "" if nm == "" or nm == dflt else nm)
		ui.toast(Loc.t("Filo adı kaydedildi."))
		done.call(null)
		manage(ui, gs, gs.fleets[fid], done)
	le.text_submitted.connect(func(_t): save_name.call())
	var nb := TK.button("Adı kaydet", "", Icons.pick("check", "flag"), Vector2(0, 60), 16)
	nb.pressed.connect(func():
		ui._click()
		save_name.call())
	col.add_child(nb)
	head.add_child(col)
	sh.body.add_child(head)
	# rütbe
	var rl := TK.t("Rütbe: %s  (tecrübe %d)" % [Ext.rank_name(f.xp), int(f.xp)], "body", TK.GOLD)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(rl)
	var nxt: float = Ext.xp_to_next(f.xp)
	if nxt > 0.0:
		sh.body.add_child(TK.t("Sonraki rütbe için %d" % int(ceil(nxt)), "small", TK.FAINT))
	var rh := TK.t(Loc.t("Muharebe ve torpido saldırıları filoya tecrübe kazandırır; rütbe yükseldikçe filo daha güçlü savaşır."), "small", TK.FAINT)
	rh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(rh)
	# gemiler
	sh.body.add_child(TK.hsep())
	var ships: Array = Ext.ships(gs, f)
	sh.body.add_child(TK.t(Loc.t("Filodaki gemiler") + "  (%d)" % Ext.ship_total(gs, f), "kicker", TK.GOLD))
	for sp in ships:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var iv := TK.IconView.new()
		iv.icon = _ship_icon(String(sp[3]))
		iv.color = TK.PAPER
		iv.stroke = 2.0
		iv.custom_minimum_size = Vector2(34, 34)
		iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(iv)
		var nm: Label = TK.t(Loc.t(String(sp[1])), "body", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(nm)
		row.add_child(TK.t("x%d" % int(sp[2]), "value", TK.GOLD))
		sh.body.add_child(row)
	# durum
	sh.body.add_child(TK.hsep())
	var hops: int = Fleets.supply_hops(gs, f)
	var sup: float = Ext.supply_mult_for(f.kind, hops)
	var stats := "%s: %d    %s: %s%s    %s: %d" % [Loc.t("Güç"), Fleets.disp(f), Loc.t("İkmal"), Loc.t(Ext.supply_label(hops)), (" (x%.2f)" % sup) if sup < 0.995 else "", Loc.t("Hız"), int(Fleets.SPEED.get(f.kind, 2))]
	if f.cargo > 0:
		stats += "    %s: %s" % [Loc.t("Asker"), Macro.num(f.cargo)]
	var sl := TK.t(stats, "body", TK.TEXT)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(sl)
	if hops > 2:
		var wl := TK.t(Loc.t("Limandan uzak: ikmal zayıf, filo gücünün bir kısmını kaybediyor. Dost bir limana yaklaştır."), "small", TK.ORANGE)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(wl)
	# duruş
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t(Loc.t("Duruş"), "kicker", TK.GOLD))
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	for st in Ext.STANCES:
		var sb := TK.button(String(Ext.STANCE_TR[st]), "gold" if f.stance == st else "", "", Vector2(0, 64), 16)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stn: String = st
		sb.pressed.connect(func():
			ui._click()
			Fleets.set_stance(gs, fid, stn)
			done.call(null)
			manage(ui, gs, gs.fleets[fid], done))
		srow.add_child(sb)
	sh.body.add_child(srow)
	var hl := TK.t(Loc.t(String(Ext.STANCE_HINT[f.stance])), "small", TK.FAINT)
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(hl)
	# eylemler
	sh.body.add_child(TK.hsep())
	_sbtn(ui, sh, "Bayrak tasarla", Icons.pick("flag", "flag"), "blue", func():
		FlagEditor.open(ui.root, f.flag, func(spec: String):
			Fleets.set_flag(gs, fid, spec)
			ui.toast(Loc.t("Filo bayrağı kaydedildi."))
			done.call(null)
			if gs.fleets.has(fid):
				manage(ui, gs, gs.fleets[fid], done)))
	if f.flag != "":
		_sbtn(ui, sh, "Ülke bayrağına dön", Icons.pick("x", "x"), "ghost", func():
			Fleets.set_flag(gs, fid, "")
			done.call(null)
			manage(ui, gs, gs.fleets[fid], done))
	_sbtn(ui, sh, "Filoyu böl", Icons.pick("plus", "plus"), "", func():
		split_dialog(ui, gs, f, done))
	if f.escort >= 0 and gs.fleets.has(f.escort):
		_sbtn(ui, sh, "Eşliği bırak", Icons.pick("x", "x"), "ghost", func():
			Fleets.set_escort(gs, fid, -1)
			done.call(null)
			manage(ui, gs, gs.fleets[fid], done))
	elif f.kind != "transport":
		var cands: Array = Fleets.escort_candidates(gs, f)
		for i in mini(3, cands.size()):
			var tg = cands[i]
			var tid: int = tg.id
			_sbtn(ui, sh, Loc.t("Eşlik et: %s") % Fleets.display_name(gs, tg), Icons.pick("shield", "shield"), "", func():
				var err: String = Fleets.set_escort(gs, fid, tid)
				if err != "":
					ui.toast(err)
					return
				ui.toast(Loc.t("Filo eşlik görevinde: hedef filoyu izler ve korur."))
				done.call(null)
				manage(ui, gs, gs.fleets[fid], done))
	sh.add_button("Kapat", func(): done.call(null), "", true, "x", 160)


static func split_dialog(ui, gs, f, done: Callable) -> void:
	var fid: int = f.id
	var btns: Array = [_cancel()]
	for pct in [25, 50, 75]:
		var fr: float = float(pct) / 100.0
		btns.append({"text": Loc.t("Filonun %s kadarını ayır") % Loc.pct(pct), "kind": "", "icon": Icons.pick("plus", "plus"), "cb": func():
			var nf = Fleets.split(gs, fid, fr)
			if nf == null:
				ui.toast(Loc.t("Filo bölünemiyor: çok küçük ya da filo sayısı sınırda."))
				return
			ui.toast(Loc.t("Filo bölündü: yeni filo oluşturuldu."))
			done.call(nf)})
	ui.show_dialog("Filoyu böl", "Filonun seçtiğin kadarı yeni bir filo olarak ayrılır; ayrı görev verebilirsin. Uçak gemisi gruplarında en az 2 gemi gerekir.", btns, "carrier", "")
