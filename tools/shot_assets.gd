extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var out := "/tmp/shots_assets"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.7"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(1.0).timeout
	var cid: int = main.gs.macro_idx.get("Russia", 0)
	main._on_start_requested(cid)
	await create_timer(1.8).timeout
	main.ui.hide_dialog()
	main.ui.show_relations(main.gs.macro_idx.get("United States of America", 1))
	await create_timer(0.8).timeout
	await _shot(out + "/relations_us.png")
	main.ui.hide_dialog()
	main.ui.show_relations(main.gs.macro_idx.get("Saudi Arabia", 1))
	await create_timer(0.8).timeout
	await _shot(out + "/relations_sa.png")
	main.ui.hide_dialog()
	main.ui.show_chokes()
	await create_timer(0.8).timeout
	await _shot(out + "/chokes.png")
	main.ui.hide_dialog()
	load("res://scripts/policy_ui.gd").open(main.ui, main.gs, 1)
	await create_timer(1.0).timeout
	await _shot(out + "/policy_buy.png")
	main.ui.hide_dialog()
	var enemy: int = main.gs.macro_idx.get("Ukraine", 1)
	main.gs.declare_war(cid, enemy, true)
	var pid := -1
	for p in main.gs.provinces:
		if p.owner == enemy and p.coastal and main.gs.armies.get(p.id) != null:
			pid = p.id; break
	main._on_ui_action("nuke", pid)
	await create_timer(1.0).timeout
	await _shot(out + "/nuke.png")
	quit()
