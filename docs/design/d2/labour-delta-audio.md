# `audio.md` değişiklikleri (K21 emek yasası)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `audio.md` yalnız `d2/audio-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/labour.md` §5.1, §6.7, §9, §13. Faz 7 bitince birleşir. `d2/time-delta-audio.md` ile aynı satıra dokunmaz (onun AU3'ü «Ortam döngüleri» ve «Hayvan ve dünya» maddelerinin altına, bu dosyanın U2'si «Komşu belgelerin ekleri» maddesinin altına ekler). Yeni efekt kimliği bir tane (`torch_post`); `tools/check-data.mjs` başvuruyu `game/builders.js` ve `game/sites.js`'te bulur.

---

## U1. §4 Ortam ve efekt reçeteleri, «Yapı» maddesi

**Değiştir:**
```
- **Yapı:** `hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`, `collapse_small`, `collapse_big`, `fire_catch`, `fire_burst`, `stage_done`, `structure_fire` (yanan yapının döngüsü, 22 kHz, 3B, yapının tepesinden; `structures.md` §6.4).
```
**Yeni:**
```
- **Yapı:** `hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`, `collapse_small`, `collapse_big`, `fire_catch`, `fire_burst`, `stage_done`, `structure_fire` (yanan yapının döngüsü, 22 kHz, 3B, yapının tepesinden; `structures.md` §6.4), `torch_post` (şantiyenin meşale direği: 2,2 kHz alçak geçirenden geçmiş pembe gürültü ve saniyede 2–6 seyrek çıtırtı darbesi, 3–8 ms; 4 sn döngü, 22 kHz mono, 3B, direğin başından, erim 14 m, aynı anda en çok 2; yalnız gece ve şantiye işlerken çalar, menü kipinde susar; `labour.md` §5.1).
```

## U2. §4, son maddeden sonra yeni paragraf

**Yer:** «**Komşu belgelerin ekleri:**» maddesinin altı, «## 5. Seslendirme (Vibi)» başlığından önce.
**Ekle:**
```
**Şantiye sesi (K21, `labour.md`).** Ustaların ve işçilerin alet sesleri (`hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`) karanlıkta −4 dB çalar: gece işi sürer ama kamp uyur. Hava durağında (`labour.md` §5.2) alet sesi kesilir, ustanın sözü altyazıyla gelir. Söküm aynı reçeteleri kurulum sırasının tersinde çalar. Çalışma atlaması (`labour.md` §6.7) Bekle'nin sesini kullanır (`wait_lapse`, `d2/time-delta-audio.md` AU3); atlama içinde biten adımın `stage_done`'ı dönüşte bir kez çalar. Bellek: `torch_post` iki değişken ≈0,7 MB (Float32), ≤40 MB tavanının içinde.
```
