extends SceneTree
## Mod/senaryo ekranlarının görüntüsü: godot -s tools/modes_shot.gd -- <ölçek> <dil>
var main
var tagp := ""
func _shot(tag: String) -> void:
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/modes_%s_%s.png" % [tagp, tag])
func _close_all() -> void:
	for c in main.menu.root.get_children():
		if c.has_method("close"):
			c.close()
	await create_timer(0.5).timeout
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	tagp = a[0]
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = a[1] if a.size() > 1 else "tr"; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER; St.tut_done = true
	St.ui_scale = float(a[0]); St.ui_scale_custom = true; St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.2).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	load("res://scripts/career_ui.gd").open_era(main.menu.root, func(e): pass)
	await _shot("hikaye")
	await _close_all()
	load("res://scripts/indep_ui.gd").open_setup(main.menu.root, func(p): pass)
	await _shot("bagimsizlik")
	await _close_all()
	main.menu._open_scenarios()
	await _shot("senaryolar")
	quit()
