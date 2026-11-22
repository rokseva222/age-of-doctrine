extends SceneTree
## İki insan oyuncu arasında savaş: ordu emri sunucuda yürütülüyor mu, saldırı başlıyor mu?
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Cmd = preload("res://scripts/cmd.gd")

func _client_copy(server_gs, cid: int):
	var d: Dictionary = server_gs.to_dict()
	var raw: PackedByteArray = var_to_bytes(d).compress(FileAccess.COMPRESSION_GZIP)
	var d2 = bytes_to_var(raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
	var g = GS.new()
	g.new_world(int(d2.get("seed", 0)))
	g.from_dict(d2)
	g.net_humans = g.humans.duplicate()
	g.humans = []
	g.switch_player(cid)
	g.cmd_log = []
	Cmd.rec_gs = g
	return g

func _init() -> void:
	var g = GS.new()
	g.new_world(21)
	var a: int = int(g.macro_idx.get("Germany", 0))
	var b: int = int(g.macro_idx.get("France", 0))
	g.start_game(a)
	var room = Room.new()
	room.setup(g, [a, b])
	print("komşu mu: ", g.neighbor_countries(a).has(b))
	var ca = _client_copy(g, a)
	print("savaş ilanı: '", ca.player_declare_war(b), "'")
	# hedef: b'nin a'ya komşu eyaleti
	var tgt := -1
	var src_army = null
	for arm in ca.armies.values():
		if arm.owner != a:
			continue
		for nb in ca.provinces[arm.prov].neighbors:
			if ca.provinces[nb].owner == b:
				tgt = nb
				src_army = arm
				break
		if tgt >= 0:
			break
	print("hedef eyalet: ", tgt, " ordu: ", src_army.id if src_army != null else null)
	if tgt < 0:
		# sınıra yakın değilse en yakın sınır eyaletine git
		print("sınırda ordu yok")
		quit()
		return
	print("emir: ", ca.player_order_move(src_army, tgt))
	print("kayıt: ", var_to_str(ca.cmd_log))
	room.cmds[a] = ca.cmd_log.duplicate(true)
	room.cmds[b] = []
	var sid = src_army.id
	for rnd in 6:
		var r = room.process_round()
		var info := ""
		for arm2 in g.armies.values():
			if arm2.id == sid:
				info = "ordu prov=%d" % arm2.prov
		print("tur ", g.turn, " ret=", r.rejected, " ", info, " savaş=", g.at_war(a, b), " tgt sahibi=", g.provinces[tgt].owner, " ctrl=", g.provinces[tgt].controller)
	var moved: bool = g.provinces[tgt].controller != b
	print("SONUÇ: ", "TAMAM — saldırı başladı, il el değiştirdi" if moved else "BOZUK — ordu ilerlemedi")
	quit(0 if moved else 1)
