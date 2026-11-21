extends SceneTree
## 45 bot arena: online odalar (sunucu + istemci kopyaları, komut kaydı) ve aynı-telefon (hotseat) oyunlar.
## Kullanım: godot --headless --path . -s tools/arena.gd -- --mode online|multi --games 3 --seats 5 --rounds 12 --seed 1 [--era ww2] [--scn ukr]
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Cmd = preload("res://scripts/cmd.gd")
const Mp = preload("res://scripts/mp.gd")
const Eras = preload("res://scripts/eras.gd")
const Scenarios = preload("res://scripts/scenarios.gd")
const Fuzz = preload("res://tools/arena_fuzz.gd")

var errors: Array = []
var total_actions := {}
var rounds_done := 0
var t_round := 0.0


func _arg(name: String, def: String) -> String:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--" + name and i + 1 < a.size():
			return a[i + 1]
	return def


func bug(ctx: String, msg: String) -> void:
	if errors.size() < 60:
		print("  BUG [", ctx, "] ", msg)
	errors.append(ctx + ": " + msg)


func _world(seed_val: int, seats: int, era: String, scn: String) -> Array:
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(seed_val)
	if era != "":
		Eras.restructure(g, era)
	# koltuklar: güçlü/rastgele ülkeler
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var ids: Array = []
	var guard := 0
	while ids.size() < seats and guard < 1000:
		guard += 1
		var c = g.countries[rng.randi_range(0, g.countries.size() - 1)]
		if c.alive and not c.is_rebel and c.held_ids.size() + c.owned_ids.size() > 0 and not ids.has(c.id):
			ids.append(c.id)
	if ids.size() < seats:
		for c in g.countries:
			if ids.size() >= seats: break
			if c.alive and not c.is_rebel and not ids.has(c.id):
				ids.append(c.id)
	g.start_game(ids[0])
	if era != "":
		Eras.start(g, era)
	if scn != "" and not Scenarios.get_sc(scn).is_empty():
		Scenarios.apply(g, scn)
	g.scn_play = -1
	return [g, ids]


func _sane(g, ctx: String) -> void:
	for c in g.countries:
		if is_nan(c.gold) or is_inf(c.gold):
			bug(ctx, "altın NaN: %s" % c.name)
		if c.alive and (is_nan(float(c.troops)) or c.troops < 0):
			bug(ctx, "asker bozuk: %s %s" % [c.name, str(c.troops)])
	for a in g.armies.values():
		if a.size < 0 or a.prov < 0 or a.prov >= g.provinces.size():
			bug(ctx, "ordu bozuk id=%s size=%s prov=%s" % [str(a.id), str(a.size), str(a.prov)])
	for p in g.provinces:
		if p.owner >= g.countries.size() or p.controller >= g.countries.size():
			bug(ctx, "il sahibi geçersiz %s" % p.name)
	for o in g.offers:
		if not g.countries[int(o.to)].alive and false:
			pass


func _roundtrip(g, ctx: String) -> void:
	var d: Dictionary = g.to_dict()
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	var d2 = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	var h = GS.new()
	h.new_world(int(d2.get("seed", 0)))
	if not h.from_dict(d2):
		bug(ctx, "from_dict başarısız")
		return
	if h.turn != g.turn or h.countries.size() != g.countries.size():
		bug(ctx, "roundtrip tur/ülke farkı")
	var d3: Dictionary = h.to_dict()
	for k in ["turn", "humans", "wars"]:
		if d.has(k) and str(d[k]) != str(d3.get(k)):
			bug(ctx, "roundtrip '%s' farklı" % k)
	if raw.size() > 3000000:
		bug(ctx, "durum çok büyük: %d bayt" % raw.size())


func _news_check(g, ctx: String, from: int) -> void:
	for i in range(from, g.news_log.size()):
		var n = g.news_log[i]
		if n.has("for"):
			continue
		var t: String = str(n.text)
		if t.find("açtın") >= 0 or t.find("ilan ettin") >= 0 or t.find("Cihan senden") >= 0:
			bug(ctx, "ortak haberde kişisel dil: %s" % t)


# ------------------------------------------------------------- online
func _client_copy(server_gs, cid: int):
	var d: Dictionary = server_gs.to_dict()
	d["armies"] = server_gs.fog_filter_armies(d["armies"], cid, 1)
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	var d2 = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	var g = GS.new()
	g.new_world(int(d2.get("seed", 0)))
	if not g.from_dict(d2):
		bug("istemci", "from_dict")
	g.net_humans = g.humans.duplicate()
	g.humans = []
	g.switch_player(cid)
	g.cmd_log = []
	g.cmd_depth = 0
	Cmd.rec_gs = g
	return g


func run_online(gi: int, seats: int, rounds: int, seed_val: int, era: String, scn: String) -> void:
	var ctx := "online#%d" % gi
	var w: Array = _world(seed_val, seats, era, scn)
	var g = w[0]
	var ids: Array = w[1]
	var room = Room.new()
	room.rng.seed = seed_val
	room.setup(g, ids)
	var fz: Array = []
	for i in seats:
		fz.append(Fuzz.new(seed_val * 31 + i))
	var chaos := RandomNumberGenerator.new()
	chaos.seed = seed_val + 7
	for r in rounds:
		var t_start := Time.get_ticks_msec()
		var turn0: int = g.turn
		var news0: int = g.news_log.size()
		var copies: Array = []
		for i in seats:
			var cid: int = ids[i]
			if not g.countries[cid].alive:
				continue
			var cp = _client_copy(g, cid)
			copies.append(cp)
			var mode: float = chaos.randf()
			if mode < 0.10:
				room.set_afk(cid, true)       # bu tur AFK: yapay zekâ oynar
				continue
			room.set_afk(cid, false)
			fz[i].act(cp, cid, chaos.randi_range(2, 14), ids)
			if mode < 0.14:
				# bozuk/saldırgan gönderim: rastgele ad ve argümanlar
				var junk: Array = [{"n": "yok_komut", "a": []}, {"n": "player_declare_war", "a": [99999]}, {"n": "player_declare_war", "a": [-3]},
					{"n": "Zzz.x", "a": [1]}, {"n": "", "a": null}, {"n": "end_turn", "a": []}, {"n": "player_build", "a": ["x", 5]},
					{"n": "player_order_move", "a": [{"$a": 424242}, 3, 1]}, {"n": "player_propose_alliance", "a": []}, {"n": "Macro.set_budget", "a": [{"$c": 9999}, "army", 5]},
					{"n": "Fleets.order_move", "a": [{"x": 1}, 7]}, {"n": "player_sign_trade", "a": [1.5]}, {"n": "respond_offer", "a": [-1, true]}]
				junk.shuffle()
				room.submit(cid, cp.cmd_log + junk)
			else:
				room.submit(cid, cp.cmd_log)
			room.set_ready(cid, true)
		# bazı oyuncular hiç hazır olmasa da süre dolunca tur işlenir
		var res: Dictionary = room.process_round()
		if g.turn != turn0 + 1:
			bug(ctx, "tur ilerlemedi %d -> %d" % [turn0, g.turn])
		if g.player != -1:
			bug(ctx, "sunucuda player=%d" % g.player)
		_sane(g, ctx)
		_news_check(g, ctx, news0)
		if r % 4 == 3:
			_roundtrip(g, ctx)
		for i in seats:
			for k in fz[i].count:
				total_actions[k] = int(total_actions.get(k, 0)) + int(fz[i].count[k])
			fz[i].count = {}
		rounds_done += 1
		t_round += (Time.get_ticks_msec() - t_start) / 1000.0
		if String(res.get("over", "")) != "":
			print("  [", ctx, "] bitti: ", res.over)
			break
		Cmd.rec_gs = null


# ------------------------------------------------------------- hotseat
func run_multi(gi: int, seats: int, rounds: int, seed_val: int, era: String, scn: String) -> void:
	var ctx := "multi#%d" % gi
	var w: Array = _world(seed_val, seats, era, scn)
	var g = w[0]
	var ids: Array = w[1]
	Mp.begin(g, ids)
	var fz: Array = []
	for i in seats:
		fz.append(Fuzz.new(seed_val * 17 + i))
	var chaos := RandomNumberGenerator.new()
	chaos.seed = seed_val + 3
	for r in rounds:
		var t_start := Time.get_ticks_msec()
		var turn0: int = g.turn
		var news0: int = g.news_log.size()
		var guard := 0
		while true:
			guard += 1
			if guard > 20:
				bug(ctx, "koltuk döngüsü bitmiyor")
				return
			var cid: int = g.player
			var idx: int = ids.find(cid)
			if idx < 0:
				bug(ctx, "sırası gelen oyuncu insan değil: %d" % cid)
				return
			fz[idx].act(g, cid, chaos.randi_range(2, 14), ids)
			var rs: Dictionary = Mp.finish_seat(g)
			if rs.round_done:
				break
		Mp.prepare_round(g)
		g.end_turn()
		if g.turn != turn0 + 1:
			bug(ctx, "tur ilerlemedi %d -> %d" % [turn0, g.turn])
		var endtxt: String = Mp.check_end(g)
		if Mp.begin_round(g) < 0:
			print("  [", ctx, "] tüm insanlar yok oldu")
			break
		_sane(g, ctx)
		_news_check(g, ctx, news0)
		# kaydet/yükle: oyun ortasında sağlam mı
		if r % 3 == 2:
			var d: Dictionary = g.to_dict()
			var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
			var d2 = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
			var h = GS.new()
			h.new_world(int(d2.get("seed", 0)))
			if not h.from_dict(d2):
				bug(ctx, "yükleme başarısız")
			else:
				if h.humans != g.humans or h.hs_i != g.hs_i or h.player != g.player:
					bug(ctx, "yüklemede koltuk bozuldu: humans %s/%s hs_i %d/%d player %d/%d" % [str(h.humans), str(g.humans), h.hs_i, g.hs_i, h.player, g.player])
				g = h
		for i in seats:
			for k in fz[i].count:
				total_actions[k] = int(total_actions.get(k, 0)) + int(fz[i].count[k])
			fz[i].count = {}
		rounds_done += 1
		t_round += (Time.get_ticks_msec() - t_start) / 1000.0
		if endtxt != "":
			print("  [", ctx, "] bitti: ", endtxt)
			break


func _init() -> void:
	var mode := _arg("mode", "online")
	var games := int(_arg("games", "3"))
	var seats := int(_arg("seats", "5"))
	var rounds := int(_arg("rounds", "12"))
	var seed0 := int(_arg("seed", "1"))
	var era := _arg("era", "")
	var scn := _arg("scn", "")
	print("ARENA mod=", mode, " oyun=", games, " koltuk=", seats, " tur=", rounds, " dönem=", era, " senaryo=", scn)
	for gi in games:
		var sv := seed0 * 100 + gi
		# sonuncu oyunlarda dönem/senaryo çeşitliliği
		var e := era
		var s := scn
		if era == "" and scn == "" and gi % 3 == 1:
			e = "ww2"
		elif era == "" and scn == "" and gi % 3 == 2:
			s = "ukr"
		if mode == "online":
			run_online(gi, seats, rounds, sv, e, s)
		else:
			run_multi(gi, seats, rounds, sv, e, s)
	var acts := 0
	for k in total_actions:
		acts += int(total_actions[k])
	print("ARENA_BİTTİ tur=", rounds_done, " eylem=", acts, " sn/tur=", snappedf(t_round / maxf(1.0, rounds_done), 0.01), " bug=", errors.size())
	print("EYLEMLER ", total_actions)
	quit()
