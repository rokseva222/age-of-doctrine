extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
const D = preload("res://scripts/districts.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n); if not ok: fails += 1
func _init() -> void:
	var gs = GS.new()
	gs.new_world(31)
	var h: int = gs.macro_idx["Turkey"]
	gs.start_game(h)
	var cap: int = gs.countries[h].capital
	print("başkent=", cap, " ", gs.provinces[cap].name)
	ck("başladı", I.begin(gs, {"host_en": "Turkey", "pids": [431, 423, 428], "name": "Test", "leader": "Ada", "color": 1, "ideo": "federal", "method": "uprising"}))
	var f = gs.countries[gs.player]
	print("sahip: ", f.owned_ids, " asker=", f.troops, " envanter=", f.inv)
	ck("İstanbul+İzmir hareketin", gs.provinces[423].owner == gs.player and gs.provinces[428].owner == gs.player)
	ck("Ankara host'ta", gs.provinces[431].owner == h)
	ck("ağır silah yok", not f.inv.keys().any(func(k): return not str(k).begins_with("i_")))
	ck("asker az", f.troops <= 12000)
	ck("3 şehir ilçe", D.pids(gs).size() == 3)
	var names: Array = []
	for i in (gs.indep.dist["431"] as Array).size():
		names.append(D.name_of(gs, 431, i))
	print("Ankara ilçeleri: ", names)
	ck("Yenimahalle+Sincan", names.has("Yenimahalle") and names.has("Sincan"))
	var cs: Array = D.cells(gs, 431)
	var okc := true
	for c in cs:
		if c.is_empty(): okc = false
	ck("hücreler dolu", cs.size() == names.size() and okc)
	for pid in D.pids(gs):
		print("  ", gs.provinces[pid].name, " ilçe=", (gs.indep.dist[str(pid)] as Array).size(), " kontrol=", snapped(D.control(gs, pid), 0.01))
	# eylem
	f.gold += 1e9
	var tries := 0
	var got := false
	for i in names.size():
		if int(gs.indep.dist["431"][i].st) == 0:
			for k in 40:
				gs.indep.dist["431"][i].cd = 0
				var r: String = D.act(gs, 431, i)
				tries += 1
				if int(gs.indep.dist["431"][i].st) == 1:
					got = true
					print("  eylem sonucu: ", r)
					break
			break
	ck("ilçe alınabildi (%d deneme)" % tries, got)
	# devir
	for e in gs.indep.dist["431"]:
		e.st = 1
	D._check_flip(gs, 431)
	ck("Ankara devrildi", gs.provinces[431].owner == gs.player)
	ck("host başkenti yeniden atandı", gs.countries[h].capital != 431 and gs.provinces[gs.countries[h].capital].owner == h)
	# kayıp
	for e in gs.indep.dist["428"]:
		e.st = 0
	for k in 5:
		D.tick(gs)
	ck("İzmir geri döndü", gs.provinces[428].owner == h)
	# kayıt
	var p := "user://dist.dat"
	ck("kayıt", gs.save_to(p))
	var g2 = GS.new()
	ck("yükle", g2.load_from(p) and D.active(g2) and D.pids(g2).size() == 3)
	ck("hücre yeniden", D.cells(g2, 431).size() == names.size())
	for t in 30:
		g2.end_turn()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	# varsayılan şehir (jenerik adlar)
	var g3 = GS.new()
	g3.new_world(5)
	g3.start_game(g3.macro_idx["Spain"])
	ck("jenerik", I.begin(g3, {"host_en": "Spain", "name": "T2", "method": "uprising"}))
	for pid in D.pids(g3):
		var nn: Array = []
		for i in (g3.indep.dist[str(pid)] as Array).size():
			nn.append(D.name_of(g3, pid, i))
		print("  ", g3.provinces[pid].name, ": ", nn)
	print("HATA SAYISI=", fails)
	quit()
