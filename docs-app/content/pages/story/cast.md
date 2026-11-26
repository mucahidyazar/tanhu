---
title: Kadro
order: 60
status: kismen
summary: 'Bütün oyunun kişileri bölüm bölüm: kim oldukları, rolleri, perdeleri, tarihî mi kurgu mu oldukları ve sesleri; 16 yoldaş ayrı tabloda; var olan sesler bu sayfada dinlenir, ansiklopedide kaydı olan her kişi oraya bağlanır.'
sources:
  - docs/design/story.md
  - docs/design/decisions.md
  - docs/design/audio.md
  - docs/design/companions.md
  - docs/design/act1.md
  - docs/design/act0-text.md
  - docs/design/fauna.md
  - docs/research/yoldaslar.md
  - docs/research/mete-tarih.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Kadro yeni senaryoyla bütün oyunu kapsar: Önsöz'den Sonsöz'e adlı kişiler, 16 yoldaş, tanrılar ve ruhlar, adlı hayvanlar ([story.md §8](/docs/source/design/story#8-kadro), [K69](/docs/source/design/decisions#k69)). Her kişi ilk göründüğü bölümün tablosundadır; «Perdeler» sütunu bütün yolunu yazar. Ansiklopedide kaydı olan kişinin adı oraya bağlıdır ([Ansiklopedi](/encyclopedia)). Kimlik İngilizce kebab-case'tir (`lan-hatun`): sitenin, Ansiklopedi'nin ve Varlıklar'ın adresi odur; Godot verisinde tire alt çizgiye döner (`lan_hatun`).

- **«Tarih» sütunu.** Tarihî: kişi kaynakta adıyla geçer. Tarihî makam: makamı kaynakta geçer, adı ya da kişiliği kurgudur. Kurgu: oyunundur, kurgu listesine girer ([K13](/docs/source/design/decisions#k13)). Mitoloji: kurgu listesine girmez. Oyun: çerçevedir. Oyuncuya hepsi kesin söylenir; ayrım Destan notundadır.
- **Söz kuralı.** Yüeçiler sayıyla, Hunlar kısa ve kara mizahla konuşur. Satır en çok iki cümledir; kişiler iş bırakmaz, yürürken konuşur. Söylenen dil İngilizce, altyazı Türkçedir. Hangi satırın ses alacağını dört dilim seçer: A hep (anlatıcı, ozan, tanrılar, sinema, ana görev düğümleri), B düğüm (yan görevin açılışı ve kapanışı, adlı kişinin ilk karşılaşması), C havuz (sistem sözleri), D yazı (iş ve ara sözler, kitap, kart) ([K61](/docs/source/design/decisions#k61)).
- **Kişi sayfası ([K85](/docs/source/design/decisions#k85), [K86](/docs/source/design/decisions#k86)).** Ansiklopedi'de ve Destan Kitabı'nın Kişiler sayfasında her kişinin üç görseli vardır: önce tam boy art, profil ve T-poz art'tan türer; 3B modeli olan kişide üçüncü görsel modelin kendisidir (bugün Mete, Ana, Baba, Ozan ve Çocuk). Başlığın yanındaki hoparlörle kişi kendini iki cümleyle tanıtır; ses kişinin oyundaki sesidir. Anlatıcının sesi Eldrin ve ozanın sesi David başka kişilere verilmez; oyunda konuşmayan kişi (Umay, Mene) sesle tanıtılmaz.
- **Ses sütunu.** Kütüphaneden seçilen ses ya da seçimin durumu. Bugün var olan sesler yalnız anlatıcının yedi satırı, ozanın şarkısı ve Erlik'in ansiklopedi tanıtımıdır: [Sesler](#sesler). Ötekilerde ses henüz yok.

> [!NOT]
> «kadro kisminda karakter seslerinide onizleme yapabilelim, simdilik sadece olani ekle hicbirinin yoksada sorun degil ileride ekleriz, kadro suan biraz oyunumuz icin dar geldi bunuda genisletelim yen isenaryoyla birlikte»

## Anlatanlar

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| Anlatıcı | Görünmeyen kâtip, tarihi günüyle söyler: Önsöz'ün mit sinemasını ve doğumu okur; köprüler, perde kartları ve Kronik onundur; II'den her Uzak Yol'un ilk geçişinde tek cümle söyler ([K84](/docs/source/design/decisions#k84)) | Önsöz, köprüler, perde kartları, Kronik, Uzak Yol | Oyun | Eldrin (`LvmvHEBEmMJBJw9UuhwO`), kararlılık 0,5, hep 2B; yedi köprü satırı var |
| [Ozan](/encyclopedia/bard) | Göl Obası'nın ozanı: Önsöz'ün şarkısını kopuzla söyler. II–III'te Mete'nin ocağına gelir (Köz Kabı'yla değil, yolu II'de yazılır; [K106](/docs/source/design/decisions#k106)), orada çalar; Ozan'a Anlattır ve Kopuz Gecesi onu okur. III→IV Kroniği'nde ölür, kopuzu ocağın Çocuğuna kalır ([K79](/docs/source/design/decisions#k79)) | Önsöz, Serbest Gez, II–III, Kronik | Kurgu | Şarkı Eleven Music, gırtlaktan: çekim 3104 ([K95](/docs/source/design/decisions#k95)). Oyun içindeki sözü David (`BNgbHR0DNeZixGQVzloa`), ses henüz yok; Önsöz'de konuşmaz |
| [Çocuk](/encyclopedia/child) | Ozanın dinleyicisi, yedi yaşında bir Hun kızı; Serbest Gez'in oyuncusu, Ev'de oyuncu değildir (K106). IV–VI'da Mete'nin ocağının ozanıdır (IV'te ≈11–13, V'te ≈15–16, VI'da ≈18–42 yaş); Sonsöz'de kırk iki yaşında kadın ozandır, Yoğ Aşı'nda çalan odur (K79) | Önsöz, Serbest Gez, IV–VI, Sonsöz | Kurgu | Çocukken sözsüz. Genç ozanın sesi kullanıcının seçimidir; Sonsöz şarkısının ses satırı «solo middle-aged female epic singer in her early forties…»; ses henüz yok |

## Ana kamp

Ana kamp Göl Obası'dır / Lake Camp: MÖ 209 baharında Göl Vadisi'nde rastgele bir oba, hikâyenin dışında. Tanhu Kampı da Teoman'ın ocağı da değildir ([K106](/docs/source/design/decisions#k106)). Önsöz'ün çerçevesi ve Serbest Gez burada geçer; Ev ve II'nin sinemaları Tanhu Kampı'ndadır, Köz Kabı orada Teoman'ın ocağından dolar. Ocak halkı obanın halkıdır: Ana, Baba, Ozan, Ağabey ve Çocuk. Mete obaya gelmez ([K6](/docs/source/design/decisions#k6), [K37](/docs/source/design/decisions#k37)): Godot'da ateş başındaki Mete kaydı Ağabey'e döner, Mete'nin modeli kamptan çıkar, Serbest Gez'de oluşturulan yetişkin değil Çocuk yürür. Çocukluk'un çocuğu küçük Mete'dir, Serbest Gez'in Çocuğu değildir; ikisi aynı çocuk denetleyicisini ve oyuncak yayı paylaşır.

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Ana](/encyclopedia/mother), [Baba](/encyclopedia/father) | Göl Obası'nın ocak halkı: ocağı tutan kadın; kampı kuran, atlara bakan adam | Önsöz, Serbest Gez | Kurgu | Kısa, sıcak; Baba az söz; ses henüz yok |
| [Ağabey](/encyclopedia/older-brother) | Çocuğun ağabeyi, Tanhu'nun atlısı; Godot'daki Mete kaydının yerine geçer; II'de Islık Ordugâhı'na katılır, adlı er olarak partiye girebilir | Önsöz, II | Kurgu | Genç, hızlı; ses henüz yok |
| [Oktar](/encyclopedia/oktar) ≈52, [Erka](/encyclopedia/erka) ≈44, [Dengiz](/encyclopedia/dengiz) 15 | Serbest Gez'de üçüncü yurdu kuran ustalar: Dülger, Keçe Ustası ve Otacı, Çırak | Serbest Gez | Kurgu; ad dönem dışı | İş sözleri altyazı |

```varlik
portrait_bard, portrait_child, portrait_mother, portrait_father, portrait_older_brother
elder, child, mother, father, older_brother
```

## Önsöz, Çocukluk ve Yola Çıkış

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Mete](/encyclopedia/mete) | Kahraman, MÖ 234–174; 15 Haziran 209'dan Tanhu; rehineyken 24 yaşında | Hepsi | Tarihî (冒頓) | King Chuku the Great, eski adı Arthur (`XALcFq0WF65uNKzmpcZW`): genç bariton, az konuşur; VI'da aynı ses, yavaş. Oyunda duyulan ilk sözü Yola Çıkış'ın «Sayarım.»ıdır; çocukken kendi sesi vardır, Ryan Quin ([K105](/docs/source/design/decisions#k105)) |
| [Teoman](/encyclopedia/teoman) | Tanhu, baba; I. Perde'de ≈52; dört saniyelik bakışı üç kez gelir; ö. 14 Haziran 209 | Önsöz, Çocukluk, Yola Çıkış, I, Ev, II | Tarihî (頭曼) | Bariton king (`KptSjXRPFHt1Dn4BqM8V`): ağır, yorgun, sabırlı; ses henüz yok |
| [Lan Hatun](/encyclopedia/lan-hatun) | Mete'nin anası, Teoman'ın büyük hatunu, Lan soyundan; II–IV'te yerleşimin Kâhya'sı; ö. 16 Kasım 203 | Önsöz, Çocukluk, Yola Çıkış, Ev, II–IV | Kurgu; soy SJ 110 蘭氏 | Alçak, düz, sayarak konuşur; ses henüz yok |
| [Hereka](/encyclopedia/hereka) | Mete'yi doğurtan ebe (234'te 39 yaşında); sonra Çukur'un ebesi, Hun tutsak (I'de 63): «Seni ilk gününde ben saydım.» | Önsöz, I, IV | Kurgu; ad dönem dışı | Doğumda konuşan tek kişi («One more.»). Sesi seçildi ([K95](/docs/source/design/decisions#k95)): Önsöz'ün 39 yaşı Heather Faith (satır okundu), I. ve IV. Perde Lea, Mature; modelleri [K89](/docs/source/design/decisions#k89)'dadır |
| [Sayıcı](/encyclopedia/counter) | Dailin'in adsız sayıcısı | Önsöz, Çocukluk | Kurgu; iş SJ 110 課校人畜計 | Yaşlı, düz; ses henüz yok |
| [Yançi](/encyclopedia/yanchi) | Çocukluk arkadaşı, iyi okçu (228'de 5 yaşında); 216'da Mete'nin sevdiği eşi, Jiyu'nun anası; ö. 10 Haziran 209. Yoldaş olmaz | Çocukluk, Köprü, Yola Çıkış, II | Kurgu; kişi SJ 110 愛妻 | Hızlı, gülen, kısa cümle; ses henüz yok |
| [Huyan Hatun](/encyclopedia/huyan-hatun) | Gözde hatun, Huyan soyundan, Mete'den bir yaş küçük; ö. 15 Haziran 209, ekran dışı | Köprü, Yola Çıkış, Ev, II | Kurgu; kişi SJ 110 所愛閼氏 | Parlak, kısa, acelesiz; ses henüz yok |
| [Gutu](/encyclopedia/gutu) | Küçük oğul, d. 24 Haziran 214; adı Hun dilinde «oğul» (孤塗); ö. 15 Haziran 209, ekran dışı | Köprü, Yola Çıkış, Ev, II | Kurgu; kişi SJ 110 少子 | Sözsüz |
| [Jiyu (Laoshang)](/encyclopedia/jiyu) | Mete'nin oğlu ve ardılı, d. 13 Haziran 213; Yola Çıkış'ta beşikte, II'de dört yaşında; VI-a'da Sol Bilge Kral ve yoldaş; 8 Ekim 174'te Tanhu | Yola Çıkış, II, VI, Sonsöz | Tarihî (稽粥; okunuşu Jiyu, Jizhu değil); doğumu ve anası kurgu | Düz, Mete'den yumuşak; iki ses yaşı (15 ve 39); sesi yoldaşlarla seçilir |
| [Eskam](/encyclopedia/eskam) | Gudu, Huyan soyundan elçi (I'de 44); Mete'yi 213'te götürür, her kış gelir | Yola Çıkış, I, II; II sonunda «Kalsın» denirse III, V | Kurgu; makam SJ 110 骨都侯 | Roland Lescalde (`dcbUcEjFfmgpM8W4YTRG`): fazla sıcak, «evladım» der; ses henüz yok |
| [Birinci İmparator](/encyclopedia/first-emperor), [Meng Tian](/encyclopedia/meng-tian) | Ç'in'in imparatoru (ö. 12 Temmuz 210) ve Ordos'u 215'te alan generali (ö. 6 Kasım 210); haberleri I'de kervanla gelir, IV'te Meng Tian'ın kazıkları sökülür | Köprü, I (haber), IV (söz) | Tarihî | Ses yok |

```varlik
portrait_mete, portrait_teoman, portrait_lan_hatun, portrait_huyan_hatun, portrait_yanchi
portrait_hereka, portrait_counter, portrait_eskam
```

## I. Perde: Kışlak

Tanımları, istekleri ve öğrettikleri [act1.md §3](/docs/source/design/act1#3-kadro)'tedir; IV'teki yolları perde sayfasındadır. Uldın ve Berik I'in kişisidir, II'den çekirdek yoldaştır: [Yoldaşlar](#yoldaslar).

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Amaga](/encyclopedia/amaga) 58 | Kışlak başı, Yüeçi Kralı'nın dul kız kardeşi; Kefil Sözü'nü öğretir | I, IV | Kurgu | Elinor (`gDQfVolj9RbmXgumLcOq`): kuru, alçak, hiç yükselmez; ses henüz yok |
| [Farnak](/encyclopedia/farnak) 25 | Atlı okçu, ilk kefil, boss | I, IV | Kurgu | Revenant (`b3tuFWghbXYRa9Cs9MJf`): hızlı, gülerek; ses henüz yok |
| [Nanay](/encyclopedia/nanay) 23 | Keçe ustası, Farnak'ın yeni eşi; [oğlu](/encyclopedia/nanay-son) IV'te beş yaşındadır | I, IV | Kurgu | Aisyah (`jfD5mm5oPglFjL59x819`): alçak, alaycı; ses henüz yok |
| [Palak](/encyclopedia/palak) 47 | Nöbet başı; her sabah sayar: «Bin kırk birinci gün. Bir rehine.» | I, IV | Kurgu | Piotr (`S1uaQ66tHSeCjgsWYpGI`): düz, sayar gibi; ses henüz yok |
| [Ardokşa](/encyclopedia/ardoksha) 52 | Ambar bekçisi | I | Kurgu | Genizden, her cümlede sayı; ses seçimi kullanıcıda; ses henüz yok |
| [Atşo](/encyclopedia/atsho) 34 | Ateş bekçisi; IV'te kutlu ateşi köz kabında batıya taşır | I, IV | Kurgu | Kısık, mikrofona yakın; ses seçimi kullanıcıda; ses henüz yok |
| [Kujul](/encyclopedia/kujul) 49 | Demir Diş ustası | I | Kurgu | Çakıl, üç kelime; ses seçimi kullanıcıda; ses henüz yok |
| [Kantu](/encyclopedia/kantu) 61 | Arabacı nine, Mene'nin ninesi, Sazlık'ı satan | I, IV | Kurgu | Babushka Valya (`ZgfahluxUmUzBjjL81NN`): boğuk, hiç susmaz; ses henüz yok |
| [Mene](/encyclopedia/mene) 9 | Duymayan çoban kızı; Ku onun kulağıdır; IV'te on dört yaşında | I, IV | Kurgu | Konuşmaz ([K5](/docs/source/design/decisions#k5)): falsolu mırıltı kodla; ses yok |
| [Mundzuk](/encyclopedia/mundzuk) 38 | Baskın başı; Huyan Hatun'un ve Yimo'nun kardeşi: «Seni biz öldürmeyiz. Onlar öldürecek.»; ö. 15 Haziran 209 | I, II | Kurgu; ad dönem dışı | Seçilmedi; ses henüz yok |
| [Omarg](/encyclopedia/omarg) 34, [Sak](/encyclopedia/sak) 20, [Opia](/encyclopedia/opia) 33 | Gece nöbetçisi; Palak'ın son oğlu (Gün IV gecesi ekran dışında ölür, eldiveni Mete'dedir); dul ambar hırsızı | I; Opia IV | Kurgu | Seçilmedi; ses henüz yok |
| [Nandu](/encyclopedia/nandu) 40 | Usun at tüccarı; Usun söylentisi ve İmparator'un ölümü ondan gelir; Ulu Ocak pazarında bir kez eyerde kopuz çalar | I | Kurgu | Seçilmedi; ses henüz yok |
| [Yuan](/encyclopedia/yuan) 30 | Çiang madenci; Demir Diş'te görev yoldaşı; Çiang'ın Yanmayan Kölesi'ni anlatır | I | Kurgu | Seçilmedi; ses henüz yok |
| [Sarva](/encyclopedia/sarva) 18, [Tola](/encyclopedia/tola) 17 | Ardokşa'nın yeğeni; hasta esir (yaşarsa firari, II'den Ambarcı) | I; Sarva IV | Kurgu | Seçilmedi; ses henüz yok |
| [Miro](/encyclopedia/miro) | Yüeçi Kralı, Amaga'nın kardeşi; 17 Haziran 205'te batıya sürülür, yok edilmez | I (söz), IV | Kurgu | Ağır, sayıyla konuşur; ses henüz yok |
| [Qin Kai](/encyclopedia/qin-kai) | Tunghu'ya rehin verilen Yan generali; Uldın bir kez anar | I (söz) | Tarihî (秦開) | Ses yok |

```varlik
portrait_amaga, portrait_farnak, portrait_nanay, portrait_palak, portrait_ardoksha, portrait_atsho
portrait_kujul, portrait_kantu, portrait_mene, portrait_mundzuk, portrait_omarg, portrait_sak
portrait_opia, portrait_nandu, portrait_yuan, portrait_sarva, portrait_tola
```

**Kışlak'ın halkı ve kodla kişi (2026-11-09, [folk-generator](/roadmap#item-folk-generator)).** Kendi Meshy modeli olmayan kişiler (Uldın, Berik, Omarg, Sak, Opia, Nandu, Yuan, Sarva, Tola, iki yapı eri) ve Kışlak'ın adsız halkı (pazarın 40 kişisi, Çukur'un 31 esiri, nöbetçiler) kodla kurulur: tek iskelet, var olan kalabalık modelleri (Hun eri, Hun kadını, pullu yelekli atlı) ve klip kütüphanesi; ten ve saç halkın renginde, giysi kişinin renginde boyanır. Görünüş tohumdandır, aynı kişi her açılışta aynıdır. Halklar Yüeçi (kızıl, aşı, sarı, krem kaftan; sivri Saka başlığı), Hun (kahve ve boz; kürk başlık ya da açık baş), Çiang (koyu zeytin ve boz; bant) ve Usun'dur (Nandu'nun yeşili). Kalabalık giysisi soğuk renk bandının dışında kalır: Mete pelerininden seçilir. Uzaktaki kişi kukla ve karttır ([Ordu ve Toplu Savaş](/docs/gameplay/army#yol-haritasi)). Adlı erin portresi aynı görünüşten pişer. Tanım: [act1.md §3](/docs/source/design/act1#3-kadro).

## II. Perde: Ok Neyi Gösterirse

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Yimo](/encyclopedia/yimo) | Huyan Hatun'un küçük kız kardeşi, Teoman'ın genç hatunu; 209'da Mete'nin hatunu; III'te Tunghu'ya verilir, baskında döner; V'te Baideng hatunu; Lan Hatun'dan sonra Kâhya; Yitu'nun anası | II–VI | Kurgu; kişi SJ 110 所愛閼氏 | Kuru, alçak, ölçülü; ses henüz yok |
| [Dulongçi](/encyclopedia/dulongchi) | Eski Binbaşı, Teoman'ın binbaşısı, altmışında; on bini getirir; V→VI Kroniği'nde ölür | II–V | Kurgu; ad HS 94A ve 94B 都隆奇 | Sert, kısa; ses henüz yok |
| [Moyan](/encyclopedia/moyan), [Guşi](/encyclopedia/gushi), [Şulü](/encyclopedia/shulu) | Ambarcı (Lan soyundan dul); Keşif Eri (III'te Gözcü Konakları'nın başı); Seyis (V'te dört rengi sayar) | II–VI | Kurgu; adlar HS 94A ve 94B | Sayıyı cümlenin sonuna saklar; az konuşur, eliyle gösterir; atı yürüyüşünden sayar; ses henüz yok |
| [Yudan](/encyclopedia/yudan), [Huluzi](/encyclopedia/huluzi) | Yaycı (ıslıklı oku oyar; III'ten Okçu Yurdu'nun ustası); Kılıç Ustası (Uldın yoksa gelir) | II–VI; Huluzi II ya da III–VI | Kurgu; adlar HS 94A | Kendi kendine ıslık çalar; kısa, sert; ses henüz yok |
| [Şidu](/encyclopedia/shidu) | Avlu kamı: «Ölü Tanhu kızgın.» | II–III | Kurgu; ad HS 94B, iş HS 94A 胡巫 | Kısık ve törensel; ses henüz yok |
| [Şiuşun](/encyclopedia/shiushun), [Ruodi](/encyclopedia/ruodi), [Dutu](/encyclopedia/dutu) | İlk ailelerin başları: onluk eri ve dülger; Oba'nın demircisi | II–VI; Dutu II–IV | Kurgu; adlar HS 94B | İş sözleri altyazı; Dutu üç sözcük |

## III. Perde: Boş Toprak

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Tuçi](/encyclopedia/tuchi) | Töreci; Sayım Çetelesi'ni tutar | III–VI | Kurgu; ad SJ 110 屠耆 «bilge» | Yavaş, örnekle konuşur; ses henüz yok |
| [Kebi](/encyclopedia/kebi) | Tunghu Kralı; at, hatun, toprak ister; 26 Eylül 208'de ölür, ekran dışı | III | Kurgu; kişi SJ 110 東胡王 | Yüksek, alaycı, kısa; ses henüz yok |
| [Tadun](/encyclopedia/tadun), [Nanlou](/encyclopedia/nanlou) | Tunghu elçisi; Vuhuan Dağı'na çekilenlerin başı (haracı yılda 20 deri) | III; Nanlou Kronik | Kurgu; adlar HHS 90 | Alaycı, yavaş; Nanlou'da ses yok |

## IV. Perde: Borç

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Yitu](/encyclopedia/yitu) | Mete'nin Yimo'dan oğlu, d. 14 Eylül 205; Sağ Bilge Kral; 177'de Han sınırını bozar, ceza olarak Yüeçi'ye gider, 176'da yener | Kronik (doğum), VI | Kurgu; makam tarihî (右賢王) | Sert, sabırsız; ses henüz yok |
| [Sungur](/encyclopedia/sungur) | Kuşçu, Altay'dan konuk usta; Mete'ye doğanını verir | IV–VI | Kurgu | Ses henüz yok |
| [Liuli](/encyclopedia/liuli) | Dangyu'nun ardılı: IV'te Xubu armağan hanesiyle dokuz yaşında gelir, VI-a'da çırak, VI-b'den Otacı Yurdu'nun ocak kamı ve otacısı | IV, VI | Kurgu; ad HS 94B 留犁 «kaşık» | Genç, ölçülü; ses henüz yok |
| [Loufan Kralı](/encyclopedia/loufan-king), [Baiyang Kralı](/encyclopedia/baiyang-king) | Ordos'un iki kralı; 25 Haziran 203 Lung-çeng'inde katılırlar: «Okumuz senin olsun, otumuz bizim kalsın.» | IV–VI | Tarihî makam; ad yok | Ağır, pazarlıkçı; ses henüz yok |
| [Xiang Yu](/encyclopedia/xiang-yu) | Çu'nun önderi; Loufan okçusu onun bakışından kaçmıştır | IV (söz), Kronik | Tarihî (項羽) | Ses yok |

## V. Perde: Dört Renk

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Nangçi](/encyclopedia/nangchi) | Sefer kamı: yol laneti | V | Kurgu; ad HS 94B | Davul altında sert; ses henüz yok |
| [Liu Bang](/encyclopedia/liu-bang) | Han'ın kurucusu; Baideng'de kuşatılır; ö. 1 Haziran 195 | V, VI (Kronik) | Tarihî | Kaba, gülen, halk ağzı; ses henüz yok |
| [Chen Ping](/encyclopedia/chen-ping), [Liu Jing](/encyclopedia/liu-jing) | Hatuna gizli armağanın sahibi; gizlenen sürüyü gören, savaşa karşı çıkıp zincire vurulan, heqin'i öneren | V; Liu Jing VI | Tarihî (SJ 56, SJ 99) | Yumuşak, hesaplı; dik, açık sözlü; ses henüz yok |
| [Zhao Li](/encyclopedia/zhao-li), [Manqiu Chen](/encyclopedia/manqiu-chen) | Han Xin'in komutanları; Zhao Li Wang Huang'la sözleşir, gelmez | V, Kronik | Tarihî (SJ 93, SJ 110) | Han ağzı; ses henüz yok |
| [Zang Tu](/encyclopedia/zang-tu) | Yan kralı, Zang Yan'ın babası; 202'de Liu Bang'a ayaklanıp yenilir; oyunda görünmez, oğlunun sözünde anılır | V (söz) | Tarihî (臧荼, SJ 93) | Ses yok |

## VI. Perde: Sayım

| Kişi | Kim ve rolü | Perdeler | Tarih | Ses |
|---|---|---|---|---|
| [Nan](/encyclopedia/nan) | Houyilu beyi; Yitu'yu kışkırtır; yazgısı oyuncunundur | VI | Tarihî (SJ 110 後義盧侯難氏) | Yumuşak, kaygan; ses henüz yok |
| [Kunmo](/encyclopedia/kunmo), [Nandoumi](/encyclopedia/nandoumi) | Usun bebeği: 4 Haziran 176'da getirilir, Hunlar büyütür, bir Tanhu ölünce halkını uzağa götürür; öldürülen babası Usun beyi (söz) | VI, Sonsöz | Tarihî (SJ 123, HS 61); yıl ve Tanhu kurgu | Ses yok |
| [Dingling ozanı](/encyclopedia/dingling-singer) | Kunduz'un ninesi; 198 Lung-çeng'inde uzun çekilen ezgiyi söyler | VI | Kurgu; ezgi Wei Shu 103 (geç tanık) | Sözsüz ezgi |
| [Lu Wan](/encyclopedia/lu-wan), [Chen Xi](/encyclopedia/chen-xi) | Yan kralı, Zhang Sheng'in efendisi, 29 Haziran 195'te binlerce adamıyla sığınır; 197 güzünde ayaklanan Han beyi (Kronik) | VI, Kronik | Tarihî (SJ 8, SJ 93) | Han ağzı; ses henüz yok |
| [Fan Kuai](/encyclopedia/fan-kuai), [Ji Bu](/encyclopedia/ji-bu) | Lü'nün avlusunda: Fan Kuai savaş ister, Ji Bu karşı çıkar | VI (Kronik) | Tarihî | Han ağzı; ses henüz yok |
| [İmparatoriçe Lü](/encyclopedia/empress-lu), [İmparator Wen](/encyclopedia/emperor-wen) | 192 mektubunu alan, 180'de ölen imparatoriçe; 174'te cevap veren imparator | VI | Tarihî | Soğuk, ölçülü; sakin, nazik; ses henüz yok |
| [Guan Ying](/encyclopedia/guan-ying), [Yi](/encyclopedia/han-envoy-yi), [Jian](/encyclopedia/han-envoy-jian) | 177'de 85.000 araba ve atlıyla yollanan Han komutanı; 174'te cevabı getiren iki Han elçisi | VI | Tarihî (SJ 110) | Guan Ying'de ses yok; elçiler resmî; ses henüz yok |
| [Han prensesi](/encyclopedia/han-princess) | Heqin'le gelir, adsız | Kronik, VI | Tarihî kişi, adsız | Az söz; ses henüz yok |
| [Han Ying](/encyclopedia/han-ying) | Han Xin'in torunu, Tuidang'ın yeğeni; Hun ülkesinde doğar; 166'da Tuidang'la Han'a geçer | VI-c, Sonsöz | Tarihî (韓嬰, SJ 93); sahnesi kurgu | Genç; ses henüz yok |

## Sonsöz: Kopuz Susar

Sonsöz'de Çocuk kırk iki yaşında bir kadın ozandır ve Yoğ Aşı'nda çalar; Jiyu Tanhu olur; kucakta iki yaşında Kunmo vardır; Son Sayım kartı yoldaşların satırlarını okur, «yıllar sonra» kartlarında Tuidang ve Bujiu görünür. Yeni kişi yalnız [Zhonghang Yue](/encyclopedia/zhonghang-yue)'dir: prensesle gelen hadım, Tanhu'nun adamlarına sayımı yazmayı öğretir (SJ 110 疏記). Tarihî; sesi kâtip sesidir, ses henüz yok.

## Yoldaşlar

Serbest dolaşımda Mete'nin yanında en çok 10 yoldaş gezer; her birinin kendi portresinden yuvarlak bir kartı vardır ([K70](/docs/source/design/decisions#k70)). Kadro 16 kişidir: 12 çekirdek (üç adımlı kişisel görev, üç kamp sahnesi, sahne sesi) ve 4 konuk (hikâyeye bağlı kısa görev, gönderilemez); 9'u kaynakta geçen kişi, 7'si kurgu ([K71](/docs/source/design/decisions#k71)). Yaş katıldığı yıldadır. Kurallar ve kart: [Yoldaşlar](/docs/gameplay/companions).

| Kişi | Halk, kademe | Rol | Katılış → son | Tarih | Ses notu |
|---|---|---|---|---|---|
| [Uldın](/encyclopedia/uldin), 36 (210) | Hun, çekirdek | Güreşçi: kısa kılıç ya da balta; Bıçak dalının ustası | I'de görev yoldaşı ve Son Gece firarisi, II'de çekirdek → VI-a'da yüzbaşı ya da Sonsöz | Kurgu; ad sonraki Hunlardan | Alçak bariton |
| [Berik](/encyclopedia/berik), 19 (210) | Hun, çekirdek | Keşif eri: sapan, bıçak, pusu | Son Gece firarisi, II'de çekirdek; ya da IV-A'da Kışlak'ta → V'te hane başı ya da Sonsöz | Kurgu; ad sonraki Hunlardan | Hızlı tenor, Yüeçi sözcükleri |
| [Luhun](/encyclopedia/luhun), 24 (209) | Hun, çekirdek | Okçu: atlı okçu, art arda iki ok | II → II'de ölüm (oyuncunun hükmü) ya da VI-a'da Jiyu'nun onluğunun onbaşısı | Kurgu | Yumuşak |
| [Mijia](/encyclopedia/mijia), 22 (208) | Tunghu, çekirdek | İz sürücü: boynuz yay, kapan | III, 1 Ekim 208 → VI-a'da Tunghu hanelerinin başı ya da Sonsöz | Kurgu; ad Xianbei kaydından | Alçak, yavaş |
| [Dangyu](/encyclopedia/dangyu), 52 (205) | Hun, çekirdek | Otacı ve ocak kamı: savaşmaz, düşeni kaldırır | IV → VI-b'de ocağına çekilir; 186 kışı ölür | Kurgu | Yaşlı ve sakin |
| [Loufan okçusu](/encyclopedia/loufan-archer), 31 (203) | Loufan, çekirdek | Keskin nişancı; lakabını Mete verir: Kiriş, Gez ya da Temren | IV-B, 25 Haziran 203 → Sonsöz ya da VI-a'da Loufan sancağına subay | Olay tarihî (SJ 7); adı ve Hun'a geçişi kurgu | Alçak, göz kaçıran |
| [Kozı](/encyclopedia/kozi), 30 (203) | Baiyang, çekirdek | At terbiyecisi ve Ordos kılavuzu | IV-B → V sonunda ırmak otlağına; VI-c'de yeniden alınabilir | Kurgu; lakap | Atlara ıslıkla konuşur |
| [Kunduz](/encyclopedia/kunduz), 19 (201) | Dingling, çekirdek | Avcı: avcı yayı, kapan, uzun ezgi | V → VI-d ya da VI-e'de kuzeye | Kurgu; lakap | Genç; ezgisi sözsüz |
| [Zang Yan](/encyclopedia/zang-yan), 27 (201) | Yan, çekirdek | Danışman: Han işleri, Han kılıcı | V → VI-b ya da VI-c'de güneye, dönmez | Tarihî (臧衍, SJ 93); Mete'yle bağı kurgu | Eğitimli, kırgın |
| [Jiyu](/encyclopedia/jiyu), 15 (198) | Hun, çekirdek | Veliaht: atlı okçu | VI-a → Sonsöz'de Tanhu; ayrılmaz, subay olmaz | Tarihî (稽粥) | İki ses yaşı |
| [Zhang Sheng](/encyclopedia/zhang-sheng), 44 (192) | Yan, çekirdek | Kâtip: savaşmaz | VI-b, kâtip adayı o seçilirse → VI-d'de ocağına çekilir | Tarihî (張勝, SJ 93) | Ölçülü, ince |
| [Tuidang](/encyclopedia/tuidang), 24 (177) | Han-Hun, çekirdek | Dilmaç: atlı okçu ve Han kılıcı | V'te doğar; VI-c → 166'da Han'a geçer («yıllar sonra») | Tarihî (穨當, SJ 93) | İki dilli, sakin |
| [Han Xin](/encyclopedia/han-xin), 45 (201) | Han, konuk | Konuk komutan; general Han Xin değildir | V → kendi ordusuna; 13 Mart 196'da ölür | Tarihî (韓王信) | Yorgun, kuşkulu |
| [Wang Huang](/encyclopedia/wang-huang), 50 (201) | Han, konuk | Konuk tüccar: arbalet | V → ordusunu getirmeye gider, gelmez; 196'da adamları onu teslim eder | Tarihî (王黃, SJ 93); seçilen son kurgu | Güler yüzlü, pazarlıkçı |
| [Xi Huqian](/encyclopedia/xi-huqian), 52 (176) | Hun, konuk | Konuk elçi: hafif yay | VI-d → armağanla yola çıkar; 20 Temmuz 176'da sınırda | Tarihî (係雩淺, SJ 110) | Sabırlı, az söz |
| [Bujiu](/encyclopedia/bujiu), 44 (176) | Usun, konuk | Konuk koruyucu: mızrak | VI-d → Kunmo'nun yanında kalır, «yıllar sonra» onunla batıya | Tarihî (布就翖侯, HS 61); Mete'yle bağı kurgu | Ağır, alçak |

- **Ölüm.** Çekirdek yoldaş ve konuk oynanışta ölmez: Düşüş zarı atmaz, bedel zaman ve yaradır ([K74](/docs/source/design/decisions#k74)). Hikâyede ölüm yalnız Luhun (II, oyuncunun hükmü), Han Xin (196), Wang Huang (196) ve Dangyu'dur (186).
- **Açık yoldaş** en çok: II 3, III 4, IV 7, V 9 ve 2 konuk (on yuva ilk kez dolar), VI dilime göre 3–9. I. Perde'de serbest parti yoktur: Ku (Gün II–V), bir görev yoldaşı (Uldın, Berik ya da Yuan) ve Son Gece'nin firarileri (en çok 10 kart).
- **Tanhu 1 sınırı.** Loufan okçusu erkektir, eş adayı değildir; çocukluk arkadaşı Luhun onbaşı olarak başlamaz; yaycı ve seyis usta kalır; sevdiği eş Yançi yoldaş olmaz.
- **Ses.** 16 yoldaşın sesi kullanıcının seçimidir; tasarım her birine kütüphaneden iki üç aday önerir, örnek dinleme kredisizdir, çekim o perdenin metni kilitlenince yapılır. Ses henüz yok.

```varlik
portrait_uldin, portrait_berik, portrait_luhun, portrait_mijia, portrait_dangyu, portrait_loufan_archer
portrait_kozi, portrait_kunduz, portrait_zang_yan, portrait_jiyu, portrait_zhang_sheng, portrait_tuidang
portrait_han_xin, portrait_wang_huang, portrait_xi_huqian, portrait_bujiu
```

## Tanrılar

Mitoloji kurgu listesine girmez (K13). Tanrılar görünmez ya da en çok iki cümle konuşur ([K35](/docs/source/design/decisions#k35)). Konuşmayan öteki mit ögeleri ([Ülgen](/encyclopedia/ulgen), [İyeler](/encyclopedia/iyeler), [Demirkazık](/encyclopedia/demirkazik), [Toybodım](/encyclopedia/toybodim), [Körmös](/encyclopedia/kormos)), çağları ve oynanışa bağlanışları: [Mitoloji](/docs/story/mythology).

| Kişi | Kim ve rolü | Perdeler | Kaynak çağı | Ses |
|---|---|---|---|---|
| [Tengri](/encyclopedia/tengri) | Gök; görünmez, tek sözcük («Gör.»); Kut onun ekseni, «Göğün rızası»dır | I, II–VI | Hun çağı (撐犁, HS 94A) | Connery (`AyUH0Pu6NRwQV6bOdfNx`): sesli, kaynağı görünmez, geniş yankı; söz altyazıyla da yazılır; A dilimi; ses henüz yok |
| [Kayra Han](/encyclopedia/kayra-han) | Önsöz'ün mitinde Tengri'nin Altay adı; Kişi'ye Erlik adını verir | Önsöz | Radloff, «Ozan der» | Ses yok; anlatıcı anlatır |
| [Erlik](/encyclopedia/erlik) | Borcun sahibi: Önsöz'de yüzsüz Kişi, I'de Teoman'ın yüzüyle, VI'da Kıl Köprü'nün ucunda Mete'nin yüzüyle; Hun ağzında Kara Nama | Önsöz, I, II ve IV (ses ya da sayı), VI | Söz 8. yy; figür geç | Kall (`ZaovTqhD16YvmEG2nDUD`): ateşten gelen alçak ses, acelesiz, vade sayar gibi; ansiklopedi tanıtımı var (başka sesle) |
| Erlik'in oğulları | [Bay Mattır](/encyclopedia/bay-mattir), [Karaş](/encyclopedia/karas-han), [Kerey](/encyclopedia/kerey-han), [Uçar](/encyclopedia/uchar-han), [Yabaş](/encyclopedia/yabash-han), [Kömür](/encyclopedia/komur-han), [Temir](/encyclopedia/temir-han), [Şıngay](/encyclopedia/shingay-han), [Padış](/encyclopedia/padish); Erlik'in Yolu kartı her kullanımda birini anar | II–VI (kart) | Anohin, «Ozan der» | Ses yok |
| [Umay](/encyclopedia/umay) | Görünmez, konuşmaz: eş, beşik, Düşüş'ün Umay Eşiği; I'de Mene'nin çevresinde altın titreşim | Önsöz, I–VI | «Taştan» | Ses yok ([K36](/docs/source/design/decisions#k36)) |
| [Yer-Sub](/encyclopedia/yer-sub), [Od Ana](/encyclopedia/od-ana) | Yerin ve suyun iyeleri (Taş Yığını, «Yer küstü»); ateşin anası (ateş yasakları, Ocağa Pay, Köz Kabı) | Önsöz, II–VI | «Taştan»; «Ozan der» | Ses yok |
| [Al Karısı](/encyclopedia/al-karisi) | Loğusa ruhu: doğum yurdunda ocak taşını geçemez | Önsöz, III–VI | «Ozan der» | Ses yok |
| [Bayanay](/encyclopedia/bayanay), [Yol Tengrisi](/encyclopedia/yol-tengrisi) | Avın iyesi (Av Payı, Kopuz Gecesi); «Benekli Atlı» (yol olayı, perdede bir kez) | II–VI | «Ozan der»; Irk Bitig «Taştan» | Ses yok |

```varlik
portrait_tengri, portrait_kayra_han, portrait_erlik, portrait_erlik_sons, portrait_umay
portrait_yer_sub, portrait_od_ana, portrait_al_karisi, portrait_bayanay, portrait_yol_tengrisi
```

## Hayvanlar

| Hayvan | Ne | Perdeler | Tarih |
|---|---|---|---|
| [Adak Aygırı](/encyclopedia/offering-stallion) | Küllü boz, sırtında kara yol; Yüeçilerin adağı, Hun ağzında ıduk; Mete çaldığı an adını seçer: Küldoru, Tanyeli ya da Arkvi | I–VI | Kurgu |
| [Yakve](/encyclopedia/yakwe), [Erkent](/encyclopedia/erkent) | Yaşlı kısrak: «Adı Yakve. Bizim dilde "at" demek. Ne bekliyordun?»; Farnak'ın kara kısrağı | I | Kurgu |
| [Ku](/encyclopedia/ku), [Karabaş](/encyclopedia/karabash) | Mene'nin köpeği, onun kulağı, oyunun ilk takipçisi; Teoman'ın çoban köpeğinin yavrusu, Mete'nin köpeği | I; Karabaş II–VI | Kurgu |
| [Bin li'lik at](/encyclopedia/thousand-li-horse) | Teoman'ın atı; II'de son avda binilir, III'te Tunghu'ya verilir; ozan Tülpar diye anar | II, III | Tarihî (頭曼時有千里馬) |
| Doru, Akbulut; yaşlı koyun | Ana kampın iki atı (Godot'da «Doru At», «Ak At»); Çocukluk'un bineği | Serbest Gez; Çocukluk | Kurgu |
| Doğan, kartal; yoldaş binekleri | Sungur'un verdiği doğan, yuvadan gelen kartal; 13 at, 2 binek deve, 1 binek katır | IV–VI; II–VI | Kurgu |

Hayvanlar ses almaz; Ku'nun havlaması efekttir. Türler ve davranış: [Hayvanlar](/docs/world/animals).

```varlik
offering_stallion, yakwe, erkent, ku, karabash, thousand_li_horse
horse_brown, horse_white, sheep, falcon, eagle
```

## Adı olmayanlar

Önceki kadroda adı ve tanımı olmayan kişilere yeni senaryo ad verdi ([K37](/docs/source/design/decisions#k37)): Mete'nin anası Lan Hatun, gözde hatun Huyan Hatun, küçük oğul Gutu, sevdiği eş Yançi, Tunghu Kralı Kebi, Tunghu'ya verilen hatun Yimo; ustalar Moyan, Guşi, Şulü, Yudan, Huluzi, Tuçi; Eski Binbaşı Dulongçi. Adsız kalanlar bilerek adsızdır:

| Kişi | Neden adsız |
|---|---|
| Sayıcı | Kişi değil, iştir: Dailin'in sayıcısı (SJ 110 課校人畜計) |
| Lan soyundan iki kadın, Nanay'ın oğlu | Doğum sahnesinin yardımcıları; IV'te beş yaşında sözsüz çocuk |
| Loufan Kralı, Baiyang Kralı | Kaynakta kişi adı yoktur; makam tarihîdir |
| Han prensesi | Kaynak adını vermez |
| Loufan okçusu | Adını kaynak vermez; lakabını Ordos Dailin'inde oyuncu seçer |
| Adı bilinmeyen firari | I. Perde'nin Son Gece'sinde portresiz siluettir |

## Adların kaynağı

1. **Hun.** Soyadı yoktur; soylu hatunlar soyuyla anılır (Lan Hatun, Huyan Hatun). Kurgu adlar Han kaynaklarına geçmiş Hun ad ve sözlerinden kurulur, Türkçe okunan pinyinle ve tiresiz yazılır: Gutu (孤塗 «oğul»), Yimo, Luhun, Yitu, Şidu, Nangçi, Dangyu, Liuli (留犁 «kaşık»), Yançi (焉支).
2. **Yüeçi.** Saka-İran (Amage, Farn, Palakos), Kuşan tanrı adları (Nana, Ardoxsho, Athsho, Miiro) ve Toharca sözler (*kantwo* dil, *meñe* ay, *yakwe* at, *ārkwi* parlak, *ku* köpek). Yüeçi ile Toharca bağı kurgu tercihidir.
3. **Tunghu.** Vuhuan ve Xianbei kayıtları: Kebi (軻比能'den), Tadun, Nanlou, Mijia (彌加).
4. **Han, Ç'in, Usun.** Tarihî kişiler kendi adlarıyla, pinyin.
5. **Dönem dışı adlar.** Hereka, Uldın, Berik, Eskam, Mundzuk ve ana kampın Oktar, Erka, Dengiz adları 5. yy Avrupa Hunlarındandır. Kalırlar, Destan'da «adı sonraki Hunlardan» notunu taşırlar; yeni ad bu kaynaktan alınmaz.
6. **Loufan, Baiyang, Dingling.** Kaynakta kişi adı yoktur, lakap kullanılır: Kozı (Eski Türkçe «kuzu»), Kunduz.
7. Tanhu 1'in adları kullanılmaz; uydurulan her kişi kurgu listesine girer, mitoloji girmez (K13). Yazım kuralları: [Tarih ve Kaynaklar](/docs/story/history-sources#ad-kurallari).

## Görünüş kuralları: kopuz ve pelerin

- **Ozanın kopuzu ([K60](/docs/source/design/decisions#k60)).** Üç telli, perdesiz, parmakla çalınan, deri göğüslü uzun saplı lavta; ezgi bir telde, öteki teller dron, aynı anda en çok üç tel; Batı akoru ve mızrap yoktur. Dombra, komuz, topşur ve saz oyunda geçmez; yaylı kıl kobuz kamın çalgısıdır, Mete'nin çağında elde görünmez, yalnız sesi duyulur. I. Perde'de kopuz dünyada bir kez görünür: Nandu Ulu Ocak pazarında eyerde çalar (Gün II–IV, ≈5 sn). Godot'da ozanın elinde üç telli Meshy kopuzu var (2026-11-06; 40 kredi); göz onayın [Karar Bekleyenler](/docs/general/pending-decisions)'dedir.
- **Mete'nin pelerini ([K58](/docs/source/design/decisions#k58)).** Renk tek yerden gelir: eşya ve seçilen boya; kaftan pelerini boyamaz. Varsayılan Göl Mavisi `#2a6f8c`'dir; oluşturucu altı soğuk boya sunar. Soğuk renk bandı kalabalık giysisinde yasak, adlı kişide serbesttir: Mete kalabalıkta pelerininden seçilir. Giysiler «Kışlak Kaftanı» ve «Kışlak Pelerini»dir. Ayrıntı: [Çocukluk: Koyun Sırtında](/docs/story/childhood).

## Sesler

Bugün var olan sesler yalnız bunlardır; öteki sesler üretildikçe eklenir.

| Kim | Ne | Ses | Dinle |
|---|---|---|---|
| Anlatıcı | N1: «Before there were empires of grass…» | Eldrin | ![N1](/media/docs/media/audio/vo/en/act0.narr.1.mp3) |
| Anlatıcı | N2: «When Mete was eighteen, the Qin raised a wall…» | Eldrin | ![N2](/media/game/audio/vo/prologue/act0.narr.2.mp3) |
| Anlatıcı | N3: «… the Yuezhi flourished …» | Eldrin | ![N3](/media/game/audio/vo/prologue/act0.narr.3.mp3) |
| Anlatıcı | N4: «He had an heir called Mete…» | Eldrin | ![N4](/media/docs/media/audio/vo/en/act0.narr.4.mp3) |
| Anlatıcı | N5: «So the Tanhu made peace with the Yuezhi…» | Eldrin | ![N5](/media/docs/media/audio/vo/en/act0.narr.5.mp3) |
| Anlatıcı | N6: «Mete rode west with no army and no bow. At the gate they tied a bell…» | Eldrin | ![N6](/media/game/audio/vo/prologue/act0.narr.6.mp3) |
| Anlatıcı | N7: «History remembers the Tanhu he became…» | Eldrin | ![N7](/media/docs/media/audio/vo/en/act0.narr.7.mp3) |
| Ozan | Kopuzlu şarkı, iki dize, çekim 3104, 26,85 sn; kullanıcı dinleyip seçti ([K95](/docs/source/design/decisions#k95)) | Eleven Music | ![Ozanın şarkısı](/media/docs/media/audio/vo/en/act0.bard.song.mp3) |
| Erlik | Ansiklopedi tanıtımı: «I am Erlik, lord of the world below. Every breath that leaves the steppe comes down to my river in the end.» | Lucifer | ![Erlik Han'ın tanıtımı](/media/docs/media/audio/vo/en/ency.erlik.mp3) |

- **Köprü satırları.** N2, N3 ve N6 yeniden yazıldı, yeni çekimlerini bekler; yeni metinleri [Çocukluk: Koyun Sırtında](/docs/story/childhood) sayfasında, kaynağı [act0-text.md](/docs/source/design/act0-text#kopruler-act0-narr-1-act0-narr-7)'dedir. Önsöz'ün mit ve doğum satırları henüz çekilmedi: [Önsöz: Kopuz Söyler](/docs/story/prologue).
- **Tanıtım sesleri (K86).** Ansiklopedide kişinin başlığının yanında hoparlör durur; kişi kendini iki cümleyle tanıtır, söylenen İngilizce, Türkçesi altyazıdır. Tanıtım sesleri ansiklopedide dinlenir; bugün yalnız [Erlik Han](/encyclopedia/erlik)'ınki var. Erlik'in tanıtımı başka bir sesledir (Lucifer), oyunun Erlik sesiyle (Kall) yeniden okunur. Ses kişinin oyundaki konuşma sesidir: sesi seçilmiş on bir kişinin (Mete, Teoman, Ozan, Hereka, Eskam, Amaga, Farnak, Nanay, Palak, Kantu, Erlik) tanıtımı o sesle okunur, ötekilere kütüphaneden ses seçilir. Bedel karakter başına 1 kredi, kişi başına ≈110; her üretim turu önce toplamıyla sorulur.
- **Seçilen ama henüz çekilmeyen sesler.** Mete Arthur, Teoman Bariton king, Erlik Kall, Tengri Connery, Amaga Elinor, Farnak Revenant, Nanay Aisyah, Palak Piotr, Kantu Babushka Valya, Eskam Roland Lescalde; ozanın oyun içindeki sözü David. Satırlar perde metni kilitlenince çekilir (K61).
- **Ses seçimi kullanıcıda.** I. Perde'nin Ardokşa, Kujul ve Atşo'su, Çocuk (genç ozan ve Sonsöz'ün ozanı) ve 16 yoldaş: [Karar Bekleyenler](/docs/general/pending-decisions). Sesi olmayanlar: Mene (K5), Umay (K36), hayvanlar.

> [!DURUM]
> Godot'da bugün: menünün gece kampında ateş başında beş kişi (Ana, Çocuk, Baba, Ağabey ve elinde kopuzu olan ozan), ahırda iki at. Önsöz'ün doğum sahnesinde Lan Hatun, 39 yaşındaki Hereka, Teoman, Sayıcı ve iki Lan kadını oynar. Çocukluk'ta küçük Mete, çocuk Yançi ve Luhun, Lan Hatun, Sayıcı ve uzaktan bakan Teoman oynar; sözleri altyazıdır. Destan Kitabı'nın Kişiler sayfası ansiklopedi düzenindedir, kayıtları sitenin ansiklopedisinden gelir, konuşan kişilerde tanıtım sesi çalar. Meshy modeli olan 18 kişi: ilk turun altısı (Mete, Ana, Baba, Çocuk, Ozan, kadın kahraman), Önsöz'ün dokuzu (Teoman, Lan Hatun, Ağabey, Hereka, 39 yaşındaki Hereka, Sayıcı, Hun Erkeği, Hun Kadını, Hun Atlısı) ve Çocukluk'un üçü (küçük Mete, çocuk Yançi, Luhun; 2026-11-07); klipleri [Animasyonlar](/animations)'da oynar. Yok: Yançi ve Luhun'un yetişkin hâlleri, Kışlak'ın adlı kişileri, yoldaşlar; I. Perde ve sonrasının satırları. Yol Haritası'nda: ateş başının kadrosu ([camp-cast](/roadmap#item-camp-cast)), Destan Kitabı'nın ansiklopedi görünümü ([epic-book-encyclopedia](/roadmap#item-epic-book-encyclopedia)), tanıtım sesleri ([intro-voices](/roadmap#item-intro-voices)), yoldaş varlıkları ([companion-assets](/roadmap#item-companion-assets)).

![Godot'da Destan Kitabı'nın bugünkü Kişiler sayfası](/media/docs/research/menu-shots/book_kisiler.jpg)

## Kaynaklar

- [story.md §8](/docs/source/design/story#8-kadro): [§8.1](/docs/source/design/story#8-1-kimlik-ve-kumeler)–[§8.11](/docs/source/design/story#8-11-perde-perde-kadro), [§14](/docs/source/design/story#14-kisiler-ii-vi-21-38-44)
- [act1.md §3](/docs/source/design/act1#3-kadro)
- [audio.md §5](/docs/source/design/audio#5-seslendirme-elevenlabs)
- `companions.md` §1 ve §2, [yoldaslar.md](/docs/source/research/companions)
- [act0-text.md](/docs/source/design/act0-text)
- [decisions.md](/docs/source/design/decisions): [K5](/docs/source/design/decisions#k5), [K6](/docs/source/design/decisions#k6), [K13](/docs/source/design/decisions#k13), [K35](/docs/source/design/decisions#k35), [K37](/docs/source/design/decisions#k37), [K58](/docs/source/design/decisions#k58), [K60](/docs/source/design/decisions#k60), [K61](/docs/source/design/decisions#k61), [K69](/docs/source/design/decisions#k69), [K70](/docs/source/design/decisions#k70), [K71](/docs/source/design/decisions#k71), [K74](/docs/source/design/decisions#k74), [K79](/docs/source/design/decisions#k79), [K84](/docs/source/design/decisions#k84), [K85](/docs/source/design/decisions#k85), [K86](/docs/source/design/decisions#k86)
- [mete-tarih.md §5](/docs/source/research/mete-history#5-yazim-birligi-9), [§6](/docs/source/research/mete-history#6-senaryo-malzemesi)
- [d3/register.md](/docs/source/design/d3/register): E4.4, E5

İlgili sayfalar: [Yoldaşlar](/docs/gameplay/companions), [Mitoloji](/docs/story/mythology), [Seslendirme](/docs/presentation/voice-over), [Hikâye Omurgası](/docs/story/spine), [Karar Bekleyenler](/docs/general/pending-decisions).
