// Suda halka (E21, K110; Kamışlı Göl): dalış, yüzme, kıyıda içen koyun, ördek ve balığın bıraktığı genişleyen halka. Tek dörtgen, örnek
// başına INSTANCE_CUSTOM: r yaş (0..1), g gücü (0..1). Halka yaşla açılır ve söner; ince parlak çizgi, içinde soluk ikinci halka.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

uniform vec4 ring_color : source_color = vec4(0.92, 0.94, 0.9, 1.0);
uniform float width = 0.07;

varying float v_age;
varying float v_power;

void vertex() {
	v_age = INSTANCE_CUSTOM.r;
	v_power = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float edge = mix(0.25, 0.98, sqrt(v_age));
	float ring = 1.0 - smoothstep(0.0, width, abs(r - edge));
	float inner = (1.0 - smoothstep(0.0, width * 1.6, abs(r - edge * 0.62))) * 0.45;
	float fade = (1.0 - v_age) * (1.0 - v_age) * v_power;
	ALBEDO = ring_color.rgb;
	ALPHA = clamp((ring + inner) * fade * 0.85, 0.0, 1.0) * step(r, 1.0);
}
