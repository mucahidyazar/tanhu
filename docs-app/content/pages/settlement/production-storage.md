---
title: Üretim ve Depolama
order: 30
status: tasarim
summary: 'Yerleşim hamı işler, kaplarda saklar ve kışa bilerek dar girer; oyuncu toplar ve buyurur, parçayı usta, yapıyı ekip kurar; darı yalnız Surlu yolda ve VI''dan ekilir.'
sources:
  - docs/design/decisions.md
  - docs/design/settlement.md
  - docs/design/economy.md
  - docs/design/d2/core.md
  - docs/design/d2/econ-model.json
  - docs/design/weather.md
  - docs/design/time.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Yerleşim, ham malı parçaya, parçayı yapıya çeviren bir zincirdir. Oyuncu toplar ve küçük işi yapar; parçayı usta, yapıyı ekip kurar. Tezgâhlar sürekli emirle kendiliğinden çalışır, mal bir yerin kaplarına girer, Defter o kapları tek ambar gibi gösterir. Kış bilerek dardır: açığı sürek avı, takas ya da akın kapatır.

> [!NOT]
> «yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak»

Tasarım bu notla aynı yöndedir: yurt, ahır, ağıl, ambar, atölye ve ötekiler malzemeyle (K24) ve emekle (K21) kurulur. Tek tek yapıların malzemesi: [Plan Kipi](/docs/settlement/plan-mode) ve [Yapı Kataloğu](/docs/buildings/catalog).

## Mal nereden gelir

| Kaynak | Kural ([K24](/docs/source/design/decisions#k24)) |
|---|---|
| Toplama | Düğümden. Mete gerçek saniyeyle (odun 6, taş 10, cevher 15 sn), işçi İS ile (kütük 2,5; ot 1,5; cevher 5). İS iş saatidir: bir işçinin bir oyun saati |
| Av | Hayvana göre belirli verim; büyük avda kemik ve iç yağı |
| Sürü | Süt, kırkım (bahar 1, güz 0,5 yün), kıl, doğum, soğum, tezek; III'ten Tunghu haracı yılda 20 ham deri |
| Savaş ganimeti | Düşman türüne göre belirli, rastgele düşme yok; I. Perde düşmanı yeni mal vermez. Adlı silah sahneye elle konur. Esir yok. Hun muhafızı 0,5, seçkin muhafız 1 kabuk verir (kesirli sayaçla, rastgele değil), yabancı düşman kabuk vermez; def edilen akının düşenleri aynı tablodan ×0,6 verir ([K49](/docs/source/design/decisions#k49)) |
| Takas | Satıcılar, aşağıda. II'den para Kabuk'tur: 1 kabuk = 1 Aş ([K48](/docs/source/design/decisions#k48)) |
| Söküm | Sağlam yurt 1 Yurt Yükü, sağlam çadır 1 Çadır Yükü verir; öteki yapılar ayaktaki adımların ham malının yarısını, yıkıntı %25'ini |
| Zanaat | Aşağıdaki zincirler |

**Satıcılar.** Hun satıcısı kabuğu tam alır, üstü verir; kesesi şafakta dolar ve şafak stoğunun Kıymet'inin dörtte biridir. Satıcı istediği malı satmaz; fiyat tek tablodan geldiği için satıcılar arası kâr ≤%11 kalır.

| Satıcı | Ne zaman | Stok (şafak) | İster | Kese |
|---|---|---|---|---|
| Tanhu pazarcısı | II'de iki günde bir (ilk 2. gün) Ocak Yeri'nin yanına gelir; III'ten pazar yerleşimdedir, her gün açıktır | darı ×10, tuz ×4, ip ×8, keçe ×6, demir külçe ×2, kalay ×1, tündük ×1; haftada bir Yurt Yükü | yün, kıl, ham deri, kürk, boynuz, sinir, at, sığır | 52 kabuk |
| Takas Yeri'nin Hun gezgini ([K81](/docs/source/design/decisions#k81)) | Takas Yeri kurulunca: III'te 3, IV'te 2, V'te 3 günde bir | tuz ×4, Kandil Yağı ×6, sinir ×6, tutkal ×6, huş kabuğu ×10, tunç hurda ×2 (Kıymet 120) | keçe, yün, ham deri, boynuz, kurut, kuru et, kürk | 30 kabuk (120 ÷ 4) |

Gezginin stoğu III–V'te gereken ve pazarcıda bulunmayan küçük maldır: fener ve kandil için Kandil Yağı, yay için sinir ve tutkal, tündük ve kap için huş kabuğu, temren ve kabuk için tunç hurda; tuz her Hun gezgininin yükündedir ve pazarcıyla ortak tek maldır. Pazarcının stoğunu yinelemek gezgini gereksiz kılardı; at ya da İpek Top gibi büyük mal keseyi şişirirdi, büyük mal zaten takasla döner. Bütün satıcılar: [Para ve Satıcılar](/docs/economy/money-traders).

**İki hız.** Mete toplamada işçiden ≈50 kat hızlıdır: toplama ve el işi Mete'de sıkışır. Tezgâh, usta işi ve kurma sıkışmaz: orada Mete bir işçidir, 1 İS 2,5 gerçek dakika eder. Bir yurdun tezgâh ve usta işini Mete tek başına yapsa 106 gerçek dakika sürer. İşçinin toplama hızı kademe büyüdükçe düşer (çevre katsayısı): 1; 1; 0,85; 0,7; 0,6. Mete'nin taşıma süresine de uygulanır.

**Yurdun zinciri.** Parça biçiminde 89 Yük: 6 taş, bosağa, kerege takımı, 6 ip, tündük, 2 sırık, uuk demeti, çiy, 6 keçe, 1 köz. Toplama 152 İS, işleme 58 İS, kurma 24 İS: toplam 9,7 İG (iş günü: tek işçiyle 60 gerçek dk). Mete her hamı toplarsa 11,0 gerçek dakika. Ham malla kurulursa parçanın zanaat emeği şantiyeye eklenir: +28 İS.

**Kereste bilerek azdır.** Zondaki kalıcı odun ≈1.100 kütük (karaağaç, söğüt, saksavul) ve ≈120 huştur. I–III. kademe ≈700 kütük ister, IV'te bitmeye başlar. Yolu: hanenin getirdiği yurt, IV'ten Hangay kereste kervanı ve takas. Tündük başına 2 huş, Otağ'ın ulu tündüğü 4 huş ister; kuzey tepeleri ≈60 tündüğe yeter. Surlu yolun suru fazladan 480 odun ister, o da kereste kervanıyla gelir ([K52](/docs/source/design/decisions#k52)). Kesim yeri görünür büyür.

## Üretim zincirleri

Tarif, girdi ve süre K24'ündür; aşağıda hangi yapının hangi zinciri taşıdığı. Tezgâh girdisini 150 m içindeki ambarlardan alır, çıktıyı kabul eden en yakın kaba koyar.

| Zincir | Yapı | Başlıca dönüşüm | Usta | Hava |
|---|---|---|---|---|
| Keçe | Keçe Avlusu | 12 yün → 6 keçe (7 İS, 6 saat bekleme); ak keçe 3 yün → 1; çiy 6 saz | | Yağmur ×0,7; sağanak ve sert rüzgârda durur |
| Sepi | Sepi Yeri | 1 ham deri + 1 sepi katkısı → 1 sepi deri (1 İS, 12 saat); IV'te gelen saraçla V'ten savaş eyeri ve at zırhı | Saraç | Su ≤100 m; kurutma yağmurda durur |
| Tutkal | Kazanlı yurt ocağı | 3 kemik → 2 ya da 2 balık → 3 (6 saat) | | |
| İp | El, her yurtta | 3 saz → 1 ip ya da 2 kıl → 1 ip | | |
| Ağaç | Ağaç Atölyesi (Oba'dan) | Bosağa 3 odun + 1 külçe (6 İS); kerege takımı 8 odun + 2 ip (12 İS); uuk demeti 12 odun (8 İS); tündük 2 huş + 2 sinir (10 İS, 24 saat); Küçük Yurt'un küçük kerege ve uuk takımı; Araba Yeri'nin teker çifti 2 odun (10 İS) | Dülger, Arabacı | Çatılı: hava etkisi yok |
| Tunç ve demir | Demirci Ocağı, Fırın | 3 odun → 2 kömür (1,5 İS, 12 saat); 4 demir cevheri + 3 kömür → 1 külçe (4 İS, 6 saat); 4 demir hurda + 1 kömür → 1 külçe (2 İS); IV'ten 1 tunç hurda → 3 kabuk (1 İS) | Demirci | Kıvılcım: ocak rüzgâraltında |
| Ok ve yay | Okçu Yurdu | 5 temren + 5 gövde + 1 tüy → 5 ok (işçi 2,5 İS); yay 12–20 İS, 24 saat | Yaycı | |
| Yiyecek | Kazanlı yurt ocağı, Kurutma Sırığı | Kazanda 1 et → 5 öğün; 10 darı → 5 Aş; 4 süt + 1 tuz → 4 kurut; 4 et + 1 tuz → 4 kak; 10 kısrak sütü → 5 kımız (bahar–güz: kışın kısrak sağılmaz) | Aşçı (toplu yemek ×1,25) | Sırık yağmurda durur |
| Yem | Ahır | Yem Bağı (2 Yük) | Seyis | |
| Yurt yükü | El | Yurt ve çadır yükü; söküm şantiyede, emek ×0,35 | | |
| Tahıl | Darı Tarlası (yalnız Surlu yol) | Ekim 10–31 Mayıs, biçim 1–20 Eylül, tarla başına 0,5 + 0,5 İG; işi Kâhya yapar, kart çıkmaz; tarla başına mevsimde 500 darı, tahıl ambarına kayıpsız ([K54](/docs/source/design/decisions#k54)) | Toprak Ustası | Dolu sağanağı başına küçük dolu %10, iri dolu %30; Haziran–Eylül arası başarılı akın güz ürününün %30'unu çiğner |

Ustası olmayan usta tarifi işlemez. Bekleme oyun saatidir: uykuda ve atlamada da akar. Işıklı atölye gece de çalışır, karanlığın her 4 oyun saatinde 1 meşale yakar; oyuncunun buyurduğu gece vardiyası hanenin Gönül'ünü düşürür.

**Darı neden VI'dan.** Surlu yol V. Perde'de, 20 Kasım 201'den sonra seçilir; o kış tarla kar altında boş durur, Tahıl Kulesi de ilk güzü görmemiştir. İlk ürün VI'dadır. Kronik her yıl tarla adımını işler, ambara yalnız son hasadı yazar: `min(500 × tarla, boş tahıl yeri)`; öncekiler yenmiş sayılır, perde kartı «Tarlalar {n} darı verdi.» der ([Kronik](/docs/settlement/court#kronik)). VI'nın oynanan günlerinde tarla takvimden görünür: 1 Haziran 198 yeşil, 13 Şubat 192 karlı ve boş, 4 Haziran 176 yeşil, 9 Eylül 174 sarı. Göçer yolda tarla yoktur, darı pazardan gelir.

```varlik
field, granary_tower, felt_yard, tannery, wood_shop, smithy, kiln, rack
```

### Sürekli emirler

Tezgâh başına bir liste; Kâhya sırayla işler. Biçim: «{n} tut» (ambarda bu kadar kalsın), «{n} yap», «durdur». Yerleşim kurulunca varsayılan:

| Tezgâh | Emir | Neden |
|---|---|---|
| Keçe Avlusu | Keçe 20 tut; çiy 2 tut | Bakım ve yeni yurt |
| Ağaç Atölyesi | Sırık 8, bosağa 1, kerege takımı 1, uuk takımı 1 tut | Hazır yükü olmayan hane için |
| Demirci Ocağı | Külçe 4 tut; kömür 10 tut | Yurt kapısı, araba |
| Okçu Yurdu | Ordugâh ambarındaki ok stoğu 24 × atlı hedefine doğru, sefer başına ok çizgisi kadar | Sadak |
| Kurutma Sırığı | Kurut 40, kak 20 tut (yaz ve güz) | Kış yiyeceği |
| Kâhya, Oba'dan | Çadır Yükü 2 tut | İsteyen Hane'ye çadır; ambarda varsa kart çıkmaz ([K53](/docs/source/design/decisions#k53)) |

## Mevsim olayları

| Mevsim | Tarih | İş | Yerleşime etkisi |
|---|---|---|---|
| Bahar | 16 Mart–14 Mayıs | Doğum, kırkım (koyun 1 yün, deve 1 kıl), tarama; Gobi'de toz fırtınası; Surlu yolda darı ekimi 10–31 Mayıs | Yün → keçe dalgası; doğumla hane Gönül'ü +2 |
| Yaz | 15 Mayıs–22 Ağustos | Sağım tepesi, kımız; Lung-çeng 5. ayın dolunayında; 8 Ağustos'ta ot biçimi başlar | Yiyecek fazlası kuruta; Toy için kımız |
| Güz | 23 Ağustos–15 Kasım | Ot biçimi 15 Kasım'a dek; ikinci kırkım (koyun 0,5 yün), soğum, kak; darı biçimi 1–20 Eylül; Dailin Sayımı 8. ayın dolunayında ([K56](/docs/source/design/decisions#k56)) | Kış ambarı dolar |
| Kış | 16 Kasım–15 Mart | Onarım, ok ve yay, ağaç işi; Kar Kabuğu tehlikesi | Yem tüketimi; ordugâh dağılır |

Soğum güz sonundadır: koyun ve keçinin %10'u, sığırın %8'i, atın %5'i kesilir, et kurutulup kışa yayılır. Sağım bahardan güze günde iki kezdir (06:00, 19:00).

**Oynanan günler bu takvimin küçük bir parçasıdır.** Perdeler takvimde başlar: II 1 Haziran 209 (yaz), III 1 Eylül 208 (güz), IV 1 Haziran 205 (yaz; içinde Kronik'le 203'ün yaz ve güzüne akar), V 20 Kasım 201 (kış), VI 1 Haziran 198 (yaz; yıl dilimleriyle 174'e dek). Perde son görevle biter, sayaç yoktur ([K42](/docs/source/design/decisions#k42)). Yaz başında açılan perdede yeni kırkım yoktur: yün Kronik'in stoğundan, II'de armağandan ve gelen hanenin getirdiği son kırkımın yarısından gelir. Kademe gününün hesabında ot biçimini III bütün payıyla öder; II ve IV Haziran'da, V kışta açıldığı için ödemez. Boy Yurdu bu yüzden en sıkışık kademedir. Oynanmayan mevsimleri Kronik kapalı biçimde işler ([Hanlık Merkezi](/docs/settlement/court#kronik)).

### Havanın payı

Bu yerleşimin tek tepki tablosudur (K22; soğuk modellenmez, K1).

| Hava | Yerleşim | Sürü |
|---|---|---|
| Sis | Nöbet görüşü ×0,5 | Kurt kaybı ×1,5 |
| Çisenti, yağmur | Islak keçe tutuşma sıçraması ×0,5 | Otlak ×0,9 |
| Sağanak | Taşkın kuşağında aşama 0–1 yapı −20 can; dere kabarır | |
| Gök gürültülü, kuru fırtına | Yıldırım adayı: Sancak Direği, kule, Tahıl Kulesi, yalnız ağaç | At ürkmesi |
| Dolu | Tarla kaybı (yukarıda); çadır keçesinde yırtık olasılığı %10 | Kuzu kaybı %0,5 |
| Fırtına | Bağsız çadır bölüm başına %25 olasılıkla bir aşama; hane fırtına işaretinde kendi çadırını bağlar; Sundurma'dan ot −%5 | |
| Kar, yoğun kar | | Otlak ×0,8, ×0,5; derin kar günü yem ister |
| Tipi | Dış işler durur | Ağılsız sürü %1/gün |
| Toz fırtınası (Gobi, bahar) | Dış işler durur | Otlak ×0,7 |
| Kar Kabuğu (kış) | | Otlak ×0,3; yem yoksa sürünün %2'si/gün |

**Kar Kabuğu** Moğolca *zud*'un oyun adıdır: bozkırın asıl kış felaketi soğuk değil, otu örten kabuktur. Derin kar, ardından sulu kar ya da açık bir öğle, ardından açık bir gece: kabuk bağlar, 5–10 gün sürer. Otlak ×0,3 olur, yem yoksa sürünün %2'si günde yiter, kışta en çok %30. Yerleşimin bozkırında kışta ortalama 0,62 kabuk düşer, derin kar günlerinin payı 0,16'dır (%16,0, K49), kabuk günleri kışın %2'sidir.

## Kaplar ve ambarlar

Bütün kaplar aynı kuraldır (K24): kapasite Yük'le ölçülür, kabul süzgeci kap türündedir. Bir yerin kapları Defter'de tek **Ambar** görünür; eşya süzgecine uyan en yakın boş kaba girer.

| Kap | Kademe | Kapasite (Yük) | Kabul | Başarılı akında |
|---|---|---|---|---|
| Mete'nin sandığı | Mete'nin yurdu | 60 | Hepsi | |
| Ambar Çukuru | Ocak | 120 | Yiyecek, tahıl | %50 olasılıkla bulunur, bulunursa %30'u gider; yanmaz |
| Ambar Yurdu | Oba | 400 | Hepsi | %30 |
| Sundurma | Oba | 500 | Kaba mal ve yem: ot, kütük, kömür | %30; ot sundurması tutuşursa hepsi |
| Tahıl Ambarı | Boy Yurdu | 600 | Yiyecek, tahıl | %30 |
| Hazine | Toy Yeri | 120 | Değerli mal, kabuk | %30, kabuk dahil; 30 m içinde Gözcü Kulesi varsa ×0,5 |
| Tahıl Kulesi | Tanhu Avlusu, Surlu | 800 | Yiyecek, tahıl | %10 |
| Silahlık | Ordugâh, Yüzlük | 200 | Teçhizat, ok, maden | Gece Akını yalnız at hattına gelir |
| Erzak Ambarı | Ordugâh, Yüzlük | 600 | Erzak: yiyecek, yem, ok, yakacak, teçhizat | Aynı |
| Şantiye yığını | Şantiye | Yapının malzeme yükü × 1,25 | O yapının malzemesi | |

- **Ambarcı** kap kaybını ×0,75 yapar, akının başarısına dokunmaz; Hazine, ot sundurması yangını ve sürü kaybı bu çarpanın dışındadır ([K55](/docs/source/design/decisions#k55)). Mete'nin kesesi Hazine değildir, akında güvendedir (K48). Akının tek kuralı: [Hanlık Merkezi](/docs/settlement/court#baskin-ve-savunma).
- **Yerler ayrıdır.** Yerleşim ambarı, ordugâh ambarı ve Hazine birbirine karışmaz. Aralarında yalnız kervan ve Mete'nin heybesi taşır.
- **Oyuncu yerleşim içinde yük taşımaz.** Şantiye ve tezgâh 150 m içindeki ambarlardan kendi taşır; varan araba ve kervan kendiliğinden boşalır.
- **Hane sandığı** hanenindir, yerleşim toplamına girmez.
- **Çukur, I. Perde'nin ilkesinin dönüşüdür:** yazılan el konur, saklanan kalır. Değerli mal çukura girmez, Hazine'dedir.

Kalite yalnız teçhizattadır. Çiğ et edinildiği günden sonraki ikinci şafakta bozulur (24–48 saat).

```varlik
grain_pit, store_yurt, shed, granary, treasury, sack, jar, barrel, crate
```

### Bakım

Hiçbir şey kurulup unutulmaz: keçe yırtılır, ip çürür. Bakım 10 günde bir, mevsim miktarının o 10 güne düşen payı kadar ambardan düşer. Ödenmezse yapı geri düşmeye başlar, konutta hane Gönül'ü −1.

| Sınıf | Mevsim başına | Emek |
|---|---|---|
| Yurt gövdeli yapılar (Hane Yurdu, Ambar Yurdu, Buyruk Yurdu, Elçi Yurdu, Otacı Yurdu, Silahlık, Okçu Yurdu, Erzak Ambarı) | 1 keçe, 1 ip | 0,05 İG |
| Küçük Yurt | ½ keçe, 1 ip | 0,05 İG |
| Tanhu Otağı, Bey Otağı | 2 ak keçe, 2 ip, 1 boya | 0,1 İG |
| Çadır | 1 keçe | 0,02 İG |
| Ahşap yapılar (Ahır, Sundurma, Tahıl Ambarı ve Kulesi, Ağaç Atölyesi, Hazine, Gözcü Kulesi) | 2 odun, 2 saz | 0,05 İG |
| Ağıl (40 m); Çit ve Çit Halkası (10 m) | Ağıl 6 dal; çit 1 odun | 0,01 İG |
| At Hattı, Kuyu | 1 ip | |
| Keçe Avlusu, Sepi Yeri | 2 saz, 1 ip | |
| Demirci Ocağı, Fırın | 2 kil; körükte yılda 1 sepi deri | |
| Yarı Gömük Ev | 2 saz, 1 kil | |
| Sur (10 m) | | 0,02 İG; sağanaktan sonra 0,05 |
| Toy Alanı, Gök Direği, Kuşhane | 1 keçe | |
| Sancak Direği | Yılda 1 keçe | |

Toy Yeri'nde (≈100 yapı) mevsim başına ≈3,4 İG ve ≈55 keçe eder, yani günde ≈0,03–0,06 İG ve ≈0,5 keçe: yerleşim emeğinin %1'inden azı. Ama sürekli küçük bir talep yaratır: Keçe Avlusu ve Sepi Yeri Tanhu Avlusu'nda da çalışır.

## Kış hazırlığı

Yerleşim Hesabı (Defter) kapların içeriğini gün olarak okur. %100 yiyecekte 30 gün, yakacakta 30 gün, yemde kışın 100 gündür. Çizgiler işi etkiler: yiyecek çizgisi <35 ise emek ×0,85, <15 ise ×0,7; yakacak çizgisi <15 ise kazan yanmaz, çiğ et pay vermez.

**Kış bilerek dardır** (K24). Kış payı saklananla %75–115 olmalıdır: altı çözülemez açlık, üstü gerilimsiz kıştır. Yaz ve güz artığının %35'i, soğum etinin %65'i kışa kalır. Ordugâh kışın dağılır, Ordu Payı ×0,1'e iner. Tablo 2026-11-04 resmî koşusudur (`econ-sim --strict`, 0 işaret; derin kar günlerin %16,0'ı).

| Kademe | Hane | Yaz payı | Kış payı | Kış + saklanan | Kış açığı (öğün/gün) | Kapatan sürek avı kolu | ya da arpa torbası/gün |
|---|---|---|---|---|---|---|---|
| Ocak | 3 | %159 | %74 | %97 | 0,4 | 0 | 0,1 |
| Oba | 10 | %139 | %73 | %87 | 5,6 | 0,07 | 0,9 |
| Boy Yurdu | 22 | %141 | %73 | %89 | 11,1 | 0,13 | 1,8 |
| Toy Yeri | 45 | %142 | %73 | %89 | 22,0 | 0,27 | 3,7 |
| Surlu Avlu | 80 | %146 | %73 | %91 (V, tarlasız); tarla ve kuleyle %102, VI'dan | V'te 32,1; tarla ve kuleyle 0, VI'dan | 0,39 | 5,3 |
| Göçer Avlu | 80 | %144 | %73 | %90; sürü tavanında (×1,2) %113 | 35,9; sürü tavanında 0 | 0,43 | 6,0 |

Yakacak her kademede %182'dir. Surlu Avlu'nun altı tarlası mevsimde 3.000 darı (1.500 öğün) verir ve Tahıl Kulesi kuru erzağın %50'sini kışa geçirir: %102. Göçer Avlu'nun sürü tavanı ×1,2'dir; ×1,25'te kış %118 olur, bandı aşardı. Surlu emek ve odunla öder, Göçer sürünün büyümesini bekler; ikisinin de V kışı sürek avıyla, takasla ya da akınla kapanır. Yem ve ot sütunlarıyla bütün tablo: [economy.md §7.1](/docs/source/design/economy#7-1-yerlesimin-ve-ordugahin-kis-hesabi-k23-k24), [Ekonomi Dengesi](/docs/economy/balance).

**Açığı kapatan üç yol:** sürek avı (on avcılık kol kışın günde ≈83 öğün getirir, aynı zamanda ordunun talimidir), takas (arpa torbası), akın.

**Oyuncunun hazırlığı.**

- Kurutma Sırığı'nda kurut ve kak emri (yaz ve güz).
- Kâhya'nın güz yem hedefi: kış için atlı başına 100 gün. Yem hedefi Kar Kabuğu'na hazırlıktır.
- Ambar kurmak. Kışla açılan V. Perde Kronik'in stoğuyla başlar; stok ambar ve sundurma kapasitesiyle sınırlıdır: ambar kurmak kışı korur.
- Ordugâhın kış bekçisinin otu ordugâhın güzde biçtiği yığındır: [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans).

## Oyunda şu an

> [!DURUM]
> Godot'da yok: envanter, toplama, zanaat, tezgâhlar, kaplar ve ambar, sürü hesabı, bakım, satıcılar ve kabuk, Kış Hesabı ve Defter ([d3/game-state](/docs/source/design/d3/game-state)). Menü kampındaki fıçı, sandık, kova, kazan ve odun yığını sahnenin süsüdür, içleri yoktur. Prototipte denendi (saf kod ve sınama, oyundan çağrılmadı): kap kuralları ve aktarma, tezgâh kuyruğu, 11 tezgâh ve 9 zanaatçı rolünün verisi, tarifler, sürü hesabı (mevsim olayları, derin kar, açlık), yerin kaplarından okuyan defter kipi, küme tükenmesi, Kronik'in yıllık adımı. Tarla adımı prototipte de yoktur.

## Yol haritası

Yerleşimin ambarı, tezgâhları ve sürüsü II. Perde'nin «Yerleşim, ordugâh ve ekonomi» fazındadır; kabuk ve satıcılar aynı fazdadır ([madde](/roadmap#item-currency)). Darı tarlası, Tahıl Kulesi ve Kronik'in tarla adımı V'in Surlu ya da Göçer fazındadır ([madde](/roadmap#item-avlu-paths)).

```ilerleme
act-2-p2
act-5-p2
```

## Kaynaklar

- [decisions.md: K24, K48, K49, K52, K53, K54, K55, K81](/docs/source/design/decisions#k54)
- [settlement.md §7.5: atölyeler ve tarla](/docs/source/design/settlement#7-5-atolye), [§7.10: bakım](/docs/source/design/settlement#7-10-bakim), [§8: üretim zincirleri](/docs/source/design/settlement#8-uretim-zincirleri-ve-atolyeler), [§9: depolama](/docs/source/design/settlement#9-depolama)
- [settlement.md §3.2: kereste](/docs/source/design/settlement#3-2-tanhu-ordu-ic-haritasi-taslak), [§4.3: Surlu ve Göçer](/docs/source/design/settlement#4-3-v-kademe-yolu), [§15.3: hava](/docs/source/design/settlement#15-3-hava-k22), [§16.2: Kronik'in tarla adımı](/docs/source/design/settlement#16-2-perde-gecisi-kronik-k25)
- [economy.md §6.7: tezgâhlar ve iki hız](/docs/source/design/economy#6-7-tezgahlar-ve-iki-hiz-k24), [§6.9: işleme zincirleri](/docs/source/design/economy#6-9-isleme-zincirleri), [§7.1: Kış Hesabı](/docs/source/design/economy#7-1-yerlesimin-ve-ordugahin-kis-hesabi-k23-k24)
- [economy.md §9.5: satıcılar](/docs/source/design/economy#9-5-ii-perde-ve-sonrasi-saticilari), [§9.6: kabuk](/docs/source/design/economy#9-6-kabuk-cowrie-k48), [§3.11: sürü](/docs/source/design/economy#3-11-suru), [§3.12: savaş ganimeti](/docs/source/design/economy#3-12-savas-ganimeti)
- [d2/core.md §5.6: kaplar](/docs/source/design/d2/core#5-6-kaplar), [§5.7: tüketim ve kalite](/docs/source/design/d2/core#5-7-tuketim-bozulma-kalite)
- [time.md §2: mevsimler ve perde başları](/docs/source/design/time#2-takvim), [d3/game-state](/docs/source/design/d3/game-state)
