// "After the Wind" tarzı kaya: açık krem taş, üstünde boyanmış açık lekeler, küçük koyu benekler
// ve sarı-yeşil yosun (üst yüzeylerde ve kayanın ortasındaki çıkıntı bandında).
// Işık iki tonludur: aydınlık taraf taşın kendi rengi, gölge tarafı sıcak ve hafif koyu.
// Desenler dünya uzayındadır: kaya hangi oranda ölçeklenirse ölçeklensin lekeler uzamaz (kayalar sabittir).
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/noise.gdshaderinc"

group_uniforms stone;
uniform vec4 rock_color : source_color = vec4(0.95, 0.83, 0.54, 1.0);
uniform vec4 blotch_color : source_color = vec4(0.99, 0.96, 0.7, 1.0);
uniform vec4 speck_color : source_color = vec4(0.62, 0.5, 0.3, 1.0);
uniform float blotch_scale = 1.35;
uniform float blotch_amount : hint_range(0.0, 1.0) = 0.38;
uniform float speck_amount : hint_range(0.0, 1.0) = 0.35;
group_uniforms moss;
uniform vec4 moss_color : source_color = vec4(0.6, 0.58, 0.11, 1.0);
uniform vec4 moss_light : source_color = vec4(0.9, 0.82, 0.38, 1.0);
uniform float moss_amount : hint_range(0.0, 1.0) = 0.7;
// Kayanın alt kısmındaki yosun kuşağının yüksekliği (UV.y; 0 = yok). Üstteki büyük kayalarda kullanılır.
uniform float moss_base : hint_range(0.0, 1.0) = 0.0;
// Kaya yüksekliğinde (UV.y, 0 taban – 1 tepe) yosun bandının konumu; < 0 ise bant yok.
uniform float moss_band = -1.0;
uniform float moss_band_width = 0.1;
group_uniforms lighting;
uniform float shadow_level : hint_range(0.0, 1.0) = 0.58;
// Yosunlu yerlerde gölge daha az koyulaşır (yosun ışığı yumuşak dağıtır; referanstaki parlak yosun).
uniform float moss_shadow_lift : hint_range(0.0, 1.0) = 0.2;
uniform vec3 shadow_tint : source_color = vec3(1.0, 0.97, 1.0);
uniform float terminator_softness : hint_range(0.0, 1.0) = 0.35;
group_uniforms;

varying vec3 v_obj_pos;
varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_height;
varying float v_moss;

void vertex() {
	v_obj_pos = VERTEX;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_height = UV.y;
}

void fragment() {
	// Boyalı açık lekeler: bükülmüş hücresel gürültünün eşiklenmesi (kırık kenarlı yamalar).
	vec3 q = v_world_pos * blotch_scale;
	q += vec3(tn_fbm3(q * 0.9, 2), tn_fbm3(q * 0.9 + 7.1, 2), tn_fbm3(q * 0.9 + 3.7, 2)) * 0.9;
	float cell = tn_worley3(q);
	float blot = 1.0 - smoothstep(blotch_amount - 0.06, blotch_amount + 0.03, cell);
	vec3 col = mix(rock_color.rgb, blotch_color.rgb, blot);
	// Küçük koyu benekler.
	float speck = 1.0 - smoothstep(0.05, 0.09, tn_worley3(q * 3.3 + 11.0));
	col = mix(col, speck_color.rgb, speck * speck_amount);
	// Yosun: yukarı bakan yüzeyler + orta bant; kenarları gürültüyle tırtıklı.
	float n = tn_fbm3(v_world_pos * 1.4, 3);
	float n2 = tn_noise3(v_world_pos * 6.0);
	float up = smoothstep(0.5, 0.8, v_world_normal.y + (n - 0.5) * 0.7);
	float band = 0.0;
	if (moss_band >= 0.0) {
		band = 1.0 - smoothstep(moss_band_width * 0.5, moss_band_width, abs(v_height - moss_band + (n - 0.5) * 0.18));
	}
	float base = moss_base > 0.0 ? 1.0 - smoothstep(moss_base * 0.6, moss_base, v_height + (n - 0.5) * 0.2) : 0.0;
	float moss = clamp(max(max(up, band), base) * (moss_amount * 2.0), 0.0, 1.0);
	// Yosun düz bir bant olmasın: büyük ölçekli yama gürültüsüyle bölünür, kenarı tırtıklıdır.
	float patches = smoothstep(0.32, 0.58, tn_fbm3(v_world_pos * 2.1 + 4.3, 3));
	moss = smoothstep(0.35, 0.65, moss * mix(0.35, 1.0, patches) + (n2 - 0.5) * 0.35);
	col = mix(col, mix(moss_color.rgb, moss_light.rgb, n2 * 0.8), moss);
	v_moss = moss;
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-terminator_softness, terminator_softness, ndl);
	float level = mix(shadow_level, 1.0, v_moss * moss_shadow_lift);
	if (LIGHT_IS_DIRECTIONAL) {
		band *= ATTENUATION;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(shadow_tint * level, vec3(1.0), band);
	} else {
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * mix(shadow_tint * level, vec3(1.0), band);
	}
}
