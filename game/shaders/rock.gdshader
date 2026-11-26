// Yumuşak hatlı kaya: açık gri-bej taş, üst yüzeylerde gürültüyle dağılan yosun.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"

uniform vec4 rock_color : source_color = vec4(0.7, 0.72, 0.75, 1.0);
uniform vec4 rock_shadow : source_color = vec4(0.46, 0.48, 0.54, 1.0);
uniform vec4 moss_color : source_color = vec4(0.38, 0.52, 0.18, 1.0);
uniform vec4 moss_dark : source_color = vec4(0.22, 0.34, 0.13, 1.0);
uniform float moss_amount : hint_range(0.0, 1.0) = 0.5;
uniform float soot : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float n = tn_noise3(v_world_pos * 1.6);
	float n2 = tn_noise3(v_world_pos * 5.5);
	vec3 rock = mix(rock_shadow.rgb, rock_color.rgb, clamp(n * 0.6 + n2 * 0.4 + 0.1, 0.0, 1.0));
	float up = v_world_normal.y;
	float moss = smoothstep(1.0 - moss_amount, 1.0 - moss_amount + 0.18, up + (n - 0.5) * 0.55 + (n2 - 0.5) * 0.15);
	vec3 col = mix(rock, mix(moss_dark.rgb, moss_color.rgb, n2), moss * step(0.001, moss_amount));
	col *= 1.0 - soot * (0.6 - n * 0.2);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
