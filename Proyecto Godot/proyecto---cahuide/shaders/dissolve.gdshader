shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float burn_size : hint_range(0.0, 0.2) = 0.06;

float pseudo_noise(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 main_tex = texture(TEXTURE, UV);
	if (main_tex.a <= 0.01) {
		discard;
	}

	float noise_val = pseudo_noise(UV * 25.0);

	if (noise_val < threshold) {
		discard;
	}

	if (noise_val < threshold + burn_size && threshold > 0.01) {
		main_tex.rgb = burn_color.rgb;
	}

	COLOR = main_tex;
}
