extends RefCounted
## Google Play Billing köprüsü (GodotGooglePlayBilling eklentisi, Godot 4 sürümü).
## UYARI: Bu dosya eklenti olmadan çalıştırılamaz ve gerçek cihazda TEST EDİLMEMİŞTİR. Eklenti API'si sürümler arasında
## değişebilir; kurulumdan sonra eklentinin README'sine göre doğrulayın. Eklenti yoksa ap_provider.gd bu dosyayı hiç yüklemez.
## Eklentiyi kurunca: addons/GodotGooglePlayBilling/ klasörü + Proje > Dışa Aktar > Android > "Gradle Build" ve eklentiyi işaretle.
## Reklam: AdMob/AppLovin eklentisi kurulunca aşağıdaki show_rewarded içine bağlanır (şimdilik kapalı: ads_ready() = false).

const PRODUCT_IDS := ["ap_100", "ap_250", "ap_600", "ap_1250", "starter", "full_game", "slots"]
const CONSUMABLE := ["ap_100", "ap_250", "ap_600", "ap_1250"]

var _client = null
var _connected := false
var _prices: Dictionary = {}
var _pending_cb: Callable = Callable()
var _pending_pid := ""
var _pending_consumable := false
var _restore_cb: Callable = Callable()


func _init() -> void:
	var scr = load("res://addons/GodotGooglePlayBilling/BillingClient.gd")
	if scr == null:
		return
	_client = scr.new()
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(func(): _connected = false)
	_client.query_product_details_response.connect(_on_details)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.query_purchases_response.connect(_on_query_purchases)
	_client.consume_purchase_response.connect(func(_r): pass)
	_client.acknowledge_purchase_response.connect(func(_r): pass)
	_client.start_connection()


func ads_ready() -> bool:
	return false


func show_rewarded(cb: Callable) -> void:
	cb.call(false, null, "Reklam şu an yok.")


func price_of(pid: String) -> String:
	return String(_prices.get(pid, ""))


func _on_connected() -> void:
	_connected = true
	_client.query_product_details(PRODUCT_IDS, "inapp")


func _on_details(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) != 0:
		return
	for p in result.get("product_details", []):
		var offer = p.get("one_time_purchase_offer_details", {})
		_prices[String(p.get("product_id", ""))] = String(offer.get("formatted_price", ""))


func purchase(pid: String, consumable: bool, cb: Callable) -> void:
	if _client == null or not _connected:
		cb.call(false, null, "Mağazaya bağlanılamadı. İnternetini kontrol et.")
		return
	_pending_cb = cb
	_pending_pid = pid
	_pending_consumable = consumable
	_client.purchase(pid)


func _on_purchase_updated(result: Dictionary) -> void:
	if not _pending_cb.is_valid():
		return
	var cb := _pending_cb
	_pending_cb = Callable()
	if int(result.get("response_code", -1)) != 0:
		cb.call(false, null, "Satın alma tamamlanmadı.")
		return
	for pu in result.get("purchases", []):
		if not (pu.get("product_ids", []) as Array).has(_pending_pid):
			continue
		var token := String(pu.get("purchase_token", ""))
		# Önce teslim (cb), sonra Play'e onay/tüketim: 3 gün içinde onaylanmayan satın alma iade edilir.
		cb.call(true, {"token": token, "consumable": _pending_consumable}, "")
		if _pending_consumable:
			_client.consume_purchase(token)
		elif not bool(pu.get("is_acknowledged", false)):
			_client.acknowledge_purchase(token)
		return
	cb.call(false, null, "Satın alma doğrulanamadı.")


func restore(cb: Callable) -> void:
	if _client == null or not _connected:
		cb.call(false, [], "Mağazaya bağlanılamadı.")
		return
	_restore_cb = cb
	_client.query_purchases("inapp")


func _on_query_purchases(result: Dictionary) -> void:
	if not _restore_cb.is_valid():
		return
	var cb := _restore_cb
	_restore_cb = Callable()
	var ids: Array = []
	for pu in result.get("purchases", []):
		for pid in pu.get("product_ids", []):
			if not CONSUMABLE.has(String(pid)):
				ids.append(String(pid))
		var token := String(pu.get("purchase_token", ""))
		if not bool(pu.get("is_acknowledged", false)) and token != "":
			_client.acknowledge_purchase(token)
	cb.call(true, ids, "")
