extends RefCounted
## Mal ve kaynak ekonomisi (Age of History tarzı): tahıl, kereste, maden, petrol.
## Her ülke eyaletlerinden mal üretir, halkı ve sanayisi tüketir; fark otomatik pazardan alınır/satılır (hazine etkilenir),
## stok biriktirilebilir, kıtlık istikrarı / sanayiyi / lojistiği vurur. Her şey deterministik (kayda yalnızca stok ve politika girer).

const Cmd = preload("res://scripts/cmd.gd")
const GOODS := ["grain", "wood", "ore", "oil"]
const NAMES := {"grain": "Tahıl", "wood": "Kereste", "ore": "Maden cevheri", "oil": "Petrol ve gaz"}
const ICONS := {"grain": "wheat", "wood": "axe", "ore": "bld_mine", "oil": "bld_oil"}
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


static func ensure(c) -> void:
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
		c.goods = {"stock": st, "pol": pol, "net": net, "rate": rate, "short": {}, "gold": 0.0}


## Eyalet başına haftalık üretim (birim)
static func prov_prod(p, g: String) -> float:
	var pop: float = maxf(0.05, p.pop)
	var rk: String = p.rich()
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


static func _recount(gs, c) -> void:
	var prod := {"grain": 0.0, "wood": 0.0, "ore": 0.0, "oil": 0.0}
	var pop := 0.0
	for p in gs.provinces:
		if p.owner != c.id or p.controller != c.id:
			continue
		pop += maxf(0.05, p.pop)
		for g in GOODS:
			prod[g] += prod_for(p, g)
	var ind: float = 0.7 + 0.6 * clampf(c.industry, 0.0, 100.0) / 100.0
	var war: float = 1.0 + (0.15 if not c.enemies.is_empty() else 0.0)
	for g in GOODS:
		var d: float = pop * float(DEMAND[g]) * ind
		if g == "oil":
			d *= war
		c.goods.rate[g] = {"prod": prod[g], "dem": maxf(0.01, d)}


static func prod_for(p, g: String) -> float:
	return prov_prod(p, g)


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
	if (gs.turn + c.id) % 4 == 0 or c.id == gs.player or float(g0.rate.oil.dem) <= 0.0:
		_recount(gs, c)
	var inc: float = maxf(c.income, 1.0)
	var avail: float = open_share(c)
	var money := 0.0
	var short := {}
	for g in GOODS:
		var r: Dictionary = g0.rate[g]
		var prod: float = float(r.prod)
		var dem: float = float(r.dem)
		var pol: String = str(g0.pol.get(g, "auto"))
		var stock: float = float(g0.stock.get(g, 0.0))
		var px: float = price(gs, g)
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
				money += net_units * avail * unit * px * SELL_DISCOUNT
		else:
			var need: float = -diff
			var from_stock: float = minf(stock, need)
			stock -= from_stock
			need -= from_stock
			if need > 0.0:
				var bought: float = need * avail
				if c.gold < 0.0:
					bought = 0.0
				money -= bought * unit * px * BUY_PREMIUM
				var unmet: float = need - bought
				if unmet > 0.001:
					short[g] = clampf(unmet / dem, 0.0, 1.0)
		g0.stock[g] = stock
		g0.net[g] = prod - dem
	g0.short = short
	money += inc * 0.05           # iç pazarın olağan payı (ortalama ülke için ticaret dengeli kalsın)
	money = clampf(money, -inc * 0.08, inc * 0.13)
	g0.gold = money
	for k in short:
		var s: float = float(short[k])
		match k:
			"grain":
				c.stability = clampf(c.stability - 0.5 * s, 3.0, 100.0)
			"wood", "ore":
				c.industry = clampf(c.industry - 0.25 * s, 5.0, 100.0)
			"oil":
				c.logistics = clampf(c.logistics - 0.3 * s, 5.0, 100.0)
	return money


## Kayıt
static func to_dict(c) -> Dictionary:
	if c.goods.is_empty():
		return {}
	return {"stock": c.goods.stock, "pol": c.goods.pol}


static func from_dict(c, d: Dictionary) -> void:
	ensure(c)
	if d.is_empty():
		return
	for g in GOODS:
		c.goods.stock[g] = float(d.get("stock", {}).get(g, 0.0))
		var pv: String = str(d.get("pol", {}).get(g, "auto"))
		c.goods.pol[g] = pv if POLICIES.has(pv) else "auto"
