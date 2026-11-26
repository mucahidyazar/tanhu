// Kışlak'ın zemini (K2; godot.md §4.4, §4.6; act1.md §15 «Zemin»): boyanmış 4096² zemin yok. Kar kabartması (yükseklik dokusundan normal ve
// rüzgârın kar dalgası), fırça gürültüsü (rüzgâr yönünde uzamış, boyalı lekeler), düşük çözünürlüklü maske (2 m: R kar, G toprak, B yol,
// A Kar Kabuğu) ve örtü (4 m: R buz, G kaya, B saz, A orman yeri), yol çıkartması (maskenin B'si: çiğnenmiş iz, tekerlek izi). Gölge serin
// mavidir; güneşte kar ince ışıltılıdır. K98'in uzak kadrajında okunur: koyu kişi ak karda, koyu patika ve toprak yön söyler.
//
// Arazi parçaları (MapBaker «gpu»; MapWorld._build_chunk) ortak düz ızgaradır: köşe gölgelendiricisi yüksekliği dokudan alır (texelFetch,
// 1 m'lik örnek; parçanın düğümü (x, 0, z)'de, dönüşsüz), UV2.y eteğin derinliğidir (yüzeyde 0). Normal parçacık gölgelendiricisinde
// normal dokusundan okunur: her düzeyde aynı ışık, dikişte kırılma yok. Dış halka (displace kapalı) kendi köşe yüksekliğini ve normalini
// taşır; maskeler haritanın dışında karla söner.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/weather_ground.gdshaderinc"

uniform bool displace = true;
uniform sampler2D height_tex : filter_nearest, repeat_disable;
uniform sampler2D normal_tex : filter_linear, repeat_disable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform sampler2D cover_tex : filter_linear, repeat_disable;
// Yükseklik ızgarasının ilk örneği (x0, z0) ve aralığı (cell); maskenin dikdörtgeni (x0, z0, 1/en, 1/boy).
uniform vec3 height_grid = vec3(0.0, 0.0, 1.0);
uniform vec4 mask_rect = vec4(0.0, 0.0, 0.001, 0.001);

group_uniforms textures;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float soil_tile = 5.0;
uniform float rock_tile = 4.0;

group_uniforms colors;
uniform vec3 snow : source_color = vec3(0.91, 0.93, 0.96);
uniform vec3 snow_shade : source_color = vec3(0.66, 0.72, 0.81);
uniform vec3 snow_warm : source_color = vec3(0.96, 0.94, 0.9);
uniform vec3 crust : source_color = vec3(0.85, 0.89, 0.94);
uniform vec3 soil : source_color = vec3(0.44, 0.37, 0.29);
uniform vec3 soil_wet : source_color = vec3(0.31, 0.26, 0.21);
uniform vec3 road : source_color = vec3(0.55, 0.5, 0.42);
uniform vec3 road_snow : source_color = vec3(0.79, 0.76, 0.72);
uniform vec3 rock_light : source_color = vec3(0.5, 0.49, 0.47);
uniform vec3 rock_dark : source_color = vec3(0.29, 0.28, 0.27);
uniform vec3 ice : source_color = vec3(0.62, 0.73, 0.8);
uniform vec3 ice_deep : source_color = vec3(0.44, 0.56, 0.66);
uniform vec3 reeds : source_color = vec3(0.71, 0.6, 0.38);
uniform vec3 forest_floor : source_color = vec3(0.36, 0.35, 0.29);

group_uniforms look;
// Rüzgârın kar dalgalarının yönü (dünya xz; kuzeybatıdan esen rüzgâr güneydoğuya akar) ve dalganın derinliği (normal sapması).
uniform vec2 wind_dir = vec2(0.707, 0.707);
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.22;
// Fırça gürültüsünün payı (lekelerin parlaklık farkı) ve boyu (m).
uniform float brush_strength : hint_range(0.0, 1.0) = 0.16;
uniform float brush_scale = 7.0;
// Işıltı: güneşte karın ince parıltısı (kabukta güçlü).
uniform float sparkle : hint_range(0.0, 2.0) = 0.35;
// Hava kabuğu yazınca (weather: crust) maskenin A'sı görünür; I. Perde'de 0 (weather.md W26), görünüş için taban pay.
uniform float crust_amount : hint_range(0.0, 1.0) = 0.35;

group_uniforms fires;
// Nöbet ateşlerinin sahte ışığı (act1.md §15: gerçek ışık yok): (x, z, yarıçap, yanma payı); WatchFires yazar (16:30–07:40).
uniform vec4 fires[12];
uniform int fire_count = 0;
uniform vec3 fire_color : source_color = vec3(1.0, 0.46, 0.14);
uniform float fire_energy = 1.4;

group_uniforms lighting;
uniform vec3 shadow_tint : source_color = vec3(0.6, 0.66, 0.8);
uniform float shadow_level : hint_range(0.0, 1.0) = 0.62;
uniform float slope_light : hint_range(0.0, 1.0) = 0.55;
group_uniforms;

varying vec3 v_world_pos;
varying vec3 v_vertex_normal;
// Işıltının payı (parçacık gölgelendiricisi yazar, ışık işlevi okur).
varying float v_glint;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (displace) {
		ivec2 size = textureSize(height_tex, 0);
		ivec2 t = clamp(ivec2(round((wp.xz - height_grid.xy) / height_grid.z)), ivec2(0), size - ivec2(1));
		float h = texelFetch(height_tex, t, 0).r - UV2.y;
		VERTEX.y = h;
		wp.y = h + MODEL_MATRIX[3].y;
	}
	v_world_pos = wp;
	v_vertex_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 ratio(sampler2D tex, vec2 uv, float lod) {
	float mean = max(luma(textureLod(tex, vec2(0.5), 12.0).rgb), 0.02);
	return vec3(luma(texture(tex, uv, lod).rgb) / mean);
}

void fragment() {
	vec2 p = v_world_pos.xz;
	vec2 uv = (p - mask_rect.xy) * mask_rect.zw;
	// Normal: yükseklik dokusundan (parçalar) ya da köşeden (dış halka).
	vec3 n;
	if (displace) {
		vec2 nxz = texture(normal_tex, uv).rg * 2.0 - 1.0;
		n = normalize(vec3(nxz.x, sqrt(max(1.0 - dot(nxz, nxz), 0.0)), nxz.y));
	} else {
		n = normalize(v_vertex_normal);
	}
	// Maskelerin kenarı gürültüyle kırılır (2 ve 4 m'lik örnek yumuşak leke olmasın).
	vec2 jitter = vec2(tn_noise2(p * 0.9), tn_noise2(p * 0.9 + 17.0)) - 0.5;
	vec2 jitter2 = vec2(tn_noise2(p * 3.1 + 5.0), tn_noise2(p * 3.1 + 29.0)) - 0.5;
	vec2 muv = (p + jitter * 1.8 + jitter2 * 0.6 - mask_rect.xy) * mask_rect.zw;
	vec4 m = texture(mask_tex, muv);
	vec4 c = texture(cover_tex, muv);
	// Haritanın dışı (dış halka): maskeler son 20 m'de söner, dışı kardır.
	vec2 edge = min(uv, vec2(1.0) - uv) / max(mask_rect.zw, vec2(1e-6));
	float inside = smoothstep(0.0, 20.0, min(edge.x, edge.y));
	m = mix(vec4(1.0, 0.0, 0.0, 0.0), m, inside);
	c = mix(vec4(0.0), c, inside);

	// Fırça gürültüsü: rüzgâr yönünde uzamış lekeler (boyalı darbe), büyük ve orta ölçek.
	vec2 along = normalize(wind_dir);
	vec2 across = vec2(-along.y, along.x);
	vec2 q = vec2(dot(p, along) / 3.2, dot(p, across)) / brush_scale;
	float stroke = tn_fbm2(q * 1.0, 3);
	float big = tn_fbm2(p * 0.018, 3);
	float mid = tn_fbm2(p * 0.12, 2);
	float small = tn_noise2(p * 1.7);

	// Kar: gölgeli çukurlar (big) maviye, tümsekler sıcağa çalar; fırça darbesi parlaklığı gezer.
	vec3 col = mix(snow_shade, snow, smoothstep(0.18, 0.62, big * 0.6 + n.y * 0.4));
	col = mix(col, snow_warm, smoothstep(0.62, 0.85, big) * 0.35);
	// Boyalı lekeler: rüzgâr yönünde uzamış darbe (stroke) ve geniş bulut gölgesi gibi tonlar; düz karın tek beyaz okunmaması için.
	float cloud = tn_fbm2(p * 0.045 + 7.0, 2);
	col *= 1.0 + (stroke - 0.5) * brush_strength * 2.0;
	col *= 0.89 + 0.12 * smoothstep(0.25, 0.75, cloud);
	col = mix(col, snow_shade * 1.05, smoothstep(0.55, 0.9, mid * 0.6 + stroke * 0.4) * 0.12);
	// Kar Kabuğu: açık düzlükte pürüzsüz, hafif mavi, ışıltılı.
	float crust_w = smoothstep(0.25, 0.7, m.a + (mid - 0.5) * 0.3) * crust_amount;
	col = mix(col, crust * (0.98 + small * 0.04), crust_w * 0.7);
	// Orman yeri: iğne yaprak, kar seyrek ve gri.
	float forest_w = smoothstep(0.3, 0.8, c.a + (mid - 0.5) * 0.4);
	col = mix(col, mix(col * 0.82, forest_floor, smoothstep(0.55, 0.85, small * 0.5 + mid * 0.5) * 0.55), forest_w);
	// Saz: karın üstünde saman rengi sap benekleri.
	if (c.b > 0.02) {
		float stalk = smoothstep(0.62, 0.78, tn_noise2(vec2(dot(p, along) * 2.4, dot(p, across) * 9.0)));
		float reed_w = smoothstep(0.25, 0.7, c.b + (mid - 0.5) * 0.3);
		col = mix(col, reeds * (0.8 + small * 0.3), reed_w * (0.35 + stalk * 0.5));
	}
	// Buz: ırmak ve göl. Pürüzsüz, gök tonuna yakın, ince çatlak ve rüzgârın sürüklediği kar şeritleri.
	float ice_w = smoothstep(0.35, 0.75, c.r + (jitter.x) * 0.2);
	if (ice_w > 0.001) {
		float crack = 1.0 - smoothstep(0.0, 0.035, abs(tn_noise2(p * 0.35) - 0.5)) * 0.5;
		vec3 ice_col = mix(ice_deep, ice, smoothstep(0.25, 0.75, tn_fbm2(p * 0.05, 2)));
		ice_col *= mix(1.0, crack, 0.6);
		float drift = smoothstep(0.45, 0.75, tn_fbm2(q * 2.0 + 3.0, 2));
		ice_col = mix(ice_col, snow * 0.96, drift * 0.7);
		col = mix(col, ice_col, ice_w);
	}
	// Toprak: çiğnenmiş kar, kirli çamur, kül; ocakların çevresinde koyu.
	float soil_w = smoothstep(0.3, 0.7, m.g + (mid - 0.5) * 0.3 + (small - 0.5) * 0.12);
	vec3 soil_col = mix(soil_wet, soil, smoothstep(0.3, 0.7, tn_noise2(p * 0.5))) * mix(vec3(1.0), ratio(soil_tex, p / soil_tile, -0.5), 0.7);
	// Çiğnenmiş yerde kar lekeleri kalır.
	// Çiğnenmiş kar: kenarda gri-kahve sulu kar, ortada toprak; kar lekeleri kalır.
	float leftover = smoothstep(0.5, 0.8, tn_noise2(p * 0.8 + 3.0) * 0.7 + (1.0 - m.g) * 0.6);
	soil_col = mix(mix(road_snow * 0.9, soil_col, 0.25 + 0.6 * smoothstep(0.5, 0.95, m.g)), road_snow, leftover * 0.5);
	col = mix(col, soil_col, soil_w);
	// Yol çıkartması: sıkışmış kar ve koyu tekerlek, toynak izi. İzin kenarı kırık.
	float road_w = smoothstep(0.25, 0.65, m.b + (small - 0.5) * 0.18 + (jitter2.x) * 0.15);
	if (road_w > 0.001) {
		// Sıkışmış kar ve kirli iz: büyük, yumuşak lekeler (yol sürekli bir bant okunur), ortası (B yüksek) daha koyu.
		float ruts = smoothstep(0.35, 0.9, tn_fbm2(p * 0.32 + 11.0, 2) * 0.55 + m.b * 0.45);
		vec3 road_col = mix(road_snow, road, 0.3 + ruts * 0.45);
		road_col *= mix(vec3(1.0), ratio(soil_tex, p / (soil_tile * 0.8) + 0.3, 0.0), 0.35 * ruts);
		col = mix(col, road_col, road_w);
	}
	// Kaya: dik yamaç (örtünün G'si ya da normal); tabakalı, karla benekli.
	float steep = max(smoothstep(0.82, 0.62, n.y + jitter.x * 0.05), smoothstep(0.35, 0.8, c.g));
	if (steep > 0.001) {
		float bands = fract(v_world_pos.y * 0.45 + jitter.y * 0.8 + big * 3.0);
		vec3 rock = mix(rock_dark, rock_light, 0.4 + 0.45 * smoothstep(0.15, 0.65, bands));
		rock *= mix(vec3(1.0), ratio(rock_tex, p / rock_tile + v_world_pos.y * 0.13, 0.0), 0.8);
		// Kayanın üst yüzlerinde kar tutar.
		rock = mix(rock, snow * 0.95, smoothstep(0.55, 0.85, n.y + small * 0.15) * 0.8);
		col = mix(col, rock, steep * 0.92 * (1.0 - ice_w));
	}
	// Erime (ocak): kar mask R'si 0'a iner, toprak zaten G'dedir; R düşükse kar incelir.
	col = mix(mix(col, soil_col, (1.0 - m.r) * 0.6), col, step(0.98, m.r));
	// Havanın kar örtüsü ve ıslaklığı (weather_ground; taze kar izleri örter).
	col = tn_weather_ground(col, v_world_pos, n, small, mid);

	// Kabartma: rüzgârın kar dalgaları normale küçük sapma verir (kar, kabuk ve buzda; toprakta ve yolda az).
	float flat_snow = (1.0 - soil_w) * (1.0 - road_w * 0.7) * (1.0 - steep);
	float rip = tn_noise2(vec2(dot(p, along) * 0.55, dot(p, across) * 2.1));
	float rip2 = tn_noise2(vec2(dot(p, along) * 0.55 + 0.37, dot(p, across) * 2.1));
	// Kar dalgası (sastrugi): rüzgâra dik uzanan, 2–6 m'lik sırtlar; eğimi gürültünün farkından (ucuz türev).
	vec2 dq = vec2(dot(p, along) / 6.0, dot(p, across) / 2.4);
	float dune = tn_fbm2(dq, 2);
	float dune2 = tn_fbm2(dq + vec2(0.0, 0.12), 2);
	vec2 tilt = across * (rip2 - rip) * ripple_strength * 2.4 * flat_snow + (jitter2 * 0.08) * flat_snow;
	tilt += across * (dune2 - dune) * 2.8 * ripple_strength * flat_snow * (1.0 - ice_w);
	n = normalize(n + vec3(tilt.x, 0.0, tilt.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);

	ALBEDO = col;
	// Nöbet ateşlerinin zemin parıltısı: yarıçapın içinde karesel sönen turuncu; ateşin dibinde kor.
	float glow = 0.0;
	for (int i = 0; i < fire_count; i++) {
		vec4 f = fires[i];
		float d = distance(p, f.xy) / max(f.z, 0.01);
		float k = 1.0 - clamp(d, 0.0, 1.0);
		glow += f.w * (k * k * 0.85 + smoothstep(0.12, 0.0, d) * 1.5);
	}
	EMISSION = col * fire_color * glow * fire_energy * (0.9 + small * 0.2);
	// Kar pürüzlü, kabuk ve buz daha pürüzsüz; ışıltı küçük hücrelerde parlak noktadır (uzakta söner).
	ROUGHNESS = mix(0.92, 0.42, max(crust_w * 0.6, ice_w * 0.85));
	// Işıltı noktası: 6 cm'lik hücrede en çok bir yuvarlak nokta; nokta piksel altına inince (uzakta) söner, kare desen olmaz.
	vec2 gq = p * 16.0;
	vec2 gcell = floor(gq);
	vec2 gc = vec2(tn_hash12(gcell + 3.7), tn_hash12(gcell + 9.1)) * 0.6 + 0.2;
	float pix = length(fwidth(gq));
	float gdot = 1.0 - smoothstep(0.06, 0.06 + pix, length(fract(gq) - gc));
	float glint = step(0.993, tn_hash12(gcell)) * gdot * (1.0 - smoothstep(0.35, 0.9, pix)) * flat_snow * (1.0 - forest_w) * (1.0 - ice_w * 0.5);
	SPECULAR = 0.22;
	v_glint = glint * sparkle * (1.0 + crust_w);
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float slope = mix(1.0, clamp(dot(NORMAL, LIGHT) * 0.75 + 0.45, 0.0, 1.0), slope_light);
		vec3 shadow = shadow_tint * shadow_level;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * slope * mix(shadow, vec3(1.0), ATTENUATION);
		// Işıltı: yarım vektöre dik bakan küçük yüzler (SPECULAR yüksekse) parlar.
		vec3 hv = normalize(LIGHT + VIEW);
		float spec = pow(max(dot(NORMAL, hv), 0.0), mix(8.0, 64.0, 1.0 - ROUGHNESS)) * v_glint;
		SPECULAR_LIGHT += LIGHT_COLOR * spec * ATTENUATION * 2.0;
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	}
}
