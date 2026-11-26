extends SceneTree
## Savaşta batan gemiler 'ship_extra' sayacını düşürmüyordu: sınırda (24) yeni gemi yapılamıyordu.
const GS = preload("res://scripts/game_state.gd")
const Carriers = preload("res://scripts/carriers.gd")
const Fleets = preload("res://scripts/fleets.gd")
var bad := 0
func ok(c: bool, m: String) -> void:
	print(("OK   " if c else "HATA ") + m)
	if not c: bad += 1
func _init() -> void:
	var gs = GS.new(); gs.new_world(4)
	gs.start_game(gs.macro_idx.get("China", 0))
	var c = gs.countries[gs.player]
	for i in 3: gs.end_turn()
	c.tech = 0.9; c.gold = 1.0e9
	var n := 0
	for i in 40:
		if Carriers.build_ship(gs) == "": n += 1
	ok(n == Carriers.SHIP_MAX and c.ship_extra == Carriers.SHIP_MAX, "sınıra kadar inşa edildi: %d" % n)
	ok(Carriers.can_build_ship(gs, c) != "", "sınırda yeni gemi reddedilir (gemiler ayakta)")
	# savaşta batma: muharebe filolarını küçült
	for f in Fleets.fleets_of(gs, c.id):
		if f.kind == "surface": f.size = maxf(0.5, f.size * 0.3)
	var eff: int = Carriers.effective_ships(gs, c)
	print("ayakta grup=", eff, " sayaç=", c.ship_extra)
	ok(eff < Carriers.SHIP_MAX, "kayıptan sonra ayakta grup sayısı sayaçtan küçük")
	ok(Carriers.can_build_ship(gs, c) == "", "kayıptan sonra yeniden inşa edilebilir")
	ok(Carriers.build_ship(gs) == "", "yeniden inşa edildi")
	ok(c.ship_extra < Carriers.SHIP_MAX, "sayaç ayakta kalanlara göre düzeldi (%d)" % c.ship_extra)
	print("HATA SAYISI=", bad)
	quit()
