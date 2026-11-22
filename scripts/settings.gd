extends RefCounted
## Kalıcı oyun ayarları (user://settings.cfg). Tüm değerler statik; her yerden okunur.

const PATH := "user://settings.cfg"

static var music := 0.5
static var sfx := 0.6
static var master_url := ""                   # kullanıcının girdiği ana liste sunucusu adresi (boş = varsayılan)
static var net_token := ""                    # online yeniden bağlanma kimliği (rastgele, bu cihaza özel)
static var player_name := ""                  # online oyuncu adı
static var country_names := true
static var province_names := true
static var armies := true
static var navy := true       # deniz filosu rozetleri (duraklatma menüsünden)
static var air := true        # hava filosu rozetleri
static var autosave := true
static var cabinet := true            # kabine/danışman kartları
static var bulletin := true           # her turda Cihan Bülteni ekranı (kapalıyken yalnızca önemli turlarda ve 8 turda bir)
static var notifications := true       # 5 saatte bir "ordun seni bekliyor" bildirimi (Android)
static var language := ""             # "tr" / "en"; boşsa sistem dilinden seçilir
static var auto_orders := true        # emir vermediğin turda boştaki ordular otomatik görev alır
static var smooth := true
static var ui_scale := 1.0
static var ui_scale_custom := false   # kullanıcı kaydırıcıyı elle ayarladı mı (değilse ölçek cihaza göre her açılışta yeniden hesaplanır)
static var seen_howto := false
static var seen_promo := false
static var seen_update := ""            # son görülen "Neler yeni" sürümü
static var tut_done := false
static var missions: Dictionary = {}  # günlük/haftalık görevler (missions.gd)
static var xp := 0                    # Komutan Puanı
static var streak := 0                # üst üste gün serisi
static var streak_day := -1
static var ach: Dictionary = {}       # açılan başarımlar/öğretici adımlar: id -> tur
static var war_aggr := 1.0             # yapay zekânın savaş açma isteği çarpanı (0 = hiç savaş açmaz, 1 = normal)
static var era_peace := false           # 1. / 2. Dünya Savaşı senaryoları savaşsız (diplomatik) başlar
static var war_gate := true            # oyuncu savaş ilan etmek için ilişkiyi en çok %20'ye düşürmeli (öğretici/sandbox hariç)
static var difficulty := 1            # 0 kolay, 1 normal, 2 zor
static var sandbox := false            # sandbox modu: oyun menüsünde deneme araçları paneli
static var currency := true           # para birimi: oyuncunun ülkesinin parası (kapalıysa dolar)
static var fog := 0                   # savaş sisi: 0 kapalı (herkes görünür), 1 orta (yalnızca yakın ordular), 2 tam (yalnız kendi/müttefik)
static var daily: Dictionary = {}     # Günlük Meydan Okuma kaydı (daily.gd)
static var ap: Dictionary = {}        # AOD Puanı, satın alımlar, reklam sayaçları (ap.gd)


## Telefonda yatay yükseklik ≈ 720/ölçek birim: 0.8 ≈ 900 birim, panellerin (ör. taarruz penceresi) sığması için gerekli.
## Çok küçük ekranlarda dokunma hedefleri için biraz büyütülür.
static func default_scale() -> float:
	if not OS.has_feature("mobile"):
		return 0.8
	var dpi: int = DisplayServer.screen_get_dpi()
	var sz: Vector2i = DisplayServer.screen_get_size()
	# Bazı cihazlar kurulumdan hemen sonra DPI'yı hiç ya da saçma (ör. 0, 1, 1000+) bildirir:
	# o durumda fiziksel boyuta güvenmeyip sabit güvenli değer kullanılır.
	if dpi < 100 or dpi > 800 or sz.x <= 0 or sz.y <= 0:
		return 0.82
	var width_mm: float = float(maxi(sz.x, sz.y)) / float(dpi) * 25.4
	if width_mm < 80.0 or width_mm > 600.0:
		return 0.82
	return clampf(120.0 / width_mm, 0.75, 0.95)


## Kullanıcı elle ayarlamadıysa ölçeği cihazın o anki ekran bilgisine göre yeniden hesaplar (boyut değişince / ilk karede çağrılır).
static func refresh_auto_scale(tree: SceneTree) -> void:
	if ui_scale_custom:
		return
	var v: float = default_scale()
	if absf(v - ui_scale) > 0.001:
		ui_scale = v
		apply_display(tree)


static func load_all() -> void:
	ui_scale = default_scale()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	music = float(cf.get_value("audio", "music", music))
	sfx = float(cf.get_value("audio", "sfx", sfx))
	player_name = String(cf.get_value("net", "name", player_name))
	net_token = String(cf.get_value("net", "token", net_token))
	master_url = String(cf.get_value("net", "master", master_url))
	country_names = bool(cf.get_value("view", "country_names", country_names))
	province_names = bool(cf.get_value("view", "province_names", province_names))
	armies = bool(cf.get_value("view", "armies", armies))
	navy = bool(cf.get_value("view", "navy", navy))
	air = bool(cf.get_value("view", "air", air))
	smooth = bool(cf.get_value("view", "smooth", smooth))
	# sürüm 2: varsayılan ölçek küçüldü; eski kayıtlı (otomatik) değer bir kez yeni varsayılana çekilir
	# sürüm 3: yalnızca elle ayarlanmış ölçek saklanır; otomatik hesaplanan eski değerler (kurulumda yanlış DPI ile kaydedilmiş olabilir) atılır
	ui_scale_custom = bool(cf.get_value("view", "ui_scale_custom", false)) and int(cf.get_value("view", "ui_scale_ver", 1)) >= 3
	if ui_scale_custom:
		ui_scale = clampf(float(cf.get_value("view", "ui_scale", ui_scale)), 0.6, 1.4)
	autosave = bool(cf.get_value("game", "autosave", autosave))
	cabinet = bool(cf.get_value("game", "cabinet", cabinet))
	bulletin = bool(cf.get_value("game", "bulletin", bulletin))
	auto_orders = bool(cf.get_value("game", "auto_orders", auto_orders))
	fog = clampi(int(cf.get_value("game", "fog", fog)), 0, 2)
	currency = bool(cf.get_value("game", "currency", currency))
	sandbox = bool(cf.get_value("game", "sandbox", sandbox))
	notifications = bool(cf.get_value("game", "notifications", notifications))
	language = str(cf.get_value("game", "language", language))
	seen_howto = bool(cf.get_value("game", "seen_howto", seen_howto))
	seen_promo = bool(cf.get_value("game", "seen_promo", seen_promo))
	seen_update = str(cf.get_value("game", "seen_update", seen_update))
	tut_done = bool(cf.get_value("game", "tut_done", tut_done))
	difficulty = clampi(int(cf.get_value("game", "difficulty", difficulty)), 0, 2)
	war_aggr = clampf(float(cf.get_value("game", "war_aggr", war_aggr)), 0.0, 1.0)
	war_gate = bool(cf.get_value("game", "war_gate", war_gate))
	era_peace = bool(cf.get_value("game", "era_peace", era_peace))
	var a = cf.get_value("game", "ach", {})
	ach = a.duplicate() if a is Dictionary else {}
	var mm = cf.get_value("game", "missions", {})
	missions = mm.duplicate(true) if mm is Dictionary else {}
	xp = int(cf.get_value("game", "xp", 0))
	streak = int(cf.get_value("game", "streak", 0))
	streak_day = int(cf.get_value("game", "streak_day", -1))
	var apv = cf.get_value("game", "ap", {})
	ap = apv.duplicate(true) if apv is Dictionary else {}
	var dv = cf.get_value("game", "daily", {})
	daily = dv.duplicate(true) if dv is Dictionary else {}


static func save_all() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music", music)
	cf.set_value("audio", "sfx", sfx)
	cf.set_value("net", "name", player_name)
	cf.set_value("net", "token", net_token)
	cf.set_value("net", "master", master_url)
	cf.set_value("view", "country_names", country_names)
	cf.set_value("view", "province_names", province_names)
	cf.set_value("view", "armies", armies)
	cf.set_value("view", "navy", navy)
	cf.set_value("view", "air", air)
	cf.set_value("view", "smooth", smooth)
	cf.set_value("view", "ui_scale", ui_scale)
	cf.set_value("view", "ui_scale_custom", ui_scale_custom)
	cf.set_value("view", "ui_scale_ver", 3)
	cf.set_value("game", "autosave", autosave)
	cf.set_value("game", "cabinet", cabinet)
	cf.set_value("game", "bulletin", bulletin)
	cf.set_value("game", "auto_orders", auto_orders)
	cf.set_value("game", "fog", fog)
	cf.set_value("game", "currency", currency)
	cf.set_value("game", "sandbox", sandbox)
	cf.set_value("game", "notifications", notifications)
	cf.set_value("game", "language", language)
	cf.set_value("game", "seen_howto", seen_howto)
	cf.set_value("game", "seen_promo", seen_promo)
	cf.set_value("game", "seen_update", seen_update)
	cf.set_value("game", "tut_done", tut_done)
	cf.set_value("game", "difficulty", difficulty)
	cf.set_value("game", "war_aggr", war_aggr)
	cf.set_value("game", "war_gate", war_gate)
	cf.set_value("game", "era_peace", era_peace)
	cf.set_value("game", "ach", ach)
	cf.set_value("game", "missions", missions)
	cf.set_value("game", "xp", xp)
	cf.set_value("game", "streak", streak)
	cf.set_value("game", "streak_day", streak_day)
	cf.set_value("game", "ap", ap)
	cf.set_value("game", "daily", daily)
	cf.save(PATH)


## Pencere/görüntü ayarlarını uygular.
static func apply_display(tree: SceneTree) -> void:
	var win := tree.root
	win.content_scale_factor = ui_scale
