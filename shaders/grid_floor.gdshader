shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 background_color : source_color = vec4(0.12, 0.14, 0.18, 1.0);
uniform vec4 grid_color : source_color = vec4(0.25, 0.32, 0.42, 1.0);
uniform vec4 accent_grid_color : source_color = vec4(0.0, 0.85, 0.95, 0.4);
uniform float grid_size : hint_range(0.5, 10.0) = 2.0;
uniform float line_thickness : hint_range(0.005, 0.1) = 0.02;
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv_coords = world_pos.xz / grid_size;
	vec2 grid_frac = abs(fract(uv_coords - 0.5) - 0.5) / fwidth(uv_coords);
	float line = min(grid_frac.x, grid_frac.y);
	float c = 1.0 - min(line, 1.0);
	
	// Cuadrícula mayor cada 5 unidades (10 metros)
	vec2 major_uv = world_pos.xz / (grid_size * 5.0);
	vec2 major_frac = abs(fract(major_uv - 0.5) - 0.5) / fwidth(major_uv);
	float major_line = min(major_frac.x, major_frac.y);
	float major_c = 1.0 - min(major_line, 1.0);
	
	vec3 base = mix(background_color.rgb, grid_color.rgb, c * 0.7);
	vec3 final_color = mix(base, accent_grid_color.rgb, major_c * accent_grid_color.a);
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.5;
}
