// Fırça darbesi: ana menü butonlarının, bildirimin ve ipucu panelinin yumuşak, boyalı arka planı.
//
// ColorRect'in ortasına, kenarları hafifçe dalgalı ve uçları kuru fırça gibi lif lif dağılan,
// yarı saydam gece mavisi bir mürekkep izi çizer. Dikdörtgenin çevresinde "padding" kadar boşluk
// kalır; "highlight" açıldığında bu boşlukta sıcak altın bir parıltı belirir.
// Tüm uzunluklar arayüz pikseli cinsindendir (1920x1080 tabanı), böylece her çözünürlükte aynı görünür.
// Betik (scripts/ui/menu_brush.gd) rect_size ve padding değerlerini günceller.
shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

// --- Boyut (betik günceller) ---
uniform vec2 rect_size = vec2(270.0, 112.0);
uniform float padding = 28.0;

// --- Görünüm ---
uniform vec4 ink_color : source_color = vec4(0.04, 0.062, 0.15, 0.8);
uniform vec4 warm_ink_color : source_color = vec4(0.27, 0.17, 0.07, 0.86);
uniform vec4 rim_color : source_color = vec4(0.95, 0.9, 0.8, 0.32);
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.46, 0.62);
// Her darbe biraz farklı görünsün diye biçim tohumu.
uniform float seed = 0.0;
// Uçların kuru fırça gibi dağılma miktarı (0 = düzgün, 1 = belirgin).
uniform float fray : hint_range(0.0, 1.0) = 1.0;

// --- Durum (0..1) ---
uniform float highlight : hint_range(0.0, 1.0) = 0.0;
uniform float press : hint_range(0.0, 1.0) = 0.0;
// Giriş animasyonu: darbe soldan sağa doğru boyanır.
uniform float reveal : hint_range(0.0, 1.0) = 1.0;

// Yuvarlatılmış dikdörtgenin işaretli uzaklığı (içeride negatif).
float sd_round_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

// Bir rengi diğerinin üstüne yarı saydam olarak bindirir (ön çarpımsız "over").
vec4 over(vec4 top, vec4 bottom) {
	float a = top.a + bottom.a * (1.0 - top.a);
	vec3 rgb = (top.rgb * top.a + bottom.rgb * bottom.a * (1.0 - top.a)) / max(a, 0.0001);
	return vec4(rgb, a);
}

void fragment() {
	vec2 half_rect = rect_size * 0.5;
	vec2 p = UV * rect_size - half_rect;                      // merkez (0, 0)
	vec2 he = max(half_rect - vec2(padding), vec2(6.0));      // darbenin yarı boyu
	float sx = seed * 17.31 + 3.7;

	// 1) Darbe ekseni elle çekilmiş gibi çok hafif dalgalanır.
	float wobble = (tn_noise2(vec2(p.x * 0.008 + sx, sx * 0.5)) - 0.5) * he.y * 0.16;
	vec2 q = vec2(p.x, p.y - wobble);
	float nx = clamp(q.x / he.x, -1.5, 1.5);

	// 2) Kalınlık: ortada dolgun, uçlara doğru hafifçe incelir.
	float thick = he.y * (0.97 - 0.1 * nx * nx);

	// 3) Fırça kılları: y boyunca ince şeritler. Uçlara yaklaştıkça (end_t) belirginleşir.
	float bristle = tn_noise2(vec2(q.y * 0.42 + sx * 3.0, sx));
	float bristle_fine = tn_noise2(vec2(q.y * 1.15 - sx, sx * 2.0 + 5.0));
	float end_t = smoothstep(0.7, 1.02, abs(nx)) * fray;
	float right = step(0.0, nx);                              // sağ uç (fırçanın kalktığı yer) daha dağınık

	// 4) Biçim: yuvarlak köşeli dikdörtgen + pürüzlü kenar + boyları farklı kıllar.
	//    "soft_d" kılsız, pürüzsüz biçimdir: parıltı ondan hesaplanır ki çizgili görünmesin.
	float soft_d = sd_round_box(q, vec2(he.x, thick), thick * 0.85);
	float d = soft_d + (tn_fbm2(p * 0.05 + vec2(sx, -sx), 3) - 0.5) * 4.5;
	d -= end_t * (bristle - 0.45) * mix(6.0, 15.0, right);

	float aa = max(fwidth(d), 0.0001);
	float body = 1.0 - smoothstep(-aa, aa, d);

	// 5) Uçlarda kuru fırça boşlukları.
	float dry = smoothstep(0.28, 0.62, bristle_fine * 0.6 + bristle * 0.4);
	body *= mix(1.0, dry, end_t * mix(0.5, 0.85, right));

	// 6) Giriş animasyonu: boyanan bölge soldan sağa ilerler; ön cephe de kıl kıl dağınıktır.
	float front = mix(-he.x - 46.0, he.x + 46.0, reveal);
	float painted = 1.0 - smoothstep(front - 30.0, front, q.x + (bristle - 0.5) * 24.0);
	body *= painted;

	// 7) Mürekkep dokusu: boyuna lifler + kenarlarda hafif koyulaşma (suluboya etkisi).
	float fiber = tn_noise2(vec2(p.x * 0.016 + sx, q.y * 0.5));
	float edge = smoothstep(-8.0, 0.0, d);
	vec4 ink = mix(ink_color, warm_ink_color, highlight);
	ink.rgb += vec3(0.07, 0.06, 0.035) * press;
	float ink_a = clamp(ink.a * body * (0.82 + 0.18 * fiber) * (0.9 + 0.2 * edge), 0.0, 1.0);

	// 8) İnce krem kenar çizgisi; uçlarda kaybolur, vurguda altına döner.
	float rim_line = 1.0 - smoothstep(0.0, 1.3, abs(d + 1.4));
	vec3 rim_rgb = mix(rim_color.rgb, glow_color.rgb, highlight);
	float rim_a = rim_line * mix(rim_color.a, 0.7, highlight) * (1.0 - end_t * 0.9) * painted;

	// 9) Dış parıltı: yalnızca vurguda, pürüzsüz biçimin çevresinde yumuşakça söner.
	//    Darbenin içindeki kuru fırça boşluklarında daha sönük görünür.
	float outside = max(soft_d + 2.0, 0.0);
	float sigma = max(padding * 0.42, 1.0);
	float pulse = 0.9 + 0.1 * sin(tn_time() * 2.2 + seed * 4.0);
	float glow_a = glow_color.a * highlight * pulse * exp(-(outside * outside) / (2.0 * sigma * sigma));
	glow_a *= (1.0 - body) * mix(1.0, 0.55, step(soft_d, 0.0));
	glow_a *= 1.0 - smoothstep(front - 30.0, front, q.x);

	vec4 col = vec4(glow_color.rgb, glow_a);
	col = over(vec4(ink.rgb, ink_a), col);
	col = over(vec4(rim_rgb, rim_a), col);
	COLOR = col;
}
