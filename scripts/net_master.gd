extends Node
## Ana liste (master) sunucusu istemcisi: sunucu listesini çeker; sunucu sahibi için heartbeat gönderir.
## Adres Settings'te saklanır; boşsa varsayılan MASTER_URL kullanılır (yayın öncesi gerçek adres yazılır).

const MASTER_URL := "https://master.example.invalid"     # Kendi liste sunucunu kurunca buraya (ya da oyunda Çok Oyunculu → Online → alttaki alana) yaz
## Sabit topluluk sunucuları listesi: depodaki server/servers.json dosyası (ana liste sunucusu olmadan da çalışır).
const STATIC_URL := "https://raw.githubusercontent.com/rokseva222/age-of-doctrine/main/server/servers.json"
const Settings = preload("res://scripts/settings.gd")
## Ana liste sunucusu kurulmamış olsa bile çalışan herkese açık oda panosu (ntfy.sh konusu): odalar kendini buraya yazar, liste buradan okunur.
const FEED_URL := "https://ntfy.sh/aod-rooms-v1-k7q2x9"
const IP_URL := "https://api.ipify.org"
const FEED_BEAT := 240.0          # sn: ntfy ücretsiz kota için seyrek
const FEED_TTL := 660             # sn: bu kadar süredir duyuru yapmayan oda düşer

signal list_ready(servers: Array)
signal failed(msg: String)

var url := MASTER_URL
var _req: HTTPRequest
var _sreq: HTTPRequest
var _dyn: Array = []
var _stat: Array = []
var _feed: Array = []
var _freq: HTTPRequest
var _fpub: HTTPRequest
var _fip: HTTPRequest
var _feed_on := false
var _pub_ip := ""
var _feed_timer: Timer
var _hb: HTTPRequest
var _token := ""
var _hb_timer: Timer
var _hb_info: Dictionary = {}


func _ready() -> void:
	_req = HTTPRequest.new()
	_req.timeout = 8.0
	add_child(_req)
	_req.request_completed.connect(_on_list)
	_sreq = HTTPRequest.new()
	_sreq.timeout = 8.0
	add_child(_sreq)
	_sreq.request_completed.connect(_on_static)
	_freq = HTTPRequest.new()
	_freq.timeout = 8.0
	add_child(_freq)
	_freq.request_completed.connect(_on_feed)
	_fpub = HTTPRequest.new()
	_fpub.timeout = 8.0
	add_child(_fpub)
	_fip = HTTPRequest.new()
	_fip.timeout = 8.0
	add_child(_fip)
	_fip.request_completed.connect(_on_ip)
	_feed_timer = Timer.new()
	_feed_timer.wait_time = FEED_BEAT
	_feed_timer.timeout.connect(_feed_publish)
	add_child(_feed_timer)
	_hb = HTTPRequest.new()
	_hb.timeout = 8.0
	add_child(_hb)
	_hb.request_completed.connect(_on_hb)
	_hb_timer = Timer.new()
	_hb_timer.wait_time = 30.0
	_hb_timer.timeout.connect(_beat)
	add_child(_hb_timer)


func _base() -> String:
	var u: String = Settings.master_url.strip_edges() if Settings.master_url.strip_edges() != "" else url
	return u.trim_suffix("/")


func _configured() -> bool:
	var u: String = _base()
	return u != "" and not u.contains("example.invalid")


## Hem ana liste sunucusundan (ayarlıysa) hem depodaki sabit listeden sunucuları çeker; ikisi birleşik yayınlanır.
func fetch() -> void:
	_sreq.cancel_request()
	_sreq.request(STATIC_URL)
	_freq.cancel_request()
	_freq.request(FEED_URL + "/json?poll=1&since=15m")
	if not _configured():
		_dyn = []
		return
	_req.cancel_request()
	var err: int = _req.request(_base() + "/servers")
	if err != OK:
		failed.emit("Liste alınamadı.")


func _emit_all() -> void:
	var all: Array = _dyn.duplicate()
	var seen: Dictionary = {}
	for e in all:
		seen["%s:%d" % [e.ip, int(e.port)]] = true
	for s in _stat + _feed:
		var k := "%s:%d" % [s.ip, int(s.port)]
		if not seen.has(k):
			seen[k] = true
			all.append(s)
	list_ready.emit(all)


## ntfy akışı: satır başına bir JSON; "message" alanı bizim oda duyurumuz. Her oda için en yeni kayıt geçerli.
func parse_feed(text: String, now: int) -> Array:
	var latest: Dictionary = {}
	for line in text.split("\n"):
		if line.strip_edges() == "":
			continue
		var m = JSON.parse_string(line)
		if not (m is Dictionary) or not m.has("message"):
			continue
		var e = JSON.parse_string(String(m.message))
		if not (e is Dictionary) or String(e.get("k", "")) != "aod" or not e.has("ip") or not e.has("port"):
			continue
		var key := "%s:%d" % [e.ip, int(e.port)]
		if not latest.has(key) or int(e.get("t", 0)) >= int(latest[key].get("t", 0)):
			latest[key] = e
	var out: Array = []
	for k in latest:
		var e: Dictionary = latest[k]
		if bool(e.get("closed", false)) or now - int(e.get("t", 0)) > FEED_TTL:
			continue
		out.append({"name": String(e.get("name", "Oda")).left(40), "era": String(e.get("era", "")), "players": int(e.get("players", 0)), "max": int(e.get("max", 6)),
			"ip": String(e.ip), "port": int(e.port), "pass": bool(e.get("pass", false)), "region": String(e.get("region", "")), "ver": String(e.get("ver", ""))})
	return out


func _on_feed(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	_feed = parse_feed(body.get_string_from_utf8(), int(Time.get_unix_time_from_system()))
	_emit_all()


func _on_ip(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var ip: String = body.get_string_from_utf8().strip_edges()
		if ip.count(".") == 3 and ip.length() <= 15:
			_pub_ip = ip
	if _feed_on:
		_feed_publish()


func _feed_publish(closed: bool = false) -> void:
	var ip: String = _pub_ip
	if ip == "" or _hb_info.is_empty():
		return
	var b: Dictionary = _hb_info.duplicate()
	b["k"] = "aod"
	b["ip"] = ip
	b["t"] = int(Time.get_unix_time_from_system())
	b["closed"] = closed
	_fpub.cancel_request()
	_fpub.request(FEED_URL, ["Content-Type: text/plain"], HTTPClient.METHOD_POST, JSON.stringify(b))


func _on_static(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var j = JSON.parse_string(body.get_string_from_utf8())
	if not (j is Array):
		return
	_stat = []
	for e in j:
		if e is Dictionary and e.has("ip") and e.has("port"):
			_stat.append({"name": String(e.get("name", "Sunucu")), "era": String(e.get("era", "")), "players": int(e.get("players", 0)), "max": int(e.get("max", 6)),
				"ip": String(e.ip), "port": int(e.port), "pass": bool(e.get("pass", false)), "region": String(e.get("region", "")), "ver": String(e.get("ver", ""))})
	_emit_all()


func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Liste alınamadı.")
		return
	var j = JSON.parse_string(body.get_string_from_utf8())
	if j is Array:
		_dyn = j
		_emit_all()
	else:
		failed.emit("Liste okunamadı.")


## Sunucu sahibi: listede görünmek için kendini bildirir (30 sn'de bir).
func announce(info: Dictionary) -> void:
	_hb_info = info
	if not _configured():
		# ana liste sunucusu yok: herkese açık pano (ntfy) üzerinden duyur
		if not _feed_on:
			_feed_on = true
			_feed_timer.start()
			_fip.cancel_request()
			_fip.request(IP_URL)
		return
	_beat()
	_hb_timer.start()


func stop_announce() -> void:
	_hb_timer.stop()
	if _feed_on:
		_feed_on = false
		_feed_timer.stop()
		_feed_publish(true)
	if _token != "" and _configured():
		var h := ["Content-Type: application/json"]
		_hb.request(_base() + "/remove", h, HTTPClient.METHOD_POST, JSON.stringify({"token": _token}))
	_token = ""


func _beat() -> void:
	var b: Dictionary = _hb_info.duplicate()
	b["token"] = _token
	var h := ["Content-Type: application/json"]
	_hb.request(_base() + "/register", h, HTTPClient.METHOD_POST, JSON.stringify(b))


func _on_hb(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var j = JSON.parse_string(body.get_string_from_utf8())
		if j is Dictionary and j.has("token"):
			_token = String(j.token)
