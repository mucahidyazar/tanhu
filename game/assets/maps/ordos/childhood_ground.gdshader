// Bozkırın zemini: doğumun ve Çocukluk'un (OrdosWorld.steppe_material; scripts/maps/ordos_world.gd, childhood_site.gd; K98: kadraj 38°, 22–40 m; doğumun ay karesinde ufka dek).
// Bu zemin maskeden (ChildhoodGround: R açık toprak, G kum, B çakıl, A koyu otluk) ve üç ücretsiz dokudan katmanlanır; dokular metre ölçeğindedir: 22 m'de
// çakıl, çatlak ve ot dibi görünür. Dik yüzler (kademe, tepe) yüksekliğe göre tabakalı kaya rengine döner; yamaçlar ışığa göre koyulaşır. Düşen gölge serindir.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"

uniform sampler2D mask_tex : filter_linear, repeat_disable;
// (x0, z0, 1/en, 1/boy): dünya xz → maske uv'si.
uniform vec4 mask_rect = vec4(0.0, 0.0, 0.01, 0.01);

group_uniforms textures;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
// Dokunun dünyada kapladığı kare (metre).
uniform float grass_tile = 5.0;
uniform float soil_tile = 6.0;
uniform float gravel_tile = 3.6;

group_uniforms colors;
uniform vec3 straw : source_color = vec3(0.61, 0.52, 0.33);
uniform vec3 straw_light : source_color = vec3(0.69, 0.6, 0.4);
uniform vec3 straw_dark : source_color = vec3(0.5, 0.43, 0.28);
uniform vec3 soil : source_color = vec3(0.58, 0.5, 0.39);
uniform vec3 soil_light : source_color = vec3(0.66, 0.58, 0.46);
uniform vec3 sand : source_color = vec3(0.68, 0.62, 0.5);
uniform vec3 sand_dark : source_color = vec3(0.57, 0.51, 0.41);
uniform vec3 gravel : source_color = vec3(0.57, 0.53, 0.46);
uniform vec3 lush : source_color = vec3(0.45, 0.42, 0.26);
uniform vec3 rock_light : source_color = vec3(0.6, 0.55, 0.48);
uniform vec3 rock_dark : source_color = vec3(0.38, 0.34, 0.3);

group_uniforms lighting;
uniform vec3 shadow_tint : source_color = vec3(0.66, 0.67, 0.78);
uniform float shadow_level : hint_range(0.0, 1.0) = 0.72;
// Yamaçların ışığa göre koyulaşması: kademeler yukarıdan bununla okunur.
uniform float slope_light : hint_range(0.0, 1.0) = 0.6;
group_uniforms;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = NORMAL;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Dokudan parlaklık oranı: örnek / dokunun ortalaması (en küçük mip). Yalnız parlaklık: dokunun kendi rengi zemine geçmez (renk düzenin).
vec3 ratio(sampler2D tex, vec2 uv, float lod) {
	float mean = max(luma(textureLod(tex, vec2(0.5), 12.0).rgb), 0.02);
	return vec3(luma(texture(tex, uv, lod).rgb) / mean);
}

void fragment() {
	vec2 p = v_world_pos.xz;
	// Maskenin kenarı gürültüyle kırılır: 1 m'lik örnek yumuşak leke olmasın.
	vec2 jitter = vec2(tn_noise2(p * 0.85), tn_noise2(p * 0.85 + 19.0)) - 0.5;
	vec2 jitter2 = vec2(tn_noise2(p * 2.7 + 7.0), tn_noise2(p * 2.7 + 31.0)) - 0.5;
	vec2 muv = (p + jitter * 2.2 + jitter2 * 0.7 - mask_rect.xy) * mask_rect.zw;
	vec4 m = texture(mask_tex, muv);
	// Maskenin alanının dışı (ufka uzanan bozkır; doğumun ay karesi batıya bakar): kenarın örnekleri uzayıp ufka düz çizgiler çekmesin,
	// maske alanın son 15 m'sinde söner, dışı ot dibidir.
	vec2 edge = min(muv, vec2(1.0) - muv) / max(mask_rect.zw, vec2(1e-6));
	m *= smoothstep(0.0, 15.0, min(edge.x, edge.y));
	float big = tn_fbm2(p * 0.035, 3);
	float mid = tn_fbm2(p * 0.16, 2);
	// Taban: ot dibi. Büyük lekeler saman tonlarını gezer, doku metre ölçeğinde okunur.
	vec3 col = mix(straw_dark, straw, smoothstep(0.3, 0.52, big));
	col = mix(col, straw_light, smoothstep(0.52, 0.72, big));
	col = mix(col, col * 0.9, smoothstep(0.45, 0.7, mid));
	col *= mix(vec3(1.0), ratio(grass_tex, p / grass_tile, -0.5), 0.5);
	// Koyu otluk.
	float lush_w = smoothstep(0.35, 0.72, m.a + (mid - 0.5) * 0.3);
	col = mix(col, lush * mix(vec3(1.0), ratio(grass_tex, p / (grass_tile * 0.7) + 0.37, 0.0), 0.6), lush_w * 0.72);
	// Açık toprak.
	float bare_w = smoothstep(0.42, 0.72, m.r + (mid - 0.5) * 0.25);
	vec3 soil_col = mix(soil, soil_light, smoothstep(0.35, 0.65, tn_noise2(p * 0.42))) * mix(vec3(1.0), ratio(soil_tex, p / soil_tile, -0.5), 0.75);
	col = mix(col, soil_col, bare_w * 0.9);
	// Çakıl: taş dokusu güçlü.
	float gravel_w = smoothstep(0.34, 0.64, m.b + (mid - 0.5) * 0.3);
	vec3 gravel_col = gravel * mix(vec3(1.0), ratio(gravel_tex, p / gravel_tile, -0.75), 1.0);
	col = mix(col, gravel_col, gravel_w);
	// Kum: açık, kuruma çatlaklı (hücre kenarı).
	if (m.g > 0.02) {
		float pale_w = smoothstep(0.3, 0.62, m.g + (mid - 0.5) * 0.2);
		vec3 sand_col = mix(sand_dark, sand, smoothstep(0.3, 0.7, tn_noise2(p * 0.6)));
		sand_col *= mix(vec3(1.0), ratio(soil_tex, p / (soil_tile * 0.6) + 0.71, 0.5), 0.45);
		// Rüzgâr çizgisi: kumun üstünde ince, uzun dalga.
		float ripple = smoothstep(0.62, 0.9, sin(dot(p, vec2(2.6, 1.1)) + tn_noise2(p * 0.5) * 3.0) * 0.5 + 0.5);
		sand_col *= 1.0 - ripple * 0.06;
		col = mix(col, sand_col, pale_w);
	}
	// Taş kırıntısı: küçük, seyrek koyu ve açık benekler (22 m'de ≈8 piksel).
	float speck = tn_noise2(p * 8.5);
	float speck_b = tn_noise2(p * 13.0 + 9.0);
	col *= 1.0 - smoothstep(0.8, 0.86, speck) * 0.34 * (1.0 - m.g * 0.6);
	col = mix(col, rock_light * 1.05, smoothstep(0.86, 0.9, speck_b) * 0.45 * (0.25 + m.b * 0.75));
	// Dik yüz: tabakalı kaya.
	vec3 n = normalize(v_world_normal);
	float steep = smoothstep(0.83, 0.68, n.y + (jitter.x * 0.04));
	if (steep > 0.001) {
		float bands = fract(v_world_pos.y * 1.2 + jitter.y * 0.6 + big * 2.0);
		vec3 rock = mix(rock_dark, rock_light, 0.55 + 0.3 * smoothstep(0.1, 0.6, bands));
		rock *= mix(vec3(1.0), ratio(gravel_tex, p / (gravel_tile * 1.4), 0.0), 0.8);
		col = mix(col, rock, steep * 0.85);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float slope = mix(1.0, clamp(dot(NORMAL, LIGHT) * 0.75 + 0.45, 0.0, 1.0), slope_light);
		vec3 shadow = shadow_tint * shadow_level;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * slope * mix(shadow, vec3(1.0), ATTENUATION);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	}
}
