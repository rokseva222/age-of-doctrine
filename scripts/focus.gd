extends RefCounted
## Odak ağacı: oyuncu aynı anda tek bir "ulusal odak" yürütür; odak haftalar sürer, bitince kalıcı etki verir.
## Dört dal: Ekonomi, Askeri, Diplomasi, İç Siyaset. Önkoşullar ağaç gibi açılır. Durum: gs.focus {"done": [], "cur": "", "left": 0}

const Loc = preload("res://scripts/loc.gd")

const BRANCHES := [
	{"id": "eco", "tr": "Ekonomi", "en": "Economy", "icon": "coins"},
	{"id": "mil", "tr": "Askeri", "en": "Military", "icon": "swords"},
	{"id": "dip", "tr": "Diplomasi", "en": "Diplomacy", "icon": "handshake"},
	{"id": "pol", "tr": "İç Siyaset", "en": "Home Front", "icon": "stability"},
]

## fx anahtarları: gold (haftalık gelir x), fund (savunma fonu, gelir x), income (+% kalıcı gelir), stab, ind, logi, cyber (anlık puan),
## att, def, recruit (+% kalıcı çarpan), rel (tüm ülkelerle ilişki), infamy (dünya tepkisi)
const TREE := {
	"e1": {"b": "eco", "row": 0, "weeks": 6, "req": [], "tr": "Sanayi Seferberliği", "en": "Industrial Mobilization",
		"dtr": "Fabrikalar savaş ve barış üretimine yönlendirilir.", "den": "Factories are put on a production footing.",
		"fx": {"ind": 8, "income": 3}},
	"e2": {"b": "eco", "row": 1, "weeks": 8, "req": ["e1"], "tr": "Ticaret Anlaşmaları", "en": "Trade Agreements",
		"dtr": "Yeni pazarlar, yeni gümrük anlaşmaları.", "den": "New markets and customs deals.",
		"fx": {"income": 4, "rel": 3}},
	"e3": {"b": "eco", "row": 1, "weeks": 8, "req": ["e1"], "tr": "Liman ve Demiryolu", "en": "Ports and Railways",
		"dtr": "Altyapı yatırımı: ikmal hatları güçlenir.", "den": "Infrastructure spending strengthens supply lines.",
		"fx": {"logi": 10, "income": 3}},
	"e4": {"b": "eco", "row": 2, "weeks": 10, "req": ["e2", "e3"], "tr": "Ulusal Bankacılık", "en": "National Banking",
		"dtr": "Kamu bankaları kasaya hemen nakit akıtır.", "den": "State banks pour cash into the treasury.",
		"fx": {"gold": 6, "income": 4}},
	"e5": {"b": "eco", "row": 3, "weeks": 12, "req": ["e4"], "tr": "Ekonomik Mucize", "en": "Economic Miracle",
		"dtr": "Büyüme rekor kırar; sanayi ve gelir yükselir.", "den": "Record growth lifts industry and revenue.",
		"fx": {"income": 8, "ind": 10}},
	"m1": {"b": "mil", "row": 0, "weeks": 6, "req": [], "tr": "Askerlik Reformu", "en": "Conscription Reform",
		"dtr": "Daha geniş yedek asker havuzu.", "den": "A wider reserve pool.",
		"fx": {"recruit": 15}},
	"m2": {"b": "mil", "row": 1, "weeks": 8, "req": ["m1"], "tr": "Taarruz Doktrini", "en": "Offensive Doctrine",
		"dtr": "Ordular hızlı ve yoğun vuruş üzerine eğitilir.", "den": "Armies drill for fast, concentrated strikes.",
		"fx": {"att": 5}},
	"m3": {"b": "mil", "row": 1, "weeks": 8, "req": ["m1"], "tr": "Savunma Hatları", "en": "Defense Lines",
		"dtr": "Tahkimat ve derinlemesine savunma.", "den": "Fortification and defense in depth.",
		"fx": {"def": 6}},
	"m4": {"b": "mil", "row": 2, "weeks": 10, "req": ["m2", "m3"], "tr": "Silah Fonu", "en": "Arms Fund",
		"dtr": "Savunma fonuna büyük bir aktarım yapılır.", "den": "A large transfer into the defense fund.",
		"fx": {"fund": 8, "att": 3, "def": 3}},
	"m5": {"b": "mil", "row": 3, "weeks": 12, "req": ["m4"], "tr": "Seçkin Harp Okulları", "en": "Elite War Colleges",
		"dtr": "Kurmay kadrosu savaş sanatında bir üst seviyeye çıkar.", "den": "The staff corps reaches a new level.",
		"fx": {"att": 5, "def": 4, "recruit": 10}},
	"d1": {"b": "dip", "row": 0, "weeks": 6, "req": [], "tr": "Dışişleri Reformu", "en": "Foreign Ministry Reform",
		"dtr": "Büyükelçilikler yeniden örgütlenir; imajın düzelir.", "den": "Embassies are reorganized and your image improves.",
		"fx": {"rel": 4, "infamy": 8}},
	"d2": {"b": "dip", "row": 1, "weeks": 8, "req": ["d1"], "tr": "Çok Taraflı Diplomasi", "en": "Multilateral Diplomacy",
		"dtr": "Her masada sesin duyulur.", "den": "Your voice is heard at every table.",
		"fx": {"rel": 5, "stab": 2}},
	"d3": {"b": "dip", "row": 1, "weeks": 8, "req": ["d1"], "tr": "Casusluk Ağı", "en": "Spy Network",
		"dtr": "İstihbarat teşkilatı genişler; siber olgunluk artar.", "den": "Intelligence expands; cyber maturity grows.",
		"fx": {"cyber": 10, "spycd": 1}},
	"d4": {"b": "dip", "row": 2, "weeks": 10, "req": ["d2", "d3"], "tr": "Nüfuz Alanı", "en": "Sphere of Influence",
		"dtr": "Komşularda nüfuz kurarsın: nakit ve ilişki gelir.", "den": "Influence among neighbors brings cash and goodwill.",
		"fx": {"gold": 3, "rel": 4, "infamy": 10}},
	"d5": {"b": "dip", "row": 3, "weeks": 12, "req": ["d4"], "tr": "Küresel Lider", "en": "Global Leader",
		"dtr": "Dünya liderler arasında seni sayar.", "den": "The world counts you among its leaders.",
		"fx": {"rel": 6, "income": 3, "infamy": 15}},
	"p1": {"b": "pol", "row": 0, "weeks": 6, "req": [], "tr": "Halk Birliği", "en": "National Unity",
		"dtr": "Ortak hedef, ortak umut.", "den": "A shared goal, a shared hope.",
		"fx": {"stab": 6}},
	"p2": {"b": "pol", "row": 1, "weeks": 8, "req": ["p1"], "tr": "Eğitim Seferberliği", "en": "Education Drive",
		"dtr": "Okullar ve üniversiteler genişler.", "den": "Schools and universities expand.",
		"fx": {"ind": 4, "income": 2, "stab": 2}},
	"p3": {"b": "pol", "row": 1, "weeks": 8, "req": ["p1"], "tr": "Sosyal Güvence", "en": "Social Security",
		"dtr": "Sağlık ve emeklilik: halk devletine bağlanır.", "den": "Healthcare and pensions tie the people to the state.",
		"fx": {"stab": 5, "income": 2}},
	"p4": {"b": "pol", "row": 2, "weeks": 10, "req": ["p2", "p3"], "tr": "Ulusal Kimlik", "en": "National Identity",
		"dtr": "Ortak kimlik, güçlü bir halk ordusu.", "den": "A shared identity and a strong people's army.",
		"fx": {"stab": 6, "recruit": 10}},
	"p5": {"b": "pol", "row": 3, "weeks": 12, "req": ["p4"], "tr": "Altın Çağ", "en": "Golden Age",
		"dtr": "Refah, istikrar ve özgüven.", "den": "Prosperity, stability and confidence.",
		"fx": {"stab": 8, "income": 5, "att": 3, "def": 3}},
}

const FX_NAME := {
	"gold": ["Hazineye nakit", "Treasury cash"], "fund": ["Savunma fonu", "Defense fund"], "income": ["Gelir", "Income"],
	"stab": ["İstikrar", "Stability"], "ind": ["Sanayi", "Industry"], "logi": ["Lojistik", "Logistics"], "cyber": ["Siber", "Cyber"],
	"att": ["Taarruz", "Attack"], "def": ["Savunma", "Defense"], "recruit": ["Asker toplama", "Recruitment"],
	"rel": ["Dünya ilişkileri", "World relations"], "infamy": ["Dünya tepkisi", "World backlash"], "spycd": ["Casus bekleme", "Spy cooldown"],
}


static func _t(tr: String, en: String) -> String:
	return en if Loc.lang != "tr" else tr


static func nm(id: String) -> String:
	var d: Dictionary = TREE[id]
	return _t(d.tr, d.en)


static func desc(id: String) -> String:
	var d: Dictionary = TREE[id]
	return _t(d.dtr, d.den)


static func branch_name(b: Dictionary) -> String:
	return _t(b.tr, b.en)


static func ensure(gs) -> void:
	if not (gs.focus is Dictionary) or gs.focus.is_empty():
		gs.focus = {"done": [], "cur": "", "left": 0}


static func is_done(gs, id: String) -> bool:
	ensure(gs)
	return (gs.focus.done as Array).has(id)


static func can_start(gs, id: String) -> String:
	ensure(gs)
	if gs.player < 0:
		return _t("Oyuncu yok.", "No player.")
	if is_done(gs, id):
		return _t("Zaten tamamlandı.", "Already completed.")
	if String(gs.focus.cur) != "":
		return _t("Önce yürüyen odak bitmeli.", "Finish or cancel the current focus first.")
	for r in TREE[id].req:
		if not is_done(gs, String(r)):
			return _t("Önkoşul eksik: ", "Missing prerequisite: ") + nm(String(r))
	return ""


static func start(gs, id: String) -> String:
	var err := can_start(gs, id)
	if err != "":
		return err
	gs.focus.cur = id
	gs.focus.left = int(TREE[id].weeks)
	gs.post_news(_t("Yeni ulusal odak: %s (%d hafta).", "New national focus: %s (%d weeks).") % [nm(id), int(TREE[id].weeks)], gs.countries[gs.player].capital, "info")
	return ""


static func cancel(gs) -> void:
	ensure(gs)
	gs.focus.cur = ""
	gs.focus.left = 0


static func income_mult(gs) -> float:
	ensure(gs)
	var s := 0.0
	for id in gs.focus.done:
		s += float(TREE[String(id)].fx.get("income", 0))
	return 1.0 + s / 100.0


static func tick(gs) -> void:
	ensure(gs)
	var id := String(gs.focus.cur)
	if id == "" or gs.player < 0:
		return
	gs.focus.left = int(gs.focus.left) - 1
	if int(gs.focus.left) > 0:
		return
	gs.focus.cur = ""
	gs.focus.left = 0
	(gs.focus.done as Array).append(id)
	_apply(gs, id)
	gs.post_news(_t("Odak tamamlandı: %s — %s", "Focus completed: %s — %s") % [nm(id), fx_text(id)], gs.countries[gs.player].capital, "peace")


static func _mul_buff(c, key: String, pct: float) -> void:
	var cur := 1.0
	var b = c.buffs.get(key)
	if b != null:
		cur = float(b[0])
	c.buffs[key] = [cur * (1.0 + pct / 100.0), 999999]


static func _apply(gs, id: String) -> void:
	var c = gs.countries[gs.player]
	var fx: Dictionary = TREE[id].fx
	for k in fx:
		var v: float = float(fx[k])
		match k:
			"gold": c.gold += v * maxf(c.income, 1.0)
			"fund": c.fund += v * maxf(c.income, 1.0)
			"stab": c.stability = clampf(c.stability + v, 0.0, 100.0)
			"ind": c.industry = clampf(c.industry + v, 0.0, 100.0)
			"logi": c.logistics = clampf(c.logistics + v, 0.0, 100.0)
			"cyber": c.cyber = clampf(c.cyber + v, 0.0, 100.0)
			"att", "def", "recruit": _mul_buff(c, String(k), v)
			"rel":
				for o in gs.countries:
					if o.alive and o.id != c.id:
						var cur: float = float(c.relation.get(o.id, 50.0))
						c.relation[o.id] = clampf(cur + v, 0.0, 100.0)
						o.relation[c.id] = clampf(float(o.relation.get(c.id, 50.0)) + v, 0.0, 100.0)
			"infamy": gs.infamy = maxf(0.0, gs.infamy - v)
			"spycd": gs.spy_cd = {}


## Etkilerin kısa metni ("Gelir +%4, İstikrar +2")
static func fx_text(id: String) -> String:
	var parts: Array = []
	var fx: Dictionary = TREE[id].fx
	for k in fx:
		var v: int = int(fx[k])
		var nmk: String = _t(FX_NAME[k][0], FX_NAME[k][1])
		match k:
			"gold", "fund": parts.append("%s +%d×" % [nmk, v] + _t(" haftalık gelir", " weekly income"))
			"income", "att", "def", "recruit": parts.append("%s +%%%d" % [nmk, v])
			"infamy": parts.append("%s −%d" % [nmk, v])
			"spycd": parts.append(nmk + " " + _t("sıfırlanır", "reset"))
			_: parts.append("%s +%d" % [nmk, v])
	return ", ".join(parts)
