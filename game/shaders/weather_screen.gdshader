// Ekran yağışı (weather.md §9.3, H9): yağmur, kar, dolu ve toz çizgisi boyalı süzgeçten (PainterlyOverlay, katman 1) sonra, son
// geçişte çizilir; Kuwahara boyası bir iki piksellik çizgiyi siler, burada çizgi keskin kalır. Üç katman (yakın, orta, uzak); her katman
// düşüş yönüne dönmüş ızgarada hücre başına en çok bir damla. Karışımın son çarpanı layer_alpha'dır (0,5; W16 karelerinde çizgi boyalı
// süzgeçte zayıf okunursa 0,65, başka değer denenmez: K58; 2026-11-08'de 0,65 seçildi, WeatherView.LAYER_ALPHA). Kadraj dışına inen
// yıldırımın ayağı aynı geçişte çizilir (bolt_edge).
// Ekran okumaz: rengi alfa karışımıyla (önceden çarpılmış) yazar, 0 çizim ve 0 program ekler; yağış yokken düğüm gizlidir (menü kimliği).
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

// x yağmur, y kar, z dolu, w toz: 0..1.
uniform vec4 precip = vec4(0.0);
// xy ekranda düşüş yönü (birim, UV'de y aşağı), z kar salınımı, w çizgi boyu.
uniform vec4 precip_dir = vec4(0.0, 1.0, 0.0, 1.0);
// Katman kayması: düşüş × zaman + kamera paralaksı (CPU biriktirir ve 256 hücrede sarar), z katman tohumu.
uniform vec3 precip_off0 = vec3(0.0);
uniform vec3 precip_off1 = vec3(0.0, 0.0, 17.0);
uniform vec3 precip_off2 = vec3(0.0, 0.0, 31.0);
// Işık düzeninden: göğün rengi × pozlama payı.
uniform vec3 precip_col : source_color = vec3(0.75, 0.8, 0.86);
uniform float layer_alpha = 0.65;
// Tipide kar yatar: tane düşüş yönünde uzar (0 yuvarlak, 1 çizgi).
uniform float snow_streak = 0.0;
uniform float aspect = 1.7778;
// Kesme sırası (godot.md §7.5 madde 7): 3 ya da 2 katman.
uniform int layers = 3;
// Kadraj dışı yıldırımın ayağı: x kenar boyunca yer (0..1), y genişlik, z güç (0..1), w kenar (0 üst, 1 sağ, 2 alt, 3 sol).
uniform vec4 bolt_edge = vec4(0.0);
uniform vec3 bolt_color : source_color = vec3(0.86, 0.9, 1.0);
// Kadrajın içine inen yıldırımın göğe uzanan gövdesi (K98'in yüksek kadrajında gök görünmez: 3B şeridin yalnız dibi kadrajdadır).
// xy üst kenardaki giriş, zw inişin ekrandaki yeri (UV, y aşağı); bolt_seg_power güç (0: yok); bolt_seg_seed kırıkların tohumu.
uniform vec4 bolt_seg = vec4(0.0);
uniform float bolt_seg_power = 0.0;
uniform float bolt_seg_seed = 0.0;

const float P = 256.0;

float p_hash(vec2 p) {
	vec3 q = fract(p.xyx * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float p_layer(vec2 uv, float scale, vec3 off) {
	vec2 d = precip_dir.xy;
	vec2 n = vec2(-d.y, d.x);
	vec2 q = vec2(dot(uv, n), dot(uv, d)) * scale + off.xy;
	vec2 cell = floor(q);
	vec2 f = fract(q) - 0.5;
	float h = p_hash(mod(cell, P) + off.z);
	float dens = precip.x * 0.55 + precip.y * 0.7 + precip.z * 0.35 + precip.w * 0.6;
	if (h < 1.0 - dens) {
		return 0.0;
	}
	f -= (vec2(p_hash(mod(cell, P) + 7.1), p_hash(mod(cell, P) + 3.7)) - 0.5) * vec2(0.6, 0.2);
	// Kar salınımı.
	f.x += sin(off.y * 0.7 + h * 40.0) * precip_dir.z;
	float rain = (1.0 - smoothstep(0.018, 0.035, abs(f.x))) * (1.0 - smoothstep(0.27 * precip_dir.w, 0.45 * precip_dir.w, abs(f.y)));
	float snow = 1.0 - smoothstep(0.06, 0.12, length(f * vec2(1.0, mix(1.0, 0.22, snow_streak))));
	float hail = 1.0 - smoothstep(0.03, 0.07, length(f * vec2(1.0, 0.45)));
	return rain * (precip.x + precip.w * 0.6) + snow * precip.y + hail * precip.z * 1.4;
}

float bolt_leg(vec2 uv) {
	if (bolt_edge.z <= 0.0) {
		return 0.0;
	}
	// Kenara dik eksen (0 kenarda, artı içeri) ve kenar boyunca konum.
	float along;
	float inward;
	int e = int(bolt_edge.w + 0.5);
	if (e == 0) {
		along = uv.x;
		inward = uv.y;
	} else if (e == 1) {
		along = uv.y;
		inward = 1.0 - uv.x;
	} else if (e == 2) {
		along = uv.x;
		inward = 1.0 - uv.y;
	} else {
		along = uv.y;
		inward = uv.x;
	}
	float w = max(bolt_edge.y, 0.002);
	// Kırık bir ayak: kenardan içeri kısa zikzak.
	float zig = (p_hash(vec2(floor(inward * 40.0), 3.0)) - 0.5) * w * 2.0;
	float leg = (1.0 - smoothstep(w * 0.25, w, abs(along - bolt_edge.x - zig))) * (1.0 - smoothstep(0.0, 0.16, inward));
	float glow = exp(-abs(along - bolt_edge.x) * 9.0) * (1.0 - smoothstep(0.0, 0.3, inward)) * 0.35;
	return (leg + glow) * bolt_edge.z;
}

// Kırık gövde: girişten inişe orta nokta kaydırmalı çizgi (hash gürültüsü), çekirdek ve parıltı.
float bolt_body(vec2 uv) {
	if (bolt_seg_power <= 0.0) {
		return 0.0;
	}
	vec2 a = bolt_seg.xy * vec2(aspect, 1.0);
	vec2 b = bolt_seg.zw * vec2(aspect, 1.0);
	vec2 p = uv * vec2(aspect, 1.0);
	vec2 ab = b - a;
	float len = max(length(ab), 1e-4);
	vec2 t = ab / len;
	vec2 n = vec2(-t.y, t.x);
	float s = clamp(dot(p - a, t) / len, 0.0, 1.0);
	// Üç ölçekli kırık: her ölçekte parça uçlarında rastgele yana kayma, arada doğrusal.
	float off = 0.0;
	float amp = 0.05;
	for (int k = 0; k < 3; k++) {
		float cells = 4.0 * pow(3.0, float(k));
		float c = floor(s * cells);
		float f = fract(s * cells);
		float o0 = p_hash(vec2(c, bolt_seg_seed + float(k) * 7.0)) - 0.5;
		float o1 = p_hash(vec2(c + 1.0, bolt_seg_seed + float(k) * 7.0)) - 0.5;
		off += mix(o0, o1, f) * amp;
		amp *= 0.4;
	}
	off *= sin(s * PI);
	float d = abs(dot(p - a, n) - off);
	float core = 1.0 - smoothstep(0.0012, 0.0032, d);
	float glow = exp(-d * 90.0) * 0.45;
	float along = step(0.0, dot(p - a, t)) * step(dot(p - a, t), len);
	return (core + glow) * along * bolt_seg_power;
}

void fragment() {
	vec2 uv = UV;
	vec4 outc = vec4(0.0);
	if (precip.x + precip.y + precip.z + precip.w > 0.0) {
		vec2 suv = uv * vec2(aspect, 1.0);
		float a = p_layer(suv, 34.0, precip_off0) * 0.55 + p_layer(suv, 22.0, precip_off1) * 0.75;
		if (layers >= 3) {
			a += p_layer(suv, 13.0, precip_off2);
		}
		a = clamp(a, 0.0, 1.0) * layer_alpha;
		outc = vec4(precip_col * a, a);
	}
	float b = bolt_leg(uv) + bolt_body(uv);
	outc.rgb += bolt_color * b;
	COLOR = outc;
}
