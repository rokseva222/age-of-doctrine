extends SceneTree
## Her dönem/senaryo için dünya + Avrupa + Orta Doğu/Asya ekran görüntüsü: SHOTS=/dir godot --path . -s tools/shot_modes.gd --resolution 960x600
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")
const MapView = preload("res://scripts/map_view.gd")
const VIEWS := [[0.0, 0.0, -1.0, "dunya"], [105.0, -270.0, 5.5, "avrupa"], [330.0, -170.0, 3.5, "asya"], [60.0, -60.0, 3.0, "afrika"]]

func _init() -> void:
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_modes"
	DirAccess.make_dir_recursive_absolute(out)
	var modes: Array = [["modern", "", ""]]
	for e in Eras.all():
		modes.append([String(e["id"]), String(e["id"]), ""])
	for s in SC.all():
		if String(s["id"]) != "free":
			modes.append(["scn_" + String(s["id"]), "", String(s["id"])])
	for m in modes:
		var g = GS.new()
		g.new_world(5)
		if m[1] != "":
			Eras.prepare(m[1]); Eras.restructure(g, m[1]); Eras.start(g, m[1])
		elif m[2] != "":
			g.start_game(g.macro_idx.get("Turkey", 0))
			SC.apply(g, m[2])
		var root := Node.new()
		get_root().add_child(root)
		var map = MapView.new()
		root.add_child(map)
		await process_frame
		map.bind(g)
		g.player = 0
		await process_frame
		await process_frame
		for v in VIEWS:
			if v[2] > 0:
				map.zoom = v[2]
				map.cam_pos = Vector2(v[0], v[1])
				map._apply()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_viewport().get_texture().get_image().save_png("%s/%s__%s.png" % [out, m[0], v[3]])
		root.queue_free()
		if m[1] != "":
			Eras.clear()
		await process_frame
	print("bitti ", modes.size())
	quit()
