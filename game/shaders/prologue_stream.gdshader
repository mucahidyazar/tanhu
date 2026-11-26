// Önsöz'ün deresi (E21, K110; scripts/story/prologue_props.gd stream_mesh): çakıllı yatakta akan küçük berrak dere. Şerit: UV.x kıyıdan kıyıya,
// UV.y akış yönünde (genişlik birimiyle). Ortası koyu ve berrak (yatağın çakılı seçilir), kıyıda açık sığlık ve köpük benekleri; akış
// çizgileri suyun yönünde kayar. Kar örtüsünde (weather_ground.y) kıyılar beyazlaşır, su açık kalır. Işık ortak cel modelidir.
shader_type spatial;
render_mode blend_mix, cull_disabled, specular_disabled, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

global uniform vec4 weather_ground;
uniform vec4 deep_color : source_color = vec4(0.16, 0.24, 0.27, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.42, 0.47, 0.44, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.5, 0.45, 0.38, 1.0);
uniform vec4 foam_color : source_color = vec4(0.86, 0.9, 0.92, 1.0);
uniform float flow_speed = 0.55;

void fragment() {
	float t = tn_time() * flow_speed;
	float across = abs(UV.x - 0.5) * 2.0;
	vec2 q = vec2(UV.x * 2.0, UV.y * 1.6 - t);
	float streak = tn_noise2(vec2(UV.x * 9.0, UV.y * 0.9 - t * 1.4));
	float ripple = tn_noise2(q * 3.0) * 0.6 + tn_noise2(q * 7.0 + 3.1) * 0.4;
	float pebbles = smoothstep(0.62, 0.75, tn_noise2(vec2(UV.x * 6.0, UV.y * 2.2)));
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.35, 0.95, across));
	col = mix(col, pebble_color.rgb, pebbles * (1.0 - across) * 0.45);
	col += vec3(0.08, 0.1, 0.1) * smoothstep(0.55, 0.85, ripple);
	float foam = smoothstep(0.72, 0.9, streak) * smoothstep(0.55, 1.0, across);
	col = mix(col, foam_color.rgb, foam * 0.55);
	col = mix(col, vec3(0.84, 0.88, 0.95), clamp(weather_ground.y * 1.4 - (1.0 - across) * 1.6, 0.0, 1.0) * 0.8);
	ALBEDO = col;
	ALPHA = mix(0.88, 0.0, smoothstep(0.9, 1.0, across));
	ROUGHNESS = 0.6;
	SPECULAR = 0.0;
}
