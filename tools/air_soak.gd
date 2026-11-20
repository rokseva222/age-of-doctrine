extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Air = preload("res://scripts/air.gd")
var strikes := 0
var lifts := 0
func _init() -> void:
	for era in ["", "ww2"]:
		Eras.clear() if era == "" else Eras.prepare(era)
		var g = GS.new()
		g.new_world(11)
		var host := "Turkey"
		if era != "":
			Eras.restructure(g, era)
			host = String(Eras.get_era(era).suggest[0])
		g.start_game(int(g.macro_idx.get(host, 0)))
		if era != "":
			Eras.start(g, era)
		g.news_posted.connect(func(t, _p, _k):
			if t.begins_with("Hava saldırısı"): strikes += 1
			if t.find("hava köprüsüyle") >= 0: lifts += 1)
		var t0 := Time.get_ticks_msec()
		var maxw := 0
		for i in 120:
			g.end_turn()
			maxw = maxi(maxw, g.wings.size())
		var ms := float(Time.get_ticks_msec() - t0) / 120.0
		var alive := 0
		for c in g.countries:
			if c.alive: alive += 1
		print("era=%s turns=120 ms/tur=%.0f wings(end)=%d max=%d strikes=%d lifts=%d alive=%d player_alive=%s" % [era, ms, g.wings.size(), maxw, strikes, lifts, alive, str(g.countries[g.player].alive)])
		strikes = 0; lifts = 0
	quit()
