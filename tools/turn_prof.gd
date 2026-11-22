extends SceneTree
## Tur süresi dökümü: godot --headless --path . -s tools/turn_prof.gd -- [ülke] [tur] [mod]
const GS = preload("res://scripts/game_state.gd")
func _init():
	var a := OS.get_cmdline_user_args()
	var cn: String = a[0] if a.size() > 0 else "Turkey"
	var n: int = int(a[1]) if a.size() > 1 else 60
	var gs = GS.new(); gs.new_world(9); gs.start_game(int(gs.macro_idx.get(cn, 0)))
	gs.profile = true
	var t0 := Time.get_ticks_usec()
	var per: Array = []
	for t in n:
		var a0 := Time.get_ticks_usec()
		gs.end_turn()
		per.append(float(Time.get_ticks_usec() - a0) / 1000.0)
	var tot := float(Time.get_ticks_usec() - t0) / n / 1000.0
	var slow: Array = []
	for i in n:
		if per[i] > 1.3 * tot:
			slow.append("%d:%.0f" % [i + 1, per[i]])
	print("yavas turlar: ", ", ".join(slow))
	var sorted: Array = per.duplicate()
	sorted.sort()
	print("ms/tur ort=%.1f  medyan=%.1f  p95=%.1f  maks=%.1f (tur %d)" % [tot, sorted[n / 2], sorted[int(n * 0.95)], sorted[n - 1], per.find(sorted[n - 1]) + 1])
	var keys: Array = gs.prof.keys()
	keys.sort_custom(func(x, y): return gs.prof[x] > gs.prof[y])
	for k in keys:
		print("  %-14s %.1f ms/tur" % [k, float(gs.prof[k]) / n / 1000.0])
	quit()
