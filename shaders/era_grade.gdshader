shader_type canvas_item;
// Tarihî dönem renk derecelendirmesi: ekranın tamamı (harita + arayüz) dönemin paletine çekilir.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec3 shadow = vec3(0.07, 0.06, 0.05);
uniform vec3 mid = vec3(0.50, 0.42, 0.30);
uniform vec3 light = vec3(0.95, 0.90, 0.76);
uniform float amount = 0.8;
uniform float vignette = 0.35;
uniform float grain = 0.035;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 g = l < 0.5 ? mix(shadow, mid, l * 2.0) : mix(mid, light, (l - 0.5) * 2.0);
	vec3 o = mix(c, g, amount);
	vec2 d = SCREEN_UV - vec2(0.5);
	o *= 1.0 - vignette * smoothstep(0.35, 0.85, length(d * vec2(1.0, 1.2)));
	o += (hash(SCREEN_UV * vec2(1280.0, 720.0)) - 0.5) * grain;
	COLOR = vec4(o, 1.0);
}
