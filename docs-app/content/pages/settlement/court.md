---
title: Hanlık Merkezi
order: 50
status: tasarim
summary: 'III. Perde''den Mete Tanhu''dur ve yerleşim avluya döner; Divan, toplantılar, Dailin Sayımı, Gök Direği ve Hazine burada işler, akın yalnız dolunayda ve tek kuralla gelir, perde arası yılları Akan Kronik geçirir.'
sources:
  - docs/design/decisions.md
  - docs/design/settlement.md
  - docs/design/story.md
  - docs/design/army.md
  - docs/design/economy.md
  - docs/design/time.md
  - docs/design/d2/core.md
  - docs/research/bozkir-ekonomi.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

III. Perde'den Mete Tanhu'dur ve yerleşim yönetilen bir yere döner. Oyuncu Tanhu Otağı'nda Divan kurar: hane dileklerini dinler, dava görür, baş atar, armağan gönderir. Beyler toplantıya gelir, Dailin'de insan ve hayvan sayılır. Dolunay gecelerinde küçük akıncı bölükleri ambarı yoklar. Perdeler arasındaki yılları Akan Kronik geçirir.

> [!NOT]
> «Yerleşim yeri sistemimiz olacak, obamızı büyütüp kağanlığımızın hanlığımızın merkezi haline getirebileceğiz»

Tasarım aynı yöndedir ([K23](/docs/source/design/decisions#k23)). Oyuncuya Tanhu, Hun Tanhuluğu ve Tanhu Avlusu denir; kağan ve hanlık oyuncu metninde geçmez ([K34](/docs/source/design/decisions#k34)).

## Avlunun yapıları

Avlu işlevleri III. Perde'de ve Tanhu Otağı ayaktaysa açılır: II. Perde sonunda Mete kendini Tanhu ilan eder (冒頓自立爲單于, Shiji 110).

| Yapı | Kademe | İşlev |
|---|---|---|
| Tanhu Otağı | Boy Yurdu | Divan; toplantıların başı. Kapı doğuya bakar: Tanhu sabah doğan güneşe eğilir (單于朝出營，拜日之始生). Gündüz Divan Düzeni: oturak kuzeye bakar, kamera yalnız bu odada güneye döner; «Toy Ver» gecesi Şölen Düzeni ([K51](/docs/source/design/decisions#k51)) |
| Elçi Yurdu | Boy Yurdu | Elçi heyeti Konuk Düzeni'nde konaklar: [Tunghu](/encyclopedia/donghu)'nun üç isteği (III), Han elçileri (V), heqin |
| Toy Alanı | Boy Yurdu | Toy, Avlu Toplantısı, Dailin Sayımı'nın oturağı, Kurultay (VI); 120 oturak |
| Gök Direği | Boy Yurdu, yalnız Kutlu Tepe | Şafak Selamı, alamet |
| Bey Otağları | Toy Yeri | Beylerin büyük yurtları, zonda en çok 3; Divan yine Tanhu Otağı'ndadır |
| Hazine | Toy Yeri | Armağan, ganimet payı, Kurultay dağıtımı |
| Sancak Direkleri | Ocak'tan | Toplantıda beylerin yeri: 24 tümen sancağı |

```varlik
otag_hun, layout_otag, layout_han, envoy_yurt, beg_otag, dais, tug, wanqi_banner
```

## Divan

Tanhu Otağı'nda `E`, yalnız III. Perde'den. II'de Divan yoktur: ilk yargı ateş başında görülür (İlk Yargı yan görevi).

| Eylem | Ne yapar |
|---|---|
| Huzur / Audience | Hanelerin dilekleri: küçük işler (2 keçe, bir kuyu, bir hekim). Yapılınca o hanenin Gönül'ü +3, Kut vermez |
| Yargı / Judgement | 15 günde bir dava. Hırsızlık: «Malını al» (hanenin sürüsü Hazine'ye, Korku +1, o hane Gönül −10), «Kefaret» (çalınan iki katıyla ya da kabukla ödenir; [K48](/docs/source/design/decisions#k48)), «Bağışla» (öteki haneler Gönül −1), «Sür» (hane gider). Bıçak çeken: «Kanun» (sahne dışı, Korku +1) ya da «Kefil» (I. Perde'nin kefil motifi; hane Gönül +5, Kut değişmez) |
| Atama / Appoint | Birliklere baş atar |
| Armağan Gönder / Send Gifts | Hazine'den ≥200 Kıymet (İpek Top burada ×1,5 sayılır, K49); 3 gün sonra 2–4 hane gelir, o soyun beyiyle bağ kurulur |
| Kamın Alameti / The Kam's Omen | Perde başına 1: kam alamet okur; «Dinle» ya da «Sustur» ([K35](/docs/source/design/decisions#k35)). Kut ≥10'da Mete'nin unvanı Divan'da «Göğün diktiği» olur, kam Gök'e Tanhu'dan yakın konuşamaz |
| Elçi Kabulü / Receive Envoy | Elçi Yurdu'ndaki heyet: hikâye olayı ya da yol olayı |
| Ere Çağır / Call to Arms | Seferberlik: [Haneler ve Kâhya](/docs/settlement/households#seferberlik) |
| Toy Ver / Hold a Feast | Hane başına 2 öğün ve 1 kımız; Gönül +6, 10 günde bir; hane başına 1 kabuk saçıyla +8 |
| Avlu yolu | V. Perde'de bir kez: [Surlu ya da Göçer](/docs/settlement/encampment#surlu-ya-da-gocer-avlu) |

Dava kuralı Shiji 110'dan gelir: bir karış bıçak çeken ölür, hırsızın hanesine el konur (其法，拔刃尺者死，坐盜者沒入其家; [K33](/docs/source/design/decisions#k33)). Ceza sahnesi görünmez, sonrası görünür.

## Toplantılar

Shiji 110 üç toplantı yazar: yıl başı avluda küçük toplantı, 5. ayda Lung-çeng'de büyük toplantı, güzün at semizken Dailin'de sayım (歳正月，諸長小會單于庭 · 五月，大會蘢城 · 秋，馬肥，大會蹛林，課校人畜計). Günler ay takviminden gelir: [Lung-çeng](/encyclopedia/longcheng) 5. ayın, [Dailin](/encyclopedia/dailin) 8. ayın dolunayıdır ([K56](/docs/source/design/decisions#k56)). Kış Toplantısı oynanan günde sahne açmaz, Kronik onu perde arasında işler ([K42](/docs/source/design/decisions#k42)); oynanan karşılığı takvimsiz Avlu Toplantısı'dır.

| Toplantı | Ne zaman | Yer | Gerekir | Etkisi |
|---|---|---|---|---|
| Kış Toplantısı / Winter Muster | 1. ayın yeni ayı (≈Şubat) | Perde dışı, Kronik | | Atama ve hane özet satırıyla |
| Avlu Toplantısı / Court Gathering | Takvimsiz; zaferden sonra perde başına bir, Divan'dan | III'te Otağ önü, IV'ten Toy Alanı | 3 gün hane başına 2 öğün, bey başına 3 öğün, 20 kımız | Gönül +5; atama; Çekim ×1,2, 10 gün; V'te Baideng'den sonra 8–12 hane |
| Lung-çeng Toplantısı / Longcheng Muster | 5. ayın dolunayı: IV'te 25 Haziran 203, VI'da 2 Haziran 198 ve 4 Haziran 176 | Lung-çeng, ayrı iç harita | Armağan kervanı: ≥200 öğün, 10 at, Hazine'den ≥200 Kıymet | Gönül +3; katılan başa sadakat +5; IV ve VI'da Beşinci Ay Sunusu |
| Dailin Sayımı / Dailin Count | 8. ayın dolunayı: yerleşimde III'te 16 Eylül 208 ve VI'da 9 Eylül 174 | Avlunun güz otlağı | Toy Alanı; Mete avluda | Sayım Çetelesi: hane, kişi, sürü, at; seferberlik payı; ordunun yeniden sayımı; Söğüt Turu |

Oynanan günler (`story.md` §2 ve §14.3):

| Gün | Gün sayacı | Ne olur | Yer |
|---|---|---|---|
| 16 Eylül MÖ 208 | 1.694 | III'ün doruğu: Dailin Sayımı; Tunghu'nun üçüncü isteği, «Toprak devletin temelidir», seferberlik | Yerleşim, Dailin otlağı |
| 17 Haziran MÖ 205 | 2.698 | Lung-çeng günü, ama Mete Hexi'dedir: [Yüeçi](/encyclopedia/yuezhi) batıya sürülür, Beşinci Ay Sunusu Gök Dağı eteğinde yapılır; Lung-çeng'de toplantı yoktur | Hexi |
| 25 Haziran MÖ 203 | 3.436 | Lung-çeng'de büyük toplantı ve armağan kervanı; [Loufan](/encyclopedia/loufan) ve [Baiyang](/encyclopedia/baiyang) katılır | Lung-çeng |
| 22 Eylül MÖ 203 | 3.525 | IV'ün son görevi: Ordos'ta, Mete'nin doğduğu otlakta, babasının Dailin yerinde bir kezlik sayım; yerleşimin sayımı değildir | Ordos |
| 2 Haziran MÖ 198 | 5.238 | VI'nın Lung-çeng Toplantısı | Lung-çeng |
| 4 Haziran MÖ 176 | 13.270 | Lung-çeng'de 176 mektubu ve [Kunmo](/encyclopedia/kunmo) | Lung-çeng |
| 9 Eylül MÖ 174 | 14.097 | Son Dailin Sayımı: Mete sayım sürerken ölür | Yerleşim, Dailin otlağı |

Dailin böylece üç kez oynanır: yerleşimde iki kez, IV'te Ordos'ta bir kez. «III'te sayım olmasın» önerisi K56 ile kalktı: III'ün sayımı perdenin doruğudur. Öteki yılların Lung-çeng'i ve Dailin'i Kronik satırıdır: ilk Lung-çeng 30 Haziran 209, ilk Dailin 27 Eylül 209 (Mete'nin Tanhu olarak ilk sayımı); doğum, beş, on bir, on beş ve on yedi yaş ile rehin kararı da Dailin'e düşer. Toplantı günü akın yazılmaz ([K55](/docs/source/design/decisions#k55)): 16 Eylül 208, 17 Haziran 205 ve 25 Haziran 203'te akın pencerenin öteki gecesine düşer; VI akınsızdır, Ordos'un Dailin'i akın penceresinin dışındadır. III ve IV'ün sayım günlerinde hava açıktır, VI'nın son sayımının da kendi hava kilidi vardır.

**Söğüt Turu** (K56). Sayımın başında Dailin otlağına söğüt dalı dikilir, atlılar üç tur atar (yarıçap ≈27 m, ≈510 m; dörtnal 8,58 m/sn ile ≈60 sn); bitiren her başın sadakati +1; kazanan yoktur. Üç tur Xianbei kaydıdır, Hun için çıkarımdır; Destan bunu yazar.

**Sayım Çetelesi / The Count Tally** ([K62](/docs/source/design/decisions#k62)). Hikâyede sayım çentikle yürür, çeteleyi Töreci [Tuçi](/encyclopedia/tuchi) tutar. Mete: «Hun yazmaz, çentikler.» Kart: «Sayımın {n}. günü. {h} hane, {p} can, {s} sürü.» / «Day {n} of the count. {h} households, {p} souls, {s} head of stock.» {n} oyunun başındaki rehine gününden süren gün sayacıdır: I. Perde'de [Palak](/encyclopedia/palak)'ın saydığı «bin kırk birinci gün»ün devamı; bu kez sayan Mete'dir. Dailin'in yeri bilinmez, avlunun güz otlağı tasarım tercihidir. Lung-çeng ayrı bir iç haritadır, yerleşim oraya kurulmaz.

Toplantıya gelen kendi 3 günlük azığını ve çadırını getirir.

```varlik
ui_tally_card, gathering_ground
```

**Kurultay** (VI): Toy Alanı'nda, VI'nın başında (3–4 Haziran 198). Hazine dağıtılır, dağıtımın kendisi oy toplar; Kut ≥20 +1 oy. [Jiyu](/encyclopedia/jiyu) Sol Bilge Kral, yani veliaht olur. Kurultay bir dağıtımdır, son karar değildir: Hazine'nin dağıtılan payı ve hanelerin ortalama Gönül'ü son karta girdi verir. VI'da at ve deve yarışı mevsimde bir kez Gönül +1 verir (K65).

## Gök Direği

Kutlu Tepe'de tek yeri vardır: taş halka, 12 m direk, keçe flama. Biçimi tasarım tercihidir, Hun sunak biçimi kaynakta yoktur.

- **Şafak Selamı.** Tan evresinde direkte `E`: «Güne Selam / Greet the Sun». Avludaki birlik moral +2, avlu haneleri Gönül +0,5, günde bir. Kut vermez. Akşamı aya selam yoktur: tek eylemdir.
- **Alamet.** Fırtınada direk zonun en uzun yalnız şeyidir. Yıldırım buraya inerse perde başına bir kez: Kut ≥ Korku ise «Gök gördü», Kut +1; değilse «Gök kızdı», Korku +1. Flama kuruysa direk tutuşur ve yeniden dikilir; ıslak fırtınada kara iz kalır. Mete'nin ocağının ozanı alameti bir satırla söyler: II–III'te [Teoman](/encyclopedia/teoman)'ın ozanı, IV–VI'da Çocuk ([K79](/docs/source/design/decisions#k79)).
- **Beşinci Ay Sunusu** (K35; yalnız IV ve VI, perde başına 1): 5. ayın dolunayında, IV'te Gök Dağı eteğinde, VI'da Lung-çeng'de ve Gök Direği'nde. Sürüden 1 at ve 2 kımız; et Toy'a gider. Avlu haneleri Gönül +3, birlik moral +5 (bir gün), Kut +1.
- **Kül Ödemesi** (K35). [Erlik](/encyclopedia/erlik)'in borcu küle bağlandıysa yerleşimde yanan her 5 yeni hane ocağı Erlik'in saydığı sönmüş ocakları 1 azaltır, perde başına en çok 2; bu sayı VI'daki Kıl Köprü'nün enini belirler. Sonsöz'ün Son Sayım kartı onu okur: «Erlik {o} ocak sayar.» / «Erlik counts {o} hearths.»
- Gök Direği yurtları korumaz. Konut halkasında yıldırımı Sancak Direği (10 m) çeker.

## Hazine

Toy Yeri'nde açılır, 120 Yük, yalnız değerli mal ve kabuk. Mal Kıymet'le sayılır; Defter'de terazi ve yanında «≈{n} kabuk» görünür (K48). Kıymet sözü oyuncuya çıkmaz.

- **Girer:** heqin malı (ipek, şarap, tahıl), ganimetin Tanhu payı, takas kârı, Yargı'nın el koyması ve kefareti, kabuk.
- **Çıkar:** Armağan, ganimetin halka payı, Lung-çeng kervanı, Kurultay dağıtımı, Toy'da saçı (hane başına 1 kabuk).
- Akında ilk hedeftir: kayıp %30, kabuk dahil; Gözcü Kulesi 30 m içindeyse ×0,5. Mete'nin kesesi Hazine değildir, akında güvendedir.
- Hiçbir kademe kapısı kabuk istemez, Kâhya kabuk harcamaz, Kronik kabuğa dokunmaz.

```varlik
treasury, cowrie
```

## Baskın ve savunma

Akın küçük, seyrek ve kolay def edilir ([K55](/docs/source/design/decisions#k55)): ordugâh için verdiğin ölçü (#43) yerleşimin akınına da uygulanır; cevabın [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans#gece-akini) sayfasındadır. **Ne zaman:** akın yalnız ay penceresinde gelir: ay ≥%97 dolu, ayda ≈3 gece (Shiji 110: 月盛壯則攻戰). Eski «8, 14, 12 günde bir» sıklığı kalktı: perde sayacı olmadığı için gün aralığı süresiz akın üretirdi. Toplantı günü akın yazılmaz. Kronik akın işlemez. Sonuç kaydın tohumundan çıkar: rastgele çekiliş yoktur, aynı kayıt aynı akını verir.

| Perde | Akıncı | Güç R: yerleşim / ordugâh | Biter ya da düşer | Pencere (oynanan takvim) | Yerleşime tavan |
|---|---|---|---|---|---|
| II | Yok (Teoman'ın barışı) | 0 / 0 | | 1–2 Haziran 209 ay doludur, akın yok | 0 |
| III | Tunghu atlıları | 6 / 4 | Tunghu Yurdu kazanılınca (26 Eylül 208) 0 | 15–17 Eylül 208 (16'sı Dailin) | 2 |
| IV | Yüeçi; Loufan, Baiyang | 10 / 6 | Yüeçi sürülünce (17 Haziran 205) 6 / 4; Loufan ve Baiyang katılınca (25 Haziran 203) 0 | 16–18 Haziran 205 (17'si Lung-çeng); 24–26 Haziran 203 (25'i Lung-çeng) | 2 |
| V | Han sınır birliği | 16 / yok (ordugâh kışın dağınık) | Baideng'den sonra 8 | 27–29 Kasım 201 kuşatmaya düşer, akın yazılmaz; perde bittikten sonra Serbest Dolaşım'da 27–29 Aralık 201 | 1 |
| VI | Yok (heqin) | 0 / 0 | 177 sınırı hikâye sahnesidir | | 0 |

IV'ün sırası K33'ün takvimindendir: önce Yüeçi sürülür, sonra Loufan ve Baiyang katılır. Oynanan takvimle beklenen akın: III 1, IV 1–2, V 0. IV'ün akın geceleri 16 Haziran 205 (R 10), 18 Haziran 205 ve 24 Haziran 203'tür (R 6); 26 Haziran 203'te R 0'dır. V'in tavanı perde bittikten sonra Serbest Dolaşım'da işler. Serbest Dolaşım bitmiş perdenin R'sini ve tavanını taşır.

Akının tek kuralı K24'ündür; başka hesap yoktur:

```
D = nöbetçi × (1 + 0,5 × kule) + garnizon
başarı = R / (R + D), Surlu Avlu'da × 0,5
hedef: pencerede D'si küçük yer (yerleşim ya da ana ordugâh); eşitse yerleşim
```

- **Nöbetçi:** barışta 8, savaş mevsiminde (III–V) 4 hanede 1 yetişkin. Nöbete görevlendirilen savaşan yoldaş 3 nöbetçi sayılır: III'te yerleşimin savunması 26,0'dan 29,0'a çıkar, başarı %18,8'den %17,1'e iner (kulesiz).
- **Garnizon:** o an zonda bulunan İş Kolu erleri (kademe başına 5 / 15 / 20 / 30 / 50) ve Mete zondaysa birliğinin gücü. Partideki yoldaş garnizonun içindedir.

Başarılı akında kap başına kayıp:

| Kap | Kayıp |
|---|---|
| Ambar Yurdu, Tahıl Ambarı, Sundurma | %30 |
| Tahıl Kulesi | %10 |
| Ambar Çukuru | %50 olasılıkla bulunur, bulunursa %30; yalnız yiyecek ve tahıl alır |
| Hazine | %30, kabuk dahil; 30 m içinde Gözcü Kulesi varsa ×0,5 |
| Ot sundurması | Tutuşursa hepsi |
| Sürü | En çok %10; Göçer Avlu'da ×0,6 |
| Surlu tarlası | Haziran–Eylül arası başarılı akın güz ürününün %30'unu çiğner ([K54](/docs/source/design/decisions#k54)) |

Ambarcı kap kaybını ×0,75 yapar, başarıya dokunmaz; Hazine, ot sundurması yangını ve sürü kaybı bunun dışındadır. Ambarcı [Tola](/encyclopedia/tola) yaşıyorsa Tola, değilse [Moyan](/encyclopedia/moyan)'dır. Çadır ve sundurma tutuşabilir. Mete zondaysa akın oynanır, değilse toplu çözülür ve kart gelir. Def edilen akında haneler Gönül +1 alır; düşen akıncılar düşman türünün ganimet tablosundan ×0,6 verir, küçük akında «Paylaş» sayılır, karar sorulmaz (K49). Başarılı akında zarar gören hane 6 Gönül yitirir.

**Tek akının beklenen ambar kaybı** (başarı × %30 × 0,7):

| Perde | D | Başarı | Kayıp | Ambarcıyla | Garnizonsuz | Tavanla perde kaybı |
|---|---|---|---|---|---|---|
| III | 26,0 | %18,8 | %3,9 | %3,0 | %10,5 | %7,9 |
| IV | 50,9 | %16,4 | %3,4 | %2,6 | %6,8 | %6,9 |
| V Surlu | 112,5 | %6,2 | %1,3 | %1,0 | %2,1 | %1,3 |
| V Göçer | 104,7 | %13,3 | %2,8 | %2,1 | %4,8 | %2,8 |

K24'ün perde başına ambar kaybı ≤%10 hedefi tavanla ve Ambarcısız sınanır: hepsi tutar. IV'ün satırı iki akını da R 10 sayar; düzelen sırayla ikinci akın Yüeçi sürüldükten sonra R 6 ile gelir: tek akında %10,5 başarı, %2,2 kayıp (Ambarcıyla %1,7), tavanla perde kaybı en çok %5,7 (Ambarcıyla %4,2). Doğrulanacak: tablo `econ-sim`'in yeni akın sırasıyla koşusundan yeniden basılır ([Yol Haritası](/roadmap#item-econ-sim-run)). Garnizonsuz sütun (İş Kolu seferde, Mete uzakta) hedefe sayılmaz: yerleşimi boş bırakmanın bedelidir.

**Uyarı** üç kanaldan gelir: boru sesi, kısa bildirim, atlas işareti. Gözcü Konağı (400 m) ≈44 sn, Gözcü Kulesi (300 m) ≈33 sn, köpek ≈20 sn önce haber verir. Sis nöbet görüşünü ×0,5 yapar. Pencere açılırken Kâhya uyarır: «Ay doluyor. Atları içeri alın.» / «The moon is filling. Bring the horses in.» Pencere açıkken ve perdenin tavanı dolmamışken yeni hane çekimi yarıya iner.

**Neden küçük ve seyrek.** Hun akıncısı dolunayda çıkar, karşılık görünce kuş sürüsü gibi dağılır (如鳥之集), zayıf nöbeti kollar (卒少則入, Hanshu 49) ve yağmayı akıncıya bırakır. Akın mal için gelir, yerleşimi düşürmek için değil. Bir kampa kaç kez geldiği kaynakta yoktur: pencere ve tavan sayıları kurgudur ([bozkir-ekonomi.md](/docs/source/research/steppe-economy) §4). Ordugâhın Gece Akını aynı formülle at hattına gelir: [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans#gece-akini).

## Kronik

Perde son ana görevle biter, sayaç yoktur (K42). Son görev yalnız perdenin kolları bitince açılır. **Son Görev Kapısı** kartı: «Bu yol perdeyi kapatır. Sonra {y} yıl geçer.» / «This road closes the act. Then {y} years will pass.»; açık yan görevler listelenir; «Yola Çık» ya da «Daha Değil»; kartta saat durur. Açık yan görevin sonucu görev verisinde yazılıdır: sonraki perdede sürer, Kronik'te sonuç satırı olur ya da kapanır; sessiz düşüş yoktur.

Son görevden sonra Serbest Dolaşım açık kalır: Plan Kipi, Defter, Kâhya, kervan, av ve inşa sürer, takvim akar (1 oyun günü 60 gerçek dakika, [K67](/docs/source/design/decisions#k67)); akın penceresi ve Çekim bitmiş perdenin R'si ve tavanlarıyla işler. Oyuncu dilediğinde «Kronik'e bırak / Leave it to the Chronicle» der: perde kartında, duraklatma kitabında, Mete'nin her ocağında.

**Akan Kronik** kapalı hesabı oyuncuya gösterir: perde kartı → atlas dönem değişimi → gün sayacı ve tarih ay ay akar → mevsim nabzı → 2–5 ozan ya da anlatıcı satırı → hane ve sürü sayıları → yeni perde kartı. Süre mevsim başına 5 saniyedir, en az 30, en çok 90: II→III 30, III→IV 54, IV→V 89, V→VI 50 saniye; IV ve VI'nın iç atlamaları aynı formülle akar. Atlanabilir, `E` basılı tutulunca ×4 hızlanır. En çok 2 Kronik Kararı gelir: tek kart, iki seçenek, 10 saniye sonra Kâhya seçer, akış durmaz. Akış: [Perde Arası: Akan Kronik](/docs/story/chronicle).

Kapalı hesabın adımları:

1. Tarih perdenin başına atlar (II 1 Haziran 209, III 1 Eylül 208, IV 1 Haziran 205, V 20 Kasım 201, VI 1 Haziran 198); atlanan her gün takvime işlenir.
2. Aradaki her yıl: sürünün doğumu, soğumu ve kaybı (otlak kapasitesiyle sınırlı), bozulanın silinmesi, saklananın bir kış ve ambar kapasitesiyle sınırı, bakımın ödenmesi. III'ten Tunghu haracı yılda 20 ham deri getirir.
3. **Tarla** (K54): Surlu yolda ve en az bir tarla varsa yıl başına hasat işlenir; ambara yalnız son hasat yazılır, `min(500 × tarla, boş tahıl yeri)`; öncekiler yenmiş sayılır. Kronik'te hava ve akın yoktur.
4. Hane perdenin açılış tabanına çıkar (III 10, IV 22, V 45, VI 80); üstündeyse düşmez. Yeni haneler yükleriyle ve türlerinin paylarıyla gelir, Kâhya parsel verir. Aradaki Kış Toplantıları, Lung-çeng'ler ve Dailin'ler burada satır olarak işlenir (ilk Lung-çeng 30 Haziran 209, ilk Dailin 27 Eylül 209), atama ve hane özet satırıyla gelir.
5. Kış stoğu: kışla açılan V. Perde K24 hedefinin ortasına dek (%75–115 bandı) doldurulur, ambar ve sundurma kapasitesiyle sınırlı: kap kurmak kışı korur. Ordugâhın kış bekçisinin otu da kapasitesine dek.
6. Yoldaki kervan varmış sayılır. Şantiyeler emek yeterse biter, yoksa bırakılmış kalır.
7. Perde kartı: «{y} yıl geçti. {h} hane, {s} baş sürü; ambar kışa {p}.» / «{y} years have passed. {h} households, {s} head of stock; the stores stand at {p} for winter.» Surlu yolda ek satır: «Tarlalar {n} darı verdi.» / «The fields gave {n} measures of millet.»

Kronik kabuğa dokunmaz: Hazine'nin ve Mete'nin kesesindeki kabuk aynı kalır. Görevdeki yoldaş yerinde kalır, etkisi toplu hesaba girer. Perdenin içindeki yıl sıçramaları (IV, VI) aynı adımdır. Üç günden kısa atlama saat saat, uzunu günlük adımla işlenir.

## Oyunda şu an

> [!DURUM]
> Godot'da yok: avlu yapıları, Divan ve davalar, toplantılar, Dailin Sayımı ve Söğüt Turu, Gök Direği, Hazine, akın ve uyarısı, Kurultay, Son Görev Kapısı ve Akan Kronik. Godot'da saat ve takvim de yoktur: gece sabittir, ay evresi hesaplanmaz ([d3/game-state](/docs/source/design/d3/game-state)). Prototipte denendi (saf kod ve sınama, oyuna bağlanmadı): Kronik'in yıllık adımı (sürü, bozulan, bakım, ambar sınırı), ay ayı takvimi, Hazine kabı. Prototipte de yazılmadı: Kronik'in hane, tarla ve kış stoğu adımları, akın kuralı.

## Yol haritası

Divan, Boy Yurdu ve Dailin Sayımı III'ün «Boy Yurdu, Divan ve Dailin» fazındadır ([Divan](/roadmap#item-divan), [Dailin](/roadmap#item-dailin)); Hazine, toplantılar ve armağan IV'ün «Toy Yeri, Hazine ve toplantılar» fazındadır ([madde](/roadmap#item-court)). Akın ve Gece Akını III'ün ordu fazında ([madde](/roadmap#item-raids)), Kurultay VI'nın fazında ([madde](/roadmap#item-kurultay)), Akan Kronik I. Perde'nin son fazındadır ([madde](/roadmap#item-chronicle)).

```ilerleme
act-3-p2
act-4-p1
```

## Kaynaklar

- [decisions.md: K23, K33, K34, K35, K42, K48, K54, K55, K56, K62, K79](/docs/source/design/decisions#k56)
- [settlement.md §12: hanlık merkezi](/docs/source/design/settlement#12-hanlik-merkezi), [§12.2: toplantılar](/docs/source/design/settlement#12-2-toplantilar-s3), [§12.3: Divan](/docs/source/design/settlement#12-3-divan-council), [§12.4: Gök Direği](/docs/source/design/settlement#12-4-gok-diregi), [§12.5: Hazine](/docs/source/design/settlement#12-5-hazine)
- [settlement.md §15.4: akın](/docs/source/design/settlement#15-4-baskin), [§16.2: Kronik](/docs/source/design/settlement#16-2-perde-gecisi-kronik-k25)
- [story.md §2: zaman çizelgesi](/docs/source/design/story#2-zaman-cizelgesi-1), [§14.3: Dailin Sayımı](/docs/source/design/story#14-3-dailin-sayimi-44), [§13: Akan Kronik](/docs/source/design/story#13-perde-arasi-akan-kronik)
- [army.md §1.3: takvim](/docs/source/design/army#1-3-takvim), [§3.8: Gece Akını](/docs/source/design/army#3-8-gece-akini-night-raid-k55)
- [economy.md §9.6: kabuk](/docs/source/design/economy#9-6-kabuk-cowrie-k48), [§10.8: denge modeli](/docs/source/design/economy#10-8-denge-modeli)
- [d2/core.md §4.10: Kronik](/docs/source/design/d2/core#4-10-kronik-k25), [time.md §2: ay ayları ve toplantılar](/docs/source/design/time#2-takvim)
- [bozkir-ekonomi.md: akın önerileri](/docs/source/research/steppe-economy), [d3/game-state](/docs/source/design/d3/game-state)
