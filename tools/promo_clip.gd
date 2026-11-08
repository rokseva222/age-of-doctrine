extends SceneTree
## Tanıtım klipleri/ekran görüntüleri (İngilizce arayüz). Kullanım:
## xvfb-run -a godot --path . --rendering-driver opengl3 --write-movie /tmp/promo/x.avi --fixed-fps 30 --resolution 1920x1080 -s tools/promo_clip.gd -- <clip>
var main
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _turns(n: int, gap: float) -> void:
	for i in n:
		if main.ui.is_dialog_open():
			main.ui.hide_dialog()
		main._do_turn()
		main.ui.hide_info()
		main.map.hud.queue_redraw()
		await _wait(gap)
func _start(cname: String) -> int:
	var cid := -1
	for c in main.gs.countries:
		if c.name_en == cname or c.name == cname:
			cid = c.id
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").tut_done = true
	main._on_start_requested(cid)
	return cid
func _init() -> void:
	var clip: String = OS.get_cmdline_user_args()[0]
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "en"; St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	St.ui_scale = 0.8; St.language = "en"; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	match clip:
		"conquest":
			main._to_select()
			await _wait(0.5)
			var cid := _start("Turkey")
			await _wait(1.0)
			var gs = main.gs
			var f = gs.countries[gs.player]
			f.auto_cmd = true
			var foe: int = gs.neighbor_countries(gs.player)[0]
			gs.player_declare_war(foe)
			main.ui.toast_panel.visible = false
			main.ui.hide_info()
			main.map.focus_country(foe)
			await _wait(1.5)
			await _turns(40, 0.28)
			await _wait(1.0)
		"cine1":
			main._to_select()
			await _wait(0.5)
			_start("Turkey")
			await _wait(0.8)
			var gs = main.gs
			var f = gs.countries[gs.player]
			f.auto_cmd = true
			main.ui.set_hud_visible(false)
			main.ui.toast_panel.visible = false
			main.ui.hide_info()
			main.map.hud.show_armies = true
			var foe: int = gs.neighbor_countries(gs.player)[0]
			gs.player_declare_war(foe)
			main.map.focus_country(foe)
			await _wait(1.0)
			for i in 60:
				if main.ui.is_dialog_open():
					main.ui.hide_dialog()
				main._do_turn()
				main.ui.hide_info()
				main.ui.set_hud_visible(false)
				main.map.hud.queue_redraw()
				await _wait(0.3)
		"cine2":
			main.menu.hide()
			main._start_era("ww2")
			await _wait(0.8)
			load("res://scripts/settings.gd").tut_done = true
			load("res://scripts/settings.gd").seen_howto = true
			main._on_start_requested(main.menu._sel)
			await _wait(0.8)
			main.ui.hide_dialog()
			main.ui.set_hud_visible(false)
			main.ui.hide_info()
			main.map.hud.show_armies = true
			main.map.animate_to(main.map.world_rect().get_center() + Vector2(250, -120), main.map.min_zoom * 3.2, 0.1)
			await _wait(0.5)
			main.map.animate_to(main.map.world_rect().get_center() + Vector2(480, -120), main.map.min_zoom * 3.2, 11.0)
			for i in 14:
				await _wait(0.8)
		"cine3":
			main.menu.hide()
			main._start_era("ww2")
			await _wait(0.8)
			load("res://scripts/settings.gd").tut_done = true
			load("res://scripts/settings.gd").seen_howto = true
			main._on_start_requested(main.menu._sel)
			await _wait(0.8)
			main.ui.hide_dialog()
			var gs = main.gs
			var f = gs.countries[gs.player]
			f.auto_cmd = true
			main.ui.set_hud_visible(false)
			main.ui.hide_info()
			main.map.hud.show_armies = true
			main.map.focus_country(gs.player)
			await _wait(0.8)
			for i in 52:
				main._do_turn()
				main.ui.hide_dialog()
				main.ui.hide_info()
				main.ui.set_hud_visible(false)
				main.map.hud.queue_redraw()
				if i == 26:
					main.map.animate_to(main.map.camera_center() + Vector2(120, 0), main.map.zoom_now() * 0.8, 6.0) if main.map.has_method("camera_center") else null
				await _wait(0.25)
		"war":
			main._to_select()
			await _wait(0.5)
			_start("Turkey")
			await _wait(1.0)
			var gs = main.gs
			var foe_c: int = gs.neighbor_countries(gs.player)[0]
			gs.player_declare_war(foe_c)
			var target := -1
			for p in gs.provinces:
				if p.owner == foe_c and not gs.armies_near(p.id, 6).is_empty():
					target = p.id
					break
			main.map.focus_province(target, 2.6)
			main._select(target)
			await _wait(2.0)
			main._on_ui_action("assault", target)
			await _wait(2.5)
			var sh = main.ui._modal
			for b in sh.footer.get_children():
				if b is Button:
					b.pressed.emit()
					break
			await _wait(3.0)
		"ww2":
			main.menu._open_eras()
			await _wait(1.5)
			main.menu.hide()
			main._start_era("ww2")
			await _wait(1.0)
			load("res://scripts/settings.gd").tut_done = true
			load("res://scripts/settings.gd").seen_howto = true
			main._on_start_requested(main.menu._sel)
			await _wait(1.0)
			main.ui.hide_dialog()
			load("res://scripts/settings.gd").tut_done = true
			main.ui.hide_info()
			main.map.animate_to(main.map.world_rect().get_center(), main.map.min_zoom * 1.7, 0.1)
			await _wait(1.0)
			main.map.animate_to(main.map.world_rect().get_center() + Vector2(500, -200), main.map.min_zoom * 2.6, 6.0)
			await _wait(7.0)
	quit()
