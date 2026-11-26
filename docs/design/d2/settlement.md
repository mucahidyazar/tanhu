# Yerleşim, Ordugâh ve Hanlık / Settlement, Army Camp and Khanate (K23)

> **Taslak, yerini aldı (2026-11-03).** Son biçim `docs/design/settlement.md`'dir; bağlayıcı olan odur. Bu dosya eleştiri ve karar izi için korunur. (2026-11-04, E6: §23'ün yedi açık sorusu kapandı; sayılar bu taslağın günündedir, güncel değer `settlement.md`'dedir.)

d2 tasarım taslağı, 2026-11-02. Alan: II. Perde'de açılış ve II–VI boyunca büyüme yayı; Ocak'tan Tanhu Avlusu'na beş kademe; yerleşim ve ordugâh yapı kataloğu (ad, kademe, görünüm, ayak izi, kapasite, bakım, önkoşul); hane ve nüfus; iş ataması; yapılara yerleşen üretim zincirleri; depolama; ordugâh ve sefer ordugâhı; ikmal kervanı; hanlık merkezi (Tanhu Otağı, toplantılar, Toy Alanı, Gök Direği, Elçi Yurdu, Hazine); `WorldSpec` üstünde yerleşim kuralları ve bütçe; Plan Kipi ve Yerleşim Defteri; kayıt; performans; I. Perde'de kurulacak altyapı. Bağlayan sıra `decisions.md` (K1–K19, yönetmen kararları K20–K24) > `architecture.md` > alan belgeleri. Bu belge K23'ü ayrıntılandırır, tersine çevirmez. Kimlikler ve kod İngilizce, oyuncu metinleri TR / EN çiftidir ve bu belge için yeni yazıldı; Tanhu 1 ve Tanhu 3'ten metin alınmadı.

**Komşu d2 taslakları okundu ve uyuldu.** `labour.md`, `labour-model.json` (K21: İD, İS, İG; `eff(W)`; roller; şantiye `SiteSystem`; `world.sites` kaydı), `econ-model.json` (K24: eşya, tezgâh, tarif, yapı malzeme listesi `bom`, hane ve sürü, kademe önerisi, hedefler), `time.md` (K20: `WorldClock`, `Calendar`, iş penceresi, toplantı günleri), `weather.md` (K22: türler, iklim satırları; `tanhu_ordu` `steppe_south`, `whistle_field` `gobi`). Sahiplik: **ad, kademe, görünüm, kapasite, bakım, önkoşul, yer kuralları, hane, iş ataması, ordugâh, kervan, hanlık bu belgenin**; emek (İG), el sınırı ve zanaat K21'in; malzeme, tarif, tezgâh, kap kapasitesi ve denge hedefleri K24'ün. Çeliştiği yerde alan sahibi kazanır, burada öneri olarak işaretlenir (†).

**Neyi değiştirmez.** Hiçbir belge ve kod düzenlenmedi. `architecture.md`, `structures.md`, `audio.md` değişiklikleri birebir talimat olarak `d2/settlement-delta-architecture.md`, `d2/settlement-delta-structures.md`, `d2/settlement-delta-audio.md` dosyalarındadır; Faz 7'den sonra işlenir. Öteki belgelerin değişiklikleri §20'dedir. Makine okunur veri `d2/settlement-model.json` (econ-sim bu dosyayı `econ-model.json`'un yanında okur).

## 0. Karar özeti

| # | Karar | Sayı | Neden |
|---|---|---|---|
| Y1 | Açılış II. Perde'dedir: `mq2_own_hearth` bitince Mete'nin **Serbest Dolaşım**'ında Plan Kipi ve Yerleşim Defteri açılır | I. Perde yalnız altyapı ve geliştirici kum havuzu | K23; ana kampın Serbest Gez'i Çocuğundur, Mete orada yoktur (K6) |
| Y2 | Yerleşim ile ordugâh ayrı iç haritalardır: yerleşim `tanhu_ordu` (112,8; 43,5; K13), ana ordugâh `whistle_field` (106,6; 44,2) | Aralarında `r_whistle_ordu`: atla 1 gün, arabayla 1, öküzle 2 | Kullanıcı: «ayrı olacak»; Shiji 110 單于之庭直代、雲中: Tanhu avlusu bu yerdedir; Islık Alanı talim yeridir |
| Y3 | Yerleşim büyür ama göçmez; sürü mevsimle otlak değiştirir; ordugâh göçer (sefer ordugâhı) | Sefer ordugâhı `CampPlan` ile 2–3 gerçek dk | 逐水草遷徙 sürüdür; avlu ve sonraki surlu yerleşimler kalıcıdır |
| Y4 | Beş kademe: **Ocak / Hearth**, **Oba / Clan Camp**, **Boy Yurdu / Lineage Seat**, **Toy Yeri / Gathering Seat**, **Tanhu Avlusu / The Tanhu's Court** | Hane 3 / 10 / 22 / 45 / 80; tavan 4 / 12 / 25 / 50 / 90 | K24 bileşim önerisi korunur; "Ordu" (ordugâhla karışır) ve "Han" (oyunun unvanı Tanhu'dur, K15) adları alınmaz |
| Y5 | Kademe n ≥ 3 için perde ≥ n | III'te Boy Yurdu, IV'te Toy Yeri, V'te Tanhu Avlusu | Büyüme perdelere yayılır; mevsim atlaması kademe atlatmaz |
| Y6 | V. kademede yol seçimi: **Surlu Avlu / Walled Court** ya da **Göçer Avlu / Moving Court** | Surlu 91 İG, göçer 55 İG yapı emeği | Hanshu 94A: Wei Lü kuyu, sur ve tahıl kulesi önerir; «胡人不能守城» itirazıyla vazgeçilir. Tarihin tartışması oyuncunun kararıdır |
| Y7 | Hane 5 kişidir; işçi ağırlığı 2,75; sürü ≈18 at eşdeğeri; günde 4,3 öğün | Net iş gücü çobanlıktan sonra ≈2,1 yetişkin | K24 `params`, `household`; K21 roller |
| Y8 | Hane gelir, ganimet olmaz. Katılım: günlük **Çekim / Draw**, hikâye, armağan, zaferden sonra **yenilenlerin seçimi**, kaçkın, sığınan | Çekim kademe tabanı 0,25 → 1,2 hane/gün × (1 + 0,03 Kut + 0,015 Korku) | K23: esir mal ve ganimet değildir. Shiji 虜其民人 yazar; oyun bunu değiştirir ve Destan Kitabı'nda söyler |
| Y9 | Hanenin yeni ekseni **Gönül / Goodwill** (0–100, hane başına) | <40 iş ×0,85, ≥70 ×1,1; <25 ayrılış | Ordu `loyalty` ekseninin yerleşim eşi; sayı gösterilmez, düğüm gösterilir |
| Y10 | Göçebe hane yurdunu getirir (`yurt_kit`); kaçkın, sığınan, yenilen getirmez | Bozkırdan çekilen %60, avlu göçü %100, yenilen %30, kaçkın ve sığınan %0 | Yurt kurma döngüsü yaşar ama abartmaz; tarihte göçebe evini taşır |
| Y11 | İş ataması altı iştir: Sürü, Toplama, Zanaat, İnşa, Nöbet, Taşıma; **Kâhya / Steward** kendiliğinden dağıtır, oyuncu kilitler | Kâhya önceliği: sürü > yiyecek > yem > yakacak > inşa > zanaat > nöbet > kervan | Oyuncu buyurur, halk çalışır; tıklama değil karar büyür (`economy.md` §0) |
| Y12 | Yapı kataloğu K21 ve K24 kimliklerini onaylar, hanlık için 9 yapı ekler | 40 yapı türü, 4 taşıt (§7) | Tek taksonomi; yeni sanat yalnız 7 görünüm ailesiyle (§7.9) |
| Y13 | Kalıcı ambarlar ayrıdır: yerleşim ambarı, ordugâh ambarı, hazine, çukur; aralarında yalnız kervan ve oyuncunun heybesi taşır | Çukur (`grain_pit`) baskında yarı yarıya bulunmaz (K24) | Act I ilkesi döner: «yazılan el konur, saklanan kalır» |
| Y14 | İkmal kervanı sürekli buyrukla gider: «Ordu Payı» + yapılan mal | Her 2 günde bir; Ordu Payı 1–60 öğün/gün; akın sefer başına ≈%2,5–9, koruma %60–90 püskürtür | Ordu yiyeceğinin %10'u yerleşimden (K24 `depotShare`); asıl iş yapılan mal: ok, keçe, çadır, eyer |
| Y15 | Hanlık merkezi Shiji 110'un üç toplantısını taşır: Kış Toplantısı avluda, Lung-çeng kervanla, Dailin Sayımı avlunun güz otlağında | Takvim günü K20 `lunarMonth`'tan | 歳正月…小會單于庭 · 五月，大會蘢城 · 秋，馬肥，大會蹛林，課校人畜計 |
| Y16 | **Gök Direği / Sky Pole**: şafak selamı (單于朝出營，拜日之始生) ve yıldırımın sevdiği yalnız uzun şey | Selam: birlik moral +2, hane Gönül +0,5, günde bir; vuruş: perde başına bir alamet kartı | K22 «yıldırım uzun ve yalnız olana iner» yerleşimde anlam kazanır |
| Y17 | Ordugâh konforu sadakati yazar, talim disiplini | Barınak ≥%90 ve tam tayın: `loyalty` +0,3/gün | Teoman'ın atlıları Mete'nin olur: 皆可用 |
| Y18 | Yer kuralları türe göredir: yurt eğimi ≤6°, su ≤150 m, rüzgâraltı atölye, kapı güneydoğu | §13 | K21 genel kuralı (`labour.md` §6.2) taban kalır, yerleşim üstüne ekler |
| Y19 | Görünür bütçe Kışlak'ınkidir: ana ≤2,04M, ≤213 çizim; uzak yurt örnekli `YurtField` (1 çizim) | Yakında en çok 4 tam yurt | `act1.md` §15; `architecture.md` §7 |
| Y20 | Kayıt: `settlement` (order 77) ≤10 KB, `camps` (order 92) ≤4 KB; yapılar `world.sites`'tadır (K21, order 76) | Yolculuk ≤96 KB içinde | Tek yapı kaydı; sıkı dizi |

## 1. Tarih dayanağı

### 1.1 Kaynak satırları

Shiji 110 ve Hanshu 94A metni zh.wikisource baskısından bu taslak için yeniden okundu (2026-11-02); karakterler o baskınındır, Türkçeler bu belgenin.

| # | Kaynak | Metin | Türkçesi | Oyun kuralı |
|---|---|---|---|---|
| S1 | SJ 110 | 逐水草遷徙，毋城郭常處耕田之業，然亦各有分地 | Su ve ot ardınca göçerler, suru, kalıcı yurdu, tarla işi yoktur; ama her birinin payına düşen toprağı vardır | Mete'nin payı (`分地`) II. Perde'de verilir: `tanhu_ordu`; sürü göçer, yerleşim kalır (Y3); V. kademe seçimi (Y6) |
| S2 | SJ 110 | 而單于之庭直代、雲中：各有分地 | Tanhu'nun avlusu Dai ve Yunzhong'a bakar | Avlunun yeri `tanhu_ordu` (K13 [112,8; 43,5]) |
| S3 | SJ 110 | 歳正月，諸長小會單于庭，祠。五月，大會蘢城，祭其先、天地、鬼神。秋，馬肥，大會蹛林，課校人畜計 | Yıl başı beyler avluda küçük toplantıya gelir, kurban sunulur. 5. ay Lung-çeng'de büyük toplantı: atalara, göğe ve yere, ruhlara sunu. Güzün, at semizken Dailin'de büyük toplantı, insan ve hayvan sayılır | §12.2 üç toplantı; Dailin Sayımı yerleşimin sayımıdır |
| S4 | SJ 110 | 而單于朝出營，拜日之始生，夕拜月 | Tanhu sabah konaktan çıkar, doğan güneşe eğilir, akşam aya | Gök Direği'nde Şafak Selamı (§12.4); Tanhu Otağı'nın kapısı doğuya bakar |
| S5 | SJ 110 | 士力能毌弓，盡爲甲騎 | Yay çekebilen her er zırhlı atlıdır | Seferberlik: her hanenin bir yetişkini ere çağrılabilir (§5.6) |
| S6 | SJ 110 | 兒能騎羊，引弓射鳥鼠；少長則射狐兔：用爲食 | Çocuk koyuna biner, yayla kuş ve fare vurur; biraz büyüyünce tilki ve tavşan: yiyecek için | Hanenin av payı (K24 `huntRationPerDay`) çocuk ve gencin işidir; çocuk iş havuzuna girmez |
| S7 | SJ 110 | 與匈奴閒，中有棄地，莫居，千餘里，各居其邊爲甌脫 | Hun ile aralarında kimsenin oturmadığı bin li'den geniş boş toprak, iki yanda gözcü konakları | **Gözcü Konağı / Watch Post** (`outpost`, §7.6); III. Perde Tunghu sınırı |
| S8 | SJ 110 | 大破滅東胡王，而虜其民人及畜產 | Tunghu kralını ezdi, halkını ve hayvanlarını aldı | Hayvan ganimet olur; insan olmaz: yenilenler seçer (§5.7). Tasarım tercihi, Destan Kitabı'nda yazılır |
| S9 | SJ 110 | 其法，拔刃尺者死，坐盜者沒入其家 | Yasaları: bir karış bıçak çeken ölür; hırsızın hanesine (malına ve ailesine) el konur | Divan davaları (§12.3): hırsızlıkta «malını al» seçeneği; kan ve ceza sahnesi görünmez |
| S10 | SJ 110 | 冒頓自立爲單于 | Mete kendini Tanhu ilan etti | II. Perde sonu: avlu işlevleri açılır (§2) |
| S11 | Hanshu 94A, Huyandi Tanhu (MÖ 85–68) | 衛律為單于謀「穿井築城，治樓以藏穀，與秦人守之…」即穿井數百，伐材數千。或曰胡人不能守城，是遺漢糧也，衛律於是止 | Wei Lü Tanhu'ya kuyu kazmayı, sur kurmayı, tahılı kulede saklamayı, Çinlilerle korumayı öğütler; yüzlerce kuyu kazılır, binlerce ağaç kesilir. Biri «Hu suru tutamaz, Han'a tahıl bırakmak olur» der; vazgeçilir | Y6: Surlu ya da Göçer Avlu. Olay Mete'den bir buçuk kuşak sonradır: `tasarım tercihi` |
| S12 | Hanshu 94A, Yizhixie Tanhu | 北至窴顏山趙信城而還 | Han atlıları Tianyan dağındaki Zhao Xin kalesine dek gelip döner | Hun'un sığınan Han beyine kurdurduğu surlu yer: sığınan hanelerin bilgisi (§5.3) |
| S13 | Hanshu 94A, Laoshang Tanhu | 匈奴父子同穹廬臥 | Hun'da baba ve oğul aynı keçe evde yatar | Hane bir yurttur (Y7) |

### 1.2 Arkeoloji

- **Ivolga (Buryatya, Selenga'nın sol kıyısı).** Planlı yerleşim, 348 × 194–216 m; üç yanda dört sıra toprak sur ve üç sıra hendek (35–40 m'lik kuşak), içte kalın kütükten duvar. 57 konut kazıldı: yarı gömük, gömük ve yer üstü, en büyüğü 6,85 × 6,65 m, güney surlarına koşut sıralar; kütükle çevrili >4,5 m kuyu. Demir eritme (körüklü ocak), tunç dökümü, çarkta çömlek, kemik, ağaç, deri, dokuma; darı, arpa, buğday. Halk karışıktır: yerli, Hun ve Kuzey Çin'den gelenler (sığınanlar ve savaş tutsakları; zanaatçı ve çiftçi). Tarih MÖ 2.–1. yy (radyokarbon MÖ 1. yy – MS 1. yy ortası); kazıcı A. V. Davydova kuruluşu Mete'ye bağlar, sayı Kradin'indir (2.500–3.000 kişi tahmini). Oyun: V. kademenin Surlu yolu (sur ve hendek 40 × 10 m, 12 yarı gömük ev, darı tarlası, tahıl kulesi). Tutsak yoktur; Çinli hane sığınan olarak, kendi seçimiyle gelir (§5.7).
- **Sanjiaocheng (Hexi, Shajing kültürü), `groups-research.md` §5.** Toprak sedde içinde ve çevresinde keçe ev, arpa ve darı çukurları: Ambar Çukuru (`grain_pit`) ve Tahıl Ambarı'nın görünüşü.
- **Terelj ve Khustyn Bulag demiri** (`economy.md` §2.4 kaynağı): Demirci Ocağı III. kademe öncesi açılır (II. Perde, Oba).
- **Arkhangai'daki "Lung-çeng" kazısı** (48°06′11″K, 102°33′38″D): kimlik tartışmalıdır (`groups-research.md` §3). Oyun Lung-çeng'i ayrı iç harita tutar, yerleşim oraya kurulmaz.

### 1.3 Tasarım tercihleri (Kurgu listesine girmez)

`decisions.md` K13: kurgu listesi yalnız uydurulan kişi ve kurumları tutar. Bu belge yeni kişi ve kurum uydurmaz; ustalar rol adıdır, adları perdeleri yazanındır. Aşağıdakiler Destan Kitabı'nda `tasarım tercihi` diye işaretlenir:

| Tercih | Neden |
|---|---|
| Mete'nin payı `tanhu_ordu`'dur, II. Perde'de Teoman verir | Shiji payın yerini yazmaz; avlunun yeri S2'dir, büyüme aynı yerde olur |
| İlk ocak babanın Ulu Ocağı'ndan taşınan közle yanar | `structures.md` §10.6 «Ateş başka ateşten doğar»; darbeye anlam verir |
| Kademe adları (Ocak, Oba, Boy Yurdu, Toy Yeri) | Türkçe söz varlığı oyunun dilidir (kerege, tündük gibi), dönemin sözcüğü değil |
| Yenilenlerin seçimi, Gönül, Kâhya | Esirsiz bir oyun kuralı; tarihte tutsak alınmıştır (S8) |
| Dailin'in yeri avlunun güz otlağıdır | Yeri bilinmez (`groups-research.md` §3) |
| Gök Direği'nin biçimi (taş halka ve uzun direk) | Hun sunak biçimi kaynakta yoktur |
| Surlu Avlu ve darı tarlası | Mete'den sonradır (S11, Ivolga) |
| Yer adları Karasu, Seki, Dirsek, Kuytu | Uydurma küçük yer adlarıdır; gerçek adlar `geography.js`'tedir |

## 2. Açılış ve büyüme yayı

### 2.1 II. Perde açılışı (hikâye alanına öneri)

| Sıra | Görev (öneri id) | TR / EN | Yer | Yerleşime etkisi |
|---|---|---|---|---|
| 1 | `mq2_allotment` | Pay / The Allotment | Teoman'ın avlusu: I. Perde sonundaki `home` sahnesinin devamı (K7). Ana kampın Serbest Gez'i Mete'siz kalır (K6) | Tümen ve güneyin payı verilir; atlas `tanhu_ordu`'yu `scouted` yapar |
| 2 | `mq2_own_hearth` | Kendi Ocağın / Your Own Hearth | Ulu Ocak → `r_tanhu_whistle` → `r_whistle_ordu` → `tanhu_ordu` | Köz Kabı (`ember_pot`†) Ulu Ocak'tan alınır; 48 oyun saati yanar, her `charcoal` 24 saat uzatır, kapla 1 kömür verilir (yol 2 gün: oyalanan yolda besler). Ocak Yeri seçilir (§3.2), Mete'nin yurdu ilk onlukla kurulur (hazır yük `yurt_kit`, 8 el, 11,6 dk), `y_ocak` közle yanar: **Ocak** |
| 3 | `mq2_whistle_camp` | Islık Ordugâhı / The Whistle Camp | `whistle_field` | Onluğun iki çadırı, Talim Alanı; ilk talim (`army.md` `drill`): **Onluk Ateşi** |
| 4 | Serbest Dolaşım | | Her yer | Plan Kipi (`P`), Yerleşim Defteri, iş ataması, kervan |

Bayrak `hearth_ember`: `father` (babanın közüyle yandı), `own` (köz söndü, yerleşimin ateşinden yakıldı). Okuyan: II. Perde sonu (darbe) ve son kart; bedeli ve ödülü yoktur, söz satırıdır. Köz sönerse görev başarısız olmaz: Seki'deki ilk ateş yerine geçer.

**Neden köz.** Yurt bir yapıdır ama ocak bir soydur (`structures.md` §10.6). Babasının ateşini taşıyan oğul, perdenin sonunda o ateşin sahibini vurur; oyuncu bu çizgiyi kendi eliyle taşımış olur.

### 2.2 Perde perde

| Perde | Yıl | Hikâye kancası (hikâye alanına öneri) | Yerleşim | Ordugâh (`whistle_field`) | Hane |
|---|---|---|---|---|---|
| II | 209 | Pay, ocak, ilk aileler (onluğun aileleri, Mete'nin anası, perde yazarına), talim, kervan, av, darbe (son) | Ocak → Oba | Onluk Ateşi → Yüzlük Kampı (100 atlı yerleşik) | 3 → 10 |
| III | 208 | Avlu göçü: eski avlunun Mete'yi tanıyan haneleri gelir (+8, yurtlarıyla); Tunghu elçileri Elçi Yurdu'nda (at, hatun, boş toprak); savaş; yenilenlerin seçimi; Gözcü Konakları | Boy Yurdu | Binlik Ordugâhı (200 yerleşik, toplantıda 1.000); sefer `donghu_land` | 10 → 22 |
| IV | 205–203 | Lung-çeng'e armağan kervanı; Loufan ve Baiyang (Ordos) katılır; batıda Yüeçi; Hexi'ye dönüş (`hexi_ash`); kereste yolu (`r_tanhu_hangai`) | Toy Yeri | Binlik (400 yerleşik); sefer `ordos`, `hexi_ash` | 22 → 45 |
| V | 201–200 | Mayi: Han Xin'in beyleri ve hanesi sığınır (surlu yer bilgisi); Baideng; heqin malı Hazine'ye; Surlu ya da Göçer Avlu tartışması | Tanhu Avlusu (seçim) | Tümen Ordugâhı (600 yerleşik, toplantıda 3.000–10.000); sefer `mayi`, `baideng` | 45 → 80 |
| VI | 198–174 | Kurultay; Dailin Sayımı; 176 mektubu; son kart avluyu okur | Tanhu Avlusu tam | Tümen | 80 → 90 tavan |

### 2.3 Kapılar

| Kapı | Koşul | Kesilirse |
|---|---|---|
| Plan Kipi | `quest:mq2_own_hearth.done`; Mete yerleşim ya da ordugâh iç haritasında; görev sahnesi, sinema, boss, `ride` yok | «Burada yurdun yok.» / «You hold no ground here.» |
| Kademe n ≥ 3 | `act>=n` ve §4.1 «gerekir» sütunu | Defter'de eksik satır yazılır |
| Kademe düşmez | Hane ya da yapı kaybı kademe adını almaz; kademenin verdiği iş (çekim tabanı, tavan) yapının ayakta olmasına bağlıdır | Yanmış otağda avlu toplantısı yapılmaz, kademe yine Toy Yeri'dir |
| Avlu işlevleri | `act>=3` (Mete Tanhu) ve Tanhu Otağı ayakta | Divan kapalı |
| Hazine, toplantı | IV. kademe ve ilgili yapı | |
| V. kademe yolu | V. Perde'de bir kez, Divan'da; geri alınmaz | §4.3 |

## 3. Yerler

### 3.1 Üç yer türü

| Tür | id | TR / EN | Dünya | Ömür |
|---|---|---|---|---|
| Yerleşim | `own_seat` | Yurt / Hold (Defter'de «Yurdun / Your Hold») | `tanhu_ordu` | II–VI, kalıcı |
| Ana ordugâh | `own_camp` | Ana Ordugâh / Home Encampment | `whistle_field` | II–VI, kalıcı |
| Sefer ordugâhı | `field_camp` | Sefer Ordugâhı / Field Camp | Sefer iç haritasının `campSites` yerlerinden biri | Seferle kurulur, dönüşte sökülür ya da bırakılır |

**Yer kimlikleri** K24 taslağının kayıt ve benzetim adlarıdır (`d2/economy.md` §16: `own_seat`, `own_camp`); `economy.md` §8.3'ün `SupplyLedger('own_camp')`'ı ordugâhın defteri olur, yerleşimin defteri `own_seat`'tir (§9.4). Zon kimlikleri ayrıdır: `world.sites.zones` anahtarı zondur (`tanhu_ordu`, `whistle_field`).

**Neden iki ayrı dünya, tek dünyada iki köşe değil.** (1) Kullanıcı ayrılık istedi; (2) tümen ordugâhı 448 × 588 m'lik kafes kamayı ve 800 × 168 m'lik bloğu sığdıran bir ova ister (`army.md` §4.2), yerleşimin dere vadisi ister; (3) iki dünyanın bütçesi ayrı kalır, en kötü kare biri olur; (4) aradaki gün kervana anlam verir. Bedeli atlas bacağıdır: 16 gerçek sn (`travel.md` §9.1 `T = 8 + 0,25 × 30`), saat 1 gün atlar.

**Zon adı.** `tanhu_ordu` II. Perde'de «Mete'nin Payı / Mete's Allotment», III'ten «Tanhu Ordusu / The Tanhu's Ordu» (bugünkü `travel.md` §1.3 adı). Yer adı satırı kademeyi ekler: «Tanhu Ordusu · Boy Yurdu» / «The Tanhu's Ordu · Lineage Seat».

### 3.2 `tanhu_ordu` iç haritası (taslak)

1400 × 1050 m (Kışlak boyu: `terrain-patches`, `nav-patches` aynen), çerçeve x doğu, z güney, merkez (0, 0). İklim `steppe_south` (Şilin Gol bozkırı, `weather.md` §4.1), enlem 43,5° (`time.md` §3). Koordinatlar Faz 13 arazi yazımında Node'da gerçek nav ile doğrulanır (`structures.md` §11.1'in deseni); sapma bu tabloya yazılır.

| Öğe | Yer | İş |
|---|---|---|
| **Karasu / Black Water** deresi | (−700, −300) → (−80, −150) → (160, 60) dirsek → (700, 150) | Su, söğüt ve karaağaç, saz, ot çayırı; taşkın kuşağı ±25 m (§13.2) |
| Kuzey tepeleri | z −380..−525 | Taş (`node_quarry`, `node_boulder`), az demir damarı |
| **Kutlu Tepe / Holy Hill** (`sacred_hill`) | (−420, −470), +24 m, ağaçsız | Gök Direği'nin tek yeri |
| Güney ve doğu ovası | z > 100 | Otlak, tezek, ot çayırı |
| Saksavul çalısı | (−560, 360), r 140 | Yakacak |
| Tuz kabuğu | (520, 470), r 50 | Tuz |
| Kapılar | `gate_ordu_w` (−690, −260) → `whistle_field`; `gate_ordu_e` (690, 180) → Ordos, Mayi, Tunghu | Uzak Durak (`travel.md` §9.3) |

**Ocak Yeri / Hearth Site** (`mq2_own_hearth`'ta seçilir, geri alınmaz).

| id | TR / EN | Merkez | Kazanç | Bedel |
|---|---|---|---|---|
| `hs_terrace` | Seki / The Terrace | (−80, −120) | Düz (r 60 m ≤3°), suya 45 m, taşkın yok, iki kapıya eşit | Açık bozkır: sert rüzgârda `R` tam (§13.2) |
| `hs_bend` | Dirsek / The Bend | (160, 40) | Ot ve söğüt 100 m içinde (yem, odun +), suya 20 m | Konut halkasının %20'si taşkın kuşağında; çamur araba ×1,2 |
| `hs_lee` | Kuytu / The Lee | (−300, −340) | Kuzey rüzgârından korunur (sıçrama rüzgârı −4 m/sn), taş 120 m, Kutlu Tepe 250 m, kule görüşü +%30 | Suya 190 m: kuyu gelene dek konutta Gönül −0,3/gün (§13.2) |

Her aday için halka parselleri (§13.1) merkezden türer ve arazi kurallarıyla kırpılır; üçü de önceden hesaplanıp veriye yazılır (yükleyici hesaplamaz).

**Düğüm kümeleri** (`spec.nodes` biçimi, `economy.md` §3.5).

| Küme | Tür | Adet | Ürün (yaklaşık) | Not |
|---|---|---|---|---|
| `c_elm_bend` | `node_elm` | 220 | 660 kütük | Kalıcı |
| `c_willow_brook` | `node_willow` | 160 | 320 kütük + kabuk | Kalıcı; kabuk şafakta |
| `c_reed_bend` | `node_reed` | 300 | Günde ≤600 saz | Yenilenir |
| `c_hay_meadow` | `node_hay` | 200 | Günde ≤400 ot; yaz ve güz | Yenilenir |
| `c_dung_steppe` | `node_dung` | 400 | Günde ≤400 tezek | Yenilenir |
| `c_saxaul` | `node_saxaul` | 120 | 120 kütük | Kalıcı |
| `c_quarry` | `node_boulder`, `node_scree` | 80 + 30 | 320 + günde 90 taş | |
| `c_clay` | `node_clay` | 20 | Günde 60 kil | |
| `c_salt` | `node_salt` | 30 | Günde 60 tuz | |
| `c_iron` | `node_vein_iron` | 8 | Günde 24 cevher | Azdır: demir ganimet (`iron_scrap`) ve takasla tamamlanır |

**Kereste baskısı (bilerek).** Zondaki kalıcı odun ≈1.100 kütüktür. I–III. kademe ≈700 kütük ister (22 yurt × 23 kütük eşdeğeri + atölyeler + arabalar); IV. kademede bitmeye başlar: göçebe hanenin getirdiği yurt (Y10), `r_tanhu_hangai` kereste kervanı (IV) ve takas. Göçer Avlu az odun ister, Surlu Avlu çok: seçim ekonomiye dokunur.

### 3.3 `whistle_field` iç haritası (taslak)

1400 × 1050 m düz Gobi ovası, iklim `gobi`, enlem 44,2°.

| Öğe | Yer | İş |
|---|---|---|
| **Pınarlar / The Springs** | z −420 boyunca 5 pınar | Su; at hatları yanında |
| Talim ovası | (0, 40), 320 × 200 m | Talim Alanı, ıslık sahneleri, tümen dizilişi |
| Ordugâh parselleri | `camp_n` (−250, −300), `camp_e` (300, −250), `camp_s` (0, 330) | Çadır, buyruk yurdu, silahlık, okçu, ambar |
| **Bakış Sırtı / Lookout Ridge** | z +480 | `army.md` §7.2 tümen bakışı |
| Kapılar | `gate_whistle_w` (−690, 0) → `tanhu_camp`; `gate_whistle_e` (690, −80) → `tanhu_ordu` | |
| Düğüm | Tezek bol (atlar), ılgın ve saksavul az, taş az | Ordugâhın odunu kervanla gelir |

### 3.4 Sefer ordugâhı yerleri

Sefer iç haritasının spec'i `campSites: [{ id, x, z, r, water, grazeKm2 }]` yazar (1–2 yer). Kural: suya ≤200 m, eğim ≤8°, düşman kampına ≥600 m. Sefer ordugâhı `CampPlan` ile kurulur (§10.4). Önerilen: `donghu_land` 2, `ordos` 2, `hexi_ash` 1 (Kışlak'ın eski Ak Otlağı), `mayi` 1, `baideng` 1 (kuşatmanın dışında).

## 4. Kademeler

### 4.1 Tablo

| n | id | TR / EN | Perde | Gerekir (kademeye çıkış) | Açar | Hane tavanı | Çekim tabanı (hane/gün) |
|---|---|---|---|---|---|---|---|
| 1 | `ocak` | Ocak / Hearth | II | Mete'nin yurdu aşama 7, ocak yanık (`mq2_own_hearth`) | `yurt`, `tent`, `hut`, `pen`, `fence`, `horse_line`, `rack`, `grain_pit`, `felt_yard`, `banner_pole`, `lantern_post`; iş ataması (sürü, toplama, inşa, nöbet) | 4 | 0,25 |
| 2 | `oba` | Oba / Clan Camp | II | Yurtta ≥3 hane; Keçe Avlusu, Ağıl, At Hattı, Ambar Çukuru; yiyecek ≥10 gün | `stable`, `store_yurt`, `shed`, `tannery`, `wood_shop`, `smithy`, `kiln`, `cart_felt`; zanaat ataması, kervan, seferberlik | 12 | 0,4 |
| 3 | `boy_yurdu` | Boy Yurdu / Lineage Seat | III | `act>=3`; ≥10 hane; Ahır, Ambar Yurdu, Demirci Ocağı, Ağaç Atölyesi, Sundurma | `otag`, `envoy_yurt`, `sky_pole`, `gathering_ground`, `granary`, `fletchery`, `watch_tower`, `barter_ground`, `outpost`, `cart_high`; Divan | 25 | 0,6 |
| 4 | `toy_yeri` | Toy Yeri / Gathering Seat | IV | `act>=4`; ≥22 hane; Tanhu Otağı, Elçi Yurdu, Gök Direği, Toy Alanı, Tahıl Ambarı, ≥1 Gözcü Kulesi; ortalama Gönül ≥50 | `treasury`, `well`, `healer_yurt`, `cart_war`; Kış Toplantısı avluda, armağan, Hazine | 50 | 0,9 |
| 5 | `tanhu_avlusu` | Tanhu Avlusu / The Tanhu's Court | V | `act>=5`; ≥45 hane; Hazine, ≥1 Kuyu; ortalama Gönül ≥55; yol seçildi (§4.3) | Yola göre §4.3; Dailin Sayımı avluda, Kurultay (VI) | 90 | 1,2 |

**Neden bu adlar.** *Ocak* hem ateş hem soydur; *Oba* birkaç hanenin göçebe obasıdır; *Boy Yurdu* Mete'nin soyunun (Luandi, II. Perde'de açılır, `groups-research.md` §4) oturduğu yerdir: darbeden sonra avlu buraya gelir; *Toy Yeri* yıl başı beylerin toplandığı yer (S3 小會單于庭); *Tanhu Avlusu* 單于庭'nin kendisidir. Ekonomi taslağının önerdiği «Ordu / Court» ordugâhla, «Han Ordası / Khan's Seat» oyunun unvanıyla (Tanhu, K15) karışırdı.

### 4.2 Tam bileşim

Bir kademenin içinde kurulması beklenen yeni yapılar (K24 önerisi, yerleşim kararıyla). Hane sayısı kademenin sonundadır; yurt sayısına hanenin getirdiği hazır yük dahildir. Emek K21 İG'sidir (†: bu belgenin önerisi, §7).

| Kademe | Yeni yapılar | Hane | Yapı emeği İG | 4 el, tek şantiye eşdeğeri |
|---|---|---|---|---|
| Ocak | yurt 3, tent 2, pen 1, horse_line 1, rack 1, felt_yard 1, grain_pit 1 | 3 | 4,5 | 1,3 gün |
| Oba | yurt 7, stable 1, pen 1, store_yurt 1, tannery 1, wood_shop 1, smithy 1, kiln 1, shed 1, cart_felt 1 | 10 | 14,1 | 4,1 gün |
| Boy Yurdu | yurt 12, otag 1, envoy_yurt 1†, sky_pole 1†, pen 2, stable 1, granary 1, fletchery 1, gathering_ground 1, cart_high 2, watch_tower 2, barter_ground 1†, outpost 2† | 22 | 26,1 | 7,6 gün |
| Toy Yeri | yurt 23, treasury 1†, healer_yurt 1†, pen 4, stable 2, store_yurt 2, granary 1, shed 2, well 2, watch_tower 2, cart_war 2, smithy 1, lantern_post 6† | 45 | 42,0 | 12,2 gün |
| Tanhu Avlusu, Surlu | yurt 23, pit_house 12, rampart 40 (400 m), rampart_gate 2†, field 6, granary_tower 3, store_yurt 2, smithy 1, kiln 1, watch_tower 4, well 2 | 80 | 91,1 | 26,5 gün |
| Tanhu Avlusu, Göçer | yurt 35, wagon_felt 6†, horse_line 4, pen 4, shed 2, granary 1, store_yurt 2, smithy 1, kiln 1, watch_tower 2, well 2 | 80 | 54,9 | 16,0 gün |

**Gerçek süre bu sütun değildir.** Şantiyeler paralel yürür, halk büyür: Oba'nın 14,1 İG'si 6 hanenin (çobanlıktan sonra 12,6 iş ağırlığı) ve 15 erin (K24 `armyDetail`) elinde ≈1 günde biter; asıl sınır malzeme zinciridir (yurt başına ≈10 İG toplama ve zanaat, K24 `targets.building.home`) ve gelen hanedir. K24'ün kademe hedefi (`targetDays` 1–3, 2–5, 2,5–6, 3–7, 3–10) bu tabloyla benzetilir (§21).

### 4.3 V. kademe yolu

V. Perde'de, Han Xin'in sığınan haneleri geldikten sonra Divan'da bir kez sorulur. Wei Lü'nün sözünü sığınan bey, itirazı Hun beyi söyler (satırları hikâye alanı yazar; burada yalnız iki konum).

| | Surlu Avlu / Walled Court | Göçer Avlu / Moving Court |
|---|---|---|
| Kaynak | 穿井築城，治樓以藏穀 (S11), Ivolga | 毋城郭常處耕田之業 (S1), 胡人不能守城 (S11) |
| Açar | `rampart`, `rampart_gate`†, `pit_house`, `field`, `granary_tower` | `wagon_felt`† (Keçe Göç Arabası, `travel.md` §3.2), ek `horse_line`, `pen` |
| Baskın | Akının başarı payı ×0,5 (sur aşılmalı) | Sürü kaybı ×0,6 (sürü dağılıp kaçar), ambar kaybı ×1 |
| Kış yiyeceği | Darı: tarla başına mevsimde 60 darı (K24 `field`) | Sürü tavanı ×1,25 (otlak dönüşü) |
| Zanaat | Kalıcı atölye ×1,1 | Yok |
| Ordu | Yok | Ordugâh ambarına günlük pay ×1,1 (sürü orduyla yürür) |
| Gönül | Sığınan haneler +10 | Bozkır haneleri +5 |
| Bedel | Yapı emeği 91 İG, odun ≈2× | Yurt ve araba bakımı; odun az |

Seçim kademe adını değiştirmez; son kart ve ozan dörtlüğü okur (`court_path: walled|moving`).

## 5. Hane ve nüfus

### 5.1 Hane

| Alan | Değer | Kaynak |
|---|---|---|
| Kişi | 2 yetişkin, 1 genç, 1 yaşlı, 1 çocuk | K24 `params.householdSize`; S13 |
| Öğün | 2 × 1 + 1 + 0,8 + 0,5 = **4,3 öğün/gün** | K24 `rationPer` |
| İş ağırlığı | Yetişkin 1 (`hand`), genç 0,75 (`apprentice`), yaşlı 0,5, çocuk 0 → 3,25; ev işi −0,5 → **2,75** | K24 `workerEq`, `choresEqPerHousehold`; K21 roller |
| Sürü | 35 koyun, 10 keçi, 7 at, 4 sığır, 0,5 deve ≈18 at eşdeğeri | K24 `household.herd` |
| Çobanlık | Hane başına ≈0,65 işçi (K24 `herderPer`); net ≈2,1 | Hesap §21 |
| Yakacak | Günde 3 (kış 3,5) birim: pişirme ve ışık | K24; K1: ısınma yok |
| Konut | Bir yurt ya da bir yarı gömük ev; geçici çadır ya da kamış kulübe (½ hane) | |

**Yaşlı** yalnız tezgâhta ve ev işinde çalışır (keçe, ip, kurut); şantiye, sürü ve nöbete atanmaz; önder sayılmaz (K21 önder kuralı ≥0,75). **Genç** çıraktır. **Çocuk** iş havuzuna girmez; hanenin av payını genç ve çocuk getirir (S6). Bu kural K21'in `child` rolünü yalnız Serbest Gez'in Çocuğuna bırakır.

### 5.2 Kişi kaydı

İşçiler kimlikle atanır (K21 `assign(siteId, workerIds)`). Kimlik haneden türer, saklanmaz: `h<hane>a0`, `a1` yetişkin, `y0` genç, `e0` yaşlı. Kayıtta yalnız iş kodu tutulur (§16).

**Ustalar** hane kaydında `crafts` ve `w` taşıyan yetişkindir (K21 «zanaat ve ağırlık kişinin kaydındadır»). Rol adları `progression.md` §4.3 ve K24 `role` alanıyla birdir; adlarını perdeyi yazan koyar.

| Rol | TR / EN | Zanaat (K21) | Ağırlık | Ne yapar | Nasıl gelir |
|---|---|---|---|---|---|
| `cr_carpenter` | Ağaç Ustası / Master Carpenter | `wood` | 1,25 | Ağaç Atölyesi usta tarifleri (kerege takımı, tündük) | Avlu göçü (III) ya da armağan |
| `cr_smith` | Demirci / Smith | `earth` | 1,25 | Demirci Ocağı usta tarifleri (kazan, tunç) | II. Perde, Oba'ya çıkış görevi |
| `cr_bowyer` | Yaycı / Bowyer | `wood` | 1 | Okçu Yurdu'nda yay (`progression.md` `m_bowyer`) | III |
| `cr_cartwright` | Arabacı / Cartwright | `wood` | 1 | Tekerlek çifti (K24 `rc_wheel_pair`) | III |
| `cr_earth` | Toprak Ustası / Earth Builder | `earth` | 1,25 | Sur, kuyu, yarı gömük ev | V, sığınan hane (Surlu yol) |
| `m_quarter` | Ambarcı / Quartermaster | | 1 | Kâhya'nın sesi; ambar kaybı −%25 | `progression.md` §4.3 (`tola_lives`) |
| `m_groom` | Seyis / Groom | | 1 | Ahır ve at hattı; ordugâhta `horse_fat` +1/gün kışın | `progression.md` §4.3 |
| `m_custom` | Töreci / Keeper of Custom | | 1 | Toplantı ve Divan'ın töresi; Kurultay | `progression.md` §4.3 |
| `cr_healer` | Otacı / Healer | | 1 | Otacı Yurdu: yaralı ×2 | IV |

Usta yoksa K21 `K_usta` 0,7 işler; `master` tarifleri (K24 `who: master`) hiç işlemez.

### 5.3 Katılım

| Kaynak | id | Ne zaman | Adet | Köken | Getirdiği | Gönül başı |
|---|---|---|---|---|---|---|
| Hikâye: ilk aileler | `hh_story` | II, `mq2_own_hearth` sonrası | 1–3 (onluğun aileleri, `first_ten` sağ ve `ties` ≥4 iki üyede bir; Mete'nin anası perde yazarına) | `xiongnu`, `fugitive` | Yurt yükü yok, sürü 4 at eşdeğeri | 70 |
| I. Perde yankısı | `hh_saved` | II | `names_known` ≥12: +1; `tola_lives`: +1 | `fugitive` | Yok | 65 |
| Çekim | `pull` | Her şafak | §5.3.1 | Çoğu `xiongnu` | %60 yurt yükü, tam sürü | `50 + 2 × kut − korku`, 25–80 |
| Avlu göçü | `court_move` | III başı | 8 | `xiongnu` | Yurt yükü, tam sürü | 45 |
| Armağan | `gift` | IV+, Divan | 2–4, 3 gün sonra; soy başına perdede bir | `huyan`, `lan`, komşu boylar | Yurt yükü, sürü | 60 |
| Yenilenlerin seçimi | `choose` | Zaferden sonra | §5.7 | Yenilenin kökeni | %30 yurt yükü, sürünün yarısı | 40; Korku ile gelen 30 |
| Kaçkın | `refugees` | Yol olayı `ev_refugees` «Paylaş» (`travel.md` §9.6), kervanın töresi | 1–2 | Karışık | Yok | 70 |
| Sığınan | `defectors` | V (Mayi, Han Xin); IV'te seçmeli | 6–12 | `han` | Yok; sürü yok; `cr_earth`, çiftçilik, kerpiç bilgisi | 50 |
| Heqin maiyeti | `heqin` | V–VI | 1–2 | `han` | Hazine malı | 50 |

#### 5.3.1 Çekim formülü

```
pull  += base(tier) × (1 + 0,03·kut + 0,015·korku) × foodK × roomK × gonulK × warK      // her şafak
foodK  = yiyecek ≥15 gün: 1 · 5–15: 0,5 · <5: 0
roomK  = hane < tavan ve boş konut parseli var: 1 · değilse 0
gonulK = ortalama Gönül ≥70: 1,25 · <40: 0,5 · arası 1
warK   = zonda etkin düşman ya da baskın tehdidi: 0,5 · değilse 1
pull ≥ 1 → bir hane yola çıkar (pull −= 1), 0,5–1,5 gün sonra kapıdan gelir
```

| Kademe, örnek Kut / Korku | Günlük | 10 günde |
|---|---|---|
| Ocak, 6 / 2 | 0,30 | 3 |
| Oba, 6 / 2 | 0,48 | 4,8 |
| Boy Yurdu, 10 / 4 | 0,82 | 8,2 |
| Toy Yeri, 14 / 6 | 1,36 | 13,6 |
| Tanhu Avlusu, 18 / 8 | 1,99 | 19,9 |

**Neden Korku da çeker.** Bozkırda güçlüye sığınmak korkudan da olur; ama Korku ile gelen düşük Gönülle gelir ve ilk kıtlıkta gider (§5.5). Kut sadık hane çeker. İkisi de sayı göstermez (`progression.md` §5.1); Defter yalnız Çekim'i dört kademeli bir işaretle gösterir.

**Gelen hane** kapıdan girer (kukla kafile: 2 kişi ve yüklü at, sürü `army.md` T2 örnekli); yurt yükü varsa Kâhya ona boş bir konut parseli verir, hane kendi yurdunu kurar (1 İG, kendi 2,75 ağırlığıyla aynı gün). Yükü yoksa çadır ya da kulübe ister; yoksa açıkta bekler (Gönül −1/gün, 3 gün sonra gider).

### 5.4 Gönül

Hane başına 0–100. Değişim (günlük, şafakta; olaylar anında):

| Olay | Değişim |
|---|---|
| Yiyecek ≥5 gün | +0,3/gün |
| Yiyecek <5 gün | −1/gün |
| Kıtlık, yiyecek <2 gün | −3/gün |
| Çadır ya da kulübede, 3 günden uzun | −0,5/gün |
| Suya >150 m (konut) | −0,3/gün |
| Duman ve koku yurda (rüzgârüstü atölye, §13.2) | −0,2/gün atölye başına |
| Toy (Toy Alanı'nda şölen, hane başına 2 öğün ve 1 kımız) | +6, 10 günde bir |
| Kış Toplantısı | +5 |
| Ganimetin halka payı (`army.md` `booty_share`) | +2/gün, 5 gün |
| Baskın yendi (zarar gördü) | −6 |
| Divan'da sert yargı | −3 (o kökenin bütün haneleri) |
| Mete 10 günde en az bir gün avluda | +1 |
| Seferberlikte 10 günden uzun | −0,2/gün (o hane) |

| Gönül | Etki |
|---|---|
| <25 | Ayrılış adayı (§5.5) |
| <40 | O hanenin işçileri ×0,85 |
| 40–69 | Yok |
| ≥70 | ×1,1; çekime ×1,25 (ortalama ≥70 ise) |

Defter Gönül'ü beş düğümlü iple gösterir, sayı yazmaz.

### 5.5 Ayrılış

Her şafak hane başına: Gönül <25 ise %3; yiyecek <2 gün ise ek %5; `korku` ≥14 ve `kut` <4 ise Gönül ayrılışı ×2; `kut` ≥14 ise yalnız kıtlık ayrılışı (`army.md` §3.4 «Kut ≥14 firar yok» eşi). Giden hane yurdunu söker (0,35 İG, K21 `DISMANTLE`), sürüsünü ve yükünü alır, kapıdan çıkar. Kart: «{n} hane göçüp gitti.» / «{n} households have moved away.»

### 5.6 Seferberlik

S5: yay çeken her er atlıdır. Divan ya da Defter'de «Ere Çağır / Call to Arms»: hane başına en çok bir yetişkin bir birliğe katılır (`UnitRec.strength` +1, `origin` hanenin kökeni, başlangıç `loyalty` = hanenin Gönül'ü). Hanenin ağırlığı −1; birlik dönünce geri gelir. 10 günden uzun seferde hane Gönül −0,2/gün. III. Perde `muster_law` (令國中有後者斬, `army.md` §1 #18) bu çağrıyı zorunlu yapar: Korku +1, çağrılmayan hanede Gönül −3.

### 5.7 Esir yoktur

- **Kural.** Eşya tablosunda insan yoktur; `join` yalnız §5.3 kaynaklarından çağrılır; ganimet tablosu (K24 `loot`) insan döndürmez. Sınama bunu denetler (§21).
- **Yenilenlerin seçimi.** Zaferden sonra yenilen topluluğun hane sayısı `D` (sahne verisi). Katılan pay `clamp(0,15 + 0,02·kut + 0,015·korku, 0,1, 0,6)`; bunların `korku / (kut + korku + 1)` kadarı Korku ile gelir (Gönül 30). Kalanlar sürülerinin yarısıyla çekilir; sahnede atlı kafile uzaklaşır. Hayvan ganimettir (`army.md` §3.5 `booty_share`).
- **Destan Kitabı.** «Tarih Tunghu halkının alındığını yazar. Bu oyunda yenilen kendi yolunu seçer.» / «History says the Donghu were taken. In this game the defeated choose their own road.»

## 6. İş ataması

### 6.1 İşler

| İş | id | Kim | Ne üretir | Gerek |
|---|---|---|---|---|
| Sürü / Herding | `herd` | Yetişkin, genç | Sürü güvenliği, sağım ve kırkımın el emeği (K24 `herdLabour`, `Herd.day` `labourIS`) | Kapsam `Σ baş / herderPer`; kış ×1,5. Kapsanmayan pay K24 `Herd.day` kaybına girdi olur (öneri: günde %1, kurt ve dağılma) |
| Toplama / Gathering | `gather` | Yetişkin, genç | Kümeden ham (K24 `gather.npcPerWh`); av kolu (K24 `hunts.npcWh`) | Küme ve tür seçilir; kalıcı küme tükenir (§9.5) |
| Zanaat / Craft | `craft` | Yetişkin, genç, yaşlı | Tezgâhta tarif (K24 `recipes`), sürekli emirle (§8.2) | Tezgâh `crewMax` |
| İnşa / Building | `build` | Yetişkin, genç | Şantiye emeği (K21 `SiteSystem`) | Yapı el sınırı |
| Nöbet / Guard | `guard` | Yetişkin | Baskın savunması, gece uyarısı | Barışta 8 hanede 1, savaş mevsiminde 4 hanede 1 |
| Taşıma / Haul | `haul` | Yetişkin | Kervan sürücüsü (araba başına 1) | Kervan buyruğu |

**Bir kişi bir iştedir** (K21 §6.4). Boştakiler ev işinde Gönül +0,05/gün kazanır.

### 6.2 Kâhya / Steward

Açıkken (varsayılan) her oyun saatinin başında dağıtır; oyuncunun kilidi önce gelir.

| Sıra | Ölçüt |
|---|---|
| 1 | Sürü kapsamı tam |
| 2 | Nöbet tabanı |
| 3 | Yiyecek ≥15 gün (yoksa av kolu ve süt işleme) |
| 4 | Yem: güz sonunda kış için atlı başına 100 gün (K24 `hayDays`); yaz sonundan ot biçimi |
| 5 | Yakacak ≥10 gün |
| 6 | İnşa sırası (öncelik 0–3, K21 «Boştaki eller yapıya») |
| 7 | Zanaat sürekli emirleri |
| 8 | Kervan sürücüleri (kalkıştan 2 saat önce ayrılır) |

Kilit: iş başına en az ve en çok; şantiye başına el (K21 + / −); tezgâh başına el. «Kâhya'yı kapat / Steward off»: dağıtım donar, değişen iş gücü (gelen, giden) boşta kalır.

### 6.3 Ordu eli ve Mete

- **İş Kolu** (`army.md` `cmd_detail`): ordugâhtan gelen erler yerleşim havuzuna «Er / Rider» olarak girer (ağırlık 1, `home` ustası), yiyeceği birliğin `supply`'ından düşer, o saatte talim kazanmaz (K21 §8.3). K24 `armyDetail` önerisi kademe başına 5, 15, 20, 30, 50.
- **Mete** şantiyede «Çalış / Work» ile 1 ağırlık ve emek becerileriyle girer (K21 §3); Kâhya onu saymaz.

### 6.4 İş saati, gece, fener

- **İş penceresi** K20'nindir: yerleşim ve ordugâh yazın 05:30–21:30, kışın 07:00–23:00 (16 saat, K24 `prodHoursPerDay`).
- **Gece işi** şantiyenin emridir (K21 E8): «Gece de çalışılsın» meşale ister. Yerleşimin bedeli: gece çalışan işçinin hanesi Gönül −0,2/gece.
- **Fener Direği / Lantern Post** (`lantern_post`†): 8 m ışık; K21 gece ışığının (c) kaynağı. 3 gecede 1 `lamp_oil`. Görüş: ışık uzaktan görünür (`act1.md` «ışık gösterir ama ele verir»). Gerçek ışık değildir: köşe rengi ve `fxGlow` (`architecture.md` §0 kural 7).

## 7. Yapı kataloğu

### 7.1 Okuma

- **id:** K21 (`labour.md` §8) ve K24 (`econ-model.json` `structures`) kimlikleri bu belgede **onaylandı**; † işaretliler bu belgenin eklediği türlerdir.
- **Görünüm:** `STRUCTURE_DEFS` türü ve hazır ayarı (`structures.md` §3.5, §4); yeni aileler §7.9 ve `d2/settlement-delta-structures.md`.
- **İG:** K21 iş günü (tek el, usta varken); † bu belgenin önerisi, K21 alanı yeniden hesaplar.
- **Malzeme:** K24 `bom` (II. Perde bileşen biçimi); † bu belgenin önerisi. Kısaltmalar: odun `tag:wood`, kapı `door_frame`, kerege `kerege_set`, uuk `uuk_set`, tündük `yurt_crown`.
- **Kapasite:** konut hane, ağıl baş, kap Yük (K24 `cap`).
- **Bakım:** mevsim sonunda ambardan düşer (§7.10).

### 7.2 Konut

| id | TR / EN | İşlev | Ayak izi, m | Görünüm | Kademe, önkoşul | Kapasite | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `yurt` | Yurt / Yurt | Hanenin evi | r 7,05; ped r 8,5 | `yurt`, `winter` (yakın), `closed` ve `YurtField` (uzak); iç `otaci`, `bolmeli` | 1 | 1 hane | 1 | taş 6, kapı 1, kerege 1, ip 6, tündük 1, sırık 2, uuk 1, çiy 1, keçe 6, köz 1 |
| `otag` | Otağ / Great Yurt; avluda «Tanhu Otağı / The Tanhu's Great Yurt» | Mete'nin avlusu, Divan | r 9,9; ped r 11,5 | `yurt` `hero` × **1,4** ölçek, iç `han`, kapı doğuya (S4) | 3, `act>=3` | Mete'nin hanesi + 40 kişilik huzur | 2,5 | taş 10, kapı 1, kerege 2, uuk 2, `crown_great` 1, sırık 4, çiy 2, `felt_white` 12, ip 14, `dye` 2, köz 1 |
| `tent` | Çadır / Tent | Geçici konut; ordugâhta 5 er | r 2,6 | `tent` | 1 | ½ hane ya da 5 er | 0,15 | odun 2, sırık 2, ip 4, keçe 3 |
| `hut` | Kamış Kulübe / Reed Hut | Keçesiz geçici konut | r 2,8 | `hut` | 1, saz kümesi | ½ hane | 0,5 | taş 2, odun 4, ip 4, saz 18 |
| `pit_house` | Yarı Gömük Ev / Pit House | Sığınan hanenin kalıcı evi | 7 × 7 | Yeni `mound` ailesi (çukur, direk, çatı, örtü) | 5, Surlu | 1 hane | 2 | taş 4, odun 16, kil 6, saz 10, keçe 2 |
| `envoy_yurt`† | Elçi Yurdu / Envoy Yurt | Elçi konağı, diplomasi olayları | r 7,05 | `yurt` `winter`, iç `otag` | 3, Tanhu Otağı | 1 elçi heyeti | 1† | yurt + `felt_white` 2, `dye` 1† |
| `healer_yurt`† | Otacı Yurdu / Healer's Yurt | Yaralı bakımı | r 7,05 | `yurt` `winter`, iç `otaci` | 4 (ordugâhta 2) | 8 yaralı | 1† | yurt + `herb_wormwood` 4† |

### 7.3 Sürü ve at

| id | TR / EN | İşlev | Ayak izi | Görünüm | Kademe | Kapasite | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `pen` | Ağıl / Pen | Gece ağılı, kurt kaybını keser | 40 m çizgi (≈12 × 8) | `pen` (örnekli pano) | 1 | 90 küçükbaş ya da 15 sığır | 0,32 | odun 10, dal 72, ip 1 |
| `fence` | Çit / Fence | Yol ve sınır | 10 m | `fence` | 1 | | 0,075 | odun 6, ip 2 |
| `horse_line` | At Hattı / Horse Line | Binek atları, gök gürültüsünde ürkme kaybını keser | 20 m çizgi | `fence` `picket` hazır ayarı† (direk ve tek ip) | 1 | 20 at | 0,08 | odun 6, ip 4 |
| `stable` | Ahır / Stable | Tımar, eyer ve koşum, kışın yem | 10,8 × 6,6 | `stable` | 2 | 8 at; `rc_fodder` tezgâhı | 1,5 | taş 4, odun 18, ip 4, saz 10, keçe 3 |
| `rack` | Kurutma Sırığı / Drying Rack | Kak, kurut | 2 × 1,4 | `rack` | 1 | 6 kür yuvası | 0,002 | odun 4, ip 2 |

### 7.4 Ambar

| id | TR / EN | İşlev | Ayak izi | Görünüm | Kademe | Kapasite | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `grain_pit` | Ambar Çukuru / Grain Pit | Gizli çukur: baskında yarı yarıya bulunmaz, yanmaz (K24) | r 1,4 | Yeni `mound` (çukur, kapak) | 1 | 120 Yük | 0,3 | taş 2, odun 2, keçe 2, deri 1, kil 2 |
| `store_yurt` | Ambar Yurdu / Store Yurt | Genel ambar | r 7,05 | `yurt` `winter`, iç `bolmeli` + çuval | 2 | 400 Yük | 1 | yurt (köz yok) |
| `shed` | Sundurma / Shed | Ot, yem, kütük, kömür | 8 × 8 | `shed` `open†` | 2 | 500 Yük, yalnız `tag:bulk` ve `tag:forage` | 0,6 | taş 2, odun 7, ip 4, dal 6, saz 8 |
| `granary` | Tahıl Ambarı / Granary | Tahıl ve kurutulmuş yiyecek | 8 × 8 | `granary` | 3 | 600 Yük, yiyecek | 0,8 | taş 2, odun 7, ip 4, dal 6, saz 8, kil 4 |
| `granary_tower` | Tahıl Kulesi / Grain Tower | 治樓以藏穀; baskında kayıp %10 (K24) | 7 × 7, h 9 | `tower` `granary†` hazır ayarı | 5, Surlu | 800 Yük, yiyecek | 2 | taş 6, odun 24, ip 6, saz 10, kil 4 |
| `treasury`† | Hazine / Treasury | Değerli mal; armağan, pay, Kurultay dağıtımı | 8 × 6 | `shed` `walled†` (tahta duvar, keçe dam, tunç kilit) | 4 | 120 Yük, yalnız `tag:valuable` | 1,2† | taş 8, odun 16, ip 4, keçe 2, kil 2, `bronze_bar` 1† |

### 7.5 Atölye

Tezgâh kimliği yapı kimliğidir (K24 `stations`). Kazan Ocağı (`kitchen`) yapı değildir: kazanı olan her yurt ocağı (K24).

| id | TR / EN | Tezgâh, iş | Ayak izi | Görünüm | Kademe | El (K24 `crewMax`) | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `felt_yard` | Keçe Avlusu / Felting Yard | `felt_yard`: keçe, ak keçe, çiy, eyer keçesi | 14 × 10 | Yeni `yard` (döğme hasırı, germe çerçevesi, çiy rüzgârlığı) | 1 | 6 | 0,5 | çiy 1, odun 4, ip 4, keçe 2 |
| `tannery` | Sepi Yeri / Tannery | `tannery`: deri, tutkal, ahşap eyer | 10 × 8 | `yard` (sergi, tekne) | 2, su ≤100 m | 3 | 0,4 | odun 6, ip 4, taş 2, `pot` 1, saz 4 |
| `wood_shop` | Ağaç Atölyesi / Woodshop | `wood_shop`: sırık, kapı, kerege ve uuk takımı, tündük, tekerlek, eyer ağacı | 12 × 8 | `shed` `open†` + tezgâh | 2 | 3 | 0,8 | taş 2, odun 12, ip 4, `iron_bar` 1, saz 8 |
| `smithy` | Demirci Ocağı / Smithy | `smithy`: körük demiri, tunç, kazan, uç, alet | 8 × 6 | `mound` (kil ocak, körük) + `shed` `open†` | 2 | 3 | 1,5 | taş 8, kil 6, `leather` 2, odun 6, `iron_bar` 1, saz 6 |
| `kiln` | Fırın / Kiln | `kiln`: kömür | r 2,5 | `mound` (toprak kubbe) | 2 | 2 | 0,6 | taş 6, kil 8 |
| `fletchery` | Okçu Yurdu / Fletcher's Yurt | `fletchery`: ok, yay (usta `cr_bowyer`) | r 7,05 | `yurt` `winter`, iç `silah` + tezgâh | 3 (ordugâhta 2) | 3 | 1,2 | yurt + odun 4 |
| `field` | Darı Tarlası / Millet Field | Ekim (bahar), biçim (güz); mevsimde 60 darı | 50 × 40 | Yeni `field` (sürülmüş toprak çıkartması, örnekli sap) | 5, Surlu, taşkın kuşağı serbest | 6 | 0,5 / tarla | odun 2, dal 10 |
| `well` | Kuyu / Well | Suya uzaklık kuralını 150 m çevresinde sağlar | r 1,5 | Yeni `ring` (taş bilezik, çıkrık) | 4 (Kuytu'da 2) | 3 | 1 | taş 6, odun 4, ip 2, `skin_bag` 1 |

### 7.6 Avlu ve savunma

| id | TR / EN | İşlev | Ayak izi | Görünüm | Kademe | Kapasite | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `gathering_ground` | Toy Alanı / Gathering Ground | Toy, Kış Toplantısı, Dailin Sayımı başı, Kurultay | r 18 | Yeni `ring` (düzlük, keçe oturak halkası, sancaklar) | 3 | 120 oturak | 0,4 | taş 8, odun 12, keçe 4, `dye` 2 |
| `sky_pole`† | Gök Direği / Sky Pole | Şafak Selamı; yıldırım alameti | r 4, direk 12 m | `ring` (taş halka, uzun direk, keçe flama, sunu taşı) | 3, yalnız `sacred_hill` | | 0,6† | taş 24, odun 2 (huş ya da karaçam), keçe 2, `dye` 1, ip 2† |
| `banner_pole`† | Sancak Direği / Banner Pole | Toplanma yeri (`army.md` `rally`), süs | r 0,5 | Yeni `post` | 1 | | basılı tutma 10 İD† | odun 1, keçe 1, `dye` 1† |
| `lantern_post`† | Fener Direği / Lantern Post | Gece ışığı 8 m (§6.4) | r 0,5 | `post` + fener | 1 | | basılı tutma 10 İD† | odun 1, ip 1, `lamp_oil` 1† |
| `barter_ground`† | Takas Yeri / Barter Ground | Gezgin satıcılar (`economy.md` §9): 3 günde 1 (III), 2 (IV), 3 (V) | 16 × 12 | `yard` (gölgelik, at bağlama) | 3 | | 0,5† | odun 8, keçe 4, ip 4† |
| `watch_tower` | Gözcü Kulesi / Watchtower | Görüş 300 m, baskın uyarısı; yıldırım adayı | r 2,4, h 7 | `tower` | 3 | 2 nöbetçi | 1,5 | taş 4, odun 20, ip 4, deri 2 |
| `outpost`† | Gözcü Konağı / Watch Post (甌脫) | Zon kenarı, görüş 400 m, erken uyarı, kervan güvenliği | 8 × 6 | `tent` + `tower` `low†` | 3, zon kenarı | 2 nöbetçi | 0,4† | çadır + odun 6† |
| `rampart` | Sur ve Hendek / Rampart and Ditch | 10 m'lik parça; kapalı halka akının başarı payını ×0,5 yapar | 10 m, kuşak 4 m | Yeni `mound` çizgisi (hendek, toprak sırt, kütük duvar) | 5, Surlu | | 0,5 / 10 m | taş 2, odun 4, dal 10 |
| `rampart_gate`† | Sur Kapısı / Rampart Gate | Sur açıklığı, iki kanat | 6 × 6 | `tower` `gate†` | 5, Surlu | | 1,5† | taş 6, odun 24, ip 4, `iron_bar` 2† |

### 7.7 Ordugâh yapıları

K21 §8.3 ve K24 kimlikleri onaylandı. Çadırlar `CampPlan` kaydıdır (`count`, `seed`, `doneAt`); öteki yapılar şantiyedir.

| id | TR / EN | İşlev | Ayak izi | Görünüm | Ordugâh kademesi | Kapasite | İG | Malzeme |
|---|---|---|---|---|---|---|---|---|
| `tent` | Onluk Çadırı / Ten's Tent | 5 er | r 2,6 | `tent` | Onluk | 5 er | 0,15 | odun 2, sırık 2, ip 4, keçe 3 |
| `cmd_yurt` | Buyruk Yurdu / Command Yurt | Onbaşı-yüzbaşı ve beyin yurdu; atama yeri | r 7,05 | `yurt` `winter`, iç `silah` | Yüzlük | 1 baş ve 9 kişi | 1 | yurt |
| `horse_line` | At Hattı / Horse Line | Binek atı (atlı başına 1) | 20 m | `fence` `picket†` | Onluk | 20 at | 0,08 | odun 6, ip 4 |
| `training_ground` | Talim Alanı / Training Ground | Talim (`army.md` `drill`), hedef direkleri, at yolu | 60 × 30 | `yard` (6 hedef, yol kazıkları) | Onluk | Aynı anda bir Yüzlük | 0,6 | odun 8, saman 4, deri 4, ip 2 |
| `supply_depot` | Erzak Ambarı / Supply Depot | Ordugâh ambarı; birlik `supply`'ı buradan dolar | r 7,05 + yük sekisi 6 × 4 | `yurt` `winter`, iç `bolmeli` + seki | Yüzlük | 600 Yük | 1,5 | yurt + ip 2, odun 8 |
| `armoury` | Silahlık / Armoury | Ok, yay, kılıç; sadak dolumu | r 7,05 | `yurt` `winter`, iç `silah` + raf | Yüzlük | 200 Yük (silah, ok) | 1,2 | yurt + odun 6 |
| `fletchery` | Okçu Yurdu / Fletcher's Yurt | Ok yapımı (§7.5) | r 7,05 | §7.5 | Yüzlük | 3 el | 1,2 | yurt + odun 4 |
| `healer_yurt`† | Otacı Yurdu / Healer's Yurt | Yaralı (`wounded`) iyileşmesi ×2 | r 7,05 | §7.2 | Binlik | 8 yaralı | 1† | §7.2 |
| `watch_tower` | Gözcü Kulesi / Watchtower | | | `tower` | Binlik | | 1,5 | §7.6 |
| `palisade` | Çit Halkası / Palisade | Sefer ordugâhında çevre | 10 m | `fence` `stockade†` | Binlik, sefer | | 0,1 / 10 m | odun 8, ip 1 |
| `banner_pole`† | Sancak Direği / Banner Pole | Birlik başına toplanma | | `post` | Onluk | | 10 İD | §7.6 |
| `outpost`† | Gözcü Konağı / Watch Post | Ova kenarı | | §7.6 | Binlik | | 0,4† | §7.6 |

### 7.8 Taşıtlar

`cart_felt` (II, 60 Yük), `cart_high` (III, 80), `cart_war` (IV, 140): `travel.md` §3.2, `progression.md` §10.3; emek ve malzeme K21, K24. `wagon_felt`† Keçe Göç Arabası (V, Göçer yol, 120 Yük, 4 öküz): 1,2 İG†, tekerlek çifti 2, odun 24, keçe 10, `iron_bar` 4, ip 6†. Taşıtlar şantiyede kurulur (Ağaç Atölyesi'nin yanında), yerleşimin `carts` listesine girer (`progression.md` §13.2).

### 7.9 Görünüm aileleri

Yeni sanat yalnız bunlardır; hepsi `core/geo.js` ile kodla kurulur, köşe renkli, `struct_parts` ve `struct_props` programlarıyla (yeni program yok, §17). Adımlar, can ve sınıf `d2/settlement-delta-structures.md`'dedir.

| Aile | Türler | Parçalar | Üçgen |
|---|---|---|---|
| `yurt` ölçeği | `otag` | `scale: 1,4`: kök ölçeği, nav şekli, oda sınırı, ped birlikte | Yurdun `hero`'su |
| `yard` | `felt_yard`, `tannery`, `barter_ground`, `training_ground` | Düzlük, köşe direkleri, alçak çit, tür donanımı (hasır, çerçeve, tekne, gölgelik, hedef) | ≤6k |
| `mound` | `grain_pit`, `kiln`, `smithy` ocağı, `pit_house`, `rampart` | Kazı çukuru, toprak sırtı (`lathe`/`surf`), kapak ya da çatı | ≤6k; sur parçası ≤1,2k, örnekli |
| `ring` | `well`, `sky_pole`, `gathering_ground` | Taş halka, direk, oturak ya da çıkrık | ≤6k; Toy Alanı oturakları örnekli |
| `post` | `banner_pole`, `lantern_post` | Direk, flama ya da fener | ≤300, örnekli |
| `field` | `field` | Zemin çıkartması + örnekli sap demeti (mevsim boyu) | ≤4k, 1 çizim |
| Hazır ayarlar | `shed` `open` ve `walled`; `tower` `low`, `gate`, `granary`; `fence` `picket`, `stockade`; `tent` | Var olan ağların değişkeni | Var olanın sınırı |

### 7.10 Bakım

Mevsim sınırında (`time.md` §2) ambardan düşer. Ödenmezse yapının en üst havuzu %25 düşer (yapı geri düşmeye başlar, `structures.md` §5.7), konutta hane Gönül −1.

| Sınıf | Mevsim başına | Emek |
|---|---|---|
| Yurt gövdeliler (`yurt`, `store_yurt`, `cmd_yurt`, `envoy_yurt`, `healer_yurt`, `armoury`, `fletchery`, `supply_depot`) | 1 keçe, 1 ip | 0,05 İG |
| `otag` | 2 `felt_white`, 2 ip, 1 `dye` | 0,1 İG |
| `tent` | 1 keçe | 0,02 İG |
| Ahşap yapılar (`stable`, `shed`, `granary`, `granary_tower`, `wood_shop`, `treasury`, `watch_tower`) | 2 odun, 2 saz | 0,05 İG |
| `pen` (40 m), `fence`, `palisade` (10 m) | 6 dal; 1 odun | 0,01 İG |
| `horse_line`, `well` | 1 ip | |
| `felt_yard`, `tannery` | 2 saz, 1 ip | |
| `smithy`, `kiln` | 2 kil; körükte 1 `leather` yılda | |
| `pit_house` | 2 saz, 1 kil | |
| `rampart` (10 m) | | 0,02 İG; sağanaktan sonra 0,05 |
| `gathering_ground`, `sky_pole` | 1 keçe | |
| `banner_pole` | Yılda 1 keçe | |

**Neden bakım.** Hiçbir şey kurulup unutulmaz; keçe yırtılır, ip çürür. Bakım sürekli küçük bir talep yaratır: keçe avlusu ve sepi yeri Tanhu Avlusu'nda da çalışır (K24 malzeme batağı). Toplam bakım IV. kademede günde ≈0,4 İG ve ≈6 keçe/mevsim × 50 yapı: yerleşim emeğinin %1'inden azı.

## 8. Üretim zincirleri ve atölyeler

### 8.1 Yapı → tezgâh → zincir

Tarif, girdi, çıktı ve süreler K24'ündür (`econ-model.json` `recipes`); burada hangi yapının hangi zinciri taşıdığı ve havası.

| Zincir (K24) | Yapı (tezgâh) | Ana tarifler | Usta | Hava (K22, K21 tablosu) |
|---|---|---|---|---|
| Keçe | `felt_yard` | `rc_felt_batch`, `rc_felt_white`, `rc_chiy`, `rc_saddle_felt`, `rc_felt_boots`, `rc_blanket_felt` | | Yağmur ×0,7, sağanak ve sert rüzgârda durur |
| Sepi | `tannery` | `rc_leather`, `rc_hide_patch`, `rc_glue`, `rc_saddle_wood` | | Su ≤100 m; kurutma yağmurda durur |
| İp | El (her yurt) | `rc_rope`, `rc_rope_hair` | | |
| Ağaç | `wood_shop` | `rc_pole`, `rc_door_frame`, `rc_kerege_set`, `rc_uuk_set`, `rc_yurt_crown`, `rc_crown_great`, `rc_wheel_pair`, `rc_saddle_tree` | `cr_carpenter`, `cr_cartwright` | Çatılı: hava etkisi yok |
| Tunç ve demir | `smithy` + `kiln` | `rc_charcoal`, `rc_bloom`, `rc_copper_bit`, `rc_bronze_bar`, `rc_reforge`, `rc_heads_iron`, `rc_cauldron` | `cr_smith` | Kıvılcım: `smithy` rüzgâraltında (§13.2) |
| Ok ve yay | `fletchery` | `rc_shafts`, `rc_heads_bone`, `rc_arrow_*`, `rc_hun_bow` | `cr_bowyer` | |
| Yiyecek | Kazanlı yurt ocağı, `rack` | `rc_meal_batch`, `rc_cauldron_meat`, `rc_qurt_batch`, `rc_dried_batch`, `rc_kumis_batch` | | Sırık yağmurda durur |
| Yem | `stable` | `rc_fodder` | `m_groom` | |
| Yurt yükü | El | `rc_yurt_kit`, `rc_tent_kit` (söküm şantiyede, K21 0,35) | | |
| Tahıl | `field` | Ekim, biçim | `cr_earth` | Dolu tarlayı %30–60 yıkar |

### 8.2 Sürekli emirler

Tezgâh başına bir liste; Kâhya sırayla işler. Biçim: «{n} tut / keep {n}» (ambarda bu kadar kalsın), «{n} yap / make {n}», «durdur / stop».

| Varsayılan (yerleşim kurulunca) | Neden |
|---|---|
| Keçe Avlusu: keçe 20 tut; çiy 2 tut | Bakım ve yeni yurt |
| Ağaç Atölyesi: sırık 8, kapı 1, kerege takımı 1, uuk takımı 1 tut | Hazır yük olmayan hane için |
| Demirci Ocağı: `iron_bar` 4 tut; kömür 10 tut | Yurt kapısı, araba |
| Okçu Yurdu: ordugâh ambarındaki ok 24 × atlı tutulsun (kervanla) | `army.md` §3.6 sadak |
| Sırık: kurut 40, kak 20 tut (yaz ve güz) | Kış yiyeceği |

### 8.3 Mevsim takvimi

K20 saatinin günlük düzeni (`time.md` §10.4) aynen; mevsimlik işler:

| Mevsim | İş | Yerleşime etkisi |
|---|---|---|
| Bahar | Doğum (K24 `growth`), kırkım (`shear.spring`), toz fırtınası (Gobi) | Yün → keçe dalgası; hanenin Gönül'ü doğumla +2 |
| Yaz | Sağım tepesi, kımız, ot biçimi başlar | Yiyecek fazlası kuruta; Toy için kımız |
| Güz | İkinci kırkım, kesim (K24 `sogum`), kak, Dailin Sayımı | Kış ambarı dolar |
| Kış | Onarım, ok ve yay, ağaç işi; kar kabuğu tehlikesi (§15.3) | Yem tüketimi |

## 9. Depolama

### 9.1 Kaplar

Bütün kaplar `Inventory` kap yüzüdür (`architecture.md` §3.13: `{ add, remove, list, load, cap }`, Yük onda bir tamsayı). Kap sınıfı, süzgeç, aktarma ve baskın ile yangın kaybı K24'ündür (`d2/economy.md` §5: `Container`, `Stores.ofPlace(place)`); bu belge kabın hangi yapıda durduğunu ve yerlerin ayrımını verir. Bir yerin kapları tek **Ambar / Store** görünümünde birleşir (`Stores.ofPlace`); eşya, süzgecine uyan ve en yakın boş kaba girer.

| Kap | Süzgeç | Kapasite |
|---|---|---|
| Mete'nin sandığı (Mete'nin yurdu) | Her şey | 60 Yük |
| `grain_pit` | Yiyecek, tahıl | 120; baskında yarı yarıya bulunmaz, yanmaz (K24) |
| `store_yurt` | Her şey | 400 |
| `shed` | `tag:bulk`, `tag:forage` | 500 |
| `granary`, `granary_tower` | Yiyecek | 600, 800 |
| `treasury` | `tag:valuable` | 120 |
| `armoury` | Silah, ok | 200 |
| `supply_depot` | Erzak: yiyecek, yem, ok, yakacak, teçhizat (ordugâhta) | 600 |
| Şantiye yığını | Adımın malzemesi | K21 `site(id)`: türün yükü × 1,25 |

### 9.2 Yer ayrımı

Yerleşim ambarı, ordugâh ambarı ve hazine **ayrıdır**. Aralarında yalnız kervan (§11) ve Mete'nin heybesi taşır; `great_stores` (`progression.md` §4.5, V) Mete'ye her ambardan alma hakkı verir, birliğin günlük çekişini değiştirmez. Şantiye 150 m içindeki bağlı ambardan kendi taşır (K21 §6.3).

### 9.3 Zula ve baskın

Baskının hangi kaptan ne götürdüğü K24 kap tablosudur (`d2/economy.md` §5.1: korumasız Ambar Yurdu ve Tahıl Ambarı %30, Tahıl Kulesi %10, Ambar Çukuru yarı yarıya bulunmaz, ot sundurması yanarsa hepsi). Yerleşim yalnız akının başarısını yazar (§15.4): nöbet, kule, sur. Act I'in «yazılan el konur, saklanan kalır» ilkesi (`economy.md` §0) II. Perde'de çukur kazmak olur.

### 9.4 Defter yüzü

`SupplyLedger` K24'ün ambar kipindedir (`d2/economy.md` §14 `mode: 'store'`): `value(line)` kaplardan günle hesaplanır, `consume` hane payını, Ordu Payı'nı, yakacağı ve yemi düşer. Yerleşim ona hane sayısını, ordugâh nüfusunu ve hedef günleri verir. Böylece `ledger` etkisi (`architecture.md` §3.14) ve K21 `K_tok` aynı yüzden okur.

| Defter | id | Çizgiler | Yüzde |
|---|---|---|---|
| Yerleşim Hesabı / Hold Ledger | `own_seat` | `food`, `fodder`, `fuel`, `arrows` | `min(100, gün / hedef × 100)`; hedef yiyecek 30, yem kışın 100, yakacak 30 gün |
| Ordugâh Hesabı / Camp Ledger | `own_camp`, `field_camp` | Aynı | Aynı, ordugâh nüfusuyla |

### 9.5 Küme tükenmesi

Uzaktaki toplama `NodeStore`'u bellekte istemez: yerleşim küme başına alınan miktarı sayar (`taken[cluster]`). Dünya kurulurken `NodeStore.applyTaken(cluster, n)` kümenin düğümlerini tohumlu sırayla kalıcı (`perm`) ya da günlük (`day`) tükenmiş işaretler (`d2/settlement-delta-architecture.md`). Kesim yeri görünür büyür (`economy.md` §3.5 «kendi emeği manzarayı değiştirir»).

## 10. Ordugâh

### 10.1 Kademeler

Ordugâhta **yerleşik** atlı, Erzak Ambarı'ndan beslenen çekirdektir: yerleşim kademesine göre 10, 100, 200, 400, 600 (K24 `armyRations` × 10, `d2/economy.md` §7.3). Tümenin geri kalanı ve `army.md` §2'nin `drilled` sayısı kendi payında ailesiyledir; talim ve toplantı için gelir, kendi çadırını ve 3 günlük azığını getirir (`tumen_call`). Böylece ordugâh büyük görünür, yerleşimin yükü küçük kalır.

| Kademe | id | TR / EN | Yerleşik atlı | Çadır (5'er) | At hattı | Yapı | Görünüm |
|---|---|---|---|---|---|---|---|
| 1 | `camp_onluk` | Onluk Ateşi / The Ten's Fire | ≤10 | 2 | 1 | Talim Alanı, 1 ateş, sancak | Tam |
| 2 | `camp_yuzluk` | Yüzlük Kampı / The Hundred's Camp | ≤100 | 20 | 5 | + Buyruk Yurdu, Erzak Ambarı, Silahlık, Okçu Yurdu, 10 ateş | Tam |
| 3 | `camp_binlik` | Binlik Ordugâhı / The Thousand's Encampment | ≤400 (toplantıda 1.000) | 80 (+ gelenlerin 120) | 20 | + 10 Buyruk Yurdu, Otacı Yurdu, 2 Gözcü Kulesi, Gözcü Konakları | 40 tam çadır, gerisi `TentField` |
| 4 | `camp_tumen` | Tümen Ordugâhı / The Tumen Encampment | ≤600 (toplantıda 3.000–10.000) | 120 (+ gelenlerin) | 30 | + sancak ovası | `TentField`, T3 kart (`army.md` §7) |

Kademe yerleşik atlıya ve yapıya bağlıdır: Onluk Ateşi Ocak'la, Yüzlük Kampı Oba'yla, Binlik Boy Yurdu ve Toy Yeri'yle, Tümen Tanhu Avlusu'yla gelir. Toplantı ve talim günlerinde gelenlerin çadırı `CampPlan`'a geçici eklenir (en çok 3 gün), azıkları kendilerinindir.

### 10.2 Yapıların ordu eksenlerine etkisi

`army.md` eksenlerinin sahibi `army.md`'dir; aşağıdaki satırlar onun §3.5 olay tablosuna önerilir (§20).

| Etken | Ölçü | Etki | Not |
|---|---|---|---|
| Barınak payı `s` | `min(1, çadır × 5 / atlı)` | Islak gece (yağmur, sağanak, kar, dolu, tipi): `morale −2 × (1 − s)` | Islaklık; soğuk yok (K1) |
| Ateş | 10 atlıya 1 yanan ateş (yakacak K24 `fuelPerRiderDay`) | `morale +1/gün` (`fire_rest`'in uzak özeti) | |
| Erzak Ambarı | Birlik `supply.food` her şafak 3 güne tamamlanır | Tam / yarım / aç gün `army.md` §3.5 | Ambar boşsa birlik kendi `supply`'ından yer |
| Silahlık | Sadaklar ordugâhta 24'e dolar; savaştan sonra %60 toplanır (K24 `recovery`) | `supply.arrows` | |
| At Hattı | Binek atları hatta | Gök gürültüsü ürkmesi: hatlı %0,2, hatsız %2 at dağılır, 2 günde döner (K22 `thunder`) | |
| Seyis (`m_groom`) | Ordugâhta | Kışın `horse_fat` +1/gün | |
| Otacı Yurdu | 8 yaralı | `wounded` günde %15 iyileşir (yoksa %7) | |
| Konfor | `s ≥ 0,9`, tam tayın, ateş | `loyalty +0,3/gün`, tavan 70 | Y17 |

### 10.3 Talim

Mete'nin ıslık talimi (`army.md` §3.5 `drill`, 90 sn tur) asıl kaynaktır ve yalnız Talim Alanı'nda yapılır. Mete yokken **Baş Talimi / Officer Drill**: Talim Alanı olan ordugâhta birlik `discipline` +0,4/gün (`old_hand` ×1,25), tavan 60; `drilled` (ıslığa uyan) yalnız Mete'nin talimiyle artar. Talim saati 07:30–10:30 (`time.md` §10.4); o saatte İş Kolu'ndaki er talim kazanmaz.

### 10.4 Sefer ordugâhı

`army.md` `cmd_camp` → `CampPlan = { site, units, tents: count, seed, fires, lines, depot: 'carts', palisade: bool, doneAt }`. Çadırlar arabalarda `tent_kit` olarak taşınır (K24), her onluk kendi çadırını kurar: konak 2–3 gerçek dakika (K21 §8.3). Erzak Ambarı yerine araba halkası (`wagon_ring`, `progression.md` §4.5) ambar olur. Sökme 0,35 emekle (K21). Seferde bırakılan ordugâh 10 gün sonra kaybolur, malı yağmalanır.

### 10.5 Ordugâhın emeği

Ordugâhın eli erdir (`UnitRec.strength − wounded`, K21 §6.4); kendi yapısını kendi kurar. Bedeli fırsattır: inşaattaki er talim almaz, `fatigue` dinlenmez. Ordugâhın ham malzemesi (keçe, sırık, ip, ok) yerleşimden kervanla gelir: ordunun yerleşime bağımlılığı budur.

## 11. İkmal kervanı

### 11.1 Yol ve araç

| Alan | Değer | Kaynak |
|---|---|---|
| Yol | `r_whistle_ordu` (30 km gösterim): atla 1, arabayla 1, öküzle 2 gün | `travel.md` §9.2 |
| Araç | `cart_felt` 60, `cart_high` 80, `cart_war` 140, `wagon_felt` 120, `pack_camel` 30, `cart_ox` 60 Yük | `travel.md` §3.2 |
| Sürücü | Araba başına bir `haul` işçisi | §6.1 |
| Koruma | Yok, Onluk ya da Yüzlük (ordugâhtan) | |
| Atlas | Seyrede ≤12 minik araba (`travel.md` §10.4) | |

### 11.2 Kervan Buyruğu / Caravan Order

```js
{ id: 'k_army', from: 'own_seat', to: 'own_camp', every: 2,          // gün
  send: { '@army_share': 2, felt: 'keep_to:30', arrow_bone: 'keep_to:2400', tent_kit: 'keep_to:4' },
  back: ['hide', 'horn', 'sinew', 'iron_scrap', 'bronze_scrap', '@booty'],
  escort: 'none' | 'onluk' | 'yuzluk', road: { refugees: 'share', wolves: 'fire' } }
```

- **Ordu Payı / Army Share** (`@army_share`): ordugâh yerleşik atlısı × 0,1 öğün/gün (K24 `depotShare`, `armyRations`): Ocak 1, Oba 10, Boy Yurdu 20, Toy Yeri 40, Tanhu Avlusu 60 öğün/gün.
- **Yol Töresi / Road Custom:** kervanın yol olaylarındaki (`travel.md` §9.6) kendiliğinden seçimi: kaçkınla paylaş (2 öğün, +1–2 hane) ya da geç; kurtta ateş (1 odun) ya da sür (1 öğün).
- Mete kervana katılırsa (atlas bacağı kervanla), olaylar ona sorulur.

### 11.3 Süre, hava, baskın

| Durum | Kural |
|---|---|
| Kalkış | Tan'da (K20); hava `sev` ≥4 (tipi, toz fırtınası, dolu) ise o gün kalkmaz |
| Süre | Yol günü × hava: yağmur ve çamur ×1,25, yoğun kar ×1,5, sert rüzgâr ×1,1 (K22 §8.10) |
| Varış | Yük kaba yazılır; dönüş ertesi Tan |
| Akın | III'ten yol olaylarına (`travel.md` §9.6: sefer başına %25, en çok 1) `ev_raid` «Akın / Raid» eklenir; olaylar içindeki payı III %30, IV %20, V %35, VI %10 (sefer başına ≈%2,5–9). Onluk koruma %60, Yüzlük %90 olasılıkla püskürtür; yol başında Gözcü Konağı payı −%25 |
| Akın sonucu | Korumasız kervan yükün yarısını yitirir (K24 `d2/economy.md` §5.3), bir araba aşama 0 (`structures.md` §4.4), sürücüler döner; varışta kart |

### 11.4 Ne taşınır (beklenen akış)

| Perde | Yerleşimden ordugâha | Ordugâhtan yerleşime |
|---|---|---|
| II | Ordu Payı 20 öğün/sefer (Oba), keçe 6, ok 200, çadır yükü 2 | Deri, boynuz, sinir (av kolları) |
| III–IV | 40–80 öğün, keçe 30, ok 2.000, eyer, araba | Ganimet payı (K24 `bootyToDepot`), demir hurdası, at |
| V–VI | 120 öğün, ok 5.000, zırh, araba | Heqin malı (Hazine'ye) |

## 12. Hanlık merkezi

### 12.1 Avlu yapıları

| Yapı | İşlev |
|---|---|
| Tanhu Otağı | Divan (§12.3); toplantıların başı; kapı doğuya; iç `han` |
| Elçi Yurdu | Elçi heyeti burada konaklar; Tunghu'nun üç isteği (III), Han elçileri (V), heqin |
| Toy Alanı | Toy, Kış Toplantısı, Dailin Sayımı'nın oturağı, Kurultay (VI) |
| Gök Direği | Şafak Selamı, alamet (§12.4) |
| Hazine | Armağan, ganimet payı, Kurultay dağıtımı (`progression.md` §9.2 VI) |
| Sancak Direkleri | Toplantıda beylerin yeri: 24 `wanqi` sancağı (`army.md` §1 #6) |

### 12.2 Toplantılar (S3)

Günler K20 `Calendar.lunarMonth`'tandır (`time.md` §2): Kış Toplantısı 1. ayın yeni ayında, Lung-çeng 5. ayda, Dailin güzün ilk dolunayında. Ordu etkileri `army.md` §1.3'ündür.

| id | TR / EN | Yer | Gerekir | Yerleşime etkisi |
|---|---|---|---|---|
| `muster_winter` | Kış Toplantısı / Winter Muster | Avlu (Toy Yeri+; III'te Otağ önünde) | Otağ, Toy Alanı; 3 gün hane başına 2 öğün + bey başına 3 öğün, kımız 20 | Gönül +5; atama; çekim ×1,2, 10 gün |
| `muster_longcheng` | Lung-çeng Toplantısı / Longcheng Muster | `longcheng` (IV+) | Armağan kervanı: ≥200 öğün, 10 at, Hazine'den değer ≥200 Kıymet | Gönül +3; `army.md` `loyalty` +5 katılan baş |
| `dailin_count` | Dailin Sayımı / Dailin Count | Avlunun güz otlağı (`dailin_ground` parseli) | Toy Alanı; Mete avluda | **Sayım Defteri**: hane, kişi, sürü, at; seferberlik payı; `army.md` yeniden sayımı. Palak'ın sayımının dönüşü: sayan Mete'dir |

**Sayım Defteri / The Count** kartı: «Bin {n}. gün. {h} hane, {p} can, {s} sürü.» / «Day {n}. {h} households, {p} souls, {s} head of stock.» (`time.md` Z16: mutlak gün sayacı).

### 12.3 Divan / Council

Tanhu Otağı'nda `E` «Divan / Council» (yalnız `act>=3`).

| Eylem | TR / EN | Ne yapar |
|---|---|---|
| Huzur | Huzur / Audience | Hanelerin dilekleri: küçük işler (2 keçe, bir kuyu, bir hekim); yapılınca Gönül +3 (o hane), Kut vermez |
| Yargı | Yargı / Judgement | 15 günde bir dava (S9). Hırsızlık: «Malını al / Take his goods» (hanenin sürüsü Hazine'ye, Korku +1, o hane Gönül −10), «Bağışla / Pardon» (öteki haneler Gönül −1), «Sür / Banish» (hane gider). Bıçak çeken: «Kanun / The law» (sahne dışı, Korku +1) ya da «Kefil / A guarantor» (Act I kefil motifi, hane Gönül +5, Kut değişmez) |
| Atama | Atama / Appoint | `army.md` §3.2 `appoint` |
| Armağan | Armağan Gönder / Send Gifts | Hazine'den ≥200 Kıymet; 3 gün sonra 2–4 hane ve o soyun beyine `ties` |
| Elçi | Elçi Kabulü / Receive Envoy | Elçi Yurdu'ndaki heyet: hikâye olayı ya da `ev_envoy` (`travel.md` §9.6) |
| Seferberlik | Ere Çağır / Call to Arms | §5.6 |
| Toy | Toy Ver / Hold a Feast | §5.4 |
| V. kademe yolu | | §4.3, bir kez |

Ceza sahnesi görünmez, sonrası görünür (`act1.md` §1, `army.md` §3.5).

### 12.4 Gök Direği

- **Şafak Selamı / Dawn Bow** (S4): Tan evresinde (`time.md` §4) direkte `E` «Güne Selam / Greet the Sun». Avludaki birlik moral +2, avlu haneleri Gönül +0,5; günde bir. Kut vermez (`progression.md` §5.1 farm yok). Akşamı aya selam yoktur: tek eylem.
- **Alamet / Omen.** Gök gürültülü ya da kuru fırtınada direk zonun en uzun yalnız şeyidir (12 m, ağaçsız tepe). K22 vuruşu buraya inerse (`weather.md` H12 kuralı) perde başına bir kez: `kut ≥ korku` ise «Gök gördü / Heaven saw» Kut +1, değilse «Gök kızdı / Heaven raged» Korku +1 (`axisOnce`). Direk yanar (`ignite`, meşale 70), yeniden dikilir (§7.10).
- Ozan dörtlüğü alameti okur.

### 12.5 Hazine

Hazine malı Kıymet'le sayılır (`economy.md` §9.1), Defter'de yalnız terazi görünür (sayı yok). Girer: heqin malı (`silk_bolt`, `wine_jar`, `grain_sack`), ganimetin Tanhu payı, takas kârı, Yargı'nın el koyması. Çıkar: Armağan, `booty_share`, Lung-çeng kervanı, Kurultay dağıtımı. Baskında ilk hedeftir; Gözcü Kulesi 30 m içindeyse kayıp ×0,5.

### 12.6 Kurultay (VI kancası)

Toy Alanı'nda; dağıtımın kendisi oy toplar (`progression.md` §9.2), Kut ≥20 +1 oy (§5.2). Hazine'nin dağıtılan payı ve hanelerin ortalama Gönül'ü hikâye alanına girdi verir. Kurallar VI. Perde'de yazılır.

## 13. Yerleşim kuralları

K21'in genel kuralı (`labour.md` §6.2: kapalı hücre yok, başka yapının duvarına ≥4 m, yola ≥3 m, izdeki ağaç ve kaya önce kesilir) taban kalır; yerleşim aşağıdakileri ekler. Denetim saf `validatePlacement`'in (K21 `game/site-core.js`) `rules` girdisiyle yapılır: bu belge kural tablosunu verir (`d2/settlement-model.json` `placement`).

### 13.1 Parseller

| Parsel | Merkezden | Türler |
|---|---|---|
| `core` | ≤40 m | `otag`, `envoy_yurt`, `gathering_ground`, `treasury`, `banner_pole`, `lantern_post`, Mete'nin yurdu |
| `dwell` | 40–200 m | `yurt`, `tent`, `hut`, `store_yurt`, `grain_pit`, `rack`, `well`, `healer_yurt`, `pit_house`, `lantern_post`, `banner_pole` |
| `work` | 100–280 m, rüzgâraltı ±60° | `felt_yard`, `tannery`, `wood_shop`, `smithy`, `kiln`, `fletchery`, `shed`, `granary`, `granary_tower`, `barter_ground` |
| `pen` | 150–400 m, suya ≤250 m | `pen`, `fence`, `stable`, `horse_line`, `shed` |
| `field` | Taşkın kuşağı ve dere düzlüğü | `field`, `shed` |
| `sacred` | `sacred_hill` | `sky_pole` |
| `wall` | Sur hattı (Surlu yol: 110 × 90 m, çevre 400 m) | `rampart`, `rampart_gate`, `watch_tower` |
| `edge` | Zon kenarına ≤60 m | `watch_tower`, `outpost` |
| `camp`, `drill` | Ordugâh dünyaları | §7.7; `training_ground` yalnız `drill` |

### 13.2 Kurallar

| Kural | Değer | Neden |
|---|---|---|
| Eğim, konut (`yurt`, `otag`, `tent`, `hut`, `pit_house`) | ≤6° (`normal.y ≥ 0,9945`) | Ped 0,175 m + kenar eğimi r 7 m'de ≈0,73 m farkı örter (`structures.md` §11.3); K21'in 0,9'u pedsiz küçük yapılar içindir |
| Eğim, ahşap ve avlu | ≤9° | Direk çukuru toleransı |
| Eğim, çizgiler (`pen`, `fence`, `horse_line`, `rampart`, `palisade`) | Parça başına ≤15° | |
| Su | Konut ≤150 m (dere, pınar, kuyu) | Aşılırsa izin var, Gönül −0,3/gün |
| Taşkın kuşağı | Konut uyarı («Taşkın yatağı / Flood plain»), sağanakta aşama 0–1 yapı zarar görür | K22 sağanak |
| Ateş payı | Duvardan duvara ≥4 m sert (K21), <8 m uyarı «Ateş payı dar / The fire gap is tight» | `structures.md` §6.2: `R = 10 + rüzgâr` merkezden; r 7 yurtlar 22 m merkezde ancak sert rüzgârda (≥12 m/sn) tutuşur |
| Rüzgâraltı | `smithy`, `kiln`, `tannery`: konuta ≥40 m ve hâkim rüzgârın (`weather.md` §4.4) altında ±60°; değilse uyarı ve Gönül −0,2/gün | Duman ve koku |
| Kapı | Yurt 120° ±45° (güneydoğu, kuzeyden); Tanhu Otağı 90° ±10° (doğu) | Gelenek; S4 doğan güneş |
| Yol | Ana yol (4 m) ve kapı yolları korunur | |
| Bağlantı | Geçici damgadan sonra ocak, her kapı ve iki zon kapısı tek bileşende kalmalı (`labelComponents`); kalmazsa «Yolu kesiyor / It blocks the way» | Kendini hapseden yerleşim olmaz |
| Sayı | Zon başına ≤160 yapı kaydı; aynı anda ≤48 canlı `StagedStructure` (yakın, şantiye, hasarlı); gerisi `YurtField` ve `KitField` | §17 |

### 13.3 Görünür yapı bütçesi ve LOD

| Uzaklık (kamera hedefinden) | Yurt | Öteki | Not |
|---|---|---|---|
| ≤40 m, en yakın 4 | `winter` (Otağ `hero`) | Tam | Hasar, yanık, iç mekân |
| 40–220 m | `YurtField`: örnekli `closed` (3k), örnek başına `aCut` (yapım yüksekliği) ve `aChar` (yanık) | `KitField`: tür başına örnekli kaba ağ (≤400 üçgen) | 1 + 1 çizim |
| >220 m | `YurtField` uzak kubbe (96 üçgen) | Yok | Sis örter |
| Şantiye | Yakındaysa tam; uzaksa `YurtField` `aCut` ile yarım yükselen kubbe | | Yarım yurt uzaktan yarım görünür |

### 13.4 `WorldSpec` alanı

```js
// world/specs/tanhu-ordu.js (Faz 13)
settlement: {
  kind: 'hold',                                   // 'hold' | 'camp'
  hearthSites: [{ id: 'hs_terrace', at: [-80, -120], name: { tr: 'Seki', en: 'The Terrace' }, traits: { water: 45, flood: 0, wind: 1 } }, /* hs_bend, hs_lee */],
  plots: { /* hearthSite id → [{ kind: 'dwell', ring: [40, 200] } …] önceden kırpılmış çokgenler */ },
  sacred: { id: 'sacred_hill', at: [-420, -470], r: 6 },
  water: [{ kind: 'brook', pts: [[-700, -300], [-80, -150], [160, 60], [700, 150]], flood: 25 }],
  wind: { dir: [0.71, 0.71], ms: 4 },             // hâkim rüzgâr K22'den; burada yalnız yerleşim kuralı için
  clusters: ['c_elm_bend', 'c_willow_brook', /* … §3.2 */],
  gates: ['gate_ordu_w', 'gate_ordu_e'],
  dailin: { at: [380, 300], r: 160 },
  limits: { records: 160, live: 48 },
},
weather: { climate: 'steppe_south' },  light: { lat: 43.5 },  labour: { torchFree: false },
```

## 14. Arayüz

### 14.1 Plan Kipi / Plan Mode

- **Tuş `P`** (`build_mode` eylemi, boş; TR «Plan», EN «Plan»). Yerleşim ya da ordugâh dünyasında açılır; başka yerde toast «Burada yurdun yok.» / «You hold no ground here.»
- **Bağlam** `plan` girdi yığınında (`architecture.md` §3.2): Q / E 15° döndürür (Shift ile 5°), tekerlek yakınlaşır, sol tık yerleştirir, sağ tık ya da `Esc` iptal, `Tab` kategori. Bağlam tuşları yuttuğu için Q (silah, `cmd_call`) ve R (`cmd_loose`) çakışmaz; K21'in önerdiği `keymap.rotate` (R) plan bağlamında Q/E olur.
- **Kamera** `plan` ön ayarı: pitch 50°, dist 64 (40–120), imleci yumuşak izler (`game.cam.push('plan', …)`).
- **Alt şerit** (`ui/hud/plan-bar.js`, yuva `bc`): kategoriler Konut, Sürü, Ambar, Atölye, Avlu, Savunma, Ordugâh. Kart: ad, işlev, malzeme (var / gerek renkli), emek («1 iş günü · 4 elle akşam biter» / «1 work-day · with 4 hands, done at dusk»), bakım, kapasite; kilitliyse nedeni.
- **Önizleme**: yerleştirilecek türün `KitField`/`YurtField` ağı, renk uniform'u (yeşil, sarı, kızıl); parsel katmanı yere çıkartma. Nedenler (en çok 3): «Yer düz değil» / «The ground is not level», «Suya uzak» / «Far from water», «Taşkın yatağı» / «Flood plain», «Ateş payı dar» / «The fire gap is tight», «Duman yurtlara gider» / «The smoke will drift over the yurts», «Yolu kesiyor» / «It blocks the way», «Burası {parsel} değil» / «This is not {plot} ground».
- **Çizgiler** (ağıl, çit, at hattı, sur): sürükle; parça yakalama (2 m, 2,2 m, 10 m, 20 m); canlı maliyet.
- **Yerleşince** K21 şantiyesi doğar (`sites.place`); Kâhya ekip ve taşımayı başlatır.
- **Sök** (`Delete` ya da kart düğmesi): K21 §6.9; yurt yurt yüküne döner.
- Saat Plan Kipi'nde akar (K20); durdurmak için `Esc` kitabı.

### 14.2 Yerleşim Defteri / Hold Ledger

Kitap sayfası `hold` (`registerPage`, `architecture.md` §3.20), `L` Defter'in yeni sekmesi. Ordugâhta aynı sayfa ordugâhı gösterir; üstte yer seçici «Yurdun / Your Hold» · «Ordugâh / Encampment». Açıkken oyun durur (`progression.md` §14.1).

| Bölüm | İçerik |
|---|---|
| Özet / Overview | Ad ve kademe; hane (yurtta / çadırda), can; yiyecek, yem, yakacak günü; Gönül ipi; Çekim işareti; «Yolda bir hane var» / «A household is on the road» |
| Halk / People | Kökene göre hane; ustalar; seferberlikte olanlar |
| İş / Work | Altı iş: sayı, + / −, kilit; Kâhya aç-kapa; işin günlük çıktısı |
| Ambar / Stores | Kategori çubukları ve eşya ızgarası; kap doluluğu |
| Sürü / Herds | Baş, at eşdeğeri, çoban kapsamı, otlak günü (`economy.md` §8.4) |
| Yapılar / Buildings | Şantiye ve yapı listesi (K21 §6.11 satırları), öncelik, gece emri, bakım borcu |
| Kervan / Caravans | Buyruklar, yoldaki arabalar, son kartlar |
| Kademe / Tier | Sonraki kademenin «gerekir» satırları işaretli |

Kut ve Korku sayı göstermez; Gönül düğüm, Çekim dört kademe; hane ve gün sayıdır.

### 14.3 HUD, atlas, bildirim

- Yer adı: «Tanhu Ordusu · Oba» (`hud.setPlace`).
- Atlas: yerleşim `yurt` simgesi, ordugâh `ordu` simgesi (`travel.md` §9.5 `ICONS`), kervan minik araba.
- Ses (`d2/settlement-delta-audio.md`): müzik `hold`, `hold_night`, `court`, `muster`; döngüler `hold_day`, `herd_flock`, `camp_army`, `gathering_crowd`; efektler `plan_place`, `plan_rotate`, `household_arrive`, `caravan_depart`, `tier_up`, `dawn_bow`, `omen_strike`, `assembly_drum`. Tezgâh sesleri K24'ün, şantiye sesleri K21'indir.
- Kısa bildirim (en çok 1/30 sn): «Yeni bir hane geldi.» / «A new household has arrived.»; «Kervan Islık Alanı'na vardı.» / «The caravan has reached the Whistle Field.»; «Akıncılar sürüye dadandı.» / «Raiders have fallen on the herds.»; «Ambar doldu: {kap}.» / «The store is full: {store}.»

### 14.4 Kademe kartları

| Kademe | TR | EN |
|---|---|---|
| Ocak | «Ocak yandı. Burası artık senin.» | «The hearth is lit. This ground is yours now.» |
| Oba | «On ocak, bir oba.» | «Ten hearths make a clan camp.» |
| Boy Yurdu | «Soyun burada oturur.» | «Your lineage sits here.» |
| Toy Yeri | «Beyler bu yere gelir.» | «The lords come to this ground.» |
| Tanhu Avlusu | «Avlu kuruldu. Bozkır buraya bakar.» | «The court stands. The steppe looks here.» |

## 15. Zaman, emek, hava bağları

### 15.1 Saat (K20)

| Olay (`time.md` §12.2) | Yerleşim |
|---|---|
| `clock:hour` | Kâhya dağıtımı; tezgâh ve toplama saati; kervan konumu; ordugâh ateşi |
| `dawn` | Tüketim, sürü (sağım çıktısı, kayıp), çekim, katılım, ayrılış, Gönül, defter |
| `clock:phase` | Şafak Selamı penceresi; iş penceresi |
| Mevsim sınırı | Bakım, doğum, kırkım, kesim |
| `clock:skip` | Saat saat toplu işler, §18.2 sırasıyla (Kâhya, K21 `simulate`, K24 tezgâh, ordugâh, kervan); 12 saatlik atlama ≤8 ms |
| Atlas yolculuğu | Varışta aynı toplu işlem; yerleşim Mete yokken büyür (K23) |

Yerleşim durumu yolculuk kaydındadır, hangi dünya yüklü olursa olsun her `clock:hour`'da işler; yüklü değilse görünüm yoktur, emek ve üretim vardır.

### 15.2 Emek (K21)

Bütün iş gücü İG ile sayılır (bir yetişkin bir oyun gününde 1 İG; açık hava işi geceyle ortalama ×0,8, K24 `outdoorK`). Şantiye `SiteSystem`'indir; yerleşim yalnız hangi işçinin hangi şantiyede olduğunu verir (`assign`). `K_tok` yerleşim defterinin `food` çizgisinden. Ustalar §5.2.

### 15.3 Hava (K22)

Hava kimlikleri ve olasılıkları `weather.md`'nindir; bu tablo yerleşimin ve ordugâhın tepkisidir. Şantiye tepkisi K21 §5.2'dedir. Soğuk ve sıcaklık yoktur (K1).

| Hava | Yerleşim | Sürü | Kervan | Ordugâh |
|---|---|---|---|---|
| Sis | Nöbet görüşü ×0,5: baskın sürprizi | Kurt kaybı ×1,5 | | |
| Çisenti, yağmur | Keçe ve sırık K21 tablosu; ıslak keçe sıçrama ×0,5 (`structures.md` §6.2) | Otlak ×0,9 | ×1,25 | Islak gece `morale` (§10.2) |
| Sağanak | Taşkın kuşağında aşama 0–1 yapı −20 can; dere kabarır | | ×1,5 | |
| Gök gürültülü, kuru fırtına | Uzun iş durur; yıldırım adayı: Gök Direği, kuleler, Tahıl Kulesi, yalnız ağaç | At ürkmesi (§10.2) | ×1,5 | At ürkmesi |
| Dolu | Tarla −%30–60; çadır keçesinde yırtık olasılığı %10 | Kuzu kaybı %0,5 | Kalkmaz | |
| Sert rüzgâr | Sıçrama `R = 10 + 16`: 26 m; kazıksız çadır %10 bir aşama düşer; Sundurma'dan ot −%5 | | ×1,1 | |
| Kar, yoğun kar | | Otlak ×0,8, ×0,5; yem tüketimi K24 `fodder.deep` | ×1,25, ×1,5 | |
| Tipi | Dış işler durur | Ağılsız sürü %1/gün | Kalkmaz | |
| Toz fırtınası (Gobi, bahar) | Dış işler durur | Otlak ×0,7 | Kalkmaz | İki ordugâhın baharı |
| **Kar Kabuğu / Snow Crust** (koşul, kış) | Yoğun kar ya da tipiden sonra çözülme ve donma: 5–10 gün | Otlak ×0,3, yem tüketimi `deep`; yem yoksa sürünün %2'si/gün | | Kış ordugâhında `horse_fat` −2/gün |

**Kar Kabuğu** Moğolca *zud*'un oyun adıdır: bozkırın asıl kış felaketi soğuk değil, otu örten buzdur. Kâhya'nın güz yem hedefi (§6.2) buna hazırlıktır. Hava alanına koşul önerisi: `snow_crust` (kış, `heavy_snow` ya da `blizzard` ardından gündüz `ground` ıslaklığı >0,5 ve gece donma); alt olay değil, zon durumudur.

### 15.4 Baskın

| Perde | Yerleşime tehdit (zon başına) | Kaynak |
|---|---|---|
| II | Yok (Teoman'ın barışı); hikâye dışında | |
| III | Tunghu yenilene dek 12 günde 1 | `donghu_land` |
| IV | 30 günde 1 (Ordos boyları katılmadan) | |
| V | 40 günde 1 | |
| VI | Yok | |

Savunma `D = nöbetçi × (1 + 0,5 × kule) + garnizon`; akın gücü `R` perde tablosundan; başarı olasılığı `R / (R + D)`, Surlu yolda ×0,5. Başarılı akında kap kayıpları K24 kap tablosudur (§9.3); sürü kaybı %≤10 (Göçer yolda ×0,6); çadır ve sundurma tutuşabilir. Mete zondaysa baskın oynanır (`act1.md` baskın sistemleri: `raid.js`, `fxFlames`, `ignite`); değilse toplu çözülür, kart gelir.

## 16. Kayıt

**`settlement` bloğu** (yolculuk, order 77, sahibi `game/settlement/index.js`). Yapılar ve şantiyeler `world.sites.zones.tanhu_ordu`'dadır (K21, order 76); kaplar, sürü, yoldaki kervan ve defter K24'ün `economy` bloğundadır (`d2/economy.md` §16: `stores`, `herds`, `caravans`). Bu blok onları tekrarlamaz.

```jsonc
"settlement": {
  "v": 1, "zone": "tanhu_ordu", "hearthSite": "hs_terrace", "tier": 2, "path": null, "lastMin": 1503330.0,
  "hh": "<base64: hane başına 8 B: id 2, köken 1, kaynak 1, Gönül 1, giriş günü 2, bayrak 1>",
  "masters": [["h07a0", "cr_smith", 1.25]],
  "jobs": { "auto": true, "lock": { "herd": [4, 8] }, "codes": "<base64: işçi başına 1 B iş kodu>" },
  "pull": 0.37, "inbound": [[1503.4, "pull", "xiongnu", 1]],
  "orders": { "felt_yard": [["keep", "felt", 20]] },
  "caravans": { "orders": [/* §11.2: buyruk, koruma, yol töresi */] },
  "taken": { "c_elm_bend": 214, "c_quarry": 37 },
  "court": { "lastCase": 1490, "omenAct": [3], "gifts": ["huyan"] },
  "flags": { "hearth_ember": "father" },
  "stats": { "joined": 9, "left": 0, "raids": 1, "built": 14 }
}
```

**`camps` bloğu** (order 92, sahibi `game/settlement/camps.js`).

```jsonc
"camps": { "v": 1,
  "own_camp": { "zone": "whistle_field", "tier": 2, "units": ["u_hundred_mete"], "plan": { "tents": 20, "lines": 5, "fires": 10, "seed": 9041, "doneAt": 1498.6 },
                 "drillDay": 1503, "comfort": { "s": 1, "fed": true } },
  "field_camp": null }
```

| Kural | Değer |
|---|---|
| Boyut | `settlement` ≤10 KB (90 hane × 8 B = 0,7 KB; işçi kodu 300 B; kervan ve emir ≤2 KB), `camps` ≤4 KB; `world.sites.zones.tanhu_ordu` ≤16 KB (K21) |
| Toplam | Tavanların toplamı (`army` 37, iki dünyanın `world.sites`'ı 2 × 16, bu iki blok 14, öteki ≈25 KB) 108 KB'dir, 96'yı aşar. Beklenen ≈66 KB: `army` ≈20, `world.sites` yerleşimde ≈6,4 KB (160 sıkı yapı × 40 B), ordugâhta ≈2 KB (çadırlar `CampPlan`), Kışlak ≈3 KB, bu iki blok ≈10, öteki ≈25. Öneri (K21'e): `world.sites` tavanı yerleşimde 8, ordugâhta 4 KB; sınama 160 yapı ve 90 haneyle tam yolculuğu ≤96 KB tutar |
| Kaydedilmez | Kişi kimliği (haneden türer), görünür işçi, kervan kuklası, tezgâh ilerlemesinin saniyesi (saat başına yuvarlanır) |
| Oto kayıt | Kademe yükselişi (`settlement`), kervan varışı, yol seçimi (`force`) |
| Göç | `v` arttıkça `migrate[v]`; bilinmeyen alan korunur; bozuk blok: hane ve sürü korunur, işler Kâhya'ya döner |
| Perde geçişi | `act_change(n)` bloğa dokunmaz (`progression.md` §15'e satır) |

## 17. Performans

**Kare.** Yerleşim ve ordugâh oyun dünyasıdır (Kışlak gibi): hedef ≤28 ms, `spec.postCuts: true`. Menü bitişiğinde değildir: `menuDiff` etkilenmez.

| Avlu, V. kademe, en kötü kare | Ana üçgen | Çizim | Kaynak |
|---|---|---|---|
| Arazi 14×10 parça, yakın 3×3 | 290k | 14 | `act1.md` §15 |
| Mete + ghost, tam at ≤2 | 158k | 46 | Aynı |
| `Folk` ≤16, kukla ≤40 (`NpcManager.budget` ortak) | 342k | 50 | Aynı; şantiye ve tezgâh işçisi buradan |
| Yapılar: Otağ `hero` ≤129k + 3 `winter` yurt 102k + `YurtField` 60 × 3k + uzak 80 × 96 + `KitField` 40k + ağıl panoları | ≈460k | ≈22 | §13.3 |
| Bitki (dere ağaçları, çalı) | 200k | 12 | Kışlak ormanından az |
| Sürü: örnekli koyun ≤300 × 360, at T1/T2 ≤60 | ≈130k | 3 | `army.md` §7.3 T2 sözleşmesi |
| Kaya, düğüm, ot | 300k | 30 | |
| Etki, post | 40k | 21 | |
| **Toplam** | **≈1,92M ≤2,04M** | **≈198 ≤213** | |

| JS | Tavan |
|---|---|
| Yerleşim saati (`clock:hour`, 150 sn'de bir) | ≤0,5 ms (90 hane, 300 işçi, 40 tezgâh) |
| Kare başına | ≤0,1 ms (yalnız görünür işçi ve sürü konumu; sürü y 5 Hz) |
| 12 saatlik atlama | ≤8 ms (karartma altında; K21 şantiye ≤0,3 ms/gün) |
| Bir mevsim atlama (90 gün) | ≤150 ms, yükleyicide |
| `YurtField` yazımı | Değişince; kare başına 0 |

**Program.** Yeni anahtarlar: `yurt_field` (+ derinlik), `kit_field` (+ derinlik), `plan_ghost`, `plot_decal`, `field_stalk`: +7 (≤92 tavanı içinde; kışta `_w` ile ≤100). Görünüm aileleri (§7.9) `struct_parts`, `struct_props` kullanır, program eklemez. Çalışma zamanında ışık eklenmez: fener, ateş, meşale `fxGlow` ve köşe rengidir.

**Bellek.** Yerleşim durumu ≤200 KB (hane, işçi, kap); dünya kurulurken `YurtField` örnek tamponu 160 × 64 B.

## 18. Uygulama taslağı

### 18.1 Modüller

| Dosya | Saf | İş |
|---|---|---|
| `src/data/settlement.js` | Evet | `TIERS`, `BUILDINGS` (§7: tür, görünüm, kademe, parsel, kapasite, bakım, önkoşul), `SOURCES`, `PLACEMENT`, `CAMP_TIERS`; `d2/settlement-model.json` ile aynı |
| `src/game/settlement/state.js` | Evet | `SettlementState`: hane, kişi kaydı, iş kodu, çekim, Gönül, kademe, yol; saat adımı |
| `src/game/settlement/households.js` | Evet | Katılım, ayrılış, seferberlik, yenilenlerin seçimi |
| `src/game/settlement/steward.js` | Evet | Kâhya: ihtiyaç, öncelik, kilit; çıktısı ekip listeleridir: K21 şantiyesi (`sites.assign`), K24 tezgâhı (`Workshop.crew`), sürü kapsamı (`Herd.day` `labourIS`), toplama kolu |
| `src/game/settlement/caravan-orders.js` | Evet | `CaravanOrders`: buyruk, koruma, yol töresi, akın; K24 `Caravan` örneklerini kurar ve sürer |
| `src/game/settlement/raids.js` | Evet | Yerleşim akını: tehdit, savunma, başarı payı; kayıp K24 kap kuralıyla |
| `src/game/settlement/camps.js` | Evet | `CampState`: kademe, konfor, talim, `CampPlan` |
| `src/game/settlement/court.js` | Evet | Divan, toplantılar, alamet, Hazine |
| `src/game/settlement/index.js` | Hayır | `SettlementSystem` (GameSystem `settlement`, order 64, kip `play`) |
| `src/game/settlement/plan.js` | Hayır | Plan Kipi: `plan` bağlamı, önizleme, `sites.place` |
| `src/world/settlement-view.js` | Hayır | `YurtField`, `KitField`, parsel çıkartması, sürü örnekleri |
| `src/ui/hold-ledger.js`, `src/ui/hud/plan-bar.js`, `src/ui/css/hold.css`, `src/i18n/strings/settlement.js` | | Defter sayfası, Plan şeridi, metinler |
| `src/world/specs/tanhu-ordu.js`, `src/world/specs/whistle-field.js` | | II. Perde dünyaları (Faz 13) |

**K24 modülleri kullanılır, yenisi yazılmaz** (`d2/economy.md` §14): `Container` ve `Stores.ofPlace` (kap ve ambar görünümü), `Workshop` (tezgâh saati), `Herd` (sürü günü, kırkım, doğum, soğum), `SupplyLedger` ambar kipi (tüketim, Ordu Payı, defter çizgileri), `Caravan` (araba, yük, varış), `loot` (ganimet). K21'in `SiteSystem`'i şantiyeyi sürer. Yerleşim bunlara **kimin, nerede, ne kadar** çalıştığını ve **kaç hane, kaç atlı** olduğunu verir.

### 18.2 Arayüzler

```js
// game/settlement/state.js (saf)
export class SettlementState {
  constructor({ data /* data/settlement.js */, econ /* K24 tabloları */, labour /* game/labour.js */, rng });
  zone; tier; path; households; work; pull; lastMin;      // sürü K24 Herd'tedir: herds(place)
  hour(env);                      // env: { minute, phase, season, weather, act, kut, korku, threat }; → olay listesi
  dawn(env);  seasonEnd(env);
  catchUp(toMin, envAt, sites);   // saat saat: sites.simulateZone(zone, 60) sonra hour(); envAt(min) → env
  tierCheck(act, built);          // → { tier, missing: [...] }
  join(src, n, opts);  leave(id, reason);  levy(householdId, unitId);  returnLevy(unitId);
  workers();                      // → [{ id, role, w, crafts, job }] (haneden türer)
  assign(job, target, n);  lock(job, min, max);  setAuto(on);
  toJSON();  fromJSON(o);
}

// game/settlement/index.js
export class SettlementSystem {   // GameSystem: id 'settlement', order 64, modes ['play']
  attach(ctx);                    // ctx.settlement; bus: clock:hour, dawn, clock:skip, structure:done, site:done, site:dismantled
  onWorld(world, nav);            // spec.settlement varsa görünüm ve plan; yoksa yalnız saat
  update(dt, t);                  // görünür işçi ve sürü; plan kipi
  collectInteractions(q, out);    // Ambara Koy / Store, Ambardan Al / Take, Divan / Council, Güne Selam / Greet the Sun, Toy Ver / Hold a Feast
  openPlan();  closePlan();
  hold;  camps;                   // SettlementState, CampState
  debug();
}
```

**Saat sırası.** `clock:hour`: (1) `SettlementState.hour`: Kâhya ekipleri yazar (şantiye, tezgâh, sürü, toplama kolu, nöbet, sürücü); (2) K21 `SiteSystem` şantiyelerin o saatini işler (yüklü dünyada zaten kare kare işledi); (3) K24 `EconomySystem` tezgâhları ve toplama kolunu işler; (4) `CampState.hour`; (5) `CaravanOrders.hour` (K24 `Caravan.tick`). `dawn`: K24 tüketim ve sürü, sonra `SettlementState.dawn` (çekim, katılım, ayrılış, Gönül, kademe). Atlamada aynı sıra saat saat (`catchUp`). Olay sırasına güvenilmez: Kâhya'nın yazdığı ekip, değişene dek şantiyede ve tezgâhta kalır; K24 `economy` (order 102) ve K21 `sites` (61) o anki ekiple çalışır. En kötü durum bir saatlik gecikmedir (2,5 gerçek dk), toplamı değiştirmez.

### 18.3 Sistem ve kayıt sırası

| `order` | `id` | Modül | Kip |
|---|---|---|---|
| 61 | `sites` | `game/sites.js` (K21) | ikisi, home |
| 64 | `settlement` | `game/settlement/index.js` | play |

| Blok | `order` | Sahip |
|---|---|---|
| `world.sites` | 76 | K21 |
| `settlement` | 77 | `game/settlement/index.js` |
| `camps` | 92 | `game/settlement/camps.js` |

### 18.4 Var olan koda dokunuşlar (sonraki fazlar)

| Dosya | Değişiklik |
|---|---|
| `src/world/structure-defs.js` | §7.9 yeni türler ve hazır ayarlar; `yurt` `scale` alanı |
| `src/world/structure.js` | Uzak yurdu `YurtField` yuvasına devretme (`closed` örneği), `aCut`; `scale` ile nav, oda, ped; ≤48 canlı yapı |
| `src/world/site-pad.js` | Hafif ped (`PadField`, örnekli; camp3'ün 512² tuvali yalnız camp3'te) |
| `src/game/nav.js`, `game/structure-nav.js` | `canPlace(shapes)`: geçici damga ve bileşen denetimi, geri al |
| `src/world/node-store.js` | `applyTaken(cluster, n)` |
| `src/core/keymap.js` | `build_mode: ['KeyP']` (`CONTRACT-REQUEST`) |
| `src/app/systems.js` (L) | `SettlementSystem` (64), `ctx.settlement` |

## 19. I. Perde'de şimdi, sonra

K23: I. Perde altyapıyı ve geliştirici kum havuzunu kurar, hikâye II. Perde'de açılır. K21 şantiyeyi (`8.9`, `8.10`, kum havuzu `?state=play&sandbox=site`), K24 malzeme ve kapları kurar; bu alan şunları ekler (paket numaraları `L`'nindir):

| Ne | Faz | Dosyalar | Bitti |
|---|---|---|---|
| Yerleşim çekirdeği (saf) | 8 | `data/settlement.js`, `game/settlement/{state,households,steward,caravan-orders,raids,camps,court}.js`, `test/settlement.test.js` | §21 saf sınamalar |
| Kum havuzunun yerleşim kipi | 9 | `?state=play&sandbox=site&hold=1` (yalnız geliştirme, K21 kum havuzunun dünyası): 3 Ocak Yeri, düğüm kümeleri, 10 hane, ambar dolu | Plan Kipi ile 20 yurt; ×60 saat; kaydet, yükle |
| Plan Kipi, `YurtField`, `KitField`, parsel kuralları | 9 | `game/settlement/plan.js`, `world/settlement-view.js`, `ui/hud/plan-bar.js` | 200 rastgele yerleşimde bağlantı kopmaz; yapay V. kademe (80 hane) karesi §17 tablosu içinde |
| Yerleşim Defteri iskeleti, kervan saplaması (kum havuzunda iki uç) | 10 | `ui/hold-ledger.js`, `game/settlement/index.js` | Defter her bölümü dolu; kervan saatle gider |
| II. Perde dünyaları ve hikâye | 13+ | `specs/tanhu-ordu.js`, `specs/whistle-field.js`, `story/act2/*` | II. Perde kapsamı |

I. Perde içeriği yerleşimi kullanmaz; Kışlak Yeni Yurdu K21'in şantiyesidir. Ana kampın Serbest Gez'i değişmez (K6, K3, menü karesi).

**Gizli panel `__tanhu.hold`.** `give(item, n)`, `households(n, origin)`, `tier(n)`, `speed(k)` (saat ×1–×240), `hour(n)`, `place(kind, x, z, rot)`, `assign(job, n)`, `steward(on)`, `raid(power)`, `weather(id)` (K22 yerel denemesi), `caravan(orderId)`, `census()`, `budget()` (§17 sayaçları), `plots(on)`, `synth(tier, path)` (yapay yerleşim).

## 20. Mevcut belgelerde değişecekler

`architecture.md`, `structures.md`, `audio.md`: birebir metin `d2/settlement-delta-architecture.md`, `d2/settlement-delta-structures.md`, `d2/settlement-delta-audio.md`. Ötekiler (sahibi birleştirir):

| Belge | Bölüm | Değişiklik |
|---|---|---|
| `act1.md` | §16 Bayraklar | Yeni satır: «`first_ten[]`, `ties.*`, `names_known`, `tola_lives`, `saved[]` · II: yerleşimin ilk haneleri (`d2/settlement.md` §5.3)» |
| | §16 Sistem kancaları | «`StagedStructure` II'de Teoman'ın ordusu» → «… II'de Mete'nin yerleşimi ve ordugâhı (K23, `d2/settlement.md`)» |
| `army.md` | §1.3 Takvim | `muster_winter` yeri: «II'de Teoman'ın avlusu (`tanhu_camp`, atlas sahnesi), III'ten `tanhu_ordu`»; `dailin_count`: «avlunun güz otlağı (`dailin_ground`)»; günler `time.md` §2 |
| | §3.5 Olaylar | Yeni satırlar §10.2: barınak, ateş, konfor, Baş Talimi |
| | §3.6 Ordugâh | «`structures.md` §15 `CampPlan`» → «`d2/settlement.md` §10, `CampPlan` K21 §8.3» |
| | §9 Kayıt | «`army` ordugâhı taşımaz; `camps` bloğu (order 92)» |
| | §11.2 Sonra | `cmd_detail`, `cmd_camp` satırına «yerleşim ve ordugâh: K23» |
| `economy.md` | §4.4 Depolar | Yeni satırlar §9.1 kapları; «Ambar Çukuru baskında yarı yarıya bulunmaz» (K24 §5.1) |
| | §6.4 Diğer yapılar | Başa: «II. Perde ve sonrası yapı kataloğu `d2/settlement.md` §7» |
| | §8.3 | `SupplyLedger('own_camp')` ordugâhın defteri olur; yerleşimin defteri `own_seat` (§9.4); «Ordu Payı» §11.2 |
| | §8.4 | Yerleşim sürüsü otlak hesabına girer (hane başına ≈18 at eşdeğeri) |
| | §9.3 | Takas Yeri'nin gezgin satıcıları (III+) |
| `d2/economy.md` (K24 taslağı) | §8.3, `econ-model.json` `tiers` | Kademe adları ve bileşimi §4.1–§4.3 (Boy Yurdu, Toy Yeri, Tanhu Avlusu; Surlu ve Göçer yol; Elçi Yurdu, Gök Direği, Takas Yeri, Gözcü Konağı, Hazine, Otacı Yurdu, Fener ve Sancak Direği, Sur Kapısı, Keçe Göç Arabası) benzetime girer; «hane Sadakati» → **Gönül** (§5.4); ordugâh yerleşik atlısı §10.1 |
| `travel.md` | §1.3 | `tanhu_ordu` adı: II «Mete'nin Payı / Mete's Allotment», III+ «Tanhu Ordusu / The Tanhu's Ordu»; oynanan alan 1400×1050 m; `whistle_field` 1400×1050 m |
| | §9.2 | Öneri `r_ordu_donghu` (`tanhu_ordu` – `donghu_land`, ≈22 km, III); `r_tanhu_hangai` IV'ten kereste kervanı |
| | §9.6 | Yol olayları kervanda «Yol Töresi» ile kendiliğinden çözülür |
| | §9.7, §10.4 | İkmal kervanı (§11): atlas simgesi, `party` köprüsü |
| | §11 | Kervan buyrukları `settlement.caravans.orders`'ta, yoldaki kervan K24 `economy.caravans`'ta |
| `progression.md` | §4.3 | Usta rolleri yerleşimde de iş görür (§5.2): `m_quarter` ambar kaybı −%25, `m_groom` ordugâh, `m_custom` toplantı |
| | §4.5 | `great_stores`: her ambardan alma (yalnız Mete); `provisioner` ordugâhın günlük çekişine de |
| | §5.3 | Yeni satırlar: «Gök alameti (Gök Direği), perdede bir: Kut +1 ya da Korku +1»; «Divan'da el koyma: Korku +1» |
| | §13.2 | Şemaya `settlement`, `camps` |
| | §15 | «Yerleşim ve ordugâh perde geçişinde aynen sürer» |
| `survival.md` | §3 | Kazanlı yurt ocağı `kitchen` tezgâhıdır (K24) |
| `decisions.md` | | Değişiklik yok (K23 satırını `L` yazar) |

## 21. Test planı

**Saf (`test/settlement.test.js`).**
1. Veri bütünlüğü: her `BUILDINGS` satırının türü `STRUCTURE_DEFS`'te ya da §7.9 yeni tür listesinde; `bom` kimlikleri K24 `items`'ta; emek K21 `labour-model.json`'da ya da † listesinde.
2. Kademe: §4.1 «gerekir» satırları; `act` kapısı; kademe düşmez.
3. Çekim: tohumlu 100 gün, §5.3.1 tablosu ±%5; `foodK`, `roomK` sıfırları.
4. Katılım kaynakları ve yurt yükü payları; yükü olmayan hane çadır ister.
5. Gönül değişimleri ve eşikleri; ayrılış: Kut ≥14'te yalnız kıtlık.
6. Esir yok: `join` ganimet yolundan çağrılamaz; `loot` tablosunda insan yok; yenilenlerin seçimi formülü.
7. Kâhya: sıra, kilitler, boştakiler; çoban kapsamı.
8. Tüketim: hane 4,3 öğün; mevsim yakacağı; Kar Kabuğu'nda yem `deep`.
9. Akın: tehdit tablosu, savunma, başarı olasılığı, Surlu ×0,5, Göçer sürü ×0,6; kap kayıpları K24 sınamasındadır.
10. Kervan: kalkış, hava çarpanı, varış, akın tohumu ve püskürtme, yol töresi.
11. Ordugâh: barınak payı, ıslak gece morali, konfor sadakati, Baş Talimi tavanı 60.
12. Toplantılar: `lunarMonth` günleri (sahte takvim); Dailin sayım kartı.
13. Yerleşim kuralları: eğim, su, taşkın, ateş payı, rüzgâraltı, kapı açısı, parsel (sahte arazi).
14. Atlama eşdeğerliği: 720 dk toplu `catchUp` = 12 × 60 dk ±1e−6 (şantiye dahil).
15. Kayıt: gidiş dönüş; 90 hane ve 160 yapıyla `settlement` ≤10 KB, `camps` ≤4 KB; bozuk blok kurtarma.
16. Küme: `applyTaken` belirlenimli.

**Tarayıcı (kum havuzu).** 20 yurt Plan Kipi'yle; 200 rastgele yerleşim, bağlantı kopmaz; `synth(5, 'walled')` ve `synth(5, 'moving')` karesi §17 tablosu (`__tanhu.hold.budget()`); program ≤92; ×240 hızla 10 gün: Kâhya, kervan, baskın; kaydet, yükle aynı.

**Denge (K24 `tools/econ-sim.mjs`).** `settlement-model.json` ile: kademe günleri K24 `targetDays` içinde; oyuncu dakikası `targetPlayerMin` içinde; yaz yiyecek kapsamı ≥1, kış ambarla ≥0,95; perde başına baskın kaybı ≤%10.

## 22. Doldurulan boşluklar

1. Yerleşim ve ordugâhın yeri; zon adı perdeye göre.
2. Ocak Yeri seçimi (üç aday) ve babanın közü.
3. Kademe adları, gerekleri, açtıkları, tavanları, çekim tabanları.
4. V. kademe yol seçimi (Hanshu 94A tartışması).
5. Hane kaydı (kişi kimliği, roller, yaşlının işi, çocuğun dışarıda kalması).
6. Katılım kaynakları, çekim formülü, yurt yükü payları; yenilenlerin seçimi.
7. Gönül ekseni, ayrılış, seferberlik.
8. Kâhya ve altı iş.
9. Fener Direği ve gece işinin yerleşim bedeli.
10. Dokuz yeni yapı (Elçi Yurdu, Gök Direği, Hazine, Sancak ve Fener Direği, Otacı Yurdu, Takas Yeri, Gözcü Konağı, Sur Kapısı) ve Keçe Göç Arabası.
11. Bakım tablosu.
12. Ambar ayrımı ve yer kimlikleri, akının başarısı (kap kaybı K24'ün), küme tükenmesi.
13. Ordugâh kademeleri, konfor, Baş Talimi, sefer ordugâhı.
14. Kervan buyruğu, Ordu Payı, yol töresi, baskın.
15. Divan eylemleri ve davalar (S9).
16. Gök Direği: Şafak Selamı ve yıldırım alameti.
17. Toplantıların yerleşim yüzü; Dailin'in yeri.
18. Kar Kabuğu (zud) koşulu.
19. Yer kuralları ve parseller; LOD ve `YurtField`.
20. Plan Kipi tuşu ve bağlamı; Yerleşim Defteri bölümleri.
21. Kayıt blokları ve boyut hesabı.

## 23. Açık sorular

(2026-11-04, E6: yedi sorunun hepsi kapandı. Bu taslak izdir; sorular soru olarak kalmaz, kapanışları aşağıda her satırın sonunda ve `settlement.md` §23'tedir.)

1. **Hikâye (II. Perde yazarı):** Mete'nin payı `tanhu_ordu` ve Teoman'ın avlusu `tanhu_camp` (II) kabul mü? Mete'nin anasının hanesi ilk ocağa gelir mi? (K23, K37, K41 ve K47 ile kapandı: pay `tanhu_ordu`'dur; Teoman'ın avlusu II'de yalnız sinemadır, `tanhu_camp` Mete için sahnesiz konaktır; Mete'nin anasının hanesi Lan Hatun'unkidir ve ilk ailelerle gelir: Şiuşun, Ruodi, Lan Hatun.)
2. **Zaman:** perde başına geçen oyun günü (çekim ve kademe hızı buna bağlı). Varsayım: II ≈25, III ≈30, IV ≈40, V ≈40, VI ≈60 gün. (K25 ve K42 ile kapandı: II 12, III 12, IV 14, V 12, VI 16 gün ±%30 yalnız tasarım ölçüsüdür; perde son görevle biter, sayaç yoktur; Çekim perde başına tavanlıdır.)
3. **K21:** † emek önerileri (Elçi Yurdu 1, Gök Direği 0,6, Hazine 1,2, Otacı Yurdu 1, Takas Yeri 0,5, Gözcü Konağı 0,4, Sur Kapısı 1,5, Keçe Göç Arabası 1,2); yerleşim fenerinin gece ışığı sayılması. (K21 ve K50 ile kapandı: sekiz öneri `labour-model.json` v3'ün `settlement` bloğuna aynı İG ve adım tablosuyla girdi; fener K21 gece ışığının kaynağıdır, `structures.md` §2.4.)
4. **K24:** † malzeme listeleri; `ember_pot` eşyası; `@army_share` ölçüsü; Yem Bağı'nın yükü (`army.md` 1 Yük, `economy.md` 2 Yük) birleşmeli. (K24 ile kapandı: † malzemeler `econ-model.json` v3 `structures`'ına aynı sayılarla girdi; `ember_pot` K24'ün 23 yeni kimliğindendir (Köz Kabı / Ember Pot); Ordu Payı yerleşik atlının düz %10'udur; Yem Bağı 2 Yük.)
5. **K22:** `snow_crust` koşulu; Gök Direği'nin yıldırım adaylığı kuralı (12 m, yalnız). (K22 ile kapandı: Kar Kabuğu `weather.md` §5.9'un sıra kuralıyla oluşur, 5–10 gün sürer; Gök Direği 12 m'dir, ağaçsız tepede zonun en uzun yalnız şeyidir, `weather.md` §8.7; `d2/core.md` §7 W3, W7, S15.)
6. **V. kademe yolu** bağlayıcı mı (tek seçim), yoksa Göçer Avlu sonradan Sur'a geçebilir mi? Öneri: tek seçim. (K23 ile kapandı: tek seçimdir, geri alınmaz; `mq5_wall_or_wheel`, 20–21 Kasım 201.)
7. **Ocak Yeri'nin üç adayı** Faz 13 arazi yazımında üç ayrı parsel kümesi ister; yazım maliyeti kabul mü? Değilse yalnız Seki. (K57 ile kapandı: Seki, Dirsek ve Kuytu kalır, «Üç Ocak Yeri»; gerçek yol ağıyla uzaklıkları Godot'da `tanhu_ordu` pişirilirken ölçülür: Yol Haritası: `settlement-measure`.)

## 24. Doğrulama durumu ve kaynaklar

- **Okundu:** `decisions.md`; `architecture.md` §0, §1, §3.5, §3.7, §3.8, §3.11–§3.14, §3.16, §3.17, §3.20, §3.22, §5, §7, §8; `army.md` bütünü; `economy.md` §0–§4, §6, §8–§10, §12–§14; `travel.md` §0–§3, §7–§12; `structures.md` §0–§4, §6, §7, §10, §11, §13–§17; `progression.md` §4.3, §4.5, §5, §9–§13, §15; `act1.md` §1, §2, §9, §15–§17; `groups-research.md` §1, §3–§5; `audio.md`; d2: `labour.md`, `labour-model.json`, `econ-model.json`, `economy.md` (§0, §5, §7.3, §8.1–§8.3, §14, §16), `time.md`, `weather.md` §0–§5, delta dosyalarının başlıkları. Kod: `structure-defs.js` (bütün), `structure-logic.js` (kurulum, `advance`, `deliver`), `builders.js` (`HELP`, `workRate`), `keymap.js`.
- **Betikle hesaplandı** (geçici dizinde): §4.2 kademe emek toplamları, §7 yapıların 1/2/4/8 el süreleri, §5.3.1 çekim tablosu, hane çobanlık payı (K24 sürüsü ve `herderPer`).
- **Kaynaktan doğrulandı (2026-11-02):** Shiji 110 ve Hanshu 94A satırları (zh.wikisource); Ivolga ölçüleri, sur ve hendek, konut, zanaat, tarım, halk ve tarih (ru.wikipedia, Davydova ve Kradin'e dayanır).
- **Hesap, koşulmadı:** §17 bütçe satırları (`act1.md` §15 ve `structures.md` §13 ölçümlerinden toplama), §16 boyutları, kervan akışı, baskın oranları.
- **Yapılmadı:** kod, arazi, tarayıcı ölçümü; Ocak Yeri koordinatları gerçek nav ile sınanmadı.

**Kaynaklar.**
- [Shiji 110, Vikikaynak](https://zh.wikisource.org/wiki/史記/卷110)
- [Hanshu 94A, Vikikaynak](https://zh.wikisource.org/wiki/漢書/卷094上)
- [Иволгинское городище, Vikipedi (Rusça)](https://ru.wikipedia.org/wiki/Иволгинское_городище); [Ivolga archaeological site, Wikipedia](https://en.wikipedia.org/wiki/Ivolga_archaeological_site)
- İç: `groups-research.md` §5 (Sanjiaocheng, Wang Jianxin), `economy.md` §15 (Terelj demiri, otlak), `army.md` §14.
