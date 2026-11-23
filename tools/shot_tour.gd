extends SceneTree
## Oyuncu gözü turu (telefon yatay): xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x720 -s tools/shot_tour.gd -- <dil> <ülke_en>
var main
var out := ""
var n := 0
func _shot(tag: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
func _close() -> void:
	for i in 4:
		if main.ui._modal != null and is_instance_valid(main.ui._modal):
			main.ui._modal.queue_free()
			main.ui._modal = null
		await create_timer(0.2).timeout
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var lang: String = a[0] if a.size() > 0 else "en"
	var cn: String = a[1] if a.size() > 1 else "Turkey"
	out = "/tmp/tour_" + lang
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = lang; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.2).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	await _shot("menu")
	main._to_select()
	await create_timer(0.8).timeout
	await _shot("secim")
	var cid := -1
	for c in main.gs.countries:
		if c.name_en == cn: cid = c.id
	main._on_start_requested(cid)
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	await create_timer(0.4).timeout
	await _shot("oyun")
	main._on_ui_action("focus", main.gs.countries[cid].capital)
	await create_timer(0.8).timeout
	await _shot("eyalet")
	for t in [0, 1, 2, 3, 4, 7, 8, 9]:
		main.ui.PolicyUI.open(main.ui, main.gs, t)
		await _shot("politika_%d" % t)
		await _close()
	main.ui.DiplomacyUI.open(main.ui, main.gs, -1)
	await _shot("diplomasi")
	await _close()
	main.ui.show_pause_menu()
	await _shot("menu_oyun")
	await _close()
	main.ui.show_goals()
	await _shot("hedefler")
	await _close()
	for wt in [0, 1, 4]:
		main.ui.show_world_panel(wt)
		await _shot("dunya_%d" % wt)
		await _close()
	for i in 6:
		main.gs.end_turn()
	main.ui.refresh_top()
	await _shot("6tur_sonra")
	print("TUR_BITTI ", n)
	quit()
