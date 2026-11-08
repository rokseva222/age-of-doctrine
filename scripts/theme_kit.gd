extends RefCounted
const Loc = preload("res://scripts/loc.gd")
## Tasarım sistemi: "Ajans Dosyası" kimliği.
## Koyu haritanın üzerinde grafit dosya panelleri, krem (kâğıt) birincil eylemler, tek bir kırmızı "son dakika" rengi.
## Üç yazı ailesi, her birinin tek görevi var:
##   Big Shoulders (display) : başlıklar, düğmeler, ülke adları  - dar, büyük harf, otoriter
##   Instrument Sans (ui)    : cümle metni, açıklamalar
##   IBM Plex Mono (mono)    : sayılar, tarih, etiketler, haber türü - tablo gibi hizalı
## Şekil kuralı: köşe yarıçapı 3 (düğme/panel), 2 (damga etiketleri); yuvarlak yalnızca işaretçilerde.
## Gölge kuralı: tek gölge (panel yüksekliği). Parıltı yok, degrade yok, emoji yok.

const Icons = preload("res://scripts/icons.gd")
const Flags = preload("res://scripts/flags.gd")

const FONT_UI_R := "res://assets/fonts/InstrumentSans-Regular.ttf"
const FONT_UI_B := "res://assets/fonts/InstrumentSans-Bold.ttf"
const FONT_DISP_B := "res://assets/fonts/BigShoulders-Bold.ttf"
const FONT_DISP_R := "res://assets/fonts/BigShoulders-Regular.ttf"
const FONT_FALLBACK := "res://assets/fonts/Rubik-Variable.ttf"
const FONT_MONO_R := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const FONT_MONO_B := "res://assets/fonts/IBMPlexMono-Bold.ttf"

# ---- renk rolleri
const SEA := Color("0c1b30")             # harita denizi (yalnızca harita)
const BG := Color("0b0e12")
const PANEL := Color("14181e")
const PANEL_SOLID := Color("171b22")
const PANEL_LIGHT := Color("20262e")
const PANEL_HI := Color("2a313b")
const LINE := Color("39414b")
const BORDER := Color("39414b")
const PAPER := Color("ece6d6")           # birincil eylem, seçili durum
const PAPER_DIM := Color("cfc8b6")
const INK := Color("17130f")             # kâğıt üstündeki yazı
const TEXT := Color("ede9de")
const MUTED := Color("9aa2ad")
const FAINT := Color("646c77")
const RED := Color("e5482f")             # savaş / son dakika / tehlike
const RED_TEXT := Color("ff7f6b")
const GOLD := Color("e3a92b")            # yalnızca para
const BLUE := Color("5ba4e0")            # ittifak
const GREEN := Color("5db86e")           # olumlu
const PURPLE := Color("a98be0")          # isyan
const ORANGE := Color("e58a3a")          # işgal

# ---- tip ölçeği (1280x720 tabanında)
const T_KICKER := 19
const T_SMALL := 22
const T_BODY := 24
const T_VALUE := 30
const T_H3 := 38
const T_H2 := 48
const T_H1 := 76

# ---- aralık ölçeği
const S1 := 4
const S2 := 8
const S3 := 12
const S4 := 16
const S5 := 24
const S6 := 32

static var _fonts: Dictionary = {}
static var scale_factor := 1.0


static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		# içe aktarılmamış geliştirme çalıştırması için yedek yol
		var ff := FontFile.new()
		ff.load_dynamic_font(path)
		return ff
	return ThemeDB.fallback_font


static func _variation(path: String, spacing: float, key: String) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var fv := FontVariation.new()
	fv.base_font = _load_font(path)
	fv.fallbacks = [_load_font(FONT_FALLBACK)]            # Kiril vb. (Latin dışı yazılar; CJK/Arapça/Devanagari sistem yazı tipinden)
	fv.spacing_glyph = int(spacing)
	_fonts[key] = fv
	return fv


## Cümle metni. Eski kodla uyumlu: 600 ve üstü kalın.
static func font(weight: int = 500) -> Font:
	return _variation(FONT_UI_B if weight >= 600 else FONT_UI_R, 0, "ui_b" if weight >= 600 else "ui_r")


static func disp(track: int = 1) -> Font:
	return _variation(FONT_DISP_B, track, "disp%d" % track)


static func mono(bold: bool = true, track: int = 0) -> Font:
	return _variation(FONT_MONO_B if bold else FONT_MONO_R, track, "mono%s%d" % [bold, track])


## Harita yazıları için MSDF'li kopya: her ölçekte ve döndürülünce keskin kalır.
static func map_font(display: bool = true) -> Font:
	var key := "map_disp" if display else "map_ui"
	if _fonts.has(key):
		return _fonts[key]
	var src: Font = _load_font(FONT_DISP_B if display else FONT_UI_B)
	var f: Font = src
	if src is FontFile:
		f = src.duplicate()
		f.fallbacks = [_load_font(FONT_FALLBACK)]
		f.multichannel_signed_distance_field = true
		f.msdf_pixel_range = 16
		f.msdf_size = 56
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	_fonts[key] = f
	return f


## Dolgu rengine göre okunur yazı rengi: [yazı, hale]
static func label_colors(fill: Color, a: float = 1.0) -> Array:
	var lin: float = fill.srgb_to_linear().get_luminance()
	if lin > 0.19:
		return [Color(0.075, 0.063, 0.05, 0.96 * a), Color(1.0, 1.0, 1.0, 0.5 * a)]
	return [Color(0.97, 0.96, 0.92, 0.97 * a), Color(0.03, 0.05, 0.08, 0.72 * a)]


## Türkçe büyük harf: i -> İ, ı -> I (motorun varsayılanı bunu yapmaz).
static func up(s: String) -> String:
	if Loc.lang == "tr":
		return s.replace("i", "İ").replace("ı", "I").to_upper()
	return Loc.t(s).to_upper()


# ---------------------------------------------------------------- metin

## Rol tabanlı metin: role = kicker | small | body | bodyb | value | valuel | h3 | h2 | h1 | mono | caps
static func t(text: String, role: String = "body", color: Color = TEXT) -> Label:
	var l := Label.new()
	var f: Font
	var fs := T_BODY
	var s := text
	match role:
		"kicker":
			f = mono(true, 2)
			fs = T_KICKER
			s = up(text)
			if color == TEXT:
				color = MUTED
		"small":
			f = font(400)
			fs = T_SMALL
			if color == TEXT:
				color = MUTED
		"bodyb":
			f = font(700)
		"value":
			f = mono(true, 0)
			fs = T_VALUE
		"valuel":
			f = mono(true, 0)
			fs = 40
		"mono":
			f = mono(false, 0)
			fs = T_SMALL
		"caps":
			f = disp(1)
			fs = 30
			s = up(text)
		"h3":
			f = disp(1)
			fs = T_H3
			s = up(text)
		"h2":
			f = disp(2)
			fs = T_H2
			s = up(text)
		"h1":
			f = disp(3)
			fs = T_H1
			s = up(text)
		_:
			f = font(400)
	l.text = s
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l


## Eski çağrılar için: Rubik'e göre yazılmış boyutlar yeni tip ölçeğine yükseltilir (en az 20).
static func label(text: String, size: int = 18, color: Color = TEXT, weight: int = 500) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(int(round(size * 1.2)), 20))
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font(weight))
	return l


## Etiketli değer hücresi: üstte küçük mono etiket, altta büyük mono sayı.
static func stat(caption: String, value: String, color: Color = TEXT, big: bool = false) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.add_child(t(caption, "kicker"))
	var l := t(value, "valuel" if big else "value", color)
	l.name = "val"
	v.add_child(l)
	return v


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font(400)
	th.default_font_size = T_BODY
	th.set_font("font", "Label", font(400))
	th.set_font_size("font_size", "Label", T_BODY)
	th.set_font("font", "Button", disp(1))
	th.set_font_size("font_size", "Button", 30)
	th.set_color("font_color", "Label", TEXT)
	th.set_color("font_color", "Button", TEXT)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	th.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 3, 1))
	th.set_font("font", "LineEdit", font(400))
	th.set_font_size("font_size", "LineEdit", T_BODY)
	th.set_color("font_color", "LineEdit", TEXT)
	th.set_color("font_placeholder_color", "LineEdit", FAINT)
	th.set_color("caret_color", "LineEdit", PAPER)
	th.set_stylebox("normal", "LineEdit", box(BG, LINE, 3, 1, 0, Vector4(16, 10, 16, 10)))
	th.set_stylebox("focus", "LineEdit", box(BG, PAPER, 3, 2, 0, Vector4(16, 10, 16, 10)))
	var grab := box(PANEL_HI, Color(0, 0, 0, 0), 2, 0, 0, Vector4(5, 5, 5, 5))
	var grab_h := box(FAINT, Color(0, 0, 0, 0), 2, 0, 0, Vector4(5, 5, 5, 5))
	for sb in ["VScrollBar", "HScrollBar"]:
		th.set_stylebox("scroll", sb, StyleBoxEmpty.new())
		th.set_stylebox("scroll_focus", sb, StyleBoxEmpty.new())
		th.set_stylebox("grabber", sb, grab)
		th.set_stylebox("grabber_highlight", sb, grab_h)
		th.set_stylebox("grabber_pressed", sb, grab_h)
	th.set_constant("separation", "VBoxContainer", S2)
	th.set_constant("separation", "HBoxContainer", S2)
	th.set_constant("h_separation", "HFlowContainer", S2)
	th.set_constant("v_separation", "HFlowContainer", S2)
	return th


## Tek kutu üreticisi. Yarıçap en çok 4'e sıkıştırılır (şekil dili: neredeyse dik köşe).
static func box(bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 3, bw: int = 0, shadow: int = 0, pad: Vector4 = Vector4(14, 10, 14, 10)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(mini(radius, 4))
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = 14
		s.shadow_offset = Vector2(0, 5)
	s.anti_aliasing = true
	s.anti_aliasing_size = 0.8
	return s


## Yalnızca alt çizgisi olan düz satır kutusu.
static func line_box(bg: Color, line: Color = LINE, left: int = 0) -> StyleBoxFlat:
	var s := box(bg, line, 0, 0, 0, Vector4(0, 0, 0, 0))
	s.border_width_bottom = 1
	s.border_width_left = left
	return s


static func kind_color(kind: String) -> Color:
	match kind:
		"good":
			return Color("2f7d4b")
		"danger":
			return Color("b83a26")
		"gold", "primary":
			return PAPER
		"blue":
			return Color("2f6fa8")
		"purple":
			return Color("6f55b0")
		"ghost":
			return Color(0, 0, 0, 0)
		_:
			return PANEL_LIGHT


static func on_color(kind: String) -> Color:
	return INK if kind in ["gold", "primary"] else TEXT


static func style_button(b: Button, kind: String = "", radius: int = 3) -> void:
	var base: Color = kind_color(kind)
	var pl: float = float(b.get_meta("pad_l", 18.0))
	var pad := Vector4(pl, 6, 18, 4)
	var pad_p := Vector4(pl, 8, 18, 2)
	if Loc.rtl and pl > 18.0:
		pad = Vector4(18, 6, pl, 4)       # sağdan sola dillerde simge sağda: metin boşluğu da sağa geçer
		pad_p = Vector4(18, 8, pl, 2)
	var line: Color = LINE if kind in ["", "ghost"] else Color(0, 0, 0, 0)
	var bw := 1 if kind in ["", "ghost"] else 0
	var hv: Color = base.lightened(0.10) if kind != "ghost" else PANEL_LIGHT
	var pr: Color = base.darkened(0.14) if kind != "ghost" else PANEL_HI
	b.add_theme_stylebox_override("normal", box(base, line, radius, bw, 0, pad))
	b.add_theme_stylebox_override("hover", box(hv, FAINT if bw > 0 else line, radius, bw, 0, pad))
	b.add_theme_stylebox_override("pressed", box(pr, line, radius, bw, 0, pad_p))
	b.add_theme_stylebox_override("disabled", box(Color(base.r, base.g, base.b, base.a * 0.35), Color(LINE.r, LINE.g, LINE.b, 0.5), radius, 1, 0, pad))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var fc := on_color(kind)
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_hover_color", fc if kind in ["gold", "primary"] else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", fc)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	if kind == "ghost":
		b.add_theme_color_override("font_color", MUTED)


## Düğme: Big Shoulders, büyük harf. font_size eski (Rubik) ölçeğinden gelir; x1.45 ile dar yüze uyarlanır.
static func button(text: String, kind: String = "", icon: String = "", min_size: Vector2 = Vector2(0, 60), font_size: int = 19) -> Button:
	var b := Button.new()
	b.text = up(text)
	b.custom_minimum_size = Vector2(min_size.x, maxf(min_size.y, 60.0))
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", disp(1))
	b.add_theme_font_size_override("font_size", int(round(font_size * 1.45)))
	if icon != "":
		b.set_meta("pad_l", 58.0)
	style_button(b, kind)
	if icon != "":
		var iv := IconView.new()
		iv.icon = icon
		iv.color = on_color(kind) if kind != "ghost" else MUTED
		iv.stroke = 2.0
		iv.custom_minimum_size = Vector2(28, 28)
		iv.size = Vector2(28, 28)
		iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(iv)
		# sol kenara sabitli (çıpalı): sağdan sola dillerde otomatik sağa yansır, düğme boyu değişse de yerinde kalır
		iv.anchor_left = 0.0
		iv.anchor_right = 0.0
		iv.anchor_top = 0.5
		iv.anchor_bottom = 0.5
		iv.offset_left = 16.0
		iv.offset_right = 44.0
		iv.offset_top = -14.0
		iv.offset_bottom = 14.0
		b.set_meta("iv_btn", iv)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


static func icon_button(icon: String, size: float = 60.0, kind: String = "", icon_color: Color = Color.WHITE) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	style_button(b, kind)
	var iv := IconView.new()
	iv.icon = icon
	iv.color = icon_color if icon_color != Color.WHITE else (on_color(kind) if kind != "ghost" else TEXT)
	iv.stroke = 2.0
	var s := size * 0.5
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(iv)
	iv.anchor_left = 0.5
	iv.anchor_right = 0.5
	iv.anchor_top = 0.5
	iv.anchor_bottom = 0.5
	iv.offset_left = -s * 0.5
	iv.offset_right = s * 0.5
	iv.offset_top = -s * 0.5
	iv.offset_bottom = s * 0.5
	b.set_meta("iv", iv)
	return b


## Küçük ikon + metin (ülke kartında vb.)
static func chip(icon: String, text: String, color: Color = TEXT, accent: Color = MUTED) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var iv := IconView.new()
	iv.icon = icon
	iv.color = accent
	iv.stroke = 2.0
	iv.custom_minimum_size = Vector2(26, 26)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(iv)
	var l := t(text, "value", color)
	l.add_theme_font_size_override("font_size", 24)
	l.name = "txt"
	h.add_child(l)
	return h


## Damga etiketi: ince çerçeveli, büyük harf mono. Dolgu yok.
static func stamp(text: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(col.r, col.g, col.b, 0.10), col, 2, 2, 0, Vector4(9, 1, 9, 1)))
	var l := t(text, "kicker", col.lightened(0.18))
	l.add_theme_color_override("font_color", col.lightened(0.22))
	p.add_child(l)
	return p


static func flag_rect(c, size: Vector2) -> FlagView:
	var f := FlagView.new()
	f.custom_minimum_size = size
	f.size = size
	f.set_country(c)
	return f


static func hsep(alpha: float = 1.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(LINE.r, LINE.g, LINE.b, alpha)
	r.custom_minimum_size = Vector2(0, 1)
	return r


static func vsep(h: float = 0.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = LINE
	r.custom_minimum_size = Vector2(1, h)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL if h <= 0.0 else Control.SIZE_SHRINK_CENTER
	return r


static func spacer(w: float = 0.0, h: float = 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	return c


static func fill() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Dosya paneli: üstte 4 px krem şerit, içte dolgu. {panel, body} döner.
static func dossier(rule: Color = PAPER, pad: Vector4 = Vector4(24, 18, 24, 22), shadow: bool = true) -> Dictionary:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(PANEL_SOLID, LINE, 3, 1, 1 if shadow else 0, Vector4(0, 0, 0, 0)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var bar := ColorRect.new()
	bar.color = rule
	bar.custom_minimum_size = Vector2(0, 4)
	v.add_child(bar)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", int(pad.x))
	m.add_theme_constant_override("margin_top", int(pad.y))
	m.add_theme_constant_override("margin_right", int(pad.z))
	m.add_theme_constant_override("margin_bottom", int(pad.w))
	v.add_child(m)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", S3)
	m.add_child(body)
	return {"panel": p, "body": body}


# ---------------------------------------------------------------- yardımcı kontroller

class IconView extends Control:
	var icon := ""
	var color := Color.WHITE
	var stroke := 2.0

	func _draw() -> void:
		var s := minf(size.x, size.y)
		Icons.draw(self, icon, Rect2((size.x - s) * 0.5, (size.y - s) * 0.5, s, s), color, stroke)

	func set_icon(n: String) -> void:
		icon = n
		queue_redraw()


class FlagView extends Control:
	var country = null
	var radius := 2.0

	func set_country(c) -> void:
		country = c
		queue_redraw()

	func _draw() -> void:
		if country == null:
			return
		Flags.draw(self, Rect2(Vector2.ZERO, size), country, radius)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5), false, 1.0)


# ---------------------------------------------------------------- ek bileşenler

static func square_texture(px: int, col: Color) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)


static func style_slider(sl: HSlider) -> void:
	sl.custom_minimum_size = Vector2(0, 44)
	sl.add_theme_stylebox_override("slider", box(PANEL_HI, Color(0, 0, 0, 0), 1, 0, 0, Vector4(0, 2, 0, 2)))
	sl.add_theme_stylebox_override("grabber_area", box(PAPER, Color(0, 0, 0, 0), 1, 0, 0, Vector4(0, 2, 0, 2)))
	sl.add_theme_stylebox_override("grabber_area_highlight", box(PAPER, Color(0, 0, 0, 0), 1, 0, 0, Vector4(0, 2, 0, 2)))
	var knob := square_texture(26, PAPER)
	sl.add_theme_icon_override("grabber", knob)
	sl.add_theme_icon_override("grabber_highlight", knob)
	sl.add_theme_icon_override("grabber_disabled", knob)


static func slider_row(text: String, value: float, cb: Callable, lo: float = 0.0, hi: float = 1.0, step: float = 0.01) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := t(text, "body")
	l.custom_minimum_size = Vector2(220, 0)
	h.add_child(l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = value
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_slider(sl)
	h.add_child(sl)
	var vl := t("%d%%" % int(round(value * 100.0)), "value", MUTED)
	vl.add_theme_font_size_override("font_size", 24)
	vl.custom_minimum_size = Vector2(76, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(vl)
	sl.value_changed.connect(func(v: float):
		vl.text = "%d%%" % int(round(v * 100.0))
		cb.call(v))
	return h


static func toggle_row(text: String, value: bool, cb: Callable, hint: String = "") -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.add_child(t(text, "body"))
	if hint != "":
		var hl := t(hint, "small", FAINT)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hl)
	h.add_child(v)
	var sw := Switch.new()
	sw.button_pressed = value
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.toggled.connect(func(on: bool): cb.call(on))
	h.add_child(sw)
	return h


class Switch extends Button:
	var tt := 0.0

	func _init() -> void:
		toggle_mode = true
		custom_minimum_size = Vector2(76, 44)
		focus_mode = Control.FOCUS_NONE
		for n in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			add_theme_stylebox_override(n, StyleBoxEmpty.new())

	func _ready() -> void:
		tt = 1.0 if button_pressed else 0.0
		toggled.connect(func(on: bool):
			create_tween().tween_property(self, "tt", 1.0 if on else 0.0, 0.12))

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(0, (size.y - 36) * 0.5), Vector2(size.x, 36))
		var off := Color("0b0e12")
		var on := Color("ece6d6")
		var fillc := off.lerp(on, tt)
		var sb := StyleBoxFlat.new()
		sb.bg_color = fillc
		sb.set_corner_radius_all(3)
		sb.border_color = Color("39414b").lerp(on, tt)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		var kw := 26.0
		var kx := lerpf(r.position.x + 5.0, r.end.x - 5.0 - kw, tt)
		var kc := Color("646c77").lerp(Color("17130f"), tt)
		draw_rect(Rect2(kx, r.position.y + 5.0, kw, r.size.y - 10.0), kc)


## Satır düğmesi: yalnızca alt çizgisi olan düz satır. Seçili hâl için row_select kullan.
static func row_button(bg: Color = Color(0, 0, 0, 0), border: Color = LINE, h: float = 68.0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, h)
	b.focus_mode = Control.FOCUS_NONE
	var tint := bg.a > 0.0
	var base := bg if tint else Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", line_box(base, LINE))
	b.add_theme_stylebox_override("hover", line_box(base.lerp(PANEL_LIGHT, 0.7) if not tint else base.lightened(0.12), LINE))
	b.add_theme_stylebox_override("pressed", line_box(PANEL_HI, LINE))
	b.add_theme_stylebox_override("hover_pressed", line_box(PANEL_HI, LINE))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func row_select(b: Button, on: bool, accent: Color = PAPER) -> void:
	b.add_theme_stylebox_override("normal", line_box(PANEL_LIGHT, LINE, 5) if on else line_box(Color(0, 0, 0, 0), LINE))
	if on:
		var s := line_box(PANEL_LIGHT, accent, 5)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)


static func row_layout(b: Button, pad: float = 14.0) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = pad
	hb.offset_right = -pad
	hb.add_theme_constant_override("separation", 14)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hb)
	# içerik (ör. dile göre uzayan, satır kıran açıklama) satırdan yüksekse düğme de büyür; taşma/üst üste binme olmaz
	var h0: float = b.custom_minimum_size.y
	var fit := func():
		if is_instance_valid(b) and is_instance_valid(hb):
			var need: float = hb.get_combined_minimum_size().y + 14.0
			var want: float = maxf(h0, need)
			if absf(b.custom_minimum_size.y - want) > 0.5:
				b.custom_minimum_size.y = want
	hb.minimum_size_changed.connect(func(): fit.call_deferred())
	return hb


static func ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		ignore_mouse(c)


# ---------------------------------------------------------------- dokunmatik kaydırma
## Mobilde bir düğme/panel üstünden sürükleyince ScrollContainer kaydırsın diye: kaydırma alanlarının içindeki
## STOP filtreli denetimler PASS yapılır (olay üst ScrollContainer'a da ulaşır). Kaydırıcı, metin kutusu vb. dokunulmaz.
static var _ts_installed := false


static func install_touch_scroll(tree: SceneTree) -> void:
	if _ts_installed:
		return
	_ts_installed = true
	tree.node_added.connect(func(n: Node):
		if n is Control:
			_ts_fix.call_deferred(n))


static func _ts_fix(n: Node) -> void:
	if not is_instance_valid(n) or not (n is Control) or not n.is_inside_tree():
		return
	if n is Slider or n is ScrollBar or n is LineEdit or n is TextEdit or n is OptionButton or n is SpinBox:
		return
	if n.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			n.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		p = p.get_parent()
