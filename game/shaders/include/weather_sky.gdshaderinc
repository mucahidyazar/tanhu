// Gök kubbesinin hava katmanı (weather.md §9.6, §9.7; godot.md §4.9): örtü, karanlık, şimşek, toz ve bulut açıklığı. Tekdüzenleri
// SkyRig yazar (hava girdisinin «sky» ezmesi; ışığın ve göğün tek yazıcısı odur). Hepsinin varsayılanı 0'dır ve her biri kendi
// koşuluyla atlanır: menü karesi bit bit aynı kalır. Işınım küp haritası geçişine (ortam ışığı) uygulanmaz: havanın ışığa etkisi
// SkyRig'in çarpanıdır, iki kez uygulanmaz.

#ifndef TN_WEATHER_SKY
#define TN_WEATHER_SKY

group_uniforms weather;
// Örtü eşiği kaydırması (türün cover_sky'ı, en çok 0,35): bulut bütün göğe yayılır.
uniform float weather_cover = 0.0;
// Bulut ve gök karanlığı (türün dark'ı): bulut ×(1 − 0,6·dark), gök gri-maviye.
uniform float weather_dark = 0.0;
// Şimşek (0..1) ve yönü (oyuncudan, birim): bulutun içi o yönde parlar.
uniform float weather_flash = 0.0;
uniform vec3 weather_flash_dir = vec3(0.0, 0.25, -1.0);
// Toz rengi (okr) karışımı.
uniform float weather_dust = 0.0;
// Bulut açıklığı (Gök Açılır, Kara Boran yıldızı): xyz yön, w yarıçap (radyan; 0 yok).
uniform vec4 weather_gap = vec4(0.0);
group_uniforms;

// Bulut maskesi ve eşiği: örtü bütün göğe yayılır, açıklık yönünde çekilir.
float tn_weather_mask(float mask, vec3 dir) {
	if (weather_cover > 0.0) {
		mask = max(mask, clamp(weather_cover * 2.86, 0.0, 1.0));
	}
	if (weather_gap.w > 0.0) {
		float a = acos(clamp(dot(dir, normalize(weather_gap.xyz)), -1.0, 1.0));
		mask *= smoothstep(weather_gap.w * 0.6, weather_gap.w, a);
	}
	return mask;
}

float tn_weather_threshold(float threshold) {
	return threshold - weather_cover * 0.5;
}

// Bulutun rengi: karanlık ve şimşek.
vec3 tn_weather_cloud(vec3 col, vec3 dir) {
	if (weather_dark > 0.0) {
		col *= 1.0 - 0.6 * weather_dark;
	}
	if (weather_flash > 0.0) {
		float toward = pow(max(dot(dir, normalize(weather_flash_dir)), 0.0), 3.0);
		col += vec3(0.86, 0.9, 1.0) * weather_flash * (0.35 + 1.6 * toward);
	}
	return col;
}

// Göğün rengi (bulutların altı): karanlık gri-maviye, toz okre çalar; şimşek göğü de aydınlatır.
vec3 tn_weather_sky(vec3 col, vec3 dir) {
	if (weather_dark > 0.0) {
		float lum = dot(col, vec3(0.3, 0.59, 0.11));
		col = mix(col, vec3(0.42, 0.46, 0.52) * lum * 1.1, weather_dark * 0.7);
		col *= 1.0 - 0.35 * weather_dark;
	}
	if (weather_dust > 0.0) {
		col = mix(col, vec3(0.7, 0.55, 0.36) * (0.4 + dot(col, vec3(0.3, 0.59, 0.11))), clamp(weather_dust, 0.0, 1.0) * 0.75);
	}
	if (weather_flash > 0.0) {
		float toward = pow(max(dot(dir, normalize(weather_flash_dir)), 0.0), 2.0);
		col += vec3(0.7, 0.75, 0.9) * weather_flash * (0.15 + 0.6 * toward);
	}
	return col;
}

#endif
