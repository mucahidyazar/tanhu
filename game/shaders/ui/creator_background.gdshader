// Karakter oluşturucu arka planı.
//
// Eski bir duvar resmi gibi boyanmış, adaçayı yeşili bir zemin: üzerinde turkuaz kuru fırça darbeleri
// ve büyük, soluk Türk motifleri (koçboynuzu sarmalları, meander / kıvrımlı anahtar bantları,
// eş merkezli yaylar). Motifler çizgi değil, geniş boya şeritleridir; turkuaz, zeytin ve aşı boyası
// (toprak sarısı) tonlarında, kenarları kuru fırçayla aşınmış gibidir.
//
// Katmanlar (alttan üste):
//   1) Büyük ölçekli renk lekeleri (adaçayı yeşili, açık yeşil, köşelerde zeytin).
//   2) Çapraz kuru fırça darbeleri: yeşil zemin üzerine turkuaz boya.
//   3) Motifler.
//   4) Benekler, kâğıt / sıva tanesi, karakterin arkasında yumuşak aydınlık ve vinyet.
// Ekranda CreatorBakedRect ile bir kez dokuya pişirilir (her karede yeniden hesaplanmaz); drift_speed
// yalnızca shader canlı bir ColorRect'te kullanılırsa desenleri çok yavaş kaydırır.
//
// Koordinatlar: p, yüksekliğe göre ölçeklenmiş merkez koordinatıdır (y aşağı doğru artar):
// y -0.5 (üst) .. 0.5 (alt), x -en_boy/2 .. en_boy/2. Böylece motifler her ekran oranında yuvarlak kalır.
shader_type canvas_item;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

// Düğümün piksel boyutu (CreatorShaderRect her yeniden boyutlandırmada günceller).
uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform vec4 base_color : source_color = vec4(0.4, 0.55, 0.39, 1.0);
uniform vec4 base_light : source_color = vec4(0.5, 0.62, 0.43, 1.0);
uniform vec4 teal_color : source_color = vec4(0.2, 0.5, 0.46, 1.0);
uniform vec4 deep_color : source_color = vec4(0.14, 0.36, 0.32, 1.0);
uniform vec4 olive_color : source_color = vec4(0.6, 0.6, 0.38, 1.0);
uniform vec4 ochre_color : source_color = vec4(0.55, 0.42, 0.27, 1.0);
// Turkuaz fırça darbelerinin miktarı.
uniform float stroke_amount : hint_range(0.0, 1.0) = 0.55;
// Motiflerin genel görünürlüğü (0 = yok, 1 = tam boya).
uniform float ornament_strength : hint_range(0.0, 1.0) = 0.68;
// Gürültünün kayma hızı (çok küçük tutulmalı; yalnızca "nefes alan" bir zemin için).
uniform float drift_speed = 0.004;
// Karakterin arkasındaki yumuşak aydınlık: merkez (UV) ve güç.
uniform vec2 focus_center = vec2(0.3, 0.5);
uniform float focus_strength : hint_range(0.0, 1.0) = 0.14;
uniform float vignette : hint_range(0.0, 1.0) = 0.42;

mat2 rot2(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Arşimet sarmalı (merkezden dışa doğru "turns" tur, turlar arası "spacing").
// Dönüş: x = sarmal çizgisine uzaklık, y = çizgi boyunca konum (0 = merkez, 1 = dış uç; >1 = uç ötesi).
vec2 spiral(vec2 p, float spacing, float turns) {
	float r = length(p);
	float t = fract(atan(p.y, p.x) / TAU);
	float k = clamp(floor(r / spacing - t + 0.5), 0.0, ceil(turns) - 1.0);
	float s = k + t;
	return vec2(abs(r - spacing * s), s / turns);
}

// Kuru fırçayla boyanmış geniş şerit: d şeridin orta çizgisine uzaklık, width yarı kalınlık.
// Kenarlar tırtıklı, içinde fırça kılı izleri ve küçük boşluklar vardır. Dönüş 0..1.
float paint_band(float d, float width, vec2 p) {
	// Şeritten uzak piksellerde gürültü hiç hesaplanmaz (pişirme hızı için).
	if (d > width * 1.4) {
		return 0.0;
	}
	float edge_noise = tn_fbm2(p * 20.0, 3) - 0.5;
	float body = 1.0 - smoothstep(width * 0.78, width, d + edge_noise * width * 0.55);
	float bristles = tn_noise2(p * vec2(160.0, 45.0));
	float patches = tn_fbm2(p * 7.0 + vec2(4.0), 3);
	float dry = smoothstep(0.18, 0.62, bristles * 0.45 + patches * 0.7);
	return body * mix(0.45, 1.0, dry);
}

// Koçboynuzu motifi: ortada dikey bir sap, tepede iki yana açılıp içe kıvrılan iki sarmal.
// size motifin yarı genişliğidir.
float ram_horn(vec2 p, float size, float angle) {
	if (length(p) > size * 1.45) {
		return 0.0;
	}
	vec2 q = rot2(-angle) * p / size;
	vec2 m = vec2(abs(q.x), q.y);
	// Sağ boynuz (sol boynuz aynadan gelir): dış ucu sapın tepesine bağlanacak şekilde döndürülmüş sarmal.
	vec2 local = rot2(-2.1) * (m - vec2(0.52, -0.05));
	local.y = -local.y;
	vec2 sp = spiral(local, 0.24, 2.1);
	float taper = smoothstep(1.03, 0.9, sp.y);
	float horn = sp.x - 0.075 * mix(0.6, 1.0, sp.y) * taper;
	// İç uçta yuvarlak kıvrım (boynuzun ucu).
	float curl = length(local) - 0.09;
	// Sap ve alttaki küçük kollar.
	float stem = sd_segment(m, vec2(0.0, -0.4), vec2(0.0, 0.78)) - 0.075;
	float foot = sd_segment(m, vec2(0.0, 0.78), vec2(0.26, 0.96)) - 0.06;
	float d = min(min(horn, curl), min(stem, foot)) * size;
	return paint_band(max(d, 0.0), 0.016, p);
}

// Meander (kıvrımlı anahtar / "su yolu") bandı. q.x bant boyunca hücre birimiyle, q.y 0..1 bant içi.
float meander_dist(vec2 q) {
	float cx = floor(q.x);
	vec2 f = vec2(q.x - cx, q.y);
	float d = 1e3;
	for (int i = 0; i < 2; i++) {
		vec2 g = f - vec2(float(i), 0.0);
		d = min(d, sd_segment(g, vec2(0.0, 0.0), vec2(1.0, 0.0)));
		d = min(d, sd_segment(g, vec2(0.0, 0.0), vec2(0.0, 1.0)));
		d = min(d, sd_segment(g, vec2(0.0, 1.0), vec2(0.8, 1.0)));
		d = min(d, sd_segment(g, vec2(0.8, 1.0), vec2(0.8, 0.2)));
		d = min(d, sd_segment(g, vec2(0.8, 0.2), vec2(0.2, 0.2)));
		d = min(d, sd_segment(g, vec2(0.2, 0.2), vec2(0.2, 0.8)));
		d = min(d, sd_segment(g, vec2(0.2, 0.8), vec2(0.6, 0.8)));
		d = min(d, sd_segment(g, vec2(0.6, 0.8), vec2(0.6, 0.4)));
		d = min(d, sd_segment(g, vec2(0.6, 0.4), vec2(0.4, 0.4)));
	}
	return d;
}

// Bir meander bandı: origin bandın başlangıcı, angle yönü, cell hücre boyu, len bant uzunluğu.
float meander_band(vec2 p, vec2 origin, float angle, float cell, float len) {
	vec2 local = rot2(-angle) * (p - origin);
	vec2 q = local / cell;
	float along = smoothstep(-0.2, 0.6, q.x) * smoothstep(len / cell + 0.2, len / cell - 0.6, q.x);
	if (along <= 0.0 || q.y < -0.3 || q.y > 1.3) {
		return 0.0;
	}
	float d = meander_dist(q) * cell;
	return paint_band(d, cell * 0.068, p) * along;
}

// Eş merkezli geniş yaylar: center merkez, r0..r1 yarıçap aralığı, a0..a1 açı aralığı (radyan).
float arcs(vec2 p, vec2 center, float spacing, float r0, float r1, float a0, float a1) {
	vec2 d = p - center;
	float r = length(d);
	if (r < r0 - 0.04 || r > r1 + 0.04) {
		return 0.0;
	}
	float a = atan(d.y, d.x);
	float in_angle = smoothstep(a0, a0 + 0.3, a) * smoothstep(a1, a1 - 0.3, a);
	float in_radius = smoothstep(r0 - 0.03, r0 + 0.03, r) * smoothstep(r1 + 0.03, r1 - 0.03, r);
	float band = abs(fract(r / spacing) - 0.5) * spacing;
	return paint_band(band, spacing * 0.27, p) * in_angle * in_radius;
}

void fragment() {
	float aspect = rect_size.x / max(rect_size.y, 1.0);
	float half_w = aspect * 0.5;
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	vec2 px = UV * rect_size;
	float t = tn_time() * drift_speed;

	// 1) Büyük renk lekeleri (alan bükmeli fBm: suluboya akışı gibi).
	vec2 warp = vec2(tn_fbm2(p * 2.0 + vec2(t, 0.0), 3), tn_fbm2(p * 2.0 + vec2(5.2, 1.3 - t), 3)) - 0.5;
	vec2 pw = p + warp * 0.12;
	float big = tn_fbm2(pw * 1.6 + vec2(3.0, t * 0.5), 4);
	float mid = tn_fbm2(pw * 4.0 + vec2(11.0, -t), 3);
	vec3 col = mix(base_color.rgb, base_light.rgb, smoothstep(0.35, 0.7, big));
	col = mix(col, base_light.rgb * 1.05, smoothstep(0.62, 0.85, mid) * 0.35);
	// Sol üst köşe zeytine, sol alt aşı boyasına çalar.
	float olive_zone = 1.0 - smoothstep(0.0, 0.7, length(p - vec2(-half_w * 0.9, -0.42)));
	col = mix(col, olive_color.rgb * 0.92, smoothstep(0.35, 0.7, mid) * olive_zone * 0.5);

	// 2) Kuru fırça darbeleri: çapraz uzanan, kenarları tırtıklı turkuaz boya şeritleri.
	float flow = -0.62 + (tn_noise2(p * 1.1 + vec2(7.0, 3.0)) - 0.5) * 0.9;
	vec2 sp = rot2(flow) * pw;
	float strokes = tn_fbm2(vec2(sp.x * 2.6, sp.y * 6.5) + vec2(2.0, t), 4);
	float bristle = tn_noise2(vec2(sp.x * 5.0, sp.y * 150.0));
	float bristle_fine = tn_noise2(vec2(sp.x * 11.0, sp.y * 320.0) + vec2(9.0));
	// Darbeler kesintisiz şeritler değil, yer yer kopan lekeler olsun.
	float breakup = smoothstep(0.3, 0.56, tn_fbm2(pw * 2.4 + vec2(8.0, -t), 3));
	float stroke_mask = smoothstep(0.49, 0.61, strokes + (bristle - 0.5) * 0.16) * breakup;
	col = mix(col, teal_color.rgb, stroke_mask * stroke_amount * mix(0.65, 1.0, bristle));
	col = mix(col, deep_color.rgb, smoothstep(0.66, 0.76, strokes) * breakup * stroke_amount * 0.45);
	col *= 1.0 + (bristle_fine - 0.5) * 0.07;

	// 3) Motifler. Her biri kendi renginde; üst üste gelirlerse sonraki baskın olur.
	float o = ornament_strength;
	// Sol: zeytin koçboynuzu (üst), turkuaz yaylar (orta), aşı boyası meander (alt).
	col = mix(col, olive_color.rgb, ram_horn(p - vec2(-half_w + 0.24, -0.12), 0.3, 0.32) * o * 0.8);
	col = mix(col, deep_color.rgb, arcs(p, vec2(-half_w - 0.12, 0.42), 0.12, 0.2, 0.72, -1.4, 0.2) * o * 0.85);
	col = mix(col, ochre_color.rgb, meander_band(p, vec2(-half_w - 0.08, 0.3), 0.0, 0.2, half_w * 0.5) * o);
	// Karakterin arkası: çok soluk, büyük yaylar.
	col = mix(col, base_light.rgb * 1.08, arcs(p, vec2(-0.26, 0.05), 0.16, 0.25, 0.62, -3.14, 3.14) * o * 0.22);
	// Sağ: üstte ve sağ kenarda turkuaz meander, sağ altta zeytin koçboynuzu.
	col = mix(col, deep_color.rgb, meander_band(p, vec2(0.08, -0.53), 0.0, 0.17, half_w) * o * 0.55);
	col = mix(col, teal_color.rgb * 0.85, meander_band(p, vec2(half_w + 0.03, -0.5), 1.5708, 0.15, 1.1) * o * 0.7);
	col = mix(col, olive_color.rgb, ram_horn(p - vec2(0.3, 0.44), 0.26, -0.2) * o * 0.7);

	// 4) Karakterin arkasında yumuşak aydınlık.
	vec2 fc = (UV - focus_center) * vec2(aspect, 1.0);
	float focus = 1.0 - smoothstep(0.0, 0.6, length(fc * vec2(1.0, 0.75)));
	col = mix(col, col * 1.16 + vec3(0.025, 0.03, 0.015), focus * focus_strength * 2.0);

	// Benekler ve sıva / kâğıt tanesi.
	float speck = tn_noise2(px * 0.33 + vec2(31.0));
	col *= 1.0 - smoothstep(0.82, 0.92, speck) * 0.12;
	col = mix(col, col * 1.12 + vec3(0.02), smoothstep(0.86, 0.95, tn_noise2(px * 0.41 + vec2(7.0))) * 0.5);
	float grain = tn_noise2(px * 0.95) - 0.5;
	float grain_big = tn_noise2(px * 0.12 + vec2(17.0)) - 0.5;
	col *= 1.0 + grain * 0.06 + grain_big * 0.05;

	// Vinyet: kenarlar ve köşeler hafifçe kararır.
	vec2 vc = (UV - 0.5) * vec2(1.15, 1.0);
	col *= mix(1.0, 0.72, smoothstep(0.35, 0.95, length(vc)) * vignette * 2.0);

	COLOR = vec4(col, 1.0);
}
