extends SceneTree
const M = preload("res://scripts/militias.gd")
const Loc = preload("res://scripts/loc.gd")
func _words() -> Array:
	var out: Array = []
	for d in [M.PRE_POOL, M.PRE_TYPE, M.WW_TYPE, M.TYPE]:
		for k in d: out.append_array(d[k])
	for cul in M.POOLS:
		for k in M.POOLS[cul]: out.append_array(M.POOLS[cul][k])
	for sp in M.SPECIAL:
		for k in M.SPECIAL[sp]: out.append_array(M.SPECIAL[sp][k])
	return out
func _init():
	var miss := {}
	for w in _words():
		if not M.EN.has(w): miss[w] = true
	Loc.lang = "en"
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var tr_re := RegEx.new(); tr_re.compile("[ğüşıöçĞÜŞİÖÇâî]")
	var badn := 0
	var sample := []
	for i in 600:
		for kind in ["rebel", "merc", "cell"]:
			var n: String = M.make(null, rng, kind)
			if tr_re.search(n): badn += 1
			if i < 3: sample.append(n)
	Loc.lang = "tr"
	var trn: String = M.make(null, rng, "merc")
	print("EKSIK=", miss.keys(), " TR_HARF_ADI=", badn, " ornek=", sample, " tr=", trn)
	print("== militia_en: ", miss.size() + badn, " bad")
	quit()
