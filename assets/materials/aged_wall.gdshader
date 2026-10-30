shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 plaster : source_color = vec3(0.46, 0.45, 0.39);
uniform vec3 paint : source_color = vec3(0.17, 0.27, 0.25);
uniform vec3 masonry : source_color = vec3(0.29, 0.15, 0.09);
uniform float decay = 0.65;
uniform float pattern = 0.0;
uniform float seed = 1.0;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453123);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){return noise(p)*0.55+noise(p*2.03)*0.27+noise(p*4.07)*0.12+noise(p*8.11)*0.06;}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	vec2 p = abs(wn.x)>abs(wn.z)?wp.zy:wp.xy;
	if(abs(wn.y)>0.7)p=wp.xz;
	p+=vec2(seed*7.13,0.0);
	float wear=fbm(p*1.7);
	float pits=noise(p*61.0);
	float chips=smoothstep(0.57-decay*0.18,0.65-decay*0.18,wear);
	vec2 brick=p*vec2(1.8,4.1);brick.x+=mod(floor(brick.y),2.0)*0.5;
	vec2 cell=fract(brick);
	float mortar=step(0.055,cell.x)*step(0.075,cell.y);
	vec3 brick_col=masonry*(0.66+hash(floor(brick))*0.55);
	brick_col=mix(vec3(0.105,0.101,0.086),brick_col,mortar);
	float low_paint=1.0-smoothstep(1.2,1.8,wp.y+wear*0.35);
	vec3 surface=mix(plaster,paint,low_paint);
	if(pattern>1.5){float panel=step(0.025,fract(p.x*0.8))*step(0.025,fract(p.y*0.8));surface*=mix(0.43,1.0,panel);}
	float broken=chips*(pattern<0.5?0.35:1.0)*decay;
	surface=mix(surface,brick_col,broken);
	float streak=fbm(vec2(p.x*9.0,p.y*0.18+seed));
	surface*=0.65+0.42*wear;
	surface*=1.0-smoothstep(0.53,0.72,streak)*decay*0.60;
	surface*=mix(0.68,1.0,smoothstep(-0.4,0.8,wp.y));
	ALBEDO=surface*(0.90+pits*0.15);
	ROUGHNESS=clamp(0.79+wear*0.20-broken*0.12,0.5,1.0);
	SPECULAR=0.22;
	float height=wear*0.20+pits*0.006-broken*0.065;
	NORMAL_MAP=normalize(vec3(-dFdx(height)*15.0,-dFdy(height)*15.0,1.0))*0.5+0.5;
	NORMAL_MAP_DEPTH=0.45;
}
