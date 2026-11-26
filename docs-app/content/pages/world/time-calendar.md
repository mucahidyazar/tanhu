---
title: Zaman ve Takvim
order: 40
status: tasarim
summary: 'Bir oyun günü 60 gerçek dakikadır ve gerçek tarihli tek takvim bu hızla akar; gündüz, gece, ay ve mevsim aynı saatten okunur, perde arasındaki yıllar Akan Kronik''te ay ay akar.'
sources:
  - docs/design/decisions.md
  - docs/design/time.md
  - docs/design/d2/core.md
  - docs/design/story.md
  - docs/design/structures.md
  - docs/design/settlement.md
  - docs/design/act1.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Bir oyun günü 60 gerçek dakikadır, hız ayarı yoktur ([K20](/docs/source/design/decisions#k20)). Oyunun tek saati gerçek tarihli takvimdir: «27 Eylül MÖ 234» diye yazılır ve bu hızla akar; gündüz, gece, ay evresi ve mevsim aynı saatten okunur ([K67](/docs/source/design/decisions#k67)). Saat yürürken ve dövüşürken akar; bloklayan konuşmada, sinemada, kitapta ve haritada durur. Güneş gerçek gök hesabıyla doğar ve batar: Hexi kışında gün 24 dakika, gece 31 dakika sürer. Oynanan takvim Çocukluk'la (22 Eylül MÖ 228) başlar, I. Perde 2 Aralık MÖ 210'dadır. Perde son görevle biter; aradaki yıllar Akan Kronik'te ay ay akar, takvimde boşluk yoktur ([K42](/docs/source/design/decisions#k42)).

> [!NOT]
> «1 gün 60dk olacak»

> [!NOT]
> «Hikaye gerçek tarih zamanı içinde gerçek zamanlı akacak, tarih sürekli akacak»

İki notun birlikte nasıl geçerli olduğunu sonra yazdın (E4.1):

> [!NOT]
> «1 gun 60dk olacak ve gercek tarih dedigim takvim bu kural ile akacak ve gunduz gece buna gore calsiacak»

Tasarım buna uyar (K67). Takvim tek sayaçtır, oyunda ve Serbest Gez'de aynıdır: geri gitmez, sıfırlanmaz, ikinci sayaç tutulmaz. Hızlı geçişler (Bekle, Uyu, yolculuk, Akan Kronik) adı konmuş atlamadır ve takvimi ileri yürütür; atlanan her gün takvime işlenir. «Sürekli akan tarih» budur.

## Oran

| Birim | Gerçek süre |
|---|---|
| 1 oyun günü = 24 oyun saati = 1.440 oyun dk | 60 dk = 3.600 sn |
| 1 oyun saati | 2,5 dk = 150 sn |
| 1 oyun dakikası | 2,5 sn |
| 1 gerçek saniye | 0,4 oyun dk |

Zaman ikiye ayrılır. **Eylem süresi** gerçek saniyedir, oyunun hissidir: vuruş, 2 sn basılı toplama, şişte 12 sn pişirme. **Dünya süresi** oyun dakikasıdır: güneş, yakıt, kuruma, bozulma, emek, program. Eylem dünyayı durdurmaz: 15 sn'lik kazan pişirmesi saati 6 oyun dk ilerletir.

Düşük kare hızında da gün 60 dakikadır: 15 fps'de saat yine duvar süresiyle birikir (kare başına en çok 0,25 sn), takılma ve sekme dönüşü saati sıçratmaz.

## Saatin aktığı ve durduğu yerler

| Durum | Saat | Not |
|---|---|---|
| Oyun (I–VI) ve Serbest Gez | Akar | 2,5 sn = 1 oyun dk |
| Çocukluk (22 Eylül MÖ 228) | Akar | 08:40'ta açılır; ≈6 dk'lık sahne en çok ≈2 sa 24 dk eder |
| Yürürken konuşma, altyazı | Akar | Kişiler iş bırakmaz |
| Yavaşlatma (ıslıklı ok ×0,25, öğretim ×0,5, baskın ×0,6) | Aynı çarpanla | |
| Yol Akışı | 1–4 kat | Saat yolun doğal süresi kadar ilerler |
| Göz Yolu sineması | Akar | 120 sn = 48 oyun dk |
| Bloklayan diyalog, sinema, seviye ekranı, Terazi, Yol Kartı, Bekle tekeri, Son Görev Kapısı, Kronik onay kartı | Durur | Konuşma zaman yemez |
| Harita, kitap, duraklatma, gizli sekme | Durur | Kaçan süre telafi edilmez; harita 0,085 birimde kapanınca saat akar ([K40](/docs/source/design/decisions#k40)) |
| Donuk Kamp | Durur | «Ay Saati durur» |
| Bekle, Dinlen, Çalış, Uyu, Yolu Kısalt | Atlar | Görsel akış ya da karartma, sonda toplu işleme |
| Atlas yolculuğu, tarih kapısı, anlatıcının iki köprüsü, Akan Kronik | Uzun atlama | Atlanan günler takvime işlenir |
| Menü, Yeni Oyun (Önsöz dahil), oluşturucu | Saat yok | Godot'da gece ışığı; menü karesi değişmez |
| Ev sahnesi | Bekler | 11 Nisan 14:46,2'nin ikindi ışığı ([K76](/docs/source/design/decisions#k76)) |

**Vakitler (I. Perde).** Hikâye anı saatlidir ve iki ucu vardır. Erken ucunda çağırır: çan çalar, kişi seslenir, «Seni çağırıyorlar.» Geç ucundan 30 oyun dk önce ikinci çağrı gelir ([K43](/docs/source/design/decisions#k43)). Geç ucunda başlamadıysa saat durmaz: 3 sn karartmayla oyuncu vaktin yerine götürülür, «Vakit geldi: {görev}.» Çatışmadaysan karartma o bitince olur. Eski İş Puanı kalktı. Günlerin saatleri: [time.md §9.2](/docs/source/design/time#9-2-hikaye-gunleri).

**II–VI'da vakit (K43).** Vakit çağrısı yalnız takvim olaylarında kalır: Dailin, Lung-çeng, Beşinci Ay Sunusu ve tablo günü olan ana görev sahnesi. Çağırır ama karartmayla götürmez; kaçırılan olay Kronik'te «Sensiz yapıldı.» satırı olur. Ana görev zamanla kapanmaz, yan görevlerin zaman penceresi yoktur.

**Tarih kapısı ([K33](/docs/source/design/decisions#k33)).** Tarihli son görev üç kol bitince açılır. Kollar tablo gününden önce biterse Son Görev Kapısı'nda «Yola Çık» seçilince saat o günün sahne saatine atlar. Oyuncu o günü geçtiyse atlama yoktur: sahne günü değil yılı ve mevsimi söyler («Güz, MÖ 208»), saat durmaz.

**Bekleyişler.** Saat yalnız üç yerde bekler: I. Perde'de günün ana işi bitmeden Tan başına varınca (Şafak, Gün I'de 06:12), Hikâye zorluğunda Son Gece 05:45'te ve Ev sahnesinde 14:46,2'de. Serbest Gez'de saat hiç beklemez. Günün ana işi uykuyu açar: bitmeden döşek «Bugünün işi bitmedi: …» der.

## Takvim

**Tek takvim (K67, K42).** Gündüz ve gece güneşin o günkü sapmasından, ay evresi mutlak günden, mevsim yılın gününden okunur. Saat yalnız K20'nin durma yerlerinde durur: bloklayan söz, sinema, kitap, harita, duraklatma, Bekle tekeri, Donuk Kamp, I. Perde'nin iki bekleyişi ve Ev sahnesi. Bekle, Uyu, Dinlen, Çalış, yolculuk, tarih kapısı ve Akan Kronik takvimi ileri yürütür; Kronik atlanan günleri ay ay gösterir. Perde son görevle biter, sayaç yoktur.

- **Tek sayaç.** Mutlak gün rehinenin günüdür: Gün I = 1.041, Palak'ın sayımıyla «Bin kırk birinci gün». 1. gün 26 Ocak MÖ 212. Perdeler ilerledikçe sayaç sürer. Geriye de uzanır: doğum −7.785 (27 Eylül MÖ 234), Çocukluk −5.600, Yola Çıkış −41 (15 Aralık MÖ 213).
- **Yıl.** 365 gün, artık gün yok. Tarih gerçek takvimin (Jülyen tablo) günüdür; oyunun günü gerçeğinden doğumdan ölüme 60 yılda 15 gün ayrılır. Artık gün K25, K33 ve K56'nın günlerini ve testlerini kaydırırdı, oyuncuya bir şey kazandırmazdı.
- **Gün sınırı.** Takvim günü gece yarısı artar. Yeni gün, şafak olayı ve hikâye günü Tan başında başlar: bozkırın günü şafakla başlar.
- **Kesin tarih (K33).** Tarih oyuncuya tam yazılır; «c.», «dolayı» ve aralık yoktur. Kaynağı olmayan seçilmiş tarihler de kesin söylenir: doğum 27 Eylül MÖ 234 şafağı, darbe 14 Haziran 209, Baideng kuşatması 25 Kasım–1 Aralık 201, ölüm 9 Eylül 174.
- **Serbest Gez.** Aynı takvimi okur; kayıtlı saati yoksa 11 Nisan MÖ 209 14:46,2'de açılır, mevsim tarihle döner: 15 Mayıs'ta yaz (34 gerçek saat sonra), 23 Ağustos'ta güz (134), 16 Kasım'da kış (219). Serbest Gez'de tarih olayı işlenmez: perde, Kronik ve takvim olayı yoktur. Eski kaydın günü 1.171 + gün olarak göçer.
- **Önsöz ve köprüler.** Önsöz saat okumaz: çerçevesi (10 Nisan MÖ 209 gecesi) ve doğum (27 Eylül MÖ 234) sinemanın tarihidir. Anlatıcının iki köprüsü adı konmuş atlamadır: takvim 22 Eylül 228'den Yola Çıkış'a (15 Aralık 213), oradan I. Perde'ye (2 Aralık 210) ileri gider, parşömen videoları aradaki yılları gösterir. Bugün Yeni Oyun'un akışı bu günleri yolculuğa yazar ([K99](/docs/source/design/decisions#k99)); oyunun saati yoktur, Çocukluk'ta ışık sahnenin kendi saatiyle akar.

| Mevsim | Tarih | Gün |
|---|---|---|
| Kış | 16 Kasım–15 Mart | 120 |
| Bahar | 16 Mart–14 Mayıs | 60 |
| Yaz | 15 Mayıs–22 Ağustos | 100 |
| Güz | 23 Ağustos–15 Kasım | 85 |

Doğrulanacak: Serbest Gez'in güz tonu ve kış kar örtüsü ekranda sınanır, menüye dönüşte görünüşün kimliğe döndüğü ekran görüntüsüyle doğrulanır; güze 134, kışa 219 gerçek saat olduğu için önceliği düşüktür ([Yol Haritası](/roadmap#item-roam-calendar)).

**Ekranda tarih.** II–VI'da her Tan'da 2 sn tarih kartı yazar: «8 Haziran MÖ 209 · 1.229. gün». Serbest Gez'de yalnız tarih yazar («12 Nisan MÖ 209»), çünkü gün sayısı rehinenin sayımıdır. I. Perde'de kart yoktur, günü Palak sayar. Kayıt kartı I. Perde'de «Gün II, ikindi», II–VI'da ve Serbest Gez'de «8 Haziran MÖ 209, ikindi» yazar.

## Gerçek güneş

Gün ışığı enlem ve yılın gününden hesaplanır. Oyun saati yerel güneş saatidir, öğle 12:00. Gün uzunluğu bir ayar kolu değil, yer duygusudur: oyuncuya mevsimi anlatır. Gün yine 60 dakikadır, payı değişir. Hiçbir dünya sapmayı iğnelemez.

| Yer, enlem | Tarih | Doğuş | Batış | Gün ışığı | Gece evresi |
|---|---|---|---|---|---|
| Göl Obası, 47,35° | 11 Nisan, açılış günü | 05:22 | 18:38 | 33 dk | 21,7 dk |
| | 15 Mayıs, yaz başı | 04:29 | 19:31 | 37,6 dk | 16,9 dk |
| | 23 Ağustos, güz başı | 05:04 | 18:56 | 34,7 dk | 20,1 dk |
| | 16 Kasım, kış başı | 07:23 | 16:37 | 23,1 dk | 31,6 dk |
| Orhun, Lung-çeng, 47,35° | 15 Ocak | 07:35 | 16:25 | 22 dk | 32,6 dk |
| | 15 Temmuz | 04:12 | 19:48 | 39 dk | 15,3 dk |
| Tanhu Ordusu, 43,5° | 15 Ocak | 07:22 | 16:38 | 23 dk | 31,7 dk |
| | 15 Temmuz | 04:26 | 19:34 | 38 dk | 16,8 dk |
| Hexi, 38,9° | Gün I, 2 Aralık | 07:11 | 16:49 | 24 dk | 31,0 dk |
| | 15 Temmuz | 04:40 | 19:20 | 37 dk | 18,3 dk |
| Ordos, 39° | 22 Eylül MÖ 228, Çocukluk | 05:56 | 18:04 | 30,3 dk | 25,0 dk |

Süreler gerçek dakikadır. Doğum sahnesi saat okumaz: ışığı çekim başına sabit örnektir (içeride 05:50, dışarıda 06:03; güneş doğuda, dolunay batıda ufukta). Bütün tablo: [time.md §3](/docs/source/design/time#3-gun-isigi).

**Serbest Gez'in açılış dakikası.** Prototipin menü güneşi 47,35°K'de ancak 11 Nisan 14:46,2'de o yönde durur (yükseklik 36,7°, azimut 235,1°, güneybatı). Serbest Gez'in açılış dakikası bu hesapla seçildi, sonra mevsim akar (K67). Godot'nun menüsü gece kampıdır (ay ışığı azimut 140°, yükseklik 50°), ilk kare ona eşit olamaz: kayıtlı saati olmayan Serbest Gez de 14:46,2'de açılır ve gece menüsünden bu ikindi ışığına 2,4 sn süzülmeyle geçilir (K76). Menü, Yeni Oyun ve Önsöz gece ışığında kalır, saati okumaz; Ev 14:46,2'nin ikindi ışığında bekler. Neden: menü karesine dokunulmaz, yeni kod yolu açılmaz, camp3'ün takvimi bu açılışa bağlıdır (ustalar 14:54'te iner). Açılışı Önsöz'ün gecesine almak reddedildi: menünün ışık yönlerini ve camp3'ün takvimini bozardı.

## Evreler ve ışık

| Evre | Başı | Sonu | Kışlak Gün I | Gerçek dk | Ana kamp, 11 Nisan | Gerçek dk |
|---|---|---|---|---|---|---|
| Tan | Sivil şafak − 30 dk | Doğuş + 30 dk | 06:12–07:41 | 3,7 | 04:21–05:52 | 3,8 |
| Sabah | Doğuş + 30 dk | 10:30 | 07:41–10:30 | 7,0 | 05:52–10:30 | 11,6 |
| Öğle | 10:30 | 13:30 | 10:30–13:30 | 7,5 | 10:30–13:30 | 7,5 |
| İkindi | 13:30 | Batış − 60 dk | 13:30–15:49 | 5,8 | 13:30–17:38 | 10,3 |
| Akşam | Batış − 60 dk | Sivil alaca + 30 dk | 15:49–17:48 | 5,0 | 17:38–19:39 | 5,1 |
| Gece | Sivil alaca + 30 dk | Sivil şafak − 30 dk | 17:48–06:12 | 31,0 | 19:39–04:21 | 21,7 |

Her evrenin bir ışık durağı vardır; altı durak arasında ışık sürekli karışır. Altı durağın değerleri hedeftir ve ekran görüntüsüyle ayarlanır ([K58](/docs/source/design/decisions#k58)); İkindi ve Akşam'ın başlangıç değeri prototipin menü ışığıdır. Gece mavi ama okunurdur: yeni ayda bile zifiri karanlık yok, ocağın sıcak havuzu ve kapı parıltıları karenin sıcak noktalarıdır. Çalışma sırasında yeni ışık eklenmez. Kışlak'ta kış güneşi hep güneydedir: varsayılan kadrajda kameranın arkasından vurur, gölge öğlede bile cismin 1,8 katıdır. Gölge düşüren yükseklik 15°'nin altına inmez; güneş alçaldıkça doğrudan ışık söner, gölge boyu cismin en çok 3,7 katıdır.

![İkindi durağı: kamp, göl vadisi, prototipin ikindi menü ışığı.](/media/docs/research/sky-shots/pullback_golden.jpg)

![Akşam durağı: aynı kadraj, kapı ışıkları yanmış.](/media/docs/research/sky-shots/pullback_dusk.jpg)

Doğrulanacak: altı durağın renkleri ve 15° gölge sınırı tek ekran görüntüsü klasöründe ayarlanır: altı durak × Mete × ot ve kar × iki yakınlaştırma (28 ve 40 m) = 24 kare, ayrıca Kışlak sabahının (08:30) ve akşamının (15:30) dört gölge karesi. Kabul P1 ve P4'tür (en kötü durakta Mete'nin pelerini kalabalıktan ΔE ≥0,05 ayrılır), göz onayı senindir. Ot kareleri kampta ([Yol Haritası](/roadmap#item-sun-light)), kar ve gölge kareleri Kışlak kurulunca ([Yol Haritası](/roadmap#item-winter-camp-terrain)).

**Görevlerde ve kayıtta.** Eski metinlerdeki dört dilim bu evrelerin birleşimidir; koşullar değişmez. Görevler vakti evreyle yazar: «Öğle çanı · Öğle». II–VI'da takvim olayı tarihle yazılır: «Dailin · 16 Eylül».

**Gök Kavisi.** Sağ üstte yarım daire: güneş doğudan batıya yürür, gece ay evresiyle yürür. Altında evre adı; ayarla saat sayısı da açılır. Son Gece Ay Saati kipine geçer, Tipide gizlenir. Hava simgesi yanındadır.

```varlik
ui_sky_arc, ui_moon_clock, ui_wait_wheel
```

**Gece göğü ([K35](/docs/source/design/decisions#k35)).** Gökte MÖ 209'un gerçek yerinde adlı dokuz yıldız vardır: Kök Boz At (Kochab), Ak Boz At (Pherkad) ve Yedi Karakçı (Büyük Ayı'nın yedisi). O yıl kutupta parlak yıldız yoktur: [Demirkazık](/encyclopedia/demirkazik) «gökte dönmeyen nokta»dır, kazık çizilmez. Gök bir turu ≈59,8 gerçek dakikada döner. Göğe Bak: gece ateş başında ilk Dinlen'de ve Bakış Noktası'nda kamera 6 sn kuzeye döner, 40° yukarı bakar. Varsayılan kadrajda gök görünmez; eğim 15°'ye inince karenin üst ≈%14'ü göktür.

## Bekle, Uyu, Dinlen, Çalış

| Kip | Nerede | En çok | Tokluk | Ne yapar |
|---|---|---|---|---|
| Bekle (`T`) | Her yer, yasaklar dışında | 12 oyun saati; «Tan ağarana dek» 15 | −5 / oyun saati | Teker: Bir saat, Üç saat, sıradaki evreye dek. Teker açıkken saat durur |
| Uyu | Döşek: Rehine Yurdu, ana kampta aile döşeği, II'den kendi yurdun, yerleşim ve ordugâh, Menzil, Gecelik Kamp | 15 oyun saati | ×0,25 | Akşam ve Gece evresinde; I. Perde'de günün ana işi bitince. Tanla uyan ya da Güneşle uyan. ≥4 oyun saati süren uyku bütün yaraları kapatır |
| Dinlen | Ateş başı (`E` 3 sn) | 12 oyun saati | ×0,5 | Stamina dolar; ≥2 saat ve Tokluk ≥25 ise Yara −1 (6 saatte bir) |
| Çalış | Mete şantiyede (`T` ya da `E` 1 sn) | 12 oyun saati | Uyanık oranı | Bir saat, Üç saat, Akşama dek, Bitene dek. Tokluk <25 ise kapalı: «Önce bir şey ye.» Çocukta «Bir saat yardım et» |
| Uzun atlama | Atlas yolculuğu, tarih kapısı, köprüler, Akan Kronik | Sınırsız | Kronik kendi hesaplar | 24 oyun saatini aşan atlama tek olaydır, sistemler kapalı biçimde tümler |

Tokluk zorlukla çarpılır: Hikâye 0,7, Normal 1, Zor 1,15.

- **Bekle'nin yasak yerleri:** 30 m içinde düşman ya da avcı hayvan, nöbetçi şüphesi, yürüyen at, su ya da buz üstü, Ay Saati, baskın ya da akın, Kara Boran, boss, bir vaktin içi.
- **Kesilir:** vakit geldi, düşman ya da avcı 20 m'ye girdi (köpek yanındaysa 60 m), nöbetçi şüphelendi, hava sertleşti, akın uyarısı geldi ([K55](/docs/source/design/decisions#k55)), görev olayı.
- **Uyku Zarı ([K45](/docs/source/design/decisions#k45)).** Güvenli yerde uyku yalnız vakit ve bekleyişle kesilir. Açıkta, Gecelik Kamp'ta, gecede en çok bir zar atılır: boş arazide `0,10 × ateşsiz saat ÷ uyku saati` (kurt ya da yaban hayvanı; ateş korur), düşman zonunda `0,25 × ateşli saat ÷ uyku saati` (devriye; ateş ele verir). Hikâye'de zar yoktur, Zor ×1,5. Onluk ya da yoldaş partisi yanındayken zar atılmaz, nöbeti onlar tutar (K88). Ayrıntı: [Tek Gecelik Kamp](/docs/gameplay/overnight-camp).
- **Görünüm:** ≤3 saat bekleme: dünya %60'a kararır, gök ve gölge hızlı akar, ≈2,3 sn. >3 saat ve uyku: karartma, Gök Kavisi döner, ≈3 sn; uyanışta «Gün III, tan».
- **Uyuyan dünya durmaz:** yakıt yanar, sırık kurur, çiğ et bozulur, ustalar çalışır, hava saat saat ilerler, her şafakta Kış Hesabı düşer, av stoğu %30 geri gelir ([time.md §7.4](/docs/source/design/time#7-4-atlamada-sistemler)).

Çalışmanın emek hesabı K21 ve [K50](/docs/source/design/decisions#k50)'dedir: İD (iş dakikası: bir işçinin bir oyun dakikası) birimiyle; inşaat ışıkta gece de sürer, ışık çarpanı aşağıda ([İnşa ve Emek](/docs/buildings/construction-labour)).

## Ay olayları

Ay 29,53 günde döner. **Gün IV 18:00 dolunaydır**: baskın o akşamdır. Gün I gecesi %91, Son Gece %99, Gün VI %95. Neden: Shiji 110 «ay dolunca saldırırlar» der; Teoman Yüeçilere dolunayda saldırır, Mete eksilmeye başlayan ayın altında kaçar. Serbest Gez ayrı ay tutmaz: açılış öğleden sonrasında (11 Nisan MÖ 209) ay %36 aydınlık ve küçülendir, gece yarısından sonra doğar.

**Akın penceresi (K55).** Ordugâh ve yerleşim akını yalnız ay ≥%97 aydınlıkken gelir: ayda ≈3 gün; bulut pencereyi değiştirmez. Oynanan takvimdeki pencereler: III 15–17 Eylül 208; IV 16–18 Haziran 205 ve 24–26 Haziran 203; V 27–29 Kasım 201 (kuşatmaya düşer, akın yazılmaz). Dailin günü (16 Eylül 208) ve iki Lung-çeng günü (17 Haziran 205, 25 Haziran 203) akın yazılmaz.

**Bulut ay ışığını keser, ay hesabını değil** ([K22](/docs/source/design/decisions#k22)). Ayın evresine bağlı ordu olayları takvimdendir. Bulut yalnız ışığı, gece emeğini, ay kartını ve gözcü satırını değiştirir.

| Durum | Işık sınıfı | Şantiye çarpanı |
|---|---|---|
| Ateş, meşale ya da fener altı | Işıklı | ×1 |
| Batışa dek | Gündüz | ×1 |
| Sivil alaca; açık gecede dolunay, ay ≥30° | Alaca | ×0,7 |
| Yarım ay; kapalı gecede dolunay; aysız gece | Karanlık | ×0,4 |

**Ay Saati (Son Gece).** Düğüm'le başlar, buz saatinde biter: [Amaga](/encyclopedia/amaga)'nın «Şafakta buza» dediği saat. Konuşmalar saati yemez.

| Zorluk | Amaga | Düğüm | Buz saati | Saat süresi | Gerçek süre |
|---|---|---|---|---|---|
| Hikâye | 20:00 | 20:10 | Yok, 05:45'te bekler | | Sınırsız |
| Normal | 20:00 | 20:10 | 06:40 | 10 sa 30 dk | ≈32 dk |
| Zor | 21:30 | 21:40 | 06:40 | 9 sa | ≈28,5 dk |

Buz saatinden 2 saat önce takipçi +1, 1 saat önce +1. Yakalanma saati 60 dk ilerletir. Saat biterse oyun bitmez.

**Toplantılar ([K56](/docs/source/design/decisions#k56)).** Kış gündönümünden sonraki ikinci yeni ay 1. aydır. Kış Toplantısı 1. ayın yeni ayında, [Lung-çeng](/encyclopedia/longcheng) 5. ayın dolunayında, [Dailin](/encyclopedia/dailin) 8. ayın dolunayındadır («at semizken»). Dailin üç, Lung-çeng dört kez oynanır:

| Toplantı | Perde | Tarih | Mutlak gün | Ne olur |
|---|---|---|---|---|
| Dailin | III | 16 Eylül MÖ 208 | 1.694 | Yerleşimin sayımı; perdenin doruğu |
| Dailin | IV | 22 Eylül MÖ 203 | 3.525 | Ordos'ta, Mete'nin doğduğu otlakta; son görev, yerleşimin sayımı değildir |
| Dailin | VI | 9 Eylül MÖ 174 | 14.097 | Son sayım; Mete sayım sürerken ölür |
| Lung-çeng | IV | 17 Haziran MÖ 205 | 2.698 | Mete Hexi'dedir; Beşinci Ay Sunusu Gök Dağı eteğinde |
| Lung-çeng | IV | 25 Haziran MÖ 203 | 3.436 | Büyük toplantı ve armağan kervanı; Loufan ve Baiyang katılır |
| Lung-çeng | VI | 2 Haziran MÖ 198 | 5.238 | Yirmi dört başın sancakları, kuzeyin beş halkının başları |
| Lung-çeng | VI | 4 Haziran MÖ 176 | 13.270 | Mektup yazılır, Kunmo getirilir |

İlk Lung-çeng (30 Haziran 209) ve öteki yılların Dailin'i Kronik satırıdır; doğum, beş, on bir, on beş ve on yedi yaş ile rehin kararı da Dailin'e düşer. Kış Toplantısı oynanan günde sahne açmaz, Kronik'in sonraki koşusunda toplu işlenir (K42).

## Perde başları ve Kronik

| Bölüm | Başlangıç | Mutlak gün | Mevsim | Saat | Son görev, tablo günü | K25 günü (ölçü, oyunda okunmaz) |
|---|---|---|---|---|---|---|
| Önsöz, çerçeve | 10 Nisan MÖ 209 gecesi | 1.170 | Bahar | Sinema, saat okumaz | Doğumda biter (27 Eylül MÖ 234) | |
| Çocukluk | 22 Eylül MÖ 228, 08:40 | −5.600 | Güz | Akar | Sayım ≈11:00 | |
| Yola Çıkış | 15 Aralık MÖ 213, şafaktan önce | −41 | Kış | Akar (≈90 sn) | Ata biniş | |
| I | 2 Aralık MÖ 210 | 1.041 | Kış | Akar; iki bekleyiş | Ev, 11 Nisan 209; kaçış 7 Aralık 210 | 6 hikâye günü |
| Ev | 11 Nisan MÖ 209 | 1.171 | Bahar | 14:46,2'de bekler | | |
| II | 1 Haziran MÖ 209 | 1.222 | Yaz | Akar | Av, 14 Haziran 209 | 12 |
| III | 1 Eylül MÖ 208 | 1.679 | Güz | Akar | Yenilenlerin seçimi, 1 Ekim 208 | 12 |
| IV | 1 Haziran MÖ 205 | 2.682 | Yaz | Akar; iç Kronik 205 → 203 | Ordos'ta Dailin, 22 Eylül 203 | 14 |
| V | 20 Kasım MÖ 201 | 4.314 | Kış | Akar | Bir köşe açılır, 1 Aralık 201 | 12 |
| VI | 1 Haziran MÖ 198 | 5.237 | Yaz | Akar; altı iç Kronik | Son Dailin, 9 Eylül 174 | 16 |

Son sütun K25'in bütçesidir ve yalnız tasarım ölçüsüdür: oyunda okunmaz, ana görev zamanla kapanmaz, son görev yalnız üç kol bitince açılır. Oynanan gün ±%30 esner, perde ≈420 gerçek dk sürer (uyku ve bekleme atlanır). Son görev açıldıktan sonra 3., 6. ve 9. günde kişiler sabırsızlanır; bedel yoktur.

**Perde arası: Serbest Dolaşım ve Akan Kronik (K42).** II–VI'da son görev bitince kapanış sahnesi ve perde kartı gelir, dünya açık kalır: iç haritalar, Plan Kipi, Defter, sonraki perdeye taşınan yan görevler, av, inşa. Takvim 60 dakikalık günle akar, yeni ana görev açılmaz. Oyuncu dilediğinde «Kronik'e bırak» der (perde kartı, duraklatma kitabı ya da Mete'nin her ocağı). Onay kartı hedef tarihi, geçecek yılı ve açık yan görevlerin sonucunu yazar; hedef `max(sonraki perdenin başı, bugün + 30 gün)`'dür. Akış: perde kartı → atlas dönem değişimi → tarih ay ay akar → mevsim nabzı → 2–5 ozan ya da anlatıcı satırı → hane ve sürü sayıları → yeni perde kartı. Süre `T = clamp(mevsim sayısı × 5 sn, 30, 90)`; `E` basılı ×4, Esc atlar. En çok iki Kronik Kararı gelir: tek kart, iki seçenek, 10 sn sonra Kâhya seçer. I'in sonunda Mete oynanmaz: 11 Nisan–1 Haziran 209 doğrudan Kronik'tir (30 sn); II yazılana dek «II. Perde yakında» kartı kalır ([K7](/docs/source/design/decisions#k7)).

| Geçiş | Tarih | Gün | Süre | Öne çıkan |
|---|---|---|---|---|
| I → II | 11 Nisan → 1 Haziran 209 | 51 | 30 sn | Sürüler yaz otlağına çıkar |
| II → III | 15 Haziran 209 → 1 Eylül 208 | 443 | 30 sn | Teoman'ın gömüsü, ilk Lung-çeng ve ilk Dailin, Kış Toplantısı |
| III → IV | 1 Ekim 208 → 1 Haziran 205 | 973 | ≈53 sn | Ç'in düşer; Göl Obası'nın ozanı ölür, kopuzu Çocuğa kalır |
| IV içi | 18 Haziran 205 → 24 Haziran 203 | 738 | ≈40 sn | Yimo'dan Yitu doğar |
| IV → V | 22 Eylül 203 → 20 Kasım 201 | 789 | ≈43 sn | Lan Hatun ölür, Han kurulur |
| V → VI | 1 Aralık 201 → 1 Haziran 198 | 912 | 50 sn | Heqin barışı |
| VI içi | 4 Haziran 198 → 8 Eylül 174 | Altı koşu | 30–90 sn | Han Xin ve Liu Bang ölür, Lu Wan sığınır, mektup Han'a varır |

Kronik'in kapalı hesabı K25'inkidir: sürünün doğumu ve kesimi, hane perdenin açılış tabanına çıkar, bakım, bozulanın silinmesi, saklananın bir kış ve ambar kapasitesiyle sınırı, kış stoğu hedefe dek; kabuğa dokunmaz. Yoldaki kervan varmış sayılır. Perde kartı özeti: «{y} yıl geçti. {h} hane, {s} baş sürü; ambar kışa {p}.» Bütün satırlar: [Perde Arası: Akan Kronik](/docs/story/chronicle).

## Ana kampın günü

Serbest Gez Çocuğun oyunudur, kampta Mete yoktur ([K6](/docs/source/design/decisions#k6)). Ana kamp Göl Obası'dır: Göl Vadisi'nde rastgele bir oba, Tanhu Kampı değildir ([K106](/docs/source/design/decisions#k106)). Ocak halkı [Ana](/encyclopedia/mother), [Baba](/encyclopedia/father), [Ozan](/encyclopedia/bard), [Ağabey](/encyclopedia/older-brother) ve [Çocuk](/encyclopedia/child)'tur ([K37](/docs/source/design/decisions#k37)). Saatler 11 Nisan içindir; takvim aktıkça sabah blokları Tan'la, akşam blokları batışla kayar (16 Kasım'da Ana közü 06:58'de canlandırır, akşam aşı 16:29'dadır). 05:00'te Ana közü canlandırır, süt kaynatır; Baba 05:15'ten atları yemler, kütük yarar, 10:00–12:00 yaya avdadır; Ağabey sabah nöbetine çıkar, öğlende döner. Ozan 09:00'da akort eder; dördü birden 12:00–22:30 ateş başındadır: öğleden sonra türküler, 19:00'dan uzun destan, ozanın kopuzu. Akşam aşı 18:30'dadır. Gece 23:00'ten sonra uzaktan kurt sesi 6–10 dk'da bir duyulur.

**Üçüncü yurt ([K83](/docs/source/design/decisions#k83)).** [Oktar](/encyclopedia/oktar), [Erka](/encyclopedia/erka) ve [Dengiz](/encyclopedia/dengiz) Serbest Gez açıldıktan 20 sn sonra iner (ilk oturumda 14:54) ve üçüncü yurdu kurar. Süre K50'nin eğrisidir: `T(n) = 60 × 0,75^(n−1)` gerçek dk; ekip 2,75 el (Dengiz çırak, 0,75) ile 36,3 gerçek dk saf emektir, öğün ve seferlerle 37,2 dk.

| Çocuğun yardımı | İlk duman | Gerçek dk | Tündük | Uuk biter | Aile ilk dumanı görür mü |
|---|---|---|---|---|---|
| Yok | 05:48, şafakta | 37,2 | 20:36 | 23:40 | Hayır |
| Yalnız ayak işi | 05:37, şafakta | 36,8 | 20:33 | 23:29 | Hayır |
| Yalnız katılma | 04:02, gece | 32,8 | 19:52 | 22:32 | Evet |
| Katılma ve ayak işi | 03:43, gece | 32,1 | 19:48 | 22:22 | Evet |

**Aile bekler (K83).** Kurulum gecesi Ozan, Ana ve Baba 22:30'da yatmaz, 23:00'e dek ateş başında kalır; Ağabey 22:30'da yatar. 23:00'te yurt aşama ≥4 ise (uuk bitmiş) aile ilk dumana dek bekler; 05:00'e dek duman çıkmazsa Ana közü getirir, ocak yurt bitince yanar, aile yine oradadır. Aşama 4'ün altındaysa aile yatar, ocak Ana'nın sabah közüyle yanar. «Gece dinlenilsin» emri verilirse ekip 22:00'de çıkar, 06:00'da döner, yardımsız yurt ertesi gün 14:17'de biter. Sabit 04:15 bitişi seçilmedi: yağmur keçe adımını ×0,7 yapar ve yalnız katılmanın 13 dakikalık payını aşardı. Ayrıntı: [İnşa ve Emek](/docs/buildings/construction-labour).

## Oyunda şu an

> [!DURUM]
> Godot'da saat ve takvim yoktur, gece sabittir: menü, Yeni Oyun ve Serbest Gez aynı ay ışığındadır (azimut 140°, yükseklik 50°); gökte ay, yıldızlar ve yavaş akan bulutlar vardır ([d3/game-state](/docs/source/design/d3/game-state)). Gün, mevsim, Bekle tekeri, Gök Kavisi, tarih kartı, kampın saat programı, vakitler, Ay Saati ve Kronik yok. Prototipte denendi: dünya saati, takvim, gerçek güneş ve ay hesabı, evreler, Bekle ve Uyu satırları, atlamalar ve kayıt; kodu yazıldı, testleri geçti, ışığa bağlanmadı.

## Yol haritası

Saat ve takvim, Serbest Gez'in takvimi, güneş ve ay, Bekle ve Uyu tekeri I. Perde'nin ilk fazındadır. Kampın günü [act-1-p2](/roadmap#act-1-p2), Akan Kronik [act-1-p6](/roadmap#act-1-p6), Dailin Sayımı [act-3-p2](/roadmap#act-3-p2) fazındadır.

```ilerleme
act-1-p1
```

## Kaynaklar

- [decisions.md: K6, K7, K20, K25, K33, K42, K43, K45, K55, K56, K58, K67, K76, K83](/docs/source/design/decisions#k67)
- [time.md: bütün saat ve takvim tasarımı](/docs/source/design/time)
- [time.md §2: tek takvim, perde başları, toplantılar](/docs/source/design/time#2-takvim)
- [time.md §5.5: menü karesi ve Serbest Gez'in açılışı](/docs/source/design/time#5-5-menu-karesi-ve-gecisler)
- [time.md §6: saatin akışı](/docs/source/design/time#6-saatin-akisi)
- [time.md §7: bekle, dinlen, uyu, çalış](/docs/source/design/time#7-bekle-dinlen-uyu-calis)
- [time.md §8: ana kampın günü](/docs/source/design/time#8-ana-kamp-serbest-gez-de-saat-programi)
- [time.md §9.6: Ay Saati](/docs/source/design/time#9-6-ay-saati-act1-md-8-7-13)
- [d2/core.md §1: saat ve takvim sayıları](/docs/source/design/d2/core#1-saat-ve-takvim-k20)
- [story.md §2 ve §13: zaman çizelgesi, Akan Kronik](/docs/source/design/story#13-perde-arasi-akan-kronik)
- [structures.md §11.6: üçüncü yurdun emeği](/docs/source/design/structures#11-6-emek-ve-oyuncunun-yardimi)
- [d3/game-state: Godot'daki oyunun bugünkü hâli](/docs/source/design/d3/game-state)
