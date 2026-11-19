extends SceneTree
## Komşu ülkelerin renkleri birbirine fazla yakın mı?
const GS = preload("res://scripts/game_state.gd")
const CC = preload("res://scripts/country_colors.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(5)
	var bad := 0
	var seen := {}
	for p in gs.provinces:
		for q in p.neighbors:
			var o: int = gs.provinces[q].owner
			if o == p.owner or o < 0 or p.owner < 0:
				continue
			var k := "%d_%d" % [mini(o, p.owner), maxi(o, p.owner)]
			if seen.has(k):
				continue
			seen[k] = true
			var a = gs.countries[p.owner]
			var b = gs.countries[o]
			var d: float = CC.dist(a.color, b.color)
			if d < 0.42:
				bad += 1
				print("YAKIN d=%.2f  %s / %s  #%s #%s" % [d, a.name_en, b.name_en, a.color.to_html(false), b.color.to_html(false)])
	print("yakın çift: ", bad, " / ", seen.size())
	for n in ["Russia", "Ukraine", "Turkey", "Greece", "Germany", "France"]:
		print(n, " #", gs.countries[gs.macro_idx[n]].color.to_html(false))
	quit()
