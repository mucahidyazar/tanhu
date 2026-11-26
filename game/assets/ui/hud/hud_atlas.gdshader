// Kitabın HARİTA sayfası (HudMapPage): prototipin 75.000 km²'lik atlası (Three.js, src/map/atlas.js, relief.js) tek bir 2B çizimde.
// 3B çizim yoktur (K63): kabartma önceden üretilmiş dokulardan (tools/atlas/bake_atlas.mjs; assets/map/) her pikselde okunur.
//   atlas düzeyi   kameranın ışını kabartmanın yükseklik dokusunda yürür (ışın yürütme, 48 adım ve ara değer): dağlar eğik bakışta
//                  yükselir, ardındakini örter. Vurduğu yerin rengi prototipin COLOR_HOOK'udur (bozkır, çöl, taşlık, yayla, orman,
//                  kar, kumsal, deniz, göl, ırmak), ışığı paintMaterial'in fırçalı Lambert'i (kuzeybatıdan güneş, gök ve yer ışığı,
//                  dağ ve bulut gölgesi), üstünde siyasi katmanın dolgusu ve çizgisi (AtlasPolitical), kenarda pus, uzakta hava
//                  perspektifi, yukarıda iki bulut katmanı; sonra prototipin son işlemi (üstel ton eşleme, doygunluk, karşıtlık, vinyet).
//   gerçek düzey   (görüş 2,9 birimin altında) iç haritanın tepeden pişirilmiş iki görüntüsü (WorldMap: vadi ve yerel alan) yere
//                  yatırılır; dışarıda atlasın rengi puslu kalır; yürünür alanın kızıl lekesi ve sınırı, alçak bulut katmanı.
// Birim harita birimidir (x doğu, z güney; gerçek düzeyde 1 birim = 1.000 sahne metresi). Kamera HudMapPage.camera_for'dur.
shader_type canvas_item;

// --- Atlasın dokuları -------------------------------------------------------------------------------------------------
uniform sampler2D t_nh : filter_linear_mipmap, repeat_disable;
uniform sampler2D t_bio : filter_linear_mipmap, repeat_disable;
uniform sampler2D t_env : filter_linear_mipmap, repeat_disable;
uniform sampler2D t_river : filter_linear_mipmap, repeat_disable;
uniform sampler2D t_cloud : filter_linear_mipmap, repeat_enable;
uniform sampler2D t_brush : filter_linear_mipmap, repeat_enable;
// Siyasi katman: kâğıdın sRGB'sinde, önceden çarpılmış alfayla (saydam zemine 2B çizim); renk alfaya bölünür, sonra doğrusala çevrilir.
uniform sampler2D t_fill : filter_linear, repeat_disable;
uniform sampler2D t_line : filter_linear, repeat_disable;
uniform float political_on = 0.0;
// --- Gerçek düzeyin pişmiş görüntüleri (WorldMap): vadi ve yerel alan; dikdörtgenler harita biriminde (x, z, en, boy) -------
uniform sampler2D t_valley : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D t_local : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 valley_rect = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 local_rect = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec3 valley_tone = vec3(1.0, 1.0, 0.5); // pozlama, karşıtlık, dayanak parlaklığı (WorldMap.measure)
uniform vec3 local_tone = vec3(1.0, 1.0, 0.5);
uniform vec3 valley_pivot = vec3(0.5);
uniform vec3 local_pivot = vec3(0.5);

uniform vec2 map_size = vec2(50.4175, 29.7515);
uniform float hmax = 0.7;
uniform float gmax = 3.0;
uniform vec3 sun_dir = vec3(-0.7374, 0.4988, -0.4554);

// --- Kamera ve görüş ---------------------------------------------------------------------------------------------------
uniform vec3 cam_pos = vec3(0.0, 20.0, 20.0);
uniform vec3 cam_f = vec3(0.0, -0.7, -0.7);
uniform vec3 cam_r = vec3(1.0, 0.0, 0.0);
uniform vec3 cam_u = vec3(0.0, 0.7, -0.7);
uniform float tan_h = 0.5;
uniform float tan_v = 0.29;
uniform float shift_ndc = 0.0;
uniform float span = 26.0;
uniform float time_s = 0.0;
uniform float real_on = 0.0;
uniform float veil = 0.0;
// Yakınlığa bağlı paylar (prototipin updateAtmosphere'i): siyasi dolgu ve çizgi, yakın ayrıntı, bulut gölgesi, iki gök bulutu, hava
// perspektifinin uzaklığı, ağaçlar.
uniform float fill_amt = 1.0;
uniform float line_amt = 1.0;
uniform float near_amt = 0.0;
uniform float cloud_amt = 1.0;
uniform float sky_amt = 1.0;
uniform float sky_hi_on = 1.0;
uniform float real_cloud_amt = 0.0;
uniform float view_dist = 80.0;
uniform float tree_k = 0.0;
uniform float clouds_on = 1.0;
// Yürünür alan (gerçek düzey; harita birimi).
uniform vec2 area_center = vec2(0.0);
uniform float area_radius = 0.04;
uniform float area_on = 1.0;
// Evin harita noktası (gerçek düzeyin bulutu evin çevresinde akar).
uniform vec2 home_pos = vec2(0.0);
// Son işlem (prototipin atlas ayarı: applyPost).
uniform float exposure = 1.1;
uniform float saturation = 1.1;
uniform float contrast = 1.08;
uniform float vignette = 0.44;

const vec3 HAZE = vec3(0.3968, 0.5089, 0.6445);
const vec3 SUN_COL = vec3(1.0, 0.8148, 0.5776) * 3.5;
const vec3 SKY_COL = vec3(0.5457, 0.6724, 0.8714) * 1.08;
const vec3 GROUND_COL = vec3(0.2016, 0.1746, 0.0976) * 1.08;

vec3 srgb_to_linear(vec3 c) {
	c = clamp(c, 0.0, 1.0);
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// Bulut alanı (prototipin CLOUD_GLSL'i): p harita birimi.
float cloud_field(vec2 p, float t) {
	float a = texture(t_cloud, p * 0.0235 + vec2(t * 0.00125, t * 0.00052)).r;
	float b = texture(t_cloud, p * 0.071 - vec2(t * 0.0009, -t * 0.0011)).r;
	float c = texture(t_cloud, p * 0.23 + vec2(t * 0.0021, t * 0.0004)).g;
	float d = texture(t_cloud, p * 0.71 - vec2(t * 0.0034, 0.0)).g;
	return a * 0.58 + b * 0.27 + c * 0.11 + d * 0.04;
}

float relief_height(vec2 p) {
	return textureLod(t_nh, p / map_size + 0.5, 0.0).b * hmax;
}

// Işın yürütme: y = hmax düzleminden y = 0'a dek; ilk alta düşüşte iki örnek arasında ara değer.
vec3 march(vec3 o, vec3 d) {
	float t0 = max(0.0, (o.y - hmax) / -d.y);
	float t1 = o.y / -d.y;
	float dt = (t1 - t0) / 48.0;
	float tp = t0;
	vec3 p0 = o + d * t0;
	float hp = p0.y - relief_height(p0.xz);
	for (int i = 1; i <= 48; i++) {
		float t = t0 + dt * float(i);
		vec3 p = o + d * t;
		float h = p.y - relief_height(p.xz);
		if (h <= 0.0) {
			float k = hp / max(hp - h, 1e-6);
			return o + d * mix(tp, t, k);
		}
		tp = t;
		hp = h;
	}
	return o + d * t1;
}

// Gök bulutu katmanı (prototipin buildClouds'u): y yüksekliğinde bir düzlem, haritanın dışına doğru yoğun. rgb doğrusal, a örtü.
vec4 sky_cloud(vec3 o, vec3 d, float y, float offset, float scale, float gain, float center, float amt, vec2 origin) {
	if (o.y <= y || d.y >= -0.0001 || amt <= 0.001) {
		return vec4(0.0);
	}
	float t = (o.y - y) / -d.y;
	vec2 w = (o + d * t).xz - origin;
	vec2 p = w * scale + offset;
	float n = cloud_field(p, time_s);
	vec2 q = abs(w * scale) - map_size * 0.5;
	float de = -max(q.x, q.y);
	float edge = smoothstep(3.6, -1.6, de);
	float th = mix(center, 0.45, edge);
	float dd = smoothstep(th, th + 0.13, n);
	vec2 sun2 = normalize(sun_dir.xz);
	float toward = cloud_field(p + sun2 * 0.42, time_s);
	float lit = clamp(0.72 + (n - toward) * 7.0, 0.0, 1.0);
	float thick = smoothstep(th + 0.02, th + 0.3, n);
	vec3 col = mix(vec3(0.56, 0.64, 0.8), vec3(1.22, 1.17, 1.1), lit * 0.72 + thick * 0.28);
	return vec4(col, clamp(dd * amt * gain * mix(0.78, 1.0, edge), 0.0, 1.0));
}

// Kabartmanın ışıklı rengi (doğrusal): prototipin COLOR_HOOK'u, NORMAL_HOOK'u, EMISSIVE_HOOK'u ve FINAL_HOOK'u.
vec3 land(vec3 pw, vec3 view_pos) {
	vec2 m_uv = pw.xz / map_size + 0.5;
	vec4 nh = texture(t_nh, m_uv);
	vec4 bio = texture(t_bio, m_uv);
	vec4 env = texture(t_env, m_uv);
	float rv = texture(t_river, m_uv).r;
	vec2 p = pw.xz;
	float hk = nh.b * hmax;
	vec2 grad = (nh.rg * 2.0 - 1.0) * gmax;
	float slope = length(grad);
	float flow = nh.a;
	float lat = m_uv.y;

	// Gürültü: bölge, yöre ve yakın ölçek.
	float nA = texture(t_cloud, p * 0.043).r;
	float nB = texture(t_cloud, p * 0.27).r;
	float nC = texture(t_cloud, p * 1.15).g;
	float nD = texture(t_cloud, p * 1.7).b;
	float nS = texture(t_brush, p * 0.62).g;

	// Bozkır: kuzeyde yeşil, Gobi çevresinde sararan ot.
	float dry = clamp(smoothstep(0.26, 0.56, lat + (nA - 0.5) * 0.34) * 1.05 - bio.a, 0.0, 1.0);
	vec3 c = mix(vec3(0.1746, 0.2502, 0.0685), vec3(0.4072, 0.3278, 0.1119), dry);
	c = mix(c, vec3(0.2582, 0.3231, 0.0908), smoothstep(0.42, 0.72, nB) * 0.5);
	c = mix(c, vec3(0.5395, 0.4233, 0.1683), smoothstep(0.55, 0.78, nC) * dry * 0.46);
	c = mix(c, vec3(0.3231, 0.2542, 0.1070), smoothstep(0.6, 0.76, nS) * 0.26);
	c = mix(c, vec3(0.1144, 0.1946, 0.0497), smoothstep(0.62, 0.8, nB * 0.5 + nC * 0.5) * (1.0 - dry * 0.6) * 0.5);
	c *= 0.86 + 0.28 * nD;
	// Bol yağış alan güney ve ovalar.
	vec3 lush_c = mix(vec3(0.0723, 0.1946, 0.0423), vec3(0.1470, 0.2747, 0.0595), nB);
	lush_c = mix(lush_c, vec3(0.2918, 0.3515, 0.0976), smoothstep(0.5, 0.72, nC) * 0.42);
	c = mix(c, lush_c, bio.a * 0.94);
	// Vadilerde ot yeşerir.
	float valley = smoothstep(0.4, 0.74, flow);
	c = mix(c, vec3(0.1144, 0.2542, 0.0545), valley * 0.42 * (1.0 - bio.g * 0.2));

	// Çöller: kum dalgaları ve taşlık.
	float dune = sin((p.x * 0.8 + p.y * 2.1 + nB * 7.0 + nC * 2.6) * 11.0) * 0.5 + 0.5;
	vec3 sand_c = mix(vec3(0.5841, 0.3763, 0.1441), vec3(0.7454, 0.5520, 0.2705), dune * 0.55 + nC * 0.45);
	c = mix(c, sand_c, bio.g);
	vec3 stone_c = mix(vec3(0.2705, 0.2270, 0.1620), vec3(0.4179, 0.3467, 0.2346), nC * 0.6 + nB * 0.4);
	stone_c *= 0.88 + 0.24 * nD;
	c = mix(c, stone_c, bio.b);

	// Yüksek yayla ve kayalık: eğim ve yükseklik belirler.
	float plat = smoothstep(0.16, 0.25, hk);
	c = mix(c, mix(vec3(0.2542, 0.1946, 0.1221), vec3(0.3663, 0.2789, 0.1590), nB), plat * 0.85);
	float rocky = smoothstep(0.58, 1.15, slope + (nC - 0.5) * 0.5) * smoothstep(0.035, 0.12, hk);
	vec3 rock_c = mix(vec3(0.1119, 0.0976, 0.0844), vec3(0.2582, 0.2232, 0.1812), nC * 0.55 + nS * 0.45);
	rock_c *= 0.98 + 0.12 * sin(hk * 190.0 + nB * 5.0);
	c = mix(c, rock_c, rocky);

	// Orman: gölgeli, dokulu örtü.
	float canopy = nD * 0.6 + nC * 0.4;
	vec3 forest_c = mix(vec3(0.0137, 0.0437, 0.0252), vec3(0.0437, 0.1144, 0.0482), canopy);
	forest_c = mix(forest_c, vec3(0.0685, 0.1946, 0.0595), bio.a * 0.55);
	float f_a = smoothstep(0.18, 0.62, bio.r + (nC - 0.5) * 0.3);
	c = mix(c, forest_c, f_a);

	// Kar çizgisi güneye doğru yükselir.
	float snow_y = mix(0.27, 0.46, lat);
	float snow = smoothstep(snow_y - 0.012, snow_y + 0.05, hk + (nC - 0.5) * 0.06 + (nB - 0.5) * 0.04);
	snow *= 1.0 - smoothstep(0.8, 1.7, slope + (nC - 0.5) * 0.5) * 0.86;
	float tundra = smoothstep(snow_y - 0.08, snow_y - 0.02, hk);
	c = mix(c, mix(c, vec3(0.1981, 0.1779, 0.1170), 0.6), tundra * (1.0 - plat));
	c = mix(c, vec3(0.8550, 0.8796, 0.9047), snow);

	// Yakınlaşınca ince taş, toprak ve ot lekeleri belirir.
	float near_a = texture(t_brush, p * 2.3).g;
	float near_b = texture(t_cloud, p * 3.4).g;
	c *= 1.0 + ((near_a - 0.5) * 0.32 + (near_b - 0.5) * 0.5) * near_amt;
	c = mix(c, vec3(0.2664, 0.2159, 0.1274), smoothstep(0.66, 0.82, near_b) * (1.0 - f_a) * (1.0 - snow) * near_amt * 0.34);

	// Ağaçlar (prototipin 42.000 küçük ağacı yerine): yakında ormanın içinde tepeden bakan koyu tepeler, güneş yanı açık.
	if (tree_k > 0.01 && f_a > 0.2) {
		vec2 g = p / 0.075;
		vec2 cell = floor(g);
		float best = 9.0;
		vec2 off = vec2(0.0);
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 cc = cell + vec2(float(i), float(j));
				vec2 jit = fract(sin(vec2(dot(cc, vec2(127.1, 311.7)), dot(cc, vec2(269.5, 183.3)))) * 43758.5453);
				vec2 dv = g - (cc + 0.2 + jit * 0.6);
				float dd = length(dv);
				if (dd < best) {
					best = dd;
					off = dv;
				}
			}
		}
		float crown = 1.0 - smoothstep(0.26, 0.36, best);
		float lit_side = clamp(0.5 - dot(off, normalize(sun_dir.xz)) * 1.6, 0.0, 1.0);
		vec3 tree_c = mix(vec3(0.0723, 0.1946, 0.0908), vec3(0.1946, 0.3515, 0.1384), lit_side);
		float shade = smoothstep(0.42, 0.3, length(off + normalize(sun_dir.xz) * 0.12)) * (1.0 - crown);
		c = mix(c, c * 0.55, shade * f_a * tree_k * 0.8);
		c = mix(c, tree_c, crown * smoothstep(0.2, 0.6, f_a) * tree_k);
	}

	// Sırtlar açık, çukurlar koyu.
	c *= mix(0.66, 1.12, env.g);

	// Su.
	float sea_f = smoothstep(0.495, 0.505, env.b);
	float lake = smoothstep(0.42, 0.58, env.a);
	float depth = clamp((env.b - 0.5) * 2.0, 0.0, 1.0);
	float beach = smoothstep(0.45, 0.495, env.b) * (1.0 - sea_f) * (1.0 - smoothstep(0.03, 0.09, hk));
	c = mix(c, vec3(0.6514, 0.5089, 0.2705), beach * 0.8);
	vec3 sea_c = mix(vec3(0.0497, 0.2918, 0.3515), vec3(0.0123, 0.1070, 0.2086), smoothstep(0.0, 0.42, depth));
	sea_c = mix(sea_c, vec3(0.0060, 0.0452, 0.1119), smoothstep(0.35, 1.0, depth));
	sea_c *= 0.94 + 0.12 * nB;
	vec3 lake_c = mix(vec3(0.0252, 0.1812, 0.2789), vec3(0.0123, 0.1022, 0.1878), nB);
	float river_a = smoothstep(0.1, 0.52, rv);
	float bank = smoothstep(0.02, 0.26, rv) * (1.0 - river_a);
	c = mix(c, c * vec3(0.6, 0.72, 0.62), bank);
	float trib = smoothstep(0.66, 0.82, flow) * (1.0 - bio.g) * (1.0 - snow);
	c = mix(c, vec3(0.0497, 0.2122, 0.2874), trib * 0.5);
	c = mix(c, vec3(0.0452, 0.2582, 0.3712), river_a);
	c = mix(c, lake_c, lake);
	float foam = smoothstep(0.5, 0.507, env.b) * (1.0 - smoothstep(0.507, 0.524, env.b + (nC - 0.5) * 0.012));
	c = mix(c, sea_c, sea_f);
	c = mix(c, vec3(0.5583, 0.7379, 0.7454), foam * 0.55);
	float water = max(sea_f, max(lake, river_a));

	// Siyasi katman yalnız karayı tonlar (önceden çarpılmış alfa: renk alfaya bölünür).
	if (political_on > 0.5) {
		float land_k = 1.0 - sea_f;
		vec4 ff = texture(t_fill, m_uv);
		vec4 ll = texture(t_line, m_uv);
		c = mix(c, srgb_to_linear(ff.rgb / max(ff.a, 0.0001)), clamp(ff.a, 0.0, 1.0) * fill_amt * land_k);
		c = mix(c, srgb_to_linear(ll.rgb / max(ll.a, 0.0001)), clamp(ll.a, 0.0, 1.0) * line_amt * land_k);
	}

	// Dağ gölgesi ve bulut gölgesi yalnız güneşi keser.
	float g_cloud = mix(0.46, 1.0, env.r);
	float cs = cloud_field(p + vec2(1.5, 1.1), time_s);
	g_cloud *= 1.0 - 0.36 * cloud_amt * clouds_on * smoothstep(0.64, 0.73, cs);

	// Yakın kabartma: kaya ve ormanda ince pürüz, suda dalga.
	vec2 dg = vec2(nD, texture(t_cloud, p.yx * 1.9).b) - 0.5;
	vec2 dh = vec2(nC, texture(t_cloud, p.yx * 1.31).g) - 0.5;
	vec2 dm = vec2(texture(t_cloud, p * 0.31).g, texture(t_cloud, p.yx * 0.37).g) - 0.5;
	vec2 dn = vec2(near_b, texture(t_cloud, p.yx * 3.1).g) - 0.5;
	dn += (vec2(near_a, texture(t_brush, p.yx * 2.9).g) - 0.5) * 0.5;
	vec2 g_grad = grad * mix(2.9, 1.7, rocky) + dn * 1.05 * near_amt * (1.0 - water)
		+ (dg * 0.5 * (rocky + f_a * 0.8 + 0.24) + dh * 0.62 * (rocky + 0.3) + dm * 0.34) * (1.0 - water) * (1.0 - bio.g * 0.6);
	vec2 wa = texture(t_cloud, p * 1.7 + time_s * vec2(0.012, 0.007)).gb - 0.5;
	vec2 wb = texture(t_cloud, p * 4.3 - time_s * vec2(0.017, -0.011)).gb - 0.5;
	vec2 g_wave = (wa + wb) * 0.16;
	vec2 gn = mix(g_grad, g_wave, water);
	vec3 n = normalize(vec3(-gn.x, 1.0, -gn.y));

	// Fırçalı Lambert (paintMaterial: term 0,06, rampa -0,42..0,74, sıcak sonlandırıcı bant).
	vec4 brush = texture(t_brush, p * 0.42);
	float stroke = brush.r - 0.5 + (brush.g - 0.5) * 0.6;
	float nl = dot(n, sun_dir) + stroke * 0.06;
	float ramp = smoothstep(-0.42, 0.74, nl);
	vec3 band = mix(vec3(1.0, 0.8, 0.66), vec3(1.0), smoothstep(0.1, 0.9, ramp));
	vec3 lit = c / PI * (ramp * SUN_COL * band * g_cloud + mix(GROUND_COL, SKY_COL, 0.5 * n.y + 0.5));

	// Suya gökyüzü yansıması ve güneş parıltısı.
	if (water > 0.01) {
		vec3 v = normalize(view_pos - pw);
		float fres = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 4.0);
		float spec = pow(clamp(dot(n, normalize(sun_dir + v)), 0.0, 1.0), 180.0);
		lit += water * (vec3(0.42, 0.56, 0.72) * (0.1 + fres * 0.9) + vec3(1.5, 1.25, 0.9) * spec * 1.3);
	}

	// Kenarda pus, uzakta hava perspektifi.
	float d_e = min(min(pw.x + map_size.x * 0.5, map_size.x * 0.5 - pw.x), min(pw.z + map_size.y * 0.5, map_size.y * 0.5 - pw.z));
	float n_e = texture(t_cloud, pw.xz * 0.05 + time_s * 0.0006).r;
	float e = smoothstep(0.05, 2.1, d_e + (n_e - 0.5) * 2.8);
	float air = 1.0 - exp(-pow(length(pw - view_pos) / view_dist, 3.0) * 0.2);
	return mix(HAZE, lit, e * (1.0 - air));
}

// Prototipin ton eşlemesi (Post TONE: 1 - e^(-c·pozlama), 2,2 gama).
vec3 tone(vec3 c) {
	c = 1.0 - exp(-max(c, vec3(0.0)) * exposure);
	return pow(c, vec3(1.0 / 2.2));
}

// Pişmiş görüntünün tonu (WorldMap.measure: kazanç, karşıtlık, dayanak) ve haritanın boyalı tonu (eski hud_map.gdshader).
vec3 inset_color(sampler2D tex, vec2 uv, vec3 tn, vec3 pivot) {
	vec3 c = texture(tex, uv).rgb * tn.x;
	c = pivot + (c - pivot) * tn.y;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, l * vec3(1.2, 0.98, 0.64), 0.22) * vec3(1.04, 0.99, 0.9);
	return clamp(c, 0.0, 1.0);
}

// Dikdörtgenin içinde kalma payı (kenara uzaklık, harita birimi; içeride +).
float rect_in(vec4 r, vec2 w) {
	vec2 lo = w - r.xy;
	vec2 hi = r.xy + r.zw - w;
	return min(min(lo.x, lo.y), min(hi.x, hi.y));
}

void fragment() {
	vec2 ndc = vec2(UV.x * 2.0 - 1.0 + shift_ndc, 1.0 - UV.y * 2.0);
	vec3 dir = normalize(cam_f + cam_r * ndc.x * tan_h + cam_u * ndc.y * tan_v);
	vec3 col;
	if (real_on < 0.5) {
		vec3 hit = march(cam_pos, dir);
		vec3 lin = land(hit, cam_pos);
		// İki gök bulutu katmanı (alçak olan önce): yakınlaştıkça açılır.
		vec4 lo = sky_cloud(cam_pos, dir, 1.15, 0.0, 1.0, 0.88, 0.64, sky_amt * clouds_on, vec2(0.0));
		lin = mix(lin, lo.rgb, lo.a);
		vec4 hi = sky_cloud(cam_pos, dir, 1.75, 13.7, 1.0, 0.5, 0.64, sky_amt * sky_hi_on * clouds_on, vec2(0.0));
		lin = mix(lin, hi.rgb, hi.a);
		col = tone(lin);
	} else {
		// Gerçek düzey: düz yer (y = 0); vadi ve yerel alan pişmiş görüntüsüyle, dışarısı atlasın puslu rengi.
		float t = cam_pos.y / max(-dir.y, 0.0005);
		vec3 hit = cam_pos + dir * t;
		vec2 w = hit.xz;
		col = tone(land(vec3(w.x, relief_height(w), w.y), cam_pos + vec3(0.0, relief_height(w), 0.0)));
		col = mix(col, tone(HAZE), 0.55);
		if (valley_rect.z > 0.0) {
			float in_v = rect_in(valley_rect, w);
			float kv = smoothstep(0.0, valley_rect.z * 0.08, in_v);
			if (kv > 0.0) {
				col = mix(col, inset_color(t_valley, (w - valley_rect.xy) / valley_rect.zw, valley_tone, valley_pivot), kv);
			}
		}
		if (local_rect.z > 0.0) {
			float in_l = rect_in(local_rect, w);
			float kl = smoothstep(0.0, local_rect.z * 0.06, in_l);
			if (kl > 0.0) {
				col = mix(col, inset_color(t_local, (w - local_rect.xy) / local_rect.zw, local_tone, local_pivot), kl);
			}
		}
		// Yürünür alan: prototipin devlet lekesi gibi kızıl-kahve leke, içe sönen ışıma, koyu kızıl sınır.
		float px = span / 1100.0;
		float dist = length(w - area_center);
		float fill_k = mix(0.1, 0.3, smoothstep(0.04, 0.2, span)) * area_on;
		vec3 fill_col = vec3(0.62, 0.27, 0.2);
		col = mix(col, col * 0.55 + fill_col * 0.5, fill_k * (1.0 - smoothstep(area_radius - px * 2.0, area_radius, dist)));
		float line_w = px * 2.6;
		float edge_line = 1.0 - smoothstep(line_w * 0.5, line_w * 0.5 + px * 1.2, abs(dist - area_radius));
		float glow = 1.0 - smoothstep(0.0, px * 9.0, abs(dist - area_radius + px * 4.0));
		col = mix(col, mix(col, fill_col * 1.15, 0.35), glow * 0.45 * area_on);
		col = mix(col, vec3(0.42, 0.1, 0.08), edge_line * 0.9 * area_on);
		// Alçak bulut katmanı (prototipin vadinin üstündeki bulutu: 760 m'de, gerçek sahne düzeyinde).
		vec4 rc = sky_cloud(cam_pos, dir, 0.76, 23.0, 5.2, 0.8, 0.43, real_cloud_amt * clouds_on, home_pos);
		col = mix(col, tone(rc.rgb) * 1.02, rc.a);
	}
	// Son işlem: doygunluk, karşıtlık, gölge ve ışık tonu, vinyet, tuval dokusu, düzey geçişinin kararması.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col += vec3(0.0, -0.002, 0.03) * (1.0 - smoothstep(0.0, 0.55, l));
	col += vec3(0.022, 0.01, -0.012) * smoothstep(0.45, 1.0, l);
	vec2 q = UV - 0.5;
	q.x *= mix(1.0, 1.78, 0.35);
	float vg = smoothstep(0.32, 0.92, length(q));
	col *= 1.0 - vg * vignette;
	col = mix(col, col * vec3(0.86, 0.84, 1.02), vg * vignette);
	vec4 cv = texture(t_brush, UV * vec2(1.78, 1.0) * 2.6);
	col *= 1.0 + (cv.g - 0.5) * 0.07 + (cv.a - 0.5) * 0.07 * 0.7;
	col = mix(col, vec3(0.0), veil);
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
