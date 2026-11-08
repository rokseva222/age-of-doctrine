extends SceneTree
## Arayüz duman testi: dönem/senaryo başlat, tüm panelleri aç, ekran görüntüsü al.
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _close(main) -> void:
	for i in 3:
		if main.ui._modal != null and is_instance_valid(main.ui._modal):
			main.ui._modal.queue_free()
			main.ui._modal = null
		await create_timer(0.15).timeout
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var kind: String = a[0]; var id: String = a[1]; var lang: String = a[2]
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = lang; St.seen_howto = true; St.save_all()
	var Loc = load("res://scripts/loc.gd")
	Loc.debug = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	if kind == "era":
		main._start_era(id)
	else:
		main.menu.scenario_id = id
		main._to_select()
	await create_timer(1.0).timeout
	var sug: Array = (load("res://scripts/eras.gd").get_era(id) if kind == "era" else load("res://scripts/scenarios.gd").get_sc(id)).get("suggest", [])
	var cid: int = int(main.gs.macro_idx.get(sug[0] if not sug.is_empty() else "Turkey", 0))
	var out := "/tmp/ui_%s_%s" % [id, lang]
	DirAccess.make_dir_recursive_absolute(out)
	main.menu.select_country(cid)
	await create_timer(1.0).timeout
	await _shot(out + "/01_select.png")
	main._on_start_requested(cid)
	await create_timer(1.5).timeout
	main._on_speed_changed(2)
	await create_timer(3.0).timeout
	main._on_speed_changed(0)
	await _shot(out + "/02_game.png")
	var calls := [["goals", func(): main.ui.show_goals()], ["relations", func(): main.ui.show_relations(cid)], ["politics", func(): main.ui.show_politics()], ["daily", func(): main.ui.show_daily()], ["chokes", func(): main.ui.show_chokes()], ["world", func(): main.ui.show_world_panel(0)], ["world2", func(): main.ui.show_world_panel(1)], ["pause", func(): main.ui.show_pause_menu()], ["grand", func(): main.ui.show_grand_op(cid)], ["un", func(): main.ui.show_un_targets("sanction")]]
	var n := 3
	for c in calls:
		main.ui.call("hide_dialog")
		await create_timer(0.1).timeout
		c[1].call()
		await create_timer(0.5).timeout
		await _shot("%s/%02d_%s.png" % [out, n, c[0]])
		n += 1
	var L = load("res://scripts/loc.gd")
	var ks: Array = L.misses.keys()
	for k in ks: print("MISS| ", str(k).replace("\n", " "))
	quit()
