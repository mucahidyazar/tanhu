---
title: Tek Gecelik Kamp
order: 60
status: tasarim
summary: 'II. Perde''den oyuncu yolda ateşin yanına 5 Yük''lük bir kişilik Gecelik Çadır kurar, içindeki döşekte uyur, sabah toplar ya da bırakır; açıkta gecede en çok bir Uyku Zarı atılır, yoldaşlar yanındayken kamp güvenli bir sefer ordugâhıdır (K45, K46, K88).'
sources:
  - docs/design/decisions.md
  - docs/design/survival.md
  - docs/design/time.md
  - docs/design/economy.md
  - docs/design/structures.md
  - docs/design/weather.md
  - docs/design/travel.md
  - docs/design/army.md
  - docs/design/companions.md
  - docs/design/progression.md
  - docs/design/d2/core.md
  - docs/design/d3/oyun-durumu.md
---

## Özü

Yolda gece bastırınca oyuncu kendi kampını kurar: önce ateşi yakar, sonra yanına bir kişilik Gecelik Çadır'ı diker, içindeki döşekte uyur. Sabah çadırı toplar ya da yerinde bırakır. Çadırla döşek 5 Yük'tür, sırtta taşınır; bir gece 1 ip, 2 dal ve yakıta mal olur. Kamp I. Perde'de kapalıdır, II. Perde'de kendi ocağını yakınca açılır.

> [!NOT]
> «küçük tek gecelik kamplar kurabileceğiz, kamp ateşi ve küçük tek gecelik çadırlarla (kamp ateşi ve çadır için malzeme ile kurulacak)»

Karar [K46](/docs/source/design/decisions#k46)'dır: yolun kampı, malzemeyle kurulan kamp ateşi ve bir kişilik küçük çadırdır. Ateş oyuncu ateşinin kuralıyla yanar ([Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting)); yeni olan Gecelik Çadır, döşek, açıkta uyku ve sabah toplamadır. Uyku kuralı bozulmaz: Uyu yalnız döşekte açılır, döşek çadırın içindedir ([K20](/docs/source/design/decisions#k20)). Açıkta uykunun riski [K45](/docs/source/design/decisions#k45)'in Uyku Zarı'dır. K46 tasarım önerisini üç ekle aldı: sabah Topla da `T` ile atlanır, iç haritalarda hazır Eski Ocak durakları vardır, çadır taşıyanın iki atlas yol olayı hafifler.

![Ana kampın taş halkalı ateşi. Gecelik Çadır'ın görseli henüz yok](/media/docs/research/cam-shots/smoke-05-fire-90.png)

```varlik
tent_night, bedroll, tent_ten, tent_kit
campfire, firestriker, branch, pole, rope, felt
```

## Ne zaman, nerede

| Kural | Değer |
|---|---|
| I. Perde | Kapalı; yalnız oyuncu ateşi açıktır (yasak bölgede kurulursa Güven −2). Neden: uyku Rehine Yurdu'na bağlıdır ve günün ana işi uykuyu açar; 07:30'da Sayım vardır; vadi uçtan uca 5,3 dk yürünür, döşek uzak değildir; I. Perde kısıtlıdır (K43) |
| Açılış | II. Perde, Kendi Ocağın görevi (1–3 Haziran MÖ 209); Plan Kipi ile aynı kapı |
| Serbest Gez | Yok: Çocuğun ateşi ve aile döşeği kalır, menü sahnesi değişmez |
| Yer | Yalnız iç haritada; atlas bacağında inilmez |
| Yerleşim ve ordugâh içi | Kurulmaz: orada yurt ve beş kişilik çadır vardır |
| Zon başına | En çok 2 Gecelik Çadır |
| XP | Yok: kurup sökmek öğütmeye dönmez |

## Malzeme ve Yük

| Parça | Malzeme | Yük | Not |
|---|---|---|---|
| Gecelik Çadır (`tent_night`) | 2 dal, 1 sırık, 1 ip, 1 keçe | 4 | Beş kişilik çadırın (`tent`) beşte biri: o 5 er alır, bu 1 kişi |
| Döşek (`bedroll`) | 1 keçe | 1 | Çadırın içine serilir, ayrı eşya değildir |
| **Çadır toplam** | | **5** | Sırtta koşu açık kalır |
| Ateş | 3 odun, 4 tezek ya da 12 dal; 1 kav; çakmak taşı, köz ya da meşale | 12, 2 ya da 6; kav 0,1–0,5 | Oyuncu ateşinin kuralı |
| Taş halkası (isteğe bağlı) | 6 taş | 30 | Sırta sığmaz: yerinde toplanır, terkide gelir ya da Eski Ocak kullanılır |

Neden beşte bir: ağır hava Zor'da en az 45 oyun dakikası önce okunur ([K22](/docs/source/design/decisions#k22)); tek başına kurma bu süreye sığmalıdır.

Bilek 3'te sırtın sınırı 21 Yük'tür, hız `1 − 0,3 × doluluk`'tur:

| Taşınan | Yük | Doluluk | Hız | Koşu ve zıplama |
|---|---|---|---|---|
| Yalnız çadır | 5 | %24 | ×0,93 | Açık |
| Çadır, 4 tezek, 1 reçine | 7,2 | %34 | ×0,90 | Açık |
| Çadır, 3 odun, 1 reçine | 17,2 | %82 | ×0,75 | Koşu kapalı (sınır %75) |

Odun yerinde bulunuyorsa taşınmaz; tezek en hafif yakıttır.

**Gecelik Çadır ile beş kişilik çadır.** Beş kişilik çadır (`tent`) yerleşimde geçici konuttur (½ hane), ordugâhta Onluk Çadırı adıyla 5 er alır. İkisi de üç aşamalıdır (Kazık, Direk ve İp, Örtü); sayılar [structures.md §4.5](/docs/source/design/structures#4-5-kisa-liste) ve [K50](/docs/source/design/decisions#k50)'dendir.

| | Gecelik Çadır | Beş kişilik çadır (`tent`) |
|---|---|---|
| Kişi | 1 | 5 er |
| Taşınan | 5 Yük, sırtta | Çadır Yükü (`tent_kit`) 16 Yük, terkide ya da arabada |
| Emek, tek el | 43,2 İD (7,2 + 14,4 + 21,6) | 216 İD (36 + 72 + 108) |
| Süre | 1 el 108 sn, 2 el 81 sn | 1, 2, 4 el: 9,0, 6,8, 3,8 gerçek dk |
| El tavanı | 2 | 4 |
| Can (Kazık yıkılmaz) | Direk ve İp 6 (ağaç), Örtü 10 (keçe) | Direk ve İp 30 (ağaç), Örtü 50 (keçe) |
| Sabah | Topla: 2 keçe ve 1 sırık döner | Sağlamsa sökülür, 1 Çadır Yükü olur |

## Kurma

İD iş dakikasıdır: bir işçinin bir oyun dakikası, tek işçiyle 2,5 gerçek sn.

| Adım | Emek, tek el | Oyun süresi | Gerçek süre |
|---|---|---|---|
| Ateş: dizme ve yakma (taşlıysa +2 sn) | Basılı tutuş | ≈2 dk | 5 sn |
| Kazık | 7,2 İD | 7 dk | 18 sn |
| Direk ve İp | 14,4 İD | 14 dk | 36 sn |
| Örtü | 21,6 İD | 22 dk | 54 sn |
| **Çadır toplam** | **43,2 İD** | **43 dk** | **108 sn** |
| Sabah Topla (kurmanın 0,35'i) | 15,1 İD | 15 dk | 38 sn |

- **Girdi.** Ateşten uzakta `Y` 0,6 sn basılı tutulunca çadır yeri önizlemesi açılır; kısa basış ateş yeri seçer. Yer seçilince küçük bir şantiye açılır, çünkü 43,2 İD basılı tutma sınırının (12 İD) üstündedir: `E` 1 sn malzeme koyar, `T` «Bitene dek çalış» 2,3 sn'de atlatır. Plan Kipi gerekmez (K46).
- **İki el.** Çadır en çok 2 el alır. Süre [K50](/docs/source/design/decisions#k50)'nin eğrisidir, `T(n) = 108 × 0,75^(n − 1)` gerçek sn: tek başına 108, iki elle 81 sn. Eğri bütün kurma, söküm ve onarımda işler.
- **Usta.** Mete ev işi zanaatının ustasıdır: usta cezası yoktur.
- **Işık.** Önce ateş yakılır. Ateş ışığında emek ×1, ateşsiz ay ışığında ×0,7 (62 dk), karanlıkta ×0,4 (108 dk).
- **Yer.** Eğim normal.y ≥0,9; su ve buz değil; izde ağaç ve iri kaya yok; başka yapıya ≥4 m, yola ≥3 m; senaryonun yasak alanı değil. Yerleşim konutlarının ≤6° kuralı burada işlemez. Ateşle çadır arası ≥6 m'dir; ateşin en küçük evresi bile (6 m ışık, 4 m pay) çadırı aydınlatır.
- **Yasak yer.** Bekle'nin yasak yerlerinde kurulmaz: 30 m içinde düşman ya da avcı hayvan, nöbetçi şüphesi, baskın, boss, bir vaktin içi.
- **Görünüş.** Yeni sanat gerekmez: beş kişilik çadırın ağı küçülür, yarıçap 1,2 m (2,6 m × √⅕), tepe ≈1,1 m.
- **Atlama.** Ateş, kurma, Şiş, Uyu ve Topla `T` ile atlanır: ateş 5, kurma 2,3, Şiş 12, Uyu 3, Topla 2,3 sn; bütün gece ≈25 gerçek sn.

## Gece: Uyu

- Çadırda `E` «Uyu», Akşam ve Gece evrelerinde açıktır: «Tanla uyan» (sivil şafak) ya da «Güneşle uyan» (doğuş + 30 dk). Uyku en çok 15 oyun saatidir.
- Uykuda Tokluk ×0,25 hızla düşer (Normal'de oyun saatinde −1,25); uyanışta oto kayıt alınır.
- ≥4 oyun saati süren uyku bütün yaraları kapatır; Uyku Zarı uykuyu daha önce keserse yaralar kapanmaz ([K45](/docs/source/design/decisions#k45); [Dövüş](/docs/gameplay/combat#yara-ve-dusus)).
- Uyunan Gecelik Çadır Düşüş'ün son barınağıdır: [Umay](/encyclopedia/umay) Eşiği oyuncuyu orada uyandırır. Bırakılan çadır 10 gün bu işi görür.
- Ateş başında Dinlen uyku değildir: zar atmaz, Bekle'nin kesintileri işler.
- Çadır ısıtmaz ([K1](/docs/source/design/decisions#k1)): işi döşek, ıslaklık, dolu ve uyanma yeridir.

## Açıkta uyku: Uyku Zarı

«Uykuda tehlike yoktur» yalnız güvenli yerde geçerlidir: yurt, yerleşim, ordugâh (sefer ordugâhı dahil), Menzil, hikâye döşeği (Rehine Yurdu, ana kampın aile döşeği). Gecelik Çadır güvenli yer değildir: açıkta bir gecede en çok bir Uyku Zarı atılır ([K45](/docs/source/design/decisions#k45)).

| Yer | Ateşin işi | Olasılık | Olay |
|---|---|---|---|
| Boş arazi | Ateş korur | `p = 0,10 × ateşsiz saat / uyku saati` | Kurt sürüsü (sahnede ≤4) ya da zonun yaban hayvanı |
| Düşman zonu | Ateş ele verir | `p = 0,25 × ateşli saat / uyku saati` | Atlı devriye (koni 100°, 24 m; K44) |
| Düşman zonu, ateşsiz ya da küllenmiş kamp | | Zar yok | Bedeli yemektir: ateşsiz kampta yemek pişmez |

- **Çarpanlar.** Hikâye zorluğunda zar yoktur; Zor ×1,5. Kamp barınak zemininde kurulduysa (kaya sığınağı, yar dibi, kurgan odası) ×0,5. Köpek yanındaysa uyanış 8 sn erken gelir.
- **Saat.** Ateşli ve ateşsiz saat uykunun içinde sayılır; küllenmiş köz ateşsizdir. Zar uykunun başında bir kez atılır; tohumu kaydın tohumu, gecenin günü ve zondur: aynı geceyi yeniden yüklemek sonucu değiştirmez.
- **Olay.** Uyurken hasar yoktur, eşya gitmez. Oyuncu uyanır, tehdit 30 m'dedir, oto kayıt alınır, oyun akar: Dövüş ya da Kaç. ≥4 oyun saati uyuduysa yaraları kapanır. Kaçanın çadırı 10 gün yerinde kalır. Olaydan sonra aynı gece yeniden uyumak zar atmaz.
- **Baskın kuralı ayrıdır.** Ambarı olan yerleşimin ve ordugâhın baskın kuralı ([K24](/docs/source/design/decisions#k24), `R / (R + D)`) bu zara karışmaz.
- **Neden.** Bir gecede bir olay, koşulu görünür. Aynı ateş iki yerde iki ayrı karardır: boş arazide kurdu uzak tutar, düşman zonunda nöbetçiye kampı gösterir (duman 60 m, ışık 18–42 m). Düşman zonunda yemek pişer, sonra ateş söndürülür (`F`) ya da Kor'a inince küllenir. Çukurdan ya da Eski Ocak'tan 1 odunla yakılan küçük ateş 240 sn'liktir, 1,2 oyun saatinde Kor'a iner.

Örnekler (9 sa 26 dk uyku):

| Kamp | Uykuda ateşli saat | Boş arazi | Düşman zonu |
|---|---|---|---|
| Ateş uyumadan doldurulur, taşsız | 4 sa 48 dk | %4,9 | %12,7 |
| Taş halkalı | 7 sa 12 dk | %2,4 | %19,1 |
| Ateşsiz ya da küllenmiş | 0 | %10,0 | %0 |
| Taşsız, Zor | 4 sa 48 dk | %7,4 | %19,1 |
| Taşsız, barınak zemini | 4 sa 48 dk | %2,5 | %6,4 |

## Sabah: Topla ya da Bırak

- **Ateş.** Yakıt gece boyu yetmez: taşsız ateş en çok 4 sa 48 dk, taşlı 7 sa 12 dk yanar. Sönen ateş çukur olur, sönüşten 24 oyun saati sonra kalkar; Gecelik Çadır yerindeyken çukur çadırla kalır ([K45](/docs/source/design/decisions#k45)). Çukur 1 odun ya da 2 tezekle kavsız yanar, kahvaltı pişer. Küllenmiş köz ertesi doğuştan 1 oyun saati sonrasına dek yaşar; `Y` ile 1 yakıt onu yakar.
- **Topla.** 15,1 İD (15 oyun dk, 38 gerçek sn; `T` ile 2,3 sn). 2 keçe (örtü ve döşek) ve 1 sırık Heybe'ye döner; 1 ip ve 2 dal gider: kazık yerinde kalır, ip kesilir. Bir gecenin malı tezekle 11 Kıymet'tir (≈3 kabuk): 1 ip, 2 dal, 4 tezek, 1 kav. Dal bulmak ve ip taşımak küçük bir hazırlıktır.
- **Bırak.** Çadır yerinde kalır, dönüp yeniden uyunur. 10 gün sonra kaybolur, içinde kalan gider (sefer ordugâhının kuralı).
- **Çadır sökümü** ([K46](/docs/source/design/decisions#k46)). Tek kural: sağlam taşınır yapı bohçasına döner, öteki hâller ayaktaki adımların ham malının yarısını verir. Gecelik Çadır'ın bohçası yoktur: sağlamsa yukarıdaki gibi toplanır; eksik ya da hasarlıysa ayaktaki adımların ham malının yarısını verir (aşağı yuvarlanır), döşeğin keçesi her durumda döner. Beş kişilik çadır sağlamsa 1 Çadır Yükü olur (16 Yük; emek kurmanın 0,35'i, ≈76 İD, tek başına ≈3,2 gerçek dk); eksik ya da hasarlıysa ayaktaki adımların ham malının yarısını verir ([economy.md §3.13](/docs/source/design/economy#3-13-sokum-ve-kurtarma)).

## Hava

Kurma emek yasasının hava tablosuyla yürür; Örtü keçe adımıdır.

| Hava | Kurma, tek el | Çadır ayaktayken |
|---|---|---|
| Açık, bulut, kapalı, sis, rüzgâr | 43 dk | Etki yok |
| Çisenti | 46 dk | Uyu açık |
| Yağmur, sulu kar | 56 dk | Uyu açık |
| Kar | 48 dk | Uyu açık |
| Yoğun kar | 62 dk | Uyu açık |
| Sağanak, gök gürültülü fırtına | Kazık ve direk ×0,5; Örtü bekler | Uyu açık |
| Fırtına (rüzgâr) | Kazık ve direk ×0,9; Örtü bekler | Bağsızsa hava bölümü başına %25 olasılıkla Örtü bir aşama düşer; Bağla (`E` basılı 3 sn) kalıcıdır |
| Dolu, tipi, Kara Boran, toz | Kurulmaz | Dolu Mete'ye işlemez; iri dolu Örtü'ye −0,2 Can/sn, aşama 1'in altına inmez |

Ağır hava en az 1 oyun saati, Zor'da 45 dk önce okunur ([K22](/docs/source/design/decisions#k22)). 43 dakikalık kurma Zor işaretine sığar; yağmurda 56, yoğun karda 62 dakikalık kurma sığmaz. Hazırlık oyunu budur: işareti görünce çadırı kur, ateşi taşla çevir, Bağla. Çadırın tepesi ≈1,1 m'dir: yaya eşiğinin (1,7 m) altındadır, yıldırım adayı değildir.

## Eski Ocak ve atlas

- **Eski Ocak.** 6 taş 30 Yük ettiği için iç haritalarda hazır durak vardır: 6 taşlık halka ve çukur, harita başına 3–5 ([K46](/docs/source/design/decisions#k46)). Küçük duraktır, XP vermez. Burada yakılan ateş taşlıdır (+%50 yanma). Çukuru kalıcıdır: 24 saat kuralı ve zonun 6 ateş sınırı ona işlemez. İlk yakış 1 odun ya da 2 tezek ister, kav istemez.
- **Atlas.** Atlas bacağında inilmez. Çadır taşıyanın iki yol olayı değişir: «Kazın» bedeli +1 gün ve −2 yerine −1 yiyecektir; «Sığın» bedelsizdir (+0,5 gün kalkar). Çadır taşıyan, Heybe'sinde ya da terkisinde 2 dal, 1 sırık, 1 ip ve 2 keçe bulunandır ([Yolculuk](/docs/world/travel)).

## Birlik ve yoldaşlar yanındayken

Gecelik Çadır tek kişiliktir. Yanında onluk ya da yoldaş varsa kamp küçük bir sefer ordugâhı olur ([K88](/docs/source/design/decisions#k88)).

| Yanındaki | Kim kurar | Ne kurulur | Süre | Uyku Zarı |
|---|---|---|---|---|
| Kimse | Mete | Gecelik Çadır | 108 sn, iki elle 81 sn | Gecede en çok bir |
| Onluk (birlik) | Onluğun erleri | 2 beş kişilik çadır; Çadır Yükü arabada | Çadır başına 4 elle ≈3,8 gerçek dk | Yok: sefer ordugâhı güvenlidir |
| Yoldaş partisi | Yoldaşlar; Mete kendi Gecelik Çadır'ını kurar | Beş kişiye bir beş kişilik çadır: 1–4 yoldaşa 1, 5–10 yoldaşa 2 | Mete'nin süresine eklenmez | Yok, düşman zonunda da |

- Parti Mete'nin onluğudur ([K70](/docs/source/design/decisions#k70)). Yoldaşlar nöbeti sırayla tutar: yer sefer ordugâhı gibi güvenlidir, düşman zonunda ateşi söndürmek gerekmez. Ağır Yaralı yoldaş çadırda yatar, nöbete girmez; partide yalnız savaşmayan yoldaş ([Dangyu](/encyclopedia/dangyu), [Zhang Sheng](/encyclopedia/zhang-sheng)) varsa da nöbet tutulur.
- Çadır Yükü arabasızken yoldaşların terkisindedir (16 Yük; Hun Atı'nın terkisi 40). Sabah Topla'da yoldaşların çadırı onlarla toplanır (kurmanın 0,35'i).
- Mete Dinlen'e geçince yoldaşlar ateşin 3–5 m'lik halkasına oturur, en çok 10 yer; onluğun morali dakikada +1 artar; gecede en çok bir kamp sahnesi gelir. Mete uyuyunca yoldaşlar da uyur: ≥4 oyun saati süren uyku yoldaşın yaralarını kapatır, Ağır Yaralı'yı bitirir ([Yoldaşlar](/docs/gameplay/companions)).
- Gerekçe: birlik yanındayken onluk 2 çadır kurar ve parti Mete'nin onluğudur; nöbetçi olan yerde zarın gerekçesi kalkar. Çadırı kişi başına kurmak terkide on çadır taşıtırdı.

## Bir gece, hesap

II. Perde'den sonra Serbest Dolaşım'da, 15 Temmuz MÖ 209, enlem 43,5° (doğuş 04:26, batış 19:34), Normal, tek başına, boş arazi:

| Saat | İş | Gerçek süre |
|---|---|---|
| 18:40 | Akşam evresi. Ateş: 4 tezek, reçine, çakmak taşı (720 sn) | 5 sn |
| 18:42–19:25 | Gecelik Çadır, ateş ışığında (×1) | 108 sn (`T` ile 2,3 sn) |
| 19:25 | Şiş Et | 12 sn |
| 19:30 | `Y` ile 1 tezek: 600 sn'lik ateş 720'ye dolar (60 sn sığmaz). Uyu, «Güneşle uyan» | ≈4 sn |
| 00:18 | Ateş söner; çukur çadırla kalır | |
| 04:56 | Uyanış: 9 sa 26 dk geçti; uykuda ateşli saat 4 sa 48 dk, zar %4,9; Tokluk −11,8; yaralar kapanır; oto kayıt | |
| 04:56–05:11 | Topla | 38 sn |

Toplam ≈2 dk 47 sn gerçek süre (`T` ile ≈25 sn). Bedel: 1 ip, 2 dal, 5 tezek, 1 reçine, 1 et. Aynı gece düşman zonunda olsaydı ateş Şiş Et'ten sonra söndürülürdü ya da Kor'a inince küllenirdi: uykuda ateşli saat 0, zar %0; sabah çukur ya da köz kavsız yanar.

**Kayıt.** Zon başına en çok 2 çadır kaydedilir; bırakılan çadır 10 gün sonra silinir; bir gecede ikinci zar atılmaz. Yanan ateş, küllenen köz ve çukur zon başına en çok 6'dır.

> [!DURUM]
> Oyunda yok. Godot'da yalnız ana kampın sahne ateşi var: taş halka ve odunlar Meshy modelidir, alev, kıvılcım ve ışık koddan gelir; saat yoktur, gece sabittir ([d3/oyun-durumu.md](/docs/source/design/d3/game-state)). Oyuncu ateşi ve `Y`, Gecelik Çadır, döşek, Bekle tekeri ve Uyu, Uyku Zarı, şantiye ve sabah Topla yazılmadı. Prototipte denendi: beş kişilik çadırın yapı tanımı, Çadır Yükü kimliği ve el tarifi, saatin uyku kapısı; Godot'a taşınmadı.

## Yol haritası

Gecelik Kamp, Uyku Zarı ve çadır sökümü II'nin yerleşim fazındadır (`overnight-camp`). Ateş, Bekle ve Uyu I. Perde'nin oyuncu ve dünya çekirdeğindedir: [ateş ve av](/roadmap#item-fire-hunting), [Bekle ve Uyu](/roadmap#item-wait-sleep).

```ilerleme
act-2-p2
```

## Kaynaklar

- [survival.md §7](/docs/source/design/survival#7-gecelik-kamp-overnight-camp-k46): [§7.1](/docs/source/design/survival#7-1-ne-zaman-nerede), [§7.2](/docs/source/design/survival#7-2-malzeme-ve-yuk), [§7.3](/docs/source/design/survival#7-3-kurma), [§7.4](/docs/source/design/survival#7-4-gece-uyu), [§7.5](/docs/source/design/survival#7-5-acikta-uyku-uyku-zari-26), [§7.6](/docs/source/design/survival#7-6-sabah-topla-ya-da-birak-24), [§7.7](/docs/source/design/survival#7-7-hava), [§7.8](/docs/source/design/survival#7-8-eski-ocak-atlas-birlik), [§7.9](/docs/source/design/survival#7-9-bir-gece-hesap); ateş ve çukur [§2.3](/docs/source/design/survival#2-3-yakit-ekleme-23), [§2.4](/docs/source/design/survival#2-4-sonme-ve-cukur-25)
- [time.md §7.1](/docs/source/design/time#7-1-tus-yer-sure), [§7.3](/docs/source/design/time#7-3-kesintiler); [economy.md §2.11](/docs/source/design/economy#2-11-ucuncu-turun-kimlikleri-k46-k48-k49-k51-k58-k65), [§3.13](/docs/source/design/economy#3-13-sokum-ve-kurtarma), [§6.14](/docs/source/design/economy#6-14-gecelik-kamp-overnight-camp-k46), [§4.1](/docs/source/design/economy#4-1-kapasite-ve-hiz)
- [structures.md §2.4](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21), [§2.5](/docs/source/design/structures#2-5-santiye-building-site-k21-k23), [§4.5](/docs/source/design/structures#4-5-kisa-liste), [§6.5](/docs/source/design/structures#6-5-hava-ve-yildirim); [weather.md §8.5](/docs/source/design/weather#8-5-kamp-atesi-pisirme-kurutma), [§8.6](/docs/source/design/weather#8-6-yapilar); [travel.md §9.4](/docs/source/design/travel#9-4-atlas-yolculugu-akisi), [§9.6](/docs/source/design/travel#9-6-yol-olaylari-ii-perde-ve-sonrasi)
- [companions.md §5.5](/docs/source/design/companions#5-5-binme-kapi-ates); [army.md §3.6](/docs/source/design/army#3-6-erzak), [§3.7](/docs/source/design/army#3-7-ordugah-the-army-camp-k23); [progression.md §3](/docs/source/design/progression#3-yara-ve-dusus), [§8.5](/docs/source/design/progression#8-5-dusus), [§12](/docs/source/design/progression#12-zorluk)
- [decisions.md](/docs/source/design/decisions): [K1](/docs/source/design/decisions#k1), [K20](/docs/source/design/decisions#k20), [K22](/docs/source/design/decisions#k22), [K24](/docs/source/design/decisions#k24), [K45](/docs/source/design/decisions#k45), [K46](/docs/source/design/decisions#k46), [K50](/docs/source/design/decisions#k50), [K70](/docs/source/design/decisions#k70), [K88](/docs/source/design/decisions#k88)
- [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting), [Dövüş](/docs/gameplay/combat), [Yoldaşlar](/docs/gameplay/companions), [Ordu](/docs/gameplay/army), [Yolculuk](/docs/world/travel), [Hava](/docs/world/weather), [İnşa ve Emek](/docs/buildings/construction-labour), [Yurtlar ve Çadırlar](/docs/buildings/yurts), [Envanter ve Yük](/docs/economy/inventory-load)
