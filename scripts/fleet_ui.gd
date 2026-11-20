extends RefCounted
## Filo eylemlerinin diyalogları (kıyı bombardımanı, torpido, gemiye bin, karaya çık). Kart düğmeleri ui.gd'de, emirler fleets.gd'de.

const Fleets = preload("res://scripts/fleets.gd")
const Seas = preload("res://scripts/seas.gd")
const Macro = preload("res://scripts/macro.gd")
const Icons = preload("res://scripts/icons.gd")

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
