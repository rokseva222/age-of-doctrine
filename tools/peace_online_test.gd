extends SceneTree
## Online: barış masası komutu sunucuda yeniden oynatılabilmeli (eskiden finish_peace "bilinmeyen komut" diye reddediliyordu).
const GS = preload("res://scripts/game_state.gd")
const Cmd = preload("res://scripts/cmd.gd")
var fails := 0
func ck(n: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + n)
	if not ok: fails += 1
func _init() -> void:
	# istemci
	var cl = GS.new(); cl.new_world(5)
	var me: int = cl.macro_idx["Hungary"]; var en: int = cl.macro_idx["Croatia"]
	cl.start_game(me)
	cl.cmd_log = []
	cl.declare_war(me, en)
	for i in 8: cl.turn += 1
	var w = cl.get_war(me, en)
	w.add(me, 60)
	var n := 0
	for pr in cl.provinces:
		if pr.owner == en and n < 6:
			pr.controller = me; n += 1
	var opts = cl.peace_options(w, me, true)
	var picked: Array = []
	var left: int = w.score_of(me)
	for o in opts:
		if o.cost <= left and picked.size() < 6:
			picked.append(o.pid); left -= o.cost
	var err: String = cl.player_finish_peace(en, "win", picked, [])
	ck("istemci barış: " + err, err == "" and not cl.at_war(me, en))
	ck("komut kaydedildi", cl.cmd_log.size() == 1 and cl.cmd_log[0].n == "player_finish_peace")
	# sunucu: aynı durumdan, kaydedilen komutu yeniden oynat
	var sv = GS.new(); sv.new_world(5); sv.start_game(me)
	sv.declare_war(me, en)
	for i in 8: sv.turn += 1
	var w2 = sv.get_war(me, en); w2.add(me, 60)
	var n2 := 0
	for pr in sv.provinces:
		if pr.owner == en and n2 < 6:
			pr.controller = me; n2 += 1
	var r = Cmd.replay(sv, me, cl.cmd_log[0])
	ck("sunucu komutu kabul etti: " + str(r.err), r.ok)
	var owned := 0
	for pid in picked:
		if sv.provinces[pid].owner == me and sv.provinces[pid].controller == me: owned += 1
	ck("sunucuda eyaletler bende (%d/%d)" % [owned, picked.size()], owned == picked.size() and picked.size() > 0)
	ck("sunucuda savaş bitti", not sv.at_war(me, en))
	# hile: puandan fazla eyalet / geçersiz il / bitmiş savaş
	var sv2 = GS.new(); sv2.new_world(5); sv2.start_game(me)
	sv2.declare_war(me, en)
	for i in 8: sv2.turn += 1
	var all2: Array = []
	for o in sv2.peace_options(sv2.get_war(me, en), me, true): all2.append(o.pid)
	ck("puansız çok eyalet reddedildi", sv2.player_finish_peace(en, "win", all2, []) != "" and sv2.at_war(me, en))
	ck("geçersiz il reddedildi", sv2.player_finish_peace(en, "win", [0, 99999], []) != "")
	ck("geçersiz şart reddedildi", sv2.player_finish_peace(en, "win", [], ["bedava"]) != "")
	ck("beraberlik çalışır", sv2.player_finish_peace(en, "draw") == "" and not sv2.at_war(me, en))
	ck("savaşta değilken hata", sv2.player_finish_peace(en, "draw") != "")
	print("HATA SAYISI=", fails)
	quit(1 if fails > 0 else 0)
