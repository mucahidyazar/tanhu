// Çayır çiçekleri (4. referanstaki gibi küçük, boyalı çiçekler): beyaz papatya (sarı göbekli, bazıları hafif
// pembe), sarı düğün çiçeği ve açık mavi unutmabeni. Taç yaprakları UV üzerinde çizilir.
// INSTANCE_CUSTOM.r: tür (0 = beyaz, 0.5 = sarı, 1 = mavi), INSTANCE_CUSTOM.g: öbek başına renk farkı.
// Model yalnızca çiçek başlarıdır (Meadow.flower_cluster; saplar çimenin içinde kalır, çizilmez).
// COLOR.r: çiçek başına rastgele değer (yaprak sayısı, yaprakların dönüşü).
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"

uniform vec4 daisy_color : source_color = vec4(0.97, 0.96, 0.92, 1.0);
// Bazı beyaz çiçeklerin kaydığı açık pembe.
uniform vec4 daisy_blush : source_color = vec4(0.98, 0.84, 0.88, 1.0);
uniform vec4 daisy_center : source_color = vec4(1.0, 0.8, 0.25, 1.0);
uniform vec4 yellow_color : source_color = vec4(0.98, 0.86, 0.34, 1.0);
uniform vec4 yellow_center : source_color = vec4(0.9, 0.64, 0.2, 1.0);
uniform vec4 blue_color : source_color = vec4(0.62, 0.74, 1.0, 1.0);
uniform vec4 blue_center : source_color = vec4(0.98, 0.95, 0.8, 1.0);
uniform float wind_strength = 0.1;
uniform float wind_speed = 1.3;
uniform vec2 wind_direction = vec2(0.85, 0.3);
uniform float fade_start = 34.0;
uniform float fade_end = 52.0;
uniform float glow = 0.18;

varying float v_kind;
varying float v_tint;
varying float v_rand;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	float rel = clamp((VERTEX.y - root.y) / 0.45, 0.0, 1.0);
	float phase = tn_time() * wind_speed + dot(root.xz, vec2(0.21, 0.17));
	float gust = tn_noise2(root.xz * 0.045 + tn_time() * vec2(0.25, 0.1));
	float sway = (sin(phase) * 0.55 + gust * 1.2 - 0.3) * wind_strength * rel * rel;
	VERTEX.xz += normalize(wind_direction) * sway;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float fade = 1.0 - smoothstep(fade_start, fade_end, distance(root, cam));
	VERTEX = root + (VERTEX - root) * fade;
	v_kind = INSTANCE_CUSTOM.r;
	v_tint = INSTANCE_CUSTOM.g;
	v_rand = COLOR.r;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x) + v_rand * 6.2832;
	bool white = v_kind < 0.25;
	bool yellow = !white && v_kind < 0.75;
	// Beyaz: 5–7 sivri yaprak; sarı ve mavi: 5 yuvarlak yaprak.
	float petals = white ? 5.0 + floor(v_rand * 2.99) : 5.0;
	float lobe = white ? pow(abs(cos(a * petals * 0.5)), 0.7) : abs(cos(a * petals * 0.5));
	float petal_len = white ? 0.62 + 0.38 * lobe : 0.7 + 0.3 * sqrt(lobe);
	if (r > petal_len) {
		discard;
	}
	float center_r = white ? 0.3 : (yellow ? 0.26 : 0.24);
	vec3 petal = yellow ? yellow_color.rgb : (white ? mix(daisy_color.rgb, daisy_blush.rgb, smoothstep(0.55, 1.0, v_tint)) : blue_color.rgb);
	vec3 center = yellow ? yellow_center.rgb : (white ? daisy_center.rgb : blue_center.rgb);
	vec3 col = mix(center, petal, smoothstep(center_r - 0.06, center_r + 0.02, r));
	// Yaprak dipleri hafif gölgeli: küçük çiçek de boyalı bir şekil gibi okunur.
	col *= 0.84 + 0.16 * smoothstep(0.0, petal_len, r);
	ALBEDO = col;
	EMISSION = col * glow;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
