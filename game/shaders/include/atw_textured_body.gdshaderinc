// atw_textured, atw_textured_double ve atw_textured_cutaway shader'larının ortak gövdesi (render_mode dışında her
// şey burada; böylece tek ve çift yüzlü modeller aynı görünür). CUTAWAY tanımlıysa otağ kesiti uygulanır.
//
// Meshy ile üretilen dokulu modeller (yurt, ahır, atlar, kamp eşyaları, kayalar, ağaçlar) için malzeme:
// - Modelin elle boyanmış dokusu (albedo_texture) korunur. "Boya" ayarları onu kamp referansının
//   (assets/_reference/menu_camp.png) boyalı görünümüne yaklaştırır: fotoğraf gibi ince ayrıntı biraz
//   yumuşatılır (paint_softness), renkler hafifçe doygunlaşır, geniş yüzeylere düşük frekanslı fırça
//   lekeleri biner.
// - Işık ortak "After the Wind" cel modelidir (atw_light): düz aydınlık taraf, sabit oranlı gölge.
// - Kenarlarda ince "mürekkep" koyulaşması; tabanda nesneyi zemine oturtan yumuşak koyulaşma.
// - İsteğe bağlı: dokudaki sıcak kor renklerinin titreyerek parlaması (ember_glow) ve modelin bir
//   bölgesini canlandıran hafif hareketler (baş sallama, kuyruk sallama, nefes; bkz. "idle").
//   Hareketler mesh uzayında tanımlıdır (Meshy modelleri yaklaşık -0,95..0,95 aralığındadır).

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#ifdef CUTAWAY
#include "res://shaders/include/cutaway.gdshaderinc"
#endif

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0);

group_uniforms paint;
// Dokuyu biraz daha kaba mip seviyesinden okur: ince fotoğrafik ayrıntı yerine boya lekeleri (0 = kapalı).
uniform float paint_softness : hint_range(0.0, 3.0) = 0.6;
uniform float saturation : hint_range(0.0, 2.0) = 1.08;
// Değer (açık/koyu) kontrastı: 1 = doku olduğu gibi.
uniform float value_contrast : hint_range(0.5, 1.5) = 1.04;
// Dünya uzayında fırça lekeleri (tekdüze geniş yüzeyleri kırar).
uniform float brush_strength : hint_range(0.0, 0.3) = 0.05;
uniform float brush_scale = 2.5;
group_uniforms base_shade;
// Tabandan yukarı doğru azalan koyulaşma (zemin teması): yükseklik (metre) ve şiddet.
uniform float base_shade_height = 0.3;
uniform float base_shade_strength : hint_range(0.0, 1.0) = 0.2;
// Mesh uzayından metreye çevrim (MeshyProp doldurur): modelin taban y'si (mesh birimi) ve ölçeği (metre / birim).
// Verilmezse taban çok aşağıda sayılır: taban koyulaşması kendiliğinden kapanır.
uniform float model_base_y = -10000.0;
uniform float model_scale = 1.0;
group_uniforms ink;
uniform vec4 ink_color : source_color = vec4(0.22, 0.16, 0.13, 1.0);
uniform float ink_strength : hint_range(0.0, 1.0) = 0.25;
uniform float ink_width : hint_range(0.0, 0.6) = 0.12;
group_uniforms glow;
// Dokudaki kor renklerini (doygun turuncu-kırmızı) kendi kendine parlatır (0 = kapalı).
uniform float ember_glow = 0.0;
uniform vec3 ember_color : source_color = vec3(1.0, 0.42, 0.12);
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
group_uniforms idle;
// Baş sallama: nod_pivot çevresinde X ekseninde döndürme (radyan; artı = baş aşağı).
// nod_region: (x, y) z boyunca ağırlık rampasının başı ve sonu, (z, w) y boyunca rampa.
uniform float nod_angle = 0.0;
uniform vec3 nod_pivot = vec3(0.0);
uniform vec4 nod_region = vec4(0.0, 1.0, -1.0, 0.0);
uniform float nod_speed = 0.35;
// Kuyruk sallama: bölge (x, y) z boyunca rampa; (z, w) y boyunca kökten (0) uca (1). Genlik mesh birimidir.
uniform float swish_amount = 0.0;
uniform vec4 swish_region = vec4(0.0, -1.0, 1.0, 0.0);
uniform float swish_speed = 1.2;
// Nefes: gövde (|z| < breath_region.x ve y > breath_region.y) yana çok hafif genişler (oran).
uniform float breath_amount = 0.0;
uniform vec2 breath_region = vec2(0.5, 0.0);
uniform float breath_speed = 1.4;
group_uniforms;

varying vec3 v_world_pos;
varying float v_base_height;

// a'dan b'ye yumuşak rampa; a > b ise ters yönde (smoothstep'in her iki yönde tanımlı hali).
float atw_ramp(float x, float a, float b) {
	float t = clamp((x - a) / (b - a), 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

vec3 atw_idle(vec3 v, float t) {
	if (nod_angle != 0.0) {
		float w = atw_ramp(v.z, nod_region.x, nod_region.y) * atw_ramp(v.y, nod_region.z, nod_region.w);
		// Yavaş, düzensiz baş hareketi; arada bir otlanır gibi biraz daha iner.
		float graze = smoothstep(0.55, 1.0, sin(t * nod_speed * 0.37 + 1.1));
		float a = nod_angle * (0.3 * sin(t * nod_speed * 2.3) + 0.2 * sin(t * nod_speed * 3.7 + 0.6) + graze) * w;
		vec3 d = v - nod_pivot;
		float c = cos(a);
		float s = sin(a);
		v = nod_pivot + vec3(d.x, d.y * c - d.z * s, d.y * s + d.z * c);
	}
	if (swish_amount != 0.0) {
		float w = atw_ramp(v.z, swish_region.x, swish_region.y) * atw_ramp(v.y, swish_region.z, swish_region.w);
		v.x += swish_amount * w * sin(t * swish_speed + sin(t * 0.41) * 1.6);
	}
	if (breath_amount != 0.0) {
		float w = (1.0 - atw_ramp(abs(v.z), breath_region.x * 0.6, breath_region.x)) * atw_ramp(v.y, breath_region.y - 0.1, breath_region.y + 0.1);
		v.x *= 1.0 + breath_amount * w * (0.5 + 0.5 * sin(t * breath_speed));
	}
	return v;
}

void vertex() {
	if (nod_angle != 0.0 || swish_amount != 0.0 || breath_amount != 0.0) {
		// Her kopya kendi ritminde: evre, nesnenin dünyadaki yerinden gelir.
		float phase = dot(NODE_POSITION_WORLD.xz, vec2(1.37, 2.11));
		VERTEX = atw_idle(VERTEX, tn_time() + phase);
	}
	v_base_height = (VERTEX.y - model_base_y) * model_scale;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
#ifdef CUTAWAY
	if (cutaway_hidden(v_world_pos)) {
		discard;
	}
#endif
	vec3 tex = texture(albedo_texture, UV, paint_softness).rgb;
	vec3 col = tex * albedo_tint.rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturation), vec3(0.0));
	col = max(col * (1.0 + (l - 0.45) * (value_contrast - 1.0) * 2.0), vec3(0.0));
	float n = tn_noise3(v_world_pos * brush_scale) * 0.6 + tn_noise3(v_world_pos * brush_scale * 2.7 + 7.1) * 0.4;
	col *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	col *= 1.0 - base_shade_strength * (1.0 - atw_ramp(v_base_height, 0.0, base_shade_height));
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float ink = 1.0 - smoothstep(ink_width * 0.5, ink_width, facing);
	ALBEDO = mix(col, ink_color.rgb, ink * ink_strength);
#ifdef CUTAWAY
	ALBEDO *= 1.0 - 0.45 * cutaway_rim(v_world_pos);
#endif
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	vec3 glow = emission_color.rgb * emission_energy;
	if (ember_glow > 0.0) {
		// Kor: kırmızısı yüksek, yeşili kırmızısına göre düşük pikseller (açık turuncu odun ve gri taş hariç).
		float hot = atw_ramp(tex.g / max(tex.r, 0.001), 0.62, 0.4) * atw_ramp(tex.r, 0.45, 0.8);
		float pulse = 0.75 + 0.25 * sin(tn_time() * 2.3 + tn_noise3(v_world_pos * 6.0) * 6.2831);
		glow += mix(tex, ember_color, 0.5) * hot * ember_glow * pulse;
	}
	EMISSION = glow;
}
