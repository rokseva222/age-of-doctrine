extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const G = preload("res://scripts/grand_op.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n); if not ok: fails += 1
func _init() -> void:
	var gs = GS.new()
	gs.new_world(9)
	var me: int = gs.macro_idx["Russia"]
	gs.start_game(me)
	var tgt: int = gs.macro_idx["Ukraine"]
	ck("savaş yokken reddedilir", G.check(gs, tgt) != "")
	gs.declare_war(me, tgt, true)
	gs.countries[me].gold = 1.0e6
	var od := G.odds(gs, tgt)
	ck("olasılık toplamı 1", absf(od.win + od.partial + od.fail - 1.0) < 0.001)
	print("  zafer=%.2f kısmi=%.2f fiyasko=%.2f güç=%.2f şehir=%d zaferde=%d bedel=%.0f" % [od.win, od.partial, od.fail, od.strength, G.target_cities(gs, tgt), G.win_count(G.target_cities(gs, tgt)), G.cost(gs)])
	var before: int = gs.countries[tgt].prov_owned
	var gold0: float = gs.countries[me].gold
	var r := G.launch(gs, tgt, "  Deneme \"Harekâtı\"  ")
	ck("başladı", r.err == "")
	ck("ad temizlendi", r.op.name == "Deneme Harekâtı")
	ck("bedel düştü", gs.countries[me].gold < gold0)
	ck("ikinci harekât reddedilir", G.check(gs, tgt) != "")
	ck("bekleme süresi", G.cooldown_left(gs) == 26)
	var p := "user://grand.dat"
	for t in 4:
		gs.end_turn()
		if t == 0:
			ck("kayıt", gs.save_to(p))
	var kinds := 0
	for n in gs.news_log:
		if n.text.contains("Harekâtı"):
			kinds += 1
	print("  harekât haberleri: ", kinds)
	ck("harekât bitti", gs.grand.ops.is_empty() and gs.grand.has("last"))
	print("  sonuç: ", gs.grand.last, " hedef eyalet önce/sonra: ", before, "/", gs.countries[tgt].prov_owned)
	var held := 0
	for pr in gs.provinces:
		if pr.owner == tgt and pr.controller == me:
			held += 1
	print("  işgal edilen: ", held)
	var g2 = GS.new()
	ck("yükle", g2.load_from(p) and g2.grand.ops.size() == 1)
	for t in 4:
		g2.end_turn()
	ck("yüklenen oyunda da sonuçlandı", g2.grand.has("last"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	# olasılık doğrulaması: 400 çekim
	var cnt := {"win": 0, "partial": 0, "fail": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 400:
		var x := rng.randf()
		if x < od.win: cnt.win += 1
		elif x < od.win + od.partial: cnt.partial += 1
		else: cnt.fail += 1
	print("  400 çekim: ", cnt)
	print("HATA SAYISI=", fails)
	quit()
