---
title: Hava
order: 50
status: tasarim
summary: '17 hava türü ve Kara Boran dokuz iklime, takvimin mevsimine ve saate göre planlanır; ağır hava en az bir oyun saati önce okunur, kar örtüsü ve Kar Kabuğu yerleşimin kışını belirler.'
sources:
  - docs/design/decisions.md
  - docs/design/weather.md
  - docs/design/d2/core.md
  - docs/design/d2/weather-model.json
  - docs/design/time.md
  - docs/design/travel.md
  - docs/design/settlement.md
  - docs/design/fauna.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Yağmur, kar, dolu, fırtına, şimşek, yıldırım: hepsi vardır ([K22](/docs/source/design/decisions#k22)). Hava dünyanın iklimine, takvimin mevsimine ve saate göre planlanır; aynı kayıt aynı havayı verir. Oyunu değiştiren her hava en az bir oyun saati önce okunur: fırtına sürpriz değil, hazırlık oyunudur. Ateşi taşla çevirirsin, çadırı bağlarsın, sırttan inersin. Sıcaklık ve soğuk modellenmez ([K1](/docs/source/design/decisions#k1)): bozkırın kış felaketi soğuk değil, otu örten buzdur.

> [!NOT]
> «Hava durumları olacak»

Notun K22'yle aynı yöndedir. Hava yalnız fiziksel değeri verir (rüzgâr, görüş, bulut, ıslaklık, çamur, kar örtüsü); her tepkinin tek sahibi vardır: şantiye, sürü, kervan, ordu ve ekonomi aynı değeri okur.

## Türler

Ağırlık 0–4 bütün sistemlerin okuduğu kaba ölçüdür: 0 etkisiz, 1 görünür, 2 hafif oyun etkisi, 3 ağır (bazı işler bekler), 4 sığınak gerektirir.

| Tür | Ağırlık | Rüzgâr ort / bora m/sn | Görüş m | Süre, oyun saati | Nerede, ne zaman |
|---|---|---|---|---|---|
| Açık | 0 | 2,5 / 4 | ∞ | 3–12 | Her yer |
| Parçalı Bulut | 0 | 3,5 / 6 | ∞ | 2–8 | Her yer |
| Kapalı | 1 | 3 / 5 | 2.000 | 2–10 | Her yer; cephe önü ve arkası |
| Sis | 1 | 0,5 / 1 | 60 | 1–4 | Durgun gece, şafak; 10:00'da dağılır |
| Çisenti | 1 | 2 / 4 | 400 | 1–4 | Ilıman satırlar |
| Yağmur | 2 | 4 / 7 | 200 | 1–5 | Bahar, yaz, güz |
| Sağanak | 3 | 6 / 11 | 70 | 0,5–2 | Yaz; yağmurun ya da fırtınanın içinden |
| Gök Gürültülü Fırtına | 3 | 7 / 16 | 120 | 1–2,5 | Yaz öğleden sonra |
| Kuru Fırtına | 3 | 9 / 18 | 800 | 1–2 | Gobi, Alaşan, Ordos yazı. Şimşek var, yağmur yok: yangın havası |
| Dolu | 4 | 8 / 16 | 60 | 0,15–0,4 (22–60 sn) | Yalnız gök gürültülü fırtınanın içinde |
| Rüzgâr | 1 | 9 / 14 | ∞ | 2–8 | Bahar, Gobi, öğleden sonra |
| Fırtına | 3 | 16 / 24 | 300 | 1–6 | Bahar, kış |
| Sulu Kar | 2 | 4 / 7 | 150 | 1–3 | Bahar, güz geçişi; kış sonu |
| Kar | 1 | 3 / 5 | 250 | 2–8 (kamp baharında 1–3) | Kış |
| Yoğun Kar | 3 | 5 / 9 | 90 | 1–4 | Kış |
| Tipi | 4 | 12 / 20 | 40 | 2–6 | Kış; yalnız kar ya da yoğun kardan sonra |
| Toz Fırtınası | 4 | 14 / 20 | 40 | 1–4 | Bahar: en sık Gobi, Alaşan, Hexi, Ordos; kampın vadisinde yok |
| Kara Boran (hikâye) | 4 | 8 / 15 | 140; Ak Otlak'ta 45–80 | Hikâye | Yalnız Gün VI kovalamacası |

**Alt olaylar:** Şimşek (fırtına başına ≈15), Yıldırım (şimşeklerin %30'u), Gök Gürültüsü, Bora, Fırtına Önü (ilk 15 sn, 16 m/sn), Dolu Sağanağı, Kara Sağanak ve Kör Rüzgâr (yalnız Kara Boran).

**İki saat.** Durum oyun saatiyle, devinim gerçek saniyeyle akar. [K20](/docs/source/design/decisions#k20) günü 60 dakikaya sıkıştırır ama fiziği sıkıştırmaz: şimşeğin sesi 1 km'den 2,9 sn, 3 km'den 8,7 sn, 10 km'den 29 sn sonra gelir. Bir bölüm ortalama 6–12 gerçek dk sürer, geçiş 20–60 sn.

![Prototipte kubbedeki bulutlar, ikindi ışığı.](/media/docs/research/sky-shots/sky_up60_golden.jpg)

```varlik
fx_rain, fx_snowfall, fx_hail, fx_lightning, fx_fog
fx_dust, fx_blizzard, fx_ice, fx_screen_precip
```

## İklimler

Dokuz iklim, dört mevsim. Tablo paylardan bu sayfa için toplandı: zamanın yüzde kaçı o türlerde geçer. Yaz sütunu çisenti, yağmur, sağanak ve gök gürültülü fırtına; kış sütunu kar, yoğun kar ve tipidir.

| İklim | Dünya | Bahar toz | Yaz yağış ve fırtına | Kış kar | Kış açık |
|---|---|---|---|---|---|
| `orkhon` | Göl Obası, Tanhu Kampı, Lung-çeng | 4 | 22 | 9 | 51,5 |
| `hexi` | Kışlak; IV'te Kışlak, Yaz | 11 | 16 | 7 | 44 |
| `gobi` | Islık Alanı | 13,5 | 7,5 | 7 | 58 |
| `alashan` | Loulan | 18 | 3 | 2 | 64 |
| `ordos` | Ordos | 9 | 20 | 8 | 49,5 |
| `steppe_south` | Tanhu Ordusu | 7 | 21 | 12 | 49,5 |
| `kerulen` | Tunghu Yurdu | 4 | 23 | 13 | 51,5 |
| `hangai` | Hangay, Dingling Yurdu | 3 | 26 | 15 | 45,5 |
| `daibei` | Mayi, Baideng | 7 | 29 | 11,5 | 48 |

Yön ve sıra doğrudur, paylar oynanış için yuvarlandı: Orhun yağışı yaza yığılır, bahar rüzgâr ve tozdur, kış açık ve durgundur. Hexi baharda tozun yoludur, Gobi'de kuru fırtına ıslak fırtınadan sıktır, Daibei en yağışlı yazdır. Bütün paylar: [weather.md §4.2](/docs/source/design/weather#4-2-paylar).

**Kampın havası takvimin mevsimini okur ([K67](/docs/source/design/decisions#k67)).** Serbest Gez 11 Nisan MÖ 209'da açılır, mevsim takvimle döner: bahar `camp_spring`, 15 Mayıs'tan yaz `camp_summer`, 23 Ağustos'tan güz `camp_autumn`, 16 Kasım'dan kış `camp_winter` satırı. Göl vadisinin farkı baharda belirgindir: ilk sağanaklar ve ilk gök gürültüsü burada başlar, oyunun her havayı gösterdiği yer burasıdır. Yaz, güz ve kışta açık Orhun'un payları vadiye zaten uyar; tek fark kuytu vadide toz olmamasıdır. Kar yalnız kışın tutar: bahar, yaz ve güz serpintisi zemini ve keçeyi ıslatır, örtü bırakmaz. Güz görünüşü çimen tonuyla, kış görünüşü kar örtüsüyle gelir; yeni doku ve program yoktur. Menüye dönüşte görünüş kimliğe döner, menü karesi değişmez.

**I. Perde Kışlak'ı** `hexi` kışıdır ama yoğun kar ve tipi dışlanır: Kara Boran'ın gücü çalınmaz.

| 60 dakikalık gün | Bölüm / gün | Dağılım, gerçek dk |
|---|---|---|
| Kamp baharı | ≈9,4 | Açık 18,6, bulut 15,0, kapalı 6,0, rüzgâr 6,0, yağmur 4,2, çisenti 2,4, GGF 2,1, sis 1,8, fırtına 1,5, sağanak 0,9, kuru fırtına 0,6, kar 0,6, sulu kar 0,3 |
| Kamp yazı | Ölçülecek | Açık 17,4, bulut 15,6, kapalı 6,6, yağmur 6,0, rüzgâr 3,3, GGF 3,0, sis 2,4, çisenti 2,4, sağanak 1,8, fırtına 0,9, kuru fırtına 0,6 |
| Kamp güzü | Ölçülecek | Açık 27,0, bulut 12,0, kapalı 6,0, rüzgâr 4,8, sis 3,0, yağmur 1,8, kar 1,5, çisenti 1,2, fırtına 1,2, sulu kar 0,9, GGF 0,3, yoğun kar 0,3 |
| Kamp kışı | Ölçülecek | Açık 30,9, bulut 9,6, kapalı 6,0, sis 3,6, kar 3,6, rüzgâr 3,0, fırtına 1,2, yoğun kar 0,9, tipi 0,9, sulu kar 0,3 |
| Kışlak, I. Perde | 4,9 | Açık 27,2, bulut 13,3, kapalı 6,6, rüzgâr 5,4, sis 3,2, kar 3,0, fırtına 1,2 |

GGF: gök gürültülü fırtına. Kamp baharında günün ≈10,5 dakikası ıslaktır (yazın ≈13,2), fırtına ≈94 dakikada bir, dolu ≈8 oyun gününde bir gelir. **Gün içi:** fırtına öğleden sonra yığılır (12–18), sis sabahın türüdür, rüzgâr öğleden sonra güçlenir. Mevsim uzunlukları: [Zaman ve Takvim](/docs/world/time-calendar).

Doğrulanacak: 41 iklim satırının her biri 4.000 günlük benzetimde hedef paydan en çok 1,5 puan sapar (W2); kampın yaz, güz ve kış satırlarının bölüm sayıları bu koşuyla yazılır ([Yol Haritası](/roadmap#item-weather)).

## Planlayıcı

- **Bölüm.** Hava tek türlü bölümler dizisidir. Planlayıcı en az 12 oyun saati ileriyi bilir: işaretler ve gök okuma buradan okur.
- **Seçim.** Sıradaki tür: hedef pay × gün içi eğri ÷ ortalama süre. Tasarımcı pay yazar, ağırlığı yükleyici ayarlar. 38 iklim satırında 4.000 günlük benzetimde en büyük sapma 1,34 puan.
- **Cephe.** Kuru havadan ıslak ya da fırtınaya atlanmaz: önce hazırlık, sonra hedef, sonra çözülme. Yağmur ve kar için kapalı 1–2 saat; gök gürültülü ve kuru fırtına için bulut 1–1,5 saat; fırtına ve toz için rüzgâr 0,5–1 saat; tipi için kar 1–2 saat. Ağır bölümden önce 0,75–1 saatlik hazırlık girer.
- **Kurallar.** Dolu hedef olarak seçilmez: fırtınanın içine girer. Sis 21:00–09:59 arasında başlar, 10:00'da biter. Hiçbir tür bir günü tek başına doldurmaz; en uzun bölüm açık havadır (12 sa = 30 gerçek dk).
- **Belirlenim.** Aynı kayıt, aynı saat, aynı dünya: aynı hava, aynı şimşek dizisi. 24 saat içinde geri dönen aynı planı bulur.
- **Varış.** Yeni dünyaya varınca ilk 1 oyun saatinde (Hikâye 1,5) ağır hava başlamaz. Fırtına sürüyorsa Yol Kartı yazar: «Fırtına sürüyor». Atlas yolunda hava yol olayı olur ([Yolculuk](/docs/world/travel)).
- **Atlama.** Uyku ve bekleme planı ileri sarar. Uyanınca ilk konuşan söyler: «Gece kar yağdı.», «Gece fırtına koptu; uyanmadın mı?»
- **Islaklık.** Zemin, keçe, çamur, birikinti ve taze kar ayrı sayaçlardır. Yağmurda zemin 0,6 ıslaklığa 1,15 oyun saatinde varır, çamur onu gecikmeli izler. Kampta kar bahar, yaz ve güzde tutmaz, kışın tutar.

## İşaretler

**Kural (K22).** Ağırlığı ≥3 olan her bölüm en az 1 oyun saati önce (Hikâye 1,5, Zor 0,75), en az üç kanaldan okunur: biri zemin ya da ışık, biri ses, biri HUD. Oyun kamerası gökyüzünü görmez: işaretin asıl yeri zemin, ışık, duman, hayvan ve sestir.

| Hedef | 2 saat önce | 1,5 saat | 1 saat | 0,75 saat | 0,25 saat | Varış |
|---|---|---|---|---|---|---|
| Yağmur, çisenti, sağanak | Bulut gölgesi artar | Duman yere çöker | Rüzgâr döner, uzak yağmur sesi, HUD | Kişi satırı, karga alçak uçar, tarbagan ıslık çalar | Işık iner, damla sesi | 20 sn'de yağış |
| Gök gürültülü, kuru fırtına | Gölge, ufukta bulut duvarı | | Uzak gök gürültüsü, atlar, rüzgâr, HUD | Kişi satırı | Kararma | Fırtına Önü 15 sn |
| Dolu | | | | Gök kararır, yağmur sesi sertleşir | Gök yeşile çalar | Dolu Sağanağı |
| Fırtına | Bulut duvarı | | Rüzgâr, atlar, Yol Kemikleri, HUD | Kişi satırı | Bora sıklaşır | Fırtına |
| Toz | Sarı duvar | | Atlar, develer çöker, rüzgâr, HUD | Kişi satırı | Ufuk sararır | Toz duvarı |
| Kar, sulu kar, yoğun kar | Bulut gölgesi | Duman çöker | Rüzgâr, bora sertleşir, HUD | Kişi satırı | Işık iner | Kar |
| Tipi | Kar sürüyor | | Yol Kemikleri, atlar, sığır ve yak sırtını rüzgâra verir, HUD | Kişi satırı | Kar yataylaşır | Tipi |
| Sis | Önceki akşam açık, durgun | | HUD (gece) | Kişi satırı (akşam) | | Şafakta sis |

- **Kişiler.** 15 m içinde konuşan kişi, altyazı. Ana: «Keçenin ağzını bağla yavrum, yağmur geliyor.» Baba: «Gök davulunu geriyor. Atları ahıra al.» Palak: «Bulut Çilyan'dan iniyor. Akşama kar.»
- **Mene.** Konuşmaz. Cephe 1 saat içindeyse göğü değil sürüyü gösterir: sağır çocuk havayı hayvandan okur.
- **Hayvanlar ([K65](/docs/source/design/decisions#k65)).** Deve toz cephesinde bağırır, toplanır, ağzını kuma gömer; deveci: «Deve çöktü, toz geliyor!» Turna ve kaz cephe önünde alçak uçar, sesi kesilir; zeren fırtınada rüzgâraltına akar; köpek 1 km içindeki gök gürültüsünde inler. Ayrıntı: [Hayvanlar](/docs/world/animals).
- **HUD.** Saatin yanında simge, cephe yakınsa altında ince ok, üstüne gelince tek satır: «Duman yere çöküyor.», «Ay ağıl aldı.», «Ufuk sararıyor.»
- **Halk bilgisi.** Çöken duman, ay halesi, şafak kızıllığı işarettir.
- **Gök okuma.** Yeni beceri değil: Demirkazık (II. Perde) önümüzdeki 6 saati okutur: «{saat} sularında {tür}.»
- **Göl boğası.** Göllü dünyada (ana kamp) gök gürültülü fırtınanın ya da fırtına cephesinin 1 saat önünde uzak, alçak bir böğürtü bir kez duyulur (K35). Doğrulanacak: önce kodla basılır ve kulakla sınanır; kod yetmezse ElevenLabs efekt ucundan tek dosya alınır, kredisi önce sorulur ([Yol Haritası](/roadmap#item-weather)).

```varlik
status_weather_sun, status_weather_sun_cloud, status_weather_cloud, status_weather_fog, status_weather_rain
status_weather_storm, status_weather_hail, status_weather_snow, status_weather_wind, status_weather_dust
```

## Oynanışa etkiler

| Tür | Ses maskesi | İz × | Taşsız ateş / taşlı | Yanan yapıya su /sn | Araba | Kalkmaz |
|---|---|---|---|---|---|---|
| Açık, bulut, kapalı | 0 | 1 | ×1 / ×1 | 0 | 1 | |
| Sis | 0 | 1 | ×1 / ×1 | 0 | 0,9 | |
| Çisenti | 0,1 | 0,8 | ×1,25 / ×1,1 | 0,25 | Çamur | |
| Yağmur | 0,35 | 0,6 | ×1,5 / ×1,25 | 1 | Çamur | |
| Sağanak | 0,8 | 0,3 | 60 sn / ×2 | 2,5 | Çamur | |
| Gök gürültülü fırtına | 0,6 + gürültü | 0,4 | 60 sn / ×2 | 1,5 | Çamur | Evet |
| Kuru fırtına | 0,2 + gürültü | 0,8 | ×1,5 / ×1,25 | 0 | 1 | Evet |
| Dolu | 1 | 0,5 | 60 sn / ×1,5 | 1,5 | 0 | Evet |
| Rüzgâr | 0,15 | 0,8 | ×1,25 / ×1,1 | 0 | 1 | |
| Fırtına | 0,5 | 0,5 | 40 sn / ×1,5 | 0 | 0,85 | Evet |
| Sulu kar | 0,3 | 0,6 | ×1,5 / ×1,25 | 0,5 | Çamur | |
| Kar | 0,15 | 0,5 | ×1,5 / ×1,25 | 0 | 0,85 | |
| Yoğun kar | 0,3 | 0,25 | ×2 / ×1,5 | 0,3 | 0,7 | |
| Tipi, Kara Boran | 0,9; 1,2 | 15 sn | 40 sn / ×2 | 0,5 | 0 | Evet |
| Toz | 0,7 | 0,1 | 40 sn / ×1,5 | 0 | 0 | Evet |

Ateş sütununda süre «o sürede söner» demektir, çarpan yakıtın ne kadar hızlı yandığıdır. Barınakta ateş ×1'dir.

- **Görüş ve gizlilik.** Nöbetçi ve hayvan en çok görüşün 0,6'sı kadar görür. Görüş 100 m'nin altındaysa gerçekten gizler. Şimşek ifşa eder (≈0,25 sn), gök gürültüsü örter (3 sn). Çanla yürüyüş 14 m duyulur: yağmurda 10,4, sağanakta 7,8, yakın gök gürültüsünden hemen sonra 3,0 m. «Çakınca say, gürleyince koş.» I. Perde gecelerinde bu sayılar kilitlidir.
- **İz, koku, av.** Yağmur ve kar izi kısaltır, kar dinince 1 saat taze iz kalır. Koku rüzgâr yönüne bağlıdır. Fırtınada küçük av ine girer; yağmurdan sonra av ×1,3, mantar ×2.
- **Ateş, kurutma.** Yağmurda kuru kav gerekir: «Kav ıslak; kuru kav gerek.» Fırtınada taşsız yakılmaz. Kurutma çarpanı: rüzgâr 1,3, açık 1, bulut 0,9, kapalı 0,6, sis 0,3, kar 0,3, toz 0,5, yağışta 0; çatı altında en az 0,6. Sağanak açıkta asılı yiyeceğin %10'unu bozar, küçük dolu %20, iri dolu %50.
- **Yapılar.** Yağmur yanan yapıyı söndürür, kar söndürmez. Islak keçe zor tutuşur. Sıçrama yarıçapı 10 + rüzgâr m. Fırtına: bağsız çadır bölüm başına %25 olasılıkla bir aşama düşer, bağsız raf içinin %20'sini döker. Bağla (`E` 3 sn) kalıcıdır. İri dolu saz ve çadırı yıpratır, yapıyı aşama 1'in altına indirmez.
- **Ok ve yay.** Ok rüzgârla sürüklenir: 12 m/sn'de 60 m'de 1,3 m; nişan halkası bunu içerir. Islak kiriş hasarı en çok %15 düşürür; sadak ıslanmayı yarıya indirir, ateş kurutur.
- **At.** Bağ <40 iken yakın gök gürültüsü ve yıldırımda at şaha kalkar, dörtnalda atabilir; Bağ ≥70 iken az etkilenir. Doluda ürker, tozda rüzgâra karşı dörtnal yok. Rüzgâr dörtnala ±2 m/sn'ye dek ekler.
- **Yol.** Çamurda araba 4,8 m/sn, yol dışı yavaş. Ağır fırtınada araba kalkmaz: «Fırtına dinmeden araba kalkmaz (≈{n} saat).» Yük Devesi çamuru okumaz, kilit süresince yarı hızla yürür. Yolcu çatı altında kurudur ([Yolculuk](/docs/world/travel)).
- **Şantiye.** Ustalar yalnız dolu, tipi, toz ve Kara Boran'da sığınır. Yağmur genel işi ×0,85, keçe adımını ×0,7 yapar. İş miktarı değişmez, takvim uzar: kampta ortalama ≈%8.
- **Kişiler, sürü.** Ağır havada nöbetçi olmayan kişi sığınır, nöbetçi kalır ama görüş konisi daralır. Sürü sıkışır, kıçını rüzgâra döner.
- **Ordu.** Hava yorgunluğu yağmur ×1,2 … tipi ×2. Han birliği iki kat yorulur (Chao Cuo). Çadırsız yağmur gecesi moral −2.
- **Ekonomi.** Yağmurda açık yığın ıslanır, yakıt değeri ×0,5. Dolu tarlayı biçer: küçük %10, iri %30. Yerleşim tepkileri: [settlement.md §15.3](/docs/source/design/settlement#15-3-hava-k22).
- **Çocuk.** Tehdit yoktur. Birikintiye zıplar, karda başını kaldırır, doluda kollarını başına kaldırır. Ana fırtınada çağırır.

| Zorluk | Hikâye | Normal | Zor |
|---|---|---|---|
| İşaret süresi | ×1,5 | ×1 | ×0,75 |
| Yıldırım oyuncuyu hedefler | Hiç | Kural | Kural |
| Yıldırım oyuncu yapısını tutuşturur | Hiç | Kuru fırtınada | Kuru fırtına ya da az ıslak keçe |
| İri dolu oyuncuya | Yok | Can −0,5/sn, taban %40 | Can −0,75/sn, taban %30 |

## Yıldırım

Yıldırım uzun ve yalnız olana iner. Fırtına başına ≈4,6 yıldırım, fırtınaların ≈%33'ünde biri 600 m içinde.

**Hedef.** 45 m içinde en büyük skor: boy × yalnızlık + sırt − 0,15 × uzaklık. Yalnız ×1, orman kıyısı ×0,7, orman içi ×0,4. Adaylar: ağaç 6–14 m, Gök Direği 12, Sancak Direği 10, yurt 8,6, kule 7, ahır 4,9, araba 2,8, açıkta atlı 2,6. Yaya seçilmez. Gerçek kural: sırttan in, atından in, yalnız ağacın altına sığınma.

**Tasarlanmış düşüş.** Fırtına başına bir kez. Serbest Gez'de %60 olasılıkla Çocuktan 30–70 m uzakta, kadrajın içinde, yalnız ağaç ya da direk yeğlenir, kampın yapılarına inmez. Oyunda açıktaysan %25 olasılıkla 0–45 m. Hedef 40 m içindeyse 1,5 sn önce vızıltı ve hedefte ince halka.

**Adil kurallar.**

- Çocuk 25 m içinde hiç hedef olmaz. Hikâye zorluğunda oyuncu hiç hedef olmaz.
- Mete ancak skoru en büyükse vurulur: Can −%35, taban 1, Yara ve Düşüş yok.
- Kurulmakta olan yapı hedef olmaz. Vurulan yapı 1 oyun günü bekler. Yerleşimde fırtına başına en çok bir yapı.
- Islak keçe tutuşmaz, yalnız iz kalır. Kuru fırtınada kuru keçe tutuşur.

**Direkler.** Sancak Direği 10 m, konut halkasına dikilir, ≈9 m içindeki yurtların yerine yıldırımı o alır. Gök Direği 12 m, yalnız Kutlu Tepe'dedir, yurtları korumaz: vuruşu perde başına bir alamettir.

**Vurulan.** Yalnız ağaç kömürleşir ve yarılır, 2 kömür verir, ateş yayılmaz. Yurt ve ahır tepeden hasar alır, kuruysa tutuşur. Takipçi ve kişi 2 sn sendeler, Can −20, ölmez. Kışın fırtına yoktur: Kışlak'taki Yıldırım Çamı geçmişi söyler.

## Hikâye kilitleri

Kilit planlayıcıyı durdurur, sahneye bağlanır, saate değil. I. Perde'nin kalibre sayıları böyle korunur.

| Sahne | Hava |
|---|---|
| Perde açılışı → İlk Çetele sonu | Açık, rüzgâr 2 |
| Eksik Ölçü (Gün II gece) | Kar, taze kar: iz dersi |
| Tündük Kaldırma | Açık, rüzgâr 0,8 |
| Elçi | Parçalı bulut |
| Av | Rüzgâr 5 m/sn, kuzey-kuzeydoğudan: rüzgâr altı öğüdü doğru çıkar |
| Toy ve baskın | Açık, rüzgâr 3 m/sn kuzeydoğudan; gök gürültüsü yok |
| Kül Sabahı | Kapalı, karanlık, rüzgâr 1 |
| Göz Yolu ve hüküm | Kar, rüzgâr 0,5: yüzler okunur |
| Son Gece | Kar; sis 1.400 m'den 140 m'ye iner, bulut 0,3 → 0,9, rüzgâr 1,5 → 6 |
| Adak Aygırı yaklaşması | Rüzgâr 4 m/sn batıdan |
| Donuk Kamp | Donar: kar havada, kıvılcımlar asılı |
| Gök Açılır | Rüzgâr kesilir, kar bir an durur, kubbede açıklık |
| Kara Yol | Oyuncunun 30 m çevresinde sükûnet: kar dik düşer |
| Kara Boran | Sis 140 m, Ak Otlak'ta 45–80 m; rüzgâr 8, bora 15 |
| Kemik Boğazı | Kar, rüzgâr 6, gökte ilk aydınlık |
| Şafak Sırtı | Açık, rüzgâr 2: fırtına kesilir |
| Ev | Kimlik (açık, kuru); ışığı 11 Nisan 14:46,2'nin ikindisi ([K76](/docs/source/design/decisions#k76)) |

Son Gece'nin ikinci yarısında kemikler, Adak Aygırı ve nöbetçi Kara Boran'ı önceden haber verir. Kilit dışındaki Kışlak saatleri `hexi` satırıyla akar, hiçbir ana adım havayı beklemez.

**Önsöz, Çocukluk ve Yola Çıkış.** Önsöz'de hava yoktur: geri çekilme menünün gece ışığında ve menü havasındadır, mit sineması parşömen videosudur (yedeği keçe pano), doğumun ışığı sabit örnektir. Çocukluk (22 Eylül MÖ 228, 08:40–≈11:00) açık, rüzgâr 2 m/sn; oyuncak okun 20 m'deki sapması ≈0,15 m kalır, öğretim bozulmaz. Yola Çıkış (15 Aralık MÖ 213, şafaktan önce) kapalı, rüzgâr 1,5 m/sn, yağış yok, karlı avlu.

**Serbest Gez başlangıcı ([K83](/docs/source/design/decisions#k83)).** İlk yarım oyun saati açıktır. Üçüncü yurdun ocağı yanana dek ağır türler (sağanak, gök gürültülü ve kuru fırtına, fırtına, dolu, toz) yoktur: ateş başı anı korunur; yağmur, çisenti, sis ve kar serbesttir. Yağmur işi yavaşlatır: kamp baharında yağmur payı ≈%7,7, 13 saatlik kurulumda yağmur gelme olasılığı ≈%33, tek bölüm ilk dumanı 22–45 oyun dk geciktirir. Bu yüzden aile sabit bir saate değil ilk dumana dek bekler ([Zaman ve Takvim](/docs/world/time-calendar)). Ocak yanınca bütün tablo açılır. Menü, Yeni Oyun, oluşturucu ve Ev havası kimliktir: menü karesi değişmez.

**Sonraki perdeler** ([K56](/docs/source/design/decisions#k56)).

| Kilit | Perde, tarih | Hava | Dayanak |
|---|---|---|---|
| İlk ocak gecesi | II, Mete'nin kendi ocağı | Açık, durgun, ay görünür | «Kendi göğü» anı |
| Talim tozu | II, Islık Alanı | Görüş <80 m iken talim turu bekler | Talim tozda yapılmaz |
| Dailin | III, 16 Eylül MÖ 208 | Sayım ve Söğüt Turu boyunca açık, rüzgâr ≤3 m/sn | Shiji 110: güzde at semizken toplanırlar |
| Tunghu baskını | III, 26 Eylül MÖ 208 şafağı | Sis, görüş 60 m | Tasarım tercihi |
| Beşinci Ay Sunusu | IV, 17 Haziran MÖ 205, Gök Dağı eteği (`hexi`) | Tören saati açık, sonra fırtına serbest | Shiji 110: 5. ayda Lung-çeng'de toplanırlar |
| Lung-çeng | IV, 25 Haziran MÖ 203 (`orkhon`) | Tören saati açık, sonra fırtına serbest | Aynı |
| Ordos'ta Dailin | IV, 22 Eylül MÖ 203 | Sayım boyunca açık, rüzgâr ≤3 m/sn | IV'ün son görevi |
| Baideng | V, 25 Kasım–1 Aralık MÖ 201 | Yoğun kar, sonra tipi; Han yorgunluğu ×2, Han yaya karda ×0,6 | Shiji 110: büyük kar; yalnız kar oynanır, soğuk değil |
| Yada taşı | V, seçmeli | Kam taşla kar ister, Baideng kilidi 1 saat erken gelir | Tasarım tercihi, kaynak geç dönem |
| Lung-çeng | VI, 2 Haziran MÖ 198 ve 4 Haziran MÖ 176 | Tören saati açık, sonra fırtına serbest | K56: VI'da da iki kez oynanır |
| Son Dailin | VI, 9 Eylül MÖ 174 | Açık, rüzgâr ≤3 m/sn | Mete sayım sürerken ölür |

Tarihli kilit tablo gününe bağlıdır; tarih kapısı ([K33](/docs/source/design/decisions#k33)) saati o güne atlatınca kilit açılır.

## Kar örtüsü ve Kar Kabuğu

Bozkırın kış felaketi soğuk değil, otu örten buzdur. Sıcaklık modellenmez, kural havanın sırasından okunur (K1). Ad oyunda «Kar Kabuğu»dur; «zud» yalnız belgede.

- **Kar örtüsü** 0–1 arası (1 ≈ 40 cm), saatte bir. Kar, yoğun kar, tipi ve sulu kar artırır; yağmayan saat ve güneş azaltır, baharda üç kat.
- **Derin kar günü:** 06:00'da örtü ≥0,6. Sürü yem ister.
- **Kar Kabuğu:** derin kar, üstüne o gün ≥1 saat sulu kar ya da yoğun kar veya tipiden sonra tümüyle açık öğle (%12), ardından açık gece. Şafakta oluşur, 5–10 gün sürer. Örtü <0,3 ya da bahar erken bitirir.
- **Tepki yerleşimindir:** otlak ×0,3, sürü yem ister, yem yoksa günde %2 yiter. I. Perde'de örtü oyunu değiştirmez; kampta kar örtüsü yalnız görünüş ve izdir.

| İklim, kış | Derin kar günü payı | Kabuk / kış | Kabuklu gün payı |
|---|---|---|---|
| `hangai` | 0,413 | 1,23 | 0,06 |
| `kerulen` (Tunghu Yurdu) | 0,258 | 0,97 | 0,039 |
| `steppe_south` (Tanhu Ordusu) | 0,16 | 0,62 | 0,02 |
| `daibei` (Mayi, Baideng) | 0,133 | 0,37 | 0,012 |
| `orkhon` (Göl Obası, Tanhu Kampı, Lung-çeng) | 0,067 | 0,29 | 0,009 |
| `ordos` | 0,017 | 0,07 | 0,001 |
| `gobi` (Islık Alanı) | 0,016 | 0,01 | 0 |
| `hexi` | 0,015 | 0,05 | 0,001 |
| `hexi` I. Perde (yoğun kar ve tipi dışlı) | 0,001 | 0 | 0 |
| `alashan` | 0 | 0 | 0 |

Tablo prototipin gerçek hava çekirdeğinden basıldı: sabit tohumla 150 kış × 120 gün koştu, sonucu `d2/weather-model.json` v2'dedir (2026-11-03; [d2/core.md §3.6](/docs/source/design/d2/core#3-6-kar-ortusu-ve-kar-kabugu-zud)). Ekonomi bu dosyayı okur: Tanhu Ordusu'nun kışında derin kar günü %16,0'dır ([K49](/docs/source/design/decisions#k49)). Eski tablo yaklaşık planlayıcıdandı (`steppe_south` 0,135 / 0,63 / 0,027) ve kalktı.

Doğrulanacak: Godot'un hava çekirdeği aynı kurallarla sabit tohumla 150 kış koşar ve kabulde kalır (W26): `steppe_south` derin kar payı 0,16 ±0,03, kabuk 0,62 ±0,3 / kış; `gobi` kabuk ≤0,05 / kış; I. Perde'nin `hexi` satırında kabuk 0. Eski merkez (0,135 ±0,03, 0,63 ±0,3) de modelin değerini kapsar ([Yol Haritası](/roadmap#item-weather); ekonomi eşliği [Yol Haritası](/roadmap#item-econ-sim-run)).

Doğrulanacak: yeni hava görünümleri ve ekran yağışı boyalı süzgeçte ışık durakları klasörüyle aynı oturumda sınanır (W16: on kare ve dört yeni görünüm; kuru fırtına, sulu kar, kampın kış kar örtüsü, kampın güz tonu). Yağmur çizgisi zayıfsa katman alfası 0,5'ten 0,65'e çıkar, başka değer denenmez; göz onayı senindir ([K58](/docs/source/design/decisions#k58), [Yol Haritası](/roadmap#item-weather)).

## Oyunda şu an

> [!DURUM]
> Godot'da hava yoktur: gece sabittir, gökte ay, yıldızlar ve yavaş akan bulutlar (örtü 0,58) çizilir, yurt dumanı hafifçe rüzgâra yatar; ses olarak gece ambiyansı çalar ([d3/game-state](/docs/source/design/d3/game-state)). Yok: hava türleri, planlayıcı, yağmur, kar, şimşek, ıslak zemin, kar örtüsü, hava sesleri, HUD simgesi, kilitler. Prototipte denendi: 17 tür, dokuz iklim, planlayıcı, etki değerleri, kilitler, yıldırım seçimi ve Kar Kabuğu (kodu yazıldı, testleri geçti); kubbe, bulut ve bulut gölgesi.

## Yol haritası

Hava, planlayıcı ve ekran sınamaları I. Perde'nin ilk fazındadır; Kara Boran'ın tipi prototipi [act-1-p4](/roadmap#act-1-p4) fazındadır.

```ilerleme
act-1-p1
```

## Kaynaklar

- [decisions.md: K1, K22, K33, K49, K56, K58, K65, K67, K76, K83](/docs/source/design/decisions#k22)
- [weather.md: bütün hava tasarımı](/docs/source/design/weather)
- [weather.md §4: iklim tabloları ve kampın mevsimi](/docs/source/design/weather#4-iklim-tablolari)
- [weather.md §5.9: ıslaklık, çamur, kar örtüsü](/docs/source/design/weather#5-9-islaklik-camur-kar-ortusu)
- [weather.md §6: hikâye kilitleri](/docs/source/design/weather#6-hikaye-kilitleri)
- [weather.md §7: işaretler](/docs/source/design/weather#7-okunur-isaretler)
- [weather.md §8: etki matrisi](/docs/source/design/weather#8-etki-matrisi)
- [weather.md §8.7: yıldırım](/docs/source/design/weather#8-7-yildirim)
- [d2/core.md §3: hava sayıları, Kar Kabuğu](/docs/source/design/d2/core#3-hava-k22)
- [fauna.md §7: hayvanların hava tepkileri](/docs/source/design/fauna#7-hava-ve-mevsim-tepkileri)
- [d3/game-state: Godot'daki oyunun bugünkü hâli](/docs/source/design/d3/game-state)
