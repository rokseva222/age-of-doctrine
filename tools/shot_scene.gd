extends SceneTree
const SA = preload("res://scripts/scene_art.gd")
var kinds: Array = ["assault", "barrage", "blitz", "naval", "air", "missile", "paradrop", "special", "landing", "cyber", "spy", "sanction", "trade", "alliance", "war", "peace"]
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png(path)
func _init() -> void:
	var bg := ColorRect.new(); bg.color = Color(0.08, 0.1, 0.14); bg.size = Vector2(1280, 720); get_root().add_child(bg)
	DirAccess.make_dir_recursive_absolute("/tmp/px")
	for page in 4:
		var vb := VBoxContainer.new(); vb.position = Vector2(60, 20); vb.custom_minimum_size = Vector2(1160, 0); get_root().add_child(vb)
		for k in kinds.slice(page * 4, page * 4 + 4):
			vb.add_child(SA.make(k, 150))
		await create_timer(1.6).timeout
		await _shot("/tmp/px/p%d.png" % page)
		vb.queue_free()
		await create_timer(0.1).timeout
	quit()
