---
title: Açık Dünya ve Görevler
order: 20
status: kismen
summary: 'Oyun tutsaklıktan itibaren açık dünyadır ve kademeli açılır: I. Perde 1.400×1.050 m''lik vadide altı günlük, saatli, kısıtlı bir rehineliktir; II''den görevlere gidilir, her perde açılış, üç kol, kapanış ve son görevdir; perde son görevle biter, sayaç yoktur (K40, K42, K43).'
sources:
  - docs/design/decisions.md
  - docs/design/story.md
  - docs/design/act1.md
  - docs/design/travel.md
  - docs/design/progression.md
  - docs/design/settlement.md
  - docs/design/time.md
  - docs/design/d2/core.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
  - docs/research/oyun-seviye-tasarimi.md
---

## Özü

Oyun Mete'nin tutsaklığından itibaren açık dünyadır ve kademeli açılır ([K43](/docs/source/design/decisions#k43)). I. Perde kısıtlıdır: altı gün, 1.400×1.050 m'lik bir vadi, saatle yürüyen bir rehinelik; duvar yoktur ama her bölge bir kefil ister. Perde bitince Mete kendi yerleşimini ve ordugâhını kurar, iç haritalar arasında atlasla gider, görevlere giderek ilerler: görev kişiden, yerden ya da olaydan gelir, yolu oyuncu seçer. Perde son ana görevle biter, sayaç yoktur ([K42](/docs/source/design/decisions#k42)). Menüden girilen Serbest Gez ayrıdır: orada oyuncu kampın çocuğudur.

> [!NOT]
> «Oyun Metenin tutsaklığından itibaren açık dünya olacak ve gta rdr Witcher Diablo tarzı görevlere giderek senaryoyu ilerleteceğiz»

> [!NOT]
> «Tabi yerleşim yeri veya askeri kamp kurmadan önce act 1 deki tutsaklık perdesini bitirmemiz gerekecek yani act 1 den önce bazı şeylerin kısıtlı olması lazım, act 1 bittikten sonra daha özgür bir açık dünya olacak»

Tasarım iki notu birlikte karşılar. Dört oyun görev kalıbının örneğidir: Witcher 3'ün üç ipucu perdenin üç koluna, RDR2'nin bölüm başına görev sayısı perde ölçeğine, GTA V'in girişten sonra açılan haritası I. Perde'den sonra açılan dünyaya, Diablo IV'ün paralel kolları ana zincire ders oldu ([oyun-seviye-tasarimi.md §1](/docs/source/research/game-and-level-design#1-ornek-oyunlar)). Dünya 75.000 km²'dir ve yürünmez: oynanan yerler elle kurulmuş iç haritalardır, aralarında atlas vardır ([K40](/docs/source/design/decisions#k40)). Yerleşim ve ordugâh I. Perde'den sonradır ([K23](/docs/source/design/decisions#k23)).

## Perde perde ne kadar açık

Takvim tek sayaçtır; perdeler takvimde başlar. Ölçü günü K25'in bütçesidir ve yalnız tasarım ölçüsüdür: oyunda okunmaz, ana görev zamanla kapanmaz. Bir perde ≈420 gerçek dakika sürer, uyku ve bekleme atlanır ([K42](/docs/source/design/decisions#k42), [d2/core.md §4.10](/docs/source/design/d2/core#4-10-kronik-k25)).

| Bölüm | Takvim | Ölçü günü (oyunda okunmaz) | İç haritalar | Serbestlik |
|---|---|---|---|---|
| [I. Perde](/docs/story/act-1) | 2–7 Aralık MÖ 210 | 6 hikâye günü | Kışlak vadisi | Rehine: vadiden çıkılmaz, vakit çağırır, bölge kefille açılır. Ana yol ≈3 sa 40 dk, tüm içerik ≈5 sa 10 dk |
| Serbest Gez | 11 Nisan MÖ 209'dan akan takvim | Sınırsız | Ana kamp (Göl Obası), 88×69 m yürünür | Çocuk: görev yok, tehdit yok, yol kapalı |
| [II. Perde](/docs/story/act-2) | 1–15 Haziran MÖ 209 | 12 | Mete'nin Payı, Islık Alanı | Açık dünya; yerleşim, ordugâh ve yoldaş partisi açılır |
| [III. Perde](/docs/story/act-3) | 1 Eylül–1 Ekim MÖ 208 | 12 | + Tunghu Yurdu | Sefer; 17–25 Eylül yürüyüşü hikâyeyle atlanır |
| [IV. Perde](/docs/story/act-4) | 1 Haziran MÖ 205–22 Eylül MÖ 203 | 14 | + Kışlak (yaz), Lung-çeng, Ordos | İki dilim, arada iç Kronik; önce Kışlak'a dönüş |
| [V. Perde](/docs/story/act-5) | 20 Kasım–1 Aralık MÖ 201 | 12 | + Mayi, Baideng | Kış seferi ve kuşatma |
| [VI. Perde](/docs/story/act-6) | 1 Haziran MÖ 198–9 Eylül MÖ 174 | 16 | + Hangay; seçmeli Dingling Yurdu, Loulan | Beş yıl dilimi, aralarında iç Kronik |

## I. Perde'nin kısıtları

**Rehine vadiden çıkmaz.** Uzak yol kapalıdır: «Rehine vadiden çıkmaz.» Yerleşim ve ordugâh yoktur (K23). Rehineye silah verilmez: oyuncak yay, Gün III'te akşam geri alınan ödünç yay, Gün IV'te yaysız bir sadak. Seviye tavanı 5, stat tavanı 7; Yay ve Buyruk dalları kilitlidir.

**Bölge kapıyla değil insanla açılır.** Vadide 14 bölge vardır. Kefil çeteleyi ikiye böler, yarısı sende kalır. Son gece yarımı sahibinin ocağına bırakırsan borç kapanır; bırakmazsan ceza ona kesilir.

| Rütbe | Güven | Gün tabanı | Açılan |
|---|---|---|---|
| 0 | 0 | I | Kışlak, Esir Çukuru (tayın işi) |
| 1 | Farnak'ın çetelesi | I | Ak Otlak, Buz Geçidi çevresi, Yar Dibi Taşlığı |
| 2 | 25 | II | Kara Yamaç, Buz Kolu, Sazlık (ilgili çeteleyle) |
| 3 | 45 | III | Demir Diş, Adak Ağılı, Eski Kurganlar (ilgili görev ya da çeteleyle) |
| 4 | 70 ya da Av görevi | IV | Yukarı Ağıllar, Kara Tepeler, Ayna Göl, Kuzey Düzü, Kemik Boğazı'na bakış |

| Kefil | Veriliş | Açtığı | Çetele bırakılmazsa |
|---|---|---|---|
| Farnak | Gün I, İlk Çetele | Ak Otlak | Adını yitirir, Nanay rehin kalır |
| Ardokşa | Gün II, 3 iş ve Güven ≥20 | Kara Yamaç, balta | Anahtarlarını yitirir |
| Kantu | Gün II, Kırık Tekerlek | Buz Kolu, Sazlık, Menzil ağı | Arabasını yitirir |
| Atşo | Gün III, Ocağın Nöbeti | Adak Ağılı (ot işi), Eski Kurganlar | Ateş görevini yitirir |
| Amaga | Gün IV Toy, Güven ≥70 | Gece izni | Kurulda itibarını yitirir |

**Yumuşak sınır.** Duvar yoktur. Bölge kenarı Kızıl Kazık hattıdır. Çetelesiz geçince 40 sn sayaç işler (çömelik ve el çanda 120 sn), sonra Kazık Atlısı gelir: 3 sn kararma, Kantu'nun arabasıyla geri, Güven −2, eşya gitmez. Bu yüzden gizlice her yere gidilir; bedel Güven'dir.

**Saat çağırır.** Günün vakitleri saatlidir. Vakit, penceresinin başında çan ve sesle çağırır, sonundan 30 oyun dakikası önce bir kez daha çağırır; penceresinin sonuna varıp başlamadıysa oyuncuyu 3 sn karartmayla yerine götürür. Saat durmaz, erken biten bekler. Günün ana işi uykuyu açar: bitmeden döşek «Bugünün işi bitmedi» der. Vakitlerin dışındaki saatler serbesttir.

**Kısıtlı ama açık (K43).** Perdenin sayıları ve saatli vakitleri değişmez; açıklık hissi veriyle gelir. Görevler'deki (`J`) «Bugün» listesi serbest saatte en az 3 iş gösterir. Kilit kişiyle yazılır: kapalı bölge kefilinin adını söyler. Her Bakış Noktası'ndan en az 2 kapalı bölge görünür. Her kilitli bölgede Kazık hattına yakın bir Kaçak Ödül durağı vardır: bilgi ya da mal verir, XP vermez. 23 yan görevin en az 8'i yol üstünde tetiklenir ([act1.md §2](/docs/source/design/act1#2-oyun-dongusu-ve-eksenler)).

**Yol.** Vadi içinde Menzil ağı ve Kantu'nun arabası vardır: ücret 1 Aş ya da 1 odun, Yolu Kısalt 3 sn. Gün V'te yalnız yaralı seferi kalır, Son Gece hat kapalıdır.

## I. Perde'den sonra açılanlar

| Açılan | Ne zaman | Ne verir |
|---|---|---|
| Uzak Yol ve atlas yolculuğu | II; Mete'nin denetimi Tanhu Kampı'ndan Islık Alanı'na giden bacakta başlar | Keşfedilen iç haritalar arasında gitmek |
| Yerleşim ve ordugâh (K23) | II, Kendi Ocağın görevinden sonra | Plan Kipi, Yerleşim Defteri, iş ataması, kervan |
| Serbest Dolaşım | Her perdenin son görevinden sonra | Mete'nin kendi işini seçtiği kip; takvim akar |
| Yoldaş partisi | II | En çok 10 yoldaş ([Yoldaşlar](/docs/gameplay/companions)) |
| Kâhya | II | İş Tahtası'nın yerini alır: işi oyuncu verir, halk yapar; II–IV Lan Hatun, V'ten Yimo |
| Yay ve Buyruk dalları | II | Kendi yayın, birlik buyrukları |
| Ordu | II | 10.000 unvan, 10 talimli atlıyla başlar ([Ordu](/docs/gameplay/army)) |
| Gecelik Kamp | II, Kendi Ocağın'dan sonra | Açık arazide tek gecelik çadır ve ateş ([K46](/docs/source/design/decisions#k46)) |
| Bütün hava türleri | II'den | Kışlak'ta yağmur, dolu, gök gürültüsü yoktur (K22) |
| Ozan'a Anlattır | II'den, perde başına 2 hak | Mete'nin ocağının ozanının ateşinde stat ya da beceri puanını taşır |

I. Perde Ev sahnesiyle biter. Ev'den sonra serbest dolaşım yoktur: 11 Nisan–1 Haziran 209 doğrudan Akan Kronik'tir (K42). II. Perde yazılana dek kart «II. Perde yakında» der, kayıt korunur, menüye dönülür (K7).

## Serbest Gez

![Ana kampın vadisi: Serbest Gez'in dünyası](/media/docs/research/cam-shots/ref-valley-after.png)

Serbest Gez ilerleme değildir: XP, stat, beceri, Tokluk ve yara yoktur, kaydı ayrıdır. Oyuncu kampın çocuğudur: oluşturulan yetişkin değil Çocuk yürür, kampta Mete yoktur (K6, [K37](/docs/source/design/decisions#k37)). Takvim oyununkiyle aynıdır (K67): kayıtlı saat yoksa 11 Nisan MÖ 209, 14:46,2'de açılır; Godot'nun gece menüsünden bu ikindi ışığına 2,4 sn süzülerek geçilir ([K76](/docs/source/design/decisions#k76)). Mevsim akar: 15 Mayıs'ta yaz, 23 Ağustos'ta güz tonu, 16 Kasım'da kar örtüsü gelir; menüye dönünce görünüş menünün karesine döner. Küçük döngüsü dal toplamak, oyuncak yayla karga ve tavşan vurmak, üçüncü yurdun ustalarına yarım el olarak katılmaktır. Güney patikasındaki arabanın sürücüsü baharda «Geçitler daha karla kapalı; yaz gelsin.» der, yazın ve güzün babanın iznini, kışın karı anar (K9). Haritada başka yere yakınlaşınca «Serbest Gez'de yol kapalı.» yazar.

Doğrulanacak: açılışın 2,4 sn'lik süzülmesi, güz ve kış görünüşü ve menüye dönünce görünüşün menü karesine dönmesi ekran görüntüsüyle sınanır ([Yol Haritası](/roadmap#item-roam-calendar)).

## İç haritalar ve atlas

75.000 km²'lik harita yürünmez. Vadi 1,47 km²'dir, haritanın %0,002'si: haritayı bu boyutta doldurmak 51.020 iç harita ister. Oyun bu yüzden iki kademelidir: iç harita içinde gerçek yolculuk, iç haritalar arasında atlas. Atlas bacağında dünya kurulmaz, inilmez; olaylar kart olarak gelir, saat varışta atlar. Gerçek süre 10–30 sn'dir. Tanhu Kampı sahnesiz bir konaktır: yollar orada zincirlenir, Mete inmez ([K41](/docs/source/design/decisions#k41)); III'ten adı «Eski Avlu»dur. Mete'nin Payı da III'ten «Tanhu Ordusu» adını alır.

![Atlas](/media/docs/research/atlas-shots/before_full.png)

| Yol | Uzunluk | At / araba / öküz | Gerçek süre | Açılış |
|---|---|---|---|---|
| Hexi Kışlağı – Tanhu Kampı | 63,6 km | 2 / 3 / 4,5 gün | 24 sn | Ev sahnesi; II–III'te Hexi yönü kapalı, IV'te ucu yazın Kışlak'tır |
| Tanhu Kampı – Islık Alanı | 36,2 km | 1 / 1,5 / 2,5 gün | 17 sn | II |
| Islık Alanı – Mete'nin Payı | 30,0 km | 1 / 1 / 2 gün | 16 sn | II |
| Tanhu Kampı – Tunghu Yurdu | 73,1 km | 2 / 3 / 4,5 gün | 26 sn | III |
| Tanhu Kampı – Lung-çeng | 4,3 km | 0,5 / 0,5 / 0,5 gün | 10 sn | IV |
| Tanhu Ordusu – Ordos | 36,4 km | 1 / 1,5 / 2,5 gün | 17 sn | IV |
| Ordos – Kışlak | 48,0 km | 1,5 / 2,5 / 3,5 gün | 20 sn | IV |
| Tanhu Ordusu – Mayi | 25,9 km | 0,5 / 1 / 2 gün | 14 sn | V |
| Mayi – Baideng | 8,3 km | 0,5 / 0,5 / 0,5 gün | 10 sn | V |
| Tanhu Kampı – Hangay | 13,7 km | 0,5 / 0,5 / 1 gün | 11 sn | VI |
| Tanhu Kampı – Dingling Yurdu | 42,3 km | 1,5 / 2,5 / 4 gün | 19 sn | Seçmeli |
| Kışlak – Loulan | 44,7 km | 1,5 / 2,5 / 4 gün; deve 2 | 19 sn | Seçmeli |

- **Yolun durumu.** Yol gizli, söylenti, keşfedilmiş ve hat durumlarından geçer. Söylenti olan yola Keşfe Çık ile gidilir: bedel iki katı, bir yol olayı kesin. Bir günden uzun seferde en çok bir yol olayı %25 olasılıkla gelir. Her yeni iç harita en az bir geliş ve 3–8 keşif durağı getirir ([travel.md §9](/docs/source/design/travel#9-uzak-yollar-atlas)).
- **Haritadan oyuna.** Yüklü iç haritada en yakın düzeyde harita kapanır, kamera 1,6 sn'de oyun kamerasına karışır, oyun sürer; M'ye basmak gerekmez. Başka yere yakınlaşma 6 birimde durur: tık, yol biliniyorsa Yol Kartı'nı açar, bilinmiyorsa «Bu yol henüz açılmadı.» yazar. Işınlanma yoktur ([K40](/docs/source/design/decisions#k40), [Harita ve Ölçek](/docs/world/map)).
- **Anlatıcı (K84).** II'den her Uzak Yol'un ilk geçişinde anlatıcı tek cümle söyler (İngilizce, en çok 80 karakter, Türkçe altyazılı); sonraki geçişler sessizdir ([K84](/docs/source/design/decisions#k84)).

## Görev yapısı

**I. Perde.** Görevler kişilerden ve yerlerden alınır, her seçim aynı perdede yankılanır.

| Tür | I. Perde | Nasıl başlar | Ödül | Kural |
|---|---|---|---|---|
| Ana görev | 22 görev, 2.460 XP | Öncekinin bitişi, saatli vakit | XP, Güven, rütbe, bazıları beceri puanı | Günün ana işi uykuyu açar |
| Yan görev | 23 görev, 1.580 XP | Kişi, yer, koşul; en az 8'i yol üstünde | XP, Kut ya da Korku, beceri ustası | Her biri aynı perdede yankılanır |
| İş Tahtası | 7 tür, 405 XP | Her gün | +3 Güven, +25 XP; türün ilki +4 Güven, +40 XP | Hikâye gününde 3 iş sayılır; 2 iş tam kase |
| Keşif | 5 Bakış, 8 Menzil: 130 XP | Varış, onarım | Başına 10 XP | Bir kez |

Yalnız ana yol ve işler seviye 4'te biter (2.865 XP); bir yan görev ve keşifle seviye 5 gelir. Hepsine yetişilmez: Son Gece ≈50 dakikalık içeriği ≈32 dakikaya sıkıştırır. İş Tahtası'nın yedi işi Odun, Nöbet Ateşi, Taş, Buz Suyu, Sürü, Ot Taşıma ve Cevher'dir ([I. Perde: Gün Gün](/docs/story/act-1-days)). **Yankı örneği:** Sürüde Kurt'ta dişi kurdu bırakırsan Kut +1 alırsın, uluması atlıları 8 sn önce haber verir; vurursan Korku +1 ve Kurt Postu alırsın, kurtlar sana saldırır.

**II'den: kalıp (K43).** Her perde bir açılış, aynı anda açılan üç kol, bir kapanış ve son görevdir. Kolların sırası serbesttir; biri bitince ötekilerin satırı değişir. Her kol en az bir kez yerleşim ya da ordugâh dışına çıkarır. III–VI'nın ilk oynanan görevi Dönüş'tür: Mete kendi yerinde yürür, değişen 3–5 kişi ve yapı görür. İki istisna tarihindir: II'nin ıslık sınamaları bir merdivendir (av, kendi atı, sevdiği, Tanhu'nun atı, Tanhu; iki sınama arası en az iki gün), VI'nın kolları yıl dilimlerine bağlıdır.

- **Görev verici ve iğne.** Görev üç kaynaktan gelir: kişi, yer, olay. Ana görev `J`'de iç haritayı ve kişiyi yazar, yolu oyuncu seçer. Yan görev önce söylentidir: haritada 160 m'lik soluk bir halka, varınca kesinleşir. Harita baştan ikonla dolmaz. Satır nedeni söyler: «Bu yolu Guşi bilir.» Elmas işaret Hikâye'de hep, Normal'de 45 sn yol kaybından sonra görünür, Zor'da yoktur.
- **Zaman.** Ana görev zamanla kapanmaz. Tarihli göreve erken gelinirse tarih kapısı saati tablodaki güne atlatır; geç gelinirse sahne yılı ve mevsimi söyler. Vakit çağrısı yalnız takvim olaylarında kalır ve karartmayla götürmez: kaçırılan olay Kronik'te «sensiz yapıldı» olur.

| Perde | Ana görev | Yan görev | XP'li durak | Yeni iç harita | Seviye | Beceri puanı veren | Son görev |
|---|---|---|---|---|---|---|---|
| II | 12 (4 + 3×2 + 2) | 5 aile × 3 | ≈12 | 2 | 6–8 | Islığı Yap, Tanhu'nun Atı | Av, 14 Haziran 209: ok Teoman'ı gösterir |
| III | 13 (2 + 3×3 + 2) | 5 × 3 | ≤8 | 1 | 9–11 | Boş Toprak, Dailin | Yenilenlerin Seçimi, 1 Ekim 208 |
| IV | 14 (2 + 3×3 + 3) | 5 × 3 | ≈12 | 3 | 12–14 | Çukur, Batı Yolu | Ordos'ta Dailin, 22 Eylül 203 |
| V | 12 (2 + 3×2 + 4) | 5 × 3 | ≈12 | 2 | 15–17 | Yalandan Kaçış, Yedi Gün | Bir Köşe, 1 Aralık 201: halkanın bir köşesi açılır |
| VI | 14 (2 + 3×3 + 3) | 4 × 3 | 8–12 | 1–3 | 18–20 | Kurultay | Son Dailin, 9 Eylül 174 |

Perdenin ≈420 dakikalık payı: ana zincir ≈180, yan görevler ≈105, keşif ve yol ≈45, yerleşim, ordu ve av ≈70, kamp ve sinema ≈20 dk. Görevler perde perde [story.md §11](/docs/source/design/story#11-ii-vi-perdeler)'dedir ([K43](/docs/source/design/decisions#k43)).

| Yan görev ailesi | Bağlandığı sistem | Tetik | Ödül | Perdeler |
|---|---|---|---|---|
| Hane | Gönül, Kâhya | Hane isteği, sığınan, Al Karısı | Gönül, Çekim, usta | II–VI |
| Yol | Yol olayı, Menzil, Taş Yığını | Yol, kervan, söylenti | Atlas adı, açılan yol | II, IV |
| Av | Av döngüsü | İz, sürü zararı, yavru | Malzeme, ilk av XP'si, Destan dizesi | II–VI |
| Ordu | Talim, moral | Onluk sorunu, kaçak | Refleks, moral, er | II, III, V |
| Töre | Kut, Korku, Divan, kam | Yargı, gömü, kurgan | Kut ya da Korku, satır | II–VI |
| Elçi | Elçi Yurdu | Heyet, armağan | Grup adı, takas, armağan | III–VI |
| Yoldaş (K71) | Onay | Yoldaşın isteği, bağ eşiği (3, 6, 9), tarihli olay | Bağ, kamp sahnesi, son kart satırı; XP yok (K88) | II–VI |

Perde başına 5 aile etkindir, her biri 3 görev (VI'da 4 × 3). Yoldaş ailesi sayılara girmez: 12 kişisel görev × 3 adım ayrı bir kuşaktır ([Yoldaşlar](/docs/gameplay/companions#kisisel-gorevler)). Açık yan görev sessizce düşmez: verisinde sonraki perdede sürer, Kronik'te sonuç satırı olur ya da kapanır yazar.

**Keşif durakları.** XP'li durak üç türdür: Bakış, Menzil ve Taş Yığını (harita başına 2–4; o seferde yol olayı %25'ten %20'ye iner); taban 10 XP. III ve tek haritada kalan VI en çok 8 durak alır. Küçük durak XP vermez: Eski Ocak (hazır altı taşlık halka), eski kurgan, kayıp sancak, kuru kuyu; ödülü bilgi, mal, ad ya da Destan dizesidir, harita başına 6–10. İç harita reçetesi 1.400×1.050 m'dir: 2–3 çapa, 1–2 kapı, 4–6 görev yeri, 3–8 keşif durağı (adlı yer toplamı 14–18), 20–30 zemin işareti; 1 ana yol, 2–3 yan yol, 3–5 patika; seviye kilidi yoktur, tehlike eşiği görünür.

| XP bütçesi | Ana | İş | Yan | Keşif | Toplam |
|---|---|---|---|---|---|
| I | 2.460 | 405 | 1.580 | 130 | 4.575 |
| II | 4.305 | 700 | 1.884 | 286 | 7.175 |
| III | 6.490 | 1.060 | 2.990 | 260 | 10.800 |
| IV | 8.722 | 1.380 | 3.668 | 630 | 14.400 |
| V | 10.877 | 1.700 | 4.719 | 704 | 18.000 |
| VI | 12.390 | 2.000 | 4.110 | 900 | 19.400 |

II–VI'nın ana görev XP'si taban × görev sayısı × perde çarpanıdır (II 205 × 12 × 1,75), keşif yeni iç haritadan ve XP'li duraktan hesaplanır; seviye ve birikim [Seviye ve Gelişim](/docs/gameplay/progression#seviye-ve-xp) sayfasındadır.

Doğrulanacak: II–VI'nın görev başına tabanı, yan görev XP'si ve İş sütunu tahmindir; ölçü günü (±%30) ve ≈420 dakika da her perde oynanınca ölçülür ([II](/roadmap#item-act2-progression), [III](/roadmap#item-act-3-story), [IV](/roadmap#item-act-4-story), [V](/roadmap#item-act-5-story), [VI](/roadmap#item-act-6-story)).

## Perde sonu ve Serbest Dolaşım

- **Son görev** yalnız üç kol bitince açılır. Son Görev Kapısı kartı «Bu yol perdeyi kapatır. Sonra {y} yıl geçer.» der, açık yan görevleri sonucuyla listeler; Yola Çık ya da Daha Değil; kartta saat durur. Oyalanana bedel yoktur: son görev açıldıktan sonra 3., 6. ve 9. günde kişiler sabırsızlanır ([K42](/docs/source/design/decisions#k42)).
- **Serbest Dolaşım.** Son görev bitince kapanış sahnesi ve perde kartı gelir, dünya açık kalır: iç haritalar, Plan Kipi, Defter, süren yan görevler, av, inşa. Yeni ana görev açılmaz. Takvim akar: kışın ordugâh dağılır, akın ay penceresiyle gelir.
- **Kronik'e bırak.** Perde kartında, duraklatma kitabında ve Mete'nin her ocağında durur. Onay kartı hedef tarihi, geçecek yılı ve açık yan görevlerin sonucunu yazar; Akan Kronik aradaki yılları 30–90 sn'de gösterir ([Perde Arası: Akan Kronik](/docs/story/chronicle)).

> [!DURUM]
> Oyunda (Godot): Serbest Gez. Menüden girilir, ana kampın Çocuğu gece kampında ateş başındaki yerinden kalkar, yürür ve koşar (K37); oluşturulan yetişkin Serbest Gez'e inmez; saat ve takvim yoktur, gece sabittir. Yok: görev sistemi ve Görevler (`J`), diyalog, Kışlak dünyası, bölge rütbesi, kefil, Kızıl Kazık, vakit çağrısı, İş Tahtası, iç haritalar, atlas ve yolculuk, keşif durakları, Son Görev Kapısı, Akan Kronik, Serbest Gez'in takvimi ve arabası, Mete'nin oynanması (Çocukluk'un küçük Mete'si dışında). Prototipte denendi: atlas haritası, saat ve takvim, koşul ve etki dili ([d3/game-state](/docs/source/design/d3/game-state)).

## Yol haritası

Görev sistemi, «Bugün» listesi ve bölge haritası I. Perde'nin hikâye sistemleri fazındadır ([görevler](/roadmap#item-quests), [bölge haritası](/roadmap#item-region-map), [İş Tahtası](/roadmap#item-work-board)); Serbest Gez'in takvimi oyuncu ve dünya çekirdeğindedir ([Serbest Gez'in takvimi](/roadmap#item-roam-calendar)). Atlas, iç haritalar ve keşif durakları II. Perde'nin harita fazında; görev verici, iğne ve Son Görev Kapısı II'nin ana zincirinde; Serbest Dolaşım ve «Kronik'e bırak» II'nin son fazındadır ([Kronik'e bırak](/roadmap#item-leave-to-chronicle)).

```ilerleme
act-2-p1
act-2-p4
```

## Kaynaklar

- [decisions.md](/docs/source/design/decisions): [K6](/docs/source/design/decisions#k6), [K7](/docs/source/design/decisions#k7), [K9](/docs/source/design/decisions#k9), [K23](/docs/source/design/decisions#k23), [K25](/docs/source/design/decisions#k25), [K37](/docs/source/design/decisions#k37), [K40](/docs/source/design/decisions#k40), [K41](/docs/source/design/decisions#k41), [K42](/docs/source/design/decisions#k42), [K43](/docs/source/design/decisions#k43), [K46](/docs/source/design/decisions#k46), [K76](/docs/source/design/decisions#k76), [K84](/docs/source/design/decisions#k84), [K88](/docs/source/design/decisions#k88)
- [story.md §10](/docs/source/design/story#10-gorev-yapisi-19-20-21): [§10.1](/docs/source/design/story#10-1-kalip), [§10.2](/docs/source/design/story#10-2-perde-basina-sayilar), [§10.3](/docs/source/design/story#10-3-yan-gorev-aileleri), [§10.4](/docs/source/design/story#10-4-kesif-duraklari), [§10.5](/docs/source/design/story#10-5-gorev-verici-ve-igne), [§10.6](/docs/source/design/story#10-6-perde-sonu-19), [§10.7](/docs/source/design/story#10-7-serbest-dolasim-ve-akan-kronik); [§11](/docs/source/design/story#11-ii-vi-perdeler)
- [act1.md §1](/docs/source/design/act1#1-oncul-sure-ton), [§2](/docs/source/design/act1#2-oyun-dongusu-ve-eksenler), [§4](/docs/source/design/act1#4-dunya), [§6](/docs/source/design/act1#6-ana-gorevler), [§7](/docs/source/design/act1#7-yan-gorevler)
- [travel.md §0](/docs/source/design/travel#0-karar-ozeti), [§1.3](/docs/source/design/travel#1-3-ic-harita-tablosu), [§8](/docs/source/design/travel#8-hikaye-kilitleri), [§9](/docs/source/design/travel#9-uzak-yollar-atlas), [§10.3](/docs/source/design/travel#10-3-serbest-gez-arabasi)
- [progression.md §1.2](/docs/source/design/progression#1-2-perde-xp-butcesi), [§2.5](/docs/source/design/progression#2-5-cocuk-blogu-serbest-gez); [settlement.md §2](/docs/source/design/settlement#2-acilis-ve-buyume-yayi); [time.md §2](/docs/source/design/time#2-takvim), [§9](/docs/source/design/time#9-i-perde-saatle); [d2/core.md §4.10](/docs/source/design/d2/core#4-10-kronik-k25)
- [oyun-seviye-tasarimi.md §1](/docs/source/research/game-and-level-design#1-ornek-oyunlar), [§2](/docs/source/research/game-and-level-design#2-gorev-yapisi); [d3/register.md](/docs/source/design/d3/register), [d3/game-state](/docs/source/design/d3/game-state)
- [Yoldaşlar](/docs/gameplay/companions), [Seviye ve Gelişim](/docs/gameplay/progression), [Tek Gecelik Kamp](/docs/gameplay/overnight-camp), [Ordu](/docs/gameplay/army), [Harita ve Ölçek](/docs/world/map), [Bölgeler](/docs/world/regions), [Yolculuk](/docs/world/travel), [I. Perde: Gün Gün](/docs/story/act-1-days), [Perde Arası: Akan Kronik](/docs/story/chronicle), [Obadan Hanlığa](/docs/settlement/encampment)
