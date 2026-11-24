extends SceneTree
## Her çağ/senaryo başlangıcında sahipsiz (delik) ya da ölü ülkeye ait eyalet var mı?
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
func _init() -> void:
	var total := 0
	var ids: Array = [""]
	for e in Eras.all():
		ids.append(String(e["id"]))
	for id in ids:
		var g = GS.new()
		g.new_world(3)
		if id != "":
			Eras.restructure(g, id)
		var pc := 0
		for c in g.countries:
			if c.alive:
				pc = c.id
				break
		g.start_game(pc)
		if id != "":
			Eras.start(g, id)
		var no_owner: Array = []
		var dead: Array = []
		var ctl_bad: Array = []
		for p in g.provinces:
			if p.owner < 0:
				no_owner.append(p.id)
			elif not g.countries[p.owner].alive:
				dead.append(p.id)
			if p.controller < 0 and p.owner >= 0:
				ctl_bad.append(p.id)
		var bad: int = no_owner.size() + dead.size() + ctl_bad.size()
		total += bad
		print("%s %-10s sahipsiz=%d ölü-ülkeye-ait=%d denetimsiz=%d %s" % ["HATA" if bad > 0 else "OK  ", id if id != "" else "dunya2027", no_owner.size(), dead.size(), ctl_bad.size(), str((no_owner + dead + ctl_bad).slice(0, 6)) if bad > 0 else ""])
	print("HATA SAYISI=", total)
	quit()
