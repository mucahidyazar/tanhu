// Yumuşak, "boyalı" (painterly) ışıklandırma modeli.
//
// Gerçekçi PBR yerine Ghibli tarzı bir görünüm hedefler:
//  - light_wrap: ışık, yüzeyin arkasına doğru "sarılır"; gölgeler sert değil yumuşak başlar.
//  - light_softness: aydınlık ile gölge arasındaki geçişin genişliği.
//  - rim_*: ışığı alan kenarlarda ince bir parlama (ay ışığı / ateş kontur ışığı).
//  - translucency: çimen, kumaş gibi ince yüzeylerde arkadan gelen ışığın sızması.
// Gölge tarafının mavimsi rengi ortam (ambient) ışığından gelir.
// Bu dosyayı dahil eden shader ayrıca light() fonksiyonu YAZMAMALIDIR.

uniform float light_wrap : hint_range(0.0, 1.0) = 0.4;
uniform float light_softness : hint_range(0.01, 1.0) = 0.55;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.25;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float translucency : hint_range(0.0, 1.5) = 0.0;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = clamp((ndl + light_wrap) / (1.0 + light_wrap), 0.0, 1.0);
	float shade = smoothstep(0.0, light_softness, wrapped);

	// Işığa bakan kenarlarda ince kontur parlaması.
	float facing = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(facing, rim_power) * clamp(ndl + 0.6, 0.0, 1.0);

	// Arkadan aydınlatılan ince yüzeyler (çimen ucu, bayrak kumaşı).
	float through = clamp(dot(VIEW, -LIGHT), 0.0, 1.0);
	float back = translucency * through * through * clamp(0.5 - ndl * 0.5, 0.0, 1.0);

	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION / PI * (shade + rim * rim_strength + back);
}
