shader_type canvas_item;

// O NOME ABAIXO DEVE SER EXATAMENTE "vignette_opacity"
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.8, 0.0, 0.0, 1.0); // Vermelho

void fragment() {
    // Usa UV para garantir que funcione em qualquer resolução
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    // Cria o círculo da vinheta
    // smoothstep(borda_interna, borda_externa, distancia)
    float vignette = smoothstep(0.2, 0.8, dist);

    // Aplica a cor e a opacidade controlada pelo script
    vec4 final_color = vignette_color;
    final_color.a = vignette * vignette_opacity;

    COLOR = final_color;
}