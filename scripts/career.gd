extends RefCounted
## HİKÂYE MODU (kariyer): bir hükümdara bağlı komutan olarak başla; tımar, maiyet ordusu, itibar ve sadakat.
## Görevler, divan, rakip beyler, başka hükümdara yemin, isyan, devlet kurma ya da tahta çıkma.
## Durum gs.career içinde (kayda girer). Oyuncu teknik olarak ayrı bir "vasal devlet"tir (create_faction);
## hükümdarla kalıcı ateşkes ve haraç ilişkisi vardır.

const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Eras = preload("res://scripts/eras.gd")
const NameGen = preload("res://scripts/name_gen.gd")

# ------------------------------------------------------------ sabitler
const RANKS := {
	"pre": ["Sipahi", "Subaşı", "Sancakbeyi", "Beylerbeyi", "Vezir"],
	"ww1": ["Binbaşı", "Yarbay", "Albay", "Tuğgeneral", "Mareşal"],
	"ww2": ["Binbaşı", "Yarbay", "Albay", "Tuğgeneral", "Mareşal"],
	"cold": ["Kaymakam", "Vali", "Bölge Valisi", "Genel Vali", "Naip"],
	"": ["Kaymakam", "Vali", "Bölge Valisi", "Genel Vali", "Naip"],
}
const RANK_RENOWN := [0, 20, 40, 65, 90]                # rütbe için gereken itibar
const SOV_TITLE := {"pre": "Hükümdar", "ww1": "Hükümdar", "ww2": "Devlet Başkanı", "cold": "Devlet Başkanı", "": "Devlet Başkanı"}
const CHAPTERS := [
	["Bölüm 1: Tımar", "Sana bir tımar bahşedildi. Köylüler seni tanımıyor, askerler seni sınıyor. Önce adını duyur."],
	["Bölüm 2: Sancak", "Adın sarayda anılıyor. Hükümdar sana görevler vermeye başladı; her görev bir sınav."],
	["Bölüm 3: Beylerbeyi", "Artık bir ordu komutanısın. Rakip beyler seni kıskanıyor; sarayda dostların kadar düşmanın da var."],
	["Bölüm 4: Divan", "Hükümdarın sağ koluna yükseldin. İstersen sadık kal, istersen kendi yolunu çiz: yemin, isyan ya da devlet."],
	["Bölüm 5: Taht", "Senin adın artık bir hanedan adı. Tarih seni ya kurucu ya da hain olarak yazacak."],
]
const BACKGROUNDS := [
	{"id": "cavalry", "t": "Süvari Beyi", "d": "Atlı bir aileden geliyorsun: daha büyük maiyet, daha az para.", "troops": 1.5, "gold": 0.7, "renown": 8, "loyalty": 55},
	{"id": "court", "t": "Saray Ehli", "d": "Sarayda büyüdün: hükümdarın gözünde yerin var, ordun küçük.", "troops": 0.7, "gold": 1.2, "favor": 25, "renown": 4, "loyalty": 70},
	{"id": "merchant", "t": "Tüccar Oğlu", "d": "Para senin dilin: dolu hazine, az itibar.", "troops": 0.8, "gold": 2.0, "renown": 0, "loyalty": 50},
	{"id": "rebel", "t": "Dağların Oğlu", "d": "Eski bir eşkıya reisi affedildi: sadakatin şüpheli, askerlerin sert.", "troops": 1.3, "gold": 0.8, "renown": 10, "loyalty": 30, "att": 0.1},
	{"id": "prince", "t": "Hanedan Üyesi", "d": "Hükümdarın akrabasısın: yüksek itibar, ama her hamlen izleniyor.", "troops": 1.0, "gold": 1.0, "favor": 15, "renown": 15, "loyalty": 60, "watch": true},
]
const MISSION_CD := 6
const CARD_CD := 4
const TRIBUTE_RATE := 0.18                              # gelirin haracı

# ------------------------------------------------------------ yardımcılar
static func _tr() -> bool:
	return Loc.lang == "tr"


static func active(gs) -> bool:
	return gs.career is Dictionary and bool(gs.career.get("on", false))


static func fam() -> String:
	return Eras.family()


static func rank_name(r: int) -> String:
	var lst: Array = RANKS.get(fam(), RANKS[""])
	return Loc.t(String(lst[clampi(r, 0, lst.size() - 1)]))


static func sov(gs):
	var h: int = int(gs.career.get("host", -1))
	return gs.countries[h] if h >= 0 and h < gs.countries.size() else null


static func sov_name(gs) -> String:
	var s = sov(gs)
	if s == null:
		return "?"
	var ld: Array = Macro.leader_of(s)
	return ("%s %s" % [ld[0], ld[1]]).strip_edges() if ld[1] != "" else s.name


static func me(gs):
	return gs.countries[gs.player]


static func state(gs) -> String:
	return String(gs.career.get("state", "vassal"))       # vassal | rebel | independent | sovereign


# ------------------------------------------------------------ kurulum
## params: era (hazır), host_en, pid (tımar), name, bg (arka plan id), gender
static func begin(gs, params: Dictionary) -> bool:
	var host_en: String = String(params.get("host_en", ""))
	var host: int = int(gs.macro_idx.get(host_en, -1))
	if host < 0:
		return false
	var hc = gs.countries[host]
	var pid: int = int(params.get("pid", -1))
	if pid < 0 or pid >= gs.provinces.size() or gs.provinces[pid].owner != host or pid == hc.capital:
		pid = pick_fiefs(gs, host)[0] if not pick_fiefs(gs, host).is_empty() else -1
	if pid < 0:
		return false
	var bg: Dictionary = BACKGROUNDS[0]
	for b in BACKGROUNDS:
		if b.id == String(params.get("bg", "cavalry")):
			bg = b
	var pname: String = String(params.get("name", "")).strip_edges().substr(0, 24)
	if pname == "":
		pname = NameGen.person(NameGen.culture_of(hc), "career|%d" % gs.rng.randi(), bool(params.get("female", false)))
	var host_troops: float = float(maxi(hc.troops, 30000))
	var troops: int = clampi(int(host_troops * 0.025 * float(bg.get("troops", 1.0))), 2500, 16000)
	var fname: String = _fief_name(gs, pname, pid)
	var spec := {"name": fname, "from": [[host_en, 1]], "pids": [pid], "troops": troops, "tech": clampf(hc.tech_set * 0.9, 0.2, 1.0), "defect": false,
		"leader": "%s|%s" % [rank_name(0), pname], "colors": [hc.color.lightened(0.18).to_html(false), hc.color2.to_html(false), hc.color3.to_html(false)],
		"pattern": int(gs.rng.randi() % 6), "aggression": 0.35, "doctrine": hc.doctrine}
	var fid: int = gs.create_faction(spec)
	if fid < 0:
		return false
	var f = gs.countries[fid]
	# vasal: savaş yok, kalıcı ateşkes, hükümdarın bloğunda
	var w = gs.get_war(fid, host)
	if w != null:
		gs.finish_peace(w, -1, [])
	f.truce[host] = gs.turn + 9999
	hc.truce[fid] = gs.turn + 9999
	gs.relation_add(fid, host, 30.0)
	f.bloc = hc.bloc
	f.inv = {}
	for k in hc.inv.keys():
		f.inv[k] = maxi(1, int(hc.inv[k] * 0.04))
	gs.countries[host].is_player = false
	gs.player = fid
	f.is_player = true
	f.gold = f.income * 6.0 * float(bg.get("gold", 1.0))
	gs.provinces[pid].defense = maxi(int(gs.provinces[pid].defense), 2)
	gs.career = {"on": true, "host": host, "host_en": host_en, "name": pname, "female": bool(params.get("female", false)), "bg": String(bg.id),
		"state": "vassal", "rank": 0, "renown": float(bg.get("renown", 0)), "favor": float(bg.get("favor", 10)), "loyalty": float(bg.get("loyalty", 50)),
		"tribute": true, "mission": {}, "next_mission": gs.turn + 4, "next_card": gs.turn + 3, "pending": {}, "rivals": _make_rivals(gs, hc),
		"chapter": 0, "log": [], "oaths": 0, "wars_won": 0, "battles": 0, "flags": {}, "start_turn": gs.turn, "won": false, "cd": {}, "fief0": pid,
		"watch": bool(bg.get("watch", false)), "att": float(bg.get("att", 0.0)), "weeks_indep": 0, "retinue": troops}
	gs.scn = {"id": "career", "start": gs.turn, "done": {}, "fired": {}, "streak": {}, "cap": {}, "over": false}
	_log(gs, "%s, %s tımarına atandı." % [pname, gs.provinces[pid].name])
	gs.post_news(Loc.t("%s: %s hizmetine girdi; %s tımarı ona bahşedildi.") % [pname, hc.name, gs.provinces[pid].name], pid, "war_player")
	return true


static func _fief_name(gs, pname: String, pid: int) -> String:
	var pn: String = gs.provinces[pid].name
	match fam():
		"pre":
			return "%s Sancağı" % pn
		"ww1", "ww2":
			return "%s Kolordusu" % pn
	return "%s Valiliği" % pn


## Tımar adayları: hükümdarın başkent olmayan, sınır/kıyı eyaletleri (nüfusa göre orta boy), en çok 8
static func pick_fiefs(gs, host: int) -> Array:
	var hc = gs.countries[host]
	var cand: Array = []
	var cp: Vector2 = gs.provinces[hc.capital].label_pos if hc.capital >= 0 else Vector2.ZERO
	var pops: Array = []
	for pid0 in hc.owned_ids:
		pops.append(gs.provinces[pid0].pop)
	pops.sort()
	var big: float = pops[int(pops.size() * 0.9)] if pops.size() > 3 else 1e9     # en kalabalık %10: büyük şehir, tımar olmaz
	for pid in hc.owned_ids:
		if pid == hc.capital or gs.provinces[pid].controller != host or gs.provinces[pid].pop > big:
			continue
		var border := false
		for nb in gs.provinces[pid].neighbors:
			if gs.provinces[nb].owner != host and gs.provinces[nb].owner >= 0:
				border = true
				break
		var dist: float = gs.provinces[pid].label_pos.distance_to(cp)
		cand.append([pid, sqrt(maxf(gs.provinces[pid].pop, 0.01)) * (1.5 if border else 1.0) / (1.0 + dist / 350.0)])
	cand.sort_custom(func(a, b): return a[1] > b[1])
	var out: Array = []
	for c in cand:
		out.append(int(c[0]))
		if out.size() >= 8:
			break
	return out


static func _make_rivals(gs, hc) -> Array:
	var out: Array = []
	for i in 3:
		var key := "rival|%s|%d" % [hc.name_en, i]
		out.append({"n": NameGen.person(NameGen.culture_of(hc), key, false), "renown": 15.0 + i * 12.0, "favor": 20.0 + i * 10.0, "hostile": i == 0, "alive": true})
	return out


static func _log(gs, t: String) -> void:
	var l: Array = gs.career.get("log", [])
	l.append([gs.turn, t])
	if l.size() > 40:
		l.pop_front()
	gs.career["log"] = l


# ------------------------------------------------------------ ölçüler
static func add(gs, key: String, d: float) -> void:
	var v: float = float(gs.career.get(key, 0.0)) + d
	gs.career[key] = clampf(v, 0.0, 100.0) if key in ["renown", "favor", "loyalty"] else v
	if key == "renown":
		_check_rank(gs)


static func _check_rank(gs) -> void:
	var r: int = int(gs.career.rank)
	var rn: float = float(gs.career.renown)
	while r < 4 and rn >= RANK_RENOWN[r + 1] and float(gs.career.favor) >= 20.0 + r * 10.0:
		r += 1
		gs.career.rank = r
		var mc = me(gs)
		mc.leader = "%s|%s" % [rank_name(r), String(gs.career.name)]
		_log(gs, "Rütbe: %s" % rank_name(r))
		gs.post_news(Loc.t("%s %s rütbesine yükseltildi.") % [String(gs.career.name), rank_name(r)], -1, "info", "medal")
		if r > int(gs.career.chapter):
			gs.career.chapter = r
			gs.career["pending"] = {"kind": "chapter", "idx": r}
			gs.career_card.emit()


# ------------------------------------------------------------ görevler
const MISSIONS := [
	{"id": "siege", "t": "Kuşatma", "d": "%s eyaletini düşmandan al.", "scene": "pre_siege", "weeks": 20, "renown": 14, "favor": 12, "gold_w": 4.0, "needs_war": true},
	{"id": "hold", "t": "Sınır nöbeti", "d": "%s eyaletini %d hafta boyunca elinde tut.", "scene": "pre_border", "weeks": 12, "renown": 6, "favor": 8, "gold_w": 2.0},
	{"id": "tribute", "t": "Haraç", "d": "%d hafta içinde hazineye %s gönder.", "scene": "pre_tribute", "weeks": 8, "renown": 3, "favor": 10, "gold_w": 0.0},
	{"id": "rebels", "t": "İsyan bastır", "d": "%s yakınındaki isyancıları ez.", "scene": "pre_assault", "weeks": 16, "renown": 10, "favor": 10, "gold_w": 3.0},
	{"id": "muster", "t": "Asker topla", "d": "Maiyetini %s askere çıkar.", "scene": "pre_camp", "weeks": 14, "renown": 5, "favor": 6, "gold_w": 1.5},
]


static func mission_text(gs) -> String:
	var m: Dictionary = gs.career.get("mission", {})
	if m.is_empty():
		return ""
	return String(m.get("text", ""))


static func _new_mission(gs) -> void:
	var hc = sov(gs)
	var mc = me(gs)
	if hc == null or not hc.alive:
		return
	var pool: Array = []
	for m in MISSIONS:
		if bool(m.get("needs_war", false)) and hc.enemies.is_empty():
			continue
		pool.append(m)
	var m: Dictionary = pool[gs.rng.randi() % pool.size()]
	var mis := {"id": m.id, "t": m.t, "scene": m.scene, "until": gs.turn + int(m.weeks), "renown": m.renown, "favor": m.favor, "gold_w": m.gold_w, "target": -1, "amount": 0}
	match String(m.id):
		"siege":
			var best := -1
			var bd := 1e9
			for en in hc.enemies:
				for pid in gs.countries[en].owned_ids:
					var d: float = gs.provinces[pid].label_pos.distance_to(gs.provinces[mc.capital].label_pos)
					if d < bd and gs.provinces[pid].controller == en:
						bd = d
						best = pid
			if best < 0:
				return
			mis.target = best
			mis.text = Loc.t(m.d) % gs.provinces[best].name
		"hold":
			mis.target = mc.capital
			mis.text = Loc.t(m.d) % [gs.provinces[mc.capital].name, int(m.weeks)]
		"tribute":
			mis.amount = int(mc.income * 5.0)
			mis.text = Loc.t(m.d) % [int(m.weeks), Macro.money(float(mis.amount))]
		"rebels":
			# tımara yakın bir host eyaletinde isyancı grup doğar
			var tgt: int = -1
			var bd2 := 1e9
			for pid in hc.owned_ids:
				if pid == hc.capital:
					continue
				var d2: float = gs.provinces[pid].label_pos.distance_to(gs.provinces[mc.capital].label_pos)
				if d2 < bd2:
					bd2 = d2
					tgt = pid
			if tgt < 0:
				return
			mis.target = tgt
			mis.text = Loc.t(m.d) % gs.provinces[tgt].name
			gs.provinces[tgt].unrest = maxf(gs.provinces[tgt].unrest, 80.0)
			gs.career.flags["rebel_pid"] = tgt
		"muster":
			mis.amount = int(mc.troops * 1.35)
			mis.text = Loc.t(m.d) % Macro.num(mis.amount)
	gs.career.mission = mis
	gs.career["pending"] = {"kind": "mission", "m": mis}
	gs.career_card.emit()


static func _mission_tick(gs) -> void:
	var m: Dictionary = gs.career.get("mission", {})
	var mc = me(gs)
	if m.is_empty():
		if gs.turn >= int(gs.career.next_mission) and state(gs) == "vassal":
			_new_mission(gs)
		return
	var done := false
	match String(m.id):
		"siege":
			done = gs.provinces[int(m.target)].controller == mc.id or gs.provinces[int(m.target)].owner == mc.id
		"hold":
			done = gs.turn >= int(m.until) and gs.provinces[int(m.target)].controller == mc.id
			if gs.provinces[int(m.target)].controller != mc.id:
				_mission_fail(gs, m)
				return
		"tribute":
			done = bool(m.get("paid", false))
		"rebels":
			var tp: int = int(m.target)
			done = gs.provinces[tp].unrest < 30.0 and gs.provinces[tp].controller == gs.provinces[tp].owner and gs.turn > int(m.get("since", gs.turn)) + 2
			m["since"] = m.get("since", gs.turn)
		"muster":
			done = mc.troops >= int(m.amount)
	if done:
		_mission_done(gs, m)
	elif gs.turn >= int(m.until):
		_mission_fail(gs, m)


static func _mission_done(gs, m: Dictionary) -> void:
	add(gs, "renown", float(m.renown))
	add(gs, "favor", float(m.favor))
	add(gs, "loyalty", 4.0)
	var mc = me(gs)
	mc.gold += mc.income * float(m.gold_w)
	gs.career.mission = {}
	gs.career.next_mission = gs.turn + MISSION_CD
	_log(gs, "Görev tamamlandı: %s" % String(m.t))
	gs.career["pending"] = {"kind": "mission_done", "m": m}
	gs.career_card.emit()
	# ödül: bazen yeni tımar
	if gs.rng.randf() < 0.35 + float(gs.career.favor) / 300.0:
		grant_fief(gs, "Hükümdar hizmetinin karşılığında %s tımarını da sana bahşetti.")


static func _mission_fail(gs, m: Dictionary) -> void:
	add(gs, "favor", -12.0)
	add(gs, "loyalty", -4.0)
	gs.career.mission = {}
	gs.career.next_mission = gs.turn + MISSION_CD + 4
	_log(gs, "Görev başarısız: %s" % String(m.t))
	gs.post_news(Loc.t("Görev başarısız: %s. Sarayda itibarın sarsıldı.") % String(m.t), -1, "war_player")


## Hükümdar, tımara komşu kendi eyaletlerinden birini oyuncuya verir
static func grant_fief(gs, msg: String) -> bool:
	var hc = sov(gs)
	var mc = me(gs)
	if hc == null or not hc.alive:
		return false
	var cand: Array = []
	for pid in mc.owned_ids:
		for nb in gs.provinces[pid].neighbors:
			if gs.provinces[nb].owner == hc.id and nb != hc.capital and not cand.has(nb):
				cand.append(nb)
	if cand.is_empty():
		return false
	var pid2: int = cand[gs.rng.randi() % cand.size()]
	_transfer(gs, pid2, mc.id)
	_log(gs, "Yeni tımar: %s" % gs.provinces[pid2].name)
	gs.post_news(Loc.t(msg) % gs.provinces[pid2].name, pid2, "war_player", "castle")
	return true


static func _transfer(gs, pid: int, to: int) -> void:
	var p = gs.provinces[pid]
	var old: int = p.owner
	p.owner = to
	p.controller = to
	p.core = to
	p.siege = 0
	p.unrest = 0
	p.is_capital = false
	p.acquired = gs.turn
	gs.province_changed.emit(pid)
	if old >= 0:
		gs._fix_capital(old)
	gs.refresh_stats()
	Macro.build_idx(gs)


# ------------------------------------------------------------ divan eylemleri
static func cd_left(gs, id: String) -> int:
	return maxi(0, int(gs.career.cd.get(id, -999)) - gs.turn)


static func actions(gs) -> Array:
	var mc = me(gs)
	var st := state(gs)
	var out: Array = []
	var inc: float = maxf(mc.income, 1.0)
	if st == "vassal":
		out.append({"id": "gift", "t": "Hediye gönder", "d": "Hazineden %s: hükümdarın gözünde yüksel." % Macro.money(inc * 3.0), "icon": "st_caravan", "scene": "pre_tribute", "cd": cd_left(gs, "gift"), "ok": mc.gold >= inc * 3.0})
		out.append({"id": "ask_fief", "t": "Tımar iste", "d": "Huzura çık, komşu bir eyalet iste (itibar ve hükümdar gözü gerekir).", "icon": "st_fort", "scene": "pre_court", "cd": cd_left(gs, "ask_fief"), "ok": float(gs.career.favor) >= 35.0 and float(gs.career.renown) >= 20.0})
		out.append({"id": "ask_gold", "t": "Hazineden yardım iste", "d": "Hükümdar gözünden harcayıp altın al.", "icon": "coins", "scene": "pre_court", "cd": cd_left(gs, "ask_gold"), "ok": float(gs.career.favor) >= 15.0})
		out.append({"id": "feast", "t": "Ziyafet ver", "d": "Beylere ziyafet: itibar artar, hazine azalır.", "icon": "st_divan", "scene": "pre_camp", "cd": cd_left(gs, "feast"), "ok": mc.gold >= inc * 2.0})
		out.append({"id": "intrigue", "t": "Entrika", "d": "Rakip bir beyi sarayda karala. Yakalanırsan bedeli ağır.", "icon": "st_spy", "scene": "pre_spy", "cd": cd_left(gs, "intrigue"), "ok": true})
		out.append({"id": "tribute_toggle", "t": ("Haracı kes" if bool(gs.career.tribute) else "Haracı yeniden öde"), "d": "Haraç gelirinin %%%d'i. Kesersen sadakat her hafta erir." % int(TRIBUTE_RATE * 100), "icon": "debt", "scene": "pre_tribute", "cd": 0, "ok": true})
		out.append({"id": "oath", "t": "Başka hükümdara yemin et", "d": "Komşu bir devlete bağlan; eski hükümdar bunu ihanet sayar.", "icon": "handshake", "scene": "pre_oath", "cd": cd_left(gs, "oath"), "ok": _oath_targets(gs).size() > 0})
		out.append({"id": "ask_indep", "t": "Devlet kurma talebi", "d": "Barışçıl ayrılık: çok yüksek itibar ve hükümdar gözü gerekir.", "icon": "st_decree", "scene": "pre_court", "cd": cd_left(gs, "ask_indep"), "ok": float(gs.career.renown) >= 70.0 and float(gs.career.favor) >= 60.0})
		out.append({"id": "rebel", "t": "İsyan bayrağı aç", "d": "Hükümdara savaş ilan et. Geri dönüş yok.", "icon": "st_rebel", "scene": "pre_rebel", "cd": 0, "ok": mc.troops >= 3000})
	elif st == "rebel":
		out.append({"id": "oath", "t": "Bir hükümdarın himayesine gir", "d": "Komşu bir devlete biat et: o seni korur, eski hükümdar barışa zorlanır.", "icon": "handshake", "scene": "pre_oath", "cd": cd_left(gs, "oath"), "ok": _oath_targets(gs).size() > 0})
		out.append({"id": "declare", "t": "Devletini ilan et", "d": "İsyanı bitir, bağımsız bir devlet ol: hükümdarla barış şartı.", "icon": "st_decree", "scene": "pre_oath", "cd": 0, "ok": sov(gs) != null and not gs.at_war(mc.id, int(gs.career.host))})
		out.append({"id": "throne", "t": "Tahta çık", "d": "Hükümdarın başkentini ele geçirdiysen tahtı sen alırsın.", "icon": "st_crown", "scene": "pre_court", "cd": 0, "ok": _holds_capital(gs)})
	elif st == "independent":
		out.append({"id": "oath", "t": "Bir hükümdara yemin et", "d": "Devletini bir büyük gücün himayesine ver.", "icon": "handshake", "scene": "pre_oath", "cd": cd_left(gs, "oath"), "ok": _oath_targets(gs).size() > 0})
	# tımar siyaseti ve maiyet: her aşamada
	var pol: String = String(gs.career.get("policy", "balanced"))
	out.append({"id": "policy", "t": Loc.t("Tımar siyaseti: %s") % Loc.t(POLICY_NAME[pol]), "d": POLICY_DESC[pol], "icon": "st_divan", "scene": "pre_court", "cd": cd_left(gs, "policy"), "ok": true})
	var comps: Array = gs.career.get("companions", [])
	if comps.size() < 4:
		for role in COMP_ROLES:
			if _has_comp(gs, role):
				continue
			out.append({"id": "hire_" + role, "t": Loc.t("Maiyete al: %s") % Loc.t(COMP_NAME[role]), "d": Loc.t("%s  (bedel: %s)") % [Loc.t(COMP_DESC[role]), Macro.money(inc * 3.0)], "icon": COMP_ICON[role], "scene": "pre_camp", "cd": 0, "ok": mc.gold >= inc * 3.0})
	return out


const POLICY_ORDER := ["balanced", "tax", "army", "dev"]
const POLICY_NAME := {"balanced": "Dengeli", "tax": "Vergi", "army": "Asker", "dev": "Kalkınma"}
const POLICY_DESC := {
	"balanced": "Ne ağır vergi ne zorlama: düzen korunur.",
	"tax": "Hazineye haftalık %25 ek gelir; halk huzursuzlaşır (istikrar düşer).",
	"army": "Maiyet tabanı %30 büyür ve savaşta daha sert vurur; hazine haftada %15 eksilir.",
	"dev": "Hazine haftada %20 eksilir; istikrar yükselir, tımar zamanla gelişir.",
}
const COMP_ROLES := ["komutan", "katip", "casus", "hekim"]
const COMP_NAME := {"komutan": "Komutan", "katip": "Kâtip", "casus": "Casus", "hekim": "Hekim"}
const COMP_ICON := {"komutan": "st_standard", "katip": "st_scribe", "casus": "st_spy", "hekim": "st_hekim"}
const COMP_DESC := {
	"komutan": "Savaşta ordun %5 daha güçlü vurur, maiyet büyür.",
	"katip": "Hazineye haftalık %4 ek gelir.",
	"casus": "Hükümdar gözü yavaşça yükselir; entrikalarda yakalanma riski azalır.",
	"hekim": "İstikrar yavaşça yükselir.",
}


static func _has_comp(gs, role: String) -> bool:
	for c in gs.career.get("companions", []):
		if String(c.role) == role:
			return true
	return false


static func comp_count(gs, role: String) -> int:
	return 1 if _has_comp(gs, role) else 0


static func _holds_capital(gs) -> bool:
	var hc = sov(gs)
	return hc != null and hc.capital >= 0 and gs.provinces[hc.capital].controller == gs.player


static func _oath_targets(gs) -> Array:
	var mc = me(gs)
	var out: Array = []
	for nb in gs.neighbor_countries(mc.id):
		var c = gs.countries[nb]
		if nb == int(gs.career.host) or not c.alive or c.is_rebel or c.name_en.begins_with("faction_"):
			continue
		if gs.at_war(mc.id, nb):
			continue
		out.append(nb)
	return out


static func oath_targets(gs) -> Array:
	return _oath_targets(gs)


static func do_action(gs, id: String, arg: int = -1) -> String:
	var mc = me(gs)
	var inc: float = maxf(mc.income, 1.0)
	var hc = sov(gs)
	match id:
		"gift":
			if mc.gold < inc * 3.0:
				return Loc.t("Hazine yetersiz.")
			mc.gold -= inc * 3.0
			add(gs, "favor", 12.0)
			add(gs, "loyalty", 3.0)
			gs.career.cd["gift"] = gs.turn + 6
			_log(gs, "Hükümdara hediye gönderildi.")
			return ""
		"ask_fief":
			gs.career.cd["ask_fief"] = gs.turn + 16
			var ok: bool = gs.rng.randf() < 0.35 + float(gs.career.favor) / 160.0
			add(gs, "favor", -10.0)
			if ok and grant_fief(gs, "Huzura çıktın; hükümdar %s tımarını sana bahşetti."):
				return ""
			return Loc.t("Hükümdar talebini geri çevirdi: 'Önce kendini göster.'")
		"ask_gold":
			gs.career.cd["ask_gold"] = gs.turn + 10
			add(gs, "favor", -8.0)
			mc.gold += inc * 4.0
			_log(gs, "Hazineden yardım alındı.")
			return ""
		"feast":
			if mc.gold < inc * 2.0:
				return Loc.t("Hazine yetersiz.")
			mc.gold -= inc * 2.0
			add(gs, "renown", 6.0)
			gs.career.cd["feast"] = gs.turn + 8
			for r in gs.career.rivals:
				r.favor = maxf(0.0, float(r.favor) - 3.0)
			_log(gs, "Beylere ziyafet verildi.")
			return ""
		"intrigue":
			gs.career.cd["intrigue"] = gs.turn + 8
			var rv: Array = gs.career.rivals.filter(func(r): return bool(r.alive))
			if rv.is_empty():
				return Loc.t("Karalanacak rakip kalmadı.")
			var r2: Dictionary = rv[gs.rng.randi() % rv.size()]
			if gs.rng.randf() < 0.6:
				r2.favor = maxf(0.0, float(r2.favor) - 15.0)
				r2.renown = maxf(0.0, float(r2.renown) - 6.0)
				add(gs, "favor", 4.0)
				_log(gs, "%s sarayda gözden düştü." % String(r2.n))
				return ""
			add(gs, "favor", -15.0)
			add(gs, "loyalty", -6.0)
			_log(gs, "Entrika açığa çıktı.")
			return Loc.t("Entrikan açığa çıktı: hükümdar sana güvenmiyor.")
		"tribute_toggle":
			gs.career.tribute = not bool(gs.career.tribute)
			return ""
		"oath":
			return swear_oath(gs, arg)
		"ask_indep":
			gs.career.cd["ask_indep"] = gs.turn + 26
			var ok2: bool = gs.rng.randf() < 0.25 + float(gs.career.favor) / 200.0 + float(gs.career.renown) / 300.0
			if ok2:
				_become_independent(gs, true)
				return ""
			add(gs, "favor", -25.0)
			add(gs, "loyalty", -10.0)
			if gs.career.watch:
				gs.career.flags["suspect"] = true
			return Loc.t("Hükümdar öfkelendi: 'Benim ekmeğimi yiyip kendi sofranı mı kuracaksın?'")
		"rebel":
			start_rebellion(gs)
			return ""
		"declare":
			_become_independent(gs, false)
			return ""
		"throne":
			if not _holds_capital(gs):
				return Loc.t("Başkent elinde değil.")
			take_throne(gs)
			return ""
		"policy":
			var cur: int = POLICY_ORDER.find(String(gs.career.get("policy", "balanced")))
			var nxt: String = POLICY_ORDER[(cur + 1) % POLICY_ORDER.size()]
			gs.career["policy"] = nxt
			gs.career.cd["policy"] = gs.turn + 4
			_log(gs, "Tımar siyaseti: %s." % POLICY_NAME[nxt])
			return ""
	if id.begins_with("hire_"):
		var role: String = id.substr(5)
		if not COMP_ROLES.has(role) or _has_comp(gs, role):
			return Loc.t("Bilinmeyen eylem.")
		if mc.gold < inc * 3.0:
			return Loc.t("Hazine yetersiz.")
		mc.gold -= inc * 3.0
		var cname: String = NameGen.person(NameGen.culture_of(gs.countries[int(gs.career.host)]), "comp|%s|%d" % [role, gs.rng.randi()], false)
		var lst: Array = gs.career.get("companions", [])
		lst.append({"role": role, "name": cname, "week": gs.turn})
		gs.career["companions"] = lst
		_log(gs, "%s maiyete katıldı: %s." % [COMP_NAME[role], cname])
		return ""
	return Loc.t("Bilinmeyen eylem.")


# ------------------------------------------------------------ yemin / isyan / devlet / taht
static func swear_oath(gs, target: int) -> String:
	var mc = me(gs)
	if target < 0 or target >= gs.countries.size():
		return Loc.t("Hedef seç.")
	var old: int = int(gs.career.host)
	var nc = gs.countries[target]
	if state(gs) == "vassal" and old >= 0:
		var oc = gs.countries[old]
		oc.truce.erase(mc.id)
		mc.truce.erase(old)
		gs.relation_add(mc.id, old, -60.0)
		gs.declare_war(old, mc.id)
		_log(gs, "%s hizmetinden ayrıldın; eski hükümdar savaş ilan etti." % oc.name)
	elif state(gs) == "rebel" and old >= 0:
		# yeni hamin araya girer: eski hükümdarla barış (uzun ateşkes)
		var ow = gs.get_war(mc.id, old)
		if ow != null:
			gs.finish_peace(ow, -1, [])
		mc.truce[old] = gs.turn + 78
		gs.countries[old].truce[mc.id] = gs.turn + 78
		_log(gs, "%s araya girdi: eski hükümdarla barış." % nc.name)
	gs.career.host = target
	gs.career.host_en = nc.name_en
	gs.career.state = "vassal"
	gs.career.loyalty = 40.0
	gs.career.favor = 25.0
	gs.career.oaths = int(gs.career.oaths) + 1
	gs.career.cd["oath"] = gs.turn + 40
	gs.career.mission = {}
	gs.career.next_mission = gs.turn + 6
	mc.truce[target] = gs.turn + 9999
	nc.truce[mc.id] = gs.turn + 9999
	var w = gs.get_war(mc.id, target)
	if w != null:
		gs.finish_peace(w, -1, [])
	gs.relation_add(mc.id, target, 40.0)
	mc.bloc = nc.bloc
	mc.color = nc.color.lightened(0.18)
	gs.career.rivals = _make_rivals(gs, nc)
	add(gs, "renown", 5.0)
	gs.post_news(Loc.t("%s, %s hükümdarına biat etti.") % [String(gs.career.name), nc.name], mc.capital, "war_player", "handshake")
	gs.career["pending"] = {"kind": "oath", "cid": target}
	gs.career_card.emit()
	return ""


static func start_rebellion(gs) -> void:
	var mc = me(gs)
	var host: int = int(gs.career.host)
	var hc = gs.countries[host]
	hc.truce.erase(mc.id)
	mc.truce.erase(host)
	gs.relation_add(mc.id, host, -70.0)
	gs.declare_war(mc.id, host)
	gs.career.state = "rebel"
	gs.career.mission = {}
	gs.career.loyalty = 0.0
	gs.career.favor = 0.0
	gs.career.flags["rebel_turn"] = gs.turn
	mc.aggression = 0.7
	# halk desteği: tımar halkı isyana katılır; komşu iki eyalet (huzursuzsa) seninle gelir; bir bey safına geçebilir
	var bonus: int = int(mc.troops * 0.6)
	gs.place_recruits(mc, bonus)
	var joined := 0
	for pid in mc.owned_ids.duplicate():
		for nb in gs.provinces[pid].neighbors:
			if joined < 2 and gs.provinces[nb].owner == host and nb != hc.capital and gs.provinces[nb].controller == host:
				_transfer(gs, nb, mc.id)
				gs.provinces[nb].defense = maxi(int(gs.provinces[nb].defense), 2)
				joined += 1
	for r in gs.career.rivals:
		if bool(r.alive) and not bool(r.hostile) and gs.rng.randf() < 0.35:
			gs.place_recruits(mc, int(mc.troops * 0.25))
			_log(gs, "%s maiyetiyle safına geçti." % String(r.n))
			r.alive = false
			break
	gs.refresh_stats()
	_log(gs, "İsyan bayrağı açıldı.")
	gs.post_news(Loc.t("%s isyan bayrağını açtı: %s ile savaş!") % [String(gs.career.name), hc.name], mc.capital, "war_player", "uprising_banner")
	gs.career["pending"] = {"kind": "rebel"}
	gs.career_card.emit()


static func _become_independent(gs, peaceful: bool) -> void:
	var mc = me(gs)
	var host: int = int(gs.career.host)
	var hc = gs.countries[host]
	gs.career.state = "independent"
	gs.career.mission = {}
	var nm: String = String(gs.career.get("state_name", ""))
	if nm == "":
		nm = "%s Beyliği" % String(gs.career.name) if fam() == "pre" else "%s Cumhuriyeti" % gs.provinces[mc.capital].name
	mc.name = nm
	mc.aggression = 0.45
	mc.leader = "%s|%s" % [("Bey" if fam() == "pre" else "Devlet Başkanı"), String(gs.career.name)]
	if peaceful:
		mc.truce[host] = gs.turn + 104
		hc.truce[mc.id] = gs.turn + 104
		gs.relation_add(mc.id, host, 20.0)
		if not gs.is_allied(mc.id, host):
			gs.make_alliance(mc.id, host)
	else:
		mc.truce[host] = gs.turn + 52
		hc.truce[mc.id] = gs.turn + 52
	add(gs, "renown", 20.0)
	_log(gs, "Devlet ilan edildi: %s" % nm)
	gs.post_news(Loc.t("%s kuruldu: %s artık bağımsız bir hükümdar.") % [nm, String(gs.career.name)], mc.capital, "war_player", "founding_scroll")
	gs.career["pending"] = {"kind": "independent", "peaceful": peaceful}
	gs.career_card.emit()


## Hükümdarın başkenti elindeyken: eski devletin tamamı sana geçer (oyuncu hükümdar olur)
static func take_throne(gs) -> void:
	var mc = me(gs)
	var host: int = int(gs.career.host)
	var hc = gs.countries[host]
	var w = gs.get_war(mc.id, host)
	if w != null:
		gs.finish_peace(w, -1, [])
	for pid in hc.owned_ids.duplicate():
		_transfer(gs, pid, mc.id)
	hc.alive = false
	mc.name = hc.name
	mc.name_en = hc.name_en if not gs.macro_idx.has(hc.name_en) else mc.name_en
	mc.color = hc.color
	mc.color2 = hc.color2
	mc.color3 = hc.color3
	mc.flag_pattern = hc.flag_pattern
	mc.leader = "%s|%s" % [Macro.leader_of(hc)[0] if Macro.leader_of(hc)[0] != "" else "Hükümdar", String(gs.career.name)]
	mc.aggression = 0.5
	gs.career.state = "sovereign"
	gs.career.won = true
	gs.refresh_stats()
	Macro.build_idx(gs)
	add(gs, "renown", 30.0)
	_log(gs, "Tahta çıkıldı: %s" % mc.name)
	gs.post_news(Loc.t("%s tahta çıktı: %s artık onun.") % [String(gs.career.name), mc.name], mc.capital, "war_player", "crown")
	gs.career["pending"] = {"kind": "throne"}
	gs.career_card.emit()


# ------------------------------------------------------------ haftalık
static func tick(gs) -> void:
	if not active(gs):
		return
	var mc = me(gs)
	if not mc.alive or mc.owned_ids.is_empty():
		if not bool(gs.career.get("over", false)):
			gs.career.over = true
			gs.game_over.emit(false, Loc.t("Topraklarını kaybettin. %s'in hikâyesi burada bitti.") % String(gs.career.name))
		return
	var st := state(gs)
	var hc = sov(gs)
	_policy_tick(gs, mc)
	# maiyet: tımar halkı maiyeti tabanın altına düşürmez (rütbeyle taban büyür)
	var floor_: int = int(float(gs.career.get("retinue", 4000)) * (1.0 + 0.2 * float(gs.career.rank)) * (1.0 + 0.25 * float(mc.owned_ids.size() - 1)))
	if String(gs.career.get("policy", "balanced")) == "army":
		floor_ = int(floor_ * 1.3)
	if _has_comp(gs, "komutan"):
		floor_ = int(floor_ * 1.1)
	if mc.troops < floor_:
		gs.place_recruits(mc, mini(floor_ - mc.troops, maxi(150, int(floor_ * 0.04))))
		gs.refresh_stats()
	if st == "vassal" and hc != null:
		if not hc.alive:
			# hükümdar yıkıldı: kendiliğinden bağımsız
			_become_independent(gs, false)
			return
		# haraç
		if bool(gs.career.tribute):
			var tr_: float = mc.income * TRIBUTE_RATE
			mc.gold = maxf(0.0, mc.gold - tr_)
			hc.gold += tr_
			add(gs, "loyalty", 0.4)
			add(gs, "favor", 0.35)
		else:
			add(gs, "loyalty", -1.5)
			add(gs, "favor", -0.8)
		# sadakat/gözde sürüklenmesi; itibar kullanılmayınca yavaşça unutulur
		add(gs, "favor", -0.25)
		if gs.career.mission.is_empty():
			add(gs, "renown", -0.2)
		if float(gs.career.loyalty) < 15.0 and gs.rng.randf() < 0.08:
			gs.career["pending"] = {"kind": "summons"}
			gs.career_card.emit()
		# hükümdarın savaşına çağrı
		if not hc.enemies.is_empty() and not bool(gs.career.flags.get("called", false)):
			gs.career.flags["called"] = true
			gs.career["pending"] = {"kind": "call_to_arms"}
			gs.career_card.emit()
		if hc.enemies.is_empty():
			gs.career.flags["called"] = false
		_mission_tick(gs)
		_rival_tick(gs)
		if gs.turn >= int(gs.career.next_card):
			_draw_card(gs)
	elif st == "rebel":
		# uzayan isyan: hükümdar başka savaşlarla meşgulse barışa yanaşır
		var since: int = gs.turn - int(gs.career.flags.get("rebel_turn", gs.turn))
		if hc != null and hc.alive and since >= 20 and gs.at_war(mc.id, int(gs.career.host)):
			var pp: float = 0.04 + 0.05 * float(hc.enemies.size() - 1) + (0.08 if _holds_capital(gs) else 0.0) + 0.002 * float(since - 20)
			if gs.rng.randf() < pp:
				var w2 = gs.get_war(mc.id, int(gs.career.host))
				if w2 != null:
					gs.finish_peace(w2, -1, [])
					gs.post_news(Loc.t("%s isyancılarla barış yaptı: %s topraklarını koruyor.") % [hc.name, String(gs.career.name)], mc.capital, "war_player", "dove")
		if hc != null and not gs.at_war(mc.id, int(gs.career.host)):
			# barış yapıldı: isyan bitti, devlet kurulabilir
			gs.career["pending"] = {"kind": "rebel_peace"}
			gs.career_card.emit()
			gs.career.state = "independent_pending"
		elif hc != null and not hc.alive:
			_become_independent(gs, false)
	elif st == "independent_pending":
		pass
	elif st == "independent":
		gs.career.weeks_indep = int(gs.career.weeks_indep) + 1
		if int(gs.career.weeks_indep) >= 52 and mc.owned_ids.size() >= 6 and not bool(gs.career.won):
			gs.career.won = true
			gs.game_over.emit(true, Loc.t("%s bir yıl ayakta kaldı ve tanındı: %s bir hanedan kurdu.") % [mc.name, String(gs.career.name)])
	# itibar: savaş kazanımları
	var caps: int = int(gs.stats.get("p_captures", 0))
	var last: int = int(gs.career.flags.get("caps", caps))
	if caps > last:
		add(gs, "renown", 2.5 * (caps - last))
	gs.career.flags["caps"] = caps


static func _policy_tick(gs, mc) -> void:
	var inc: float = maxf(mc.income, 0.0)
	match String(gs.career.get("policy", "balanced")):
		"tax":
			mc.gold += inc * 0.25
			mc.stability = maxf(15.0, mc.stability - 0.35)
		"army":
			mc.gold = maxf(0.0, mc.gold - inc * 0.15)
		"dev":
			mc.gold = maxf(0.0, mc.gold - inc * 0.20)
			mc.stability = minf(100.0, mc.stability + 0.3)
			if (gs.turn - int(gs.career.get("start_turn", 0))) % 26 == 25:
				for pid in mc.owned_ids:
					var p = gs.provinces[pid]
					p.dev = mini(p.dev + 1, 5)
	if _has_comp(gs, "katip"):
		mc.gold += inc * 0.04
	if _has_comp(gs, "hekim"):
		mc.stability = minf(100.0, mc.stability + 0.12)
	if _has_comp(gs, "casus") and state(gs) == "vassal":
		add(gs, "favor", 0.12)


static func _rival_tick(gs) -> void:
	for r in gs.career.rivals:
		if not bool(r.alive):
			continue
		r.renown = clampf(float(r.renown) + gs.rng.randf_range(-0.5, 1.2), 0.0, 100.0)
		r.favor = clampf(float(r.favor) + gs.rng.randf_range(-0.8, 0.9), 0.0, 100.0)
		if bool(r.hostile) and gs.rng.randf() < 0.05:
			add(gs, "favor", -3.0)
			if gs.rng.randf() < 0.4:
				gs.career["pending"] = {"kind": "slander", "r": r.n}
				gs.career_card.emit()


# ------------------------------------------------------------ hikâye kartları
const CARDS := [
	{"id": "bandits", "t": "Eşkıya Baskını", "scene": "pre_assault", "b": "Tımarının köylerini eşkıya bastı. Köylüler senden koruma bekliyor.",
		"c": [["Peşlerine düş", {"troops": -300, "renown": 5, "stab": 2}], ["Köylülere silah dağıt", {"gold_w": -1.0, "stab": 3, "renown": 2}], ["Görmezden gel", {"stab": -4, "renown": -3}]]},
	{"id": "envoy", "t": "Komşu Beyin Elçisi", "scene": "pre_alliance", "b": "Komşu bir bey gizlice dostluk öneriyor: 'Hükümdar bizi kullanıyor, birlik olalım.'",
		"c": [["Dostluğu kabul et", {"renown": 4, "loyalty": -6, "favor": -2}], ["Nazikçe reddet", {"loyalty": 2}], ["Hükümdara ihbar et", {"favor": 12, "renown": -4, "loyalty": 6}]]},
	{"id": "harvest", "t": "Bereketli Hasat", "scene": "pre_fief", "b": "Bu yıl hasat bol. Fazlayı ne yapalım?",
		"c": [["Köylülere bırak", {"stab": 5, "renown": 2}], ["Hazineye sat", {"gold_w": 3.0}], ["Hükümdara gönder", {"favor": 8, "loyalty": 3}]]},
	{"id": "duel", "t": "Düello Daveti", "scene": "pre_camp", "b": "Rakip bir bey seni ordugâhta herkesin önünde aşağıladı. Kılıç mı, sabır mı?",
		"c": [["Düelloyu kabul et", {}, {"game": "duel", "style": [1.5, 0.8, 1.0], "power": 1.0, "title": "Düello", "intro": "Ordugâh halka oldu. Kılıçlar çekildi.",
				"win": {"renown": 12, "favor": 2}, "lose": {"renown": -4, "troops": -150, "favor": -3}, "draw": {"renown": 3}, "yield": {"renown": -8, "favor": -2},
				"win_text": "Rakibin kılıcı elinden düştü. Ordugâh senin adını sayıyor.", "lose_text": "Yere düştün. Adamların seni ordugâhtan taşıdı."}],
			["Sakin kal", {"renown": -3, "loyalty": 2}], ["Adamlarını üstüne sal", {"renown": 3, "favor": -10, "stab": -2}]]},
	{"id": "champion", "t": "Meydan Okuma", "scene": "pre_siege", "b": "Kuşatma sırasında surların önünde düşman pehlivanı çıktı ve seni teke tek dövüşe çağırıyor. Askerler bakıyor.",
		"c": [["Meydana çık", {}, {"game": "duel", "style": [1.1, 1.2, 1.1], "power": 1.1, "title": "Tek Dövüş", "intro": "Surların gölgesinde iki ordu seyrediyor.",
				"win": {"renown": 14, "stab": 3, "troops": 300}, "lose": {"troops": -400, "renown": -6, "stab": -3}, "draw": {"renown": 2}, "yield": {"renown": -10, "troops": -200},
				"win_text": "Pehlivan yere serildi. Surlardan ve saflardan ses yükseldi.", "lose_text": "Yenildin. Askerler moralini kaybetti."}],
			["Reddet", {"renown": -5, "stab": -1}], ["Okçulara işaret et", {"renown": -2, "favor": 2}]]},
	{"id": "tax", "t": "Vergi Memuru", "scene": "pre_tribute", "b": "Sarayın vergi memuru tımarından fazladan pay istiyor; rüşvet de kabul ediyor.",
		"c": [["Fazlasını öde", {"gold_w": -2.0, "favor": 4}], ["Rüşvet ver", {"gold_w": -0.6, "loyalty": -2}], ["Kapıdan kov", {"favor": -8, "renown": 3, "stab": 2}]]},
	{"id": "plague", "t": "Salgın", "scene": "pre_fief", "b": "Tımarında hastalık yayılıyor. Askerler de hasta düşüyor.",
		"c": [["Karantina", {"troops": -400, "stab": 2}], ["Hekim getirt", {"gold_w": -1.5, "troops": -100}], ["Dua et", {"troops": -900, "stab": -3}]]},
	{"id": "prisoner", "t": "Değerli Esir", "scene": "pre_siege", "b": "Askerlerin düşman bir beyi esir aldı. Fidye mi, hükümdara hediye mi?",
		"c": [["Fidye al", {"gold_w": 4.0, "renown": 1}], ["Hükümdara gönder", {"favor": 14, "loyalty": 4}], ["Serbest bırak", {"renown": 6}]]},
	{"id": "marriage", "t": "Evlilik Teklifi", "scene": "pre_court", "b": "Güçlü bir aile kızını/oğlunu seninle evlendirmek istiyor. Çeyiz büyük, bağ da büyük.",
		"c": [["Kabul et", {"gold_w": 5.0, "renown": 6, "loyalty": -3}], ["Reddet", {"renown": -2}]]},
	{"id": "deserters", "t": "Firariler", "scene": "pre_camp", "b": "Maaş gecikti; bir bölük kaçmaya hazırlanıyor.",
		"c": [["Maaşları öde", {"gold_w": -2.5}], ["İbret için cezalandır", {"troops": -200, "renown": 2, "stab": -2}], ["Bırak gitsinler", {"troops": -1200}]]},
	{"id": "spy", "t": "Sarayın Gözü", "scene": "pre_spy", "b": "Hükümdarın casusu maiyetine sızmış; bütün hamlelerin saraya gidiyor.",
		"c": [["Casusu yakalat", {"loyalty": -4, "favor": -4, "renown": 3}], ["Yanlış bilgi besle", {"favor": 3}], ["Görmezden gel", {"favor": 2, "loyalty": 2}]]},
	{"id": "hunt", "t": "Büyük Av", "scene": "pre_camp", "b": "Hükümdar av partisine seni de çağırdı. Beyler seni gözlüyor: ava çıkmak da bir sınav, çıkmamak da.",
		"c": [["Avın başına geç", {"renown": 5, "favor": 4, "gold_w": -0.8}], ["Hükümdara av payı bırak", {"favor": 8, "renown": 1}], ["Mazeret bildir", {"favor": -5, "loyalty": 2}]]},
	{"id": "caravan", "t": "Kervan Soygunu", "scene": "pre_border", "b": "Tımarından geçen ipek kervanı soyuldu. Tüccarlar korunma bekliyor; suçlu senin adamların da olabilir.",
		"c": [["Soyguncuları bul", {"troops": -150, "renown": 6, "gold_w": 2.0}], ["Zararı karşıla", {"gold_w": -2.0, "stab": 3, "renown": 2}], ["Başkasını suçla", {"renown": -4, "favor": 2, "stab": -2}]]},
	{"id": "dervish", "t": "Derviş", "scene": "pre_fief", "b": "Köyde yoksulların dilinde bir derviş: 'Yakında bir hükümdar çıkacak,' diyor. Halk seni kastettiğini fısıldıyor.",
		"c": [["Dervişi ağırla", {"renown": 7, "stab": 3, "loyalty": -4}], ["Sessizce uzaklaştır", {"favor": 4, "loyalty": 3}], ["Saraya ihbar et", {"favor": 10, "renown": -4, "stab": -2}]]},
	{"id": "hostage_prince", "t": "Rehine Şehzade", "scene": "pre_court", "b": "Komşu bir hanın oğlu rehin olarak maiyetine verildi. Onu nasıl yetiştireceksin?",
		"c": [["Dost bir şehzade yetiştir", {"renown": 4, "gold_w": -0.8, "loyalty": 2}], ["Koz olarak sakla", {"favor": 5, "renown": 1}], ["Hükümdara teslim et", {"favor": 10, "loyalty": 3, "renown": -2}]]},
	{"id": "flood", "t": "Sel", "scene": "pre_fief", "b": "Nehir taştı, köprü yıkıldı, tarlalar suyun altında. Yardım ya da fırsat?",
		"c": [["Ambarı aç", {"gold_w": -2.5, "stab": 5, "renown": 4}], ["Askerle köprüyü onar", {"troops": -200, "stab": 2, "renown": 2}], ["Vergiyi yine al", {"gold_w": 1.5, "stab": -6, "renown": -3}]]},
	{"id": "foundry", "t": "Top Döküm Ustası", "scene": "pre_siege", "b": "Yabancı bir usta, kuşatma toplarını döküp ustalarını yetiştireceğini söylüyor. Altın istiyor, ama sırlarını da saklıyor.",
		"c": [["Ustayı tut", {"gold_w": -3.0, "troops": 400, "renown": 4}], ["Sırrı rüşvetle öğren", {"gold_w": -1.5, "renown": 2, "loyalty": -2}], ["Geri çevir", {"renown": -1}]]},
	{"id": "gift_rival", "t": "Rakibin Hediyesi", "scene": "pre_alliance", "b": "Rakip bir bey sana yüzük ve kılıç yolladı. Hediye mi, tuzak mı?",
		"c": [["Kabul et ve teşekkür et", {"renown": 3, "favor": -3, "gold_w": 1.0}], ["Saraya göster", {"favor": 6, "renown": -1}], ["Geri yolla", {"renown": 2, "loyalty": 2}]]},
	{"id": "mutiny", "t": "Paralı Askerler", "scene": "pre_camp", "b": "Yabancı paralı bölüğü maaş istiyor; yoksa kılıçlarını düşmana satacaklarını söylüyor.",
		"c": [["Peşin öde", {"gold_w": -3.0, "troops": 300}], ["Ganimet vaat et", {"troops": 150, "renown": -2, "loyalty": -1}], ["Dağıt gitsinler", {"troops": -250, "stab": -1, "renown": 1}]]},
	{"id": "festival", "t": "Bayram Şenliği", "scene": "pre_court", "b": "Bayramda tımarda şenlik var. Halk yeni beyini görmek, ordu da bahşiş beklemek istiyor.",
		"c": [["Ziyafet ver", {"gold_w": -1.5, "stab": 5, "renown": 4}], ["Askerlere pay ver", {"gold_w": -1.0, "troops": 200}], ["Sade geçir", {"gold_w": 0.5, "stab": -1}]]},
	{"id": "old_wound", "t": "Eski Yara", "scene": "pre_siege", "b": "Eski bir savaş yoldaşı, geçmişteki yenilgiyi senin kabahatin diye anlatıyor. Askerler dinliyor.",
		"c": [["Yüzüne karşı konuş", {"renown": 3, "loyalty": 1}], ["Yoldaşını sürgüne yolla", {"renown": -3, "stab": -2, "favor": 2}], ["Hatayı üstlen", {"renown": 5, "stab": 3, "favor": -2}]]},
]


const MODERN_CARDS := [
	{"id": "talks", "t": "Müzakere Masası", "scene": "talks", "b": "Komşu ülkenin heyeti sınır ve ticaret konusunda seninle masaya oturmak istiyor. Hükümet sonucu bekliyor.",
		"c": [["Masaya otur", {}, {"game": "negotiate", "style": [1.2, 1.0, 1.0], "title": "Müzakere Masası", "scene": "talks", "intro": "Heyetler karşılıklı oturdu. Karşı tarafın duruşunu oku, doğru hamleyi seç.",
				"win": {"renown": 10, "favor": 5, "gold_w": 3.0, "stab": 2}, "lose": {"renown": -4, "favor": -4, "stab": -2}, "draw": {"renown": 2, "favor": 1}, "yield": {"renown": -6, "favor": -3},
				"win_text": "Sınır ve ticaret anlaşması imzalandı. Hükümet seni tebrik etti.", "lose_text": "Görüşmeler çöktü. Karşı taraf basına sert bir açıklama yaptı."}],
			["Yetkili bir vekil gönder", {"renown": 1, "favor": 1}], ["Görüşmeyi reddet", {"renown": -3, "favor": -3}]]},
	{"id": "hostages", "t": "Esir Takası Pazarlığı", "scene": "spy", "b": "Karşı taraf esir ettiği askerlerinizi karşılığında bir bölgeyi boşaltmanı istiyor. Aracı bir ülke masayı kurdu.",
		"c": [["Pazarlığa otur", {}, {"game": "negotiate", "style": [1.0, 0.8, 1.3], "title": "Esir Takası", "scene": "talks", "skill_bonus": 0.1, "intro": "Aracı ülkenin diplomatları iki tarafı oturttu. Süre kısıtlı; her hamle önemli.",
				"win": {"troops": 400, "renown": 8, "favor": 4}, "lose": {"renown": -6, "stab": -3, "troops": -100}, "draw": {"troops": 150, "renown": 1}, "yield": {"renown": -8, "stab": -2},
				"win_text": "Esirler ek taviz verilmeden geri döndü. Askerler seni alkışlıyor.", "lose_text": "Takas çöktü; esirler yurda dönemedi."}],
			["Şartları olduğu gibi kabul et", {"troops": 250, "renown": -4, "favor": -3}], ["Esirleri kaderine bırak", {"renown": -8, "stab": -3}]]},
	{"id": "coup", "t": "Darbe Söylentisi", "scene": "spy", "b": "Subaylar arasında hükümete karşı bir darbe hazırlığı söylentisi dolaşıyor. Senden bilgi bekleniyor.",
		"c": [["Hükümete bildir", {"favor": 12, "loyalty": 4, "renown": -3}], ["Sessiz kal", {"renown": 2, "favor": -4, "loyalty": -2}], ["Komplocularla görüş", {"renown": 5, "loyalty": -8, "favor": -6}]]},
	{"id": "press", "t": "Basın Skandalı", "scene": "alliance", "b": "Bir gazete bölgendeki yolsuzluk iddialarını manşete taşıdı. Kamuoyu hesap soruyor.",
		"c": [["Soruşturma aç", {"gold_w": -0.5, "stab": 2, "renown": 3}], ["Gazeteyi sustur", {"favor": 3, "renown": -5, "stab": -3}], ["Açıklama yap", {"renown": 2}]]},
	{"id": "clash", "t": "Sınırda Çatışma", "scene": "border", "b": "Sınır karakoluna ateş açıldı; iki ülkenin devriyeleri karşı karşıya. Askerler talimat bekliyor.",
		"c": [["Takviye gönder", {"troops": -200, "renown": 5, "stab": 1}], ["Diplomatik protesto", {"favor": 3, "renown": -1}], ["Görmezden gel", {"renown": -4, "stab": -2}]]},
	{"id": "strike", "t": "Grev Dalgası", "scene": "trade", "b": "Limanlarda ve fabrikalarda grev başladı. Üretim durdu, işçiler seni bekliyor.",
		"c": [["Taleplere uy", {"gold_w": -2.0, "stab": 4}], ["Güvenlik güçlerini gönder", {"stab": -4, "favor": 3, "renown": -2}], ["Arabulucu getir", {"gold_w": -0.6, "stab": 2, "renown": 2}]]},
	{"id": "disaster", "t": "Doğal Afet", "scene": "trade", "b": "Bölgende deprem ve sel yaşandı. Yollar kapalı, binlerce kişi yardım bekliyor.",
		"c": [["Askerî yardım seferberliği", {"troops": -150, "stab": 4, "renown": 4}], ["Bütçeyi kullan", {"gold_w": -2.5, "stab": 5, "renown": 3}], ["Merkezden yardım iste", {"favor": -2, "stab": 2}]]},
	{"id": "invest", "t": "Yabancı Yatırım Teklifi", "scene": "trade", "b": "Yabancı bir şirket bölgene büyük bir liman ve fabrika yatırımı önerdi; karşılığında geniş imtiyaz istiyor.",
		"c": [["Kabul et", {"gold_w": 4.0, "loyalty": -3, "favor": -2}], ["Şartlı kabul et", {"gold_w": 2.0, "favor": 2}], ["Reddet", {"renown": 2, "stab": 1}]]},
	{"id": "defector", "t": "Sığınmacı Subay", "scene": "spy", "b": "Komşu ordunun bir subayı sana sığınıp gizli bilgiler vermek istiyor.",
		"c": [["Sığınma ver", {"renown": 4, "favor": -6, "troops": 100}], ["İade et", {"favor": 6, "renown": -3}], ["Sorgula", {"favor": 3, "loyalty": -1}]]},
	{"id": "visit", "t": "Müttefik Heyeti", "scene": "alliance", "b": "Müttefik bir ülkenin askerî heyeti bölgeni ziyaret etmek istiyor.",
		"c": [["Ağırla", {"gold_w": -1.0, "renown": 4, "favor": 4}], ["Ortak tatbikat yap", {"troops": -100, "renown": 6, "stab": 1}], ["Geri çevir", {"renown": -2, "loyalty": 2}]]},
	{"id": "pay", "t": "Maaşlar Gecikti", "scene": "assault", "b": "Maaşlar gecikti; bir birlik toplu olarak izin istemeye hazırlanıyor.",
		"c": [["Maaşları öde", {"gold_w": -2.5}], ["İbret için cezalandır", {"troops": -200, "renown": 2, "stab": -2}], ["Bırak gitsinler", {"troops": -1200}]]},
	{"id": "protest", "t": "Sokak Protestoları", "scene": "alliance", "b": "Başkentte ve bölgende kalabalıklar sokaklara döküldü; hayat pahalılığı ve yolsuzluk protesto ediliyor.",
		"c": [["Dinle ve reform sözü ver", {"gold_w": -1.0, "stab": 3, "renown": 2}], ["Güvenlik güçlerini kullan", {"stab": -3, "favor": 4, "renown": -4}], ["Bekle", {"stab": -4}]]},
	{"id": "rival", "t": "Rakip General", "scene": "alliance", "b": "Genelkurmayda terfi için bir rakibin seni hükümete karalıyor.",
		"c": [["Kamuoyunda yanıt ver", {"renown": 3, "favor": -4}], ["Hükümete şikâyet et", {"favor": 5, "renown": -2}], ["Kanıt topla", {"gold_w": -0.5, "favor": 2, "renown": 2}]]},
	{"id": "cyber", "t": "Siber Saldırı", "scene": "spy", "b": "Bölgenin elektrik ve haberleşme şebekesine siber saldırı yapıldı. Kaynağı belirsiz.",
		"c": [["Karşı saldırı yap", {"gold_w": -1.5, "renown": 5}], ["Sistemleri kapat", {"gold_w": -0.5, "stab": -2}], ["Hükümete bildir", {"favor": 5}]], "modern_only": true},
	{"id": "arms", "t": "Silah Tüccarı", "scene": "trade", "b": "Bir tüccar indirimli silah ve teçhizat satmak istiyor; kaynağı şüpheli.",
		"c": [["Hepsini al", {"gold_w": -3.0, "troops": 500, "favor": -2}], ["Pazarlık et", {"gold_w": -1.5, "troops": 250}], ["Reddet", {"favor": 2, "renown": 1}]]},
]


const PRE_ONLY := ["duel", "champion"]


static func _draw_card(gs) -> void:
	# kılıç düellosu / pehlivan meydan okuması yalnızca erken çağlarda (modern/dünya savaşı çağında anlamsız)
	var fam: String = Eras.family()
	var pool: Array = []
	if fam == "pre":
		pool = CARDS.duplicate()
	else:
		for cc in MODERN_CARDS:
			if bool(cc.get("modern_only", false)) and fam != "":
				continue
			pool.append(cc)
	# evlilik teklifi: bir kez kabul edilince bir daha gelmez; reddedilirse bir süre (52 hafta) gelmez
	var married: bool = bool(gs.career.get("married", false))
	var mcd: int = int(gs.career.get("marriage_cd", 0))
	var pool2: Array = []
	for cc2 in pool:
		if String(cc2.get("id", "")) == "marriage" and (married or gs.turn < mcd):
			continue
		pool2.append(cc2)
	if not pool2.is_empty():
		pool = pool2
	var c: Dictionary = pool[gs.rng.randi() % pool.size()]
	gs.career.next_card = gs.turn + CARD_CD + gs.rng.randi() % 4
	gs.career["pending"] = {"kind": "card", "card": c}
	gs.career_card.emit()


static func apply_fx(gs, fx: Dictionary) -> void:
	var mc = me(gs)
	for k in fx:
		var v: float = float(fx[k])
		match k:
			"renown":
				add(gs, k, v * 0.5)
			"favor", "loyalty":
				add(gs, k, v)
			"gold_w":
				mc.gold = maxf(0.0, mc.gold + mc.income * v)
			"troops":
				if v > 0:
					gs.place_recruits(mc, int(v))
				else:
					var left: int = int(-v)
					for ar in gs.armies_of(mc.id):
						var take: int = mini(left, ar.size - 100)
						if take > 0:
							ar.size -= take
							left -= take
						if left <= 0:
							break
				gs.refresh_stats()
			"stab":
				mc.stability = clampf(mc.stability + v, 5.0, 100.0)


## Kart seçimi (pending kind=card)
static func choose(gs, idx: int) -> void:
	var pend: Dictionary = gs.career.get("pending", {})
	if pend.get("kind", "") == "card":
		var c: Dictionary = pend.card
		var ch: Array = c.c
		if idx >= 0 and idx < ch.size():
			apply_fx(gs, ch[idx][1])
			_log(gs, "%s: %s" % [String(c.t), String(ch[idx][0])])
			if String(c.get("id", "")) == "marriage":
				if idx == 0:
					gs.career["married"] = true
				else:
					gs.career["marriage_cd"] = gs.turn + 52
	gs.career["pending"] = {}


## Mini oyunlu seçim: sonuç "win" | "lose" | "draw" | "yield"
static func choose_game(gs, idx: int, result: String) -> void:
	var pend: Dictionary = gs.career.get("pending", {})
	if pend.get("kind", "") == "card":
		var c: Dictionary = pend.card
		var ch: Array = c.c
		if idx >= 0 and idx < ch.size() and ch[idx].size() > 2:
			var g: Dictionary = ch[idx][2]
			var fx: Dictionary = g.get(result, g.get("lose", {}))
			apply_fx(gs, fx)
			var tag: String = {"win": "kazandın", "lose": "yenildin", "draw": "berabere", "yield": "çekildin"}.get(result, result)
			_log(gs, "%s: %s" % [String(c.t), tag])
			if result == "win":
				add(gs, "loyalty", 0.0)
	gs.career["pending"] = {}


## Savaşa çağrı yanıtı
static func answer_call(gs, go: bool) -> void:
	if go:
		add(gs, "favor", 10.0)
		add(gs, "loyalty", 5.0)
		var hc = sov(gs)
		var mc = me(gs)
		if hc != null:
			for en in hc.enemies:
				if not gs.at_war(mc.id, en) and gs.countries[en].alive:
					gs.declare_war(mc.id, en, true)
		_log(gs, "Hükümdarın savaşına katıldın.")
	else:
		add(gs, "favor", -18.0)
		add(gs, "loyalty", -8.0)
		_log(gs, "Savaş çağrısını reddettin.")
	gs.career["pending"] = {}


## Huzura çağrı (düşük sadakat): af dile / hediye / gitme
static func answer_summons(gs, idx: int) -> void:
	var mc = me(gs)
	match idx:
		0:
			add(gs, "loyalty", 15.0)
			add(gs, "favor", 5.0)
			add(gs, "renown", -4.0)
		1:
			mc.gold = maxf(0.0, mc.gold - mc.income * 4.0)
			add(gs, "loyalty", 25.0)
			add(gs, "favor", 10.0)
		2:
			add(gs, "favor", -20.0)
			gs.career.flags["suspect"] = true
			if gs.rng.randf() < 0.5:
				gs.career["pending"] = {"kind": "arrest"}
				gs.career_card.emit()
				return
	gs.career["pending"] = {}


## Tutuklama emri: kaç ve isyan et / teslim ol (oyun biter)
static func answer_arrest(gs, flee: bool) -> void:
	gs.career["pending"] = {}
	if flee:
		start_rebellion(gs)
	else:
		gs.career.over = true
		gs.game_over.emit(false, Loc.t("%s zincire vuruldu ve saray avlusunda boynu vuruldu. Hikâye burada bitti.") % String(gs.career.name))


static func resume(gs) -> void:
	if active(gs) and not gs.career.get("pending", {}).is_empty():
		gs.career_card.emit()


## Savaşta vasal/isyancı eki: kendi toprağını savunurken küçük bonus
static func war_mod(gs, att, def) -> float:
	if not active(gs):
		return 1.0
	if att.id == gs.player:
		return 1.0 + float(gs.career.get("att", 0.0)) + float(gs.career.rank) * 0.03 + (0.05 if _has_comp(gs, "komutan") else 0.0) + (0.04 if String(gs.career.get("policy", "balanced")) == "army" else 0.0)
	return 1.0
