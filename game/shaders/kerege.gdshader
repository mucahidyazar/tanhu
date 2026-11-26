// Otağın iç kaplaması (bkz. YurtInterior):
//   part 0, duvar: krem keçenin önünde kızıl boyalı kafes (kereğe; çaprazlama çıtalar, kesişimlerde deri bağlar,
//          çıtaların çevresinde keçeye düşen hafif gölge) ve duvarın üst kenarında dokuma bant (baskur: kırmızı
//          zeminde basamaklı elmaslar, koyu kenar çizgileri). UV.x çevre boyunca metre, UV.y zeminden metre.
//   part 1, çatı: keçe üstünde duvardan tepeye (tündük) uzanan boyalı sırıklar (uuk); keçe tepeye doğru isle
//          koyulaşır. UV.x açı (0..1), UV.y saçaktan (0) tepeye (1).
// Kesitlidir (bkz. include/cutaway.gdshaderinc); ışık boyalı yumuşak modeldir (soft_light). hide_back açıkken yüzün arkası
// (dış yüzü: içe bakan duvarın kameraya bakan yakın yarısı) çizilmez ve gölge vermez: dış kabuk gizliyken içerisi yukarıdan
// diorama gibi görünür (doğum 7a; K98).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/cutaway.gdshaderinc"

uniform int part = 0;
// Yüzün arkası (dış yüz) çizilmesin mi (7a'nın dioraması)?
uniform bool hide_back = false;
uniform vec4 felt_color : source_color = vec4(0.86, 0.79, 0.66, 1.0);
uniform vec4 lattice_color : source_color = vec4(0.6, 0.25, 0.11, 1.0);
uniform vec4 tie_color : source_color = vec4(0.25, 0.14, 0.08, 1.0);
// Kafesin elmas gözü ve çıta eni (metre).
uniform float lattice_cell = 0.3;
uniform float lattice_width = 0.034;
// Duvarın boyu ve üst kenardaki dokuma bandın eni (metre).
uniform float wall_height = 2.4;
uniform float band_height = 0.24;
uniform vec4 band_color : source_color = vec4(0.6, 0.09, 0.06, 1.0);
uniform vec4 band_light : source_color = vec4(0.93, 0.87, 0.74, 1.0);
uniform vec4 band_dark : source_color = vec4(0.13, 0.1, 0.13, 1.0);
// Çatıdaki sırık sayısı ve sırığın eni (metre).
uniform float pole_count = 64.0;
uniform float pole_width = 0.045;
uniform vec4 soot_color : source_color = vec4(0.3, 0.22, 0.17, 1.0);

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// İçeride 1, dışarıda 0 (d < 0 içeride); kenar ekran pikseline göre yumuşatılır.
float fill(float d, float aa) {
	return 1.0 - smoothstep(-aa, aa, d);
}

// Çaprazlama çıta ailesinin en yakın çizgisine dik uzaklık (metre): çizgiler x ± y = k · cell.
float diag_dist(float s, float cell) {
	return abs(fract(s / cell + 0.5) - 0.5) * cell * 0.70711;
}

// Basamaklı elmas (dokuma motifi): Manhattan uzaklığı basamaklara yuvarlanır (d < 0 içeride).
float stepped_diamond(vec2 q, float r, float steps) {
	vec2 a = abs(q);
	float s = r / steps;
	vec2 snapped = floor(a / s) * s;
	return (snapped.x + snapped.y) - r;
}

vec3 wall(vec2 uv, float aa, float n) {
	vec3 col = felt_color.rgb * (0.92 + n * 0.12);
	// Zemine yakın keçe biraz kirli, üstte hafif isli.
	col *= mix(0.82, 1.0, smoothstep(0.0, 0.35, uv.y));
	float d1 = diag_dist(uv.x + uv.y, lattice_cell);
	float d2 = diag_dist(uv.x - uv.y, lattice_cell);
	float d = min(d1, d2);
	float hw = lattice_width * 0.5;
	// Çıtaların çevresinde keçeye düşen yumuşak gölge, sonra çıtalar (kenarları biraz koyu, yuvarlak).
	col *= 1.0 - 0.28 * (1.0 - smoothstep(hw, hw + 0.035, d));
	float slat = fill(d - hw, aa);
	vec3 wood = lattice_color.rgb * (0.82 + 0.28 * (1.0 - d / max(hw, 0.001))) * (0.94 + n * 0.1);
	col = mix(col, wood, slat);
	// Kesişimlerde deri bağ.
	float knot = fill(length(vec2(d1, d2)) - hw * 0.95, aa);
	col = mix(col, tie_color.rgb, knot * 0.85);
	// Üst kenarda dokuma bant (baskur) ve duvar kirişi.
	float top = wall_height - uv.y;
	if (top < band_height + 0.02) {
		float b = clamp((band_height - top) / band_height, 0.0, 1.0);
		vec3 band = band_color.rgb * (0.94 + n * 0.1);
		float cell = band_height * 0.85;
		vec2 q = vec2((fract(uv.x / cell) - 0.5) * cell, (b - 0.5) * band_height) / (band_height * 0.42);
		band = mix(band, band_light.rgb, fill(stepped_diamond(q, 0.8, 3.0), aa * 6.0));
		band = mix(band, band_color.rgb, fill(stepped_diamond(q, 0.48, 2.0), aa * 6.0));
		band = mix(band, band_dark.rgb, fill(stepped_diamond(q, 0.2, 1.0), aa * 6.0));
		// Kenar çizgileri.
		float edge = min(abs(top - band_height), abs(top - 0.035));
		band = mix(band, band_dark.rgb, fill(edge - 0.012, aa));
		col = mix(col, band, fill(top - band_height, aa));
	}
	col = mix(col, lattice_color.rgb * 0.55, fill(top - 0.03, aa));
	return col;
}

vec3 roof(vec2 uv, float aa, float n) {
	vec3 col = felt_color.rgb * (0.86 + n * 0.12);
	col = mix(col, soot_color.rgb, smoothstep(0.35, 1.0, uv.y) * 0.75);
	float r = max(length(v_world_pos.xz - cut_center.xz), 0.05);
	float slot = 6.28318 * r / pole_count;
	float f = abs(fract(uv.x * pole_count) - 0.5) * slot;
	float hw = pole_width * 0.5;
	col *= 1.0 - 0.25 * (1.0 - smoothstep(hw, hw + 0.03, f));
	float pole = fill(f - hw, aa * slot * pole_count);
	vec3 wood = lattice_color.rgb * (0.8 + 0.3 * (1.0 - f / max(hw, 0.001)));
	return mix(col, wood, pole);
}

void fragment() {
	if (cutaway_hidden(v_world_pos) || (hide_back && !FRONT_FACING)) {
		discard;
	}
	float n = tn_noise3(v_world_pos * 2.2) * 0.6 + tn_noise3(v_world_pos * 7.0 + 3.1) * 0.4;
	vec3 col;
	if (part == 0) {
		float aa = max(fwidth(UV.x), fwidth(UV.y)) * 0.75;
		col = wall(UV, aa, n);
	} else {
		col = roof(UV, fwidth(UV.x) * 0.75, n);
	}
	col *= 1.0 - 0.45 * cutaway_rim(v_world_pos);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
