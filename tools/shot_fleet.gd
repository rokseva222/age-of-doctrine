extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots_fleet")
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.7"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(1.0).timeout
	var cid: int = main.gs.macro_idx.get("Turkey", 0)
	main._on_start_requested(cid)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	var tc = main.gs.countries[cid]
	print("NAVAL ", tc.naval_pow, " carriers ", tc.carriers, " cap coastal ", main.gs.provinces[tc.capital].coastal, " show_armies ", main.map.hud.show_armies if "hud" in main.map else "?")
	main.map.focus_country(cid)
	await create_timer(2.5).timeout
	await _shot("/tmp/shots_fleet/fleet.png")
	quit()
