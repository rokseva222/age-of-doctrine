extends RefCounted
## Kayıt yuvaları: 0 = otomatik kayıt, 1..3 = elle kayıt. Her yuvanın yanında küçük bir özet (meta) dosyası bulunur.

const AP = preload("res://scripts/ap.gd")

const SLOTS := 3


## Elle kayıt yuvası sayısı (ek yuva satın alınınca artar)
static func slot_count() -> int:
	return SLOTS + AP.slot_bonus()


static func path(slot: int) -> String:
	return "user://save.dat" if slot == 0 else "user://save_%d.dat" % slot


static func meta_path(slot: int) -> String:
	return "user://save.meta" if slot == 0 else "user://save_%d.meta" % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


static func any() -> bool:
	for s in slot_count() + 1:
		if exists(s):
			return true
	return false


## Özet: {name, date, turn, prov, ts, era} ya da boş sözlük
static func meta(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(meta_path(slot), FileAccess.READ)
	if f != null:
		var v = f.get_var()
		f.close()
		if typeof(v) == TYPE_DICTIONARY:
			return v
	return {"name": "", "date": "", "turn": 0, "prov": 0, "ts": FileAccess.get_modified_time(path(slot)), "era": "", "legacy": true}


static func write(gs, slot: int, era: String = "") -> bool:
	if not gs.save_to(path(slot)):
		return false
	var c = gs.countries[gs.player] if gs.player >= 0 else null
	var Names = load("res://scripts/names.gd")
	var m := {"name": c.name if c != null else "", "date": Names.date_string(gs.turn), "turn": gs.turn,
		"prov": c.prov_owned if c != null else 0, "ts": int(Time.get_unix_time_from_system()), "era": era}
	var f := FileAccess.open(meta_path(slot), FileAccess.WRITE)
	if f != null:
		f.store_var(m)
		f.close()
	return true


static func delete(slot: int) -> void:
	for p in [path(slot), meta_path(slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## En yeni kaydın yuvası (yoksa -1).
static func latest() -> int:
	var best := -1
	var best_ts := -1
	for s in slot_count() + 1:
		if not exists(s):
			continue
		var ts: int = int(meta(s).get("ts", 0))
		if ts > best_ts:
			best_ts = ts
			best = s
	return best


static func stamp_text(ts: int) -> String:
	if ts <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(ts + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d.%02d.%d %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]
