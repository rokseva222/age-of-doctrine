extends CanvasLayer
const Loc = preload("res://scripts/loc.gd")
## Oyun içi arayüz (HUD): durum şeridi, haber bülteni, yan düğmeler, eyalet dosyası, Dünya paneli, barış masası, duraklatma menüsü.
## Görsel dil: grafit paneller, krem birincil eylem, tek kırmızı vurgu. Ayrıntı için theme_kit.gd.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const Carriers = preload("res://scripts/carriers.gd")
const Missions = preload("res://scripts/missions.gd")
const Emblem = preload("res://scripts/emblem.gd")
const PolicyUI = preload("res://scripts/policy_ui.gd")
const SceneArt = preload("res://scripts/scene_art.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Names = preload("res://scripts/names.gd")
const Settings = preload("res://scripts/settings.gd")
const Info = preload("res://scripts/info_sheets.gd")
const UN = preload("res://scripts/un.gd")
const Goals = preload("res://scripts/goals.gd")
const Objectives = preload("res://scripts/objectives.gd")
const GrandOp = preload("res://scripts/grand_op.gd")
const IndepUI = preload("res://scripts/independence_ui.gd")
const Independence = preload("res://scripts/independence.gd")
const Icons = preload("res://scripts/icons.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")
const Daily = preload("res://scripts/daily.gd")
const Politics = preload("res://scripts/politics.gd")
const WarRoomUI = preload("res://scripts/war_room_ui.gd")

## Başarım ikonları (yeni ikon yoksa yedek: yıldız)
const GOAL_ICONS := {"t_turn": "hourglass", "t_move": "tank", "t_war": "war_declared", "t_cap": "flag", "t_peace": "dove",
	"a_cap10": "medal_bronze", "a_cap50": "medal_silver", "a_cap150": "medal_gold", "a_battle50": "general", "a_peace5": "handshake",
	"a_ally": "alliance_shield", "a_elim": "skull", "a_un": "assembly_hall", "a_landing": "landing", "a_nuke": "radiation",
	"a_year1": "calendar", "a_year10": "hourglass", "a_prov30": "five_stars"}
const TERM_ICONS := {"reparations": ["reparations", "coins"], "disarm": ["disarm", "rifle"], "buffer": ["buffer_zone", "flag"]}

## BM önerge ikonları: [yeni ikon adı, yedek]
const UN_ICONS := {"ceasefire": ["ceasefire", "dove"], "rebuild": ["rebuild", "home"], "aid": ["aid", "coins"], "peace_keep": ["un_peacekeeper", "shield"],
	"develop": ["develop", "factory"], "guarantee": ["guarantee", "shield_star"], "sanction": ["sanction", "lock"], "embargo": ["embargo", "lock"],
	"probe": ["probe", "eye"], "disarm": ["disarm", "rifle"], "attack": ["war_declared", "swords"]}

const BAR_H := 80.0
const TICK_H := 52.0
const PADX := 8

signal speed_changed(idx: int)
signal step_requested()
signal action(name: String, arg)
signal settings_changed()
signal main_menu_requested()
signal load_requested()
signal save_requested()

var gs = null
var sfx = null
var speed_idx := 0

var root: Control
var topbar: PanelContainer
var ticker: Button
var side: VBoxContainer
var _side_btns: Array = []
var card: PanelContainer
var toast_panel: PanelContainer
var toast_lbl: Label
var _modal = null

var _flag_top
var _name_lbl: Label
var _gold_lbl: Label
var _delta_lbl: Label
var _troops_lbl: Label
var _prov_lbl: Label
var _date_lbl: Label
var _speed_btns: Array = []
var _turn_btn: Button = null
var _menu_btn: Control = null
signal tutorial_requested
signal shop_requested

var _card_flag
var _card_rule: ColorRect
var _card_kicker: Label
var _card_title: Label
var _card_tags: HFlowContainer
var _card_stats: HBoxContainer
var _card_hint: Label
var _card_actions: HFlowContainer
var _card_pid := -1

var _tick_kind: Label
var _tick_icon: TK.IconView
var _tick_lbl: Label
var _tick_pid := -1
var _tick_tween: Tween = null
var _toast_tween: Tween = null


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = TK.make_theme()
	add_child(root)
	_build_topbar()
	_build_ticker()
	_build_side()
	_build_card()
	_build_toast()
	set_hud_visible(false)


func _click() -> void:
	if sfx != null:
		sfx.play("click")


func _fmt(n: float) -> String:
	var a := absf(n)
	if a >= 1000000.0:
		return "%.1fM" % (n / 1000000.0)
	if a >= 10000.0:
		return "%.1fK" % (n / 1000.0)
	return str(int(n))


## Haber türü -> [etiket, renk]
func _news_info(kind: String, ic: String = "") -> Array:
	var r: Array = ["HABER", TK.MUTED, "news"]
	match kind:
		"war", "war_player":
			r = ["SAVAŞ", TK.RED_TEXT, "swords"]
		"capture", "capture_player":
			r = ["FETİH", TK.GOLD, "flag"]
		"lost_player":
			r = ["KAYIP", TK.RED_TEXT, "skull"]
		"peace":
			r = ["BARIŞ", TK.GREEN, "dove"]
		"event", "event_player":
			r = ["OLAY", TK.BLUE, "news"]
		"battle":
			r = ["ÇATIŞMA", TK.ORANGE, "explosion"]
		"elim":
			r = ["SON", TK.PURPLE, "skull"]
		"rebel", "rebel_player":
			r = ["İSYAN", TK.PURPLE, "unrest"]
		"alliance":
			r = ["İTTİFAK", TK.BLUE, "handshake"]
		"rank":
			r = ["SIRALAMA", TK.MUTED, "trophy"]
		"cyber":
			r = ["SİBER", TK.PURPLE, "hacker"]
		"ops":
			r = ["HAREKÂT", TK.ORANGE, "spy"]
		"arms":
			r = ["TEDARİK", TK.BLUE, "arty"]
	if ic != "":
		r[2] = ic
	return r


## Haber kaydı için ikon adı (olaylarda kayıtlı özel ikon, yoksa türün ikonu).
func news_icon_of(n: Dictionary) -> String:
	return _news_info(n.kind, n.get("ic", ""))[2]


func _news_icon_view(name: String, px: float) -> TK.IconView:
	var iv := TK.IconView.new()
	iv.icon = name
	iv.color = Color.WHITE
	iv.custom_minimum_size = Vector2(px, px)
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return iv


# ------------------------------------------------------------------ durum şeridi

func _bar_cell(caption: String, value_color: Color = TK.TEXT, width: float = 0.0) -> VBoxContainer:
	var c := TK.stat(caption, "", value_color)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if width > 0.0:
		c.custom_minimum_size = Vector2(width, 0)
	return c


func _bar_icon(name: String) -> TK.IconView:
	var iv := _news_icon_view(name, 28)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return iv


func _build_topbar() -> void:
	topbar = PanelContainer.new()
	topbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topbar.offset_bottom = BAR_H
	var sb := TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.97), TK.LINE, 0, 0, 1, Vector4(0, 0, 0, 0))
	sb.border_width_bottom = 1
	topbar.add_theme_stylebox_override("panel", sb)
	root.add_child(topbar)
	var wide: bool = root.get_viewport_rect().size.x >= 1560.0
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	topbar.add_child(h)
	# ülke
	var who := TK.row_button(Color(0, 0, 0, 0), TK.LINE, BAR_H)
	who.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	who.custom_minimum_size = Vector2(290, BAR_H)
	var wl := TK.row_layout(who, 16)
	_flag_top = TK.flag_rect(null, Vector2(58, 39))
	_flag_top.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wl.add_child(_flag_top)
	var wv := VBoxContainer.new()
	wv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wv.add_theme_constant_override("separation", -6)
	wv.add_child(TK.t("Devlet", "kicker"))
	_name_lbl = TK.t("", "h3", TK.TEXT)
	_name_lbl.clip_text = true
	_name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	wv.add_child(_name_lbl)
	wl.add_child(wv)
	var cv := TK.IconView.new()
	cv.icon = "chev_d"
	cv.color = TK.FAINT
	cv.custom_minimum_size = Vector2(24, 24)
	cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wl.add_child(cv)
	TK.ignore_mouse(wl)
	who.pressed.connect(func():
		_click()
		show_world_panel())
	h.add_child(who)
	h.add_child(TK.vsep())
	# kasa
	var gcell := _bar_cell("Kasa", TK.GOLD, 0.0)
	_gold_lbl = gcell.get_node("val")
	var gpad := MarginContainer.new()
	gpad.add_theme_constant_override("margin_left", PADX)
	gpad.add_theme_constant_override("margin_right", PADX)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 8)
	if wide:
		gh.add_child(_bar_icon("money_bag"))
	gh.add_child(gcell)
	_delta_lbl = TK.t("", "kicker", TK.GREEN)
	_delta_lbl.add_theme_font_size_override("font_size", 17)
	var cap_lbl: Node = gcell.get_child(0)
	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 10)
	gcell.add_child(cap_row)
	gcell.move_child(cap_row, 0)
	cap_lbl.reparent(cap_row)
	cap_row.add_child(_delta_lbl)
	gpad.add_child(gh)
	h.add_child(gpad)
	h.add_child(TK.vsep())
	var tcell := _bar_cell("Asker")
	_troops_lbl = tcell.get_node("val")
	var tpad := MarginContainer.new()
	tpad.add_theme_constant_override("margin_left", PADX)
	tpad.add_theme_constant_override("margin_right", PADX)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	if wide:
		th.add_child(_bar_icon("infantry"))
	th.add_child(tcell)
	tpad.add_child(th)
	h.add_child(tpad)
	h.add_child(TK.vsep())
	var pcell := _bar_cell("Eyalet")
	_prov_lbl = pcell.get_node("val")
	var ppad := MarginContainer.new()
	ppad.add_theme_constant_override("margin_left", PADX)
	ppad.add_theme_constant_override("margin_right", PADX)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 8)
	if wide:
		ph.add_child(_bar_icon("city"))
	ph.add_child(pcell)
	ppad.add_child(ph)
	h.add_child(ppad)
	h.add_child(TK.fill())
	# tarih
	var dcell := _bar_cell("Tarih")
	_date_lbl = dcell.get_node("val")
	_date_lbl.add_theme_font_size_override("font_size", 26)
	var dpad := MarginContainer.new()
	dpad.add_theme_constant_override("margin_left", PADX)
	dpad.add_theme_constant_override("margin_right", PADX)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 8)
	if wide:
		dh.add_child(_bar_icon("calendar"))
	dh.add_child(dcell)
	dpad.add_child(dh)
	h.add_child(TK.vsep())
	h.add_child(dpad)
	h.add_child(TK.vsep())
	# tur
	var sp_pad := MarginContainer.new()
	sp_pad.add_theme_constant_override("margin_left", PADX)
	sp_pad.add_theme_constant_override("margin_right", PADX)
	_turn_btn = TK.button("Turu geç", "gold", "play", Vector2(150, 58), 19)
	_turn_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_btn.pressed.connect(func():
		step_requested.emit())
	sp_pad.add_child(_turn_btn)
	h.add_child(sp_pad)
	h.add_child(TK.vsep())
	var menu := TK.icon_button("menu", BAR_H, "")
	_menu_btn = menu
	menu.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	menu.pressed.connect(func():
		_click()
		show_pause_menu())
	h.add_child(menu)


func _on_speed(idx: int) -> void:
	set_speed(idx)
	speed_changed.emit(idx)


func set_speed(idx: int) -> void:
	speed_idx = idx
	for i in _speed_btns.size():
		var b: Button = _speed_btns[i]
		TK.style_button(b, "gold" if i == idx else "ghost")
		var iv = b.get_meta("iv")
		iv.color = TK.INK if i == idx else TK.TEXT
		iv.queue_redraw()


func refresh_top() -> void:
	if gs == null or gs.player < 0:
		return
	var c = gs.countries[gs.player]
	_flag_top.set_country(c)
	_name_lbl.text = TK.up(c.name)
	var nfont: Font = _name_lbl.get_theme_font("font")
	var fs := 28
	while fs > 14 and nfont != null and nfont.get_string_size(_name_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 142.0:
		fs -= 1
	_name_lbl.add_theme_font_size_override("font_size", fs)
	var net: float = gs.net_income(c)
	_gold_lbl.text = Macro.money(c.gold)
	_delta_lbl.text = "%s%s%s" % ["+" if net >= 0.0 else "-", Macro.money(absf(net)), Loc.t("/hf")]
	_delta_lbl.add_theme_color_override("font_color", TK.GREEN if net >= 0.0 else TK.RED_TEXT)
	_troops_lbl.text = Macro.num(c.troops)
	_prov_lbl.text = "%d" % c.prov_owned
	_date_lbl.text = Names.date_string(gs.turn)


# ------------------------------------------------------------------ haber bülteni

func _build_ticker() -> void:
	ticker = Button.new()
	ticker.focus_mode = Control.FOCUS_NONE
	ticker.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ticker.offset_top = BAR_H
	ticker.offset_bottom = BAR_H + TICK_H
	var s := TK.line_box(Color(0.06, 0.07, 0.09, 0.95))
	ticker.add_theme_stylebox_override("normal", s)
	ticker.add_theme_stylebox_override("hover", TK.line_box(Color(0.09, 0.10, 0.13, 0.97)))
	ticker.add_theme_stylebox_override("pressed", TK.line_box(TK.PANEL_LIGHT))
	ticker.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var hb := TK.row_layout(ticker, 0)
	hb.add_theme_constant_override("separation", 14)
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", TK.box(TK.RED, Color(0, 0, 0, 0), 0, 0, 0, Vector4(18, 0, 18, 0)))
	var tl := TK.t("Cihan Bülteni", "kicker", Color.WHITE)
	tl.add_theme_color_override("font_color", Color.WHITE)
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_child(tl)
	hb.add_child(tag)
	_tick_icon = _news_icon_view("news", 26)
	_tick_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_tick_icon)
	_tick_kind = TK.t("", "kicker", TK.MUTED)
	_tick_kind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tick_kind.custom_minimum_size = Vector2(112, 0)
	hb.add_child(_tick_kind)
	_tick_lbl = TK.t("Haber bekleniyor...", "body", TK.TEXT)
	_tick_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tick_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tick_lbl.clip_text = true
	_tick_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_tick_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hb.add_child(_tick_lbl)
	var cv := TK.IconView.new()
	cv.icon = "chev_r"
	cv.color = TK.FAINT
	cv.custom_minimum_size = Vector2(24, 24)
	cv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(cv)
	hb.add_child(TK.spacer(14, 0))
	TK.ignore_mouse(hb)
	ticker.pressed.connect(func():
		_click()
		show_world_panel(2))
	root.add_child(ticker)


## Yeni oyunda eski oyunun haberi kalmasın.
func reset_news() -> void:
	_tick_pid = -1
	_tick_lbl.text = "Haber bekleniyor..."
	_tick_lbl.modulate.a = 1.0
	_tick_kind.text = ""
	_tick_icon.set_icon("news")


func show_news(text: String, prov: int, kind: String) -> void:
	_tick_pid = prov
	_tick_lbl.text = text
	var ic := ""
	if not gs.news_log.is_empty() and gs.news_log.back().text == text:
		ic = gs.news_log.back().get("ic", "")
	var info: Array = _news_info(kind, ic)
	_tick_icon.set_icon(info[2])
	_tick_kind.text = info[0]
	_tick_kind.add_theme_color_override("font_color", info[1])
	if _tick_tween != null and _tick_tween.is_valid():
		_tick_tween.kill()
	_tick_lbl.modulate.a = 0.0
	_tick_tween = create_tween().set_parallel(true)
	_tick_tween.tween_property(_tick_lbl, "modulate:a", 1.0, 0.25)
	if sfx != null and kind in ["capture_player", "event_player", "alliance"]:
		sfx.play("news", 0.6)


# ------------------------------------------------------------------ yan düğmeler

func _build_side() -> void:
	side = VBoxContainer.new()
	side.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.offset_left = -84
	side.offset_right = -14
	side.offset_top = BAR_H + TICK_H + 14
	side.add_theme_constant_override("separation", 6)
	root.add_child(side)
	var defs := [["tank", "policy"], ["globe", "world"], ["swords", "wars"], ["handshake", "rel"], ["target", "capital"], ["map", "fit"]]
	for d in defs:
		var b := TK.icon_button(d[0], 70, "")
		b.add_theme_stylebox_override("normal", TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.96), TK.LINE, 3, 1, 1))
		b.pressed.connect(_side_pressed.bind(d[1]))
		side.add_child(b)
		_side_btns.append(b)
	get_viewport().size_changed.connect(_fit_side)
	_fit_side.call_deferred()


## Kısa ekranlarda (büyük arayüz ölçeği) yan düğmeler ekran altına taşmasın diye küçülür.
func _fit_side() -> void:
	if side == null or _side_btns.is_empty():
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var avail: float = vp.y - side.offset_top - 12.0
	var sz: float = clampf((avail - 6.0 * (_side_btns.size() - 1)) / _side_btns.size(), 44.0, 70.0)
	for b in _side_btns:
		b.custom_minimum_size = Vector2(sz, sz)
		b.size = Vector2(sz, sz)
	side.offset_left = -(sz + 14.0)


func _side_pressed(key: String) -> void:
	_click()
	if key == "policy":
		PolicyUI.open(self, gs, 0)
	elif key == "world":
		show_world_panel(0)
	elif key == "wars":
		show_world_panel(1)
	elif key == "rel":
		var rc: int = gs.player
		if card.visible and _card_pid >= 0:
			rc = gs.provinces[_card_pid].owner
		action.emit("rel_view", rc)
	elif key == "capital":
		action.emit("capital", 0)
	elif key == "fit":
		action.emit("fit", 0)


# ------------------------------------------------------------------ eyalet dosyası

func _tag(text: String, col: Color) -> PanelContainer:
	return TK.stamp(text, col)


func _build_card() -> void:
	var d := TK.dossier(TK.PAPER, Vector4(22, 14, 22, 18))
	card = d.panel
	card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = 14
	card.offset_right = 14 + 660
	card.offset_bottom = -14
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card_rule = card.get_child(0).get_child(0)
	root.add_child(card)
	var v: VBoxContainer = d.body
	v.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	_card_flag = TK.flag_rect(null, Vector2(66, 44))
	_card_flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_card_flag)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_kicker = TK.t("", "kicker")
	_card_kicker.clip_text = true
	_card_kicker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(_card_kicker)
	_card_title = TK.t("", "h3", TK.TEXT)
	_card_title.add_theme_font_size_override("font_size", 44)
	_card_title.clip_text = true
	_card_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(_card_title)
	head.add_child(tv)
	var x := TK.icon_button("x", 56, "ghost")
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.pressed.connect(func():
		_click()
		action.emit("close_card", 0))
	head.add_child(x)
	v.add_child(head)
	_card_tags = HFlowContainer.new()
	_card_tags.add_theme_constant_override("h_separation", 8)
	v.add_child(_card_tags)
	v.add_child(TK.hsep())
	_card_stats = HBoxContainer.new()
	_card_stats.add_theme_constant_override("separation", 0)
	v.add_child(_card_stats)
	_card_hint = TK.t("", "small", TK.TEXT)
	_card_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_card_hint)
	_card_actions = HFlowContainer.new()
	_card_actions.add_theme_constant_override("h_separation", 10)
	_card_actions.add_theme_constant_override("v_separation", 10)
	v.add_child(_card_actions)
	card.visible = false


func hide_info() -> void:
	card.visible = false
	_card_pid = -1


func _clear(n: Node) -> void:
	for ch in n.get_children():
		n.remove_child(ch)
		ch.queue_free()


func _abtn(text: String, kind: String, icon: String, act: String, arg, enabled: bool = true) -> Button:
	var b := TK.button(text, kind, icon, Vector2(0, 60), 17)
	b.disabled = not enabled
	b.pressed.connect(func():
		_click()
		action.emit(act, arg))
	_card_actions.add_child(b)
	return b


func _card_stat(caption: String, value: String, col: Color = TK.TEXT, first: bool = false) -> void:
	if not first:
		var sp := TK.vsep()
		_card_stats.add_child(sp)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 0 if first else 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_child(TK.stat(caption, value, col))
	_card_stats.add_child(m)


func show_province(pid: int, selected_army) -> void:
	if gs == null or pid < 0 or gs.player < 0:
		hide_info()
		return
	var p = gs.provinces[pid]
	var me: int = gs.player
	_card_pid = pid
	card.visible = true
	var oc = gs.countries[p.owner]
	_card_flag.set_country(oc)
	_card_rule.color = oc.color.lightened(0.05) if oc.color.get_luminance() > 0.12 else TK.PAPER
	_card_title.text = TK.up(p.name)
	var kick: String = oc.name
	if p.city != "" and p.city != p.name and p.city.length() < 26:
		kick += "  /  " + p.city
	_card_kicker.text = TK.up(kick)
	_clear(_card_tags)
	_clear(_card_stats)
	_clear(_card_actions)
	var allied: bool = gs.is_allied(me, p.owner)
	if p.is_capital:
		_card_tags.add_child(_tag("Başkent", TK.GOLD))
	if p.owner == me:
		_card_tags.add_child(_tag("Senin", TK.GREEN))
	elif allied:
		_card_tags.add_child(_tag("Müttefik", TK.BLUE))
	elif gs.at_war(me, p.owner):
		_card_tags.add_child(_tag("Savaşta", TK.RED))
	if p.controller != p.owner and p.controller >= 0:
		var cc = gs.countries[p.controller]
		_card_tags.add_child(_tag(("İsyancı: " if cc.is_rebel else "İşgal: ") + cc.name, TK.PURPLE if cc.is_rebel else TK.ORANGE))
	_card_tags.visible = _card_tags.get_child_count() > 0
	_card_stat("Nüfus", "%.1fM" % p.pop, TK.TEXT, true)
	_card_stat("Gelir", Macro.money(p.rev()) + Loc.t("/hf"), TK.GOLD)
	_card_stat("Savunma", "%d" % p.defense, TK.TEXT)
	var army = gs.armies.get(pid)
	var hint := ""
	if p.is_capital:
		var ld: Array = Macro.leader_of(oc)
		if ld[1] != "":
			hint = "%s: %s" % [ld[0], ld[1]]
	if army != null:
		hint += ("\n" if hint != "" else "") + "Ordu: %s asker (%s)" % [Macro.num(army.size), gs.countries[army.owner].name] + ("\nParalı birlik: %s (%d hf kaldı)" % [army.merc, maxi(0, army.merc_until - gs.turn)] if army.merc != "" else "") + (Loc.t("\nElle konuşlu (otomatik komut dışı)") if army.hold and army.owner == me else "") + ((Loc.t("\nKomutan: %s (Sv %d)") % [army.cmd_name, army.cmd_lvl]) if army.cmd_lvl > 0 else "")
	if p.siege > 0:
		hint += ("   /   " if hint != "" else "") + "Kuşatma %d/%d" % [p.siege, p.siege_needed()]
	if p.owner == me and p.unrest >= 6 and p.controller == me:
		hint += ("   /   " if hint != "" else "") + "Huzursuzluk %d/12: ordu bulundur!" % p.unrest
	var moving: bool = selected_army != null and selected_army.owner == me and selected_army.prov != pid
	if selected_army != null:
		if moving:
			hint = "Seçili ordu: %s asker, %s. Emri aşağıdaki düğmeyle ver." % [Macro.num(selected_army.size), gs.provinces[selected_army.prov].name]
		else:
			hint = "Ordu seçili (%s asker). Gidilecek eyalete dokun, sonra emri onayla." % Macro.num(selected_army.size)
	_card_hint.text = hint
	_card_hint.visible = hint != ""
	if moving:
		_abtn("Ordu buraya yürüsün", "gold", "play", "move_army", pid)
		_abtn("Seçimi bırak", "ghost", "x", "deselect", pid)
	if p.owner != me:
		if gs.at_war(me, p.owner) or (p.controller >= 0 and gs.at_war(me, p.controller)):
			_abtn("Taarruz", "danger", "swords", "assault", pid)
		if Carriers.count(gs.countries[me]) > 0 and p.coastal and (gs.at_war(me, p.owner) or (p.controller >= 0 and gs.at_war(me, p.controller))):
			_abtn("Uçak gemisi saldırısı", "danger", "ship", "carrier", pid, gs.countries[me].carrier_cd <= gs.turn)
		if gs.player_has_nukes() and (gs.at_war(me, p.owner) or (p.controller >= 0 and gs.at_war(me, p.controller))):
			_abtn("Nükleer saldırı", "danger", "nuke", "nuke", pid, gs.nuke_cd <= gs.turn)
		if gs.at_war(me, p.owner):
			_abtn("Barış teklif et", "good", "handshake", "peace", p.owner)
		elif not allied:
			var truce_left: int = gs.countries[me].truce.get(p.owner, -1) - gs.turn
			if truce_left > 0:
				_abtn("Ateşkes: %d hafta" % truce_left, "", "hourglass", "none", 0, false)
			else:
				_abtn("Savaş ilan et", "danger", "sword", "war", p.owner)
		if not oc.is_rebel and not gs.at_war(me, p.owner):
			if allied:
				if not gs.countries[me].enemies.is_empty() and not gs.aid_request_foes(p.owner).is_empty():
					_abtn("Yardım iste", "blue", "handshake", "ask_aid", p.owner)
				if not gs.aid_join_foes(p.owner).is_empty():
					_abtn("Savaşına katıl", "danger", "swords", "aid_join", p.owner)
				_abtn("Mali yardım gönder", "gold", "coins", "aid_gold", p.owner)
				_abtn("İttifakı boz", "ghost", "x", "break_alliance", p.owner)
			else:
				_abtn("İttifak teklif et", "blue", "handshake", "alliance", p.owner)
	if not oc.is_rebel:
		_abtn("İlişkiler", "ghost", "handshake", "relations", p.owner)
	if army != null and army.owner == me:
		if selected_army == army:
			if not army.path.is_empty():
				_abtn("Durdur", "", "pause", "stop", pid)
			_abtn("Seçimi bırak", "ghost", "x", "deselect", pid)
		else:
			_abtn("Ordu seç", "gold", "flag", "select_army", pid)
	_card_actions.visible = _card_actions.get_child_count() > 0


# ------------------------------------------------------------------ bildirim

func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_panel.offset_top = BAR_H + TICK_H + 16
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := TK.box(Color(TK.PANEL_SOLID.r, TK.PANEL_SOLID.g, TK.PANEL_SOLID.b, 0.98), TK.RED, 2, 0, 1, Vector4(24, 12, 26, 12))
	sb.border_width_left = 6
	toast_panel.add_theme_stylebox_override("panel", sb)
	toast_lbl = TK.t("", "bodyb", TK.TEXT)
	toast_panel.add_child(toast_lbl)
	toast_panel.modulate.a = 0.0
	root.add_child(toast_panel)


func toast(text: String) -> void:
	toast_lbl.text = text
	toast_panel.reset_size()
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_panel.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)


# ------------------------------------------------------------------ modal pencereler

func _open_sheet(title: String, width: float, tall: bool = false, closable: bool = true, kicker: String = ""):
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	if speed_idx != 0:
		set_speed(0)
		speed_changed.emit(0)
	if sfx != null:
		sfx.play("paper", 0.6)
	var sh = Sheet.open(root, title, width, tall, closable, kicker)
	_modal = sh
	sh.closed.connect(func():
		if _modal == sh:
			_modal = null)
	return sh


func hide_dialog() -> void:
	if _modal != null and is_instance_valid(_modal):
		_modal.close()
	_modal = null


## Tam ekran bir paneli (haber/rapor) modal olarak kaydet.
func set_modal(n) -> void:
	_modal = n


func is_dialog_open() -> bool:
	return _modal != null and is_instance_valid(_modal)


## Basit diyalog: başlık, gövde metni, düğmeler [{text, cb, kind}]
func show_dialog(title: String, body: String, buttons: Array, scene: String = "", icon: String = "") -> void:
	var cancel_cb := Callable()
	for bd in buttons:
		if String(bd.text) in ["Vazgeç", "Reddet", "İptal", "Hayır", "Kapat", "Şimdi değil"]:
			cancel_cb = bd.cb
	var sh = _open_sheet(title, 580, false, buttons.size() < 2 or cancel_cb.is_valid(), "Bildiri")
	sh.on_cancel = cancel_cb
	if icon != "":
		sh.set_icon(icon)
	if scene == "":
		scene = {"Barış": "peace", "Barış teklifi": "peace", "Barış şartları": "peace", "Beraberlik teklifi": "peace",
			"ZAFER!": "peace", "Yenilgi": "war", "İttifak çağrısı": "war", "İttifak teklifi": "alliance"}.get(title, "")
	if scene != "":
		sh.body.add_child(SceneArt.make(scene, 150))
	sh.add_text(body)
	for bd in buttons:
		sh.add_button(bd.text, bd.cb, bd.get("kind", ""), true, "", 160)
	if sfx != null:
		sfx.play("news")


func show_deal_dialog(w, winner: int, options: Array, on_confirm: Callable, on_white: Callable) -> void:
	var budget: int = w.score_of(winner)
	var loser: int = w.other(winner)
	var sh = _open_sheet("Barış Masası", 700, true, true, "Müzakere")
	sh.on_cancel = func(): gs.cancel_proposal()
	sh.add_text("%s ile barış görüşmesi. Savaş puanın: %d. Almak istediğin işgal ettiğin eyaletleri seç (maliyet puandan düşer); seçmediklerin geri verilir." % [gs.countries[loser].name, budget], 22, TK.MUTED)
	var rows: Array = []
	var spent_lbl := TK.t("", "value", TK.GREEN)
	var confirm := TK.button("Anlaşmayı imzala", "gold", "check", Vector2(260, 60))
	var recompute := func():
		var total := 0
		for r in rows:
			if r.btn.button_pressed:
				total += r.cost
		spent_lbl.text = "HARCANAN  %d / %d PUAN" % [total, budget]
		spent_lbl.add_theme_color_override("font_color", TK.RED_TEXT if total > budget else TK.GREEN)
		confirm.disabled = total > budget
	for o in options:
		var pr = gs.provinces[o.pid]
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
		b.toggle_mode = true
		var on_s := TK.line_box(TK.PANEL_LIGHT, TK.GREEN, 5)
		b.add_theme_stylebox_override("pressed", on_s)
		b.add_theme_stylebox_override("hover_pressed", on_s)
		var hb := TK.row_layout(b, 16)
		var tick := TK.IconView.new()
		tick.icon = "check"
		tick.color = TK.GREEN
		tick.custom_minimum_size = Vector2(28, 28)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tick.modulate.a = 0.0
		hb.add_child(tick)
		var nl := TK.t(pr.title() + ("  *" if pr.is_capital else ""), "bodyb", TK.TEXT)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(nl)
		var cl := TK.t("%d PUAN" % o.cost, "mono", TK.GOLD)
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(cl)
		TK.ignore_mouse(hb)
		b.toggled.connect(func(on: bool):
			tick.modulate.a = 1.0 if on else 0.0
			recompute.call())
		sh.body.add_child(b)
		rows.append({"btn": b, "cost": o.cost, "pid": o.pid, "tick": tick})
	var sorted_rows := rows.filter(func(r): return not r.has("term"))
	sorted_rows.sort_custom(func(x, y): return x.cost > y.cost)
	var left := budget
	for r in sorted_rows:
		if r.cost <= left:
			r.btn.button_pressed = true
			left -= r.cost
	for tk in gs.PEACE_TERMS:
		var td: Dictionary = gs.PEACE_TERMS[tk]
		var tb := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
		tb.toggle_mode = true
		var ton := TK.line_box(TK.PANEL_LIGHT, TK.GREEN, 5)
		tb.add_theme_stylebox_override("pressed", ton)
		tb.add_theme_stylebox_override("hover_pressed", ton)
		var thb := TK.row_layout(tb, 16)
		var ttick := TK.IconView.new()
		ttick.icon = "check"
		ttick.color = TK.GREEN
		ttick.custom_minimum_size = Vector2(28, 28)
		ttick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ttick.modulate.a = 0.0
		thb.add_child(ttick)
		var tic := TK.IconView.new()
		tic.icon = Icons.pick(TERM_ICONS[tk][0], TERM_ICONS[tk][1])
		tic.color = TK.TEXT
		tic.custom_minimum_size = Vector2(40, 40)
		tic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thb.add_child(tic)
		var tcol := VBoxContainer.new()
		tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tcol.add_child(TK.t(Loc.t(td.name), "bodyb", TK.TEXT))
		tcol.add_child(TK.t(Loc.t(td.desc), "small", TK.MUTED))
		thb.add_child(tcol)
		var tcl := TK.t("%d PUAN" % td.cost, "mono", TK.GOLD)
		tcl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		thb.add_child(tcl)
		TK.ignore_mouse(thb)
		tb.toggled.connect(func(on: bool):
			ttick.modulate.a = 1.0 if on else 0.0
			recompute.call())
		sh.body.add_child(tb)
		rows.append({"btn": tb, "cost": td.cost, "pid": -1, "term": tk, "tick": ttick})
	sh.body.add_child(spent_lbl)
	recompute.call()
	var white := TK.button("Beraberlik barışı", "ghost", "", Vector2(220, 60))
	white.pressed.connect(func():
		sh.close()
		on_white.call())
	var back := TK.button("Vazgeç", "ghost", "", Vector2(160, 60))
	back.pressed.connect(sh.cancel)
	sh.footer.add_child(back)
	sh.footer.add_child(white)
	confirm.pressed.connect(func():
		var picked: Array = []
		var picked_terms: Array = []
		for r in rows:
			if r.btn.button_pressed:
				if r.has("term"):
					picked_terms.append(r.term)
				else:
					picked.append(r.pid)
		sh.close()
		on_confirm.call(picked, picked_terms))
	sh.footer.add_child(confirm)


# ------------------------------------------------------------------ duraklatma menüsü

func show_pause_menu() -> void:
	var sh = _open_sheet("Duraklatıldı", 460, false, true, "Oyun menüsü")
	var items := [
		["Devam et", "gold", "play", func(): pass],
		["Kaydet", "", "save", func(): save_requested.emit()],
		["Yükle", "", "folder", func(): load_requested.emit()],
		["Ayarlar", "", "gear", func(): Info.open_settings(root, func(): settings_changed.emit(), sfx)],
		["Hedefler ve başarımlar", "", "trophy", func(): show_goals()],
		["Hareket paneli", "", "flag", func(): show_indep()],
		["Savaş Odası", "", "swords", func(): WarRoomUI.open(self)],
		["Siyasi sistem", "", "gavel", func(): show_politics()],
		["Meydan okuma durumu", "", "target", func(): show_daily()],
		["Stratejik geçitler", "", "anchor", func(): show_chokes()],
		["Mağaza", "", "coins", func(): shop_requested.emit()],
		["Öğretici", "", "book", func(): tutorial_requested.emit()],
		["Nasıl oynanır", "", "book", func(): Info.open_howto(root)],
		["Ana menü", "danger", "home", func(): main_menu_requested.emit()],
	]
	for it in items:
		if it[0] == "Hareket paneli" and not Independence.active(gs):
			continue
		if it[0] == "Meydan okuma durumu" and not Daily.active(gs):
			continue
		if it[0] == "Savaş Odası" and (gs.player < 0 or gs.countries[gs.player].enemies.is_empty()) and not (gs.wroom is Dictionary and bool(gs.wroom.get("on", false))):
			continue
		var b := TK.button(it[0], it[1], it[2], Vector2(0, 62), 20)
		var cb: Callable = it[3]
		b.pressed.connect(func():
			_click()
			sh.close()
			cb.call())
		sh.body.add_child(b)


# ------------------------------------------------------------------ Hedefler ve başarımlar

func _missions_block(sh) -> void:
	Missions.ensure_current()
	var rk: Dictionary = Missions.rank_of(Settings.xp)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	var rl := TK.t("%s  /  %d %s" % [Loc.t(rk.name), Settings.xp, Loc.t("puan")], "h3", TK.GOLD)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(rl)
	var st: int = Missions.streak_now()
	top.add_child(TK.t((Loc.t("Seri: %d gün") % st) if st > 0 else Loc.t("Seri yok"), "small", TK.MUTED))
	sh.body.add_child(top)
	if rk.next > 0:
		var pb := ProgressBar.new()
		pb.show_percentage = false
		pb.min_value = rk.base
		pb.max_value = rk.next
		pb.value = Settings.xp
		pb.custom_minimum_size = Vector2(0, 10)
		sh.body.add_child(pb)
	for sec in [["daily", "Günlük görevler"], ["weekly", "Haftalık görevler"]]:
		var h := Label.new()
		h.text = Loc.t(sec[1])
		h.add_theme_font_size_override("font_size", 20)
		h.add_theme_color_override("font_color", TK.GOLD)
		sh.body.add_child(h)
		for t in Settings.missions.get(sec[0], []):
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 12)
			var ic := TK.IconView.new()
			ic.icon = "check" if t.done else "hourglass"
			ic.color = TK.GOLD if t.done else TK.MUTED
			ic.custom_minimum_size = Vector2(34, 34)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			r.add_child(ic)
			var l := Label.new()
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 17)
			l.add_theme_color_override("font_color", TK.GOLD if t.done else TK.TEXT)
			l.text = Loc.t(t.t)
			r.add_child(l)
			r.add_child(TK.t("%d / %d   +%d" % [int(t.p), int(t.n), int(t.xp)], "mono", TK.MUTED))
			sh.body.add_child(r)
	sh.body.add_child(TK.hsep())


## Senaryo / çağ hedefleri (JSON motoru): ilerleme ve kalan süre
func _objectives_block(sh) -> void:
	if gs == null or not Objectives.active(gs):
		return
	var objs: Array = Objectives.list(gs)
	if objs.is_empty():
		return
	var head := Label.new()
	head.text = Loc.t("Görev hedefleri")
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", TK.GOLD)
	sh.body.add_child(head)
	for o in objs:
		var ok: bool = Objectives.is_done(gs, o)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var ic := TK.IconView.new()
		ic.icon = "check" if ok else "flag"
		ic.color = TK.GOLD if ok else TK.MUTED
		ic.modulate.a = 1.0 if ok else 0.55
		ic.custom_minimum_size = Vector2(34, 34)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
		var l := Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 17)
		l.add_theme_color_override("font_color", TK.GOLD if ok else TK.TEXT)
		var txt: String = Objectives.text_of(gs, o)
		if not Objectives.is_required(o):
			txt += " (" + Loc.t("isteğe bağlı") + ")"
		var pr: String = "" if ok else Objectives.progress(gs, o)
		l.text = txt if pr == "" else "%s   %s" % [txt, pr]
		hb.add_child(l)
		sh.body.add_child(hb)
	var dl: int = int(Objectives.src(gs).get("deadline", 0))
	if dl > 0:
		var left: int = maxi(0, dl - (gs.turn - int(gs.scn.start)))
		var dlab := Label.new()
		dlab.text = Loc.t("Kalan süre: %d hafta") % left
		dlab.add_theme_color_override("font_color", TK.RED_TEXT if left < 20 else TK.MUTED)
		sh.body.add_child(dlab)


func show_goals() -> void:
	var sh = _open_sheet("Hedefler ve başarımlar", 640, false, true, "İlerleme")
	_objectives_block(sh)
	_missions_block(sh)
	var nxt: Dictionary = Goals.next_tutorial()
	var head := Label.new()
	head.text = Loc.t("İlk adımlar") if not nxt.is_empty() else Loc.t("Öğretici tamamlandı")
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", TK.GOLD)
	sh.body.add_child(head)
	var done := 0
	var total := 0
	for kind in ["tut", "ach"]:
		if kind == "ach":
			var h2 := Label.new()
			h2.text = Loc.t("Başarımlar")
			h2.add_theme_font_size_override("font_size", 20)
			h2.add_theme_color_override("font_color", TK.GOLD)
			sh.body.add_child(h2)
		for d in Goals.DEFS:
			if d.kind != kind:
				continue
			total += 1
			var ok: bool = Settings.ach.has(d.id)
			if ok:
				done += 1
			var gh := HBoxContainer.new()
			gh.add_theme_constant_override("separation", 12)
			var gic := TK.IconView.new()
			gic.icon = Icons.pick(GOAL_ICONS.get(d.id, "hint"), "star") if not ok or kind == "ach" else "check"
			gic.color = TK.GOLD if ok else TK.MUTED
			gic.modulate.a = 1.0 if ok else 0.45
			gic.custom_minimum_size = Vector2(38, 38)
			gic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			gh.add_child(gic)
			var l := Label.new()
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", 17)
			l.add_theme_color_override("font_color", TK.GOLD if ok else (TK.TEXT if (kind == "tut" and d.id == nxt.get("id", "")) else TK.MUTED))
			l.text = "%s\n%s" % [Loc.t(d.name), Loc.t(d.desc)]
			gh.add_child(l)
			sh.body.add_child(gh)
	var tens := Label.new()
	tens.text = Loc.t("Dünya tepkisi: %d / 100 (fetih arttıkça yükselir; 50'yi aşarsa koalisyon kurulur)") % int(gs.infamy)
	tens.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tens.add_theme_font_size_override("font_size", 16)
	tens.add_theme_color_override("font_color", TK.RED_TEXT if gs.infamy >= 50.0 else TK.MUTED)
	sh.body.add_child(tens)
	var foot := Label.new()
	foot.text = "%d / %d" % [done, total]
	foot.add_theme_color_override("font_color", TK.MUTED)
	sh.body.add_child(foot)


# ------------------------------------------------------------------ Ülke ilişkileri (World Empire tarzı)

func show_relations(cid: int) -> void:
	if gs == null or gs.player < 0 or cid < 0:
		return
	var c = gs.countries[cid]
	var sh = _open_sheet(c.name, 900, false, true, "İlişkiler")
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var fl := TK.flag_rect(c, Vector2(84, 56))
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(fl)
	var ld: Array = Macro.leader_of(c)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	if ld[1] != "":
		info.add_child(TK.t("%s: %s" % [ld[0], ld[1]], "bodyb", TK.TEXT))
	info.add_child(TK.t("%d eyalet   /   asker %s   /   gelir %s" % [c.prov_owned, Macro.compact(c.troops), Macro.money(c.income)], "small", TK.MUTED))
	var bl: String = ""
	for b in gs.blocs:
		if b["id"] == c.alliance:
			bl = b["name"]
	if bl != "":
		info.add_child(TK.t("İttifak bloğu: %s" % bl, "small", TK.BLUE))
	head.add_child(info)
	sh.body.add_child(head)
	sh.body.add_child(TK.hsep())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y * 0.42, 200.0, 420.0))
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	scroll.add_child(content)
	sh.body.add_child(scroll)
	var sections: Array = []
	var wars_l: Array = []
	for w in gs.wars:
		if w.a == cid:
			wars_l.append([w.b, "%d - %d   %dH" % [w.score_a, w.score_b, gs.turn - w.start]])
		elif w.b == cid:
			wars_l.append([w.a, "%d - %d   %dH" % [w.score_b, w.score_a, gs.turn - w.start]])
	sections.append(["Savaşta", TK.RED_TEXT, wars_l])
	var ally_l: Array = []
	for a in c.allies:
		ally_l.append([a, ""])
	if c.alliance >= 0:
		for b2 in gs.blocs:
			if b2["id"] == c.alliance:
				for m in b2["members"]:
					if m != cid and not c.allies.has(m):
						ally_l.append([m, "blok"])
	sections.append(["Müttefikler", TK.BLUE, ally_l])
	var truce_l: Array = []
	for k in c.truce:
		var left: int = int(c.truce[k]) - gs.turn
		if left > 0 and gs.countries[int(k)].alive and not gs.at_war(cid, int(k)):
			truce_l.append([int(k), "%d hf" % left])
	sections.append(["Ateşkes", TK.PURPLE, truce_l])
	for sec in sections:
		content.add_child(TK.spacer(0, 10))
		content.add_child(TK.t("%s (%d)" % [Loc.t(sec[0]), sec[2].size()], "kicker", sec[1]))
		if sec[2].is_empty():
			content.add_child(TK.t("Yok", "small", TK.FAINT))
		for e in sec[2]:
			var oid: int = e[0]
			var oc2 = gs.countries[oid]
			var b3 := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 56)
			var hb := TK.row_layout(b3, 12)
			var f2 := TK.flag_rect(oc2, Vector2(42, 28))
			f2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(f2)
			var nl := TK.t(oc2.name, "bodyb", TK.TEXT)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(nl)
			if e[1] != "":
				hb.add_child(_stat_lbl(e[1], 170, TK.MUTED))
			TK.ignore_mouse(hb)
			b3.pressed.connect(func():
				_click()
				sh.close()
				show_relations(oid))
			content.add_child(b3)
	sh.add_button("Haritada göster", func(): action.emit("rel_view", cid), "blue", true, "handshake", 240)
	if cid == gs.player and not c.allies.is_empty() and not c.enemies.is_empty():
		sh.add_button("Müttefiklerden yardım iste", func(): action.emit("ask_aid_all", cid), "gold", true, "handshake", 300)
	if cid != gs.player and gs.at_war(gs.player, cid):
		sh.add_button("Büyük Harekât", func(): show_grand_op(cid), "danger", true, "swords", 230)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Bağımsızlık Yolu paneli

func show_indep() -> void:
	if gs == null or not Independence.active(gs):
		return
	var sh = _open_sheet(gs.countries[gs.player].name, 860, true, true, "Bağımsızlık Yolu")
	sh.set_icon("founding_scroll", "flag")
	IndepUI.fill_panel(sh, gs, toast, func():
		sh.close()
		show_indep(), func(pid: int):
			hide_dialog()
			action.emit("focus_city", pid))
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Siyasi sistem

func show_politics() -> void:
	if gs == null or gs.player < 0:
		return
	Politics.ensure(gs)
	var c = gs.countries[gs.player]
	var r: String = Politics.regime(gs, gs.player)
	var sh = _open_sheet("Siyasi sistem", 820, true, true, c.name)
	sh.set_icon("politics", "gavel")
	sh.body.add_child(TK.t(Politics.name_of(r), "h2", TK.GOLD))
	var dl := TK.t(Politics.desc_of(r), "body", TK.MUTED)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(dl)
	sh.body.add_child(TK.hsep())
	var rows: Array = []
	var we: int = Politics.weeks_to_election(gs, gs.player)
	if we >= 0 and not Macro.era_on:
		rows.append([Loc.t("Sonraki seçim"), Loc.t("%d hafta sonra") % we])
	elif r != "democracy":
		rows.append([Loc.t("Seçim"), Loc.t("Yok")])
	var p: float = Politics.coup_risk(gs, gs.player)
	rows.append([Loc.t("Darbe / kriz riski"), Politics.risk_label(p)])
	rows.append([Loc.t("İstikrar"), "%d" % int(c.stability)])
	if Politics.martial_on(gs, gs.player):
		rows.append([Loc.t("Sıkıyönetim"), Loc.t("%d hafta kaldı") % (int(gs.pol.martial[str(gs.player)]) - gs.turn)])
	for rw in rows:
		var hb := HBoxContainer.new()
		var a := TK.t(String(rw[0]), "body", TK.MUTED)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(a)
		hb.add_child(TK.t(String(rw[1]), "body", TK.TEXT))
		sh.body.add_child(hb)
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Siyasi eylemler", "kicker", TK.GOLD))
	for a in Politics.actions(gs):
		var act: Dictionary = a
		var b := TK.button(String(act.label), "" if bool(act.ok) else "ghost", Icons.pick({"democratize": "democratize", "centralize": "power_tower", "martial": "martial_law"}.get(String(act.id), ""), ""), Vector2(0, 58), 19)
		b.disabled = not bool(act.ok)
		var aid: String = String(act.id)
		b.pressed.connect(func():
			_click()
			var res: String = Politics.do_action(gs, aid)
			if res != "":
				toast(res)
			refresh_top()
			sh.close()
			show_politics())
		sh.body.add_child(b)
		var ds := TK.t(String(act.desc) + (("   (" + String(act.why) + ")") if String(act.why) != "" else ""), "small", TK.FAINT)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(ds)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Günlük Meydan Okuma

func show_daily() -> void:
	if gs == null or not Daily.active(gs):
		return
	var tw: String = String(gs.daily.twist)
	var sh = _open_sheet("Günlük Meydan Okuma", 760, false, true, gs.countries[gs.player].name)
	sh.set_icon("daily_challenge", "target")
	sh.body.add_child(TK.t(Daily.twist_name(tw), "caps", TK.GOLD))
	var dl := TK.t(Daily.twist_desc(tw), "small", TK.MUTED)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(dl)
	sh.body.add_child(TK.hsep())
	if bool(gs.daily.get("done", false)):
		sh.body.add_child(TK.chip(Icons.pick("score_star", "star"), Loc.t("Tamamlandı. Skor: %d") % int(gs.daily.score), TK.GREEN, TK.GOLD))
	else:
		sh.body.add_child(TK.chip(Icons.pick("score_star", "star"), Loc.t("Anlık skor: %d") % Daily.score(gs), TK.TEXT, TK.GOLD))
		sh.body.add_child(TK.t(Loc.t("Kalan süre: %d hafta") % Daily.weeks_left(gs), "body", TK.MUTED))
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Stratejik geçitler

func show_chokes(only: String = "") -> void:
	if gs == null or gs.player < 0:
		return
	Chokepoints.ensure(gs)
	var sh = _open_sheet("Stratejik geçitler", 880, true, true, "Dünya ticareti")
	sh.set_icon("strait_control", "anchor")
	var t1 := TK.t("Boğazları ve kanalları kontrol eden ülke geçişi yönetir: ücret alabilir, düşmana kapatabilir ya da herkese kapatabilir. Anahtar eyaleti ele geçirerek kontrolü alırsın.", "small", TK.MUTED)
	t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(t1)
	var total := 0.0
	for id in Chokepoints.ids():
		total += Chokepoints.effect_on(gs, id, gs.player)
	var sum_txt: String = Loc.t("Geçitlerin gelirine toplam etkisi: %+.1f%%") % (total * 100.0)
	var sum_col: Color = TK.GREEN if total > 0.0005 else (TK.RED_TEXT if total < -0.0005 else TK.MUTED)
	if Icons.pick("trade_shock", "") != "":
		sh.body.add_child(TK.chip("trade_shock", sum_txt, sum_col, TK.GOLD))
	else:
		sh.body.add_child(TK.t(sum_txt, "small", sum_col))
	for id in Chokepoints.ids():
		if only != "" and id != only:
			continue
		sh.body.add_child(TK.hsep())
		var st: Dictionary = gs.chokes[id]
		var ctrl: int = int(st.get("ctrl", -1))
		var mode: String = String(st.get("mode", "open"))
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		var nm := TK.t(Chokepoints.name_of(id), "caps", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		var who: String = gs.countries[ctrl].name if ctrl >= 0 else Loc.t("Kimse")
		head.add_child(TK.t(who, "body", TK.GOLD if ctrl == gs.player else TK.MUTED))
		sh.body.add_child(head)
		var eff: float = Chokepoints.effect_on(gs, id, gs.player)
		var line: String = Chokepoints.mode_name(mode)
		if absf(eff) > 0.0005:
			line += "   /   " + Loc.t("sana etkisi: %+.1f%%") % (eff * 100.0)
		sh.body.add_child(TK.t(line, "small", TK.GREEN if eff > 0.0005 else (TK.RED_TEXT if eff < -0.0005 else TK.MUTED)))
		if ctrl == gs.player:
			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 8)
			row.add_theme_constant_override("v_separation", 8)
			for m in Chokepoints.MODES:
				var mm: String = m
				var b := TK.button(Chokepoints.mode_name(mm), "primary" if mm == mode else "", Icons.pick({"toll": "toll_gate", "enemy": "strait_closed", "all": "strait_closed", "open": "shipping_lane"}.get(mm, ""), ""), Vector2(180, 52), 17)
				b.pressed.connect(func():
					_click()
					var err: String = Chokepoints.set_mode(gs, id, mm)
					if err != "":
						toast(Loc.t(err))
						return
					sh.close()
					show_chokes(only))
				row.add_child(b)
			sh.body.add_child(row)
			var dl := TK.t(Chokepoints.mode_desc(mode), "small", TK.FAINT)
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sh.body.add_child(dl)
	if only != "":
		sh.add_button("Tüm geçitler", func(): show_chokes(), "", true, "", 200)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Büyük Harekât

func show_grand_op(cid: int) -> void:
	if gs == null or gs.player < 0 or cid < 0:
		return
	GrandOp.ensure(gs)
	var foe = gs.countries[cid]
	var sh = _open_sheet("Büyük Harekât", 820, false, true, foe.name)
	sh.set_icon("grand_operation", "swords")
	sh.add_text("Kara, hava, deniz, sabotaj ve siber saldırıyı tek planda birleştiren bitirici operasyon. Pahalıdır, 3 hafta sürer ve uzun süre tekrarlanamaz. Başarırsan hedefin şehirlerinin yaklaşık yarısı bir anda düşer.", 20, TK.MUTED)
	var name_edit := LineEdit.new()
	name_edit.text = GrandOp.default_name(gs)
	name_edit.max_length = 24
	name_edit.placeholder_text = Loc.t("Harekâtın adı")
	name_edit.custom_minimum_size = Vector2(0, 56)
	sh.body.add_child(name_edit)
	sh.body.add_child(TK.t("Hazırlık", "kicker", TK.FAINT))
	var comp: Dictionary = GrandOp.components(gs, cid)
	var w: Dictionary = GrandOp.active_weights()
	for k in GrandOp.COMP:
		if float(w[k]) <= 0.0:
			continue
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var l := TK.t(GrandOp.COMP_NAME[k], "body", TK.TEXT)
		l.custom_minimum_size = Vector2(130, 0)
		hb.add_child(l)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = float(comp[k]) * 100.0
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 22)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(bar)
		var pl := TK.t("%%%d" % int(float(comp[k]) * 100.0), "small", TK.MUTED)
		pl.custom_minimum_size = Vector2(60, 0)
		hb.add_child(pl)
		sh.body.add_child(hb)
	var od: Dictionary = GrandOp.odds(gs, cid)
	sh.body.add_child(TK.hsep())
	var orow := HBoxContainer.new()
	orow.add_theme_constant_override("separation", 14)
	for e in [["Zafer", od.win, TK.GREEN], ["Kısmi", od.partial, TK.GOLD], ["Fiyasko", od.fail, TK.RED_TEXT]]:
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", -4)
		v.add_child(TK.t(e[0], "kicker", e[2]))
		v.add_child(TK.t("%%%d" % int(round(float(e[1]) * 100.0)), "h3", e[2]))
		orow.add_child(v)
	sh.body.add_child(orow)
	var total: int = GrandOp.target_cities(gs, cid)
	var cost: float = GrandOp.cost(gs)
	var lines: Array = [
		Loc.t("Zaferde ele geçecek şehir: %d / %d") % [mini(GrandOp.win_count(total), total), total],
		Loc.t("Bedel: %s   /   Dünya tepkisi: +%d (zaferde +%d daha)") % [Macro.money(cost), int(GrandOp.INFAMY_LAUNCH), int(GrandOp.INFAMY_WIN)],
	]
	var left: int = GrandOp.cooldown_left(gs)
	if left > 0:
		lines.append(Loc.t("Genelkurmay yeniden hazırlanıyor (%d hafta).") % left)
	for ln in lines:
		var ll := TK.t(ln, "small", TK.MUTED)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(ll)
	var err: String = GrandOp.check(gs, cid)
	if err != "":
		var el := TK.t(err, "small", TK.RED_TEXT)
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(el)
	var go: Button = sh.add_button("Harekâtı başlat", func():
		var r: Dictionary = GrandOp.launch(gs, cid, name_edit.text)
		if r.err != "":
			toast(Loc.t(r.err))
		else:
			toast(Loc.t("Büyük Harekât başladı: %s") % r.op.name), "danger", true, "swords", 260)
	go.disabled = err != ""
	sh.add_button("Vazgeç", func(): pass, "ghost", true, "", 150)


# ------------------------------------------------------------------ Birleşmiş Milletler

func show_un_targets(kind: String) -> void:
	if gs == null or gs.player < 0:
		return
	var def: Dictionary = UN.KINDS[kind]
	var sh = _open_sheet(def.name, 860, false, true, "Birleşmiş Milletler")
	sh.add_text(Loc.t("Önergenin hedefini seç.") if kind != "ceasefire" else Loc.t("Ateşkes istenecek savaşı seç."), 22, TK.MUTED)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y * 0.5, 220.0, 440.0))
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	scroll.add_child(content)
	sh.body.add_child(scroll)
	var list: Array = UN.targets(gs, kind)
	var shown := 0
	for t in list:
		var tid: int = t
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
		var hb := TK.row_layout(b, 14)
		if kind == "ceasefire":
			var w = gs.wars[tid]
			var fa := TK.flag_rect(gs.countries[w.a], Vector2(48, 32))
			fa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(fa)
			hb.add_child(TK.t(gs.countries[w.a].name, "bodyb", TK.TEXT))
			var sw := TK.IconView.new()
			sw.icon = "swords"
			sw.color = TK.RED_TEXT
			sw.custom_minimum_size = Vector2(26, 26)
			sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(sw)
			var fb := TK.flag_rect(gs.countries[w.b], Vector2(48, 32))
			fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(fb)
			var lb := TK.t(gs.countries[w.b].name, "bodyb", TK.TEXT)
			lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(lb)
			hb.add_child(_stat_lbl("%dH" % (gs.turn - w.start), 70, TK.MUTED))
		else:
			var c = gs.countries[tid]
			var f := TK.flag_rect(c, Vector2(48, 32))
			f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(f)
			var nl := TK.t(c.name, "bodyb", TK.TEXT)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(nl)
			hb.add_child(_stat_lbl("%d" % int(c.stability), 70, TK.MUTED))
			hb.add_child(_stat_lbl(Macro.compact(c.troops), 100, TK.MUTED))
		TK.ignore_mouse(hb)
		b.pressed.connect(func():
			_click()
			sh.close()
			var r: Dictionary = UN.propose(gs, kind, gs.player, tid)
			var title: String = Loc.t("Önerge kabul edildi") if r.passed else (Loc.t("Önerge reddedildi") if r.ok else Loc.t("Önerge verilemedi"))
			show_dialog(title, r.text, [{"text": "Tamam", "cb": func(): pass}]))
		content.add_child(b)
		shown += 1
		if shown >= 60:
			break
	if list.is_empty():
		content.add_child(TK.t("Geçerli bir hedef yok.", "body", TK.MUTED))
	sh.add_button("Geri", func(): show_world_panel(4), "", true, "", 160)


# ------------------------------------------------------------------ Dünya paneli

func _rel_tag(cid: int) -> Control:
	var me: int = gs.player
	if cid == me:
		return _tag("Sen", TK.GREEN)
	if gs.at_war(me, cid):
		return _tag("Savaş", TK.RED)
	if gs.is_allied(me, cid):
		return _tag("Müttefik", TK.BLUE)
	return null


func _stat_lbl(text: String, w: float, col: Color = TK.TEXT) -> Label:
	var l := TK.t(text, "mono", col)
	l.custom_minimum_size = Vector2(w, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func show_world_panel(tab: int = 0) -> void:
	if gs == null or gs.player < 0:
		return
	var sh = _open_sheet("Dünya", 940, false, true, "Durum odası")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	sh.body.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y * 0.5, 220.0, 460.0))
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	scroll.add_child(content)
	sh.body.add_child(scroll)
	var state := {"tab": tab, "filter": 0, "render": Callable()}
	var names := ["Ülkeler", "Savaşlar", "Haberler", "İttifaklar", "BM"]
	var icons := ["flag", "swords", "news", "handshake", "gavel"]
	var tab_n: int = 5 if UN.available(gs) else 4
	var tab_btns: Array = []
	var build_countries := func():
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 14)
		head.add_child(TK.spacer(14, 0))
		head.add_child(TK.fill())
		for hd in [["Eyalet", 100.0], ["Gelir/hf", 130.0], ["Asker", 100.0]]:
			var hl := TK.t(hd[0], "kicker", TK.FAINT)
			hl.custom_minimum_size = Vector2(hd[1], 0)
			hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			head.add_child(hl)
		head.add_child(TK.spacer(14, 0))
		content.add_child(head)
		var order: Array = []
		var rebels: Array = []
		for c in gs.countries:
			if not c.alive:
				continue
			(rebels if c.is_rebel else order).append(c)
		order.sort_custom(func(a, b): return a.prov_owned > b.prov_owned)
		var rank := 1
		for c in order:
			var cid: int = c.id
			var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 64)
			if cid == gs.player:
				TK.row_select(b, true, TK.PAPER)
			var hb := TK.row_layout(b, 14)
			var rl := TK.t("%02d" % rank, "mono", TK.FAINT)
			rl.custom_minimum_size = Vector2(40, 0)
			rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(rl)
			var f := TK.flag_rect(c, Vector2(48, 32))
			f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(f)
			var nl := TK.t(c.name, "bodyb", TK.TEXT)
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(nl)
			var tg := _rel_tag(cid)
			if tg != null:
				tg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				hb.add_child(tg)
			hb.add_child(TK.fill())
			hb.add_child(_stat_lbl(str(c.prov_owned), 100.0))
			hb.add_child(_stat_lbl(Macro.money(c.income), 130.0, TK.GOLD))
			hb.add_child(_stat_lbl(Macro.compact(c.troops), 100.0, TK.MUTED))
			TK.ignore_mouse(hb)
			b.pressed.connect(func():
				_click()
				sh.close()
				action.emit("focus_country", cid))
			content.add_child(b)
			rank += 1
		if not rebels.is_empty():
			content.add_child(TK.spacer(0, 16))
			content.add_child(TK.t("Devlet dışı gruplar", "kicker", TK.PURPLE))
			for c in rebels:
				var cid2: int = c.id
				var b2 := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 60)
				var hb2 := TK.row_layout(b2, 14)
				var f2 := TK.flag_rect(c, Vector2(48, 32))
				f2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				hb2.add_child(f2)
				var nl2 := TK.t(c.name, "bodyb", TK.TEXT)
				nl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				nl2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				hb2.add_child(nl2)
				hb2.add_child(_stat_lbl("%d EYALET" % c.prov_held, 150))
				hb2.add_child(_stat_lbl("%s ASKER" % Macro.compact(c.troops), 150, TK.MUTED))
				TK.ignore_mouse(hb2)
				b2.pressed.connect(func():
					_click()
					sh.close()
					action.emit("focus_country", cid2))
				content.add_child(b2)
	var build_wars := func():
		if gs.wars.is_empty():
			var l := TK.t("Şu an dünyada aktif bir savaş yok.", "body", TK.MUTED)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(TK.spacer(0, 40))
			content.add_child(l)
			return
		var ws: Array = gs.wars.duplicate()
		ws.sort_custom(func(a, b): return (1 if a.involves(gs.player) else 0) > (1 if b.involves(gs.player) else 0))
		for w in ws:
			var ca = gs.countries[w.a]
			var cb = gs.countries[w.b]
			var mine: bool = w.involves(gs.player)
			var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 72)
			if mine:
				TK.row_select(b, true, TK.RED)
			var hb := TK.row_layout(b, 14)
			var fa := TK.flag_rect(ca, Vector2(48, 32))
			fa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(fa)
			var la := TK.t(ca.name, "bodyb", TK.TEXT)
			la.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(la)
			var sw := TK.IconView.new()
			sw.icon = "swords"
			sw.color = TK.RED_TEXT
			sw.custom_minimum_size = Vector2(28, 28)
			sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(sw)
			var fb := TK.flag_rect(cb, Vector2(48, 32))
			fb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(fb)
			var lb := TK.t(cb.name, "bodyb", TK.TEXT)
			lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hb.add_child(lb)
			hb.add_child(_stat_lbl("%d - %d" % [w.score_a, w.score_b], 110, TK.GOLD))
			hb.add_child(_stat_lbl("%dH" % (gs.turn - w.start), 70, TK.MUTED))
			TK.ignore_mouse(hb)
			var aid: int = w.a
			b.pressed.connect(func():
				_click()
				sh.close()
				action.emit("focus_country", aid))
			content.add_child(b)
	var build_blocs := func():
		if gs.blocs.is_empty():
			content.add_child(TK.t("Henüz kurulmuş bir ittifak yok. Politika > İttifak sekmesinden kendi ittifakını kurabilirsin.", "body", TK.MUTED))
		for b in gs.blocs:
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", TK.line_box(Color(0, 0, 0, 0), TK.LINE))
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 16)
			box.add_child(hb)
			var ev := Emblem.new()
			ev.custom_minimum_size = Vector2(84, 84)
			ev.set_emblem(b["emblem"])
			ev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(ev)
			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_theme_constant_override("separation", 2)
			var mine: bool = gs.countries[gs.player].alliance == b["id"]
			tv.add_child(TK.t(b["name"] + ("   (senin)" if mine else ""), "bodyb", TK.PAPER if mine else TK.TEXT))
			var fl := HFlowContainer.new()
			fl.add_theme_constant_override("h_separation", 6)
			fl.add_theme_constant_override("v_separation", 4)
			for m in b["members"]:
				var f := TK.flag_rect(gs.countries[m], Vector2(36, 24))
				fl.add_child(f)
			tv.add_child(fl)
			var pw := 0.0
			for m2 in b["members"]:
				pw += gs.countries[m2].troops
			tv.add_child(TK.t("%d üye   /   toplam asker %s" % [b["members"].size(), Macro.compact(pw)], "small", TK.FAINT))
			hb.add_child(tv)
			content.add_child(box)
			content.add_child(TK.spacer(0, 6))
	var build_un := func():
		var hd := TK.t("%s   /   %s" % [Loc.t("Birleşmiş Milletler"), Loc.t("%d üye   /   karar salt çoğunlukla, veto yok") % UN.members(gs).size()], "kicker", TK.MUTED)
		content.add_child(hd)
		content.add_child(TK.spacer(0, 8))
		for kind in UN.ORDER:
			var k: String = kind
			var def: Dictionary = UN.KINDS[k]
			var left: int = UN.cooldown_left(gs, k)
			var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 92)
			var hb := TK.row_layout(b, 14)
			var uic := TK.IconView.new()
			uic.icon = Icons.pick(UN_ICONS[k][0], UN_ICONS[k][1])
			uic.color = TK.TEXT
			uic.custom_minimum_size = Vector2(44, 44)
			uic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(uic)
			var tv := VBoxContainer.new()
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tv.add_theme_constant_override("separation", 0)
			tv.add_child(TK.t(def.name, "bodyb", TK.TEXT))
			var dl := TK.t(def.desc, "small", TK.MUTED)
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tv.add_child(dl)
			hb.add_child(tv)
			var cost: float = UN.cost_of(gs, k)
			var st: String = (Loc.t("%d hf sonra") % left) if left > 0 else (Loc.t("Maliyet %s") % Macro.money(cost) if cost > 0.0 else Loc.t("Hazır"))
			hb.add_child(_stat_lbl(st, 150, TK.RED_TEXT if left > 0 else TK.GOLD))
			TK.ignore_mouse(hb)
			b.disabled = left > 0
			b.pressed.connect(func():
				_click()
				sh.close()
				show_un_targets(k))
			content.add_child(b)
		content.add_child(TK.spacer(0, 14))
		content.add_child(TK.t("Son kararlar", "kicker", TK.FAINT))
		if gs.un_log.is_empty():
			content.add_child(TK.t("Henüz karar alınmadı.", "body", TK.MUTED))
		for i in range(gs.un_log.size() - 1, maxi(-1, gs.un_log.size() - 7), -1):
			var e: Dictionary = gs.un_log[i]
			var tl := TK.t("%s   %s" % [Names.date_string(int(e.turn)), e.text], "small", TK.GREEN if e.ok else TK.MUTED)
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(tl)
			content.add_child(TK.spacer(0, 4))
	var kinds_of := [
		[],
		["war", "war_player", "capture", "capture_player", "lost_player", "battle", "elim", "cyber", "ops"],
		["peace", "alliance"],
		["event", "event_player", "rebel", "rebel_player", "info", "rank", "arms"],
	]
	var build_news := func():
		var fr := HBoxContainer.new()
		fr.add_theme_constant_override("separation", 6)
		var fnames := ["Tümü", "Savaş", "Diplomasi", "Olaylar"]
		for i in 4:
			var idx := i
			var fb := TK.button(fnames[i], "gold" if state.filter == i else "ghost", "", Vector2(0, 52), 15)
			fb.pressed.connect(func():
				_click()
				state.filter = idx
				state.render.call())
			fr.add_child(fb)
		content.add_child(fr)
		content.add_child(TK.spacer(0, 6))
		var shown := 0
		for i in range(gs.news_log.size() - 1, -1, -1):
			var n = gs.news_log[i]
			var fl: Array = kinds_of[state.filter]
			if not fl.is_empty() and not (n.kind in fl):
				continue
			var info: Array = _news_info(n.kind)
			var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 0)
			var hb := HBoxContainer.new()
			hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.offset_left = 0
			hb.offset_right = -14
			hb.add_theme_constant_override("separation", 14)
			var bar := ColorRect.new()
			bar.color = info[1]
			bar.custom_minimum_size = Vector2(5, 0)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(bar)
			var nic := _news_icon_view(info[2] if n.get("ic", "") == "" else n.ic, 34)
			nic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(nic)
			var tv := VBoxContainer.new()
			tv.add_theme_constant_override("separation", 0)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dl := TK.t("%s   %s" % [Names.date_string(n.turn), info[0]], "kicker", info[1])
			tv.add_child(dl)
			var tl := TK.t(n.text, "body", TK.TEXT)
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tv.add_child(tl)
			hb.add_child(tv)
			b.add_child(hb)
			b.custom_minimum_size = Vector2(0, 108 if n.text.length() > 64 else 82)
			var pid: int = n.prov
			b.pressed.connect(func():
				_click()
				sh.close()
				if pid >= 0:
					action.emit("focus", pid))
			content.add_child(b)
			shown += 1
			if shown >= 60:
				break
	state.render = func():
		for ch in content.get_children():
			content.remove_child(ch)
			ch.queue_free()
		for i in tab_btns.size():
			TK.style_button(tab_btns[i], "gold" if state.tab == i else "ghost")
			var ivb = tab_btns[i].get_meta("iv_btn")
			ivb.color = TK.INK if state.tab == i else TK.MUTED
			ivb.queue_redraw()
		match state.tab:
			0:
				build_countries.call()
			1:
				build_wars.call()
			3:
				build_blocs.call()
			4:
				build_un.call()
			_:
				build_news.call()
	for i in tab_n:
		var idx := i
		var tb := TK.button(names[i], "ghost", icons[i], Vector2(0, 56), 17)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(func():
			_click()
			state.tab = idx
			state.render.call())
		tab_btns.append(tb)
		tabs.add_child(tb)
	state.render.call()
	sh.add_button("Kapat", func(): pass, "", true, "", 160)


func set_hud_visible(v: bool) -> void:
	topbar.visible = v
	ticker.visible = v
	side.visible = v
	if not v:
		card.visible = false
