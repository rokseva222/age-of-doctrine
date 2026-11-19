extends SceneTree
const Cabinet = preload("res://scripts/cabinet.gd")
const CabinetUI = preload("res://scripts/cabinet_ui.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var out := "/tmp/shots_pre"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.6"
	main._start_era("ott1520")
	await create_timer(1.5).timeout
	var cid: int = main.menu._sel
	main._on_start_requested(cid)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n := 0
	for id in ["p_ulufe", "p_plague", "p_tribute"]:
		var card: Dictionary = {}
		for cd in Cabinet.PreCards.CARDS:
			if cd.id == id: card = cd
		CabinetUI.open(main.ui, main.gs, card, rng, func(t): pass)
		await create_timer(0.8).timeout
		await _shot("%s/%d_%s.png" % [out, n, id])
		n += 1
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	# havuz: pre dönemde sadece p_ kartları
	var seen := {}
	for t in 300:
		var c: Dictionary = Cabinet.pick(main.gs, -99, [], rng, true)
		if not c.is_empty(): seen[c.id] = true
	print("havuz: ", seen.keys())
	quit()
