shader_type canvas_item;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	vec2 pixel = floor(FRAGCOORD.xy);
	float noise = fract(sin(dot(pixel + floor(TIME * 8.0), vec2(12.9898, 78.233))) * 43758.5453);
	float edge = smoothstep(0.35, 1.45, length(p));
	float scan = step(0.5, fract(FRAGCOORD.y / 3.0));
	COLOR = vec4(vec3(noise * 0.35), 0.045 + edge * 0.24 + scan * 0.018);
}
