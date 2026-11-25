extends SceneTree
## Ajan B: çok stratejili GERÇEK oynayan bot + her turda değişmez (invariant) denetimi + oynanış ölçümü.
## Kullanım: godot --headless --path . -s tools/agentB_play.gd -- <free|era|scn> <id> <ülke_en> <strateji> <tur> <seed> [kayıt_turu]
## Stratejiler: conquer (saldırgan genişleme, çıkarma), weapons (conquer + gaz/nükleer/paralı), turtle (savunma/barış),
##   bloc (ittifak/blok/BM/diplomasi), econ (ekonomi/kabine/silah alımı), fuzz (rastgele API çağrıları, elle emirler)
## Her koşu sonunda tek satır "RESULT ..." ve her sorun için "ISSUE ..." yazar.
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const UN = preload("res://scripts/un.gd")
const Ult = preload("res://scripts/ultimatum.gd")
const Focus = preload("res://scripts/focus.gd")
const Formables = preload("res://scripts/formables.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const PlayerBot = preload("res://tools/player_bot.gd")

var gs
var bot
var rng := RandomNumberGenerator.new()
var strat := ""
var kind := ""
var era_id := ""
var pname := ""
var pid_ := -1
var issues := {}
var info := {}
var alog := {}                 # eylem sayaçları
var errlog := {}               # eylem hata metinleri (ilk 40 karakter) -> sayaç
var tms: Array = []            # tur süreleri (ms)
var slow_turns: Array = []
var prev_pairs := {}
var ai_new_wars := 0
var ai_on_player := 0
var player_decl := 0
var peace_streak := 0
var max_peace_streak := 0
var peace_streak_start := 0
var first_war_turn := -1
var war_turns := 0
var maxshare := 0.0
var maxshare_name := ""
var maxshare_turn := 0
var share_series: Array = []
var over_text := ""
var prop_names: Array = []
var unowned0 := -1
var player_min := 999999
var player_max := 0
var player_prov0 := 0
var died_turn := -1
var land_ok := 0
var land_try := 0
var base_bad := {}


func note_act(k: String) -> void:
	alog[k] = int(alog.get(k, 0)) + 1


func note_err(k: String, e: String) -> void:
	var key := k + ": " + e.substr(0, 46)
	errlog[key] = int(errlog.get(key, 0)) + 1


func bad(k: String, ex: String = "") -> void:
	if not issues.has(k):
		issues[k] = {"n": 0, "t": gs.turn, "ex": ex}
	issues[k].n += 1


func _bind_bot(strategy_aggr: bool) -> void:
	bot = PlayerBot.new(gs, rng.randi(), strategy_aggr)
	gs.game_over.connect(func(v, t): over_text = ("ZAFER@%d: " % gs.turn if v else "YENILGI@%d: " % gs.turn) + String(t))
	if strat == "fuzz" or strat == "bloc":
		gs.countries[gs.player].auto_cmd = (strat == "bloc")


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	kind = a[0]
	era_id = a[1]
	pname = a[2]
	strat = a[3]
	var turns: int = int(a[4])
	var seed_val: int = int(a[5])
	var save_at: int = int(a[6]) if a.size() > 6 else 100 + (seed_val % 90)
	rng.seed = seed_val * 7919 + 13
	if kind == "era":
		Eras.prepare(era_id)
	gs = GS.new()
	gs.new_world(seed_val)
	if kind == "era":
		Eras.restructure(gs, era_id)
	pid_ = int(gs.macro_idx.get(pname, -1))
	if pid_ < 0:
		print("RESULT HATA: ülke bulunamadı ", pname)
		quit(2)
		return
	gs.start_game(pid_)
	if kind == "era":
		Eras.start(gs, era_id)
	elif kind == "scn":
		load("res://scripts/scenarios.gd").apply(gs, era_id)
	gs.profile = false
	_bind_bot(strat == "conquer" or strat == "weapons")
	var pl = gs.countries[pid_]
	player_prov0 = pl.prov_owned
	var t_start := Time.get_ticks_msec()
	var saved_done := false
	var eras_cur0: String = Eras.current
	var load_note := ""
	for t in turns:
		if gs.countries[gs.player].alive:
			_act()
		else:
			if died_turn < 0:
				died_turn = gs.turn
		var t0 := Time.get_ticks_usec()
		gs.end_turn()
		var dt := (Time.get_ticks_usec() - t0) / 1000.0
		tms.append(dt)
		if dt > 2000.0:
			slow_turns.append("t%d=%dms" % [gs.turn, int(dt)])
		_check(gs)
		_metrics(gs)
		if (t + 1) % 50 == 0:
			print("  .. %s/%s/%s/%s tur %d savaş=%d yaşayan=%d (%ds)" % [era_id, pname, strat, str(seed_val), gs.turn, gs.wars.size(), gs.alive_count(), (Time.get_ticks_msec() - t_start) / 1000])
		if not saved_done and t + 1 == save_at:
			saved_done = true
			load_note = _save_load_cycle()
	var ms: int = Time.get_ticks_msec() - t_start
	if Eras.current != eras_cur0:
		bad("Eras.current değişti", "%s -> %s" % [eras_cur0, Eras.current])
	_report(ms, load_note, turns)
	quit()


# ===================================================================== kaydet / yükle

func _hash(g) -> String:
	var h := 0
	for p in g.provinces:
		h = (h * 31 + p.owner * 7 + p.controller * 3 + p.siege) % 1000000007
	var tr := 0
	var gd := 0.0
	for c in g.countries:
		if c.alive:
			tr += c.troops
			gd += c.gold
	return "own=%d tr=%d gold=%.0f wars=%d armies=%d alive=%d turn=%d" % [h, tr, gd, g.wars.size(), g.armies.size(), g.alive_count(), g.turn]


func _save_load_cycle() -> String:
	var path := "user://agentB_%d.dat" % OS.get_process_id()
	var h1: String = _hash(gs)
	if not gs.save_to(path):
		bad("kaydet başarısız")
		return "save-fail"
	var g2 = GS.new()
	if not g2.load_from(path):
		bad("yükle başarısız")
		return "load-fail"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var h2: String = _hash(g2)
	var note := ""
	if h1 != h2:
		bad("yükleme_sonrası_durum_farkı", "önce: %s | sonra: %s" % [h1, h2])
		note = "DIFF"
	# bekleyen kartlar kaydedilmez: yüklenen oyunda devam
	var old = gs
	gs = g2
	_bind_bot(strat == "conquer" or strat == "weapons")
	# yükleme sonrası iki oyun birbirinden bağımsız ilerlesin: sadece yüklenen devam eder
	prev_pairs = {}
	for w in gs.wars:
		prev_pairs[_pk(w.a, w.b)] = true
	old = null
	return "OK " + note


# ===================================================================== değişmezler

func _pk(a: int, b: int) -> String:
	return "%d|%d" % [mini(a, b), maxi(a, b)]


func _fprops() -> Array:
	if prop_names.is_empty():
		for pr in gs.countries[0].get_property_list():
			if pr.type == TYPE_FLOAT and (pr.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				prop_names.append(pr.name)
	return prop_names


func _check(g) -> void:
	var np: int = g.provinces.size()
	var nc: int = g.countries.size()
	var cnt := {}
	var unowned := 0
	for p in g.provinces:
		if p.owner < 0:
			unowned += 1
		elif p.owner >= nc:
			bad("eyalet_sahibi_gecersiz", "pid=%d owner=%d" % [p.id, p.owner])
		else:
			cnt[p.owner] = int(cnt.get(p.owner, 0)) + 1
			if not g.countries[p.owner].alive:
				bad("ölü_ülkenin_eyaleti", "%s pid=%d %s" % [g.countries[p.owner].name_en, p.id, p.name])
		if p.controller >= nc:
			bad("kontrolcü_geçersiz", "pid=%d" % p.id)
		elif p.controller >= 0 and not g.countries[p.controller].alive:
			bad("ölü_kontrolcü", "%s pid=%d" % [g.countries[p.controller].name_en, p.id])
		if p.owner < 0 and p.controller >= 0:
			bad("sahipsiz_ama_kontrollü", "pid=%d" % p.id)
		if is_nan(p.pop) or is_inf(p.pop) or p.pop < 0.0:
			bad("eyalet_nüfus_nan/neg", "pid=%d %s" % [p.id, str(p.pop)])
		if p.unrest < 0 or p.defense < 0:
			bad("eyalet_negatif_alan", "pid=%d unrest=%d def=%d" % [p.id, p.unrest, p.defense])
	if unowned0 < 0:
		unowned0 = unowned
	elif unowned > unowned0:
		bad("sahipsiz_eyalet_arttı", "%d -> %d" % [unowned0, unowned])
		unowned0 = unowned
	var by_owner := {}
	for key in g.armies:
		var a = g.armies[key]
		if a.prov != key:
			bad("ordu_anahtar≠prov", "key=%d prov=%d" % [key, a.prov])
		if a.prov < 0 or a.prov >= np:
			bad("ordu_geçersiz_eyalet", "army %d prov=%d" % [a.id, a.prov])
			continue
		if a.size <= 0:
			bad("ordu_boyut<=0", "army %d size=%d owner=%d" % [a.id, a.size, a.owner])
		if a.owner < 0 or a.owner >= nc:
			bad("ordu_sahibi_geçersiz", "army %d owner=%d" % [a.id, a.owner])
			continue
		by_owner[a.owner] = int(by_owner.get(a.owner, 0)) + a.size
		if not g.countries[a.owner].alive:
			bad("ölü_ülkede_ordu", "%s army %d" % [g.countries[a.owner].name_en, a.id])
		for q in a.path:
			if q < 0 or q >= np:
				bad("ordu_yol_geçersiz", "army %d" % a.id)
				break
		for q in a.sp_path:
			if q < 0 or q >= np:
				bad("ordu_sp_yol_geçersiz", "army %d" % a.id)
				break
		var po: int = g.provinces[a.prov].owner
		if po >= 0 and po != a.owner and po < nc and not (g.at_war(a.owner, po) or g.is_allied(a.owner, po) or g.has_passage(a.owner, po) or g.vassals.has(po) or g.vassals.has(a.owner)):
			info["~ordu_yabancı_topraklarda_izinsiz"] = int(info.get("~ordu_yabancı_topraklarda_izinsiz", 0)) + 1
			if not base_bad.has("yab"):
				base_bad["yab"] = "t=%d %s ordusu %s eyaletinde (%s)" % [g.turn, g.countries[a.owner].name_en, g.provinces[a.prov].name, g.countries[po].name_en]
	var pairs := {}
	for w in g.wars:
		if w.a < 0 or w.a >= nc or w.b < 0 or w.b >= nc:
			bad("savaş_geçersiz_ülke", "%d-%d" % [w.a, w.b])
			continue
		if w.a == w.b:
			bad("savaş_kendine", str(w.a))
			continue
		var pk := _pk(w.a, w.b)
		if pairs.has(pk):
			bad("savaş_yinelenen", "%s-%s" % [g.countries[w.a].name_en, g.countries[w.b].name_en])
		pairs[pk] = true
		if not g.countries[w.a].alive or not g.countries[w.b].alive:
			bad("ölü_ülkeyle_savaş", "%s-%s" % [g.countries[w.a].name_en, g.countries[w.b].name_en])
		if not g.countries[w.a].enemies.has(w.b) or not g.countries[w.b].enemies.has(w.a):
			bad("savaş_var_enemies_yok", "%s-%s" % [g.countries[w.a].name_en, g.countries[w.b].name_en])
	var deep: bool = g.turn % 5 == 0
	for f in g.fleets.values():
		if f.cargo > 0 and f.owner >= 0 and f.owner < nc:
			by_owner[f.owner] = int(by_owner.get(f.owner, 0)) + f.cargo     # denizdeki asker de toplama girer
	for c in g.countries:
		if not c.alive:
			if c.owned_ids.size() > 0 and int(cnt.get(c.id, 0)) > 0:
				bad("ölü_ülke_owned_ids", c.name_en)
			if c.enemies.size() > 0:
				bad("ölü_ülkenin_düşmanı_var", "%s %s" % [c.name_en, str(c.enemies)])
			if c.allies.size() > 0:
				bad("ölü_ülkenin_müttefiki_var", "%s" % c.name_en)
			continue
		for e in c.enemies:
			if e < 0 or e >= nc:
				bad("enemies_geçersiz", c.name_en)
			elif not pairs.has(_pk(c.id, e)):
				bad("olmayan_savaş_enemies", "%s->%s t=%d" % [c.name_en, g.countries[e].name_en, g.turn])
			elif not g.countries[e].alive:
				bad("ölü_düşman", "%s->%s" % [c.name_en, g.countries[e].name_en])
		for al in c.allies:
			if al < 0 or al >= nc:
				bad("müttefik_geçersiz", c.name_en)
			elif not g.countries[al].alive:
				bad("ölü_müttefik", "%s-%s" % [c.name_en, g.countries[al].name_en])
			elif not g.countries[al].allies.has(c.id):
				bad("ittifak_asimetrik", "%s-%s" % [c.name_en, g.countries[al].name_en])
			elif c.enemies.has(al):
				bad("müttefikle_savaş", "%s-%s" % [c.name_en, g.countries[al].name_en])
		if c.enemies.has(c.id):
			bad("kendine_düşman", c.name_en)
		if c.troops < 0:
			bad("asker<0", "%s %d" % [c.name_en, c.troops])
		if int(by_owner.get(c.id, 0)) != c.troops:
			bad("asker≠ordu_toplamı", "%s troops=%d armies=%d t=%d" % [c.name_en, c.troops, int(by_owner.get(c.id, 0)), g.turn])
		if int(cnt.get(c.id, 0)) != c.prov_owned:
			bad("prov_owned_uyumsuz", "%s %d/%d" % [c.name_en, int(cnt.get(c.id, 0)), c.prov_owned])
		if int(cnt.get(c.id, 0)) == 0 and not c.is_rebel:
			bad("eyaletsiz_canlı_ülke", "%s rebel=%s t=%d" % [c.name_en, str(c.is_rebel), g.turn])
		for pid in c.owned_ids:
			if pid < 0 or pid >= np or g.provinces[pid].owner != c.id:
				bad("owned_ids_uyumsuz", "%s pid=%d" % [c.name_en, pid])
				break
		if c.is_rebel:
			if c.prov_held == 0 and c.troops == 0 and g.turn - c.born > 8:
				bad("isyancı_hayalet(held=0,asker=0)", "%s born=%d" % [c.name_en, c.born])
		elif c.capital < 0 or c.capital >= np:
			bad("canlı_ülke_başkentsiz", "%s rebel=%s" % [c.name_en, str(c.is_rebel)])
		elif g.provinces[c.capital].owner != c.id:
			bad("başkent_sahibi_değil" + ("(isyancı)" if c.is_rebel else ""), "%s cap=%s owner=%d t=%d" % [c.name_en, g.provinces[c.capital].name, g.provinces[c.capital].owner, g.turn])
		if c.stability < -0.01 or c.stability > 100.01:
			bad("istikrar_aralık", "%s %.1f" % [c.name_en, c.stability])
		if c.gold < -1.0e7:
			bad("altın_çok_negatif", "%s %.0f" % [c.name_en, c.gold])
		if deep:
			for k in _fprops():
				var v: float = c.get(k)
				if is_nan(v) or is_inf(v):
					bad("NaN/inf_" + k, "%s t=%d" % [c.name_en, g.turn])
		else:
			if not is_finite(c.gold) or not is_finite(c.income) or not is_finite(c.stability):
				bad("NaN/inf_temel", c.name_en)
	if not is_finite(g.infamy):
		bad("NaN_infamy")
	for v in g.vassals:
		if v < 0 or v >= nc or not g.countries[v].alive:
			bad("vasal_ölü/geçersiz", str(v))
		else:
			var l: int = int(g.vassals[v].lord)
			if l < 0 or l >= nc or not g.countries[l].alive:
				bad("vasal_lordu_ölü", "%s lord=%d" % [g.countries[v].name_en, l])
	for b in g.blocs:
		for m in b.get("members", []):
			if m < 0 or m >= nc or not g.countries[m].alive:
				bad("blok_ölü_üye", "%s m=%s" % [str(b.get("name", "")), str(m)])
	if g.player < 0 or g.player >= nc:
		bad("oyuncu_indeks_geçersiz")
	# haber metni
	if g.turn % 10 == 0:
		for n in g.news_log.slice(maxi(0, g.news_log.size() - 30)):
			var tx: String = String(n.get("text", ""))
			if tx == "" or tx.contains("%s") or tx.contains("%d") or tx.contains("<null>") or tx.contains("null ") or tx.contains("{}"):
				bad("haber_metni_bozuk", tx.substr(0, 70))


# ===================================================================== oynanış ölçümleri

func _metrics(g) -> void:
	# savaş çiftleri
	var cur := {}
	var nonrebel_wars := 0
	for w in g.wars:
		cur[_pk(w.a, w.b)] = true
		if not (g.countries[w.a].is_rebel or g.countries[w.b].is_rebel):
			nonrebel_wars += 1
	for k in cur:
		if not prev_pairs.has(k):
			var ab: PackedStringArray = k.split("|")
			var x := int(ab[0])
			var y := int(ab[1])
			if g.countries[x].is_rebel or g.countries[y].is_rebel:
				continue
			if x == g.player or y == g.player:
				ai_on_player += 1 if _last_decl_by_ai(g, x, y) else 0
			else:
				ai_new_wars += 1
	prev_pairs = cur
	if nonrebel_wars > 0:
		war_turns += 1
		if first_war_turn < 0:
			first_war_turn = g.turn
		peace_streak = 0
	else:
		if peace_streak == 0:
			peace_streak_start = g.turn
		peace_streak += 1
		if peace_streak > max_peace_streak:
			max_peace_streak = peace_streak
	var pl = g.countries[g.player]
	if pl.alive:
		player_min = mini(player_min, pl.prov_owned)
		player_max = maxi(player_max, pl.prov_owned)
	if g.turn % 10 == 0:
		var tot := 0
		var best = null
		for c in g.countries:
			if c.alive and not c.is_rebel:
				tot += c.prov_owned
				if best == null or c.prov_owned > best.prov_owned:
					best = c
		if best != null and tot > 0:
			var sh: float = float(best.prov_owned) / float(tot)
			if sh > maxshare:
				maxshare = sh
				maxshare_name = best.name_en
				maxshare_turn = g.turn
			if g.turn % 50 == 0:
				share_series.append("%d:%s=%d%%" % [g.turn, best.name_en, int(sh * 100)])


var _decl_log: Array = []

func _last_decl_by_ai(_g, x: int, y: int) -> bool:
	# oyuncunun bu tur ilan ettiği savaşları _decl_log'a yazıyoruz (turn,target)
	var other: int = y if x == gs.player else x
	for d in _decl_log:
		if d[0] == gs.turn - 1 or d[0] == gs.turn:
			if d[1] == other:
				return false
	return true


# ===================================================================== eylemler

func _declare(need: float, allow_sea: bool = true) -> bool:
	var me = gs.countries[gs.player]
	var cands: Array = gs.neighbor_countries(gs.player)
	if allow_sea:
		for s in gs.sea_neighbor_countries(gs.player):
			if not cands.has(s):
				cands.append(s)
	var best := -1
	var bs := 1.0e18
	var mine: float = me.troops
	for al in me.allies:
		mine += gs.countries[al].troops * 0.4
	for o in cands:
		var oc = gs.countries[o]
		if not oc.alive or oc.is_rebel or gs.at_war(gs.player, o) or gs.is_allied(gs.player, o):
			continue
		if int(me.truce.get(o, -1)) > gs.turn:
			continue
		if mine < oc.troops * need:
			continue
		if oc.troops < bs:
			bs = oc.troops
			best = o
	if best < 0:
		return false
	var r: String = gs.player_declare_war(best)
	if r == "":
		player_decl += 1
		_decl_log.append([gs.turn, best])
		note_act("savaş_ilan")
		return true
	note_err("declare", r)
	return false


func _frontier_targets() -> Array:
	var out: Array = []
	var seen := {}
	for e in gs.countries[gs.player].enemies:
		var ec = gs.countries[e]
		for pid in ec.owned_ids:
			var p = gs.provinces[pid]
			var adj := false
			for nb in p.neighbors:
				if gs.provinces[nb].controller == gs.player:
					adj = true
					break
			if not adj and p.coastal:
				for sl in p.sea_links:
					if gs.provinces[sl].controller == gs.player and gs.armies.get(sl) != null and gs.armies[sl].owner == gs.player:
						adj = true
						break
			if adj and not seen.has(pid):
				seen[pid] = true
				out.append(pid)
	# başka biri tarafından işgal edilmiş (kontrolcü düşman) kendi eyaletlerimiz
	for pid2 in gs.countries[gs.player].owned_ids:
		var p2 = gs.provinces[pid2]
		if p2.controller != gs.player and p2.controller >= 0 and gs.at_war(gs.player, p2.controller) and not seen.has(pid2):
			seen[pid2] = true
			out.append(pid2)
	return out


func _launch_assaults(max_n: int) -> void:
	var tg: Array = _frontier_targets()
	if tg.is_empty():
		return
	tg.shuffle()
	var done := 0
	for pid in tg:
		if done >= max_n:
			break
		var near: Array = gs.armies_near(pid, 5)
		var ids: Array = []
		var has_sea := false
		for e in near:
			ids.append(e.army.id)
			if e.get("sea", false):
				has_sea = true
		if ids.is_empty():
			continue
		var op: String = "assault"
		var r := rng.randf()
		if r < 0.45:
			op = "assault"
		else:
			var pool: Array = ["barrage", "night", "siege", "armor", "air", "naval", "missile", "paradrop", "special", "cyber", "encircle", "blitz", "deception", "landing"]
			var cand: String = pool[rng.randi() % pool.size()]
			if GS.OPS.has(cand):
				op = cand
		if has_sea and rng.randf() < 0.7:
			op = "landing"
		var frac: float = [1.0, 1.0, 0.6, 0.35][rng.randi() % 4]
		var res: Dictionary = gs.player_launch_assault(pid, ids, op, frac)
		if has_sea:
			land_try += 1
		if res.err != "":
			note_err("assault/" + op, res.err)
			if op != "assault":
				res = gs.player_launch_assault(pid, ids, "assault", 1.0)
		if res.err == "":
			note_act("taarruz/" + op)
			done += 1
			if has_sea:
				land_ok += 1
		else:
			note_err("assault", res.err)


func _eco(me, peace_gap: int) -> void:
	var at_war: bool = not me.enemies.is_empty()
	var big := 0
	for e in me.enemies:
		big = maxi(big, gs.countries[e].troops)
	var want := "peace"
	if at_war:
		want = "war"
	elif strat == "conquer" or strat == "weapons":
		want = "hawk"
	elif me.capacity < 0.22:
		want = "poor"
	if gs.turn % 4 == 0:
		var preset: Dictionary = Macro.PRESETS[want]
		if JSON.stringify(me.budget) != JSON.stringify(preset):
			me.budget = preset.duplicate()
	if at_war:
		if big > me.troops * 0.5 and not Macro.mob_active(me) and me.mob_cd <= gs.turn and me.gold > Macro.mob_cost(me) * 1.3:
			var e0: String = Macro.mobilize(gs, me)
			if e0 == "":
				note_act("seferberlik")
			else:
				note_err("mobilize", e0)
		if gs.turn % 5 == 0:
			gs.player_request_aid_all()
			note_act("yardım_iste")
		if peace_gap > 0 and gs.turn % peace_gap == 0:
			for e in me.enemies.duplicate():
				if gs.countries[e].is_rebel:
					continue
				var r: Dictionary = gs.player_request_peace(e)
				if r.get("ok", false):
					if r.get("mode", "") == "player_wins":
						var w = r["war"]
						gs.finish_peace(w, gs.player, gs._ai_choose_annex(w, gs.player))
						note_act("barış_kazanan")
					else:
						note_act("barış_diğer")
	elif gs.turn % 5 == 0 and me.gold > me.income * 6.0:
		bot._build(me)
	if gs.turn % 3 == 0:
		bot._focus()
	bot._cabinet_turn()


func _merc(me) -> void:
	if me.owned_ids.is_empty():
		return
	var tier: int = rng.randi() % 3
	var r: Dictionary = gs.hire_merc(gs.player, tier)
	if r.err == "":
		note_act("paralı/%d" % tier)
	else:
		note_err("merc", r.err)


func _weapons(me) -> void:
	if me.enemies.is_empty():
		return
	# en büyük düşman ordusunun bulunduğu eyalet
	var best_pid := -1
	var best_sz := 0
	for a in gs.armies.values():
		if me.enemies.has(a.owner) and a.size > best_sz:
			best_sz = a.size
			best_pid = a.prov
	if best_pid < 0:
		return
	if gs.player_has_gas():
		var pf: Array = gs.gas_platforms()
		var r: String = gs.player_gas(best_pid, pf[rng.randi() % pf.size()])
		if r == "":
			note_act("gaz")
		else:
			note_err("gas", r)
	if gs.player_has_nukes() and rng.randf() < 0.6:
		var plats: Array = gs.nuke_platforms(best_pid)
		var r2: String = gs.player_nuke(best_pid, plats[rng.randi() % plats.size()])
		if r2 == "":
			note_act("nükleer")
		else:
			note_err("nuke", r2)
	else:
		# nükleer yoksa da API'yi çağır (hata dönmeli, çökmemeli)
		var r3: String = gs.player_nuke(best_pid)
		if r3 != "":
			note_err("nuke", r3)


func _diplo_basic(me) -> void:
	var nbs: Array = gs.neighbor_countries(gs.player)
	nbs.shuffle()
	var tried := 0
	for o in nbs:
		var oc = gs.countries[o]
		if not oc.alive or oc.is_rebel or gs.at_war(gs.player, o):
			continue
		tried += 1
		if tried > 3:
			break
		if not gs.is_allied(gs.player, o) and me.allies.size() < 4:
			var r: String = gs.player_propose_alliance(o)
			if r == "":
				note_act("ittifak")
			else:
				note_err("alliance", r)
		var kinds: Array = ["envoy", "gift", "pact"]
		var r2: String = gs.player_improve_relations(o, kinds[rng.randi() % 3])
		if r2 == "":
			note_act("ilişki")
		else:
			note_err("relations", r2)


func _un_play(me) -> void:
	if not UN.available(gs):
		return
	var k: String = UN.ORDER[rng.randi() % UN.ORDER.size()]
	var tg: Array = UN.targets(gs, k)
	if tg.is_empty():
		return
	var t: int = tg[rng.randi() % mini(tg.size(), 6)]
	var r: Dictionary = UN.propose(gs, k, gs.player, t)
	if r.ok:
		note_act("bm/" + k + ("+" if r.passed else "-"))
	else:
		note_err("un/" + k, String(r.text))


func _bloc_play(me) -> void:
	if me.alliance < 0 and gs.turn >= 2:
		var r: String = gs.player_found_bloc("Test Bloğu", {"shape": 1, "inner": 1, "symbol": "star", "c1": "2f4f9a", "c2": "ece6d6", "c3": "2f4f9a"})
		if r == "":
			note_act("blok_kur")
		else:
			note_err("found_bloc", r)
	if me.alliance >= 0:
		var all_c: Array = []
		for c in gs.countries:
			if c.alive and not c.is_rebel and c.id != gs.player and not gs.at_war(gs.player, c.id):
				all_c.append(c.id)
		all_c.shuffle()
		for i in mini(4, all_c.size()):
			var r2: String = gs.player_invite(all_c[i])
			if r2 == "":
				note_act("davet_kabul")
			else:
				note_err("invite", r2)
	if gs.turn % 9 == 0:
		var nb: Array = gs.neighbor_countries(gs.player)
		if not nb.is_empty():
			var o: int = nb[rng.randi() % nb.size()]
			var r3: String = gs.player_request_passage(o)
			if r3 == "":
				note_act("geçiş_izni")
			else:
				note_err("passage", r3)
			for uk in ["passage", "tribute", "land"]:
				if Ult.available(gs, uk, o):
					var d: Dictionary = Ult.deliver(gs, uk, o)
					note_act("ültimatom/" + uk)
					break
	if gs.turn % 11 == 0:
		var nb2: Array = gs.neighbor_countries(gs.player)
		if not nb2.is_empty():
			var o2: int = nb2[rng.randi() % nb2.size()]
			var ck: String = ["spy", "prop", "sab", "emb"][rng.randi() % 4]
			var cr: Dictionary = gs.player_covert(o2, ck)
			note_act("gizli/" + ck + ("+" if cr.ok else "-"))
	for v in gs.vassals.keys():
		if gs.vassals[v].lord == gs.player:
			var ar: String = gs.player_annex_vassal(v) if rng.randf() < 0.5 else gs.player_release_vassal(v)
			note_act("vasal")


func _econ_play(me) -> void:
	# silah alımı: rastgele satın alınabilir kalem
	if gs.turn % 3 == 0:
		var ids: Array = Arsenal.ITEMS.keys()
		for i in 4:
			var id: String = ids[rng.randi() % ids.size()]
			var e: String = Macro.buy(gs, me, id, [1, 5, 20][rng.randi() % 3])
			if e == "":
				note_act("silah_al")
			else:
				note_err("buy", e)
	if gs.turn % 7 == 0:
		var keys: Array = Macro.BUDGET_KEYS
		Macro.set_budget(me, keys[rng.randi() % keys.size()], rng.randi_range(0, 70))
		var sum := 0
		for k in Macro.BUDGET_KEYS:
			sum += int(me.budget[k])
		if sum != 100:
			bad("bütçe_toplamı≠100", "%d %s" % [sum, str(me.budget)])
	if gs.turn % 26 == 0:
		var dr: String = Macro.set_doctrine(gs, me, rng.randi() % 3)
		if dr != "":
			note_err("doctrine", dr)
	if gs.turn % 8 == 0:
		for bk in ["farm", "mine", "oil", "press"]:
			gs.player_bulk("build", bk)
		gs.player_bulk("assimilate")
		gs.player_bulk("faith")
	if gs.turn % 20 == 0:
		gs.player_set_propaganda(["", "oral", "press", "poster"][rng.randi() % 4])
	if gs.turn % 15 == 0:
		for f in Formables.available(gs):
			var fr: String = Formables.form(gs, f)
			note_act("formable" + ("+" if fr == "" else "-"))
	if gs.turn % 30 == 0:
		var cands: Array = []
		for pid in me.owned_ids:
			cands.append(pid)
		if not cands.is_empty():
			var pp: int = cands[rng.randi() % cands.size()]
			gs.player_build(pp, ["farm", "mine", "oil", "press"][rng.randi() % 4])


func _fuzz(me) -> void:
	var n := 3
	for i in n:
		match rng.randi() % 14:
			0:
				_declare(0.5)
			1:
				_launch_assaults(2)
			2:
				_weapons(me)
			3:
				_merc(me)
			4:
				_diplo_basic(me)
			5:
				_un_play(me)
			6:
				_econ_play(me)
			7:
				# elle emirler
				var mine: Array = gs.armies_of(gs.player)
				if not mine.is_empty():
					var a = mine[rng.randi() % mine.size()]
					var tgt: int = rng.randi() % gs.provinces.size()
					var cnt: int = [0, 0, a.size / 2, a.size / 3][rng.randi() % 4]
					var r: String = gs.player_order_move(a, tgt, cnt)
					if r == "":
						note_act("emir")
					else:
						note_err("order", r)
					if rng.randf() < 0.2:
						gs.player_cancel_move(a)
			8:
				_bloc_play(me)
			9:
				if rng.randf() < 0.3 and not me.enemies.is_empty():
					var e: int = me.enemies[rng.randi() % me.enemies.size()]
					var r2: String = gs.player_surrender(e)
					note_act("teslim")
					if r2 != "":
						note_err("surrender", r2)
			10:
				var oid: int = rng.randi() % gs.countries.size()
				if gs.countries[oid].alive and oid != gs.player:
					var r3: String = gs.player_break_alliance(oid)
					var r4: String = gs.player_spy(oid)
					if r4 != "":
						note_err("spy", r4)
			11:
				gs.player_request_aid_all()
				for al in me.allies:
					gs.player_aid_gold(al)
			12:
				if gs.turn % 2 == 0:
					Macro.mobilize(gs, me)
			13:
				var ids2: Array = gs.armies_of(gs.player).map(func(x): return x.id)
				if not ids2.is_empty() and not me.enemies.is_empty():
					# rastgele (geçersiz olabilen) eyalete taarruz
					var pid3: int = rng.randi() % gs.provinces.size()
					var rr: Dictionary = gs.player_launch_assault(pid3, ids2, GS.OPS.keys()[rng.randi() % GS.OPS.size()], 0.5)
					if rr.err != "":
						note_err("fuzz_assault", rr.err)
					else:
						note_act("fuzz_taarruz")


func _act() -> void:
	var me = gs.countries[gs.player]
	match strat:
		"conquer":
			_eco(me, 6)
			var nw := 0
			for e in me.enemies:
				if not gs.countries[e].is_rebel:
					nw += 1
			if nw < 2 and gs.turn % 3 == 0:
				_declare(0.7)
			_launch_assaults(3)
			if gs.turn % 10 == 0 and not me.enemies.is_empty() and me.gold > me.income * 8.0:
				_merc(me)
		"weapons":
			_eco(me, 9)
			var nw2 := 0
			for e in me.enemies:
				if not gs.countries[e].is_rebel:
					nw2 += 1
			if nw2 < 2 and gs.turn % 3 == 0:
				_declare(0.6)
			_launch_assaults(3)
			_weapons(me)
			if gs.turn % 6 == 0 and not me.enemies.is_empty():
				_merc(me)
		"turtle":
			_eco(me, 3)
			if gs.turn % 6 == 0:
				_diplo_basic(me)
			if gs.turn % 8 == 0 and not gs.wars.is_empty():
				if UN.available(gs):
					var tg: Array = UN.targets(gs, "ceasefire")
					if not tg.is_empty():
						var r: Dictionary = UN.propose(gs, "ceasefire", gs.player, tg[0])
						if r.ok:
							note_act("bm/ceasefire" + ("+" if r.passed else "-"))
			if not me.enemies.is_empty() and me.troops < 1.0e9 and gs.turn % 9 == 0 and me.gold > me.income * 6.0:
				_merc(me)
		"bloc":
			_eco(me, 4)
			_bloc_play(me)
			if gs.turn % 2 == 0:
				_un_play(me)
			if gs.turn % 7 == 0:
				_diplo_basic(me)
		"econ":
			_eco(me, 4)
			_econ_play(me)
			if gs.turn % 12 == 0:
				_diplo_basic(me)
		"fuzz":
			_eco(me, 5)
			_fuzz(me)
		_:
			bot.act()


# ===================================================================== rapor

func _report(ms: int, load_note: String, turns: int) -> void:
	var pl = gs.countries[gs.player]
	var sorted: Array = tms.duplicate()
	sorted.sort()
	var avg := 0.0
	for x in tms:
		avg += x
	avg /= maxf(1.0, tms.size())
	var p95: float = sorted[int(sorted.size() * 0.95)] if sorted.size() > 0 else 0.0
	var mx: float = sorted[sorted.size() - 1] if sorted.size() > 0 else 0.0
	var top: Array = []
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			top.append(c)
	top.sort_custom(func(a, b): return a.prov_owned > b.prov_owned)
	var ts := ""
	for i in mini(3, top.size()):
		ts += "%s:%d " % [top[i].name_en, top[i].prov_owned]
	var tot_prov := 0
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			tot_prov += c.prov_owned
	var ai_dec := 0
	var reb := 0
	for c in gs.countries:
		if c.alive and c.is_rebel:
			reb += 1
	print("RESULT %s/%s/%s seed→tur=%d/%d %ds | oyuncu %s: eyalet %d→%d (min %d max %d) ölüm=%d asker=%dk | savaş_turu=%d/%d en_uzun_barış=%d (t%d) ilk_savaş=t%d | YZ_yeni_savaş=%d YZ→oyuncu=%d oyuncu_ilan=%d | yaşayan=%d isyancı=%d | tepe_pay=%d%% %s@t%d | son: %s | tur_süresi avg=%.0f p95=%.0f max=%.0f ms | kayıt/yükle: %s | %s" % [
		era_id, pname, strat, gs.turn, turns, ms / 1000, pl.name_en, player_prov0, pl.prov_owned, player_min, player_max, died_turn, pl.troops / 1000,
		war_turns, turns, max_peace_streak, peace_streak_start, first_war_turn, ai_new_wars, ai_on_player, player_decl, gs.alive_count(), reb,
		int(maxshare * 100), maxshare_name, maxshare_turn, ts, avg, p95, mx, load_note, over_text.substr(0, 60)])
	print("   PAY: ", ", ".join(share_series))
	print("   EYLEM: ", JSON.stringify(alog), " çıkarma ", land_ok, "/", land_try)
	var ek := errlog.keys()
	ek.sort_custom(func(a, b): return errlog[a] > errlog[b])
	var es := ""
	for i in mini(8, ek.size()):
		es += "%s ×%d; " % [ek[i], errlog[ek[i]]]
	print("   RED: ", es)
	if not slow_turns.is_empty():
		print("   YAVAŞ_TUR: ", " ".join(slow_turns.slice(0, 12)), " (toplam ", slow_turns.size(), ")")
	for k in info:
		print("   INFO ", k, " ×", info[k], " ", base_bad.get("yab", ""))
	for k in issues:
		print("ISSUE [%s/%s/%s] %s ×%d ilk_tur=%d örnek: %s" % [era_id, pname, strat, k, issues[k].n, issues[k].t, issues[k].ex])
