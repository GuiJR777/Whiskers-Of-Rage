shader_type spatial;

render_mode cull_front, unshaded, depth_draw_opaque, shadows_disabled;

group_uniforms Outline;

uniform vec3 outline_color : source_color = vec3(0.02, 0.02, 0.02);
uniform float outline_width : hint_range(0.0, 20.0, 0.1) = 3.0;

void vertex() {
	// Posição do vértice no espaço da câmera.
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

	// Posição final em Clip Space.
	vec4 clip_position = PROJECTION_MATRIX * view_position;

	// Normal corretamente transformada para View Space.
	vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);

	// Projetamos a normal para descobrir para qual direção
	// ela aponta na tela.
	vec2 projected_normal = (
		PROJECTION_MATRIX * vec4(view_normal, 0.0)
	).xy;

	// Evita divisão por zero.
	float normal_length = max(length(projected_normal), 0.0001);

	vec2 screen_direction = projected_normal / normal_length;

	// 2.0 porque o NDC vai de -1 até +1.
	vec2 pixel_size = 2.0 / VIEWPORT_SIZE;

	// Multiplicar por W cancela a divisão por perspectiva.
	// Isso é o que mantém a espessura aproximadamente constante
	// independentemente da distância da câmera.
	clip_position.xy += (
		screen_direction
		* outline_width
		* pixel_size
		* clip_position.w
	);

	// POSITION espera diretamente Clip Space.
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color;
}