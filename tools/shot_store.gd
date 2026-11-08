extends SceneTree
## Play Store ekran görüntüleri (1920x1080 ile çalıştır): store/screens/*.png
const PolicyUI = preload("res://scripts/policy_ui.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)

func _init() -> void:
	var out := "/tmp/store_shots"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(2.6).timeout
	await _shot(out + "/s0_splash.png")
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	await _shot(out + "/s1_menu.png")
	main._to_select()
	await create_timer(1.0).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	main.menu.select_country(tr_id)
	await create_timer(1.6).timeout
	await _shot(out + "/s2_select.png")
	load("res://scripts/settings.gd").seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	var gs = main.gs
	# arka plan haritası (HUD'suz)
	main.ui.set_hud_visible(false)
	main.ui.toast_panel.visible = false
	main.map.hud.show_armies = false
	main.map.hud.queue_redraw()
	main.map.animate_to(main.map.world_rect().get_center() + Vector2(300, -250), main.map.min_zoom * 2.2, 0.05)
	await create_timer(1.0).timeout
	await _shot(out + "/map_bg.png")
	main.ui.set_hud_visible(true)
	main.map.hud.show_armies = true
	main.map.focus_country(tr_id)
	var foe_c: int = gs.neighbor_countries(tr_id)[0]
	gs.player_declare_war(foe_c)
	var target := -1
	for p in gs.provinces:
		if p.owner == foe_c and not gs.armies_near(p.id, 6).is_empty():
			target = p.id
			break
	main.map.focus_province(target, 2.6)
	main._select(target)
	await create_timer(1.2).timeout
	await _shot(out + "/s3_game.png")
	main._on_ui_action("assault", target)
	await create_timer(0.8).timeout
	await _shot(out + "/s4_assault.png")
	var sh = main.ui._modal
	for b in sh.footer.get_children():
		if b is Button:
			b.pressed.emit()
			break
	await create_timer(0.5).timeout
	main._on_step()
	await create_timer(2.8).timeout
	await _shot(out + "/s5_report.png")
	main.ui.hide_dialog()
	await create_timer(0.6).timeout
	for i in 3:
		main._on_step()
		await create_timer(1.8).timeout
		if main.ui.is_dialog_open():
			main.ui.hide_dialog()
		await create_timer(0.4).timeout
	PolicyUI.open(main.ui, gs, 0)
	await create_timer(0.8).timeout
	await _shot(out + "/s6_budget.png")
	main.ui.hide_dialog()
	main._go_main_menu()
	await create_timer(1.0).timeout
	main._start_era("ww2")
	await create_timer(1.4).timeout
	main._on_start_requested(main.menu._sel)
	await create_timer(1.8).timeout
	main.ui.refresh_top()
	main.map.animate_to(main.map.world_rect().get_center(), main.map.min_zoom * 1.7, 0.1)
	await create_timer(1.0).timeout
	main.ui.hide_dialog()
	await _shot(out + "/s7_ww2.png")
	quit()
