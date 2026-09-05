shader_type canvas_item;

uniform float occlusion_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float fade_ratio : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	if (UV.y < fade_ratio) {
		color.a *= occlusion_alpha;
	}
	COLOR = color;
}
