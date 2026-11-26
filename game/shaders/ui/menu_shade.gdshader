// Ana menü gölge bandı: alttan yukarı doğru yumuşakça kaybolan koyu gece mavisi.
// Butonların açık renkli çimenin üstünde rahat okunmasını sağlar.
// mode = 0: dikey bant (alt kenarda en koyu). mode = 1: ortada yumuşak elips hale (başlığın arkası için).
shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/include/noise.gdshaderinc"

uniform vec4 shade_color : source_color = vec4(0.012, 0.022, 0.065, 0.66);
// Geçişin eğrisi: büyüdükçe koyuluk alt kenara daha çok yığılır.
uniform float curve = 1.7;
// Yan kenarlarda ek koyuluk (yumuşak vinyet hissi).
uniform float side_darkening = 0.18;
uniform int mode = 0;

void fragment() {
	float a;
	if (mode == 1) {
		// Kenarda eğimi sıfır olan yumuşak düşüş: koyu zeminde bile belirgin bir halka (kenar izi) oluşmaz.
		vec2 c = (UV - vec2(0.5)) * 2.0;
		float r = length(c);
		a = shade_color.a * pow(1.0 - smoothstep(0.0, 1.0, r), curve);
	} else {
		float t = pow(clamp(UV.y, 0.0, 1.0), curve);
		float side = abs(UV.x - 0.5) * 2.0;
		a = shade_color.a * t * (1.0 - side_darkening + side_darkening * side * side);
	}
	// Koyu geçişlerde renk bantlaşmasını önlemek için küçük üçgen dağılımlı titreşim (dither).
	float dither = (tn_hash12(FRAGCOORD.xy) + tn_hash12(FRAGCOORD.yx + 19.7) - 1.0) * 1.5 / 255.0;
	COLOR = vec4(shade_color.rgb, clamp(a + dither, 0.0, 1.0));
}
