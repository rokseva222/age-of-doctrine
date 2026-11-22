extends SceneTree
## Her ülkeyi sığdırıp ekran görüntüsü alır: SHOTS=/dir godot --path . -s tools/shot_countries.gd --resolution 960x600 -- [başlangıç] [adet]
const GS = preload("res://scripts/game_state.gd")
const MapView = preload("res://scripts/map_view.gd")

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var start := int(a[0]) if a.size() > 0 else 0
	var cnt := int(a[1]) if a.size() > 1 else 9999
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
	var out: String = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "/tmp/shots_ctry"
	DirAccess.make_dir_recursive_absolute(out)
	var vp := get_root().get_viewport().get_visible_rect().size
	var done := 0
	for c in g.countries:
		if c.id < start or done >= cnt:
			continue
		var r := Rect2()
		var first := true
		for p in g.provinces:
			if p.owner != c.id:
				continue
			if first:
				r = p.bbox
				first = false
			else:
				r = r.merge(p.bbox)
		if first:
			continue
		var zoom := minf(vp.x / maxf(r.size.x, 1.0), vp.y / maxf(r.size.y, 1.0)) * 0.8
		zoom = clampf(zoom, 1.0, 30.0)
		map.zoom = zoom
		map.cam_pos = r.get_center()
		map._apply()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_viewport().get_texture().get_image()
		img.save_png("%s/%03d_%s.png" % [out, c.id, c.name_en.replace(" ", "_").replace("/", "_").replace(".", "")])
		done += 1
	print("bitti ", done)
	quit()
