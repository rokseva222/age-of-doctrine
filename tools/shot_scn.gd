extends SceneTree
const PolicyUI = preload("res://scripts/policy_ui.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = "/tmp/shots_scn"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	main.menu._open_scenarios()
	await create_timer(0.7).timeout
	await _shot(out + "/01_scn_list.png")
	main.menu.root.get_child(main.menu.root.get_child_count() - 1).close()
	await create_timer(0.4).timeout
	main.menu.set_scenario("kara")
	await create_timer(1.2).timeout
	await _shot(out + "/02_select_kara.png")
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	main._on_start_requested(main.menu._sel)
	await create_timer(1.8).timeout
	main._on_speed_changed(2)
	await create_timer(6.0).timeout
	main._on_speed_changed(0)
	main.ui.refresh_top()
	await _shot(out + "/03_game_kara.png")
	main.ui.show_world_panel(3)
	await create_timer(0.6).timeout
	await _shot(out + "/04_blocs.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	PolicyUI.open(main.ui, main.gs, 5)
	await create_timer(0.7).timeout
	await _shot(out + "/05_alliance_create.png")
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
