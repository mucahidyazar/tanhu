// Dünya zamanı (godot.md §8.5): zamana bağlı her gölgelendirici TIME yerine tn_time() okur.
//
// world_time genel tekdüzendir (project.godot [shader_globals]). Değeri normalde -1'dir: gölgelendirici
// motorun TIME'ını kullanır, oyunda hiçbir şey değişmez. Ekran görüntüsü aracı (scripts/dev/capture.gd)
// --freeze-time=<sn> ile onu 0 ya da daha büyük bir değere sabitler: çimen, su, alev, duman, gök ve
// sancaklar o anda donar, aynı argümanlarla iki koşu aynı kareyi verir (menü karesi referansı, tests/refs/).
// TIME duraklatmadan etkilenmez, yalnız Engine.time_scale'den etkilenir (Godot belgesi): donmuş kare
// bu yüzden ayrı bir tekdüzenle kurulur.
// Birden fazla dosya bu dosyayı içerebilir (ör. bir gölgelendirici ve onun ortak gövdesi): koruma tek tanım bırakır.

#ifndef TN_WORLD_TIME
#define TN_WORLD_TIME

global uniform float world_time;

// Gölgelendiricinin saati (saniye): dondurulmuşsa world_time, değilse TIME.
float tn_time() {
	return world_time >= 0.0 ? world_time : TIME;
}

#endif
