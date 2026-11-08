extends SceneTree
## Yeni kabine özellikleri: aday penceresi, şans kartı, seçim, kabine sekmesi.
const Cabinet = preload("res://scripts/cabinet.gd")
const CabinetUI = preload("res://scripts/cabinet_ui.gd")
const AppointUI = preload("res://scripts/appoint_ui.gd")
const PolicyUI = preload("res://scripts/policy_ui.gd")

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)

func _init() -> void:
	var out := "/tmp/shots_cab2"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(0.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	main._on_start_requested(tr_id)
	await create_timer(1.3).timeout
	var gs = main.gs
	var me = gs.countries[gs.player]
	Cabinet.init_cabinet(me, gs.turn)
	me.cab["fin"].until = gs.turn
	me.cab["fin"].why = "scandal"
	var sh = AppointUI.open(main.ui, gs, "fin")
	await create_timer(0.8).timeout
	await _shot(out + "/1_appoint.png")
	sh.close()
	await create_timer(0.3).timeout
	for id in ["t_crates", "e_vote", "s_cup", "r_coup"]:
		var card: Dictionary = {}
		for cd in Cabinet.CARDS:
			if cd.id == id:
				card = cd
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		var sh2 = CabinetUI.open(main.ui, gs, card, rng, func(t): pass)
		await create_timer(0.7).timeout
		await _shot("%s/2_%s.png" % [out, id])
		if id == "t_crates" or id == "e_vote":
			var btns: Array = sh2.find_children("*", "Button", true, false)
			btns[1 if id == "e_vote" else 2].pressed.emit()
			await create_timer(0.5).timeout
			await _shot("%s/3_%s_res.png" % [out, id])
		sh2.close()
		await create_timer(0.3).timeout
	PolicyUI.open(main.ui, gs, 7)
	await create_timer(0.8).timeout
	await _shot(out + "/4_tab.png")
	quit()
