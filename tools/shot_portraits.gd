extends SceneTree
const Sil = preload("res://scripts/silhouette.gd")

func _init() -> void:
	var holder := Control.new()
	root.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08)
	bg.size = Vector2(1500, 700)
	holder.add_child(bg)
	var styles := ["us", "eu", "ru", "me", "asia", "sa", "af"]
	var cols := [Color(0.3, 0.4, 0.7), Color(0.3, 0.55, 0.65), Color(0.75, 0.3, 0.25), Color(0.7, 0.2, 0.2), Color(0.8, 0.7, 0.2), Color(0.3, 0.6, 0.35), Color(0.55, 0.4, 0.2)]
	for i in styles.size():
		for k in 3:
			var p = Sil.new()
			p.style = styles[i]
			p.role = ["def", "for", "fin"][k]
			p.female = (k == 1)
			p.tint = cols[i]
			p.size = Vector2(190, 220)
			p.position = Vector2(20 + i * 205, 20 + k * 230)
			holder.add_child(p)
	await create_timer(0.4).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/portraits.png")
	quit()
