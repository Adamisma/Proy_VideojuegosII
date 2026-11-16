shader_type canvas_item;

// ====================================================================
// Laboratorio 10 - Sección 26: Shader de Dissolve (Desintegración)
// ====================================================================
// Compara el canal rojo de una textura de ruido procedural contra un umbral (threshold).
// Genera un borde incandescente antes de volver transparente el fragmento.

uniform sampler2D noise_texture;
uniform float threshold : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.001, 0.2) = 0.06;
uniform vec4 edge_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float noise_value = texture(noise_texture, UV).r;
	
	float visible_mask = step(threshold, noise_value);
	float edge_mask = step(threshold, noise_value) - step(threshold + edge_width, noise_value);
	
	vec3 final_rgb = mix(tex.rgb, edge_color.rgb, edge_mask);
	COLOR = vec4(final_rgb, tex.a * visible_mask);
}
