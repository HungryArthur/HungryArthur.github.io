shader_type canvas_item;

uniform float elapsed = 0.0;
uniform float ripple_time = 0.24;
uniform float clock_period = 8.0;

varying vec3 mark_data;
varying vec4 vertex_tint;

void vertex() {
	// Radius, birth time and lifetime are uploaded only on spawn or slot reuse.
	// A half-float birth time may round slightly into the future. Use the
	// shortest signed clock difference before clamping that rounding to zero.
	float age = max(mod(elapsed - INSTANCE_CUSTOM.y + clock_period * 0.5, clock_period)
		- clock_period * 0.5, 0.0);
	mark_data = vec3(INSTANCE_CUSTOM.x, age, INSTANCE_CUSTOM.z);
	vertex_tint = COLOR;
}

void fragment() {
	float radius = mark_data.x;
	float age = mark_data.y;
	float distance_to_center = length((UV * 2.0 - 1.0) * (radius + 2.5));
	float edge = max(fwidth(distance_to_center) * 0.5, 0.1);
	float fade = clamp(1.0 - age / mark_data.z, 0.0, 1.0);
	float patch_alpha = (1.0 - smoothstep(radius - edge, radius + edge, distance_to_center)) * 0.22 * fade;
	float progress = clamp(age / ripple_time, 0.0, 1.0);
	float ring_radius = mix(0.8, radius + 2.0, progress);
	float ring_alpha = (1.0 - smoothstep(0.35 - edge, 0.35 + edge, abs(distance_to_center - ring_radius)))
		* 0.48 * (1.0 - progress);
	// Composite the pale ripple over the dark wet patch in the same fragment.
	float alpha = ring_alpha + patch_alpha * (1.0 - ring_alpha);
	vec3 premultiplied = vec3(0.66, 0.80, 0.91) * ring_alpha
		+ vec3(0.10, 0.17, 0.22) * patch_alpha * (1.0 - ring_alpha);
	COLOR = vec4(premultiplied / max(alpha, 0.00001), alpha) * vertex_tint;
}
