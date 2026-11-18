extends SceneTree
var main
var hide_dialogs := false
func _tick() -> void:
	if hide_dialogs and main != null:
		var m = main.ui._modal
		if m != null and is_instance_valid(m):
			m.visible = false
			m.queue_free()
			main.ui._modal = null
		main.ui.toast_panel.visible = false
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var clip: String = OS.get_cmdline_user_args()[0]
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	St.ui_scale = 0.8; St.language = "tr"; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	main.ui.toast_panel.visible = false
	hide_dialogs = clip != "form"
	process_frame.connect(_tick)
	match clip:
		"ott":
			main.menu.hide()
			main._start_era("ott1520")
			await _wait(0.8)
			main._on_start_requested(main.menu._sel)
			await _wait(0.8)
			main.ui.hide_dialog()
			var gs = main.gs
			gs.countries[gs.player].auto_cmd = true
			main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
			main.map.hud.show_armies = true
			var firstfoe := -1
			for n in gs.neighbor_countries(gs.player):
				if gs.countries[gs.player].truce.get(n, -1) <= gs.turn:
					gs.player_declare_war(n)
					if firstfoe < 0 and gs.countries[n].name_en != "": firstfoe = n
			main.map.focus_country(gs.player)
			await _wait(1.5)
			for i in 70:
				if main.ui.is_dialog_open(): main.ui.hide_dialog()
				main._do_turn(); _tick(); main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
				main.map.hud.queue_redraw()
				await _wait(0.22)
		"ww2":
			main.menu.hide()
			main._start_era("ww2")
			await _wait(0.8)
			main._on_start_requested(main.menu._sel)
			await _wait(0.8)
			main.ui.hide_dialog()
			var gs = main.gs
			gs.countries[gs.player].auto_cmd = true
			main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
			main.map.hud.show_armies = true
			main.map.focus_country(gs.player)
			await _wait(1.0)
			for i in 60:
				if main.ui.is_dialog_open(): main.ui.hide_dialog()
				main._do_turn(); _tick(); main.ui.hide_info(); main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
				main.map.hud.queue_redraw()
				await _wait(0.22)
		"modern":
			main._to_select()
			await _wait(0.5)
			var tid := -1
			for c in main.gs.countries:
				if c.name_en == "Turkey": tid = c.id
			main._on_start_requested(tid)
			await _wait(1.0)
			main.ui.hide_dialog()
			var gs = main.gs
			gs.countries[gs.player].auto_cmd = true
			main.ui.hide_info(); main.ui.set_hud_visible(false)
			main.map.hud.show_armies = true
			for c in gs.countries:
				if c.name_en in ["Georgia", "Armenia", "Syria"]:
					gs.player_declare_war(c.id)
			main.map.focus_country(gs.player)
			await _wait(1.5)
			for i in 70:
				main._do_turn(); _tick(); main.ui.hide_info(); main.ui.set_hud_visible(false)
				main.map.hud.queue_redraw()
				await _wait(0.22)
		"form":
			main._to_select()
			await _wait(0.5)
			var cid := -1
			for c in main.gs.countries:
				if c.name_en == "Turkey": cid = c.id
			main._on_start_requested(cid)
			await _wait(1.0)
			main.ui.hide_dialog(); main.ui.hide_info()
			var gs = main.gs
			var F = load("res://scripts/formables.gd")
			var f = F.available(gs)[0]
			main.ui.set_hud_visible(false); main.ui.toast_panel.visible = false
			var cap := -1
			for pp in gs.provinces:
				if pp.owner == gs.player and pp.is_capital: cap = pp.id
			main.map.focus_province(cap, 3.2)
			await _wait(1.0)
			main.ui.toast_panel.visible = false
			var order := ["Syria","Iraq","Lebanon","Jordan","Israel","Palestine","Egypt","Cyprus","Greece","Bulgaria","Serbia","Albania","North Macedonia","Bosnia and Herz.","Kosovo"]
			for nm in order:
				for c in gs.countries:
					if c.name_en == nm:
						gs.sandbox_annex_country(c.id, gs.player)
				main.map.repaint_all()
				main.ui.toast_panel.visible = false
				await _wait(0.7)
			await _wait(0.8)
			main.ui.set_hud_visible(true)
			main.ui.FormationUI.open(main.ui, gs)
			await _wait(2.5)
			await _shot("/tmp/promo/form_ui.png")
			var err = F.form(gs, f)
			print("form err=", err)
			main.ui.hide_dialog()
			main.map.repaint_all()
			await _wait(3.0)
			await _shot("/tmp/promo/form_done.png")
	quit()
