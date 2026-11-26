# `audio.md` için hava deltası (K22)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `audio.md` yalnız `d2/audio-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/weather.md` §3.5 ve §10. Faz 7 bitince uygulanır; Faz 7 sırasında `audio.md` düzenlenmez. Her madde: bölüm ve başlık, yer (bulunacak metin), yapılacak iş, yeni metnin tamamı.

## 1. §1 Sinyal yolu

Madde listesinin («- **3B:** …» maddesinden sonra) sonuna ekle:

```
- **Hava (K22).** Döngü listesini tek sahip kurar (`app/sounds.js`; kış dünyasında o dünyanın ses sahibi): taban liste + `ctx.weather.audio.beds`, rüzgâr döngüsü × `windK` (11 m/sn üstünde `wind_gale`'e geçer), öteki döngüler × `quiet` (kar ve sis sesi yutar). `ambience.set` yalnız liste ya da bir kazanç 0,05'ten çok değişince, en çok 4 Hz. Gök gürültüsü uzaklıkla gecikir: `delay = d / 343` sn, `at` iniş noktası (`d2/weather.md` §10.2). Yakın yıldırımda master 2 sn −12 dB (`tinnitus`). Menü, Yeni Oyun ve oluşturucu havasızdır.
```

## 2. §3 Müzik durumları

Şu cümleden sonra:

```
Geçişler katman kazançlarıyla 2–4 sn; durum değişince aynı ölçü sınırında girilir.
```

ekle:

```
**Yağmur katmanı.** `rain` katmanı (çan damlaları) havanın elindedir: çisenti 0,35, yağmur 0,2, sulu kar ve kar 0,15, yoğun kar 0,1, yağmurdan sonra 0,45 (0,5 oyun saatinde söner), öteki havada 0. Yalnız ortam durumlarında (`camp`, `winter_day`, `winter_evening`, `winter_night`, `home`, `road_leg`); hikâye müziklerine (`chase`, `raid`, `erlik`, `tengri`, `tension`) hava dokunmaz. Yakın gök gürültüsü müziği 2 sn −3 dB indirir.
```

## 3. §4 Ortam ve efekt reçeteleri

**3a.** **Bellek** paragrafının sonuna ekle:

```
 Hava döngüleri ve efektleri yükleyicide değil, plan bir cephe gösterince pişer (en az 1 oyun saati = 150 sn önce, dilimli); cephe geçtikten 1 oyun saati sonra bırakılır. Kampta yerleşik hava sesi en çok 3,0 MB döngü + 2,5 MB efekt (hepsi 22 kHz); Kışlak'ta 1,23 MB (`d2/weather.md` §10.1). Kampın efekt ve ortam önbelleği fırtına anında ≈14 MB, 16 MB tavanının altında.
```

**3b.** «- **Ortam döngüleri:**» maddesinin sonuna ekle:

```
 Hava: `rain_light` (10 sn; pembe gürültü, 2,5 kHz bant, damla çıtırtısı 40/sn), `rain_heavy` (10 sn; yoğun gürültü, 200 Hz gövde, 180/sn sıçrama), `rain_felt` (8 sn; keçe çatı, 1,2 kHz alçak geçiren, 300 Hz yumuşak darbe 25/sn, 3B yurdun tepesinden ya da yurt içinde), `hail_bed` (6 sn; 120/sn sert tık, 2–4 kHz, 600 Hz zemin takırtısı), `wind_gale` (14 sn; `wind_winter` deseni, 90 Hz uğultu, 600–900 Hz iki uluma, keçe çırpınması), `dust_storm` (12 sn; 3,5 kHz kum tıslaması, bora gezinmesi).
```

**3c.** «- **Hayvan ve dünya:**» maddesinde `` `thunder` `` sözcüğünden sonra ekle: `` (orta uzaklık 0,6–3 km)``.

**3d.** «- **Komşu belgelerin ekleri:**» maddesinin sonuna ekle:

```
 Hava (`d2/weather.md` §10.2, `sfx/weather.js`): `thunder_crack` (≤600 m: yırtılan çatırtı, sert patlama, 45 Hz gövde; 3 sn), `thunder_far` (3–10 km: 300 Hz alçak geçirenli yuvarlanma; 6 sn), `static_hum` (yakın yıldırım uyarısı: 100/200/300 Hz vızıltı ve çıtırtı; 1,6 sn), `gust` (bora kabarması, rüzgârın geldiği yandan; 2,5 sn), `rain_drip` (tek damla 1,2 → 0,6 kHz; 0,3 sn), `hail_tick` (3 kHz sert tık, keçede boğuk; 0,15 sn), `tinnitus` (4 kHz sinüs sönümü; 2,5 sn).
```
