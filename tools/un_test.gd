extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const UN = preload("res://scripts/un.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var me: int = gs.macro_idx.get("Turkey", 0)
	gs.start_game(me)
	gs.countries[me].gold = 1.0e9
	var other: int = gs.macro_idx.get("Greece", 0)
	var bg: int = gs.macro_idx.get("Bulgaria", 0)
	var tg: int = gs.macro_idx.get("Syria", 0)
	gs.declare_war(bg, other)
	print("üye: ", UN.members(gs).size(), " savaş: ", gs.wars.size())
	for k in UN.ORDER:
		var tid: int = gs.wars.size() - 1 if k == "ceasefire" else tg
		var r = UN.propose(gs, k, me, tid)
		print(k, " ok=", r.ok, " geçti=", r.passed, " ", r.yes, "-", r.no, " | ", r.text)
		print("   tekrar: ", UN.propose(gs, k, me, tid).text)
	print("savaş sayısı: ", gs.wars.size(), " yaptırım bitişi Syria: ", gs.countries[tg].sanction_until)
	for i in 300: gs.end_turn()
	print("log: ", gs.un_log.size(), " son: ", gs.un_log[-1].text if not gs.un_log.is_empty() else "-")
	gs.save_to("user://t_un.json")
	var g2 = GS.new(); g2.new_world(21); g2.load_from("user://t_un.json")
	print("yüklü log=", g2.un_log.size(), " cd=", g2.un_cd.size(), " sanc=", g2.countries[tg].sanction_until)
	quit()
