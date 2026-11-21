extends SceneTree
## Online oyuncu şeridi görünümü. xvfb-run -a godot --path . -s tools/shot_hud.gd --resolution 1280x800
const NetS = preload("res://scripts/net.gd")
const GS = preload("res://scripts/game_state.gd")
const Hud = preload("res://scripts/online_hud.gd")
var main
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/rep/%s.png" % name)
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
	main.menu.hide_all()
	var g = GS.new()
	g.new_world(21)
	var ids: Array = []
	for n in ["Turkey", "Germany", "France", "Italy", "Japan", "Brazil"]:
		ids.append(int(g.macro_idx.get(n, 0)))
	g.start_game(ids[0])
	g.net_humans = ids.duplicate()
	var net = NetS.new()
	get_root().add_child(net)
	net.gs_client = g
	net.my_cid = ids[0]
	net.waiting = [ids[0], ids[4]]
	net.afk_ids = [ids[5]]
	net.deadline_left = 95.0
	net.deadline_grace = true
	for i in 5:
		net.players[i + 2] = {"name": "p%d" % i, "cid": ids[i], "host": i == 0}
	var hud = Hud.new()
	main.ui.root.add_child(hud)
	hud.setup(net, main.ui.BAR_H + main.ui.TICK_H)
	main.ui.set_hud_visible(true)
	hud.add_note("ready", ids[1])
	hud.add_note("ready", ids[2])
	hud.add_note("grace", ids[0], "120")
	hud.add_note("left", ids[5])
	await create_timer(1.0).timeout
	await _shot("hud1")
	quit()
