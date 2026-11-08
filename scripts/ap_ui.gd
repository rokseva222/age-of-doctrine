extends RefCounted
## AOD Puanı arayüzü: mağaza sayfası ve «içerik kilitli» penceresi. Hepsi kodla çizilir (tema: theme_kit).

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const AP = preload("res://scripts/ap.gd")
const Provider = preload("res://scripts/ap_provider.gd")
const Scenarios = preload("res://scripts/scenarios.gd")
const Eras = preload("res://scripts/eras.gd")
const Loc = preload("res://scripts/loc.gd")


static func _say(toast: Callable, msg: String) -> void:
	if toast.is_valid():
		toast.call(msg)


static func _price(pid: String, fallback: String) -> String:
	var p := Provider.price_of(pid)
	return p if p != "" else fallback


static func _mmss(sec: int) -> String:
	return "%d:%02d" % [sec / 60, sec % 60]


## Bir satır: solda başlık + açıklama, sağda eylem düğmesi.
static func _row(box: Control, title: String, sub: String, btn_text: String, kind: String, enabled: bool, cb: Callable, loc_title := true) -> Button:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_theme_constant_override("separation", 0)
	tv.add_child(TK.t(title, "bodyb", TK.TEXT))
	if sub != "":
		var sl := TK.t(sub, "small", TK.MUTED)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(sl)
	hb.add_child(tv)
	var b := TK.button(btn_text, kind, "", Vector2(210, 60), 18)
	b.disabled = not enabled
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cb.is_valid():
		b.pressed.connect(cb)
	hb.add_child(b)
	box.add_child(hb)
	box.add_child(TK.hsep(0.5))
	return b


static func _section(box: Control, text: String) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 12)
	m.add_child(TK.t(text, "kicker", TK.FAINT))
	box.add_child(m)


# ------------------------------------------------------------------ mağaza

static func open(parent: Node, toast: Callable = Callable()) -> void:
	var sh = Sheet.open(parent, "Mağaza", 900, true, true, "AOD Puanı")
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	sh.body.add_child(box)
	var render := func(): pass
	render = func():
		for ch in box.get_children():
			box.remove_child(ch)
			ch.queue_free()
		_fill(box, render, toast)
	render.call()
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 170)


static func _fill(box: VBoxContainer, render: Callable, toast: Callable) -> void:
	# --- bakiye
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	head.add_child(TK.stat("Bakiye", "%d AP" % AP.balance(), TK.GOLD, true))
	var note := TK.t("AOD Puanı reklamdan, görevlerden, zaferlerden ve satın almadan kazanılır. Süresi dolmaz. Ordu, para ya da avantaj satmaz.", "small", TK.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(note)
	box.add_child(head)
	box.add_child(TK.hsep())

	# --- ücretsiz AP
	_section(box, "Ücretsiz AP")
	var claim := AP.login_claimable()
	_row(box, "Günlük ödül", (Loc.t("%d. ödül günü: +%d AP") % [AP.login_count() + 1, AP.login_next_reward()]) if claim else "Yarın tekrar gel. Kaçırdığın günler sayacı sıfırlamaz.",
		"Al" if claim else "Alındı", "gold" if claim else "", claim, func():
			var g := AP.claim_login()
			_say(toast, Loc.t("+%d AP") % g)
			render.call())
	var left := AP.ads_left()
	var wait := AP.ad_wait()
	var ready_ad := AP.ad_available()
	var ad_sub: String = Loc.t("Bugün kalan: %d/%d") % [left, AP.AD_DAILY_CAP]
	if not Provider.ads_ready():
		ad_sub = Loc.t("Reklam şu an yok.")
	elif left <= 0:
		ad_sub = Loc.t("Bugünlük reklam hakkın bitti. Yarın yenilenir.")
	elif wait > 0:
		ad_sub = (Loc.t("Sonraki reklam: %s") % _mmss(wait)) + "   /   " + ad_sub
	_row(box, Loc.t("Reklam izle  +%d AP") % AP.AD_REWARD, ad_sub, "Reklamı izle", "primary" if ready_ad else "", ready_ad, func():
		AP.watch_ad(false, func(ok: bool, gain: int, msg: String):
			_say(toast, (Loc.t("+%d AP") % gain) if ok else Loc.t(msg))
			render.call()))
	if AP.bonus_ad_ready() or not Provider.ads_ready():
		var bonus_ok := AP.bonus_ad_ready() and ready_ad
		_row(box, Loc.t("Günlük bonus reklamı  +%d AP") % AP.BONUS_AD_REWARD, "Günde bir kez. Bugünkü reklam hakkından sayılır.", "Bonusu al", "primary" if bonus_ok else "", bonus_ok, func():
			AP.watch_ad(true, func(ok: bool, gain: int, msg: String):
				_say(toast, (Loc.t("+%d AP") % gain) if ok else Loc.t(msg))
				render.call()))
	var tip := TK.t("Görevler, başarımlar ve ilk zaferler de AP verir.", "small", TK.FAINT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)

	# --- AP al
	_section(box, "AP al")
	if AP.starter_available():
		_row(box, Loc.t("Başlangıç teklifi  %d AP") % AP.STARTER.ap, "Tek seferlik. Süre baskısı yok, istediğin zaman alabilirsin.",
			_price("starter", AP.STARTER.usd), "gold", true, func(): _buy(AP.STARTER.id, render, toast))
	for pk in AP.PACKS:
		var pid: String = pk.id
		_row(box, "%d AP" % int(pk.ap), "", _price(pid, pk.usd), "", true, func(): _buy(pid, render, toast))

	# --- içerik
	_section(box, "İçerik")
	var full := AP.has_full()
	_row(box, "Tam Sürüm", "Tüm senaryolar ve tarihî çağlar, bugünkü ve gelecek ücretsiz içerik güncellemeleri. Tek seferlik.",
		"Alındı" if full else _price(AP.FULL.id, AP.FULL.usd), "" if full else "gold", not full, func(): _buy(AP.FULL.id, render, toast))
	var has_slots := AP.slot_bonus() > 0
	_row(box, Loc.t("Ek kayıt yuvası  +%d") % AP.EXTRA_SLOTS, "Elle kayıt yuvalarını 3'ten 5'e çıkarır. Kalıcı.",
		"Alındı" if has_slots else Loc.t("%d AP") % AP.PRICE_SLOTS, "", not has_slots, func():
			if AP.unlock_with_ap("slots", ""):
				_say(toast, Loc.t("Ek kayıt yuvaları açıldı."))
			else:
				_say(toast, Loc.t("Yetersiz AP."))
			render.call())
	if not full:
		for sc in Scenarios.all():
			var sid: String = sc["id"]
			if AP.scenario_unlocked(sid):
				continue
			_content_row(box, "scn", sid, sc["name"], sc["sub"], render, toast)
		for e in Eras.all():
			var eid: String = e["id"]
			if AP.era_unlocked(eid):
				continue
			_content_row(box, "era", eid, e["name"], e["sub"], render, toast)

	# --- alt işlemler
	box.add_child(TK.spacer(0, 6))
	var rb := TK.button("Satın alımları geri yükle", "ghost", "", Vector2(0, 56), 18)
	rb.pressed.connect(func():
		AP.restore(func(ok: bool, n: int, msg: String):
			if ok:
				_say(toast, (Loc.t("%d satın alma geri yüklendi.") % n) if n > 0 else Loc.t("Geri yüklenecek satın alma bulunamadı."))
			else:
				_say(toast, Loc.t(msg))
			render.call()))
	box.add_child(rb)
	if Provider.dev_mode():
		box.add_child(TK.hsep(0.5))
		var dv := TK.toggle_row("Geliştirici: tüm içeriği aç", AP.dev_all(), func(on: bool):
			AP.set_dev_all(on)
			render.call())
		box.add_child(dv)
		var dv2 := TK.button("Geliştirici: +500 AP", "ghost", "", Vector2(0, 52), 16)
		dv2.pressed.connect(func():
			AP.earn(500, "dev")
			render.call())
		box.add_child(dv2)
	var fine := TK.t("Fiyatlar Google Play'de yerel para biriminde gösterilir. AP süresiz geçerlidir, başka oyunlarda kullanılmaz.", "small", TK.FAINT)
	fine.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(fine)


static func _content_row(box: Control, kind: String, id: String, name: String, sub: String, render: Callable, toast: Callable) -> void:
	var price: int = AP.price_of_unlock(kind)
	var can := AP.can_afford(price)
	_row(box, name, sub, Loc.t("%d AP") % price, "primary" if can else "", can, func():
		if AP.unlock_with_ap(kind, id):
			_say(toast, Loc.t("Açıldı: %s") % Loc.t(name))
		render.call())


static func _buy(pid: String, render: Callable, toast: Callable) -> void:
	AP.purchase(pid, func(ok: bool, gain: int, msg: String):
		if ok:
			_say(toast, (Loc.t("+%d AP") % gain) if gain > 0 else Loc.t("Satın alma tamamlandı."))
		else:
			_say(toast, Loc.t(msg) if msg != "" else Loc.t("Satın alma tamamlanmadı."))
		render.call())


# ------------------------------------------------------------------ içerik kilitli penceresi

## kind: "scn" | "era". on_done: içerik açılınca çağrılır.
static func open_unlock(parent: Node, kind: String, id: String, name: String, toast: Callable = Callable(), on_done: Callable = Callable()) -> void:
	var sh = Sheet.open(parent, "İçerik kilitli", 680, false, true, name)
	var price: int = AP.price_of_unlock(kind)
	var t1 := TK.t("Bu içerik ücretsiz sürümde yok. AP ile ya da tek seferlik satın almayla açabilirsin.", "body", TK.MUTED)
	t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(t1)
	sh.body.add_child(TK.spacer(0, 6))
	var done := func():
		if on_done.is_valid():
			on_done.call()
		sh.close()
	var can := AP.can_afford(price)
	var b1: Button
	if can:
		b1 = TK.button(Loc.t("%d AP ile aç  (bakiye %d)") % [price, AP.balance()], "primary", "", Vector2(0, 66), 19)
		b1.pressed.connect(func():
			if AP.unlock_with_ap(kind, id):
				_say(toast, Loc.t("Açıldı: %s") % Loc.t(name))
				done.call())
	else:
		b1 = TK.button(Loc.t("%d AP gerekli  (bakiye %d)  /  Mağaza") % [price, AP.balance()], "", "", Vector2(0, 66), 18)
		b1.pressed.connect(func():
			sh.close()
			open(parent, toast))
	sh.body.add_child(b1)
	var pid: String = kind + "_" + id
	var usd: String = AP.USD_SCENARIO if kind == "scn" else AP.USD_ERA
	var b2 := TK.button(Loc.t("Yalnızca bunu aç  %s") % _price(pid, usd), "", "", Vector2(0, 66), 19)
	b2.pressed.connect(func():
		AP.purchase(pid, func(ok: bool, _g: int, msg: String):
			if ok:
				_say(toast, Loc.t("Açıldı: %s") % Loc.t(name))
				done.call()
			else:
				_say(toast, Loc.t(msg) if msg != "" else Loc.t("Satın alma tamamlanmadı."))))
	sh.body.add_child(b2)
	var b3 := TK.button(Loc.t("Tam Sürüm  %s  (hepsini aç)") % _price(AP.FULL.id, AP.FULL.usd), "gold", "", Vector2(0, 66), 19)
	b3.pressed.connect(func():
		AP.purchase(AP.FULL.id, func(ok: bool, _g: int, msg: String):
			if ok:
				_say(toast, Loc.t("Tam Sürüm açıldı."))
				done.call()
			else:
				_say(toast, Loc.t(msg) if msg != "" else Loc.t("Satın alma tamamlanmadı."))))
	sh.body.add_child(b3)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 170)
