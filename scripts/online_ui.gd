extends RefCounted
## Online arayüzü: sunucu tarayıcısı (liste + ping + konum), kodla katıl, LAN, oda kur, lobi.

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")
const Net = preload("res://scripts/net.gd")
const Eras = preload("res://scripts/eras.gd")

const REGIONS := ["TR", "EU", "US", "AS", "SA", "AF", "OC"]


# ---- kod: IPv4 + port → 10 karakter (Base32), "XXXXX-XXXXX"
const B32 := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

static func code_of(ip: String, port: int) -> String:
	var parts: PackedStringArray = ip.split(".")
	if parts.size() != 4:
		return ""
	var bytes := PackedByteArray()
	for p in parts:
		bytes.append(int(p) & 255)
	bytes.append((port >> 8) & 255)
	bytes.append(port & 255)
	var bits := 0
	var acc := 0
	var out := ""
	for b in bytes:
		acc = (acc << 8) | b
		bits += 8
		while bits >= 5:
			out += B32[(acc >> (bits - 5)) & 31]
			bits -= 5
	if bits > 0:
		out += B32[(acc << (5 - bits)) & 31]
	return out.substr(0, 5) + "-" + out.substr(5)


## Kod → {"ip","port"}; geçersizse boş sözlük. "ip:port" biçimi de kabul edilir.
static func parse_code(text: String) -> Dictionary:
	var t: String = text.strip_edges().to_upper().replace("-", "").replace(" ", "")
	if text.contains(":") or text.contains("."):
		var tt: String = text.strip_edges()
		var ip: String = tt.get_slice(":", 0)
		var port: int = int(tt.get_slice(":", 1)) if tt.contains(":") else Net.DEFAULT_PORT
		return {"ip": ip, "port": port}
	if t.length() != 10:
		return {}
	var acc := 0
	var bits := 0
	var bytes: Array = []
	for ch in t:
		var v: int = B32.find(ch)
		if v < 0:
			return {}
		acc = (acc << 5) | v
		bits += 5
		if bits >= 8:
			bytes.append((acc >> (bits - 8)) & 255)
			bits -= 8
			acc &= (1 << bits) - 1
	if bytes.size() < 6:
		return {}
	return {"ip": "%d.%d.%d.%d" % [bytes[0], bytes[1], bytes[2], bytes[3]], "port": (int(bytes[4]) << 8) | int(bytes[5])}


static func local_ip() -> String:
	for a in IP.get_local_addresses():
		if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
			return a
	return "127.0.0.1"


## Sunucu tarayıcısı. main: Main düğümü (net, master, join_server, host_form çağrıları için).
static func browser(main) -> void:
	var net = main.get_net()
	var master = main.get_master()
	var sh = Sheet.open(main.menu.root, "Online", 1000, true, true, "Sunucu tarayıcısı")
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	sh.body.add_child(top)
	var code := LineEdit.new()
	code.placeholder_text = Loc.t("Kod ya da IP")
	code.custom_minimum_size = Vector2(0, 60)
	code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(code)
	var join := TK.button("Kodla katıl", "gold", "play", Vector2(220, 60), 17)
	join.pressed.connect(func():
		var d: Dictionary = parse_code(code.text)
		if d.is_empty():
			main.menu.toast(Loc.t("Geçersiz kod."))
			return
		sh.close()
		main.online_join(String(d.ip), int(d.port)))
	top.add_child(join)
	var row2 := HFlowContainer.new()
	row2.add_theme_constant_override("h_separation", 10)
	sh.body.add_child(row2)
	var refresh := TK.button("Yenile", "", "refresh", Vector2(180, 56), 16)
	row2.add_child(refresh)
	var mk := TK.button("Oda kur", "", "flag", Vector2(180, 56), 16)
	mk.pressed.connect(func():
		sh.close()
		host_form(main))
	row2.add_child(mk)
	sh.body.add_child(TK.hsep())
	var hdr := TK.t("Sunucu  ·  Çağ  ·  Oyuncu  ·  Ping  ·  Konum", "kicker")
	sh.body.add_child(hdr)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	sh.body.add_child(list)
	var empty := TK.t("Sunucu bulunamadı. «Oda kur» ile kendin aç ya da aynı Wi-Fi'daki LAN oyunlarını bekle.", "small", TK.FAINT)
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var state := {"net": [], "lan": []}
	var render := func():
		for ch in list.get_children():
			list.remove_child(ch)
			ch.queue_free()
		var all: Array = []
		for s in state.net:
			var e: Dictionary = s.duplicate()
			e["lan"] = false
			all.append(e)
		for k in net.lan_found:
			var s2: Dictionary = net.lan_found[k]
			if Time.get_ticks_msec() - int(s2.t) < 5000:
				var e2: Dictionary = s2.duplicate()
				e2["lan"] = true
				e2["region"] = "LAN"
				all.append(e2)
		if all.is_empty():
			list.add_child(empty)
			return
		for e in all:
			var key := "%s:%d" % [String(e.ip), int(e.port)]
			var ping: int = int(net.pings.get(key, -2))
			var ptxt: String = "…" if ping == -2 else ("—" if ping < 0 else "%d ms" % ping)
			var era: String = String(e.era) if String(e.era) != "" else Loc.t("Dünya 2027")
			var txt := "%s  ·  %s  ·  %d/%d  ·  %s  ·  %s%s" % [e.name, era, int(e.players), int(e.max), ptxt, String(e.get("region", "")), "  🔒" if bool(e.get("pass", false)) else ""]
			var b := TK.button(txt, "", "", Vector2(0, 64), 15)
			b.pressed.connect(func():
				sh.close()
				main.online_join(String(e.ip), int(e.port)))
			list.add_child(b)
			if ping == -2:
				net.ping(String(e.ip), int(e.port))
	refresh.pressed.connect(func():
		master.fetch())
	master.list_ready.connect(func(arr: Array):
		state.net = arr
		render.call())
	master.failed.connect(func(_m: String): render.call())
	net.lan_scan_start()
	master.fetch()
	var tm := Timer.new()
	tm.wait_time = 1.0
	tm.autostart = true
	tm.timeout.connect(func(): render.call())
	sh.add_child(tm)
	sh.closed.connect(func(): net.lan_scan_stop())
	render.call()
	sh.add_button("Geri", func(): pass, "ghost", true, "", 170)


## Oda kurma formu.
static func host_form(main) -> void:
	var sh = Sheet.open(main.menu.root, "Oda kur", 760, true, true, "Online")
	var st := {"name": "", "era": "", "secs": 120, "max": 4, "pass": "", "region": "EU", "public": true}
	var nm := LineEdit.new()
	nm.placeholder_text = Loc.t("Oda adı")
	nm.text = Loc.t("Oda") + " " + str(randi() % 900 + 100)
	nm.custom_minimum_size = Vector2(0, 60)
	sh.body.add_child(nm)
	var pw := LineEdit.new()
	pw.placeholder_text = Loc.t("Şifre (boş = herkese açık)")
	pw.custom_minimum_size = Vector2(0, 60)
	sh.body.add_child(pw)
	# tur süresi
	sh.body.add_child(TK.t("Tur süresi", "kicker"))
	var secs_row := HFlowContainer.new()
	secs_row.add_theme_constant_override("h_separation", 8)
	sh.body.add_child(secs_row)
	for v in [60, 120, 180, 0]:
		var lbl: String = "%d sn" % v if v > 0 else Loc.t("Sınırsız")
		var b := TK.button(lbl, "gold" if v == 120 else "", "", Vector2(150, 56), 16)
		b.pressed.connect(func():
			st.secs = v
			for c in secs_row.get_children():
				c.theme_type_variation = ""
			TK.style_button(b, "gold")
			for c in secs_row.get_children():
				if c != b:
					TK.style_button(c, ""))
		secs_row.add_child(b)
	sh.body.add_child(TK.t("Oyuncu sayısı", "kicker"))
	var max_row := HFlowContainer.new()
	max_row.add_theme_constant_override("h_separation", 8)
	sh.body.add_child(max_row)
	for n in range(2, 7):
		var b2 := TK.button(str(n), "gold" if n == 4 else "", "", Vector2(90, 56), 18)
		b2.pressed.connect(func():
			st.max = n
			for c in max_row.get_children():
				TK.style_button(c, "")
			TK.style_button(b2, "gold"))
		max_row.add_child(b2)
	sh.body.add_child(TK.t("Konum", "kicker"))
	var reg_row := HFlowContainer.new()
	reg_row.add_theme_constant_override("h_separation", 8)
	sh.body.add_child(reg_row)
	for r in REGIONS:
		var b3 := TK.button(r, "gold" if r == "EU" else "", "", Vector2(90, 56), 16)
		b3.pressed.connect(func():
			st.region = r
			for c in reg_row.get_children():
				TK.style_button(c, "")
			TK.style_button(b3, "gold"))
		reg_row.add_child(b3)
	var note := TK.t("Dünya ve senaryo, oda kurulunca lobide seçilir. Telefonda oda kurarsan oyun bitene kadar uygulamayı açık tut; kalıcı oda için sunucu programını bir bilgisayarda çalıştır.", "small", TK.FAINT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sh.body.add_child(note)
	sh.add_button("Oda kur", func():
		main.online_host({"name": nm.text.strip_edges(), "pass": pw.text, "round_secs": float(st.secs), "max": int(st.max), "region": String(st.region)}), "gold", true, "play", 220)
	sh.add_button("Vazgeç", func(): pass, "ghost", true, "", 170)


## Lobi: oyuncu listesi, ülke seç, (kurucu) başlat.
static func lobby(main) -> Control:
	var net = main.get_net()
	var sh = Sheet.open(main.menu.root, "Lobi", 760, true, false, "Online")
	var codelbl := TK.t("", "small", TK.MUTED)
	sh.body.add_child(codelbl)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	sh.body.add_child(list)
	var pick := TK.button("Ülke seç", "gold", "flag", Vector2(0, 64), 18)
	sh.body.add_child(pick)
	var start := TK.button("Oyunu başlat", "", "play", Vector2(0, 64), 18)
	sh.body.add_child(start)
	var render := func():
		if net.info.has("need_pass"):
			codelbl.text = Loc.t("Şifre gerekli.")
			return
		var code: String = code_of(local_ip(), int(net.info.get("port", 0))) if net.is_server else ""
		codelbl.text = ("%s: %s   ·   %s" % [Loc.t("Kod"), code, local_ip()]) if net.is_server else String(net.info.get("name", ""))
		for ch in list.get_children():
			list.remove_child(ch)
			ch.queue_free()
		var me_host := false
		for id in net.players:
			var p: Dictionary = net.players[id]
			var cn := ""
			if int(p.cid) >= 0 and main.gs != null and int(p.cid) < main.gs.countries.size():
				cn = main.gs.countries[int(p.cid)].name
			list.add_child(TK.t("%s%s   %s" % [p.name, "  ★" if bool(p.host) else "", cn if cn != "" else Loc.t("(ülke seçmedi)")], "bodyb", TK.TEXT))
			if bool(p.host) and int(id) == multiplayer_id(net):
				me_host = true
		start.visible = me_host
	net.lobby_changed.connect(func(): render.call())
	pick.pressed.connect(func(): main.online_pick_country())
	start.pressed.connect(func(): net.rpc_id(1, "srv_start") if not net.is_server else net.srv_start())
	render.call()
	sh.add_button("Ayrıl", func(): main.online_leave(), "ghost", true, "", 170)
	return sh


static func multiplayer_id(net) -> int:
	return net.multiplayer.get_unique_id()
