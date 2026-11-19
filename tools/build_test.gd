extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	var tr := -1
	for c in gs.countries:
		if c.name_en == "Turkey" or c.name_en == "Türkiye": tr = c.id
	gs.start_game(tr)
	var pid: int = gs.countries[gs.player].owned_ids[0]
	for q in gs.countries[gs.player].owned_ids:
		if not gs.provinces[q].is_capital: pid = q; break
	var p = gs.provinces[pid]
	gs.countries[gs.player].gold = 100000.0
	gs.refresh_stats()
	var inc0: float = gs.countries[gs.player].income
	var g0: float = gs.countries[gs.player].gold
	var e: String = gs.player_build(pid, "oil")
	if e != "" or gs.countries[gs.player].gold >= g0:
		print("HATA kurulum: ", e); quit(1); return
	if gs.player_build(pid, "farm") == "":
		print("HATA: ikinci bina kuruldu"); quit(1); return
	for i in 9: gs.end_turn()
	if p.bld != "oil":
		print("HATA: bina bitmedi ", p.bld, " ", p.bld_wip, " ", p.bld_until, " t=", gs.turn); quit(1); return
	gs.refresh_stats()
	var inc1: float = gs.countries[gs.player].income
	print("gelir ", inc0, " -> ", inc1)
	if inc1 <= inc0:
		print("HATA: gelir artmadi"); quit(1); return
	var d: Dictionary = gs.to_dict()
	var gs2 = GS.new(); gs2.new_world(4)
	if not gs2.from_dict(d) or gs2.provinces[pid].bld != "oil":
		print("HATA: kayit"); quit(1); return
	print("TAMAM"); quit()
