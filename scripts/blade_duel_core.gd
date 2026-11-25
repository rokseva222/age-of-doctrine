extends RefCounted
## Kılıç düellosu mantığı (Warband / Bannerlord tarzı, görüntüden bağımsız; başsız testte kullanılır).
## Dört yön: 0 sol vuruş, 1 üstten vuruş, 2 sağ vuruş, 3 saplama. Her savaşçı bir yöne SİPER tutar ya da bir yöne VURUR.
## Vuruş: kılıç kalkar (hazırlık) → temas. Hazırlığın ilk yarısında yön değiştirilebilir (aldatma) ya da vazgeçilebilir.
## Siper doğru yöne tutulmuşsa vuruş durdurulur; siper vuruşa az kala (tepkisel) kaldırıldıysa KUSURSUZ SİPER: saldıran sendeler.
## Yanlış yön ya da siper yok: isabet, hasar ve kısa sersemleme. Vuruş sırasında siper tutulamaz.
## Oyuncu = p, rakip = f (yapay zekâ).

const DIRS := ["Sol", "Üst", "Sağ", "Saplama"]
const DMG := [1.0, 1.12, 1.0, 1.18]            # yöne göre hasar çarpanı
const PERFECT_WIN := 0.32                      # siper temastan en çok bu kadar önce kalktıysa kusursuz sayılır
const FEINT_FRAC := 0.5                        # hazırlığın bu kadarında sonra yön değişmez
const TIME_CAP := 90.0


class Fighter extends RefCounted:
	var hp := 100.0
	var state := "idle"      # idle | wind | recover | stagger
	var t := 0.0
	var dur := 0.0
	var dir := 1             # vuruş yönü (wind sırasında)
	var guard := -1          # tutulan siper (-1 yok)
	var guard_since := -9.0
	var power := 1.0
	var wind_id := 0
	var redirected := false

	func can_guard() -> bool:
		return state == "idle" or state == "recover"


var p := Fighter.new()
var f := Fighter.new()
var skill := 0.3           # oyuncu becerisi 0..1 (hazırlık süresini biraz kısaltır)
var power := 1.0           # rakip gücü 0.7..1.5
var aq := 0.5              # rakip yapay zekâ kalitesi 0..1 (power'dan)
var rng := RandomNumberGenerator.new()
var clock := 0.0
var outcome := ""
var events: Array = []     # [ad, veri] - görüntü tüketir
# yapay zekâ durumu
var _ai_react := 0.0
var _ai_seen := -1
var _ai_seen_dir := -1
var _ai_target := -1
var _ai_next_attack := 1.2
var _ai_next_idle := 0.6


func setup(skill_: float, power_: float, seed_: int = -1) -> void:
	skill = clampf(skill_, 0.0, 1.0)
	power = clampf(power_, 0.7, 1.5)
	aq = clampf((power - 0.7) / 0.8, 0.0, 1.0)
	f.power = power
	if seed_ >= 0:
		rng.seed = seed_
	else:
		rng.randomize()


func _ev(n: String, d = null) -> void:
	events.append([n, d])


func _wind_time(fi: Fighter) -> float:
	if fi == p:
		return 0.46 * (1.0 - 0.15 * skill)
	return lerpf(0.66, 0.44, aq)


func _other(fi: Fighter) -> Fighter:
	return f if fi == p else p


func _who(fi: Fighter) -> String:
	return "p" if fi == p else "f"


# ------------------------------------------------------------------ oyuncu girdisi
func player_guard(d: int) -> void:
	_guard(p, d)


func player_attack(d: int) -> void:
	_attack(p, d)


func player_redirect(d: int) -> void:
	_redirect(p, d)


func player_feint() -> void:
	_feint(p)


func _guard(fi: Fighter, d: int) -> void:
	if outcome != "" or d < -1 or d > 3 or not fi.can_guard():
		return
	if d != fi.guard:
		fi.guard = d
		fi.guard_since = clock
		_ev("guard", [_who(fi), d])


func _attack(fi: Fighter, d: int) -> void:
	if outcome != "" or d < 0 or d > 3 or fi.state != "idle":
		return
	fi.state = "wind"
	fi.t = 0.0
	fi.dur = _wind_time(fi)
	fi.dir = d
	fi.guard = -1
	fi.wind_id += 1
	fi.redirected = false
	_ev("wind", [_who(fi), d])


func _redirect(fi: Fighter, d: int) -> void:
	if fi.state != "wind" or d < 0 or d > 3 or d == fi.dir or fi.t > fi.dur * FEINT_FRAC:
		return
	fi.dir = d
	fi.redirected = true
	fi.wind_id += 1
	_ev("redirect", [_who(fi), d])


func _feint(fi: Fighter) -> void:
	if fi.state != "wind" or fi.t > fi.dur * FEINT_FRAC:
		return
	fi.state = "recover"
	fi.t = 0.0
	fi.dur = 0.2
	_ev("feint", _who(fi))


# ------------------------------------------------------------------ zaman
func update(dt: float) -> void:
	if outcome != "":
		return
	clock += dt
	p.t += dt
	f.t += dt
	_ai(dt)
	var due: Array = []
	for fi in [p, f]:
		if fi.state == "wind" and fi.t >= fi.dur:
			due.append(fi)
	due.sort_custom(func(a, b): return (a.t - a.dur) > (b.t - b.dur))    # temasa önce varan önce çözülür
	for att in due:
		if att.state == "wind":
			_contact(att, _other(att))
	for fi in [p, f]:
		if (fi.state == "recover" or fi.state == "stagger") and fi.t >= fi.dur:
			fi.state = "idle"
			fi.t = 0.0
	_check_end()


func _contact(att: Fighter, de: Fighter) -> void:
	var d: int = att.dir
	if de.can_guard() and de.guard == d:
		if clock - de.guard_since <= PERFECT_WIN:
			att.state = "stagger"
			att.t = 0.0
			att.dur = 0.95
			_ev("parry", [_who(de), true])
		else:
			att.state = "recover"
			att.t = 0.0
			att.dur = 0.55
			_ev("parry", [_who(de), false])
		return
	var dmg: float
	if att == p:
		dmg = 14.0 * float(DMG[d]) * (1.0 + 0.25 * skill)
	else:
		dmg = 13.0 * float(DMG[d]) * att.power
	de.hp = maxf(0.0, de.hp - dmg)
	de.state = "stagger"
	de.t = 0.0
	de.dur = 0.4
	de.guard = -1
	att.state = "recover"
	att.t = 0.0
	att.dur = 0.35
	_ev("hit", [_who(de), dmg, d])


func _check_end() -> void:
	if outcome != "":
		return
	if p.hp <= 0.0 and f.hp <= 0.0:
		outcome = "draw"
	elif f.hp <= 0.0:
		outcome = "win"
	elif p.hp <= 0.0:
		outcome = "lose"
	elif clock >= TIME_CAP:
		outcome = "win" if f.hp < p.hp else ("lose" if p.hp < f.hp else "draw")
	if outcome != "":
		_ev("over", outcome)


# ------------------------------------------------------------------ rakip yapay zekâsı
func _ai(dt: float) -> void:
	# savunma: oyuncunun vuruşunu oku; tepki süresinden sonra (çoğu zaman doğru) yöne siper al
	if p.state == "wind":
		if _ai_seen != p.wind_id:
			_ai_seen = p.wind_id
			_ai_seen_dir = p.dir
			_ai_react = lerpf(0.34, 0.14, aq) + rng.randf() * 0.06
			var acc: float = lerpf(0.50, 0.93, aq)
			if rng.randf() < acc:
				_ai_target = p.dir
			else:
				_ai_target = (p.dir + 1 + rng.randi() % 3) % 4
		_ai_react -= dt
		if _ai_react <= 0.0 and f.can_guard():
			_guard(f, _ai_target)
	else:
		_ai_seen = -1
		# boştayken siper yönünü ara sıra değiştirir
		_ai_next_idle -= dt
		if _ai_next_idle <= 0.0 and f.can_guard():
			_ai_next_idle = lerpf(1.3, 0.8, aq) + rng.randf() * 0.5
			_guard(f, rng.randi() % 4 if rng.randf() < 0.85 else -1)
	# saldırı
	_ai_next_attack -= dt
	if _ai_next_attack <= 0.0 and f.state == "idle":
		if p.state == "wind" and rng.randf() > 0.25:
			_ai_next_attack = 0.15
		else:
			var d: int = rng.randi() % 4
			if p.guard >= 0 and rng.randf() < aq:
				d = (p.guard + 1 + rng.randi() % 3) % 4          # iyi rakip, oyuncunun siper tuttuğu yöne vurmaz
			_attack(f, d)
			_ai_next_attack = lerpf(1.6, 0.8, aq) + rng.randf() * 0.7
	# aldatma: hazırlığın başında yön değiştirir
	if f.state == "wind" and not f.redirected and f.t > f.dur * 0.2 and f.t < f.dur * 0.45:
		if rng.randf() < dt * 1.6 * aq:
			_redirect(f, (f.dir + 1 + rng.randi() % 3) % 4)
