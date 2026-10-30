shader_type canvas_item;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = smoothstep(0.45, 1.4, length(p));
	float grain = fract(sin(dot(UV + TIME * 0.001, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(mix(vec3(0.015, 0.024, 0.017), vec3(0.23, 0.02, 0.015), damage), edge * (0.2 + damage * 0.45) + grain * 0.025);
}
