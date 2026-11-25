extends SceneTree
## Kafkas Düğümü tanıtım videosu için oyun içi ekran görüntüleri. kullanım: -- <çıktı klasörü>
var main
var out := "/tmp/kk/shots"
var n := 0
func _shot(tag: String, wait := 0.9) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
func _btn_at(n: Node, pt: Vector2) -> Button:
	if n is Button and (n as Button).is_visible_in_tree() and (n as Button).get_global_rect().has_point(pt):
		return n
	for c in n.get_children():
		var r = _btn_at(c, pt)
		if r != null: return r
	return null
func _cid(en: String) -> int:
	for c in main.gs.countries:
		if c.name_en == en if "name_en" in c else c.name == en:
			return c.id
	return -1
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER; St.tut_done = true; St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.2).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main.menu.set_scenario("cau")
	main._to_select()
	await _shot("sec", 1.2)
	var az := -1
	for c in main.gs.countries:
		if c.name == "Azerbaycan":
			az = c.id
	print("az=", az)
	main._on_start_requested(az)
	await _shot("oyun", 2.0)
	var ids := {}
	for c in main.gs.countries:
		if c.name in ["Azerbaycan", "Ermenistan", "Gürcistan"]:
			ids[c.id] = true
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p in main.gs.provinces:
		if ids.has(p.owner):
			lo = lo.min(p.label_pos)
			hi = hi.max(p.label_pos)
	print("bbox ", lo, hi)
	main.ui.hide_dialog()
	var xb := _btn_at(get_root(), Vector2(421, 1503))
	print("kapat: ", xb)
	if xb: xb.pressed.emit()
	var ctr: Vector2 = (lo + hi) * 0.5
	var z := 19.0
	main.map.animate_to(main.map._center_offset(ctr, z), z, 0.1)
	await _shot("kafkas_harita", 2.2)
	# tarihî an kartları (Azerbaycan rolü)
	var mm = JSON.parse_string(FileAccess.get_file_as_string("res://data/scn_moments/cau.json"))
	for pair in [["cau_washington", "washington"], ["cau_sinirci", "sinir"], ["cau_tcm", "koridor"]]:
		for m in mm["moments"]:
			if m["id"] == pair[0]:
				main.gs.moment_pending = {"id": m["id"], "role": "Azerbaijan", "m": m}
				main._on_moment_card()
				await _shot("an_" + pair[1], 1.0)
				main.ui.hide_dialog()
				main.gs.moment_pending = {}
	quit()
