extends SceneTree
const Ed = preload("res://scripts/scenario_editor.gd")
var dir := "/tmp/shots_ed2"
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(dir + "/" + n + ".png")
func _top(main):
	return main.menu.root.get_children().back()
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(dir)
	await create_timer(3.8).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main.menu.show_main()
	await create_timer(0.8).timeout
	var ed = load("res://scripts/scenario_editor.gd").new()
	ed.root = main.menu.root
	ed.on_done = func(_id): pass
	ed._start({})
	await create_timer(0.8).timeout
	await _shot("p1")
	for i in [1, 2, 4, 5]:
		ed._show_page(i)
		await create_timer(0.5).timeout
		await _shot("page%d" % (i + 1))
	# yeni devlet formu
	ed._show_page(1)
	ed._custom_form(-1)
	await create_timer(0.6).timeout
	await _shot("custom_form")
	_top(main).queue_free()
	await create_timer(0.3).timeout
	# bayrak editörü
	var FE = load("res://scripts/flag_editor.gd")
	FE.open(main.menu.root, "H:#c8102e,#c8102e|M:#ffffff,0.4,0.5,0.22,0|Y:#ffffff,star,0.6,0.5,0.1", func(_s): pass)
	await create_timer(0.8).timeout
	await _shot("flag_editor")
	_top(main).queue_free()
	await create_timer(0.3).timeout
	ed._show_page(5)
	ed._cabev_form(-1)
	await create_timer(0.6).timeout
	await _shot("cabev_form")
	quit()
