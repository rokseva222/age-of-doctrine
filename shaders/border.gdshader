shader_type canvas_item;
// Sınırlar: genişlik ekranda sabit kalır (zoom'a göre ters ölçeklenir); tür sahiplikten seçilir.
uniform sampler2D lut : filter_nearest, repeat_disable;
uniform float zoom = 1.0;
uniform float w_prov = 0.8;
uniform float w_country = 1.9;
uniform float w_coast = 1.0;
uniform vec4 c_prov = vec4(0.0, 0.0, 0.0, 0.30);
uniform vec4 c_country = vec4(0.04, 0.05, 0.08, 0.92);
uniform vec4 c_coast = vec4(0.03, 0.10, 0.18, 0.60);
uniform float glow_mode = 0.0;
uniform float glow_w = 12.0;
uniform vec4 glow_c = vec4(0.25, 0.55, 0.8, 0.18);
varying vec4 v_col;

int owner_of(int pid) {
	vec4 t = texelFetch(lut, ivec2(pid, 2), 0);
	return int(t.r * 255.0 + 0.5) + 256 * int(t.g * 255.0 + 0.5);
}

void vertex() {
	int a = int(UV.x + 0.5);
	float bf = UV.y;
	vec2 dir = (COLOR.rg - vec2(0.5)) * 5.0;
	float w = 0.0;
	vec4 col = vec4(0.0);
	if (glow_mode > 0.5) {
		if (bf < -0.5) {
			w = glow_w;
			col = glow_c;
		}
	} else if (bf < -0.5) {
		w = w_coast;
		col = c_coast;
	} else {
		int b = int(bf + 0.5);
		if (owner_of(a) == owner_of(b)) {
			w = w_prov;
			col = c_prov;
		} else {
			w = w_country;
			col = c_country;
		}
	}
	if (glow_mode > 0.5) {
		dir = normalize(dir + vec2(0.0001));   // parıltıda sivri uç olmasın
	}
	VERTEX += dir * (w * 0.5 / zoom);
	v_col = col;
}

void fragment() {
	COLOR = v_col;
}
