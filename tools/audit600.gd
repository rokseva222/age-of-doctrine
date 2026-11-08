extends SceneTree
## 600 turluk denetim: değişmezleri (invariant) her 10 turda kontrol eder. Kullanım:
## godot --headless --path . -s tools/audit600.gd -- <seed> <tur> [oyuncu_ülkesi_ingilizce_ad]
const GS = preload("res://scripts/game_state.gd")
var issues := {}
func note(key: String, detail: String) -> void:
	if not issues.has(key):
		issues[key] = {"n": 0, "ex": detail}
	issues[key].n += 1
func check(gs, t: int) -> void:
	var tot_army := 0
	var by_owner := {}
	for a in gs.armies.values():
		tot_army += a.size
		by_owner[a.owner] = int(by_owner.get(a.owner, 0)) + a.size
		if a.size <= 0:
			note("ordu_boyutu<=0", "ordu %d sahibi %s" % [a.id, str(a.owner)])
		if a.owner < 0 or a.owner >= gs.countries.size():
			note("ordu_sahibi_gecersiz", str(a.owner))
		elif not gs.countries[a.owner].alive:
			note("ordu_olu_ulkede", gs.countries[a.owner].name + " t=" + str(t))
	for c in gs.countries:
		if not c.alive:
			continue
		for k in ["gold", "income", "stability", "fund"]:
			var v = c.get(k)
			if typeof(v) == TYPE_FLOAT and (is_nan(v) or is_inf(v)):
				note("nan_" + k, c.name + " t=" + str(t))
		if c.troops < 0:
			note("asker<0", c.name + " " + str(c.troops))
		if int(by_owner.get(c.id, 0)) != c.troops and not c.is_rebel:
			note("asker!=ordu_toplami", "%s troops=%d ordular=%d t=%d" % [c.name, c.troops, int(by_owner.get(c.id, 0)), t])
		if c.stability < -0.5 or c.stability > 100.5:
			note("istikrar_aralik", "%s %.1f" % [c.name, c.stability])
		if c.gold < -1.0e6:
			note("altin_cok_negatif", "%s %.0f t=%d" % [c.name, c.gold, t])
		if c.owned_ids.size() == 0 and c.alive and not c.is_rebel:
			note("eyaletsiz_canli", c.name + " t=" + str(t))
		for pid in c.owned_ids:
			if gs.provinces[pid].owner != c.id:
				note("sahiplik_uyumsuz", "%s pid=%d" % [c.name, pid])
				break
		for al in c.allies:
			if not gs.countries[al].allies.has(c.id):
				note("ittifak_asimetrik", "%s-%s" % [c.name, gs.countries[al].name])
			if c.enemies.has(al):
				note("muttefik_ayni_zamanda_dusman", "%s-%s t=%d" % [c.name, gs.countries[al].name, t])
		if c.enemies.has(c.id):
			note("kendine_savas", c.name)
		if c.name == "" or c.name_en == "":
			note("bos_isim", str(c.id))
	for w in gs.wars:
		if w.a == w.b:
			note("savas_kendine", str(w.a))
		if not gs.countries[w.a].alive or not gs.countries[w.b].alive:
			note("savas_olu_ulke", "t=" + str(t))
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_val := int(args[0]) if args.size() > 0 else 7
	var turns := int(args[1]) if args.size() > 1 else 600
	var pname: String = args[2] if args.size() > 2 else ""
	var gs = GS.new()
	gs.new_world(seed_val)
	var pid := -1
	for c in gs.countries:
		if c.name_en == pname:
			pid = c.id
	gs.start_game(pid)
	if pid >= 0:
		gs.countries[pid].auto_cmd = true
	var t0 := Time.get_ticks_msec()
	var peak_wars := 0
	for t in turns:
		gs.end_turn()
		peak_wars = maxi(peak_wars, gs.wars.size())
		if (t + 1) % 10 == 0:
			check(gs, t + 1)
		if (t + 1) % 100 == 0:
			var tt := 0
			var al := 0
			for c in gs.countries:
				if c.alive and not c.is_rebel:
					tt += c.troops
					al += 1
			print("tur %d savas=%d yasayan=%d toplam_asker=%d sure=%ds" % [gs.turn, gs.wars.size(), al, tt, (Time.get_ticks_msec() - t0) / 1000])
	print("SEED=%d TUR=%d tepe_savas=%d" % [seed_val, turns, peak_wars])
	if pid >= 0:
		var pc = gs.countries[pid]
		print("oyuncu %s: alive=%s eyalet=%d asker=%d altin=%.0f istikrar=%.1f" % [pc.name, str(pc.alive), pc.owned_ids.size(), pc.troops, pc.gold, pc.stability])
	if issues.is_empty():
		print("SORUN_YOK")
	for k in issues:
		print("SORUN %s x%d örnek: %s" % [k, issues[k].n, issues[k].ex])
	quit()
