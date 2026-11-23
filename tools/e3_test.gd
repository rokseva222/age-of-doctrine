extends SceneTree
## E3: savaşsız deniz nakliyesi (kendi adası / müttefik / geçiş izinli kıyı), geçit bitince eve dönüş.
const GS = preload("res://scripts/game_state.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _id(gs, en: String) -> int:
	for c in gs.countries:
		if c.name_en == en: return c.id
	return -1
func _prov(gs, cid: int, name: String) -> int:
	for p in gs.provinces:
		if p.owner == cid and p.name.findn(name) >= 0: return p.id
	return -1
func _init():
	var F = load("res://scripts/fleets.gd")
	var Seas = load("res://scripts/seas.gd")
	# --- 1) Japonya: Tokyo -> Hokkaido (kendi adası, savaş yok)
	var gs = GS.new(); gs.new_world(9)
	var jp := _id(gs, "Japan")
	gs.start_game(jp)
	var src := -1
	var dst := -1
	for p in gs.provinces:
		if p.owner == jp and p.coastal and gs.armies.has(p.id) and src < 0: src = p.id
	for p in gs.provinces:
		if p.owner == jp and p.coastal and p.landmass != gs.provinces[src].landmass: dst = p.id
	print("kaynak ", gs.provinces[src].name, " hedef ", gs.provinces[dst].name if dst >= 0 else "-")
	var e: String = F.embark(gs, src, 5000)
	ck("Japonya: gemiye binme ('%s')" % e, e == "")
	var fid := -1
	for f in gs.fleets.values():
		if f.owner == jp and f.cargo > 0: fid = f.id
	ck("nakliye filosu oluştu", fid >= 0)
	var zt: Array = Seas.coast_zones(gs, dst)
	var mv: String = F.order_move(gs, fid, String(zt[0]))
	ck("filo hedef denize yönlendi ('%s')" % mv, mv == "")
	print("auto_cmd=", gs.countries[jp].auto_cmd, " auto_idle=", gs.auto_idle, " acted=", gs.player_acted)
	print("rota: ", gs.fleets[fid].zone, " -> ", zt[0], " path=", gs.fleets[fid].get("path") if "path" in gs.fleets[fid] else "?")
	for i in 12:
		if not gs.fleets.has(fid):
			print("  filo yok oldu, tur ", i); break
		var ff = gs.fleets[fid]
		print("  tur ", i, " bölge=", ff.zone, " yük=", ff.cargo, " path=", ff.path, " acted=", gs.player_acted)
		if ff.zone == String(zt[0]): break
		gs.end_turn()
	ck("filo hedef denize vardı", gs.fleets.has(fid) and gs.fleets[fid].zone == String(zt[0]))
	var d: String = F.debark(gs, fid, dst)
	ck("kendi adasına çıkış, savaşsız ('%s')" % d, d == "")
	# --- 2) Türkiye: geçiş izinli ülkenin kıyısına çıkış ve izin bitince eve dönüş
	var g2 = GS.new(); g2.new_world(9)
	var tr := _id(g2, "Turkey")
	var gr := _id(g2, "Greece")
	g2.start_game(tr)
	g2.countries[gr].passage[tr] = g2.turn + 6
	var izm := _prov(g2, tr, "İzmir")
	if not g2.armies.has(izm):
		var a = load("res://scripts/model.gd").Army.new(); a.id = g2.next_army_id; g2.next_army_id += 1; a.owner = tr; a.prov = izm; a.size = 20000
		g2.armies[izm] = a
	var e2: String = F.embark(g2, izm, 8000)
	ck("Türkiye: İzmir'de gemiye binme ('%s')" % e2, e2 == "")
	var f2 := -1
	for f in g2.fleets.values():
		if f.owner == tr and f.cargo > 0: f2 = f.id
	var gdst := -1
	for pid in Seas.provs_of(g2, g2.fleets[f2].zone):
		if g2.provinces[pid].owner == gr and not g2.armies.has(pid): gdst = pid
	print("Yunan kıyısı: ", g2.provinces[gdst].name if gdst >= 0 else "-")
	var d2: String = F.debark(g2, f2, gdst) if gdst >= 0 else "hedef yok"
	ck("geçiş izinli kıyıya savaşsız çıkış ('%s')" % d2, d2 == "")
	var land: int = -1
	for a2 in g2.armies.values():
		if a2.owner == tr and g2.provinces[a2.prov].owner == gr: land = a2.prov
	ck("ordu Yunan topraklarında", land >= 0)
	for i in 8: g2.end_turn()
	var still := false
	for a3 in g2.armies.values():
		if a3.owner == tr and g2.provinces[a3.prov].owner == gr: still = true
	ck("izin bitince ordu yabancı toprakta kalmadı", not still)
	print("HATA SAYISI=", fails)
	quit()
