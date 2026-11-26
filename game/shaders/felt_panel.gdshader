// Mit sinemasının keçe aplike panoları (Yol Haritası myth-panels; story.md §3, godot.md §3.6). Yurdun keçesi
// shaders/felt.gdshader'dır; bu gölgelendirici panonun kesilmiş keçe parçaları ve uzun keçe şerit içindir.
//
// Bir malzeme bütün parçalara gider; parçayı örnek tekdüzenleri ayırır (MeshInstance3D.set_instance_shader_parameter):
//   shape_color  parçanın keçe rengi; stitch_color  dikiş ipliği (alfa 0: renkten türetilir);
//   emission     közün ve kıvılcımın parıltısı (0 yok); seed  lif gürültüsünün kayması; pattern  0 parça, 1 şerit.
// FeltPanel'in ağı (scripts/cine/felt_panel.gd):
//   UV   x = dış hat boyunca yay uzunluğu (m), y = dikiş şeridinde 0 (dış kenar) → 1 (iç halka); iç dolgu y = 1.
//        Şeritte (pattern 1) UV metredir: x şerit boyunca, y yukarı.
//   UV2  parçanın yerel x, y'si (m): keçe lifinin ve dokunun koordinatı (parça kıpırdayınca lifi de onunla gider).
// Keçe: Fabric034 (ambientCG, CC0; assets/_free/texture/fabric034) renk ve normal dokusu verilirse lif ondan, yoksa
// gürültüden gelir (use_textures). Işık soft_light.gdshaderinc'in yumuşak toon'udur. Zaman tn_time()'dandır.
// Görsel (gpt-image-2) gelince panonun katmanı albedo_texture ile dokuya geçebilir (use_albedo_texture).
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

instance uniform vec4 shape_color : source_color = vec4(0.8, 0.72, 0.6, 1.0);
instance uniform vec4 stitch_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
instance uniform float emission = 0.0;
instance uniform float seed = 0.0;
instance uniform int pattern = 0;

uniform bool use_textures = false;
uniform sampler2D felt_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D felt_normal : hint_normal, filter_linear_mipmap, repeat_enable;
// Keçe dokusunun metredeki tekrarı ve normalin gücü.
uniform float felt_scale = 2.2;
uniform float felt_normal_depth = 0.6;
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
// Görselin panodaki yeri (yerel m): x, y sol alt köşe; z, w en ve boy.
uniform vec4 albedo_rect = vec4(-2.6, -1.4, 5.2, 2.8);
// Dikiş: aralık (m), dikişin şeritteki yeri ve kalınlığı.
uniform float stitch_period = 0.032;
uniform float stitch_line = 0.55;
uniform float stitch_width = 0.16;
// Şeridin süsü: bordür yüksekliği (m), pano aralığı (m), şeridin yarı yüksekliği (m).
uniform vec4 border_color : source_color = vec4(0.52, 0.16, 0.1, 1.0);
uniform vec4 motif_color : source_color = vec4(0.9, 0.8, 0.62, 1.0);
uniform float border_height = 0.32;
uniform float panel_spacing = 6.0;
uniform float strip_half_height = 1.8;

varying vec2 v_local;

void vertex() {
	v_local = UV2;
}

// Koçboynuzu (koşkar müyiz): yurdun keçesindeki motifin sadesi (felt.gdshader ile aynı biçim).
float ram_horn(vec2 p) {
	vec2 q = vec2(abs(p.x), p.y);
	float horn = abs(length(q - vec2(0.19, 0.06)) - 0.14) - 0.04;
	if (q.y < 0.02 && q.x < 0.19) {
		horn = 1.0;
	}
	float curl = length(q - vec2(0.19, 0.06)) - 0.045;
	float stem = max(q.x - 0.04, abs(p.y + 0.12) - 0.2);
	float base = max(abs(p.y + 0.33) - 0.04, q.x - 0.3);
	return min(min(horn, curl), min(stem, base));
}

// Keçenin lifi: iki yönde çekilmiş ince gürültü ve bulutsu kabarma (dokusuzken). Örnek tekdüzeni (seed) yardımcı
// işlevde okunmaz, argümanla gelir: örnek tekdüzenleri yalnız vertex/fragment'te güvenle okunur.
float felt_fiber(vec2 p, float s) {
	float coarse = tn_fbm2(p * 6.0 + s * 7.13, 3);
	float fine_a = tn_noise2(vec2(p.x * 90.0, p.y * 30.0) + s);
	float fine_b = tn_noise2(vec2(p.x * 32.0 + p.y * 70.0, p.y * 85.0 - p.x * 20.0) + s * 3.1);
	return coarse * 0.6 + (fine_a + fine_b) * 0.2;
}

void fragment() {
	vec2 lp = v_local;
	vec3 base = shape_color.rgb;
	float band = UV.y;
	vec3 col = base;

	if (pattern == 1) {
		// Uzun keçe şerit: koyu zemin, alt ve üst bordürde koçboynuzu motifleri, panolar arasında dikişli ayraç.
		float top_d = strip_half_height - lp.y;
		float bot_d = lp.y + strip_half_height;
		float edge = min(top_d, bot_d);
		if (edge < border_height) {
			float by = clamp(edge / border_height, 0.0, 1.0);
			vec2 m = vec2(fract(lp.x / (border_height * 1.6)) - 0.5, by - 0.5);
			if (top_d < bot_d) {
				m.y = -m.y;
			}
			float d = ram_horn(m * vec2(1.0, 1.15));
			float motif = 1.0 - smoothstep(0.0, 0.04, d);
			float rim = 1.0 - smoothstep(0.05, 0.09, min(by, 1.0 - by));
			col = mix(border_color.rgb, motif_color.rgb, max(motif * 0.92, rim * 0.8));
		}
		float divider = abs(fract(lp.x / panel_spacing + 0.5) - 0.5) * panel_spacing;
		float div_band = 1.0 - smoothstep(0.14, 0.16, divider);
		col = mix(col, border_color.rgb * 0.92, div_band);
		float div_stitch = (1.0 - smoothstep(0.004, 0.008, abs(divider - 0.08))) * step(0.5, fract(lp.y / 0.04));
		col = mix(col, motif_color.rgb, div_stitch * 0.85);
	} else if (use_albedo_texture) {
		vec2 iuv = (lp - albedo_rect.xy) / albedo_rect.zw;
		col = texture(albedo_texture, vec2(iuv.x, 1.0 - iuv.y)).rgb;
	}

	// Keçenin dokusu: lif ve hafif kabarma.
	vec2 fp = lp * felt_scale + vec2(seed * 0.37, seed * 0.61);
	float fiber;
	vec3 nmap = vec3(0.5, 0.5, 1.0);
	if (use_textures) {
		float lum = dot(texture(felt_albedo, fp).rgb, vec3(0.299, 0.587, 0.114));
		fiber = lum;
		nmap = texture(felt_normal, fp).rgb;
	} else {
		fiber = felt_fiber(lp, seed);
		float nx = tn_noise2(lp * 140.0 + seed) - 0.5;
		float ny = tn_noise2(lp * 140.0 + seed + 17.0) - 0.5;
		nmap = vec3(0.5 + nx * 0.5, 0.5 + ny * 0.5, 1.0);
	}
	col *= 0.82 + fiber * 0.36;

	// Dikiş şeridi: kenara doğru hafif koyulaşma ve yay uzunluğu boyunca kesik kesik iplik.
	if (band < 0.999) {
		col *= mix(0.78, 1.0, smoothstep(0.0, 0.6, band));
		float along = fract(UV.x / stitch_period);
		float dash = smoothstep(0.08, 0.16, along) * (1.0 - smoothstep(0.62, 0.7, along));
		float across = 1.0 - smoothstep(stitch_width * 0.5, stitch_width * 0.5 + 0.06, abs(band - stitch_line));
		vec3 thread = stitch_color.a > 0.0 ? stitch_color.rgb : mix(base, vec3(0.95, 0.88, 0.72), 0.65);
		col = mix(col, thread, dash * across * 0.9);
	}

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	NORMAL_MAP = nmap;
	NORMAL_MAP_DEPTH = felt_normal_depth;
	if (emission > 0.0) {
		float t = tn_time();
		float flicker = 0.88 + 0.08 * sin(t * 7.3 + seed) + 0.04 * sin(t * 13.1 + seed * 2.0);
		EMISSION = base * emission * flicker * (0.75 + fiber * 0.5);
	}
}
