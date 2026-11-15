extends Control
const Loc = preload("res://scripts/loc.gd")
## BM oylama animasyonu (piksel sanat, kodla çizilir): hemicycle koltuklar sırayla yanar, ardından önergenin simgesi belirir.
## Kabul: yeşil parıltı + kıvılcımlar; ret: kırmızı ışık, simge solar ve çarpı belirir.

const PAL := {
	"k": Color("1a1f2b"), "w": Color("f4f4f0"), "b": Color("4f8fe0"), "g": Color("3fb56a"), "r": Color("d9483f"),
	"y": Color("f0c040"), "o": Color("f08a30"), "s": Color("98a2b3"), "n": Color("8a5a2e"),
}
const SPRITES := {
	"ceasefire": ["............", "..kkkkkkk...", "..kwwwwwwk..", "..kwwwwwwwk.", "..kwwwwwwk..", "..kwwwwwk...", "..kkkkkk....", "..k.........", "..k.........", "..k.........", "..k.........", ".kkk........"],
	"rebuild": ["............", ".....rr.....", "....rrrr....", "...rrrrrr...", "..rrrrrrrr..", ".rrrrrrrrrr.", "..yyyyyyyy..", "..yyynnyyy..", "..yyynnyyy..", "..yyynnyyy..", "..kkkkkkkk..", "............"],
	"aid": ["............", ".nnnnnnnnnn.", ".nyyyyyyyyn.", ".nyyyrryyyn.", ".nyyyrryyyn.", ".nyrrrrrryn.", ".nyrrrrrryn.", ".nyyyrryyyn.", ".nyyyrryyyn.", ".nyyyyyyyyn.", ".nnnnnnnnnn.", "............"],
	"peace_keep": ["............", "............", "....bbbb....", "...bbbbbb...", "..bbbbbbbb..", ".bbbbwwbbbb.", ".bbbbwwbbbb.", ".bbbbbbbbbb.", "kkkkkkkkkkkk", "............", "............", "............"],
	"develop": ["............", "..........g.", ".........gg.", "......g..gg.", ".....gg..gg.", ".....gg..gg.", "..g..gg..gg.", ".gg..gg..gg.", ".gg..gg..gg.", ".gg..gg..gg.", "kkkkkkkkkkkk", "............"],
	"guarantee": [".kkkkkkkkkk.", ".kbbbbbbbbk.", ".kbbwwwwbbk.", ".kbbbwwbbbk.", ".kbbbwwbbbk.", ".kbbbwwbbbk.", "..kbbwwbbk..", "..kbbbbbbk..", "...kbbbbk...", "....kbbk....", ".....kk.....", "............"],
	"sanction": ["....ssss....", "...s....s...", "...s....s...", "...s....s...", "..yyyyyyyy..", "..yyyyyyyy..", "..yyykkyyy..", "..yyykkyyy..", "..yyyykyyy..", "..yyyyyyyy..", "..kkkkkkkk..", "............"],
	"embargo": ["............", ".nnnnnnnnnn.", ".nyyyyyyyyn.", ".nyryyyyryn.", ".nyyryyryyn.", ".nyyyrryyyn.", ".nyyyrryyyn.", ".nyyryyryyn.", ".nyryyyyryn.", ".nnnnnnnnnn.", "............", "............"],
	"probe": ["...ssss.....", "..s....s....", ".s.wwww.s...", ".s.wwww.s...", ".s.wwww.s...", "..s....s....", "...ssss.n...", "........nn..", ".........nn.", "..........nn", "..........nn", "............"],
	"disarm": ["..........ss", ".........sss", "........sss.", ".......ss...", "............", "............", "...ss.......", "..sss.y.....", "..ss.yy.....", ".yyyyy......", "..nny.......", ".nn........."],
	"attack": ["..y....y....", "...y..y..y..", "y...oooo....", "..ooyyyyoo.y", "..oyyrryyo..", ".ooyrrrryoo.", "..oyyrryyoo.", "..ooyyyyoo..", "y..oooooo..y", "...y..y..y..", "..y....y....", "............"],
}
const SEAT_N := 48
const SEAT_T0 := 0.35
const SEAT_DT := 0.04

var kind := "ceasefire"
var yes := 0
var no := 0
var abstain := 0
var passed := false
var my_vote := -2          # -2: oy vermedi, -1 çekimser, 0 aleyhte, 1 lehte
var _t := 0.0
var _seat_pos: Array = []  # [Vector2, sonuç] sırayla yanar (soldan sağa)
var _mine := -1            # oyuncunun koltuğu (dizin)
var _end_t := 0.0
var _font: Font


## res: UN.propose / UN.player_vote sonucu.
static func make(res: Dictionary, h: float = 200.0) -> Control:
	var a = load("res://scripts/un_art.gd").new()
	a.kind = String(res.get("kind", "ceasefire"))
	a.yes = int(res.get("yes", 0))
	a.no = int(res.get("no", 0))
	a.abstain = int(res.get("abstain", 0))
	a.passed = bool(res.get("passed", false))
	a.my_vote = int(res.get("pv", -2))
	a.custom_minimum_size = Vector2(0, h)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_build_seats()
	_end_t = SEAT_T0 + SEAT_N * SEAT_DT + 0.25
	set_process(true)


func _build_seats() -> void:
	var tot: int = maxi(yes + no + abstain, 1)
	var ny: int = roundi(SEAT_N * float(yes) / tot)
	var na: int = roundi(SEAT_N * float(abstain) / tot)
	var nn: int = maxi(0, SEAT_N - ny - na)
	var results: Array = []
	for i in ny:
		results.append(1)
	for i in nn:
		results.append(0)
	for i in na:
		results.append(-1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d%d" % [kind, yes, no])
	for i in range(results.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = results[i]
		results[i] = results[j]
		results[j] = tmp
	# halka düzeni: açı (π → 0) sırasına göre sıralı koltuklar
	var raw: Array = []
	var rings := [[12, 0], [16, 1], [20, 2]]
	for rg in rings:
		var cnt: int = rg[0]
		for k in cnt:
			raw.append([PI - PI * (float(k) + 0.5) / float(cnt), rg[1]])
	raw.sort_custom(func(a, b): return a[0] > b[0])
	_seat_pos.clear()
	_mine = -1
	for i in raw.size():
		var res: int = results[i] if i < results.size() else 0
		_seat_pos.append([raw[i][0], raw[i][1], res])
		if _mine < 0 and my_vote >= -1 and res == my_vote:
			_mine = i


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > _end_t + 3.2:
		set_process(false)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), c)


func _draw() -> void:
	var W: float = size.x
	var H: float = size.y
	_r(0, 0, W, H, Color("0c1a2e"))
	_r(0, H - 26, W, 26, Color("14263f"))
	_r(0, H - 28, W, 2, Color("2a4468"))
	# arka duvar: mavi şerit ve beyaz yıldızlar (BM bayrağı esintisi)
	_r(0, 0, W, 4, Color("4f8fe0"))
	for i in 9:
		_r(W * (0.06 + 0.11 * i), 14 + (i % 3) * 6, 4, 4, Color(1, 1, 1, 0.18))
	var cx: float = W * 0.36
	var cy: float = H - 38.0
	var radii := [52.0, 80.0, 108.0]
	var lit_frac: float = clampf((_t - SEAT_T0) / (SEAT_N * SEAT_DT), 0.0, 1.0)
	# kürsü
	_r(cx - 14, cy - 10, 28, 20, Color("2f5d9e"))
	_r(cx - 14, cy - 10, 28, 3, Color("6aa5ee"))
	for i in _seat_pos.size():
		var sp: Array = _seat_pos[i]
		var r: float = radii[int(sp[1])]
		var x: float = cx + cos(sp[0]) * r * 1.0 - 5.0
		var y: float = cy - sin(sp[0]) * r * 0.9 - 5.0
		var lit_at: float = SEAT_T0 + i * SEAT_DT
		var base := Color("24354f")
		var col: Color = base
		if _t >= lit_at:
			var res: int = sp[2]
			col = Color("3fb56a") if res == 1 else (Color("d9483f") if res == 0 else Color("8a94a6"))
			var pop: float = clampf((_t - lit_at) / 0.12, 0.0, 1.0)
			if pop < 1.0:
				col = base.lerp(Color.WHITE, 1.0 - pop).lerp(col, pop)
		_r(x, y, 10, 10, col)
		_r(x, y, 10, 2, col.lightened(0.25))
		_r(x, y + 8, 10, 2, col.darkened(0.3))
		if i == _mine and _t >= lit_at:
			var gold := Color("f0c040")
			_r(x - 2, y - 2, 14, 2, gold)
			_r(x - 2, y + 10, 14, 2, gold)
			_r(x - 2, y, 2, 10, gold)
			_r(x + 10, y, 2, 10, gold)
	# sayaç
	var sy: int = roundi(yes * lit_frac)
	var sn: int = roundi(no * lit_frac)
	draw_string(_font, Vector2(14, 34), "%s %d" % [Loc.t("LEHTE"), sy], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("5fd08a"))
	draw_string(_font, Vector2(14, 58), "%s %d" % [Loc.t("ALEYHTE"), sn], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f0706a"))
	if abstain > 0:
		draw_string(_font, Vector2(14, 80), "%s %d" % [Loc.t("ÇEKİMSER"), roundi(abstain * lit_frac)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a8b2c4"))
	# sonuç sahnesi: önergenin simgesi
	if _t < _end_t:
		return
	var tt: float = _t - _end_t
	var sx: float = W * 0.77
	var sc: float = 1.0
	if tt < 0.35:
		var q: float = tt / 0.35
		sc = 1.0 + 2.2 * pow(q - 1.0, 3) + 1.2 * pow(q - 1.0, 2)   # kısa taşma ile oturur
		sc = clampf(sc, 0.0, 1.25)
	var u: float = 9.0 * sc
	var bob: float = sin(tt * 4.0) * 3.0 if passed else 0.0
	var shake: float = 0.0 if passed else sin(tt * 60.0) * 5.0 * exp(-tt * 5.0)
	var ox: float = sx - 6.0 * u + shake
	var oy: float = H * 0.46 - 6.0 * u + bob
	var spr: Array = SPRITES.get(kind, SPRITES["ceasefire"])
	for ry in spr.size():
		var row: String = spr[ry]
		for rx in row.length():
			var ch: String = row[rx]
			if ch == ".":
				continue
			var c: Color = PAL[ch]
			if not passed:
				var gray: float = c.get_luminance()
				c = c.lerp(Color(gray, gray, gray), 0.8).darkened(0.15)
			_r(ox + rx * u, oy + ry * u, u, u, c)
	if passed:
		for i in 10:
			var ph: float = fmod(tt * 0.7 + i * 0.1, 1.0)
			var ang: float = i * 0.628 + 0.4
			var rr: float = 70.0 + ph * 50.0
			var a: float = 1.0 - ph
			_r(sx + cos(ang) * rr - 2, H * 0.46 + sin(ang) * rr * 0.8 - 2, 5, 5, Color(0.96, 0.82, 0.25, a))
		_r(0, 0, W, H, Color(0.25, 0.8, 0.45, 0.28 * exp(-tt * 3.5)))
	else:
		var xc := Color(0.85, 0.28, 0.25, clampf(tt * 4.0, 0.0, 1.0))
		var half: float = 6.0 * u
		for k in 26:
			var f: float = float(k) / 25.0
			_r(sx - half + f * 2.0 * half - 4, H * 0.46 - half + f * 2.0 * half - 4, 9, 9, xc)
			_r(sx + half - f * 2.0 * half - 4, H * 0.46 - half + f * 2.0 * half - 4, 9, 9, xc)
		_r(0, 0, W, H, Color(0.85, 0.2, 0.2, 0.25 * exp(-tt * 3.5)))
