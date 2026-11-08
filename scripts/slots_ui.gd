extends RefCounted
## Kayıt yuvası penceresi. mod "save": yuvaya kaydet; mod "load": yuvadan yükle.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Saves = preload("res://scripts/saves.gd")


static func open(parent: Node, mode: String, on_pick: Callable, click: Callable = Callable()) -> void:
	var sh = Sheet.open(parent, "Kaydet" if mode == "save" else "Yükle", 760, false, true, "Kayıt yuvaları")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	sh.body.add_child(box)
	var st := {"confirm": -1}
	var render := func(): pass
	render = func():
		for ch in box.get_children():
			box.remove_child(ch)
			ch.queue_free()
		var first := 0 if mode == "load" else 1
		for slot in range(first, Saves.slot_count() + 1):
			box.add_child(_row(slot, mode, st, on_pick, sh, render, click))
		if mode == "save":
			box.add_child(TK.t("Otomatik kayıt (Ayarlar'dan açılır/kapanır) ayrı bir yuvada tutulur ve buradan üzerine yazılamaz.", "small", TK.FAINT))
	render.call()
	sh.add_button("Kapat", func(): pass, "ghost", true, "", 170)


static func _row(slot: int, mode: String, st: Dictionary, on_pick: Callable, sh, render: Callable, click: Callable) -> Control:
	var m: Dictionary = Saves.meta(slot)
	var filled: bool = not m.is_empty()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", TK.box(TK.PANEL_LIGHT, TK.LINE, 2, 1, 0, Vector4(14, 10, 14, 10)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	var title := "Otomatik kayıt" if slot == 0 else "Yuva %d" % slot
	v.add_child(TK.t(title, "kicker"))
	if not filled:
		v.add_child(TK.t("Boş", "h3", TK.FAINT))
	elif m.get("legacy", false) and str(m.get("name", "")) == "":
		v.add_child(TK.t("Eski kayıt", "h3", TK.TEXT))
		v.add_child(TK.t(Saves.stamp_text(int(m.ts)), "small", TK.MUTED))
	else:
		v.add_child(TK.t(str(m.name), "h3", TK.TEXT))
		v.add_child(TK.t("%s  /  %d eyalet  /  %s" % [m.date, int(m.prov), Saves.stamp_text(int(m.ts))], "small", TK.MUTED))
	h.add_child(v)
	if mode == "load":
		var b := TK.button("Yükle", "gold", "folder", Vector2(150, 52), 16)
		b.disabled = not filled
		b.pressed.connect(func():
			if click.is_valid(): click.call()
			sh.close()
			on_pick.call(slot))
		h.add_child(b)
	else:
		var sure: bool = st.confirm == slot
		var b2 := TK.button("Emin misin?" if sure else "Kaydet", "danger" if sure else "gold", "save", Vector2(170, 52), 16)
		b2.pressed.connect(func():
			if click.is_valid(): click.call()
			if filled and not sure:
				st.confirm = slot
				render.call()
				return
			sh.close()
			on_pick.call(slot))
		h.add_child(b2)
	if filled:
		var asked: bool = st.confirm == -100 - slot
		var d := TK.button("Emin?" if asked else "Sil", "danger" if asked else "ghost", "x", Vector2(120, 52), 15)
		d.pressed.connect(func():
			if click.is_valid(): click.call()
			if asked:
				Saves.delete(slot)
				st.confirm = -1
			else:
				st.confirm = -100 - slot
			render.call())
		h.add_child(d)
	return panel
