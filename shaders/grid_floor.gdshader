shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Shader de suelo estilo Kawaii Low-Poly: losas suaves de pradera y jardín (colores descansados, cero deslumbramiento)
uniform vec4 tile_color_a : source_color = vec4(0.48, 0.58, 0.45, 1.0); // Verde salvia suave y mate
uniform vec4 tile_color_b : source_color = vec4(0.43, 0.53, 0.40, 1.0); // Verde pradera apacible
uniform vec4 border_color : source_color = vec4(0.36, 0.44, 0.33, 1.0); // Borde tierra suave
uniform vec4 path_glow_color : source_color = vec4(0.68, 0.65, 0.52, 0.12); // Tono cálido sutil de sendero
uniform float tile_size : hint_range(0.5, 6.0) = 2.5;
uniform float border_width : hint_range(0.01, 0.15) = 0.04;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz / tile_size;
	vec2 tile_id = floor(uv);
	vec2 f = fract(uv);
	
	// Patrón de tablero suave y relajante
	float checker = mod(tile_id.x + tile_id.y, 2.0);
	vec3 base_color = mix(tile_color_a.rgb, tile_color_b.rgb, checker);
	
	// Bordes redondeados de las losas
	vec2 dist_to_edge = min(f, 1.0 - f);
	float edge = min(dist_to_edge.x, dist_to_edge.y);
	float border_mask = smoothstep(0.0, border_width, edge);
	
	vec3 final_color = mix(border_color.rgb, base_color, border_mask);
	
	// Sutil línea de guía cada 15 metros sin deslumbramiento
	vec2 major_uv = world_pos.xz / (tile_size * 6.0);
	vec2 major_f = abs(fract(major_uv - 0.5) - 0.5);
	float major_line = 1.0 - smoothstep(0.0, 0.025, min(major_f.x, major_f.y));
	final_color = mix(final_color, path_glow_color.rgb, major_line * path_glow_color.a);

	ALBEDO = final_color;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.05; // Bajo para evitar reflejos molestos a la vista
}
