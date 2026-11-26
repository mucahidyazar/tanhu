// Ortak gürültü yardımcıları.
// Birden fazla shader bu dosyayı #include ile kullanır.
// Tüm fonksiyonlar "tn_" önekiyle başlar; böylece isim çakışması olmaz.

// --- Hash fonksiyonları (Dave Hoskins "hash without sine") ---
float tn_hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float tn_hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 tn_hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// --- Değer gürültüsü (value noise) ---
float tn_noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = tn_hash12(i);
	float b = tn_hash12(i + vec2(1.0, 0.0));
	float c = tn_hash12(i + vec2(0.0, 1.0));
	float d = tn_hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float tn_noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = tn_hash13(i);
	float n100 = tn_hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = tn_hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = tn_hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = tn_hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = tn_hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = tn_hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = tn_hash13(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, u.x);
	float x10 = mix(n010, n110, u.x);
	float x01 = mix(n001, n101, u.x);
	float x11 = mix(n011, n111, u.x);
	return mix(mix(x00, x10, u.y), mix(x01, x11, u.y), u.z);
}

// --- Fraktal gürültü (fBm): birkaç oktavın toplamı, 0..1 aralığına yakın ---
float tn_fbm2(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * tn_noise2(p);
		norm += amplitude;
		p = p * 2.03 + vec2(13.7, 7.3);
		amplitude *= 0.5;
	}
	return value / norm;
}

float tn_fbm3(vec3 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		value += amplitude * tn_noise3(p);
		norm += amplitude;
		p = p * 2.03 + vec3(13.7, 7.3, 3.1);
		amplitude *= 0.5;
	}
	return value / norm;
}

// --- Hücresel (Worley) gürültü: en yakın rastgele noktaya uzaklık (F1). ---
// Yuvarlak "kabarcık" desenleri üretir; kümülüs bulutlarının kabarık kenarları için kullanılır.
float tn_worley3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d = 1.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 o = vec3(float(x), float(y), float(z));
				vec3 r = o + tn_hash33(i + o) - f;
				d = min(d, dot(r, r));
			}
		}
	}
	return sqrt(d);
}
