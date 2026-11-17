extends RefCounted
## Ültimatom ekranı: bir ülkeye talep seç; reddederse savaş çıkar.

const TK = preload("res://scripts/theme_kit.gd")
const Ultimatum = preload("res://scripts/ultimatum.gd")


static func open(ui, gs, target: int) -> void:
	if gs == null or gs.player < 0 or target < 0:
		return
	var t = gs.countries[target]
	var sh = ui._open_sheet("Ültimatom", 860, true, true, t.name)
	var why: String = Ultimatum.blocked(gs, target)
	sh.body.add_child(_wrap("Talebin kabul edilirse yerine gelir. Reddedilirse %s'e savaş açmış olursun. Kabul ihtimali, güç oranına ve müttefiklerine bağlıdır." % t.name))
	if why != "":
		sh.body.add_child(_wrap(why, TK.RED))
	var ratio: float = Ultimatum.power_ratio(gs, gs.player, target)
	sh.body.add_child(_wrap("Güç oranı: %.1f× (senin gücün / onların ve müttefiklerinin gücü)" % ratio, TK.BLUE))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	sh.body.add_child(box)
	for kind in ["passage", "tribute", "land"]:
		var info: Dictionary = Ultimatum.KINDS[kind]
		var pnl := PanelContainer.new()
		pnl.add_theme_stylebox_override("panel", TK.box(Color(0, 0, 0, 0.22), TK.LINE, 4, 1, 12))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		pnl.add_child(v)
		v.add_child(TK.t(info.name, "bodyb", TK.TEXT))
		v.add_child(_wrap(Ultimatum.describe(gs, kind, target)))
		var ok: bool = why == "" and Ultimatum.available(gs, kind, target)
		var p: float = Ultimatum.chance(gs, kind, target)
		var lab: String = Ultimatum.chance_label(p)
		var col: Color = TK.GREEN if p >= 0.75 else (TK.GOLD if p >= 0.4 else TK.RED)
		v.add_child(TK.t("Kabul ihtimali: %s" % lab, "small", col))
		var b := TK.button("Talep et", "danger" if p < 0.4 else "gold", "sword", Vector2(0, 52), 16)
		b.disabled = not ok
		var kd: String = kind
		b.pressed.connect(func():
			ui._click()
			var res: Dictionary = Ultimatum.deliver(gs, kd, target)
			ui.toast(res.text)
			ui.refresh_top()
			ui.hide_dialog())
		v.add_child(b)
		box.add_child(pnl)
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 150)


static func _wrap(text: String, col: Color = TK.MUTED) -> Label:
	var l := TK.t(text, "small", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
