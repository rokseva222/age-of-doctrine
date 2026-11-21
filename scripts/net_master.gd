extends Node
## Ana liste (master) sunucusu istemcisi: sunucu listesini çeker; sunucu sahibi için heartbeat gönderir.
## Adres Settings'te saklanır; boşsa varsayılan MASTER_URL kullanılır (yayın öncesi gerçek adres yazılır).

const MASTER_URL := "https://master.example.invalid"     # TODO: yayın öncesi gerçek ana liste adresi

signal list_ready(servers: Array)
signal failed(msg: String)

var url := MASTER_URL
var _req: HTTPRequest
var _hb: HTTPRequest
var _token := ""
var _hb_timer: Timer
var _hb_info: Dictionary = {}


func _ready() -> void:
	_req = HTTPRequest.new()
	_req.timeout = 8.0
	add_child(_req)
	_req.request_completed.connect(_on_list)
	_hb = HTTPRequest.new()
	_hb.timeout = 8.0
	add_child(_hb)
	_hb.request_completed.connect(_on_hb)
	_hb_timer = Timer.new()
	_hb_timer.wait_time = 30.0
	_hb_timer.timeout.connect(_beat)
	add_child(_hb_timer)


func fetch() -> void:
	if url == "" or url.contains("example.invalid"):
		failed.emit("Ana liste adresi ayarlanmamış.")
		return
	_req.cancel_request()
	var err: int = _req.request(url.trim_suffix("/") + "/servers")
	if err != OK:
		failed.emit("Liste alınamadı.")


func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Liste alınamadı.")
		return
	var j = JSON.parse_string(body.get_string_from_utf8())
	if j is Array:
		list_ready.emit(j)
	else:
		failed.emit("Liste okunamadı.")


## Sunucu sahibi: listede görünmek için kendini bildirir (30 sn'de bir).
func announce(info: Dictionary) -> void:
	_hb_info = info
	if url == "" or url.contains("example.invalid"):
		return
	_beat()
	_hb_timer.start()


func stop_announce() -> void:
	_hb_timer.stop()
	if _token != "" and not url.contains("example.invalid"):
		var h := ["Content-Type: application/json"]
		_hb.request(url.trim_suffix("/") + "/remove", h, HTTPClient.METHOD_POST, JSON.stringify({"token": _token}))
	_token = ""


func _beat() -> void:
	var b: Dictionary = _hb_info.duplicate()
	b["token"] = _token
	var h := ["Content-Type: application/json"]
	_hb.request(url.trim_suffix("/") + "/register", h, HTTPClient.METHOD_POST, JSON.stringify(b))


func _on_hb(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var j = JSON.parse_string(body.get_string_from_utf8())
		if j is Dictionary and j.has("token"):
			_token = String(j.token)
