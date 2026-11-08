extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const CP = preload("res://scripts/chokepoints.gd")

func _init() -> void:
	var errs := 0
	var g = GS.new()
	g.new_world(4242)
	var eg: int = int(g.macro_idx.get("Egypt", 0))
	g.start_game(eg)
	CP.ensure(g)
	for id in CP.ids():
		var c: int = CP.controller(g, id)
		print("  ", id, " -> ", g.countries[c].name if c >= 0 else "?", " mod=", g.chokes[id].mode)
	if CP.controller(g, "suez") != eg:
		print("HATA suez kontrolcüsü Mısır değil"); errs += 1
	# toll
	var e0: float = float(g.countries[eg].income)
	print("hata:", CP.set_mode(g, "suez", "toll"))
	g.end_turn()
	var m1: float = CP.income_mult(g.countries[eg])
	print("Mısır toll çarpanı=", m1)
	if m1 <= 1.0: print("HATA toll çarpanı >1 değil"); errs += 1
	var other: int = int(g.macro_idx.get("Brazil", 0))
	print("Brezilya çarpanı=", CP.income_mult(g.countries[other]))
	# cooldown
	var err: String = CP.set_mode(g, "suez", "all")
	print("cooldown mesajı: ", err)
	if err == "": print("HATA cooldown yok"); errs += 1
	for i in 5: g.end_turn()
	print("all:", CP.set_mode(g, "suez", "all"))
	g.end_turn()
	var m2: float = CP.income_mult(g.countries[other])
	print("herkese kapalı: Brezilya çarpanı=", m2, " infamy=", g.infamy)
	if m2 >= 1.0: print("HATA all çarpanı <1 değil"); errs += 1
	# kayıt
	var d: Dictionary = g.to_dict()
	var g2 = GS.new()
	g2.new_world(4242)
	g2.from_dict(d)
	print("yüklenen mode=", g2.chokes["suez"].mode, " ctrl=", g2.chokes["suez"].ctrl)
	if String(g2.chokes["suez"].mode) != "all": print("HATA kayıt"); errs += 1
	# 100 tur kararlılık
	for i in 100: g.end_turn()
	var cnt := 0
	for id in CP.ids():
		if String(g.chokes[id].mode) != "open": cnt += 1
	print("100 tur sonra açık olmayan geçit sayısı: ", cnt)
	print("HATA SAYISI=", errs)
	quit()
