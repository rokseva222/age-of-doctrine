extends RefCounted
## Duraklatma menüsündeki "Deniz filoları" ve "Hava filoları" sayfaları (Savaş Odası / Siyasi sistemin yanında):
## haritada göster/gizle anahtarı + kendi filoların listesi (dokununca haritada o filoya gider ve seçer).

const Fleets = preload("res://scripts/fleets.gd")
const Air = preload("res://scripts/air.gd")
const Seas = preload("res://scripts/seas.gd")
const Macro = preload("res://scripts/macro.gd")
const Icons = preload("res://scripts/icons.gd")
const TK = preload("res://scripts/theme_kit.gd")
const Loc = preload("res://scripts/loc.gd")
const Settings = preload("res://scripts/settings.gd")
const FleetExt = preload("res://scripts/fleet_ext.gd")


static func open(ui, gs, air: bool) -> void:
	if gs == null or gs.player < 0:
		return
	var me: int = gs.player
	var title: String = "Hava filoları" if air else "Deniz filoları"
	var sh = ui._open_sheet(title, 760, true, true, "Harita katmanı")
	sh.body.add_child(TK.toggle_row("Haritada göster", Settings.air if air else Settings.navy, func(on: bool):
		if air:
			Settings.air = on
		else:
			Settings.navy = on
		Settings.save_all()
		ui.settings_changed.emit(),
		"Haritada kalabalık olursa kapat; filolar çalışmaya devam eder, yalnız rozetler gizlenir."))
	sh.body.add_child(TK.hsep())
	var rows: Array = []
	if air:
		for w in Air.wings_of(gs, me):
			rows.append([w.id, Air.display_name(gs, w), "%s  /  %s" % [Loc.t(Air.kind_name(w.kind)), gs.provinces[w.base].name], "%d" % Air.disp(w), Icons.pick(Air.kind_icon(w.kind), "jet"), int(w.xp)])
	else:
		for f in Fleets.fleets_of(gs, me):
			rows.append([f.id, Fleets.display_name(gs, f), "%s  /  %s" % [Loc.t(Fleets.kind_name(f.kind)), Loc.t(Seas.name_tr(f.zone))], "%d" % FleetExt.ship_total(gs, f), Icons.pick(_kind_icon(f.kind), "ship"), int(f.xp)])
	if rows.is_empty():
		var e := TK.t("Henüz filon yok." if not air else "Henüz hava kanadın yok.", "body", TK.MUTED)
		sh.body.add_child(e)
	else:
		sh.body.add_child(TK.t("%s  (%d)" % [Loc.t("Filolarım"), rows.size()], "kicker", TK.GOLD))
	for r in rows:
		var b := TK.row_button(Color(0, 0, 0, 0), TK.LINE, 76)
		var hb := TK.row_layout(b, 14)
		var iv := TK.IconView.new()
		iv.icon = r[4]
		iv.color = TK.PAPER
		iv.stroke = 2.0
		iv.custom_minimum_size = Vector2(38, 38)
		iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(iv)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(TK.t(String(r[1]), "bodyb", TK.TEXT))
		col.add_child(TK.t(String(r[2]), "small", TK.MUTED))
		hb.add_child(col)
		var cl := TK.t("%s  ·  %s" % [FleetExt.rank_name(float(r[5])), r[3]], "mono", TK.GOLD)
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(cl)
		TK.ignore_mouse(hb)
		var id: int = int(r[0])
		b.pressed.connect(func():
			ui._click()
			sh.close()
			ui.action.emit("wing_focus" if air else "fleet_focus", id))
		sh.body.add_child(b)
	sh.add_button("Kapat", func(): pass, "", true, "x", 160)


static func _kind_icon(kind: String) -> String:
	match kind:
		"sub":
			return "uc_sub"
		"carrier":
			return "uc_carrier"
		"transport":
			return "cargo_ship"
	return "uc_ship"
