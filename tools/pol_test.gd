extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const P = preload("res://scripts/politics.gd")

func _init() -> void:
	var errs := 0
	var g = GS.new()
	g.new_world(31337)
	var pl: int = int(g.macro_idx.get("Egypt", 0))
	g.start_game(pl)
	print("Mısır rejim=", P.regime(g, pl), " Türkiye=", P.regime(g, int(g.macro_idx.get("Turkey", 0))), " Çin=", P.regime(g, int(g.macro_idx.get("China", 0))), " ABD=", P.regime(g, int(g.macro_idx.get("United States of America", 0))))
	var cards := [0]
	g.pol_card.connect(func(): cards[0] += 1)
	var news_coup := [0]
	g.news_posted.connect(func(t, p, k, ic = ""): if str(t).begins_with("DARBE"): news_coup[0] += 1)
	var counts := {}
	for i in 600:
		g.end_turn()
		if not g.pol.pending.is_empty():
			var idx: int = i % 3
			var res: String = P.choose(g, idx)
			if res == "": print("HATA boş sonuç"); errs += 1
	for c in g.countries:
		if c.alive and not c.is_rebel:
			var r: String = P.regime(g, c.id)
			counts[r] = int(counts.get(r, 0)) + 1
	print("600 tur sonra rejim dağılımı: ", counts, " oyuncu kartı=", cards[0], " darbe haberi=", news_coup[0])
	if int(counts.get("junta", 0)) > 40: print("HATA çok fazla cunta"); errs += 1
	# eylemler
	g.countries[pl].stability = 50.0
	for a in P.actions(g):
		print("  eylem: ", a.id, " ok=", a.ok)
	print(P.do_action(g, "martial"))
	if not P.martial_on(g, pl): print("HATA sıkıyönetim"); errs += 1
	print(P.do_action(g, "democratize"))
	if P.regime(g, pl) != "democracy": print("HATA demokratikleşme"); errs += 1
	# oyuncu darbesi
	g.pol.pending = {}
	P._player_card(g, g.countries[pl], "authoritarian")
	var before: int = int(g.countries[pl].stability)
	var tx: String = P._player_coup(g, g.countries[pl])
	print(tx, " rejim=", P.regime(g, pl), " istikrar ", before, " -> ", int(g.countries[pl].stability))
	# kayıt
	var g2 = GS.new(); g2.new_world(31337); g2.from_dict(g.to_dict())
	if P.regime(g2, pl) != P.regime(g, pl): print("HATA kayıt rejim"); errs += 1
	print("HATA SAYISI=", errs)
	quit()
