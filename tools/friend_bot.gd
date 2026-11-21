extends SceneTree
## Odaya "arkadaş" gibi katılır: ad ve ülke seçer, sonra bekler. -- --port N --name Ad --pick Ülke --secs 120
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
var picked := false
func _init() -> void:
	var St = load("res://scripts/settings.gd")
	St.player_name = _arg("name", "Oyuncu")
	net = NetS.new()
	net.name = "AodNet"
	get_root().add_child(net)
	net.lobby_changed.connect(_on_lobby)
	await process_frame
	net.join("127.0.0.1", int(_arg("port", "47397")))
	await create_timer(float(_arg("secs", "120"))).timeout
	quit()
func _on_lobby() -> void:
	if picked or net.players.size() < 1:
		return
	picked = true
	var era: String = String(net.info.get("era", ""))
	if era != "":
		Eras.prepare(era)
	var g = GS.new()
	g.new_world(int(net.info.get("seed", 0)))
	if era != "":
		Eras.restructure(g, era)
	var cid := int(g.macro_idx.get(_arg("pick", "Greece"), -1))
	await create_timer(1.0).timeout
	net.rpc_id(1, "srv_pick", cid, g.countries[cid].name)
	print("PICK ", g.countries[cid].name)
	var say: String = _arg("say", "")
	if say != "":
		await create_timer(float(_arg("say_after", "4")) ).timeout
		net.rpc_id(1, "srv_chat", say)
