extends SceneTree
## Senaryo editörü akışı: haritadan il seç → Bitti → devir listesi; olay ekle; kaydet; senaryoyu başlat.
const ScenarioEditor = preload("res://scripts/scenario_editor.gd")
var main
var out := "/tmp/shots_editor2"
var n := 0

func _shot(tag: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	n += 1
	get_root().get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	print("shot ", tag)

func _btn(pred: Callable) -> Button:
	for b in get_root().find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and pred.call(String(b.text).to_lower()):
			return b
	return null

func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	DirAccess.make_dir_recursive_absolute(out)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.8).timeout
	main._to_select()
	await create_timer(0.8).timeout
	ScenarioEditor.open(main.menu.root, {}, func(id): print("done ", id))
	await create_timer(0.8).timeout
	# ad yaz
	for le in get_root().find_children("*", "LineEdit", true, false):
		if le.is_visible_in_tree() and le.placeholder_text.to_lower().find("scenario name") >= 0:
			le.text = "Test Senaryosu"
			le.text_changed.emit(le.text)
	var nxt := _btn(func(t): return t.find("next") >= 0 or t.find("ileri") >= 0)
	nxt.pressed.emit(); nxt.pressed.emit()          # sayfa 3
	await _shot("sayfa3")
	var pk := _btn(func(t): return t.find("pick provinces on the map") >= 0 or t.find("haritadan il") >= 0)
	print("harita butonu: ", pk != null)
	if pk == null:
		quit(); return
	pk.pressed.emit()
	await create_timer(1.2).timeout
	await _shot("harita_secim_bos")
	var gr := []
	var tr_ := []
	for c in main.gs.countries:
		if c.name_en == "Turkey":
			gr = c.owned_ids.duplicate()
	print("Turkiye il sayisi: ", gr.size())
	for i in mini(4, gr.size()):
		await create_timer(0.05).timeout
		main.map.tapped.emit(gr[i])
		await create_timer(0.15).timeout
	await _shot("harita_secim_4il")
	var done := _btn(func(t): return t.find("done") >= 0 or t.find("bitti") >= 0)
	print("bitti butonu: ", done != null)
	done.pressed.emit()
	await create_timer(0.6).timeout
	await _shot("secim_sonrasi")
	for sc in get_root().find_children("*", "ScrollContainer", true, false):
		if sc.is_visible_in_tree():
			sc.scroll_vertical = 100000
	await _shot("secim_sonrasi_alt")
	print("EDITOR2_BITTI")
	quit()
