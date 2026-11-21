extends Node
## Online çok oyunculu ağ katmanı (ENet, sunucu otoriter). Aynı betik hem sunucuda hem istemcide /root/AodNet olarak çalışır;
## RPC'ler iki tarafta da aynı adla tanımlıdır. Sunucu = eş kimliği 1.
##
## Akış: istemci bağlanır → hello → lobi durumu → ülke seç → (kurucu) başlat → herkese tam durum →
## her tur: istemci komutlarını + hazır bilgisini yollar → sunucu turu işler → herkese yeni tam durum.

const Room = preload("res://scripts/net_room.gd")
const GS = preload("res://scripts/game_state.gd")
const Mp = preload("res://scripts/mp.gd")
const Eras = preload("res://scripts/eras.gd")

const PROTO := 1
const DEFAULT_PORT := 47320
const LAN_PORT := 47321
const MAX_PLAYERS := 6

signal lobby_changed()
signal game_started(cid: int)
signal round_done(info: Dictionary)
signal status_changed()
signal disconnected()
signal error(msg: String)
signal chat(from_cid: int, text: String)

# ---- ortak durum
var is_server := false
var connected := false
var info: Dictionary = {}                  # sunucu bilgisi: name, era, scenario, max, pass, round_secs
var players: Dictionary = {}               # peer_id -> {"name":, "cid": -1, "host": bool}
var my_cid := -1
var started := false
var waiting: Array = []                    # henüz hazır olmayan ülke kimlikleri
var deadline_left := 0.0                   # tur bitimine kalan saniye (-1 = sınırsız)

# ---- sunucu
var room = null
var gs_server = null
var _round_timer := 0.0
var _lan_udp: PacketPeerUDP = null
var _lan_t := 0.0
var _world_seed := 0
var _server_logs: Array = []

# ---- ping (UDP sorgu: sunucu port+1'de dinler)
var _q_srv: UDPServer = null
var _q_peers: Array = []
var pings: Dictionary = {}                 # "ip:port" -> ms (-1 = yanıt yok)
var _q_out: Dictionary = {}                # "ip:port" -> {peer, t0}

# ---- istemci
var gs_client = null                       # istemcinin yerel oyun durumu (sunucudan gelen son tam durum)
var _lan_listen: PacketPeerUDP = null
var lan_found: Dictionary = {}             # "ip:port" -> {info..., "t": zaman}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func():
		connected = true
		rpc_id(1, "srv_hello", PROTO, Settings_name()))
	multiplayer.connection_failed.connect(func():
		connected = false
		error.emit("Sunucuya bağlanılamadı."))
	multiplayer.server_disconnected.connect(func():
		connected = false
		started = false
		disconnected.emit())


static func Settings_name() -> String:
	var S = load("res://scripts/settings.gd")
	var n: String = String(S.get("player_name")) if "player_name" in S else ""
	return n if n != "" else "Oyuncu"


# ======================================================================= sunucu

## Sunucuyu açar. cfg: {name, era, scenario, max, pass, round_secs, port}
func host(cfg: Dictionary) -> bool:
	var port: int = int(cfg.get("port", DEFAULT_PORT))
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(port, int(cfg.get("max", MAX_PLAYERS)))
	if err != OK:
		error.emit("Sunucu açılamadı (port %d)." % port)
		return false
	multiplayer.multiplayer_peer = peer
	is_server = true
	connected = true
	info = {"name": String(cfg.get("name", "Oda")), "era": String(cfg.get("era", "")), "scn": String(cfg.get("scenario", "")),
		"max": int(cfg.get("max", MAX_PLAYERS)), "pass": String(cfg.get("pass", "")), "secs": float(cfg.get("round_secs", 120.0)),
		"port": port, "proto": PROTO, "ver": String(cfg.get("ver", ""))}
	_world_seed = int(cfg.get("seed", randi() % 1000000))
	_lan_udp = PacketPeerUDP.new()
	_lan_udp.set_broadcast_enabled(true)
	_lan_udp.set_dest_address("255.255.255.255", LAN_PORT)
	_q_srv = UDPServer.new()
	_q_srv.listen(port + 1)
	return true


func _on_peer_connected(id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if is_server:
		var p: Dictionary = players.get(id, {})
		if started and room != null and int(p.get("cid", -1)) >= 0:
			room.set_afk(int(p.cid), true)      # bağlantı koptu: yapay zekâ devralır
		players.erase(id)
		_check_round()
		_push_lobby()


@rpc("any_peer", "call_remote", "reliable")
func srv_hello(proto: int, pname: String) -> void:
	if not is_server:
		return
	var id: int = multiplayer.get_remote_sender_id()
	if proto != PROTO:
		rpc_id(id, "cli_denied", "Sürüm uyuşmazlığı: sunucu ve oyun aynı sürümde olmalı.")
		return
	if players.size() >= int(info.max):
		rpc_id(id, "cli_denied", "Sunucu dolu.")
		return
	players[id] = {"name": pname.left(24), "cid": -1, "host": players.is_empty(), "pass_ok": String(info.pass) == ""}
	if String(info.pass) != "":
		rpc_id(id, "cli_need_pass")
	else:
		_push_lobby()


@rpc("any_peer", "call_remote", "reliable")
func srv_pass(pw: String) -> void:
	if not is_server:
		return
	var id: int = multiplayer.get_remote_sender_id()
	if not players.has(id):
		return
	if pw == String(info.pass):
		players[id].pass_ok = true
		_push_lobby()
	else:
		rpc_id(id, "cli_denied", "Şifre yanlış.")


## Kurucu (ilk bağlanan) dünyayı sunucuda kurar: çağ + seçili ülkeler başlatılınca.
@rpc("any_peer", "call_remote", "reliable")
func srv_pick(cid: int) -> void:
	if not is_server or started:
		return
	var id: int = multiplayer.get_remote_sender_id()
	if not players.has(id) or not bool(players[id].pass_ok):
		return
	for p in players.values():
		if int(p.cid) == cid:
			return
	players[id].cid = cid
	_push_lobby()


@rpc("any_peer", "call_remote", "reliable")
func srv_start() -> void:
	if not is_server or started:
		return
	var id: int = multiplayer.get_remote_sender_id()
	if not players.has(id) or not bool(players[id].host):
		return
	var picks: Array = []
	for p in players.values():
		if int(p.cid) >= 0:
			picks.append(int(p.cid))
	if picks.size() < 1:
		rpc_id(id, "cli_denied", "En az bir oyuncu ülke seçmeli.")
		return
	_build_world(picks)
	started = true
	_round_timer = float(info.secs)
	for pid in players:
		_send_state(pid, "cli_start")
	_push_lobby()


func _build_world(picks: Array) -> void:
	var era: String = String(info.era)
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(_world_seed)
	if era != "":
		Eras.restructure(g, era)
	g.start_game(picks[0])
	if era != "":
		Eras.start(g, era)
	room = Room.new()
	room.setup(g, picks)
	gs_server = g


func _send_state(pid: int, method: String) -> void:
	var d: Dictionary = gs_server.to_dict()
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	rpc_id(pid, method, raw, int(players[pid].cid), room.waiting_for(), String(info.era))


## İstemci: bu turun komutlarını yollar. ready=true ise "turu bitirdim".
@rpc("any_peer", "call_remote", "reliable")
func srv_submit(list: Array, is_ready: bool) -> void:
	if not is_server or not started:
		return
	var id: int = multiplayer.get_remote_sender_id()
	var p: Dictionary = players.get(id, {})
	if p.is_empty() or int(p.cid) < 0:
		return
	room.set_afk(int(p.cid), false)
	room.submit(int(p.cid), list)
	room.set_ready(int(p.cid), is_ready)
	_push_status()
	_check_round()


@rpc("any_peer", "call_remote", "reliable")
func srv_chat(text: String) -> void:
	if not is_server:
		return
	var id: int = multiplayer.get_remote_sender_id()
	var cid: int = int(players.get(id, {}).get("cid", -1))
	for pid in players:
		rpc_id(pid, "cli_chat", cid, text.left(200))


func _check_round() -> void:
	if not is_server or not started or room == null:
		return
	if room.all_ready():
		_run_round()


func _run_round() -> void:
	var r: Dictionary = room.process_round()
	_round_timer = float(info.secs)
	for pid in players:
		_send_state(pid, "cli_round")
	if String(r.get("over", "")) != "":
		for pid in players:
			rpc_id(pid, "cli_over", String(r.over))


func _push_lobby() -> void:
	var list: Array = []
	for pid in players:
		var p: Dictionary = players[pid]
		list.append({"id": pid, "name": p.name, "cid": p.cid, "host": p.host})
	for pid in players:
		if bool(players[pid].pass_ok):
			rpc_id(pid, "cli_lobby", info, list, started, pid)
	lobby_changed.emit()


func _push_status() -> void:
	var w: Array = room.waiting_for() if room != null else []
	for pid in players:
		rpc_id(pid, "cli_status", w, _round_timer)


## Bir sunucuya ping atar (sonuç pings["ip:port"] içinde, ms). Yanıt gelmezse 2 sn sonra -1.
func ping(ip: String, port: int) -> void:
	var key := "%s:%d" % [ip, port]
	var pk := PacketPeerUDP.new()
	if pk.connect_to_host(ip, port + 1) != OK:
		pings[key] = -1
		return
	pk.put_packet("AODQ".to_utf8_buffer())
	_q_out[key] = {"peer": pk, "t0": Time.get_ticks_msec()}


func _poll_ping() -> void:
	if _q_srv != null:
		_q_srv.poll()
		while _q_srv.is_connection_available():
			var pe: PacketPeerUDP = _q_srv.take_connection()
			var pkt: PackedByteArray = pe.get_packet()
			if pkt.get_string_from_utf8() == "AODQ":
				pe.put_packet(("AODR|%s|%d|%d|%d" % [String(info.name).replace("|", " "), players.size(), int(info.max), PROTO]).to_utf8_buffer())
			_q_peers.append(pe)
		if _q_peers.size() > 32:
			_q_peers = _q_peers.slice(_q_peers.size() - 16)
	for key in _q_out.keys():
		var o: Dictionary = _q_out[key]
		var pk: PacketPeerUDP = o.peer
		if pk.get_available_packet_count() > 0:
			var r: String = pk.get_packet().get_string_from_utf8()
			if r.begins_with("AODR"):
				pings[key] = Time.get_ticks_msec() - int(o.t0)
				pk.close()
				_q_out.erase(key)
				continue
		if Time.get_ticks_msec() - int(o.t0) > 2000:
			pings[key] = -1
			pk.close()
			_q_out.erase(key)


func _process(delta: float) -> void:
	_poll_ping()
	if is_server:
		_lan_t += delta
		if _lan_t >= 1.0 and _lan_udp != null:
			_lan_t = 0.0
			var n: int = 0
			for p in players.values():
				n += 1
			var beacon := "AOD|%d|%s|%s|%d|%d|%d|%s" % [PROTO, String(info.name).replace("|", " "), String(info.era), n, int(info.max), int(info.port), "1" if String(info.pass) != "" else "0"]
			_lan_udp.put_packet(beacon.to_utf8_buffer())
		if started and room != null and float(info.secs) > 0.0:
			_round_timer -= delta
			if _round_timer <= 0.0:
				# süre doldu: hazır olmayanın emirleri o ana kadar gönderdiği kadar, tur işlenir
				_run_round()
	if _lan_listen != null:
		while _lan_listen.get_available_packet_count() > 0:
			var pkt: PackedByteArray = _lan_listen.get_packet()
			var ip: String = _lan_listen.get_packet_ip()
			var s: String = pkt.get_string_from_utf8()
			var f: PackedStringArray = s.split("|")
			if f.size() >= 8 and f[0] == "AOD":
				lan_found["%s:%s" % [ip, f[6]]] = {"proto": int(f[1]), "name": f[2], "era": f[3], "players": int(f[4]), "max": int(f[5]), "port": int(f[6]), "pass": f[7] == "1", "ip": ip, "t": Time.get_ticks_msec()}


# ======================================================================= istemci

func join(addr: String, port: int = DEFAULT_PORT) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_client(addr, port)
	if err != OK:
		error.emit("Bağlantı kurulamadı.")
		return false
	multiplayer.multiplayer_peer = peer
	is_server = false
	return true


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	connected = false
	started = false
	is_server = false
	room = null
	gs_server = null
	players = {}
	if _lan_udp != null:
		_lan_udp.close()
		_lan_udp = null
	if _q_srv != null:
		_q_srv.stop()
		_q_srv = null


func lan_scan_start() -> void:
	if _lan_listen != null:
		return
	_lan_listen = PacketPeerUDP.new()
	if _lan_listen.bind(LAN_PORT) != OK:
		_lan_listen = null


func lan_scan_stop() -> void:
	if _lan_listen != null:
		_lan_listen.close()
		_lan_listen = null


@rpc("authority", "call_remote", "reliable")
func cli_denied(msg: String) -> void:
	error.emit(msg)


@rpc("authority", "call_remote", "reliable")
func cli_need_pass() -> void:
	status_changed.emit()
	players = {}
	info = {"need_pass": true}
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func cli_lobby(inf: Dictionary, list: Array, is_started: bool, my_id: int) -> void:
	info = inf
	started = is_started
	players = {}
	for p in list:
		players[int(p.id)] = p
		if int(p.id) == my_id:
			my_cid = int(p.cid)
	lobby_changed.emit()


@rpc("authority", "call_remote", "reliable")
func cli_start(raw: PackedByteArray, cid: int, wait: Array, era: String) -> void:
	_apply_state(raw, cid, wait, era)
	started = true
	game_started.emit(cid)


@rpc("authority", "call_remote", "reliable")
func cli_round(raw: PackedByteArray, cid: int, wait: Array, era: String) -> void:
	_apply_state(raw, cid, wait, era)
	round_done.emit({"turn": gs_client.turn})


@rpc("authority", "call_remote", "reliable")
func cli_status(wait: Array, left: float) -> void:
	waiting = wait
	deadline_left = left
	status_changed.emit()


@rpc("authority", "call_remote", "reliable")
func cli_chat(cid: int, text: String) -> void:
	chat.emit(cid, text)


@rpc("authority", "call_remote", "reliable")
func cli_over(text: String) -> void:
	error.emit(text)


func _apply_state(raw: PackedByteArray, cid: int, wait: Array, era: String) -> void:
	var d = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(int(d.get("seed", 0)))
	g.from_dict(d)
	g.humans = []
	my_cid = cid
	waiting = wait
	gs_client = g
