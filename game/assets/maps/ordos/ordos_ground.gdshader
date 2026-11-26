// childhood_ordos'un boyalı zemini (scripts/maps/ordos_ground.gd, ordos_world.gd): atw_ground'un dili, güz tonu.
//
// mode 0  Zemin: kuru, solgun sarı güz otunun dibi (atw_grass tutamlarının kök rengiyle aynı aile: tutam araları
//         zemin gibi görünür). Büyük lekeler gürültüden; küçük renk lekeleri ücretsiz dokudan (mottle_tex). Doku
//         yalnız düşük frekanslı, basamaklı bir renk oranı olarak okunur: mip kaydırmasıyla (mottle_lod) fotoğrafın
//         ayrıntısı atılır, oranın parlaklığı birkaç tona yuvarlanır (mottle_steps), boyalı leke kalır. Çiğnenmiş
//         toprağın çevresinde ot ezik ve kahverengidir (üst katmanın kenarı buna karışır).
// mode 1  Çiğnenmiş toprak katmanı (avlu, kapı önleri, sayım hattının izi): zeminin ızgarasıyla aynı köşelerde,
//         birkaç santim yukarıda; kenarı gürültüyle kesilir (discard, saydamlık yok).
// mode 2  Disk (yurdun toprak tabanı, ocağın külü): ağın yerel uzayında disc_center çevresinde (yurt ya da ocak
//         taşınınca disk de onunla gider), kenarı gürültülü.
// Her malzeme tek bir ücretsiz doku kullanır (düğümün free_asset meta verisi; assets/_free/FREE_ASSETS.json).
//
// Işık: düz boyalı model (atw_ground gibi). Yönlü ışıkta düşen gölge serin bir tona döner; interior > 0 iken
// (yurt içi) gölge koyulaşır: kapalı yerde gün ışığı yalnız kapıdan girer. Nokta ışıklar (ocak) sarılmış Lambert.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"

const int MAX_CIRCLES = 12;
const int MAX_TRAILS = 12;

uniform int mode = 0;

group_uniforms colors;
// mode 0: otun dibi; mode 1: çiğnenmiş toprağın ortası; mode 2: diskin ortası.
uniform vec4 base_color : source_color = vec4(0.56, 0.47, 0.29, 1.0);
// Güneşli lekeler (mode 0) ya da açık toprak (mode 1).
uniform vec4 sunny_color : source_color = vec4(0.64, 0.54, 0.32, 1.0);
// Gölgeli lekeler (mode 0) ya da kenar (mode 1, 2).
uniform vec4 dark_color : source_color = vec4(0.45, 0.39, 0.25, 1.0);
// Çiğnenmiş toprağın çevresindeki ezik otun rengi (mode 0).
uniform vec4 trampled_tint : source_color = vec4(0.55, 0.45, 0.31, 1.0);
uniform float variation_scale = 0.05;

group_uniforms mottle;
uniform sampler2D mottle_tex : source_color, filter_linear_mipmap, repeat_enable;
// Dokunun dünyada kapladığı kare (metre), mip kaydırması, gücü ve ton basamağı.
uniform float mottle_tile = 9.0;
uniform float mottle_lod = 3.5;
uniform float mottle_strength = 0.5;
uniform float mottle_steps = 4.0;

group_uniforms trampled;
// Daireler (x, z, yarıçap, _) ve izler (ax, az, bx, bz) + yarı genişlik (OrdosGround.ground_uniforms).
uniform vec4 trampled_circles[MAX_CIRCLES];
uniform int trampled_circle_count = 0;
uniform vec4 trampled_trails[MAX_TRAILS];
uniform float trampled_trail_widths[MAX_TRAILS];
uniform int trampled_trail_count = 0;
uniform float trampled_soft = 1.2;
// Çiğnenmiş toprağın kenarını dalgalandıran gürültü (metre).
uniform float edge_noise = 1.1;

group_uniforms disc;
// Diskin merkezi ağın yerel uzayındadır (x, z).
uniform vec2 disc_center = vec2(0.0);
uniform float disc_radius = 1.0;
uniform float disc_soft = 0.25;

group_uniforms lighting;
uniform vec3 shadow_tint : source_color = vec3(0.62, 0.68, 0.84);
uniform float shadow_level : hint_range(0.0, 1.0) = 0.8;
// Yamaçların ışığa göre hafif koyulaşması (0 = tamamen düz).
uniform float slope_light : hint_range(0.0, 1.0) = 0.25;
// Kapalı yer (yurt içi): gölgedeki gün ışığı bu oranda söner.
uniform float interior : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

varying vec3 v_world_pos;
varying vec2 v_local;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local = VERTEX.xz;
}

float segment_distance(vec2 p, vec4 s) {
	vec2 a = s.xy;
	vec2 ab = s.zw - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	return length(p - (a + ab * t));
}

// Çiğnenmiş toprağın kenarına işaretli uzaklık (içeride eksi; OrdosGround.trampled_distance ile aynı).
float trampled_distance(vec2 p) {
	float best = 1e5;
	for (int i = 0; i < MAX_CIRCLES; i++) {
		if (i >= trampled_circle_count) {
			break;
		}
		vec4 c = trampled_circles[i];
		best = min(best, length(p - c.xy) - c.z);
	}
	for (int i = 0; i < MAX_TRAILS; i++) {
		if (i >= trampled_trail_count) {
			break;
		}
		best = min(best, segment_distance(p, trampled_trails[i]) - trampled_trail_widths[i]);
	}
	return best;
}

// Dokudan boyalı renk oranı: düşük frekanslı örnek / dokunun ortalaması (en küçük mip), parlaklığı basamaklı.
vec3 mottle(vec2 p) {
	vec3 m = textureLod(mottle_tex, p / mottle_tile, mottle_lod).rgb;
	vec3 mean = max(textureLod(mottle_tex, vec2(0.5), 12.0).rgb, vec3(0.02));
	vec3 ratio = m / mean;
	float l = max((ratio.r + ratio.g + ratio.b) / 3.0, 0.001);
	float q = floor(l * mottle_steps + 0.5) / mottle_steps;
	return mix(vec3(1.0), ratio / l * q, mottle_strength);
}

void fragment() {
	vec2 p = v_world_pos.xz;
	vec3 col;
	if (mode == 1) {
		float n = tn_fbm2(p * 0.45, 3);
		float d = trampled_distance(p) + (n - 0.5) * edge_noise;
		if (d > 0.0) {
			discard;
		}
		float inner = smoothstep(0.0, -trampled_soft * 1.6, d);
		float light_patch = smoothstep(0.45, 0.75, tn_fbm2(p * 0.35 + 7.3, 2));
		col = mix(dark_color.rgb, base_color.rgb, inner);
		col = mix(col, sunny_color.rgb, light_patch * inner * 0.6);
		col *= mottle(p);
	} else if (mode == 2) {
		float n = tn_fbm2(p * 1.3, 3);
		float d = length(v_local - disc_center) - disc_radius + (n - 0.5) * disc_soft * 2.0;
		if (d > 0.0) {
			discard;
		}
		float inner = smoothstep(0.0, -disc_radius * 0.7, d);
		col = mix(dark_color.rgb, base_color.rgb, inner) * mottle(p);
	} else {
		float big = tn_fbm2(p * variation_scale, 3);
		col = mix(dark_color.rgb, base_color.rgb, smoothstep(0.25, 0.5, big));
		col = mix(col, sunny_color.rgb, smoothstep(0.55, 0.8, big));
		col *= mottle(p);
		float d = trampled_distance(p);
		col = mix(col, trampled_tint.rgb, (1.0 - smoothstep(0.0, trampled_soft * 2.5, d)) * 0.55);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float slope = mix(1.0, clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0), slope_light);
		vec3 shadow = shadow_tint * shadow_level * (1.0 - interior * 0.85);
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * slope * mix(shadow, vec3(1.0), ATTENUATION);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	}
}
