shader_type spatial;
uniform vec4 tint : source_color = vec4(0.8,0.75,0.65,1.0);
uniform float tile_size = 0.65;
uniform float tiled = 0.0;
varying vec3 world;
void vertex(){ world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 cell=abs(fract(world.xz/tile_size)-0.5);
 float grout=smoothstep(0.48,0.495,max(cell.x,cell.y))*tiled;
 float grain=sin(world.x*137.0+sin(world.z*71.0))*sin(world.z*143.0)*0.009;
 ALBEDO=tint.rgb*(1.0-grout*0.16+grain); ROUGHNESS=mix(0.9,0.42,tiled);
}
