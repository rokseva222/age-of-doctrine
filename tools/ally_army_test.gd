extends SceneTree
## Müttefik ordusu bizim eyaletteyken denetim değişmemeli; çekilince de sahip/denetim aynı kalmalı
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
	var me: int = g.player
	var kar := -1
	for c in g.countries:
		if c.name.contains("Karaman"): kar = c.id
	g.countries[me].truce.erase(kar); g.countries[kar].truce.erase(me)
	g.make_alliance(me, kar)
	var p = g.provinces[433]
	if g.armies.has(433): g.armies.erase(433)
	g._spawn_army(kar, 433, 20000)
	for i in 4:
		g.end_turn()
		ck("müttefik ordusu Sivas'ta, tur %d: sahip=%d denetim=%d" % [i + 1, p.owner, p.controller], p.owner == me and p.controller == me)
	g.armies.erase(433)
	for i in 3:
		g.end_turn()
		ck("ordu çekildi, tur %d: sahip=%d denetim=%d" % [i + 1, p.owner, p.controller], p.owner == me and p.controller == me)
	print("HATA SAYISI=", fails)
	quit()
