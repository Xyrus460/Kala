shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
void fragment() {
	vec3 scene = textureLod(screen_texture, SCREEN_UV, 2.0).rgb;
	float edge = smoothstep(0.25, 0.8, distance(SCREEN_UV, vec2(0.5)));
	COLOR = vec4(scene * (0.42 - edge * 0.15), 1.0);
}
