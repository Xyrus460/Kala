shader_type spatial;
uniform vec3 paint : source_color = vec3(0.18,0.25,0.24);
uniform vec3 plaster : source_color = vec3(0.43,0.43,0.37);
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
 float u=abs(wn.x)>0.5?wp.z:wp.x;
 vec2 p=vec2(u,wp.y);
 float damp=noise(p*0.65)*noise(p*2.7);
 float chips=smoothstep(0.56,0.73,noise(p*12.0)+damp*0.4);
 vec3 c=mix(paint,plaster,smoothstep(1.58,1.63,wp.y));
 c=mix(c,plaster*0.65,chips*0.48);
 float drip=pow(noise(vec2(u*9.0,0)),7.0)*(0.5+0.5*sin(wp.y*0.45));
 float base=1.0-smoothstep(0.0,0.55,wp.y);
 ALBEDO=c*(0.92+noise(p*90.0)*0.09-damp*0.28-drip*0.6-base*0.24);
 ROUGHNESS=0.91; SPECULAR=0.2;
}
