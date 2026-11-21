extends RefCounted
## Çok oyunculu oda mantığı (ağdan bağımsız): sunucu bu sınıfı kullanır, testler ağsız çalıştırır.
## Eşzamanlı tur: herkes emirlerini gönderir, hepsi "hazır" deyince (ya da süre dolunca) tur işlenir.

const GS = preload("res://scripts/game_state.gd")
const Cmd = preload("res://scripts/cmd.gd")
const Mp = preload("res://scripts/mp.gd")
const FleetsM = preload("res://scripts/fleets.gd")
const AirM = preload("res://scripts/air.gd")

var gs = null
var cmds: Dictionary = {}       # cid -> bekleyen komutlar (Array)
var ready: Dictionary = {}      # cid -> bool
var afk: Dictionary = {}        # cid -> bool (yapay zekâ devraldı)
var missed: Dictionary = {}     # cid -> üst üste kaçırılan tur sayısı
var last_report: Dictionary = {}
var rng := RandomNumberGenerator.new()


## Dünya durumundan oda kurar (gs: başlamış oyun; picks: insan ülkeleri).
func setup(g, picks: Array) -> void:
	gs = g
	gs.humans = picks.duplicate()
	gs.hs_i = 0
	gs.cmd_log = null
	FleetsM.ensure(gs)       # filo/uçak kimlikleri ilk görüntüden önce sabitlensin (istemciler aynı kimlikleri görsün)
	AirM.ensure(gs)
	for h in picks:
		gs.countries[h].is_player = true
		cmds[h] = []
		ready[h] = false
		afk[h] = false
	gs.player = -1


func is_human(cid: int) -> bool:
	return gs.humans.has(cid)


## Oyuncunun o tura ait komutlarını (kayıt listesi) ekler; yinelenen gönderimde öncekini değiştirir.
func submit(cid: int, list: Array) -> bool:
	if not is_human(cid) or not gs.countries[cid].alive:
		return false
	cmds[cid] = list.duplicate(true)
	return true


func set_ready(cid: int, v: bool) -> void:
	if is_human(cid):
		ready[cid] = v


func set_afk(cid: int, v: bool) -> void:
	if is_human(cid):
		afk[cid] = v


## Yaşayan ve AFK olmayan herkes hazır mı?
func all_ready() -> bool:
	var any := false
	for h in gs.humans:
		if not gs.countries[h].alive:
			continue
		if bool(afk.get(h, false)):
			continue
		any = true
		if not bool(ready.get(h, false)):
			return false
	return any


## Yaşayan ve yapay zekâ devralmamış insan sayısı.
func active_count() -> int:
	var n := 0
	for h in gs.humans:
		if gs.countries[h].alive and not bool(afk.get(h, false)):
			n += 1
	return n


func waiting_for() -> Array:
	var r: Array = []
	for h in gs.humans:
		if gs.countries[h].alive and not bool(afk.get(h, false)) and not bool(ready.get(h, false)):
			r.append(h)
	return r


## Turu işler: komutlar rastgele sırayla yeniden oynatılır (adil sıra), sonra dünya tur hesabı.
## AFK oyuncuların ülkesini yapay zekâ yönetir. Dönüş: {"turn": yeni tur, "results": {cid: [sonuçlar]}, "rejected": n}
func process_round() -> Dictionary:
	var order: Array = gs.humans.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	var results: Dictionary = {}
	var rejected := 0
	for cid in order:
		if not gs.countries[cid].alive:
			continue
		var res: Array = []
		for c in cmds.get(cid, []):
			var r: Dictionary = Cmd.replay(gs, cid, c)
			res.append({"n": c.get("n", ""), "ok": r.ok, "res": r.res if (r.res is String or r.res is int or r.res is float or r.res is bool) else null})
			if not r.ok:
				rejected += 1
		results[cid] = res
	# AFK ülkeler: yapay zekâ oynasın
	var humans_keep: Array = gs.humans
	var afk_ids: Array = []
	for h in gs.humans:
		if bool(afk.get(h, false)):
			afk_ids.append(h)
	if not afk_ids.is_empty():
		var rest: Array = []
		for h in gs.humans:
			if not afk_ids.has(h):
				rest.append(h)
		gs.humans = rest
	gs.player = -1
	gs.end_turn()
	gs.humans = humans_keep
	gs.player = -1
	for h in gs.humans:
		cmds[h] = []
		ready[h] = false
	return {"turn": gs.turn, "results": results, "rejected": rejected, "over": Mp.check_end(gs)}
