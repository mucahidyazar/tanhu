// Şırdak: iki renkli keçenin birbirine kakılmasıyla yapılan desenli taban keçesi (Kırgız ve Kazak otağlarının
// döşemesi). İç alan gözlere bölünür; her gözde koçboynuzu (koçkar müyüz) motifi vardır ve gözler renkleri
// birbirinin tersi olacak biçimde dama gibi sıralanır. Motiflerin kenarında açık renkli kaytan (ip) dikişi,
// çevrede boynuz kıvrımları dizili bir bordür ve dış kenarda kaytan şerit bulunur.
// UV 0..1; "size" keçenin metre cinsinden ölçüsüdür. Işık ortak "After the Wind" cel modelidir.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/atw_light.gdshaderinc"

uniform vec2 size = vec2(2.0, 1.3);
uniform vec4 color_a : source_color = vec4(0.62, 0.1, 0.07, 1.0);
uniform vec4 color_b : source_color = vec4(0.12, 0.16, 0.34, 1.0);
uniform vec4 cord_color : source_color = vec4(0.94, 0.84, 0.55, 1.0);
// Bir gözün hedef boyu (metre; iç alana tam sayıda göz sığacak biçimde yuvarlanır) ve bordürün eni.
uniform float cell_size = 0.42;
uniform float border_width = 0.15;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float fill(float d, float aa) {
	return 1.0 - smoothstep(-aa, aa, d);
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Kıvrık boynuz: merkezi c, yarıçapı r olan halkanın, ağzı "open" yönüne bakan kısmı (yaklaşık 3/4 halka).
float sd_curl(vec2 p, vec2 c, float r, float w, vec2 open_dir) {
	vec2 d = p - c;
	float ring = abs(length(d) - r) - w;
	float gap = dot(normalize(d + vec2(0.0001)), open_dir) - 0.55;
	return max(ring, gap * 0.25);
}

// Koçboynuzu motifi (göz uzayı -1..1; d < 0 motifin içi): ortada basamaklı elmas, dört çaprazda kol, her kolun
// ucunda iki yana kıvrılan boynuz.
float ram_horn(vec2 q) {
	vec2 a = abs(q);
	float d = (a.x + a.y) - 0.34;
	d = min(d, sd_segment(a, vec2(0.12, 0.12), vec2(0.5, 0.5)) - 0.085);
	d = min(d, sd_curl(a, vec2(0.7, 0.4), 0.16, 0.065, normalize(vec2(-0.7, -1.0))));
	d = min(d, sd_curl(a, vec2(0.4, 0.7), 0.16, 0.065, normalize(vec2(-1.0, -0.7))));
	return d;
}

void fragment() {
	vec2 p = UV * size;
	float aa = max(fwidth(p.x), fwidth(p.y)) * 0.8;
	float n = tn_noise2(v_world_pos.xz * 2.6);
	float fine = tn_noise2(v_world_pos.xz * 30.0);
	// Elle kesilmiş keçe: desen koordinatı hafifçe titrer.
	vec2 w = p + vec2(tn_noise2(p * 2.5) - 0.5, tn_noise2(p * 2.5 + 9.0) - 0.5) * 0.025;
	vec2 e2 = min(w, size - w);
	float edge = min(e2.x, e2.y);
	vec3 col;
	if (edge < border_width) {
		// Bordür: koyu zeminde boyuna dizilmiş boynuz kıvrımları (kenar boyunca dalga).
		float along = (e2.x < e2.y) ? w.y : w.x;
		float across = edge / border_width;
		float wave = abs(across - 0.5 - 0.26 * sin(along / border_width * 3.14159));
		float d = wave - 0.16;
		col = mix(color_b.rgb, color_a.rgb, fill(d, aa * 3.0));
		col = mix(col, cord_color.rgb, fill(abs(d) - 0.025, aa * 3.0) * 0.9);
		col = mix(col, cord_color.rgb, fill(abs(edge - border_width) - 0.01, aa));
		col = mix(col, color_b.rgb * 0.7, fill(edge - 0.018, aa));
	} else {
		vec2 inner = size - vec2(border_width * 2.0);
		vec2 counts = max(floor(inner / cell_size + 0.5), vec2(1.0));
		vec2 cell = inner / counts;
		vec2 c = (w - vec2(border_width)) / cell;
		vec2 id = floor(c);
		vec2 q = (fract(c) - 0.5) * 2.0;
		float d = ram_horn(q);
		bool swap = mod(id.x + id.y, 2.0) > 0.5;
		vec3 ground = swap ? color_b.rgb : color_a.rgb;
		vec3 motif = swap ? color_a.rgb : color_b.rgb;
		float caa = aa * 2.0 / min(cell.x, cell.y);
		col = mix(ground, motif, fill(d, caa));
		col = mix(col, cord_color.rgb, fill(abs(d) - 0.045, caa) * 0.9);
		// Gözler arası ince kaytan çizgileri.
		vec2 grid = abs(fract(c) - 0.5);
		col = mix(col, cord_color.rgb * 0.85, fill(0.5 - max(grid.x, grid.y) - 0.012, caa) * 0.6);
	}
	// Keçe dokusu: geniş lekeler ve ince lif gürültüsü.
	col *= 0.9 + n * 0.14 + (fine - 0.5) * 0.06;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
