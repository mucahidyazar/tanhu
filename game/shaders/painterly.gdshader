// Boyalı ekran efekti (son işlem): 3B sahneye hafif bir yağlı boya / guaj hissi verir.
//
// 1) Hafif Kuwahara süzgeci (yarıçap 2): her piksel için çevresindeki dört küçük bölgeden (3x3)
//    en "düz" olanların ortalaması alınır. Düz yüzeyler fırça lekelerine dönüşür, kenarlar korunur.
//    Örnek aralığı ekran yüksekliğine göre ölçeklenir (1080p'de 1 piksel, Retina'da ~2 piksel):
//    efekt her çözünürlükte aynı görünür ve piksel başına okuma sayısı sabit kalır.
//    Her bölge, yarım piksel kaydırılmış çift doğrusal (bilinear) okumalarla taranır: 1080p'de bir
//    okuma birden çok pikselin ortalamasını tek seferde verir. Böylece 25 yerine 16 (+1) okuma yeterli.
// 2) Sonuç orijinal görüntüyle "strength" oranında karıştırılır. Çevresinden çok farklı küçük
//    ayrıntılar (yıldızlar, kıvılcımlar, gözler, göz parıltıları) korunur; yüzler okunur kalır.
// 3) Çok hafif kâğıt dokusu, yumuşak kenar kararması (vinyet) ve biraz doygunluk artışı.
//
// Ekranı hint_screen_texture ile okur: bu yüzden 3B sahnenin üstünde, arayüzün ALTINDA
// bir CanvasLayer'da (katman 1) durmalıdır (bkz. scenes/ui/painterly_overlay.tscn).
shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/include/noise.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

// Kuwahara karışım oranı (0 = kapalı, 1 = tam boyalı).
uniform float strength : hint_range(0.0, 1.0) = 0.58;
// Bu yükseklikte (piksel) örnek aralığı 1 pikseldir; daha büyük ekranlarda orantılı açılır.
uniform float reference_height = 1080.0;
// Bölge seçiminin keskinliği: büyüdükçe kenarlar daha net, yüzeyler daha "lekeli".
uniform float sharpness = 300.0;
// Çevresinden belirgin farklı küçük ayrıntıları koruma (0 = koruma yok, 1 = tam).
uniform float detail_protect : hint_range(0.0, 1.0) = 0.8;
// Kâğıt dokusu yoğunluğu.
uniform float grain : hint_range(0.0, 0.2) = 0.026;
// Kenar kararması.
uniform float vignette : hint_range(0.0, 1.0) = 0.3;
uniform vec3 vignette_tint : source_color = vec3(0.56, 0.6, 0.8);
// Doygunluk artışı (0 = yok).
uniform float saturation : hint_range(0.0, 0.5) = 0.06;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Bölge ağırlığı: değişimi (varyansı) küçük olan bölge ağır basar; sert seçim yerine yumuşak geçiş.
float region_weight(vec3 mean, vec3 mean_sq) {
	float variance = dot(abs(mean_sq - mean * mean), vec3(1.0));
	float v = variance * sharpness;
	return 1.0 / (1.0 + v * v);
}

// Bir bölgenin ortalama rengi (rgb) ve ağırlığı (a). dir: bölgenin yönü, ör. (-1, -1) = sol üst.
// Bölge, merkezden 2 adım (yarıçap 2) uzanan 3x3 piksellik karedir. Dört okumayla taranır:
//   a (0.5, 0.5): iç 2x2 blok (4 piksel)    b (2.0, 0.5): dış sütun (2 piksel)
//   c (0.5, 2.0): dış satır (2 piksel)      d (2.0, 2.0): dış köşe (1 piksel)
// Her okuma kapsadığı piksel sayısıyla tartılır: (4a + 2b + 2c + d) / 9 = 3x3 karenin gerçek ortalaması.
// (Eşit tartılsaydı en uzaktaki köşe pikseli merkezdekinin 4 katı ağır basar, görüntü kayar/bulanırdı.)
vec4 region(vec2 uv, vec2 texel, vec2 dir) {
	vec2 step_uv = dir * texel;
	vec3 a = texture(screen_texture, uv + vec2(0.5, 0.5) * step_uv).rgb;
	vec3 b = texture(screen_texture, uv + vec2(2.0, 0.5) * step_uv).rgb;
	vec3 c = texture(screen_texture, uv + vec2(0.5, 2.0) * step_uv).rgb;
	vec3 d = texture(screen_texture, uv + vec2(2.0, 2.0) * step_uv).rgb;
	vec3 mean = (a * 4.0 + b * 2.0 + c * 2.0 + d) / 9.0;
	vec3 mean_sq = (a * a * 4.0 + b * b * 2.0 + c * c * 2.0 + d * d) / 9.0;
	return vec4(mean, region_weight(mean, mean_sq));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float screen_height = 1.0 / SCREEN_PIXEL_SIZE.y;
	float stride = max(1.0, screen_height / reference_height);
	vec2 texel = SCREEN_PIXEL_SIZE * stride;

	vec3 original = texture(screen_texture, uv).rgb;

	// --- 1) Kuwahara: birbirine bitişik dört bölge (sol üst, sağ üst, sol alt, sağ alt) ---
	vec4 r0 = region(uv, texel, vec2(-1.0, -1.0));
	vec4 r1 = region(uv, texel, vec2(1.0, -1.0));
	vec4 r2 = region(uv, texel, vec2(-1.0, 1.0));
	vec4 r3 = region(uv, texel, vec2(1.0, 1.0));
	float total = max(r0.a + r1.a + r2.a + r3.a, 0.0001);
	vec3 painted = (r0.rgb * r0.a + r1.rgb * r1.a + r2.rgb * r2.a + r3.rgb * r3.a) / total;

	// --- 2) Karışım + küçük ayrıntıları koruma ---
	float detail = abs(luma(original) - luma(painted));
	float keep = smoothstep(0.07, 0.24, detail) * detail_protect;
	vec3 col = mix(original, painted, strength * (1.0 - keep));

	// --- 3a) Kâğıt dokusu: ince tane + daha iri lif (1080p ölçeğinde, ekrana sabit) ---
	//     Çok parlak yerlerde (ay, ateş) zayıflar; yoksa orada kumlanma gibi görünür.
	vec2 paper = FRAGCOORD.xy / stride;
	float fine = tn_noise2(paper * 0.45);
	float fibre = tn_noise2(paper * vec2(0.07, 0.13) + vec2(17.0, 3.0));
	float g = fine * 0.45 + fibre * 0.55 - 0.5;
	float bright = smoothstep(0.55, 0.95, luma(col));
	col *= 1.0 + g * grain * 2.0 * (1.0 - 0.75 * bright);

	// --- 3b) Yumuşak vinyet (köşelerde hafif mavi kararma) ---
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centered = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	float r = length(centered) / length(vec2(0.5 * aspect, 0.5));
	float vig = smoothstep(0.42, 1.05, r) * vignette;
	col = mix(col, col * vignette_tint, vig);

	// --- 3c) Hafif doygunluk artışı ---
	float l = luma(col);
	col = mix(vec3(l), col, 1.0 + saturation);

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
