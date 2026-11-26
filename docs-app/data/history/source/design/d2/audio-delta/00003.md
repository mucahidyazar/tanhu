# `audio.md` birleşik deltası (K20–K24)

> **İşlendi, iz olarak kalır (2026-11-04).** Bu defter `audio.md`'ye işlendi; `audio.md` bugün bütün maddeleri 2026-11-03 doğrulama turunun inceltmeleriyle taşır. Defter yeniden uygulanmaz. «Bul», «Yerine», «Önüne ekle» ve «Sonrasına ekle» blokları 2026-11-03 metninin kopyasıdır; tek değişiklik, AD9'un hava tablosunda boş hücreyi gösteren uzun çizginin «yok» olmasıdır (yazım kuralı, `audio.md`'nin tablosuyla aynı). İçlerindeki «dombra», «Vibi», «hazır ses ≤40 MB», «16 MB pişirme tavanı» ve `court`'un «koro uzakta» sözü eski kuraldır. Geçerli metin `audio.md`'dir; `d2/` deltaları taslak ve izdir (K31). Üçüncü turun kararları (K59, K60, K61, K65, K68) `audio.md`'ye doğrudan işlendi; bu defterin değişen sözleri aşağıdaki «Üçüncü turda değişen sözler» tablosundadır. Aynı günün E6 kararları (K75 şarkı aracının ölçütleri, K78 konuşmada kısma, K79 ocağın ozanı ve Sonsöz ozanının sesi, K84 Uzak Yol'un anlatıcısı, K86 ansiklopedinin tanıtım sesi) da `audio.md`'ye doğrudan işlendi; bu defterin «Bul» ve «Yerine» metinlerine değmez, yalnız AD7'nin `lake_bull` notu düzeldi.

Tarih 2026-11-03. Faz 7 bitince `L` işler; Faz 7 sürerken `audio.md` düzenlenmez (`decisions.md` K26; K29 ile değişti: bu iş düzeni Three.js prototipi içindi, oyun Godot'dadır ve `audio.md` alan belgesi olarak doğrudan düzenlenir). **Bu dosya `audio.md` için tek işleme defteridir.** `d2/core-delta-audio.md` (CA1, CA2), `d2/time-delta-audio.md` (AU1–AU4), `d2/weather-delta-audio.md` (1, 2, 3a–3d), `d2/labour-delta-audio.md` (U1, U2), `d2/settlement-delta-audio.md` (SU1–SU4) ve `d2/economy-delta-audio.md` (A1–A3) maddelerini core defterinin değişiklikleriyle tek metne indirir; `L` yalnız bu dosyayı işler, altı kaynak dosya iz için kalır. Maddeler `audio.md`'nin bölüm sırasıyla dizilidir. Kaynak sayılar: `time.md` §8.5, `weather.md` §3.5, §7.1, §10, `d2/core.md` §3.7, `settlement.md` §12, §14, `economy.md`, `structures.md` §2.4.

**Core defterinin değişiklikleri işlendi:** hava döngüleri 8 / 8 / 6 / 4 / 10 / 10 sn (`rain_light`, `rain_heavy`, `rain_felt`, `hail_bed`, `wind_gale`, `dust_storm`); `far_rain` işareti `rain_light`'ın süzgeçli uzak çalınışıdır, yeni pişirme yoktur; hava efektleri `sr: AMB_RATE` (22,05 kHz) taşır; kar öncesi işaret `gust` 20–30 sn'de birdir (`gust_rise` ayrı reçete değildir); dört alanın «Bellek» ekleri tek paragraftır (CA1); saat ve hava paragrafları sırayla durur (CA2).

**Gerekçeyle üç inceltme:**
1. Müziğin `rain` katmanı `weather.md` §10.3'ün ortam durumlarına ek olarak `camp_night` (K20), `hold` ve `hold_night`'ta (K23) da çalar: hava listesi o durumlardan önce yazılmıştı, üçü de ortam durumudur.
2. `torch_post` kampta tek değişkenle pişer (0,35 MB; ikinci çalınış aynı tampondan perde ±%6): labour ekinin iki değişkeni (0,7 MB) kampın fırtınalı gece önbelleğini ≈15,9 MB'ye çıkarıp 16 MB pişirme tavanının payını (`weather.md` §10.1, ≈0,8 MB) 0,1 MB'ye indiriyordu; tek değişkenle ≈15,6 MB.
3. Ekonomi ve şantiye başvuruları birleşmiş belgelere çevrildi (`economy.md`, `structures.md` §2.4, §2.5; `d2/labour.md` ve `d2/economy.md` taşınmaz).

Biçim `d2/structures-delta.md` ile aynıdır: **Bul** birebir metindir (2026-11-03'te bugünkü `audio.md`'de tek eşleşme olarak denetlendi; maddeler sırayla işlenince de her biri tek eşleşmedir). **Yerine** bulunan metnin yerine birebir girer; **Önüne ekle** ve **Sonrasına ekle** yeni metni bulunan metnin önüne ya da ardına ayrı blok olarak koyar, araya bir boş satır girer; eklenen metin tablo satırı ya da liste maddesiyse bir alt satıra, boş satırsız girer. Faz 7 bir «Bul» metnini değiştirdiyse madde atlanmaz, `L`'ye sorulur (`d2/core.md` §6.7).

## Üçüncü turda değişen sözler (2026-11-04)

Aşağıdaki sözler bu defterde eski hâliyle durur; geçerli kural sağdaki sütundadır. Sütunun bölüm numaraları `audio.md`'nindir.

| Madde | Defterdeki söz | Geçerli kural (`audio.md`) | Karar |
|---|---|---|---|
| Baş | «Faz 7 bitince `L` işler; Faz 7 sürerken `audio.md` düzenlenmez» | Oyun Godot 4.7'dedir; `audio.md` alan belgesidir, doğrudan düzenlenir; d2 deltaları izdir | K29, K31 |
| AD1 | «Ozanın dombrası … `PannerNode` ile konumlanır» | Ozanın kopuzu. Godot'da dinleyici `AudioListener3D`'dir: `ROAM` ve `PLAY`'de oyuncunun 1,5 m üstünde, yönü kameranın yatay açısı; menü, sinema ve oluşturucuda kamerada (§1) | K60, K39 |
| AD2 | `camp`'ta «hafif dombra», `camp_night`'ta «seyrek dombra», `hold`'da «çekilen dombra ve uzak kobuz» | Kopuz, `motor` rolünün yoğunluğuyla (0,55; 0,3; 0,8); `hold`'un uzak sesi hucia; kıl kobuz yalnız `tengri` ve `erlik`'te ana renk (§3) | K60 |
| AD2 | `winter_day` 84 (çekilen kopuz, hafif çerçeve davul, seyrek kobuz), `winter_evening` 66, `winter_night` 60 (alçak dron, seyrek tel, nefesli kaval) | `winter_day` 72, `winter_evening` 58, `winter_night` 58; E Frigyen, kerbez akordu; Yüeçi arpı, uzak hucia, çan ve çentik; kopuz kaçış gecesine dek müzikte yok. Eski diziler Tanhu 1'in `kamp_gunduz` ve `kamp_gece`'siyle örtüşüyordu (§3) | K59 |
| AD2 | `court`: «koro uzakta» | Koro yok; `gathering_crowd` ve hafif boğaz dronu. Koro yalnız `tengri` ve `dawn`'dadır (§2, §3) | K59 (#53) |
| AD3 | «Tan'da dombra yok, ozan uyur; 09:00'dan ozanın dombrası» | Kopuz. Godot'da seçici `AudioManager`'dadır, evre ve saat `GameClock`'tan okunur, Serbest Gez aynı takvimi okur (§3 «Saate bağlı durum») | K60, K67 |
| AD4 | «Ortam döngüleri 22 kHz mono … hazır ses ≤40 MB», «16 MB pişirme tavanının (`sfx.js` `BAKE_BUDGET`) altında» | Godot'da dünya başına 26 MiB: müzik (Ogg) 16, efekt ve ortam (WAV, QOA) 8, seslendirme (MP3 64 kb/sn) 2; ortam döngüsünün 22,05 kHz monosu bir içe aktarma ayarıdır (`force/mono`, `force/max_rate_hz = 22050`, QOA). Prototipte 48 MiB: müzik 16, efekt ve ortam 24, satır penceresi 8 (§4 «Bellek») | K59 (#52) |
| AD7 | `tier_up`: «tunç gong 110 Hz FM + dombra A G F D» | Gong önce, 1,2 sn sonra kopuzla düşüş A G F D (§4 «Yerleşim ekleri») | K60 |
| AD9 | «`## 5. Seslendirme (Vibi)`» | Başlık «5. Seslendirme (ElevenLabs)»; Vibi kalktı | K28 |
| AD9 | `craft_done`: «Dombra çekişi D4 (D Dorian)» | Kopuzun tek tel fiskesi D4 (`flick`, kambarkan; düşüşün son notası) (§4 «Ekonomi reçeteleri») | K60 |

Defterde geçmeyen ama aynı bölümlerde değişenler: `crane` durumu K68 ile kalktı, `camp_bard` geri çekilmenin ve şarkının dronu oldu, `myth` ve `childhood` eklendi (§3); «tel çekilir ("strummed" değil)» kuralı kopuz kuralına döndü (K60, §2); K5'in seslendirme tavanı kalktı, sayaç ve defter kaldı (K61, §5). E6'da (2026-11-04): §1'e konuşmada kısma tablosu girdi (K78: anlatı ve sinema −3 / −3 dB, gündelik −6 / −3, gerilim ve toplanma −6 / −6, baskın ve kovalamaca −9 / −6; iniş 0,3 sn ve satırdan 0,15 sn önce, dönüş 1,0 sn; prototipin −6 / −3 dB ve 0,4 sn'si yalnız prototipte kalır); §2'nin «Kabul» tablosu sınır, sayılan ölçü ve bilgi diye üç sınıfa ayrıldı, eş zamanlı perde sözsüz bölümlerde sınır oldu (K75); Sonsöz şarkısının ses satırı kırk iki yaşında kadın ozana göre yazıldı (K79); §3'e I. Perde'nin iki kip istisnası (`chase`, `dawn`) yazıldı (K59'un E6 notu).

---

## AD1. §1 Sinyal yolu: hava

> 2026-11-04: «Ozanın dombrası» sözü kopuz oldu (K60); Godot'da dinleyici oyuncunun 1,5 m üstündedir (K39). Geçerli metin `audio.md` §1.

**Bul:** `` - **3B:** `AudioListener` kameraya bağlıdır. Ozanın dombrası, ateş, atlar `PannerNode` ile konumlanır (HRTF kapalı, `equalpower`, uzaklık modeli `inverse`). Kişiler uzaklaşınca ses kısılır. ``
**Sonrasına ekle:**
```
- **Hava (K22).** Döngü listesini tek sahip kurar (`app/sounds.js`; kış dünyasında o dünyanın ses sahibi): taban liste (evre ve ışık, §4 «Ortamın saati») + `ctx.weather.audio.beds`. Rüzgâr döngüsü × `windK` (`windGain(w) = clamp(0,45 + w/8; 0,4; 1,6)`; 11 m/sn üstünde `wind_gale`'e çapraz geçer), öteki döngüler × `quiet` (kar ve sis sesi yutar); yurt içindeyse yağmur `rain_felt`'e döner, rüzgâr ×0,4. `ambience.set` yalnız liste ya da bir kazanç 0,05'ten çok değişince, en çok 4 Hz. Gök gürültüsü uzaklıkla seçilir ve gecikir (§4 «Hava sesi»); yakın yıldırımda master 2 sn −12 dB (`tinnitus`). Menü, Yeni Oyun ve oluşturucu havasızdır (`weather.md` §10.4).
```

## AD2. §3 Müzik durumları: tablo satırları (saat ve yerleşim)

> 2026-11-04: Durum tablosu yeniden yazıldı (K59, K60, K68): «dombra» kopuz oldu; Kışlak durumları 72 / 58 / 58, E Frigyen, kopuzsuz; `court`'tan koro çıktı; `hold`'un kobuzu hucia oldu. Geçerli metin `audio.md` §3.

**Bul:** `` | `camp` | Menü, Serbest Gez | Noktalı dörtlük 52 | Dron + boğaz çok hafif, **hafif dombra** (Serbest Gez'de ozanın konumundan), ara sıra kobuz cümlesi, rüzgâr ortamı | ``
**Yerine:**
```
| `camp` | Menü; Serbest Gez Tan'dan Akşam'a | Noktalı dörtlük 52 | Dron + boğaz çok hafif, **hafif dombra** (Serbest Gez'de ozanın konumundan, yalnız ozan ateş başındayken: 09:00–22:30), ara sıra kobuz cümlesi, rüzgâr ortamı |
| `camp_night` | Serbest Gez, Gece evresi | 46 | Dron, ozan ateşteyken (22:30'a dek) seyrek dombra ozanın konumundan; sonra yalnız dron ve 40–70 sn'de bir kısa kaval cümlesi. A G F D motifi gecede bir kez |
```

**Bul:** `` | `winter_day` | Act 1 gündüz | 84 | Çekilen kopuz, hafif çerçeve davul, seyrek kobuz | ``
**Yerine:** `` | `winter_day` | Act 1, Sabah, Öğle, İkindi | 84 | Çekilen kopuz, hafif çerçeve davul, seyrek kobuz | ``

**Bul:** `` | `winter_evening` | Act 1 akşam, kazan başı | 66 | Kaval + dron, kamp sesleri | ``
**Yerine:** `` | `winter_evening` | Act 1, Tan; Akşam ve Gece'nin 22:30'a dek olanı (kazan başı, ateşler) | 66 | Kaval + dron, kamp sesleri | ``

**Bul:** `` | `winter_night` | Act 1 gece | 60 | Alçak dron, seyrek tel, nefesli kaval | ``
**Yerine:** `` | `winter_night` | Act 1, 22:30'dan Tan'a | 60 | Alçak dron, seyrek tel, nefesli kaval | ``

**Bul:** `` | `road_leg` | Atlas yolculuğu (`travel.md` §14) | 66 | Seyrek çekilen kopuz, dron, rüzgâr; A G F D motifi konak başına bir kez | ``
**Yerine:**
```
| `road_leg` | Atlas yolculuğu (`travel.md` §14) | 66 | Seyrek çekilen kopuz, dron, rüzgâr; A G F D motifi konak başına bir kez |
| `hold` | Yerleşim ve ordugâh, Tan'dan Akşam'a (K23) | 72 | Çekilen dombra ve uzak kobuz, hafif çerçeve davul ikinci zamanda; D Dorian; A G F D motifi kademe yükselişinde bir kez tam |
| `hold_night` | Yerleşim ve ordugâh, Gece | 56 | Dron, seyrek tel, kaval; davul yok |
| `court` | Toplantılar ve Toy (Kış Toplantısı, Dailin Sayımı, Toy Ver) | 96 | Major pentatonik: davul ve tüngür birlikte, boğaz dronu, koro uzakta; sevinç kipi (§3 kuralı) |
| `muster` | Ordugâhta talim ve toplanma | 108 | Tüngür ve çerçeve davul, kısa kopuz cümleleri, `whistling_arrow` perdesinde (2,4 kHz) tek kobuz notası |
```

## AD3. §3 Müzik durumları: saate bağlı durum ve yağmur katmanı

> 2026-11-04: Ozanın çalgısı kopuzdur (K60); Godot'da saat `GameClock`'tan, tek takvimden okunur (K67). Geçerli metin `audio.md` §3 «Saate bağlı durum» ve «Yağmur katmanı».

**Bul:** `Geçişler katman kazançlarıyla 2–4 sn; durum değişince aynı ölçü sınırında girilir.`
**Sonrasına ekle:**
```
**Saate bağlı durum (K20).** Gündelik müzik `clock:phase` ve saatle seçilir (`time.md` §8.5): Serbest Gez'de `camp` Tan'dan Akşam'a (Tan'da dombra yok, ozan uyur; 09:00'dan ozanın dombrası), `camp_night` Gece; Kışlak'ta `winter_day` Sabah, Öğle, İkindi, `winter_evening` Tan ile 22:30'a dek Akşam ve Gece, `winter_night` 22:30'dan Tan'a; yerleşim ve ordugâhta `hold` Tan'dan Akşam'a, `hold_night` Gece, toplantı ve Toy'da `court`, talim ve toplanmada `muster`. Sahne ve görev durumu (`tension`, `raid`, `erlik`, `chase` …) her zaman önce gelir. Bekleme ve uyku atlamasında müzik durumu varış saatine göre seçilir, geçiş karartma içinde biter. Menü `camp`'tır, saati okumaz.

**Yağmur katmanı (K22).** `rain` katmanı (çan damlaları, `music.setLayer('rain', g, 4)`) havanın elindedir: çisenti 0,35, yağmur 0,2, sulu kar ve kar 0,15, yoğun kar 0,1, yağmurdan sonra 0,45 (0,5 oyun saatinde söner), öteki havada 0. Yalnız ortam durumlarında çalar: `camp`, `camp_night`, `winter_day`, `winter_evening`, `winter_night`, `home`, `road_leg`, `hold`, `hold_night`; hikâye müziklerine (`chase`, `raid`, `erlik`, `tengri`, `tension`, `court`, `muster`) hava dokunmaz. Yakın gök gürültüsü yalnız ortam durumlarında müziği 2 sn −3 dB indirir.
```

## AD4. §4 Bellek paragrafı (birleşik)

> 2026-11-04: K12'nin «hazır ses ≤40 MB»ı ve 16 MiB pişirme tavanı kalktı (K59): Godot'da dünya başına 26 MiB (16 + 8 + 2), prototipte 48 MiB (16 + 24 + 8). Geçerli metin `audio.md` §4 «Bellek».

**Bul:** `**Bellek.** Ortam döngüleri 22 kHz mono. Üretim sahne başına önceden yapılır (`sfx.warm`, yükleyicide); hazır ses ≤40 MB. Toplu üretim ana iş parçacığını kilitlemez: dilimli, kare başına ≤4 ms.`
**Yerine:**
```
**Bellek.** Ortam döngüleri 22 kHz mono. Üretim sahne başına önceden yapılır (`sfx.warm`, yükleyicide); hazır ses ≤40 MB. Toplu üretim ana iş parçacığını kilitlemez: dilimli, kare başına ≤4 ms. **Ekler (K20–K24).** Saat ekleri (`meal_call`, `night_drum`, `wait_lapse`, `wake`) toplam ≤0,5 MB. Hava döngüleri ve efektleri yükleyicide değil, plan bir cephe gösterince pişer (en az 1 oyun saati = 150 sn önce, dilimli, kare başına ≤4 ms); cephe geçtikten 1 oyun saati sonra bırakılır (o iklimde payı %10'u aşmıyorsa). Kampta yerleşik hava sesi en çok 3,2 MB döngü + 2,5 MB efekt (hepsi 22,05 kHz); Kışlak'ta `wind_gale` 0,88 MB. `torch_post` kampta tek değişken, 0,35 MB. Kampın efekt ve ortam önbelleği fırtınalı gecede ≈15,6 MB, 16 MB pişirme tavanının (`sfx.js` `BAKE_BUDGET`) altında (`weather.md` §10.1, W19 ölçer). Yerleşim ekleri (dört döngü, sekiz efekt, ≈0,9 MB) ve ekonomi reçeteleri (≈0,6 MB) yalnız yerleşim ve ordugâh dünyalarında ön üretilir; Kışlak'ta ekonomiden yalnız `anvil` ve `bellows` (Kujul'un körüğü).
```

## AD5. §4 Ortam döngüleri: saat, hava, yerleşim

**Bul:** `` - **Ortam döngüleri:** `wind_steppe`, `wind_winter`, `blizzard`, `fire_loop`, `night_meadow` (cırcır), `birds_day`, `camp_day` (uzak uğultu, keçi, çekiç), `yurt_inside`, `ice_groan`, `water_reed`. ``
**Sonrasına ekle:**
```
- **Ortamın saati (K20, `app/sounds.js`).** Serbest Gez'de kazançlar evreyle 8 sn'de süzülür: Tan `birds_day` 0,5, `wind_steppe` 0,35, `fire_loop` 0,6; Sabah `birds_day` 0,35, `camp_day` 0,35, `wind_steppe` 0,55; Öğle ve İkindi `camp_day` 0,35, `wind_steppe` 0,7; Akşam `camp_day` 0,2 → `night_meadow` 0,3, `wind_steppe` 0,45, `fire_loop` 1; Gece `night_meadow` 0,45, `wind_steppe` 0,3, `fire_loop` 1 (22:30'dan 0,5). Bugünkü `moodTarget > 0,75` eşiği kalkar. Kışlak'ta `wind_winter` gündüz 0,6, gece 0,45; `ice_groan` Tan ve Gece'de; köpek havlaması (`dog_bark`) 22:30'dan sonra seyrekleşir. Gece 23:00'ten sonra uzak `wolf_howl` 6–10 dk'da bir (ana kamp ve Ak Otlak). Rüzgâr döngüsünün kazancı ayrıca havanın `windK`'sıyla çarpılır (§1).
- **Hava döngüleri (K22, `audio/ambience.js`; `weather.md` §10.1):** `rain_light` (8 sn, 0,71 MB; pembe gürültü, 2,5 kHz Q 0,6 bant, yavaş gezinme, damla çıtırtısı 40/sn, 150 Hz hafif gövde), `rain_heavy` (8 sn, 0,71 MB; yoğun gürültü, 5 kHz alçak geçiren, 200 Hz gövde gezinmesi, sıçrama çıtırtısı 180/sn), `rain_felt` (6 sn, 0,53 MB; keçe çatı: 1,2 kHz alçak geçiren, 300 Hz yumuşak modal darbe 25/sn; yurt içinde ve dışarıda 3B yurdun tepesinden), `hail_bed` (4 sn, 0,35 MB; sert tıkırtı 120/sn, 2–4 kHz, zeminde 600 Hz takırtı), `wind_gale` (10 sn, 0,88 MB; `wind_winter` deseni, 90 Hz uğultu, 600–900 Hz Q 10 iki uluma, keçe çırpınması), `dust_storm` (10 sn, 0,88 MB; 3,5 kHz yüksek geçiren kum tıslaması, bora gezinmesi, alçak gövde).
- **Yerleşim döngüleri (K23, `settlement.md`):** `hold_day` (yerleşimin gündüzü: sözsüz uzak konuşma uğultusu, bant 300–1.200 Hz, 0,3 Hz kabarma; seyrek köpek ve keçi; kazan kenarı tıkı; hane sayısıyla kazanç `0,25 + 0,5 × min(1, hane / 45)`), `herd_flock` (sürü: koyun ve keçi meleme kümesi, 4–9 sn'de bir, ±%8 perde; toynak hışırtısı; sürü kadrajdaysa 3B, sürünün merkezinden, erim 60 m), `camp_army` (ordugâh: at kişnemesi ve horlama 10–20 sn'de bir, uzak `anvil` 30 sn'de bir, alçak erkek uğultusu 150–500 Hz; yerleşik atlıyla kazanç), `gathering_crowd` (Toy ve toplantı: yoğun uğultu, kahkaha yerine nefesli coşku darbeleri, uzak `drum_hit` 2 sn'de bir; yalnız `court` müziği çalarken). Gece `hold_day` ve `camp_army` ×0,3, `herd_flock` ×0,5 (K20 evresi).
```

## AD6. §4 Yapı: şantiyenin meşale direği

**Bul:** `` - **Yapı:** `hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`, `collapse_small`, `collapse_big`, `fire_catch`, `fire_burst`, `stage_done`, `structure_fire` (yanan yapının döngüsü, 22 kHz, 3B, yapının tepesinden; `structures.md` §6.4). ``
**Yerine:** `` - **Yapı:** `hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`, `collapse_small`, `collapse_big`, `fire_catch`, `fire_burst`, `stage_done`, `structure_fire` (yanan yapının döngüsü, 22 kHz, 3B, yapının tepesinden; `structures.md` §6.4), `torch_post` (şantiyenin meşale direği: 2,2 kHz alçak geçirenden geçmiş pembe gürültü ve saniyede 2–6 seyrek çıtırtı darbesi, 3–8 ms; 4 sn döngü, 22 kHz mono, 3B, direğin başından, erim 14 m, aynı anda en çok 2; yalnız gece ve şantiye işlerken çalar, menü kipinde susar; `structures.md` §2.4 `K_gece`). ``

## AD7. §4 Hayvan ve dünya: gök gürültüsü, saat ve yerleşim ekleri

> 2026-11-04: `tier_up`'ın dombrası kopuz oldu (K60); «Hayvan ve dünya» satırına `eagle_call` ve `lake_bull` girdi, `eagle_cry` Tengri'ye bağlanmaz (K61, K65). Geçerli metin `audio.md` §4. (2026-11-04, E6.4: `lake_bull` önce kodla basılır, inandırıcı olmazsa ElevenLabs efekt ucundan tek dosya alınır, kredi önce sorulur; `weather.md` §10.2.)

**Bul:** `` - **Hayvan ve dünya:** `wolf_howl`, `eagle_cry`, `crow`, `dog_bark`, `sheep`, `thunder`, `ice_crack`, `heartbeat`, `alarm_horn`, `drum_hit`, `bone_hum` (Yol Kemiği uğultusu: gürültü + bant geçiren, rüzgâra bağlı, 3B), `mene_hum` (Mene'nin falsolu mırıltısı). ``
**Yerine:**
```
- **Hayvan ve dünya:** `wolf_howl`, `eagle_cry`, `crow`, `dog_bark`, `sheep`, `thunder` (orta uzaklık 0,6–3 km; §4 «Hava sesi»), `ice_crack`, `heartbeat`, `alarm_horn`, `drum_hit`, `bone_hum` (Yol Kemiği uğultusu: gürültü + bant geçiren, rüzgâra bağlı, 3B), `mene_hum` (Mene'nin falsolu mırıltısı).
- **Saat ekleri (K20):** `meal_call` (Mutfak Kazanı'nın kenarına vurulan tunç: FM, 180 Hz taban, iki uyumsuz kısmi, 2,5 sn kuyruk; öğle çanı 12:00 ve akşam aşı 17:30, 3B kazandan), `night_drum` (gece davulu: üç ağır `drum_hit`, 1,5 oyun saatinde bir, Nöbet Yurdu'ndan, 3B), `wait_lapse` (arayüz: 1,8 sn yumuşak rüzgâr kabarması, bekleme ve çalışma akışı), `wake` (arayüz: soluk ve köz çıtırtısı, uyanış).
- **Yerleşim ekleri (K23):** `plan_place` (Plan Kipi'nde yerleştirme: kazık vuruşu `hammer_wood` ×0,8 + kısa ip gerilmesi, bant 900 Hz, 120 ms; −14 dB), `plan_rotate` (döndürme: ince tahta tık, `ui_hover` ×0,6, 15°'de bir), `household_arrive` (hane kapıdan girer: uzak `hoof_walk` dörtlüsü + iki melemeli `sheep` + kısa karşılama boru notası, `alarm_horn`'un yumuşatılmışı, alçak geçiren 800 Hz, −20 dB, 3B kapıdan), `caravan_depart` (kervan kalkışı: `cart_loop` 2 sn kabarma, `horse_snort`; 3B ambardan), `tier_up` (kademe kartı: tunç gong 110 Hz FM + dombra A G F D, `level_up`'tan ayrı: gong önce, 1,2 sn sonra dombra; −12 dB), `dawn_bow` (Şafak Selamı: boğaz dronu D2 4 sn kabarıp söner + tek kaval D5, 1,5 sn; yalnız Gök Direği'nde), `omen_strike` (alamet: yakın `thunder` + `fire_catch` + 0,8 sn sessizlik + `bone_hum` perdesinde tek uzun ton; perde başına bir kez), `assembly_drum` (toplantı çağrısı: tüngür üçlüsü, 8 sn arayla iki kez, Toy Alanı'ndan 3B, erim 300 m).
```

## AD8. §4 Komşu belgelerin ekleri: ekonomi ve hava efektleri

**Bul:** `` - **Komşu belgelerin ekleri:** `clean_strike`, `load_thud`, `notch`, `cook_sizzle`, `balance_tick` (`economy.md` §3.7); `post_knock`, `wheel_snow` (`travel.md` §14); `bone_clack`, `sling_whirl` (`progression.md` §14.2); `whoosh`, `page_turn` (`menu-spec.md`). ``
**Yerine:**
```
- **Komşu belgelerin ekleri:** `clean_strike`, `load_thud`, `notch`, `cook_sizzle`, `balance_tick` (`economy.md` §3.7); `post_knock`, `wheel_snow` (`travel.md` §14); `bone_clack`, `sling_whirl` (`progression.md` §14.2); `whoosh`, `page_turn` (`menu-spec.md`); `felt_roll`, `bellows`, `anvil`, `adze`, `tan_scrape`, `shear_snip`, `milk_pail`, `store_open`, `cart_unload`, `loot_search`, `craft_done` (K24 tezgâhları, kaplar ve ganimet: `economy.md` §6.7, §4.5, §3.12; reçeteler aşağıda).
- **Hava efektleri (K22, `audio/sfx/weather.js`; `weather.md` §10.2).** Hepsi reçetede `sr: AMB_RATE` (22,05 kHz) taşır (motorun varsayılanı 32 kHz; verilmezse bellek ≈%45 büyür), fırtına cephesiyle pişer, ≈2,5 MB: `thunder_crack` (2 değişken, 3 sn, aynı anda 1; ≤600 m: yırtılan çatırtı, hızlanan crackle, sert patlama, 45 Hz gövde), `thunder_far` (2, 6 sn, 2; 3–10 km: 300 Hz alçak geçirenli yuvarlanma, yavaş kabarma), `static_hum` (1, 1,6 sn, 1; yakın yıldırım uyarısı: 100/200/300 Hz vızıltı ve seyrek çıtırtı), `gust` (2, 2,5 sn, 2; bora kabarması, rüzgârın geldiği yandan pan), `rain_drip` (3, 0,3 sn, 3; tek damla 1,2 → 0,6 kHz kısa sinüs ve tık), `hail_tick` (3, 0,15 sn, 4; 3 kHz sert tık, keçede boğuk), `tinnitus` (1, 2,5 sn, 1; 4 kHz sinüs sönümü). Birikintide Çocuğun adımı `splash`'tır (`sfx/gather.js`).
```

## AD9. §4 sonu: hava sesi, şantiye sesi, ekonomi reçeteleri

> 2026-11-04: «Bul» başlığı `## 5. Seslendirme (Vibi)` bugün `## 5. Seslendirme (ElevenLabs)`'tir (K28 ile değişti). `craft_done`'ın dombra çekişi kopuzun tek tel fiskesi oldu (K60). Godot'da canlı ses oynatıcısı ≤40'tır (K63). Geçerli metin `audio.md` §4.

**Bul:** `## 5. Seslendirme (Vibi)`
**Önüne ekle:**
```
**Hava sesi (K22, `weather.md` §3.5, §7.1, §10).** Hava döngü listesi vermez, veri verir (`weather.audio = { beds, windK, windSwap, quiet, inside }`); listeyi §1'in tek sahibi kurar. `windGain` taban rüzgâr döngüsünün (`wind_steppe`, kışta `wind_winter`) çarpanıdır.

| Tür | Ortam (kazanç) | Taban rüzgâr × | Müzik `rain` | Tek seferlik |
|---|---|---|---|---|
| `clear`, `cloud` | Taban | `windGain` | 0 | yok |
| `overcast` | Taban; `birds_day` ×0,5 | `windGain` | 0 | yok |
| `fog` | Taban ×0,7 (uzak boğulur), `camp_day` ×0,6 | 0,5 | 0 | `rain_drip` 8–20 sn'de bir |
| `drizzle` | `rain_light` 0,45 | `windGain` | 0,35 | `rain_drip` |
| `rain` | `rain_light` 0,7, `rain_heavy` 0,3; yurt ≤12 m'deyse `rain_felt` 3B | `windGain` | 0,2 | yok |
| `downpour` | `rain_heavy` 1 | ×0,8 | 0 | yok |
| `thunderstorm` | `rain_heavy` 0,8, `wind_gale` 0,3 | `windGain` | 0 | `thunder_crack`, `thunder`, `thunder_far`, `gust`, `static_hum` |
| `dry_storm` | `wind_gale` 0,6 | `windGain` | 0 | Gök gürültüleri, `gust` |
| `hail` | `hail_bed` 1, `rain_heavy` 0,4; yurt içinde `rain_felt` yerine boğuk `hail_bed` | ×0,8 | 0 | `hail_tick` 3B |
| `wind` | Taban | `windGain` | 0 | `gust` |
| `gale` | `wind_gale` 1; taban söner | yok | 0 | `gust`; kapı keçelerinde `felt_flap` |
| `sleet` | `rain_light` 0,6 | `windGain` | 0,15 | yok |
| `snow` | Taban ×0,8 (kar sesi yutar) | ×0,7 | 0,15 | yok |
| `heavy_snow` | Taban ×0,6 | ×0,8 | 0,1 | yok |
| `blizzard` | `blizzard` 1 | yok | 0 | `gust` |
| `kara_boran` | `blizzard` 1; T4 kör rüzgârda yalnız `bone_hum` | yok | 0 (müzik `chase`) | `gust` |
| `dust_storm` | `dust_storm` 1, `wind_gale` 0,4 | yok | 0 | `gust` |
| Yağmur sonrası (çözülme) | Taban + `rain_drip` | `windGain` | 0,45; 0,5 oyun saatinde söner | `rain_drip` |

**Gök gürültüsü uzaklıkla.** Her şimşekten sonra hava iniş noktasını ve uzaklığı verir; ses `sfx.play(id, { at: iniş, delay: d / 343, gain })` ile, panner `inverse`: ≤600 m `thunder_crack` (300 m'de 0,9 sn sonra), 0,6–3 km `thunder` (`sfx/world.js`, 4,2 sn, `ref` 400; 1 km'de 2,9 sn sonra), 3–10 km `thunder_far` (5 km'de 14,6 sn sonra); 10 km ötesi duyulmaz. Yakın düşüşten 1,5 sn önce `static_hum` (telegraf), düşüşte master 2 sn −12 dB ve `tinnitus`; yakın gök gürültüsü ortam müziğini 2 sn −3 dB indirir (§3). Aynı anda en çok bir gök gürültüsü.

**İşaret sesleri** (`weather.md` §7.1; `sev` ≥3 cephede ses kanalı zorunlu): `far_thunder` (cepheden 1 oyun saati önce, 8–12 km'den `thunder_far` 40–70 sn'de bir), `far_rain` (rüzgârın geldiği yanda `rain_light`'ın 900 Hz alçak geçirenli uzak 3B çalınışı, −20 dB'den −10 dB'ye kabarır; yeni pişirme yok), `gust_rise` (kardan 1 oyun saati önce `gust` 20–30 sn'de bir; ayrı reçete yok), `bones` (Yol Kemikleri: `bone_hum` kazancı rüzgârla yükselir), `static` (yakın yıldırım). Varıştan 0,25 oyun saati önce `rain_drip` başlar.

**Kışlak.** `hexi` kışında gök gürültüsü ve yağmur sesi yoktur; rüzgâr, kar ve Kara Boran döngüleri ve `bone_hum` havanın rüzgârına bağlıdır; Kara Boran'dan önce `bone_hum` kazancı yükselir (`act1.md` §14).

**Düğüm bütçesi.** Hava en çok iki döngü (2 × 2 düğüm), bir 3B döngü (3), bir gök gürültüsü (3, geçici) ekler: ≤10. Serbest Gez ölçümü ≤25 (Faz 3) → ≤35, tavan 40 (`architecture.md` §7).

**Şantiye sesi (K21, `structures.md` §2.4, §2.5).** Ustaların ve işçilerin alet sesleri (`hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`) gece −4 dB çalar: iş sürer ama kamp uyur. Hava durağında alet sesi kesilir, ustanın sözü altyazıyla gelir. Söküm aynı reçeteleri kurulum sırasının tersinde çalar. Çalışma atlaması Bekle'nin sesini kullanır (`wait_lapse`); atlama içinde biten adımın `stage_done`'ı dönüşte bir kez çalar. Gece atölye döngüleri de −4 dB'dir.

**Ekonomi reçeteleri (K24, `src/audio/sfx/economy.js`).** Hepsi kodla sentezdir, 22 kHz mono, yerleşim ve ordugâh dünyalarında dilimli ön üretim. Döngüler tezgâhta iş sürerken çalar, ekip yoksa susar; aynı anda en çok 2 tezgâh döngüsü, uzaklıkla 3B (`audio/spatial.js`).

| id | Olay | Sentez | Kazanç |
|---|---|---|---|
| `felt_roll` | Keçe Avlusu, döngü | Yumuşak tok vuruşlar 1,2 Hz (400 Hz alçak geçirenli gürültü, 60 ms) + hasır hışırtısı (bant 2–4 kHz, %30); her 8 vuruşta bir nefes (gürültü 300–800 Hz, 0,4 sn), söz yok | −20 dB |
| `bellows` | Demirci Ocağı, döngü | Nefes gibi kabaran gürültü 0,8 Hz (bant 300–900 Hz, zarf 0,5 sn yükselme, 0,7 sn iniş) + kor çıtırtısı (8 Hz rastgele tık) | −18 dB |
| `anvil` | Demirci vuruşu, 2–3 sn'de bir | FM: taşıyıcı 1,2 kHz, oran 2,76, indis 4, 600 ms sönüm + 180 Hz tok 40 ms | −14 dB |
| `adze` | Ağaç Atölyesi, keser | Bant 1,1 kHz gürültü 25 ms + sinüs 140→100 Hz 60 ms; 1,6 sn'de bir, ±%8 perde | −16 dB |
| `tan_scrape` | Sepi Yeri, kazıma | Bant 1,5–3 kHz gürültü vuruşları 2 Hz, 180 ms, ıslak alçak geçiren son | −22 dB |
| `shear_snip` | Kırkım | İki tık 4 kHz (8 ms arayla) + yapağı hışırtısı (1,2 kHz alçak geçiren, 250 ms) | −20 dB |
| `milk_pail` | Sağım | Sıvı fışkırma (bant 2–4 kHz, 70 ms) kova rezonansına (bant 700 Hz, Q 6) | −22 dB |
| `store_open` | Kap açılır (ambar, sandık, terki) | Keçe kapak hışırtısı (600 Hz alçak geçiren, 200 ms) + tahta kapak tok (120 Hz, 50 ms) | −16 dB |
| `cart_unload` | Araba ya da kervan boşalır | `load_thud` üç kez, 0,25 sn arayla, perde her birinde −%6 | −14 dB |
| `loot_search` | Ara / Search | Kumaş hışırtısı (bant 1–3 kHz, 400 ms) + 2 metal şıngırtı (FM 2,4 kHz, 90 ms) | −18 dB |
| `craft_done` | Tarif ya da sipariş bitti (arayüz) | Dombra çekişi D4 (D Dorian) + ince tahta tık (`ui_hover` ×0,7) | −16 dB |
```
