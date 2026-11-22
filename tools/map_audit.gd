extends SceneTree
## Tüm mod/dönem/senaryolarda harita tutarlılık denetimi: sahiplik, başkent, kopuk (exclave) eyalet grupları, ölü ülke eyaletleri.
## godot --headless --path . -s tools/map_audit.gd
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")

var problems := 0

func _check(gs, label: String) -> void:
	var n: int = gs.provinces.size()
	var cnt := {}
	for p in gs.provinces:
		if p.owner < 0 or p.owner >= gs.countries.size():
			print("  [HATA] ", label, ": eyalet ", p.id, " ", p.name, " sahibi geçersiz ", p.owner); problems += 1; continue
		if p.controller < 0 or p.controller >= gs.countries.size():
			print("  [HATA] ", label, ": eyalet ", p.id, " ", p.name, " kontrolcü geçersiz ", p.controller); problems += 1
		var oc = gs.countries[p.owner]
		if not oc.alive:
			print("  [HATA] ", label, ": eyalet ", p.id, " ", p.name, " ölü ülkeye ait: ", oc.name_en); problems += 1
		cnt[p.owner] = int(cnt.get(p.owner, 0)) + 1
	for c in gs.countries:
		var k: int = int(cnt.get(c.id, 0))
		if c.alive and k == 0:
			print("  [HATA] ", label, ": yaşayan ülkenin eyaleti yok: ", c.name_en); problems += 1
		if c.alive and k > 0:
			if c.capital < 0 or c.capital >= n:
				print("  [HATA] ", label, ": ", c.name_en, " başkent geçersiz ", c.capital); problems += 1
			elif gs.provinces[c.capital].owner != c.id:
				print("  [UYARI] ", label, ": ", c.name_en, " başkenti (", gs.provinces[c.capital].name, ") başkasında: ", gs.countries[gs.provinces[c.capital].owner].name_en); problems += 1
			if c.name == "" or c.name_en == "":
				print("  [HATA] ", label, ": ülke adı boş id=", c.id); problems += 1
	# kopuk gruplar: aynı sahibin kara komşuluğu ile bağlı olmayan eyalet grupları
	var seen := {}
	var comps := {}   # owner -> [size...]
	var first := {}
	for p in gs.provinces:
		if seen.has(p.id):
			continue
		var stack := [p.id]
		seen[p.id] = true
		var size := 0
		while not stack.is_empty():
			var cur: int = stack.pop_back()
			size += 1
			for q in gs.provinces[cur].neighbors:
				if not seen.has(q) and gs.provinces[q].owner == p.owner:
					seen[q] = true
					stack.append(q)
		if not comps.has(p.owner):
			comps[p.owner] = []
		comps[p.owner].append(size)
		if not first.has(p.owner):
			first[p.owner] = []
		first[p.owner].append(gs.provinces[p.id].name)
	var ex: Array = []
	for o in comps:
		var arr: Array = comps[o]
		if arr.size() > 1 and gs.countries[o].alive:
			ex.append("%s%s" % [gs.countries[o].name_en, str(arr)])
	ex.sort()
	print("  kopuk: ", " ".join(ex))

func _init() -> void:
	# modern
	var gs = GS.new()
	gs.new_world(5)
	gs.start_game(gs.macro_idx.get("Turkey", 0))
	print("MOD modern eyalet=", gs.provinces.size(), " ülke=", gs.countries.size())
	_check(gs, "modern")
	# dönemler
	for e in Eras.all():
		var id: String = String(e["id"])
		var g2 = GS.new()
		g2.new_world(5)
		Eras.prepare(id)
		Eras.restructure(g2, id)
		Eras.start(g2, id)
		var alive := 0
		for c in g2.countries:
			if c.alive:
				alive += 1
		print("MOD dönem ", id, " yaşayan=", alive)
		_check(g2, "dönem " + id)
		# 40 tur sonra tekrar
		g2.start_game(g2.macro_idx.get("Turkey", 0)) if false else null
		Eras.clear()
	# senaryolar
	for s in SC.all():
		var id2: String = String(s["id"])
		if id2 == "free":
			continue
		var g3 = GS.new()
		g3.new_world(5)
		var me: int = g3.macro_idx.get(s["suggest"][0] if not s["suggest"].is_empty() else "Turkey", 0)
		g3.start_game(me)
		SC.apply(g3, id2)
		print("MOD senaryo ", id2)
		_check(g3, "senaryo " + id2)
		for t in 30:
			g3.end_turn()
		_check(g3, "senaryo " + id2 + " +30 tur")
	print("TOPLAM sorun: ", problems)
	quit()
