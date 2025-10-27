shader_type canvas_item;

uniform vec4 dark_color  = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D light_mask;       // textura generada por el Viewport (Polygon2D blancos)
uniform vec2 viewport_size = vec2(1024.0, 768.0); // asignar desde GDScript
uniform float global_edge_smooth = 0.02; // suaviza transiciones si la máscara tiene bordes

void fragment() {
    vec2 suv = SCREEN_UV;
    // muestreo de la máscara; si no hay textura devuelve 0.0 (oscuro)
    float mask_val = 0.0;
    #ifdef TEXTURE_LIGHT_MASK_EXISTS
        mask_val = texture(light_mask, suv).r;
    #else
        // si el material no tiene la textura asignada será 0
        mask_val = 0.0;
    #endif

    // pequeño suavizado adicional por shader (opcional)
    mask_val = smoothstep(0.0, 1.0, mask_val);

    vec4 outc = dark_color;
    // where mask_val == 1 => fully visible (no alpha), mask_val == 0 => fully dark
    outc.a *= (1.0 - mask_val);

    COLOR = outc;
}