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
	var s = GS.new()
	s.new_world(5)
	s.start_game(picks[0])
	var t1: int = s.turn
	s.end_turn()
	chk(s.turn == t1 + 1 and not s.is_multi(), "tek oyunculu tur")
	print("HATA SAYISI=", bad)
	quit()
