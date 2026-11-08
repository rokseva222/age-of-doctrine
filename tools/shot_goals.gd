extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.ach = {}; St.save_all()
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_goals")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	St.seen_howto = true
	main._on_start_requested(me)
	await create_timer(1.5).timeout
	await _shot("/tmp/shots_goals/01_start.png")
	var gs = main.gs
	for i in 3: gs.end_turn()
	await create_timer(0.6).timeout
	await _shot("/tmp/shots_goals/02_toast.png")
	main.ui.show_goals()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_goals/03_goals.png")
	main.ui.show_world_panel()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_goals/04_world.png")
	St.ach = {}; St.save_all()
	quit()
