extends RefCounted
const PickButton = preload("res://scripts/pick_button.gd")
const Minigames = preload("res://scripts/minigames.gd")
## Hikâye Modu arayüzü: çağ seçimi → hükümdar/tımar/karakter kurulumu → Divan paneli → hikâye kartları.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Icons = preload("res://scripts/icons.gd")
const SceneArt = preload("res://scripts/scene_art.gd")
const Career = preload("res://scripts/career.gd")
const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const AP = preload("res://scripts/ap.gd")
const ApUi = preload("res://scripts/ap_ui.gd")

## Hikâye kipinin sahne adları (çağ "pre" değilse modern karşılığı)
static func scene(k: String) -> String:
	if Eras.family() == "pre":
		return k
	return {"pre_court": "alliance", "pre_oath": "alliance", "pre_fief": "trade", "pre_rebel": "war", "pre_camp": "assault", "pre_siege": "barrage",
		"pre_tribute": "trade", "pre_assault": "assault", "pre_border": "border", "pre_spy": "spy", "pre_alliance": "alliance"}.get(k, k)


# ------------------------------------------------------------ 1) çağ seçimi
static func open_era(parent: Node, on_pick: Callable) -> void:
	var sh = Sheet.open(parent, "Hikâye Modu", 900, true, true, "Kariyer")
	sh.set_icon("mode_story", "book")
	var intro := TK.t("Bir devletin başına değil, bir komutanın yerine geç. Hükümdarına hizmet et, tımar kazan, ordunu büyüt; sonra ister sadık kal, ister başka hükümdara yemin et, ister isyan bayrağı aç ve kendi devletini kur. Hangi çağda?", "body", TK.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(intro)
	var eras: Array = [{"id": "", "name": "Modern Dünya", "sub": "2027", "blurb": "Bir bölge valisi olarak başla."}]
	eras.append_array(Eras.all())
	for e in eras:
		var eid: String = String(e.get("id", ""))
		if eid.begins_with("alt_"):
			continue
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 0)
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_top = 6
		hb.offset_bottom = -6
		hb.offset_right = -12
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_theme_constant_override("separation", 14)
		var ban = SceneArt.make(SceneArt.era_scene(eid) if eid != "" else "era_modern", 0.0)
		ban.custom_minimum_size = Vector2(230, 0)
		ban.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		ban.size_flags_vertical = Control.SIZE_FILL
		hb.add_child(ban)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(TK.t(String(e.get("sub", "")), "kicker", TK.GOLD))
		tv.add_child(TK.t(String(e.get("name", "")), "caps", TK.TEXT))
		var bl := TK.t(String(e.get("blurb", "")).split(". ")[0].left(100), "small", TK.MUTED)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(bl)
		hb.add_child(tv)
		if eid != "" and not AP.era_unlocked(eid):
			var lk := TK.stamp("Kilitli", TK.RED_TEXT)
			lk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(lk)
		b.add_child(hb)
		b.custom_minimum_size = Vector2(0, 130)
		b.pressed.connect(func():
			if eid != "" and not AP.era_unlocked(eid):
				return
			sh.close()
			on_pick.call(eid))
		sh.body.add_child(b)
	sh.add_button("Kapat", func(): pass, "", true, "", 160)


# ------------------------------------------------------------ 2) hükümdar / tımar / karakter
static func open_setup(parent: Node, gs, era_id: String, on_start: Callable, on_cancel: Callable) -> void:
	var sh = Sheet.open(parent, "Komutanını yarat", 940, true, true, "Hikâye Modu")
	sh.on_cancel = on_cancel
	var p := {"host_en": "", "pid": -1, "name": "", "bg": "cavalry", "female": false}
	sh.body.add_child(SceneArt.make(scene("pre_court"), 120))
	# --- hükümdar
	sh.body.add_child(TK.t("Hizmet edeceğin hükümdar", "kicker", TK.GOLD))
	var suggest: Array = Eras.get_era(era_id).get("suggest", []) if era_id != "" else ["Turkey", "Germany", "France", "United Kingdom", "Russia", "China", "United States of America", "Japan"]
	var hosts: Array = []
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.prov_owned < 4 or c.name_en.begins_with("faction_"):
			continue
		hosts.append(c)
	hosts.sort_custom(func(a, b):
		var ia: int = suggest.find(a.name_en)
		var ib: int = suggest.find(b.name_en)
		if (ia >= 0) != (ib >= 0):
			return ia >= 0
		if ia >= 0 and ib >= 0:
			return ia < ib
		return a.prov_owned > b.prov_owned)
	var search := LineEdit.new()
	search.placeholder_text = Loc.t("Devlet ara...")
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(0, 52)
	sh.body.add_child(search)
	var host_ob := PickButton.new()
	host_ob.title = Loc.t("Hükümdar seç")
	host_ob.custom_minimum_size = Vector2(0, 52)
	sh.body.add_child(host_ob)
	var fief_lbl := TK.t("Tımarın", "kicker", TK.GOLD)
	sh.body.add_child(fief_lbl)
	var fief_ob := PickButton.new()
	fief_ob.title = Loc.t("Tımar seç")
	fief_ob.custom_minimum_size = Vector2(0, 52)
	sh.body.add_child(fief_ob)
	var fief_hint := TK.t("", "small", TK.MUTED)
	fief_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(fief_hint)
	var fill_fiefs := func():
		fief_ob.clear()
		var host: int = int(gs.macro_idx.get(String(p.host_en), -1))
		if host < 0:
			return
		var hc = gs.countries[host]
		var ld: Array = Macro.leader_of(hc)
		fief_hint.text = Loc.t("%s %s (%d eyalet). Tımar: sınırdaki orta boy bir eyalet; başkent verilmez.") % [ld[0], ld[1], hc.prov_owned]
		var first := -1
		for pid in Career.pick_fiefs(gs, host):
			var pv = gs.provinces[pid]
			fief_ob.add_item("%s  (%s milyon)" % [pv.name, "%.1f" % pv.pop])
			fief_ob.set_item_metadata(fief_ob.item_count - 1, pid)
			if first < 0:
				first = pid
		p.pid = first
		if fief_ob.item_count > 0:
			fief_ob.select(0)
	var fill_hosts := func(q: String):
		host_ob.clear()
		var n := 0
		var sel := -1
		for c in hosts:
			if q != "" and not c.name.to_lower().contains(q.to_lower()):
				continue
			host_ob.add_item("%s  (%d eyalet)" % [c.name, c.prov_owned])
			host_ob.set_item_metadata(n, c.name_en)
			if c.name_en == String(p.host_en):
				sel = n
			n += 1
		if n > 0:
			host_ob.select(maxi(sel, 0))
			p.host_en = String(host_ob.get_item_metadata(host_ob.selected))
			fill_fiefs.call()
	fill_hosts.call("")
	search.text_changed.connect(func(q: String): fill_hosts.call(q))
	host_ob.item_selected.connect(func(_i):
		p.host_en = String(host_ob.get_item_metadata(host_ob.selected))
		fill_fiefs.call())
	fief_ob.item_selected.connect(func(_i): p.pid = int(fief_ob.get_item_metadata(fief_ob.selected)))
	# --- karakter
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Komutan", "kicker", TK.GOLD))
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 8)
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = Loc.t("Ad (boş: rastgele)")
	name_edit.max_length = 24
	name_edit.custom_minimum_size = Vector2(0, 52)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(t: String): p.name = t)
	nrow.add_child(name_edit)
	var gb := TK.button("Erkek", "gold", "", Vector2(130, 52), 15)
	gb.pressed.connect(func():
		p.female = not bool(p.female)
		gb.text = TK.up(Loc.t("Kadın" if p.female else "Erkek")))
	nrow.add_child(gb)
	sh.body.add_child(nrow)
	sh.body.add_child(TK.t("Kökenin", "kicker", TK.GOLD))
	var bg_btns: Array = []
	for b in Career.BACKGROUNDS:
		var bid: String = String(b.id)
		var bb := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 0)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -14
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tl := TK.t(String(b.t), "bodyb", TK.TEXT)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tl)
		var dl := TK.t(String(b.d), "small", TK.MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(dl)
		bb.add_child(v)
		bb.custom_minimum_size = Vector2(0, 66)
		bg_btns.append([bb, bid, tl])
		bb.pressed.connect(func():
			p.bg = bid
			for e in bg_btns:
				(e[2] as Label).add_theme_color_override("font_color", TK.GOLD if e[1] == bid else TK.TEXT))
		sh.body.add_child(bb)
	(bg_btns[0][2] as Label).add_theme_color_override("font_color", TK.GOLD)
	sh.add_button("Vazgeç", func(): on_cancel.call(), "ghost", true, "", 160)
	sh.add_button("Hikâyeye başla", func(): on_start.call(p), "gold", true, "play", 240)


# ------------------------------------------------------------ 3) Divan paneli
static func _bar(label: String, v: float, col: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := TK.t(label, "small", TK.MUTED)
	l.custom_minimum_size = Vector2(120, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var bg := PanelContainer.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.custom_minimum_size = Vector2(0, 14)
	bg.add_theme_stylebox_override("panel", TK.box(Color(0, 0, 0, 0.35), TK.LINE, 2, 1, 0, Vector4(0, 0, 0, 0)))
	var fill := ColorRect.new()
	fill.color = col
	fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fill.custom_minimum_size = Vector2(0, 10)
	bg.add_child(fill)
	bg.resized.connect(func(): fill.custom_minimum_size = Vector2(maxf(0.0, (bg.size.x - 4.0) * clampf(v, 0.0, 100.0) / 100.0), 10))
	h.add_child(bg)
	var vl := TK.t("%d" % int(v), "mono", TK.TEXT)
	vl.custom_minimum_size = Vector2(40, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(vl)
	return h


static func fill_panel(sh, gs, toast: Callable, reopen: Callable, focus: Callable = Callable()) -> void:
	var s: Dictionary = gs.career
	var mc = gs.countries[gs.player]
	var st: String = Career.state(gs)
	var head_scene: String = {"vassal": "pre_fief", "rebel": "pre_rebel", "independent": "pre_oath", "sovereign": "pre_court", "independent_pending": "pre_camp"}.get(st, "pre_fief")
	sh.body.add_child(SceneArt.make(scene(head_scene), 130))
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 12)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", -2)
	tv.add_child(TK.t(Career.rank_name(int(s.rank)), "kicker", TK.GOLD))
	tv.add_child(TK.t(String(s.name), "h2", TK.TEXT))
	var st_txt: String = {"vassal": "%s hizmetinde" % (gs.countries[int(s.host)].name if int(s.host) >= 0 else "?"), "rebel": "İSYANDA", "independent": "Bağımsız hükümdar", "sovereign": "HÜKÜMDAR", "independent_pending": "Barış yapıldı: devletini ilan et"}.get(st, "")
	tv.add_child(TK.t(st_txt, "small", TK.MUTED))
	hr.add_child(tv)
	var ch: Array = Career.CHAPTERS[clampi(int(s.chapter), 0, 4)]
	hr.add_child(TK.stamp(String(ch[0]).split(":")[0], TK.GOLD))
	sh.body.add_child(hr)
	sh.body.add_child(_bar("İtibar", float(s.renown), TK.GOLD))
	if st == "vassal":
		sh.body.add_child(_bar("Hükümdar gözü", float(s.favor), TK.GREEN))
		sh.body.add_child(_bar("Sadakat", float(s.loyalty), TK.BLUE))
	var mis: String = Career.mission_text(gs)
	sh.body.add_child(TK.hsep())
	if mis != "":
		var m: Dictionary = s.mission
		var mr := HBoxContainer.new()
		mr.add_theme_constant_override("separation", 10)
		var iv := TK.IconView.new()
		iv.icon = "target"
		iv.color = TK.GOLD
		iv.custom_minimum_size = Vector2(36, 36)
		mr.add_child(iv)
		var ml := TK.t("%s: %s  (%d hafta)" % [Loc.t("Görev"), mis, maxi(0, int(m.until) - gs.turn)], "body", TK.TEXT)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mr.add_child(ml)
		if int(m.get("target", -1)) >= 0 and focus.is_valid():
			var fb := TK.button("Göster", "ghost", "map", Vector2(120, 44), 13)
			fb.pressed.connect(func(): focus.call(int(m.target)))
			mr.add_child(fb)
		if String(m.id) == "tribute" and not bool(m.get("paid", false)):
			var pb := TK.button("Öde", "gold", "coins", Vector2(120, 44), 13)
			pb.disabled = mc.gold < float(m.amount)
			pb.pressed.connect(func():
				mc.gold -= float(m.amount)
				gs.countries[int(s.host)].gold += float(m.amount)
				m["paid"] = true
				reopen.call())
			mr.add_child(pb)
		sh.body.add_child(mr)
	elif st == "vassal":
		sh.body.add_child(TK.t("Yeni görev %d hafta içinde gelir." % maxi(0, int(s.next_mission) - gs.turn), "small", TK.FAINT))
	# eylemler
	sh.body.add_child(TK.t("Divan", "kicker", TK.GOLD))
	for a in Career.actions(gs):
		var aid: String = String(a.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var ai := TK.IconView.new()
		ai.icon = Icons.pick(String(a.icon), "flag")
		ai.color = Color.WHITE
		ai.custom_minimum_size = Vector2(40, 40)
		ai.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ai)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", -2)
		v.add_child(TK.t(String(a.t), "bodyb", TK.TEXT))
		var dl := TK.t(String(a.d), "small", TK.MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(dl)
		row.add_child(v)
		var cd: int = int(a.cd)
		var kind: String = "danger" if aid in ["rebel", "oath"] else ("gold" if aid in ["throne", "declare", "ask_indep"] else "")
		var b := TK.button("%d hf" % cd if cd > 0 else "Yap", kind, "", Vector2(110, 48), 14)
		b.disabled = cd > 0 or not bool(a.ok)
		b.pressed.connect(func():
			if aid == "oath":
				_pick_oath(sh.get_parent(), gs, toast, reopen)
				sh.close()
				return
			if aid in ["rebel", "throne", "declare", "ask_indep"]:
				_confirm(sh.get_parent(), gs, a, toast, reopen)
				sh.close()
				return
			var err: String = Career.do_action(gs, aid)
			if err != "":
				toast.call(err)
			reopen.call())
		row.add_child(b)
		sh.body.add_child(row)
	# rakipler
	if st == "vassal":
		sh.body.add_child(TK.hsep())
		sh.body.add_child(TK.t("Saraydaki beyler", "kicker", TK.GOLD))
		for r in s.rivals:
			if not bool(r.alive):
				continue
			var rr := HBoxContainer.new()
			rr.add_theme_constant_override("separation", 8)
			var nl := TK.t(String(r.n), "body", TK.TEXT)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rr.add_child(nl)
			rr.add_child(TK.stamp("İtibar %d" % int(r.renown), TK.MUTED))
			rr.add_child(TK.stamp("Göz %d" % int(r.favor), TK.GREEN if float(r.favor) < float(s.favor) else TK.RED_TEXT))
			if bool(r.hostile):
				rr.add_child(TK.stamp("Düşman", TK.RED_TEXT))
			sh.body.add_child(rr)
	# günlük
	var lg: Array = s.get("log", [])
	if not lg.is_empty():
		sh.body.add_child(TK.hsep())
		sh.body.add_child(TK.t("Vakayiname", "kicker", TK.GOLD))
		for i in range(maxi(0, lg.size() - 6), lg.size()):
			var e: Array = lg[i]
			sh.body.add_child(TK.t("• %s" % String(e[1]), "small", TK.MUTED))


static func _pick_oath(parent: Node, gs, toast: Callable, reopen: Callable) -> void:
	var sh = Sheet.open(parent, "Kime yemin edeceksin?", 700, true, true, "Yemin")
	sh.body.add_child(SceneArt.make(scene("pre_oath"), 120))
	var w := TK.t("Komşu bir hükümdara biat edersin: tımarın kalır, yeni hükümdar seni korur. Eski hükümdar bunu ihanet sayar ve savaş ilan eder.", "small", TK.MUTED)
	w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(w)
	for cid in Career.oath_targets(gs):
		var c = gs.countries[cid]
		var b := TK.button("%s  (%d eyalet, %s)" % [c.name, c.prov_owned, Macro.num(c.troops)], "", "handshake", Vector2(0, 56), 15)
		b.pressed.connect(func():
			var err: String = Career.do_action(gs, "oath", cid)
			if err != "":
				toast.call(err)
			sh.close()
			reopen.call())
		sh.body.add_child(b)
	sh.add_button("Vazgeç", func(): reopen.call(), "ghost", true, "", 160)


static func _confirm(parent: Node, gs, a: Dictionary, toast: Callable, reopen: Callable) -> void:
	var sh = Sheet.open(parent, String(a.t), 640, false, true, "Divan")
	sh.body.add_child(SceneArt.make(scene(String(a.scene)), 130))
	var txt: String = {"rebel": "İsyan ettiğinde hükümdar bütün ordusuyla üstüne gelir. Tımar halkı sana katılır, ama arkanda kimse kalmaz. Kazanırsan ya barış yapıp devletini ilan edersin ya da başkenti alıp tahta çıkarsın.",
		"throne": "Başkent elinde. Tahta çıkarsan hükümdarın bütün toprakları, orduları ve düşmanları senin olur.",
		"declare": "İsyan bitti. Devletini ilan ettiğinde 52 hafta ayakta kalmalısın (en az 6 eyalet).",
		"ask_indep": "Huzura çıkıp barışçıl ayrılık isteyeceksin. Hükümdar kabul ederse müttefik olarak ayrılırsın; reddederse gözden düşersin."}.get(String(a.id), String(a.d))
	sh.add_text(txt)
	sh.add_button("Vazgeç", func(): reopen.call(), "ghost", true, "", 160)
	sh.add_button(String(a.t), func():
		var err: String = Career.do_action(gs, String(a.id))
		if err != "":
			toast.call(err)
		reopen.call(), "danger" if String(a.id) == "rebel" else "gold", true, "", 220)


# ------------------------------------------------------------ 4) hikâye kartları (main._on_career_card çağırır)
## Dönen sözlük: {title, body, scene, icon, buttons:[{text, cb, kind}]}
static func _foe_name(gs, card_id: String) -> String:
	if card_id == "champion":
		return "Düşman pehlivanı"
	for r in gs.career.get("rivals", []):
		if bool(r.alive) and bool(r.hostile):
			return String(r.n)
	for r2 in gs.career.get("rivals", []):
		if bool(r2.alive):
			return String(r2.n)
	return "Rakip Bey"


static func card_spec(gs, after: Callable, ui = null) -> Dictionary:
	var pend: Dictionary = gs.career.get("pending", {})
	var kind: String = String(pend.get("kind", ""))
	var nm: String = String(gs.career.name)
	var sovn: String = Career.sov_name(gs)
	var done := func():
		gs.career["pending"] = {}
		after.call()
	match kind:
		"chapter":
			var ch: Array = Career.CHAPTERS[clampi(int(pend.idx), 0, 4)]
			return {"title": String(ch[0]), "body": String(ch[1]), "scene": scene(["pre_fief", "pre_camp", "pre_siege", "pre_court", "pre_oath"][clampi(int(pend.idx), 0, 4)]), "icon": "medal",
				"buttons": [{"text": "Devam", "cb": done, "kind": "good"}]}
		"mission":
			var m: Dictionary = pend.m
			return {"title": "Hükümdar emri: %s" % Loc.t(String(m.t)), "body": "%s, %s sana emir gönderdi:\n\n%s\n\nSüre: %d hafta. Başarı itibar ve gözde getirir; başarısızlık gözden düşürür." % [nm, sovn, String(m.text), int(m.until) - gs.turn],
				"scene": scene(String(m.scene)), "icon": "scroll", "buttons": [{"text": "Emredersiniz", "cb": done, "kind": "good"}]}
		"mission_done":
			var m2: Dictionary = pend.m
			return {"title": "Görev tamamlandı", "body": "%s görevi başarıyla bitti. Saray memnun: itibar +%d, hükümdar gözü +%d, ödül hazineye yattı." % [Loc.t(String(m2.t)), int(m2.renown), int(m2.favor)],
				"scene": scene("pre_tribute"), "icon": "medal", "buttons": [{"text": "Şanlı olsun", "cb": done, "kind": "good"}]}
		"call_to_arms":
			return {"title": "Savaşa çağrı", "body": "%s sefere çıkıyor ve bütün beylerini bayrak altına çağırıyor. Katılırsan hükümdarın düşmanları senin de düşmanın olur; katılmazsan sarayda hain diye anılırsın." % sovn,
				"scene": scene("pre_mobilize"), "icon": "sword", "buttons": [
					{"text": "Bayrak altına koş", "cb": func(): Career.answer_call(gs, true); after.call(), "kind": "good"},
					{"text": "Tımarımda kalırım", "cb": func(): Career.answer_call(gs, false); after.call(), "kind": "danger"}]}
		"summons":
			return {"title": "Huzura çağrıldın", "body": "%s sana güvenmiyor. Saraydan ulak geldi: 'Hükümdar seni huzuruna bekliyor.' Gidersen boyun eğeceksin; gitmezsen bu bir isyan sayılabilir." % sovn,
				"scene": scene("pre_court"), "icon": "warning", "buttons": [
					{"text": "Git, af dile", "cb": func(): Career.answer_summons(gs, 0); after.call(), "kind": ""},
					{"text": "Git, hediyelerle (%s)" % Macro.money(gs.countries[gs.player].income * 4.0), "cb": func(): Career.answer_summons(gs, 1); after.call(), "kind": "good"},
					{"text": "Gitme", "cb": func(): Career.answer_summons(gs, 2); after.call(), "kind": "danger"}]}
		"arrest":
			return {"title": "Tutuklama emri", "body": "Saray muhafızları tımarına doğru yola çıktı: 'Hain %s zincire vurulsun.' Kaçıp isyan bayrağı açabilirsin ya da teslim olursun." % nm,
				"scene": scene("pre_rebel"), "icon": "skull", "buttons": [
					{"text": "Kaç ve isyan et", "cb": func(): Career.answer_arrest(gs, true); after.call(), "kind": "danger"},
					{"text": "Teslim ol", "cb": func(): Career.answer_arrest(gs, false); after.call(), "kind": ""}]}
		"slander":
			return {"title": "Sarayda dedikodu", "body": "%s hükümdarın kulağına fısıldıyor: '%s gizlice ordu topluyor.' Gözden düştün." % [String(pend.r), nm],
				"scene": scene("pre_spy"), "icon": "spy", "buttons": [{"text": "Hesabını soracağım", "cb": done, "kind": ""}]}
		"oath":
			var c = gs.countries[int(pend.cid)]
			return {"title": "Yemin edildi", "body": "%s, %s hükümdarının önünde diz çöktü ve biat etti. Yeni sancaklar tımarında dalgalanıyor." % [nm, c.name],
				"scene": scene("pre_oath"), "icon": "handshake", "buttons": [{"text": "Devam", "cb": done, "kind": "good"}]}
		"rebel":
			return {"title": "İsyan!", "body": "Ferman yakıldı, kızıl sancak kaldırıldı. %s artık bir asi: %s bütün ordusuyla geliyor. Tımar halkı silaha sarıldı." % [nm, sovn],
				"scene": scene("pre_rebel"), "icon": "uprising_banner", "buttons": [{"text": "Ya devlet ya ölüm", "cb": done, "kind": "danger"}]}
		"rebel_peace":
			return {"title": "Barış", "body": "Eski hükümdar seninle barış yaptı. Artık Divan'dan devletini ilan edebilirsin.",
				"scene": scene("pre_peace"), "icon": "dove", "buttons": [{"text": "Devletimi ilan et", "cb": func(): gs.career.state = "rebel"; Career.do_action(gs, "declare"); after.call(), "kind": "good"},
					{"text": "Sonra", "cb": func(): gs.career["pending"] = {}; gs.career.state = "independent"; after.call(), "kind": ""}]}
		"independent":
			return {"title": "Yeni bir devlet", "body": "%s kuruldu. %s artık kimsenin vasalı değil. Bir yıl ayakta kal ve en az 6 eyalet tut: hanedanın tarihe geçsin." % [gs.countries[gs.player].name, nm],
				"scene": scene("pre_oath"), "icon": "founding_scroll", "buttons": [{"text": "Devam", "cb": done, "kind": "good"}]}
		"throne":
			return {"title": "Tahta çıktın", "body": "%s, %s tahtına oturdu. Dün hizmet ettiğin saray bugün senin. Hikâye burada bitmiyor: artık bir imparatorluğu yönetiyorsun." % [nm, gs.countries[gs.player].name],
				"scene": scene("pre_court"), "icon": "crown", "buttons": [{"text": "Uzun yaşa", "cb": done, "kind": "good"}]}
		"card":
			var c2: Dictionary = pend.card
			var btns: Array = []
			for i in c2.c.size():
				var idx: int = i
				if c2.c[i].size() > 2 and ui != null:
					var g: Dictionary = (c2.c[i][2] as Dictionary).duplicate()
					g["skill"] = clampf(float(gs.career.get("renown", 0.0)) / 100.0, 0.0, 1.0) * 0.8
					g["player"] = nm
					g["foe"] = _foe_name(gs, String(c2.id))
					btns.append({"text": String(c2.c[i][0]), "icon": "swords", "kind": "danger", "cb": func():
						Minigames.duel(ui, g, func(res: String, _info: Dictionary):
							Career.choose_game(gs, idx, res)
							after.call())})
				else:
					btns.append({"text": String(c2.c[i][0]), "cb": func(): Career.choose(gs, idx); after.call(), "kind": "good" if i == 0 else ""})
			return {"title": String(c2.t), "body": String(c2.b), "scene": scene(String(c2.scene)), "icon": "", "buttons": btns}
	return {}
