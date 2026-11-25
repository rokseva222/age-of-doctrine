extends SceneTree
## Age of Doctrine sunucu programı (başsız). Çalıştırma:
##   godot --headless --path . -s server/dedicated.gd -- --name "TR Resmi" --era ww1 --port 47320 --secs 120 --max 6 --pass "" --master https://liste.adresiniz --region EU
## Sunucu bir oda tutar: oyuncular bağlanır, ülke seçer, ilk bağlanan "Başlat" der. Oyun bitince oda lobiye döner.
const NetS = preload("res://scripts/net.gd")
const MasterS = preload("res://scripts/net_master.gd")

var net
var master


func _arg(name: String, def: String) -> String:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--" + name and i + 1 < a.size():
			return a[i + 1]
	return def


func _init() -> void:
	net = NetS.new()
	net.name = "AodNet"
	get_root().add_child(net)
	master = MasterS.new()
	get_root().add_child(master)
	var url: String = _arg("master", "")
	if url != "":
		master.url = url
	await process_frame
	var save_dir: String = _arg("savedir", "")
	var resume_id: String = _arg("resume", "")
	net.save_dir = save_dir
	var cfg := {"name": _arg("name", "Sunucu"), "era": _arg("era", ""), "scenario": _arg("scn", ""), "port": int(_arg("port", "47320")), "round_secs": float(_arg("secs", "120")),
		"max": clampi(int(_arg("max", "6")), 2, 12), "pass": _arg("pass", ""), "ver": _arg("ver", ""), "upnp": _arg("upnp", "0") == "1", "fog": int(_arg("fog", "0"))}
	if resume_id != "":
		# kayıtlı oda: ayarlar kayıt özetinden gelir (ad, çağ, süre, şifre...)
		var meta: Dictionary = NetS.read_meta(save_dir, resume_id)
		if meta.is_empty():
			print("Kayıt bulunamadı: ", resume_id)
			quit(2)
			return
		cfg["name"] = String(meta.get("name", cfg.name))
		cfg["era"] = String(meta.get("era", ""))
		cfg["scenario"] = String(meta.get("scn", ""))
		cfg["round_secs"] = float(meta.get("secs", 120.0))
		cfg["max"] = clampi(int(meta.get("max", 6)), 2, 12)
		cfg["pass"] = String(meta.get("pass", ""))
		cfg["fog"] = int(meta.get("fog", 0))
	var sf: String = _arg("scnfile", "")
	if sf != "" and FileAccess.file_exists(sf):
		cfg["scn_code"] = FileAccess.get_file_as_string(sf).strip_edges()
	if not net.host(cfg):
		print("Sunucu açılamadı")
		quit(1)
		return
	if resume_id != "" and not net.load_saved(resume_id):
		print("Kayıt yüklenemedi: ", resume_id)
		quit(3)
		return
	print("AOD sunucu hazır: %s port %d" % [cfg.name, cfg.port])
	# --idle N: oda N sn boş kalırsa süreç kapanır (hub kullanılıyorsa). İlk oyuncu en geç 90 sn içinde gelmeli.
	var idle_max: int = int(_arg("idle", "0"))
	if idle_max > 0:
		var idle_t := Timer.new()
		idle_t.wait_time = 10.0
		idle_t.autostart = true
		var st := {"idle": 0, "had": false}
		idle_t.timeout.connect(func():
			if net.players.size() > 0:
				st.had = true
				st.idle = 0
				return
			st.idle += 10
			if st.idle >= (idle_max if st.had else 90):
				print("Oda boş kaldı, kapanıyor")
				quit(0))
		get_root().add_child(idle_t)
	var region: String = _arg("region", "EU")
	var announce := func():
		master.announce({"name": cfg.name, "era": cfg.era, "players": net.players.size(), "max": cfg.max, "port": cfg.port, "pass": cfg.pass != "", "ver": cfg.ver, "region": region, "save": String(net.info.get("save", ""))})
	var beat := Timer.new()
	beat.wait_time = 8.0
	beat.autostart = true
	beat.timeout.connect(announce)
	get_root().add_child(beat)
	# biri girip çıkınca ya da ülke seçince hemen duyur: oda listede geç görünmesin
	net.lobby_changed.connect(announce)
	master.announce({"name": cfg.name, "era": cfg.era, "players": 0, "max": cfg.max, "port": cfg.port, "pass": cfg.pass != "", "ver": cfg.ver, "region": region, "save": String(net.info.get("save", ""))})
