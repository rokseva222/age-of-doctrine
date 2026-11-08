extends SceneTree
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = "/tmp/shots_phone"
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	for c in main.gs.countries:
		if c.name_en == "United Kingdom":
			main.menu.select_country(c.id)
	await create_timer(1.2).timeout
	await _shot(out + "/06_leader_select.png")
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	main._on_start_requested(main.menu._sel)
	await create_timer(1.8).timeout
	main.ui.show_province(main.gs.countries[main.gs.player].capital, null)
	await create_timer(0.6).timeout
	await _shot(out + "/07_leader_card.png")
	quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
