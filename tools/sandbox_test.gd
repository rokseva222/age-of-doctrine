extends SceneTree
## Sandbox paneli: tüm düğmeleri (kendi eyaletim + yabancı eyalet seçiliyken) bas, birkaç tur oyna, hata say.
const SB = preload("res://scripts/sandbox_ui.gd")
func _btns() -> Array:
	return get_root().find_children("*", "Button", true, false)
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var St = load("res://scripts/settings.gd")
	St.seen_update = "9.9.9"
	St.seen_promo = true
	St.seen_howto = true
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.5).timeout
	main._to_select()
	await create_timer(0.5).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	var gs = main.gs
	var bad := 0
	var pressed := 0
	var foreign := -1
	for p in gs.provinces:
		if p.owner != tr_id and gs.countries[p.owner].alive and not gs.countries[p.owner].is_rebel:
			foreign = p.id
			break
	for mode in 2:
		var sel: int = gs.countries[tr_id].capital if mode == 0 else foreign
		var i := 0
		while true:
			main._select(sel)
			await create_timer(0.2).timeout
			var before := _btns()
			SB.open(main.ui, gs)
			await create_timer(0.25).timeout
			var fresh: Array = _btns().filter(func(b): return not before.has(b))
			if i == 0:
				print("mod=", mode, " düğme=", fresh.size())
			if i >= fresh.size() - 1:
				main.ui.hide_dialog()
				break
			var b = fresh[i]
			print("  bas: ", b.text)
			b.pressed.emit()
			pressed += 1
			await create_timer(0.1).timeout
			main.ui.hide_dialog()
			gs.end_turn()
			i += 1
	print("basılan=", pressed, " tur=", gs.turn)
	print("HATA SAYISI=", bad)
	quit()
