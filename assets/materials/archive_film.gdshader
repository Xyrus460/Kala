shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float film_time=0.0;
uniform float fade=1.0;
uniform float damage=0.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
void fragment() {
 vec2 uv=SCREEN_UV;
 float tear=step(0.985,hash(vec2(floor(film_time*7.0),1.0)))*damage;
 uv.x+=sin(uv.y*90.0+film_time*6.0)*tear*0.018;
 vec3 col=texture(screen_texture,uv).rgb;
 float luminance=dot(col,vec3(0.2126,0.7152,0.0722));
 col=mix(col,vec3(luminance)*vec3(1.06,1.0,0.85),0.62);
 col+=vec3(hash(floor(uv*vec2(960,540))+floor(film_time*24.0))*0.08-0.04);
 float vignette=clamp(1.15-dot((uv-0.5)*vec2(1.1,1.3),(uv-0.5)*vec2(1.1,1.3)),0.25,1.0);
 float scratch=step(0.9994,hash(vec2(floor(uv.x*720.0),floor(film_time*5.0))));
 col=col*vignette+scratch*0.12;
 COLOR=vec4(col*(1.0-fade),1.0);
}
