shader_type canvas_item;

uniform float light_radius : hint_range(0.0, 500.0) = 100.0;
uniform vec2 light_pos = vec2(0.0, 0.0);
uniform float softness : hint_range(0.0, 200.0) = 20.0;
uniform bool use_circle = true;
uniform float square_size : hint_range(0.0, 500.0) = 100.0;

void fragment() {
	vec2 pixel_pos = FRAGCOORD.xy;
	float alpha = 1.0;

	if (use_circle) {
		float dist = distance(pixel_pos, light_pos);
		alpha = smoothstep(light_radius - softness, light_radius + softness, dist);
	} else {
		vec2 diff = abs(pixel_pos - light_pos);
		float max_diff = max(diff.x, diff.y);
		alpha = smoothstep(square_size - softness, square_size + softness, max_diff);
	}

	COLOR = vec4(1.0, 1.0, 1.0, alpha);
}