# Bozkırın Hayvanları / Animals of the Steppe

Bu belge, kullanıcının ek isteğinin («Oyunda at ve deve olsun, çeşitli hayvanlar olsun: inek, koyun, geyik, köpek, kartal») araştırma tabanıdır ve `docs/design/fauna.md`'ye girdi verir. Demir Çağı'nda Moğolistan, Ordos, Hexi Koridoru, Altay, Gobi, Baykal ve Mançurya'da hangi hayvanların yaşadığını, Hunların onları nasıl kullandığını ve bu bilginin kaynak düzeyini yazar; sonra türleri oyunun var olan sistemlerine bağlar (K24 sürü, K23 yerleşim, K20 saat, K22 hava, K21 emek, K27 kamera, K3 kamp sınırı). Etiketler: [kaynak] kaynağı olan bilgi, [çıkarım] kaynaktan benim çıkarımım, [kurgu] oyun için öneri. «k.b.» kaynak bulunamadı, «#Ek» kullanıcının ek isteği demektir. Sanat ve kademe ayrıntısı `sanat-animasyon.md`'de, av inancı `mitoloji.md`'de, tarih çizelgesi `mete-tarih.md`'dedir; bu belge onlarla çakışmadan bağlanır. Tanhu 1'den hiçbir şey alınmaz: tanrısal kartal vuruşu (`gok_ok`), ruh kurdu, kuş boss (Kara Kuş), giyilen tüy ve post eşyaları (`kartal_tuyu`, `tilki_borku`) yoktur; `feather` ve `fur_big` yalnız ham maldır. Uygulama önerileri Three.js prototipinin adlarıyla yazıldı; oyun Godot 4.7'dedir (`game/`), karşılıklar öneri 22'dedir. Bağımsız doğrulama belgenin sonundadır.

## Özet

1. Shiji 110 tabandır: çok olan at, sığır, koyun; nadir olan deve, eşek, katır ve üç at benzeri tür. Kimlikler `economy.md` §3.11 ile aynı kalır, yeni satırlar hane sürüsünü değiştirmez. [kaynak]
2. Kazı listeyi genişletir. Ivolga'nın 1955–74 kemiklerinde köpek %29, koyun %22, sığır %17, domuz %15, at %12, keçi %4, deve ile yak birlikte %1'dir. Köpek ve domuz Shiji'nin listesinde yoktur. [kaynak]
3. Mezarlara baş, ayak, kuyruk ve post konur; at en son yerleştirilir. Gol Mod T20'de 16 at vardır, kesimler yazındır. [kaynak]
4. Kartalla av Hun çağı için belgeli değildir. Belgeli olan kartal vuran okçu (射雕者) ve kartallı taçtır. Doğanla atlı avın Hun çağına yakın bir görseli vardır: Xichagou tunç kemer tokası, Soma'ya göre MÖ 3. yy. Kuşçuluk bu sırayla açılır: doğan IV, kartal V [kurgu]. Savaşa girmez, kamerayı almaz.
5. Katalog 45 tür: 24 var olan (18 av, 5 sürü, köpek), 21 yeni. Çoğu yeni tür sekiz gövde planından parametreyle çıkar (`buildQuad`).
6. Av kuralı tek döngüdür: bölge stoğu, Pay Bırak, kopuz gecesi, Yer küstü. Kopuz gecesi gerçek bir geleneğe dayanır (Şor, Altay, Saha). [kaynak]
7. Kurt ekolojisi basit bir sayıya iner: yaban stoğu düşerse ve kış gelirse kurt sürüye döner. Aşırı av kendi koyununu vurur. [kaynak → çıkarım]
8. #39'un iki türü (yükünü getiren, yurt isteyen) beş görünüşle gelir: at yüklü, deve yüklü, arabalı, çadırlı, isteyen. `pack_camel` 30 Yük atın terkisinden azdır, 60 önerilir: bir deve bir Yurt Yükü taşır, eşyasıyla bir hane iki deve yükler. Gerçekte de bir yurt eşyasıyla iki üç deveye yüklenir.
9. Üç küçük tarih hatası düzelir: Aralık'taki Kışlak'ta tarbagan yok (kış uykusu), `deer` «Red Deer» değil Maral, kulan su başına gece iner.
10. K3 ile tek çelişki vardır: söz «iskeletli hayvan ≤6» olmalıdır. Yaban hayvanı iç haritada ≈65k üçgen ve ≤24 çizim tutar, `sanat-animasyon.md` payının içindedir (prototip ölçüsü; Godot bütçesi `godot.md` §7).
11. Godot'da dört ayaklının iskeleti Meshy'den gelmez: Meshy'nin rig API'si yalnız insansı alır. Yakındaki hayvan 16 kemikli kendi `Skeleton3D`'si ve `AnimationTree`'siyle, sürü `MultiMeshInstance3D` ve köşe gölgelendiricisiyle, uzak kademe görünürlük aralığıyla çizilir (öneri 22).

## 1. Birincil metinler

Çinli yazarların Hunlar hakkındaki satırları düşman gözüdür ve sayıları kuşkuludur. Listeler yine de tutarlıdır. [çıkarım]

### 1.1 Hun satırları

| Metin | Satır | Anlam | Oyun bağı |
|---|---|---|---|
| [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110) | 其畜之所多則馬、牛、羊 | Çok olan hayvanları at, sığır, koyun | Hane sürüsü |
| Aynı | 其奇畜則橐駞、驢、驘、駃騠、騊駼、騨騱 | Nadir hayvanları deve, eşek, katır ve üç tür | §1.2 |
| Aynı | 兒能騎羊，引弓射鳥鼠；少長則射狐兔：用爲食 | Çocuk koyuna biner, kuş ve fare vurur; büyüyünce tilki ve tavşan | `toy_bow`, hane av payı |
| Aynı | 因射獵禽獸爲生業 | Rahat zamanda geçim avla da olur | Av kolu |
| Aynı | 人食畜肉，飲其汁，衣其皮；畜食草飲水，隨時轉移 | Eti, sütü, derisi; sürü otla, suyla, mevsimle gider | K24 zinciri |
| Aynı | 冒頓盜其善馬，騎之亡歸 · 自射其善馬 · 射單于善馬 | Mete'nin üç at sahnesi | Adak Aygırı, II. Perde |
| Aynı | 欲得頭曼時有千里馬 | Tunghu bin li atı ister | III. Perde; yeni tür yok, aygır kullanılır (`mete-tarih.md`) |
| Aynı | 其西方盡白馬，東方盡青駹馬，北方盡烏驪馬，南方盡騂馬 | Baideng'de dört renk at | `four_winds`, `army.md` §7.4 |
| [Şerhli Shiji 110](https://zh.wikisource.org/wiki/史記三家註/卷110) | 獻橐他一匹，騎馬二匹，駕二駟 | Mektup armağanı: 1 deve, 2 binek, 8 koşum atı | VI. Perde |
| [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110) | 秋，馬肥，大會蹛林，課校人畜計 | Güzde at semizken insan ve hayvan sayımı | Dailin (#44) |
| [Shiji 109](https://zh.wikisource.org/wiki/史記/卷109) | 是必射雕者也 · 果匈奴射雕者也 | Üç seçkin Hun okçu: kartal vuranlar | `eagle_shooter` |
| [Hanshu 49](https://zh.wikisource.org/wiki/漢書/卷049) | 上下山阪，出入溪澗，中國之馬弗與也 | Yokuşta ve derede Han atı Hun atına yetişemez | `hun_pony` |
| [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下) | 刑白馬…共飲血盟 | Ant için ak at kesilir (Huhanye dönemi) | Ant sahneleri |

Sayılar: 127'de Ordos'tan «牛羊百餘萬» ([Shiji 110](https://zh.wikisource.org/wiki/史記/卷110)); MÖ 72–71'de beş Han ordusunun ganimeti 萬餘, 二千餘, 七千餘, 百餘 ve 七萬餘 baştır, sonuncusunu metin şişirilmiş sayar (詐增鹵獲) ([Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上)); MÖ 71'de Wusun baskınında «馬、牛、羊、驢、橐駝七十餘萬頭» ([Hanshu 96B](https://zh.wikisource.org/wiki/漢書/卷096下)). Hepsi Mete'den sonradır. Oran vermezler. Sıra hemen hep at, sığır, koyundur (bir satırda 牛馬羊); deve ve eşek yalnız büyük dökümde görünür. [kaynak, oran yorumu çıkarım]

### 1.2 Nadir altı hayvan

| Söz | Şerh | Oyun karşılığı |
|---|---|---|
| 橐駞 | Sırtı torba gibi ([Şerhli Shiji 110](https://zh.wikisource.org/wiki/史記三家註/卷110)) | `camel` [kaynak] |
| 驢 | | `donkey` [kaynak] |
| 驘 (騾) | 古今注: 驢牡馬牝 | `mule` [kaynak] |
| 駃騠 | Xu Guang «北狄駿馬»; Shuowen: 馬父驘子; yedi günlükken anasını aşar (Lienü zhuan) | `jueti`, seçkin melez binek [çıkarım] |
| 騊駼 | «似馬而青»; Ziling: yaban at | `takhi` [çıkarım] |
| 騨騱 (şerhli metinde 驒騱) | Shuowen «野馬屬»; «青驪白鱗» (adsız «一云») | `kulan` [çıkarım] |

Şerhler dört ila sekiz yüzyıl sonradır (Xu Guang MS 4.–5. yy, Sima Zhen ve Zhang Shoujie 8. yy); alıntıladıkları Shuowen MS 100 dolayındadır. Metin bunları «nadir hayvan» sayar, yabanı mı evcili mi belli değildir. Oyun son ikisini yaban sayar. [çıkarım]

### 1.3 Komşular

| Yer | Satır | Anlam | Bağ |
|---|---|---|---|
| Vuhuan ([HHS 90](https://zh.wikisource.org/wiki/後漢書/卷90)) | 肥養一犬…使護死者神靈歸赤山 | Besili köpek ruhu Kızıl Dağ'a götürür. Töre MS 1.–2. yy Vuhuan'ınındır; Vuhuan, Mete'nin yendiği Tunghu'nun artığıdır (烏桓者，本東胡也) | III. Perde sahnesi: Tunghu'ya geriye yansıtma [çıkarım] |
| Vuhuan | 歲輸牛馬羊皮 | Mete'den sonra Hun'a her yıl deri öderler | Haraç, öneri 4 |
| Vuhuan | 見鳥獸孕乳，以別四節 | Mevsimi kuş ve hayvanın doğumundan okurlar | Mene, hava işareti |
| Vuhuan | 獻奴婢牛馬及弓虎豹貂皮 | Kaplan, pars, samur postu armağan | `fur_big`, `sable` |
| Xianbei | 野馬、原羊、角端牛 · 貂、豽、鼲子 | Yaban at, dağ koyunu; samur, sincap benzeri kürk | `donghu_land` takımı |
| Fuyu, Yilou, Ye ([HHS 85](https://zh.wikisource.org/wiki/後漢書/卷85)) | 馬加、牛加、狗加 · 好養豕 · 祠虎以為神 | Unvan at, sığır, köpek; domuz besler; kaplana tapar | Elçi rengi, `pig`, `tiger` |
| Loulan ([Hanshu 96A](https://zh.wikisource.org/wiki/漢書/卷096上)) | 有驢馬，多橐它 · 多葭葦、檉柳、胡桐 | Eşek, at, çok deve; saz, ılgın, toğrak | `loulan` |
| Wusun ([Shiji 123](https://zh.wikisource.org/wiki/史記/卷123)) | 其富人至有四五千匹馬 | Zengin 4–5 bin at tutar | Ölçek |
| Yüeçi (Shiji 123) | 行國也，隨畜移徙，與匈奴同俗 | Sürüyle göçer, töresi Hun gibi | I. Perde |
| Hexi ([Hanshu 28B](https://zh.wikisource.org/wiki/漢書/卷028下), [şerh](https://zh.wikisource.org/wiki/史記三家註/卷110)) | 水屮宜畜牧…之畜為天下饒 · 匈奴失祁連、焉支二山 | Sürüsü ünlüdür; Çilyan yitince sürü üremez diye ağıt | `hexi_winter` |
| Kuzey ([Shiji 129](https://zh.wikisource.org/wiki/史記/卷129)) | 龍門、碣石北多馬、牛、羊、旃裘、筋角 · 畜至用谷量馬牛 | Kuzeyin malı hayvan, keçe, sinir, boynuz; sürü vadiyle ölçülür | Takas, ölçek |
| Baykal ([Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054)) | 掘野鼠 · 弋射 · 網紡繳 · 丁令盜武牛羊 | Su Wu fare yer, ağ örer; Dingling sürü çalar | `dingling_north` |
| Qiemo ([Bei Shi 97](https://zh.wikisource.org/wiki/北史/卷097)) | 風之所至，唯老駝預知之…埋其口鼻于沙中 | Yaşlı deve yazın sıcak rüzgârı önceden bilir, toplanır, ağzını kuma gömer (MS 5.–7. yy tanıklığı) | Hava işareti, öneri 12 |

## 2. Kazı

- **Egiin Gol (halk) ve Gol Mod (seçkin).** At, sığır, koyun, keçi; bu mezarlarda köpek yok, makaleye göre başka mezarlıklarda var. Çoğu zaman yalnız baş, bacak ucu ve sağrı konur, post başa sarılır. T18'de 17 hayvanın postu, dördü at; ikisinin ağzında gem. T19'da sıra sığır, dört keçi, sonra kemik gemli bir kısrak tayı. Gol Mod T20'de 16 at, 32 ön bacak, bir sığır başı; bakır alaşımlı kaplarda at ve koyun eti. Hayvanlar yazın kesilmiş. Mezarlar çoğunlukla Mete'den sonradır (T18 MÖ 2. yy–MS 1. yy, T20 MS 1. yy). Atlar «çok büyük değil», bugünkü Moğol atından ≈10 cm iri, Przewalski üst sınırında ([Martin, André, Desroches 2010](https://journals.openedition.org/archeopages/808?lang=es)). [kaynak]
- **Takhiltyn-khotgor, Shombuuzyn-belchir.** Beş atın başı ve ayağı odanın kuzeyinde; bir çukurda 15 küçükbaş (koyun ya da keçi) kafatası. At yalnız mezarda, sığır yalnız taş sırasında çıkar. Taş sıralarında yakılmış kemik vardır ([Miller ve ark. 2018](https://www.cambridge.org/core/journals/antiquity/article/stone-lines-and-burnt-bones-ritual-elaborations-in-xiongnu-mortuary-arenas-of-inner-asia/1A4636F94C9A10D2599280A59E2E7163)). [kaynak]
- **Ivolga (Selenga, surlu yerleşim).** 1955–74 kemikleri: %92,5 evcil. Köpek 29, koyun 22, sığır 17, domuz 15, at 12, keçi 4, deve ile yak birlikte 1. 2017 kazısında sığır %30,8, küçükbaş %23, at %12,7; avlananlarda karaca %19,3. Yetişkin kemik çoğunluğu at ve öküzün koşumda, ineğin sağımda kullanıldığını düşündürür. Bazı köpek kemiklerinde kesik izi var, 10–12 aylık kesim olabilir. Köpek boyu 49–69 cm, ağırlık 13–29 kg; kafatası laika tipi. Boynuz ve kemik işi karaca ve geyikten; kuş ve balık kemiği de çıkar ([Sizova, Klementiev, Sablin 2021](https://izvestiageoarh.isu.ru/en/article?id=267), Rusça tam metin). [kaynak] Ivolga yerleşik ve karışıktır, bozkır hanesini temsil etmez. [çıkarım]
- **Süt.** Moğolistan'da diş taşında süt ≈MÖ 3000'e, at sütü ≈MÖ 1200'e iner ([Wilkin ve ark. 2020](https://eprints.whiterose.ac.uk/159472)). Özet Hun örneğini ayrı yazmaz. [kaynak]
- **Görsel.** Aluchaideng tacı: tepede turkuaz kartal, altta koyun ısıran dört kurt, uçlarda kaplan, at, koyun; Savaşan Devletler, Hanggin, Ordos ([China Daily](https://govt.chinadaily.com.cn/s/202304/06/WS642e6fcc498ea274927b5b56/eagle-shaped-gold-crown-from-more-than-2-000-years-ago.html)). Gol Mod T20 koşum levhası: at başlı, çift toynaklı, yaban keçisi boynuzlu yaratık ([Martin ve ark.](https://journals.openedition.org/archeopages/808?lang=es)). [kaynak]

## 3. Evcil hayvanlar

- **At.** Moğol atı kışın karı kazıp otlar, kar yer, kışta ≈%30 kilo yitirir; çoğu serbest gezer, azı bağlanır; yazın kısrak günde altı kez sağılır ([Mongol atı](https://en.wikipedia.org/wiki/Mongolian_horse)). Boy: Moğol atı ≈122–142 cm, ortalama ≈1,28 m (FAO DAD-IS ve Porter ve ark. 2016, [Chinese Mongolian horse](https://en.wikipedia.org/wiki/Chinese_Mongolian_horse) üzerinden); [takhi](https://en.wikipedia.org/wiki/Przewalski%27s_horse) 122–142 cm. İngilizce Vikipedi'nin Mongolian horse sayfasındaki 142–152 cm öteki kaynaklarla ve Gol Mod ölçümüyle çelişir, kullanılmaz (`sanat-animasyon.md` §3 de böyle der). Gol Mod atı bugünkünden ≈10 cm iridir: ≈1,38 m [çıkarım]. Han yasası MÖ 146'da 五尺九寸 üstü atın sınırdan çıkışını yasaklar ([Hanshu 5](https://zh.wikisource.org/wiki/漢書/卷005)): Batı Han arşını 23,1 cm ile ≈136 cm ([Chinese units](https://en.wikipedia.org/wiki/Chinese_units_of_measurement)). Yasak sınırı Gol Mod atının boyuna denk düşer. [kaynak, cm ve denklik çıkarım] Prototipte at 1,74 m'dir, dünya ×1,18 büyüktür (`sanat-animasyon.md` §3). Godot'da `Horse` burundan kuyruğa 2,3 m, omuz ≈1,45 m'dir, Mete 1,82 m (`game/scripts/camp/horse.gd`, `game/tools/asset_plan.json`): oran gerçeğe yakındır, korunur. Üzengi dönem dışıdır (`sanat-animasyon.md` öneri 13).
- **Deve.** Yük 170–250 kg, 47 km/gün, 4 km/sa; sürekli ≈40, en çok 65 km/sa; yan yürüyüşle yürür (aynı yanın iki bacağı birlikte); −30 °C dayanır, kar yer ([Baktriya devesi](https://en.wikipedia.org/wiki/Bactrian_camel)). Bir yurt eşyasıyla iki üç Baktriya devesine yüklenir ([Three Camel Lodge](https://www.threecamellodge.com/10-surprising-facts-about-the-ger), turizm kaynağı). Karı kazar, kılı çadır ve giyecek, sütü mayalanır ([ADW](https://animaldiversity.org/accounts/Camelus_bactrianus/)). Evcilleşme yeri açıktır, Moğolistan kazısı azdır ([Berthon ve ark. 2020](https://books.openedition.org/momeditions/8527?lang=de)). Güney Hunlarında at ve deve yarışı anılır (`mitoloji.md` H6, [HHS 89](https://zh.wikisource.org/wiki/後漢書/卷89)). [kaynak]
- **Koyun, keçi.** Moğol çobanı ikisini çoğu zaman tek sürüde tutar, öteki türleri ayrı ([Five Snouts](https://www.eternal-landscapes.co.uk/the-five-snouts-of-mongolias-herders/)). [kaynak] Keçinin sürüyü yönettiği bu kaynakta yoktur; oyunda süs olarak kalır. [kurgu]
- **Sığır, öküz.** HHS 90'daki 車牛 Vuhuan'ın değildir: MS 135'te Vuhuan akıncıları Yunzhong yolunda Han tüccarlarının bin küsur öküz arabasını keser (遮截道上商賈車牛千餘兩, [HHS 90](https://zh.wikisource.org/wiki/後漢書/卷90)). Bozkırda öküz koşumunun dayanağı Ivolga'nın yetişkin öküz kemikleridir. [kaynak] `cart_ox`, `wagon_felt`, `sled_log` Ivolga'ya ve [çıkarım]a oturur. Hun göç arabasının kanıtı zayıftır (`travel.md` §3.1). [kaynak]
- **Yak.** Bugün Moğolistan ve Altay'da vardır; en eski buluntu ≈2.500 yıl; yük ve çift, süt, kıl, tezek; sığırla melez ([Yak](https://en.wikipedia.org/wiki/Domestic_yak)). Moğol çobanı yakı sığır grubunda sayar ([Five Jewels](https://www.bankhar.org/the-five-jewels/)). Hun çağı için tek iz Ivolga'nın deve ile birlikte %1'idir; yakın tek başına payı verilmez. [kaynak] Çilyan otlaklarında bugün yak, koyun, at vardır ([Duke Kunshan](https://swce.dukekunshan.edu.cn/2022/projects/summer-distribution-of-blue-sheep-pseudois-nayaur-in-the-qilian-mountains-the-influence-of-livestock-grazing-and-the-implications-for-conservation-strategies/)). [kaynak]
- **Eşek, katır, domuz.** Eşek ve katır Shiji'de nadirdir, Loulan'da eşek vardır. Domuz Ivolga ve Mançurya'dadır, bozkır mezarlarında çıkmaz. [kaynak] Surlu Avlu ile Hun bozkırı ayrımı için iyi işarettir. [çıkarım]
- **Köpek.** Bugünkü Bankhar omuzda 66–84 cm, 36–57 kg ([Bankhar](https://www.bankhar.org/bankhar-dogs/)); Ivolga köpeği belirgin küçüktür. Davydova üç tip yazar (laika, iri kurt benzeri, mastı), dayanağı yayımlanmamıştır (Sizova ve ark.). «Binlerce yıllık Bankhar» sözü proje iddiasıdır. Projenin verisi 30 köpekte yırtıcı kaybının %93,7 düştüğünü söyler ([SCMP](https://www.scmp.com/print/lifestyle/travel-leisure/article/3013514/dogs-could-stop-mongolian-grasslands-turning-desert-return), arama özeti). [kaynak, zayıf] Hun metninde çoban köpeği k.b.

## 4. Kartal ve doğan: tanığın düzeyi

| Tanık | Çağ | Söylediği | Düzey |
|---|---|---|---|
| Altay kaya resmi | ≈3.000 yıl | Yırtıcı kuş yakalanıp alıştırılıyordu; kuşçuluk olup olmadığı belli değil | [Soma 2012](https://falconryheritage.org/uploads/itemUploads/3186/ACSS2012_0271.pdf) okundu; [Soma 2013](https://papers.iafor.org/wp-content/uploads/papers/accs2013/ACCS2013_0108.pdf) okunamadı (403) |
| Xichagou (Liaoning) tunç kemer tokası | MÖ 3. yy (Soma) | İki atlıdan biri sağ elinde doğan ya da atmaca taşır; Soma atlı kuşçuluğu ≈2.300 yıla koyar | [Soma 2012](https://falconryheritage.org/uploads/itemUploads/3186/ACSS2012_0271.pdf) okundu, Bunker, Kawami, Linduff 1997 (A112) atfıyla; tek araştırmacı, tokanın tarihi bağımsız sınanmadı |
| Aluchaideng tacı | MÖ 5–3. yy | Kartal simgesi, kuşçuluk demek değil | Sağlam ama dolaylı |
| 射雕者 | MÖ 2. yy | Hun kartalı oklar | Sağlam; eğitmez, vurur |
| Zhi Du'nun lakabı 蒼鷹 ([Shiji 122](https://zh.wikisource.org/wiki/史記/卷122)) | MÖ 2. yy | Çakır kuşu sert adam simgesi | Sağlam; kuşçuluk değil |
| Li Si'nin son sözü ([Şerhli Shiji 87](https://zh.wikisource.org/wiki/史記三家註/卷087)) | MÖ 208 | 牽黃犬…逐狡兔: sarı köpekle tavşan avı | Sağlam; köpek var. «臂蒼鷹» Shiji'nin bugünkü metninde yok; [Taiping Yulan 926](https://zh.wikisource.org/wiki/太平御覽/0926) (MS 977–983) Shiji'den böyle aktarır: geç ve tek tanık |
| Shandong Han taş kabartmaları | MS 1.–2. yy | Çin'de kuşçu | Soma 2012'nin aktarımı; görsel bağımsız sınanmadı |
| Hitan (Liao) | MS 10.–12. yy | Bahar kampında kuğu ve kaz 鷹 ve 海東青鶻 (ak doğan) ile avlanır; kartal geçmez | [Liao Shi 32](https://zh.wikisource.org/wiki/遼史/卷32); Vikipedi'nin «Khitan eagle hunters» resim yazısı kuşun türünü belgelemez |
| Altay Kazakları | Modern | Atlı kartal avı; kızıl tilki, karsak, kışın tavşan | [Hunting with eagles](https://en.wikipedia.org/wiki/Hunting_with_eagles); Bayan-Ölgii'de ≈250 avcı, yıl verilmez |

**Sonuç.** Hunların kartal eğittiğine doğrudan kanıt yok. Vikipedi Orta Asya kuşçuluğunu MÖ 2.–1. binyıla tarihler, ama dayanağı Soma 2013 ile bir popüler bilim sayfasıdır ([aynı sayfa](https://en.wikipedia.org/wiki/Hunting_with_eagles)): zincirleme kaynaktır. Bağımsız okunan Soma 2012 atlı doğancılığı Xichagou tokasına dayandırır. Bu yüzden Mete'nin çağında doğanla atlı av olanaklıdır, kartalla av belgesizdir. Doğanı kartaldan önce açmak kanıtın sırasıdır. Oyunda kuşçu bir konuk ustadır, Hun geleneği diye sunulmaz. [çıkarım] Kartal dişisi erkeğinden iridir, 3,9–6,1 kg; tavşan, tarbagan yer; çift olarak avlanabilir; yuvası yardadır ([ADW](https://animaldiversity.org/accounts/Aquila_chrysaetos/)). Doğan da yaz diyetinin %60–90'ı küçük memelidir, Moğolistan'dan yakalanır, genç dişi seçilir ([ADW](https://animaldiversity.org/accounts/Falco_cherrug/)). [kaynak]

## 5. Yaban türleri

Biyoloji bugünkü verilerdir; MÖ 3. yy dağılımı k.b., büyük olasılıkla daha geniştir. [çıkarım]

### 5.1 Otçullar

| Tür | Yaşam alanı | Sürü | Mevsim | Davranış, tehlike | Ürün |
|---|---|---|---|---|---|
| Zeren, Moğol ceylanı ([ADW](https://animaldiversity.org/accounts/Procapra_gutturosa/)) | Doğu bozkırı, düz kuru çayır | Yaz 20–30, kış yüzlerce, göç 35–80 bin | Kızışma Kasım ortası–Şubat başı; doğum Haziran ortası–Temmuz ortası, bir sürünün dişilerinin %90'ı 4 günde | Hep göçer, 60–65 km/sa; kurt kış sonu ve baharda, yaz başında gebe dişileri vurur | Et, deri, boynuz |
| Karakuyruk ceylan ([ADW](https://animaldiversity.org/accounts/Gazella_subgutturosa/)) | Çöl, dağ eteği, ≤3.500 m | 2–9; üremede 10–30 | Kızışma Eylül–Ocak; doğum Mart–Mayıs | Gündüz; avlanınca gece; 10–15 cm kar sınırı | Et, deri, boynuz |
| Sayga ([ADW](https://animaldiversity.org/accounts/Saiga_tatarica/), [J. Zool. 2013](https://works.bepress.com/julie_young1/208), arama özeti) | Düz kuru bozkır | 1–121, ortanca 6,5; Aralık en çok | Kızışma Kasım sonu–Aralık; harem 5–10 | Tipi ve kuraklıktan kaçar; geceleri yatak kazar | Et, deri, boynuz |
| Kulan ([ADW](https://animaldiversity.org/accounts/Equus_hemionus/), [Zhang 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4498657), [CMS](https://cami.cms.int/es/node/41587)) | Gobi; su ≤30 km | Geçici kümeler; sayı k.b. | Çiftleşme Nisan–Ekim; gebelik 339 gün | İçmenin ≈%85'i gece ve alaca; 69 km/sa; yıllık alan 30–60 bin km² | Et, deri |
| Takhi ([Przewalski atı](https://en.wikipedia.org/wiki/Przewalski%27s_horse)) | Orta Asya bozkırı; son yer Cungarya, 1969 | 5–15, tek aygır | Yavru ilkbahar–yaz başı [çıkarım] | Botai kaçkını sayılır, tartışmalı | Et, deri, kıl |
| Yaban devesi ([Reading 1999](https://www.cambridge.org/core/journals/oryx/article/status-of-wild-bactrian-camels-and-other-large-ungulates-in-southwestern-mongolia/68800469DCDDA80FE7592DCF70721C0F), ADW) | Gobi, Lop | Ort. 10; 6–20, en çok ≈500 | Üreme Mart–Nisan | Kışın bozkıra iner, baskın erkek yönetir | Et, kıl |
| Maral, Altay wapitisi ([Altai wapiti](https://en.wikipedia.org/wiki/Altai_wapiti), [HMW](https://treatment.plazi.org/id/03a087c4ffd5-ffd4-ff60-fa22efd5f46a), arama özeti) | Güney Sibirya, KB Moğolistan, ormanlı tepe | Dişi aile, küçük erkek sürüleri | Kızışma Eylül–Ekim; boynuz atma Şubat–Mart | Altay'da ≤140 km mevsim yolu; boğa ≤300 kg | Et, deri, boynuz, sinir |
| Mançurya wapitisi ([Manchurian wapiti](https://en.wikipedia.org/wiki/Manchurian_wapiti)) | Baykal doğusu, Mançurya; Gansu ve Alaşan geyiği aynı soy | k.b. | Aynı | Karışık orman; boğa 200–250 kg | Aynı |
| Karaca ([ADW](https://animaldiversity.org/accounts/Capreolus_pygargus/)) | Orman, yanık açıklık, sel ovası | Aile; göçte ≤500 | Kızışma Temmuz ortası–Eylül; doğum Mayıs–Temmuz; göç Eylül–Ekim 100–300 km | Alaca etkin | Et, deri, boynuz |
| Ren ([ADW](https://animaldiversity.org/accounts/Rangifer_tarandus/)) | Tundra, orman, kışın karı kazar | Harem 5–15 | Kızışma Ekim–Kasım; doğum Mayıs–Haziran | 80 km/sa; Sayan için ayrı kaynak okunmadı | Et, kürk, boynuz |
| Sığın ([ADW](https://animaldiversity.org/accounts/Alces_alces/)) | Tayga, su kıyısı | Yalnız | Kızışma Eylül–Ekim | Yavrusunu korur, saldırır; 360–600 kg | Et, deri |
| Argali ([ADW](https://animaldiversity.org/accounts/Ovis_ammon/), [Singh 2010](https://doaj.org/article/a9f3e791f17f47c8acd44ce73316638b)) | Açık dağ, ≥1.000 m | Ort. 15; Gobi'de 5 | Tepe Mayıs–Haziran, Kasım–Aralık | Cinsler ayrı; kuzu ölümlerinin ≈%45'i yırtıcıdan | Et, boynuz |
| Yaban keçisi ([ADW](https://animaldiversity.org/accounts/Capra_sibirica/)) | Kayalık, 500–5.000 m | ≤40; harem 5–15 | Kızışma Kasım | Kaçış yamacından ≈350 m uzaklaşmaz; 30–40 cm kar kazar | Et, boynuz |
| Mavi koyun ([One Earth](https://www.oneearth.org/ecoregions/qilian-mountains-conifer-forests/)) | Çilyan; en yaygın toynaklı | k.b. | k.b. | Büyük yırtıcıların ana avı | Et, boynuz |
| Yaban domuzu ([ADW](https://animaldiversity.org/accounts/Sus_scrofa/)) | Ormanlık, sazlık, su yakını | 6–20 | Yıl boyu | Alaca, gece; insanı yaralar | Et, yağ |

### 5.2 Yırtıcılar

| Tür | Yaşam alanı | Sürü | Mevsim | Davranış, tehlike | Ürün |
|---|---|---|---|---|---|
| Kurt ([ADW](https://animaldiversity.org/accounts/Canis_lupus/)) | Her yer | 5–9 çoğunlukla | Çiftleşme Ocak–Nisan | 55–70 km/sa; Hustai'de diyetin yarısından çoğu sürü, kışın artar, yabanı yeğler ([van Duyne 2009](https://bioone.org/journals/journal-of-wildlife-management/volume-73/issue-6/2008-027/Wolf-Predation-Among-Reintroduced-Przewalski-Horses-in-Hustai-National-Park/10.2193/2008-027.full)); Hentiy'de besinin %89'u yaban, sürü yok ([Tiralla](https://openpolar.no/Record/ftsubgoettingen:oai:publications.goettingen-research-online.de:2%2F79643)) | Kürk |
| Tilki, karsak ([ADW](https://animaldiversity.org/accounts/Vulpes_corsac/); kızıl tilki okunmadı) | Kuru bozkır | Küçük kış grubu | Ocak–Mart | Gece; tarbagan inini kullanır; yavaş köpek yakalar | Kürk |
| Ayı ([ADW](https://animaldiversity.org/accounts/Ursus_arctos/)) | Orman, dağ | Yalnız | Kış uykusu Ekim/Aralık–Mart/Mayıs | Yakında ve yavruyla saldırır | Et, yağ, post |
| Kar leoparı ([ADW](https://animaldiversity.org/accounts/Uncia_uncia/)) | 3.000–4.500 m, kışın aşağı | Yalnız | Çiftleşme Ocak–Mart | İnsana saldırı çok seyrek: bilinen üç vaka, hiçbiri ölümcül değil ([Vikipedi](https://en.wikipedia.org/wiki/Snow_leopard); ADW yabanda bilinmez der); sürüden çalar, kolay kovulur, avını bırakır | Post |
| Vaşak ([ADW](https://animaldiversity.org/accounts/Lynx_lynx/)) | Orman, taşlı tepe | Yalnız | Şubat–Nisan | Alaca; karaca, misk geyiği, tavşan | Kürk |
| Kaplan ([ADW](https://animaldiversity.org/accounts/Panthera_tigris/), HHS 85, 90) | Amur, Mançurya ormanı | Yalnız | k.b. | En büyük kedi, tek başına tehlike | Post |

### 5.3 Küçükler, kuşlar, balık

| Tür | Yaşam alanı | Sürü | Mevsim | Davranış | Ürün |
|---|---|---|---|---|---|
| Tarbagan ([Tarbagan](https://en.wikipedia.org/wiki/Tarbagan_marmot)) | Moğolistan bozkırı, Altay'dan Gobi'ye | İn ağı, kolonide | Kış uykusu; av güzde | İnden uzaklaşmaz, vurulmayan kaçar, veba taşır | Et, yağ, post |
| Tavşan ([Tolai](https://en.wikipedia.org/wiki/Tolai_hare)) | Kum, ova, ırmak boyu | Tek | Üreme Şubat sonundan | Alaca ve gece; ini yok | Et, post |
| Samur ([ADW](https://animaldiversity.org/accounts/Martes_zibellina/)) | Tayga | k.b. | Çiftleşme Haziran–Ağustos | Gündüzcü diye yazılı; fırtınada inde | Kürk |
| Sincap (鼲子, [HHS 90](https://zh.wikisource.org/wiki/後漢書/卷90)) | Orman | | | Biyoloji okunmadı | Küçük kürk |
| Altın kartal, doğan | §4 | Çift | Mart–Ağustos | Dalış ≈320 km/sa | Tüy |
| Turna ([Demoiselle](https://en.wikipedia.org/wiki/Demoiselle_crane)) | Su yakını açık alan | Kışta büyük sürü | Yumurta Nisan–Mayıs; kışı Hindistan'da | Danslı | Tüy |
| Toy kuşu ([Great bustard](https://en.wikipedia.org/wiki/Great_bustard)) | Düz bozkır | Düzinelerle | Lek Mart; yumurta Mayıs–Haziran; Kuzey Moğolistan'dan 2.000 km güneye | Önce koşar, ağır havalanır; erkek ≤18 kg | Et, tüy |
| Kaz ([Bar-headed](https://en.wikipedia.org/wiki/Bar-headed_goose)) | Yüksek göl | Binlerce | Yaz gölde, kış Hindistan | Gece uçar | Et, tüy |
| Kuzgun, karga ([ADW](https://animaldiversity.org/accounts/Corvus_corax/)) | Her yer | Çift; leşte toplu | Mart–Nisan | Leş bulur, zeki | Tüy |
| Akbaba ([ADW](https://animaldiversity.org/accounts/Aegypius_monachus/)) | Moğolistan, ağaç yuvası | Koloni | | Leşe hâkim; 8 kg | Tüy |
| Sülün ([ADW](https://animaldiversity.org/accounts/Phasianus_colchicus/)) | Çalılık, sazlık, tarla | Kışta ≤50 | Mart–Haziran | Dik havalanır, koşar | Et, tüy |
| Taymen ([Taimen](https://en.wikipedia.org/wiki/Hucho_taimen), [Eg-Uur](https://worldwidescience.org/topicpages/h/hucho+taimen+pallas.html)) | Selenga, Amur, Lena havzası | Tek | Hareket Mayıs–Haziran, Eylül–Ekim | 70–120 cm; ≤55 yıl; kemirgen ve kuş da yer; buzda kalan dev taymen efsanesi | Balık |

### 5.4 Bölge özeti

| Bölge | Evcil | Yaban | Dayanak |
|---|---|---|---|
| Doğu bozkırı (`tanhu_ordu`, `donghu_land`) | At, koyun, keçi, sığır | Zeren, tarbagan, toy kuşu, kurt, karsak | Shiji 110, ADW |
| Ordos | Koyun, at, deve | Ceylan, sülün, kurt, domuz | Aluchaideng, 河南 baskını; yaban [çıkarım] |
| Hexi, Çilyan | At, koyun, deve; yak dağda | Karakuyruk, mavi koyun, kar leoparı, vaşak, ayı, domuz | Hanshu 28B, One Earth |
| Altay | At, koyun, yak | Maral, argali, yaban keçisi, kar leoparı | ADW, [Altai wapiti](https://en.wikipedia.org/wiki/Altai_wapiti) |
| Gobi | Deve, keçi, at | Kulan, karakuyruk, takhi, yaban devesi, sayga | Reading 1999, Zhang 2015 |
| Baykal, Selenga | Köpek, koyun, sığır, domuz | Karaca, maral, samur, balık | Ivolga, Hanshu 54 |
| Mançurya | Sığır, at, koyun, köpek, domuz | İzubra, kaplan, samur, sincap | HHS 85, 90 |

## 6. Av töresi

Mehmet Aça'nın derlemesi doğrudan kullanılır ([TÜBAR 2007](https://dergipark.org.tr/en/download/article-file/156891)). Altay, Hakas, Şor, Tıva ve Saha avcıları ava destancı götürür. Şorlara göre tayga iyesi kopuz ve destan sever; kayçısız gelen avcıyı cezalandırır. Saha'da Baay Bayanay anlatı düşkünüdür; av öncesi gece anlatı yoksa av tutmaz; gündüz ve yazın anlatmak yasaktır. Ürün avcı ile anlatıcı arasında eşit bölünür. Av öldürme değil, iyenin armağanı ve gönüllü bir alışveriştir; gereğinden fazlası hoş görülmez. [kaynak] Bu derlemeler 19–20. yüzyıldandır, Hun çağına taşımak [çıkarım]dır; `mitoloji.md` bunu ozan ağzına koyar. Sakha avcısının ilk ganimetten pay vermesi ve ayının adını anmaması `mitoloji.md` öneri 8'dedir.

## Oyuna öneriler

**1. Evcil katalog (#Ek).** Kimlikler `economy.md` §3.11 ile aynıdır. Hız tırıs ve dörtnal, m/sn; binekler öneri 5'te. [kurgu, biyoloji §3]

| id | TR / EN | Yer | P | Hane; görünen | Mizaç, davranış | Hız | Can | Ürün, iş | Oyuncu |
|---|---|---|---|---|---|---|---|---|---|
| `horse` | At / Horse | Her yer | I | 7; ≤60 | Ürkek, sürü izler, kar kazar | Binek | 70 | `mare_milk`, `hair`; binek, koşum | Bağ, `herd_habit` |
| `sheep` | Koyun / Sheep | Bozkır, ağıl | I | 35; ≤300 | Toplanır, kurttan içe kaçar | 2,5 / 5,5 | 16 | `milk`, `wool`, `fat` | Kurt görevi; çocuk biner |
| `goat` | Keçi / Goat | Yamaç, Gobi kenarı | II | 10; ≤60 | Meraklı, kayaya çıkar | 2,6 / 6 | 14 | `milk`, `hair` | Koyunla tek sürü |
| `cattle` | Sığır, Öküz / Cattle, Ox | Irmak, vadi | I çevre, II | 4; ≤40 | Sabırlı | 3,5 / 6 | 60 | `milk`, `horn`; `cart_ox`, `sled_log`, `wagon_felt` | Koşum kartı |
| `camel` | Deve / Camel | Gobi, Alaşan, Hexi, Ordos | I çevre, II | 0,5; Gobi hanesi 2; ≤24 | Mağrur, diz çöker, kar yer | 4,2 / 9 | 80 | `milk`, `hair`; `pack_camel`, binek | Toz işareti, yarış |
| `yak` | Yak / Yak | Hangay, Çilyan | IV çevre, VI | Çiang hanesi 6; ≤24 | Sessiz, karda yürür | 3,4 / 6 | 70 | `milk`, `hair`; yük | `cattle` görünüşü |
| `donkey` | Eşek / Donkey | Hexi, Loulan, Han sınırı | IV | 1–6; ≤12 | İnatçı | 3,2 / 7 | 40 | Yük 20, su | Vaha hanesi |
| `mule` | Katır / Mule | Han sınırı, Hexi | V | 1–4; ≤12 | Güçlü, doğurmaz | 3,6 / 8 | 55 | Yük 35, binek | Sığınan Han hanesi |
| `pig` | Domuz / Pig | Surlu Avlu | V | Tavan 12 | Artık yer | 2,2 / 5 | 24 | `meat`, `fat`, `hide` | Yalnız Surlu yol (Y6) |
| `dog` | Köpek / Dog | Her yer | I | 1–2; T0 ≤2, T1 ≤6 | Sadık, havlar | 3,2 / 10 | 30 | Çoban, koku, nöbet | Öneri 9 |

**2. Yaban katalog (#Ek).** Hız tepe ve sürek, m/sn. «Mevcut» `survival.md` §4 satırıdır, değişmez. Kaçış: `v = sürek + (tepe − sürek) × max(0, 1 − t / T)`; T ceylan 12, zeren 15, kulan 20, öteki 8 sn. `hun_pony` (11) ceylana ancak 12. saniyeden sonra yaklaşır: o anda ceylan 18 m daha açılmıştır, at saniyede 1 m kapatır; başlangıç açığı d m ise ≈30 + d sn'de yakalar. Zeren ve kulanın süreği 11'dir: tek atlı yakalayamaz, sürek ya da pusu ister. [kurgu]

| id | TR / EN | Biyom, zon | P | Sürü | Ana davranış | Hız | Can | Av ürünü | Oyuncu |
|---|---|---|---|---|---|---|---|---|---|
| `gazelle` | Ceylan / Goitered Gazelle | Hexi, Gobi kenarı, Ordos | I | 2–9 | Kaç, dur, bak | 15 / 10 | 26 | Mevcut | İlk av |
| `dzeren` | Zeren / Mongolian Gazelle | `tanhu_ordu`, `donghu_land` | II | 20–30; akın | Toplu döner, göçer | 16 / 11 | 24 | `gazelle` gibi | Sürek avı |
| `saiga` | Sayga / Saiga | Gobi, kış | IV | 6–40 | Düz ovada kalır | 15 / 10 | 24 | 3 `meat`, 1 `hide`, 1 `horn`, 1 `bone` | Nadir |
| `kulan` | Kulan / Wild Ass | Gobi, Alaşan | II | 5–40 | Gece su başına iner | 15 / 11 | 40 | Mevcut | Su Başı Pususu |
| `takhi` | Taki / Takhi | Gobi | IV | 5–15 | Aygır korur, kısrak çeker | 14 / 10 | 44 | 5 `meat`, 2 `hide`, 2 `sinew`, 3 `bone`, 2 `hair` | At sürüsüne karışır |
| `wild_camel` | Yaban Devesi / Wild Camel | `loulan` | VI | 6–20 | Çok ürkek, uzak kaçar | 13 / 9 | 70 | 6 `meat`, 3 `hide`, 2 `sinew`, 4 `bone`, 2 `fat` | Destan dizesi |
| `deer` | Maral / Maral | Orman bozkırı, Kara Yamaç | I | 3–8 | Tan, akşam açıkta; güzde böğürür | 13 / 9 | 36 | Mevcut | İz sürme |
| `izubra` | Mançurya Marali / Izubra | `donghu_land` | III | 3–8 | `deer` görünüşü, daha küçük | 13 / 9 | 32 | `deer` −1 `meat` | Tunghu takımı |
| `roe` | Karaca / Roe Deer | Orman, Selenga | III | 2–6 | Sıçrar, güzde göçer | 13 / 9 | 22 | Mevcut | |
| `reindeer` | Ren / Reindeer | `dingling_north` | Seçmeli | 5–15 | Kar kazar | 14 / 9 | 40 | 4 `meat`, 1 `hide`, 1 `antler`, 2 `sinew`, 2 `bone` | Dingling takası |
| `moose` | Sığın / Moose | Hentiy, `dingling_north` | VI | Tek | Yavrulu saldırır, 16 `blunt` | 13 / 8 | 110 | 8 `meat`, 2 `hide`, 1 `antler`, 3 `sinew`, 4 `bone`, 2 `fat` | Tehlikeli av |
| `argali` | Argali / Argali | Dağ, Gobi Altay | II | 5–15 | Kayaya kaçar, cinsler ayrı | 12 / 8 | 34 | Mevcut | |
| `ibex` | Yaban Keçisi / Ibex | Dağ, Kara Tepeler | I | 5–40 | Yamaçtan ≤350 m | 11 / 8 | 32 | Mevcut | `mq_hunt` |
| `boar` | Domuz / Boar | Sazlık, orman | I | 6–20 | Vurunca saldırır, 8 `blunt` | 10 / 6 | 44 | Mevcut | |
| `wolf` | Kurt / Wolf | Her yer | I | 5–9; T0 ≤4 | Gece sürüye, ateşten çekinir, 8 `pierce` | 13 / 8 | 30 | Mevcut | Öneri 8 |
| `fox` | Tilki, Karsak / Fox, Corsac | Bozkır | I | 1–4 | Gece; `look: corsac` 8 / 5 | 10 / 6 | 14 | Mevcut | Kuş avı |
| `bear` | Ayı / Bear | Hangay, Hentiy, Çilyan | III | Tek | Ekim–Mart inde, 14 hasar | 11 / 5 | 90 | Mevcut | Adı anılmaz |
| `snow_leopard` | Kar Leoparı / Snow Leopard | Çilyan, Altay | IV | Tek | Görünmez, sürüden çalar, 12 `slash` sıkışınca | 13 / 6 | 50 | 1 `fur_big`, 1 `sinew`, 1 `bone` | Görmek Destan dizesi |
| `lynx` | Vaşak / Lynx | Orman | III | Tek | Alaca | 12 / 5 | 28 | 1 `fur_wolf`, 1 `sinew` | Kapan |
| `tiger` | Kaplan / Tiger | `donghu_land` doğusu | III | Tek | Pusu, 22 `slash` | 14 / 6 | 140 | 1 `fur_big`, 8 `meat`, 3 `sinew`, 4 `bone`, 2 `fat` | Boss değil, olay |
| `hare` | Tavşan / Hare | Otlak, sazlık | I | Tek | Zikzak | 12 / 8 | 8 | Mevcut | Kapan |
| `marmot` | Tarbagan / Marmot | Bozkır, yamaç | I kamp, II | Koloni | İne kaçar, ıslık; kışın yok | 4 / 2 | 10 | Mevcut; güzde +1 `fat` | Çocuk hedefi |
| `squirrel` | Sincap / Squirrel | Orman | III | Tek | Ağaca kaçar | 5 / 3 | 3 | 1 `hide_small` | Kapan |
| `sable` | Samur / Sable | Tayga | VI | Tek | Ağaç, in | 6 / 3 | 4 | Mevcut | Hazine |
| `partridge` | Keklik / Partridge | Yamaç | I | 5–12 | Toplu havalanır | Uçar | 4 | Mevcut | |
| `crow` | Karga / Crow | Her yer | I | ≤64 | Leş bulur, ürker | Uçar | 1 | Mevcut | `look: raven` |
| `eagle` | Altın Kartal / Golden Eagle | Dağ, bozkır | I geçiş | Çift | Gökte süzülür | Uçar | 12 | 6 `feather` | Öneri 10 |
| `falcon` | Doğan / Saker | Bozkır, yar | IV | Çift | Pusudan dalar | Uçar | 5 | 2 `feather` | Öneri 10 |
| `crane` | Turna / Crane | Göl, ırmak | II | 2–30 | Yazın; güzde göç | Uçar | 8 | 1 `meat_small`, 4 `feather` | Mevsim işareti |
| `bustard` | Toy Kuşu / Great Bustard | Bozkır | II | 4–20 | Önce koşar | 8 / uçar | 10 | Mevcut | Yaz, güz |
| `goose` | Kaz / Goose | Göl, ırmak | II | ≤32 | Gürültülü, V uçar | Uçar | 6 | Mevcut | Yaz |
| `vulture` | Akbaba / Vulture | Dağ, savaş alanı | IV | 2–12 | Leşe iner | Uçar | 14 | 4 `feather` | Leş ve ceset izi |
| `pheasant` | Sülün / Pheasant | Sazlık, Ordos, Daibei | IV | ≤50 kışın | Dik havalanır | 6 / uçar | 5 | 1 `meat_small`, 3 `feather` | Kış avı |
| `fish` | Balık / Fish | Buz, göl, ırmak | I | | Ağ, olta | | | Mevcut | |
| `taimen` | Taymen / Taimen | Kerulen, Selenga, Hangay | III | Tek | Hareket Mayıs–Haziran, Eylül–Ekim | | | 6 `fish` | Destan dizesi |

Yeni tek eşya `fur_big` «İri Post / Great Pelt»: 1,5 Yük, yığın 3, Kıymet 48, `fur`, `valuable`; sıcaklık etkisi yoktur (K1). XP kuralı (`progression.md` §1.3): tür başına ilk av +40 kalır, **perde başına en çok 4 tür** sayılır (160 XP), kalanı Destan dizesidir; `oyun-seviye-tasarimi.md`'nin Keşif sütunu uyarısı bununla kapanır. (#21)

**3. Görünüş çeşitleri, kimlik eklemez (#32).** `gazelle` yalnız Karakuyruk'tur; Hexi ve Gobi'nin ceylanıdır, Doğu bozkırı `dzeren`'dir. `ibex`in Çilyan görünüşü mavi koyundur (`look: bharal`): I. Perde sayıları değişmez, gri mavi tüy, dışa kıvrık boynuz. `deer` EN adı «Red Deer»den «Maral» olur. `crow` dağda `raven`. `yak` kendi sürü satırını taşır (öneri 4), hane sürüsünde ve Kıymet'te `cattle` gibi sayılır. [çıkarım]

**4. Sürü ekonomisi (#29, #30, #44, K24).** `HOUSEHOLD_HERD`, `herdDay`, `econ-sim` değişmez: yeni türlerin hane değeri 0'dır.

- **Fiyat (#29).** Kesim değeri (et 4, deri 8, kemik 1, sinir 4, boynuz 6, yağ 2, kıl 1; `economy.md` §2) × 1,33; iş değeri eklenir. Koyun 36 × 1,33 = 48 (var); at 141, binek +%138 = 336 (var). Hesap `economy.md` §3.11 kesim satırlarıyla yeniden yapıldı, tutar. #29'un öteki iki kalemi: Tahıl Çuvalı `economy.md` §9.4'te 12'dir; arbalet oku bu belgenin alanı değildir. Oranlar Han ya da Hun dönemi bir fiyat kaynağıyla sınanamadı (k.b.). [çıkarım]

| id | Kesim × 1,33 | İş | Kıymet | Koyun oranı |
|---|---|---|---|---|
| `goat` | 35 | | **36** | 0,75 |
| `cattle` | 168 | Koşum +%43 | **240** | 5 |
| `camel` | 189 | Yük +%129 | **432** | 9 |
| `yak` | 168 | Yük +%43 | **240** | 5 |
| `donkey` | 29 | Yük | **120** | 2,5 |
| `mule` | 68 | Yük ve binek | **288** | 6 |
| `pig` | 64 | | **64** | 1,33 |

- **Ek sürü satırları** (`herd-kinds.js` biçimi; yalnız ticaret, olay ve Kronik girişi ile gelir): `yak` lu 1, `herderPer` 50, doğum %20, süt `cattle` ×0,6, tarama 1 `hair`, kış yemi 0,05 / 0,4. `donkey` lu 0,5, doğum %12, süt 0, kesim {3 `meat`, 1 `hide`, 2 `bone`}. `mule` lu 0,7, doğum 0, kesim {8 `meat`, 2 `hide`, 3 `bone`}. `pig` lu 0,2, otlak saymaz, tavan 12, doğum %100, kesim {8 `meat`, 3 `fat`, 1 `hide`, 2 `bone`}. [kurgu]
- **Haraç (#21).** III. Perde'de Tunghu yenilince Kronik yılda 20 `hide` işler (歲輸牛馬羊皮). IV açılışında ≈60 deri. [kaynak + kurgu]
- **Dailin (#44).** Sayım beş kimliği okur, güzde T2 ağında kalınlık `horse_fat` ile çarpılır («馬肥» görünür). Saymada renkler dört yönle ayrılır. [kurgu]
- **Deve otlağı.** `camel.lu` 1,3 kalır; Moğol koyun birimi bu turda doğrulanamadı (Belirsizlikler).

**5. Binek (#Ek, #27).** `progression.md` §6.4 satırlarına ek; var olanlar değişmez. [kurgu]

| id | TR / EN | P | `base` | Tırıs | At staminası × | Yük | Not |
|---|---|---|---|---|---|---|---|
| `hun_pony` | Hun Atı / Hun Pony | II | 11 | 6,2 | 1 | 40 | Var; yeni: yokuş cezası ×0,5 (Chao Cuo) |
| `riding_camel` | Binek Deve / Riding Camel | II | 8,5 | 4,2 | 1,3 | 60 | Yan yürüyüş; kum ve tuz çarpanı yok; 20 m içinde düşman atı ürker (`enemyHorseSpook`; Herodot 1.80 [kaynak], 20 m [kurgu]); savaş `saddle_cut` yok |
| `mule_mount` | Binek Katır / Riding Mule | V | 8 | 4,6 | 1,2 | 40 | Eğim cezası yok; gök gürültüsü ürkmesi ×0,5 |
| `jueti` | Cüti / Jueti | VI | 11,5 | 6 | 1,25 | 45 | Kuzeyin melezi; `west_steed` ile seçim, armağan |

Yeni at eşyası `bridle_bone` «Kemik Gem / Bone Bit», `bridle`, I–II, dönüş ×1,04, 2 `bone` 1 `hide` (T19'un kemik gemi). `bone` bir kullanım daha kazanır. Görsel boy: `hun_pony` ×0,94, `yakwe` ×0,92, `west_steed` ×1,06 (`Horse` kuruluş yeniden ölçeği), menü atları 1,06 kalır (`menuDiff`). Godot'da ölçek `Horse.MODEL_LENGTH` (2,3 m) çarpanıdır; menü kampının iki atı değişmez (`godot.md` §6.7). Üzengi `sanat-animasyon.md` öneri 13. VI. Perde mektup armağanı (1 deve, 2 binek, 8 koşum atı) sahnede görünür. Toy Alanı'nda at ve deve yarışı: Gönül +1, mevsimde bir. (#21)

**6. Yük, kafile, araba (#39, #48, K24).** `yurt_kit` 59 Yük. **Çelişki düzeltmesi:** `pack_camel` 30 Yük, atın terkisinden (40) azdır; deve attan iki kat yük taşır (170–250 kg, §3). `travel.md` §3.2 ve `economy.md` §4.3'te **30 → 60**. «Bir keçe arabaya ya da iki yük devesine» cümlesi kalır, anlamı değişir: bir deve Yurt Yükü'nü, ikincisi hanenin eşyasını taşır. Gerçekte de bir yurt eşyasıyla iki üç deveye yüklenir (§3); tek deveye bir yurt, gerçeğin değil oyunun sadeleştirmesidir. Yeni `pack_horse` «Yük Atı / Pack Horse» 30 Yük, 4,0 / 3,0 m/sn: iki at bir yurt. `pack_camel` I. Perde'de yalnız çevredir, sayı değişmez. #39'un iki türü yükünü getiren (at yüklü, deve yüklü, arabalı) ve yurt isteyendir (çadırlı, isteyen). Gelen hane `settlement.md` §5.3'ün kaynaklarına böyle oturur: [kurgu]

| Gelen tür | Kaynak | Görünen kafile | Davranış |
|---|---|---|---|
| At yüklü | `oba_wave`, `court_move`, `court_gathering`, `pull` %60'ının çoğu | 2 kişi, 2 `pack_horse`, T2 sürü | Parsel alır, yurdunu kurar (1 İG) |
| Deve yüklü | `loufan_baiyang`, Gobi kökenli `pull`, `kurultay` | 2 kişi, 2 yüklü deve (yurt, eşya) | Aynı; sürüde 3 at yerine 2 deve (≈18 lu korunur) |
| Arabalı | `gift`, beylerin `court_gathering` | `cart_felt` ya da `cart_ox` | Aynı; araba kervan havuzuna hemen girmez, 3 gün sonra |
| Çadırlı | `choose` %30 | 1 `pack_horse`, `tent_kit` | Çadır kurar, sonra yurt ister |
| İsteyen | `hh_story`, `hh_saved`, `refugees`, `defectors`, `choose` %70, `pull` %40 | Yaya ya da tek at | Kapıda bekler: «Yurdumuz yok.» / «We have no home.»; 3 gün, Gönül −1/gün (var) |

- **Yük indirme.** Deve diz çöker, at durur; yük 8 sn'de iner. ≤30 m'de T0, ötede T1 pozu. Hayvanlar sürüye girer.
- **Araba kartı (#48).** Plan Kipi kartı `team` alanı taşır: `cart_felt` 1 `horse`, `cart_high` 2, `cart_war` 4, `cart_ox` 2 `cattle`, `wagon_felt` 4 `cattle`, `sled_log` 1. Sürüde yoksa araba biter, kervan bekler. Koşum hayvanı kesilmez, sürü sayısından düşmez.
- **Deve kervanı.** Kervan Buyruğu'nda 1 keçe araba yerine 1 deve (60 Yük). `fx.cartK` okumaz; `fx.cartLock`'ta ×0,5 yürür; yol dışı gider. Gobi yolları (`r_whistle_ordu`) için doğal seçim. `pack_camel` günü: atlas `deve` sütunu var.

**7. Av ve Bayanay (#8, #55, #20).** `mitoloji.md` öneri 8 aynen: Pay Bırak (`E` 2 sn, 1 `meat_small` ya da `fat`, bölge başına günde 1; algı ×0,9, sonraki şafak %30 → %35) ve Yer küstü (stok <%30: 2 şafak %15). Bu belgenin eki: [kaynak → kurgu]

- **Kopuz Gecesi.** Ateş başı Dinlen sırasında ozan onluktaysa ve evre `dusk` ya da `night` ise ≥1 oyun saati dinleme, ertesi gün ilk büyük avda +1 verim (günde 1). Gündüz çalınmaz (Saha kuralı). Saha'nın yaz yasağı alınmaz: II, IV ve VI Haziran'da açılır. Kopuzsuz avın cezası yoktur (`survival.md` §1 «ceza yumuşak»).
- **Ozanın Payı.** Avdan 1 parça ozana `Ver`: `ties` +1 (var). Kut vermez (`progression.md` §5.1).
- **Okunur işaret.** Yer küstü'nde HUD sayı vermez: o bölgede `birds_day` ×0,5, uzak kurt ulur, Mene ya da kam el eder.
- **Mevsim yasağı.** Doğum penceresinde (zeren Haziran–Temmuz, karaca Mayıs–Temmuz, argali Mayıs–Haziran) yavrulu sürüyü kırmak Korku +1 (var; `axisOnce: cubs_<zone>`).
- **Stok yerleri.** Mevcut: bozkır 40, dağ 25, orman 30, küçük ×3 (`economy.md` §3.6). Yeni türler bu stoktan pay alır, stok büyümez. Tek yırtıcı (`tiger`, `moose`, `snow_leopard`) stok dışıdır: perde başına zon başına ≤1.

**8. Kurt ve sürü (#43, #45, `settlement.md` §15.3).** Kapsanmayan sürü payının kaybı bir formüle bağlanır: [kaynak → kurgu]

```
wolfLoss = 0,01 × (1 + 1,5 × (1 − stok / tamStok)) × (kış ? 1,5 : 1) × (sis ? 1,5 : 1) × (hanede köpek ? 0,4 : 1) × (ağıl ? 0,3 : 1)
```

Tam stok, yaz: %1 (bugünkü öneri). Stok %30, kış: ≈%3,1. Köpekle ≈%1,2. Kapsanan sürüde kayıp yoktur, `econ-sim` hedefleri değişmez. Sonuç: yerleşim çevresini boşaltan oyuncunun koyunu kurda gider. Olay: `ev_wolves` (`travel.md` §9.6) aynı stoku okur. **Küçük akın (#43).** Akının amacı sürüdür: hedef `pen` ya da `horse_line`, başarıda kayıp ≤%3 (≤%10 tavanının içinde), `R`, `D` değişmez. `mete-tarih.md` öneri 10 ile dolunay günlerinde gelir.

**9. Köpek yoldaş (#22, #26, #38, #43).** Ku Mene'de kalır (`act1.md` §9.7). II'de Teoman'ın sürüsüyle iki çoban köpeği gelir; üç gün et verilen yavru Mete'nin olur. Varsayılan ad **Karabaş** (K13 kurgu listesi). `Follower`, aynı üç buyruk (Z, X, G), `dog` T0. Bağ 0–3, yalnız besleme ve avla büyür. Ölmez: Can 0'da 1 oyun günü yurtta yaralı kalır. Köpek boyu tipi: Hun `wolfish` ×1, Selenga `laika` ×0,8; omuz 0,68 m (`sanat-animasyon.md`). [kurgu, tip kaynak]

| İş | Kural | Sistem |
|---|---|---|
| **Çoban** | Hanede 1 köpek: `wolfLoss` ×0,4. Sürü kenarında durur | `settlement.md` §6.1; yem: `spoiled`, `bone` artığı, hane öğünü değişmez |
| **Koku** | `G`: köpek burnunu indirir, en taze izde 20 m önden yürür. Menzil `60 m × scentK × yönK` (`weather.md` §8.4). HUD yok, ikon yok (`economy.md` §3.7) | `game/hunting` |
| **Getirme** | Vurulan küçük av (`hare`, `partridge`, `goose`, `pheasant`) ≤40 m'den ayağına gelir, sazlıkta da | `game/hunting` |
| **Kaldırma** | Kuş kümesi yanında `G`: `partridge`, `bustard`, `pheasant` havalanır, nişan için 3 sn kalır | `fauna` |
| **Nöbet, kamp** | Bekle kesintisi 20 m → 60 m; uyku zarında uyanış 8 sn erken (`oyun-seviye-tasarimi.md` #26) | `time.md` §7 |
| **Nöbet, yerleşim** | ≥2 köpek: sis sürprizi ×0,5 → ×0,75; akından 60 gerçek sn önce havlar. `D` değişmez | `settlement.md` §15.3, §15.4 |

Gizlilikte `Kal` şarttır: izlerken gürültü +4 m, koşarken +8 m; Bağ <2 ise hedef görünce %20 havlar. **Düşman köpeği (#22):** `oyun-seviye-tasarimi.md` satırı aynen (80°, 16 m + koku r 12 m, rüzgâr altı ×0,5, üstü ×2). `bone_throw` köpekte `lureR` ×2 tutar. `wolf_pelt` algı ×0,8 işler. **Tarih notu:** Ivolga'da köpek eti izi vardır (kesik izi, 10–12 aylık kesim); sahneye konmaz, Destan Kitabı'nda tek satır. III. Perde'de Tunghu cenazesinde süslü köpek görülür (`sq_red_dog`; HHS 90'ın Vuhuan töresi geriye yansıtılır [çıkarım]).

**10. Kartal ve doğan (#Ek, #12, #22, #38, K27).** Kuşçu konuktur. Üç aşama, hepsi [kurgu]:

- **Yaban (I+).** Kut ≥5'te Şafak Sırtı geçişi kalır (`act1.md`). Bozkırda gerçek irtifada yalnız gölge lekesi ve `eagle_cry` (`sanat-animasyon.md` öneri 9). Tarbagan ve tavşan kapan sahnesi kadrajda en çok zon başına günde 1.
- **Kuşçı ve doğan (IV).** Altay'dan gelen usta **Sungur** (`m_falconer`, K13 kurgu listesi) `sq_first_bird` ile Mete'ye genç bir dişi doğan verir. Yapı `mews` «Kuşhane / Mews»: Boy Yurdu ve üstü, 4 × 3 m, 0,12 İG, 6 `wood`, 2 `rope`, 2 `felt`, 1 `hide`, görünüm `pen` ailesi.
- **Kartal (V).** Yuva görevinden genç dişi; `Bilek ≥5`, atlıyken tırıs üstünde salınmaz.

| İş | Kural | Sınır |
|---|---|---|
| **Keşif** | Buyruk Halkası'nda `cmd_bird`. Doğan 350 m, kartal 600 m yarıçapta **sürü ve birlik lekeleri** haritaya düşer, 1 oyun saati kalır | 20 oyun dk uçuş (50 gerçek sn), 2 oyun saati bekleme. Gece, `sev` ≥3, `vis` <100 yok. Kişi işaretlemez, nöbetçi yerini vermez |
| **Av** | ≤120 m hedef: doğan `hare`, `partridge`, `pheasant`, genç `marmot`; kartal `fox`, `hare`, `marmot` | Başarı `0,55 + 0,05 × Göz`, karda +0,2 (tilki karda belli olur [kurgu]; Soma'nın 2014 tezi bu turda okunamadı); post sağlam, ok harcanmaz; verim var olan tablo |
| **Yerleşim** | `mews` + 1 kuşçu: güz ve kış günde 0,25 `fur_fox`, 0,5 `hide_small` | Yiyeceğe etkisi yok, K24 kışı değişmez; 0,5 İS/gün |
| **Salma** | İki perde sonra kuşu sal: Kut +1 (`axisOnce`, kuş başına) | Kazak kartalcıların kuşu yıllar sonra doğaya salma töresinden esinli, kaynağı bu turda okunmadı (k.b.); geri dönmez, yeni kuş alınabilir |

Kurallar: Kuş savaşa girmez, adam vurmaz (Tanhu 1'in `gok_ok`'u yok). **Kamera kuşa geçmez:** K27 ve varsayılan kadraj korunur, gök görünmez, yüksek kamera dış arazi bütçesini bozar. AC Origins'te oyuncu kuşu sürüp düşmanı işaretler ([Origins](https://en.wikipedia.org/wiki/Assassin%27s_Creed_Origins)); burada bilerek yapılmaz, gizlilik (#22) kişi bilgisini kuşa vermez. `eagle_shooter` kartalı okla düşürme sınavı kalır: 射雕者 tek belgeli Hun kartal ilişkisidir.

**11. Kut ve Korku (#8, `progression.md` §5).** Tekrar eden eylem eksen vermez. [kurgu]

| Olay | Kut | Korku | Kural |
|---|---|---|---|
| Yavrulu sürüyü kırmak | | +1 | Var; bölge başına bir |
| Yağmalanan sürüyü geri vermek | | −1 | Var |
| Ak Maral'ı bırakmak (`iduk`, `mitoloji.md` Iduk) | +1 | | Oyunda bir; vurursa Korku +1, Yer küstü |
| Kuşu salmak | +1 | | Kuş başına |
| Kunmo bebeği (`mete-tarih.md` 16) | +1 | | VI |
| Kar leoparını sürüden kovmak, vurmamak | | | Yalnız Destan dizesi |

Okunur ipuçları, sayı değil: Kut ≥14'te zon başına günde 1 kartal gölgesi; Korku ≥14'te çoban köpekleri hırlar (ses ve canlandırma). Ruh kurdu yardımı yoktur (Tanhu 1). **Tanhu 1 denetimi:** ad ve nesne alınmadı. Desen yakınlığı vardır: Tanhu 1'de kartal Tengri'nindir (`gok_ok`) ve Kut ≥6'da ruh kurdu ava yardım eder. Bu yüzden kartal gölgesi yalnız ortam işaretidir, hiçbir işe yardım etmez; Kut eşiğine bağlanması baş mühendisin onayına açıktır.

**12. Hava (#16, K22, `weather.md` §7.6).** Hava yalnız `fx` verir; bu satırlar `fauna` ve `herd` işaret kanalıdır. Kampta K3 gereği yeni hayvan yok. [kaynak: deve, Bei Shi 97, yaz sıcak rüzgârı; toz cephesine genişletmek ve kalan satırlar kurgu]

| Tür | ≥1 oyun saati önce | Sırasında |
|---|---|---|
| Deve | Toz cephesinde bağırır, toplanır, ağzını kuma gömer: `herd` kanalı. Deveci: «Deve çöktü, toz geliyor!» / «The camels are down. Dust is coming!» | Yürür, `fx.cartLock` ×0,5 |
| At, deve | | Kar Kabuğu'nda kazar (poz); yem tablosu aynı |
| Yak, sığır | Tipi önünde sırtını rüzgâra verir | Yak karda yük taşır |
| Turna, kaz | Cephe önü alçak uçar, ses keser | Yere iner |
| Zeren | Fırtınada rüzgâraltına akar | Doğma ×0,5 |
| Kartal, doğan | | `sev` ≥3 uçmaz |
| Köpek | Gök gürültüsü ≤1 km inler (var) | Yurt altına girer |
| Mevsim | Kışın `marmot`, `goose`, `crane`, `bustard`, `bear` yok; `pheasant`, `crow`, `wolf` var | Mene ve kam mevsimi hayvandan okur (見鳥獸孕乳) |

**13. Gece ve gün (#Ek, K20, `survival.md` §4).** Ağırlık 0–3, sütunlar Tan, Sabah, Öğle, İkindi, Akşam, Gece. Var olan satırlar değişmez, iki düzeltme var. [kaynak: kulan, samur; kalan kurgu]

| Tür | T | S | Ö | İ | A | G | Not |
|---|---|---|---|---|---|---|---|
| `kulan` (ceylandan ayrılır) | 3 | 1 | 0 | 1 | 3 | 3 | Su başı, Zhang 2015; `whistle_field`'in beş pınarı |
| `sable` (tilkiden ayrılır) | 2 | 2 | 1 | 2 | 2 | 1 | ADW gündüz der |
| `dzeren`, `saiga` | 2 | 3 | 1 | 2 | 3 | 0 | Gece yatak |
| `takhi` | 2 | 2 | 1 | 2 | 2 | 1 | Gündüz içer |
| `reindeer`, `moose`, `izubra` | 3 | 1 | 0 | 0 | 3 | 1 | Geyik gibi |
| `snow_leopard`, `lynx` | 3 | 0 | 0 | 0 | 3 | 2 | |
| `tiger` | 2 | 0 | 0 | 0 | 2 | 3 | |
| `eagle`, `vulture` | 0 | 2 | 3 | 3 | 1 | 0 | Sıcak hava sütunu [çıkarım] |
| `falcon`, `pheasant`, `crane` | 2 | 3 | 1 | 2 | 3 | 0 | |
| `squirrel` | 2 | 3 | 1 | 2 | 2 | 0 | |

Gece kuralı: sürü ağılda, atlar 21:00–05:00 baş eğik (`time.md` §8.4); kurt gözleri iki parlak nokta, ışık yok; ateş 8 ve 12 m kuralı (var); `wolf_howl` 23:00'ten sonra 6–10 dk (var); stok düşükse aralık yarıya iner.

**14. Serbest Gez ve K3 (#63, K3 ile çelişki).** K3 «ana kampta hayvan ≤6» der. **Değişiklik isteği: «iskeletli hayvan ≤6»** (`sanat-animasyon.md` öneri 7 ile aynı). T0 takımı `time.md` §8.4 aynen: Doru, Akbulut, araba atı, ≤3 yaban. Evre tablosu bu türlerden çıkmaz. Yeni olan yalnız örnekli: menü kadrajı dışında ≤40 T2 koyun (1 çizim, 14k), ≤16 karga, ≤1 T1 köpek ahır yanında uyur. `campLife.menuPose(true)` gizler, `menuDiff` 0. Deve, sığır, kartal gövdesi, kurt kampa girmez; kurt yalnız `wolf_howl`. K3 değişmezse T2 de kalkar, kamp bugünkü gibi kalır. K6 değişmez: Mete kampta yoktur, Çocuk avı `toy_bow` ile sınırlıdır.

*Godot için.* K3'ün 33 ms sınırı Godot kampında da geçerlidir (`godot.md` §7.2). «İskeletli hayvan» Godot'da `Skeleton3D` taşıyan hayvan demektir. Bugünkü iki at (`horse_brown`, `horse_white`) iskeletsizdir, canlılığı köşe gölgelendiricisi verir (`Horse.IDLE_PARAMS`: baş, kuyruk, nefes); bu sayıya girmez. 40 koyun tek `MultiMeshInstance3D`'dir (`Scatter.make_multimesh` kalıbı, `HerdField`), yürüyüş evresi `INSTANCE_CUSTOM`'dadır. Ahır yanında uyuyan köpek tek `MeshInstance3D`'dir, `Horse` gibi nefes gölgelendiricisiyle. Menü Godot'da gece kampının üstündedir: yeni hayvanlar menü durumunda gizlenir, menü karesi değişmez (`godot.md` §7.5). `campLife.menuPose` ve `menuDiff`'in yerini bu kural ve ekran görüntüsü karşılaştırması alır (`godot.md` §8.5).

**15. Gizlilik ve hayvan algısı (#22, `survival.md` §4).** `R_eff`, `fogK`, rüzgâr çarpanları, `animalSense`, `wolf_pelt` aynen. Tür değerleri (görüş, duyma, koku ×): [kurgu]

| Tür | Görüş m | Duyma m | Koku | Alarm |
|---|---|---|---|---|
| `crow` | 20 | 16 | | Havalanır, r 30 |
| `goose` | 30 | 24 | | Bağırır, r 50 |
| `marmot` | 30 | 20 | | Islık, r 40 |
| `partridge`, `pheasant` | 14 | 20 | | Patlayarak havalanır, r 30 |
| `gazelle` | 40 (var) | 30 | 1 | Toz, r 60 |
| `dzeren`, `saiga` | 60 | 30 | 1 | Toplu döner, r 80 |
| `kulan`, `takhi` | 50 | 30 | 1,5 | Kişner, r 60 |
| `deer`, `izubra`, `roe` | 30 | 30 | 1,5 | Böğürür, r 40 |
| `argali` | 50 (var) | 30 | 1 | Taş düşer, r 40 |
| `boar`, `bear` | 12 | 24 | 2 | |
| `wolf` | 30, gece ×1 | 40 | 2 | Ulur, r 120 |

**Hayvan alarmı.** II. Perde'den `animal_alarm { x, z, r }` nöbetçi şüphesine +0,3 yazar, `stealth-core` okur, koniyi aşmaz. Düşman atı ≤20 m huylanır, nöbetçi bakar. I. Perde §9.5 kalibrasyonu okumaz, sayı değişmez. **Ters yön:** oyuncu da okur: kaz sustuysa yakında biri vardır. `kuş yok` işareti HUD'a yazılmaz.

**16. Perde perde açılış (#19, #20, #21, K25).** Perde süresi görevle biter, takvim başlangıcı K25'tir. [kurgu]

| Perde, takvim | Zon | Yeni tür | Yeni sistem | Görülen |
|---|---|---|---|---|
| I, Aralık 210 | `hexi_winter` | `horse`, `sheep`, `dog`, `crow`, `hare`, `partridge`, `fox`, `gazelle`, `ibex`, `boar`, `deer`, `wolf`; çevre `camel`, `cattle` | Sapan, tuzak, ödünç yay, Ku | Kış takımı; `marmot` yok |
| Serbest Gez, 11 Nisan | `tanhu_camp` | `marmot`, Doru, Akbulut | K3 | Maral tanda |
| II, Haziran 209 | `whistle_field`, `tanhu_ordu` | `goat`, `cattle`, `camel`, `dzeren`, `kulan`, `bustard`, `goose`, `crane`, `argali` | Sürü, atlı av, Karabaş, Pay Bırak, Kopuz Gecesi, `riding_camel` | 行獵鳥獸: Islıklı okla ilk av; beş pınar pususu; zeren doğumu |
| III, Eylül 208 | `donghu_land` | `izubra`, `roe`, `bear`, `lynx`, `tiger`, `squirrel`, `taimen` | Akar su, haraç | Geyik böğürmesi, turna göçü, Tunghu cenazesinin köpeği, zeren akını |
| IV, Haziran 205 | `ordos`, `longcheng`, `hexi_ash` | `pheasant`, `donkey`, `yak`, `saiga`, `takhi`, `snow_leopard`, `vulture`, `falcon` | Sürek avı, `mews`, doğan | Çiang yak kervanı |
| V, Kasım 201 | `mayi`, `baideng` | `mule`, `pig`, kartal | Kartal, Surlu domuzu | Kış takımı; `shown_weak` zayıf sürü; dört renk at |
| VI, Haziran 198 | `hangai`, seçmeli | `sable`, `moose`, `reindeer`, `wild_camel`, `jueti` | Yarış, mektup armağanı | Kunmo, Ak Maral |

**17. Yoğunluk ve bütçe (#63, #66, #12).** Kademe ve tavanlar `sanat-animasyon.md` §5, öneri 1, 7 esastır: T0 ≤8, T1, T2, T3. Bu belgenin eki zon takımı ve yaban payıdır. [kurgu]

| Zon | Evcil üst sınır (görünen) | Yaban takımı (ana) | Av bölgesi, stok | Aynı anda küme |
|---|---|---|---|---|
| `hexi_winter` | 60 at, ≤60 koyun T2 + 140 T3 | `gazelle`, `ibex`, `boar`, `deer`, `wolf` | Var (`survival.md`) | Büyük 3, küçük 4, yırtıcı 1 |
| `whistle_field` | At 60, deve 24, koyun 80 | `gazelle`, `kulan`, `bustard`, `argali` | 3; 40, 40, 25 | Büyük 3, küçük 3, yırtıcı 1 |
| `tanhu_ordu` | Koyun 300, keçi 60, at 60, sığır 40, deve 12 | `dzeren`, `marmot`, `bustard`, `goose`, `crane`, `fish` | 4; 40, 40, 30, 25 | Büyük 3, küçük 4, yırtıcı 1 |
| `donghu_land` | Koyun 150, sığır 40, at 60 | `dzeren`, `izubra`, `roe`, `bear`, `tiger`, `taimen` | 4; 40, 30, 30, 25 | Büyük 3, küçük 3, yırtıcı 2 |
| `ordos`, `longcheng` | Koyun 200, at 60, deve 24 | `gazelle`, `pheasant`, `saiga`, `boar` | 3; 40, 40, 30 | Büyük 2, küçük 4, yırtıcı 1 |
| `hexi_ash` | Koyun 80, yak 24, eşek 12 | `gazelle`, `ibex`, `snow_leopard`, `lynx` | 3; 40, 25, 30 | Büyük 2, küçük 3, yırtıcı 1 |
| `mayi`, `baideng` | At T1, T2; öküz 40; katır 12 | `wolf`, `crow`, `pheasant`, `hare`, `deer` | 2; 30, 30 | Büyük 1, küçük 3, yırtıcı 2 |
| `hangai` | Yak 24, koyun 200, at 60 | `deer`, `argali`, `roe`, `bear`, `sable`, `moose` | 4; 30, 30, 25, 25 | Büyük 3, küçük 3, yırtıcı 1 |
| `dingling_north`, `loulan` | At 40; deve 24, eşek 12 | `reindeer`, `sable`, `moose`; `wild_camel`, `kulan` | 2; 30, 40 | Büyük 2, küçük 2, yırtıcı 1 |

| Yaban payı, en kötü kare | Ana üçgen | Çizim | Not |
|---|---|---|---|
| T0 ≤8 (ortalama 2,4k) | 19k | 8 + gölge 8 | `SkinnedMesh`; adlı, avlanan, yakın |
| T1 ≤16 (≤600) | 10k | ≤3 | Gövde planı başına |
| T2 ≤80 (≤360) | 29k | ≤3 | Av ve yırtıcı; sürü satırı ayrıdır (`settlement.md` §17, ≈130k) |
| Kuş ≤64 (≤60) | 4k | 1 | `flock_bird` |
| Zeren akını T3 ≤1.500 | 3k | 1 | Yalnız olay; atlas 512² |
| **Toplam** | **≈65k** | **≤24** | `sanat-animasyon.md` öneri 1 payında (+0,08–0,16M) |

Düzeltme: `survival.md` §4 «≤24 ayrı animasyonlu» → «ajan ≤24, T0 ≤8»; aynı yerin «1,2k kukla»sı T1 ≤600 ve T2 ≤360 olur. `act1.md` §15'te 200 koyun satırı yoktur: ≤60 T2 + 140 T3 ≈22k. JS: `fauna` kare başına ≤0,3 ms, FSM 4 Hz, küme merkez ofsetli (`sanat-animasyon.md` §6). Kayıt: `survival.fauna` ≤0,6 KB. Ses: +8 reçete (`camel_groan`, `cattle_low`, `goat_bleat`, `deer_bugle`, `crane_call`, `marmot_whistle`, `goose_honk`, `tiger_cough`), ≈0,4 MB, 22 kHz, yalnız zonda pişer (K12, #52). Okunurluk: varsayılan kadrajda küçük av ≥15 cm ayrıntı ister; #12 yakınlaşması T0'ı açar.

*Godot için.* Bu tablo prototipin ölçüsüdür, Godot'ya bire bir taşınmaz: Godot çizimi yüzey ve geçiş başına sayar, gölgeyi ayrı sayar. Sayı motorun sayacıyla okunur (`Performance.get_monitor`: `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `TIME_PROCESS`; görünür ve gölge geçişi `Viewport.get_render_info` ile ayrı), bütçe `godot.md` §7.2'dir. Kademe eşlemesi öneri 22'dedir. `JS: fauna ≤0,3 ms` Godot'da GDScript payıdır (kampta toplam ≤3 ms içinde); FSM 4 Hz bir `Timer` ya da biriken `delta` ile döner; ekran dışındaki T0 `VisibleOnScreenEnabler3D` ile durur. `survival.fauna` kaydının yerini Kayıt v2'nin `fauna` bloğu alır (`godot.md` §3.4).

**18. Öncelik: ilk 12 tür (#Ek, Faz 8.6).** At vardır. `sanat-animasyon.md` öneri 18'in ilk üçü aynen başlar. Sıra, gövde planını ve kullanıcının adlarını açar.

| # | id | Plan | Neden | Aynı plandan bedava |
|---|---|---|---|---|
| 1 | `sheep` | `bovid_s` | Ak Otlak 200 koyun, sürü dili, T2 | |
| 2 | `dog` | `canid` | Ku, `Follower` | |
| 3 | `deer` | `cervid` | Kamp, K3 tablosu, iz | `roe`, `izubra` |
| 4 | `wolf` | `canid` | `sq_wolf`, `ev_wolves` | `fox` |
| 5 | `hare` | Küçük | Kapan, kamp | `squirrel` |
| 6 | `marmot` | Küçük | Kamp, Shiji 鳥鼠 | |
| 7 | `crow` | `flock_bird` | Kamp, `sq_crow_war` | `goose`, `partridge`, `pheasant` |
| 8 | `cattle` | `bovid_l` | `cart_ox`, `sled_log` | `yak` |
| 9 | `camel` | `camelid` | Kullanıcı; #39 | `wild_camel` |
| 10 | `goat` | `bovid_s` | `mq_hunt` önkoşulu | `ibex`, `argali` |
| 11 | `gazelle` | `cervid` | Hexi, ilk av, II | `dzeren`, `saiga` |
| 12 | `eagle` | Kuş T0 | Kullanıcı; Kut geçişi | `falcon`, `vulture` |

Sonraki altı: `boar`, `kulan`, `bustard`, `crane`, `bear`, `tiger`. Silüet sınaması her türe uygulanır (`sanat-animasyon.md` §3).

*Godot için.* Plan sütunu (`bovid_s`, `canid`, `cervid` …) prototipin `buildQuad` gövde planıdır. Godot'da plan başına bir 16 kemikli `Skeleton3D` şablonu ve paylaşılan bir `AnimationLibrary` olur; tür, `FaunaKind` Resource'unda oran, renk ve ses taşır (`godot.md` §1, §3). Aynı plandan çıkan tür yeni iskelet ve yeni klip istemez; yalnız ağ ve oran değişir.

**19. Görev kancaları (#20, #38).** Aile «Av» (`oyun-seviye-tasarimi.md`). Metinler `story.md`'nindir. [kurgu, dayanak parantezde]

- II `sq_water_ambush`: Islık Alanı pınarında gece kulan pususu. Köpek `Kal` dersi. (Zhang 2015)
- II `sq_camel_lore`: Nandu'dan deve ve toz dersi; `riding_camel`. Dersi alan toz işaretini 1 oyun saati erken duyar. (Bei Shi 97)
- II `sq_calving`: Zeren doğumu görünür; kol av yasağı ister. Dinlersen hane Gönül +1. (ADW)
- III `sq_red_dog`: Tunghu cenazesi: süslü köpek, Kızıl Dağ. Sözsüz sahne. (HHS 90, MS 1.–2. yy Vuhuan töresi; geriye yansıtma [çıkarım])
- III `sq_wolf_winter`: Stok düşünce kurt ağıla iner; ateş, köpek, kol. (van Duyne)
- IV `sq_first_bird`: Sungur ile doğan yavrusu, 3 oyun günü eğitim.
- VI `sq_white_maral`: Ak Maral izi, Bırak ya da Vur (öneri 11).
- VI Kunmo: `mete-tarih.md` öneri 16 aynen; bu belge kurt ve karga T0'ını verir.

**20. Kültür × hayvan (#32).** Yerleşim paleti `sanat-animasyon.md`'de; sürü burada. Hun: at, koyun, sığır, köpek. Yüeçi: at, koyun; Hexi hattında deve. Tunghu, Vuhuan: sığır, at, koyun, süslü köpek; öküz arabası [çıkarım] (HHS 90'daki 車牛 Han tüccarınındır, §3). Çiang: koyun, yak [çıkarım]. Loulan: eşek, at, çok deve. Han sınırı: öküz, katır, domuz [çıkarım]. Selenga: köpek, koyun, sığır, domuz. Dingling: koyun, sığır; kuzeyde ren [çıkarım]. Yabancı yurt görünüşü sürüyle uzaktan okunur.

**21. Belge düzeltmeleri, topluca (#Ek, #29).** `survival.md` §4 ve `time.md` §9.9: `marmot` `season: spring–autumn`, Kışlak'ta doğmaz; tuzak zarı `hare`e düşer, I. Perde sayısı değişmez (yalnız arada 1 `fat` azalır). `survival.md` §4: `deer` EN adı, `gazelle` açıklaması, `Ceylan, kulan` ve `Tilki, samur` satırlarının ayrılması. `travel.md` §3.2, `economy.md` §4.3: `pack_camel` 60, `pack_horse` eklenir. `economy.md` §9.4: öneri 4 fiyatları. `weather.md` §7.6: öneri 12. Yeni kimlikler prototipte `data/fauna-kinds.js`, `herd-kinds.js`, `items.js` (`fur_big`, `bridle_bone`), `contract-requests.md`'ye; Godot'da `data/fauna/kinds.json`, `data/fauna/mounts.json` ve eşya JSON'una (`godot.md` §2, §3).

**22. Godot için: iskelet, animasyon, sürü, LOD (#Ek, #12, #63).** Oyun Godot 4.7'dedir. Bu öneri yukarıdaki prototip adlarının karşılığıdır; `godot.md` §4.5, §4.6, §4.7, §6.7 ve §7 ile aynı yoldadır. [kaynak: Godot ve Meshy belgeleri; sayılar kurgu]

- **Bugün.** At Meshy ağıdır, iskeleti yoktur; baş, kuyruk ve nefes köşe gölgelendiricisindedir (`game/scripts/camp/horse.gd`, `IDLE_PARAMS`). Model yoksa kodla çizilen yedek at eklemleriyle oynar (`Procedural3D`). `game/tools/meshy_pipeline.py` yalnız `character` türüne rig ister. Meshy'nin rig API'si yalnız insansı alır, insansı olmayanı kapsam dışı sayar ([Meshy](https://docs.meshy.ai/en/api/rigging-and-animation)).
- **T0 iskelet.** Plan başına 16 kemik (`sanat-animasyon.md` §3): Meshy ağı, Blender MCP'de bu iskelete Automatic Weights, glTF ile içe aktarılır; Godot `Skeleton3D` ve `Skin` kurar (`godot.md` §6.7, `varlik-hatti.md` §5.7). Kodla kurulan yedek için `Skeleton3D.add_bone`, `set_bone_parent`, `set_bone_rest` vardır ([Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)). Toynak yere `TwoBoneIK3D` ile oturur (`SkeletonModifier3D`, [belge](https://docs.godotengine.org/en/stable/classes/class_twoboneik3d.html)). Tripo dört ayaklı rigi yalnız tekil yaratıkta (`varlik-hatti.md`).
- **T0 animasyon.** `AnimationPlayer` klipleri: dur, otla, yürü, tırıs, dörtnal, kaç, yat, silkin. `AnimationTree`: hız için `BlendSpace1D`, durumlar için `AnimationNodeStateMachine`, kişneme ve silkinme için `OneShot`. Kök hareketi yalnız binekte; sürü hızı koddan gelir. Düğüm kaynakları örnekler arasında paylaşılır, hayvana özgü değer `parameters/` yolundan yazılır ([AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)). Ekran dışındaki T0 `VisibleOnScreenEnabler3D` ile durur; işaret kaba bir kestirimdir, duvarı saymaz ([belge](https://docs.godotengine.org/en/stable/classes/class_visibleonscreenenabler3d.html)).
- **Sürü T1, T2.** `HerdField` tür ve parça başına bir `MultiMeshInstance3D`'dir. Konumları 4 Hz'lik sürü hesabı verir (`FaunaDirector`: ayrılma, hizalanma, toplanma, kurttan kaçış, öndeki hayvanı izleme); aradaki kareler ara değerlenir. Yürüyüş köşe gölgelendiricisindedir: evre ve hız `set_instance_custom_data` ile `INSTANCE_CUSTOM`'a yazılır ([balık örneği](https://docs.godotengine.org/en/stable/tutorials/performance/vertex_animation/animating_thousands_of_fish.html)). Sürü ajan taşımaz: `NavigationAgent3D` yalnız T0'dadır (köpek, avlanan hayvan, binek); sürü akış alanını izler (`godot.md` §4.7).
- **Kırpma ve LOD.** `MultiMesh` örnek örnek kırpılmaz, ya hepsi çizilir ya hiçbiri ([MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)). LOD da düğüm başınadır: bütün örnekler aynı düzeydedir ([Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)). Bu yüzden büyük sürü 50–100 m'lik parçalara bölünür [kurgu], her parça ayrı düğümdür. İçe aktarılan ağ otomatik LOD alır; deri giydirilmiş ağda LOD bozulursa o ağda kapatılır (aynı belge).
- **Görünürlük aralığı.** T0 yakın, T1 ve T2 orta, T3 kart uzak kademedir (`godot.md` §4.6). `visibility_range_begin`, `visibility_range_end` ve pay kullanılır; solma kipi «Disabled» kalır, çünkü «Self» ve «Dependencies» geçişte saydam çizime zorlar ([Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)). Sınır ekran pikseliyle hesaplanır, metreye çevrilir.
- **Kuş.** Süzülen kartal tek `MeshInstance3D`, kanat köşe gölgelendiricisinde. Karga, kaz ve turna sürüsü tek `MultiMesh`'tir (`flock_bird` karşılığı).
- **Kabul.** Kampa 40 koyun ve uyuyan köpek eklenince görünür çizim en çok +3, GDScript işi en çok +0,3 ms artar; menü karesi değişmez [kurgu]. Ölçüm `godot.md` §7.4'ün bütçe sahnesiyle yapılır.
- **Kredi.** Meshy ağı model başına 40 kredidir (`game/tools/asset_plan.json`). Kredi harcayan her üretim önce kullanıcıya sorulur (`d3/brief.md`).

| Prototip adı | Godot 4.7 karşılığı |
|---|---|
| `buildQuad` gövde planı | Plan başına `Skeleton3D` şablonu; `FaunaKind` Resource (oran, renk, ses) |
| `SkinnedMesh` (T0) | `MeshInstance3D` + `Skin` + `Skeleton3D`, `AnimationTree` |
| Örnekli ağ (T1, T2, `flock_bird`) | `MultiMeshInstance3D` (`HerdField`), `INSTANCE_CUSTOM` |
| `Horse` yeniden ölçek | `Horse.MODEL_LENGTH` çarpanı |
| `Follower` | T0 `Animal` + `NavigationAgent3D` |
| `menuDiff`, `campLife.menuPose` | Menü karesi değişmez kuralı, menü durumunda gizleme (`godot.md` §7.5, §8.5) |
| `game/hunting`, `stealth-core` | `FaunaDirector`, `scripts/sim/stealth/` (saf hesap) |
| `survival.fauna` | Kayıt v2 `fauna` bloğu |
| `data/fauna-kinds.js`, `herd-kinds.js` | `data/fauna/kinds.json`, `data/fauna/mounts.json` |
| `__tanhu.step` | `tools/run_tests.sh` birim testleri (`godot.md` §8) |

## Belirsizlikler

- **Arama bütçesi.** Bu görev sırasında paylaşılan WebSearch sınırı doldu (200). Sonrasında yeni arama yapılmadı; yalnız bilinen sayfalar doğrudan okundu. Kalan boşluklar aşağıdadır. 2026-11-04 doğrulama turu yeni arama ve okuma yaptı; sonuç «Doğrulama» bölümündedir.
- **Okunamayan.** MDPI Egiin Gol, ScienceDirect Ivolga, Soma 2013 (403) ve Soma'nın 2014 tezi (10 MB üstü), Klementiev'in 2017 raporu (403 ya da kısmi). Soma 2012 doğrulama turunda okundu. Egiin Gol'ün sayıları k.b. Ivolga'nın yaban türleri (18 memeli, 14 balık özet parçasından) tek tek okunmadı.
- **Hun sürü oranı.** Bozkır hanesinin oranı için doğrudan veri yok. K24'ün %63 koyunu tasarımdır. Ivolga yerleşiktir, kemik sayısı baş sayısı değildir. [çıkarım]
- **Kuşçuluk.** Hun çağı için kartalla av kanıtı yok. Doğanla atlı avın tek erken görseli Xichagou tokasıdır; MÖ 3. yy tarihi Soma'nındır, bağımsız sınanmadı. Li Si'nin 臂蒼鷹 sözü yalnız Taiping Yulan 926'dadır (MS 10. yy). Kartalın sanatı ve yuvası [kurgu].
- **Köpek.** Davydova'nın üç tipinin dayanağı belirsizdir. Bankhar'ın antikliği ve %93,7 iddiası proje kaynaklıdır, küçük örnektir.
- **Şerh.** 駃騠, 騊駼, 騨騱 türü kesin değildir. Karşılıklar benimdir.
- **Moğol koyun birimi.** At 7, sığır 6, deve 5–7, keçi 0,9 bellekten; doğrulama turunda da kaynak bulunamadı. `camel.lu` 1,3 ile `Kıymet` bu yüzden değişmedi.
- **Han ölçüsü.** Batı Han arşını 23,1 cm (Vikipedi, Batı Han cetveli); Han satırı 23,0–23,8 cm verir. 136 cm yaklaşıktır.
- **Dağılım.** Tablolar modern alanlardır, MÖ 3. yy sınırları k.b. Hentiy ve Hövsgöl'de hangi wapiti olduğu çözülmedi. Çilyan'da yaban keçisinin yokluğu doğrudan okunmadı, yalnız mavi koyunun yaygınlığı okundu.
- **Deve ve at.** Herodot 1.80 doğrulandı: Sardes önünde Kyros yük develerine atlı bindirir, Lidya atları devenin görünüşüne ve kokusuna dayanamaz ([Herodot I](https://en.wikisource.org/wiki/History_of_Herodotus/Book_1), Rawlinson çevirisi). Hun atına taşımak ve 20 m sınırı [kurgu]dur.
- **Tanhu 1 deseni.** Kut ≥14 kartal gölgesi ad ve nesne almaz, ama Tanhu 1'in «kartal Tengri'nindir» desenine yakındır (öneri 11): onay baş mühendisindir.
- **Godot.** Dört ayaklı `Skeleton3D` için 16 kemikli şablon ve klipler henüz yok; Blender MCP ile ağırlık verme ve Tripo yolu kullanıcı onayı ister. Öneri 22'nin sayıları (parça boyu, kabul eşiği) ölçülmedi.
- **Sayılar.** Can, hız, kaçış T'si, Kıymet ve formüller koşulmadı. `tools/econ-sim.mjs` ve `__tanhu.step` ile sınanmalı. `wolfLoss`'un hane dengesini bozmaması beklenir, sınanmadı.
- **Karar isteyen.** Kuşçı Sungur, Karabaş adı, kartal yuva görevi kullanıcı onayına açıktır. Tarbagan ile veba bağı gerçektir, modellenmez.

## Kaynaklar

**Çince metin (Wikisource).**
- [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), [şerhli Shiji 110](https://zh.wikisource.org/wiki/史記三家註/卷110), [Shiji 87 şerhli](https://zh.wikisource.org/wiki/史記三家註/卷087), [Shiji 109](https://zh.wikisource.org/wiki/史記/卷109), [Shiji 122](https://zh.wikisource.org/wiki/史記/卷122), [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123), [Shiji 129](https://zh.wikisource.org/wiki/史記/卷129)
- [Hanshu 5](https://zh.wikisource.org/wiki/漢書/卷005), [Hanshu 28B](https://zh.wikisource.org/wiki/漢書/卷028下), [Hanshu 49](https://zh.wikisource.org/wiki/漢書/卷049), [Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054), [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下), [Hanshu 96A](https://zh.wikisource.org/wiki/漢書/卷096上), [Hanshu 96B](https://zh.wikisource.org/wiki/漢書/卷096下)
- [Hou Hanshu 85](https://zh.wikisource.org/wiki/後漢書/卷85), [Hou Hanshu 89](https://zh.wikisource.org/wiki/後漢書/卷89), [Hou Hanshu 90](https://zh.wikisource.org/wiki/後漢書/卷90), [Wei Shu 103](https://zh.wikisource.org/wiki/魏書/卷103), [Bei Shi 97](https://zh.wikisource.org/wiki/北史/卷097)
- Geç tanıklar: [Taiping Yulan 926](https://zh.wikisource.org/wiki/太平御覽/0926) (MS 977–983), [Liao Shi 32](https://zh.wikisource.org/wiki/遼史/卷32)
- Batı: [Herodot I, Rawlinson](https://en.wikisource.org/wiki/History_of_Herodotus/Book_1) (§80)

**Kazı ve arkeozooloji.**
- [Martin, André, Desroches 2010, Archéopages](https://journals.openedition.org/archeopages/808?lang=es)
- [Miller ve ark. 2018, Antiquity](https://www.cambridge.org/core/journals/antiquity/article/stone-lines-and-burnt-bones-ritual-elaborations-in-xiongnu-mortuary-arenas-of-inner-asia/1A4636F94C9A10D2599280A59E2E7163)
- [Sizova, Klementiev, Sablin 2021](https://izvestiageoarh.isu.ru/en/article?id=267), [tam metin](https://izvestiageoarh.isu.ru/en/article/file?id=267)
- [Wilkin ve ark. 2020](https://eprints.whiterose.ac.uk/159472), [EurekAlert](https://www.eurekalert.org/news-releases/894766), [Berthon ve ark. 2020](https://books.openedition.org/momeditions/8527?lang=de), [China Daily, kartal tacı](https://govt.chinadaily.com.cn/s/202304/06/WS642e6fcc498ea274927b5b56/eagle-shaped-gold-crown-from-more-than-2-000-years-ago.html)

**Tür ekolojisi.**
- Animal Diversity Web: [Procapra](https://animaldiversity.org/accounts/Procapra_gutturosa/), [Gazella](https://animaldiversity.org/accounts/Gazella_subgutturosa/), [Saiga](https://animaldiversity.org/accounts/Saiga_tatarica/), [Equus hemionus](https://animaldiversity.org/accounts/Equus_hemionus/), [Camelus](https://animaldiversity.org/accounts/Camelus_bactrianus/), [Ovis ammon](https://animaldiversity.org/accounts/Ovis_ammon/), [Capra sibirica](https://animaldiversity.org/accounts/Capra_sibirica/), [Capreolus](https://animaldiversity.org/accounts/Capreolus_pygargus/), [Rangifer](https://animaldiversity.org/accounts/Rangifer_tarandus/), [Alces](https://animaldiversity.org/accounts/Alces_alces/), [Sus](https://animaldiversity.org/accounts/Sus_scrofa/), [Canis](https://animaldiversity.org/accounts/Canis_lupus/), [Vulpes corsac](https://animaldiversity.org/accounts/Vulpes_corsac/), [Ursus](https://animaldiversity.org/accounts/Ursus_arctos/), [Uncia](https://animaldiversity.org/accounts/Uncia_uncia/), [Lynx](https://animaldiversity.org/accounts/Lynx_lynx/), [Panthera tigris](https://animaldiversity.org/accounts/Panthera_tigris/), [Martes](https://animaldiversity.org/accounts/Martes_zibellina/), [Aquila](https://animaldiversity.org/accounts/Aquila_chrysaetos/), [Falco cherrug](https://animaldiversity.org/accounts/Falco_cherrug/), [Corvus](https://animaldiversity.org/accounts/Corvus_corax/), [Aegypius](https://animaldiversity.org/accounts/Aegypius_monachus/), [Phasianus](https://animaldiversity.org/accounts/Phasianus_colchicus/)
- [Reading ve ark. 1999, Oryx](https://www.cambridge.org/core/journals/oryx/article/status-of-wild-bactrian-camels-and-other-large-ungulates-in-southwestern-mongolia/68800469DCDDA80FE7592DCF70721C0F), [Singh, Amgalanbaatar, Reading 2010](https://doaj.org/article/a9f3e791f17f47c8acd44ce73316638b), [Zhang ve ark. 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4498657), [CMS, kulan](https://cami.cms.int/es/node/41587), [J. Zool. 2013 sayga](https://works.bepress.com/julie_young1/208)
- [van Duyne ve ark. 2009](https://bioone.org/journals/journal-of-wildlife-management/volume-73/issue-6/2008-027/Wolf-Predation-Among-Reintroduced-Przewalski-Horses-in-Hustai-National-Park/10.2193/2008-027.full), [Tiralla, Hentiy kurdu](https://openpolar.no/Record/ftsubgoettingen:oai:publications.goettingen-research-online.de:2%2F79643)
- [One Earth, Çilyan](https://www.oneearth.org/ecoregions/qilian-mountains-conifer-forests/), [Duke Kunshan, mavi koyun](https://swce.dukekunshan.edu.cn/2022/projects/summer-distribution-of-blue-sheep-pseudois-nayaur-in-the-qilian-mountains-the-influence-of-livestock-grazing-and-the-implications-for-conservation-strategies/), [HMW, Cervus canadensis](https://treatment.plazi.org/id/03a087c4ffd5-ffd4-ff60-fa22efd5f46a), [Taymen göçü](https://worldwidescience.org/topicpages/h/hucho+taimen+pallas.html)
- Başlangıç noktası Vikipedi: [Mongol atı](https://en.wikipedia.org/wiki/Mongolian_horse) (boyu kullanılmaz), [Çin Moğol atı](https://en.wikipedia.org/wiki/Chinese_Mongolian_horse) (DAD-IS, Porter ve ark. 2016), [Kar leoparı](https://en.wikipedia.org/wiki/Snow_leopard), [Çin ölçü birimleri](https://en.wikipedia.org/wiki/Chinese_units_of_measurement), [Baktriya devesi](https://en.wikipedia.org/wiki/Bactrian_camel), [Yak](https://en.wikipedia.org/wiki/Domestic_yak), [Przewalski atı](https://en.wikipedia.org/wiki/Przewalski%27s_horse), [Altai wapiti](https://en.wikipedia.org/wiki/Altai_wapiti), [Manchurian wapiti](https://en.wikipedia.org/wiki/Manchurian_wapiti), [Tarbagan](https://en.wikipedia.org/wiki/Tarbagan_marmot), [Tolai tavşanı](https://en.wikipedia.org/wiki/Tolai_hare), [Turna](https://en.wikipedia.org/wiki/Demoiselle_crane), [Toy kuşu](https://en.wikipedia.org/wiki/Great_bustard), [Kaz](https://en.wikipedia.org/wiki/Bar-headed_goose), [Taymen](https://en.wikipedia.org/wiki/Hucho_taimen)

**Köpek, kuşçuluk, av töresi.**
- [Bankhar Dog Project](https://www.bankhar.org/bankhar-dogs/), [Five Jewels](https://www.bankhar.org/the-five-jewels/), [SCMP](https://www.scmp.com/print/lifestyle/travel-leisure/article/3013514/dogs-could-stop-mongolian-grasslands-turning-desert-return), [Five Snouts](https://www.eternal-landscapes.co.uk/the-five-snouts-of-mongolias-herders/)
- [Soma 2012, ACSS bildirisi, tam metin](https://falconryheritage.org/uploads/itemUploads/3186/ACSS2012_0271.pdf), [Soma 2012 özeti](https://www.academia.edu/14642222/Takuya_Soma_2012_Ethnoarhchaeology_of_Horse_Riding_Falconry_Proceedings_of_ACSS_2012_), [Soma 2013](https://papers.iafor.org/wp-content/uploads/papers/accs2013/ACCS2013_0108.pdf) (okunamadı), [Soma, Kassel tezi](https://falconryheritage.org/uploads/itemUploads/3718/DissertationTakuyaSoma.pdf) (okunamadı), [Hunting with eagles](https://en.wikipedia.org/wiki/Hunting_with_eagles)
- Yurdun taşınması: [Three Camel Lodge](https://www.threecamellodge.com/10-surprising-facts-about-the-ger) (turizm kaynağı)
- [Aça 2007, TÜBAR XXI](https://dergipark.org.tr/en/download/article-file/156891)

**Oyun.** [Assassin's Creed Origins](https://en.wikipedia.org/wiki/Assassin%27s_Creed_Origins).

**Godot 4.7 ve Meshy belgeleri.** [MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html), [Binlerce balığı canlandırmak](https://docs.godotengine.org/en/stable/tutorials/performance/vertex_animation/animating_thousands_of_fish.html), [Görünürlük aralıkları](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html), [Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html), [AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html), [Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html), [TwoBoneIK3D](https://docs.godotengine.org/en/stable/classes/class_twoboneik3d.html), [VisibleOnScreenEnabler3D](https://docs.godotengine.org/en/stable/classes/class_visibleonscreenenabler3d.html), [NavigationAgent](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html), [Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html); [Meshy rig ve animasyon](https://docs.meshy.ai/en/api/rigging-and-animation).

**Proje.** [register.md](../design/d3/register.md), [decisions.md](../design/decisions.md), [economy.md](../design/economy.md), [survival.md](../design/survival.md), [progression.md](../design/progression.md), [army.md](../design/army.md), [travel.md](../design/travel.md), [weather.md](../design/weather.md), [settlement.md](../design/settlement.md), [time.md](../design/time.md), [act1.md](../design/act1.md), [sanat-animasyon.md](sanat-animasyon.md), [mitoloji.md](mitoloji.md), [mete-tarih.md](mete-tarih.md), [oyun-seviye-tasarimi.md](oyun-seviye-tasarimi.md), [godot.md](../design/godot.md), [varlik-hatti.md](varlik-hatti.md); prototip kodu: `src/data/herd-kinds.js`, `src/game/herds.js`, `src/character/horse.js`; Godot kodu: `game/scripts/camp/horse.gd`, `game/scripts/world/scatter.gd`, `game/tools/meshy_pipeline.py`, `game/tools/asset_plan.json`.

## Doğrulama

**Tarih:** 2026-11-04. Şüpheci tur; yazarın kaynaklarına güvenilmedi, her iddia yeniden açıldı. **Sınanan iddia: 56.** 24'ü birincil metinde doğrudan okundu (zh.wikisource), 5'i kazı yayınında (Ivolga'nın Rusça tam metni dahil), 20'si tür, töre ve Batı kaynağında, 7'si proje belgeleri ve Godot koduyla. Düzeltilenler bağımsız kaynakla sınandı.

**Düzeltilenler.**

1. Moğol atı boyu 142–152 cm değil ≈122–142 cm, ortalama 1,28 m (DAD-IS, Porter ve ark. 2016). Hata İngilizce Vikipedi'den geliyordu; Gol Mod ölçümü ve Han yasasıyla çelişiyordu (§3).
2. HHS 90'daki 車牛 Vuhuan arabası değil, MS 135'te Vuhuan'ın yolda kestiği Han tüccar arabalarıdır. `cart_ox`'un dayanağı Ivolga'ya çekildi, öneri 20'de öküz arabası [çıkarım] oldu.
3. Hanshu 94A: ganimet üç değil beş ordunundur (萬餘, 二千餘, 七千餘, 百餘, 七萬餘; sonuncusu şişirilmiş). «Sıra hep at, sığır, koyun» → «hemen hep» (bir satırda 牛馬羊).
4. Vuhuan'ın köpek ve Kızıl Dağ töresi MS 1.–2. yy tanıklığıdır. III. Perde'deki sahne «Tunghu cenazesi» oldu ve [çıkarım] etiketi aldı (§1.3, öneri 9, 16, 19).
5. «Hitan atlı kartalcıları» yanlıştı: Liao Shi 32'de Hitan bahar avı 鷹 ve 海東青鶻 (ak doğan) iledir, kartal geçmez.
6. Vikipedi'nin kuşçuluk tarihi zincirleme kaynak olarak işaretlendi (Soma 2013 ve popüler bir sayfa). Soma 2012 okundu: Xichagou tunç tokası, ≈2.300 yıllık atlı doğancılık. Özet 4 ve §4'ün sonucu buna göre yazıldı.
7. Li Si'nin 臂蒼鷹 sözünün yeri bulundu: Taiping Yulan 926 (MS 977–983), geç ve tek tanık.
8. Kar leoparı için «insana saldırı kaydı yok» → bilinen üç vaka, hiçbiri ölümcül değil.
9. «Bir deve bir yurt taşır» gerçeğe uymuyordu: yurt eşyasıyla iki üç deveye yüklenir. `pack_camel` 60 önerisi kalır; metin «iki deve: yurt ve eşya» olur, deve yüklü hane 2 yüklü deveyle gelir (Özet 8, öneri 6).
10. Kaçış hesabı: Hun atı ceylanı 12 sn'de değil, ≈30 + d sn'de yakalar; zeren de kulan gibi sürek ister (öneri 2).
11. `yak` kimlik çelişkisi giderildi: kendi sürü satırı vardır, hane sürüsünde ve Kıymet'te `cattle` gibi sayılır (öneri 3).
12. Zeren: kurt avı kış sonu, bahar ve yaz başıdır; %90'lık doğum bir sürünün dişileri içindir.
13. Küçükler: Gol Mod'da kap bakır alaşımlıdır; köpek başka Hun mezarlıklarında vardır; çukurda 15 küçükbaş kafatası; Ivolga'da deve ile yak birlikte %1; deve hızı «sürekli 40, en çok 65 km/sa»; ≈250 avcı yalnız Bayan-Ölgii'dedir; yedi gün sözü Lienü zhuan'dandır; Shuowen MS 100'dür; Bei Shi 97 yaz sıcak rüzgârıdır, MS 5.–7. yy.
14. Etiketler: Herodot 1.80 [kurgu] → [kaynak]; Han arşını 23,1 cm doğrulandı; «Soma 2014» ve «Soma 2016» atıfları okunamadı, gerekçe [kurgu] ya da k.b. oldu; Moğol koyun birimi yine k.b.
15. Tasarım uyumu: #39'un iki türü beş görünüşe bağlandı (`d3/brief.md`); #29'un öteki iki kalemi yazıldı (Tahıl Çuvalı 12 var, arbalet oku bu belgenin dışında).
16. Tanhu 1: ad ve nesne bulunmadı (`progression.md` ile sınandı; Karabaş, Sungur, Ak Maral, Ku orada yok). Kut ≥14 kartal gölgesinin «kartal Tengri'nindir» desenine yakınlığı not edildi (öneri 11).
17. Godot: Özet 11, öneri 14, 17, 18, 21'e «Godot için» ekleri ve yeni öneri 22 (`Skeleton3D`, `AnimationTree`, `TwoBoneIK3D`, `MultiMeshInstance3D`, `INSTANCE_CUSTOM`, görünürlük aralığı, LOD, `Performance` ölçümü, ad eşleme tablosu). Dayanak: Godot 4.7 belgeleri, Meshy rig belgesi, `game/scripts/camp/horse.gd`, `game/tools/meshy_pipeline.py`, `godot.md`.

**Doğru bulunup değiştirilmeyenler.** Shiji 110'un hayvan, çocuk avı, at sahnesi, dört renk, mektup armağanı, Dailin ve MÖ 127 satırları; Shiji 109, 122, 123 (Wusun'un 4–5 bin atı Shiji 123'te de vardır); Hanshu 5, 49, 94B, 96B; HHS 85, 89 ve HHS 90'ın haraç, mevsim, armağan ve Sienpi satırları; şerh glosları; Ivolga'nın bütün yüzdeleri, köpek boyu ve kesik izi; Martin ve ark. ile Miller ve ark.'nın ana bulguları; Wilkin ve ark. 2020; Aluchaideng tacı; Aça 2007'nin bütün töre maddeleri; zeren, karaca, argali, altın kartal, samur (ADW'ye göre), kulan (gece ve alacada içme %84,93), van Duyne 2009; Kıymet hesabı (`economy.md` §2, §3.11 değerleriyle); hane sürüsü (35, 10, 7, 4, ½ ≈18 at eşdeğeri).

**Açık kalan.** Moğol koyun birimi, Xichagou tokasının bağımsız tarihi, Soma 2013 ve tezi, Han dönemi hayvan fiyatı, öneri 22'nin ölçülmemiş sayıları.
