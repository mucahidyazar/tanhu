// En basit AtW malzemesi: düz renk + AtW cel ışığı (atw_light). Hızlı denemeler ve basit nesneler için.
shader_type spatial;
render_mode cull_back, specular_disabled;

#include "res://shaders/include/atw_light.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
