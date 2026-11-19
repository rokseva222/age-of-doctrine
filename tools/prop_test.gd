extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	var tr := -1
	for c in gs.countries:
		if c.name_en == "Turkey" or c.name_en == "Türkiye": tr = c.id
	gs.start_game(tr)
	var c = gs.countries[gs.player]
	c.trust = 40.0; c.stability = 70.0
	gs.player_set_propaganda("press")
	var t0: float = c.trust
	for i in 12: gs.end_turn()
	print("guven ", t0, " -> ", c.trust)
	var c2 = c.trust
	gs.player_set_propaganda("")
	c.trust = 40.0
	for i in 12: gs.end_turn()
	print("propagandasiz 12 hf: ", c.trust)
	if c2 <= c.trust:
		print("HATA: propaganda etkisiz"); quit(1); return
	var d: Dictionary = gs.to_dict()
	var gs2 = GS.new(); gs2.new_world(4)
	gs2.from_dict(d)
	if absf(gs2.countries[gs2.player].trust - c.trust) > 0.01:
		print("HATA kayit"); quit(1); return
	print("TAMAM"); quit()
