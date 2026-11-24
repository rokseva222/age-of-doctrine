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
const Scenarios = preload("res://scripts/scenarios.gd")
const Settings = preload("res://scripts/settings.gd")

const PROTO := 2
const DEFAULT_PORT := 47320
const LAN_PORT := 47321
const MAX_PLAYERS := 12
const FLUSH_SECS := 4.0
const MAX_CMDS := 600
const MAX_COUNTRY_ID := 400
const HELLO_SECS := 10.0
const GRACE_SECS := 120.0                    # biri turu bitirince diğerlerine tanınan bekleme süresi
const MISS_LIMIT := 2                        # üst üste bu kadar tur kaçıran oyuncunun ülkesini yapay zekâ devralır

signal lobby_changed()
signal game_started(cid: int)
signal round_done(info: Dictionary)
signal status_changed()
signal disconnected()
signal error(msg: String)
signal chat(from_cid: int, pname: String, text: String)
signal over(text: String)
signal flush_asked()
signal voice_invite(from_cid: int, from_name: String, gid: int)
signal voice_state()
signal voice_audio(from_cid: int, data: PackedByteArray)
signal note(kind: String, cid: int, text: String)   # oyuncu olayları: ready, afk, back, left, grace, diplo...

# ---- ortak durum
var is_server := false
var connected := false
var info: Dictionary = {}                  # sunucu bilgisi: name, era, scenario, max, pass, round_secs
var players: Dictionary = {}               # peer_id -> {"name":, "cid": -1, "host": bool}
var my_cid := -1
var started := false
var waiting: Array = []                    # henüz hazır olmayan ülke kimlikleri
var chat_log: Array = []                   # [{cid, name, text}] (son 60 mesaj)
var deadline_left := 0.0                   # tur bitimine kalan saniye (-1 = sınırsız)
var deadline_grace := false                # true: geri sayım "diğerleri bitirdi, sen bekletiyorsun" süresi
var afk_ids: Array = []                    # yapay zekânın yönettiği insan ülkeleri

# ---- sunucu
var room = null
var gs_server = null
var _round_timer := 0.0
var _grace_on := false
var _grace_left := 0.0
var _flushed := false                      # bu tur için "bekleyen emirleri yolla" çağrısı yapıldı mı
var _hello_t: Dictionary = {}              # peer -> bağlandıktan beri geçen sn (selam gelmeyen eş atılır)
var _lan_udp: PacketPeerUDP = null
var _lan_t := 0.0
var _st_t := 0.0
var _world_seed := 0
var _scn_code := ""           # kullanıcı senaryosu paylaşım kodu (sunucuda dosyası yoksa buradan kurulur)
var _server_logs: Array = []
var upnp_state := ""                       # "", "trying", "ok", "fail"
var upnp_ip := ""                          # UPnP ile öğrenilen dış IP
var _upnp: UPNP = null
var _upnp_thread: Thread = null
var _upnp_port := 0
var _seats: Dictionary = {}                # token -> {"cid", "cname"} (bağlantısı kopan oyuncu geri dönünce koltuğunu alır)

# ---- ping (UDP sorgu: sunucu port+1'de dinler)
var _q_srv: UDPServer = null
var _q_peers: Array = []
var pings: Dictionary = {}                 # "ip:port" -> ms (-1 = yanıt yok)
var ping_info: Dictionary = {}             # "ip:port" -> {"players", "max"} (sunucunun kendi yanıtından)
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
		_ever_connected = true
		rpc_id(1, "srv_hello", PROTO, Settings_name(), my_token()))
	multiplayer.connection_failed.connect(func():
		connected = false
		# aynı bilgisayarda iki oyun açıkken genel IP'ye (NAT geri dönüşü) bağlanılamaz: yerel adresi de dene
		if not _ever_connected and last_addr != "127.0.0.1" and not _tried_local:
			_tried_local = true
			join("127.0.0.1", last_port)
			return
		error.emit("Sunucuya bağlanılamadı.")
		disconnected.emit())
	multiplayer.server_disconnected.connect(func():
		connected = false
		started = false
		disconnected.emit())


static func my_token() -> String:
	if Settings.net_token == "":
		Settings.net_token = "%08x%08x" % [randi(), randi()]
		Settings.save_all()
	return Settings.net_token


static func Settings_name() -> String:
	var n: String = Settings.player_name
	return n if n != "" else "Oyuncu"


# ======================================================================= yardımcılar

## Sunucu → eş. Eş yerel sunucu oyuncusu (kimlik 1) ise doğrudan çağrılır.
func _to(pid: int, method: String, args: Array = []) -> void:
	if pid == 1 and is_server:
		callv(method, args)
	else:
		var full: Array = [pid, method]
		full.append_array(args)
		callv("rpc_id", full)


## İstemci → sunucu (sunucu oyuncusuysa doğrudan çağrı).
func to_server(method: String, args: Array = []) -> void:
	if is_server:
		callv(method, args)
	else:
		var full: Array = [1, method]
		full.append_array(args)
		callv("rpc_id", full)


func _sender() -> int:
	if multiplayer == null:
		return 1
	var s: int = multiplayer.get_remote_sender_id()
	return 1 if s == 0 else s


# ======================================================================= sunucu

## Sunucuyu açar. cfg: {name, era, scenario, max, pass, round_secs, port}
func host(cfg: Dictionary) -> bool:
	var local_player: bool = bool(cfg.get("local", false))
	var port: int = int(cfg.get("port", DEFAULT_PORT))
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(port, int(cfg.get("max", MAX_PLAYERS)))
	if err != OK:
		error.emit("Sunucu açılamadı.")
		return false
	multiplayer.multiplayer_peer = peer
	is_server = true
	connected = true
	info = {"name": String(cfg.get("name", "Oda")), "era": String(cfg.get("era", "")), "scn": String(cfg.get("scenario", "")),
		"max": int(cfg.get("max", MAX_PLAYERS)), "pass": String(cfg.get("pass", "")), "secs": float(cfg.get("round_secs", 120.0)),
		"port": port, "proto": PROTO, "ver": String(cfg.get("ver", "")), "fog": clampi(int(cfg.get("fog", 0)), 0, 2)}
	_world_seed = int(cfg.get("seed", randi() % 1000000))
	_scn_code = String(cfg.get("scn_code", ""))
	_lan_udp = PacketPeerUDP.new()
	_lan_udp.set_broadcast_enabled(true)
	_lan_udp.set_dest_address("255.255.255.255", LAN_PORT)
	_q_srv = UDPServer.new()
	_q_srv.listen(port + 1)
	info["seed"] = _world_seed
	players = {}
	_seats.clear()
	if local_player:
		players[1] = {"name": Settings_name(), "cid": -1, "host": true, "pass_ok": true}
	if bool(cfg.get("upnp", false)):
		_upnp_open(port)
	return true


## Yönlendiricide UPnP ile portu açar (NAT arkasındaki telefon/PC odası internetten erişilebilsin). Ayrı iş parçacığında çalışır.
func _upnp_open(port: int) -> void:
	upnp_state = "trying"
	upnp_ip = ""
	_upnp_port = port
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_work.bind(port))


func _upnp_work(port: int) -> void:
	var u := UPNP.new()
	var ok := false
	var ip := ""
	if u.discover(2000, 2, "InternetGatewayDevice") == UPNP.UPNP_RESULT_SUCCESS:
		var gw = u.get_gateway()
		if gw != null and gw.is_valid_gateway():
			var a: int = u.add_port_mapping(port, port, "Age of Doctrine", "UDP", 0)
			var b: int = u.add_port_mapping(port + 1, port + 1, "Age of Doctrine ping", "UDP", 0)
			if a == UPNP.UPNP_RESULT_SUCCESS:
				ok = true
				ip = u.query_external_address()
	call_deferred("_upnp_done", u, ok, ip)


func _upnp_done(u: UPNP, ok: bool, ip: String) -> void:
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if not is_server:
		_upnp_close_map(u)
		return
	_upnp = u
	upnp_state = "ok" if ok else "fail"
	upnp_ip = ip if ok else ""
	lobby_changed.emit()


func _upnp_close_map(u: UPNP) -> void:
	if u == null:
		return
	if _upnp_port > 0:
		u.delete_port_mapping(_upnp_port, "UDP")
		u.delete_port_mapping(_upnp_port + 1, "UDP")


## Sunucunun dışarıdan görünen adresi: UPnP varsa dış IP, yoksa yerel IP (çağıran verir).
func public_ip() -> String:
	return upnp_ip


func _exit_tree() -> void:
	if is_server and _upnp != null:
		_upnp_close_map(_upnp)


func _on_peer_connected(id: int) -> void:
	if is_server:
		_hello_t[id] = 0.0


func _on_peer_disconnected(id: int) -> void:
	if is_server:
		var p: Dictionary = players.get(id, {})
		var gone_cid: int = int(p.get("cid", -1))
		if started and room != null and gone_cid >= 0:
			room.set_afk(gone_cid, true)      # bağlantı koptu: yapay zekâ devralır
		_voice_remove(id)
		players.erase(id)
		_hello_t.erase(id)
		if started and room != null and gone_cid >= 0:
			_say("left", gone_cid)
		_reassign_host()
		_check_round()
		_push_lobby()
		_push_status()


@rpc("any_peer", "call_remote", "reliable")
func srv_hello(proto: int, pname: String, token: String = "") -> void:
	if not is_server:
		return
	var id: int = _sender()
	_hello_t.erase(id)
	if players.has(id):
		return                                   # ikinci selam: yok say
	if proto != PROTO:
		_to(id, "cli_denied", ["Sürüm uyuşmazlığı: sunucu ve oyun aynı sürümde olmalı."])
		return
	token = token.left(32)
	if started and not (token != "" and _seats.has(token)):
		_to(id, "cli_denied", ["Oyun başladı, bu odaya artık yeni oyuncu alınmıyor."])
		return
	if started and token != "" and _seats.has(token):
		# oyun sürüyor: bu cihazın eski koltuğuna geri dön
		var seat: Dictionary = _seats[token]
		for q in players.keys():
			if String(players[q].get("token", "")) == token:
				players.erase(q)
		players[id] = {"name": pname.left(24), "cid": int(seat.cid), "cname": String(seat.cname), "host": false, "pass_ok": true, "token": token}
		room.set_afk(int(seat.cid), false)
		room.missed[int(seat.cid)] = 0
		_send_state(id, "cli_start")
		_say("back", int(seat.cid))
		_push_lobby()
		_push_status()
		return
	if players.size() >= int(info.max):
		_to(id, "cli_denied", ["Sunucu dolu."])
		return
	var any_host := false
	for q in players.values():
		if bool(q.host):
			any_host = true
	players[id] = {"name": pname.left(24), "cid": -1, "host": not any_host, "pass_ok": String(info.pass) == "", "token": token}
	if String(info.pass) != "":
		_to(id, "cli_need_pass")
	else:
		_push_lobby()


@rpc("any_peer", "call_remote", "reliable")
func srv_pass(pw: String) -> void:
	if not is_server:
		return
	var id: int = _sender()
	if not players.has(id):
		return
	if pw == String(info.pass):
		players[id].pass_ok = true
		_push_lobby()
	else:
		_to(id, "cli_denied", ["Şifre yanlış."])


## Kurucu (ilk bağlanan) dünyayı sunucuda kurar: çağ + seçili ülkeler başlatılınca.
@rpc("any_peer", "call_remote", "reliable")
func srv_pick(cid: int, cname: String = "") -> void:
	if not is_server or started:
		return
	var id: int = _sender()
	if not players.has(id) or not bool(players[id].pass_ok):
		return
	if cid < 0 or cid >= MAX_COUNTRY_ID:
		return
	for p in players.values():
		if int(p.cid) == cid:
			return
	players[id].cid = cid
	players[id]["cname"] = cname.left(40)
	_push_lobby()


@rpc("any_peer", "call_remote", "reliable")
func srv_start() -> void:
	if not is_server or started:
		return
	var id: int = _sender()
	if not players.has(id) or not bool(players[id].host):
		return
	var picks: Array = []
	for p in players.values():
		if int(p.cid) >= 0 and bool(p.get("pass_ok", false)) and not picks.has(int(p.cid)):
			picks.append(int(p.cid))
	if picks.size() < 1:
		_to(id, "cli_denied", ["En az bir oyuncu ülke seçmeli."])
		return
	room = null
	_build_world(picks)
	if room == null or room.gs.humans.is_empty():
		room = null
		gs_server = null
		_to(id, "cli_denied", ["Seçilen ülkeler geçersiz."])
		return
	# dünyada geçersiz çıkan seçimler (yok olmuş/ayrılıkçı ülke) elenir
	var valid: Array = room.gs.humans
	_seats.clear()
	for pid in players.keys():
		var pc: int = int(players[pid].cid)
		if pc >= 0 and not valid.has(pc):
			players[pid].cid = -1
			players[pid]["cname"] = ""
		elif pc >= 0 and String(players[pid].get("token", "")) != "":
			_seats[String(players[pid].token)] = {"cid": pc, "cname": String(players[pid].get("cname", ""))}
	started = true
	_round_timer = float(info.secs)
	_flushed = false
	for pid in players.keys():
		if int(players[pid].cid) < 0:
			_to(pid, "cli_denied", ["Oyun başladı; ülke seçmediğin için bu turda yer alamıyorsun."])
			_kick(pid)
			continue
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
	var ok_picks: Array = []
	for pc in picks:
		if int(pc) >= 0 and int(pc) < g.countries.size() and g.countries[int(pc)].alive and not g.countries[int(pc)].is_rebel:
			ok_picks.append(int(pc))
	picks = ok_picks
	if picks.is_empty():
		return
	g.start_game(picks[0])
	if era != "":
		Eras.start(g, era)
	# oda kurucunun seçtiği senaryo (dönemin üstüne ya da serbest dünyaya) herkes için aynı başlangıç durumunu kurar
	var scn: String = String(info.get("scn", ""))
	if scn != "" and Scenarios.get_sc(scn).is_empty() and _scn_code != "":
		var U = load("res://scripts/user_scn.gd")
		var ud: Dictionary = U.import_code(_scn_code)
		if not ud.is_empty():
			ud["id"] = scn
			U.save(ud)
			Scenarios.reload()
	if scn != "" and not Scenarios.get_sc(scn).is_empty():
		Scenarios.apply(g, scn)
	g.scn_play = -1
	room = Room.new()
	room.setup(g, picks)
	gs_server = g


func _kick(pid: int) -> void:
	if pid == 1 or multiplayer.multiplayer_peer == null:
		return
	_voice_remove(pid)
	players.erase(pid)
	multiplayer.multiplayer_peer.disconnect_peer(pid)


func _send_state(pid: int, method: String) -> void:
	if not players.has(pid) or not bool(players[pid].get("pass_ok", false)) or int(players[pid].cid) < 0:
		return
	var d: Dictionary = gs_server.to_dict()
	# başka oyuncuya özel haberler bu oyuncuya gönderilmez
	var mine: int = int(players[pid].cid)
	var nl: Array = []
	for n in d.get("news", []):
		if not n.has("for") or int(n["for"]) == mine:
			nl.append(n)
	# tur sonunda yüzlerce dünya haberi son-80 penceresinden bu oyuncuya özel (diplomasi) haberleri dışarı itiyordu:
	# yakın turlardaki kişiye özel haberler her zaman eklenir
	var cur: int = gs_server.turn
	for n in gs_server.news_log:
		if n.has("for") and int(n["for"]) == mine and int(n.get("turn", 0)) >= cur - 2 and not nl.has(n):
			nl.append(n)
	d["news"] = nl
	d["armies"] = gs_server.fog_filter_armies(d["armies"], int(players[pid].cid), int(info.get("fog", 0)))
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	_to(pid, method, [raw, int(players[pid].cid), room.waiting_for(), String(info.era)])


## İstemci: bu turun komutlarını yollar. ready=true ise "turu bitirdim".
@rpc("any_peer", "call_remote", "reliable")
func srv_submit(turn: int, list: Array, is_ready: bool) -> void:
	if not is_server or not started or room == null:
		return
	var id: int = _sender()
	var p: Dictionary = players.get(id, {})
	if p.is_empty() or int(p.cid) < 0 or not bool(p.get("pass_ok", false)):
		return
	if turn != room.gs.turn:
		return                                   # eski turdan kalan gönderim (ağ gecikmesi): yok say
	if list.size() > MAX_CMDS:
		list = list.slice(0, MAX_CMDS)
	var was_afk: bool = bool(room.afk.get(int(p.cid), false))
	var was_ready: bool = bool(room.ready.get(int(p.cid), false))
	room.set_afk(int(p.cid), false)
	if was_afk:
		_say("back", int(p.cid))
	room.submit(int(p.cid), list)
	room.set_ready(int(p.cid), is_ready)
	if is_ready:
		room.missed[int(p.cid)] = 0
		if not was_ready:
			_say("ready", int(p.cid))
	_push_status()
	_check_round()


@rpc("any_peer", "call_remote", "reliable")
func srv_chat(text: String) -> void:
	if not is_server:
		return
	var id: int = _sender()
	if not bool(players.get(id, {}).get("pass_ok", false)):
		return
	var cid: int = int(players.get(id, {}).get("cid", -1))
	var pn: String = String(players.get(id, {}).get("name", ""))
	var t: String = text.strip_edges().left(200)
	if t == "":
		return
	# kim yazdığı her zaman görünsün: oyuncu adı (boşsa "Oyuncu") + ülke
	var cn: String = String(players.get(id, {}).get("cname", ""))
	if cn == "" and cid >= 0 and gs_server != null and cid < gs_server.countries.size():
		cn = String(gs_server.countries[cid].name)
	var shown: String = pn.strip_edges() if pn.strip_edges() != "" else "Oyuncu"
	if cn != "" and cn != shown:
		shown += " (" + cn + ")"
	for pid in players.keys():
		if bool(players[pid].get("pass_ok", false)):
			_to(pid, "cli_chat", [cid, shown, t])


func _check_round() -> void:
	if not is_server or not started or room == null:
		return
	if room.all_ready():
		_run_round()


## Süre doldu: hâlâ hazır olmayanlar bu turu kaçırdı; üst üste MISS_LIMIT kez kaçıran yapay zekâya devredilir.
func _force_round() -> void:
	if room == null:
		return
	var temp: Array = []
	for c in room.waiting_for():
		var n: int = int(room.missed.get(int(c), 0)) + 1
		room.missed[int(c)] = n
		if n >= MISS_LIMIT:
			room.set_afk(int(c), true)
			_say("afk", int(c))
		else:
			# bu tur ülkeyi yapay zekâ yönetir (oyuncu boşta kalmasın); sonra oyuncuya geri verilir
			room.set_afk(int(c), true)
			temp.append(int(c))
			_say("miss", int(c))
	_run_round()
	if room != null:
		for c in temp:
			room.set_afk(int(c), false)
	_push_status()


func _run_round() -> void:
	var r: Dictionary = room.process_round()
	_round_timer = float(info.secs)
	_grace_on = false
	_flushed = false
	for pid in players.keys():
		_send_state(pid, "cli_round")
	if String(r.get("over", "")) != "":
		for pid in players.keys():
			if bool(players[pid].get("pass_ok", false)):
				_to(pid, "cli_over", [String(r.over)])
		_reset_to_lobby()


## Oyun bitti: oda boşalır, kurucu yeni oyun başlatabilir (eski koltuklar silinir).
func _reset_to_lobby() -> void:
	started = false
	room = null
	gs_server = null
	_seats.clear()
	_grace_on = false
	for pid in players.keys():
		players[pid].cid = -1
		players[pid]["cname"] = ""


func _push_lobby() -> void:
	var list: Array = []
	for pid in players:
		var p: Dictionary = players[pid]
		list.append({"id": pid, "name": p.name, "cid": p.cid, "host": p.host, "cname": String(p.get("cname", ""))})
	for pid in players:
		if bool(players[pid].pass_ok):
			_to(pid, "cli_lobby", [info, list, started, pid])
	lobby_changed.emit()


## Geri sayım: tur süresi (secs>0) ve bekleme süresinden (biri bitirince) hangisi önce dolacaksa o.
func _deadline() -> Dictionary:
	var left := -1.0
	var grace := false
	if started and float(info.secs) > 0.0:
		left = maxf(_round_timer, 0.0)
	if _grace_on and (left < 0.0 or _grace_left < left):
		left = maxf(_grace_left, 0.0)
		grace = true
	return {"left": left, "grace": grace}


func _push_status() -> void:
	var w: Array = room.waiting_for() if room != null else []
	var afk: Array = []
	if room != null:
		for h in room.gs.humans:
			if bool(room.afk.get(h, false)):
				afk.append(h)
	var d: Dictionary = _deadline()
	for pid in players.keys():
		if bool(players[pid].get("pass_ok", false)):
			_to(pid, "cli_status", [w, float(d.left), afk, bool(d.grace)])


## Herkese oyuncu olayı yollar (istemci bayraklı şeritte gösterir).
func _say(kind: String, cid: int, text: String = "") -> void:
	if room != null and gs_server != null and cid >= 0 and cid < gs_server.countries.size():
		var nm: String = String(gs_server.countries[cid].name)
		var line := ""
		match kind:
			"left":
				line = "%s oyundan ayrıldı; ülkesini yapay zekâ yönetiyor." % nm
			"afk":
				line = "%s art arda turları kaçırdı; ülkesini yapay zekâ yönetiyor." % nm
			"back":
				line = "%s oyuna geri döndü." % nm
		if line != "":
			gs_server.news_bias = 1          # bir sonraki tur raporunda görünsün
			gs_server.post_news(line, -1, "info")
			gs_server.news_bias = 0
	for pid in players.keys():
		if bool(players[pid].get("pass_ok", false)):
			_to(pid, "cli_note", [kind, cid, text])



## Kurucu çıkarsa sıradaki bağlı oyuncu kurucu olur (yoksa kimse oyunu başlatamazdı).
func _reassign_host() -> void:
	for q in players.values():
		if bool(q.host):
			return
	for q in players.values():
		if bool(q.get("pass_ok", false)):
			q.host = true
			return


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
		_st_t += delta
		if _st_t >= 2.0 and started and room != null:
			_st_t = 0.0
			_push_status()
		_lan_t += delta
		if _lan_t >= 1.0 and _lan_udp != null:
			_lan_t = 0.0
			var n: int = 0
			for p in players.values():
				n += 1
			var beacon := "AOD|%d|%s|%s|%d|%d|%d|%s" % [PROTO, String(info.name).replace("|", " "), String(info.era), n, int(info.max), int(info.port), "1" if String(info.pass) != "" else "0"]
			var data := beacon.to_utf8_buffer()
			for t in _lan_targets():
				_lan_udp.set_dest_address(t, LAN_PORT)
				_lan_udp.put_packet(data)
		for hp in _hello_t.keys():
			_hello_t[hp] += delta
			if _hello_t[hp] > HELLO_SECS and not players.has(hp):
				_hello_t.erase(hp)
				if multiplayer.multiplayer_peer != null:
					multiplayer.multiplayer_peer.disconnect_peer(int(hp))
		if started and room != null and room.active_count() > 0:
			var w: Array = room.waiting_for()
			# biri turu bitirdi, diğerleri hâlâ oynuyor: bekleme süresi başlar
			if not _grace_on and not w.is_empty() and w.size() < room.active_count():
				_grace_on = true
				_grace_left = GRACE_SECS
				_say("grace", int(w[0]), str(int(GRACE_SECS)))
				_push_status()
			elif _grace_on and w.is_empty():
				_grace_on = false
			if _grace_on:
				_grace_left -= delta
			if float(info.secs) > 0.0:
				_round_timer -= delta
			if (_grace_on and _grace_left <= 0.0) or (float(info.secs) > 0.0 and _round_timer <= 0.0):
				# süre doldu: hazır olmayanın emirleri o ana kadar gönderdiği kadar, tur işlenir
				_force_round()
			elif not _flushed and not w.is_empty():
				# süre dolmak üzere: bekleyenlerin yerelde biriken emirlerini sunucuya yollatır (kaybolmasın)
				var lf: float = 999999.0
				if float(info.secs) > 0.0:
					lf = _round_timer
				if _grace_on:
					lf = minf(lf, _grace_left)
				if lf <= FLUSH_SECS:
					_flushed = true
					for pid in players.keys():
						if int(players[pid].get("cid", -1)) >= 0 and w.has(int(players[pid].cid)):
							_to(pid, "cli_flush")
	if _lan_listen != null:
		while _lan_listen.get_available_packet_count() > 0:
			var pkt: PackedByteArray = _lan_listen.get_packet()
			var ip: String = _lan_listen.get_packet_ip()
			var s: String = pkt.get_string_from_utf8()
			var f: PackedStringArray = s.split("|")
			if f.size() >= 8 and f[0] == "AOD":
				lan_found["%s:%s" % [ip, f[6]]] = {"proto": int(f[1]), "name": f[2], "era": f[3], "players": int(f[4]), "max": int(f[5]), "port": int(f[6]), "pass": f[7] == "1", "ip": ip, "t": Time.get_ticks_msec()}


# ======================================================================= istemci

var last_addr := ""
var last_port := DEFAULT_PORT
var _ever_connected := false
var _tried_local := false


func join(addr: String, port: int = DEFAULT_PORT) -> bool:
	last_addr = addr
	last_port = port
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_client(addr, port)
	if err != OK:
		error.emit("Bağlantı kurulamadı.")
		return false
	multiplayer.multiplayer_peer = peer
	is_server = false
	_attempt += 1
	_watch(_attempt)
	return true


var _attempt := 0

## ENet bağlantı hatasını ~30 sn sonra bildirir; çok uzun. 6 sn içinde bağlanılamazsa kendimiz vazgeçeriz.
func _watch(n: int) -> void:
	await get_tree().create_timer(6.0).timeout
	if n != _attempt or connected or is_server or multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	if not _ever_connected and last_addr != "127.0.0.1" and not _tried_local:
		_tried_local = true
		join("127.0.0.1", last_port)
		return
	error.emit("Sunucuya bağlanılamadı.")
	disconnected.emit()


func leave() -> void:
	_ever_connected = false
	_tried_local = false
	_attempt += 1
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	connected = false
	started = false
	is_server = false
	room = null
	gs_server = null
	players = {}
	_seats.clear()
	_hello_t.clear()
	chat_log = []
	_grace_on = false
	_flushed = false
	afk_ids = []
	waiting = []
	deadline_left = 0.0
	deadline_grace = false
	if _upnp_thread != null:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if _upnp != null:
		_upnp_close_map(_upnp)
		_upnp = null
	upnp_state = ""
	upnp_ip = ""
	if _lan_udp != null:
		_lan_udp.close()
		_lan_udp = null
	if _q_srv != null:
		_q_srv.stop()
		_q_srv = null


## Yayın hedefleri: genel yayın + her yerel IPv4 arayüzünün /24 yayın adresi (çok kartlı PC'lerde 255.255.255.255 yanlış karta gidebilir).
func _lan_targets() -> Array:
	var out: Array = ["255.255.255.255"]
	for a in IP.get_local_addresses():
		var f: PackedStringArray = String(a).split(".")
		if f.size() != 4 or f[0] == "127" or (f[0] == "169" and f[1] == "254"):
			continue
		var t := "%s.%s.%s.255" % [f[0], f[1], f[2]]
		if not out.has(t):
			out.append(t)
	return out


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
func cli_status(wait: Array, left: float, afk: Array = [], grace: bool = false) -> void:
	waiting = wait
	deadline_left = left
	deadline_grace = grace
	afk_ids = afk
	status_changed.emit()


@rpc("authority", "call_remote", "reliable")
func cli_flush() -> void:
	flush_asked.emit()


@rpc("authority", "call_remote", "reliable")
func cli_note(kind: String, cid: int, text: String) -> void:
	note.emit(kind, cid, text)



@rpc("authority", "call_remote", "reliable")
func cli_chat(cid: int, pname: String, text: String) -> void:
	chat_log.append({"cid": cid, "name": pname, "text": text})
	if chat_log.size() > 60:
		chat_log = chat_log.slice(chat_log.size() - 60)
	chat.emit(cid, pname, text)


@rpc("authority", "call_remote", "reliable")
func cli_over(text: String) -> void:
	over.emit(text)


func _apply_state(raw: PackedByteArray, cid: int, wait: Array, era: String) -> void:
	var d = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(int(d.get("seed", 0)))
	g.from_dict(d)
	g.net_humans = g.humans.duplicate()
	g.humans = []
	my_cid = cid
	waiting = wait
	gs_client = g



# ------------------------------------------------------------------ sesli görüşme odası
# Sunucu yalnızca ses paketlerini aynı görüşme odasındakilere iletir (8 bit µ-law, 16 kHz, tek kanal).
var voice_groups: Dictionary = {}     # sunucu: gid -> [peer id]
var voice_of: Dictionary = {}         # sunucu: peer id -> gid
var _voice_next := 1
var voice_gid := 0                    # istemci: içinde olduğum görüşme (0 = yok)
var voice_members: Array = []         # istemci: görüşmedeki ülke numaraları
const VOICE_MAX := 6


func _peer_of_cid(cid: int) -> int:
	for pid in players.keys():
		if int(players[pid].get("cid", -1)) == cid and bool(players[pid].get("pass_ok", false)):
			return int(pid)
	return -1


func _voice_cid(id: int) -> int:
	return int(players.get(id, {}).get("cid", -1))


func _voice_push(gid: int) -> void:
	var peers: Array = voice_groups.get(gid, [])
	var cids: Array = []
	for pid in peers:
		cids.append(_voice_cid(int(pid)))
	for pid in peers:
		_to(int(pid), "cli_voice_state", [gid, cids])


func _voice_remove(id: int) -> void:
	if not is_server or not voice_of.has(id):
		return
	var gid: int = int(voice_of[id])
	voice_of.erase(id)
	var peers: Array = voice_groups.get(gid, [])
	peers.erase(id)
	_to(id, "cli_voice_state", [0, []])
	if peers.size() <= 1:
		for pid in peers:
			voice_of.erase(pid)
			_to(int(pid), "cli_voice_state", [0, []])
		voice_groups.erase(gid)
	else:
		voice_groups[gid] = peers
		_voice_push(gid)


@rpc("any_peer", "call_remote", "reliable")
func srv_voice_invite(target_cid: int) -> void:
	if not is_server:
		return
	var id: int = _sender()
	var my: int = _voice_cid(id)
	if my < 0 or not bool(players.get(id, {}).get("pass_ok", false)):
		return
	var tp: int = _peer_of_cid(target_cid)
	if tp < 0 or tp == id:
		return
	var gid: int = int(voice_of.get(id, 0))
	if gid == 0:
		gid = _voice_next
		_voice_next += 1
		voice_groups[gid] = [id]
		voice_of[id] = gid
		_to(id, "cli_voice_state", [gid, [my]])
	_to(tp, "cli_voice_invite", [my, String(players[id].get("name", "")), gid])


@rpc("any_peer", "call_remote", "reliable")
func srv_voice_accept(gid: int) -> void:
	if not is_server:
		return
	var id: int = _sender()
	if _voice_cid(id) < 0 or not voice_groups.has(gid):
		return
	if int(voice_of.get(id, 0)) == gid:
		return
	_voice_remove(id)
	var peers: Array = voice_groups[gid]
	if peers.size() >= VOICE_MAX:
		return
	peers.append(id)
	voice_groups[gid] = peers
	voice_of[id] = gid
	_voice_push(gid)


@rpc("any_peer", "call_remote", "reliable")
func srv_voice_leave() -> void:
	if is_server:
		_voice_remove(_sender())


@rpc("any_peer", "call_remote", "unreliable")
func srv_voice(data: PackedByteArray) -> void:
	if not is_server or data.size() == 0 or data.size() > 2000:
		return
	var id: int = _sender()
	var gid: int = int(voice_of.get(id, 0))
	if gid == 0:
		return
	var cid: int = _voice_cid(id)
	for pid in voice_groups.get(gid, []):
		if int(pid) != id:
			_to(int(pid), "cli_voice", [cid, data])


@rpc("authority", "call_remote", "reliable")
func cli_voice_invite(from_cid: int, from_name: String, gid: int) -> void:
	voice_invite.emit(from_cid, from_name, gid)


@rpc("authority", "call_remote", "reliable")
func cli_voice_state(gid: int, cids: Array) -> void:
	voice_gid = gid
	voice_members = cids
	voice_state.emit()


@rpc("authority", "call_remote", "unreliable")
func cli_voice(from_cid: int, data: PackedByteArray) -> void:
	voice_audio.emit(from_cid, data)
