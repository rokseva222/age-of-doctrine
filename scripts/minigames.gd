extends RefCounted
## Etkileşimli mini oyunlar (tarihî ağırlıkta, kısa). Şimdilik: Düello (tek dövüş / meydan okuma).
## Kullanım: duel(ui, {foe, style, skill, title, intro, win_text, lose_text}, func(result: String, info: Dictionary): ...)
## result: "win" | "lose" | "draw" | "yield"

const TK = preload("res://scripts/theme_kit.gd")
const PS = preload("res://scripts/pixel_scenes.gd")
const SceneArt = preload("res://scripts/scene_art.gd")

const MOVES := ["Kes", "Siper", "Hamle"]
const MOVE_HELP := ["Doğrudan vuruş. Hamle'yi ezer, Siper'e takılır.", "Kapanıp bekle. Kes'i karşılar, Hamle'ye yenilir.", "Aldatma ve yan vuruş. Siper'i bozar, Kes'e yakalanır."]
const TELLS := ["Ağırlığını öne verdi, omzu yükseldi.", "Kılıcını yüksek, gövdesini kapalı tutuyor.", "Bakışı kaçamak, adımı hafif ve yanlara kayıyor."]
const BODY := [
	"...kkk...",
	"..kkkkk..",
	"..keeek..",
	"...eee...",
	"..XXXXX..",
	".XXXXXXX.",
	".XXYYYXX.",
	"..XXXXX..",
	"..XXXXX..",
	"..YYYYY..",
	"..dd.dd..",
	"..dd.dd..",
	"..dd.dd..",
	"..kk.kk..",
]
enum Pose { IDLE, STRIKE, GUARD, FEINT, HIT }
const ROUND_CAP := 10
const CHOOSE_TIME := 6.0


## Düello penceresini açar; oyun hızını durdurur.
static func duel(ui, spec: Dictionary, cb: Callable) -> void:
	if ui.speed_idx != 0:
		ui.set_speed(0)
		ui.speed_changed.emit(0)
	var ov := DuelView.new()
	ov.setup(ui, spec, cb)
	ui.root.add_child(ov)
	ui.set_modal(ov)


class DuelView extends Control:
	var ui
	var spec: Dictionary
	var cb: Callable
	var arena: Control
	var tell_lbl: Label
	var info_lbl: Label
	var btns: Array = []
	var yield_btn: Button
	var end_box: VBoxContainer
	var php := 100.0
	var ohp := 100.0
	var pst := 3
	var ost := 3
	var rnd := 1
	var phase := "intro"      # intro | choose | anim | end
	var t := 0.0              # faz süresi
	var clock := 0.0
	var foe_move := 0
	var tell_idx := 0
	var last_player := -1
	var res := {"w": 0, "pdmg": 0.0, "odmg": 0.0, "pm": 0, "om": 0}
	var impact_done := false
	var flash_p := 0.0
	var flash_o := 0.0
	var skill := 0.3
	var rng := RandomNumberGenerator.new()
	var banner := ""
	var outcome := ""
	var log_lines: Array = []

	func close() -> void:
		queue_free()

	## PC: 1/2/3 ya da A/S/D ya da ←/↓/→ ile hamle; Boşluk/Enter ile devam; dokunmatik ve fare düğmelerle çalışır.
	func _input(e: InputEvent) -> void:
		if not (e is InputEventKey) or not e.pressed or e.echo:
			return
		var k: int = e.keycode
		if phase == "choose":
			var m: int = -1
			if k in [KEY_1, KEY_KP_1, KEY_A, KEY_LEFT]:
				m = 0
			elif k in [KEY_2, KEY_KP_2, KEY_S, KEY_DOWN]:
				m = 1
			elif k in [KEY_3, KEY_KP_3, KEY_D, KEY_RIGHT]:
				m = 2
			if m >= 0:
				get_viewport().set_input_as_handled()
				_pick(m)
		elif phase == "end" and k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			if end_box.get_child_count() > 0:
				(end_box.get_child(0) as Button).emit_signal("pressed")

	func setup(ui_, spec_: Dictionary, cb_: Callable) -> void:
		ui = ui_
		spec = spec_
		cb = cb_
		skill = clampf(float(spec.get("skill", 0.3)), 0.0, 1.0)
		rng.randomize()
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.04, 1.0)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 14
		vb.offset_right = -14
		vb.offset_top = 10
		vb.offset_bottom = -10
		vb.add_theme_constant_override("separation", 8)
		add_child(vb)
		var title := TK.t(String(spec.get("title", "Meydan Okuma")), "h3", TK.TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(title)
		arena = Arena.new()
		arena.view = self
		arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
		arena.custom_minimum_size = Vector2(0, 220)
		vb.add_child(arena)
		tell_lbl = TK.t("", "bodyb", TK.GOLD)
		tell_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(tell_lbl)
		info_lbl = TK.t("", "small", TK.MUTED)
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(info_lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		for i in 3:
			var idx: int = i
			var b := TK.button("%s  [%d]" % [MOVES[i], i + 1], ["danger", "blue", "gold"][i], ["sword", "shield", "spy"][i], Vector2(0, 72), 18)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func(): _pick(idx))
			row.add_child(b)
			btns.append(b)
		yield_btn = TK.button("Meydanı terk et", "ghost", "", Vector2(0, 52), 15)
		yield_btn.pressed.connect(func(): _finish("yield"))
		vb.add_child(yield_btn)
		end_box = VBoxContainer.new()
		end_box.visible = false
		vb.add_child(end_box)
		_set_buttons(false)
		banner = String(spec.get("intro", "Kılıçlar çekildi."))
		set_process(true)

	func _set_buttons(on: bool) -> void:
		for b in btns:
			b.disabled = not on

	func _process(d: float) -> void:
		clock += d
		t += d
		flash_p = maxf(0.0, flash_p - d)
		flash_o = maxf(0.0, flash_o - d)
		match phase:
			"intro":
				if t > 1.6:
					_begin_round()
			"choose":
				if t >= CHOOSE_TIME:
					_pick(1)
				info_lbl.text = "Tur %d / %d   –   karar süresi: %d sn" % [rnd, ROUND_CAP, int(ceil(CHOOSE_TIME - t))]
			"anim":
				if t > 0.42 and not impact_done:
					_impact()
				if t > 1.25:
					_after_round()
		arena.queue_redraw()

	# ---------------------------------------------------------- tur akışı
	func _begin_round() -> void:
		phase = "choose"
		t = 0.0
		impact_done = false
		banner = ""
		foe_move = _foe_choose()
		var acc: float = clampf(0.5 + skill * 0.3, 0.4, 0.85)
		tell_idx = foe_move if rng.randf() < acc else (foe_move + 1 + rng.randi() % 2) % 3
		tell_lbl.text = "Rakibi izle: " + String(TELLS[tell_idx])
		_set_buttons(true)
		for i in 3:
			btns[i].disabled = false
		info_lbl.text = ""

	func _foe_choose() -> int:
		var st: Array = spec.get("style", [1.0, 1.0, 1.0])
		var w: Array = [float(st[0]), float(st[1]), float(st[2])]
		if ost <= 0:
			w[0] *= 0.2
			w[2] *= 0.2
			w[1] += 2.0
		if last_player >= 0:
			var counter: int = {0: 1, 1: 2, 2: 0}[last_player]   # oyuncunun son hamlesini yenen
			w[counter] += 0.6
		var tot: float = w[0] + w[1] + w[2]
		var r: float = rng.randf() * tot
		for i in 3:
			if r < w[i]:
				return i
			r -= w[i]
		return 1

	static func _beats(a: int, b: int) -> int:
		if a == b:
			return 0
		if (a == 0 and b == 2) or (a == 2 and b == 1) or (a == 1 and b == 0):
			return 1
		return -1

	func _pick(pm: int) -> void:
		if phase != "choose":
			return
		phase = "anim"
		t = 0.0
		_set_buttons(false)
		last_player = pm
		var om: int = foe_move
		var w: int = _beats(pm, om)
		var pd := 0.0
		var od := 0.0
		var pw: float = 1.0 + skill * 0.25
		var ow: float = float(spec.get("power", 1.0))
		var ptired: bool = pm != 1 and pst <= 0
		var otired: bool = om != 1 and ost <= 0
		if w == 1:
			od = 26.0 * pw * (0.5 if ptired else 1.0) if pm != 1 else 9.0
		elif w == -1:
			pd = 26.0 * ow * (0.5 if otired else 1.0) if om != 1 else 9.0
		elif pm == 0:
			pd = 12.0
			od = 12.0
		if pm != 1:
			pst = maxi(0, pst - 1)
		else:
			pst = mini(4, pst + 1)
		if om != 1:
			ost = maxi(0, ost - 1)
		else:
			ost = mini(4, ost + 1)
		if w == 1 and pm == 1:
			ost = maxi(0, ost - 1)
		if w == -1 and om == 1:
			pst = maxi(0, pst - 1)
		res = {"w": w, "pdmg": pd, "odmg": od, "pm": pm, "om": om}
		banner = ""

	func _impact() -> void:
		impact_done = true
		php = maxf(0.0, php - float(res.pdmg))
		ohp = maxf(0.0, ohp - float(res.odmg))
		if res.pdmg > 0.0:
			flash_p = 0.35
		if res.odmg > 0.0:
			flash_o = 0.35
		var s = ui.sfx
		if s != null:
			if res.pdmg > 0.0:
				s.play("error", 0.5)
			elif res.odmg > 0.0:
				s.play("order", 0.6)
			else:
				s.play("paper", 0.5)
		var pm: int = res.pm
		var om: int = res.om
		var line: String = "Sen: %s  –  Rakip: %s" % [MOVES[pm], MOVES[om]]
		if res.w == 1:
			line += "  →  isabet" if res.odmg > 0.0 else ""
		elif res.w == -1:
			line += "  →  yara aldın" if res.pdmg > 0.0 else ""
		else:
			line += "  →  kılıçlar çarpıştı"
		info_lbl.text = line
		tell_lbl.text = ""

	func _after_round() -> void:
		if php <= 0.0 or ohp <= 0.0 or rnd >= ROUND_CAP:
			if php <= 0.0 and ohp <= 0.0:
				_finish("draw")
			elif ohp <= 0.0:
				_finish("win")
			elif php <= 0.0:
				_finish("lose")
			else:
				_finish("win" if ohp < php else ("lose" if php < ohp else "draw"))
			return
		rnd += 1
		_begin_round()

	func _finish(r: String) -> void:
		if phase == "end":
			return
		phase = "end"
		outcome = r
		_set_buttons(false)
		yield_btn.visible = false
		tell_lbl.text = ""
		var txt: String
		match r:
			"win":
				txt = String(spec.get("win_text", "Rakip silahını bıraktı. Meydan senin."))
			"lose":
				txt = String(spec.get("lose_text", "Yere yığıldın. Ordugâh sessizliğe gömüldü."))
			"draw":
				txt = String(spec.get("draw_text", "İki taraf da ayakta kalamadı; hakemler dövüşü durdurdu."))
			_:
				txt = String(spec.get("yield_text", "Meydanı terk ettin; bunu herkes gördü."))
		banner = {"win": "ZAFER", "lose": "YENİLGİ", "draw": "BERABERE", "yield": "ÇEKİLDİN"}[r]
		info_lbl.text = txt
		var b := TK.button("Devam", "good" if r == "win" else "", "", Vector2(0, 64), 18)
		b.pressed.connect(func():
			var info := {"hp": php, "foe_hp": ohp, "rounds": rnd}
			ui.set_modal(null)
			queue_free()
			cb.call(outcome, info))
		end_box.add_child(b)
		end_box.visible = true


# ------------------------------------------------------------------ Müzakere (modern / dünya savaşı çağları)
const NEG_MOVES := ["Baskı yap", "Taviz ver", "Gerekçe sun"]
const NEG_STANCE := ["Sert", "Esnek", "Aceleci"]
const NEG_TELLS := ["Çenesi sıkılı, ellerini masaya bastırıyor; geri adım atacak gibi değil.", "Rahat; kâğıtlarına bakmadan dinliyor, itiraz etmiyor.", "Saatine bakıp duruyor; bir an önce bir sonuç almak istiyor."]
const NEG_HELP := ["Yük bindir. Esnek karşıya iyi gelir, sert karşıda ters teper.", "Geri adım at. Sert karşıyı yumuşatır, esneğe boşuna taviz olur.", "Mantıklı gerekçe sun. Aceleci karşıyı ikna eder."]
# satır: hamle, sütun: rakibin duruşu (Sert, Esnek, Aceleci)
const NEG_GAIN := [[-14.0, 16.0, 4.0], [12.0, -4.0, -8.0], [2.0, 6.0, 14.0]]
const NEG_ROUNDS := 6


## Müzakere masası: 6 turda anlaşma ölçeğini 75'in üstüne çıkar.
## spec: {title, intro, scene, style:[sert,esnek,aceleci], skill, win_text, lose_text, draw_text, yield_text}
static func negotiate(ui, spec: Dictionary, cb: Callable) -> void:
	if ui.speed_idx != 0:
		ui.set_speed(0)
		ui.speed_changed.emit(0)
	var ov := NegView.new()
	ov.setup(ui, spec, cb)
	ui.root.add_child(ov)
	ui.set_modal(ov)


class NegView extends Control:
	var ui
	var spec: Dictionary
	var cb: Callable
	var meter: ProgressBar
	var meter_lbl: Label
	var tell_lbl: Label
	var info_lbl: Label
	var btns: Array = []
	var walk_btn: Button
	var end_box: VBoxContainer
	var deal := 50.0
	var rnd := 1
	var stance := 0
	var skill := 0.3
	var phase := "choose"
	var rng := RandomNumberGenerator.new()
	var last_move := -1

	func setup(ui_, spec_: Dictionary, cb_: Callable) -> void:
		ui = ui_
		spec = spec_
		cb = cb_
		skill = clampf(float(spec.get("skill", 0.3)), 0.0, 1.0)
		rng.randomize()
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.04, 1.0)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 14
		vb.offset_right = -14
		vb.offset_top = 10
		vb.offset_bottom = -10
		vb.add_theme_constant_override("separation", 8)
		add_child(vb)
		var title := TK.t(String(spec.get("title", "Müzakere")), "h3", TK.TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(title)
		var art = SceneArt.make(String(spec.get("scene", "talks")), 0.0)
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art.custom_minimum_size = Vector2(0, 430)
		vb.add_child(art)
		var intro := TK.t(String(spec.get("intro", "Masaya oturdunuz. Karşı tarafın duruşunu oku, doğru hamleyi seç.")), "small", TK.MUTED)
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(intro)
		meter_lbl = TK.t("", "bodyb", TK.TEXT)
		meter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(meter_lbl)
		meter = ProgressBar.new()
		meter.min_value = 0.0
		meter.max_value = 100.0
		meter.show_percentage = false
		meter.custom_minimum_size = Vector2(0, 26)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.85, 0.7, 0.25)
		fill.set_corner_radius_all(6)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.16, 0.17, 0.22)
		back.set_corner_radius_all(6)
		meter.add_theme_stylebox_override("fill", fill)
		meter.add_theme_stylebox_override("background", back)
		vb.add_child(meter)
		tell_lbl = TK.t("", "bodyb", TK.GOLD)
		tell_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(tell_lbl)
		info_lbl = TK.t("", "small", TK.MUTED)
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(info_lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		for i in 3:
			var idx: int = i
			var b := TK.button("%s  [%d]" % [NEG_MOVES[i], i + 1], ["danger", "blue", "gold"][i], ["sword", "handshake", "book"][i], Vector2(0, 72), 18)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.tooltip_text = String(NEG_HELP[i])
			b.pressed.connect(func(): _pick(idx))
			row.add_child(b)
			btns.append(b)
		var help := TK.t("Baskı → esnek karşıya. Taviz → sert karşıya. Gerekçe → aceleci karşıya.", "small", TK.FAINT)
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(help)
		walk_btn = TK.button("Masadan kalk", "ghost", "", Vector2(0, 52), 15)
		walk_btn.pressed.connect(func(): _finish("yield"))
		vb.add_child(walk_btn)
		end_box = VBoxContainer.new()
		end_box.visible = false
		vb.add_child(end_box)
		_begin_round()

	func _input(e: InputEvent) -> void:
		if not (e is InputEventKey) or not e.pressed or e.echo:
			return
		var k: int = e.keycode
		if phase == "choose":
			var m: int = -1
			if k in [KEY_1, KEY_KP_1, KEY_A, KEY_LEFT]:
				m = 0
			elif k in [KEY_2, KEY_KP_2, KEY_S, KEY_DOWN]:
				m = 1
			elif k in [KEY_3, KEY_KP_3, KEY_D, KEY_RIGHT]:
				m = 2
			if m >= 0:
				get_viewport().set_input_as_handled()
				_pick(m)
		elif phase == "end" and k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			if end_box.get_child_count() > 0:
				(end_box.get_child(0) as Button).emit_signal("pressed")

	func _refresh() -> void:
		meter.value = deal
		meter_lbl.text = "Anlaşma ölçeği: %d   (Tur %d / %d)" % [int(round(deal)), rnd, NEG_ROUNDS]

	func _begin_round() -> void:
		phase = "choose"
		var st: Array = spec.get("style", [1.0, 1.0, 1.0])
		var w: Array = [float(st[0]), float(st[1]), float(st[2])]
		if last_move >= 0:
			w[(last_move + 1) % 3] += 0.8      # karşı taraf oyuncunun son hamlesine uyum sağlar
		var tot: float = w[0] + w[1] + w[2]
		var r: float = rng.randf() * tot
		stance = 2
		for i in 3:
			if r < w[i]:
				stance = i
				break
			r -= w[i]
		var acc: float = clampf(0.55 + skill * 0.3, 0.45, 0.88)
		var shown: int = stance if rng.randf() < acc else (stance + 1 + rng.randi() % 2) % 3
		tell_lbl.text = "Karşı tarafı izle: " + String(NEG_TELLS[shown])
		info_lbl.text = ""
		for b in btns:
			b.disabled = false
		_refresh()

	func _pick(m: int) -> void:
		if phase != "choose":
			return
		phase = "anim"
		last_move = m
		for b in btns:
			b.disabled = true
		var g: float = float(NEG_GAIN[m][stance])
		if g > 0.0:
			g *= 1.0 + skill * 0.2
		deal = clampf(deal + g, 0.0, 100.0)
		var s = ui.sfx
		if s != null:
			s.play("paper" if g >= 0.0 else "error", 0.5)
		var verdict: String = "karşı taraf ikna oldu" if g >= 10.0 else ("küçük bir ilerleme" if g > 0.0 else "masa gerildi")
		info_lbl.text = "Sen: %s  –  Karşı taraf: %s  →  %s (%+d)" % [NEG_MOVES[m], NEG_STANCE[stance], verdict, int(round(g))]
		tell_lbl.text = ""
		_refresh()
		await get_tree().create_timer(1.0).timeout
		if phase != "anim":
			return
		if deal >= 100.0:
			_finish("win")
		elif deal <= 0.0:
			_finish("lose")
		elif rnd >= NEG_ROUNDS:
			_finish("win" if deal >= 75.0 else ("lose" if deal <= 25.0 else "draw"))
		else:
			rnd += 1
			_begin_round()

	func _finish(r: String) -> void:
		if phase == "end":
			return
		phase = "end"
		for b in btns:
			b.disabled = true
		walk_btn.visible = false
		tell_lbl.text = ""
		var txt: String
		match r:
			"win":
				txt = String(spec.get("win_text", "Karşı taraf şartlarını kabul etti. Anlaşma imzalandı."))
			"lose":
				txt = String(spec.get("lose_text", "Görüşmeler çöktü. Karşı taraf masayı terk etti."))
			"draw":
				txt = String(spec.get("draw_text", "Taraflar kesin bir sonuca varamadı; görüşmeler ertelendi."))
			_:
				txt = String(spec.get("yield_text", "Masadan kalktın; bu itibarına zarar verdi."))
		meter_lbl.text = {"win": "ANLAŞMA", "lose": "ÇÖKTÜ", "draw": "ERTELENDİ", "yield": "MASADAN KALKTIN"}[r]
		info_lbl.text = txt
		var b := TK.button("Devam", "good" if r == "win" else "", "", Vector2(0, 64), 18)
		b.pressed.connect(func():
			var info := {"deal": deal, "rounds": rnd}
			ui.set_modal(null)
			queue_free()
			cb.call(r, info))
		end_box.add_child(b)
		end_box.visible = true


class Arena extends Control:
	var view

	func _draw() -> void:
		if view == null:
			return
		var w: float = size.x
		var h: float = size.y
		var ps: float = maxf(2.0, floorf(minf(w / 105.0, h / 52.0)))
		var P = PS
		# gökyüzü (alacakaranlık bantları)
		var bands := [Color("2b1b3d"), Color("4a2a4a"), Color("7a3b4a"), Color("b0594a"), Color("d98a55")]
		var gh: float = h * 0.72
		for i in bands.size():
			draw_rect(Rect2(0, gh * i / bands.size(), w, gh / bands.size() + 1), bands[i])
		# uzak tepe ve çadırlar
		var step: float = ps * 6.0
		var x: float = 0.0
		var hill := Color("1d1a2b")
		while x < w:
			var hh: float = ps * (3.0 + 2.0 * absf(sin(x * 0.011)))
			draw_rect(Rect2(x, gh - hh, step, hh), hill)
			x += step
		for tx in [0.08, 0.2, 0.78, 0.9]:
			var cx: float = w * tx
			draw_colored_polygon(PackedVector2Array([Vector2(cx - ps * 6, gh), Vector2(cx, gh - ps * 9), Vector2(cx + ps * 6, gh)]), Color("2a2438"))
		# zemin
		draw_rect(Rect2(0, gh, w, h - gh), Color("3a2e2a"))
		draw_rect(Rect2(0, gh, w, ps), Color("54443a"))
		for i in 18:
			draw_rect(Rect2(fmod(i * 97.0, w), gh + ps * (2.0 + float(i % 4) * 2.0), ps * 3.0, ps), Color("2b221f"))
		# seyirci siluetleri
		for i in 26:
			var sx: float = w * (0.02 + 0.04 * float(i))
			if sx > w * 0.34 and sx < w * 0.66:
				continue
			var bob: float = float(int(view.clock * 4.0 + i) % 2) * (ps * 0.5 if i % 3 == 0 else 0.0)
			draw_rect(Rect2(sx, gh - ps * 4.0 - bob, ps * 2.0, ps * 4.0), Color("17141f"))
			draw_rect(Rect2(sx, gh - ps * 6.0 - bob, ps * 2.0, ps * 2.0), Color("17141f"))
		# meşaleler
		for tx2 in [0.33, 0.67]:
			var fx: float = w * tx2
			draw_rect(Rect2(fx, gh - ps * 10.0, ps, ps * 10.0), Color("5a3a22"))
			var fl: float = ps * (2.0 + float(int(view.clock * 8.0 + tx2 * 10.0) % 3))
			draw_rect(Rect2(fx - ps * 0.5, gh - ps * 10.0 - fl, ps * 2.0, fl), Color("ef7d57"))
			draw_rect(Rect2(fx, gh - ps * 10.0 - fl * 0.6, ps, fl * 0.6), Color("ffcd75"))
		# dövüşçüler
		var base_y: float = gh - ps * 14.0 + ps * 6.0
		var pose_p: int = Pose.IDLE
		var pose_o: int = Pose.IDLE
		var off_p: float = 0.0
		var off_o: float = 0.0
		if view.phase == "anim":
			var tt: float = view.t
			var k: float = clampf(tt / 0.42, 0.0, 1.0)
			var back: float = clampf((tt - 0.8) / 0.4, 0.0, 1.0)
			var lunge: float = k * (1.0 - back)
			var pm: int = view.res.pm
			var om: int = view.res.om
			pose_p = [Pose.STRIKE, Pose.GUARD, Pose.FEINT][pm]
			pose_o = [Pose.STRIKE, Pose.GUARD, Pose.FEINT][om]
			off_p = lunge * ps * (3.0 if pm != 1 else 1.0)
			off_o = lunge * ps * (3.0 if om != 1 else 1.0)
			if view.impact_done:
				if view.res.pdmg > 0.0:
					pose_p = Pose.HIT
					off_p = -lunge * ps * 3.0
				if view.res.odmg > 0.0:
					pose_o = Pose.HIT
					off_o = -lunge * ps * 3.0
		var lx: float = w * 0.38
		var rx: float = w * 0.62
		_fighter(lx + off_p, base_y, ps, Color("3b5dc9"), Color("ffcd75"), false, pose_p, view.flash_p > 0.0)
		_fighter(rx - off_o, base_y, ps, Color("b13e53"), Color("94b0c2"), true, pose_o, view.flash_o > 0.0)
		# kıvılcım
		if view.phase == "anim" and view.impact_done and view.t < 0.75:
			var sc: Vector2 = Vector2(w * 0.5, base_y + ps * 5.0)
			for i in 7:
				var a: float = float(i) * 0.9 + view.t * 3.0
				var rr: float = ps * (2.0 + (view.t - 0.42) * 18.0)
				draw_rect(Rect2(sc + Vector2(cos(a), sin(a)) * rr, Vector2(ps, ps)), Color("ffcd75"))
		# HUD
		_hud(w, ps)
		# afiş
		if view.banner != "":
			var f: Font = TK.disp(1)
			var fs: int = int(clampf(ps * 9.0, 28.0, 64.0))
			var sz: Vector2 = f.get_string_size(view.banner, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var pos: Vector2 = Vector2((w - sz.x) * 0.5, h * 0.32)
			draw_rect(Rect2(pos.x - 20, pos.y - sz.y, sz.x + 40, sz.y + 18), Color(0, 0, 0, 0.55))
			draw_string(f, pos, view.banner, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TK.TEXT)

	func _hud(w: float, ps: float) -> void:
		var f: Font = TK.disp(1)
		var bw: float = minf(w * 0.4, 360.0)
		var y: float = 6.0
		var items := [
			[8.0, String(view.spec.get("player", "Sen")), view.php, view.pst, false],
			[w - 8.0 - bw, String(view.spec.get("foe", "Rakip")), view.ohp, view.ost, true]]
		for it in items:
			var x: float = it[0]
			draw_string(f, Vector2(x, y + 20), String(it[1]), HORIZONTAL_ALIGNMENT_LEFT, bw, 20, TK.TEXT)
			draw_rect(Rect2(x, y + 28, bw, 14), Color(0, 0, 0, 0.6))
			var frac: float = clampf(float(it[2]) / 100.0, 0.0, 1.0)
			var col: Color = Color("5db86e") if frac > 0.5 else (Color("e3a92b") if frac > 0.25 else Color("ff7f6b"))
			var fw: float = bw * frac
			draw_rect(Rect2(x + (bw - fw if it[4] else 0.0), y + 28, fw, 14), col)
			draw_rect(Rect2(x, y + 28, bw, 14), Color(1, 1, 1, 0.25), false, 1.0)
			for s in 4:
				var on: bool = s < int(it[3])
				draw_rect(Rect2(x + (bw - 14.0 - s * 18.0 if it[4] else s * 18.0), y + 48, 14, 8), Color("73eff7") if on else Color(1, 1, 1, 0.15))

	func _fighter(x: float, y: float, ps: float, cloth: Color, accent: Color, mirror: bool, pose: int, hit: bool) -> void:
		var P = PS
		var rows: Array = BODY
		var cols: int = String(rows[0]).length()
		var bob: float = 0.0
		if pose == Pose.IDLE:
			bob = float(int(view.clock * 3.0) % 2) * ps * 0.5
		for r in rows.size():
			var row: String = rows[r]
			for c in cols:
				var ch: String = row[c]
				if ch == ".":
					continue
				var col: Color
				match ch:
					"X":
						col = cloth
					"Y":
						col = accent
					_:
						col = P.PAL.get(ch, Color.WHITE)
				if hit:
					col = col.lerp(Color("ff7f6b"), 0.6)
				var cc: int = (cols - 1 - c) if mirror else c
				draw_rect(Rect2(x + (cc - cols * 0.5) * ps, y + r * ps - bob, ps, ps), col)
		# kılıç
		var dirx: float = 1.0
		var diry: float = -1.0
		var ln: float = 8.0
		var hx: float = 7.0
		var hy: float = 6.0
		match pose:
			Pose.STRIKE:
				dirx = 1.0
				diry = -0.15
				ln = 11.0
			Pose.GUARD:
				dirx = 0.25
				diry = -1.0
				ln = 8.0
				hx = 8.0
			Pose.FEINT:
				dirx = 1.0
				diry = 0.35 + 0.25 * sin(view.t * 22.0)
				ln = 9.0
			Pose.HIT:
				dirx = 0.4
				diry = 1.0
				ln = 6.0
		var d := Vector2(dirx, diry).normalized()
		var n: int = int(ln * 2.0)
		for i in n + 1:
			var px: float = hx + d.x * float(i) * 0.5
			var py: float = hy + d.y * float(i) * 0.5
			var pxm: float = (cols - 1 - px) if mirror else px
			var col2: Color = Color("f4f4f4") if i >= n - 1 else (Color("94b0c2") if i > 1 else Color("ffcd75"))
			draw_rect(Rect2(x + (pxm - cols * 0.5) * ps, y + py * ps - bob, ps, ps), col2)
