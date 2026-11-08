extends SceneTree
## Harita HUD çizim maliyeti ölçümü (xvfb + yazılım GL; mutlak değil, önce/sonra karşılaştırması içindir).
var main
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _frames(n: int, label: String, pan := false) -> void:
	var t0 := Time.get_ticks_usec()
	for i in n:
		if pan:
			main.map.cam_pos += Vector2(3, 1)
			main.map._apply()
		await RenderingServer.frame_post_draw
	var dt := float(Time.get_ticks_usec() - t0) / n / 1000.0
	print("%-34s %.1f ms/kare" % [label, dt])
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	St.ui_scale = 0.8; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.6)
	main._to_select()
	await _wait(0.5)
	for c in main.gs.countries:
		if c.name_en == "Turkey":
			main._on_start_requested(c.id)
			break
	await _wait(1.0)
	St.tut_done = true
	main.ui.hide_info()
	main.map.focus_country(main.gs.player)
	await _wait(1.5)
	main.map.select_province(main.gs.countries[main.gs.player].capital) if main.map.has_method("select_province") else null
	await _wait(0.5)
	await _frames(60, "sabit harita, eyalet secili")
	await _frames(60, "kaydirma (pan)", true)
	main.map.selected_prov = -1
	await _frames(60, "sabit harita, secim yok")
	print("BENCH_BITTI")
	quit()
