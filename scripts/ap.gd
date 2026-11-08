extends RefCounted
## AOD Puanı (AP): tek, kalıcı, güç satmayan oyun içi puan.
## Kazanma: ödüllü reklam (günlük tavan), günlük ödül, görev, başarım, ilk zafer. Satın alma: AP paketleri (Play).
## Harcama: senaryo/çağ açma, ek kayıt yuvası. AP ASLA ordu, para, teknoloji ya da zorluk rahatlığı satmaz.
## Tek kova: reklamdan, paketten ve oyundan gelen AP ayırt edilmez. Süre sınırı (son kullanma) yoktur.

const Settings = preload("res://scripts/settings.gd")
const Provider = preload("res://scripts/ap_provider.gd")
const EraExt = preload("res://scripts/era_ext.gd")

# --- ekonomi sabitleri (tek yerden ayarlanır)
const AD_REWARD := 5
const BONUS_AD_REWARD := 12            # günde bir kez "günlük bonus" reklamı
const AD_DAILY_CAP := 6                # bonus reklam da bu sayıya dahildir
const AD_COOLDOWN := 1200              # reklamlar arası en az 20 dk
const AD_COOLDOWN_DEV := 4
const LOGIN_REWARD := 3
const LOGIN_WEEK_REWARD := 15          # her 7. ödül günü
const MISSION_DAILY := 5
const MISSION_WEEKLY := 25
const MISSION_DAILY_ALL := 10
const MISSION_WEEKLY_ALL := 50
const ACH_REWARD := 20
const TUT_REWARD := 5
const WIN_FREE := 40
const WIN_SCENARIO := 60
const WIN_ERA := 100
const WIN_NEW_DIFFICULTY := 25
const WIN_REPLAY_FRAC := 0.2           # aynı yerde tekrar zafer: ilk ödülün %20'si (farm önleme)
const PRICE_SCENARIO := 400
const PRICE_ERA := 600
const PRICE_SLOTS := 100
const EXTRA_SLOTS := 2

# Ücretsiz içerik; kalanı AP ile ya da Tam Sürüm ile açılır.
const FREE_SCENARIOS := ["free", "ukr", "twn"]
const FREE_ERAS := ["ww1"]
# Lansman kampanyası: bu tarihe (UTC, 2027-03-01) kadar Bağımsızlık Yolu'nu açan herkese "Kurucu Erişimi" (kalıcı) verilir; sonra AP/ürünle açılır.
const LAUNCH_END := 1803859200
# Lansman süresi: bu tarihe (UTC, 2027-01-31) kadar bütün çağlar ve senaryolar herkese açık; sonra AP/ürünle açılır.
const PROMO_END := 1801353600

# Play Console ürün kimlikleri. consumable: Play'de tüketilir (tekrar alınabilir).
const PACKS := [
	{"id": "ap_100", "ap": 100, "usd": "0,99 $"},
	{"id": "ap_250", "ap": 250, "usd": "2,49 $"},
	{"id": "ap_600", "ap": 600, "usd": "4,99 $"},
	{"id": "ap_1250", "ap": 1250, "usd": "9,99 $"},
]
const STARTER := {"id": "starter", "ap": 250, "usd": "1,99 $"}     # tek seferlik başlangıç teklifi (süresiz)
const FULL := {"id": "full_game", "usd": "9,99 $"}                   # tüm senaryolar + çağlar, tek seferlik
const USD_SCENARIO := "3,49 $"
const USD_ERA := "4,99 $"

static var cur_key := "free"            # şu an oynanan senaryo/çağ (zafer ödülü için)


# ------------------------------------------------------------------ durum

static func _d() -> Dictionary:
	return Settings.ap


static func _save() -> void:
	Settings.save_all()


static func today() -> int:
	var bias: float = float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
	return int((Time.get_unix_time_from_system() + bias) / 86400.0)


static func balance() -> int:
	return int(_d().get("bal", 0))


static func earn(n: int, why: String = "") -> void:
	if n <= 0:
		return
	var d := _d()
	d["bal"] = int(d.get("bal", 0)) + n
	d["earned"] = int(d.get("earned", 0)) + n
	Settings.ap = d
	_save()


static func can_afford(n: int) -> bool:
	return balance() >= n


static func spend(n: int, why: String = "") -> bool:
	if n <= 0 or balance() < n:
		return false
	var d := _d()
	d["bal"] = int(d.get("bal", 0)) - n
	d["spent"] = int(d.get("spent", 0)) + n
	Settings.ap = d
	_save()
	return true


# ------------------------------------------------------------------ sahiplik

static func owns(id: String) -> bool:
	return bool((_d().get("owned", {}) as Dictionary).get(id, false))


static func grant(id: String) -> void:
	var d := _d()
	var o: Dictionary = d.get("owned", {})
	o[id] = true
	d["owned"] = o
	Settings.ap = d
	_save()


## Geliştirici anahtarı: yalnızca debug/editör yapısında tüm içeriği açar.
static func dev_all() -> bool:
	return Provider.dev_mode() and bool(_d().get("dev_all", false))


static func set_dev_all(on: bool) -> void:
	var d := _d()
	d["dev_all"] = on
	Settings.ap = d
	_save()


static var promo_off := false        # testler için: lansman açıklığını kapatır

static func promo_active() -> bool:
	return not promo_off and Time.get_unix_time_from_system() < float(PROMO_END)


static func promo_days_left() -> int:
	return maxi(0, int(ceil((float(PROMO_END) - Time.get_unix_time_from_system()) / 86400.0)))


static func has_full() -> bool:
	return owns("full") or dev_all()


static func scenario_unlocked(sid: String) -> bool:
	return promo_active() or FREE_SCENARIOS.has(sid) or sid.begins_with("u_") or has_full() or owns("scn_" + sid)


static func era_unlocked(eid: String) -> bool:
	if promo_active() or eid == "" or FREE_ERAS.has(eid) or has_full() or owns("era_" + eid):
		return true
	if EraExt.has_era(eid):
		if EraExt.is_free(eid):
			return true
		var pk: String = EraExt.pack(eid)
		if pk != "" and owns("era_pack_" + pk):
			return true
	return false


## Çağ kartından açılırken satın alınacak ürün: paketli çağlar paketin kimliğiyle ve adıyla açılır
static func unlock_id_for_era(eid: String) -> String:
	var pk: String = EraExt.pack(eid) if EraExt.has_era(eid) else ""
	return ("pack_" + pk) if pk != "" else eid


## Oyun kipleri (şimdilik yalnız "indep"): lansman süresince ücretsiz ve kalıcı, sonra kilitli.
static func mode_unlocked(id: String) -> bool:
	if has_full() or owns("mode_" + id):
		return true
	if Time.get_unix_time_from_system() < LAUNCH_END:
		grant("mode_" + id)
		var d := _d()
		d["founder"] = true
		Settings.ap = d
		_save()
		return true
	return false


static func is_founder() -> bool:
	return bool(_d().get("founder", false))


static func slot_bonus() -> int:
	return EXTRA_SLOTS if (owns("slots") or has_full()) else 0


## Açma: AP ile. Dönüş: true = açıldı.
static func unlock_with_ap(kind: String, id: String) -> bool:
	var price: int = PRICE_SCENARIO if kind == "scn" else PRICE_ERA
	if kind == "slots":
		price = PRICE_SLOTS
	if owns(kind + "_" + id) or (kind == "slots" and owns("slots")):
		return true
	if not spend(price, "unlock_" + kind):
		return false
	grant("slots" if kind == "slots" else kind + "_" + id)
	return true


static func price_of_unlock(kind: String) -> int:
	return PRICE_SCENARIO if kind == "scn" else (PRICE_ERA if (kind == "era" or kind == "mode") else PRICE_SLOTS)


# ------------------------------------------------------------------ reklam

static func _ad_state() -> Dictionary:
	var d := _d()
	if int(d.get("ad_day", -1)) != today():
		d["ad_day"] = today()
		d["ad_n"] = 0
		d["ad_bonus"] = false
		Settings.ap = d
	return d


static func ads_left() -> int:
	return maxi(0, AD_DAILY_CAP - int(_ad_state().get("ad_n", 0)))


## kalan bekleme saniyesi (0 = hazır)
static func ad_wait() -> int:
	var d := _ad_state()
	var cd: int = AD_COOLDOWN_DEV if Provider.dev_mode() else AD_COOLDOWN
	var since: float = Time.get_unix_time_from_system() - float(d.get("ad_last", 0))
	if since < 0.0:      # cihaz saati geri alınmış: bekleme süresini aşırı uzatma
		return cd
	return maxi(0, int(ceil(cd - since)))


static func bonus_ad_ready() -> bool:
	return not bool(_ad_state().get("ad_bonus", false)) and ads_left() > 0


static func ad_available() -> bool:
	return ads_left() > 0 and ad_wait() == 0 and Provider.ads_ready()


## bonus: günlük bonus reklamı. cb.call(ok: bool, gained: int, msg: String)
static func watch_ad(bonus: bool, cb: Callable) -> void:
	if ads_left() <= 0:
		cb.call(false, 0, "Bugünlük reklam hakkın bitti.")
		return
	if ad_wait() > 0:
		cb.call(false, 0, "Sonraki reklam için biraz bekle.")
		return
	if bonus and not bonus_ad_ready():
		cb.call(false, 0, "Günlük bonus bugün alındı.")
		return
	Provider.show_rewarded(func(ok: bool, _info, msg: String):
		if not ok:
			cb.call(false, 0, msg if msg != "" else "Reklam tamamlanmadı.")
			return
		var d := _ad_state()
		d["ad_n"] = int(d.get("ad_n", 0)) + 1
		d["ad_last"] = int(Time.get_unix_time_from_system())
		if bonus:
			d["ad_bonus"] = true
		Settings.ap = d
		var gain: int = BONUS_AD_REWARD if bonus else AD_REWARD
		earn(gain, "ad")
		cb.call(true, gain, ""))


# ------------------------------------------------------------------ günlük ödül (birikimli sayaç, seri cezası yok)

static func login_claimable() -> bool:
	return int(_d().get("login_day", -1)) != today()


static func login_next_reward() -> int:
	return LOGIN_WEEK_REWARD if (int(_d().get("login_n", 0)) + 1) % 7 == 0 else LOGIN_REWARD


static func login_count() -> int:
	return int(_d().get("login_n", 0))


static func claim_login() -> int:
	if not login_claimable():
		return 0
	var gain := login_next_reward()
	var d := _d()
	d["login_n"] = int(d.get("login_n", 0)) + 1
	d["login_day"] = today()
	Settings.ap = d
	earn(gain, "login")
	return gain


# ------------------------------------------------------------------ oyundan kazanma

static func goal_reward(kind: String) -> int:
	return ACH_REWARD if kind == "ach" else (TUT_REWARD if kind == "tut" else 0)


## Zafer ödülü. key: "free" / senaryo kimliği / çağ kimliği. Dönüş: kazanılan AP.
static func on_victory(key: String, difficulty: int) -> int:
	var base: int = WIN_FREE
	if key == "ww1" or key == "ww2" or key == "cw62" or key == "indep":
		base = WIN_ERA
	elif key != "free" and key != "":
		base = WIN_SCENARIO
	var d := _d()
	var wins: Dictionary = d.get("wins", {})
	var any_win := false
	for k in wins:
		if String(k).begins_with(key + ":"):
			any_win = true
			break
	var wk := "%s:%d" % [key, difficulty]
	var gain := 0
	if not any_win:
		gain = base
	elif not wins.has(wk):
		gain = WIN_NEW_DIFFICULTY
	else:
		gain = int(round(base * WIN_REPLAY_FRAC))
	wins[wk] = true
	d["wins"] = wins
	Settings.ap = d
	earn(gain, "win")
	return gain


# ------------------------------------------------------------------ satın alma

static func product_for(pid: String) -> Dictionary:
	for p in PACKS:
		if p.id == pid:
			return p
	if pid == STARTER.id:
		return STARTER
	return {}


static func starter_available() -> bool:
	return not owns("starter")


static func _seen_token(tok: String) -> bool:
	return (_d().get("tokens", []) as Array).has(tok)


static func _remember_token(tok: String) -> void:
	var d := _d()
	var arr: Array = d.get("tokens", [])
	arr.append(tok)
	if arr.size() > 60:
		arr = arr.slice(arr.size() - 60)
	d["tokens"] = arr
	Settings.ap = d


## Ürünü teslim eder. Aynı satın alma jetonu iki kez işlenmez. Dönüş: eklenen AP (paketler için).
static func fulfill(pid: String, token: String) -> int:
	if token != "":
		if _seen_token(token):
			return 0
		_remember_token(token)
	var gain := 0
	var pk := product_for(pid)
	if not pk.is_empty():
		gain = int(pk.ap)
		if pid == STARTER.id:
			grant("starter")
		earn(gain, "iap")
	elif pid == FULL.id:
		grant("full")
	elif pid.begins_with("scn_") or pid.begins_with("era_"):
		grant(pid)
	elif pid == "slots":
		grant("slots")
	_save()
	return gain


## cb.call(ok: bool, gained_ap: int, msg: String)
static func purchase(pid: String, cb: Callable) -> void:
	var consumable := not product_for(pid).is_empty() and pid != STARTER.id
	Provider.purchase(pid, consumable, func(ok: bool, info, msg: String):
		if not ok:
			cb.call(false, 0, msg)
			return
		var tok := ""
		if info is Dictionary:
			tok = String(info.get("token", ""))
		cb.call(true, fulfill(pid, tok), ""))


## Tek seferlik ürünleri geri yükler. cb.call(ok: bool, restored: int, msg: String)
static func restore(cb: Callable) -> void:
	Provider.restore(func(ok: bool, info, msg: String):
		if not ok:
			cb.call(false, 0, msg)
			return
		var n := 0
		if info is Array:
			for pid in info:
				var id := String(pid)
				if id == "full_game":
					id = "full"
				if id == "starter" or id == "full" or id == "slots" or id.begins_with("scn_") or id.begins_with("era_"):
					if not owns(id):
						grant(id)
						n += 1
		cb.call(true, n, ""))
