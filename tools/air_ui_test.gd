extends SceneTree
const Air = preload("res://scripts/air.gd")
const Info = preload("res://scripts/info_sheets.gd")
var bad := 0
func chk(c: bool, m: String) -> void:
	if not c:
		bad += 1
		print("FAIL: ", m)
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.seen_update = Info.UPDATE_VER
	St.seen_promo = true
	St.tut_done = true
	St.seen_howto = true
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.6).timeout
	main._to_select()
	await create_timer(0.6).timeout
	var me := -1
	for c in main.gs.countries:
		if c.name == "Türkiye": me = c.id
	main._on_start_requested(me)
	await create_timer(2.0).timeout
	var gs = main.gs
	Air.ensure(gs)
	main.ui.hide_dialog()
	var ws: Array = Air.wings_of(gs, me)
	chk(ws.size() >= 3, "wings exist")
	for w in ws:
		main._on_wing_tapped(w.id)
		chk(main.selected_wing == w, "select wing kind=" + w.kind)
		main._on_ui_action("wing_manage", w.id)
		await create_timer(0.3).timeout
		main.ui.hide_dialog()
		main._on_ui_action("wing_rebase_menu", w.id)
		await create_timer(0.2).timeout
		main.ui.hide_dialog()
		if w.kind == "bomber" or w.kind == "drone":
			main._on_ui_action("wing_strike_menu", w.id)
			await create_timer(0.2).timeout
			main.ui.hide_dialog()
		if w.kind == "transport":
			main._on_ui_action("wing_lift", w.id)
			await create_timer(0.2).timeout
			main.ui.hide_dialog()
	# fleet seçimi kanadı temizler
	main._clear_fleet_sel()
	chk(main.selected_wing == null, "fleet clear clears wing")
	var w0 = ws[0]
	main._select_wing(w0)
	main._on_ui_action("wing_deselect", w0.id)
	chk(main.selected_wing == null, "deselect")
	# eyalet kartı kanat modunda
	main._select_wing(w0)
	main._select(gs.countries[me].capital)
	await create_timer(0.2).timeout
	# end turn x3 ile çökme yok
	for i in 3:
		main.ui.hide_dialog()
		gs.end_turn() if gs.has_method("end_turn") else null
	print("AIR_UI_TEST bad=", bad)
	quit()
