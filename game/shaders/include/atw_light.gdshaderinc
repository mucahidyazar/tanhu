// "After the Wind" cel (iki tonlu) ışık modeli — tüm AtW malzemelerinin ortak ışığı.
//
// Karakter malzemesinde (character_toon) ve çevre laboratuvarında (atw_grass / atw_rock) referans
// görüntülere ölçülerek bulunan kurallar:
//   - Aydınlık taraf DÜZDÜR: yüzey kendi rengindedir, ışığa göre kademeli koyulaşmaz (boyalı düz alanlar).
//   - Gölge tarafı sabit bir oranda (atw_shadow_level) koyulaşır ve hafif renklenir (atw_shadow_tint);
//     düşen gölgeler de aynı gölge tonuna döner. Saf siyah yoktur.
//   - Aydınlık/gölge sınırı (terminator) yumuşak bir çizgidir (atw_softness).
//   - atw_form: aydınlık tarafta biçimi hissettiren çok hafif yumuşak geçiş (0 = tamamen düz).
//   - Nokta ışıklar (kamp ateşi, fener) yumuşak "sarılmış" ışıktır: arkaya doğru da biraz sızar.
//   - Speküler parlama yoktur (malzeme render_mode'una specular_disabled eklenmelidir).
//
// Kullanım: shader'da   #include "res://shaders/include/atw_light.gdshaderinc"
// Bu dosya light() fonksiyonunu tanımlar; dahil eden shader ayrıca light() yazmamalıdır.
// Malzeme başına ayar için uniform'lar ShaderMaterial.set_shader_parameter ile değiştirilir.

group_uniforms atw_light;
uniform float atw_shadow_level : hint_range(0.0, 1.0) = 0.7;
uniform vec3 atw_shadow_tint : source_color = vec3(0.96, 0.94, 1.0);
uniform float atw_terminator : hint_range(-1.0, 1.0) = 0.0;
uniform float atw_softness : hint_range(0.01, 1.0) = 0.22;
uniform float atw_form : hint_range(0.0, 0.5) = 0.08;
// Nokta ışıkların yüzeyin arkasına sarılma miktarı (0 = Lambert, 1 = tamamen sarılmış).
uniform float atw_point_wrap : hint_range(0.0, 1.0) = 0.5;
group_uniforms;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(atw_terminator - atw_softness, atw_terminator + atw_softness, ndl);
	vec3 dark = atw_shadow_tint * atw_shadow_level;
	if (LIGHT_IS_DIRECTIONAL) {
		// Yönlü ışıkta ATTENUATION düşen gölgedir.
		band *= ATTENUATION;
		float form = 1.0 - atw_form * (1.0 - smoothstep(0.0, 1.0, ndl));
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(dark, vec3(form), band);
	} else {
		// Nokta ışıkta ATTENUATION mesafe sönümüdür (ve varsa gölge).
		float wrap = clamp((ndl + atw_point_wrap) / (1.0 + atw_point_wrap), 0.0, 1.0);
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * ATTENUATION * mix(dark, vec3(1.0), smoothstep(0.0, 0.6, wrap)) * wrap;
	}
}
