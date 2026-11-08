extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const SC = preload("res://scripts/scenarios.gd")
func _init() -> void:
	for sc in SC.LIST:
		var gs = GS.new()
		gs.new_world(21)
		var me: int = gs.macro_idx.get(sc["suggest"][0] if not sc["suggest"].is_empty() else "Turkey", 0)
		gs.start_game(me)
		SC.apply(gs, sc["id"])
		var line := "%-22s | başta: savaş=%d blok=%d ülke=%d cold=%d" % [sc["name"], gs.wars.size(), gs.blocs.size(), gs.countries.size(), gs.cold.size()]
		for t in 60:
			gs.end_turn()
		line += " || 60 tur: savaş=%d yaşayan=%d" % [gs.wars.size(), gs.alive_count()]
		var tot := 0
		for c in gs.countries:
			if c.alive and not c.is_rebel and c.name.begins_with("Yeni") or c.name.begins_with("Kara"):
				line += " [%s: %d eyalet, %d asker]" % [c.name, c.prov_owned, c.troops]
		print(line)
		var cy := 0
		for n in gs.news_log:
			if n.kind == "cyber":
				cy += 1
		print("    siber haber: ", cy, " | ilk haber: ", gs.news_log[1].text if gs.news_log.size() > 1 else "")
	quit()
