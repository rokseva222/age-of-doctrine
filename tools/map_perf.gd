extends SceneTree
## Harita kaydırma/yakınlaştırma kare süresi (masaüstü yazılım çizimi: yalnızca göreli karşılaştırma içindir).
var main
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.tut_done = true; St.seen_howto = true; St.seen_promo = true
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.6).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(0.6).timeout
	main._on_start_requested(int(OS.get_environment("CID")) if OS.get_environment("CID") != "" else 0)
	await create_timer(2.0).timeout
	main.ui.hide_dialog()
	var m = main.map
	for z in [0.8, 3.0, 12.0]:
		m.zoom = z; m._apply()
		await process_frame
		await process_frame
		var t0 := Time.get_ticks_usec()
		var N := 40
		for i in N:
			m.cam_pos += Vector2(6.0 / z, 2.0 / z)
			m._apply()
			await process_frame
		print("kaydırma zoom=%5.1f kare=%6.1f ms" % [z, (Time.get_ticks_usec() - t0) / 1000.0 / N])
	# yakınlaştırma (sıkıştırma hareketi)
	m.zoom = 2.0; m._apply()
	await process_frame
	var t1 := Time.get_ticks_usec()
	for i in 40:
		m.zoom_at(Vector2(960, 540), 1.02 if i < 20 else 0.98)
		await process_frame
	print("yakınlaştırma kare=%6.1f ms" % [(Time.get_ticks_usec() - t1) / 1000.0 / 40.0])
	# görsel doğruluk: kaydırılmış HUD ile tam çizim aynı yerde mi?
	m.zoom = 4.0; m._apply()
	await create_timer(0.5).timeout
	m.cam_pos += Vector2(30, 10); m._apply()
	await process_frame
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/lazy.png")
	m.hud_redraw()
	await process_frame
	await process_frame
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/full.png")
	quit()
