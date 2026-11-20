extends SceneTree
## kullanım: -- <tür> <id> <oyuncu_sırası> <tur> ; oyuncunun düşüşünü tur tur izler
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var kind: String = a[0]; var id: String = a[1]; var pi: int = int(a[2]); var turns: int = int(a[3])
	var sug: Array = []
	if kind == "era":
		Eras.prepare(id); sug = Eras.get_era(id).get("suggest", [])
	elif kind == "scn":
		sug = SC.get_sc(id).get("suggest", [])
	var gs = GS.new()
	gs.new_world(4242 + pi)
	if kind == "era": Eras.restructure(gs, id)
	var nm: String = sug[pi % sug.size()] if not sug.is_empty() else "Turkey"
	var me: int = int(gs.macro_idx.get(nm, 0))
	gs.start_game(me)
	if kind == "era": Eras.start(gs, id)
	elif kind == "scn": SC.apply(gs, id)
	var pl = gs.countries[gs.player]
	pl.auto_cmd = true
	print("oyuncu=", pl.name_en, " eyalet=", pl.prov_owned, " asker=", pl.troops, " savaşlar=", _enemies(gs, pl))
	for t in turns:
		if t == 4 and pl.alive:
			var bestn := -1
			for n in gs.neighbor_countries(gs.player):
				var cn = gs.countries[n]
				if cn.alive and not cn.is_rebel and not gs.at_war(gs.player, n) and not gs.is_allied(n, gs.player) and int(pl.truce.get(n, -1)) <= gs.turn:
					if bestn < 0 or cn.troops < gs.countries[bestn].troops: bestn = n
			if bestn >= 0:
				print("  >> test oyuncusu savaş açıyor: ", gs.countries[bestn].name_en, " asker=", gs.countries[bestn].troops)
				gs.declare_war(gs.player, bestn)
		var before: int = gs.news_log.size()
		gs.end_turn()
		var held := 0
		for p in gs.provinces:
			if p.owner == gs.player and p.controller == gs.player: held += 1
		print("t=%d sahip=%d elde=%d asker=%d altın=%.0f istikrar=%.0f ordu=%d düşman=%s" % [gs.turn, pl.prov_owned, held, pl.troops, pl.gold, pl.stability, _myarmies(gs), _enemies(gs, pl)])
		if held < pl.prov_owned and t % 1 == 0:
			for n in gs.news_log.slice(before): 
				if String(n.text).find(pl.name) >= 0 or true: print("     ", String(n.text).substr(0, 110))
		if not pl.alive: break
	quit()
func _myarmies(gs) -> int:
	var n := 0
	for k in gs.armies: if gs.armies[k].owner == gs.player: n += 1
	return n
func _enemies(gs, pl) -> String:
	var s := ""
	for e in pl.enemies: s += "%s(%d) " % [gs.countries[e].name_en, gs.countries[e].troops]
	return s
