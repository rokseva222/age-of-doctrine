extends Node
## Android yerel bildirimleri: devam eden bir oyun varken uygulama arka plana alınınca 5 saatte bir
## "ordun seni bekliyor" hatırlatması planlar; oyuna dönünce iptal eder.
## Eklenti: "Android Notification Scheduler" (AssetLib). Eklenti kurulu değilse (masaüstü/test) hiçbir şey yapmaz.

const NOTIF_ID := 7001
const CHANNEL := "aod_reminder"
const INTERVAL := 5 * 3600

var _sched: Node = null
var _ready_ok := false


func _ready() -> void:
	if not OS.has_feature("android"):
		return
	var path := _class_path("NotificationScheduler")
	if path == "":
		return
	_sched = load(path).new()
	add_child(_sched)
	if _sched.has_method("initialize"):
		_sched.call("initialize")
	var ch_path := _class_path("NotificationChannel")
	if ch_path != "":
		var ch = load(ch_path).new()
		ch.set_id(CHANNEL).set_name("Hatırlatmalar").set_description("Ordun seni bekliyor").set_importance(3)
		_sched.call("create_notification_channel", ch)
	_ready_ok = true


static func _class_path(cname: String) -> String:
	for d in ProjectSettings.get_global_class_list():
		if d.get("class", "") == cname:
			return str(d.get("path", ""))
	return ""


func available() -> bool:
	return _ready_ok


## Ayar açılırken izin ister (Android 13+).
func ask_permission() -> void:
	if _ready_ok and _sched.has_method("has_post_notifications_permission") and not _sched.call("has_post_notifications_permission"):
		_sched.call("request_post_notifications_permission")


func cancel() -> void:
	if _ready_ok:
		_sched.call("cancel", NOTIF_ID)


## message: bildirim metni (zaten çevrilmiş).
func schedule(title: String, message: String) -> void:
	if not _ready_ok:
		return
	var dp := _class_path("NotificationData")
	if dp == "":
		return
	var nd = load(dp).new()
	nd.set_id(NOTIF_ID).set_channel_id(CHANNEL).set_title(title).set_content(message).set_delay(INTERVAL).set_interval(INTERVAL)
	_sched.call("cancel", NOTIF_ID)
	_sched.call("schedule", nd)
