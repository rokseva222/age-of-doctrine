extends SceneTree
## Bayrak denetimi: her çağ/senaryo/form için canlı ülkelerin bayrağı gerçek görsel mi, kodla çizilmiş taklit mi?
## Çıktı: /tmp/rep/flag_audit.json  (kaynak -> {tür -> [ülkeler]})
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")
const Flags = preload("res://scripts/flags.gd")
const DB = preload("res://scripts/flag_db.gd")
const Formables = preload("res://scripts/formables.gd")

func _kind(c) -> String:
	if c.is_rebel:
		return "uretilmis_isyanci"
	if Flags._texture_for(c) != null:
		return "gercek"
	if c.flag_spec != "":
		return "kod_ozel"
	if not Flags.era_specs.is_empty() and Flags.era_specs.has(c.name_en):
		return "kod_donem"
	if DB.FLAGS.has(Flags._key(c)):
		return "kod_db"
	return "uretilmis_renk"

func _scan(gs, tag: String, out: Dictionary) -> void:
	var r := {}
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.prov_owned <= 0:
			continue
		var k: String = _kind(c)
		if k == "gercek":
			r["gercek"] = int(r.get("gercek", 0)) + 1
			continue
		if not r.has(k):
			r[k] = []
		(r[k] as Array).append("%s [%s|%s]" % [c.name, c.name_en, c.iso])
	out[tag] = r

func _init() -> void:
	var out := {}
	# bugünkü dünya
	Eras.clear()
	var gs = GS.new(); gs.new_world(5); gs.start_game(0)
	_scan(gs, "dunya_2027", out)
	# senaryolar
	for sc in SC.all():
		if String(sc.get("id", "")) == "free":
			continue
		var g2 = GS.new(); g2.new_world(5)
		var me: int = int(g2.macro_idx.get("Turkey", 0))
		g2.start_game(me)
		SC.apply(g2, sc["id"])
		_scan(g2, "senaryo:" + sc["id"], out)
	# çağlar
	for e in Eras.all():
		Eras.prepare(e["id"])
		var g3 = GS.new(); g3.new_world(5); g3.start_game(0)
		Eras.restructure(g3, e["id"])
		_scan(g3, "cag:" + e["id"], out)
	Eras.clear()
	# formlar
	var fm := []
	for f in Formables.all():
		var c = load("res://scripts/model.gd").Country.new()
		c.flag_spec = String(f.get("flag", ""))
		c.name = String(f.get("name", ""))
		c.name_en = c.name
		fm.append("%s (%s)" % [c.name, "kod" if c.flag_spec != "" else "bayraksız→renk"])
	out["formlar"] = fm
	var f2 := FileAccess.open("/tmp/rep/flag_audit.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(out, " "))
	f2.close()
	for k in out:
		if k == "formlar":
			print(k, ": ", out[k].size())
			continue
		var s := ""
		for t in out[k]:
			s += " %s=%s" % [t, str(out[k][t].size() if out[k][t] is Array else out[k][t])]
		print(k, s)
	quit()
