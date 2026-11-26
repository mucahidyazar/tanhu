// Havanın zemin ve çim kancaları (weather.md §9.8, §9.9, §5.9; godot.md §3.5): ıslak zemin, birikinti, kar örtüsü (taze kar ve SnowPack;
// kampta yalnız kışın tutar, K67), dolu beyazlığı ve rüzgârın bükmesi. Değerleri WeatherView genel tekdüzenlere yazar
// (project.godot [shader_globals]). Hepsinin varsayılanı 0'dır ve her kanca kendi koşuluyla atlanır: menü karesi bit bit aynı kalır.
// Yeni doku ve program yoktur; malzemeler kendi gölgelendiricilerinde bu dosyayı içerir (arazi, kampın çim tutamı).
// Birden fazla dosya bu dosyayı içerebilir: koruma tek tanım bırakır.

#ifndef TN_WEATHER_GROUND
#define TN_WEATHER_GROUND

// x zemin ıslaklığı, y kar örtüsü (görünüş), z birikinti, w dolu beyazlığı (0..1).
global uniform vec4 weather_ground;
// xy rüzgârın akış yönü (dünya xz, birim), z bükülme çarpanı (windK; 0: kimlik, çim kendi tekdüzenini kullanır), w bora payı.
global uniform vec4 weather_wind;

// Zemin rengi: ıslakken koyulaşır (yukarı bakan yüzde ×(1 − 0,28·ıslaklık)), düz ve alçak yerlerde birikinti gök tonuna çalar, kar
// örtüsü yukarı bakan yüzü fırça gürültüsüyle düzensiz kenarla örter, dolu ak taneli örtü bırakır. n dünya normali; small ve mid
// gölgelendiricinin kendi gürültüleri (0..1).
vec3 tn_weather_ground(vec3 col, vec3 p, vec3 n, float small, float mid) {
	if (weather_ground == vec4(0.0)) {
		return col;
	}
	float up = smoothstep(0.3, 0.9, n.y);
	col *= 1.0 - weather_ground.x * 0.28 * up;
	if (weather_ground.z > 0.0) {
		float level = smoothstep(0.97, 0.995, n.y);
		float pool = smoothstep(0.55, 0.75, tn_noise2(p.xz * 0.21 + 9.0)) * level * weather_ground.z;
		col = mix(col, col * 0.55 + vec3(0.05, 0.07, 0.09), pool * 0.7);
	}
	if (weather_ground.y > 0.0) {
		float edge = (small - 0.5) * 0.35 + (mid - 0.5) * 0.3;
		float cover = smoothstep(0.05, 0.6, weather_ground.y * 1.25 - (1.0 - up) * 1.1 + edge);
		vec3 snow = vec3(0.84, 0.88, 0.95) * (0.93 + small * 0.09);
		col = mix(col, snow, cover);
	}
	if (weather_ground.w > 0.0) {
		// Dolu: ince ak taneler (≈14 cm'lik ızgarada hücre başına en çok bir yuvarlak tane; payı dolu beyazlığıyla büyür). Tane piksel
		// altına inince (uzakta) örtü ortalama beyazlığa söner: blok blok desen olmaz.
		vec2 q = p.xz * 7.0;
		vec2 cell = floor(q);
		float on = step(1.0 - weather_ground.w * 0.7, tn_hash12(cell));
		vec2 c = vec2(tn_hash12(cell + 3.7), tn_hash12(cell + 9.1)) * 0.4 + 0.3;
		float pix = length(fwidth(q));
		float grain = (1.0 - smoothstep(0.2, 0.2 + max(pix, 0.08), length(fract(q) - c))) * on;
		float far = smoothstep(0.35, 0.9, pix);
		grain = mix(grain, weather_ground.w * 0.7 * 0.126, far) * up;
		col = mix(col, vec3(0.9, 0.92, 0.95), weather_ground.w * 0.12 * up);
		col = mix(col, vec3(0.94, 0.96, 0.98), grain * 0.9);
	}
	return col;
}

// Çim tutamının rengi: ıslakken ×(1 − 0,2·ıslaklık) koyulaşır, kar örtüsünde uçlar beyaza döner (tutam karın altında kısalır:
// tn_weather_grass_height). h yaprağın yüksekliği (0 kök, 1 uç).
vec3 tn_weather_grass(vec3 col, float h) {
	if (weather_ground == vec4(0.0)) {
		return col;
	}
	col *= 1.0 - weather_ground.x * 0.2;
	if (weather_ground.y > 0.0) {
		col = mix(col, vec3(0.84, 0.88, 0.95), clamp(weather_ground.y * 1.4 - (1.0 - h) * 0.4, 0.0, 1.0));
	}
	return col;
}

// Kar örtüsünde tutamın boy çarpanı (1 kimlik).
float tn_weather_grass_height() {
	return 1.0 - clamp(weather_ground.y, 0.0, 1.0) * 0.75;
}

#endif
