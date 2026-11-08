extends Node
## Ses yöneticisi: müzik (menü / barış / savaş / 1. DS / 2. DS) çapraz geçişle, savaş ambiyansı,
## tik-tak ve kısa efektler. Tüm ses dosyaları tools/audio/*.py ile kodla üretilmiştir.

const Settings = preload("res://scripts/settings.gd")
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const EraExt = preload("res://scripts/era_ext.gd")
const MOODS := ["menu", "peace", "war", "ww1", "ww2", "coldwar"]
## Çağ kimliği -> müzik dosyası adı (eksik dosyada barış/savaş müziğine düşülür)
const MOOD_ALIAS := {"cw62": "coldwar"}
const FADE := 2.4                 ## müzik çapraz geçiş süresi (sn)
const WAR_HOLD_MS := 20000        ## savaş bittikten sonra savaş müziği ne kadar sürsün
const MUSIC_GAIN := 0.5
const AMB_GAIN := 0.8
## efekt başına en kısa tekrar aralığı (ms) ve ses payı
const COOLDOWN := {"cannon": 1200, "volley": 3000, "boom": 1500, "tick": 0, "tock": 0, "news": 500, "plane": 6000, "mg": 3000}

var _bank: Dictionary = {}
var _music_cache: Dictionary = {}
var _pool: Array = []
var _pi := 0
var _mp: Array = []               ## iki müzik oynatıcı (A/B)
var _cur := 0
var _mood := ""
var _want := ""
var _amb: AudioStreamPlayer
var _amb_on := false
var _last: Dictionary = {}
var _tock := false
var _war_hold := 0
var _poll := 0.0
var _ticks := 0

## main.gd'nin doldurduğu bağlam: Callable -> {"mode": String, "era": String, "war": bool}
var context_cb: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = -80.0
		add_child(m)
		_mp.append(m)
	_amb = AudioStreamPlayer.new()
	_amb.volume_db = -80.0
	add_child(_amb)
	_load_bank()
	var a = _load_stream(SFX_DIR + "amb_war.ogg")
	if a != null:
		a.loop = true
		_amb.stream = a
	apply_settings()


func _load_stream(path: String):
	if ResourceLoader.exists(path):
		var r = load(path)
		if r != null:
			return r
	# içe aktarılmamış dosya (ör. editörsüz çalıştırma): doğrudan oku
	if FileAccess.file_exists(path):
		return AudioStreamOggVorbis.load_from_file(path)
	return null


func _load_bank() -> void:
	var d := DirAccess.open(SFX_DIR)
	if d == null:
		return
	var names := {}
	for f in d.get_files():
		var base := f.get_basename()
		if f.ends_with(".import"):
			base = f.trim_suffix(".ogg.import")
		elif not f.ends_with(".ogg"):
			continue
		names[base] = true
	for n in names:
		if n == "amb_war":
			continue
		var s = _load_stream(SFX_DIR + n + ".ogg")
		if s != null:
			_bank[n] = s


# ------------------------------------------------------------------ efektler

func play(n: String, vol: float = 1.0, pitch: float = 1.0) -> void:
	if Settings.sfx <= 0.01 or not _bank.has(n):
		return
	var now := Time.get_ticks_msec()
	var cd: int = COOLDOWN.get(n, 60)
	if cd > 0 and now - int(_last.get(n, -100000)) < cd:
		return
	_last[n] = now
	var p: AudioStreamPlayer = _pool[_pi]
	_pi = (_pi + 1) % _pool.size()
	p.stream = _bank[n]
	p.volume_db = linear_to_db(maxf(Settings.sfx * clampf(vol, 0.7, 1.0), 0.0001))  # tüm efektler aynı seviyede
	p.pitch_scale = pitch
	p.play()


## Her hafta ilerleyişinde saat tik-takı (hızlı modlarda seyreltilir).
func turn_tick(speed_idx: int) -> void:
	_ticks += 1
	if speed_idx >= 3 and _ticks % 2 == 1:
		return
	_tock = not _tock
	play("tock" if _tock else "tick", 0.5 if speed_idx < 3 else 0.35, 1.0 + (0.04 if speed_idx >= 2 else 0.0))


## Haber türüne göre ses.
func news_kind(kind: String) -> void:
	match kind:
		"war_player":
			play("war", 0.8)
		"lost_player":
			play("alarm", 0.7)
			play("boom", 0.5)
		"capture_player":
			play("capture", 0.9)
		"capture":
			play("volley", 0.28)
		"battle":
			play("cannon", 0.4)
		"war":
			play("radio", 0.4)
		"peace":
			play("peace", 0.6)
		"alliance":
			play("bell", 0.55)
		"elim":
			play("boom", 0.6)
		"rebel_player":
			play("siren", 0.55)
		"rebel":
			play("mg", 0.3)
		"cyber":
			play("cyber", 0.55)
		"event_player":
			play("paper", 0.6)
		"rank":
			play("paper", 0.35)


# ------------------------------------------------------------------ müzik

func _music_stream(m: String):
	if not _music_cache.has(m):
		var s = _load_stream(MUSIC_DIR + m + ".ogg")
		if s != null:
			s.loop = true
		_music_cache[m] = s
	return _music_cache[m]


func set_mood(m: String) -> void:
	_want = m
	if m == _mood:
		return
	_mood = m
	if Settings.music <= 0.01 or m == "":
		return
	var s = _music_stream(m)
	if s == null:
		return
	var old: AudioStreamPlayer = _mp[_cur]
	_cur = 1 - _cur
	var nw: AudioStreamPlayer = _mp[_cur]
	nw.stream = s
	nw.volume_db = -80.0
	nw.play()
	var target := _music_db()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nw, "volume_db", target, FADE)
	if old.playing:
		tw.tween_property(old, "volume_db", -80.0, FADE)
		tw.chain().tween_callback(func():
			if old != _mp[_cur]:
				old.stop())


func _music_db() -> float:
	return linear_to_db(maxf(Settings.music * MUSIC_GAIN, 0.0001))


func set_ambient(on: bool) -> void:
	if on == _amb_on:
		return
	_amb_on = on
	if _amb.stream == null:
		return
	var db := linear_to_db(maxf(Settings.sfx * AMB_GAIN, 0.0001)) if on and Settings.sfx > 0.01 else -80.0
	if on and not _amb.playing:
		_amb.volume_db = -80.0
		_amb.play()
	var tw := create_tween()
	tw.tween_property(_amb, "volume_db", db, 3.0)
	if not on:
		tw.tween_callback(func():
			if not _amb_on:
				_amb.stop())


func apply_settings() -> void:
	if _mp.is_empty():
		return
	if Settings.music <= 0.01:
		for p in _mp:
			p.stop()
			p.volume_db = -80.0
		_mood = ""
	else:
		var cur: AudioStreamPlayer = _mp[_cur]
		if cur.playing:
			cur.volume_db = _music_db()
		elif _want != "":
			set_mood(_want)
	if _amb_on and _amb.playing:
		_amb.volume_db = linear_to_db(maxf(Settings.sfx * AMB_GAIN, 0.0001)) if Settings.sfx > 0.01 else -80.0


func _process(delta: float) -> void:
	_poll += delta
	if _poll < 0.5 or not context_cb.is_valid():
		return
	_poll = 0.0
	var c: Dictionary = context_cb.call()
	var mode: String = c.get("mode", "menu")
	var era: String = c.get("era", "")
	var war: bool = c.get("war", false)
	var now := Time.get_ticks_msec()
	if mode != "game":
		set_mood("menu")
		set_ambient(false)
		return
	if war:
		_war_hold = now + WAR_HOLD_MS
	var fighting: bool = now < _war_hold
	var mood_era: String = MOOD_ALIAS.get(era, era)
	if mood_era != "" and not MOODS.has(mood_era):
		var fam: String = EraExt.field(era, "mood", EraExt.family(era)) if EraExt.has_era(era) else ""
		mood_era = fam if MOODS.has(fam) else ""
	if mood_era != "" and not ResourceLoader.exists(MUSIC_DIR + mood_era + ".ogg"):
		mood_era = ""
	if mood_era != "":
		set_mood(mood_era)
	else:
		set_mood("war" if fighting else "peace")
	set_ambient(fighting)
