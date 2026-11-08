extends RefCounted
## Ayarlar ve "Nasıl oynanır" pencereleri (menüde ve oyun içinde ortak).

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Settings = preload("res://scripts/settings.gd")
const Loc = preload("res://scripts/loc.gd")


static func _section(sh, text: String) -> void:
	sh.body.add_child(TK.spacer(0, 6))
	sh.body.add_child(TK.t(text, "kicker", TK.PAPER_DIM))
	sh.body.add_child(TK.hsep())


## Çeviri emeği: dil kodu -> isimler (kişi adları çevrilmez)
const TRANSLATORS := [
	["en", ["Ali Solmaz", "Selengül Öztürk", "Enes Koçak"]],
	["ar", ["Aykut Karaman"]],
	["fa", ["Aykut Karaman"]],
	["ja", ["Utku Berk Nergiz", "Sato Takuya", "Nakamura Yuta"]],
	["de", ["Hayrunnisa Nur Varilci", "Arthur Dorohov"]],
	["ru", ["Seva Hovanneski", "Dmitriy Petrov", "Aleksandr Vladimirov"]],
	["fr", ["Thomas Martin", "Lucas Dubois"]],
	["hi", ["Lahar Shurma", "Rohit Shingh"]],
	["es", ["Alejandro Gracia"]],
	["it", ["Mattia Romano", "Lorenzo Esposita"]],
	["ko", ["Jung Ha-joon", "Kim Jin-woo"]],
	["pt", ["Afonso Costa", "Martim Ferreira"]],
	["zh", ["Chen Yu Qiang", "Wang Wei", "Huang Lei"]],
]


static func open_credits(parent: Node) -> void:
	var sh = Sheet.open(parent, "Emeği Geçenler", 700, true, true, "Rok Games Studios")
	_section(sh, "Yapım")
	sh.body.add_child(TK.t("Age of Doctrine", "h3", TK.GOLD))
	sh.body.add_child(TK.t("Rok Games Studios", "body", TK.TEXT))
	_section(sh, "Kaynaklar")
	for ln in ["Harita: Natural Earth (kamu malı)", "Yazı tipleri: Big Shoulders, Instrument Sans, IBM Plex Mono (SIL Open Font License)"]:
		var src := TK.t(ln, "small", TK.MUTED)
		src.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(src)
	_section(sh, "Çeviriler")
	var thanks := TK.t("Çeviriye emek verenlere teşekkürler.", "small", TK.MUTED)
	thanks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(thanks)
	for row in TRANSLATORS:
		var code: String = row[0]
		var lname: String = Loc.native_name(code)
		var names: Array = row[1]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var a := TK.t(lname, "caps", TK.GOLD)
		a.custom_minimum_size = Vector2(190, 0)
		a.autowrap_mode = TextServer.AUTOWRAP_OFF
		hb.add_child(a)
		var b := TK.t(", ".join(names), "body", TK.TEXT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(b)
		sh.body.add_child(hb)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


static func open_settings(parent: Node, on_change: Callable, sfx = null) -> void:
	var sh = Sheet.open(parent, "Ayarlar", 700, true, true, "Tercihler")
	var changed := func():
		Settings.save_all()
		on_change.call()
	_section(sh, "Ses")
	sh.body.add_child(TK.slider_row("Müzik", Settings.music, func(v: float):
		Settings.music = v
		changed.call()))
	sh.body.add_child(TK.slider_row("Ses efektleri", Settings.sfx, func(v: float):
		Settings.sfx = v
		changed.call()
		if sfx != null:
			sfx.play("coin")))
	_section(sh, "Dil")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for l in Loc.available():
		var lb: Button = TK.button(l[1], "primary" if l[0] == Settings.language else "", "", Vector2(0, 56), 18)
		lb.text = l[1]
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var code: String = l[0]
		lb.pressed.connect(func():
			if code == Settings.language:
				return
			Settings.language = code
			Loc.apply(code)
			Settings.save_all()
			var scn = parent.get_tree().current_scene
			if scn != null and scn.has_method("reload_for_language"):
				scn.reload_for_language()
				return
			on_change.call()
			sh.close()
			open_settings(parent, on_change, sfx))
		grid.add_child(lb)
	sh.body.add_child(grid)
	_section(sh, "Görünüm")
	sh.body.add_child(TK.toggle_row("Ülke adları", Settings.country_names, func(on: bool):
		Settings.country_names = on
		changed.call(), "Ülkenin boyuna göre ölçeklenir; yakınlaştıkça belirir."))
	sh.body.add_child(TK.toggle_row("Eyalet adları", Settings.province_names, func(on: bool):
		Settings.province_names = on
		changed.call(), "Yakınlaştırınca eyalet isimlerini gösterir."))
	sh.body.add_child(TK.toggle_row("Ordu rozetleri", Settings.armies, func(on: bool):
		Settings.armies = on
		changed.call()))
	sh.body.add_child(TK.toggle_row("Yüksek kalite efektler", Settings.smooth, func(on: bool):
		Settings.smooth = on
		changed.call(), "Kıyı parıltısı. Eski telefonlarda kapatmak akıcılığı artırır."))
	sh.body.add_child(TK.slider_row("Arayüz boyutu", Settings.ui_scale, func(v: float):
		Settings.ui_scale = v
		changed.call(), 0.6, 1.4, 0.05))
	_section(sh, "Oyun")
	sh.body.add_child(TK.toggle_row("Otomatik kayıt", Settings.autosave, func(on: bool):
		Settings.autosave = on
		changed.call(), "Her 13 haftada (üç ayda) bir kaydeder."))
	sh.body.add_child(TK.toggle_row("Kabine kartları", Settings.cabinet, func(on: bool):
		Settings.cabinet = on
		changed.call(), "Bakanlar arada bir karar sorar (savunma, dışişleri, içişleri, maliye, sağlık, istihbarat). Bazı riskli seçimler oyunu bitirebilir."))
	sh.body.add_child(TK.toggle_row("Otomatik asker atama", Settings.auto_orders, func(on: bool):
		Settings.auto_orders = on
		changed.call(), "Bir turda hiç emir vermezsen, savaştaki boş ordular en uygun cephe hedeflerine kendiliğinden yönlendirilir. Kapalıyken ordular sen söyleyene dek yerinde bekler."))
	sh.body.add_child(TK.toggle_row("Bildirimler", Settings.notifications, func(on: bool):
		Settings.notifications = on
		changed.call(), "Telefonda, devam eden bir oyun varken 5 saatte bir \"ordun seni bekliyor\" hatırlatması gönderir. Oyun yoksa ya da bittiyse bildirim gelmez."))
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	var dl := TK.t("Zorluk", "body")
	dl.custom_minimum_size = Vector2(220, 0)
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drow.add_child(dl)
	var btns: Array = []
	var names := ["Kolay", "Normal", "Zor"]
	for i in 3:
		var b := TK.button(names[i], "", "", Vector2(0, 60), 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btns.append(b)
		drow.add_child(b)
	var refresh := func():
		for i in 3:
			TK.style_button(btns[i], "gold" if Settings.difficulty == i else "ghost")
	for i in 3:
		var idx := i
		btns[i].pressed.connect(func():
			Settings.difficulty = idx
			refresh.call()
			changed.call())
	refresh.call()
	sh.body.add_child(drow)
	sh.body.add_child(TK.t("Zorluk yeni başlayan oyunlarda geçerlidir.", "small", TK.FAINT))
	sh.add_button("Emeği Geçenler", func(): open_credits(parent), "ghost", true, "", 220)
	sh.add_button("Tamam", func(): pass, "gold", true, "check", 180)


const PAGES := [
	{"icon": "map", "title": "Eyalet eyalet fetih", "text": "Harita gerçek dünyadır. Her ülke birkaç eyaletten oluşur. Bir eyalete dokun; bilgisini ve yapabileceklerini gör. İki parmakla yakınlaştır, sürükleyerek gez."},
	{"icon": "swords", "title": "Asker topla", "text": "Kendi eyaletinde 'Asker +10' ya da '+30' ile ordu kur. Gelirin eyaletlerden gelir; ordunun bakım gideri vardır, altının eksiye düşmesin."},
	{"icon": "flag", "title": "Tur tabanlı oyun", "text": "Zaman kendiliğinden akmaz. Hazır olunca sağ üstteki 'Turu geç' düğmesine bas: bir hafta geçer, ardından Cihan Bülteni dünyada olanları ve harp raporunu gösterir."},
	{"icon": "swords", "title": "Taarruz harekâtı", "text": "Savaştığın bir ülkenin eyaletine dokun, 'Taarruz' de. Yakındaki ordularını seç, harekât türünü belirle (kara taarruzu, topçu ve hava hazırlığı, siber harp, yıldırım), tahmini üstünlüğü gör ve emri ver. Sonucu Turu geç sonrası raporda görürsün."},
	{"icon": "recruit", "title": "Asker gönderme ve paralı asker", "text": "Ordu seçip hedefe dokununca kaç askerin yola çıkacağını kaydırıcıyla (%25 / %50 / %75 / %100) seçersin; kalanlar yerinde bekler. Taarruzda da aynı oran vardır. Politika > Cepheler'den süreli paralı birlik kiralayabilirsin. Bir turda emir vermezsen savaştaki boş ordular otomatik görev alabilir (Ayarlar'dan kapatılır)."},
	{"icon": "handshake", "title": "Savaş, barış, ittifak", "text": "Kuşatma ve zaferler savaş puanı kazandırır. Barış masasında puanınla eyalet alırsın. Müttefikler birlikte savaşır; ateşkes süresince saldıramazsın."},
	{"icon": "users", "title": "Kabine kartları", "text": "Zaman zaman bir bakan karşına çıkıp karar sorar. Seçeneklerin yanındaki simgeler hangi alanı etkileyeceğini gösterir (yönü gizlidir); ☠ işareti oyunu bitirebilecek riskli bir seçimdir. Bir bakan görevden ayrılınca (istifa, skandal, seçim) 3 aday gelir: ucuz-acemi, orta-kıdemli, pahalı-usta; sen seçersin. Kabine sekmesinden bakanı değiştirebilirsin. Ayrıca nişe kartlar çıkar: seçim gecesi, şüpheli tüccarın kasası (kumar), Dünya Kupası/Olimpiyat, muhbir. Ayarlardan kapatılabilir."},
	{"icon": "news", "title": "Haberler ve zafer", "text": "Üstteki Cihan Bülteni dünyada olan biteni haber yapar; dokunarak geçmişi aç. Dünyadaki eyaletlerin %55'ini ele geçiren ülke cihan hâkimi olur."},
]


static func open_howto(parent: Node) -> void:
	var sh = Sheet.open(parent, "Nasıl oynanır", 700, false, true, "Rehber")
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 12)
	holder.custom_minimum_size = Vector2(0, 300)
	sh.body.add_child(holder)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_BEGIN
	dots.add_theme_constant_override("separation", 6)
	sh.body.add_child(dots)
	var state := {"i": 0}
	var render := func():
		for ch in holder.get_children():
			ch.queue_free()
		for ch in dots.get_children():
			ch.queue_free()
		var pg: Dictionary = PAGES[state.i]
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 18)
		var ib := PanelContainer.new()
		ib.custom_minimum_size = Vector2(92, 92)
		ib.add_theme_stylebox_override("panel", TK.box(TK.PAPER, Color(0, 0, 0, 0), 3, 0, 0, Vector4(0, 0, 0, 0)))
		var iv := TK.IconView.new()
		iv.icon = pg.icon
		iv.color = TK.INK
		iv.stroke = 2.0
		iv.custom_minimum_size = Vector2(52, 52)
		iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ib.add_child(iv)
		top.add_child(ib)
		var tvv := VBoxContainer.new()
		tvv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tvv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tvv.add_theme_constant_override("separation", -4)
		tvv.add_child(TK.t("Adım %d / %d" % [state.i + 1, PAGES.size()], "kicker"))
		var tl := TK.t(pg.title, "h3", TK.TEXT)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tvv.add_child(tl)
		top.add_child(tvv)
		holder.add_child(top)
		var tx := TK.t(pg.text, "body", TK.TEXT)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.size_flags_vertical = Control.SIZE_EXPAND_FILL
		holder.add_child(tx)
		for k in PAGES.size():
			var d := ColorRect.new()
			d.custom_minimum_size = Vector2(36 if k == state.i else 14, 6)
			d.color = TK.PAPER if k == state.i else TK.PANEL_HI
			dots.add_child(d)
	render.call()
	var prev := TK.button("Geri", "ghost", "chev_l", Vector2(160, 60))
	var nxt := TK.button("İleri", "gold", "chev_r", Vector2(190, 60))
	sh.footer.add_child(prev)
	sh.footer.add_child(nxt)
	prev.pressed.connect(func():
		state.i = maxi(state.i - 1, 0)
		render.call())
	nxt.pressed.connect(func():
		if state.i >= PAGES.size() - 1:
			Settings.seen_howto = true
			Settings.save_all()
			sh.close()
		else:
			state.i += 1
			nxt.text = TK.up("Başla" if state.i >= PAGES.size() - 1 else "İleri")
			render.call())
