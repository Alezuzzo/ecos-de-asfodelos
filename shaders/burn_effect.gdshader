shader_type canvas_item;

// Uniforms para controlar o efeito
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.08;
uniform vec3 edge_color1 : source_color = vec3(1.0, 0.4, 0.0); // Laranja intenso
uniform vec3 edge_color2 : source_color = vec3(0.9, 0.0, 0.0); // Vermelho escuro
uniform sampler2D noise_texture;
uniform float noise_scale = 3.0;
uniform float distortion_strength = 0.15;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	// Múltiplas camadas de ruído para efeito mais orgânico
	vec2 noise_uv1 = UV * noise_scale + TIME * 0.05;
	vec2 noise_uv2 = UV * (noise_scale * 1.5) - TIME * 0.03;

	float noise1 = texture(noise_texture, noise_uv1).r;
	float noise2 = texture(noise_texture, noise_uv2).r;
	float combined_noise = mix(noise1, noise2, 0.5);

	// Distorção nas bordas para efeito de desintegração
	vec2 distorted_uv = UV + vec2(
		sin(UV.y * 10.0 + TIME) * distortion_strength * dissolve_progress,
		cos(UV.x * 10.0 + TIME) * distortion_strength * dissolve_progress
	);

	// Calcula threshold de dissolução com padrão irregular
	float dissolve_threshold = (1.0 - UV.y * 0.7) + combined_noise * 0.6;

	// Adiciona variação horizontal para efeito mais caótico
	dissolve_threshold += sin(UV.x * 20.0) * 0.1;

	// Calcula quanto este pixel está dissolvido
	float dissolve_amount = dissolve_threshold - dissolve_progress * 1.3;

	vec3 final_color = original_color.rgb;
	float final_alpha = original_color.a;

	if (dissolve_amount < -edge_thickness) {
		// Completamente dissolvido - transparente
		final_alpha = 0.0;
	} else if (dissolve_amount < edge_thickness) {
		// Na borda da dissolução - efeito de queima
		float edge_factor = (dissolve_amount + edge_thickness) / (edge_thickness * 2.0);

		// Gradiente de cor nas bordas (laranja -> vermelho -> preto)
		vec3 burn_glow;
		if (edge_factor > 0.5) {
			burn_glow = mix(edge_color2, edge_color1, (edge_factor - 0.5) * 2.0);
		} else {
			burn_glow = mix(vec3(0.1, 0.0, 0.0), edge_color2, edge_factor * 2.0);
		}

		// Adiciona brilho intenso nas bordas
		burn_glow += edge_color1 * (1.0 - edge_factor) * 1.5;

		// Mistura com a cor original
		final_color = mix(burn_glow, original_color.rgb, edge_factor * 0.3);

		// Escurece e dissolve gradualmente
		final_alpha *= edge_factor;

		// Adiciona efeito de "pixels queimando"
		float pixel_noise = fract(sin(dot(UV * 100.0, vec2(12.9898, 78.233))) * 43758.5453);
		if (pixel_noise > edge_factor) {
			final_alpha *= 0.3;
		}
	}

	COLOR = vec4(final_color, final_alpha);
}
