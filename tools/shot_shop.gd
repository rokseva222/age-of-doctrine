extends SceneTree
const AP = preload("res://scripts/ap.gd")
const ApUi = preload("res://scripts/ap_ui.gd")
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var keep = St.ap.duplicate(true)
	St.ap = {"bal": 135}
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute("/tmp/shots_shop")
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_shop/01_menu.png")
	ApUi.open(main.menu.root, main.menu.toast)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_shop/02_shop.png")
	main.menu.toast("+3 AP")
	main.menu.root.get_children().back().queue_free()
	await create_timer(0.3).timeout
	main.menu._open_scenarios()
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_shop/03_scn.png")
	ApUi.open_unlock(main.menu.root, "scn", "kara", "Kara Sancak", main.menu.toast)
	await create_timer(0.8).timeout
	await _shot("/tmp/shots_shop/04_unlock.png")
	St.ap = keep; St.save_all()
	quit()
