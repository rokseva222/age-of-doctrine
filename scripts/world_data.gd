extends RefCounted
## Gerçek dünya verisini (data/world.json) okur: ülke/eyalet nesneleri, çizim ağları (mesh), dokunma ızgarası.
## Geometri tüm oyunlar için paylaşılır; oyun durumu (sahiplik vb.) her yeni oyunda taze nesnelerle kurulur.

const Model = preload("res://scripts/model.gd")
const PATH := "res://data/world.json"
const GRID := 24.0
const MITER_MAX := 2.5

# kara paleti: 12 ana ton + 4 sakin ton (H derece, S, V). Koyu lacivert denize karşı 3.6-9.2 kontrast.
const PALETTE := [
	[3, 0.70, 0.78], [33, 0.79, 0.86], [46, 0.71, 0.85], [71, 0.59, 0.72], [134, 0.54, 0.64],
	[170, 0.71, 0.61], [194, 0.66, 0.79], [217, 0.64, 0.84], [243, 0.51, 0.84], [275, 0.50, 0.80],
	[320, 0.54, 0.78], [351, 0.44, 0.90], [30, 0.63, 0.66], [42, 0.28, 0.80], [212, 0.25, 0.65], [99, 0.38, 0.54],
]

static var _inst = null

var raw: Dictionary = {}
var world_rect := Rect2()
var scale_deg := 5.0

# geometri (paylaşılan, salt okunur)
var geo_provinces: Array = []     # her biri: {rings, bbox, label_pos, label_r, ...} ham veri
var fill_arrays: Array = []       # ArrayMesh için diziler
var border_arrays: Array = []
var lake_arrays: Array = []
var grid: Dictionary = {}
var prov_order: Array = []
var load_ms := 0


static func instance():
	if _inst == null:
		_inst = load("res://scripts/world_data.gd").new()
		_inst._load()
	return _inst


func _load() -> void:
	var t0 := Time.get_ticks_msec()
	var txt := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("world.json okunamadı")
		return
	raw = parsed
	scale_deg = float(raw.get("scale", 5.0))
	_build_geometry()
	load_ms = Time.get_ticks_msec() - t0


static func _to_vec_array(flat: Array) -> PackedVector2Array:
	var n := flat.size() / 2
	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		out[i] = Vector2(flat[i * 2], flat[i * 2 + 1])
	return out


func _build_geometry() -> void:
	var provs: Array = raw.provinces
	var xmin := 1e9
	var ymin := 1e9
	var xmax := -1e9
	var ymax := -1e9
	geo_provinces.resize(provs.size())
	for p in provs:
		var rings: Array = []
		for r in p.rings:
			rings.append(_to_vec_array(r))
		var bb: Array = p.bb
		var rect := Rect2(bb[0], bb[1], bb[2] - bb[0], bb[3] - bb[1])
		xmin = minf(xmin, rect.position.x)
		ymin = minf(ymin, rect.position.y)
		xmax = maxf(xmax, rect.end.x)
		ymax = maxf(ymax, rect.end.y)
		geo_provinces[p.id] = {"rings": rings, "bbox": rect, "lab": Vector2(p.lab[0], p.lab[1]), "lab_r": float(p.lab[2]), "area": int(p.area)}
	world_rect = Rect2(xmin, ymin, xmax - xmin, ymax - ymin).grow(10.0)

	# --- dolgu ağı (büyük eyaletler önce çizilir, enklavlar üstüne gelir)
	prov_order = range(provs.size())
	prov_order.sort_custom(func(a, b): return geo_provinces[a].area > geo_provinces[b].area)
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var bad := 0
	for pid in prov_order:
		for ring in geo_provinces[pid].rings:
			var parts: Array = _triangulate(ring)
			if parts.is_empty():
				bad += 1
				print("  üçgenlenemedi: ", raw.provinces[pid].name, " (", ring.size(), " köşe)")
				continue
			for part in parts:
				var pv: PackedVector2Array = part[0]
				var pt: PackedInt32Array = part[1]
				var base := verts.size()
				verts.append_array(pv)
				for i in pv.size():
					uvs.append(Vector2(pid, 0))
				for t in pt:
					idx.append(base + t)
	fill_arrays = [verts, uvs, idx]
	if bad > 0:
		print("uyarı: üçgenlenemeyen halka: ", bad)

	# --- göller
	var lv := PackedVector2Array()
	var li := PackedInt32Array()
	for flat in raw.lakes:
		var ring := _to_vec_array(flat)
		var tri2 := Geometry2D.triangulate_polygon(ring)
		if tri2.is_empty():
			continue
		var base2 := lv.size()
		lv.append_array(ring)
		for t in tri2:
			li.append(base2 + t)
	lake_arrays = [lv, li]

	# --- sınır şeritleri
	var bv := PackedVector2Array()
	var bu := PackedVector2Array()
	var bc := PackedColorArray()
	var bi := PackedInt32Array()
	for b in raw.borders:
		_add_border_strip(b, bv, bu, bc, bi)
	border_arrays = [bv, bu, bc, bi]

	# --- dokunma ızgarası
	for pid in geo_provinces.size():
		var r: Rect2 = geo_provinces[pid].bbox
		for gx in range(int(floor(r.position.x / GRID)), int(floor(r.end.x / GRID)) + 1):
			for gy in range(int(floor(r.position.y / GRID)), int(floor(r.end.y / GRID)) + 1):
				var k := Vector2i(gx, gy)
				if not grid.has(k):
					grid[k] = []
				grid[k].append(pid)


## Halkayı üçgenler; başarısız olursa kendini kesen halkayı temizleyip yeniden dener.
func _clean_ring(ring: PackedVector2Array, min_d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in ring:
		if out.is_empty() or out[out.size() - 1].distance_to(v) >= min_d:
			out.append(v)
	while out.size() > 2 and out[0].distance_to(out[out.size() - 1]) < min_d:
		out.remove_at(out.size() - 1)
	# iğne ucu: bir önceki ve sonraki nokta aynıysa at
	var i := 1
	while i < out.size() - 1 and out.size() > 3:
		if out[i - 1].distance_to(out[i + 1]) < min_d:
			out.remove_at(i)
			out.remove_at(i)
			i = maxi(1, i - 1)
		else:
			i += 1
	return out


func _triangulate(ring0: PackedVector2Array) -> Array:
	var tri := Geometry2D.triangulate_polygon(ring0)
	if not tri.is_empty():
		return [[ring0, tri]]
	# kendine değen/kesişen halka: birleşim ile sadeleştir (parçalara ayrılır)
	var out: Array = []
	for m in Geometry2D.merge_polygons(ring0, PackedVector2Array()):
		if Geometry2D.is_polygon_clockwise(m):
			continue   # delik
		var t2 := Geometry2D.triangulate_polygon(m)
		if not t2.is_empty():
			out.append([m, t2])
	if not out.is_empty():
		return out
	for md in [0.02, 0.06, 0.15]:
		var ring := _clean_ring(ring0, md)
		if ring.size() < 3:
			continue
		var t3 := Geometry2D.triangulate_polygon(ring)
		if not t3.is_empty():
			return [[ring, t3]]
		for m2 in Geometry2D.merge_polygons(ring, PackedVector2Array()):
			if Geometry2D.is_polygon_clockwise(m2):
				continue
			var t4 := Geometry2D.triangulate_polygon(m2)
			if not t4.is_empty():
				out.append([m2, t4])
		if not out.is_empty():
			return out
	return out


func _add_border_strip(b: Dictionary, bv: PackedVector2Array, bu: PackedVector2Array, bc: PackedColorArray, bi: PackedInt32Array) -> void:
	var pts := _to_vec_array(b.p)
	var n := pts.size()
	if n < 2:
		return
	var closed := n > 2 and pts[0].distance_to(pts[n - 1]) < 0.001
	var a: int = b.a
	var bb: int = b.b
	var uv := Vector2(a, bb)
	var base := bv.size()
	for i in n:
		var prev := Vector2.ZERO
		var next := Vector2.ZERO
		var has_prev := false
		var has_next := false
		if i > 0:
			prev = pts[i] - pts[i - 1]
			has_prev = true
		elif closed:
			prev = pts[0] - pts[n - 2]
			has_prev = true
		if i < n - 1:
			next = pts[i + 1] - pts[i]
			has_next = true
		elif closed:
			next = pts[1] - pts[0]
			has_next = true
		var n1 := Vector2.ZERO
		var n2 := Vector2.ZERO
		if has_prev and prev.length() > 0.0001:
			var t := prev.normalized()
			n1 = Vector2(-t.y, t.x)
		if has_next and next.length() > 0.0001:
			var t2 := next.normalized()
			n2 = Vector2(-t2.y, t2.x)
		var dir := Vector2.ZERO
		if n1 == Vector2.ZERO:
			dir = n2
		elif n2 == Vector2.ZERO:
			dir = n1
		else:
			var m := (n1 + n2)
			if m.length() < 0.0001:
				dir = n1
			else:
				m = m.normalized()
				var d := maxf(m.dot(n1), 0.0001)
				dir = m * minf(1.0 / d, MITER_MAX)
		var e := dir / (2.0 * MITER_MAX) + Vector2(0.5, 0.5)
		var e2 := Vector2(1.0, 1.0) - e
		bv.append(pts[i])
		bu.append(uv)
		bc.append(Color(e.x, e.y, 0.0, 1.0))
		bv.append(pts[i])
		bu.append(uv)
		bc.append(Color(e2.x, e2.y, 0.0, 1.0))
	for i in n - 1:
		var k := base + i * 2
		bi.append_array(PackedInt32Array([k, k + 1, k + 2, k + 1, k + 3, k + 2]))


# ------------------------------------------------------------------ oyun nesneleri

func populate(gs) -> void:
	gs.provinces = []
	gs.countries = []
	var provs: Array = raw.provinces
	var cts: Array = raw.countries
	for c in cts:
		var cc := Model.Country.new()
		cc.id = c.id
		cc.a3 = c.a3
		cc.iso = c.iso
		cc.name = c.name
		cc.name_en = c.name_en
		cc.continent = c.cont
		cc.pop = c.pop
		cc.gdp = c.gdp
		cc.capital = c.capital
		cc.aggression = 0.35 + fmod(float(hash(c.a3) & 0xffff) / 65535.0, 1.0) * 0.6
		gs.countries.append(cc)
	for p in provs:
		var pp := Model.Province.new()
		var g: Dictionary = geo_provinces[p.id]
		pp.id = p.id
		pp.name = p.name
		pp.city = p.city
		pp.rings = g.rings
		pp.bbox = g.bbox
		pp.label_pos = g.lab
		pp.label_r = g.lab_r
		pp.area_km2 = g.area
		pp.neighbors = []
		for q in p.nb:
			pp.neighbors.append(int(q))
		pp.sea_links = []
		for q in p.sea:
			pp.sea_links.append(int(q))
		pp.landmass = p.lm
		pp.owner = p.c
		pp.controller = p.c
		pp.core = p.c
		pp.home = p.c
		gs.provinces.append(pp)
	for c in cts:
		var cc2 = gs.countries[c.id]
		var plist: Array = c.provs
		cc2.total_area = 0
		var wsum := 0.0
		var csum := 0.0
		for pid in plist:
			wsum += 0.45 * float(provs[pid].area) / 1000.0 + 0.0001
			csum += float(provs[pid].cpop)
		var share_tot := 0.0
		var weights: Dictionary = {}
		var area_tot := 0.0
		for pid in plist:
			area_tot += float(provs[pid].area)
		for pid in plist:
			var wa: float = float(provs[pid].area) / maxf(area_tot, 1.0)
			var wc: float = float(provs[pid].cpop) / csum if csum > 0.0 else wa
			var w: float = 0.35 * wa + 0.65 * wc if csum > 0.0 else wa
			w = maxf(w, 0.02)
			weights[pid] = w
			share_tot += w
		var gdp_pc: float = cc2.gdp / maxf(cc2.pop, 0.001)
		var base_dev := 1
		if gdp_pc >= 35000.0:
			base_dev = 5
		elif gdp_pc >= 15000.0:
			base_dev = 4
		elif gdp_pc >= 5000.0:
			base_dev = 3
		elif gdp_pc >= 1500.0:
			base_dev = 2
		for pid in plist:
			var pr = gs.provinces[pid]
			var share: float = weights[pid] / share_tot
			pr.pop = cc2.pop * share
			pr.gdp = cc2.gdp * share
			var bonus := 0
			if float(provs[pid].cpop) > 5000000.0 and base_dev < 5:
				bonus = 1
			pr.dev = clampi(base_dev + bonus, 1, 5)
			cc2.total_area += provs[pid].area
		if cc2.capital >= 0:
			var cp = gs.provinces[cc2.capital]
			cp.is_capital = true
			cp.dev = clampi(cp.dev + 1, 1, 5)
			cp.defense = 1
		_country_label(cc2, plist, gs)
	for p in provs:
		var pr2 = gs.provinces[p.id]
		pr2.coastal = false
	for b in raw.borders:
		if int(b.b) < 0:
			gs.provinces[b.a].coastal = true
	_color_countries(gs)


func _country_label(cc, plist: Array, gs) -> void:
	# en büyük kara parçasının eyaletleri
	var area_by_lm: Dictionary = {}
	for pid in plist:
		var lm: int = gs.provinces[pid].landmass
		area_by_lm[lm] = area_by_lm.get(lm, 0.0) + float(gs.provinces[pid].area_km2)
	var best_lm := -1
	var best_a := -1.0
	for lm in area_by_lm:
		if area_by_lm[lm] > best_a:
			best_a = area_by_lm[lm]
			best_lm = lm
	var wsum := 0.0
	var pos := Vector2.ZERO
	var rect := Rect2()
	var first := true
	for pid in plist:
		var p = gs.provinces[pid]
		if p.landmass != best_lm:
			continue
		var w := float(p.area_km2) + 1.0
		pos += p.label_pos * w
		wsum += w
		if first:
			rect = p.bbox
			first = false
		else:
			rect = rect.merge(p.bbox)
	if wsum > 0.0:
		cc.label_pos = pos / wsum
		cc.label_w = rect.size.x
		# ağırlıklı merkez denizde kalırsa en yakın eyalet etiketine çek
		var inside := false
		for pid in plist:
			var p2 = gs.provinces[pid]
			if p2.bbox.has_point(cc.label_pos):
				for r in p2.rings:
					if Geometry2D.is_point_in_polygon(cc.label_pos, r):
						inside = true
						break
			if inside:
				break
		if not inside:
			var bd := 1e18
			for pid in plist:
				var p3 = gs.provinces[pid]
				if p3.landmass != best_lm:
					continue
				var d: float = p3.label_pos.distance_squared_to(cc.label_pos)
				if d < bd:
					bd = d
					cc.label_pos = p3.label_pos


func _color_countries(gs) -> void:
	var n: int = gs.countries.size()
	var adj: Array = []
	for i in n:
		adj.append({})
	for p in gs.provinces:
		for q in p.neighbors:
			var o: int = gs.provinces[q].owner
			if o != p.owner:
				adj[p.owner][o] = true
		for q in p.sea_links:
			var o2: int = gs.provinces[q].owner
			if o2 != p.owner:
				adj[p.owner][o2] = true
	var order: Array = range(n)
	order.sort_custom(func(a, b): return adj[a].size() > adj[b].size() or (adj[a].size() == adj[b].size() and a < b))
	var pick: Array = []
	pick.resize(n)
	pick.fill(-1)
	var use: Array = []
	use.resize(PALETTE.size())
	use.fill(0)
	for i in order:
		var bad: Dictionary = {}
		for j in adj[i]:
			if pick[j] >= 0:
				bad[pick[j]] = true
		var best := -1
		for k in PALETTE.size():
			if bad.has(k):
				continue
			if best < 0 or use[k] < use[best]:
				best = k
		if best < 0:
			best = 0
			for k in PALETTE.size():
				if use[k] < use[best]:
					best = k
		pick[i] = best
		use[best] += 1
	for i in n:
		var h: Array = PALETTE[pick[i]]
		gs.countries[i].color = Color.from_hsv(float(h[0]) / 360.0, h[1], h[2])
		gs.countries[i].color2 = gs.countries[i].color.darkened(0.4)
		gs.countries[i].color3 = gs.countries[i].color.lightened(0.3)


# ------------------------------------------------------------------ dokunma

## Dünya koordinatındaki noktayı eyalete çevirir. tol: dünya biriminde yakınlık toleransı.
func province_at(gs, wp: Vector2, tol: float = 0.0) -> int:
	var k := Vector2i(int(floor(wp.x / GRID)), int(floor(wp.y / GRID)))
	var best := -1
	var best_area := 1 << 60
	if grid.has(k):
		for pid in grid[k]:
			var g: Dictionary = geo_provinces[pid]
			if not g.bbox.has_point(wp):
				continue
			for ring in g.rings:
				if Geometry2D.is_point_in_polygon(wp, ring):
					if g.area < best_area:
						best_area = g.area
						best = pid
					break
	if best >= 0 or tol <= 0.0:
		return best
	# küçük devletler / ince eyaletler için yakınlık
	var bd := tol * tol
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var kk := Vector2i(k.x + dx, k.y + dy)
			if not grid.has(kk):
				continue
			for pid in grid[kk]:
				var d: float = geo_provinces[pid].lab.distance_squared_to(wp)
				if d < bd:
					bd = d
					best = pid
	return best
