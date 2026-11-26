// "After the Wind" tarzı zemin (stil laboratuvarı ve oyun alanı için).
//
// - Çimenlik zemin, çimen tutamlarının kök rengiyle aynıdır (tutam araları "çimen gölgesi" olur).
// - Toprak patika: patika çizgilerine (segment) uzaklıkla çizilir. Ortası açık ten rengi, kenarı koyu
//   ıslak toprak; kenar gürültüyle dalgalanır; kenar boyunca küçük açık renkli çakıllar serpilir.
// - Işık çimenle aynı düz modeldir; düşen gölgeler serin koyu tona döner.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"

const int MAX_SEGMENTS = 48;

group_uniforms grass;
uniform vec4 grass_color : source_color = vec4(0.27, 0.47, 0.22, 1.0);
uniform vec4 grass_variation : source_color = vec4(0.3, 0.5, 0.2, 1.0);
uniform float variation_scale = 0.09;
group_uniforms path;
// Patika parçaları: vec4(ax, az, bx, bz); genişlik (yarı genişlik, metre) path_widths'te.
uniform vec4 path_segments[MAX_SEGMENTS];
uniform float path_widths[MAX_SEGMENTS];
uniform int path_count = 0;
uniform vec4 dirt_color : source_color = vec4(0.7, 0.55, 0.38, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.88, 0.72, 0.5, 1.0);
uniform vec4 dirt_edge : source_color = vec4(0.52, 0.42, 0.24, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.88, 0.84, 0.74, 1.0);
uniform vec4 pebble_outline : source_color = vec4(0.42, 0.36, 0.26, 1.0);
uniform float pebble_scale = 3.6;
uniform float edge_width = 0.24;
uniform float edge_noise = 0.22;
uniform float pebble_amount : hint_range(0.0, 1.0) = 0.5;
group_uniforms lighting;
uniform vec3 shadow_tint : source_color = vec3(0.6, 0.72, 0.8);
uniform vec3 dirt_shadow_tint : source_color = vec3(0.7, 0.72, 0.8);
group_uniforms;

varying vec3 v_world_pos;
varying float v_dirt;

// p noktasının patikalara işaretli uzaklığı (içeride eksi) ve ait olduğu parçanın yarı genişliği.
float path_distance(vec2 p) {
	float best = 1e5;
	for (int i = 0; i < MAX_SEGMENTS; i++) {
		if (i >= path_count) {
			break;
		}
		vec4 s = path_segments[i];
		vec2 a = s.xy;
		vec2 ab = s.zw - a;
		float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
		float d = length(p - (a + ab * t)) - path_widths[i];
		best = min(best, d);
	}
	return best;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world_pos.xz;
	float n = tn_fbm2(p * 1.7, 3);
	float big = tn_fbm2(p * variation_scale, 3);
	vec3 grass = mix(grass_color.rgb, grass_variation.rgb, smoothstep(0.35, 0.75, big));
	// Kenar dalgalı olsun: uzaklığa gürültü ekle.
	float d = path_distance(p) + (n - 0.5) * edge_noise;
	float inside = 1.0 - smoothstep(-0.02, 0.03, d);
	// Ortası açık, kenara doğru koyulaşan toprak; gürültüyle lekeli.
	float center = smoothstep(-0.9, -0.15, -d);  // kenardan uzaklaştıkça 1
	vec3 dirt = mix(dirt_color.rgb, dirt_light.rgb, smoothstep(0.3, 0.8, tn_fbm2(p * 0.8, 2)) * center);
	float rim = 1.0 - smoothstep(-edge_width, -0.01, d);  // kenarda 0, içeride 1
	dirt = mix(dirt_edge.rgb, dirt, rim * 0.85 + 0.15);
	// Kenar boyunca çakıllar (hücresel gürültünün merkezleri).
	float cell = tn_worley3(vec3(p * pebble_scale, 0.5));
	float near_edge = 1.0 - smoothstep(0.0, 0.4, abs(d + 0.14));
	float keep = near_edge * step(1.0 - pebble_amount, tn_hash12(floor(p * pebble_scale * 0.5)));
	float stone = 1.0 - smoothstep(0.13, 0.16, cell);
	float ring = (1.0 - smoothstep(0.16, 0.2, cell)) - stone;
	dirt = mix(dirt, pebble_outline.rgb, ring * keep * 0.8);
	dirt = mix(dirt, pebble_color.rgb * mix(0.92, 1.05, tn_hash12(floor(p * pebble_scale) + 3.0)), stone * keep);
	v_dirt = inside;
	ALBEDO = mix(grass, dirt, inside);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 tint = mix(shadow_tint, dirt_shadow_tint, v_dirt);
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(tint, vec3(1.0), ATTENUATION);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	}
}
