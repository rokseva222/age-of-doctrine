extends SceneTree
const FE = preload("res://scripts/flag_editor.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_fe"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(3.8).timeout
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	St.seen_update = "1.2.12"
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	FE.open(main.menu.root, "R:#c8102e,0,0,1,1|Y:#ffffff,swords,0.5,0.5,0.45", func(sp): pass)
	await create_timer(0.8).timeout
	for n in main.menu.root.find_children("*", "ScrollContainer", true, false):
		n.scroll_vertical = 900
	await create_timer(0.5).timeout
	get_root().get_viewport().get_texture().get_image().save_png(out + "/fe.png")
	quit()
