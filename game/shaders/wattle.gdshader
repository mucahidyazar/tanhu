// Örgü çit (ağıl; scripts/maps/childhood_site.gd): ince kazıklar arasına dokunmuş çubuklar. Geometri tek şerittir, örgü burada çizilir:
// UV metredir (x çit boyunca, y yerden). Satırlar arasında ve çubukların kazık arkasına geçtiği yerde boşluk vardır (discard): içeriden ve
// dışarıdan görünür. İki yüzlü. Gölgede de delikli düşer. Işık çizgisi soft_toon'un dilindedir.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"

uniform vec3 rod_light : source_color = vec3(0.6, 0.47, 0.3);
uniform vec3 rod_dark : source_color = vec3(0.3, 0.22, 0.14);
uniform vec3 stake_color : source_color = vec3(0.26, 0.19, 0.13);
// Çubukların aralığı ve ince kazıkların aralığı (metre).
uniform float rod_spacing = 0.085;
uniform float stake_spacing = 0.34;
// Çubuğun kalınlığının satıra oranı (kalanı boşluk).
uniform float rod_fill : hint_range(0.3, 1.0) = 0.86;

void fragment() {
	vec2 p = UV;
	// Satırlar hafifçe dalgalanır.
	float wave = (tn_noise2(vec2(p.x * 1.3, floor(p.y / rod_spacing) * 3.7)) - 0.5) * 0.7;
	float v = p.y / rod_spacing + wave;
	float row = floor(v);
	float f = fract(v);
	float seed = tn_hash12(vec2(row, 3.0));
	// Örgü: çubuk bir kazığın önünden, öbürünün arkasından geçer.
	float side = sin(PI * p.x / stake_spacing + PI * row);
	float across = abs(f * 2.0 - 1.0);
	float fill = rod_fill * (0.84 + 0.16 * abs(side));
	if (across > fill) {
		discard;
	}
	float round_shade = 1.0 - across * across;
	vec3 col = mix(rod_dark, rod_light * (0.82 + seed * 0.34), round_shade * (0.55 + 0.45 * side * 0.5 + 0.22));
	// İnce kazık: çubuğun arkasına geçtiği yerde görünür.
	float sx = abs(fract(p.x / stake_spacing + 0.5) * 2.0 - 1.0);
	if (sx < 0.1 && side < -0.2) {
		col = stake_color;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
