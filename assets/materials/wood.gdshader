shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 wood_color : source_color = vec3(0.3, 0.19, 0.1);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float grain=sin(p.y*8.0+p.x*1.6+sin(p.z*5.0)*0.3);
	float fine=sin(p.y*150.0+sin(p.x*4.0+p.z*9.0)*3.0);
	float pores=fract(sin(dot(floor(p.xy*300.0),vec2(12.98,78.23)))*43758.54);
	ALBEDO=wood_color*(0.91+grain*0.06+fine*0.035+pores*0.035);
	ROUGHNESS=0.65+pores*0.1; SPECULAR=0.3;
}
