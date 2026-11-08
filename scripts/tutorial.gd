extends Control
## Etkileşimli öğretici: ekranın üstünde adım adım yönerge kartı; eylem adımları oyuncu yapınca kendiliğinden ilerler
## (her adım «Geç» ile atlanabilir). Menüden istenildiği an yeniden açılır.

const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")
const Settings = preload("res://scripts/settings.gd")

## need: tap | army | order | turn | war | battle | capture  ("" = bilgi adımı, «Devam» ile geçilir)
## hl: vurgulanacak öğe: side:N | turn | topbar | menu
const STEPS := [
	{"t": "Hoş geldin, komutan", "b": "Bu kısa rehber oyunun temelini öğretir. İstediğin adımı «Geç» ile atlayabilirsin; eylem adımları sen yapınca kendiliğinden ilerler.", "need": "", "hl": ""},
	{"t": "Haritayı tanı", "b": "Haritayı parmağınla sürükle, iki parmakla yakınlaştır. Şimdi herhangi bir eyalete dokun.", "need": "tap", "hl": ""},
	{"t": "Eyalet kartı", "b": "Kartta eyaletin sahibi, nüfusu, geliri ve savunması yazar; başkent yıldızlıdır. Eyaletlerin sana gelir getirir, kaybettikçe gelirin düşer.", "need": "", "hl": ""},
	{"t": "Üst çubuk", "b": "Kasa (para), asker, eyalet sayısı ve tarih burada. Her tur bir haftadır: gelir her hafta kasana eklenir, ordu ve harcamalar düşer.", "need": "", "hl": "topbar"},
	{"t": "Ordunu seç", "b": "Kendi eyaletine dokun ve kartta «Ordu seç» düğmesine bas. Ordular harita üzerinde asker sayısıyla görünür.", "need": "army", "hl": ""},
	{"t": "Ordu hareketi", "b": "Komşu bir eyalete dokun ve «Ordu buraya yürüsün» de. Elle gönderdiğin ordu varışta bekler; emir vermediğin ordular, ayardaysa, otomatik savaşır.", "need": "order", "hl": ""},
	{"t": "Turu geçir", "b": "Sağ üstteki «Turu geç» düğmesiyle bir hafta ilerlet. Haberler üstteki Cihan Bülteni'nde akar; dokunarak geçmişi aç.", "need": "turn", "hl": "turn"},
	{"t": "Politika paneli", "b": "Sağdaki tank düğmesi: bütçe dağılımı (askerî, sanayi, siber, lojistik...), silah alımı, envanter, ticaret, cepheler, ittifaklar, istihbarat ve kabine. Gücün buradan büyür.", "need": "", "hl": "side:0"},
	{"t": "Kabine ve istikrar", "b": "Politika → Kabine: bakanlar ülkenin kültürüne göre atanır; iyi bakan gelir, ordu ve istikrara bonus verir. Savaş yorgunluğu ve düşük istikrar eyaletlerde huzursuzluk ve isyan çıkarır; paralı asker kiralayarak ordunu hızla güçlendirebilirsin.", "need": "", "hl": ""},
	{"t": "Savaş ilanı", "b": "Önce komşu zayıf bir ülke seç. Önerim: {target}. Onun bir eyaletine dokun ve «Savaş ilan et» de. Müttefikleri sana karşı çıkabilir; bedeli düşün.", "need": "war", "hl": ""},
	{"t": "Taarruz", "b": "Düşman eyaletine dokun ve «Taarruz»a bas. Ordularını seç, harekât türünü belirle (topçu, hava, donanma, füze, paraşüt, özel kuvvet...). Üstünlük çubuğu kazanma şansını gösterir.", "need": "battle", "hl": ""},
	{"t": "Kuşatma ve fetih", "b": "Savunmayı yenen ordu eyalete girer ve kuşatır; kuşatma süresi dolunca eyalet senin olur ve savaş puanın artar. Ordular sınırı geçerken izin gerekir.", "need": "capture", "hl": ""},
	{"t": "Barış masası", "b": "Savaş puanın yüksekse düşman eyaletine dokunup «Barış teklif et»: aldığın eyaletleri ve tazminat, silahsızlandırma, tampon bölge şartlarını puanınla seçersin. Fazla fetih «dünya tepkisi»ni artırır; 50'yi aşarsa ülkeler koalisyon kurar.", "need": "", "hl": ""},
	{"t": "İttifak ve ilişkiler", "b": "Dost bir ülkenin eyaletine dokun: «İttifak teklif et» ya da «İlişkiler» (kim kimle müttefik, kim savaşta). Sağdaki el sıkışma düğmesi haritayı ilişki renklerine boyar.", "need": "", "hl": "side:3"},
	{"t": "Dünya ve BM", "b": "Sağdaki küre düğmesi: sıralama, bloklar, haberler ve BM. BM'de ateşkes, yeniden inşa, yardım, yaptırım gibi önergeleri oy çokluğuyla geçirirsin (veto yok).", "need": "", "hl": "side:1"},
	{"t": "Nükleer ve riskler", "b": "Nükleer güçsen düşman eyaletine nükleer saldırı yapabilirsin: büyük yıkım, ama ağır yaptırım ve koalisyon getirir. Son çare olarak sakla.", "need": "", "hl": ""},
	{"t": "Kaydet ve hedefler", "b": "Sol üstteki ≡ menüsü: kaydet/yükle, ayarlar ve «Hedefler ve başarımlar». Ayarlardan otomatik kayıt açılabilir. Başarımlar kalıcıdır.", "need": "", "hl": "menu"},
	{"t": "Hazırsın!", "b": "Artık fethe, diplomasiye ya da barışla kalkınmaya hazırsın. Öğreticiyi istediğin an menüden tekrar açabilirsin. İyi şanslar!", "need": "", "hl": ""},
]

var ui = null
var gs = null
var main = null
var idx := 0
var _base := {}
var _tapped := false
var _tick := 0.0
var _done_cond := false
var _title: Label
var _body: Label
var _count: Label
var _next: Button
var _skip: Button
var _wait: Label
var _ring: Panel
var _panel: PanelContainer
var _hl_node: Control = null


static func open(ui_, gs_, main_) -> Control:
	var tu = load("res://scripts/tutorial.gd").new()
	tu.ui = ui_
	tu.gs = gs_
	tu.main = main_
	ui_.root.add_child(tu)
	return tu


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring = Panel.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0, 0, 0, 0)
	rs.border_color = TK.PAPER
	rs.set_border_width_all(4)
	rs.set_corner_radius_all(6)
	_ring.add_theme_stylebox_override("panel", rs)
	_ring.visible = false
	add_child(_ring)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.add_theme_stylebox_override("panel", TK.box(Color(TK.PANEL.r, TK.PANEL.g, TK.PANEL.b, 0.98), TK.PAPER, 6, 2, 1, Vector4(18, 12, 18, 14)))
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_panel.add_child(v)
	var top := HBoxContainer.new()
	_count = TK.t("", "kicker", TK.PAPER)
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_count)
	v.add_child(top)
	_title = TK.t("", "h3", TK.TEXT)
	v.add_child(_title)
	_body = TK.t("", "body", TK.MUTED)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(430, 0)
	_body.add_theme_font_size_override("font_size", 21)
	_title.add_theme_font_size_override("font_size", 30)
	v.add_child(_body)
	_wait = TK.t("", "small", TK.PAPER)
	v.add_child(_wait)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	_skip = TK.button("Kapat", "ghost", "", Vector2(0, 52), 13)
	_skip.pressed.connect(func():
		ui._click()
		finish(false))
	row.add_child(_skip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	_next = TK.button("Devam", "", "", Vector2(150, 52), 14)
	_next.pressed.connect(func():
		ui._click()
		_advance())
	row.add_child(_next)
	main.map.tapped.connect(_on_tap)
	_show(0)


func _on_tap(_pid: int) -> void:
	_tapped = true


func _snapshot() -> void:
	_base = {"orders": gs.stats.orders, "turn": gs.turn, "p_wars": gs.stats.p_wars, "p_battles": gs.stats.p_battles, "p_captures": gs.stats.p_captures}
	_tapped = false
	_done_cond = false


func _target_name() -> String:
	var best := ""
	var best_t := 1.0e18
	for cid in gs.neighbor_countries(gs.player):
		var c = gs.countries[cid]
		if not c.alive or c.is_rebel or gs.is_allied(cid, gs.player) or gs.at_war(cid, gs.player):
			continue
		if c.truce.get(gs.player, -1) > gs.turn:
			continue
		if c.troops < best_t:
			best_t = c.troops
			best = c.name
	return best if best != "" else Loc.t("komşu bir ülke")


func _show(i: int) -> void:
	idx = i
	var s: Dictionary = STEPS[idx]
	_snapshot()
	_count.text = "%s  %d / %d" % [Loc.t("ÖĞRETİCİ"), idx + 1, STEPS.size()]
	_title.text = Loc.t(s.t)
	var body: String = Loc.t(s.b)
	if body.contains("{target}"):
		body = body.replace("{target}", _target_name())
	_body.text = body
	var action_step: bool = s.need != ""
	_next.visible = true
	_next.text = TK.up(Loc.t("Geç") if action_step else (Loc.t("Bitir") if idx == STEPS.size() - 1 else Loc.t("Devam")))
	_wait.text = Loc.t("Yönergeyi yap, kart kendiliğinden ilerler.") if action_step else ""
	_skip.visible = idx < STEPS.size() - 1
	_set_highlight(str(s.hl))
	_panel.reset_size()
	_place.call_deferred()


func _place() -> void:
	if not is_inside_tree():
		return
	_panel.reset_size()
	var vw: float = get_viewport_rect().size.x
	_panel.position = Vector2(vw - 96.0 - _panel.size.x, ui.BAR_H + ui.TICK_H + 12.0)


func _advance() -> void:
	if idx >= STEPS.size() - 1:
		finish(true)
	else:
		_show(idx + 1)


func finish(_completed: bool) -> void:
	Settings.tut_done = true
	Settings.save_all()
	if main.map.tapped.is_connected(_on_tap):
		main.map.tapped.disconnect(_on_tap)
	if main.tutorial == self:
		main.tutorial = null
	queue_free()


func _set_highlight(h: String) -> void:
	_hl_node = null
	if h.begins_with("side:"):
		var n: int = int(h.substr(5))
		if ui.side != null and n < ui.side.get_child_count():
			_hl_node = ui.side.get_child(n)
	elif h == "turn":
		_hl_node = ui._turn_btn
	elif h == "topbar":
		_hl_node = ui.topbar
	elif h == "menu":
		_hl_node = ui._menu_btn
	_ring.visible = _hl_node != null


func _condition_met(need: String) -> bool:
	match need:
		"tap": return _tapped
		"army": return main.selected_army != null
		"order": return gs.stats.orders > _base.orders
		"turn": return gs.turn >= _base.turn + 1
		"war": return gs.stats.p_wars > _base.p_wars
		"battle": return gs.stats.p_battles > _base.p_battles
		"capture": return gs.stats.p_captures > _base.p_captures
	return false


func _process(delta: float) -> void:
	if gs == null:
		return
	if _ring.visible and is_instance_valid(_hl_node):
		var r: Rect2 = _hl_node.get_global_rect()
		var o: Vector2 = get_global_rect().position
		var pulse: float = 4.0 + 3.0 * sin(Time.get_ticks_msec() / 220.0)
		_ring.position = r.position - o - Vector2(pulse, pulse)
		_ring.size = r.size + Vector2(pulse, pulse) * 2.0
	_tick += delta
	if _tick < 0.25:
		return
	_tick = 0.0
	var need: String = STEPS[idx].need
	if need != "" and not _done_cond and _condition_met(need):
		_done_cond = true
		_wait.text = Loc.t("Tamam!")
		await get_tree().create_timer(0.9).timeout
		if is_inside_tree() and STEPS[idx].need == need:
			_advance()
