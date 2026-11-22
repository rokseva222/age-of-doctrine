extends SceneTree
## Harita bölgesi ekran görüntüsü: SHOTS=/dir godot --path . -s tools/shot_region.gd -- x y zoom [ad]
const GS = preload("res://scripts/game_state.gd")
const MapView = preload("res://scripts/map_view.gd")

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var g = GS.new()
	g.new_world(7)
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
	var i := 0
	while i + 2 < a.size():
		map.zoom = float(a[i + 2])
		map.cam_pos = Vector2(float(a[i]), float(a[i + 1]))
		map._apply()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_viewport().get_texture().get_image()
		var p := "%s/r_%d.png" % [out, i / 3]
		img.save_png(p)
		print("shot ", p)
		i += 3
	quit()
