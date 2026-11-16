shader_type canvas_item;

// ====================================================================
// Laboratorio 10 - Sección 24: Shader de Pulso Procedural con TIME
// ====================================================================
// Reutiliza la función senoidal de la semana 9 sobre la variable TIME
// para producir un pulso oscilante continuo de brillo sin llamadas de CPU.

uniform float speed = 3.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = (sin(TIME * speed) * 0.5 + 0.5);
	vec3 boosted = tex.rgb * (1.0 + pulse * intensity);
	COLOR = vec4(boosted, tex.a);
}
