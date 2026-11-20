extends RefCounted
## Filo uzantıları: gemi sınıfları (filonun içindeki gemiler), ad, rütbe/tecrübe, duruş, ikmal menzili.
## Yalnızca Seas/Eras/Arsenal'e dayanır (fleets.gd bunu yükler; döngüsel bağımlılık yok).

const Seas = preload("res://scripts/seas.gd")
const Eras = preload("res://scripts/eras.gd")
const Arsenal = preload("res://scripts/arsenal.gd")

# ------------------------------------------------------------------ rütbe (tecrübe)
const RANKS := [[0.0, "Acemi", 1.0], [6.0, "Tecrübeli", 1.06], [16.0, "Elit", 1.13], [36.0, "Efsane", 1.22]]
const XP_MAX := 60.0

# ------------------------------------------------------------------ duruş
const STANCES := ["attack", "defend", "avoid"]
const STANCE_TR := {"attack": "Saldırı", "defend": "Savunma", "avoid": "Çekil"}
const STANCE_HINT := {
	"attack": "Düşman filosunu arar; yapay zekâ komutu açıksa hedef seçer.",
	"defend": "Bulunduğu denizi tutar, kendi limanında %10 güçlü savaşır; kendiliğinden saldırıya gitmez.",
	"avoid": "Düşman kendisinden belirgin güçlüyse savaşmadan en yakın limana çekilir.",
}
const DEFEND_BONUS := 1.10
const AVOID_RATIO := 1.15

# ------------------------------------------------------------------ gemi sınıfları
# [anahtar, Türkçe ad, ağırlık, ağır(1)/hafif(0)]
const SURFACE := {
	"pre": [["galleon", "Kalyon", 3.0, 1], ["carrack", "Karaka", 3.0, 1], ["galley", "Kadırga", 5.0, 0]],
	"ww1": [["dreadnought", "Dretnot", 2.0, 1], ["cruiser", "Kruvazör", 3.0, 1], ["destroyer", "Muhrip", 6.0, 0], ["torpedo_boat", "Torpido botu", 4.0, 0]],
	"ww2": [["battleship", "Zırhlı", 1.5, 1], ["heavy_cruiser", "Ağır kruvazör", 2.5, 1], ["light_cruiser", "Hafif kruvazör", 3.0, 1], ["destroyer", "Muhrip", 7.0, 0], ["escort", "Eskort muhribi", 4.0, 0]],
	"cold": [["cruiser", "Kruvazör", 2.0, 1], ["destroyer", "Muhrip", 6.0, 0], ["frigate", "Firkateyn", 6.0, 0], ["missile_boat", "Füze botu", 3.0, 0]],
	"": [["cruiser", "Kruvazör", 1.5, 1], ["destroyer", "Muhrip", 5.0, 0], ["frigate", "Firkateyn", 6.0, 0], ["corvette", "Korvet", 4.0, 0], ["patrol", "Karakol botu", 2.5, 0]],
}
const CARRIER_NAME := {"pre": "Amiral gemisi", "ww1": "Uçak gemisi", "ww2": "Uçak gemisi", "cold": "Uçak gemisi", "": "Uçak gemisi"}
const SUB_FALLBACK := {"pre": "Galiot", "ww1": "Denizaltı", "ww2": "U-botu / denizaltı", "cold": "Denizaltı", "": "Denizaltı"}


static func family() -> String:
	var f: String = Eras.family()
	if SURFACE.has(f):
		return f
	# bilinmeyen çağ ailesi: modern say; "ww1/ww2/cold" dışındakiler eski çağ olabilir
	if f.begins_with("ott") or f.begins_with("tim") or f == "med":
		return "pre"
	return ""


static func rank_index(xp: float) -> int:
	var idx := 0
	for i in RANKS.size():
		if xp >= float(RANKS[i][0]):
			idx = i
	return idx


static func rank_name(xp: float) -> String:
	return String(RANKS[rank_index(xp)][1])


static func rank_mult(xp: float) -> float:
	return float(RANKS[rank_index(xp)][2])


## Sonraki rütbeye kalan tecrübe (0 = son rütbe)
static func xp_to_next(xp: float) -> float:
	var i: int = rank_index(xp)
	if i >= RANKS.size() - 1:
		return 0.0
	return float(RANKS[i + 1][0]) - xp


## Yüzey filosundaki ağır gemi payı (0..1)
static func heavy_share() -> float:
	var tot := 0.0
	var hv := 0.0
	for e in SURFACE[family()]:
		tot += float(e[2])
		if int(e[3]) == 1:
			hv += float(e[2])
	return hv / maxf(tot, 0.001)


## Büyük kalan yöntemiyle ağırlığa göre dağıtım: [[anahtar, ad, adet], ...] (adet > 0 olanlar)
static func _alloc(entries: Array, total: int) -> Array:
	var wsum := 0.0
	for e in entries:
		wsum += float(e[2])
	var out: Array = []
	var used := 0
	var rem: Array = []
	for e in entries:
		var exact: float = float(total) * float(e[2]) / wsum
		var n: int = int(floor(exact))
		out.append([e[0], e[1], n])
		used += n
		rem.append(exact - float(n))
	var left: int = total - used
	var guard := 0
	while left > 0 and guard < 50:
		var bi := 0
		for i in rem.size():
			if rem[i] > rem[bi]:
				bi = i
		out[bi][2] = int(out[bi][2]) + 1
		rem[bi] = -1.0
		left -= 1
		guard += 1
	var res: Array = []
	for o in out:
		if int(o[2]) > 0:
			res.append(o)
	return res


static func surface_count(size: float) -> int:
	return clampi(int(round(2.0 + size * 1.6)), 2, 44)


## Filonun içindeki gemiler: [[anahtar, ad, adet, tür]], tür: surface/sub/carrier/transport (UI simgesi için)
static func ships(gs, f) -> Array:
	var fam: String = family()
	var out: Array = []
	match f.kind:
		"surface":
			for r in _alloc(SURFACE[fam], surface_count(f.size)):
				out.append([r[0], r[1], r[2], "surface"])
		"carrier":
			var n: int = maxi(1, int(round(f.size)))
			out.append(["carrier", CARRIER_NAME[fam], n, "carrier"])
			var esc: Array = SURFACE[fam]
			var heavy: Array = []
			var light: Array = []
			for e in esc:
				(heavy if int(e[3]) == 1 else light).append(e)
			if not heavy.is_empty():
				out.append([heavy[0][0] + "_esc", heavy[0][1] + " (eskort)", n, "surface"])
			if not light.is_empty():
				out.append([light[0][0] + "_esc", light[0][1] + " (eskort)", n * 2, "surface"])
			out.append(["air_wing", "Hava kanadı (uçak)", n * 40, "air"])
		"transport":
			var m: int = maxi(1, int(round(f.size)))
			var lst: int = int(floor(float(m) * 0.35))
			out.append(["transport", "Nakliye gemisi", maxi(1, m - lst), "transport"])
			if lst > 0:
				out.append(["landing_ship", "Çıkarma gemisi", lst, "transport"])
		"sub":
			out = _sub_models(gs, f)
	return out


## Denizaltı filosu: ülkenin envanterindeki model adları (filonun payı kadar), yoksa çağın genel adı
static func _sub_models(gs, f) -> Array:
	var out: Array = []
	var c = gs.countries[f.owner]
	var total := 0.0
	var models: Array = []
	for id in c.inv:
		if not Arsenal.ITEMS.has(id) or Arsenal.cat_of(id) != "sub":
			continue
		var n: int = int(c.inv[id])
		if n <= 0:
			continue
		models.append([id, n])
		total += float(n)
	var mine := 0.0
	var cnt := 0.0
	for g in gs.fleets.values():
		if g.owner == f.owner and g.kind == "sub":
			cnt += g.size
	if total > 0.0 and cnt > 0.0:
		mine = clampf(f.size / cnt, 0.0, 1.0)
		models.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
		for m in models:
			var k: int = int(round(float(m[1]) * mine))
			if k > 0:
				out.append([String(m[0]), Arsenal.name_of(String(m[0])), k, "sub"])
			if out.size() >= 5:
				break
	if out.is_empty():
		out.append(["sub", SUB_FALLBACK[family()], maxi(1, int(round(f.size / 3.0))), "sub"])
	return out


static func ship_total(gs, f) -> int:
	var n := 0
	for s in ships(gs, f):
		if String(s[3]) != "air":
			n += int(s[2])
	return n


# ------------------------------------------------------------------ ad
const KIND_TPL := {"surface": "%d. Muharebe Filosu", "sub": "%d. Denizaltı Filosu", "carrier": "%d. Uçak Gemisi Grubu", "transport": "%d. Nakliye Filosu"}


static func ordinal_k(gs, f) -> int:
	var k := 0
	for g in gs.fleets.values():
		if g.owner == f.owner and g.kind == f.kind and g.id <= f.id:
			k += 1
	return maxi(k, 1)


static func ordinal_tpl(f) -> String:
	return String(KIND_TPL.get(f.kind, "%d. Filo"))


static func ordinal_name(gs, f) -> String:
	return ordinal_tpl(f) % ordinal_k(gs, f)


## Gösterilecek ad: oyuncunun verdiği ya da varsayılan (varsayılan Türkçe kaynak; arayüzde çevrilir)
static func custom_name(f) -> String:
	return String(f.name)


# ------------------------------------------------------------------ ikmal
## Filonun en yakın dost/müttefik limanına sıçrama uzaklığı; limanı yoksa 99
static func port_hops(f, port_zones: Dictionary) -> int:
	if port_zones.is_empty():
		return 99
	if port_zones.has(f.zone):
		return 0
	var best := 99
	for z in port_zones:
		var h: int = Seas.hops(f.zone, z)
		if h < best:
			best = h
	return best


static func supply_mult_for(kind: String, hops: int) -> float:
	if hops <= 2:
		return 1.0
	var floor_v := 0.7
	if kind == "sub" or kind == "carrier":
		floor_v = 0.85
	return maxf(floor_v, 1.0 - 0.06 * float(hops - 2))


static func supply_label(hops: int) -> String:
	if hops <= 2:
		return "İyi"
	if hops <= 4:
		return "Uzak"
	return "Kritik"
