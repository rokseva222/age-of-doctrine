extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var out := "/tmp/shots_career"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.7"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._career_pick_era("ott1520")
	await create_timer(1.0).timeout
	var kids = main.menu.root.get_children()
	kids.back().queue_free()
	await create_timer(0.3).timeout
	main._start_career("ott1520", {"host_en": "Turkey", "bg": "cavalry", "name": "Kemal Bey"})
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	main.gs.career["pending"] = {}
	main.ui.show_career()
	await create_timer(1.0).timeout
	await _shot(out + "/divan.png")
	quit()
