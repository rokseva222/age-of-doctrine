extends SceneTree
## Kurtuluş Savaşı 1919 çağı: harita düzeni, başkent, ateşkes, ilk turlar, tarihî kartlar
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func own(g, pid: int) -> String:
	return g.countries[g.provinces[pid].owner].name_en
func ctl(g, pid: int) -> String:
	return g.countries[g.provinces[pid].controller].name_en
func _init() -> void:
	var g = GS.new()
	g.new_world(777)
	Eras.restructure(g, "ks1919")
	g.start_game(int(g.macro_idx.get("Turkey", 0)))
	Eras.start(g, "ks1919")
	ck("İzmir Yunan: " + own(g, 428), own(g, 428) == "Greece")
	ck("Manisa Yunan: " + own(g, 1961), own(g, 1961) == "Greece")
	ck("Adana Fransız: " + own(g, 430), own(g, 430) == "France")
	ck("Antep Fransız: " + own(g, 422), own(g, 422) == "France")
	ck("Antalya İtalyan: " + own(g, 429), own(g, 429) == "Italy")
	ck("İstanbul sahibi Türkiye, denetim İngiliz: %s/%s" % [own(g, 423), ctl(g, 423)], own(g, 423) == "Turkey" and ctl(g, 423) == "United Kingdom")
	ck("Kars Ermeni: " + own(g, 1949), own(g, 1949) == "Armenia")
	ck("Ankara Türk: " + own(g, 431), own(g, 431) == "Turkey")
	ck("Konya Türk: " + own(g, 434), own(g, 434) == "Turkey")
	var pc = g.countries[g.player]
	ck("başkent Ankara (431): %d" % pc.capital, int(pc.capital) == 431)
	ck("oyuncu adı: " + pc.name, pc.name.contains("Ankara"))
	for n in ["Syria", "Iraq", "Lebanon", "Israel"]:
		var ci: int = int(g.macro_idx.get(n, -1))
		print("   ", n, " yaşıyor=", ci >= 0 and g.countries[ci].alive)
	ck("Polonya bağımsız", g.countries[int(g.macro_idx.get("Poland", 0))].alive)
	ck("Ermenistan bağımsız", g.countries[int(g.macro_idx.get("Armenia", 0))].alive)
	ck("Avusturya-Macaristan yok / Macaristan var", g.countries[int(g.macro_idx.get("Hungary", 0))].alive)
	print("tarih: ", g.date_string() if g.has_method("date_string") else g.turn)
	print("Türkiye il=", pc.prov_owned, " ordu=", pc.troops, " savaşlar=", pc.enemies.size())
	for i in 60:
		if i % 10 == 0:
			var c = g.countries[g.player]
			print("tur %d istikrar=%.0f altın=%.0f gelir=%.0f il=%d" % [i, c.stability, c.gold, c.income, c.prov_owned])
		g.end_turn()
	print("60 tur sonra: Türkiye il=", g.countries[g.player].prov_owned, " İstikrar=", int(g.countries[g.player].stability), " savaşta Yunan=", g.at_war(g.player, int(g.macro_idx["Greece"])))
	print("HATA SAYISI=", fails)
	quit()
