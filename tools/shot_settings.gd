extends SceneTree
const InfoSheets = preload("res://scripts/info_sheets.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_set"
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(3.8).timeout
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	St.seen_update = "1.2.9"
	St.war_aggr = 0.4
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	InfoSheets.open_settings(main.menu.root, func(): pass)
	await create_timer(0.8).timeout
	# aşağı kaydır
	for n in main.menu.root.find_children("*", "ScrollContainer", true, false):
		n.scroll_vertical = 1500
	await create_timer(0.5).timeout
	get_root().get_viewport().get_texture().get_image().save_png(out + "/settings.png")
	quit()
