extends RefCounted
## Bağımsızlık Yolu arayüzü: kurulum sihirbazı + hareket paneli + rakip grup ekranı.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")
const I = preload("res://scripts/independence.gd")
const U = preload("res://scripts/user_scn.gd")
const Districts = preload("res://scripts/districts.gd")
const Icons = preload("res://scripts/icons.gd")
const PHASE_ICONS := ["phase_spark", "phase_uprising", "phase_negotiation", "phase_statehood", "phase_consolidation"]

const DIRS := ["near", "east", "west", "north", "south"]
const DIR_TR := {"near": "Başkent çevresi", "east": "Doğu", "west": "Batı", "north": "Kuzey", "south": "Güney"}
const DIR_EN := {"near": "Around the capital", "east": "East", "west": "West", "north": "North", "south": "South"}


static func _tr() -> bool:
	return Loc.lang == "tr"


## Ülke adı: dile çevrilmişse o dilde, yoksa İngilizce
static func _cname(c: Dictionary) -> String:
	if Loc.lang != "en":
		var r: String = Loc.translate(String(c["tr"]))
		if r != "":
			return r
	return String(c["en"])


# ------------------------------------------------------------------ şehir listesi (oyun başlamadan, ham dünya verisinden)

static var _cities_cache: Dictionary = {}


## [{pid, name, cpop (milyon), cap}] nüfusa göre azalan; başkent işaretli
static func host_cities(host_en: String) -> Array:
	if _cities_cache.has(host_en):
		return _cities_cache[host_en]
	var raw: Dictionary = preload("res://scripts/world_data.gd").instance().raw
	var cid := -1
	var cap := -1
	for c in raw.get("countries", []):
		if String(c["name_en"]) == host_en:
			cid = int(c["id"])
			cap = int(c.get("capital", -1))
	var out: Array = []
	if cid >= 0:
		for pr in raw.get("provinces", []):
			if int(pr["c"]) == cid:
				var nm: String = String(pr["name"])
				var cty: String = String(pr.get("city", nm))
				out.append({"pid": int(pr["id"]), "name": nm if cty == nm or cty == "" else "%s (%s)" % [nm, cty], "cpop": float(pr.get("cpop", 0)) / 1.0e6, "cap": int(pr["id"]) == cap})
	out.sort_custom(func(a, b): return float(a.cpop) > float(b.cpop))
	_cities_cache[host_en] = out
	return out


## Seçilen şehirlerin nüfusuna göre zorluk özeti
static func city_difficulty(host_en: String, pids: Array) -> String:
	var tot := 0.0
	var has_cap := false
	for c in host_cities(host_en):
		if pids.has(int(c.pid)):
			tot += float(c.cpop)
			has_cap = has_cap or bool(c.cap)
	var lv: String = Loc.t("Düşük") if tot < 1.5 else (Loc.t("Orta") if tot < 4.0 else (Loc.t("Yüksek") if tot < 8.0 else Loc.t("Çok yüksek")))
	return "%s: %s   /   %s" % [Loc.t("Başlangıç zorluğu"), lv, Loc.t("Toplam şehir nüfusu: %s milyon" % ("%.1f" % tot))] + ("   /   " + Loc.t("Başkent dahil") if has_cap else "")


# ------------------------------------------------------------------ kurulum sihirbazı

## on_start: Callable(params: Dictionary)
static func open_setup(parent: Node, on_start: Callable) -> void:
	var sh = Sheet.open(parent, "Bağımsızlık Yolu", 900, true, true, "Yeni kip")
	var p := {"host_en": "Spain", "dir": "east", "n": 3, "ncity": 1, "pids": [], "name": "", "leader": "", "color": 0, "ideo": "liberal", "method": "uprising"}
	var intro := TK.t("Kurgusal bir hareketin lideri ol. Gizlice örgütlen, ayaklan, müzakere et, bağımsızlığını ilan et, tanınmanı sağla ve devleti ayakta tut. Yabancı destek ideolojine göre gelir; her yardımın bir şartı vardır.", "body", TK.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(intro)
	sh.body.add_child(TK.hsep())
	# ülke
	sh.body.add_child(TK.t("Ayrılacağın ülke", "kicker", TK.GOLD))
	var host := OptionButton.new()
	host.custom_minimum_size = Vector2(0, 52)
	var sel := 0
	var i := 0
	for c in U.countries():
		host.add_item(c["tr"] if _tr() else _cname(c))
		host.set_item_metadata(i, c["en"])
		if c["en"] == p.host_en:
			sel = i
		i += 1
	host.select(sel)
	host.item_selected.connect(func(_i): p.host_en = String(host.get_item_metadata(host.selected)))
	sh.body.add_child(host)
	# merkez şehirler: hareketin üssü; seçilen şehirlerin ilçeleri haritada görünür
	sh.body.add_child(TK.t("Merkez şehirler", "kicker", TK.GOLD))
	var city_hint := TK.t("Hareket önce seçtiğin şehirlerin ilçelerinde başlar. Nüfusu yoğun şehirde güvenlik güçleri de yoğundur; ilçe almak zor olur. Başkenti seçersen oradaki ilçeler gizli ağla alınır.", "small", TK.MUTED)
	city_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(city_hint)
	# şehir sayısı: 1 / 2 / 3
	var city_opts: Array = []
	var cnt_btns: Array = []
	var sels: Array = [-1, -1, -1]
	var diff_lbl := TK.t("", "small", TK.GOLD)
	diff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var rebuild := func():
		var cities: Array = host_cities(String(p.host_en))
		var ncity: int = clampi(int(p.ncity), 1, maxi(1, mini(3, cities.size())))
		p.ncity = ncity
		# geçerli + tekrarsız seçim; boşları en kalabalık (başkent olmayan) şehirle doldur
		var used: Array = []
		for k in 3:
			var v: int = int(sels[k])
			var ok := false
			for c in cities:
				if int(c.pid) == v:
					ok = true
			if k >= ncity or not ok or used.has(v):
				v = -1
				for c in cities:
					if not used.has(int(c.pid)) and not bool(c.cap):
						v = int(c.pid)
						break
				if v < 0:
					for c in cities:
						if not used.has(int(c.pid)):
							v = int(c.pid)
							break
			sels[k] = v
			if k < ncity and v >= 0:
				used.append(v)
		for k in 3:
			var ob: OptionButton = city_opts[k]
			ob.visible = k < ncity
			ob.clear()
			var other: Array = []
			for j in ncity:
				if j != k:
					other.append(int(sels[j]))
			for c2 in cities:
				if other.has(int(c2.pid)):
					continue
				var txt: String = "%s%s  (%s)" % [String(c2.name), Loc.t(" · başkent") if bool(c2.cap) else "", Loc.t("%s milyon" % ("%.1f" % float(c2.cpop)))]
				ob.add_item(txt)
				ob.set_item_metadata(ob.item_count - 1, int(c2.pid))
				if int(c2.pid) == int(sels[k]):
					ob.select(ob.item_count - 1)
		for e in cnt_btns:
			var nn: int = int(e[1])
			TK.style_button(e[0], "gold" if nn == ncity else "")
			(e[0] as Button).disabled = nn > maxi(1, cities.size())
		p.pids = sels.slice(0, ncity)
		diff_lbl.text = city_difficulty(String(p.host_en), p.pids)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 8)
	for nn2 in [1, 2, 3]:
		var cb := TK.button(str(nn2), "gold" if nn2 == 1 else "", "", Vector2(0, 54), 17)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nv: int = nn2
		cb.pressed.connect(func():
			p.ncity = nv
			rebuild.call())
		cnt_btns.append([cb, nn2])
		crow.add_child(cb)
	sh.body.add_child(crow)
	for k2 in 3:
		var ob3 := OptionButton.new()
		ob3.custom_minimum_size = Vector2(0, 52)
		var kk: int = k2
		ob3.item_selected.connect(func(ix):
			sels[kk] = int(city_opts[kk].get_item_metadata(ix))
			rebuild.call())
		city_opts.append(ob3)
		sh.body.add_child(ob3)
	sh.body.add_child(diff_lbl)
	host.item_selected.connect(func(_i2):
		sels.fill(-1)
		rebuild.call())
	rebuild.call()
	# ad / lider
	sh.body.add_child(TK.t("Hareketin kimliği", "kicker", TK.GOLD))
	var nm := LineEdit.new()
	nm.placeholder_text = Loc.t("Hareketin adı")
	nm.max_length = 30
	nm.custom_minimum_size = Vector2(0, 54)
	nm.text_changed.connect(func(t): p.name = t)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 8)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rrow.add_child(nm)
	var rb := TK.button("Rastgele", "", "", Vector2(150, 54), 17)
	rb.pressed.connect(func():
		nm.text = I.random_name(rng)
		p.name = nm.text)
	rrow.add_child(rb)
	sh.body.add_child(rrow)
	var ld := LineEdit.new()
	ld.placeholder_text = Loc.t("Lider adı (kurgusal)")
	ld.max_length = 24
	ld.custom_minimum_size = Vector2(0, 54)
	ld.text_changed.connect(func(t): p.leader = t)
	sh.body.add_child(ld)
	# renk
	var colrow := HBoxContainer.new()
	colrow.add_theme_constant_override("separation", 8)
	var swatches: Array = []
	for ci in I.COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 48)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(I.COLORS[ci][0])
		sb.border_color = Color(I.COLORS[ci][2])
		sb.set_border_width_all(3 if ci == 0 else 1)
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		swatches.append([b, sb])
		var idx: int = ci
		b.pressed.connect(func():
			p.color = idx
			for e in swatches:
				e[1].set_border_width_all(1)
			(swatches[idx][1] as StyleBoxFlat).set_border_width_all(4))
		colrow.add_child(b)
	sh.body.add_child(colrow)
	# ideoloji
	sh.body.add_child(TK.t("İdeoloji (yabancı desteği belirler)", "kicker", TK.GOLD))
	var ideo := OptionButton.new()
	ideo.custom_minimum_size = Vector2(0, 52)
	for k in I.IDEOS:
		ideo.add_item(I.ideo_name(k))
	ideo.item_selected.connect(func(ix): p.ideo = I.IDEOS[ix])
	sh.body.add_child(ideo)
	# yöntem
	sh.body.add_child(TK.t("Yöntem", "kicker", TK.GOLD))
	var mdesc := TK.t(I.method_desc("uprising"), "small", TK.MUTED)
	mdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	var mbtns: Array = []
	for m in I.METHODS:
		var mb := TK.button(I.method_name(m), "gold" if m == "uprising" else "", Icons.pick("method_" + String(m), ""), Vector2(0, 54), 17)
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mm: String = m
		mb.pressed.connect(func():
			p.method = mm
			mdesc.text = I.method_desc(mm)
			for e in mbtns:
				TK.style_button(e[0], "gold" if String(e[1]) == mm else "")
			)
		mbtns.append([mb, mm])
		mrow.add_child(mb)
	sh.body.add_child(mrow)
	sh.body.add_child(mdesc)
	sh.add_button("Başla", func():
		on_start.call(p.duplicate()), "gold", true, "play", 170)
	sh.add_button("Kapat", func(): pass, "", true, "", 140)


# ------------------------------------------------------------------ hareket paneli

static func _meter(sh, label: String, v: float, col: Color) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var l := TK.t(label, "body", TK.TEXT)
	l.custom_minimum_size = Vector2(190, 0)
	hb.add_child(l)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = v
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 20)
	hb.add_child(bar)
	var pl := TK.t("%d" % int(v), "small", col)
	pl.custom_minimum_size = Vector2(50, 0)
	hb.add_child(pl)
	sh.body.add_child(hb)


## sh: açılmış Sheet; reopen: panelin yeniden çizilmesi için Callable
static func fill_panel(sh, gs, toast: Callable, reopen: Callable, focus: Callable = Callable()) -> void:
	var s: Dictionary = gs.indep
	var ph: int = int(s.phase)
	# evre çubuğu
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 6)
	for i in 5:
		var lb := TK.t(I.phase_name(i), "kicker", TK.GOLD if i == ph else (TK.GREEN if i < ph else TK.FAINT))
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		var pic: String = Icons.pick(PHASE_ICONS[i], "")
		if pic != "":
			var iv := TK.IconView.new()
			iv.icon = pic
			iv.custom_minimum_size = Vector2(48, 48)
			iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			iv.modulate.a = 1.0 if i <= ph else 0.4
			cell.add_child(iv)
		cell.add_child(lb)
		pr.add_child(cell)
	sh.body.add_child(pr)
	var goal := TK.t(I.phase_goal(ph), "body", TK.TEXT)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(goal)
	if ph == 4:
		sh.body.add_child(TK.t(Loc.t("Konsolidasyon: %d / 52 hafta") % I.consolidation_weeks(gs), "small", TK.MUTED))
	sh.body.add_child(TK.hsep())
	_meter(sh, Loc.t("Halk desteği"), float(s.support), TK.TEXT)
	if ph == 0:
		_meter(sh, Loc.t("Gizlilik"), float(s.secrecy), TK.TEXT)
	_meter(sh, Loc.t("Meşruiyet"), float(s.legit), TK.TEXT)
	var f = gs.countries[gs.player]
	var info := Loc.t("Bağımlılık: %d   /   Tanıyan ülke: %d   /   Eyalet: %d   /   Asker: %s   /   Kasa: %s") % [int(s.dep), (s.recog as Array).size(), f.prov_owned, Macro.compact(f.troops), Macro.money(f.gold)]
	var il := TK.t(info, "small", TK.MUTED)
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(il)
	sh.body.add_child(TK.hsep())
	if Districts.active(gs):
		sh.body.add_child(TK.t("Yerel kontrol (ilçeler)", "kicker", TK.GOLD))
		for dpid in Districts.pids(gs):
			var pid_i: int = dpid
			var ctl: float = Districts.control(gs, pid_i)
			var db := TK.button("%s   %%%d" % [gs.provinces[pid_i].title(), int(round(ctl * 100.0))], "", Icons.pick("uprising_banner", ""), Vector2(0, 54), 17)
			db.pressed.connect(func():
				open_districts(sh.get_parent(), gs, pid_i, toast, reopen, focus))
			sh.body.add_child(db)
		if ph == 1 and not Districts.local_ok(gs):
			var need := TK.t("Müzakere evresi için en az bir şehrin ilçelerinin %60'ını ele geçirmelisin.", "small", TK.FAINT)
			need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sh.body.add_child(need)
		sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Eylemler", "kicker", TK.GOLD))
	for a in I.actions(gs):
		var aid: String = a.id
		var b := TK.button("%s   [%s]" % [a.label, Macro.money(a.cost)] if a.cost > 0 else a.label, "", "", Vector2(0, 56), 18)
		b.disabled = a.why != ""
		b.tooltip_text = a.desc
		b.pressed.connect(func():
			var msg: String = I.do_action(gs, aid)
			if msg != "":
				toast.call(msg)
			reopen.call())
		sh.body.add_child(b)
		var line: String = a.desc
		if float(a.chance) >= 0.0:
			line += "   —   " + Loc.t("başarı şansı %%%d") % int(round(float(a.chance) * 100.0))
		if a.why != "":
			line = a.why
		var dl := TK.t(line, "small", TK.RED_TEXT if a.why != "" else TK.MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.body.add_child(dl)
	# destekçiler
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Destekçiler", "kicker", TK.GOLD))
	var shown := 0
	for k in s.patrons.keys():
		var pt: Dictionary = s.patrons[k]
		if int(pt.lvl) <= 0 and int(pt.cut) <= gs.turn:
			continue
		var cc = gs.countries[int(k)]
		var txt := "%s  —  %s %d   /   %s %d" % [cc.name, Loc.t("yardım"), int(pt.lvl), Loc.t("şart"), int(pt.strings)]
		if int(pt.cut) > gs.turn:
			txt = "%s  —  %s" % [cc.name, Loc.t("desteği kesti")]
		if Icons.pick("foreign_patron", "") != "":
			sh.body.add_child(TK.chip("foreign_patron", txt, TK.TEXT, TK.GOLD))
		else:
			sh.body.add_child(TK.t(txt, "small", TK.TEXT))
		shown += 1
	if shown == 0:
		sh.body.add_child(TK.t("Henüz yabancı destek yok.", "small", TK.FAINT))
	# rakip gruplar
	sh.body.add_child(TK.hsep())
	sh.body.add_child(TK.t("Diğer hareketler", "kicker", TK.GOLD))
	for g in s.groups:
		var gid: int = int(g.id)
		var gc = gs.countries[gid]
		if not gc.alive or String(g.status) == "merged":
			continue
		var gb := TK.button("%s  —  %s  /  %s" % [gc.name, I.ideo_name(String(g.ideo)), _status(String(g.status))], "", Icons.pick("ideo_" + String(g.ideo), ""), Vector2(0, 54), 17)
		gb.pressed.connect(func():
			open_group(sh.get_parent(), gs, gid, toast, reopen))
		sh.body.add_child(gb)


static func _status(st: String) -> String:
	return {"neutral": Loc.t("tarafsız"), "ally": Loc.t("müttefik"), "rival": Loc.t("rakip"), "merged": Loc.t("birleşti")}.get(st, st)


static func open_group(parent: Node, gs, gid: int, toast: Callable, reopen: Callable) -> void:
	var g: Dictionary = I.group_of(gs, gid)
	if g.is_empty():
		return
	var gc = gs.countries[gid]
	var sh = Sheet.open(parent, gc.name, 760, false, true, I.ideo_name(String(g.ideo)))
	var sim: float = I.similarity(String(gs.indep.ideo), String(g.ideo))
	sh.add_text(Loc.t("İdeolojik yakınlık: %%%d   /   İlişki: %d   /   Asker: %s   /   Eyalet: %d") % [int(sim * 100.0), int(g.rel), Macro.compact(gc.troops), gc.prov_owned], 20, TK.MUTED)
	var acts := [["talk", "Görüş", -1.0], ["ally", "İttifak öner", I.group_odds(gs, g, "ally")], ["merge", "Birleşmeyi öner", I.group_odds(gs, g, "merge")], ["rival", "Rakip ilan et", -1.0]]
	for a in acts:
		var aid: String = a[0]
		var label: String = Loc.t(a[1])
		if float(a[2]) >= 0.0:
			label += "   —   " + Loc.t("şans %%%d") % int(round(float(a[2]) * 100.0))
		var b := TK.button(label, "danger" if aid == "rival" else "", "", Vector2(0, 58), 18)
		b.disabled = (aid == "merge" and String(g.status) != "ally") or String(g.status) == "merged"
		b.pressed.connect(func():
			var msg: String = I.group_act(gs, gid, aid)
			if msg != "":
				toast.call(msg)
			sh.close()
			reopen.call())
		sh.body.add_child(b)
	sh.add_button("Kapat", func(): pass, "", true, "", 140)


## Şehrin ilçeleri: durum, güvenlik, eylem
static func open_districts(parent: Node, gs, pid: int, toast: Callable, reopen: Callable, focus: Callable = Callable()) -> void:
	var sh = Sheet.open(parent, gs.provinces[pid].title(), 880, true, true, "İlçeler")
	sh.set_icon("uprising_banner", "flag")
	_meter(sh, Loc.t("Yerel kontrol"), Districts.control(gs, pid) * 100.0, TK.TEXT)
	var hint := TK.t("İlçeyi örgütleyerek hareketin eline geçir. Güvenlik yoğunsa şans düşer; halk desteği ve şehirdeki birliklerin şansı artırır. Elindeki ilçeleri güçlendirmezsen merkez geri alabilir.", "small", TK.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(hint)
	var n: int = (gs.indep.dist[str(pid)] as Array).size()
	for i in n:
		var ix: int = i
		var inf: Dictionary = Districts.info(gs, pid, ix)
		sh.body.add_child(TK.hsep())
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		var nm := TK.t(String(inf.name), "caps", TK.TEXT)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		var held: bool = int(inf.st) == 1
		head.add_child(TK.t("Hareketin elinde" if held else "Merkezin elinde", "small", TK.GREEN if held else TK.RED_TEXT))
		sh.body.add_child(head)
		var line: String = "%s: %.2fM   /   %s: %s" % [Loc.t("Nüfus"), float(inf.pop_m), Loc.t("Güvenlik"), Districts.sec_label(int(inf.sec))]
		if held:
			line += "   /   %s: %d" % [Loc.t("Tutunma"), int(inf.g)]
		else:
			line += "   /   %s: %%%d" % [Loc.t("Başarı şansı"), int(round(float(inf.chance) * 100.0))]
		sh.body.add_child(TK.t(line, "small", TK.FAINT))
		var lab: String = "%s   [%s]" % [Loc.t("Güçlendir") if held else Loc.t("Örgütle"), Macro.money(float(inf.cost))]
		var b := TK.button(lab, "ghost" if String(inf.why) != "" else "", "", Vector2(0, 54), 17)
		b.disabled = String(inf.why) != ""
		b.pressed.connect(func():
			var res: String = Districts.act(gs, pid, ix)
			if res != "":
				toast.call(res)
			sh.close()
			open_districts(parent, gs, pid, toast, reopen, focus))
		sh.body.add_child(b)
		if String(inf.why) != "":
			sh.body.add_child(TK.t(String(inf.why), "small", TK.FAINT))
	if focus.is_valid():
		sh.add_button("Haritada göster", func(): focus.call(pid), "gold", true, "", 220)
	sh.add_button("Kapat", func(): reopen.call(), "ghost", true, "", 150)

