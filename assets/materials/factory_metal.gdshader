shader_type spatial;
uniform vec4 paint : source_color = vec4(0.25, 0.33, 0.31, 1.0);
uniform float decay = 0.45;
varying vec3 p;
float hash(vec3 v) { return fract(sin(dot(v, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise(vec3 v) {
 vec3 i = floor(v); vec3 f = fract(v); f = f * f * (3.0 - 2.0 * f);
 return mix(mix(mix(hash(i), hash(i+vec3(1,0,0)), f.x), mix(hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)), f.x), f.y), mix(mix(hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)), f.x), mix(hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 float spots = noise(p * 5.0) * 0.7 + noise(p * 18.0) * 0.3;
 float rust = smoothstep(0.66 - decay * 0.3, 0.80, spots);
 ALBEDO = mix(paint.rgb, vec3(0.25,0.12,0.065), rust) * (0.88 + hash(floor(p * 190.0)) * 0.19);
 METALLIC = 0.45 * (1.0 - rust);
 ROUGHNESS = 0.63 + rust * 0.3;
}
