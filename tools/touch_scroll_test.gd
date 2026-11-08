extends SceneTree
## Mobil simülasyonu: telefon çözünürlüğü, dokunma olayı ile düğme üstünden sürükleyip kaydırma testi.
var main
var fails := 0
func _wait(s: float) -> void:
	await create_timer(s).timeout
func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index = 0; e.position = pos; e.pressed = pressed
	Input.parse_input_event(e)
func _drag(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = 0; e.position = pos; e.relative = rel
	Input.parse_input_event(e)
func _find_scroll(n: Node, out: Array) -> void:
	if n is ScrollContainer and n.is_visible_in_tree() and n.get_v_scroll_bar().max_value > n.get_v_scroll_bar().page + 4:
		out.append(n)
	for c in n.get_children():
		_find_scroll(c, out)
func _first_button(n: Node):
	if n is BaseButton and n.is_visible_in_tree() and not n.disabled:
		return n
	for c in n.get_children():
		var r = _first_button(c)
		if r != null:
			return r
	return null
func _swipe_test(label: String, sc: ScrollContainer) -> void:
	var before := sc.scroll_vertical
	# kaydırma alanında ekranda görünen ilk düğmenin üstünden başla
	var btn = _first_button(sc)
	var r: Rect2 = sc.get_global_rect()
	var start: Vector2 = r.position + Vector2(r.size.x * 0.5, r.size.y * 0.7)
	if btn != null:
		var br: Rect2 = btn.get_global_rect()
		if r.intersects(br):
			start = Vector2(br.position.x + br.size.x * 0.5, clampf(br.position.y + br.size.y * 0.5, r.position.y + 20, r.end.y - 20))
	var win_scale: Vector2 = get_root().get_final_transform().get_scale()
	var spos: Vector2 = get_root().get_final_transform() * start
	var pressed_flag := [false]
	var hit = null
	# basılan düğmeyi bul (start altında)
	var stack := [sc]
	while stack:
		var n = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is BaseButton and n.get_global_rect().has_point(start) and n.is_visible_in_tree():
			hit = n
	if hit != null:
		hit.pressed.connect(func(): pressed_flag[0] = true)
	if hit != null:
		var chain := []
		var q: Node = hit
		while q != null and q != sc:
			if q is Control:
				chain.append(["STOP", "PASS", "IGNORE"][q.mouse_filter])
			q = q.get_parent()
		print("   olay zinciri (dugmeden kaydirma alanina): ", chain)
		for f in chain:
			if f == "STOP":
				fails += 1
	_touch(spos, true)
	await _wait(0.05)
	for i in 8:
		_drag(spos - Vector2(0, 14 * (i + 1)) * win_scale.y, Vector2(0, -14) * win_scale.y)
		await _wait(0.03)
	_touch(spos - Vector2(0, 8 * 14) * win_scale.y, false)
	await _wait(0.5)
	var moved := sc.scroll_vertical - before
	var ok: bool = moved > 20 and not pressed_flag[0]
	print(("ok" if ok else "BASARISIZ"), " [", label, "] kaydi=", moved, " dugmeye_basildi=", pressed_flag[0], " (dugme: ", str(hit.get_class()) if hit else "yok", ")")
	if not ok:
		fails += 1
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.ui_scale = 0.8; St.seen_howto = true; St.seen_promo = true; St.tut_done = true; St.sfx = 0.0; St.music = 0.0
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	St.ui_scale = 0.8; St.apply_display(self)
	await _wait(1.0)
	main.menu.finish_splash()
	await _wait(0.8)
	var found := []
	_find_scroll(get_root(), found)
	print("menu kaydirma alanlari: ", found.size())
	for sc in found:
		await _swipe_test("menu", sc)
	main._to_select()
	await _wait(0.8)
	for c in main.gs.countries:
		if c.name_en == "Turkey" or c.name == "Türkiye":
			main._on_start_requested(c.id)
			break
	await _wait(1.0)
	St.ui_scale = 0.8; St.tut_done = true; St.apply_display(self)
	var ui = main.ui
	ui.show_goals()
	await _wait(0.6)
	found = []
	_find_scroll(get_root(), found)
	print("hedefler kaydirma alanlari: ", found.size())
	for sc in found:
		await _swipe_test("hedefler", sc)
	print("DOKUNMA_HATA=", fails)
	quit()
