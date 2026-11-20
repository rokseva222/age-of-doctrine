extends SceneTree
## Telefon boyutu görsel kontrol: --resolution WxH ile çalıştır. OUT=<önek>
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true; St.seen_update = "1.2.21"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	var out := OS.get_environment("OUT")
	main.menu.finish_splash()
	await create_timer(1.2).timeout
	await _shot(out + "_menu.png")
	main._start_career("ott1520", {"host_en": "Turkey", "bg": "cavalry", "name": "Kemal Bey"})
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	await create_timer(0.6).timeout
	await _shot(out + "_game.png")
	main.ui.show_career()
	await create_timer(1.0).timeout
	await _shot(out + "_sheet.png")
	quit()
