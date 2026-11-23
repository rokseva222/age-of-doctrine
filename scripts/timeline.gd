extends RefCounted
## Zaman çizelgesi: senaryonun ve tarihî çağın zamanlanmış olayları (geçmiş + gelecek) tarih sırasıyla.
## Oyuncu ileride ne olacağını görebilir (tester isteği: "gelecek olayları simüle et").
const Loc = preload("res://scripts/loc.gd")
const Names = preload("res://scripts/names.gd")
const DataUtil = preload("res://scripts/data_util.gd")
const EraExt = preload("res://scripts/era_ext.gd")
const EraEvents = preload("res://scripts/era_events.gd")
const Eras = preload("res://scripts/eras.gd")
const Objectives = preload("res://scripts/objectives.gd")


## Mevcut turun (yıl*12 + ay) anahtarı
static func _ym_of_turn(turn: int) -> int:
	var days: int = turn * 7 + Names.start_doy
	var year: int = Names.start_year + days / 365
	var doy: int = days % 365
	var m := 0
	while m < 11 and doy >= Names.MONTH_DAYS[m]:
		doy -= Names.MONTH_DAYS[m]
		m += 1
	return year * 12 + m


static func _ym_label(key: int) -> String:
	var y: int = key / 12
	var m: int = key % 12
	return "%s %s" % [Loc.months[m] if m < Loc.months.size() else str(m + 1), Names.year_label(y)]


## [{"key": sıralama anahtarı, "date": metin, "t": olay metni, "done": bool}]
static func list(gs) -> Array:
	var out: Array = []
	var now_key: int = _ym_of_turn(gs.turn)
	# senaryo olayları (başlangıçtan itibaren tur)
	if not gs.scn.is_empty():
		var s: Dictionary = Objectives.src(gs)
		var evs: Array = s.get("events", [])
		for i in evs.size():
			var e: Dictionary = evs[i]
			var tt: int = int(gs.scn.get("start", 0)) + int(e.get("turn", 0))
			var txt: String = String(e.get("t", ""))
			if Loc.lang != "tr" and s.has("en") and (s["en"] as Dictionary).has("events") and (s["en"]["events"] as Dictionary).has(str(i)):
				txt = DataUtil.loc_text(txt, String(s["en"]["events"][str(i)]))
			if txt == "":
				continue
			out.append({"key": tt * 10, "date": Names.date_string(tt), "t": txt, "done": gs.scn.get("fired", {}).has(i)})
	# tarihî çağ olayları (ay bazlı)
	var era: String = Eras.current
	if era != "":
		var pool: Array = EraExt.events(era) if EraExt.has_era(era) else EraEvents.EVENTS
		if EraExt.has_era(era) and EraExt.raw(era).has("inherit_until"):
			pool = pool.duplicate()
			pool.append_array(EraEvents._inherited(era))
		for e in pool:
			if String(e.get("era", "")) != era:
				continue
			var key: int = int(e["y"]) * 12 + int(e["m"]) - 1
			# ay anahtarını tur ölçeğine yaklaştır (sıralama için)
			out.append({"key": key * 43 + 0, "ym": key, "date": _ym_label(key), "t": Loc.t(String(e["t"])), "done": key < now_key})
	# tek ölçekte sırala: senaryo olaylarını aya çevir
	for o in out:
		if not o.has("ym"):
			o["ym"] = _ym_of_turn(int(o["key"]) / 10)
	out.sort_custom(func(a, b): return int(a["ym"]) < int(b["ym"]) if int(a["ym"]) != int(b["ym"]) else String(a["date"]) < String(b["date"]))
	return out


static func available(gs) -> bool:
	return not list(gs).is_empty()
