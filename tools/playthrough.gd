extends SceneTree
## Baştan sona oynatma: menü -> seçim -> oyun, turlar, pencereler. Ekran görüntüleri /tmp/play/*.png
## Kullanım: xvfb-run ... godot --path . --rendering-driver opengl3 --resolution 1280x720 -s tools/playthrough.gd -- [tur_sayısı] [ülke]
const PolicyUI = preload("res://scripts/policy_ui.gd")
const Info = preload("res://scripts/info_sheets.gd")

var main
var out := "/tmp/play"
var n := 0
var seen := {}
var running := true
var log_lines: Array = []

func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	var path := "%s/%02d_%s.png" % [out, n, tag]
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)

func _title_of(m) -> String:
	if m != null and "title_lbl" in m and m.title_lbl != null:
		return str(m.title_lbl.text)
	return m.get_class() if m != null else ""

## Açık pencereyi (varsa) görüntüle ve kapat. Kabine/atama gibi seçmeli pencerelerde ilk seçeneği uygular.
func _handle_modal() -> bool:
	var ui = main.ui
	if not ui.is_dialog_open():
		return false
	var m = ui._modal
	var t := _title_of(m)
	var cnt: int = seen.get(t, 0)
	seen[t] = cnt + 1
	if cnt < 2:
		await _shot("modal_" + t.replace(" ", "_").replace("/", "-").substr(0, 24))
	log_lines.append("t=%d modal: %s" % [main.gs.turn, t])
	if "footer" in m and "body" in m:
		var btns: Array = []
		for b in m.body.find_children("*", "Button", true, false):
			if not b.disabled and b.visible:
				btns.append(b)
		if not btns.is_empty() and (t == "Kabine değişikliği" or t == "Kabine toplantısı"):
			btns[0].pressed.emit()
			await create_timer(0.6).timeout
			if cnt < 2:
				await _shot("result_" + t.replace(" ", "_").substr(0, 20))
			for fb in m.footer.find_children("*", "Button", true, false):
				fb.pressed.emit()
				break
			await create_timer(0.3).timeout
			if ui.is_dialog_open() and ui._modal == m:
				m.close()
			return true
		for fb2 in m.footer.find_children("*", "Button", true, false):
			if not fb2.disabled:
				fb2.pressed.emit()
				return true
		m.close()
		return true
	if m.has_method("close"):
		m.close()
		return true
	return false

func _pump() -> void:
	while running:
		await create_timer(0.45).timeout
		if main != null and main.mode == "game":
			await _handle_modal()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var args := OS.get_cmdline_user_args()
	var turns: int = int(args[0]) if args.size() > 0 else 30
	var country: String = args[1] if args.size() > 1 else "Türkiye"
	var Lc = load("res://scripts/loc.gd")
	var St0 = load("res://scripts/settings.gd")
	if OS.get_environment("LANG_SHOT") != "":
		St0.language = OS.get_environment("LANG_SHOT")
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Lc.debug = true
	await create_timer(0.8).timeout
	await _shot("splash")
	await create_timer(1.6).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	await _shot("menu_main")
	main._to_select()
	await create_timer(1.0).timeout
	await _shot("select_empty")
	var cid := -1
	for c in main.gs.countries:
		if c.name == country:
			cid = c.id
	main.menu.select_country(cid)
	await create_timer(0.8).timeout
	await _shot("select_" + country)
	main.menu._open_scenarios()
	await create_timer(0.7).timeout
	await _shot("scenarios")
	main.ui.hide_dialog()
	for ch in main.menu.get_children():
		pass
	main.menu._open_eras()
	await create_timer(0.7).timeout
	await _shot("eras")
	main.menu._select_first([]) if false else null
	# modal kapatma: menü kendi sheet'ini kullanıyor
	for s in get_root().find_children("*", "Control", true, false):
		if s.get_script() != null and s.get_script().resource_path.ends_with("sheet.gd"):
			s.close()
	await create_timer(0.4).timeout
	main.menu.select_country(cid)
	await create_timer(0.3).timeout
	main._on_start_requested(cid)
	await create_timer(1.3).timeout
	await _shot("game_start_howto")
	for s2 in get_root().find_children("*", "Control", true, false):
		if s2.get_script() != null and s2.get_script().resource_path.ends_with("sheet.gd"):
			s2.close()
	await create_timer(0.5).timeout
	Settings_set_howto()
	await _shot("game_hud")
	# yan düğmeler ve paneller
	var ui = main.ui
	for key in ["policy", "world", "wars"]:
		ui._side_pressed(key)
		await create_timer(0.7).timeout
		await _shot("side_" + key)
		ui.hide_dialog()
		await create_timer(0.3).timeout
	for tb in [0, 2, 3]:
		ui.show_world_panel(tb)
		await create_timer(0.7).timeout
		await _shot("world_tab%d" % tb)
		ui.hide_dialog()
		await create_timer(0.3).timeout
	for t in 8:
		PolicyUI.open(ui, main.gs, t)
		await create_timer(0.7).timeout
		await _shot("policy_tab%d" % t)
		ui.hide_dialog()
		await create_timer(0.3).timeout
	ui.show_pause_menu()
	await create_timer(0.6).timeout
	await _shot("pause_menu")
	ui.hide_dialog()
	await create_timer(0.3).timeout
	Info.open_settings(ui.root, func(): pass, main.sfx)
	await create_timer(0.6).timeout
	await _shot("settings")
	close_sheets()
	Info.open_howto(ui.root)
	await create_timer(0.6).timeout
	await _shot("howto")
	close_sheets()
	_pump()
	# --- oyun: savaş aç, turlar
	var gs = main.gs
	var me = gs.countries[gs.player]
	var foe := -1
	var best := 1.0e18
	for nb in gs.neighbor_countries(gs.player):
		var oc = gs.countries[nb]
		if oc.alive and not oc.is_rebel and oc.troops < best and not me.allies.has(nb):
			best = oc.troops
			foe = nb
	if foe >= 0:
		main._on_ui_action("war", foe)
		log_lines.append("savaş: %s" % gs.countries[foe].name)
	main._on_ui_action("capital", 0)
	await create_timer(0.6).timeout
	await _shot("capital_card")
	for i in turns:
		var wait := 0
		while (main.ui.is_dialog_open() or main.turn_busy) and wait < 60:
			await create_timer(0.25).timeout
			wait += 1
		_bot_orders(gs, me)
		main._on_step()
		var guard := 0
		while main.turn_busy and guard < 120:
			await create_timer(0.25).timeout
			guard += 1
		if guard >= 120:
			log_lines.append("UYARI: tur %d takıldı" % gs.turn)
			break
		if i in [0, 4, 12, 24]:
			await _shot("turn_%d_map" % gs.turn)
		if not me.alive or not main.playing:
			break
	await _shot("end_state")
	await create_timer(0.5).timeout
	print("--- günlük ---")
	for l in log_lines:
		print(l)
	print("tur=", gs.turn, " ülke yaşıyor=", me.alive, " eyalet=", me.prov_owned, " kasa=", int(me.gold), " asker=", me.troops)
	running = false
	var f := FileAccess.open("/tmp/loc_misses.txt", FileAccess.WRITE)
	for k in Lc.misses:
		f.store_line(str(k).replace("\n", "\\n"))
	f.close()
	Lc.apply("tr")
	quit()

func Settings_set_howto() -> void:
	load("res://scripts/settings.gd").seen_howto = true

func close_sheets() -> void:
	for s in get_root().find_children("*", "Control", true, false):
		if s.get_script() != null and s.get_script().resource_path.ends_with("sheet.gd"):
			s.close()

func _bot_orders(gs, me) -> void:
	# basit oyuncu botu: ordular düşman eyaletine yürür
	for a in gs.armies_of(me.id):
		if a.target >= 0 if "target" in a else false:
			continue
		var best := -1
		var bd := 1.0e9
		for e in me.enemies:
			for p in gs.provinces:
				if p.owner == e and p.controller != me.id:
					var d: float = gs.provinces[a.prov].center.distance_to(p.center) if "center" in p else 0.0
					if d < bd:
						bd = d
						best = p.id
		if best >= 0:
			gs.player_order_move(a, best)
