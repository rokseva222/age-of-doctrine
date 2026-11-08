extends SceneTree
## Harita çizim testi: gerçek dünya, rastgele sahiplik ve ekran görüntüleri.
const GS = preload("res://scripts/game_state.gd")
const MapView = preload("res://scripts/map_view.gd")
const TK = preload("res://scripts/theme_kit.gd")

func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var g = GS.new()
	g.new_world(7)
	print("dünya hazır ms=", Time.get_ticks_msec() - t0, " ülke=", g.countries.size(), " eyalet=", g.provinces.size(), " json/geo ms=", g.world.load_ms)
	var root := Node.new()
	get_root().add_child(root)
	var map = MapView.new()
	root.add_child(map)
	await process_frame
	map.bind(g)
	g.player = 0
	await process_frame
	await process_frame
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_map"
	DirAccess.make_dir_recursive_absolute(out)
	await _shot(out + "/01_world.png")
	# Avrupa
	var tr = g.countries[20]
	for c in g.countries:
		if c.name == "Türkiye" or c.name == "Fransa":
			print("ülke ", c.name, " id=", c.id)
	map.zoom = 3.2
	map.cam_pos = Vector2(220, -190)
	map._apply()
	await process_frame
	await _shot(out + "/02_europe.png")
	map.zoom = 7.0
	map.cam_pos = Vector2(225, -185)
	map._apply()
	await process_frame
	await _shot(out + "/03_zoom.png")
	map.zoom = 2.4
	map.cam_pos = Vector2(-760, -330)
	map._apply()
	await process_frame
	await _shot(out + "/04_alaska.png")
	quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(path)
	print("shot ", path)
