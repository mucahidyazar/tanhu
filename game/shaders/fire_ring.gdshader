// Ateşin yer halkası (survival.md §2.3, §2.1, §3; FireView, SurvivalLayer): yere yatık tek dörtgen, ışıksız, derinlik yazmaz.
//   mode 0  yay: kalan yakıt (fill: ateşin doluluğu; renk evrenin), yer seçiminin önizlemesi (fill 1; altın geçerli, kızıl geçersiz) ve
//           işin ilerlemesi (kurma, söndürme, Küle Yatır, yüzme)
//   mode 1  Tam Vuruş: dış halka k ile hedef banda kapanır (k 1'de temas), bant pencerenin yarıçapıdır; flash basışın ışıması
// Dörtgenin UV'si 0..1; halkanın yarıçapı ve kalınlığı UV'nin yarısına oranla. Ağın kendisi PlaneMesh'tir (XZ düzlemi, yukarı bakar).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform int mode = 0;
uniform vec4 color : source_color = vec4(1.0, 0.72, 0.32, 1.0);
uniform vec4 track : source_color = vec4(0.08, 0.06, 0.05, 0.42);
uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float radius = 0.82;
uniform float width = 0.07;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
// Tam Vuruş: k (0 açılış, 1 temas), bant (pencerenin yarıçap karşılığı), flash (1 → 0 sönen ışıma), hit (1 tam, 0 kaçış).
uniform float k = 0.0;
uniform float band = 0.05;
uniform float flash = 0.0;
uniform float hit = 1.0;

float ring_at(float d, float r, float w) {
	return 1.0 - smoothstep(w * 0.5 - 0.012, w * 0.5 + 0.012, abs(d - r));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = length(q);
	vec3 col = vec3(0.0);
	float a = 0.0;
	if (mode == 0) {
		float ring = ring_at(d, radius, width);
		// Saat yönünde, kuzeyden (−Z, UV'nin üstü) başlar.
		float ang = atan(q.x, -q.y);
		float a01 = fract(ang / 6.2831853 + 1.0);
		float on = step(a01, fill + 0.0005);
		vec4 c = mix(track, color, on);
		col = c.rgb;
		a = ring * c.a;
	} else {
		float rb = radius * 0.6;
		float r = mix(radius * 1.12, rb, clamp(k, 0.0, 1.6));
		float bnd = 1.0 - smoothstep(band - 0.004, band + 0.012, abs(d - rb));
		float outer = ring_at(d, r, width * 0.7);
		float near = 1.0 - smoothstep(0.0, 0.25, abs(r - rb));
		vec3 warm = color.rgb;
		col = warm * (bnd * (0.35 + 0.45 * near)) + warm * outer * 1.25;
		vec3 fl = mix(vec3(0.55, 0.5, 0.45), vec3(1.6, 1.15, 0.4), hit);
		col += fl * flash * ring_at(d, rb, 0.1) * 1.6;
		a = clamp(max(max(bnd * 0.5, outer), flash * ring_at(d, rb, 0.12)), 0.0, 1.0);
	}
	ALBEDO = col;
	ALPHA = a * alpha;
}
