extends SceneTree
const M = preload("res://scripts/missions.gd")
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.load_all()
	var keep_m = St.missions.duplicate(true); var keep_xp = St.xp; var keep_s = St.streak; var keep_sd = St.streak_day
	St.missions = {}; St.xp = 0; St.streak = 0; St.streak_day = -1
	M.ensure_current()
	print("gün=", M.today(), " hafta=", M.week_of(M.today()))
	for t in St.missions.daily: print("  G ", t.k, " ", t.n, " ", t.t, " ", t.xp)
	for t in St.missions.weekly: print("  H ", t.k, " ", t.n, " ", t.t, " ", t.xp)
	# aynı gün aynı görevler
	var a = St.missions.daily.duplicate(true)
	St.missions = {}; M.ensure_current()
	var same := true
	for i in 3: if St.missions.daily[i].t != a[i].t: same = false
	print("deterministik: ", same)
	var tot := 0
	for k in ["turns", "captures", "battles", "orders", "peace", "alliance", "un", "landing", "strike", "war"]:
		var r = M.add(k, 40)
		tot += r.done.size()
	print("biten=", tot, " xp=", St.xp, " rütbe=", M.rank_of(St.xp).name, " seri=", M.streak_now())
	# ertesi gün
	St.missions["day"] = M.today() - 1
	M.ensure_current()
	print("yenilendi: ", St.missions.daily[0].p == 0)
	print("rütbe 6000=", M.rank_of(6000).name, " 99=", M.rank_of(99).name)
	St.save_all()
	var St2 = load("res://scripts/settings.gd")
	St2.load_all()
	print("kayıttan xp=", St2.xp, " günlük sayısı=", St2.missions.daily.size())
	St.missions = keep_m; St.xp = keep_xp; St.streak = keep_s; St.streak_day = keep_sd
	St.save_all()
	quit()
