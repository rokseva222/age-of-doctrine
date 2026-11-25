extends SceneTree
## Kılıç düellosu (yönlü) mantığı: iyi oyuncu kazanır, pasif/rastgele oyuncu kaybeder; kusursuz siper ve aldatma kuralları.
const BD = preload("res://scripts/blade_duel_core.gd")
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1

## mode: skilled (rakibi okur, tepkisel siper, açıkta vurur) | random | idle | turtle (hep aynı yöne siper)
func run(mode: String, seed_: int, skill: float, power: float) -> Dictionary:
	var c = BD.new()
	c.setup(skill, power, seed_)
	var r := RandomNumberGenerator.new()
	r.seed = seed_ + 77
	var dt := 1.0 / 60.0
	var react := 0.0
	var seen := -1
	var steps := 0
	var parries := 0
	while c.outcome == "" and steps < 20000:
		steps += 1
		match mode:
			"skilled":
				# rakibin vuruşunu 0.12 sn gecikmeyle okur ve o yöne siper alır
				if c.f.state == "wind":
					if seen != c.f.wind_id:
						seen = c.f.wind_id
						react = 0.12
					react -= dt
					if react <= 0.0:
						c.player_guard(c.f.dir)
				else:
					seen = -1
					# rakip açıktayken (iyileşme/sendeleme) ya da siper tutmuyorken vurur: siperi olmayan yönü seçer
					if c.p.state == "idle" and (c.f.state == "recover" or c.f.state == "stagger" or (c.f.state == "idle" and r.randf() < 0.01)):
						var d: int = r.randi() % 4
						if c.f.guard >= 0:
							d = (c.f.guard + 1 + r.randi() % 3) % 4
						c.player_attack(d)
			"random":
				if r.randf() < 0.03:
					c.player_guard(r.randi() % 4)
				if r.randf() < 0.02:
					c.player_attack(r.randi() % 4)
			"turtle":
				c.player_guard(1)
		for ev in c.events:
			if ev[0] == "parry" and ev[1][0] == "p" and bool(ev[1][1]):
				parries += 1
		c.events.clear()
		c.update(dt)
	return {"out": c.outcome, "parries": parries, "t": c.clock, "php": c.p.hp, "fhp": c.f.hp}

func _init() -> void:
	var n := 30
	for power in [0.8, 1.1, 1.4]:
		var w := {"skilled": 0, "random": 0, "idle": 0, "turtle": 0}
		var pf := 0
		var tsum := 0.0
		for mode in w:
			for i in n:
				var res: Dictionary = run(mode, i + 1, 0.3, power)
				if res.out == "win":
					w[mode] += 1
				if mode == "skilled":
					pf += res.parries
					tsum += res.t
		print("güç ", power, " kazanma: ", w, "  kusursuz siper/oyun=", snappedf(float(pf) / n, 0.1), "  ort. süre=", snappedf(tsum / n, 0.1), " sn")
		ck("güç %.1f: pasif oyuncu kazanamaz" % power, w["idle"] == 0)
		ck("güç %.1f: rastgele oyuncu çoğunlukla kaybeder" % power, w["random"] <= n * 0.5)
		ck("güç %.1f: hep aynı yöne siper tutan kazanamaz" % power, w["turtle"] <= n * 0.15)
	var w1 := 0
	for i in n:
		if run("skilled", i + 1, 0.3, 1.1).out == "win":
			w1 += 1
	ck("orta güçte iyi oyuncu çoğunlukla kazanır (%d/%d)" % [w1, n], w1 >= n * 0.7)
	var w2 := 0
	for i in n:
		if run("skilled", i + 1, 0.3, 1.4).out == "win":
			w2 += 1
	ck("güçlü rakipte iyi oyuncu yine kazanabilir ama zorlanır (%d/%d)" % [w2, n], w2 >= n * 0.2 and w2 <= w1)
	# kurallar
	var c = BD.new()
	c.setup(0.3, 1.0, 5)
	c.f.guard = -1
	c._ai_next_attack = 999.0
	c._ai_next_idle = 999.0
	# 1) doğru yöne tepkisel siper = kusursuz: saldıran sendeler
	c.f.state = "wind"; c.f.t = 0.0; c.f.dur = 0.5; c.f.dir = 2
	c.update(0.3)
	c.player_guard(2)
	c.update(0.25)
	ck("tepkisel doğru siper kusursuz sayılır, saldıran sendeler", c.f.state == "stagger" and c.p.hp == 100.0)
	# 2) uzun süredir tutulan doğru siper normal siperdir
	var c2 = BD.new()
	c2.setup(0.3, 1.0, 5)
	c2._ai_next_attack = 999.0
	c2._ai_next_idle = 999.0
	c2.player_guard(0)
	c2.update(1.0)
	c2.f.state = "wind"; c2.f.t = 0.0; c2.f.dur = 0.5; c2.f.dir = 0
	c2.update(0.55)
	ck("eskiden tutulan doğru siper vuruşu durdurur ama sendeletmez", c2.f.state == "recover" and c2.p.hp == 100.0)
	# 3) yanlış yön: isabet
	var c3 = BD.new()
	c3.setup(0.3, 1.0, 5)
	c3._ai_next_attack = 999.0
	c3._ai_next_idle = 999.0
	c3.player_guard(0)
	c3.update(0.5)
	c3.f.state = "wind"; c3.f.t = 0.0; c3.f.dur = 0.5; c3.f.dir = 2
	c3.update(0.55)
	ck("yanlış yöne siper: isabet ve sersemleme", c3.p.hp < 100.0 and c3.p.state == "stagger")
	# 4) aldatma: hazırlığın başında yön değiştirilir, sonunda değiştirilemez
	var c4 = BD.new()
	c4.setup(0.3, 1.0, 5)
	c4._ai_next_attack = 999.0
	c4._ai_next_idle = 999.0
	c4.player_attack(1)
	c4.update(0.1)
	c4.player_redirect(3)
	ck("hazırlığın başında yön değişir", c4.p.dir == 3)
	c4.update(0.2)
	c4.player_redirect(0)
	ck("hazırlığın sonunda yön değişmez", c4.p.dir == 3)
	# 5) vuruş sırasında siper tutulamaz; aldatma ile vazgeçilir
	var c5 = BD.new()
	c5.setup(0.3, 1.0, 5)
	c5._ai_next_attack = 999.0
	c5._ai_next_idle = 999.0
	c5.player_attack(1)
	c5.player_guard(1)
	ck("vuruş sırasında siper alınamaz", c5.p.guard == -1)
	c5.update(0.05)
	c5.player_feint()
	ck("aldatma vuruştan vazgeçirir", c5.p.state == "recover")
	# 6) iki taraf aynı anda vurursa önce temas eden isabet alır, ikincisinin vuruşu yarıda kesilir
	var c6 = BD.new()
	c6.setup(0.0, 1.0, 5)
	c6._ai_next_attack = 999.0
	c6._ai_next_idle = 999.0
	c6.p.state = "wind"; c6.p.t = 0.0; c6.p.dur = 0.4; c6.p.dir = 1
	c6.f.state = "wind"; c6.f.t = 0.0; c6.f.dur = 0.5; c6.f.dir = 0
	c6.update(0.45)
	ck("daha önce temas eden vurur, diğerinin vuruşu kesilir", c6.f.hp < 100.0 and c6.p.hp == 100.0 and c6.f.state == "stagger")
	print("HATA SAYISI=", errs)
	quit()
