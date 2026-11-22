extends SceneTree
## Sunucu tur zamanlayıcısı (ağsız): biri turu bitirince 120 sn bekleme; dolunca tur işlenir, 2 kaçıran yapay zekâya geçer.
const NetS = preload("res://scripts/net.gd")
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")

var bad := 0
func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

func _init() -> void:
	var g = GS.new()
	g.new_world(21)
	var ids: Array = []
	for n in ["Turkey", "Germany", "France"]:
		ids.append(int(g.macro_idx.get(n, 0)))
	g.start_game(ids[0])
	var room = Room.new()
	room.setup(g, ids)
	var net = NetS.new()
	root.add_child(net)
	net.is_server = true
	net.started = true
	net.room = room
	net.gs_server = g
	net.info = {"secs": 0.0, "name": "t", "era": "", "max": 6, "pass": "", "port": 1}
	var t0: int = g.turn
	# kimse hazır değil: geri sayım yok
	net._process(1.0)
	chk(not net._grace_on, "kimse hazır değilken bekleme yok")
	# Türkiye hazır: bekleme başlar
	room.set_ready(ids[0], true)
	net._process(1.0)
	chk(net._grace_on, "biri hazırken bekleme başladı")
	var d: Dictionary = net._deadline()
	chk(bool(d.grace) and float(d.left) > 100.0 and float(d.left) <= 120.0, "geri sayım ~120 sn: %s" % str(d))
	for i in 118:
		net._process(1.0)
	chk(g.turn == t0, "süre dolmadan tur işlenmedi")
	for i in 5:
		net._process(1.0)
	chk(g.turn == t0 + 1, "süre dolunca tur işlendi (turn=%d)" % g.turn)
	chk(int(room.missed.get(ids[1], 0)) == 1 and int(room.missed.get(ids[2], 0)) == 1, "kaçıranlar 1 sayıldı")
	chk(not bool(room.afk.get(ids[1], false)), "ilk kaçırışta AFK olmaz")
	chk(not net._grace_on, "tur sonrası bekleme sıfırlandı")
	# ikinci tur: Türkiye yine hazır, diğerleri yine yok → 2. kaçış → yapay zekâ
	room.set_ready(ids[0], true)
	for i in 130:
		net._process(1.0)
	chk(g.turn == t0 + 2, "ikinci tur işlendi")
	chk(bool(room.afk.get(ids[1], false)) and bool(room.afk.get(ids[2], false)), "iki kaçıştan sonra yapay zekâ devraldı")
	chk(not bool(room.afk.get(ids[0], false)), "hazır olan AFK olmadı")
	# AFK'lar atlanır: Türkiye tek başına hazır olunca tur hemen işlenir
	room.set_ready(ids[0], true)
	net._check_round()
	chk(g.turn == t0 + 3, "AFK'lar beklenmeden tur işlendi")
	# süre sınırı (secs) devrede: kimse hazır değil, süre dolunca tur zorla işlenir
	net.info.secs = 30.0
	net._round_timer = 30.0
	room.afk[ids[1]] = false
	room.afk[ids[2]] = false
	for i in 32:
		net._process(1.0)
	chk(g.turn == t0 + 4, "tur süresi dolunca işlendi (turn=%d)" % g.turn)
	# bayat tur kimliği reddedilir, güncel olan kabul edilir (yerel sunucu oyuncusu = eş 1)
	net.players[1] = {"name": "t", "cid": ids[0], "host": true, "pass_ok": true}
	room.ready[ids[0]] = false
	net.srv_submit(g.turn - 1, [], true)
	chk(not bool(room.ready.get(ids[0], false)), "bayat tur gönderimi yok sayıldı")
	net.srv_submit(g.turn, [], false)
	chk(not bool(room.ready.get(ids[0], false)), "hazır işaretlenmeden gönderim")
	# süre dolmak üzereyken bekleyenlere "emirleri yolla" çağrısı bir kez gider
	var flushed := [0]
	net.flush_asked.connect(func(): flushed[0] += 1)
	net.info.secs = 30.0
	net._round_timer = 6.0
	net._flushed = false
	room.missed[ids[0]] = 0
	for i in 3:
		net._process(1.0)
	chk(flushed[0] == 1, "bitmeden önce bir kez emir yollatıldı (%d)" % flushed[0])
	# geçici YZ devri: kaçıran oyuncu AFK olarak işaretli kalmaz (ilk kaçış)
	for i in 5:
		net._process(1.0)
	chk(not bool(room.afk.get(ids[0], false)), "geçici devir sonrası oyuncuya geri verildi")
	print("HATA SAYISI=%d" % bad)
	quit()
