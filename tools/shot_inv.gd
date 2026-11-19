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
	var PolicyUI = load("res://scripts/policy_ui.gd")
	PolicyUI.open(main.ui, main.gs, 2)
	await create_timer(1.0).timeout
	await _shot("/tmp/shots_gas/inv.png")
	quit()
