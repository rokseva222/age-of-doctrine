extends RefCounted
## Birleşmiş Milletler: önergeler tüm üyelerin salt çoğunluk oyuyla karara bağlanır (veto yok).
## Önergeler: ateşkes, yeniden inşa fonu, insani yardım, ortak harekât (kabul eden ülkeler hedefe savaş açar).

const Eras = preload("res://scripts/eras.gd")
const Macro = preload("res://scripts/macro.gd")
const Names = preload("res://scripts/names.gd")

const ORDER := ["ceasefire", "rebuild", "aid", "peace_keep", "develop", "guarantee", "sanction", "embargo", "probe", "disarm", "attack"]
const FRIENDLY := ["rebuild", "aid", "peace_keep", "develop", "guarantee"]
const HOSTILE := ["sanction", "embargo", "probe", "disarm", "attack"]
# mult: önerge bedeli = hf geliri x mult; cd: aynı önergeyi yeniden verme bekleme süresi (hafta)
const KINDS := {
	"ceasefire": {"name": "Ateşkes çağrısı", "desc": "Savaşan iki tarafı ateşkese çağırır.", "mult": 0.0, "cd": 8},
	"rebuild": {"name": "Yeniden inşa fonu", "desc": "Hedef ülkenin harap eyaletlerini onarmak için fon ayrılır.", "mult": 8.0, "cd": 26},
	"aid": {"name": "İnsani yardım", "desc": "Hedef ülkeye hazine ve istikrar desteği.", "mult": 4.0, "cd": 13},
	"peace_keep": {"name": "Barış gücü", "desc": "Hedef ülkede huzursuzluğu söndürür, istikrarı artırır.", "mult": 3.0, "cd": 13},
	"develop": {"name": "Kalkınma programı", "desc": "Hedef ülkenin en az gelişmiş eyaletleri bir kademe gelişir.", "mult": 10.0, "cd": 39},
	"guarantee": {"name": "Egemenlik garantisi", "desc": "Lehte oy veren ülkeler hedefe 26 hafta saldırmaz.", "mult": 6.0, "cd": 26},
	"embargo": {"name": "Silah ambargosu", "desc": "Hedef ülkenin sanayisi ve lojistiği zayıflar.", "mult": 6.0, "cd": 26},
	"probe": {"name": "Uluslararası soruşturma", "desc": "Hedef ülkenin istikrarı ve saldırganlığı düşer.", "mult": 3.0, "cd": 26},
	"disarm": {"name": "Silahsızlanma kararı", "desc": "Hedef ülkenin ordusu yüzde 12 küçülür.", "mult": 8.0, "cd": 39},
	"sanction": {"name": "Yaptırım kararı", "desc": "Hedef ülkenin geliri 26 hafta boyunca yüzde 25 düşer.", "mult": 5.0, "cd": 26},
	"attack": {"name": "Ortak harekât", "desc": "Kabul edilirse lehte oy veren ülkeler hedefe savaş açar.", "mult": 12.0, "cd": 52},
}
const MAX_ATTACKERS := 8


## BM bu tarihte var mı? Tarihî kiplerde Ekim 1945'ten itibaren.
static func available(gs) -> bool:
	if Eras.current == "":
		return true
	var ym: Array = Names.year_month(gs.turn)
	return int(ym[0]) * 12 + int(ym[1]) - 1 >= 1945 * 12 + 9


static func members(gs) -> Array:
	var out: Array = []
	for c in gs.countries:
		if c.alive and not c.is_rebel:
			out.append(c.id)
	return out


static func cost_of(gs, kind: String) -> float:
	var inc: float = maxf(gs.countries[gs.player].income, 1.0)
	return inc * float(KINDS[kind]["mult"])


static func cooldown_left(gs, kind: String) -> int:
	return maxi(0, int(gs.un_cd.get(kind, 0)) - gs.turn)


## Önerge için aday hedefler (kind'a göre sıralı).
static func targets(gs, kind: String) -> Array:
	var out: Array = []
	if kind == "ceasefire":
		for w in gs.wars:
			if not (gs.countries[w.a].is_rebel or gs.countries[w.b].is_rebel):
				out.append(gs.wars.find(w))
		return out
	for c in gs.countries:
		if not c.alive or c.is_rebel:
			continue
		if HOSTILE.has(kind) and (c.id == gs.player or gs.is_allied(gs.player, c.id)):
			continue
		out.append(c.id)
	if HOSTILE.has(kind):
		out.sort_custom(func(a, b): return gs.countries[a].aggression > gs.countries[b].aggression)
	else:
		out.sort_custom(func(a, b): return gs.countries[a].stability < gs.countries[b].stability)
	return out


static func _p_yes(gs, kind: String, m: int, proposer: int, target: int, w) -> float:
	var mc = gs.countries[m]
	if m == proposer:
		return 1.0
	match kind:
		"ceasefire":
			var p := 0.76
			if m == w.a or m == w.b:
				var mine: int = w.score_of(m)
				var theirs: int = w.score_of(w.b if m == w.a else w.a)
				p = 0.8 if mine < theirs else (0.25 if mine > theirs else 0.5)
			elif gs.is_allied(m, w.a) or gs.is_allied(m, w.b):
				p = 0.7
			return clampf(p - 0.25 * mc.aggression, 0.05, 0.95)
		"rebuild", "aid", "peace_keep", "develop", "guarantee":
			if m == target:
				return 1.0
			var base := 0.66 if (kind == "rebuild" or kind == "guarantee") else 0.62
			if gs.at_war(m, target):
				base = 0.1
			elif gs.is_allied(m, target):
				base = 0.92
			elif mc.alliance >= 0 and mc.alliance == gs.countries[target].alliance:
				base = 0.9
			return clampf(base, 0.05, 0.95)
		"sanction", "embargo", "probe", "disarm":
			if m == target:
				return 0.0
			if gs.at_war(m, target):
				return 0.95
			if gs.is_allied(m, target):
				return 0.05
			var ts = gs.countries[target]
			var p3: float = 0.35 + 0.4 * clampf(ts.aggression, 0.0, 1.0) + 0.04 * minf(float(ts.enemies.size()), 5.0)
			if kind == "disarm":
				p3 -= 0.1
			elif kind == "probe":
				p3 += 0.05
			if gs.is_allied(m, proposer):
				p3 += 0.2
			return clampf(p3, 0.05, 0.92)
		_:
			if m == target:
				return 0.0
			if gs.at_war(m, target):
				return 0.97
			if gs.is_allied(m, target):
				return 0.02
			var t = gs.countries[target]
			var p2: float = 0.28 + 0.45 * clampf(t.aggression, 0.0, 1.0) + 0.04 * minf(float(t.enemies.size()), 5.0)
			if gs.is_allied(m, proposer):
				p2 += 0.2
			return clampf(p2, 0.03, 0.93)


## Oylama: {yes, no, passed, yes_ids}
static func vote(gs, kind: String, proposer: int, target: int, w = null) -> Dictionary:
	var yes := 0
	var no := 0
	var yes_ids: Array = []
	for m in members(gs):
		if gs.rng.randf() < _p_yes(gs, kind, m, proposer, target, w):
			yes += 1
			yes_ids.append(m)
		else:
			no += 1
	return {"yes": yes, "no": no, "passed": yes > no, "yes_ids": yes_ids}


## Önergeyi verir: bedel/bekleme kontrolü (yalnızca oyuncu için), oylama ve uygulama.
## target: ateşkesse savaşın dizini (gs.wars), diğerlerinde ülke kimliği.
static func propose(gs, kind: String, proposer: int, target: int) -> Dictionary:
	var res := {"ok": false, "passed": false, "text": "", "yes": 0, "no": 0}
	if not available(gs):
		res.text = "Birleşmiş Milletler henüz kurulmadı."
		return res
	var is_player: bool = proposer == gs.player
	if is_player:
		var left: int = cooldown_left(gs, kind)
		if left > 0:
			res.text = "Bu önerge için %d hafta beklemelisin." % left
			return res
		var cost: float = cost_of(gs, kind)
		if gs.countries[proposer].gold < cost:
			res.text = "Kasa yetersiz: önerge bedeli %s." % Macro.money(cost)
			return res
	var w = null
	var tc: int = target
	if kind == "ceasefire":
		if target < 0 or target >= gs.wars.size():
			res.text = "Geçerli bir hedef yok."
			return res
		w = gs.wars[target]
		tc = w.a
	elif target < 0 or target >= gs.countries.size() or not gs.countries[target].alive:
		res.text = "Geçerli bir hedef yok."
		return res
	if is_player:
		gs.countries[proposer].gold -= cost_of(gs, kind)
		gs.un_cd[kind] = gs.turn + int(KINDS[kind]["cd"])
		gs.player_acted = true
	var v: Dictionary = vote(gs, kind, proposer, tc, w)
	res.ok = true
	res.yes = v.yes
	res.no = v.no
	res.passed = v.passed
	var kname: String = KINDS[kind]["name"]
	if not v.passed:
		res.text = "BM: %s önergesi reddedildi (%d lehte, %d aleyhte)." % [kname, v.yes, v.no]
		_log(gs, res.text, false)
		if is_player:
			gs.post_news(res.text, -1, "peace")
		return res
	var eff: String = _apply(gs, kind, proposer, tc, w, v.yes_ids)
	res.text = "BM: %s önergesi kabul edildi (%d lehte, %d aleyhte). %s" % [kname, v.yes, v.no, eff]
	_log(gs, res.text, true)
	if is_player:
		gs.stats.un_passed += 1
	gs.post_news(res.text, -1, "war" if kind == "attack" else "peace")
	return res


static func _log(gs, text: String, ok: bool) -> void:
	gs.un_log.append({"turn": gs.turn, "text": text, "ok": ok})
	if gs.un_log.size() > 12:
		gs.un_log = gs.un_log.slice(gs.un_log.size() - 12)


static func _apply(gs, kind: String, proposer: int, target: int, w, yes_ids: Array) -> String:
	match kind:
		"ceasefire":
			var a: int = w.a
			var b: int = w.b
			gs.finish_peace(w, -1, [])
			gs.countries[a].truce[b] = gs.turn + 26
			gs.countries[b].truce[a] = gs.turn + 26
			return "%s ile %s arasında ateşkes başladı." % [gs.countries[a].name, gs.countries[b].name]
		"rebuild":
			var t = gs.countries[target]
			var fund: float = maxf(t.income, 1.0) * 20.0
			t.gold += fund
			t.stability = clampf(t.stability + 12.0, 5.0, 100.0)
			var fixed := 0
			for pid in gs.country_province_ids(target):
				var p = gs.provinces[pid]
				if p.unrest > 0:
					p.unrest = maxi(0, p.unrest - 6)
				if fixed < 3 and p.dev < 5 and p.controller == target:
					p.dev += 1
					fixed += 1
			return "%s için %s fon aktarıldı; eyaletler onarılıyor." % [t.name, Macro.money(fund)]
		"aid":
			var t2 = gs.countries[target]
			var amt: float = maxf(t2.income, 1.0) * 8.0
			t2.gold += amt
			t2.stability = clampf(t2.stability + 5.0, 5.0, 100.0)
			return "%s için %s yardım gönderildi." % [t2.name, Macro.money(amt)]
		"peace_keep":
			var tk = gs.countries[target]
			tk.stability = clampf(tk.stability + 8.0, 5.0, 100.0)
			for pid2 in gs.country_province_ids(target):
				gs.provinces[pid2].unrest = 0
			return "Barış gücü %s topraklarına konuşlandı; huzursuzluk sönüyor." % tk.name
		"develop":
			var ids: Array = gs.country_province_ids(target).duplicate()
			ids.sort_custom(func(a, b): return gs.provinces[a].dev < gs.provinces[b].dev)
			var grown := 0
			for pid3 in ids:
				if grown >= 5:
					break
				if gs.provinces[pid3].dev < 5 and gs.provinces[pid3].controller == target:
					gs.provinces[pid3].dev += 1
					grown += 1
			return "%s için kalkınma programı: %d eyalet gelişti." % [gs.countries[target].name, grown]
		"guarantee":
			var gcount := 0
			for m3 in yes_ids:
				if m3 == target or gs.at_war(m3, target):
					continue
				gs.countries[m3].truce[target] = maxi(int(gs.countries[m3].truce.get(target, -1)), gs.turn + 26)
				gs.countries[target].truce[m3] = maxi(int(gs.countries[target].truce.get(m3, -1)), gs.turn + 26)
				gcount += 1
			return "%d ülke %s için 26 hafta saldırmazlık verdi." % [gcount, gs.countries[target].name]
		"embargo":
			var te = gs.countries[target]
			te.industry = maxf(3.0, te.industry - 10.0)
			te.logistics = maxf(3.0, te.logistics - 5.0)
			return "%s için silah ambargosu: sanayi ve lojistik zayıfladı." % te.name
		"probe":
			var tp = gs.countries[target]
			tp.stability = clampf(tp.stability - 9.0, 5.0, 100.0)
			tp.aggression = maxf(0.05, tp.aggression - 0.15)
			return "%s için uluslararası soruşturma: istikrar düştü, saldırganlık azaldı." % tp.name
		"disarm":
			for a3 in gs.armies_of(target):
				a3.size = maxi(1, int(a3.size * 0.88))
			return "%s ordusu yüzde 12 küçüldü." % gs.countries[target].name
		"sanction":
			var t3 = gs.countries[target]
			t3.sanction_until = gs.turn + 26
			return "%s için 26 haftalık yaptırım başladı." % t3.name
		_:
			var cands: Array = []
			for m in yes_ids:
				if m != target and not gs.is_allied(m, target) and not gs.at_war(m, target):
					cands.append(m)
			cands.sort_custom(func(a, b): return gs.countries[a].troops > gs.countries[b].troops)
			var n := 0
			for m2 in cands:
				if n >= MAX_ATTACKERS:
					break
				if gs.declare_war(m2, target):
					n += 1
			return "%d ülke savaş açtı. Hedef: %s." % [n, gs.countries[target].name]


## Yapay zekâ önergeleri: 26 haftada bir ateşkes ya da yardım.
static func weekly(gs) -> void:
	if gs.turn % 26 != 13 or not available(gs):
		return
	var cands: Array = []
	for i in gs.wars.size():
		var w = gs.wars[i]
		if w.involves(gs.player) or gs.countries[w.a].is_rebel or gs.countries[w.b].is_rebel:
			continue
		if gs.turn - w.start >= 20:
			cands.append(i)
	var mem: Array = members(gs)
	if mem.is_empty():
		return
	var proposer: int = mem[gs.rng.randi_range(0, mem.size() - 1)]
	if proposer == gs.player:
		return
	if not cands.is_empty() and gs.rng.randf() < 0.6:
		var wi: int = cands[gs.rng.randi_range(0, cands.size() - 1)]
		if gs.wars[wi].a == proposer or gs.wars[wi].b == proposer:
			return
		propose(gs, "ceasefire", proposer, wi)
		return
	var needy := -1
	var lo := 100.0
	for m in mem:
		var c = gs.countries[m]
		if c.stability < lo:
			lo = c.stability
			needy = m
	if needy >= 0 and lo < 35.0:
		propose(gs, "aid", proposer, needy)
