shader_type canvas_item;

uniform float radius : hint_range(0.1, 2.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;
uniform float noise_scale = 16.0;
uniform float noise_speed = 1.0;
uniform vec4 color_inside : source_color = vec4 (0.051, 0.051, 0.051, 0.282);
uniform vec4 color_edge : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool use_circle_shape = false;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Simple 2D noise
float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // Normaliza de -1 a 1
    float dist = length(uv);

    // Forma base: círculo o cuadrado
    float base_shape = use_circle_shape ? dist : max(abs(uv.x), abs(uv.y));

    // Borde difuminado
    float edge = smoothstep(radius, radius - edge_softness, base_shape);

    // Animación de bruma
    float t = TIME * noise_speed;
    float n = noise(uv * noise_scale + vec2(t, t));
    edge += (n - 0.5) * 0.2; // Añade distorsión de bruma

    edge = clamp(edge, 0.0, 1.0);

    // Color final basado en el borde
    COLOR = mix(color_inside, color_edge, edge);
}
