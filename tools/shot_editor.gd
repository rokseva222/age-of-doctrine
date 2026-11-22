extends SceneTree
## Senaryo editörü ekran görüntüleri: xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x800 -s tools/shot_editor.gd
const ScenarioEditor = preload("res://scripts/scenario_editor.gd")
var main
var out := "/tmp/shots_editor"
var n := 0
var ed

func _shot(tag: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	print("shot ", tag)

func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	ScenarioEditor.open(main.menu.root, {}, func(id): print("done ", id))
	await create_timer(0.8).timeout
	ed = null
	for ch in main.menu.root.get_children():
		if ch.has_method("_show_page") or ch.get_class() == "Control":
			pass
	await _shot("sayfa1")
	# butonlara bas: "İleri" ile sayfa gez
	var nxt: Button = null
	for b in get_root().find_children("*", "Button", true, false):
		var tl: String = String(b.text).to_lower()
		if tl.find("ileri") >= 0 or tl.find("next") >= 0:
			nxt = b
	print("ileri butonu: ", nxt != null)
	for i in range(2, 8):
		if nxt == null: break
		nxt.pressed.emit()
		await _shot("sayfa%d" % i)
		for sc in get_root().find_children("*", "ScrollContainer", true, false):
			if sc.is_visible_in_tree():
				sc.scroll_vertical = 100000
		await _shot("sayfa%d_alt" % i)
	print("EDITOR_SHOT_BITTI")
	quit()
