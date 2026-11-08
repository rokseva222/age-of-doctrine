extends RefCounted
## Oyun içi senaryo oluşturucu. Menüden açılır; sonuç user://scenarios/u_*.json olarak kaydedilir.
## Bölümler: ad, oyuncu ülke, savaşlar, ittifaklar, ülke ayarları, hedefler, süre, giriş metni; paylaşım kodu.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const U = preload("res://scripts/user_scn.gd")

const PAIR_KINDS := [["wars", "Savaşlar", "saldırgan", "hedef"], ["embargo", "Ambargolar", "uygulayan", "uygulanan"], ["cold", "Gerginlikler", "taraf", "taraf"]]
const OBJ_LABELS := {
	"survive": "Hayatta kal (hafta)", "no_war": "Savaşsız kal (hafta)", "own_provinces": "Eyalet sayısı", "alliances": "Müttefik sayısı",
	"stability": "İstikrar eşiği", "bloc_members": "Blok üye sayısı", "cease_war": "Barış yap (ülke)", "eliminate": "Yok et (ülke)", "gdp_share": "GSYH payı (%)",
}

var root: Node
var on_done: Callable
var d := {}          # düzenlenen senaryo (yayın biçiminde)
var _sheet
var _sections := {}   # ad -> VBoxContainer
var _name_edit: LineEdit
var _sub_edit: LineEdit
var _intro_edit: LineEdit
var _dl_spin: SpinBox
var _msg: Label


## existing: düzenlenecek kullanıcı senaryosu ({} = yeni)
static func open(parent: Node, existing: Dictionary, done_cb: Callable) -> void:
	var e = load("res://scripts/scenario_editor.gd").new()
	e.root = parent
	e.on_done = done_cb
	e._start(existing)


func _start(existing: Dictionary) -> void:
	if existing.is_empty():
		d = {"id": U.new_id(), "kind": "user", "name": "", "sub": "", "intro": "", "suggest": ["Turkey"], "wars": [], "embargo": [], "cold": [], "blocs": [],
			"troops_mult": {}, "treasury_mult": {}, "stability": {}, "objectives": {"*": [{"id": "o0", "type": "survive", "turns": 104, "text": ""}]}, "deadline": 0}
	else:
		d = existing.duplicate(true)
		for k in ["wars", "embargo", "cold", "blocs"]:
			if not d.has(k):
				d[k] = []
		for k in ["troops_mult", "treasury_mult", "stability"]:
			if not d.has(k):
				d[k] = {}
		if not d.has("objectives") or not d["objectives"].has("*"):
			d["objectives"] = {"*": []}
	_build()


# ------------------------------------------------------------------ yardımcılar

func _country_picker(selected: String = "") -> OptionButton:
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(0, 52)
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.fit_to_longest_item = false
	var sel := 0
	var i := 0
	for c in U.countries():
		ob.add_item(c["tr"] if Loc.lang == "tr" else c["en"])
		ob.set_item_metadata(i, c["en"])
		if c["en"] == selected:
			sel = i
		i += 1
	ob.select(sel)
	return ob


func _val(ob: OptionButton) -> String:
	return String(ob.get_item_metadata(ob.selected))


func _head(text: String) -> Label:
	var l := TK.t(text, "caps", TK.GOLD)
	return l


func _small_btn(text: String, cb: Callable, kind: String = "") -> Button:
	var b := TK.button(text, kind, "", Vector2(0, 52), 17)
	b.pressed.connect(cb)
	return b


func _section(name: String, title: String, fill: Callable) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_sheet.body.add_child(_head(title))
	_sheet.body.add_child(box)
	_sheet.body.add_child(HSeparator.new())
	_sections[name] = box
	fill.call()


func _refill(name: String, fill: Callable) -> void:
	var box: VBoxContainer = _sections[name]
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	fill.call()


func _row_label(text: String, on_remove: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var l := TK.t(text, "body", TK.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(l)
	var x := TK.button("Sil", "danger", "", Vector2(90, 48), 16)
	x.pressed.connect(on_remove)
	hb.add_child(x)
	return hb


# ------------------------------------------------------------------ ana pencere

func _build() -> void:
	_sheet = Sheet.open(root, "Senaryo oluştur", 900, true, true, "Kendi senaryon")
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = Loc.t("Senaryo adı")
	_name_edit.max_length = 40
	_name_edit.text = String(d.get("name", ""))
	_name_edit.custom_minimum_size = Vector2(0, 56)
	_sheet.body.add_child(_name_edit)
	_sub_edit = LineEdit.new()
	_sub_edit.placeholder_text = Loc.t("Alt başlık (isteğe bağlı)")
	_sub_edit.max_length = 60
	_sub_edit.text = String(d.get("sub", ""))
	_sub_edit.custom_minimum_size = Vector2(0, 56)
	_sheet.body.add_child(_sub_edit)
	_intro_edit = LineEdit.new()
	_intro_edit.placeholder_text = Loc.t("Oyun başında okunacak haber cümlesi")
	_intro_edit.max_length = 200
	_intro_edit.text = String(d.get("intro", ""))
	_intro_edit.custom_minimum_size = Vector2(0, 56)
	_sheet.body.add_child(_intro_edit)
	_sheet.body.add_child(HSeparator.new())
	_section("player", "Oyuncu ülkesi", _fill_player)
	for pk in PAIR_KINDS:
		var key: String = pk[0]
		_section(key, pk[1], func(): _fill_pairs(key))
	_section("blocs", "İttifaklar (bloklar)", _fill_blocs)
	_section("mods", "Ülke ayarları", _fill_mods)
	_section("objs", "Hedefler", _fill_objs)
	var dlb := HBoxContainer.new()
	dlb.add_theme_constant_override("separation", 10)
	var dll := TK.t("Süre sınırı (hafta, 0 = yok)", "body", TK.TEXT)
	dll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlb.add_child(dll)
	_dl_spin = SpinBox.new()
	_dl_spin.min_value = 0
	_dl_spin.max_value = 1000
	_dl_spin.step = 4
	_dl_spin.value = int(d.get("deadline", 0))
	_dl_spin.custom_minimum_size = Vector2(160, 52)
	dlb.add_child(_dl_spin)
	_sheet.body.add_child(dlb)
	_msg = TK.t("", "small", TK.RED_TEXT)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet.body.add_child(_msg)
	_sheet.add_button("Kaydet", _save, "gold", false, "save", 150)
	_sheet.add_button("Paylaşım kodu", _show_code, "", false, "", 170)
	_sheet.add_button("Koddan içe aktar", _import_dialog, "", false, "", 190)
	if U.list_ids().has(String(d.get("id", ""))):
		_sheet.add_button("Sil", func():
			U.remove(String(d["id"]))
			_sheet.close()
			on_done.call(""), "danger", false, "", 110)
	_sheet.add_button("Kapat", func(): _sheet.close(), "", false, "", 130)


# ------------------------------------------------------------------ bölümler

func _fill_player() -> void:
	var box: VBoxContainer = _sections["player"]
	var pick := _country_picker(String(d["suggest"][0]))
	pick.item_selected.connect(func(_i):
		d["suggest"][0] = _val(pick))
	box.add_child(pick)
	box.add_child(TK.t("Menüde varsayılan olarak seçili gelir; oyuncu başka ülkeyi de seçebilir.", "small", TK.MUTED))


func _fill_pairs(key: String) -> void:
	var box: VBoxContainer = _sections[key]
	var meta: Array = []
	for pk in PAIR_KINDS:
		if pk[0] == key:
			meta = pk
	for i in d[key].size():
		var p: Array = d[key][i]
		var idx: int = i
		box.add_child(_row_label("%s  →  %s" % [U.country_label(p[0]), U.country_label(p[1])], func():
			d[key].remove_at(idx)
			_refill(key, func(): _fill_pairs(key))))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var a := _country_picker("Turkey")
	var b := _country_picker("Greece")
	hb.add_child(a)
	hb.add_child(b)
	hb.add_child(_small_btn("Ekle", func():
		if _val(a) == _val(b):
			_msg.text = Loc.t("İki taraf aynı ülke olamaz.")
			return
		for p in d[key]:
			if p[0] == _val(a) and p[1] == _val(b):
				return
		if d[key].size() >= U.MAX_ITEMS:
			return
		_msg.text = ""
		d[key].append([_val(a), _val(b)])
		_refill(key, func(): _fill_pairs(key)), "good"))
	box.add_child(hb)


func _fill_blocs() -> void:
	var box: VBoxContainer = _sections["blocs"]
	for i in d["blocs"].size():
		var b: Dictionary = d["blocs"][i]
		var idx: int = i
		var names: Array = []
		for m in b["members"]:
			names.append(U.country_label(m))
		box.add_child(_row_label("%s: %s" % [b["name"], ", ".join(names)], func():
			d["blocs"].remove_at(idx)
			_refill("blocs", _fill_blocs)))
	if d["blocs"].size() >= 4:
		return
	var nm := LineEdit.new()
	nm.placeholder_text = Loc.t("İttifak adı")
	nm.max_length = 40
	nm.custom_minimum_size = Vector2(0, 52)
	box.add_child(nm)
	var members: Array = []
	var chips := TK.t("", "small", TK.MUTED)
	chips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var pick := _country_picker("Turkey")
	hb.add_child(pick)
	hb.add_child(_small_btn("Üye ekle", func():
		var v := _val(pick)
		if not members.has(v) and members.size() < 40:
			members.append(v)
		var ns: Array = []
		for m in members:
			ns.append(U.country_label(m))
		chips.text = ", ".join(ns)))
	box.add_child(hb)
	box.add_child(chips)
	box.add_child(_small_btn("İttifakı oluştur", func():
		if nm.text.strip_edges() == "" or members.size() < 2:
			_msg.text = Loc.t("İttifak için bir ad ve en az 2 üye gerekir.")
			return
		_msg.text = ""
		d["blocs"].append({"name": nm.text.strip_edges(), "members": members.duplicate()})
		_refill("blocs", _fill_blocs), "good"))


func _fill_mods() -> void:
	var box: VBoxContainer = _sections["mods"]
	var keys := {}
	for k in ["troops_mult", "treasury_mult", "stability"]:
		for c in d[k].keys():
			keys[c] = true
	for c in keys.keys():
		var parts: Array = []
		if d["troops_mult"].has(c):
			parts.append(Loc.t("Ordu") + " ×%.1f" % float(d["troops_mult"][c]))
		if d["treasury_mult"].has(c):
			parts.append(Loc.t("Kasa") + " ×%.1f" % float(d["treasury_mult"][c]))
		if d["stability"].has(c):
			parts.append(Loc.t("İstikrar") + " %+d" % int(d["stability"][c]))
		var cc: String = c
		box.add_child(_row_label("%s: %s" % [U.country_label(cc), ", ".join(parts)], func():
			for k in ["troops_mult", "treasury_mult", "stability"]:
				d[k].erase(cc)
			_refill("mods", _fill_mods)))
	var pick := _country_picker("Turkey")
	box.add_child(pick)
	var sl := {}
	for spec in [["troops", "Ordu çarpanı", 0.5, 2.0, 0.1, 1.0], ["treasury", "Kasa çarpanı", 0.3, 3.0, 0.1, 1.0], ["stab", "İstikrar farkı", -40.0, 20.0, 1.0, 0.0]]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var l := TK.t(spec[1], "small", TK.TEXT)
		l.custom_minimum_size = Vector2(190, 0)
		hb.add_child(l)
		var s := HSlider.new()
		s.min_value = spec[2]
		s.max_value = spec[3]
		s.step = spec[4]
		s.value = spec[5]
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.custom_minimum_size = Vector2(0, 44)
		hb.add_child(s)
		var vl := TK.t("%.1f" % spec[5], "small", TK.MUTED)
		vl.custom_minimum_size = Vector2(60, 0)
		s.value_changed.connect(func(v): vl.text = ("%.1f" % v) if spec[0] != "stab" else ("%+d" % int(v)))
		hb.add_child(vl)
		box.add_child(hb)
		sl[spec[0]] = s
	box.add_child(_small_btn("Ayarı uygula", func():
		var c := _val(pick)
		var t: float = sl["troops"].value
		var g: float = sl["treasury"].value
		var s2: float = sl["stab"].value
		if absf(t - 1.0) > 0.01:
			d["troops_mult"][c] = t
		else:
			d["troops_mult"].erase(c)
		if absf(g - 1.0) > 0.01:
			d["treasury_mult"][c] = g
		else:
			d["treasury_mult"].erase(c)
		if absf(s2) > 0.01:
			d["stability"][c] = s2
		else:
			d["stability"].erase(c)
		_refill("mods", _fill_mods), "good"))


func _fill_objs() -> void:
	var box: VBoxContainer = _sections["objs"]
	var arr: Array = d["objectives"]["*"]
	for i in arr.size():
		var o: Dictionary = arr[i]
		var idx: int = i
		var txt: String = U.describe(o, Loc.lang)
		if not bool(o.get("required", true)):
			txt += " (" + Loc.t("isteğe bağlı") + ")"
		box.add_child(_row_label(txt, func():
			arr.remove_at(idx)
			_refill("objs", _fill_objs)))
	if arr.size() >= 8:
		return
	var tp := OptionButton.new()
	tp.custom_minimum_size = Vector2(0, 52)
	for t in U.OBJ_TYPES:
		tp.add_item(Loc.t(OBJ_LABELS[t]))
	box.add_child(tp)
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = 400
	spin.value = 52
	spin.custom_minimum_size = Vector2(160, 52)
	var pick := _country_picker("Turkey")
	pick.visible = false
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(spin)
	hb.add_child(pick)
	var opt := CheckBox.new()
	opt.text = Loc.t("İsteğe bağlı")
	hb.add_child(opt)
	box.add_child(hb)
	tp.item_selected.connect(func(i):
		var t: String = U.OBJ_TYPES[i]
		var needs_country: bool = t in ["cease_war", "eliminate"]
		pick.visible = needs_country
		spin.visible = not needs_country)
	box.add_child(_small_btn("Hedef ekle", func():
		var t: String = U.OBJ_TYPES[tp.selected]
		var o := {"id": "o%d" % arr.size(), "type": t, "text": ""}
		var used := {}
		for x in arr:
			used[x["id"]] = true
		var n := 0
		while used.has("o%d" % n):
			n += 1
		o["id"] = "o%d" % n
		if t == "cease_war":
			o["with"] = _val(pick)
		elif t == "eliminate":
			o["country"] = _val(pick)
		elif t in ["survive", "no_war"]:
			o["turns"] = int(spin.value)
		elif t == "gdp_share":
			o["pct"] = float(spin.value)
		else:
			o["n"] = int(spin.value)
		if opt.button_pressed:
			o["required"] = false
		o["text"] = U.describe(o, "tr")
		arr.append(o)
		_refill("objs", _fill_objs), "good"))


# ------------------------------------------------------------------ kaydet / paylaş

func _collect() -> Dictionary:
	d["name"] = _name_edit.text.strip_edges()
	d["sub"] = _sub_edit.text.strip_edges()
	d["intro"] = _intro_edit.text.strip_edges()
	d["deadline"] = int(_dl_spin.value)
	if d["deadline"] <= 0:
		d.erase("deadline")
	d["blurb"] = String(d.get("blurb", ""))
	if d["blurb"] == "":
		d["blurb"] = Loc.t("Senin hazırladığın senaryo.")
	if d["intro"] == "":
		d["intro"] = d["name"]
	for k in ["wars", "embargo", "cold", "blocs"]:
		if d[k].is_empty():
			d.erase(k)
	for k in ["troops_mult", "treasury_mult", "stability"]:
		if d.has(k) and d[k].is_empty():
			d.erase(k)
	var objs: Array = d["objectives"]["*"]
	for o in objs:
		o["text"] = U.describe(o, "tr")
	if objs.is_empty():
		d.erase("objectives")
	return U.finalize(d)


func _save() -> void:
	if _name_edit.text.strip_edges() == "":
		_msg.text = Loc.t("Önce senaryoya bir ad ver.")
		return
	var out := _collect()
	if not U.save(out):
		_msg.text = Loc.t("Senaryo kaydedilemedi.")
		return
	_sheet.close()
	on_done.call(String(out["id"]))


func _show_code() -> void:
	if _name_edit.text.strip_edges() == "":
		_msg.text = Loc.t("Önce senaryoya bir ad ver.")
		return
	var out := _collect()
	var code := U.export_code(out)
	var sh = Sheet.open(root, "Paylaşım kodu", 760, false, true, "Senaryo")
	sh.add_text("Bu kodu arkadaşına gönder; o da \"Koddan içe aktar\" ile senaryonu kendi oyununa ekler.")
	var te := TextEdit.new()
	te.text = code
	te.editable = false
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.custom_minimum_size = Vector2(0, 160)
	sh.body.add_child(te)
	sh.add_button("Panoya kopyala", func():
		DisplayServer.clipboard_set(code), "gold", false)
	sh.add_button("Kapat", func(): pass, "", true)


func _import_dialog() -> void:
	var sh = Sheet.open(root, "Koddan içe aktar", 760, false, true, "Senaryo")
	sh.add_text("Paylaşım kodunu aşağıya yapıştır.")
	var te := TextEdit.new()
	te.placeholder_text = "AOD1...."
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.custom_minimum_size = Vector2(0, 160)
	sh.body.add_child(te)
	var res := TK.t("", "small", TK.RED_TEXT)
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(res)
	sh.add_button("Yapıştır", func():
		te.text = DisplayServer.clipboard_get(), "", false)
	sh.add_button("İçe aktar", func():
		var imp := U.import_code(te.text)
		if imp.is_empty():
			res.text = Loc.t("Kod geçersiz ya da bozuk.")
			return
		if String(imp.get("blurb", "")) == "":
			imp["blurb"] = Loc.t("Senin hazırladığın senaryo.")
		var fin := U.finalize(imp)
		if U.save(fin):
			sh.close()
			_sheet.close()
			on_done.call(String(fin["id"])), "gold", false)
	sh.add_button("Kapat", func(): pass, "", true)
