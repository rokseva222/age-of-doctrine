extends SceneTree
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.tut_done = true; St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.5).timeout
	main._to_select()
	await create_timer(0.5).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	main._on_start_requested(me)
	await create_timer(1.0).timeout
	for ch in main.ui.topbar.get_child(0).get_children(): print("CH ", ch.get_class(), ch.get_combined_minimum_size().x, " ", ch.name)
	print("VP ", main.ui.root.get_viewport_rect().size, " TOPBAR min ", main.ui.topbar.get_combined_minimum_size(), " size ", main.ui.topbar.size, " scale ", get_root().content_scale_factor, " win ", get_root().size)
	quit()
