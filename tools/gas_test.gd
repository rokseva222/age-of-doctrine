extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Macro = preload("res://scripts/macro.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	var enemy: int = gs.macro_idx.get("Greece", 1)
	var fails := 0
	print("gaz var mı: ", gs.player_has_gas(), " air_pow=", gs.countries[me].air_pow)
	if gs.player_gas(0) == "": fails += 1; print("HATA: savaşsız gaz çalıştı")
	gs.declare_war(me, enemy, true)
	var pid := -1
	for p in gs.provinces:
		if p.owner == enemy and gs.armies.get(p.id) != null:
			pid = p.id; break
	var bs: int = gs.armies[pid].size
	var inf0: float = gs.infamy
	var r: String = gs.player_gas(pid)
	var af: int = gs.armies[pid].size
	print("gaz: '", r, "' ordu ", bs, " -> ", af, " infamy ", inf0, "->", gs.infamy, " cd=", gs.gas_cd)
	if r != "" or af >= bs: fails += 1; print("HATA: gaz etkisiz")
	if gs.player_gas(pid) == "": fails += 1; print("HATA: bekleme yok")
	gs.save_to("user://t_gas.json")
	var g2 = GS.new(); g2.new_world(21); g2.load_from("user://t_gas.json")
	if g2.gas_cd != gs.gas_cd: fails += 1; print("HATA: gas_cd kaydedilmedi")
	# abluka
	var a = gs.countries[me]; var b = gs.countries[enemy]
	a.naval_pow = 0.0; b.naval_pow = 50.0; b.ratios["sub"] = 1.0
	var m1: float = Macro.blockade_mult(gs, a)
	b.naval_pow = 0.0
	var m0: float = Macro.blockade_mult(gs, a)
	print("abluka çarpanı: ", m1, " yokken: ", m0)
	if not (m1 < 0.95 and m1 >= 0.87 and m0 == 1.0): fails += 1; print("HATA: abluka")
	for i in 8: gs.end_turn()
	print("HATA SAYISI=", fails)
	quit()
