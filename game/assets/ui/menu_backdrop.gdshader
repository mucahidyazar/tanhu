shader_type canvas_item;
// Oyun menüsünün (kitabın) arkasındaki dünya (Tanhu 1): ekranın bulanık hâli (düşük bir mip
// seviyesi), temanın gece mürekkebine çekilir ve kenarlarda kararır.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 3.4;
uniform vec4 ink : source_color = vec4(0.012, 0.02, 0.035, 0.74);
uniform float vignette = 0.62;

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	c = mix(c, ink.rgb, ink.a);
	float d = length((UV - 0.5) * vec2(1.0, 0.82));
	c *= mix(1.0, 1.0 - vignette, smoothstep(0.25, 0.75, d));
	COLOR = vec4(c, 1.0);
}
