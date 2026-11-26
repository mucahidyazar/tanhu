---
title: 'VI. Perde: Sayım'
order: 55
status: tasarim
summary: "1 Haziran MÖ 198–9 Eylül MÖ 174, beş yıl dilimi: yay çeken bütün halkların Tanhu'su Mete Kurultay'ı toplar, Han'a mektup yazar, oğlunun bozduğu sınırı yargılar, bir Usun bebeğini sayıma alır ve son Dailin'de, Kıl Köprü'den tek başına geçtikten sonra, sayım sürerken ölür."
sources:
  - docs/design/story.md
  - docs/design/decisions.md
  - docs/design/companions.md
  - docs/design/settlement.md
  - docs/design/army.md
  - docs/design/progression.md
  - docs/design/fauna.md
  - docs/design/economy.md
  - docs/design/travel.md
  - docs/design/weather.md
  - docs/design/audio.md
  - docs/design/godot.md
  - docs/design/d3/oyun-durumu.md
  - docs/research/mete-tarih.md
  - docs/research/mitoloji.md
---

## Özet

VI. Perde «Sayım / The Count» 1 Haziran MÖ 198'den 9 Eylül MÖ 174'e, yirmi dört yıla yayılır (`dayN` 5.237–14.097). [Mete](/encyclopedia/mete) 35 yaşında başlar, 59 yaşında ölür. Perde beş yıl dilimidir, aralarında iç Kronik akar. Heqin barışı sürer; Mete yay çeken bütün halkların Tanhu'sudur (諸引弓之民，并爲一家). Sayı büyür, borç da: Han'a mektuplar, oğlunun bozduğu sınır, batıda Yüeçi, sayıma giren bir Usun çocuğu. Son Dailin'de Mete sayım sürerken ölür; perde kartı gelmez, Sonsöz başlar.

**Ad.** «Sayım» [K32](/docs/source/design/decisions#k32)'dir: I. Perde'de Palak rehineyi sayar, VI'da Mete halkını sayar.

**Boyut.** 14 ana görev (ortalama taban 177 XP, `xpScale` 5: 12.390 XP), 12 yan görev (4.110 XP), 8–12 XP'li keşif durağı, bir yeni iç harita (Hangay) ve iki seçmeli harita (Dingling Yurdu, Loulan); seviye 18–20 ve aşkın XP. Perdenin bütün XP'si 19.400'dür, seçmeli haritalar gezilmezse 19.000. Oynanan 15 gündür; K25'in 16 günü yalnız tasarım ölçüsüdür ([K42](/docs/source/design/decisions#k42), [K43](/docs/source/design/decisions#k43)).

> [!NOT]
> «Hikaye gerçek tarih zamanı içinde gerçek zamanlı akacak, tarih sürekli akacak»

Tasarım bu yöndedir ([K42](/docs/source/design/decisions#k42), [K67](/docs/source/design/decisions#k67)): takvim tek sayaçtır, 1 oyun günü 60 gerçek dakikadır. VI yirmi dört yılı beş dilimde oynatır; aradaki yıllar iç Kronik'le ay ay akar, tarihin olayları orada günüyle geçer. Sayaç yoktur; perde son göreviyle, Son Dailin'le kapanır.

## Perdenin sorusu

- **Soru.** Halkını sayan kime borçludur?
- **Fiil.** Saymak. Kollar yıl dilimlerine bağlıdır, sıra takvimindir.
- **Yankı.** Doğumda Hereka «Bir eklendi.» demişti; Mete bebek Kunmo'yu aynı sözle sayıma alır, babasının ona yaptığının tersini yapar. Son sayımda çeteleyi tutan «Bir eksildi.» der. Son şafak, doğduğu şafağın göğüdür: doğuda gün, batıda dolunay.

## Tarih ve takvim

| Dilim | Oynanan günler (MÖ) | `dayN` | Mete'nin yaşı | Ne olur |
|---|---|---|---|---|
| VI-a | 1–4 Haziran 198 | 5.237–5.240 | 35 | Dönüş, Lung-çeng (2 Haziran), Kurultay |
| VI-b | 12–13 Şubat 192 | 7.318–7.319 | 41 | Kâtip, Lü'ye mektup; Kış Toplantısı 14 Şubat'tır, oynanmaz |
| VI-c | 14–15 Temmuz ve 11 Ekim 177 | 12.945–12.946, 13.034 | 56, 57 | Yitu Ordos'a girer; Hüküm |
| VI-d | 3–5 Haziran 176 | 13.269–13.271 | 57 | Lung-çeng (4 Haziran): 176 mektubu, Kunmo; yirmi altı ülke |
| VI-e | 14 Şubat ve 8–9 Eylül 174 | 13.890, 14.096–14.097 | 59 | Wen'in cevabı; son söğüt, iki ışık, son Dailin |

- **Toplantılar ([K56](/docs/source/design/decisions#k56)).** [Lung-çeng](/encyclopedia/longcheng) iki kez oynanır: 2 Haziran 198 ve 4 Haziran 176. Yerleşimin [Dailin](/encyclopedia/dailin) Sayımı III'ten sonra ikinci ve son kez 9 Eylül 174'te oynanır.
- **Hava.** Lung-çeng günlerinde tören saati açıktır, törenden sonra gök gürültüsü serbesttir. Son sayım açık havadadır, rüzgâr ≤3 m/sn ([weather.md §6.4](/docs/source/design/weather#6-4-sonraki-perde-kancalari)).
- **Tarla ([K54](/docs/source/design/decisions#k54)).** Surlu yolda tarla takvimden görünür: 1 Haziran 198 yeşil, 13 Şubat 192 karlı ve boş, 4 Haziran 176 yeşil, 9 Eylül 174 sarı.

## Açılış

- **V → VI Kroniği.** 1 Aralık 201'den 1 Haziran 198'e 912 gün, 50 sn akar: Liu Jing zincirden çözülür; Han Xin'in komutanları Dai ve Yunzhong'a akar; 197 güzü Chen Xi ayaklanır; 6 Aralık 199'da heqin gelir: prenses, her yıl ipek, kumaş, şarap ve tahıl, iki hükümdar kardeş sayılır; barış kartı Beyaz At kalıbıyladır; Dulongçi ölür. Kronik Kararı Han Xin'in komutanlarının akın payıdır. Yerleşim 80 haneyle açılır ([V. Perde: Dört Renk](/docs/story/act-5)).
- **Dönüş.** Tanhu Avlusu V'te seçilen yolla, surlu ya da göçer durur. Han prensesinin yurdu kurulmuştur, Otağ'da ilk heqin ipeği vardır. [Yimo](/encyclopedia/yimo) Kâhya'dır; [Jiyu](/encyclopedia/jiyu) on beş, [Yitu](/encyclopedia/yitu) yedi yaşındadır.

## Ana görev zinciri

Kalıp 2 + 3 × 3 + 3'tür: iki açılış görevi, üç kol ve üç kapanış görevi. Kol A (Kâtip, 176 Mektubu) mektupların, Kol B (Irmağın Güneyi, Kunmo) Yitu'nun ve sınırın, Kol C (Kurultay, Yirmi Altı) dağıtımın ve ülkelerin koludur; kollar yıl dilimlerine bağlıdır, sıra takvimindir. Görev puanı veren tek görev Kurultay'dır.

| # | Görev | Dilim, gün | Yer | Ne olur |
|---|---|---|---|---|
| 1 | Dönüş / The Return | VI-a, 1 Haziran 198 | Tanhu Avlusu | Avlu, prensesin yurdu, heqin ipeği |
| 2 | Lung-çeng / Longcheng | VI-a, 2 Haziran 198 | Lung-çeng | Beşinci ayın dolunayı: yirmi dört başın sancakları ve kuzeyin beş halkının başları. Dingling ozanı uzun çekilen ezgiyi söyler (好引聲長歌，又似狼嘷): bir Hun Tanhu'su kızlarını göğe vermek ister, yaşlı bir kurt gelir (Wei Shu 103). Beşinci Ay Sunusu |
| 3 | Kurultay / The Kurultay (Kol C) | VI-a, 3–4 Haziran 198 | Toy Alanı | Hazine dağıtılır, dağıtımın kendisi oy toplar; Jiyu Sol Bilge Kral, yani veliaht olur (左屠耆王). Kurultay perdenin başındaki bir dağıtımdır, son karar değildir |
| 4 | Kâtip / The Scribe (Kol A) | VI-b, 12 Şubat 192 | Sığınanların yurtları | Hun yazmaz: Han kâtibi aranır; aday Zhang Sheng ya da Lu Wan'la gelenlerden biridir |
| 5 | Lü'ye Mektup / The Letter to Lü | VI-b, 13 Şubat 192 | Tanhu Otağı | Mete söyler, kâtip yazar (孤僨之君，生於沮澤之中，長於平野牛馬之域…願以所有，易其所無). Oyuncu ağzı seçer: alay (tarihin metni), övünç ya da yalın. Lü'nün öfkesi, Ji Bu'nun sözü ve yumuşak cevap tarihtir, Kronik'te gelir |
| 6 | Irmağın Güneyi / South of the River (Kol B) | VI-c, 14–15 Temmuz 177 | Ordos | Sağ Bilge Kral Yitu dolunayda Ordos'a girer, sınır halkını yağmalar (入居河南地，侵盜上郡葆塞蠻夷); Han [Guan Ying](/encyclopedia/guan-ying)'le 85.000 araba ve atlı yollar. Mete'nin haberci atlısı Yitu'ya yetişir; Yitu sınırdan çıkar |
| 7 | Hüküm / The Sentence | VI-c, 11 Ekim 177 | Tanhu Otağı | Yitu'yu kışkırtan Houyilu beyi [Nan](/encyclopedia/nan) izlenir (takip, ≤8 nöbetçi, [K44](/docs/source/design/decisions#k44)). Yitu'nun cezası tarihtir: batıya, Yüeçi'ye (罰右賢王，使之西求月氏擊之). Nan'ın yazgısı oyuncunundur: Kanun, Kefil ya da Sür |
| 8 | 176 Mektubu / The Letter of 176 (Kol A) | VI-d, 4 Haziran 176 | Lung-çeng | «Göğün diktiği Hun Büyük Tanhu'su» (天所立匈奴大單于). Okunacak cümle seçilir: «Yay çeken halklar tek aile oldu.» / «All who draw the bow have become one family.», «Askeri dinlendirelim, atları besleyelim.» / «Let us rest the soldiers and feed the horses.» ya da «Gençler büyüsün, yaşlılar yerinde dursun.» / «Let the young grow up and the old rest where they are.» Armağan 1 deve, 2 binek, 8 koşum atı; elçi [Xi Huqian](/encyclopedia/xi-huqian) |
| 9 | Kunmo / Kunmo (Kol B) | VI-d, 4 Haziran 176 | Lung-çeng | Yitu batıdan döner; bir Usun bebeği getirilir: karga et getirmiş, kurt emzirmiştir (烏嗛肉蜚其上，狼往乳之). Mete bebeği sayıma alır: «Bir eklendi.» / «One more.» Kut +1, seçim yoktur |
| 10 | Yirmi Altı / The Twenty-Six (Kol C) | VI-d, 5 Haziran 176 | Elçi Yurdu | [Loulan](/encyclopedia/loulan), [Usun](/encyclopedia/wusun), Hujie ve yanlarındaki yirmi altı ülkenin elçileri (定樓蘭、烏孫、呼揭及其旁二十六國，皆以爲匈奴); her ülke sayılır |
| 11 | Wen'in Cevabı / Wen's Reply | VI-e, 14 Şubat 174 | Tanhu Otağı | Han elçileri Yi ve Jian cevabı ve armağanı getirir: işlemeli giysiler, altın süslü kemer, ipek, kızıl ve yeşil kumaş. Elçi: «Sağ Bilge Kral'ın suçu aftan öncedir. Tanhu onu ağır cezalandırmasın.» / «The Right Wise King's offence came before the amnesty. Let the Tanhu not punish him harshly.» Han giysisi giyilir ya da dağıtılır |
| 12 | Son Söğüt / The Last Willow | VI-e, 8 Eylül 174 | Dailin yeri | Söğüt dikilir; Mete sayım çetelesini kime vereceğini seçer: Jiyu, Yimo ya da [Tuçi](/encyclopedia/tuchi) |
| 13 | İki Işık / Two Lights | VI-e, 9 Eylül 174, şafak | Gök Direği | Şafak Selamı: doğuda gün doğar, batıda dolunay batmamıştır. Doğduğu şafağın göğüdür |
| 14 | Son Dailin / The Last Count | VI-e, 9 Eylül 174 | Toy Alanı, Dailin yeri | Son görev |

## Son görev: Son Dailin ve Kıl Köprü

- **Sayım.** Sayım bir oynanış fiilidir: geçen her baş bir tıktır (`E`), sayı ekranda değil kulaktadır. Mete oturağındadır, kuzeye bakar (長左而北鄉). Partideki her yoldaş sayımdan bir baş olarak geçer.
- **Kıl Köprü.** Bir yerde tıklar seyrekleşir, rüzgâr kesilir: [Toybodım](/encyclopedia/toybodim) üstünde at kılından bir köprü, 24 m. Eni `max(0,4; 2,0 − 0,1 × sönmüş ocak)` m'dir: Kül Borcu yoksa 2,0 m, en dar 0,4 m ([K35](/docs/source/design/decisions#k35)). Köprüyü Mete yalnız geçer, bütün parti yasaktır. Düşen ölmez, ırmak geri getirir; ip ve kesme görüntüsü yoktur, dövüş yoktur.
- **Köprünün ucu.** Kül Borcu «kül» ise [Erlik](/encyclopedia/erlik) Mete'nin yüzüyle oturur: «Sen tuttun.» / «You kept it.»; borç açıksa yüzsüz bir karartıdır; borç yoksa kimse yoktur, ot vardır.
- **Son.** Köprü geçilince oturağa dönülür: Mete kıpırdamaz. Çeteleyi tutan bir çentik atar: «Bir eksildi.» / «One less.» Bu, Hereka'nın «Bir eklendi.»sinin aynasıdır. Kan, hastalık ve son söz yoktur (後頃之，冒頓死). Adak Aygırı verilmediyse son sayımda soyundan bir tay geçer: «Küllü boz, sırtında kara yol.» / «Ash-grey, a black stripe down its back.» Perde kartı gelmez, [Sonsöz: Kopuz Susar](/docs/story/epilogue) başlar.

## Yan görev aileleri

Dört aile etkindir: Hane, Töre, Elçi, Av. Yol ve Ordu aileleri dinlenir, çünkü heqin barışı sürer.

| Aile | Görevler |
|---|---|
| Hane | Prensesin Yurdu / The Princess's Yurt (heqin maiyeti); Lu Wan'ın Adamları / Lu Wan's Men (195'in sığınanları: parsel ve iş); Kurultay Haneleri / Kurultay Households (2–4) |
| Töre | Yargılar / Judgements (yıllar boyu Divan davaları); Dulongçi'nin Yoğu / Dulongçi's Funeral Feast (Yoğ Aşı); Direğe Yıldırım / Lightning on the Pole (Gök Direği alameti: Kut Korku'dan büyük ya da eşitse Kut +1 «Gök gördü», değilse Korku +1 «Gök kızdı») |
| Elçi | Elçinin Yolu / The Envoy's Road (Xi Huqian'ın kervanı); Usun / The Wusun (Kunmo'nun halkından kalanlar); Loulan / Loulan (seçmeli harita) |
| Av | Ak Maral / The White Maral (Hangay; ıduk); Samur / The Sable; At ve Deve Yarışı / The Horse and Camel Race (Gönül +1, mevsimde bir) |

## Seçimler ve sonuçları

| Seçim | Nerede | Seçenekler ve sonuç |
|---|---|---|
| Hazine'nin dağıtımı | Kurultay | Dağıtım oy toplar, Kut ≥20 bir oy ekler; dağıtılan pay ve hanelerin ortalama Gönül'ü son karta girer ([settlement.md §12.6](/docs/source/design/settlement#12-6-kurultay-vi-kancasi)) |
| Mektubun ağzı | Lü'ye Mektup | Alay, övünç ya da yalın |
| Nan'ın yazgısı | Hüküm | Kanun (Korku +1), Kefil ya da Sür |
| 176'nın cümlesi | 176 Mektubu | Üç cümleden biri |
| Han giysisi | Wen'in Cevabı | Giyilir ya da dağıtılır |
| Çeteleyi kim tutar | Son Söğüt | Jiyu, Yimo ya da Tuçi; Sonsöz «Çeteleyi {ad} tuttu.» yazar |
| Ak Maral | Av | Bırakmak Kut +1; vurmak Korku +1 ve «Yer küstü» |
| Kunmo | Kunmo | Seçim yoktur, Kut +1 |

**Önceki perdelerin okunuşu.** I'in Kül Borcu ve sönmüş ocakları köprünün enini yazar. Kül Ödemesi: Kül Borcu «kül» iken yerleşimde yanan her 5 yeni ocak bir sönmüş ocağı siler, perde başına en çok 2; II–VI boyunca en çok on ocak döner. IV'ün Aygır Antı tayı getirir. Antların toplamı Sonsöz'ün son kartında okunur.

## Yıl dilimleri ve iç Kronikler

Kronik Kararı yoktur. Süre `T = clamp(gün / 91,25 × 5 sn, 30, 90)` formülüdür; `E` basılı ×4, Esc atlar. Akan Kronik'te parti donar; tarihli kişisel adım Kronik'e düşer, son adım +2 yerine +1 verir.

| Geçiş | Gün, süre | Olaylar | Anlatıcının satırı |
|---|---|---|---|
| VI-a → VI-b | 4 Haziran 198 → 12 Şubat 192; ≈2.080 gün, 90 sn | 13 Mart 196 Han Xin ölür; 196'da Wang Huang'ı kendi adamları ödül için diri teslim eder; Zang Yan, Lu Wan'ın elçisi Zhang Sheng'e Hun yanını tutmasını, Chen Xi'nin savaşını uzatmasını söyler; 1 Haziran 195 Liu Bang ölür; 29 Haziran 195 Lu Wan binlerce adamıyla sığınır | «Liu Bang öldü. Lu Wan binlerce adamıyla sınırı geçti.» / «Liu Bang died. Lu Wan crossed the border with thousands of men.» |
| VI-b → VI-c | 14 Şubat 192 → 14 Temmuz 177; ≈5.265 gün, 90 sn | Lü'nün cevabı (年老氣衰，髮齒墮落), iki araba ve iki takım at; Mete'nin özrü ve at armağanı; 180 yazı Lü ölür, Wen tahta çıkar, heqin yenilenir; 186 kışı Dangyu ölür, ocağını ardılı Liuli yakar (Dangyu yoldaş olduysa); Jiyu ve Yitu büyür | «Lü öfkelendi, sonra yumuşak yazdı. Han'da yeni bir imparator barışı yeniledi.» / «Lü raged, then wrote softly. In Han, a new emperor renewed the peace.» |
| VI-c içi | 15 Temmuz → 11 Ekim 177; 88 gün, 30 sn | Han atlıları Gaonu'ya gelir; Wen Taiyuan'a gider, Jibei ayaklanınca döner | «Han'ın atlıları geldi, Sağ Bilge Kral sınırın ötesine çekildi.» / «The Han horsemen came, and the Right Wise King drew back beyond the border.» |
| VI-c → VI-d | 11 Ekim 177 → 3 Haziran 176; 235 gün, 30 sn | Sağ kanat batıdadır; Yüeçi yenilir; Loulan, Usun, Hujie | «Sağ kanat batıya yürüdü. Yüeçi yenildi, yirmi altı ülke Hun sayıldı.» / «The right wing rode west. The Yuezhi were beaten, and twenty-six states were counted as Hun.» |
| VI-d → VI-e | 5 Haziran 176 → 14 Şubat 174; 619 gün, 34 sn | 20 Temmuz 176 mektup sınırdaki Xinwang'a varır; Han tartışır, barışı seçer (和親甚便); Kunmo büyür | «Mektup sınıra vardı. Han barışı seçti.» / «The letter reached the border. Han chose peace.» |
| VI-e içi | 15 Şubat → 8 Eylül 174; 206 gün, 30 sn | Son yaz; atlar semizler; Surlu yolda darı sararır | «Son yaz uzun sürdü. Atlar semizledi.» / «The last summer was long. The horses grew fat.» |

## Açılan sistemler

| Sistem | VI'daki yüzü | Sayfa |
|---|---|---|
| Kurultay | Toy Alanı'nda, 3–4 Haziran 198: Hazine dağıtılır, dağıtım oy toplar, Jiyu veliaht olur | [Hanlık Merkezi](/docs/settlement/court) |
| Mektuplar | Hun yazmaz: Mete söyler, kâtip yazar; oyuncu ağzı ya da cümleyi seçer | [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests) |
| Tam avlu | 80 → ≤90 hane: Kurultay 2–4, heqin maiyeti 1–2, Çekim ≤10. Kurultay Toy Alanı'nda, Beşinci Ay Sunusu Lung-çeng'de ve Gök Direği'nde, Dailin avlunun güz otlağındadır | [Haneler ve Kâhya](/docs/settlement/households) |
| Ordu | Ordugâh Tümen'dir (600 yerleşik), 24 tümen sancağı; ıslığa bütün ordu uyar; törende kart ve kitle kademesi. Akın yoktur (heqin); 177 sınırı hikâye sahnesidir. Söğüt Turu T1 kümesiyle atılır ([K55](/docs/source/design/decisions#k55), [K56](/docs/source/design/decisions#k56)) | [Ordu](/docs/gameplay/army) |
| Ekonomi | Yönetim: dağıtım Kut terazisinde; heqin malı Hazine'de; sınır pazarı, Dingling satıcısı, samur; ilk tarla hasadı Kronik'te işlenir. Mektup armağanı 1 deve, 2 binek, 8 koşum atı: 3.864 Kıymet, 966 kabuk | [Para ve Satıcılar](/docs/economy/money-traders) |
| Hayvanlar | Samur, sığın, ren, yaban devesi; binek Cüti ve Batı Atı; at ve deve yarışı ([K65](/docs/source/design/decisions#k65)) | [Hayvanlar](/docs/world/animals) |
| Kıl Köprü | Tek sahnelik geçiş; eni sönmüş ocaktan; düşen ölmez | [Mitoloji](/docs/story/mythology) |
| Beceriler | Tek yeni beceri Tümen Çağrısı; stat tavanı 12; birikimli beceri puanı 30. L20'den sonra her 1.800 XP +1 beceri puanı, en çok 3 | [Seviye ve Gelişim](/docs/gameplay/progression) |

```varlik
hair_bridge, han_robe, wanqi_banner, sky_pole, ui_tally_card, silk_bolt, wine_jar, fur_sable
sable, moose, reindeer, wild_camel, jueti, west_steed, skill_tumen_call
crowd_usun_man, crowd_usun_woman, crowd_dingling_man, crowd_dingling_woman, yurt_usun, otag_usun, yurt_dingling
```

## Yoldaşlar

Açık çekirdek dilime göre 3–9, konuk 0–2'dir. Perde ayrılıkların perdesidir: son sayıma az yoldaş kalır. Ayrılan yoldaş halkının yerine gider, her ayrılık bir sahnedir ([K71](/docs/source/design/decisions#k71)). Sistemin bütünü [Yoldaşlar](/docs/gameplay/companions) sayfasındadır.

- **VI-a (198).** Jiyu Kurultay'da veliaht olur ve partiye girer (onay 5; Luhun yayı verdiyse +1); ayrılmaz, onayı ≤1 iken kendi ordugâhında bekler. Çetele, 1: Lung-çeng'de yirmi dört sancağı Tuçi'yle sayar (+1). Üç ayrılık gelir. [Uldın](/encyclopedia/uldin) Çukur'dan kurtulanlardan kurulan Yüzlük'ün yüzbaşılığını ister: verilirse subay olur, partiden kalıcı çıkar (+2); verilmezse kalır (−1): «O zaman yanında yaşlanırım.» / «Then I will grow old at your side.» [Mijia](/encyclopedia/mijia) avludaki Tunghu hanelerinin başı olmak ister: verilirse hane başı (+2), verilmezse kalır (−1). [Luhun](/encyclopedia/luhun) yayını Jiyu'ya verir (Jiyu +1, Luhun +2), Jiyu'nun onluğunun onbaşısı olur. Dangyu Xubu hanesinden [Liuli](/encyclopedia/liuli)'yi ardılı olarak yetiştirmeye başlar. Lung-çeng'in Dingling ozanı [Kunduz](/encyclopedia/kunduz)'un ninesidir, seçmeli Dingling Yurdu'ndan getirilir (+1). [Loufan okçusu](/encyclopedia/loufan-archer) Loufan sancağına subay olabilir.
- **VI-b (192).** [Zhang Sheng](/encyclopedia/zhang-sheng) Kâtip'te aday o seçilirse gelir (onay 3), Lü'ye Mektup'ta zorunludur; seçilmezse yoldaş olmaz. [Zang Yan](/encyclopedia/zang-yan) onu aday diye getirir (196–195'te ona Hun yanını tutmasını o söylemişti, SJ 93; +1). Zhang Sheng Lu Wan'ın buyruğunu nasıl çiğnediğini anlatır: «Sözün senin» +1, «Efendini sattın» −1. Mektupta Zang Yan ağzı tartar (alay +1, yalın −0,5), Zhang Sheng yazar (yalın +1, alay −1). Zang Yan güneye, Yan'a gitmek için izin ister: verilirse ayrılır (+2), verilmezse kalır (−1) ve VI-c'de yine sorar. VI-b sonunda [Dangyu](/encyclopedia/dangyu) ocağına çekilir (+2), Otacı Yurdu'nu Liuli alır.
- **VI-c (177).** [Tuidang](/encyclopedia/tuidang) Irmağın Güneyi'nde zorunludur, Han'la dilmaçtır (onay 3; V'te Dangyu doğumu karşıladıysa +1). Babasının ölümünü (13 Mart 196) anlatır, yeğeni [Han Ying](/encyclopedia/han-ying)'le ikili sahne gelir (+1). Hüküm'ün takibinde en çok 2 yoldaş izler. Jiyu Nan için söz alır, Kefil'i önerir (Kefil +1, Kanun −1); Kanun Tuidang'ın kırmızı çizgisidir: «Babamı da böyle kestiler.» / «That is how they cut down my father.» [Kozı](/encyclopedia/kozi) Ordos'ta yeniden alınabilir.
- **VI-d (176).** Xi Huqian 176 Mektubu'nda konuk olarak gelir, 176 Mektubu ve Yirmi Altı'da zorunludur; Elçinin Yolu sonunda armağanla yola çıkar. [Bujiu](/encyclopedia/bujiu) Kunmo'da bebek Kunmo'nun lalası olarak konuk gelir; Usun görevi boyunca partidedir, sonra Kunmo'nun yanında avluda kalır. Zhang Sheng fırçayı Tuidang'a verir (Tuidang +1), ocağına çekilir (+2). Tuidang 176 mektubunun kâtibidir; fırça ondaysa ek bir ağız seçeneği gelir (+1). Kunduz samur avından sonra kuzeye döner (+2; armağan 2 samur kürkü; VI-d ya da VI-e).
- **VI-e (174).** Tuidang Wen'in Cevabı'nda Han giysisini mi, Hun kaftanını mı giyeceğini seçer: seçim onundur, Mete'nin cevabı ±1, son adım +2. Çetele Jiyu'ya verilirse +2, başkasına verilirse −1 ama sayıma gelir. Son Söğüt'te ve Son Dailin'de Jiyu zorunludur; Kıl Köprü'de bütün parti yasaktır.
- **İkililer.** Luhun – Jiyu (yay, dostluk); Jiyu – Tuidang «İpek / Silk»: Han malı ve Han sözü (çatışma); Zang Yan – Zhang Sheng (SJ 93'ün konuşması, dostluk); Zhang Sheng – Tuidang (fırça, dostluk).

```varlik
portrait_jiyu, portrait_zhang_sheng, portrait_tuidang, portrait_xi_huqian, portrait_bujiu, portrait_uldin, portrait_mijia, portrait_luhun, portrait_kunduz, portrait_zang_yan
jiyu, jiyu_21, jiyu_37, uldin_old, mete_elder
```

## Kişiler

| Kişi | Kim | VI'da |
|---|---|---|
| Mete, 35–59 | Yay çeken halkların Tanhu'su | Dağıtır, yazar, yargılar, sayar; son sayımda ölür |
| Jiyu (Laoshang), 15–39 | Oğlu ve ardılı | Sol Bilge Kral, veliaht, çekirdek yoldaş; iki ses yaşı |
| Yitu | Oğlu, Sağ Bilge Kral | 177'de sınırı bozar, ceza olarak Yüeçi'ye gider, 176'da yener |
| Yimo | Kâhya | Çetele adayı |
| Tuçi | Töreci, Sayım Çetelesi'nin tutucusu | Sancakları Jiyu'yla sayar; çetele adayı |
| Nan | Houyilu beyi | Yitu'yu kışkırtır; yumuşak, kaygan |
| Liuli | Dangyu'nun ardılı | VI-a'da on dört yaşında çırak; VI-b'den Otacı Yurdu'nun ocak kamı ve otacısı |
| [Kunmo](/encyclopedia/kunmo) | Usun bebeği | Hunlar büyütür; babası [Nandoumi](/encyclopedia/nandoumi) öldürülmüştür |
| [Dingling ozanı](/encyclopedia/dingling-singer) | Kunduz'un ninesi | Sözsüz, uzun çekilen ezgi |
| [Lu Wan](/encyclopedia/lu-wan) | Yan kralı, Zhang Sheng'in efendisi | 29 Haziran 195'te sığınır |
| [İmparatoriçe Lü](/encyclopedia/empress-lu), [Fan Kuai](/encyclopedia/fan-kuai), [Ji Bu](/encyclopedia/ji-bu) | Lü'nün avlusu | 192 mektubu; Fan Kuai savaş ister, Ji Bu karşı çıkar (Kronik) |
| [İmparator Wen](/encyclopedia/emperor-wen), [Yi](/encyclopedia/han-envoy-yi), [Jian](/encyclopedia/han-envoy-jian) | Han imparatoru ve elçileri | 174 cevabı |
| [Han prensesi](/encyclopedia/han-princess) | Heqin'le gelir, adsız | Prensesin Yurdu |
| [Çocuk](/encyclopedia/child), ≈18–42 | Mete'nin ocağının ozanı | Kopuz ocağında çalar |
| Erlik, [Tengri](/encyclopedia/tengri), [Umay](/encyclopedia/umay) | Tanrılar | Erlik Kıl Köprü'nün ucundadır; Tengri 176 mektubunda «Göğün diktiği» sözündedir |

```varlik
yitu, nan, liuli, dingling_singer, lu_wan, empress_lu, emperor_wen, han_envoy_yi, han_envoy_jian, han_princess, han_ying
portrait_yitu, portrait_nan, portrait_liuli, portrait_tuchi, portrait_dingling_singer, portrait_lu_wan, portrait_empress_lu, portrait_emperor_wen, portrait_han_princess
```

## Mekânlar

| Yer | Ne | Görevler |
|---|---|---|
| Tanhu Avlusu (`tanhu_ordu`) | Toy Alanı, Tanhu Otağı, Elçi Yurdu, Gök Direği, sığınanların yurtları; Dailin yeri avlunun güz otlağındadır | 1, 3–5, 7, 10–14 |
| Lung-çeng (`longcheng`) | 198 ve 176 toplantıları | 2, 8, 9 |
| Ordos (`ordos`) | 177'nin sınırı | 6 |
| Hangay Yaylası (`hangai`) | Avlunun yaz otlağı; av ve yan görev | Ak Maral, Samur |
| Dingling Yurdu, Loulan | Seçmeli iki harita | Kunduz'un ninesi; Loulan |
| Kıl Köprü | Toybodım üstünde, at kılından, 24 m | 14 |

Uzak Yollar'ın ilk geçişinde anlatıcı tek cümle söyler ([K84](/docs/source/design/decisions#k84)); satırlar taslaktır:

- Hangay yolu: «Past Longcheng and up into the Khangai, where the Orkhon rises.» / «Lung-çeng'i geçip Hangay'a, Orhun'un doğduğu yaylaya.»
- Dingling yolu (seçmeli): «North by the Selenga and Lake Khövsgöl, into the forests of the Dingling.» / «Selenga ve Hövsgöl boyunca kuzeye, Dingling'in ormanlarına.»
- Loulan yolu (seçmeli): «West past Dunhuang to Loulan, at the edge of the salt marsh of Lop.» / «Dunhuang'ı geçip batıya, Lop tuzlasının kıyısındaki Loulan'a.»

## Mit, ozan ve müzik

- **Mitoloji anı ([K35](/docs/source/design/decisions#k35)).** Dingling'in [kurt atası](/encyclopedia/old-wolf) (Wei Shu 103, 554; geç tanık), Kunmo'nun kurdu ve kargası (SJ 123), «Göğün diktiği» mektubu, Söğüt Turu'nun üç turu, Kıl Köprü ve iki ışıklı şafak. Kıl Köprü Anohin'in derlediği bir motiftir: alt dünya bölümü olmaz, antların terazisi yoktur.
- **Ocağın ozanı ([K79](/docs/source/design/decisions#k79)).** IV'ten beri Mete'nin ocağında Çocuk çalar; VI'da ≈18 yaşından 42 yaşına yürür. Sonsöz'ün Yoğ Aşı'nda çalan da odur.
- **Perde rengi ([K59](/docs/source/design/decisions#k59)).** Tek tel kopuz, tek başına; skor seyrek drondur; nabız 50, D Dorian; motif bütün, yavaş, D'de çözülür; davul ve koro yoktur. Sayımda her baş bir tıktır: I'de rehineyi sayan tık burada Mete'nin halkını sayar ([audio.md §3](/docs/source/design/audio#3-muzik-durumlari)).

## Tarih ile kurgu

Oyuncuya her şey kesin tarihle söylenir; ayrım belgede ve Destan notunda kalır ([K33](/docs/source/design/decisions#k33), [K13](/docs/source/design/decisions#k13)).

| | VI'da |
|---|---|
| Kaynakta | Heqin ve «yay çeken halklar tek aile»; Sol Bilge Kral makamı; 192 mektubu, Lü'nün öfkesi ve cevabı (HS 94A); 177'de Sağ Bilge Kral'ın Ordos'a girişi, Guan Ying'in ordusu ve Yitu'nun Yüeçi'ye gönderilişi; 176 mektubu, armağanı ve elçi Xi Huqian; Loulan, Usun, Hujie ve yirmi altı ülke; 174 cevabı, elçiler Yi ve Jian; Nan; Mete'nin ölümü ve Jiyu'nun Tanhu oluşu (SJ 110); Kunmo'nun kurt ve karga söylencesi (SJ 123); Han Xin'in ve Liu Bang'ın ölümü, Lu Wan'ın sığınması, Zang Yan ile Zhang Sheng'in konuşması (SJ 93) |
| Oyunun seçimi | 1 Haziran 198 açılışı ve dilimlerin günleri; son Dailin'in günü (ölüm yılı kaynaktadır, gün oyunundur) |
| Okuma seçimi | Wang Huang'ın diri teslimi SJ 93'ün iki okumasından biridir; öteki, Quni'de kesildiği, Destan notudur |
| Kurgu | Kunmo'nun getirildiği yıl ve onu büyüten Tanhu'nun Mete oluşu; Liuli, Dingling ozanı, Dulongçi'nin ölümü ve yoğu, Dangyu'nun ölümü; Zhang Sheng'in ve Bujiu'nun Mete'yle bağı; Han Ying'in VI-c sahnesi; Nan'ın yazgısı oyuncunundur |
| Geç tanık ve mitoloji | Dingling'in kurt atası (Wei Shu 103); Söğüt Turu'nun üç turu Xianbei kaydıdır, Hun için çıkarımdır; Kıl Köprü ve Erlik mitolojidir, kurgu listesine girmez |

## Tanhu 1'den fark

Antların terazisi yoktur: borcun ölçüsü Kıl Köprü'nün enidir. Kurultay son bir karar değildir, perdenin başındaki bir dağıtımdır. Alt dünyaya inilen bir bölüm yoktur; köprü tek sahnelik bir geçiştir.

## Oyunda şu an

> [!DURUM]
> Oyunda: VI. Perde yok. Godot'da bugün menü, gece kampı, karakter oluşturucu, kayıt, ayarlar, Destan Kitabı, Serbest Gez ve takip kamerası var. Perdeler, görev ve diyalog, saat ve takvim (gece sabittir), Akan Kronik, yerleşim ve Kurultay, ordu, atlas ve yoldaş partisi yok; Hangay, Dingling Yurdu ve Loulan haritaları da yok. Godot'da Mete'nin bir Meshy modeli var; yaşlı Mete, Jiyu'nun yaşları ve VI'nın kişileri için model yok. Prototipte denendi: saat, hava, emek yasası, atlas ve yapı aşamaları; Godot'a taşınmadı ([oyun-durumu.md](/docs/source/design/d3/game-state)).

## Yol Haritası

Perdenin üç fazı ve 11 maddesi Yol Haritası'ndan canlı gelir. Önkoşul V'in son fazıdır (`act-5-p4`); sıra yıl dilimleri ve tam avlu, ana zincir, ayrılıklar ve yan aileler.

```ilerleme
act-6
```

## Doğrulanacaklar

- Doğrulanacak: beş dilimin sırayla açılması ve iç Kroniklerin formülle 30–90 sn akması ([Yol Haritası](/roadmap#item-year-slices)).
- Doğrulanacak: Kıl Köprü'nün eninin sönmüş ocaktan hesaplanması ve köprüyü Mete'nin yalnız geçmesi ([Yol Haritası](/roadmap#item-hair-bridge)).
- Doğrulanacak: avlunun ≤90 hane tavanı ve at ve deve yarışının mevsimde bir kez Gönül +1 vermesi ([Yol Haritası](/roadmap#item-kurultay)).
- Doğrulanacak: tek telin ve sayım tıklarının kulakla dengesi; ana görev satırları metin kilidinden sonra seslendirilir ([Yol Haritası](/roadmap#item-act6-sound)).

Kullanıcının onayını bekleyenler [Karar Bekleyenler](/docs/general/pending-decisions) sayfasındadır: VI'nın yoldaşlarının ve konuklarının sesi ve üretimi (Jiyu'nun iki yaş modeli ve Uldın'ın VI yaşı dahil), Çocuğun sesi ve genç ozan modeli, Sonsöz şarkısının çekimi (VI ve Sonsöz metni kilitlenince).

## Kaynaklar

- [story.md §2](/docs/source/design/story#2-zaman-cizelgesi-1), [§11.5](/docs/source/design/story#11-5-vi-perde-sayim-the-count), [§13](/docs/source/design/story#13-perde-arasi-akan-kronik), [§14.3](/docs/source/design/story#14-3-dailin-sayimi-44), [§14.4](/docs/source/design/story#14-4-yoldaslarin-kisisel-gorevleri-k71-k72), [§8.8](/docs/source/design/story#8-8-c-in-ve-han)
- [settlement.md §2.2](/docs/source/design/settlement#2-2-perde-perde), [§12.6](/docs/source/design/settlement#12-6-kurultay-vi-kancasi); [army.md §2](/docs/source/design/army#2-olcek); `companions.md` §1.3, §2.2 ve §2.3
- [progression.md §1.2](/docs/source/design/progression#1-2-perde-xp-butcesi), [§5.3](/docs/source/design/progression#5-3-olay-degerleri), [§5.4](/docs/source/design/progression#5-4-dort-yol-ii-perde-den)
- [fauna.md §9](/docs/source/design/fauna#9-perde-perde-acilis), [economy.md §8.6](/docs/source/design/economy#8-6-perde-perde-ekonomi), [weather.md §6.4](/docs/source/design/weather#6-4-sonraki-perde-kancalari), [audio.md §3](/docs/source/design/audio#3-muzik-durumlari), [travel.md](/docs/source/design/travel)
- [godot.md §9.10](/docs/source/design/godot#9-10-vi-perde-sayim-act-6)
- [mete-tarih.md](/docs/source/research/mete-history), [mitoloji.md](/docs/source/research/mythology)
- [decisions.md](/docs/source/design/decisions): K13, K25, K32, K33, K35, K42–K44, K54–K56, K59, K65, K67, K70, K71, K79, K84, K88

İlgili sayfalar: [V. Perde: Dört Renk](/docs/story/act-5), [Sonsöz: Kopuz Susar](/docs/story/epilogue), [Perde Arası: Akan Kronik](/docs/story/chronicle), [Hikâye Omurgası](/docs/story/spine).
