shader_type canvas_item;

const int MAX_HOLES = 16;

uniform int holes_count : hint_range(0, MAX_HOLES) = 0;
uniform vec2 holes_pos[MAX_HOLES];
uniform float holes_radius[MAX_HOLES];
uniform vec4 dark_color  = vec4(0.0, 0.0, 0.0, 0.85);
uniform float edge_frac = 0.25; // fracción del radio usada para suavizar bordes

void fragment() {
    vec2 uv = UV;
    float hole = 0.0;
    for (int i = 0; i < holes_count; i++) {
        vec2 p = holes_pos[i];
        float r = holes_radius[i];
        float d = distance(uv, p);
        float edge = r * edge_frac;
        float s = 1.0 - smoothstep(r - edge, r + edge, d);
        hole = max(hole, s);
    }
    vec4 outc = dark_color;
    outc.a *= (1.0 - hole);
    COLOR = outc;
}