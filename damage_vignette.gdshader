shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Normaliza as coordenadas UV para o centro da tela
	vec2 center = vec2(0.5, 0.5);
	vec2 uv = UV - center;

	// Ajusta a proporção da tela
	uv.x *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;

	// Calcula a distância do centro
	float dist = length(uv);

	// Cria a vinheta (mais forte nas bordas)
	float vignette = smoothstep(0.2, 1.0, dist) * vignette_intensity;

	// Cor vermelha com a intensidade da vinheta
	vec3 red = vec3(1.0, 0.0, 0.0);
	COLOR = vec4(red, vignette * vignette_opacity);
}
