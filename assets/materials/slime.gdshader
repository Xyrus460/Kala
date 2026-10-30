shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 tint : source_color = vec4(0.19,0.36,0.22,0.82);
void fragment(){
 float d=length(UV*2.0-1.0); float edge=1.0-smoothstep(0.75,1.0,d);
 float veins=sin(UV.x*58.0+sin(UV.y*26.0+TIME)*3.0)*sin(UV.y*47.0+TIME*0.7);
 ALBEDO=tint.rgb*(0.7+veins*0.16); ALPHA=edge*tint.a;
 ROUGHNESS=0.18; SPECULAR=0.85; EMISSION=tint.rgb*0.18;
}
