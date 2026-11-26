// Önsöz'ün kazık bayrağı (E21, K110; scripts/story/prologue_props.gd): direğe bağlı dar keçe şerit. Mesh MeshKit.cloth (genişlik x,
// yükseklik −y; UV.x 0 direkte bağlı uç, 1 serbest uç). wind 0'da şerit direkten aşağı sarkar ve hafifçe sallanır; 1'de (tipi) yatay çırpar:
// serbest uç rüzgârın yönünde uzar (düğümün yerel +x'i rüzgâra döner: PrologueProps.set_flag_wind), dalga sıklaşır. Işık ortak cel modelidir.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

uniform vec4 cloth_color : source_color = vec4(0.64, 0.23, 0.13, 1.0);
uniform float wind : hint_range(0.0, 1.0) = 0.15;
uniform float seed = 0.0;

varying float v_fold;
varying vec3 v_world_pos;

void vertex() {
	float t = tn_time() * mix(1.6, 9.0, wind) + seed * 6.28;
	float free = UV.x;
	// Bağlı uç direğin yanında: şerit yerel x boyunca uzanır. Rüzgârsızken serbest uç aşağı sarkar (dönüş z ekseni çevresinde).
	vec3 p = VERTEX + vec3(0.21, 0.0, 0.0);
	float droop = mix(1.25, 0.08, wind);
	float s = sin(-droop * free);
	float c = cos(-droop * free);
	p = vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
	float wave = sin(t + free * mix(4.0, 11.0, wind)) * mix(0.03, 0.07, wind) * free;
	p.z += wave;
	p.y += sin(t * 0.7 + free * 5.0) * 0.02 * free * wind;
	VERTEX = p;
	v_fold = cos(t + free * mix(4.0, 11.0, wind)) * free;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = tn_noise2(UV * vec2(10.0, 6.0) + seed);
	vec3 col = cloth_color.rgb * (0.88 + n * 0.18);
	col *= 1.0 - 0.18 * clamp(v_fold * 2.0 + 0.2, 0.0, 1.0);
	col *= 0.95 + tn_noise2(v_world_pos.xz * 7.0) * 0.08;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
