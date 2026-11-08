extends RefCounted
## Savaş Odası arayüzü: plan listesi, aşama ekleme, otomatik plan, yürürlüğe koyma.

const TK = preload("res://scripts/theme_kit.gd")
const Icons = preload("res://scripts/icons.gd")
const Loc = preload("res://scripts/loc.gd")
const WR = preload("res://scripts/war_room.gd")

const FRACS := [0.5, 0.75, 1.0]
const DELAYS := [0, 2, 4, 8]


## ui: ui.gd örneği (_open_sheet, toast, _click)
static func open(ui) -> void:
	var gs = ui.gs
	if gs == null or gs.player < 0:
		return
	WR.ensure(gs)
	var w: Dictionary = gs.wroom
	var sh = ui._open_sheet("Savaş Odası", 860, true, true, gs.countries[gs.player].name)
	sh.set_icon("war_room", "swords")
	var again := func():
		sh.close()
		open(ui)
	var intro := TK.t("Birden çok aşamalı bir harekât planla: hedefleri, harekât türünü ve zamanlamayı sen belirle; plan her turu kendisi yürütür. Plana uyan taarruzların bedelinin %15'i iade edilir; tüm plan başarılı olursa istikrar kazanırsın.", "small", TK.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(intro)
	sh.body.add_child(TK.hsep())
	var foes: Array = WR.enemies(gs)
	if int(w.enemy) < 0 or (not bool(w.on) and not foes.has(int(w.enemy))):
		if foes.is_empty():
			sh.body.add_child(TK.t("Şu an savaşta değilsin; plan yapmak için bir savaş gerekir.", "body", TK.MUTED))
			sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)
			return
		sh.body.add_child(TK.t("Plan kurulacak düşman", "kicker", TK.GOLD))
		for e in foes:
			var cid: int = int(e)
			var b := TK.button(gs.countries[cid].name, "", "swords", Vector2(0, 60), 20)
			b.pressed.connect(func():
				ui._click()
				WR.new_plan(gs, cid)
				again.call())
			sh.body.add_child(b)
		sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)
		return
	var foe_name: String = gs.countries[int(w.enemy)].name
	sh.body.add_child(TK.t(String(w.name), "h3", TK.GOLD))
	sh.body.add_child(TK.t(Loc.t("Hedef ülke: %s") % foe_name, "small", TK.MUTED))
	var phases: Array = w.phases
	if phases.is_empty():
		sh.body.add_child(TK.t("Henüz aşama yok. Elle ekle ya da otomatik plan öner.", "body", TK.FAINT))
	for i in phases.size():
		var idx: int = i
		var ph: Dictionary = phases[i]
		sh.body.add_child(TK.hsep())
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		var sic: String = Icons.pick({"wait": "phase_wait", "ok": "phase_success", "fail": "phase_fail"}.get(String(ph.state), ""), "")
		if sic != "":
			var siv := TK.IconView.new()
			siv.icon = sic
			siv.custom_minimum_size = Vector2(40, 40)
			siv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			head.add_child(siv)
		var nm := TK.t("%d. %s" % [i + 1, WR.phase_label(gs, ph)], "body", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		head.add_child(nm)
		var stc: Color = TK.GREEN if String(ph.state) == "ok" else (TK.RED_TEXT if String(ph.state) == "fail" else (TK.GOLD if String(ph.state) == "go" else TK.MUTED))
		head.add_child(TK.t(WR.state_label(String(ph.state)), "small", stc))
		sh.body.add_child(head)
		var odds: float = WR.odds(gs, int(ph.pid), String(ph.op), float(ph.frac))
		var sub: String = Loc.t("Başarı şansı ≈ %%%d   /   bekleme: %d hf") % [int(round(odds * 100.0)), int(ph.delay)]
		sh.body.add_child(TK.t(sub, "small", TK.FAINT))
		if not bool(w.on):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			for act in [["▲", -1], ["▼", 1]]:
				var d: int = int(act[1])
				var mb := TK.button(String(act[0]), "", "", Vector2(64, 44), 18)
				mb.pressed.connect(func():
					ui._click()
					WR.move_phase(gs, idx, d)
					again.call())
				row.add_child(mb)
			var rb := TK.button(Loc.t("Kaldır"), "ghost", "", Vector2(120, 44), 16)
			rb.pressed.connect(func():
				ui._click()
				WR.remove_phase(gs, idx)
				again.call())
			row.add_child(rb)
			sh.body.add_child(row)
	sh.body.add_child(TK.hsep())
	if bool(w.on):
		sh.body.add_child(TK.t(Loc.t("Başarılı: %d   /   Başarısız: %d   /   Toplam: %d") % [int(w.done), int(w.failed), phases.size()], "small", TK.TEXT))
		sh.add_button("Planı iptal et", func():
			WR.cancel(gs)
			ui.refresh_top(), "danger", true, "", 200)
	else:
		sh.add_button("Aşama ekle", func():
			_picker(ui, {"step": 0, "pid": -1, "op": "assault", "frac": 1.0, "delay": 1}), "", false, "plus", 180)
		sh.add_button("Otomatik plan öner", func():
			var sug: Array = WR.suggest(gs, int(w.enemy))
			if sug.is_empty():
				ui.toast(Loc.t("Başkente giden yol bulunamadı."))
				return
			w["phases"] = []
			for s in sug:
				WR.add_phase(gs, int(s.pid), String(s.op), float(s.frac), int(s.delay))
			again.call(), "", false, "map", 220)
		var go: Button = sh.add_button("Yürürlüğe koy", func():
			var err: String = WR.start(gs)
			if err != "":
				ui.toast(Loc.t(err))
				return
			again.call(), "primary", false, "play", 200)
		go.disabled = phases.is_empty()
		sh.add_button("Planı sıfırla", func():
			WR.reset(gs)
			again.call(), "ghost", false, "", 170)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


## Aşama ekleme penceresi: önce hedef, sonra harekât türü/kuvvet/bekleme
static func _picker(ui, st: Dictionary) -> void:
	var gs = ui.gs
	var w: Dictionary = gs.wroom
	var sh = ui._open_sheet("Aşama ekle", 820, true, true, String(w.name))
	sh.set_icon("attack_phases", "swords")
	var again := func():
		sh.close()
		_picker(ui, st)
	if int(st.pid) < 0:
		sh.body.add_child(TK.t("Hedef eyalet", "kicker", TK.GOLD))
		var cands: Array = WR.candidates(gs, int(w.enemy))
		if cands.is_empty():
			sh.body.add_child(TK.t("Ordularının menzilinde düşman eyaleti yok. Önce ordularını cepheye yaklaştır.", "body", TK.MUTED))
		for pid in cands:
			var target: int = int(pid)
			var p = gs.provinces[target]
			var o: float = WR.odds(gs, target, "assault", 1.0)
			var b := TK.button("%s   —   %s" % [p.title(), Loc.t("şans %%%d") % int(round(o * 100.0))], "", "target", Vector2(0, 58), 18)
			b.pressed.connect(func():
				ui._click()
				st["pid"] = target
				again.call())
			sh.body.add_child(b)
		sh.add_button("Vazgeç", func(): open(ui), "ghost", true, "", 150)
		return
	var p2 = gs.provinces[int(st.pid)]
	sh.body.add_child(TK.t(p2.title(), "h3", TK.GOLD))
	sh.body.add_child(TK.t("Harekât türü", "kicker", TK.GOLD))
	var orow := HFlowContainer.new()
	orow.add_theme_constant_override("h_separation", 8)
	orow.add_theme_constant_override("v_separation", 8)
	for op in WR.ops_for(gs, int(st.pid)):
		var opk: String = op
		var ob := TK.button(Loc.t(String(gs.OPS[opk].name)), "primary" if String(st.op) == opk else "", "", Vector2(0, 50), 16)
		ob.pressed.connect(func():
			ui._click()
			st["op"] = opk
			again.call())
		orow.add_child(ob)
	sh.body.add_child(orow)
	var od: Dictionary = gs.OPS[String(st.op)]
	var dsc := TK.t(Loc.t(String(od.desc)), "small", TK.FAINT)
	dsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(dsc)
	sh.body.add_child(TK.t("Kuvvet oranı", "kicker", TK.GOLD))
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 8)
	for f in FRACS:
		var fv: float = f
		var fb := TK.button("%%%d" % int(fv * 100.0), "primary" if absf(float(st.frac) - fv) < 0.01 else "", "", Vector2(110, 50), 18)
		fb.pressed.connect(func():
			ui._click()
			st["frac"] = fv
			again.call())
		frow.add_child(fb)
	sh.body.add_child(frow)
	sh.body.add_child(TK.t("Bekleme (önceki aşamadan sonra)", "kicker", TK.GOLD))
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	for d in DELAYS:
		var dv: int = d
		var db := TK.button(Loc.t("%d hf") % dv, "primary" if int(st.delay) == dv else "", "", Vector2(110, 50), 18)
		db.pressed.connect(func():
			ui._click()
			st["delay"] = dv
			again.call())
		drow.add_child(db)
	sh.body.add_child(drow)
	var o2: float = WR.odds(gs, int(st.pid), String(st.op), float(st.frac))
	sh.body.add_child(TK.t(Loc.t("Tahmini başarı şansı: %%%d") % int(round(o2 * 100.0)), "body", TK.TEXT))
	sh.add_button("Ekle", func():
		var err: String = WR.add_phase(gs, int(st.pid), String(st.op), float(st.frac), int(st.delay))
		if err != "":
			ui.toast(Loc.t(err))
		open(ui), "primary", true, "plus", 160)
	sh.add_button("Geri", func():
		st["pid"] = -1
		_picker(ui, st), "ghost", true, "", 140)
