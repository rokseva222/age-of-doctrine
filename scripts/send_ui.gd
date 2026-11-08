extends RefCounted
## "Kaç asker gönderilsin?" penceresi: ordudan yalnızca bir kısmı hedefe yürür, kalanlar yerinde durur.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")


static func open(ui, gs, army, dest: int, on_send: Callable) -> void:
	var from_p = gs.provinces[army.prov]
	var to_p = gs.provinces[dest]
	var sh = ui._open_sheet("Kaç asker gönderilsin?", 760, false, true, "%s  →  %s" % [from_p.name, to_p.name])
	var st := {"frac": 1.0}
	var info := TK.t("", "h3", TK.TEXT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sub := TK.t("", "small", TK.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(info)
	sh.body.add_child(sub)
	var slider_holder := VBoxContainer.new()
	sh.body.add_child(slider_holder)
	var upd := func():
		var n: int = _count(army, st.frac)
		info.text = "%s asker yola çıkar" % Macro.num(n)
		sub.text = "%s asker %s'da kalır. Yaklaşık varış: %d hf." % [Macro.num(army.size - n), from_p.name, maxi(1, gs.path_to(gs.player, army.prov, dest).size())] if n < army.size else "Ordunun tamamı yola çıkar; %s savunmasız kalır." % from_p.name
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	var sl_row: HBoxContainer = TK.slider_row("Oran", 1.0, func(v: float):
		st.frac = v
		upd.call(), 0.1, 1.0, 0.05)
	var sl: HSlider = sl_row.get_child(1)
	slider_holder.add_child(sl_row)
	for f in [0.25, 0.5, 0.75, 1.0]:
		var fv: float = f
		var b := TK.button("%%%d" % int(fv * 100.0), "ghost", "", Vector2(0, 52), 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			ui._click()
			sl.value = fv)
		chips.add_child(b)
	sh.body.add_child(chips)
	upd.call()
	sh.add_button("Gönder", func():
		var n: int = _count(army, st.frac)
		on_send.call(n if n < army.size else 0), "gold", true, "play", 240)
	sh.add_button("Vazgeç", func(): pass, "ghost", true, "", 150)


static func _count(army, frac: float) -> int:
	return clampi(int(round(army.size * frac)), 1, army.size)
