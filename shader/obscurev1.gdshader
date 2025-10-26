shader_type canvas_item;

uniform float darkness : hint_range(0.0, 1.0) = 0.85;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.5;
uniform float vignette_size : hint_range(0.1, 1.0) = 0.3;
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.15;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.3;
uniform float desaturation : hint_range(0.0, 1.0) = 0.7;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// Desaturación
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(gray), desaturation);
	
	// Viñeta circular
	vec2 center = UV - vec2(0.5);
	float dist = length(center);
	float vignette = smoothstep(vignette_size, vignette_size + 0.5, dist);
	vignette = pow(vignette, vignette_intensity);
	
	// Ruido sucio
	float dirt = noise(UV * 50.0 + TIME * 0.1);
	dirt = mix(dirt, noise(UV * 100.0), 0.5);
	col.rgb -= dirt * noise_intensity;
	
	// Grano
	float grain = random(UV + fract(TIME)) * grain_amount;
	col.rgb += (grain - grain_amount * 0.5) * 0.1;
	
	// Aplicar oscuridad y viñeta
	col.rgb *= (1.0 - darkness);
	col.rgb *= (1.0 - vignette);
	
	COLOR = col;
}