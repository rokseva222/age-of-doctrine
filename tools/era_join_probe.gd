extends SceneTree
## Dönemli odaya katılan istemci: lobide ve başladıktan sonra dönem/ülke listesi sunucuyla aynı mı?
const NetS = preload("res://scripts/net.gd")
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
var net
func _arg(name: String, def: String) -> String:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--" + name and i + 1 < a.size():
			return a[i + 1]
	return def
func _init() -> void:
	net = NetS.new()
	net.name = "AodNet"
	get_root().add_child(net)
	net.lobby_changed.connect(_on_lobby)
	net.game_started.connect(_on_start)
	await process_frame
	net.join("127.0.0.1", int(_arg("port", "47413")))
	await create_timer(float(_arg("timeout", "40"))).timeout
	print("TIMEOUT")
	quit(2)
var picked := false
func _on_lobby() -> void:
	if net.players.size() < 1 or picked:
		return
	picked = true
	var era: String = String(net.info.get("era", ""))
	print("LOBİ info.era=[", era, "] Eras.current=[", Eras.current, "]")
	# seçim ekranındaki dünyayı main.gd gibi kur
	if era != "":
		Eras.prepare(era)
	else:
		Eras.clear()
	var g = GS.new()
	g.new_world(int(net.info.get("seed", 0)))
	if era != "":
		Eras.restructure(g, era)
	var want := _arg("want", "Almanya")
	var cid := -1
	for c in g.countries:
		if c.name == want or c.name == "Germany":
			cid = c.id
	print("SEÇİM dünyası: ülke=", g.countries.size(), " ", want, " cid=", cid, " ad=", g.countries[cid].name)
	net.rpc_id(1, "srv_pick", cid, g.countries[cid].name)
	await create_timer(0.5).timeout
	net.rpc_id(1, "srv_start")
func _on_start(c: int) -> void:
	var g = net.gs_client
	print("BAŞLADI cid=", c, " ad=", g.countries[c].name, " ülke=", g.countries.size(), " Eras.current=[", Eras.current, "] tur=", g.turn, " tarih=", g.date_string() if g.has_method("date_string") else "?")
	var ru := -1
	var ua := -1
	for k in g.countries:
		if k.name == "Rusya": ru = k.id
		if k.name == "Ukrayna": ua = k.id
	print("SAVAŞ Rusya-Ukrayna: ", ru >= 0 and ua >= 0 and g.countries[ru].enemies.has(ua), " scn.id=", g.scn.get("id", "-"))
	print("PROBE_OK")
	quit()
