// Gece gökyüzü: yumuşak renk geçişi, yıldızlar, büyük dolunay ve
// ay ışığıyla kenarları parlayan boyalı (painterly) bulutlar.
//
// Yön sistemi: -Z ileri (menü kamerasının baktığı yön, kuzey), +Y yukarı, +X doğu.
// moon_direction değeri GDScript'ten (kampta world.gd, öteki dünyalarda SkyRig) atanır.
//
// Güneş (godot.md §4.9; Önsöz'ün doğum şafağı, SkyRig yazar): disk (sun_disc_size), ufuk ışıltısı ve hale
// (sun_glow_strength), bulutların güneşten aydınlanması (cloud_light_from_sun) ve ortam ışığının (ışınım küp
// haritası) isteğe bağlı panorama kaynağı (ambient_panorama_mix). Hepsinin varsayılanı 0'dır ve her biri kendi
// koşuluyla atlanır: kampın gece göğü ve menü karesi bit bit aynı kalır.
// Zaman yalnız tn_time()'dan okunur (world_time dondurması, godot.md §8.5).
//
// Gerçek gece göğü (time.md §5.6; K35; Serbest Gez'de SkyRig yazar): night_sky > 0 iken yıldız alanı gök kutbunun çevresinde yerel
// yıldız zamanıyla (sky_rotation) döner, kutup enlem kadar yüksektedir (sky_latitude); MÖ 209'un gerçek yerinde adlı dokuz yıldız
// çizilir: Kök Boz At (Kochab, kutba 7,7°), Ak Boz At (Pherkad, 10,9°) ve Yedi Karakçı (Büyük Ayı'nın yedisi, 18–29°). MÖ 209'da
// kutupta parlak yıldız yoktur: Demirkazık «gökte dönmeyen nokta»dır, çizilmez. moon_phase_shade > 0 iken ayın evresi güneşin gerçek
// yönünden çıkar (aydınlık yan güneşe bakar). İkisinin de varsayılanı 0'dır ve kendi koşuluyla atlanır: menü karesi bit bit aynıdır.
shader_type sky;
// Bulutlar pahalıdır: yarım çözünürlüklü geçişte hesaplanıp tam çözünürlükte birleştirilir.
render_mode use_half_res_pass, disable_fog;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

group_uniforms gradient;
uniform vec3 zenith_color : source_color = vec3(0.025, 0.045, 0.16);
uniform vec3 mid_color : source_color = vec3(0.06, 0.11, 0.32);
uniform vec3 horizon_color : source_color = vec3(0.2, 0.3, 0.6);
uniform vec3 ground_color : source_color = vec3(0.04, 0.06, 0.13);

group_uniforms moon;
uniform vec3 moon_direction = vec3(0.39, 0.24, -0.89);
uniform float moon_radius = 0.045;
uniform vec3 moon_color : source_color = vec3(1.0, 0.98, 0.92);
uniform float moon_energy = 3.2;
uniform vec3 moon_glow_color : source_color = vec3(0.5, 0.6, 1.0);
uniform float moon_glow_strength = 0.55;

group_uniforms stars;
uniform vec3 star_color : source_color = vec3(0.9, 0.93, 1.0);
uniform float star_density = 0.05;
uniform float star_brightness = 2.4;

group_uniforms clouds;
uniform vec3 cloud_lit_color : source_color = vec3(0.6, 0.64, 0.92);
uniform vec3 cloud_shadow_color : source_color = vec3(0.21, 0.25, 0.52);
uniform vec3 cloud_rim_color : source_color = vec3(0.95, 0.96, 1.0);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.58;
uniform float cloud_base_coverage : hint_range(0.0, 1.0) = 0.3;
uniform float cloud_softness : hint_range(0.01, 0.5) = 0.04;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.97;
uniform float cloud_scale = 3.4;
uniform float cloud_speed = 0.004;
// Bulutların aydınlandığı yön: 0 ay (kamp), 1 güneş (şafak).
uniform float cloud_light_from_sun : hint_range(0.0, 1.0) = 0.0;

group_uniforms sun;
// Güneşe doğru birim yön (SkyRig kırılmayla görünen yönü yazar: ufuktaki güneşin üst yarısı görünür).
uniform vec3 sun_direction = vec3(0.0, -1.0, 0.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.66, 0.36);
uniform float sun_energy = 6.0;
// Diskin açısal yarıçapı (radyan). 0: disk çizilmez.
uniform float sun_disc_size = 0.0;
uniform vec3 sun_glow_color : source_color = vec3(1.0, 0.56, 0.32);
// Ufuk ışıltısının ve halenin gücü. 0: ışıltı yok.
uniform float sun_glow_strength = 0.0;
// Ufuk ışıltısının güneşin azimutundan yana yayılımı: büyüdükçe dar (kosinüs üssü).
uniform float sun_glow_spread = 3.0;
// Işıltının ufuktan yukarı uzandığı yükseklik (EYEDIR.y).
uniform float sun_glow_height = 0.35;

group_uniforms night;
// Gerçek gece göğünün payı (0: menünün sabit yıldız alanı; >0: dönen gök ve adlı yıldızlar, bu payla).
uniform float night_sky = 0.0;
// Yerin enlemi (derece): gök kutbu kuzeyde bu yükseklikte. Yerel yıldız zamanı (radyan): gök kutup çevresinde bu kadar dönmüştür.
uniform float sky_latitude = 47.35;
uniform float sky_rotation = 0.0;
// Ayın evre gölgesi (0: yok; 1: güneşin bakmadığı yarı karanlık, yalnız yer ışığı kalır).
uniform float moon_phase_shade = 0.0;

group_uniforms ambient;
// Ortam ışığının (yalnız küp haritası geçişi: ortam ve yansıma) kaynağı olarak eşdikdörtgen panorama (HDR).
// Görünen gök boyalı kalır. mix 0: kullanılmaz. offset: panoramanın yatay kayması (0..1; güneşini gökteki
// güneşin azimutuna getirir). Değerler clamp'ta kesilir (güneş diskinin parlaklığı ortamı boğmasın).
uniform sampler2D ambient_panorama : filter_linear, repeat_enable, hint_default_black;
uniform float ambient_panorama_mix : hint_range(0.0, 1.0) = 0.0;
uniform float ambient_panorama_energy = 1.0;
uniform float ambient_panorama_offset = 0.0;
uniform float ambient_panorama_clamp = 12.0;
group_uniforms;

// Havanın katmanı (weather.md §9.7; tekdüzenleri SkyRig yazar, hepsi 0'da kimlik).
#include "res://shaders/include/weather_sky.gdshaderinc"

// Yükseklik açısına göre üç renkli degrade; ayın olduğu taraf biraz daha aydınlık.
vec3 sky_gradient(vec3 dir, vec3 md) {
	float e = dir.y;
	vec3 col = mix(horizon_color, mid_color, smoothstep(0.0, 0.28, e));
	col = mix(col, zenith_color, smoothstep(0.2, 0.95, e));
	vec2 flat_dir = normalize(dir.xz + vec2(0.0001));
	vec2 flat_moon = normalize(md.xz + vec2(0.0001));
	float moon_side = pow(max(dot(flat_dir, flat_moon), 0.0), 3.0);
	col += moon_glow_color * moon_side * (1.0 - smoothstep(0.0, 0.45, e)) * 0.12;
	return mix(col, ground_color, smoothstep(0.0, -0.12, e));
}

// Hücre tabanlı yıldız alanı: her hücrede küçük bir olasılıkla bir yıldız bulunur.
float stars(vec3 dir, float scale, float density, float seed) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	vec3 local = fract(p);
	float h = tn_hash13(cell + seed);
	if (h > density) {
		return 0.0;
	}
	vec3 center = tn_hash33(cell + seed + 4.1) * 0.6 + 0.2;
	float d = length(local - center);
	float size = mix(0.12, 0.27, tn_hash13(cell * 1.7 + seed));
	float core = 1.0 - smoothstep(0.0, size, d);
	float twinkle = 0.7 + 0.3 * sin(tn_time() * (1.2 + h * 90.0) + h * 600.0);
	return core * core * twinkle * mix(0.35, 1.0, tn_hash13(cell * 2.3 + seed));
}

// MÖ 209'un adlı dokuz yıldızı (ekvator çerçevesinde birim yön, xyz; w parlaklık, 10^(−0,4(m − 1,8))). J2000 konumları genel
// presesyonla (50,29″/yıl, 2.208 yıl) MÖ 209'a taşındı, eğiklik 23,44° (oyunun güneşiyle aynı): kutba uzaklıklar time.md §5.6'dır.
const vec4 NAMED_STARS[9] = vec4[9](
	vec4(-0.063199, -0.118282, 0.990967, 0.773), // Kochab, Kök Boz At
	vec4(-0.090271, -0.166099, 0.981969, 0.316), // Pherkad, Ak Boz At
	vec4(-0.160400, 0.271838, 0.948882, 1.009),  // Dubhe (Yedi Karakçı)
	vec4(-0.224902, 0.331555, 0.916237, 0.592),  // Merak
	vec4(-0.336295, 0.250849, 0.907734, 0.555),  // Phecda
	vec4(-0.312240, 0.179829, 0.932828, 0.249),  // Megrez
	vec4(-0.359812, 0.098076, 0.927856, 1.028),  // Alioth
	vec4(-0.390548, 0.028879, 0.920129, 0.649),  // Mizar
	vec4(-0.483245, -0.025334, 0.875118, 0.946)  // Alkaid
);

// Bakış yönünün gök küresindeki (yıldız günüyle dönen ekvator çerçevesindeki) birim yönü: x sağ açıklık 0, z kutup.
vec3 celestial(vec3 dir) {
	float lat = radians(sky_latitude);
	vec3 north = vec3(0.0, 0.0, -1.0);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 pole = north * cos(lat) + up * sin(lat);
	// Saat açısı 0 ve sapma 0: güneydeki ekvator noktası; saat açısı batıya artar.
	vec3 meridian = up * cos(lat) - north * sin(lat);
	vec3 west = vec3(-1.0, 0.0, 0.0);
	float dec = asin(clamp(dot(dir, pole), -1.0, 1.0));
	float ra = sky_rotation - atan(dot(dir, west), dot(dir, meridian));
	return vec3(cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec));
}

// Adlı yıldızlar: küçük yumuşak noktalar (yarıçap ≈0,1°), hafif titrer.
float named_stars(vec3 cel) {
	float sum = 0.0;
	for (int i = 0; i < 9; i++) {
		vec4 st = NAMED_STARS[i];
		float a2 = 2.0 * max(1.0 - dot(cel, st.xyz), 0.0);
		float core = exp(-a2 / 3.0e-6);
		float twinkle = 0.85 + 0.15 * sin(tn_time() * (1.7 + float(i) * 0.61) + float(i) * 4.1);
		sum += core * st.w * twinkle;
	}
	return sum;
}

// Bulut yoğunluğu: büyük ölçekli fBm (kümelerin yerleşimi) + iki kat Worley kabarcığı
// (karnabahar gibi kabarık kenarlar). 3B örnekleme sayesinde gökyüzünde dikiş oluşmaz.
float cloud_field(vec3 p) {
	float base = tn_fbm3(p * 0.55 + vec3(3.1, 0.0, 7.7), 3);
	float puffs = 1.0 - tn_worley3(p * 1.6);
	float small_puffs = 1.0 - tn_worley3(p * 3.7 + vec3(5.0, 1.0, 2.0));
	return base * 0.62 + puffs * 0.28 + small_puffs * 0.1;
}

vec3 cloud_space(vec3 dir) {
	// Bulutlar biraz yassı olsun: dikey ekseni hafifçe sıkıştır.
	return vec3(dir.x, dir.y * 1.35, dir.z) * cloud_scale;
}

// md: ayın yönü (ayın çevresi açık kalır); ld: bulutları aydınlatan yön, light_angle ona açı (kampta ay ve
// moon_angle).
vec4 clouds(vec3 dir, vec3 md, vec3 ld, float moon_angle, float light_angle) {
	if (dir.y < -0.01) {
		return vec4(0.0);
	}
	vec3 drift = vec3(tn_time() * cloud_speed, 0.0, tn_time() * cloud_speed * 0.3);
	vec3 p = cloud_space(dir) + drift;

	// Yerleşim: bulutlar solda ve sağda toplanır, başlığın olduğu orta üst kısım açık kalır.
	float az = atan(dir.x, -dir.z);
	float left = smoothstep(-1.6, -1.0, az) * (1.0 - smoothstep(-0.42, -0.15, az));
	float right = smoothstep(0.18, 0.4, az) * (1.0 - smoothstep(1.2, 1.7, az));
	float sides = max(left, right) * (1.0 - smoothstep(0.32, 0.62, dir.y));
	float band = (1.0 - smoothstep(0.02, 0.1, dir.y)) * 0.75;
	float mask = max(max(sides, band), cloud_base_coverage);
	// Ayın hemen çevresi daha açık kalsın.
	mask *= mix(0.35, 1.0, smoothstep(moon_radius * 1.3, moon_radius * 4.0, moon_angle));
	mask = tn_weather_mask(mask, dir);

	float n = cloud_field(p);
	float threshold = tn_weather_threshold(1.0 - cloud_coverage * mask);
	float density = smoothstep(threshold, threshold + cloud_softness, n);
	if (density <= 0.001) {
		return vec4(0.0);
	}

	// Aydınlatma: gök küresi üzerinde ışığa (kampta aya) doğru kaydırılmış ikinci örnek.
	// Işığa bakan kenarlar parlak, ters taraf mavi gölgede kalır.
	vec3 toward_moon = normalize(ld - dir * dot(ld, dir) + vec3(0.0, 0.0001, 0.0));
	float n2 = cloud_field(cloud_space(normalize(dir + toward_moon * 0.06)) + drift);
	float lit = clamp(0.55 + (n - n2) * 5.0, 0.0, 1.0);
	// Üst kısımlar biraz daha aydınlık (kümülüs hissi).
	lit = clamp(lit + smoothstep(0.0, 0.5, dir.y) * 0.12, 0.0, 1.0);
	lit = mix(lit, smoothstep(0.35, 0.65, lit), 0.5);

	vec3 col = mix(cloud_shadow_color, cloud_lit_color, lit);
	float edge = 1.0 - smoothstep(0.0, 0.6, density);
	float near_moon = exp(-light_angle * 3.0);
	col += cloud_rim_color * edge * (0.12 + near_moon * 0.9) * lit;
	// Ufka yakın bulutlar ufuk rengine karışır (hava perspektifi).
	col = mix(col, horizon_color * 1.1, (1.0 - smoothstep(0.0, 0.2, dir.y)) * 0.45);
	return vec4(col, density * cloud_opacity);
}


// Güneşin ufuk ışıltısı ve halesi: güneşin azimutunda ufka yayılan sıcak bant ve güneşin çevresinde hale.
vec3 sun_glow(vec3 dir, vec3 sd) {
	vec2 flat_dir = normalize(dir.xz + vec2(0.0001));
	vec2 flat_sun = normalize(sd.xz + vec2(0.0001));
	float side = pow(max(dot(flat_dir, flat_sun) * 0.5 + 0.5, 0.0), sun_glow_spread);
	float low = 1.0 - smoothstep(-0.02, max(sun_glow_height, 0.01), dir.y);
	float sun_angle = acos(clamp(dot(dir, sd), -1.0, 1.0));
	float halo = exp(-sun_angle * 2.5) * 0.35 + exp(-sun_angle * 10.0) * 0.65;
	return sun_glow_color * (side * low + halo) * sun_glow_strength;
}

// Eşdikdörtgen panoramadan yön (Godot'nun SKY_COORDS kuralı: u kuzeyden doğuya azimut / 360, v tepeden 0..1).
vec3 panorama(vec3 dir) {
	vec2 uv = vec2(fract(atan(dir.x, -dir.z) / TAU + ambient_panorama_offset), acos(clamp(dir.y, -1.0, 1.0)) / PI);
	return min(textureLod(ambient_panorama, uv, 0.0).rgb, vec3(ambient_panorama_clamp)) * ambient_panorama_energy;
}


void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 md = normalize(moon_direction);
	vec3 col = sky_gradient(dir, md);

	float angle = acos(clamp(dot(dir, md), -1.0, 1.0));
	float halo = exp(-angle * 2.2) * 0.1 + exp(-angle * 7.0) * 0.35 + exp(-angle * 22.0) * 0.6;
	col += moon_glow_color * halo * moon_glow_strength;

	vec3 sd = normalize(sun_direction);
	if (sun_glow_strength > 0.0) {
		col += sun_glow(dir, sd);
	}

	if (AT_CUBEMAP_PASS) {
		// Ortam ışığı için ucuz sürüm: sadece degrade ve hale (istenirse panoramayla karışık).
		if (ambient_panorama_mix > 0.0) {
			col = mix(col, panorama(dir), ambient_panorama_mix);
		}
		COLOR = col;
	} else if (AT_HALF_RES_PASS) {
		vec3 ld = md;
		float light_angle = angle;
		if (cloud_light_from_sun > 0.0) {
			ld = normalize(mix(md, sd, cloud_light_from_sun));
			light_angle = acos(clamp(dot(dir, ld), -1.0, 1.0));
		}
		vec4 cl = clouds(dir, md, ld, angle, light_angle);
		COLOR = tn_weather_cloud(cl.rgb, dir);
		ALPHA = cl.a;
	} else {
		float star_mask = smoothstep(0.02, 0.25, dir.y) * (1.0 - smoothstep(0.0, 0.25, halo));
		if (night_sky > 0.0) {
			// Gerçek gök: alan gök kutbunun çevresinde döner, adlı yıldızlar MÖ 209'un yerinde.
			vec3 cel = celestial(dir);
			float s = stars(cel, 140.0, star_density, 0.0) + stars(cel, 55.0, star_density * 0.35, 7.0) * 1.6;
			s += named_stars(cel) * 2.2 * night_sky;
			col += star_color * s * star_mask * star_brightness;
		} else {
			float s = stars(dir, 140.0, star_density, 0.0) + stars(dir, 55.0, star_density * 0.35, 7.0) * 1.6;
			col += star_color * s * star_mask * star_brightness;
		}

		float disk = 1.0 - smoothstep(moon_radius * 0.965, moon_radius, angle);
		if (disk > 0.0) {
			vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), md));
			vec3 up = cross(md, right);
			vec2 muv = vec2(dot(dir, right), dot(dir, up)) / moon_radius;
			float maria = tn_fbm2(muv * 1.6 + vec2(3.1, 7.7), 4);
			float craters = tn_noise2(muv * 7.0 + 11.0);
			float shade = 1.0 - smoothstep(0.48, 0.7, maria) * 0.28 - smoothstep(0.7, 0.9, craters) * 0.06;
			float limb = sqrt(max(1.0 - dot(muv, muv), 0.0));
			vec3 moon = moon_color * moon_energy * shade * mix(0.78, 1.0, limb);
			if (moon_phase_shade > 0.0) {
				// Bakan yarıkürenin normali ve güneşin ışığı: evre güneşle ayın gerçek yönlerinden çıkar (yer ışığı %6).
				vec3 n = normalize(right * muv.x + up * muv.y - md * limb);
				float lit = smoothstep(-0.06, 0.06, dot(n, sd));
				moon *= mix(1.0, mix(0.06, 1.0, lit), moon_phase_shade);
			}
			col = mix(col, moon, disk);
		}

		if (sun_disc_size > 0.0) {
			// Boyalı güneş diski: kenarı yumuşak, ortası beyaza yakın; ufkun altındaki yarısını zemin örter.
			float sun_angle = acos(clamp(dot(dir, sd), -1.0, 1.0));
			float sun_disk = 1.0 - smoothstep(sun_disc_size * 0.82, sun_disc_size, sun_angle);
			if (sun_disk > 0.0) {
				float core = 1.0 - smoothstep(0.0, sun_disc_size, sun_angle);
				col = mix(col, sun_color * sun_energy * mix(0.85, 1.15, core), sun_disk);
			}
		}

		vec4 cl = HALF_RES_COLOR;
		col = mix(tn_weather_sky(col, dir), cl.rgb, cl.a);
		COLOR = col;
	}
}
