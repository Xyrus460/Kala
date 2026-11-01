shader_type canvas_item;

void fragment() {
	vec4 ink = texture(TEXTURE, UV) * COLOR;
	vec2 pixel = floor(FRAGCOORD.xy);
	float fleck = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453);
	ink.a *= mix(0.30, 1.0, step(0.045, fleck));
	COLOR = ink;
}
