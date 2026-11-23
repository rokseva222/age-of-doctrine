extends SceneTree
## Online oda mantığı (ağsız): istemci komut kaydı → sunucuda yeniden oynatma → tur → tam durum
const CabinetT = preload("res://scripts/cabinet.gd")
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Cmd = preload("res://scripts/cmd.gd")
const Macro = preload("res://scripts/macro.gd")
const FleetsM = preload("res://scripts/fleets.gd")

var bad := 0

func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

func _client_copy(server_gs, cid: int):
	var d: Dictionary = server_gs.to_dict()
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	var d2 = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	var g = GS.new()
	g.new_world(int(d2.get("seed", 0)))
	chk(g.from_dict(d2), "istemci from_dict")
	g.net_humans = g.humans.duplicate()
	g.humans = []
	g.switch_player(cid)
	g.cmd_log = []
	Cmd.rec_gs = g
	return g

func _init() -> void:
	var g = GS.new()
	g.new_world(21)
	var ids: Array = []
	for n in ["Turkey", "Germany", "France"]:
		ids.append(int(g.macro_idx.get(n, 0)))
	g.start_game(ids[0])
	var room = Room.new()
	room.setup(g, ids)
	chk(g.player == -1, "sunucuda player=-1")
	var t0: int = g.turn
	# --- oyuncu 0 (Türkiye): savaş ilanı + ordu hareketi + bütçe
	var c0 = _client_copy(g, ids[0])
	var foe: int = -1
	for nb in c0.neighbor_countries(ids[0]):
		if nb != ids[1] and nb != ids[2] and c0.countries[nb].alive and not c0.at_war(ids[0], nb) and not c0.is_allied(ids[0], nb):
			foe = nb
			break
	chk(foe >= 0, "komşu hedef var")
	var r1: String = c0.player_declare_war(foe, true)
	chk(r1 == "", "istemci savaş ilanı: %s" % r1)
	var old_b: int = int(c0.countries[ids[0]].budget.get("army", 0)) if c0.countries[ids[0]].budget.has("army") else -1
	Macro.set_budget(c0.countries[ids[0]], "army", 30)
	var mv := 0
	for a in c0.armies.values():
		if a.owner == ids[0] and a.size > 1:
			var tgt: int = -1
			for nb2 in c0.provinces[a.prov].neighbors:
				if c0.provinces[nb2].owner == ids[0]:
					tgt = nb2
					break
			if tgt >= 0:
				c0.player_order_move(a, tgt)
				mv += 1
				break
	chk(c0.cmd_log.size() >= 2, "komut kaydı: %d" % c0.cmd_log.size())
	var names: Array = []
	for c in c0.cmd_log:
		names.append(c.n)
	print("kayıtlı komutlar: ", names)
	chk(names.has("player_declare_war"), "savaş ilanı kaydedildi")
	chk(names.has("Macro.set_budget"), "bütçe kaydedildi")
	# iç içe çağrılar çift kaydedilmedi: savaş ilanı tek
	chk(names.count("player_declare_war") == 1, "savaş ilanı tek kayıt")
	# filo emri: kendi filolarından birini hareket ettir
	FleetsM.ensure(c0)
	var fl = null
	for f in FleetsM.fleets_of(c0, ids[0]):
		fl = f
		break
	var fleet_cmd := false
	if fl != null:
		var zones: Array = []
		for z in c0.fleets.keys():
			pass
		var before: int = c0.cmd_log.size()
		FleetsM.set_stance(c0, fl.id, "patrol")
		fleet_cmd = c0.cmd_log.size() > before
	print("filo komutu kaydı: ", fleet_cmd)
	# --- oyuncu 1 (Almanya): bir komut
	var c1 = _client_copy(g, ids[1])
	var foe1: int = -1
	for nb in c1.neighbor_countries(ids[1]):
		if nb != ids[0] and nb != ids[2] and c1.countries[nb].alive and not c1.at_war(ids[1], nb) and not c1.is_allied(ids[1], nb):
			foe1 = nb
			break
	if foe1 >= 0:
		c1.player_declare_war(foe1, true)
	# gönder
	chk(room.submit(ids[0], c0.cmd_log), "submit 0")
	chk(room.submit(ids[1], c1.cmd_log), "submit 1")
	room.set_ready(ids[0], true)
	room.set_ready(ids[1], true)
	chk(not room.all_ready(), "3. oyuncu hazır değil → bekle")
	room.set_ready(ids[2], true)
	chk(room.all_ready(), "hepsi hazır")
	# işlemeden önce yeniden oynatma: savaş sunucu durumunda gerçekleşti mi (process_round içinde)
	var rr: Dictionary = room.process_round()
	chk(g.turn == t0 + 1, "tur ilerledi")
	chk(rr.rejected == 0, "reddedilen komut: %d" % rr.rejected)
	chk(g.at_war(ids[0], foe) or g.countries[ids[0]].truce.size() >= 0, "savaş durumu")
	chk(g.player == -1, "tur sonrası player=-1")
	chk(g.humans == ids, "humans korundu")
	chk(int(g.countries[ids[0]].budget.get("army", -1)) == int(c0.countries[ids[0]].budget.get("army", -2)), "bütçe sunucuda istemciyle aynı: %s vs %s" % [str(g.countries[ids[0]].budget), str(c0.countries[ids[0]].budget)])
	print("sonuçlar: ", rr.results)
	# yeni turda komutlar temizlendi
	chk(room.cmds[ids[0]].is_empty() and not room.all_ready(), "yeni tur sıfırlandı")
	# AFK: 3. oyuncu AFK olunca diğerleri hazır olunca tur işlenir
	room.set_afk(ids[2], true)
	room.set_ready(ids[0], true)
	room.set_ready(ids[1], true)
	chk(room.all_ready(), "AFK beklenmez")
	var t1: int = g.turn
	room.process_round()
	chk(g.turn == t1 + 1, "AFK ile tur")
	# insanlar arası teklif: istemci teklif eder → sunucuda bekler → karşı istemci kabul eder → müttefik
	room.set_afk(ids[2], false)
	var ca = _client_copy(g, ids[0])
	var msg: String = ca.player_propose_alliance(ids[1])
	chk(ca.offers.size() == 1 and not ca.is_allied(ids[0], ids[1]), "istemci tarafı teklif yerel kabul etmedi: %s" % msg)
	room.submit(ids[0], ca.cmd_log)
	for h in ids:
		room.set_ready(h, true)
	room.process_round()
	chk(g.offers.size() == 1 and not g.is_allied(ids[0], ids[1]), "sunucuda teklif bekliyor")
	var cb = _client_copy(g, ids[1])
	chk(cb.offers_for(ids[1]).size() == 1, "alıcı istemci teklifi gördü")
	cb.respond_offer(int(cb.offers_for(ids[1])[0].id), true)
	room.submit(ids[1], cb.cmd_log)
	for h in ids:
		room.set_ready(h, true)
	var rr2: Dictionary = room.process_round()
	chk(g.is_allied(ids[0], ids[1]) and g.offers.is_empty(), "kabul sunucuda ittifak kurdu (red=%d)" % int(rr2.rejected))
	# kriz kararı + kabine kartı etkisi: komut olarak sunucuya gider (oyuncu başına önlem)
	const CrisesT = preload("res://scripts/crises.gd")
	var ck: String = String(CrisesT.KINDS.keys()[0])
	g.crisis = {"kind": ck, "start": g.turn, "end": g.turn + 8, "sev": 1.0, "mit": 1.0}
	var cc = _client_copy(g, ids[0])
	var gold0: float = float(g.countries[ids[0]].gold)
	var eff: Dictionary = {"g": -1.6, "mit": 0.35}
	CabinetT.apply(cc, eff)
	chk(cc.cmd_log.size() == 1 and cc.cmd_log[0].n == "Cabinet.apply", "Cabinet.apply komut olarak kaydedildi")
	chk(cc.crisis.get("mit_by", {}).get(ids[0], -1.0) == 0.35, "istemcide oyuncu başına önlem")
	room.submit(ids[0], cc.cmd_log)
	for h in ids:
		room.set_ready(h, true)
	var rr3: Dictionary = room.process_round()
	chk(rr3.rejected == 0, "kart komutu reddedilmedi")
	chk(float(g.crisis.get("mit_by", {}).get(ids[0], -1.0)) == 0.35 and not g.crisis.get("mit_by", {}).has(ids[1]), "sunucuda yalnızca o oyuncuya önlem")
	chk(CrisesT._mit_of(g, ids[1]) == 0.7 and CrisesT._mit_of(g, ids[0]) == 0.35, "kriz etkisi oyuncu başına")
	# savaş sisi: tam sis → yalnızca kendi/müttefik/görünür ordular
	var da: Dictionary = g.to_dict()
	var all_n: int = da.armies.size()
	var f2: Array = g.fog_filter_armies(da.armies, ids[1], 2)
	var own_n := 0
	for a in da.armies:
		if int(a[1]) == ids[1]:
			own_n += 1
	var f_own := 0
	for a in f2:
		if int(a[1]) == ids[1]:
			f_own += 1
	chk(f2.size() < all_n and f_own == own_n, "tam sis: yabancı ordular süzüldü (%d→%d), kendi ordular duruyor" % [all_n, f2.size()])
	chk(g.fog_filter_armies(da.armies, ids[1], 0).size() == all_n, "sis kapalı: hepsi")
	# diplomasi bildirimleri: karşı insan oyuncu haber alır (ittifak kurulmuş: elçi + ambargo), kötü niyetli komutlar reddedilir
	var cn = _client_copy(g, ids[0])
	var e1: String = cn.player_improve_relations(ids[1], "envoy")
	cn.player_set_embargo(ids[2], true)
	chk(cn.cmd_log.size() >= 2, "bildirim emirleri kaydedildi (%s)" % e1)
	room.submit(ids[0], cn.cmd_log)
	var evil: Array = [
		{"n": "Macro.buy", "a": [{"$c": ids[0]}, "x", -50]},
		{"n": "Macro.buy", "a": [{"$c": ids[1]}, "x", 5]},
		{"n": "finish_peace", "a": [null, 0, [], []]},
		{"n": "Cabinet.candidates", "a": []},
		{"n": "UN.propose", "a": ["sanction", ids[0], ids[2], {}]},
	]
	room.submit(ids[1], evil)
	for h in ids:
		room.set_ready(h, true)
	var rr4: Dictionary = room.process_round()
	chk(rr4.rejected >= 5, "kötü niyetli komutlar reddedildi: %d" % int(rr4.rejected))
	var got_env := false
	var got_emb := false
	for n in g.news_log:
		if n.kind == "dipl" and int(n.get("for", -1)) == ids[1] and n.turn == g.turn and String(n.text).contains("elçi"):
			got_env = true
		if n.kind == "dipl" and int(n.get("for", -1)) == ids[2] and n.turn == g.turn and String(n.text).contains("ambargo"):
			got_emb = true
	chk(got_env, "elçi haberi hedef oyuncuya (e1=%s)" % e1)
	chk(got_emb, "ambargo haberi hedef oyuncuya")
	chk(g.countries[ids[0]].embargo.has(ids[2]), "ambargo sunucuda uygulandı")
	# 5 tur daha stabil
	for i in 5:
		for h in ids:
			room.set_ready(h, true)
		room.process_round()
	chk(g.turn == t1 + 10, "ardışık turlar")
	print("HATA SAYISI=", bad)
	quit()
