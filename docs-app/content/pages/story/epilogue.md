---
title: 'Sonsöz: Kopuz Susar'
order: 56
status: tasarim
summary: "9 Eylül–8 Ekim MÖ 174 ve «yıllar sonra»: ≈2 dk 55 sn'lik sinemada Mete höyüksüz gömülür, Yoğ Aşı'nda Önsöz'ün Çocuğu kırk iki yaşında bir ozan olarak çalar, Jiyu Tanhu olur, Son Sayım kartı oyunun sayımını okur ve kopuz son sözcükte susar."
sources:
  - docs/design/story.md
  - docs/design/decisions.md
  - docs/design/progression.md
  - docs/design/settlement.md
  - docs/design/companions.md
  - docs/design/audio.md
  - docs/design/act0-text.md
  - docs/design/godot.md
  - docs/design/d3/oyun-durumu.md
  - docs/research/mitoloji.md
  - docs/research/mete-tarih.md
  - docs/research/kopuz.md
---

## Özet

Sonsöz «Kopuz Susar / The Kopuz Falls Silent» tamamen sinemadır: ≈2 dk 55 sn sürer, Esc atlar. Tarih 9 Eylül–8 Ekim MÖ 174'tür (`dayN` 14.097–14.126), ardından «yıllar sonra» kartları gelir. [Mete](/encyclopedia/mete) son Dailin'de, sayım sürerken, 59 yaşında ölmüştür ([VI. Perde: Sayım](/docs/story/act-6)). Oyuncu izler: sayım hattı durmaz, Mete höyüksüz gömülür, Yoğ Aşı'nda ozan çalar, [Jiyu](/encyclopedia/jiyu) Tanhu olur, Son Sayım kartı oyunun sayımını okur, ozan iki dize söyler ve kopuz son sözcükte susar. Önsöz'ün ilk vuruşuyla açılan çerçeve burada kapanır.

- **Ad.** «Kopuz Susar» [K32](/docs/source/design/decisions#k32)'dir: ozanın anlatısı biter.
- **Soru.** Sayım kimde kalır?
- **Ozan.** Önsöz'de ateş başında ozanı dinleyen [Çocuk](/encyclopedia/child) MÖ 209 baharında yedi yaşında bir Hun kızıydı. Teoman'ın [ozanı](/encyclopedia/bard) III → IV Kroniği'nde ölmüş, kopuzu ona kalmıştı; IV'ten beri Mete'nin ocağının ozanıdır. MÖ 174'te kırk iki yaşında bir kadın ozandır ve yoğda çalan odur ([K79](/docs/source/design/decisions#k79)). Dinleyen ozan oldu.

> [!NOT]
> «Act ler olacak - Metenin hayatını anlatacak»

Tasarım bu yöndedir ([K32](/docs/source/design/decisions#k32), [K36](/docs/source/design/decisions#k36)): oyun perde perde Mete'nin hayatını anlatır, Önsöz'deki doğumdan (27 Eylül MÖ 234) VI. Perde'nin son görevindeki ölüme (9 Eylül MÖ 174). Sonsöz hayatın bittiği yerde ozanın anlatısını kapatır; oynanmaz, izlenir.

## Sahne sahne

| # | Süre | Görüntü | Ses |
|---|---|---|---|
| 1 | 0:00–0:20 | Mete oturakta kıpırdamaz; sayım hattı durmaz, atlar geçer; çetele VI'da seçilen kişinin elindedir | Tıklar seyrekleşir, rüzgâr |
| 2 | 0:20–0:55 | Gömü: tabut, altın daire ve hilal, kürk; höyük, ağaç ve yas giysisi yoktur (無封樹喪服). Ardından gidenler son kartın yoluna göredir. Kan görünmez | Tek tel |
| 3 | 0:55–1:20 | Yoğ Aşı. Ateş başında ozan: Önsöz'ün Çocuğu, kırk iki yaşında. Bir kucakta iki yaşında [Kunmo](/encyclopedia/kunmo) | Kopuz |
| 4 | 1:20–1:30 | Kart: «8 Ekim MÖ 174 · Jiyu Tanhu oldu.» / «8 October 174 BC · Jiyu became Tanhu.» (子稽粥立，號曰老上單于) | |
| 5 | 1:30–2:00 | «Yıllar sonra» kartları | Seyrek dron |
| 6 | 2:00–2:35 | Son Sayım kartı, yoldaş satırlarıyla | Müzik yok, rüzgâr ve tek tel |
| 7 | 2:35–2:55 | Ozanın iki dizesi; kopuz son sözcükte susar; 4 sn sessizlik; son kare ot | Rüzgâr |

Süre önceki ≈2 dk 40 sn'ye Tuidang ve Bujiu'nun «yıllar sonra» satırları ile Son Sayım'ın yoldaş satırları için 15 sn eklenerek ≈2 dk 55 sn oldu ([K71](/docs/source/design/decisions#k71)). Godot'da sahne `epilogue.tscn`'dir, kart satırlarının değerleri kayıttan okunur.

## Gömü ve dört yol

Gömünün ardından gidenler, Son Sayım kartının «Yol» satırını okur. Yol Kut ve Korku'dan II. Perde'den beri hesaplanır ([progression.md §5.4](/docs/source/design/progression#5-4-dort-yol-ii-perde-den)).

| Yol | Koşul | Gömüde |
|---|---|---|
| Tan Yolu / The Dawn Road | Kut ≥10, Korku <6 | Yalnız tabut ve Mete'nin sözü: «Ardımdan kimse gelmesin.» / «Let no one follow me.» |
| Çetele Yolu / The Tally Road | Kut ≥10, Korku ≥10 | Töre kadar (近幸臣妾從死者) |
| Kor Yolu / Road of Embers | Kut <6, Korku ≥10 | Tabutun ardında boş eyerli atlar |
| Toz Yolu / Dust Road | Kut <6, Korku <6 | Töre kadar |

Yolun adı kartta tek satırdır, bir son adı gibi büyük yazılmaz.

## Yoğ Aşı ve Jiyu'nun kartı

- **Yoğ Aşı.** Höyüksüz gömüden sonra yoğ verilir. Ateş başında kopuzla ozan oturur; bir kucakta iki yaşında Kunmo vardır: VI'da Mete'nin sayıma aldığı Usun bebeği.
- **Jiyu.** 8 Ekim MÖ 174'te Jiyu Tanhu olur, unvanı Laoshang'dır (號曰老上單于). 39 yaşındadır; VI-a'dan beri Sol Bilge Kral ve çekirdek yoldaştı. Son Sayım'da yoldaş satırı yazılmaz, çünkü Tanhu kartı onundur.

## Yıllar sonra

- **Kalem.** Yeni prensesle gelen hadım [Zhonghang Yue](/encyclopedia/zhonghang-yue) Tanhu'nun adamlarına sayımı yazmayı öğretir (於是說教單于左右疏記，以計課其人眾畜物): çentik kaleme geçer ([K62](/docs/source/design/decisions#k62)). III'te Mete «Hun yazmaz, çentikler.» demişti.
- **Kunmo.** Kunmo büyür, [Bujiu](/encyclopedia/bujiu) yanındadır. Bir Tanhu ölünce halkını uzağa götürür (單于死，昆莫乃率其眾遠徙); Bujiu onunla batıya gider. Bujiu'nun gidişi kurgudur.
- **Tuidang.** [Tuidang](/encyclopedia/tuidang) 166'da yeğeni [Han Ying](/encyclopedia/han-ying)'le halkını alıp Han'a geçer: «Tuidang 166'da halkıyla Han'a geçti; ona Gonggao markisi dediler (弓高侯).» / «In 166 Tuidang crossed to Han with his people; they called him Marquis of Gonggao.» (SJ 93)
- **Atlas.** [Yüeçi](/encyclopedia/yuezhi)'nin batı yolu atlasta uzar.

## Son Sayım / The Last Count

Kart bir son adı koymaz, oyunun sayımını okur. Satırlar sırayla gelir; değeri olmayan satır düşer.

| Satır | TR / EN | Nereden gelir |
|---|---|---|
| Gün | «Sayımın on dört bin doksan yedinci günü.» / «Day fourteen thousand and ninety-seven of the count.» | Takvimin sayacı: rehinenin günü, 1. gün 26 Ocak MÖ 212 |
| Halk | «{h} hane, {p} can, {s} baş sürü.» / «{h} households, {p} souls, {s} head of stock.» | Yerleşimin hane, can ve sürü sayısı (II–VI) |
| Ordu | «{n} atlı ıslığa uyar.» / «{n} riders answer the whistle.» | Islığa uyan atlı (II'den talim) |
| Ocak | «Erlik {o} ocak sayar.» / «Erlik counts {o} hearths.» Borç yoksa satır yoktur | I'in Kül Borcu ve sönmüş ocakları; II–VI'nın Kül Ödemesi |
| Adlar | «Çukur'un adlarından {n}'i sayıldı.» / «{n} of the Hollow's names were counted.» | I'in Bilinen Adlar'ı ve Ad İpi; IV'te Çukur'da sayılır |
| Antlar | «Beş anttan {k}'i tutuldu.» / «{k} of five oaths were kept.» | I'de verilen beş ant; IV'te okunur |
| Yol | Yolun adı, tek satır | Kut ve Korku (II'den) |
| Avlu | «Avlusu surluydu.» / «His court stood behind walls.» ya da «Avlusu tekerlekteydi.» / «His court rode on wheels.» | V'in Sur mu, Teker mi seçimi ([settlement.md §4.3](/docs/source/design/settlement#4-3-v-kademe-yolu)) |
| Ocağın kökü | «Ocağı babasının közüyle yanmıştı.» / «His hearth was lit from his father's ember.» ya da «Ocağını kendi yaktı.» / «He lit his own hearth.» | II'nin Köz Kabı |
| Çetele | «Çeteleyi {ad} tuttu.» / «{name} kept the tally.» | VI'nın Son Söğüt'ü: Jiyu, Yimo ya da Tuçi |
| Yoldaşlar | En çok 5 satır (aşağıda) | II–VI'nın partisi ve kişisel görevlerin sonu |
| Son | «Sayım sürüyor.» / «The count goes on.» | |

**Yoldaş satırları ([K71](/docs/source/design/decisions#k71)).** Her tanınan çekirdek yoldaşın durumu ve kişisel görevinin sonu okunur, en çok 5 satır. Sıra: önce ölüm satırları, sonra sona dek partide kalanlar onay sırasıyla, sonra subay, hane başı ve yurduna dönenler. Jiyu ve konuklar yazılmaz; konukların sonu Kronik'tedir, Tuidang ve Bujiu «yıllar sonra»dadır. Onayı düşüp ayrılık sahnesiyle giden yoldaşın satırı yoktur.

- **Ölüm satırları.** Luhun II'de kestirildiyse: «Luhun'un oku Yançi'ye gitmedi.» / «Luhun's arrow never flew at Yanchi.» Dangyu: «Dangyu 186 kışı öldü; ocağını ardılı yaktı.» / «Dangyu died in the winter of 186; her successor lit her hearth.»
- **Örnekler.** «Uldın sayımın ertesi kışı öldü; Çukur'un ipi onunla gömüldü.» / «Uldin died the winter after the count; the Hollow's cord was buried with him.» «Kunduz'un ezgisi kuzeyde sürdü.» / «Kunduz's song went on in the north.» Ötekilerin satırı `companions.md` §1.3'tedir: «Berik'in yurdu avlunun kıyısındaydı; kapısını hiç bağlamadı.», «Kozı'nın sürüsü ırmak otlağında otladı; kazıklar bir daha çakılmadı.», «Zang Yan güneye gitti; dönmedi.», «Zhang Sheng'in fırçası Tuidang'ın elinde kurudu.»

```varlik
ui_tally_card, mete_elder, jiyu_37, zhonghang_yue, portrait_zhonghang_yue, portrait_bujiu, portrait_tuidang, portrait_han_ying
```

## Ozanın kapanışı

Ozan iki dize söyler ([K60](/docs/source/design/decisions#k60)). Biçim Qilian şarkısının koşut dizesidir (亡我祁連山，使我六畜不蕃息；失我焉支山，使我婦女無顏色; SJ 110 şerhi, 西河故事); şarkının kendisi söylenmez.

- «Sayanımızı yitirdik, sayımız yabancı ele geçti; / otumuzu yitirmedik, atlarımız yine semiz.» / «We lost the one who counted us, and our count passed to a stranger's hand; / we did not lose our grass, and our horses are fat again.»
- Sönmüş ocak sayısı ≥6 ise ikinci dize değişir: «ocağımızı yitirmedik, külümüz bizimle göçer.» / «we did not lose our hearth, and our ash moves on with us.»
- Kopuz son sözcükte susar, son nota çalınmaz. Ardından 4 sn yalnız rüzgâr; son kare ottur. Önsöz'ün ilk vuruşuyla açılan çerçeve kapanır.

**Çekim ([K79](/docs/source/design/decisions#k79), [K75](/docs/source/design/decisions#k75)).** Şarkı bir Eleven Music çekimidir. Tarifin ses satırı: «solo middle-aged female epic singer in her early forties, low and guttural, who sings and plays at the same time, the komuz never stops under the voice». Kip, hız, çalgı tarifi ve ölçütler Önsöz'ünkidir: D Dorian (doğal F ve C), 6/8, noktalı dörtlük 52, her sekizlikte vuruş, gırtlaktan hece başına bir nota; sözsüz bölümlerde eş zamanlı perde ≤3; son onay kulaktadır. Sözcük sınaması Sonsöz'ün kendi dizelerini okur; çıkış yoktur. Ses satırı yaşı ve cinsiyeti söylemezse Eleven Music Önsöz'ün yaşlı erkek sesini yineler ve «dinleyen ozan oldu» çerçevesi duyulmaz. Bir tur 4 çekim ≈1.620 kredidir (çekim başına ≈405); seçenek B planıdır: a cappella ses ve kodla kopuz. Çekim VI ve Sonsöz metni kilitlenince sorulur ([K61](/docs/source/design/decisions#k61)).

![Önsöz'ün şarkısı, bugünkü dosya (çekim 3104; [K95](/docs/source/design/decisions#k95)). Sonsöz'ün şarkısı aynı kip, hız ve çalgıyla, kırk iki yaşında bir kadın sesiyle çekilecek](/media/docs/media/audio/vo/en/act0.bard.song.mp3)

```varlik
kopuz, music_epilogue_song, vo_epilogue_bard, child, portrait_child
```

## Ses ve görünüş

- **Perde rengi ([K59](/docs/source/design/decisions#k59)).** Tek tel ve kopuz; ozanın iki dizesi. Skor seyrek drondur; nabız 52, D Dorian: Önsöz'ün çerçevesi kapanır. Motifin düşüşünün son notası çalınmaz. Davul ve koro yoktur. Tıklar seyrekleşir ([audio.md §3](/docs/source/design/audio#3-muzik-durumlari)).
- **Sessizlik.** Sonsöz'ün sessizliği son sözcükten sonraki 4 sn'dir: yalnız rüzgâr.
- **Görüntü.** Kan, hastalık ve son söz yoktur. Gömüde höyük, ağaç ve yas giysisi yoktur; son kare ottur (SJ 110 無封樹).

## Tarih ile kurgu

Oyuncuya her şey kesin tarihle söylenir; ayrım belgede ve Destan notunda kalır ([K33](/docs/source/design/decisions#k33), [K13](/docs/source/design/decisions#k13)).

| | Sonsöz'de |
|---|---|
| Kaynakta | Mete'nin ölümü ve Jiyu'nun Tanhu oluşu (yıl kaynaktadır; SJ 110); höyüksüz, ağaçsız, yas giysisiz gömü ve yakınların ardından gidişi (SJ 110); Zhonghang Yue'nun sayımı yazdırması (SJ 110); Kunmo'nun halkını uzağa götürmesi (SJ 123); Tuidang'ın 166'da Han'a geçişi (SJ 93); Qilian şarkısının koşut dize biçimi (SJ 110 şerhi) |
| Oyunun seçimi | Günler: 9 Eylül ölüm, 8 Ekim kart; dört yolun gömüye etkisi |
| Kurgu | Ozanın Önsöz'ün Çocuğu oluşu ve kırk iki yaşı; Bujiu'nun Kunmo'yla batıya gitmesi; yoldaşların son kart satırları; ozanın iki dizesi |

## Tanhu 1'den fark

Tanhu 1'in sonsözü yaz ateşinde çocuklara anlatan kör bir ozandır ve dört adlı son vardır. Burada ozan Önsöz'ün dinleyicisidir, kırk iki yaşında bir kadındır ve yoğda çalar; son kart bir sayımdır, son adı yoktur. Yolların eski «Gök Yolu» ve «Demir Yol» adları Tanhu 1'in iki son adına denk düştüğü için Tan Yolu ve Çetele Yolu oldu ([K32](/docs/source/design/decisions#k32)).

## Oyunda şu an

> [!DURUM]
> Oyunda: Sonsöz yok. Godot'da hikâye perdeleri ve kayıttan okunan son kart yok. Sinema çalıştırıcı ve seslendirme Önsöz için oyunda. Godot'daki `child` modeli Önsöz'ün yedi yaşındaki Çocuğudur; kırk iki yaşındaki ozanın ve yaşlı Mete'nin modeli yok. Ateş başındaki ozanın elinde üç telli Meshy kopuzu var. Önsöz'ün şarkısı oyunda çalar; Sonsöz'ün şarkısı çekilmedi ([Yol Haritası](/roadmap#epilogue)).

## Yol Haritası

Sonsöz'ün iki fazı ve üç maddesi Yol Haritası'ndan canlı gelir. Önkoşul VI'nın son fazıdır (`act-6-p3`); ardından yayın gelir.

```ilerleme
epilogue
```

## Doğrulanacaklar

- Doğrulanacak: Sonsöz'ün ≈2 dk 55 sn'si satır sayısından tahmindir, sinema kurulunca ölçülür ([Yol Haritası](/roadmap#item-epilogue-scene)).
- Doğrulanacak: Son Sayım'ın satırlarının kayıttan okunması, değeri olmayan satırın düşmesi ve yoldaş satırının en çok 5 olması ([Yol Haritası](/roadmap#item-last-count)).
- Doğrulanacak: şarkı aracının ölçütleri (K75) Sonsöz'ün çekiminde de kredisiz koşulur ([Yol Haritası](/roadmap#item-song-measure)).
- Doğrulanacak: kopuzun son sözcükte susması, 4 sn sessizlik ve menüye dönüşte menü karesinin referansla aynı olması ([Yol Haritası](/roadmap#epilogue-p2)).

Kullanıcının onayını bekleyenler [Karar Bekleyenler](/docs/general/pending-decisions) sayfasındadır: Sonsöz şarkısının Eleven Music çekimi (bir tur 4 çekim, ≈1.620 kredi; B planı seçeneği), Çocuğun sesi ve genç ozan modeli.

## Kaynaklar

- [story.md §1](/docs/source/design/story#1-oncul-ve-ton), [§12](/docs/source/design/story#12-sonsoz-kopuz-susar-the-kopuz-falls-silent), [§8.3](/docs/source/design/story#8-3-anlati-ve-ana-kamp), [§2](/docs/source/design/story#2-zaman-cizelgesi-1)
- [progression.md §5.4](/docs/source/design/progression#5-4-dort-yol-ii-perde-den), [settlement.md §4.3](/docs/source/design/settlement#4-3-v-kademe-yolu); `companions.md` §1.3
- [audio.md §2](/docs/source/design/audio#2-calgilar-kodla) (Sonsöz'ün şarkısı), [§3](/docs/source/design/audio#3-muzik-durumlari); [act0-text.md](/docs/source/design/act0-text); [kopuz.md](/docs/source/research/kopuz)
- [godot.md §9.11](/docs/source/design/godot#9-11-sonsoz-kopuz-susar-epilogue)
- [mitoloji.md](/docs/source/research/mythology) (öneri 19: Qilian şarkısının biçimi), [mete-tarih.md](/docs/source/research/mete-history)
- [decisions.md](/docs/source/design/decisions): K13, K32, K33, K36, K59–K62, K71, K75, K79, K87

İlgili sayfalar: [VI. Perde: Sayım](/docs/story/act-6), [Önsöz: Kopuz Söyler](/docs/story/prologue), [Hikâye Omurgası](/docs/story/spine), [Kadro](/docs/story/cast), [Ses ve Müzik](/docs/presentation/sound-music).
