extends RefCounted
## Hava filoları: haritada üsleri olan, menzili dâhilindeki hedeflere uçan hava kanatları (avcı, bombardıman, İHA, nakliye, keşif/AWACS).
## Gücü ülkenin hava gücünden (c.air_pow / envanterdeki uçak kalemleri) türetilir; kayıplar envantere yansır.
## Durum gs.wings (id -> Model.Wing). Rastgelelik gs.rng'ye dokunmaz.

const Model = preload("res://scripts/model.gd")
const Macro = preload("res://scripts/macro.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Settings = preload("res://scripts/settings.gd")
const Loc = preload("res://scripts/loc.gd")
const Ext = preload("res://scripts/fleet_ext.gd")
const Eras = preload("res://scripts/eras.gd")
const Cmd = preload("res://scripts/cmd.gd")

const KINDS := ["fighter", "bomber", "drone", "transport", "recon"]
const KIND_TR := {"fighter": "Avcı filosu", "bomber": "Bombardıman filosu", "drone": "İHA filosu", "transport": "Hava nakliye filosu", "recon": "Keşif ve erken uyarı filosu"}
const KIND_TPL := {"fighter": "%d. Avcı Filosu", "bomber": "%d. Bombardıman Filosu", "drone": "%d. İHA Filosu", "transport": "%d. Nakliye Filosu", "recon": "%d. Keşif Filosu"}
const KIND_CP := {"fighter": 1.0, "bomber": 1.0, "drone": 0.7, "transport": 0.0, "recon": 0.2}
const KIND_HINT := {
	"fighter": "Avcılar hava üstünlüğü kazanır: menzilindeki karada savaşan ordulara bonus verir, düşman bombardıman ve nakliye uçaklarını önler, bombardımanlara eşlik eder.",
	"bomber": "Bombardıman uçakları menzilindeki düşman eyaletlerini vurur: ordu kaybettirir, savunmayı ve sanayiyi bozar. Düşman avcıları önleyebilir; avcı eşliği kayıpları azaltır.",
	"drone": "İHA'lar ucuz ve pilotsuzdur: bombardımandan zayıf ama menzili geniştir; düşman avcıları az etkiler.",
	"transport": "Hava nakliye: orduyu menzildeki dost eyalete uçurur ya da düşman eyaletine paraşütle indirir. Korumasız kalırsa vurulur.",
	"recon": "Keşif ve erken uyarı uçakları düşman filo/üslerini görür, avcıların önlemesini ve savunma bonusunu artırır.",
}
const RANGE_KM := {"fighter": 1200.0, "bomber": 3500.0, "drone": 2500.0, "transport": 3000.0, "recon": 2500.0}
const ERA_RANGE := {"pre": 0.0, "ww1": 0.25, "ww2": 0.6, "cold": 0.9, "": 1.0}
const UNIT_F := {"pre": 1.0, "ww1": 1.0, "ww2": 1.2, "cold": 8.0, "": 10.0}     # hava gücü / uçak sayısı
const SHARE := {
	"ww1": {"fighter": 0.6, "bomber": 0.4},
	"ww2": {"fighter": 0.44, "bomber": 0.36, "transport": 0.12, "recon": 0.08},
	"cold": {"fighter": 0.44, "bomber": 0.32, "transport": 0.12, "recon": 0.12},
	"": {"fighter": 0.38, "bomber": 0.2, "drone": 0.16, "transport": 0.12, "recon": 0.14},
}
const KM_PER_PX := 20.0
const STRIKE_CD := 2
const MAX_PER_KIND := 2
const MIN_UNITS := 3.0
const DEFEND_BONUS := 1.2
const NEWS_MAX := 3

static var enabled := true
static var _news_left := 0

# uçak sınıfları: tür -> çağ -> [[anahtar, ad, ağırlık], ...]
const CLASSES := {
	"fighter": {
		"ww1": [["biplane", "Çift kanatlı avcı", 1.0]],
		"ww2": [["prop_fighter", "Piston motorlu avcı", 0.6], ["escort_fighter", "Eskort avcısı", 0.4]],
		"cold": [["jet_fighter", "Jet avcı", 0.6], ["interceptor", "Önleyici avcı", 0.4]],
		"": [["gen4", "4. nesil çok rollü avcı", 0.55], ["gen5", "5. nesil hayalet avcı", 0.25], ["interceptor", "Önleyici avcı", 0.2]],
	},
	"bomber": {
		"ww1": [["gotha", "Ağır bombardıman", 1.0]],
		"ww2": [["medium", "Orta bombardıman", 0.5], ["heavy", "Ağır bombardıman", 0.3], ["dive", "Pike bombardıman", 0.2]],
		"cold": [["jet_bomber", "Jet bombardıman", 0.5], ["strategic", "Stratejik bombardıman", 0.5]],
		"": [["attack", "Taarruz uçağı", 0.45], ["strategic", "Stratejik bombardıman", 0.25], ["strike", "Çok rollü taarruz", 0.15], ["heli", "Taarruz helikopteri", 0.15]],
	},
	"drone": {"": [["male", "Silahlı İHA", 0.6], ["loiter", "Dolaşan mühimmat", 0.4]], "cold": [["male", "Silahlı İHA", 1.0]], "ww2": [["male", "Silahlı İHA", 1.0]], "ww1": [["male", "Silahlı İHA", 1.0]]},
	"transport": {
		"ww1": [["tr1", "Nakliye uçağı", 1.0]],
		"ww2": [["dakota", "Nakliye uçağı", 0.6], ["glider", "Planör", 0.4]],
		"cold": [["tr2", "Nakliye uçağı", 1.0]],
		"": [["tactical", "Taktik nakliye uçağı", 0.6], ["heavy_tr", "Ağır stratejik nakliye", 0.4]],
	},
	"recon": {
		"ww1": [["recon1", "Keşif uçağı", 1.0]],
		"ww2": [["recon2", "Keşif uçağı", 1.0]],
		"cold": [["elint", "Keşif ve ELINT uçağı", 1.0]],
		"": [["awacs", "AWACS erken uyarı uçağı", 0.5], ["elint", "Keşif ve ELINT uçağı", 0.3], ["tanker", "Havada yakıt ikmal uçağı", 0.2]],
	},
}


# ------------------------------------------------------------------ yardımcılar

static var _fam_key := "\u0001"
static var _fam_val := ""


static func family() -> String:
	var cur: String = Eras.current          # çağ ailesi hesabı pahalı: çağ değişmedikçe önbellekten
	if cur == _fam_key:
		return _fam_val
	var f: String = Ext.family()
	_fam_val = f if UNIT_F.has(f) and f != "pre" else ("pre" if f == "pre" else "")
	_fam_key = cur
	return _fam_val


static func units(c) -> float:
	return c.air_pow / float(UNIT_F.get(family(), 10.0))


static func qualifies(c) -> bool:
	return c.alive and not c.is_rebel and family() != "pre" and units(c) >= MIN_UNITS


static func cp(w) -> float:
	return w.size * float(KIND_CP.get(w.kind, 1.0)) * Ext.rank_mult(w.xp)


static func disp(w) -> int:
	return maxi(1, int(round(w.size)))


static func kind_name(kind: String) -> String:
	return String(KIND_TR.get(kind, kind))


static func kind_icon(kind: String) -> String:
	match kind:
		"bomber":
			return "uc_bomber"
		"transport":
			return "plane"
		"drone":
			return "drone"
		"recon":
			return "radar"
	return "uc_jet"


static func range_px(kind: String) -> float:
	return float(RANGE_KM.get(kind, 1000.0)) * float(ERA_RANGE.get(family(), 1.0)) / KM_PER_PX


static func range_km(kind: String) -> int:
	return int(round(float(RANGE_KM.get(kind, 1000.0)) * float(ERA_RANGE.get(family(), 1.0)) / 50.0)) * 50


static func _rng(gs, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([gs.seed_value, gs.turn, salt, 77])
	return r


static func dist(gs, a: int, b: int) -> float:
	return gs.provinces[a].label_pos.distance_to(gs.provinces[b].label_pos)


static var _reach: Dictionary = {}
static var _reach_fam: String = "?"
static var _reach_n: int = -1


## Bir üssün menzilindeki eyaletler (üs + tür başına önbellek; harita sabit olduğu için çağ/harita değişince temizlenir)
static func reach(gs, base: int, kind: String) -> Array:
	var fam: String = family()
	if fam != _reach_fam or gs.provinces.size() != _reach_n:
		_reach.clear()
		_reach_fam = fam
		_reach_n = gs.provinces.size()
	var key: int = base * 8 + KINDS.find(kind)
	if _reach.has(key):
		return _reach[key]
	var rng_px: float = range_px(kind)
	var bpos: Vector2 = gs.provinces[base].label_pos
	var out: Array = []
	for p in gs.provinces:
		if p.label_pos.distance_to(bpos) <= rng_px:
			out.append(p.id)
	_reach[key] = out
	return out


static func in_range(gs, w, pid: int) -> bool:
	return w.base >= 0 and dist(gs, w.base, pid) <= range_px(w.kind)


static func new_wing(gs, owner: int, base: int, kind: String, size: float):
	var w = Model.Wing.new()
	w.id = gs.next_wing_id
	gs.next_wing_id += 1
	w.owner = owner
	w.base = base
	w.kind = kind
	w.size = size
	w.born = gs.turn
	gs.wings[w.id] = w
	return w


static func wings_of(gs, cid: int) -> Array:
	var out: Array = []
	for w in gs.wings.values():
		if w.owner == cid:
			out.append(w)
	return out


static func wings_at(gs, pid: int) -> Array:
	var out: Array = []
	for w in gs.wings.values():
		if w.base == pid:
			out.append(w)
	return out


# ------------------------------------------------------------------ üsler

## Üs olabilecek eyaletler: ülkenin elindeki eyaletler (başkent ilk); gelişmişliğe göre sıralı
static func base_candidates(gs, c) -> Array:
	var out: Array = []
	for pid in c.held_ids:
		var p = gs.provinces[pid]
		if p.controller == c.id:
			out.append(pid)
	out.sort_custom(func(a, b):
		var pa = gs.provinces[a]
		var pb = gs.provinces[b]
		if pa.is_capital != pb.is_capital:
			return pa.is_capital
		if pa.dev != pb.dev:
			return pa.dev > pb.dev
		return a < b)
	return out


## n adet birbirinden uzak üs seç (ülke küçükse hepsi başkentte)
static func pick_bases(gs, c, n: int) -> Array:
	var cands: Array = base_candidates(gs, c)
	var out: Array = []
	if cands.is_empty():
		return out
	out.append(cands[0])
	var sep: float = 70.0
	for pid in cands:
		if out.size() >= n:
			break
		var far := true
		for b in out:
			if dist(gs, pid, b) < sep:
				far = false
				break
		if far:
			out.append(pid)
	while out.size() < n:
		out.append(cands[0])
	return out


static func nearest_base(gs, c, from_pid: int) -> int:
	var best := -1
	var bd := 1e18
	for pid in c.held_ids:
		var p = gs.provinces[pid]
		if p.controller != c.id:
			continue
		var d: float = dist(gs, from_pid, pid) if from_pid >= 0 else 0.0
		if d < bd:
			bd = d
			best = pid
	return best


# ------------------------------------------------------------------ kurulum / eşitleme

static func ensure(gs) -> void:
	if gs.wings_ready:
		return
	gs.wings = {}
	gs.next_wing_id = 1
	gs.wings_ready = true
	for c in gs.countries:
		if qualifies(c):
			sync_country(gs, c, true)


static func reset(gs) -> void:
	gs.wings = {}
	gs.next_wing_id = 1
	gs.wings_ready = false


static func _sum_kind(lst: Array, kind: String) -> float:
	var s := 0.0
	for w in lst:
		if w.kind == kind:
			s += w.size
	return s


static func _kind_list(lst: Array, kind: String) -> Array:
	var out: Array = []
	for w in lst:
		if w.kind == kind:
			out.append(w)
	return out


## Ülkenin kanatlarını hava gücüyle eşitle (tür başına pay)
static var _sync_mult: float = 1.0


static func sync_country(gs, c, fresh: bool = false, pre: Array = []) -> void:
	var lst: Array = pre if not pre.is_empty() else wings_of(gs, c.id)
	var ok: bool = qualifies(c)
	var share: Dictionary = SHARE.get(family(), SHARE[""])
	var u: float = units(c) if ok else 0.0
	for kind in KINDS:
		var sh: float = float(share.get(kind, 0.0))
		var tgt: float = u * sh
		var cur_l: Array = _kind_list(lst, kind)
		var cur: float = _sum_kind(lst, kind)
		if sh <= 0.0 or tgt < 1.0:
			if cur_l.size() > 0 and (not ok or sh <= 0.0):
				for w in cur_l:
					gs.wings.erase(w.id)
			continue
		if cur_l.is_empty():
			var n: int = 2 if (tgt >= 400.0 and (kind == "fighter" or kind == "bomber")) else 1
			var bases: Array = pick_bases(gs, c, n if fresh else 1)
			if bases.is_empty():
				continue
			for i in n:
				var b: int = int(bases[mini(i, bases.size() - 1)])
				new_wing(gs, c.id, b, kind, tgt / float(n))
			continue
		if tgt > cur * 1.06 + 1.0:
			var best = cur_l[0]
			for w in cur_l:
				if w.size < best.size:
					best = w
			best.size += minf(tgt - cur, maxf(1.0, tgt * 0.05) * _sync_mult if not fresh else tgt - cur)
		elif cur > tgt * 1.12 + 1.0:
			var f: float = tgt / cur
			for w in cur_l:
				w.size *= f
				if w.size < 0.5:
					gs.wings.erase(w.id)


## Kayıpları envantere yansıt: uçak kalemleri ölçeklenir
static func reflect(gs, cid: int) -> void:
	var c = gs.countries[cid]
	var lst: Array = wings_of(gs, cid)
	var total := 0.0
	for w in lst:
		total += w.size
	var tgt: float = units(c)
	if tgt <= 0.0 or total >= tgt * 0.995:
		return
	var fac: float = clampf(total / tgt, 0.0, 1.0)
	var r := _rng(gs, cid * 131 + 3)
	for id in c.inv.keys():
		if not Arsenal.ITEMS.has(id) or Arsenal.cat_of(id) != "air":
			continue
		var n: int = int(c.inv[id])
		var v: float = float(n) * fac
		var iv: int = int(floor(v))
		if r.randf() < v - float(iv):
			iv += 1
		c.inv[id] = mini(n, iv)
	Macro.recalc(c)


# ------------------------------------------------------------------ gemi gibi: uçak sınıfları

static func planes(gs, w) -> Array:
	var fam: String = family()
	var tbl: Dictionary = CLASSES.get(w.kind, {})
	var entries: Array = tbl.get(fam, tbl.get("", []))
	var c = gs.countries[w.owner]
	var use: Array = []
	for e in entries:
		if String(e[0]) == "gen5" and c.tech < 0.6:
			continue
		use.append(e)
	if use.is_empty():
		use = entries
	return Ext._alloc(use, maxi(1, int(round(w.size))))


# ------------------------------------------------------------------ hava üstünlüğü ve önleme

## a ile (müttefikleriyle) b (düşman) arasındaki hava üstünlüğü, a açısından [-1, 1]; pid üzerindeki karada savaşa yansır
static func superiority(gs, pid: int, a: int, b: int) -> float:
	if gs.wings.is_empty():
		return 0.0
	var pa := 0.0
	var pb := 0.0
	for w in gs.wings.values():
		if w.kind != "fighter" and w.kind != "drone":
			continue
		if not in_range(gs, w, pid):
			continue
		var p: float = cp(w) * (DEFEND_BONUS if w.stance == "defend" else 1.0) * (0.35 if w.kind == "drone" else 1.0)
		if w.owner == a or gs.is_allied(w.owner, a):
			pa += p
		elif w.owner == b or gs.is_allied(w.owner, b):
			pb += p
	var denom: float = pa + pb + 20.0
	return clampf((pa - pb) / denom, -1.0, 1.0)


## pid'e saldıran düşman uçaklarını önleyebilecek avcılar (sahip ve müttefikleri)
static func interceptors(gs, pid: int, victim: int, attacker: int) -> Array:
	var out: Array = []
	for w in gs.wings.values():
		if w.kind != "fighter" and w.kind != "drone":
			continue
		if not (w.owner == victim or gs.is_allied(w.owner, victim)) or gs.at_war(w.owner, attacker) == false:
			continue
		if in_range(gs, w, pid):
			out.append(w)
	return out


static func escorts(gs, pid: int, owner: int, exclude) -> Array:
	var out: Array = []
	for w in gs.wings.values():
		if w == exclude or w.kind != "fighter":
			continue
		if (w.owner == owner or gs.is_allied(w.owner, owner)) and in_range(gs, w, pid):
			out.append(w)
	return out


static func awacs_bonus(gs, owner: int, pid: int) -> float:
	for w in gs.wings.values():
		if w.kind == "recon" and (w.owner == owner or gs.is_allied(w.owner, owner)) and in_range(gs, w, pid):
			return 1.0 + minf(0.3, 0.1 + w.size / 400.0)
	return 1.0


static func _sum_cp(lst: Array) -> float:
	var s := 0.0
	for w in lst:
		s += cp(w) * (DEFEND_BONUS if w.stance == "defend" else 1.0)
	return s


# ------------------------------------------------------------------ saldırı

static func strike_cost(gs, cid: int) -> float:
	return clampf(gs.countries[cid].income * 0.2, 8.0, 300.0)


static func _holder_hostile(gs, cid: int, pid: int) -> bool:
	var p = gs.provinces[pid]
	var h: int = p.controller if p.controller >= 0 else p.owner
	return h >= 0 and gs.at_war(cid, h)


## Kanadın saldırabileceği düşman eyaletleri (menzil içinde, savaşta olunan ülkenin elinde)
static func targets(gs, w) -> Array:
	var out: Array = []
	if w.kind != "bomber" and w.kind != "drone":
		return out
	for pid in reach(gs, w.base, w.kind):
		if _holder_hostile(gs, w.owner, pid):
			out.append(pid)
	out.sort_custom(func(a, b):
		var sa: int = gs.armies[a].size if gs.armies.has(a) and gs.armies[a].owner != w.owner else 0
		var sb: int = gs.armies[b].size if gs.armies.has(b) and gs.armies[b].owner != w.owner else 0
		if sa != sb:
			return sa > sb
		return a < b)
	return out


## Saldırı çözümü. Dönüş: {err, killed, lost, down} (down: düşürülen düşman avcısı)
static func resolve_strike(gs, w, pid: int, quiet: bool = false) -> Dictionary:
	if not quiet and not gs.is_headless_sim():
		gs.fx.emit(pid, "bomb")
	var res := {"err": "", "killed": 0, "lost": 0.0, "down": 0.0, "eff": 0.0}
	var holder: int = gs._holder(pid)
	if holder < 0 or not gs.at_war(w.owner, holder):
		res.err = "Hedefle savaşta olmalısın."
		return res
	if not in_range(gs, w, pid):
		res.err = "Hedef bu kanadın menzilinde değil."
		return res
	var pb: float = cp(w)
	# önleme
	var ints: Array = interceptors(gs, pid, holder, w.owner)
	var esc: Array = escorts(gs, pid, w.owner, w)
	var p_int: float = _sum_cp(ints) * awacs_bonus(gs, holder, pid) * (0.6 if w.kind == "drone" else 1.0)
	var p_esc: float = _sum_cp(esc) * 0.8
	var loss_frac: float = clampf(0.03 + 0.35 * p_int / (p_int + p_esc + pb * 0.5 + 1.0), 0.02, 0.6)
	if w.kind == "drone":
		loss_frac *= 0.7
	var eff: float = 1.0 - loss_frac
	# ordu kaybı
	var d = gs.armies.get(pid)
	var p = gs.provinces[pid]
	var d_size: int = d.size if d != null and d.owner != w.owner else 0
	var k: float = 1.0 - exp(-pb * eff / (150.0 + 0.01 * float(d_size)))
	res.eff = k
	if d_size > 0:
		res.killed = int(float(d_size) * 0.25 * k)
		d.size = maxi(1, d.size - res.killed)
		Macro.attrition(gs, d.owner, res.killed, gs.countries[d.owner].troops)
	if k > 0.3 and p.defense > 0 and w.size >= 20.0:
		p.defense -= 1
	var foe = gs.countries[holder]
	foe.industry = maxf(3.0, foe.industry - 2.0 * k)
	foe.logistics = maxf(3.0, foe.logistics - 1.2 * k)
	# kayıplar
	res.lost = w.size * loss_frac
	w.size = maxf(0.0, w.size - res.lost)
	w.xp = minf(Ext.XP_MAX, w.xp + 1.0 + k * 2.0)
	var down := 0.0
	if not ints.is_empty():
		var frac: float = clampf(0.02 + 0.10 * p_esc / (p_esc + p_int + 1.0), 0.0, 0.4)
		for g in ints:
			var l: float = g.size * frac
			g.size = maxf(0.0, g.size - l)
			g.xp = minf(Ext.XP_MAX, g.xp + 1.5)
			down += l
	res.down = down
	w.tgt = pid
	w.tgt_turn = gs.turn
	if w.size < 0.5:
		gs.wings.erase(w.id)
	for g2 in ints:
		if gs.wings.has(g2.id) and g2.size < 0.5:
			gs.wings.erase(g2.id)
	reflect(gs, w.owner)
	for g3 in ints:
		reflect(gs, g3.owner)
	var mine: bool = w.owner == gs.player or holder == gs.player
	if mine or (not quiet and _news_left > 0 and res.killed > 800):
		if not mine:
			_news_left -= 1
		gs.post_news("Hava saldırısı: %s uçakları %s eyaletini vurdu. Düşman kaybı: %s asker; düşen uçak: %d." % [gs.countries[w.owner].name, p.name, Macro.num(res.killed), int(round(res.lost + down))], pid, "war_player" if mine else "ops", "jet")
	return res


## Oyuncu: bir kanadı hedefe yolla
static func player_strike(gs, wid: int, pid: int) -> Dictionary:
	var _cmd := Cmd.Scope.new(gs, "Air.player_strike", [wid, pid])
	var w = gs.wings.get(wid)
	var res := {"err": "", "killed": 0, "lost": 0.0, "down": 0.0}
	if w == null or w.owner != gs.player:
		res.err = "Bu kanat senin değil."
		return res
	if w.kind != "bomber" and w.kind != "drone":
		res.err = "Yalnız bombardıman ve İHA kanatları saldırabilir."
		return res
	if w.cd > gs.turn:
		res.err = "Kanat hazırlanıyor (%d hafta)." % (w.cd - gs.turn)
		return res
	var cost: float = strike_cost(gs, w.owner)
	if gs.countries[w.owner].gold < cost:
		res.err = "Kasa yetersiz: %s." % Macro.money(cost)
		return res
	var r: Dictionary = resolve_strike(gs, w, pid)
	if r.err != "":
		return r
	gs.countries[w.owner].gold -= cost
	w.cd = gs.turn + STRIKE_CD
	gs.stats["air_strikes"] = int(gs.stats.get("air_strikes", 0)) + 1
	gs.player_acted = true
	gs.province_changed.emit(pid)
	gs.armies_changed.emit()
	return r


## Üs değiştir (menzilin 2.5 katı içinde, sahip olunan eyalete); 1 hafta bekler
static func rebase_check(gs, w, pid: int) -> String:
	if w == null or w.owner != gs.player:
		return "Bu kanat senin değil."
	var p = gs.provinces[pid]
	if p.controller != w.owner:
		return "Üs, kendi elindeki bir eyalet olmalı."
	if pid == w.base:
		return "Kanat zaten bu üste."
	if dist(gs, w.base, pid) > range_px(w.kind) * 2.5:
		return "Bu üs çok uzak: kanadın menzilinin 2,5 katı içinde olmalı."
	return ""


static func rebase(gs, wid: int, pid: int) -> String:
	var _cmd := Cmd.Scope.new(gs, "Air.rebase", [wid, pid])
	var w = gs.wings.get(wid)
	var e: String = rebase_check(gs, w, pid)
	if e != "":
		return e
	w.base = pid
	w.cd = maxi(w.cd, gs.turn + 1)
	gs.player_acted = true
	gs.armies_changed.emit()
	return ""


# ------------------------------------------------------------------ hava köprüsü / paraşüt

static func lift_cap(w) -> int:
	return int(1500.0 + 140.0 * w.size * Ext.rank_mult(w.xp))


## Menzildeki, kanadın taşıyabileceği dost ordular (en büyük önce)
static func lift_sources(gs, w) -> Array:
	var out: Array = []
	for pid in gs.armies:
		var a = gs.armies[pid]
		if a.owner == w.owner and a.prov >= 0 and in_range(gs, w, pid) and a.sp_size <= 0:
			out.append(pid)
	out.sort_custom(func(x, y): return gs.armies[x].size > gs.armies[y].size)
	return out


## Hedefler: dost cephe eyaletleri (düşmana komşu) ve paraşüt için düşman eyaletleri
static func lift_dests(gs, w, src_pid: int) -> Array:
	var out: Array = []
	var cand: Array = []
	for pid0 in reach(gs, w.base, w.kind):
		var p = gs.provinces[pid0]
		if p.id == src_pid:
			continue
		if p.controller == w.owner:
			var front := false
			for nb in p.neighbors:
				var q = gs.provinces[nb]
				if q.controller != w.owner and q.controller >= 0 and gs.at_war(w.owner, q.controller):
					front = true
			var occ = gs.armies.get(p.id)
			if front and (occ == null or occ.owner == w.owner):
				cand.append([0, p.id])
		elif _holder_hostile(gs, w.owner, p.id):
			var d = gs.armies.get(p.id)
			cand.append([1, p.id, d.size if d != null and d.owner != w.owner else 0])
	cand.sort_custom(func(a, b):
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[0] == 1:
			return int(a[2]) < int(b[2])
		return dist(gs, src_pid, a[1]) < dist(gs, src_pid, b[1]))
	for e in cand:
		out.append(e[1])
	return out


static func lift_check(gs, w, src: int, dst: int) -> String:
	if w == null or w.kind != "transport":
		return "Bu kanat hava nakliyesi yapamaz."
	if w.cd > gs.turn:
		return "Kanat hazırlanıyor (%d hafta)." % (w.cd - gs.turn)
	var a = gs.armies.get(src)
	if a == null or a.owner != w.owner:
		return "Burada senin ordun yok."
	if not in_range(gs, w, src) or not in_range(gs, w, dst):
		return "Kaynak ya da hedef kanadın menzili dışında."
	var hostile: bool = _holder_hostile(gs, w.owner, dst)
	if not hostile and gs.provinces[dst].controller != w.owner:
		return "Hedef dost ya da düşman eyalet olmalı."
	var occ = gs.armies.get(dst)
	if occ != null and occ.owner != w.owner and not gs.at_war(w.owner, occ.owner):
		return "Hedefte savaşmadığın bir ülkenin ordusu var."
	if hostile and gs.countries[w.owner].gold < gs.op_cost("paradrop"):
		return "Kasa yetersiz: paraşüt harekâtı %s." % Macro.money(gs.op_cost("paradrop"))
	return ""


## Ordunun bir kısmını (kapasite kadar) hedefe uçurur. Dönüş hata metni ("" = tamam)
static func airlift(gs, wid: int, src: int, dst: int) -> String:
	var _cmd := Cmd.Scope.new(gs, "Air.airlift", [wid, src, dst])
	var w = gs.wings.get(wid)
	var e: String = lift_check(gs, w, src, dst)
	if e != "":
		return e
	var me: int = w.owner
	var a = gs.armies[src]
	var hostile: bool = _holder_hostile(gs, me, dst)
	var n: int = mini(a.size, lift_cap(w))
	if hostile:
		n = mini(n, 6000)
	if n < 100:
		return "Kanat çok küçük: taşıyabileceği asker yok."
	# önleme: düşman avcıları nakliyeyi vurabilir
	var holder: int = gs._holder(dst)
	if holder >= 0 and gs.at_war(me, holder):
		var ints: Array = interceptors(gs, dst, holder, me)
		var p_int: float = _sum_cp(ints)
		var p_esc: float = _sum_cp(escorts(gs, dst, me, w)) * 0.8
		var lf: float = clampf(0.02 + 0.3 * p_int / (p_int + p_esc + 5.0), 0.0, 0.5)
		var lost: int = int(float(n) * lf)
		n -= lost
		w.size = maxf(0.0, w.size * (1.0 - lf * 0.5))
		if lost > 0:
			gs.post_news("Hava köprüsü: düşman avcıları nakliye uçaklarımızı vurdu; %s asker kaybedildi." % Macro.num(lost), dst, "war_player", "jet")
	if n < 1:
		return "Nakliye uçakları düşürüldü."
	var army := Model.Army.new()
	army.id = gs.next_army_id
	gs.next_army_id += 1
	army.owner = me
	army.prov = -1
	army.size = n
	army.cmd_lvl = a.cmd_lvl
	army.cmd_name = a.cmd_name
	army.cmd_wins = a.cmd_wins
	army.hold = true
	if hostile:
		army.op = "paradrop"
		gs.countries[me].gold -= gs.op_cost("paradrop")
		gs.sea_campaign[holder] = true
	a.size -= n if n <= a.size else a.size
	if a.size <= 0:
		gs.armies.erase(src)
	else:
		a.path.clear()
	w.cd = gs.turn + 2
	w.xp = minf(Ext.XP_MAX, w.xp + 1.0)
	w.tgt = dst
	w.tgt_turn = gs.turn
	gs.stats["airlifts"] = int(gs.stats.get("airlifts", 0)) + 1
	gs._enter(army, dst)
	gs.post_news("%s hava köprüsüyle %s eyaletine %s asker taşıdı." % [gs.countries[me].name, gs.provinces[dst].name, Macro.num(n)], dst, "war_player" if me == gs.player else "ops", "jet")
	if me == gs.player:
		gs.player_acted = true
	gs.refresh_stats()
	gs.province_changed.emit(dst)
	gs.province_changed.emit(src)
	gs.armies_changed.emit()
	gs.state_changed.emit()
	return ""


# ------------------------------------------------------------------ görünürlük

## Yabancı kanatları oyuncu görebilir mi
static func visible(gs, w) -> bool:
	var me: int = gs.player
	if me < 0 or w.owner == me or gs.is_allied(me, w.owner) or Settings.fog == 0:
		return true
	# savaşta olduğun ülkenin üsleri: komşu eyaletin ya da keşif kanadının menzilinde
	var base_p = gs.provinces[w.base]
	for nb in base_p.neighbors:
		if gs.provinces[nb].controller == me:
			return true
	for v in gs.wings.values():
		if v.owner == me and v.kind == "recon" and in_range(gs, v, w.base):
			return true
	for pid in gs.countries[me].held_ids:
		if gs.provinces[pid].controller == me and gs.provinces[pid].label_pos.distance_to(base_p.label_pos) < 45.0:
			return true
	return false


# ------------------------------------------------------------------ tur

static func tick(gs) -> void:
	if not enabled:
		return
	ensure(gs)
	_news_left = NEWS_MAX
	for w in gs.wings.values().duplicate():
		var c = gs.countries[w.owner] if w.owner >= 0 and w.owner < gs.countries.size() else null
		if c == null or not c.alive or c.is_rebel:
			gs.wings.erase(w.id)
			continue
		# üs ele geçirildiyse en yakın dost eyalete taşın
		if w.base < 0 or gs.provinces[w.base].controller != w.owner:
			var nb: int = nearest_base(gs, c, w.base)
			if nb < 0:
				gs.wings.erase(w.id)
				continue
			w.base = nb
			w.cd = maxi(w.cd, gs.turn + 1)
	# kanatları sahibine göre bir kez grupla (ülke başına tüm kanatları taramak ~10 ms'ydi)
	var by_owner: Dictionary = {}
	for w2 in gs.wings.values():
		if not by_owner.has(w2.owner):
			by_owner[w2.owner] = []
		by_owner[w2.owner].append(w2)
	for c2 in gs.countries:
		if not c2.alive or c2.is_rebel:
			continue
		# YZ ülkelerinin kanat eşitlemesi 3 turda bir (büyüme adımı 3 kat); oyuncu her tur
		var hum: bool = c2.id == gs.player or gs.humans.has(c2.id)
		if not hum and (gs.turn + c2.id) % 3 != 0:
			continue
		if qualifies(c2) or by_owner.has(c2.id):
			_sync_mult = 1.0 if hum else 3.0
			sync_country(gs, c2, false, by_owner.get(c2.id, []))
	_sync_mult = 1.0
	_ai(gs)


## Üssü ele geçirilen kanatları en yakın dost eyalete taşır (kuşatma sonuçlarından sonra da çağrılır)
static func fix_bases(gs) -> void:
	if not enabled or gs.wings.is_empty():
		return
	for w in gs.wings.values().duplicate():
		if w.base >= 0 and gs.provinces[w.base].controller == w.owner:
			continue
		var c = gs.countries[w.owner] if w.owner >= 0 and w.owner < gs.countries.size() else null
		if c == null or not c.alive:
			gs.wings.erase(w.id)
			continue
		var nb: int = nearest_base(gs, c, w.base)
		if nb < 0:
			gs.wings.erase(w.id)
			continue
		w.base = nb
		w.cd = maxi(w.cd, gs.turn + 1)


static func _controls(gs, w) -> bool:
	if w.owner != gs.player:
		return true
	return gs.countries[gs.player].auto_cmd


static func _ai(gs) -> void:
	var rr := _rng(gs, 991)
	for w in gs.wings.values().duplicate():
		if not gs.wings.has(w.id) or w.cd > gs.turn or w.stance == "defend":
			continue
		if w.kind == "transport":
			_ai_lift(gs, w, rr)
			continue
		if w.kind != "bomber" and w.kind != "drone":
			continue
		if not _controls(gs, w):
			continue
		var c = gs.countries[w.owner]
		if c.enemies.is_empty() or rr.randf() > 0.5:
			continue
		var best := -1
		var bs := 0.0
		# tüm eyaletleri taramak yerine yalnızca ordu bulunan eyaletler (3000+ asker) adaydır
		var rng_px: float = range_px(w.kind)
		var bpos: Vector2 = gs.provinces[w.base].label_pos
		var cands: Array = []
		for pid2 in gs.armies:
			var d2 = gs.armies[pid2]
			if d2.owner == w.owner or d2.size < 3000:
				continue
			if gs.provinces[pid2].label_pos.distance_to(bpos) > rng_px:
				continue
			if _holder_hostile(gs, w.owner, pid2):
				cands.append(pid2)
		cands.sort_custom(func(a, b):
			var sa: int = gs.armies[a].size
			var sb: int = gs.armies[b].size
			if sa != sb:
				return sa > sb
			return a < b)
		for pid in cands:
			var sz: int = gs.armies[pid].size
			var pint: float = _sum_cp(interceptors(gs, pid, gs._holder(pid), w.owner))
			if pint > cp(w) * 1.5:
				continue
			bs = float(sz)
			best = pid
			break
		if best >= 0:
			resolve_strike(gs, w, best)
			w.cd = gs.turn + STRIKE_CD + 1


## Yapay zekâ hava köprüsü: arkadaki büyük bir orduyu en yakın dost cephe eyaletine uçurur (paraşüt yok)
static func _ai_lift(gs, w, rr: RandomNumberGenerator) -> void:
	if w.cd > gs.turn or not _controls(gs, w):
		return
	var c = gs.countries[w.owner]
	if c.enemies.is_empty() or rr.randf() > 0.3:
		return
	var srcs: Array = []
	for pid in gs.armies:       # yalnızca 4000+ askerli, emir almamış ordular (lift_sources hepsini menzil için tarıyordu)
		var a0 = gs.armies[pid]
		if a0.owner == w.owner and a0.size >= 4000 and a0.op == "" and a0.prov >= 0 and a0.sp_size <= 0 and in_range(gs, w, pid):
			srcs.append(pid)
	srcs.sort_custom(func(x, y): return gs.armies[x].size > gs.armies[y].size)
	for src in srcs:
		var a = gs.armies[src]
		var p = gs.provinces[src]
		var front := false
		for nb in p.neighbors:
			var q = gs.provinces[nb]
			if q.controller != w.owner and q.controller >= 0 and gs.at_war(w.owner, q.controller):
				front = true
		if front:
			continue
		for dst in lift_dests(gs, w, src):
			if gs.provinces[dst].controller == w.owner:
				airlift(gs, w.id, src, dst)
				return
		return


# ------------------------------------------------------------------ kayıt

static func to_array(gs) -> Array:
	var out: Array = []
	for w in gs.wings.values():
		out.append([w.id, w.owner, w.base, w.kind, w.size, w.cd, w.xp, w.stance, w.name, w.flag, w.born, w.tgt, w.tgt_turn])
	return out


static func from_array(gs, arr: Array) -> void:
	gs.wings = {}
	var mx := 0
	for r in arr:
		if r.size() < 13:
			continue
		var w = Model.Wing.new()
		w.id = int(r[0])
		w.owner = int(r[1])
		w.base = int(r[2])
		w.kind = String(r[3])
		w.size = float(r[4])
		w.cd = int(r[5])
		w.xp = float(r[6])
		w.stance = String(r[7])
		w.name = String(r[8])
		w.flag = String(r[9])
		w.born = int(r[10])
		w.tgt = int(r[11])
		w.tgt_turn = int(r[12])
		if w.owner < 0 or w.owner >= gs.countries.size() or w.base < 0 or w.base >= gs.provinces.size() or not KINDS.has(w.kind) or w.size <= 0.0:
			continue
		gs.wings[w.id] = w
		mx = maxi(mx, w.id)
	gs.next_wing_id = maxi(gs.next_wing_id, mx + 1)
	gs.wings_ready = true


# ------------------------------------------------------------------ ad / eylemler

static func ordinal_k(gs, w) -> int:
	var k := 0
	for g in gs.wings.values():
		if g.owner == w.owner and g.kind == w.kind and g.id <= w.id:
			k += 1
	return maxi(k, 1)


static func default_display(gs, w) -> String:
	return Loc.t(String(KIND_TPL.get(w.kind, "%d. Hava Filosu")) % ordinal_k(gs, w))


static func display_name(gs, w) -> String:
	return w.name if w.name != "" else default_display(gs, w)


static func _mine(gs, wid: int):
	var w = gs.wings.get(wid)
	return w if w != null and w.owner == gs.player else null


static func rename(gs, wid: int, nm: String) -> String:
	var _cmd := Cmd.Scope.new(gs, "Air.rename", [wid, nm])
	var w = _mine(gs, wid)
	if w == null:
		return "Bu kanat senin değil."
	w.name = nm.strip_edges().left(28)
	gs.armies_changed.emit()
	return ""


static func set_flag(gs, wid: int, spec: String) -> String:
	var _cmd := Cmd.Scope.new(gs, "Air.set_flag", [wid, spec])
	var w = _mine(gs, wid)
	if w == null:
		return "Bu kanat senin değil."
	w.flag = spec
	gs.armies_changed.emit()
	return ""


static func set_stance(gs, wid: int, st: String) -> String:
	var _cmd := Cmd.Scope.new(gs, "Air.set_stance", [wid, st])
	var w = _mine(gs, wid)
	if w == null:
		return "Bu kanat senin değil."
	if st == "attack" or st == "defend":
		w.stance = st
	gs.armies_changed.emit()
	return ""
