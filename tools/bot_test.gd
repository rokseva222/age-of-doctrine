extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	for seed_v in [3, 9]:
		for cname in ["Türkiye", "Fransa", "Kenya", "Polonya", "Hindistan"]:
			var gs = GS.new()
			gs.new_world(seed_v)
			var me := -1
			for c in gs.countries:
				if c.name == cname:
					me = c.id
			gs.difficulty = 1
			gs.start_game(me)
			var line := "seed %d %-9s" % [seed_v, cname]
			for t in 300:
				gs.end_turn()
				var c = gs.countries[me]
				if c.alive and t % 6 == 0:
					for e in c.enemies.duplicate():
						gs.player_request_peace(e)
				if (t + 1) % 100 == 0:
					line += " | t%d: %d eyalet (%s)" % [t + 1, c.prov_owned, "yaşıyor" if c.alive else "ölü"]
			print(line)
	quit()
