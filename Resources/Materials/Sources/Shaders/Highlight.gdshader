shader_type spatial;
render_mode unshaded;
uniform sampler2D texture : source_color;
void fragment() {
	ALBEDO = texture(texture, SCREEN_UV).rgb;
	ALPHA = texture(texture, SCREEN_UV).a;
}