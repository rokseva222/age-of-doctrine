extends SceneTree
## kullanım: godot --headless --path . -s tools/full_play.gd -- <tür:free|scn|era> <id> <oyuncu_sırası> <tur>
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const SC = preload("res://scripts/scenarios.gd")
const Obj = preload("res://scripts/objectives.gd")
const Names = preload("res://scripts/names.gd")
var issues: Dictionary = {}
var last_snap := ""
func bad(k: String) -> void:
	issues[k] = int(issues.get(k, 0)) + 1
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var kind: String = a[0]; var id: String = a[1]; var pi: int = int(a[2]); var turns: int = int(a[3])
	var sug: Array = []
	if kind == "era":
		Eras.prepare(id)
		sug = Eras.get_era(id).get("suggest", [])
	elif kind == "scn":
		sug = SC.get_sc(id).get("suggest", [])
	var gs = GS.new()
	gs.new_world(4242 + pi)
	if kind == "era":
		Eras.restructure(gs, id)
	var nm: String = sug[pi % sug.size()] if not sug.is_empty() else "Turkey"
	var me: int = int(gs.macro_idx.get(nm, 0))
	var oc := {"t": ""}
	gs.game_over.connect(func(v, t): oc.t = ("ZAFER: " if v else "YENİLGİ: ") + t)
	gs.start_game(me)
	if kind == "era":
		Eras.start(gs, id)
	elif kind == "scn":
		SC.apply(gs, id)
	var pl = gs.countries[gs.player]
	pl.auto_cmd = true
	var t0 := Time.get_ticks_msec()
	var w0: int = gs.wars.size()
	var minprov: int = pl.prov_owned
	var maxprov: int = pl.prov_owned
	var prov0: int = pl.prov_owned
	var died := -1
	for t in turns:
		if t == 4 and pl.alive:
			# oyuncu bir komşuya savaş açar
			var nbs: Array = gs.neighbor_countries(gs.player)
			var bestn := -1
			for n in nbs:
				var cn = gs.countries[n]
				if cn.alive and not cn.is_rebel and not gs.at_war(gs.player, n) and not gs.is_allied(n, gs.player) and int(pl.truce.get(n, -1)) <= gs.turn:
					if bestn < 0 or cn.troops < gs.countries[bestn].troops:
						bestn = n
			if bestn >= 0:
				gs.declare_war(gs.player, bestn)
		gs.end_turn()
		if not pl.alive:
			if died < 0: died = t
			if oc.t != "" or t > died + 3: break
		minprov = mini(minprov, pl.prov_owned); maxprov = maxi(maxprov, pl.prov_owned)
		if t % 4 == 0:
			_check(gs)
	var ms: int = Time.get_ticks_msec() - t0
	# kayıt-yükleme
	var p := "user://fp_%s.dat" % id
	var ok_save: bool = gs.save_to(p)
	var g2 = GS.new()
	var ok_load: bool = g2.load_from(p)
	if not (ok_save and ok_load):
		bad("kayıt/yükleme başarısız")
	elif g2.turn != gs.turn or g2.player != gs.player or g2.countries[g2.player].prov_owned != gs.countries[gs.player].prov_owned:
		bad("yükleme sonrası durum farklı")
	else:
		for i in 6:
			g2.end_turn()
		_check(g2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var objs := ""
	if Obj.active(gs):
		var done := 0
		var lst: Array = Obj.list(gs)
		for o in lst:
			if Obj.is_done(gs, o): done += 1
		objs = " hedef=%d/%d" % [done, lst.size()]
	var iss := ""
	for k in issues: iss += "\n      ! %s ×%d" % [k, issues[k]]
	if died >= 0: print("   ÖLÜM ÖNCESİ: ", last_snap)
	print("SONUC %-16s %-24s tur=%3d %5dms/tur=%d | eyalet %d→%d (min %d max %d) savaş %d→%d ölüm=%d%s | %s%s" % [id, nm, gs.turn, ms, ms / maxi(gs.turn, 1), prov0, pl.prov_owned, minprov, maxprov, w0, gs.wars.size(), died, objs, String(oc.t).substr(0, 70), iss])
	quit()
func _check(gs) -> void:
	var cnt: Dictionary = {}
	for p in gs.provinces:
		if p.owner >= 0:
			cnt[p.owner] = int(cnt.get(p.owner, 0)) + 1
			if p.owner >= gs.countries.size(): bad("geçersiz sahip")
			elif not gs.countries[p.owner].alive: bad("ölü ülkenin eyaleti")
		if p.controller >= gs.countries.size(): bad("geçersiz kontrolcü")
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			if int(cnt.get(c.id, 0)) != c.prov_owned: bad("prov_owned uyumsuz")
			if int(cnt.get(c.id, 0)) == 0: bad("eyaletsiz canlı ülke")
			if c.capital < 0 or c.capital >= gs.provinces.size() or gs.provinces[c.capital].owner != c.id:
				bad("başkent sahibi değil")
				var cp: int = c.capital
				print("  CAP ", c.name, " cap=", cp, " ", gs.provinces[cp].name if cp >= 0 and cp < gs.provinces.size() else "?", " owner=", gs.provinces[cp].owner if cp >= 0 and cp < gs.provinces.size() else -9, " prov=", c.prov_owned, " turn=", gs.turn, " rebel=", c.is_rebel)
		if not is_finite(c.gold) or not is_finite(c.income) or not is_finite(c.stability): bad("NaN/inf")
		if c.alive and (c.stability < -0.01 or c.stability > 100.01): bad("istikrar aralık dışı")
		if c.troops < 0: bad("negatif asker")
		for al in c.allies:
			if al >= gs.countries.size() or not gs.countries[al].allies.has(c.id): bad("tek taraflı ittifak")
			elif gs.at_war(c.id, al): bad("müttefikle savaş")
		if c.alive:
			for en in c.enemies:
				if not gs.at_war(c.id, en): bad("enemies≠savaş")
	for w in gs.wars:
		if not gs.countries[w.a].alive or not gs.countries[w.b].alive: bad("ölü ülkeyle savaş")
		if w.a == w.b: bad("kendine savaş")
	for n in gs.news_log.slice(maxi(0, gs.news_log.size() - 40)):
		var tx: String = String(n.text)
		if tx == "" or tx.contains("%s") or tx.contains("%d") or tx.contains("null") or tx.contains("<null>") or tx.contains("{"):
			bad("haber metni bozuk: " + tx.substr(0, 60))
