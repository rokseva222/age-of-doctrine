extends SceneTree
const PolicyUI = preload("res://scripts/policy_ui.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_pol"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	var gs = main.gs
	# bir komşuya savaş aç
	var foe := -1
	for nb in gs.neighbor_countries(tr_id):
		if foe < 0 and not gs.countries[nb].is_rebel:
			foe = nb
	gs.player_declare_war(foe)
	for i in 6:
		gs.end_turn()
	main.ui.refresh_top()
	await create_timer(0.8).timeout
	await _shot(out + "/00_hud.png")
	for t in [0, 6]:
		PolicyUI.open(main.ui, gs, t)
		await create_timer(0.7).timeout
		await _shot(out + "/policy_%d.png" % t)
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	main.ui.show_dialog("Barış teklifi", "Test barış teklifi metni.", [{"text": "Masaya otur", "cb": func(): pass, "kind": "good"}, {"text": "Reddet", "cb": func(): pass}])
	await create_timer(0.8).timeout
	await _shot(out + "/dlg_peace.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	var AU = load("res://scripts/assault_ui.gd")
	var tgt := -1
	for p in gs.provinces:
		if p.owner == foe:
			tgt = p.id
			break
	AU.open(main.ui, gs, tgt, func(): pass)
	await create_timer(0.8).timeout
	await _shot(out + "/assault.png")
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
