// Çamların ortak malzemesi: Meshy ladinleri ve vadi ormanının prosedürel ladinleri aynı ışık, boya ve renk
// ayarlarıyla çizilir; böylece kampın yanındaki model ağaç ile vadideki ucuz ağaç aynı ağaç gibi görünür
// (bkz. TreeKit, Forest). Her ikisi de köşe rengi kullanır: Meshy ladininin dokusu birleştirilmiş meshin
// köşelerine işlenmiştir (TreeKit.lod_chain), prosedürel ladinin renkleri o dokudan ölçülmüştür. COLOR.rgb
// sRGB renktir (8 bit köşe renginde koyu yeşiller böyle daha hassas kalır); köşe aşamasında doğrusala çevrilir.
//
// - Taç ışığı: 4. referanstaki ladinler gibi koyu, az doygun bir kütle; dal katlarının göğe bakan dış uçları
//   açık ve serin-gri (ay ışığı), içi ve katların altı neredeyse siyahtır. Köşenin ağaç ekseninden uzaklığı,
//   o yükseklikteki taç yarıçapıyla (model_radius tabanda, tepeye doğru daralır) karşılaştırılır; katların altı
//   dünya normalinin aşağı bakmasından bulunur. Ay ışığı kamera tarafından geldiği için (World.light_azimuth)
//   görünen yüzlerin çoğu aydınlık taraftadır: derinliği ışık değil bu boya verir.
// - Boya ayarları atw_textured ile aynı ailedendir (saturation, fırça lekeleri, tabanda koyulaşma, mürekkep
//   kenarı); ışık ortak "After the Wind" cel modelidir (atw_light). Uzak orman için (detail = false) fırça
//   lekeleri ve mürekkep kapatılır: piksel altı gürültü titreşmez, ucuzdur. Fırça lekesi gürültüsü köşe
//   aşamasında hesaplanır (lekeler ~1 m'dir, Meshy ladini sık köşelidir); yakın çamlar ekranın büyük kısmını
//   kapladığından parça başına iş az kalır.
// - Ağaç başına ton farkı (biraz daha açık / koyu, biraz daha serin): ağacın dünyadaki yerinden türetilir
//   (MultiMesh örneği ya da tek MeshInstance3D fark etmez).
// - Rüzgâr: tepeye doğru artan yavaş salınım. Ağacın mesh uzayındaki tabanı ve boyu model_bottom /
//   model_height ile verilir. COLOR.a = 0 olan köşeler (prosedürel ladinin gövdesi) sallanmaz.
// - Arka yüzler çizilmez (cull_back): Meshy ladini kapalı bir meshtir, prosedürel ladinin katları dışa bakar;
//   böylece yaprak kütlesinin içi boşuna gölgelenmez (performans).
// - Çamlar gölge düşürür ama üstlerine gölge almaz (shadows_disabled): koyu dal kütlesinde düşen gölge
//   görünmez, yumuşak gölge süzgeci ise her pikselde pahalıdır (menüde ~1 ms). Karanlık yüz atw_light'tan gelir.
// - Kamera örtmesi: FollowCamera'nın görüş hattında (occlusion_from → occlusion_to) kalan dallar noktalı
//   (dither) biçimde saydamlaşır; occlusion_radius 0 ise kapalıdır.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled, shadows_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

// Köşe renginin doğrusal çarpanı (koyu Meshy dokusunu gece sahnesinde referanstaki ladinler kadar açar).
uniform vec3 albedo_gain = vec3(1.0);
// Referanstaki ladinler az doygundur (koyu yeşil-gri); Meshy dokusunun yeşili mavi ay ışığında camgöbeğine kaçar.
uniform float saturation : hint_range(0.0, 2.0) = 0.65;
// Uzak orman için false: fırça lekeleri ve mürekkep kenarı kapalı.
uniform bool detail = true;

group_uniforms crown;
// Mesh uzayında ağacın ekseni (x, z) ve tabandaki taç yarıçapı.
uniform vec2 model_axis = vec2(0.0);
uniform float model_radius = 2.6;
// Dal uçlarının aydınlanması ve rengi, taç içinin koyuluğu.
uniform float tip_light : hint_range(0.0, 2.0) = 1.2;
uniform vec3 tip_tint = vec3(0.9, 1.0, 1.0);
uniform float inner_shade : hint_range(0.0, 1.0) = 0.22;
// Aşağı bakan yüzlerin (dal katlarının altı) koyuluğu: 1 = koyulaşma yok.
uniform float under_shade : hint_range(0.0, 1.0) = 0.25;
group_uniforms paint;
// Dünya uzayında fırça lekeleri (geniş dal kütlelerinin tekdüzeliğini kırar).
uniform float brush_strength : hint_range(0.0, 0.4) = 0.1;
uniform float brush_scale = 0.9;
// Ağaç başına parlaklık farkı ve serin (mavi-yeşil) ton karışımı.
uniform float variation : hint_range(0.0, 0.5) = 0.14;
uniform vec3 cool_tint = vec3(0.86, 0.96, 1.0);
group_uniforms base_shade;
// Tabandan yukarı doğru azalan koyulaşma (ağacın boyuna oranla) ve şiddeti.
uniform float base_shade_height : hint_range(0.0, 1.0) = 0.12;
uniform float base_shade_strength : hint_range(0.0, 1.0) = 0.3;
group_uniforms ink;
uniform vec4 ink_color : source_color = vec4(0.08, 0.12, 0.1, 1.0);
uniform float ink_strength : hint_range(0.0, 1.0) = 0.18;
uniform float ink_width : hint_range(0.0, 0.6) = 0.14;
group_uniforms wind;
// Mesh uzayında ağacın tabanı ve boyu.
uniform float model_bottom = 0.0;
uniform float model_height = 10.0;
// Tepedeki salınım genliği (ağaç boyuna oran) ve hızı.
uniform float sway_strength : hint_range(0.0, 0.05) = 0.012;
uniform float sway_speed = 0.8;
group_uniforms occlusion;
uniform vec3 occlusion_from = vec3(0.0);
uniform vec3 occlusion_to = vec3(0.0);
uniform float occlusion_radius = 0.0;
// Örtmede en fazla ne kadarının silineceği (dallar hayalet gibi görünmeye devam eder).
uniform float occlusion_strength : hint_range(0.0, 1.0) = 0.85;
group_uniforms;

varying vec3 v_world_pos;
varying float v_variation;
varying float v_height;
varying float v_outer;
// Fırça lekesinin renk çarpanı (köşe aşamasında; detail kapalıyken 1).
varying float v_brush;

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
	COLOR.rgb = srgb_to_linear(COLOR.rgb);
	vec3 root = MODEL_MATRIX[3].xyz;
	float h = clamp((VERTEX.y - model_bottom) / max(model_height, 0.0001), 0.0, 1.2);
	v_height = h;
	// Taç: bu yükseklikte beklenen yarıçapa göre köşenin dışarılığı (0 eksen, 1 dal ucu).
	float crown = model_radius * max(1.0 - h * 0.9, 0.08);
	v_outer = clamp(length(VERTEX.xz - model_axis) / max(crown, 0.0001), 0.0, 1.3);
	float t = tn_time() * sway_speed + dot(root.xz, vec2(0.13, 0.11));
	float k = h * h * model_height * sway_strength * COLOR.a;
	VERTEX.x += sin(t) * k;
	VERTEX.z += cos(t * 0.8) * k * 0.6;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_variation = fract(sin(dot(root.xz, vec2(12.9898, 78.233))) * 43758.5453);
	v_brush = 1.0;
	if (detail) {
		v_brush += (tn_noise3(v_world_pos * brush_scale) - 0.5) * 2.0 * brush_strength;
	}
}

void fragment() {
	// Görüş hattını örten dalları sil (gölge geçişinde değil: orada "kamera" ışıktır).
	if (occlusion_radius > 0.0 && distance(CAMERA_POSITION_WORLD, occlusion_from) < 0.5) {
		vec3 seg = occlusion_to - occlusion_from;
		float t = clamp(dot(v_world_pos - occlusion_from, seg) / max(dot(seg, seg), 0.0001), 0.0, 1.0);
		float d = distance(v_world_pos, occlusion_from + seg * t);
		float fade = (1.0 - smoothstep(occlusion_radius * 0.55, occlusion_radius, d)) * (1.0 - smoothstep(0.85, 0.97, t));
		if (fade * occlusion_strength > bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
	vec3 col = COLOR.rgb * albedo_gain;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(l), col, saturation), vec3(0.0));
	// Dal katlarının altı koyu, göğe bakan üstleri açık (ışık kamera tarafından geldiği için derinliği bu verir).
	float up = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
	col *= mix(under_shade, 1.0, smoothstep(-0.6, 0.4, up));
	// Dal uçları açık ve serin, taç içi koyu.
	float tip = smoothstep(0.45, 1.05, v_outer) * smoothstep(-0.3, 0.5, up);
	col *= mix(inner_shade, 1.0, smoothstep(0.1, 0.7, v_outer));
	col = mix(col, col * tip_tint * (1.0 + tip_light), tip);
	col *= 1.0 + (v_variation - 0.5) * 2.0 * variation;
	col = mix(col, col * cool_tint, 1.0 - v_variation);
	col *= 1.0 - base_shade_strength * (1.0 - smoothstep(0.0, max(base_shade_height, 0.0001), v_height));
	col *= v_brush;
	if (detail) {
		float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float ink = 1.0 - smoothstep(ink_width * 0.5, ink_width, facing);
		col = mix(col, ink_color.rgb, ink * ink_strength);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
