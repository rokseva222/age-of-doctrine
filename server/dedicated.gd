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
	var cfg := {"name": _arg("name", "Sunucu"), "era": _arg("era", ""), "port": int(_arg("port", "47320")), "round_secs": float(_arg("secs", "120")),
		"max": int(_arg("max", "6")), "pass": _arg("pass", ""), "ver": _arg("ver", ""), "upnp": _arg("upnp", "0") == "1"}
	if not net.host(cfg):
		print("Sunucu açılamadı")
		quit(1)
		return
	print("AOD sunucu hazır: %s port %d" % [cfg.name, cfg.port])
	var region: String = _arg("region", "EU")
	var beat := Timer.new()
	beat.wait_time = 20.0
	beat.autostart = true
	beat.timeout.connect(func():
		master.announce({"name": cfg.name, "era": cfg.era, "players": net.players.size(), "max": cfg.max, "port": cfg.port, "pass": cfg.pass != "", "ver": cfg.ver, "region": region}))
	get_root().add_child(beat)
	master.announce({"name": cfg.name, "era": cfg.era, "players": 0, "max": cfg.max, "port": cfg.port, "pass": cfg.pass != "", "ver": cfg.ver, "region": region})
