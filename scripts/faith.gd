extends RefCounted
## DİN: her eyaletin bir inancı (mezhebi) vardır; komşu ve devlet baskısıyla zamanla yayılır.
## 14 inanç / mezhep, 7 aile: Hristiyanlık (Katolik, Protestan, Ortodoks, Doğu), İslam (Sünni, Şii, İbadi),
## Dharmik (Hindu, Budist, Sih), Doğu Asya (Şinto, Çin halk dinleri), Yahudilik, Geleneksel inançlar, Seküler.
## Aynı ailenin başka mezhebi "yarı yabancı", başka ailenin inancı "yabancı" sayılır.
## Din dayatma barış şartı ve toplu dönüştürme bu sistemi kullanır. Durum gs.faith içinde saklanır (kayda girer).

const Loc = preload("res://scripts/loc.gd")
const Eras = preload("res://scripts/eras.gd")
const Icons = preload("res://scripts/icons.gd")

## kod: [aile, Türkçe ad, İngilizce ad]
const FAITHS := {
	"catholic": ["christian", "Katoliklik", "Catholicism"],
	"protestant": ["christian", "Protestanlık", "Protestantism"],
	"orthodox": ["christian", "Ortodoksluk", "Orthodoxy"],
	"oriental": ["christian", "Doğu Hristiyanlığı", "Oriental Christianity"],
	"sunni": ["islam", "Sünni İslam", "Sunni Islam"],
	"shia": ["islam", "Şii İslam", "Shia Islam"],
	"ibadi": ["islam", "İbadi İslam", "Ibadi Islam"],
	"hindu": ["dharmic", "Hinduizm", "Hinduism"],
	"buddhist": ["dharmic", "Budizm", "Buddhism"],
	"sikh": ["dharmic", "Sihizm", "Sikhism"],
	"shinto": ["eastasian", "Şintoizm", "Shinto"],
	"chinese": ["eastasian", "Çin halk dinleri", "Chinese folk religion"],
	"judaism": ["judaic", "Yahudilik", "Judaism"],
	"animism": ["folk", "Geleneksel inançlar", "Traditional beliefs"],
	"secular": ["secular", "Dinsiz / seküler", "Irreligious"],
}
## Eski kayıtlardaki 4 genel kod → yeni mezhep (eyaletin ev ülkesine göre incelenir)
const LEGACY := {"christian": "catholic", "islam": "sunni", "dharmic": "hindu", "other": "animism"}
## Aile → eski simge adı (faith_christian_c.png gibi dosyalar zaten var)
const FAMILY_ICON := {"christian": "faith_christian", "islam": "faith_islam", "dharmic": "faith_dharmic", "eastasian": "faith_other", "judaic": "faith_other", "folk": "faith_other", "secular": "faith_other"}
const SPREAD_EVERY := 4          # hafta

const COUNTRY := {
	"catholic": ["Italy", "Spain", "Portugal", "France", "Poland", "Ireland", "Austria", "Belgium", "Croatia", "Slovenia", "Slovakia", "Hungary", "Lithuania", "Malta", "Luxembourg",
		"Andorra", "Monaco", "Liechtenstein", "San Marino", "Vatican", "Mexico", "Guatemala", "Honduras", "El Salvador", "Nicaragua", "Costa Rica", "Panama", "Cuba", "Dominican Rep.",
		"Haiti", "Colombia", "Venezuela", "Ecuador", "Peru", "Bolivia", "Paraguay", "Uruguay", "Argentina", "Chile", "Brazil", "Philippines", "Timor-Leste", "East Timor", "Angola",
		"Mozambique", "Dem. Rep. Congo", "Congo", "Rwanda", "Burundi", "Gabon", "Eq. Guinea", "Central African Rep.", "Uganda", "Cameroon", "Madagascar", "Lesotho", "Kiribati",
		"Belize", "Saint Lucia", "Cabo Verde", "São Tomé and Principe", "Seychelles", "Micronesia", "Palau", "Grenada", "Dominica", "S. Sudan", "Benin", "Guinea-Bissau", "Togo"],
	"protestant": ["United Kingdom", "Germany", "Netherlands", "Denmark", "Norway", "Sweden", "Finland", "Iceland", "Latvia", "United States of America", "Canada", "Australia",
		"New Zealand", "South Africa", "Namibia", "Botswana", "Zimbabwe", "Zambia", "Malawi", "Kenya", "Tanzania", "Ghana", "Nigeria", "Liberia", "Papua New Guinea", "Fiji",
		"Solomon Is.", "Vanuatu", "Samoa", "Tonga", "Jamaica", "Bahamas", "Barbados", "Guyana", "Suriname", "Trinidad and Tobago", "Switzerland", "South Korea", "eSwatini",
		"Saint Vincent and the Grenadines", "Antigua and Barbuda", "Saint Kitts and Nevis", "Marshall Is.", "Tuvalu", "Nauru"],
	"orthodox": ["Russia", "Ukraine", "Belarus", "Serbia", "Bulgaria", "Romania", "Greece", "Cyprus", "Georgia", "Moldova", "North Macedonia", "Montenegro"],
	"oriental": ["Ethiopia", "Eritrea", "Armenia"],
	"sunni": ["Turkey", "Saudi Arabia", "Egypt", "Pakistan", "Bangladesh", "Afghanistan", "Algeria", "Morocco", "Tunisia", "Libya", "Sudan", "Jordan", "Uzbekistan", "Turkmenistan",
		"Tajikistan", "Kyrgyzstan", "Kazakhstan", "Indonesia", "Malaysia", "Somalia", "Somaliland", "Mauritania", "Senegal", "Mali", "Niger", "Chad", "Gambia", "Guinea",
		"Djibouti", "Kosovo", "Albania", "Bosnia and Herz.", "Brunei", "Maldives", "Comoros", "W. Sahara", "Palestine", "Kuwait", "Qatar", "United Arab Emirates", "Syria",
		"N. Cyprus", "Northern Cyprus", "Burkina Faso", "Sierra Leone", "Yemen", "Côte d'Ivoire", "Lebanon", "Iraq"],
	"shia": ["Iran", "Azerbaijan", "Bahrain"],
	"ibadi": ["Oman"],
	"hindu": ["India", "Nepal", "Mauritius"],
	"buddhist": ["Thailand", "Cambodia", "Laos", "Myanmar", "Mongolia", "Sri Lanka", "Bhutan", "Vietnam"],
	"shinto": ["Japan"],
	"chinese": ["China", "Taiwan", "Singapore"],
	"judaism": ["Israel"],
	"secular": ["North Korea", "Czechia", "Estonia"],
}
## Karışık ülkeler: eyaletler eksene göre (x: batı→doğu, y: kuzey→güney) sıralanıp dilimlere bölünür; [üst sınır oranı, inanç]
const SPLIT := {
	"Germany": {"axis": "y", "segs": [[0.58, "protestant"], [1.0, "catholic"]]},
	"Netherlands": {"axis": "y", "segs": [[0.55, "protestant"], [1.0, "catholic"]]},
	"Switzerland": {"axis": "x", "segs": [[0.45, "protestant"], [1.0, "catholic"]]},
	"Canada": {"axis": "x", "segs": [[0.72, "protestant"], [1.0, "catholic"]]},
	"South Korea": {"axis": "y", "segs": [[0.55, "protestant"], [1.0, "buddhist"]]},
	"Nigeria": {"axis": "y", "segs": [[0.5, "sunni"], [1.0, "protestant"]]},
	"Côte d'Ivoire": {"axis": "y", "segs": [[0.45, "sunni"], [1.0, "catholic"]]},
	"Ethiopia": {"axis": "x", "segs": [[0.6, "oriental"], [1.0, "sunni"]]},
	"Lebanon": {"axis": "y", "segs": [[0.3, "sunni"], [0.65, "catholic"], [1.0, "shia"]]},
	"Iraq": {"axis": "y", "segs": [[0.4, "sunni"], [1.0, "shia"]]},
	"Yemen": {"axis": "y", "segs": [[0.4, "shia"], [1.0, "sunni"]]},
	"Benin": {"axis": "y", "segs": [[0.3, "sunni"], [0.7, "catholic"], [1.0, "animism"]]},
	"Chad": {"axis": "y", "segs": [[0.55, "sunni"], [1.0, "protestant"]]},
	"Ghana": {"axis": "y", "segs": [[0.2, "sunni"], [1.0, "protestant"]]},
	"Cameroon": {"axis": "y", "segs": [[0.2, "sunni"], [1.0, "catholic"]]},
	"Mozambique": {"axis": "y", "segs": [[0.3, "sunni"], [1.0, "catholic"]]},
	"Togo": {"axis": "y", "segs": [[0.25, "sunni"], [1.0, "animism"]]},
	"Guinea-Bissau": {"axis": "y", "segs": [[0.5, "sunni"], [1.0, "animism"]]},
	"Eq. Guinea": {"axis": "y", "segs": [[1.0, "catholic"]]},
}
## İl adına göre özel durumlar (alt dize, harf büyüklüğü önemsiz)
const NAME_OVR := {
	"India": {"Ludhiana": "sikh", "Srinagar": "sunni", "Ladakh": "buddhist", "Nagaland": "protestant", "Mizoram": "protestant", "Meghalaya": "protestant", "Sikkim": "buddhist"},
	"Russia": {"Chechnya": "sunni", "Ingush": "sunni", "Karachay": "sunni", "Kabardin": "sunni", "Adygey": "sunni", "Kazan": "sunni", "Ufa": "sunni", "Buryat": "buddhist", "Kalmyk": "buddhist", "Tuva": "buddhist"},
	"Indonesia": {"Bali": "hindu", "Papua": "protestant", "Nusa Tenggara Timur": "catholic", "Maluku": "protestant", "Sulawesi Utara": "protestant"},
	"Tanzania": {"Zanzibar": "sunni", "Pemba": "sunni", "Unguja": "sunni"},
	"Germany": {"Münih": "catholic", "Rheinland": "catholic", "Saarland": "catholic", "Essen": "catholic", "Stuttgart": "catholic", "Frankfurt": "protestant"},
	"Philippines": {"Maguindanao": "sunni", "Lanao del Sur": "sunni"},
	"Iran": {},
}


static func _tr() -> bool:
	return Loc.lang == "tr"


static func family_of(k: String) -> String:
	if FAITHS.has(k):
		return String(FAITHS[k][0])
	if LEGACY.has(k):
		return k if k != "other" else "folk"
	return "folk"


static func name_of(k: String) -> String:
	if not FAITHS.has(k):
		k = String(LEGACY.get(k, "animism"))
	return Loc.t(String(FAITHS[k][1])) if not _tr() else String(FAITHS[k][1])


## Simge adı: faith_<kod> (varsa) → faith_<aile> → faith
static func icon(k: String) -> String:
	if not FAITHS.has(k):
		k = String(LEGACY.get(k, "animism"))
	return Icons.pick("faith_" + k, Icons.pick(String(FAMILY_ICON.get(family_of(k), "faith_other")), "faith"))


static func _base_code(n: String, continent: String) -> String:
	for code in COUNTRY:
		if (COUNTRY[code] as Array).has(n):
			return code
	match continent:
		"Europe", "North America", "South America":
			return "catholic"
		"Oceania":
			return "protestant"
		"Asia":
			return "buddhist"
	return "animism"


## Çağa göre düzeltme: Reform öncesi Protestan yok, Amerika/Okyanusya yerli inançlar, 1380'de İran/Azerbaycan Sünni...
static func _era_adjust(code: String, n: String, continent: String) -> String:
	if Eras.current == "":
		return code
	var fam: String = Eras.family()
	if code == "secular":
		code = "catholic" if continent == "Europe" else "buddhist"
	if fam == "pre":
		if code == "protestant":
			code = "catholic"
		if code == "sikh":
			code = "hindu"
		if code == "judaism":
			code = "sunni"
		if ["tim1380", "ott1299", "ott1453"].has(Eras.current) and code == "shia" and n in ["Iran", "Azerbaijan"]:
			code = "sunni"
		if continent in ["North America", "South America", "Oceania"]:
			code = "animism"
		if continent == "Africa" and code in ["catholic", "protestant"]:
			code = "animism"
	return code


static var _upg_id := -1


static func ensure(gs) -> void:
	if not gs.faith.is_empty():
		_upgrade(gs)
		return
	_upg_id = gs.get_instance_id()
	var groups: Dictionary = {}
	for p in gs.provinces:
		var cid: int = p.home if p.home >= 0 else p.owner
		if cid < 0:
			continue
		if not groups.has(cid):
			groups[cid] = []
		(groups[cid] as Array).append(p.id)
	for cid in groups:
		var c = gs.countries[cid]
		var n: String = String(c.name_en)
		var pids: Array = groups[cid]
		var spl = SPLIT.get(n)
		var order: Array = pids.duplicate()
		if spl != null:
			var ax: String = String(spl["axis"])
			order.sort_custom(func(a, b):
				var pa: Vector2 = gs.provinces[a].label_pos
				var pb: Vector2 = gs.provinces[b].label_pos
				return (pa.x < pb.x) if ax == "x" else (pa.y < pb.y))
		for i in order.size():
			var pid: int = order[i]
			var code: String = _base_code(n, String(c.continent))
			if spl != null:
				var f: float = (float(i) + 0.5) / float(order.size())
				for seg in spl["segs"]:
					if f <= float(seg[0]):
						code = String(seg[1])
						break
			if NAME_OVR.has(n):
				var nm: String = String(gs.provinces[pid].name)
				for key in NAME_OVR[n]:
					if nm.findn(String(key)) >= 0:
						code = String(NAME_OVR[n][key])
			gs.faith[str(pid)] = _era_adjust(code, n, String(c.continent))


## Eski kayıttaki genel kodlar ("christian", "islam"...) ev ülkesine göre mezhebe çevrilir (oyun başına bir kez).
static func _upgrade(gs) -> void:
	if _upg_id == gs.get_instance_id():
		return
	_upg_id = gs.get_instance_id()
	var bad: Array = []
	for k in gs.faith:
		if LEGACY.has(String(gs.faith[k])):
			bad.append(k)
	if bad.is_empty():
		return
	for k in bad:
		var pid := int(k)
		var p = gs.provinces[pid]
		var cid: int = p.home if p.home >= 0 else p.owner
		var c = gs.countries[cid] if cid >= 0 else null
		var legacy: String = String(gs.faith[k])
		var code: String = String(LEGACY[legacy])
		if c != null:
			var b: String = _base_code(String(c.name_en), String(c.continent))
			if family_of(b) == family_of(code):
				code = b
			elif legacy == "other" and not b in ["catholic", "protestant", "orthodox", "oriental", "sunni", "shia", "ibadi", "hindu", "sikh"]:
				code = b if b != "buddhist" or family_of(b) == "dharmic" else code
		gs.faith[k] = code


static func of(gs, pid: int) -> String:
	ensure(gs)
	var k := str(pid)
	if not gs.faith.has(k):
		var o: int = gs.provinces[pid].owner
		var c = gs.countries[o] if o >= 0 else null
		gs.faith[k] = _base_code(String(c.name_en), String(c.continent)) if c != null else "animism"
	return String(gs.faith[k])


static func default_for(c) -> String:
	return _base_code(String(c.name_en), String(c.continent))


## Ülkenin devlet inancı: başkentinin inancı
static func state_faith(gs, cid: int) -> String:
	var c = gs.countries[cid]
	if c.capital >= 0:
		return of(gs, c.capital)
	return default_for(c)


## Yabancılık ağırlığı: aynı inanç 0, aynı ailenin başka mezhebi 0,4, başka aile 1
static func _weight(a: String, b: String) -> float:
	if a == b:
		return 0.0
	return 0.4 if family_of(a) == family_of(b) else 1.0


## Yabancı inançlı eyalet payı (mezhep farkı yarım ağırlıkla sayılır)
static func foreign_share(gs, cid: int) -> float:
	var c = gs.countries[cid]
	if c.owned_ids.is_empty():
		return 0.0
	var sf := state_faith(gs, cid)
	var n := 0.0
	for pid in c.owned_ids:
		n += _weight(of(gs, pid), sf)
	return n / float(c.owned_ids.size())


## Devlet inancıyla aynı inançtaki eyalet payı (dini birlik)
static func unity(gs, cid: int) -> float:
	var c = gs.countries[cid]
	if c.owned_ids.is_empty():
		return 0.0
	var sf := state_faith(gs, cid)
	var n := 0
	for pid in c.owned_ids:
		if of(gs, pid) == sf:
			n += 1
	return float(n) / float(c.owned_ids.size())


static var _mult_turn := -1
static var _mult_gs := -1
static var _mult: Dictionary = {}


static func invalidate() -> void:
	_mult_turn = -1


## Gelir çarpanı: dini birlik +%4'e kadar, yabancı inanç payı −%7'ye kadar
static func income_mult(gs, c) -> float:
	if _mult_turn != gs.turn or _mult_gs != gs.get_instance_id():
		_mult.clear()
		_mult_turn = gs.turn
		_mult_gs = gs.get_instance_id()
	if _mult.has(c.id):
		return float(_mult[c.id])
	var m := 1.0
	if not c.owned_ids.is_empty() and not c.is_rebel:
		m = clampf(1.0 + 0.04 * unity(gs, c.id) - 0.07 * foreign_share(gs, c.id), 0.93, 1.04)
	_mult[c.id] = m
	return m


## Her 4 haftada: eyaletler komşu ve devlet baskısıyla inanç değiştirir.
static func tick(gs) -> void:
	if gs.player < 0:
		return
	ensure(gs)
	var changes: Array = []
	var slot: int = gs.turn % SPREAD_EVERY       # eyaletlerin 1/4'ü her turda (4 haftalık tek seferlik yük/donma yerine)
	for p in gs.provinces:
		if p.id % SPREAD_EVERY != slot:
			continue
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
		var bv: float = float(press.get(cur, 0.0)) + 0.35     # atalet (mezhepler direnir)
		for f2 in press.keys():
			if f2 != cur and float(press[f2]) > bv:
				best = f2
				bv = float(press[f2])
		if best == cur:
			continue
		# yavaş: eşiği aşan eyalet bile sadece olasılıkla döner; başka aileye geçiş mezhep değişiminden zordur
		if gs.rng.randf() < (0.12 if family_of(best) == family_of(cur) else 0.05):
			changes.append([p.id, best])
	var told := 0
	for ch in changes:
		var pid: int = ch[0]
		var old := of(gs, pid)
		gs.faith[str(pid)] = ch[1]
		var pr = gs.provinces[pid]
		if told < 2 and (pr.owner == gs.player or pr.controller == gs.player or gs.rng.randf() < 0.25):
			told += 1
			var msg_tr := "%s eyaletinde halk yavaş yavaş %s inancına geçiyor." % [pr.name, FAITHS[ch[1]][1]]
			var msg_en := "%s: the people are gradually turning to %s." % [pr.name, FAITHS[ch[1]][2]]
			gs.post_news(msg_tr if _tr() else msg_en, pid, "info")
		if pr.owner == gs.player and ch[1] != old:
			pass
	if slot != 0:
		if not changes.is_empty():
			invalidate()
			gs.province_changed.emit(changes[0][0])
		return
	# yabancı inanç payı yüksekse istikrar yavaşça aşınır (oyuncu)
	var me = gs.countries[gs.player]
	var fs := foreign_share(gs, gs.player)
	if fs > 0.4:
		me.stability = clampf(me.stability - 0.25 * (fs - 0.4) * 4.0, 5.0, 100.0)
	if unity(gs, gs.player) >= 0.85:
		me.stability = clampf(me.stability + 0.3, 5.0, 100.0)      # dini birlik: istikrar yavaşça pekişir
	if not changes.is_empty():
		invalidate()
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
	invalidate()
	countries_unrest(gs, loser)
	return n


static func countries_unrest(gs, cid: int) -> void:
	var c = gs.countries[cid]
	c.stability = clampf(c.stability - 6.0, 5.0, 100.0)
