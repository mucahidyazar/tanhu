// Arazi malzemesi: çayır, orman tabanı, kayalık yamaçlar, kıyı ve kamp toprağı.
// Renkler dünya konumu, eğim ve büyük ölçekli gürültüyle boyanır;
// böylece doku dosyası olmadan "fırça lekeli" bir zemin elde edilir.
//
// Köşe rengi (COLOR) kanalları TerrainShape.vertex_tint() tarafından doldurulur:
//   r = orman yoğunluğu, g = çayır canlılığı, b = kayalık sırt maskesi.
// Toprak patikalar PathNetwork tarafından doldurulan path_* dizileriyle çizilir.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
// Işık: ortak "After the Wind" cel modeli (düz aydınlık taraf, sabit oranlı gölge, yumuşak sınır).
#include "res://shaders/include/atw_light.gdshaderinc"
// Hava: ıslak zemin, birikinti, kar örtüsü, dolu (weather.md §9.8; genel tekdüzen 0'da kimlik).
#include "res://shaders/include/weather_ground.gdshaderinc"

// Çayır renkleri AtW çimen tutamlarının kök rengiyle aynı ailedendir (tutam araları zemin gibi görünür).
uniform vec4 grass_light : source_color = vec4(0.3, 0.5, 0.21, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.24, 0.44, 0.22, 1.0);
uniform vec4 grass_warm : source_color = vec4(0.36, 0.52, 0.18, 1.0);
uniform vec4 forest_floor : source_color = vec4(0.07, 0.17, 0.1, 1.0);
uniform vec4 rock_color : source_color = vec4(0.46, 0.48, 0.53, 1.0);
uniform vec4 rock_dark : source_color = vec4(0.27, 0.29, 0.37, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.52, 0.44, 0.34, 1.0);
uniform vec4 shore_color : source_color = vec4(0.38, 0.42, 0.33, 1.0);
uniform vec4 underwater_color : source_color = vec4(0.1, 0.17, 0.22, 1.0);
uniform float water_level = -36.0;
// Kamp çevresindeki toprak lekeleri: (x, z, yarıçap, şiddet).
uniform vec4 dirt_spots[12];
uniform int dirt_spot_count = 0;

// --- Patikalar (PathNetwork doldurur; dizi boyutları PathNetwork.MAX_SEGMENTS ile aynı) ---
// Her parça vec4(ax, az, bx, bz); patika, parçaların çevresindeki kapsüllerin birleşimidir.
uniform vec4 path_segments[64];
uniform float path_half_widths[64];
// Sekizli parça gruplarının kutuları (min_x, min_z, max_x, max_z): kutu dışındaki pikseller grubu atlar.
uniform vec4 path_group_bounds[8];
uniform int path_segment_count = 0;
// Tüm ağın kutusu: dışındaki pikseller (vadi, dağlar) patika hesabına hiç girmez.
uniform vec4 path_bounds = vec4(1.0, 1.0, -1.0, -1.0);
uniform vec4 path_color : source_color = vec4(0.6, 0.5, 0.42, 1.0);
uniform vec4 path_edge_color : source_color = vec4(0.45, 0.38, 0.29, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.88, 0.84, 0.74, 1.0);
// Kenarın ne kadar tırtıklı olduğu (metre).
uniform float path_edge_noise = 0.15;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// En yakın patika kenarına işaretli uzaklık (metre): içeride eksi, dışarıda artı.
float path_distance(vec2 p) {
	float d = 1000.0;
	int group_count = (path_segment_count + 7) / 8;
	for (int g = 0; g < group_count; g++) {
		vec4 gb = path_group_bounds[g];
		if (p.x < gb.x || p.y < gb.y || p.x > gb.z || p.y > gb.w) {
			continue;
		}
		int last = min(g * 8 + 8, path_segment_count);
		for (int i = g * 8; i < last; i++) {
			vec4 s = path_segments[i];
			vec2 pa = p - s.xy;
			vec2 ba = s.zw - s.xy;
			float t = clamp(dot(pa, ba) / max(dot(ba, ba), 0.000001), 0.0, 1.0);
			d = min(d, length(pa - ba * t) - path_half_widths[i]);
		}
	}
	return d;
}

// Patika toprağını zemin rengine işler (boyalı, yumuşak ve tırtıklı kenarlı).
// pixel_size: pikselin zemindeki boyu (metre), fragment()'te fwidth ile hesaplanır.
// dirt_mask: kamp toprağı lekelerinin bu noktadaki gücü; lekenin içinde patika kenarı belirmez,
// böylece patika ateşin çevresindeki toprağa dikişsiz karışır.
vec3 apply_paths(vec3 col, vec3 p, float mid, float small, float pixel_size, float dirt_mask) {
	if (path_segment_count <= 0 || p.x < path_bounds.x || p.z < path_bounds.y || p.x > path_bounds.z || p.z > path_bounds.w) {
		return col;
	}
	float d = path_distance(p.xz);
	if (d > 0.9) {
		return col;
	}
	// Kenarı iki ölçekli gürültüyle boz: fırçayla çizilmiş gibi düzensiz bir sınır.
	float wobble = (tn_noise2(p.xz * 1.7) - 0.5) * 2.0 * path_edge_noise + (tn_noise2(p.xz * 6.3 + 3.1) - 0.5) * 0.09;
	float e = d + wobble;
	float inside = (1.0 - smoothstep(-0.1, 0.05, e)) * (1.0 - smoothstep(0.25, 0.85, dirt_mask) * 0.85);
	// Kenara yakın toprak koyu ve nemli, ortası güneşte ağarmış açık toprak.
	float center = smoothstep(-0.04, -0.42, e);
	vec3 dirt = mix(path_edge_color.rgb, path_color.rgb, center);
	dirt *= 0.9 + tn_noise2(p.xz * 2.6 + 7.0) * 0.16 + (mid - 0.5) * 0.08;
	// Yürünmüş izler: yol boyunca uzayan hafif açık/koyu lekeler.
	dirt *= 0.96 + (small - 0.5) * 0.12;
	// Küçük açık renkli taş benekleri: çoğu kenara yakın, ortada seyrek.
	// (Uzaktan titremesin diye piksel boyuna göre söner.)
	vec2 q = p.xz * 5.0;
	vec2 cell = floor(q);
	vec2 c = vec2(tn_hash12(cell + 17.3), tn_hash12(cell + 41.9)) * 0.6 + 0.2;
	float near_edge = smoothstep(-0.55, -0.12, e);
	float speck = (1.0 - smoothstep(0.05, 0.1, length(fract(q) - c))) * step(mix(0.975, 0.88, near_edge), tn_hash12(cell));
	speck *= 1.0 - smoothstep(0.02, 0.07, pixel_size);
	vec3 pebble = mix(dirt, pebble_color.rgb, 0.65) * (0.9 + tn_hash12(cell + 5.0) * 0.2);
	dirt = mix(dirt, pebble, speck * 0.8);
	vec3 result = mix(col, dirt, inside);
	// Kenarın hemen dışında çimen biraz koyulaşır (çimenin toprağa düşen gölgesi).
	float rim = smoothstep(0.0, 0.1, e) * (1.0 - smoothstep(0.1, 0.55, e)) * (1.0 - dirt_mask);
	return result * (1.0 - rim * 0.18);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 p = v_world_pos;
	float slope = 1.0 - v_world_normal.y;
	float big = tn_fbm2(p.xz * 0.011, 3);
	float mid = tn_noise2(p.xz * 0.085);
	float small = tn_noise2(p.xz * 0.55);

	// Çayır: büyük açık/koyu yeşil lekeler + sıcak tonlu yamalar.
	vec3 grass = mix(grass_dark.rgb, grass_light.rgb, smoothstep(0.28, 0.72, big * 0.7 + mid * 0.3));
	grass = mix(grass, grass_warm.rgb, smoothstep(0.62, 0.8, tn_noise2(p.xz * 0.03 + 4.0)) * 0.5);
	grass *= 0.9 + small * 0.2;
	grass = mix(grass, grass_light.rgb * 1.05, COLOR.g * 0.35);
	grass = mix(grass, forest_floor.rgb, COLOR.r);

	// Dik yamaçlar ve kayalık sırtlar taş rengine döner.
	float rock_mask = smoothstep(0.36, 0.52, slope + (mid - 0.5) * 0.16);
	rock_mask = max(rock_mask, COLOR.b * smoothstep(0.15, 0.3, slope + (small - 0.5) * 0.1));
	vec3 rock = mix(rock_dark.rgb, rock_color.rgb, tn_noise2(p.xz * 0.18 + p.y * 0.3) * 0.7 + v_world_normal.y * 0.3);
	vec3 col = mix(grass, rock, rock_mask);

	// Kıyı şeridi ve su altı.
	float shore = 1.0 - smoothstep(water_level + 0.4, water_level + 2.0, p.y + (mid - 0.5) * 0.8);
	col = mix(col, shore_color.rgb, shore * 0.75);
	col = mix(col, underwater_color.rgb, 1.0 - smoothstep(water_level - 2.5, water_level - 0.1, p.y));

	// Kamp toprağı (ateş çevresi, patikalar).
	float dirt_mask = 0.0;
	for (int i = 0; i < dirt_spot_count; i++) {
		vec4 s = dirt_spots[i];
		float d = length(p.xz - s.xy) + (small - 0.5) * s.z * 0.45 + (mid - 0.5) * s.z * 0.25;
		float m = (1.0 - smoothstep(s.z * 0.45, s.z, d)) * s.w;
		col = mix(col, dirt_color.rgb * (0.85 + small * 0.3), m);
		dirt_mask = max(dirt_mask, m);
	}

	// Toprak patikalar.
	col = apply_paths(col, p, mid, small, length(fwidth(p.xz)), dirt_mask);
	col = tn_weather_ground(col, p, v_world_normal, small, mid);

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
