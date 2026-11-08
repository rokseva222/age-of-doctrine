extends RefCounted
## AP için dış servis köprüsü: ödüllü reklam ve Google Play satın alma.
## - Hata ayıklama (debug) yapılarında ve editörde "sahte" sağlayıcı çalışır: reklam hemen ödül verir, satın alma hemen başarılı olur.
## - Yayın (release) yapısında addon yoksa ikisi de "kullanılamıyor" döner: bedava AP / bedava içerik ASLA verilmez.
## - Gerçek servisler res://addons/ altındaki eklentilerle bağlanır (bkz. scripts/bridge_play.gd, README "Satın alma ve reklam kurulumu").
## Geri çağırma biçimi: cb.call(ok: bool, info: Variant, msg: String)  — info: satın almada {"token": String, "consumable": bool}.

const PLAY_BILLING_DIR := "res://addons/GodotGooglePlayBilling/BillingClient.gd"
const BRIDGE := "res://scripts/bridge_play.gd"

static var force_release := false      # test: yayın yapısını taklit eder
static var _bridge = null
static var _bridge_tried := false


static func dev_mode() -> bool:
	return not force_release and (OS.is_debug_build() or OS.has_feature("editor"))


static func _get_bridge():
	if _bridge_tried:
		return _bridge
	_bridge_tried = true
	if FileAccess.file_exists(PLAY_BILLING_DIR) or ResourceLoader.exists(PLAY_BILLING_DIR):
		var scr = load(BRIDGE)
		if scr != null:
			_bridge = scr.new()
	return _bridge


static func billing_ready() -> bool:
	return dev_mode() or _get_bridge() != null


static func ads_ready() -> bool:
	if dev_mode():
		return true
	var b = _get_bridge()
	return b != null and b.has_method("show_rewarded") and b.call("ads_ready")


## Gerçek yerel fiyat (Play'den); yoksa boş döner ve arayüz yedek fiyatı gösterir.
static func price_of(pid: String) -> String:
	var b = _get_bridge()
	if b != null and b.has_method("price_of"):
		return String(b.call("price_of", pid))
	return ""


static func show_rewarded(cb: Callable) -> void:
	if dev_mode():
		cb.call(true, null, "")
		return
	var b = _get_bridge()
	if b == null or not b.has_method("show_rewarded"):
		cb.call(false, null, "Reklam şu an yok.")
		return
	b.call("show_rewarded", cb)


## consumable: AP paketi gibi tekrar alınabilen ürün mü (Play'de tüketilir)
static func purchase(pid: String, consumable: bool, cb: Callable) -> void:
	if dev_mode():
		cb.call(true, {"token": "dev_%d_%s" % [Time.get_ticks_usec(), pid], "consumable": consumable}, "")
		return
	var b = _get_bridge()
	if b == null:
		cb.call(false, null, "Mağaza bu sürümde bağlı değil.")
		return
	b.call("purchase", pid, consumable, cb)


## Daha önce alınmış tek seferlik ürünleri geri getirir: cb.call(true, [pid, ...], "")
static func restore(cb: Callable) -> void:
	if dev_mode():
		cb.call(true, [], "")
		return
	var b = _get_bridge()
	if b == null:
		cb.call(false, [], "Mağaza bu sürümde bağlı değil.")
		return
	b.call("restore", cb)
