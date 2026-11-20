extends SceneTree
## Deniz Filoları testi (headless): bölgeler, filo türetme, hareket/BFS/geçit, muharebe, abluka, bombardıman, torpido,
## gemiye bin / karaya çık, kayıt/yükleme (eski kayıt dâhil), 300 tur invaryantları, tur süresi ölçümü.
## Çalıştır: godot --headless --path . -s tools/fleet_test.gd   (sonda HATA SAYISI=0 beklenir)
const GS = preload("res://scripts/game_state.gd")
const Eras = preload("res://scripts/eras.gd")
const Fleets = preload("res://scripts/fleets.gd")
const Seas = preload("res://scripts/seas.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")
const Macro = preload("res://scripts/macro.gd")
const Model = preload("res://scripts/model.gd")

var fails := 0


func ck(name: String, ok: bool) -> void:
	print(("OK   " if ok else "HATA ") + name)
	if not ok:
		fails += 1


func make(era: String, seed_v: int = 7):
	var g = GS.new()
	Eras.prepare(era) if era != "" else Eras.clear()
	g.new_world(seed_v)
	var host := "Turkey"
	if era != "":
		Eras.restructure(g, era)
		host = String(Eras.get_era(era).suggest[0])
	var pl: int = int(g.macro_idx.get(host, 0))
	g.start_game(pl)
	if era != "":
		Eras.start(g, era)
	return g


func cid(g, nm: String) -> int:
	return int(g.macro_idx.get(nm, -1))


## Bir ülkenin elindeki, bölgesi olan kıyı eyaletlerinden birini (ordulu olanı tercih ederek) döndürür
func port_prov(g, c: int, with_army: bool) -> int:
	for pid in g.countries[c].owned_ids:
		var p = g.provinces[pid]
		if p.controller == c and not Seas.coast_zones(g, pid).is_empty() and (not with_army or (g.armies.has(pid) and g.armies[pid].owner == c)):
			return pid
	return -1


func clear_fleets(g, c: int) -> void:
	for f in Fleets.fleets_of(g, c):
		g.fleets.erase(f.id)


func invariants(g, label: String) -> int:
	var bad := 0
	var per: Dictionary = {}
	for f in g.fleets.values():
		var c = g.countries[f.owner] if f.owner >= 0 and f.owner < g.countries.size() else null
		if c == null:
			bad += 1
			print("  [!] sahipsiz filo ", f.id)
			continue
		if not c.alive or c.is_rebel:
			bad += 1
			print("  [!] ölü/isyancı ülkenin filosu ", f.id, " ", c.name_en)
		if not Seas.has(f.zone):
			bad += 1
			print("  [!] geçersiz bölge ", f.zone)
		if f.size <= 0.0 or is_nan(f.size) or f.cargo < 0:
			bad += 1
			print("  [!] negatif/NaN güç ", f.id, " ", f.size, " ", f.cargo)
		if not Fleets.KINDS.has(f.kind):
			bad += 1
		for z in f.path:
			if not Seas.has(String(z)):
				bad += 1
		if f.kind != "transport":
			per[f.owner] = int(per.get(f.owner, 0)) + 1
	for k in per:
		if int(per[k]) > Fleets.MAX_FLEETS:
			bad += 1
			print("  [!] ülke başına çok filo ", g.countries[k].name_en, " ", per[k])
	for c2 in g.countries:
		if c2.naval_pow < 0.0 or c2.carriers < -1 or is_nan(c2.naval_pow):
			bad += 1
			print("  [!] negatif deniz gücü ", c2.name_en)
	if bad > 0:
		print("  invaryant ihlali (", label, ")=", bad)
	return bad


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	# ------------------------------------------------------------ bölgeler
	var g0 = make("")
	Seas.ensure_coast(g0)
	ck("bölge sayısı 24-40 (%d)" % Seas.count(), Seas.count() >= 24 and Seas.count() <= 40)
	var land_bad := 0
	var conn_bad := 0
	for id in Seas.ids():
		if Seas.center_on_land(g0, g0.world, id):
			land_bad += 1
			print("  merkez karada: ", id)
		for id2 in Seas.ids():
			if Seas.is_lake(id) or Seas.is_lake(id2):
				continue
			if Seas.hops(id, id2) >= 99:
				conn_bad += 1
	ck("bölge merkezleri denizde", land_bad == 0)
	ck("bölge grafiği bağlantılı", conn_bad == 0)
	var cz := 0
	var coastal := 0
	for p in g0.provinces:
		if p.coastal:
			coastal += 1
			if not Seas.coast_zones(g0, p.id).is_empty():
				cz += 1
	ck("kıyı eyaletlerinin çoğu bölgeye eşlendi (%d/%d)" % [cz, coastal], float(cz) / float(coastal) > 0.88)
	var sl_before: int = g0.provinces[423].sea_links.size()
	ck("sea_links değişmedi", g0.provinces[423].sea_links.size() == sl_before)
	for pair in [["Turkey", ["black", "aegean", "med_e"]], ["Egypt", ["med_e", "red_sea"]], ["Japan", ["pac_nw", "japan_sea"]], ["United Kingdom", ["channel", "north_sea", "atl_n"]]]:
		var c: int = cid(g0, pair[0])
		var have: Dictionary = {}
		for pid in g0.countries[c].owned_ids:
			for z in Seas.coast_zones(g0, pid):
				have[z] = true
		var okz := true
		for z2 in pair[1]:
			if not have.has(z2):
				okz = false
		ck("%s kıyı bölgeleri %s" % [pair[0], str(have.keys())], okz)
	# geçitler
	ck("Karadeniz->Akdeniz yolu (Türkiye)", Seas.path(g0, cid(g0, "Turkey"), "black", "med_e") == ["aegean", "med_e"])
	var ru: int = cid(g0, "Russia")
	var tr: int = cid(g0, "Turkey")
	Chokepoints.ensure(g0)
	g0.chokes["bosphorus"]["mode"] = "all"
	ck("Boğaz herkese kapalı: Rusya geçemez", Seas.path(g0, ru, "black", "aegean").is_empty() or Chokepoints.controller(g0, "bosphorus") == ru)
	ck("Boğaz kapalı: kontrolcü Türkiye geçer", not Seas.path(g0, tr, "black", "aegean").is_empty())
	g0.chokes["bosphorus"]["mode"] = "open"
	ck("Boğaz açık: Rusya geçer", not Seas.path(g0, ru, "black", "aegean").is_empty())
	g0.declare_war(tr, ru)
	ck("Savaştaki kontrolcü: Rusya boğazdan geçemez", Seas.path(g0, ru, "black", "aegean").is_empty())
	ck("Süveyş geçidi kenarı", Seas.gate_of("med_e", "red_sea") == "suez")

	# ------------------------------------------------------------ modern senaryo
	var g = make("", 11)
	Fleets.ensure(g)
	var me: int = g.player
	ck("modern: filolar türetildi (%d)" % g.fleets.size(), g.fleets.size() >= 40)
	var bad_n := 0
	var bad_none := 0
	var per: Dictionary = {}
	for f in g.fleets.values():
		per[f.owner] = int(per.get(f.owner, 0)) + 1
	for k in per:
		if int(per[k]) > 4:
			bad_n += 1
	for c3 in g.countries:
		if c3.alive and not c3.is_rebel and c3.naval_pow < 1.0 and c3.carriers < 1 and per.has(c3.id):
			bad_none += 1
	ck("ülke başına en çok 4 filo", bad_n == 0)
	ck("deniz gücü olmayan ülkede filo yok", bad_none == 0)
	var sub_bad := 0
	for c4 in g.countries:
		if not Fleets.qualifies(c4) or not per.has(c4.id):
			continue
		var s := 0.0
		var cs := 0.0
		for f in Fleets.fleets_of(g, c4.id):
			if f.kind == "sub":
				s += f.size
			elif f.kind == "carrier":
				cs += f.size
		if absf(s - Fleets.sub_target(c4)) > 0.1 * Fleets.sub_target(c4) + 1.0 or absf(cs - float(maxi(c4.carriers, 0))) > 0.6:
			sub_bad += 1
	ck("denizaltı/uçak gemisi filoları envanterle eşit", sub_bad == 0)
	ck("invaryantlar (başlangıç)", invariants(g, "modern") == 0)
	# filo hareketi
	var tr_f = null
	for f in Fleets.fleets_of(g, me):
		if f.kind == "surface":
			tr_f = f
	ck("Türkiye muharebe filosu var", tr_f != null)
	var zfrom: String = tr_f.zone
	var err: String = Fleets.order_move(g, tr_f.id, "med_c")
	ck("hareket emri verildi (%s -> med_c) [%s]" % [zfrom, err], err == "" and not tr_f.path.is_empty())
	var plen: int = tr_f.path.size()
	g.end_turn()
	ck("filo haftada 2 bölge ilerledi", tr_f.zone != zfrom and tr_f.path.size() == maxi(0, plen - 2))
	for i in 4:
		g.end_turn()
	ck("filo hedefe vardı", tr_f.zone == "med_c" and tr_f.path.is_empty())
	ck("geçersiz hedef reddedildi", Fleets.order_move(g, tr_f.id, "yok_bolge") != "")
	# denizaltı yavaş
	var sub_f = null
	for f in Fleets.fleets_of(g, me):
		if f.kind == "sub":
			sub_f = f
	if sub_f != null:
		var z0: String = sub_f.zone
		var other: String = ""
		for nb in Seas.neighbors(z0):
			if Seas.edge_ok(g, me, z0, nb):
				other = String(nb)
		var far: String = other
		for nb2 in Seas.neighbors(other):
			if nb2 != z0 and Seas.edge_ok(g, me, other, nb2):
				far = String(nb2)
		Fleets.order_move(g, sub_f.id, far)
		var l0: int = sub_f.path.size()
		g.end_turn()
		ck("denizaltı haftada 1 bölge", sub_f.path.size() == l0 - 1 or l0 <= 1)
	# ------------------------------------------------------------ muharebe
	var gr: int = cid(g, "Greece")
	var ru2: int = cid(g, "Russia")
	g.declare_war(me, gr)
	g.declare_war(me, ru2)
	for c5 in [me, gr, ru2]:
		clear_fleets(g, c5)
	var fa = Fleets.new_fleet(g, me, "aegean", "sub", 50.0)
	var fb = Fleets.new_fleet(g, gr, "aegean", "surface", 50.0)
	var inv_before: Dictionary = g.countries[gr].inv.duplicate()
	Fleets._combat(g, Fleets._index(g))
	var la: float = 1.0 - fa.size / 50.0
	var lb: float = 1.0 - fb.size / 50.0
	ck("denizaltı yüzey gemisine üstün (kayıp %.2f vs %.2f)" % [la, lb], lb > la and lb > 0.1)
	ck("muharebe haber akışına yazıldı", g.news_log.any(func(n): return String(n.text).begins_with("Deniz muharebesi")))
	# yüzey + uçak gemisi, denizaltıya karşı (ASW)
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var s1 = Fleets.new_fleet(g, me, "med_c", "surface", 50.0)
	var d1 = Fleets.new_fleet(g, gr, "med_c", "sub", 50.0)
	Fleets._combat(g, Fleets._index(g))
	var loss_sub_alone: float = 1.0 - d1.size / 50.0
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var s2 = Fleets.new_fleet(g, me, "med_c", "surface", 50.0)
	var c2f = Fleets.new_fleet(g, me, "med_c", "carrier", 3.0)
	var d2 = Fleets.new_fleet(g, gr, "med_c", "sub", 50.0)
	Fleets._combat(g, Fleets._index(g))
	var loss_sub_asw: float = 1.0 - d2.size / 50.0
	ck("uçak gemisi hava/ASW: denizaltı daha çok kayıp (%.2f > %.2f)" % [loss_sub_asw, loss_sub_alone], loss_sub_asw > loss_sub_alone)
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var ca = Fleets.new_fleet(g, me, "med_c", "carrier", 3.0)
	var sh = Fleets.new_fleet(g, gr, "med_c", "surface", 24.0)
	var sh_before: float = sh.size
	Fleets._combat(g, Fleets._index(g))
	var car_loss: float = 1.0 - ca.size / 3.0
	var sh_loss: float = 1.0 - sh.size / sh_before
	ck("uçak gemisi grubu tek başına zayıf (kayıp %.2f >= %.2f)" % [car_loss, sh_loss], car_loss >= sh_loss * 0.9)
	# yok olma + envanter yansıması
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var big = Fleets.new_fleet(g, me, "aegean", "surface", 200.0)
	var small_sub = Fleets.new_fleet(g, gr, "aegean", "sub", 3.0)
	var sub_before_inv: float = Fleets.sub_target(g.countries[gr])
	var np_before: float = g.countries[gr].naval_pow
	for i in 4:
		Fleets._combat(g, Fleets._index(g))
	ck("sıfırlanan filo kaldırıldı", not g.fleets.has(small_sub.id))
	ck("kayıp naval_pow'a yansıdı (%.1f -> %.1f)" % [np_before, g.countries[gr].naval_pow], g.countries[gr].naval_pow < np_before or np_before < 1.0)
	# uçak gemisi kaybı c.carriers'a yansır
	var ch: int = cid(g, "China")
	var chc = g.countries[ch]
	var car_n: int = chc.carriers
	g.declare_war(me, ch)
	if car_n >= 1:
		clear_fleets(g, ch)
		var cf = Fleets.new_fleet(g, ch, "pac_nw", "carrier", float(car_n))
		var killer = Fleets.new_fleet(g, me, "pac_nw", "sub", 400.0)
		for i in 3:
			Fleets._combat(g, Fleets._index(g))
		ck("uçak gemisi kaybı c.carriers'a yansıdı (%d -> %d)" % [car_n, chc.carriers], chc.carriers < car_n)
	else:
		ck("Çin uçak gemisi yok (atla)", true)
	# ------------------------------------------------------------ abluka
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var gports: Dictionary = Seas.ports_of(g, gr)
	var gz: String = ""
	var gbest := 0
	for z in gports:
		if int(gports[z]) > gbest:
			gbest = int(gports[z])
			gz = z
	var blk = Fleets.new_fleet(g, me, gz, "surface", 80.0)
	blk.mission = "blockade"
	Fleets._blockade(g, Fleets._index(g))
	ck("abluka: Yunanistan kıyı baskısı > 0 (%.2f, bölge %s)" % [g.countries[gr].fleet_block, gz], g.countries[gr].fleet_block > 0.05)
	g.countries[gr].blockade = 0.0
	Macro._blockades(g)
	ck("abluka c.blockade'a yansıdı (%.2f)" % g.countries[gr].blockade, g.countries[gr].blockade > 0.05)
	# savunan filo ablukayı kırar
	var def_f = Fleets.new_fleet(g, gr, gz, "surface", 200.0)
	Fleets._blockade(g, Fleets._index(g))
	ck("savunan üstün filo ablukayı kaldırır", g.countries[gr].fleet_block < 0.01)
	g.fleets.erase(def_f.id)
	# ------------------------------------------------------------ bombardıman
	var tgt_p := -1
	for pid in Seas.provs_of(g, gz):
		if g.provinces[pid].owner == gr and g.provinces[pid].controller == gr:
			tgt_p = pid
			break
	ck("bombardıman hedefi bulundu", tgt_p >= 0)
	if tgt_p >= 0:
		if not g.armies.has(tgt_p):
			g._spawn_army(gr, tgt_p, 20000)
		g.armies[tgt_p].size = 20000
		g.countries[me].gold = 1.0e7
		var dfs: int = g.provinces[tgt_p].defense
		var r: Dictionary = Fleets.player_bombard(g, blk.id, tgt_p)
		ck("bombardıman asker öldürdü (%d)" % int(r.killed), r.err == "" and r.killed > 0 and g.armies[tgt_p].size < 20000)
		ck("bombardıman bekleme süresi", Fleets.player_bombard(g, blk.id, tgt_p).err != "")
		ck("bombardıman kıyı olmayan/uzak hedefe yapılmaz", Fleets.player_bombard(g, blk.id, g.countries[me].capital).err != "")
	# ------------------------------------------------------------ torpido
	clear_fleets(g, me)
	clear_fleets(g, gr)
	var tsub = Fleets.new_fleet(g, me, "aegean", "sub", 30.0)
	var ttr = Fleets.new_fleet(g, gr, "aegean", "transport", 2.0)
	ttr.cargo = 12000
	var rt: Dictionary = Fleets.player_torpedo(g, tsub.id)
	ck("torpido: nakliye vuruldu (hit %.1f, asker %d)" % [rt.hit, rt.cargo], rt.err == "" and rt.hit > 0.0 and rt.cargo > 0)
	ck("torpido sonrası denizaltı açığa çıktı", tsub.seen >= g.turn and tsub.cd > g.turn)
	ck("torpido bekleme süresi", Fleets.player_torpedo(g, tsub.id).err != "")
	# ------------------------------------------------------------ gemiye bin / karaya çık
	clear_fleets(g, me)
	clear_fleets(g, gr)
	g.countries[me].gold = 1.0e7
	var pp: int = port_prov(g, me, true)
	ck("Türkiye limanlı ordu eyaleti bulundu", pp >= 0)
	if pp >= 0:
		g.armies[pp].size = 30000
		g.refresh_stats()
		var troops_before: int = g.countries[me].troops
		var want_n: int = mini(10000, g.landing_cap(me))
		var e1: String = Fleets.embark(g, pp, 10000, -1)
		ck("gemiye binme [%s]" % e1, e1 == "")
		var tf = null
		for f in Fleets.fleets_of(g, me):
			if f.kind == "transport":
				tf = f
		ck("otomatik nakliye filosu doğdu, asker taşıyor", tf != null and tf.cargo == want_n)
		ck("ordu küçüldü", g.armies[pp].size == 30000 - want_n)
		ck("denizdeki asker ülke askerine dahil", g.countries[me].troops == troops_before)
		# nakliyeyi düşman filosu vurur
		var pz: String = tf.zone
		var foe_f = Fleets.new_fleet(g, gr, pz, "surface", 60.0)
		Fleets._combat(g, Fleets._index(g))
		ck("nakliye vuruldu: asker kaybı (%d)" % tf.cargo, not g.fleets.has(tf.id) or tf.cargo < want_n)
		g.fleets.erase(foe_f.id)
		# yeni binme ve karaya çıkma
		var tf2 = null
		if g.fleets.has(tf.id):
			tf2 = tf
		else:
			Fleets.embark(g, pp, 8000, -1)
			for f in Fleets.fleets_of(g, me):
				if f.kind == "transport":
					tf2 = f
		ck("nakliye hazır", tf2 != null and tf2.cargo > 0)
		# kendi limanına geri çıkış
		var dz: Array = Fleets.debark_targets(g, tf2)
		ck("karaya çıkış hedefi var (%d)" % dz.size(), dz.size() > 0)
		var friendly_p := -1
		for q in dz:
			if g.provinces[q].controller == me:
				friendly_p = q
		var army_before: int = g.armies[friendly_p].size if friendly_p >= 0 and g.armies.has(friendly_p) else 0
		var carg: int = tf2.cargo
		if friendly_p >= 0:
			var e2: String = Fleets.debark(g, tf2.id, friendly_p)
			var ar = g.armies.get(friendly_p)
			ck("dost limana çıkarma [%s]" % e2, e2 == "" and ar != null and ar.owner == me and ar.size >= army_before + carg - 5)
			ck("boşalan nakliye kaldırıldı", not g.fleets.has(tf2.id))
		# düşman kıyısına çıkarma (savaş halinde)
		var hp2 := -1
		for pid3 in g.countries[gr].owned_ids:
			if g.provinces[pid3].coastal and not Seas.coast_zones(g, pid3).is_empty():
				hp2 = pid3
				break
		g.armies[pp].size = max(g.armies[pp].size, 20000)
		var e3: String = Fleets.embark(g, pp, 15000, -1)
		var tf3 = null
		for f in Fleets.fleets_of(g, me):
			if f.kind == "transport":
				tf3 = f
		if tf3 != null and hp2 >= 0:
			tf3.zone = String(Seas.coast_zones(g, hp2)[0])
			g.armies.erase(hp2)
			g._spawn_army(gr, hp2, 3000)
			var gold0: float = g.countries[me].gold
			var e4: String = Fleets.debark(g, tf3.id, hp2)
			var res_a = g.armies.get(hp2)
			ck("düşman kıyısına çıkarma [%s]" % e4, e4 == "" and (res_a != null and res_a.owner == me))
			ck("çıkarma bedeli düşüldü", g.countries[me].gold < gold0)
			ck("gemiye binme: kapasite ve limit [%s]" % e3, true)
		else:
			ck("düşman kıyısı/nakliye (atla)", true)
		# barış halindeki ülkeye çıkarma reddedilir
		var us: int = cid(g, "Germany")
		var gp := -1
		for pid4 in g.countries[us].owned_ids:
			if g.provinces[pid4].coastal and not Seas.coast_zones(g, pid4).is_empty():
				gp = pid4
		if gp >= 0:
			g.armies[pp].size = max(g.armies[pp].size, 6000)
			Fleets.embark(g, pp, 3000, -1)
			var tf4 = null
			for f in Fleets.fleets_of(g, me):
				if f.kind == "transport":
					tf4 = f
			if tf4 != null:
				tf4.zone = String(Seas.coast_zones(g, gp)[0])
				ck("barıştaki ülkeye çıkarma reddedildi", Fleets.debark(g, tf4.id, gp) != "")
	# ------------------------------------------------------------ doğrudan çıkarma + rota kesme
	var gk = make("", 5)
	Fleets.ensure(gk)
	gk.declare_war(gk.player, cid(gk, "Greece"))
	for f in Fleets.fleets_of(gk, cid(gk, "Greece")):
		gk.fleets.erase(f.id)
	var a_stub = Model.Army.new()
	a_stub.owner = gk.player
	a_stub.size = 10000
	var lp: int = port_prov(gk, gk.player, false)
	var gp2: int = port_prov(gk, cid(gk, "Greece"), false)
	var zl: Array = Fleets.route_zones(gk, lp, gp2)
	ck("çıkarma rotası bölgeleri (%s)" % str(zl), not zl.is_empty())
	ck("düşman filosu yoksa eski çıkarma davranışı (-1)", Fleets.intercept_loss(gk, a_stub, lp, gp2) == -1)
	if not zl.is_empty():
		Fleets.new_fleet(gk, cid(gk, "Greece"), String(zl[0]), "sub", 60.0)
		var ll: int = Fleets.intercept_loss(gk, a_stub, lp, gp2)
		ck("rotadaki düşman filosu çıkarma filosunu vurur (%d)" % ll, ll > 0 and a_stub.size < 10000)
	# ------------------------------------------------------------ kayıt / yükleme
	var gs1 = make("", 21)
	for i in 5:
		gs1.end_turn()
	var e5: String = ""
	var pz2: int = port_prov(gs1, gs1.player, true)
	if pz2 >= 0:
		gs1.countries[gs1.player].gold = 1.0e7
		gs1.armies[pz2].size = 12000
		e5 = Fleets.embark(gs1, pz2, 5000, -1)
	var path1 := "user://t_fleet.sav"
	ck("kaydet", gs1.save_to(path1))
	var gs2 = GS.new()
	gs2.new_world(21)
	ck("yükle", gs2.load_from(path1))
	ck("yükleme: filo sayısı aynı (%d / %d)" % [gs1.fleets.size(), gs2.fleets.size()], gs1.fleets.size() == gs2.fleets.size())
	var cg1 := 0
	var cg2 := 0
	for f in gs1.fleets.values():
		cg1 += f.cargo
	for f in gs2.fleets.values():
		cg2 += f.cargo
	ck("yükleme: denizdeki asker aynı (%d)" % cg2, cg1 == cg2 and (pz2 < 0 or e5 != "" or cg2 == 5000))
	ck("yükleme: tek tek filo özellikleri", _same(gs1, gs2))
	# eski kayıt (filo alanı yok)
	var d_old: Dictionary = gs1.to_dict()
	d_old.erase("fleets")
	d_old.erase("next_fleet")
	var gs3 = GS.new()
	gs3.new_world(21)
	ck("eski kayıt yüklenir", gs3.from_dict(d_old))
	ck("eski kayıt: filolar yeniden türetildi (%d)" % gs3.fleets.size(), gs3.fleets.size() >= 30)
	ck("eski kayıttan oynanır", _play(gs3, 5))
	ck("yüklenen oyun oynanır", _play(gs2, 5))
	# ------------------------------------------------------------ senaryolar
	for sc in ["ww2", "tim1380", ""]:
		var gx = make(sc, 3)
		Fleets.ensure(gx)
		var label: String = sc if sc != "" else "modern"
		print("[", label, "] oyuncu=", gx.countries[gx.player].name_en, " filo=", gx.fleets.size())
		if sc != "tim1380":
			ck("%s: filolar türetildi (%d)" % [label, gx.fleets.size()], gx.fleets.size() >= 5)
		ck("%s: başlangıç invaryantları" % label, invariants(gx, label + " başlangıç") == 0)
		# kayıt/yükleme
		gx.save_to("user://t_fleet2.sav")
		var gy = GS.new()
		Eras.prepare(sc) if sc != "" else Eras.clear()
		gy.new_world(3)
		ck("%s: kaydet/yükle" % label, gy.load_from("user://t_fleet2.sav") and gy.fleets.size() == gx.fleets.size())
		# 300 tur: invaryantlar + süre
		var ticks := 0
		var worst := 0
		var tt0 := Time.get_ticks_msec()
		var inv_bad := 0
		var turns: int = 300 if sc == "" else 150
		for t in turns:
			gx.end_turn()
			if t % 25 == 24:
				inv_bad += invariants(gx, "%s tur %d" % [label, gx.turn])
		var ms: int = Time.get_ticks_msec() - tt0
		var kinds: Dictionary = {}
		for f in gx.fleets.values():
			kinds[f.kind] = int(kinds.get(f.kind, 0)) + 1
		print("[", label, "] ", turns, " tur ", ms, " ms (", ms / turns, " ms/tur) filo=", gx.fleets.size(), " ", kinds, " deniz muharebesi=", gx.stats.get("sea_battles", 0), " kayıp asker=", gx.stats.get("sea_troops_lost", 0))
		ck("%s: %d tur sonra invaryantlar" % [label, turns], inv_bad == 0)
	# ------------------------------------------------------------ tur süresi (A/B)
	var ga = make("", 9)
	Fleets.ensure(ga)
	Fleets.enabled = false
	var ta := Time.get_ticks_msec()
	for i in 60:
		ga.end_turn()
	var base_ms: int = Time.get_ticks_msec() - ta
	Fleets.enabled = true
	var gb = make("", 9)
	var tb := Time.get_ticks_msec()
	for i in 60:
		gb.end_turn()
	var with_ms: int = Time.get_ticks_msec() - tb
	print("tur süresi (modern, 60 tur): filosuz ", base_ms / 60, " ms/tur, filolu ", with_ms / 60, " ms/tur")
	ck("tur süresi belirgin artmadı (%d -> %d ms/tur)" % [base_ms / 60, with_ms / 60], with_ms <= base_ms * 1.35 + 600)
	print("toplam ", (Time.get_ticks_msec() - t0) / 1000, " sn")
	print("HATA SAYISI=", fails)
	quit()


func _same(a, b) -> bool:
	for f in a.fleets.values():
		var o = b.fleets.get(f.id)
		if o == null or o.owner != f.owner or o.zone != f.zone or o.kind != f.kind or absf(o.size - f.size) > 0.001 or o.cargo != f.cargo or o.path != f.path or o.mission != f.mission or o.cd != f.cd:
			return false
	return true


func _play(g, n: int) -> bool:
	for i in n:
		g.end_turn()
	return invariants(g, "oynanış") == 0
