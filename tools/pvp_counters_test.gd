extends SceneTree
## İki insan: dünya tepkisi, kimyasal/nükleer bekleme ve BM bekleme herkese ayrı; kayıt/yükleme ve koalisyon doğru.
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Focus = preload("res://scripts/focus.gd")
var fails := 0
func _chk(name: String, ok: bool) -> void:
	print(("TAMAM  " if ok else "HATA   "), name)
	if not ok: fails += 1
func _init() -> void:
	var g = GS.new()
	g.new_world(21)
	var a: int = int(g.macro_idx.get("Germany", 0))
	var b: int = int(g.macro_idx.get("France", 0))
	g.start_game(a)
	var room = Room.new()
	room.setup(g, [a, b])
	_chk("sunucuda player=-1", g.player == -1)
	g.switch_player(a)
	g.infamy = 70.0
	g.gas_cd = g.turn + 9
	g.nuke_cd = g.turn + 12
	g.un_cd["x"] = g.turn + 5
	g.switch_player(b)
	_chk("B tepkisi 0", g.infamy == 0.0)
	_chk("B gaz beklemesi 0", g.gas_cd == 0 and g.nuke_cd == 0)
	_chk("B BM beklemesi bos", g.un_cd.is_empty())
	g.infamy = 10.0
	g.player = -1
	var d: Dictionary = g.to_dict()
	var g2 = GS.new(); g2.new_world(21); g2.from_dict(d)
	g2.switch_player(a)
	_chk("kayit: A tepkisi 70", int(g2.infamy) == 70 and g2.gas_cd == g.turn + 9 and g2.nuke_cd == g.turn + 12 and g2.un_cd.has("x"))
	g2.switch_player(b)
	_chk("kayit: B tepkisi 10", int(g2.infamy) == 10 and g2.gas_cd == 0)
	# koalisyon sadece A'ya karsi (tepki 70, tur % 8 == 0 olsun)
	g.turn = 16
	g.player = -1
	var war_before := 0
	for c in g.countries:
		if c.alive and g.at_war(c.id, a): war_before += 1
	g._coalition_tick()
	var war_a := 0
	var war_b := 0
	for c in g.countries:
		if c.alive and g.at_war(c.id, a): war_a += 1
		if c.alive and g.at_war(c.id, b): war_b += 1
	_chk("koalisyon yalniz yuksek tepkili A'ya kuruldu", war_a > war_before and war_b == 0)
	g.player = -1
	print("A'ya savaş: ", war_before, " -> ", war_a, "  B'ye savaş: ", war_b, "  player=", g.player)
	_chk("tick sonrasi player geri -1", g.player == -1)
	# odak ağacı: A'nın odağı sunucuda ilerler ve yalnız A'ya uygulanır; B'nin ağacı ayrı
	g.player = a
	var fid := ""
	for id in Focus.TREE.keys():
		if Focus.TREE[id].req.is_empty() and Focus.visible_for(g, String(id)):
			fid = String(id)
			break
	var err: String = Focus.start(g, fid)
	_chk("A odak basladi (%s)" % fid, err == "" and String(g.focus.cur) == fid)
	g.player = b
	_chk("B odak ayri (bos)", String(g.focus.get("cur", "")) == "")
	g.player = -1
	var weeks: int = int(Focus.TREE[fid].weeks)
	for i in weeks:
		Focus.tick(g)
	g.player = a
	_chk("A odak tamamlandi (sunucu tick)", Focus.is_done(g, fid))
	g.player = b
	_chk("B odak tamamlanmadi", not Focus.is_done(g, fid))
	g.player = -1
	print("SONUC hata=", fails)
	quit(1 if fails > 0 else 0)
