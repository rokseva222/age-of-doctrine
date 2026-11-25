extends RefCounted
## Yönlü kılıç düellosu (Warband / Bannerlord tarzı) — 3B sahne, dokunmatik kontrol.
## Kontrol: sol altta 4 siper düğmesi (Sol / Üst / Sağ / Saplama; dokun = o yöne siper, aynısına tekrar dokun = bırak),
## sağ tarafta vuruş alanı: kaydır (sola / yukarı / sağa) ya da dokun (saplama). Vuruş kalkarken ilk yarıda başka yöne
## kaydırırsan yön değişir (aldatma); siper düğmesine basarsan vazgeçersin. Rakibin kılıç duruşundan yönünü oku.
## Klavye: A W D S = siper, ok tuşları = vuruş (sol, yukarı, sağ, aşağı = saplama).
## Kullanım: BladeDuel.open(ui, {title, intro, skill, power, win_text, lose_text, draw_text, yield_text}, func(result, info): ...)
## Sonuç: "win" | "lose" | "draw" | "yield".
## Modeller: assets/duel/knight_player.glb, knight_foe.glb, sword.glb, shield.glb, arena.glb (hepsi isteğe bağlı; yoksa basit şekiller).

const TK = preload("res://scripts/theme_kit.gd")
const Core = preload("res://scripts/blade_duel_core.gd")
const ArmIK = preload("res://scripts/arm_ik.gd")
const DIR_PATH := "res://assets/duel/"

const GUARD_NAMES := ["Sol", "Üst", "Sağ", "Saplama"]

# Duruş tabloları: [tutuş noktası (x sağ, y yukarı, f ileri), kılıç yönü (x, y, f)]; x ekrandaki sağdır, f rakibe doğru.
const FOE_REST := [Vector3(-0.35, 1.15, 0.35), Vector3(-0.15, 1.0, 0.15)]
const FOE_GUARD := [
	[Vector3(-0.40, 1.30, 0.45), Vector3(-0.85, 0.50, 0.15)],
	[Vector3(-0.20, 1.55, 0.40), Vector3(0.0, 1.0, 0.20)],
	[Vector3(-0.05, 1.25, 0.50), Vector3(0.85, 0.50, 0.15)],
	[Vector3(-0.35, 1.00, 0.35), Vector3(0.0, -0.10, 1.0)]]
const FOE_WIND := [
	[Vector3(-0.58, 1.55, 0.15), Vector3(-0.45, 0.85, -0.10)],
	[Vector3(-0.25, 1.95, 0.10), Vector3(0.0, 1.0, -0.25)],
	[Vector3(0.15, 1.50, 0.20), Vector3(0.65, 0.70, -0.10)],
	[Vector3(-0.35, 1.10, -0.05), Vector3(0.0, 0.05, 1.0)]]
const FOE_STRIKE := [
	[Vector3(0.05, 1.25, 0.55), Vector3(0.85, -0.20, 0.45)],
	[Vector3(-0.20, 1.00, 0.60), Vector3(0.0, -0.55, 0.85)],
	[Vector3(-0.55, 1.25, 0.50), Vector3(-0.85, -0.20, 0.45)],
	[Vector3(-0.30, 1.10, 0.70), Vector3(0.0, 0.0, 1.0)]]
const ME_REST := [Vector3(0.35, 1.15, 0.35), Vector3(0.15, 1.0, 0.15)]
const ME_GUARD := [
	[Vector3(0.15, 1.30, 0.50), Vector3(-0.85, 0.50, 0.15)],
	[Vector3(0.25, 1.60, 0.40), Vector3(0.0, 1.0, 0.20)],
	[Vector3(0.50, 1.25, 0.50), Vector3(0.85, 0.50, 0.15)],
	[Vector3(0.30, 1.00, 0.40), Vector3(0.0, -0.10, 1.0)]]
const ME_WIND := [
	[Vector3(0.60, 1.50, 0.15), Vector3(0.45, 0.85, -0.10)],
	[Vector3(0.28, 1.95, 0.10), Vector3(0.0, 1.0, -0.25)],
	[Vector3(-0.10, 1.50, 0.20), Vector3(-0.65, 0.70, -0.10)],
	[Vector3(0.35, 1.10, -0.05), Vector3(0.0, 0.05, 1.0)]]
const ME_STRIKE := [
	[Vector3(-0.05, 1.25, 0.55), Vector3(-0.85, -0.20, 0.45)],
	[Vector3(0.20, 1.00, 0.60), Vector3(0.0, -0.55, 0.85)],
	[Vector3(0.60, 1.25, 0.50), Vector3(0.85, -0.20, 0.45)],
	[Vector3(0.30, 1.10, 0.75), Vector3(0.0, 0.0, 1.0)]]
const CAM_POS := Vector3(1.25, 2.0, 4.1)
const CAM_LOOK := Vector3(-0.15, 1.25, -0.2)
const STAGGER_POSE := [Vector3(0.0, 1.30, 0.0), Vector3(0.3, 1.0, -0.2)]


static func open(ui, spec: Dictionary, cb: Callable) -> void:
	if ui.speed_idx != 0:
		ui.set_speed(0)
		ui.speed_changed.emit(0)
	var ov := View.new()
	ov.setup(ui, spec, cb)
	ui.root.add_child(ov)
	ui.set_modal(ov)


## Bir savaşçının 3B görünümü: gövde (model ya da basit şekil), kılıç düğümü, kol IK'leri.
class Fig extends RefCounted:
	var root: Node3D
	var body: Node3D
	var sword: Node3D
	var skel: Skeleton3D = null
	var ik_r = null
	var ik_l = null
	var is_foe := false
	var fwd := 1.0                 # rakibe doğru dünya Z yönü (rakip +1: kameraya bakar, oyuncu -1)
	var grip := Vector3.ZERO       # şu anki tutuş (x, y, f), yumuşatılmış
	var blade := Vector3.UP
	var struck_t := 0.0
	var last_dir := 1
	var tilt := 0.0

	func world(v: Vector3) -> Vector3:
		return root.global_position + Vector3(v.x, v.y, v.z * fwd)

	func world_dir(v: Vector3) -> Vector3:
		return Vector3(v.x, v.y, v.z * fwd).normalized()


class View extends Control:
	var ui
	var spec: Dictionary
	var cb: Callable
	var core := Core.new()
	var svp: SubViewport
	var cam: Camera3D
	var me := Fig.new()
	var foe := Fig.new()
	var php_bar: ProgressBar
	var fhp_bar: ProgressBar
	var msg_lbl: Label
	var hint_lbl: Label
	var banner_lbl: Label
	var guard_btns: Array = []
	var yield_btn: Button
	var swipe: Control
	var end_box: VBoxContainer
	var yield_armed := false
	var _yield_token := 0
	var finished := false
	var _done := false
	var shake := 0.0
	var _press := Vector2.ZERO
	var _pressing := false
	var _svc: SubViewportContainer
	var _q_time := 0.0
	var _q_frames := 0
	var _q_done := false

	func _input(e: InputEvent) -> void:
		if not (e is InputEventKey) or not e.pressed or e.echo:
			return
		var k: int = e.keycode
		var g := -1
		var a := -1
		if k == KEY_A:
			g = 0
		elif k == KEY_W:
			g = 1
		elif k == KEY_D:
			g = 2
		elif k == KEY_S:
			g = 3
		elif k == KEY_LEFT:
			a = 0
		elif k == KEY_UP:
			a = 1
		elif k == KEY_RIGHT:
			a = 2
		elif k == KEY_DOWN:
			a = 3
		if g >= 0:
			get_viewport().set_input_as_handled()
			_guard(g)
		elif a >= 0:
			get_viewport().set_input_as_handled()
			_attack(a)
		elif k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and finished and end_box.get_child_count() > 0:
			get_viewport().set_input_as_handled()
			(end_box.get_child(0) as Button).emit_signal("pressed")

	func setup(ui_, spec_: Dictionary, cb_: Callable) -> void:
		ui = ui_
		spec = spec_
		cb = cb_
		core.setup(float(spec.get("skill", 0.3)), float(spec.get("power", 1.0)))
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.04, 1.0)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		# 3B sahne tüm ekranı kaplar; kontroller üstüne biner
		var svc := SubViewportContainer.new()
		svc.stretch = true
		svc.set_anchors_preset(Control.PRESET_FULL_RECT)
		svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_svc = svc
		add_child(svc)
		svp = SubViewport.new()
		svp.own_world_3d = true
		svp.msaa_3d = Viewport.MSAA_DISABLED
		svp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		svp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		svc.add_child(svp)
		_build_world()
		_build_ui()
		set_process(true)

	# ------------------------------------------------------------ arayüz
	func _build_ui() -> void:
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 14
		vb.offset_right = -14
		vb.offset_top = 8
		vb.offset_bottom = -10
		vb.add_theme_constant_override("separation", 6)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vb)
		var head := HBoxContainer.new()
		head.layout_direction = Control.LAYOUT_DIRECTION_LTR
		head.add_theme_constant_override("separation", 10)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(head)
		yield_btn = TK.button("Meydanı terk et", "ghost", "", Vector2(300, 64), 13)
		yield_btn.pressed.connect(_yield_pressed)
		head.add_child(yield_btn)
		var title := TK.t(String(spec.get("title", "Düello")), "h3", TK.TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(title)
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(300, 0)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(pad)
		var bars := HBoxContainer.new()
		bars.layout_direction = Control.LAYOUT_DIRECTION_LTR
		bars.add_theme_constant_override("separation", 14)
		bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(bars)
		php_bar = _bar(Color(0.30, 0.65, 0.40))
		fhp_bar = _bar(Color(0.80, 0.30, 0.25))
		bars.add_child(php_bar)
		bars.add_child(fhp_bar)
		hint_lbl = TK.t("", "h1", Color(1.0, 0.35, 0.25))
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_lbl.modulate.a = 0.0
		vb.add_child(hint_lbl)
		var mid := Control.new()
		mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(mid)
		banner_lbl = TK.t(String(spec.get("intro", "Kılıçlar çekildi.")), "bodyb", TK.GOLD)
		banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		banner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mid.add_child(banner_lbl)
		msg_lbl = TK.t("", "small", TK.TEXT)
		msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg_lbl.custom_minimum_size = Vector2(0, 40)
		msg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		msg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(msg_lbl)
		# alt: solda 2x2 siper düğmeleri, sağda vuruş alanı
		var bottom := HBoxContainer.new()
		bottom.layout_direction = Control.LAYOUT_DIRECTION_LTR
		bottom.add_theme_constant_override("separation", 12)
		bottom.custom_minimum_size = Vector2(0, 200)
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(bottom)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.size_flags_stretch_ratio = 1.1
		bottom.add_child(grid)
		for i in 4:
			var idx: int = i
			var b := TK.button("%s  [%s]" % [GUARD_NAMES[i], ["A", "W", "D", "S"][i]], "blue", "shield", Vector2(0, 92), 16)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func(): _guard(idx))
			grid.add_child(b)
			guard_btns.append(b)
		swipe = PanelContainer.new()
		swipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swipe.size_flags_vertical = Control.SIZE_EXPAND_FILL
		swipe.add_theme_stylebox_override("panel", TK.box(Color(0.55, 0.2, 0.18, 0.28), Color(0.85, 0.35, 0.3, 0.8), 2, 12, 0, Vector4(8, 8, 8, 8)))
		swipe.mouse_filter = Control.MOUSE_FILTER_STOP
		swipe.gui_input.connect(_swipe_input)
		var hint := TK.t("VUR\nkaydır: ◄ sola   ▲ üstten   ► sağa\ndokun: saplama", "small", TK.TEXT)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swipe.add_child(hint)
		bottom.add_child(swipe)
		end_box = VBoxContainer.new()
		end_box.visible = false
		vb.add_child(end_box)

	func _bar(col: Color) -> ProgressBar:
		var pb := ProgressBar.new()
		pb.min_value = 0
		pb.max_value = 100
		pb.value = 100
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 16)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		pb.add_theme_stylebox_override("fill", fill)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.1, 0.11, 0.14, 0.85)
		pb.add_theme_stylebox_override("background", bg)
		return pb

	# ------------------------------------------------------------ girdi
	func _guard(d: int) -> void:
		if finished:
			return
		if core.p.state == "wind":
			core.player_feint()            # vuruş sırasında siper düğmesi = vazgeç
			return
		core.player_guard(-1 if core.p.guard == d else d)

	func _attack(d: int) -> void:
		if finished:
			return
		if core.p.state == "wind":
			core.player_redirect(d)
		else:
			core.player_attack(d)

	func _swipe_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press = e.position
				_pressing = true
			elif _pressing:
				_pressing = false
				var d: Vector2 = e.position - _press
				if d.length() < 40.0:
					_attack(3)
				elif absf(d.x) > absf(d.y) * 0.8:
					_attack(0 if d.x < 0.0 else 2)
				elif d.y < 0.0:
					_attack(1)
				else:
					_attack(3)

	# ------------------------------------------------------------ 3B dünya
	func _mat(c: Color, rough: float = 0.8) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		return m

	func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = pos
		mi.material_override = mat
		parent.add_child(mi)
		return mi

	static func _collect_meshes(n: Node, out: Array) -> void:
		if n is MeshInstance3D:
			out.append(n)
		for c in n.get_children():
			_collect_meshes(c, out)

	static func _find_skel(n: Node) -> Skeleton3D:
		if n is Skeleton3D:
			return n
		for c in n.get_children():
			var r: Skeleton3D = _find_skel(c)
			if r != null:
				return r
		return null

	## Modelin yüksekliğini hedefe ölçekler, ayakları zemine oturtur.
	func _normalize(inst: Node3D, height: float) -> void:
		var meshes: Array = []
		_collect_meshes(inst, meshes)
		if meshes.is_empty():
			return
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := Vector3(-1e9, -1e9, -1e9)
		for m in meshes:
			var mi: MeshInstance3D = m
			var ab: AABB = mi.get_aabb()
			var xf: Transform3D = inst.global_transform.affine_inverse() * mi.global_transform
			for i in 8:
				var pt: Vector3 = xf * ab.get_endpoint(i)
				lo = lo.min(pt)
				hi = hi.max(pt)
		var h: float = hi.y - lo.y
		if h < 0.001:
			return
		var sc: float = height / h
		inst.scale *= sc
		inst.position.y -= lo.y * sc

	func _fighter(path: String, col: Color, foe_side: bool) -> Fig:
		var f := Fig.new()
		f.is_foe = foe_side
		f.fwd = 1.0 if foe_side else -1.0
		f.root = Node3D.new()
		var body := Node3D.new()
		f.root.add_child(body)
		f.body = body
		var loaded := false
		if ResourceLoader.exists(path):
			var ps = load(path)
			if ps is PackedScene:
				var inst: Node3D = ps.instantiate()
				body.add_child(inst)
				_normalize(inst, 1.85)
				f.skel = _find_skel(inst)
				if f.skel != null:
					f.ik_r = ArmIK.new()
					if not f.ik_r.setup(f.skel, "right"):
						f.ik_r = null
					f.ik_l = ArmIK.new()
					if not f.ik_l.setup(f.skel, "left"):
						f.ik_l = null
				loaded = true
		if not loaded:
			var cap := CapsuleMesh.new()
			cap.radius = 0.3
			cap.height = 1.5
			_mesh(body, cap, Vector3(0, 0.85, 0), _mat(col))
			var head := SphereMesh.new()
			head.radius = 0.21
			head.height = 0.42
			_mesh(body, head, Vector3(0, 1.82, 0), _mat(col.lightened(0.1)))
		# model yüzü +Z'ye bakar; oyuncu -Z'ye (rakibe) bakmalı
		if not foe_side:
			body.rotation_degrees.y = 180.0
		# kılıç
		var sw := Node3D.new()
		var sp: String = DIR_PATH + "sword.glb"
		var swm_loaded := false
		if ResourceLoader.exists(sp):
			var sps = load(sp)
			if sps is PackedScene:
				var si: Node3D = sps.instantiate()
				sw.add_child(si)
				_fit_sword(si)
				swm_loaded = true
		if not swm_loaded:
			var blade := BoxMesh.new()
			blade.size = Vector3(0.09, 1.0, 0.025)
			_mesh(sw, blade, Vector3(0, 0.55, 0), _mat(Color(0.82, 0.85, 0.9), 0.25))
			var hilt := BoxMesh.new()
			hilt.size = Vector3(0.28, 0.04, 0.05)
			_mesh(sw, hilt, Vector3(0, 0.04, 0), _mat(Color(0.85, 0.68, 0.25)))
			var grp := BoxMesh.new()
			grp.size = Vector3(0.045, 0.2, 0.045)
			_mesh(sw, grp, Vector3(0, -0.08, 0), _mat(Color(0.3, 0.2, 0.12)))
		f.root.add_child(sw)
		f.sword = sw
		var rest: Array = FOE_REST if foe_side else ME_REST
		f.grip = rest[0]
		f.blade = rest[1]
		return f

	## Kılıç modelini +Y'ye uzayacak ve sapı orijinde olacak biçimde hizalar (en uzun eksen bıçak sayılır).
	func _fit_sword(si: Node3D) -> void:
		var meshes: Array = []
		_collect_meshes(si, meshes)
		if meshes.is_empty():
			return
		var ab: AABB = (meshes[0] as MeshInstance3D).get_aabb()
		for i in range(1, meshes.size()):
			ab = ab.merge((meshes[i] as MeshInstance3D).get_aabb())
		var ax := 1
		if ab.size.x >= ab.size.y and ab.size.x >= ab.size.z:
			ax = 0
		elif ab.size.z >= ab.size.y and ab.size.z >= ab.size.x:
			ax = 2
		if ax == 0:
			si.rotation_degrees.z = 90.0
		elif ax == 2:
			si.rotation_degrees.x = -90.0
		var len_: float = maxf(ab.size[ax], 0.01)
		var sc: float = 1.15 / len_
		si.scale = Vector3(sc, sc, sc)
		si.position = Vector3.ZERO

	func _build_world() -> void:
		var world := Node3D.new()
		svp.add_child(world)
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.10, 0.12, 0.20)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.6, 0.57, 0.55)
		env.ambient_light_energy = 0.85
		var we := WorldEnvironment.new()
		we.environment = env
		world.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-48, 28, 0)
		sun.light_energy = 1.1
		world.add_child(sun)
		var ap: String = DIR_PATH + "arena.glb"
		var arena_loaded := false
		if ResourceLoader.exists(ap):
			var aps = load(ap)
			if aps is PackedScene:
				world.add_child(aps.instantiate())
				arena_loaded = true
		if not arena_loaded:
			var plane := PlaneMesh.new()
			plane.size = Vector2(80, 60)
			_mesh(world, plane, Vector3.ZERO, _mat(Color(0.55, 0.45, 0.30)))
			var wall := BoxMesh.new()
			wall.size = Vector3(80, 8, 0.5)
			_mesh(world, wall, Vector3(0, 4, -7.0), _mat(Color(0.36, 0.33, 0.30)))
			for x in [-4.5, -1.5, 1.5, 4.5]:
				var pil := CylinderMesh.new()
				pil.top_radius = 0.28
				pil.bottom_radius = 0.28
				pil.height = 5.0
				_mesh(world, pil, Vector3(x, 2.5, -6.3), _mat(Color(0.45, 0.4, 0.34)))
		foe = _fighter(DIR_PATH + "knight_foe.glb", Color(0.45, 0.10, 0.10), true)
		foe.root.position = Vector3(0, 0, -0.8)
		world.add_child(foe.root)
		me = _fighter(DIR_PATH + "knight_player.glb", Color(0.12, 0.2, 0.34), false)
		me.root.position = Vector3(0.1, 0, 1.7)
		world.add_child(me.root)
		cam = Camera3D.new()
		cam.position = CAM_POS
		world.add_child(cam)
		cam.look_at_from_position(cam.position, CAM_LOOK, Vector3.UP)
		cam.current = true
		svp.size_changed.connect(_fit_cam)
		_fit_cam.call_deferred()

	func _fit_cam() -> void:
		if cam == null or not is_instance_valid(cam):
			return
		var sz := Vector2(svp.size)
		if sz.y <= 0.0:
			return
		if sz.x / sz.y < 1.4:
			cam.keep_aspect = Camera3D.KEEP_WIDTH
			cam.fov = 80.0
		else:
			cam.keep_aspect = Camera3D.KEEP_HEIGHT
			cam.fov = 46.0

	# ------------------------------------------------------------ duruş
	func _pose_target(fig: Fig, c) -> Array:
		var rest: Array = FOE_REST if fig.is_foe else ME_REST
		var guards: Array = FOE_GUARD if fig.is_foe else ME_GUARD
		var winds: Array = FOE_WIND if fig.is_foe else ME_WIND
		var strikes: Array = FOE_STRIKE if fig.is_foe else ME_STRIKE
		var base: Array = rest
		if c.guard >= 0:
			base = guards[c.guard]
		if c.state == "wind":
			var p: float = clampf(c.t / maxf(c.dur, 0.01), 0.0, 1.0)
			var e: float = p * p * (3.0 - 2.0 * p)
			var w: Array = winds[c.dir]
			return [(rest[0] as Vector3).lerp(w[0], e), (rest[1] as Vector3).lerp(w[1], e).normalized(), true]
		if fig.struck_t > 0.0:
			return [strikes[fig.last_dir][0], strikes[fig.last_dir][1], false]
		if c.state == "stagger":
			return [STAGGER_POSE[0], STAGGER_POSE[1], false]
		return [base[0], base[1], false]

	func _apply_fig(fig: Fig, c, dt: float) -> void:
		var tg: Array = _pose_target(fig, c)
		var k: float = 40.0 if bool(tg[2]) else 16.0
		var a: float = 1.0 - exp(-k * dt)
		fig.grip = fig.grip.lerp(tg[0], a)
		fig.blade = fig.blade.lerp(tg[1], a).normalized()
		fig.struck_t = maxf(0.0, fig.struck_t - dt)
		var gw: Vector3 = fig.world(fig.grip)
		var bw: Vector3 = fig.world_dir(fig.blade)
		var sword_pos: Vector3 = gw
		if fig.ik_r != null and fig.skel != null:
			var inv: Transform3D = fig.skel.global_transform.affine_inverse()
			var sh: Vector3 = fig.ik_r.shoulder()
			var pole: Vector3 = sh + Vector3(0.25 if not fig.is_foe else -0.25, -1.0, 0.1)
			fig.ik_r.solve(inv * gw, pole)
			sword_pos = fig.skel.global_transform * fig.ik_r.wrist_pos()
			if fig.ik_l != null:
				# serbest kol göğüs önünde kalkanı tutar gibi durur
				var lt: Vector3 = fig.world(Vector3(-0.3 if not fig.is_foe else 0.3, 1.2, 0.3))
				var shl: Vector3 = fig.ik_l.shoulder()
				fig.ik_l.solve(inv * lt, shl + Vector3(-0.25 if not fig.is_foe else 0.25, -1.0, 0.1))
		fig.sword.global_position = sword_pos
		var q := Quaternion(Vector3.UP, bw)
		fig.sword.global_basis = Basis(q)
		# sendeleyen savaşçı geriye eğilir
		var want_tilt: float = -16.0 if c.state == "stagger" else 0.0
		fig.tilt = lerpf(fig.tilt, want_tilt, 1.0 - exp(-10.0 * dt))
		fig.root.rotation_degrees.x = fig.tilt * (1.0 if fig.is_foe else -1.0)

	# ------------------------------------------------------------ her kare
	func _process(dt: float) -> void:
		if finished:
			_apply_fig(me, core.p, dt)
			_apply_fig(foe, core.f, dt)
			return
		_adapt_quality(dt)
		core.update(dt)
		for ev in core.events:
			_on_event(String(ev[0]), ev[1])
		core.events.clear()
		shake = maxf(0.0, shake - dt * 2.5)
		php_bar.value = core.p.hp
		fhp_bar.value = core.f.hp
		_apply_fig(me, core.p, dt)
		_apply_fig(foe, core.f, dt)
		var sh := Vector3(randf() - 0.5, randf() - 0.5, 0) * 0.18 * shake
		cam.position = CAM_POS + sh
		# kolaylık oku: rakibin vuruş yönü soluk bir okla gösterilir (kılıç duruşunu okumayı öğretir)
		if core.f.state == "wind" and bool(spec.get("hint", true)):
			var pr: float = clampf(core.f.t / maxf(core.f.dur, 0.01), 0.0, 1.0)
			hint_lbl.text = ["◄", "▲", "►", "●"][core.f.dir]
			hint_lbl.modulate.a = clampf(pr * 1.6, 0.0, 0.55)
		else:
			hint_lbl.modulate.a = 0.0
		for i in 4:
			var on: bool = core.p.guard == i
			(guard_btns[i] as Button).modulate = Color(1.0, 0.9, 0.5) if on else Color(1, 1, 1)

	func _on_event(n: String, d) -> void:
		var s = ui.sfx
		match n:
			"wind":
				if String(d[0]) == "f":
					msg_lbl.text = "Rakibin kılıcı kalkıyor: yönünü oku, o yöne siper al."
					banner_lbl.text = ""
				else:
					banner_lbl.text = ""
			"redirect":
				if String(d[0]) == "f":
					msg_lbl.text = "Aldatma! Rakip yönünü değiştirdi."
			"parry":
				var defender: String = String(d[0])
				var att: Fig = foe if defender == "p" else me
				att.struck_t = 0.22
				att.last_dir = (core.f.dir if defender == "p" else core.p.dir)
				if defender == "p":
					msg_lbl.text = "Kusursuz siper! Rakip sendeledi: VUR!" if bool(d[1]) else "Siper tuttu."
				else:
					msg_lbl.text = "Rakip vuruşunu savuşturdu." if not bool(d[1]) else "Rakip kusursuz savuşturdu: sendeledin."
				shake = 0.5
				if s != null:
					s.play("order", 0.6)
			"hit":
				var victim: String = String(d[0])
				var att2: Fig = foe if victim == "p" else me
				att2.struck_t = 0.22
				att2.last_dir = int(d[2])
				shake = 1.0
				if victim == "p":
					msg_lbl.text = "İsabet aldın."
					if s != null:
						s.play("error", 0.5)
				else:
					msg_lbl.text = "Vuruş isabet etti!"
					if s != null:
						s.play("coin", 0.5)
			"feint":
				pass
			"over":
				_finish(String(d))

	func _finish(r: String) -> void:
		if finished:
			return
		finished = true
		for b in guard_btns:
			b.disabled = true
		swipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		yield_btn.disabled = true
		yield_btn.modulate.a = 0.0
		yield_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		yield_armed = false
		hint_lbl.modulate.a = 0.0
		var txt: String
		match r:
			"win":
				txt = String(spec.get("win_text", "Rakip silahını bıraktı. Meydan senin."))
			"lose":
				txt = String(spec.get("lose_text", "Yere yığıldın. Ordugâh sessizliğe gömüldü."))
			"draw":
				txt = String(spec.get("draw_text", "İki taraf da ayakta kalamadı; hakemler dövüşü durdurdu."))
			_:
				txt = String(spec.get("yield_text", "Meydanı terk ettin; bunu herkes gördü."))
		banner_lbl.text = {"win": "ZAFER", "lose": "YENİLGİ", "draw": "BERABERE", "yield": "ÇEKİLDİN"}[r]
		msg_lbl.text = txt
		var b := TK.button("Devam", "good" if r == "win" else "", "", Vector2(0, 92), 18)
		b.pressed.connect(func():
			if _done:
				return
			_done = true
			var info := {"hp": core.p.hp, "foe_hp": core.f.hp, "rounds": 0}
			ui.set_modal(null)
			queue_free()
			cb.call(r, info))
		end_box.add_child(b)
		end_box.visible = true

	# ------------------------------------------------------------ çıkış: geri tuşu / Meydanı terk et
	func _yield_pressed() -> void:
		if finished:
			return
		if not yield_armed:
			_arm_yield()
		else:
			core.outcome = "yield"
			_finish("yield")

	func _arm_yield() -> void:
		yield_armed = true
		_yield_token += 1
		var tok := _yield_token
		yield_btn.text = TK.up("Onaylamak için dokun")
		TK.style_button(yield_btn, "danger")
		get_tree().create_timer(2.5).timeout.connect(func():
			if is_instance_valid(self) and not finished and yield_armed and tok == _yield_token:
				yield_armed = false
				yield_btn.text = TK.up("Meydanı terk et")
				TK.style_button(yield_btn, "ghost"))

	## ui.hide_dialog() (Android geri tuşu / Esc) bunu çağırır.
	func close() -> void:
		if finished:
			if not _done:
				_press_end.call_deferred()
			return
		_yield_pressed()
		if ui != null:
			ui.set_modal.call_deferred(self)

	func _press_end() -> void:
		if _done or not is_instance_valid(self) or end_box.get_child_count() == 0:
			return
		(end_box.get_child(0) as Button).emit_signal("pressed")

	func _exit_tree() -> void:
		if _done or finished or not cb.is_valid():
			return
		finished = true
		_done = true
		var info := {"hp": core.p.hp, "foe_hp": core.f.hp, "rounds": 0}
		cb.call_deferred("yield", info)

	## Zayıf cihazda (ort. kare süresi > 26 ms) 3B alanı yarı çözünürlükte çizilir; bir kez karar verilir.
	func _adapt_quality(dt: float) -> void:
		if _q_done:
			return
		_q_frames += 1
		if _q_frames <= 20:
			return
		_q_time += dt
		if _q_frames >= 110:
			_q_done = true
			if _q_time / 90.0 > 0.026 and _svc != null:
				_svc.stretch_shrink = 2
