extends RefCounted
## Oyun durumu ve tüm kurallar: tur akışı, ordular, kuşatma, savaş/barış, yapay zeka, olaylar.

const Model = preload("res://scripts/model.gd")
const Names = preload("res://scripts/names.gd")
const WorldData = preload("res://scripts/world_data.gd")
const Macro = preload("res://scripts/macro.gd")
const Emblem = preload("res://scripts/emblem.gd")
const Eras = preload("res://scripts/eras.gd")
const GrandOp = preload("res://scripts/grand_op.gd")
const Independence = preload("res://scripts/independence.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")
const Daily = preload("res://scripts/daily.gd")
const Politics = preload("res://scripts/politics.gd")
const WarRoom = preload("res://scripts/war_room.gd")
const Crises = preload("res://scripts/crises.gd")
const Objectives = preload("res://scripts/objectives.gd")
const UN = preload("res://scripts/un.gd")
const Cabinet = preload("res://scripts/cabinet.gd")
const Militias = preload("res://scripts/militias.gd")

signal news_posted(text: String, prov: int, kind: String)
signal province_changed(pid: int)
signal armies_changed()
signal state_changed()
signal peace_proposal(war, from_country: int, kind: String)
signal game_over(victory: bool, text: String)
signal objective_done(id: String)
signal pol_card
signal wroom_card(title: String, body: String, scene: String)
signal grand_resolved(kind: String, op_name: String, taken: int)
signal indep_card
signal ally_call(friend: int, foe: int, kind: String)
signal alliance_proposal(from_country: int)

const MAX_MERGE := 250000
const LETHAL := 0.2          # muharebe kayıp çarpanı (cephe temposunu yavaşlatır)
const RETREAT_KEEP := 0.88    # bozguna uğrayan ordunun geri çekilen oranı
const VICTORY_RATIO := 0.55
const ECON_RATIO := 0.5

var rng := RandomNumberGenerator.new()
var setup_mode := false                  # senaryo kurulurken oyuncuya ittifak çağrısı gösterilmez
var seed_value := 0
var world = null
var provinces: Array = []
var countries: Array = []
var armies: Dictionary = {}
var wars: Array = []
var news_log: Array = []
var turn := 0
var player := -1
var next_army_id := 1
var player_acted := false                # bu turda oyuncu emir verdi mi
var auto_idle := false                   # emir verilmezse boştaki ordulara otomatik görev (ayar)
var infamy_warned := false
var infamy := 0.0                        # dünya tepkisi (0-100): fetihle artar, zamanla söner; yüksekse koalisyon kurulur
var indep: Dictionary = {}               # Bağımsızlık Yolu kipi durumu (independence.gd)
var wroom: Dictionary = {}               # Savaş Odası planı (war_room.gd)
var pol: Dictionary = {}                 # siyasi sistem durumu (politics.gd): rejimler, YZ seçimleri, kartlar
var daily: Dictionary = {}               # Günlük Meydan Okuma durumu (daily.gd)
var chokes: Dictionary = {}              # stratejik geçitler: {id: {mode, ctrl, cd}} (chokepoints.gd)
var grand: Dictionary = {}               # Büyük Harekât: {cd, ops, done, last}
var nuke_cd := 0                         # bir sonraki nükleer saldırı turu
const AI_MAX_ALLIES := 6               # yalnız yapay zekâ için yumuşak sınır; oyuncuda sınır yok
var aid: Dictionary = {"cd": {}, "good": {}}   # müttefik yardımı: bekleme süreleri / minnet (müttefik -> tur)
var un_cd: Dictionary = {}               # BM önerge bekleme süreleri (önerge -> tur)
var un_log: Array = []                   # son BM kararları
var last_auto := 0                       # son turda otomatik görevlendirilen ordu sayısı
var victory_declared := false
var game_started := false
var pending_proposal := false
var sea_campaign: Dictionary = {}     # oyuncunun denizden başlattığı sefer: kurban ülke id -> true (sonrasını otomatik sistem yürütür)
var crisis: Dictionary = {}            # aktif dünya krizi (crises.gd)
var crisis_pending: Dictionary = {}    # oyuncuya sorulacak kriz kartı
var crisis_last_end := -999
var scn: Dictionary = {}               # senaryo/çağ hedefleri ve olayları (objectives.gd)
var stats := {"wars": 0, "captures": 0, "battles": 0, "peaces": 0, "eliminated": 0, "rebels": 0, "independence": 0, "alliances": 0, "p_wars": 0, "p_alliances": 0, "p_peaces": 0, "p_battles": 0, "p_captures": 0, "p_eliminated": 0, "orders": 0, "un_passed": 0, "landings": 0, "nukes": 0}
var base_country_count := 0
var difficulty := 1                      # 0 kolay, 1 normal, 2 zor (yapay zekâ gelir çarpanı)
var rebel_name_count: Dictionary = {}
var merc_names: Dictionary = {}
var macro_idx: Dictionary = {}
var blocs: Array = []            # {id, name, emblem, members, founder, born}
var next_bloc_id := 0
var turn_battles: Array = []     # bu turdaki oyuncu muharebeleri (rapor ekranı için)
var cold: Array = []             # soğuk savaş çiftleri: yalnızca siber operasyon [[a, b], ...]


# ===================================================================== kurulum

func new_world(seed_val: int, _ncountries: int = 0) -> void:
	news_log.clear()
	pending_proposal = false
	game_started = false
	rebel_name_count = {}
	merc_names = {}
	seed_value = seed_val
	rng.seed = seed_val
	world = WorldData.instance()
	world.populate(self)
	base_country_count = countries.size()
	_init_armies()
	refresh_stats()


## Tarihî kipte eyaletler yeniden dağıtıldıktan sonra ordu ve envanterleri yeniden kurar
func rebuild_after_era() -> void:
	_init_armies()
	refresh_stats()


## Küçük ülkeler için ilk haftalarda savunma desteği (hızlı yok oluşu önler); her tur 1 azalır
var guard_left := 0
const GUARD_WEEKS := 16
const SMALL_NATION := 8


func start_game(player_country: int) -> void:
	player = player_country
	guard_left = GUARD_WEEKS
	if player >= 0:
		countries[player].is_player = true
	game_started = true
	post_news("Yeni oyun: %s liderliğinde cihan hâkimiyeti yarışı başladı." % countries[player].name if player >= 0 else "Simülasyon başladı.", -1, "info")


func _init_armies() -> void:
	armies.clear()
	next_army_id = 1
	refresh_stats()
	Macro.build_idx(self)
	for c in countries:
		c.inv = {}
		c.base_troops = 0
		Macro.init_country(self, c)
		var owned: Array = c.owned_ids
		if owned.is_empty():
			continue
		c.gold = c.income * 8.0
		c.fund = c.income * 0.2
		var total: int = c.base_troops
		var cap_pid: int = c.capital if c.capital >= 0 else owned[0]
		var cap_n: int = int(total * 0.12)
		var rest: int = total - cap_n
		var want := clampi(int(owned.size() * 0.7), 1, 40)
		var border: Array = []
		var inland: Array = []
		for pid in owned:
			if pid == cap_pid:
				continue
			var hot := false
			for nb in provinces[pid].neighbors:
				if provinces[nb].owner != c.id:
					hot = true
					break
			if hot or provinces[pid].coastal:
				border.append(pid)
			else:
				inland.append(pid)
		_shuffle(border)
		_shuffle(inland)
		var spots: Array = border + inland
		var n_arm: int = mini(want, spots.size())
		if n_arm > 0 and rest >= 500:
			n_arm = mini(n_arm, maxi(1, rest / 500))
			var each: int = rest / n_arm
			for i in n_arm:
				_spawn_army(c.id, spots[i], each)
				rest -= each
		_spawn_army(c.id, cap_pid, cap_n + rest)
	refresh_stats()
	Macro.prime(self)


func _country_income(c) -> float:
	var s := 0.0
	for pid in c.owned_ids:
		s += provinces[pid].rev()
	return s


func _spawn_army(owner_id: int, pid: int, size: int):
	var ex = armies.get(pid)
	if ex != null:
		if ex.owner == owner_id:
			ex.size += size
			return ex
		return null
	var a := Model.Army.new()
	a.id = next_army_id
	next_army_id += 1
	a.owner = owner_id
	a.prov = pid
	a.size = size
	armies[pid] = a
	return a


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


# ===================================================================== taarruz harekâtları

const OP_ORDER := ["assault", "barrage", "naval", "air", "missile", "paradrop", "special", "cyber", "blitz"]
const OPS := {
	"assault": {"name": "Kara Taarruzu", "icon": "swords", "cost": 0.0, "att": 1.0, "dp": 1.0, "surv": 0.35,
		"desc": "Standart birleşik silah taarruzu."},
	"barrage": {"name": "Topçu ve Hava Hazırlığı", "icon": "explosion", "cost": 0.5, "att": 1.04, "dp": 0.88, "surv": 0.35,
		"desc": "Önce savunmayı döver: savunma −%12, taarruz +%4."},
	"air": {"name": "Hava Harekâtı", "icon": "jet", "cost": 0.7, "att": 1.06, "dp": 0.80, "surv": 0.38,
		"desc": "Havadan bombardıman: etkisi hava üstünlüğüne bağlı (hava gücün rakipten fazlaysa savunma −%20'ye kadar). Eski çağda yoktur."},
	"naval": {"name": "Donanma Bombardımanı", "icon": "battleship", "cost": 0.55, "att": 1.0, "dp": 0.82, "surv": 0.35,
		"desc": "Sahildeki eyalete gemi topçusu: donanma gücün rakipten fazlaysa savunma −%18'e kadar. Yalnız kıyı eyaletleri."},
	"missile": {"name": "Füze Saldırısı", "icon": "missile", "cost": 1.0, "att": 1.0, "dp": 0.70, "surv": 0.35,
		"desc": "Uzun menzilli füze ve hassas vuruş: savunma −%30'a kadar, hava üstünlüğü gerekmez. Yalnız modern çağda."},
	"paradrop": {"name": "Hava İndirme", "icon": "paratrooper", "cost": 0.8, "att": 0.95, "dp": 1.0, "surv": 0.45, "no_fort": true,
		"desc": "Arkadan paraşütlü baskın: eyaletin savunma ve evde-savunma bonusu işlemez. WW2 ve modern çağda."},
	"special": {"name": "Özel Kuvvet Baskını", "icon": "special_forces", "cost": 0.3, "att": 1.18, "dp": 0.92, "surv": 0.6,
		"desc": "Küçük, seçkin birlikle sert vuruş: taarruz +%18, kayıplar düşük. En çok 25.000 askerle; WW2 ve modern çağda."},
	"cyber": {"name": "Siber ve Elektronik Harp", "icon": "hacker", "cost": 0.35, "att": 1.0, "dp": 0.86, "surv": 0.35,
		"desc": "Komuta ağını kör eder: savunma −%14."},
	"landing": {"name": "Amfibi Çıkarma", "icon": "ship", "cost": 0.6, "att": 0.85, "dp": 1.1, "surv": 0.30,
		"desc": "Deniz aşırı çıkarma: taarruz −15 yüzde, savunma +10 yüzde. Taşıma kapasitesi donanmanla sınırlı."},
	"blitz": {"name": "Yıldırım Taarruzu", "icon": "fast", "cost": 0.0, "att": 1.07, "dp": 1.0, "surv": 0.25,
		"desc": "Taarruz +%12; yenilirsen sağ kalan yalnız %25."},
}


# ===================================================================== nükleer silah

const NUCLEAR := ["United States of America", "Russia", "United Kingdom", "France", "China", "India", "Pakistan", "Israel", "North Korea"]


func player_has_nukes() -> bool:
	if player < 0:
		return false
	var nm: String = countries[player].name_en
	var fam: String = Eras.family()
	if fam == "ww1":
		return false
	if fam == "ww2":
		var ym: Array = Names.year_month(turn)
		return nm == "United States of America" and int(ym[0]) * 12 + int(ym[1]) - 1 >= 1945 * 12 + 6
	var owners = Eras.field("nukes", null)
	if owners is Array:
		return owners.has(nm)
	return NUCLEAR.has(nm)


## Nükleer saldırı: hedef eyaletteki ordu büyük ölçüde yok olur, ama küresel tepki ağır olur.
func player_nuke(pid: int) -> String:
	if not player_has_nukes():
		return "Nükleer silahın yok."
	if nuke_cd > turn:
		return "Nükleer arsenal hazır değil (%d hafta)." % (nuke_cd - turn)
	var p = provinces[pid]
	var tgt: int = p.owner if at_war(player, p.owner) else p.controller
	if tgt < 0 or not at_war(player, tgt):
		return "Nükleer saldırı için hedefle savaşta olmalısın."
	var me = countries[player]
	var d = armies.get(pid)
	var killed := 0
	if d != null and d.owner != player:
		killed = int(d.size * 0.8)
		d.size = maxi(1, d.size - killed)
	p.defense = 0
	p.dev = maxi(0, p.dev - 2)
	p.unrest = 12
	p.pop *= 0.8
	nuke_cd = turn + 26
	stats.nukes += 1
	infamy = minf(100.0, infamy + 40.0)
	me.stability = clampf(me.stability - 10.0, 5.0, 100.0)
	me.sanction_until = turn + 26
	for al in countries[tgt].allies.duplicate():
		if al != player and rng.randf() < 0.5:
			declare_war(al, player, true)
	for c in countries:
		if c.alive and not c.is_rebel and c.id != player and not is_allied(c.id, player):
			c.aggression = minf(1.0, c.aggression + 0.05)
	post_news("NÜKLEER SALDIRI! %s, %s eyaletine nükleer silah kullandı; dünya şokta, yaptırımlar geliyor." % [me.name, p.name], pid, "war_player")
	province_changed.emit(pid)
	state_changed.emit()
	return ""


## Bir turda denizden çıkarılabilecek azami asker (donanma gücüne bağlı).
func landing_cap(cid: int) -> int:
	return 6000 + int(1500.0 * countries[cid].naval_pow) + 3000 * maxi(countries[cid].carriers, 0)


func op_cost(op: String) -> float:
	if player < 0:
		return 0.0
	return OPS[op].cost * maxf(countries[player].income, 1.0)


## Hedef eyalete (en çok max_hops adımda) ulaşabilecek oyuncu orduları: [{army, hops}] yakından uzağa.
func armies_near(pid: int, max_hops: int = 6) -> Array:
	var out: Array = []
	var dist := {pid: 0}
	var q: Array = [pid]
	var qi := 0
	while qi < q.size():
		var cur: int = q[qi]
		qi += 1
		var d: int = dist[cur]
		var a = armies.get(cur)
		if a != null and a.owner == player and cur != pid:
			out.append({"army": a, "hops": d})
		if d >= max_hops:
			continue
		for nb in provinces[cur].neighbors:
			if not dist.has(nb):
				dist[nb] = d + 1
				q.append(nb)
	# deniz aşırı: hedefle deniz bağlantısı olan kıyı eyaletlerindeki ordular (amfibi çıkarma)
	var have := {}
	for e in out:
		have[e.army.id] = true
	for sl in provinces[pid].sea_links:
		var sa = armies.get(sl)
		if sa != null and sa.owner == player and not have.has(sa.id):
			out.append({"army": sa, "hops": 1, "sea": true})
	return out


## Harekât çarpanları; hava harekâtının gücü hava üstünlüğüne göre ölçeklenir.
func op_effect(op: String, att_id: int, def_id: int) -> Dictionary:
	var o: Dictionary = OPS[op]
	if op == "air" or op == "naval":
		var key: String = "air_pow" if op == "air" else "naval_pow"
		var a: float = countries[att_id].get(key)
		var b: float = countries[def_id].get(key) if def_id >= 0 else 0.0
		var share: float = (a - b) / (a + b + 1.0)
		var k: float = clampf(0.2 + share, 0.0, 1.0)
		return {"att": 1.0 + (o.att - 1.0) * k - (0.04 if share <= 0.0 else 0.0), "dp": 1.0 - (1.0 - o.dp) * k}
	if op == "missile":
		var a2: float = countries[att_id].air_pow
		var b2: float = countries[def_id].air_pow if def_id >= 0 else 0.0
		var k2: float = clampf(0.45 + 0.4 * (a2 - b2) / (a2 + b2 + 1.0), 0.2, 1.0)
		return {"att": o.att, "dp": 1.0 - (1.0 - o.dp) * k2}
	if op == "landing":
		return {"att": o.att + minf(0.2, 0.04 * maxi(countries[att_id].carriers, 0)), "dp": o.dp}
	return {"att": o.att, "dp": o.dp}


## Harekât bu hedefte ve bu kuvvetle seçilebilir mi? (çağ, kıyı, birlik büyüklüğü)
func op_available(op: String, prov = null, army_list: Array = [], frac: float = 1.0) -> bool:
	var era: String = Eras.current
	var fam: String = Eras.family()
	match op:
		"air", "paradrop", "special":
			if fam == "ww1":
				return false
		"missile", "cyber":
			if era != "":
				return false
		"blitz":
			if fam == "ww1":
				return false
	if op == "naval" and prov != null and not prov.coastal:
		return false
	if op == "special":
		var tot := 0
		for a in army_list:
			tot += int(a.size * frac)
		if tot > 25000:
			return false
	return true


## Savunan ve taarruz gücü tahmini (rastgelelik hariç).
func assault_estimate(pid: int, army_list: Array, op: String, frac: float = 1.0) -> Dictionary:
	var p = provinces[pid]
	var def = armies.get(pid)
	var holder: int = p.controller if p.controller >= 0 else p.owner
	var o: Dictionary = op_effect(op, player, holder)
	var att_total := 0
	var ap := 0.0
	for a in army_list:
		var sz: float = a.size * frac
		att_total += int(sz)
		ap += sz * Macro.battle_mult(self, player, holder, true, p)
	ap *= o.att
	var def_size := 0
	var dp := 0.0
	if def != null and def.owner != player:
		def_size = def.size
		var home: bool = ((p.owner == def.owner) or (p.controller == def.owner)) and not OPS[op].get("no_fort", false)
		dp = def.size * (1.0 + (0.15 + 0.12 * p.defense if home else 0.0)) * Macro.battle_mult(self, def.owner, player, false, p) * o.dp
	return {"att": att_total, "def": def_size, "ap": ap, "dp": dp,
		"ratio": 1.0 if dp <= 0.0 else ap / (ap + dp), "empty": dp <= 0.0, "holder": holder}


func player_launch_assault(pid: int, ids: Array, op: String, frac: float = 1.0) -> Dictionary:
	var res := {"err": "", "n": 0, "eta": 0}
	if player < 0 or not OPS.has(op):
		res.err = "Geçersiz harekât."
		return res
	var p = provinces[pid]
	if not (at_war(player, p.owner) or (p.controller >= 0 and at_war(player, p.controller))):
		res.err = "Bu eyalete taarruz için önce savaş olmalı."
		return res
	var sel: Array = []
	for a0 in armies.values():
		if a0.owner == player and ids.has(a0.id):
			sel.append(a0)
	if not op_available(op, p, sel, frac) and op != "landing":
		res.err = "Bu harekât burada kullanılamaz."
		return res
	# kara yolu olmayan ama deniz bağlantısı olan ordular amfibi çıkarma yapar
	var plan: Array = []
	var any_sea := false
	for a in armies.values():
		if a.owner != player or not ids.has(a.id) or a.prov == pid:
			continue
		var path := path_to(player, a.prov, pid)
		var sea := false
		if path.is_empty() and provinces[pid].sea_links.has(a.prov):
			path = [pid]
			sea = true
			any_sea = true
		if path.is_empty():
			continue
		plan.append([a, path, sea])
	var cost: float = op_cost(op)
	if any_sea:
		cost = maxf(cost, op_cost("landing"))
		for e in plan:
			if not e[2] and op != "assault":
				cost += op_cost(op)
				break
	if countries[player].gold < cost:
		res.err = "Kasa yetersiz: harekât bedeli %s." % Macro.money(cost)
		return res
	var sent := 0
	var eta := 0
	var cap_left: int = landing_cap(player)
	for e in plan:
		var a = e[0]
		var path: Array = e[1]
		var aop: String = "landing" if e[2] else op
		var n_send: int = int(a.size * frac) if frac < 0.99 else a.size
		if e[2]:
			n_send = mini(n_send, cap_left)
			if n_send < 1:
				continue
			cap_left -= n_send
		if n_send < a.size and a.size >= 2:
			a.sp_size = clampi(n_send, 1, a.size - 1)
			a.sp_path = path
			a.sp_op = aop
			a.sp_hold = false
			a.path.clear()
			a.leaving = false
		else:
			a.sp_size = 0
			a.sp_path = []
			a.path = path
			a.leaving = true
			a.op = aop
			a.hold = false
		sent += 1
		if e[2]:
			stats.landings += 1
			var holder_id: int = p.controller if p.controller >= 0 else p.owner
			sea_campaign[holder_id] = true
		eta = maxi(eta, path.size())
	if sent == 0:
		res.err = "Hedefe ulaşabilen ordu yok (geçiş izni ya da yol yok)."
		return res
	countries[player].gold -= cost
	player_acted = true
	res.n = sent
	res.eta = eta
	armies_changed.emit()
	state_changed.emit()
	return res


# ===================================================================== yardımcılar

func post_news(text: String, prov: int = -1, kind: String = "info", icon: String = "") -> void:
	var rec := {"turn": turn, "text": text, "prov": prov, "kind": kind}
	if icon != "":
		rec["ic"] = icon
	news_log.append(rec)
	if news_log.size() > 300:
		news_log.pop_front()
	news_posted.emit(text, prov, kind)


func refresh_stats() -> void:
	for c in countries:
		c.prov_owned = 0
		c.prov_held = 0
		c.income = 0.0
		c.troops = 0
		c.owned_ids = []
		c.held_ids = []
	for p in provinces:
		if p.owner >= 0:
			countries[p.owner].prov_owned += 1
			countries[p.owner].owned_ids.append(p.id)
		if p.controller >= 0:
			countries[p.controller].prov_held += 1
			countries[p.controller].held_ids.append(p.id)
		if p.controller == p.owner:
			if p.owner >= 0:
				countries[p.owner].income += p.rev()
		elif p.controller >= 0:
			countries[p.controller].income += p.rev() * 0.5
	for a in armies.values():
		countries[a.owner].troops += a.size


func net_income(c) -> float:
	return Macro.net_income(self, c)


func power_of(c) -> float:
	return Macro.power(self, c)


func at_war(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0:
		return false
	return countries[a].enemies.has(b)


func get_war(a: int, b: int):
	for w in wars:
		if (w.a == a and w.b == b) or (w.a == b and w.b == a):
			return w
	return null


func country_province_ids(cid: int) -> Array:
	return countries[cid].owned_ids.duplicate()


func armies_of(cid: int) -> Array:
	var out: Array = []
	for a in armies.values():
		if a.owner == cid:
			out.append(a)
	return out


func neighbor_countries(cid: int) -> Array:
	var seen: Dictionary = {}
	for pid in countries[cid].owned_ids:
		for nb in provinces[pid].neighbors:
			var o: int = provinces[nb].owner
			if o != cid and o >= 0:
				seen[o] = true
	return seen.keys()


func alive_count() -> int:
	var n := 0
	for c in countries:
		if c.alive:
			n += 1
	return n


func is_allied(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and a != b and countries[a].allies.has(b)


func can_enter(cid: int, pid: int) -> bool:
	var o: int = provinces[pid].owner
	return o == cid or at_war(cid, o) or is_allied(cid, o)


func is_sieging(a) -> bool:
	var p = provinces[a.prov]
	if p.controller == a.owner:
		return false
	return at_war(a.owner, p.controller) or at_war(a.owner, p.owner)


func _build_path(prev: PackedInt32Array, from: int, to: int) -> Array:
	var path: Array = []
	var cur := to
	while cur != from and cur >= 0:
		path.append(cur)
		cur = prev[cur]
	path.reverse()
	return path


func path_to(cid: int, from: int, to: int) -> Array:
	if from == to:
		return []
	var prev := PackedInt32Array()
	prev.resize(provinces.size())
	prev.fill(-2)
	prev[from] = -1
	var q: Array = [from]
	var qi := 0
	while qi < q.size():
		var cur: int = q[qi]
		qi += 1
		for nb in provinces[cur].neighbors:
			if prev[nb] != -2 or not can_enter(cid, nb):
				continue
			prev[nb] = cur
			if nb == to:
				return _build_path(prev, from, to)
			q.append(nb)
	return []


## Son path_nearest çağrısında ziyaret edilen eyaletler (prev != -2); başarısız aramanın tekrarını önlemek için
var _pn_prev := PackedInt32Array()


func path_nearest(cid: int, from: int, pred: Callable, max_depth: int = -1) -> Array:
	var prev := PackedInt32Array()
	prev.resize(provinces.size())
	prev.fill(-2)
	prev[from] = -1
	var depth := PackedInt32Array()
	if max_depth > 0:
		depth.resize(provinces.size())
	var q: Array = [from]
	var qi := 0
	_pn_prev = prev
	while qi < q.size():
		var cur: int = q[qi]
		qi += 1
		if max_depth > 0 and depth[cur] >= max_depth:
			continue
		for nb in provinces[cur].neighbors:
			if prev[nb] != -2 or not can_enter(cid, nb):
				continue
			prev[nb] = cur
			if max_depth > 0:
				depth[nb] = depth[cur] + 1
			if pred.call(nb):
				return _build_path(prev, from, nb)
			var blk = armies.get(nb)
			if blk != null and at_war(cid, blk.owner):
				continue     # düşman yığınının içinden geçilmez (intihar saldırısı)
			q.append(nb)
	return []


# ===================================================================== savaş / barış

func declare_war(a: int, b: int, joined: bool = false) -> bool:
	if a == b or not countries[a].alive or not countries[b].alive:
		return false
	if at_war(a, b) or is_allied(a, b):
		return false
	if not joined and countries[a].truce.get(b, -1) > turn:
		return false
	var w := Model.War.new()
	w.a = a
	w.b = b
	w.start = turn
	wars.append(w)
	countries[a].enemies.append(b)
	countries[b].enemies.append(a)
	stats.wars += 1
	if a == player or b == player:
		stats.p_wars += 1
	if countries[a].is_rebel or countries[b].is_rebel:
		return true
	var na: String = countries[a].name
	var nb: String = countries[b].name
	if not joined:
		if b == player:
			post_news(Names.war_on_player(rng, na), countries[a].capital, "war_player")
		elif a == player:
			post_news(Names.war_by_player(rng, nb), countries[b].capital, "war_player")
		else:
			post_news(Names.war_declared(rng, na, nb), countries[a].capital, "war")
		_call_allies(a, b)
	return true


# ===================================================================== ittifaklar

## Senaryo: bir ülkenin eyaletlerinden ayrılan kurgusal devlet. Eski sahiple savaş başlar.
func create_faction(spec: Dictionary) -> int:
	var picks: Array = []
	var from_cids: Array = []
	for e in spec["from"]:
		var cid: int = int(macro_idx.get(e[0], -1))
		if cid < 0:
			continue
		from_cids.append(cid)
		var oc = countries[cid]
		if spec.has("pids"):
			for pid0 in spec["pids"]:
				if int(pid0) >= 0 and int(pid0) < provinces.size() and provinces[int(pid0)].owner == cid and not picks.has(int(pid0)):
					picks.append(int(pid0))
			continue
		var cp: Vector2 = provinces[oc.capital].label_pos if oc.capital >= 0 else Vector2.ZERO
		var cand: Array = []
		for pid in oc.owned_ids:
			if pid != oc.capital and provinces[pid].controller == oc.id and not picks.has(pid):
				cand.append(pid)
		var dir: String = spec.get("dir", "east")
		cand.sort_custom(func(a, b):
			var pa: Vector2 = provinces[a].label_pos
			var pb: Vector2 = provinces[b].label_pos
			match dir:
				"east":
					return pa.x > pb.x
				"west":
					return pa.x < pb.x
				"north":
					return pa.y < pb.y
				"south":
					return pa.y > pb.y
			return pa.distance_to(cp) < pb.distance_to(cp))
		for i in mini(int(e[1]), cand.size()):
			picks.append(cand[i])
	if picks.is_empty():
		return -1
	var f := Model.Country.new()
	f.id = countries.size()
	f.name = spec["name"]
	f.name_en = "faction_%d" % f.id
	f.a3 = "XXX"
	f.continent = countries[from_cids[0]].continent
	var cols: Array = spec.get("colors", ["333a44", "e3a92b", "ece6d6"])
	f.color = Color(cols[0])
	f.color2 = Color(cols[1])
	f.color3 = Color(cols[2])
	f.flag_pattern = int(spec.get("pattern", 2))
	f.aggression = float(spec.get("aggression", 0.9))
	f.born = turn
	var best: int = picks[0]
	var troops: int = int(spec.get("troops", 30000))
	for pid in picks:
		var p = provinces[pid]
		if p.pop > provinces[best].pop:
			best = pid
		f.pop += p.pop
		f.gdp += p.gdp
		var a = armies.get(pid)
		if a != null:
			if bool(spec.get("defect", true)):
				troops += a.size
			armies.erase(pid)
	f.capital = best
	provinces[best].is_capital = true
	provinces[best].dev = maxi(provinces[best].dev, 3)
	countries.append(f)
	var old_owners: Array = []
	for pid in picks:
		var p2 = provinces[pid]
		if p2.owner >= 0 and not old_owners.has(p2.owner):
			old_owners.append(p2.owner)
		if pid != best:
			p2.is_capital = false
		p2.owner = f.id
		p2.controller = f.id
		p2.core = f.id
		p2.acquired = turn
		p2.unrest = 0
		p2.siege = 0
		province_changed.emit(pid)
	for oo in old_owners:
		_fix_capital(oo)
	f.base_troops = troops
	f.tech_set = float(spec.get("tech", 0.5))
	f.leader = String(spec.get("leader", ""))
	Macro.build_idx(self)
	Macro.init_country(self, f)
	f.doctrine = int(spec.get("doctrine", 0))
	var each: int = maxi(1000, troops / picks.size())
	for pid in picks:
		_spawn_army(f.id, pid, each)
	refresh_stats()
	f.gold = f.income * 8.0
	for cid2 in from_cids:
		declare_war(f.id, cid2, true)
		_call_allies_of(cid2, f.id)
	Macro.prime(self)
	return f.id


func _call_allies_of(defender: int, attacker: int) -> void:
	for ally in countries[defender].allies.duplicate():
		_ally_join(ally, defender, attacker, "defend")


func _call_allies(attacker: int, defender: int) -> void:
	for ally in countries[defender].allies.duplicate():
		_ally_join(ally, defender, attacker, "defend")
	for ally in countries[attacker].allies.duplicate():
		_ally_join(ally, attacker, defender, "attack")


func _ally_join(ally: int, friend: int, foe: int, kind: String) -> void:
	var c = countries[ally]
	if not c.alive or ally == foe or at_war(ally, foe) or is_allied(ally, foe):
		return
	if ally == player:
		if setup_mode:
			return
		if not pending_proposal:
			pending_proposal = true
			ally_call.emit(friend, foe, kind)
		return
	if rng.randf() < (0.75 if kind == "defend" else 0.55):
		if declare_war(ally, foe, true):
			post_news(Names.ally_joined(rng, c.name, countries[friend].name, countries[foe].name), c.capital, "war")


func _alliance_decay() -> void:
	for c in countries:
		if not c.alive:
			continue
		for a in c.allies.duplicate():
			if a > c.id and rng.randf() < 0.003:
				break_alliance(c.id, a)


func make_alliance(a: int, b: int) -> void:
	if is_allied(a, b):
		return
	countries[a].allies.append(b)
	countries[b].allies.append(a)
	stats.alliances += 1
	if a == player or b == player:
		stats.p_alliances += 1
	post_news(Names.alliance(rng, countries[a].name, countries[b].name), countries[a].capital, "alliance")
	# isimli blok: iki bloksuz ülke yeni blok kurar; biri blokluysa diğeri ona katılır
	var ba: int = countries[a].alliance
	var bb: int = countries[b].alliance
	if ba < 0 and bb < 0:
		var nm: String = Names.bloc_name(rng, countries[a].name, _bloc_names())
		var bid: int = create_bloc(a, nm, Emblem.random_emblem(rng, countries[a].color))
		_bloc_join_quiet(bid, b)
	elif ba >= 0 and bb < 0 and bloc_get(ba).members.size() < 10:
		_bloc_join_quiet(ba, b)
	elif bb >= 0 and ba < 0 and bloc_get(bb).members.size() < 10:
		_bloc_join_quiet(bb, a)
	state_changed.emit()


func break_alliance(a: int, b: int) -> void:
	if not is_allied(a, b):
		return
	countries[a].allies.erase(b)
	countries[b].allies.erase(a)
	post_news(Names.alliance_broken(rng, countries[a].name, countries[b].name), -1, "info")
	if countries[a].alliance >= 0 and countries[a].alliance == countries[b].alliance:
		bloc_leave(a, true)
	for arm in armies.values().duplicate():
		if arm.owner == a or arm.owner == b:
			var p2 = provinces[arm.prov]
			if p2.owner != arm.owner and not at_war(arm.owner, p2.owner) and not is_allied(arm.owner, p2.owner):
				_send_home(arm)
	state_changed.emit()


# ---- isimli ittifak blokları

func _bloc_names() -> Dictionary:
	var used: Dictionary = {}
	for b in blocs:
		used[b.name] = true
	return used


func bloc_get(bid: int) -> Dictionary:
	for b in blocs:
		if b.id == bid:
			return b
	return {}


func create_bloc(founder: int, bname: String, emblem: Dictionary) -> int:
	var b: Dictionary = {"id": next_bloc_id, "name": bname, "emblem": emblem, "members": [founder], "founder": founder, "born": turn}
	next_bloc_id += 1
	blocs.append(b)
	countries[founder].alliance = b.id
	return b.id


## üyeyi ekler ve mevcut tüm üyelerle karşılıklı ittifak bağı kurar
func bloc_add(bid: int, cid: int) -> void:
	var b: Dictionary = bloc_get(bid)
	if b.is_empty() or b.members.has(cid):
		return
	for m in b.members:
		if at_war(cid, m):
			return
	for m in b.members:
		if not is_allied(cid, m):
			countries[cid].allies.append(m)
			countries[m].allies.append(cid)
	b.members.append(cid)
	countries[cid].alliance = bid


func _bloc_join_quiet(bid: int, cid: int) -> void:
	bloc_add(bid, cid)


func bloc_leave(cid: int, silent: bool = false) -> void:
	var bid: int = countries[cid].alliance
	if bid < 0:
		return
	var b: Dictionary = bloc_get(bid)
	countries[cid].alliance = -1
	if b.is_empty():
		return
	for m in b.members:
		if m != cid:
			countries[cid].allies.erase(m)
			countries[m].allies.erase(cid)
	b.members.erase(cid)
	if not silent:
		post_news("%s, %s ittifakından ayrıldı." % [countries[cid].name, b.name], countries[cid].capital, "alliance")
	if b.members.size() < 2:
		for m2 in b.members:
			countries[m2].alliance = -1
		blocs.erase(b)
		if not silent:
			post_news("%s dağıldı." % b.name, -1, "alliance")
	elif b.founder == cid:
		b.founder = b.members[0]


func bloc_accepts(target: int, bid: int) -> String:
	var t = countries[target]
	var b: Dictionary = bloc_get(bid)
	if b.is_empty() or not t.alive or t.is_rebel:
		return "Geçersiz hedef."
	if t.alliance >= 0:
		return "%s zaten başka bir ittifakta." % t.name
	var near := false
	var common := false
	for m in b.members:
		if at_war(target, m):
			return "%s, ittifak üyesi %s ile savaşta." % [t.name, countries[m].name]
		for e in t.enemies:
			if countries[m].enemies.has(e):
				common = true
	for oid in neighbor_countries(target):
		if b.members.has(oid):
			near = true
	var chance: float = 0.18 + 0.02 * b.members.size()
	if near:
		chance += 0.25
	if common:
		chance += 0.35
	if power_of(countries[b.founder]) > power_of(t) * 1.5:
		chance += 0.12
	if rng.randf() < chance:
		return ""
	return "%s daveti reddetti." % t.name


func player_found_bloc(bname: String, emblem: Dictionary) -> String:
	if countries[player].alliance >= 0:
		return "Zaten bir ittifaktasın."
	bname = bname.strip_edges()
	if bname.length() < 3 or bname.length() > 30:
		return "İttifak adı 3-30 harf olmalı."
	if _bloc_names().has(bname):
		return "Bu ad kullanımda."
	var bid: int = create_bloc(player, bname, emblem)
	post_news("%s, \"%s\" ittifakını kurdu." % [countries[player].name, bname], countries[player].capital, "alliance")
	state_changed.emit()
	return ""


func player_invite(target: int) -> String:
	var bid: int = countries[player].alliance
	if bid < 0:
		return "Önce bir ittifak kur."
	var why: String = bloc_accepts(target, bid)
	if why != "":
		return why
	bloc_add(bid, target)
	var b: Dictionary = bloc_get(bid)
	post_news("%s, %s ittifakına katıldı." % [countries[target].name, b.name], countries[target].capital, "alliance")
	state_changed.emit()
	return ""


func ai_accepts_alliance(ai: int, other: int) -> bool:
	var c = countries[ai]
	var o = countries[other]
	if not c.alive or not o.alive or c.is_rebel or o.is_rebel:
		return false
	if at_war(ai, other) or is_allied(ai, other):
		return false
	if (c.id != player and c.allies.size() >= AI_MAX_ALLIES) or (o.id != player and o.allies.size() >= AI_MAX_ALLIES):
		return false
	for e in c.enemies:
		if o.allies.has(e):
			return false
	for e2 in o.enemies:
		if c.allies.has(e2):
			return false
	var common := false
	for e in o.enemies:
		if c.enemies.has(e):
			common = true
	var chance := 0.15
	if common:
		chance = 0.85
	elif neighbor_countries(ai).has(other):
		chance = 0.40
	return rng.randf() < chance


func player_propose_alliance(target: int) -> String:
	var t = countries[target]
	if t.is_rebel:
		return "İsyancılarla ittifak kurulmaz."
	if at_war(player, target):
		return "Savaştayken ittifak teklif edilemez."
	if is_allied(player, target):
		return "Zaten müttefiksiniz."
	if ai_accepts_alliance(target, player):
		make_alliance(player, target)
		return ""
	return "%s ittifak teklifini reddetti." % t.name


func player_break_alliance(target: int) -> String:
	if not is_allied(player, target):
		return "Müttefik değilsiniz."
	break_alliance(player, target)
	return ""


# ------------------------------------------------------------ müttefik yardımı

func _aid_left(kind: String, ally: int) -> int:
	return maxi(0, int(aid.cd.get("%s%d" % [kind, ally], 0)) - turn)


func _aid_set(kind: String, ally: int, weeks: int) -> void:
	aid.cd["%s%d" % [kind, ally]] = turn + weeks


## Müttefikin savaşa sokabileceğimiz düşmanlarımız (zaten savaşmadığı, müttefiki olmadığı).
func aid_request_foes(ally: int) -> Array:
	var out: Array = []
	for e in countries[player].enemies:
		var o = countries[e]
		if o.alive and e != ally and not at_war(ally, e) and not is_allied(ally, e):
			out.append(e)
	out.sort_custom(func(x, y): return countries[x].troops > countries[y].troops)
	return out


func aid_request_chance(ally: int, foe: int) -> float:
	var a = countries[ally]
	var f = countries[foe]
	var ch := 0.5
	if a.alliance >= 0 and a.alliance == countries[player].alliance:
		ch += 0.15
	if a.enemies.has(foe) or f.enemies.has(ally):
		ch += 0.3
	ch += clampf((a.troops - f.troops) / maxf(1.0, f.troops) * 0.1, -0.15, 0.15)
	ch -= 0.12 * float(a.enemies.size())
	if int(aid.good.get(str(ally), 0)) > turn:
		ch += 0.2
	ch -= 0.1 * maxf(0.0, war_load() - 0.8)
	return clampf(ch, 0.1, 0.92)


## Savaştayken tek bir müttefikten yardım iste: {ok, text}
func player_request_aid(ally: int) -> Dictionary:
	if not is_allied(player, ally) or not countries[ally].alive:
		return {"ok": false, "text": "Müttefik değilsiniz."}
	if countries[player].enemies.is_empty():
		return {"ok": false, "text": "Savaşta değilsin; yardım istemek için savaş gerek."}
	var nm: String = countries[ally].name
	var left := _aid_left("r", ally)
	if left > 0:
		return {"ok": false, "text": "%s yakında yanıt verdi; %d hafta sonra tekrar iste." % [nm, left]}
	var foes := aid_request_foes(ally)
	if foes.is_empty():
		return {"ok": false, "text": "%s zaten tüm düşmanlarınla savaşıyor." % nm}
	var foe: int = foes[0]
	if rng.randf() < aid_request_chance(ally, foe):
		if declare_war(ally, foe, true):
			_aid_set("r", ally, 10)
			post_news(Names.ally_joined(rng, nm, countries[player].name, countries[foe].name), countries[ally].capital, "war")
			state_changed.emit()
			return {"ok": true, "text": "%s yardım isteğini kabul etti ve %s'a savaş açtı!" % [nm, countries[foe].name]}
	_aid_set("r", ally, 5)
	return {"ok": false, "text": "%s şimdilik savaşa girmek istemiyor." % nm}


## Tüm müttefiklerden yardım iste: {ok(joined count), text}
func player_request_aid_all() -> Dictionary:
	var joined := 0
	var n_all: int = countries[player].allies.size()
	for a in countries[player].allies.duplicate():
		var r: Dictionary = player_request_aid(a)
		if r.ok:
			joined += 1
	if n_all == 0:
		return {"ok": false, "text": "Müttefikin yok."}
	return {"ok": joined > 0, "joined": joined, "text": "%d müttefik savaşa katıldı." % joined if joined > 0 else "Hiçbir müttefik savaşa katılmadı."}


## Müttefikin savaştığı, bizim henüz savaşmadığımız düşmanlar.
func aid_join_foes(ally: int) -> Array:
	var out: Array = []
	var me = countries[player]
	for e in countries[ally].enemies:
		var o = countries[e]
		if o.alive and e != player and not at_war(player, e) and not is_allied(player, e) and me.truce.get(e, -1) <= turn:
			out.append(e)
	out.sort_custom(func(x, y): return countries[x].troops > countries[y].troops)
	return out


## Müttefikin savaşına katıl (en güçlü düşmanına savaş aç): hata metni ya da "".
func player_aid_join(ally: int) -> String:
	if not is_allied(player, ally):
		return "Müttefik değilsiniz."
	var foes := aid_join_foes(ally)
	if foes.is_empty():
		return "%s'ın savaşına katılabileceğin bir düşman yok." % countries[ally].name
	declare_war(player, foes[0], true)
	aid.good[str(ally)] = turn + 60
	state_changed.emit()
	return ""


func aid_gold_cost() -> float:
	return maxf(20.0, countries[player].income * 3.0)


## Müttefike mali yardım: hata metni ya da "".
func player_aid_gold(ally: int) -> String:
	if not is_allied(player, ally):
		return "Müttefik değilsiniz."
	var left := _aid_left("g", ally)
	if left > 0:
		return "Yeni yardım için %d hafta bekle." % left
	var cost := aid_gold_cost()
	var me = countries[player]
	if me.gold < cost:
		return "Kasa yetmiyor."
	var a = countries[ally]
	me.gold -= cost
	a.gold += cost * 0.8
	a.stability = minf(100.0, a.stability + 2.0)
	_aid_set("g", ally, 8)
	aid.good[str(ally)] = turn + 40
	post_news("%s, müttefiki %s'a mali yardım gönderdi." % [me.name, a.name], a.capital, "alliance")
	state_changed.emit()
	return ""


func player_join_war(foe: int) -> void:
	pending_proposal = false
	declare_war(player, foe, true)
	state_changed.emit()


func _ai_alliance_decision(c) -> void:
	if c.is_rebel or c.allies.size() >= AI_MAX_ALLIES - 2 or turn < 3:
		return
	if rng.randf() > 0.007:
		return
	var cands: Array = []
	for oid in neighbor_countries(c.id):
		var o = countries[oid]
		if o.alive and not o.is_rebel and not at_war(c.id, oid) and not is_allied(c.id, oid) and (oid == player or o.allies.size() < AI_MAX_ALLIES):
			cands.append(oid)
	if cands.is_empty():
		return
	var t: int = cands[rng.randi_range(0, cands.size() - 1)]
	if t == player:
		if not pending_proposal:
			pending_proposal = true
			alliance_proposal.emit(c.id)
		return
	if ai_accepts_alliance(t, c.id):
		make_alliance(c.id, t)


## Barış masasında eyalete ek olarak seçilebilen şartlar (maliyet savaş puanından düşer).
const PEACE_TERMS := {
	"reparations": {"name": "Savaş tazminatı", "desc": "Yenilenin kasasının yarısı sana geçer, istikrarı düşer.", "cost": 6},
	"disarm": {"name": "Silahsızlandırma", "desc": "Yenilenin orduları yarıya iner.", "cost": 8},
	"buffer": {"name": "Tampon bölge", "desc": "Ateşkes 26 yerine 78 hafta sürer; iki taraf da saldıramaz.", "cost": 5},
}


func _apply_terms(winner: int, loser: int, terms: Array) -> String:
	var parts: Array = []
	if terms.has("reparations"):
		var amt: float = maxf(0.0, countries[loser].gold * 0.5)
		countries[loser].gold -= amt
		countries[winner].gold += amt
		countries[loser].stability = clampf(countries[loser].stability - 5.0, 5.0, 100.0)
		parts.append("tazminat")
	if terms.has("disarm"):
		for arm in armies.values():
			if arm.owner == loser:
				arm.size = maxi(1, int(arm.size * 0.5))
		parts.append("silahsızlandırma")
	if terms.has("buffer"):
		countries[winner].truce[loser] = turn + 78
		countries[loser].truce[winner] = turn + 78
		parts.append("tampon bölge")
	return ", ".join(parts)


func peace_options(w, winner: int) -> Array:
	var loser: int = w.other(winner)
	var out: Array = []
	for p in provinces:
		if p.owner == loser and p.controller == winner:
			out.append({"pid": p.id, "cost": p.peace_cost()})
	return out


func _ai_choose_annex(w, winner: int) -> Array:
	var opts := peace_options(w, winner)
	opts.sort_custom(func(x, y): return x.cost > y.cost)
	var budget: int = w.score_of(winner)
	var loser: int = w.other(winner)
	var cap := maxi(3, int(countries[loser].prov_owned * 0.5))
	var picked: Array = []
	for o in opts:
		if picked.size() >= cap:
			break
		if o.cost <= budget:
			picked.append(o.pid)
			budget -= o.cost
	return picked


func _fix_capital(cid: int) -> void:
	var c = countries[cid]
	if not c.alive or c.is_rebel:
		return
	if c.capital >= 0 and provinces[c.capital].owner == cid:
		provinces[c.capital].is_capital = true
		return
	var best := -1
	for p in provinces:
		if p.owner == cid and (best < 0 or p.gdp > provinces[best].gdp):
			best = p.id
	if best >= 0:
		c.capital = best
		provinces[best].is_capital = true
		provinces[best].dev = maxi(provinces[best].dev, 3)


func finish_peace(w, winner: int, annex: Array, terms: Array = []) -> void:
	var a: int = w.a
	var b: int = w.b
	var changed: Array = []
	if winner >= 0:
		for pid in annex:
			var p = provinces[pid]
			p.owner = winner
			p.controller = winner
			p.siege = 0
			p.acquired = turn
			p.unrest = 0
			p.is_capital = false
			changed.append(pid)
		_fix_capital(w.other(winner))
	for p in provinces:
		if p.controller != p.owner and p.controller >= 0:
			if (p.owner == a and p.controller == b) or (p.owner == b and p.controller == a):
				p.controller = p.owner
				p.siege = 0
				changed.append(p.id)
	wars.erase(w)
	countries[a].enemies.erase(b)
	countries[b].enemies.erase(a)
	countries[a].truce[b] = turn + 26
	countries[b].truce[a] = turn + 26
	# artık savaşta olmadığımız topraklardaki ordular eve döner
	for arm in armies.values().duplicate():
		if arm.owner == a or arm.owner == b:
			var p2 = provinces[arm.prov]
			if p2.owner != arm.owner and not at_war(arm.owner, p2.owner) and not is_allied(arm.owner, p2.owner):
				_send_home(arm)
	stats.peaces += 1
	if a == player or b == player:
		stats.p_peaces += 1
	pending_proposal = false
	if winner >= 0 and not terms.is_empty():
		var tl: String = _apply_terms(winner, w.other(winner), terms)
		if tl != "":
			post_news("Barış şartları: %s, %s'e şunları dayattı: %s." % [countries[winner].name, countries[w.other(winner)].name, tl], -1, "peace")
	var na: String = countries[a].name
	var nb: String = countries[b].name
	if a == player or b == player:
		post_news(Names.peace(rng, na, nb), -1, "peace")
	else:
		post_news(Names.peace(rng, na, nb), -1, "peace")
	if winner >= 0 and annex.size() > 0:
		var names: Array = []
		for pid in annex:
			names.append(provinces[pid].name)
		post_news(Names.annexed(rng, countries[winner].name, annex.size(), ", ".join(names)), annex[0], "peace")
	refresh_stats()
	for pid in changed:
		province_changed.emit(pid)
	armies_changed.emit()
	_check_elimination()
	refresh_stats()
	state_changed.emit()


func _send_home(arm) -> void:
	var from: int = arm.prov
	var prev := PackedInt32Array()
	prev.resize(provinces.size())
	prev.fill(-2)
	prev[from] = -1
	var q: Array = [from]
	var qi := 0
	var dest := -1
	while qi < q.size() and dest < 0:
		var cur: int = q[qi]
		qi += 1
		for nb in provinces[cur].neighbors:
			if prev[nb] != -2:
				continue
			prev[nb] = cur
			if provinces[nb].owner == arm.owner and provinces[nb].controller == arm.owner:
				var ex = armies.get(nb)
				if ex == null or (ex.owner == arm.owner and ex.size + arm.size <= MAX_MERGE):
					dest = nb
					break
			q.append(nb)
	armies.erase(from)
	arm.path.clear()
	arm.leaving = false
	if dest < 0:
		return
	var ex2 = armies.get(dest)
	if ex2 != null:
		ex2.size += arm.size
	else:
		arm.prov = dest
		armies[dest] = arm


func war_weariness_turns(w) -> int:
	return turn - w.start


func _lost_ratio(cid: int) -> float:
	var owned := 0
	var lost := 0
	for pid in countries[cid].owned_ids:
		owned += 1
		if provinces[pid].controller != cid:
			lost += 1
	return float(lost) / maxf(1.0, owned)


func _ai_wants_peace(ai: int, w) -> bool:
	var other: int = w.other(ai)
	var mine: int = w.score_of(ai)
	var theirs: int = w.score_of(other)
	var dur: int = turn - w.start
	if dur < 4:
		return false
	if _lost_ratio(ai) > 0.35:
		return true
	if dur > 8 and mine * 1.5 < theirs:
		return true
	if dur > 40 and absi(mine - theirs) < 15:
		return true
	if dur > 14 and mine + theirs == 0:
		return true
	if countries[ai].troops <= 0 and dur > 6:
		return true
	var wl := war_load()
	if wl > 0.8 and ai != player and dur > 20 and mine <= theirs * 1.5 + 5:
		return true
	if wl > 1.2 and ai != player and dur > 10 and mine <= theirs:
		return true
	return false


func player_request_peace(enemy: int) -> Dictionary:
	var w = get_war(player, enemy)
	if w == null:
		return {"ok": false, "text": "Bu ülkeyle savaşta değilsin."}
	if countries[enemy].is_rebel:
		return {"ok": false, "text": "İsyancılarla müzakere edilmez; eyaletleri geri al."}
	var dur: int = turn - w.start
	var mine: int = w.score_of(player)
	var theirs: int = w.score_of(enemy)
	var ename: String = countries[enemy].name
	var accept := false
	if dur < 3:
		return {"ok": false, "text": "%s: Savaş yeni başladı, barışa yanaşmıyorlar." % ename}
	if _ai_wants_peace(enemy, w):
		accept = true
	elif mine < theirs:
		accept = dur >= 6 and rng.randf() < 0.6
	elif dur >= 10 and mine == theirs:
		accept = true
	if not accept:
		return {"ok": false, "text": "%s barış teklifini reddetti." % ename}
	if mine > theirs:
		return {"ok": true, "mode": "player_wins", "war": w}
	if theirs > mine:
		var annex := _ai_choose_annex(w, enemy)
		finish_peace(w, enemy, annex)
		return {"ok": true, "mode": "done", "text": "%s barışı kabul etti ve %d eyalet aldı." % [ename, annex.size()]}
	finish_peace(w, -1, [])
	return {"ok": true, "mode": "done", "text": "Beraberlik barışı imzalandı."}


func _auto_peace(w) -> void:
	var winner := -1
	if w.score_a > w.score_b:
		winner = w.a
	elif w.score_b > w.score_a:
		winner = w.b
	var annex: Array = []
	if winner >= 0:
		annex = _ai_choose_annex(w, winner)
	finish_peace(w, winner, annex)


func cancel_proposal() -> void:
	pending_proposal = false


func _war_diplomacy() -> void:
	var ws: Array = wars.duplicate()
	for w in ws:
		if not wars.has(w):
			continue
		if countries[w.a].is_rebel or countries[w.b].is_rebel:
			continue
		if w.a == player or w.b == player:
			if pending_proposal:
				continue
			var ai: int = w.other(player)
			var mine: int = w.score_of(ai)
			var theirs: int = w.score_of(player)
			var dur: int = turn - w.start
			var kind := ""
			if _ai_wants_peace(ai, w) and rng.randf() < 0.3:
				kind = "loser_asks" if mine < theirs else "stalemate"
			elif mine > theirs * 1.4 + 5 and dur >= 8 and rng.randf() < 0.12 and not peace_options(w, ai).is_empty():
				kind = "winner_demands"
			if kind != "":
				pending_proposal = true
				peace_proposal.emit(w, ai, kind)
		else:
			var wa := _ai_wants_peace(w.a, w)
			var wb := _ai_wants_peace(w.b, w)
			if (wa or wb) and rng.randf() < 0.35 + minf(0.4, maxf(0.0, war_load() - 0.8) * 0.5):
				_auto_peace(w)


# ===================================================================== tur akışı

var profile := false
var prof: Dictionary = {}


func _tp(name: String, t0: int) -> int:
	if profile:
		var t1 := Time.get_ticks_usec()
		prof[name] = prof.get(name, 0) + (t1 - t0)
		return t1
	return 0


func end_turn() -> void:
	turn += 1
	if guard_left > 0:
		guard_left -= 1
	turn_battles.clear()
	var t := Time.get_ticks_usec() if profile else 0
	for c in countries:
		if c.alive and c.id != player:
			_ai_turn(c)
	last_auto = 0
	if player >= 0 and countries[player].alive:
		if countries[player].auto_cmd or (auto_idle and not player_acted):
			last_auto = _ai_orders(countries[player])
	player_acted = false
	t = _tp("ai", t)
	_move_armies()
	_merc_tick()
	t = _tp("move", t)
	_process_sieges()
	t = _tp("siege", t)
	refresh_stats()
	_check_elimination()
	_alliance_decay()
	_process_unrest()
	refresh_stats()
	t = _tp("stats_unrest", t)
	_check_rebels()
	Macro.weekly(self)
	Cabinet.weekly(self)
	_war_diplomacy()
	t = _tp("econ_dipl", t)
	if rng.randf() < 0.45:
		_random_event()
	if turn % 13 == 0:
		_post_ranking()
	Eras.leaders_tick(self)
	UN.weekly(self)
	Crises.weekly(self)
	GrandOp.tick(self)
	Independence.tick(self)
	Chokepoints.tick(self)
	Daily.tick(self)
	Politics.tick(self)
	WarRoom.tick(self)
	Objectives.tick(self)
	for vid in sea_campaign.keys():
		if vid >= countries.size() or not countries[vid].alive or not at_war(player, vid):
			sea_campaign.erase(vid)
	_coalition_tick()
	if turn % 52 == 0 and not Eras.leader_chain_active(turn):
		_leader_turnover()
	_check_victory()
	refresh_stats()
	t = _tp("rest", t)
	armies_changed.emit()
	state_changed.emit()


## Her yıl bazı ülkelerde lider değişir; yeni lider ülkenin isim kültürüne göre üretilir (deterministik tohum).
func _leader_turnover() -> void:
	var NG = load("res://scripts/name_gen.gd")
	for c in countries:
		if not c.alive or c.id == player or c.is_rebel:
			continue
		var cur: Array = Macro.leader_of(c)
		if cur[0] == "":
			continue
		if rng.randf() > 0.10:
			continue
		var key := "%s|leader|%d" % [c.name_en, turn]
		var fem: bool = NG.is_female(key, 0.2)
		var nm: String = NG.person(NG.culture_of(c), key, fem)
		c.leader = "%s|%s" % [cur[0], nm]
		var close: bool = player >= 0 and (c.enemies.has(player) or c.allies.has(player) or neighbor_countries(player).has(c.id))
		if close:
			post_news("%s'de yeni lider: %s %s göreve başladı." % [c.name, cur[0], nm], -1, "info")


## Kısmî gönderim: ordudan ayrılan müfreze tek başına yola çıkar, kalanlar yerinde durur.
func _move_detachments() -> void:
	for a in armies.values().duplicate():
		if a.sp_size <= 0:
			continue
		var n: int = mini(a.sp_size, a.size - 1)
		var path: Array = a.sp_path.duplicate()
		var op: String = a.sp_op
		a.sp_size = 0
		a.sp_path = []
		a.sp_op = ""
		if n <= 0 or path.is_empty():
			continue
		var d := Model.Army.new()
		d.id = next_army_id
		next_army_id += 1
		d.owner = a.owner
		d.prov = a.prov
		d.size = n
		d.path = path
		d.op = op
		d.leaving = true
		d.merc = a.merc
		d.merc_until = a.merc_until
		d.hold = a.sp_hold
		a.sp_hold = false
		a.size -= n
		var origin: int = a.prov
		armies[origin] = d
		_step_army(d)
		if armies.get(origin) == d:
			a.size += d.size          # yerinde kaldı (yol kapandı ya da yenildi): geri katıl
		armies[origin] = a
		armies_changed.emit()


func _move_armies() -> void:
	_move_detachments()
	var list: Array = armies.values()
	_shuffle(list)
	for a in list:
		if armies.get(a.prov) != a:
			continue
		_step_army(a)


func _step_army(a) -> void:
	if a.path.is_empty():
		a.leaving = false
		return
	if not a.leaving and is_sieging(a):
		return
	var nxt: int = a.path[0]
	var sea_hop: bool = a.op == "landing" and provinces[a.prov].sea_links.has(nxt)
	if (not provinces[a.prov].neighbors.has(nxt) and not sea_hop) or not can_enter(a.owner, nxt):
		a.path.clear()
		a.leaving = false
		return
	a.path.pop_front()
	a.leaving = false
	# dost orduların bulunduğu ara eyaletlerden geçip ilerle (yığılmayı önler)
	var hop: int = nxt
	var guard := 0
	while not a.path.is_empty() and guard < 4:
		var fr = armies.get(hop)
		if fr != null and fr.owner == a.owner and fr != a:
			var nn: int = a.path[0]
			if provinces[hop].neighbors.has(nn) and can_enter(a.owner, nn):
				a.path.pop_front()
				hop = nn
				guard += 1
				continue
		break
	_enter(a, hop)
	if a.path.is_empty():
		a.op = ""


func _enter(a, dest: int) -> void:
	var d = armies.get(dest)
	if d == null:
		_relocate(a, dest)
	elif d.owner == a.owner:
		if d.size + a.size > MAX_MERGE or (a.merc != "") != (d.merc != ""):
			a.path.clear()
			return
		d.size += a.size
		if a.hold:
			d.hold = true
		if a.cmd_lvl > d.cmd_lvl:
			d.cmd_lvl = a.cmd_lvl
			d.cmd_name = a.cmd_name
			d.cmd_wins = a.cmd_wins
		armies.erase(a.prov)
		a.path.clear()
	elif at_war(a.owner, d.owner):
		_battle(a, d, dest)
	else:
		a.path.clear()


func _relocate(a, dest: int) -> void:
	if armies.get(a.prov) == a:
		armies.erase(a.prov)
	a.prev_prov = a.prov
	a.prov = dest
	armies[dest] = a


func _battle(att, def, dest: int) -> void:
	var p = provinces[dest]
	var home: bool = (p.owner == def.owner) or (p.controller == def.owner)
	var op_id: String = att.op if OPS.has(att.op) else "assault"
	var o: Dictionary = OPS[op_id].duplicate()
	if o.get("no_fort", false):
		home = false
	var eff: Dictionary = op_effect(op_id, att.owner, def.owner)
	o.att = eff.att
	o.dp = eff.dp
	att.op = ""
	var surv_r: float = o.surv
	var ap: float = att.size * (1.0 + 0.05 * att.cmd_lvl) * rng.randf_range(0.85, 1.15) * Macro.battle_mult(self, att.owner, def.owner, true, p) * o.att
	var dp: float = def.size * (1.0 + 0.05 * def.cmd_lvl) * (1.0 + (0.15 + 0.12 * p.defense if home else 0.0)) * rng.randf_range(0.85, 1.15) * Macro.battle_mult(self, def.owner, att.owner, false, p) * o.dp
	var gm: Vector2 = Independence.war_mod(self, att, def, dest)
	ap *= gm.x
	dp *= gm.y
	if guard_left > 0 and def.owner == player and player >= 0 and countries[player].prov_owned <= SMALL_NATION:
		dp *= 1.0 + 0.7 * float(guard_left) / GUARD_WEEKS
	var w = get_war(att.owner, def.owner)
	var att_size: int = att.size
	var def_size: int = def.size
	var att_name: String = countries[att.owner].name
	var def_name: String = countries[def.owner].name
	stats.battles += 1
	if att.owner == player or def.owner == player:
		stats.p_battles += 1
	if ap > dp:
		var loss := int(ceil(def_size * dp / ap * LETHAL))
		Macro.attrition(self, def.owner, def_size - int(def_size * RETREAT_KEEP), countries[def.owner].troops)
		Macro.attrition(self, att.owner, loss, countries[att.owner].troops)
		_retreat(def, att.prov)
		att.size = maxi(1, att_size - loss)
		_relocate(att, dest)
		_record_battle(p, att.owner, def.owner, att_size, def_size, loss, def_size - int(def_size * 0.35), true, op_id)
		_commander_xp(att, def_size)
		if w != null:
			w.add(att.owner, 1 + int(def_size / 5000.0))
		if att_size + def_size >= 12000 or att.owner == player or def.owner == player:
			post_news(Names.big_battle(rng, att_name, def_name, p.name), dest, "battle")
	else:
		var loss2 := int(ceil(att_size * ap / dp * LETHAL))
		Macro.attrition(self, att.owner, att_size - int(att_size * (1.0 - (1.0 - surv_r) * 0.3)), countries[att.owner].troops)
		Macro.attrition(self, def.owner, loss2, countries[def.owner].troops)
		def.size = maxi(1, def_size - loss2)
		var survivors := int(att_size * (1.0 - (1.0 - surv_r) * 0.3))
		_record_battle(p, att.owner, def.owner, att_size, def_size, att_size - survivors, loss2, false, op_id)
		_commander_xp(def, att_size)
		att.path.clear()
		if survivors <= 0:
			armies.erase(att.prov)
		else:
			att.size = survivors
		if w != null:
			w.add(def.owner, 1 + int(att_size / 5000.0))
		if att_size + def_size >= 12000 or att.owner == player or def.owner == player:
			post_news(Names.big_battle(rng, def_name, att_name, p.name), dest, "battle")


## Fetih sürtünmesi: oyuncu hızla toprak kazanırsa dünya tepki gösterir; eşik aşılınca komşular ve büyük güçler koalisyon kurar.
func _coalition_tick() -> void:
	if player < 0:
		return
	infamy = maxf(0.0, infamy - 0.35)
	if infamy < 15.0:
		infamy_warned = false
	elif infamy >= 25.0 and not infamy_warned:
		infamy_warned = true
		post_news("Dünya, %s'nin yükselişinden endişeli: komşular ve büyük güçler soğuk bakıyor." % countries[player].name, -1, "war")
	if infamy < 50.0 or turn % 8 != 0:
		return
	var pool: Array = []
	var nb: Array = neighbor_countries(player)
	for c in countries:
		if not c.alive or c.is_rebel or c.id == player or is_allied(c.id, player) or at_war(c.id, player):
			continue
		if c.truce.get(player, -1) > turn:
			continue
		if nb.has(c.id) or c.troops > countries[player].troops * 0.5:
			pool.append(c)
	if pool.is_empty():
		return
	var n: int = 1 + int((infamy - 50.0) / 25.0)
	_shuffle(pool)
	var joined := 0
	for c in pool:
		if joined >= n:
			break
		if declare_war(c.id, player, true):
			joined += 1
	if joined > 0:
		infamy = maxf(0.0, infamy - 10.0 * joined)
		post_news("KOALİSYON! %d ülke, %s'nin fetihlerine karşı savaş ilan etti." % [joined, countries[player].name], -1, "war_player")


## Büyük bir muharebe kazanan ordu komutan çıkarır; kazandıkça seviye atlar (azami 5).
func _commander_xp(a, foe_size: int) -> void:
	if a.size < 3000 or foe_size < 1500 or a.merc != "":
		return
	a.cmd_wins += 1
	var lvl: int = mini(5, 1 + (a.cmd_wins - 1) / 2)
	if a.cmd_name == "":
		var NG = load("res://scripts/name_gen.gd")
		var key := "%d|cmd|%d" % [a.id, turn]
		a.cmd_name = NG.person(NG.culture_of(countries[a.owner]), key, false)
	if lvl > a.cmd_lvl:
		a.cmd_lvl = lvl
		if a.owner == player:
			post_news("Komutan %s sefer kazandı: seviye %d (+%%%d savaş gücü)." % [a.cmd_name, lvl, lvl * 5], a.prov, "battle")


func _record_battle(p, att_id: int, def_id: int, att_size: int, def_size: int, att_loss: int, def_loss: int, att_won: bool, op_id: String) -> void:
	if att_id != player and def_id != player:
		return
	turn_battles.append({"prov": p.id, "name": p.name, "att": att_id, "def": def_id,
		"att_name": countries[att_id].name, "def_name": countries[def_id].name,
		"att_size": att_size, "def_size": def_size, "att_loss": att_loss, "def_loss": def_loss,
		"att_won": att_won, "op": op_id})


func _retreat(d, avoid: int) -> void:
	var survivors := int(d.size * RETREAT_KEEP)
	var from: int = d.prov
	armies.erase(from)
	if survivors < 1:
		return
	var opts: Array = []
	for nb in provinces[from].neighbors:
		if nb == avoid:
			continue
		if provinces[nb].controller != d.owner:
			continue
		var other = armies.get(nb)
		if other != null and (other.owner != d.owner or other.size + survivors > MAX_MERGE):
			continue
		opts.append(nb)
	if opts.is_empty():
		# sıkışan ordu tamamen yok olmasın: en yakın dost eyalete (kayıpla) çekilir
		var own: int = d.owner
		var pth: Array = path_nearest(own, from, func(n): return provinces[n].controller == own and n != avoid and not armies.has(n))
		if pth.is_empty():
			return
		d.size = int(survivors * 0.7)
		d.prov = pth.back()
		d.path.clear()
		armies[d.prov] = d
		return
	var dest: int = opts[rng.randi_range(0, opts.size() - 1)]
	var ex = armies.get(dest)
	if ex != null:
		ex.size += survivors
	else:
		d.size = survivors
		d.prov = dest
		d.path.clear()
		armies[dest] = d


func _process_sieges() -> void:
	var active: Dictionary = {}
	for a in armies.values().duplicate():
		var p = provinces[a.prov]
		if p.controller == a.owner or a.leaving:
			continue
		if not (at_war(a.owner, p.controller) or at_war(a.owner, p.owner)):
			continue
		active[p.id] = true
		if p.siege_by != a.owner:
			p.siege_by = a.owner
			p.siege = 0
		var sg: int = 1 + (1 if a.size >= 300000 else 0)
		if guard_left > 0 and p.owner == player and player >= 0 and countries[player].prov_owned <= SMALL_NATION and (turn + p.id) % 2 == 0:
			sg = 0     # küçük oyuncu devleti: ilk haftalarda kuşatmalar yarı hızda ilerler
		p.siege += sg
		if p.siege >= p.siege_needed():
			_complete_siege(a, p)
	for p in provinces:
		if p.siege > 0 and not active.has(p.id):
			p.siege = maxi(0, p.siege - 1)


func _complete_siege(a, p) -> void:
	var old_controller: int = p.controller
	p.controller = a.owner
	p.siege = 0
	p.siege_by = -1
	var w = get_war(a.owner, p.owner)
	if w == null and old_controller >= 0:
		w = get_war(a.owner, old_controller)
	if w != null:
		w.add(a.owner, p.value() * (3 if p.owner != a.owner else 1))
	stats.captures += 1
	if a.owner == player:
		stats.p_captures += 1
		if not countries[p.owner].is_rebel:
			infamy = minf(100.0, infamy + 2.5)
	province_changed.emit(p.id)
	var by_name: String = countries[a.owner].name
	if a.owner == player:
		post_news(Names.player_captured(rng, p.name), p.id, "capture_player")
	elif p.owner == player:
		post_news(Names.player_lost(rng, p.name), p.id, "lost_player")
	else:
		post_news(Names.province_captured(rng, p.name, by_name), p.id, "capture")


func _check_elimination() -> void:
	var owned := PackedInt32Array()
	owned.resize(countries.size())
	var held := PackedInt32Array()
	held.resize(countries.size())
	for p in provinces:
		if p.owner >= 0:
			owned[p.owner] += 1
			if p.controller == p.owner:
				held[p.owner] += 1
	for c in countries:
		if not c.alive or c.is_rebel:
			continue
		if owned[c.id] == 0 or held[c.id] == 0:
			if owned[c.id] > 0 and Independence.Districts.holdout(self, c.id):
				continue
			_eliminate(c)


func _eliminate(c) -> void:
	if player >= 0 and c.enemies.has(player):
		stats.p_eliminated += 1
	for p in provinces:
		if p.owner == c.id:
			if p.controller != c.id and p.controller >= 0:
				p.owner = p.controller
				p.acquired = turn
				p.is_capital = false
			p.siege = 0
			province_changed.emit(p.id)
		elif p.controller == c.id:
			p.controller = p.owner
			p.siege = 0
			p.siege_by = -1
			province_changed.emit(p.id)
		if p.siege_by == c.id:
			p.siege = 0
			p.siege_by = -1
	for pid in armies.keys().duplicate():
		if armies[pid].owner == c.id:
			armies.erase(pid)
	for w in wars.duplicate():
		if w.involves(c.id):
			var o: int = w.other(c.id)
			countries[o].enemies.erase(c.id)
			wars.erase(w)
	c.enemies.clear()
	bloc_leave(c.id, true)
	for o in countries:
		o.allies.erase(c.id)
	c.allies.clear()
	c.alive = false
	for o2 in countries:
		o2.truce.erase(c.id)
	for o3 in countries:
		if o3.alive and not o3.is_rebel:
			_fix_capital(o3.id)
	stats.eliminated += 1
	post_news(Names.eliminated(rng, c.name), c.capital, "elim")
	if c.id == player:
		game_over.emit(false, "%s devleti yıkıldı. Cihan Bülteni sana başsağlığı diliyor." % c.name)
	pending_proposal = false
	refresh_stats()


func _check_victory() -> void:
	if player < 0 or victory_declared or not countries[player].alive:
		return
	var owned: int = countries[player].prov_owned
	if float(owned) / provinces.size() >= VICTORY_RATIO:
		victory_declared = true
		game_over.emit(true, "Dünyanın %d%%'ine hükmediyorsun. Cihan hâkimiyeti senin!" % int(100.0 * owned / provinces.size()))
		return
	if turn % 4 == 0:
		var tot := 0.0
		var mine := 0.0
		for p in provinces:
			if p.owner >= 0 and not countries[p.owner].is_rebel:
				tot += p.gdp
				if p.owner == player:
					mine += p.gdp
		if tot > 0.0 and mine / tot >= ECON_RATIO:
			victory_declared = true
			game_over.emit(true, "Dünya ekonomisinin %%%d'ini kontrol ediyorsun. Ekonomik hegemonya senin!" % int(100.0 * mine / tot))


# ===================================================================== oyuncu eylemleri

func player_order_move(a, target: int, count: int = 0) -> String:
	if a.owner != player:
		return "Bu ordu senin değil."
	if a.prov == target:
		return ""
	var path := path_to(player, a.prov, target)
	if path.is_empty():
		return "Oraya ulaşamazsın (geçiş izni yok ya da yol yok)."
	if count > 0 and count < a.size:
		a.sp_size = clampi(count, 1, a.size - 1)
		a.sp_path = path
		a.sp_op = ""
		a.sp_hold = true             # gönderilen müfreze varış yerinde elle kalır; kalanlar otomatikte
		a.path.clear()
		a.leaving = false
	else:
		a.sp_size = 0
		a.sp_path = []
		a.path = path
		a.leaving = true
		a.hold = true
	player_acted = true
	stats.orders += 1
	armies_changed.emit()
	return ""


func player_cancel_move(a) -> void:
	a.path.clear()
	a.leaving = false
	a.sp_size = 0
	a.sp_path = []
	armies_changed.emit()


func player_declare_war(target: int) -> String:
	if target < 0 or target >= countries.size():
		return "Geçersiz hedef."
	if target == player or not countries[target].alive:
		return "Geçersiz hedef."
	if at_war(player, target):
		return "Zaten savaştasınız."
	if is_allied(player, target):
		return "Müttefike savaş açamazsın; önce ittifakı boz."
	if countries[player].truce.get(target, -1) > turn:
		return "Ateşkes sürüyor (%d tur)." % (countries[player].truce[target] - turn)
	declare_war(player, target)
	state_changed.emit()
	return ""


# ===================================================================== gizli harekât

const COVERT := {
	"spy": {"name": "Casusluk ağı", "desc": "Hedefin savunma sırlarını çal: teknolojin yükselir.", "scene": "spy", "icon": "spy", "k": 0.06, "cd": 4},
	"prop": {"name": "Propaganda", "desc": "Hedefte halkı yönetime karşı kışkırt: istikrarı düşer.", "scene": "summit", "icon": "megaphone", "k": 0.05, "cd": 4},
	"sab": {"name": "Sabotaj", "desc": "Fabrika ve altyapıya zarar ver: sanayi ve istikrar düşer.", "scene": "cyber", "icon": "bomb", "k": 0.09, "cd": 5},
	"emb": {"name": "Elçilik", "desc": "Diplomatik temas: hedefin sana karşı saldırganlığı azalır.", "scene": "summit", "icon": "embassy", "k": 0.04, "cd": 6},
}


func covert_cost(c, kind: String) -> float:
	return maxf(6.0, c.income * COVERT[kind].k)


func covert_chance(me, o, kind: String) -> float:
	if kind == "emb":
		return 0.85 if not at_war(me.id, o.id) else 0.0
	var base := 0.5 if kind != "sab" else 0.4
	return clampf(base + (me.cyber - o.cyber) / 220.0 + (me.tech - o.tech) * 0.2, 0.1, 0.9)


## oyuncunun gizli harekâtı: {ok, text}
func player_covert(target: int, kind: String) -> Dictionary:
	var me = countries[player]
	var o = countries[target]
	if target == player or not o.alive or not COVERT.has(kind):
		return {"ok": false, "text": "Geçersiz hedef."}
	if me.covert_cd.get(target, -1) > turn:
		return {"ok": false, "text": "Bu hedefte ajanlar saklanıyor (%d tur)." % (me.covert_cd[target] - turn)}
	var cost := covert_cost(me, kind)
	if me.gold < cost:
		return {"ok": false, "text": "Kasa yetmiyor."}
	if kind == "emb" and at_war(player, target):
		return {"ok": false, "text": "Savaştaki devlete elçilik açılmaz."}
	me.gold -= cost
	me.covert_cd[target] = turn + int(COVERT[kind].cd)
	var good := rng.randf() < covert_chance(me, o, kind)
	var text := ""
	match kind:
		"spy":
			if good:
				me.tech = minf(1.0, me.tech + 0.012)
				text = "%s'nın savunma planları ele geçirildi. Silah teknolojin ilerledi." % o.name
			else:
				me.stability = maxf(0.0, me.stability - 1.5)
				text = "Casus ağın %s'da çökertildi. Skandal iç siyaseti sarstı." % o.name
		"prop":
			if good:
				o.stability = maxf(0.0, o.stability - 7.0)
				text = "%s'da protestolar büyüyor. İstikrar düştü." % o.name
			else:
				text = "%s propagandanı sansürledi; para boşa gitti." % o.name
		"sab":
			if good:
				o.industry = maxf(5.0, o.industry - 5.0)
				o.stability = maxf(0.0, o.stability - 3.0)
				text = "%s'da fabrikalarda gizemli yangınlar çıktı. Sanayi sarsıldı." % o.name
			else:
				me.stability = maxf(0.0, me.stability - 2.0)
				o.aggression = minf(1.0, o.aggression + 0.08)
				text = "Sabotaj timin yakalandı! %s sana öfkeli." % o.name
		"emb":
			if good:
				o.aggression = maxf(0.05, o.aggression - 0.12)
				text = "%s ile ilişkiler ısındı; saldırganlığı azaldı." % o.name
			else:
				text = "%s elçiliğini soğuk karşıladı." % o.name
	post_news(text, -1, "info")
	state_changed.emit()
	return {"ok": true, "good": good, "text": text, "cost": cost}


# ===================================================================== yapay zeka

# ===================================================================== paralı askerler

const MERC_TIERS := [
	{"id": "band", "name": "Gönüllü Çete", "pct": 0.025, "lo": 2000, "hi": 15000, "cost": 1.4, "weeks": 13,
		"desc": "Ucuz ve kalabalık; kısa sözleşme."},
	{"id": "pro", "name": "Profesyonel Birlik", "pct": 0.06, "lo": 5000, "hi": 35000, "cost": 4.0, "weeks": 26,
		"desc": "Eğitimli, dengeli maliyet."},
	{"id": "elite", "name": "Özel Harekât Şirketi", "pct": 0.10, "lo": 9000, "hi": 60000, "cost": 10.0, "weeks": 26,
		"desc": "Pahalı ama büyük ve tecrübeli kadro."},
]


func merc_offer(c, tier: int) -> Dictionary:
	tier = clampi(tier, 0, MERC_TIERS.size() - 1)
	var t: Dictionary = MERC_TIERS[tier]
	var n: int = clampi(int(c.base_troops * t.pct), t.lo, t.hi)
	var unit: float = Cabinet._income_unit(self, c)
	return {"n": n, "cost": unit * t.cost, "weeks": t.weeks, "name": t.name, "desc": t.desc}


## Paralı birlik kiralar: boş bir eyalete (öncelik cephe/başkent) yerleşir. Dönen: {err, name, prov, n}
func hire_merc(cid: int, tier: int, pay: bool = true) -> Dictionary:
	tier = clampi(tier, 0, MERC_TIERS.size() - 1)
	var c = countries[cid]
	var res := {"err": "", "name": "", "prov": -1, "n": 0}
	var offer: Dictionary = merc_offer(c, tier)
	if pay and c.gold < offer.cost:
		res.err = "Kasa yetersiz: sözleşme bedeli %s." % Macro.money(offer.cost)
		return res
	var best := -1
	var best_w := -1.0
	for hid in c.held_ids:
		var p = provinces[hid]
		if p.controller != c.id or armies.get(hid) != null:
			continue
		var w := 1.0 + (2.0 if p.is_capital else 0.0) + float(p.unrest) * 0.3
		for nb in p.neighbors:
			var no: int = provinces[nb].controller
			if no != c.id and no >= 0 and at_war(c.id, no):
				w += 4.0
				break
		w += rng.randf()
		if w > best_w:
			best_w = w
			best = hid
	if best < 0:
		res.err = "Birlik yerleştirecek boş eyalet yok."
		return res
	var a = _spawn_army(c.id, best, offer.n)
	if a == null:
		res.err = "Birlik yerleştirilemedi."
		return res
	if pay:
		c.gold -= offer.cost
	a.merc = Militias.unique(Militias.make(c, rng, "merc"), merc_names)
	a.merc_until = turn + offer.weeks
	res.name = a.merc
	res.prov = best
	res.n = offer.n
	if cid == player:
		post_news("%s sözleşme imzaladı: %s (%d asker) %s eyaletinde göreve başladı." % [c.name, a.merc, offer.n, provinces[best].name], best, "info", "recruit")
	armies_changed.emit()
	state_changed.emit()
	return res


func _merc_tick() -> void:
	for a in armies.values().duplicate():
		if a.merc == "" or a.merc_until < 0 or turn < a.merc_until:
			continue
		var c = countries[a.owner]
		armies.erase(a.prov)
		if a.owner == player:
			post_news("%s sözleşmesi bitti; %s asker ayrıldı." % [a.merc, Macro.num(a.size)], a.prov, "info", "veteran")
	# yapay zekâ ara sıra paralı kiralar (savaştaki, parası olan ülke)
	if turn % 4 == 0:
		for c in countries:
			if not c.alive or c.is_rebel or c.id == player or c.enemies.is_empty() or c.owned_ids.is_empty():
				continue
			if c.gold < Cabinet._income_unit(self, c) * 6.0 or rng.randf() > 0.06:
				continue
			hire_merc(c.id, rng.randi_range(0, 1), true)


func _ai_turn(c) -> void:
	_ai_war_decision(c)
	_ai_alliance_decision(c)
	_ai_orders(c)


## askerleri kritik eyaletlere dağıtır (makro askerlik alımının haritaya yansıması)
func place_recruits(c, n: int) -> void:
	var cands: Array = []
	var weights: Array = []
	for hid in c.held_ids:
		var p = provinces[hid]
		if p.owner != c.id and not c.is_rebel:
			continue
		var ex = armies.get(p.id)
		if ex != null and ex.owner != c.id:
			continue
		var wgt := 1.0
		if p.is_capital:
			wgt += 1.0
		if p.unrest >= 6 and ex == null:
			wgt += 3.0
		var foreign := false
		var hot := false
		for nb in p.neighbors:
			var no: int = provinces[nb].owner
			if no != c.id:
				foreign = true
				if at_war(c.id, no):
					hot = true
		if hot:
			wgt += 4.0
		elif foreign:
			wgt += 1.0
		cands.append(p.id)
		weights.append(wgt)
	if cands.is_empty():
		return
	var picks := clampi(n / 2500, 1, 6)
	var each: int = maxi(1, n / picks)
	for i in picks:
		var total := 0.0
		for wv in weights:
			total += wv
		var r := rng.randf() * total
		var idx := 0
		for k in weights.size():
			r -= weights[k]
			if r <= 0.0:
				idx = k
				break
		var pid: int = cands[idx]
		var ex2 = armies.get(pid)
		if ex2 == null:
			_spawn_army(c.id, pid, each)
		else:
			ex2.size += each


## Dünya savaş yorgunluğu: aktif (isyancı olmayan) savaş sayısı, canlı ülke sayısına göre yumuşak bir tavanı aşınca 1'den büyür.
var _wl_turn := -1
var _wl_val := 0.0


func war_load() -> float:
	if _wl_turn == turn:
		return _wl_val
	_wl_turn = turn
	var n := 0
	for w in wars:
		if not countries[w.a].is_rebel and not countries[w.b].is_rebel:
			n += 1
	var alive := 0
	for c in countries:
		if c.alive and not c.is_rebel:
			alive += 1
	_wl_val = float(n) / maxf(8.0, 6.0 + alive * 0.06)
	return _wl_val


func _ai_war_decision(c) -> void:
	if c.is_rebel or turn < 5 or c.enemies.size() >= 2:
		return
	var chance: float = 0.006 + c.aggression * 0.013
	if c.enemies.size() == 1:
		chance *= 0.3
	var wl := war_load()
	if wl > 0.6:
		chance /= 1.0 + 6.0 * (wl - 0.6) * (wl - 0.6) * 4.0 + (wl - 0.6) * 4.0
	if rng.randf() > chance:
		return
	var my_power := power_of(c)
	var best := -1
	var best_ratio := 0.0
	for oid in neighbor_countries(c.id):
		var o = countries[oid]
		if not o.alive or c.enemies.has(oid) or o.is_rebel or is_allied(c.id, oid):
			continue
		if c.truce.get(oid, -1) > turn:
			continue
		if oid == player and turn < 14:
			continue
		var their_power := power_of(o)
		for al in o.allies:
			their_power += power_of(countries[al]) * 0.25
		var ratio: float = my_power / maxf(1.0, their_power)
		if not o.enemies.is_empty():
			ratio *= 1.3
		if oid == player:
			ratio *= [0.7, 0.9, 1.2][clampi(difficulty, 0, 2)]
		if ratio > best_ratio:
			best_ratio = ratio
			best = oid
	if best >= 0 and best_ratio > 1.55 - c.aggression * 0.3:
		declare_war(c.id, best)


func _ai_target_ok(cid: int, pid: int, a) -> bool:
	var p = provinces[pid]
	var enemy_land: bool = at_war(cid, p.owner) and p.controller != cid
	var liberate: bool = p.owner == cid and at_war(cid, p.controller)
	if not (enemy_land or liberate):
		return false
	if cid == player:
		var tgt: int = p.controller if liberate else p.owner
		if Macro.stance(countries[cid], tgt) == "defend":
			return false
	var d = armies.get(pid)
	if d != null and d.owner == cid:
		return false
	# ikmal hattı: yalnızca kendi kontrolündeki eyalete bitişik cephe hedeflenir (derine sıçrama yok)
	var front := false
	for nb in p.neighbors:
		if provinces[nb].controller == cid:
			front = true
			break
	if not front:
		for sl in p.sea_links:
			if provinces[sl].controller == cid:
				front = true
				break
	if not front:
		return false
	if d != null and at_war(cid, d.owner):
		if d.size * (1.0 + 0.12 * p.defense) > a.size * 1.15:
			return false
	return true


func _ai_orders(c) -> int:
	var n := 0
	if c.enemies.is_empty():
		return 0
	var failed: Array = []     # hedefi bulunamayan aramalar: [ziyaret_haritası, ordu_büyüklüğü]; aynı bölgedeki eşit/küçük ordular tekrar aramaz
	for a in armies_of(c.id):
		if not a.path.is_empty() or a.sp_size > 0 or a.size < 2000 or is_sieging(a) or a.hold:
			continue
		var cid: int = c.id
		var arm = a
		var skip := false
		for fl in failed:
			if fl[0][a.prov] != -2 and a.size <= fl[1]:
				skip = true
				break
		var path: Array = []
		if not skip:
			path = path_nearest(cid, a.prov, func(pid): return _ai_target_ok(cid, pid, arm))
			if path.is_empty():
				failed.append([_pn_prev, a.size])
		if not path.is_empty():
			a.path = path
			n += 1
		elif _ai_try_landing(cid, arm):
			n += 1
		elif cid == player and not sea_campaign.is_empty() and _campaign_shuttle(cid, arm):
			n += 1
		elif not _ai_threatened(cid, a.prov, true):
			# saldırı yok: iç bölgedeki ordu en yakın tehdit altındaki boş cephe eyaletine kayar
			var rp := path_nearest(cid, a.prov, func(pid): return pid != arm.prov and _ai_threatened(cid, pid, false), 7)
			if not rp.is_empty() and rp.size() <= 7:
				a.path = rp
				n += 1
	return n


## Yapay zekâ amfibi çıkarması: kara hedefi yoksa deniz bağlantılı zayıf düşman eyaletine müfreze çıkarır.
func _ai_try_landing(cid: int, a) -> bool:
	var camp: bool = cid == player
	if camp and sea_campaign.is_empty():
		return false      # oyuncu için yalnızca kendi başlattığı deniz seferi sürer; yapay zekâ ada saldırısı başlatmaz
	if a.size < (3000 if camp else 6000) or a.merc != "" or rng.randf() > (0.6 if camp else 0.2):
		return false
	for q in provinces[a.prov].sea_links:
		if not _ai_target_ok(cid, q, a):
			continue
		if camp and not sea_campaign.has(_holder(q)):
			continue
		var n: int = mini(int(a.size * 0.7), landing_cap(cid))
		if n < 2500:
			return false
		var d = armies.get(q)
		if d != null and d.size > n * 0.8:
			continue
		a.sp_size = clampi(n, 1, a.size - 1)
		a.sp_path = [q]
		a.sp_op = "landing"
		a.sp_hold = false
		return true
	return false


func _holder(pid: int) -> int:
	var p = provinces[pid]
	return p.controller if p.controller >= 0 else p.owner


## Deniz seferi: kara hedefi olmayan ordu, çıkarma yapılabilecek bir kıyı eyaletine ilerler (sonra _ai_try_landing devreye girer).
func _campaign_shuttle(cid: int, a) -> bool:
	var arm = a
	var pth := path_nearest(cid, a.prov, func(pid):
		if pid == arm.prov or provinces[pid].controller != cid:
			return false
		for q in provinces[pid].sea_links:
			if sea_campaign.has(_holder(q)) and at_war(cid, _holder(q)) and _ai_target_ok(cid, q, arm):
				return true
		return false)
	if pth.is_empty() or pth.size() > 9:
		return false
	a.path = pth
	return true


## Savaş başında: iç bölgedeki orduların çoğu cephe eyaletlerine (boş olanlara) konuşlanır.
func deploy_front(cid: int) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		var moved := false
		for a in armies_of(cid):
			if a.size < 4000 or _ai_threatened(cid, a.prov, true) or provinces[a.prov].is_capital or a.merc != "" or a.hold:
				continue
			var arm = a
			var rp := path_nearest(cid, a.prov, func(pid): return pid != arm.prov and _ai_threatened(cid, pid, false))
			if rp.is_empty():
				continue
			_relocate(a, rp[rp.size() - 1])
			moved = true
		if not moved:
			break


## Düşmanın kontrolündeki ya da düşman ordusu bulunan bir eyalete komşu savunma eyaleti.
func _ai_threatened(cid: int, pid: int, allow_own_army: bool) -> bool:
	var p = provinces[pid]
	if p.controller != cid:
		return false
	if not allow_own_army and armies.get(pid) != null:
		return false
	for nb in p.neighbors:
		var q = provinces[nb]
		if q.controller != cid and q.controller >= 0 and at_war(cid, q.controller):
			return true
		var e = armies.get(nb)
		if e != null and e.owner != cid and at_war(cid, e.owner):
			return true
	return false


# ===================================================================== olaylar ve haberler

func crisis_active_for_card() -> bool:
	return not crisis.is_empty()


func _random_event() -> void:
	var alive: Array = []
	for c in countries:
		if c.alive and not c.is_rebel:
			alive.append(c)
	if alive.is_empty():
		return
	var c = alive[rng.randi_range(0, alive.size() - 1)]
	var kind := rng.randi_range(0, 15)
	var prov_ids := country_province_ids(c.id)
	var news_kind := "event_player" if c.id == player else "event"
	match kind:
		0:
			var amt: float = maxf(c.income, 1.0) * rng.randf_range(0.8, 2.0)
			c.gold += amt
			post_news(Names.event_boom(rng, c.name, Macro.money(amt)), c.capital, news_kind, "money_bag")
		1:
			var amt2: float = maxf(c.income, 1.0) * rng.randf_range(0.6, 1.5)
			c.gold = maxf(0.0, c.gold - amt2)
			post_news(Names.event_crisis(rng, c.name, Macro.money(amt2)), c.capital, news_kind, "debt")
		2:
			if prov_ids.is_empty():
				return
			var pid: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			var p = provinces[pid]
			if p.dev < 5:
				p.dev += 1
				post_news(Names.event_resource(rng, p.name, c.name), pid, news_kind, "oil")
		3:
			var n: int = int(c.base_troops * rng.randf_range(0.01, 0.03)) + 300
			var cap = provinces[c.capital]
			if cap.controller == c.id:
				var ex = armies.get(c.capital)
				if ex == null:
					_spawn_army(c.id, c.capital, n)
				elif ex.owner == c.id:
					ex.size += n
				else:
					return
				post_news(Names.event_volunteers(rng, c.name, Macro.num(n)), c.capital, news_kind, "infantry")
		4:
			if prov_ids.is_empty():
				return
			var pid2: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			var p2 = provinces[pid2]
			if p2.dev > 1:
				p2.dev -= 1
				post_news(Names.event_quake(rng, p2.name, c.name), pid2, news_kind, "earthquake")
		5:
			c.stability = clampf(c.stability - rng.randf_range(4.0, 9.0), 0.0, 100.0)
			var l5: float = maxf(c.income, 1.0) * rng.randf_range(0.2, 0.5)
			c.gold = maxf(0.0, c.gold - l5)
			post_news(Names.event_line("virus", rng, c.name, _rand_prov_name(prov_ids)), c.capital, news_kind, "virus")
		6:
			if prov_ids.is_empty():
				return
			var pid6: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			if provinces[pid6].dev > 1:
				provinces[pid6].dev -= 1
			post_news(Names.event_line("flood", rng, c.name, provinces[pid6].name), pid6, news_kind, "flood")
		7:
			var l7: float = maxf(c.income, 1.0) * rng.randf_range(0.4, 0.9)
			c.gold = maxf(0.0, c.gold - l7)
			post_news(Names.event_line("drought", rng, c.name, "", Macro.money(l7)), c.capital, news_kind, "drought")
		8:
			var coast: Array = []
			for q in prov_ids:
				if provinces[q].coastal:
					coast.append(q)
			if coast.is_empty():
				return
			var pid8: int = coast[rng.randi_range(0, coast.size() - 1)]
			var l8: float = maxf(c.income, 1.0) * rng.randf_range(0.3, 0.7)
			c.gold = maxf(0.0, c.gold - l8)
			post_news(Names.event_line("storm", rng, c.name, provinces[pid8].name, Macro.money(l8)), pid8, news_kind, "storm")
		9:
			if prov_ids.is_empty():
				return
			var pid9: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			provinces[pid9].unrest += rng.randi_range(3, 5)
			c.stability = clampf(c.stability - 2.0, 0.0, 100.0)
			post_news(Names.event_line("protest", rng, c.name, provinces[pid9].name), pid9, news_kind, "protest")
		10:
			if c.stability > 50.0:
				return
			c.stability = clampf(c.stability - rng.randf_range(6.0, 12.0), 0.0, 100.0)
			post_news(Names.event_line("coup", rng, c.name), c.capital, news_kind, "coup")
		11:
			if prov_ids.is_empty():
				return
			var pid11: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			var l11: float = maxf(c.income, 1.0) * rng.randf_range(0.2, 0.6)
			c.gold = maxf(0.0, c.gold - l11)
			provinces[pid11].unrest += 2
			post_news(Names.event_line("refugees", rng, c.name, provinces[pid11].name, Macro.money(l11)), pid11, news_kind, "refugees")
		15:
			if prov_ids.is_empty():
				return
			var pid15: int = prov_ids[rng.randi_range(0, prov_ids.size() - 1)]
			var grp: String = Militias.make(c, rng, "cell")
			provinces[pid15].unrest += rng.randi_range(2, 3)
			c.stability = clampf(c.stability - rng.randf_range(2.0, 4.0), 0.0, 100.0)
			var l15: float = maxf(c.income, 1.0) * rng.randf_range(0.1, 0.3)
			c.gold = maxf(0.0, c.gold - l15)
			var tl: String = Names.pick([
				"%s, %s eyaletinde saldırı düzenledi; güvenlik güçleri alarmda. (%s)",
				"%s saldırısı %s eyaletini sarstı. %s olağanüstü tedbir aldı.",
				"Yeraltından ses: %s, %s eyaletindeki saldırıyı üstlendi. (%s)",
			], rng)
			post_news(tl % [grp, provinces[pid15].name, c.name], pid15, news_kind, "bomb")
		12:
			var g12: float = maxf(c.income, 1.0) * rng.randf_range(0.5, 1.2)
			c.gold += g12
			c.stability = clampf(c.stability + 2.0, 0.0, 100.0)
			post_news(Names.event_line("harvest", rng, c.name, "", Macro.money(g12)), c.capital, news_kind, "wheat")
		13:
			c.tech = clampf(c.tech + 0.01, 0.0, 1.0)
			c.cyber = clampf(c.cyber + 2.0, 0.0, 100.0)
			post_news(Names.event_line("science", rng, c.name), c.capital, news_kind, "flask")
		14:
			c.stability = clampf(c.stability + rng.randf_range(2.0, 5.0), 0.0, 100.0)
			post_news(Names.event_line("summit", rng, c.name), c.capital, news_kind, "summit")


func _rand_prov_name(ids: Array) -> String:
	if ids.is_empty():
		return ""
	return provinces[ids[rng.randi_range(0, ids.size() - 1)]].name


func _post_ranking() -> void:
	refresh_stats()
	var rich = null
	var army = null
	var land = null
	for c in countries:
		if not c.alive or c.is_rebel:
			continue
		if rich == null or c.income > rich.income:
			rich = c
		if army == null or c.troops > army.troops:
			army = c
		if land == null or c.prov_owned > land.prov_owned:
			land = c
	if rich != null:
		post_news(Names.ranking(rng, rich.name, army.name, land.name), -1, "info")


# ===================================================================== isyancılar (devlet dışı gruplar)

func _process_unrest() -> void:
	var rebels_active := 0
	for c in countries:
		if c.alive and c.is_rebel:
			rebels_active += 1
	for c in countries:
		if not c.alive or c.is_rebel or c.prov_owned <= 18:
			continue
		if rng.randf() < (c.prov_owned - 18) * 0.004:
			var ids := country_province_ids(c.id)
			var pp = provinces[ids[rng.randi_range(0, ids.size() - 1)]]
			if not pp.is_capital and pp.controller == pp.owner:
				pp.unrest += 8
	for p in provinces:
		if p.owner < 0 or countries[p.owner].is_rebel or p.controller != p.owner:
			continue
		if p.owner != p.core and turn - p.acquired > 60:
			p.core = p.owner  # zamanla sindirilir
		var oc = countries[p.owner]
		var restless: bool = p.owner != p.core
		if not restless and oc.gold <= 0.0 and rng.randf() < 0.3:
			restless = true
		var g = armies.get(p.id)
		var garrisoned: bool = g != null and g.owner == p.owner
		if garrisoned:
			p.unrest = maxi(0, p.unrest - 2)
		elif restless:
			p.unrest += 1
		else:
			p.unrest = maxi(0, p.unrest - 1)
		if p.unrest >= 12 and rebels_active < 8 and rng.randf() < 0.3:
			if _spawn_rebels(p):
				rebels_active += 1


func _spawn_rebels(p) -> bool:
	if armies.get(p.id) != null:
		return false
	var owner_id: int = p.owner
	var faction = null
	for nb in p.neighbors:
		var cc: int = provinces[nb].controller
		if cc >= 0 and countries[cc].is_rebel and countries[cc].alive and at_war(cc, owner_id):
			faction = countries[cc]
			break
	if faction == null:
		faction = Model.Country.new()
		faction.id = countries.size()
		faction.is_rebel = true
		faction.name = Militias.unique(Militias.make(countries[owner_id], rng, "rebel"), rebel_name_count)
		faction.color = Color.from_hsv(rng.randf(), 0.6, 0.42)
		faction.color2 = Color(0.12, 0.12, 0.14)
		faction.color3 = Color(0.8, 0.12, 0.12)
		faction.flag_pattern = rng.randi_range(0, 5)
		faction.capital = -1
		faction.gold = 200.0
		faction.born = turn
		faction.aggression = 0.5
		countries.append(faction)
		declare_war(faction.id, owner_id, true)
	p.unrest = 6
	p.controller = faction.id
	p.siege = 0
	_spawn_army(faction.id, p.id, rng.randi_range(3000, 12000))
	stats.rebels += 1
	province_changed.emit(p.id)
	var kind := "rebel_player" if owner_id == player else "rebel"
	post_news(Names.rebel_uprising(rng, faction.name, p.name, countries[owner_id].name), p.id, kind)
	return true


func _check_rebels() -> void:
	for c in countries.duplicate():
		if not c.alive or not c.is_rebel:
			continue
		var age: int = turn - c.born
		if c.prov_owned > 0 or (c.prov_held >= 2 and age >= 15):
			_rebel_independence(c)
		elif c.prov_held == 0 and c.troops == 0:
			_rebel_crushed(c)


func _rebel_crushed(c) -> void:
	for w in wars.duplicate():
		if w.involves(c.id):
			var o: int = w.other(c.id)
			countries[o].enemies.erase(c.id)
			wars.erase(w)
	c.enemies.clear()
	c.alive = false
	post_news(Names.rebel_crushed(rng, c.name), -1, "peace")


func _rebel_independence(c) -> void:
	var held: Array = []
	for p in provinces:
		if p.controller == c.id:
			held.append(p)
	if held.is_empty():
		_rebel_crushed(c)
		return
	var cap = held[0]
	for p in held:
		if cap.is_capital or (not p.is_capital and p.gdp > cap.gdp):
			cap = p
	var former := "?"
	if cap.owner >= 0 and cap.owner != c.id:
		former = countries[cap.owner].name
	var group: String = c.name
	var used: Dictionary = {}
	for k in countries:
		used[k.name] = true
	var nm: String = Names.independent_name(cap.name, used)
	c.name = nm
	c.iso = ""
	c.is_rebel = false
	c.pop = 0.0
	c.gdp = 0.0
	for hp in held:
		c.pop += hp.pop
		c.gdp += hp.gdp
	c.base_troops = 0
	c.inv = {}
	c.budget = Macro.PRESETS["poor"].duplicate()
	c.capital = cap.id
	if not cap.is_capital:
		cap.is_capital = true
		cap.dev = maxi(cap.dev, 3)
	var h := rng.randf()
	c.color = Color.from_hsv(h, rng.randf_range(0.6, 0.8), rng.randf_range(0.88, 0.97))
	c.color2 = Color.WHITE
	c.color3 = Color.from_hsv(fmod(h + 0.4, 1.0), 0.7, 0.9)
	c.aggression = rng.randf_range(0.3, 0.9)
	var old_owners: Array = []
	for p in held:
		if p.owner >= 0 and p.owner != c.id and not old_owners.has(p.owner):
			old_owners.append(p.owner)
		if p.id != cap.id:
			p.is_capital = false
		p.owner = c.id
		p.controller = c.id
		p.core = c.id
		p.acquired = turn
		p.unrest = 0
		province_changed.emit(p.id)
	for oo in old_owners:
		_fix_capital(oo)
	stats.independence += 1
	post_news(Names.independence(rng, group, c.name, former), cap.id, "rebel")
	refresh_stats()


# ===================================================================== kayıt / yükleme

func to_dict() -> Dictionary:
	var d: Dictionary = {
		"v": 3, "seed": seed_value, "base": base_country_count,
		"turn": turn, "player": player, "next_army_id": next_army_id, "victory": victory_declared,
		"rng_state": rng.state, "rebel_names": rebel_name_count, "merc_names": merc_names, "stats": stats,
		"difficulty": difficulty, "blocs": blocs, "next_bloc": next_bloc_id, "cold": cold, "sea_camp": sea_campaign.keys(), "crisis": crisis, "crisis_end": crisis_last_end, "scn": scn, "era": Eras.current, "nuke_cd": nuke_cd, "grand": grand, "chokes": chokes, "daily": daily, "pol": pol, "wroom": wroom, "indep": indep, "infamy": infamy, "un_cd": un_cd, "un_log": un_log, "aid": aid,
	}
	var ps: Array = []
	for p in provinces:
		ps.append([p.owner, p.controller, p.siege, p.siege_by, p.dev, p.is_capital, p.core, p.unrest, p.acquired, p.pop, p.defense, p.gdp])
	d["provinces"] = ps
	var cs: Array = []
	for c in countries:
		cs.append({
			"name": c.name, "color": c.color.to_html(), "color2": c.color2.to_html(), "color3": c.color3.to_html(),
			"pattern": c.flag_pattern, "capital": c.capital, "gold": c.gold, "alive": c.alive,
			"aggr": c.aggression, "enemies": c.enemies, "truce": c.truce, "allies": c.allies,
			"rebel": c.is_rebel, "born": c.born, "leader": c.leader, "sanc": c.sanction_until, "macro": Macro.to_dict(c), "pop": c.pop, "gdp": c.gdp,
			"name_en": c.name_en, "a3": c.a3, "cont": c.continent, "tech": c.tech_set,
		})
	d["countries"] = cs
	var arms: Array = []
	for a in armies.values():
		arms.append([a.id, a.owner, a.prov, a.size, a.path, a.prev_prov, a.op, a.sp_size, a.sp_path, a.sp_op, a.merc, a.merc_until, a.hold, a.sp_hold, a.cmd_lvl, a.cmd_name, a.cmd_wins, a.leaving])
	d["armies"] = arms
	var ws: Array = []
	for w in wars:
		ws.append([w.a, w.b, w.score_a, w.score_b, w.start])
	d["wars"] = ws
	d["news"] = news_log.slice(maxi(0, news_log.size() - 80))
	return d


func from_dict(d: Dictionary) -> bool:
	var ver: int = d.get("v", 0)
	if ver != 2 and ver != 3:
		return false
	seed_value = d.seed
	difficulty = int(d.get("difficulty", 1))
	var era_id: String = d.get("era", "")
	if era_id != "":
		Eras.prepare(era_id)
	else:
		Eras.clear()
	world = WorldData.instance()
	world.populate(self)
	base_country_count = d.base
	var ps: Array = d.provinces
	if ps.size() != provinces.size():
		return false
	for i in ps.size():
		var r: Array = ps[i]
		var p = provinces[i]
		p.owner = r[0]
		p.controller = r[1]
		p.siege = r[2]
		p.siege_by = r[3]
		p.dev = r[4]
		p.is_capital = r[5]
		p.core = r[6]
		p.unrest = r[7]
		p.acquired = r[8]
		p.pop = r[9]
		p.defense = r[10]
		if r.size() > 11:
			p.gdp = r[11]
	var cs: Array = d.countries
	while countries.size() < cs.size():
		var nc := Model.Country.new()
		nc.id = countries.size()
		countries.append(nc)
	for i in cs.size():
		var r: Dictionary = cs[i]
		var c = countries[i]
		if i >= base_country_count or Eras.current != "":
			c.name = r.name
			c.color = Color(r.color)
			c.color2 = Color(r.color2)
			c.color3 = Color(r.color3)
			c.flag_pattern = r.pattern
		c.capital = r.capital
		c.gold = r.gold
		c.alive = r.alive
		c.aggression = r.aggr
		c.enemies = r.enemies.duplicate()
		c.truce = r.truce.duplicate()
		c.allies = r.allies.duplicate()
		c.is_rebel = r.rebel
		c.born = r.born
		c.sanction_until = int(r.get("sanc", -1))
		if r.has("leader"):
			c.leader = String(r["leader"])
		elif era_id != "":
			c.leader = Eras.leader_at(era_id, c.name_en, int(d.get("turn", 0)))
		if i >= base_country_count:
			c.name_en = str(r.get("name_en", c.name_en))
			c.a3 = str(r.get("a3", c.a3))
			c.continent = str(r.get("cont", c.continent))
			c.tech_set = float(r.get("tech", c.tech_set))
		if i >= base_country_count or era_id != "":
			c.pop = r.get("pop", 0.0)
			c.gdp = r.get("gdp", 0.0)
	armies.clear()
	for r in d.armies:
		var a := Model.Army.new()
		a.id = r[0]
		a.owner = r[1]
		a.prov = r[2]
		a.size = r[3]
		a.path = r[4].duplicate()
		a.prev_prov = r[5]
		a.op = r[6] if r.size() > 6 else ""
		if r.size() > 11:
			a.sp_size = r[7]
			a.sp_path = r[8].duplicate()
			a.sp_op = r[9]
			a.merc = r[10]
			a.merc_until = r[11]
		if r.size() > 13:
			a.hold = bool(r[12])
			a.sp_hold = bool(r[13])
		if r.size() > 16:
			a.cmd_lvl = int(r[14])
			a.cmd_name = str(r[15])
			a.cmd_wins = int(r[16])
		if r.size() > 17:
			a.leaving = bool(r[17])
		armies[a.prov] = a
	wars.clear()
	for r in d.wars:
		var w := Model.War.new()
		w.a = r[0]
		w.b = r[1]
		w.score_a = r[2]
		w.score_b = r[3]
		w.start = r[4]
		wars.append(w)
	blocs = d.get("blocs", []).duplicate(true)
	next_bloc_id = d.get("next_bloc", 0)
	cold = d.get("cold", []).duplicate(true)
	sea_campaign = {}
	for k in d.get("sea_camp", []):
		sea_campaign[int(k)] = true
	crisis = d.get("crisis", {}).duplicate(true)
	crisis_last_end = int(d.get("crisis_end", -999))
	scn = d.get("scn", {}).duplicate(true)
	crisis_pending = {}
	nuke_cd = int(d.get("nuke_cd", 0))
	grand = d.get("grand", {}).duplicate(true)
	chokes = d.get("chokes", {}).duplicate(true)
	daily = d.get("daily", {}).duplicate(true)
	pol = d.get("pol", {}).duplicate(true)
	wroom = d.get("wroom", {}).duplicate(true)
	Chokepoints.ensure(self)
	Chokepoints.tick(self)
	indep = d.get("indep", {}).duplicate(true)
	infamy = float(d.get("infamy", 0.0))
	un_cd = d.get("un_cd", {}).duplicate()
	aid = d.get("aid", {"cd": {}, "good": {}}).duplicate(true)
	un_log = d.get("un_log", []).duplicate(true)
	turn = d.turn
	Macro.build_idx(self)
	refresh_stats()
	for i in cs.size():
		var rm: Dictionary = cs[i]
		var cm = countries[i]
		if ver >= 3 and rm.has("macro"):
			Macro.from_dict(cm, rm["macro"])
		else:
			cm.inv = {}
			cm.base_troops = 0
			Macro.init_country(self, cm)
	if ver < 3:
		var sums: Dictionary = {}
		for a2 in armies.values():
			sums[a2.owner] = int(sums.get(a2.owner, 0)) + a2.size
		for a3 in armies.values():
			var tot: int = sums[a3.owner]
			a3.size = maxi(500, int(float(a3.size) / maxf(tot, 1.0) * countries[a3.owner].base_troops))
	player = d.player
	next_army_id = d.next_army_id
	victory_declared = d.victory
	rebel_name_count = d.rebel_names.duplicate()
	merc_names = d.get("merc_names", {}).duplicate()
	for k in d.stats:
		stats[k] = d.stats[k]
	news_log = d.news.duplicate(true)
	rng.state = d.rng_state
	pending_proposal = false
	game_started = true
	if player >= 0:
		countries[player].is_player = true
	refresh_stats()
	Macro.prime(self)
	return true


func save_to(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(to_dict())
	f.close()
	return true


func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var d = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	return from_dict(d)
