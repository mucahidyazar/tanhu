// Boyalı alev: kameraya dönük (yalnızca Y ekseninde) bir kart üzerinde, yukarı akan gürültüyle
// dalgalanan damla biçimli alev. HDR renk sayesinde parlama (glow) yapar.
// Renkler referanstaki gibi doygun sarı-turuncudur: üst üste binen katmanlar bile beyaza patlamasın diye
// çekirdek sarı, dış dil kızıldır.
//
// Karışım önceden çarpılmış alfadır (blend_premul_alpha): alev kendi ışığını ekler ve arkasındakini
// "coverage" oranında örter. Salt toplamalı karışımda arkadaki yeşil çimen alevin rengine eklenir ve
// gece renk ayarından sonra alevin üst dilleri zeytin yeşili görünür; örtme bunu önler, alevi de
// referanstaki gibi belirgin boyalı bir biçim yapar. Kenarlarda (shape küçük) karışım yine toplamalıdır.
shader_type spatial;
render_mode blend_premul_alpha, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

uniform vec3 core_color : source_color = vec3(1.0, 0.53, 0.15);
uniform vec3 mid_color : source_color = vec3(1.0, 0.37, 0.07);
uniform vec3 edge_color : source_color = vec3(0.7, 0.11, 0.03);
uniform float energy = 3.0;
uniform float speed = 1.6;
uniform float seed = 0.0;
// Alevin arkasındakini örtme oranı (0 = salt toplamalı ışık, 1 = alevin ortası opak boya).
uniform float coverage : hint_range(0.0, 1.0) = 0.5;
// Kenar keskinliği (0 = yumuşak ışık lekesi, 1 = keskin boyalı kenar).
uniform float edge_sharpness : hint_range(0.0, 1.0) = 0.6;

void vertex() {
	// Y ekseninde sabit ilan panosu: alev hep dik durur ama kameraya döner.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float y = 1.0 - UV.y;
	float x = (UV.x - 0.5) * 2.0;
	float t = tn_time() * speed + seed * 10.0;
	float n = tn_fbm2(vec2(UV.x * 3.5 + seed * 3.0, UV.y * 2.6 + t), 4);
	float n2 = tn_noise2(vec2(UV.x * 7.0 - seed, UV.y * 5.0 + t * 1.7));
	// Damla biçimi: altta geniş, yukarı doğru incelir; gürültü alevi yana savurur.
	float width = 0.62 * pow(max(1.0 - y, 0.0), 0.75) * smoothstep(0.0, 0.18, y + 0.05);
	float dx = abs(x + (n - 0.5) * 0.55 * y);
	float inner = mix(0.35, 0.75, edge_sharpness);
	float shape = 1.0 - smoothstep(width * inner, width, dx);
	// Üst kısım gürültüyle aşınır; alev dil dil ayrılır.
	shape *= smoothstep(1.0, mix(0.35, 0.62, edge_sharpness), y + (n2 - 0.5) * 0.45);
	shape = clamp(shape, 0.0, 1.0);
	float heat = shape * (1.0 - y * 0.6);
	vec3 col = mix(edge_color, mid_color, smoothstep(0.1, 0.45, heat));
	col = mix(col, core_color, smoothstep(0.55, 0.85, heat));
	// Önceden çarpılmış alfa: renk şekille çarpılır (kenarlar yumuşakça söner), örtme ayrı ayarlanır.
	ALBEDO = col * energy * shape;
	ALPHA = clamp(shape * coverage, 0.0, 1.0);
}
