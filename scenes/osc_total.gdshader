shader_type canvas_item;

uniform sampler2D light_texture;
uniform vec4 darkness_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 light = texture(light_texture, SCREEN_UV);
    // Donde hay luz (blanco), mostramos transparente. Donde no hay, oscuridad
    COLOR = mix(darkness_color, vec4(0.0, 0.0, 0.0, 0.0), light.r);
}