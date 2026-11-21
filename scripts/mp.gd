extends RefCounted
## Çok oyunculu (aynı telefonda sırayla): oyuncu slotları, sıra geçişi, bitiş koşulları.
## Mantık GameState.humans / hs_i üzerinde çalışır; arayüz mp_ui.gd'dedir.

const MIN_PLAYERS := 2
const MAX_PLAYERS := 6
const Loc = preload("res://scripts/loc.gd")


## Seçilen ülkelerle çok oyunculu oyunu kurar (oyun başlamış olmalı).
static func begin(gs, picks: Array) -> void:
	gs.humans = picks.duplicate()
	gs.hs_i = 0
	for h in gs.humans:
		gs.countries[h].is_player = true
	gs.switch_player(gs.humans[0])
	for h in gs.humans:
		gs.countries[h].is_player = true


static func active(gs) -> bool:
	return gs != null and gs.humans.size() > 1


static func alive_humans(gs) -> Array:
	var r: Array = []
	for h in gs.humans:
		if gs.countries[h].alive:
			r.append(h)
	return r


static func _first_alive(gs) -> int:
	for i in gs.humans.size():
		if gs.countries[gs.humans[i]].alive:
			return i
	return -1


## Mevcut insan turunu bitirdi. Dönüş: {"round_done": bool, "next": ülke kimliği}
## round_done=true ise ardından gs.end_turn() çağrılmalı (çağıran yapar), sonra begin_round().
static func finish_seat(gs) -> Dictionary:
	var i: int = gs.hs_i + 1
	while i < gs.humans.size():
		if gs.countries[gs.humans[i]].alive:
			gs.hs_i = i
			gs.switch_player(gs.humans[i])
			_flag_all(gs)
			return {"round_done": false, "next": gs.humans[i]}
		i += 1
	return {"round_done": true, "next": -1}


## Tur hesabından sonra yeni turu ilk yaşayan insanla başlatır.
static func begin_round(gs) -> int:
	var i: int = _first_alive(gs)
	if i < 0:
		return -1
	gs.hs_i = i
	gs.switch_player(gs.humans[i])
	_flag_all(gs)
	return gs.humans[i]


## Tur hesabından önce oyuncuyu ilk koltuğa alır (gelen teklifler ilk insana gitsin diye).
static func prepare_round(gs) -> void:
	var i: int = _first_alive(gs)
	if i >= 0 and gs.humans[i] != gs.player:
		gs.hs_i = i
		gs.switch_player(gs.humans[i])
		_flag_all(gs)


static func _flag_all(gs) -> void:
	for h in gs.humans:
		gs.countries[h].is_player = true


## Bitiş: son insan kalırsa ya da biri dünya/ekonomi eşiğine ulaşırsa metin döner, yoksa "".
static func check_end(gs) -> String:
	if not active(gs) or gs.victory_declared:
		return ""
	var live: Array = alive_humans(gs)
	if live.size() == 1:
		gs.victory_declared = true
		return Loc.t("Tek ayakta kalan: %s. Oyun bitti.") % gs.countries[live[0]].name
	if live.is_empty():
		gs.victory_declared = true
		return Loc.t("Tüm oyuncular devrildi.")
	var total: int = gs.provinces.size()
	for h in live:
		var owned: int = gs.countries[h].prov_owned
		if float(owned) / total >= gs.VICTORY_RATIO:
			gs.victory_declared = true
			return Loc.t("%s dünyanın %%%d'ine hükmediyor. Cihan hâkimiyeti onun!") % [gs.countries[h].name, int(100.0 * owned / total)]
	if gs.turn % 4 == 0:
		var tot := 0.0
		var mine: Dictionary = {}
		for p in gs.provinces:
			if p.owner >= 0 and not gs.countries[p.owner].is_rebel:
				tot += p.gdp
				if live.has(p.owner):
					mine[p.owner] = float(mine.get(p.owner, 0.0)) + p.gdp
		for h in live:
			if tot > 0.0 and float(mine.get(h, 0.0)) / tot >= gs.ECON_RATIO:
				gs.victory_declared = true
				return Loc.t("%s dünya ekonomisinin %%%d'ini kontrol ediyor. Ekonomik hegemonya onun!") % [gs.countries[h].name, int(100.0 * float(mine[h]) / tot)]
	return ""
