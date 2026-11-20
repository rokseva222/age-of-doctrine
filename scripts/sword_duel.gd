extends RefCounted
## Kılıç düellosu (3B, gerçek zamanlı). Rakip kılıcını bir yönden kaldırır; doğru anda doğru yönde siper al.
## Kusursuz siper uzun bir karşı vuruş fırsatı verir. Rakip bazen son anda yönünü değiştirir (aldatma).
## Kullanım: SwordDuel.open(ui, {title, intro, skill, power, win_text, lose_text, ...}, func(result, info): ...)
## Sonuç: "win" | "lose" | "draw" | "yield" (Minigames.duel ile aynı).

const TK = preload("res://scripts/theme_kit.gd")

const GUARDS := ["Sol siper", "Üst siper", "Sağ siper"]
const ARROWS := ["◄", "▲", "►"]
const TIME_CAP := 80.0


static func open(ui, spec: Dictionary, cb: Callable) -> void:
	if ui.speed_idx != 0:
		ui.set_speed(0)
		ui.speed_changed.emit(0)
	var ov := View.new()
	ov.setup(ui, spec, cb)
	ui.root.add_child(ov)
	ui.set_modal(ov)


## Oyun mantığı (görüntüden bağımsız; başsız testte kullanılır)
class Core extends RefCounted:
	var php := 100.0
	var ohp := 100.0
	var skill := 0.3          # oyuncu becerisi 0..1
	var power := 1.0          # rakip gücü (0.8..1.4)
	var rng := RandomNumberGenerator.new()
	var phase := "idle"       # idle | wind | counter | over
	var t := 0.0
	var clock := 0.0
	var dir := 1              # gerçekte gelecek vuruş yönü
	var show_dir := 1         # rakibin şu an gösterdiği yön
	var wind := 1.0
	var feint_at := -1.0
	var guard := -1
	var guard_t := -9.0
	var perfect := false
	var counter_left := 0.0
	var pause := 0.9
	var outcome := ""
	var events: Array = []    # [ad, veri] - görüntü tüketir

	func setup(skill_: float, power_: float, seed_: int = -1) -> void:
		skill = clampf(skill_, 0.0, 1.0)
		power = clampf(power_, 0.7, 1.5)
		if seed_ >= 0:
			rng.seed = seed_
		else:
			rng.randomize()

	func _ev(n: String, d = null) -> void:
		events.append([n, d])

	func _start_attack() -> void:
		dir = rng.randi() % 3
		show_dir = dir
		wind = lerpf(1.2, 0.72, clampf((power - 0.8) / 0.6, 0.0, 1.0))
		feint_at = -1.0
		if rng.randf() < 0.16 * power:
			feint_at = wind * 0.5
		guard = -1
		guard_t = -9.0
		phase = "wind"
		t = 0.0
		_ev("wind", show_dir)

	func press_guard(d: int) -> void:
		if phase != "wind" or d < 0 or d > 2:
			return
		guard = d
		guard_t = t
		_ev("guard", d)

	func press_strike() -> void:
		if phase != "counter":
			return
		var dmg: float = 20.0 * (1.0 + skill * 0.25) + (10.0 if perfect else 0.0)
		ohp = maxf(0.0, ohp - dmg)
		_ev("hit_foe", dmg)
		phase = "idle"
		t = 0.0
		pause = 1.0
		_check_end()

	func _check_end() -> void:
		if outcome != "":
			return
		if php <= 0.0 and ohp <= 0.0:
			outcome = "draw"
		elif ohp <= 0.0:
			outcome = "win"
		elif php <= 0.0:
			outcome = "lose"
		elif clock >= TIME_CAP:
			outcome = "win" if ohp < php else ("lose" if php < ohp else "draw")
		if outcome != "":
			phase = "over"
			_ev("over", outcome)

	func update(dt: float) -> void:
		if phase == "over":
			return
		clock += dt
		t += dt
		match phase:
			"idle":
				if t >= pause:
					_start_attack()
			"wind":
				if feint_at >= 0.0 and t >= feint_at:
					feint_at = -1.0
					dir = (dir + 1 + rng.randi() % 2) % 3
					show_dir = dir
					_ev("feint", dir)
				if t >= wind:
					_resolve()
			"counter":
				counter_left -= dt
				if counter_left <= 0.0:
					phase = "idle"
					t = 0.0
					pause = 0.5
					_ev("missed")
		_check_end()

	func _resolve() -> void:
		var win: float = 0.5 + 0.2 * skill
		var ok: bool = guard == dir and (wind - guard_t) <= win
		if ok:
			perfect = (wind - guard_t) <= 0.2
			phase = "counter"
			counter_left = 1.7 if perfect else 1.1
			t = 0.0
			_ev("parry", perfect)
		else:
			var dmg: float = 17.0 * power
			if guard >= 0 and guard != dir:
				dmg *= 1.15
			php = maxf(0.0, php - dmg)
			_ev("hit_player", dmg)
			phase = "idle"
			t = 0.0
			pause = 0.8


class View extends Control:
	var ui
	var spec: Dictionary
	var cb: Callable
	var core := Core.new()
	var svp: SubViewport
	var cam: Camera3D
	var foe: Node3D
	var foe_sword: Node3D
	var foe_blade: MeshInstance3D
	var my_sword: Node3D
	var php_bar: ProgressBar
	var ohp_bar: ProgressBar
	var msg_lbl: Label
	var arrow_lbl: Label
	var banner_lbl: Label
	var guard_btns: Array = []
	var strike_btn: Button
	var yield_btn: Button
	var end_box: VBoxContainer
	var yield_armed := false
	var _yield_token := 0
	var swing_p := 0.0         # rakip vuruş animasyonu
	var my_swing := 0.0        # oyuncu vuruş animasyonu
	var shake := 0.0
	var stagger := 0.0
	var my_guard := 1
	var finished := false
	var _svc: SubViewportContainer
	var _q_time := 0.0
	var _q_frames := 0
	var _q_done := false
	var _done := false          # sonuç geri çağrısı tek sefer
	var tilt := [66.0, 0.0, -66.0]   # ekranda sol / üst / sağ için kılıç eğimi (derece, z ekseni)

	func _input(e: InputEvent) -> void:
		if not (e is InputEventKey) or not e.pressed or e.echo:
			return
		var k: int = e.keycode
		var g := -1
		if k in [KEY_A, KEY_LEFT, KEY_1]:
			g = 0
		elif k in [KEY_W, KEY_UP, KEY_2, KEY_S, KEY_DOWN]:
			g = 1
		elif k in [KEY_D, KEY_RIGHT, KEY_3]:
			g = 2
		if g >= 0:
			get_viewport().set_input_as_handled()
			_guard(g)
		elif k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			if finished and end_box.get_child_count() > 0:
				(end_box.get_child(0) as Button).emit_signal("pressed")
			else:
				_strike()

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
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 14
		vb.offset_right = -14
		vb.offset_top = 10
		vb.offset_bottom = -10
		vb.add_theme_constant_override("separation", 8)
		add_child(vb)
		# Üst satır: köşede "Meydanı terk et" (alttaki Vur! düğmesine yanlışlıkla basılmasın; iki dokunuşla onaylanır), ortada başlık
		var head := HBoxContainer.new()
		head.layout_direction = Control.LAYOUT_DIRECTION_LTR
		head.add_theme_constant_override("separation", 10)
		vb.add_child(head)
		yield_btn = TK.button("Meydanı terk et", "ghost", "", Vector2(300, 72), 13)
		yield_btn.pressed.connect(_yield_pressed)
		head.add_child(yield_btn)
		var title := TK.t(String(spec.get("title", "Düello")), "h3", TK.TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(title)
		var head_pad := Control.new()
		head_pad.custom_minimum_size = Vector2(300, 0)
		head.add_child(head_pad)
		var bars := HBoxContainer.new()
		bars.layout_direction = Control.LAYOUT_DIRECTION_LTR
		bars.add_theme_constant_override("separation", 14)
		vb.add_child(bars)
		php_bar = _bar(Color(0.30, 0.65, 0.40))
		ohp_bar = _bar(Color(0.80, 0.30, 0.25))
		bars.add_child(php_bar)
		bars.add_child(ohp_bar)
		# 3B sahne
		var holder := Control.new()
		holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		holder.custom_minimum_size = Vector2(0, 240)
		holder.clip_contents = true
		vb.add_child(holder)
		var svc := SubViewportContainer.new()
		svc.stretch = true
		_svc = svc
		# telefon için hafif: MSAA yok, gölge yok, tek ışık; kare süresi uzarsa 3B yarı çözünürlüğe düşer (bkz. _adapt_quality)
		svc.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.add_child(svc)
		svp = SubViewport.new()
		svp.own_world_3d = true
		svp.msaa_3d = Viewport.MSAA_DISABLED
		svp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		svp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		svc.add_child(svp)
		_build_world()
		arrow_lbl = TK.t("", "h1", Color(1.0, 0.35, 0.25))
		arrow_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
		arrow_lbl.anchor_left = 0.0
		arrow_lbl.anchor_right = 1.0
		arrow_lbl.offset_top = 6
		arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(arrow_lbl)
		banner_lbl = TK.t(String(spec.get("intro", "Kılıçlar çekildi.")), "bodyb", TK.GOLD)
		banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_lbl.anchor_left = 0.0
		banner_lbl.anchor_right = 1.0
		banner_lbl.anchor_top = 1.0
		banner_lbl.anchor_bottom = 1.0
		banner_lbl.offset_left = 12
		banner_lbl.offset_right = -12
		banner_lbl.offset_top = -10
		banner_lbl.offset_bottom = -10
		banner_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN   # etiket kendi yüksekliğiyle yukarı doğru büyür (alt kenara yaslı)
		banner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(banner_lbl)
		msg_lbl = TK.t("", "small", TK.MUTED)
		msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg_lbl.custom_minimum_size = Vector2(0, 52)
		msg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vb.add_child(msg_lbl)
		var row := HBoxContainer.new()
		row.layout_direction = Control.LAYOUT_DIRECTION_LTR   # sağdan sola dillerde de "sol siper" solda, "sağ siper" sağda kalsın
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		for i in 3:
			var idx: int = i
			var b := TK.button("%s  [%s]" % [GUARDS[i], ["A", "W", "D"][i]], "blue", "shield", Vector2(0, 104), 17)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func(): _guard(idx))
			row.add_child(b)
			guard_btns.append(b)
		strike_btn = TK.button("Vur!  [Boşluk]", "danger", "sword", Vector2(0, 92), 20)
		strike_btn.pressed.connect(_strike)
		strike_btn.disabled = true
		vb.add_child(strike_btn)
		end_box = VBoxContainer.new()
		end_box.visible = false
		vb.add_child(end_box)
		set_process(true)

	func _bar(col: Color) -> ProgressBar:
		var pb := ProgressBar.new()
		pb.min_value = 0
		pb.max_value = 100
		pb.value = 100
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 18)
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fill := StyleBoxFlat.new()
		fill.bg_color = col
		pb.add_theme_stylebox_override("fill", fill)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.1, 0.11, 0.14)
		pb.add_theme_stylebox_override("background", bg)
		return pb

	# ------------------------------------------------------------ 3B dünya (yüzsüz, koyu lacivert silüetler)
	func _mat(c: Color, emis: float = 0.0, rough: float = 0.8) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		if emis > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = emis
		return m

	func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = pos
		mi.material_override = mat
		parent.add_child(mi)
		return mi

	func _fighter(col: Color, blade_col: Color) -> Array:
		var root := Node3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.5
		_mesh(root, cap, Vector3(0, 0.85, 0), _mat(col))
		var head := SphereMesh.new()
		head.radius = 0.21
		head.height = 0.42
		_mesh(root, head, Vector3(0, 1.82, 0), _mat(col))
		var pivot := Node3D.new()
		pivot.position = Vector3(0.0, 1.25, 0.35)
		root.add_child(pivot)
		var blade := BoxMesh.new()
		blade.size = Vector3(0.15, 1.3, 0.04)
		var bi := _mesh(pivot, blade, Vector3(0, 0.7, 0), _mat(blade_col, 0.0, 0.25))
		var hilt := BoxMesh.new()
		hilt.size = Vector3(0.3, 0.05, 0.05)
		_mesh(pivot, hilt, Vector3(0, 0.03, 0), _mat(Color(0.85, 0.68, 0.25)))
		var grip := BoxMesh.new()
		grip.size = Vector3(0.05, 0.22, 0.05)
		_mesh(pivot, grip, Vector3(0, -0.1, 0), _mat(Color(0.3, 0.2, 0.12)))
		return [root, pivot, bi]

	func _build_world() -> void:
		var world := Node3D.new()
		svp.add_child(world)
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.10, 0.12, 0.20)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.55, 0.52, 0.5)
		env.ambient_light_energy = 0.8
		var we := WorldEnvironment.new()
		we.environment = env
		world.add_child(we)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, 25, 0)
		sun.light_energy = 1.1
		world.add_child(sun)
		var plane := PlaneMesh.new()
		plane.size = Vector2(30, 30)
		_mesh(world, plane, Vector3(0, 0, 0), _mat(Color(0.55, 0.45, 0.30)))
		var wall := BoxMesh.new()
		wall.size = Vector3(30, 8, 0.5)
		_mesh(world, wall, Vector3(0, 4, -6.5), _mat(Color(0.36, 0.33, 0.30)))
		for x in [-4.5, -1.5, 1.5, 4.5]:
			var pil := CylinderMesh.new()
			pil.top_radius = 0.28
			pil.bottom_radius = 0.28
			pil.height = 5.0
			_mesh(world, pil, Vector3(x, 2.5, -5.8), _mat(Color(0.45, 0.4, 0.34)))
		var f := _fighter(Color(0.07, 0.1, 0.2), Color(0.75, 0.78, 0.82))
		foe = f[0]
		foe_sword = f[1]
		foe_blade = f[2]
		var fm: StandardMaterial3D = foe_blade.material_override
		fm.emission_enabled = true          # her karede aç/kapa yapmak StandardMaterial3D shader'ını yeniden derletir (mobilde takılma); yalnız enerji değişir
		fm.emission = Color(1.0, 0.25, 0.2)
		fm.emission_energy_multiplier = 0.0
		foe.position = Vector3(0, 0, -0.1)
		foe.scale = Vector3(1.2, 1.2, 1.2)
		foe.rotation_degrees.y = 180.0
		world.add_child(foe)
		var m := _fighter(Color(0.12, 0.2, 0.14), Color(0.85, 0.88, 0.9))
		var mine: Node3D = m[0]
		# oyuncu: kameranın önünde, omuz hizasında kılıç (kendi gövdesi görünmez)
		my_sword = m[1]
		mine.position = Vector3(0.0, -0.15, 2.4)
		mine.visible = true
		(mine.get_child(0) as MeshInstance3D).visible = false
		(mine.get_child(1) as MeshInstance3D).visible = false
		world.add_child(mine)
		cam = Camera3D.new()
		cam.position = Vector3(0, 1.8, 3.0)
		cam.rotation_degrees = Vector3(-8, 0, 0)
		cam.fov = 58
		world.add_child(cam)
		cam.current = true
		svp.size_changed.connect(_fit_cam)
		_fit_cam.call_deferred()

	# ------------------------------------------------------------ girdi
	func _guard(d: int) -> void:
		if finished:
			return
		my_guard = d
		core.press_guard(d)

	func _strike() -> void:
		if finished:
			return
		core.press_strike()

	# ------------------------------------------------------------ her kare
	func _process(dt: float) -> void:
		if finished:
			return
		_adapt_quality(dt)
		core.update(dt)
		for ev in core.events:
			_on_event(String(ev[0]), ev[1])
		core.events.clear()
		swing_p = maxf(0.0, swing_p - dt * 4.0)
		my_swing = maxf(0.0, my_swing - dt * 5.0)
		shake = maxf(0.0, shake - dt * 2.5)
		php_bar.value = core.php
		ohp_bar.value = core.ohp
		_pose()
		strike_btn.disabled = core.phase != "counter"
		for i in 3:
			guard_btns[i].disabled = core.phase != "wind"
		if core.phase == "wind":
			var p: float = clampf(core.t / core.wind, 0.0, 1.0)
			arrow_lbl.text = String(ARROWS[core.show_dir]) if p > 0.12 else ""
			arrow_lbl.modulate.a = clampf(p * 2.0, 0.0, 1.0)
		else:
			arrow_lbl.text = ""

	func _pose() -> void:
		var z_rest := 12.0
		var foe_z := z_rest
		var foe_x := 0.0
		var glow := 0.0
		if core.phase == "wind":
			var p: float = clampf(core.t / core.wind, 0.0, 1.0)
			var e: float = p * p * (3.0 - 2.0 * p)
			foe_z = lerpf(z_rest, -float(tilt[core.show_dir]), e)   # rakip bize dönük: x ekseni ters
			foe_x = -55.0 * e
			glow = e
		elif core.phase == "counter":
			foe_z = 20.0
			foe_x = 25.0
			stagger = minf(1.0, stagger + get_process_delta_time() * 6.0)
		else:
			stagger = maxf(0.0, stagger - get_process_delta_time() * 4.0)
		if swing_p > 0.0:
			foe_x = lerpf(foe_x, 80.0, swing_p)
		foe_sword.rotation_degrees = Vector3(foe_x, 0, foe_z)
		foe.rotation_degrees.x = -14.0 * stagger
		var m: StandardMaterial3D = foe_blade.material_override
		m.emission_energy_multiplier = glow * 2.5
		# oyuncu kılıcı: seçili siper yönüne yatar; vuruşta öne savrulur
		var mz: float = float(tilt[my_guard]) * 0.9
		var mx: float = -20.0 + 85.0 * my_swing
		my_sword.rotation_degrees = Vector3(mx, 0, mz)
		my_sword.position = Vector3(0.5, 0.9, -0.2)
		my_sword.scale = Vector3(0.7, 0.7, 0.7)
		var sh := Vector3(randf() - 0.5, randf() - 0.5, 0) * 0.25 * shake
		cam.position = Vector3(0, 1.8, 3.0) + sh

	func _on_event(n: String, d) -> void:
		var s = ui.sfx
		match n:
			"wind":
				msg_lbl.text = "Rakibin kılıcı kalkıyor: yönünü oku."
				banner_lbl.text = ""
			"feint":
				msg_lbl.text = "Aldatma! Rakip yönünü değiştirdi."
			"parry":
				my_swing = 0.0
				if bool(d):
					msg_lbl.text = "Kusursuz siper! Rakip sendeledi: VUR!"
				else:
					msg_lbl.text = "Siper tuttu. Rakip açıkta: VUR!"
				if s != null:
					s.play("order", 0.6)
			"hit_player":
				swing_p = 1.0
				shake = 1.0
				msg_lbl.text = "İsabet aldın."
				if s != null:
					s.play("error", 0.5)
			"hit_foe":
				my_swing = 1.0
				shake = 0.6
				msg_lbl.text = "Vuruş isabet etti!"
				if s != null:
					s.play("coin", 0.5)
			"missed":
				msg_lbl.text = "Fırsat kaçtı."
			"over":
				_finish(String(d))

	func _finish(r: String) -> void:
		if finished:
			return
		finished = true
		for b in guard_btns:
			b.disabled = true
		strike_btn.disabled = true
		yield_btn.disabled = true
		yield_btn.modulate.a = 0.0
		yield_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		yield_armed = false
		arrow_lbl.text = ""
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
		var b := TK.button("Devam", "good" if r == "win" else "", "", Vector2(0, 104), 18)
		b.pressed.connect(func():
			if _done:
				return
			_done = true
			var info := {"hp": core.php, "foe_hp": core.ohp, "rounds": 0}
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

	## ui.hide_dialog() (Android geri tuşu / Esc) bunu çağırır: ilk basış çekilmeyi onay ister, ikincisi çekilir;
	## sonuç ekranındayken "Devam"a basar. hide_dialog() sonda _modal'ı boşalttığı için düello sürerken modal kaydı yeniden yazılır.
	func close() -> void:
		if finished:
			# sonuç ekranında geri = Devam. Geri çağrısı yeni pencere açabilir; hide_dialog() sonda _modal'ı boşalttığı için
			# Devam kare sonuna ertelenir (yeni pencerenin modal kaydı ezilmesin).
			if not _done:
				_press_end.call_deferred()
			return
		_yield_pressed()
		if ui != null:
			ui.set_modal.call_deferred(self)    # düello sürüyor/sonuç bekliyor: modal kaydı geri yazılır

	func _press_end() -> void:
		if _done or not is_instance_valid(self) or end_box.get_child_count() == 0:
			return
		(end_box.get_child(0) as Button).emit_signal("pressed")

	func _exit_tree() -> void:
		# başka bir pencere bizi sildiyse (ui._open_sheet) hikâye akışı takılı kalmasın: çekilmiş say
		if _done or finished or not cb.is_valid():
			return
		finished = true
		_done = true
		var info := {"hp": core.php, "foe_hp": core.ohp, "rounds": 0}
		cb.call_deferred("yield", info)

	## Zayıf cihazda (ort. kare süresi > 26 ms) 3B alanı yarı çözünürlükte çizilir; bir kez karar verilir.
	func _adapt_quality(dt: float) -> void:
		if _q_done:
			return
		_q_frames += 1
		if _q_frames <= 20:      # açılış/gölgelendirici derleme karelerini sayma
			return
		_q_time += dt
		if _q_frames >= 110:
			_q_done = true
			if _q_time / 90.0 > 0.026 and _svc != null:
				_svc.stretch_shrink = 2

	## Dikey/dar ekranda yatay görüş açısı sabit tutulur: yoksa rakibin yana yatan kılıcı kadraj dışında kalır.
	func _fit_cam() -> void:
		if cam == null or not is_instance_valid(cam):
			return
		var sz := Vector2(svp.size)
		if sz.y <= 0.0:
			return
		if sz.x / sz.y < 1.4:
			cam.keep_aspect = Camera3D.KEEP_WIDTH
			cam.fov = 82.0
		else:
			cam.keep_aspect = Camera3D.KEEP_HEIGHT
			cam.fov = 58.0
