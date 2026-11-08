extends SceneTree
## Rastgele olay türlerinin dağılımı (ikon etiketi) — 400 tur.
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	gs.start_game(0)
	for t in 400:
		gs.end_turn()
	var cnt := {}
	for n in gs.news_log:
		if n.kind.begins_with("event") and n.has("ic"):
			cnt[n.ic] = cnt.get(n.ic, 0) + 1
	print("olay ikonları (son ", gs.news_log.size(), " haber): ", cnt)
	for n in gs.news_log:
		if n.has("ic") and n.ic in ["virus", "flood", "coup", "summit", "science"]:
			print("  ", n.ic, ": ", n.text)
			break
	quit()
