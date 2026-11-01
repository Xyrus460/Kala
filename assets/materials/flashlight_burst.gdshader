shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform float age = 0.0;
uniform float opacity = 1.0;
uniform float heat = 1.0;
uniform float seed = 0.0;
uniform int effect_mode = 0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
float turbulence(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.07 + 13.2) * 0.28 + noise(p * 4.13) * 0.17;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float n = turbulence(p * 3.4 + vec2(seed, -age * 1.8));
	float density = (1.0 - smoothstep(0.24, 1.0, radius + (n - 0.5) * 0.68));
	density *= 1.0 - smoothstep(0.70, 1.0, radius);
	if (density < 0.005 && effect_mode != 1) {
		discard;
	}
	if (effect_mode == 1) {
		float ring = smoothstep(0.70, 0.85, radius) * (1.0 - smoothstep(0.86, 1.0, radius));
		ALBEDO = vec3(0.65, 0.52, 0.32);
		EMISSION = vec3(1.0, 0.43, 0.08) * opacity * 0.8;
		ALPHA = ring * opacity * 0.32;
	} else if (effect_mode == 2) {
		ALBEDO = vec3(0.035, 0.031, 0.027);
		ALPHA = density * opacity * (0.5 + n * 0.35);
	} else {
		float core = (1.0 - smoothstep(0.0, 0.78, radius)) * (0.55 + n * 0.6);
		vec3 smoke = mix(vec3(0.035, 0.042, 0.040), vec3(0.23, 0.24, 0.22), n);
		vec3 flame = mix(vec3(0.8, 0.065, 0.005), vec3(1.0, 0.78, 0.32), smoothstep(0.18, 0.8, core));
		float tongues = smoothstep(0.20, 0.65, n + core * 0.28);
		ALBEDO = mix(smoke, flame, heat);
		EMISSION = flame * heat * (0.8 + core * 3.5) * tongues;
		ALPHA = density * opacity * mix(0.70, tongues, heat);
	}
}
