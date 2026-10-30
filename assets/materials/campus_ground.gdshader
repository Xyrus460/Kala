shader_type spatial;
render_mode diffuse_burley;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world.xz * 2.2;
 vec2 cell = floor(p + vec2(mod(floor(p.y), 2.0) * 0.5, 0.0));
 vec2 uv = fract(p + vec2(mod(floor(p.y), 2.0) * 0.5, 0.0));
 float seam = step(0.04, uv.x) * step(0.04, uv.y);
 vec3 paving = mix(vec3(0.28, 0.31, 0.29), vec3(0.46, 0.47, 0.41), hash(cell));
 ALBEDO = mix(vec3(0.18, 0.22, 0.19), paving, seam) + (hash(world.xz * 220.0) - 0.5) * 0.04;
 ROUGHNESS = 0.94;
}
