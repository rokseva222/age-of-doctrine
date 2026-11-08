extends RefCounted
## BÜYÜK HAREKÂT: kara + hava + deniz + sabotaj + siber saldırıyı birleştiren, pahalı ve uzun beklemeli bitirici operasyon.
## Oyuncu adını koyar; başarı olasılığı (Zafer / Kısmi / Fiyasko) önceden gösterilir ve gerçekten o olasılıkla çekilir.
## Zafer hedefin kalan eyaletlerinin yaklaşık yarısını bir anda ele geçirir; bedeli: büyük kasa harcaması, kayıplar, dünya tepkisi.
## Operasyon 3 hafta sürer; her aşamada operasyona özgü, çeşitli haberler düşer (TR + EN).

const Loc = preload("res://scripts/loc.gd")
const Macro = preload("res://scripts/macro.gd")
const Eras = preload("res://scripts/eras.gd")

const COOLDOWN := 26                # hafta
const DURATION := 3                 # hafta (başlangıç → sonuç)
const COST_WEEKS := 8.0             # gelirin kaç haftalığı
const MIN_TROOPS := 30000
const MIN_TARGET_PROVS := 3
const INFAMY_LAUNCH := 8.0
const INFAMY_WIN := 10.0
const INFAMY_PARTIAL := 4.0
const SHARE_WIN := 0.45
const SHARE_PARTIAL := 0.20
const MAX_WIN := 8
const COMP := ["land", "air", "sea", "sab", "cyber"]
const COMP_NAME := {"land": "Kara", "air": "Hava", "sea": "Deniz", "sab": "Sabotaj", "cyber": "Siber"}
const WEIGHT := {"land": 0.40, "air": 0.20, "sea": 0.15, "sab": 0.10, "cyber": 0.15}

const DEFAULT_NAMES_TR := ["Çelik Fırtına", "Kızıl Şafak", "Demir Yumruk", "Kuzey Okyanusu", "Son Kapı", "Gece Mızrağı", "Kırık Zincir", "Büyük Dalga", "Altın Kılıç", "Sessiz Kasırga"]
const DEFAULT_NAMES_EN := ["Steel Storm", "Red Dawn", "Iron Fist", "Northern Tide", "Last Gate", "Night Spear", "Broken Chain", "Great Wave", "Golden Sword", "Silent Cyclone"]

# --- haber şablonları: {op} harekât adı, {me} oyuncu devlet, {foe} hedef devlet, {n} ele geçen şehir, {tot} hedefin toplam şehri, {ratio} kayıp oranı, {lost} kendi kaybı, {killed} düşman kaybı
const NEWS_TR := {
	"start": [
		"{me}, {foe}'e karşı \"{op}\" adlı büyük harekâtı başlattı: kara, hava ve deniz kuvvetleri aynı anda hareketlendi.",
		"\"{op}\" başladı! {me} ordusu {foe} cephesinde geniş çaplı birleşik taarruza geçti; siber hatlar çöktü.",
		"Sınırda sirenler: {me}, \"{op}\" harekâtıyla {foe}'in savunma hattını hedef aldı.",
	],
	"p1": [
		"\"{op}\": ilk dalga bombardıman sürüyor, {foe} komuta ağı kesintilerle sarsıldı.",
		"{foe} kaynakları \"{op}\" taarruzunun ilk saatlerinde hava savunmasının ağır baskı altında olduğunu bildiriyor.",
		"\"{op}\": {me} özel kuvvetleri {foe} arkasında köprü ve depoları vurdu.",
	],
	"p2": [
		"\"{op}\" ikinci haftasında: zırhlı kollar derinlemesine ilerliyor, {foe} yedekleri cepheye yetişemiyor.",
		"{foe} hükûmeti olağanüstü toplandı; \"{op}\" yüzünden başkentte alarm hâli ilan edildi.",
		"Denizden destek: {me} donanması \"{op}\" kapsamında kıyı hedeflerini vurmaya başladı.",
	],
	"win": [
		"ZAFER! \"{op}\" tamamlandı: {me}, {foe}'in {tot} şehrinden {n}'ini ele geçirdi. Kayıp oranı {ratio}.",
		"\"{op}\" tarihe geçiyor: {foe} savunması çöktü, {n} şehir bir hamlede {me} kontrolüne girdi.",
		"{foe} cephesi dağıldı! \"{op}\" harekâtında {n} şehir düştü; {me} generalleri zaferi ilan etti.",
		"\"{op}\": {me} ordusu {n} şehri aldı, düşman kaybı {killed}, kendi kaybı {lost}. Dünya basını \"şimşek taarruzu\" diyor.",
	],
	"partial": [
		"\"{op}\" kısmen başarılı: {me} yalnızca {n} şehri alabildi, {foe} direnişi cepheyi tutuyor. Kayıp oranı {ratio}.",
		"{me}, \"{op}\" ile {n} şehir kazandı; ancak plan hedeflerin gerisinde kaldı.",
		"\"{op}\" yavaşladı: {n} şehir alındı ama {foe} ana hatlarını korudu.",
	],
	"fail": [
		"FİYASKO! \"{op}\" çöktü: {me} saldırısı {foe} savunmasında dağıldı, kayıp {lost}.",
		"\"{op}\" harekâtı başarısız: tek şehir bile alınamadı. {foe} karşı saldırıya hazırlanıyor.",
		"{me} için ağır darbe: \"{op}\" planı sızdı ve çöktü; kayıplar {lost} asker.",
	],
}
const NEWS_EN := {
	"start": [
		"{me} has launched the grand operation \"{op}\" against {foe}: land, air and naval forces moved at once.",
		"\"{op}\" has begun! {me}'s army launched a sweeping combined assault on the {foe} front; cyber lines went down.",
		"Sirens at the border: {me}'s operation \"{op}\" targets {foe}'s defensive line.",
	],
	"p1": [
		"\"{op}\": the first wave of bombardment continues, {foe}'s command network is shaken by outages.",
		"{foe} sources report heavy pressure on air defenses in the opening hours of \"{op}\".",
		"\"{op}\": {me} special forces struck bridges and depots behind {foe}'s lines.",
	],
	"p2": [
		"\"{op}\", week two: armored columns push deep, {foe}'s reserves cannot reach the front.",
		"{foe}'s government met in emergency session; alert declared in the capital because of \"{op}\".",
		"Naval support: {me}'s fleet began striking coastal targets as part of \"{op}\".",
	],
	"win": [
		"VICTORY! \"{op}\" is complete: {me} captured {n} of {foe}'s {tot} cities. Loss ratio {ratio}.",
		"\"{op}\" goes into the history books: {foe}'s defense collapsed, {n} cities fell under {me} control in one stroke.",
		"The {foe} front has shattered! {n} cities fell in \"{op}\"; {me}'s generals declared victory.",
		"\"{op}\": {me}'s army took {n} cities, enemy losses {killed}, own losses {lost}. The world press calls it a \"lightning strike\".",
	],
	"partial": [
		"\"{op}\" partly successful: {me} could take only {n} cities, {foe}'s resistance holds the line. Loss ratio {ratio}.",
		"{me} gained {n} cities with \"{op}\", but the plan fell short of its goals.",
		"\"{op}\" slowed down: {n} cities taken but {foe} kept its main lines.",
	],
	"fail": [
		"FIASCO! \"{op}\" collapsed: {me}'s assault dissolved against {foe}'s defense, losses {lost}.",
		"Operation \"{op}\" failed: not a single city was taken. {foe} is preparing a counter-attack.",
		"A heavy blow for {me}: the \"{op}\" plan leaked and collapsed; {lost} troops lost.",
	],
}


static func ensure(gs) -> void:
	if not (gs.grand is Dictionary) or not gs.grand.has("ops"):
		gs.grand = {"cd": 0, "ops": [], "done": 0}


static func default_name(gs) -> String:
	var arr: Array = DEFAULT_NAMES_TR if Loc.lang == "tr" else DEFAULT_NAMES_EN
	return arr[(gs.turn + gs.grand.get("done", 0) * 3) % arr.size()]


static func clean_name(gs, s: String) -> String:
	s = s.strip_edges().replace("\"", "").replace("\n", " ").substr(0, 24)
	return s if s != "" else default_name(gs)


# ------------------------------------------------------------------ hesap

static func _share(a: float, b: float, neutral: float) -> float:
	if a + b <= 0.001:
		return neutral
	return clampf((a / (a + b) - 0.3) / 0.5, 0.0, 1.0)


## Beş bileşenin hazırlık puanı (0..1)
static func components(gs, tgt: int) -> Dictionary:
	var me = gs.countries[gs.player]
	var foe = gs.countries[tgt]
	var land: float = _share(float(me.troops) * me.eq_land, float(foe.troops) * foe.eq_land, 0.4)
	var air: float = _share(me.air_pow, foe.air_pow, 0.3)
	var sea: float = _share(me.naval_pow, foe.naval_pow, 0.35)
	var coastal := false
	for pid in foe.owned_ids:
		if gs.provinces[pid].coastal:
			coastal = true
			break
	if not coastal:
		sea = 0.5                       # kıyısı olmayan hedefe deniz bileşeni nötr
	var sab: float = clampf(0.35 + (me.tech - foe.tech) * 1.4 + 0.1 * float(me.doctrine >= 3), 0.0, 1.0)
	var cyber: float = _share(me.cyber, foe.cyber, 0.4)
	var fam: String = Eras.family()
	if fam == "ww1":
		air = 0.0
		cyber = 0.0
		sab = 0.0
	elif fam == "ww2" or Eras.current != "":
		cyber = 0.0
	return {"land": land, "air": air, "sea": sea, "sab": sab, "cyber": cyber}


static func active_weights() -> Dictionary:
	var w: Dictionary = WEIGHT.duplicate()
	var fam: String = Eras.family()
	if fam == "ww1":
		w = {"land": 0.75, "air": 0.0, "sea": 0.25, "sab": 0.0, "cyber": 0.0}
	elif Eras.current != "":
		w = {"land": 0.50, "air": 0.25, "sea": 0.15, "sab": 0.10, "cyber": 0.0}
	return w


static func strength(gs, tgt: int) -> float:
	var comp: Dictionary = components(gs, tgt)
	var w: Dictionary = active_weights()
	var s := 0.0
	for k in COMP:
		s += float(w[k]) * float(comp[k])
	# hedefin savunma gücü (istikrar ve eyalet savunması) küçük bir ceza
	var foe = gs.countries[tgt]
	s -= 0.06 * clampf(foe.stability / 100.0, 0.0, 1.0)
	return clampf(s, 0.0, 1.0)


## Zafer / Kısmi / Fiyasko dağılımı (toplam 1)
static func odds(gs, tgt: int) -> Dictionary:
	var s: float = strength(gs, tgt)
	var win: float = clampf(s * 1.05 - 0.12, 0.04, 0.85)
	var fail: float = clampf((1.0 - s) * 0.55, 0.05, 0.6)
	var part: float = 1.0 - win - fail
	if part < 0.10:
		var take: float = 0.10 - part
		fail = maxf(0.05, fail - take * 0.5)
		win = maxf(0.04, win - take * 0.5)
		part = 1.0 - win - fail
	return {"win": win, "partial": part, "fail": fail, "strength": s}


static func target_cities(gs, tgt: int) -> int:
	var n := 0
	for pid in gs.countries[tgt].owned_ids:
		if gs.provinces[pid].controller == tgt:
			n += 1
	return n


static func win_count(total: int) -> int:
	return clampi(int(round(total * SHARE_WIN)), 2, MAX_WIN) if total >= MIN_TARGET_PROVS else 0


static func partial_count(total: int) -> int:
	return clampi(int(round(total * SHARE_PARTIAL)), 1, 4) if total >= MIN_TARGET_PROVS else 0


static func cost(gs) -> float:
	return maxf(3.0, COST_WEEKS * maxf(gs.countries[gs.player].income, 1.0))


static func cooldown_left(gs) -> int:
	ensure(gs)
	return maxi(0, int(gs.grand.cd) - gs.turn)


## Hata metni ("" = başlatılabilir)
static func check(gs, tgt: int) -> String:
	ensure(gs)
	if gs.player < 0 or tgt < 0 or tgt == gs.player or not gs.countries[tgt].alive:
		return Loc.t("Geçersiz hedef.")
	if not gs.at_war(gs.player, tgt):
		return Loc.t("Büyük Harekât için hedefle savaşta olmalısın.")
	for o in gs.grand.ops:
		if int(o.tgt) == tgt:
			return Loc.t("Bu hedefe karşı zaten bir Büyük Harekât sürüyor.")
	var left: int = cooldown_left(gs)
	if left > 0:
		return Loc.t("Genelkurmay yeniden hazırlanıyor (%d hafta).") % left
	if gs.countries[gs.player].troops < MIN_TROOPS:
		return Loc.t("Büyük Harekât için en az %d asker gerekir.") % MIN_TROOPS
	if target_cities(gs, tgt) < MIN_TARGET_PROVS:
		return Loc.t("Hedefin en az %d eyaleti kalmış olmalı.") % MIN_TARGET_PROVS
	if gs.countries[gs.player].gold < cost(gs):
		return Loc.t("Kasa yetersiz: Büyük Harekât bedeli %s.") % Macro.money(cost(gs))
	return ""


# ------------------------------------------------------------------ başlat / yürüt

static func _text(kind: String, op: Dictionary, extra: Dictionary = {}) -> String:
	var pool: Array = (NEWS_TR if Loc.lang == "tr" else NEWS_EN)[kind]
	var t: String = pool[int(op.seed + int(extra.get("v", 0))) % pool.size()]
	var vals := {"op": op.name, "me": op.me_name, "foe": op.foe_name, "n": str(extra.get("n", 0)), "tot": str(op.tot),
		"ratio": str(extra.get("ratio", "-")), "lost": str(extra.get("lost", "-")), "killed": str(extra.get("killed", "-"))}
	for k in vals.keys():
		t = t.replace("{%s}" % k, str(vals[k]))
	return t


## Başlatır. Dönüş: {"err": "", ...}
static func launch(gs, tgt: int, op_name: String) -> Dictionary:
	var err: String = check(gs, tgt)
	if err != "":
		return {"err": err}
	var me = gs.countries[gs.player]
	var foe = gs.countries[tgt]
	var od: Dictionary = odds(gs, tgt)
	me.gold -= cost(gs)
	gs.grand.cd = gs.turn + COOLDOWN
	gs.infamy = minf(100.0, gs.infamy + INFAMY_LAUNCH)
	var op := {"name": clean_name(gs, op_name), "tgt": tgt, "start": gs.turn, "tot": target_cities(gs, tgt),
		"win": od.win, "partial": od.partial, "fail": od.fail, "seed": gs.rng.randi() % 1000,
		"me_name": me.name, "foe_name": foe.name, "stage": 0}
	gs.grand.ops.append(op)
	gs.post_news(_text("start", op), me.capital, "war_player")
	gs.state_changed.emit()
	return {"err": "", "op": op}


static func tick(gs) -> void:
	ensure(gs)
	if gs.grand.ops.is_empty():
		return
	for op in gs.grand.ops.duplicate():
		var age: int = gs.turn - int(op.start)
		var tgt: int = int(op.tgt)
		if not gs.countries[tgt].alive or not gs.at_war(gs.player, tgt):
			# hedef yok oldu / barış yapıldı: harekât iptal, kasa iade edilmez
			gs.grand.ops.erase(op)
			continue
		if age >= 1 and int(op.stage) < 1:
			op.stage = 1
			gs.post_news(_text("p1", op, {"v": 1}), -1, "war_player")
		if age >= 2 and int(op.stage) < 2:
			op.stage = 2
			gs.post_news(_text("p2", op, {"v": 2}), -1, "war_player")
		if age >= DURATION:
			gs.grand.ops.erase(op)
			_resolve(gs, op)


static func _scale_armies(gs, owner: int, frac: float) -> int:
	var lost := 0
	for a in gs.armies.values():
		if a.owner == owner:
			var l: int = int(a.size * frac)
			a.size = maxi(1, a.size - l)
			lost += l
	return lost


static func _near_order(gs, tgt: int) -> Array:
	# hedefin oyuncuya (ve oyuncunun işgal ettiği topraklara) yakın eyaletleri önce
	var mine := {}
	for p in gs.provinces:
		if p.controller == gs.player:
			mine[p.id] = true
	var dist := {}
	var q: Array = []
	for pid in mine.keys():
		dist[pid] = 0
		q.append(pid)
	var qi := 0
	while qi < q.size():
		var cur: int = q[qi]
		qi += 1
		for nb in gs.provinces[cur].neighbors:
			if not dist.has(nb):
				dist[nb] = int(dist[cur]) + 1
				q.append(nb)
	var cand: Array = []
	for pid in gs.countries[tgt].owned_ids:
		if gs.provinces[pid].controller == tgt:
			cand.append([int(dist.get(pid, 99)), pid])
	cand.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	return cand.map(func(e): return e[1])


static func _resolve(gs, op: Dictionary) -> void:
	var tgt: int = int(op.tgt)
	var roll: float = gs.rng.randf()
	var kind := "fail"
	if roll < float(op.win):
		kind = "win"
	elif roll < float(op.win) + float(op.partial):
		kind = "partial"
	var total_now: int = target_cities(gs, tgt)
	var want := 0
	var own_loss := 0.03
	var foe_loss := 0.20
	match kind:
		"win":
			want = mini(win_count(maxi(int(op.tot), total_now)), total_now)
		"partial":
			want = mini(partial_count(maxi(int(op.tot), total_now)), total_now)
			own_loss = 0.06
			foe_loss = 0.10
		_:
			own_loss = 0.12
			foe_loss = 0.03
	var me_troops_before: int = gs.countries[gs.player].troops
	var killed := _scale_armies(gs, tgt, foe_loss)
	var lost := _scale_armies(gs, gs.player, own_loss)
	var taken := 0
	if want > 0:
		for pid in _near_order(gs, tgt):
			if taken >= want:
				break
			var p = gs.provinces[pid]
			var d = gs.armies.get(pid)
			if d != null and d.owner == tgt:
				killed += d.size
				gs.armies.erase(pid)
			p.controller = gs.player
			p.siege = 0
			p.siege_by = -1
			p.unrest = maxf(p.unrest, 4.0)
			gs.stats.captures += 1
			gs.stats.p_captures += 1
			var w = gs.get_war(gs.player, tgt)
			if w != null:
				w.add(gs.player, p.value() * 3)
			gs.province_changed.emit(pid)
			taken += 1
	if kind == "win":
		gs.infamy = minf(100.0, gs.infamy + INFAMY_WIN)
		gs.countries[gs.player].stability = clampf(gs.countries[gs.player].stability + 3.0, 5.0, 100.0)
	elif kind == "partial":
		gs.infamy = minf(100.0, gs.infamy + INFAMY_PARTIAL)
	else:
		gs.countries[gs.player].stability = clampf(gs.countries[gs.player].stability - 6.0, 5.0, 100.0)
	gs.grand.done = int(gs.grand.get("done", 0)) + 1
	var ratio := "1:%d" % maxi(1, int(round(float(maxi(killed, 1)) / float(maxi(lost, 1)))))
	if killed < lost:
		ratio = "%d:1" % maxi(1, int(round(float(maxi(lost, 1)) / float(maxi(killed, 1)))))
	var ex := {"n": taken, "ratio": ratio, "lost": _k(lost), "killed": _k(killed), "v": int(op.seed)}
	var pid0: int = int(gs.countries[tgt].capital)
	gs.post_news(_text(kind, op, ex), pid0, "war_player")
	gs.grand["last"] = {"name": op.name, "kind": kind, "taken": taken, "tgt": tgt, "turn": gs.turn}
	gs.stats["grand_" + kind] = int(gs.stats.get("grand_" + kind, 0)) + 1
	gs._check_elimination()
	gs.refresh_stats()
	gs.state_changed.emit()
	if gs.has_signal("grand_resolved"):
		gs.grand_resolved.emit(kind, String(op.name), taken)


static func _k(n: int) -> String:
	return "%d bin" % int(round(n / 1000.0)) if Loc.lang == "tr" and n >= 1000 else (("%dk" % int(round(n / 1000.0))) if n >= 1000 else str(n))
