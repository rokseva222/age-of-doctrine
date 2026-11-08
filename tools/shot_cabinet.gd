extends SceneTree
## Kabine kartı ekran görüntüleri: farklı ülke ve roller.
const Cabinet = preload("res://scripts/cabinet.gd")
const CabinetUI = preload("res://scripts/cabinet_ui.gd")

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)

func _init() -> void:
	var out := "/tmp/shots_cab"
	DirAccess.make_dir_recursive_absolute(out)
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(0.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	var plan := [["Türkiye", "d_drill"], ["Rusya", "i_protest"], ["ABD", "fn_deficit"], ["Çin", "s_cyberhit"], ["Japonya", "h_epidemic"], ["Suudi Arabistan", "f_summit"], ["Nijerya", "a_summit"], ["Kenya", "a_leak"], ["Japonya", "a_trade"]]
	var idx := 0
	for pr in plan:
		var cid := -1
		for c in main.gs.countries:
			if c.name == pr[0]:
				cid = c.id
		if cid < 0:
			print("yok: ", pr[0])
			continue
		main._on_start_requested(cid)
		await create_timer(1.2).timeout
		var card: Dictionary = {}
		for cd in Cabinet.CARDS:
			if cd.id == pr[1]:
				card = cd
		var rng := RandomNumberGenerator.new()
		var sh = CabinetUI.open(main.ui, main.gs, card, rng, func(t): pass)
		await create_timer(0.7).timeout
		await _shot("%s/%d_%s.png" % [out, idx, pr[1]])
		if idx == 0:
			# ilk seçeneği uygula
			var opts: Node = sh.find_children("*", "Button", true, false)[0]
			opts.pressed.emit()
			await create_timer(0.5).timeout
			await _shot("%s/%d_result.png" % [out, idx])
		sh.close()
		await create_timer(0.3).timeout
		main._go_main_menu()
		await create_timer(0.8).timeout
		main._to_select()
		await create_timer(0.6).timeout
		idx += 1
	quit()
