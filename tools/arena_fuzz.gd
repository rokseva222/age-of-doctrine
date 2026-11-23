extends RefCounted
## Arena botu: oyuncu gibi rastgele (ve ara sıra bozuk) emirler verir. Hem online (istemci kopyası) hem aynı-telefon yolunda kullanılır.
const Macro = preload("res://scripts/macro.gd")
const FleetsM = preload("res://scripts/fleets.gd")
const AirM = preload("res://scripts/air.gd")
const Model = preload("res://scripts/model.gd")
const Propaganda = preload("res://scripts/propaganda.gd")
const GoodsM = preload("res://scripts/goods.gd")

var rng := RandomNumberGenerator.new()
var count: Dictionary = {}      # eylem adı -> kaç kez
var garbage := false             # true: ara sıra geçersiz hedefle da dene (yalnız doğrulaması olan yollarda)
var online_garbage := false      # yalnız online (sunucu doğrulaması) testinde geçersiz hedef üret


func _init(seed_val: int) -> void:
	rng.seed = seed_val


func _n(k: String) -> void:
	count[k] = int(count.get(k, 0)) + 1


func _alive(g, cid: int) -> Array:
	var r: Array = []
	for c in g.countries:
		if c.alive and c.id != cid and not c.is_rebel:
			r.append(c.id)
	return r


func _pick(a: Array):
	return a[rng.randi_range(0, a.size() - 1)] if not a.is_empty() else -1


func _mine_armies(g, cid: int) -> Array:
	var r: Array = []
	for a in g.armies.values():
		if a.owner == cid:
			r.append(a)
	return r


func _mine_prov(g, cid: int) -> Array:
	var r: Array = []
	for pid in g.countries[cid].held_ids:
		r.append(pid)
	return r


## Bir oyuncu bu tur kaç emir verirse versin: n adet rastgele eylem.
func act(g, cid: int, n: int, humans: Array) -> void:
	var me = g.countries[cid]
	var others: Array = _alive(g, cid)
	var hum: Array = []
	for h in humans:
		if h != cid and g.countries[h].alive:
			hum.append(h)
	for i in n:
		if not me.alive:
			return
		var t: int = _pick(others) if (hum.is_empty() or rng.randf() < 0.5) else _pick(hum)
		if garbage and online_garbage and rng.randf() < 0.04:
			t = rng.randi_range(-5, g.countries.size() + 5)      # geçersiz hedef
		var k: int = rng.randi_range(0, 37)
		match k:
			0, 1:
				_n("savaş_ilan")
				g.player_declare_war(t)
			2, 3:
				_n("ittifak_teklif")
				g.player_propose_alliance(t)
			4:
				_n("barış_iste")
				var en: Array = me.enemies.duplicate()
				g.player_request_peace(_pick(en) if not en.is_empty() else t)
			5:
				_n("ilişki_iyi")
				g.player_improve_relations(t, _pick(g.DIPLO_ACTS.keys()))
			6:
				_n("ilişki_kötü")
				g.player_worsen_relations(t, _pick(g.PROVOKE_ACTS.keys()))
			7:
				_n("ticaret")
				g.player_sign_trade(t)
			8:
				_n("ticaret_iptal")
				g.player_cancel_trade(t)
			9, 10, 11:
				var arm: Array = _mine_armies(g, cid)
				if not arm.is_empty():
					var a = _pick(arm)
					var dest: int = _pick(_mine_prov(g, cid)) if rng.randf() < 0.3 else rng.randi_range(0, g.provinces.size() - 1)
					_n("ordu_sevk")
					g.player_order_move(a, dest, rng.randi_range(0, a.size))
			12:
				var arm2: Array = _mine_armies(g, cid)
				if not arm2.is_empty():
					_n("ordu_iptal")
					g.player_cancel_move(_pick(arm2))
			13:
				var mp: Array = _mine_prov(g, cid)
				if not mp.is_empty():
					_n("bina")
					g.player_build(_pick(mp), _pick(Model.BLD.keys()))
			14:
				_n("bütçe")
				Macro.set_budget(me, _pick(Macro.BUDGET_KEYS), rng.randi_range(0, 80))
			15:
				_n("cephe")
				Macro.set_front(me, t, _pick(["stance", "cyber"]), _pick(["attack", "defend", "auto", "hold"]))
			16:
				_n("seferberlik")
				Macro.mobilize(g, me)
			17:
				_n("doktrin")
				Macro.set_doctrine(g, me, rng.randi_range(0, 5))
			18:
				_n("propaganda")
				g.player_set_propaganda(_pick(Propaganda.MODES.keys()))
			19:
				_n("casusluk")
				g.player_spy(t)
			20:
				_n("gizli_harekât")
				g.player_covert(t, _pick(g.COVERT.keys()))
			21:
				for o in g.offers_for(cid).duplicate():
					_n("teklif_yanıt")
					g.respond_offer(int(o.id), rng.randf() < 0.6)
			22:
				_n("yardım")
				g.player_aid_gold(t)
			23:
				_n("savaşa_katıl")
				g.player_join_war(t)
			24:
				_n("ittifak_boz")
				g.player_break_alliance(t)
			25:
				_n("geçiş_izni")
				g.player_request_passage(t)
			26:
				var fl: Array = []
				for f in g.fleets.values():
					if f.owner == cid:
						fl.append(f)
				if not fl.is_empty():
					var f2 = _pick(fl)
					match rng.randi_range(0, 3):
						0:
							_n("filo_duruş")
							FleetsM.set_stance(g, f2.id, _pick(["attack", "defend", "hold", "escort"]))
						1:
							_n("filo_birleş")
							FleetsM.merge(g, f2.id)
						2:
							_n("filo_böl")
							FleetsM.split(g, f2.id, rng.randf_range(0.2, 0.8))
						3:
							_n("filo_abluka")
							FleetsM.blockade(g, f2.id)
			27:
				var wg: Array = []
				for w in g.wings.values():
					if w.owner == cid:
						wg.append(w)
				if not wg.is_empty():
					var w2 = _pick(wg)
					match rng.randi_range(0, 2):
						0:
							_n("kanat_duruş")
							AirM.set_stance(g, w2.id, _pick(["attack", "defend"]))
						1:
							_n("kanat_üs")
							AirM.rebase(g, w2.id, _pick(_mine_prov(g, cid)) if not _mine_prov(g, cid).is_empty() else 0)
						2:
							_n("hava_saldırı")
							AirM.player_strike(g, w2.id, rng.randi_range(0, g.provinces.size() - 1))
			28:
				var mp2: Array = _mine_prov(g, cid)
				if not mp2.is_empty():
					_n("asimilasyon")
					g.player_assimilate(_pick(mp2))
			29:
				_n("ittifak_davet")
				g.player_invite(t)
			30:
				_n("teslim")
				if rng.randf() < 0.1:
					g.player_surrender(t)
			31:
				_n("ittifak_yardım")
				g.player_request_aid(t)
			32:
				_n("mal_politika")
				GoodsM.set_policy(me, _pick(GoodsM.GOODS), _pick(GoodsM.POLICIES))
			33:
				var gd: String = _pick(GoodsM.GOODS)
				var sup: Array = GoodsM.suppliers(g, me, gd)
				_n("mal_anlaşma")
				if not sup.is_empty() and rng.randf() < 0.7:
					GoodsM.make_deal(g, me, gd, int(sup[0][0]))
				else:
					GoodsM.cancel_deal(g, me, gd)
			34:
				_n("askerlik_düzeni")
				Macro.set_draft(me, rng.randi_range(0, 2))
			35:
				var mp3: Array = _mine_prov(g, cid)
				if not mp3.is_empty():
					_n("kaynak_ara")
					g.player_explore(_pick(mp3))
			36:
				var arm3: Array = _mine_armies(g, cid)
				if not arm3.is_empty():
					var a3 = _pick(arm3)
					if g.provinces[a3.prov].coastal:
						_n("gemiye_bin")
						FleetsM.embark(g, a3.prov, rng.randi_range(1000, maxi(1000, a3.size)))
			37:
				var fl2: Array = []
				for f3 in g.fleets.values():
					if f3.owner == cid and f3.cargo > 0:
						fl2.append(f3)
				if not fl2.is_empty():
					var f4 = _pick(fl2)
					var tg: Array = FleetsM.debark_targets(g, f4)
					if not tg.is_empty():
						_n("karaya_çık")
						FleetsM.debark(g, f4.id, int(_pick(tg)))
