extends SceneTree
const PolicyUI = preload("res://scripts/policy_ui.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = "/tmp/shots_era"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main.menu._open_eras()
	await create_timer(0.7).timeout
	await _shot(out + "/01_era_menu.png")
	main.menu.root.get_child(main.menu.root.get_child_count() - 1).close()
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	for id in ["ww2", "ww1"]:
		main._start_era(id)
		await create_timer(1.4).timeout
		await _shot(out + "/02_%s_select.png" % id)
		main._on_start_requested(main.menu._sel)
		await create_timer(1.8).timeout
		main._on_speed_changed(2)
		await create_timer(5.0).timeout
		main._on_speed_changed(0)
		main.ui.refresh_top()
		main.map.animate_to(main.map.world_rect().get_center(), main.map.min_zoom * 1.6, 0.1)
		await create_timer(1.0).timeout
		await _shot(out + "/03_%s_game.png" % id)
		main.ui.hide_dialog()
		PolicyUI.open(main.ui, main.gs, 1)
		await create_timer(0.8).timeout
		await _shot(out + "/04_%s_arms.png" % id)
		main._go_main_menu()
		await create_timer(1.0).timeout
	quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
