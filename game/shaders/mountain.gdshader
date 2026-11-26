// Uzak dağlar: mavi-mor kaya, eteklerde koyu orman, zirvelerde kar.
//
// Dağlar sahnenin gerçek ışığını değil kendi "ressam ışığını" kullanır (unshaded):
// ışık ayın olduğu sağ üstten gelir; sağa bakan yamaçlar aydınlık, sola bakanlar mavi gölgede kalır.
// Böylece kamera tarafından gelen ay ışığı dağları düzleştirmez.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/include/noise.gdshaderinc"

uniform vec4 rock_low : source_color = vec4(0.1, 0.13, 0.27, 1.0);
uniform vec4 rock_high : source_color = vec4(0.25, 0.29, 0.5, 1.0);
uniform vec4 forest_color : source_color = vec4(0.06, 0.13, 0.17, 1.0);
uniform vec4 snow_color : source_color = vec4(0.88, 0.92, 1.0, 1.0);
uniform float snow_line = 205.0;
uniform float forest_line = 45.0;
// Ressam ışığı: yön ve renkler.
uniform vec3 paint_light_direction = vec3(0.55, 0.6, -0.35);
uniform vec3 paint_light_color : source_color = vec3(0.95, 0.97, 1.05);
uniform vec3 paint_shadow_color : source_color = vec3(0.34, 0.4, 0.7);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float h = v_world_pos.y;
	float n = tn_fbm2(v_world_pos.xz * 0.004, 4);
	float n2 = tn_noise2(v_world_pos.xz * 0.03);
	vec3 nrm = normalize(v_world_normal);
	float up = nrm.y;

	vec3 col = mix(rock_low.rgb, rock_high.rgb, clamp(smoothstep(-30.0, 420.0, h) * 0.75 + n * 0.35, 0.0, 1.0));
	float forest = 1.0 - smoothstep(forest_line - 25.0, forest_line + 25.0, h + (n - 0.5) * 70.0);
	col = mix(col, forest_color.rgb, forest * smoothstep(0.5, 0.75, up));

	float snow_h = smoothstep(snow_line - 45.0, snow_line + 30.0, h + (n - 0.5) * 140.0 + (n2 - 0.5) * 35.0);
	float flatness = smoothstep(0.3, 0.68, up + (n2 - 0.5) * 0.35);
	float snow = clamp(snow_h * mix(0.25, 1.0, flatness), 0.0, 1.0);
	col = mix(col, snow_color.rgb, snow);

	// Yumuşak, hafif kademeli ressam ışığı.
	float ndl = dot(nrm, normalize(paint_light_direction));
	float lit = smoothstep(-0.15, 0.45, ndl);
	lit = mix(lit, smoothstep(0.4, 0.6, lit), 0.35);
	vec3 light = mix(paint_shadow_color, paint_light_color, lit);
	ALBEDO = col * light;
}
