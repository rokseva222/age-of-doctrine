extends SceneTree
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.save_all()
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_rel")
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
	var gs = main.gs
	gs.player_declare_war(gs.macro_idx.get("Bulgaria", 0))
	gs.make_alliance(me, gs.macro_idx.get("Azerbaijan", 0))
	for i in 2: gs.end_turn()
	main.map.set_relation_view(me)
	main.map.focus_country(me)
	await create_timer(1.0).timeout
	await _shot("/tmp/shots_rel/01_map.png")
	main.ui.show_relations(me)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_rel/02_sheet.png")
	St.language = "tr"; St.save_all()
	quit()
