extends SceneTree
## Ana sahne ile ses akışı: menü -> oyun -> savaş -> tik-tak (hata var mı?)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	print("menü mood=", main.sfx._mood)
	main._to_select()
	await create_timer(1.0).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	load("res://scripts/settings.gd").seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	print("oyun mood=", main.sfx._mood)
	main._on_speed_changed(3)
	await create_timer(6.0).timeout
	print("ticks=", main.sfx._ticks, " mood=", main.sfx._mood, " amb=", main.sfx._amb_on)
	main._on_speed_changed(0)
	var p = main.gs.player
	var foe := -1
	for c in main.gs.countries:
		if c.alive and c.id != p and c.id != 0:
			foe = c.id
			break
	print(main.gs.player_declare_war(foe))
	await create_timer(1.5).timeout
	print("savaş mood=", main.sfx._mood, " amb=", main.sfx._amb_on)
	quit()
