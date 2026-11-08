shader_type canvas_item;
// Eyalet dolgusu: renk, işgal taraması ve ton farkı tek bir arama dokusundan (LUT) gelir.
uniform sampler2D lut : filter_nearest, repeat_disable;
uniform float zoom = 1.0;
uniform float stripe_px = 6.0;
varying vec4 v_fill;
varying vec4 v_stripe;
varying vec2 v_world;

void vertex() {
	int id = int(UV.x + 0.5);
	vec4 f = texelFetch(lut, ivec2(id, 0), 0);
	float h = fract(sin(float(id) * 12.9898) * 43758.5453);
	f.rgb *= 0.93 + h * 0.12;
	v_fill = f;
	v_stripe = texelFetch(lut, ivec2(id, 1), 0);
	v_world = VERTEX;
}

void fragment() {
	vec4 c = v_fill;
	if (v_stripe.a > 0.01) {
		float s = fract((v_world.x + v_world.y) * zoom / (stripe_px * 2.0));
		float m = step(0.5, s);
		c.rgb = mix(c.rgb * 0.82, v_stripe.rgb, 0.80 * m);
	}
	COLOR = c;
}
