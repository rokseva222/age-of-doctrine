extends SceneTree
## Yeni özellikler: mal pazarı, bütçe/askerlik düzeni, bina menüsü, kaynak arama, savaş ilanı penceresi.
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x800 -s tools/shot_new.gd
const PolicyUI = preload("res://scripts/policy_ui.gd")
var main
var out := "/tmp/shots_new"
var n := 0

func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	print("shot ", tag)

func _init() -> void:
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var St = load("res://scripts/settings.gd")
	St.seen_howto = true
	var cid := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			cid = c.id
	main.menu.select_country(cid)
	await create_timer(0.5).timeout
	main._on_start_requested(cid)
	await create_timer(1.5).timeout
	var gs = main.gs
	print("oyuncu: ", gs.countries[gs.player].name)
	main._on_speed_changed(2)
	await create_timer(8.0).timeout
	main._on_speed_changed(0)
	await create_timer(0.4).timeout
	await _shot("oyun")
	PolicyUI.open(main.ui, gs, 0)
	await create_timer(0.8).timeout
	await _shot("butce")
	for s0 in main.ui._modal.body.find_children("*", "ScrollContainer", true, false):
		s0.scroll_vertical = 640
	await create_timer(0.4).timeout
	await _shot("butce_alt")
	PolicyUI.open(main.ui, gs, 3)
	await create_timer(0.8).timeout
	await _shot("ticaret_mal")
	var sc = main.ui._modal
	# aşağı kaydır
	for s in sc.body.find_children("*", "ScrollContainer", true, false):
		s.scroll_vertical = 500
	await create_timer(0.4).timeout
	await _shot("ticaret_mal_alt")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	# eyalet kartı + bina menüsü + kaynak ara
	var pid: int = gs.countries[gs.player].capital
	for p in gs.provinces:
		if p.owner == gs.player and p.controller == gs.player and p.bld == "" and p.rich() == "" and p.found == "":
			pid = p.id
			break
	main._select(pid)
	await create_timer(0.8).timeout
	await _shot("eyalet_karti")
	main._on_ui_action("build", pid) if main.has_method("_on_ui_action") else null
	await create_timer(0.6).timeout
	await _shot("bina_menusu")
	main.ui.hide_dialog()
	await create_timer(0.3).timeout
	# savaş ilanı penceresi
	var tgt := -1
	for p0 in gs.provinces:
		if p0.owner != gs.player:
			continue
		for nb in p0.neighbors:
			var o: int = gs.provinces[nb].owner
			if o >= 0 and o != gs.player and not gs.countries[o].is_rebel and not gs.is_allied(gs.player, o):
				tgt = o
				break
		if tgt >= 0:
			break
	print("hedef: ", tgt)
	if tgt >= 0:
		main._on_ui_action("war", tgt) if main.has_method("_on_ui_action") else null
		await create_timer(0.6).timeout
		await _shot("savas_ilani")
	quit()
