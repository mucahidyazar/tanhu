// Rüzgârda dalgalanan çimen yaprakları (MultiMesh ile çizilir).
// Renk: koyu yeşil taban → açık/sarımsı uç. Normaller yukarı bakar;
// böylece çimenlik tek bir yumuşak yüzey gibi aydınlanır (boyalı görünüm).
// Kameradan uzaklaştıkça yapraklar küçülerek zemine karışır.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"

uniform vec4 base_color : source_color = vec4(0.07, 0.2, 0.07, 1.0);
uniform vec4 tip_color : source_color = vec4(0.36, 0.6, 0.15, 1.0);
uniform vec4 tip_color_warm : source_color = vec4(0.6, 0.68, 0.2, 1.0);
uniform float wind_strength = 0.12;
uniform float wind_speed = 1.3;
uniform vec2 wind_direction = vec2(0.85, 0.3);
uniform float fade_start = 26.0;
uniform float fade_end = 40.0;

varying float v_height;
varying vec3 v_tint;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	// UV.y yaprağın yerel yüksekliği (0..~1); ölçek yerine oran kullanılır.
	v_height = clamp(UV.y, 0.0, 1.0);
	float h2 = v_height * v_height;
	float phase = tn_time() * wind_speed + dot(root.xz, vec2(0.21, 0.17));
	float gust = tn_noise2(root.xz * 0.045 + tn_time() * vec2(0.25, 0.1));
	float sway = (sin(phase) * 0.55 + sin(phase * 2.31 + 1.7) * 0.2 + gust * 1.3 - 0.35) * wind_strength * h2;
	vec2 wd = normalize(wind_direction);
	VERTEX.xz += wd * sway;
	VERTEX.y -= abs(sway) * 0.35;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float fade = 1.0 - smoothstep(fade_start, fade_end, distance(root, cam));
	VERTEX = root + (VERTEX - root) * fade;
	NORMAL = vec3(0.0, 1.0, 0.0);
	v_tint = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	vec3 tip = mix(tip_color.rgb, tip_color_warm.rgb, v_tint.r);
	vec3 col = mix(base_color.rgb, tip, smoothstep(0.0, 0.95, v_height));
	col *= mix(0.8, 1.15, v_tint.g);
	// Arka yüzde de normal yukarı baksın (Godot iki yüzlü malzemede normali çevirir).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
