extends SceneTree
## Çağlı senaryo: düzenleyicide çağ seçimi, harita önizleme, menüden seçip başlatma
const Ed = preload("res://scripts/scenario_editor.gd")
const U = preload("res://scripts/user_scn.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _has(b: Button, needles: Array) -> bool:
	for n in needles:
		if b.text.contains(n):
			return true
	return false
func _init() -> void:
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_ee"
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	St.seen_howto = true
	St.seen_update = "1.2.13"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	Ed.open(main.menu.root, {}, func(_id): pass)
	await create_timer(0.8).timeout
	await _shot(out + "/01_editor.png")
	# WW2 seç
	var ed_sheet = main.menu.root.get_children().back()
	var btn: Button = null
	for b in ed_sheet.find_children("*", "Button", true, false):
		if _has(b, ["II. Dünya", "II. DÜNYA", "WAR II"]):
			btn = b
	print("ww2 düğmesi: ", btn != null)
	btn.pressed.emit()
	await create_timer(0.8).timeout
	var ed2 = main.menu.root.get_children().back()
	var lbls: Array = []
	for l in ed2.find_children("*", "Label", true, false):
		if l.text.contains("/ "):
			lbls.append(l.text)
	print("sayfa etiketi: ", lbls.slice(0, 2))
	await _shot(out + "/02_editor_ww2.png")
	# kaydedilmiş bir senaryo gibi: Almanya'nın bir ilini Polonya'ya devret
	var info: Dictionary = U.era_info("ww2")
	var pids: Array = []
	for p in info["provs"]:
		if p["en"] == "Germany" and pids.size() < 6:
			pids.append(int(p["id"]))
	var d := {"id": U.new_id(), "kind": "user", "name": "Polonya Büyür", "sub": "WW2 denemesi", "blurb": "b", "intro": "Giriş.", "suggest": ["Poland"], "era": "ww2",
		"transfer": pids.map(func(pid): return [pid, "Germany", "Poland", "own", ""]),
		"objectives": {"*": [{"id": "o0", "type": "survive", "turns": 20, "text": ""}]}}
	var fin := U.finalize(U.sanitize(d))
	print("kaydet: ", U.save(fin))
	main.menu.root.get_children().back().close()
	await create_timer(0.5).timeout
	# editörü kayıtlı senaryoyla aç, önizleme
	Ed.open(main.menu.root, U.load_one(fin["id"]), func(_id): pass)
	await create_timer(0.8).timeout
	var sh2 = main.menu.root.get_children().back()
	for sc in sh2.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 0
	var prev_btn: Button = null
	for pg in 3:
		for b in sh2.find_children("*", "Button", true, false):
			if _has(b, ["Haritada önizle", "HARİTADA ÖNİZLE", "HARITADA ÖNIZLE", "PREVIEW"]):
				prev_btn = b
		if prev_btn != null: break
		for b in sh2.find_children("*", "Button", true, false):
			if _has(b, ["İleri", "İLERİ", "ILERI", "NEXT"]):
				b.pressed.emit()
		await create_timer(0.3).timeout
	print("önizleme düğmesi: ", prev_btn != null)
	await _shot(out + "/03_transfer_page.png")
	prev_btn.pressed.emit()
	await create_timer(1.6).timeout
	await _shot(out + "/04_preview.png")
	main._end_map_preview()
	await create_timer(0.6).timeout
	print("önizleme sonrası Eras.current='", load("res://scripts/eras.gd").current, "' sheet görünür=", sh2.visible)
	main.menu.root.get_children().back().close()
	await create_timer(0.4).timeout
	# menüden senaryoyu seç → dünya WW2'ye kurulur
	main._to_select()
	await create_timer(0.8).timeout
	main.menu.set_scenario(fin["id"])
	await create_timer(1.8).timeout
	print("seçim sonrası Eras.current=", load("res://scripts/eras.gd").current, " era_scn=", main.menu.era_scn)
	await _shot(out + "/05_select.png")
	var pl: int = main.gs.macro_idx["Poland"]
	main._on_start_requested(pl)
	await create_timer(1.5).timeout
	print("oyun: yıl=", load("res://scripts/names.gd").year_month(main.gs.turn), " il sahibi=", main.gs.provinces[pids[0]].owner, " Polonya=", pl)
	await _shot(out + "/06_game.png")
	U.remove(String(fin["id"]))
	quit()
