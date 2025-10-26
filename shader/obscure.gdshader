shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.5;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.0;
uniform float vignette_size : hint_range(0.1, 1.0) = 0.6;
uniform sampler2D screen_texture : hint_screen_texture;
void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(screen_texture, uv);

    // Calcular distancia desde el centro
    vec2 center = vec2(0.5, 0.5);
    float distance = length(uv - center);

    // Crear efecto de viñeta
    float vignette = smoothstep(vignette_size, vignette_size + 0.3, distance);
    vignette = pow(vignette, vignette_strength);

    // Aplicar oscuridad general y viñeta
    float total_darkness = darkness + (vignette * (1.0 - darkness));
    color.rgb *= (1.0 - total_darkness);

    COLOR = color;
}