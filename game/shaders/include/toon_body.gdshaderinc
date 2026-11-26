// soft_toon, soft_toon_double ve soft_toon_cut shader'larının ortak gövdesi.
// (render_mode dışında her şey burada; böylece varyantlar aynı görünür. CUTAWAY tanımlıysa otağ kesiti uygulanır.)

#include "res://shaders/include/noise.gdshaderinc"
#include "res://shaders/include/soft_light.gdshaderinc"
#ifdef CUTAWAY
#include "res://shaders/include/cutaway.gdshaderinc"
#endif

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
// Yerel Y eksenine göre alttan üste renk geçişi (0 = kapalı).
uniform vec4 albedo_bottom : source_color = vec4(1.0);
uniform float gradient_height = 0.0;
uniform float gradient_offset = 0.0;
uniform bool use_vertex_color = false;
// Fırça darbesi hissi veren düşük frekanslı renk lekeleri.
uniform float brush_strength : hint_range(0.0, 0.6) = 0.08;
uniform float brush_scale = 4.0;
// UV.y boyunca ince koyu çizgiler (tahta aralıkları, fıçı çemberleri).
uniform float stripe_count = 0.0;
uniform float stripe_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;

varying vec3 v_world_pos;
varying vec3 v_local_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_local_pos = VERTEX;
}

void fragment() {
#ifdef CUTAWAY
	if (cutaway_hidden(v_world_pos)) {
		discard;
	}
#endif
	vec3 col = albedo.rgb;
	if (use_vertex_color) {
		col *= COLOR.rgb;
	}
	if (gradient_height > 0.0) {
		float g = clamp((v_local_pos.y - gradient_offset) / gradient_height, 0.0, 1.0);
		col *= mix(albedo_bottom.rgb, vec3(1.0), g);
	}
	float n = tn_noise3(v_world_pos * brush_scale) * 0.6 + tn_noise3(v_world_pos * brush_scale * 3.1) * 0.4;
	col *= 1.0 + (n - 0.5) * 2.0 * brush_strength;
	if (stripe_count > 0.0) {
		float s = abs(fract(UV.y * stripe_count) - 0.5) * 2.0;
		col *= 1.0 - smoothstep(0.82, 1.0, s) * stripe_strength;
	}
#ifdef CUTAWAY
	col *= 1.0 - 0.45 * cutaway_rim(v_world_pos);
#endif
	ALBEDO = col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	EMISSION = emission_color.rgb * emission_energy;
}
