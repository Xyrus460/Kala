shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 shaft_color : source_color = vec3(1.0, 0.82, 0.60);
uniform float intensity = 0.025;
uniform bool roof_beam = false;
void fragment() {
	float edge = smoothstep(0.0, 0.20, UV.x) * smoothstep(0.0, 0.20, 1.0 - UV.x);
	float fade = roof_beam ? smoothstep(0.0, 0.22, UV.y) * smoothstep(0.0, 0.12, 1.0 - UV.y) : pow(clamp(1.0 - UV.y, 0.0, 1.0), 1.8);
	float facing = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	ALBEDO = shaft_color;
	ALPHA = intensity * fade * (roof_beam ? edge : facing);
}
