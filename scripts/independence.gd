extends RefCounted
## BAĞIMSIZLIK YOLU: kurgusal bir hareketle bağımsızlığa giden, ayrı bir oyun kipi.
## Evreler: 0 Kıvılcım (gizli örgütlenme) → 1 Ayaklanma → 2 Müzakere → 3 Devlet Kurma → 4 Konsolidasyon (zafer).
## Ölçüler: halk desteği, gizlilik, meşruiyet (uluslararası itibar), bağımlılık (destekçilerin şartlı yardımları).
## Yabancı destek ideolojiye göre değişir; her yardımın şartı vardır. Rakip gruplarla ittifak/birleşme/rekabet olur.
## Gerçek örgüt adı/sembolü yoktur; her şey kurgusaldır. Durum gs.indep içinde saklanır (kayda girer).

const Loc = preload("res://scripts/loc.gd")
const Icons = preload("res://scripts/icons.gd")
const Macro = preload("res://scripts/macro.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Districts = preload("res://scripts/districts.gd")

const PHASE_TR := ["Kıvılcım", "Ayaklanma", "Müzakere", "Devlet Kurma", "Konsolidasyon"]
const PHASE_EN := ["Spark", "Uprising", "Negotiation", "Statehood", "Consolidation"]
const PHASE_GOAL_TR := [
	"Halk desteğini ve gizliliği koru; hazır olunca ayaklanmayı başlat.",
	"Eyaletlerini koru ve genişlet; yabancı destek ve meşruiyet topla.",
	"Ateşkes yap ve referandumla halkın iradesini göster.",
	"Anayasanı seç, 5+ ülkenin tanımasını sağla, BM'ye başvur.",
	"52 hafta boyunca istikrarı 50 üzerinde tut, bağımlılığı 3'ün altında tut.",
]
const PHASE_GOAL_EN := [
	"Keep popular support and secrecy; start the uprising when ready.",
	"Hold and expand your provinces; gather foreign support and legitimacy.",
	"Make a ceasefire and show the people's will with a referendum.",
	"Choose your constitution, win recognition from 5+ countries, apply to the UN.",
	"Keep stability above 50 and dependency below 3 for 52 weeks.",
]
const IDEOS := ["liberal", "social", "national", "traditional", "federal", "techno"]
const IDEO_TR := {"liberal": "Liberal-demokrat", "social": "Sosyal-işçi", "national": "Ulusal-muhafazakâr", "traditional": "Gelenekçi-dinî", "federal": "Federalist-özerkçi", "techno": "Teknokrat-reformcu"}
const IDEO_EN := {"liberal": "Liberal-democratic", "social": "Social-labor", "national": "National-conservative", "traditional": "Traditionalist-religious", "federal": "Federalist-autonomist", "techno": "Technocrat-reformist"}
const IDEO_POS := {"liberal": Vector2(0.2, 0.8), "social": Vector2(-0.7, 0.6), "national": Vector2(0.3, -0.7), "traditional": Vector2(0.5, -0.9), "federal": Vector2(0.0, 0.4), "techno": Vector2(0.7, 0.2)}
# bloc -> ideoloji -> yakınlık
const BLOC_AFF := {
	"us": {"liberal": 0.7, "social": 0.0, "national": 0.0, "traditional": -0.1, "federal": 0.4, "techno": 0.4},
	"eu": {"liberal": 0.7, "social": 0.4, "national": -0.2, "traditional": -0.3, "federal": 0.5, "techno": 0.4},
	"ru": {"liberal": -0.5, "social": 0.3, "national": 0.3, "traditional": 0.2, "federal": -0.5, "techno": 0.0},
	"cn": {"liberal": -0.4, "social": 0.2, "national": 0.3, "traditional": 0.0, "federal": -0.6, "techno": 0.2},
}
const OTHER_AFF := {"liberal": 0.1, "social": 0.2, "national": 0.1, "traditional": 0.3, "federal": 0.1, "techno": 0.15}
const COLORS := [["a83a32", "ece6d6", "e3a92b"], ["2f6f9a", "ece6d6", "e3a92b"], ["2f7a5a", "ece6d6", "e3a92b"], ["6b3f8a", "ece6d6", "e3a92b"],
	["c9832a", "1c1f24", "ece6d6"], ["1c1f24", "e3a92b", "ece6d6"], ["8a2f5a", "ece6d6", "5ab0a0"], ["3f5f3a", "ece6d6", "d8a05c"]]
const METHODS := ["uprising", "coup", "political"]
const METHOD_TR := {"uprising": "Silahlı ayaklanma", "coup": "Darbe girişimi", "political": "Siyasi hareket"}
const METHOD_EN := {"uprising": "Armed uprising", "coup": "Coup attempt", "political": "Political movement"}
const METHOD_DESC_TR := {
	"uprising": "Hemen savaş: 3 eyalet, hazır birlikler. Gizlilik yok, ama zaman da kaybetmezsin.",
	"coup": "Önce örgütlen: yeterli destekle iktidarın bir kısmını ani bir hamleyle ele geçir. Başarısız olursa ağır bedel.",
	"political": "Barışçıl başla: 1 eyalet, uzun ateşkes. Önce halkı ve dünyayı kazan; savaş istersen sonra.",
}
const METHOD_DESC_EN := {
	"uprising": "War at once: 3 provinces, ready troops. No secrecy, but no lost time.",
	"coup": "Organize first: seize part of power in a sudden move once support is high. Heavy cost on failure.",
	"political": "Start peacefully: 1 province, long truce. Win the people and the world first; war later if you choose.",
}
const NAME_A := ["Özgür", "Birleşik", "Kuzey", "Halk", "Doğu", "Ulusal", "Yeni", "Güney", "Batı", "Ortak"]
const NAME_B := ["Cephe", "Birlik", "Hareket", "Meclis", "Girişim", "Konsey", "Ordu", "Platform"]
const NAME_C := ["Kurtuluş", "Diriliş", "Şafak", "Uyanış", "Yurt", "Ufuk", "Ant"]
const NAME_A_EN := ["Free", "United", "Northern", "People's", "Eastern", "National", "New", "Southern", "Western", "Common"]
const NAME_B_EN := ["Front", "Union", "Movement", "Assembly", "Initiative", "Council", "Army", "Platform"]
const NAME_C_EN := ["Liberation", "Revival", "Dawn", "Awakening", "Homeland", "Horizon", "Oath"]
const ACTION_CD := 3
const GRACE_WEEKS := 6

# ------------------------------------------------------------------ kart havuzu: [tr, en]; fx anahtarları apply_fx içinde
# phase listesi: bu evrelerde çıkar. c: [[tr, en, fx]]
const CARDS := [
	{"id": "leak", "ph": [0], "t": ["Gizli Toplantı Sızdı", "A Secret Meeting Leaked"],
		"b": ["Bir hücrenin toplantı yeri yerel basında çıktı. Güvenlik birimleri soruşturma açtı.", "A cell's meeting place appeared in the local press. Security units opened an investigation."],
		"c": [["Yalanla ve dağıl", "Deny it and scatter", {"secrecy": -4, "support": -2}], ["Yeraltına çekil", "Go deeper underground", {"secrecy": 12, "support": -5}], ["Alenileş", "Go public", {"support": 10, "secrecy": -22}]]},
	{"id": "diaspora", "ph": [0, 1], "t": ["Diaspora Bağışı", "Diaspora Donation"],
		"b": ["Yurtdışındaki topluluk bağış önerdi. Küçük bağış şartsız; büyük bağışın bir bağlantısı var.", "The community abroad offered a donation. The small one has no strings; the large one is connected."],
		"c": [["Küçük bağışı al", "Take the small donation", {"gold_w": 1.5}], ["Büyük bağışı al (şartlı)", "Take the large donation (strings)", {"gold_w": 5.0, "dep": 1}], ["Reddet", "Decline", {"legit": 2}]]},
	{"id": "students", "ph": [0, 1], "t": ["Üniversite Gösterisi", "University Demonstration"],
		"b": ["Öğrenciler hareketin bayrağıyla yürümek istiyor. Yürüyüş büyük ilgi görebilir ama baskı da çekebilir.", "Students want to march under the movement's flag. It may draw big attention, and a crackdown."],
		"c": [["Destekle", "Support it", {"support": 9, "secrecy": -8, "stab": -1}], ["Sessiz kal", "Stay quiet", {"support": -2}], ["Yönlendir: sivil eylem", "Steer it: civil action", {"support": 5, "legit": 4}]]},
	{"id": "raid", "ph": [0], "t": ["Güvenlik Operasyonu", "Security Operation"],
		"b": ["Merkezî hükûmet bölgede ani aramalar yapıyor. Silah depolarından biri tehlikede.", "The central government is conducting sudden searches. One of the weapon caches is at risk."],
		"c": [["Depoyu taşı", "Move the cache", {"troops": -800, "secrecy": 4}], ["Depoyu yak", "Burn the cache", {"gold_w": -0.5, "secrecy": 8}], ["Savun", "Defend it", {"troops": -2500, "support": 4, "secrecy": -10}]]},
	{"id": "elders", "ph": [1], "t": ["Köy Muhtarları Ant İçti", "Village Elders Swear an Oath"],
		"b": ["Bölgenin köy ileri gelenleri hareketi desteklemeye hazır; karşılığında yerel özerklik sözü istiyorlar.", "Village elders in the region are ready to back the movement; in return they want a pledge of local autonomy."],
		"c": [["Söz ver", "Make the pledge", {"support": 10, "troops": 3000, "stab": -2}], ["Yalnızca teşekkür et", "Only thank them", {"support": 3}]]},
	{"id": "swap", "ph": [1, 2], "t": ["Esir Takası", "Prisoner Exchange"],
		"b": ["Merkezî hükûmet esir takası önerdi. İyi niyet jesti dünya basınında yankı bulabilir.", "The central government proposed a prisoner exchange. A goodwill gesture could resonate in the world press."],
		"c": [["Kabul et", "Accept", {"legit": 8, "support": -2}], ["Şartlarını artır", "Raise the terms", {"legit": 2, "support": 4}], ["Reddet", "Refuse", {"support": 3, "legit": -4}]]},
	{"id": "journalist", "ph": [1, 2, 3], "t": ["Yabancı Gazeteci", "Foreign Journalist"],
		"b": ["Tanınmış bir yabancı gazeteci bölgeye gelmek istiyor. Gördükleri ilgi çekebilir ya da seni zor durumda bırakabilir.", "A well-known foreign journalist wants to visit. What they see could win attention, or put you in a tight spot."],
		"c": [["Serbest dolaşsın", "Let them roam freely", {"legit": 10, "stab": -1}], ["Rehber eşliğinde gezdir", "Guided tour", {"legit": 5}], ["Reddet", "Refuse", {"legit": -4}]]},
	{"id": "hunger", "ph": [1, 2], "t": ["Kıtlık Köyleri", "Hungry Villages"],
		"b": ["Çatışma tarlaları vurdu; bazı köylerde yiyecek tükeniyor.", "The fighting hit the fields; food is running out in some villages."],
		"c": [["Hububat dağıt", "Distribute grain", {"gold_w": -2.0, "support": 8, "stab": 3}], ["Önce orduyu doyur", "Feed the army first", {"troops": 2000, "support": -8, "stab": -3}]]},
	{"id": "mediator", "ph": [2], "t": ["Arabulucu Teklifi", "Mediator's Offer"],
		"b": ["Tarafsız bir ülke geniş özerklik planı sundu: bağımsızlık yok, ama güçlü yerel meclis ve gelir payı var.", "A neutral country offered a broad autonomy plan: no independence, but a strong local assembly and a revenue share."],
		"c": [["Kabul et", "Accept", {"legit": 10, "support": -12, "stab": 5, "gold_w": 3}], ["Pazarlık et", "Bargain", {"legit": 4, "support": -2}], ["Reddet", "Reject", {"support": 6, "legit": -6}]]},
	{"id": "hardliners", "ph": [1, 2, 3], "t": ["Sertlik Yanlıları", "The Hardliners"],
		"b": ["Komutanlardan bir grup, müzakereyi ihanet sayıyor ve ayrılmakla tehdit ediyor.", "A group of commanders call negotiation treason and threaten to break away."],
		"c": [["Taviz ver", "Make concessions", {"troops": 2500, "legit": -4, "stab": 1}], ["Disiplin uygula", "Enforce discipline", {"troops": -2500, "stab": 2, "legit": 2}], ["Konsey kur", "Form a council", {"support": 3, "stab": -1}]]},
	{"id": "currency", "ph": [3], "t": ["Para Birimi", "The Currency"],
		"b": ["Yeni devlet kendi parasını mı basacak, yoksa komşunun parasına mı bağlanacak?", "Will the new state print its own money, or peg to a neighbor's currency?"],
		"c": [["Kendi paramızı bas", "Print our own", {"stab": -3, "legit": 6, "gold_w": -2.0}], ["Bağla (destekçinin parası)", "Peg (patron's currency)", {"stab": 4, "gold_w": 4.0, "dep": 1}]]},
	{"id": "army", "ph": [3, 4], "t": ["Milislerin Entegrasyonu", "Militia Integration"],
		"b": ["Dağınık milis grupları ulusal orduya katılmak istiyor; ama maaş ve rütbe bekliyorlar.", "Scattered militias want to join the national army, but expect pay and rank."],
		"c": [["Tam entegre et", "Fully integrate", {"troops": 4000, "gold_w": -3.0, "stab": 2}], ["Seçerek al", "Select some", {"troops": 1500, "gold_w": -1.0}], ["Dağıt", "Disband", {"troops": -1500, "stab": -3, "support": -3}]]},
	{"id": "border", "ph": [3, 4], "t": ["Sınır Pazarlığı", "Border Bargaining"],
		"b": ["Eski merkezle sınır çizgisi konusunda gizli bir görüşme önerildi. Taviz verirsen barış kalıcı olur.", "A secret talk on the border line with the old center was proposed. Concede, and peace becomes lasting."],
		"c": [["Taviz ver", "Concede", {"legit": 8, "stab": 4, "support": -5}], ["Sert dur", "Hold firm", {"support": 5, "legit": -3, "stab": -2}]]},
	{"id": "election", "ph": [4], "t": ["Seçim Takvimi", "Election Calendar"],
		"b": ["Halk ilk özgür seçimleri soruyor. Seçim meşruiyeti artırır ama sonucu garanti değildir.", "The people ask about the first free elections. Voting raises legitimacy, but the outcome is not guaranteed."],
		"c": [["Seçim yap", "Hold elections", {"legit": 10, "stab": -3, "support": 4}], ["Ertele", "Postpone", {"stab": 3, "legit": -8, "support": -4}]]},
	{"id": "investors", "ph": [4], "t": ["Yatırım Heyeti", "Investment Delegation"],
		"b": ["Yabancı bir heyet liman ve enerji için büyük yatırım önerdi; karşılığında uzun imtiyaz istiyor.", "A foreign delegation offered a large investment in ports and energy, in exchange for a long concession."],
		"c": [["Kabul et", "Accept", {"gold_w": 8.0, "dep": 1, "stab": 2}], ["Yerli sermayeyi destekle", "Back local capital", {"gold_w": 2.0, "stab": 1}], ["Reddet", "Decline", {"legit": 3}]]},
]
const CONST_CARD := {"id": "constitution", "t": ["Anayasa", "The Constitution"],
	"b": ["Bağımsızlık ilan edildi. Yeni devletin yönetim biçimini seçmenin zamanı.", "Independence is declared. Time to choose the new state's form of government."],
	"c": [["Cumhuriyet", "Republic", {"legit": 6, "stab": 2}], ["Parlamenter monarşi", "Parliamentary monarchy", {"stab": 5, "legit": 2}],
		["Federasyon", "Federation", {"support": 5, "stab": 1, "legit": 3}], ["Geçiş yönetimi", "Transitional rule", {"stab": 3, "troops": 2000, "legit": -6}]]}

# ------------------------------------------------------------------ yardımcılar

static func _tr() -> bool:
	return Loc.lang == "tr"


static func _p(pair: Array) -> String:
	return pair[0] if _tr() else pair[1]


static func ideo_name(i: String) -> String:
	return IDEO_TR[i] if _tr() else IDEO_EN[i]


static func phase_name(ph: int) -> String:
	return PHASE_TR[ph] if _tr() else PHASE_EN[ph]


static func phase_goal(ph: int) -> String:
	return PHASE_GOAL_TR[ph] if _tr() else PHASE_GOAL_EN[ph]


static func method_name(m: String) -> String:
	return METHOD_TR[m] if _tr() else METHOD_EN[m]


static func method_desc(m: String) -> String:
	return METHOD_DESC_TR[m] if _tr() else METHOD_DESC_EN[m]


static func active(gs) -> bool:
	return gs.indep is Dictionary and bool(gs.indep.get("on", false))


static func random_name(rng: RandomNumberGenerator) -> String:
	var a: Array = NAME_A if _tr() else NAME_A_EN
	var b: Array = NAME_B if _tr() else NAME_B_EN
	var c: Array = NAME_C if _tr() else NAME_C_EN
	if rng.randf() < 0.6:
		return "%s %s" % [a[rng.randi_range(0, a.size() - 1)], b[rng.randi_range(0, b.size() - 1)]]
	return "%s %s" % [c[rng.randi_range(0, c.size() - 1)], b[rng.randi_range(0, b.size() - 1)]]


static func similarity(a: String, b: String) -> float:
	return clampf(1.0 - (IDEO_POS[a] as Vector2).distance_to(IDEO_POS[b]) / 2.4, 0.0, 1.0)


static func _hash_noise(cid: int, ideo: String) -> float:
	return (float(hash("%d:%s" % [cid, ideo]) % 1000) / 1000.0 - 0.5) * 0.5


## Bir ülkenin hareketin ideolojisine yakınlığı (-1..1)
static func affinity(gs, cid: int) -> float:
	var s: Dictionary = gs.indep
	var c = gs.countries[cid]
	var ideo: String = s.ideo
	var tbl: Dictionary = BLOC_AFF.get(String(c.bloc), {})
	var a: float = float(tbl.get(ideo, OTHER_AFF[ideo]))
	a += _hash_noise(cid, ideo)
	var host: int = int(s.host)
	if cid == host or not c.alive:
		return -1.0
	if gs.is_allied(cid, host):
		a -= 0.9
	if gs.at_war(cid, host) or gs.cold.any(func(p): return (p[0] == cid and p[1] == host) or (p[1] == cid and p[0] == host)):
		a += 0.4
	if c.embargo.has(host):
		a += 0.2
	for nb in gs.provinces[gs.countries[host].capital].neighbors:
		if gs.provinces[nb].owner == cid:
			a += 0.1
			break
	return clampf(a, -1.0, 1.0)


## Ana vatanın büyüklüğüne göre yardım/asker ölçeği
static func _scale(gs) -> float:
	return clampf(float(gs.indep.get("host_troops", 100000)) / 150000.0, 0.6, 4.0)


static func _inc(gs) -> float:
	return maxf(gs.countries[gs.player].income, 1.0)


static func held(gs) -> int:
	return int(gs.countries[gs.player].prov_held)


static func owned(gs) -> int:
	return int(gs.countries[gs.player].prov_owned)


# ------------------------------------------------------------------ başlangıç

## params: host_en, dir, n, name, leader, color, ideo, method
static func begin(gs, params: Dictionary) -> bool:
	var host_en: String = String(params.get("host_en", ""))
	var host: int = int(gs.macro_idx.get(host_en, -1))
	if host < 0:
		return false
	var method: String = String(params.get("method", "uprising"))
	var n: int = clampi(int(params.get("n", 3)), 1, 5)
	if method == "political":
		n = 1
	elif method == "coup":
		n = clampi(n, 2, 4)
	var cols: Array = COLORS[clampi(int(params.get("color", 0)), 0, COLORS.size() - 1)]
	var host_troops: float = float(maxi(gs.countries[host].troops, 40000))
	# zayıf başlangıç: birkaç bin silahlı gönüllü, ağır silah yok
	var troops: int = clampi(int(host_troops * {"uprising": 0.03, "coup": 0.02, "political": 0.01}[method]), {"uprising": 4000, "coup": 3000, "political": 1500}[method], {"uprising": 12000, "coup": 9000, "political": 5000}[method])
	# merkez şehirler: seçilen eyaletler (host başkenti hariç hepsi hareketin elinde başlar; başkent ilçe ağıyla alınır)
	var chosen: Array = []
	for v in params.get("pids", []):
		var pv: int = int(v)
		if pv >= 0 and pv < gs.provinces.size() and gs.provinces[pv].owner == host and not chosen.has(pv):
			chosen.append(pv)
	chosen = chosen.slice(0, 1 if method == "political" else 3)
	var host_cap: int = int(gs.countries[host].capital)
	var base: Array = []
	for pv2 in chosen:
		if pv2 != host_cap:
			base.append(pv2)
	var spec := {"name": String(params.get("name", "")).strip_edges().substr(0, 30), "from": [[host_en, n]], "dir": String(params.get("dir", "near")),
		"troops": troops, "tech": 0.4, "defect": false, "leader": "%s|%s" % [Loc.t("Lider"), String(params.get("leader", "")).strip_edges().substr(0, 24)] if String(params.get("leader", "")).strip_edges() != "" else "",
		"colors": cols, "pattern": int(gs.rng.randi() % 6), "aggression": 0.6, "doctrine": 2}
	if not base.is_empty():
		spec["pids"] = base
		n = base.size()
	if spec.name == "":
		spec.name = random_name(gs.rng)
	var fid: int = gs.create_faction(spec)
	if fid < 0:
		return false
	var f = gs.countries[fid]
	_weaken(gs, f)
	if method != "uprising":
		_end_war(gs, fid)
		var wk: int = 26 if method == "political" else 16
		for cid in gs.countries.size():
			pass
		f.truce[host] = gs.turn + wk
		gs.countries[host].truce[fid] = gs.turn + wk
	else:
		# merkez harekete geçene kadar kısa bir hazırlık süresi: ilçelerde örgütlenmek için
		_end_war(gs, fid)
		f.truce[host] = gs.turn + GRACE_WEEKS
		gs.countries[host].truce[fid] = gs.turn + GRACE_WEEKS
	# oyuncuyu hareketin devletine aktar
	gs.countries[host].is_player = false
	gs.player = fid
	f.is_player = true
	f.gold = maxf(f.gold, f.income * (10.0 if method == "political" else 6.0))
	for pid in f.owned_ids:
		gs.provinces[pid].defense = maxi(int(gs.provinces[pid].defense), 2)
	var ideo: String = String(params.get("ideo", "liberal"))
	if not IDEOS.has(ideo):
		ideo = "liberal"
	gs.indep = {"on": true, "phase": 0 if method != "uprising" else 1, "host": host, "method": method, "ideo": ideo, "start_n": n,
		"support": {"political": 45.0, "coup": 35.0, "uprising": 50.0}[method], "secrecy": 80.0 if method == "coup" else (65.0 if method == "political" else 0.0),
		"legit": 15.0 if method == "political" else 10.0, "dep": 0, "patrons": {}, "recog": [], "groups": [], "next_card": gs.turn + 3, "pending": {},
		"host_troops": int(host_troops), "phase_turn": gs.turn, "cd": {}, "const": "", "un_tries": 0, "ref_done": false, "weeks4": 0, "last_aid": gs.turn, "won": false}
	gs.scn = {"id": "indep", "start": gs.turn, "done": {}, "fired": {}, "streak": {}, "cap": {}, "over": false}
	# ilçe katmanı: seçilen şehirler (yoksa hareketin ilk eyaletleri)
	var dist_src: Array = chosen if not chosen.is_empty() else f.owned_ids.duplicate()
	Districts.build(gs, dist_src, gs.rng)
	_spawn_groups(gs, host_en, String(params.get("dir", "near")))
	var intro_tr := "%s doğdu: %s topraklarında bağımsızlık için yola çıktı. Yol uzun; destek, para ve zaman gerekecek." % [f.name, gs.countries[host].name]
	var intro_en := "%s is born: it sets out for independence in the lands of %s. The road is long; it will take support, money and time." % [f.name, gs.countries[host].name]
	gs.post_news(intro_tr if _tr() else intro_en, f.capital, "war_player")
	if method == "uprising":
		gs.indep["grace"] = gs.turn + GRACE_WEEKS
		gs.post_news(Loc.t("Güvenlik güçleri toparlanıyor: ilçelerde örgütlenmek için 6 haftan var."), f.capital, "war_player")
	return true


## Hareket silahsız başlamaz ama ağır silahı da yoktur: yalnızca eski nesil tüfek, tank/top/hava yok.
static func _weaken(gs, f) -> void:
	var ids: Array = Arsenal.family(f.name_en, "inf", f.bloc)
	var kt: float = maxf(float(f.base_troops), 1000.0) / 1000.0
	f.inv = {String(ids[0]): maxi(1, int(ceil(kt * 0.7)))}
	f.carriers = 0
	f.eq_land = 0.72
	Macro.recalc(f)


static func _war_news(gs) -> void:
	var f = gs.countries[gs.player]
	var h = gs.countries[int(gs.indep.host)]
	gs.post_news(("%s ayaklandı! %s birlikleriyle çatışma başladı." % [f.name, h.name]) if _tr() else ("%s has risen! Fighting with %s forces has begun." % [f.name, h.name]), f.capital, "war_player")


static func _end_war(gs, fid: int) -> void:
	for w in gs.wars.duplicate():
		if w.involves(fid):
			var o: int = w.other(fid)
			gs.countries[o].enemies.erase(fid)
			gs.countries[fid].enemies.erase(o)
			gs.wars.erase(w)


static func _spawn_groups(gs, host_en: String, dir: String) -> void:
	var host: int = int(gs.indep.host)
	var cands: Array = []
	for c in gs.countries:
		if c.alive and not c.is_rebel and c.id != host and c.id != gs.player and c.owned_ids.size() >= 7 and not c.name_en.begins_with("faction_"):
			cands.append(c)
	var used := {gs.countries[gs.player].name: true}
	var ideos: Array = IDEOS.duplicate()
	ideos.shuffle()
	for i in 3:
		var from_en: String = host_en if i == 0 else String(cands[gs.rng.randi() % cands.size()].name_en)
		var gdir: String = {"east": "west", "west": "east", "north": "south", "south": "north"}.get(dir, "near") if i == 0 else ["north", "south", "east", "west"][gs.rng.randi() % 4]
		var nm: String = random_name(gs.rng)
		while used.has(nm):
			nm = random_name(gs.rng)
		used[nm] = true
		var cols: Array = COLORS[(i * 3 + 2 + gs.rng.randi() % 2) % COLORS.size()]
		var gid: int = gs.create_faction({"name": nm, "from": [[from_en, 2]], "dir": gdir, "troops": 14000 + 4000 * i, "tech": 0.3, "colors": cols,
			"pattern": gs.rng.randi() % 6, "aggression": 0.8, "doctrine": 2})
		if gid < 0:
			continue
		gs.indep.groups.append({"id": gid, "ideo": ideos[i], "rel": 45 + gs.rng.randi() % 20, "status": "neutral", "cd": 0})


# ------------------------------------------------------------------ etkiler

static func apply_fx(gs, fx: Dictionary) -> void:
	var s: Dictionary = gs.indep
	var c = gs.countries[gs.player]
	for k in fx.keys():
		var v: float = float(fx[k])
		match k:
			"support":
				s.support = clampf(float(s.support) + v, 0.0, 100.0)
			"secrecy":
				s.secrecy = clampf(float(s.secrecy) + v, 0.0, 100.0)
			"legit":
				s.legit = clampf(float(s.legit) + v, 0.0, 100.0)
			"dep":
				s.dep = maxi(0, int(s.dep) + int(v))
			"gold_w":
				c.gold = maxf(0.0, c.gold + v * _inc(gs))
			"stab":
				c.stability = clampf(c.stability + v, 5.0, 100.0)
			"troops":
				_add_troops(gs, int(v))


static func _add_troops(gs, n: int) -> void:
	if n > 0:
		var room: int = int(maxf(float(gs.indep.get("host_troops", 40000)) * 0.6, 12000.0)) - int(gs.countries[gs.player].troops)
		n = mini(n, maxi(room, 0))
		if n <= 0:
			return
	var mine: Array = []
	for a in gs.armies.values():
		if a.owner == gs.player:
			mine.append(a)
	if mine.is_empty():
		if n > 0:
			var cap: int = gs.countries[gs.player].capital
			if gs._spawn_army(gs.player, cap, n) == null:
				# şehir işgal altında: gönüllüler çevredeki boş bir bölgede toplanır
				for nb in gs.provinces[cap].neighbors:
					if not gs.armies.has(int(nb)):
						gs._spawn_army(gs.player, int(nb), n)
						break
		gs.refresh_stats()
		return
	mine.sort_custom(func(a, b): return a.size > b.size)
	if n >= 0:
		mine[0].size += n
	else:
		var left: int = -n
		for a in mine:
			var take: int = mini(left, int(a.size * 0.6))
			a.size = maxi(1, a.size - take)
			left -= take
			if left <= 0:
				break
	gs.refresh_stats()


# ------------------------------------------------------------------ kartlar

const CARD_ICON := {"mediator": "autonomy", "army": "militia"}


static func _card_data(card: Dictionary) -> Dictionary:
	var ch: Array = []
	for c in card.c:
		ch.append({"t": _p([c[0], c[1]]), "fx": c[2]})
	var icon: String = Icons.pick("card_" + String(CARD_ICON.get(String(card.id), card.id)), "")
	return {"id": card.id, "title": _p(card.t), "body": _p(card.b), "choices": ch, "icon": icon}


static func _draw(gs) -> Dictionary:
	var s: Dictionary = gs.indep
	var seen: Array = s.get("seen", [])
	var pool: Array = []
	for c in CARDS:
		if (c.ph as Array).has(int(s.phase)) and not seen.has(c.id):
			pool.append(c)
	if pool.is_empty():
		seen.clear()
		s["seen"] = seen
		for c in CARDS:
			if (c.ph as Array).has(int(s.phase)):
				pool.append(c)
	if pool.is_empty():
		return {}
	return pool[gs.rng.randi() % pool.size()]


static func _show(gs, data: Dictionary) -> void:
	gs.indep["pending"] = data
	gs.indep_card.emit()


## Yüklemeden sonra bekleyen kart varsa yeniden gösterir
static func resume(gs) -> void:
	if active(gs) and not (gs.indep.get("pending", {}) as Dictionary).is_empty():
		gs.indep_card.emit()


static func choose(gs, idx: int) -> void:
	var s: Dictionary = gs.indep
	var p: Dictionary = s.get("pending", {})
	if p.is_empty():
		return
	var ch: Array = p.get("choices", [])
	if idx >= 0 and idx < ch.size():
		var fx: Dictionary = ch[idx].get("fx", {})
		if fx.has("_cut"):
			var pk: String = str(fx["_cut"])
			if s.patrons.has(pk):
				s.patrons[pk].cut = gs.turn + 26
				s.patrons[pk].lvl = 0
				s.patrons[pk].strings = 0
		if fx.has("_accept"):
			var pk2: String = str(fx["_accept"])
			if s.patrons.has(pk2):
				s.patrons[pk2].strings = 0
				s.patrons[pk2].lvl = int(s.patrons[pk2].lvl) + 1
		apply_fx(gs, fx)
		if str(p.get("id", "")) == "constitution":
			s["const"] = str(idx)
	var seen: Array = s.get("seen", [])
	if str(p.get("id", "")) != "" and not seen.has(p.id):
		seen.append(p.id)
	s["seen"] = seen
	s["pending"] = {}
	gs.state_changed.emit()


# ------------------------------------------------------------------ destekçiler

static func _aid_news(gs, donor, kind: String) -> void:
	var f = gs.countries[gs.player]
	var tr := {"money": "%s, %s hareketine mali yardım gönderdi.", "weapons": "%s, %s hareketine silah sevkiyatı yaptı.", "volunteers": "%s kaynaklı gönüllüler %s saflarına katıldı.",
		"recognize": "%s, %s devletini resmen tanıdığını açıkladı."}
	var en := {"money": "%s sent financial aid to %s.", "weapons": "%s shipped weapons to %s.", "volunteers": "Volunteers from %s joined %s.", "recognize": "%s officially recognized %s."}
	gs.post_news((tr if _tr() else en)[kind] % [donor.name, f.name], donor.capital, "war_player")


static func _patron(gs, cid: int) -> Dictionary:
	var k := str(cid)
	if not gs.indep.patrons.has(k):
		gs.indep.patrons[k] = {"lvl": 0, "strings": 0, "cut": 0}
	return gs.indep.patrons[k]


static func _demand(gs, cid: int) -> void:
	var donor = gs.countries[cid]
	var pk := str(cid)
	var kinds := ["base", "econ", "policy", "reform"]
	var kind: String = kinds[gs.rng.randi() % kinds.size()]
	var t: Array = {"base": ["%s Üs Hakkı İstiyor", "%s Wants Base Rights"], "econ": ["%s İmtiyaz İstiyor", "%s Wants a Concession"],
		"policy": ["%s Dış Politikada Hizalanma İstiyor", "%s Wants Foreign Policy Alignment"], "reform": ["%s Reform Şartı Koyuyor", "%s Sets a Reform Condition"]}[kind]
	var b: Array = {"base": ["%s, verdiği desteğe karşılık bölgede bir askerî üs hakkı talep ediyor.", "%s demands a military base in return for its support."],
		"econ": ["%s, liman ve enerji hatlarında uzun vadeli imtiyaz istiyor.", "%s wants a long-term concession on ports and energy lines."],
		"policy": ["%s, uluslararası oylamalarda kendi safında durmanı bekliyor.", "%s expects you to side with it in international votes."],
		"reform": ["%s, desteğini sürdürmek için siyasi bir reform paketini şart koşuyor.", "%s makes its continued support conditional on a political reform package."]}[kind]
	var fxa: Dictionary = {"base": {"dep": 1, "legit": -3, "stab": 1, "gold_w": 2.0}, "econ": {"dep": 1, "gold_w": 5.0, "support": -3}, "policy": {"dep": 1, "legit": -2, "stab": 2}, "reform": {"support": -4, "stab": -3, "legit": 3}}[kind]
	fxa = fxa.duplicate()
	fxa["_accept"] = pk
	var data := {"id": "demand:" + pk, "title": (t[0] if _tr() else t[1]) % donor.name, "body": (b[0] if _tr() else b[1]) % donor.name,
		"choices": [{"t": Loc.t("Kabul et"), "fx": fxa}, {"t": Loc.t("Reddet"), "fx": {"_cut": pk, "support": 3, "legit": 1}}]}
	_show(gs, data)


static func _patron_tick(gs) -> void:
	var s: Dictionary = gs.indep
	var ph: int = int(s.phase)
	var best := -1
	var best_score := 0.0
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.id == gs.player or c.id == int(s.host) or c.name_en.begins_with("faction_"):
			continue
		var a: float = affinity(gs, c.id)
		if a < 0.3:
			continue
		var pat: Dictionary = s.patrons.get(str(c.id), {})
		if int(pat.get("cut", 0)) > gs.turn:
			continue
		var sc: float = a * gs.rng.randf() + 0.15 * float(pat.get("lvl", 0))
		if sc > best_score:
			best_score = sc
			best = c.id
	if best < 0 or best_score < 0.18:
		return
	var donor = gs.countries[best]
	var pat2: Dictionary = _patron(gs, best)
	var f = gs.countries[gs.player]
	var kinds: Array = ["money"]
	if ph >= 1:
		kinds += ["weapons", "volunteers"]
	var kind: String = kinds[gs.rng.randi() % kinds.size()]
	match kind:
		"money":
			f.gold += maxf(0.4 * donor.income, 0.5 * _inc(gs))
			pat2.strings = int(pat2.strings) + 1
		"weapons":
			f.eq_land = minf(1.6, f.eq_land + 0.02)
			f.fund += 0.5 * _inc(gs)
			pat2.strings = int(pat2.strings) + 2
		"volunteers":
			_add_troops(gs, int(gs.rng.randi_range(2000, 6000) * _scale(gs)))
			pat2.strings = int(pat2.strings) + 2
	pat2.lvl = int(pat2.lvl) + 1
	_aid_news(gs, donor, kind)
	if int(pat2.strings) >= 4 and (s.pending as Dictionary).is_empty():
		_demand(gs, best)


static func _recognition_tick(gs) -> void:
	var s: Dictionary = gs.indep
	if int(s.phase) < 2:
		return
	var legit: float = float(s.legit)
	var cands: Array = []
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.id == gs.player or c.id == int(s.host) or (s.recog as Array).has(c.id) or c.name_en.begins_with("faction_"):
			continue
		var a: float = affinity(gs, c.id)
		if a > 0.0 and gs.rng.randf() < 0.002 + 0.012 * a * (legit / 100.0) + (0.003 if int(s.phase) >= 3 else 0.0):
			cands.append(c.id)
	if cands.is_empty():
		return
	var pick: int = cands[gs.rng.randi() % cands.size()]
	s.recog.append(pick)
	_aid_news(gs, gs.countries[pick], "recognize")


# ------------------------------------------------------------------ rakip gruplar

static func group_of(gs, gid: int) -> Dictionary:
	for g in gs.indep.groups:
		if int(g.id) == gid:
			return g
	return {}


static func group_odds(gs, g: Dictionary, what: String) -> float:
	var sim: float = similarity(String(gs.indep.ideo), String(g.ideo))
	var rel: float = float(g.rel)
	var mine: float = float(gs.countries[gs.player].troops) + 1.0
	var theirs: float = float(gs.countries[int(g.id)].troops) + 1.0
	var strength: float = mine / (mine + theirs)
	match what:
		"ally":
			return clampf(0.15 + 0.5 * sim + (rel - 50.0) / 200.0 + (0.08 if gs.at_war(gs.player, int(g.id)) else 0.0), 0.05, 0.9)
		"merge":
			if String(g.status) != "ally":
				return 0.0
			return clampf(0.05 + 0.5 * sim + (rel - 50.0) / 150.0 + 0.2 * (strength - 0.5), 0.03, 0.85)
	return 1.0


static func group_act(gs, gid: int, what: String) -> String:
	var g: Dictionary = group_of(gs, gid)
	if g.is_empty() or not gs.countries[gid].alive:
		return Loc.t("Bu grup artık yok.")
	if int(g.cd) > gs.turn and what != "rival":
		return Loc.t("Bu grupla yakın zamanda görüştün (%d hafta).") % (int(g.cd) - gs.turn)
	var gc = gs.countries[gid]
	match what:
		"talk":
			g.rel = mini(100, int(g.rel) + 8 + int(similarity(String(gs.indep.ideo), String(g.ideo)) * 12.0))
			g.cd = gs.turn + 4
			return (Loc.t("%s ile görüşme olumlu geçti.") % gc.name)
		"ally":
			var p: float = group_odds(gs, g, "ally")
			g.cd = gs.turn + 6
			if gs.rng.randf() < p:
				if gs.at_war(gs.player, gid):
					gs.finish_peace(gs.get_war(gs.player, gid), -1, [])
				gs.make_alliance(gs.player, gid)
				g.status = "ally"
				g.rel = mini(100, int(g.rel) + 15)
				return Loc.t("%s ile ittifak kuruldu.") % gc.name
			g.rel = maxi(0, int(g.rel) - 10)
			return Loc.t("%s ittifakı reddetti.") % gc.name
		"merge":
			var p2: float = group_odds(gs, g, "merge")
			g.cd = gs.turn + 8
			if gs.rng.randf() < p2:
				_merge(gs, gid)
				g.status = "merged"
				return Loc.t("%s hareketine katıldı!") % gc.name
			g.rel = maxi(0, int(g.rel) - 12)
			return Loc.t("%s birleşmeyi reddetti.") % gc.name
		"rival":
			if not gs.at_war(gs.player, gid):
				if gs.is_allied(gs.player, gid):
					gs.break_alliance(gs.player, gid)
				gs.declare_war(gs.player, gid)
			g.status = "rival"
			g.rel = 0
			return Loc.t("%s ile rekabet savaşa döndü.") % gc.name
	return ""


static func _merge(gs, gid: int) -> void:
	var me: int = gs.player
	for p in gs.provinces:
		if p.owner == gid:
			p.owner = me
			p.core = me
		if p.controller == gid:
			p.controller = me
			p.siege = 0
		if p.owner == me or p.controller == me:
			gs.province_changed.emit(p.id)
	for pid in gs.armies.keys().duplicate():
		if gs.armies[pid].owner == gid:
			gs.armies[pid].owner = me
	gs.break_alliance(me, gid)
	gs._check_elimination()
	gs.refresh_stats()


static func _group_tick(gs) -> void:
	var s: Dictionary = gs.indep
	for g in s.groups:
		var gc = gs.countries[int(g.id)]
		if not gc.alive or String(g.status) == "merged":
			continue
		if String(g.status) != "ally" and not gs.at_war(gs.player, int(g.id)) and int(g.rel) < 30 and gs.rng.randf() < 0.015:
			g.status = "rival"
			if gs.declare_war(int(g.id), gs.player):
				gs.post_news(("%s, %s hareketine savaş açtı: rekabet kızıştı." % [gc.name, gs.countries[gs.player].name]) if _tr() else ("%s declared war on %s: the rivalry has turned hot." % [gc.name, gs.countries[gs.player].name]), gc.capital, "war_player")
		g.rel = clampi(int(g.rel) + (1 if String(g.status) == "ally" else 0), 0, 100)


# ------------------------------------------------------------------ eylemler

static func cd_left(gs, id: String) -> int:
	return maxi(0, int(gs.indep.cd.get(id, 0)) - gs.turn)


## [{id, label, desc, cost, chance (-1 = yok), why ("" = olabilir)}]
static func actions(gs) -> Array:
	var s: Dictionary = gs.indep
	var ph: int = int(s.phase)
	var inc: float = _inc(gs)
	var out: Array = []
	var gold: float = gs.countries[gs.player].gold
	var A := func(id: String, tr: Array, en: Array, cost: float, chance: float, why: String):
		if why == "" and cd_left(gs, id) > 0:
			why = Loc.t("Bekleme: %d hafta") % cd_left(gs, id)
		if why == "" and cost > gold:
			why = Loc.t("Kasa yetersiz")
		out.append({"id": id, "label": _p(tr), "desc": _p(en), "cost": cost, "chance": chance, "why": why})
	if ph == 0:
		A.call("propaganda", ["Propaganda", "Propaganda"], ["+8 halk desteği, −10 gizlilik", "+8 support, −10 secrecy"], 0.5 * inc, -1.0, "")
		A.call("cell", ["Gizli hücre kur", "Build a secret cell"], ["+12 gizlilik, +2.000 gönüllü", "+12 secrecy, +2,000 volunteers"], 0.3 * inc, -1.0, "")
		A.call("fund", ["Fon topla", "Raise funds"], ["+1,5 haftalık gelir, −3 destek", "+1.5 weeks of income, −3 support"], 0.0, -1.0, "")
		A.call("arms", ["Silah tedariki", "Procure arms"], ["Silah kalitesi +, −8 gizlilik", "Better arms, −8 secrecy"], 0.8 * inc, -1.0, "")
		A.call("uprise", ["Ayaklanmayı başlat", "Start the uprising"], ["Merkezle savaş başlar; evre 2'ye geçilir", "War with the center begins; phase 2"], 0.0, -1.0, "" if float(s.support) >= 40.0 else Loc.t("Halk desteği en az 40 olmalı"))
		if String(s.method) == "coup":
			var cp: float = coup_chance(gs)
			A.call("coup", ["Darbe", "Coup"], ["Başarırsan 3 eyalet bir anda, başarısızlıkta ağır kayıp", "Success seizes 3 provinces at once; failure is costly"], 0.5 * inc, cp, "" if float(s.support) >= 50.0 else Loc.t("Halk desteği en az 50 olmalı"))
	elif ph == 1:
		A.call("propaganda", ["Propaganda", "Propaganda"], ["+6 halk desteği", "+6 support"], 0.4 * inc, -1.0, "")
		A.call("volunteers", ["Gönüllü topla", "Recruit volunteers"], ["+5.000 asker, −2 istikrar", "+5,000 troops, −2 stability"], 0.6 * inc, -1.0, "")
		A.call("appeal", ["Uluslararası çağrı", "International appeal"], ["+6 meşruiyet", "+6 legitimacy"], 0.4 * inc, -1.0, "")
	elif ph == 2:
		A.call("appeal", ["Uluslararası çağrı", "International appeal"], ["+6 meşruiyet", "+6 legitimacy"], 0.4 * inc, -1.0, "")
		var why_ref := ""
		if gs.at_war(gs.player, int(s.host)):
			why_ref = Loc.t("Önce merkezle ateşkes yapmalısın")
		elif float(s.support) < 50.0:
			why_ref = Loc.t("Halk desteği en az 50 olmalı")
		A.call("referendum", ["Referandum", "Referendum"], ["Halkın iradesi: başarırsan bağımsızlık ilanı", "The people's will: on success, declare independence"], 0.8 * inc, referendum_chance(gs), why_ref)
		A.call("unilateral", ["Tek taraflı ilan", "Unilateral declaration"], ["Anında bağımsızlık; meşruiyet −15, merkez savaşa dönebilir", "Instant independence; legitimacy −15, the center may resume war"], 0.0, -1.0, "" if float(s.support) >= 40.0 else Loc.t("Halk desteği en az 40 olmalı"))
	elif ph == 3:
		A.call("appeal", ["Uluslararası çağrı", "International appeal"], ["+6 meşruiyet", "+6 legitimacy"], 0.4 * inc, -1.0, "")
		var why_un := ""
		if (s.recog as Array).size() < 5:
			why_un = Loc.t("En az 5 ülke tanımalı")
		elif float(s.legit) < 35.0:
			why_un = Loc.t("Meşruiyet en az 35 olmalı")
		A.call("un_apply", ["BM üyeliği için başvur", "Apply for UN membership"], ["Başarırsan Konsolidasyon evresi", "On success, the Consolidation phase"], 1.0 * inc, un_chance(gs), why_un)
		A.call("treaty", ["Sınır antlaşması", "Border treaty"], ["+8 meşruiyet; merkezle barış gerekir", "+8 legitimacy; needs peace with the center"], 0.5 * inc, -1.0, "" if not gs.at_war(gs.player, int(s.host)) else Loc.t("Önce merkezle barış yapmalısın"))
	else:
		A.call("appeal", ["Uluslararası çağrı", "International appeal"], ["+6 meşruiyet", "+6 legitimacy"], 0.4 * inc, -1.0, "")
		A.call("invest", ["Kalkınma yatırımı", "Development investment"], ["+4 istikrar", "+4 stability"], 1.5 * inc, -1.0, "")
	return out


static func coup_chance(gs) -> float:
	var s: Dictionary = gs.indep
	return clampf(0.15 + 0.5 * (float(s.support) / 100.0) + 0.25 * (float(s.secrecy) / 100.0) - 0.15 * (float(gs.countries[int(s.host)].stability) / 100.0), 0.05, 0.85)


static func referendum_chance(gs) -> float:
	var s: Dictionary = gs.indep
	return clampf(0.2 + 0.6 * (float(s.support) / 100.0) + 0.25 * (float(s.legit) / 100.0) - 0.2, 0.05, 0.95)


static func vetoes(gs) -> int:
	var n := 0
	for nm in ["United States of America", "Russia", "China", "United Kingdom", "France"]:
		var cid: int = int(gs.macro_idx.get(nm, -1))
		if cid >= 0 and gs.countries[cid].alive and affinity(gs, cid) < -0.2:
			n += 1
	return n


static func un_chance(gs) -> float:
	var s: Dictionary = gs.indep
	return clampf(0.25 + 0.05 * (s.recog as Array).size() + 0.004 * float(s.legit) - 0.15 * vetoes(gs) - 0.03 * float(s.dep), 0.03, 0.9)


static func do_action(gs, id: String) -> String:
	var s: Dictionary = gs.indep
	var acts: Array = actions(gs)
	var a: Dictionary = {}
	for x in acts:
		if x.id == id:
			a = x
	if a.is_empty():
		return ""
	if a.why != "":
		return a.why
	var f = gs.countries[gs.player]
	f.gold -= float(a.cost)
	s.cd[id] = gs.turn + ACTION_CD
	var res := ""
	match id:
		"propaganda":
			apply_fx(gs, {"support": 8.0 if int(s.phase) == 0 else 6.0, "secrecy": -10.0 if int(s.phase) == 0 else 0.0})
			res = Loc.t("Propaganda kampanyası yürütüldü.")
		"cell":
			apply_fx(gs, {"secrecy": 12.0, "troops": 2000})
			res = Loc.t("Yeni bir gizli hücre kuruldu.")
		"fund":
			apply_fx(gs, {"gold_w": 1.5, "support": -3.0})
			s.cd[id] = gs.turn + 6
			res = Loc.t("Bağış toplandı.")
		"arms":
			f.eq_land = minf(1.6, f.eq_land + 0.03)
			apply_fx(gs, {"secrecy": -8.0})
			s.cd[id] = gs.turn + 6
			res = Loc.t("Silah sevkiyatı ulaştı.")
		"uprise":
			start_uprising(gs)
			res = Loc.t("Ayaklanma başladı!")
		"coup":
			res = _coup(gs)
		"volunteers":
			apply_fx(gs, {"troops": 5000, "stab": -2.0})
			res = Loc.t("Gönüllüler orduya katıldı.")
		"appeal":
			apply_fx(gs, {"legit": 6.0})
			res = Loc.t("Uluslararası kamuoyuna çağrı yapıldı.")
		"referendum":
			res = _referendum(gs)
		"unilateral":
			apply_fx(gs, {"legit": -15.0})
			declare_independence(gs, true)
			res = Loc.t("Bağımsızlık tek taraflı ilan edildi!")
		"un_apply":
			res = _un_apply(gs)
		"treaty":
			apply_fx(gs, {"legit": 8.0})
			res = Loc.t("Sınır antlaşması imzalandı.")
		"invest":
			apply_fx(gs, {"stab": 4.0})
			res = Loc.t("Kalkınma yatırımı başladı.")
	gs.state_changed.emit()
	return res


static func start_uprising(gs) -> void:
	var s: Dictionary = gs.indep
	var host: int = int(s.host)
	s.phase = 1
	s.phase_turn = gs.turn
	var f = gs.countries[gs.player]
	_host_shock(gs)
	f.truce.erase(host)
	gs.countries[host].truce.erase(gs.player)
	gs.declare_war(gs.player, host, true)
	gs._call_allies_of(host, gs.player)
	_war_news(gs)


## Ayaklanma başlarken merkez şaşırır: ordusu dağınık, istikrarı düşer
static func _host_shock(gs) -> void:
	var host: int = int(gs.indep.host)
	for a in gs.armies.values():
		if a.owner == host:
			a.size = maxi(1, int(a.size * 0.88))
	gs.countries[host].stability = clampf(gs.countries[host].stability - 8.0, 5.0, 100.0)


static func _coup(gs) -> String:
	var s: Dictionary = gs.indep
	var host: int = int(s.host)
	var p: float = coup_chance(gs)
	var ok: bool = gs.rng.randf() < p
	f_truce_clear(gs)
	_host_shock(gs)
	var f = gs.countries[gs.player]
	s.phase = 1
	s.phase_turn = gs.turn
	gs.declare_war(gs.player, host, true)
	if ok:
		var taken := 0
		var order: Array = []
		for pid in gs.countries[host].owned_ids:
			if gs.provinces[pid].controller == host:
				order.append([gs.provinces[pid].label_pos.distance_to(gs.provinces[f.capital].label_pos), pid])
		order.sort_custom(func(a, b): return a[0] < b[0])
		for e in order:
			if taken >= 3:
				break
			var pr = gs.provinces[e[1]]
			var d = gs.armies.get(pr.id)
			if d != null and d.owner == host:
				gs.armies.erase(pr.id)
			pr.controller = gs.player
			pr.siege = 0
			gs.province_changed.emit(pr.id)
			taken += 1
		apply_fx(gs, {"support": 8.0, "legit": -4.0})
		gs.post_news(("DARBE BAŞARILI: %s, %s'nin %d eyaletini bir anda ele geçirdi!" % [f.name, gs.countries[host].name, taken]) if _tr() else ("COUP SUCCEEDS: %s seized %d provinces of %s at once!" % [f.name, taken, gs.countries[host].name]), f.capital, "war_player")
		gs.refresh_stats()
		return Loc.t("Darbe başarılı!")
	apply_fx(gs, {"troops": -int(f.troops * 0.4), "secrecy": -100.0, "support": -10.0, "legit": -6.0})
	gs.post_news(("Darbe girişimi bastırıldı: %s ağır kayıp verdi, çatışma başladı." % f.name) if _tr() else ("The coup attempt was crushed: %s took heavy losses and fighting has begun." % f.name), f.capital, "war_player")
	return Loc.t("Darbe başarısız oldu.")


static func f_truce_clear(gs) -> void:
	var host: int = int(gs.indep.host)
	gs.countries[gs.player].truce.erase(host)
	gs.countries[host].truce.erase(gs.player)


static func _referendum(gs) -> String:
	var s: Dictionary = gs.indep
	var p: float = referendum_chance(gs)
	s.ref_done = true
	if gs.rng.randf() < p:
		gs.post_news("REFERANDUM: Halk %s için bağımsızlığa oy verdi!" % gs.countries[gs.player].name if _tr() else "REFERENDUM: The people voted for independence for %s!" % gs.countries[gs.player].name, gs.countries[gs.player].capital, "war_player")
		apply_fx(gs, {"legit": 8.0, "support": 5.0})
		declare_independence(gs, false)
		return Loc.t("Referandum kazanıldı: bağımsızlık ilan edildi!")
	apply_fx(gs, {"support": -15.0, "legit": -4.0})
	return Loc.t("Referandum kaybedildi; halk bölündü.")


static func declare_independence(gs, unilateral: bool) -> void:
	var s: Dictionary = gs.indep
	s.phase = 3
	s.phase_turn = gs.turn
	var f = gs.countries[gs.player]
	gs.post_news(("%s bağımsızlığını ilan etti!" % f.name) if _tr() else ("%s has declared independence!" % f.name), f.capital, "war_player")
	if unilateral:
		var host: int = int(s.host)
		if not gs.at_war(gs.player, host) and gs.rng.randf() < 0.6:
			gs.declare_war(host, gs.player)
	_show(gs, _card_data(CONST_CARD))


static func _un_apply(gs) -> String:
	var s: Dictionary = gs.indep
	var p: float = un_chance(gs)
	s.un_tries = int(s.un_tries) + 1
	if gs.rng.randf() < p:
		s.phase = 4
		s.phase_turn = gs.turn
		gs.post_news("BM, %s devletini üyeliğe kabul etti!" % gs.countries[gs.player].name if _tr() else "The UN admitted %s as a member!" % gs.countries[gs.player].name, gs.countries[gs.player].capital, "war_player")
		apply_fx(gs, {"legit": 12.0, "stab": 3.0})
		return Loc.t("BM üyeliği kabul edildi!")
	apply_fx(gs, {"legit": -3.0})
	return Loc.t("BM başvurusu reddedildi (veto ya da yetersiz oy).")


# ------------------------------------------------------------------ haftalık

static func tick(gs) -> void:
	if not active(gs) or gs.player < 0:
		return
	var s: Dictionary = gs.indep
	var f = gs.countries[gs.player]
	if not f.alive or bool(s.won):
		return
	var ph: int = int(s.phase)
	# doğal akış
	s.support = clampf(float(s.support) + (f.stability - 50.0) * 0.01 - 0.02 * float(maxi(0, int(s.dep) - 2)), 0.0, 100.0)
	if ph == 0:
		s.secrecy = clampf(float(s.secrecy) + 0.2, 0.0, 100.0)
		if float(s.secrecy) < 25.0 and gs.rng.randf() < 0.08:
			apply_fx(gs, {"support": -4.0, "troops": -600, "secrecy": 8.0})
			gs.post_news(("Güvenlik güçleri %s hücrelerine baskın düzenledi." % f.name) if _tr() else ("Security forces raided %s cells." % f.name), f.capital, "war_player")
		if float(s.secrecy) <= 0.0:
			start_uprising(gs)
	# halk desteği gönüllü akışı sağlar (ana vatanın büyüklüğüne oranlı)
	if float(s.support) > 45.0 and gs.turn % 2 == 0:
		var cap: float = float(s.host_troops) * 0.35
		if float(f.troops) < cap:
			var loc_mul: float = 0.6 + 1.2 * Districts.total_control(gs) if Districts.active(gs) else 1.0
			_add_troops(gs, int((float(s.support) - 40.0) / 60.0 * 0.0012 * float(s.host_troops) * (1.0 if ph >= 1 else 0.3) * loc_mul))
	# karar kartı
	if gs.turn >= int(s.next_card) and (s.pending as Dictionary).is_empty():
		var c: Dictionary = _draw(gs)
		s.next_card = gs.turn + gs.rng.randi_range(6, 9)
		if not c.is_empty():
			_show(gs, _card_data(c))
	# destek / tanınma / gruplar
	s.weeks4 = int(s.weeks4) + 1
	if int(s.weeks4) % 4 == 0:
		_patron_tick(gs)
	if int(s.weeks4) % 2 == 0:
		_recognition_tick(gs)
	_group_tick(gs)
	if int(s.get("grace", 0)) > 0 and gs.turn >= int(s.grace):
		s["grace"] = 0
		s["war_turn"] = gs.turn
		f.truce.erase(int(s.host))
		gs.countries[int(s.host)].truce.erase(gs.player)
		gs.declare_war(gs.player, int(s.host), true)
		gs._call_allies_of(int(s.host), gs.player)
		_war_news(gs)
	Districts.tick(gs)
	_check_phase(gs)


## Gerilla dengesi: merkez güçleri ülkenin her yanında düzeni korumak zorunda olduğundan isyana tek seferde
## tüm ordusunu yığamaz; yerel halk da kendi şehrini savunur. (att_ölçek, savunma_çarpanı) döner.
static func war_mod(gs, att, def, dest: int) -> Vector2:
	if not active(gs) or gs.player < 0 or int(gs.indep.phase) > 2:
		return Vector2.ONE
	if att.owner != int(gs.indep.host) or def.owner != gs.player:
		return Vector2.ONE
	var weeks: int = maxi(0, gs.turn - int(gs.indep.get("war_turn", gs.turn)))
	var loc: float = 1.0 + 1.5 * Districts.control(gs, dest)
	var eqa: float = float(gs.countries[att.owner].eq_land)
	var eqd: float = float(gs.countries[def.owner].eq_land)
	var dp_est: float = float(def.size) * eqd * 1.27 * loc
	var cap: float = 4000.0 * eqa + 0.55 * dp_est + 250.0 * float(weeks) * eqa
	var sc: float = minf(1.0, cap / maxf(float(att.size) * eqa, 1.0))
	return Vector2(sc, loc)


static func _check_phase(gs) -> void:
	var s: Dictionary = gs.indep
	var ph: int = int(s.phase)
	var f = gs.countries[gs.player]
	var age: int = gs.turn - int(s.phase_turn)
	if ph == 1:
		var need: int = maxi(3, int(s.start_n) + 1)
		if ((held(gs) >= need and age >= 8) or (age >= 26 and held(gs) >= int(s.start_n))) and Districts.local_ok(gs):
			s.phase = 2
			s.phase_turn = gs.turn
			gs.post_news(("Çatışma yeni bir aşamaya girdi: arabulucular %s ile merkezi masaya çağırıyor." % f.name) if _tr() else ("The conflict enters a new stage: mediators call %s and the center to the table." % f.name), f.capital, "war_player")
	elif ph == 4:
		var ok: bool = f.stability >= 50.0 and int(s.dep) <= 3 and owned(gs) >= 1
		s["good"] = (int(s.get("good", 0)) + 1) if ok else 0
		if int(s.good) >= 52:
			s.won = true
			gs.victory_declared = true
			gs.game_over.emit(true, Loc.t("Bağımsızlık Yolu tamamlandı: devleti kurdun, tanıttın ve ayakta tuttun."))


static func consolidation_weeks(gs) -> int:
	return int(gs.indep.get("good", 0)) if int(gs.indep.phase) == 4 else 0
