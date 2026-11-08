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
