extends SceneTree
## Tur sistemi ve taarruz akışı: ekran görüntüleri
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)

func _init() -> void:
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_turn"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	load("res://scripts/settings.gd").seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	var gs = main.gs
	var foe_c: int = gs.neighbor_countries(tr_id)[0]
	print("komşu: ", gs.countries[foe_c].name)
	gs.player_declare_war(foe_c)
	# düşman eyalet: bir Türk ordusunun yakınındaki
	var target := -1
	for p in gs.provinces:
		if p.owner == foe_c:
			var near: Array = gs.armies_near(p.id, 6)
			if not near.is_empty():
				target = p.id
				break
	print("hedef: ", target)
	main.map.focus_province(target, 3.0)
	main._select(target)
	await create_timer(1.2).timeout
	await _shot(out + "/01_card.png")
	main._on_ui_action("assault", target)
	await create_timer(0.8).timeout
	await _shot(out + "/02_assault.png")
	# harekâtı başlat (en iyi ordu seçili): düğmeyi bul
	var sh = main.ui._modal
	var go: Button = null
	for b in sh.footer.get_children():
		if b is Button and go == null:
			go = b
	go.pressed.emit()
	await create_timer(0.8).timeout
	await _shot(out + "/03_launched.png")
	main._on_step()
	await create_timer(0.6).timeout
	await _shot(out + "/04_loading.png")
	await create_timer(2.0).timeout
	await _shot(out + "/05_report.png")
	main.ui.hide_dialog()
	await create_timer(0.5).timeout
	for i in 4:
		main._on_step()
		await create_timer(1.8).timeout
		if main.ui.is_dialog_open():
			main.ui.hide_dialog()
		await create_timer(0.4).timeout
	await _shot(out + "/06_after4.png")
	print("tur=", gs.turn, " savaşlar=", gs.turn_battles.size())
	quit()
