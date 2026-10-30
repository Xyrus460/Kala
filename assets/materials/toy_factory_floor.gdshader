shader_type spatial;
uniform vec3 base_color : source_color = vec3(0.57,0.55,0.45);
uniform float colorful = 1.0;
varying vec3 wp;
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex(){ wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 tile=wp.xz/1.15; vec2 grid=floor(tile); vec2 uv=fract(tile);
 float index=mod(grid.x+grid.y*3.0,7.0);
 vec3 c=base_color;
 if(index<1.0) c=mix(c,vec3(0.54,0.11,0.08),colorful);
 else if(index<2.0) c=mix(c,vec3(0.08,0.24,0.40),colorful);
 else if(index<3.0) c=mix(c,vec3(0.69,0.49,0.08),colorful);
 float grout=step(0.014,uv.x)*step(0.014,uv.y)*step(uv.x,0.986)*step(uv.y,0.986);
 float grime=hash(floor(wp.xz*6.0))*0.065+sin(wp.x*0.8+sin(wp.z*0.72))*0.045;
 ALBEDO=mix(vec3(0.08,0.085,0.076),c*(0.91+hash(grid)*0.1-grime),grout);
 ROUGHNESS=0.66+grime; SPECULAR=0.32;
}
