// Subtle world-space brightness variation so tiled ground stops looking flat.
shader_type canvas_item;

uniform float variation_strength : hint_range(0.0, 0.5) = 0.10;
uniform float noise_scale = 0.06;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float n = value_noise(world_pos * noise_scale);
	col.rgb *= 1.0 + (n - 0.5) * 2.0 * variation_strength;
	COLOR = col;
}
