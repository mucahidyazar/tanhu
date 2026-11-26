// Yağış noktalarının çizimi (weather.md §9.4, §9.5): parçacığın dörtgeni kameraya döner, boyu dünyada sabittir (prototipin 34/derinlik
// kuralı: kar ≈6 cm), ekranda en çok point_max_px; boyalı süzgeç küçük parlak lekeyi korur, kar boyada leke olarak yaşar. Işık eklenmez:
// renk ışık düzeninden gelen lit_color'la çarpılır (gece kar söner). Sis elle uygulanır (uzaklıkla sönme). Derinlik sınaması açık,
// yazımı kapalı. CUSTOM'u parçacık gölgelendiricisi yazar (weather_precip.gdshader).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform vec3 snow_color : source_color = vec3(0.94, 0.96, 1.0);
// Sulu kar: gri, ıslak (0..1 karışım) ve Kara Boran'ın koyu gri-mavisi.
uniform vec3 wet_snow_color : source_color = vec3(0.66, 0.7, 0.74);
uniform float wet_snow = 0.0;
uniform vec3 dark_snow_color : source_color = vec3(0.32, 0.36, 0.44);
uniform float dark_snow = 0.0;
uniform vec3 hail_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 dust_color : source_color = vec3(0.7, 0.55, 0.36);
uniform vec3 splash_color : source_color = vec3(0.78, 0.84, 0.9);
// Işık düzeninin rengi (ortam + güneş payı; WeatherView yazar) ve görünümün kimlikle karışımı.
uniform vec3 lit_color : source_color = vec3(1.0);
uniform float alpha_k = 1.0;
// Ekranda en küçük ve en büyük boy (piksel, 1080p'ye göre).
uniform float point_min_px = 2.0;
uniform float point_max_px = 14.0;
// Elle sis: bu uzaklıklar arasında söner (m).
uniform float fog_near = 30.0;
uniform float fog_far = 140.0;
// Geliştirme: noktaları kırmızı ve büyük çizer (görünürlük denetimi).
uniform float debug_points = 0.0;

varying vec4 v_custom;
varying vec2 v_uv;
varying float v_fog;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec4 vc = VIEW_MATRIX * vec4(center, 1.0);
	float depth = max(-vc.z, 0.05);
	// Dünyadaki boyun ekrandaki pikseli (1080p ölçeğinde) kıstırılır.
	float px_per_m = PROJECTION_MATRIX[1][1] * 1080.0 / (2.0 * depth);
	float size_px = clamp(v_custom.y * px_per_m, point_min_px, point_max_px);
	float size = size_px / px_per_m;
	if (v_custom.x < -0.5) {
		size = 0.0;
	}
	if (debug_points > 0.0) {
		size = 8.0 / px_per_m;
	}
	vec2 quad = VERTEX.xy;
	// Sıçrama tacı yere yatık, açılarak büyür.
	if (v_custom.x > 2.5 && v_custom.x < 3.5) {
		size *= mix(0.4, 1.2, v_custom.w);
	}
	v_uv = quad * 2.0;
	VERTEX = (vc + vec4(quad * size, 0.0, 0.0)).xyz;
	v_fog = smoothstep(fog_near, fog_far, depth);
}

void fragment() {
	float r = length(v_uv);
	float kind = v_custom.x;
	vec3 col;
	float a;
	if (kind < 0.5) {
		col = mix(mix(snow_color, wet_snow_color, wet_snow), dark_snow_color, dark_snow);
		a = 1.0 - smoothstep(0.45, 1.0, r);
	} else if (kind < 1.5) {
		col = hail_color;
		a = 1.0 - smoothstep(0.6, 0.9, r);
	} else if (kind < 2.5) {
		col = dust_color;
		a = (1.0 - smoothstep(0.2, 1.0, r)) * 0.4;
	} else if (kind < 3.5) {
		// Yağmur sıçraması: 0,25 sn'de açılan taç (halka), söner.
		float ring = 1.0 - smoothstep(0.12, 0.3, abs(r - mix(0.3, 0.85, v_custom.w)));
		col = splash_color;
		a = ring * (1.0 - v_custom.w) * 0.85;
	} else {
		col = hail_color;
		a = (1.0 - smoothstep(0.55, 0.9, r)) * (1.0 - v_custom.w * 0.6);
	}
	a *= v_custom.z * alpha_k * (1.0 - v_fog);
	if (debug_points > 0.0) {
		col = vec3(1.0, 0.0, 0.0);
		a = 1.0;
	}
	if (a <= 0.004) {
		discard;
	}
	ALBEDO = col * lit_color;
	ALPHA = a;
}
