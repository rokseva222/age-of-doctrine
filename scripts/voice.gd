extends Node
## Online sesli görüşme: mikrofon → 16 kHz tek kanal 8 bit µ-law → sunucu → aynı görüşme odasındaki oyuncular.
## Görüşme odası: bir oyuncu başkasını çağırır, kabul eden odaya girer (en çok VOICE_MAX kişi).

const TK = preload("res://scripts/theme_kit.gd")
const Sheet = preload("res://scripts/sheet.gd")
const Loc = preload("res://scripts/loc.gd")

const RATE := 16000
const CHUNK := 640            # 40 ms
const BUS := "AodVoiceMic"

var net
var gs_getter: Callable
var ui
var muted := false
var _mic: AudioStreamPlayer
var _cap: AudioEffectCapture
var _running := false
var _acc := 0.0
var _cnt := 0
var _pos := 0.0
var _out := PackedFloat32Array()
var _hang := 0
var _sp := {}                 # cid -> {player, pb}
var _talk := {}               # cid -> son ses zamanı (ms)
var _sheet = null
var _rebuild: Callable = Callable()


func setup(n, getter: Callable, ui_ref) -> void:
	net = n
	gs_getter = getter
	ui = ui_ref
	net.voice_state.connect(_on_state)
	net.voice_audio.connect(_on_audio)
	net.voice_invite.connect(_on_invite)


func in_voice() -> bool:
	return net != null and net.voice_gid != 0


# ---- davet / katılma
func invite(cid: int) -> void:
	net.to_server("srv_voice_invite", [cid])


func leave() -> void:
	net.to_server("srv_voice_leave", [])


func _on_invite(from_cid: int, from_name: String, gid: int) -> void:
	var g = gs_getter.call()
	var who: String = from_name
	if g != null and from_cid >= 0 and from_cid < g.countries.size():
		who = "%s (%s)" % [from_name, g.countries[from_cid].name] if from_name != "" else g.countries[from_cid].name
	ui.show_dialog("Görüşme daveti", Loc.t("%s seni sesli görüşmeye çağırıyor.") % who, [
		{"text": "Katıl", "kind": "good", "cb": func(): net.to_server("srv_voice_accept", [gid])},
		{"text": "Reddet", "cb": func(): pass},
	])


func _on_state() -> void:
	if in_voice():
		_start_mic()
	else:
		_stop_mic()
		for k in _sp.keys():
			_drop_speaker(int(k))
	if _rebuild.is_valid() and _sheet != null and is_instance_valid(_sheet):
		_rebuild.call()


# ---- mikrofon
func _start_mic() -> void:
	if _running:
		return
	if OS.get_name() == "Android":
		var perms: PackedStringArray = OS.get_granted_permissions()
		if not perms.has("android.permission.RECORD_AUDIO"):
			OS.request_permission("RECORD_AUDIO")
	var idx: int = AudioServer.get_bus_index(BUS)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS)
		_cap = AudioEffectCapture.new()
		_cap.buffer_length = 0.5
		AudioServer.add_bus_effect(idx, _cap)
		var amp := AudioEffectAmplify.new()
		amp.volume_db = -80.0          # kendi sesini duyma
		AudioServer.add_bus_effect(idx, amp)
	else:
		_cap = AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture
	if _mic == null:
		_mic = AudioStreamPlayer.new()
		_mic.stream = AudioStreamMicrophone.new()
		_mic.bus = BUS
		add_child(_mic)
	_mic.play()
	_running = true
	_acc = 0.0
	_cnt = 0
	_out.clear()


func _stop_mic() -> void:
	if not _running:
		return
	_running = false
	if _mic != null:
		_mic.stop()
	if _cap != null:
		_cap.clear_buffer()


func set_muted(m: bool) -> void:
	muted = m
	if _cap != null:
		_cap.clear_buffer()


func _process(_dt: float) -> void:
	if _running and _cap != null:
		_pump_mic()
	# konuşma göstergesi süresi dolsun
	if _sheet != null and is_instance_valid(_sheet) and _rebuild.is_valid() and Engine.get_process_frames() % 20 == 0:
		_rebuild.call()


func _pump_mic() -> void:
	var n: int = _cap.get_frames_available()
	if n <= 0:
		return
	var buf: PackedVector2Array = _cap.get_buffer(n)
	if muted:
		return
	var step: float = float(AudioServer.get_mix_rate()) / float(RATE)
	for f in buf:
		_acc += (f.x + f.y) * 0.5
		_cnt += 1
		_pos += 1.0
		if _pos >= step:
			_pos -= step
			_out.append(_acc / float(maxi(_cnt, 1)))
			_acc = 0.0
			_cnt = 0
			if _out.size() >= CHUNK:
				_send_chunk()


func _send_chunk() -> void:
	var e := 0.0
	for s in _out:
		e += s * s
	var rms: float = sqrt(e / float(_out.size()))
	if rms < 0.012:
		_hang = maxi(_hang - 1, 0)
		if _hang == 0:
			_out.clear()
			return
	else:
		_hang = 3
	var bytes := PackedByteArray()
	bytes.resize(_out.size())
	for i in _out.size():
		bytes[i] = _enc(_out[i] * 2.0)     # küçük bir kazanç
	_out.clear()
	net.to_server("srv_voice", [bytes])


static func _enc(s: float) -> int:
	var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
	var sign: int = 0x80 if v < 0 else 0
	v = mini(absi(v), 32635) + 0x84
	var ex: int = 7
	var mask: int = 0x4000
	while ex > 0 and (v & mask) == 0:
		ex -= 1
		mask >>= 1
	var man: int = (v >> (ex + 3)) & 0x0F
	return (~(sign | (ex << 4) | man)) & 0xFF


static func _dec(b: int) -> float:
	b = (~b) & 0xFF
	var sign: int = b & 0x80
	var ex: int = (b >> 4) & 7
	var man: int = b & 0x0F
	var v: int = (((man << 3) + 0x84) << ex) - 0x84
	return float(-v if sign != 0 else v) / 32768.0


# ---- oynatma
func _on_audio(cid: int, data: PackedByteArray) -> void:
	if not in_voice():
		return
	var sp: Dictionary = _sp.get(cid, {})
	if sp.is_empty():
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = RATE
		gen.buffer_length = 0.6
		var pl := AudioStreamPlayer.new()
		pl.stream = gen
		add_child(pl)
		pl.play()
		sp = {"player": pl, "pb": pl.get_stream_playback()}
		_sp[cid] = sp
	var pb: AudioStreamGeneratorPlayback = sp.pb
	var frames := PackedVector2Array()
	frames.resize(data.size())
	for i in data.size():
		var v: float = _dec(data[i])
		frames[i] = Vector2(v, v)
	if pb.get_frames_available() >= frames.size():
		pb.push_buffer(frames)
	_talk[cid] = Time.get_ticks_msec()


func _drop_speaker(cid: int) -> void:
	var sp: Dictionary = _sp.get(cid, {})
	if not sp.is_empty() and is_instance_valid(sp.player):
		sp.player.queue_free()
	_sp.erase(cid)
	_talk.erase(cid)


func speaking(cid: int) -> bool:
	return Time.get_ticks_msec() - int(_talk.get(cid, -100000)) < 700


# ---- arayüz
func open() -> void:
	var g = gs_getter.call()
	if g == null or net == null:
		return
	_sheet = Sheet.open(ui.root, "Sesli görüşme", 720, true, true, "Online")
	var body: VBoxContainer = _sheet.body
	_rebuild = func():
		for c in body.get_children():
			c.queue_free()
		var gg = gs_getter.call()
		if gg == null:
			return
		var me: int = net.my_cid
		if in_voice():
			body.add_child(TK.t("Görüşme odasındakiler", "kicker"))
			for cid in net.voice_members:
				var ci: int = int(cid)
				if ci < 0 or ci >= gg.countries.size():
					continue
				var nm: String = gg.countries[ci].name + ("  (sen)" if ci == me else "")
				if speaking(ci) or (ci == me and _running and not muted and _hang > 0):
					nm += "  🔊"
				body.add_child(TK.t(nm, "body", TK.TEXT))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var mb := TK.button("Mikrofonu aç" if muted else "Sessize al", "gold" if not muted else "", "", Vector2(0, 60), 18)
			mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mb.pressed.connect(func():
				ui._click()
				set_muted(not muted)
				_rebuild.call())
			row.add_child(mb)
			var lb := TK.button("Görüşmeden ayrıl", "danger", "", Vector2(0, 60), 18)
			lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lb.pressed.connect(func():
				ui._click()
				leave())
			row.add_child(lb)
			body.add_child(row)
		else:
			body.add_child(TK.t("Bir oyuncuyu sesli görüşmeye çağır; kabul ederse aynı odada konuşursunuz.", "small", TK.FAINT))
		body.add_child(TK.spacer(0, 6))
		body.add_child(TK.t("Oyuncular", "kicker"))
		var shown := 0
		for cid in gg.net_humans:
			var ci2: int = int(cid)
			if ci2 == me or ci2 < 0 or ci2 >= gg.countries.size() or not gg.countries[ci2].alive:
				continue
			shown += 1
			var r2 := HBoxContainer.new()
			r2.add_theme_constant_override("separation", 8)
			var fl := TK.flag_rect(gg.countries[ci2], Vector2(44, 30))
			r2.add_child(fl)
			var l := TK.t(gg.countries[ci2].name, "body", TK.TEXT)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r2.add_child(l)
			if net.voice_members.has(ci2):
				r2.add_child(TK.t("görüşmede", "small", TK.GREEN))
			else:
				var ib := TK.button("Görüşmeye çağır", "", "", Vector2(220, 56), 16)
				ib.pressed.connect(func():
					ui._click()
					invite(ci2)
					ui.toast(Loc.t("Davet gönderildi.")))
				r2.add_child(ib)
			body.add_child(r2)
		if shown == 0:
			body.add_child(TK.t("Odada çağırılabilecek başka oyuncu yok.", "small", TK.FAINT))
	_rebuild.call()
