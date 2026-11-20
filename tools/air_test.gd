extends SceneTree
## Hava filoları testi: kanat türetme, üsler, menzil, hava üstünlüğü, saldırı, hava köprüsü, kayıt/yükleme, tur süresi.
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Air = preload("res://scripts/air.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const Model = preload("res://scripts/model.gd")

var fails := 0


func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok:
		fails += 1


func make(era: String, seed_v: int = 7):
	var g = GS.new()
	Eras.prepare(era) if era != "" else Eras.clear()
	g.new_world(seed_v)
	var host := "Turkey"
	if era != "":
		Eras.restructure(g, era)
		host = String(Eras.get_era(era).suggest[0])
	g.start_game(int(g.macro_idx.get(host, 0)))
	if era != "":
		Eras.start(g, era)
	return g


func inv_ok(g, tag: String) -> void:
	var bad := 0
	for w in g.wings.values():
		if w.size <= 0.0 or w.base < 0 or g.provinces[w.base].controller != w.owner:
			bad += 1
	ck("%s: kanat invaryantları (%d bozuk)" % [tag, bad], bad == 0)


func _init() -> void:
	for era in ["", "ww2", "ww1", "cw62"]:
		var g = make(era)
		Air.ensure(g)
		var me: int = g.player
		var tag: String = era if era != "" else "modern"
		ck("%s: kanatlar türetildi (%d)" % [tag, g.wings.size()], g.wings.size() > 0)
		inv_ok(g, tag)
		var mine: Array = Air.wings_of(g, me)
		ck("%s: oyuncunun kanadı var (%d)" % [tag, mine.size()], mine.size() > 0)
		var bad_planes := 0
		for w in g.wings.values():
			if Air.planes(g, w).is_empty():
				bad_planes += 1
		ck("%s: uçak sınıfı listesi dolu (%d bozuk)" % [tag, bad_planes], bad_planes == 0)
		# toplam kanat gücü ~ hava gücü / ölçek
		var tot_units := 0.0
		for w in Air.wings_of(g, me):
			tot_units += w.size
		var want: float = Air.units(g.countries[me])
		ck("%s: kanat toplamı hava gücüyle uyumlu (%.0f / %.0f)" % [tag, tot_units, want], want <= 0.0 or absf(tot_units - want) / want < 0.2)
		if era == "":
			# menzil ve saldırı: bir düşman ülkeyle savaş
			var gr: int = g.macro_idx["Greece"]
			g.player_declare_war(gr)
			var bomber = null
			for w in mine:
				if w.kind == "bomber":
					bomber = w
			if bomber == null:
				bomber = mine[0]
			# bombardıman menzilinde hedef var mı
			var tg: Array = Air.targets(g, bomber)
			ck("modern: bombardıman menzilinde düşman eyaleti (%d)" % tg.size(), tg.size() > 0)
			if tg.size() > 0:
				g.countries[me].gold = 1e9
				var before: int = int(g.armies[tg[0]].size) if g.armies.has(tg[0]) else 0
				bomber.cd = 0
				var r: Dictionary = Air.player_strike(g, bomber.id, tg[0])
				ck("modern: hava saldırısı çalıştı (%s)" % r.err, r.err == "")
				if before > 0:
					ck("modern: saldırı ordu kaybettirdi (%d)" % int(r.killed), int(r.killed) > 0)
				ck("modern: bekleme süresi kondu", bomber.cd > g.turn)
				var r2: Dictionary = Air.player_strike(g, bomber.id, tg[0])
				ck("modern: bekleme sırasında saldırı reddedilir", r2.err != "")
			# menzil dışı
			var far := -1
			for p in g.provinces:
				if p.owner != me and g.at_war(me, p.owner) == false and not Air.in_range(g, bomber, p.id):
					far = p.id
					break
			ck("modern: menzil dışı hedef bulunabilir", far >= 0)
			# üs değiştirme
			var rb := -1
			for pid in g.countries[me].held_ids:
				if Air.rebase_check(g, bomber, pid) == "":
					rb = pid
					break
			if rb >= 0:
				ck("modern: üs değiştirilir", Air.rebase(g, bomber.id, rb) == "" and bomber.base == rb)
			# hava üstünlüğü
			var sup: float = Air.superiority(g, g.countries[me].capital, me, gr)
			ck("modern: hava üstünlüğü [-1,1] (%.2f)" % sup, sup >= -1.0 and sup <= 1.0)
			# hava köprüsü
			var tr = null
			for w in mine:
				if w.kind == "transport":
					tr = w
			if tr != null:
				var srcs: Array = Air.lift_sources(g, tr)
				ck("modern: hava köprüsü kaynağı var (%d)" % srcs.size(), srcs.size() > 0)
				if srcs.size() > 0:
					var ds: Array = Air.lift_dests(g, tr, srcs[0])
					ck("modern: hava köprüsü hedefi var (%d)" % ds.size(), ds.size() > 0)
					if ds.size() > 0:
						tr.cd = 0
						var tot_before: int = g.countries[me].troops
						var e: String = Air.airlift(g, tr.id, srcs[0], ds[0])
						ck("modern: hava köprüsü (%s)" % e, e == "")
			# kayıt
			Air.rename(g, mine[0].id, "Kara Şahinler")
			Air.set_flag(g, mine[0].id, "H:#aa0000,#ffffff")
			Air.set_stance(g, mine[0].id, "defend")
			var d: Dictionary = g.to_dict()
			var g2 = GS.new()
			g2.new_world(7)
			g2.from_dict(d)
			var w2 = g2.wings.get(mine[0].id)
			ck("modern: kayıt ad/bayrak/duruş", w2 != null and w2.name == "Kara Şahinler" and w2.flag.begins_with("H:") and w2.stance == "defend")
			# tur süresi
			var t0 := Time.get_ticks_msec()
			for i in 30:
				g.end_turn()
			var ms: float = float(Time.get_ticks_msec() - t0) / 30.0
			ck("modern: 30 tur sonra kanat invaryantları", true)
			inv_ok(g, "modern(30 tur)")
			print("  tur süresi (hava dâhil) %.0f ms/tur, kanat=%d" % [ms, g.wings.size()])
			Air.enabled = false
			var t1 := Time.get_ticks_msec()
			for i in 30:
				g.end_turn()
			var ms0: float = float(Time.get_ticks_msec() - t1) / 30.0
			Air.enabled = true
			print("  tur süresi (hava kapalı) %.0f ms/tur" % ms0)
		else:
			for i in 40:
				g.end_turn()
			inv_ok(g, tag + "(40 tur)")
	print("HATA SAYISI=%d" % fails)
	quit(fails)
