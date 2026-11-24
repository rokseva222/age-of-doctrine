extends SceneTree
var main
var out := "/tmp/sc_shots"
var n := 0
func _shot(tag: String) -> void:
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var tag: String = a[0] if a.size() > 0 else "land"
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER; St.tut_done = true; St.ui_scale = float(a[1]) if a.size() > 1 else 1.0; St.ui_scale_custom = true; St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.2).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu._open_scenarios()
	await _shot(tag + "_senaryolar")
	main.ui._modal = null
	for c in main.menu.root.get_children():
		if c.get_class() == "Control" and c.has_method("close"):
			c.close()
	await create_timer(0.4).timeout
	main.menu._open_eras()
	await _shot(tag + "_caglar")
	quit()
