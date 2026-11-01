shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 world_point;
varying vec3 world_normal;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 p=world_point.xz/0.6;
 vec2 edge=abs(fract(p)-0.5);
 float line=smoothstep(0.485-fwidth(p.x),0.495,max(edge.x,edge.y));
 float fleck=fract(sin(dot(floor(p),vec2(12.9898,78.233)))*43758.5453);
 vec3 tile=mix(vec3(0.40,0.46,0.43),vec3(0.49,0.54,0.50),fleck*0.25);
 ALBEDO=world_normal.y>0.5?mix(tile,vec3(0.29,0.34,0.31),line*0.32):vec3(0.64,0.67,0.62);
 ROUGHNESS=0.86;
}
