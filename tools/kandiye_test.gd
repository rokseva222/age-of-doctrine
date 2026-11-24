extends SceneTree
## 1453: barışla alınan eyalet (Kandiye 1311) tur sonrası da sahibine ait ve işgalsiz olmalı
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _init() -> void:
	var g = GS.new()
	g.new_world(5)
	Eras.restructure(g, "ott1453")
	g.start_game(int(g.macro_idx.get("Turkey", 0)))
	Eras.start(g, "ott1453")
	var pr = g.provinces[1311]
	var old: int = pr.owner
	print("Kandiye sahibi: ", g.countries[old].name_en, " denetim: ", g.countries[pr.controller].name_en)
	var me: int = g.player
	g.countries[me].truce.erase(old); g.countries[old].truce.erase(me)
	g.player_declare_war(old, true)
	var w = g.get_war(me, old)
	ck("savaş var", w != null)
	pr.controller = me
	g.finish_peace(w, me, [1311])
	ck("barış sonrası sahip=oyuncu, denetim=oyuncu", pr.owner == me and pr.controller == me)
	for i in 6:
		g.end_turn()
		ck("tur %d: sahip=%s denetim=%s" % [i + 1, g.countries[pr.owner].name_en, g.countries[pr.controller].name_en], pr.owner == pr.controller)
	print("HATA SAYISI=", fails)
	quit()
