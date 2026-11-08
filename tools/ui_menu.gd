extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var lang: String = OS.get_cmdline_user_args()[0]
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = lang; St.seen_howto = true; St.save_all()
	var Loc = load("res://scripts/loc.gd")
	Loc.debug = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	var out := "/tmp/uim_" + lang
	DirAccess.make_dir_recursive_absolute(out)
	await _shot(out + "/01_main.png")
	var IS = load("res://scripts/info_sheets.gd")
	var IU = load("res://scripts/independence_ui.gd")
	var DU = load("res://scripts/daily_ui.gd")
	var APU = load("res://scripts/ap_ui.gd")
	var steps := [
		["02_scn", func(): main.menu._open_scenarios()],
		["03_eras", func(): main.menu._open_eras()],
		["04_settings", func(): IS.open_settings(main.menu.root, func(): pass)],
		["05_credits", func(): IS.open_credits(main.menu.root)],
		["06_howto", func(): IS.open_howto(main.menu.root)],
		["07_indep", func(): IU.open_setup(main.menu.root, func(p): pass)],
		["08_daily", func(): DU.open(main.menu.root, func(c): pass)],
		["09_store", func(): APU.open(main.menu.root)],
	]
	for s in steps:
		var before: int = main.menu.root.get_child_count()
		s[1].call()
		await create_timer(0.7).timeout
		await _shot("%s/%s.png" % [out, s[0]])
		while main.menu.root.get_child_count() > before:
			main.menu.root.get_children().back().queue_free()
			await create_timer(0.1).timeout
	for k in Loc.misses.keys():
		print("MISS| ", str(k).replace("\n", " "))
	quit()
