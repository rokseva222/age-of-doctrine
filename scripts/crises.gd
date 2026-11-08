extends RefCounted
## Dünya krizleri: oyun ortasında tüm ülkeleri hafifçe etkileyen, süreli olaylar (salgın, mali çöküş, kıtlık, enerji şoku).
## Tasarım kuralı: ASLA boğucu olmasın. Etki gelirde en çok ~%9, istikrarda haftada ~0.25 puan; oyuncuya hep bir
## karşılık verme şansı tanınır; zorluk ayarı şiddeti kısar; isyan zaten yüksekse (istikrar düşükse) kriz başlamaz.

const Names = preload("res://scripts/names.gd")
const Eras = preload("res://scripts/eras.gd")

const FIRST_TURN := 45          # ilk kriz bundan önce çıkmaz
const COOLDOWN := 60            # bir kriz bittikten sonra bu kadar hafta yenisi çıkmaz
const MIN_STABILITY := 45.0     # oyuncunun istikrarı bunun altındaysa kriz başlamaz

# inc: gelir kaybı (şiddet 1.0'da), stab: haftalık istikrar kaybı, dur: [en az, en çok] hafta, eras: hangi dönemlerde ("" = modern)
const KINDS := {
	"pandemic": {"name": "Küresel Salgın", "icon": "virus", "inc": 0.08, "stab": 0.25, "dur": [10, 16], "eras": ["", "ww1", "ww2"], "role": "hlt",
		"names": {"ww1": "İspanyol Gribi", "ww2": "Salgın Hastalık"},
		"q": "Efendim, ülkeye bir salgın giriyor ve tüm dünyada yayılıyor. Sağlık sistemi zorlanacak. Ne yapalım?"},
	"crash": {"name": "Küresel Mali Çöküş", "icon": "debt", "inc": 0.09, "stab": 0.22, "dur": [12, 18], "eras": ["", "ww1", "ww2"], "role": "fin",
		"names": {"ww1": "Mali Panik", "ww2": "Büyük Buhran Artçısı"},
		"q": "Efendim, borsalar çöküyor ve bankalar sallanıyor. Kriz tüm dünyayı sarıyor. Hazine ne yapsın?"},
	"famine": {"name": "Kıtlık ve Gıda Krizi", "icon": "wheat", "inc": 0.06, "stab": 0.30, "dur": [10, 15], "eras": ["", "ww1", "ww2"], "role": "int",
		"names": {},
		"q": "Efendim, kuraklık ve nakliye sorunları gıda fiyatlarını uçurdu. Halk ekmek kuyruğunda. Ne yapalım?"},
	"energy": {"name": "Enerji Şoku", "icon": "oil", "inc": 0.07, "stab": 0.18, "dur": [10, 14], "eras": ["", "ww2"], "role": "fin",
		"names": {"ww2": "Yakıt Kıtlığı"},
		"q": "Efendim, petrol fiyatları fırladı; sanayi ve ulaşım zorlanıyor. Ne yapalım?"},
}


static func sev_mult(gs) -> float:
	return [0.6, 0.8, 1.0][clampi(gs.difficulty, 0, 2)]


## Kriz havuzu için çağ ailesi: JSON çağları ("cold" gibi) modern kurallara düşer
static func _fam() -> String:
	var f: String = Eras.family()
	return f if (f == "" or f == "ww1" or f == "ww2") else ""


static func kind_name(kind: String) -> String:
	var k: Dictionary = KINDS[kind]
	return String(k.names.get(_fam(), k.name))


static func active(gs) -> bool:
	return not gs.crisis.is_empty() and gs.turn < int(gs.crisis.end)


## ülkenin bu haftaki gelir çarpanı (1.0 = etkisiz)
static func income_mult(gs, c) -> float:
	if not active(gs):
		return 1.0
	var k: Dictionary = KINDS[gs.crisis.kind]
	var mit: float = _mit_of(gs, c.id)
	return 1.0 - float(k.inc) * float(gs.crisis.sev) * mit


static func _mit_of(gs, cid: int) -> float:
	if cid == gs.player:
		return float(gs.crisis.get("mit", 1.0))
	return 0.7


static func weekly(gs) -> void:
	if active(gs):
		_tick(gs)
		return
	if not gs.crisis.is_empty():
		_end(gs)
	if gs.turn < FIRST_TURN or gs.turn - gs.crisis_last_end < COOLDOWN:
		return
	if gs.rng.randf() > 0.03:
		return
	if gs.player >= 0 and gs.countries[gs.player].alive and gs.countries[gs.player].stability < MIN_STABILITY:
		return
	_start(gs)


static func _pick_kind(gs) -> String:
	var pool: Array = []
	for k in KINDS:
		if KINDS[k].eras.has(_fam()):
			pool.append(k)
	pool.sort()
	if pool.is_empty():
		return ""
	return pool[gs.rng.randi_range(0, pool.size() - 1)]


static func _start(gs) -> void:
	var kind := _pick_kind(gs)
	if kind == "":
		return
	var k: Dictionary = KINDS[kind]
	var dur: int = gs.rng.randi_range(int(k.dur[0]), int(k.dur[1]))
	gs.crisis = {"kind": kind, "start": gs.turn, "end": gs.turn + dur, "sev": sev_mult(gs), "mit": 1.0}
	gs.post_news(Names.crisis_start(gs.rng, kind_name(kind), dur), -1, "event", String(k.icon))
	if gs.player >= 0 and gs.countries[gs.player].alive:
		gs.crisis_pending = card_for(gs, kind)


static func _tick(gs) -> void:
	var k: Dictionary = KINDS[gs.crisis.kind]
	for c in gs.countries:
		if not c.alive or c.is_rebel:
			continue
		var floor_v: float = 40.0 if c.id == gs.player else 30.0
		if c.stability > floor_v:
			c.stability = maxf(floor_v, c.stability - float(k.stab) * float(gs.crisis.sev) * _mit_of(gs, c.id))


static func _end(gs) -> void:
	var kind: String = gs.crisis.kind
	var mit: float = float(gs.crisis.get("mit", 1.0))
	gs.post_news(Names.crisis_end(gs.rng, kind_name(kind)), -1, "event", "peace")
	if gs.player >= 0 and gs.countries[gs.player].alive and mit < 1.0:
		var c = gs.countries[gs.player]
		c.stability = clampf(c.stability + 3.0, 5.0, 100.0)    # toparlanma ödülü
	gs.crisis_last_end = gs.turn
	gs.crisis = {}


## Kabine kartı biçiminde oyuncuya sorulan karar
static func card_for(gs, kind: String) -> Dictionary:
	var k: Dictionary = KINDS[kind]
	return {"id": "crisis_" + kind, "role": k.role, "w": 0.0, "war": 0,
		"title": kind_name(kind), "q": k.q,
		"o": [
			{"t": "Acil önlem paketi", "e": {"g": -1.6, "mit": 0.35}, "r": "Geniş bir önlem paketi açıklandı. Kriz ülkeni çok az etkileyecek, toparlanma hızlı olacak."},
			{"t": "Kemer sıkma", "e": {"stab": -2, "mit": 0.65}, "r": "Harcamalar kısıldı. Sert ama ucuz bir önlem; halk homurdanıyor."},
			{"t": "Bekle ve izle", "e": {"mit": 1.0}, "r": "Hükümet beklemeyi seçti. Kriz tam etkisini gösterecek, ama bu kadarını atlatırsın."}]}
