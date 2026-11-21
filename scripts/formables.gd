extends RefCounted
## Ülke formlama (Age of History tarzı): eski bir devletin topraklarının yeterli kısmını ele geçirince
## ülke adı ve bayrağı değişir, eyaletler öz toprak olur, ödül gelir. Yalnızca günümüz haritasında.

const Eras = preload("res://scripts/eras.gd")
const Flags = preload("res://scripts/flags.gd")
const Cmd = preload("res://scripts/cmd.gd")

static var _data: Array = []


static func all() -> Array:
	if _data.is_empty():
		var f := FileAccess.open("res://data/formables.json", FileAccess.READ)
		if f != null:
			var j = JSON.parse_string(f.get_as_text())
			if j is Array:
				_data = j
	return _data


## Oyuncunun ülkesine açık formlar (zaten formladıysa boş).
static func available(gs) -> Array:
	if gs == null or gs.player < 0 or Eras.current != "":
		return []
	var me = gs.countries[gs.player]
	if me.formed != "":
		return []
	var out: Array = []
	for f in all():
		if (f.former as Array).has(me.name_en):
			out.append(f)
	return out


## {have, total, need, ok}: lands listesindeki eyaletlerden kaçı oyuncunun elinde.
static func progress(gs, f: Dictionary) -> Dictionary:
	var ids := {}
	for c in gs.countries:
		if (f.lands as Array).has(c.name_en) and not c.is_rebel:
			ids[c.id] = true
	var have := 0
	var total := 0
	for p in gs.provinces:
		if ids.has(p.home):
			total += 1
			if p.owner == gs.player:
				have += 1
	var need: int = int(ceil(total * float(f.share)))
	return {"have": have, "total": total, "need": need, "ok": total > 0 and have >= need}


## Formun hedef eyaletleri {pid: true} (haritada gösterim için).
static func target_provinces(gs, f: Dictionary) -> Dictionary:
	var ids := {}
	for c in gs.countries:
		if (f.lands as Array).has(c.name_en) and not c.is_rebel:
			ids[c.id] = true
	var out := {}
	for p in gs.provinces:
		if ids.has(p.home):
			out[p.id] = true
	return out


## Formu uygular; hata metni ("" = başarılı).
static func form(gs, f: Dictionary) -> String:
	var _cmd := Cmd.Scope.new(gs, "Formables.form", [f])
	if not available(gs).has(f):
		return "Bu ülkeyi şu an formlayamazsın."
	var pr: Dictionary = progress(gs, f)
	if not pr.ok:
		return "Yeterli toprak yok: %d / %d eyalet." % [pr.have, pr.need]
	var me = gs.countries[gs.player]
	var old: String = me.name
	me.name = f.name
	me.formed = f.id
	me.flag_spec = f.flag
	Flags.clear_cache()
	var ids := {}
	for c in gs.countries:
		if (f.lands as Array).has(c.name_en) and not c.is_rebel:
			ids[c.id] = true
	for p in gs.provinces:
		if p.owner == gs.player and ids.has(p.home):
			p.core = gs.player
			p.unrest = 0
	me.stability = minf(100.0, me.stability + 10.0)
	me.gold += maxf(me.income, 1.0) * 6.0
	for c in gs.countries:
		if c.alive and not c.is_rebel and c.id != gs.player:
			c.relation[gs.player] = maxf(0.0, float(c.relation.get(gs.player, 50.0)) - 3.0)
	gs.post_news("%s, tarihî topraklarını birleştirip %s ilan etti!" % [old, f.name], me.capital, "war_player")
	gs.refresh_stats()
	gs.state_changed.emit()
	for p in gs.provinces:
		if p.owner == gs.player:
			gs.province_changed.emit(p.id)
	return ""
