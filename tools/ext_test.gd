extends SceneTree
## JSON senaryolarını sırayla başlatır, 100 tur oynatır, hedefleri ve kaydet/yükle'yi dener.
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
const Obj = preload("res://scripts/objectives.gd")
func _init() -> void:
	SC.reload()
	var fails := 0
	for sc in SC.all():
		if not (String(sc["id"]) in ["nile", "scs", "arctic", "essequibo", "redsea", "korea", "kuraklik", "sahel"]):
			continue
		var gs = GS.new()
		gs.new_world(21)
		var first: String = sc["suggest"][0] if not sc["suggest"].is_empty() else "Turkey"
		var me: int = gs.macro_idx.get(first, 0)
		gs.start_game(me)
		SC.apply(gs, sc["id"])
		var n0 := Obj.list(gs).size()
		for t in 60:
			gs.end_turn()
		var done := 0
		for o in Obj.list(gs):
			if Obj.is_done(gs, o): done += 1
		var path := "user://ext_test.dat"
		var ok1: bool = gs.save_to(path)
		var g2 = GS.new()
		var ok2: bool = g2.load_from(path)
		var keep: bool = ok2 and g2.scn.get("id", "") == gs.scn.get("id", "") and Obj.list(g2).size() == n0
		for t in 20:
			g2.end_turn()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if not (ok1 and ok2 and keep):
			fails += 1
			print("  [!] kayıt/yükleme sorunu ", ok1, ok2, keep)
		print("%-14s oyuncu=%-14s hedef=%d bitti=%d savaş=%d blok=%d tur=%d" % [sc["id"], first, n0, done, gs.wars.size(), gs.blocs.size(), gs.turn])
	print("SORUN=", fails)
	quit()
