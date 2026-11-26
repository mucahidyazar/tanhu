// Yıldırım şeridi (weather.md §9.6): bulut tabanından iniş noktasına orta nokta kaydırmalı çizgi; kameraya dönük şerit (CPU vuruş
// başına bir kez kurar: 32 parçalık gövde + 2 dal). Toplamalı, sis kapalı, derinlik sınaması açık, yazımı kapalı. Renk (6; 6,6; 8) × f:
// HDR rengi parlama eşiğini aşar. Köşe rengi alfası şeridin kenarıdır (0 kenar, 1 öz); UV.x gövde boyunca konum.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 bolt_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float energy = 6.0;
// Nabız (0..1; dönüş vuruşlarıyla titrer) ve görünümün kimlikle karışımı.
uniform float flash = 0.0;

void fragment() {
	float core = 1.0 - abs(UV.y * 2.0 - 1.0);
	float glow = pow(clamp(core, 0.0, 1.0), 1.5);
	vec3 c = bolt_color * vec3(1.0, 1.1, 1.333) * energy * flash * glow * COLOR.a;
	ALBEDO = c;
}
