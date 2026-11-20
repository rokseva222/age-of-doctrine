extends RefCounted
## Oyun içi senaryo oluşturucu. Menüden açılır; sonuç user://scenarios/u_*.json olarak kaydedilir.
## Bölümler: ad, oyuncu ülke, savaşlar, ittifaklar, ülke ayarları, hedefler, süre, giriş metni; paylaşım kodu.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const U = preload("res://scripts/user_scn.gd")
const WorldData = preload("res://scripts/world_data.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const FlagEditor = preload("res://scripts/flag_editor.gd")
const Macro = preload("res://scripts/macro.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Eras = preload("res://scripts/eras.gd")
const AP = preload("res://scripts/ap.gd")

const PAIR_KINDS := [["wars", "Savaşlar", "saldırgan", "hedef"], ["embargo", "Ambargolar", "uygulayan", "uygulanan"], ["cold", "Gerginlikler", "taraf", "taraf"]]
const OBJ_LABELS := {
	"survive": "Hayatta kal (hafta)", "no_war": "Savaşsız kal (hafta)", "own_provinces": "Eyalet sayısı", "alliances": "Müttefik sayısı",
	"stability": "İstikrar eşiği", "bloc_members": "Blok üye sayısı", "cease_war": "Barış yap (ülke)", "eliminate": "Yok et (ülke)", "gdp_share": "GSYH payı (%)",
}

var root: Node
var _year_spin: SpinBox
var _prov_idx: Array = []
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
		d = {"id": U.new_id(), "kind": "user", "name": "", "sub": "", "intro": "", "events": [], "suggest": ["Turkey"], "wars": [], "embargo": [], "cold": [], "blocs": [],
			"troops_mult": {}, "treasury_mult": {}, "stability": {}, "objectives": {"*": [{"id": "o0", "type": "survive", "turns": 104, "text": ""}]}, "deadline": 0}
	else:
		d = existing.duplicate(true)
		for k in ["wars", "embargo", "cold", "blocs"]:
			if not d.has(k):
				d[k] = []
		for k in ["troops_mult", "treasury_mult", "stability"]:
			if not d.has(k):
				d[k] = {}
		if not d.has("events"):
			d["events"] = []
		if not d.has("objectives") or not d["objectives"].has("*"):
			d["objectives"] = {"*": []}
	_build()


## Çağ değişince düzenleyici yeni ülke listesiyle yeniden kurulur (girilen metinler korunur)
func _set_era(id: String) -> void:
	if id == String(d.get("era", "")):
		return
	d["name"] = _name_edit.text.strip_edges()
	d["sub"] = _sub_edit.text.strip_edges()
	d["intro"] = _intro_edit.text.strip_edges()
	d["deadline"] = int(_dl_spin.value)
	if id == "":
		d.erase("era")
	else:
		d["era"] = id
		d.erase("year")
	# o çağda olmayan (başka devlete katılmış) ülkeler bu çağın listesinde yoktur; eski devirler/birlikler çağa uymayabilir
	d["transfer"] = []
	d["garrison"] = []
	_prov_idx = []
	_sheet.close()
	_build()


# ------------------------------------------------------------------ yardımcılar

## Aranabilir ülke seçici: uzun açılır liste yerine arama kutulu bir pencere açar (dokunmatikte kaydırırken yanlış seçim olmaz).
class CountryPick extends Button:
	signal item_selected(i)
	var value := ""
	var host

	func _init() -> void:
		custom_minimum_size = Vector2(0, 52)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		clip_text = true
		pressed.connect(_open)

	func set_value(en: String) -> void:
		value = en
		text = "▾  " + U.country_label(en)

	func _open() -> void:
		var sh = Sheet.open(host.root, Loc.t("Ülke seç"), 720, true, true, "")
		var search := LineEdit.new()
		search.placeholder_text = Loc.t("Ülke ara…")
		search.custom_minimum_size = Vector2(0, 56)
		sh.body.add_child(search)
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.custom_minimum_size = Vector2(0, 360)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 6)
		sc.add_child(vb)
		sh.body.add_child(sc)
		var fill := func(q: String):
			for ch in vb.get_children():
				vb.remove_child(ch)
				ch.queue_free()
			var ql := q.strip_edges().to_lower()
			for c in U.countries():
				var lab: String = c["tr"] if Loc.lang == "tr" else c["en"]
				if ql != "" and not lab.to_lower().contains(ql) and not String(c["en"]).to_lower().contains(ql):
					continue
				var bt := TK.button(lab, "gold" if c["en"] == value else "ghost", "", Vector2(0, 50), 17)
				bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
				var en: String = c["en"]
				bt.pressed.connect(func():
					set_value(en)
					item_selected.emit(0)
					sh.close())
				vb.add_child(bt)
		search.text_changed.connect(fill)
		fill.call("")
		sh.add_button("Kapat", func(): pass, "", true, "x", 140)


func _country_picker(selected: String = "") -> Button:
	var cp := CountryPick.new()
	cp.host = self
	cp.set_value(selected if selected != "" else "Turkey")
	return cp


func _val(ob) -> String:
	if ob is CountryPick:
		return ob.value
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
	_cur_page.add_child(_head(title))
	_cur_page.add_child(box)
	_cur_page.add_child(HSeparator.new())
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

const PAGE_TITLES := ["Temel bilgiler", "Oyuncu ve devletler", "Harita ve birlikler", "Diplomasi", "Ordu, silah ve ekonomi", "Zaman çizelgesi (olaylar)", "Hedefler ve kayıt"]
var _pages: Array = []
var _page := 0
var _cur_page: VBoxContainer
var _page_lbl: Label
var _btn_back: Button
var _btn_next: Button


func _new_page() -> VBoxContainer:
	var pb := VBoxContainer.new()
	pb.add_theme_constant_override("separation", 10)
	pb.visible = false
	_sheet.body.add_child(pb)
	_pages.append(pb)
	_cur_page = pb
	return pb


func _show_page(i: int) -> void:
	_page = clampi(i, 0, _pages.size() - 1)
	for k in _pages.size():
		_pages[k].visible = k == _page
	_page_lbl.text = "%s %d / %d  ·  %s" % [Loc.t("SAYFA"), _page + 1, _pages.size(), Loc.t(PAGE_TITLES[_page])]
	_btn_back.disabled = _page == 0
	_btn_next.disabled = _page == _pages.size() - 1
	_msg.text = ""
	if _sheet.scroll != null:
		_sheet.scroll.scroll_vertical = 0


func _line(placeholder: String, maxlen: int, text: String) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = Loc.t(placeholder)
	le.max_length = maxlen
	le.text = text
	le.custom_minimum_size = Vector2(0, 56)
	return le


func _build() -> void:
	_pages = []
	_page = 0
	_sections = {}
	_sheet = Sheet.open(root, "Senaryo oluştur", 900, true, true, "Kendi senaryon")
	U.era = String(d.get("era", ""))
	_sheet.closed.connect(func(): U.era = "")
	U.extra_names = {}
	var ci := 0
	for cu in d.get("custom", []):
		U.extra_names["custom_%d" % ci] = String(cu.get("name", "Yeni Devlet"))
		ci += 1
	_page_lbl = TK.t("", "kicker", TK.GOLD)
	_sheet.body.add_child(_page_lbl)
	# ---- 1. sayfa: temel bilgiler
	var pb := _new_page()
	_name_edit = _line("Senaryo adı", 40, String(d.get("name", "")))
	pb.add_child(_name_edit)
	_sub_edit = _line("Alt başlık (isteğe bağlı)", 60, String(d.get("sub", "")))
	pb.add_child(_sub_edit)
	_intro_edit = _line("Hikâyenin girişi: oyun başında okunacak haber metni", 400, String(d.get("intro", "")))
	pb.add_child(_intro_edit)
	pb.add_child(_head("Dönem (harita)"))
	var era_fl := HFlowContainer.new()
	era_fl.add_theme_constant_override("h_separation", 8)
	era_fl.add_theme_constant_override("v_separation", 8)
	var cur_era: String = String(d.get("era", ""))
	var era_opts: Array = [["", "Dünya 2027"]]
	for ed in Eras.all():
		era_opts.append([String(ed["id"]), String(ed["name"])])
	for eo in era_opts:
		var eid2: String = eo[0]
		var locked: bool = eid2 != "" and not AP.era_unlocked(eid2)
		var eb := TK.button(String(eo[1]) + ("  (" + Loc.t("kilitli") + ")" if locked else ""), "gold" if cur_era == eid2 else "ghost", "", Vector2(0, 52), 16)
		eb.disabled = locked
		eb.pressed.connect(func(): _set_era(eid2))
		era_fl.add_child(eb)
	pb.add_child(era_fl)
	pb.add_child(TK.t("Dönem seçersen harita o dönemin devletleriyle açılır; dönemin tarihî savaşları ve ittifakları geçerli kalır, senin düzenlemelerin üstüne eklenir. Dönem değişince eyalet devirleri ve birlikler sıfırlanır.", "small", TK.FAINT))
	var ylb := HBoxContainer.new()
	ylb.add_theme_constant_override("separation", 10)
	var yll := TK.t("Başlangıç yılı (0 = 2027)", "body", TK.TEXT)
	yll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ylb.add_child(yll)
	_year_spin = SpinBox.new()
	_year_spin.min_value = 0
	_year_spin.max_value = 2100
	_year_spin.step = 1
	_year_spin.value = int(d.get("year", 0))
	_year_spin.editable = String(d.get("era", "")) == ""
	_year_spin.custom_minimum_size = Vector2(160, 52)
	ylb.add_child(_year_spin)
	pb.add_child(ylb)
	pb.add_child(TK.t("Modern harita 2024 ve sonrası için kurulu; geçmiş yıllar için yukarıdan bir dönem seç (silahlar ve kabine o döneme uyar).", "small", TK.FAINT))
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
	pb.add_child(dlb)
	pb.add_child(TK.t("Her sayfada bir konu var: ilerlemek için «İleri»ye bas. Dilediğin sayfayı boş geçebilirsin; «Kaydet» her sayfadan çalışır.", "small", TK.MUTED))
	# ---- 2. sayfa
	_new_page()
	_section("player", "Oyuncu ülkesi", _fill_player)
	_section("cabnames", "Kabine kadrosu (bakan adları)", _fill_cabnames)
	_section("custom", "Sıfırdan yeni devlet kur", _fill_custom)
	_section("rename", "Mevcut ülkelerin adı, lideri, rengi, bayrağı", _fill_rename)
	# ---- 3. sayfa
	_new_page()
	_section("transfer", "Eyalet devirleri (harita boyama)", _fill_transfer)
	_section("garrison", "Birlik yerleştirme", _fill_garrison)
	# ---- 4. sayfa
	_new_page()
	for pk in PAIR_KINDS:
		var key: String = pk[0]
		_section(key, pk[1], func(): _fill_pairs(key))
	_section("blocs", "İttifaklar (bloklar)", _fill_blocs)
	# ---- 5. sayfa
	_new_page()
	_section("mods", "Ülke ayarları", _fill_mods)
	_section("army", "Ordu ve silah özelleştirme", _fill_army)
	# ---- 6. sayfa
	_new_page()
	_section("events", "Hikâye olayları (zamanlı)", _fill_events)
	_section("cabev", "Kabine olayları (bakan sorar, sen cevaplarsın)", _fill_cabev)
	# ---- 7. sayfa
	_new_page()
	_section("objs", "Hedefler", _fill_objs)
	_msg = TK.t("", "small", TK.RED_TEXT)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sheet.body.add_child(_msg)
	_btn_back = _sheet.add_button("◀ Geri", func(): _show_page(_page - 1), "", false, "", 120)
	_btn_next = _sheet.add_button("İleri ▶", func(): _show_page(_page + 1), "blue", false, "", 120)
	_sheet.add_button("Kaydet", _save, "gold", false, "save", 130)
	_sheet.add_button("Paylaşım kodu", _show_code, "", false, "", 170)
	_sheet.add_button("Koddan içe aktar", _import_dialog, "", false, "", 190)
	if U.list_ids().has(String(d.get("id", ""))):
		_sheet.add_button("Sil", func():
			U.remove(String(d["id"]))
			_sheet.close()
			on_done.call(""), "danger", false, "", 110)
	_sheet.add_button("Kapat", func(): _sheet.close(), "", false, "", 130)
	_show_page(0)


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


func _prov_index() -> Array:
	if _prov_idx.is_empty() and String(d.get("era", "")) != "":
		for p in U.era_info(String(d["era"]))["provs"]:
			_prov_idx.append(p)
	if _prov_idx.is_empty():
		var w = WorldData.instance()
		var owner_of := {}
		for c in w.raw.get("countries", []):
			for pid in c.get("provs", []):
				owner_of[int(pid)] = {"en": String(c["name_en"]), "tr": String(c["name"])}
		for p in w.raw.get("provinces", []):
			var o: Dictionary = owner_of.get(int(p["id"]), {"en": "", "tr": ""})
			_prov_idx.append({"id": int(p["id"]), "name": String(p.get("name", "")), "en": o["en"], "tr": o["tr"]})
	return _prov_idx


static var preview_hook := Callable()    # main.gd: (sc, geri_çağrı) başlangıç haritası önizlemesi
static var pick_hook := Callable()     # main.gd: harita seçim modunu açar (cb(pids), bitince geri çağırır)


func _provs_of(en: String) -> Array:
	var out: Array = []
	for p in _prov_index():
		if String(p["en"]) == en:
			out.append(p)
	return out


func _pname(pid: int) -> String:
	for p in _prov_index():
		if int(p["id"]) == pid:
			return String(p["name"])
	return str(pid)


## Devir ekler: week <= 0 → oyun başında; aksi halde o haftada gerçekleşen olay
func _add_transfer(src: String, dst: String, pids: Array, week: int, whole: bool) -> void:
	if src == dst:
		_msg.text = Loc.t("Kaynak ve hedef ülke aynı olamaz.")
		return
	if pids.is_empty():
		_msg.text = Loc.t("Devredilecek eyalet seçilmedi.")
		return
	_msg.text = ""
	if week <= 0:
		for pid in pids:
			var dup := false
			for t in d["transfer"]:
				if int(t[0]) == int(pid):
					t[2] = dst
					t[1] = src
					dup = true
			if not dup and d["transfer"].size() < U.MAX_TRANSFER:
				d["transfer"].append([int(pid), src, dst, "own", _pname(int(pid))])
	else:
		if d["events"].size() >= U.MAX_EVENTS:
			_msg.text = Loc.t("Olay sınırı doldu.")
			return
		var txt: String = ("%s: %s → %s" % [Loc.t("Toprak devri"), U.country_label(src), U.country_label(dst)])
		var ids: Array = []
		for pid in pids:
			ids.append(int(pid))
		d["events"].append({"turn": week, "t": txt, "fx": [["cede", src, dst, "all" if whole else ids]]})
	_refill("transfer", _fill_transfer)
	_refill("events", _fill_events)


## Yaptığın düzenlemelerin (devirler, yeni devletler) başlangıç haritasındaki halini haritada göster
func _preview() -> void:
	var tmp: Dictionary = d.duplicate(true)
	tmp["name"] = _name_edit.text.strip_edges() if _name_edit.text.strip_edges() != "" else "Önizleme"
	var sc: Dictionary = U.sanitize(tmp)
	if sc.is_empty() or not preview_hook.is_valid():
		_msg.text = Loc.t("Önizleme açılamadı.")
		return
	_sheet.visible = false
	preview_hook.call(sc, func(): _sheet.visible = true)


func _fill_transfer() -> void:
	var box: VBoxContainer = _sections["transfer"]
	if not d.has("transfer"):
		d["transfer"] = []
	if preview_hook.is_valid():
		box.add_child(_small_btn("Haritada önizle (düzenlemelerle)", _preview, "blue"))
	var tip := TK.t(Loc.t("Haritayı istediğin gibi boya: bir ülkenin tamamını ya da seçtiğin illeri başka bir ülkeye ver. Hafta 0 = oyun başında; sonrası olursa o haftada, hikâye olayı olarak gerçekleşir."), "small", TK.FAINT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	# başlangıç devirleri: (kaynak → hedef) gruplarına özet
	var groups := {}
	var order: Array = []
	for t in d["transfer"]:
		var k := "%s|%s" % [t[1], t[2]]
		if not groups.has(k):
			groups[k] = []
			order.append(k)
		groups[k].append(int(t[0]))
	for k in order:
		var parts: PackedStringArray = k.split("|")
		var ids: Array = groups[k]
		var names: PackedStringArray = []
		for pid in ids.slice(0, 4):
			names.append(_pname(int(pid)))
		var more := "" if ids.size() <= 4 else " +%d" % (ids.size() - 4)
		var gk: String = k
		box.add_child(_row_label("%s → %s  ·  %d %s\n   %s%s" % [U.country_label(parts[0]), U.country_label(parts[1]), ids.size(), Loc.t("eyalet"), ", ".join(names), more], func():
			d["transfer"] = d["transfer"].filter(func(t): return "%s|%s" % [t[1], t[2]] != gk)
			_refill("transfer", _fill_transfer)))
	var src := _country_picker("Turkey")
	var dst := _country_picker("Greece")
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var l1 := TK.t(Loc.t("Kimden"), "small", TK.MUTED)
	l1.custom_minimum_size = Vector2(80, 0)
	hb.add_child(l1)
	hb.add_child(src)
	box.add_child(hb)
	var hb2 := HBoxContainer.new()
	hb2.add_theme_constant_override("separation", 8)
	var l2 := TK.t(Loc.t("Kime"), "small", TK.MUTED)
	l2.custom_minimum_size = Vector2(80, 0)
	hb2.add_child(l2)
	hb2.add_child(dst)
	box.add_child(hb2)
	var wk := SpinBox.new()
	wk.min_value = 0
	wk.max_value = 520
	wk.step = 1
	wk.value = 0
	wk.prefix = Loc.t("Hafta") + " "
	wk.suffix = "  (0 = " + Loc.t("başlangıç") + ")"
	wk.custom_minimum_size = Vector2(0, 52)
	box.add_child(wk)
	var br := HFlowContainer.new()
	br.add_theme_constant_override("h_separation", 8)
	br.add_theme_constant_override("v_separation", 8)
	br.add_child(_small_btn("Tüm ülkeyi devret", func():
		var ps := _provs_of(_val(src))
		_add_transfer(_val(src), _val(dst), ps.map(func(p): return int(p["id"])), int(wk.value), true), "gold"))
	br.add_child(_small_btn("İlleri listeden seç", func():
		_pick_list(_val(src), _val(dst), int(wk.value)), ""))
	if pick_hook.is_valid():
		br.add_child(_small_btn("Haritadan il seç", func():
			_sheet.visible = false
			pick_hook.call(func(pids: Array):
				_sheet.visible = true
				if pids.is_empty():
					return
				# seçilen illeri sahiplerine göre grupla
				var by_src := {}
				for pid in pids:
					var own: String = ""
					for p in _prov_index():
						if int(p["id"]) == int(pid):
							own = String(p["en"])
					if own == "" or own == _val(dst):
						continue
					if not by_src.has(own):
						by_src[own] = []
					by_src[own].append(int(pid))
				for sn in by_src:
					_add_transfer(sn, _val(dst), by_src[sn], int(wk.value), false)), "blue"))
	box.add_child(br)


## Seçilebilir il listesi (onay kutuları); dokunmatik kaydırmayla seçim karışmaz
func _pick_list(src: String, dst: String, week: int) -> void:
	var provs := _provs_of(src)
	if provs.is_empty():
		_msg.text = Loc.t("Bu ülkenin eyaleti yok.")
		return
	var sh = Sheet.open(root, "%s → %s" % [U.country_label(src), U.country_label(dst)], 760, true, true, Loc.t("İlleri seç"))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 380)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	sh.body.add_child(sc)
	var boxes: Array = []
	for p in provs:
		var cb := CheckBox.new()
		cb.text = String(p["name"])
		cb.custom_minimum_size = Vector2(0, 48)
		cb.set_meta("pid", int(p["id"]))
		vb.add_child(cb)
		boxes.append(cb)
	sh.add_button("Hepsini seç", func():
		for cb in boxes:
			cb.button_pressed = true, "", false, "", 160)
	sh.add_button("Temizle", func():
		for cb in boxes:
			cb.button_pressed = false, "", false, "", 130)
	sh.add_button("Devret", func():
		var ids: Array = []
		for cb in boxes:
			if cb.button_pressed:
				ids.append(int(cb.get_meta("pid")))
		_add_transfer(src, dst, ids, week, ids.size() == provs.size()), "gold", true, "check", 150)
	sh.add_button("Kapat", func(): pass, "", true, "x", 130)


## Birlik yerleştirme: seçilen ilde belirli büyüklükte ordu (0 = orduyu kaldır)
func _fill_garrison() -> void:
	var box: VBoxContainer = _sections["garrison"]
	if not d.has("garrison"):
		d["garrison"] = []
	var tip := TK.t(Loc.t("Bir ilin ordusunu tam sayıyla belirle (örn. cepheye 200.000 asker koy). İl o ülkeye ait olmalı; 0 yazarsan orada ordu kalmaz."), "small", TK.FAINT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	for i in d["garrison"].size():
		var g: Array = d["garrison"][i]
		var idx: int = i
		box.add_child(_row_label("%s (%s): %s" % [_pname(int(g[0])), U.country_label(String(g[1])), str(int(g[2]))], func():
			d["garrison"].remove_at(idx)
			_refill("garrison", _fill_garrison)))
	var who := _country_picker("Turkey")
	box.add_child(who)
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("İl ara (en az 2 harf)")
	search.custom_minimum_size = Vector2(0, 52)
	box.add_child(search)
	var res := VBoxContainer.new()
	res.add_theme_constant_override("separation", 4)
	box.add_child(res)
	var chosen := {"pid": -1}
	var chosen_lbl := TK.t("", "small", TK.GOLD)
	var show := func(q: String):
		for ch in res.get_children():
			res.remove_child(ch)
			ch.queue_free()
		var ql := q.strip_edges().to_lower()
		if ql.length() < 2:
			return
		var n := 0
		for p in _provs_of(_val(who)):
			if String(p["name"]).to_lower().contains(ql):
				var bt := TK.button(String(p["name"]), "ghost", "", Vector2(0, 46), 16)
				bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
				var pid: int = int(p["id"])
				var pn: String = String(p["name"])
				bt.pressed.connect(func():
					chosen["pid"] = pid
					chosen_lbl.text = "✔ " + pn)
				res.add_child(bt)
				n += 1
				if n >= 8:
					break
	search.text_changed.connect(show)
	box.add_child(chosen_lbl)
	var amt := SpinBox.new()
	amt.min_value = 0
	amt.max_value = 5000000
	amt.step = 1000
	amt.value = 50000
	amt.suffix = " " + Loc.t("asker")
	amt.custom_minimum_size = Vector2(0, 52)
	box.add_child(amt)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_child(_small_btn("Birliği yerleştir", func():
		if int(chosen["pid"]) < 0:
			_msg.text = Loc.t("Önce bir il ara ve seç.")
			return
		if d["garrison"].size() >= U.MAX_GARRISON:
			return
		_msg.text = ""
		var pid2: int = int(chosen["pid"])
		d["garrison"] = d["garrison"].filter(func(g): return int(g[0]) != pid2)
		d["garrison"].append([pid2, _val(who), int(amt.value), _pname(pid2)])
		_refill("garrison", _fill_garrison), "good"))
	if pick_hook.is_valid():
		row.add_child(_small_btn("Haritadan il seç", func():
			_sheet.visible = false
			pick_hook.call(func(pids: Array):
				_sheet.visible = true
				if pids.is_empty():
					return
				chosen["pid"] = int(pids[0])
				chosen_lbl.text = "✔ " + _pname(int(pids[0]))
				for p in _prov_index():
					if int(p["id"]) == int(pids[0]):
						who.set_value(String(p["en"]))), "blue"))
	box.add_child(row)


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
	for spec in [["troops", "Ordu çarpanı", 0.1, 5.0, 0.1, 1.0], ["treasury", "Kasa çarpanı", 0.0, 10.0, 0.1, 1.0], ["stab", "İstikrar farkı", -60.0, 40.0, 1.0, 0.0]]:
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


# ------------------------------------------------------------------ yeni devlet

func _provs_label(pids: Array) -> String:
	if pids.is_empty():
		return Loc.t("henüz il seçilmedi")
	var names: Array = []
	for q in pids.slice(0, 4):
		names.append(_pname(int(q)))
	return "%d %s: %s%s" % [pids.size(), Loc.t("il"), ", ".join(names), "…" if pids.size() > 4 else ""]


func _refresh_extra_names() -> void:
	U.extra_names = {}
	var ci := 0
	for cu in d.get("custom", []):
		U.extra_names["custom_%d" % ci] = String(cu.get("name", "Yeni Devlet"))
		ci += 1


func _fill_custom() -> void:
	var box: VBoxContainer = _sections["custom"]
	if not d.has("custom"):
		d["custom"] = []
	var arr: Array = d["custom"]
	var tip := TK.t(Loc.t("Haritadaki illerden kendi devletini kur: adı, lideri, renkleri, bayrağı, ordusu, ilk günden mi yoksa belli bir haftada mı doğacağı… Kurduğun devlet diğer sayfalardaki seçicilerde de görünür (savaş, ittifak, olay…)."), "small", TK.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	for i in arr.size():
		var c: Dictionary = arr[i]
		var idx: int = i
		var line := "%s — %s\n   %s · %s" % [String(c["name"]), String(c.get("leader", "")), _provs_label(c["pids"]),
			(Loc.t("Hafta") + " %d" % int(c.get("week", 0))) if int(c.get("week", 0)) > 0 else Loc.t("oyun başında")]
		if bool(c.get("play", false)):
			line += " · " + Loc.t("oyuncu bu devlet")
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := TK.t(line, "body", TK.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(l)
		hb.add_child(_small_btn("Düzenle", func(): _custom_form(idx), ""))
		var x := TK.button("Sil", "danger", "", Vector2(90, 48), 16)
		x.pressed.connect(func():
			arr.remove_at(idx)
			_refresh_extra_names()
			_refill("custom", _fill_custom))
		hb.add_child(x)
		box.add_child(hb)
	if arr.size() < U.MAX_CUSTOM:
		box.add_child(_small_btn("Yeni devlet kur", func(): _custom_form(-1), "gold"))


func _color_btn(c: Color) -> ColorPickerButton:
	var cp := ColorPickerButton.new()
	cp.color = c
	cp.edit_alpha = false
	cp.custom_minimum_size = Vector2(70, 48)
	return cp


func _lab_spin(parent: Node, label: String, lo: float, hi: float, step: float, val: float) -> SpinBox:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var l := TK.t(Loc.t(label), "small", TK.TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(l)
	var sp := SpinBox.new()
	sp.min_value = lo
	sp.max_value = hi
	sp.step = step
	sp.value = val
	sp.custom_minimum_size = Vector2(170, 48)
	hb.add_child(sp)
	parent.add_child(hb)
	return sp


func _custom_form(idx: int) -> void:
	var arr: Array = d["custom"]
	var c: Dictionary = (arr[idx] as Dictionary).duplicate(true) if idx >= 0 else {"name": "", "leader": "", "pids": [], "colors": ["#3a7bd5", "#f5f5f5", "#d4af37"], "flag": "", "troops": 30000,
		"tech": 0.5, "aggression": 0.5, "doctrine": 0, "gold_mult": 1.0, "war": false, "play": false, "week": 0}
	var sh = Sheet.open(root, Loc.t("Yeni devlet"), 880, true, true, Loc.t("Sıfırdan devlet kur"))
	var nm := _line("Devletin adı", 40, String(c["name"]))
	sh.body.add_child(nm)
	var ld := _line("Liderin adı", 40, String(c.get("leader", "")))
	sh.body.add_child(ld)
	var cols: Array = c["colors"]
	while cols.size() < 3:
		cols.append("#888888")
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	crow.add_child(TK.t(Loc.t("Renkler (harita / bayrak)"), "small", TK.TEXT))
	var cb: Array = []
	for k in 3:
		var cp := _color_btn(Color(String(cols[k])))
		crow.add_child(cp)
		cb.append(cp)
	sh.body.add_child(crow)
	# bayrak
	var flag_spec: Array = [String(c.get("flag", ""))]
	var fl_lbl := TK.t("", "small", TK.MUTED)
	var set_fl := func():
		fl_lbl.text = Loc.t("Bayrak: özel tasarım var") if flag_spec[0] != "" else Loc.t("Bayrak: renklerden otomatik")
	set_fl.call()
	var fhb := HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 10)
	fhb.add_child(_small_btn("Bayrak tasarla", func():
		FlagEditor.open(root, flag_spec[0], func(sp: String):
			flag_spec[0] = sp
			set_fl.call()), "blue"))
	fhb.add_child(fl_lbl)
	sh.body.add_child(fhb)
	# iller
	var pids: Array = (c["pids"] as Array).duplicate()
	var pl := TK.t(_provs_label(pids), "small", TK.TEXT)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var upd := func(): pl.text = _provs_label(pids)
	sh.body.add_child(pl)
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 8)
	pr.add_child(_small_btn("İlleri listeden seç", func():
		_pick_provs_for(pids, upd), ""))
	if pick_hook.is_valid():
		pr.add_child(_small_btn("Haritadan il seç", func():
			pick_hook.call(func(got: Array):
				for g in got:
					if not pids.has(int(g)):
						pids.append(int(g))
				upd.call()), ""))
	pr.add_child(_small_btn("Temizle", func():
		pids.clear()
		upd.call(), "danger"))
	sh.body.add_child(pr)
	var cap_sp := _lab_spin(sh.body, "Başkent il numarası (0 = otomatik)", 0, 9999, 1, int(c.get("capital", 0)) if c.has("capital") else 0)
	var troops := _lab_spin(sh.body, "Ordu (asker)", 1000, 5000000, 1000, int(c["troops"]))
	var tech := _lab_spin(sh.body, "Teknoloji (0-100)", 0, 100, 5, float(c["tech"]) * 100.0)
	var aggr := _lab_spin(sh.body, "Saldırganlık (0-100)", 0, 100, 5, float(c["aggression"]) * 100.0)
	var gold := _lab_spin(sh.body, "Gelir çarpanı", 0, 10, 0.1, float(c["gold_mult"]))
	var doc := _lab_spin(sh.body, "Doktrin (0-9)", 0, 9, 1, int(c["doctrine"]))
	var wk := _lab_spin(sh.body, "Doğum haftası (0 = oyun başında)", 0, 520, 1, int(c.get("week", 0)))
	var war := CheckBox.new()
	war.text = Loc.t("Ana devletle savaşta doğsun (bağımsızlık savaşı)")
	war.button_pressed = bool(c.get("war", false))
	sh.body.add_child(war)
	var play := CheckBox.new()
	play.text = Loc.t("Oyuncu bu devleti yönetsin (yalnız oyun başında doğuyorsa)")
	play.button_pressed = bool(c.get("play", false))
	sh.body.add_child(play)
	sh.add_button("Kaydet", func():
		if nm.text.strip_edges() == "":
			_msg.text = Loc.t("Devlete bir ad ver.")
			return
		if pids.is_empty():
			_msg.text = Loc.t("Devlet için en az bir il seç.")
			return
		var ne := {"name": nm.text.strip_edges(), "leader": ld.text.strip_edges(), "pids": pids,
			"colors": [cb[0].color.to_html(false), cb[1].color.to_html(false), cb[2].color.to_html(false)].map(func(h): return "#" + String(h)),
			"flag": flag_spec[0], "troops": int(troops.value), "tech": tech.value / 100.0, "aggression": aggr.value / 100.0,
			"doctrine": int(doc.value), "gold_mult": gold.value, "war": war.button_pressed, "play": play.button_pressed and int(wk.value) == 0, "week": int(wk.value)}
		if int(cap_sp.value) > 0:
			ne["capital"] = int(cap_sp.value)
		_msg.text = ""
		if idx >= 0:
			arr[idx] = ne
		else:
			arr.append(ne)
		_refresh_extra_names()
		_refill("custom", _fill_custom), "gold", true, "check", 150)
	sh.add_button("Vazgeç", func(): pass, "", true, "x", 130)


## Eyalet listesinden çoklu seçim (ülke → il)
func _pick_provs_for(pids: Array, on_change: Callable) -> void:
	var sh = Sheet.open(root, Loc.t("İl seç"), 780, true, true, "")
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("İl ara…")
	search.custom_minimum_size = Vector2(0, 56)
	sh.body.add_child(search)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 380)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	sh.body.add_child(sc)
	var all: Array = _prov_index()
	var fill := func(q: String):
		for ch in vb.get_children():
			vb.remove_child(ch)
			ch.queue_free()
		var ql := q.strip_edges().to_lower()
		var shown := 0
		for e in all:
			if shown >= 80:
				break
			var nm: String = String(e["name"])
			if ql != "" and not nm.to_lower().contains(ql):
				continue
			var pid: int = int(e["id"])
			var cbx := CheckBox.new()
			cbx.text = "%s  (%s)" % [nm, U.country_label(String(e["en"]))]
			cbx.button_pressed = pids.has(pid)
			cbx.custom_minimum_size = Vector2(0, 46)
			cbx.toggled.connect(func(on: bool):
				if on and not pids.has(pid):
					pids.append(pid)
				elif not on:
					pids.erase(pid)
				on_change.call())
			vb.add_child(cbx)
			shown += 1
	search.text_changed.connect(fill)
	fill.call("")
	sh.add_button("Tamam", func(): pass, "gold", true, "check", 150)


# ------------------------------------------------------------------ ülke adı / lider / renk / bayrak değişimi

func _fill_rename() -> void:
	var box: VBoxContainer = _sections["rename"]
	if not d.has("rename"):
		d["rename"] = {}
	var ren: Dictionary = d["rename"]
	var tip := TK.t(Loc.t("Var olan bir ülkenin adını, liderini, renklerini ve bayrağını değiştir (ör. Osmanlı İmparatorluğu, Sultan II. Abdülhamid, kırmızı bayrak + hilal)."), "small", TK.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	for cn in ren.keys():
		var r: Dictionary = ren[cn]
		var cname: String = cn
		var parts: Array = []
		if r.has("name"):
			parts.append(String(r["name"]))
		if r.has("leader"):
			parts.append(Loc.t("lider") + ": " + String(r["leader"]))
		if r.has("color"):
			parts.append(Loc.t("renk"))
		if r.has("flag"):
			parts.append(Loc.t("bayrak"))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := TK.t("%s → %s" % [U.country_label(cname), ", ".join(parts)], "body", TK.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(l)
		hb.add_child(_small_btn("Düzenle", func(): _rename_form(cname), ""))
		var x := TK.button("Sil", "danger", "", Vector2(90, 48), 16)
		x.pressed.connect(func():
			ren.erase(cname)
			_refill("rename", _fill_rename))
		hb.add_child(x)
		box.add_child(hb)
	box.add_child(_small_btn("Ülke düzenle", func(): _rename_form(""), "gold"))


func _rename_form(cname: String) -> void:
	var ren: Dictionary = d["rename"]
	var sh = Sheet.open(root, Loc.t("Ülkeyi düzenle"), 860, true, true, "")
	var pick := _country_picker(cname if cname != "" else "Turkey")
	sh.body.add_child(pick)
	var r: Dictionary = ren.get(pick.value, {})
	var nm := _line("Yeni ülke adı (boşsa değişmez)", 40, String(r.get("name", "")))
	sh.body.add_child(nm)
	var ld := _line("Lider adı (boşsa değişmez)", 40, String(r.get("leader", "")))
	sh.body.add_child(ld)
	var use_col := CheckBox.new()
	use_col.text = Loc.t("Renkleri değiştir")
	use_col.button_pressed = r.has("color")
	sh.body.add_child(use_col)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	var cb: Array = []
	for k in 3:
		var key: String = ["color", "color2", "color3"][k]
		var cp := _color_btn(Color(String(r.get(key, ["#c8102e", "#f5f5f5", "#d4af37"][k]))))
		crow.add_child(cp)
		cb.append(cp)
	sh.body.add_child(crow)
	var flag_spec: Array = [String(r.get("flag", ""))]
	var fl_lbl := TK.t("", "small", TK.MUTED)
	var set_fl := func():
		fl_lbl.text = Loc.t("Özel bayrak ayarlı") if flag_spec[0] != "" else Loc.t("Bayrak değişmez")
	set_fl.call()
	var fhb := HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 10)
	fhb.add_child(_small_btn("Bayrak tasarla", func():
		FlagEditor.open(root, flag_spec[0], func(sp: String):
			flag_spec[0] = sp
			set_fl.call()), "blue"))
	fhb.add_child(_small_btn("Bayrağı sıfırla", func():
		flag_spec[0] = ""
		set_fl.call(), ""))
	fhb.add_child(fl_lbl)
	sh.body.add_child(fhb)
	sh.add_button("Kaydet", func():
		var en := _val(pick)
		var nr := {}
		if nm.text.strip_edges() != "":
			nr["name"] = nm.text.strip_edges()
		if ld.text.strip_edges() != "":
			nr["leader"] = ld.text.strip_edges()
		if use_col.button_pressed:
			nr["color"] = "#" + cb[0].color.to_html(false)
			nr["color2"] = "#" + cb[1].color.to_html(false)
			nr["color3"] = "#" + cb[2].color.to_html(false)
		if flag_spec[0] != "":
			nr["flag"] = flag_spec[0]
		if cname != "" and cname != en:
			ren.erase(cname)
		if nr.is_empty():
			ren.erase(en)
		else:
			ren[en] = nr
		_refill("rename", _fill_rename), "gold", true, "check", 150)
	sh.add_button("Vazgeç", func(): pass, "", true, "x", 130)


# ------------------------------------------------------------------ ordu ve silah özelleştirme

func _fill_army() -> void:
	var box: VBoxContainer = _sections["army"]
	for k in ["weapons", "cats", "inv", "tech", "doctrine"]:
		if not d.has(k):
			d[k] = {}
	var tip := TK.t(Loc.t("Silahların adını, maliyetini ve gücünü; birlik sınıflarının adını; ülkelerin başlangıç envanterini, teknoloji düzeyini ve doktrinini değiştir."), "small", TK.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	# sınıf adları
	box.add_child(TK.t(Loc.t("Birlik sınıflarının adı"), "kicker", TK.GOLD))
	for k in Arsenal.CATS:
		var key: String = k
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := TK.t(Loc.t(String(Arsenal.CAT_NAME[key])), "small", TK.MUTED)
		l.custom_minimum_size = Vector2(190, 0)
		hb.add_child(l)
		var le := _line("Yeni ad (boşsa varsayılan)", 30, String(d["cats"].get(key, "")))
		le.custom_minimum_size = Vector2(0, 46)
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.text_changed.connect(func(t: String):
			if t.strip_edges() == "":
				d["cats"].erase(key)
			else:
				d["cats"][key] = t.strip_edges())
		hb.add_child(le)
		box.add_child(hb)
	# silahlar
	box.add_child(TK.t(Loc.t("Silahlar"), "kicker", TK.GOLD))
	for wid in d["weapons"].keys():
		var w: Dictionary = d["weapons"][wid]
		var wk: String = wid
		var txt := "%s → %s (×%.1f %s, ×%.1f %s)" % [Arsenal.ITEMS[wk][0] if Arsenal.ITEMS.has(wk) else wk, String(w.get("name", "—")), float(w.get("cost", 1.0)), Loc.t("maliyet"), float(w.get("pow", 1.0)), Loc.t("güç")]
		box.add_child(_row_label(txt, func():
			d["weapons"].erase(wk)
			_refill("army", _fill_army)))
	box.add_child(_small_btn("Silah düzenle", func(): _weapon_form(), "gold"))
	# envanter / teknoloji / doktrin
	box.add_child(TK.t(Loc.t("Ülke başına teknoloji, doktrin ve envanter"), "kicker", TK.GOLD))
	var keys := {}
	for k in ["inv", "tech", "doctrine"]:
		for c in d[k].keys():
			keys[c] = true
	for c in keys.keys():
		var cc: String = c
		var parts: Array = []
		if d["tech"].has(cc):
			parts.append("%s %d" % [Loc.t("teknoloji"), int(float(d["tech"][cc]) * 100.0)])
		if d["doctrine"].has(cc):
			parts.append("%s %d" % [Loc.t("doktrin"), int(d["doctrine"][cc])])
		if d["inv"].has(cc):
			parts.append("%d %s" % [d["inv"][cc].size(), Loc.t("silah türü")])
		box.add_child(_row_label("%s: %s" % [U.country_label(cc), ", ".join(parts)], func():
			for k2 in ["inv", "tech", "doctrine"]:
				d[k2].erase(cc)
			_refill("army", _fill_army)))
	box.add_child(_small_btn("Ülke ordusunu düzenle", func(): _army_country_form(), "gold"))


func _weapon_form() -> void:
	var sh = Sheet.open(root, Loc.t("Silah düzenle"), 820, true, true, "")
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("Silah ara (ör. Leopard, F-16, S-400)…")
	search.custom_minimum_size = Vector2(0, 56)
	sh.body.add_child(search)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 320)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	sh.body.add_child(sc)
	var sel: Array = [""]
	var sel_lbl := TK.t(Loc.t("Bir silah seç"), "body", TK.GOLD)
	sh.body.add_child(sel_lbl)
	var nm := _line("Yeni silah adı (boşsa değişmez)", 40, "")
	sh.body.add_child(nm)
	var cost := _lab_spin(sh.body, "Maliyet çarpanı", 0.1, 10.0, 0.1, 1.0)
	var pw := _lab_spin(sh.body, "Güç çarpanı", 0.2, 5.0, 0.1, 1.0)
	var fill := func(q: String):
		for ch in vb.get_children():
			vb.remove_child(ch)
			ch.queue_free()
		var ql := q.strip_edges().to_lower()
		var shown := 0
		for id in Arsenal.ITEMS.keys():
			if shown >= 60:
				break
			var base: String = String(Arsenal.ITEMS[id][0])
			if ql != "" and not base.to_lower().contains(ql) and not String(id).to_lower().contains(ql):
				continue
			var wid: String = id
			var bt := TK.button("%s  ·  %s" % [base, Loc.t(String(Arsenal.CAT_NAME.get(Arsenal.ITEMS[id][1], "")))], "ghost", "", Vector2(0, 46), 16)
			bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bt.pressed.connect(func():
				sel[0] = wid
				sel_lbl.text = base
				var cur: Dictionary = d["weapons"].get(wid, {})
				nm.text = String(cur.get("name", ""))
				cost.value = float(cur.get("cost", 1.0))
				pw.value = float(cur.get("pow", 1.0)))
			vb.add_child(bt)
			shown += 1
	search.text_changed.connect(fill)
	fill.call("")
	sh.add_button("Kaydet", func():
		if sel[0] == "":
			_msg.text = Loc.t("Önce listeden bir silah seç.")
			return
		var w := {}
		if nm.text.strip_edges() != "":
			w["name"] = nm.text.strip_edges()
		if absf(cost.value - 1.0) > 0.01:
			w["cost"] = cost.value
		if absf(pw.value - 1.0) > 0.01:
			w["pow"] = pw.value
		if w.is_empty():
			d["weapons"].erase(sel[0])
		else:
			d["weapons"][sel[0]] = w
		_msg.text = ""
		_refill("army", _fill_army), "gold", true, "check", 150)
	sh.add_button("Vazgeç", func(): pass, "", true, "x", 130)


func _army_country_form() -> void:
	var sh = Sheet.open(root, Loc.t("Ülke ordusu"), 820, true, true, "")
	var pick := _country_picker("Turkey")
	sh.body.add_child(pick)
	var use_t := CheckBox.new()
	use_t.text = Loc.t("Teknoloji düzeyini sabitle")
	sh.body.add_child(use_t)
	var tech := _lab_spin(sh.body, "Teknoloji (0-100)", 0, 100, 5, 50)
	var use_d := CheckBox.new()
	use_d.text = Loc.t("Doktrini sabitle")
	sh.body.add_child(use_d)
	var doc := _lab_spin(sh.body, "Doktrin (0-9)", 0, 9, 1, 0)
	var load_vals := func():
		var en := _val(pick)
		use_t.button_pressed = d["tech"].has(en)
		tech.value = float(d["tech"].get(en, 0.5)) * 100.0
		use_d.button_pressed = d["doctrine"].has(en)
		doc.value = int(d["doctrine"].get(en, 0))
	load_vals.call()
	pick.item_selected.connect(func(_i): load_vals.call())
	sh.body.add_child(TK.t(Loc.t("Başlangıç envanteri (adet; 0 = ekleme)"), "kicker", TK.GOLD))
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("Silah ara…")
	search.custom_minimum_size = Vector2(0, 52)
	sh.body.add_child(search)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 260)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	sc.add_child(vb)
	sh.body.add_child(sc)
	var pending := {}
	var fill := func(q: String):
		for ch in vb.get_children():
			vb.remove_child(ch)
			ch.queue_free()
		var ql := q.strip_edges().to_lower()
		var shown := 0
		var en := _val(pick)
		for id in Arsenal.ITEMS.keys():
			if shown >= 40:
				break
			var base: String = String(Arsenal.ITEMS[id][0])
			if ql != "" and not base.to_lower().contains(ql):
				continue
			var wid: String = id
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			var l := TK.t(base, "small", TK.TEXT)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(l)
			var sp := SpinBox.new()
			sp.min_value = 0
			sp.max_value = 1000000
			sp.step = 10
			sp.value = float(pending.get(wid, d["inv"].get(en, {}).get(wid, 0)))
			sp.custom_minimum_size = Vector2(150, 44)
			sp.value_changed.connect(func(v: float): pending[wid] = int(v))
			hb.add_child(sp)
			vb.add_child(hb)
			shown += 1
	search.text_changed.connect(fill)
	fill.call("")
	sh.add_button("Kaydet", func():
		var en := _val(pick)
		if use_t.button_pressed:
			d["tech"][en] = tech.value / 100.0
		else:
			d["tech"].erase(en)
		if use_d.button_pressed:
			d["doctrine"][en] = int(doc.value)
		else:
			d["doctrine"].erase(en)
		var cur: Dictionary = d["inv"].get(en, {})
		for wid in pending.keys():
			if int(pending[wid]) > 0:
				cur[wid] = int(pending[wid])
			else:
				cur.erase(wid)
		if cur.is_empty():
			d["inv"].erase(en)
		else:
			d["inv"][en] = cur
		_refill("army", _fill_army), "gold", true, "check", 150)
	sh.add_button("Vazgeç", func(): pass, "", true, "x", 130)



const FX_LABELS := [["", "Yalnızca haber"], ["war", "Savaş çıkar"], ["peace", "Barış olur"], ["ally", "İttifak kurulur"], ["break", "İttifak bozulur"],
	["vassal", "Vasal olur (2. ülke 1.'nin vasalı)"], ["free", "Vasal serbest kalır"], ["embargo", "Ambargo konur"],
	["xstab", "İstikrar değişir (±)"], ["xgold", "Hazine değişir (± haftalık gelir)"], ["xtroops", "Ordu değişir (± %)"], ["xtech", "Teknoloji değişir (± puan)"],
	["leader", "Lider değişir (yeni isim)"], ["rename", "Ülke adı değişir (yeni ad)"], ["cabinet", "Oyuncunun bakanı değişir"]]
const ROLES := [["def", "Savunma Bakanı"], ["for", "Dışişleri Bakanı"], ["int", "İçişleri Bakanı"], ["fin", "Maliye Bakanı"], ["hlt", "Sağlık Bakanı"], ["spy", "İstihbarat Başkanı"]]


func _fx_text(f: Array) -> String:
	var t: String = String(f[0])
	match t:
		"war":
			return "%s → %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("savaş")]
		"peace":
			return "%s – %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("barış")]
		"ally":
			return "%s + %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("ittifak")]
		"break":
			return "%s × %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("ittifak bozulur")]
		"vassal":
			return "%s ⇒ %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("vasal olur")]
		"free":
			return "%s: %s" % [U.country_label(f[1]), Loc.t("vasallıktan çıkar")]
		"embargo":
			return "%s × %s: %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("ambargo")]
		"xstab":
			return "%s: %s %+d" % [U.country_label(f[1]), Loc.t("istikrar"), int(f[2])]
		"xgold":
			return "%s: %s %+d %s" % [U.country_label(f[1]), Loc.t("hazine"), int(f[2]), Loc.t("hafta")]
		"xtroops":
			return "%s: %s %+d%%" % [U.country_label(f[1]), Loc.t("ordu"), int(f[2])]
		"xtech":
			return "%s: %s %+d" % [U.country_label(f[1]), Loc.t("teknoloji"), int(f[2])]
		"leader":
			return "%s: %s → %s" % [U.country_label(f[1]), Loc.t("lider"), String(f[2])]
		"rename":
			return "%s: %s → %s" % [U.country_label(f[1]), Loc.t("yeni ad"), String(f[2])]
		"cabinet":
			var cp: PackedStringArray = String(f[2]).split("|")
			var rt := String(f[2])
			for r in ROLES:
				if cp.size() == 2 and r[0] == cp[0]:
					rt = "%s → %s" % [Loc.t(r[1]), cp[1]]
			return "%s: %s" % [Loc.t("Oyuncunun kabinesi"), rt]
		"cede":
			var cnt: String = Loc.t("tüm ülke") if (typeof(f[3]) != TYPE_ARRAY) else "%d %s" % [(f[3] as Array).size(), Loc.t("eyalet")]
			return "%s → %s: %s %s" % [U.country_label(f[1]), U.country_label(f[2]), Loc.t("devir"), cnt]
	return ""


func _fill_events() -> void:
	var box: VBoxContainer = _sections["events"]
	var tip := TK.t(Loc.t("Hangi haftada ne olsun, haberde ne yazsın: hepsini sen belirle. Olay hafta gelince haber olarak düşer ve seçtiğin etki gerçekleşir (savaş, barış, ittifak, vasallık, lider/ülke adı değişimi, istikrar, hazine, ordu, teknoloji, bakan değişimi). Oyuncu ülkesi de etkilenebilir."), "small", TK.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var arr: Array = d["events"]
	arr.sort_custom(func(a, b): return int(a["turn"]) < int(b["turn"]))
	for i in arr.size():
		var e: Dictionary = arr[i]
		var idx: int = i
		var line := "%s %d: %s" % [Loc.t("Hafta"), int(e["turn"]), String(e["t"])]
		for f in e["fx"]:
			line += "\n   › " + _fx_text(f)
		box.add_child(_row_label(line, func():
			arr.remove_at(idx)
			_refill("events", _fill_events)))
	if arr.size() >= U.MAX_EVENTS:
		return
	var wk := SpinBox.new()
	wk.min_value = 0
	wk.max_value = 520
	wk.step = 1
	wk.value = 8
	wk.prefix = Loc.t("Hafta") + " "
	wk.custom_minimum_size = Vector2(200, 52)
	var txt := LineEdit.new()
	txt.placeholder_text = Loc.t("Haber metni (ör. Sınırda silah sesleri duyuldu)")
	txt.max_length = 220
	txt.custom_minimum_size = Vector2(0, 56)
	var hb0 := HBoxContainer.new()
	hb0.add_theme_constant_override("separation", 8)
	hb0.add_child(wk)
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb0.add_child(txt)
	box.add_child(hb0)
	var tp := OptionButton.new()
	tp.custom_minimum_size = Vector2(0, 52)
	for fl in FX_LABELS:
		tp.add_item(Loc.t(fl[1]))
	box.add_child(tp)
	var a := _country_picker("Turkey")
	var b := _country_picker("Greece")
	var amt := SpinBox.new()
	amt.min_value = -50
	amt.max_value = 50
	amt.value = -10
	amt.custom_minimum_size = Vector2(150, 52)
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = Loc.t("Yeni isim")
	name_edit.max_length = 40
	name_edit.custom_minimum_size = Vector2(0, 52)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role := OptionButton.new()
	role.custom_minimum_size = Vector2(0, 52)
	for r in ROLES:
		role.add_item(Loc.t(r[1]))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(a)
	hb.add_child(b)
	hb.add_child(amt)
	hb.add_child(role)
	hb.add_child(name_edit)
	box.add_child(hb)
	var sync := func():
		var t: String = FX_LABELS[tp.selected][0]
		a.visible = t != "" and t != "cabinet"
		b.visible = t in ["war", "peace", "ally", "break", "vassal", "embargo"]
		amt.visible = t in ["xstab", "xgold", "xtroops", "xtech"]
		name_edit.visible = t in ["leader", "rename", "cabinet"]
		role.visible = t == "cabinet"
	tp.item_selected.connect(func(_i): sync.call())
	sync.call()
	box.add_child(_small_btn("Olayı ekle", func():
		var t: String = FX_LABELS[tp.selected][0]
		var fx: Array = []
		if t in ["war", "peace", "ally", "break", "vassal", "embargo"]:
			if _val(a) == _val(b):
				_msg.text = Loc.t("İki taraf aynı ülke olamaz.")
				return
			fx.append([t, _val(a), _val(b)])
		elif t == "free":
			fx.append([t, _val(a)])
		elif t in ["leader", "rename"]:
			if name_edit.text.strip_edges() == "":
				_msg.text = Loc.t("Yeni ismi yaz.")
				return
			fx.append([t, _val(a), name_edit.text.strip_edges()])
		elif t == "cabinet":
			if name_edit.text.strip_edges() == "":
				_msg.text = Loc.t("Yeni bakanın adını yaz.")
				return
			fx.append([t, "*", "%s|%s" % [ROLES[role.selected][0], name_edit.text.strip_edges()]])
		elif t != "":
			fx.append([t, _val(a), float(amt.value)])
		if txt.text.strip_edges() == "" and fx.is_empty():
			_msg.text = Loc.t("Haber metni yaz ya da bir etki seç.")
			return
		_msg.text = ""
		arr.append({"turn": int(wk.value), "t": txt.text.strip_edges(), "fx": fx})
		_refill("events", _fill_events), "good"))


# ------------------------------------------------------------------ kabine: bakan adları ve bakanın sorduğu olaylar

func _fill_cabnames() -> void:
	var box: VBoxContainer = _sections["cabnames"]
	if not d.has("cab_names"):
		d["cab_names"] = {}
	var tip := TK.t(Loc.t("Oyuncunun kabinesindeki bakanların adlarını yaz (boş bırakırsan oyun kendisi seçer)."), "small", TK.FAINT)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	for r in ROLES:
		var role: String = r[0]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := TK.t(Loc.t(r[1]), "small", TK.MUTED)
		l.custom_minimum_size = Vector2(170, 0)
		hb.add_child(l)
		var le := _line("Ad Soyad", 40, String(d["cab_names"].get(role, "")))
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.custom_minimum_size = Vector2(0, 48)
		le.text_changed.connect(func(t: String):
			if t.strip_edges() == "":
				d["cab_names"].erase(role)
			else:
				d["cab_names"][role] = t.strip_edges())
		hb.add_child(le)
		box.add_child(hb)


const EFF_ROWS := [["g", "Hazine (haftalık gelir ×)", -3.0, 3.0, 0.1, 1.0], ["stab", "İstikrar", -10.0, 10.0, 1.0, 1.0], ["cyb", "Siber", -10.0, 10.0, 1.0, 1.0],
	["ind", "Sanayi", -10.0, 10.0, 1.0, 1.0], ["log", "Lojistik", -10.0, 10.0, 1.0, 1.0], ["tech", "Teknoloji (puan)", -10.0, 10.0, 0.5, 0.01],
	["troops", "Ordu (%)", -30.0, 30.0, 1.0, 0.01], ["unrest", "Huzursuzluk (il sayısı)", 0.0, 6.0, 1.0, 1.0], ["aggr", "Komşu saldırganlığı (%)", -20.0, 20.0, 1.0, 0.01],
	["dev", "Başkent kalkınması", 0.0, 3.0, 1.0, 1.0]]


func _fill_cabev() -> void:
	var box: VBoxContainer = _sections["cabev"]
	if not d.has("cab_events"):
		d["cab_events"] = []
	var tip := TK.t(Loc.t("Belirli bir haftada seçtiğin bakan kapıdan girer ve oyuncuya senin yazdığın soruyu sorar. Cevap seçeneklerini, her cevabın sonucunu ve etkisini sen yazarsın."), "small", TK.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var arr: Array = d["cab_events"]
	arr.sort_custom(func(a, b): return int(a["turn"]) < int(b["turn"]))
	for i in arr.size():
		var e: Dictionary = arr[i]
		var idx: int = i
		var who: String = String(e.get("who", ""))
		var rt: String = String(e.get("role_text", ""))
		if rt == "":
			for r in ROLES:
				if r[0] == e.get("role", "def"):
					rt = Loc.t(r[1])
		var line := "%s %d · %s%s\n   “%s”\n   %s" % [Loc.t("Hafta"), int(e["turn"]), rt, (" (" + who + ")") if who != "" else "", String(e["q"]).substr(0, 90),
			" / ".join((e["o"] as Array).map(func(o): return String(o["t"])))]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		var l := TK.t(line, "body", TK.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(l)
		hb.add_child(_small_btn("Düzenle", func(): _cabev_form(idx), ""))
		var x := TK.button("Sil", "danger", "", Vector2(90, 48), 16)
		x.pressed.connect(func():
			arr.remove_at(idx)
			_refill("cabev", _fill_cabev))
		hb.add_child(x)
		box.add_child(hb)
	if arr.size() < 30:
		box.add_child(_small_btn("Yeni kabine olayı yaz", func(): _cabev_form(-1), "gold"))


func _cabev_form(idx: int) -> void:
	var arr: Array = d["cab_events"]
	var e: Dictionary = (arr[idx] as Dictionary).duplicate(true) if idx >= 0 else {"turn": 12, "role": "def", "who": "", "role_text": "", "q": "", "o": [{"t": "", "r": "", "e": {}}, {"t": "", "r": "", "e": {}}]}
	var sh = Sheet.open(root, Loc.t("Kabine olayı"), 880, true, true, Loc.t("Bakan soruyor, sen cevaplıyorsun"))
	var wk := SpinBox.new()
	wk.min_value = 0
	wk.max_value = 520
	wk.value = int(e["turn"])
	wk.prefix = Loc.t("Hafta") + " "
	wk.custom_minimum_size = Vector2(0, 52)
	sh.body.add_child(wk)
	var role := OptionButton.new()
	role.custom_minimum_size = Vector2(0, 52)
	for k in ROLES.size():
		role.add_item(Loc.t(ROLES[k][1]))
		if ROLES[k][0] == e["role"]:
			role.select(k)
	sh.body.add_child(role)
	var who := _line("Bakanın adı (boşsa kabinedeki bakan)", 40, String(e["who"]))
	sh.body.add_child(who)
	var rtxt := _line("Unvan (boşsa bakanlığın adı; ör. Genelkurmay Başkanı)", 40, String(e["role_text"]))
	sh.body.add_child(rtxt)
	var q := TextEdit.new()
	q.placeholder_text = Loc.t("Bakanın oyuncuya sorduğu / anlattığı metin")
	q.text = String(e["q"])
	q.custom_minimum_size = Vector2(0, 120)
	q.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	sh.body.add_child(q)
	var opts: Array = e["o"]
	var opt_ui: Array = []
	for oi in 4:
		var o: Dictionary = opts[oi] if oi < opts.size() else {"t": "", "r": "", "e": {}}
		sh.body.add_child(TK.t("%s %d%s" % [Loc.t("Cevap"), oi + 1, "" if oi < 2 else " (" + Loc.t("isteğe bağlı") + ")"], "kicker", TK.GOLD))
		var bt := _line("Düğme yazısı (ör. Kabul et)", 40, String(o["t"]))
		sh.body.add_child(bt)
		var rs := _line("Seçilince çıkan sonuç metni", 300, String(o.get("r", "")))
		sh.body.add_child(rs)
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 10)
		fl.add_theme_constant_override("v_separation", 6)
		var spins := {}
		for row in EFF_ROWS:
			var cell := HBoxContainer.new()
			cell.add_theme_constant_override("separation", 4)
			cell.add_child(TK.t(Loc.t(row[1]), "small", TK.MUTED))
			var sp := SpinBox.new()
			sp.min_value = row[2]
			sp.max_value = row[3]
			sp.step = row[4]
			var cur: float = float((o.get("e", {}) as Dictionary).get(row[0], 0.0))
			sp.value = cur / float(row[5])
			sp.custom_minimum_size = Vector2(110, 44)
			cell.add_child(sp)
			fl.add_child(cell)
			spins[row[0]] = [sp, float(row[5])]
		sh.body.add_child(fl)
		opt_ui.append([bt, rs, spins])
	sh.add_button("Kaydet", func():
		if q.text.strip_edges() == "":
			_msg.text = Loc.t("Bakanın sorusunu yaz.")
			return
		var out_o: Array = []
		for ui_o in opt_ui:
			if ui_o[0].text.strip_edges() == "":
				continue
			var eff := {}
			for k in ui_o[2]:
				var v: float = float(ui_o[2][k][0].value) * float(ui_o[2][k][1])
				if absf(v) > 0.00001:
					eff[k] = v
			out_o.append({"t": ui_o[0].text.strip_edges(), "r": ui_o[1].text.strip_edges(), "e": eff})
		if out_o.is_empty():
			_msg.text = Loc.t("En az bir cevap seçeneği yaz.")
			return
		var ne := {"turn": int(wk.value), "role": ROLES[role.selected][0], "who": who.text.strip_edges(), "role_text": rtxt.text.strip_edges(), "q": q.text.strip_edges(), "o": out_o}
		_msg.text = ""
		if idx >= 0:
			arr[idx] = ne
		else:
			arr.append(ne)
		_refill("cabev", _fill_cabev), "gold", true, "check", 150)
	sh.add_button("Vazgeç", func(): pass, "", true, "x", 130)


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
	var yv: int = int(_year_spin.value)
	if yv >= 1 and String(d.get("era", "")) == "":
		d["year"] = maxi(yv, 2024)
	else:
		d.erase("year")
	if d.get("transfer", []).is_empty():
		d.erase("transfer")
	if d.get("garrison", []).is_empty():
		d.erase("garrison")
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
	if d.get("events", []).is_empty():
		d.erase("events")
	for k2 in ["custom", "cab_events"]:
		if d.has(k2) and (d[k2] as Array).is_empty():
			d.erase(k2)
	for k3 in ["rename", "weapons", "cats", "inv", "tech", "doctrine", "cab_names"]:
		if d.has(k3) and (d[k3] as Dictionary).is_empty():
			d.erase(k3)
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
