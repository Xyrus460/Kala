shader_type spatial;
render_mode cull_disabled, diffuse_burley;
void fragment(){
	vec2 p=UV*2.0-1.0;
	float shape=pow(abs(p.x),1.4)+p.y*p.y;
	if(shape>0.92+sin(p.x*35.0)*0.035) discard;
	float vein=1.0-smoothstep(0.02,0.08,abs(p.y));
	ALBEDO=mix(vec3(0.12,0.22,0.105),vec3(0.29,0.39,0.19),UV.x)* (0.85+vein*0.2);
	ROUGHNESS=0.9; BACKLIGHT=vec3(0.09,0.15,0.04);
}
