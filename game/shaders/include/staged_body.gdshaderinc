// Aşama kitinin ortak gövdesi (godot.md §6.7; structures.md §9): staged.gdshader (kalın parçalar, cull_back) ve staged_double.gdshader
// (ince parçalar: keçe, örtü, kuşak, halat; iki yüzlü) bunu içerir. Köşe verisi StagedMesh'indir (scripts/world/structures/staged_mesh.gd):
//   COLOR.rgb renk, COLOR.a sınıf / 8; CUSTOM0 (aşama, sıra, kip, tohum); CUSTOM1 (pivot xyz, kipin ölçüsü); UV desen; UV2 (gizlenme aşaması, desen).
// Örnek tekdüzenleri yapının durumudur (SiteState; StagedStructure yazar): stage en son biten aşama, stage_t sıradaki aşamanın oranı,
// damage üst havuzun eksik payı, burn kömürleşme, tear yırtık, snow kar örtüsü, cut odanın kesiti (çatı kalkar, K98), glow kapı ve ocak
// parıltısı, frame_on iskeletin (kerege, uuk) tam yurtta da görünmesi, shake vuruş sallantısı. Tam ve hasarsız yapıda (stage 7, öteki
// tekdüzenler 0) köşe kodu konuma dokunmaz, parça kodu discard etmez.

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

instance uniform int stage = 7;
instance uniform float stage_t = 0.0;
instance uniform float damage = 0.0;
instance uniform float burn = 0.0;
instance uniform float tear = 0.0;
instance uniform float snow = 0.0;
instance uniform float cut = 0.0;
instance uniform float glow = 0.0;
instance uniform float frame_on = 0.0;
instance uniform float shake = 0.0;
// Geri düşüş: stage'in üstünde fall_from'a dek parçalar fall_t ile çöker (1 → 0).
instance uniform int fall_from = -1;
instance uniform float fall_t = 0.0;

// Milletin süs renkleri (YurtStyle): desenin motifi ve ikinci rengi.
uniform vec4 motif_color : source_color = vec4(0.93, 0.86, 0.7, 1.0);
uniform vec4 accent_color : source_color = vec4(0.23, 0.64, 0.6, 1.0);
uniform vec4 snow_color : source_color = vec4(0.9, 0.93, 0.98, 1.0);
uniform float brush_strength : hint_range(0.0, 0.6) = 0.1;
uniform float brush_scale = 2.6;
// Kesit (yerel metre, kök ölçeğinden önce): kameraya bakan yarının alçak duvarı, her yerde kesilen yükseklik, tavan.
uniform float cut_low = 0.55;
uniform float cut_top = 1.95;
uniform float cut_ceiling = 6.0;
uniform float cut_radius = 4.0;

varying vec3 v_world;
varying vec3 v_local;
varying float v_strip;
varying float v_cls;
varying float v_pattern;
varying float v_seed;
varying vec3 v_origin;
#ifdef FIELD
// YurtField (MultiMesh): INSTANCE_CUSTOM x keçe tonu (rütbe: ×0,78 / ×1 / ×1,12), y kapı ve ocak parıltısı, z yapım yüksekliği (aCut:
// 0..1, yarım yurt uzaktan yarım görünür), w yanık (aChar).
varying vec4 v_field;
#endif

void vertex() {
	float ps = CUSTOM0.x;
	float ord = CUSTOM0.y;
	int md = int(CUSTOM0.z + 0.5);
	float sd = CUSTOM0.w;
	vec3 piv = CUSTOM1.xyz;
	float sub = CUSTOM1.w;
	float st = float(stage);
	float k = 1.0;
	if (ps > st + 0.5) {
		k = ps < st + 1.5 ? clamp((stage_t - ord * 0.88) / 0.12, 0.0, 1.0) : 0.0;
		if (ps < float(fall_from) + 0.5) {
			k = max(k, fall_t);
		}
	}
	if (st >= UV2.x - 0.5 && frame_on < 0.5) {
		k = 0.0;
	}
	v_strip = 1.0;
	if (k < 1.0) {
		float e = k * k * (3.0 - 2.0 * k);
		vec3 rel = VERTEX - piv;
		if (md == 0) {
			rel.y *= e;
		} else if (md == 1) {
			rel *= e;
		} else if (md == 2) {
			// Kanat yelpaze gibi pivotunun açısından açılır.
			float a0 = atan(piv.x, piv.z);
			float da = atan(VERTEX.x, VERTEX.z) - a0;
			da = da - 6.2831853 * floor((da + 3.14159265) / 6.2831853);
			float na = a0 + da * e;
			float rr = length(VERTEX.xz);
			rel = vec3(sin(na) * rr, VERTEX.y, cos(na) * rr) - piv;
		} else if (md == 3) {
			// Tündük bakanlarla alttan kalkar (sub: inişin yüksekliği).
			rel.y -= (1.0 - e) * sub;
			rel.x += (1.0 - e) * 0.08 * sin(stage_t * 40.0 + sd * 6.0);
		} else if (md == 4) {
			// Uuk dikten iner: pivotun çevresinde radyal düzlemde döner.
			float sw = (1.0 - e) * 1.1;
			float c = cos(sw);
			float s = sin(sw);
			vec2 rd = normalize(piv.xz + vec2(1e-4));
			float h = dot(rel.xz, rd);
			float nh = h * c - rel.y * s;
			rel.y = h * s + rel.y * c;
			rel.xz += rd * (nh - h);
		} else if (md == 5) {
			v_strip = k - sub;
		}
		if (k <= 0.0 && md != 5) {
			rel = vec3(0.0);
		}
		VERTEX = piv + rel;
	}
	if (shake > 0.0) {
		float sk = shake * sin(tn_time() * 26.0 + sd * 6.28);
		VERTEX.xz += vec2(0.7, 0.4) * sk * smoothstep(0.0, 3.0, VERTEX.y);
	}
	v_cls = COLOR.a * 8.0;
	v_pattern = UV2.y;
	v_seed = sd;
	v_local = VERTEX;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_origin = MODEL_MATRIX[3].xyz;
#ifdef FIELD
	v_field = INSTANCE_CUSTOM;
#endif
}

// Desenler (UV: x bant yüksekliği birimiyle çevre boyunca, y enine 0..1; çatıda x açının payı, y saçaktan tepeye).
float sdf_box(vec2 p, vec2 c, vec2 h) {
	vec2 d = abs(p - c) - h;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec3 pattern_color(int pat, vec2 uv, vec3 base) {
	if (pat == 1) {
		// Menderes (hun): alt ve üst kenar şeridi, aralarında dönen anahtar.
		vec2 f = vec2(fract(uv.x * 0.5), uv.y);
		float d = min(abs(uv.y - 0.14) - 0.05, abs(uv.y - 0.86) - 0.05);
		d = min(d, sdf_box(f, vec2(0.18, 0.47), vec2(0.05, 0.27)));
		d = min(d, sdf_box(f, vec2(0.45, 0.70), vec2(0.27, 0.05)));
		d = min(d, sdf_box(f, vec2(0.67, 0.52), vec2(0.05, 0.22)));
		d = min(d, sdf_box(f, vec2(0.52, 0.34), vec2(0.15, 0.05)));
		return mix(base, motif_color.rgb, 1.0 - smoothstep(-0.006, 0.012, d));
	} else if (pat == 2) {
		// Plaka sırası ve turkuaz nokta (yuezhi): altın plaka, içinde koyu halka; aralarında turkuaz.
		vec2 f = vec2(fract(uv.x * 0.55), uv.y);
		float plate = sdf_box(f, vec2(0.38, 0.5), vec2(0.3, 0.33));
		float ring = abs(length((f - vec2(0.38, 0.5)) * vec2(1.0, 0.85)) - 0.17) - 0.035;
		float dot_d = length((f - vec2(0.86, 0.5)) * vec2(1.0, 0.6)) - 0.09;
		vec3 c = base;
		c = mix(c, motif_color.rgb, 1.0 - smoothstep(-0.01, 0.01, plate));
		c = mix(c, base * 0.6, (1.0 - smoothstep(-0.01, 0.01, ring)) * (1.0 - smoothstep(-0.01, 0.01, plate)));
		c = mix(c, accent_color.rgb, 1.0 - smoothstep(-0.01, 0.01, dot_d));
		return c;
	} else if (pat == 3) {
		// Düz çift şerit (usun).
		float d = min(abs(uv.y - 0.3) - 0.06, abs(uv.y - 0.7) - 0.06);
		return mix(base, motif_color.rgb, 1.0 - smoothstep(-0.01, 0.01, d));
	} else if (pat == 4) {
		// Tepeden ışın (tunghu çatısı): kızıl ışınlar (uv.x ışın birimi).
		float f = abs(fract(uv.x) - 0.5);
		float w = mix(0.16, 0.05, uv.y);
		return mix(base, motif_color.rgb, 1.0 - smoothstep(w, w + 0.02, f));
	} else if (pat == 5) {
		// Baklava (dingling, baiyang).
		vec2 f = vec2(fract(uv.x * 0.8) - 0.5, uv.y - 0.5);
		float d = abs(f.x) + abs(f.y) - 0.34;
		return mix(base, motif_color.rgb, 1.0 - smoothstep(-0.01, 0.01, max(d, -(abs(f.x) + abs(f.y) - 0.18))));
	} else if (pat == 6) {
		// Hayvan plakası (loufan): koyu zeminde yuvarlak plaka.
		vec2 f = vec2(fract(uv.x * 0.6), uv.y);
		float d = length((f - vec2(0.5, 0.5)) * vec2(1.0, 0.75)) - 0.28;
		return mix(base, motif_color.rgb, 1.0 - smoothstep(-0.01, 0.01, d));
	} else if (pat == 7) {
		// İç duvar: krem örtünün önünde boyalı kerege (çapraz çıta), kesişimde bağ.
		vec2 g = uv * vec2(6.4, 6.4);
		float a = abs(fract((g.x + g.y) * 0.5) - 0.5);
		float b = abs(fract((g.x - g.y) * 0.5) - 0.5);
		float lat = 1.0 - smoothstep(0.035, 0.06, min(a, b));
		return mix(base, motif_color.rgb, lat * 0.9);
	} else if (pat == 8) {
		// İç çatı: saçaktan tepeye boyalı uuk, tepeye doğru is.
		float f = abs(fract(uv.x) - 0.5);
		float pole = 1.0 - smoothstep(0.05, 0.09, f);
		vec3 c = mix(base, motif_color.rgb, pole);
		return c * mix(1.0, 0.55, smoothstep(0.4, 1.0, uv.y));
	} else if (pat == 9) {
		// Kamış hasır (çiy): ince dikey çizgiler, iki yatay bağ.
		float f = abs(fract(uv.x * 22.0) - 0.5);
		float d = min(abs(uv.y - 0.33), abs(uv.y - 0.7));
		vec3 c = base * (0.85 + 0.2 * smoothstep(0.1, 0.4, f));
		return mix(c, motif_color.rgb, 1.0 - smoothstep(0.015, 0.03, d));
	}
	return base;
}

void fragment() {
	if (v_strip < 0.0) {
		discard;
	}
	int cls = int(v_cls + 0.5);
	// Kesit: oyuncu odadayken çatı kalkar, kameraya bakan yarı alçalır (K98: içerisi yukarıdan görünür).
	if (cut > 0.0) {
		vec3 rel = v_world - v_origin;
		float sy = max(length(MODEL_MATRIX[1].xyz), 0.001);
		float sx = max(length(MODEL_MATRIX[0].xyz), 0.001);
		vec2 cd = CAMERA_POSITION_WORLD.xz - v_origin.xz;
		cd = length(cd) > 0.001 ? normalize(cd) : vec2(0.0, 1.0);
		float len = length(rel.xz);
		if (len < cut_radius * sx) {
			float facing = len > 0.001 ? dot(rel.xz / len, cd) : 0.0;
			float h = mix(cut_top, cut_low, smoothstep(-0.2, 0.45, facing)) * sy;
			if (rel.y > mix(cut_ceiling * sy, h, smoothstep(0.0, 1.0, cut))) {
				discard;
			}
		}
	}
	vec3 col = COLOR.rgb;
	float k_glow = glow;
	float k_burn = burn;
#ifdef FIELD
	if (v_field.z < 0.999 && (v_world.y - v_origin.y) > v_field.z * cut_ceiling * max(length(MODEL_MATRIX[1].xyz), 0.001)) {
		discard;
	}
	col *= v_field.x > 0.0 ? v_field.x : 1.0;
	k_glow = max(k_glow, v_field.y);
	k_burn = max(k_burn, v_field.w);
#endif
	int pat = int(v_pattern + 0.5);
	if (pat > 0) {
		col = pattern_color(pat, UV, col);
	}
	float n = tn_noise3(v_world * brush_scale) * 0.6 + tn_noise3(v_world * brush_scale * 3.1) * 0.4;
	if (cls == 1) {
		// Keçe: yırtık delik açar, kenarı koyulaşır.
		if (tear > 0.0) {
			float h = tn_noise3(v_world * 0.85 + vec3(v_seed * 7.0)) * 0.7 + tn_noise3(v_world * 2.6) * 0.3;
			float edge = tear * 0.42;
			if (h < edge) {
				discard;
			}
			col *= mix(0.42, 1.0, smoothstep(edge, edge + 0.06, h));
		}
		col *= 0.95 + 0.08 * tn_noise3(v_world * 9.0);
	}
	col *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	if (damage > 0.0) {
		col *= 1.0 - 0.24 * damage * smoothstep(0.35, 0.85, n);
	}
	if (k_burn > 0.0) {
		float ch = smoothstep(0.15, 0.85, k_burn + (n - 0.5) * 0.5);
		col *= mix(1.0, 0.16, ch);
	}
	if (snow > 0.0 && cls != 4) {
		// Kar yalnız yukarı bakan yüzde tutar: keçe çatıda tam, ahşap ve taşta seyrek, eşyada yok (kayıt başına snow; ocak çevresi 0).
		float k_cls = cls == 1 ? 1.0 : (cls == 5 ? 0.85 : (cls == 6 || cls == 2 ? 0.45 : (cls == 3 ? 0.35 : 0.0)));
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		float patchy = tn_noise3(v_world * 1.3) * 0.65 + tn_noise3(v_world * 4.1) * 0.35;
		float up = smoothstep(0.5, 0.92, wn.y + (patchy - 0.5) * 0.45);
		col = mix(col, snow_color.rgb, up * snow * k_cls);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	if (cls == 4) {
		EMISSION = col * k_glow * 2.4;
	}
}
