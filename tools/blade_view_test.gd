extends SceneTree
## Yeni düello ekranı: bot oyuncu ekranı baştan sona oynar; sonuç geri çağrısı gelir, ekran kapanır; çekilme ve geri tuşu çalışır.
const BD = preload("res://scripts/blade_duel.gd")
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1
func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	var St0 = load("res://scripts/settings.gd")
	St0.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St0.seen_promo = true
	await create_timer(1.0).timeout
	main.menu.finish_splash()
	await create_timer(0.6).timeout
	main._to_select()
	await create_timer(0.6).timeout
	var tr_id := -1
	for c in main.gs.countries:
		if c.name == "Türkiye":
			tr_id = c.id
	St0.seen_howto = true
	main._on_start_requested(tr_id)
	await create_timer(1.5).timeout
	# 1) bot: rakibin yönünü okuyup siper alır, aralarda vurur
	var res := {"r": "", "n": 0}
	BD.open(main.ui, {"title": "T", "skill": 0.5, "power": 0.8}, func(r, _i):
		res.r = r
		res.n += 1)
	await process_frame
	var view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
	var steps := 0
	while not view.finished and steps < 6000:
		steps += 1
		var f = view.core.f
		if f.state == "wind" and f.t > f.dur * 0.3:
			view._guard(f.dir) if view.core.p.guard != f.dir else null
		elif view.core.p.state == "idle" and f.state != "wind" and steps % 50 == 0:
			view._attack(steps % 4)
		await process_frame
	ck("düello bitti", view.finished)
	ck("bot kazandı ya da kaybetti (sonuç var)", view.core.outcome != "")
	view._press_end()
	await process_frame
	await process_frame
	ck("geri çağrı bir kez, sonuç doğru", res.n == 1 and res.r == view.core.outcome)
	ck("ekran kapandı", not is_instance_valid(view))
	# 2) çekilme: iki dokunuş
	res.n = 0
	BD.open(main.ui, {"title": "T"}, func(r, _i):
		res.r = r
		res.n += 1)
	await process_frame
	view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
	view._yield_pressed()
	ck("ilk dokunuş sadece onay ister", not view.finished and view.yield_armed)
	view._yield_pressed()
	ck("ikinci dokunuş çekilir", view.finished)
	view._press_end()
	await process_frame
	await process_frame
	ck("çekilme sonucu 'yield'", res.r == "yield" and res.n == 1)
	# 3) ekran ağaçtan çıkarsa (ör. ana menüye dönüş) yine de 'yield' bildirilir
	res.n = 0
	BD.open(main.ui, {"title": "T"}, func(r, _i):
		res.r = r
		res.n += 1)
	await process_frame
	view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
	view.queue_free()
	await process_frame
	await process_frame
	ck("ağaçtan çıkınca yield bildirilir", res.n == 1 and res.r == "yield")
	print("HATA SAYISI=", errs)
	quit()
