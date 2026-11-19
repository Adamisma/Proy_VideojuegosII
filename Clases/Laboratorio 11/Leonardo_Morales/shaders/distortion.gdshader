shader_type canvas_item;

// ====================================================================
// Laboratorio 10 - Sección 25: Shader de Distorsión Ondulatoria
// ====================================================================
// Modifica dinámicamente las coordenadas UV mediante una onda senoidal
// animada por TIME para simular calor, distorsión de energía o refracción.

uniform float amplitude = 0.008;
uniform float frequency = 18.0;
uniform float speed = 2.5;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(
		UV.y * frequency
		+ TIME * speed
	) * amplitude;
	COLOR = texture(TEXTURE, uv);
}
