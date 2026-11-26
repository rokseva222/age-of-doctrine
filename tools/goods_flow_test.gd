extends SceneTree
## Gerçek akış: Politika → Ticaret → "Anlaşma yap" → tedarikçi seç. Yayın sürümünde serbest bırakılmış pencereye erişim çökertiyordu;
## hata ayıklama sürümünde "freed instance" betik hatası olarak görünür. Beklenen: hata yok, Politika yeniden açılır, anlaşma yapılmış.
const PolicyUI = preload("res://scripts/policy_ui.gd")
var main
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all(); St.language = "tr"; St.tut_done = true; St.seen_howto = true; St.seen_promo = true
	St.seen_update = load("res://scripts/info_sheets.gd").UPDATE_VER
	St.save_all()
	main = load("res://main.tscn").instantiate()
	get_root().add_child(main)
	await create_timer(1.6).timeout
	main.menu.finish_splash()
	await create_timer(1.0).timeout
	main._to_select()
	await create_timer(0.6).timeout
	main._on_start_requested(int(OS.get_environment("CID")) if OS.get_environment("CID") != "" else 0)
	await create_timer(2.0).timeout
	main.ui.hide_dialog()
	var gs = main.gs
	var Goods = load("res://scripts/goods.gd")
	var ok := 0
	var fail := 0
	for g in Goods.GOODS:
		PolicyUI.open(main.ui, gs, 3)
		await create_timer(0.4).timeout
		var c = gs.countries[gs.player]
		if not Goods.deal_of(c, g).is_empty() or (c.goods.deals as Array).size() >= 3 or Goods.suppliers(gs, c, g).is_empty():
			continue
		var old_modal = main.ui._modal
		# "Anlaşma yap" düğmesinin yaptığı: diyaloğu aç
		var pu = null
		for n in old_modal.get_children():
			pass
		# PolicyUI örneğine ulaş: düğmenin sinyal bağlantısından
		var rowb: Array = []
		for b in old_modal.find_children("*", "Button", true, false):
			var tx: String = (b as Button).text.to_upper()
			if "ANLAŞMA YAP" in tx or "İPTAL:" in tx:
				rowb.append(b)
		var gi: int = Goods.GOODS.find(g)
		var btn: Button = rowb[gi] if gi < rowb.size() else null
		if btn != null and not ("ANLAŞMA YAP" in btn.text.to_upper()):
			btn = null
		if btn == null:
			print("düğme yok: ", g); fail += 1; continue
		btn.pressed.emit()
		await create_timer(0.5).timeout
		var dlg = main.ui._modal
		if OS.get_environment("DBG") != "":
			for b in dlg.find_children("*", "Button", true, false):
				print("  düğme: [", (b as Button).text, "]")
		var pick: Button = _find_btn(dlg, "FAZLASI")
		if pick == null:
			print("tedarikçi düğmesi yok: ", g); fail += 1; continue
		pick.pressed.emit()
		await create_timer(0.6).timeout
		var again = main.ui._modal
		var good: bool = again != null and is_instance_valid(again) and again != dlg and not Goods.deal_of(gs.countries[gs.player], g).is_empty()
		print(g, ": anlaşma=", not Goods.deal_of(gs.countries[gs.player], g).is_empty(), " Politika yeniden açıldı=", good)
		if good: ok += 1
		else: fail += 1
		main.ui.hide_dialog()
		await create_timer(0.3).timeout
	print("SONUC ok=", ok, " fail=", fail)
	quit()

func _find_btn(n: Node, part: String) -> Button:
	if n is Button and part in _btn_text(n).to_upper():
		return n
	for ch in n.get_children():
		var r = _find_btn(ch, part)
		if r != null:
			return r
	return null

func _btn_text(b: Button) -> String:
	var s: String = b.text
	for ch in b.find_children("*", "Label", true, false):
		s += " " + (ch as Label).text
	return s
