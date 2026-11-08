extends RefCounted
## İlk dakikalar için yönlendirici hedefler (öğretici) + kalıcı başarımlar.
## Başarımlar Settings.ach içinde saklanır; Google Play Games için `external_unlock` kancası vardır.

const Settings = preload("res://scripts/settings.gd")
const AP = preload("res://scripts/ap.gd")

## kind: "tut" (öğretici adım, sırayla) / "ach" (başarım). stat: gs.stats anahtarı ya da "turn"/"prov"/"countries".
const DEFS := [
	{"id": "t_turn", "kind": "tut", "name": "İlk turu oyna", "desc": "Alttaki oynat düğmesine bas ya da tur ilerlet.", "stat": "turn", "n": 2},
	{"id": "t_move", "kind": "tut", "name": "Bir ordu hareket ettir", "desc": "Bir ordu seç, sonra bir komşu eyalete dokun.", "stat": "orders", "n": 1},
	{"id": "t_war", "kind": "tut", "name": "Savaş ilan et", "desc": "Komşu bir ülkenin eyaletine dokun ve savaş ilan et.", "stat": "p_wars", "n": 1},
	{"id": "t_cap", "kind": "tut", "name": "İlk eyaleti fethet", "desc": "Orduyla düşman eyaletine saldır ve ele geçir.", "stat": "p_captures", "n": 1},
	{"id": "t_peace", "kind": "tut", "name": "Barış yap", "desc": "Savaşı barışla bitir; ganimeti güvene al.", "stat": "p_peaces", "n": 1},
	{"id": "a_cap10", "kind": "ach", "name": "Fatih", "desc": "10 eyalet fethet.", "stat": "p_captures", "n": 10},
	{"id": "a_cap50", "kind": "ach", "name": "İmparator", "desc": "50 eyalet fethet.", "stat": "p_captures", "n": 50},
	{"id": "a_cap150", "kind": "ach", "name": "Cihan Hâkimi", "desc": "150 eyalet fethet.", "stat": "p_captures", "n": 150},
	{"id": "a_battle50", "kind": "ach", "name": "Savaş Tecrübesi", "desc": "50 muharebe yap.", "stat": "p_battles", "n": 50},
	{"id": "a_peace5", "kind": "ach", "name": "Diplomat", "desc": "5 barış anlaşması imzala.", "stat": "p_peaces", "n": 5},
	{"id": "a_ally", "kind": "ach", "name": "Dost Bulan", "desc": "Bir ittifak kur.", "stat": "p_alliances", "n": 1},
	{"id": "a_elim", "kind": "ach", "name": "Devlet Yıkıcı", "desc": "Bir ülkeyi haritadan sil.", "stat": "p_eliminated", "n": 1},
	{"id": "a_un", "kind": "ach", "name": "Salon Diplomasisi", "desc": "Bir BM önergesini kabul ettir.", "stat": "un_passed", "n": 1},
	{"id": "a_landing", "kind": "ach", "name": "Normandiya Ruhu", "desc": "Denizden çıkarma yap.", "stat": "landings", "n": 1},
	{"id": "a_nuke", "kind": "ach", "name": "Pandora'nın Kutusu", "desc": "Nükleer silah kullan. Bedeli ağırdır.", "stat": "nukes", "n": 1},
	{"id": "a_year1", "kind": "ach", "name": "Bir Yıl Dayan", "desc": "52 hafta (1 yıl) oyna.", "stat": "turn", "n": 52},
	{"id": "a_year10", "kind": "ach", "name": "On Yıl", "desc": "520 hafta (10 yıl) oyna.", "stat": "turn", "n": 520},
	{"id": "a_prov30", "kind": "ach", "name": "Büyük Devlet", "desc": "Aynı anda 30 eyalete sahip ol.", "stat": "prov", "n": 30},
]

## Play Games vb. için dışarıdan bağlanabilir: func(id: String) -> void
static var external_unlock: Callable = Callable()


static func value(gs, stat: String) -> int:
	match stat:
		"turn":
			return gs.turn
		"prov":
			return _own(gs)
		_:
			return int(gs.stats.get(stat, 0))


static func _own(gs) -> int:
	var n := 0
	for p in gs.provinces:
		if p.owner == gs.player:
			n += 1
	return n


## Yeni açılanları döndürür (ve kalıcı olarak kaydeder).
static func check(gs) -> Array:
	var fresh: Array = []
	if gs == null or gs.player < 0:
		return fresh
	for d in DEFS:
		if Settings.ach.has(d.id):
			continue
		if value(gs, d.stat) >= int(d.n):
			Settings.ach[d.id] = gs.turn
			fresh.append(d)
			AP.earn(AP.goal_reward(String(d.kind)), "goal")
			if external_unlock.is_valid():
				external_unlock.call(d.id)
	if not fresh.is_empty():
		Settings.save_all()
	return fresh


## Sıradaki tamamlanmamış öğretici adımı (yoksa boş sözlük).
static func next_tutorial() -> Dictionary:
	for d in DEFS:
		if d.kind == "tut" and not Settings.ach.has(d.id):
			return d
	return {}
