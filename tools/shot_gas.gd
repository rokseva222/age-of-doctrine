extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots_gas")
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.6"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.6"
	main._to_select()
	await create_timer(1.0).timeout
	var cid: int = main.gs.macro_idx.get("Turkey", 0)
	main._on_start_requested(cid)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	var enemy: int = main.gs.macro_idx.get("Greece", 1)
	main.gs.declare_war(cid, enemy, true)
	var pid := -1
	for p in main.gs.provinces:
		if p.owner == enemy and main.gs.armies.get(p.id) != null:
			pid = p.id; break
	main._on_map_tapped(pid)
	await create_timer(1.0).timeout
	await _shot("/tmp/shots_gas/card.png")
	main.ui.hide_dialog()
	quit()
