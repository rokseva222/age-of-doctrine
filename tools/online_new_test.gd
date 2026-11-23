extends SceneTree
## Yeni özellikler çevrimiçi odada sunucuda uygulanıyor mu (mal politikası, anlaşma, askerlik düzeni, kaynak arama, barışçıl çıkarma).
const GS = preload("res://scripts/game_state.gd")
const Room = preload("res://scripts/net_room.gd")
const Cmd = preload("res://scripts/cmd.gd")
const Goods = preload("res://scripts/goods.gd")
const Macro = preload("res://scripts/macro.gd")
const Fleets = preload("res://scripts/fleets.gd")
const WarRoom = preload("res://scripts/war_room.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _id(g, en: String) -> int:
	for c in g.countries:
		if c.name_en == en: return c.id
	return -1
func _copy(server, cid: int):
	var d: Dictionary = server.to_dict()
	var g = GS.new(); g.new_world(int(d.get("seed", 0))); g.from_dict(d)
	g.net_humans = g.humans.duplicate(); g.humans = []; g.switch_player(cid)
	g.cmd_log = []; g.cmd_depth = 0; Cmd.rec_gs = g
	return g
func _init():
	var g = GS.new(); g.new_world(5)
	var tr := _id(g, "Turkey"); var de := _id(g, "Germany")
	g.start_game(tr)
	for i in 5: g.end_turn()
	var room = Room.new(); room.setup(g, [tr, de])
	var cp = _copy(g, tr)
	var me = cp.countries[tr]
	Goods.set_policy(me, "oil", "hold")
	Macro.set_draft(me, 2)
	Macro.set_tax(me, 2)
	load("res://scripts/milres.gd").set_research(me, "arty")
	Macro.set_auto_buy(me, false)
	Macro.set_pri(me, "tank", 2.0)
	Macro.set_auto_cmd(me, true)
	var pid: int = cp.countries[tr].capital
	cp.player_explore(pid)
	var sup: Array = []
	var dg := ""
	for gd in Goods.GOODS:
		sup = Goods.suppliers(cp, me, gd)
		if not sup.is_empty():
			dg = gd
			print("anlaşma: ", gd, " <- ", cp.countries[int(sup[0][0])].name, " sonuç='", Goods.make_deal(cp, me, gd, int(sup[0][0])), "'")
			break
	# Savaş Odası planı (oyuncuya özel, sunucuda insan başına saklanır)
	var gr := _id(cp, "Greece")
	WarRoom.new_plan(cp, gr)
	var cands: Array = WarRoom.candidates(cp, gr, 4)
	var wr_add := ""
	if not cands.is_empty():
		var c0 = cands[0]
		var pid0: int = int(c0[0]) if c0 is Array else int(c0)
		var ops: Array = WarRoom.ops_for(cp, pid0)
		wr_add = WarRoom.add_phase(cp, pid0, String(ops[0]) if not ops.is_empty() else "attack", 0.5, 0)
	print("savaş odası aşama: '", wr_add, "'")
	print("komutlar: ", cp.cmd_log.map(func(x): return x.n))
	room.submit(tr, cp.cmd_log); room.set_ready(tr, true)
	room.submit(de, []); room.set_ready(de, true)
	var res: Dictionary = room.process_round()
	print("reddedilen: ", res.rejected)
	var sc = g.countries[tr]
	ck("sunucuda petrol politikası 'hold'", str(sc.goods.pol.get("oil", "")) == "hold")
	ck("sunucuda askerlik düzeni zorunlu", sc.draft == 2)
	ck("sunucuda vergi oranı yüksek", sc.tax == 2)
	ck("sunucuda Ar-Ge dalı topçu", String(sc.mres.get("cur", "")) == "arty")
	ck("sunucuda kaynak arandı (il işaretli)", g.provinces[pid].found != "" )
	ck("sunucuda mal anlaşması (%s)" % dg, dg != "" and not (sc.goods.deals as Array).is_empty())
	ck("sunucuda otomatik tedarik kapalı", sc.auto_buy == false)
	ck("sunucuda tank önceliği yüksek", float(sc.pri.get("tank", 1.0)) == 2.0)
	ck("sunucuda otomatik komuta açık", sc.auto_cmd == true)
	var wb: Dictionary = g.wroom_by.get(tr, {})
	ck("sunucuda Savaş Odası planı Türkiye'ye ait (Yunanistan)", int(wb.get("enemy", -1)) == gr)
	ck("Savaş Odası planı Almanya'ya karışmadı", int((g.wroom_by.get(de, {}) as Dictionary).get("enemy", -1)) != gr)
	ck("reddedilen komut yok", int(res.rejected) == 0)
	print("HATA SAYISI=", fails)
	quit()
