// Göl ve nehir: gökyüzünü yansıtan, ay ışığında pırıldayan stilize su.
// Işık hesabı elle yapılır (unshaded) — böylece renkler tamamen sanatsal kontrol altında kalır.
// Derinlik dokusu sayesinde kıyıya yaklaştıkça su açılır ve yumuşakça kaybolur.
shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_always;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

uniform vec3 deep_color : source_color = vec3(0.04, 0.08, 0.2);
uniform vec3 shallow_color : source_color = vec3(0.18, 0.3, 0.5);
uniform vec3 reflection_horizon : source_color = vec3(0.42, 0.54, 0.86);
uniform vec3 reflection_zenith : source_color = vec3(0.18, 0.29, 0.54);
uniform vec3 moon_direction = vec3(0.39, 0.24, -0.89);
uniform vec3 glint_color : source_color = vec3(1.0, 0.95, 0.85);
uniform float glint_energy = 5.0;
uniform float ripple_strength = 0.3;
uniform float shore_fade = 1.2;
uniform sampler2D ripple_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D ripple_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wuv = v_world_pos.xz;
	vec2 na = texture(ripple_a, wuv * 0.018 + tn_time() * vec2(0.004, 0.0025)).xy * 2.0 - 1.0;
	vec2 nb = texture(ripple_b, wuv * 0.05 - tn_time() * vec2(0.003, 0.005)).xy * 2.0 - 1.0;
	vec2 slope = (na + nb * 0.6) * ripple_strength;
	vec3 n = normalize(vec3(-slope.x, 1.0, -slope.y));

	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 v = normalize(cam - v_world_pos);
	float fresnel = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 4.0);
	vec3 r = reflect(-v, n);
	vec3 refl = mix(reflection_horizon, reflection_zenith, smoothstep(0.0, 0.5, r.y));
	vec3 col = mix(deep_color, refl, clamp(fresnel * 1.15 + 0.08, 0.0, 1.0));

	// Ayın su üzerindeki parıltısı (dalgacıklar sayesinde uzun bir yol gibi görünür).
	vec3 md = normalize(moon_direction);
	float rd = max(dot(r, md), 0.0);
	col += glint_color * (pow(rd, 350.0) * glint_energy + pow(rd, 40.0) * 0.3);

	// Derinlik farkı: sahnedeki zemin ile su yüzeyi arasındaki mesafe.
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	float water_depth = max(-view.z + VERTEX.z, 0.0);
	col = mix(col, shallow_color, (1.0 - smoothstep(0.0, 5.0, water_depth)) * 0.45);
	float shore = 1.0 - smoothstep(0.0, shore_fade, water_depth);
	col += vec3(0.22, 0.27, 0.34) * shore * 0.55;

	ALBEDO = col;
	ALPHA = clamp(smoothstep(0.0, 0.5, water_depth) * 0.94 + 0.06, 0.0, 1.0);
}
