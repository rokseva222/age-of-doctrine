extends SceneTree
## Kılıç düellosu mantığı: kusursuz oyuncu kazanır, pasif oyuncu kaybeder, rastgele oyuncu çoğunlukla kaybeder
const SD = preload("res://scripts/sword_duel.gd")
var errs := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: errs += 1
func run(mode: String, seed_: int, skill: float, power: float) -> String:
	var c = SD.Core.new()
	c.setup(skill, power, seed_)
	var dt := 0.016
	var r := RandomNumberGenerator.new()
	r.seed = seed_ + 99
	var steps := 0
	while c.phase != "over" and steps < 20000:
		steps += 1
		if mode == "perfect":
			if c.phase == "wind" and c.t >= c.wind - 0.1:
				c.press_guard(c.dir)
			elif c.phase == "wind" and c.t >= c.wind * 0.8:
				c.press_guard(c.show_dir)
			if c.phase == "counter":
				c.press_strike()
		elif mode == "random":
			if c.phase == "wind" and r.randf() < 0.05:
				c.press_guard(r.randi() % 3)
			if c.phase == "counter" and r.randf() < 0.1:
				c.press_strike()
		c.update(dt)
	return c.outcome
func _init() -> void:
	var wins := {"perfect": 0, "random": 0, "idle": 0}
	var n := 20
	for mode in wins:
		for i in n:
			if run(mode, i + 1, 0.3, 1.1) == "win":
				wins[mode] += 1
	print(wins)
	ck("kusursuz oyuncu hep kazanır", wins["perfect"] >= n - 1)
	ck("pasif oyuncu kazanamaz", wins["idle"] == 0)
	ck("rastgele oyuncu çoğunlukla kaybeder", wins["random"] <= n / 3)
	ck("sonuç her zaman üretilir", run("idle", 5, 0.3, 1.4) != "")
	print("HATA SAYISI=", errs)
	quit()
