extends SceneTree
## Her çağ/senaryo × önerilen oyuncu: hedefler oyunun 1. turunda zaten sağlanıyor mu?
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")
const Obj = preload("res://scripts/objectives.gd")
func _init() -> void:
	var items: Array = []
	for e in Eras.all(): items.append(["era", String(e.id)])
	for s in SC.all(): items.append(["scn", String(s.id)])
	for it in items:
		var kind: String = it[0]; var id: String = it[1]
		var sug: Array = Eras.get_era(id).get("suggest", []) if kind == "era" else SC.get_sc(id).get("suggest", [])
		for pi in sug.size():
			if kind == "era": Eras.prepare(id)
			var gs = GS.new()
			gs.new_world(4242 + pi)
			if kind == "era": Eras.restructure(gs, id)
			var me: int = int(gs.macro_idx.get(sug[pi], 0))
			gs.start_game(me)
			if kind == "era": Eras.start(gs, id)
			else: SC.apply(gs, id)
			var lst: Array = Obj.list(gs)
			var done_now: Array = []
			var req := 0; var reqdone := 0
			for o in lst:
				var m: bool = Obj._met(gs, o)
				if Obj.is_required(o):
					req += 1
					if m: reqdone += 1
				if m: done_now.append(String(o.get("id", "")) + ":" + String(o.get("type", "")))
			if req > 0 and reqdone == req:
				print("ANINDA_ZAFER ", kind, " ", id, " ", sug[pi], " hedefler=", done_now)
			elif not done_now.is_empty():
				print("ön-tamam    ", kind, " ", id, " ", sug[pi], " ", done_now)
	quit()
