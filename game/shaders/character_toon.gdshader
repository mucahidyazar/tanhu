// Meshy karakter modelleri için "After the Wind" tarzı cel (anime) malzeme.
//
// - Modelin elle boyanmış dokusu (albedo_texture) korunur.
// - Işık iki tonludur: aydınlık taraf dokunun kendi rengi, gölge tarafı sabit bir oranda (shadow_level)
//   hafif soğuk tonlu (shadow_tint) koyulaşır. Işık ne kadar güçlü olursa olsun bu oran değişmez;
//   böylece beyazlar patlamaz, renkler referanstaki gibi düz ve temiz kalır.
// - Kontur: yüzey kameraya yan döndükçe koyulaşan ince mürekkep çizgisi (ink_*).
// - Karakter oluşturucu için bölge maskesi (region_mask) ile renk değiştirme:
//   R = saç, G = ten, B = göz bebeği. Hedef rengin alfası 0 ise ("Doğal") bölge değişmez.
// - Kılık maskesi (dye_mask; K58, tools/bake_dye_mask.py): R = pelerin, G = zırh levhası, B = gömlek; dye_mask2'nin R'si
//   kuşak ve şeritler. Pelerin rengi tek yerden gelir (CharacterOptions.cape_tint); kılığın renkleri pelerine dokunmaz.
//   Bölgenin ortalama pikseli hedef rengin kendisi olur (*_lum bölgenin doğrusal ortalama parlaklığıdır); pelerinde
//   gölge oranı 0,6–1,4'e kıstırılır: kıvrımın gölgesi kalır, boncukta görülen renk ekrana gelir
//   (sanat-animasyon.md öneri 3). Hedefin alfası 0 ise bölge modelin kendi rengindedir.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;
// Karakterin kapladığı pikselleri işaretle; kontur yalnızca bu alanın DIŞINA çizilir.
stencil_mode write, compare_always, 128;

#include "res://shaders/include/noise.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform sampler2D region_mask : hint_default_black, filter_linear_mipmap, repeat_enable;
// Ek maske: R = göz akı.
uniform sampler2D region_mask2 : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool use_region_mask = false;
uniform vec4 hair_color : source_color = vec4(0.0);
uniform vec4 skin_color : source_color = vec4(0.0);
uniform vec4 eye_color : source_color = vec4(0.0);
uniform vec3 hair_base : source_color = vec3(0.5);
uniform vec3 skin_base : source_color = vec3(0.9, 0.72, 0.6);
uniform vec3 eye_base : source_color = vec3(0.2);
// Saç bölgesinin doğal tonu (beyaz = dokunun kendi rengi). Ör. bembeyaz saçı referanstaki bej-griye çeker.
uniform vec3 hair_natural_tint : source_color = vec3(1.0);

group_uniforms dye;
uniform sampler2D dye_mask : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D dye_mask2 : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool use_dye_mask = false;
uniform vec4 cape_color : source_color = vec4(0.0);
uniform vec4 plate_color : source_color = vec4(0.0);
uniform vec4 tunic_color : source_color = vec4(0.0);
uniform vec4 trim_color : source_color = vec4(0.0);
uniform float cape_lum = 0.058;
uniform float plate_lum = 0.058;
uniform float tunic_lum = 0.317;
uniform float trim_lum = 0.055;
// Pelerinin gölge oranı sınırları (bölgenin ortalama parlaklığına göre).
uniform vec2 cape_shade_range = vec2(0.6, 1.4);
group_uniforms;

group_uniforms folk;
// Folk'un giysi boyası (scripts/character/folk.gd; data/character/folk.json «models»): bölge maskesinde saç, ten ve göz olmayan
// piksel giysidir. Giysinin ortalama pikseli (cloth_lum, tools/bake_folk_cloth.py) hedef renk olur, kıvrımın gölgesi kalır; boya
// parlaklık bandında (cloth_band) yumuşakça girer: koyu deri, kuşak ve çizme doğal renginde kalır. Alfa boyanın payıdır, 0 ise boya yok.
uniform vec4 cloth_color : source_color = vec4(0.0);
uniform float cloth_lum = 0.1;
uniform vec2 cloth_band = vec2(0.03, 0.08);
group_uniforms;

group_uniforms cel;
// Gölge tarafının aydınlık tarafa oranı (0 = siyah gölge, 1 = gölgesiz).
uniform float shadow_level : hint_range(0.0, 1.0) = 0.78;
uniform vec3 shadow_tint : source_color = vec3(1.0, 0.97, 0.9);
// Aydınlık/gölge sınırının konumu ve yumuşaklığı (N·L cinsinden).
uniform float terminator = 0.05;
uniform float terminator_softness : hint_range(0.0, 0.6) = 0.14;
// Aydınlık tarafta da biçimi hissettiren çok hafif yumuşak geçiş (boyalı hacim hissi).
uniform float form_shading : hint_range(0.0, 0.5) = 0.12;
uniform float brush_strength : hint_range(0.0, 0.4) = 0.025;
group_uniforms ink;
// Silüet ve saç tutamı kenarlarında ince "mürekkep" çizgisi (yüzey kameraya yan döndükçe koyulaşır).
uniform vec4 ink_color : source_color = vec4(0.25, 0.18, 0.15, 1.0);
uniform float ink_strength : hint_range(0.0, 1.0) = 0.6;
uniform float ink_width : hint_range(0.0, 0.6) = 0.18;
uniform float ink_sharpness : hint_range(0.0, 1.0) = 0.6;
group_uniforms;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Dokunun ışık/gölge ayrıntısını koruyarak bölgeyi yeni renge boyar.
vec3 recolor(vec3 col, vec3 base, vec4 target, float mask) {
	if (target.a <= 0.0 || mask <= 0.0) {
		return col;
	}
	float shade = clamp(lum(col) / max(lum(base), 0.04), 0.0, 2.2);
	vec3 painted = target.rgb * shade;
	return mix(col, painted, clamp(mask * target.a, 0.0, 1.0));
}

// Kılık bölgesini boyar: gölge oranı bölgenin ortalama doğrusal parlaklığına göre, verilen sınırlar içinde.
vec3 dye(vec3 col, float base_lum, vec4 target, float mask, vec2 shade_range) {
	if (target.a <= 0.0 || mask <= 0.0) {
		return col;
	}
	float shade = clamp(lum(col) / max(base_lum, 0.004), shade_range.x, shade_range.y);
	return mix(col, target.rgb * shade, clamp(mask * target.a, 0.0, 1.0));
}

void fragment() {
	vec3 col = texture(albedo_texture, UV).rgb * albedo_tint.rgb;
	if (use_region_mask) {
		vec3 m = texture(region_mask, UV).rgb;
		// Göz akı yok: o pikseller her zaman ten rengine boyanır (seçili ten ya da dokunun teni).
		float sclera = texture(region_mask2, UV).r;
		col = mix(col, skin_color.a > 0.0 ? skin_color.rgb : skin_base, sclera);
		col *= mix(vec3(1.0), hair_natural_tint, m.r);
		col = recolor(col, hair_base, hair_color, m.r);
		col = recolor(col, skin_base, skin_color, m.g);
		// Gözde rengin tamamı değil bir kısmı uygulanır: göz bebeği koyu ve parlak kalsın.
		col = recolor(col, eye_base, vec4(eye_color.rgb * 0.8, eye_color.a), m.b * 0.75);
		if (cloth_color.a > 0.0) {
			float l = lum(col);
			float cloth = (1.0 - clamp(m.r + m.g + m.b, 0.0, 1.0)) * smoothstep(cloth_band.x, cloth_band.y, l) * cloth_color.a;
			col = mix(col, cloth_color.rgb * clamp(l / max(cloth_lum, 0.004), 0.0, 2.2), cloth);
		}
	}
	if (use_dye_mask) {
		vec3 d = texture(dye_mask, UV).rgb;
		float trim = texture(dye_mask2, UV).r;
		col = dye(col, cape_lum, cape_color, d.r, cape_shade_range);
		col = dye(col, plate_lum, plate_color, d.g, vec2(0.0, 2.2));
		col = dye(col, tunic_lum, tunic_color, d.b, vec2(0.0, 2.2));
		col = dye(col, trim_lum, trim_color, trim, vec2(0.0, 2.2));
	}
	float n = tn_noise3(v_world_pos * 6.0);
	col *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float ink = 1.0 - smoothstep(ink_width * ink_sharpness, ink_width, facing);
	ALBEDO = mix(col, ink_color.rgb, ink * ink_strength);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	EMISSION = emission_color.rgb * emission_energy;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(terminator - terminator_softness, terminator + terminator_softness, ndl);
	vec3 shade;
	float form = 1.0 - form_shading * (1.0 - smoothstep(0.0, 1.0, ndl));
	if (LIGHT_IS_DIRECTIONAL) {
		// Yönlü ışıkta ATTENUATION gölge bilgisidir: düşen gölgeler de cel gölge tonuna döner.
		band *= ATTENUATION;
		shade = mix(shadow_tint * shadow_level, vec3(form), band);
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * shade;
	} else {
		// Nokta ışıklarda (ateş, fener) ATTENUATION mesafeyle sönümlenmedir; rengi ılık bir dolgu gibi ekle.
		shade = mix(shadow_tint * shadow_level, vec3(1.0), band);
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * shade;
	}
}
