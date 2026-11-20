extends SceneTree
## Dönem denetimi: her dönem için başlangıç yılı, silah envanteri (hangi silahlar kaç ülkede), liderler, kabine
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Names = preload("res://scripts/names.gd")
func _init() -> void:
	var ids: Array = []
	for e in Eras.all():
		ids.append(String(e["id"]))
	ids.append("")
	for id in ids:
		var gs = GS.new()
		gs.new_world(5)
		if id != "":
			Eras.prepare(id)
			Eras.restructure(gs, id)
			Eras.start(gs, id)
		var items: Dictionary = {}
		var alive := 0
		for c in gs.countries:
			if not c.alive:
				continue
			alive += 1
			for iid in c.inv:
				if int(c.inv[iid]) > 0:
					var nm: String = Arsenal.name_of(iid)
					items[nm] = int(items.get(nm, 0)) + 1
		var lst: Array = []
		for k in items:
			lst.append("%s×%d" % [k, items[k]])
		lst.sort()
		print("ERA\t", id, "\t", Names.start_year, "\talive=", alive, "\tarsenal_key=", Arsenal.key)
		print("ITEMS\t", id, "\t", " | ".join(lst))
		var ld: Array = []
		for c in gs.countries:
			if c.alive and c.leader != "" and (c.troops > 0):
				ld.append("%s:%s" % [c.name_en, c.leader])
		print("LEAD\t", id, "\t", "; ".join(ld.slice(0, 60)))
		var nol: Array = []
		for c in gs.countries:
			if c.alive and c.leader == "":
				nol.append("%s(%d)" % [c.name_en, c.troops])
		print("NOLEAD\t", id, "\t", ", ".join(nol))
		if id != "":
			Eras.clear()
	quit()
