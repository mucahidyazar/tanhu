// Kaya kümeleri (oyun alanının kenarındaki uzun, yuvarlak taş grupları) ile çayıra ve vadiye serpiştirilmiş
// kayalar için malzeme. Renkler 4. referansın (assets/_reference/menu_camp.png) ve Meshy kayalarının
// (assets/nature/boulder_a, boulder_b) gri granit + yeşil yosun ailesindendir (gündüz renkleri; gece görünümünü
// dünyanın renk ayarı verir). Işık bütün AtW malzemelerinin ortak iki tonlu modelidir (atw_light).
//
// İki renk kaynağı:
//   - Kümeler (use_vertex_albedo = false): RockField.boulder_mesh() köşe rengini doldurur:
//     r = çatlak derinliği, g = dilim tonu (her dilim biraz farklı), b = yükseklik (0 taban, 1 tepe).
//     Gri taşın üstünde fırça lekesi gibi açık yamalar ve küçük koyu benekler, üst yüzeylerde yeşil yosun
//     (kubbelerin omzundan kısa dillerle sarkar), dikey çatlaklarda ve dilim aralarında koyu gölge.
//   - Serpiştirilmiş kayalar (use_vertex_albedo = true): TreeKit.baked_lod() Meshy dokusunu köşe rengine
//     işler, uzak vadi kayalarına RockField.painted_rock() aynı dokudan ölçülen renkleri işler (sRGB; köşe
//     aşamasında doğrusala çevrilir); burada yalnızca doku tonu (saturation, tint) ve fırça lekeleri uygulanır.
// Kamera örtmesi (yalnızca kümelerde açıktır): kamera (occlusion_from) ile karakter (occlusion_to) arasındaki
// tüpün içinde kalan parçalar noktalı (dither) biçimde saydamlaşır. FollowCamera her karede yazar.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

uniform bool use_vertex_albedo = false;
group_uniforms stone;
uniform vec4 rock_color : source_color = vec4(0.47, 0.47, 0.44, 1.0);
uniform vec4 blotch_color : source_color = vec4(0.57, 0.57, 0.54, 1.0);
uniform vec4 speck_color : source_color = vec4(0.3, 0.3, 0.29, 1.0);
// Tabana yakın, toprağa değen nemli koyu gri ve çatlakların içi.
uniform vec4 base_color : source_color = vec4(0.33, 0.33, 0.31, 1.0);
uniform vec4 crack_color : source_color = vec4(0.17, 0.18, 0.17, 1.0);
// Açık yamaların ölçeği (büyüdükçe lekeler küçülür) ve miktarı.
uniform float blotch_scale = 1.1;
uniform float blotch_amount : hint_range(0.0, 1.0) = 0.38;
uniform float speck_amount : hint_range(0.0, 1.0) = 0.3;
group_uniforms moss;
uniform vec4 moss_color : source_color = vec4(0.29, 0.37, 0.12, 1.0);
uniform vec4 moss_light : source_color = vec4(0.42, 0.5, 0.17, 1.0);
// 0 = yosunsuz, 1 = yosun yanlara kadar iner.
uniform float moss_amount : hint_range(0.0, 1.0) = 0.5;
group_uniforms vertex_albedo;
// Köşe rengi kipinde doku tonu: doygunluk ve renk çarpanı (Meshy kahraman kayalarıyla aynı ayar).
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float brush_strength : hint_range(0.0, 0.4) = 0.08;
uniform float brush_scale = 3.0;
group_uniforms occlusion;
uniform vec3 occlusion_from = vec3(0.0);
uniform vec3 occlusion_to = vec3(0.0);
uniform float occlusion_radius = 0.0;
// Örtmede en fazla ne kadarının silineceği (taş hayalet gibi görünmeye devam eder).
uniform float occlusion_strength : hint_range(0.0, 1.0) = 0.8;
group_uniforms;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// 4x4 sıralı (Bayer) titreşim eşiği: 0..1 aralığında, piksel başına sabit desen.
float bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	if (use_vertex_albedo) {
		COLOR.rgb = srgb_to_linear(COLOR.rgb);
	}
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

// Kümelerin prosedürel taşı: gri granit, açık yamalar, benekler, çatlaklar ve yosun.
vec3 formation_albedo(vec3 p, vec3 n, float crack, float tint, float height) {
	// Boyalı açık lekeler: bükülmüş hücresel gürültünün eşiklenmesi (kırık kenarlı yamalar).
	vec3 q = p * blotch_scale;
	q += vec3(tn_fbm3(q * 0.9, 2), tn_fbm3(q * 0.9 + 7.1, 2), tn_fbm3(q * 0.9 + 3.7, 2)) * 0.9;
	float blot = 1.0 - smoothstep(blotch_amount - 0.06, blotch_amount + 0.03, tn_worley3(q));
	vec3 stone = mix(rock_color.rgb, blotch_color.rgb, blot);
	// Küçük koyu benekler.
	float speck = 1.0 - smoothstep(0.05, 0.09, tn_worley3(q * 3.3 + 11.0));
	stone = mix(stone, speck_color.rgb, speck * speck_amount);
	// Her dilim kendi tonunda (biraz sıcak ya da biraz serin gri).
	stone *= mix(vec3(1.02, 1.0, 0.97), vec3(0.95, 0.96, 0.99), tint);
	// Tabana doğru nemli, koyu gri (toprağa yakın kısım).
	float n1 = tn_fbm3(p * 1.4, 3);
	stone = mix(base_color.rgb, stone, smoothstep(0.0, 0.3, height + (n1 - 0.5) * 0.14));
	// Çatlaklar ve dilim aralıkları: koyu gölge.
	float crack_mask = smoothstep(0.16, 0.7, crack);
	stone = mix(stone, crack_color.rgb, crack_mask * 0.85);
	// Yosun: yukarı bakan yüzeylerde büyük, düzensiz yamalar; kubbelerin omzundan kısa dillerle sarkar.
	float n2 = tn_noise3(p * 6.0);
	float up = smoothstep(0.35, 0.85, n.y + (n1 - 0.5) * 0.6);
	float patches = smoothstep(0.32, 0.58, tn_fbm3(p * 1.7 + 4.3, 3));
	float drip = tn_noise2(vec2((p.x + p.z) * 3.1, p.y * 0.45)) * 0.65 + tn_noise2(vec2((p.x - p.z) * 6.3, p.y * 0.9)) * 0.35;
	float shoulder = smoothstep(0.55, 0.9, height) * smoothstep(0.42, 0.62, drip);
	// Her dilimin yosunu biraz farklı: kimi neredeyse çıplak, kimi kalın örtülü.
	float slice_moss = (tint - 0.5) * 0.3;
	float coverage = max(up * mix(0.35, 1.0, patches), shoulder * 0.85) * (moss_amount * 2.0) + slice_moss;
	float moss = smoothstep(0.45, 0.7, coverage + (n2 - 0.5) * 0.3) * smoothstep(0.25, 0.5, height);
	// Çatlakların üst kısmında da yosun birikir.
	moss = max(moss, crack_mask * smoothstep(0.75, 0.95, height) * 0.7);
	vec3 moss_col = mix(moss_color.rgb, moss_light.rgb, clamp(n2 * 0.6 + up * 0.3, 0.0, 1.0));
	return mix(stone, moss_col, moss);
}

// Serpiştirilmiş Meshy kayası: dokudan işlenmiş köşe rengi + doku tonu + fırça lekeleri.
vec3 baked_albedo(vec3 p, vec3 col) {
	col *= albedo_tint.rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturation), vec3(0.0));
	float n = tn_noise3(p * brush_scale) * 0.6 + tn_noise3(p * brush_scale * 2.7 + 7.1) * 0.4;
	return col * (1.0 + (n - 0.5) * 2.0 * brush_strength);
}

void fragment() {
	vec3 p = v_world_pos;
	// Görüş hattını örten parçaları sil (gölge geçişinde değil: orada "kamera" ışıktır).
	if (occlusion_radius > 0.0 && distance(CAMERA_POSITION_WORLD, occlusion_from) < 0.5) {
		vec3 seg = occlusion_to - occlusion_from;
		float t = clamp(dot(p - occlusion_from, seg) / max(dot(seg, seg), 0.0001), 0.0, 1.0);
		float d = distance(p, occlusion_from + seg * t);
		float fade = (1.0 - smoothstep(occlusion_radius * 0.55, occlusion_radius, d)) * (1.0 - smoothstep(0.85, 0.97, t));
		if (fade * occlusion_strength > bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
	if (use_vertex_albedo) {
		ALBEDO = baked_albedo(p, COLOR.rgb);
	} else {
		ALBEDO = formation_albedo(p, normalize(v_world_normal), COLOR.r, COLOR.g, COLOR.b);
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
