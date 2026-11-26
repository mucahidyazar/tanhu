// Bayrak ve duvar kumaşı: rüzgârda dalgalanan boyalı keçe kumaş, ortada damga (tamga), kenarlarda işlemeli
// şeritler (küçük elmas dizisi), isteğe bağlı yırtık ve kırlangıç kuyruklu alt kenar. Kamp referansındaki
// (menu_camp.png) gibi: koyu kızıl zemin üstünde krem damga ya da krem zemin üstünde koyu damga.
// Boyalı görünüm: kıvrım gölgeleri, fırça gürültüsü, elle çizilmiş gibi hafif titrek damga kenarı.
// Mesh: MeshKit.cloth() — üst kenar sabit (UV.y = 0), alt kenar serbest (UV.y = 1).
// Işık ortak "After the Wind" cel modelidir.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

uniform vec4 cloth_color : source_color = vec4(0.42, 0.1, 0.08, 1.0);
uniform vec4 emblem_color : source_color = vec4(0.93, 0.85, 0.66, 1.0);
uniform vec4 trim_color : source_color = vec4(0.22, 0.11, 0.07, 1.0);
uniform float wave_amplitude = 0.08;
uniform float wave_speed = 1.5;
// 0 = düz kenar, 1 = yırtık ve çatallı (kırlangıç kuyruğu) alt kenar.
uniform float tatter = 0.0;
uniform float aspect = 0.6; // genişlik / yükseklik (damganın yuvarlak kalması için)
uniform float emblem_size = 1.0;
// Rüzgârın açtığı kıvrımlardaki gölgelenme (0 = düz kumaş).
uniform float fold_strength : hint_range(0.0, 0.6) = 0.22;

varying vec3 v_world_pos;
varying float v_fold;

float wave_at(vec2 uv, float t) {
	return sin(t + uv.x * 3.1 + uv.y * 4.2) * 0.6 + sin(t * 1.7 + uv.y * 7.0 + 1.3) * 0.4;
}

void vertex() {
	float t = tn_time() * wave_speed;
	float free = UV.y;
	float wave = wave_at(UV, t);
	VERTEX.z += wave * wave_amplitude * free;
	VERTEX.x += sin(t * 0.8 + UV.y * 2.0) * wave_amplitude * 0.3 * free;
	// Dalganın yatay eğimi: kıvrımın ışığa dönük ve gölgede kalan yanları.
	v_fold = (wave_at(UV + vec2(0.05, 0.0), t) - wave) * free;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float fill(float d, float aa) {
	return 1.0 - smoothstep(-aa, aa, d);
}

// Damga: halka + dikey çubuk + üstte kollar (Style.tamga_distance ile aynı biçim).
float tamga(vec2 p) {
	float ring = abs(length(p) - 0.15) - 0.028;
	float bar = max(abs(p.x) - 0.024, abs(p.y - 0.05) - 0.3);
	float arms = max(abs(p.y + 0.24) - 0.024, abs(p.x) - 0.12);
	return min(ring, min(bar, arms));
}

void fragment() {
	vec2 uv = UV;
	float n = tn_noise2(uv * vec2(14.0, 20.0));
	float aa = max(fwidth(uv.x), fwidth(uv.y)) * 0.8;
	// Yırtık alt kenar ve kırlangıç kuyruğu kesiği.
	if (tatter > 0.0) {
		float edge = 1.0 - tatter * (0.06 + 0.1 * n);
		float notch = 1.0 - tatter * 0.22 * (1.0 - abs(uv.x - 0.5) * 2.0);
		if (uv.y > min(edge, notch)) {
			discard;
		}
	}
	vec3 col = cloth_color.rgb * (0.9 + n * 0.16);
	// Kenar şeritleri: iki yanda ve üstte koyu bant, içinde krem elmas dizisi.
	float side = min(uv.x, 1.0 - uv.x) * aspect;
	float top = uv.y;
	float band = 0.075 * aspect;
	float in_side = fill(side - band, aa);
	float in_top = fill(top - 0.06, aa);
	col = mix(col, trim_color.rgb * (0.9 + n * 0.15), max(in_side, in_top));
	float along = (in_side > 0.5) ? uv.y / aspect : uv.x;
	float across = (in_side > 0.5) ? side / band : top / 0.06;
	vec2 q = vec2(fract(along * 9.0) - 0.5, across - 0.5);
	float diamond = abs(q.x) * 1.4 + abs(q.y) * 1.1 - 0.32;
	col = mix(col, emblem_color.rgb * 0.85, fill(diamond, 0.05) * max(in_side, in_top) * 0.6);
	// Damga (elle boyanmış gibi titrek kenar).
	vec2 p = (uv - vec2(0.5, 0.42)) * vec2(aspect, 1.0) / emblem_size;
	float wobble = (tn_noise2(p * 38.0) - 0.5) * 0.012;
	float mark = fill(tamga(p) + wobble, 0.008);
	col = mix(col, emblem_color.rgb * (0.92 + n * 0.12), mark);
	// Kıvrım gölgeleri ve fırça lekeleri.
	col *= 1.0 - fold_strength * clamp(v_fold * 3.0 + 0.15, 0.0, 1.0);
	col *= 0.94 + tn_noise2(v_world_pos.xy * 9.0 + v_world_pos.z * 5.0) * 0.1;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
