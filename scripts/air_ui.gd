extends RefCounted
## Hava kanadı diyalogları: komutanlık (ad, bayrak, uçaklar, duruş), saldırı, üs değiştirme, hava köprüsü.
## Kart düğmeleri ui.gd'de, emirler air.gd'de.

const Air = preload("res://scripts/air.gd")
const Macro = preload("res://scripts/macro.gd")
const Icons = preload("res://scripts/icons.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const FleetFlag = preload("res://scripts/fleet_flag.gd")
const FlagEditor = preload("res://scripts/flag_editor.gd")

const MAX_BUTTONS := 4
const STANCES := ["attack", "defend"]
const STANCE_TR := {"attack": "Saldır", "defend": "Savun"}
const STANCE_HINT := {
	"attack": "Menzilindeki düşman uçaklarını ve hedefleri arar; hava üstünlüğü için en güçlü ayardır.",
	"defend": "Üssünün üstünde kalır: düşman saldırılarını %20 daha güçlü önler ama dışarıdaki orduya destek vermez.",
}


static func _cancel() -> Dictionary:
	return {"text": "Vazgeç", "cb": func(): pass, "kind": "ghost"}


static func _pname(gs, pid: int) -> String:
	return gs.provinces[pid].name


# ------------------------------------------------------------------ hava saldırısı

static func strike(ui, gs, w, done: Callable, pid: int = -1) -> void:
	if pid >= 0:
		_do_strike(ui, gs, w, pid, done)
		return
	if w.kind != "bomber" and w.kind != "drone":
		ui.toast("Yalnız bombardıman ve İHA kanatları saldırabilir.")
		return
	var tg: Array = Air.targets(gs, w)
	if tg.is_empty():
		ui.toast("Menzilde vurulacak düşman eyaleti yok: kanadı cepheye yakın bir üsse taşı.")
		return
	if w.cd > gs.turn:
		ui.toast(Loc.t("Kanat hazırlanıyor (%d hafta).") % (w.cd - gs.turn))
		return
	var wid: int = w.id
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, tg.size()):
		var q: int = tg[i]
		var a = gs.armies.get(q)
		var label: String = _pname(gs, q)
		if a != null and a.owner != w.owner:
			label = "%s (%s %s)" % [label, Macro.compact(float(a.size)), Loc.t("asker")]
		btns.append({"text": label, "kind": "danger", "icon": Icons.pick("airstrike", "jet"), "cb": func(): _do_strike(ui, gs, gs.wings[wid], q, done)})
	ui.show_dialog("Hava saldırısı", "Kanat menzildeki düşman eyaletini bombalar: ordu kaybettirir, savunmayı bozar. Düşman avcıları önleyebilir; avcı eşliği kayıpları azaltır. Bedel: %s; kanat %d hafta dinlenir." % [Macro.money(Air.strike_cost(gs, w.owner)), Air.STRIKE_CD], btns, "carrier", "")


static func _do_strike(ui, gs, w, pid: int, done: Callable) -> void:
	var r: Dictionary = Air.player_strike(gs, w.id, pid)
	if r.err != "":
		ui.toast(r.err)
		return
	var msg: String = "Hava saldırısı: düşman kaybı %s asker; kayıp uçak %d; düşürülen düşman avcısı %d." % [Macro.num(int(r.killed)), int(round(float(r.lost))), int(round(float(r.down)))]
	ui.toast(msg)
	done.call()


# ------------------------------------------------------------------ üs değiştir

static func rebase(ui, gs, w, done: Callable, pid: int = -1) -> void:
	if pid >= 0:
		var e: String = Air.rebase(gs, w.id, pid)
		if e != "":
			ui.toast(e)
			return
		ui.toast(Loc.t("Kanat yeni üsse uçuyor: %s.") % _pname(gs, pid))
		done.call()
		return
	var cands: Array = Air.base_candidates(gs, gs.countries[w.owner])
	var ok: Array = []
	for q in cands:
		if Air.rebase_check(gs, w, int(q)) == "":
			ok.append(int(q))
	if ok.is_empty():
		ui.toast("Uygun başka üs yok: haritadan menzil çemberi içindeki kendi eyaletine dokun.")
		return
	var wid: int = w.id
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, ok.size()):
		var q2: int = ok[i]
		btns.append({"text": _pname(gs, q2), "kind": "", "icon": Icons.pick("airbase", "plane"), "cb": func(): rebase(ui, gs, gs.wings[wid], done, q2)})
	ui.show_dialog("Üs değiştir", "Kanat başka bir üsse taşınır (1 hafta bekler). Menzil çemberi yeni üsten çizilir; en yakın dört üs listelenir, ötekiler için haritada kendi eyaletine dokun.", btns, "carrier", "")


# ------------------------------------------------------------------ hava köprüsü / paraşüt

static func lift(ui, gs, w, done: Callable) -> void:
	if w.kind != "transport":
		return
	if w.cd > gs.turn:
		ui.toast(Loc.t("Kanat hazırlanıyor (%d hafta).") % (w.cd - gs.turn))
		return
	var src: Array = Air.lift_sources(gs, w)
	if src.is_empty():
		ui.toast("Menzilde taşınacak ordun yok: kanadı ordunun yanındaki üsse taşı.")
		return
	var wid: int = w.id
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, src.size()):
		var q: int = src[i]
		var a = gs.armies[q]
		btns.append({"text": "%s (%s)" % [_pname(gs, q), Macro.compact(float(a.size))], "kind": "gold", "icon": Icons.pick("paratrooper", "users"), "cb": func(): lift_dest(ui, gs, gs.wings[wid], q, done)})
	ui.show_dialog("Hava köprüsü", "Hangi ordu uçurulsun? Kanat en fazla %s asker taşır. Dost cephe eyaletine iner ya da düşman eyaletine paraşütle atlar." % Macro.num(Air.lift_cap(w)), btns, "carrier", "")


static func lift_dest(ui, gs, w, src: int, done: Callable) -> void:
	var dl: Array = Air.lift_dests(gs, w, src)
	if dl.is_empty():
		ui.toast("Menzilde uygun iniş bölgesi yok.")
		return
	var wid: int = w.id
	var btns: Array = [_cancel()]
	for i in mini(MAX_BUTTONS, dl.size()):
		var q: int = dl[i]
		var hostile: bool = gs.provinces[q].controller != w.owner
		var label: String = _pname(gs, q)
		if hostile:
			label = "%s (%s)" % [label, Loc.t("paraşüt")]
		btns.append({"text": label, "kind": "danger" if hostile else "", "icon": Icons.pick("paratrooper" if hostile else "plane", "plane"), "cb": func(): _do_lift(ui, gs, wid, src, q, done)})
	ui.show_dialog("İniş bölgesi", "Nereye indirilsin? Düşman eyaletine atlayan birlikler dümdüz saldırır; kasadan paraşüt harekâtı bedeli düşülür.", btns, "carrier", "")


static func _do_lift(ui, gs, wid: int, src: int, dst: int, done: Callable) -> void:
	var e: String = Air.airlift(gs, wid, src, dst)
	if e != "":
		ui.toast(e)
		return
	ui.toast(Loc.t("Hava köprüsü: birlikler %s eyaletine indi.") % _pname(gs, dst))
	done.call()


# ------------------------------------------------------------------ komutanlık

static func manage(ui, gs, w, done: Callable) -> void:
	if w == null or not gs.wings.has(w.id) or w.owner != gs.player:
		return
	var wid: int = w.id
	var oc = gs.countries[w.owner]
	var sh = ui._open_sheet("Kanat komutanlığı", 780, true, true, Loc.t(Air.kind_name(w.kind)) + "  /  " + gs.provinces[w.base].name)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	var fv := FleetFlag.new()
	fv.spec = w.flag
	fv.country = oc
	fv.custom_minimum_size = Vector2(168, 112)
	head.add_child(fv)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var le := LineEdit.new()
	le.text = Air.display_name(gs, w)
	le.placeholder_text = Loc.t("Filo adı")
	le.max_length = 28
	le.custom_minimum_size = Vector2(0, 64)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(le)
	var save_name := func():
		var nm: String = le.text.strip_edges()
		Air.rename(gs, wid, "" if nm == "" or nm == Air.default_display(gs, w) else nm)
		ui.toast(Loc.t("Filo adı kaydedildi."))
		done.call()
		manage(ui, gs, gs.wings[wid], done)
	le.text_submitted.connect(func(_t): save_name.call())
	var nb := TK.button("Adı kaydet", "", Icons.pick("check", "flag"), Vector2(0, 60), 16)
	nb.pressed.connect(func():
		ui._click()
		save_name.call())
	col.add_child(nb)
	head.add_child(col)
	sh.body.add_child(head)
	var rl := TK.t("Rütbe: %s  (tecrübe %d)" % [Ext.rank_name(w.xp), int(w.xp)], "body", TK.GOLD)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(rl)
	var nxt: float = Ext.xp_to_next(w.xp)
	if nxt > 0.0:
		var rn := TK.t("Sonraki rütbe için %d" % int(ceil(nxt)), "small", TK.FAINT)
		sh.body.add_child(rn)
	var hl0 := TK.t(Loc.t(String(Air.KIND_HINT.get(w.kind, ""))), "small", TK.FAINT)
	hl0.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(hl0)
	# uçaklar
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t(Loc.t("Filodaki uçaklar") + "  (%d)" % Air.disp(w), "kicker", TK.GOLD))
	for sp in Air.planes(gs, w):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var iv := TK.IconView.new()
		iv.icon = Icons.pick(Air.kind_icon(w.kind), "jet")
		iv.color = TK.PAPER
		iv.stroke = 2.0
		iv.custom_minimum_size = Vector2(34, 34)
		iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(iv)
		var nm2: Label = TK.t(Loc.t(String(sp[1])), "body", TK.TEXT)
		nm2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(nm2)
		row.add_child(TK.t("x%d" % int(sp[2]), "value", TK.GOLD))
		sh.body.add_child(row)
	# durum
	sh.body.add_child(TK.hsep())
	var stats := "%s: %d    %s: %d km    %s: %s" % [Loc.t("Güç"), int(round(Air.cp(w))), Loc.t("Menzil"), Air.range_km(w.kind), Loc.t("Üs"), gs.provinces[w.base].name]
	var sl := TK.t(stats, "body", TK.TEXT)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(sl)
	# duruş
	if w.kind == "fighter" or w.kind == "recon":
		sh.body.add_child(TK.hsep())
		sh.body.add_child(TK.t(Loc.t("Duruş"), "kicker", TK.GOLD))
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 10)
		for st in STANCES:
			var sb := TK.button(String(STANCE_TR[st]), "gold" if w.stance == st else "", "", Vector2(0, 64), 16)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var stn: String = st
			sb.pressed.connect(func():
				ui._click()
				Air.set_stance(gs, wid, stn)
				done.call()
				manage(ui, gs, gs.wings[wid], done))
			srow.add_child(sb)
		sh.body.add_child(srow)
		var hl := TK.t(Loc.t(String(STANCE_HINT[w.stance if STANCE_HINT.has(w.stance) else "attack"])), "small", TK.FAINT)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(hl)
	# eylemler
	sh.body.add_child(TK.hsep())
	_sbtn(ui, sh, "Bayrak tasarla", Icons.pick("flag", "flag"), "blue", func():
		FlagEditor.open(ui.root, w.flag, func(spec: String):
			Air.set_flag(gs, wid, spec)
			ui.toast(Loc.t("Filo bayrağı kaydedildi."))
			done.call()
			if gs.wings.has(wid):
				manage(ui, gs, gs.wings[wid], done)))
	if w.flag != "":
		_sbtn(ui, sh, "Ülke bayrağına dön", Icons.pick("x", "x"), "ghost", func():
			Air.set_flag(gs, wid, "")
			done.call()
			manage(ui, gs, gs.wings[wid], done))
	sh.add_button("Kapat", func(): done.call(), "", true, "x", 160)


static func _sbtn(ui, sh, text: String, icon: String, kind: String, cb: Callable) -> void:
	var b := TK.button(text, kind, icon, Vector2(0, 72), 17)
	b.pressed.connect(func():
		ui._click()
		cb.call())
	sh.body.add_child(b)
