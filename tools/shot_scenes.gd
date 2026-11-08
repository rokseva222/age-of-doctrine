extends SceneTree
const Scene = preload("res://scripts/scene_art.gd")

func _init() -> void:
	var holder := Control.new()
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.size = Vector2(1600, 1100)
	holder.add_child(bg)
	var kinds := ["assault", "barrage", "cyber", "blitz", "trade", "alliance", "war", "peace", "summit", "spy", "sanction"]
	for i in kinds.size():
		var s = Scene.new()
		s.kind = kinds[i]
		s.animate = false
		s.t = 3.7
		s.size = Vector2(600, 170)
		s.position = Vector2(10 + (i % 2) * 610, 10 + (i / 2) * 180)
		holder.add_child(s)
	await create_timer(0.5).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/scenes.png")
	quit()
