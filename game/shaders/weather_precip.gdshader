// Yağış noktaları (weather.md §9.4, §9.5; godot.md §3 «yağış GPUParticles3D»): kar, yoğun kar, tipi, Kara Boran, sulu kar, dolu ve toz
// tek parçacık sisteminde, sıçrama ve dolu sekmesi aynı sistemin son 192 noktası (aynı geometri, aynı çizim).
//
// Konum tohumdan ve hava saatinden çıkar, dünya kutusunda sarılır: kamera kayınca noktalar yerinde kalır, yalnız kutunun kenarında
// döner. Kayma CPU'da sarılarak verilir (fall_off[], kutu boyunun katında): uzun oturumda kayan değer büyümez, çizgi keskin kalır
// (W17). Hız dört sınıftır (0,8 / 0,93 / 1,07 / 1,2): her sınıfın kayması ayrı sarılır, sınıf geçişinde sıçrama olmaz.
// Sıçramaların yeri ve doğuşu CPU'dandır (splash_data: 192×1, xyz yer, w doğuş anı); CPU yeri zeminden okur, barınağı atlar.
// CUSTOM: x tür (0 kar, 1 dolu, 2 toz, 3 yağmur sıçraması, 4 dolu sekmesi, −1 gizli), y boy (m), z saydamlık, w yaş (0..1).
shader_type particles;
render_mode disable_velocity, disable_force;

// Kutunun merkezi ve boyu (m; WeatherView.BOX: K98 kadrajında 50 × 22 × 50, odak + 6 m ileride, +8 m yukarı).
uniform vec3 box_center = vec3(0.0);
uniform vec3 box_size = vec3(50.0, 22.0, 50.0);
// Etkin yağış noktası sayısı (türün points değeri, karışmış).
uniform float active = 0.0;
// Türlerin payı: x kar (ıslak kar dahil), y dolu, z toz; toplam 1.
uniform vec3 kind_frac = vec3(1.0, 0.0, 0.0);
// Dört hız sınıfının kayması (m, sarılı): [tür × 4 + sınıf], tür 0 kar, 1 dolu, 2 toz.
uniform vec3 fall_off[12];
// Kar salınımının evresi (radyan, sarılı) ve genliği (m).
uniform float sway_phase = 0.0;
uniform float sway = 0.25;
// Boy (m): kar, dolu, toz.
uniform vec3 kind_size = vec3(0.06, 0.05, 0.04);
// Sıçrama havuzu: ilk sıra, sayı, yaşam (sn; yağmur, dolu), şimdiki an (sn, splash_data'nın w'siyle aynı sarımda).
uniform float splash_base = 6000.0;
uniform float splash_count = 0.0;
uniform vec2 splash_life = vec2(0.25, 0.4);
uniform float splash_now = 0.0;
uniform sampler2D splash_data : filter_nearest, repeat_disable;

uint tn_hash_u(uint x) {
	x ^= x >> 16u;
	x *= 0x7feb352du;
	x ^= x >> 15u;
	x *= 0x846ca68bu;
	x ^= x >> 16u;
	return x;
}

float tn_h01(uint x) {
	return float(tn_hash_u(x) & 0xFFFFFFu) / 16777216.0;
}

// Noktanın yeri ve CUSTOM'u: yerleşik değişkenler yardımcı işlevde okunmaz, sıra numarası verilir.
vec4 place(uint i, out vec3 pos) {
	float fi = float(i);
	pos = vec3(0.0, -10000.0, 0.0);
	vec4 custom = vec4(-1.0, 0.0, 0.0, 0.0);
	if (fi < splash_base) {
		if (fi < active) {
			vec3 s = vec3(tn_h01(i * 5u), tn_h01(i * 5u + 1u), tn_h01(i * 5u + 2u));
			float dice = tn_h01(i * 5u + 3u);
			int cls = int(tn_h01(i * 5u + 4u) * 3.999);
			int kind = dice < kind_frac.x ? 0 : (dice < kind_frac.x + kind_frac.y ? 1 : 2);
			vec3 lo = box_center - box_size * 0.5;
			vec3 p = s * box_size - fall_off[kind * 4 + cls];
			p = mod(p - lo, box_size) + lo;
			if (kind == 0) {
				p.x += sin(sway_phase + dice * 40.0) * sway;
			}
			pos = p;
			custom = vec4(float(kind), kind == 0 ? kind_size.x : (kind == 1 ? kind_size.y : kind_size.z), 1.0, 0.0);
		}
	} else {
		float j = fi - splash_base;
		if (j < splash_count) {
			vec4 d = texelFetch(splash_data, ivec2(int(j), 0), 0);
			float hail = d.w < 0.0 ? 1.0 : 0.0;
			float born = abs(d.w) - 1.0;
			float age = mod(splash_now - born + 1000.0, 1000.0);
			float life = hail > 0.5 ? splash_life.y : splash_life.x;
			if (born >= 0.0 && age < life) {
				float u = age / life;
				pos = d.xyz;
				// Dolu sekmesi: 0,4 sn'de üç sekişli ak tane.
				if (hail > 0.5) {
					pos.y += abs(sin(u * 3.0 * PI)) * 0.35 * (1.0 - u);
				}
				custom = vec4(hail > 0.5 ? 4.0 : 3.0, hail > 0.5 ? 0.05 : 0.22, 1.0, u);
			}
		}
	}
	return custom;
}

void start() {
	vec3 pos;
	CUSTOM = place(INDEX, pos);
	TRANSFORM = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(pos, 1.0));
}

void process() {
	vec3 pos;
	CUSTOM = place(INDEX, pos);
	TRANSFORM = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(pos, 1.0));
}
