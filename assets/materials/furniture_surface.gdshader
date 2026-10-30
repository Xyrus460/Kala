shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.6, 0.45, 0.3, 1.0);
uniform bool fabric = false;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void fragment() {
 vec3 p = local_point;
 float grain = sin(p.y * 260.0 + sin(p.x * 21.0 + p.z * 18.0) * 3.0);
 float pores = hash(floor(p.xy * 900.0 + p.z * 23.0));
 if (fabric) {
  float weave = sin(p.x * 1400.0) * sin((p.y + p.z) * 1400.0);
  ALBEDO = tint.rgb * (0.96 + pores * 0.045 + weave * 0.025);
  ROUGHNESS = 0.94; SPECULAR = 0.18;
 } else {
  ALBEDO = tint.rgb * (0.89 + grain * 0.055 + pores * 0.055);
  ROUGHNESS = 0.50 + pores * 0.18; SPECULAR = 0.32;
 }
}
