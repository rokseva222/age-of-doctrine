extends SceneTree
const SA = preload("res://scripts/scene_art.gd")
func _init() -> void:
	var kinds: Array = OS.get_environment("KINDS").split(",")
	var tm := float(OS.get_environment("T") if OS.get_environment("T") != "" else "1.3")
	var root := Control.new()
	get_root().add_child(root)
	var bg := ColorRect.new(); bg.color = Color.BLACK; bg.size = Vector2(1200, 600); root.add_child(bg)
	for i in kinds.size():
		var sc = SA.make(kinds[i], 150)
		sc.animate = false
		sc.t = tm
		sc.position = Vector2((i % 3) * 400, (i / 3) * 150)
		sc.size = Vector2(396, 146)
		root.add_child(sc)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(OS.get_environment("OUT"))
	quit()
