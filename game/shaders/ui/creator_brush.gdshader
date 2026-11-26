// Kuru fırça darbesi: başlık bandı ve "Geri Al" / "Onayla" düğmeleri için.
//
// UV.x fırçanın gidiş yönüdür (soldan sağa), UV.y enine. Sol uçta boyanın biriktiği yuvarlak bir baş,
// sağ uçta kıllara ayrılarak incelen kuru bir kuyruk vardır. Gövdede kıl izleri ve küçük boşluklar olur.
shader_type canvas_item;

#include "res://shaders/include/noise.gdshaderinc"

uniform vec4 stroke_color : source_color = vec4(0.16, 0.13, 0.12, 1.0);
// Düğümün piksel boyutu (CreatorShaderRect / CreatorBrushButton günceller).
uniform vec2 rect_size = vec2(400.0, 80.0);
// Farklı düğmeler farklı fırça izi taşısın diye desen tohumu.
uniform float seed = 1.0;
// Gövde kalınlığı (düğüm yüksekliğine oranla).
uniform float thickness : hint_range(0.1, 1.0) = 0.7;
// Sol baş: 0 = yuvarlak boya birikimi, 1 = ekran dışından geliyormuş gibi kesik (başlık bandı).
uniform float open_start : hint_range(0.0, 1.0) = 0.0;
// Sağdaki kuru kuyruğun uzunluğu (genişliğe oranla).
uniform float tail : hint_range(0.0, 0.8) = 0.3;
// Kıl izlerinin belirginliği.
uniform float bristle : hint_range(0.0, 1.0) = 0.6;
// Üzerine gelince hafif aydınlanma (0..1, betik canlandırır).
uniform float hover : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 px = UV * rect_size;
	float u = UV.x;
	float v = UV.y * 2.0 - 1.0;

	// Fırçanın orta çizgisi hafifçe dalgalanır; uçlara doğru hafif yukarı kalkar.
	float center = (tn_noise2(vec2(u * 2.3 + seed, seed * 1.7)) - 0.5) * 0.16 - smoothstep(0.75, 1.0, u) * 0.06;

	// Kalınlık profili: yarım daire biçiminde yuvarlak baş + incelen kuyruk + gövdede hafif şişkinlik.
	float head_len = max(rect_size.y * thickness * 0.5 / max(rect_size.x, 1.0), 0.001);
	float h = clamp(u / head_len, 0.0, 1.0);
	float head = mix(sqrt(max(h * (2.0 - h), 0.0)), 1.0, open_start);
	float tail_t = smoothstep(1.0 - tail, 1.0, u);
	float profile = head * (1.0 - tail_t * 0.72);
	float half_t = thickness * profile * (0.94 + 0.06 * sin(u * 3.4 + seed));

	// Kenarlar: üst ve alt kenar farklı tırtıklı.
	float side = step(0.0, v - center);
	float rag = (tn_noise2(vec2(px.x * 0.08, side * 7.0 + seed)) - 0.5) * 0.13
		+ (tn_noise2(vec2(px.x * 0.37, side * 13.0 + seed)) - 0.5) * 0.06;
	float dist_px = (abs(v - center) - (half_t + rag)) * rect_size.y * 0.5;
	float alpha = clamp(0.5 - dist_px, 0.0, 1.0);

	// Kıl izleri: enine sık, boyuna seyrek gürültü. Kuyrukta kıllar birbirinden ayrılır.
	float streak = tn_noise2(vec2(u * 3.0 + seed * 3.1, v * 24.0));
	float streak_fine = tn_noise2(vec2(u * 7.0 + seed, v * 68.0));
	float dry = tail_t * 0.88 + (1.0 - head) * 0.3;
	alpha *= smoothstep(dry - 0.08, dry + 0.08, streak * 0.72 + streak_fine * 0.38);

	// Gövdedeki küçük kuru boşluklar (gövdenin ortasında seyrek, kuyruğa doğru sık).
	float holes = smoothstep(0.84, 0.92, tn_noise2(px * vec2(0.035, 0.28) + vec2(seed * 5.0)));
	alpha *= 1.0 - holes * mix(0.25, 0.7, tail_t) * bristle;

	// Renk: kıl izleriyle hafif açık/koyu çizgiler; başta boya daha yoğun.
	vec3 col = stroke_color.rgb * (0.88 + 0.2 * streak * bristle + 0.08 * streak_fine);
	col *= mix(0.9, 1.0, smoothstep(0.0, head_len * 2.0, u));
	col = mix(col, col * 1.25 + vec3(0.05), hover);
	COLOR = vec4(col, alpha * stroke_color.a * opacity);
}
