extends SceneTree
## Dil taşma denetimi: savaşta bir eyalet kartı + taarruz penceresi + birkaç panel; metin taşmalarını tarar ve ekran görüntüsü alır.
## xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/shot_lang.gd -- <dil>
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _scan(n: Node, tag: String, out: Array) -> void:
	if n is Control and not (n as Control).is_visible_in_tree():
		return
	if n is Label or n is Button:
		var c: Control = n
		var txt: String = c.atr(c.text)
		if txt != "" and c.size.x > 4:
			var f: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			var wrap := n is Label and (n as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
			var need: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if not wrap and not txt.contains("\n") and need > c.size.x + 2.0:
				out.append("%s | %s | need %d > %d | %s" % [tag, c.get_path().get_name(c.get_path().get_name_count() - 1), need, c.size.x, txt.substr(0, 40)])
			var r := c.get_global_rect()
			var vp := get_root().get_visible_rect()
			if r.end.x > vp.end.x + 2 or r.position.x < -2:
				out.append("%s | OFFSCREEN | %s" % [tag, txt.substr(0, 40)])
	for ch in n.get_children():
		_scan(ch, tag, out)
func _init() -> void:
	var lang: String = OS.get_cmdline_user_args()[0]
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = lang; St.seen_howto = true
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 1:
		St.ui_scale = float(ua[1])
	if ua.size() > 2:
		DisplayServer.window_set_size(Vector2i(int(ua[2]), int(ua[3])))
	St.save_all()
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._start_era("ww2")
	await create_timer(1.0).timeout
	var gs = main.gs
	var cid: int = int(gs.macro_idx.get("Germany", 0))
	main.menu.select_country(cid)
	await create_timer(0.8).timeout
	main._on_start_requested(cid)
	await create_timer(1.5).timeout
	var out := "/tmp/lang_%s_%s" % [lang, OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else "d"]
	DirAccess.make_dir_recursive_absolute(out)
	var issues: Array = []
	# savaş ilan et ve komşu eyalet bul
	var target := -1
	for pr in gs.provinces:
		if pr.owner != cid and pr.owner >= 0:
			for nb in pr.neighbors:
				if gs.provinces[nb].owner == cid and gs.armies.has(nb) and gs.armies[nb].owner == cid:
					target = pr.id; break
		if target >= 0: break
	if target >= 0 and not gs.at_war(cid, gs.provinces[target].owner):
		gs.declare_war(cid, gs.provinces[target].owner)
	await create_timer(0.3).timeout
	main.ui.show_province(target, null)
	await create_timer(0.6).timeout
	await _shot(out + "/01_card.png")
	_scan(get_root(), "card", issues)
	var AU = load("res://scripts/assault_ui.gd")
	AU.open(main.ui, gs, target, func(): pass)
	await create_timer(0.8).timeout
	await _shot(out + "/02_assault.png")
	_scan(get_root(), "assault", issues)
	main.ui.hide_dialog()
	await create_timer(0.2).timeout
	var calls := [["goals", func(): main.ui.show_goals()], ["relations", func(): main.ui.show_relations(cid)], ["politics", func(): main.ui.show_politics()], ["world", func(): main.ui.show_world_panel(0)], ["pause", func(): main.ui.show_pause_menu()], ["grand", func(): main.ui.show_grand_op(cid)]]
	var n := 3
	for c in calls:
		main.ui.hide_dialog()
		await create_timer(0.1).timeout
		c[1].call()
		await create_timer(0.5).timeout
		await _shot("%s/%02d_%s.png" % [out, n, c[0]])
		_scan(get_root(), c[0], issues)
		n += 1
	print("TARGET ", target, " ISSUES ", issues.size())
	for i in issues:
		print("ISSUE| ", i)
	quit()
