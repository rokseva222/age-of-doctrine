extends SceneTree
## Çok oyunculu oda kaydı (ağsız): her tur sonunda kaydedilir, yeni süreçte yüklenir, koltuk sahipleri dönene kadar tur işlenmez,
## oyun bitince kayıt silinir.
const NetS = preload("res://scripts/net.gd")
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const DIR := "/tmp/aod_savetest"

var bad := 0
func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + "/" + f)
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
	net.save_dir = DIR
	net.info = {"secs": 0.0, "name": "Deneme Odası", "era": "", "max": 6, "pass": "", "port": 1, "save": "deneme_0001"}
	net._seats = {"tokA1234": {"cid": ids[0], "cname": "Türkiye"}, "tokB1234": {"cid": ids[1], "cname": "Almanya"}, "tokC1234": {"cid": ids[2], "cname": "Fransa"}}
	net.save_room()
	chk(FileAccess.file_exists(DIR + "/deneme_0001.dat") and FileAccess.file_exists(DIR + "/deneme_0001.json"), "ilk kayıt yazıldı")
	var meta: Dictionary = NetS.read_meta(DIR, "deneme_0001")
	chk(int(meta.get("turn", -1)) == g.turn and (meta.get("seats", {}) as Dictionary).size() == 3, "özet doğru: %s" % str(meta).left(120))
	# iki tur oyna: her tur sonunda kayıt güncellenir
	var t0: int = g.turn
	for i in 2:
		for h in ids:
			room.set_ready(h, true)
		net._check_round()
	chk(g.turn == t0 + 2, "iki tur işlendi (%d)" % g.turn)
	chk(int(NetS.read_meta(DIR, "deneme_0001").get("turn", -1)) == t0 + 2, "kayıt tur sonunda güncellendi")
	var gold0: float = g.countries[ids[0]].gold
	var prov_owner0: int = g.provinces[0].owner
	var turn_saved: int = g.turn
	# yeni süreç: kayıttan yükle
	var net2 = NetS.new()
	root.add_child(net2)
	net2.is_server = true
	net2.save_dir = DIR
	net2.info = {"secs": 0.0, "name": "Deneme Odası", "era": "", "max": 6, "pass": "", "port": 2}
	chk(net2.load_saved("deneme_0001"), "kayıt yüklendi")
	chk(net2.started and net2.room != null, "oda başlamış durumda")
	chk(net2.gs_server.turn == turn_saved, "tur aynı (%d)" % net2.gs_server.turn)
	chk(is_equal_approx(net2.gs_server.countries[ids[0]].gold, gold0), "altın aynı")
	chk(net2.gs_server.provinces[0].owner == prov_owner0, "eyalet sahibi aynı")
	chk(net2.gs_server.humans == ids, "insan ülkeler aynı: %s" % str(net2.gs_server.humans))
	chk(net2._seats.size() == 3 and String(net2._seats["tokB1234"].cname) == "Almanya", "koltuklar geri geldi")
	chk(String(net2.info.get("save", "")) == "deneme_0001", "kayıt kimliği korundu")
	chk(net2._resume_left > 0.0, "koltuk sahiplerini bekleme açık")
	# kimse dönmeden herkes hazır olsa da tur işlenmez
	for h in ids:
		net2.room.set_afk(h, false)
		net2.room.set_ready(h, true)
	net2._check_round()
	chk(net2.gs_server.turn == turn_saved, "bekleme sırasında tur işlenmedi")
	for h in ids:
		net2.room.set_afk(h, true)
		net2.room.set_ready(h, false)
	# zamanlayıcı: kimse bağlı değilken bekleme süresi akmaz
	var left0: float = net2._resume_left
	net2._process(10.0)
	chk(is_equal_approx(net2._resume_left, left0), "kimse yokken bekleme süresi akmadı")
	# bir koltuk sahibi döner (eş 1 = yerel sunucu oyuncusu): süre akar, ama herkes dönmedi
	net2.players[1] = {"name": "A", "cid": ids[0], "host": true, "pass_ok": true, "token": "tokA1234"}
	net2.room.set_afk(ids[0], false)
	net2._resume_check()
	chk(net2._resume_left > 0.0, "herkes dönmedi: bekleme sürüyor")
	net2._process(30.0)
	chk(net2._resume_left < left0, "biri bağlıyken bekleme süresi akıyor")
	chk(net2.gs_server.turn == turn_saved, "hâlâ tur işlenmedi")
	# bekleme süresi dolunca: dönmeyenler yapay zekâda, dönen hazırsa tur işlenir
	net2.room.set_ready(ids[0], true)
	net2._process(net2._resume_left + 1.0)
	chk(net2._resume_left == 0.0, "bekleme bitti")
	chk(net2.gs_server.turn == turn_saved + 1, "bekleme bitince tur işlendi (%d)" % net2.gs_server.turn)
	chk(bool(net2.room.afk.get(ids[1], false)) and not bool(net2.room.afk.get(ids[0], false)), "dönmeyen YZ'de, dönen oyuncuda")
	# herkes dönünce bekleme hemen biter
	var net3 = NetS.new()
	root.add_child(net3)
	net3.is_server = true
	net3.save_dir = DIR
	net3.info = {"secs": 0.0, "name": "x", "era": "", "max": 6, "pass": "", "port": 3}
	chk(net3.load_saved("deneme_0001"), "ikinci yükleme")
	var tk := ["tokA1234", "tokB1234", "tokC1234"]
	for i in 3:
		net3.players[100 + i] = {"name": "p%d" % i, "cid": ids[i], "host": i == 0, "pass_ok": true, "token": tk[i]}
	net3._resume_check()
	chk(net3._resume_left == 0.0, "herkes dönünce bekleme bitti")
	# geçersiz kimlik / bozuk kayıt
	chk(not net3.load_saved("../etc"), "geçersiz kimlik reddedildi")
	chk(not net3.load_saved("yok_boyle_kayit"), "olmayan kayıt reddedildi")
	# oyun bitince kayıt silinir
	net.info["save"] = "deneme_0001"
	net._reset_to_lobby()
	chk(not FileAccess.file_exists(DIR + "/deneme_0001.dat") and not FileAccess.file_exists(DIR + "/deneme_0001.json"), "oyun bitince kayıt silindi")
	print("HATA SAYISI=%d" % bad)
	quit()
