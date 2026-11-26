// rug ve rug_cut shader'larının ortak gövdesi (render_mode dışında her şey burada). Açıklama: shaders/rug.gdshader.
// CUTAWAY tanımlıysa otağ kesiti uygulanır (duvara asılı halı, bkz. include/cutaway.gdshaderinc).

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"
#ifdef CUTAWAY
#include "res://shaders/include/cutaway.gdshaderinc"
#endif

uniform vec4 field_color : source_color = vec4(0.3, 0.09, 0.06, 1.0);
uniform vec4 border_color : source_color = vec4(0.15, 0.075, 0.05, 1.0);
uniform vec4 pattern_color : source_color = vec4(0.56, 0.4, 0.28, 1.0);
uniform vec4 accent_color : source_color = vec4(0.42, 0.2, 0.09, 1.0);
uniform vec2 size = vec2(2.0, 1.25);
// Kısa kenarlardaki püskül uzunluğu (metre).
uniform float fringe = 0.0;
// Aşınma: yürünen yerlerde açılan renk lekeleri (0 = yeni halı).
uniform float wear : hint_range(0.0, 1.0) = 0.3;
// İç alandaki şeritlerin aralığı (metre) ve desenlerin zemine karışma oranı (1 = tam renk).
uniform float stripe_period = 0.2;
uniform float pattern_strength : hint_range(0.0, 1.0) = 0.75;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// İçeride 1, dışarıda 0; kenar ekran pikseline göre yumuşatılır (d < 0 içeride).
float fill(float d, float aa) {
	return 1.0 - smoothstep(-aa, aa, d);
}

// Basamaklı elmas (kilim motifi): Manhattan uzaklığı basamaklara yuvarlanır.
float stepped_diamond(vec2 q, float r, float steps) {
	vec2 a = abs(q);
	float s = r / steps;
	vec2 snapped = floor(a / s) * s;
	return (snapped.x + snapped.y) - r;
}

// Bordür bandı: dış koyu kenar, bant boyunca küçük basamaklı elmaslar, iç kenarda ince soluk çizgi.
vec3 border(vec3 col, vec2 w, vec2 e2, float edge, float band_w, float aa) {
	col = mix(col, border_color.rgb, fill(edge - band_w, aa));
	col = mix(col, border_color.rgb * 0.7, fill(edge - 0.02, aa));
	if (edge > 0.022 && edge < band_w) {
		float along = (e2.x < e2.y) ? w.y : w.x;
		float cell = band_w * 0.95;
		vec2 q = vec2((fract(along / cell) - 0.5) * cell, edge - (band_w + 0.022) * 0.5) / (band_w * 0.34);
		col = mix(col, accent_color.rgb, fill(stepped_diamond(q, 0.75, 3.0), aa * 3.0) * pattern_strength);
		col = mix(col, pattern_color.rgb, fill(stepped_diamond(q, 0.28, 2.0), aa * 3.0) * pattern_strength);
	}
	return mix(col, pattern_color.rgb, fill(abs(edge - band_w - 0.012) - 0.005, aa) * pattern_strength * 0.8);
}

// İç alan: kısa kenara paralel şeritler (ince çizgiler arasında küçük elmas dizileri) ve ortada madalyon.
vec3 field(vec3 col, vec2 c, vec2 inner, float aa) {
	float sx = c.x / stripe_period;
	float lane = floor(sx);
	float u = (fract(sx) - 0.5) * stripe_period;
	// Şerit çizgileri.
	col = mix(col, border_color.rgb, fill(abs(abs(u) - stripe_period * 0.5) - 0.007, aa) * pattern_strength);
	// Şeritlerdeki küçük elmaslar: sırayla vurgu ve desen renginde.
	float cell = stripe_period * 0.8;
	vec2 q = vec2(u, (fract(c.y / cell) - 0.5) * cell) / (stripe_period * 0.3);
	vec3 motif = mod(lane, 2.0) < 0.5 ? accent_color.rgb : pattern_color.rgb * 0.85;
	col = mix(col, motif, fill(stepped_diamond(q, 0.62, 2.0), aa * 4.0) * pattern_strength * 0.85);
	// Madalyon: koyu çerçeve, vurgu halkası, zemin rengi göbek ve içinde küçük açık elmas.
	vec2 m = c / max(inner.y, 0.05) * vec2(inner.y / max(inner.x, 0.05) * 1.7, 1.0);
	float med = abs(m.x) + abs(m.y);
	col = mix(col, border_color.rgb, fill(med - 0.78, aa * 5.0));
	col = mix(col, accent_color.rgb, fill(abs(med - 0.66) - 0.05, aa * 5.0) * pattern_strength);
	col = mix(col, field_color.rgb * 0.92, fill(med - 0.56, aa * 5.0));
	col = mix(col, pattern_color.rgb, fill(stepped_diamond(m, 0.26, 3.0), aa * 5.0) * pattern_strength);
	col = mix(col, border_color.rgb, fill(stepped_diamond(m, 0.09, 1.0), aa * 5.0));
	return col;
}

void fragment() {
#ifdef CUTAWAY
	if (cutaway_hidden(v_world_pos)) {
		discard;
	}
#endif
	vec2 total = size + vec2(fringe * 2.0, 0.0);
	vec2 p = UV * total - vec2(fringe, 0.0);
	float aa = max(fwidth(p.x), fwidth(p.y)) * 0.75;
	float n = tn_noise2(v_world_pos.xz * 3.0);
	float fine = tn_noise2(v_world_pos.xz * 40.0);

	if (p.x < 0.0 || p.x > size.x) {
		// Püsküller: soluk iplik demetleri, uçları düzensiz.
		float t = p.x < 0.0 ? -p.x : p.x - size.x;
		float thread = abs(fract(p.y / 0.045) - 0.5);
		float tip = fringe * (0.75 + 0.25 * tn_noise2(vec2(floor(p.y / 0.045) * 7.3, 3.1)));
		if (thread > 0.24 || t > tip) {
			discard;
		}
		ALBEDO = pattern_color.rgb * (0.7 + fine * 0.15) * (1.0 - smoothstep(0.0, tip, t) * 0.2);
	} else {
		// Elle çizilmiş gibi hafif titreyen desen koordinatı.
		vec2 w = p + vec2(tn_noise2(p * 3.0) - 0.5, tn_noise2(p * 3.0 + 11.0) - 0.5) * 0.02;
		vec2 e2 = min(w, size - w);
		float edge = min(e2.x, e2.y);
		float band_w = clamp(min(size.x, size.y) * 0.1, 0.08, 0.14);
		vec3 col = border(field_color.rgb, w, e2, edge, band_w, aa);
		if (edge > band_w + 0.02) {
			col = field(col, w - size * 0.5, size * 0.5 - vec2(band_w + 0.04), aa);
		}
		// Dokuma izi, aşınma ve boyalı renk dalgalanması (geniş fırça lekeleri + ince dokuma).
		float weave = abs(fract(p.y * 90.0) - 0.5) * 2.0;
		col *= 0.95 + weave * 0.06;
		float worn = smoothstep(0.55, 0.85, n) * wear;
		col = mix(col, col * 1.12 + vec3(0.025), worn);
		float strokes = tn_noise2(vec2(p.x * 2.2, p.y * 7.0) + n);
		col *= 0.88 + fine * 0.1 + (strokes - 0.5) * 0.16;
		ALBEDO = col;
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
