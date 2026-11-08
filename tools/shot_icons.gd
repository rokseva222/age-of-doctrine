extends SceneTree
const TK = preload("res://scripts/theme_kit.gd")
const Icons = preload("res://scripts/icons.gd")

func _init() -> void:
	var vp := Control.new()
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.size = Vector2(1400, 520)
	vp.add_child(bg)
	var g := GridContainer.new()
	g.columns = 12
	g.position = Vector2(30, 20)
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 18)
	vp.add_child(g)
	for n in Icons.NAMES:
		var v := TK.IconView.new()
		v.icon = n
		v.color = TK.PAPER
		v.custom_minimum_size = Vector2(80, 80)
		g.add_child(v)
	await create_timer(0.5).timeout
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/icons.png")
	quit()
