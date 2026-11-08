extends SceneTree
const TK = preload("res://scripts/theme_kit.gd")
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(21)
	var root := ColorRect.new()
	root.color = Color(0.1, 0.11, 0.13)
	root.size = Vector2(1280, 720)
	get_root().add_child(root)
	var g := GridContainer.new()
	g.columns = 10
	g.position = Vector2(20, 20)
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	root.add_child(g)
	var n := 0
	for c in gs.countries:
		if c.is_rebel or c.iso == "": continue
		if n >= 50: break
		g.add_child(TK.flag_rect(c, Vector2(110, 73)))
		n += 1
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/flags_test.png")
	quit()
