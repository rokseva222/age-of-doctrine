extends SceneTree
## Osmanlı çağları (ott1299, ott1453): kurulum doğrulaması + 120 hafta oynatma (çökme/ülke sayısı/tarih)
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Names = preload("res://scripts/names.gd")
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1
func _n(g, name_en: String) -> int:
	var c := 0
	var i: int = int(g.macro_idx.get(name_en, -1))
	if i < 0: return -1
	for p in g.provinces:
		if p.owner == i: c += 1
	return c
func _init() -> void:
	for id in ["ott1299", "ott1453"]:
		var g = GS.new()
		g.new_world(31)
		Eras.prepare(id)
		Eras.restructure(g, id)
		g.start_game(int(g.macro_idx["Turkey"]))
		Eras.start(g, id)
		var tr := _n(g, "Turkey")
		var gr := _n(g, "Greece")
		print(id, " Turkey=", tr, " Greece=", gr, " Karaman(NM)=", _n(g, "North Macedonia"), " W.Anadolu(Mont)=", _n(g, "Montenegro"), " Azer=", _n(g, "Azerbaijan"), " Bulgaria=", _n(g, "Bulgaria"), " Serbia=", _n(g, "Serbia"), " Egypt=", _n(g, "Egypt"))
		var tc = g.countries[g.macro_idx["Turkey"]]
		print(id, " ad=", tc.name, " lider=", tc.leader, " başkent=", g.provinces[tc.capital].name, " tarih=", Names.year_month(g.turn), " ordu=", tc.troops if "troops" in tc else "?")
		var gc = g.countries[g.macro_idx["Greece"]]
		print(id, " Bizans: ", gc.name, " lider=", gc.leader, " başkent=", g.provinces[gc.capital].name, " savaşta=", g.at_war(tc.id, gc.id))
		var alive := 0
		var noleader := []
		for c in g.countries:
			if c.alive and not c.is_rebel:
				alive += 1
				if c.leader == "": noleader.append(c.name_en)
		print(id, " canlı ülke=", alive, " liderisiz=", noleader.size(), " ", noleader.slice(0, 12))
		ck(id + ": Türkiye eyaleti var", tr > 0)
		ck(id + ": Bizans başkenti 423 Konstantinopolis", g.provinces[gc.capital].name.begins_with("Konstantin") or gc.capital == 423)
		if id == "ott1453":
			ck("1453: Osmanlı >= 40 eyalet", tr >= 40)
			ck("1453: Bizans 2-6 eyalet", gr >= 2 and gr <= 6)
			ck("1453: Bizans ile savaşta", g.at_war(tc.id, gc.id))
			ck("1453: Bulgaristan yok", _n(g, "Bulgaria") <= 0)
		else:
			ck("1299: Osmanlı küçük beylik (2-8 eyalet)", tr >= 2 and tr <= 8)
			ck("1299: Bizans savaşta değil", not g.at_war(tc.id, gc.id))
			ck("1299: İlhanlı-Memlük savaşı", g.at_war(g.macro_idx["Azerbaijan"], g.macro_idx["Egypt"]))
		var t0 := Time.get_ticks_msec()
		for i in 120:
			g.end_turn()
		var al2 := 0
		for c in g.countries:
			if c.alive and not c.is_rebel: al2 += 1
		print(id, " 120 hafta sonra: tarih=", Names.year_month(g.turn), " canlı=", al2, " Türkiye=", _n(g, "Turkey"), " Bizans=", _n(g, "Greece"), " ms=", Time.get_ticks_msec() - t0)
		ck(id + ": 120 hafta sonra oyun sürüyor", al2 > 10 and tc.alive)
	print("HATA SAYISI=", errs)
	quit()
