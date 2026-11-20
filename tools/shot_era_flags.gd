extends SceneTree
const TK = preload("res://scripts/theme_kit.gd")
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	var gs = GS.new()
	Eras.prepare("ww1")
	gs.new_world(21)
	Eras.restructure(gs, "ww1")
	var root := ColorRect.new()
	root.color = Color(0.1, 0.11, 0.13)
	root.size = Vector2(1280, 720)
	get_root().add_child(root)
	var g := GridContainer.new()
	g.columns = 8
	g.position = Vector2(20, 20)
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 24)
	root.add_child(g)
	for nm in ["United Kingdom","India","Algeria","Egypt","Libya","South Korea","Indonesia","Dem. Rep. Congo","Philippines","Mongolia","Italy","Japan"]:
		for c in gs.countries:
			if c.name_en == nm:
				var v := VBoxContainer.new()
				v.add_child(TK.flag_rect(c, Vector2(110, 73)))
				var l := Label.new(); l.text = c.name; l.add_theme_font_size_override("font_size", 11); v.add_child(l)
				g.add_child(v)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/era_flags_test.png")
	quit()
