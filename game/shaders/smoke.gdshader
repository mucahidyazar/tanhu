// Yurt dumanı: tacından yükselen ince, yumuşak bir duman sütunu (4. referanstaki gibi).
// Tek bir dörtgen düşey eksen etrafında kameraya döner; duman, üst üste binen ve yukarı doğru akan yumuşak
// tutamlarla (puf) ve onların kenarını bozan gürültüyle çizilir. Durumsuzdur (yalnızca zamana, tn_time()'a bağlıdır): yavaş
// ilk kareler ya da takılmalar onu bir topa toplayamaz. Sütun yukarı doğru genişler, rüzgârla hafifçe bir yana
// kıvrılır ve tepede silinir.
// Dörtgenin kökü dumanın çıktığı noktanın "sink" kadar altındadır (duman tacın içinden çıkar; UV.y = 1 kök,
// 0 tepe; bkz. Fx.smoke).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, world_vertex_coords;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/world_time.gdshaderinc"

uniform vec4 smoke_color : source_color = vec4(0.74, 0.74, 0.88, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.6;
// Dörtgenin ölçüsü (metre): genişlik, yükseklik (Fx.smoke ile aynı olmalı).
uniform vec2 plume_size = vec2(1.2, 2.6);
// Taçtaki ve tepedeki tutam yarıçapı (metre).
uniform float base_width = 0.13;
uniform float top_width = 0.5;
// Tutamların dikey aralığı (metre).
uniform float puff_spacing = 0.26;
// Dörtgenin düğümün altına uzandığı pay (metre): duman tacın içinden çıkıyor gibi görünür.
uniform float sink = 0.3;
// Rüzgârın dumanı tepede sürüklediği yatay uzaklık (dünya XZ, metre).
uniform vec2 wind = vec2(-0.55, -0.15);
// Duman tutamlarının yükselme hızı (m/sn).
uniform float rise_speed = 0.32;

varying vec2 v_local;
varying float v_drift;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec2 to_cam = CAMERA_POSITION_WORLD.xz - origin.xz;
	vec2 f = to_cam / max(length(to_cam), 0.0001);
	vec3 right = vec3(f.y, 0.0, -f.x);
	vec2 local = vec2((UV.x - 0.5) * plume_size.x, (1.0 - UV.y) * plume_size.y);
	// Rüzgârın ekranda görünen (kameraya dik) bileşeni; dörtgen onunla yukarı doğru eğilir.
	v_drift = dot(wind, right.xz);
	v_local = local;
	VERTEX = origin + right * (local.x + v_drift * local.y / plume_size.y) + vec3(0.0, local.y - sink, 0.0);
}

// Tutamın yatay ekseni: rüzgârla eğri bir yay (h: 0 taç, 1 tepe) ve tutamdan tutama sağa sola sapma.
float puff_axis(float h, float id, float r, float drift) {
	return drift * pow(h, 1.6) + (tn_hash12(vec2(id, 3.1)) - 0.5) * 0.9 * r;
}

void fragment() {
	float hn = clamp(v_local.y / plume_size.y, 0.0, 1.0);
	float t = tn_time() * rise_speed;
	// Dünya uzayındaki yatay konum (dörtgen rüzgârla doğrusal eğilir; bkz. vertex()).
	float x = v_local.x + v_drift * hn;
	// Üst üste binen, yukarı akan yuvarlak tutamlar: en yakın beş tutamın birleşimi. Önde (sonra) gelen tutam
	// arkadakinin ışığını örter; her tutamın üstü açık, altı koyudur (boyalı duman).
	float k = floor((v_local.y + t) / puff_spacing);
	float density = 0.0;
	float shade = 0.5;
	for (int j = -2; j <= 2; j++) {
		float id = k + float(j);
		float cy = id * puff_spacing - t;
		float h = clamp(cy / plume_size.y, 0.0, 1.0);
		float r = mix(base_width, top_width, pow(h, 0.75)) * (0.6 + 0.8 * tn_hash12(vec2(id, 1.7)));
		// Tacın hemen üstünde tutamlar dikine uzar ve birbirine karışır: dip, üst üste dizili ayrı toplar
		// ("inci dizisi") değil, ince ve sürekli bir sütun olarak çıkar; yukarıda yuvarlak tutamlara açılır.
		float stretch = mix(0.4, 1.1, smoothstep(0.08, 0.4, h));
		vec2 d = vec2(x - puff_axis(h, id, r, v_drift), (v_local.y - cy) * stretch) / r;
		float f = 1.0 - smoothstep(0.5, 1.0, length(d));
		shade = mix(shade, clamp(dot(d, vec2(0.45, 0.9)) * 0.5 + 0.55, 0.0, 1.0), f);
		density = 1.0 - (1.0 - density) * (1.0 - f);
	}
	// Kenarları kabaran, içi dalgalanan duman.
	float wisps = tn_fbm2(vec2(x * 2.4, v_local.y * 1.5 - t * 1.2), 3);
	density *= smoothstep(0.2, 0.55, wisps + density * 0.3);
	// Taçtan ince ve soluk başla (referanstaki gibi baca ağzında duman incedir), yukarıda incelip silin.
	float rise = mix(0.4, 1.0, smoothstep(sink / plume_size.y, sink / plume_size.y + 0.25, hn));
	float fade = (1.0 - smoothstep(0.3, 1.0, hn)) * rise;
	ALBEDO = smoke_color.rgb * (0.74 + 0.32 * shade);
	ALPHA = clamp(density * fade * mix(1.0, 0.55, hn) * opacity, 0.0, 1.0);
}
