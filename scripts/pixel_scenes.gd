extends RefCounted
## Kodla çizilen piksel-art sahne afişleri (dosya yok). Her "piksel" ekranda ps x ps birimlik kare; tüm hareket 8 kare/sn ile
## kuantize edilir. kinds: assault barrage blitz naval air missile paradrop special landing cyber spy sanction trade alliance war peace

const PAL := {
	"k": Color("1a1c2c"), "d": Color("333c57"), "s": Color("566c86"), "l": Color("94b0c2"), "w": Color("f4f4f4"),
	"r": Color("b13e53"), "o": Color("ef7d57"), "y": Color("ffcd75"), "g": Color("38b764"), "G": Color("a7f070"),
	"h": Color("3d6b2f"), "H": Color("5f8f36"), "b": Color("3b5dc9"), "c": Color("41a6f6"), "C": Color("73eff7"),
	"n": Color("29366f"), "p": Color("5d275d"), "t": Color("257179"), "e": Color("e0b47c"), "m": Color("8f563b"),
}

const TANK := [
	"........hhhhh.......",
	".......hHHHHHhkkkkkk",
	".......hHHHHHh......",
	"...hhhhhhhhhhhhhhh..",
	"..hHHHHHHHHHHHHHHh..",
	".kkkkkkkkkkkkkkkkkk.",
	"kdsdsdsdsdsdsdsdsdk.",
	".kkkkkkkkkkkkkkkkkk.",
]
const SOLDIER_A := [".kk.", ".ee.", "hhhh", "hhkk", ".hh.", ".h.h", "k..k"]
const SOLDIER_B := [".kk.", ".ee.", "hhhh", "hhkk", ".hh.", "..hh", "..kk"]
const HOWITZER := [
	"..............kk",
	"............kkk.",
	".........kkkk...",
	"......kkkk......",
	"...hhhhhhh......",
	"..hHHHHHHHh.....",
	".hhhhhhhhhhh....",
	"kkdkkkkkdkkkk...",
	".kkkkkkkkkkk....",
]
const DOVE_UP := [
	"..w.....",
	".www..ww",
	"wwwwwwww",
	".kwwwww.",
	"..wwww..",
]
const DOVE_DN := [
	"........",
	"..www.w.",
	"kwwwwwww",
	".wwwwww.",
	"wwwwww..",
]
const HORSEMAN := [
	"..........ww..",
	".........wwww.",
	".........eeee.",
	"........rrrr..",
	"..mmmmmmrrmmm.",
	".mmmmmmmmmmmmm",
	".mmmmmmmmmmmmm",
	".mm.mm...mm.mm",
	".mm.mm...mm.mm",
	".kk.kk...kk.kk",
]
const JET := [
	"......k.",
	"....kkkk",
	"kkkkkkkk",
	"....kkkk",
	"......k.",
]
const MUSKETEER := [".ww.", ".ww.", ".ee.", "rrrr", "rrkk", ".rr.", ".r.r", "k..k"]
const MUSKETEER_B := [".ww.", ".ww.", ".ee.", "rrrr", "rrkk", ".rr.", "..rr", "..kk"]
const PIKEMAN := ["..k.", ".ss.", ".ee.", "bbbb", "bbkk", ".bb.", ".b.b", "k..k"]
const BIPLANE := [
	"..kkkkkkkk..",
	"kk....k.....",
	"..kkkkkkkkk.",
	"....k.k..kkk",
	"...kkkkk....",
]
const CAMEL := [
	"......mm....",
	".....mmm....",
	"..mmmmmm....",
	".mmmmmmmmm..",
	".mm.mm.mm.m.",
	".mm.mm.mm.m.",
	".kk.kk.kk.k.",
]
const SULTAN := [
	"..wwww..",
	".wwwwww.",
	".weeeew.",
	"..eeee..",
	".rrrrrr.",
	"rryyyyrr",
	"rryyyyrr",
	"rrrrrrrr",
	"rrrrrrrr",
	".rr..rr.",
	".rr..rr.",
	".kk..kk.",
]
const MAN := [
	"..kkkk..",
	".kkkkkk.",
	".keeeek.",
	"..eeee..",
	".dddddd.",
	"dwwrrwwd",
	"dwwrrwwd",
	"dddddddd",
	"dddddddd",
	".dd..dd.",
	".dd..dd.",
	".kk..kk.",
]
const HAT_MAN := [
	"..kkkk..",
	".kkkkkk.",
	"kkkkkkkk",
	"..eeee..",
	"..eeee..",
	".dddddd.",
	"dddddddd",
	"dddddddd",
	"dddddddd",
	".dd..dd.",
	".dd..dd.",
	".kk..kk.",
]

var c: Control
var ps := 2
var pw := 100
var ph := 60
var gy := 40
var t := 0.0
var fr := 0


func draw(ctrl: Control, kind: String, time: float) -> void:
	c = ctrl
	t = time
	ps = 2
	pw = ceili(c.size.x / ps)
	ph = ceili(c.size.y / ps)
	gy = int(ph * 0.66)
	fr = int(time * 8.0)
	match kind:
		"barrage": _barrage()
		"blitz": _blitz()
		"naval": _naval()
		"air": _air()
		"missile": _missile()
		"paradrop": _paradrop()
		"special": _special()
		"landing": _landing()
		"cyber": _cyber()
		"spy": _spy()
		"sanction": _sanction()
		"trade": _trade()
		"alliance": _alliance()
		"war": _war()
		"peace": _peace()
		"era_ott1520": _horde(false)
		"era_tim1380": _horde(true)
		"era_ww1": _trench()
		"un_hall": _hall()
		"mobilize": _mobilize()
		"border": _border()
		"crisis": _crisis()
		"carrier": _carrier()
		"pre_assault": _pre_assault()
		"pre_barrage": _pre_barrage()
		"pre_naval": _pre_naval()
		"pre_landing": _pre_landing()
		"pre_spy": _pre_spy()
		"pre_trade": _pre_trade()
		"pre_alliance": _pre_alliance()
		"pre_war": _pre_war()
		"pre_peace": _pre_peace()
		"pre_sanction": _pre_sanction()
		"pre_special": _pre_special()
		"pre_mobilize": _pre_mobilize()
		"pre_border": _pre_border()
		"pre_court": _pre_court()
		"pre_oath": _pre_oath()
		"pre_fief": _pre_fief()
		"pre_rebel": _pre_rebel()
		"pre_camp": _pre_camp()
		"pre_siege": _pre_siege()
		"pre_tribute": _pre_tribute()
		"ww1_assault": _trench()
		"ww1_air": _ww1_air()
		_: _assault()


# ------------------------------------------------------------ yardımcılar

func R(x, y, w, h, k) -> void:
	var cc: Color = PAL[k] if k is String else k
	c.draw_rect(Rect2(floori(x) * ps, floori(y) * ps, maxi(1, floori(w)) * ps, maxi(1, floori(h)) * ps), cc)


func A(k: String, a: float) -> Color:
	var x: Color = PAL[k]
	x.a = a
	return x


func spr(rows: Array, x: float, y: float, flip := false, pal: Dictionary = PAL, sc: int = 1) -> void:
	var xi := floori(x)
	var yi := floori(y)
	for j in rows.size():
		var row: String = rows[j]
		var n: int = row.length()
		var i := 0
		while i < n:
			var ch: String = row[(n - 1 - i) if flip else i]
			if ch == ".":
				i += 1
				continue
			var k := i
			while k + 1 < n and row[(n - 1 - (k + 1)) if flip else (k + 1)] == ch:
				k += 1
			R(xi + i * sc, yi + j * sc, (k - i + 1) * sc, sc, pal[ch])
			i = k + 1


func sky(stops: Array, to_y: int = -1) -> void:
	var h: int = gy if to_y < 0 else to_y
	var y := 0
	while y < h:
		var f: float = float(y) / maxf(1.0, h - 1.0)
		var seg: float = f * (stops.size() - 1)
		var i: int = mini(int(seg), stops.size() - 2)
		var a: Color = PAL[stops[i]] if stops[i] is String else stops[i]
		var b: Color = PAL[stops[i + 1]] if stops[i + 1] is String else stops[i + 1]
		R(0, y, pw, 3, a.lerp(b, seg - i))
		y += 3


func hills(base: int, k, amp: float, freq: float, sd: float, scroll: float = 0.0) -> void:
	var x := 0
	while x < pw:
		var xs: float = x + scroll
		var h: int = int(amp * (0.55 + 0.35 * sin(xs * freq + sd) + 0.2 * sin(xs * freq * 2.7 + sd * 1.7)))
		R(x, base - h, 2, ph - (base - h), k)
		x += 2


func circ(cx: float, cy: float, r: int, k) -> void:
	for dy in range(-r, r + 1):
		var w: int = int(sqrt(maxf(0.0, r * r - dy * dy)))
		R(cx - w, cy + dy, 2 * w + 1, 1, k)


func cloud(x: float, y: float, k) -> void:
	R(x + 2, y - 1, 6, 1, k)
	R(x, y, 12, 1, k)
	R(x + 3, y + 1, 7, 1, k)


func stars(n: int, ymax: int, sd: float = 3.0) -> void:
	for i in n:
		var x: int = int(fposmod(sin(i * 12.9898 + sd) * 43758.5, 1.0) * pw)
		var y: int = int(fposmod(sin(i * 78.233 + sd) * 24634.6, 1.0) * ymax)
		if (fr + i) % 7 != 0:
			R(x, y, 1, 1, A("w", 0.8))


func wrapx(speed: float, offset: float, span: float, margin: float = 30.0) -> float:
	return fposmod(t * speed + offset, span + margin) - margin


func boom(x: float, y: float, age: float) -> void:
	if age < 0.0 or age > 1.0:
		return
	var r: int = int(2 + age * 8)
	var k: String = "w" if age < 0.15 else ("y" if age < 0.35 else ("o" if age < 0.6 else ("r" if age < 0.8 else "s")))
	circ(x, y, r, k)
	if age < 0.6:
		circ(x, y, maxi(1, r - 3), "y" if age > 0.15 else "w")


func muzzle(x: float, y: float) -> void:
	R(x, y - 1, 3, 3, "w")
	R(x + 3, y, 3, 1, "y")
	R(x - 2, y, 2, 1, "y")
	R(x + 1, y - 3, 1, 2, "o")
	R(x + 1, y + 2, 1, 2, "o")


func smoke(x: float, base: float, n: int = 6, k: String = "d", rise: float = 20.0) -> void:
	for i in n:
		var f: float = fposmod(t * 0.22 + i * 0.17, 1.0)
		R(x + sin(f * 6.0 + i) * 3.0, base - f * rise, 2 + int(f * 4), 2 + int(f * 3), A(k, (1.0 - f) * 0.7))


func dust_trail(x: float, y: float, n: int = 4) -> void:
	for i in n:
		var f: float = fposmod(t * 1.4 + i * 0.25, 1.0)
		R(x - f * 12, y - f * 3, 2 + f * 3, 2, A("e", (1.0 - f) * 0.7))


func ground(k, y: int = -1) -> void:
	var yy: int = gy if y < 0 else y
	R(0, yy, pw, ph - yy, k)


func ship(x: float, y: float, k: String = "s", flip := false, big := true) -> void:
	var L: int = 38 if big else 24
	var d: float = -1.0 if flip else 1.0
	var o: float = x if not flip else x - L
	R(o, y, L, 3, k)
	R(o + 2, y + 3, L - 6, 2, "d")
	R(o + (6 if not flip else 4), y - 3, 10, 3, k)
	R(o + (9 if not flip else 7), y - 7, 4, 4, k)
	R(o + (10 if not flip else 8), y - 10, 1, 3, "k")
	R(o + (16 if not flip else 14), y - 2, 6, 2, "d")
	for i in 2:
		var tx: float = o + (4 + i * 22 if not flip else L - 8 - i * 22)
		R(tx, y - 2, 4, 2, "d")
		R(tx + (3 if not flip else -5), y - 2, 5, 1, "k")


func waves(y0: int, k1, k2, speed: float = 3.0) -> void:
	ground(k1, y0)
	for row in range(y0 + 2, ph, 4):
		var off: float = t * speed * (1.0 + (row - y0) * 0.05)
		var x := -int(fposmod(off, 12.0))
		while x < pw:
			R(x, row, 6, 1, k2)
			x += 12


# ------------------------------------------------------------ sahneler

func _assault() -> void:
	sky(["p", "r", "o", "y"])
	circ(pw * 0.78, gy - 1, 7, "y")
	hills(gy + 2, "p", 7, 0.06, 1.0)
	smoke(pw * 0.2, gy, 6, "d", 22)
	smoke(pw * 0.62, gy, 5, "d", 18)
	ground("h")
	for row in range(gy + 3, ph, 4):
		var x := -int(fposmod(t * 9.0, 8.0))
		while x < pw:
			R(x, row, 4, 1, "H")
			x += 8
	for i in 4:
		var x: float = wrapx(5.0, i * pw / 4.0, pw)
		var y: float = gy + 2 + (i % 2) * 7
		dust_trail(x, y + 7)
		spr(TANK, x, y)
		if (fr + i * 4) % 12 == 0:
			muzzle(x + 20, y + 1)
	for i in 9:
		var sx: float = wrapx(7.0 + (i % 2), i * pw / 9.0 + 10, pw)
		spr(SOLDIER_A if (fr + i) % 2 == 0 else SOLDIER_B, sx, gy + 15 + (i % 3) * 3, false, PAL, 1)


func _barrage() -> void:
	sky(["n", "p", "r", "o"])
	stars(10, int(gy * 0.4))
	hills(gy + 2, "n", 8, 0.05, 2.0)
	ground("d")
	for i in 3:
		var hx: float = pw * 0.06 + i * 34
		var hy: float = gy + 2 + (i % 2) * 8
		spr(HOWITZER, hx, hy, false, PAL, 2)
		if (fr + i * 5) % 16 < 2:
			muzzle(hx + 30, hy - 2)
	for i in 4:
		var ph_: float = fposmod(t * 0.5 + i * 0.25, 1.0)
		var sx: float = pw * 0.22 + ph_ * pw * 0.6
		var sy: float = gy - sin(ph_ * PI) * ph * 0.5 + 2
		R(sx, sy, 2, 2, "y")
		R(sx - 4, sy + 1, 3, 1, A("o", 0.6))
		if ph_ > 0.9:
			boom(sx, gy + 4, (ph_ - 0.9) * 10.0)
	for i in 3:
		R(pw * 0.8 + i * 9, gy + 1, 3, 2, "r" if (fr + i) % 3 else "y")
	smoke(pw * 0.86, gy + 1, 6, "d", 20)


func _blitz() -> void:
	sky(["d", "s", "l"])
	if (fr % 40) < 2:
		R(0, 0, pw, gy, A("w", 0.35))
		R(pw * 0.55, 0, 1, 12, "w")
		R(pw * 0.55 - 2, 11, 3, 1, "w")
	cloud(wrapx(2.0, 10, pw), 6, "s")
	cloud(wrapx(1.4, pw * 0.5, pw), 12, "s")
	hills(gy + 1, "s", 6, 0.04, 0.5, t * 6)
	ground("h")
	R(0, gy + 8, pw, 14, "d")
	for x in range(-int(fposmod(t * 40, 16)), pw, 16):
		R(x, gy + 14, 8, 1, "y")
	for i in 3:
		var x: float = wrapx(30.0, i * 40.0, pw)
		dust_trail(x, gy + 15, 5)
		spr(TANK, x, gy + 7)
		for s in 3:
			R(x - 18 - s * 8, gy + 9 + s * 2, 10, 1, A("w", 0.5))
	for i in 5:
		R(wrapx(80.0, i * 51.0, pw), gy + 4 + (i * 5) % 18, 16, 1, A("w", 0.35))


func _naval() -> void:
	sky(["k", "n", "t"], int(ph * 0.55))
	stars(14, int(ph * 0.4))
	circ(pw * 0.8, int(ph * 0.2), 4, "l")
	waves(int(ph * 0.55), "n", "t", 3.0)
	var by: int = int(ph * 0.55) + 4
	ship(pw * 0.12, by + 4, "s", false)
	ship(pw * 0.5, by + 12, "s", false)
	for i in 2:
		var sx: float = pw * (0.12 + i * 0.38) + 38
		if (fr + i * 6) % 20 < 3:
			muzzle(sx, by + 2 + i * 8)
			R(0, 0, pw, ph, A("o", 0.12))
		var p_: float = fposmod(t * 0.45 + i * 0.5, 1.0)
		var x: float = sx + 6 + p_ * pw * 0.35
		var y: float = by - sin(p_ * PI) * ph * 0.4
		R(x, y, 2, 2, "y")
		if p_ > 0.9:
			var a: float = (p_ - 0.9) * 10.0
			R(x - 2, by + 6 - a * 6, 1, int(a * 6) + 1, A("w", 1.0 - a))
			R(x + 2, by + 6 - a * 4, 1, int(a * 4) + 1, A("w", 1.0 - a))


func _air() -> void:
	sky(["n", "p", "o"], gy)
	stars(8, int(gy * 0.5))
	hills(gy + 1, "n", 6, 0.05, 4.0)
	waves(gy + 2, "n", "t", 2.0)
	ground("d", gy + 12)
	for i in 2:
		var bx: float = pw * (0.3 + i * 0.4)
		var sw: float = sin(t * 0.7 + i * 2.0) * 14
		for s in 3:
			R(bx + (gy - s * 8) * 0.0 + (s * 2) * (sw / 14.0), gy - s * 8, 2, 8, A("y", 0.18))
	for i in 3:
		var x: float = wrapx(14.0, i * pw / 3.0, pw)
		var y: float = 8 + i * 7
		R(x, y, 18, 3, "l")
		R(x + 14, y - 3, 3, 3, "l")
		R(x + 4, y + 3, 10, 1, "s")
		R(x + 6, y - 1, 6, 1, "s")
		R(x + 18, y, 2, 2, "C")
		if (fr + i * 3) % 12 < 2:
			R(x + 20, y, 2, 3, A("w", 0.5))
		var bf: float = fposmod(t * 0.6 + i * 0.33, 1.0)
		R(x + 8, y + 4 + bf * (gy - y), 2, 3, "k")
		if bf > 0.95:
			boom(x + 8, gy + 2, (bf - 0.95) * 20.0)
	for i in 5:
		var fx: float = fposmod(i * 0.21 + floor(t * 1.2 + i) * 0.13, 1.0) * pw
		R(fx, 10 + (i * 11) % 24, 3, 3, A("w", 0.6))
		R(fx + 1, 12 + (i * 11) % 24, 2, 2, A("s", 0.6))


func _missile() -> void:
	sky(["n", "p", "r", "o"])
	stars(8, int(gy * 0.4))
	hills(gy + 2, "n", 7, 0.05, 1.0)
	ground("d")
	var lx: float = pw * 0.14
	R(lx, gy + 8, 34, 5, "s")
	R(lx + 24, gy + 3, 10, 6, "d")
	R(lx + 26, gy + 4, 4, 3, "C")
	R(lx, gy + 13, 34, 2, "k")
	for w in 4:
		R(lx + 3 + w * 8, gy + 12, 4, 4, "k")
	for r in 4:
		R(lx + 2 + r, gy + 4 - r, 18, 2, "h")
	if (fr % 24) < 3:
		muzzle(lx + 22, gy)
	var rx: float = pw * 0.8
	R(rx, gy - 6, 1, 14, "l")
	R(rx - 4, gy - 9 + (fr % 4 - 2) % 2, 9, 2, "l")
	R(rx - 3, gy - 7, 7, 1, "s")
	for i in 3:
		var p_: float = fposmod(t * 0.3 + i * 0.33, 1.0)
		var x: float = pw * 0.2 + p_ * pw * 0.3 + i * 6
		var y: float = gy - p_ * (gy + 10)
		for s in 10:
			R(x - s * 0.7 + 6, y + s * 2.2 + 3, 2, 2, A("y" if s < 3 else ("o" if s < 6 else "w"), 0.9 - s * 0.08))
		R(x + 5, y, 3, 7, "w")
		R(x + 5, y - 2, 3, 2, "r")
		R(x + 4, y + 5, 5, 2, "s")


func _paradrop() -> void:
	sky(["c", "C", "y", "o"])
	cloud(wrapx(2.0, 20, pw), 14, "w")
	cloud(wrapx(1.5, pw * 0.6, pw), 24, "w")
	hills(gy + 2, "g", 6, 0.05, 2.0)
	ground("H")
	for row in range(gy + 3, ph, 4):
		for x in range(0, pw, 10):
			R(x + (row % 8), row, 6, 1, "h")
	var px: float = wrapx(10.0, 0.0, pw, 40)
	R(px, 4, 22, 3, "s")
	R(px + 16, 1, 4, 3, "s")
	R(px + 22, 4, 2, 2, "C")
	for i in 6:
		var f: float = fposmod(t * 0.12 + i * 0.17, 1.0)
		var x: float = px + 8 + i * 4 + sin(t * 1.3 + i) * 3 + f * 20
		var y: float = 7 + f * (gy - 4)
		R(x - 3, y, 8, 1, "w")
		R(x - 4, y + 1, 10, 1, "w")
		R(x - 3, y + 2, 8, 1, "r")
		R(x - 3, y + 3, 1, 3, "w")
		R(x + 4, y + 3, 1, 3, "w")
		R(x, y + 6, 2, 2, "k")
		R(x, y + 8, 2, 3, "h")


func _special() -> void:
	sky(["k", "n", "t"], gy)
	stars(10, int(gy * 0.5))
	ground("k")
	R(0, gy - 16, pw, 20, "d")
	for x in range(0, pw, 8):
		R(x, gy - 18, 4, 2, "d")
	for x in range(6, pw, 24):
		R(x, gy - 10, 4, 4, A("y", 0.8 if (fr / 6 + x) % 5 else 0.1))
	var sw: float = fposmod(t * 0.18, 1.0)
	var sx: float = sw * pw
	for s in 14:
		R(sx - s * 2 + 10, gy - 18 + s * 2, 3 + s * 2, 2, A("C", 0.16 - s * 0.008))
	for i in 3:
		var x: float = wrapx(6.0, i * 20.0 + pw * 0.2, pw * 0.7)
		spr(SOLDIER_A if (fr + i) % 2 == 0 else SOLDIER_B, x, gy + 2, false, {"k": PAL.k, "e": PAL.G, "h": PAL.d, ".": PAL.k}, 2)
	for i in 5:
		R(fposmod(i * 0.23 + t * 0.02 * (1 + i % 2), 1.0) * pw, gy + 6 + (i * 3) % 12, 30, 2, A("l", 0.12))


func _landing() -> void:
	sky(["p", "r", "o", "y"], int(ph * 0.42))
	circ(pw * 0.7, int(ph * 0.42) - 1, 6, "y")
	ship(pw * 0.1, int(ph * 0.42) - 4, "s", false, false)
	ship(pw * 0.3, int(ph * 0.42) - 2, "s", false, false)
	waves(int(ph * 0.42), "t", "C", 2.0)
	ground("e", int(ph * 0.76))
	R(0, int(ph * 0.76), pw, 2, "w")
	for i in 3:
		var x: float = pw * 0.18 + i * pw * 0.22 + sin(t * 1.5 + i) * 2
		var y: int = int(ph * 0.62)
		R(x, y, 18, 4, "d")
		R(x - 2, y + 1, 2, 3, "d")
		R(x + 16, y - 2, 2, 2, "s")
		for s in 3:
			R(x + 3 + s * 4, y - 3, 2, 3, "h")
			R(x + 3 + s * 4, y - 4, 2, 1, "k")
		R(x + 18, y + 3, 6, 1, A("w", 0.6))
		var sxs: float = x + 22 + fposmod(t * 3 + i, 12.0)
		spr(SOLDIER_A if (fr + i) % 2 == 0 else SOLDIER_B, sxs, int(ph * 0.74) - 2)
	boom(pw * 0.86, int(ph * 0.72), fposmod(t * 0.4, 1.0))
	smoke(pw * 0.88, int(ph * 0.72), 5, "d", 18)


func _cyber() -> void:
	R(0, 0, pw, ph, "k")
	for x in range(0, pw, 6):
		var f: float = fposmod(t * (0.3 + (x % 5) * 0.08) + x * 0.37, 1.0)
		var y: float = f * (ph + 10) - 10
		for s in 5:
			R(x, y - s * 2, 2, 2, A("G" if s == 0 else "g", 1.0 - s * 0.2))
	var cx: float = pw * 0.5
	for i in 16:
		var gx: float = pw * 0.2 + fposmod(i * 7.3, 1.0) * pw * 0.6
		var gyy: float = ph * 0.2 + fposmod(i * 3.7, 1.0) * ph * 0.6
		R(gx, gyy, 2, 2, A("C", 0.8))
		R(gx, gyy, 12, 1, A("t", 0.9))
	R(cx - 24, ph * 0.46, 48, 1, A("t", 0.6))
	R(cx - 1, 4, 3, ph - 8, A("t", 0.0))
	if (fr / 3) % 2 == 0:
		var rx: float = pw * 0.76
		R(rx, ph * 0.22, 1, 1, "r")
		for r in 7:
			R(rx - r, ph * 0.22 + r, 2 * r + 1, 1, "r")
		R(rx, ph * 0.22 + 3, 1, 3, "k")
	circ(cx, ph * 0.5, 9, "k")
	circ(cx, ph * 0.5, 8, "t")
	R(cx - 4, ph * 0.5 - 1, 9, 7, "y")
	R(cx - 3, ph * 0.5 - 5, 7, 5, "y")
	R(cx - 1, ph * 0.5 - 4, 3, 5, "k")
	R(cx - 1, ph * 0.5 + 2, 3, 2, "k")


func _spy() -> void:
	sky(["k", "n", "d"], gy)
	for i in 6:
		R(pw * 0.1 + i * pw * 0.16, gy - 26 - (i * 7) % 12, 14, 30 + (i * 7) % 12, "d")
		for w in 3:
			if (i + w) % 2 == 0:
				R(pw * 0.1 + i * pw * 0.16 + 3 + w * 4, gy - 22 - (i * 7) % 12 + w * 5, 2, 2, "y")
	ground("k")
	R(0, gy + 8, pw, 2, "d")
	var lx: float = pw * 0.62
	R(lx, gy - 22, 2, 30, "s")
	R(lx - 3, gy - 24, 8, 3, "s")
	for s in 12:
		R(lx - 6 - s, gy - 20 + s * 2, 12 + s * 2, 2, A("y", 0.22 - s * 0.015))
	spr(HAT_MAN, lx - 22, gy - 6)
	spr(HAT_MAN, lx + 8, gy - 6, true)
	R(lx - 12 + (fr % 6) / 3, gy + 1, 5, 3, "w")
	for i in 40:
		var f: float = fposmod(i * 0.137 + t * 1.6, 1.0)
		R(fposmod(i * 0.317, 1.0) * pw, f * ph, 1, 3, A("l", 0.45))


func _sanction() -> void:
	sky(["n", "p", "o"], gy)
	hills(gy + 1, "n", 5, 0.05, 2.0)
	waves(gy + 1, "n", "t", 2.0)
	ground("d", gy + 12)
	R(0, gy + 12, pw, 2, "s")
	ship(pw * 0.12 + sin(t) * 1.0, gy - 3, "r", false)
	for i in 3:
		R(pw * 0.55 + i * 10, gy + 6, 9, 6, "m")
		R(pw * 0.55 + i * 10, gy + 8, 9, 1, "e")
	R(pw * 0.55 + 6, gy, 9, 6, "m")
	var gx: float = pw * 0.42
	R(gx, gy - 8, 2, 20, "w")
	R(gx + 26, gy - 8, 2, 20, "w")
	for s in 4:
		R(gx + s * 7, gy - 4 + (s % 2) * 6, 7, 3, "r" if s % 2 == 0 else "w")
	R(gx - 1, gy - 10, 4, 3, "r" if (fr / 4) % 2 == 0 else "y")
	R(gx + 25, gy - 10, 4, 3, "y" if (fr / 4) % 2 == 0 else "r")
	for i in 7:
		R(gx - 22 + i * 3, gy + 8 + (i % 2), 2, 2, "s")


func _trade() -> void:
	sky(["c", "y", "o"], gy)
	circ(pw * 0.8, gy - 2, 6, "y")
	waves(gy + 1, "t", "C", 2.0)
	ground("d", gy + 6)
	R(0, gy + 6, pw, 2, "s")
	var cols := ["r", "b", "y", "g", "o", "c"]
	for i in 12:
		var cx: float = pw * 0.04 + (i % 4) * 12
		var cy: float = gy + 12 - (i / 4) * 5
		R(cx, cy, 11, 5, cols[(i * 2) % 6])
		R(cx, cy, 11, 1, A("w", 0.3))
	var kx: float = pw * 0.45
	R(kx, gy - 18, 2, 26, "o")
	R(kx + 8, gy - 18, 2, 26, "o")
	R(kx - 8, gy - 20, 32, 3, "o")
	var sw: float = sin(t * 0.8) * 6
	R(kx + 14 + sw, gy - 17, 1, 10, "k")
	R(kx + 10 + sw, gy - 7, 9, 5, cols[(fr / 16) % 6])
	ship(pw * 0.62 + sin(t * 0.5) * 2, gy - 4, "s", false)
	for i in 3:
		var gxp: float = fposmod(t * 6.0 + i * 40, pw + 20) - 10
		var gyp: float = 6 + i * 6 + sin(t * 2 + i) * 2
		R(gxp, gyp, 3, 1, "w")
		R(gxp + 3, gyp + (fr + i) % 2, 3, 1, "w")


func _alliance() -> void:
	sky(["o", "y", "e"], gy)
	circ(pw * 0.5, gy - 8, 10, A("y", 0.5))
	hills(gy + 2, "H", 7, 0.05, 3.0)
	ground("h")
	var fc := ["b", "g", "y", "r", "b", "g", "y", "r", "b", "g"]
	var n: int = mini(10, int(pw / 22.0))
	for i in n:
		var fx: float = pw * 0.06 + i * (pw * 0.88 / maxf(1.0, n - 1))
		R(fx, gy - 16, 1, 22, "k")
		for s in 8:
			R(fx + 1 + s, gy - 16 + int(sin(t * 3 + s * 0.6 + i) * 1.4) + s / 3, 1, 6, fc[i % 10])
	var mx: float = pw * 0.5
	var bob: int = 1 if fr % 8 < 2 else 0
	spr(MAN, mx - 26, gy - 12, false, PAL, 2)
	spr(MAN, mx + 10, gy - 12, true, PAL, 2)
	R(mx - 10, gy + 2 + bob, 20, 4, "e")
	R(mx - 10, gy + 2 + bob, 20, 1, "w")
	R(mx - 2, gy + 1 + bob, 4, 6, "e")


func _war() -> void:
	sky(["k", "p", "r", "o"], gy)
	stars(6, int(gy * 0.3))
	for i in 9:
		var bx: float = pw * 0.02 + i * (pw / 9.0)
		var bh: int = 14 + (i * 7) % 16
		R(bx, gy - bh, 12, bh + 4, "k")
		for w in 4:
			if (i * 3 + w + fr / 9) % 3 != 0:
				R(bx + 2 + (w % 2) * 5, gy - bh + 3 + (w / 2) * 5, 3, 3, "o" if w % 2 == 0 else "y")
		var f: float = fposmod(t * 6 + i * 3, 4.0)
		R(bx + 3, gy - bh - 3 - int(f), 3, 3, "o")
		R(bx + 4, gy - bh - 5 - int(f), 2, 3, "y")
	smoke(pw * 0.25, gy - 12, 7, "d", 26)
	smoke(pw * 0.6, gy - 16, 7, "d", 28)
	ground("k")
	R(0, gy, pw, 2, "r")
	for i in 2:
		spr(TANK, wrapx(4.0, i * pw * 0.5, pw), gy + 4 + i * 4, false, {"h": PAL.k, "H": PAL.d, "k": PAL.k, "d": PAL.d, "s": PAL.s, ".": PAL.k})
	for i in 3:
		R(pw * 0.15 + i * pw * 0.3 + sin(t * 2 + i), 4, 1, gy - 10, A("y", 0.14))


func _peace() -> void:
	sky(["c", "C", "y", "o"])
	for s in 12:
		var a: float = s * 0.26 + t * 0.05
		for r in range(8, int(ph * 0.9), 3):
			R(pw * 0.5 + cos(a) * r * 1.6, gy - 2 - sin(a) * r * 0.5, 2, 1, A("y", 0.10))
	circ(pw * 0.5, gy - 2, 8, "y")
	cloud(wrapx(2.0, 10, pw), 10, "w")
	cloud(wrapx(1.2, pw * 0.5, pw), 18, "w")
	hills(gy + 2, "g", 8, 0.045, 1.0)
	ground("H", gy + 3)
	for i in 5:
		var hx: float = pw * 0.14 + i * pw * 0.17
		R(hx, gy - 4 + (i % 2), 11, 8, "e")
		R(hx - 1, gy - 6 + (i % 2), 13, 2, "r")
		R(hx + 4, gy - 1 + (i % 2), 3, 5, "m")
		R(hx + 1, gy - 2 + (i % 2), 2, 2, "C")
	var dx: float = pw * 0.5 + sin(t * 0.6) * 18
	var dy: float = 8 + sin(t * 1.2) * 3
	spr(DOVE_UP if (fr / 2) % 2 == 0 else DOVE_DN, dx, dy, false, PAL, 2)
	R(dx - 10, dy + 7, 10, 2, "g")
	R(dx - 10, dy + 5, 3, 2, "G")
	R(dx - 5, dy + 9, 3, 2, "G")


# ------------------------------------------------------------ yeni kipler: dönem, BM, seferberlik, sınır, kriz

func _horse(x: float, y: float, flag: String) -> void:
	var yo: int = 1 if (fr / 2) % 2 == 0 else 0
	spr(HORSEMAN, x, y - yo)
	R(x + 12, y - 8 - yo, 1, 9, "k")                       # mızrak
	var wv: int = int(sin(t * 6.0 + x) * 1.5)
	R(x + 13, y - 8 - yo, 6, 3, flag)                      # sancak
	R(x + 17 + wv, y - 7 - yo, 2, 2, flag)


## Osmanlı (timur=false: sıcak gün batımı, kubbe/minare, kızıl sancak) ve Timur (true: soğuk şafak, karlı dağ, çadır, mavi sancak)
func _horde(timur: bool) -> void:
	if timur:
		sky(["n", "t", "c", "y"])
		stars(14, int(gy * 0.5), 5.0)
		hills(gy - 4, "l", 16, 0.035, 2.0)
		hills(gy, "s", 11, 0.05, 4.0)
		ground("H")
		for i in 3:
			var yx: float = pw * (0.16 + i * 0.3)
			R(yx, gy - 5, 12, 5, "w")                      # yurt gövdesi
			R(yx + 2, gy - 8, 8, 3, "w")
			R(yx + 4, gy - 10, 4, 2, "e")
			R(yx + 5, gy - 2, 2, 2, "k")
			smoke(yx + 5, gy - 10, 3, "l", 12)
	else:
		sky(["p", "r", "o", "y"])
		circ(pw * 0.72, gy - 6, 8, "y")
		hills(gy, "p", 6, 0.07, 1.0)
		ground("e")
		for i in 4:                                         # kubbe + minare silüeti
			var bx: float = pw * (0.08 + i * 0.26)
			circ(bx, gy - 7, 7, "k")
			R(bx - 7, gy - 7, 15, 8, "k")
			R(bx + 9, gy - 20, 2, 21, "k")
			R(bx + 9, gy - 23, 2, 3, "r")
			R(bx + 8, gy - 12, 4, 1, "k")
	for i in 5:
		var hx: float = wrapx(11.0 + (i % 2) * 2.0, i * pw / 5.0, pw, 40.0)
		var hy: float = gy + 4 + (i % 3) * 6
		dust_trail(hx, hy + 9, 3)
		_horse(hx, hy, "b" if timur else "r")
	for i in 6:
		var f: float = fposmod(t * 0.3 + i * 0.17, 1.0)
		R(fposmod(i * 41.0 + t * 4.0, pw), gy + 2 + f * (ph - gy - 4), 2, 1, A("e", 0.5))


func _trench() -> void:
	sky(["d", "s", "l"])
	hills(gy - 2, "d", 5, 0.08, 3.0)
	ground("m")
	for i in 5:                                            # şarapnel çukurları
		R(pw * (0.07 + i * 0.2), gy + 3 + (i % 2) * 2, 10, 2, "k")
	for x in range(0, pw, 9):                              # dikenli tel
		R(x, gy - 4, 1, 6, "k")
		R(x, gy - 3, 9, 1, "d")
	R(0, gy + 11, pw, 9, "k")                              # siper hendeği
	for x in range(0, pw, 6):
		R(x, gy + 8, 4, 3, "m")                            # kum torbaları
	for i in 6:
		var sx: float = 8 + i * (pw / 6.0)
		if (fr / 3 + i) % 6 != 0:
			spr(SOLDIER_A if i % 2 == 0 else SOLDIER_B, sx, gy + 4, false, PAL, 2)
	for i in 3:
		var age: float = fposmod(t * 0.45 + i * 0.33, 1.0)
		boom(pw * (0.2 + i * 0.3), gy - 6, age * 1.4)
	for i in 4:
		var lx: float = fposmod(t * 40.0 + i * 37.0, pw)
		R(lx, gy + 9, 2, 1, "y")                           # tüfek izi


func _hall() -> void:
	R(0, 0, pw, ph, "n")
	for y in range(0, ph, 3):
		R(0, y, pw, 3, PAL.n.lerp(PAL.k, float(y) / ph))
	var cx: int = pw / 2
	circ(cx, int(ph * 0.28), 11, "b")                      # arma yerine soyut küre
	circ(cx, int(ph * 0.28), 9, "c")
	for k in range(-8, 9, 4):
		R(cx - 9, int(ph * 0.28) + k, 19, 1, "b")
	R(cx, int(ph * 0.28) - 9, 1, 19, "b")
	for i in 3:
		R(cx - 14 - i * 4, int(ph * 0.28) + 12 + i * 2, 29 + i * 8, 1, A("C", 0.25 - i * 0.07))
	for row in 4:                                          # koltuk yarım daireleri
		var n: int = 14 + row * 6
		for i in n:
			var a: float = PI * (0.08 + 0.84 * float(i) / (n - 1))
			var rx: float = cx - cos(a) * (pw * (0.22 + row * 0.085))
			var ry: float = ph * 0.97 - sin(a) * (ph * (0.22 + row * 0.1))
			var on: bool = fposmod(sin(i * 3.7 + row * 5.1) * 91.7, 1.0) < 0.55
			R(rx, ry, 3, 2, "y" if (on and (fr / 4 + i + row) % 9 != 0) else "s")
	R(cx - 6, int(ph * 0.58), 12, 4, "m")                  # kürsü
	R(cx - 5, int(ph * 0.58) - 1, 10, 1, "y")


func _mobilize() -> void:
	sky(["d", "r", "o", "y"])
	circ(pw * 0.8, gy - 4, 6, "y")
	hills(gy + 1, "d", 6, 0.06, 2.0)
	for i in 5:                                            # şehir silüeti
		var bx: float = 4 + i * 11
		R(bx, gy - 6 - (i % 3) * 4, 9, 12 + (i % 3) * 4, "k")
		if (fr / 6 + i) % 3 == 0:
			R(bx + 2, gy - 3, 2, 2, "y")
	ground("d")
	R(0, gy + 8, pw, 8, "m")                               # yol
	for i in 9:
		var sx: float = wrapx(9.0, i * 22.0, pw, 20.0)
		spr(SOLDIER_A if (fr + i) % 2 == 0 else SOLDIER_B, sx, gy + 4 + (i % 2) * 8, false, PAL, 2)
	var wv: int = int(sin(t * 5.0) * 1.5)                  # kızıl bayrak
	R(pw * 0.5, gy - 14, 1, 24, "k")
	R(pw * 0.5 + 1, gy - 14, 12 + wv, 7, "r")
	R(pw * 0.5 + 5, gy - 12, 3, 3, "y")
	dust_trail(pw * 0.7, gy + 18, 4)


func _border() -> void:
	sky(["n", "s", "l", "y"])
	hills(gy, "s", 8, 0.05, 6.0)
	ground("H")
	R(0, gy + 6, pw, 3, "m")                               # sınır yolu
	var cx: int = pw / 2
	for k in 8:                                            # çizgili bariyer
		R(cx - 22 + k * 6, gy + 3 + (1 if (fr / 8) % 2 == 0 and k == 7 else 0), 3, 2, "r" if k % 2 == 0 else "w")
	R(cx - 24, gy - 2, 2, 12, "k")
	R(cx + 24, gy - 2, 2, 12, "k")
	for side in 2:                                         # iki gözetleme kulesi
		var tx: float = 10 + side * (pw - 30)
		R(tx, gy - 14, 12, 4, "d")
		R(tx + 1, gy - 10, 2, 16, "k")
		R(tx + 9, gy - 10, 2, 16, "k")
		var lit: bool = (fr / 5 + side) % 2 == 0
		R(tx + 3, gy - 13, 6, 2, "y" if lit else "o")
		if lit:
			R(tx + (11 if side == 0 else -12), gy - 12, 12, 1, A("y", 0.4))
	for i in 4:
		spr(SOLDIER_A, cx - 46 + i * 9, gy + 9 + (i % 2) * 4, false, PAL, 2)
		spr(SOLDIER_B, cx + 22 + i * 9, gy + 9 + (i % 2) * 4, true, PAL, 2)
	for x in range(0, pw, 5):
		R(x, gy + 11, 1, 3, "k")
	R(0, gy + 12, pw, 1, "d")


func _crisis() -> void:
	sky(["k", "p", "r"])
	stars(8, int(gy * 0.4), 9.0)
	circ(pw * 0.3, int(gy * 0.35), 5, A("o", 0.45))
	for i in 8:
		var bx: float = i * (pw / 8.0)
		var bh: int = 14 + int(fposmod(sin(i * 5.3) * 33.1, 1.0) * 22)
		R(bx, gy - bh, pw / 8 - 1, bh + 8, "k")
		for wy in range(gy - bh + 3, gy, 5):
			if fposmod(sin(i * 7.0 + wy) * 55.5, 1.0) < 0.35 and (fr / 6 + wy) % 4 != 0:
				R(bx + 3, wy, 2, 2, "y")
	ground("k")
	R(0, gy - 3, pw, 4, A("r", 0.45 + 0.15 * sin(t * 3.0)))
	for i in [1, 3, 5, 7]:                                 # yanan çatılar (bina yüksekliğiyle aynı formül)
		var bh: int = 14 + int(fposmod(sin(i * 5.3) * 33.1, 1.0) * 22)
		var fx: float = i * (pw / 8.0) + 4
		var fh: int = 3 + int(fposmod(t * 5.0 + i, 3.0))
		R(fx, gy - bh - fh, 4, fh, "o")
		R(fx + 1, gy - bh - fh - 2, 2, 3, "y")
		smoke(fx + 2, gy - bh - 2, 5, "s", 40)
	for i in 14:                                           # kül/kıvılcım
		var f: float = fposmod(t * 0.25 + i * 0.13, 1.0)
		R(fposmod(i * 23.0 + sin(t + i) * 4.0, pw), f * ph, 1, 1, A("o", 1.0 - f))
	if sin(t * 1.7) > 0.93:
		R(0, 0, pw, ph, A("w", 0.12))


## Uçak gemisi saldırısı: alacakaranlık deniz, güvertede kalkış, kıyıya dalış ve patlamalar, uçaksavar
func _carrier() -> void:
	sky(["n", "p", "o", "y"])
	stars(8, int(gy * 0.3), 7.0)
	circ(pw * 0.5, gy - 2, 6, "o")
	waves(gy + 2, "b", "c", 2.0)
	# sağda kıyı şeridi + şehir silüeti
	var cx0: int = int(pw * 0.64)
	var x := cx0
	while x < pw:
		var hgt: int = int(6 + 5 * (0.5 + 0.5 * sin((x - cx0) * 0.09 + 1.0)) + minf(8.0, (x - cx0) * 0.35))
		R(x, gy + 2 - hgt, 2, hgt + 6, "d")
		x += 2
	for i in 5:
		var bx: float = cx0 + 6 + i * 7
		R(bx, gy - 12 - (i % 3) * 3, 4, 10 + (i % 3) * 3, "k")
	# gemi: sol (2x ölçek)
	var sx: float = pw * 0.05 + sin(t * 0.4)
	var sy: float = gy + 1 + int(sin(t * 0.8))
	R(sx, sy, 44, 6, "s")                                          # gövde
	R(sx + 2, sy + 6, 40, 2, "d")
	R(sx - 3, sy - 4, 50, 4, "l")                                  # uçuş güvertesi
	R(sx - 1, sy - 3, 46, 1, "d")
	for i in 7:
		R(sx + 1 + i * 7, sy - 3, 3, 1, "y")                       # güverte çizgileri
	R(sx + 32, sy - 12, 7, 8, "s")                                 # ada (köprü)
	R(sx + 34, sy - 16, 2, 4, "k")
	R(sx + 33, sy - 10, 5, 1, "C")
	R(sx + 35, sy - 18 - int((fr / 2) % 2), 1, 2, "r")
	spr(JET, sx + 6, sy - 9, false, PAL, 1)                        # güvertede bekleyen jet
	# kalkış: güverteden fırlayıp sağa tırmanan, kıyıya dalan jetler
	for i in 3:
		var f: float = fposmod(t * 0.3 + i * 0.33, 1.0)
		var jx: float = sx + 10 + f * (pw * 0.95)
		var climb: float = sin(minf(f * 1.8, 1.0) * PI * 0.5) * (gy * 0.7)
		var dive: float = ((f - 0.62) * gy * 1.6) if f > 0.62 else 0.0
		var jy: float = sy - 6 - climb + dive
		spr(JET, jx, jy, false, PAL, 2)
		if f < 0.1:
			R(jx - 5, jy + 4, 5, 2, A("y", 0.9))                   # katapult alevi
		elif f > 0.55 and f < 0.9:
			R(jx + 6, jy + 10, 2, 3, "y")                          # bomba
	# kıyıda patlamalar
	for i in 3:
		var age: float = fposmod(t * 0.5 + i * 0.37, 1.3)
		boom(cx0 + 8 + i * 12, gy - 8 - (i % 2) * 4, age)
	smoke(cx0 + 14, gy - 10, 6, "d", 30)
	# uçaksavar (flak) bulutları ve izleri
	for i in 5:
		var fa: float = fposmod(t * 0.9 + i * 0.21, 1.0)
		if fa < 0.5:
			circ(pw * (0.5 + fposmod(i * 0.37, 0.45)), gy * (0.2 + fposmod(i * 0.29, 0.45)), 1 + int(fa * 5), A("l", 0.6 - fa))
	for i in 3:
		var tr_: float = fposmod(t * 1.5 + i * 0.33, 1.0)
		R(cx0 + 10 + i * 10, gy - 6 - tr_ * (gy - 8), 1, 2, "y")


# ============================================================ çağ sahneleri: Osmanlı / Timur ("pre" ailesi)

func domes(x: float, base: float, n: int = 3, k: String = "k") -> void:
	for i in n:
		var bx: float = x + i * 26
		circ(bx, base - 7, 7, k)
		R(bx - 7, base - 7, 15, 8, k)
		R(bx + 9, base - 20, 2, 21, k)
		R(bx + 9, base - 23, 2, 3, "r")


func castle(x: float, base: float, w: int = 40, k: String = "s", broken: bool = false) -> void:
	R(x, base - 14, w, 14, k)
	for i in range(0, w, 6):
		R(x + i, base - 17, 3, 3, k)
	R(x - 4, base - 24, 8, 24, k)
	R(x + w - 4, base - 24, 8, 24, k)
	R(x - 4, base - 27, 3, 3, k)
	R(x + 1, base - 27, 3, 3, k)
	R(x + w - 4, base - 27, 3, 3, k)
	R(x + w + 1, base - 27, 3, 3, k)
	R(x + w / 2 - 3, base - 8, 6, 8, "k")                 # kapı
	if broken:
		R(x + w * 0.55, base - 14, 9, 9, "d")
		for j in 5:
			R(x + w * 0.5 + j * 3, base - 2 - (j % 2) * 2, 3, 2, "s")


func horse_line(n: int, speed: float, y0: float, flag: String, scale2 := true) -> void:
	for i in n:
		var hx: float = wrapx(speed + (i % 2) * 2.0, i * pw / float(n), pw, 40.0)
		var hy: float = y0 + (i % 3) * 5
		dust_trail(hx, hy + 9, 3)
		_horse(hx, hy, flag)


func _pre_assault() -> void:
	sky(["p", "r", "o", "y"])
	circ(pw * 0.8, gy - 4, 7, "y")
	hills(gy, "p", 7, 0.06, 1.0)
	castle(pw * 0.62, gy + 1, 40, "d")
	ground("e")
	for row in range(gy + 3, ph, 4):
		var x := -int(fposmod(t * 6.0, 8.0))
		while x < pw:
			R(x, row, 4, 1, A("m", 0.35))
			x += 8
	horse_line(5, 11.0, gy + 2, "r")
	for i in 8:
		var sx: float = wrapx(6.0 + (i % 2), i * pw / 8.0 + 6, pw)
		spr(MUSKETEER if (fr + i) % 2 == 0 else MUSKETEER_B, sx, gy + 16 + (i % 3) * 3)
		if (fr + i * 3) % 14 == 0:
			R(sx + 4, gy + 18 + (i % 3) * 3, 3, 1, "y")
			smoke(sx + 6, gy + 17, 2, "l", 8)


func _pre_barrage() -> void:
	sky(["n", "p", "r", "o"])
	stars(8, int(gy * 0.4))
	hills(gy + 2, "n", 8, 0.05, 2.0)
	castle(pw * 0.66, gy + 2, 36, "s", true)
	ground("d")
	for i in 3:
		var bx: float = pw * 0.05 + i * 30
		var by: float = gy + 4 + (i % 2) * 7
		R(bx, by + 4, 16, 3, "m")                          # kızak
		R(bx + 2, by + 1, 14, 3, "e")                      # namlu
		R(bx + 13, by, 4, 5, "e")
		R(bx + 1, by + 7, 3, 3, "k")
		R(bx + 12, by + 7, 3, 3, "k")
		if (fr + i * 5) % 18 < 2:
			muzzle(bx + 18, by + 2)
			smoke(bx + 18, by, 4, "l", 14)
	for i in 3:
		var ph_: float = fposmod(t * 0.4 + i * 0.33, 1.0)
		var sx: float = pw * 0.2 + ph_ * pw * 0.5
		var sy: float = gy + 4 - sin(ph_ * PI) * ph * 0.45
		R(sx, sy, 3, 3, "k")
		if ph_ > 0.94:
			boom(pw * 0.7, gy - 8, (ph_ - 0.94) * 12.0)


func galley(x: float, y: float, k: String = "m", flip := false) -> void:
	var L := 34
	var o: float = x
	R(o, y, L, 3, k)
	R(o + 2, y + 3, L - 4, 1, "k")
	for i in range(2, L - 2, 4):                           # kürekler
		var dip: int = 1 if (fr / 2 + i) % 4 < 2 else 0
		R(o + i, y + 3 + dip, 1, 3, "e")
	R(o + L * 0.45, y - 16, 1, 16, "k")                    # direk
	var sw: int = int(sin(t * 2.0 + x) * 1.0)
	for j in 10:                                          # üçgen yelken
		R(o + L * 0.45 + 1, y - 16 + j, 1 + j + sw, 1, "w")
	R(o + (L - 2 if not flip else -2), y - 4, 2, 4, "r")   # sancak


func _pre_naval() -> void:
	sky(["k", "n", "t"], int(ph * 0.55))
	stars(12, int(ph * 0.4))
	circ(pw * 0.78, int(ph * 0.18), 4, "l")
	waves(int(ph * 0.55), "n", "t", 2.5)
	var by: int = int(ph * 0.55) + 2
	galley(pw * 0.08 + sin(t * 0.5), by + 2, "m")
	galley(pw * 0.56 + sin(t * 0.6 + 1), by + 10, "d")
	for i in 2:
		var sx: float = pw * (0.08 + i * 0.48) + 30
		if (fr + i * 7) % 22 < 3:
			muzzle(sx, by + 2 + i * 8)
		var p_: float = fposmod(t * 0.45 + i * 0.5, 1.0)
		var x: float = sx + 4 + p_ * pw * 0.3
		var y: float = by - sin(p_ * PI) * ph * 0.3
		R(x, y, 2, 2, "y")                                  # ateşli ok
		R(x - 2, y + 1, 2, 1, A("o", 0.7))
		if p_ > 0.92:
			R(x, by + 4, 3, 2, A("o", 0.8))


func _pre_landing() -> void:
	sky(["p", "r", "o", "y"], int(ph * 0.42))
	circ(pw * 0.7, int(ph * 0.42) - 1, 6, "y")
	galley(pw * 0.06, int(ph * 0.42) - 2, "m")
	galley(pw * 0.34, int(ph * 0.42) + 1, "m")
	waves(int(ph * 0.42), "t", "C", 2.0)
	ground("e", int(ph * 0.76))
	R(0, int(ph * 0.76), pw, 2, "w")
	for i in 10:
		var sx: float = pw * 0.2 + i * 7 + sin(t * 1.5 + i) * 2
		spr(MUSKETEER if (fr + i) % 2 == 0 else MUSKETEER_B, sx, int(ph * 0.76) - 6 + (i % 2) * 3)
	castle(pw * 0.75, int(ph * 0.76) + 1, 30, "d")


func _pre_spy() -> void:
	sky(["k", "n", "d"], gy)
	stars(10, int(gy * 0.5))
	domes(pw * 0.15, gy - 6, 3, "d")
	ground("k")
	R(0, gy + 8, pw, 2, "d")
	var lx: float = pw * 0.62
	R(lx, gy - 18, 2, 26, "m")                             # fener direği
	R(lx - 2, gy - 20, 6, 3, "y")
	for s in 10:
		R(lx - 5 - s, gy - 17 + s * 2, 10 + s * 2, 2, A("y", 0.2 - s * 0.015))
	spr(HAT_MAN, lx - 22, gy - 6, false, {"k": PAL.k, "e": PAL.e, "d": PAL.d, "w": PAL.w, "r": PAL.r})
	spr(SULTAN, lx + 8, gy - 6, true, {"w": PAL.w, "e": PAL.e, "r": PAL.d, "y": PAL.y, "k": PAL.k})
	R(lx - 12 + (fr % 6) / 3, gy + 1, 5, 3, "y")             # mühürlü mektup
	for i in 14:
		var f: float = fposmod(i * 0.137 + t * 0.4, 1.0)
		R(fposmod(i * 0.317, 1.0) * pw, f * ph, 1, 1, A("l", 0.3))


func _pre_trade() -> void:
	sky(["o", "y", "e"], gy)
	circ(pw * 0.2, gy - 10, 9, A("y", 0.6))
	hills(gy + 2, "e", 8, 0.04, 2.0)
	domes(pw * 0.6, gy - 2, 2, "d")
	ground("e", gy + 4)
	R(0, gy + 10, pw, 3, "m")
	for i in 4:
		var cx: float = wrapx(3.0, i * 30.0, pw, 30.0)
		spr(CAMEL, cx, gy + 2 + (i % 2))
		R(cx + 3, gy + 1, 5, 3, "r")                        # yük
		R(cx + 9, gy, 2, 3, "b")
	for i in 6:
		var f: float = fposmod(t * 0.25 + i * 0.17, 1.0)
		R(fposmod(i * 37.0 + t * 3.0, pw), gy + 6 + f * 8, 2, 1, A("y", 0.4))


func _pre_alliance() -> void:
	sky(["o", "y", "e"], gy)
	circ(pw * 0.5, gy - 8, 10, A("y", 0.5))
	hills(gy + 2, "H", 7, 0.05, 3.0)
	ground("h")
	R(pw * 0.5 - 30, gy - 14, 60, 18, "w")                 # otağ
	R(pw * 0.5 - 24, gy - 20, 48, 6, "w")
	R(pw * 0.5 - 1, gy - 26, 2, 6, "y")
	R(pw * 0.5 - 6, gy - 2, 12, 6, "k")
	var fc := ["r", "g", "y", "b", "r", "g"]
	for i in 6:
		var fx: float = pw * (0.08 + i * 0.17)
		R(fx, gy - 16, 1, 22, "k")
		for s in 6:
			R(fx + 1 + s, gy - 16 + int(sin(t * 3 + s * 0.6 + i) * 1.4), 1, 5, fc[i])
	var bob: int = 1 if fr % 8 < 2 else 0
	spr(SULTAN, pw * 0.5 - 26, gy - 12, false, PAL, 2)
	spr(SULTAN, pw * 0.5 + 10, gy - 12, true, {"w": PAL.l, "e": PAL.e, "r": PAL.b, "y": PAL.y, "k": PAL.k}, 2)
	R(pw * 0.5 - 2, gy + 1 + bob, 4, 6, "e")


func _pre_war() -> void:
	sky(["k", "p", "r"])
	stars(6, int(gy * 0.4), 9.0)
	castle(pw * 0.3, gy, 44, "k", true)
	domes(pw * 0.62, gy, 2, "k")
	ground("k")
	R(0, gy - 3, pw, 4, A("r", 0.45 + 0.15 * sin(t * 3.0)))
	for i in 4:
		var fx: float = pw * (0.3 + i * 0.12)
		var fh: int = 3 + int(fposmod(t * 5.0 + i, 3.0))
		R(fx, gy - 16 - fh, 4, fh, "o")
		R(fx + 1, gy - 18 - fh, 2, 3, "y")
		smoke(fx + 2, gy - 18, 5, "s", 40)
	horse_line(3, 8.0, gy + 4, "r")
	if sin(t * 1.7) > 0.93:
		R(0, 0, pw, ph, A("w", 0.12))


func _pre_peace() -> void:
	sky(["c", "C", "y", "o"])
	circ(pw * 0.5, gy - 2, 8, "y")
	cloud(wrapx(2.0, 10, pw), 10, "w")
	hills(gy + 2, "g", 8, 0.045, 1.0)
	ground("H", gy + 3)
	domes(pw * 0.12, gy, 2, "e")
	R(pw * 0.68, gy - 5, 12, 5, "w")                      # yurt
	R(pw * 0.68 + 2, gy - 8, 8, 3, "w")
	var dx: float = pw * 0.5 + sin(t * 0.6) * 18
	var dy: float = 8 + sin(t * 1.2) * 3
	spr(DOVE_UP if (fr / 2) % 2 == 0 else DOVE_DN, dx, dy, false, PAL, 2)


func _pre_sanction() -> void:
	sky(["d", "s", "l"], gy)
	hills(gy + 1, "s", 6, 0.05, 2.0)
	ground("e")
	R(0, gy + 8, pw, 3, "m")
	R(pw * 0.5 - 2, gy - 10, 4, 20, "k")                   # kapalı kapı/sur kapısı
	R(pw * 0.5 - 14, gy - 18, 28, 8, "s")
	R(pw * 0.5 - 16, gy - 10, 4, 20, "s")
	R(pw * 0.5 + 12, gy - 10, 4, 20, "s")
	R(pw * 0.5 - 12, gy - 10, 24, 18, "k")
	for i in 3:
		R(pw * 0.5 - 12 + i * 8, gy - 6 + (fr / 6 % 2), 2, 10, "r")   # zincir
	for i in 3:
		var cx: float = pw * 0.1 + i * 16 + sin(t * 0.8 + i)
		spr(CAMEL, cx, gy + 2)
	spr(MUSKETEER, pw * 0.5 + 18, gy + 2)


func _pre_special() -> void:
	sky(["k", "n", "d"], gy)
	stars(12, int(gy * 0.5), 4.0)
	castle(pw * 0.55, gy + 2, 40, "d")
	ground("k")
	for i in 3:                                            # merdivenler
		var lx: float = pw * 0.56 + i * 12
		R(lx, gy - 20, 1, 22, "e")
		R(lx + 4, gy - 20, 1, 22, "e")
		for j in range(0, 22, 4):
			R(lx, gy - 20 + j, 5, 1, "e")
		var cy: float = gy - fposmod(t * 6.0 + i * 7.0, 22.0)
		R(lx + 1, cy, 3, 4, "r")
	for i in 3:
		var tx: float = pw * 0.1 + i * 14
		spr(MUSKETEER_B, tx, gy + 4)
		R(tx + 2, gy - 1, 1, 4, "m")
		R(tx + 1, gy - 3 - (fr % 2), 3, 2, "o")             # meşale
		R(tx + 2, gy - 5 - (fr % 2), 1, 2, "y")


func _pre_mobilize() -> void:
	sky(["d", "r", "o", "y"])
	circ(pw * 0.8, gy - 4, 6, "y")
	hills(gy + 1, "d", 6, 0.06, 2.0)
	domes(pw * 0.05, gy - 2, 2, "k")
	ground("d")
	R(0, gy + 8, pw, 8, "m")
	for i in 9:
		var sx: float = wrapx(9.0, i * 22.0, pw, 20.0)
		spr(MUSKETEER if (fr + i) % 2 == 0 else MUSKETEER_B, sx, gy + 4 + (i % 2) * 8, false, PAL, 2)
	R(pw * 0.5, gy - 16, 1, 26, "k")                       # tuğ
	circ(pw * 0.5, gy - 18, 2, "y")
	for j in 6:
		R(pw * 0.5 - 2 + (j % 3) + int(sin(t * 5 + j) * 1.5), gy - 15 + j, 1, 3, "k")
	R(pw * 0.5 + 2, gy - 12, 10 + int(sin(t * 5.0) * 1.5), 6, "r")


func _pre_border() -> void:
	sky(["n", "s", "l", "y"])
	hills(gy, "s", 8, 0.05, 6.0)
	ground("H")
	R(0, gy + 6, pw, 3, "m")
	var cx: int = pw / 2
	for k in 6:
		R(cx - 1, gy - 20 + k * 2, 3, 1, "k" if k % 2 == 0 else "w")   # sınır taşı/direği
	R(cx - 3, gy - 8, 7, 14, "s")
	for side in 2:
		var tx: float = 8 + side * (pw - 26)
		R(tx, gy - 16, 12, 6, "d")
		R(tx + 2, gy - 10, 8, 16, "s")
		R(tx + 4, gy - 14, 4, 2, "y" if (fr / 5 + side) % 2 == 0 else "o")
	for i in 3:
		_horse(cx - 46 + i * 12, gy + 6 + (i % 2) * 3, "r")
	for i in 3:
		spr(PIKEMAN, cx + 22 + i * 9, gy + 9 + (i % 2) * 4, true, PAL, 2)


## Saray / divan: hükümdar tahtta, iki yanda vezirler, şamdanlar (hikâye modu: huzura çıkma)
func _pre_court() -> void:
	R(0, 0, pw, ph, "n")
	for y in range(0, ph, 3):
		R(0, y, pw, 3, PAL.n.lerp(PAL.p, float(y) / ph * 0.6))
	for i in 7:                                            # kemerler
		var ax: float = i * (pw / 7.0) + 4
		circ(ax + 6, int(ph * 0.22), 6, "p")
		R(ax, int(ph * 0.22), 13, int(ph * 0.5), "p")
		circ(ax + 6, int(ph * 0.22), 4, "n")
		R(ax + 2, int(ph * 0.22), 9, int(ph * 0.5), "n")
	R(0, int(ph * 0.72), pw, ph, "m")                      # halı/zemin
	for x in range(0, pw, 8):
		R(x, int(ph * 0.72) + 2, 4, 1, "r")
	var tx: int = pw / 2
	R(tx - 14, int(ph * 0.48), 28, 24, "y")                 # taht
	R(tx - 12, int(ph * 0.5), 24, 20, "r")
	spr(SULTAN, tx - 8, int(ph * 0.42), false, PAL, 2)
	for side in 2:
		var sx: float = tx - 44 + side * 70
		spr(HAT_MAN, sx, int(ph * 0.52), side == 1, {"k": PAL.w, "e": PAL.e, "d": PAL.b, "w": PAL.w, "r": PAL.r}, 2)
	for i in 2:                                            # şamdanlar
		var cx: float = tx - 60 + i * 120
		R(cx, int(ph * 0.4), 2, 26, "y")
		R(cx - 1, int(ph * 0.36) - (fr % 2), 4, 4, "o")
		R(cx, int(ph * 0.34) - (fr % 2), 2, 2, "y")
	if (fr / 6) % 5 == 0:
		R(0, 0, pw, ph, A("y", 0.05))


## Yemin: diz çökmüş komutan, hükümdar elini uzatıyor, arkada sancaklar
func _pre_oath() -> void:
	sky(["o", "y", "e"], gy)
	circ(pw * 0.5, gy - 10, 10, A("y", 0.5))
	ground("h")
	R(0, gy, pw, 3, "H")
	var fc := ["r", "y", "r", "y", "r", "y"]
	for i in 6:
		var fx: float = pw * (0.06 + i * 0.17)
		R(fx, gy - 18, 1, 24, "k")
		for s in 6:
			R(fx + 1 + s, gy - 18 + int(sin(t * 3 + s * 0.6 + i) * 1.4), 1, 5, fc[i])
	spr(SULTAN, pw * 0.5 + 6, gy - 14, true, PAL, 2)
	R(pw * 0.5 - 2, gy - 2 + (fr % 8) / 4, 8, 2, "e")      # uzanan el
	# diz çökmüş komutan
	var kx: float = pw * 0.5 - 28
	R(kx, gy - 8, 6, 6, "k")
	R(kx + 1, gy - 2, 4, 4, "e")
	R(kx - 2, gy + 2, 10, 6, "b")
	R(kx + 8, gy + 4, 6, 2, "b")
	R(kx - 1, gy + 8, 4, 4, "k")
	R(kx + 10, gy - 10, 1, 20, "k")                        # kılıç saplı
	for i in 8:
		var f: float = fposmod(i * 0.21 + t * 0.03, 1.0)
		R(fposmod(i * 0.43, 1.0) * pw, ph * (1.0 - f), 1, 1, A("y", sin(f * PI) * 0.5))


## Tımar: köy, tarla, değirmen; köylüler çalışıyor
func _pre_fief() -> void:
	sky(["c", "C", "y"])
	circ(pw * 0.15, gy - 14, 7, "y")
	cloud(wrapx(1.5, 20, pw), 8, "w")
	hills(gy + 1, "g", 9, 0.045, 1.0)
	ground("H", gy + 3)
	for row in range(gy + 6, ph, 4):                       # tarla sıraları
		var x := int(fposmod(row * 1.7, 8.0))
		while x < pw * 0.5:
			R(x, row, 5, 1, "e")
			x += 8
	for i in 3:                                            # evler
		var hx: float = pw * 0.55 + i * 18
		R(hx, gy - 5, 12, 8, "e")
		R(hx - 1, gy - 8, 14, 3, "r")
		R(hx + 4, gy - 1, 3, 4, "m")
	R(pw * 0.86, gy - 20, 6, 24, "m")                      # değirmen
	for j in 4:
		var a: float = t * 1.5 + j * PI * 0.5
		R(pw * 0.86 + 3 + cos(a) * 9, gy - 18 + sin(a) * 9, 2, 2, "w")
		R(pw * 0.86 + 3 + cos(a) * 5, gy - 18 + sin(a) * 5, 2, 2, "w")
	for i in 4:
		var px: float = pw * 0.08 + i * 12
		var bend: int = 1 if (fr / 3 + i) % 2 == 0 else 0
		R(px, gy + 8 + bend, 3, 3, "e")
		R(px, gy + 11 + bend, 3, 4, "m")
	smoke(pw * 0.6, gy - 8, 3, "l", 12)


## İsyan: yakılan ferman, kalabalık, kızıl sancak kaldırılıyor
func _pre_rebel() -> void:
	sky(["p", "r", "o"])
	stars(5, int(gy * 0.3), 11.0)
	domes(pw * 0.7, gy, 2, "k")
	ground("d")
	R(0, gy - 2, pw, 3, A("r", 0.4 + 0.15 * sin(t * 4.0)))
	for i in 12:
		var sx: float = pw * 0.05 + i * 7 + sin(t * 2 + i) * 1.5
		spr(MUSKETEER_B if (fr + i) % 2 == 0 else MUSKETEER, sx, gy + 4 + (i % 2) * 4)
		if i % 3 == 0:
			R(sx + 1, gy - 2 - (fr % 2), 2, 3, "o")         # meşale
	R(pw * 0.45, gy - 24, 1, 30, "k")
	R(pw * 0.45 + 1, gy - 24, 12 + int(sin(t * 5.0) * 2), 7, "r")
	boom(pw * 0.72, gy - 10, fposmod(t * 0.6, 1.4))
	smoke(pw * 0.72, gy - 12, 5, "d", 30)


## Ordugâh: çadırlar, ateş, nöbetçiler
func _pre_camp() -> void:
	sky(["k", "n", "p"])
	stars(18, int(gy * 0.6), 2.0)
	circ(pw * 0.85, int(gy * 0.25), 4, "l")
	hills(gy + 1, "n", 6, 0.05, 5.0)
	ground("d")
	for i in 5:
		var tx: float = pw * 0.06 + i * 22
		var ty: float = gy + 2 + (i % 2) * 5
		for j in 8:
			R(tx + 7 - j, ty - 8 + j, j * 2 + 1, 1, "w" if i != 2 else "r")
		R(tx + 6, ty - 2, 3, 2, "k")
	var fx: float = pw * 0.5
	R(fx - 3, gy + 10, 7, 2, "m")
	R(fx - 1, gy + 6 + (fr % 2), 3, 4, "o")
	R(fx, gy + 4 + (fr % 2), 1, 3, "y")
	for s in 6:
		R(fx - 8 - s, gy + 2 + s, 16 + s * 2, 1, A("o", 0.08))
	spr(MUSKETEER, fx - 14, gy + 6)
	spr(MUSKETEER_B, fx + 10, gy + 6, true)
	R(pw * 0.85, gy - 18, 1, 24, "k")
	circ(pw * 0.85, gy - 19, 2, "y")
	R(pw * 0.85 + 2, gy - 15, 8 + int(sin(t * 4.0)), 5, "r")


func _pre_siege() -> void:
	sky(["d", "s", "l"])
	hills(gy, "s", 6, 0.05, 1.5)
	castle(pw * 0.62, gy + 2, 40, "s", true)
	ground("m")
	R(pw * 0.1, gy + 6, 18, 3, "m")                        # kuşatma kulesi
	R(pw * 0.1 + 2, gy - 14, 12, 20, "m")
	R(pw * 0.1 + 4, gy - 12, 8, 3, "k")
	R(pw * 0.1 + 12, gy - 8 + int(fposmod(t * 3.0, 6.0)), 10, 1, "e")   # köprü
	for i in 2:
		var bx: float = pw * 0.33 + i * 20
		R(bx, gy + 8, 14, 3, "m")
		R(bx + 2, gy + 5, 12, 3, "e")
		if (fr + i * 9) % 20 < 2:
			muzzle(bx + 16, gy + 6)
	boom(pw * 0.7, gy - 8, fposmod(t * 0.5, 1.5))
	for i in 5:
		spr(PIKEMAN, pw * 0.4 + i * 7, gy + 12 + (i % 2) * 3)


func _pre_tribute() -> void:
	sky(["o", "y", "e"], gy)
	domes(pw * 0.1, gy - 2, 2, "d")
	ground("e", gy + 2)
	R(0, gy + 9, pw, 3, "m")
	for i in 3:
		var cx: float = wrapx(3.5, i * 28.0 + pw * 0.3, pw, 30.0)
		spr(CAMEL, cx, gy + 2 + (i % 2))
		R(cx + 3, gy, 6, 3, "y")                            # altın sandık
		R(cx + 4, gy + 1, 4, 1, "o")
	spr(SULTAN, pw * 0.72, gy - 6, true, PAL, 2)
	for i in 6:
		var f: float = fposmod(t * 0.35 + i * 0.16, 1.0)
		R(pw * 0.5 + i * 4 + sin(t + i) * 3, gy + 4 - f * 16, 1, 1, A("y", 1.0 - f))


# ============================================================ I. Dünya Savaşı: çift kanatlı uçaklar

func _ww1_air() -> void:
	sky(["s", "l", "y"], gy)
	cloud(wrapx(2.0, 10, pw), 8, "w")
	cloud(wrapx(1.3, pw * 0.5, pw), 16, "w")
	hills(gy + 1, "h", 6, 0.05, 4.0)
	ground("H")
	R(0, gy + 6, pw, 2, "m")
	for i in range(0, pw, 9):
		R(i, gy + 3, 1, 5, "k")
	for i in 3:
		var fx: float = wrapx(14.0 + i * 2.0, i * pw / 3.0, pw, 30.0)
		var fy: float = 6 + i * 9 + sin(t * 2.0 + i) * 2
		spr(BIPLANE, fx, fy, false, {"k": PAL.k if i != 1 else PAL.r})
		if (fr + i * 4) % 10 < 3:
			R(fx + 12, fy + 2, 4, 1, "y")
	var ex: float = wrapx(6.0, pw * 0.6, pw, 20.0)
	spr(BIPLANE, ex, 14 + sin(t * 3.0) * 2, true, {"k": PAL.d})
	smoke(ex + 4, 16, 4, "s", 10)
	for i in 4:
		var fa: float = fposmod(t * 0.9 + i * 0.25, 1.0)
		if fa < 0.5:
			circ(pw * (0.2 + i * 0.2), gy * (0.3 + fposmod(i * 0.3, 0.4)), 1 + int(fa * 4), A("k", 0.5 - fa))
