extends SceneTree
## Tedarik/ticaret anlaşması çökmesi: Ticaret sekmesinden her mal için anlaşma penceresi açılıp ilk tedarikçi seçilir.
const PolicyUI = preload("res://scripts/policy_ui.gd")
const Loc = preload("res://scripts/loc.gd")
var main
var errs := 0
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = OS.get_environment("SLANG") if OS.get_environment("SLANG") != "" else "tr"
	St.tut_done = true; St.seen_howto = true; St.seen_promo = true; St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.6).timeout
	main.menu.finish_splash()
	await create_timer(1.2).timeout
	main._to_select()
	await create_timer(0.8).timeout
	var tid := -1
	for c in main.menu.gs_preview_countries() if main.menu.has_method("gs_preview_countries") else []:
		pass
	main._on_start_requested(0 if OS.get_environment("CID") == "" else int(OS.get_environment("CID")))
	await create_timer(1.8).timeout
	var gs = main.gs
	main.ui.hide_dialog()
	for i in int(OS.get_environment("TURNS") if OS.get_environment("TURNS") != "" else "3"):
		main._on_step()
		await create_timer(1.2).timeout
		if main.ui.is_dialog_open():
			main.ui.hide_dialog()
	var c = gs.countries[gs.player]
	print("oyuncu=", c.name, " tur=", gs.turn)
	var pu = load("res://scripts/policy_ui.gd").new()
	pu.ui = main.ui; pu.gs = gs; pu.tab = 3
	pu._build()
	await create_timer(0.6).timeout
	var Goods = load("res://scripts/goods.gd")
	var n := 0
	for cc in gs.countries:
		if not cc.alive or cc.is_rebel: continue
		for g in Goods.GOODS:
			var sup: Array = Goods.suppliers(gs, cc, g)
			pu._goods_deal_dialog(cc, g)
			main.ui.hide_dialog()
			n += 1
			if sup.size() > 0 and g == "grain":
				print("TAHIL ", cc.name, " ", sup.size(), " ", gs.countries[sup[0][0]].name)
			if sup.size() > 0 and cc.id == gs.player:
				print(cc.name, " ", g, " tedarikçi ", sup.size(), " ilk ", gs.countries[sup[0][0]].name, " ", Goods.fmt(sup[0][1]))
	print("pencere sayısı=", n)
	var tr_id := -1
	for cc in gs.countries:
		if cc.name_en == "Turkey": tr_id = cc.id
	var tc = gs.countries[tr_id]
	for g in Goods.GOODS:
		var sup2: Array = Goods.suppliers(gs, tc, g)
		print("TR ", g, " tedarikçi=", sup2.size())
		if sup2.size() > 0:
			print("  make_deal:", Goods.make_deal(gs, tc, g, sup2[0][0]))
	for i in 12:
		gs.end_turn() if gs.has_method("end_turn") else main._on_step()
		await create_timer(0.3).timeout
		if main.ui.is_dialog_open(): main.ui.hide_dialog()
	print("tur=", gs.turn)
	# klasik ticaret anlaşması
	for o in gs.countries:
		if o.alive and not o.is_rebel and o.id != gs.player and gs.relation_of(gs.player, o.id) >= 40.0 and not gs.trade.has(o.id):
			print("ticaret: ", o.name, " -> '", gs.player_sign_trade(o.id), "'")
			break
	print("BİTTİ")
	quit()
func _find_buttons(n: Node, txt: String) -> Array:
	var out: Array = []
	if n is Button and txt in (n as Button).text and (n as Button).is_visible_in_tree():
		out.append(n)
	for ch in n.get_children():
		out.append_array(_find_buttons(ch, txt))
	return out
