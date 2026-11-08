extends SceneTree
const PolicyUI = preload("res://scripts/policy_ui.gd")
const SendUI = preload("res://scripts/send_ui.gd")
const AssaultUI = preload("res://scripts/assault_ui.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_send")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	load("res://scripts/settings.gd").seen_howto = true
	main._on_start_requested(me)
	await create_timer(1.5).timeout
	var gs = main.gs
	var foe: int = gs.macro_idx.get("Bulgaria", 0)
	gs.player_declare_war(foe)
	for i in 2: gs.end_turn()
	var best = null
	var tgt := -1
	for a in gs.armies_of(me):
		for nb in gs.provinces[a.prov].neighbors:
			if gs.provinces[nb].owner == foe and (best == null or a.size > best.size):
				best = a; tgt = nb
	main.ui.refresh_top()
	main.map.focus_province(best.prov, 4.0)
	await create_timer(0.8).timeout
	SendUI.open(main.ui, gs, best, tgt, func(n): pass)
	await create_timer(0.7).timeout
	await _shot("/tmp/shots_send/send.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	AssaultUI.open(main.ui, gs, tgt, func(r): pass)
	await create_timer(0.7).timeout
	await _shot("/tmp/shots_send/assault.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	PolicyUI.open(main.ui, gs, 4)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_send/merc.png")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	main.ui.show_settings() if main.ui.has_method("show_settings") else null
	quit()
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
