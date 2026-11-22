extends SceneTree
## Eksik ikon denetimi (silah/birlik modelleri). godot --headless --path . -s tools/asset_audit.gd
func _init() -> void:
	var Ar = load("res://scripts/arsenal.gd")
	var Ic = load("res://scripts/icons.gd")
	var Eras = load("res://scripts/eras.gd")
	var seen := {}
	var miss_list: Array = []
	var tot := {"specific": 0, "mapped": 0, "generic": 0}
	var ids: Array = [""]
	for ed in Eras.all():
		ids.append(String(ed["id"]))
	for eid in ids:
		Ar.set_era(eid)
		var items: Dictionary = Ar.ITEMS
		var per := {"specific": 0, "mapped": 0, "generic": 0}
		for id in items:
			if seen.has(id):
				continue
			seen[id] = true
			var cat: String = items[id][1]
			if Ic.pick("x_" + id, "") != "":
				per["specific"] += 1
				continue
			var mn := ""
			if Ar.ITEM_ICON.has(id):
				mn = String(Ar.ITEM_ICON[id])
			elif Ar.MODERN_ICON.has(id):
				mn = String(Ar.MODERN_ICON[id])
			if mn != "" and Ic.pick(mn, "") != "":
				per["mapped"] += 1
				miss_list.append("MAP|%s|%s|%s|%s|%s|%s" % [eid, id, cat, items[id][0], items[id][2], mn])
			else:
				per["generic"] += 1
				miss_list.append("GEN|%s|%s|%s|%s|%s|" % [eid, id, cat, items[id][0], items[id][2]])
		print("çağ %-12s yeni model: %3d  özel: %3d  eşlenmiş: %3d  genel: %3d" % [eid if eid != "" else "modern", per.specific + per.mapped + per.generic, per.specific, per.mapped, per.generic])
		for k in per:
			tot[k] += per[k]
	print("TOPLAM benzersiz model: ", seen.size(), " ", tot)
	var f := FileAccess.open("/tmp/missing_items.txt", FileAccess.WRITE)
	for l in miss_list:
		f.store_line(l)
	f.close()
	quit()
