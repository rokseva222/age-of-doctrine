extends Control
const Loc = preload("res://scripts/loc.gd")
## Haritanın ekran-uzayı katmanı: ülke/eyalet adları, ordu rozetleri, yollar, kuşatma çubukları, seçim çerçevesi.
## Ekran koordinatlarında çizildiği için yazılar ve çizgiler her yakınlaştırmada net kalır.

const TK = preload("res://scripts/theme_kit.gd")
const Macro = preload("res://scripts/macro.gd")
const Flags = preload("res://scripts/flags.gd")
const Icons = preload("res://scripts/icons.gd")
const Chokepoints = preload("res://scripts/chokepoints.gd")
const Districts = preload("res://scripts/districts.gd")

var map = null
var fast := false            # kamera hareket ederken: yazı çizgileri (outline) atlanır, durunca tam çizilir
var top: Control = null      # her karede yenilenen hafif üst katman (seçim nabzı)
var sel_army_rect := Rect2()
var show_country_names := true
var show_province_names := true
var show_armies := true
var show_chokes := true
const CHOKE_R := 13.0
const NAME_ALPHA := 0.5          # ülke adları yarı saydam: harita renkleri üstünden okunur
const PROV_ALPHA := 0.8


static func tw_char(font: Font, ch: String, fs: float) -> float:
	return font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x * fs / 48.0

var _banner_cache: Dictionary = {}


func _ready() -> void:
	top = TopLayer.new()
	top.hud = self
	top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)


## Seçim çerçevesi ve seçili ordu nabzı: sadece bu küçük katman her karede çizilir; ağır HUD yalnızca değişince.
class TopLayer extends Control:
	var hud = null
	func _draw() -> void:
		if hud == null or hud.map == null or hud.map.gs == null:
			return
		if hud.map.selected_prov >= 0:
			hud._draw_selection(hud.map.gs, hud.map.selected_prov, self)
		if hud.map.selected_army != null and hud.sel_army_rect.size.x > 0.0:
			var pulse := 0.5 + 0.5 * sin(hud.map.anim_time * 6.0)
			draw_rect(hud.sel_army_rect.grow(4.0 + pulse * 2.0), Color(TK.PAPER.r, TK.PAPER.g, TK.PAPER.b, 0.9), false, 2.0)


func _gs():
	return map.gs if map != null else null


func _banner_box(col: Color, thick: float) -> StyleBoxFlat:
	var key := "%s_%s" % [col.to_html(), thick]
	if _banner_cache.has(key):
		return _banner_cache[key]
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.078, 0.094, 0.118, 0.96)
	s.border_color = col
	s.set_border_width_all(int(thick))
	s.set_corner_radius_all(2)
	s.anti_aliasing = true
	_banner_cache[key] = s
	return s


func _draw() -> void:
	var gs = _gs()
	if gs == null or map.wd == null:
		return
	var z: float = map.zoom
	var vp := get_viewport_rect().size
	var screen := Rect2(Vector2.ZERO, vp).grow(60.0)
	var font_b: Font = TK.map_font(true)
	var font_m: Font = TK.map_font(false)

	# --- deniz bağlantıları
	if z >= 1.0:
		for p in gs.provinces:
			for nb in p.sea_links:
				if nb > p.id:
					var a: Vector2 = map.world_to_screen(p.label_pos)
					var b: Vector2 = map.world_to_screen(gs.provinces[nb].label_pos)
					if screen.has_point(a) or screen.has_point(b):
						var related: bool = p.id == map.selected_prov or nb == map.selected_prov
						draw_dashed_line(a, b, Color(1, 1, 1, 0.55 if related else 0.18), 1.6 if related else 1.0, 7.0)

	# --- ülke adları
	if show_country_names:
		_draw_country_names(gs, z, screen, font_b)

	# --- eyalet adları
	if show_province_names and z >= 2.6:
		_draw_province_names(gs, z, screen, font_m)

	# --- Bağımsızlık Yolu: seçilen şehirlerin ilçeleri
	if Districts.active(gs):
		_draw_districts(gs, z, screen, font_m)

	# --- başkent ve küçük devlet işaretleri
	_draw_markers(gs, z, screen)

	# --- stratejik geçit işaretleri
	if show_chokes:
		_draw_chokes(gs, screen)

	# --- kuşatma çubukları
	for p in gs.provinces:
		if p.siege > 0 and p.siege_by >= 0:
			var sp: Vector2 = map.world_to_screen(p.label_pos)
			if not screen.has_point(sp):
				continue
			var need: int = maxi(p.siege_needed(), 1)
			var fr := clampf(float(p.siege) / float(need), 0.0, 1.0)
			var w := 34.0
			var r := Rect2(sp + Vector2(-w * 0.5, 14), Vector2(w, 6))
			draw_rect(r.grow(1.5), Color(0, 0, 0, 0.75))
			draw_rect(r, Color(0.2, 0.2, 0.25))
			draw_rect(Rect2(r.position, Vector2(w * fr, 6)), gs.countries[p.siege_by].color.lightened(0.15))

	sel_army_rect = Rect2()
	if top != null:
		top.queue_redraw()

	# --- emir yolları
	_draw_paths(gs)

	# --- ordular
	if show_armies:
		_draw_armies(gs, z, screen, font_b)

	# --- fetih nabızları
	for pl in map.pulses:
		var sp2: Vector2 = map.world_to_screen(pl.pos)
		var t: float = pl.t
		var col: Color = pl.col
		draw_arc(sp2, 10.0 + t * 46.0, 0.0, TAU, 40, Color(col.r, col.g, col.b, (1.0 - t) * 0.9), 3.0 * (1.0 - t) + 1.0, true)
		draw_arc(sp2, 4.0 + t * 24.0, 0.0, TAU, 32, Color(1, 1, 1, (1.0 - t) * 0.6), 2.0, true)


func _label(text: String, pos: Vector2, size: int, font: Font, col: Color, outline: float = 4.0, align := HORIZONTAL_ALIGNMENT_CENTER) -> Rect2:
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var p := pos - Vector2(ts.x * 0.5, -ts.y * 0.3)
	if not fast:
		draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, int(outline), Color(0.02, 0.06, 0.12, 0.85))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return Rect2(pos - ts * 0.5, ts)


## Ülke adları: ülkenin ekrandaki boyuna göre ölçeklenir, eğimli/aralıklı yazılır (AoC & HoI4 tarzı).
## Sığmayan (küçük ya da uzaktaki) ülkelerin adı çizilmez; yakınlaştıkça belirir.
func _draw_country_names(gs, z: float, screen: Rect2, font: Font) -> void:
	var items: Array = []
	for cid in map.country_labels:
		var c = gs.countries[cid]
		if not c.alive:
			continue
		var lab = map.country_labels[cid]
		items.append([cid, lab.len * lab.th])
	items.sort_custom(func(a, b): return a[1] > b[1])
	var hi_alpha := lerpf(1.0, 0.3, clampf((z - 2.8) / 1.8, 0.0, 1.0))
	var placed: Array = []
	var REF := 48
	for it in items:
		var c2 = gs.countries[it[0]]
		var lab2 = map.country_labels[it[0]]
		var sp: Vector2 = map.world_to_screen(lab2.pos)
		var Ls: float = lab2.len * z
		var Ts: float = lab2.th * z
		if Ls < 24.0 or not screen.grow(Ls).has_point(sp):
			continue
		var name: String = TK.up(Loc.map_name(c2.name, c2.name_en))
		var n := name.length()
		var tw1: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, REF).x / float(REF)
		var fs := minf(minf(Ts * 0.40, Ls * 0.68 / maxf(tw1, 0.1)), 44.0)
		if fs < 9.5:
			continue
		var a := clampf((fs - 9.5) / 4.0, 0.0, 1.0) * hi_alpha * NAME_ALPHA
		# yazı boyutu 2'şer pikselle sabitlenir, kalan oran GPU ölçeğiyle uygulanır: yakınlaşırken titreme/sıçrama olmaz
		var fsq := maxi(10, int(round(fs / 2.0)) * 2)
		var sc := fs / float(fsq)
		var nat := tw1 * fs
		var track := 0.0
		if n > 1 and nat < Ls * 0.55:
			track = clampf((Ls * 0.62 - nat) / float(n - 1), fs * 0.04, fs * 0.22)
		var total := nat + track * float(n - 1)
		var half := Vector2(total * 0.5, fs * 0.6)
		var cs := cos(lab2.ang)
		var sn := sin(lab2.ang)
		var ex := absf(half.x * cs) + absf(half.y * sn)
		var ey := absf(half.x * sn) + absf(half.y * cs) + absf(lab2.bend * z * 0.5)
		var rect := Rect2(sp - Vector2(ex, ey), Vector2(ex, ey) * 2.0).grow(3.0)
		var clash := false
		for r in placed:
			if r.intersects(rect):
				clash = true
				break
		if clash:
			continue
		placed.append(rect)
		var lc: Array = TK.label_colors(c2.color, a)
		var fcol: Color = lc[0]
		var ocol: Color = lc[1]
		var ow := int(clampf(fs * 0.07, 1.0, 3.0))
		ocol.a *= 0.55
		var bend_s: float = lab2.bend * z * 0.5
		if track < 1.0 and absf(bend_s) < fs * 0.08:
			draw_set_transform(sp, lab2.ang, Vector2(sc, sc))
			var p0 := Vector2(-total * 0.5, fs * 0.34) / sc
			if not fast:
				draw_string_outline(font, p0, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsq, ow, ocol)
			draw_string(font, p0, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsq, fcol)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		var u := -total * 0.5
		var ax := Vector2(cs, sn)
		var ay := Vector2(-sn, cs)
		for i in n:
			var ch := name.substr(i, 1)
			var cw: float = tw_char(font, ch, fs)
			var uc := u + cw * 0.5
			var t := 2.0 * uc / maxf(Ls, 1.0)
			var vc := bend_s * t * t
			var slope := bend_s * 8.0 * uc / maxf(Ls * Ls, 1.0)
			var cp := sp + ax * uc + ay * vc
			draw_set_transform(cp, lab2.ang + atan(slope), Vector2(sc, sc))
			var pc := Vector2(-cw * 0.5, fs * 0.34) / sc
			if not fast:
				draw_string_outline(font, pc, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsq, ow, ocol)
			draw_string(font, pc, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fsq, fcol)
			u += cw + track
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## İlçe hücreleri: merkez elindeki ilçeler kırmızımsı, hareketin elindekiler hareketin renginde. Şehir yeterince büyükken görünür.
func _draw_districts(gs, z: float, screen: Rect2, font: Font) -> void:
	var me: Color = gs.countries[gs.player].color
	for pid in Districts.pids(gs):
		var p = gs.provinces[pid]
		var sp: Vector2 = map.world_to_screen(p.label_pos)
		var rpx: float = p.label_r * z
		if not screen.grow(200.0).has_point(sp) or rpx < 14.0:
			continue
		var list: Array = gs.indep.dist[str(pid)]
		var cs: Array = Districts.cells(gs, pid)
		var fade: float = clampf((rpx - 14.0) / 30.0, 0.0, 1.0)
		for i in cs.size():
			var held: bool = int(list[i].st) == 1
			var fillc: Color = Color(me.r, me.g, me.b, 0.55 * fade) if held else Color(0.55, 0.12, 0.12, 0.20 * fade)
			for poly in cs[i]:
				var pts := PackedVector2Array()
				for q in poly:
					pts.append(map.world_to_screen(q))
				if pts.size() < 3:
					continue
				draw_colored_polygon(pts, fillc)
				var closed := PackedVector2Array(pts)
				closed.append(pts[0])
				draw_polyline(closed, Color(1, 1, 1, 0.55 * fade), 1.4, true)
		# adlar: sığıyorsa
		if rpx >= 40.0:
			for i in cs.size():
				var best: PackedVector2Array = PackedVector2Array()
				var ba := -1.0
				for poly in cs[i]:
					var bb := Rect2((poly as PackedVector2Array)[0], Vector2.ZERO)
					for q in poly:
						bb = bb.expand(q)
					if bb.size.x * bb.size.y > ba:
						ba = bb.size.x * bb.size.y
						best = poly
				if best.size() < 3:
					continue
				var bbw := Rect2(best[0], Vector2.ZERO)
				for q in best:
					bbw = bbw.expand(q)
				var c2: Vector2 = map.world_to_screen(bbw.get_center())
				var nm: String = Districts.name_of(gs, pid, i)
				var fs := 12 if bbw.size.x * z < 90.0 else 15
				var ts := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				if ts.x > bbw.size.x * z * 1.05 or ts.y > bbw.size.y * z:
					continue
				var held2: bool = int(list[i].st) == 1
				_label(nm, c2, fs, font, Color(1, 1, 1, 0.95 * fade) if held2 else Color(1, 0.86, 0.82, 0.85 * fade), 3.0)


func _draw_province_names(gs, z: float, screen: Rect2, font: Font) -> void:
	var alpha := clampf((z - 2.6) / 1.2, 0.0, 1.0) * PROV_ALPHA
	var placed: Array = []
	for p in gs.provinces:
		var rpx: float = p.label_r * z
		if rpx < 20.0:
			continue
		var sp: Vector2 = map.world_to_screen(p.label_pos)
		if not screen.has_point(sp):
			continue
		var fs := int(clampf(rpx * 0.36, 12.0, 26.0))
		var ts := font.get_string_size(p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		if ts.x > rpx * 2.6:
			continue
		var rect := Rect2(sp - ts * 0.5, ts).grow(2.0)
		var clash := false
		for r in placed:
			if r.intersects(rect):
				clash = true
				break
		if clash:
			continue
		placed.append(rect)
		var pp := sp - Vector2(ts.x * 0.5, -ts.y * 0.3) - Vector2(0, 7)
		var pc: Array = TK.label_colors(gs.countries[p.owner].color, alpha)
		if not fast:
			draw_string_outline(font, pp, p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, pc[1])
		draw_string(font, pp, p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, pc[0])


func _draw_markers(gs, z: float, screen: Rect2) -> void:
	# küçük devletler (kara parçası ekranda görünmeyecek kadar küçük)
	for c in gs.countries:
		if not c.alive or c.is_rebel or c.total_area <= 0 or c.total_area > 30000:
			continue
		if c.capital < 0:
			continue
		var p = gs.provinces[c.capital]
		if p.owner != c.id:
			continue
		var sp: Vector2 = map.world_to_screen(p.label_pos)
		if not screen.has_point(sp):
			continue
		var rpx: float = p.label_r * z
		if rpx > 9.0:
			continue
		draw_circle(sp, 6.0, Color(1, 1, 1, 0.95))
		draw_circle(sp, 4.4, c.color)
	# başkentler
	if z >= 2.0:
		for c2 in gs.countries:
			if not c2.alive or c2.capital < 0:
				continue
			var p2 = gs.provinces[c2.capital]
			if p2.owner != c2.id and p2.owner >= 0:
				pass
			var sp2: Vector2 = map.world_to_screen(p2.label_pos)
			if not screen.has_point(sp2):
				continue
			if p2.label_r * z < 14.0:
				continue
			Icons.draw(self, "star", Rect2(sp2 + Vector2(-8, -26), Vector2(16, 16)), TK.PAPER, 2.4)


## Geçit işaretinin ekrandaki yeri (-Vector2.INF: görünmez)
func _choke_pos(gs, id: String) -> Vector2:
	var d: Dictionary = Chokepoints.def_of(id)
	if d.is_empty():
		return Vector2(-1e9, -1e9)
	var pid: int = int(d.prov[0])
	if pid < 0 or pid >= gs.provinces.size():
		return Vector2(-1e9, -1e9)
	return map.world_to_screen(gs.provinces[pid].label_pos)


## Dokunulan geçidin kimliği ("" = yok)
func choke_at(screen_pos: Vector2) -> String:
	var gs = _gs()
	if gs == null or not show_chokes or gs.player < 0 or not (gs.chokes is Dictionary) or gs.chokes.is_empty():
		return ""
	var best := ""
	var bd := (CHOKE_R + 10.0) * (CHOKE_R + 10.0)
	for id in Chokepoints.ids():
		var d2: float = _choke_pos(gs, id).distance_squared_to(screen_pos)
		if d2 < bd:
			bd = d2
			best = id
	return best


func _choke_icon_name(id: String, mode: String) -> String:
	match mode:
		"toll":
			return Icons.pick("toll_gate", "")
		"enemy", "all":
			return Icons.pick("strait_closed", "")
	if id == "suez" or id == "panama":
		return Icons.pick("canal", Icons.pick("strait", ""))
	return Icons.pick("strait", "")


func _draw_chokes(gs, screen: Rect2) -> void:
	if gs.player < 0 or not (gs.chokes is Dictionary):
		return
	Chokepoints.ensure(gs)
	for id in Chokepoints.ids():
		var sp: Vector2 = _choke_pos(gs, id)
		if not screen.has_point(sp):
			continue
		var st: Dictionary = gs.chokes[id]
		var ctrl: int = int(st.get("ctrl", -1))
		var mode: String = String(st.get("mode", "open"))
		var ring := Color(0.62, 0.66, 0.72)
		if ctrl == gs.player:
			ring = Color(0.35, 0.85, 0.45)
		elif ctrl >= 0 and (gs.at_war(ctrl, gs.player) or gs.countries[ctrl].embargo.has(gs.player)):
			ring = Color(0.95, 0.32, 0.3)
		elif ctrl >= 0 and gs.is_allied(ctrl, gs.player):
			ring = Color(0.45, 0.7, 0.95)
		var r := CHOKE_R
		draw_circle(sp, r + 3.0, Color(0, 0, 0, 0.55))
		draw_circle(sp, r + 1.5, ring)
		draw_circle(sp, r - 1.5, Color(0.07, 0.1, 0.15, 0.96))
		var nm: String = _choke_icon_name(id, mode)
		if nm != "":
			Icons.draw(self, nm, Rect2(sp - Vector2(r - 3.0, r - 3.0), Vector2((r - 3.0) * 2.0, (r - 3.0) * 2.0)), Color.WHITE, 2.0)
			continue
		# yedek çizim: dalga çizgileri + mod simgesi
		var wc := Color(0.55, 0.8, 1.0)
		match mode:
			"toll":
				draw_circle(sp, 6.0, Color(0.95, 0.78, 0.25))
				draw_arc(sp, 6.0, 0.0, TAU, 20, Color(0.55, 0.38, 0.05), 1.4, true)
				draw_line(sp + Vector2(0, -3), sp + Vector2(0, 3), Color(0.55, 0.38, 0.05), 1.6, true)
			"enemy":
				draw_line(sp + Vector2(-6, 0), sp + Vector2(6, 0), wc, 1.6, true)
				draw_line(sp + Vector2(-6, -6), sp + Vector2(6, 6), Color(0.95, 0.32, 0.3), 2.6, true)
			"all":
				draw_line(sp + Vector2(-6, -6), sp + Vector2(6, 6), Color(0.95, 0.32, 0.3), 2.6, true)
				draw_line(sp + Vector2(-6, 6), sp + Vector2(6, -6), Color(0.95, 0.32, 0.3), 2.6, true)
			_:
				for k in [-4.0, 0.0, 4.0]:
					var pts := PackedVector2Array()
					for i in range(9):
						var x := -6.0 + float(i) * 1.5
						pts.append(sp + Vector2(x, float(k) + sin(float(i) * 1.4) * 1.3))
					draw_polyline(pts, wc, 1.5, true)


func _draw_selection(gs, pid: int, cv: CanvasItem) -> void:
	var p = gs.provinces[pid]
	var pulse := 0.5 + 0.5 * sin(map.anim_time * 4.0)
	for ring in p.rings:
		var pts := PackedVector2Array()
		for v in ring:
			pts.append(map.world_to_screen(v))
		if pts.size() < 3:
			continue
		pts.append(pts[0])
		cv.draw_polyline(pts, Color(0.03, 0.04, 0.06, 0.8), 6.0, true)
		cv.draw_polyline(pts, Color(TK.PAPER.r, TK.PAPER.g, TK.PAPER.b, 0.85 + 0.15 * pulse), 3.0, true)


func _draw_paths(gs) -> void:
	for a in gs.armies.values():
		var route: Array = a.sp_path if a.sp_size > 0 else a.path
		if route.is_empty():
			continue
		if a.owner != gs.player and a != map.selected_army:
			continue
		var pts := PackedVector2Array()
		pts.append(map.world_to_screen(gs.provinces[a.prov].label_pos))
		for pid in route:
			pts.append(map.world_to_screen(gs.provinces[pid].label_pos))
		var col := Color(TK.PAPER.r, TK.PAPER.g, TK.PAPER.b, 0.95) if a == map.selected_army else Color(1, 1, 1, 0.75)
		for i in pts.size() - 1:
			draw_dashed_line(pts[i], pts[i + 1], Color(0, 0, 0, 0.5), 5.0, 9.0)
			draw_dashed_line(pts[i], pts[i + 1], col, 3.0, 9.0)
		# ok ucu
		var last := pts[pts.size() - 1]
		var prev := pts[pts.size() - 2]
		var d := (last - prev).normalized()
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([last + d * 4, last - d * 12 + n * 8, last - d * 12 - n * 8]), col)


func _draw_armies(gs, z: float, screen: Rect2, font: Font) -> void:
	var me: int = gs.player
	var show_all := z >= 7.0
	var tiny := z < 1.25
	var sc := clampf(z / 2.6, 0.72, 1.0)
	for a in gs.armies.values():
		var near := false
		var hostile := false
		if a.owner == me:
			near = true
		elif me >= 0 and gs.at_war(me, a.owner):
			near = true
			hostile = true
		elif me >= 0 and gs.is_allied(me, a.owner):
			near = true
		if not near and not show_all:
			continue
		var wp: Vector2 = gs.provinces[a.prov].label_pos
		var anim = map.army_anim.get(a.id)
		if anim != null:
			var t: float = clampf(anim.t, 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			wp = anim.from.lerp(anim.to, t)
		var sp: Vector2 = map.world_to_screen(wp)
		if not screen.has_point(sp):
			continue
		var c = gs.countries[a.owner]
		if tiny:
			var rad := 4.0 + minf(sqrt(float(a.size) / 1000.0) * 0.9, 12.0)
			var ring_col := TK.PAPER if a.owner == me else (TK.RED if hostile else Color(1, 1, 1))
			draw_circle(sp, rad + 1.8, ring_col)
			draw_circle(sp, rad, c.color.darkened(0.1))
			continue
		var txt := Macro.compact(a.size)
		var font2: Font = TK.mono(true, 0)
		var fs := int(round(16.0 * sc))
		var ts := font2.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var fw := 20.0 * sc
		var fh := 14.0 * sc
		var w := fw + ts.x + 17.0 * sc
		var h := 26.0 * sc
		var rect := Rect2(sp - Vector2(w * 0.5, h * 0.5 + 2), Vector2(w, h))
		var edge: Color = TK.PAPER if a.owner == me else (TK.RED if hostile else c.color.lightened(0.1))
		var thick := 2.0 if a.owner == me else 1.5
		draw_style_box(_banner_box(edge, thick), rect)
		Flags.draw(self, Rect2(rect.position + Vector2(5 * sc, (h - fh) * 0.5), Vector2(fw, fh)), c)
		draw_string(font2, rect.position + Vector2(fw + 10 * sc, h * 0.5 + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		if a == map.selected_army:
			sel_army_rect = rect
		if (not a.path.is_empty() or a.sp_size > 0) and a.owner == me:
			Icons.draw(self, "chev_r", Rect2(rect.end + Vector2(-2, -22), Vector2(14, 14)), TK.PAPER, 3.0)
