extends RefCounted
## DİN: her eyaletin bir inancı vardır; komşu ve devlet baskısıyla zamanla yayılır (İslam, Hristiyanlık, Dharmik inançlar).
## Din dayatma barış şartı bu sistemi kullanır. Durum gs.faith içinde saklanır (kayda girer).

const Loc = preload("res://scripts/loc.gd")

const KINDS := ["christian", "islam", "dharmic", "other"]
const NAME_TR := {"christian": "Hristiyanlık", "islam": "İslam", "dharmic": "Dharmik inançlar", "other": "Diğer inançlar"}
const NAME_EN := {"christian": "Christianity", "islam": "Islam", "dharmic": "Dharmic faiths", "other": "Other beliefs"}
const SPREAD_EVERY := 4          # hafta
const MUSLIM := ["Turkey", "Iran", "Iraq", "Syria", "Saudi Arabia", "Egypt", "Pakistan", "Bangladesh", "Afghanistan", "Algeria", "Morocco", "Tunisia", "Libya",
	"Sudan", "Yemen", "Oman", "United Arab Emirates", "Qatar", "Kuwait", "Jordan", "Azerbaijan", "Uzbekistan", "Turkmenistan", "Tajikistan", "Kyrgyzstan",
	"Kazakhstan", "Indonesia", "Malaysia", "Somalia", "Mauritania", "Senegal", "Mali", "Niger", "Chad", "Gambia", "Guinea", "Djibouti", "Kosovo", "Albania",
	"Bosnia and Herz.", "Brunei", "Maldives", "Comoros", "W. Sahara", "Palestine", "Lebanon", "Bahrain", "Northern Cyprus", "N. Cyprus"]
const DHARMIC := ["India", "Nepal", "Bhutan", "Sri Lanka", "Thailand", "Cambodia", "Laos", "Myanmar", "Mongolia", "Vietnam", "Japan", "Taiwan"]
const CHRISTIAN_AFRICA := ["Ethiopia", "Kenya", "Uganda", "Tanzania", "Zambia", "Zimbabwe", "South Africa", "Angola", "Mozambique", "Malawi", "Congo", "Dem. Rep. Congo",
	"Rwanda", "Burundi", "Namibia", "Botswana", "Lesotho", "eSwatini", "Ghana", "Cameroon", "Gabon", "Central African Rep.", "Eritrea", "South Sudan", "Madagascar"]


static func _tr() -> bool:
	return Loc.lang == "tr"


static func name_of(k: String) -> String:
	return String(NAME_TR[k]) if _tr() else String(NAME_EN[k])


static func default_for(c) -> String:
	var n: String = String(c.name_en)
	if MUSLIM.has(n):
		return "islam"
	if DHARMIC.has(n):
		return "dharmic"
	match String(c.continent):
		"Europe", "North America", "South America", "Oceania":
			return "christian"
		"Africa":
			return "christian" if CHRISTIAN_AFRICA.has(n) else "islam"
		"Asia":
			return "christian" if n in ["Georgia", "Armenia", "Philippines", "Cyprus", "East Timor", "Timor-Leste"] else "other"
	return "other"


static func ensure(gs) -> void:
	if not gs.faith.is_empty():
		return
	for p in gs.provinces:
		if p.owner >= 0:
			gs.faith[str(p.id)] = default_for(gs.countries[p.owner])


static func of(gs, pid: int) -> String:
	ensure(gs)
	var k := str(pid)
	if not gs.faith.has(k):
		var o: int = gs.provinces[pid].owner
		gs.faith[k] = default_for(gs.countries[o]) if o >= 0 else "other"
	return String(gs.faith[k])


## Ülkenin devlet inancı: başkentinin inancı
static func state_faith(gs, cid: int) -> String:
	var c = gs.countries[cid]
	if c.capital >= 0:
		return of(gs, c.capital)
	return default_for(c)


## Yabancı inançlı eyalet payı
static func foreign_share(gs, cid: int) -> float:
	var c = gs.countries[cid]
	if c.owned_ids.is_empty():
		return 0.0
	var sf := state_faith(gs, cid)
	var n := 0
	for pid in c.owned_ids:
		if of(gs, pid) != sf:
			n += 1
	return float(n) / float(c.owned_ids.size())


## Her 4 haftada: eyaletler komşu ve devlet baskısıyla inanç değiştirir.
static func tick(gs) -> void:
	if gs.turn % SPREAD_EVERY != 0 or gs.player < 0:
		return
	ensure(gs)
	var changes: Array = []
	for p in gs.provinces:
		if p.owner < 0 or p.controller < 0:
			continue
		var cur := of(gs, p.id)
		var press := {}
		for nb in p.neighbors:
			var f := of(gs, nb)
			press[f] = float(press.get(f, 0.0)) + 1.0 / maxf(1.0, float(p.neighbors.size()))
		var sf := state_faith(gs, p.controller)
		press[sf] = float(press.get(sf, 0.0)) + 0.6          # devlet baskısı
		var best := cur
		var bv: float = float(press.get(cur, 0.0)) + 0.25     # atalet
		for f2 in press.keys():
			if f2 != cur and float(press[f2]) > bv:
				best = f2
				bv = float(press[f2])
		if best == cur:
			continue
		# yavaş: eşiği aşan eyalet bile sadece olasılıkla döner
		if gs.rng.randf() < 0.12:
			changes.append([p.id, best])
	var told := 0
	for ch in changes:
		var pid: int = ch[0]
		var old := of(gs, pid)
		gs.faith[str(pid)] = ch[1]
		var pr = gs.provinces[pid]
		if told < 2 and (pr.owner == gs.player or pr.controller == gs.player or gs.rng.randf() < 0.25):
			told += 1
			var msg_tr := "%s eyaletinde halk yavaş yavaş %s inancına geçiyor." % [pr.name, NAME_TR[ch[1]]]
			var msg_en := "%s: the people are gradually turning to %s." % [pr.name, NAME_EN[ch[1]]]
			gs.post_news(msg_tr if _tr() else msg_en, pid, "info")
		if pr.owner == gs.player and ch[1] != old:
			pass
	# yabancı inanç payı yüksekse istikrar yavaşça aşınır (oyuncu)
	var me = gs.countries[gs.player]
	var fs := foreign_share(gs, gs.player)
	if fs > 0.4:
		me.stability = clampf(me.stability - 0.25 * (fs - 0.4) * 4.0, 5.0, 100.0)
	if not changes.is_empty():
		gs.province_changed.emit(changes[0][0])


## Barış şartı: din dayatma. Yenilenin eyaletleri ve işgal edilen topraklar galibin inancına geçer.
static func impose(gs, winner: int, loser: int) -> int:
	ensure(gs)
	var wf := state_faith(gs, winner)
	var n := 0
	for pid in gs.countries[loser].owned_ids:
		if of(gs, pid) != wf:
			gs.faith[str(pid)] = wf
			n += 1
	countries_unrest(gs, loser)
	return n


static func countries_unrest(gs, cid: int) -> void:
	var c = gs.countries[cid]
	c.stability = clampf(c.stability - 6.0, 5.0, 100.0)
