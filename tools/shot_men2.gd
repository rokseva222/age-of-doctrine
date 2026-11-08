extends SceneTree
const Sil = preload("res://scripts/silhouette.gd")
func _init() -> void:
	var holder := Control.new()
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.size = Vector2(1280, 720)
	holder.add_child(bg)
	var i := 0
	for cu in ["pers", "easia"]:
		for role in ["fin", "for"]:
			var p = Sil.new()
			p.culture = cu
			p.role = role
			p.female = false
			p.seed_name = "Test " + cu
			p.tint = Color(0.8, 0.2, 0.2) if cu == "easia" else Color(0.3, 0.6, 0.35)
			p.size = Vector2(300, 360)
			p.position = Vector2(20 + i * 310, 150)
			holder.add_child(p)
			i += 1
	await create_timer(0.5).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/iki_erkek.png")
	quit()
