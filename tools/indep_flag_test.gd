extends SceneTree
## Bağımsızlık Yolu: oyuncunun tasarladığı bayrak hareket ülkesine geçer, kayda girer, çizilir.
const GS = preload("res://scripts/game_state.gd")
const I = preload("res://scripts/independence.gd")
const Flags = preload("res://scripts/flags.gd")
const FlagEditor = preload("res://scripts/flag_editor.gd")
func _init() -> void:
	var gs = GS.new()
	gs.new_world(77)
	gs.start_game(gs.macro_idx["Spain"])
	var spec: String = "H:c83030,f0e0a0*2,2050a0|S:0.5,0.5,0.2,ffffff,5"
	var ok := I.begin(gs, {"host_en": "Spain", "dir": "east", "n": 3, "name": "Bayrak Hareketi", "color": 1, "ideo": "federal", "method": "uprising", "flag": spec})
	var fid := -1
	for c in gs.countries:
		if c.name == "Bayrak Hareketi":
			fid = c.id
	var fs: String = gs.countries[fid].flag_spec if fid >= 0 else "?"
	var d: Dictionary = gs.to_dict()
	var g2 = GS.new()
	g2.from_dict(d)
	var fs2: String = g2.countries[fid].flag_spec
	var layers: Array = Flags.layers_for(gs.countries[fid])
	print("SONUC begin=", ok, " spec_ayni=", fs == spec, " kayit_ayni=", fs2 == spec, " katman=", layers.size())
	# bayraksız: renklerden otomatik
	var gs3 = GS.new(); gs3.new_world(78); gs3.start_game(gs3.macro_idx["Spain"])
	I.begin(gs3, {"host_en": "Spain", "dir": "east", "n": 3, "name": "Düz Hareket", "color": 0, "ideo": "federal", "method": "uprising"})
	var f3 = null
	for c in gs3.countries:
		if c.name == "Düz Hareket": f3 = c
	print("SONUC2 bayraksiz_spec_bos=", f3.flag_spec == "", " katman=", Flags.layers_for(f3).size())
	quit(0)
