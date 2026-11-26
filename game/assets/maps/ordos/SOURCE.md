# childhood_ordos: kaynaklar

Bu klasör `childhood_ordos` dünyasının (Önsöz'ün doğumu, Çocukluk) kendi varlıklarını tutar.

- `ordos_ground.gdshader`: zeminin boyalı gölgelendiricisi (kodla yazıldı; `atw_ground`'un dili, güz tonu). Üç kipi vardır: zemin, çiğnenmiş toprak katmanı ve disk (yurdun toprak tabanı, ocağın külü). Her malzeme tek bir ücretsiz dokuyu yalnız düşük frekanslı, basamaklı renk lekesi olarak okur: fotoğrafın ayrıntısı atılır, boyalı leke kalır.

## Kullanılan ücretsiz varlıklar (K89, E7.5)

Dosyalar `assets/_free/<tür>/<kimlik>/` altındadır (yolları geçici olduklarını işaretler); kayıtları `assets/_free/FREE_ASSETS.json`'da, kullanım satırları `assets/_free/usage.jsonl`'dadır. Hepsi Poly Haven'dan, CC0 1.0'dır (atıf gerekmez; yazarlar `assets/_free/LICENSES.md`'de). Oyunun düğümü `free_asset` meta verisini taşır. İçe aktarma: renk haritası 256 piksele küçültülür (VRAM sıkıştırmalı, mip'li; doku başına ≈0,04 MiB), normal ve pürüzlülük haritaları içe aktarılmaz (`importer="skip"`); HDR panorama 512 × 256 BC6H'dir (≈0,13 MiB).

| Kimlik | Düğüm (`scenes/maps/childhood_ordos.tscn`) | Ne için |
|---|---|---|
| `withered_grass` | `Ground/Terrain` | Güz otlağının zemininde renk lekeleri |
| `dry_ground_rocks` | `Ground/Trampled` | Avlunun, kapı önlerinin ve sayım hattının çiğnenmiş toprağı |
| `dirt` | `Places/LanYurt/Floor` | Lan Hatun'un yurdunun toprak tabanı |
| `burned_ground_01` | `Places/LanYurt/Hearth/Ash` | Ocağın kül yatağı |
| `qwantani_sunrise_puresky` | `WorldEnvironment` | Şafağın ortam ışığı: yalnız gök gölgelendiricisinin küp haritası geçişine karışır (`ambient_panorama`), görünen gök boyalıdır |

Kullanılmayanlar `_staging`'de kaldı: `grass_ground` ve `gravelly_sand` (kodla çizilen zemin ve uzaktaki ırmak kıyısı yetti), `qwantani_dawn_puresky` (iki ışık örneği tek panoramayla kuruldu), `stone_fire_pit` (çok taşlı halka; ocak mitin «üç taşı»dır, kodla çizildi), kap kacak modelleri (kase kodla çizildi).
