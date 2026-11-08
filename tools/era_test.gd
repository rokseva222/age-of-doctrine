extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Macro = preload("res://scripts/macro.gd")
const Names = preload("res://scripts/names.gd")

func _init() -> void:
	for id in ["ww1", "ww2"] + Eras.all().map(func(e): return e["id"]).filter(func(i): return i != "ww1" and i != "ww2"):
		# katalog doğrulama
		Eras.prepare(id)
		var bad := 0
		for k in Arsenal.BLOC:
			for cat in Arsenal.CATS:
				var arr: Array = Arsenal.BLOC[k][cat]
				if arr.size() != 4:
					print("  [!] ", k, " ", cat, " boyut ", arr.size()); bad += 1
				for iid in arr:
					if not Arsenal.ITEMS.has(iid):
						print("  [!] eksik id ", iid, " bloc ", k); bad += 1
					elif Arsenal.cat_of(iid) != cat:
						print("  [!] kategori uyumsuz ", iid, " ", k, " ", cat); bad += 1
		for f in Arsenal.FAMILY:
			for cat in Arsenal.FAMILY[f]:
				for iid in Arsenal.FAMILY[f][cat]:
					if not Arsenal.ITEMS.has(iid):
						print("  [!] family eksik ", iid); bad += 1
		for g in Arsenal.GATE:
			if not Arsenal.ITEMS.has(g):
				print("  [!] gate eksik ", g); bad += 1
		print("== ", id, " katalog hatası: ", bad, " öğe: ", Arsenal.ITEMS.size())
		var g = GS.new()
		g.new_world(12345)
		Eras.restructure(g, id)
		var idx: Dictionary = {}
		for c in g.countries:
			idx[c.name_en] = c.id
		print("  yaşayan ülke: ", g.countries.filter(func(c): return c.alive and not c.is_rebel).size(), "  tarih: ", Names.date_string(0))
		var rows: Array = []
		for c in g.countries:
			if c.alive and c.prov_owned > 0:
				rows.append(c)
		rows.sort_custom(func(a, b): return a.income > b.income)
		for i in mini(12, rows.size()):
			var c = rows[i]
			print("  %-26s eyalet=%3d asker=%8d gelir=%8.1f M\\$/hf nüfus=%6.1fM lider=%s tech=%.2f" % [c.name, c.prov_owned, c.troops, c.income, c.pop, Macro.leader_of(c)[1], c.tech])
		var pl: int = int(idx.get("Germany", 0))
		g.start_game(pl)
		Eras.start(g, id)
		print("  savaş sayısı başta: ", g.wars.size(), " blok: ", g.blocs.size())
		var t0 := Time.get_ticks_msec()
		for t in 80:
			g.end_turn()
		print("  80 tur: %d ms, savaş=%d, tarih=%s" % [Time.get_ticks_msec() - t0, g.wars.size(), Names.date_string(g.turn)])
		var rows2: Array = []
		for c in g.countries:
			if c.alive and c.prov_owned > 0:
				rows2.append(c)
		rows2.sort_custom(func(a, b): return a.prov_owned > b.prov_owned)
		for i in mini(8, rows2.size()):
			var c2 = rows2[i]
			print("   t80 %-26s eyalet=%3d asker=%8d" % [c2.name, c2.prov_owned, c2.troops])
		# kayıt-yükleme
		g.save_to("/tmp/era_save.dat")
		var g2 = GS.new()
		print("  yükleme: ", g2.load_from("/tmp/era_save.dat"), " era=", Eras.current, " tur=", g2.turn, " isim=", g2.countries[pl].name)
	Eras.clear()
	quit()
