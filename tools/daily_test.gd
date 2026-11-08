extends SceneTree
const GS = preload("res://scripts/game_state.gd")
const D = preload("res://scripts/daily.gd")
const Settings = preload("res://scripts/settings.gd")

func _init() -> void:
	var errs := 0
	# aynı gün aynı yapılandırma, farklı gün farklı
	var a: Dictionary = D.cfg(20000)
	var b: Dictionary = D.cfg(20000)
	if JSON.stringify(a) != JSON.stringify(b): print("HATA cfg deterministik değil"); errs += 1
	var seen := {}
	for d in range(20000, 20030):
		var c: Dictionary = D.cfg(d)
		seen[c.country + ":" + c.twist] = true
	print("30 günde farklı kombinasyon: ", seen.size())
	# her çarpıtmayı bir ülkede dene, 60 tur oyna
	var wonmsg := ""
	for t in D.TWISTS:
		var conf: Dictionary = {"day": 20001, "seed": 555, "country": "Turkey", "twist": t.id, "turns": 52}
		var g = GS.new()
		g.new_world(int(conf.seed))
		var pc: int = int(g.macro_idx.get("Turkey", 0))
		g.start_game(pc)
		D.begin(g, conf)
		var s0: int = D.score(g)
		var got := [false]
		g.game_over.connect(func(v, txt): got[0] = true; wonmsg = txt)
		for i in 60:
			g.end_turn()
		print("  ", t.id, " başlangıç skor=", s0, " bitti=", got[0], " skor=", g.daily.score, " savaş=", g.wars.size())
		if not got[0] and g.countries[pc].alive: print("HATA süre dolunca bitmedi ", t.id); errs += 1
	print(wonmsg)
	# aynı tohum, aynı sonuç (determinizm)
	var scores: Array = []
	for k in 2:
		var conf2: Dictionary = {"day": 20002, "seed": 999, "country": "Poland", "twist": "poor", "turns": 52}
		var g2 = GS.new()
		g2.new_world(999)
		g2.start_game(int(g2.macro_idx.get("Poland", 0)))
		D.begin(g2, conf2)
		for i in 30: g2.end_turn()
		scores.append(D.score(g2))
	print("determinizm skorları: ", scores)
	if scores[0] != scores[1]: print("HATA aynı tohum farklı sonuç"); errs += 1
	# kayıt: ilk bitiriş AP, tekrar AP yok
	var r1: Dictionary = D.record(30000, 1800)
	var r2: Dictionary = D.record(30000, 2600)
	print("kayıt: ", r1, r2)
	if int(r1.ap) <= 0 or int(r2.ap) != 0: print("HATA AP kuralı"); errs += 1
	var r3: Dictionary = D.record(30001, 100)
	if int(r3.streak) != 2: print("HATA seri ", r3); errs += 1
	# kaydet/yükle
	var g3 = GS.new()
	g3.new_world(5)
	g3.start_game(int(g3.macro_idx.get("Egypt", 0)))
	D.begin(g3, {"day": 1, "seed": 5, "country": "Egypt", "twist": "rich", "turns": 52})
	var g4 = GS.new(); g4.new_world(5); g4.from_dict(g3.to_dict())
	if not D.active(g4): print("HATA kayıt daily"); errs += 1
	print("HATA SAYISI=", errs)
	quit()
