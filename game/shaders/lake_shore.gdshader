// Kıyıya vuran küçük dalga (E21, K110; Kamışlı Göl): kıyı çizgisi boyunca ince şerit (UV.y: 0 su yanı, 1 kara yanı). Köpük çizgisi
// zamanla karaya doğru yürür ve söner; şeridin boyunca evre kayar (dalga kıyıyı aynı anda yalamaz). Su gölgelendiricisinin (water.gdshader)
// kıyı açıklığının üstündedir.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

#include "res://shaders/include/world_time.gdshaderinc"

uniform vec4 foam_color : source_color = vec4(0.94, 0.92, 0.84, 1.0);
uniform float period = 3.4;
uniform float strength = 0.55;

void fragment() {
	float phase = fract(tn_time() / period + UV.x * 0.083);
	float front = mix(0.1, 0.85, phase);
	float crest = 1.0 - smoothstep(0.0, 0.09, abs(UV.y - front));
	float wash = smoothstep(front, front - 0.35, UV.y) * 0.25;
	float life = sin(phase * 3.14159);
	ALBEDO = foam_color.rgb;
	ALPHA = clamp((crest + wash) * life * strength * smoothstep(0.0, 0.08, UV.y), 0.0, 1.0);
}
