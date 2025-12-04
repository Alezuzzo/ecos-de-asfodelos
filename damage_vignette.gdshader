shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Calcula a distância do centro (0.5, 0.5)
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);

	// Cria a vinheta (mais forte nas bordas)
	float vignette = smoothstep(0.3, 0.7, dist) * vignette_intensity;

	// Cor vermelha com a intensidade da vinheta
	vec3 red = vec3(1.0, 0.0, 0.0);
	COLOR = vec4(red, vignette * vignette_opacity);
}
