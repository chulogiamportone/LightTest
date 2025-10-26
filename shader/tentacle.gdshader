shader_type canvas_item;

// 🎨 Colores personalizables
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);   // Fondo oscuro
uniform vec4 tentacle_color : source_color = vec4(0.05, 0.05, 0.05, 1.0); // Tentáculos

// 📍 Posición del centro (relativo al rectángulo, de 0 a 1)
uniform vec2 center = vec2(0.5, 0.5);

// 🐙 Parámetros de tentáculos
uniform int tentacle_count : hint_range(2, 16) = 6;
uniform float tentacle_thickness : hint_range(0.01, 0.3) = 0.1;
uniform float tentacle_wiggle : hint_range(0.0, 1.0) = 0.25;
uniform float tentacle_speed : hint_range(0.1, 5.0) = 1.5;
uniform float tentacle_sharpness : hint_range(0.5, 10.0) = 4.0;
uniform float movement_detail : hint_range(-20.0, 20.0) = 8.0;

// 🌫️ Parámetros de desvanecimiento hacia los bordes
uniform float fade_start : hint_range(0.0, 1.0) = 0.8;
uniform float fade_end : hint_range(0.0, 1.0) = 1.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    vec2 pos = UV - center;
    float radius = length(pos);
    float angle = atan(pos.y, pos.x);
    float norm_angle = fract((angle + PI) / (2.0 * PI) * float(tentacle_count));

    float t = TIME * tentacle_speed;
    float wiggle = noise(vec2(angle * movement_detail, radius * movement_detail + t));

    float tentacle_line = abs(norm_angle - 0.5 + (wiggle - 0.5) * tentacle_wiggle);
    float tentacle_strength = smoothstep(tentacle_thickness, 0.0, tentacle_line);
    tentacle_strength = pow(tentacle_strength, tentacle_sharpness);

    // 🌫️ Desvanecimiento hacia los bordes
    float fade_radius = length(UV - center) / 0.7071;
    float fade = smoothstep(fade_end, fade_start, fade_radius);
    tentacle_strength *= fade;

    vec4 final_color = mix(background_color, tentacle_color, tentacle_strength);
    COLOR = final_color;
}
