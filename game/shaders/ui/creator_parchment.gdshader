// Parşömen kâğıdı paneli: krem rengi, lifli kâğıt; yırtık, hafif yanık koyu kenarlar ve yumuşak gölge.
//
// Düğüm kâğıttan her yönde "margin" piksel büyüktür; aradaki boşluğa kâğıdın gölgesi düşer.
// Tüm ölçüler piksel cinsindendir; böylece lifler ve yırtıklar panel boyutundan bağımsız görünür.
shader_type canvas_item;

#include "res://shaders/include/noise.gdshaderinc"

// Düğümün piksel boyutu (CreatorShaderRect günceller).
uniform vec2 rect_size = vec2(760.0, 920.0);
// Kâğıt kenarı ile düğüm kenarı arasındaki boşluk (gölge için).
uniform float margin = 40.0;
uniform vec4 paper_light : source_color = vec4(0.98, 0.94, 0.81, 1.0);
uniform vec4 paper_dark : source_color = vec4(0.92, 0.85, 0.7, 1.0);
uniform vec4 burn_color : source_color = vec4(0.5, 0.35, 0.17, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.01, 0.07, 0.07, 0.55);
uniform vec2 shadow_offset = vec2(7.0, 14.0);
uniform float shadow_softness = 30.0;
// Yırtık kenarın dalgalanma miktarı (piksel).
uniform float tear = 5.0;
// Kenardaki kahverengi "yanık" bandın genişliği (piksel). Dar tutulur: kâğıt yalnızca kenarında
// hafifçe yanmış görünsün (referanstaki gibi ince, koyu, lifli bir kenar çizgisi baskın kalır).
uniform float burn_width = 22.0;
// Yanık bandın ve en dıştaki koyu kenar çizgisinin gücü (0..1).
uniform float burn_strength : hint_range(0.0, 1.0) = 0.6;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.7;
// Farklı paneller farklı görünsün diye desen tohumu.
uniform float seed = 4.0;

mat2 rot2(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

// Kâğıdın yırtık kenarlı biçimi: negatif = kâğıdın içi (piksel cinsinden uzaklık).
float paper_shape(vec2 px) {
	vec2 half_size = rect_size * 0.5 - vec2(margin);
	float d = sd_box(px - rect_size * 0.5, half_size - vec2(5.0)) - 5.0;
	// Büyük dalgalanma + küçük lif çıkıntıları + çok ince tırtıklar.
	d += (tn_fbm2(px * 0.017 + vec2(seed), 3) - 0.5) * tear * 2.2;
	d += (tn_noise2(px * 0.15 + vec2(seed * 3.0)) - 0.5) * tear * 0.8;
	d += (tn_noise2(px * 0.55 + vec2(seed * 7.0)) - 0.5) * tear * 0.3;
	return d;
}

// Farklı yönlerde uzanan kısa, ince kâğıt lifleri (0..1). Her yön kendi seyrek gürültüsüyle
// maskelenir; böylece lifler uzun çizgiler değil, dağınık kısa kıllar olur.
float fibers(vec2 px) {
	float f = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 q = rot2(float(i) * 1.7 + seed) * px + vec2(float(i) * 37.0);
		float line = tn_noise2(vec2(q.x * 0.09, q.y * 0.75));
		float sparse = tn_noise2(q * 0.045 + vec2(float(i) * 11.0));
		f += smoothstep(0.8, 0.95, line) * smoothstep(0.55, 0.8, sparse);
	}
	return clamp(f, 0.0, 1.0);
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 half_size = rect_size * 0.5 - vec2(margin);
	float d = paper_shape(px);
	float paper_a = clamp(0.5 - d, 0.0, 1.0);

	// Gölge: kâğıdın kaydırılmış ve yumuşatılmış hali.
	float ds = sd_box(px - rect_size * 0.5 - shadow_offset, half_size - vec2(12.0)) - 12.0;
	float shadow_a = (1.0 - smoothstep(-shadow_softness * 0.6, shadow_softness, ds)) * shadow_color.a;

	// Kâğıt rengi: büyük lekeler ve küçük benekler.
	float stain = tn_fbm2(px * 0.0045 + vec2(seed), 4);
	float mottle = tn_fbm2(px * 0.028 + vec2(seed * 2.0), 3);
	vec3 col = mix(paper_dark.rgb, paper_light.rgb, smoothstep(0.22, 0.7, stain * 0.62 + mottle * 0.38));
	// Ortası biraz daha açık; kâğıt ışığı ortadan alıyor gibi.
	vec2 c = (px - rect_size * 0.5) / max(half_size, vec2(1.0));
	col = mix(col, paper_light.rgb * 1.02, (1.0 - smoothstep(0.15, 1.15, length(c))) * 0.4);
	// Kâğıt hamuru topakları, lifler ve tane.
	float pulp = tn_fbm2(px * 0.09 + vec2(seed * 4.0), 3);
	col *= 0.985 + (pulp - 0.5) * 0.06;
	col *= 1.0 - fibers(px) * 0.05;
	col *= 0.975 + tn_noise2(px * 1.1) * 0.045;
	// Kenara yaklaştıkça koyulaşan, düzensiz yanık bant ve en dışta ince koyu kontur.
	float burn_noise = (tn_fbm2(px * 0.02 + vec2(seed * 5.0), 3) - 0.5) * burn_width * 1.1;
	float edge = smoothstep(-burn_width, 0.0, d + burn_noise);
	col = mix(col, burn_color.rgb, edge * edge * edge * burn_strength);
	float outline = smoothstep(-3.5, -0.5, d + (tn_noise2(px * 0.3) - 0.5) * 2.0);
	col = mix(col, burn_color.rgb * 0.62, outline * outline_strength);

	// Kâğıt, gölgenin üzerine biner ("over" birleştirme).
	float alpha = paper_a + shadow_a * (1.0 - paper_a);
	vec3 rgb = (col * paper_a + shadow_color.rgb * shadow_a * (1.0 - paper_a)) / max(alpha, 0.0001);
	COLOR = vec4(rgb, alpha);
}
