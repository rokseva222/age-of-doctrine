extends SceneTree
const GS = preload("res://scripts/game_state.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	var me_n: String = OS.get_environment("ME") if OS.get_environment("ME") != "" else "Hungary"
	var en_n: String = OS.get_environment("EN") if OS.get_environment("EN") != "" else "Croatia"
	print(gs.macro_idx.has("Croatia"), gs.macro_idx.has("Slovenia"), gs.macro_idx.has(me_n))
	var me: int = gs.macro_idx[me_n]
	var en: int = gs.macro_idx[en_n]
	gs.start_game(me)
	var sl: int = gs.macro_idx["Slovenia"]
	print("müttefikler HR=", gs.countries[en].allies, " SI=", gs.countries[sl].allies, " blok HR=", gs.bloc_of(en) if gs.has_method("bloc_of") else "?")
	gs.declare_war(me, en)
	gs.declare_war(me, sl)
	print("savaşlar: ", gs.wars.size(), " HR savaşta ben:", gs.at_war(me, en), " SI:", gs.at_war(me, sl))
	var w = gs.get_war(me, en)
	for i in 8:
		gs.turn += 1
	w.add(me, 60)
	# gerçek oyundaki gibi: düşman eyaletlerini işgal et (kontrol bende, sahip düşman)
	var occ_n := 0
	for pr in gs.provinces:
		if (pr.owner == en or pr.owner == sl) and occ_n < 6:
			pr.controller = me
			occ_n += 1
	var opts = gs.peace_options(w, me, true)
	var picked: Array = []
	var left: int = w.score_of(me)
	for o in opts:
		if o.cost <= left and picked.size() < 6:
			picked.append(o.pid); left -= o.cost
	print("seçilen: ", picked.size())
	gs.finish_peace(w, me, picked, [])
	print("barış sonrası: HR savaşta=", gs.at_war(me, en), " SI savaşta=", gs.at_war(me, sl))
	_dump(gs, picked, me, en, "barıştan hemen sonra")
	for t in 3:
		gs.end_turn()
		_dump(gs, picked, me, en, "tur+%d" % (t + 1))
	quit()
func _dump(gs, picked, me, en, tag) -> void:
	var o := 0; var c := 0; var s := 0
	for pid in picked:
		var p = gs.provinces[pid]
		if p.owner == me: o += 1
		if p.controller == me: c += 1
		if p.controller != p.owner: s += 1
	print(tag, ": sahip=me ", o, "/", picked.size(), " kontrol=me ", c, " çizgili(işgal)=", s, " savaşta=", gs.at_war(me, en), " ateşkes=", gs.countries[me].truce.get(en, -1), " tur=", gs.turn)
