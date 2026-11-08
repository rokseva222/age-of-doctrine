extends SceneTree
## Kayıt/yükleme turu: oyun oyna, kaydet, yükle, durumları karşılaştır, devam ettir.
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(11)
	var me := 0
	for c in gs.countries:
		if c.name == "Türkiye":
			me = c.id
	gs.start_game(me)
	for t in 80:
		gs.end_turn()
		if t == 10:
			load("res://scripts/macro.gd").buy(gs, gs.countries[me], "t_leo2a7", 20)
			load("res://scripts/macro.gd").set_budget(gs.countries[me], "cyber", 20)
			gs.countries[me].embargo.append(0)
	var path := "user://test_save.dat"
	print("kaydet: ", gs.save_to(path))
	var g2 = GS.new()
	print("yükle: ", g2.load_from(path))
	var same := true
	for i in gs.provinces.size():
		var a = gs.provinces[i]
		var b = g2.provinces[i]
		if a.owner != b.owner or a.controller != b.controller or a.siege != b.siege:
			same = false
	print("eyaletler aynı: ", same, " tur=", g2.turn, "/", gs.turn, " altın=", int(g2.countries[me].gold), "/", int(gs.countries[me].gold), " asker=", g2.countries[me].troops, "/", gs.countries[me].troops, " envanter=", g2.countries[me].inv.size(), "/", gs.countries[me].inv.size(), " bütçe=", g2.countries[me].budget, " ordu=", g2.armies.size(), "/", gs.armies.size(), " ülke=", g2.countries.size(), "/", gs.countries.size(), " savaş=", g2.wars.size(), "/", gs.wars.size())
	for t in 60:
		g2.end_turn()
	print("yüklenen oyun 60 tur devam etti, tur=", g2.turn, " oyuncu eyalet=", g2.countries[g2.player].prov_owned)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
