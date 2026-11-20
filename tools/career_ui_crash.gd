extends SceneTree
## Hikâye UI çökme testi: yemin/isyan akışlarını düğmelere basarak dener. kullanım: -- <rebel|oath_cancel|oath_pick>
var main
func _find_btn(n: Node, txt: String) -> Button:
	if n is Button and (n as Button).text.to_upper() == txt.to_upper() and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
		return n
	for c in n.get_children():
		var r = _find_btn(c, txt)
		if r != null: return r
	return null
func _find_row_btn(n: Node, label: String) -> Button:
	# etiket metni label olan Label'ın kardeş düğmesini bul (satır HBox)
	if n is Label and (n as Label).text == label:
		var row = n.get_parent().get_parent()
		for c in row.get_children():
			if c is Button: return c
	for c in n.get_children():
		var r = _find_row_btn(c, label)
		if r != null: return r
	return null
func _tr(t: String) -> String:
	return String(get_root().get_node("/root").get_meta("x", t)) if false else t
func _dump(n: Node, d: int) -> void:
	if n is Button and (n as Button).is_visible_in_tree():
		print("  BTN[", (n as Button).text, "] disabled=", (n as Button).disabled)
	for c in n.get_children(): _dump(c, d + 1)
func _init() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	load("res://scripts/settings.gd").seen_howto = true
	load("res://scripts/settings.gd").seen_update = "1.2.15"
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._start_career("ott1520", {"host_en": "Turkey", "bg": "cavalry", "name": "Kemal Bey"})
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	main.gs.career["pending"] = {}
	var pl = main.gs.countries[main.gs.player]
	pl.troops = maxi(pl.troops, 20000)
	main.ui.show_career()
	await create_timer(0.8).timeout
	var lbl := "İsyan bayrağı aç" if mode == "rebel" else "Başka hükümdara yemin et"
	var b := _find_row_btn(get_root(), lbl)
	print("satır düğmesi: ", b, " disabled=", b.disabled if b else "-")
	if b == null: quit(); return
	b.disabled = false
	b.pressed.emit()
	await create_timer(0.8).timeout
	_dump(get_root(), 0)
	if mode == "rebel":
		var c := _find_btn(get_root(), "RAISE THE BANNER OF REVOLT")
		print("onay düğmesi: ", c)
		if c: c.pressed.emit()
	elif mode == "oath_cancel":
		var v := _find_btn(get_root(), "CANCEL")
		print("vazgeç: ", v)
		if v: v.pressed.emit()
	await create_timer(1.0).timeout
	if mode == "rebel":
		main._on_career_card()
		await create_timer(0.8).timeout
		_dump(get_root(), 0)
		for i in 12:
			main.gs.end_turn()
			if not main.gs.career.get("pending", {}).is_empty():
				print("  pending t", i, " ", main.gs.career.pending.kind)
				main._on_career_card()
				await create_timer(0.4).timeout
				main.gs.career["pending"] = {}
				main.ui.hide_dialog()
		await create_timer(0.5).timeout
	print("durum=", main.gs.career.state, " pending=", main.gs.career.get("pending", {}).get("kind", ""))
	print("BİTTİ")
	quit()
