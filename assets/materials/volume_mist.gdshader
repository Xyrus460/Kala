shader_type fog;
uniform float density = 0.13;
uniform vec3 tint : source_color = vec3(0.53, 0.62, 0.66);
uniform float drift = 0.18;
float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise3(vec3 p) {
	vec3 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),
		mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void fog() {
	vec3 p = WORLD_POSITION * vec3(0.48,0.8,0.48) + vec3(TIME*drift, TIME*0.025, -TIME*drift*0.4);
	float wisps = noise3(p)*0.72 + noise3(p*2.13)*0.28;
	float edge = smoothstep(0.0, 0.65, -SDF);
	DENSITY = density * smoothstep(0.18, 0.85, wisps) * edge;
	ALBEDO = tint;
}
