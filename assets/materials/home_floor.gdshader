shader_type spatial;
uniform vec3 tint : source_color = vec3(0.40,0.29,0.19);
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float row = floor(world.x / 0.18);
 vec2 uv = vec2(world.x / 0.18, (world.z + hash(vec2(row,0.0))*1.2)/1.35);
 vec2 cell = fract(uv);
 float seam = max(1.0-smoothstep(0.0,0.012,min(cell.x,1.0-cell.x)),1.0-smoothstep(0.0,0.003,min(cell.y,1.0-cell.y)));
 float grain = sin(world.x*140.0+sin(world.z*4.0+row)*2.0) * (1.0-smoothstep(0.2,1.4,fwidth(world.x)*140.0));
 float board = hash(floor(uv));
 ALBEDO = tint * (0.86 + board*0.24 + grain*0.055) * (1.0-seam*0.43);
 ROUGHNESS = 0.54 + board*0.13; SPECULAR = 0.35;
}
