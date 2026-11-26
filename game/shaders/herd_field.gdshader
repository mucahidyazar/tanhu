// Sürü (scripts/crowd/herd_field.gd; fauna.md §10, godot.md §4.5): tek ağlı MultiMesh; yürüyüş ve otlama köşede.
//
// Örnek verisi (INSTANCE_CUSTOM; HerdField yazar):
//   r  yürüyüş evresi (0..1)    g  salınım genliği (0 duruyor, 1 ≈ bacak boyunun tamamı kadar öne)
//   b  otlama (0 baş yukarıda, 1 burun yerde)    a  örneğin tohumu (0..1: ton, boynuz, kuyruk, kulak)
// Parça bilgisi (CUSTOM0; FaunaMesh yazar): x bacak (1 sol arka, 2 sol ön, 3 sağ arka, 4 sağ ön), y salınım ağırlığı,
// z baş ağırlığı, w kuyruk ağırlığı; w = −1 boynuz (yalnız ram_share'in içindeki tohumlarda görünür).
//
// Yürüyüş sırası (fauna.md §10): sol arka 0, sol ön 0,25, sağ arka 0,5, sağ ön 0,75; tırısta çapraz çift: sol arka ile
// sağ ön 0, sağ arka ile sol ön 0,5. Ayak yere bakarken salınımın hızı gövdeninkiyle aynıdır (HerdField genliği hızdan seçer).
// Işık çizgisi soft_toon'un dilindedir. Zaman tn_time() ile okunur: kararlı karede donar (godot.md §8.5).
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

group_uniforms body;
uniform float hip_height = 0.4;
uniform vec3 neck_pivot = vec3(0.0, 0.55, 0.25);
uniform vec3 tail_pivot = vec3(0.0, 0.58, -0.44);
// Otlamada başın en büyük dönüşü (radyan).
uniform float graze_angle = 1.58;
// Bu tohumun altındakiler koçtur: boynuz görünür.
uniform float ram_share : hint_range(0.0, 1.0) = 0.16;
group_uniforms color;
// Boya köşe rengindedir: kodla çizilen koyunda elle, Meshy ağında dokudan okunmuş (FaunaMesh.from_model). Yünün rengi tohumla kayar; en koyu tohumlar (dark_share) esmer koyundur.
uniform vec3 wool_warm : source_color = vec3(1.0, 0.97, 0.9);
uniform vec3 wool_cool : source_color = vec3(0.95, 0.95, 0.94);
uniform vec3 wool_dark : source_color = vec3(0.42, 0.37, 0.35);
uniform float dark_share : hint_range(0.0, 1.0) = 0.05;
// 1: koyu tohumda bütün don koyulaşır (at sürüsünün yağızları; Kışlak, kinds.json herd.tints.dark_all); 0: yalnız yün (koyun).
uniform float dark_all : hint_range(0.0, 1.0) = 0.0;
// Yüz ve incik boyaları (tohumla seçilir): çoğu koyu yüzlü (Moğol koyunu), kimi sarımsı, azı açık.
uniform vec3 face_dark : source_color = vec3(0.24, 0.16, 0.11);
uniform vec3 face_tan : source_color = vec3(0.42, 0.29, 0.18);
uniform vec3 face_pale : source_color = vec3(0.72, 0.62, 0.48);
// Yünün kıvırcık benekleri (yerel uzayda; gövdeyle birlikte gider).
uniform float curl_scale = 26.0;
uniform float curl_strength : hint_range(0.0, 0.6) = 0.14;
group_uniforms;

varying vec3 v_local;
varying vec3 v_tint;
varying vec3 v_face;
varying float v_dark;

// Bacağın evre gecikmesi: yürüyüşte dört vuruş, tırısta çapraz çift.
float leg_offset(float leg, float trot) {
	float walk = leg < 1.5 ? 0.0 : (leg < 2.5 ? 0.25 : (leg < 3.5 ? 0.5 : 0.75));
	float pair = leg < 1.5 ? 0.0 : (leg < 2.5 ? 0.5 : (leg < 3.5 ? 0.5 : 0.0));
	return mix(walk, pair, trot);
}

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float amp = INSTANCE_CUSTOM.g;
	float graze = INSTANCE_CUSTOM.b;
	float seed = INSTANCE_CUSTOM.a;
	float t = tn_time() + seed * 41.0;
	vec3 v = VERTEX;
	v_local = v;

	// Bacak: kalçadan salınır; öne giderken ayak yerden kalkar.
	if (CUSTOM0.x > 0.5) {
		float trot = smoothstep(0.68, 0.73, amp);
		float angle = TAU * (phase + leg_offset(CUSTOM0.x, trot));
		float drop = max(hip_height - v.y, 0.0);
		float weight = CUSTOM0.y;
		v.z += amp * sin(angle) * drop * weight;
		v.y += max(cos(angle), 0.0) * amp * 0.14 * drop * weight;
	}

	// Baş: boyun dibinden öne ve aşağı döner; otlarken hafifçe çiğner, yürürken adımla sallanır.
	float head_w = CUSTOM0.z;
	if (head_w > 0.0) {
		float chew = graze * sin(t * 5.5) * 0.035;
		float nod = amp * sin(TAU * phase * 2.0) * 0.05;
		float look = (1.0 - graze) * (1.0 - min(amp * 2.5, 1.0)) * sin(t * 0.37 + seed * 9.0) * 0.32;
		float a = (graze * graze_angle + chew + nod) * head_w;
		vec3 q = v - neck_pivot;
		float ca = cos(a);
		float sa = sin(a);
		q = vec3(q.x, q.y * ca - q.z * sa, q.y * sa + q.z * ca);
		float cy = cos(look * head_w);
		float sy = sin(look * head_w);
		q = vec3(q.x * cy + q.z * sy, q.y, -q.x * sy + q.z * cy);
		v = mix(v, q + neck_pivot, step(0.001, head_w));
	}

	// Boynuz: yalnız koçta; öteki koyunlarda başın içine çekilir.
	if (CUSTOM0.w < -0.5 && seed > ram_share) {
		v = neck_pivot + vec3(0.0, 0.15, 0.2);
	}

	// Kuyruk: yanlara kısa kısa sallanır.
	if (CUSTOM0.w > 0.0) {
		float swish = sin(t * (2.2 + seed * 1.3)) * (0.04 + amp * 0.1) * sin(t * 0.41 + seed * 6.0);
		v.x += swish * CUSTOM0.w * clamp((tail_pivot.y - v.y) * 3.0, 0.2, 1.0);
	}

	// Otlarken ön taraf hafifçe iner; gövde adımla iner kalkar, soluk alır.
	float body_w = 1.0 - clamp(CUSTOM0.y, 0.0, 1.0);
	v.y -= graze * 0.05 * smoothstep(-0.05, 0.3, VERTEX.z) * body_w;
	float breath = sin(t * 1.3) * 0.004;
	v.y += (amp * sin(TAU * phase * 2.0) * 0.022 + breath) * body_w;
	v.x += amp * sin(TAU * phase) * 0.012 * body_w;

	VERTEX = v;

	// Örneğin tonu (parçaya taşınır).
	v_dark = step(1.0 - dark_share, seed);
	vec3 tone = mix(wool_cool, wool_warm, fract(seed * 7.13));
	v_tint = tone * (0.92 + fract(seed * 13.7) * 0.1);
	float pick = fract(seed * 23.71);
	v_face = pick < 0.68 ? face_dark : (pick < 0.92 ? face_tan : face_pale);
}

void fragment() {
	vec3 col;
	float paint = COLOR.a;
	if (paint > 0.75) {
		// Yün: kıvırcık benek (hücre gürültüsü) ve geniş leke.
		float cell = tn_worley3(v_local * curl_scale);
		float blot = tn_noise3(v_local * 4.0);
		// Esmer koyunda yalnız yün koyulaşır: boyanın açık yeri (yün, doğrusal parlaklık ≥0,4) esmere döner; Meshy ağının yüzü ve inciği
		// (koyu doku, ≈0,1–0,2) kendi rengini korur, koyun boğaya benzemesin.
		float lum = dot(COLOR.rgb, vec3(0.2126, 0.7152, 0.0722));
		vec3 tint = mix(v_tint, wool_dark, v_dark * mix(smoothstep(0.2, 0.4, lum), 1.0, dark_all));
		col = COLOR.rgb * tint * (1.0 + (0.5 - smoothstep(0.2, 0.62, cell)) * curl_strength * 2.0) * (0.92 + blot * 0.16);
	} else if (paint > 0.25) {
		col = COLOR.rgb * v_face;
	} else {
		col = COLOR.rgb;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
