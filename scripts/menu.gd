extends CanvasLayer
## Açılış ekranı, ana menü ve ülke seçimi. Her şey kodla çizilir; harita arkada canlı döner.

const Loc = preload("res://scripts/loc.gd")
const Icons = preload("res://scripts/icons.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const Logo = preload("res://scripts/logo.gd")
const Sheet = preload("res://scripts/sheet.gd")
const EraExt = preload("res://scripts/era_ext.gd")
const ScenarioEditor = preload("res://scripts/scenario_editor.gd")
const IndepUI = preload("res://scripts/independence_ui.gd")
const DailyUI = preload("res://scripts/daily_ui.gd")
const UserScn = preload("res://scripts/user_scn.gd")
const Settings = preload("res://scripts/settings.gd")
const Info = preload("res://scripts/info_sheets.gd")
const Scenarios = preload("res://scripts/scenarios.gd")
const Eras = preload("res://scripts/eras.gd")
const Saves = preload("res://scripts/saves.gd")
const AP = preload("res://scripts/ap.gd")
const ApUi = preload("res://scripts/ap_ui.gd")

const PROMO_PATH := "res://assets/brand/promo.ogv"
const INTRO_PATH := "res://assets/brand/rok_intro.ogv"

signal splash_done()
signal play_pressed()
signal era_chosen(id: String)
signal indep_start(params: Dictionary)
signal daily_start(cfg: Dictionary)
signal continue_pressed()
signal start_country(cid: int)
signal preview_country(cid: int)
signal back_pressed()
signal quit_pressed()
signal settings_changed()

const CONT_TR := {
	"Europe": "Avrupa", "Asia": "Asya", "Africa": "Afrika", "North America": "Kuzey Amerika",
	"South America": "Güney Amerika", "Oceania": "Okyanusya", "Antarctica": "Antarktika",
	"Seven seas (open ocean)": "Okyanus",
}

var gs = null
var sfx = null
var root: Control
var splash: Control
var main_panel: Control
var select_panel: Control
var continue_btn: Button
var _splash_logo
var _splash_done := false
var _splash_t := 0.0
var _splash_tw: Tween
var _intro: Control = null
var _intro_player: VideoStreamPlayer = null
var _intro_t := 0.0
var _rows: Array = []
var _list_gs = null
var _sel := -1
var _search: LineEdit
var _go_btn: Button
var _sel_box: VBoxContainer
var _sel_card: PanelContainer
var _power: Dictionary = {}
var _rank: Dictionary = {}
var scenario_id := "free"
var _scn_btn: Button
var _shop_btn: Button
var _shop_dot: Control
var _toast_panel: PanelContainer
var _toast_lbl: Label
var _toast_tw: Tween
var era_id := ""


func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = TK.make_theme()
	add_child(root)
	_build_main()
	_build_select()
	_build_splash()
	main_panel.visible = false
	select_panel.visible = false
	_build_intro()


func _click() -> void:
	if sfx != null:
		sfx.play("click")


# ------------------------------------------------------------------ açılış

func _build_splash() -> void:
	splash = Control.new()
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(splash)
	var bg := ColorRect.new()
	bg.color = TK.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	_splash_logo = Logo.new()
	_splash_logo.custom_minimum_size = Vector2(560, 560)
	_splash_logo.intro = 0.0
	_splash_logo.emblem_scale = 0.9
	v.add_child(_splash_logo)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(320, 4)
	bar.max_value = 1.0
	bar.add_theme_stylebox_override("background", TK.box(TK.PANEL_HI, Color(0, 0, 0, 0), 0, 0, 0, Vector4(0, 0, 0, 0)))
	bar.add_theme_stylebox_override("fill", TK.box(TK.PAPER, Color(0, 0, 0, 0), 0, 0, 0, Vector4(0, 0, 0, 0)))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bar)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_splash_logo, "intro", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_splash_logo, "emblem_scale", 1.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", 1.0, 2.3).set_delay(0.2)
	tw.chain().tween_interval(0.25)
	tw.chain().tween_callback(finish_splash)
	_splash_tw = tw
	splash.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and _splash_t > 0.7:
			finish_splash())


func _process(delta: float) -> void:
	_splash_t += delta
	_intro_t += delta


## Stüdyo açılış videosu (Rok Games Studios): tüm arayüzün üstünde oynar; dokununca geçilir, bitince Age of Doctrine açılışı başlar.
func _build_intro() -> void:
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(INTRO_PATH):
		return
	var stream = load(INTRO_PATH)
	if stream == null:
		return
	_intro = Control.new()
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_intro)
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.051, 0.063)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(bg)
	var ar := AspectRatioContainer.new()
	ar.ratio = 16.0 / 9.0
	ar.stretch_mode = AspectRatioContainer.STRETCH_FIT
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(ar)
	_intro_player = VideoStreamPlayer.new()
	_intro_player.stream = stream
	_intro_player.expand = true
	_intro_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_player.volume_db = linear_to_db(maxf(0.001, Settings.sfx))
	ar.add_child(_intro_player)
	_intro_player.finished.connect(_end_intro)
	_intro.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed and _intro_t > 0.5:
			_end_intro())
	if _splash_tw != null:
		_splash_tw.pause()
	_intro_t = 0.0
	_intro_player.play()


func _end_intro() -> void:
	if _intro == null:
		return
	var it: Control = _intro
	_intro = null
	if _intro_player != null:
		_intro_player.stop()
		_intro_player = null
	_splash_t = 0.0
	if _splash_tw != null and _splash_tw.is_valid():
		_splash_tw.play()
	var tw := create_tween()
	tw.tween_property(it, "modulate:a", 0.0, 0.35)
	tw.tween_callback(it.queue_free)


func finish_splash() -> void:
	if _splash_done:
		return
	if _intro != null:
		_end_intro()
	_splash_done = true
	# İlk açılışta tanıtım videosunun karartması splash'ın ALTINDAN değil ÜSTÜNDEN gelir; ana menü hiç görünmez.
	_build_promo()
	var tw := create_tween()
	tw.tween_property(splash, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		splash.visible = false
		splash_done.emit())


## Tanıtım videosu (CapCut vb. ile yapılıp assets/brand/promo.ogv olarak eklenir): ilk açılışta bir kez oynar, dokununca geçilir.
func _build_promo() -> void:
	if DisplayServer.get_name() == "headless" or Settings.seen_promo or not ResourceLoader.exists(PROMO_PATH):
		return
	var stream = load(PROMO_PATH)
	if stream == null:
		return
	Settings.seen_promo = true
	Settings.save_all()
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ov)
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.051, 0.063)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(bg)
	var ar := AspectRatioContainer.new()
	ar.ratio = 16.0 / 9.0
	ar.stretch_mode = AspectRatioContainer.STRETCH_FIT
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(ar)
	var pl := VideoStreamPlayer.new()
	pl.stream = stream
	pl.expand = true
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pl.volume_db = linear_to_db(maxf(0.001, Settings.sfx))
	ar.add_child(pl)
	var skip := TK.t("Geçmek için dokun", "h3", TK.TEXT)
	skip.add_theme_font_size_override("font_size", 38)
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skip.offset_left = -520
	skip.offset_top = -86
	skip.offset_right = -36
	skip.offset_bottom = -30
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	skip.add_theme_constant_override("outline_size", 8)
	ov.add_child(skip)
	var pulse := create_tween().set_loops()
	pulse.tween_property(skip, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(skip, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	var done := func():
		if is_instance_valid(ov) and not ov.has_meta("closing"):
			ov.set_meta("closing", true)
			pl.stop()
			pulse.kill()
			var ft := create_tween()
			ft.tween_property(ov, "modulate:a", 0.0, 0.35)
			ft.tween_callback(ov.queue_free)
	pl.finished.connect(done)
	ov.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed:
			done.call())
	pl.play()


# ------------------------------------------------------------------ ana menü

func _build_main() -> void:
	main_panel = Control.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(main_panel)
	# sol sütun: düz grafit şerit, sağ kenarda ince çizgi
	var strip := PanelContainer.new()
	strip.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	strip.offset_right = 540
	var sb := TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.97), TK.LINE, 0, 0, 1, Vector4(64, 40, 56, 32))
	sb.border_width_right = 1
	strip.add_theme_stylebox_override("panel", sb)
	main_panel.add_child(strip)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	strip.add_child(col)
	var logo := Logo.new()
	logo.vertical = false
	logo.custom_minimum_size = Vector2(420, 120)
	col.add_child(logo)
	col.add_child(TK.spacer(0, 14))
	col.add_child(TK.hsep())
	col.add_child(TK.spacer(0, 6))
	var play := TK.button("Oyna", "gold", "play", Vector2(0, 76), 24)
	play.pressed.connect(func():
		_click()
		play_pressed.emit())
	col.add_child(play)
	var bscroll := ScrollContainer.new()
	bscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(bscroll)
	var btns := VBoxContainer.new()
	btns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_theme_constant_override("separation", 10)
	bscroll.add_child(btns)
	var hist := TK.button("Tarihî Savaşlar", "", "hourglass", Vector2(0, 64), 21)
	hist.pressed.connect(func():
		_click()
		_open_eras())
	btns.add_child(hist)
	var indep_btn := TK.button("Bağımsızlık Yolu", "", "flag", Vector2(0, 64), 21)
	indep_btn.pressed.connect(func():
		_click()
		if not AP.mode_unlocked("indep"):
			ApUi.open_unlock(root, "mode", "indep", "Bağımsızlık Yolu", toast)
			return
		IndepUI.open_setup(root, func(p): indep_start.emit(p)))
	btns.add_child(indep_btn)
	var daily_btn := TK.button("Günlük Meydan Okuma", "", "target", Vector2(0, 64), 21)
	daily_btn.pressed.connect(func():
		_click()
		DailyUI.open(root, func(c): daily_start.emit(c)))
	btns.add_child(daily_btn)
	var online_btn := TK.button("Çok Oyunculu", "", "globe", Vector2(0, 64), 21)
	online_btn.pressed.connect(func():
		_click()
		toast("Online çok oyunculu mod yakında geliyor!"))
	var soon := TK.stamp("Yakında", TK.PURPLE)
	soon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	soon.offset_top = -12
	soon.offset_right = -10
	soon.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	online_btn.add_child(soon)
	btns.add_child(online_btn)
	continue_btn = TK.button("Devam Et", "", "folder", Vector2(0, 64), 21)
	continue_btn.pressed.connect(func():
		_click()
		continue_pressed.emit())
	btns.add_child(continue_btn)
	_shop_btn = TK.button("Mağaza", "", "coins", Vector2(0, 64), 21)
	_shop_btn.pressed.connect(func():
		_click()
		ApUi.open(root, toast))
	btns.add_child(_shop_btn)
	_shop_dot = TK.stamp("Ödül", TK.GREEN)
	_shop_dot.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_shop_dot.anchor_left = 1.0
	_shop_dot.anchor_right = 1.0
	_shop_dot.offset_left = -90
	_shop_dot.offset_right = -14
	_shop_dot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_shop_dot.grow_vertical = Control.GROW_DIRECTION_BOTH
	_shop_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_btn.add_child(_shop_dot)
	var how := TK.button("Nasıl Oynanır", "", "book", Vector2(0, 64), 21)
	how.pressed.connect(func():
		_click()
		Info.open_howto(root))
	btns.add_child(how)
	var set_row := HBoxContainer.new()
	set_row.add_theme_constant_override("separation", 10)
	var st := TK.button("Ayarlar", "", "gear", Vector2(0, 64), 21)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.pressed.connect(func():
		_click()
		Info.open_settings(root, func(): settings_changed.emit(), sfx))
	set_row.add_child(st)
	var cr := TK.button("Emeği Geçenler", "", "", Vector2(0, 64), 17)
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cr.pressed.connect(func():
		_click()
		Info.open_credits(root))
	set_row.add_child(cr)
	btns.add_child(set_row)
	if not (OS.has_feature("mobile") or OS.has_feature("web")):
		var q := TK.button("Çıkış", "ghost", "power", Vector2(0, 64), 21)
		q.pressed.connect(func(): quit_pressed.emit())
		btns.add_child(q)
	btns.add_child(TK.spacer(0, 6))
	var foot := TK.t("Sürüm 1.0   /   1 hafta = 1 tur", "kicker", TK.FAINT)
	foot.add_theme_font_size_override("font_size", 17)
	btns.add_child(foot)
	if AP.promo_active():
		var pr := TK.t("Lansman: tüm çağlar ve senaryolar açık (%d gün kaldı)" % AP.promo_days_left(), "kicker", TK.GREEN)
		pr.add_theme_font_size_override("font_size", 17)
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btns.add_child(pr)


# ------------------------------------------------------------------ ülke seçimi

class PowerBar extends Control:
	var frac := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(76, 8)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := size.y * 0.5 - 2.0
		draw_rect(Rect2(0, y, size.x, 4), Color("2a313b"))
		draw_rect(Rect2(0, y, size.x * clampf(frac, 0.06, 1.0), 4), Color("ece6d6"))


class Pips extends Control:
	var n := 1

	func _init() -> void:
		custom_minimum_size = Vector2(92, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in 4:
			var r := Rect2(i * 24.0, 0, 18, 16)
			if i < n:
				draw_rect(r, Color("ece6d6"))
			else:
				draw_rect(r, Color("39414b"), false, 1.5)


func _build_select() -> void:
	select_panel = Control.new()
	select_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(select_panel)
	# sol: ülke listesi
	var d := TK.dossier(TK.PAPER, Vector4(20, 14, 20, 18))
	var card: PanelContainer = d.panel
	card.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	card.offset_left = 14
	card.offset_top = 14
	card.offset_bottom = -14
	card.offset_right = 14 + 470
	select_panel.add_child(card)
	var v: VBoxContainer = d.body
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.get_child(0).size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var back := TK.icon_button("chev_l", 60, "ghost")
	back.pressed.connect(func():
		_click()
		back_pressed.emit())
	head.add_child(back)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", -6)
	tv.add_child(TK.t("Yeni oyun", "kicker"))
	tv.add_child(TK.t("Ülkeni seç", "h3", TK.TEXT))
	head.add_child(tv)
	v.add_child(head)
	_scn_btn = TK.button("Dünya 2027", "", "book", Vector2(0, 60), 16)
	_scn_btn.pressed.connect(func():
		_click()
		_open_scenarios())
	v.add_child(_scn_btn)
	_search = LineEdit.new()
	_search.placeholder_text = "Ülke ara..."
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(0, 56)
	_search.text_changed.connect(_on_search)
	v.add_child(_search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.name = "list"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	v.add_child(scroll)
	# sağ alt: seçili ülke dosyası
	var d2 := TK.dossier(TK.PAPER, Vector4(22, 14, 22, 20))
	_sel_card = d2.panel
	_sel_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_sel_card.anchor_left = 1.0
	_sel_card.anchor_right = 1.0
	_sel_card.anchor_top = 1.0
	_sel_card.anchor_bottom = 1.0
	_sel_card.offset_left = -14 - 500
	_sel_card.offset_right = -14
	_sel_card.offset_bottom = -14
	_sel_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_sel_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	select_panel.add_child(_sel_card)
	_sel_box = d2.body
	_sel_box.add_theme_constant_override("separation", 12)
	_sel_card.visible = false
	_go_btn = TK.button("Başla", "gold", "play", Vector2(0, 72), 23)
	_go_btn.disabled = true
	_go_btn.pressed.connect(func():
		if _sel >= 0:
			_click()
			start_country.emit(_sel))


func _open_scenarios() -> void:
	var sh = Sheet.open(root, "Senaryo seç", 980, false, true, "Oyun kipi")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y * 0.58, 240.0, 540.0))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	scroll.add_child(box)
	sh.body.add_child(scroll)
	var kinds := {"free": ["SERBEST", TK.PAPER], "real": ["GERÇEK KRİZ", TK.RED_TEXT], "fiction": ["KURGUSAL", TK.PURPLE], "user": ["SENİN SENARYON", TK.GREEN]}
	var last_kind := ""
	for sc in Scenarios.all():
		var kd: String = sc["kind"]
		if kd != last_kind:
			var hl := TK.t({"free": "Serbest oyun", "real": "Gerçek dünya senaryoları", "fiction": "Kurgusal modern senaryolar", "user": "Senin senaryoların"}[kd], "kicker", TK.FAINT)
			var hm := MarginContainer.new()
			hm.add_theme_constant_override("margin_top", 14)
			hm.add_theme_constant_override("margin_bottom", 6)
			hm.add_child(hl)
			box.add_child(hm)
			last_kind = kd
		var sid: String = sc["id"]
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 0)
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 0
		hb.offset_right = -12
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_theme_constant_override("separation", 14)
		var bar := ColorRect.new()
		bar.color = kinds[kd][1]
		bar.custom_minimum_size = Vector2(5, 0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(bar)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(TK.t("%s   /   %s" % [Loc.t(kinds[kd][0]), Loc.t(sc["sub"])], "kicker", kinds[kd][1]))
		tv.add_child(TK.t(sc["name"], "caps", TK.TEXT))
		var bl := TK.t(sc["blurb"], "small", TK.MUTED)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(bl)
		hb.add_child(tv)
		if kd == "user":
			var eb := TK.button("Düzenle", "", "", Vector2(120, 48), 16)
			eb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			eb.pressed.connect(func():
				_click()
				sh.close()
				ScenarioEditor.open(root, UserScn.load_one(sid), _after_editor))
			hb.add_child(eb)
		if sid == scenario_id:
			var stp := TK.stamp("Seçili", TK.GREEN)
			stp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(stp)
		b.add_child(hb)
		b.custom_minimum_size = Vector2(0, 150 if kd != "free" else 138)
		b.pressed.connect(func():
			_click()
			set_scenario(sid)
			sh.close())
		box.add_child(b)
	sh.add_button("Senaryo oluştur", func():
		_click()
		ScenarioEditor.open(root, {}, _after_editor), "gold", true, "plus", 220)
	sh.add_button("Kapat", func(): pass, "", true, "", 160)


## Senaryo düzenleyiciden dönünce: yeni/değişen senaryo seçilir, silindiyse liste açılır
func _after_editor(id: String) -> void:
	if id != "" and Scenarios.get_sc(id).size() > 0:
		set_scenario(id)
	elif scenario_id.begins_with("u_") and Scenarios.get_sc(scenario_id).is_empty():
		set_scenario("free")
	_open_scenarios()


func _open_eras() -> void:
	var sh = Sheet.open(root, "Tarihî savaşlar", 900, false, true, "Oyun kipi")
	sh.set_icon("what_if", "")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	sh.body.add_child(box)
	box.add_child(TK.t("Ayrı bir oyun kipi: dönemin imparatorlukları, silahları, ittifakları ve renkleri. Senaryolardan bağımsızdır.", "small", TK.MUTED))
	for e in Eras.all():
		var eid: String = e["id"]
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 0)
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_right = -12
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_theme_constant_override("separation", 14)
		var bar := ColorRect.new()
		bar.color = TK.GOLD
		bar.custom_minimum_size = Vector2(5, 0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(bar)
		var eic := TK.IconView.new()
		eic.icon = {"ww1": "helmet_ww1", "ww2": "helmet_ww2"}.get(eid, str(EraExt.field(eid, "icon", "helmet")) if EraExt.has_era(eid) else "helmet")
		if AP.unlock_id_for_era(eid).begins_with("pack_"):
			eic.icon = Icons.pick("alt_history", eic.icon)
		eic.color = Color.WHITE
		eic.custom_minimum_size = Vector2(54, 54)
		eic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		eic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(eic)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(TK.t("TARİHÎ KİP   /   %s" % e["sub"], "kicker", TK.GOLD))
		tv.add_child(TK.t(e["name"], "caps", TK.TEXT))
		var bl := TK.t(e["blurb"], "small", TK.MUTED)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(bl)
		hb.add_child(tv)
		if not AP.era_unlocked(eid):
			var lk2 := TK.stamp("Kilitli", TK.RED_TEXT)
			lk2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(lk2)
		b.add_child(hb)
		b.custom_minimum_size = Vector2(0, 176)
		var ename: String = e["name"]
		b.pressed.connect(func():
			_click()
			if not AP.era_unlocked(eid):
				var uid: String = AP.unlock_id_for_era(eid)
				ApUi.open_unlock(root, "era", uid, "Alternatif Tarih Paketi" if uid.begins_with("pack_") else ename, toast, func():
					sh.close()
					_open_eras())
				return
			sh.close()
			era_chosen.emit(eid))
		box.add_child(b)
	sh.add_button("Kapat", func(): pass, "", true, "", 160)


func set_era(id: String) -> void:
	era_id = id
	scenario_id = "free"
	var e: Dictionary = Eras.get_era(id)
	if _scn_btn != null:
		_scn_btn.text = TK.up("%s  /  %s" % [e["name"], e["sub"]])
		_scn_btn.disabled = true


func _apply_suggest(suggest: Array) -> void:
	var list: Control = select_panel.find_child("list", true, false)
	var pos := 0
	for en in suggest:
		for r in _rows:
			if r["en"] == en and list != null and r["btn"].visible:
				list.move_child(r["btn"], pos)
				pos += 1
	if list != null:
		var rest: Array = _rows.filter(func(r): return not suggest.has(r["en"]))
		rest.sort_custom(func(a, b): return _rank.get(a["cid"], 999) < _rank.get(b["cid"], 999))
		for r in rest:
			list.move_child(r["btn"], pos)
			pos += 1
	for r in _rows:
		r["badge"].visible = suggest.has(r["en"]) and era_id == ""


func set_scenario(sid: String) -> void:
	if not AP.scenario_unlocked(sid):
		sid = "free"
	scenario_id = sid
	var sc: Dictionary = Scenarios.get_sc(sid)
	_scn_btn.text = TK.up(sc["name"])
	_apply_suggest(sc["suggest"])
	_select_first(sc["suggest"])


func _select_first(suggest: Array) -> void:
	if not suggest.is_empty() and gs != null:
		for c in gs.countries:
			if c.name_en == suggest[0] and c.alive:
				select_country(c.id)
				preview_country.emit(c.id)
				break


func _on_search(q: String) -> void:
	var k := q.strip_edges().to_lower()
	for r in _rows:
		r.btn.visible = k == "" or r.key.contains(k)


func _populate_list() -> void:
	var list: VBoxContainer = select_panel.find_child("list", true, false)
	for ch in list.get_children():
		ch.queue_free()
	_rows.clear()
	var order: Array = []
	var maxp := 1.0
	for c in gs.countries:
		if c.is_rebel or not c.alive:
			continue
		order.append(c)
		_power[c.id] = gs.power_of(c)
		maxp = maxf(maxp, _power[c.id])
	order.sort_custom(func(a, b): return _power[a.id] > _power[b.id])
	for i in order.size():
		_rank[order[i].id] = i
	for c in order:
		var cid: int = c.id
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 68)
		var hb := TK.row_layout(b, 12)
		var f := TK.flag_rect(c, Vector2(52, 35))
		f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(f)
		var nl := TK.t(c.name, "bodyb", TK.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.clip_text = true
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(nl)
		var badge := TK.stamp("Önerilen", TK.GOLD)
		badge.visible = false
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(badge)
		var pb := PowerBar.new()
		pb.frac = sqrt(_power[cid] / maxp)
		hb.add_child(pb)
		TK.ignore_mouse(hb)
		b.pressed.connect(func():
			_click()
			select_country(cid))
		list.add_child(b)
		_rows.append({"btn": b, "cid": cid, "key": (c.name + " " + c.name_en).to_lower(), "badge": badge, "en": c.name_en})
	_list_gs = gs


func _difficulty_of(cid: int) -> Array:
	var r: int = _rank.get(cid, 99)
	if r < 12:
		return [1, "Kolay"]
	if r < 60:
		return [2, "Orta"]
	if r < 130:
		return [3, "Zor"]
	return [4, "Çok zor"]


func _clear_sel() -> void:
	if _go_btn.get_parent() != null:
		_go_btn.get_parent().remove_child(_go_btn)
	for ch in _sel_box.get_children():
		_sel_box.remove_child(ch)
		ch.queue_free()


func select_country(cid: int) -> void:
	if gs == null or cid < 0 or cid >= gs.countries.size() or gs.countries[cid].is_rebel:
		return
	_sel = cid
	var c = gs.countries[cid]
	for r in _rows:
		TK.row_select(r.btn, r.cid == cid, TK.PAPER)
		if r.cid != cid:
			r.btn.add_theme_stylebox_override("normal", TK.line_box(Color(0, 0, 0, 0), TK.LINE))
	_clear_sel()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var f := TK.flag_rect(c, Vector2(88, 59))
	f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(f)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(TK.t(CONT_TR.get(c.continent, c.continent), "kicker"))
	var nm := TK.t(c.name, "h2", TK.TEXT)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var nl2: int = c.name.length()
	if nl2 > 12:
		nm.add_theme_font_size_override("font_size", 38 if nl2 <= 16 else 30)
	tv.add_child(nm)
	var ld: Array = Macro.leader_of(c)
	if ld[1] != "":
		var ltxt: String = "%s: %s" % [ld[0], ld[1]]
		var lt := TK.t(ltxt, "small", TK.MUTED)
		lt.add_theme_font_size_override("font_size", 20 if ltxt.length() <= 30 else 17)
		lt.clip_text = true
		lt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tv.add_child(lt)
	top.add_child(tv)
	_sel_box.add_child(top)
	var d := _difficulty_of(cid)
	var dr := HBoxContainer.new()
	dr.add_theme_constant_override("separation", 14)
	dr.add_child(TK.t("Zorluk", "kicker"))
	var pips := Pips.new()
	pips.n = d[0]
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dr.add_child(pips)
	dr.add_child(TK.t(d[1], "mono", TK.TEXT))
	_sel_box.add_child(dr)
	if c.prov_owned <= 8 and d[0] >= 3:
		var warn := TK.t("Küçük devlet: güçlü komşular erken saldırabilir. İlk 16 hafta savunma desteği alırsın.", "small", TK.MUTED)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_sel_box.add_child(warn)
	_sel_box.add_child(TK.hsep())
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 0)
	var vals := [
		["Nüfus", "%.0fM" % c.pop, TK.TEXT],
		["Eyalet", "%d" % c.prov_owned, TK.TEXT],
		["Gelir/hf", Macro.money(c.income), TK.GOLD],
		["Asker", Macro.compact(c.troops), TK.TEXT],
	]
	for i in vals.size():
		if i > 0:
			stats.add_child(TK.vsep())
		var m := MarginContainer.new()
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m.add_theme_constant_override("margin_left", 0 if i == 0 else 14)
		m.add_child(TK.stat(vals[i][0], vals[i][1], vals[i][2]))
		stats.add_child(m)
	_sel_box.add_child(stats)
	_go_btn.disabled = false
	_go_btn.text = TK.up("%s ile başla" % c.name)
	if _go_btn.get_parent() != null:
		_go_btn.get_parent().remove_child(_go_btn)
	_sel_box.add_child(_go_btn)
	_sel_card.visible = true
	preview_country.emit(cid)


# ------------------------------------------------------------------ bildirim (menü katmanı ui'nin üstünde olduğu için kendi toast'ı)

func toast(msg: String) -> void:
	if _toast_panel == null:
		_toast_panel = PanelContainer.new()
		_toast_panel.add_theme_stylebox_override("panel", TK.box(TK.PANEL_SOLID, TK.PAPER, 3, 1, 1, Vector4(22, 12, 22, 12)))
		_toast_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_toast_panel.anchor_top = 1.0
		_toast_panel.anchor_bottom = 1.0
		_toast_panel.offset_top = -120
		_toast_panel.offset_bottom = -60
		_toast_panel.offset_left = -300
		_toast_panel.offset_right = 300
		_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_toast_lbl = TK.t("", "body", TK.TEXT)
		_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_toast_panel.add_child(_toast_lbl)
		root.add_child(_toast_panel)
	_toast_lbl.text = msg
	_toast_panel.modulate = Color(1, 1, 1, 1)
	_toast_panel.visible = true
	if _toast_tw != null:
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_interval(2.2)
	_toast_tw.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)


# ------------------------------------------------------------------ görünürlük

func _fade_in(n: Control) -> void:
	n.visible = true
	n.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(n, "modulate", Color(1, 1, 1, 1), 0.3)


func show_main() -> void:
	select_panel.visible = false
	if _shop_dot != null:
		_shop_dot.visible = AP.login_claimable()
	continue_btn.visible = Saves.any()
	_fade_in(main_panel)


func show_select(g) -> void:
	gs = g
	main_panel.visible = false
	if _list_gs != gs:
		_populate_list()
		_sel = -1
		_clear_sel()
		_sel_card.visible = false
		_go_btn.disabled = true
	_search.text = ""
	_on_search("")
	if era_id != "":
		var sg: Array = Eras.get_era(era_id)["suggest"]
		_apply_suggest(sg)
		if _sel < 0:
			_select_first(sg)
	else:
		var sc0: Dictionary = Scenarios.get_sc(scenario_id)
		for r in _rows:
			r["badge"].visible = sc0["suggest"].has(r["en"])
	_fade_in(select_panel)


func hide_all() -> void:
	main_panel.visible = false
	select_panel.visible = false


func is_selecting() -> bool:
	return select_panel.visible


func reset_world() -> void:
	_list_gs = null
	scenario_id = "free"
	era_id = ""
	if _scn_btn != null:
		_scn_btn.disabled = false
		_scn_btn.text = TK.up("Dünya 2027")
