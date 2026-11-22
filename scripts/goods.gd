extends RefCounted
## Mal ve kaynak ekonomisi (Age of History tarzı): tahıl, kereste, maden, petrol.
## Her ülke eyaletlerinden mal üretir, halkı ve sanayisi tüketir; fark otomatik pazardan alınır/satılır (hazine etkilenir),
## stok biriktirilebilir, kıtlık istikrarı / sanayiyi / lojistiği vurur. Her şey deterministik (kayda yalnızca stok ve politika girer).

const Cmd = preload("res://scripts/cmd.gd")
const Loc = preload("res://scripts/loc.gd")
const GOODS := ["grain", "wood", "ore", "oil"]
const NAMES := {"grain": "Tahıl", "wood": "Kereste", "ore": "Maden cevheri", "oil": "Petrol ve gaz"}
const ICONS := {"grain": "wheat", "wood": "crate", "ore": "bld_mine", "oil": "bld_oil"}
## Haftalık gelirin yüzde kaçı o malın ticaretine denk gelir (fiyat 1.0 iken, tüm talep ithal edilirse)
const SHARE := {"grain": 0.06, "wood": 0.03, "ore": 0.04, "oil": 0.07}
## Kişi (milyon nüfus) başına talep
const DEMAND := {"grain": 1.0, "wood": 0.30, "ore": 0.20, "oil": 0.25}
const POLICIES := ["auto", "hold", "sell"]
const POLICY_NAMES := {"auto": "Otomatik", "hold": "Depola", "sell": "Sat"}
const BUY_PREMIUM := 1.15
const SELL_DISCOUNT := 0.85
const CAP_AUTO := 8.0       # otomatik: talebin kaç haftalık stoğu tutulur
const CAP_HOLD := 40.0


## Ekranda gösterim: küçük değerler ondalıklı, büyükler tam sayı
static func fmt(v: float) -> String:
	var a: float = absf(v)
	if a >= 100.0:
		return "%d" % int(round(v))
	if a >= 10.0:
		return "%.0f" % v
	return "%.1f" % v


static func ensure(c) -> void:
	if not c.goods.is_empty() and not c.goods.has("deals"):
		c.goods["deals"] = []
	if c.goods.is_empty():
		var st := {}
		var pol := {}
		var net := {}
		var rate := {}
		for g in GOODS:
			st[g] = 0.0
			pol[g] = "auto"
			net[g] = 0.0
			rate[g] = {"prod": 0.0, "dem": 0.0}
		c.goods = {"deals": [], "stock": st, "pol": pol, "net": net, "rate": rate, "short": {}, "gold": 0.0}


## Eyalet başına haftalık üretim (birim)
static func prov_prod(p, g: String, rk: String = "") -> float:
	var pop: float = maxf(0.05, p.pop)
	var h2: int = int((p.id * 40503) % 100)
	match g:
		"grain":
			var m := 1.0
			if p.bld == "farm":
				m = 1.5 * (1.3 if rk == "farm" else 1.0)
			elif rk == "farm":
				m = 1.25
			return pop * m
		"wood":
			var m := 2.2 if h2 < 40 else 0.4
			if p.bld == "wood":
				m = 1.8 * m * (1.3 if rk == "wood" else 1.0)
			elif rk == "wood":
				m *= 1.5
			return pop * 0.3 * m
		"ore":
			var m := 1.0
			if p.bld == "mine":
				m = 2.2 * (1.3 if rk == "mine" else 1.0)
			elif rk == "mine":
				m = 2.0
			return pop * 0.2 * m
		"oil":
			var m := 0.2
			if rk == "oil":
				m = 7.0 if p.bld == "oil" else 6.0
				if p.bld == "oil":
					m *= 1.3
			elif p.bld == "oil":
				m = 0.8
			return pop * 0.25 * m
	return 0.0


static var _acc: Dictionary = {}
static var _acc_turn := -99
static var _acc_gs := 0


## Tüm eyaletleri tek geçişte tarar: ülke -> {pop, prod{...}} (4 haftada bir; oyuncu için her tur)
static func _scan(gs, only: int = -1) -> Dictionary:
	var acc := {}
	for p in gs.provinces:
		if p.owner < 0 or p.owner != p.controller or (only >= 0 and p.owner != only):
			continue
		var e: Dictionary = acc.get(p.owner, {})
		if e.is_empty():
			e = {"pop": 0.0, "grain": 0.0, "wood": 0.0, "ore": 0.0, "oil": 0.0, "school": 0, "refinery": 0, "export": 0}
			acc[p.owner] = e
		var rk: String = p.rich()
		if p.bld == "school" or p.bld == "refinery" or p.bld == "export":
			e[p.bld] = int(e[p.bld]) + 1
		e.pop += maxf(0.05, p.pop)
		for g in GOODS:
			e[g] += prov_prod(p, g, rk)
	return acc


static func _recount(gs, c) -> void:
	var e: Dictionary
	if c.id == gs.player:
		e = _scan(gs, c.id).get(c.id, {})
	else:
		var gid: int = gs.get_instance_id()
		if _acc_gs != gid or gs.turn - _acc_turn >= 4 or gs.turn < _acc_turn:
			_acc = _scan(gs)
			_acc_turn = gs.turn
			_acc_gs = gid
		e = _acc.get(c.id, {})
	var pop: float = float(e.get("pop", 0.0))
	c.goods["bl"] = {"school": int(e.get("school", 0)), "refinery": int(e.get("refinery", 0)), "export": int(e.get("export", 0))}
	var ind: float = 0.7 + 0.6 * clampf(c.industry, 0.0, 100.0) / 100.0
	var war: float = 1.0 + (0.15 if not c.enemies.is_empty() else 0.0)
	for g in GOODS:
		var d: float = pop * float(DEMAND[g]) * ind
		if g == "oil":
			d *= war
		c.goods.rate[g] = {"prod": float(e.get(g, 0.0)), "dem": maxf(0.01, d)}


static func prod_for(p, g: String) -> float:
	return prov_prod(p, g, p.rich())


## Küresel fiyat endeksi (1.0 etrafında, savaşlarda petrol pahalanır)
static func price(gs, g: String) -> float:
	var i: int = GOODS.find(g)
	var base: float = 1.0 + 0.10 * sin(float(gs.turn) * 0.11 + float(i) * 1.7)
	if g == "oil":
		base += 0.03 * float(mini(8, gs.wars.size()))
	return base


static func open_share(c) -> float:
	if c.trade_block > 0:
		return 0.0
	return clampf((0.35 + 0.65 * c.trade_share) * (1.0 - clampf(c.blockade, 0.0, 1.0)), 0.0, 1.0)


const DEAL_WEEKS := 52
const DEAL_DISCOUNT := 0.80      # anlaşmalı alımda fiyat çarpanı


static func deal_of(c, g: String) -> Dictionary:
	for d in c.goods.get("deals", []):
		if d.good == g:
			return d
	return {}


## Anlaşma yapılabilecek tedarikçiler: o maldan açık verebilen, savaşta/ambargoda olmayan canlı ülkeler (en çok fazlası olandan başlayarak)
static func suppliers(gs, c, g: String) -> Array:
	var out: Array = []
	for o in gs.countries:
		if not o.alive or o.is_rebel or o.id == c.id:
			continue
		if c.enemies.has(o.id) or c.embargo.has(o.id) or o.embargo.has(c.id) or o.trade_block > 0:
			continue
		ensure(o)
		if float(o.goods.rate[g].dem) <= 0.02 or float(o.goods.rate[g].prod) < float(o.goods.rate[g].dem) * 1.25:
			continue
		var sur: float = float(o.goods.rate[g].prod) - float(o.goods.rate[g].dem)
		out.append([o.id, sur])
	out.sort_custom(func(a, b): return a[1] > b[1])
	return out.slice(0, 6)


static func make_deal(gs, me, g: String, pid: int) -> String:
	var _cmd := Cmd.Scope.new(gs, "Goods.make_deal", [me, g, pid])
	ensure(me)
	if not GOODS.has(g) or pid < 0 or pid >= gs.countries.size():
		return "Geçersiz anlaşma."
	if not deal_of(me, g).is_empty():
		return "Bu malda zaten anlaşman var."
	var ok := false
	for s in suppliers(gs, me, g):
		if s[0] == pid:
			ok = true
	if not ok:
		return "Bu ülke şu an bu malı satamaz."
	if (me.goods.deals as Array).size() >= 3:
		return "En çok 3 anlaşma yapılabilir."
	me.goods.deals.append({"good": g, "partner": pid, "until": gs.turn + DEAL_WEEKS})
	me.relation[pid] = minf(100.0, float(me.relation.get(pid, 50.0)) + 6.0)
	gs.countries[pid].relation[me.id] = minf(100.0, float(gs.countries[pid].relation.get(me.id, 50.0)) + 6.0)
	return ""


static func cancel_deal(gs, me, g: String) -> void:
	var _cmd := Cmd.Scope.new(gs, "Goods.cancel_deal", [me, g])
	ensure(me)
	var keep: Array = []
	for d in me.goods.deals:
		if d.good != g:
			keep.append(d)
	me.goods.deals = keep


static func _deal_valid(gs, c, d: Dictionary) -> bool:
	if gs.turn >= int(d.until):
		return false
	var o = gs.countries[int(d.partner)]
	if not o.alive or o.is_rebel or c.enemies.has(o.id) or c.embargo.has(o.id) or o.embargo.has(c.id):
		return false
	return o.trade_block <= 0 and c.trade_block <= 0


## Ekranda gösterilen güncel oran (ilk turda henüz hesaplanmamışsa hesaplar)
static func refresh(gs, c) -> void:
	ensure(c)
	if float(c.goods.rate.oil.dem) <= 0.011:
		_recount(gs, c)


static func set_policy(c, good: String, pol: String) -> bool:
	var _cmd := Cmd.Scope.new(Cmd.rec_gs, "Goods.set_policy", [c, good, pol])
	ensure(c)
	if not GOODS.has(good) or not POLICIES.has(pol):
		return false
	c.goods.pol[good] = pol
	return true


## Haftalık işlem: stok, pazar, kıtlık. Hazineye eklenecek net parayı döndürür.
static func weekly(gs, c) -> float:
	ensure(c)
	var g0: Dictionary = c.goods
	var slot: bool = (gs.turn + c.id) % 4 == 0
	# YZ ülkeleri: tam hesap 4 turda bir; aradaki turlarda son sonuç (para + kıtlık cezası) aynen uygulanır
	if not slot and c.id != gs.player and g0.has("gold") and (g0.deals as Array).is_empty() and float(g0.rate.oil.dem) > 0.0:
		_apply_short(c, g0.short)
		return float(g0.gold)
	if slot or c.id == gs.player or float(g0.rate.oil.dem) <= 0.0:
		_recount(gs, c)
	var inc: float = maxf(c.income, 1.0)
	var avail0: float = open_share(c)
	if not (g0.deals as Array).is_empty():
		var live: Array = []
		for d in g0.deals:
			if _deal_valid(gs, c, d):
				live.append(d)
			elif c.id == gs.player:
				gs.post_news(Loc.t("%s ile %s anlaşması sona erdi.") % [gs.countries[int(d.partner)].name, Loc.t(NAMES[d.good])], -1, "info", "", c.id)
		g0.deals = live
	var money := 0.0
	var short := {}
	var bl: Dictionary = g0.get("bl", {})
	var ex_mult: float = 1.0 + 0.06 * float(mini(5, int(bl.get("export", 0))))
	var ref_mult: float = 1.0 + 0.08 * float(mini(5, int(bl.get("refinery", 0))))
	var nsch: int = mini(10, int(bl.get("school", 0)))
	if nsch > 0:
		c.tech = minf(1.0, c.tech + 0.00012 * float(nsch))
	for g in GOODS:
		var r: Dictionary = g0.rate[g]
		var prod: float = float(r.prod)
		var dem: float = float(r.dem)
		var pol: String = str(g0.pol.get(g, "auto"))
		var stock: float = float(g0.stock.get(g, 0.0))
		var px: float = price(gs, g)
		var deal: Dictionary = deal_of(c, g)
		var avail: float = maxf(avail0, 0.9) if not deal.is_empty() else avail0
		var unit: float = inc * float(SHARE[g]) / dem          # 1 birimin değeri (fiyat 1.0)
		var diff: float = prod - dem
		var cap: float = dem * (CAP_HOLD if pol == "hold" else CAP_AUTO)
		var net_units := 0.0                                    # pazara satılacak miktar
		if diff >= 0.0:
			var keep: float = diff
			if stock + keep > cap:
				keep = maxf(0.0, cap - stock)
			stock += keep
			net_units = diff - keep
			if pol == "sell":
				var drain: float = stock * 0.10
				stock -= drain
				net_units += drain
			if net_units > 0.0:
				money += net_units * avail * unit * px * SELL_DISCOUNT * ex_mult * (ref_mult if g == "oil" else 1.0)
		else:
			var need: float = -diff
			var from_stock: float = minf(stock, need)
			stock -= from_stock
			need -= from_stock
			if need > 0.0:
				var bought: float = need * avail
				if c.gold < 0.0:
					bought = 0.0
				var bill: float = bought * unit * px * BUY_PREMIUM * (DEAL_DISCOUNT if not deal.is_empty() else 1.0)
				money -= bill
				if not deal.is_empty():
					var po = gs.countries[int(deal.partner)]
					po.gold += bill * 0.6
				var unmet: float = need - bought
				if unmet > 0.001:
					short[g] = clampf(unmet / dem, 0.0, 1.0)
		g0.stock[g] = stock
		g0.net[g] = prod - dem
	g0.short = short
	money += inc * 0.05           # iç pazarın olağan payı (ortalama ülke için ticaret dengeli kalsın)
	money = clampf(money, -inc * 0.08, inc * 0.13)
	g0.gold = money
	_apply_short(c, short)
	return money


static func _apply_short(c, short: Dictionary) -> void:
	for k in short:
		var s: float = float(short[k])
		match k:
			"grain":
				c.stability = clampf(c.stability - 0.5 * s, 3.0, 100.0)
			"wood", "ore":
				c.industry = clampf(c.industry - 0.25 * s, 5.0, 100.0)
			"oil":
				c.logistics = clampf(c.logistics - 0.3 * s, 5.0, 100.0)


## Kayıt
static func to_dict(c) -> Dictionary:
	if c.goods.is_empty():
		return {}
	return {"stock": c.goods.stock, "pol": c.goods.pol, "deals": c.goods.get("deals", [])}


static func from_dict(c, d: Dictionary) -> void:
	ensure(c)
	if d.is_empty():
		return
	for g in GOODS:
		c.goods.stock[g] = float(d.get("stock", {}).get(g, 0.0))
		var pv: String = str(d.get("pol", {}).get(g, "auto"))
		c.goods.pol[g] = pv if POLICIES.has(pv) else "auto"
	c.goods.deals = (d.get("deals", []) as Array).duplicate(true)
