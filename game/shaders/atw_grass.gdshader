// "After the Wind" tarzı çimen tutamları (MultiMesh ile çizilir; model: AtwKit.tuft).
//
// - Her tutam kameraya döner (dikey eksende); ince, sivri yaprakların üst kenarları
//   arkadaki tutamların koyu diplerinin üstüne düşer ve "testere dişi" çimen halısı oluşur.
// - Renk yaprak boyunca koyu kökten (zemin rengiyle aynı) açık uca geçer. Büyük ölçekli gürültü
//   bazı bölgeleri güneşli sarı-yeşile, bazılarını derin yeşile çeker (boyalı lekeler).
// - Işık düzdür (normaller yukarı): çimenlik tek bir boyalı yüzey gibi aydınlanır; düşen gölgeler
//   (karakter, kaya) serin, koyu bir yeşile döner.
// - Uzaktaki yapraklar genişler (UV2.x: köşenin yaprak ekseninden uzaklığı; Meadow.tuft_mesh doldurur): ekranda
//   piksel altına düşen ince yapraklar hem pahalıdır hem de referanstaki fırça darbelerinden incedir.
//   UV2 olmayan modellerde (AtwKit.tuft) etkisizdir.
// - Renk lekeleri tutam başına sabittir: Meadow onları önceden hesaplayıp INSTANCE_CUSTOM.a ile verir
//   (instance_patches); verilmezse köşe shader'ında hesaplanır. Parça (fragment) başına gürültü yoktur.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"
// Hava: rüzgârın bükmesi, ıslaklık, kar örtüsü (weather.md §9.8, §9.9; genel tekdüzen 0'da kimlik).
#include "res://shaders/include/weather_ground.gdshaderinc"

group_uniforms colors;
// Kök rengi zeminle aynı olmalı: böylece tutamların arası "çimen gölgesi" gibi görünür.
uniform vec4 root_color : source_color = vec4(0.26, 0.46, 0.24, 1.0);
uniform vec4 mid_color : source_color = vec4(0.4, 0.63, 0.2, 1.0);
uniform vec4 tip_color : source_color = vec4(0.51, 0.71, 0.16, 1.0);
// Güneşli lekelerde uç ve orta rengin kaydığı sarı-yeşil.
uniform vec4 sun_color : source_color = vec4(0.56, 0.74, 0.12, 1.0);
// Derin lekelerde renklerin kaydığı koyu yeşil.
uniform vec4 deep_color : source_color = vec4(0.25, 0.46, 0.21, 1.0);
uniform float patch_scale = 0.09;
// true: renk lekesi değeri (0..1) örneğin INSTANCE_CUSTOM.a kanalından okunur (Meadow önceden hesaplar).
uniform bool instance_patches = false;
uniform float sun_patches : hint_range(0.0, 1.0) = 0.8;
uniform float deep_patches : hint_range(0.0, 1.0) = 0.45;
// Yaprak boyunca renk geçişinin başladığı ve bittiği oranlar (0 kök, 1 uç).
uniform float gradient_start : hint_range(0.0, 1.0) = 0.1;
uniform float gradient_end : hint_range(0.0, 1.0) = 0.95;
// Yaprak başına küçük ton farkı.
uniform float tone_variation : hint_range(0.0, 0.5) = 0.1;
group_uniforms lighting;
// Düşen gölgedeki çimenin renk çarpanı (serin, koyu yeşil).
uniform vec3 shadow_tint : source_color = vec3(0.6, 0.72, 0.8);
// 1 = tamamen düz ışık (güneşin yüksekliği önemli değil), 0 = yukarı normale göre Lambert.
uniform float light_flatness : hint_range(0.0, 1.0) = 1.0;
group_uniforms motion;
uniform float wind_strength = 0.07;
uniform float wind_speed = 1.1;
uniform vec2 wind_direction = vec2(0.85, 0.3);
// Tutamın rastgele yönden sapma miktarı (radyan, ±yarısı).
uniform float yaw_jitter = 1.7;
uniform float fade_start = 26.0;
uniform float fade_end = 40.0;
// Yaprakların kameradan uzaklaştıkça genişlemesi: widen_start metreden sonra her metrede widen_rate kadar,
// en çok widen_max katına kadar.
uniform float widen_start = 12.0;
uniform float widen_rate = 0.09;
uniform float widen_max = 2.8;
group_uniforms;

varying float v_h;
varying float v_tone;
// Tutamın renk lekesi değeri (tutam başına sabit; köşeden parçaya tek bir sayı taşınır).
varying float v_patch;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	v_h = clamp(UV.y, 0.0, 1.0);
	v_tone = UV.x;
	// Kameraya dön: yerel +Z kameraya baksın. (Örneğin dönüşümünde dönme yoktur, yalnızca ölçek.)
	vec2 to_cam = CAMERA_POSITION_WORLD.xz - root.xz;
	float cam_dist = distance(root, CAMERA_POSITION_WORLD);
	// Uzaktaki yapraklar genişler (bkz. widen_*): yalnızca yaprak ekseninden yatay uzaklık büyür.
	VERTEX.x += UV2.x * (clamp(1.0 + (cam_dist - widen_start) * widen_rate, 1.0, widen_max) - 1.0);
	float yaw = atan(to_cam.x, to_cam.y) + (INSTANCE_CUSTOM.b - 0.5) * yaw_jitter;
	float c = cos(yaw);
	float s = sin(yaw);
	VERTEX = vec3(VERTEX.x * c + VERTEX.z * s, VERTEX.y, -VERTEX.x * s + VERTEX.z * c);
	// Rüzgâr: uçlar salınır, kökler sabit.
	float h2 = v_h * v_h;
	float phase = tn_time() * wind_speed + dot(root.xz, vec2(0.21, 0.17));
	float gust = tn_noise2(root.xz * 0.045 + tn_time() * vec2(0.25, 0.1));
	float sway = (sin(phase) * 0.55 + sin(phase * 2.31 + 1.7) * 0.2 + gust * 1.3 - 0.35) * wind_strength * h2;
	vec2 sway_dir = normalize(wind_direction);
	if (weather_wind.z > 0.0) {
		// Havanın rüzgârı: yön ve bükülme (windK; fırtınada ×2,3), bora payıyla.
		sway_dir = weather_wind.xy;
		sway = (sway + 0.35 * wind_strength * h2 * weather_wind.w) * weather_wind.z;
	}
	VERTEX.xz += sway_dir * sway;
	VERTEX.y -= abs(sway) * 0.3;
	if (weather_ground.y > 0.0) {
		VERTEX.y *= tn_weather_grass_height();
	}
	// Uzakta tutamlar küçülerek zemine karışır.
	float fade = 1.0 - smoothstep(fade_start, fade_end, cam_dist);
	VERTEX *= fade;
	NORMAL = vec3(0.0, 1.0, 0.0);
	// Boyalı renk lekeleri (güneşli sarı-yeşil ve derin yeşil bölgeler) için tutamın leke değeri.
	if (instance_patches) {
		v_patch = INSTANCE_CUSTOM.a;
	} else {
		v_patch = tn_fbm2(root.xz * patch_scale, 3);
	}
}

void fragment() {
	float sunny = smoothstep(0.5, 0.72, v_patch) * sun_patches;
	float deep = (1.0 - smoothstep(0.28, 0.48, v_patch)) * deep_patches;
	vec3 tip = mix(mix(tip_color.rgb, sun_color.rgb, sunny), deep_color.rgb, deep * 0.6);
	vec3 mid = mix(mix(mid_color.rgb, mix(mid_color.rgb, sun_color.rgb, 0.45), sunny), deep_color.rgb, deep * 0.4);
	float g = smoothstep(gradient_start, gradient_end, v_h);
	vec3 col = mix(root_color.rgb, mid, smoothstep(0.0, 0.55, g));
	col = mix(col, tip, smoothstep(0.5, 1.0, g));
	col *= 1.0 + (v_tone - 0.5) * 2.0 * tone_variation;
	col = tn_weather_grass(col, v_h);
	ALBEDO = col;
	// İki yüzde de normal yukarı baksın (Godot iki yüzlü malzemede arka yüzün normalini çevirir).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float lambert = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float lit = mix(lambert, 1.0, light_flatness);
	if (LIGHT_IS_DIRECTIONAL) {
		// Yönlü ışıkta ATTENUATION düşen gölgedir: gölgede renk serin koyu yeşile döner.
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * mix(shadow_tint, vec3(1.0), ATTENUATION);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * mix(0.6, 1.0, lambert);
	}
}
