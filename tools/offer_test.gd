extends SceneTree
## İnsan oyuncuya ticaret/geçiş izni teklifi: sorulmadan yapılmaz; kabulde iki taraf da kazanır; elçi bekleme süresi oyuncu başına.
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Cmd = preload("res://scripts/cmd.gd")
var bad := 0

func chk(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("  BOZUK: ", msg)

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
	g.relation_add(a, b, 60.0)
	g.countries[a].gold += 5000.0
	g.countries[b].gold += 5000.0
	var ca = _client_copy(g, a)
	var r1: String = ca.player_sign_trade(b)
	var r2: String = ca.player_request_passage(b)
	print("istemci: '", r1, "' | '", r2, "'")
	chk(ca.trade.is_empty(), "ticaret sorulmadan yapılmadı")
	chk(ca.offers.size() == 2, "iki teklif iletildi: %d" % ca.offers.size())
	room.cmds[a] = ca.cmd_log.duplicate(true)
	room.cmds[b] = []
	var rr = room.process_round()
	chk(rr.rejected == 0, "reddedilen komut: %d" % rr.rejected)
	chk(g.offers_for(b).size() == 2, "sunucuda B'ye 2 teklif: %d" % g.offers_for(b).size())
	chk((g.trade_by.get(a, []) as Array).is_empty(), "A ticareti hâlâ yok")
	# B kabul eder
	var cb = _client_copy(g, b)
	var ids: Array = []
	for o in cb.offers_for(b):
		ids.append([int(o.id), String(o.kind)])
	print("B'ye gelen: ", ids)
	for pr in ids:
		cb.respond_offer(pr[0], true)
	room.cmds[a] = []
	room.cmds[b] = cb.cmd_log.duplicate(true)
	var gold_a: float = g.countries[a].gold
	var gold_b: float = g.countries[b].gold
	rr = room.process_round()
	chk(rr.rejected == 0, "kabul komutları: %d" % rr.rejected)
	chk((g.trade_by.get(a, []) as Array).has(b), "A'nın ticaret listesinde B")
	chk((g.trade_by.get(b, []) as Array).has(a), "B'nin ticaret listesinde A")
	chk(g.has_passage(a, b), "geçiş izni verildi")
	# haftalık gelir: ticaret tick'i çalışmalı (player<0 iken de)
	var g_a1: float = g.countries[a].gold
	var g_b1: float = g.countries[b].gold
	room.process_round()
	print("altın A: ", gold_a, " -> ", g_a1, " -> ", g.countries[a].gold, " | B: ", gold_b, " -> ", g_b1, " -> ", g.countries[b].gold)
	chk((g.trade_by.get(a, []) as Array).has(b), "anlaşma sürüyor")
	# kayıt-yükleme gidiş dönüş
	var d: Dictionary = g.to_dict()
	var g2 = GS.new()
	g2.new_world(21)
	g2.from_dict(d)
	chk((g2.trade_by.get(a, []) as Array).has(b) and (g2.trade_by.get(b, []) as Array).has(a), "trade_by kayıttan döndü")
	# elçi bekleme süresi: A'nın kullanması B'ninkini kilitlemez
	var c3 = _client_copy(g, a)
	var c4 = _client_copy(g, b)
	var other: int = -1
	for i in g.countries.size():
		if i != a and i != b and g.countries[i].alive and not g.countries[i].is_rebel:
			other = i
			break
	c3.relation_add(a, other, 10.0)
	c4.relation_add(b, other, 10.0)
	var e1: String = c3.player_improve_relations(other, "envoy")
	var e2: String = c4.player_improve_relations(other, "envoy")
	print("elçi A: '", e1, "' B: '", e2, "'")
	chk(e1 == "" and e2 == "", "iki oyuncu da aynı hedefe elçi yollayabildi")
	print("SONUÇ: ", "TAMAM" if bad == 0 else "BOZUK %d" % bad)
	quit(0 if bad == 0 else 1)
