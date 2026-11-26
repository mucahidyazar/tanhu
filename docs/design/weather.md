# Hava / Weather (K22)

Alan belgesi, son biçim 2026-11-03; üçüncü tur güncellemesi 2026-11-04 (K29, K31, K35, K39, K42, K45, K46, K54–K56, K58–K61, K65, K67, K68); E6 düzeltmesi aynı gün (K49: kar örtüsü payları `d2/weather-model.json` v2'den; K56: `a4_dailin` ve Lung-çeng günleri; K76: Ev'in ışığı; K83: camp3 gecesinin havası). Kaynak: d2 taslağı (`d2/weather.md`, 2026-11-02), eleştirisi ve baş tasarımcının kararları (`decisions.md` K22, K26; kesişen sayılar `d2/core.md` §3). Bağlayıcı sıra K31'dir: `decisions.md` > `d2/core.md` > alan belgeleri (bu belge dahil) > `godot.md`; `architecture.md` yalnız prototipin belgesidir (K31 ile değişti). Bu belge K22'yi ayrıntılandırır: sayıları gerekçesiyle inceltir, kararı tersine çevirmez. Kimlikler ve kod İngilizce, metin Türkçe; oyuncu dizgeleri TR / EN çiftidir ve bu belge için yeni yazılmıştır (Tanhu 1'den alınmaz, K32).

**Godot.** Oyun Godot 4.7 ile yapılır (K29). Bu belgenin kuralları ve sayıları bağlayıcıdır; `src/…` dosyaları, GLSL parçaları, `menuDiff`, `__tanhu.weather` ve 8.10, 9.4 gibi paket adları Three.js prototipinindir (§9, §12, §14, §15'in tarayıcı satırları). Godot karşılıkları: `WeatherPlanner`, `WetState`, `SnowPack`, `WeatherFx` (saf sınıflar), `WeatherView` (yağış `GPUParticles3D`, şimşek, ekran yağışı); veri `data/weather/types.json` ve `climates.json` (`godot.md` §3). Işığın tek yazıcısı `SkyRig`'dir (`godot.md` §4.9). İş Yol Haritası'nın `weather` maddesindedir ([/roadmap#act-1-p1](/roadmap#act-1-p1)). Faz 7 sürerken `architecture.md`, `structures.md`, `audio.md` ve `contract-requests.md` düzenlenmez: o üç belgeye giden değişiklikler Faz 7'den sonra yalnız üç birleşik defterle işlenir: `d2/architecture-delta.md`, `d2/structures-delta.md`, `d2/audio-delta.md` (K26, §13); `d2/weather-delta-*.md` ve `d2/core-delta-*.md` iz için kalır. Öteki belgeler için yönergeler §13'tedir.

Komşu belgeler: `time.md` (K20, K67: `WorldClock`, `Calendar`, `clock:hour`, `clock:skip`, `lightLevel(…, cloud)`, `nightClass`, tek takvim, ana kampın 11 Nisan açılışı ve akan mevsimi, Son Gece sisi, ışığın tek hattı), `fauna.md` §7 (K65: hayvanların hava ve mevsim tepkileri), `d2/core.md` §2 (K21: şantiyenin hava tepkisi ve sığınma tablosu), `settlement.md` (K23: Gök Direği, Sancak Direği, kervan, ordugâh ve sürü tepkileri), `d2/core.md` §5 (K24: kurutma ve bozulma, mevsim uzunlukları). Tür kimlikleri emek tablosuyla aynıdır (`wind`, `gale`, `kara_boran` …). **Hava yalnız fiziksel değeri (`fx`) verir; her tepki tablosunun tek sahibi vardır** (§8, `d2/core.md` §3.3).

**Kısaltmalar.** sa: oyun saati (K20: 1 sa = 150 gerçek sn, 1 gün = 24 sa = 60 gerçek dk). gdk: gerçek dakika. sn: gerçek saniye. m/sn: rüzgâr ve hız. "Bölüm": planlayıcının tek türlü zaman dilimi (segment).

## 0. Karar özeti

| # | Karar | Sayı | Neden |
|---|---|---|---|
| H1 | Hava durumu oyun saatiyle, devinim gerçek saniyeyle akar | Bölüm süreleri sa; yağış, bora, bulut gölgesi, gök gürültüsü gecikmesi sn | K20 bir günü 60 dk'ya sıkıştırır. Ses hızı ve yağmur düşüşü sıkıştırılırsa okunmaz: 3 km'deki şimşeğin sesi 8,7 sn sonra gelmeli |
| H2 | 17 tür + hikâyenin Kara Boran'ı; 8 alt olay | §3 | K22 listesi; kuru fırtına ve sulu kar boşluk doldurur (§17) |
| H3 | Her tür bir parametre vektörüdür; geçiş vektörlerin karışımıdır | Bölüm geçişi 20–60 sn | Ayrık tür sıçrar. Vektör çizime, sese ve oyun etkisine tek kaynaktan dağılır |
| H4 | Bölüm planlayıcı: yarı Markov + cephe dizgesi + gün içi eğri, tohumlu ve belirlenimli | Plan en az 12 sa ileride | İşaretler ve gök okuma geleceği bilmeli; kaydet, yükle aynı havayı vermeli |
| H5 | Tasarımcı hedef payı yazar; ağırlıkları yükleyici ayarlar | 38 iklim satırında en büyük sapma 1,34 puan (benzetim, §19) | Cephe parçaları kapalı ve bulutlu payını şişirir; elle ağırlık tutmaz |
| H6 | Oyunu değiştiren her hava en az 1 sa (2,5 gdk) önceden okunur | §7 | Fırtına sürpriz değil hazırlık oyunu olur: ateşi taşla çevir, çadırı bağla, sırttan in |
| H7 | Hikâye kilidi planlayıcıyı durdurur; kalibre sahneleri `pinFx` ile korunur | I. Perde 17 kilit + `home` (§6.2) | act1.md sahneleri sabit hava ister; Son Gece, baskın ve Kara Boran sayıları değişmez |
| H8 | Çalışma zamanında ışık eklenmez: şimşek pozlama, yarımküre ışığı yoğunluğu ve gök uniform'uyla | Program +2 (≤92) | §0 kural 7, K22 |
| H9 | Yağmur, kar ve dolu çizgisi son geçişte (FINAL) ekran katmanı; kar, dolu, toz ve sıçrama tek 3B nokta geometrisi | Ekran katmanı 0 çizim; nokta 1 çizim | Kuwahara boyası 1–2 piksellik çizgiyi siler; FINAL'de çizgi keskin kalır. Nokta derinlik ve paralaks verir, boyada parlak leke olarak yaşar |
| H10 | Islaklık ve kar tazeliği tek paylaşılan uniform: `U.uWet` | 0 çizim | Zemin, keçe, çim, kaya aynı kaynaktan okur; menüde 0, görüntü bit bit aynı |
| H11 | Menü, Yeni Oyun sineması (Önsöz dahil), oluşturucu ve `home`: hava kimliktir (açık, kuru) | `menuDiff` 0; Godot'da menü karesi referansla aynı | §0 kural 8, K7, K22, K68 |
| H12 | Yıldırım uzun ve yalnız olana iner; oyuncu ve yapılar için adil kurallar; ana kampta okunur | Fırtına başına ≤1 yakın düşüş, 1,5 sn uyarı; Serbest Gez'de %60 kadraja | §8.7 |
| H13 | Hava soğuk ya da sıcaklık modellemez | §16 denetimi | K1 |
| H14 | Rüzgâr tek sayıdır (m/sn, yön); bütün sistemler aynı sayıyı okur | Açık 2,5 … Fırtına 16 | structures §6.2 `R = 10 + rüzgâr` ve act1 §10 dörtnal ±1,5 aynı sayıdan çıkar |
| H15 | Gök okuma yeni beceri değil, `iron_stake`'e eklenir | 6 sa tahmin | 93 beceri ve XP toplamı korunur (`progression.md` §4) |
| H16 | Ses: 6 yeni ortam döngüsü, 8 yeni efekt (`lake_bull` dahil); yalnız planda varken pişer | Kampta yerleşik ≤6 MB (prototipin yüzer nokta tamponu; `lake_bull` +0,26 MB) | (K59 ile değişti) Godot'da dünya başına efekt ve ortam havuzu ≤8 MiB (WAV QOA, ortam 22,05 kHz mono); prototipte efekt ve ortam 24 MiB; K12'nin 40 MB'ı kalkar |
| H17 | Tepkiler sahiplerinindir; hava yalnız fiziksel `fx`'i verir | §8, `d2/core.md` §3.3 | Çift sayı olmaz; şantiye, sürü, kervan, ordu, ekonomi aynı `fx`'i okur |
| H18 | Çamur ve taze kar yolu yavaşlatır; ağır havada araba kalkmaz, Yol Kartı bekleme süresi yazar | §8.10 | `travel.md` kilit deseni |
| H19 | Han birlikleri havadan iki kat yorulur | `fatigue` | Chao Cuo, Han Shu 49: 風雨罷勞，飢渴不困，中國之人弗與也 |
| H20 | Bulut ay ışığını keser, ay hesabını değil | `cloud`, `moonSeen` | Shiji 110'un 月盛壯則攻戰'ı ayın evresidir, gün sayılarak bilinir: ordu ay olayları takvimden; bulut yalnız ışığı (gece emeği, ay kartı, gözcü satırı) değiştirir |
| H21 | Her türün gök örtüsü vardır | `cloud` 0..1 (§3.4) | `lightLevel`, `moonSeen` ve gece sınıfı tek sayıdan okur |
| H22 | Kar örtüsü ve Kar Kabuğu zon durumudur | `snowpack`, `deepSnow`, `crust` (§5.9) | Bozkırın kış felaketi soğuk değil otu örten buzdur; sıcaklıksız sıra kuralı (K1) |
| H23 | Işığın tek yazıcısı `WeatherView.compose`'dur | Saat tabanı `world.lightBase`'e yazar | Çift çarpım yok, menü yolu değişmez (K26) |
| H24 | Hava zinciri sabit çapadan kurulur | `floor(hourAbs/24) × 24 − 24` | Kayıt, yükleme ve geri dönüş aynı havayı verir |
| H25 | Kampın havası takvimin mevsimini okur (K67) | Bahar `camp_spring`, yaz `camp_summer`, güz `camp_autumn`, kış `camp_winter`; kar yalnız kışın tutar (§4.1, §5.9) | Tek takvim: Serbest Gez 11 Nisan'da açılır, mevsim akar; yeni doku ve program yok |
| H26 | Görünüm ve kar örtüsü soru değil, ölçüm işidir (K58, #16) | Ekran yağışının çizgisi zayıfsa katman alfası 0,5 → 0,65 (W16); kar örtüsü paylarını prototipin gerçek çekirdeği bastı (`d2/weather-model.json` v2; `steppe_south` derin kar 0,16, K49), Godot'un `WeatherPlanner` ve `SnowPack`'i W26'nın kabulünde kalır | Kullanıcı: «bunun gibi şeyler soru değilse önerdiğin araştırdığın gibi yap» |
| H27 | Hayvan işaretleri `fauna.md` §7'nin satırlarıyla genişler (K65) | Deve, yak, sığır, turna, kaz, zeren, doğan ve kartal (§7.6) | Bozkırın hava bilgisi hayvandan okunur |
| H28 | Akın günü takvimdir, bulut onu ertelemez (K55, H20) | `moon_illum(dayN + 0,5) ≥ 0,97` | Shiji 110 月盛壯則攻戰 ayın evresidir |

## 1. Kapsam ve dayanak

**Dokunduğu sistemler.** Görüş ve sis; gizlilik (görüş, gürültü maskesi, şimşek ifşası); iz ve koku (av); kamp ateşi, pişirme, kurutma; yapılar (ıslak keçe, sıçrama, yağmurla sönme, dolu, rüzgâr, yıldırım); ok ve yay; atlar ve sürüş; yol, araba, hızlı yolculuk; inşa ve işçiler (K21); NPC programı ve sürüler; ordu (`army.md`); ekonomi ve yerleşim kancaları (K23, K24); Çocuk (Serbest Gez); çizim, ses, HUD, kayıt, geliştirici paneli.

**Dokunmadığı.** Sıcaklık, üşüme, ısınma, giysi sıcaklığı (K1). Irmak buzunun evreleri (`act1.md` §4: Gün I akar, III kenar buzu, V ince tam buz) hikâyenin takvimidir, havanın sonucu değildir. Mevsimin akışı takvim alanınındır (K20, K67), hava mevsimi okur; ana kamp da dahil her dünyada mevsimi takvim verir.

**Tarih ve gelenek dayanağı.**

| Kaynak | Söylediği | Oyun kuralı |
|---|---|---|
| Shiji 110 (Baideng, MÖ 200) | 會冬大寒雨雪，卒之墮指者十二三: kış geldi, büyük soğuk ve kar; askerin onda ikisi üçü parmağını yitirdi | V. Perde `a5_baideng` kar kilidi (§6.4). Yalnız kar ve derin kar oynanır; soğuk ve parmak donması oynanmaz (K1), Destan Kitabı yalnız karı anar |
| Han Shu 49, Chao Cuo (MÖ 169) | 風雨罷勞，飢渴不困，中國之人弗與也: rüzgârda, yağmurda, yorgunlukta Han insanı Hun'la boy ölçüşemez | H19: Han birliğinin hava yorgunluğu ×2 (§8.13) |
| Shiji 110 (`army.md` §1 #11) | 舉事而候星月，月盛壯則攻戰，月虧則退兵 | H20: ayın evresi takvimdir (ordu ay olayları değişmez); bulut yalnız ay ışığını keser |
| Shiji 110 (`army.md` §1 #10) | 五月，大會蘢城 · 秋，馬肥，大會蹛林 | Lung-çeng toplantısı (5. ayın dolunayı, takvimde yaz) `orkhon` yaz satırında; Dailin (8. ayın dolunayı, K56) güz satırında; oynanan günlerin kilitleri §6.4 |
| Türk halk hava bilgisi | «Ay ağıl aldı»; «duman yere çökerse yağmur gelir»; sabah kızıllığı | İşaretler (§7): ay ve güneş halesi, çöken duman, kızıl şafak. Halk bilgisi kurgu listesine girmez |
| Yada taşı, `yat` (Kaşgarlı Mahmud, 11. yy; Moğol `jada`) | Taşla yağış ve tipi çağırma | Yalnız V. Perde kancası, `tasarım tercihi` olarak işaretlenir (§6.4); kaynak Mete çağından geçtir |

## 2. Zaman ölçeği (K20 ile)

- **Durum saatle.** Planlayıcı oyun saati sınırında karar verir; bölümün süresi sa ile yazılır, en kısası dolu sağanağıdır: 0,15 sa = 22 sn. Bir bölüm ortalama 6–12 gdk sürer (§4.5).
- **Devinim saniyeyle.** Yağmur ekran düşüşü, kar salınımı, bora, bulut gölgesinin kayması, şimşek nabzı ve gök gürültüsü gecikmesi gerçek saniyedir: `gecikme = d / 343` sn (100 m 0,3 sn; 1 km 2,9 sn; 3 km 8,7 sn; 10 km 29 sn). Saatin hızlanması fiziği sıkıştırmaz; sıkışan yalnız günün gidişidir.
- **Karışım.** Bölümden bölüme parametre karışımı 20–60 sn (§5.8). Cephe hazırlığı 1–2 sa (2,5–5 gdk) sürer; işaretler bu sürede gelir.
- **Uyku ve atlama.** K20 uyku, dinlenme ve çalışmayla saati atlatır. Hava `clock:skip { from, to, minutes, reason, sleep, long }` alınca (atlamanın `clock:hour` olaylarını `skipping: true` iken yok sayar, `time.md` §7.4) planlayıcıyı ileri sarar, ıslaklığı ve kar örtüsünü analitik ya da saat adımlı çözer (§5.9); uzun atlamada (`long`) olay yaymadan ileri sarar. Atlanan bölümlerin işareti söylenmez, uyanınca ilk konuşan kişi ne olduğunu bir satırla söyler (§7.3 uyanış satırları).
- **Akan Kronik ve tarih kapısı (K42, K33).** İkisi de uzun atlamadır (`reason: 'chronicle'`, `'gate'`). Yüklü dünyanın planı tutulmaz: varış gününde sabit çapalı zincirden yeniden kurulur (§5.5). Yerleşim ve ordugâh zonlarının kar örtüsü ve kabuğu (`packs`) olaysız saat adımıyla ileri sarılır; bütçe Kronik'in mevsim başına ≤150 ms'si içindedir (2.190 saat adımı / mevsim). Kronik hava kartı göstermez; Kar Kabuğu'nun sürüye etkisi Kronik'in kapalı hesabındadır (`settlement.md` §15.3, §16.2).
- **Tek takvim (K67).** Serbest Gez de oyunla aynı saati okur: `clock.abs = dayN × 1440 + dakika`, ayrı `roam.clock` sayacı kalkar.
- **Saat yüzü** (`time.md` §12, `d2/core.md` §1.7). Hava yalnız şunları okur; planlayıcının saati `clock.hourAbs`'tır (`abs / 60`).

```js
clock.abs        // oyun dakikası (dayN × 1440 + dakika); Serbest Gez dahil tek takvim (K67);  clock.hourAbs = abs / 60
clock.hour       // 0..24;  clock.belowHorizon (−0,833°), clock.dark (−6°);  clock.paused (diyalog, sinema, harita, Donuk Kamp)
calendar.season  // 'spring' | 'summer' | 'autumn' | 'winter' (SEASONS; econ-model seasonDays uzunlukları)
calendar.dayN, calendar.moonIllum(abs)   // tohum (dünya, dayN, saat) ve ay
daylight.sunAt, moonAt                   // güneş ve ay yönü: hale, kubbe şimşeği yönü
bus 'clock:hour' { day, hour, abs, skipping } · 'clock:skip' { from, to, minutes, reason, sleep, long, days, dawns } · 'dawn' { day, abs, skipping }
// Havadan saate: fx.cloud → daylight.lightLevel(sunEl, moonEl, illum, cloud) ve nightClass; 'weather:change' (sev ≥3) Bekle'yi keser (time.md §7.3)
```

## 3. Hava türleri

### 3.1 Liste

Ağırlık (`sev`) 0–4 bütün sistemlerin okuduğu kaba ölçüdür: 0 etkisiz, 1 görünür, 2 hafif oyun etkisi, 3 ağır (bazı işler bekler), 4 sığınak gerektirir.

| id | TR / EN | Grup | `sev` | Süre sa (gdk) | Nerede, ne zaman | Kısaca |
|---|---|---|---|---|---|---|
| `clear` | Açık / Clear | kuru | 0 | 3–12 (7,5–30) | Her yer | Menünün görünümü: hafif bulut gölgesi |
| `cloud` | Parçalı Bulut / Broken Cloud | kuru | 0 | 2–8 (5–20) | Her yer | Bulut gölgeleri iri ve hızlı |
| `overcast` | Kapalı / Overcast | gri | 1 | 2–10 (5–25) | Her yer; cephe önü ve arkası | Düz ışık, gölge yok denecek kadar |
| `fog` | Sis / Fog | gri | 1 | 1–4 (2,5–10) | Durgun gece, şafak; 10:00'da dağılır | Göl ve ırmak boyu, Buz Kolu |
| `drizzle` | Çisenti / Drizzle | ıslak | 1 | 1–4 | Ilıman satırlar | İnce çizgi, ıslak zemin yavaş |
| `rain` | Yağmur / Rain | ıslak | 2 | 1–5 | Bahar, yaz, güz | Su birikintisi, çamur |
| `downpour` | Sağanak / Downpour | ıslak | 3 | 0,5–2 | Yaz; yağmurun ya da fırtınanın içinden | Görüş 70 m, sesi örter |
| `thunderstorm` | Gök Gürültülü Fırtına / Thunderstorm | fırtına | 3 | 1–2,5 | Yaz öğleden sonra (13–19) | Şimşek, yıldırım, bora önü, içinde dolu ya da sağanak |
| `dry_storm` | Kuru Fırtına / Dry Storm | fırtına | 3 | 1–2 | Gobi, Alaşan, Ordos yazı | Şimşek var, yağmur yok: yangın havası |
| `hail` | Dolu / Hail | fırtına | 4 | 0,15–0,4 (22–60 sn) | Yalnız gök gürültülü fırtınanın içinde | Sığınak ister; saz çatı, kurutma rafı, tarla |
| `wind` | Rüzgâr / Wind | kuru | 1 | 2–8 | Bahar, Gobi, öğleden sonra | Çim yatar, duman yatay, ok sürüklenir |
| `gale` | Fırtına / Gale | fırtına | 3 | 1–6 | Bahar, kış | 16 m/sn; çadır, raf, taşsız ateş |
| `sleet` | Sulu Kar / Sleet | ıslak | 2 | 1–3 | Bahar, güz geçişi | Yağmur ve kar birlikte |
| `snow` | Kar / Snow | ıslak | 1 | 2–8 (kampta 1–3) | Kış; kampta seyrek serpinti | Taze kar, iz kısalır, ses yutulur |
| `heavy_snow` | Yoğun Kar / Heavy Snow | ıslak | 3 | 1–4 | Kış | Görüş 90 m, araba yavaş |
| `blizzard` | Tipi / Blizzard | fırtına | 4 | 2–6 | Kış; yalnız kar ya da yoğun kardan sonra | Yatay kar, görüş 40 m, iz 15 sn |
| `dust_storm` | Toz Fırtınası / Dust Storm | fırtına | 4 | 1–4 | Bahar: en sık Gobi, Alaşan, Hexi, Ordos; açık bozkır satırlarında seyrek (`steppe_south`, `daibei`, `orkhon`, `kerulen`, `hangai`: Moğol baharının toz yolu); kampın kuytu göl vadisinde (`camp_*` satırları) yok | Sarı duvar, görüş 40 m, iz silinir |
| `kara_boran` | Kara Boran / Black Blizzard | fırtına | 4 | Hikâye | Yalnız `act1.md` §10 (Gün VI) | Tipinin karanlık hâli; kör rüzgâr, kara sağanak |

`blizzard` genel tipidir (II. Perde'den kış satırlarında); `kara_boran` I. Perde'nin tek kovalamacasıdır ve yalnız hikâye kilidiyle gelir. İkisi aynı kuralları paylaşır (`fx.blizzard = true`), Kara Boran'ın görüş, sis ve derece değerleri act1 §10'dan gelir.

### 3.2 Alt olaylar

Bölümün içinde gerçek saniyeyle zamanlanır; tohum bölümün tohumundan türer (§5.5).

| id | TR / EN | Kimin içinde | Sıklık, süre | Ne yapar |
|---|---|---|---|---|
| `flash` | Şimşek / Lightning Flash | `thunderstorm`, `dry_storm` | Hücre uzakken 2/gdk, tepedeyken 5/gdk; fırtına başına ortalama 15 | Pozlama, yarımküre ve gök nabzı (§9.6); gece görüşünü 0,25 sn açar (§8.3) |
| `strike` | Yıldırım / Lightning Strike | Aynı | Şimşeklerin %30'u; fırtına başına 4,6; fırtınaların %35'inde biri ≤600 m'de | Şerit, çatırtı, hedef kuralı (§8.7) |
| `thunder` | Gök Gürültüsü / Thunder | Her şimşekten sonra | `d / 343` sn gecikme; ≤10 km duyulur | Ses ve gürültü maskesi (§8.3); at ürkmesi (§8.9) |
| `gust` | Bora / Gust | `wind`, `gale`, `thunderstorm`, `blizzard`, `dust_storm` | 20–60 sn'de bir, 3–6 sn | Rüzgâr ×1,6; çim dalgası, duman kırılması, `gust` sesi |
| `gust_front` | Fırtına Önü / Gust Front | `thunderstorm`, `dry_storm` başı | İlk 0,1 sa (15 sn) | Rüzgâr 16 m/sn, toz, yön dönüşü: fırtınanın son işareti |
| `hail_burst` | Dolu Sağanağı / Hail Burst | `thunderstorm` | Fırtınaların %10–30'u (iklim satırı `pHail`); 0,15–0,4 sa | Bölüm `hail`'e geçer, sonra fırtınaya döner; %30'u iri dolu |
| `squall` | Kara Sağanak / Black Squall | `kara_boran` | `erlik_choice=refuse` ise 2 adet (act1 §8.5), 25 sn, aralarında ≥40 sn | Görüş 20 m, rüzgâr +6, ışık ×0,6 |
| `whiteout` | Kör Rüzgâr / Blind Wind | `kara_boran` T4 (act1 §10) | 40–60 sn, bir kez | Görüş 15 m, ortamda yalnız kemik sesi |

### 3.3 Parametre vektörü

Her tür aşağıdaki vektörün bir satırıdır (`data/weather-types.js`). Planlayıcı bölümün türünü verir; görünen ve oynanan her şey bu vektörün karışımından okunur.

```js
WeatherParams = {
  cloud,                                           // gök örtüsü 0..1: lightLevel, moonSeen, gece sınıfı (§3.4 sütunu)
  cover, coverSky, shadowK, cloudSpeedK, dark,     // bulut görünümü: zemindeki gölge eşiği kaydırması, kubbe eşiği, gölge gücü, hız, karanlık
  sunK, hemiK, expK,                               // ışık çarpanları
  fogNearK, fogFarK, fogTint, fogMix,              // sis
  sat, con, tone,                                  // derece (post.weather, §9.2)
  rain, snow, hail, dust,                          // ekran yağışı 0..1 (§9.3)
  points, splashes,                                // 3B nokta ve sıçrama sayısı (§9.4, §9.5)
  wind, gust,                                      // m/sn ortalama ve bora
  vis, mask,                                       // görüş m, ses maskesi
  wetGround, wetFelt, snowRate,                    // sa⁻¹: ıslanma ve kar örtüsü hızı
  storm,                                           // 0..1 şimşek hızının çarpanı
};
```

### 3.4 Görsel tanım

Çarpanlar ışık düzeninin (K20 saati) tabanına uygulanır (§9.2). Sis çarpanından sonra kamera tabanı gelir: yakın ≥ 0,5 × kamera uzaklığı, uzak ≥ kamera uzaklığı + 50 m (Kara Boran ve Tipi act1 değerini kullanır, oyuncuyu `ghost` izi okutur).

| Tür | Örtü zemin / kubbe | Gölge × | Bulut hızı × | Güneş × | Yarımküre × | Pozlama × | Sis yakın × / uzak × | Sis rengi, karışım | Doygunluk ×, karşıtlık ×, ton | Ekran yağışı y/k/d/t | 3B nokta | Sıçrama | Kubbe karanlığı |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `clear` | 0 / 0 | 1 | 1 | 1 | 1 | 1 | 1 / 1 | · | 1, 1, nötr | 0 | 0 | 0 | 0 |
| `cloud` | 0,06 / 0,05 | 1,4 | 1,3 | 1 | 1 | 1 | 1 / 1 | · | 1, 1, nötr | 0 | 0 | 0 | 0 |
| `overcast` | 0,2 / 0,3 | 0,25 | 0,8 | 0,3 | 0,92 | 1,12 | 0,9 / 0,8 | `#9aa6b2` 0,3 | 0,9, 0,96, (0,98; 0,99; 1,02) | 0 | 0 | 0 | 0,25 |
| `fog` | 0,1 / 0,2 | 0,2 | 0,3 | 0,45 | 1 | 1,05 | 0,04 / 0,07 | `#b9c3c9` 0,7 | 0,82, 0,88, (1; 1; 1,02) | 0 | 0 | 0 | 0,1 |
| `drizzle` | 0,18 / 0,28 | 0,3 | 1 | 0,3 | 0,85 | 1,1 | 0,7 / 0,55 | `#94a0ac` 0,4 | 0,88, 0,95, (0,98; 0,99; 1,03) | 0,25/0/0/0 | 0 | 32 | 0,3 |
| `rain` | 0,2 / 0,32 | 0,25 | 1,3 | 0,2 | 0,75 | 1,1 | 0,5 / 0,35 | `#8794a1` 0,5 | 0,82, 0,94, (0,97; 0,99; 1,04) | 0,6/0/0/0 | 0 | 96 | 0,4 |
| `downpour` | 0,22 / 0,35 | 0,2 | 1,6 | 0,1 | 0,62 | 1,05 | 0,3 / 0,15 | `#7b8794` 0,6 | 0,75, 0,92, (0,96; 0,99; 1,05) | 1/0/0/0 | 0 | 192 | 0,55 |
| `thunderstorm` | 0,22 / 0,33 | 0,5 | 2,2 | 0,12 | 0,55 | 1 | 0,4 / 0,25 | `#5f6b78` 0,6 | 0,78, 1,05, (0,95; 0,98; 1,06) | 0,75/0/0/0 (sağanakta 1) | 0 | 128 | 0,75 |
| `dry_storm` | 0,12 / 0,15 | 1,5 | 2,5 | 0,4 | 0,8 | 1 | 0,9 / 0,7 | `#a39a8a` 0,4 | 0,9, 1,04, (1,02; 0,98; 0,96) | 0/0/0/0,25 | 600 toz | 0 | 0,45 |
| `hail` | 0,22 / 0,35 | 0,3 | 2,5 | 0,1 | 0,6 | 1 | 0,3 / 0,12 | `#6c7a72` 0,6 (yeşile çalar) | 0,75, 1, (0,96; 1,02; 1) | 0,3/0/1/0 | 1500 dolu | 128 sekme | 0,8 |
| `wind` | 0,03 / 0,02 | 1,2 | 3 | 1 | 1 | 1 | 1 / 0,9 | · | 1, 1, nötr | Kuru iklimde 0/0/0/0,15 | Kuru iklimde 600 toz | 0 | 0 |
| `gale` | 0,08 / 0,08 | 1,3 | 4 | 0,8 | 0,9 | 1 | 0,8 / 0,5 | `#a8a49a` 0,3 | 0,95, 1,02, nötr | Kuru iklimde 0/0/0/0,3 | Kuru iklimde 1200 toz | 0 | 0,2 |
| `sleet` | 0,2 / 0,3 | 0,25 | 1,4 | 0,2 | 0,8 | 1,1 | 0,5 / 0,3 | `#9aa4ae` 0,5 | 0,82, 0,94, (0,97; 0,99; 1,04) | 0,4/0,4/0/0 | 1500 ıslak kar | 64 | 0,4 |
| `snow` | 0,2 / 0,3 | 0,25 | 1 | 0,25 | 0,95 | 1,08 | 0,5 / 0,4 | `#c8d0d8` 0,6 | 0,86, 0,95, (0,98; 0,99; 1,03) | 0/0,5/0/0 | 3000 | 0 | 0,2 |
| `heavy_snow` | 0,22 / 0,34 | 0,2 | 1,3 | 0,15 | 0,85 | 1,08 | 0,3 / 0,15 | `#d0d6dc` 0,7 | 0,8, 0,92, (0,97; 0,99; 1,04) | 0/1/0/0 | 6000 | 0 | 0,35 |
| `blizzard` | 0,22 / 0,35 | 0,15 | 4 | 0,1 | 0,8 | 1,05 | 0,1 / 0,1 | `#b9c6d8` 0,8 | 0,655, 0,9, (0,98; 0,98; 1,03) | 0/1 yatay/0/0 | 6000 yatay | 0 | 0,4 |
| `kara_boran` | 0,22 / 0,35 | 0,15 | 4 | 0,06 | 0,55 | 1 | act1 §10: 140 m, Ak Otlak 45–80 m | `#3e4858` 0,85 | Hikâye `blizzard` profili, katman nötr | 0/1 yatay, koyu | 6000 yatay | 0 | 0,85 |
| `dust_storm` | 0,1 / 0,1 | 0,4 | 4 | 0,25 | 0,7 | 1,05 | 0,1 / 0,08 | `#b38b5d` 0,8 | 0,8, 0,95, (1,06; 0,98; 0,86) | 0/0/0/1 | 2000 toz | 0 | 0,3 + toz |

**Gök örtüsü (`cloud`).** `cover` ve `coverSky` görsel eşik kaydırmalarıdır (en çok 0,35); gökyüzünün kaçta kaçının örtülü olduğunu `cloud` söyler ve ışığı yalnız o okur:

| Tür | `cloud` | Tür | `cloud` | Tür | `cloud` |
|---|---|---|---|---|---|
| `clear` | 0 | `downpour` | 1 | `sleet` | 0,9 |
| `cloud` | 0,35 | `thunderstorm` | 1 | `snow` | 0,85 |
| `overcast` | 0,9 | `dry_storm` | 0,6 | `heavy_snow` | 1 |
| `fog` | 0,7 | `hail` | 1 | `blizzard`, `kara_boran` | 1 |
| `drizzle` | 0,9 | `wind` | 0,1 | `dust_storm` | 0,8 |
| `rain` | 0,9 | `gale` | 0,3 | | |

Karışımda öteki parametreler gibi yumuşar; kilit `params.cloud` yazabilir. `fx.cloud` karışmış değerdir; `moonSeen = gece && ay ufkun üstünde && cloud < 0,6 && yağış ve sis yok`. Kapalı gecede ay ışığı yoktur: `lightLevel` aysız tabana (≈0,08) iner.

**Neden bu sayılar.** Kampın taban sis uzağı 1400 m: yağmurda 490 m, sağanakta 210 m, siste 98 m (kamera tabanıyla yakın 16,5 m; kamera 33 m'deyken oyuncu %20 sisli, kadraj tepesi tam sisli). Tipi sisi act1 §10'un mutlak değeridir: «Sis Tipi başında 140 m»; 1400 m'lik tabanda `blizzard` çarpanı (0,1) da 140 m verir, Kışlak'ın kendi ışık duraklarında tür değeri mutlak 140 m'ye kıstırılır. `blizzard` doygunluğu 0,655 × 1,1 (`POST_DEFAULTS`) = 0,72, ton (0,98; 0,98; 1,03): act1 §10 derecesiyle bit bit aynıdır. Kara Boran'da derece hikâyenin `post.applyProfile('blizzard')` çağrısındadır; katman nötr kalır ki iki kez uygulanmasın. Fırtınada pozlama telafisi yoktur: karanlık, şimşeğin parlaması için gereklidir.

### 3.5 Ses tanımı

`windGain(w) = clamp(0,45 + w/8; 0,4; 1,6)` taban rüzgâr döngüsünün (`wind_steppe`, kışta `wind_winter`) çarpanıdır; 11 m/sn üstünde `wind_gale`'e çapraz geçer. Yeni döngüler ve efektler §10.

| Tür | Ortam (kazanç) | Taban rüzgâr × | Müzik `rain` katmanı | Tek seferlik |
|---|---|---|---|---|
| `clear`, `cloud` | Taban (`app/sounds.js`) | `windGain` | 0 | · |
| `overcast` | Taban; `birds_day` ×0,5 | `windGain` | 0 | · |
| `fog` | Taban ×0,7 (uzak boğulur), `camp_day` ×0,6 | 0,5 | 0 | `rain_drip` 8–20 sn |
| `drizzle` | `rain_light` 0,45 | `windGain` | 0,35 | `rain_drip` |
| `rain` | `rain_light` 0,7, `rain_heavy` 0,3; yurt ≤12 m'deyse `rain_felt` 3B | `windGain` | 0,2 | · |
| `downpour` | `rain_heavy` 1 | ×0,8 | 0 | · |
| `thunderstorm` | `rain_heavy` 0,8, `wind_gale` 0,3 | `windGain` | 0 | `thunder_crack`, `thunder`, `thunder_far`, `gust`, `static_hum` |
| `dry_storm` | `wind_gale` 0,6 | `windGain` | 0 | Gök gürültüleri, `gust` |
| `hail` | `hail_bed` 1, `rain_heavy` 0,4; yurt içinde `rain_felt` yerine `hail_bed` boğuk | ×0,8 | 0 | `hail_tick` 3B |
| `wind` | Taban | `windGain` | 0 | `gust` |
| `gale` | `wind_gale` 1; taban söner | · | 0 | `gust`; kapı keçelerinde `felt_flap` |
| `sleet` | `rain_light` 0,6 | `windGain` | 0,15 | · |
| `snow` | Taban ×0,8 (kar sesi yutar) | ×0,7 | 0,15 | · |
| `heavy_snow` | Taban ×0,6 | ×0,8 | 0,1 | · |
| `blizzard` | `blizzard` 1 | · | 0 | `gust` |
| `kara_boran` | `blizzard` 1; T4 kör rüzgârda yalnız `bone_hum` | · | 0 (müzik `chase`, act1) | `gust` |
| `dust_storm` | `dust_storm` 1, `wind_gale` 0,4 | · | 0 | `gust` |
| Yağmur sonrası (çözülme bölümü) | Taban + `rain_drip` | `windGain` | 0,45, 0,5 sa'te söner | `rain_drip` |

## 4. İklim tabloları

### 4.1 Dünya → iklim

Her `WorldSpec` bir iklim satırı seçer (`spec.weather.climate`, §12.3). Atlas yolları uç dünyalarının ikliminden okunur (§8.10).

| Dünya (`travel.md` ZONES) | İklim | Mevsim kaynağı | Not |
|---|---|---|---|
| `tanhu_camp` (Serbest Gez) | `orkhon` | (K67 ile değişti) Takvim; kampın dört satırı: bahar `camp_spring` (Göl Vadisi baharı), yaz `camp_summer`, güz `camp_autumn`, kış `camp_winter` | Serbest Gez 11 Nisan MÖ 209'da açılır, mevsim takvimle döner: yaz 15 Mayıs (34 gerçek saat sonra), güz 23 Ağustos (134), kış 16 Kasım (219) (`time.md` §5.5). Eski kural kampı +7,42° sapmaya, yani bahara iğneliyordu; K67 ile yalnız açılış dakikası iğnelidir. `camp_*` bir iklim satırıdır: mevsimi takvim verir, satırı kamp spec'i seçer. Kampın yeşil, kuytu göl vadisi baharda açık bozkırdan yağışlıdır, ilk sağanaklar ve gök gürültüsü burada başlar (oyunun her havayı gösterdiği yer). Kuytu vadide toz fırtınası yoktur (`camp_*` satırlarında toz 0, payı rüzgâra). K9 sürücüsünün bahar satırı vadi dışındaki geçitler içindir; kampta bahar serpintisi tutmaz, kışın kar tutar (§5.9) |
| `tanhu_camp` (`home`, K7) | `orkhon` | Hikâye: `home_spring` kilidi | Açık, kuru, kimlik (§6.3) |
| `childhood_ordos` (Çocukluk, K36) | `ordos` | Hikâye: `a0_childhood` kilidi (22 Eylül MÖ 228) | Açık, rüzgâr 2 m/sn, ot sarı (`story.md` §5); Önsöz'ün doğum sahnesi aynı dünyada hava okumaz, ışığı sabit örnektir |
| `depart_yurt` (Yola Çıkış, K36) | `orkhon` | Hikâye: `a0_depart` kilidi (15 Aralık MÖ 213) | Kış şafağından önce kapalı gök, yağış yok, karlı avlu (§6.3) |
| `longcheng` | `orkhon` | Takvim; 5. ay toplantısı yaz satırında | Shiji 110: 五月，大會蘢城 |
| `hexi_winter` (I. Perde) | `hexi` | Sabit `winter`; `exclude: ['heavy_snow', 'blizzard']` | Yoğun kar ve tipi yalnız hikâyeyle gelir: Kara Boran'ın gücü çalınmaz |
| `hexi_ash` (IV. Perde) | `hexi` | Takvim | |
| `whistle_field` | `gobi` | Takvim | Islık Ovası Gobi yolundadır (`r_tanhu_whistle`) |
| `tanhu_ordu` | `steppe_south` | Takvim | [112,8; 43,5]: Şilin Gol bozkırı |
| `donghu_land` | `kerulen` | Takvim | Tula, Kerulen |
| `ordos` | `ordos` | Takvim | |
| `mayi`, `baideng` | `daibei` | Takvim; Baideng kilidi | Shiji 110 kar kaydı (§6.4) |
| `hangai` | `hangai` | Takvim | |
| `dingling_north` (seçmeli) | `hangai` | Takvim | Selenga, Hövsgöl: aynı satır, daha yağışlı ise II. turda ayrılır |
| `loulan` (seçmeli) | `alashan` | Takvim | Dunhuang yolu: aşırı kurak satır |

**Mevsim.** Takvim yalnız dört anahtar verir: `spring`, `summer`, `autumn`, `winter` (`econ-model.json` `params.seasonDays` ile aynı). Kampın dört satırı (`camp_spring`, `camp_summer`, `camp_autumn`, `camp_winter`) yalnız kampındır: mevsimi takvim verir, satırı kamp spec'i seçer (`seasonRows`, §12.3); açık bozkırın Nisan'ı `orkhon` bahar satırıdır. Perdelerin varsayılan mevsimi ekonomi taslağının `params.actSeason` tablosudur (II yaz, III güz, IV yaz, V kış, VI yaz); perde sahneleri kilitle başka mevsim isteyebilir.

### 4.2 Paylar

Hücre değeri o iklim ve mevsimde zamanın yüzde kaçının o türde geçtiğidir (hedef pay; satır toplamı 100). `GGF` gök gürültülü fırtına, `Kuru F.` kuru fırtına. Dolu ayrı pay almaz: fırtınaların `pHail` kadarında dolu sağanağı açılır (§5.4). Son sütun: ayarlı ağırlıklarla 4000 günlük benzetimde hedeften en büyük sapma, puan (§5.6, §19).

**`orkhon`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 38 | 20 | 8 | 2 | 2 | 3 | · | 0,5 | 0,5 | 14 | 4 | 1,5 | 2 | 0,5 | · | 4 | 0,1 | 0,72 (`clear`) |
| Kamp baharı (Göl Vadisi, `camp_spring`) | 31 | 25 | 10 | 3 | 4 | 7 | 1,5 | 3,5 | 1 | 10 | 2,5 | 0,5 | 1 | · | · | · | 0,25 | 0,24 (`clear`; toz → rüzgâr değişiminden önceki koşu, W2 yeniden ölçer) |
| Yaz | 29 | 26 | 11 | 4 | 4 | 10 | 3 | 5 | 1 | 5 | 1,5 | · | · | · | · | 0,5 | 0,25 | 0,74 (`cloud`) |
| Kamp yazı (`camp_summer`, K67) | 29 | 26 | 11 | 4 | 4 | 10 | 3 | 5 | 1 | 5,5 | 1,5 | · | · | · | · | · | 0,25 | W2 ölçer |
| Güz | 45 | 20 | 10 | 5 | 2 | 3 | · | 0,5 | · | 8 | 2 | 1,5 | 2,5 | 0,5 | · | · | 0,1 | 0,41 (`cloud`) |
| Kamp güzü (`camp_autumn`, K67) | 45 | 20 | 10 | 5 | 2 | 3 | · | 0,5 | · | 8 | 2 | 1,5 | 2,5 | 0,5 | · | · | 0,1 | W2 ölçer |
| Kış | 51,5 | 16 | 10 | 6 | · | · | · | · | · | 5 | 2 | 0,5 | 6 | 1,5 | 1,5 | · | · | 0,52 (`clear`) |
| Kamp kışı (`camp_winter`, K67) | 51,5 | 16 | 10 | 6 | · | · | · | · | · | 5 | 2 | 0,5 | 6 | 1,5 | 1,5 | · | · | W2 ölçer |

**Kampın yaz, güz ve kış satırları (K67).** Göl vadisinin farkı baharda belirgindir: ilk sağanaklar, ilk gök gürültüsü, toz yok. Yaz, güz ve kışta açık Orhun'un payları vadiye zaten uyar; tek fark kuytu vadide toz olmamasıdır, yazın 0,5 puanlık toz rüzgâra geçer. Kampın kışında tipi kalır: Serbest Gez'de tehdit yoktur, Çocuk ve halk sığınır (§8.12, §8.15). Kampta kar serpintisinin 1–3 sa süresi yalnız bahardadır (`dur`, §12.3).

**`hexi`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 34 | 18 | 8 | 1 | 2 | 2 | · | 0,5 | 0,5 | 16 | 5 | 1 | 1 | · | · | 11 | 0,15 | 0,77 (`clear`) |
| Yaz | 36 | 24 | 9 | 2 | 3 | 6 | 2 | 5 | 2 | 7 | 2 | · | · | · | · | 2 | 0,3 | 0,40 (`cloud`) |
| Güz | 50 | 20 | 9 | 4 | 2 | 2 | · | · | · | 8 | 2 | 1 | 1 | · | · | 1 | · | 0,41 (`cloud`) |
| Kış | 44 | 22 | 11 | 5 | · | · | · | · | · | 9 | 2 | · | 5 | 1 | 1 | · | · | 0,32 (`wind`) |

**`gobi`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 40 | 14 | 5 | · | 0,5 | 1 | · | 0,5 | 1 | 16 | 7 | 0,5 | 1 | · | · | 13,5 | 0,1 | 0,28 (`clear`) |
| Yaz | 52 | 20 | 5 | · | 1 | 2 | 1,5 | 3 | 4 | 7 | 2 | · | · | · | · | 2,5 | 0,15 | 0,62 (`cloud`) |
| Güz | 58 | 16 | 6 | 1 | 1 | 1 | · | · | · | 9 | 3 | · | 1 | · | · | 4 | · | 0,36 (`clear`) |
| Kış | 58 | 14 | 8 | 3 | · | · | · | · | · | 7 | 3 | · | 4 | 1 | 2 | · | · | 0,63 (`snow`) |

**`alashan`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 42 | 12 | 4 | · | · | 0,5 | · | · | 0,5 | 16 | 7 | · | · | · | · | 18 | · | 0,41 (`cloud`) |
| Yaz | 62 | 16 | 3 | · | · | 1 | 1 | 1 | 3 | 8 | 2 | · | · | · | · | 3 | 0,1 | 1,34 (`clear`) |
| Güz | 66 | 14 | 4 | · | · | 0,5 | · | · | · | 9 | 2,5 | · | · | · | · | 4 | · | 0,38 (`clear`) |
| Kış | 64 | 12 | 6 | 1 | · | · | · | · | · | 8 | 3 | · | 2 | · | · | 4 | · | 0,58 (`clear`) |

**`ordos`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 38 | 18 | 7 | 1 | 2 | 3 | · | 0,5 | 0,5 | 14 | 5 | 1 | 1 | · | · | 9 | 0,1 | 0,20 (`wind`) |
| Yaz | 33 | 25 | 9 | 2 | 3 | 8 | 3 | 6 | 2 | 6 | 1,5 | · | · | · | · | 1,5 | 0,2 | 0,39 (`cloud`) |
| Güz | 48 | 20 | 10 | 4 | 3 | 4 | · | 0,5 | · | 6 | 1,5 | 1 | 1 | · | · | 1 | 0,1 | 0,50 (`clear`) |
| Kış | 49,5 | 16 | 10 | 5 | · | · | · | · | · | 7 | 3 | 0,5 | 6 | 1 | 1 | 1 | · | 0,36 (`clear`) |

**`steppe_south`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 36 | 18 | 8 | 1 | 2 | 3 | · | 0,5 | 0,5 | 15 | 6 | 1 | 1,5 | 0,5 | · | 7 | 0,1 | 0,68 (`cloud`) |
| Yaz | 32 | 25 | 9 | 2 | 3 | 9 | 3 | 6 | 1,5 | 6 | 2 | · | · | · | · | 1,5 | 0,25 | 0,46 (`clear`) |
| Güz | 48 | 19 | 10 | 4 | 3 | 3 | · | · | · | 7 | 2 | 1 | 2 | · | · | 1 | · | 0,18 (`snow`) |
| Kış | 49,5 | 14 | 10 | 4 | · | · | · | · | · | 6 | 4 | 0,5 | 7 | 2 | 3 | · | · | 0,26 (`cloud`) |

**`kerulen`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 37 | 19 | 9 | 2 | 2 | 3 | · | 0,5 | 0,5 | 14 | 5 | 1,5 | 2 | 0,5 | · | 4 | 0,1 | 0,33 (`cloud`) |
| Yaz | 29 | 26 | 11 | 4 | 4 | 10 | 3 | 6 | 1 | 4 | 1,5 | · | · | · | · | 0,5 | 0,2 | 0,36 (`clear`) |
| Güz | 46 | 19 | 11 | 5 | 3 | 3 | · | · | · | 6 | 2 | 1,5 | 2,5 | 0,5 | · | 0,5 | · | 0,47 (`overcast`) |
| Kış | 51,5 | 13 | 9 | 5 | · | · | · | · | · | 5 | 3 | 0,5 | 8 | 2,5 | 2,5 | · | · | 0,41 (`snow`) |

**`hangai`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 32 | 22 | 10 | 3 | 3 | 4 | · | 0,5 | 0,5 | 11 | 4 | 2 | 4 | 1 | · | 3 | 0,1 | 0,84 (`overcast`) |
| Yaz | 24 | 26 | 12 | 6 | 5 | 11 | 3 | 7 | 0,5 | 4 | 1 | · | 0,5 | · | · | · | 0,3 | 0,59 (`wind`) |
| Güz | 38 | 20 | 12 | 7 | 3 | 4 | · | · | · | 6 | 2 | 2 | 5 | 1 | · | · | · | 0,49 (`wind`) |
| Kış | 45,5 | 14 | 11 | 7 | · | · | · | · | · | 4 | 3 | 0,5 | 9 | 3 | 3 | · | · | 0,52 (`snow`) |

**`daibei`**

| Mevsim | Açık | Bulut | Kapalı | Sis | Çisenti | Yağmur | Sağanak | GGF | Kuru F. | Rüzgâr | Fırtına | Sulu kar | Kar | Yoğun kar | Tipi | Toz | `pHail` | Gerçekleşen en büyük sapma |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 36 | 20 | 9 | 2 | 3 | 4 | · | 0,5 | 0,5 | 12 | 4 | 1 | 1 | · | · | 7 | 0,1 | 0,73 (`clear`) |
| Yaz | 26 | 24 | 12 | 4 | 5 | 12 | 4 | 8 | 0,5 | 3 | 1 | · | · | · | · | 0,5 | 0,2 | 0,46 (`clear`) |
| Güz | 46 | 20 | 11 | 6 | 4 | 4 | · | 0,5 | · | 5 | 1,5 | 1 | 1 | · | · | · | 0,1 | 0,79 (`clear`) |
| Kış | 48 | 14 | 12 | 6 | · | · | · | · | · | 5 | 3 | 0,5 | 7 | 2,5 | 2 | · | · | 0,60 (`cloud`) |

**Kış sulu karı.** `orkhon`, `ordos`, `steppe_south`, `kerulen` ve `hangai` kış satırlarına %0,5 sulu kar eklendi (açıktan alındı; son sütun eski koşunun sapmasıdır, W2 yeniden ölçer): kış sonu sulu karı Kar Kabuğu'nun iki yolundan biridir (§5.9).

**I. Perde Kışlak satırı.** `hexi` kışından `heavy_snow` ve `blizzard` dışlanır, kalan 98 puan 100'e ölçeklenir: açık 44,9, bulut 22,4, kapalı 11,2, sis 5,1, rüzgâr 9,2, fırtına 2,0, kar 5,1 (benzetimde en büyük sapma 0,58). Hikâye kilitleri (§6.2) günlerin büyük bölümünü zaten sabitler; serbest saatler bu satırla akar.

**Neden böyle.** Orhun ve Hangay yağışının ≈%70'i yaz aylarındadır, öğleden sonra kümülüs ve dolu gelir; bahar rüzgâr ve tozdur, kış Sibirya yüksek basıncı altında açık ve durgundur. Hexi Koridoru baharda tozun yoludur (toz 11), kışın kuru ve rüzgârlıdır. Gobi ve Alaşan'da kuru fırtına ıslak fırtınadan sık, toz en büyük tehlikedir. Daibei (Pingçeng) yaz musonunun kıyısıdır: en yağışlı yaz satırı. Paylar oynanış için yuvarlanmıştır; gerçek iklim istatistiği değildir, yön ve sıra doğrudur.

### 4.3 Gün içi eğriler

Seçim ağırlığı türün eğrisiyle çarpılır; eğrilerin gün ortalaması 1'dir (normalleştirilir), paylar bu yüzden değişmez, yalnız saat dağılımı değişir.

| Eğri | Türler | 0–3 | 4–8 | 9 | 10–11 | 12–18 | 19–21 | 22–23 |
|---|---|---|---|---|---|---|---|---|
| `conv` (kümülüs) | `thunderstorm`, `dry_storm`, `downpour` | 0,24 | 0,24 | 0,76 | 0,76 | 2,18 | 1,14 | 0,47 |
| `fog` | `fog` | 1,15 | 3,35 | 0,96 | 0 | 0 | 0 (21'de 0,57) | 0,57 |
| `wind` | `wind`, `gale`, `dust_storm` | 0,5 | 0,5 (7–8: 0,9) | 0,9 | 0,9 (11: 1,6) | 1,61 | 0,8 | 0,8 |
| `flat` | Ötekiler | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

Sis 10:00'dan sonra başlamaz ve en geç 10:00'da dağılır (bölüm kısaltılır): sabahın türüdür.

### 4.4 Hâkim rüzgâr

Rüzgârın geldiği yön (meteoroloji) derece, kuzey 0, saat yönünde; oyundaki akış vektörü bunun tersidir (x doğu, z güney). Bölüm başında `yön = hâkim ± 40°` (tohumlu); cephe hazırlığında yön 30–60° döner (işaret, §7). Kampın bugünkü `U.uWindDir` (0,8; 0,45) değeri batı-kuzeybatıdan esen rüzgârdır (≈299°), `orkhon` hâkimiyle aynı yöndedir: menü görüntüsü bu yüzden değişmez.

| İklim | Hâkim | Mevsim farkı |
|---|---|---|
| `orkhon`, `kerulen`, `hangai` | 290° (BKB) | Yazın fırtınalar batıdan |
| `hexi` | 315° (KB) | Baharda toz batı-kuzeybatıdan |
| `gobi`, `alashan`, `ordos`, `steppe_south` | 315° (KB) | Yazın güneydoğu yeli 135°, %30 |
| `daibei` | 320° (KB) kış; 135° (GD) yaz | Muson |

### 4.5 Oyunda ne görülür (60 dakikalık gün, benzetim)

| Satır | Değişim | Gerçek dakika / 60 dk'lık gün |
|---|---|---|
| Kamp baharı, `orkhon` `camp_spring` | Günde ≈9,4 bölüm, ≈6,4 gdk'da bir | Hedef paydan (ayarlı benzetim ±1,5 puan içinde tutar, W2): açık 18,6 · bulut 15,0 · kapalı 6,0 · sis 1,8 · çisenti 2,4 · yağmur 4,2 · sağanak 0,9 · GGF 2,1 · kuru fırtına 0,6 · rüzgâr 6,0 · fırtına 1,5 · sulu kar 0,3 · kar 0,6 · dolu fırtınanın içinden; toz yok (kuytu vadi). İlk Serbest Gez'de camp3'ün ocağı yanana dek `sev` ≥3 türler yoktur (§6.3) |
| Kamp yazı, `camp_summer` | Bölüm sayısı W2 ölçer | Hedef paydan: açık 17,4 · bulut 15,6 · kapalı 6,6 · sis 2,4 · çisenti 2,4 · yağmur 6,0 · sağanak 1,8 · GGF 3,0 · kuru fırtına 0,6 · rüzgâr 3,3 · fırtına 0,9; dolu fırtınanın içinden (`pHail` 0,25); ıslak ≈13,2 gdk |
| Kamp güzü, `camp_autumn` | Bölüm sayısı W2 ölçer | Açık 27,0 · bulut 12,0 · kapalı 6,0 · sis 3,0 · çisenti 1,2 · yağmur 1,8 · GGF 0,3 · rüzgâr 4,8 · fırtına 1,2 · sulu kar 0,9 · kar 1,5 · yoğun kar 0,3 |
| Kamp kışı, `camp_winter` | Bölüm sayısı W2 ölçer | Açık 30,9 · bulut 9,6 · kapalı 6,0 · sis 3,6 · rüzgâr 3,0 · fırtına 1,2 · sulu kar 0,3 · kar 3,6 · yoğun kar 0,9 · tipi 0,9; derin kar günü payı ≈%6,7 (§5.9; K49 ile değişti, eski ≈%6,6) |
| Kışlak, `hexi` I. Perde | Günde 4,9 bölüm, ≈12 gdk'da bir | Açık 27,2 · bulut 13,3 · kapalı 6,6 · sis 3,2 · rüzgâr 5,4 · fırtına 1,2 · kar 3,0 |
| Gobi baharı | 8,8 bölüm | Açık 23,8 · rüzgâr 9,6 · fırtına 4,1 · toz 8,1 … |
| Daibei kışı (Baideng öncesi) | 5,9 bölüm | Açık 28,9 · kar 4,3 · yoğun kar 1,5 · tipi 1,3 … |

Kamp baharında 60 dakikalık bir günün ≈10,5 dakikası ıslaktır; fırtına (gök gürültülü ya da kuru) ≈0,64/gün, yani ≈94 gdk'da bir; dolu sağanağı ≈8 oyun gününde bir; kar serpintisi ≈8 günde bir (kampta kar bölümü 1–3 sa, §5.2). Fırtınaların %60'ında kadraja bir yıldırım iner (§8.7). Hiçbir tür bir günü tek başına doldurmaz; en uzun tek bölüm açık havadır (en çok 12 sa = 30 gdk).

## 5. Planlayıcı

### 5.1 Bölüm

```js
Segment = { type, t0, t1, src: 'sim' | 'build' | 'clear' | 'story', front: null | { kind, to }, seed }
// t0, t1: hourAbs. src 'build' cephe hazırlığı, 'clear' çözülme; ikisi de bir tür taşır (kapalı, bulut, rüzgâr, kar)
```

Planlayıcı `plan` kuyruğunu en az 12 sa ileride tutar; kuyruk kısalınca sonuna bölüm ekler. Şu anki bölüm `plan[0]`'dır. Plan kayda girer (§12.7): işaretler ve gök okuma bu kuyruktan okur.

### 5.2 Seçim

Yeni hedef tür, şu anki türden sonra şu ağırlıkla seçilir:

```
w(j) = W[j] × D[eğri(j)][saat] / ortalamaSüre(j),   izinli(şu, j) değilse 0
```

`W` ayarlı ağırlıktır (§5.6), `D` gün içi eğri (§4.3); süreye bölmek uzun türlerin paydan fazla görünmesini önler (pay = sıklık × süre). Seçilen bölümün süresi `[min, max]` aralığında tohumla çekilir (§3.1); iklim satırı aralığı değiştirebilir (kampta kar 1–3 sa).

### 5.3 Cephe dizgesi

Hedef ıslak ya da fırtına grubundaysa ve şu anki tür kuru ya da sis ise önce **hazırlık**, hedeften sonra **çözülme** bölümü eklenir. Hedefin `sev`'i ≥3 ise şu anki tür ıslak olsa da (yağmurdan sağanağa, kardan yoğun kara) 0,75–1 sa'lik bir hazırlık bölümü girer: şu anki türün daha ağır gökli hâli ve işaretler; dolu sağanağı da fırtınanın içinde 0,75 sa önceden planlanır. Hazırlık bölümü kendi türünü taşır ama `front` alanı hedefi bilir: bulut kalınlaşır, rüzgâr döner, işaretler çalar (§7).

| Hedef | Hazırlık (sa) | Çözülme (sa) |
|---|---|---|
| `drizzle`, `rain`, `downpour`, `sleet`, `snow`, `heavy_snow` | `overcast` 1–2; sağanaklı satırlarda (`showery` 0,5–0,6) o olasılıkla `cloud` | `overcast` 0,5–1,5; sağanaklıda `cloud` |
| `thunderstorm`, `dry_storm` | `cloud` 1–1,5 (kule bulutu, uzak gök gürültüsü) | `cloud` 0,5–1 |
| `gale`, `dust_storm` | `wind` 0,5–1 | `wind` 0,5–1 |
| `blizzard` | `snow` 1–2 (zorunlu) | `overcast` 0,5–1,5 |

### 5.4 Kurallar

- `clear` ve `cloud` kendinden sonra yeniden seçilebilir (uzun açık dönem); öteki türler kendini izlemez.
- `hail` hedef olarak seçilmez: `thunderstorm` bölümünün `pHail` olasılığıyla ortasına (bölümün %40'ında) bir dolu sağanağı girer; yoksa %35 olasılıkla 0,5–1 sa sağanak (`downpour`) girer.
- `fog` yalnız `clear`, `cloud` ya da `overcast`'tan sonra ve saat 21:00–09:59 arasında başlar; 10:00'da biter.
- `blizzard` yalnız `snow`, `heavy_snow`, `gale`, `overcast`, `cloud` ya da `clear`'dan gelebilir; kardan gelmiyorsa önce `snow` hazırlığı eklenir.
- `exclude` listesindeki türün ağırlığı 0'dır; kalan hedef paylar 100'e ölçeklenir.
- Hikâye kilidi (§6) süresince planlayıcı bölüm eklemez; kilit kalkınca kilidin türünden devam eder (gerekiyorsa çözülme bölümü ekler).

### 5.5 Tohum ve belirlenim

```
çapa(zon)    = floor(hourAbs / 24) × 24 − 24         // zincir her zaman 'clear' ile bu saatten başlar ve olaysız ileri sarılır
seed(bölüm)  = hash32(journeySeed, zone, floor(t0 × 4))  // Serbest Gez: roam.weatherSeed; sıra sayısı tohuma girmez
rng          = mulberry32(seed)                       // Math.random kullanılmaz
altOlayZamanı = (hourAbs − t0) × 150                   // hava saati saniyesi: saatle durur (diyalog, Donuk Kamp), Yol Akışı k ile hızlanır
```

Aynı kayıt, aynı saat, aynı dünya her zaman aynı havayı ve aynı şimşek dizisini verir; zon zinciri yüklemede ya da dünyaya dönüşte sabit çapadan yeniden kurulduğu için 24 sa içinde geri dönen oyuncu aynı planı bulur. Varış lütfu (§5.7) zincirin üstüne kaplamadır, zinciri değiştirmez. Alt olayların zamanlaması bölüm tohumundan türeyen ikinci akıştır ve hava saati saniyesiyle sayılır: kayıtta yalnız `at` (oyun saati) tutulur, yüklemede sonraki yıldırım aynı andadır. Görsel devinim (yağmur düşüşü, bulut kayması) gerçek zamanla akar. `__tanhu.step` altında sınama belirlenimlidir; oyuncunun kare hızı olay sırasını değiştirmez.

### 5.6 Ayar (kalibrasyon)

Cephe parçaları kapalı ve bulut payını şişirir (yağmurlu satırda kapalı hedefin 2 puan üstüne çıkıyordu). Bu yüzden veri hedef payı taşır, ağırlık yükleyicide çözülür:

```
W ← hedef
8 tur:  pay ← benzet(W, 800 gün);  W[j] ← W[j] × (hedef[j] / pay[j])^0,8
```

Süre ≈45 ms (Node 24, prototip), dünya kurulurken bir kez, `climate:season:exclude` anahtarıyla oturum boyunca saklanır. Sınama 4000 günle ±1,5 puan ister (§15 W2). Yükleme süresi sorun olursa ağırlıklar `__tanhu.weather.calibrate()` çıktısıyla veriye gömülür ve sınama onları doğrular.

### 5.7 Dünya değişimi, atlas yolu

- **Varış.** Yeni dünyanın havası varış saatinde sabit çapalı zincirden kurulur (§5.5). Varış lütfu bir kaplamadır: ilk 1 sa (Hikâye 1,5) `sev` ≥3 bölüm başlamaz, ilk 0,5 sa işaret söylenmez; zincirde o saatte zaten sürmekte olan bir fırtına varsa Yol Kartı varışta «Fırtına sürüyor» / «The storm is still raging» yazar ve oyuncu sığınakta iner.
- **Dönüş.** Ayrılınan dünyanın havası saklanmaz (yerleşim ve ordugâh zonlarının kar örtüsü ve kabuğu `packs`'te kalır, saatte bir ilerler; `architecture.md` §3.24 `zoneAt`); zincir sabit çapadan yeniden kurulduğu için 24 sa içinde geri dönülürse aynı plan gelir.
- **Atlas yolculuğu.** Yolda dünya yoktur; havanın yüzü yol olaylarıdır (§8.10). Varış saati K20 saatiyle hesaplanır (`time.md` §10.6); bacak 24 saati aşarsa uzun atlamadır.

### 5.8 Karışım

Parametre vektörü bölüm sınırında `blendS` saniyede eski türden yenisine yumuşar (sine-in-out, kare başına ayırma yok): kuru↔kuru 40 sn, kuru↔gri 30 sn, ıslaklık başlangıcı 20 sn, ıslaktan çözülmeye 60 sn, fırtına önü (`gust_front`) 6 sn. Hazırlık bölümünde `cover` ve `dark` doğrusal değil üstel yükselir: son 0,25 sa'te iki katı hızla (fırtına "yaklaşıyor" okunur). Hikâye kilidi kendi `blend` değerini verir. Menüden Serbest Gez'e inişte hava kimlikten kayıttakine 2,4 sn'de, menüye dönüşte 1,7 sn'de karışır: saatin ışık süzülmesiyle aynı süreler (`time.md` §5.5).

### 5.9 Islaklık, çamur, kar örtüsü

Durum değişkenleri `wet` (0..1), saniyede bir tümleşir; uyku ve atlamada analitik çözülür (`x(t) = x∞ + (x0 − x∞)·e^(−kt)`): yağmurda zemin `k` 0,8 sa⁻¹ ile 1'e gider, 0,6'ya 1,15 sa'te varır (W8).

| Değişken | Artış | Azalış | Okuyan |
|---|---|---|---|
| `ground` zemin ıslaklığı | Türün `wetGround` hızı (§8.1), sa⁻¹ | Kuru türlerde gündüz −0,35, gece −0,12; rüzgâr ×1,5 | `U.uWet.x`, çamur, ıslak yakıt |
| `felt` keçe ıslaklığı | `wetFelt` hızı (keçe çabuk ıslanır) | Zeminin 0,6 katı (keçe yavaş kurur) | `U.uWet.y`, yapı sıçraması, yıldırım |
| `mud` çamur | `(ground − mud) × 0,5` sa⁻¹ | Aynı (gecikmeli izler) | Yol, araba, iz |
| `puddle` birikinti | `max(0, ground − 0,6) / 0,4` | · | `U.uWet.w`, Çocuğun su sıçratması |
| `snow` taze kar | Türün `snowRate` hızı | Yağış bitince −0,25 sa⁻¹ ("eski kara" döner); yaz satırında erir −1 sa⁻¹, yağmurda ×2 | `U.uWet.z`, iz, keçe sıçrama çarpanı |
| `bow` kiriş ıslaklığı | §8.8 | §8.8 | Ok hasarı ve menzil |

(K67 ile değişti) Kampta kar bahar, yaz ve güzde tutmaz (`accumulate.snow` bu mevsimlerde kapalı): serpinti zemini ve keçeyi ıslatır (zemin +0,2, keçe +0,3 sa⁻¹), örtü bırakmaz, çimde beyazlık yoktur. Kışın (16 Kasım–15 Mart) kampta kar tutar: `snowpack` `orkhon` kış satırıyla birikir (derin kar günü ≈%6,7, kabuk kış başına ≈0,29; `d2/weather-model.json` v2, K49 ile değişti: eski ≈%6,6 ve ≈0,33 yaklaşık planlayıcıdandı), baharda ×3 hızla erir (yukarıdaki azalış kuralı). Görünüş var olan taze kar ve örtü tekdüzeniyle gelir (Godot `SnowPack`, `godot.md` §3.5); yeni doku ve program yoktur. Menüde tekdüzen 0'dır: menüye dönüşte görünüş kimliğe döner, menü karesi değişmez. Kampta kar örtüsü yalnız görünüş ve izdir: kampın ≤40 koyunu yalnız görünüştür, ekonomiye girmez (K65); kabuk tepkisi yerleşimindir (`settlement.md` §15.3).

**Kar örtüsü ve Kar Kabuğu** (zon durumu, kayıtta; görsel taze kardan ayrıdır). Sıcaklık modellenmez (K1): kabuk havanın sırasından okunur.

```
snowpack ∈ [0, 1]   (1 ≈ 40 cm)                                     // saatte bir
+ sa başına:  snow 0,035 · heavy_snow 0,09 · blizzard ve kara_boran 0,05 · sleet 0,01
− sa başına:  yağış olmayan her saat 0,004; güneş >15° ve tür açık ya da bulutluysa ek 0,03; bahar ×3; yaz ve güz başında 0
deepSnow  = snowpack ≥ 0,6, 06:00'da okunur                          // derin kar günü
crust     = deepSnow ve [ o gün ≥1 sa sulu kar
                          ya da son 24 sa'te yoğun kar ya da tipi bitmiş ve 10:00–15:00 tümüyle açık (tohumlu %12) ]
            ve ardından açık gece (20:00–06:00 arasında ≥6 sa açık ya da bulutlu)
          → şafakta Kar Kabuğu / Snow Crust (`snow_crust`), 5–10 gün (tohumlu); snowpack <0,3 ya da bahar erken bitirir; kabuk sürerken yenisi oluşmaz
```

Tepki yerleşimindir (`settlement.md` §15.3): kabukta otlak ×0,3, sürü yem ister, yem yoksa günde %2 yiter; derin kar günü yem ister. Payların dökümü `d2/weather-model.json` v2'dedir (2026-11-03): prototipin gerçek `weather-core`'u (ayarlı ağırlıklar, cephe hazırlığı ve çözülmesi, gün içi eğriler, sis, dolu ve tipi kuralları) §4.2'nin kış satırlarıyla sabit tohumla (2048377054) 150 kış × 120 gün koştu, dosyayı `tools/weather-model.mjs` yazdı. `econ-sim` oradan okur; ekonominin resmî koşusu (2026-11-04, `--strict`, 0 işaret) bu dosyayla yapıldı (K49: derin kar %16,0). Tablo dosyadan basıldı:

| İklim, kış | Derin kar günü payı | Kabuk / kış | Kabuklu gün payı |
|---|---|---|---|
| `steppe_south` (`tanhu_ordu`) | 0,16 | 0,62 | 0,02 |
| `kerulen` (`donghu_land`) | 0,258 | 0,97 | 0,039 |
| `hangai` | 0,413 | 1,23 | 0,06 |
| `orkhon` (`tanhu_camp`, `longcheng`) | 0,067 | 0,29 | 0,009 |
| `daibei` (`mayi`, `baideng`) | 0,133 | 0,37 | 0,012 |
| `gobi` (`whistle_field`) | 0,016 | 0,01 | 0 |
| `ordos` | 0,017 | 0,07 | 0,001 |
| `hexi` | 0,015 | 0,05 | 0,001 |
| `hexi` I. Perde (yoğun kar ve tipi dışlı) | 0,001 | 0 | 0 |
| `alashan` | 0 | 0 | 0 |

(K49 ile değişti, E6.4) Eski tablo baş tasarımcının yaklaşık planlayıcısındandı (150 kış; gün içi eğriler yoktu): `steppe_south` 0,135 / 0,63 / 0,027, `kerulen` 0,30 / 1,25 / 0,066, `hangai` 0,38 / 1,35 / 0,071, `orkhon` 0,066 / 0,33 / 0,012, `daibei` 0,146 / 0,59 / 0,023, `gobi` 0,019 / 0,01 / 0, `ordos` 0,024 / 0,08 / 0,003, `hexi` 0,019 / 0 / 0. K49 derin kar payını modelin değeri sayar (%16,0); tablo dosyadan basıldığı için ona uyar (K31: `decisions.md` kazanır; `d2/core.md` §3.6'nın tablosu da aynı dosyadan yeniden basılır).

I. Perde'de kar örtüsü oyunu değiştirmez: Derin Kar bir bölge türüdür (`act1.md` §9.2). Doğrulanacak, soru değildir (K58, #16): W26'nın üreteç yarısı prototipte koşuldu; Godot'un `WeatherPlanner` ve `SnowPack`'i aynı kurallarla sabit tohumla 150 kış koşar ve kabulde kalır. Kabul modelin değerine ortalanır: `steppe_south` derin kar payı 0,16 ±0,03, kabuk 0,62 ±0,3 / kış; `gobi` kabuk ≤0,05 / kış; `hexi` I. Perde satırında kabuk 0. Prototipin `test/weather-core.test.js`'i bu turda değişmez, eski merkezle sınar (0,135 ±0,03, 0,63 ±0,3); modelin değeri iki aralığın da içindedir (Genel kural 6). Dosya sonra değişirse `econ-sim --strict` yeniden koşulur. İş Yol Haritası'nın `weather` maddesindedir ([/roadmap#act-1-p1](/roadmap#act-1-p1)); ekonomi eşliği II'nin `econ-sim-run` maddesindedir ([/roadmap#act-2-p2](/roadmap#act-2-p2)).

## 6. Hikâye kilitleri

### 6.1 Yüz

```js
// ctx.weather (game/weather.js). Kilitler yığındır: son açılan kazanır, release kendi kilidini kaldırır.
weather.lock(id, {
  type,                       // §3.1 kimliği
  params = null,              // vektörün üstüne yazılan alanlar: { wind, dirFrom, fogFar, cover, dark, rain, snow, ... }
  keys = null,                // [{ k: 0..1, type?, params? }]: ilerleme anahtarları; progress(id, k) sürer
  blend = 6,                  // gerçek sn
  until = null,               // hourAbs ya da null (release'e dek)
  pinFx = null,               // kalibre sahne: { mask, trackK, douse, felt, snowFelt, fogStealth }
  signs = false,              // kilidin önceden işaret vermesi (§7.2)
  after = 'resume',           // 'resume' | 'clear' | tür kimliği
});
weather.release(id, { blend = 6 });
weather.progress(id, k);       // ör. Ay Saati ilerlemesi
weather.pin(params, seconds);   // kısa iğne: { wind: 0 } (Gök Açılır)
weather.freeze(on);             // yağış ve rüzgâr saati durur; global uTime'dan bağımsız (Donuk Kamp)
weather.calm(on);               // yerel sükûnet: oyuncunun 30 m çevresinde rüzgâr 0, kar dik düşer (Kara Yol)
weather.flash(power, dirXZ);    // senaryolu şimşek
weather.strike(target, { telegraph = true });   // 'tree:<id>' | 'structure:<id>' | [x, z]
weather.gap(dirXZ, radius, seconds);             // kubbede açıklık: yıldız ve gök (Gök Açılır, Kara Boran yıldızı)
```

Görev ve sinema bunları etki op'u `weather` ve sinema satırı `weather` ile çağırır (§12.6). Kilit kayda yazılır (§12.7); yüklemede yeniden kurulur.

### 6.2 I. Perde takvimi

Saatler zaman alanının taşıdığı sahne saatleridir (K20); kilitler sahneye bağlanır, saate değil. `pinFx` kalibre edilmiş sayıları korur: act1 §9.5 gürültü yarıçapları, §9.2 iz süreleri, structures §6.1 yanık süreleri, act1 §10 Kara Boran değerleri.

| id | Bağ: açılış → kapanış | Tür ve değerler | `pinFx` | Neden |
|---|---|---|---|---|
| `a1_road_in` | Perde açılışı → `mq_first_tally` sonu (ilk 15 dk, act1 §12) | `clear`, rüzgâr 2 m/sn, 300°'den | · | Öğretim okunur kalır; Yar Bakışı'nda «gök ilk kez» açık görünür |
| `a1_short_measure` | `sq_short_measure` (Gün II gece) | `snow`, kar 0,4, rüzgâr 1,5; taze kar 1 | `mask 0`, `trackK 1` | Yeni karda iz dersi (act1 §9.5 «Yeni karda iz kalır»): iz süresi ve çan yarıçapı act1'deki gibi |
| `a1_crown` | `mq_crown` (Gün III sabah, act1 §8.1) | `clear`, rüzgâr 0,8 | · | Tündük durgun havada kalkar; fırtınada `tall` adım bekler (§8.11) |
| `a1_envoy` | `mq_envoy` (Gün III öğle) | `cloud` | · | Eskam'ın gezisi aydınlık ve okunur |
| `a1_hunt` | `mq_hunt` (Gün III akşam) | `wind`, rüzgâr 5 m/sn, 20°'den (kuzey-kuzeydoğu) | · | Rüzgâr altından yaklaşma (survival §4, `downwind`); yön sabit ki Farnak'ın öğüdü doğru çıksın |
| `a1_feast_raid` | `mq_feast` → `mq_reeds` sonu (Gün IV akşam) | `clear`, rüzgâr 3 m/sn, 45°'den (kuzeydoğu); taze kar 0; gök gürültüsü yok | `douse 0`, `felt` 0, `snowFelt` 0,5 | structures §6.2 sıçrama kalibrasyonu (rüzgâr 3, karlı keçe 0,5); act1 §8.3 «kuzeydoğu kızarır» |
| `a1_ash` | `mq_ash` (Gün V sabah) | `overcast`, karanlık 0,3, rüzgâr 1 | · | Kül Sabahı |
| `a1_sentence` | Göz Yolu + Hüküm (Gün V öğle, act1 §8.4) | `snow`, kar 0,3, rüzgâr 0,5 | `mask 0` | Ağır ve sessiz; sis yok, yüzler okunur |
| `a1_last_night` | `mq_knot` → `mq_offering_stallion` sonu (Son Gece) | `snow`, kar 0,35; sis uzağı Düğüm'den buz saatine doğrusal 1400 → 140 m (`keys`, `time.md` §9.6); `cloud` 0,3 → 0,9 (`fx.cloud`; ay ışığı giderek söner, gizlilik değişmez); rüzgâr 1,5 → 6 m/sn (k ≥ 0,66) | `mask 0`, `trackK 1`, `douse 0`, `fogStealth` kapalı | act1 §8.7 sisi; §9.5 gürültü ve iz; oyalama ≈70 sn'de 7→3 (structures §6.1) |
| `a1_stallion` | Adak Aygırı yaklaşması (act1 §8.8) | Rüzgâr 4 m/sn, 270°'den (batıdan) | · | «Rüzgâr bezine bak»: rüzgâr altı ağılın doğusudur, g09 Ağıl Batı'dan uzak; bez yönü gösterir |
| `a1_frozen` | Donuk Kamp (act1 §8.5) | `freeze(true)` | · | «Kar havada, kıvılcımlar asılı» |
| `a1_sky` | Gök Açılır, Yar Bakışı (act1 §8.6) | `pin({ wind: 0 }, 6)`, `freeze` 1,2 sn, kubbe örtüsü −0,35, `gap` Tengri kamerası yönünde 6 sn | · | «Rüzgâr kesilir, kar bir an havada durur»; `sky_closed` ise örtü +0,1, 10 sn yoğun kar |
| `a1_black_road` | Oyuncu Kara Yol üstündeyken (act1 §8.5) | `calm(true)` | · | «Rüzgâr ve müzik kesilir, Yol Kemikleri susar»: kar dik düşer |
| `a1_kara_boran` | `mq_blizzard` (Gün VI) | `kara_boran`: sis 140 m, `pale_pasture` bölgesinde 45–80 m; T4 `whiteout`; `erlik_choice=refuse` ise 2 `squall`; T5'te kubbe örtüsü −0,3; Kut ≥6 ise `gap` yıldız yönünde | act1 §10 değerleri: rüzgâr 8 (bora 15), iz 15 sn, taşsız ateş 40 sn | act1 §10 |
| `a1_throat` | `mq_throat` (boss, act1 §8.9) | `snow`, kar 0,5, rüzgâr 6, kubbe örtüsü 0,25 | · | Kara Boran'ın kuyruğu, «gökte ilk aydınlık» |
| `a1_dawn` | Şafak Sırtı (act1 §8.11) | `clear`, rüzgâr 2; 8 sn karışım | · | «Fırtına kesilir, ilk açık gök» |
| `a1_guard_boran` | Son Gece, Ay Saati k ≥ 0,66 | İşaret: kemikler, Adak Aygırı huzursuz, nöbetçi satırı (§7.3) | · | Kara Boran'ın 1 sa'ten uzun işareti |
| `home_spring` | K7 `home` | Kimlik (açık, kuru); ışık 11 Nisan 14:46,2'nin ikindisi (K76) | · | K7: bahar, Mete atla gelir |

**Serbest günler.** Kilit dışındaki Kışlak saatleri `hexi` I. Perde satırıyla akar (§4.2): Gün I öğleden sonra, II, III ve IV'ün kilitsiz saatleri. Bu saatlerde kar ve rüzgâr oyunu hafifçe değiştirir (iz, ateş, işçi); hiçbir ana adım havayı beklemez.

### 6.3 Ev ve Serbest Gez başlangıcı

- `home` (K7): hava kimliktir; WeatherSystem `home` kipinde çalışmaz (§12.4). (K76 ile değişti) Ev'in ışığı 11 Nisan 14:46,2'nin ikindisidir (`MENU_SUN`, ikindi durağı), Godot menüsünün gece ışığı değildir. Eski «Kart ve menü aynı görüntüdür» yalnız prototipin ikindi menüsü içindi.
- İlk Serbest Gez (kayıtta `weather` yok): 11 Nisan MÖ 209 14:46,2'de açılır (K67); `roam_first` 0,5 sa `clear`, sonra planlayıcı `camp_spring` satırıyla. **camp3'ün ocağı yanana dek** (`y_ocak`, kayıtta `camp3.done`) planlayıcı `sev` ≥3 türleri dışlar (`exclude`, I. Perde Kışlak satırının yolu: sağanak, gök gürültülü ve kuru fırtına, fırtına, dolu, toz); yağmur, çisenti, sis ve kar serbesttir. Neden (K83 ile yeniden hesaplandı; `structures.md` §11.6): yardımsız camp3'ün ilk dumanı 05:48'de şafaktadır (emek 05:56), tündük 20:36'da meşale ışığında kalkar, uuk 23:40'ta biter; bütün yardımla duman 03:43'te gecedir (tündük 19:48, uuk 22:22). Aile 23:00'e dek ateş başındadır; 23:00'te aşama ≥4 ise (uuk bitmiş) ilk dumana dek bekler, 05:00'e dek duman çıkmazsa Ana közü getirir (`time.md` §8.2). Kampın ortalama ≈%8'lik hava payı tündük ve keçe adımlarının gece saatlerine düşmesiyle ateş başı anını götürürdü (doğrulama V5; `d2/core.md` §2.11). Yağmur bu dışlamanın dışındadır ve işi yavaşlatır: genel işi ×0,85, keçe adımını ×0,7 yapar (`structures.md` §2.4); kamp baharında yağmur payı ≈%7,7, bölümü ≈2,5 oyun saatidir (§4.2, §4.5), 13 saatlik kurulumda yağmur gelme olasılığı ≈%33'tür ve tek bölüm ilk dumanı 22–45 oyun dk geciktirir. Bu yüzden aile sabit bir saate değil ilk dumana dek bekler (K83): uuk adımında tek yağmur bölümü ≈22 oyun dk geciktirir ve yalnız katılmanın 23:00'e kalan 28 dakikalık payını aşmaz; keçe adımındaki 45 dk'ya varan gecikme yalnız dumanın saatini kaydırır, aile ilk dumana dek bekler, duman Tan'a (04:21) kalsa da oradadır. Önerilen sabit 04:15 bitişi bu yüzden seçilmedi: yalnız katılmanın 13 dakikalık payını her yağmurda aşardı. Yalnız katılmada (uuk 22:32, duman 04:02) aile bekler: Evet (eski 22:30 / 03:45 kuralında Hayır'dı). Ocak yanınca bütün tablo açılır; 8.11'in saatli kabul koşuları açık havaya iğnelidir. Sonraki girişler kayıttaki havayla ve kayıttaki günün mevsim satırıyla açılır; menüden inişte hava 2,4 sn'de kimlikten kayıttakine karışır (kamera karışımı 1,6 sn sürerken yağmur yukarıdan başlar, saatin ışık süzülmesiyle aynı süre). Menüye dönüşte 1,7 sn'de kimliğe döner (§9.12); kampın kış kar örtüsü de kimliğe döner.

**Önsöz, Çocukluk ve Yola Çıkış (K36, K67, K68).** Önsöz'de hava yoktur: geri çekilme menü ışığında (Godot'da gece kampı, K76) ve menü havasındadır (kimlik), mit sineması keçe panodur, doğum sahnesinin ışığı sabit örnektir (`time.md` §3). İki küçük dünya hikâye kilidiyle açılır, planlayıcı çalışmaz:

| id | Bağ | Tür ve değerler | Neden |
|---|---|---|---|
| `a0_childhood` | Çocukluk, `childhood_ordos`, 22 Eylül MÖ 228, 08:40–≈11:00 | `clear`, rüzgâr 2 m/sn, 300°'den; ıslaklık 0, kar 0 | `story.md` §5: «Hava açık, rüzgâr 2 m/sn, ot sarı»; oyuncak okun yan ivmesi 0,25 × 2 = 0,5 m/sn², 20 m'de sapma ≈0,15 m (§8.15'in 8 m/sn'de 14 m'de 0,3 m'siyle aynı hesap): öğretim bozulmaz |
| `a0_depart` | Yola Çıkış, `depart_yurt`, 15 Aralık MÖ 213, şafaktan önce (≈90 sn) | `overcast`, rüzgâr 1,5 m/sn; yağış yok; zon kar örtüsü sabit 0,5 (karlı avlu) | Kış şafağından önceki gri ışık; kısa sahne, söz okunur |

### 6.4 Sonraki perde kancaları

| Kanca | Perde | Kilit | Dayanak |
|---|---|---|---|
| `a2_first_hearth` | II | Mete'nin kendi ocağındaki ilk gece (`tanhu_ordu`): `clear`, durgun, ay görünür (`moonSeen`) | Tasarım: «kendi göğü» anı |
| `a2_drill_dust` | II | `whistle_field` talimi tozda yapılmaz: `drill` turu görüş <80 m iken bekler | `army.md` §3.5 `drill` 90 sn |
| `a3_dailin` | III, 16 Eylül MÖ 208 (`dayN` 1.694), `dailin_ground` | Sayım ve Söğüt Turu boyunca `clear`, rüzgâr ≤3 m/sn; sayımdan sonra planlayıcı sürer (K56) | Shiji 110 秋，馬肥，大會蹛林; perdenin doruğu: «Toprak devletin temelidir» |
| `a3_donghu_dawn` | III, 26 Eylül MÖ 208 şafağı | Doğu baskını şafakta `fog` (görüş 60 m) | Shiji 110 東胡初輕冒頓，不爲備 (Tunghu hazırlıksız); sis `tasarım tercihi` |
| `a4_longcheng` | (K56 ile değişti, E6.4) IV'te iki gün: 17 Haziran MÖ 205 (`dayN` 2.698), Gök Dağı eteğinde Beşinci Ay Sunusu (`hexi_ash`, iklim `hexi`; Mete Hexi'dedir); 25 Haziran MÖ 203 (3.436), Lung-çeng'de büyük toplantı ve armağan kervanı (`longcheng`, iklim `orkhon`) | İki günde de tören saati `clear`; törenden sonra `thunderstorm` serbest | Shiji 110 五月，大會蘢城，祭其先、天地、鬼神; gök gürültüsü yorumu ozana kalır. Eski satır yalnız 17 Haziran 205'i sayıyordu ve onu Lung-çeng'e koyuyordu |
| `a4_dailin` | IV, 22 Eylül MÖ 203 (`dayN` 3.525), `ordos`, Mete'nin doğduğu otlakta; son görev `mq4_dailin_ordos` (K43) | Sayım boyunca `clear`, rüzgâr ≤3 m/sn; sayımdan sonra planlayıcı sürer | Shiji 110 秋，馬肥，大會蹛林; K56: Dailin üç kez oynanır, IV'ünkü yerleşimin sayımı değildir. `a3_dailin` ve `a6_dailin` ile aynı desen (`story.md` §14.3'ün önerisi) |
| `a5_baideng` | V, 25 Kasım–1 Aralık MÖ 201 | `heavy_snow` → `blizzard` anahtarları; Han yorgunluğu ×2 (§8.13), Han yaya karda ×0,6 | Shiji 110 會冬大寒雨雪 (yalnız kar oynanır, K1) |
| `a5_yada` | V (seçmeli) | Kam yada taşıyla kar ister; kilit `a5_baideng`'i 1 sa erkene alır | `tasarım tercihi`, kaynak geç dönem (§1) |
| `a6_longcheng` | (K56 ile değişti, E6.4) VI'da iki gün: 2 Haziran MÖ 198 (`dayN` 5.238) ve 4 Haziran MÖ 176 (13.270), `longcheng` | `a4_longcheng`'in aynısı | K56: Lung-çeng VI'da da iki kez oynanır (`mq6_letter_176`, `mq6_kunmo`); eski satır yalnız 2 Haziran 198'i sayıyordu |
| `a6_dailin` | VI, 9 Eylül MÖ 174 (`dayN` 14.097) | Son sayım `clear`, rüzgâr ≤3 m/sn | Shiji 110 秋，馬肥，大會蹛林; Mete sayım sürerken ölür (K56) |

Tarihli kilit tablo gününe bağlıdır; tarih kapısı (K33) saati o güne atlatınca kilit açılır. Oyuncu günü geçtiyse sahne kilidi yine sahneye bağlanır, takvim değil.

## 7. Okunur işaretler

### 7.1 Kanallar

Prototipin oyun kamerası (28°) gökyüzünü görmezdi (act1 §4: üst ışın ufkun 9° altında). Godot'nun varsayılan kadrajı da görmez: K98'den beri eğim 38°, dikey görüş 36°, üst ışın ufkun 20° altında (önce 23,35°, 41,76° ve 2,5°; K39, K98). Oyuncu eğimi bandın alt ucuna (15°) indirirse karenin üst ≈%9'u göktür (önce ≈%14). İşaretin asıl yeri bu yüzden zemin, ışık, duman, hayvan ve sestir; kubbe alçak eğimde, Bakış Noktası'nda, «Göğe Bak» çekiminde (K35), yokuşta sürüşte, Tengri kamerasında ve sinemada görünür.

| id | Kanal | Önce (sa) | Cephe | Görünen ya da duyulan |
|---|---|---|---|---|
| `cover` | Zemin | 2 → 0 | Hepsi | Bulut gölgesi örtüsü ve hızı artar (`uCloudInfo.w`, `uCloudPhase`); cephe hattı vadiyi geçer (`U.uFront`, §9.7) |
| `light` | Işık | 0,25 → 0 | Islak, fırtına | Güneş türün çarpanına iner, gölge yumuşar |
| `wind_shift` | Rüzgâr | 1 | Hepsi | Yön 30–60° döner, hız ×1,3: çim, bayrak, duman yön değiştirir |
| `smoke_sink` | Duman | 1,5 | Yağmur, kar | Ocak dumanı yükselmez, yere çöker ve yatar (yükselme ×0,6): «duman yere çökerse yağmur gelir» |
| `far_thunder` | Ses | 1 → hazırlık boyunca | GGF, kuru fırtına | 8–10 km'den boğuk gök gürültüsü, 40–70 sn'de bir |
| `far_rain` | Ses | 1 → 0 | Yağmur, sağanak, sulu kar, dolu | Rüzgârın geldiği yanda uzak yağmur hışırtısı, yaklaştıkça kabarır; −20 dB'den −10 dB'ye |
| `gust_rise` | Ses | 1 | Kar, yoğun kar, tipi | Bora sıklaşır ve sertleşir (`gust` 20–30 sn'de bir) |
| `herd` | Hayvan | 1 | Fırtına, toz, tipi | Atlar kıçını rüzgâra döner, koyun toplanır, karga bağırarak alçak uçar, kuş sesi söner, tarbagan inine girer (kışın tarbagan yok), deve toz önünde bağırıp çöker, yak ve sığır tipi önünde sırtını rüzgâra verir, köpek inler (§7.6) |
| `bones` | Ses (I. Perde) | 1 | Rüzgâr, fırtına, Kara Boran | Yol Kemikleri'nin uğultusu yükselir: `bone_hum` kazancı rüzgârla |
| `npc` | Söz | 0,75 | Hepsi | §7.3; 15 m içindeki konuşan kişi, cephe başına bir kez, altyazı (K5: iş ve ara söz seslendirilmez) |
| `hud` | HUD | 1 | Hepsi | Saatin yanındaki simge döner, altında ince ok; işaret satırı (§7.4) |
| `halo` | Kubbe | Cephe 8 sa içindeyse | Islak | Ay ya da alçak güneş çevresinde 22° hale: «Ay ağıl aldı.» |
| `red_dawn` | Kubbe, ışık | Cephe o gün geliyorsa | Islak, fırtına | Şafak kızıllığı ×1,6 |
| `front_wall` | Kubbe | 2 | Hepsi | Rüzgârın geldiği ufukta bulut duvarı (`uFront`); tozda sarı duvar |
| `green_sky` | Işık, sis | 0,25 (dolu sağanağından önce) | Dolu | Yarımküre ve sis rengi yeşile çalar |
| `static` | Ses, zemin | 1,5 sn (yakın yıldırım) | Yıldırım | `static_hum` vızıltısı, hedefte ince parlak halka (telegraf, §8.7) |
| `skill` | Gök okuma | 6 | Hepsi | `iron_stake` (§7.5) |

**Kural.** `sev` ≥3 olan her bölüm en az 1 sa önce (Hikâye 1,5 sa, Zor 0,75 sa: K22'nin zorluk kolu, §8.16) en az üç kanaldan işaret verir: biri zemin ya da ışık, biri **ses** (zorunlu), biri HUD. Islak cephelerin ses kanalı `far_rain`'dir (rüzgârın geldiği yanda uzak yağmur hışırtısı: `rain_light`'ın alçak geçiren süzgeçli ve 3B uzak çalınışı, yeni pişirme yok), ardından `rain_drip`'in başlaması; gündüz tarbagan ıslığı ve alçak uçan kargaların çağrısı; kardan önce bora sertleşir (`gust`). Islak türün içinden gelen ağır bölüm de hazırlık bölümüyle gelir (§5.3); varışta lütuf kuralı (§5.7). Zorluk: Hikâye süreler ×1,5, Zor ×0,75 (en az 0,75 sa). Hikâye kilidi `signs: true` ise aynı çizelgeyi kendi saatinden geriye kurar.

### 7.2 Cephe çizelgesi

| Hedef | −2 sa | −1,5 sa | −1 sa | −0,75 sa | −0,25 sa | Varış |
|---|---|---|---|---|---|---|
| `rain`, `drizzle`, `downpour` | `cover` | `smoke_sink` | `wind_shift`, `far_rain`, `hud` | `npc`, `herd` (tarbagan, karga) | `light`, `rain_drip` | 20 sn'de yağış |
| `thunderstorm`, `dry_storm` | `cover`, `front_wall` | · | `far_thunder`, `herd`, `wind_shift`, `hud` | `npc` | `light` (kararma) | `gust_front` 15 sn, sonra fırtına |
| `hail` (fırtına içinde) | | | | Hazırlık: gök kararır, `far_rain` sertleşir | `green_sky` | Dolu sağanağı |
| `gale` | `front_wall` | · | `wind_shift`, `herd`, `bones`, `hud` | `npc` | Bora sıklaşır | Fırtına |
| `dust_storm` | `front_wall` (sarı) | · | `herd`, `wind_shift`, `hud` | `npc` | Ufuk sararır, toz zerresi | Toz duvarı |
| `snow`, `sleet`, `heavy_snow` | `cover` | `smoke_sink` | `wind_shift`, `gust_rise`, `hud` | `npc` | `light` | Kar |
| `blizzard` | (kar sürüyor) | · | `bones`, `herd`, `hud` | `npc` | Kar yataylaşır | Tipi |
| `fog` | Önceki akşam: açık ve durgun | · | `hud` (gece) | `npc` (akşam) | · | Şafakta sis |
| Kara Boran | Son Gece k ≥ 0,66 | `bones` | `herd` (Adak Aygırı huzursuz) | Nöbetçi satırı | · | Boru (act1 §8.8) |

### 7.3 Kişi satırları

Altyazı; D dilimidir (yazı), seslendirilmez, kredi harcamaz (K61). Konuşan 15 m içindeyse ve son 6 gdk'da hava satırı söylemediyse.

| id | Kim | Cephe | TR / EN |
|---|---|---|---|
| `weather.say.camp_mother.rain` | Ana (kamp) | Yağmur | «Keçenin ağzını bağla yavrum, yağmur geliyor.» / «Tie the felt flap, little one, rain is coming.» |
| `weather.say.camp_father.storm` | Baba (kamp) | GGF | «Gök davulunu geriyor. Atları ahıra al.» / «The sky is tightening its drum. Get the horses into the stable.» |
| `weather.say.camp_bard.storm` | Ozan | GGF | «Tengri'nin atları geçiyor; yollarından çekil.» / «Tengri's horses are passing; keep out of their road.» |
| `weather.say.camp_mother.hail` | Ana | Dolu (sırasında) | «İçeri! Gök taş atıyor!» / «Inside! The sky is throwing stones!» |
| `weather.say.camp_bard.fog` | Ozan | Sis (sabah) | «Göl bu sabah nefesini salmış.» / «The lake has let out its breath this morning.» |
| `weather.say.camp_mother.after` | Ana | Yağmur sonrası | «Islak ot kokusu... Koyun bugün iyi otlar.» / «Smell the wet grass... the sheep will graze well today.» |
| `weather.say.camp_father.gale` | Baba | Fırtına | «Rüzgâr dönüyor. Ocağın çevresine taş diz.» / «The wind is turning. Ring the fire with stones.» |
| `weather.say.camp_bard.snow` | Ozan | Kar serpintisi, yalnız bahar | «Kar bahara küsmüş; birazdan barışırlar.» / «The snow has quarrelled with spring; they will make up soon.» |
| `weather.say.camp_brother.storm` | Ağabey (kamp, K37) | Fırtına, GGF | «Atlıların atları huysuz. Ben ahırın kapısını tutarım.» / «The riders' horses are restless. I'll hold the stable door.» |
| `weather.say.palak.snow` | Palak | Kar | «Bulut Çilyan'dan iniyor. Akşama kar.» / «Cloud is coming down off the Qilian. Snow by evening.» |
| `weather.say.atsho.gale` | Atşo | Fırtına | «Köz kıpırdıyor. Rüzgâr döndü, ocakları örtün.» / «The embers stir. The wind has turned; cover the hearths.» |
| `weather.say.kantu.snow` | Kantu | Kar | «Kar geliyor, teker ağırlaşır. Gideceksen şimdi.» / «Snow is coming; the wheels will drag. If you're going, go now.» |
| `weather.say.farnak.wind` | Farnak | Rüzgâr, fırtına | «Atlar kıçını rüzgâra döndü. Gece sert geçer.» / «The horses have turned their tails to the wind. It will be a hard night.» |
| `weather.say.ardoksha.snow` | Ardokşa | Kar | «Kar geliyor. Kütükleri şimdi getir; sonra her adımın yazılır.» / «Snow is coming. Bring the logs now; later every step you take is written down.» |
| `weather.say.hereka.fog` | Hereka | Sis | «Sis inince Çukur susar. Sis kulak verir.» / «When the fog comes down, the Hollow goes quiet. Fog listens.» |
| `weather.say.guard.boran` | Nöbetçi (Son Gece) | Kara Boran | «Şafakta boran var. Atları sıkı bağlayın.» / «There is a storm at dawn. Tie the horses tight.» |
| `weather.say.scout.moon` | Gözcü (II+) | Gece bulut | «Kuzeyde kara bulut; ay görünmeyecek. Akın bekler.» / «Black cloud to the north; the moon won't show. The raid can wait.» Satır Mete'nin kendi gece yürüyüşünü söyler (ışık, `nightClass`). Düşman akını ayın evresiyle gelir, bulut onu ertelemez (K55, H20, H28) |
| `weather.say.herder.dust` | Çoban (II+) | Toz | «Toz geliyor! Sürüyü yamacın kuytusuna sür!» / «Dust is coming! Drive the herd into the lee of the slope!» |
| `weather.say.camel_driver.dust` | Deveci (II+) | Toz cephesi, deve 1 sa önce | «Deve çöktü, toz geliyor!» / «The camels are down. Dust is coming!» (`fauna.md` §7) |
| `weather.say.steward.hail` | Kâhya (K23 yerleşim) | Dolu; yalnız Surlu yolda tarla varsa (K54) | «Dolu darıyı döver. Ambarın ağzını kapatın!» / «Hail beats the millet. Shut the storehouse!» |

**İye satırları (K35; `mitoloji.md` öneri 13, `story.md` §9).** Hun ve Altay ağzıdır, «Ozan der» çağındandır; durum etkisi yoktur, işaret kanalıdır. Konuşan 15 m içindeyse, sahnesinde bir kez.

| id | Kim | Ne zaman | TR / EN |
|---|---|---|---|
| `weather.say.iye.ice_bull` | 15 m içindeki Hun kişisi (I: Uldın, Berik ya da Hereka) | Buz Kolu, gece buz inlerken | «Buz böğürdü. Su boğası altında dönüyor.» / «The ice bellowed. The water bull is turning beneath it.» |
| `weather.say.iye.lake_bull` | Ozan (kamp) ya da göllü dünyada yaşlı biri | GGF ya da fırtına cephesinden 1 sa önce, `lake_bull` sesinden sonra | «Göl boğası böğürdü. Fırtına yolda.» / «The lake bull has bellowed. A storm is on its way.» |
| `weather.say.iye.mountain` | Çoban (II+) | Fırtına (`gale`) | «Dağ iyesi koşuyor; rüzgâr onun atı.» / «The mountain spirit is running; the wind is his horse.» |
| `weather.say.iye.pleiades` | Ozan (kampın kışı, K67; bahar serpintisinde ozanın satırı `camp_bard.snow`'dur) ya da yerleşimde yaşlı biri | Kar, kış | «Gök çadırının Ülker deliği açıldı; kar oradan dökülüyor.» / «The Pleiades hole in the sky-tent has opened; the snow pours through it.» |
| `weather.say.iye.pass` | Balamir (II+) | Geçitte, rüzgâr ≥9 m/sn | «Geçitte biri alçak sesle konuşuyor. Selam ver, sonra geç.» / «Someone speaks low in the pass. Greet it, then go through.» |
| `weather.say.iye.reed_light` | 15 m içindeki Hun kişisi (I: Berik, Uldın ya da Hereka) | Saz Tüneli, gece sis | «Sazda ışık görürsen yürüme. Bozkır iyesi yol sorar gibi yapar.» / «If you see a light in the reeds, don't follow it. The steppe spirit only pretends to ask the way.» |

Ülker satırı soğuk demez (K1): delik karın yoludur, ısının değil.

**Mene.** Konuşmaz (K5, K61: D dilimi, sessiz). Cephe 1 sa içindeyse ve oyuncu 12 m'deyse göğü değil sürüyü gösterir (el işareti, `sign` jesti): sağır çocuk havayı hayvandan okur.

**Uyanış satırları** (atlamadan sonra, ilk konuşan): «Gece kar yağdı.» / «It snowed in the night.» · «Gece yağmur yağmış; yol çamur.» / «It rained in the night; the road is mud.» · «Gece fırtına koptu; uyanmadın mı?» / «A storm broke in the night. Didn't you wake?» · «Sabah sisi daha dağılmadı.» / «The morning fog hasn't lifted yet.»

### 7.4 HUD işaret satırı

Saatin yanındaki simgenin üstüne gelince ya da dokununca bir satır (`ui/hud/weather.js`, §11). Cephe yoksa şu anki tür adı yazar.

| id | TR / EN |
|---|---|
| `weather.sign.rain` | «Rüzgârın geldiği yanda bulut ağırlaşıyor.» / «Cloud is gathering weight where the wind comes from.» |
| `weather.sign.storm` | «Uzakta gök gürlüyor.» / «Thunder, far off.» |
| `weather.sign.hail` | «Bulutun altı yeşile çalıyor.» / «The underside of the cloud has gone green.» |
| `weather.sign.snow` | «Hava kar kokuyor.» / «The air smells of snow.» |
| `weather.sign.gale` | «Rüzgâr dönüyor, sertleşiyor.» / «The wind is turning, and hardening.» |
| `weather.sign.dust` | «Ufuk sararıyor.» / «The horizon is turning yellow.» |
| `weather.sign.fog` | «Gece durgun; sabaha sis iner.» / «A still night; fog will settle by morning.» |
| `weather.sign.blizzard` | «Kar yana yatıyor.» / «The snow is falling sideways.» |
| `weather.sign.clearing` | «Bulut yırtılıyor.» / «The cloud is tearing open.» |
| `weather.sign.halo` | «Ay ağıl aldı.» / «The moon wears a ring.» |
| `weather.sign.smoke` | «Duman yere çöküyor.» / «The smoke is sinking to the ground.» |
| `weather.sign.herd` | «Atlar kıçlarını rüzgâra döndü.» / «The horses have turned their rumps to the wind.» |

### 7.5 Gök okuma (`iron_stake`)

Yeni beceri eklenmez: 93 beceri ve XP toplamı `progression.md`'nin değişmezidir. `iron_stake` (Demirkazık, Gölge T3, II. Perde) zaten gökle ilgilidir; ikinci etki alır.

- Açıklama (K35 ile değişti; MÖ 209'da kutupta parlak yıldız yoktur, `time.md` §5.6): «Gökte dönmeyen noktayı ve bulutun yolunu bilirsin: gece ve körde kuzey ekranda kalır, göğe bakınca önümüzdeki altı saati okursun.» / «You know the point in the sky that never turns and the road the clouds travel: at night and in whiteout north stays on your screen, and one look at the sky tells you the next six hours.»
- Sayılar: `northMark=true`, `skyRead=6`. HUD satırı plan kuyruğundan (§5.1) en çok iki olay okur:

| id | TR / EN |
|---|---|
| `weather.read.none` | «Önümüzdeki altı saat gök değişmez.» / «The sky holds for the next six hours.» |
| `weather.read.one` | «{saat} sularında {tür}.» / «{type} around {hour}.» |
| `weather.read.two` | «{saat} sularında {tür}; {saat2} sularında diner.» / «{type} around {hour}; easing around {hour2}.» |

`{tür}` için `weather.noun.<id>` (küçük harf ad: «sağanak» / «a downpour», «kar» / «snow», «fırtına» / «a gale», «toz fırtınası» / «a dust storm», «gök gürültülü fırtına» / «a thunderstorm», «sis» / «fog»). Saat biçimi zaman alanının `format`'ıdır. Beceri yokken satır yalnız §7.4 cümlesidir (1 sa önce). `downwind`'in `windArrow` oku artık havanın canlı rüzgârını gösterir.

### 7.6 Hayvanlar

Hava yalnız fiziksel `fx`'i verir; hayvan işareti `herd` kanalıdır ve ağır havayı (`sev` ≥3) en az bir oyun saati önce okutur. Binek tepkisi §8.9'un, sürünün ekonomi tepkisi `settlement.md` §15.3'ündür. İlk altı satır K22'nindir, sonrakiler `fauna.md` §7'den (K65).

| Tür ya da cephe | İşaret (1 sa önce) | Sırasında |
|---|---|---|
| Fırtına, GGF, tipi, toz | Atlar kıçını rüzgâra döner, sürü sıkışır; karga bağırarak alçak uçar; `birds_day` söner | Küçük av (tavşan, tarbagan) inde: doğma ×0,2; maral ormanda; kurt değişmez |
| Yağmur | Karga alçak uçar ve bağırır (ana kampta ≤16 karga, K65); tarbagan ıslık çalıp girer | Küçük av ×0,3; koku ×0,6 (§8.4) |
| Sis | Yok | Hayvan görüşü sis kurallı (§8.2): yakına sokulmak kolaylaşır |
| Kar | Yok | Kar dinince 1 sa taze iz: `tracking` iki kat eski izi okur |
| Yağmur sonrası | Yok | Av ×1,3 (çıkarlar), mantar ×2 (§8.14) |
| Gök gürültüsü ≤1 km | Köpek (Ku, sonraki perdelerin köpekleri) inler, arabanın ya da yurdun altına girer | Ahırdaki atlar horlar (`horse_snort` ×3), birkaçı şaha kalkar (yalnız canlandırma) |
| Toz cephesi, deve | Deve bağırır, toplanır, ağzını kuma gömer; Deveci satırı (§7.3) | Deve yürür; `fx.cartLock`'ta hızı ×0,5 |
| Kar Kabuğu, at ve deve | Yok | Karı kazar (poz); yem tablosu aynı (`settlement.md` §15.3) |
| Tipi, yak ve sığır | Sırtını rüzgâra verir | Yak karda yük taşır |
| Cephe, turna ve kaz | Alçak uçar, sesi kesilir | Yere iner |
| Fırtına, zeren | Rüzgâraltına akar | Doğma ×0,5 |
| `sev` ≥3, doğan ve kartal | Yok | Uçmaz |

**Mevsim (`fauna.md` §7).** Kışın tarbagan, kaz, turna ve toy kuşu yoktur, ayı indedir: kış cephesinde `herd` işaretinin küçük hayvan ve kuş parçası karga ve attan okunur. Güzde maral böğürür, turna göçer, zeren akın eder. Deve satırının dayanağı Bei Shi 97'dir (MS 5.–7. yy: yaşlı deve sıcak rüzgârı önceden bilir, ağzını kuma gömer); toz cephesine genişletmek tasarım tercihidir.

## 8. Etki matrisi

Bütün sistemler tek nesneyi okur: `weather.fx` (§12.5), kare başına yerinde yazılır. Bu bölümün her kuralı bir okuyucuya bağlıdır (`progression.md` kural 1: okuyucusuz değer yok). **Sahiplik:** hava fiziksel değeri verir (rüzgâr, görüş, bulut, ıslaklık, çamur, kar örtüsü, kabuk, `cartK`, `cartLock`, `dryK`, dolu, şimşek); kamp ateşinin, yanan yapının, okun, atın ve gizliliğin hava kuralları bu belgededir; şantiye (`d2/core.md` §2.8), sürü, tarla, kervan, ordugâh (`settlement.md` §10.2, §11.3, §15.3), kurutulan yiyeceğin bozulması (`d2/core.md` §3.3) ve ordu ay olayları (`army.md`) kendi tablolarında `fx`'i okur.

### 8.1 Özet

`İz ×`: iz ömrü çarpanı. `Ateş`: kamp ateşinin yakıt tüketim çarpanı, taşsız / taşlı; süre yazan hücre "o sürede söner". `Söndürme`: yanan yapıda `burnT` düşüşü sn başına (yağmur `douse`). `Islanma`: sa⁻¹, zemin / keçe. `Araba`: yolda hız çarpanı (çamur ve kar ayrıca, §8.10).

| Tür | `sev` | Rüzgâr ort / bora m/sn | Görüş m | Ses maskesi | İz × | Koku × | Ateş taşsız / taşlı | Söndürme /sn | Islanma zemin / keçe | Kar örtüsü | Araba | Yıldırım | Araba kalkmaz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `clear` | 0 | 2,5 / 4 | ∞ | 0 | 1 | 1 | ×1 / ×1 | 0 | kurur | 0 | 1 | · | · |
| `cloud` | 0 | 3,5 / 6 | ∞ | 0 | 1 | 1 | ×1 / ×1 | 0 | kurur | 0 | 1 | · | · |
| `overcast` | 1 | 3 / 5 | 2000 | 0 | 1 | 1 | ×1 / ×1 | 0 | −0,1 / −0,05 | 0 | 1 | · | · |
| `fog` | 1 | 0,5 / 1 | 60 | 0 | 1 | 1,1 | ×1 / ×1 | 0 | +0,05 / +0,03 | 0 | 0,9 | · | · |
| `drizzle` | 1 | 2 / 4 | 400 | 0,1 | 0,8 | 0,8 | ×1,25 / ×1,1 | 0,25 | +0,25 / +0,3 | 0 | çamur | · | · |
| `rain` | 2 | 4 / 7 | 200 | 0,35 | 0,6 | 0,6 | ×1,5 / ×1,25 | 1 | +0,8 / +1 | 0 | çamur | · | · |
| `downpour` | 3 | 6 / 11 | 70 | 0,8 | 0,3 | 0,4 | 60 sn / ×2 | 2,5 | +2 / +2,5 | 0 | çamur | · | · |
| `thunderstorm` | 3 | 7 / 16 | 120 | 0,6 + gürültü | 0,4 | 0,5 | 60 sn / ×2 | 1,5 | +1,2 / +1,5 | 0 | çamur | Evet | Evet |
| `dry_storm` | 3 | 9 / 18 | 800 | 0,2 + gürültü | 0,8 | 1 (yönlü) | ×1,5 / ×1,25 | 0 | −0,2 / −0,1 | 0 | 1 | Evet, kuru | Evet |
| `hail` | 4 | 8 / 16 | 60 | 1 | 0,5 | 0,4 | 60 sn / ×1,5 | 1,5 | +0,6 / +0,6 | +0,3, erir | 0 | Fırtınanınki | Evet |
| `wind` | 1 | 9 / 14 | ∞ | 0,15 | 0,8 (karda 0,6) | Yönlü | ×1,25 / ×1,1 | 0 | −0,5 / −0,3 | 0 | 1 | · | · |
| `gale` | 3 | 16 / 24 | 300 | 0,5 | 0,5 | Yönlü, güçlü | 40 sn / ×1,5 | 0 | −0,6 / −0,4 | 0 | 0,85 | · | Evet |
| `sleet` | 2 | 4 / 7 | 150 | 0,3 | 0,6 | 0,6 | ×1,5 / ×1,25 | 0,5 | +0,5 / +0,6 | +0,2 | çamur | · | · |
| `snow` | 1 | 3 / 5 | 250 | 0,15 | 0,5 | 0,8 | ×1,5 / ×1,25 | 0 | 0 / 0 (keçe karlı) | +0,5 | 0,85 | · | · |
| `heavy_snow` | 3 | 5 / 9 | 90 | 0,3 | 0,25 | 0,6 | ×2 / ×1,5 | 0,3 | 0 / 0 | +1,2 | 0,7 | · | · |
| `blizzard` | 4 | 12 / 20 | 40 | 0,9 | 15 sn | 0,4 | 40 sn / ×2 | 0,5 | 0 / 0 | +1 | 0 | · | Evet |
| `kara_boran` | 4 | 8 / 15 | act1 §10 | 1,2 | 15 sn | 0,3 | 40 sn / ×2 | 0,5 | 0 / 0 | +1 | 0 | · | Hikâye (`pursuit`) |
| `dust_storm` | 4 | 14 / 20 | 40 | 0,7 | 0,1 | 0,3 | 40 sn / ×1,5 | 0 | −0,8 / −0,5 | 0 | 0 | · | Evet |

**Neden Kara Boran'ın rüzgârı 8.** structures §6.2 «Rüzgâr hızı 3 m/sn (Kara Boran 8)» yazar; act1 §10 dörtnala «± rüzgâr (1,5 m/sn)» der. Tek sayı ikisini birden tutar: sürüşte `±0,19 × rüzgâr`, 8 m/sn'de ±1,5 (§8.9). Kar yatay uçar çünkü yağış vektörü ayrı bir görsel değerdir (§9.4), rüzgârın oyun sayısı değil.

### 8.2 Görüş ve sis

- **Görüş** `vis` (m): türün değeri ile bölge sisinin (Kışlak Buz Kolu, Kara Boran Ak Otlak; `spec.weather.fogZones`) küçüğü.
- **Yapay zekâ görüşü** (nöbetçi, hayvan, takipçi): `R_eff = min(R, 0,6 × vis)`; ayrıca `fogK(d) = vis ≥ 100 ? 1 : clamp(1 − 2d / vis; 0,25; 1)` algı hızını çarpar (`dsdt × fogK`). Okuyan: `game/stealth-core` (10.4), `game/fauna` (8.6). **Neden 100 m eşiği:** Son Gece sisi 140 m'de durur; act1 §9.5 nöbet dengesine dokunulmaz. Eşiğin altı (sis, sağanak, dolu, tipi, toz, Kara Boran) gerçekten gizler: siste 10 m'deki oyuncu ×0,67 hızla fark edilir, 16 m'de ×0,47.
- **Oyuncu sezgisi** (`sense`, düğüm ve iz parıltısı): kullanım anında `sense × clamp(vis / 120; 0,4; 1)`. Okuyan: `world/nodes.js` `hot` taraması ve `game/hunting` (derive değişmez: önbelleği kare başına boşalmaz).
- **Takipçi kaybolma** (`lostRadius`): II. Perde'den `min(taban, 0,6 × vis)`. I. Perde'de act1 §10 «40 m'den uzaklaşan kaybolur» kuralı değişmez (pursuit sahibi).
- **Çizim sisi** ışık düzeninin sisine türün çarpanıyla uygulanır, sonra kamera tabanı (§3.4), en son sinemanın sis katmanı kazanır (§9.2).

### 8.3 Gizlilik

```
hearK      = 1 / (1 + mask + thunderMask)               // §8.1 maske; okuyan stealth-core
noiseR_eff = noiseR × hearK                             // çan, adım, balta, ateş; act1 §9.5 yarıçapları
thunderMask(t) = 3 × e^(−t / 1,2)                       // ses gelişinden sonra 3 sn; yalnız d ≤ 3 km gök gürültüsü
flashReveal: şimşek nabzında (fx.flashK > 0, ≈0,25 sn) act1 §9.2 «Karanlık» koşulu kapanır (time.md §9.9); saat başka çarpan vermez
cone: nöbetçi görüş konisi coneDeg (80°, architecture §3 addGuard) × yağmur ve sulu kar 0,85 (68°), sağanak ve dolu 0,75 (60°), tipi ve toz 0,7 (56°)
      (başlık ve kukuleta); tarama açısı (scanDeg, g01–g10 ±50°) değişmez; Kara Boran kovalamacadır, koni çarpanı yok
```

**Okunan oyun.** Şimşek tehlikedir (o an görünürsün), gök gürültüsü fırsattır (o an duyulmazsın). Uzaklığı sayan oyuncu ikisinin arasını kullanır: «çakınca say, gürleyince koş». Örnek: çanla yürüyüş 14 m; yağmurda 14 / 1,35 = 10,4 m; sağanakta 7,8 m; gök gürültülü fırtınada yakın gök gürültüsünden hemen sonra 14 / (1 + 0,6 + 3) = 3,0 m.

**I. Perde istisnası.** Kışlak'ta gök gürültüsü yoktur (kış iklimi). Kilitli gecelerde `pinFx.mask = 0`: act1 §9.5 çan yarıçapları ve §9.5 rota süreleri aynen geçerli.

### 8.4 İz, koku, av

- **İz ömrü** `life = taban × trackK`. Taban: act1 §9.2 Derin Kar 90 sn; yaz zemininde iz yalnız çamurda kalır (`mud` ≥0,5: 240 sn, kuru zeminde iz yok). Tipi ve Kara Boran'da 15 sn mutlak (act1 §9.2). Kar dindikten sonra 1 sa taze iz: `tracking` 1,5 kat eski izi okur. Okuyan: `world/track-decals` (10.4), `game/hunting` (8.6).
- **Koku** (survival §4 kuralının hava yüzü): menzil `20 m × scentK × yönK`. Rüzgâr ≥1 m/sn ise yönK rüzgâr altı 0,5, üstü 2 (survival §4 sayıları); fırtına (≥12 m/sn) üstü 2,5, altı 0,4; durgunda (<1 m/sn) yön yok, ×1. `scentK` §8.1. HUD rüzgâr oku (`downwind`) canlı yönü gösterir.
- **Av doğması** §7.6. **Balık:** yağmurda ağ verimi +1 (sonraki perdelerin akar suyunda; I. Perde buz deliği değişmez).

### 8.5 Kamp ateşi, pişirme, kurutma

survival §2 kuralı korunur ve genelleşir: «Tipi'de taşsız ateş 40 sn'de» (Tipi, Kara Boran, toz, fırtına) ve «kar yağışı süreyi ×1,5 hızlandırır» (`snow`, taşsız) aynen tablodadır. Taş halkası survival §2'deki +%50 yanma süresini korur; hava çarpanı onun üstüne gelir.

| Durum | Taşsız | Taşlı | Barınakta (yurt ocağı, sundurma) | Yakma | Pişirme |
|---|---|---|---|---|---|
| Açık, bulut, kapalı, sis | ×1 | ×1 | ×1 | 3 sn | Olağan |
| Rüzgâr | ×1,25 | ×1,1 | ×1 | 3 sn | Şiş ×0,9 süre (alev harlı) |
| Fırtına (rüzgâr) | 40 sn'de söner | ×1,5 | ×1 | Taşsız yakılmaz: «Bu rüzgârda taşsız ateş tutmaz.» / «No fire holds in this wind without stones.» | Şiş ×1,1 |
| Çisenti | ×1,25 | ×1,1 | ×1 | 4 sn, kuru kav | ×1,1 |
| Yağmur, sulu kar | ×1,5 | ×1,25 | ×1 | 5 sn; `dry_reed` ıslanır, `resin` ya da `birch_bark` gerekir: «Kav ıslak; kuru kav gerek.» / «The tinder is wet; you need dry tinder.» | ×1,2; korda ×1,5 |
| Sağanak, GGF | 60 sn'de söner | ×2 | ×1 | Açıkta yakılmaz | Kor pişirmesi yok |
| Dolu | 60 sn'de söner | ×1,5 | ×1 | Yakılmaz | Yok (oyuncu sığınır) |
| Kar | ×1,5 (survival §2) | ×1,25 | ×1 | 4 sn | ×1,1 |
| Yoğun kar | ×2 | ×1,5 | ×1 | 5 sn | ×1,2 |
| Tipi, Kara Boran | 40 sn'de söner (survival §2) | ×2 | ×1 | Taşsız yakılmaz | Şiş yok |
| Toz | 40 sn'de söner | ×1,5 | ×1 | Taşsız yakılmaz | Kalite −1 (kum) |

**Meşale.** Yağmurda yanma süresi ×0,5; sağanak ve dolu altında 20 sn'de söner; fener (`lantern`, kapalı) etkilenmez. **Kurutma** (survival §3 Kurutma Sırığı, `econ-model.json` `stations.drying_rack`): ilerleme × `dryK` (fiziksel, havanın): açık 1, bulut 0,9, rüzgâr 1,3, kapalı 0,6, sis 0,3, çisenti, yağmur ve sağanak 0 (durur), kar 0,3, toz 0,5. Sundurma ya da yurt içindeki raf `max(dryK, 0,6)`. Açıkta asılı yiyeceğin bozulması ekonominin tepkisidir (`d2/core.md` §3.3): sağanak bölümü başına %10, küçük dolu %20, iri dolu %50; toz kalite −1 (yalnız ateş başı yıldızı). Okuyan: `game/campfire`, `game/cooking` (8.5). Bu tablo kamp ateşinin ve pişirmenin hava tablosudur; `survival.md` §2'ye işlenir, ekonomi kendi pişirme çarpanını yazmaz.

### 8.6 Yapılar

**Sıçrama** (structures §6.2, `structure-logic.js` `spread`). Yerleşik kod `StructureManager.wind`, `.windDir` ve her yapının `spreadEntry.wet` alanını okur; Hava bunları yazar, mantık değişmez:

```
manager.wind    = clamp(rüzgâr + 0,5 × boraŞimdi; 0; 24)      // R = 10 + rüzgâr; varsayılan 3 korunur
manager.windDir = akış yönü (U.uWindDir'in yönü, birim)
spreadEntry.wet = keçe, saz: min(1 − 0,8 × felt, snowFelt)      ahşap: 1 − 0,4 × felt      taş, metal: 1
snowFelt        = Kışlak: taze kar (snow > 0,5) 0,2, aksi 0,5;  kar tutmayan iklimde 1     // structures §6.2 sayıları
```

**Yağmurla sönme.** Yanan, barınaksız her yapıya kare başına `douse(douseRate × dt)` (yerleşik `StagedStructure.douse`). Keçe henüz kuruyken ateşli ok (`burnT` 30) yağmurda `tickBurn` ile birlikte 15 sn yanar (7→6 olur, 6→5 için 30 sn gerekir), sağanakta 8,6 sn; meşale (`burnT` 70) yağmurda 35 sn (7→5), sağanakta 20 sn (7→6). Keçe ıslanınca ateşli okun gücü de yarıya iner (aşağıda): yağmurda 7,5 sn. Kar ve hafif kar söndürmez (`douse` 0): Son Gece oyalaması act1'deki gibi ≈70 sn'de 7→3.

**Islak keçe tutuşması.** Ateşli okun tutuşturma gücü `× (1 − 0,5 × felt)` (yerleşik kodda küçük değişiklik, `weather-delta-structures.md`). Kuru fırtınada ve kuru bozkırda keçe kurudur, yağmurda zor tutuşur: yünün gerçek davranışına yakın (structures §16 #3'ün tersine giden adım değil, havanın eklediği koşul).

**Dolu.** İri dolu (`hail_burst`un %30'u): `reed` birimi −0,5 Can/sn, `tent` örtüsü −0,2 Can/sn; küçük dolu `reed` −0,1. Taban: dolu bir yapıyı aşama 1'in altına indirmez, sağanak başına en çok bir aşama düşürür. Keçe ve ahşap dolu almaz. Hava `weather:hail { size: 'small'|'large', minutes, x, z }` yayar; tarlanın kaybı yerleşimindir (sağanak başına küçük %10, iri %30).

**Fırtına (rüzgâr).** Tetik açıktır: `fx.galeDamage = ortalama rüzgâr ≥16 m/sn ya da anlık bora >20 m/sn`. Tetik açık bir bölümde bağsız her `tent` örtüsü bir kez %25 olasılıkla bir birim aşaması düşer, bağsız `rack` içindekinin %20'sini döker; Can kaybı sürekli değil, bölüm başına tek zardır (ortalama fırtına bir çadırı yıkmaz). **Bağla / Tie Down** (`E` basılı 3 sn, çadır ve raf) kalıcı bir durumdur: söküm ya da çözme (`E` 1 sn) dek sürer. Hane ve ordugâh ekipleri fırtına işareti gelince kendi çadırlarını kendiliğinden bağlar (boşta el varsa); oyuncunun kurduğu çadırı oyuncu bağlar. Yurt ve ahır rüzgâr almaz (kolan ve kiriş). Taban: aşama 1'in altına inmez. Sayılar `structures.md` §6.5 (delta) ve yerleşimin tepki tablosunda aynıdır.

**Görünüm.** Islak keçe koyulaşır ve dikey akıntı izi alır (`U.uWet.y`, §9.8); karlı çatı Kışlak'ın kar kancasıdır (K2). Okuyan: `world/structure.js`, `world/structure-shader.js`. **Sıçrama yarıçapı** `R = 10 + manager.wind` tek kuraldır; yerleşim kendi sabit yarıçapını yazmaz.

### 8.7 Yıldırım

**Hücre modeli.** Fırtına bölümü üç evredir: yaklaşma (%25; hücre 8 km'den en yakın geçiş uzaklığı `b`'ye gelir, `b` 0–2 km), tepede (%50; hücre `b`'de), uzaklaşma (%25). Şimşek hızı 2 / 5 / 2 gdk⁻¹, %30'u yere iner; iniş noktası hücre merkezinin 1,2 km'lik dairesinde. Benzetim (20.000 fırtına, ortalama 263 sn): ≈15 şimşek, ≈4,6 yıldırım; fırtınaların ≈%33'ünde biri ≤600 m'de (eleştirmenin yeniden koşusu %32, taslak %35); doğal olarak ≤60 m'ye düşüş %0,5.

**Tasarlanmış yakın düşüş.** Tepede evresinde, fırtına başına bir kez:

- **Serbest Gez:** %60 olasılıkla, Çocuktan 30–70 m ötede, kameranın baktığı yönde, kadrajın içinde bir nokta seçilir (K39: kamera döner; Godot'nun varsayılan kadrajı kahramandan ≈13 m geriye, ≈240 m ileriye uzanır; prototipte 79 m kuzeye, 8 m güneye); yalnız ağaç ya da direk yeğlenir, ana kampın yapılarına inmez. Kadraj dışında kalan ≤1,5 km'lik düşüşler ekranın düşüşe en yakın kenarında kısa bir şerit ayağı ve parıltı çizer (FINAL katmanı, §9.3; 0 çizim). Kabul: kamp fırtınalarının ≥%50'sinde kadrajda bir yıldırım görünür (W25).
- **Oyun (Mete):** oyuncu açıktaysa %25 olasılıkla oyuncudan 0–45 m uzakta bir nokta seçilir.

Seçilen nokta gerçek yıldırım gibi uzun olana gider:

```
aday: 45 m içinde yalnız ağaç (h 6–14 m), yapı (`bounds.top`: yurt 8,6, kule 7, ahır 4,9 m), Sancak Direği (10 m), Gök Direği (12 m),
      araba (2,8 m), açıkta atlı (2,6 m), çıplak sırtta duran (yerel kabartma ek), yaya (1,7 m: eşik altı, seçilmez)
      adaylar world.tallThings'tir: yapı yöneticisi aşama değişince ekler ve siler (kurulan yapı aday değildir); flora kurulumda doldurur
h_eff = h × yalnızlık (yalnız 1; orman kıyısı 0,7; orman içi 0,4) + sırt (60 m içindeki yükseklik farkı)
skor  = h_eff − 0,15 × uzaklık;   en büyük skor > 0 ise hedef, değilse noktaya
uyarı: hedef oyuncunun 40 m içindeyse 1,5 sn önce `static_hum` ve hedefte ince halka (telegraf, kadraj sözleşmesi)
```

**Adil kurallar.**

| Kural | Neden |
|---|---|
| Oyuncu ancak skoru en büyükse vurulur: açıkta atlıyken noktaya 17 m'den yakınsa, çıplak sırtta 57 m'den yakınsa (nokta 0–45 m seçildiği için olanaklı) | Gerçek kural: sırttan in, atından in, yalnız ağacın altına sığınma |
| Oyuncuya düşen yıldırım Can'ı en çok %35 düşürür, 1'in altına indirmez, Yara açmaz, Düşüş getirmez | `progression.md` §8.5: Umay Eşiği yalnız Can bitince, «açlık ya da hava açmaz» |
| Çocuk (Serbest Gez) 25 m içinde hiçbir zaman hedef olmaz; yakın düşüş noktası ondan ≥25 m seçilir | Serbest Gez'de tehdit yok (`progression.md` §2.5); yalnız ışık ve ses |
| Hikâye zorluğunda oyuncu hiç hedef olmaz | §8.16 |
| Kurulmakta olan yapı (tamamlanmamış) hedef olmaz; vurulan yapı 1 oyun günü bekler; yerleşim fırtına başına en çok bir yapı | Oyuncunun emeği bir anlık zarla yanmaz |
| Islak keçe (`felt` ≥0,5) tutuşmaz: tepe birimine `blunt` 25 ve yanık izi | Yağmurlu fırtınada yurt yanmaz; tehlike kuru fırtınadır ve 2 sa önce görünür (§7) |
| Kuru fırtınada keçe (`felt` <0,3) tutuşur: `ignite({ power: 30 })`, ateşli okla aynı | Kuru bozkırda yıldırımla yangın gerçek ve hikâyelik |
| **Sancak Direği / Banner Pole** (`banner_pole`, 10 m, konut ve çekirdek parselinde): yurttan (8,6 m) 1,4 m uzundur, ≈9 m içindeki yurtların yerine yıldırımı o alır (tepe birimine `blunt` 25, iz; keçe flama kuruysa tutuşur). **Gök Direği / Sky Pole** (`sky_pole`, 12 m) yalnız Kutlu Tepe'dedir, yurtları korumaz: vuruşu perde başına bir alamettir, kuruysa tutuşur (meşale 70), ıslak fırtınada yalnız iz (`settlement.md` §12.4). Gözcü kulesi (7 m) de adaydır; varsayılan en uzun aday yurttur | Paratoner yok; uzun direğin çektiği doğa kuralıdır, oyuncu bunu öğrenir: yurtların arasına sancak dik |

**Etkiler.**

| Hedef | Etki |
|---|---|
| Mete (doğrudan) | Can −%35 (taban 1), 1,2 sn sendeleme, 3 sn sağırlık (ses −12 dB, `tinnitus`), Bağ <40 ise at atar (düşüş hasarsız), elindeki meşale düşer |
| 8 m içinde | 0,6 sn sendeleme, 2 sn sağırlık |
| Takipçi, kişi | 2 sn sendeleme, Can −20; ölmez |
| Yurt, ahır | Tepe birimine `blunt` 25 (tündük ahşap, `STRUCT.blunt.wood` 1); kuruysa tutuşur; yanık izi `addScorch` |
| Kule | Tepe birimine `blunt` 40 |
| Sancak Direği | `blunt` 25, iz; kuru flama tutuşur |
| Gök Direği | Alamet (`settlement.md` §12.4); kuruysa `ignite` (meşale 70), ıslaksa iz |
| Yalnız ağaç | Gövde kömürleşir ve yarılır (örnek rengi ve ölçeği), 60 sn duman; düğüm `struck` olur: 2 `charcoal` + olağan odun verir. Ağaç yanmaz, ateş yayılmaz (structures §6.2: yalnız yapıdan yapıya) |
| Araba | `c_tilt` keçesine `blunt` 15, koşum atı ürker |
| Zemin | Kara iz (yanık çıkartması, 120 sn), toz |

**Yıldırım Çamı.** act1 §4 Kara Yamaç'taki Yıldırım Çamı / Lightning Pine (470,150) bu kuralın eski izidir: Faz 9 kış ormanında yarık ve kömürleşmiş gövdeyle kurulur. Kışın fırtına yoktur; ad, geçmişte düşen yıldırımı söyler.

### 8.8 Ok ve yay

**Rüzgâr sapması.** Mermiye yan ivme: `a = k × rüzgâr` (m/sn²), atış anındaki rüzgârla donar (uçuşta değişmez, telegraf doğru kalır). `k`: ok 0,15, ateşli ok 0,18, ıslıklı ok 0,2, oyuncak ok 0,25, taş ve kemik 0,08, arbalet oku 0,08.

| Rüzgâr m/sn | 20 m | 40 m | 60 m (ok, 50 m/sn) |
|---|---|---|---|
| 4 | 0,05 | 0,19 | 0,43 |
| 8 | 0,10 | 0,38 | 0,86 |
| 12 | 0,14 | 0,58 | 1,30 |
| 16 | 0,19 | 0,77 | 1,73 |
| 20 | 0,24 | 0,96 | 2,16 |

Yakında önemsiz, uzakta okunur. Oyuncunun nişan halkası sapmayı içerir (halka gerçek iniş yeridir): rüzgâr oyunu bozan sürpriz değil, halkanın kayan yeridir. Düşman okçu rüzgârın %70'ini düzeltir; zemine 1,2 sn önce çizilen telgraf (act1 §10) gerçek iniş noktasıdır. Okuyan: `game/projectiles.js` (`s.wind`, `predict`).

**Islak kiriş** (`wet.bow`, 0..1). Yay eldeyken ıslanır: çisenti 1/300, yağmur ve sulu kar 1/120, sağanak 1/45, kar 1/400 sn⁻¹; dolu ve sis ıslatmaz. `gorytos` sadağında (`progression.md` §7.3, yay ve ok kılıfı) ıslanma ×0,5. Kurur: ateşin 4 m'sinde 1/20, barınakta 1/90, kuru havada 1/240 sn⁻¹. Etki `w = wet.bow × yayK` (bileşik yay 1: `saka_bow`, `fallen_bow`, `hun_bow`, `bone_bow`, `heavy_bow`, `horn_bow`, `great_bow`; ağaç yay 0,5: `toy_bow`, `loan_bow`; arbalet 0,3): hasar ×(1 − 0,15w), menzil ×(1 − 0,1w), çekiş süresi ×(1 + 0,1w). Çubukta yay simgesine damla düşer (w >0,3). **Neden:** bileşik yayın tutkalı ve sinir kirişi neme duyarlıdır; ceza en çok %15'tir, yağmurda okçuluk yasaklanmaz, kılıf ve ateş anlam kazanır. Okuyan: `game/derive` `env.wetBow` (0,25'lik basamak: önbellek en çok 30 sn'de bir boşalır; `architecture.md` §3.13 «kare başına çağrılmaz»).

### 8.9 At ve sürüş

| Tetik | Bağ <40 | 40–69 | ≥70 | Çocuğun atı (Serbest Gez) |
|---|---|---|---|---|
| Gök gürültüsü ≤1 km (gecikme ≤3 sn) | Şaha kalkar 1,2 sn (`horse_rear`), durur | Ürker 0,5 sn, hız ×0,6 | Etkisiz | Ürker 0,4 sn |
| Yıldırım ≤60 m | Şaha kalkar; dörtnaldaysa atar (hasarsız düşüş) | Şaha kalkar 1,2 sn | Ürker 0,5 sn | Ürker 0,6 sn, hiç atmaz |
| Dolu | 6 sn'de bir ürker, doluya yüz tutmaz | Hız ×0,85 | Etkisiz | Hız ×0,9 |
| Toz | Rüzgâra karşı dörtnal yok | Rüzgâra karşı hız ×0,8 | ×0,9 | ×0,9 |

Binek türleri `fauna.md` §2.1'dedir (K65). Binek Katır'ın gök gürültüsü ve yıldırım ürkmesi süresi ×0,5'tir. Binek Deve tozda yürür, dörtnala kalkmaz; `fx.cartLock` süren havada hızı ×0,5'tir; öteki satırları atınkidir (`fauna.md` §7). Bağ ≥70 at gök gürültüsüne aldırmaz (yukarıdaki sütun).

```
gallop  = taban ± clamp(0,19 × rüzgârBoyunca; −2; 2)       // act1 §10: Kara Boran 8 m/sn → ±1,5
horseDrain × (1 + 0,015 × max(0, karşıRüzgâr)), en çok ×1,25 // Tipide değil: orada act1 §10 tipiDrain geçer
çamur: dörtnal × (1 − 0,1 × mud) yol dışında
```

Okuyan: `game/mounted.js` ve `game/pursuit` kare başına (at yönü döndükçe rüzgâr payı değişir; `derive`'ın `gallop` ve `horseDrain` değerleri değişmez, act1 §10'un «± rüzgâr» terimi burada eklenir), `character/horse.js` (`spook`). Ahırdaki ve ağıldaki atlar yalnız canlandırma ve ses alır, kaçmaz.

### 8.10 Yol, araba, hızlı yolculuk

| Değer | Kural | `travel.md` |
|---|---|---|
| Yol hızı | `6,4 × (1 − 0,25 × mud)` m/sn: çamurda 4,8; taze kar örtüsünde `× (1 − 0,15 × snow)` | §2, §3.5 |
| Yol dışı | `2,4 × (1 − 0,4 × mud)`; kar ve derin kar act1 değerleri | §6.6 |
| Sarsıntı pürüzü | Yol `1 + 0,4 × mud`; kar 1,6; yol dışı 2,4; fırtınada ×1,3 | §6.6 |
| Yürüyüş | Yol dışında çamur ×(1 − 0,05 × mud) | · |
| Kalkış kilidi | `thunderstorm`, `dry_storm`, `hail`, `gale`, `blizzard`, `dust_storm`, `kara_boran` (`fx.cartLock`): yeni kilit `weather`, kalan süre plandan, yarım saate yuvarlanır. Sağanakta ve yoğun karda araba yavaş da olsa kalkar | §8 tablosuna satır |
| `fx.cartK` | `(1 − 0,25 × mud) × (1 − 0,15 × snowFresh) × tür` (fırtına 0,85, yoğun kar 0,7, öteki 1): yağmurdan sonra ≈0,8, yoğun karda ≈0,7 | Yerleşimin kervanı yol gününü ortalama `cartK`'ye böler (`settlement.md` §11.3) |
| Yük hayvanı (K65) | Yük Devesi yol dışı gider, `fx.cartK`'yi okumaz; `fx.cartLock`'ta durmaz, hızı ×0,5'tir. Yük Atı, Eşeği ve Katırı arabanın kuralını alır (`fauna.md` §2.2) | §3.2, §9.9 |
| Yoldaki araba | Sonraki Menzil'de bekler; yağmurda yolcu keçe çatı altında kuru (`c_tilt` aşama 1) | §6.1 |
| Yolu Kısalt | Yağmurda açık, kilitte kapalı | §6.5 |
| Çevre arabaları | `sev` ≥3'te şerit durur ve uçta bekler | §10.2 |

**Yol Kartı satırı.** `lock.weather`: «Fırtına dinmeden araba kalkmaz (≈{n} saat).» / «No cart leaves until the storm passes (about {n} hours).»

**Atlas yolları.** `travel.md` §9.1 «Kış ×0,7» çarpanı aynen kalır; havanın atlastaki yüzü yol olaylarıdır (§9.6 havuzu, ağırlık uç dünyaların iklim payından):

| id | TR / EN | Ağırlık | Seçim | Sonuç |
|---|---|---|---|---|
| `ev_storm` | Fırtınaya Yakalanma / Caught in the Storm | GGF + fırtına + dolu payı | Sığın / Shelter · Sür / Ride On | +0,5 gün · −1 Yiyecek, yedek at %25 topallar (`ev_lame`'e bağlanır) |
| `ev_dust` | Toz Duvarı / Wall of Dust | Toz payı (Gobi, Alaşan, Ordos) | Yere Yat / Lie Low · Yön Bul / Find the Way | +0,5 gün · %50 yol kaybı: +1 gün, −1 Yem |
| `ev_flood` | Sel / Flash Flood | Sağanak payı, yaz | Bekle / Wait · Geç / Cross | +0,5 gün · arabadan −4 Yük, insan ve at kaybı yok |
| `ev_snowbound` | Karda Kalış / Snowbound | Yoğun kar + tipi payı, kış | Kazın / Dig In · Yürüyün / Push On | +1 gün, −2 Yiyecek · −1 Yem, `fatigue` +20 |

Gecelik Çadır taşıyanın (K46) `ev_storm` «Sığın» seçimi bedelsizdir, `ev_snowbound` «Kazın» −1 yiyecektir. Taş Yığını'na taş bırakılan seferde (K35) yol olayı olasılığı %25'ten %20'ye iner; dört hava olayı da bu sayıya girer (`travel.md` §9.6). Varış dünyasının havası varış saatinde planlayıcıdan gelir (§5.7).

### 8.11 İnşa ve işçiler (K21)

Şantiyenin hava çarpanı ve durakları emek alanının tablosudur (`d2/core.md` §2.8; `sleet` ve `dry_storm` satırları dahil). Hava bu tabloya şunları verir: bölümün türü (`fx.type`) ve şiddeti; gece sınıfı için `fx.cloud` (`time.md` §12.3: bulutlu gecede ay ışığı yoktur, ateş ya da meşale gerekir). Ustalar beklerken emek tablosunun sığınma kuralına uyar: yalnız `all` durağında (dolu, tipi, Kara Boran, toz) ya da ne şimdiki ne sonraki adım ilerleyebiliyorsa en yakın yurda ya da ahır çatısının altına yürür (`SHELTER`); adımın hava çarpanı 0,25 sa (37 sn) işe izin verince döner. HUD: `lock.weather_build` «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» İş miktarı (iş günü) değişmez, takvim uzar: kampta ortalama ≈%8.

### 8.12 NPC programı, sürüler

- **Sığınma.** `sev` ≥3 iken açık hava yuvasındaki nöbetçi olmayan kişiler yuvanın `shelter` noktasına (yoksa evine) yürür; `sev` 0,25 sa <2 kalınca döner. Nöbetçi yerinde kalır, koni daralır (§8.3). Şantiye ekipleri bu kurala değil emek tablosuna uyar (§8.11). Okuyan: `game/schedule.js`, `game/npcs.js` (10.3).
- **Serbest Gez kampı.** Ana, Baba ve Ağabey (K37) kapı önüne çekilir, ozan kopuzunu kılıfa koyar (`perform.stop`; K60), ocak başındaki statik kişiler menü karesi için yerinde kalır; Serbest Gez'de `child.js`'in ikizleri yürür (`architecture.md` §8 karar 16 deseni). Ağabey fırtınada ahırın kapısını tutar (§7.3). Kampın kışında (K67) tipi ve yoğun karda (`sev` ≥3) halk yurda girer: statik figürler `time.md` §8.2'nin kuralıyla yalnız kadraj dışındayken ya da karartma altında gizlenir, ikizleri kapıdan girer, ateş başı boşalır; hava 0,25 sa `sev` <2 kalınca programa dönerler.
- **Sürüler.** Fırtınada ve tozda sürü sıkışır, kıçını rüzgâra döner; doluda koşuşur. I. Perde'nin 60 atı (kukla) aynı kuralı GLSL yönüyle alır (yalnız yön ve sıkışma).

### 8.13 Ordu (`army.md`)

```
fatigueGain × K;   K: yağmur 1,2 · sağanak 1,5 · dolu 1,5 · kar 1,2 · yoğun kar 1,6 · tipi 2 · fırtına (karşı rüzgâr) 1,4 · toz 1,6;  çamur × (1 + 0,3 × mud)
Han birliği: K_han = 1 + 2 × (K − 1)          // Chao Cuo: 風雨罷勞…中國之人弗與也
ay olayları (Dolunay tavanı, Eksilen ay cezası) takvimden: calendar.moonIllum (army.md §3.5); bulut onları değiştirmez
akın penceresi (K55): moon_illum(dayN + 0,5) ≥ 0,97; bulut ve hava pencereyi değiştirmez, aynı kayıt aynı akını verir
Çadırsız yağmur gecesi: morale −2;  yakın yıldırım: drilled/strength < 0,3 olan birlikte morale −6
Salvo: yayılma × (1 + 0,02 × yanRüzgâr); ıslak kiriş hasar ×(1 − 0,15w) (Han arbaleti 0,3 ile)
lostRadius (II+): min(taban, 0,6 × vis)
```

Okuyan: `game/squad/army-data.js`, `game/squad/index.js` (10.6). Bir tümen sisli şafakta daha sıkı yürür. Bulutlu gece ay ışığını keser (gece yürüyüşü `nightClass` ile yavaşlar, gözcü satırı §7.3), ama ayın evresine bağlı moral olayını değiştirmez: Shiji'nin 月盛壯則攻戰'ı gün sayılarak bilinen evredir. Bir hava bağı istenirse sahibi `army.md`'dir (öneri: `pious` birliğin dolunay ×1,5'i yalnız `moonSeen` iken).

### 8.14 Ekonomi ve yerleşim kancaları (K23, K24)

Hava değer üretmez; fiziksel durumu verir, tepki sahibinin tablosundadır (`d2/core.md` §3.3).

| Kanca | Değer | Okuyan (tepkinin sahibi) |
|---|---|---|
| `dryK(x, z)` | §8.5 kurutma çarpanı | Kurutma sırığı, keçe kurutma, deri kurutma (atölye çatısı altında ≥0,6); bozulma payları ekonominin |
| Açık yığın ıslaklığı | Yağmur ve sulu karda `node_ground_pile` içindeki yakıt ve yem `wet` olur: yakıt değeri ×0,5, 2 sa `dryK` ≥0,6 ya da ateşin 4 m'sinde 30 sn kurur. Ambar, araba, heybe kurudur | Ekonomi; I. Perde'de yığınlar şafakta toplanır (`economy.md` §3.2), Kış Hesabı değişmez |
| `node_mushroom` | Son 12 sa'te ≥1 sa yağmur: sayı ×2; değilse ×0,5 | `world/nodes.js` |
| `node_dung` | Yağmurdan sonraki 6 sa yakıt ×0,5 | Kışlak'ta yağmur yok: Kış Hesabı değişmez |
| `weather:hail { size, minutes, x, z }` | Dolu olayı | Yerleşim: tarla (yalnız Surlu yolda, K54) sağanak başına küçük %10, iri %30; kuzu kaybı |
| Otlak | Yağışlı yaz: `pasture` yeniden büyüme +%10; 7 günde <%3 ıslak saat: −%10 | `economy.md` §8.4 atlas katmanı |
| Yıldırım ağacı | `struck` ağaç 2 `charcoal` + olağan odun verir | Yeni malzeme gerekmez |
| `snowpack`, `deepSnow`, `crust` | §5.9 zon durumu ve `d2/weather-model.json` payları | Yerleşim: sürü yemi, otlak ×0,3, yemsiz %2/gün; ordugâh `horse_fat` −2/gün; ekonomi kış yemi |
| `fx.galeDamage` | §8.6 tetik | `structures.md` §6.5 ve yerleşim: bağsız çadır ve raf |
| `fx.cartLock`, `fx.cartK` | §8.10 | Yerleşimin kervanı |
| Sancak ve Gök Direği | §8.7 aday kuralı | Yerleşim §12.4 (alamet) |

### 8.15 Çocuk (Serbest Gez)

Tehdit yok; hava kampın havasıdır ve takvimin mevsimini okur (K67). Kışın kar örtüsünde Çocuk iz bırakır (iz çıkartması, §8.4), yürüyüş hızı değişmez: Serbest Gez'de ceza yoktur; tipide Ana çağırır ve Çocuk Yurt A'ya yönlendirilir (yalnız satır, zorlama yok). Çocuk birikintiye zıplarsa (`puddle` >0,3, toprak zemin) su sıçrar (`splash`, sıçrama havuzu); kar serpintisinde durunca başını kaldırır (`lookAtPoint` göğe, 2 sn); dolu altında kollarını başına kaldırır (yeni `cover_head` jesti, `gestures/story.js` ya da `labour.js` sahibine istek), hız ×0,9. Ana fırtınada çağırır (§7.3). Oyuncak ok rüzgârda sürüklenir (0,25): 8 m/sn'de 14 m'de 0,3 m. Yapı hasarı, yangın ve yıldırım çocuğa ya da kampa zarar vermez (§8.7).

### 8.16 Zorluk

| Ayar | Hikâye | Normal | Zor |
|---|---|---|---|
| İşaret süresi | ×1,5 | ×1 | ×0,75 (en az 0,75 sa) |
| Yıldırım oyuncuyu hedefler | Hiç | Kural | Kural |
| Yıldırım oyuncu yapısını tutuşturur | Hiç (yalnız iz) | Kuru fırtınada | Kuru fırtına ya da `felt` <0,5 |
| İri dolu oyuncuya | Yok | Can −0,5/sn 8 sn sonra, taban %40 | Can −0,75/sn, taban %30 |
| Islak kiriş cezası | ×0,5 | ×1 | ×1 |

### 8.17 Dolu ve beden

Açıkta ve barınaksız Mete: küçük dolu stamina dolumunu ×0,5 yapar; iri dolu 8 sn sonra Can −0,5/sn (Normal), %40'ın altına indirmez, Yara açmaz (`progression.md` §8.5). Barınak (`shelterAt` ≥0,5: yurt, ahır, sundurma, araba keçesi, orman kıyısı yarım) korur. Okuyan: `game/player.js` (8.8). **Neden:** dolunun işi oyuncuyu sığınağa koşturmaktır; öldürmek değil. Kampta ve Kışlak'ta (kış iklimi, dolu yok) ceza yoktur.

## 9. Çizim

### 9.1 İlke

Çalışma zamanında ışık eklenmez, silinmez (§0 kural 7); render hedefi değişmez (K3); menü karesi bit bit aynı kalır (§0 kural 8). Havanın görüntüsü dört yoldan gelir: var olan ışıkların yoğunluk ve rengi, sis ve kubbe uniform'ları, paylaşılan uniform'lar (`U.*`) ve iki küçük ağ (yağış ve sıçrama noktaları tek geometride, yıldırım şeridi). Bütçe §9.11.

### 9.2 Kompozisyon hattı

```
K20 saati ──► ışık düzeni tabanı   world.lightBase (ClockSystem 4 Hz yazar; yön oyun dakikasında bir adım): güneş rengi ve yoğunluğu, yarımküre, sis, kubbe anahtarları, göl, kenar ışığı, pozlama
          ──► hava çarpanı         WeatherView.compose(base, p): §3.4 çarpanları, sis rengi ve kamera tabanı, bölge sisi
          ──► şimşek nabzı         pozlama × (1 + A·f), yarımküre yoğunluğu + B·f ve renk, kubbe uFlash
          ──► sinema sis katmanı   world.setFogOverride kazanır (`architecture.md` §3.8)
          ──► post                 profil (applyProfile) → post.weather katmanı (doygunluk, karşıtlık, ton, parlaklık; ekran yağışı) → FINAL
```

**Tek yazıcı** (K26, `time.md` §12.6). Menü yolu `applyMood(t)` değişmez: menü, Yeni Oyun, oluşturucu ve `home` saat ve hava okumaz. `freeroam` ve `play`'de saat yalnız `world.lightBase` düz kaydını yazar (`setTimeOfDay`); güneşi, yarımküreyi, sisi, kubbe, göl, köy ve kenar ışığı uniform'larını ve pozlamayı yalnız `world.writeLight()` yazar: 8.9'da kimlik (tabanın kopyası), bu paketten (9.4) `WeatherView.compose(base, params, flash)`. Hava kimlikse ve şimşek yoksa `compose` tabanı olduğu gibi yazar (hızlı yol): sayılar bugünkü `applyMood` ile aynı sırayla aynı değere çıkar. `compose` karede en çok bir kez, yalnız taban, hava ya da şimşek değiştiyse çalışır; 4 Hz'lik taban yazımı şimşek nabzını kesmez, çünkü nabız her karede tabanın üstüne yeniden uygulanır. Hava çarpanı yalnız burada bir kez uygulanır.

### 9.3 Ekran yağışı (FINAL katmanı)

Kuwahara boyası (`paint` 3,1 px) bir iki piksellik çizgiyi komşu ortalamasına eritir; yağmur sahnede çizilirse ancak gri bir tül kalır. Bu yüzden yağmur, kar, dolu ve toz çizgisi boyadan sonra, FINAL'de çizilir. Üç katman: yakın, orta, uzak; her katman düşüş yönüne dönmüş bir ızgarada hücre başına en çok bir damla (hücre karmayla seçilir; tek doku okuması boya darbesiyle kenarı kırmak içindir).

```glsl
// world/weather-hooks.js PRECIP_FINAL → core/post.js FINAL; tilt bulanıklığından sonra, doygunluktan önce.
uniform vec4 uPrecip;      // x yağmur, y kar, z dolu, w toz: 0..1. Toplam 0 iken dal çalışmaz: menü kimliği
uniform vec4 uPrecipDir;   // xy ekranda düşüş yönü (birim), z kar salınımı, w çizgi boyu
uniform vec3 uPrecipOff[ 3 ];   // katman kayması: düşüş × zaman + kamera paralaksı (CPU biriktirir), z katman tohumu
uniform vec3 uPrecipCol;   // ışık düzeninden: göğün rengi × pozlama payı

float pHash( vec2 p ) { vec3 q = fract( p.xyx * 0.1031 ); q += dot( q, q.yzx + 33.33 ); return fract( ( q.x + q.y ) * q.z ); }

float pLayer( vec2 uv, float scale, vec3 off ) {
  vec2 d = uPrecipDir.xy, n = vec2( -d.y, d.x );
  vec2 q = vec2( dot( uv, n ), dot( uv, d ) ) * scale + off.xy;
  vec2 cell = floor( q ), f = fract( q ) - 0.5;
  float h = pHash( cell + off.z );
  float dens = uPrecip.x * 0.55 + uPrecip.y * 0.7 + uPrecip.z * 0.35 + uPrecip.w * 0.6;
  if ( h < 1.0 - dens ) return 0.0;
  f -= ( vec2( pHash( cell + 7.1 ), pHash( cell + 3.7 ) ) - 0.5 ) * vec2( 0.6, 0.2 );
  f.x += sin( off.y * 0.7 + h * 40.0 ) * uPrecipDir.z;                      // kar salınımı
  float rain = ( 1.0 - smoothstep( 0.018, 0.035, abs( f.x ) ) ) * ( 1.0 - smoothstep( 0.27 * uPrecipDir.w, 0.45 * uPrecipDir.w, abs( f.y ) ) );
  float snow = 1.0 - smoothstep( 0.06, 0.12, length( f ) );
  float hail = 1.0 - smoothstep( 0.03, 0.07, length( f * vec2( 1.0, 0.45 ) ) );
  return rain * ( uPrecip.x + uPrecip.w * 0.6 ) + snow * uPrecip.y + hail * uPrecip.z * 1.4;
}

// main():
if ( uPrecip.x + uPrecip.y + uPrecip.z + uPrecip.w > 0.0 ) {
  vec2 uv = vUv * vec2( uAspect, 1.0 );
  float a = pLayer( uv, 34.0, uPrecipOff[ 0 ] ) * 0.55 + pLayer( uv, 22.0, uPrecipOff[ 1 ] ) * 0.75 + pLayer( uv, 13.0, uPrecipOff[ 2 ] );
  a *= 1.0 - blur * 0.5;                                                     // diyorama bulanığında sönük
  if ( uFocus.w > 0.0 ) a *= smoothstep( uFocus.z * 0.9, uFocus.z * 1.3, length( ( vUv - uFocus.xy ) * vec2( uAspect, 1.0 ) ) );   // oda içi kuru
  a *= 0.85 + ( texture2D( tBrush, vUv * 7.0 ).g - 0.5 ) * 0.3;               // boya darbesiyle kırık kenar
  c = mix( c, uPrecipCol, clamp( a, 0.0, 1.0 ) * 0.5 );
}
```

**Paralaks ve sarma.** CPU her kare katman kaymasını yazar: `off[i] = mod(off[i] + düşüş × hız[i] × dt + ekranKayması × paralaks[i], P)`, `P = 256` hücre; gölgelendiricide karma `pHash(mod(cell, P) + off.z)`'dir, sarma dikişsizdir ve kayma uzun oturumda büyümez (mediump GPU'da da 60 dakikalık günler boyunca çizgi keskin kalır, W17); `ekranKayması` oyuncunun ekrandaki izdüşümünün kare farkıdır, paralaks 0,6 / 1 / 1,4. Böylece kamera kayınca yağmur camdaki damla gibi değil, havadaki yağmur gibi okunur. Düşüş yönü 3B yağış vektörünün (rüzgâr + yerçekimi) oyuncu konumundaki izdüşümüdür: rüzgârda çizgiler yatar. Katman hızı (UV/sn): yağmur 2,4 / 1,6 / 1; kar 0,12 / 0,08 / 0,05; dolu 3; toz yatay 1,2. Oda içinde (`uFocus`) yağış görünmez. Bedel ≈20 ALU × 3 katman, 1 doku okuması; 2,6 MP'de ≤0,3 ms (hesap).

**Katman alfası ve ölçüm (K58, kullanıcının #16 ve #51 cevabı).** Karışımın son çarpanı (`* 0.5`) katman alfasıdır. Okunurluk soru değil, ölçüm işidir: W16 karelerinde çizgi boyalı süzgeçte zayıf okunursa alfa 0,65'e çıkar; başka değer denenmez. Kareler ışık durağı klasörüyle aynı oturumda çekilir (`time.md` §5.3: altı durak × Mete × kar ve ot × iki yakınlaştırma; ekran yağışı kartları aynı oturumda; `sanat-animasyon.md` öneri 17). Yöntem `godot.md` §8.5'tir: sabit poz, `tests/refs/`, piksel farkı ve ΔE; göz onayı kullanıcınındır. Godot'da katman `PainterlyOverlay`'den sonra, son geçişte çizilir; yeni hava görünümleri (kuru fırtına, sulu kar, dolu, toz) aynı klasörde sınanır. Doğrulanacak: iş Yol Haritası'nın `weather` maddesindedir ([/roadmap#act-1-p1](/roadmap#act-1-p1)).

**Kadraj dışı yıldırımın ayağı.** Ana kampta kadraj dışında ≤1,5 km'ye inen yıldırım için aynı dal `uBoltEdge` (vec4: ekran x, genişlik, güç, zaman) ile ekranın düşüşe en yakın kenarında 0,35 sn'lik toplamalı kısa bir şerit ayağı ve parıltı çizer: 0 çizim, 0 program. Varsayılan kadrajda bu kenar üst kenardır (kuzey); kamera dönünce düşüşün ekrandaki yönü kenarı seçer (K39).

### 9.4 Yağış noktaları (3B)

`THREE.Points`, en çok 6000 nokta (`drawRange` etkin sayıya), öznitelik `aSeed` (vec4, 96 KB), malzeme `weather_pts`. Konum gölgelendiricide tohumdan ve saatten çıkar, dünya kutusunda sarılır: kamera kayınca noktalar yerinde kalır, yalnız kutunun kenarında döner.

```glsl
attribute vec4 aSeed;                   // xyz kutu içi 0..1, w boy ve tür zarı
uniform vec3 uBoxC; uniform vec3 uBox; uniform vec3 uFall; uniform float uT; uniform vec4 uMix; uniform float uPointMax;
void main() {
  vec3 lo = uBoxC - uBox * 0.5;
  vec3 p = aSeed.xyz * uBox - uFall * uT * ( 0.8 + 0.4 * aSeed.w );
  p = mod( p - lo, uBox ) + lo;                                   // dünyaya bağlı sarılma
  p.x += sin( uT * 1.3 + aSeed.w * 40.0 ) * 0.25 * uMix.y;          // kar salınımı
  vec4 mv = viewMatrix * vec4( p, 1.0 );
  gl_Position = projectionMatrix * mv;
  gl_PointSize = min( mix( 2.6, 2.0, uMix.z ) * ( 34.0 / -mv.z ) * ( projectionMatrix[ 1 ][ 1 ] / 2.9 ), uPointMax );   // kıvılcım kuralı (fire.js)
}
```

| Değer | Kar | Yoğun kar, tipi, Kara Boran | Dolu | Sulu kar | Toz |
|---|---|---|---|---|---|
| Nokta | 3000 | 6000 | 1500 | 1500 | 600–2000 |
| Düşüş m/sn | 1,2 + rüzgâr ×0,6 | 1,6; tipide yatay 14 | 14 | 4 | Yatay, rüzgâr ×1 |
| Boy, renk | 2,6 px, ak | 2,6 px, ak (Kara Boran koyu gri-mavi) | 2 px, parlak ak | 2,2 px, gri | 1,6 px, okr, α 0,4 |

Kutu 70 × 30 × 90 m, merkez odak + 25 m kameranın baktığı yönde, +8 m yukarı (prototipte kamera kuzeye bakardı, act1 §4: kadraj tepesi 79 m kuzey; K39'dan beri kamera döner, kutu kameranın yatay açısıyla döner). Godot'da yağış `GPUParticles3D`'dir, kutu aynı ölçüdedir (`godot.md` §3). Sis elle uygulanır (uzaklıkla sönme, sis yakın ve uzak uniform'u). Derinlik sınaması açık, yazımı kapalı, `renderOrder` 7 (duman 6'nın ardında). `uPointMax` 14 px (`ambient.js` zerreleriyle aynı). Boyalı süzgeç parlak küçük lekeyi korur (`PAINT` `pop` kuralı): kar boyada leke olarak yaşar. Yağmur 3B nokta almaz; yağmurun derinliği sıçrama ve birikintidedir.

### 9.5 Sıçrama ve sekme

Yağış noktalarıyla **aynı geometri ve aynı çizim**: tamponun son 192 noktası sıçrama havuzudur, nokta başına kip özniteliği (`aSeed.w`'nin üst biti) gölgelendiricide yolu seçer; `drawRange` etkin yağış sayısı + 192'dir. Konumu CPU yazar: karede en çok 32 yeni sıçrama, odak çevresinde 24 m'lik dairede, kameraya bakan yarıya ağırlıklı; `y = world.groundAt(x, z) + 0,03`, `world.shelterAt(x, z) ≥ 0,5` ise atlanır (yurt içi, ahır). Yağmur sıçraması 0,25 sn'de açılan taç; dolu sekmesi 0,4 sn'de üç sekişli ak tane. Sayı türün `splashes` değeri (§3.4). Birikintide halkalar zemin kancasındadır (§9.8), çizim almaz. CPU ≤0,05 ms (32 `groundAt`).

### 9.6 Şimşek ve yıldırım

**Nabız.** Yere inen şimşek 1–4 dönüş vuruşudur: ilk vuruş 8 ms yükselir, 60 ms söner; sonrakiler 70–140 ms arayla, tepe 0,6–0,9. Bulut içi şimşek 1–2 yumuşak vuruş (tepe 0,5, sönüm 150 ms).

| Uygulama | Yere ≤2 km | Bulut içi | Uzak >2 km |
|---|---|---|---|
| Pozlama `world.mood.exposure × (1 + A·f)` | A 1,6 | 0,6 | 0,3 |
| Yarımküre yoğunluğu `+ B·f`, renk `#dfe6ff`'e karışır | B 3 | 1,2 | 0,6 |
| Kubbe `uFlash = f`, `uFlashDir` | Evet | Evet | Evet |
| Göl `uSky + 0,4 f` | Evet | Hayır | Hayır |

Işık eklenmez: var olan yarımküre ışığının yoğunluğu ve rengi değişir, pozlama `game.applyPost` ve `cine.applyPost`'un okuduğu `world.mood.exposure` üstünden gelir. Bloom eşiği (1,5) şeridin HDR rengini zaten parlatır.

**Şerit.** Yalnız ≤900 m'deki ve görüş konisindeki (ya da kubbe görünürken) yıldırım için; ana kampta tasarlanmış düşüş kadraja seçilir (§8.7), kadraj dışındaki kuzey düşüşü üst kenar ayağıyla görünür (§9.3). Bulut tabanından (zeminin 220 m üstü, hücre yönünde) iniş noktasına orta nokta kaydırmalı çizgi: 32 parçalık gövde + 2 dal (8'er), kameraya dönük şerit, 96 üçgen, genişlik 0,6 m (uzaklıkla ölçekli). `ShaderMaterial` toplamalı, renk (6; 6,6; 8) × f, sis kapalı, derinlik sınaması açık, yazımı kapalı. Vuruş başına bir kez kurulur (≤1 KB, ayırma yok: öznitelik dizisi önceden ayrılır), 0,35 sn görünür. Program `weather_bolt` (+1). Zemin izi `world/track-decals.js` havuzundan bir çıkartma (Faz 10.4; o gelene dek `fxGlow` 2 sn parıltı).

**Erişilebilirlik** (`a11y.flashes`, §11): `full` ×1; `soft` A ve B ×0,35, tek vuruş, vuruşlar arası en az 0,4 sn (saniyede ≤2,5 parlama, WCAG 2.3.1'in 3 eşiğinin altında); `off` A ve B 0, şerit ×0,3, ses sürer. Hareketi Azalt (`a11y.reduceMotion`) açıkken yakın yıldırımın kamera sarsıntısı (`game.shake(0,04; 0,25)`, ≤30 m) yoktur.

### 9.7 Bulut örtüsü, bulut gölgesi, gök kubbesi

**Zemindeki bulut gölgesi** (`paint-material.js` `BRUSH_FRAG`, bütün boyalı malzemeler):

```glsl
vec2 cuv = vPW.xz * uCloudInfo.x + uTime * uCloudInfo.y * vec2( 1.0, 0.6 ) + uCloudPhase;          // uCloudPhase yeni, menüde 0
gCloud = 1.0 - uCloudInfo.z * smoothstep( 0.46 - uCloudInfo.w, 0.72 - uCloudInfo.w, texture2D( uCloud, cuv ).r );   // w örtü, menüde 0
vec2 fd = vec2( cos( uFront.z ), sin( uFront.z ) );                                                 // cephe hattı (§7.1 cover)
gCloud *= 1.0 - uFront.w * smoothstep( -40.0, 40.0, dot( vPW.xz - uFront.xy, fd ) ) * 0.55;         // w 0: kimlik
```

`uCloudInfo.z` = profilin `cloudShadow` değeri × türün `shadowK` (WeatherView her kare `post.settings.cloudShadow`'dan okur, birikmez). `uCloudPhase` rüzgârla birikir: `+= yön × (cloudSpeedK − 1) × 0,006 × dt` ve bulut dokusunun periyodunda (1) sarılır; `uSkyPhase` kubbe dokusunun periyodunda, `uWindPhase` 2π'de sarılır: hız değişince desen sıçramaz, uzun oturumda kayan değer büyümez. `uFront` cephenin son 0,25 sa'inde (37 sn) rüzgâr yönünden 8 m/sn ile vadiyi geçer: fırtınanın gölgesi yaklaşırken görünür.

**Gök kubbesi** (`world/sky.js`): yeni uniform'lar, hepsi menüde 0:

| Uniform | Anlam |
|---|---|
| `uCover` | Örtü eşiği kaydırması: `smoothstep(0,545 − uCover, 0,6 − uCover, n)` |
| `uDark` | Bulut ve gök karanlığı: `cc *= 1 − 0,6·uDark`, gök rengi gri-maviye |
| `uFlash`, `uFlashDir` | Şimşek: bulutun içi yönlü parlar |
| `uHalo` (vec2) | Ay ya da güneş halesi: güç, 22° yarıçap (`halo` işareti) |
| `uFront` (vec3) | Ufukta cephe duvarı: yön ve güç |
| `uDust` | Toz rengi (okr) karışımı |
| `uGap` (vec4) | Bulut açıklığı: yön, yarıçap (Gök Açılır, Kara Boran yıldızı) |
| `uSkyPhase` | Kubbe bulut kayması (rüzgârla) |

### 9.8 Islak zemin, ıslak keçe, kar tazeliği

`U.uWet` (vec4: x zemin, y keçe, z taze kar ya da serpinti, w birikinti) ve `U.uWetFx` (vec4: x yağmur şiddeti (birikinti halkası), y dolu beyazlığı, z çamur, w boş). Kancalar `world/weather-hooks.js`'te düz GLSL dizgesidir; okuyan malzemeler:

| Kanca | Malzeme | Etki (uniform 0 iken kimlik) |
|---|---|---|
| `WET_GROUND` | Kamp zemini (yakın, uzak), kaya, çim, çiçek, orman | `diffuse *= 1 − uWet.x × 0,28 × yukarı` (`yukarı = smoothstep(0,3; 0,9; normal.y)`); çimde ×0,2 |
| `PUDDLE` | Kamp yakın zemini | Düz (normal.y ≥0,97) ve alçak frekans gürültü maskesinde koyulaşma, gök tonu; `uWetFx.x` ile halka: `sin(r × 40 − uTime × 9)` |
| `MUD` | Kamp yakın zemini, patika | Patikada `uWetFx.z` ile koyu, doygun toprak |
| `FELT_WET` | Yapı kabuğu `struct_tex`, yalnız dış yüz | `× (1 − uWet.y × (0,18 + 0,1 × akıntı))`; akıntı fırça dokusunun dikey bileşeni; iç duvar kuru (dışa bakan normal sınaması) |
| `SNOW_FRESH` | Kışlak kar kancaları (`*_w`, K2) | Taze kar parlak ve pürüzsüz, fırça darbesi ×0,7; çıkartma (yol, iz) sönükleşir |
| `HAIL_WHITE` | Kamp zemini, çim | `uWetFx.y` ile ak taneli örtü; 0,5 sa'te erir |

Karakterler (Mete, `Folk`, at) kanca almaz: derece katmanı yeter, program da değişmez. Program sayısı değişmez (anahtar aynı kalır, kanca karması yeni GLSL'i ayırır: `paint-material.js` `hookHash`).

### 9.9 Rüzgâr: çim, ağaç, duman, bayrak, alev

`windK = sqrt(max(rüzgâr, 0,3) / 3)`: 3 m/sn'de 1 (structures §6.2 tabanı), 9'da 1,73, 16'da 2,31.

| Nesne | Uygulama | Menü |
|---|---|---|
| Çim, çiçek (`grass.js` `WIND`) | `U.uWindDir = yön × 0,918 × windK` (bükülme büyüklüğü vektörün boyudur, GLSL değişmez); bora deseni `(uTime + uWindPhase)`: `uWindPhase += (windK − 1) × dt` | `uWindDir` (0,8; 0,45), faz 0: bugünkü sayılar |
| Ağaç (`flora.js` salınım) | Salınım genliği `× min(uWindK, 2,2)` | `uWindK` 1 |
| Bayrak, sancak (`camp.js` dalga) | Genlik `× uWindK`, dalga saati `uTime + uWindPhase` | 1, 0 |
| Duman (`fire.js` `Smoke`) | CPU: `puff.x += rüzgâr.x × h × 0,035`, `puff.z` aynı; yükselme `× (1 − 0,4 × sink)` (§7 `smoke_sink`) | `wind` 0, `sink` 0: duman yalnız saate bağlı kalır |
| Alev (`fire.js` `FLAME`) | Yeni paylaşılan `FLAME_LEAN` (vec2): `p.xz += uLean × position.y²` | 0 |
| Göl (`valley.js`) | `uGlowAmt × (1 − 0,3 × min(1, rüzgâr / 12))`; `uSky` örtüyle griye | Var olan uniform'lar |
| Yağış | Ekran çizgisi eğimi, kar savrulması, tipide yatay kar (§9.3, §9.4) | 0 |

### 9.10 Sis, göl, uzak arazi

Sis çarpanı ve rengi §3.4; kamera tabanı yakın ≥0,5 × kamera uzaklığı, uzak ≥ kamera uzaklığı + 50 m. Hava etkinken gölün sis aralığı `LAKE_FOG_R × fogFarK` olur (sinemanın katmanı gelince onunki). Bölge sisi (`spec.weather.fogZones`): Kışlak Buz Kolu çizgisinin 120 m'si gece ve şafakta uzak ×0,4 («buz inler, sis», act1 §4); Kara Boran'da `pale_pasture` 45–80 m (act1 §10). Uzak arazi (`far` ağ) zaten sisle söner; tipide ve tozda ufuk hiç görünmez.

### 9.11 Bütçe

Tablo prototipin tarayıcı bütçesidir. Godot bütçesi `godot.md` §7.2'dir (K63): kampta kare hedefi 16,7 ms, sınır 33 ms; iç haritada 16,7 / 28 ms; çizim ve üçgen motorun sayacıyla, görünür ve gölge geçişi ayrı ölçülür. Kesme sırasında havanın payı `godot.md` §7.5 madde 7'dir: parçacık sayısı yarıya iner, ekran yağışı bir katman azalır. Ölçüm bütçe sahnesiyle (`scenes/dev/budget_probe.tscn`) fırtınalı karede de koşar.

| Parça | Çizim | Üçgen | Program | VRAM | CPU | GPU (2,6 MP, hesap) |
|---|---|---|---|---|---|---|
| Ekran yağışı ve kadraj dışı yıldırım ayağı (FINAL) | 0 | 0 | 0 (FINAL metni) | 0 | ≈0,01 ms | ≤0,3 ms |
| Yağış ve sıçrama noktaları (tek geometri) | 1 | 0 (≤6000 + 192 nokta) | +1 `weather_pts` | 99 KB | ≤0,06 ms | ≤0,1 ms |
| Yıldırım şeridi | 1 (≤0,35 sn) | ≤96 | +1 `weather_bolt` | 4 KB | ≤0,05 ms vuruş başına | ≈0 |
| Işık, sis, kubbe, bulut, rüzgâr, ıslaklık | 0 | 0 | 0 (metin değişir) | 0 | ≤0,05 ms | ≤0,1 ms (kancalar) |
| Planlayıcı, etki | · | · | · | · | Kare ort. ≤0,03 ms, saat sınırında ≤0,3 ms | · |
| **Toplam, en kötü** | **≤2** | **≤96** | **+2** | **≈0,1 MB** | **≤0,2 ms** | **≤0,5 ms** |

| Sahne | Etki | Tavan (`architecture.md` §7) |
|---|---|---|
| Serbest Gez, fırtına + dolu + şerit, gündüz | +2 çizim, +96 üçgen | 446 menü + 9 Çocuk + 45 üçüncü yurt + 6 araba + 6 saat ikizi + 2 = 514 > 511: **`Smoke` birleşmesi (5.2, −30) önkoşuldur** → 484 ≤511; düşerse gündüz ikizi 1'e iner (511) |
| Kışlak, yoğun kar | +1 çizim, 6000 nokta | act1 §15 «kar» satırı (40k, 21 çizim) içinde; nokta üçgen değildir |
| Kara Boran | +1 çizim | ≤220 çizim, ≤1,2M: değişmez |
| Yerleşim, en kötü | +2 | ≈198 + 2 ≤213 (`settlement.md` §17) |
| Program | Menü 57 → 59, Serbest Gez 57 → 59, oluşturucudan sonra 72 → 74; yerleşim dünyası +6 ile | ≤92; kışta `*_w` ile ≤100 |

**Önce ne kesilir** (`architecture.md` §7 sıra 8 «Etki» satırına ek): ekran yağışı 3 → 2 katman, nokta 6000 → 3000 (zaten yazılı «kar 6000 → 3000»), sıçrama 192 → 96, şimşek dönüş vuruşu 4 → 1. `video.quality` low aynı kesintileri baştan uygular.

### 9.12 Menü güvencesi

1. `WeatherView.identity()` her uniform'u bugünkü değerine yazar: `U.uWet`, `U.uWetFx` 0; `U.uCloudInfo.w` 0, `U.uCloudPhase` (0, 0), `U.uFront.w` 0; `U.uWindDir` (0,8; 0,45), `U.uWindK` 1, `U.uWindPhase` 0; `FLAME_LEAN` 0; kubbe hava uniform'ları 0; `post.weather` kimlik; ışık hızlı yolu; `Smoke` rüzgârı 0; `StructureManager.wind` 3, yön varsayılan, `spreadEntry.wet` 1; ağlar gizli; hava döngüleri listeden çıkar, müzik `rain` katmanı 0.
2. Tetik: `app:state` → `menu`, `newgame`, `creator`, `home`: 1,7 sn'de (menüye dönüş uçuşu, saatin ışığıyla aynı süre) kimliğe karışır, karışım bitince değerler tam yazılır (karışımın kalıntısı kalmaz).
3. `menuDiff` (`devtools.js` `drawMenuFrame`, `L`) ölçümden önce hava durumunu saklar, `world.weather.identity(0)`, `world.setTimeOfDay(null)` ve `campLife.menuPose(true)` çağırır, sonra hepsini geri yükler (post ayarlarını sakladığı gibi; `time.md` §5.5). Serbest Gez sürerken de çalışır.
4. Hava ağları yükleyicide derlenir: `app.start` derleme geçişinde görünür yapılır, sonra gizlenir (`architecture.md` §8 karar 36 deseni): ilk yağmurda derleme takılması olmaz.
5. Kabul: Serbest Gez'de ıslak zemin, yıldırım şeridi, dolu ve rüzgârdan sonra menüye dönüşte `menuDiff` 0 piksel (§15 W12).

## 10. Ses

Bütün sesler kodla üretilir (`audio.md` §4), ortam döngüleri 22 kHz tek kanal (K12). Yüzer nokta tampon 88,2 KB/sn. (K59, K61 ile değişti) Godot'da müzik ve efekt kodla üretilir ve başsız araçla dosyaya basılır (`tools/bake_music.gd`; Ogg ve WAV); WAV QOA ile sıkıştırılır, ortam döngüleri 22,05 kHz mono içe aktarılır (`force/mono`, `force/max_rate_hz = 22050`). Dünya başına yüklü ses en çok 26 MiB'tır: müzik 16, efekt ve ortam 8, seslendirme 2. Godot kampının bugünkü ElevenLabs ortam ve efekt dosyaları, kodla basılan katman kullanıcının kulak onayından geçene dek kalır; onay Karar Bekleyenler'de (onay): katman katman, önce kamp müziği, kredisiz. ElevenLabs'in efekt ucu yalnız kod yetmezse yedek olarak kullanılır (ör. `lake_bull`, §10.2), her iş önce kullanıcıya sorulur. Aşağıdaki reçeteler ve MB sayıları prototipin tarayıcı tamponunadır.

### 10.1 Yeni ortam döngüleri (`audio/ambience.js`)

| id | Süre | Bellek | Reçete |
|---|---|---|---|
| `rain_light` | 8 sn | 0,71 MB | Pembe gürültü → bant geçiren 2,5 kHz Q 0,6, yavaş gezinme; damla çıtırtısı 40/sn (1–3 ms, 3–6 kHz); 150 Hz hafif gövde. `far_rain` işareti aynı tamponun alçak geçiren (900 Hz) 3B uzak çalınışıdır |
| `rain_heavy` | 8 sn | 0,71 MB | Yoğun gürültü, alçak geçiren 5 kHz; 200 Hz gövde gezinmesi; sıçrama çıtırtısı 180/sn |
| `rain_felt` | 6 sn | 0,53 MB | Keçe çatı: alçak geçiren 1,2 kHz, düzensiz yumuşak tıpırtı (300 Hz kısa modal darbe, 25/sn); yurt içinde ve dışarıda 3B yurdun tepesinden |
| `hail_bed` | 4 sn | 0,35 MB | Sert tıkırtı 120/sn, genlik dağınık, bant 2–4 kHz; zeminde 600 Hz takırtı; alçak gürültü tabanı |
| `wind_gale` | 10 sn | 0,88 MB | `wind_winter` deseni + 90 Hz uğultu, iki uluyan bant (600–900 Hz, Q 10), keçe çırpınması (alçak geçirenli darbe dizisi) |
| `dust_storm` | 10 sn | 0,88 MB | Yüksek geçiren tıslama 3,5 kHz (kum), bora gezinmesi, alçak gövde |

**Pişirme.** Yükleyici yalnız iklimin olası türlerinin döngülerini tanır; bir döngü ancak planda (≥1 sa = 150 sn önce) cephe görünce dilimli pişer (`ambience.warm`, kare başına ≤4 ms) ve cephe geçtikten 1 sa sonra bırakılır (o iklimde payı %10'u aşmıyorsa). Kampta yerleşik en çok `rain_light`, `rain_heavy`, `rain_felt`, `hail_bed` ve gök gürültülü fırtınanın `wind_gale`'i: 3,18 MB; efektlerle (≤2,5 MB) 5,7 MB; Kışlak'ta `wind_gale`: 0,88 MB (`blizzard`, `wind_winter` var). Kampın bugünkü efekt ve ortam önbelleği ≈8–9 MB; saatin ekleri ≤0,5 MB: bunlarla ≈15,2 MB; K20 ve K21 ekleri (`birds_day`, `wolf_howl`, `torch_post`), `thunder` ve `splash` ile bırakmasız ≈18,8 MB, `audio.md` §4 «Bellek»in bırakma kurallarıyla en kötü ≈16,6 MB (eski 16 MiB `BAKE_BUDGET` = 16,78 MB). (K59 ile değişti) Prototipte efekt ve ortam havuzu artık 24 MiB'tır, sayı içinde kalır. Godot'da aynı dosyalar QOA ile ≈4 kat küçülür (44 kHz mono bir saniye ≈17 KB); efekt ve ortam havuzu dünya başına ≤8 MiB'tır. W19 bunu kampta fırtınalı akşamda ve 23:00'ten sonra ölçer.

### 10.2 Yeni efektler (`audio/sfx/weather.js`)

| id | Değişken | Süre | Sınır | Reçete |
|---|---|---|---|---|
| `thunder_crack` | 2 | 3 sn | 1 | Yakın (≤600 m), `ref` 400: yırtılan çatırtı (hızlanan crackle), sert patlama, 45 Hz gövde |
| `thunder_far` | 2 | 6 sn | 1 | Uzak (3–10 km), `ref` 400: alçak geçiren 300 Hz yuvarlanma, yavaş kabarma |
| `static_hum` | 1 | 1,6 sn | 1 | 100/200/300 Hz vızıltı, seyrek çıtırtı, kabarma: yakın yıldırım uyarısı |
| `gust` | 2 | 2,5 sn | 1 | Bant gezinmeli gürültü kabarması; rüzgârın geldiği yandan pan |
| `rain_drip` | 3 | 0,3 sn | 1 | Tek damla: 1,2 kHz → 600 Hz kısa sinüs ve tık |
| `hail_tick` | 3 | 0,15 sn | 1 | Sert tık 3 kHz; keçe üstünde boğuk |
| `tinnitus` | 1 | 2,5 sn | 1 | 4 kHz sinüs sönümü; master −12 dB: vurulunca 3 sn, düşüş 8 m içindeyse 2 sn (§8.7) |
| `lake_bull` | 1 | 3 sn | 1 | Göl boğası (K35, `mitoloji.md` öneri 13): uzak alçak böğürtü, 70–110 Hz gezinen testere ve gürültü, alçak geçiren 400 Hz, uzun yankı; yalnız göllü dünyada (ana kamp), GGF ve fırtına cephesinden 1 sa önce `far_rain` kanalında bir kez; cepheyle pişer (≈0,26 MB, 22,05 kHz). Önce kodla basılır ve kulakla sınanır; doğrulanacak, soru değildir: Yol Haritası'nın `weather` maddesi ([/roadmap#act-1-p1](/roadmap#act-1-p1)). Yalnız kod inandırıcı olmazsa ElevenLabs efekt ucundan tek dosya alınır (K61), kredisi önce kullanıcıya sorulur |

Var olan `thunder` (`sfx/world.js`, 4,2 sn, `ref` 400) orta uzaklıktır (0,6–3 km). Seçim uzaklıkla: ≤600 m `thunder_crack`, 0,6–3 km `thunder`, 3–10 km `thunder_far`; gecikme (`d / 343` sn) dolunca `sfx.play(id, { at: iniş, gain })`, panner `inverse`, üç bantta `ref` 400. Hepsi reçetede `sr: 22050` (22,05 kHz) taşır; motorun varsayılanı 32 kHz'dir ve verilmezse bellek ≈%45 büyür. Efekt belleği ≈2,5 MB, fırtına cephesiyle pişer. `splash` (`sfx/gather.js`) Çocuğun birikintisinde kullanılır.

### 10.3 Müzik

`music.setAmbientLayer('rain', g, 4)` (Faz 3'te bırakılan kanca: «weather owner calls it»): çisenti 0,35, yağmur 0,2, sulu kar ve kar 0,15, yoğun kar 0,1, yağmur sonrası 0,45 (0,5 sa'te söner), öteki 0. `rain` katmanı çan damlalarıdır (`music-states.js` `bell: 'rain'`): yağmurdan sonra müzik damlar. Yalnız ortam durumlarında uygulanır: `camp`, `camp_night`, `winter_day`, `winter_evening`, `winter_night`, `hold`, `hold_night`; `home` ve `road_leg`'de hava yoktur (§6.3, §12.4); hikâye müziklerine (`chase`, `raid`, `erlik`, `tengri`, `tension`, `court`, `muster`) dokunulmaz. Yakın gök gürültüsü müziği 2 sn −3 dB indirir.

### 10.4 Karıştırma

İki sahip aynı anda `ambience.set` çağırırsa biri ötekini siler. Bu yüzden Hava döngü listesi vermez, veri verir; listeyi tek sahip kurar:

```js
weather.audio = { beds: [{ id, gain, at?, lp? }], windK, windSwap, quiet, inside }   // her kare yerinde yazılır
// app/sounds.js (L), kampta; Faz 9'da kış dünyasının ses sahibi aynı birleşimi yapar:
// liste = taban(durum, ışık): rüzgâr döngüsü × windK (windSwap ise wind_gale'e geçer), ötekiler × quiet
//       + weather.audio.beds;  yurt içindeyse (inside) yağmur → rain_felt, rüzgâr × 0,4
// ambience.set(liste) yalnız kimlik listesi değişince ya da bir kazanç 0,05'ten çok oynayınca, en çok 4 Hz
```

### 10.5 Düğüm bütçesi

Hava en çok iki döngü (2 × 2 düğüm) ve bir 3B döngü (3) ekler; tek seferliklere tek 3B pay (3) ayrılır: gök gürültüsünün üç bandı, `gust`, `rain_drip`, `hail_tick` ve havanın çaldığı `felt_flap` onu paylaşır, biri çalarken yenisi düşer, yalnız daha yakın gök gürültüsü çalanı 0,1 sn'de keserek girer. Hava gecikmeli gök gürültüsünü gecikme (`d / 343` sn) dolunca `sfx.play`'e verir, `delay` vermez: `sfx.play` gecikmeli atımın düğümlerini hemen kurar ve 10 km'de 29 sn sayar. `static_hum` konumsuz çalar (2); `tinnitus` (2) yalnız `play`'de, Mete vurulunca ya da düşüş 8 m içindeyse. Serbest Gez'de en çok 12: ölçüm ≤25 (Faz 3) → fırtınada ≤37, tavan 40 (`architecture.md` §7).

## 11. Arayüz

- **HUD simgesi** (`ui/hud/weather.js`, `HudWidget`, yuva `tr`, zaman alanının saatinin yanı). Kodla çizilmiş SVG, 10 simge: güneş, güneş-bulut, bulut, sis, yağmur, fırtına (bulut ve şimşek), dolu, kar, rüzgâr, toz. Cephe 1 sa içindeyse altında ince ok. Üstüne gelince ya da dokununca §7.4 satırı; `iron_stake` ile §7.5 satırı. DOM yalnız değişince yazılır (§7 «kare başına DOM yazımı yok»).
- **Ayar satırı** (`registerSettingRow`, kitap Ayarlar): «Şimşek Parlaması / Lightning Flashes»: «Tam / Full», «Yumuşak / Soft», «Kapalı / Off». Anahtar `a11y.flashes`, okuyan `world/weather.js`.
- **İstem.** «Bağla / Tie Down» (çadır, raf; `E` 3 sn; kalıcı) ve «Çöz / Untie» (`E` 1 sn). Ret satırları: «Kav ıslak; kuru kav gerek.» / «The tinder is wet; you need dry tinder.» · «Bu rüzgârda taşsız ateş tutmaz.» / «No fire holds in this wind without stones.»
- **Yol Kartı.** `lock.weather` satırı (§8.10); fırtınanın ortasına varışta «Fırtına sürüyor» / «The storm is still raging» (§5.7).
- **İnşa göstergesi.** `lock.weather_build` satırı (§8.11) `hud/build-status.js` altında.
- **Tür adları.** `weather.type.<id>` (§3.1 TR / EN sütunu), alt olaylar `weather.event.<id>` (§3.2), tahmin adları `weather.noun.<id>` (§7.5). Hepsi `src/i18n/strings/weather.js`.

## 12. Uygulama taslağı

Bu bölüm Three.js prototipinin taslağıdır. Godot'da aynı kurallar şu biçimdedir (`godot.md` §3, §3.1): saf `WeatherPlanner`, `WetState`, `SnowPack`, `WeatherFx` sınıfları `Session`'da `GameClock` ve `GameCalendar`'dan sonra adım atar; görünüm `WeatherView`'dur (yağış `GPUParticles3D`, şimşek, ekran yağışı); veri `data/weather/types.json`, `climates.json` ve `d2/weather-model.json`'dır. Planlayıcının RNG'sinin bit bit mi taşınacağı fikstür denemesiyle seçilir (`godot.md` §11). Kural farkı olursa bu belgenin sayısı kazanır (K31).

### 12.1 Modüller

| Dosya | Saf | Önerilen paket | Tek sorumluluk |
|---|---|---|---|
| `src/data/weather-types.js` | Evet | 8.10 | §3 tür vektörleri (`cloud` dahil), §8.1 etki sayıları |
| `src/data/climates.js` | Evet | 8.10 | §4 paylar, eğriler, hâkim rüzgâr, dünya → iklim |
| `src/game/weather-core.js` | Evet | 8.10 | Planlayıcı (sabit çapa), ayar, karışım, ıslaklık, kar örtüsü ve kabuk, `fxFor`, `strikePick`, `signsFor`, kayıt biçimi |
| `src/game/weather.js` | Hayır | 8.10 | `WeatherSystem` (GameSystem), `ctx.weather`, kilitler, işaretler, alt olaylar, ses verisi, panel |
| `src/i18n/strings/weather.js` | Evet | 8.10 | §7, §8, §11 dizgeleri |
| `test/weather-core.test.js`, `test/weather-fx.test.js`, `test/weather-strike.test.js` | | 8.10 | §15 |
| `src/world/weather.js` | Hayır | 9.4 | `WeatherView`: noktalar (sıçrama dahil), şerit, `compose` (tek ışık yazıcısı), `identity` |
| `src/world/weather-hooks.js` | Evet (yalnız dizge) | 9.4 | GLSL dizgeleri: §9.3, §9.7, §9.8 |
| `src/audio/sfx/weather.js` | Hayır | 9.8 | §10.2 reçeteleri |
| `src/ui/hud/weather.js`, `src/ui/css/weather.css` | Hayır | 9.8 | §11 HUD |

### 12.2 Arayüzler

```js
// game/weather-core.js (saf)
export class Planner {
  constructor({ climate, season, exclude = [], seed, zone, types, climates });
  plan;                          // Segment[]: plan[0] şimdiki bölüm, ≥12 sa ileri
  advance(hourAbs);              // saat sınırında: kuyruğu doldurur, geçen bölümü atar
  lock(id, opts);  release(id);  locks;
  at(hourAbs, out);              // → { a, b, k }: karışan iki bölüm ve oran
  toJSON();  fromJSON(o);
}
export function calibrate(target, opts);          // §5.6; anahtarla önbellekli
export function blend(pa, pb, k, out);            // WeatherParams karışımı, ayırmasız
export class WetState { step(dtH, p, opts);  skip(hours, p);  toJSON();  fromJSON(o); }
export function fxFor(p, wet, opts, out);         // WeatherFx'i yazar (§12.5)
export function strikePick(cands, point, rules);  // §8.7 → aday | null
export function thunderDelay(d);                  // d / 343
export function signsFor(plan, nowH, opts, out);  // §7.2 → bekleyen işaretler

// game/weather.js: GameSystem { id: 'weather', order: 22, modes: ['freeroam', 'play'] }
attach(ctx);                    // ctx.weather = this; bus 'app:state' (kimlik), 'clock:hour', 'clock:skip' (long dahil), 'dawn'
// Yayılan olaylar: 'weather:change' { from, to, sev }, 'weather:front' { type, inH }, 'weather:strike' { x, z, target },
//                 'weather:hail' { size, minutes, x, z }, 'weather:thunder' { d }, 'weather:crust' { zone, on }  (kare başına olay yok)
onWorld(world);                 // spec.weather, iklim ayarı (≈45 ms, önbellekli), kayıttan durum, adaylar (world.tallThings)
update(dt, t);                  // saat → planlayıcı; karışım; alt olaylar; ıslaklık; fx; audio; world.weather.apply(...)
place(dt, t);                   // sıçrama konumu, aynı nokta tamponunun sıçrama dilimine (aktörler yerleştikten sonra)
fx;  audio;                     // §12.5, §10.4
lock, release, progress, pin, freeze, calm, flash, strike, gap;   // §6.1
shelterAt(x, z);                // 0..1: oda, yapı, araba koltuğu, orman kıyısı (spec.weather.shelters ek)
windAt(x, z, out);              // m/sn vektör; kuytu ve sükûnet (calm) uygulanmış
next(hours);                    // [{ type, at, sev }]: HUD ve gök okuma
debug();

// world/weather.js
export class WeatherView {
  constructor(world, spec);     // World.build sonunda; kendi tohumu: kamp RNG akışı değişmez
  meshes;                       // [points (yağış + sıçrama), bolt]: yükleyici derlemesinde görünür yapılır
  compose(base, p, flash);      // world.writeLight'ın 9.4 hâli: tek ışık yazıcısı; kimlikte tabanın kopyası
  apply(p, fx, ev, cam, dt);    // uniform'lar, sis, kubbe, rüzgâr, kutu, katman kayması (sarılı); ayırma yok
  flash(power, dirXZ);  bolt(from, to, seed);  splashAt(x, y, z, kind);
  identity(fade = 0);           // §9.12
  update(dt);                   // world.updaters: kimliğe karışım menüde de sürer
  dispose();
}
```

### 12.3 `WorldSpec.weather`

```js
weather: {
  climate: 'orkhon',                 // §4.1
  season: 'calendar',                // K67: her dünyada calendar.season; hikâye kilidi geçersiz kılabilir
  seasonRows: { spring: 'camp_spring', summer: 'camp_summer', autumn: 'camp_autumn', winter: 'camp_winter' },  // kamp; öteki dünyalar null
  exclude: [],                       // Kışlak: ['heavy_snow', 'blizzard']
  accumulate: { snow: ['winter'] },  // kampta kar yalnız kışın tutar; Kışlak her mevsim
  snowFelt: 1,                       // keçenin kar çarpanı tabanı; Kışlak 0,5 (structures §6.2)
  dur: { snow: { spring: [1, 3] } }, // iklimin süre farkı: kampta bahar serpintisi 1–3 sa
  box: [70, 30, 90], points: 6000, splashes: 192,  // sıçrama aynı tamponun son dilimi
  fogZones: [],                      // Kışlak: Buz Kolu 120 m, Kara Boran Ak Otlak
  shelters: null,                    // (x, z) => 0..1 ek barınak
  menu: 'identity',                  // kamp: menüde ve sinemada kimlik
}
```

`world.tallThings` (Faz 9 `flora.js` kurulumda doldurur; yapı yöneticisi aşama değişince ekler ve siler, kurulmakta olan yapı aday değildir): `[{ id, x, z, h, kind: 'tree'|'pole'|'tower'|'structure', lone }]`, oynanan alanda en çok 256.

### 12.4 Sistem sırası

`| 22 | weather | game/weather.js | freeroam, play |`. Saatten (`clock` 15, `calendar` 20) sonra, `regions` (30) ve okuyucularından (`campfire` 52, `structures` 60, `sites` 61, `settlement` 64, `stealth` 84, `travel` 90, `nodes` 100, `sound` 110) önce: hepsi aynı karenin `fx`'ini okur. `home` kipinde çalışmaz (hava kimlik).

### 12.5 `WeatherFx` (okuyanların yüzü)

```js
fx = {
  type, sev, front,                 // şimdiki tür, ağırlık, yaklaşan cephe { type, inH } | null
  wind, gust, dirX, dirZ,           // m/sn, akış yönü (birim)
  cloud, vis, fogK,                 // gök örtüsü 0..1 (§3.4 sütunu; lightLevel, moonSeen, nightClass); görüş m; fogK(d) için vis (§8.2)
  mask, thunderMask, hearK,         // §8.3
  flashK,                           // 0..1: o anki şimşek (görüş ifşası)
  trackK, trackAbs,                 // iz çarpanı; tipide 15 sn mutlak (null değilse)
  scentK, calm,                     // §8.4
  fireK, fireOutS, fireRing,        // §8.5: taşsız çarpan ya da söner sn, taşlı çarpan
  douse, dryK,                      // §8.5, §8.6
  wetGround, wetFelt, mud, puddle, snowFresh, wetBow,   // §5.9
  cartK, roughK, cartLock,          // §8.10
  snowpack, deepSnow, crust,        // §5.9 zon durumu
  galeDamage, hail,                 // §8.6: fırtına tetiği; { size, minutes } | null
  strikeRisk, moonSeen,             // §8.7; moonSeen yalnız ışık ve görsel (§3.4)
  blizzard,                         // blizzard ya da kara_boran: act1 §10 kuralları
  fatigueK,                         // §8.13
  pin,                              // etkin pinFx (okuyan kendi sayısını korur)
};
```

### 12.6 Etki op'u ve sinema satırı

`effects.js` (`architecture.md` §3.14 tablosuna satır): `weather` | `do, id?, ...` | `do`: `lock`, `release`, `progress`, `pin`, `freeze`, `calm`, `flash`, `strike`, `gap`; `ctx.weather` yoksa (hava sistemi kurulmamışsa, ör. `node` sınaması) yok sayılır. Sinema (`architecture.md` §3.19): `{ t, weather: { do: 'lock', id: 'cine_x', type: 'thunderstorm', blend: 3 } }`; `release()` sinemanın kilitlerini kaldırır. `schema.js` ikisini doğrular, `check-data` tür kimliklerini denetler.

### 12.7 Kayıt

Yolculuk bloğu `world.weather`, `order` 78 (`world.sites` 76 ve `settlement` 77'den sonra: yapı ıslaklığı ve `struck` geri yüklenen şantiyeye ve yapıya yazılır), sahip `game/weather.js`, ≤1 KB:

```js
{ v: 1, seed: 2654435761, zone: 'hexi_winter', climate: 'hexi', season: 'winter', at: 131.25,
  plan: [ { type: 'snow', t0: 129.5, t1: 133, src: 'sim' }, /* ≤10 */ ],
  wet: [0.12, 0.3, 0.05, 0, 0.8, 0],          // ground, felt, mud, puddle, snow, bow; üç basamak
  packs: { hexi_winter: { snowpack: 0.42, crust: 0 } },   // zon durumu (§5.9); crust: kalan gün
  locks: [ { id: 'a1_last_night', type: 'snow', k: 0.42 } ],
  struck: { 'tanhu_ordu:s17': 101.2 },        // yıldırım beklemesi, site kimliğiyle
  said: ['front:129.5'] }                     // söylenmiş işaretler, ≤16
```

Plan sabit çapadan yeniden üretilebilir (§5.5); kayıttaki plan yalnız sınama ve hızlı açılış içindir. Serbest Gez: `tanhu.roam.weather` aynı biçim (`progression.md` §13.4: dosyadaki öteki alanlar korunur), 30 sn'de bir ve `leave`'de yazılır; `season` kayıttaki günün mevsimidir, `packs` kampın kış kar örtüsünü de taşır (K67). Kayıt bozuksa ya da yoksa: o saatten taze plan, `roam_first` kuralı. Godot'da kayıt v2'nin `weather` bloğu aynı alanları taşır (`godot.md` §3.4).

### 12.8 Geliştirici paneli `__tanhu.weather`

`devtools.register('weather', panel)` (§0 kural 4: `devtools.js` düzenlenmez):

```js
state()                          // tür, vektör, plan (12 sa), ıslaklık, kilitler, bekleyen işaretler, fx
set(type, { hold = true, blend = 6 })   // zorla; hold false ise planlayıcı sonra sürer
clear()                          // dev kilidini kaldırır
plan(hours = 12)                 // sonraki bölümler
seed(n)                          // yeni tohum, plan yeniden kurulur
skip(hours)                      // zaman alanının saatini ileri alır (clock.skip → clock:skip)
wind(speed, fromDeg)  wet({ ground, felt, mud, snow, bow })  freeze(on)  calm(on)
flash(power = 1)  thunder(distanceM)  hail(size = 'large')
strike(target)                   // 'near' | 'tree' | 'yurt:<id>' | 'player' | [x, z]
fx(x, z)                         // o noktadaki bütün çarpanlar
sim(climate, season, days = 1000)   // saf çekirdekle paylar, bölüm sayısı, en büyük sapma
calibrate()                      // ayarlı ağırlıkların dökümü (gömme seçeneği, §5.6)
budget()                         // çizim, üçgen, program, ms, ses MB
identity()                       // menü kimliği (menuDiff için)
```

### 12.9 Var olan sözleşmelere bağ

| Sözleşme (`architecture.md`) | Bağ | Değişen |
|---|---|---|
| `StagedStructure`, `StructureManager` (§3.11) | `wind`, `windDir`, `spreadEntry.wet` yazılır; yanan yapıya `douse`; yıldırımda `hit` ve `ignite` | Yalnız ateşli ok tutuşma çarpanı (§8.6) |
| `NodeStore`, `NodePools` (§3.12) | Yağmurda açık yığınların `flags` dizisinde bir `wet` biti (`piles`); `onDawn` doğma çarpanını `node-kinds.js` `weather` alanından okur (`node_mushroom` ×2 / ×0,5); tipide `NodePools.setMode('blizzard')` zaten var | `node-kinds.js` satırına `weather` alanı; kayıt `economy.nodes` içinde |
| `Inventory` (§3.13) | Eşya ıslanmaz; ıslaklık yığının ve yayın durumudur. `gorytos` `equipped` ise kiriş ıslanması ×0,5 | Yok |
| `derive` (§3.13) | `env.wetBow` (0,25 basamaklı), `env.blizzard` (act1 §10 `tipiDrain`, var); öteki hava etkileri kullanım anında `fx`'ten | `env` alanına `wetBow` |
| `SupplyLedger` (§3.22) | Kış Hesabı değişmez (Kışlak'ta yağmur yok). II+ yerleşim (`own_seat`) ve ordugâh (`own_camp`, `field_camp`): ıslak yığından teslim edilen yakıt ×0,5 sayılır (teslim anında yığının bitinden) | Yok |
| `army.md` §3 (`UnitRec`) | `fatigue` kazancı × `fx.fatigueK` (Han ×2), `morale` olayları (§8.13); ay olayları takvimden (değişmez) | Yok |
| `Travel`, `LOCKS` (§3.17) | `lock.weather` kilidi, ETA plandan; atlas yol olayları havuzuna dört olay | `travel-data.js` |

### 12.10 Faz yerleşimi (Faz 7 sonrası, K26)

| Paket | Dosyalar | Bitti |
|---|---|---|
| 8.10 Hava çekirdeği | §12.1'in 8.10 satırları, `src/game/projectiles.js` (rüzgâr sapması, `predict`), `tools/weather-model.mjs`, `docs/design/d2/weather-model.json` | §15 W1–W11, W26; `node --test` |
| 9.4 (genişler) Hava görünümü | `src/world/weather.js`, `src/world/weather-hooks.js`, `src/world/sky.js`, `src/world/flora.js`, `src/world/grass.js`, `src/world/fire.js`, `src/world/camp.js` (bayrak), `src/world/terrain.js` (zemin kancaları), `src/core/post.js`, `src/core/paint-material.js` | §15 W12–W18, W25; `menuDiff` 0 |
| 9.6 (ek satır) | `src/world/structure-shader.js` `FELT_WET`, `src/world/structure.js` tutuşma çarpanı ve aday kaydı | `structures.md` §17 1, 5, 10 değişmez |
| 9.8 Hava sesi ve arayüzü | `src/audio/sfx/weather.js`, `src/audio/ambience.js`, `src/ui/hud/weather.js`, `src/ui/css/weather.css`, `src/core/settings-schema.js`, `src/ui/menu/pages/settings.js`, `src/audio/sfx.js`, `src/audio/engine.js`, `test/settings.test.js` | §15 W19–W21 |
| `L` | `src/app/systems.js` (sistem 22), `src/app/sounds.js` (§10.4 birleşim), `src/app/devtools.js` (`drawMenuFrame` saklaması, `freeze` havayı da dondurur), `src/app/states/freeroam.js` (`tanhu.roam.weather`, giriş 2,4 sn ve çıkış 1,7 sn karışımı) | Faz sonu duman |
| Okuyucular | `stealth-core` (10.4), `fauna`, `hunting` (8.6), `campfire`, `cooking` (8.5), `travel`, `lanes` (10.5), `schedule`, `npcs` (10.3), `squad` (10.6), `derive`, `player`, `mounted` (8.1, 8.8), `builders` ve `sites` (8.11–8.12), `settlement` (8.13) | Her paket kendi `fx` satırını sınar |

8.10 saatin (8.9) yüzünü sözleşmeyle alır; `world.js`'te ışık yazıcısını 9.4 devralır (8.9 kimlik yazıcısını kurar).

## 13. Belgelerde değişecekler

`architecture.md`, `structures.md`, `audio.md` için tam yönergeler Faz 7 bitince yalnız üç birleşik defterle işlenir: `d2/architecture-delta.md`, `d2/structures-delta.md`, `d2/audio-delta.md` (K26). Aşağıdaki alan deltaları ve `d2/core-delta-*.md` o defterlere indirildi, iz için kalır ve işlenmez (birleşik defter çakışanları çözdü: Serbest Gez kayıt satırı, `world.weather` sırası 78, ışık hattı paragrafı, paket numaraları 8.10 ve 9.8, Gök Direği adı ve fırtına hasarı):

- `docs/design/d2/weather-delta-architecture.md`: §1 ağaç, §3.4 ayar, §3.5 kayıt, §3.6 ses, §3.7 sistem, §3.8 WorldSpec ve World, §3.14 etki, §3.19 sinema, §3.21 post, §5 Faz 8, 9, §6.1, §6.3, §7, §8 (karar 37).
- `docs/design/d2/weather-delta-structures.md`: §6.1 tutuşma çarpanı, §6.2, §6.3, yeni §6.5 Hava ve yıldırım, §4.5 bağlama, §10.2 sığınma, §16, §17.
- `docs/design/d2/weather-delta-audio.md`: §1, §3, §4.

Öteki belgeler için yönergeler (belge, bölüm, yer, yeni metin). Komşu d2 taslakları aynı belgelere yazıyorsa birleştiren son metni korur; burada yalnız hava satırları vardır.

| Belge, bölüm | Yer | Yeni metin |
|---|---|---|
| `act1.md` §8.7 | «Sis 1400 m'den 140 m'ye iner.» cümlesinin sonuna | « Sis Ay Saati ilerlemesiyle iner (hava kilidi `a1_last_night`, `weather.md` §6.2); kar yağar ama sesi ve izi act1 §9.5 değerlerinde kalır.» |
| `act1.md` §10 Görüş | «6000 nokta kar.» cümlesinden sonra | « Hava türü `kara_boran` (`weather.md` §3.1): rüzgâr 8 m/sn, bora 15; T4 kör rüzgâr ve `erlik_choice=refuse` kara sağanakları alt olaydır.» |
| `act1.md` §9.2 Üç Zemin tablosunun altı | Tablodan sonra yeni paragraf | «**Hava.** Kar yağarken iz ömrü havanın çarpanıyla kısalır (`weather.md` §8.4); kilitli gecelerde (Eksik Ölçü, Son Gece) 90 sn korunur.» |
| `act1.md` §12 İlk 15 dakika | Tablonun altına | «Hava kilidi `a1_road_in`: açık, rüzgâr 2 m/sn (`weather.md` §6.2).» |
| `act1.md` §14 Ses | Son maddeden sonra | «- **Hava.** Rüzgâr, kar ve Kara Boran döngüleri ve kemik uğultusu havanın rüzgârına bağlıdır (`weather.md` §3.5, §10).» |
| `act1.md` §15 bütçe tablosu | «Sürü 60×600, kar, duman; post» satırının notu | Satır adı «Sürü 60×600, kar (6000 nokta, 1 çizim), duman; post» olur |
| `act1.md` §17 tablo | Son satırdan sonra | «\| 15 \| K22 hava sistemi \| Rastgele hava sahne zamanlamasını bozar \| Sahne başına hava kilidi, kalibre sayılar `pinFx` ile korunur \| act1 sahneleri ve dengeleri değişmez \|» |
| `survival.md` §2 | «Söner: yakıt biter; Tipi'de taşsız ateş 40 sn'de; kar yağışı süreyi ×1,5 hızlandırır.» | «Söner: yakıt biter; hava tablosu `weather.md` §8.5: Tipi, Kara Boran, fırtına ve tozda taşsız ateş 40 sn'de, sağanak ve doluda 60 sn'de söner; kar yağışı taşsız ateşte tüketimi ×1,5 yapar; yağmur ve rüzgâr aynı tablodadır. Taş halkası ve barınak korur.» |
| `survival.md` §3 istasyon tablosu | Kurutma Sırığı satırının son hücresi | «Kak, kurut, tütsü; süre (`time.md`: 2 oyun saati) havanın kurutma çarpanıyla uzar (`weather.md` §8.5: yağmurda durur, rüzgârda ×1,3; çatı altında ≥0,6)» |
| `survival.md` §4 Algı | «Rüzgâr altından yaklaşırsan algı ×0,5, üstünden ×2.» cümlesinden sonra | « Rüzgârı hava verir (`weather.md` §8.4): durgunda (<1 m/sn) yön yok, fırtınada ×2,5 / ×0,4; yağmurda koku menzili ×0,6.» |
| `survival.md` §4 Yeniden doğma | Paragraf sonuna | « Havada doğma çarpanı `weather.md` §7.6.» |
| `travel.md` §2 | «Karda araba 4,0 m/sn …» cümlesinden sonra | « Çamurda yol hızı 6,4 × (1 − 0,25 × çamur) m/sn, taze karda × (1 − 0,15 × kar) (`weather.md` §8.10).» |
| `travel.md` §6.6 | Kod bloğundaki `pürüz:` yorumu | `// pürüz: yol 1 (+0,4 × çamur), kar 1.6, yol dışı 2.4; fırtınada ×1,3; carter 0.5` |
| `travel.md` §8 kilit tablosu | 6 `combat` ile 7 `cart_broken` arasına yeni satır, sonrakiler bir kayar | «\| 7 \| `weather` \| `weather.fx.cartLock` (`sev` ≥3 fırtına türleri) \| «Fırtına dinmeden araba kalkmaz (≈{n} saat).» / «No cart leaves until the storm passes (about {n} hours).» \|» |
| `travel.md` §9.6 | `ev_envoy` satırından sonra | `weather.md` §8.10 tablosunun dört satırı (`ev_storm`, `ev_dust`, `ev_flood`, `ev_snowbound`); ağırlık uç dünyaların iklim payından, perdede bir kez kuralı bunlara uygulanmaz |
| `travel.md` §10.2 | «**Gece ve Tipi.** Şerit yok.» maddesinin sonuna | « `sev` ≥3 havada şerit durur, araç uçta bekler.» |
| `travel.md` §14 | 3B maddesinden sonra | «- **Yağmur.** Yolcu keçe çatı altında `rain_felt` duyar (3B değil, ×0,8); sürücü açıkta `rain_light`.» |
| `progression.md` §4.6 `iron_stake` satırı | Açıklama ve Sayılar hücreleri | Açıklama: «Gökte dönmeyen noktayı ve bulutun yolunu bilirsin: gece ve körde kuzey ekranda kalır, göğe bakınca önümüzdeki altı saati okursun.» / «You know the point in the sky that never turns and the road the clouds travel: at night and in whiteout north stays on your screen, and one look at the sky tells you the next six hours.» · Sayılar: «`northMark=true`, `skyRead=6`» |
| `progression.md` §2.3 | `gallop   = … ± wind` satırının sonuna yorum | `   // ± wind: sürüşte kare başına clamp(0.19 × rüzgârBoyunca, −2, 2) (game/mounted.js, d2/weather.md §8.9); Kara Boran 8 m/sn → ±1,5; derive değeri rüzgârsızdır` |
| `progression.md` §2.3 | `horseDrain` satırının sonuna yorum | `   // sürüşte kare başına × min(1.25, 1 + 0.015 × karşıRüzgâr), Tipide değil (d2/weather.md §8.9)` |
| `progression.md` §2.3 | `arrowDmg` satırından sonra yeni satır | `wetBow   = env.wetBow * bowWetK;  arrowDmg *= 1 - 0.15*wetBow;  range *= 1 - 0.1*wetBow;  drawT *= 1 + 0.1*wetBow   // env.wetBow 0,25 basamaklı, d2/weather.md §8.8` |
| `progression.md` §2.3 | `sense = …` satırının sonuna yorum | `   // kullanım anında × clamp(vis/120, 0.4, 1) (nodes, hunting; d2/weather.md §8.2)` |
| `progression.md` §2.3 | `noiseR = …` satırının sonuna yorum | `   // stealth-core kullanım anında × weather.fx.hearK (d2/weather.md §8.3)` |
| `progression.md` §8.5 | «açlık ya da hava açmaz.» | «açlık ya da hava açmaz (yıldırım ve dolu Can'ı tabanın altına indirmez, Yara açmaz: `weather.md` §8.7, §8.17).» |
| `progression.md` §12 zorluk tablosu | Son satırdan sonra | `weather.md` §8.16 tablosunun beş satırı |
| `progression.md` §13.2 | Yolculuk şemasına | `world.weather` bloğu (`weather.md` §12.7) |
| `progression.md` §13.4 | Serbest Gez kaydına | `weather` alanı (aynı biçim) |
| `army.md` §3.4 Yorgunluk satırı | «(× `fatigueGain`)» sonrasına | « × hava `fatigueK` (Han birliğinde `1 + 2 × (K − 1)`, `weather.md` §8.13)» |
| `army.md` §6 salvo kuralı | Salvo paragrafı sonuna | « Rüzgârda yayılma × (1 + 0,02 × yan rüzgâr); ıslak kirişte hasar × (1 − 0,15w) (`weather.md` §8.8).» |
| `economy.md` §3.2 düğüm tablosu | `node_mushroom` ve `node_dung` satırlarının son hücresi | «… · son 12 sa'te ≥1 sa yağmur: ×2, değilse ×0,5 (`weather.md` §8.14)» ve «… · yağmurdan sonraki 6 sa yakıt ×0,5» |
| `economy.md` §4.4 | Paragraf sonuna | « Açık yer yığını (`node_ground_pile`) yağmur ve sulu karda ıslanır: yakıt ve yem değeri ×0,5, kuruyunca geri gelir (`weather.md` §8.14). Ambar, araba, heybe kurudur.» |
| `d2/labour-model.json` `weather` | Satırlar zaten var (`dry_storm`, `sleet`) | Gece sınıfı `time.md` §12.3 `nightClass`'tan; sığınma kuralı `d2/core.md` §2.8 |
| `survival.md` §2 | «Pişirme» sütunu | Pişirmenin hava çarpanı bu belgenin §8.5'idir; ekonomi kendi çarpanını yazmaz |
| `settlement.md` §15.3 (yapıldı) | Tepki tablosu | `fx`'e başvurur: Kar Kabuğu (§5.9), dolu sağanağı başına tarla kaybı, `fx.galeDamage`, `fx.cartLock` ve `fx.cartK`; yarıçap `R = 10 + manager.wind` |
| `decisions.md` (yapıldı) | K22 | Satır yazıldı |
| `audio.md` §4 efekt listesi (K35, K61) | Hava efektlerinin sonuna | `lake_bull` (§10.2): kodla basılır; inandırıcı olmazsa ElevenLabs efekt ucu, önce sorulur |
| `act1.md` §4 bölge notları (K35) | Buz Kolu ve Saz Tüneli satırları | Hun kişilerinin iye satırları (§7.3); durum etkisi yok |
| `fauna.md` §7 (yapıldı, K65) | Hava ve mevsim tepkileri | §7.6'ya işlendi; binek satırları §8.9'da |
| `story.md` §5 (yapıldı, K36) | Çocukluk'un havası | Kilit `a0_childhood` (§6.3) |
| `time.md` §5.5, §8 (yapıldı, K67) | Kampın akan mevsimi | Kampın dört iklim satırı (§4.1, §4.2), kışın kar örtüsü (§5.9) |
| `d2/core.md` §3.6 (K49, E6.4) | Kar örtüsü tablosu ve «Hesap» paragrafı | Tablo `d2/weather-model.json` v2'den yeniden basılır (§5.9'un satırları); «yaklaşık planlayıcı» sözü «gerçek `weather-core`, 150 kış, sabit tohum» olur; «0,135 ±0,03 ikisini de kapsar» cümlesi «Godot kabulü modelin değerine ortalanır: 0,16 ±0,03, kabuk 0,62 ±0,3» olur |
| `settlement.md` §15.3 (K49, E6.4) | Derin kar ve kabuk payı | «0,63 kabuk ve 0,135» → «0,62 kabuk ve 0,16» (`steppe_south`, kış) |
| `godot.md` §3.5, `act1.md` §8.11 (K76) | Ev'in ışığı | Ev 11 Nisan 14:46,2'nin ikindi ışığında bekler; hava kimliktir (§6.3) |
| `structures.md` §11.6, `story.md` §7.6 (K83) | camp3'ün havası ve «Aile bekler» | Ocak yanana dek `sev` ≤2, yağmur açık; aile 23:00'e dek ateş başında, aşama ≥4 ise ilk dumana dek (§6.3) |
| `army.md` §1.3, `story.md` §14.3 (K56) | IV'ün Ordos Dailin'i | Hava kilidi `a4_dailin` (`clear`, rüzgâr ≤3 m/sn) §6.4'tedir; `story.md` §14.3'ün önerisi uygulandı |

## 14. Yerleşik kodda değişecekler (Faz 7'den sonra)

| Dosya | Değişiklik | Menü riski ve güvence |
|---|---|---|
| `src/core/paint-material.js` | `U.uCloudPhase` (vec2 0), `U.uFront` (vec4 0), `U.uWet`, `U.uWetFx` (vec4 0), `U.uWindK` (1), `U.uWindPhase` (0); `BRUSH_FRAG`'e `uCloudInfo.w` örtü, faz ve cephe satırları (§9.7) | Bütün boyalı programların metni değişir, sayısı değişmez; uniform kimlikte sonuç aynı; `menuDiff` |
| `src/core/post.js` | `post.weather` katmanı `{ sat, con, tone, bright, precip, precipDir, precipOff[3], precipCol }`; FINAL'de çarpım ve §9.3 dalı | Kimlikte `uPrecip` 0: dal çalışmaz, çarpanlar 1 |
| `src/world/sky.js` | §9.7 uniform'ları | Hepsi 0 iken bugünkü FRAG sonucu |
| `src/world/world.js` | `applyMood` değişmez (menü yolu); `world.writeLight` 9.4'te `WeatherView.compose`'a devredilir (taban `world.lightBase`, 8.9); `world.weather` kurulumu (son adım, kendi tohumu); sis sırası taban → hava → sinema | Kimlik hızlı yolu bugünkü sırayı korur; RNG akışı değişmez |
| `src/world/grass.js` | Bora deseni `(uTime + uWindPhase)` | Faz 0 iken aynı |
| `src/world/flora.js` | Salınım `× uWindK` | 1 iken aynı |
| `src/world/camp.js` | Bayrak dalgası `× uWindK`, `uTime + uWindPhase` | Aynı |
| `src/world/fire.js` | `Smoke.wind` (lean, sink), `FLAME_LEAN` | 0 iken saate bağlı aynı duman |
| `src/world/terrain.js` | `WET_GROUND`, `PUDDLE`, `MUD`, `HAIL_WHITE` kancaları zemin malzemesine | Kimlikte aynı |
| `src/world/structure-shader.js` | `FELT_WET` (`struct_tex`, dış yüz) | Aynı |
| `src/world/structure.js` | Ateşli ok tutuşması `× (1 − 0,5 × felt)` (`igniteK`); `spreadEntry.wet`, `wind`, `windDir` zaten okunuyor | Menüde yangın yok |
| `src/game/projectiles.js` | Atışta donan `s.wind`, yan ivme `k × rüzgâr`; `predict` aynı ivmeyle | Rüzgâr 0'da bugünkü yörünge |
| `src/game/builders.js` | `SHELTER` durumu, emek tablosunun `hold` alanı ve sığınma kuralı (`d2/core.md` §2.8) | 8.11 |
| `src/world/structure.js` | `world.tallThings`'e aday ekleme ve silme (aşama değişince) | 9.6 |
| `src/game/effects.js`, `src/story/schema.js`, `src/game/cine.js` | `weather` op'u ve sinema satırı | · |
| `src/core/settings-schema.js` | `'a11y.flashes': { type: 'enum', def: 'full', values: ['full', 'soft', 'off'] }` | · |
| `src/audio/ambience.js` | §10.1 altı döngü | Menü listesi değişmez |
| `src/app/sounds.js` (L) | §10.4 birleşim | Menüde hava listesi boş |
| `src/app/devtools.js` (L) | `drawMenuFrame` hava, saat ve CampLife saklaması (`CONTRACT-REQUEST`), `freeze` havayı da dondurur | §9.12 |
| `src/app/systems.js` (L) | `WeatherSystem` kaydı | · |
| `src/app/states/freeroam.js` | `tanhu.roam.weather` okuma ve yazma; giriş ve çıkış karışımı | Çıkışta kimlik |

## 15. Test planı

**Node (`node --test "test/*.test.js"`, K18).**

| # | Sınama | Ölçüt |
|---|---|---|
| W1 | Belirlenim | Aynı tohum, dünya ve saat 30 gün boyunca aynı plan ve aynı alt olay dizisi; bölüm ortasında kaydet ve yükle aynı devamı verir |
| W2 | Paylar | 41 satırın (38 ve kampın yeni üç satırı, K67) her biri 4000 günde hedeften ≤1,5 puan; kamp satırlarının bölüm sayısı ve en büyük sapması §4.2 ve §4.5'e yazılır |
| W3 | Süreler ve kurallar | Her bölüm `[min, max]` içinde; sis 10:00'da biter; dolu yalnız fırtına içinde; tipi kardan sonra; `exclude` türleri hiç çıkmaz |
| W4 | Cephe ve işaret | Kurudan ıslağa her geçişte ve ıslaktan `sev` ≥3'e her geçişte hazırlık bölümü; `sev` ≥3 her bölüm Normal'de ≥1 sa, Zor'da ≥0,75, Hikâye'de ≥1,5 sa önce üç kanaldan, biri ses, işaret; varışın ilk 1 sa'inde `sev` ≥3 başlamaz |
| W5 | Kilitler | Kilit planlayıcıyı durdurur, kalkınca sürer; `keys` ilerlemesi; `pinFx` değerleri `fx`'te (`mask` 0, `trackK` 1, `douse` 0) |
| W6 | I. Perde sayıları | `a1_feast_raid`: rüzgâr 3, `spreadEntry.wet` 0,5; `a1_last_night`: gerçek `structure-logic` ile meşale 7→3 70 ±2 sn; Kara Boran: dörtnal ±1,5, iz 15 sn, taşsız ateş 40 sn; Tipi sisi 140 m |
| W7 | Etki matrisi | §8.1 tablosu tür × alan, tablo güdümlü; koni çarpanları (68°, 60°, 56°); kapalı gecede `moonSeen` yanlış, `lightLevel` ≤0,08 |
| W8 | Islaklık | Yağmurda zemin 0,6'ya 1,15 ±0,05 sa'te (üstel, `k` 0,8); analitik atlama ile adımlı tümleme farkı ≤1e-3 |
| W9 | Yıldırım adaleti | Çocuk 25 m içinde hedef olmaz; kurulmakta olan yapı aday değildir; vurulan yapı 1 gün bekler; ıslak keçe tutuşmaz; oyuncu yalnız en büyük skorda (açıkta atlı noktaya 17 m'den yakın, sırtta 57 m); Can tabanı 1, Yara yok; fırtına başına ≤1 yakın düşüş; 10 m Sancak Direği ≈9 m içindeki yurtların yerine vurulur; Gök Direği yalnız Kutlu Tepe'de ve alamet verir |
| W10 | Ses uzaklığı | Gecikme `d / 343`; bant seçimi ≤600 m, ≤3 km, ≤10 km |
| W11 | K1 denetimi | `i18n/strings/weather.js`'te ve oyuncuya görünen metinde `üşü`, `ısın`, `soğuk`, `chill`, `cold`, `warm` yok (kod adları `ambience.warm`, `cold_pit` serbest); `Needs`'e bağlantı yok |
| W26 | Kar örtüsü ve kabuk: üreteç ve sınama (K58: soru değil, ölçüm işi) | Üreteç: `weather-core` sabit tohumla 150 kış koşar ve `d2/weather-model.json`'ı yeniden yazar (`node --test` dışında, `tools` komutu; dosya sürüm denetiminde fark olarak görünür). Sınama (`node --test`, dosyaya bakmadan): kabuk yalnız kural sırasıyla oluşur (sulu kar ya da yoğun kar/tipi + açık öğle, ardından açık gece); I. Perde `hexi` satırında kabuk 0; mutlak tolerans yalnız iki yerleşim ikliminde: `steppe_south` derin kar payı ve kabuğu (prototipte 0,135 ±0,03 ve 0,63 ±0,3 / kış; Godot'da modelin değerine ortalanır, aşağıda), `gobi` kabuk ≤0,05 / kış. Göreli tolerans yoktur (Gobi 0,01, Ordos 0,003, Hexi 0 için anlamsızdı). Sıra: 8.10 dosyayı ekonomi alanının son `--strict` koşusundan önce yazar; dosya sonra değişirse sim yeniden koşulur (doğrulama V30). (K49 ile değişti, E6.4) Üreteç prototipte koşuldu: `d2/weather-model.json` v2 (2026-11-03, tohum 2048377054) `steppe_south` için 0,16 / 0,62 / 0,02 verdi, §5.9'un tablosu ondandır. Kabul aralığı modelin değerine ortalanır: `steppe_south` derin kar 0,16 ±0,03, kabuk 0,62 ±0,3 / kış; Godot'un `WeatherPlanner` ve `SnowPack` koşusu bu aralıkta kalmalıdır. Prototipin `test/weather-core.test.js`'i bu turda değişmez, eski merkezle (0,135 ±0,03, 0,63 ±0,3) sınar; modelin değeri iki aralığın da içindedir (Genel kural 6) |

**Tarayıcı (`__tanhu`, §6.3).**

| # | Sınama | Ölçüt |
|---|---|---|
| W12 | Menü | Serbest Gez'de ıslak zemin, dolu, şerit ve fırtınadan sonra menüye dönüş; Yeni Oyun ve oluşturucu: `menuDiff` 0 piksel |
| W13 | Program | Hava taban üstüne +2 (menü 59, Serbest Gez 59); `weather.set('rain')` ve `strike` sonrası `renderer.info.programs` değişmez (ilk yağmurda derleme yok) |
| W14 | Bütçe | Fırtına en kötü karesi +≤2 çizim, +≤96 üçgen; Serbest Gez gündüz fırtınası `Smoke` birleşmesiyle ≤511; Kışlak yoğun kar +≤1 çizim; Kara Boran ≤220 çizim |
| W15 | Şimşek | Sahnedeki ışık sayısı sabit; `a11y.flashes` `soft` ≤2,5 parlama/sn, `off` pozlama değişmez |
| W16 | Görünüş (K58) | 900p'de boya açıkken yağmur çizgisi okunur; on kare (açık, yağmur, sağanak, fırtına + şerit, dolu, sis, kar, tipi, toz, Kara Boran) ve yeni dört görünüm (kuru fırtına, sulu kar, kampın kış kar örtüsü, kampın güz tonu) `time.md` §5.3'ün klasörüyle aynı oturumda; çizgi zayıfsa katman alfası 0,5 → 0,65 (§9.3); karar ekran görüntüsüyle, göz onayı kullanıcının |
| W17 | Paralaks ve sarma | 4,4 m/sn yürüyüşte katmanlar ekrana kilitli değil, paralaksla kayar; 10 oyun saatlik yağmurdan sonra çizgi kenarı ilk dakikadaki gibi keskin (sarma) |
| W18 | Rüzgâr | Fırtınada çim bükümü ×2,3, duman yatık, bayrak hızlı; menüde `uWindDir` (0,8; 0,45) |
| W19 | Ses | Fırtınada canlı düğüm ≤40; hazır ses K59'un tavanında (prototip 48 MiB: müzik 16, efekt ve ortam 24, satır 8; Godot dünya başına 26 MiB, efekt ve ortam 8); kampta fırtınalı akşamda ve 23:00'ten sonra, dolulu fırtınada da efekt ve ortam önbelleği havuzun içinde ve fırın hiçbir girişi düşürmez (`sfx.js` `evict` her pişirmeden sonra bütçeye iner; ölçülür); döngüler cepheden ≥1 sa önce pişmiş, geçince bırakılmış; hava efektleri 22,05 kHz |
| W20 | HUD | Simge bölüm başına en çok bir kez yazılır; satır TR ve EN |
| W21 | Ayar | `a11y.flashes` kaydedilir, kitap satırı canlı |
| W22 | Oyun | 12 m/sn yan rüzgârda 60 m'de ok 1,3 ±0,1 m sapar, telgraf iniş yerini gösterir; ıslak kiriş w=1'de hasar −%15; araba kilidi süre yazar; ustalar yalnız `all` durağında sığınır ve 37 sn sonra döner; fırtınada taşsız ateş 40 sn'de söner; bağlı çadır fırtınada aşama yitirmez |
| W23 | Kayıt | Blok ≤1 KB; fırtına ortasında yükleme aynı fırtınayı ve aynı sonraki yıldırım anını verir (diyalog ve Donuk Kamp duraklamasından sonra da); dünyaya 24 sa içinde dönüş aynı planı verir |
| W24 | I. Perde | 17 kilit bağlarında açılır; ilk 15 dk açık; Kara Boran temiz sürüş ≥3 dk (K10) değişmez |
| W25 | Kampta yıldırım | Ana kampın gök gürültülü fırtınalarının ≥%50'sinde kadrajda bir yıldırım; kadraj dışı düşüşte düşüşe en yakın kenarda ayak (varsayılan kadrajda üst kenar); Çocuğa ≥25 m, yapıya hiç |
| W27 | Kampın mevsimi (K67) | Serbest Gez 11 Nisan'da `camp_spring` ile açılır; takvim 15 Mayıs'ı geçince planlayıcı `camp_summer`'a, 23 Ağustos'ta `camp_autumn`'a, 16 Kasım'da `camp_winter`'a geçer; kar yalnız kışta tutar; kış örtüsüyle menüye dönüşte menü karesi referansla aynı |
| W28 | Akın ve bulut (K55) | Kapalı gecede ve fırtınada akın günü değişmez; `moonSeen` yanlışken akın penceresi yine açık |
| W29 | Önsöz ve küçük dünyalar | Önsöz boyunca hava kimlik; `a0_childhood` 08:40'tan sayıma dek `clear`, rüzgâr 2 m/sn; `a0_depart` yağışsız |

## 16. K1 denetimi

| Kural | Neden soğuk ya da sıcaklık değil |
|---|---|
| Kar, tipi, Kara Boran: görüş, iz, at staminası (act1 §10), ateş | Görme, hareket ve yanma; beden ısısı yok |
| Islak kiriş | Malzemenin nemi |
| Dolu: iri dolu Can, stamina dolumu | Çarpma; taban %40 |
| Yağmur: zemin, keçe, yakıt ıslaklığı | Su; beden ısısı yok |
| Kamp ateşi | Pişirme ve yanma süresi; ısıtma yok (survival §2) |
| Barınak | Saklanma ve dolum (act1 Üç Zemin); ısınma yok |
| Baideng | Yalnız kar ve derin kar; donma ve parmak kaybı oynanmaz |
| Irmak buzu | Hikâyenin takvimi; hava donmayı modellemez |
| Kar örtüsü, Kar Kabuğu | Yağışın ve güneşin sırası; erime ve donma sözcüğü yok, sıcaklık değişkeni yok |
| Dizgeler | «soğuk», «üşü», «ısın» sözcükleri yok (W11) |

## 17. Doldurulan boşluklar

1. **İki saat ilkesi:** durum oyun saatiyle, devinim gerçek saniyeyle (H1).
2. **Kuru fırtına** ve **sulu kar** türleri (Gobi yangın havası; bahar ve güz geçişi).
3. **Kampın satırı** `camp_spring` (Göl Vadisi baharı, 11 Nisan): yeşil kuytu vadi açık bozkırdan yağışlıdır, toz fırtınası yoktur; K9 sürücü satırı («Geçitler daha karla kapalı; yaz gelsin.») ile seyrek kar serpintisi birlikte okunur. (K67 ile genişledi: kampın dört mevsim satırı, madde 29.)
4. **Dolu** fırtınanın içinde bir sağanaktır (`pHail`), ayrı tür olarak seçilmez.
5. **Fırtına hücresi** modeli ve tasarlanmış **yakın yıldırım** (fırtına başına %25, uyarılı).
6. **Yıldırımın yükseklik kuralı** yerleşimde anlam kazanır: Sancak Direği (`banner_pole`, 10 m) konut halkasında yurtların yerine vurulur; Gök Direği (`sky_pole`) Kutlu Tepe'de alamettir, yurtları korumaz (§8.7).
7. **Yıldırım ağacı** kömür verir; Yıldırım Çamı'nın adı bu kurala bağlanır.
8. **Islak kiriş** ve `gorytos` kılıfı.
9. **Bağla / Tie Down**: fırtına öncesi hazırlık döngüsü.
10. **Dört yol olayı** (fırtına, toz, sel, karda kalış).
11. **Bulut ay ışığını keser:** gece emeği (`nightClass`), ay kartı, gözcü satırı; ay olayları (dolunay tavanı, eksilen ay) takvimdendir, bulut onları değiştirmez (H20, §8.13, K22).
12. **Han ×2 yorgunluk** (Chao Cuo).
13. **Şimşek ifşa eder, gök gürültüsü örter**: gizliliğin hava ritmi.
14. **Mene** havayı hayvandan okur; konuşmadan işaret eder.
15. **Halk işaretleri**: çöken duman, «ay ağıl aldı», sabah kızıllığı.
16. **Kara Yol'da yerel sükûnet**: kar dik düşer.
17. **Çocuğun küçük hava oyunları**: birikinti, kar tanesi, dolu.
18. **Parlama ayarı** (`a11y.flashes`) ve Hareketi Azalt bağı.
19. **Uyanış satırları**: uykuda geçen hava söylenir.
20. **Sis gizliliği eşiği** (görüş ≥100 m'de etkisiz): I. Perde dengesi korunur.
21. **Hedef pay + yükleyici ayarı**: tasarımcı ağırlık değil pay yazar.
22. **Gök örtüsü sütunu** (`cloud`): ay ışığı ve gece sınıfı tek sayıdan.
23. **Kar örtüsü ve Kar Kabuğu** (zud): sıcaklıksız sıra kuralı, derin kar ve kabuk payları `weather-model.json`'da.
24. **Kampta görünür yıldırım**: kadraja tasarlanmış düşüş, kadraj dışı ayak.
25. **Sancak Direği** konut halkasının paratoner dersi; Gök Direği tepede alamet.
26. **Uzak yağmur sesi** (`far_rain`): ıslak cephenin ses kanalı.
27. **Kalıcı Bağla** ve hanenin kendi çadırını bağlaması; fırtına hasarı bölüm başına tek zar.
28. **Sabit çapalı zincir**: geri dönüşte ve yüklemede aynı hava.

**Üçüncü tur (2026-11-04):**

29. **Kampın dört mevsim satırı** (K67): `camp_summer`, `camp_autumn`, `camp_winter` açık Orhun'un paylarıdır, toz rüzgâra geçer; bahar serpintisinin 1–3 sa süresi yalnız bahardadır (§4.1, §4.2).
30. **Kampın kışında kar örtüsü**: kar yalnız kışın tutar, görünüş var olan tekdüzenle gelir, menüde kimlik (§5.9).
31. **Önsöz, Çocukluk ve Yola Çıkış havası**: Önsöz kimlik; `a0_childhood` ve `a0_depart` kilitleri (§6.3).
32. **Takvimli kilitler** (K56): `a3_dailin`, `a6_longcheng`; Baideng, Tunghu baskını ve Lung-çeng kilitlerine tarih (§6.4).
33. **İye satırları** (K35): altı satır ve `lake_bull` efekti; Ülker satırı soğuk demez (§7.3, §10.2).
34. **Deveci satırı ve hayvan işaretleri** (K65): `fauna.md` §7'nin satırları §7.6'ya; binek katır ve binek devenin hava kuralı (§8.9); yük devesinin araba çarpanı (§8.10).
35. **Ağabey'in fırtına satırı ve sığınması** (K37): kamp halkı dört kişidir (§7.3, §8.12).
36. **Gözcü satırının okuması** (K55): bulut Mete'nin gece yürüyüşünü erteler, düşman akınını değil (§7.3).
37. **Kadraj dışı yıldırım ayağı ve yağış kutusu** dönen kamerada kameranın baktığı yönle çalışır (K39; §8.7, §9.3, §9.4).
38. **Akan Kronik'te hava**: plan tutulmaz, zon kar örtüsü olaysız sarılır (§2).
39. **Katman alfasının ölçümü** (K58): tek alternatif değer 0,65, ışık klasörüyle aynı oturum (§9.3).

**E6 düzeltmesi (2026-11-04):**

40. **IV'ün Dailin kilidi ve Lung-çeng günleri** (K56): `a4_dailin` (`clear`, rüzgâr ≤3 m/sn, 22 Eylül 203, `ordos`); `a4_longcheng` iki güne (17 Haziran 205 Gök Dağı eteği, 25 Haziran 203 Lung-çeng), `a6_longcheng` iki güne (2 Haziran 198, 4 Haziran 176) bağlandı (§6.4).
41. **camp3 gecesinin havası** (K83): yağmur sev ≥3 dışlamasının dışındadır; aile sabit saat yerine ilk dumana dek bekler, çünkü tek yağmur bölümü dumanı 22–45 oyun dk geciktirir (§6.3).
42. **Kar örtüsü tablosu modelden** (K49): §5.9 `d2/weather-model.json` v2'den basıldı; W26'nın Godot kabulü modelin değerine ortalandı (§15).

## 18. Kararlar ve açık konular

Taslağın soruları baş tasarımcı kararıyla kapandı (`d2/core.md` §7):

1. **Kampın satırı.** `camp_spring` kalır: oyunun her havayı gösterdiği yer göl vadisidir; gerçek Orhun Nisanı (`orkhon` bahar) açık bozkırın satırıdır. (K67 ile genişledi) Kampın mevsimi takvimle akar: yaz, güz ve kış satırları §4.2'dedir; kışın kar tutar.
2. **Yıldırım Mete'yi vurur mu.** Normal ve Zor'da evet, yalnız skoru en büyükse: Can −%35, taban 1, Yara yok; Hikâye'de hiç.
3. **Kar Kabuğu.** Tanım §5.9; yerleşim tepkisini kabul etti, süre 5–10 gün.
4. **Gök Direği vuruşu.** Kuru fırtınada ve keçe flama kuruyken tutuşur (meşale 70); ıslak fırtınada yalnız iz ve alamet.
5. **II–VI. Perde mevsimi.** Takvim verir (perde başları `time.md` §2); sahne kilidi geçersiz kılabilir.
6. **Emek tablosu satırları.** `dry_storm` ve `sleet` zaten var.

**Üçüncü turun kararları** (2026-11-04):

7. **Görünüm ve kar örtüsü (K58, kullanıcının #16 ve #51 cevabı).** Soru değildir. Yeni görünümlerin ve ekran yağışının boyalı süzgeçteki okunurluğu ölçüm işidir: W16, `time.md` §5.3'ün ışık klasörüyle aynı oturumda; çizgi zayıfsa katman alfası 0,5 → 0,65 (§9.3); yöntem `godot.md` §8.5, göz onayı kullanıcının. Kar örtüsü paylarını prototipin gerçek çekirdeği zaten üretti (`d2/weather-model.json` v2, `steppe_south` 0,16 / 0,62 / 0,02; ekonomi %16,0'ı okur, K49); kalan iş Godot'un `WeatherPlanner` ve `SnowPack`'iyle W26 sınamasıdır (§5.9, §15). Doğrulanacak: iş Yol Haritası'nın `weather` maddesindedir ([/roadmap#act-1-p1](/roadmap#act-1-p1)); ekonominin Godot eşliği `econ-sim-run` maddesindedir ([/roadmap#act-2-p2](/roadmap#act-2-p2)).
8. **Kampın mevsimi (K67).** Kampın dört satırı ve kışın kar örtüsü (§4.1, §4.2, §5.9). Kamp satırlarının bölüm sayıları W2 ile ölçülür (§4.2, §4.5); Serbest Gez'in güz ve kış görünüşü Yol Haritası'nın `roam-calendar` maddesindedir.
9. **Takvimli kilitler (K56).** `a3_dailin` `clear`; `a4_dailin` `clear` (E6.4 ile eklendi); `a4_longcheng` IV'ün iki gününde, `a6_longcheng` VI'nın iki gününde; `a6_dailin` (§6.4).
10. **Akın ve bulut (K55).** Bulut akın gününü değiştirmez (H28).
11. **Ev'in ışığı (K76).** `home` havası kimliktir, ışığı 11 Nisan 14:46,2'nin ikindisidir; Godot menüsünün gece ışığı değildir (§6.3).
12. **camp3 gecesinin havası (K83).** Ocak yanana dek `sev` ≥3 türler dışlıdır, yağmur açıktır; aile ilk dumana dek bekler, sabit 04:15 bitişi seçilmedi (§6.3).

**Açık kalan:** yok. Ölçüm işleri soru değildir (E6.3), Yol Haritası'ndadır: W16 ve W26 `weather` maddesinde, `lake_bull`'un kulak sınaması da orada; kodla basılan ortamın ElevenLabs dosyalarının yerini alması kullanıcının kulak onayıdır, Karar Bekleyenler'de (onay).

## 19. Doğrulama durumu

- **Okundu:** `decisions.md`; `architecture.md` §0, §1, §3.5–§3.8, §3.14, §3.19–§3.22, §5, §6, §7, §8; `act1.md` §1, §2, §4, §5, §8–§10, §12–§17; `survival.md`; `structures.md` §0–§6, §9, §10, §13–§18; `travel.md` §2, §3.5–§3.7, §4.4, §6, §8–§10, §14; `audio.md`; `army.md` §0–§3; `progression.md` §2, §4.5–§4.8, §6.2, §7.2–§7.3; `economy.md` §3, §5.4, §7, §8; `contract-requests.md` (yalnız okundu); d2 taslakları, `labour-model.json`, `econ-model.json`, `settlement-model.json`. Kod: `sky.js`, `post.js`, `post-profiles.js`, `paint-material.js`, `fire.js`, `world.js`, `grass.js` (rüzgâr), `structure-logic.js` (`spread`, `ignite`, `douse`), `structure.js` (`_fires`), `projectiles.js` (`_substep`), `ambience.js`, `sfx.js` (`BAKE_BUDGET`, `SFX_RATE`), `sfx/world.js` (`thunder`), `music-states.js`, `sounds.js`, `settings-schema.js`, `clock.js`, `specs/index.js`, `geography.js` (kamp konumu).
- **Benzetildi (taslak turu, Node 24, prototip, projeye yazılmadı):** planlayıcı ve ayar 38 iklim satırında 4000 gün: en büyük sapma 1,34 puan (`alashan` yaz, `clear`); Kışlak dakika tablosu (§4.5); ayar süresi ≈43 ms; fırtına hücresi 20.000 fırtına (§8.7; eleştirmenin yeniden koşusu ≈%32 yakın düşüş); ok sapması tablosu (§8.8). Kampın §4.5 satırı hedef paydan yeniden yazıldı (eski satır ayarlanmamış bir koşudandı).
- **Baş tasarımcı benzetimi (son biçim, prototip; K49 ile değişti):** kar örtüsü ve Kar Kabuğu paylarının ilk hâli 150 kışlık yaklaşık planlayıcıdandı (ayarlı ağırlıklar, cephe hazırlığı ve çözülmesi, sis saat kuralı; gün içi eğriler yok): `steppe_south` 0,135 / 0,63 / 0,027. `d2/weather-model.json` v2 (2026-11-03) prototipin gerçek `weather-core`'uyla, sabit tohumla (2048377054), 150 kış × 120 gün koşularak `tools/weather-model.mjs` ile yeniden yazıldı: `steppe_south` 0,16 / 0,62 / 0,02. §5.9'un tablosu bu dosyadandır; Godot'da W26 aynı sınamayı `WeatherPlanner` ve `SnowPack` ile yineler. Dosya üretecin çıktısıdır, elle değiştirilmez (`--check` bayt bayt karşılaştırır).
- **Hesap, koşulmadı:** GPU maliyetleri, çizim ve program sayıları, ses belleği (§10.1), sönme ve tutuşma süreleri (structures §6.1 hızlarıyla).
- **Yapılmadı:** kod yazılmadı, hiçbir şey çizilmedi, `menuDiff` koşulmadı, ses dinlenmedi.
- **E6 düzeltmesi (2026-11-04):** §5.9'un tablosu `d2/weather-model.json` v2'nin `byClimate.*.winter` alanlarından birebir basıldı; dosya değişmedi. Üreteç (`tools/weather-model.mjs`) geçici bir çıktıya yeniden koşuldu, projeye yazılmadı: kar örtüsü ve kabuk payları on iklimin hepsinde v2 ile aynıdır; yalnız mevsimin inşa çarpanı `buildK` 12 satırda üçüncü ondalıkta ±0,001 kayar (`d2/labour-model.json` v3'ün tepkileri), `feltK` aynıdır. Dosya ekonominin resmî koşusunun girdisi olduğu için yeniden yazılmadı; `--check` bu yüzden «farklı» der. Yeniden yazım `econ-sim`'in `law.build` koşusuyla birlikte yapılır (Yol Haritası `econ-sim-run`, [/roadmap#act-2-p2](/roadmap#act-2-p2)). camp3 saatleri `structures.md` §11.6'dan okundu (K83), bu belgede yeniden hesaplanmadı. Kamp baharında yağmur gelme olasılığı (≈%33, 13 saatlik kurulum) ve tek bölümün gecikmesi (22–45 oyun dk) K83'ün gerekçesinden alındı. `a4_dailin` ve Lung-çeng günlerinin `dayN`'leri `time.md` §2'nin formülüyle tuttu (`time.md` §20). Okundu: `decisions.md` K49, K55, K56, K76, K83, K87; `story.md` §11.3, §14.3.
- **Üçüncü tur (2026-11-04):** kampın yaz, güz ve kış satırları `orkhon` satırlarından türetildi (yazın toz 0,5 → rüzgâr; satır toplamları 100); §4.5'in dakika satırları hedef paydan hesaplandı (pay × 0,6), bölüm sayıları ve sapma W2 ile ölçülecek. Oyuncak okun 2 m/sn rüzgârda 20 m'deki sapması §8.15'in örneğinden hesaplandı (≈0,15 m). Godot varsayılan kadrajının ufuk açısı ve kadraj derinliği betikle hesaplandı (üst ışın ufkun 2,5° altı; ≈13 m geri, ≈240 m ileri; eğim 15°'de karenin üst ≈%14'ü gök). Okundu: `decisions.md` K29–K69, `d3/register.md`, `d3/brief.md`, `d3/oyun-durumu.md`, `fauna.md` §2, §7, §9, §12, `story.md` §2, §4, §5, §7.6, §9, §11, `godot.md` §3, §3.5, §4.8, §4.9, §7.2, §8.5, §11, `mitoloji.md` öneri 9–13, `sanat-animasyon.md` öneri 4 ve 17, `hayvanlar.md` öneri 13–14.
