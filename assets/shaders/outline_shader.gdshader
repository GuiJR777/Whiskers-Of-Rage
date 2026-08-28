shader_type spatial;

render_mode cull_front, unshaded;

group_uniforms Outline;

uniform vec4 outline_color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float outline_size : hint_range(0.0, 0.1, 0.001) = 0.015;

void vertex() {
	VERTEX += NORMAL * outline_size;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}