extends RefCounted
## Günlük ve haftalık görevler: gerçek takvime göre (cihaz tarihi) her gün 3, her hafta 3 görev.
## Ödül: Komutan Puanı (rütbe) ve seri sayacı — oyun gücüne etkisi yok (adil, tek oyunculu).
## İlerleme, oyun ne zaman/hangi senaryoda oynanırsa oynansın birikir.

const Settings = preload("res://scripts/settings.gd")
const AP = preload("res://scripts/ap.gd")

# kind: turns | captures | battles | orders | peace | alliance | un | landing | strike | war
const DAILY := {
	"easy": [
		{"k": "turns", "n": 5, "t": "5 tur oyna"},
		{"k": "orders", "n": 3, "t": "3 ordu emri ver"},
		{"k": "battles", "n": 2, "t": "2 muharebeye gir"},
	],
	"mid": [
		{"k": "turns", "n": 12, "t": "12 tur oyna"},
		{"k": "captures", "n": 1, "t": "Bir eyalet fethet"},
		{"k": "alliance", "n": 1, "t": "Bir ittifak kur"},
		{"k": "un", "n": 1, "t": "BM'de bir önerge geçir"},
		{"k": "peace", "n": 1, "t": "Bir barış imzala"},
	],
	"hard": [
		{"k": "captures", "n": 3, "t": "3 eyalet fethet"},
		{"k": "battles", "n": 6, "t": "6 muharebeye gir"},
		{"k": "landing", "n": 1, "t": "Amfibi çıkarma yap"},
		{"k": "peace", "n": 2, "t": "2 barış imzala"},
		{"k": "war", "n": 1, "t": "Bir savaş ilan et"},
	],
}
const WEEKLY := {
	"easy": [{"k": "turns", "n": 40, "t": "Bu hafta 40 tur oyna"}, {"k": "battles", "n": 12, "t": "Bu hafta 12 muharebeye gir"}],
	"mid": [{"k": "captures", "n": 6, "t": "Bu hafta 6 eyalet fethet"}, {"k": "peace", "n": 2, "t": "Bu hafta 2 barış imzala"}, {"k": "un", "n": 2, "t": "Bu hafta BM'de 2 önerge geçir"}],
	"hard": [{"k": "captures", "n": 12, "t": "Bu hafta 12 eyalet fethet"}, {"k": "war", "n": 2, "t": "Bu hafta 2 savaş ilan et"}, {"k": "alliance", "n": 3, "t": "Bu hafta 3 ittifak kur"}],
}
const XP_DAILY := {"easy": 10, "mid": 20, "hard": 35}
const XP_WEEKLY := {"easy": 40, "mid": 70, "hard": 120}
const TIERS := ["easy", "mid", "hard"]
const RANKS := [["Çavuş", 0], ["Teğmen", 100], ["Yüzbaşı", 300], ["Binbaşı", 600], ["Albay", 1000], ["Tuğgeneral", 1600],
	["Tümgeneral", 2400], ["Korgeneral", 3400], ["Orgeneral", 4600], ["Mareşal", 6000]]


static func today() -> int:
	return int((Time.get_unix_time_from_system() + _tz_bias()) / 86400.0)


static func _tz_bias() -> float:
	return float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0


static func week_of(day: int) -> int:
	return int((day + 3) / 7)    # 1970-01-01 perşembe: haftalar pazartesi başlar


static func _pick(pool: Array, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _make(table: Dictionary, xp: Dictionary, seed_v: int) -> Array:
	var out: Array = []
	var used := {}
	for i in TIERS.size():
		var tier: String = TIERS[i]
		var pool: Array = table[tier]
		var d: Dictionary = _pick(pool, seed_v * 31 + i * 7 + 1)
		# aynı türde iki görev olmasın
		var tries := 0
		while used.has(d.k) and tries < 8:
			tries += 1
			d = _pick(pool, seed_v * 31 + i * 7 + 1 + tries * 13)
		used[d.k] = true
		out.append({"k": d.k, "n": d.n, "t": d.t, "tier": tier, "xp": xp[tier], "p": 0, "done": false})
	return out


## Gün/hafta değiştiyse görevleri yeniler.
static func ensure_current() -> void:
	var m: Dictionary = Settings.missions
	var day: int = today()
	var wk: int = week_of(day)
	if int(m.get("day", -1)) != day:
		m["day"] = day
		m["daily"] = _make(DAILY, XP_DAILY, day)
	if int(m.get("week", -1)) != wk:
		m["week"] = wk
		m["weekly"] = _make(WEEKLY, XP_WEEKLY, wk + 100000)
	Settings.missions = m


static func rank_of(xp: int) -> Dictionary:
	var idx := 0
	for i in RANKS.size():
		if xp >= int(RANKS[i][1]):
			idx = i
	var nxt: int = int(RANKS[idx + 1][1]) if idx + 1 < RANKS.size() else -1
	return {"name": RANKS[idx][0], "idx": idx, "next": nxt, "base": int(RANKS[idx][1])}


## ilerleme ekle; yeni biten görevlerin listesini ve terfi bilgisini döndürür
static func add(kind: String, n: int) -> Dictionary:
	ensure_current()
	var res := {"done": [], "promoted": "", "ap": 0}
	if n <= 0:
		return res
	var before: int = int(rank_of(Settings.xp).idx)
	var m: Dictionary = Settings.missions
	for key in ["daily", "weekly"]:
		for t in m[key]:
			if t.done or t.k != kind:
				continue
			t.p = mini(int(t.n), int(t.p) + n)
			if int(t.p) >= int(t.n):
				t.done = true
				Settings.xp += int(t.xp)
				res.done.append(t)
				res.ap += AP.MISSION_DAILY if key == "daily" else AP.MISSION_WEEKLY
				if key == "daily":
					_touch_streak()
	if not res.done.is_empty():
		res.ap += _all_done_bonus(m)
		AP.earn(int(res.ap), "mission")
	var after: Dictionary = rank_of(Settings.xp)
	if int(after.idx) > before:
		res.promoted = after.name
	if not res.done.is_empty():
		Settings.save_all()
	return res


## Günün (haftanın) 3 görevi de bitince bir kez ek AP
static func _all_done_bonus(m: Dictionary) -> int:
	var bonus := 0
	if _all_done(m.daily) and int(m.get("bonus_d", -1)) != int(m.day):
		m["bonus_d"] = int(m.day)
		bonus += AP.MISSION_DAILY_ALL
	if _all_done(m.weekly) and int(m.get("bonus_w", -1)) != int(m.week):
		m["bonus_w"] = int(m.week)
		bonus += AP.MISSION_WEEKLY_ALL
	return bonus


static func _all_done(arr: Array) -> bool:
	for t in arr:
		if not t.done:
			return false
	return true


static func _touch_streak() -> void:
	var day: int = today()
	var last: int = int(Settings.streak_day)
	if last == day:
		return
	Settings.streak = (int(Settings.streak) + 1) if last == day - 1 else 1
	Settings.streak_day = day


## Seri hâlâ geçerli mi (dün ya da bugün görev bitirildiyse)
static func streak_now() -> int:
	var day: int = today()
	return int(Settings.streak) if int(Settings.streak_day) >= day - 1 else 0
