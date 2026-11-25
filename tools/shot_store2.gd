extends SceneTree
## Play Store ekran görüntüleri (güncel oyun): 1920x1080 ile çalıştır. SLANG=tr|en, STAGE=1..4, SHOTS=çıktı klasörü
const PolicyUI = preload("res://scripts/policy_ui.gd")
var main
func _shot(path: String, wait := 0.0) -> void:
	if wait > 0.0:
		await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
	print("shot ", path)
func _cid(en: String, tr: String) -> int:
	for c in main.gs.countries:
		if c.name_en == en or c.name == tr:
			return c.id
	return -1
func _init() -> void:
	var lang: String = OS.get_environment("SLANG") if OS.get_environment("SLANG") != "" else "tr"
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/store2_" + lang
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = lang; St.ui_scale = 0.8; St.ui_scale_custom = true; St.tut_done = true; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var stage: String = OS.get_environment("STAGE") if OS.get_environment("STAGE") != "" else "1"
	await create_timer(1.6).timeout
	main.menu.finish_splash()
	await create_timer(1.5).timeout
	var gs
	if stage == "1":
		await _shot(out + "/1_menu.png")
		main._to_select()
		await create_timer(1.0).timeout
		main.menu.select_country(_cid("Turkey", "Türkiye"))
		await _shot(out + "/2_select.png", 1.6)
	elif stage == "2":
		main.menu.set_scenario("kara")
		main._to_select()
		await create_timer(1.0).timeout
		var tr_id := _cid("Turkey", "Türkiye")
		main._on_start_requested(tr_id)
		await create_timer(1.8).timeout
		gs = main.gs
		main.ui.hide_dialog()
		var foe_c := -1
		for c in gs.countries:
			if c.alive and c.id != tr_id and gs.at_war(tr_id, c.id) and (c.is_rebel or c.name_en.begins_with("Kara") or c.name.begins_with("Kara")):
				foe_c = c.id
		if foe_c < 0:
			for c in gs.countries:
				if c.alive and c.id != tr_id and gs.at_war(tr_id, c.id):
					foe_c = c.id
		for c in gs.countries:
			if c.alive and ("Kara Sancak" in c.name or "Black Banner" in c.name_en or "Kara Sancak" in c.name_en):
				foe_c = c.id
		print("foe=", foe_c, " ", gs.countries[foe_c].name if foe_c >= 0 else "-")
		if foe_c < 0:
			foe_c = gs.neighbor_countries(tr_id)[0]
		if not gs.at_war(tr_id, foe_c):
			gs.player_declare_war(foe_c)
		var target := -1
		for p in gs.provinces:
			if p.owner == foe_c and not gs.armies_near(p.id, 6).is_empty():
				target = p.id
				break
		if target < 0:
			for p in gs.provinces:
				if p.owner == foe_c:
					target = p.id
					break
		main.map.focus_province(target, 2.6)
		main._select(target)
		await _shot(out + "/3_map.png", 1.4)
		main._on_ui_action("assault", target)
		await _shot(out + "/4_assault.png", 0.9)
		var sh = main.ui._modal
		for b in sh.footer.get_children():
			if b is Button:
				b.pressed.emit()
				break
		await create_timer(0.5).timeout
		main._on_step()
		await _shot(out + "/5_report.png", 2.8)
		main.ui.hide_dialog()
		await create_timer(0.6).timeout
		for i in 3:
			main._on_step()
			await create_timer(1.8).timeout
			if main.ui.is_dialog_open():
				main.ui.hide_dialog()
			await create_timer(0.4).timeout
		PolicyUI.open(main.ui, gs, 0)
		await _shot(out + "/6_budget.png", 0.9)
	elif stage == "3":
		main._start_era("ww2")
		await create_timer(1.4).timeout
		main._on_start_requested(main.menu._sel)
		await create_timer(2.2).timeout
		main.ui.hide_dialog()
		main.ui.refresh_top()
		main.map.animate_to(main.map.world_rect().get_center(), main.map.min_zoom * 1.7, 0.1)
		await create_timer(0.8).timeout
		main.ui.hide_dialog()
		await _shot(out + "/7_ww2.png", 0.8)
	else:
		main.menu.set_scenario("cau")
		main._to_select()
		await create_timer(1.0).timeout
		main._on_start_requested(_cid("Azerbaijan", "Azerbaycan"))
		await create_timer(2.2).timeout
		main.ui.hide_dialog()
		var ids := {}
		for c in main.gs.countries:
			if c.name_en in ["Azerbaijan", "Armenia", "Georgia"]:
				ids[c.id] = true
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		for p in main.gs.provinces:
			if ids.has(p.owner):
				lo = lo.min(p.label_pos)
				hi = hi.max(p.label_pos)
		main.map.animate_to(main.map._center_offset((lo + hi) * 0.5, 14.0), 14.0, 0.1)
		await create_timer(1.0).timeout
		var mm = JSON.parse_string(FileAccess.get_file_as_string("res://data/scn_moments/cau.json"))
		for m in mm["moments"]:
			if m["id"] == "cau_tcm":
				main.gs.moment_pending = {"id": m["id"], "role": "Azerbaijan", "m": m}
				main._on_moment_card()
		await _shot(out + "/8_kafkas.png", 1.5)
	quit()
