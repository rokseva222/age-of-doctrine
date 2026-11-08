extends RefCounted
## Kalıcı oyun ayarları (user://settings.cfg). Tüm değerler statik; her yerden okunur.

const PATH := "user://settings.cfg"

static var music := 0.5
static var sfx := 0.6
static var country_names := true
static var province_names := true
static var armies := true
static var autosave := true
static var cabinet := true            # kabine/danışman kartları
static var notifications := true       # 5 saatte bir "ordun seni bekliyor" bildirimi (Android)
static var language := ""             # "tr" / "en"; boşsa sistem dilinden seçilir
static var auto_orders := true        # emir vermediğin turda boştaki ordular otomatik görev alır
static var smooth := true
static var ui_scale := 1.0
static var seen_howto := false
static var seen_promo := false
static var tut_done := false
static var missions: Dictionary = {}  # günlük/haftalık görevler (missions.gd)
static var xp := 0                    # Komutan Puanı
static var streak := 0                # üst üste gün serisi
static var streak_day := -1
static var ach: Dictionary = {}       # açılan başarımlar/öğretici adımlar: id -> tur
static var difficulty := 1            # 0 kolay, 1 normal, 2 zor
static var daily: Dictionary = {}     # Günlük Meydan Okuma kaydı (daily.gd)
static var ap: Dictionary = {}        # AOD Puanı, satın alımlar, reklam sayaçları (ap.gd)


## Telefonda yatay yükseklik ≈ 720/ölçek birim: 0.8 ≈ 900 birim, panellerin (ör. taarruz penceresi) sığması için gerekli.
## Çok küçük ekranlarda dokunma hedefleri için biraz büyütülür.
static func default_scale() -> float:
	if not OS.has_feature("mobile"):
		return 0.8
	var dpi: int = DisplayServer.screen_get_dpi()
	var sz: Vector2i = DisplayServer.screen_get_size()
	if dpi <= 0 or sz.x <= 0:
		return 0.8
	var width_mm: float = float(maxi(sz.x, sz.y)) / float(dpi) * 25.4
	return clampf(120.0 / width_mm, 0.75, 0.95)


static func load_all() -> void:
	ui_scale = default_scale()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	music = float(cf.get_value("audio", "music", music))
	sfx = float(cf.get_value("audio", "sfx", sfx))
	country_names = bool(cf.get_value("view", "country_names", country_names))
	province_names = bool(cf.get_value("view", "province_names", province_names))
	armies = bool(cf.get_value("view", "armies", armies))
	smooth = bool(cf.get_value("view", "smooth", smooth))
	# sürüm 2: varsayılan ölçek küçüldü; eski kayıtlı (otomatik) değer bir kez yeni varsayılana çekilir
	if int(cf.get_value("view", "ui_scale_ver", 1)) >= 2:
		ui_scale = clampf(float(cf.get_value("view", "ui_scale", ui_scale)), 0.6, 1.4)
	autosave = bool(cf.get_value("game", "autosave", autosave))
	cabinet = bool(cf.get_value("game", "cabinet", cabinet))
	auto_orders = bool(cf.get_value("game", "auto_orders", auto_orders))
	notifications = bool(cf.get_value("game", "notifications", notifications))
	language = str(cf.get_value("game", "language", language))
	seen_howto = bool(cf.get_value("game", "seen_howto", seen_howto))
	seen_promo = bool(cf.get_value("game", "seen_promo", seen_promo))
	tut_done = bool(cf.get_value("game", "tut_done", tut_done))
	difficulty = clampi(int(cf.get_value("game", "difficulty", difficulty)), 0, 2)
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
	cf.set_value("view", "country_names", country_names)
	cf.set_value("view", "province_names", province_names)
	cf.set_value("view", "armies", armies)
	cf.set_value("view", "smooth", smooth)
	cf.set_value("view", "ui_scale", ui_scale)
	cf.set_value("view", "ui_scale_ver", 2)
	cf.set_value("game", "autosave", autosave)
	cf.set_value("game", "cabinet", cabinet)
	cf.set_value("game", "auto_orders", auto_orders)
	cf.set_value("game", "notifications", notifications)
	cf.set_value("game", "language", language)
	cf.set_value("game", "seen_howto", seen_howto)
	cf.set_value("game", "seen_promo", seen_promo)
	cf.set_value("game", "tut_done", tut_done)
	cf.set_value("game", "difficulty", difficulty)
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
