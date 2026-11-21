extends SceneTree
## Senaryo listesi: arama kutusu + kaydırma (ekran görüntüsü). xvfb-run -a godot --path . -s tools/shot_scnlist.gd --resolution 1280x800
var main
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/rep/%s.png" % name)
func _find(n: Node, cls: String, out: Array) -> void:
	for c in n.get_children():
		if c.get_class() == cls:
			out.append(c)
		_find(c, cls, out)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	var Loc = load("res://scripts/loc.gd")
	St.load_all(); St.language = "tr"; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	Loc.apply("tr")
	await create_timer(2.0).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	for i in 6:
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	main.menu._open_scenarios()
	await create_timer(1.0).timeout
	await _shot("scn1")
	var les: Array = []
	_find(main.menu.root, "LineEdit", les)
	print("LineEdit sayisi ", les.size())
	if les.size() > 0:
		les[les.size() - 1].text = "krim"
		les[les.size() - 1].text_changed.emit("krim")
	await create_timer(0.8).timeout
	await _shot("scn2")
	if les.size() > 0:
		les[les.size() - 1].text = "zzzzq"
		les[les.size() - 1].text_changed.emit("zzzzq")
	await create_timer(0.8).timeout
	await _shot("scn3")
	quit()
