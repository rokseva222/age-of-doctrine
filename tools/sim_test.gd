extends SceneTree
## Başsız simülasyon: tüm ülkeler yapay zeka. Kullanım:
## godot --headless --path . -s tools/sim_test.gd -- <seed> <tur>

const GS = preload("res://scripts/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_val := int(args[0]) if args.size() > 0 else 12345
	var turns := int(args[1]) if args.size() > 1 else 300
	var gs = GS.new()
	var t0 := Time.get_ticks_msec()
	gs.new_world(seed_val)
	print("dünya üretimi: %d ms | eyalet=%d ülke=%d" % [Time.get_ticks_msec() - t0, gs.provinces.size(), gs.countries.size()])
	gs.start_game(-1)
	gs.profile = true
	var news_count := 0
	gs.news_posted.connect(func(_t, _p, _k): news_count += 1)
	var t1 := Time.get_ticks_msec()
	for t in turns:
		gs.end_turn()
		if (t + 1) % 50 == 0 or t == 0:
			var parts: Array = []
			var reb := 0
			var al := 0
			var top: Array = []
			for c in gs.countries:
				if c.alive and c.is_rebel:
					reb += 1
				elif c.alive:
					top.append(c)
					al += c.allies.size()
			top.sort_custom(func(a, b): return a.prov_owned > b.prov_owned)
			for i in mini(6, top.size()):
				parts.append("%s:%d" % [top[i].name, top[i].prov_owned])
			parts.append("isyancı=%d ittifak=%d" % [reb, al / 2])
			print("tur %d | savaş=%d | yaşayan=%d | %s" % [gs.turn, gs.wars.size(), gs.alive_count(), ", ".join(parts)])
	print("sim süresi: %d ms (%.1f ms/tur)" % [Time.get_ticks_msec() - t1, float(Time.get_ticks_msec() - t1) / turns])
	for k in gs.prof:
		print("  profil %s: %.1f ms/tur" % [k, gs.prof[k] / 1000.0 / turns])
	var biggest := 0
	for a in gs.armies.values():
		biggest = maxi(biggest, a.size)
	print("istatistik: ", gs.stats, " | en büyük ordu=", biggest, " | ordu sayısı=", gs.armies.size())
	var last: Array = gs.news_log.slice(maxi(0, gs.news_log.size() - 12))
	for n in last:
		print("  [%s] %s" % [n.kind, n.text])
	quit()
