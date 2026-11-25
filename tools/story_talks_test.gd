extends SceneTree
## Hikâye modu: duel/champion/prisoner/tax kartları müzakere masası açar; masa oynanır, sonuç etkileri uygulanır, bekleyen kart temizlenir.
const Career = preload("res://scripts/career.gd")
const Loc = preload("res://scripts/loc.gd")
var main
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1
func _find_btn_prefix(n: Node, pre: String) -> Button:
	if n is Button and (n as Button).text.to_upper().begins_with(pre.to_upper()) and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
		return n
	for c in n.get_children():
		var r = _find_btn_prefix(c, pre)
		if r != null: return r
	return null
func _dump(n: Node) -> void:
	if n is Button and (n as Button).is_visible_in_tree():
		print("  BTN[", (n as Button).text, "]")
	for c in n.get_children(): _dump(c)
func _init() -> void:
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(3.8).timeout
	var St0 = load("res://scripts/settings.gd")
	St0.seen_howto = true
	St0.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._start_career("ott1520", {"host_en": "Turkey", "bg": "cavalry", "name": "Kemal Bey"})
	await create_timer(1.5).timeout
	main.ui.hide_dialog()
	var wants := {"duel": "Barış masasına otur", "champion": "Müzakereye otur", "prisoner": "Fidye pazarlığı yap", "tax": "Payı pazarlıkla düşür"}
	for id in wants:
		var card: Dictionary = {}
		for c in Career.CARDS:
			if String(c.id) == id:
				card = c
		ck("%s: kart var, ilk seçenek müzakere" % id, not card.is_empty() and String(card.c[0][2].get("game", "")) == "negotiate")
		main.gs.career["pending"] = {"kind": "card", "card": card}
		var ren0: float = float(main.gs.career.get("renown", 0.0))
		main._on_career_card()
		await create_timer(0.8).timeout
		var b := _find_btn_prefix(get_root(), String(wants[id]))
		if b == null:
			b = _find_btn_prefix(get_root(), String(Loc.t(String(wants[id]))))
		if b == null:
			_dump(get_root())
		ck("%s: düğme görünür (%s)" % [id, wants[id]], b != null)
		if b == null:
			continue
		b.pressed.emit()
		await create_timer(0.6).timeout
		var view = main.ui.root.get_child(main.ui.root.get_child_count() - 1)
		ck("%s: müzakere ekranı açıldı" % id, view.get_script() != null and "deal" in view)
		# bot: karşı tarafın gerçek duruşuna göre doğru hamleyi seçer
		var steps := 0
		while view.phase != "end" and steps < 40:
			steps += 1
			if view.phase == "choose":
				var move: int = [1, 0, 2][view.stance]    # sert->taviz, esnek->baskı, aceleci->gerekçe
				view._pick(move)
			await create_timer(1.1).timeout
		ck("%s: masa bitti" % id, view.phase == "end")
		var cb_btn := _find_btn_prefix(view, "Devam")
		if cb_btn == null:
			cb_btn = _find_btn_prefix(view, "Continue")
		ck("%s: devam düğmesi var" % id, cb_btn != null)
		if cb_btn:
			cb_btn.pressed.emit()
		await create_timer(0.6).timeout
		ck("%s: bekleyen kart temizlendi" % id, main.gs.career.get("pending", {}).is_empty())
		var ren1: float = float(main.gs.career.get("renown", 0.0))
		print("   ", id, " ün: ", ren0, " -> ", ren1)
		main.ui.hide_dialog()
	print("HATA SAYISI=", errs)
	quit()
