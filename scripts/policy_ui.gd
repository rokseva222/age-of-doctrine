extends RefCounted
const Loc = preload("res://scripts/loc.gd")
## Politika paneli: bütçe, doktrin, isimli silah alımı, envanter, ticaret/ambargo ve cepheler.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const Carriers = preload("res://scripts/carriers.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Emblem = preload("res://scripts/emblem.gd")

var ui
var gs
var sh
var content: VBoxContainer
var tab := 0
var cat := "tank"
var tab_btns: Array = []
var _draft: Dictionary = {}
var _draft_name := ""
var _editing := false
var _inv_filter := ""

const SceneArt = preload("res://scripts/scene_art.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Sil = preload("res://scripts/silhouette.gd")
const Names = preload("res://scripts/names.gd")
const TABS := [["Bütçe", "coins"], ["Silah Alımı", "tank"], ["Envanter", "shield"], ["Ticaret", "globe"], ["Cepheler", "swords"], ["İttifak", "handshake"], ["İstihbarat", "eye"], ["Kabine", "badge"]]
const CAT_ICON := {"inf": "rifle", "tank": "tank", "afv": "afv", "arty": "arty", "air": "jet", "sub": "sub"}
const TIER_COL := [Color("646c77"), Color("9aa2ad"), Color("5ba4e0"), Color("a98be0")]


static func open(ui_ref, gs_ref, start_tab: int = 0) -> void:
	var p = load("res://scripts/policy_ui.gd").new()
	p.ui = ui_ref
	p.gs = gs_ref
	p.tab = start_tab
	p._build()


func _pl():
	return gs.countries[gs.player]


func _build() -> void:
	var c = _pl()
	sh = ui._open_sheet("Politika", 1020, false, true, "Genel Kurmay  /  " + c.name)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	sh.body.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, clampf(ui.get_viewport().get_visible_rect().size.y * 0.56, 240.0, 520.0))
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	sh.body.add_child(scroll)
	for i in TABS.size():
		var idx := i
		var tb := TK.button(TABS[i][0], "ghost", TABS[i][1], Vector2(0, 56), 15)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(func():
			ui._click()
			tab = idx
			render())
		tabs.add_child(tb)
		tab_btns.append(tb)
	sh.add_button("Kapat", func(): pass, "", true, "x", 160)
	render()


func render() -> void:
	for ch in content.get_children():
		content.remove_child(ch)
		ch.queue_free()
	for i in tab_btns.size():
		TK.style_button(tab_btns[i], "gold" if tab == i else "ghost")
		var ivb = tab_btns[i].get_meta("iv_btn")
		ivb.color = TK.INK if tab == i else TK.MUTED
		ivb.queue_redraw()
	var banners := {1: "barrage", 3: "trade", 4: "cyber", 5: "alliance", 6: "spy"}
	if banners.has(tab):
		content.add_child(SceneArt.make(banners[tab], 120))
	match tab:
		0:
			_tab_budget()
		1:
			_tab_buy()
		2:
			_tab_inventory()
		3:
			_tab_trade()
		4:
			_tab_fronts()
		6:
			_tab_intel()
		7:
			_tab_cabinet()
		_:
			_tab_alliance()
	ui.refresh_top()


# ------------------------------------------------------------------ yardımcılar

func _kick(text: String, col: Color = TK.FAINT) -> Label:
	return TK.t(text, "kicker", col)


func _stat_row(items: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	var first := true
	for it in items:
		if not first:
			h.add_child(TK.vsep())
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 0 if first else 18)
		m.add_theme_constant_override("margin_right", 18)
		m.add_child(TK.stat(it[0], it[1], it[2] if it.size() > 2 else TK.TEXT))
		h.add_child(m)
		first = false
	return h


func _wrap(text: String, role: String = "small", col: Color = TK.MUTED) -> Label:
	var l := TK.t(text, role, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _toast(msg: String) -> void:
	ui.toast(msg)


# ------------------------------------------------------------------ 1) bütçe ve doktrin

func _tab_budget() -> void:
	var c = _pl()
	var f: Dictionary = c.fin if not c.fin.is_empty() else Macro.calc(gs, c)
	content.add_child(_kick("Haftalık mali tablo"))
	var net: float = f["net"]
	content.add_child(_stat_row([
		["Gelir", Macro.money(f["rev"]), TK.GOLD],
		["Ordu maaşı", Macro.money(f["wages"])],
		["Silah bakımı", Macro.money(f["upkeep"])],
		["Net hazine", ("+" if net >= 0.0 else "") + Macro.money(net), TK.GREEN if net >= 0.0 else TK.RED_TEXT],
	]))
	if f.get("covered", 0.0) > 0.0:
		content.add_child(_wrap("Ordu masrafları savunma payını aşıyor; fark %s diğer kalemlerden (hazine, sanayi…) kesiliyor." % Macro.money(f["covered"]), "small", TK.ORANGE))
	content.add_child(TK.hsep())
	content.add_child(_kick("Bütçe dağılımı (gelirin yüzdesi)"))
	var rows: Dictionary = {}
	var refresh_rows := func():
		var fin: Dictionary = Macro.calc(gs, c)
		for k in Macro.BUDGET_KEYS:
			var r: Dictionary = rows[k]
			r["slider"].set_value_no_signal(float(c.budget[k]))
			r["pct"].text = Loc.pct(int(c.budget[k]))
			r["money"].text = Macro.money(fin["rev"] * float(c.budget[k]) / 100.0) + Loc.t("/hf")
	for k in Macro.BUDGET_KEYS:
		var key: String = k
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var bic := TK.IconView.new()
		bic.icon = {"mil": "shield_star", "ind": "industry", "cyber": "hacker", "logi": "truck", "stab": "stability", "res": "bank"}.get(key, "coins")
		bic.color = Color.WHITE
		bic.custom_minimum_size = Vector2(40, 40)
		bic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bic)
		var nv := VBoxContainer.new()
		nv.custom_minimum_size = Vector2(260, 0)
		nv.add_theme_constant_override("separation", -2)
		nv.add_child(TK.t(Macro.BUDGET_NAMES[key], "bodyb"))
		var hint := TK.t(Macro.BUDGET_HINT[key], "small", TK.FAINT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nv.add_child(hint)
		row.add_child(nv)
		var sl := HSlider.new()
		sl.min_value = 0
		sl.max_value = 70
		sl.step = 1
		sl.value = c.budget[key]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		TK.style_slider(sl)
		row.add_child(sl)
		var pl := TK.t("", "value", TK.TEXT)
		pl.custom_minimum_size = Vector2(84, 0)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(pl)
		var ml := TK.t("", "mono", TK.GOLD)
		ml.custom_minimum_size = Vector2(190, 0)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(ml)
		rows[key] = {"slider": sl, "pct": pl, "money": ml}
		sl.value_changed.connect(func(v: float):
			Macro.set_budget(c, key, int(v))
			refresh_rows.call())
		content.add_child(row)
	refresh_rows.call()
	content.add_child(TK.hsep())
	content.add_child(_kick("Durum göstergeleri"))
	content.add_child(_stat_row([
		["Sanayi", "%d" % int(c.industry)],
		["Siber", "%d" % int(c.cyber)],
		["Lojistik", "%d" % int(c.logistics)],
		["İstikrar", "%d" % int(c.stability), TK.GREEN if c.stability >= 50.0 else TK.RED_TEXT],
		["Teknoloji", "%d" % int(c.tech * 100.0)],
	]))
	content.add_child(TK.hsep())
	content.add_child(_kick("Ordu doktrini"))
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	var dl := _wrap("", "small", TK.MUTED)
	for i in Macro.DOCTRINES.size():
		var idx := i
		var d: Dictionary = Macro.DOCTRINES[i]
		var b := TK.button(d["name"], "gold" if c.doctrine == i else "", "", Vector2(0, 52), 15)
		b.pressed.connect(func():
			ui._click()
			var err: String = Macro.set_doctrine(gs, c, idx)
			if err != "":
				_toast(err)
			else:
				_toast("Doktrin değişti: " + Macro.DOCTRINES[idx]["name"])
			render())
		fl.add_child(b)
	content.add_child(fl)
	dl.text = Macro.DOCTRINES[c.doctrine]["desc"]
	content.add_child(dl)
	var wait: int = Macro.DOCTRINE_COOLDOWN - (gs.turn - c.doctrine_turn)
	var note := "Doktrin değiştirme bedeli %s; ardından %d hafta beklenir." % [Macro.money(Macro.doctrine_cost(gs, c)), Macro.DOCTRINE_COOLDOWN]
	if wait > 0 and c.doctrine_turn > -50:
		note = "Yeni doktrin için %d hafta beklemelisin." % wait
	content.add_child(_wrap(note, "small", TK.FAINT))


# ------------------------------------------------------------------ 2) silah alımı

func _stars(t: int) -> PanelContainer:
	return TK.stamp("T%d" % t, TIER_COL[t - 1])


func _tab_buy() -> void:
	var c = _pl()
	content.add_child(_stat_row([
		["Savunma fonu", Macro.money(c.fund), TK.GOLD],
		["Hazine", Macro.money(c.gold), TK.GOLD],
		["Bekleyen sipariş", "%d" % c.orders.size()],
	]))
	var cf := HFlowContainer.new()
	cf.add_theme_constant_override("h_separation", 6)
	cf.add_theme_constant_override("v_separation", 6)
	for k in Arsenal.CATS:
		var key2: String = k
		var cb := TK.button(Arsenal.CAT_NAME[key2], "gold" if cat == key2 else "ghost", CAT_ICON[key2], Vector2(0, 52), 14)
		cb.pressed.connect(func():
			ui._click()
			cat = key2
			render())
		cf.add_child(cb)
	var pb := TK.button("Tedarik politikası", "gold" if cat == "policy" else "ghost", "gear", Vector2(0, 52), 14)
	pb.pressed.connect(func():
		ui._click()
		cat = "policy"
		render())
	cf.add_child(pb)
	content.add_child(cf)
	if cat == "policy":
		_buy_policy(c)
		return
	var step: int = int(Arsenal.CAT_STEP[cat])
	content.add_child(_wrap("Birim: %s. Fiyatlar yaklaşık, milyon $ cinsindendir. Yerli üretimde indirim ve kısa teslimat vardır." % Arsenal.CAT_UNIT[cat], "small", TK.FAINT))
	var lst: Array = Arsenal.list_cat(cat).duplicate()
	# kendi ülkenin ürettikleri ve alınabilir olanlar öne
	var rank_of := func(id: String) -> int:
		var r := 0
		if Arsenal.origin_of(id) != c.name_en:
			r += 2
		if Macro.availability(gs, c, id) != "":
			r += 1
		return r
	lst.sort_custom(func(a, b):
		var ra: int = rank_of.call(a)
		var rb: int = rank_of.call(b)
		if ra != rb:
			return ra < rb
		return Arsenal.tier_of(a) < Arsenal.tier_of(b))
	for id in lst:
		content.add_child(_item_row(c, id, step))
	if not c.orders.is_empty():
		content.add_child(TK.hsep())
		content.add_child(_kick("Teslimat bekleyenler"))
		for o in c.orders:
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 14)
			var nm := TK.t("%d × %s" % [o["qty"], Arsenal.name_of(o["id"])], "body")
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(nm)
			h.add_child(TK.t("%d hafta" % maxi(0, o["due"] - gs.turn), "mono", TK.MUTED))
			content.add_child(h)


func _buy_policy(c) -> void:
	content.add_child(TK.toggle_row("Otomatik silah tedariki", c.auto_buy, func(on: bool): c.auto_buy = on,
		"Açıkken savunma fonu, aşağıdaki öncelik ve doktrine göre kendiliğinden silah alır. Kapalıyken fon birikir; alımı sen yaparsın."))
	content.add_child(TK.hsep())
	content.add_child(_kick("Tedarik önceliği (otomatik alım)"))
	var pr := HFlowContainer.new()
	pr.add_theme_constant_override("h_separation", 8)
	pr.add_theme_constant_override("v_separation", 6)
	for k in Arsenal.CATS:
		var key: String = k
		var lvl: float = c.pri.get(key, 1.0)
		var name: String = ["Düşük", "Normal", "Yüksek"][0 if lvl < 0.8 else (1 if lvl < 1.6 else 2)]
		var b := TK.button("%s: %s" % [Arsenal.CAT_NAME[key], name], "ghost", CAT_ICON[key], Vector2(0, 52), 14)
		b.pressed.connect(func():
			ui._click()
			var cur: float = c.pri.get(key, 1.0)
			if cur < 0.8:
				c.pri[key] = 1.0
			elif cur < 1.6:
				c.pri[key] = 2.0
			else:
				c.pri[key] = 0.4
			render())
		pr.add_child(b)
	content.add_child(pr)
	content.add_child(_wrap("Öncelik, bir kategorinin eksik donanımına ne kadar pay ayrılacağını belirler. Hava-Kara doktrini uçak alımını, Asimetrik doktrin top/roketatarı öne çıkarır.", "small", TK.FAINT))


func _item_row(c, id: String, step: int) -> Control:
	var why: String = Macro.availability(gs, c, id)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", TK.line_box(Color(0, 0, 0, 0), TK.LINE))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	pc.add_child(h)
	h.add_child(_stars(Arsenal.tier_of(id)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", -2)
	var own: bool = Arsenal.origin_of(id) == c.name_en
	var origin_name: String = Arsenal.origin_of(id)
	if gs.macro_idx.has(origin_name):
		origin_name = gs.countries[gs.macro_idx[origin_name]].name
	v.add_child(TK.t(Arsenal.name_of(id), "bodyb", TK.TEXT if why == "" else TK.FAINT))
	var sub := "%s%s   /   teslim %d hf   /   elde %s" % [origin_name, " (yerli)" if own else "", Macro.lead_time(c, id), Macro.num(c.inv.get(id, 0))]
	if why != "":
		sub = why
	v.add_child(TK.t(sub, "small", TK.FAINT if why == "" else TK.RED_TEXT))
	h.add_child(v)
	var pr: float = Macro.price(c, id)
	var pl := TK.t("$%s mn" % (str(snappedf(pr, 0.1)).replace(".", ",") if pr < 100.0 else str(int(pr))), "mono", TK.GOLD)
	pl.custom_minimum_size = Vector2(120, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(pl)
	for mult in [1, 5]:
		var qty: int = step * mult
		var b := TK.button("+%d" % qty, "gold" if mult == 1 else "", "", Vector2(96, 52), 15)
		b.disabled = why != ""
		b.pressed.connect(func():
			ui._click()
			var err: String = Macro.buy(gs, c, id, qty)
			if err != "":
				_toast(err)
			else:
				_toast("Sipariş: %d × %s" % [qty, Arsenal.name_of(id)])
				if ui.sfx != null:
					ui.sfx.play("stamp", 0.9)
					ui.sfx.play("coin", 0.5)
			render())
		h.add_child(b)
	return pc


# ------------------------------------------------------------------ 3) envanter

func _carrier_row(c) -> void:
	content.add_child(TK.hsep())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var iv := TK.IconView.new()
	iv.icon = "ship"
	iv.color = Color.WHITE
	iv.custom_minimum_size = Vector2(38, 38)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(iv)
	var nm := TK.t("Uçak gemisi grubu", "caps", TK.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	h.add_child(TK.t(str(Carriers.count(c)), "value", TK.TEXT))
	content.add_child(h)
	content.add_child(_wrap("Çıkarma kapasitesini ve çıkarma saldırısını güçlendirir; kıyıdaki düşman eyaletlerini (ada ülkeleri dâhil) ordu göndermeden vurabilirsin. Satın alınanların bakım gideri vardır.", "small", TK.FAINT))
	var err: String = Carriers.can_buy(gs, c)
	var b := TK.button("Satın al: %s" % Macro.money(Carriers.cost(c)), "gold", "ship", Vector2(0, 56), 15)
	b.disabled = err != "" and not err.begins_with("Kasa")
	b.pressed.connect(func():
		var e2: String = Carriers.buy(gs)
		if e2 != "":
			ui.toast(e2)
		else:
			ui.toast("Yeni uçak gemisi grubu devrede.")
		render())
	content.add_child(b)
	content.add_child(TK.spacer(0, 6))


func _tab_inventory() -> void:
	var c = _pl()
	Macro.recalc(c)
	content.add_child(_stat_row([
		["Asker", Macro.num(c.troops)],
		["Hedef", Macro.num(Macro.troop_goal(c))],
		["Kara donanımı", "x%.2f" % c.eq_land],
		["Hava gücü", Macro.num(c.air_pow)],
		["Deniz gücü", Macro.num(c.naval_pow)],
	]))
	_carrier_row(c)
	content.add_child(_wrap("Hedef asker sayısı, savunma bütçesi ve savaş durumuna göre belirlenir; fark kendiliğinden askere alınır ve cephelere dağıtılır.", "small", TK.FAINT))
	for row in Macro.inventory_rows(c):
		if row["items"].is_empty():
			continue
		content.add_child(TK.hsep())
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 12)
		var iv := TK.IconView.new()
		iv.icon = CAT_ICON[row["cat"]]
		iv.color = Color.WHITE
		iv.custom_minimum_size = Vector2(38, 38)
		iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hh.add_child(iv)
		var ct := TK.t(Arsenal.CAT_NAME[row["cat"]], "caps", TK.TEXT)
		ct.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(ct)
		var unit := " set" if row["cat"] == "inf" else ""
		hh.add_child(TK.t(Macro.num(row["total"]) + unit, "value", TK.TEXT))
		content.add_child(hh)
		for id in row["items"]:
			var r := HBoxContainer.new()
			r.add_theme_constant_override("separation", 12)
			r.add_child(TK.spacer(38, 0))
			r.add_child(_stars(Arsenal.tier_of(id)))
			var nm := TK.t(Arsenal.name_of(id), "body", TK.TEXT)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(nm)
			r.add_child(TK.t(Macro.num(c.inv[id]), "mono", TK.TEXT))
			content.add_child(r)


# ------------------------------------------------------------------ 7) istihbarat

func _tab_cabinet() -> void:
	var c = _pl()
	content.add_child(_wrap("Bakanlar görev süresi dolunca, istifa edince ya da düşünce yerine 3 aday gelir: usta olan pahalı, acemi olan ucuz ama riskli. Kıdemli ve usta bakanlar her hafta küçük bir bonus verir.", "small", TK.FAINT))
	if c.cab.is_empty():
		Cabinet.init_cabinet(c, gs.turn)
	for role in Cabinet.APPOINT:
		if not c.cab.has(role):
			continue
		var e: Dictionary = c.cab[role]
		content.add_child(TK.hsep())
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var pt = Sil.new()
		pt.style = Sil.style_for(c)
		pt.culture = Sil.culture_for(c)
		pt.seed_name = e.n
		pt.female = e.f
		pt.role = role
		pt.tint = c.color
		pt.custom_minimum_size = Vector2(70, 84)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pt)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(TK.t(Cabinet.ROLE_TITLE[role], "kicker", TK.GOLD))
		tv.add_child(TK.t(e.n, "bodyb", TK.TEXT))
		var q: int = int(e.q)
		tv.add_child(_wrap(Cabinet.ROLE_FX[role][q], "small", TK.GREEN if q > 0 else TK.MUTED))
		h.add_child(tv)
		var rv := VBoxContainer.new()
		rv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rv.custom_minimum_size = Vector2(150, 0)
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_END
		stars.add_theme_constant_override("separation", 2)
		for i in 3:
			var st := TK.IconView.new()
			st.icon = "star"
			st.color = TK.GOLD if i <= q else Color(1, 1, 1, 0.14)
			st.custom_minimum_size = Vector2(22, 22)
			stars.add_child(st)
		rv.add_child(stars)
		var left: int = maxi(0, int(e.until) - gs.turn)
		var yl := TK.t("%s  ·  ~%.1f yıl" % [Cabinet.Q_NAME[q], float(left) / 52.0], "kicker", TK.MUTED)
		yl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rv.add_child(yl)
		h.add_child(rv)
		var fb := TK.button("Görevden al", "danger", "", Vector2(150, 48), 14)
		var rl: String = role
		fb.pressed.connect(func():
			ui._click()
			ui.show_dialog("Görevden alma", "%s görevden alınsın mı? İstikrar −2. Yerine bir sonraki bülten sonrasında 3 aday gelir." % e.n, [
				{"text": "Görevden al", "cb": func():
					Cabinet.dismiss(gs, rl)
					ui.toast("%s görevden alındı" % e.n), "kind": "danger"},
				{"text": "Vazgeç", "cb": func(): pass}]))
		h.add_child(fb)
		content.add_child(h)


func _tab_intel() -> void:
	var c = _pl()
	content.add_child(_wrap("Gizli harekâtlar savaş ilan etmeden rakibi zayıflatır. Başarı şansı siber gücüne ve teknolojine bağlıdır; yakalanırsan iç siyaset ve ilişkiler zarar görür. Her hedefte ajanların kısa süre saklanması gerekir.", "small", TK.FAINT))
	var cands: Array = []
	var seen := {}
	for j in c.enemies:
		if gs.countries[j].alive and not seen.has(j):
			cands.append(j)
			seen[j] = true
	var nbs: Array = gs.neighbor_countries(c.id)
	nbs.sort_custom(func(a, b): return gs.countries[a].income > gs.countries[b].income)
	for j in nbs:
		if gs.countries[j].alive and not seen.has(j) and cands.size() < 7:
			cands.append(j)
			seen[j] = true
	if cands.is_empty():
		content.add_child(_wrap("Henüz temas kurulabilecek komşu yok.", "body", TK.MUTED))
		return
	for j in cands:
		var o = gs.countries[j]
		content.add_child(TK.hsep())
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var fl := TK.flag_rect(o, Vector2(48, 32))
		fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fl)
		var nm := TK.t(o.name, "bodyb", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(nm)
		h.add_child(TK.t("istikrar %d  siber %d" % [int(o.stability), int(o.cyber)], "mono", TK.MUTED))
		if c.enemies.has(j):
			h.add_child(TK.stamp("Savaş", TK.RED))
		content.add_child(h)
		var ops := HBoxContainer.new()
		ops.add_theme_constant_override("separation", 10)
		var cd: int = c.covert_cd.get(j, -1) - gs.turn
		for kind in gs.COVERT:
			var def: Dictionary = gs.COVERT[kind]
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 3)
			var cost: float = gs.covert_cost(c, kind)
			var chance: float = gs.covert_chance(c, o, kind)
			var b := TK.button(def.name, "gold" if chance >= 0.5 else "ghost", def.icon, Vector2(0, 54), 14)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.disabled = cd > 0 or c.gold < cost or chance <= 0.0
			b.tooltip_text = def.desc
			var tg: int = j
			var kd: String = kind
			b.pressed.connect(func():
				ui._click()
				var r: Dictionary = gs.player_covert(tg, kd)
				ui.toast(r.text)
				ui.refresh_top()
				render())
			col.add_child(b)
			var info := "bekleme %d tur" % cd if cd > 0 else (("Bedel %s" % Macro.money(cost)) + ("  ·  şans %%%d" % int(chance * 100.0) if chance > 0.0 else ""))
			var il := TK.t(info, "small", TK.FAINT)
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(il)
			ops.add_child(col)
		content.add_child(ops)


# ------------------------------------------------------------------ 4) ticaret

func _tab_trade() -> void:
	var c = _pl()
	content.add_child(_stat_row([
		["Ticaret geliri", Macro.money(c.trade_income) + Loc.t("/hf"), TK.GOLD],
		["Açık ticaret", "%%%d" % int(c.trade_share * 100.0)],
		["Deniz ablukası", "%%%d" % int(c.blockade * 100.0), TK.RED_TEXT if c.blockade > 0.05 else TK.TEXT],
	]))
	if c.trade_block > 0:
		content.add_child(_wrap("Siber saldırı yüzünden dış ticaret %d hafta daha kesik." % c.trade_block, "small", TK.RED_TEXT))
	content.add_child(_wrap("Savaştaki ve ambargolu ülkelerle ticaret durur. Ambargo her iki tarafı da vurur; rakibini ekonomik olarak sıkıştırmak için kullan.", "small", TK.FAINT))
	content.add_child(TK.hsep())
	for e in c.partners:
		var j: int = e[0]
		var o = gs.countries[j]
		if not o.alive:
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var fl := TK.flag_rect(o, Vector2(48, 32))
		fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fl)
		var nm := TK.t(o.name, "bodyb", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(nm)
		h.add_child(TK.t("%%%d" % int(e[1] * 100.0), "mono", TK.MUTED))
		var st := "Açık"
		var col := TK.GREEN
		if c.enemies.has(j):
			st = "Savaş"
			col = TK.RED
		elif c.embargo.has(j):
			st = "Ambargo"
			col = TK.ORANGE
		elif o.embargo.has(c.id):
			st = "Ambargolu"
			col = TK.ORANGE
		elif o.trade_block > 0:
			st = "Kesinti"
			col = TK.PURPLE
		var sp := TK.stamp(st, col)
		sp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(sp)
		var on_emb: bool = c.embargo.has(j)
		var b := TK.button("Ambargoyu kaldır" if on_emb else "Ambargo koy", "ghost" if on_emb else "danger", "embargo", Vector2(210, 52), 14)
		b.disabled = c.enemies.has(j)
		b.pressed.connect(func():
			ui._click()
			if on_emb:
				c.embargo.erase(j)
			else:
				c.embargo.append(j)
				if not gs.is_allied(c.id, j):
					pass
			Macro.prime(gs)
			render())
		h.add_child(b)
		content.add_child(h)
		content.add_child(TK.hsep(0.5))


# ------------------------------------------------------------------ 5) cepheler

func _merc_section(c) -> void:
	content.add_child(_kick("Paralı asker"))
	content.add_child(_wrap("Özel şirketlerden süreli birlik kirala: ücret peşin ödenir, birlik boş bir cephe/başkent eyaletine yerleşir, sözleşme bitince dağılır. Adı ülkeni kültürüne göre rastgele gelir.", "small", TK.MUTED))
	for i in gs.MERC_TIERS.size():
		var ti: int = i
		var o: Dictionary = gs.merc_offer(c, ti)
		var can: bool = c.gold >= o.cost
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var ic := TK.IconView.new()
		ic.icon = ["recruit", "helmet", "special_forces"][ti]
		ic.color = TK.PAPER
		ic.custom_minimum_size = Vector2(44, 44)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v.add_theme_constant_override("separation", 0)
		v.add_child(TK.t(o.name, "bodyb", TK.TEXT))
		var dl := _wrap("%s asker  /  %d hf  /  %s" % [Macro.num(o.n), o.weeks, o.desc], "small", TK.MUTED)
		v.add_child(dl)
		h.add_child(v)
		var cost_l := TK.t(Macro.money(o.cost), "mono", TK.GOLD if can else TK.RED_TEXT)
		cost_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(cost_l)
		var b := TK.button("Kirala", "gold", "", Vector2(150, 52), 16)
		b.disabled = not can
		b.pressed.connect(func():
			ui._click()
			var r: Dictionary = gs.hire_merc(c.id, ti)
			if r.err != "":
				ui.toast(r.err)
			else:
				ui.toast("%s göreve başladı: %s (%s asker)" % [r.name, gs.provinces[r.prov].name, Macro.num(r.n)])
				ui.refresh_top()
			render())
		h.add_child(b)
		content.add_child(h)

func _tab_fronts() -> void:
	var c = _pl()
	content.add_child(TK.toggle_row("Ordular otomatik komuta edilsin", c.auto_cmd, func(on: bool): c.auto_cmd = on,
		"Açıkken kurmay, savaştığın düşmanın zayıf eyaletlerine kendiliğinden harekât düzenler. Kapalıyken ordulara haritadan sen emir verirsin."))
	content.add_child(TK.hsep())
	_merc_section(c)
	content.add_child(TK.hsep())
	if c.enemies.is_empty():
		content.add_child(_wrap("Şu an savaşta değilsin. Savaş ilan ettiğinde cepheler burada listelenir.", "body", TK.MUTED))
		return
	content.add_child(_kick("Cepheler"))
	for ej in c.enemies:
		var e: int = ej
		var o = gs.countries[e]
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", TK.box(TK.PANEL_LIGHT, TK.LINE, 2, 1, 0, Vector4(14, 10, 14, 10)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		box.add_child(v)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var fl := TK.flag_rect(o, Vector2(48, 32))
		fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fl)
		var nm := TK.t(o.name, "h3", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nm)
		v.add_child(h)
		v.add_child(_stat_row([
			["Düşman askeri", Macro.num(o.troops), TK.RED_TEXT],
			["Donanım", "x%.2f" % o.eq_land],
			["Hava", Macro.num(o.air_pow)],
			["Siber", "%d" % int(o.cyber)],
		]))
		var hb := HFlowContainer.new()
		hb.add_theme_constant_override("h_separation", 8)
		hb.add_theme_constant_override("v_separation", 8)
		var stn: String = Macro.stance(c, e)
		for sp in [["attack", "Taarruz", "sword"], ["defend", "Savunma", "shield"]]:
			var key: String = sp[0]
			var b := TK.button(sp[1], "gold" if stn == key else "ghost", sp[2], Vector2(180, 52), 15)
			b.pressed.connect(func():
				ui._click()
				Macro.set_front(c, e, "stance", key)
				render())
			hb.add_child(b)
		var cf: String = Macro.cyber_focus(c, e)
		var order: Array = ["auto", "industry", "logistics", "trade", "finance", "off"]
		var cb := TK.button("Siber: " + Macro.CYBER_NAMES[cf], "", "bolt", Vector2(240, 52), 15)
		cb.pressed.connect(func():
			ui._click()
			var nx: String = order[(order.find(cf) + 1) % order.size()]
			Macro.set_front(c, e, "cyber", nx)
			render())
		hb.add_child(cb)
		v.add_child(hb)
		content.add_child(box)


# ------------------------------------------------------------------ 6) ittifak

func _emblem_editor(em: Dictionary, on_change: Callable) -> Control:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	var prev := Emblem.new()
	prev.custom_minimum_size = Vector2(170, 170)
	prev.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	prev.set_emblem(em)
	root.add_child(prev)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	root.add_child(col)
	var refresh := func():
		prev.set_emblem(em)
		on_change.call()
	# şekil
	col.add_child(_kick("Şekil"))
	var f1 := HFlowContainer.new()
	f1.add_theme_constant_override("h_separation", 6)
	f1.add_theme_constant_override("v_separation", 6)
	for i in Emblem.SHAPES.size():
		var idx := i
		var b := TK.button(Emblem.SHAPES[i], "gold" if int(em["shape"]) == i else "ghost", "", Vector2(0, 52), 12)
		b.pressed.connect(func():
			ui._click()
			em["shape"] = idx
			refresh.call()
			render_keep())
		f1.add_child(b)
	col.add_child(f1)
	col.add_child(_kick("İç desen"))
	var f2 := HFlowContainer.new()
	f2.add_theme_constant_override("h_separation", 6)
	for i in Emblem.INNERS.size():
		var idx2 := i
		var b2 := TK.button(Emblem.INNERS[i], "gold" if int(em["inner"]) == i else "ghost", "", Vector2(0, 52), 12)
		b2.pressed.connect(func():
			ui._click()
			em["inner"] = idx2
			refresh.call()
			render_keep())
		f2.add_child(b2)
	col.add_child(f2)
	col.add_child(_kick("Simge"))
	var f3 := HFlowContainer.new()
	f3.add_theme_constant_override("h_separation", 6)
	f3.add_theme_constant_override("v_separation", 6)
	for sym in Emblem.SYMBOLS:
		var sy: String = sym
		var b3 := TK.icon_button(sy, 56, "gold" if em["symbol"] == sy else "ghost")
		b3.pressed.connect(func():
			ui._click()
			em["symbol"] = sy
			refresh.call()
			render_keep())
		f3.add_child(b3)
	col.add_child(f3)
	for ck in [["c1", "Ana renk"], ["c2", "Zemin ve simge"], ["c3", "Çizgi"]]:
		var key: String = ck[0]
		col.add_child(_kick(ck[1]))
		var fc := HFlowContainer.new()
		fc.add_theme_constant_override("h_separation", 6)
		fc.add_theme_constant_override("v_separation", 6)
		for hexc in Emblem.PALETTE:
			var hx: String = hexc
			var sw := Button.new()
			sw.custom_minimum_size = Vector2(44, 44)
			sw.focus_mode = Control.FOCUS_NONE
			var sel: bool = em[key] == hx
			var sb := TK.box(Color(hx), TK.PAPER if sel else TK.LINE, 2, 3 if sel else 1, 0, Vector4(0, 0, 0, 0))
			sw.add_theme_stylebox_override("normal", sb)
			sw.add_theme_stylebox_override("hover", sb)
			sw.add_theme_stylebox_override("pressed", sb)
			sw.pressed.connect(func():
				ui._click()
				em[key] = hx
				refresh.call()
				render_keep())
			fc.add_child(sw)
		col.add_child(fc)
	return root


## düzenleme sırasında sekmeyi, kaydırma konumunu bozmadan yeniden çiz
func render_keep() -> void:
	var sc: ScrollContainer = content.get_parent()
	var pos: int = sc.scroll_vertical
	render()
	await ui.get_tree().process_frame
	sc.scroll_vertical = pos


func _name_edit(initial: String, placeholder: String) -> LineEdit:
	var le := LineEdit.new()
	le.text = initial
	le.placeholder_text = placeholder
	le.max_length = 30
	le.custom_minimum_size = Vector2(0, 60)
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return le


func _tab_alliance() -> void:
	var c = _pl()
	var b: Dictionary = gs.bloc_get(c.alliance) if c.alliance >= 0 else {}
	if b.is_empty():
		_alliance_create(c)
		return
	# mevcut ittifak
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	var ev := Emblem.new()
	ev.custom_minimum_size = Vector2(110, 110)
	ev.set_emblem(b["emblem"])
	head.add_child(ev)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_theme_constant_override("separation", -4)
	tv.add_child(_kick("İttifakın"))
	tv.add_child(TK.t(b["name"], "h2", TK.TEXT))
	tv.add_child(TK.t("%d üye   /   kurucu: %s" % [b["members"].size(), gs.countries[b["founder"]].name], "small", TK.MUTED))
	head.add_child(tv)
	content.add_child(head)
	content.add_child(_wrap("Üyeler birbirine saldırmaz; biri saldırıya uğrayınca diğerleri çağrılır. Üyelerden biriyle savaşan ülke ittifaka katılamaz.", "small", TK.FAINT))
	content.add_child(TK.hsep())
	content.add_child(_kick("Üyeler"))
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 10)
	fl.add_theme_constant_override("v_separation", 10)
	for m in b["members"]:
		var mc = gs.countries[m]
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 8)
		var f := TK.flag_rect(mc, Vector2(40, 27))
		f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.add_child(f)
		chip.add_child(TK.t(mc.name, "body", TK.TEXT))
		chip.add_child(TK.spacer(10, 0))
		fl.add_child(chip)
	content.add_child(fl)
	content.add_child(TK.hsep())
	# ad ve amblem
	if _editing:
		if _draft.is_empty():
			_draft = (b["emblem"] as Dictionary).duplicate()
			_draft_name = b["name"]
		var le := _name_edit(_draft_name, "İttifak adı")
		le.text_changed.connect(func(t: String): _draft_name = t)
		content.add_child(le)
		content.add_child(_emblem_editor(_draft, func(): pass))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var sv := TK.button("Kaydet", "gold", "check", Vector2(180, 56), 15)
		sv.pressed.connect(func():
			ui._click()
			var nm: String = _draft_name.strip_edges()
			if nm.length() < 3:
				_toast("İttifak adı en az 3 harf olmalı.")
				return
			b["name"] = nm
			b["emblem"] = _draft.duplicate()
			_editing = false
			_draft = {}
			gs.state_changed.emit()
			render())
		hb.add_child(sv)
		var cn := TK.button("Vazgeç", "ghost", "x", Vector2(160, 56), 15)
		cn.pressed.connect(func():
			ui._click()
			_editing = false
			_draft = {}
			render())
		hb.add_child(cn)
		content.add_child(hb)
	else:
		var eb := TK.button("Adı ve amblemi düzenle", "", "gear", Vector2(0, 56), 15)
		eb.pressed.connect(func():
			ui._click()
			_editing = true
			_draft = {}
			render())
		content.add_child(eb)
	# davet
	content.add_child(TK.hsep())
	content.add_child(_kick("Yeni üye davet et"))
	var search := LineEdit.new()
	search.placeholder_text = "Ülke ara..."
	search.text = _inv_filter
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(0, 56)
	content.add_child(search)
	var listbox := VBoxContainer.new()
	listbox.add_theme_constant_override("separation", 0)
	content.add_child(listbox)
	var fill_list := func(q: String):
		for ch in listbox.get_children():
			listbox.remove_child(ch)
			ch.queue_free()
		var cands: Array = []
		var nb: Array = gs.neighbor_countries(c.id)
		for o in gs.countries:
			if not o.alive or o.is_rebel or o.id == c.id or o.alliance >= 0:
				continue
			if q != "" and not (o.name + " " + o.name_en).to_lower().contains(q.to_lower()):
				continue
			cands.append(o)
		cands.sort_custom(func(x, y):
			var nx: int = 1 if nb.has(x.id) else 0
			var ny: int = 1 if nb.has(y.id) else 0
			if nx != ny:
				return nx > ny
			return gs.power_of(x) > gs.power_of(y))
		for i in mini(cands.size(), 12):
			var o = cands[i]
			var oid: int = o.id
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 14)
			var f := TK.flag_rect(o, Vector2(48, 32))
			f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(f)
			var nm := TK.t(o.name, "bodyb", TK.TEXT)
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			h.add_child(nm)
			if nb.has(oid):
				h.add_child(TK.stamp("Komşu", TK.BLUE))
			var ib := TK.button("Davet et", "gold", "recruit", Vector2(150, 52), 14)
			ib.pressed.connect(func():
				ui._click()
				var err: String = gs.player_invite(oid)
				_toast(err if err != "" else "%s ittifaka katıldı." % gs.countries[oid].name)
				render_keep())
			h.add_child(ib)
			listbox.add_child(h)
			listbox.add_child(TK.hsep(0.5))
	fill_list.call(_inv_filter)
	search.text_changed.connect(func(t: String):
		_inv_filter = t
		fill_list.call(t))
	content.add_child(TK.hsep())
	var lv := TK.button("İttifaktan ayrıl", "danger", "retreat", Vector2(0, 56), 15)
	lv.pressed.connect(func():
		ui._click()
		gs.bloc_leave(c.id)
		_editing = false
		_draft = {}
		render())
	content.add_child(lv)


func _alliance_create(c) -> void:
	content.add_child(_wrap("Kendi ittifakını kur: ad ve amblemi sen belirle, sonra ülkeleri davet et. Oyun şu an duraklatıldıysa başlamadan da kurabilirsin.", "body", TK.MUTED))
	if _draft.is_empty():
		_draft = Emblem.default_emblem()
		_draft["c1"] = c.color.darkened(0.25).to_html(false)
		_draft["c3"] = _draft["c1"]
		_draft_name = ""
	var le := _name_edit(_draft_name, "İttifak adı (örn. Doğu Savunma Paktı)")
	le.text_changed.connect(func(t: String): _draft_name = t)
	content.add_child(le)
	content.add_child(_emblem_editor(_draft, func(): pass))
	var kb := TK.button("İttifakı kur", "gold", "alliance_shield", Vector2(0, 60), 17)
	kb.pressed.connect(func():
		ui._click()
		var err: String = gs.player_found_bloc(_draft_name, _draft.duplicate())
		if err != "":
			_toast(err)
			return
		_toast("İttifak kuruldu: " + _draft_name.strip_edges())
		_draft = {}
		render())
	content.add_child(kb)
