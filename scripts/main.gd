extends Node
## Oyun denetleyicisi: açılış → ana menü → ülke seçimi → oyun akışını yönetir; harita, arayüz ve ses arasında köprüdür.

const Formables = preload("res://scripts/formables.gd")
const Model = preload("res://scripts/model.gd")
const Icons = preload("res://scripts/icons.gd")
const SceneArt = preload("res://scripts/scene_art.gd")
const TK = preload("res://scripts/theme_kit.gd")
const GS = preload("res://scripts/game_state.gd")
const ScenarioEditor = preload("res://scripts/scenario_editor.gd")
const UserScn = preload("res://scripts/user_scn.gd")
const MapView = preload("res://scripts/map_view.gd")
const UI = preload("res://scripts/ui.gd")
const Menu = preload("res://scripts/menu.gd")
const Scenarios = preload("res://scripts/scenarios.gd")
const Eras = preload("res://scripts/eras.gd")
const AssaultUI = preload("res://scripts/assault_ui.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const CabinetUI = preload("res://scripts/cabinet_ui.gd")
const SendUI = preload("res://scripts/send_ui.gd")
const AppointUI = preload("res://scripts/appoint_ui.gd")
const TurnUI = preload("res://scripts/turn_ui.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Loc = preload("res://scripts/loc.gd")
const UN = preload("res://scripts/un.gd")
const Macro = preload("res://scripts/macro.gd")
const Carriers = preload("res://scripts/carriers.gd")
const Missions = preload("res://scripts/missions.gd")
const Names = preload("res://scripts/names.gd")
const Settings = preload("res://scripts/settings.gd")
const Info = preload("res://scripts/info_sheets.gd")

const TURN_SECONDS := [0.0, 1.2, 0.6, 0.22]
const Goals = preload("res://scripts/goals.gd")
const Notifier = preload("res://scripts/notifier.gd")
const Saves = preload("res://scripts/saves.gd")
const AP = preload("res://scripts/ap.gd")
const Independence = preload("res://scripts/independence.gd")
const Career = preload("res://scripts/career.gd")
const CareerUI = preload("res://scripts/career_ui.gd")
const EraMoments = preload("res://scripts/era_moments.gd")
const Daily = preload("res://scripts/daily.gd")
const Politics = preload("res://scripts/politics.gd")
const ApUi = preload("res://scripts/ap_ui.gd")
const SlotsUI = preload("res://scripts/slots_ui.gd")
const FOCUS_ZOOM := 3.4

var gs
var map
var ui
var menu
var sfx
var timer: Timer
var drift_timer: Timer
var speed_idx := 0
var turn_busy := false
var selected_pid := -1
var selected_army = null
var tutorial = null
var _cab_last := -99
var _cab_recent: Array = []
var _cab_rng := RandomNumberGenerator.new()
var playing := false
var mode := "splash"            # splash | menu | select | game
var world_rng := RandomNumberGenerator.new()
var _drift_i := 0
var era_layer: CanvasLayer
var era_rect: ColorRect
var notifier: Node


func _ready() -> void:
	# kaydırmalı listelerde kaydırırken parmağın değdiği düğme basılmış sayılmasın
	get_tree().node_added.connect(func(n: Node): if n is Button: TK.guard_if_scrolled.call_deferred(n))
	Settings.load_all()
	Settings.language = Loc.setup(Settings.language)
	Settings.apply_display(get_tree())
	TK.install_touch_scroll(get_tree())
	Settings.refresh_auto_scale.call_deferred(get_tree())
	if OS.has_feature("mobile"):
		Engine.max_fps = 60                  # 90/120 Hz ekranlarda boşuna ısınma/kasma olmasın
		OS.low_processor_usage_mode = true   # ekran değişmiyorsa çizim yapılmaz (pil + ısı)
	RenderingServer.set_default_clear_color(Color(0.03, 0.06, 0.11))
	world_rng.randomize()
	notifier = Notifier.new()
	add_child(notifier)
	sfx = Sfx.new()
	add_child(sfx)
	sfx.context_cb = _audio_context
	map = MapView.new()
	add_child(map)
	ui = UI.new()
	ui.sfx = sfx
	add_child(ui)
	menu = Menu.new()
	menu.sfx = sfx
	add_child(menu)
	_build_era_look()
	timer = Timer.new()
	timer.timeout.connect(_on_tick)
	add_child(timer)
	drift_timer = Timer.new()
	drift_timer.wait_time = 13.0
	drift_timer.timeout.connect(_drift_step)
	add_child(drift_timer)
	map.tapped.connect(_on_map_tapped)
	ScenarioEditor.pick_hook = _begin_map_pick
	ScenarioEditor.preview_hook = _begin_map_preview
	map.choke_tapped.connect(_on_choke_tapped)
	ui.speed_changed.connect(_on_speed_changed)
	ui.step_requested.connect(_on_step)
	ui.action.connect(_on_ui_action)
	ui.settings_changed.connect(_apply_settings)
	ui.main_menu_requested.connect(_go_main_menu)
	ui.tutorial_requested.connect(_start_tutorial)
	ui.shop_requested.connect(func(): ApUi.open(ui.root, ui.toast))
	ui.load_requested.connect(func(): SlotsUI.open(ui.root, "load", _load_game, ui._click))
	ui.save_requested.connect(func(): SlotsUI.open(ui.root, "save", _save_game, ui._click))
	menu.splash_done.connect(_on_splash_done)
	menu.play_pressed.connect(_to_select)
	menu.era_chosen.connect(func(id: String): _start_era(id))
	menu.scenario_era.connect(func(sid: String, era: String): _start_era(era, sid))
	menu.indep_start.connect(_start_indep)
	menu.career_era.connect(_career_pick_era)
	menu.daily_start.connect(_start_daily)
	menu.continue_pressed.connect(_on_continue)
	menu.back_pressed.connect(_back_to_menu)
	menu.start_country.connect(_on_start_requested)
	menu.preview_country.connect(_on_preview_country)
	menu.settings_changed.connect(_apply_settings)
	menu.quit_pressed.connect(func(): get_tree().quit())
	get_tree().root.size_changed.connect(_on_resized)
	_new_world()
	map.input_enabled = false
	_apply_settings()
	_start_demo()


func _on_resized() -> void:
	Settings.refresh_auto_scale(get_tree())
	_update_insets()


func _update_insets() -> void:
	match mode:
		"select":
			map.ui_insets = Vector4(470, 0, 0, 0)
		"game":
			map.ui_insets = Vector4(0, 124, 70, 0)
		_:
			map.ui_insets = Vector4(0, 0, 0, 0)


func _apply_settings() -> void:
	Settings.apply_display(get_tree())
	sfx.apply_settings()
	var bare: bool = mode == "menu" or mode == "splash"
	map.hud.show_country_names = Settings.country_names and not bare
	map.hud.show_province_names = Settings.province_names and not bare
	map.hud.show_armies = Settings.armies and mode == "game"
	map.set_quality(Settings.smooth)
	map.hud.queue_redraw()
	menu.continue_btn.visible = Saves.any()
	if Settings.notifications and notifier != null:
		notifier.ask_permission()


# ------------------------------------------------------------------ dünya ve akış

func _build_era_look() -> void:
	era_layer = CanvasLayer.new()
	era_layer.layer = 100
	add_child(era_layer)
	era_rect = ColorRect.new()
	era_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	era_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = FileAccess.get_file_as_string("res://shaders/era_grade.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = sh
	era_rect.material = mat
	era_rect.visible = false
	era_layer.add_child(era_rect)


## Tarihî dönem renk derecelendirmesi (boş kimlik = kapalı)
func _era_look(id: String) -> void:
	var lk: Dictionary = Eras.look(id)
	if lk.is_empty():
		era_rect.visible = false
		return
	var mat: ShaderMaterial = era_rect.material
	mat.set_shader_parameter("shadow", Vector3(lk["shadow"][0], lk["shadow"][1], lk["shadow"][2]))
	mat.set_shader_parameter("mid", Vector3(lk["mid"][0], lk["mid"][1], lk["mid"][2]))
	mat.set_shader_parameter("light", Vector3(lk["light"][0], lk["light"][1], lk["light"][2]))
	mat.set_shader_parameter("amount", float(lk["amount"]))
	mat.set_shader_parameter("vignette", float(lk["vignette"]))
	mat.set_shader_parameter("grain", float(lk["grain"]))
	era_rect.visible = true


func _new_world() -> void:
	_detach_gs()
	Eras.clear()
	_era_look("")
	var g = GS.new()
	g.new_world(world_rng.randi() % 1000000)
	_attach_gs(g)


func _attach_gs(g) -> void:
	gs = g
	ui.gs = gs
	map.bind(gs)
	gs.news_posted.connect(_on_news)
	gs.state_changed.connect(_on_state_changed)
	gs.peace_proposal.connect(_on_peace_proposal)
	gs.game_over.connect(_on_game_over)
	gs.ally_call.connect(_on_ally_call)
	gs.side_call.connect(_on_side_call)
	gs.un_vote_card.connect(_on_un_vote_card)
	gs.alliance_proposal.connect(_on_alliance_proposal)
	gs.indep_card.connect(_on_indep_card)
	gs.career_card.connect(_on_career_card)
	gs.moment_card.connect(_on_moment_card)
	gs.pol_card.connect(_on_pol_card)
	gs.wroom_card.connect(_on_wroom_card)
	selected_pid = -1
	selected_army = null
	ui.set_speed(0)
	speed_idx = 0
	menu.reset_world()


func _detach_gs() -> void:
	playing = false
	timer.stop()
	if gs != null:
		for pair in [[gs.news_posted, _on_news], [gs.state_changed, _on_state_changed], [gs.peace_proposal, _on_peace_proposal], [gs.game_over, _on_game_over], [gs.ally_call, _on_ally_call], [gs.un_vote_card, _on_un_vote_card], [gs.alliance_proposal, _on_alliance_proposal], [gs.indep_card, _on_indep_card], [gs.career_card, _on_career_card], [gs.moment_card, _on_moment_card], [gs.pol_card, _on_pol_card], [gs.wroom_card, _on_wroom_card]]:
			if pair[0].is_connected(pair[1]):
				pair[0].disconnect(pair[1])
	ui.hide_dialog()


func _on_splash_done() -> void:
	mode = "menu"
	menu.show_main()


func _start_demo() -> void:
	map.input_enabled = false
	map.set_highlight_country(-1)
	map.hud.show_armies = false
	map.hud.show_country_names = false           # ana menü arka planı: sabit harita, yazısız
	map.hud.show_province_names = false
	map.hud.queue_redraw()
	drift_timer.stop()
	map.ui_insets = Vector4(0, 0, 0, 0)
	map.animate_to(Vector2(520, -40), map.min_zoom * 2.1, 0.01)


func _drift_step() -> void:
	if mode != "menu" and mode != "splash":
		return
	var wr: Rect2 = map.world_rect()
	var spots := [Vector2(220, -150), Vector2(520, -40), Vector2(-560, -90), Vector2(300, 120), Vector2(-420, 190)]
	var p: Vector2 = spots[_drift_i % spots.size()]
	_drift_i += 1
	map.ui_insets = Vector4(0, 0, 0, 0)
	map.animate_to(p, map.min_zoom * 2.1, 13.0)


func _to_select() -> void:
	mode = "select"
	_apply_settings()
	drift_timer.stop()
	map.input_enabled = true
	_update_insets()
	menu.show_select(gs)
	map.animate_to(map.world_rect().get_center(), map.min_zoom * 1.25, 0.8)


func _start_era(id: String, scn: String = "") -> void:
	_detach_gs()
	Eras.prepare(id)
	var g = GS.new()
	g.new_world(world_rng.randi() % 1000000)
	Eras.restructure(g, id)
	_attach_gs(g)
	menu.set_era(id)
	if scn != "":
		menu.set_era_scn(scn)
	_era_look(id)
	map.repaint_all()
	_to_select()


func _back_to_menu() -> void:
	if Eras.current != "":
		_new_world()
		map.input_enabled = false
	mode = "menu"
	menu.show_main()
	_start_demo()


func _on_preview_country(cid: int) -> void:
	map.set_highlight_country(cid)
	map.focus_country(cid)


func _on_start_requested(cid: int) -> void:
	map.set_highlight_country(-1)
	ui.reset_news()
	gs.difficulty = Settings.difficulty
	AP.cur_key = Eras.current if Eras.current != "" else menu.scenario_id
	gs.start_game(cid)
	if Eras.current != "":
		Eras.start(gs, Eras.current)
		if menu.era_scn != "":
			Scenarios.apply(gs, menu.era_scn)     # dönemin üstüne kullanıcı senaryosu
	else:
		Scenarios.apply(gs, menu.scenario_id)
	if gs.scn_play >= 0:
		gs.switch_player(gs.scn_play)
		cid = gs.player
		gs.scn_play = -1
	map.repaint_all()
	mode = "game"
	playing = true
	menu.hide_all()
	ui.gs = gs
	ui.set_hud_visible(true)
	ui.refresh_top()
	_apply_settings()
	_update_insets()
	var cap: int = gs.countries[cid].capital
	map.focus_country(cid)
	if cap >= 0:
		selected_pid = cap
		map.select_province(cap)
		ui.show_province(cap, null)
	sfx.play("horn", 0.6)
	if not Settings.tut_done:
		Settings.seen_howto = true
		Settings.save_all()
		_start_tutorial()
	elif not Settings.seen_howto:
		Info.open_howto(ui.root)
	else:
		var nx: Dictionary = Goals.next_tutorial()
		if nx.is_empty():
			ui.toast("Başlamak için «Turu geç» düğmesine dokun.")
		else:
			ui.toast(Loc.t("Hedef: %s") % Loc.t(nx.name) + "\n" + Loc.t(nx.desc))
	EraMoments.resume(gs)


## Dil değişince arayüz yeniden kurulur: oyun varsa önce otomatik kayıt yuvasına yazılır, sonra sahne yeniden yüklenir.
func reload_for_language() -> void:
	if mode == "game" and gs != null and gs.game_started and gs.player >= 0 and gs.countries[gs.player].alive:
		Saves.write(gs, 0, Eras.current)
	get_tree().reload_current_scene()


func _go_main_menu() -> void:
	if mode == "game" and gs.game_started and gs.player >= 0 and gs.countries[gs.player].alive and Settings.autosave:
		Saves.write(gs, 0, Eras.current)
	_detach_gs()
	ui.set_hud_visible(false)
	ui.hide_info()
	_new_world()
	mode = "menu"
	_apply_settings()
	menu.show_main()
	_start_demo()


func _save_game(slot: int = 1) -> void:
	var ok: bool = Saves.write(gs, slot, Eras.current)
	ui.toast("Oyun kaydedildi: yuva %d." % slot if ok else "Kayıt başarısız.")
	_apply_settings()


## Ana menü "Devam Et": tek kayıt varsa doğrudan yükler, birden çoksa yuva listesini açar.
func _on_continue() -> void:
	var n := 0
	for sl in Saves.slot_count() + 1:
		if Saves.exists(sl):
			n += 1
	if n <= 1:
		_load_game(Saves.latest())
	else:
		SlotsUI.open(ui.root, "load", _load_game, ui._click)


func _load_game(slot: int = 0) -> void:
	var g = GS.new()
	if slot < 0 or not g.load_from(Saves.path(slot)):
		ui.toast("Kayıt bulunamadı ya da okunamadı.")
		sfx.play("error")
		return
	drift_timer.stop()
	_detach_gs()
	_attach_gs(g)
	mode = "game"
	playing = true
	map.input_enabled = true
	menu.hide_all()
	ui.set_hud_visible(true)
	ui.refresh_top()
	_apply_settings()
	_update_insets()
	if gs.player >= 0:
		map.focus_country(gs.player)
	_era_look(Eras.current)
	AP.cur_key = Eras.current if Eras.current != "" else String(gs.scn.get("id", "")) if not gs.scn.is_empty() and String(gs.scn.get("id", "")) != "" else "free"
	if Daily.active(gs):
		AP.cur_key = "daily"
	ui.toast("Oyun yüklendi: %s" % Names.date_string(gs.turn))
	Independence.resume(gs)
	Career.resume(gs)
	EraMoments.resume(gs)


# ------------------------------------------------------------------ zaman

func _on_speed_changed(_idx: int) -> void:
	# Gerçek zamanlı akış yok: oyun tur tabanlı ("Turu geç").
	speed_idx = 0
	timer.stop()


## Turu Geç: yükleniyor ekranı -> tur hesabı -> Cihan Bülteni (haber ve harp raporu).
func _on_step() -> void:
	if turn_busy or not playing or mode != "game" or ui.is_dialog_open():
		return
	turn_busy = true
	sfx.play("stamp", 0.8)
	var before: Dictionary = TurnUI.snapshot(gs)
	var ov = TurnUI.loading(ui.root, gs.turn + 1)
	ov.set_step(0.18, TurnUI.TIPS[0])
	await get_tree().create_timer(0.35).timeout
	ov.set_step(0.5, TurnUI.TIPS[1])
	_do_turn()
	await get_tree().create_timer(0.4).timeout
	ov.set_step(0.8, TurnUI.TIPS[2])
	await get_tree().create_timer(0.3).timeout
	ov.set_step(1.0, TurnUI.TIPS[4])
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(ov):
		ov.queue_free()
	# savaş/barış teklifi gibi pencereler açıldıysa önce onlar kapansın
	while mode == "game" and ui.is_dialog_open():
		await get_tree().create_timer(0.2).timeout
	if mode == "game" and playing and gs != null:
		var rep = TurnUI.build_report(ui, gs, before, func(pid: int):
			map.focus_province(pid, FOCUS_ZOOM)
			_select(pid))
		ui.set_modal(rep)
		sfx.play("news", 0.9)
		await rep.closed
		await _cabinet_turn()
	turn_busy = false


## Bülten kapandıktan sonra, ayar açıksa ve sıra gelmişse bir kabine kartı göster.
func _cabinet_turn() -> void:
	if mode != "game" or not playing or gs == null or gs.player < 0:
		return
	if not gs.countries[gs.player].alive:
		return
	if Career.active(gs) and Career.state(gs) in ["vassal", "rebel"]:
		return          # hikâye modunda komutansın: kabine, kriz ve seçim toplantıları yok; olayları Divan kartları getirir
	# 0) dünya krizi kartı (kabine ayarından bağımsız: kısa bir karar)
	if not gs.crisis_pending.is_empty():
		var ccard: Dictionary = gs.crisis_pending
		gs.crisis_pending = {}
		await _show_card(ccard)
		if not playing:
			return
	# 0b) senaryo düzenleyicisinde yazılmış kabine olayı (ayardan bağımsız: hikâyenin parçası)
	var scn_card: Dictionary = Cabinet.scn_card(gs)
	if not scn_card.is_empty():
		await _show_card(scn_card)
		if not playing:
			return
	# 1) takvimli olay: seçim
	if Settings.cabinet:
		var sched: Dictionary = Cabinet.scheduled(gs)
		if not sched.is_empty():
			await _show_card(sched)
			if not playing:
				return
	# 2) boşalan bakanlıklar: 3 aday
	for role in Cabinet.vacancies(gs):
		if not Settings.cabinet:
			Cabinet.appoint(gs, role, Cabinet.candidates(gs, role)[1])     # kabine kapalıysa orta aday otomatik
			continue
		var sh = AppointUI.open(ui, gs, role)
		ui.set_modal(sh)
		sfx.play("paper", 0.8)
		await sh.closed
		ui.refresh_top()
		if mode != "game" or not playing:
			return
	if not Settings.cabinet:
		return
	# 3) rastgele kabine kartı
	var card: Dictionary = Cabinet.pick(gs, _cab_last, _cab_recent, _cab_rng)
	if card.is_empty():
		return
	_cab_last = gs.turn
	_cab_recent.append(card.id)
	if _cab_recent.size() > 10:
		_cab_recent.pop_front()
	await _show_card(card)


func _show_card(card: Dictionary) -> void:
	var fatal_text := ""
	var sh = CabinetUI.open(ui, gs, card, _cab_rng, func(t: String): fatal_text = t)
	ui.set_modal(sh)
	sfx.play("paper", 0.8)
	await sh.closed
	ui.refresh_top()
	if fatal_text != "":
		gs.game_over.emit(false, fatal_text)


func _on_tick() -> void:
	if ui.is_dialog_open():
		return
	_do_turn()


func _audio_context() -> Dictionary:
	var war := false
	if mode == "game" and gs != null and gs.player >= 0 and gs.player < gs.countries.size():
		war = gs.countries[gs.player].enemies.size() > 0
	return {"mode": mode, "era": Eras.current, "war": war}


func _do_turn() -> void:
	gs.auto_idle = Settings.auto_orders
	gs.end_turn()
	if gs.last_auto > 0 and not gs.countries[gs.player].auto_cmd:
		ui.toast("Emir vermedin: %d boşta ordu otomatik görevlendirildi." % gs.last_auto)
	sfx.turn_tick(speed_idx)
	if Settings.autosave and gs.turn % 13 == 0 and gs.countries[gs.player].alive:
		Saves.write(gs, 0, Eras.current)
	if selected_army != null and gs.armies.get(selected_army.prov) != selected_army:
		selected_army = null
		map.set_selected_army(null)
	_refresh_selection()


func _on_state_changed() -> void:
	if mode == "game":
		ui.refresh_top()
		_check_goals()


## Başarım/öğretici adımı açılınca bildirir; sıradaki öğretici adımı hatırlatır.
var _mis_gs = null
var _mis_snap: Dictionary = {}


## Günlük/haftalık görev ilerlemesi: oyun istatistiklerindeki artışları görevlere işler. Dönüş: bildirim metni.
func _track_missions() -> String:
	if gs == null or gs.player < 0:
		return ""
	var cur := {"turns": gs.turn, "captures": gs.stats.p_captures, "battles": gs.stats.p_battles, "orders": gs.stats.orders, "peace": gs.stats.p_peaces,
		"alliance": gs.stats.p_alliances, "un": gs.stats.un_passed, "landing": gs.stats.landings, "strike": int(gs.stats.get("strikes", 0)), "war": gs.stats.p_wars}
	if _mis_gs != gs:
		_mis_gs = gs
		_mis_snap = cur.duplicate()
		return ""
	var msg := ""
	for k in cur:
		var dlt: int = int(cur[k]) - int(_mis_snap.get(k, cur[k]))
		_mis_snap[k] = cur[k]
		if dlt <= 0 or dlt > 500:
			continue
		var r: Dictionary = Missions.add(k, dlt)
		for t in r.done:
			msg += ("\n" if msg != "" else "") + Loc.t("Görev tamam: %s (+%d puan)") % [Loc.t(t.t), int(t.xp)]
		if int(r.ap) > 0:
			msg += ("\n" if msg != "" else "") + Loc.t("AOD Puanı: +%d AP") % int(r.ap)
		if r.promoted != "":
			msg += ("\n" if msg != "" else "") + Loc.t("Terfi: %s!") % Loc.t(r.promoted)
	return msg


func _check_goals() -> void:
	var fresh: Array = Goals.check(gs)
	var msg := _track_missions()
	if fresh.is_empty():
		if msg != "":
			ui.toast(msg)
			sfx.play("click", 1.0)
		return
	var gap := 0
	for d in fresh:
		gap += AP.goal_reward(String(d.kind))
		msg += ("\n" if msg != "" else "") + ((Loc.t("Başarım: %s") % Loc.t(d.name)) if d.kind == "ach" else (Loc.t("Hedef tamamlandı: %s") % Loc.t(d.name)))
	if gap > 0:
		msg += "\n" + Loc.t("AOD Puanı: +%d AP") % gap
	var nxt: Dictionary = Goals.next_tutorial()
	if not nxt.is_empty():
		msg += "\n" + Loc.t("Sıradaki hedef: %s") % Loc.t(nxt.name)
	ui.toast(msg)
	sfx.play("click", 1.0)


func _refresh_selection() -> void:
	if selected_pid >= 0 and mode == "game":
		ui.show_province(selected_pid, selected_army)
	map.hud.queue_redraw()


func _on_news(text: String, prov: int, kind: String) -> void:
	if mode != "game":
		return
	ui.show_news(text, prov, kind)
	sfx.news_kind(kind)


# ------------------------------------------------------------------ seçim ve emirler

func _on_choke_tapped(id: String) -> void:
	if mode != "game" or ui.is_dialog_open():
		return
	sfx.play("tap")
	ui.show_chokes(id)


## Senaryo editöründen "Haritadan il seç": editör pencereleri gizlenir, dokunulan iller toplanır, "Bitti" ile geri dönülür.
var _pick_cb := Callable()
var _pick_ids: Array = []
var _pick_bar: Control
var _pick_lbl: Label
var _pick_hidden: Array = []


## Düzenleyici için geçici dünya: çağ (ve istenirse senaryo düzenlemeleri) uygulanmış halde haritaya bağlanır
var _scn_view_gs = null
var _prev_bar: Control = null
var _prev_cb := Callable()
var _prev_menu_vis := false


func _scn_world_bind(era: String, sc: Dictionary) -> bool:
	if era == "" and sc.is_empty():
		return false
	var prev: String = Eras.current
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(7)
	if era != "":
		Eras.restructure(g, era)
	if not sc.is_empty():
		Scenarios.apply_dict(g, sc, false)
	if prev != "":
		Eras.prepare(prev)
	else:
		Eras.clear()
	_scn_view_gs = g
	map.bind(g)
	_era_look(era)
	map.repaint_all()
	return true


func _scn_world_unbind() -> void:
	if _scn_view_gs == null:
		return
	_scn_view_gs = null
	map.bind(gs)
	_era_look(Eras.current)
	map.repaint_all()


func _hide_editor_sheets() -> Array:
	var hid: Array = []
	for c in menu.root.get_children():
		if c is Control and c.visible and c.has_method("close"):
			c.visible = false
			hid.append(c)
	return hid


## Başlangıç haritası önizlemesi: dönem + yapılan devirler/yeni devletler uygulanmış harita
func _begin_map_preview(sc: Dictionary, cb: Callable) -> void:
	_prev_cb = cb
	_pick_hidden = _hide_editor_sheets()
	_prev_menu_vis = menu.main_panel.visible
	menu.main_panel.visible = false
	_scn_world_bind(String(sc.get("era", "")), sc)
	_prev_bar = PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.add_child(TK.t(Loc.t("Önizleme: başlangıç haritası (sonradan olacak devirler hariç)"), "body", TK.GOLD))
	var back := TK.button("Düzenlemeye dön", "gold", "check", Vector2(230, 56), 18)
	back.pressed.connect(_end_map_preview)
	hb.add_child(back)
	_prev_bar.add_child(hb)
	menu.root.add_child(_prev_bar)
	_prev_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_prev_bar.position.y = 16
	map.input_enabled = true
	map.select_province(-1)
	var tr_list: Array = sc.get("transfer", [])
	if not tr_list.is_empty():
		map.focus_province(int(tr_list[0][0]), map.min_zoom * 3.0)     # ilk devrin olduğu bölgeye yakınlaş
	else:
		map.animate_to(map.world_rect().get_center(), map.min_zoom * 1.25, 0.6)


func _end_map_preview() -> void:
	var cb := _prev_cb
	_prev_cb = Callable()
	if _prev_bar != null:
		_prev_bar.queue_free()
		_prev_bar = null
	_scn_world_unbind()
	menu.main_panel.visible = _prev_menu_vis
	for c in _pick_hidden:
		if is_instance_valid(c):
			c.visible = true
	_pick_hidden = []
	if cb.is_valid():
		cb.call()


func _begin_map_pick(cb: Callable) -> void:
	_pick_cb = cb
	_pick_ids = []
	_pick_hidden = _hide_editor_sheets()
	if UserScn.era != "":
		_scn_world_bind(UserScn.era, {})
	_pick_bar = PanelContainer.new()
	_pick_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_pick_bar.position.y = 16
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	_pick_lbl = TK.t("", "body", TK.GOLD)
	hb.add_child(_pick_lbl)
	var done := TK.button("Bitti", "gold", "check", Vector2(150, 56), 18)
	done.pressed.connect(_end_map_pick)
	hb.add_child(done)
	_pick_bar.add_child(hb)
	menu.root.add_child(_pick_bar)
	_pick_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_pick_bar.position.y = 16
	_pick_refresh()
	map.input_enabled = true
	map.animate_to(map.world_rect().get_center(), map.min_zoom * 1.25, 0.6)


func _pick_refresh() -> void:
	_pick_lbl.text = "%s: %d %s" % [Loc.t("Haritadan il seç — dokunarak ekle/çıkar"), _pick_ids.size(), Loc.t("il")]


func _end_map_pick() -> void:
	var cb := _pick_cb
	var got := _pick_ids.duplicate()
	_pick_cb = Callable()
	if _pick_bar != null:
		_pick_bar.queue_free()
		_pick_bar = null
	map.select_province(-1)
	_scn_world_unbind()
	for c in _pick_hidden:
		if is_instance_valid(c):
			c.visible = true
	_pick_hidden = []
	if cb.is_valid():
		cb.call(got)


func _on_map_tapped(pid: int) -> void:
	if _prev_bar != null:
		return
	if _pick_cb.is_valid():
		if pid >= 0:
			if _pick_ids.has(pid):
				_pick_ids.erase(pid)
			else:
				_pick_ids.append(pid)
			map.select_province(pid)
			_pick_refresh()
		return
	if mode == "select":
		if pid >= 0:
			sfx.play("tap")
			menu.select_country(gs.provinces[pid].owner)
		return
	if mode != "game" or ui.is_dialog_open():
		return
	if pid < 0:
		selected_pid = -1
		selected_army = null
		map.select_province(-1)
		map.set_selected_army(null)
		ui.hide_info()
		return
	sfx.play("tap")
	# Eyalete dokunmak yalnızca eyaleti seçer. Ordu, kartındaki "Ordu seç" düğmesiyle seçilir;
	# seçiliyken başka eyalete dokununca hedef kartı açılır ve "Ordu buraya yürüsün" ile emir verilir.
	_select(pid)


func _select(pid: int) -> void:
	selected_pid = pid
	map.select_province(pid)
	ui.show_province(pid, selected_army)


func _on_ui_action(act: String, arg) -> void:
	match act:
		"focus":
			map.focus_province(arg, FOCUS_ZOOM)
			_select(arg)
		"focus_city":
			map.focus_province(arg, 28.0)
		"capital":
			var cap: int = gs.countries[gs.player].capital
			if cap >= 0:
				map.focus_province(cap, FOCUS_ZOOM)
				_select(cap)
		"fit":
			map.animate_to(map.world_rect().get_center(), map.min_zoom * 1.05, 0.7)
		"close_card":
			selected_pid = -1
			selected_army = null
			map.select_province(-1)
			map.set_selected_army(null)
			ui.hide_info()
		"select_army":
			var a = gs.armies.get(arg)
			if a != null and a.owner == gs.player:
				selected_army = a
				map.set_selected_army(a)
				ui.show_province(arg, a)
				ui.toast("Ordu seçildi. Gidilecek eyalete dokun.")
		"assault":
			AssaultUI.open(ui, gs, arg, func(res: Dictionary):
				if res.err != "":
					ui.toast(res.err)
					sfx.play("error")
				else:
					ui.toast("%d ordu yola çıktı (varış: %d hf). Sonuç raporda." % [res.n, res.eta])
					sfx.play("order")
					sfx.play("drumroll", 0.7)
				_refresh_selection())
		"carrier":
			var cp: int = int(arg)
			ui.show_dialog("Uçak gemisi saldırısı", "%s eyaletine uçak gemisi grubundan hava taarruzu düzenlenecek. Hedefteki ordu ağır kayıp verir; grup %d hafta yeniden hazırlanır." % [gs.provinces[cp].name, Carriers.STRIKE_CD], [
				{"text": "Vazgeç", "cb": func(): pass, "kind": "ghost"},
				{"text": "Saldır", "kind": "danger", "icon": Icons.pick("carrier_strike", "ship"), "cb": func():
					var cr: Dictionary = Carriers.strike(gs, cp)
					if cr.err != "":
						ui.toast(cr.err)
						sfx.play("error")
						return
					sfx.play("drumroll", 0.9)
					_refresh_selection()
					var body: String = "Hedef: %s.\n%s" % [gs.provinces[cp].name, ("Düşman %s asker kaybetti." % Macro.num(cr.killed)) if cr.killed > 0 else "Hedefte ordu yoktu; sahil tesisleri vuruldu."]
					ui.show_dialog("Harekât tamamlandı", body, [{"text": "Tamam", "cb": func(): pass, "kind": "good"}], "carrier", "")}], "carrier", "")
		"gas":
			var gp: int = int(arg)
			ui.show_dialog("Kimyasal saldırı", "%s eyaletinde zehirli gaz kullanılacak. Hedef ordusunun yaklaşık %%45'i kaybolur, ama istikrarın düşer ve dünya tepkisi artar. 8 hafta tekrar kullanılamaz." % gs.provinces[gp].name, [
				{"text": "Vazgeç", "cb": func(): pass, "kind": "ghost"},
				{"text": "Saldır", "kind": "danger", "cb": func():
					var eg: String = gs.player_gas(gp)
					if eg != "":
						ui.toast(eg)
					else:
						sfx.play("drumroll", 0.9)
						_refresh_selection()}])
		"nuke":
			var np: int = int(arg)
			var plats: Array = gs.nuke_platforms(np)
			var nb: Array = [{"text": "Vazgeç", "cb": func(): pass, "kind": "ghost"}]
			var fire := func(pl: String):
				var er: String = gs.player_nuke(np, pl)
				if er != "":
					ui.toast(er)
				else:
					sfx.play("drumroll", 0.9)
				_refresh_selection()
			var pname := {"silo": "Füze silosu", "bomber": "Bombardıman", "sub": "Denizaltı"}
			for pl in plats:
				var pls: String = pl
				nb.append({"text": pname[pls], "icon": "nk_" + pls, "kind": "danger", "cb": func(): fire.call(pls)})
			ui.show_dialog("Nükleer saldırı", "%s eyaletine nükleer silah kullanılacak.\n\nFüze silosu: %%80 kayıp, kesin isabet.\nBombardıman: %%65 kayıp, hedefin hava gücü uçağı düşürebilir, bekleme kısa.\nDenizaltı: kıyı eyaleti, %%70 kayıp, gizli: yaptırım ve müttefik tepkisi daha az.\n\nİstikrarın düşer, 26 hafta yaptırım gelir ve hedefin müttefikleri sana savaş açabilir." % gs.provinces[np].name, nb)
		"move_army":
			if selected_army != null and selected_army.owner == gs.player:
				var arm = selected_army
				var dest: int = arg
				var go := func(count: int):
					var sent: int = count if count > 0 and count < arm.size else arm.size
					var err2: String = gs.player_order_move(arm, dest, count)
					if err2 != "":
						ui.toast(err2)
						sfx.play("error")
					else:
						ui.toast("%s asker yola çıktı: %s" % [Macro.num(sent), gs.provinces[dest].name])
						sfx.play("order")
					if err2 == "" and count > 0 and count < arm.size and gs.split_pending(arm) < arm.size - 1:
						_refresh_selection()     # ordu seçili kalır: başka bir hedefe dokunarak kalanı da bölebilirsin
						return
					selected_army = null
					map.set_selected_army(null)
					_select(dest)
				if arm.size >= 200:
					SendUI.open(ui, gs, arm, dest, go)
				else:
					go.call(0)
		"deselect":
			selected_army = null
			map.set_selected_army(null)
			ui.show_province(arg, null)
		"stop":
			if selected_army != null:
				gs.player_cancel_move(selected_army)
				ui.show_province(arg, selected_army)
		"war":
			var err: String = gs.player_declare_war(arg)
			if err != "":
				ui.toast(err)
				sfx.play("error")
			_refresh_selection()
		"peace":
			_player_peace(arg)
		"alliance":
			var e: String = gs.player_propose_alliance(arg)
			ui.toast(e if e != "" else "İttifak kuruldu!")
			if e == "":
				sfx.play("peace", 0.7)
			_refresh_selection()
		"ask_passage":
			var pe: String = gs.player_request_passage(arg)
			ui.toast(pe if pe != "" else "Geçiş izni verildi (39 hafta).")
			sfx.play("peace" if pe == "" else "error", 0.7)
			_refresh_selection()
		"ask_aid":
			var r: Dictionary = gs.player_request_aid(arg)
			ui.toast(r.text)
			sfx.play("peace" if r.ok else "error", 0.7)
			_refresh_selection()
		"ask_aid_all":
			var ra: Dictionary = gs.player_request_aid_all()
			ui.toast(ra.text)
			sfx.play("peace" if ra.ok else "error", 0.7)
			_refresh_selection()
		"aid_join":
			var foes: Array = gs.aid_join_foes(arg)
			if foes.is_empty():
				ui.toast("Katılabileceğin bir savaş yok.")
			else:
				var fn: String = gs.countries[foes[0]].name
				var an: String = gs.countries[arg].name
				ui.show_dialog("Müttefike yardım", "%s, %s ile savaşıyor. Yanında yer alıp %s devletine savaş açmak ister misin?" % [an, fn, fn], [
					{"text": "Savaş aç", "cb": func():
						var er: String = gs.player_aid_join(arg)
						if er != "":
							ui.toast(er)
						_refresh_selection(), "kind": "danger"},
					{"text": "Vazgeç", "cb": func(): pass},
				])
		"aid_gold":
			var cost: float = gs.aid_gold_cost()
			ui.show_dialog("Mali yardım", "%s altını %s devletine göndermek ister misin? (Müttefikin %s alır, istikrarı artar, sana minnet duyar.)" % [Macro.money(cost), gs.countries[arg].name, Macro.money(cost * 0.8)], [
				{"text": "Gönder", "cb": func():
					var eg: String = gs.player_aid_gold(arg)
					ui.toast(eg if eg != "" else "Yardım gönderildi.")
					_refresh_selection(), "kind": "good"},
				{"text": "Vazgeç", "cb": func(): pass},
			])
		"break_alliance":
			var e2: String = gs.player_break_alliance(arg)
			if e2 != "":
				ui.toast(e2)
			_refresh_selection()
		"rel_view":
			var tgt: int = int(arg)
			if tgt < 0 or map.rel_country == tgt:
				map.set_relation_view(-1)
				ui.toast("İlişki görünümü kapalı.")
			else:
				map.set_relation_view(tgt)
				ui.toast("İlişki görünümü: sarı seçili ülke, mavi müttefik, kırmızı savaş, mor ateşkes.")
		"relations":
			ui.show_relations(int(arg))
		"diplomacy":
			ui.DiplomacyUI.open(ui, gs, int(arg))
		"annex_vassal":
			var vc = gs.countries[arg]
			var left: int = int(gs.vassals[arg].since) + gs.VASSAL_ANNEX_MIN - gs.turn
			ui.show_dialog("Vasalı ilhak et", "%s tüm eyaletleriyle sana katılsın mı? Bedel: %s. Vasal ilişkisi sona erer, yeni topraklarda bir süre huzursuzluk olabilir.%s" % [vc.name, Macro.money(gs.vassal_annex_cost(arg)), ("\n(Henüz %d hafta bekle.)" % left) if left > 0 else ""], [
				{"text": "İlhak et", "cb": func():
					var ea: String = gs.player_annex_vassal(arg)
					ui.toast(ea if ea != "" else "%s ilhak edildi." % vc.name)
					_refresh_selection(), "kind": "danger"},
				{"text": "Vazgeç", "cb": func(): pass},
			])
		"release_vassal":
			var vr = gs.countries[arg]
			ui.show_dialog("Vasalı serbest bırak", "%s bağımsız olsun mu? Sana minnet duyar, ama haraç ödemeyi bırakır." % vr.name, [
				{"text": "Serbest bırak", "cb": func():
					gs.player_release_vassal(arg)
					_refresh_selection(), "kind": ""},
				{"text": "Vazgeç", "cb": func(): pass},
			])
		"assimilate":
			var ac: float = gs.assimilate_cost(arg)
			ui.show_dialog("Asimile et: %s" % gs.provinces[arg].name, "Fethedilen halkı kendi kimliğine katmak %s tutar. Eyalet öz toprağın olur, huzursuzluk biter; istikrar hafifçe düşer. Barışta da yapılabilir." % Macro.money(ac), [
				{"text": "Asimile et (%s)" % Macro.money(ac), "cb": func():
					var ea: String = gs.player_assimilate(arg)
					ui.toast(ea if ea != "" else "Halk asimile edildi.")
					_refresh_selection(), "kind": "gold" if gs.countries[gs.player].gold >= ac else ""},
				{"text": "Vazgeç", "cb": func(): pass},
			])
		"convert_faith":
			var fc: float = gs.faith_convert_cost(arg)
			ui.show_dialog("İnancı yay: %s" % gs.provinces[arg].name, "Halkı devlet inancına döndürmek %s tutar. İstikrar hafifçe düşer, eyalette kısa süreli huzursuzluk olur. Barışta da yapılabilir." % Macro.money(fc), [
				{"text": "Döndür (%s)" % Macro.money(fc), "cb": func():
					var ef: String = gs.player_convert_faith(arg)
					ui.toast(ef if ef != "" else "Halk devlet inancına döndürüldü.")
					_refresh_selection(), "kind": "gold" if gs.countries[gs.player].gold >= fc else ""},
				{"text": "Vazgeç", "cb": func(): pass},
			])
		"bulk":
			_open_bulk_dialog()
		"form_view":
			if String(arg) == "" or String(arg) == "off":
				map.set_form_view({})
				ui.form_view_on = false
				ui.toast("Form görünümü kapatıldı.")
			else:
				for fd in Formables.all():
					if fd.id == String(arg):
						var tp: Dictionary = Formables.target_provinces(gs, fd)
						map.set_form_view(tp)
						ui.form_view_on = true
						var need := 0
						for q in tp:
							if gs.provinces[q].owner != gs.player:
								need += 1
						ui.toast("%s: yeşil sende, turuncu alınacak yerler (%d eyalet). Kapatmak için eyalet kartındaki düğmeyi kullan." % [fd.name, need])
				_refresh_selection()
		"build":
			var bp = gs.provinces[arg]
			var opts: Array = []
			for k in ["farm", "mine", "oil", "press"]:
				var bk: String = k
				var bc: float = bp.bld_cost(bk)
				opts.append({"text": "%s — %s (%s)" % [Model.bld_name(bk, Macro.era_on and Eras.family() == "pre"), Macro.money(bc), Model.BLD[bk].info], "cb": func():
					var eb: String = gs.player_build(arg, bk)
					ui.toast(eb if eb != "" else "%s inşaatı başladı (%d hafta)." % [Model.bld_name(bk, Macro.era_on and Eras.family() == "pre"), Model.BLD_WEEKS])
					_refresh_selection(), "kind": "gold" if gs.countries[gs.player].gold >= bc else ""})
			opts.append({"text": "Vazgeç", "cb": func(): pass})
			ui.show_dialog("Bina kur: %s" % bp.name, "Bu eyalette haftalık vergi gelirini artıran bir bina kur. İnşaat %d hafta sürer; eyalet fetihle el değiştirirse bina yeni sahibe geçer." % Model.BLD_WEEKS, opts)
		"form":
			ui.FormationUI.open(ui, gs)
		"focus_country":
			var c = gs.countries[arg]
			map.focus_country(arg)
			var target: int = c.capital
			if target < 0:
				for p in gs.provinces:
					if p.controller == arg:
						target = p.id
						break
			if target >= 0:
				_select(target)


## Toplu işlemler: tüm eyaletlere bina / asimile / din dönüştürme (kasa yettiği kadar, kârlı eyaletten başlayarak).
func _open_bulk_dialog() -> void:
	var pre: bool = Macro.era_on and Eras.family() == "pre"
	var opts: Array = []
	for k in ["farm", "mine", "oil", "press"]:
		var bk: String = k
		var pv: Dictionary = gs.bulk_preview("build", bk)
		if pv.n > 0:
			var btxt: String = ("Tüm eyaletlere %s: %d yer, %s" % [Model.bld_name(bk, pre), pv.n, Macro.money(pv.cost)]) if pv.afford >= pv.n else ("Tüm eyaletlere %s: %d/%d yer (kasa yettiği kadar), %s" % [Model.bld_name(bk, pre), pv.afford, pv.n, Macro.money(pv.cost)])
			opts.append({"text": btxt, "cb": func():
				var d: int = gs.player_bulk("build", bk)
				ui.toast("%d eyalette %s inşaatı başladı." % [d, Model.bld_name(bk, pre)] if d > 0 else "Kasa yetmiyor.")
				_refresh_selection(), "kind": "gold" if pv.afford > 0 else ""})
	var pa: Dictionary = gs.bulk_preview("assimilate")
	if pa.n > 0:
		opts.append({"text": "Hepsini asimile et: %d eyalet, %s" % [pa.n, Macro.money(pa.cost)], "cb": func():
			var d2: int = gs.player_bulk("assimilate")
			ui.toast("%d eyalet asimile edildi." % d2 if d2 > 0 else "Kasa yetmiyor.")
			_refresh_selection(), "kind": "gold" if pa.afford > 0 else ""})
	var pf: Dictionary = gs.bulk_preview("faith")
	if pf.n > 0:
		opts.append({"text": "Hepsinin inancını değiştir: %d eyalet, %s" % [pf.n, Macro.money(pf.cost)], "cb": func():
			var d3: int = gs.player_bulk("faith")
			ui.toast("%d eyaletin inancı değişti." % d3 if d3 > 0 else "Kasa yetmiyor.")
			_refresh_selection(), "kind": "gold" if pf.afford > 0 else ""})
	if opts.is_empty():
		ui.toast("Toplu yapılacak bir işlem yok.")
		return
	opts.append({"text": "Vazgeç", "cb": func(): pass})
	ui.show_dialog("Toplu işlemler", "Kasa yettiği kadar, geliri en yüksek eyaletten başlayarak uygulanır. Yalnızca kendi kontrolündeki eyaletler etkilenir.", opts)


func _toast_result(err: String, ok_text: String) -> void:
	ui.toast(err if err != "" else ok_text)
	if err != "":
		sfx.play("error")
	else:
		sfx.play("coin")


# ------------------------------------------------------------------ barış

func _player_peace(enemy: int) -> void:
	var res: Dictionary = gs.player_request_peace(enemy)
	if not res.ok:
		ui.toast(res.text)
		return
	if res.mode == "player_wins":
		_open_deal(res.war, true)
	else:
		ui.toast(res.text)
		_refresh_selection()


func _open_deal(w, _from_player_request: bool) -> void:
	_on_speed_changed(0)
	var options: Array = gs.peace_options(w, gs.player, true)
	if options.is_empty():
		ui.show_dialog("Barış", "İşgal ettiğin eyalet yok; beraberlik barışı yapılacak.", [
			{"text": "Beraberlik barışı", "cb": func(): gs.finish_peace(w, -1, []), "kind": "good"},
			{"text": "Vazgeç", "cb": func(): gs.cancel_proposal()},
		])
		return
	ui.show_deal_dialog(w, gs.player, options,
		func(picked, terms): gs.finish_peace(w, gs.player, picked, terms),
		func(): gs.finish_peace(w, -1, []))


func _on_peace_proposal(w, from_country: int, kind: String) -> void:
	_on_speed_changed(0)
	var cname: String = gs.countries[from_country].name
	match kind:
		"loser_asks":
			ui.show_dialog("Barış teklifi", "%s barış istiyor. Savaş puanların: sen %d, onlar %d.\nMasaya oturup eyalet alabilirsin." % [cname, w.score_of(gs.player), w.score_of(from_country)], [
				{"text": "Masaya otur", "cb": func(): _open_deal(w, false), "kind": "good"},
				{"text": "Reddet", "cb": func(): gs.cancel_proposal(), "kind": "danger"},
			])
		"winner_demands":
			var annex: Array = gs._ai_choose_annex(w, from_country)
			var names: Array = []
			for pid in annex:
				names.append(gs.provinces[pid].name)
			if annex.is_empty():
				gs.cancel_proposal()
				return
			ui.show_dialog("Barış şartları", "%s barış için şunları talep ediyor: %s.\nReddedersen savaş sürer." % [cname, ", ".join(names)], [
				{"text": "Kabul et", "cb": func(): gs.finish_peace(w, from_country, annex), "kind": "good"},
				{"text": "Reddet", "cb": func(): gs.cancel_proposal(), "kind": "danger"},
			])
		_:
			ui.show_dialog("Beraberlik teklifi", "%s beraberlik barışı öneriyor. İşgal edilen yerler geri verilir." % cname, [
				{"text": "Kabul et", "cb": func(): gs.finish_peace(w, -1, []), "kind": "good"},
				{"text": "Reddet", "cb": func(): gs.cancel_proposal(), "kind": "danger"},
			])


## Bağımsızlık Yolu karar kartı
func _on_wroom_card(title: String, body: String, scene: String) -> void:
	_on_speed_changed(0)
	ui.show_dialog(title, body, [{"text": "Tamam", "cb": func(): pass, "kind": "good"}], scene)


func _on_pol_card() -> void:
	var pend: Dictionary = gs.pol.get("pending", {})
	if pend.is_empty():
		return
	_on_speed_changed(0)
	var btns: Array = []
	var ch: Array = pend.get("choices", [])
	for i in ch.size():
		var idx: int = i
		btns.append({"text": String(ch[i].get("t", "?")), "cb": func():
			var res: String = Politics.choose(gs, idx)
			if res != "":
				ui.toast(res)
			ui.refresh_top(), "kind": "good" if i == 0 else ""})
	ui.show_dialog(String(pend.get("title", "")), String(pend.get("body", "")), btns, "", String(pend.get("icon", "")))


func _on_indep_card() -> void:
	var pend: Dictionary = gs.indep.get("pending", {})
	if pend.is_empty():
		return
	_on_speed_changed(0)
	var btns: Array = []
	var ch: Array = pend.get("choices", [])
	for i in ch.size():
		var idx: int = i
		btns.append({"text": String(ch[i].get("t", "?")), "cb": func():
			Independence.choose(gs, idx)
			ui.refresh_top(), "kind": "good" if i == 0 else ""})
	ui.show_dialog(String(pend.get("title", "")), String(pend.get("body", "")), btns, "", String(pend.get("icon", "")))


# ------------------------------------------------------------------ Hikâye Modu (kariyer)

## Çağ seçildi: o çağın dünyası kurulur (oyun başlamadan), sonra hükümdar/tımar/karakter seçimi
func _career_pick_era(era_id: String) -> void:
	_detach_gs()
	var g = GS.new()
	if era_id != "":
		Eras.prepare(era_id)
		g.new_world(world_rng.randi() % 1000000)
		Eras.restructure(g, era_id)
	else:
		Eras.prepare("")
		g.new_world(world_rng.randi() % 1000000)
	_attach_gs(g)
	_era_look(era_id)
	CareerUI.open_setup(menu.root if "root" in menu else self, gs, era_id, func(p: Dictionary): _start_career(era_id, p), func(): pass)


func _start_career(era_id: String, params: Dictionary) -> void:
	map.set_highlight_country(-1)
	ui.reset_news()
	var host: int = int(gs.macro_idx.get(String(params.get("host_en", "")), -1))
	if host < 0:
		ui.toast("Hükümdar bulunamadı.")
		return
	gs.difficulty = Settings.difficulty
	gs.start_game(host)
	if era_id != "":
		Eras.start(gs, era_id)
		menu.set_era(era_id)
	if not Career.begin(gs, params):
		ui.toast("Tımar kurulamadı; başka bir hükümdar dene.")
		return
	AP.cur_key = "career"
	map.repaint_all()
	mode = "game"
	playing = true
	map.input_enabled = true
	menu.hide_all()
	ui.gs = gs
	ui.set_hud_visible(true)
	ui.refresh_top()
	_apply_settings()
	_update_insets()
	var cap: int = gs.countries[gs.player].capital
	map.focus_country(gs.player)
	if cap >= 0:
		selected_pid = cap
		map.select_province(cap)
		ui.show_province(cap, null)
	sfx.play("horn", 0.6)
	# açılış hikâyesi
	var hc = gs.countries[host]
	gs.career["pending"] = {"kind": "chapter", "idx": 0}
	_on_career_card()


func _on_moment_card() -> void:
	if gs == null or gs.moment_pending.is_empty():
		return
	var c: Dictionary = EraMoments.card(gs)
	if c.is_empty():
		return
	_on_speed_changed(0)
	var btns: Array = []
	if (c.options as Array).is_empty():
		btns.append({"text": "Tamam", "cb": func(): gs.moment_pending = {}, "kind": "good"})
	else:
		for i in c.options.size():
			var idx: int = i
			var o: Dictionary = c.options[i]
			btns.append({"text": String(o.t), "cb": func():
				EraMoments.choose(gs, idx)
				ui.refresh_top(), "kind": String(o.get("kind", "good" if i == 0 else ""))})
	var body: String = String(c.body)
	if not (c.options as Array).is_empty():
		var ds: Array = []
		for o2 in c.options:
			if String(o2.d) != "":
				ds.append("• %s: %s" % [String(o2.t), String(o2.d)])
		if not ds.is_empty():
			body += "\n\n" + "\n".join(ds)
	ui.show_dialog("TARİHÎ AN  /  " + String(c.title), body, btns, String(c.scene), String(c.icon))


func _on_career_card() -> void:
	if gs == null or not Career.active(gs):
		return
	var spec: Dictionary = CareerUI.card_spec(gs, func():
		ui.refresh_top()
		if ui.has_method("refresh_card"):
			ui.refresh_card(), ui)
	if spec.is_empty():
		return
	_on_speed_changed(0)
	ui.show_dialog(String(spec.title), String(spec.body), spec.buttons, String(spec.get("scene", "")), String(spec.get("icon", "")))


## Menüden Bağımsızlık Yolu başlatılır: yeni dünya, ayrılacak ülke ve hareketin kurulumu
func _start_indep(params: Dictionary) -> void:
	_detach_gs()
	var g = GS.new()
	g.new_world(world_rng.randi() % 1000000)
	_attach_gs(g)
	Eras.prepare("")
	map.set_highlight_country(-1)
	ui.reset_news()
	var host: int = int(gs.macro_idx.get(String(params.get("host_en", "")), -1))
	if host < 0:
		ui.toast("Ülke bulunamadı.")
		return
	gs.difficulty = Settings.difficulty
	gs.start_game(host)
	if not Independence.begin(gs, params):
		ui.toast("Hareket kurulamadı; başka bir bölge dene.")
		return
	AP.cur_key = "indep"
	map.repaint_all()
	mode = "game"
	playing = true
	map.input_enabled = true
	menu.hide_all()
	ui.gs = gs
	ui.set_hud_visible(true)
	ui.refresh_top()
	_apply_settings()
	_update_insets()
	var cap: int = gs.countries[gs.player].capital
	map.focus_country(gs.player)
	if cap >= 0:
		selected_pid = cap
		map.select_province(cap)
		ui.show_province(cap, null)
	sfx.play("horn", 0.6)
	ui.show_indep()


func _start_daily(cfg: Dictionary) -> void:
	_detach_gs()
	var g = GS.new()
	g.new_world(int(cfg.seed))
	_attach_gs(g)
	Eras.prepare("")
	map.set_highlight_country(-1)
	ui.reset_news()
	var pc: int = int(gs.macro_idx.get(String(cfg.country), -1))
	if pc < 0:
		ui.toast("Ülke bulunamadı.")
		return
	gs.start_game(pc)
	Daily.begin(gs, cfg)
	AP.cur_key = "daily"
	map.repaint_all()
	mode = "game"
	playing = true
	map.input_enabled = true
	menu.hide_all()
	ui.gs = gs
	ui.set_hud_visible(true)
	ui.refresh_top()
	_apply_settings()
	_update_insets()
	var cap: int = gs.countries[gs.player].capital
	map.focus_country(gs.player)
	if cap >= 0:
		selected_pid = cap
		map.select_province(cap)
		ui.show_province(cap, null)
	sfx.play("horn", 0.6)
	ui.show_daily()


func _on_game_over(victory: bool, text: String) -> void:
	_on_speed_changed(0)
	if victory:
		sfx.play("win")
		var win_ap: int = 0 if AP.cur_key == "daily" else AP.on_victory(AP.cur_key, gs.difficulty)
		if win_ap > 0:
			text += "\n\n" + Loc.t("Zafer ödülü: +%d AP") % win_ap
		ui.show_dialog("ZAFER!", text, [
			{"text": "Oynamaya devam et", "cb": func(): pass, "kind": "good"},
			{"text": "Ana menü", "cb": func(): _go_main_menu()},
		])
	else:
		sfx.play("lose")
		playing = false
		ui.show_dialog("Yenilgi", text, [
			{"text": "Ana menü", "cb": func(): _go_main_menu(), "kind": "good"},
		])


func _on_ally_call(friend: int, foe: int, kind: String) -> void:
	_on_speed_changed(0)
	var fname: String = gs.countries[friend].name
	var foename: String = gs.countries[foe].name
	var body := ""
	if kind == "defend":
		body = "Müttefikin %s, %s tarafından saldırıya uğradı! Savaşa katılacak mısın?\nKatılmazsan ittifak bozulur." % [fname, foename]
	else:
		body = "Müttefikin %s, %s devletine savaş açtı. Yanında yer alacak mısın?\nKatılmazsan ittifak bozulur." % [fname, foename]
	ui.show_dialog("İttifak çağrısı", body, [
		{"text": "Savaşa katıl", "cb": func(): gs.player_join_war(foe), "kind": "danger"},
		{"text": "Katılma", "cb": func():
			gs.cancel_proposal()
			gs.break_alliance(gs.player, friend)},
	])


func _on_side_call(a: int, b: int) -> void:
	_on_speed_changed(0)
	var an: String = gs.countries[a].name
	var bn: String = gs.countries[b].name
	var body := "%s ve %s birbirine savaş açtı. Dünya taraf tutuyor: birinin yanında savaşa girebilir ya da tarafsız kalabilirsin.\n\nTarafsızlık ticaret ve istikrar getirir; bir tarafı seçersen o ülkeyle ilişkin güçlenir, diğeriyle savaşa girersin." % [an, bn]
	ui.show_dialog("Büyük savaş: taraf seç", body, [
		{"text": "%s yanında savaş" % an, "cb": func(): gs.player_choose_side(a, b, 0), "kind": "danger"},
		{"text": "%s yanında savaş" % bn, "cb": func(): gs.player_choose_side(a, b, 1), "kind": "danger"},
		{"text": "Tarafsız kal", "cb": func(): gs.player_choose_side(a, b, 2), "kind": "good"},
	], "war")


func _on_un_vote_card() -> void:
	_on_speed_changed(0)
	var body: String = UN.pending_text(gs)
	var cast := func(v: int):
		var r: Dictionary = UN.player_vote(gs, v)
		if r.get("ok", false):
			ui.show_un_result(r)
	ui.show_dialog("BM oylaması", body + "\n\nOyun, ilişkilerini etkiler.", [
		{"text": "Lehte oy ver", "cb": func(): cast.call(1), "kind": "good", "icon": Icons.pick("vote_yes", "check")},
		{"text": "Aleyhte oy ver", "cb": func(): cast.call(0), "kind": "danger", "icon": Icons.pick("vote_no", "x")},
		{"text": "Çekimser", "cb": func(): cast.call(-1), "icon": Icons.pick("vote_abstain", "")},
	], SceneArt.un_scene(String(gs.un_pending.get("kind", ""))), "")


func _on_alliance_proposal(from_country: int) -> void:
	_on_speed_changed(0)
	var cname: String = gs.countries[from_country].name
	ui.show_dialog("İttifak teklifi", "%s seninle ittifak kurmak istiyor." % cname, [
		{"text": "Kabul et", "cb": func():
			gs.cancel_proposal()
			gs.make_alliance(gs.player, from_country), "kind": "good"},
		{"text": "Reddet", "cb": func(): gs.cancel_proposal(), "kind": "danger"},
	])


# ------------------------------------------------------------------ tuş / geri

func _back_action() -> void:
	if ui.is_dialog_open():
		ui.hide_dialog()
	elif mode == "game":
		ui.show_pause_menu()
	elif mode == "select":
		_back_to_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back_action()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_arm_reminder()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if notifier != null:
			notifier.cancel()


## Yalnızca devam eden (bitmemiş) bir oyun varken 5 saatte bir hatırlatma planlanır.
func _arm_reminder() -> void:
	if notifier == null or not Settings.notifications or not notifier.available():
		return
	if mode != "game" or not playing or gs == null or not gs.game_started or gs.player < 0 or not gs.countries[gs.player].alive:
		notifier.cancel()
		return
	var cn: String = gs.countries[gs.player].name
	var msgs: Array = [
		"Ordun seni bekliyor, komutan!",
		"%s için yeni kararlar bekliyor. Turu geç!" % cn,
		"Cephede hareketlilik var; emirlerini ver.",
		"Kasanda birikim var. Silah mı, bina mı? Karar senin.",
		"Dünya sensiz dönmüyor: Cihan Bülteni'nde yeni haberler var.",
	]
	notifier.schedule("Age of Doctrine", tr(msgs[randi() % msgs.size()]))


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_back_action()
		KEY_SPACE, KEY_ENTER:
			if mode == "game" and not ui.is_dialog_open():
				_on_step()


func _start_tutorial() -> void:
	if tutorial != null and is_instance_valid(tutorial):
		tutorial.queue_free()
	tutorial = load("res://scripts/tutorial.gd").open(ui, gs, self)
