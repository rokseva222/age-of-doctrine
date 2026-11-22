extends SceneTree
## Uçtan uca ağ testi istemcisi: sunucuya bağlan → ülke seç → başlat → komut gönder → tur al.
const NetS = preload("res://scripts/net.gd")
var net
var step := 0
var t := 0.0
var cid := -1
var done_rounds := 0

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
	net.error.connect(func(m): print("HATA:", m))
	net.lobby_changed.connect(_on_lobby)
	net.game_started.connect(_on_start)
	net.round_done.connect(_on_round)
	await process_frame
	net.join("127.0.0.1", int(_arg("port", "47399")))

var picked := false
func _on_lobby() -> void:
	print("lobi: ", net.players.size(), " oyuncu info=", net.info.get("name", "?"))
	if not picked and net.players.size() >= 1:
		picked = true
		net.rpc_id(1, "srv_pick", int(_arg("cid", "16")), "X")
	if int(_arg("host", "1")) == 1 and net.players.size() >= int(_arg("need", "1")):
		var all_picked := true
		for p in net.players.values():
			if int(p.cid) < 0:
				all_picked = false
		if all_picked and not net.started:
			net.rpc_id(1, "srv_start")

func _on_start(c: int) -> void:
	if _dropped:
		print("RESUMED cid=", c, " tur=", net.gs_client.turn)
		cid = c
		_play()
		return
	cid = c
	var g = net.gs_client
	print("başladı cid=", c, " tur=", g.turn, " ülke=", g.countries[c].name)
	_play()

func _play() -> void:
	var g = net.gs_client
	g.cmd_log = []
	const Cmd = preload("res://scripts/cmd.gd")
	Cmd.rec_gs = g
	g.switch_player(cid)
	# basit bir emir: bütçeyi değiştir
	const Macro = preload("res://scripts/macro.gd")
	Macro.set_budget(g.countries[cid], "army", 25 + done_rounds)
	print("gönder: ", g.cmd_log.size(), " komut, tur=", g.turn)
	net.rpc_id(1, "srv_submit", g.turn, g.cmd_log, true)

var _dropped := false
func _on_round(inf: Dictionary) -> void:
	done_rounds += 1
	if int(_arg("reconnect", "0")) == 1 and done_rounds == 1 and not _dropped:
		_dropped = true
		print("bağlantı kesiliyor...")
		net.leave()
		await create_timer(1.0).timeout
		net.started = false
		net.join("127.0.0.1", int(_arg("port", "47399")))
		return
	print("tur geldi: ", inf.turn, " (", done_rounds, ")")
	if done_rounds >= int(_arg("rounds", "3")):
		print("E2E_OK")
		quit()
		return
	_play()

func _process(delta: float) -> bool:
	t += delta
	if t > float(_arg("timeout", "120")):
		print("E2E_TIMEOUT")
		quit(2)
	return false
