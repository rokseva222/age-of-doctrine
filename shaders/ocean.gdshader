shader_type canvas_item;
// Deniz: koyu lacivert, ortası biraz açık; kenarlara doğru vinyet.
uniform vec4 center_col : source_color = vec4(0.075, 0.20, 0.33, 1.0);
uniform vec4 edge_col : source_color = vec4(0.035, 0.10, 0.18, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = distance(uv * vec2(1.3, 1.0), vec2(0.65, 0.48));
	vec3 c = mix(center_col.rgb, edge_col.rgb, smoothstep(0.05, 0.85, d));
	COLOR = vec4(c, 1.0);
}
