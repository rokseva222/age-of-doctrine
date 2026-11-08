extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
const D = preload("res://scripts/districts.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	if not ok:
		print("HATA ", n); fails += 1
func run(host: String, method: String, k: int, seed_: int, active := false) -> void:
	var gs = GS.new()
	gs.new_world(seed_)
	var h: int = gs.macro_idx[host]
	gs.start_game(h)
	var cities: Array = []
	for pr in gs.provinces:
		if pr.owner == h: cities.append(pr.id)
	cities.sort_custom(func(a, b): return gs.provinces[a].pop > gs.provinces[b].pop)
	var pids: Array = cities.slice(0, k)
	if not I.begin(gs, {"host_en": host, "pids": pids, "name": "T", "leader": "L", "color": 1, "ideo": "federal", "method": method}):
		print("HATA begin ", host); fails += 1; return
	var f = gs.countries[gs.player]
	var tag := "%s/%s/k%d%s" % [host, method, k, "/aktif" if active else ""]
	ck(tag + " zayıf", f.troops <= 12000)
	ck(tag + " ağır silah yok", not f.inv.keys().any(func(q): return not str(q).begins_with("i_")))
	if method == "uprising":
		var uniq := {}
		for pid in D.pids(gs): uniq[pid] = true
		ck(tag + " ilçe şehirleri tekrarsız", uniq.size() == D.pids(gs).size() and D.pids(gs).size() == mini(k, pids.size()))
	gs.indep_card.connect(func():
		if not gs.indep.pending.is_empty(): I.choose(gs, 0))
	f.auto_cmd = true
	var maxphase := 0
	for t in 120:
		if method == "uprising" and D.active(gs) and t % 2 == 0:
			f.gold = maxf(f.gold, 5e6)
			for pid in D.pids(gs):
				var arr: Array = gs.indep.dist[str(pid)]
				for i in arr.size():
					if int(arr[i].st) == 0 and int(arr[i].cd) <= 0:
						D.act(gs, pid, i); break
		if active:
			f.gold = maxf(f.gold, 5e6)
			for a in I.actions(gs):
				if a.why == "" and not ["unilateral", "coup", "referendum", "un_apply"].has(a.id):
					I.do_action(gs, a.id)
		gs.end_turn()
		maxphase = maxi(maxphase, int(gs.indep.phase))
		# invariants
		if not f.alive:
			print(tag, " öldü t=", t, " evre=", gs.indep.phase)
			break
		for pid in D.pids(gs):
			var c: float = D.control(gs, pid)
			ck(tag + " kontrol aralığı", c >= -0.0001 and c <= 1.0001)
			var own: int = gs.provinces[pid].owner
			ck(tag + " sahip geçerli", own >= 0 and own < gs.countries.size() and gs.countries[own].alive)
		ck(tag + " asker negatif değil", f.troops >= 0)
		ck(tag + " gold sonlu", is_finite(f.gold))
		var cc: int = gs.countries[h].capital
		if gs.countries[h].alive:
			ck(tag + " host başkent sahibi host", gs.provinces[cc].owner == h)
	print("%s son: evre=%d max=%d yaşıyor=%s eyalet=%d asker=%d destek=%d ilçe_kontrol=%s" % [tag, gs.indep.phase, maxphase, f.alive, f.prov_owned, f.troops, int(gs.indep.support), str(snapped(D.total_control(gs), 0.01)) if D.active(gs) else "-"])
func _init() -> void:
	run("Turkey", "uprising", 1, 5, true)
	run("Turkey", "uprising", 2, 6, true)
	run("Spain", "uprising", 3, 7, true)
	run("India", "uprising", 2, 8, true)
	run("Japan", "uprising", 1, 12, true)
	run("Turkey", "uprising", 1, 5)
	run("Turkey", "uprising", 2, 6)
	run("Spain", "uprising", 3, 7)
	run("India", "uprising", 3, 8)
	run("United States of America", "uprising", 2, 9)
	run("Turkey", "political", 1, 10)
	run("Brazil", "coup", 2, 11)
	run("Japan", "uprising", 1, 12)
	print("HATA SAYISI=", fails)
	quit()
