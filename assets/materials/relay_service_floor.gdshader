shader_type spatial;
varying vec3 wp;
void vertex() { wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 cell = abs(fract(wp.xz * 0.5 + 0.001) - 0.5);
	float seam = smoothstep(0.485, 0.498, max(cell.x, cell.y));
	float stain = sin(wp.x * 1.7 + sin(wp.z * 0.7)) * sin(wp.z * 1.1) * 0.025;
	ALBEDO = mix(vec3(0.23,0.27,0.25)+stain,vec3(0.10,0.13,0.12),seam * 0.45);
	ROUGHNESS = 0.91; SPECULAR = 0.2;
}
