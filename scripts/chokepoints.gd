extends RefCounted
## Stratejik geçitler: boğazlar ve kanallar. Anahtar eyaleti kontrol eden ülke geçişi yönetir:
##   open  = serbest geçiş (varsayılan)
##   toll  = geçiş ücreti: kontrolcünün geliri artar, müttefik olmayanlar küçük bir bedel öder
##   enemy = düşmanlara kapalı: savaştaki/ambargodaki ülkelerin geliri düşer
##   all   = herkese kapalı (müttefikler hariç): dünya ticareti sarsılır, kontrolcü dünya tepkisi alır
## Etki, haftalık gelir çarpanı olarak Macro.calc içinde uygulanır (Chokepoints.income_mult).

const Loc = preload("res://scripts/loc.gd")

const MODES := ["open", "toll", "enemy", "all"]
const MODE_TR := {"open": "Serbest geçiş", "toll": "Geçiş ücreti", "enemy": "Düşmana kapalı", "all": "Herkese kapalı"}
const MODE_EN := {"open": "Open passage", "toll": "Toll", "enemy": "Closed to enemies", "all": "Closed to all"}
const MODE_DESC_TR := {
	"open": "Gemiler serbestçe geçer. Dünya ticareti rahat, kimse seni suçlamaz.",
	"toll": "Müttefik olmayan ülkelerden geçiş ücreti alırsın: gelirin artar, onların gelirinden küçük bir pay düşer.",
	"enemy": "Savaştığın ve ambargo uyguladığın ülkelerin gemileri geçemez; onların geliri düşer.",
	"all": "Müttefikler dışında kimse geçemez. Dünya ticareti sarsılır; istikrarın düşer, dünya tepkisi büyür.",
}
const MODE_DESC_EN := {
	"open": "Ships pass freely. World trade flows and nobody blames you.",
	"toll": "You charge a toll to non-allied countries: your income rises, theirs dips slightly.",
	"enemy": "Ships of countries you fight or embargo cannot pass; their income falls.",
	"all": "Nobody but allies may pass. World trade is shaken; your stability falls and world backlash grows.",
}
const COOLDOWN := 4          # kontrolcünün modu değiştirebilmesi için beklenen hafta

# prov: anahtar eyalet kimlikleri (ilki karar verir), v: önem (1-3)
const LIST := [
	{"id": "bosphorus", "name": ["İstanbul ve Çanakkale Boğazları", "Bosphorus and Dardanelles"], "prov": [423, 427], "v": 2},
	{"id": "suez", "name": ["Süveyş Kanalı", "Suez Canal"], "prov": [370, 374], "v": 3},
	{"id": "hormuz", "name": ["Hürmüz Boğazı", "Strait of Hormuz"], "prov": [469, 1365], "v": 3},
	{"id": "malacca", "name": ["Malakka Boğazı", "Strait of Malacca"], "prov": [883, 1520], "v": 3},
	{"id": "babelmandeb", "name": ["Babülmendeb", "Bab-el-Mandeb"], "prov": [932, 1755], "v": 2},
	{"id": "gibraltar", "name": ["Cebelitarık Boğazı", "Strait of Gibraltar"], "prov": [648, 815], "v": 2},
	{"id": "panama", "name": ["Panama Kanalı", "Panama Canal"], "prov": [1615, 1613], "v": 2},
	{"id": "danish", "name": ["Danimarka Boğazları", "Danish Straits"], "prov": [1518, 1519], "v": 1},
	{"id": "channel", "name": ["Manş Denizi", "English Channel"], "prov": [503, 525], "v": 2},
]

static var _mult: Dictionary = {}      # ülke id -> bu haftaki gelir çarpanı (kayıt gerekmez; her tur yeniden hesaplanır)


static func _tr() -> bool:
	return Loc.lang == "tr"


static func ids() -> Array:
	var out: Array = []
	for d in LIST:
		out.append(String(d.id))
	return out


static func def_of(id: String) -> Dictionary:
	for d in LIST:
		if String(d.id) == id:
			return d
	return {}


static func name_of(id: String) -> String:
	var d: Dictionary = def_of(id)
	if d.is_empty():
		return id
	var n: Array = d.name
	return String(n[0]) if _tr() else String(n[1])


static func mode_name(m: String) -> String:
	return String(MODE_TR[m]) if _tr() else String(MODE_EN[m])


static func mode_desc(m: String) -> String:
	return String(MODE_DESC_TR[m]) if _tr() else String(MODE_DESC_EN[m])


## gs.chokes: {id: {"mode", "ctrl", "cd"}} — eksikse kurar
static func ensure(gs) -> void:
	if not (gs.chokes is Dictionary):
		gs.chokes = {}
	for d in LIST:
		var id: String = String(d.id)
		if not gs.chokes.has(id):
			gs.chokes[id] = {"mode": "open", "ctrl": controller(gs, id), "cd": 0}


## Anahtar eyaleti fiilen elinde tutan ülke (-1: bilinmiyor)
static func controller(gs, id: String) -> int:
	var d: Dictionary = def_of(id)
	if d.is_empty():
		return -1
	var pid: int = int(d.prov[0])
	if pid < 0 or pid >= gs.provinces.size():
		return -1
	var p = gs.provinces[pid]
	var c: int = int(p.controller)
	if c < 0:
		c = int(p.owner)
	if c >= 0 and not gs.countries[c].alive:
		return -1
	return c


static func mode_of(gs, id: String) -> String:
	ensure(gs)
	return String(gs.chokes[id].get("mode", "open"))


## Oyuncunun kontrol ettiği geçitler
static func held_by(gs, cid: int) -> Array:
	ensure(gs)
	var out: Array = []
	for id in ids():
		if int(gs.chokes[id].get("ctrl", -1)) == cid:
			out.append(id)
	return out


static func holds(gs, id: String, cid: int) -> bool:
	return controller(gs, id) == cid


## Bir geçidin o ülkeye (kontrolcüye göre) etkisi: gelir çarpanı farkı (negatif = zarar)
static func effect_on(gs, id: String, cid: int) -> float:
	ensure(gs)
	var d: Dictionary = def_of(id)
	var st: Dictionary = gs.chokes[id]
	var ctrl: int = int(st.get("ctrl", -1))
	if ctrl < 0 or not gs.countries[ctrl].alive:
		return 0.0
	var v: float = float(d.v)
	var mode: String = String(st.get("mode", "open"))
	var c = gs.countries[cid]
	if cid == ctrl:
		match mode:
			"toll":
				return 0.012 * v
			"all":
				return -0.01 * v
		return 0.0
	var friendly: bool = gs.is_allied(ctrl, cid)
	match mode:
		"toll":
			return 0.0 if friendly else -0.003 * v
		"enemy":
			var hostile: bool = gs.at_war(ctrl, cid) or gs.countries[ctrl].embargo.has(cid) or c.embargo.has(ctrl)
			return -0.025 * v if hostile else 0.0
		"all":
			return 0.0 if friendly else -0.03 * v
	return 0.0


static func income_mult(c) -> float:
	return float(_mult.get(c.id, 1.0))


static func _recompute(gs) -> void:
	_mult.clear()
	for c in gs.countries:
		if not c.alive or c.is_rebel:
			continue
		var m := 0.0
		for id in ids():
			m += effect_on(gs, id, c.id)
		if absf(m) > 0.0001:
			_mult[c.id] = clampf(1.0 + m, 0.8, 1.08)


## Her tur: kontrol değişimi haberi, YZ kararları, çarpanların hesabı, tam kapatmanın bedeli
static func tick(gs) -> void:
	ensure(gs)
	for d in LIST:
		var id: String = String(d.id)
		var st: Dictionary = gs.chokes[id]
		var now: int = controller(gs, id)
		var was: int = int(st.get("ctrl", -1))
		if now != was:
			st["ctrl"] = now
			st["mode"] = "open"
			st["cd"] = 0
			if now >= 0 and was >= 0:
				gs.post_news(_news(("%s artık %s kontrolünde." if _tr() else "%s is now under the control of %s.") % [name_of(id), gs.countries[now].name]), int(d.prov[0]), "war")
		var ctrl: int = int(st.get("ctrl", -1))
		if ctrl < 0:
			continue
		var cc = gs.countries[ctrl]
		if String(st.get("mode", "open")) == "all":
			cc.stability = maxf(5.0, cc.stability - 0.15)
			gs.infamy = minf(100.0, gs.infamy + 0.7)
		elif ctrl != gs.player and (gs.turn + ctrl + int(d.v)) % 8 == 0:
			_ai(gs, id, st, cc, int(d.v))
	_recompute(gs)


static func _news(t: String) -> String:
	return t


static func _ai(gs, id: String, st: Dictionary, cc, v: int) -> void:
	var cur: String = String(st.get("mode", "open"))
	var want := "open"
	if not cc.enemies.is_empty() and v >= 2:
		want = "enemy"
	elif cc.gdp > 0.0 and gs.rng.randf() < 0.25 and v >= 2:
		want = "toll"
	if want == cur:
		return
	st["mode"] = want
	st["cd"] = gs.turn + 1
	if gs.player >= 0 and (effect_on(gs, id, gs.player) < 0.0 or want != "open"):
		var d: Dictionary = def_of(id)
		var tmpl_tr := {"toll": "%s, %s'nda geçiş ücreti uygulamaya başladı.", "enemy": "%s, %s'nı düşman gemilerine kapattı.", "open": "%s, %s'nı yeniden serbest bıraktı."}
		var tmpl_en := {"toll": "%s began charging a toll at the %s.", "enemy": "%s closed the %s to enemy ships.", "open": "%s reopened the %s."}
		var t: String = String((tmpl_tr if _tr() else tmpl_en)[want])
		gs.post_news(t % [cc.name, name_of(id)], int(d.prov[0]), "info")


## Oyuncu bir geçidin modunu değiştirir. Dönüş: "" = tamam, aksi hâlde Türkçe hata (Loc.t ile çevrilir)
static func set_mode(gs, id: String, mode: String) -> String:
	ensure(gs)
	if not MODES.has(mode):
		return "Geçersiz mod."
	var st: Dictionary = gs.chokes[id]
	if int(st.get("ctrl", -1)) != gs.player:
		return "Bu geçidi sen kontrol etmiyorsun."
	if String(st.get("mode", "open")) == mode:
		return ""
	var left: int = int(st.get("cd", 0)) - 1 + COOLDOWN - gs.turn
	if left > 0 and int(st.get("cd", 0)) > 0:
		return Loc.t("Bu geçit için yeni karar %d hafta sonra verilebilir.") % left
	st["mode"] = mode
	st["cd"] = gs.turn + 1
	var d: Dictionary = def_of(id)
	var pn: String = gs.countries[gs.player].name
	var tmpl_tr := {"open": "%s, %s'nı serbest bıraktı.", "toll": "%s, %s'nda geçiş ücreti uygulamaya başladı.", "enemy": "%s, %s'nı düşman gemilerine kapattı.", "all": "%s, %s'nı herkese kapattı: dünya ticareti sarsılıyor!"}
	var tmpl_en := {"open": "%s reopened the %s.", "toll": "%s began charging a toll at the %s.", "enemy": "%s closed the %s to enemy ships.", "all": "%s closed the %s to everyone: world trade is shaken!"}
	gs.post_news(String((tmpl_tr if _tr() else tmpl_en)[mode]) % [pn, name_of(id)], int(d.prov[0]), "info")
	_recompute(gs)
	return ""
