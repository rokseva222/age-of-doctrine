extends Node
## Ana liste (master) sunucusu istemcisi: sunucu listesini çeker; sunucu sahibi için heartbeat gönderir.
## Adres Settings'te saklanır; boşsa varsayılan MASTER_URL kullanılır (yayın öncesi gerçek adres yazılır).

const MASTER_URL := "https://master.example.invalid"     # Kendi liste sunucunu kurunca buraya (ya da oyunda Çok Oyunculu → Online → alttaki alana) yaz
## Sabit topluluk sunucuları listesi: depodaki server/servers.json dosyası (ana liste sunucusu olmadan da çalışır).
const STATIC_URL := "https://raw.githubusercontent.com/rokseva222/age-of-doctrine/main/server/servers.json"
const Settings = preload("res://scripts/settings.gd")

signal list_ready(servers: Array)
signal failed(msg: String)

var url := MASTER_URL
var _req: HTTPRequest
var _sreq: HTTPRequest
var _dyn: Array = []
var _stat: Array = []
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
	if not _configured():
		_dyn = []
		return
	_req.cancel_request()
	var err: int = _req.request(_base() + "/servers")
	if err != OK:
		failed.emit("Liste alınamadı.")


func _emit_all() -> void:
	var all: Array = _dyn.duplicate()
	for s in _stat:
		all.append(s)
	list_ready.emit(all)


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
		return
	_beat()
	_hb_timer.start()


func stop_announce() -> void:
	_hb_timer.stop()
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
