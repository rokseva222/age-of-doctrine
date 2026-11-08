extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.tut_done = true; St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_cr")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.6).timeout
	main._to_select()
	await create_timer(0.6).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	main._on_start_requested(me)
	await create_timer(1.5).timeout
	var Cr = load("res://scripts/crises.gd")
	main.gs.crisis = {"kind": "pandemic", "start": 50, "end": 62, "sev": 0.8, "mit": 1.0}
	main._show_card(Cr.card_for(main.gs, "pandemic"))
	await create_timer(1.2).timeout
	await _shot("/tmp/shots_cr/card.png")
	quit()
