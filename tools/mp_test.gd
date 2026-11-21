extends SceneTree
## Çok oyunculu (hotseat) mantığı: sıra geçişi, yapay zekânın insanları atlaması, bitiş, kayıt
const GS = preload("res://scripts/game_state.gd")
const Mp = preload("res://scripts/mp.gd")

var bad := 0

func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

func _init() -> void:
	var g = GS.new()
	g.new_world(11)
	var names := ["Turkey", "Germany", "France"]
	var picks: Array = []
	for n in names:
		picks.append(int(g.macro_idx.get(n, 0)))
	g.start_game(picks[0])
	Mp.begin(g, picks)
	chk(g.is_multi(), "is_multi")
	chk(g.player == picks[0], "ilk koltuk")
	for c in picks:
		chk(g.countries[c].is_player, "is_player %d" % c)
	# 3 tam tur
	for round_i in 3:
		var seen: Array = [g.player]
		while true:
			var r: Dictionary = Mp.finish_seat(g)
			if r.round_done:
				break
			chk(g.player == r.next, "koltuk geçişi")
			seen.append(g.player)
		chk(seen == picks, "koltuk sırası %s" % str(seen))
		var t0: int = g.turn
		Mp.prepare_round(g)
		g.end_turn()
		chk(g.turn == t0 + 1, "tur ilerledi")
		var f: int = Mp.begin_round(g)
		chk(f == picks[0], "yeni tur ilk koltuk")
		chk(Mp.check_end(g) == "", "erken bitiş yok")
	# insan ülkeleri yapay zekâ tarafından oynanmadı: otomatik emir yok
	chk(g.last_auto == 0, "otomatik emir yok")
	# kayıt gidiş-dönüş
	var d: Dictionary = g.to_dict()
	var g2 = GS.new()
	g2.new_world(11)
	chk(g2.from_dict(d), "from_dict")
	chk(g2.humans == picks, "humans yüklendi: %s" % str(g2.humans))
	chk(g2.player == g.player, "player yüklendi")
	# yok edilen insan atlanır
	g.countries[picks[1]].alive = false
	chk(Mp.alive_humans(g).size() == 2, "alive_humans")
	var r2: Dictionary = Mp.finish_seat(g)
	chk(not r2.round_done and g.player == picks[2], "ölü koltuk atlandı")
	g.countries[picks[2]].alive = false
	chk(Mp.check_end(g) != "", "tek kalan: bitiş")
	# tek oyunculu bozulmadı
	# insanlar arası teklifler
	var o = GS.new()
	o.new_world(11)
	o.start_game(picks[0])
	Mp.begin(o, picks)
	var a: int = picks[0]
	var b: int = picks[1]
	var msg: String = o.player_propose_alliance(b)
	chk(o.offers.size() == 1 and not o.is_allied(a, b), "ittifak teklifi bekliyor: %s" % msg)
	chk(o.player_propose_alliance(b) != "", "aynı tur tekrar teklif yok")
	chk(o.offers_for(b).size() == 1 and o.offers_for(a).is_empty(), "teklif hedefte")
	var od: Dictionary = o.to_dict()
	var o2 = GS.new()
	o2.new_world(11)
	o2.from_dict(od)
	chk(o2.offers.size() == 1, "teklif kayıttan döndü")
	o.switch_player(b)
	var oid: int = int(o.offers[0].id)
	o.respond_offer(oid, true)
	chk(o.is_allied(a, b) and o.offers.is_empty(), "kabul → müttefik")
	o.switch_player(a)
	o.break_alliance_for_test(a, b) if o.has_method("break_alliance_for_test") else null
	o.player_declare_war(picks[2])
	var res: Dictionary = o.player_request_peace(picks[2])
	chk(not res.ok and o.offers.size() == 1, "barış teklifi insana gitti: %s" % str(res))
	o.switch_player(picks[2])
	var w0: int = o.wars.size()
	o.respond_offer(int(o.offers[0].id), true)
	chk(o.wars.size() == w0 - 1, "barış kabulü savaşı bitirdi")
	o.switch_player(a)
	o.player_propose_alliance(picks[2])
	chk(o.offers.size() == 1, "ikinci ittifak teklifi bekliyor")
	o.switch_player(picks[2])
	o.respond_offer(int(o.offers[0].id), false)
	chk(o.offers.is_empty(), "ret teklifi kaldırdı")
	o.switch_player(picks[1])
	o.player_propose_alliance(picks[2])
	for i in 5:
		o.end_turn()
	chk(o.offers.is_empty(), "teklif süresi doldu")
	var s = GS.new()
	s.new_world(5)
	s.start_game(picks[0])
	var t1: int = s.turn
	s.end_turn()
	chk(s.turn == t1 + 1 and not s.is_multi(), "tek oyunculu tur")
	print("HATA SAYISI=", bad)
	quit()
