extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const Faith = preload("res://scripts/faith.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	var tr: int = gs.macro_idx["Turkey"]
	var gr: int = gs.macro_idx["Greece"]
	gs.start_game(tr)
	gs.declare_war(tr, gr)
	var w = gs.get_war(tr, gr)
	ck("savaş var", w != null)
	var occ = gs.peace_options(w, tr, false)
	var all = gs.peace_options(w, tr, true)
	print("işgalli=", occ.size(), " tümü=", all.size())
	ck("işgalsiz seçenekler geldi", all.size() > occ.size())
	var free_n := 0
	for o in all:
		if o.get("free", false):
			free_n += 1
			ck("serbest maliyet 1.5x", o.cost >= gs.provinces[o.pid].peace_cost())
			break
	ck("serbest var", free_n > 0)
	# puanla il al
	w.add(tr, 40)
	var picked: Array = []
	var left: int = w.score_of(tr)
	for o in all:
		if o.cost <= left and picked.size() < 2:
			picked.append(o.pid); left -= o.cost
	gs.finish_peace(w, tr, picked, [])
	for pid in picked:
		ck("il alındı", gs.provinces[pid].owner == tr)
	# din dönüştürme
	var pid2 := -1
	for p in gs.provinces:
		if p.owner == tr and p.controller == tr and Faith.of(gs, p.id) != Faith.state_faith(gs, tr):
			pid2 = p.id; break
	if pid2 < 0:
		var cand = gs.country_province_ids(tr)[3]
		gs.faith[str(cand)] = "christian" if Faith.state_faith(gs, tr) != "christian" else "islam"
		pid2 = cand
	gs.countries[tr].gold = 1.0e7
	var r: String = gs.player_convert_faith(pid2)
	ck("dönüştürme " + r, r == "" and Faith.of(gs, pid2) == Faith.state_faith(gs, tr))
	print("HATA SAYISI=", fails)
	quit(1 if fails > 0 else 0)
