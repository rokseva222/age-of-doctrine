extends SceneTree
## Ekrana sığmayan panelleri bulur. xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tools/overflow_scan.gd -- <ui_scale>
var main
var bad := 0
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _clipped(n: Node) -> bool:
	var p := n.get_parent()
	while p:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
func _scan(label: String) -> void:
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	var vp: Vector2 = get_root().get_visible_rect().size
	var found := []
	var stack: Array = [get_root()]
	while stack:
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is Control and n.is_visible_in_tree() and not _clipped(n):
			var r: Rect2 = n.get_global_rect()
			if r.size.x < 8 or r.size.y < 8:
				continue
			if r.size.x >= vp.x - 2 and r.size.y >= vp.y - 2:
				continue
			if n is PanelContainer or n is Button or n is Label:
				if r.end.y > vp.y + 3 or r.position.y < -3:
					found.append("%s %s y=%d..%d" % [n.get_class(), str(n.get_path()).right(60), r.position.y, r.end.y])
	if found.size() > 0:
		bad += 1
		print("TASMA [", label, "] vp=", vp, " ", found.slice(0, 4))
	else:
		print("ok [", label, "]")
func _close_all() -> void:
	for c in main.ui.get_children():
		if c.get_script() and str(c.get_script().resource_path).ends_with("sheet.gd"):
			c.queue_free()
	if main.ui.has_method("hide_dialog"):
		main.ui.hide_dialog()
	main.ui.hide_info()
	await _wait(0.3)
func _init() -> void:
	var sc := float(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 0.8
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.ui_scale = sc; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	St.ui_scale = sc; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	await _scan("menu")
	main._to_select()
	await _scan("select")
	for c in main.gs.countries:
		if c.name_en == "Turkey" or c.name == "Türkiye":
			main._on_start_requested(c.id)
			break
	await _wait(1.0)
	St.ui_scale = sc; St.tut_done = true; St.apply_display(self)
	var ui = main.ui
	var gs = main.gs
	await _scan("oyun")
	var tests := {
		"pause": func(): ui.show_pause_menu(),
		"goals": func(): ui.show_goals(),
		"relations": func(): ui.show_relations(gs.player),
		"relations_foe": func(): ui.show_relations(gs.neighbor_countries(gs.player)[0]),
		"politics": func(): ui.show_politics(),
		"daily": func(): ui.show_daily(),
		"chokes": func(): ui.show_chokes(),
		"grand_op": func(): ui.show_grand_op(gs.player),
		"world0": func(): ui.show_world_panel(0),
		"world1": func(): ui.show_world_panel(1),
		"world2": func(): ui.show_world_panel(2),
		"un_aid": func(): ui.show_un_targets("aid"),
		"province": func(): ui.show_province(gs.countries[gs.player].capital if "capital" in gs.countries[gs.player] else 0, null),
	}
	for k in tests:
		tests[k].call()
		await _scan(k)
		await _close_all()
	var PU = load("res://scripts/policy_ui.gd")
	for t in 5:
		PU.open(ui, gs, t)
		await _scan("policy%d" % t)
		await _close_all()
	var WR = load("res://scripts/war_room_ui.gd")
	WR.open(ui)
	await _scan("warroom"); await _close_all()
	var SL = load("res://scripts/slots_ui.gd")
	SL.open(ui, "load", func(_i): pass)
	await _scan("slots"); await _close_all()
	var IS = load("res://scripts/info_sheets.gd")
	IS.open_settings(main.ui, func(): pass)
	await _scan("settings"); await _close_all()
	IS.open_howto(main.ui)
	await _scan("howto"); await _close_all()
	IS.open_credits(main.ui)
	await _scan("credits"); await _close_all()
	print("TASMA_SAYISI=", bad)
	quit()
