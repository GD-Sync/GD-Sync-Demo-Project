shader_type canvas_item;

uniform vec4 modulate: source_color;
uniform float blur_amount : hint_range(0, 5);

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount) * modulate;
}