extends RefCounted
## Çok oyunculu arayüzü: mod seçimi, oyuncu sayısı, "telefonu devret" perdesi.

const Icons = preload("res://scripts/icons.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Mp = preload("res://scripts/mp.gd")


## Çok Oyunculu: iki seçenek. on_multi: aynı telefonda sırayla; on_online: sunucu tarayıcısı.
static func open_mode(parent: Node, on_multi: Callable, on_online: Callable) -> void:
	var sh = Sheet.open(parent, "Çok Oyunculu", 700, false, true, "Mod seç")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	sh.body.add_child(box)
	box.add_child(_choice("Aynı Telefon", "Aynı telefon, sırayla. 2–6 kişi telefonu elden ele verir; masa oyunu gibi.", Icons.pick("mp_hotseat", "users"), func():
		sh.close()
		on_multi.call()))
	box.add_child(_choice("Online", "Sunucu listesi, kodla katılma, LAN. Herkes kendi telefonundan oynar.", Icons.pick("mp_online", "radio_tower"), func():
		sh.close()
		on_online.call()))
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 170)


static func _choice(title: String, desc: String, icon: String, cb: Callable) -> Control:
	var b := TK.button(title, "gold" if title == "Aynı Telefon" else "", icon, Vector2(0, 76), 22)
	b.pressed.connect(cb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(b)
	var d := TK.t(desc, "small", TK.MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return v


## Oyuncu sayısı: 2–6 düğmesi.
static func open_count(parent: Node, on_pick: Callable) -> void:
	var sh = Sheet.open(parent, "Oyuncu sayısı", 700, false, true, "Aynı telefon")
	sh.add_text("Kaç kişi oynayacak? Sırayla ülkelerinizi seçeceksiniz; her tur herkes kendi hamlesini yapıp telefonu devredecek.")
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	sh.body.add_child(row)
	for n in range(Mp.MIN_PLAYERS, Mp.MAX_PLAYERS + 1):
		var b := TK.button(str(n), "gold" if n == 2 else "", "", Vector2(96, 76), 24)
		b.pressed.connect(func():
			sh.close()
			on_pick.call(n))
		row.add_child(b)
	sh.add_button("Vazgeç", func(): pass, "ghost", true, "", 170)


## "Telefonu devret" perdesi: harita tamamen gizlenir; sıradaki oyuncu "Hazırım" der.
## Dönüş: perde düğümü (kapanınca ready_cb çağrılır).
static func pass_screen(parent: Node, gs, cid: int, ready_cb: Callable) -> Control:
	var cov := Control.new()
	cov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cov.mouse_filter = Control.MOUSE_FILTER_STOP
	cov.z_index = 4000
	cov.name = "MpPass"
	parent.add_child(cov)
	var bg := ColorRect.new()
	bg.color = TK.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cov.add_child(bg)
	var cen := CenterContainer.new()
	cen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cov.add_child(cen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(620, 0)
	cen.add_child(v)
	var c = gs.countries[cid]
	var seat: int = gs.humans.find(cid) + 1
	var kick := TK.t("Telefonu devret", "kicker")
	kick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(kick)
	var fr := TK.flag_rect(c, Vector2(176, 118))
	var fc := CenterContainer.new()
	fc.add_child(fr)
	v.add_child(fc)
	var nm := TK.t(c.name, "h1", TK.TEXT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var sub := TK.t(Loc.t("Oyuncu %d / %d  ·  %s") % [seat, gs.humans.size(), Names_date(gs)], "small", TK.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var warn := TK.t("Telefonu bu oyuncuya ver. Diğerleri ekrana bakmasın.", "small", TK.FAINT)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(warn)
	v.add_child(TK.spacer(0, 10))
	var go := TK.button("Hazırım", "gold", "play", Vector2(0, 80), 24)
	go.pressed.connect(func():
		cov.queue_free()
		ready_cb.call())
	v.add_child(go)
	cov.set_meta("go", go)
	return cov


static func Names_date(gs) -> String:
	var N = load("res://scripts/names.gd")
	return N.date_string(gs.turn)
