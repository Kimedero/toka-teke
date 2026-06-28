shader_type spatial;

render_mode cull_back, diffuse_toon, unshaded;//, depth_test_disabled;

uniform sampler2D main_texture: source_color;
uniform vec3 extra_color: source_color = vec3(1.0);

uniform float scroll_speed: hint_range(0.0, 10.0, 0.25) = 2.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 scrolling_uv = UV * vec2(0.5, 25.0) - vec2(TIME * scroll_speed, 0.0);
	vec3 albedo_color = texture(main_texture, scrolling_uv).rgb;
	ALBEDO = albedo_color * extra_color;
	//ALPHA = 0.25;
}
