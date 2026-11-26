# Bozkır ekonomisi: para, tarım, akın, kervan, araba

Bu belge Hun döneminin ekonomisini kaynakla sınar ve cevap #29, #36, #39, #41, #42, #43, #45, #48 ile Karar Bekleyenler 2 (para birimi) ve 12 (savaştan malzeme) için oyunun sayılarına bağlı kural önerir. Tanhu 1'den bir şey almaz. Kod değiştirmez: öneriler `economy.md`, `settlement.md`, `travel.md` ve modele işlenmek içindir. Her bilgi [kaynak], [çıkarım] ya da [kurgu] etiketi taşır. Hesaplar `tools/econ-sim.mjs` ve modelin geçici kopyasıyla yapıldı, proje dosyası değişmedi. Oyun Godot 4.7 ile `game/` klasöründe yapılır; `src/` ve `tools/econ-sim.mjs` prototipin ölçüm araçlarıdır, Godot karşılıkları öneri 15'tedir. En önemli 12 iddianın bağımsız kaynakla sınaması belgenin sonundadır (Doğrulama).

## Özet

1. Hun'un sikke bastığına dair kaynak bulunamadı. Han sikkesi Hun'a armağan olarak gider ve mezarda çıkar. Gümüş Qin ve Han'da para sayılmazdı.
2. Para birimi önerisi **Kabuk / Cowrie**, «Kümüş» değil. Dayanak: kabuk ve tunç taklidi Hun kemerlerinde yaygındır; Ivolga'da kabuğun para olarak kullanıldığı varsayılır. Para işlevi bağımsız kaynakla doğrulanmadı, seçim [kurgu]dur.
3. 1 kabuk = 4 Kıymet = 1 Aş. I. Perde'de yok, II'den görünür. Terazi kalır, üstü kabukla verilir, satıcının kesesi vardır.
4. #29: sığır 240 (kodun 336'sı otlak ölçeğinden, simin 120'si kesim değerinin altında), keçi 40, deve 504, Tahıl Çuvalı 12 ve IV'ten, arbalet oku 1,5.
5. #41: Surlu tarlası V'te ürün veremez. Hasat Kronik'in yıllık adımına girer, %102 V'in değil VI'nın kışıdır.
6. #42: Ocak'ta kervan yok. Onluktan bir atlı iki günde bir 2 öğün alır.
7. #43: ordugâh akını yalnız III ve IV'te, dolunay penceresinde ve toplantı günü dışında, perde başına en çok 1, 4 ya da 6 atlıyla olur. Tam ordugâhta başarı ≤%5,2'dir, başarılıysa yalnız at gider.
8. #45: R tablosu III 6, IV 10, V 16 kalır, bitiş koşulu ve ordugâh sütunu eklenir. Ambarcı kap kaybını ×0,75 yapar. V'in oynanan günlerinde akın yoktur, tek pencere Baideng'e düşer.
9. #36: sur parçasının odunu 4'ten 16'ya çıkar. Surlu odun ≈×1,4 ister, iki yolun günü 8,1 ve 7,8 olur.
10. #48: araba Atölye kategorisinde tek karttır. #39: gelen hane iki türdür: Yüklü Hane (evi at ve develerde, yurtlu ya da çadırlı) ve İsteyen Hane. Oranlar kaynağa bağlıdır.
11. Doğrulama: 12 iddianın 9'u bağımsız kaynakla doğrulandı, 2'si kısmen; darının olgunlaşma süresi düzeltildi. Satıcı keseleri, IV'ün ay penceresi ve V'in akın sayısı yeniden hesaplandı.

## 1. Hun döneminde para ve takas

### 1.1 Yazı yok, sayım var

- SJ 110: 毋文書，以言語爲約束. Yazı yoktur, söz bağlar [kaynak: [SJ 110](https://zh.wikisource.org/wiki/史記/卷110)].
- Yantie lun, MÖ 81 tartışması: 刻骨卷木，百官有以相記. Kemik ve ağaç çentikle kayıt tutulur [kaynak: [Yantie lun 52](https://zh.wikisource.org/wiki/鹽鐵論/卷九)].
- Sayım zaten vardır: 秋，馬肥，大會蹛林，課校人畜計 [kaynak: SJ 110]. Zhonghang Yue yazılı sayımı Mete'den sonra getirir: 疏記，以計課其人眾畜物 [kaynak: SJ 110].
- Göktürk için aynı desen: 其徵發兵馬，科稅雜畜，輒刻木為數 [kaynak: [Zhoushu 50](https://zh.wikisource.org/wiki/周書/卷50)]. Hun için [çıkarım].
- Sonuç [çıkarım]: Hun'da ölçü hayvandır, kayıt çentiktir, sikke ölçü değildir.

### 1.2 Sikke

Mete'nin ömrünün sikkesi ban liang'dır. Wu zhu ondan 56 yıl sonra çıkar.

| MÖ | Sikke | Ağırlık | Kaynak |
|---|---|---|---|
| 221'den | Ban liang, 12 zhu | ≈7,2 g | [Ban Liang](https://en.wikipedia.org/wiki/Ban_Liang) |
| Han kuruluşu | Karaağaç tohumu (莢錢), halk döker | ≈0,4 g | [HS 24B](https://zh.wikisource.org/wiki/漢書/卷024下), Ban Liang |
| 186 | 8 zhu | ≈5 g | Ban Liang |
| 182 | 5 fen | ≈1,5 g | Ban Liang; Nishijima, [Han Economy](https://en.wikipedia.org/wiki/Economy_of_the_Han_dynasty) üzerinden |
| 175 | 4 zhu (孝文五年) | ≈2,6–3 g | HS 24B |
| 118 | Wu zhu (元狩五年) | ≈3,2 g | HS 24B |

- Han kuruluşunda sikke hafif, fiyat uçuktur: 米至石萬錢，馬一匹則百金 [kaynak: [SJ 30](https://zh.wikisource.org/wiki/史記/卷030)]. V. Perde'nin Han sikkesi bu sikkedir [çıkarım].
- Hun alanında: Tamir mezarlığında sikke çıkar [kaynak: [Waugh, Xiongnu arkeolojisi](https://depts.washington.edu/silkroad/archaeology/mongolia/xiongnu/xiongnuarchhist/xiongnuarchhist.html)]. Bir mezarda lake kutu içinde küçük bir dizi wu zhu bulunur [kaynak: [Waugh 2006, The Silk Road](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/The-Challenges-of-Preserving-Evidence.pdf)]. Wu zhu olduğu için en az MÖ 118'den sonradır [çıkarım]. Kutu içinde durması para gibi değil, değerli eşya gibi saklandığını düşündürür [çıkarım].
- Moğolistan'daki Hun yerlerinden yalnız iki tür Çin sikkesi çıkar: wu zhu (MÖ 118'den) ve huo quan (MS 14'ten). Tamir Ulaan Khoshuu 201'de on wu zhu boru gibi bir dizi halindedir [kaynak: [Multidisciplinary Studies in Archaeology 2022/2, 37–50](https://repository.kulib.kyoto-u.ac.jp/dspace/bitstream/2433/286450/1/2658-3550-2022-2-37-50.pdf); metin arama aracıyla okundu, dosya doğrudan açılmadı].
- Tuva'da Ala-Tey 1 mezarlığında wu zhu kadın kemerinin kenar süsüdür: «bronze Chinese coins ran all the way around them» [kaynak: [The History Blog 2019](https://www.thehistoryblog.com/?p=56375), IIMK RAS fotoğraflarıyla; [Ancient Origins](https://www.ancient-origins.net/news-history-archaeology/tighten-your-belt-2200-year-old-xiongnu-jewelry-made-coal-jade-and-coral-021656), kazı başkanı Kilunovskaya'nın sözüyle]. Han sikkesi Hun'da süstür [çıkarım].
- Ban liang'ın Hun alanında çıktığına dair **kaynak bulunamadı**.
- Han Tanhu'ya sikke de verir: 51 yılında 錢二十萬 [kaynak: [HS 94B](https://zh.wikisource.org/wiki/漢書/卷094下)]. Bu Mete'den 123 yıl sonradır.
- Hun'un kendi sikkesi için **kaynak bulunamadı**.

### 1.3 Altın ve gümüş: süs, armağan, mezar

- Qin kuralı: 黃金以溢名，為上幣；銅錢…為下幣。而珠玉、龜貝、銀錫之屬為器飾寶藏，不為幣. Altın üst para, tunç alt paradır; inci, yeşim, kabuk, gümüş ve kalay para değil süs ve hazinedir [kaynak: SJ 30]. Aynı kural Ban Gu'nun derlemesinde de vardır: 而珠玉龜貝銀錫之屬為器飾寶臧，不為幣 [kaynak: [HS 24B](https://zh.wikisource.org/wiki/漢書/卷024下)].
- Gümüş ancak Wu Di'nin gümüş-kalay parasıyla para olur, MÖ 119 dolayı [kaynak: SJ 30].
- Batıda aynı tavır: 得漢黃白金，輒以為器，不用為幣. Han altın ve gümüşü kap olur, para olmaz [kaynak: [SJ 123](https://zh.wikisource.org/wiki/史記/卷123)]. Bu söz Dayuan'dan batıya içindir, Hun için [çıkarım].
- Hun'da: 其送死，有棺槨金銀衣裘 [kaynak: SJ 110]. Noin-Ula 22'de gümüş koşum levhaları [kaynak: [Polosmak ve Bogdanov 2013](https://scfh.ru/en/papers/traces-of-chinese-chariot/)]. Kuzey Çin atölyelerinde Hun için yapılmış gümüş levhalar [kaynak: Bunker 2002, [Ordos culture](https://en.wikipedia.org/wiki/Ordos_culture) üzerinden].
- Han altını ağırlıkla sayar: 黃金方寸，而重一斤 [kaynak: HS 24B]. Hun'un madeni tarttığına dair **kaynak bulunamadı**. Xigoupan altınlarındaki Çince ağırlık yazıları hafızadandır, doğrulanamadı.
- `economy.md` §9.1'in «gümüş ve tunç tartılır» sözü böylece Han pratiğinden Hun'a çıkarımdır, kaynak değildir [çıkarım].

### 1.4 İpek, tahıl, heqin

| MÖ | Kaynak | Ne gider |
|---|---|---|
| 198 | SJ 110 | 歳奉匈奴絮繒酒米食物各有數: ipek yumağı, ipek, içki, pirinç, yiyecek, yıl başına belli miktar; sayı yazmaz |
| ≈174 | SJ 110 | Wen'in armağanı: giysi takımları, altın süslü kemer, 10 işleme, 30 brokar, 40'ar kumaş |
| Wen dönemi | SJ 110 | 秫糱金帛絲絮佗物歳有數: maya, altın, ipek, yıllık |
| 89 | [HS 94A](https://zh.wikisource.org/wiki/漢書/卷094上) | Hulugu ister: 糱酒萬石，稷米五千斛，雜繒萬匹. 5.000 hu ≈ 100.000 L [kaynak: Han Economy] |
| 51 | HS 94B | 黃金二十斤，錢二十萬，衣被七十七襲，錦繡綺縠雜帛八千匹，絮六千斤; ayrıca ≈680.000 L tahıl [kaynak: Han Economy] |

- Hun atı Han malına, özellikle ipeğe değişilir [kaynak: Liu 1988, Han Economy üzerinden]. Tarım'da yol ve yiyecek ipekle ödenir [kaynak: aynı].
- Qin çağında: 烏氏倮牧，及眾，斥賣，求奇繒物，閒獻遺戎王。戎王什倍其償，與之畜. Sürü satılır, ipek alınır, Rong kralına verilir, kral on katını hayvan olarak öder [kaynak: [SJ 129](https://zh.wikisource.org/wiki/史記/卷129)]. Bu, oyundaki İpek Top için en yakın çağ kaydıdır.
- Zhonghang Yue Han ipeğini çalıda yırtıp küçümsetir ama nedeni şudur: 今單于變俗好漢物，漢物不過什二，則匈奴盡歸於漢矣 [kaynak: SJ 110]. Hun Han malını sever. Söz Mete'den sonradır.
- Moğol çağından benzer: Rubruck altın ve gümüşle değil, yalnız keten ve kumaşla alışveriş yapabildiğini yazar; yoksul darı ve unu koyun ve postla alır [kaynak: [Rubruck](https://depts.washington.edu/silkroad/texts/rubruck.html)]. 14 yüzyıl sonradır, benzerlik [çıkarım].

### 1.5 Sınır pazarı ve kaçak

- İlk resmî kayıt Jing dönemidir: 孝景帝復與匈奴和親，通關市 [kaynak: SJ 110; HS 94A aynı: 景帝復與匈奴和親，通關市]. Wu Di: 通關市，饒給之. Yani Mete'den sonra.
- Kaçak mal: 聶翁壹奸蘭出物與匈奴交 [kaynak: SJ 110].
- MÖ 129: Han atlıları pazarın altında vurur: 擊胡關市下 [kaynak: HS 94A].
- MS 84: 驅牛、馬萬餘頭来與漢賈客交易. 10.000'den çok sığır ve at [kaynak: [HHS 89](https://zh.wikisource.org/wiki/後漢書/卷89)].
- Demir yasağı Lü döneminde Güney Yue için: 高后時，有司請禁南越關市鐵器 [kaynak: [SJ 113](https://zh.wikisource.org/wiki/史記/卷113)]. At yasağı MÖ 146: 禁馬高五尺九寸以上…不得出關 [kaynak: [HS 5](https://zh.wikisource.org/wiki/漢書/卷005)].
- Mete'nin sağlığında resmî sınır pazarı için **kaynak bulunamadı**. VI'nın `vendor_han_border`'ı [kurgu]dur; resmî olmayan yer pazarı sayılmalıdır [çıkarım].
- Vikipedi'nin Xiongnu maddesi Laoshang'ın Wen ile «government sponsored market system» üzerine anlaştığını dipnotsuz yazar [kaynak: [Xiongnu](https://en.wikipedia.org/wiki/Xiongnu)]. SJ 110 ve HS 94A bunu desteklemez.

### 1.6 Kabuk

- Ivolga'da kabuğun para olarak kullanıldığı varsayılır: «Предположительно, в качестве денег на городище использовали раковины каури.» Gerçek kabuk, tunçtan taklit ve işlenmiş kabuk çıkar [kaynak: [Иволгинское городище](https://ru.wikipedia.org/wiki/Иволгинское_городище); dipnotların özgün metni okunmadı]. Aynı makale kabuğu süs hammaddesi olarak da anar. Kanıt düzeyi «varsayım»dır.
- Bağımsız tanık: kabuklu kemerin en eski örnekleri Geç İskit çağındandır (MÖ 4.–2. yy), en yaygın olduğu çağ Hun çağıdır (MÖ 2. yy – MS 2. yy). Hun kemeri İskit kemerinden kadın mezarlarında, süs sırasının sayısında ve kabuk taklitlerinde ayrılır [kaynak: Trubnikova, Kilunovskaya, Leus 2025, Ulan Bator derlemesi III, [özet](https://archeo.academia.edu/VarvaraTrubnikova); sayfa 403 verdi, özet arama aracıyla okundu]. Ala-Tey'de kadın kemerinde «bronze imitations of cowrie shells» ve wu zhu birliktedir [kaynak: Ancient Origins, Kilunovskaya].
- Bu kaynaklar kabuğu süs ve kemer eşyası olarak anar, para olarak değil. Kabuğun ve tunç kabuğun Mete'nin yüzyılında Hun dünyasında var olduğu sağlamdır; para işlevi yalnız Ivolga maddesinin varsayımıdır [çıkarım].
- Ivolga'nın tarihi tartışmalıdır, çoğu görüş MÖ 2.–1. yy der; Davydova en erken kuruluşu MÖ 3. yy sonu aynalarına dayandırır [kaynak: aynı]. Mete'den sonra olabilir.
- Çin'in eski parası kabuktu: 或錢，或布，或刀，或龜貝; Qin onu paradan çıkarır [kaynak: SJ 30]. Çin'de paradan düşen kabuğun kuzeyde süs ve ölçü olarak yaşaması mümkündür [çıkarım].

## 2. Hayvan birimleri ve #29 sınaması

**Kaynaklar.**
- Moğolistan'ın bugünkü sürü ölçüsü «koyun ot birimi»dir: 1 koyun 1, 1 keçi 0,9, 1 deve 5, 1 sığır 6, 1 at 7. Bu ot gereksinimidir, fiyat değil: «1 SFU expresses the feeding requirement of 1 sheep for one year» [kaynak: [Rao ve ötekiler 2015](https://iopscience.iop.org/article/10.1088/1748-9326/10/7/074012)]. Aynı katsayılar Moğolistan Tarım Bakanlığı'nın 2019 yöntemine dayanılarak da verilir [kaynak: [Tseveg-Ochir ve ötekiler 2024](https://koreascience.kr/article/JAKO202411643744808.page); katsayılar PDF'ten arama aracıyla okundu].
- Geleneksel **bod** oranı için iki turda da **kaynak bulunamadı**. Hafızadan, doğrulanmadı: 1 at ya da 1 sığır = 1 bod, 1 deve ≈1,5 bod, 1 bod ≈7 koyun.
- Han oranı: 陸地牧馬二百蹄，牛蹄角千，千足羊. 集解: 五十匹 ve 百六十七頭也。馬貴而牛賤，以此爲率 [kaynak: SJ 129, [üç yorum](https://zh.wikisource.org/wiki/史記三家註/卷129)]. Yani 50 at ile 167 sığır aynı geliri verir. Koyuna yorum yoktur: 1.000 ayak ÷ 4 = 250 koyun [çıkarım]; 韋昭'nın «二百五十頭»ü sonraki satırın domuzu (千足彘) içindir. Aynı liste Ban Gu'nun derlemesinde de vardır [kaynak: [HS 91](https://zh.wikisource.org/wiki/漢書/卷091)]. At pahalı, sığır ucuz.
- İkinci liste: 馬蹄躈千，牛千足，羊彘千雙. Xiao Yan (Yan Shigu) okumasıyla 200 at, 250 sığır, 2.000 koyun ve domuz [kaynak: aynı; sığır ve koyun için yorum yok, sayılar [çıkarım]].
- Sürü bileşimi: 其畜之所多則馬、牛、羊，其奇畜則橐駞、驢、驘 [kaynak: SJ 110]. Deve, eşek, katır seyrektir.
- Kazak ve Kırgız oranları için **kaynak bulunamadı** ([Жеты Жаргы](https://ru.wikipedia.org/wiki/Жеты_Жаргы) sayı vermez).

**Sınama** (koyun = 1).

| Tür | Kod | Sim | Öneri | Oran | Ot birimi | SJ 129 / 1. liste | SJ 129 / 2. liste | Kesim Kıymeti |
|---|---|---|---|---|---|---|---|---|
| Koyun | 48 | yok | 48 | 1 | 1 | 1 | 1 | 36 |
| Keçi | 40 | yok | 40 | 0,83 | 0,9 | yok | yok | 26 |
| At | 336 | 336 | 336 | 7 | 7 | 5 | 10 | 106 |
| Sığır | 336 | 120 | **240** | 5 | 6 | 1,5 | 8 | 126 |
| Deve | 437 | yok | **504** | 10,5 | 5 | yok | yok | 142 |

**Bulgular [çıkarım].**
- `barter.js` keçi, sığır ve deveyi at eşdeğeriyle (`lu`) ölçekler. `lu` otlak ölçüsüdür, fiyat değildir. Sığır otlakta at kadar yer ama 馬貴而牛賤.
- Simin 120'si kesim değerinin altındadır. `buyK` 0,9 iken 108'e alınan sığır 126 Kıymet mal verir: %17 kâr, döngü doğar. 240 bu sınamayı geçer: 216 > 126. Öteki türler de geçer.
- 240, at/sığır oranını 1,4 yapar. Han yorumunun iki okuması 1,25 ile 3,3 arasıdır, içindedir.
- Deve fiyatı kaynakta yok. 504 = 1,5 at, seyrek hayvan ve 176 mektubunda listenin başındadır: 獻橐他一匹，騎馬二匹，駕二駟 [kaynak: SJ 110]. 504 [kurgu]dur, hafızadaki bod oranıyla uyuşur.
- Modelin deve `lu` değeri 1,3, ot birimine göre ≈0,7 ata denk gelir. Etkisi küçüktür (hane başına ½ deve), `fauna.md` ile birlikte bakılmalı.

## 3. Hun tarımı ve kış erzakı

### 3.1 Kanıt

- Metin «tarla işi yoktur» der: 毋城郭常處耕田之業 [kaynak: SJ 110]. Yine de Hun tahılı vardır: 連雨雪數月，畜產死，人民疫病，穀稼不孰 [kaynak: HS 94A].
- MÖ 119'da Han ordusu Zhao Xin kalesinde Hun tahılını yer, kalanı yakar: 得匈奴積粟食軍…悉燒其城餘粟 [kaynak: [SJ 111](https://zh.wikisource.org/wiki/史記/卷111); aynı olay [HS 55](https://zh.wikisource.org/wiki/漢書/卷055)'te: 遂至窴顏山趙信城，得匈奴積粟食軍].
- Hun 車師'te (Turfan yöresi) tarla açar ve o tarla için savaşır: 昭帝時，匈奴復使四千騎田車師; 單于必爭此地，不可田也 [kaynak: [HS 96B](https://zh.wikisource.org/wiki/漢書/卷096下)]. Mete'den sonradır.
- Beslenme: geç dönemde (makale Erken Demir, Hun ve Moğol çağını birlikte sayar) darının kalori payı yere göre ortalama ≈%3–26'dır, en çok orta kuzey Moğolistan'da. Gol Mod ve Noyon Uul'daki Hun hükümdar mezarlarında kavuzuyla darı bulunur [kaynak: [Wilkin ve ötekiler 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7054399/)]. Çobanlar zaman zaman darı eker [kaynak: [Bower 2023](https://www.sciencenews.org/article/asia-xiongnu-nomadic-empire-expansion)].

### 3.2 Ivolga

Bilgiler [Иволгинское городище](https://ru.wikipedia.org/wiki/Иволгинское_городище) maddesinden, Davydova 1985, 1995 ve Kradin'e dayanarak; özgün metinler okunmadı [kaynak].

- Başlıca ürün darı; arpa, buğday, çavdar da var. Demir saban ucu, kürek ucu, orak, öğütme taşı, sığır kemiğinden çapa.
- Kradin: 5 km içinde ≈34,5 km² verimli toprak. **Ekime uygun yalnız Mayıs'ın üç haftası.** En çok 1.800 ha sürülür, ≈1,32 milyon kg ürün: ≈733 kg/ha (hesap).
- 1974 kazısında 740 m²'de 86 çukur. Büyük tahıl çukuru 5–5,6 × 2–2,7 m, üstü örtülü.
- Kemik payı: köpek %29, koyun %22, sığır %17, domuz %15, at %12, keçi %4, deve ve yak %1. Aynı madde başka bir sayımda sığırı %30,8 («основная тягловая сила»), domuzu %23 verir; iki sayımın farkı açıklanmaz.
- Halk karışıktır. Davydova tarlada Çinli sığınanların ve tutsakların çalıştığını önerir. Sürüsünü yitirip yoksullaşan Hun da vardır.

### 3.3 Takvim ve verim

- En hızlı darı çeşidi ekimden ≈60 gün sonra ürün verir; 10–13 °C altına duyarlıdır; Avrupa'da ekim Nisan ortası–Mayıs sonudur, biçim Ağustos sonu–Eylül ortasıdır [kaynak: [Proso millet](https://en.wikipedia.org/wiki/Proso_millet)]. Minnesota ve Wisconsin'de olgunlaşma 70–90 gündür, darı dona duyarlıdır [kaynak: [Purdue, Alternative Field Crops Manual: Millets](https://hort.purdue.edu/newcrop/afcm/millet.html)]. Süre çeşide ve enleme göre 60–90 gündür [çıkarım].
- Oyun takvimi önerisi [çıkarım]: ekim 10–31 Mayıs, biçim 1–20 Eylül. Ekimle biçim arası 93–133 gündür, iki süreyi de kapsar.
- Modelin tarlası 0,2 ha'da 500 darı (250 öğün) verir. 1 öğün ≈0,72 kg tahılsa (§6.1) ≈900 kg/ha eder. Kradin'in 733 kg/ha'sına yakındır [çıkarım]. Sayı değişmez.

### 3.4 Kış erzakı ve kurutma

- Rubruck: ölen öküz ya da atın eti ince şeritler halinde güneşte ve rüzgârda tuzsuz kurutulur; kurut güneşte demir cürufu gibi sertleşir, torbada kışa saklanır; inek yağı kışa kalır; kışın kurut suda çırpılır, süt yerine içilir [kaynak: Rubruck]. 13. yy'dır, `dried_meat` ve `qurt` için benzerlik [çıkarım].
- Tahıl köylerden gelir: seçkin için kışın darı ve un taşınır, yoksul koyun ve postla alır [kaynak: Rubruck]. Bu, K24'ün `tradeRationPerDay` (kışın 0,5) çizgisinin dayanağıdır [çıkarım].
- Kış sonunda kurut ve peynir azalınca av ve toplama açığı kapatır [kaynak: [Mongolian cuisine](https://en.wikipedia.org/wiki/Mongolian_cuisine), dipnotsuz]. K24'ün «bilerek dar kış» kuralıyla uyuşur.
- Zud oranı: 2009–2010 kışında sürünün ≈%20'si, 1944–45'te %33'ü gider [kaynak: Rao 2015]. Oyunun kış tavanı %30 bu aralıktadır.
- Soğum için bu turda birincil kaynak okunamadı.

## 4. Akın ve baskın kültürü

- **Ay.** 舉事而候星月，月盛壯則攻戰，月虧則退兵. Ay dolunca saldırır, eksilince çekilir [kaynak: SJ 110; HS 94A aynı: 舉事常隨月，盛壯以攻戰，月虧則退兵]. `mete-tarih.md` öneri 10 aynı kuralı önerir, `time.md` ay hattı hazırdır.
- **Zayıf yeri kollama.** 候備塞之卒，卒少則入. Sınır erini gözler, azsa girer [kaynak: Chao Cuo, [HS 49](https://zh.wikisource.org/wiki/漢書/卷049)].
- **Çözülme.** 其見敵則逐利，如鳥之集；其困敗，則瓦解雲散矣 [kaynak: SJ 110; HS 94A: 故其逐利，如鳥之集；其困敗，瓦解雲散矣]. Akıncı karşılık görünce dağılır: «kolay def edilen» akının tarih yüzü [çıkarım].
- **Ganimet.** 所得鹵獲因以予之 [kaynak: SJ 110]. Küçük akının nedeni budur [çıkarım].
- **Sıklık.** 匈奴日已驕，歳入邊，殺略人民畜產甚多 [kaynak: SJ 110]. Yılda birkaç akın, sınır boyunca. Bir kampa kaç kez geldiğine dair **kaynak bulunamadı**.
- **Baskına uğrayan ordugâh.** 右賢王以爲漢兵不能至，飲酒醉，漢兵…夜圍右賢王 [kaynak: SJ 110]. Geceleyin, gevşek nöbette.
- **Nöbet.** Li Guang'ın kampı sade ama 遠斥候，未嘗遇害; Cheng Bushi: 虜卒犯之，無以禁也…我軍雖煩擾，然虜亦不得犯我 [kaynak: [SJ 109](https://zh.wikisource.org/wiki/史記/卷109)]. Uzak gözcü ve sıkı nöbet iki yoldur. Han tarafı için [kaynak], Hun için [çıkarım].
- **Köpek.** Barış sözü: 邊城晏閉，牛馬布野，三世無犬吠之警 [kaynak: HS 94B]. Köpek havlaması sınırın alarmıdır. Ivolga'da köpek kemiği en büyük paydır (§3.2).
- **Barımta.** Kazak ve Kırgız töresi, haksızlığı telafi için hayvan alma. Atlar, develer, koyun, sığır ve taşınır mal hedeftir. Grodekov'a göre gündüz ve ilanla yapılır [kaynak: Donuk, [TDV Baranta](https://islamansiklopedisi.org.tr/baranta)]. Kan davasından korkulduğu için keskin silahtan kaçınılır, sonra hesap görülür [kaynak: Dal, [Баранта](https://ru.wikipedia.org/wiki/Барымта)]. Kişi sayısı kaynaklarda yoktur. Hun'dan 2.000 yıl sonraki bir töredir; oyunda hırsızlık davası ve hayvan hedefli küçük akın için model olur [çıkarım].
- **Hırsızlık.** 坐盜者沒入其家 [kaynak: SJ 110, `settlement.md` S9].

## 5. Ordu erzak zinciri ve kervan

- Hun ordusu kendini besler: 資糧不見案首，而支數十日之食，因山谷為城郭，因水草為倉廩 [kaynak: Yantie lun 52]. 胡人衣食之業不著於地 [kaynak: Chao Cuo, HS 49].
- Han tersine zincire bağlıdır. Yan You: 計一人三百日食，用糒十八斛…牛又當自齎食…軍出未滿百日，牛必物故且盡 [kaynak: HS 94B].
- Zhao Chongguo: bütün güç ayda 199.630 hu tahıl, 1.693 hu tuz, 250.286 shi ot; 10.281 kişilik birlik 27.363 hu tahıl, 308 hu tuz [kaynak: [HS 69](https://zh.wikisource.org/wiki/漢書/卷069)].
- Zhang Qian'ın heyeti: 將三百人，馬各二匹，牛羊以萬數. Üç yüz kişinin yemeği on binlerce baş sürüyle yürür [kaynak: SJ 123]. Bu bir Han elçiliğidir, Hun ordusu için [çıkarım].
- Sonuç [çıkarım]: K24'ün düz %10'u doğru yöndedir. Ordu Payı ana besin değil, bağ ve küçük destektir. Tarih «yerleşim orduyu besler» demez.

## 6. Arabalar ve yük hayvanları

### 6.1 Bir Yük kaç kilo

Yan You'nun 18 hu / 300 gün sayısı günde 0,06 hu eder. 1 hu ≈20 L [kaynak: Han Economy]. Kavrulmuş tahıl ≈0,6 kg/L varsayımıyla 0,72 kg/gün [çıkarım]. 1 öğün 0,1 Yük olduğundan **1 Yük ≈7 kg** [çıkarım].

| Oyun | Yük | ≈kg | Kaynak sayısı |
|---|---|---|---|
| `pack_camel` | 30 | 210 | Baktriya devesi 170–250 kg, 47 km/gün [kaynak: [Bactrian camel](https://en.wikipedia.org/wiki/Bactrian_camel)]; Moğol kervanında deve başına 100–200 kg, sırtta 160–240 kg [kaynak: [Erdenebileg 2022](https://www.irci.jp/rdb/item/13405)]: uyar, üst uçtadır |
| Binek terkisi | 30–50 | 210–350 | Binicisiyle at 125 kg [kaynak: [Transport Geography](https://transportgeography.org/contents/chapter1/emergence-of-mechanized-transportation-systems/pre-industrial-travel-modes/)]; midilli 70 kg, katır ≈91 kg [kaynak: [Pack animal](https://en.wikipedia.org/wiki/Pack_animal)]: oyun 2–3 kat cömert, I. Perde sözleşmesidir, değişmez |
| `yurt_kit` | 59 | 410 | Yurdun ağırlığı için **kaynak bulunamadı**; deve ya da yakla taşınır [kaynak: [Yurt](https://en.wikipedia.org/wiki/Yurt)] |
| `cart_felt` | 60 | 420 | Yan You: bir askerin 300 günlük 18 hu kuru azığı öküz gücü ister, öküzün kendi yemi 20 hu ekler: 非牛力不能勝；牛又當自齎食，加二十斛 [kaynak: HS 94B]. Öküz başına 38 hu ≈760 L ≈450 kg [çıkarım, §6.1 yoğunluğuyla]: uyar |

### 6.2 Kanıt

- **Hun arabası.** 匈奴車器無銀黃絲漆之飾，素成而務堅. Hun'un arabası ve kap kacağı süssüz, sağlamdır [kaynak: Yantie lun 52]. `travel.md` §3.1 «Hunların kendi arabası için kanıt yok» der; yazılı kanıt vardır, biçim bilinmez.
- **Yük katarı.** HS 94A Hun'un 輜重'ini (ağırlık, yük katarı; 輜 örtülü yük arabasıdır) üç kez anar: 單于聞漢兵大出，悉遣其輜重 [kaynak: HS 94A]. Taşıtın biçimini söylemez [çıkarım].
- **Metal.** Hun ordusu koşum, temren ve araba için metal ister [kaynak: Brosseder, Bower 2023]. Demir teknolojisi Çin'den değil Güney Sibirya'dandır [kaynak: [Sasada ve Amartuvshin 2014](https://www.jstage.jst.go.jp/article/isijinternational/54/5/54_1017/_article)].
- **Han armağan arabası.** Noin-Ula 22: iki tekerli, tenteli `yao che`, tek ya da çift at, tekerler sökülmüş, armağan kabul edilir [kaynak: Polosmak ve Bogdanov 2013]. Tsaraam 7 ve Gol Mod 1'de Han arabası [kaynak: Waugh]. MÖ 51'de Huhanye'ye 安車一乘 verilir; Wang Mang: 賜安車鼓車各一 [kaynak: HS 94B]. Hepsi Mete'den sonradır.
- **Tanhu'nun arabası.** 單于遂乘六驘 [kaynak: SJ 111]. Altı katırla çekilen araç diye okunur [çıkarım]. Katır 奇畜'dir.
- **Keçe göç arabası.** Hippokrates: en küçüğü dört, kimi altı tekerli, keçeyle örtülü, iki ya da üç çift öküz; kadınlar arabada, erkekler atta [kaynak: [Airs, Waters, Places 18](https://classics.mit.edu/Hippocrates/airwatpl.18.18.html); öteki çeviri aynı: «drawn by two or by three yoke of hornless oxen», [Perseus](https://atlas.perseus.tufts.edu/library/passage/urn:cts:greekLit:tlg0627.tlg002.perseus-eng4:17-20)]. Pazyryk 5'te dört büyük parmaklı tekerli sökük araba [kaynak: [Pazyryk burials](https://en.wikipedia.org/wiki/Pazyryk_burials)]. Rubruck: bir kız 20–30 arabayı sıra halinde götürür; yüksek arabaları deve çeker [kaynak: Rubruck].
- **Araba halkası.** 大將軍令武剛車自環為營 [kaynak: SJ 111]. Han yapar, `wagon_ring` için dayanak.

## 7. Gelen hanenin eşyası (#39)

- Sığınan seçkin adamlarıyla gelir: 燕王綰悉將其宮人家屬騎數千居長城下; 率其黨數千人降匈奴 [kaynak: [SJ 93](https://zh.wikisource.org/wiki/史記/卷093), SJ 110].
- Sıradan Çinli sığınan zanaat ve tarım bilgisiyle gelir, keçe evi yoktur [çıkarım; Davydova, Ivolga maddesi].
- Sürüsünü yitiren Hun yoksullaşır [kaynak: Ivolga maddesi]. Bu, çadır isteyen hanenin tarih yüzüdür [çıkarım].
- Bozkırda sürüsü olmayana hayvan ödünç verme töreleri için bu turda **kaynak bulunamadı** (Kazak «saun» hafızadan).
- Taşıma: `yurt_kit` 59 Yük iki at ya da iki deveye, `tent_kit` 16 Yük bir ata yeter (`economy.md` §4.3). Yurt deve ya da yakla taşınır [kaynak: Yurt].

## 8. Savaştan malzeme (Karar 12)

- 其攻戰，斬首虜賜一卮酒，而所得鹵獲因以予之 [kaynak: SJ 110]. 戰而扶輿死者，盡得死者家財 [kaynak: SJ 110]. Düşmüş arkadaşını taşıyan onun malını alır.
- K24'ün belirli ganimeti ve «Paylaş / Alıkoy» kararı bu satırlara dayanır. Karar Bekleyenler 12'nin yönü (I. Perde'den sonra açık dünyada ganimet) K24 ile aynıdır, çelişki yoktur.
- Esir yoktur (K23), tarihte vardır: 得人以爲奴婢 [kaynak: SJ 110]. Destan Kitabı bunu söyler.

## Oyuna öneriler

### 1. Para birimi: Kabuk (Karar 2)

**«Kümüş» sınaması.** Sözcük sağlamdır: KT güney 5 «altun kümüş işgiti kutay» [kaynak: [Kül Tigin](https://tr.wikisource.org/wiki/Orhun_Yaz%C4%B1tlar%C4%B1_(K%C3%BCl_Tigin))], Eski Türkçe kümüš [kaynak: [Wiktionary](https://en.wiktionary.org/wiki/Reconstruction:Proto-Turkic/kümüĺ)]. Ama para adı olarak zayıftır:

| Ad | Dayanak | Sorun | Karar |
|---|---|---|---|
| Kümüş | 8. yy yazıtı | Gümüş dönemde para değil (§1.3). «8 Kümüş = 1 Gümüş Parça» karışır. 1 Aş'a 1 gümüş, gümüşü ucuzlatır. EN'de okunmaz | Hayır |
| Yarmak | *yār- «yarmak» [kaynak: [Wiktionary](https://en.wiktionary.org/wiki/yarmak)]; «sikke» anlamı Karahanlı, hafızadan | 13 yy sonra. Bugün fiil diye okunur | Hayır |
| Tamga | Eski Türkçe damga, hayvan işareti [kaynak: [Tamga](https://en.wikipedia.org/wiki/Tamga)] | Sonradan gümrük vergisi. Birim değil | Hayır; kabuğun üstünde işaret olabilir |
| Çentik | §1.1 | Kefeye konmaz, yabancı saymaz | Sayım dilinde kalır (`mete-tarih.md` öneri 14) |
| Akçe | Yaygın söz | Osmanlı çağrışımı | Hayır |
| **Kabuk** | Ivolga, SJ 30, Hun kemerlerindeki kabuk ve tunç taklit (§1.6) | Para işlevi varsayım düzeyinde; Ivolga'nın tarihi Mete'den sonra olabilir | **Evet** |

**Kural.**

| Alan | Değer |
|---|---|
| Ad | Kabuk / Cowrie; eşya «Tunç Kabuk / Bronze Cowrie»; kimlik `cowrie` |
| Oran | 1 kabuk = 4 Kıymet = 1 Aş (`travel.md` §7.2 değer tablosu aynen kabuk olur) |
| Ağırlık | 100 kabuk 0,1 Yük (`per: 100`) |
| I. Perde | Yok. K24 dondurur, Mete rehinedir, Terazi sayısızdır |
| II'den | Görünür. İlk kez Tanhu pazarcısında. Pazarcı: «Burada sayarız. Bir Aş, bir kabuk.» / «Here we count. One meal, one cowrie.» |
| Hun satıcısı | Tanhu pazarcısı, Takas Yeri gezgini, Çiang tuzcusu: kabuk `sellK` 1, üstü verir, kesesi vardır |
| Yabancı satıcı | Saka, Hexi vahası, sınır pazarı, Dingling: kabuk `sellK` 0,6, üstü vermez, mal ister |
| Tartılan maden | `silver_bit` 8, `gold_old` 24 kabuk; II'den Hun satıcısında `sellK` 1 |
| Han sikkesi | `economy.md` §9.1 kalır: V'te `bronze_scrap` gibi tartılır, bir dizi 3 kabuk [kurgu]. Pazarcı: «Yaprak gibi.» / «Light as a leaf.» |
| Etiket | Hun'un kabuk saydığı `tasarım tercihi`dir, Destan Kitabı'nda yazılır: «Hun sikke basmadı. Kemerine kabuk dikti, tunçtan taklidini döktü. Ivolga'da kabuğun para olduğu düşünülür.» [kurgu; dayanak §1.6] |

**K ve belge çelişkisi.** `economy.md` §9.1 ve §14 karar 8 ile `progression.md` §16.1 karar 6 («para yok») II'den itibaren değişir. K23'ün armağan listesine satır eklenir (öneri 3). K24'ün I. Perde kuralı korunur.

### 2. Terazi ve arayüz (Karar 2)

Terazi ekranı tek kalır, paket 8.7 bunu baştan bilerek yazılır.

```
take = Σ worth × buyK
give = Σ worth × sellK + cowrie × 4 × cowrieK    // cowrieK: Hun satıcısı 1, yabancı 0,6
kabul: give ≥ take
üstü = min(purse, floor((give − take) / 4))      // yalnız keseli satıcı
yazı: satıcı kefesi yukarı, oyuncu kefesi aşağı yuvarlanır; satır değil toplam yuvarlanır
```

- **I. Perde:** bugünkü Terazi, sayı yok.
- **II'den:** kiriş ve «Denk / Eksik / Fazla» kalır. Her kefenin altında «Eder {n}», üstte «Kese {n}», «Fazla»da «Üstü {n} kabuk» / «{n} cowries back».
- **Kese yetmezse:** «Kesem yetmez.» / «My purse won't cover it.» Üstü kesenin dışındaki fazlalık gider. Oyuncu kabul düğmesinden önce görür.
- **Fiyat etiketi:** kefedeki mal satır satır kabuk yazar. Kıymet sözü oyuncuya hiç çıkmaz. Söz'ün ve bağın etkisi fiyatta görünür.
- **Ok, temren gibi küçük mal:** deste yazılır (10 tunç ok ≈5 kabuk).
- **Heybe:** üst satırda «Kese {n}». HUD'a eklenmez.
- **Hazine:** terazi kalır, yanında «≈{n} kabuk» (`settlement.md` §12.5).
- **Yol bedeli:** Aş ya da kabukla ödenir, 1:1.

### 3. Kese, kaynak ve harcama (Karar 2)

| Satıcı kesesi (şafakta dolar) | Kabuk | Dayanak |
|---|---|---|
| Tanhu pazarcısı | 52 | Şafak stoğu 208 Kıymet ÷ 4 (§9.5 stoğu, model Kıymetleri) |
| Çiang tuzcusu | 26 | Şafak stoğu 104 Kıymet ÷ 4 (tuz 80, bakır cevheri 16, Uyku Otu 8) |
| Takas Yeri gezgini | 30 | [kurgu] |
| Yabancı satıcılar | 0 | Takas ister |

- **Neden kese.** Parayla oyuncu her şeyi satabilir; takasta `give`, `take` ile sınırlıydı. Kese bu sınırı geri getirir. Satıcılar arası %11 kâr tavanı (1 ÷ 0,9) aynen kalır, kese ve stokla sınırlıdır.
- **At satışı.** 84 kabuk keseyi aşar. Satıcı mal karşılığı alır ya da üstünü veremez. Bu bilerektir: büyük mal takasla döner.
- **Kaynak.** Teoman'ın kesesi 24 kabuk (K23 listesine ek; T1'in pazardan alacağı iki Tündük ≈19 kabuktur). Satış. Görev. `guard_hun` 0,5, `guard_elite` 1 kabuk (öneri 5). IV'ten `rc_cowrie`: Demirci Ocağı, usta, 1 `bronze_scrap` → 3 kabuk, 1 İS; oran 12 ÷ (12 + 0,75) = 0,94, K24 bandında.
- **Harcama.** Pazar, Yol bedeli, Divan'da kefaret (öneri 13), Toy'da saçı: hane başına 1 kabuk, toyun Gönül'ü +6 yerine +8 [kurgu].
- **Sınır.** Hiçbir kademe kapısı kabuk istemez. `--strict` varlık sınamasına eklenir: kabuksuz da her kademe biter. Kabuk kısayoldur. Kâhya kabuk harcamaz, K24 `tradeRationPerDay` soyut kalır.
- **Kronik.** Kabuğa dokunmaz. Hazine'deki kabuk baskında %30 kaybolur, Mete'nin kesesi güvendedir.

### 4. #29 tam fiyat tablosu

Tek sahip: `econ-model.json` `herds.<id>.worth`. `barter.js` `HERD_WORTH` ve `econ-sim.mjs` `HW` oradan okur.

| Mal | Kıymet | Kabuk | Perde | Not |
|---|---|---|---|---|
| Koyun | 48 | 12 | II | Değişmez |
| Keçi | 40 | 10 | II | Değişmez |
| At | 336 | 84 | II | Değişmez |
| Sığır | **240** | 60 | II | Kod 336, sim 120 kalkar. Sınır pazarı ve Hun pazarı ister (HHS 89 牛馬) |
| Deve | **504** | 126 | II | Kod 437 kalkar; `lu` 1,3 otlak için kalır |
| Tahıl Çuvalı | 12 | 3 | **IV** | §9.4 V yazar, §9.5 Hexi vahası IV'te satar. İlk perde IV, model `act: 4`. Heqin V–VI |
| Arpa Torbası | 8 | 2 | I | Değişmez |
| Arbalet oku `bolt` | **1,5** | 3 / 8 adet | V | Yeni eşya kaydı; 10 adet 0,5 Yük. 8 `bolt` = 1 `bronze_scrap` (`rc_melt_bolt`, Demirci Ocağı). Hun yayıyla atılmaz |
| İpek Top | 48 | 12 | V | Pazarda düşük, armağanda değerli (öneri 13) |
| Şarap Küpü | 32 | 8 | V | Değişmez |
| Yurt Yükü | 240 | 60 | II | Değişmez |
| Çadır Yükü | 42 | 10,5 | II | Değişmez |
| Tündük | 30 | 7,5 | I | Değişmez |
| Demir Külçe, Tunç Külçe | 16, 20 | 4, 5 | I, II | Değişmez |
| Gümüş Parça, Eski Altın | 32, 96 | 8, 24 | I | Değişmez |

`fauna.md` eklerse: eşek 144 (36), katır 240 (60) [kurgu]. Kural: yeni tür koyun oranıyla yazılır, canlı × 0,9 > kesim Kıymeti sınanır, `lu` ayrı kalır.

**Ganimete etkisi** (hesap): `han_wagon` 175,2 → 296,7 (0,9 sığır 216, 9 `bolt` 13,5). `xbow_han` 2,3 → 15,8. Öteki satırlar aynı. V'in perde dakikası değişmez, ganimet emek değildir.

### 5. Savaştan malzeme (Karar 12, #29)

- K24 aynen kalır: I. Perde düşmanı yeni mal vermez, II'den belirli ganimet, sayaç, rastgele yok, adlı silah elle, esir yok.
- Ek 1: `guard_hun` 0,5 ve `guard_elite` 1 kabuk, sayaçla. Yabancı düşmanda kabuk yoktur.
- Ek 2: def edilen akının düşenleri aynı tablodan verir (`rider_donghu`, `lancer_yuezhi`), ×0,6 toplanan pay, «Paylaş / Alıkoy» kararı küçük akında sorulmaz, Paylaş sayılır.
- Ek 3: Karar 12 `acik-sorular.md`'den kalkar; `toplama.md` metni `economy.md` §3.12'ye gönderir.

### 6. #41 Darı tarlası ve Kronik

- **Takvim.** Ekim 10–31 Mayıs, biçim 1–20 Eylül. Kâhya yapar, kart çıkmaz. Emek model gibi 0,5 + 0,5 İG.
- **V'te ürün yok.** Surlu yol 20 Kasım 201'den sonra seçilir, tarla kurulur, kar altında boş durur. V'in kışı tarlasızdır: Surlu %91, Göçer %90 (`economy.md` §7.1). `%102` satırı V'ten kalkar, «VI'dan itibaren» diye yazılır. Tahıl Kulesi'nin %50'si de güzden sonra işler. Sim tarlayı V kışına saymaz (varlık sınaması).
- **Kronik'in yeni adımı** (`settlement.md` §16.2, adım 2'den sonra): `court_path = walled` ve ≥1 `field` ise yıl başına hasat işlenir; ambara yalnız **son hasat** yazılır: `min(500 × tarla, boş tahıl yeri)`. Öncekiler yenmiş sayılır. Emek ve bakım bu adımın içindedir. Kronik'te hava ve akın yoktur. Perde kartı satırı: «Tarlalar {n} darı verdi.» / «The fields gave {n} measures of millet.»
- **VI'nın oynanan günleri.** 1 Haziran 198 yeşil, 13 Şubat 192 karlı boş, 4 Haziran 176 yeşil, 9 Eylül 174 sarı ve biçimde (`mete-tarih.md` §2, §4). Görünüm yalnız takvimden okunur.
- **Akın.** Haziran–Eylül arası başarılı yerleşim akını güzdeki ürünün %30'unu çiğner: 候秋孰，以騎馳蹂而稼穡耳 [kaynak: SJ 110; sayı [kurgu]].
- **Göçer yol.** Tarla yok, darı pazardan. Çobanların ara sıra darı ekmesi [kaynak: Bower] ayrı sistem açmaz, hanenin takas payında sayılır [çıkarım].

### 7. #42 Ocak'ta Ordu Payı

- **Tek kural.** Ocak'ta kervan yoktur. **Azıkçı / Ration Rider**: onluktan bir atlı iki günde bir (Tan'da) Ocak Yeri'ne gelir, 2 öğün (0,2 Yük) alır, terkisiyle gider.
- `economy.md` §8.5'in sayısı değişmez: 1 öğün/gün. Sütun adı «Kervanla» yerine o satırda «Azıkçı».
- Araba, sürücü (`haul`), koruma, Kervan Buyruğu ve yol olayı yoktur. Kervan Oba'yla açılır (`settlement.md` §4.1). Defter'in Kervan sekmesi Ocak'ta: «Onluğun azığını bir atlı alır.» / «A rider fetches the Ten's rations.»
- Ambarda 2 öğün yoksa atlı boş döner, o gün birlik `morale` −1. Başka bedel yok.
- Teoman'ın arabası Mete'nindir, Ocak'ta kervan için kullanılmaz.
- Tarih: Hun birliği azığını kendi çıkarır (§5).

### 8. #43 Ordugâh akını

**Kimlik:** `camp_raid`, «Gece Akını / Night Raid». Kural K24'ün tek formülüdür.

| Soru | Kural |
|---|---|
| Hangi perde | III, IV. II'de Teoman'ın barışı, V'te ordugâh kışın dağınık, VI'da heqin |
| Hangi gece | Yalnız `moon ≥ 0,97` (ayda ≈3,3 gün) [kaynak: SJ 110 月盛壯則攻戰] |
| Tarihler (hesap, `time.md` §2 formülü) | III: 14,8–18,1 Eylül 208. IV: 15,8–19,1 Haziran 205; 24,1–27,4 Haziran 203. Gün kapısıyla (`moon_illum(day_n + 0,5)`, öneri 15): III 15–17 Eylül, IV 16–18 Haziran 205 ve 24–26 Haziran 203, V 27–29 Kasım 201. III, IV 205 ve V `mete-tarih.md` öneri 10 ile aynıdır |
| Toplantı günü | Dailin (16 Eylül 208) ve Lung-çeng (17 Haziran 205) günü akın yazılmaz; akın pencerenin ilk gecesine düşer: III 15 Eylül, IV 16 Haziran 205 (`mete-tarih.md` öneri 3, 5, 10) |
| Pencere başına | 1 akın. Hedef `D`'si küçük olan yer, eşitse yerleşim [kaynak: HS 49 卒少則入] |
| Tavan | Ordugâha perde başına en çok 1. Kronik işlemez |
| Güç | `R_camp = ⌈R × 0,6⌉`: III 4, IV 6 atlı |
| Hedef | Yalnız at hattı. Ambar, ok, çadır etkilenmez |
| `D` | `nöbetçi × (1 + 0,5 × kule) + garnizon`. Nöbetçi: ordugâhtaki atlı ÷ 10 [kurgu]. Kule: Gözcü Kulesi ve Konağı (`army.md` §3.7). Garnizon: ordugâhtaki atlı |
| Boş ordugâh | Birlik seferde: kendiliğinden 1 Onluk bekçi kalır |

| Durum | Atlı | Kule | D | Başarı R 4 | Başarı R 6 |
|---|---|---|---|---|---|
| Yüzlük | 100 | 0 | 110 | %3,5 | %5,2 |
| Binlik | 200 | 2 | 240 | %1,6 | %2,4 |
| Binlik | 400 | 2 | 480 | yok | %1,2 |
| Bekçi Onluk | 10 | 0–2 | 11–12 | %25–27 | %33–35 |

Normal oyunda ordugâhın `D`'si yerleşiminkinden büyüktür (III: 240 ve 26), akın yerleşime gider. Ordugâh ancak birlik seferdeyken hedef olur. Beklenen kayıp III'te ≈1 at, IV'te ≈2 at.

**Sonuç.**

| Sonuç | Mete ordugâhta | Mete uzakta |
|---|---|---|
| Püskürtüldü | Küçük dövüş, ≤6 atlı, 3 düşünce ya da 45 sn sonra dağılırlar (如鳥之集). Ganimet öneri 5 | Kart: «Gece akıncılar at hattına geldi. Nöbet püskürttü.» / «Riders came for the horse line in the night. The watch drove them off.» |
| Ödül | Birlik `morale` +2, `loyalty` +1 | Birlik `morale` +1 |
| Başarılı | Her akıncı bir at götürür (III 4, IV 6). 60 sn içinde `horse_call` ile yakalanan döner (`economy.md` §3.12). `morale` −2 | Kart: «Bekçiler yetişemedi: {n} at gitti.» / «The watch came too late: {n} horses are gone.» |

**Uyarı** (K22'nin üç kanal deseni): uyarı süresi = görüş ÷ at hızı (≈9 m/sn). Konak 400 m ≈44 sn, Kule 300 m ≈33 sn (`army.md` §3.7 görüşleri), köpek ≈20 sn. Boru sesi, kısa bildirim, atlas işareti. Sis nöbeti ×0,5 yapar (`settlement.md` §15.3); köpek varsa ceza işlemez (`fauna.md`) [kurgu; dayanak §4]. Pencere açılırken Kâhya: «Ay doluyor. Atları içeri alın.» / «The moon is filling. Bring the horses in.» Oyuncu takvimden okur.

**Sahne önerisi** (hikâye alanı karar verir): III'ün ilk penceresi Dailin'den (16 Eylül) önceki geceye düşer. Tunghu atlılarının dört atlık küstahlığı 東胡初輕冒頓 satırına yaslanır, sahnelenirse tek ordugâh akını budur [kurgu].

`field_camp` bu kuralın dışındadır, yalnız hikâye sahnesi. `ev_raid` (kervan) değişmez.

### 9. #45 Akın gücü ve Ambarcı

| Perde | Akıncı | R yerleşim | R ordugâh | Biter ya da düşer |
|---|---|---|---|---|
| II | Yok | 0 | 0 | Teoman'ın barışı |
| III | Tunghu atlıları | 6 | 4 | `donghu_land` kazanılınca 0 |
| IV | Yüeçi; Loufan, Baiyang | 10 | 6 | Ordos katılınca 6 ve 4; Yüeçi sürülünce 0 |
| V | Han sınır birliği, dağılmış çeteler [kurgu] | 16 | Yok (kış) | Baideng'den sonra 8 |
| VI | Yok | 0 | 0 | Heqin; hikâye sahnesi ayrı |

- **Sıklık.** `settlement.md` §15.4'ün «8, 14, 12 günde bir»i kalkar, ay penceresi gelir. Cevap #19 perde sayacını kaldırdığı için gün aralığı süresiz akın üretirdi. Yerleşime perde tavanı: III 2, IV 2, V 1. Oynanan takvimle beklenen: III 1, IV 1–2, V 0. V'in oynanan günlerindeki tek pencere (27,0–30,3 Kasım 201) Baideng kuşatmasına düşer, o pencerede akın yazılmaz (`mete-tarih.md` öneri 10). V'in tavanı perde bittikten sonra Serbest Dolaşım'da işler (sonraki pencere 26,5–29,8 Aralık 201); akın Mete uzaktayken kartla çözülür.
- `warK` (Çekim ×0,5) yalnız ay penceresinde ve perde tavanı dolmamışken işler.
- **Ambarcı (`m_quarter`).** `kap kaybı × (Ambarcı ? 0,75 : 1)`. Başarıya dokunmaz. Yerleşim ve ordugâh kapları: Ambar Yurdu, Tahıl Ambarı, Sundurma, Tahıl Kulesi, Ambar Çukuru, Erzak Ambarı. Hazine (kendi kule çarpanı), ot sundurması yangını, sürü kaybı dışındadır. K24'ün ≤%10 sınaması Ambarcısız sütunla yapılır, Ambarcı seçmelidir.
- **Def edilen akın.** Gönül +1 (yeni satır). «Baskın yendi −6» kalır.

**Tek akının beklenen ambar kaybı** (`econ-sim` D değerleriyle; kaybı başarı × %30 × 0,7):

| Perde | D | Başarı | Kayıp | Ambarcı | Garnizonsuz | Ambarcı, garnizonsuz |
|---|---|---|---|---|---|---|
| III | 26,0 | %18,8 | %3,9 | %3,0 | %10,5 | %7,9 |
| IV | 50,9 | %16,4 | %3,4 | %2,6 | %6,8 | %5,1 |
| V Surlu | 112,5 | %6,2 | %1,3 | %1,0 | %2,1 | %1,6 |
| V Göçer | 104,7 | %13,3 | %2,8 | %2,1 | %4,8 | %3,6 |

`economy.md` §10.8'in D'leri (26,8; 50,6; 96,5) eskidir, bugünkü sim yukarıdakini basar. III garnizonsuz %10,5 hedefe sayılmaz (V6, «boş bırakmanın bedeli»).

### 10. #36 Surlu yolun farkı

**Bulgu.** Kataloğa göre iki yolun odunu eşittir, «odun ≈2×» yanlıştır. Tarih ise Surlu'yu odunla öder: 穿井數百，伐材數千 (`settlement.md` S11), Ivolga'da kalın kütük duvar. Metni zayıflatmak yerine malzeme düzelir.

**Kural.** `rampart` (10 m) `tag:wood` 4 → **16**. 40 parça 640 odun. Geçici sim koşusu, 0 işaret:

| | Surlu, bugün | **Surlu, öneri** | Göçer |
|---|---|---|---|
| Odun (tarifle açılmış) | 1.153 | **1.633** | 1.158 |
| Taş, kil | 350, 98 | 350, 98 | 262, 18 |
| Keçe, ip, demir | 174, 246, 30 | 174, 246, 30 | 282, 376, 62 |
| Kurma emeği İG | 91,1 | 91,1 | 54,9 |
| Ham Yük | 6.133 | **8.053** | 6.771 |
| Gün (payla), hedef 4–12 | 6,7 | **8,1** | 7,8 |
| Mete dk, hedef ≤45 | 21,4 | **27,0** | 24,9 |
| V perde dakikası, tavan 85 | 41,1 | 46,7 | 44,6 |

Odun sayısı yapı malzemesinin tarife göre açılmasıyla bulundu. Site 1.178 ve 1.195 yazar, fark açma yöntemindendir, sonuç aynıdır: bugün iki yol eşittir. Ham Yük, gün ve Mete dakikası bugünkü simdendir, `economy.md` §10.6'nın eski sayılarından değil.

- **Neden 16.** İki yolun süresi eşitlenir, seçim hızla değil malla olur. Surlu odun, taş, kil ve emek ister; Göçer keçe, ip, demir ister.
- **Seçenekler.** 24: gün 9,0, odun ×1,7. 30: gün 9,7, odun ×1,9, Mete 33,6. «≈2×» isteniyorsa 30 da hedefte kalır ama Surlu açıkça yavaşlar.
- **Kereste kervanı.** Zondaki odun IV'te biter (`settlement.md` §3.2). Fazladan 480 odun `wood_larch` ise 1.920 Yük, ≈14 `cart_war` seferi. #48 ile bağlanır, araba Surlu yolunda iş görür.
- **Metin.** §4.3 «odun ≈×1,4, kurma emeği ≈×1,7»; Göçer satırı «keçe ≈×1,6, ip ≈×1,5, demir ≈×2». §3.2 ve §7.1 doğru kalır. `economy.md` §10.6 «Göçer ≈%10 çok» → «Surlu ham Yük ≈%19 çok». `settlement.md` §7.6, `economy.md` §6.12 ve model sayısı.

### 11. #48 Plan Kipi'nde araba kartı

**Karar.** Sekizinci kategori açılmaz. Atölye kategorisinde **tek kart: Araba / Cart**. Bina kartına gizlenmez, çünkü araba kendi şantiyesiyle yere konur (§7.8) ve Plan Kipi yere koyma ekranıdır.

| Alan | Değer |
|---|---|
| Kart içi seçim | ◂ ▸ ile tür. Q / E döndürmeye kalır (K27) |
| Türler | `cart_felt` Oba, `cart_high` Boy Yurdu, `cart_war` Toy Yeri, `wagon_felt` Göçer Avlu |
| Kilit | «Önce Ağaç Atölyesi.» / «Build a Woodshop first.»; «Dülger yok.» / «You have no carpenter.» (#40'ın adı); teker çifti usta işi |
| Yer | İş parseli, Ağaç Atölyesi'ne ≤30 m, 6 × 12 m ped: **Araba Yeri / Cart Yard**. Yapı değildir, kart her konuşta açar |
| Yazar | Yük, çeken, yol / kar hızı, malzeme (var / gerek), emek, «Boşta {n} · Kervanda {m}» |
| Bitince | `carts` listesine girer, Araba Yeri'nde durur. Çeken at ya da öküz sürüden ayrılır; yoksa kart uyarır |
| Kırık | `ev_raid` sonrası aşama 0: aynı kartta «Onar». K21 onarımı |
| Sök | K21: ham malın yarısı |
| Armağan | Teoman'ın `cart_felt`'i listede başlar. Ocak'ta kart kilitli, araba var |

| Araba | Yük | Çeken | Yol / kar m/sn | Malzeme | Zincir İG |
|---|---|---|---|---|---|
| Keçe Araba | 60 | 1 at | 6,8 / 4,4 | 1 teker çifti, 10 odun, 4 keçe, 2 demir, 2 ip | 5,8 |
| Yüksek Teker | 80 | 2 at | 7 / 5 | 1 teker çifti, 14 odun, 6 keçe, 4 demir, 2 ip | 9,8 |
| Ordu Arabası | 140 | 4 at | 6 / 4 | 2 teker çifti, 20 odun, 8 keçe, 6 demir, 4 ip | 15,0 |
| Keçe Göç Arabası | 120 | 4 öküz | 3 / 2 | 2 teker çifti, 24 odun, 10 keçe, 4 demir, 6 ip | 12,9 |

- Araba `settlement.md` §7.8 bileşimindeki gibi kalır. Yeni çizim yok.
- **Süre.** Araba Yeri bir şantiyedir: kurma ve söküm brif'in inşaat eğrisiyle işler (`T(n) = taban × 0,75^(n−1)`, en çok 8 el; `d3/brief.md`). Teker çifti Ağaç Atölyesi'nin tezgâh işidir (`rc_wheel_pair`, 10 İS, usta), eski `eff` ile kalır. Kartın emek satırı ikisini ayrı yazar.
- `chariot_yao` kartta yoktur: V'te armağan [kaynak: Polosmak 2013], yapılmaz.
- `travel.md` §3.1 güncellenir: Hun arabası yazılı kaynakta var (Yantie lun), biçim Pazyryk ve Hippokrates'ten [çıkarım].

### 12. #39 Gelen hane türleri

**İki tür, üç durum.** **Yüklü Hane / Laden Household**: kendi evi at ve develerde. Yurtlu (`kit`) ya da çadırlı (`tent`). **İsteyen Hane / Asking Household** (`ask`): barınak ister. Tür kesirli sayaçla gelir, rastgele çekiliş yoktur (K24 ganimet deseni).

| Kaynak | Adet | Yurtlu | Çadırlı | İsteyen | Sürü |
|---|---|---|---|---|---|
| `hh_story` | 2–3 | 0 | 0 | 1 | 4 at eş. |
| `hh_saved` | 0–2 | 0 | 0 | 1 | Yok |
| `oba_wave` | 4 | 1 | 0 | 0 | Tam |
| `court_move` | 8 | 1 | 0 | 0 | Tam |
| `gift` | 2–4 × ≤3 soy | 1 | 0 | 0 | Tam |
| `loufan_baiyang` | 6–10 | 1 | 0 | 0 | Tam |
| `court_gathering` | 8–12 | 1 | 0 | 0 | Tam |
| `kurultay` | 2–4 | 1 | 0 | 0 | Tam |
| `pull` (Çekim) | ≤3 / 4 / 6 / 8 / 10 | 0,6 | 0,25 | 0,15 | Tam |
| `choose` (yenilen) | III 2–6, IV 3–6, V 4–8 | 0,3 | 0,4 | 0,3 | Yarı |
| `refugees` | 1–2 | 0 | 0,5 | 0,5 | Yok |
| `defectors` | 6–12 | 0 | 0 | 1 | Yok |
| `heqin` | 1–2 | 0 | 0 | 1 | Hazine malı |

**Sağlama** (perde başına beklenen, hesap):

| Perde | Yurtlu | Çadırlı | İsteyen | Model `expectedKits` |
|---|---|---|---|---|
| II | 5,8 (+ Mete 1) | 0,8 | 4,0 | 6 |
| III | 11,6 | 3,4 | 2,5 | 12 |
| IV | 22,0 | 3,3 | 2,2 | 22 |
| V | 16,6 | 4,4 | 13,5 | 17 |
| VI | 9,0 | 2,5 | 1,5 | yok |

K24'ün hazır Yurt Yükü sayıları değişmez, kademe günü bozulmaz. V'in 13,5 isteyeni Surlu'nun 12 yarı gömük evine denk gelir.

**Kafile.**

| Tür | Yük (ev + 18 yün + azık) | Görünüş |
|---|---|---|
| Yurtlu | 59 + 9 + 2,2 ≈70 | 3 yük hayvanı: iki hanede bir biri deve (hane ½ deve), kalanı at |
| Çadırlı | 16 + 9 + 2,2 ≈27 | 1 yük atı |
| İsteyen | 2,2 | Yaya ya da tek at |

**İsteyen Hane kartı.** «{n} hane barınak istiyor.» / «{n} households ask for shelter.»

| Seçenek | Bedel | Sonuç |
|---|---|---|
| Çadır ver | 1 `tent_kit` (42 Kıymet, 16 Yük) | Gönül başı +8; hane konutta sayılır, çadır kuralı sürer |
| Yurt ver | 1 `yurt_kit` | Gönül başı +15 |
| Yarı gömük ev (Surlu, `defectors`) | Şantiye | Gönül başı +10; kurulana dek çadır |
| Bekleyin | Yok | Mevcut kural: Gönül −1/gün, 3 gün sonra gider |

- Kâhya: «Sürekli emir» `tent_kit keep_to: 2`, Oba'dan. Ambarda varsa kendiliğinden verir, kart çıkmaz. Yoksa kart.
- T1'in bileşimindeki `tent` ×2 `hh_story` içindir: isteyen hane II'de bu görevle öğretilir.
- `settlement.md` Y10 ve §5.3 «Getirdiği» sütunu bu tabloya döner. `d2/core.md` §4.4 «çadırı ya da yurt yükü» cümlesi «çadırı, yurt yükü ya da yalnız azığı» olur. Model: `households.sources.*` alanına `tent`, `ask`.

### 13. Küçük düzeltmeler

- **İpek (#29).** `economy.md` §9.4 «Hun satıcısı ucuz alır, Shiji 110» gerekçesi Mete'den sonraki bir söze dayanır. Kural kalır (`sellK` 0,6), gerekçe değişir: ipek pazar malı değil otağ malıdır. Yeni: Divan armağanında (`gift.costWorth`) İpek Top Kıymet ×1,5 sayılır [kaynak: SJ 129 什倍, SJ 110 好漢物; sayı [kurgu]]. Vaha `sellK` 1 kalır.
- **Kaçak demir.** `vendor_han_border` `iron_bar` ×4 Han yasasına ters düşer (§1.5). Yalnız bu mal için `buyAdd` +0,25, satıcı: «Görmedin.» / «You saw nothing.» [kurgu].
- **Sınır pazarı.** Destan notu: resmî kayıt Jing dönemindedir, oyun onu erken açar `tasarım tercihi`.
- **Divan kefareti (hırsızlık davası).** 坐盜者沒入其家 seçeneğinin yanına barımta deseni: çalınan hayvan iki katıyla ya da kabukla ödenir [kurgu, dayanak §4]. `settlement.md` §12.3 ile `mete-tarih.md` öneri 13'e bir seçenek.
- **Heqin Kronik satırı (VI).** Yıl başına 10 İpek Top, 10 Şarap Küpü, 5 Tahıl Çuvalı, Hazine sınırıyla [kurgu; HS 94A'nın şarap, tahıl, ipek üçlüsü].

### 14. İşlenecek yerler

| Dosya | Değişiklik |
|---|---|
| `d2/econ-model.json` | `cowrie`, `bolt`, `rc_cowrie`, `rc_melt_bolt`; `herds.*.worth`; `grain_sack.act` 4; `rampart.bom`; `loot` kabuk |
| `d2/settlement-model.json` | `raids` (`moonGate` 0,97, `perActMax`, `campK` 0,6, `campPerActMax` 1, `quartermasterK` 0,75, R bitişleri); `households.sources` `tent`, `ask`; ordugâh `guardPer` |
| `src/game/barter.js`, `tools/econ-sim.mjs` (prototip, ölçüm) | `HERD_WORTH` ve `HW` tek kaynaktan; kese, üstü, `cowrieK`. Paket 8.7. Sim Godot sayılarının başvurusudur |
| `economy.md` | §3.11, §3.12, §7.1, §8.5, §9, §10.6, §10.8, §14 |
| `settlement.md` | §4.3, §5.3, §7.6, §7.8, §11, §14.1, §15.4, §16.2 |
| `army.md`, `travel.md`, `progression.md`, `d2/core.md` | §3.7; §3.1, §7.2; §4.3, §16.1; §4.2, §4.4, §4.8 |
| `godot.md` (uygulama) | Öneri 15'in sekiz maddesi |
| Site | `para-satici.md`, `hanlik-merkezi.md`, `ordugah-kervan.md`, `uretim-depo.md`, `plan-kipi.md`, `hane-kahya.md`, `oba-hanlik.md`, `acik-sorular.md` kutuları kalkar |

### 15. Godot için

Godot'ta ekonomi, takas, takvim, yerleşim ve Plan Kipi henüz yoktur (`d3/oyun-durumu.md`). Yukarıdaki öneriler prototipin dosyalarına göre yazıldı; Godot karşılıkları aşağıdadır. Uygulama planının sahibi `godot.md`'dir, sayı ve kural alan belgesinden okunur (`d3/brief.md` belge üstünlüğü). Kod bu turda yazılmaz.

1. **Tek veri kaynağı.** Fiyat, sürü, kese, akın ve araba sayıları GDScript'e gömülmez. `d2/econ-model.json` ve `d2/settlement-model.json`'dan dışa aktarılan veri dosyası okunur (örnek `game/data/economy.json`, `game/data/raids.json`; okuma `destan_kitabi.gd`'nin JSON yoludur). `herds.<id>.worth` tek sahip kalır (#29).
2. **Takas.** `Barter`: `class_name Barter extends RefCounted`, yalnız `static func`, yan etkisiz (`SaveData` deseni). `take(items, vendor)`, `give(items, cowries, vendor)`, `change(give, take, purse)`; `cowrieK` satıcı verisidir (Hun 1, yabancı 0,6). I. Perde kipinde ekran sayı göstermez, işlev yine hesaplar.
3. **Terazi.** Tek `Control` sahnesi, iki kip. Kiriş `(give − take) / (give + take) × 18°`, «Denk / Eksik / Fazla»; II'den «Eder», «Kese», «Üstü». Biçim `ui_kit.gd` ve `menu_style.gd`'den gelir.
4. **Kayıt.** `SaveData`'ya `economy` sözlüğü: `purse` (kabuk), satıcı keseleri ve son dolum günü (`day_n`). `VERSION` 1'den 2'ye çıkar; alan yoksa kese 0 sayılır (`parse`'ın «eksik alan güvenli varsayılana düşer» kuralı).
5. **Akın.** `RaidRules` saf sınıf: kapı `GameCalendar.moon_illum(day_n + 0.5) >= 0.97` (`mete-tarih.md` «Godot için» madde 7), toplantı günü dışarıda, perde tavanı, hedef (küçük `D`), başarı `R / (R + D)`, sonuç. Rastgele yoktur: aynı kayıt aynı akını verir. Önkoşul: `GameCalendar` ve `GameClock`; bugün Godot'ta gece sabittir.
6. **Plan Kipi.** Kendi girdi bağlamıdır: Q / E kartın nesnesini 15° döndürür, Shift ile 5° (`settlement.md` §14.1). Serbest gezide Q / E kamerayı döndürdüğü için bu bağlamda kamera orta tuş sürüklemesiyle döner (K27); sağ tık iptaldir. Tuşlar `InputSetup`'ta yeniden atanır. Araba kartı Atölye sekmesindedir, türler ◂ ▸ ile.
7. **Sınama.** `tests/unit/test_barter.gd` (`extends TestCase`): her türde canlı × 0,9 > kesim Kıymeti (sığır 216 > 126, deve 453,6 > 142), keseli ve kesesiz üstü, 10 tunç ok ≈5 kabuk. `tests/unit/test_raid_rules.gd`: öneri 8'in tablosu (D 110, R 6 → %5,2; D 11, R 4 → %26,7), III'ün gün kapısı 15–17 Eylül 208 (`day_n` 1.693–1.695) ve Dailin günü 1.694'te akın olmaması. Sayılar prototipin `econ-sim.mjs` çıktısıyla aynı olmalıdır. Koşu: `tools/run_tests.sh --filter=barter`.
8. **Varlık.** Kabuk, kese ve Terazi 2B'dir (simge ve arayüz), 3B gerekmez. Dört araba türü 3B ister; yolu `docs/research/varlik-hatti.md` seçer, Meshy kredisi üretimden önce kullanıcıya sorulur (`d3/brief.md`).

## Belirsizlikler

- **Arama.** İlk yazımda WebSearch hakkı bitmişti; doğrulama turunda açıktı. Bod oranı ve Juyan Han fiyatları yine bulunamadı: sığır ile at oranı yalnız SJ 129'a ve kesim sınamasına dayanır. Üç kaynak doğrudan açılamadı, metni arama aracının okumasından alındı: MSA 2022/2 makalesi (Kyoto deposu HTML döndürdü), Trubnikova ve ötekiler 2025 özeti (academia.edu 403, journal.asu.ru bakımda), Tseveg-Ochir 2024'ün PDF'i (HTML sayfasında katsayı yok). Asıl metinle sınanmalıdır.
- **Okunamayan.** ctext otomatik erişime kapalıdır, iki turda da kullanılmadı; Çince metinler Vikikaynak baskısındandır. Yantie lun'un ikinci bir baskısı bu yüzden görülmedi. Di Cosmo, Yü Ying-shih, Barfield, Kradin, Davydova özgün metinleri okunmadı; adları geçen sayılar ikincil sayfalardan gelir. Nature sayfası açılmadı, PMC kopyası okundu. Türkçe özetlerden Çerçi'nin makalesi Asya Hunları ile Attila'yı karıştırdığı için kullanılmadı.
- **Kabuk.** Kabuğun ve tunç taklidinin Hun dünyasında varlığı bağımsız kaynakla sağlamdır (§1.6). Para işlevinin tek dayanağı Ivolga maddesinin «varsayılır» cümlesidir, dipnotu okunamadı; bağımsız kaynaklar kabuğu kemer süsü olarak anar. Davydova metniyle sınanmalı. Kanıt zayıflarsa kural değişmez, yalnız Destan notu değişir: seçim [kurgu]dur.
- **Sınır pazarı.** Vikipedi'nin Wen dönemi pazar düzeni sözü dipnotsuzdur (§1.5); Yü Ying-shih'in *Trade and Expansion in Han China*'sı okunmadı.
- **Darı süresi.** Olgunlaşma çeşide ve enleme göre 45–90 gündür. Transbaykal ve Orhon için ölçü bulunamadı; oyunun 93–133 günlük aralığı güvenli taraftadır.
- **Ivolga kemikleri.** Maddede iki sayım vardır (köpek %29 ve sığır %30,8); hangisinin hangi kazıdan geldiği yazmaz. Fiyat önerisi bu sayılara dayanmaz.
- **Ivolga tarihi.** Mete'den sonra olabilir. Oyunda V sonrası görünüştür.
- **Bod.** Doğrulanmadı, sayı hafızadan. Fiyat önerisi ona dayanmaz, yalnız uyuşur.
- **Çeviri.** SJ 129 listeleri fiyat değil yıllık gelir denkliği olabilir; 羊彘千雙 koyun ve domuzu birlikte sayar. Yan Shigu ile Gu Yin at sayısında ayrışır (200 ve 76).
- **Yük.** 1 Yük ≈7 kg kaba hesaptır, tahıl yoğunluğu varsayımdır. Atın terkisi kaynak sayısının üstündedir, bilerek bırakıldı.
- **Akın sıklığı.** Tek bir kampa ne sıklıkla akın geldiği kaynakta yok. Oyunun sıklığı kullanıcının «seyrek» isteğinden ve ay kuralından gelir.
- **Ay ve hikâye.** Üç dolunay büyük sahneyle çakışır (Dailin, Lung-çeng, Baideng). Kural akını toplantı gününden önceki geceye alır ve V'te akın yazmaz (öneri 8, 9). Hikâye alanı sahneyi başka türlü kurarsa bu satır onunla değişir.
- **Ölçüm.** Kese, üstü, Kabuk akışı ve Gönül değerleri koşulmadı. `#36` dışındaki sayılar resmî koşuda sınanır. Surlu sayıları geçici model kopyasıyla basıldı, `econ-sim` bugünkü kademe tablosu `economy.md` §10.6'nın önündedir (site `denge.md`). Doğrulama turunda sim yeniden koşulmadı; tablolar elle ve modelden yeniden hesaplandı.
- **Godot.** Godot'ta takvim, ekonomi ve Plan Kipi yoktur; öneri 15'in sınıf adları öneridir, `godot.md` ile uzlaşmalıdır.
- **`fauna.md`.** Bu belge yazılırken ve doğrulanırken yoktu. Köpek kuralı ve eşek, katır fiyatı oraya uydurulur.

## Kaynaklar

**Birincil (Çince, Vikikaynak).**
- [Shiji 30](https://zh.wikisource.org/wiki/史記/卷030), [Shiji 93](https://zh.wikisource.org/wiki/史記/卷093), [Shiji 109](https://zh.wikisource.org/wiki/史記/卷109), [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), [Shiji 111](https://zh.wikisource.org/wiki/史記/卷111), [Shiji 113](https://zh.wikisource.org/wiki/史記/卷113), [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123), [Shiji 129](https://zh.wikisource.org/wiki/史記/卷129), [Shiji 129 üç yorum](https://zh.wikisource.org/wiki/史記三家註/卷129)
- [Hanshu 3](https://zh.wikisource.org/wiki/漢書/卷003), [Hanshu 5](https://zh.wikisource.org/wiki/漢書/卷005), [Hanshu 24B](https://zh.wikisource.org/wiki/漢書/卷024下), [Hanshu 49](https://zh.wikisource.org/wiki/漢書/卷049), [Hanshu 55](https://zh.wikisource.org/wiki/漢書/卷055), [Hanshu 69](https://zh.wikisource.org/wiki/漢書/卷069), [Hanshu 91](https://zh.wikisource.org/wiki/漢書/卷091), [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下), [Hanshu 96B](https://zh.wikisource.org/wiki/漢書/卷096下)
- [Hou Hanshu 89](https://zh.wikisource.org/wiki/後漢書/卷89), [Yantie lun, 52. bölüm](https://zh.wikisource.org/wiki/鹽鐵論/卷九), [Zhoushu 50](https://zh.wikisource.org/wiki/周書/卷50)

**Birincil (öteki).**
- [Hippokrates, Airs, Waters, Places 18](https://classics.mit.edu/Hippocrates/airwatpl.18.18.html); öteki İngilizce çeviri [Perseus, 17–20](https://atlas.perseus.tufts.edu/library/passage/urn:cts:greekLit:tlg0627.tlg002.perseus-eng4:17-20)
- [Rubruck, Silk Road Seattle](https://depts.washington.edu/silkroad/texts/rubruck.html)
- [Kül Tigin Yazıtı, Vikikaynak](https://tr.wikisource.org/wiki/Orhun_Yaz%C4%B1tlar%C4%B1_(K%C3%BCl_Tigin))

**Hakemli ve uzman.**
- [Wilkin ve ötekiler, Economic Diversification Supported the Growth of Mongolia's Nomadic Empires, Scientific Reports 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7054399/)
- [Rao ve ötekiler, Dzuds, droughts, and livestock mortality in Mongolia, ERL 2015](https://iopscience.iop.org/article/10.1088/1748-9326/10/7/074012)
- [Sasada ve Amartuvshin, Iron Smelting in the Nomadic Empire of Xiongnu, ISIJ International 2014](https://www.jstage.jst.go.jp/article/isijinternational/54/5/54_1017/_article)
- [Polosmak ve Bogdanov, Traces of Chinese Chariot, SCIENCE First Hand 2013](https://scfh.ru/en/papers/traces-of-chinese-chariot/)
- [Waugh, The Challenges of Preserving Evidence, The Silk Road 2006](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/The-Challenges-of-Preserving-Evidence.pdf)
- [Waugh, Xiongnu arkeolojisi tarihi](https://depts.washington.edu/silkroad/archaeology/mongolia/xiongnu/xiongnuarchhist/xiongnuarchhist.html)
- [Donuk, Baranta, TDV İslam Ansiklopedisi 1992](https://islamansiklopedisi.org.tr/baranta)
- [Bower, How Asia's first nomadic empire broke the rules, Science News 2023](https://www.sciencenews.org/article/asia-xiongnu-nomadic-empire-expansion)
- [Multidisciplinary Studies in Archaeology 2022/2, 37–50](https://repository.kulib.kyoto-u.ac.jp/dspace/bitstream/2433/286450/1/2658-3550-2022-2-37-50.pdf) (başlık ve yazar görülmedi; konu Hun yerlerindeki Çin eşyasıyla radyokarbon karşılaştırması; arama aracıyla okundu)
- [Trubnikova, Kilunovskaya, Leus 2025, kabuklu kemerler, Ulan Bator derlemesi III, özet](https://archeo.academia.edu/VarvaraTrubnikova) (arama aracıyla okundu)
- [Tseveg-Ochir, Lee, Woo, Choi, Review of the Current Status of Pasture-based Livestock Industry in Mongolia, J. Korean Soc. Grassland and Forage Science 44(1), 2024](https://koreascience.kr/article/JAKO202411643744808.page)
- [Erdenebileg, A comprehensive review of research pertaining to the relics and applications associated with the culture of the bactrian camel, 2022, IRCI kaydı](https://www.irci.jp/rdb/item/13405)
- [Oelke ve ötekiler, Millets, Alternative Field Crops Manual, Purdue](https://hort.purdue.edu/newcrop/afcm/millet.html)

**Basın (kazı haberi).**
- [Huge jet belt buckle found in Bronze Age grave, The History Blog 2019](https://www.thehistoryblog.com/?p=56375) (Ala-Tey 1, IIMK RAS fotoğrafları)
- [Tighten Your Belt: 2,200 year-old Xiongnu Jewelry, Ancient Origins](https://www.ancient-origins.net/news-history-archaeology/tighten-your-belt-2200-year-old-xiongnu-jewelry-made-coal-jade-and-coral-021656) (Kilunovskaya ile söyleşi, Siberian Times üzerinden)

**Başlangıç noktası (Vikipedi, Vikisözlük; ikincil sayıların taşıyıcısı).**
- [Иволгинское городище](https://ru.wikipedia.org/wiki/Иволгинское_городище) (Davydova, Kradin, Gokhman), [Баранта](https://ru.wikipedia.org/wiki/Барымта), [Жеты Жаргы](https://ru.wikipedia.org/wiki/Жеты_Жаргы)
- [Ban Liang](https://en.wikipedia.org/wiki/Ban_Liang), [Economy of the Han dynasty](https://en.wikipedia.org/wiki/Economy_of_the_Han_dynasty) (Nishijima, Yü, Liu, Bielenstein), [Ordos culture](https://en.wikipedia.org/wiki/Ordos_culture) (Bunker)
- [Proso millet](https://en.wikipedia.org/wiki/Proso_millet), [Mongolian cuisine](https://en.wikipedia.org/wiki/Mongolian_cuisine), [Bactrian camel](https://en.wikipedia.org/wiki/Bactrian_camel), [Pack animal](https://en.wikipedia.org/wiki/Pack_animal), [Yurt](https://en.wikipedia.org/wiki/Yurt), [Pazyryk burials](https://en.wikipedia.org/wiki/Pazyryk_burials), [Tamga](https://en.wikipedia.org/wiki/Tamga)
- [Proto-Turkic *kümülᶴ, Vikisözlük](https://en.wiktionary.org/wiki/Reconstruction:Proto-Turkic/kümüĺ), [yarmak, Vikisözlük](https://en.wiktionary.org/wiki/yarmak)
- [Orkhon inscriptions](https://en.wikipedia.org/wiki/Orkhon_inscriptions) (İngilizce çeviri), [Xiongnu](https://en.wikipedia.org/wiki/Xiongnu)
- [Pre-industrial travel modes, The Geography of Transport Systems](https://transportgeography.org/contents/chapter1/emergence-of-mechanized-transportation-systems/pre-industrial-travel-modes/)

**Proje.**
- `docs/design/d3/register.md`, `d3/brief.md`, `d3/oyun-durumu.md`, `decisions.md` (K23, K24, K25, K27), `d2/econ-model.json` (`items`, `herds`, `structures`, `recipes`, `raid`), `d2/settlement-model.json` (`raids`, `households`), `time.md` §2, `docs/research/mete-tarih.md` (öneri 3, 5, 10; «Godot için»), `game/scripts/save/save_data.gd`, `game/scripts/ui/destan_kitabi.gd`, `economy.md` §3.11, §3.12, §7.1, §8.5, §9, §10, §14; `settlement.md` §1, §4, §5.3, §7, §11, §14, §15, §16.2; `army.md` §3.6, §3.7; `travel.md` §3, §7.2, §9.6; `progression.md` §4.3, §10.3; `d2/core.md` §4, §5; `src/game/barter.js`; `tools/econ-sim.mjs`; `docs-app/content/pages/ekonomi/para-satici.md`.

## Doğrulama

**Tarih:** 2026-11-04. **Sınanan iddia: 12.** Yöntem: belge baştan sona okundu, tasarım kararı taşıyan 12 iddia seçildi. Her biri belgenin kullandığından başka bir tanıkla yeniden açıldı: başka derleme (Shiji yerine Hanshu), başka çeviri, başka yazar ya da kazı. Çince metin Vikikaynak'tan okundu; ctext otomatik erişime kapalıdır. Ay pencereleri `time.md` §2 formülüyle betikle, kese ve kesim değerleri `d2/econ-model.json`'dan yeniden hesaplandı.

| # | İddia (yer) | Belgedeki dayanak | Bağımsız tanık | Sonuç |
|---|---|---|---|---|
| 1 | Hun kendi sikkesini basmadı; Hun alanındaki sikke Han'ındır, süs ya da mezar eşyasıdır (§1.2, öneri 1) | Waugh 2006 | Moğolistan'daki Hun yerlerinde yalnız wu zhu ve huo quan çıkar [[MSA 2022/2](https://repository.kulib.kyoto-u.ac.jp/dspace/bitstream/2433/286450/1/2658-3550-2022-2-37-50.pdf)]; Ala-Tey 1'de wu zhu kadın kemerinin kenar süsüdür [[The History Blog 2019](https://www.thehistoryblog.com/?p=56375); [Ancient Origins](https://www.ancient-origins.net/news-history-archaeology/tighten-your-belt-2200-year-old-xiongnu-jewelry-made-coal-jade-and-coral-021656)] | Doğrulandı. «Hun sikkesi yok» kanıtın yokluğudur |
| 2 | Qin'de altın üst, tunç alt paradır; kabuk (貝) ve gümüş para değildir (§1.3) | SJ 30 | [HS 24B](https://zh.wikisource.org/wiki/漢書/卷024下) aynı kuralı yazar: 而珠玉龜貝銀錫之屬為器飾寶臧，不為幣. [HS 3](https://zh.wikisource.org/wiki/漢書/卷003) ve HS 24B §1.2'nin yıllarını da verir: 行八銖錢 (Lü'nün 2. yılı), 行五分錢 (6. yılı), 孝文五年…四銖錢, 元狩五年…五銖錢 | Doğrulandı |
| 3 | Ivolga'da gerçek ve tunç kabuk bulundu, kabuk para olarak kullanılmış olabilir (§1.6, öneri 1) | ru.wikipedia, Ivolga | Kabuklu kemer Hun çağında en yaygındır, taklit kabuk Hun kemerinin ayırıcısıdır [[Trubnikova ve ötekiler 2025, özet](https://archeo.academia.edu/VarvaraTrubnikova)]; Ala-Tey'de tunç kabuk taklidi [Ancient Origins] | Kısmen. Kabuk ve tunç kabuk doğrulandı, para işlevi doğrulanmadı. Kural değişmez, Destan notu yeniden yazıldı |
| 4 | «Kümüş» Eski Türkçede gümüştür, Kül Tigin G5'te geçer (öneri 1) | tr.wikisource, Vikisözlük | [Orkhon inscriptions](https://en.wikipedia.org/wiki/Orkhon_inscriptions) maddesindeki çeviri: «gold, silver, millet, and silk»; Vikikaynak G5 yeniden okundu: «aLTUN: KÜMüŞ: İŞGiTİ: KUTaY» | Doğrulandı. Ret gerekçesi sözcükte değil dönemdedir (iddia 2) |
| 5 | Han gelir hesabında at pahalı, sığır ucuzdur: 50 at = 167 sığır (§2, öneri 4) | SJ 129, 三家註 | [HS 91](https://zh.wikisource.org/wiki/漢書/卷091) aynı iki listeyi verir; 三家註'de iki ayrı yorumcu aynı hesaptadır: 集解 (漢書音義) «百六十七頭也。馬貴而牛賤», 索隱 «牛有百六十六頭有奇» | Doğrulandı, düzeltmeyle: «250 koyun» yorumda yoktur, hesaptır |
| 6 | Moğolistan ot birimi koyun 1, keçi 0,9, deve 5, sığır 6, at 7'dir; ot gereksinimidir, fiyat değil (§2) | Rao 2015 | [Tseveg-Ochir ve ötekiler 2024](https://koreascience.kr/article/JAKO202411643744808.page), Moğolistan Tarım Bakanlığı'nın 2019 yöntemiyle aynı katsayılar | Doğrulandı. `lu`'nun fiyat olmadığı bulgusu geçerli |
| 7 | Hun ay dolunca saldırır, eksilince çekilir (§4, öneri 8) | SJ 110 | [HS 94A](https://zh.wikisource.org/wiki/漢書/卷094上): 舉事常隨月，盛壯以攻戰，月虧則退兵 | Doğrulandı |
| 8 | Hun akıncısı direnişte dağılır, ganimet alanındır (§4, öneri 8, 9) | SJ 110 | HS 94A: 故其逐利，如鳥之集；其困敗，瓦解雲散矣 ve 所得鹵獲因以予之 | Doğrulandı. «Küçük, kolay def edilen akın» bu iki satıra dayanır |
| 9 | Hun'un tahıl ambarı ve tarlası vardır (§3.1, öneri 6) | SJ 111, HS 96B, Wilkin 2020 | [HS 55](https://zh.wikisource.org/wiki/漢書/卷055): 得匈奴積粟食軍 ve 悉燒其城餘粟以歸; HS 94A: 穀稼不孰; HS 96B yeniden okundu: 匈奴復使四千騎田車師 | Doğrulandı; Wilkin'in dönem grubu düzeltildi |
| 10 | Darı ekimden ≈60 gün sonra ürün verir, soğuğa duyarlıdır (§3.3, öneri 6) | Proso millet (Vikipedi) | [Purdue AFCM](https://hort.purdue.edu/newcrop/afcm/millet.html): «proso millet will mature in 70 to 90 days», dona duyarlı | Düzeltildi: 60–90 gün. Takvim değişmez, 93–133 günlük aralık ikisini de kapsar |
| 11 | Baktriya devesi 170–250 kg taşır, `pack_camel` 30 Yük ≈210 kg uyar (§6.1) | Bactrian camel (Vikipedi) | [Erdenebileg 2022](https://www.irci.jp/rdb/item/13405): kervanda deve başına 100–200 kg, sırtta 160–240 kg | Doğrulandı. 210 kg üst uçtadır |
| 12 | Hun'un yük taşıtı vardı; bozkırın göç arabası keçe örtülü, 4–6 tekerli, öküz çekişlidir (§6.2, öneri 11) | Yantie lun 52, Hippokrates (MIT çevirisi) | [Perseus çevirisi](https://atlas.perseus.tufts.edu/library/passage/urn:cts:greekLit:tlg0627.tlg002.perseus-eng4:17-20): «The smallest have four wheels, others six wheels», keçe örtülü, «two or by three yoke of hornless oxen»; HS 94A Hun'un 輜重'ini üç kez anar | Kısmen. Göç arabası doğrulandı; Yantie lun'un ikinci baskısı açılamadı, Hun arabasının biçimi bilinmiyor |

**Sonuç:** 9 doğrulandı (biri düzeltmeyle), 2 kısmen, 1 düzeltildi. Sınama hiçbir kararı devirmedi: para birimi Kabuk, #29 fiyatları ve araba kartı aynı kalır. Akın kuralına yalnız `mete-tarih.md` ile uyum için toplantı günü satırı eklendi ve V'in beklenen akını 0 oldu.

**Yeniden okunan öteki satırlar.** Hepsi belgeyle uyuşur: SJ 110'un on beş alıntısı; HS 94A'nın 通關市, 糱酒萬石, 東胡初輕冒頓 ve 好漢物 satırları (HS 歲奉匈奴絮繒酒食物 yazar, SJ'deki 米 yoktur); HS 94B'nin beş satırı (錢二十萬, 三萬四千斛, 三世無犬吠之警, 用糒十八斛, 賜安車鼓車); HS 49 (卒少則入, 胡人衣食之業不著於地); HS 96B (單于必爭此地); SJ 123 (牛羊以萬數; 得漢黃白金，輒以為器); Yantie lun 52'nin üç satırı; Ivolga maddesinin kabuk, tarih, Kradin, 86 çukur, tahıl çukuru ve kemik satırları; Rao 2015 (ot birimi, %20, %33); Wilkin 2020; Ban Liang ağırlıkları.

**Hesapla sınananlar.**
- Ay pencereleri (`moon ≥ 0,97`, yarı genişlik 1,64 gün): III 14,8–18,1 Eylül 208 doğru; IV 15,9–19 → 15,8–19,1 Haziran 205; 24,1–27,4 Haziran 203 doğru; V'in tek penceresi 27,0–30,3 Kasım 201. Öğle gün kapısıyla III 15–17 Eylül, IV 16–18 Haziran 205, V 27–29 Kasım 201: `mete-tarih.md` öneri 10 ile aynı. Dailin 208 `dayN` 1.694, Lung-çeng 205 `dayN` 2.698: `mete-tarih.md` öneri 3 ve 5 ile aynı.
- Kese ve Kafile: Tanhu pazarcısının şafak stoğu 208, Çiang tuzcusununki 104 Kıymet; gelen hanenin azığı 5 × 4,3 × 0,1 = 2,15 Yük.
- Öneri 8'in başarı tablosu (R / (R + D)) ve öneri 9'un beklenen kaybı (başarı × %30 × 0,7) satır satır doğru.
- Kesim Kıymetleri (36, 26, 106, 126, 142) modelle aynı. #39 sağlaması kaynak tablosundan yeniden toplandı, aynı. Araba malzemeleri modelin `structures` satırlarıyla aynı. `rc_cowrie` oranı 12 ÷ (12 + 0,75) = 0,94, `markupBand` [0,85, 1,6] içinde.
- Satıcı keseleri yanlış bölünmüştü (düzeltme 9).

**Yapılan düzeltmeler.**
1. Özet 10: #39 «üç tür» → iki tür (Yüklü, İsteyen); Yüklü hane yurtlu ya da çadırlıdır (`d3/brief.md`).
2. §2: «250 koyun» yorumda değil hesaptadır, 韋昭'nın 250'si domuz içindir; HS 91 eklendi.
3. §3.1: Wilkin 2020'nin %3–26'sı Erken Demir, Hun ve Moğol çağını birlikte sayar.
4. §3.3: darı 60 gün → 60–90 gün; oyun takvimi değişmedi.
5. §3.2: Ivolga'nın ikinci kemik sayımı eklendi. §5: Zhang Qian heyetinin sürüsü 牛羊以萬數 diye dolduruldu.
6. §6.2: 車器 «araba ve kap kacak» oldu; HS 94A'nın 輜重'i, HS 94B'nin 安車一乘'i ve Perseus çevirisi eklendi. §6.1: deve yükü ikinci kaynakla; `cart_felt`'in «hafızadan, doğrulanmadı» satırı Yan You'nun öküz hesabıyla (HS 94B, ≈450 kg) dolduruldu.
7. §1.2, §1.3, §1.5, §1.6: MSA 2022, Ala-Tey, HS 24B, HS 94A ve Trubnikova 2025 tanıkları eklendi.
8. Öneri 1: Destan notu kanıta göre yeniden yazıldı.
9. Öneri 3: Tanhu pazarcısının kesesi 50 → 52 (208 ÷ 4), Çiang tuzcusununki 25 → 26 (104 ÷ 4; eski 96 Uyku Otu'nu saymıyordu ve 24 ederdi).
10. Öneri 8: IV penceresi 15,9–19 → 15,8–19,1 Haziran 205; gün kapısının tarihleri eklendi; Dailin ve Lung-çeng günleri akın dışı, akın önceki geceye düşer (`mete-tarih.md` ile uyum); uyarı süreleri ≈45 / ≈35 → ≈44 / ≈33 sn.
11. Öneri 9 ve Özet 8: V'te beklenen akın 1 → 0; tek pencere Baideng'e düşer (`mete-tarih.md` öneri 10), tavan Serbest Dolaşım'da işler.
12. Öneri 11: Araba Yeri brif'in inşaat eğrisine bağlandı.
13. Öneri 14 Godot'a bağlandı; öneri 15 «Godot için» eklendi.
14. Belirsizlikler ve Kaynaklar güncellendi.

**Bu dosyanın dışında kalanlar** (başka ajanların dosyaları, değiştirilmedi): öneri 14'ün tablosu aynen geçerlidir. Bu turda eklenenler: site `acik-sorular.md` Karar Bekleyenler 2'deki «Kümüş» önerisi Kabuk'a döner; `travel.md` §3.1'in deve satırındaki «İkincil alıntıdan okundu» notu kalkar, satır birincil metinde doğrulandı (SJ 110 其奇畜則橐駞、驢、驘; HS 94A 其奇畜則橐佗、驢…); `godot.md` öneri 15'i alır.
