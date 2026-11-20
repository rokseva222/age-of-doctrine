extends SceneTree
## Çağa özel deniz filosu: tür adları, gemi sınıfları, simgeler, kadırga filosunda denizaltı mekaniği olmaması, hava filosu teknoloji eşiği
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Air = preload("res://scripts/air.gd")
const FleetsM = preload("res://scripts/fleets.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const Icons = preload("res://scripts/icons.gd")
const Arsenal = preload("res://scripts/arsenal.gd")

var bad := 0

func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

func _init() -> void:
	for era in ["", "ww1", "ww2", "cw62", "ott1299", "tim1380", "ott1453", "ott1520", "alt_maginot", "alt_berlin_hot", "alt_schlieffen", "alt_cuba_hot"]:
		Eras.prepare(era) if era != "" else Eras.clear()
		var g = GS.new()
		g.new_world(7)
		var host := "Turkey"
		if era != "":
			Eras.restructure(g, era)
			host = String(Eras.get_era(era).suggest[0])
		g.start_game(int(g.macro_idx.get(host, 0)))
		if era != "":
			Eras.start(g, era)
		Air.ensure(g)
		FleetsM.ensure(g)
		var fam: String = Ext.family()
		var pre: bool = fam == "pre"
		var nk := {}
		for f in g.fleets.values():
			nk[f.kind] = int(nk.get(f.kind, 0)) + 1
			var nm: String = FleetsM.kind_name(f.kind)
			chk(not (pre and nm.find("Denizaltı") >= 0), "%s: eski çağda denizaltı adı: %s" % [era, nm])
			chk(not (pre and f.kind == "carrier"), "%s: eski çağda uçak gemisi grubu" % era)
			chk(not (fam == "ww1" and f.kind == "carrier"), "%s: ww1'de uçak gemisi grubu" % era)
			var dn: String = FleetsM.display_name(g, f)
			chk(not (pre and dn.find("Denizaltı") >= 0), "%s: ad: %s" % [era, dn])
			var sh: Array = Ext.ships(g, f)
			chk(not sh.is_empty(), "%s: gemi listesi boş" % era)
			for r in sh:
				var ic: String = Ext.row_icon(r)
				chk(ic != "" and Icons.pick(ic, "") != "", "%s: simge yok %s" % [era, str(r)])
				if pre:
					var n2: String = String(r[1])
					chk(n2.find("Dretnot") < 0 and n2.find("Muhrip") < 0 and n2.find("Denizaltı") < 0 and n2.find("Uçak") < 0, "%s: çağ dışı gemi %s" % [era, n2])
			chk(Icons.pick(FleetsM.kind_icon(f.kind), "") != "", "%s: tür simgesi yok" % era)
			chk(Ext.undersea(f.kind) == (f.kind == "sub" and not pre), "%s: undersea" % era)
		# hava filosu teknolojisi: kanadı olan her ülkenin hava envanteri var, eski çağda hiç yok
		if pre:
			chk(g.wings.is_empty(), "%s: eski çağda hava filosu var (%d)" % [era, g.wings.size()])
		for w in g.wings.values():
			chk(Air.qualifies(g.countries[w.owner]), "%s: teknolojisiz hava filosu %s" % [era, g.countries[w.owner].name])
		print("ERA %-14s fam=%-4s fleets=%s wings=%d" % [era, fam, str(nk), g.wings.size()])
	print("HATA SAYISI=", bad)
	quit()
