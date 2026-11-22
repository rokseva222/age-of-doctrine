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
	var net = main.get_net()
	net.gs_client = g
	net.my_cid = ids[0]
	net.afk_ids = []
	net.waiting = []
	for i in 5:
		net.players[i + 2] = {"name": "p%d" % i, "cid": ids[i], "host": i == 0}
	main._online_begin(ids[0])
	await create_timer(0.6).timeout
	await _shot("start2")
	await create_timer(2.0).timeout
	await _shot("start3")
	var out: Array = []
	_dump(main.ui.root, out, 0)
	for l in out: print(l)
	quit()


func _dump(n: Node, out: Array, d: int) -> void:
	if n is Control and n.visible:
		var r: Rect2 = n.get_global_rect()
		if r.size.x > 500 and r.size.y > 400 and r.position.x > 800 and d < 8:
			out.append("%s%s [%s] %s vis=%s" % ["  ".repeat(d), n.name, n.get_class(), str(r), str(n.is_visible_in_tree())])
	for c in n.get_children():
		_dump(c, out, d + 1)
