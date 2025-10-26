shader_type canvas_item;

uniform int particle_count : hint_range(10, 1000) = 40;
uniform float particle_size : hint_range(0.0005, 0.05) = 0.015;
uniform float particle_speed : hint_range(0.1, 2.0) = 0.5;
uniform float particle_opacity : hint_range(0.0, 1.0) = 0.15;
uniform vec4 particle_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float drift_amount : hint_range(0.0, 2.0) = 1.0;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float circle(vec2 uv, vec2 pos, float size) {
	float dist = length(uv - pos);
	return smoothstep(size, size * 0.5, dist);
}

void fragment() {
	float particles = 0.0;

	for(int i = 0; i < particle_count; i++) {
		float fi = float(i);

		// Posición base aleatoria
		vec2 seed = vec2(fi * 0.123, fi * 0.456);
		float x = random(seed);
		float y = random(seed + vec2(1.0, 0.0));

		// Movimiento vertical lento + deriva horizontal
		float speed_var = random(seed + vec2(2.0, 0.0)) * 0.5 + 0.5;
		float drift = sin(TIME * 0.5 + fi) * drift_amount * 0.1;

		y = fract(y - TIME * particle_speed * speed_var * 0.1);
		x = fract(x + drift);

		vec2 pos = vec2(x, y);

		// Tamaño variable
		float size_var = random(seed + vec2(3.0, 0.0)) * 0.5 + 0.5;
		float p_size = particle_size * size_var;

		// Dibujar partícula
		particles += circle(UV, pos, p_size);
	}

	// Solo las partículas, con transparencia
	vec4 final_color = vec4(particle_color.rgb, particles * particle_opacity);

	COLOR = final_color;
}