extends RefCounted
## Gerçek oyuncu gibi oynayan test botu (tüm modlar için ortak).
## Savaş/barış bütçesi, seferberlik, bina, odak, kabine atamaları ve kartları, diplomasi (ittifak, ilişki, yardım),
## gelen teklif/çağrı/oylama kartları, barışta toprak alma, hedeflere göre savaş açma.
const Macro = preload("res://scripts/macro.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Focus = preload("res://scripts/focus.gd")
const UN = preload("res://scripts/un.gd")
const EraMoments = preload("res://scripts/era_moments.gd")
const Politics = preload("res://scripts/politics.gd")
const Obj = preload("res://scripts/objectives.gd")
const Model = preload("res://scripts/model.gd")

var gs
var rng := RandomNumberGenerator.new()
var cab_last := -99
var cab_recent: Array = []
var log: Dictionary = {}          # eylem sayaçları (rapor için)
var attacker := false             # true: hedefe göre komşuya savaş açar (fetihçi oyuncu)

func _init(g, seed_val: int = 1, aggressive: bool = false) -> void:
	gs = g
	rng.seed = seed_val
	attacker = aggressive
	gs.peace_proposal.connect(_on_peace)
	gs.alliance_proposal.connect(_on_alliance)
	gs.ally_call.connect(_on_ally_call)
	gs.side_call.connect(_on_side_call)
	gs.un_vote_card.connect(_on_un)
	gs.pol_card.connect(_on_pol)
	gs.moment_card.connect(_on_moment)
	gs.countries[gs.player].auto_cmd = true     # ordu emirleri: otomatik komuta (insan da çoğu zaman bunu açar)
	gs.countries[gs.player].auto_buy = true


func n(k: String) -> void:
	log[k] = int(log.get(k, 0)) + 1


# ------------------------------------------------------------------ gelen kartlar

func _on_peace(w, from_country: int, kind: String) -> void:
	var me = gs.countries[gs.player]
	var foe = gs.countries[from_country]
	match kind:
		"loser_asks":
			var annex: Array = gs._ai_choose_annex(w, gs.player)
			gs.finish_peace(w, gs.player, annex)
			n("barış_kazanan")
		"winner_demands":
			var annex2: Array = gs._ai_choose_annex(w, from_country)
			if annex2.is_empty():
				gs.cancel_proposal()
				return
			# kaybediyorsan ya da talep küçükse kabul; hâlâ güçlüysen reddet
			if annex2.size() <= 1 or me.troops < foe.troops * 0.8 or me.prov_owned <= 3:
				gs.finish_peace(w, from_country, annex2)
				n("barış_kaybeden")
			else:
				gs.cancel_proposal()
				n("barış_red")
		_:
			gs.finish_peace(w, -1, [])
			n("beraberlik")


func _on_alliance(from_country: int) -> void:
	var me = gs.countries[gs.player]
	var o = gs.countries[from_country]
	var bad := false
	for e in me.enemies:
		if o.allies.has(e):
			bad = true
	gs.cancel_proposal()
	if not bad and me.allies.size() < 4:
		gs.make_alliance(gs.player, from_country)
		n("ittifak_kabul")


func _on_ally_call(friend: int, foe: int, kind: String) -> void:
	var me = gs.countries[gs.player]
	var f = gs.countries[friend]
	var e = gs.countries[foe]
	if e.troops < (me.troops + f.troops) * 1.2 and me.prov_owned >= 3:
		gs.player_join_war(foe)
		n("müttefike_katıl")
	else:
		gs.cancel_proposal()
		gs.break_alliance(gs.player, friend)
		n("müttefike_katılma")


func _on_side_call(a: int, b: int) -> void:
	var me = gs.countries[gs.player]
	var choice := 2
	if me.allies.has(a):
		choice = 0
	elif me.allies.has(b):
		choice = 1
	gs.player_choose_side(a, b, choice)
	n("taraf_seçimi")


func _on_un() -> void:
	var v := -1
	var prop: int = int(gs.un_pending.get("proposer", -1))
	var tgt: int = int(gs.un_pending.get("target", -1))
	var me = gs.countries[gs.player]
	if prop >= 0 and me.allies.has(prop):
		v = 1
	elif tgt >= 0 and me.allies.has(tgt):
		v = 0
	UN.player_vote(gs, v)
	n("bm_oyu")


func _on_pol() -> void:
	var pend: Dictionary = gs.pol.get("pending", {})
	if pend.is_empty():
		return
	Politics.choose(gs, 0)
	n("siyaset_kartı")


func _on_moment() -> void:
	if gs.moment_pending.is_empty():
		return
	var c: Dictionary = EraMoments.card(gs)
	if c.is_empty():
		gs.moment_pending = {}
		return
	if (c.options as Array).is_empty():
		gs.moment_pending = {}
	else:
		EraMoments.choose(gs, 0)
	n("tarihi_an")


# ------------------------------------------------------------------ kabine kartı

func _opt_score(opt: Dictionary) -> float:
	var s := 0.0
	var e: Dictionary = opt.get("e", {})
	for k in e:
		var v: float = float(e[k])
		match String(k):
			"g":
				s += v * 1.0
			"stab":
				s += v * 0.35
			"troops", "mil":
				s += v * 0.2
			_:
				s += v * 0.25
	if opt.has("gamble"):
		var g: Dictionary = opt.gamble
		s += 0.5 * (float(g.get("p", 0.5)) - 0.4)
	s -= Cabinet.fatal_chance(gs, opt) * 200.0
	return s


func _play_card(card: Dictionary) -> void:
	var opts: Array = card.get("o", [])
	if opts.is_empty():
		return
	var best: Dictionary = opts[0]
	var bs := -1.0e9
	for o in opts:
		var sc: float = _opt_score(o)
		if sc > bs:
			bs = sc
			best = o
	var fatal: float = Cabinet.fatal_chance(gs, best)
	if fatal > 0.0 and rng.randf() < fatal:
		gs.game_over.emit(false, "Kader anı: kabine kararı ölümcül sonuçlandı.")
		n("kabine_ölüm")
		return
	Cabinet.resolve(gs, rng, card, best)
	n("kabine_kartı")


func _cabinet_turn() -> void:
	var me = gs.countries[gs.player]
	if not gs.crisis_pending.is_empty():
		var cc: Dictionary = gs.crisis_pending
		gs.crisis_pending = {}
		_play_card(cc)
	var sc: Dictionary = Cabinet.scn_card(gs)
	if not sc.is_empty():
		_play_card(sc)
	var sched: Dictionary = Cabinet.scheduled(gs)
	if not sched.is_empty():
		_play_card(sched)
	for role in Cabinet.vacancies(gs):
		var cands: Array = Cabinet.candidates(gs, role)
		var pick: Dictionary = cands[1]
		for cd in [cands[2], cands[1], cands[0]]:
			if cd.afford:
				pick = cd
				break
		Cabinet.appoint(gs, role, pick)
		n("bakan_atama")
	var card: Dictionary = Cabinet.pick(gs, cab_last, cab_recent, rng)
	if not card.is_empty():
		cab_last = gs.turn
		cab_recent.append(card.id)
		if cab_recent.size() > 10:
			cab_recent.pop_front()
		_play_card(card)


# ------------------------------------------------------------------ her tur

func act() -> void:
	var me = gs.countries[gs.player]
	if not me.alive:
		return
	var at_war: bool = false
	var big_foe := 0
	for e in me.enemies:
		var fc = gs.countries[e]
		if fc.is_rebel:
			at_war = true
			big_foe = maxi(big_foe, fc.troops)
		else:
			at_war = true
			big_foe = maxi(big_foe, fc.troops)
	# bütçe
	var want := "peace"
	if at_war:
		want = "war"
	elif me.aggression > 0.65 or (attacker and me.gold > me.income * 10.0):
		want = "hawk"
	elif me.capacity < 0.22:
		want = "poor"
	if gs.turn % 4 == 0 or at_war != (me.budget.get("mil", 18) > 30):
		var preset: Dictionary = Macro.PRESETS[want]
		if JSON.stringify(me.budget) != JSON.stringify(preset):
			me.budget = preset.duplicate()
	# seferberlik ve yardım ve barış
	if at_war:
		if big_foe > me.troops * 0.5 and not Macro.mob_active(me) and me.mob_cd <= gs.turn and me.gold > Macro.mob_cost(me) * 1.3:
			if Macro.mobilize(gs, me) == "":
				n("seferberlik")
		if gs.turn % 5 == 0:
			gs.player_request_aid_all()
			n("yardım_iste")
		if gs.turn % 3 == 0:
			for e in me.enemies.duplicate():
				if gs.countries[e].is_rebel:
					continue
				var r: Dictionary = gs.player_request_peace(e)
				if r.get("ok", false):
					if r.get("mode", "") == "player_wins":
						var w = r["war"]
						gs.finish_peace(w, gs.player, gs._ai_choose_annex(w, gs.player))
					n("barış_istedi")
	else:
		# barışta: bina, ilişki, ittifak, odak
		if gs.turn % 6 == 0:
			_diplomacy(me)
		if gs.turn % 5 == 0 and me.gold > me.income * 6.0:
			_build(me)
	if gs.turn % 3 == 0:
		_focus()
	# kasada çok altın birikirse yatırım bütçesi
	if not at_war and me.gold > me.income * 40.0:
		me.budget = {"mil": 14, "ind": 40, "cyber": 8, "logi": 12, "stab": 16, "res": 10}
	# hedefe göre savaş
	if attacker or Obj.active(gs):
		_pursue(me)
	_cabinet_turn()


func _focus() -> void:
	Focus.ensure(gs)
	if String(gs.focus.cur) != "":
		return
	var best := ""
	var bw := 9999
	for id in Focus.TREE:
		if Focus.can_start(gs, id) == "":
			var w: int = int(Focus.TREE[id].weeks)
			if w < bw:
				bw = w
				best = id
	if best != "":
		Focus.start(gs, best)
		n("odak")


func _build(me) -> void:
	var cands: Array = []
	for pid in me.owned_ids:
		var p = gs.provinces[pid]
		if p.bld == "" and p.bld_wip == "" and p.controller == gs.player and p.siege <= 0:
			cands.append(p)
	if cands.is_empty():
		return
	cands.sort_custom(func(a, b): return a.base_rev() > b.base_rev())
	var p0 = cands[0]
	var bestk := ""
	var bv := 0.0
	for k in Model.BLD:
		var v: float = float(Model.BLD[k].bonus) / maxf(p0.bld_cost(k), 1.0)
		if v > bv:
			bv = v
			bestk = k
	if bestk != "" and gs.player_build(p0.id, bestk) == "":
		n("bina")


func _diplomacy(me) -> void:
	var nbs: Array = gs.neighbor_countries(gs.player)
	nbs.sort_custom(func(a, b): return gs.relation_of(gs.player, a) > gs.relation_of(gs.player, b))
	var tried := 0
	for o in nbs:
		var oc = gs.countries[o]
		if not oc.alive or oc.is_rebel or gs.at_war(gs.player, o):
			continue
		if tried >= 2:
			break
		tried += 1
		if not gs.is_allied(gs.player, o) and me.allies.size() < 3:
			var r: String = gs.player_propose_alliance(o)
			if r == "":
				n("ittifak_kur")
				continue
		if gs.relation_of(gs.player, o) < 70.0:
			var r2: String = gs.player_improve_relations(o, "envoy")
			if r2 == "":
				n("elçi")


## Hedefler: ülke yok etme / başkent alma / eyalet sayısı → uygun komşuya savaş aç
func _pursue(me) -> void:
	if gs.turn % 4 != 2:
		return
	var targets: Array = []
	for o in Obj.list(gs):
		if Obj.is_done(gs, o):
			continue
		match String(o.get("type", "")):
			"eliminate":
				targets.append(Obj._cid(gs, String(o.country)))
			"own_capital":
				var ci: int = Obj._cid(gs, String(o.country))
				if ci != gs.player:
					targets.append(ci)
			"own_province":
				var pp = Obj._prov(gs, o.province)
				if pp != null and pp.owner != gs.player and pp.owner >= 0:
					targets.append(pp.owner)
			"own_provinces":
				if attacker:
					var nb: Array = gs.neighbor_countries(gs.player)
					var weakest := -1
					for x in nb:
						var xc = gs.countries[x]
						if xc.alive and not xc.is_rebel and (weakest < 0 or xc.troops < gs.countries[weakest].troops):
							weakest = x
					targets.append(weakest)
	for t in targets:
		if t < 0 or t == gs.player or not gs.countries[t].alive:
			continue
		var tc = gs.countries[t]
		if gs.at_war(gs.player, t) or gs.is_allied(gs.player, t):
			continue
		if not gs.neighbor_countries(gs.player).has(t):
			continue
		# yeterince güçlüysen ya da müttefiklerle birlikte saldır
		var mine: int = me.troops
		for a in me.allies:
			mine += int(gs.countries[a].troops * 0.5)
		if mine > tc.troops * 1.3 and int(me.truce.get(t, -1)) <= gs.turn:
			gs.player_declare_war(t)
			n("savaş_ilan")
			return
