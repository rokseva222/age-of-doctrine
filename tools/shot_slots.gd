extends SceneTree
const SlotsUI = preload("res://scripts/slots_ui.gd")
const Saves = preload("res://scripts/saves.gd")
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	load("res://scripts/settings.gd").seen_howto = true
	main._on_start_requested(me)
	await create_timer(1.2).timeout
	for i in 4: main.gs.end_turn()
	print("yaz1=", Saves.write(main.gs, 1, ""), " yaz0=", Saves.write(main.gs, 0, ""))
	for i in 5: main.gs.end_turn()
	print("yaz3=", Saves.write(main.gs, 3, ""))
	print("meta1=", Saves.meta(1), " latest=", Saves.latest())
	SlotsUI.open(main.ui.root, "load", func(s): print("seçilen ", s))
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_root().get_viewport().get_texture().get_image().save_png("/tmp/slots_load.png")
	main.ui.hide_dialog()
	main._load_game(3)
	print("yüklendi tur=", main.gs.turn)
	Saves.delete(1); Saves.delete(3); Saves.delete(0)
	print("silindi any=", Saves.any())
	quit()
