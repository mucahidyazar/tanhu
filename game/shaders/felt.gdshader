// Yurt keçesi: krem keçe, koçboynuzu motifli kahverengi süs bandı, çatı halatları.
// İçeriden bakıldığında (arka yüz) turuncu ahşap kafes (kerege) ve çatı sırıkları (uuk) görünür.
//
// UV: u = çevre boyunca 0..1, v = alttan üste 0..1 (duvar) / saçaktan taca 0..1 (çatı).
shader_type spatial;
render_mode cull_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"

uniform vec4 felt_color : source_color = vec4(0.93, 0.88, 0.77, 1.0);
uniform vec4 band_color : source_color = vec4(0.42, 0.24, 0.13, 1.0);
uniform vec4 motif_color : source_color = vec4(0.92, 0.84, 0.68, 1.0);
uniform vec4 lattice_color : source_color = vec4(0.78, 0.4, 0.17, 1.0);
// 0 = duvar, 1 = çatı
uniform int part = 0;
// Süs bandının v aralığı.
uniform float band_start = 0.76;
uniform float band_end = 0.93;
// Çevre boyunca motif sayısı (motiflerin kare görünmesi için çevre / bant yüksekliği).
uniform float motif_count = 60.0;
// Duvardaki keçe dikiş çizgileri / çatıdaki halat sayısı.
uniform float seam_count = 28.0;
uniform float rope_count = 16.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float ring_sdf(vec2 p, vec2 c, float r) {
	return abs(length(p - c) - r);
}

// Koçboynuzu (koshkar müyiz) motifinin basitleştirilmiş hali: ortada sap, iki yana kıvrılan boynuzlar.
float ram_horn(vec2 p) {
	vec2 q = vec2(abs(p.x), p.y);
	float horn = ring_sdf(q, vec2(0.19, 0.06), 0.14) - 0.04;
	if (q.y < 0.02 && q.x < 0.19) {
		horn = 1.0;
	}
	float curl = length(q - vec2(0.19, 0.06)) - 0.045;
	float stem = max(q.x - 0.04, abs(p.y + 0.12) - 0.2);
	float base = max(abs(p.y + 0.33) - 0.04, q.x - 0.3);
	return min(min(horn, curl), min(stem, base));
}

void fragment() {
	vec2 uv = UV;
	float n = tn_noise2(v_world_pos.xz * 1.7 + v_world_pos.y * 2.3);
	float fine = tn_noise2(v_world_pos.xz * 9.0 + v_world_pos.y * 11.0);
	vec3 col = felt_color.rgb * (0.94 + n * 0.1 + fine * 0.04);

	if (!FRONT_FACING) {
		// --- İç yüz: ahşap kafes / çatı sırıkları ---
		vec3 inner = felt_color.rgb * 0.55;
		if (part == 0) {
			vec2 g = vec2(uv.x * 90.0, uv.y * 6.0);
			float d1 = abs(fract(g.x + g.y) - 0.5);
			float d2 = abs(fract(g.x - g.y) - 0.5);
			float lattice = 1.0 - smoothstep(0.06, 0.1, min(d1, d2));
			inner = mix(inner, lattice_color.rgb, lattice);
		} else {
			float pole = 1.0 - smoothstep(0.05, 0.09, abs(fract(uv.x * 72.0) - 0.5));
			inner = mix(inner, lattice_color.rgb, pole);
		}
		ALBEDO = inner;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else {
		if (part == 0) {
			// Keçe panelleri arasındaki hafif dikişler.
			float seam = 1.0 - smoothstep(0.0, 0.06, abs(fract(uv.x * seam_count) - 0.5) - 0.44);
			col *= 1.0 - seam * 0.07;
			// Alt kısım hafif kirli.
			col *= mix(0.82, 1.0, smoothstep(0.0, 0.22, uv.y + (n - 0.5) * 0.08));
			// Süs bandı.
			if (uv.y > band_start && uv.y < band_end) {
				float by = (uv.y - band_start) / (band_end - band_start);
				vec2 p = vec2(fract(uv.x * motif_count) - 0.5, by - 0.5);
				float d = ram_horn(p * vec2(1.0, 1.15));
				float motif = 1.0 - smoothstep(0.0, 0.035, d);
				float border = 1.0 - smoothstep(0.035, 0.07, min(by, 1.0 - by));
				vec3 band = band_color.rgb * (0.9 + n * 0.2);
				band = mix(band, motif_color.rgb, max(motif * 0.9, border * 0.85));
				col = band;
			}
			// Bandın hemen altında ince bir halat.
			float rope_v = band_start - 0.03;
			float rope = 1.0 - smoothstep(0.006, 0.014, abs(uv.y - rope_v));
			col = mix(col, band_color.rgb * 0.8, rope * 0.8);
		} else {
			// Çatı: tacın etrafında is lekesi, saçakta koyu bant, çapraz halatlar.
			float crossing_a = abs(fract(uv.x * rope_count + uv.y * 1.6) - 0.5);
			float crossing_b = abs(fract(uv.x * rope_count - uv.y * 1.6) - 0.5);
			float ropes = 1.0 - smoothstep(0.012, 0.028, min(crossing_a, crossing_b));
			col = mix(col, band_color.rgb * 0.8, ropes * 0.3 * smoothstep(0.12, 0.2, uv.y));
			float eave = 1.0 - smoothstep(0.07, 0.1, uv.y);
			col = mix(col, band_color.rgb, eave);
			float soot = smoothstep(0.78, 1.0, uv.y + (n - 0.5) * 0.12);
			col *= 1.0 - soot * 0.35;
		}
		ALBEDO = col;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	}
}
