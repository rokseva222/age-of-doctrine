extends RefCounted
## Savaş Odası: çok aşamalı harekât planı. Oyuncu bir düşman seçer, aşamaları (hedef eyalet, harekât türü, kuvvet oranı,
## bekleme) sıralar ve planı yürürlüğe koyar; plan her tur sıradaki aşamayı kendisi başlatır, takip eder ve bitirir.
## Plana uyan taarruzların harekât bedelinin %15'i iade edilir; plan tamamlanınca istikrar ve moral kazanılır.
## Altta yatan savaş mekaniği değişmez: her aşama gs.player_launch_assault çağırır.

const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")

const MAX_PHASES := 6
const REFUND := 0.15
const PHASE_TIMEOUT := 30      # taarruz başladıktan sonra bu kadar hafta içinde fethedilmezse başarısız (kuşatma sürüyorsa uzar)
const WAIT_LIMIT := 8          # para/ordu beklemesi bu süreyi aşarsa aşama başarısız
const OP_ORDER := ["assault", "barrage", "air", "naval", "missile", "paradrop", "special", "cyber", "landing", "blitz"]


static func _tr() -> bool:
	return Loc.lang == "tr"


static func _t(tr: String, en: String) -> String:
	return tr if _tr() else en


static func ensure(gs) -> void:
	if not (gs.wroom is Dictionary):
		gs.wroom = {}
	if not gs.wroom.has("phases"):
		gs.wroom = {"on": false, "enemy": -1, "name": "", "start": 0, "phases": [], "done": 0, "failed": 0, "plans_won": 0}


static func active(gs) -> bool:
	ensure(gs)
	return bool(gs.wroom.on)


static func enemies(gs) -> Array:
	var out: Array = []
	if gs.player < 0:
		return out
	for e in gs.countries[gs.player].enemies:
		if gs.countries[int(e)].alive:
			out.append(int(e))
	return out


static func reset(gs) -> void:
	gs.wroom = {}
	ensure(gs)


static func new_plan(gs, enemy: int) -> void:
	reset(gs)
	gs.wroom["enemy"] = enemy
	gs.wroom["name"] = _t("Harekât: %s", "Operation: %s") % gs.countries[enemy].name


static func ops_for(gs, pid: int) -> Array:
	var out: Array = []
	var p = gs.provinces[pid]
	for op in OP_ORDER:
		if not gs.OPS.has(op):
			continue
		if op == "landing":
			continue          # amfibi harekât, kara yolu olmayan hedefte otomatik seçilir
		if gs.op_available(op, p, [], 1.0):
			out.append(op)
	return out


## Düşmanın elindeki ve oyuncunun ordularının makul sürede ulaşabileceği eyaletler (değere göre)
static func candidates(gs, enemy: int, limit: int = 14) -> Array:
	var out: Array = []
	for p in gs.provinces:
		var holder: int = p.controller if p.controller >= 0 else p.owner
		if holder != enemy and p.owner != enemy:
			continue
		if holder == gs.player:
			continue
		var near: Array = gs.armies_near(p.id, 5)
		if near.is_empty():
			continue
		out.append(p.id)
	out.sort_custom(func(a, b): return gs.provinces[a].value() > gs.provinces[b].value())
	if out.size() > limit:
		out.resize(limit)
	return out


static func odds(gs, pid: int, op: String, frac: float) -> float:
	var near: Array = gs.armies_near(pid, 6)
	var list: Array = []
	for e in near:
		list.append(e.army)
	if list.is_empty():
		return 0.0
	var est: Dictionary = gs.assault_estimate(pid, list, op, frac)
	return float(est.ratio)


static func add_phase(gs, pid: int, op: String, frac: float, delay: int) -> String:
	ensure(gs)
	if gs.wroom.phases.size() >= MAX_PHASES:
		return "En fazla 6 aşama eklenebilir."
	for ph in gs.wroom.phases:
		if int(ph.pid) == pid:
			return "Bu eyalet planda zaten var."
	gs.wroom.phases.append({"pid": pid, "op": op, "frac": frac, "delay": delay, "state": "wait", "ready": -1, "launched": -1, "finished": -1})
	return ""


static func remove_phase(gs, i: int) -> void:
	if i >= 0 and i < gs.wroom.phases.size() and not bool(gs.wroom.on):
		gs.wroom.phases.remove_at(i)


static func move_phase(gs, i: int, d: int) -> void:
	var ph: Array = gs.wroom.phases
	var j: int = i + d
	if bool(gs.wroom.on) or i < 0 or j < 0 or i >= ph.size() or j >= ph.size():
		return
	var tmp = ph[i]
	ph[i] = ph[j]
	ph[j] = tmp


## Otomatik plan: en güçlü ordunun düşman başkentine giden yolundaki düşman eyaletlerini aşamalara böler
static func suggest(gs, enemy: int) -> Array:
	var out: Array = []
	var cap: int = int(gs.countries[enemy].capital)
	if cap < 0:
		return out
	var best = null
	for a in gs.armies.values():
		if a.owner == gs.player and (best == null or a.size > best.size):
			best = a
	if best == null:
		return out
	var path: Array = gs.path_to(gs.player, best.prov, cap)
	var steps: Array = []
	for pid in path:
		var p = gs.provinces[int(pid)]
		var holder: int = p.controller if p.controller >= 0 else p.owner
		if holder == enemy or p.owner == enemy:
			steps.append(int(pid))
	if steps.is_empty():
		return out
	if steps.size() > MAX_PHASES:
		var pick: Array = []
		for i in MAX_PHASES:
			pick.append(steps[int(round(float(i) * float(steps.size() - 1) / float(MAX_PHASES - 1)))])
		steps = pick
	for pid in steps:
		out.append({"pid": int(pid), "op": "barrage" if gs.op_available("barrage", gs.provinces[int(pid)], [], 1.0) else "assault", "frac": 1.0, "delay": 1})
	return out


static func start(gs) -> String:
	ensure(gs)
	var w: Dictionary = gs.wroom
	if w.phases.is_empty():
		return "Plana en az bir aşama ekle."
	if int(w.enemy) < 0 or not gs.at_war(gs.player, int(w.enemy)):
		return "Bu ülkeyle savaşta değilsin."
	w["on"] = true
	w["start"] = gs.turn
	w["done"] = 0
	w["failed"] = 0
	for ph in w.phases:
		ph["state"] = "wait"
		ph["ready"] = -1
	gs.post_news(_t("Savaş Odası: %s yürürlüğe girdi.", "War Room: %s is under way.") % String(w.name), -1, "war_player")
	return ""


static func cancel(gs) -> void:
	ensure(gs)
	if bool(gs.wroom.on):
		gs.post_news(_t("Savaş Odası: plan iptal edildi.", "War Room: the plan was cancelled."), -1, "info")
	reset(gs)


static func phase_label(gs, ph: Dictionary) -> String:
	var p = gs.provinces[int(ph.pid)]
	var opn: String = String(gs.OPS[String(ph.op)].name) if gs.OPS.has(String(ph.op)) else String(ph.op)
	return "%s  —  %s  (%%%d)" % [p.title(), Loc.t(opn), int(round(float(ph.frac) * 100.0))]


static func state_label(st: String) -> String:
	match st:
		"go":
			return _t("Sürüyor", "In progress")
		"ok":
			return _t("Başarılı", "Succeeded")
		"fail":
			return _t("Başarısız", "Failed")
	return _t("Bekliyor", "Waiting")


static func _card(gs, title: String, body: String, scene: String) -> void:
	gs.wroom_card.emit(title, body, scene)


static func _finish_phase(gs, ph: Dictionary, ok: bool, why: String = "") -> void:
	ph["state"] = "ok" if ok else "fail"
	ph["finished"] = gs.turn
	var p = gs.provinces[int(ph.pid)]
	var w: Dictionary = gs.wroom
	if ok:
		w["done"] = int(w.done) + 1
		var capital: bool = p.is_capital
		gs.post_news(_t("Savaş Odası: %s ele geçirildi.", "War Room: %s has been captured.") % p.title(), p.id, "war_player")
		if capital:
			gs.countries[gs.player].stability = clampf(gs.countries[gs.player].stability + 3.0, 5.0, 100.0)
			_card(gs, _t("BAŞKENT DÜŞTÜ", "THE CAPITAL HAS FALLEN"), _t("%s, planın %d. aşamasında düştü. Düşman komuta zinciri çöküyor.", "%s fell in phase %d of your plan. The enemy chain of command is collapsing.") % [p.title(), int(w.phases.find(ph)) + 1], "peace")
		else:
			_card(gs, _t("Aşama tamamlandı", "Phase complete"), _t("%d. aşama: %s ele geçirildi.", "Phase %d: %s has been captured.") % [int(w.phases.find(ph)) + 1, p.title()], "war")
	else:
		w["failed"] = int(w.failed) + 1
		gs.post_news(_t("Savaş Odası: %s aşaması başarısız. %s", "War Room: the %s phase failed. %s") % [p.title(), Loc.t(why)], p.id, "info")


## Her tur
static func tick(gs) -> void:
	ensure(gs)
	var w: Dictionary = gs.wroom
	if not bool(w.on) or gs.player < 0:
		return
	var enemy: int = int(w.enemy)
	if enemy < 0 or not gs.countries[enemy].alive or not gs.at_war(gs.player, enemy):
		_end(gs, _t("Savaş sona erdi; plan kapatıldı.", "The war is over; the plan was closed."))
		return
	var cur: Dictionary = {}
	for ph in w.phases:
		if String(ph.state) == "wait" or String(ph.state) == "go":
			cur = ph
			break
	if cur.is_empty():
		_end(gs, "")
		return
	var pid: int = int(cur.pid)
	var p = gs.provinces[pid]
	if String(cur.state) == "wait":
		if int(cur.ready) < 0:
			# aşama ilk kez sıraya girdi: bekleme süresi bundan itibaren
			var prev_fin: int = int(w.start)
			for ph2 in w.phases:
				if int(ph2.finished) > prev_fin:
					prev_fin = int(ph2.finished)
			cur["ready"] = prev_fin + int(cur.delay)
		# ele geçirilmiş bile olabilir (başka orduyla)
		if p.controller == gs.player or p.owner == gs.player:
			_finish_phase(gs, cur, true)
			return
		if gs.turn < int(cur.ready):
			return
		var near: Array = gs.armies_near(pid, 8)
		var ids: Array = []
		for e in near:
			var a = e.army
			if not a.leaving:
				ids.append(a.id)
		var op: String = String(cur.op)
		if ids.is_empty():
			if gs.turn - int(cur.ready) > WAIT_LIMIT:
				_finish_phase(gs, cur, false, "Hedefe ulaşabilecek ordu kalmadı.")
			return
		if not gs.op_available(op, p, [], 1.0):
			op = "assault"
		var res: Dictionary = gs.player_launch_assault(pid, ids, op, float(cur.frac))
		if String(res.err) != "":
			if gs.turn - int(cur.ready) > WAIT_LIMIT:
				_finish_phase(gs, cur, false, String(res.err))
			return
		cur["state"] = "go"
		cur["launched"] = gs.turn
		gs.countries[gs.player].gold += gs.op_cost(op) * REFUND
		gs.post_news(_t("Savaş Odası: %s için taarruz başladı.", "War Room: the assault on %s has begun.") % p.title(), pid, "war_player")
	else:
		if p.controller == gs.player or p.owner == gs.player:
			_finish_phase(gs, cur, true)
		elif gs.turn - int(cur.launched) > PHASE_TIMEOUT and not (int(p.siege) > 0 and int(p.siege_by) == gs.player):
			_finish_phase(gs, cur, false, "Süre doldu.")


static func _end(gs, msg: String) -> void:
	var w: Dictionary = gs.wroom
	var ok: int = int(w.done)
	var bad: int = int(w.failed)
	var total: int = w.phases.size()
	w["on"] = false
	if msg != "":
		gs.post_news(_t("Savaş Odası: ", "War Room: ") + msg, -1, "info")
		return
	var all_ok: bool = bad == 0 and ok == total and total > 0
	if all_ok:
		w["plans_won"] = int(w.get("plans_won", 0)) + 1
		var c = gs.countries[gs.player]
		c.stability = clampf(c.stability + 4.0, 5.0, 100.0)
		c.gold += maxf(c.income, 1.0) * 1.5
		_card(gs, _t("Plan başarıyla tamamlandı", "Plan completed"), _t("%s: %d aşamanın tamamı başarıyla bitti. Genelkurmay ödüllendirildi: istikrar +4, hazineye ek kaynak.", "%s: all %d phases succeeded. The General Staff is rewarded: stability +4 and extra funds.") % [String(w.name), total], "peace")
	else:
		_card(gs, _t("Plan sona erdi", "Plan ended"), _t("%s: %d aşama başarılı, %d başarısız.", "%s: %d phases succeeded, %d failed.") % [String(w.name), ok, bad], "war")
