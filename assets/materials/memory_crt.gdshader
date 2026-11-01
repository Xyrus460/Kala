shader_type spatial;
render_mode unshaded;
uniform vec4 signal_color : source_color = vec4(0.14, 0.33, 0.30, 1.0);
uniform float intensity = 0.2;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float vignette = max(0.1, 1.0 - dot(p * 0.65, p * 0.65));
	float scan = 0.83 + 0.17 * sin(UV.y * 520.0);
	float noise = fract(sin(dot(floor(UV * 180.0), vec2(12.9898, 78.233)) + floor(TIME * 12.0)) * 43758.5453);
	vec3 glow = signal_color.rgb * (intensity + noise * 0.09) * scan * vignette;
	ALBEDO = glow;
	EMISSION = glow * 0.6;
}
