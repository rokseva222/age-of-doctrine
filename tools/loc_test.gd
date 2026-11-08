extends SceneTree
const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")
func _init() -> void:
	var code := "en"
	for a in OS.get_cmdline_user_args():
		code = a
	Loc.apply(code)
	for s in ["Vazgeç", "Harekâtı başlat", "%d hf" % 5, "Gelir", "Yakında ordun yok. Ordularını hedefe 6 eyalet mesafeye getir ya da yeni birlik kur.", "Kabine değişikliği", "Paralı birlik: Gölge Ağı (3 hf kaldı)"]:
		print("[", s, "] -> [", Loc.t(s), "]")
	var l := Label.new()
	l.text = "Vazgeç"
	root.add_child(l)
	await process_frame
	print("Label:", l.text, " tr():", l.tr("Gelir"))
	print(Macro.money(2500000.0), " ", Macro.money(1500.0), " ", Macro.num(1234567), " ", Macro.compact(2500000))
	Loc.apply("tr")
	quit()
