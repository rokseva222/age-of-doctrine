extends Node2D
## Harita görünümü: vektör dolgu/sınır ağları, kamera (kaydır/yakınlaştır/atalet), dokunma ve ekran katmanı (HUD).

const Model = preload("res://scripts/model.gd")
const WorldData = preload("res://scripts/world_data.gd")
const Hud = preload("res://scripts/map_hud.gd")
const SHADER_FILL = preload("res://shaders/fill.gdshader")
const SHADER_BORDER = preload("res://shaders/border.gdshader")
const SHADER_OCEAN = preload("res://shaders/ocean.gdshader")

signal tapped(pid: int)
signal choke_tapped(id: String)

const LUT_W := 2048

var gs = null
var wd = null
var world: Node2D
var hud: Control
var ocean_layer: CanvasLayer
var hud_layer: CanvasLayer
var fill_mat: ShaderMaterial
var border_mat: ShaderMaterial
var glow_mats: Array = []
var glow_nodes: Array = []

var cam_pos := Vector2.ZERO
var zoom := 1.0
var min_zoom := 0.6
var max_zoom := 36.0
var fit_zoom := 1.0

var selected_prov := -1
var selected_army = null
var highlight_country := -1
var rel_country := -1                  # >=0: ilişki görünümü (seçili ülke sarı, müttefik mavi, savaş kırmızı, ateşkes mor)
var input_enabled := true
var ui_insets := Vector4(0, 0, 0, 0)      # sol, üst, sağ, alt (arayüzün kapladığı alan)

var _lut_img: Image
var _lut_tex: ImageTexture
var _lut_dirty := false
var _dirty_provs: Dictionary = {}
var _labels_dirty := true
var _touches := {}
var _pinch_dist := 0.0
var _suppress_tap := false
var _dragging := false
var _moved := false
var _press_pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _tween: Tween = null
var pulses: Array = []
var army_anim: Dictionary = {}
var _army_prev: Dictionary = {}
var country_labels: Dictionary = {}     # cid -> {pos, w}
var anim_time := 0.0


func _ready() -> void:
	ocean_layer = CanvasLayer.new()
	ocean_layer.layer = -10
	add_child(ocean_layer)
	var oc := ColorRect.new()
	oc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var om := ShaderMaterial.new()
	om.shader = SHADER_OCEAN
	oc.material = om
	ocean_layer.add_child(oc)

	world = Node2D.new()
	add_child(world)

	hud_layer = CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	hud = Hud.new()
	hud.map = self
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)

	wd = WorldData.instance()
	_build_meshes()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	reset_camera()


func _build_meshes() -> void:
	_lut_img = Image.create(LUT_W, 4, false, Image.FORMAT_RGBA8)
	_lut_img.fill(Color(0, 0, 0, 0))
	_lut_tex = ImageTexture.create_from_image(_lut_img)

	# kıyı parıltısı (3 katman, zeminde)
	var bmesh := _mesh_from(wd.border_arrays[0], wd.border_arrays[1], wd.border_arrays[3], wd.border_arrays[2])
	var glows := [[12.0, 0.07], [5.0, 0.12]]
	for g in glows:
		var m := ShaderMaterial.new()
		m.shader = SHADER_BORDER
		m.set_shader_parameter("lut", _lut_tex)
		m.set_shader_parameter("glow_mode", 1.0)
		m.set_shader_parameter("glow_w", g[0])
		m.set_shader_parameter("glow_c", Color(0.35, 0.65, 0.9, g[1]))
		glow_mats.append(m)
		var mi := MeshInstance2D.new()
		mi.mesh = bmesh
		mi.material = m
		world.add_child(mi)
		glow_nodes.append(mi)

	# dolgu
	fill_mat = ShaderMaterial.new()
	fill_mat.shader = SHADER_FILL
	fill_mat.set_shader_parameter("lut", _lut_tex)
	var fmesh := _mesh_from(wd.fill_arrays[0], wd.fill_arrays[1], wd.fill_arrays[2])
	var fmi := MeshInstance2D.new()
	fmi.mesh = fmesh
	fmi.material = fill_mat
	world.add_child(fmi)

	# göller
	var lv: PackedVector2Array = wd.lake_arrays[0]
	if lv.size() > 0:
		var lmesh := _mesh_from(lv, PackedVector2Array(), wd.lake_arrays[1])
		var lmi := MeshInstance2D.new()
		lmi.mesh = lmesh
		lmi.modulate = Color(0.06, 0.17, 0.28, 1.0)
		world.add_child(lmi)

	# sınırlar
	border_mat = ShaderMaterial.new()
	border_mat.shader = SHADER_BORDER
	border_mat.set_shader_parameter("lut", _lut_tex)
	var bmi := MeshInstance2D.new()
	bmi.mesh = bmesh
	bmi.material = border_mat
	world.add_child(bmi)


func _mesh_from(verts: PackedVector2Array, uvs: PackedVector2Array, idx: PackedInt32Array, colors: PackedColorArray = PackedColorArray()) -> ArrayMesh:
	var m := ArrayMesh.new()
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = verts
	if uvs.size() > 0:
		a[Mesh.ARRAY_TEX_UV] = uvs
	if colors.size() > 0:
		a[Mesh.ARRAY_COLOR] = colors
	a[Mesh.ARRAY_INDEX] = idx
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return m


# ------------------------------------------------------------------ bağlama

## Kıyı parıltısı gibi ağır efektleri aç/kapat (eski telefonlar için).
func set_quality(high: bool) -> void:
	for n in glow_nodes:
		n.visible = high


func bind(game_state) -> void:
	if gs != null:
		if gs.province_changed.is_connected(_on_province_changed):
			gs.province_changed.disconnect(_on_province_changed)
		if gs.armies_changed.is_connected(_on_armies_changed):
			gs.armies_changed.disconnect(_on_armies_changed)
		if gs.state_changed.is_connected(_on_state_changed):
			gs.state_changed.disconnect(_on_state_changed)
	gs = game_state
	selected_prov = -1
	selected_army = null
	highlight_country = -1
	rel_country = -1
	pulses.clear()
	army_anim.clear()
	_army_prev.clear()
	gs.province_changed.connect(_on_province_changed)
	gs.armies_changed.connect(_on_armies_changed)
	gs.state_changed.connect(_on_state_changed)
	repaint_all()
	_snapshot_armies()
	hud.queue_redraw()


func repaint_all() -> void:
	if gs == null:
		return
	for p in gs.provinces:
		_write_lut(p)
	_lut_tex.update(_lut_img)
	_labels_dirty = true


func _country_fill(cid: int) -> Color:
	if cid < 0:
		return Color(0.3, 0.3, 0.3)
	var c = gs.countries[cid]
	if rel_country >= 0:
		return _rel_fill(cid)
	var col: Color = c.color
	if highlight_country >= 0:
		if cid == highlight_country:
			col = col.lightened(0.12)
		else:
			col = col.lerp(Color(0.10, 0.16, 0.24), 0.68)
	return col


func _rel_fill(cid: int) -> Color:
	var r = gs.countries[rel_country]
	var c = gs.countries[cid]
	if cid == rel_country:
		return Color(0.93, 0.78, 0.28)
	if gs.is_allied(rel_country, cid) or (r.alliance >= 0 and r.alliance == c.alliance):
		return Color(0.30, 0.55, 0.88)
	if gs.at_war(rel_country, cid):
		return Color(0.82, 0.24, 0.24)
	if int(r.truce.get(cid, -1)) > gs.turn:
		return Color(0.55, 0.45, 0.75)
	return Color(0.17, 0.20, 0.25)


func set_relation_view(cid: int) -> void:
	rel_country = cid
	repaint_all()
	hud.queue_redraw()


func _write_lut(p) -> void:
	var x: int = p.id
	_lut_img.set_pixel(x, 0, _country_fill(p.owner))
	var stripe := Color(0, 0, 0, 0)
	if p.controller != p.owner and p.controller >= 0:
		stripe = gs.countries[p.controller].color
		stripe.a = 1.0
		if highlight_country >= 0 or rel_country >= 0:
			stripe.a = 0.0
	_lut_img.set_pixel(x, 1, stripe)
	var packed: int = p.owner + 1
	_lut_img.set_pixel(x, 2, Color((packed & 255) / 255.0, ((packed >> 8) & 255) / 255.0, 0.0, 1.0))


func set_highlight_country(cid: int) -> void:
	if highlight_country == cid:
		return
	highlight_country = cid
	repaint_all()
	hud.queue_redraw()


func _on_province_changed(pid: int) -> void:
	_dirty_provs[pid] = true
	_labels_dirty = true
	var p = gs.provinces[pid]
	if pulses.size() < 12:
		pulses.append({"pos": p.label_pos, "t": 0.0, "col": gs.countries[p.controller].color if p.controller >= 0 else Color.WHITE})


func _on_state_changed() -> void:
	if rel_country >= 0:
		repaint_all()
	hud.queue_redraw()


func _snapshot_armies() -> void:
	_army_prev.clear()
	for a in gs.armies.values():
		_army_prev[a.id] = a.prov


func _on_armies_changed() -> void:
	for a in gs.armies.values():
		var old = _army_prev.get(a.id)
		if old != null and old != a.prov:
			army_anim[a.id] = {"from": gs.provinces[old].label_pos, "to": gs.provinces[a.prov].label_pos, "t": 0.0}
	_snapshot_armies()
	hud.queue_redraw()


func select_province(pid: int) -> void:
	selected_prov = pid
	hud.queue_redraw()


func set_selected_army(a) -> void:
	selected_army = a
	hud.queue_redraw()


# ------------------------------------------------------------------ kamera

func world_rect() -> Rect2:
	return wd.world_rect


func _on_viewport_resized() -> void:
	var vp := get_viewport_rect().size
	var wr := world_rect()
	fit_zoom = minf(vp.x / wr.size.x, vp.y / wr.size.y)
	min_zoom = vp.x / wr.size.x * 0.98
	max_zoom = 36.0
	zoom = clampf(zoom, min_zoom, max_zoom)
	_apply()


func reset_camera() -> void:
	var wr := world_rect()
	cam_pos = wr.get_center() + Vector2(0, wr.size.y * 0.04)
	zoom = min_zoom
	_apply()


func world_to_screen(p: Vector2) -> Vector2:
	return (p - cam_pos) * zoom + get_viewport_rect().size * 0.5


func screen_to_world(s: Vector2) -> Vector2:
	return (s - get_viewport_rect().size * 0.5) / zoom + cam_pos


func visible_world_rect() -> Rect2:
	var half := get_viewport_rect().size * 0.5 / zoom
	return Rect2(cam_pos - half, half * 2.0)


func _clamp_camera() -> void:
	var wr := world_rect()
	var half := get_viewport_rect().size * 0.5 / zoom
	# harita ekranı tamamen terk etmesin: merkez, harita sınırı içinde kalsın (yarım ekran payı)
	var lo := wr.position + Vector2(minf(half.x, wr.size.x * 0.5), minf(half.y, wr.size.y * 0.5)) * 0.35
	var hi := wr.end - Vector2(minf(half.x, wr.size.x * 0.5), minf(half.y, wr.size.y * 0.5)) * 0.35
	cam_pos.x = clampf(cam_pos.x, lo.x, hi.x)
	cam_pos.y = clampf(cam_pos.y, lo.y, hi.y)


func _apply() -> void:
	if world == null:
		return
	_clamp_camera()
	var vp := get_viewport_rect().size
	world.scale = Vector2(zoom, zoom)
	world.position = vp * 0.5 - cam_pos * zoom
	fill_mat.set_shader_parameter("zoom", zoom)
	border_mat.set_shader_parameter("zoom", zoom)
	for m in glow_mats:
		m.set_shader_parameter("zoom", zoom)
	hud.queue_redraw()


func zoom_at(screen_pos: Vector2, factor: float) -> void:
	var old := zoom
	var nz := clampf(old * factor, min_zoom, max_zoom)
	if is_equal_approx(nz, old):
		return
	var before := screen_to_world(screen_pos)
	zoom = nz
	cam_pos = before - (screen_pos - get_viewport_rect().size * 0.5) / zoom
	_apply()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func animate_to(target_pos: Vector2, target_zoom: float, dur: float = 0.55) -> void:
	_kill_tween()
	var p0 := cam_pos
	var z0 := zoom
	var z1 := clampf(target_zoom, min_zoom, max_zoom)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(t: float):
		# yakınlaştırma logaritmik, konum doğrusal
		zoom = z0 * pow(z1 / z0, t)
		cam_pos = p0.lerp(target_pos, t)
		_apply(), 0.0, 1.0, dur)


## Eyaleti, arayüzün kapladığı alanı hesaba katarak ekranın ortasına getirir.
func focus_province(pid: int, target_zoom: float = -1.0) -> void:
	var z := target_zoom if target_zoom > 0.0 else maxf(zoom, 3.0)
	z = clampf(z, min_zoom, max_zoom)
	var p = gs.provinces[pid]
	animate_to(_center_offset(p.label_pos, z), z)


func _center_offset(wp: Vector2, z: float) -> Vector2:
	# arayüz payı: görünür alanın merkezi (insets) ile ekran merkezi arasındaki fark
	var shift := Vector2((ui_insets.x - ui_insets.z) * 0.5, (ui_insets.y - ui_insets.w) * 0.5)
	return wp - shift / z


func focus_rect(r: Rect2, pad: float = 0.75) -> void:
	var vp := get_viewport_rect().size
	var avail := Vector2(vp.x - ui_insets.x - ui_insets.z, vp.y - ui_insets.y - ui_insets.w)
	var z := minf(avail.x * pad / maxf(r.size.x, 1.0), avail.y * pad / maxf(r.size.y, 1.0))
	z = clampf(z, min_zoom, 9.0)
	animate_to(_center_offset(r.get_center(), z), z)


func focus_country(cid: int) -> void:
	var lab = country_labels.get(cid)
	var rect := Rect2()
	var first := true
	var best_lm := -1
	var best_a := -1.0
	var area_by_lm: Dictionary = {}
	for p in gs.provinces:
		if p.owner == cid:
			area_by_lm[p.landmass] = area_by_lm.get(p.landmass, 0.0) + float(p.area_km2)
	for lm in area_by_lm:
		if area_by_lm[lm] > best_a:
			best_a = area_by_lm[lm]
			best_lm = lm
	for p in gs.provinces:
		if p.owner == cid and p.landmass == best_lm:
			if first:
				rect = p.bbox
				first = false
			else:
				rect = rect.merge(p.bbox)
	if first:
		return
	focus_rect(rect.grow(10.0), 0.7)


# ------------------------------------------------------------------ döngü

func _process(delta: float) -> void:
	anim_time += delta
	if gs == null:
		return
	var redraw := false
	if not _dirty_provs.is_empty():
		for pid in _dirty_provs.keys():
			_write_lut(gs.provinces[pid])
		_dirty_provs.clear()
		_lut_tex.update(_lut_img)
		redraw = true
	if _labels_dirty:
		_labels_dirty = false
		_recompute_country_labels()
		redraw = true
	if _vel.length() > 12.0 and not _dragging:
		cam_pos -= _vel * delta / zoom
		_vel *= pow(0.04, delta)
		_apply()
	if not pulses.is_empty():
		for pl in pulses:
			pl.t += delta * 1.5
		pulses = pulses.filter(func(pl): return pl.t < 1.0)
		redraw = true
	if not army_anim.is_empty():
		for k in army_anim.keys():
			army_anim[k].t += delta * 2.2
			if army_anim[k].t >= 1.0:
				army_anim.erase(k)
		redraw = true
	if selected_prov >= 0 or selected_army != null:
		redraw = true    # seçili eyalet nabzı
	if redraw:
		hud.queue_redraw()


## AoC / HoI4 tarzı ülke yazısı: ülkenin en büyük kara parçasının asal ekseni boyunca,
## hafif eğimli ve ülkenin boyuna sığacak büyüklükte. Sığmıyorsa HUD hiç çizmez.
func _recompute_country_labels() -> void:
	# ülkenin kara ile bağlı parçalarını bul (aynı sahip + komşu), en büyüğüne yaz
	var comp: Dictionary = {}          # pid -> bileşen no
	var acc: Dictionary = {}           # bileşen no -> {...}
	var next_id := 0
	for p0 in gs.provinces:
		if p0.owner < 0 or comp.has(p0.id):
			continue
		var e = {"area": 0.0, "pos": Vector2.ZERO, "pids": [], "owner": p0.owner}
		acc[next_id] = e
		var stack: Array = [p0.id]
		comp[p0.id] = next_id
		while not stack.is_empty():
			var pid: int = stack.pop_back()
			var p = gs.provinces[pid]
			var w := float(p.area_km2) + 1.0
			e.area += w
			e.pos += p.label_pos * w
			e.pids.append(pid)
			for nb in p.neighbors:
				if not comp.has(nb) and gs.provinces[nb].owner == p0.owner:
					comp[nb] = next_id
					stack.append(nb)
		next_id += 1
	var best: Dictionary = {}
	for k in acc:
		var cid: int = acc[k].owner
		if not best.has(cid) or acc[k].area > best[cid].area:
			best[cid] = acc[k]
	country_labels.clear()
	for cid in best:
		var e2 = best[cid]
		var pos: Vector2 = e2.pos / e2.area
		var inside := false
		var pid_in: int = wd.province_at(gs, pos, 0.0)
		if pid_in >= 0 and gs.provinces[pid_in].owner == cid:
			inside = true
		if not inside:
			var bd := 1e18
			for pid in e2.pids:
				var d: float = gs.provinces[pid].label_pos.distance_squared_to(pos)
				if d < bd:
					bd = d
					pos = gs.provinces[pid].label_pos
		# kenar noktalarından örnekle (şekil tabanlı eksen)
		var pts := PackedVector2Array()
		for pid in e2.pids:
			for ring in gs.provinces[pid].rings:
				var step := maxi(1, ring.size() / 20)
				var i := 0
				while i < ring.size():
					pts.append(ring[i])
					i += step
		country_labels[cid] = _fit_label(pts, pos)


func _fit_label(pts: PackedVector2Array, pos: Vector2) -> Dictionary:
	var out := {"pos": pos, "ang": 0.0, "len": 8.0, "th": 4.0, "bend": 0.0, "w": 8.0}
	if pts.size() < 3:
		return out
	var mean := Vector2.ZERO
	for v in pts:
		mean += v
	mean /= float(pts.size())
	var cxx := 0.0
	var cxy := 0.0
	var cyy := 0.0
	for v in pts:
		var d := v - mean
		cxx += d.x * d.x
		cxy += d.x * d.y
		cyy += d.y * d.y
	var ang := 0.5 * atan2(2.0 * cxy, cxx - cyy)
	var tr := cxx + cyy
	var disc := sqrt(maxf((cxx - cyy) * (cxx - cyy) * 0.25 + cxy * cxy, 0.0))
	var l1 := tr * 0.5 + disc
	var l2 := maxf(tr * 0.5 - disc, 1e-6)
	if sqrt(l1 / l2) < 1.35:
		ang = 0.0                       # yuvarlak ülke: düz yaz
	ang = clampf(ang, -deg_to_rad(52.0), deg_to_rad(52.0))
	var ax := Vector2(cos(ang), sin(ang))
	var ay := Vector2(-sin(ang), cos(ang))
	var pu := pos.dot(ax)
	var pv := pos.dot(ay)
	var umin := 1e18
	var umax := -1e18
	for v in pts:
		var u := v.dot(ax)
		umin = minf(umin, u)
		umax = maxf(umax, u)
	var ln := 2.0 * minf(pu - umin, umax - pu) * 0.94
	ln = maxf(ln, (umax - umin) * 0.35)
	ln = minf(ln, umax - umin)
	# merkez çevresindeki şeritte dikey genişlik
	var vmin := 1e18
	var vmax := -1e18
	for v in pts:
		if absf(v.dot(ax) - pu) < ln * 0.3:
			var vv := v.dot(ay)
			vmin = minf(vmin, vv)
			vmax = maxf(vmax, vv)
	if vmax < vmin:
		vmin = pv - 2.0
		vmax = pv + 2.0
	pv = lerpf(pv, (vmin + vmax) * 0.5, 0.6)
	var th := 2.0 * minf(pv - vmin, vmax - pv)
	th = maxf(th, (vmax - vmin) * 0.45)
	# eğim: sol/orta/sağ şeritlerin orta çizgisi
	var mids: Array = []
	for k in 3:
		var u0 := pu + (float(k) - 1.0) * ln * 0.4
		var lo := 1e18
		var hi := -1e18
		for v in pts:
			if absf(v.dot(ax) - u0) < ln * 0.12:
				var vv2 := v.dot(ay)
				lo = minf(lo, vv2)
				hi = maxf(hi, vv2)
		mids.append((lo + hi) * 0.5 if hi >= lo else pv)
	var bend: float = ((float(mids[0]) + float(mids[2])) * 0.5 - float(mids[1])) * 1.5
	bend = clampf(bend, -th * 0.35, th * 0.35)
	out.pos = ax * pu + ay * pv
	out.ang = ang
	out.len = ln
	out.th = th
	out.bend = bend
	out.w = ln
	return out


# ------------------------------------------------------------------ giriş

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or gs == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() >= 2:
				var pts: Array = _touches.values()
				_pinch_dist = (pts[0] as Vector2).distance_to(pts[1])
				_suppress_tap = true
				_vel = Vector2.ZERO
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 2:
			var pts2: Array = _touches.values()
			var d: float = (pts2[0] as Vector2).distance_to(pts2[1])
			var mid: Vector2 = ((pts2[0] as Vector2) + (pts2[1] as Vector2)) * 0.5
			if _pinch_dist > 1.0:
				zoom_at(mid, d / _pinch_dist)
			_pinch_dist = d
	elif event is InputEventMagnifyGesture:
		zoom_at(event.position, event.factor)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(event.position, 1.18)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(event.position, 1.0 / 1.18)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_moved = false
				_vel = Vector2.ZERO
				_press_pos = event.position
				_kill_tween()
				if _touches.size() < 2:
					_suppress_tap = false
			else:
				if _dragging and not _moved and not _suppress_tap:
					_handle_tap(event.position)
				_dragging = false
	elif event is InputEventMouseMotion:
		if _dragging and _touches.size() < 2 and not _suppress_tap:
			if not _moved and _press_pos.distance_to(event.position) > 12.0:
				_moved = true
			if _moved:
				cam_pos -= event.relative / zoom
				var dt := maxf(get_process_delta_time(), 0.001)
				_vel = _vel.lerp(event.relative / dt, 0.35)
				_apply()


func _handle_tap(screen_pos: Vector2) -> void:
	if hud != null:
		var cid: String = hud.choke_at(screen_pos)
		if cid != "":
			choke_tapped.emit(cid)
			return
	var wp := screen_to_world(screen_pos)
	var pid: int = wd.province_at(gs, wp, 18.0 / zoom)
	tapped.emit(pid)
