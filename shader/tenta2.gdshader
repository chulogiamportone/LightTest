shader_type canvas_item;

uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);   // Fondo oscuro
uniform vec4 tentacle_color : source_color = vec4(0.05, 0.05, 0.05, 1.0); // Color del tentáculo

uniform vec2 center  = vec2(0.5, 0.5); // Centro de la criatura

uniform int tentacle_count : hint_range(1, 16) = 6;
uniform float tentacle_width : hint_range(0.01, 0.2) = 0.05;
uniform float tentacle_length : hint_range(0.2, 1.5) = 1.0;
uniform float tentacle_wiggle : hint_range(0.0, 1.0) = 0.25;
uniform float tentacle_speed : hint_range(0.0, 5.0) = 1.0;
uniform float tentacle_detail : hint_range(1.0, 20.0) = 8.0;
uniform float tentacle_sharpness : hint_range(0.5, 10.0) = 4.0;



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
	vec2 u = f*f*(3.0 - 2.0*f);
	return mix(a, b, u.x) + (c - a)*u.y*(1.0 - u.x) + (d - b)*u.x*u.y;
}

void fragment() {
	vec2 uv = UV;
	vec2 rel = uv - center;
	float radius = length(rel);
	float angle = atan(rel.y, rel.x); // -PI to PI

	// Calculamos el ángulo normalizado
	float norm_angle = (angle + PI) / (2.0 * PI);

	// Localizamos el tentáculo más cercano
	float tentacle_segment = fract(norm_angle * float(tentacle_count));
	float tentacle_axis_dist = abs(tentacle_segment - 0.5);

	// Movimiento
	float t = TIME * tentacle_speed;
	float offset = (noise(vec2(angle * tentacle_detail, radius * tentacle_detail + t)) - 0.5) * tentacle_wiggle;

	// Define la "columna" del tentáculo
	float tentacle_mask = smoothstep(tentacle_width, 0.0, tentacle_axis_dist + offset);

	// Ahora limitamos la longitud del tentáculo: solo aparece desde el centro hacia afuera
	float radial_mask = smoothstep(0.0, tentacle_length, radius);

	// Combinamos forma + movimiento + distancia desde centro
	float final_mask = tentacle_mask * radial_mask;

	// Definimos nitidez
	final_mask = pow(final_mask, tentacle_sharpness);

	// Mezclamos
	COLOR = mix(background_color, tentacle_color, final_mask);
}
