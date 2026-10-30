shader_type spatial;
uniform vec3 paint : source_color = vec3(0.1,0.3,0.4);
uniform vec3 plaster : source_color = vec3(0.65,0.61,0.48);
uniform float clinical = 0.0;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float u=abs(wn.x)>0.5?wp.z:wp.x;
 float blot=hash(floor(vec2(u*2.0,wp.y*2.0)));
 vec3 c=mix(paint,plaster,smoothstep(1.55,1.62,wp.y));
 float seam=step(0.018,fract(u*1.6))*step(0.018,fract(wp.y*2.5));
 c=mix(c,c*mix(0.5,1.0,seam),clinical);
 float band=step(1.35,wp.y)*step(wp.y,1.48);
 c=mix(c,vec3(0.67,0.47,0.1),band);
 float base_dirt=(1.0-smoothstep(0.0,1.0,wp.y))*0.32;
 float streak=pow(hash(vec2(floor(u*14.0),1.0)),14.0)*0.2;
 ALBEDO=c*(0.91+blot*0.065-base_dirt-streak); ROUGHNESS=mix(0.88,0.53,clinical); SPECULAR=0.25;
}
