---
title: 'I. Perde: Çan'
order: 30
status: tasarim
summary: 'MÖ 210 kışı, Yüeçi Kışlağı: üç kıştır çanla sayılan rehine Mete altı günde emeğiyle güven kazanır, güven borca döner, kefillerinin adı pahasına kaçar, ilk ıslıklı oku duymayan bir çocuğun oyuncağından öğrenir ve baharda eve döner.'
sources:
  - docs/design/act1.md
  - docs/design/story.md
  - docs/design/decisions.md
  - docs/design/companions.md
  - docs/design/time.md
  - docs/design/progression.md
  - docs/design/audio.md
  - docs/design/fauna.md
  - docs/design/act0-text.md
  - docs/design/godot.md
  - docs/design/d3/oyun-durumu.md
  - docs/research/mete-tarih.md
---

## Özet

I. Perde «Çan / The Bell» 2–7 Aralık MÖ 210'da geçer (sayımın 1.041–1.046. günleri): Hexi Koridoru, Çilyan eteği, Hey Irmağı'nın bir kolundaki Yüeçi Kışlağı. [Mete](/encyclopedia/mete) 24 yaşındadır, üç kıştır Yüeçilerin rehinesidir. Sol ayak bileğindeki tunç çan her adımını kampa duyurur. Oyuncu altı gün taşır, toplar, kurar, pişirir, ata biner, nöbetçiden saklanır ve kefil kazanır. Gün IV'te babası [Teoman](/encyclopedia/teoman) Yüeçilere saldırır, kazanılan her güven borca döner. Son Gece Mete kefillerinin adı pahasına kaçar; Gün VI'da Kara Boran'da, duymayan bir çocuğun oyuncağından yontulan ilk ıslıklı oku atar. Perde 11 Nisan MÖ 209'da Tanhu Kampı'na, Teoman'ın ocağına dönüşle (Ev) biter.

**Ad.** Perdenin adı «Çan»dır ([K32](/docs/source/design/decisions#k32)): rehinenin ayağındaki çan; perde çanla açılır, ıslıkla kapanır. Gün I'in adı perdeyle çakışmasın diye «Gösteri / The Showing»dır; öteki günler Kefil, Elçi, Kâse, Hüküm, Son Gece ve Ses'tir ([K38](/docs/source/design/decisions#k38)).

**Boyut.** 22 ana görev (2.460 XP), 23 yan görev (1.580 XP), seviye 1–5. Ana yol ≈3 sa 40 dk, bütün içerik ≈5 sa 10 dk. Perde son ana görevle, Ev ile biter; sayaç yoktur ([K42](/docs/source/design/decisions#k42)). Günlerin saat saat anlatımı [I. Perde: Gün Gün](/docs/story/act-1-days) sayfasındadır.

> [!NOT]
> «Tabi yerleşim yeri veya askeri kamp kurmadan önce act 1 deki tutsaklık perdesini bitirmemiz gerekecek yani act 1 den önce bazı şeylerin kısıtlı olması lazım, act 1 bittikten sonra daha özgür bir açık dünya olacak»

Tasarım bu yöndedir ([K43](/docs/source/design/decisions#k43)): I. Perde kısıtlı bölümdür (tek vadi, kefil, Kızıl Kazık); yerleşim, ordugâh ve serbest parti yoktur, açık dünya II'den başlar. Kısıtlı vadide de açıklık hissi veriyle gelir («Çekirdek döngü» altında).

## Perdenin sorusu

- **Soru.** Sayılan biri kendini nasıl geri alır?
- **Fiil.** Taşımak ve güven kazanmak. Her bölüm bir fiil öğretir ve ona yük bindirir: Çocukluk'ta nişan almak, I'de taşımak ve güven kazanmak, II'de buyurmak.
- **Tema.** Sayılan sayan olur; her sayı bir borçtur. Palak her sabah rehineyi sayar; perdenin sonunda sayan Mete'dir: «Bir... dokuz.»
- **Önce ver, sonra al.** İlk üç gün kamp güler; Gün IV'te perde güldüğün her şeyi tek tek geri alır. Mete'nin kurduğu yurt IV. Perde'de yırtık durur.
- **Yankı.** Teoman'ın dört saniyelik bakışı üç kez gelir: Çocukluk'ta atlıyken, Yola Çıkış'ta kapalı kapı olarak, Gün IV'te höyükten. «Beni gördü.» birinci ve üçüncüde söylenir (K38).
- **Tarih her dalda korunur.** Game over yoktur; seçim olayı değil anlamı ve bedeli değiştirir: Kut, Korku, bayraklar. Saat biterse oyun bitmez: buza yürürken aygır ipini koparır, Mete firarisiz ve eyersiz kaçar.

## Tarih ve açılış

Shiji 110'un çizgisi şudur. MÖ 215'te [Meng Tian](/encyclopedia/meng-tian) Hunları Ordos'tan sürer. Teoman, gözde hatunun küçük oğluna yol açmak için Mete'yi Yüeçilere rehin verir, sonra Yüeçilere ansızın saldırır. Yüeçiler Mete'yi öldürmek ister; Mete en iyi atlardan birini çalıp döner. Teoman onu yiğit bulur ve on bin atlı verir (II. Perde). Rehinelik 26 Ocak 212'de Kapı'da çanla başlar: sayım rehinenin günüdür, 1. gün odur. Mete 27 Eylül MÖ 234 şafağında doğdu; tarihler oyuncuya kesin söylenir, «c.» ya da aralık yazılmaz ([K33](/docs/source/design/decisions#k33)).

**Gösteri (K33).** Her yıl Dailin Sayımı'ndan sonraki dolunayda Hun elçisi yola çıkar, kışın ilk haftalarında Kemik Boğazı'na varır; rehine ona canlı gösterilir, Hun sayımının son satırı odur. Rehinenin elçiye gösterildiğine dair kaynak yoktur; gösteri kurgudur, gerekçesi çıkarımdır: rehine yaşamıyorsa rehin hükümsüzdür. Takvim: Birinci İmparator 12 Temmuz 210'da, Meng Tian 6 Kasım 210'da ölür; iki haber I. Perde'de kervanla gelir. Teoman'ın son Dailin Sayımı 8 Eylül 210'dur. Elçi [Eskam](/encyclopedia/eskam) izleyen dolunayda, 7 Ekim'de armağan arabasıyla yola çıkar; 1.173 km'yi 50 günde alır (40 gün × 25 km; 16 Kasım'dan kalan 173 km kış çarpanı ×0,7 ile 10 gün), 26 Kasım'da Kemik Boğazı'na varır. Yüeçi onu Kapı dışında beş gün bekletir: bu Amaga'nın gücüdür. Gösteri 2 Aralık sabahıdır; araba 10:40'ta Kışlak'a girer, perde açılır.

Aynı kural 21 Kasım 212 ve 18 Aralık 211'i verir: üç gösteri de kışın ilk beş haftasındadır, «üç kış» tutar. Atlas aynı yolu 2–4,5 günde gösterir; 50 gün yalnız hikâye hesabıdır, oyuncu metninde geçmez. Palak bunu sayıyla söyler: «Elçi yılda bir gelir. Bu kış iki kez geldi.» Sayım'dan sonra bir kez daha: «Üç gösteri. Bin kırk bir gün.»

## Önce ve sonra

Yeni Oyun'dan perdeye yol şudur ([K36](/docs/source/design/decisions#k36), [K68](/docs/source/design/decisions#k68)): [Önsöz «Kopuz Söyler»](/docs/story/prologue) (sinema, 4 dk 18 sn; doğum 27 Eylül MÖ 234) → [Çocukluk «Koyun Sırtında»](/docs/story/childhood) (22 Eylül MÖ 228, ≈6 dk, oynanır) → Köprü 1 (N1–N5, ≈50 sn) → oluşturucu «Yola Hazırlan» → Yola Çıkış (15 Aralık MÖ 213, ≈90 sn) → Köprü 2 (N6–N7, ≈18 sn) → I. Perde'nin kara ekranı ve çanı. İlk oyunda ≈12 dk geçer, oluşturucu hariç. Köprüler adı konmuş atlamadır: takvim 22 Eylül 228'den 15 Aralık 213'e, oradan 2 Aralık 210'a ileri gider ([K67](/docs/source/design/decisions#k67)). Yola Çıkış'ta Lan Hatun «Kırk iki gün yol.» der; Eskam «Ben her kış gelirim.» der.

Köprü 2'nin parşömen videosu kar yolunu, Kemik Boğazı'ndaki kapıyı, bileğe bağlanan çanı, sığırlarla sayılan rehineyi ve yürüyen ayaktaki çanı gösterir. Anlatıcı: «Mete batıya ordusuz ve yaysız gitti. Kapıda ayağına bir çan bağladılar, onu bir baş hayvan gibi saydılar.» ve «Tarih, sonradan olduğu Tanhu'yu yazar. Bu, önce olduğu rehinenin hikâyesi.» Son satırın kaydı vardır, değişmez; ilk satır yeni metniyle 2026-11-05'te okundu ([act0-text.md](/docs/source/design/act0-text#kopruler-act0-narr-1-act0-narr-7)).

![Anlatıcı, Köprü 2'nin son satırı (N7)](/media/docs/media/audio/vo/en/act0.narr.7.mp3)

```varlik
fx_panel_bridge2_road, fx_panel_bridge2_gate, fx_panel_bridge2_bell
```

## Kışlak

Kışlak 1.400 × 1.050 m'lik ayrı bir iç haritadır; atlasta Hexi Koridoru'nda tek iğnedir. Ortada Ulu Ocak'ın 12 m'lik meydanı durur; ev kuzeydedir, Adak Ağılı güneyde. Kamera kuzeye bakarak açıldığı için kaçış varsayılan kadrajda bütün vadiyi bakılan yönde sürer. Kampta 24 ocak (11'i adlı) ve 9 nöbet ateşi vardır; nöbet ateşleri 16:30'da yanar, 07:40'ta söner. Kışlak'ın yurtları Hane boyunda ve Yüeçi gövdesindedir. Kışlak başının yurdu «Amaga'nın Yurdu / Amaga's Yurt»tur: boyu Hane Yurdu (×1), iç düzeni Divan Düzeni. Eski «Otağ» adı kalktı, çünkü Otağ yurdun en büyük boyunun adıdır (×1,4); Otağ boyu yurdu kaydırır ve Hüküm kadrajında Yar'ı ve ev yolunu örtebilirdi ([K34](/docs/source/design/decisions#k34), [K51](/docs/source/design/decisions#k51)). Bölgelerin yeri ve gece hâli: [Bölgeler](/docs/world/regions).

```varlik
yurt_yuezhi, yurt_yuezhi_small, great_hearth, tower_gate, deer_stone
```

## Ton

- İlk üç gün kamp güler: Kantu'nun çenesi, Mene'nin çığlığı, Palak'ın bahisleri, Nanay'ın alayı. Sonra perde güldüğün her şeyi geri alır.
- Kimse canavar değildir, herkesin haklı nedeni vardır. Boss bile insandır. Çocuk ölümü ve kan görünmez; görünen sonrasıdır: boş eldiven, sönmüş ocak.
- Tanrılar en çok iki cümle konuşur. Satır en çok iki cümledir: Yüeçiler sayıyla, Hunlar kısa ve kara mizahla konuşur.
- Gündüz kar sıcak beyaz, gölge mavidir; mavi baskınlık yalnız gece ve tipide. Yüeçi bordo, hardal, okra; Hun kızıl, kahve, altın. Mete'nin pelerini kalabalığın tek soğuk vurgusudur: varsayılan Göl Mavisi `#2a6f8c`, oluşturucunun «Boya» satırı altı renk sunar; soğuk renk kalabalık giysisinde yasak, adlı kişide serbesttir ([K58](/docs/source/design/decisions#k58)).
- Müzik E Frigyen'dir, akort kerbez. Nabız ikidir: iş ve gerilim 72, akşam ve gece 58; baskın 132. İki istisna bilerek konmuştur: Kara Boran'ın kovalamacası 116, D Dorian, kambarkandır, çünkü kopuz müziğe kampın akordunda döner ve eve dönüşün ilk sesidir; Şafak Sırtı ve Ses 76, majör pentatonik, terstir, çünkü gök anıdır ([K59](/docs/source/design/decisions#k59)). Kopuz müzikte kaçış gecesine dek yoktur; dünyada bir kez görünür: Usun at tüccarı Nandu Gün II–IV'te Ulu Ocak pazarında ≈5 sn eyerde çalar ([K60](/docs/source/design/decisions#k60)). Koro yalnız gök içindir: Gök Açılır ve Şafak Sırtı.

## Üç motif

- **Çan.** Sol ayak bileğindeki tunç çan üç kış önce Kapı'da bağlandı. Yürüyünce 14 m, koşunca 32 m duyulur; durunca susar, el çanda çömelince 2 m'ye iner. Ancak Son Gece kesilir: kesilir, bırakılır ya da Mene'ye verilir.
- **Sayım.** Palak her sabah Sayım Taşı'nda sayar: «Bin kırk birinci gün. Bir rehine.» Sayı takvimin kendisidir: Gün I, sayımın 1.041. günüdür, 2 Aralık MÖ 210. Perde sonunda sayan Mete'dir.
- **Kefil.** Bölgeler kapıyla değil insanla açılır. Kefil çeteleyi ikiye böler, yarısı sende kalır. Haritan borç defterindir.

```varlik
hostage_bell, count_stone, notch_stick, tally_farnak, red_stake, work_board
```

## Kişiler

Kadro `act1.md` §3 ve `story.md` §8.4'tedir. Yüeçi adları Saka-İran ve Kuşan tanrı adlarından ve Toharca sözlerden gelir. Hereka, Uldın, Berik, Eskam ve Mundzuk 5. yy Avrupa Hunlarının adlarıdır: kalırlar, Destan'da «adı sonraki Hunlardan» notunu taşırlar; yeni Hun adları Han kaynaklarına geçmiş Hun sözlerinden kurulur ([K37](/docs/source/design/decisions#k37)).

| Kişi | Kim | Ne ister | Öğrettiği beceri | Sonra |
|---|---|---|---|---|
| Mete, 24 | Rehine, oyuncu | Eve dönmek, sonra neden gönderildiğini bilmek | | II'de on bin atlının başı |
| [Amaga](/encyclopedia/amaga), 58 | Kışlak başı, Yüeçi Kralı'nın dul kız kardeşi | Halkını bahara çıkarmak, Teoman'ın istediğini vermemek | Kefil Sözü | IV: Batı Yolu ve antı |
| [Farnak](/encyclopedia/farnak), 25 | Atlı okçu, ilk kefil, boss | Bir ev, temiz bir ad | Binicilik, Rüzgâr Altı, Sapan Eli | IV: yazgısı Nanay'ın ocağında okunur |
| [Nanay](/encyclopedia/nanay), 23 | Keçe ustası, Farnak'ın yeni eşi | Akmayan çatı, eve dönen adam | Onarım | IV: ocağı ve beş yaşında oğlu |
| [Ardokşa](/encyclopedia/ardoksha), 52 | Ambar bekçisi | Baharda eksik kalmasın | Sırt Yükü, Hesap Gözü | IV: çetelesi Sarva'nın yolunu açar |
| [Kantu](/encyclopedia/kantu), 61 | Arabacı nine, Mene'nin ninesi, Sazlık'ı satan | Torununun borcunu ödemek | Soluk Paylaşımı, Arabacı | IV: Kantu'nun Arabası |
| [Mene](/encyclopedia/mene), 9 | Duymayan çoban kızı; seslendirmesi yok | Aygır kurban edilmesin | El Dili, Kemik Atışı, Kar Adımı | IV: on dört yaşında, çan |
| [Palak](/encyclopedia/palak), 47 | Nöbet başı, her sabah sayar | İki oğlu gitti, üçüncüsü yaşasın; sonra yasa | Savuş, Nöbet Okuma | IV: Palak'ın Borcu |
| [Atşo](/encyclopedia/atsho), 34 | Ateş bekçisi | Kutlu ateş bu kış sönmesin | Kışlak Ağzı | IV: kutlu ateşi köz kabında batıya taşır |
| [Hereka](/encyclopedia/hereka), 63 | Çukur'un ebesi; 234'te Mete'yi doğurtan ebe, onu tanır | Adlar unutulmasın | Ocak Bilgisi | IV: adların sayımı |
| [Uldın](/encyclopedia/uldin), 36 | Eski onbaşı, Çukur'un Hun tutsağı | Sekiz yılın kanı | Dizle Sürme, Uyku Kolu | II'den çekirdek yoldaş (Güreşçi) |
| [Berik](/encyclopedia/berik), 19 | Çukur'da doğmuş hırsız | Görmediği «ev» ve Sarva | Keçe Tıkaç tarifi | II'de ya da IV'te yoldaş (Keşif eri) |
| [Kujul](/encyclopedia/kujul), 49 | Demir Diş ustası | Gerçek demiri dövmek | Tam Vuruş | |
| Eskam, 44 | Gudu, Huyan soyundan elçi; 213'te Mete'yi götüren | Kampın haritası, levhanın yerine varması | Yalan Yüz | II: yazgısı |
| [Mundzuk](/encyclopedia/mundzuk), 38 | Baskın başı, Huyan Hatun'un kardeşi | | | II'de ölür, ekran dışı |
| Teoman, ≈52 | Tanhu, baba; Gün IV'te höyükten bakar | Küçük oğluna yol, büyüğünün ölümü başka elden | | II'de av |

- **İkinciler.** [Omarg](/encyclopedia/omarg) (34, gece nöbetçisi), [Sak](/encyclopedia/sak) (20, Palak'ın son oğlu; Gün IV gecesi ekran dışı ölür), [Opia](/encyclopedia/opia) (33, ambar hırsızı dul), [Nandu](/encyclopedia/nandu) (40, Usun at tüccarı), [Yuan](/encyclopedia/yuan) (30, Çiang madenci; Çiang'ın Yanmayan Kölesi'ni anlatır), [Sarva](/encyclopedia/sarva) (18, Ardokşa'nın yeğeni), [Tola](/encyclopedia/tola) (17, hasta esir).
- **Tanrılar.** [Erlik](/encyclopedia/erlik) Teoman'ın yüzüyle görünür: kor göz, insan boyunda, oturur, aşık oynar; sesi ateşlerden gelir, acelesiz, vade sayar gibi. Hun ağzında adı Kara Nama'dır; Önsöz'de yüzsüzdü, yüzü ilk kez burada görünür ([K35](/docs/source/design/decisions#k35)). [Tengri](/encyclopedia/tengri) görünmez, tek sözcük söyler: «Gör.» [Umay](/encyclopedia/umay) sözsüzdür: Mene'nin çevresinde altın titreşim; Düşüş'ten uyanınca başucunda küçük ok-yay durur.
- **Hayvanlar.** [Adak Aygırı](/encyclopedia/offering-stallion) küllü bozdur, sırtında kara yol vardır: Yüeçilerin baharda Geyik Taşları'nda kurban edeceği at, Hun ağzında ıduk; Mete çaldığı an adını seçer: Küldoru, Tanyeli ya da Arkvi. [Yakve](/encyclopedia/yakwe) yaşlı kısraktır («Adı Yakve. Bizim dilde "at" demek. Ne bekliyordun?»), [Erkent](/encyclopedia/erkent) Farnak'ın kara kısrağı, [Ku](/encyclopedia/ku) Mene'nin köpeğidir. Kışlak'ın yaban takımı köpek, tavşan, tilki, ceylan, yaban keçisi, yaban domuzu, maral ve kurttur; çevrede deve, sığır ve kartal; Ak Otlak'ta 60 at ve 200 koyun. Kartal Şafak Sırtı'nda ilk açık göğün parçası olarak geçer ([K65](/docs/source/design/decisions#k65)); türler ve perde perde açılış [Hayvanlar](/docs/world/animals) sayfasında ([fauna.md §9](/docs/source/design/fauna#9-perde-perde-acilis)).

```varlik
portrait_amaga, portrait_farnak, portrait_nanay, portrait_ardoksha, portrait_kantu, portrait_mene, portrait_palak, portrait_atsho
portrait_hereka, portrait_uldin, portrait_berik, portrait_kujul, portrait_eskam, portrait_mundzuk, portrait_teoman, portrait_erlik
offering_stallion, yakwe, erkent, ku, eagle
```

## Çekirdek döngü

`Emek → Güven → Kefil → Bölge → Usta + Malzeme → Beceri + Zula → Kaçış`. Teoman saldırınca her güven borca döner.

- **Emek.** İş Tahtası'nda hikâye günü başına 3 iş sayılır: iş başına +3 Güven, +25 XP; türün ilki +4 Güven, +40 XP. 2 iş tam kase, 0–1 iş yarım kase verir; kaseler akşam aşında (17:30–19:30) verilir. Günlük Sayım'a (07:30) gelmek +1 Güven. Yeni Yurt'un pedinde çalışmak iş sayılmaz.
- **Kış Hesabı.** Yakacak %60, Yiyecek %55, Yem %65 başlar; her şafakta −8 düşer (Hikâye −6, Zor −10). Üçü de Toy'da %100 ise Kut +1. Son kartta Yiyecek ≥%35 ise Kışlak bahara çıkar.
- **Kefil.** Son Gece yarımı sahibinin ocağına bırakırsan borç kapanır, kefil temize çıkar; bırakmazsan ceza ona kesilir. Çetele, iki yarım eşleştiği için kanıttır.

| Kefil | Veriliş | Açtığı | Bırakılmazsa |
|---|---|---|---|
| Farnak | Gün I, İlk Çetele | Ak Otlak | Adını yitirir, Nanay rehin kalır, Boğaz'da onun için gelir |
| Ardokşa | Gün II, 3 iş ve Güven ≥20 | Kara Yamaç, balta | Anahtarlarını yitirir, Ambar başka elde |
| Kantu | Gün II, Kırık Tekerlek | Buz Kolu, Sazlık, Menzil ağı | Arabasını yitirir |
| Atşo | Gün III, Ocağın Nöbeti | Adak Ağılı (yalnız ot işi), Eski Kurganlar | Ateş görevini yitirir |
| Amaga | Gün IV Toy, Güven ≥70 | Gece izni | Kurulda itibarını yitirir |

- **Bölge rütbesi.** Kilitlenme yoktur: her rütbe Güven eşiğiyle ya da gün tabanıyla gelir. Rütbe 0 Kışlak ve Esir Çukuru'dur; 1 Farnak'ın çetelesiyle (Ak Otlak, Buz Geçidi çevresi, Yar Dibi Taşlığı), 2 Güven 25 ya da Gün II ile (Kara Yamaç, Buz Kolu, Sazlık), 3 Güven 45 ya da Gün III ile (Demir Diş, Adak Ağılı, Eski Kurganlar), 4 Güven 70, Av ya da Gün IV ile (Yukarı Ağıllar, Kara Tepeler, Ayna Göl, Kuzey Düzü, Kemik Boğazı'na bakış) açılır; ilgili bölgeler kefilin çetelesini ya da görevini de ister. Tablo [I. Perde: Gün Gün](/docs/story/act-1-days#bolge-rutbeleri) sayfasındadır.
- **Yumuşak sınır.** Duvar yoktur; bölge kenarı Kızıl Kazık hattıdır. Çetelesiz geçince 40 sn sayaç işler (çömelik ve el çanda 120 sn), sonra Kazık Atlısı gelir: 3 sn kararma, Kantu'nun arabasıyla geri, Güven −2; eşya gitmez. Amaga: «Kaçacak yerin yok. Kış senin bekçin.»
- **Kısıtlı ama açık (K43).** Görevler'deki «Bugün» listesi serbest saatte en az 3 iş gösterir. Kapalı bölge kefilinin adını söyler. Her Bakış Noktası'ndan en az 2 kapalı bölge görünür. Her kilitli bölgede Kazık hattına yakın bir Kaçak Ödül durağı vardır: bilgi ya da mal verir, XP vermez. Vakit en geç saatinden 30 oyun dk önce ikinci kez çağırır. 23 yan görevin en az 8'i yol üstünde tetiklenir.

## Eksenler

Her eksen ilk değişiminde kartla açıklanır. Kut ve Korku birbirinden bağımsızdır; aralık perde tavanıdır, dolunca artmaz.

| Eksen | Aralık | Görünüşü | Ne değiştirir |
|---|---|---|---|
| Güven | 0–100 | Çentik Çubuğu: 5 puana 1 çentik | Bölge rütbesi, nöbet satırları, ≥70 Amaga'nın çetelesi |
| Yakınlık (kişi başına) | 0–10 | Defter'de 0–3 düğüm | Göz Yolu tepkisi, öğretim, gece suskunluğu, ek seçenek |
| Kut | 0–16 | Altın güneş, sayı yok | ≥4 firari ilk çağrıda gelir; ≥5 Tipide at staminası gideri −%15, Umay Eşiği erzak almaz; ≥6 Tipide yıldız açıklığı yönü gösterir; ≥8 «Görmedim.» seçeneği |
| Korku | 0–13 | Kızıl kor, sayı yok | ≥4 nöbetçi ilk görüşte 0,5 sn duraksar, Güven kazancı −%10; ≥6 çağrıya kor karışır: Çığırtkan çağrısında kızıl kor bir an parlar, kısık bir kor çıtırtısı duyulur, söz yoktur, çağrı başına Refleks +2 ([K4](/docs/source/design/decisions#k4)); ≥8 firariler emirsiz atar |
| Kış Hesabı | %0–100 | İş Tahtası, Defter | Nöbet ateşi yarıçapı, Güven kazancı, takipçi atlarının hızı |
| At Bağı | 0–100 | Defter | Adak Aygırı yaklaşımı, dörtnal, stamina |
| Sürü Alışkanlığı | 0–100 | Defter | Çığırtkan yarıçapı `20 + 0,2×alışkanlık` m, doğum okunda dönen at sayısı |
| Bilinen Adlar | 0–31 | Ad İpi | Firari kalitesi, son kart |
| Sönen Ocak | 0–24 | Yalnız son kart | Kara Yol bedeli, Erlik'in borcu |
| Refleks | 0+ | Gizli | Firarilerin sese koşulsuz uyması, II. Perde'nin disiplin tabanı |

## Ana görev zinciri

Her adım öncekinin bitişiyle tetiklenir; Gün I–IV'te adımlar arası serbesttir. Vakit en erken saatinde çanla çağırır, en geç saatinde 3 sn karartmayla oyuncuyu yerine götürür. Günün ana işi bitmeden uyku açılmaz; ana iş bitmeden gece Tan'a varırsa saat orada bekler.

| # | Görev | Gün, vakit | Ne olur | XP |
|---|---|---|---|---|
| 1 | Sayım | I, 10:40 | Arabadan in, 73 m yürü, çanı öğren; Palak sayar | 30 |
| 2 | Tayın | I, 12:00–13:30 | Kazan çanı; 2 Aş al, esir sepetini Çukur Kapısı'na taşı; payını ver ya da verme | 80 |
| 3 | İlk Çetele | I, 15:30'a dek | Farnak'ın 6 taşı, Yeni Yurt pedi, Amaga çeteleyi böler, Yakve, Yar Bakışı; rütbe 1 | 100 |
| 4 | Sürü Okulu | II, 08:00–12:00 | Mene'nin ağılı, el dili, Ku; oyuncu Mene'nin oyuncağından kendi Çığırtkan'ını yontar; 40 at 3 kapıdan | 110 |
| 5 | Üç Çetele | II | Ardokşa: 3 iş; Kantu: Kırık Tekerlek; Nanay: kuzey panelinin düğümü, sıkı ya da gevşek; rütbe 2 | 170 |
| 6 | Tündük Kaldırma | III, 08:30–10:30 | Sırığa omuz ver, 3 hamle; tündük 09:11'de oturur; ilk kez kamp sana gülerek bakar | 60 |
| 7 | Elçi | III, 11:30–13:00 | Eskam'ı gezdir: gösterdiğin yer baskının kaderini yazar; Altın Levha | 130 |
| 8 | Av | III, 14:00–16:30 | Ödünç yay, 2 yaban keçisi; yay akşam geri alınır; rütbe 4 | 100 |
| 9 | Toy | IV, 16:30–17:30 | Yurt aşama 7, 17:06'da ilk duman, Kardeş Kâsesi; Farnak sadak verir, yay vermez | 100 |
| 10 | Sazlık Yanıyor | IV, 17:40–20:04 | 20 Hun atlısı, üç hedef, en çok ikisi kurtulur; Teoman höyükten bakar | 200 |
| 11 | Kül Sabahı | V, 07:30–09:00 | Tekeri onar, 0–3 yaralıyı 414 m sür | 70 |
| 12 | Göz Yolu | V, 11:50–12:30 | Bağlı yürüyüş 131 m, hüküm; heybe Ambar'a gider | 60 |
| 13 | Son Aş | V, 18:00 | Yeni Yurt hücren olur; Nanay ve Amaga gelir | 60 |
| 14 | Düğüm | Son Gece, 20:10 | Yurttan çık; Ay Saati başlar | 60 |
| 15 | Kara İp | Son Gece | Donuk Kamp: Erlik Teoman'ın yüzüyle | 140 |
| 16 | Gördüm | Son Gece | Yar Bakışı'nda Gök Açılır, üç ışık; gök kapalıysa XP yok | 140 |
| 17 | Gece İşleri | Son Gece | Eyer, erzak, çeteleler, Çukur, Kantu, çan | 60 |
| 18 | Adak Aygırı | Son Gece | Yaklaş, eyerle, adlandır, çitten atla | 140 |
| 19 | Kara Boran | VI | Şeritsiz kovalamaca, temiz sürüş ≥3 dk | 300 |
| 20 | Kemik Boğazı | VI, ≥06:14 | Boss: Farnak | 220 |
| 21 | Ses | VI | Doğum oku, ikinci ok | 100 |
| 22 | Ev | 11 Nisan 209 | Tanhu Kampı'na dönüş, uzak kare (K106); perdeyi kapatır | 30 |

## Yan görevler

23 yan görev 1.580 XP verir. Her biri aynı perdede yankılanır; yankısız seçim yoktur. Yan görevler Kışlak'a bağlıdır: Göz Yolu başlayınca açık kalanlar Görevler'de «Kapanır / Closes» diye yazılır, sessiz düşüş yoktur (K42). Sonraki perdelere antlar ve bayraklar taşınır. Tek tek tablo [I. Perde: Gün Gün](/docs/story/act-1-days) sayfasındadır.

| Küme | Görevler | Kaçışa ne hazırlar |
|---|---|---|
| Çukur ve adlar | Otuz Bir Ad, Erzak Yolu, Çukur Humması, Zula, Berik'in Evi | Firarilerin sayısı ve ilk çağrısı, Ad İpi, Tipi'de firari başına 1 Aş, Hereka'nın susması, Berik kalırsa Ay Saati'ne +1 saat |
| Sürü ve aygır | Karga Savaşı, Çakıl Defteri, Adak Yemi, Yol Kemikleri | Aygırın sese gelmesi, Mene'nin el işaretiyle yol göstermesi, düşersen aygırın dönmesi, Tipi'de direklerin uğultusu |
| Nöbet ve gece | Kandil Yağı, Eksik Ölçü, Sıcak Aş | Sönen fenerler, Opia'nın saklaması, Omarg'ın uyuması ya da kapıyı açması |
| Kefiller ve ustalar | Ocağın Nöbeti, Yolcular, Eski Köprü, Sürüde Kurt, Buz Yarışı, Keçe Dövme, Bahis, Demir Diş | Atşo'nun çetelesi, yedek at, köprüyü arkandan kesmek, kurdun uluması, Farnak'ın tuzağının saati, keçe çizme ve sessiz giriş, bıçak ve beceriler |
| Pazar ve ölüler | Kervan Haberi, Balık Delikleri, Ölünün Altını | Baskın süresi ±60 sn, takipçi düşüren ince buz, akinakes ya da Kut |

## Sistemler

Oyunun çekirdek sistemleri ilk kez bu perdede gelir. Perde kısıtlı olduğu için onları açık dünyadan önce dar bir alanda sınar; sayılar burada kurulur, sonraki perdeler aynen kullanır.

| Sistem | I. Perde'deki yüzü | Sayfa |
|---|---|---|
| Saat ve takvim | 1 oyun günü 60 gerçek dk, tek takvim ([K67](/docs/source/design/decisions#k67)); hikâye günü Tan'da başlar (Gün I'de 06:12); saat iki yerde bekler: ana iş bitmeden gece Tan'a varınca ve Hikâye zorluğunda Son Gece 05:45'te; Son Gece'nin saati Ay Saati'dir | [Zaman ve Takvim](/docs/world/time-calendar) |
| Hava | Kış satırı: açık, parçalı bulut, kapalı, sis, kar, rüzgâr; yağmur, dolu, gök gürültüsü yok; her büyük sahne kendi hava kilidini taşır; yoğun kar ve Kara Boran yalnız hikâye kilidiyle gelir | [Hava](/docs/world/weather) |
| Toplama, Yük, zanaat | Dal, saz, tezek 2 sn; ağaç 5 vuruş, 3 tomruk; Tam Vuruş halkası 0,18 sn; Yük `12 + 3×Bilek` (tomruk 4, taş 5, cevher 4, tulum 3; yarı yükte hız ×0,85, tam yükte ×0,7); at üstünde ≤2 sn'lik düğümler toplanır ([K46](/docs/source/design/decisions#k46)); malzeme yontulmuş gelir | [Toplama ve Kaynaklar](/docs/economy/gathering) |
| Ekonomi | Para yoktur, Terazi'de sayısız takas; Kabuk II'den görünür ([K48](/docs/source/design/decisions#k48)) | [Para ve Satıcılar](/docs/economy/money-traders) |
| Erzak ve ateş | Tokluk uyanıkken −5 / oyun saati, açlık öldürmez; kamp ateşi pişirme içindir, `Y` yakıt ekler ([K45](/docs/source/design/decisions#k45)); Gecelik Kamp kapalıdır, II'de açılır | [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting) |
| Emek ve yapı | Yeni Yurt'u Nanay ve iki Yapı Eri kurar: 3 el bir yurdu 33,75 gerçek dk'da kaldırır ([K50](/docs/source/design/decisions#k50)). Tündüğün işi 171 İD'dir (iş dakikası: bir işçinin bir oyun dakikası): altı elle 40,6 oyun dk sürer, Gün III 09:11'de oturur; Toy'da ilk duman 17:06; Gün V yaması 07:00–09:35 ([K83](/docs/source/design/decisions#k83)); darboğaz malzeme ve hikâye kapısıdır | [İnşa ve Emek](/docs/buildings/construction-labour) |
| Gizlilik ve dövüş | Çan yarıçapı; nöbetçi konisi 80°, 16 m (fenerle 20 m); Üç Zemin; yakalanma yükleme değildir; tık-hedef dövüş, öldürmek Korku +2 ve XP yok | [Dövüş](/docs/gameplay/combat) |
| Binicilik ve yol | Gün I'den Yakve; Son Gece Adak Aygırı; Kantu'nun arabası ve Menzil ağı; Yolu Kısalt 3 sn; üzengi yok | [Yolculuk](/docs/world/travel) |
| Kamera | Varsayılan Diablo kadrajı, uzak ve yüksek: 28 m, eğim 38°, görüş 36°, kuzeye bakar; 360° döner, eğim bandı 15–60°, 14–40 m ([K98](/docs/source/design/decisions#k98)). Bakış 15° ve 44 m, Tengri 13° ve 70 m (ufuk istisnası); Çömelme ve Sürüş K98'e göre yeniden kurulur (eskiden en az 36 m ve 27,5°; 23,9°, yokuşta 18,9° ve 30 m). Görev ve sahne çekimleri de uzak karedir: yakın plan yok. Kadraj sözleşmesi kameradan bağımsızdır: tehdit kadrajdadır ya da ekran kenarındaki ok en az 1,2 sn önce yanar ([K39](/docs/source/design/decisions#k39)). `Q` I. Perde'de Çığırtkan'dır, II'den hızlı silahtır ([K82](/docs/source/design/decisions#k82)) | [Kamera ve Kontroller](/docs/gameplay/camera-controls) |
| Seviye | L1'den L5'e; 18 beceriden 6'sı alınır, her beceriyi bir insan öğretir; stat tavanı 7; bütün kaynaklar 4.575 XP, L6'ya varılmaz | [Seviye ve Gelişim](/docs/gameplay/progression) |
| Zorluk | Hikâye, Normal, Zor; oluşturucuda bir satır, kayda yazılır ([K13](/docs/source/design/decisions#k13)) | [I. Perde: Gün Gün](/docs/story/act-1-days) |
| Ses ve söz | Konuşmada müzik ve ortam durum türüne göre kısılır: gündelik −6 / −3 dB, gerilim −6 / −6, baskın ve kovalamaca −9 / −6, Erlik, gök ve Ev −3 / −3; iniş satırdan 0,15 sn önce başlar ([K78](/docs/source/design/decisions#k78)). Alçak sessizlik ≤4 («Yak!», Göz Yolu'nun girişi, Kara Yol), kara sessizlik 1, okun ardında. Söylenen dil İngilizce, altyazı Türkçe; satırlar taslaktır ([K61](/docs/source/design/decisions#k61)) | [Ses ve Müzik](/docs/presentation/sound-music) |

## Yoldaş kısıtı

Mete rehinedir: serbest parti yoktur; Al, Burada Bırak, Ordugâh'a Gönder ve Görevlendir yoktur ([K70](/docs/source/design/decisions#k70), [K71](/docs/source/design/decisions#k71)). Buyruklar yalnız Z (Gel), X (Kal) ve G'dir (Bak); Tab kartlarda ad ve uzaklığı gösterir. Saldır, Topla, Avla, İz Sür, Gizlen, Düzen ve F1–F10 seçimi II'de açılır. Takipçi ve kalabalık altyapısı I. Perde'nin hikâye sistemleri fazında kurulur; talim ve ıslık II'nin, toplu savaş III'ün işidir ([K77](/docs/source/design/decisions#k77)).

| Yardımcı | Ne zaman | Ne yapar | Sınır |
|---|---|---|---|
| Ku | Gün II sabahı Sürü Okulu'ndan Gün V'e | Gel, Kal, Bak; ilk takipçi | Son Gece Mene'nin yanında kalır; kartı 40 px |
| Görev yoldaşı | Görevin süresi: Uldın (Demir Diş, Bahis), Berik (Berik'in Evi, gece), Yuan (Demir Diş) | İzler, Dur ve İzle alır, savaşmaz | Ku'nun yanında en çok bir kişi; Kızıl Kazık'ı geçemez, geçersen sayaç ikinizi de kapsar |
| Firariler | Son Gece'nin Çukur'undan Eşik'e | Kama, Çığırtkan çağrısı, Refleks | Çukur seçimiyle 9 ya da 6, payını vermediysen tavan −2; en çok 10 kart |

- **Kart ve kenar göstergesi ([K73](/docs/source/design/decisions#k73)).** Parti şeridi Ku'yu, görev yoldaşını ve firarileri gösterir. Adı bilinmeyen firari portresiz keçe siluettir. Kadraj dışındaki yardımcının kartı ekran kenarında, onun yönünde durur; tehdit okları her zaman öndedir. 40 m'den uzaklaşan firarinin kartı kırık halkalı ve 1 Hz nabızlıdır, Çığırtkan onu döndürünce halka kapanır. Ku kadraj dışına ilk çıktığında: «Ku'nun kartı onun yönündedir.»
- **Düşüş ([K74](/docs/source/design/decisions#k74)).** Uldın ve Berik Düşüş zarı atmaz: II'nin çekirdek yoldaşlarıdır. Öteki firari Düşüş'te Normal'de %30, Zor'da %50 olasılıkla ölür, Hikâye'de ölmez; ölen Ad İpi'ne geçer.
- **II'ye geçiş.** Firariler Mete'yle gelir, II'nin onluğudur. Uldın Yakınlık ≥3 ile, Berik gelip satmadıysa çekirdek yoldaş olur; Yakınlık II'den yoldaşın onayıdır, ayrı bir onay ekseni açılmaz ([K72](/docs/source/design/decisions#k72)). Mete firarisiz kaçtıysa Uldın 4 Haziran 209'da Islık Ordugâhı'na kendi gelir: «Beni orada bıraktın.» Ku Kışlak'ta kalır; II'nin köpeği Karabaş'tır. Sistemin bütünü: [Yoldaşlar](/docs/gameplay/companions).

```varlik
ui_companion_card, ui_offscreen_indicator, ui_animal_card
```

## Mete neyi yapar, neyi yapamaz

Rehinedir: hareket serbest, her hareketin bedeli var. Duvar yoktur, görünür kural vardır.

| Konu | Yapabilir | Yapamaz ya da bedeli |
|---|---|---|
| Dolaşım | Vadinin her yerine gider | Çetelesiz Kızıl Kazık'ı geçince sayaç, sonra Kazık Atlısı: geri, Güven −2 |
| Ses | Durunca çan susar, el çanda çömelince kısılır | Yürü 14 m, koş 32 m, el çanda çömelik 2 m duyulur; Keçe Tıkaç ×0,4; çan ancak Son Gece kesilir |
| Silah | Oyuncak yay; Gün III ödünç yay; Gün IV Farnak'ın sadağı; balta, sapan, gece meşale | Rehineye silah verilmez: ödünç yay akşam geri alınır, sadak yaysızdır; gizli silah yalnız yan görevden: kendi bıçağı, kurgan akinakesi |
| Öldürmek | Serbest | Korku +2, XP yok, kan görünmez |
| At | Gün I'den Yakve'ye biner; Son Gece Adak Aygırı'nı alıp adını koyar | Kendi atı yoktur; eyer çalınmaz, Keçe Avlusu'nda yapılır |
| Yol | Menzil ve Kantu'nun arabası; Yolcular'dan sonra kendi sürer | Kantu 21:00–07:30 uyur; Gün V yalnız yaralı seferi, Son Gece hat kapalı |
| Yapı | Yeni Yurt'a malzeme taşır, pedde 1 el çalışır: 3 elden 4'e hız %33 artar | Yurdu Nanay ve iki Yapı Eri kurar; tündük Gün III'ü, ocak Toy'u bekler |
| Zaman | Bekle (en çok 12 oyun saati), ateş başında Dinlen, Akşam ve Gece döşekte Uyu | Günün ana işi bitmeden uyuyamaz; Gün V gecesi uyku yok |
| Yemek | Tayın 2 Aş, akşam kasesi | Ambardan günde 1'den fazla aşırma fark edilir: Güven −4; Tokluk <25 ise stamina dolumu ×0,6 |
| Düşüş | Can bitince Umay Eşiği, son barınakta uyanış | Yakalanma yükleme değildir: yurda dönüş, saat +60 dk, o çıkış kapanır, +1 nöbetçi |
| Hüküm | Çığırtkan, çentik çubuğu, çizmedeki bıçak, zula ve çetele yarımları kalır | Gün V'te heybe Ambar'a gider; zula da el konmayanlardandır ([K38](/docs/source/design/decisions#k38)) |

## Son: Eşik ve Ev

- **Şafak Sırtı (≥07:04).** Fırtına kesilir, ilk açık gök; güneş 07:14'te doğar. Kartal geçer: ilk açık göğün parçasıdır, her dalda (K65). Mete son çentiği atar, çubuğu kırar; uzakta Hun işaret ateşi.
- **Perde kartı.** Kefil sonuçları, Ocak x/24, Direk x/14, Erzak, Yurt aşaması, rota, firarilerin adları, Ad İpi düğümü, Kut, Korku ve ozan dörtlüğü; dörtlük kartta okunan metindir, şarkı değildir. Anlatıcı: «O sesi bütün bozkır duydu. Bir tek o duymadı.» Sonra: «Kış bitti, o hâlâ yoldaydı.»
- **Ev.** 11 Nisan MÖ 209 (sayımın 1.171. günü), bahar, Tanhu Kampı'nda Teoman'ın ocağı; Önsöz gecesinin ertesi günü. Işık 14:46,2'nin ikindisidir; Godot menüsünün gece ışığı Ev'in ışığı değildir ([K76](/docs/source/design/decisions#k76)). Ev menü dünyasını yüklemez: Tanhu Kampı'nın kendi küçük dünyasında uzak karedir; Çocuk oyuncu değildir, atlıya su götürmez ([K106](/docs/source/design/decisions#k106)). Mete küllü boz aygırla güney patikasından çıkar; Göl Obası'na (ana kamp) hiç gelmez (K6). Teoman: «Seni öldürdüklerini duydum.» Mete: «Duydun.» Levha takılıysa Teoman levhaya bakar. [Lan Hatun](/encyclopedia/lan-hatun) seçim sunmaz, tek satır söyler: «Kırk iki gün dedim. Bin iki yüz on iki oldu.»
- **Sonra.** Kart: «II. Perde yakında / Act II is coming». Kayıt korunur, menüye dönülür, Devam Et kartı gösterir ([K7](/docs/source/design/decisions#k7)). Ev'den sonra serbest dolaşım yoktur: Mete'nin denetimi II'de atlas bacağında başlar. II yazılınca kartın yerine Akan Kronik gelir: 11 Nisan → 1 Haziran 209, 30 sn, Kronik Kararı yok.

## Sonraki perdelere kancalar

Perdenin altı antı sonraki perdelerde okunur; IV'te tutulan ant Kut +1, bozulan Kut −1 yazar, Hereka'nın antı ±2'dir. Hereka'nın «Adlar»ı IV'te Çukur'da (Bilinen Adlar ≥16 ise tutulur), Farnak'ın «Kâse»si Kemik Boğazı'nda ve IV'te Nanay'ın ocağında, Amaga'nın «Yol»u IV'ün Batı Yolu'nda (yol dolunaydan önce verilir, Yüeçiler yok edilmez, batıya çekilir), Mene'nin «El»i IV'te batı yolunun güzergâhında, Adak Aygırı'nın antı IV'ün Adak'ında (Mete önce ata bakarsa tutulur) okunur. Erlik'in Kül Borcu II'de Huyan Hatun'un soğuk ocağında, yerleşimde Kül Ödemesi'nde ve VI'da Kıl Köprü'nün eninde okunur. Antların sözleri [Gün Gün](/docs/story/act-1-days#antlar-ve-bayraklar) sayfasındadır.

İlk onluk ve Refleks II'nin onluğunu ve disiplin tabanını kurar. İlk Islıklı Ok II'de Yay dalını açar. Sürü Alışkanlığı, At Bağı ve aygırın adı talimde okunur. Levha, Eskam'a gösterilenler ve «Beni gördü» II'de Teoman ve Eskam'la karşılaşmaya gider. Kefiller, Sazlık, adlar, yurt ve çan IV'ün Kışlak dönüşündedir; Güven ve Kış Hesabı arşive geçer, orada okunur. Tam liste [act1.md §16](/docs/source/design/act1#16-sonraki-perdelere-kancalar), IV'teki karşılıkları [IV. Perde](/docs/story/act-4) sayfasındadır.

**Tanhu 1'den fark.** Tek gün yerine altı gün; 58×40 m yerine 1.400×1.050 m. Eski kadro, sahne ve replikler yok; ayna, bilek ipi, çocuğa bıçak sahnesi, kuş boss, şeritli kovalama ve kazara kemik ıslık yok. [K4](/docs/source/design/decisions#k4) gereği gümüş ay atı, geyik taşlarında yıldız halkası, can borcu pazarlığı, Ambar'dan çalınan eyer, tuzla alıştırma ve Korku 6'nın Erlik fısıltısı kalktı; yerlerine Adak Aygırı, Yar Bakışı'nda Gök Açılır, Kül Borcu, Keçe Avlusu'nda yapılan eyer, kutlu ot ve kor çıtırtısı geldi. Mene armağan vermez: Çığırtkan'ı oyuncu onun oyuncağından kendi yontar. Ana duası seçimi Tanhu 1'in olduğu için kalktı (K32).

## Oyunda şu an

> [!DURUM]
> Oyunda: I. Perde yok. Yeni Oyun bugün Önsöz'ü, Çocukluk'u, Köprü 1'i, oluşturucuyu ve Köprü 2'yi oynatır; sonra kara ekranda «I. Perde: Çan» ve «Yapım aşamasında.» kartı çıkar, açılış ekranı gelir; oluşturulan Mete kampa inmez ([K99](/docs/source/design/decisions#k99)). Kışlak, görev, diyalog, envanter, toplama, zanaat, saat ve takvim (gece sabittir), hava, emek ve aşamalı kurulum, gizlilik, dövüş, atla binicilik ve kovalamaca Godot'da yok. Perdenin dayanacağı temel hazır: takip kamerası (eğim 38°, görüş 36°, 28 m; Q/E ve sağ tıkla döner, tekerlekle 14–40 m; eğim oyuncuya açık değil), Çocukluk'un çocuk denetleyicisi, koyuna binme ve oyuncak yay, 10 yuvalı kayıt, ayarlar, Destan Kitabı, boyalı görünüm. Mete'nin Meshy modeli var (iskelet; yürüme, koşma ve oturma klipleri); rehine kılığı ve pelerin rengi yok. Teoman, Lan Hatun, Ağabey, yaşlı Hereka ve Sayıcı'nın da modeli var. Ateş başında bugün Ağabey oturur (K37); Mete ana kampa hiç gelmez, Ev Tanhu Kampı'ndadır (K106). Prototipte denendi: saat, hava, emek yasası ve yapı aşamaları; Godot'a taşınmadı ([oyun-durumu.md](/docs/source/design/d3/game-state)).

## Yol Haritası

Perdenin altı fazı ve maddeleri Yol Haritası'ndan canlı gelir. K11'in kapısı dikey dilimdir (`act-1-p4`): Gün I'in ilk 15 dakikası ve Tipi oynanır, kullanıcı onaylamadan sonraki fazlar açılmaz ([K11](/docs/source/design/decisions#k11), [K69](/docs/source/design/decisions#k69)).

```ilerleme
act-1
```

- Doğrulanacak: satırlar taslaktır; perde metni dikey dilimin ölçümünden sonra kilitlenir, A ve B dilimi ancak kilitten sonra seslendirilir (K38, K61) ([Yol Haritası](/roadmap#item-act1-text-lock)).
- Doğrulanacak: süre, kadraj ve kışın görünüşü dikey dilimde ölçülür; dakikalar ilk tahmindir, kamera sayıları Godot kamerasının değerleriyle betikte hesaplandı, oynanmadı ([Yol Haritası](/roadmap#item-vertical-slice)).
- Doğrulanacak: Amaga'nın Yurdu Hane boyunda kalır; Hüküm karesi dikey dilimde göz onayından geçer ([Yol Haritası](/roadmap#item-slice-measure)).
- Doğrulanacak: Kara Boran'da temiz sürüş ≥3 dk'dır ([K10](/docs/source/design/decisions#k10)); ortalama 6–9 dk tahmindir, ilk testlerde ortalama 5 dk'nın altında kalırsa zemin çarpanları %10 düşer ([Yol Haritası](/roadmap#item-tipi-prototype)).
- Doğrulanacak: konuşmada kısmanın son ayarı kulakla yapılır (K78) ([Yol Haritası](/roadmap#item-act-1-audio)).
- Doğrulanacak: on firarinin kaması ilk parti ölçümüdür: Mete ve on firari ≤16,7 ms, %95 ≤22 ms (K74) ([Yol Haritası](/roadmap#item-party11-lod)).

Kullanıcının onayını bekleyenler [Karar Bekleyenler](/docs/general/pending-decisions) sayfasındadır: Hereka'nın sesi; Ardokşa, Kujul ve Atşo'nun sesi; Uldın ve Berik'in sesi (16 yoldaşla birlikte); ilk 12 hayvan türünün Meshy işi ve toplu üretimden önceki üç yol denemesi. Kredi harcayan her çekim önce kullanıcıya sorulur, seslendirme metin kilidinden sonradır ([K87](/docs/source/design/decisions#k87)).

## Kaynaklar

- [act1.md](/docs/source/design/act1): [§1](/docs/source/design/act1#1-oncul-sure-ton), [§2](/docs/source/design/act1#2-oyun-dongusu-ve-eksenler), [§3](/docs/source/design/act1#3-kadro), [§4](/docs/source/design/act1#4-dunya), [§6](/docs/source/design/act1#6-ana-gorevler), [§7](/docs/source/design/act1#7-yan-gorevler), [§9](/docs/source/design/act1#9-sistemlerin-act-1-yuzu), [§9.7](/docs/source/design/act1#9-7-takipci-altyapisi), [§14](/docs/source/design/act1#14-ses), [§16](/docs/source/design/act1#16-sonraki-perdelere-kancalar), [§18](/docs/source/design/act1#18-dogrulama-durumu)
- [story.md §1](/docs/source/design/story#1-oncul-ve-ton), [§7](/docs/source/design/story#7-i-perde-can), [§7.2](/docs/source/design/story#7-2-acilis-ve-2-aralik-3), [§8.4](/docs/source/design/story#8-4-kislak-i-perde-ve-iv-un-donusu), [§11.3](/docs/source/design/story#11-3-iv-perde-borc-the-debt)
- [time.md §9](/docs/source/design/time#9-i-perde-saatle), [companions.md §2.1](/docs/source/design/companions#2-1-i-perde-rehinelikte-yardimcilar), [progression.md §15](/docs/source/design/progression#15-perde-gecisi), [audio.md §3](/docs/source/design/audio#3-muzik-durumlari), [godot.md §9.5](/docs/source/design/godot#9-5-i-perde-can-act-1), [mete-tarih.md §3.5](/docs/source/research/mete-history#3-5-yol-ve-hesap) (gösterinin takvimi)
- [decisions.md](/docs/source/design/decisions): K4, K7, K10, K11, K13, K32–K39, K42, K43, K45, K46, K48, K50, K51, K58–K61, K65, K67–K74, K76–K78, K82, K83, K87

İlgili sayfalar: [I. Perde: Gün Gün](/docs/story/act-1-days), [Perde Arası: Akan Kronik](/docs/story/chronicle), [Hikâye Omurgası](/docs/story/spine), [Kadro](/docs/story/cast), [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests), [Bölgeler](/docs/world/regions), [II. Perde](/docs/story/act-2).
