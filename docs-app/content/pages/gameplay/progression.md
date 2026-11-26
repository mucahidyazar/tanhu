---
title: Seviye ve Gelişim
order: 30
status: tasarim
summary: 'Oyun 20 seviyedir, her perdenin bandı vardır (I 1–5, II 6–8, III 9–11, IV 12–14, V 15–17, VI 18–20); XP görev, iş, keşif, av ve tariften gelir, insan öldürmek XP vermez; II–VI''nın XP''si görev listesine bağlıdır; her beceriyi bir insan öğretir; Kut ve Korku ayrı iki eksendir; yoldaşın seviyesi yoktur (K43, K82, K88).'
sources:
  - docs/design/decisions.md
  - docs/design/progression.md
  - docs/design/act1.md
  - docs/design/story.md
  - docs/design/army.md
  - docs/design/companions.md
  - docs/design/d3/oyun-durumu.md
---

## Özü

Mete 20 seviyede büyür. Her seviye bir stat puanı, bir beceri puanı ve 5 Can verir. Puan tek başına beceri açmaz: öğretecek bir usta gerekir. Moral eksenleri sayı olarak görünmez: Kut altın güneş, Korku kızıl kordur. Eksik beceri yolu kapatmaz, yalnız bedelini değiştirir. Ölüm ve yeniden başlatma yoktur. Önsöz, Çocukluk ve Yola Çıkış XP vermez; I. Perde seviye 1 ve 0 XP ile açılır.

> [!NOT]
> «20 level sınırı olacak»

Tasarım bu notla aynıdır: seviye 20'de biter, her perdenin kendi bandı ve tavanı vardır ([K43](/docs/source/design/decisions#k43)).

## Seviye ve XP

Perde tavanı gerçek kuraldır: seviye atlamayı durdurur, XP'yi silmez; fazla XP birikir, perde geçişinde seviyeler peş peşe gelir. Bantlar tam oyuncunun o perdede aldığı seviyelerdir: I 1–5, II 6–8, III 9–11, IV 12–14, V 15–17, VI 18–20. Seviye 20'den sonra her 1.800 XP +1 beceri puanı verir, en çok 3 kez.

| Seviye | Birikimli XP | Can tabanı | Açılan kademe | Perde tavanı |
|---|---|---|---|---|
| 1 | 0 | 100 | T1 | |
| 2 | 250 | 105 | | |
| 3 | 800 | 110 | T2 | |
| 4 | 1.700 | 115 | | |
| 5 | 3.000 | 120 | | I |
| 6 | 4.600 | 125 | T3 | |
| 7 | 6.600 | 130 | | |
| 8 | 9.000 | 135 | | II |
| 9 | 11.800 | 140 | T4 | |
| 10 | 15.000 | 145 | | |
| 11 | 18.600 | 150 | | III |
| 12 | 22.600 | 155 | T5 | |
| 13 | 27.000 | 160 | | |
| 14 | 31.800 | 165 | | IV |
| 15 | 37.000 | 170 | T6 | |
| 16 | 42.600 | 175 | | |
| 17 | 48.600 | 180 | | V |
| 18 | 55.000 | 185 | | |
| 19 | 61.800 | 190 | | |
| 20 | 69.000 | 195 | | VI |

**XP nereden gelir.** İnsan öldürmek, ham toplama ve ganimet hiçbir perdede XP vermez: yoksa kampta öldürmek en kârlı iş olur, Korku ekseni anlamını yitirirdi. Sonraki perdelerde değerler perde çarpanıyla büyür: II ×1,75, III ×2,6, IV ×3,5, V ×4,4, VI ×5.

| Kaynak | Taban XP | Sınır |
|---|---|---|
| Ana ve yan görev | Görev verisi | I'de 22 ve 23 görev; II–VI'da ana 12, 13, 14, 12, 14 ve yan 15, 15, 15, 15, 12 görev |
| İş Tahtası | 25; türün ilki +15 | Günde 3 iş sayılır |
| Bakış, Menzil, Taş Yığını | 10 | Bakış'a ilk varış, Menzil'in onarımı; Taş Yığını II'den, harita başına 2–4 |
| Yolcu | 35 | I'de Yolcular görevinde 3 kez; II'den günde en çok 3 |
| Av | 40 | Tür başına bir kez; II'den perde başına en çok 4 tür |
| Tarif | 20 | Tarif başına bir kez |
| Atlas düğümü | 20 | II'den, yeni iç haritaya ilk varış; sahnesiz Tanhu Kampı konağı XP vermez |
| Yapı tamamlama | 30 | II'den, yapı başına bir kez |
| Erzak teslimi | 40 | II'den, 100 kişi-gün başına, perdede en çok 4 |
| Küçük durak, Kaçak Ödül, Gecelik Kamp | 0 | Bilgi, mal, ad ya da Destan dizesi verir |
| Yoldaşın kişisel görevi, söyleşi, armağan | 0 | Ödülü bağdır ([K88](/docs/source/design/decisions#k88)) |

**Perde bütçesi görev listesine bağlıdır (K43).** II–VI'nın ana görev XP'si taban × görev sayısı × perde çarpanıdır: II 205 × 12 × 1,75 = 4.305; III 192 × 13 × 2,6 = 6.490; IV 178 × 14 × 3,5 = 8.722; V 206 × 12 × 4,4 = 10.877; VI 177 × 14 × 5 = 12.390. Keşif, yeni iç haritanın ilk varışı ve XP'li durak sayısından hesaplanır; yan görev sütunu perde toplamını tutan kalandır. Görev listesi değişirse bütçe yeniden hesaplanır ([progression.md §1.2](/docs/source/design/progression#1-2-perde-xp-butcesi)). XP'nin ana, iş, yan ve keşif sütunlarına dağılımı [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests#gorev-yapisi) sayfasındadır.

| Perde | Perde toplamı | Ana yol + iş, birikimli | Seviye | Tam oyuncu, birikimli | Seviye |
|---|---|---|---|---|---|
| I | 4.575 | 2.865 | 4 | 4.575 | 5 |
| II | 7.175 | 7.870 | 7 | 11.750 | 8 |
| III | 10.800 | 15.420 | 10 | 22.550 | 11 |
| IV | 14.400 | 25.522 | 12 | 36.950 | 14 |
| V | 18.000 | 38.099 | 15 | 54.950 | 17 |
| VI | 19.400 | 52.489 | 17 | 74.350 | 20 |

Zorluk ana yol ve işe göre ayarlanır. Tam oyuncu bir, en çok üç seviye öndedir: yan içerik ödüldür, zorunluluk değil. Av ve tarifin ilk XP'si sütunlarda yoktur, tam oyuncuyu tavana erken götürür: I'de 11 tür × 40 ve 12 tarif × 20 (≈680 XP); II–VI'da tür başına ilk av 40 × perde çarpanı, perde başına en çok 4 tür (II 280, III 416, IV 560, V 704, VI 800 XP). Tam oyuncu VI'nın %72'sinde seviye 20 olur; kalan 5.350 XP 2 aşkın puan eder.

Doğrulanacak: II–VI'nın görev başına tabanı, yan görev XP'si ve İş sütunu tahmindir; görev verisi yazılınca ve perde oynanınca ölçülür ([II](/roadmap#item-act2-progression), [III](/roadmap#item-act-3-story), [IV](/roadmap#item-act-4-story), [V](/roadmap#item-act-5-story), [VI](/roadmap#item-act-6-story)).

## Statlar

Beş stat vardır, başlangıçta hepsi 3. Köken +1 verir, seviye başına +1 dağıtılır, 20. seviyede toplam 35 olur. Tek stat tavanı I. Perde'de 7, her perde +1, VI. Perde'de 12. Altıncı stat yoktur: Kut, Korku ve At Bağı zaten üç ayrı eksen taşır.

| Stat | Puan başına (3'ün üstü) | Eşikler |
|---|---|---|
| Bilek / Grip | Yük +3, vuruş ve yapı hasarı +%6, Can +2 | ≥5 Hun Yayı tam çekiş; ≥7 Ağır Yay; ≥10 Ulu Yay |
| Soluk / Wind | Stamina +6, dolum +%4, koşu gideri −%2 | ≥5 Kürtük Yürüyüşü önkoşulu; ≥7 Tokluk <25 stamina cezası yok; ≥9 yara cezası yarım |
| Ayak / Foot | Gürültü −0,2 m, yürüyüş +%1,2, koşu +%1,5, çömelik +%2, savuş bedeli −0,5 | ≥4 Tündük çıkışı; ≥6 tırmanma ×0,6; ≥8 savuş iki hak |
| Göz / Eye | İz ve kaynak sezgisi +3 m, sapan +1 m, yay yayılması −%5, yay menzil ve hasarı +%2 | ≥5 nöbetçi `?` işareti 6 m uzaktan; ≥7 ok çizimi +0,1 sn; ≥9 hareketli hedefte öne alma |
| Söz / Word | Güven +%6, birlik sadakati +%6, takas oranı −%3 | ≥5 ek seçenekler, ayrılan yoldaşı geri kazanma; ≥7 elçi ve kurul seçenekleri, yoldaşa «Söz ver» ve «Barıştır»; ≥9 yeni üye ve yeni yoldaş bağı +2; ≥11 kurultayda ek oy |

| Puan | Yük | Vuruş × | Stamina | Yürü | Koş | Savuş bedeli | Sezgi m | Sapan m |
|---|---|---|---|---|---|---|---|---|
| 3 | 21 | 1,00 | 100 | 4,40 | 7,60 | 15 | 15 | 18 |
| 5 | 27 | 1,12 | 112 | 4,51 | 7,83 | 14 | 21 | 20 |
| 7 | 33 | 1,24 | 124 | 4,61 | 8,06 | 13 | 27 | 22 |
| 9 | 39 | 1,36 | 136 | 4,72 | 8,28 | 12 | 33 | 24 |
| 12 | 48 | 1,54 | 154 | 4,88 | 8,63 | 10,5 | 42 | 27 |

**Köken** oluşturucuda seçilir, değişmez: Zırhlı Atlılar Arasında (Bilek +1), Otağda Yetişen (Söz +1), Yılkı Beyi (Ayak +1, Bağ +10) ([K104](/docs/source/design/decisions#k104)): veliahdın nasıl yetiştiğini anlatır.

**Ozan'a Anlattır.** II. Perde'den her perde başında 2 hak gelir, birikir. Mete'nin ocağının ozanının ateşinde bir hak bir stat puanını taşır ya da bağımlısı olmayan bir beceriyi geri alır. Beceriyle gelen eksen değişimi dönmez. Ozan perdeye göre değişir ([K79](/docs/source/design/decisions#k79)): II–III'te Göl Obası'nın ozanı Mete'nin ocağına gelir, Köz Kabı'yla değil ([K106](/docs/source/design/decisions#k106)); III→IV Kroniği'nde ölür, kopuzu Çocuğa kalır; IV–VI'da Çocuk genç ozan olarak çalar. I. Perde'de yoktur.

## Beceri dalları

Yedi dal, 93 beceri: 90'ı puanla, 3'ü bedava. Bütün oyunda 30 puan (ve en çok 3 aşkın puan) kazanılır, satın alınabilirin yaklaşık %33'ü. Bir dalın tamamı 11–16 puandır: en büyük iki dal bütün puanı yer.

| Dal | Beceri | Konu | Açıldığı perde |
|---|---|---|---|
| Emek / Labour | 11 | Yük, erzak, onarım | I |
| Gölge / Shadow | 13 | Gece, iz, soluk | I |
| Eyer / Saddle | 13 | At, araba, yol | I |
| Bıçak / Blade | 13 | Yakın dövüş, bayıltma, kesiş | I |
| Söz / Word | 14 | Güven, ant, kurultay | I |
| Yay / Bow | 12 | Kiriş, temren, menzil | II |
| Buyruk / Command | 17 | Birlik, düzen, yasa | II |

Kademe seviyeye bağlıdır: T1 seviye 1, T2 3, T3 6, T4 9, T5 12, T6 15. Etkin beceri ve sarf eşyası 6 yuvalı çubuğa (1–6) girer; `F` sapan sabittir. I. Perde'de `Q` Çığırtkan'dır: rehinenin değiştireceği silahı yoktur. II'den `Q` hızlı silahtır (yay ile yakın silah arasında), Çığırtkan çubuğun 6. yuvasına geçer, oyun kolunda RB kalır ([K82](/docs/source/design/decisions#k82)).

| Perde | Seviye (ana yol → tam) | Seviye puanı | Görev puanı veren görevler | Birikimli beceri puanı | Stat tavanı | Açılan beceri |
|---|---|---|---|---|---|---|
| I | 1 → 4 / 5 | 4 | Sürü Okulu, Toy | 6 | 7 | 20 |
| II | → 7 / 8 | 3 | Islığı Yap, Tanhu'nun Atı | 11 | 8 | 29 |
| III | → 10 / 11 | 3 | Boş Toprak, Dailin | 16 | 9 | 18 |
| IV | → 12 / 14 | 3 | Çukur, Batı Yolu | 21 | 10 | 14 |
| V | → 15 / 17 | 3 | Yalandan Kaçış, Yedi Gün | 26 | 11 | 11 |
| VI | → 17 / 20 | 3 | Kurultay | 30 | 12 | 1 |

## Her beceriyi bir insan öğretir

Puan tek başına yetmez: usta, seviye ve önkoşul birlikte aranır. İlk seviye ekranı bu yüzden açılır ve hiçbir şey öğretmez: «Puanın bekler. Her beceriyi bir usta öğretir.» Ekran ustaları ve koşullarını gösterir. Gizli kural yoktur.

![Ardokşa: Sırt Yükü ve Hesap Gözü'nün ustası](/media/docs/media/ui/portraits/ardoksha.webp)

| Durum | Koşul | Ekranda |
|---|---|---|
| Gizli | Adı saklı beceri, Islıklı Ok yok | Siluet, yalnız ipucu |
| Kilitli | Perde ya da önkoşul tutmuyor | Ad ve ipucu; açıklama gizli |
| Öğretilebilir | Perde tamam, usta koşulu tutmuyor | «Usta: {ad}. {koşul}» |
| Hazır | Usta tamam | Puan ve seviye varsa alınır |
| Öğrenildi | Satın alındı | Etkinse çubuğa konur |
| Usta yitti | Koşul Hüküm'e dek tutmadı | «Usta yitti. II. Perde'de başkası öğretir.» |

**I. Perde'nin ustaları.** 18 öğrenilebilir, 2 bedava beceri; 6 puan: 18'den 6'sı, seçim gerçektir. Koşulu tutan beceri hazır kalır, puan sonra da harcanır.

| Dal | Beceri ve usta |
|---|---|
| Emek | Sırt Yükü ([Ardokşa](/encyclopedia/ardoksha)), Tam Vuruş ([Kujul](/encyclopedia/kujul)), Hesap Gözü (Ardokşa), Onarım ([Nanay](/encyclopedia/nanay)), Ocak Bilgisi ([Hereka](/encyclopedia/hereka)) |
| Gölge | Kar Adımı ([Mene](/encyclopedia/mene)), Nöbet Okuma ([Opia](/encyclopedia/opia) ya da [Palak](/encyclopedia/palak)), Kemik Atışı (Mene); bedava El Dili (Mene) |
| Eyer | Rüzgâr Altı ([Farnak](/encyclopedia/farnak)), Dizle Sürme ([Uldın](/encyclopedia/uldin)), Soluk Paylaşımı ([Kantu](/encyclopedia/kantu)), Arabacı (Kantu); bedava Binicilik (Farnak) |
| Bıçak | Savuş (Palak), Uyku Kolu (Uldın), Sapan Eli (Farnak) |
| Söz | Kışlak Ağzı ([Atşo](/encyclopedia/atsho)), Kefil Sözü ([Amaga](/encyclopedia/amaga)), Yalan Yüz ([Eskam](/encyclopedia/eskam)) |

**II. Perde ve sonrası (K43).** Rolü önce ilk onluktaki adlı kişi üstlenir: kendi firarin öğretiyorsa seviye şartı −1'dir. Usta kaybolursa eşdeğeri bir perde sonra gelir. Kişiler Hun ad kuralındandır ([K37](/docs/source/design/decisions#k37), [story.md §14.1](/docs/source/design/story#14-1-ustalar)).

| Dal | Rol | Önce kim (I. Perde yankısı) | Varsayılan usta | Geliş |
|---|---|---|---|---|
| Emek | Ambarcı | [Tola](/encyclopedia/tola) yaşıyorsa o | [Moyan](/encyclopedia/moyan): Lan soyundan dul, Lan Hatun'un ambarını tutar | II, Lan Hatun'un hanesiyle |
| Gölge | Keşif Eri | [Berik](/encyclopedia/berik) geldi ve satmadıysa o | [Guşi](/encyclopedia/gushi): on binin gözcüsü | II, Islık Ordugâhı |
| Eyer | Seyis | Yolcular görevi bittiyse yedek at hazır gelir | [Şulü](/encyclopedia/shulu): Teoman'ın sürüsünün seyisi, otuzlarında | II, armağan sürüyle |
| Yay | Yaycı | Yok | [Yudan](/encyclopedia/yudan): Tanhu Kampı'nın yaşlı yaycısı | II, Islığı Yap; III'te Okçu Yurdu'nun ustası |
| Bıçak | Kılıç Ustası | Uldın ilk onluktaysa o | [Huluzi](/encyclopedia/huluzi): Lan soyunun kılıççısı | II (Uldın) ya da III, avlu göçüyle |
| Söz | Töreci | Yok | [Tuçi](/encyclopedia/tuchi): Lan soyundan töre bilen | III, avlu göçüyle |
| Buyruk | Eski Binbaşı | Satır önkoşulları I. Perde kişilerini okur | [Dulongçi](/encyclopedia/dulongchi): Teoman'ın binbaşısı, altmışında | II, on binle; V→VI Kroniği'nde ölür |

- **Usta beklemeyen beceriler.** Söz dalının ustası III'te gelir; II'nin iki Söz becerisi onu beklemez: İki Dil usta istemez, I'in mirasıdır; Ozan Dostu'nu Mete'nin ocağının ozanı öğretir (K79). Dulongçi V→VI'da öldüğü için VI'nın Tümen Çağrısı usta istemez. Sayım (Birlik Kartı) hem bedavadır hem usta istemez.
- **Dal öğretmeyen ustalar.** Kuşçu [Sungur](/encyclopedia/sungur) (IV) doğanı ve Kuşhane'yi getirir. Ocak kamı ve otacı [Dangyu](/encyclopedia/dangyu) (IV–VI) Otacı Yurdu'nu kurar ve Kamın Alameti'ni okur; VI-b'de ocağına çekilir, ardılı [Liuli](/encyclopedia/liuli) Otacı Yurdu'nu alır.
- **Usta yoldaş (K70).** Uldın (Bıçak) ve Berik (Keşif Eri) II'den çekirdek yoldaştır: partideyken de öğretir, beceri ateş başında ya da Defter'den alınır; partide değilse bulunduğu yerde öğretir. Subay olan ya da hane başı olup partiden çıkan usta kaybolmuş sayılmaz. Usta yalnız ayrılıkla yiter; eşdeğeri (Huluzi, Guşi) bir perde sonra gelir.
- **Yerleşimde.** Ambarcı akında kap kaybını ×0,75 yapar; Seyis ordugâhta kışın atın yağına +1/gün verir, V'te dört renk atı sayar; Keşif Eri III'te Gözcü Konakları'nın başıdır; Töreci toplantıda söz alır, sayım çetelesini tutar; Dulongçi Baş Talimi'ni yürütür. Kâhya II–IV [Lan Hatun](/encyclopedia/lan-hatun), V'ten [Yimo](/encyclopedia/yimo)'dur; Kâhya usta değildir, işi o dağıtır.

## Kut ve Korku

İki eksen birbirinden bağımsızdır: biri ötekini silmez. Kut [Tengri](/encyclopedia/tengri)'nin ekseni, «Göğün rızası»dır; Korku [Erlik](/encyclopedia/erlik)'in gölgesidir, Hun ağzında Kara Nama ([K35](/docs/source/design/decisions#k35)). Sayı görünmez, dört parlaklık kademesi görünür (0–3, 4–7, 8–13, 14+). Her eşik ilk geçildiğinde bir kez kart açar. Her kaynak bir kez sayılır: tekrarlanan eylem eksen vermez. Korku yalnız üç yolla söner: ant tutmak, esir salmak, yağmalanan sürüyü geri vermek; her biri perdede bir kez −1. Kut ant bozulunca düşer. Avda öldürmek eksen vermez.

| Perde | I | II | III | IV | V | VI |
|---|---|---|---|---|---|---|
| Kut tavanı | 16 | 20 | 24 | 28 | 32 | 36 |
| Korku tavanı | 13 | 18 | 23 | 28 | 32 | 36 |

| Eşik | Okunduğu perde | Kut | Korku |
|---|---|---|---|
| ≥4 | I | Firari ilk çağrıda gelir | Nöbetçi ilk görüşte 0,5 sn duraksar; Güven kazancı −%10 |
| ≥5 | I | Tipide at staminası gideri −%15; Umay Eşiği erzak almaz | |
| ≥6 | I | Tipide yıldız açıklığı yönü gösterir: dönmeyen nokta ve çevresinde iki at | Çağrıya kor karışır: Çığırtkan çağrısında arayüzün kızıl koru bir an parlar, sese kısık bir kor çıtırtısı karışır, söz yoktur; çağrı başına refleks +2 |
| ≥8 | I | «Görmedim.» ve merhamet seçenekleri | Firariler emirsiz atar |
| ≥10 | II | Yeni bölgede Güven +5; Divan'da «Göğün diktiği» unvanı | Düşman ilk görüşte moral −10; Güven kazancı −%20 |
| ≥12 | II | Bölgede bir kez [Umay](/encyclopedia/umay) Eşiği yaraları da kapatır | Zorla Erzak seçeneği: erzak +50, Kut −1, sadakat −2, bölgede Güven −5 |
| ≥14 | III | Firar yok: sadakat tabanı 25, moral tabanı 40 | Moral tabanı 30; Kut <4 ise firar eşiği sadakat <40; çoban köpekleri Mete'ye hırlar |
| ≥16 | III | Düşman teslim şansı +%10 | |
| ≥18 | III | | Erlik'in Yolu: atlasta bedava anlık yolculuk; her kullanımda Korku +1 ve bir ocak söner |
| ≥20 | IV | Kurultayda +1 oy | |
| ≥22 | IV | | Düşman moral −20; teslim olanı öldürme seçeneği görünür |
| ≥24 | V | Sancak halkasında üye +%1 Can/sn | |
| ≥28 | V | | Kut kazançları ×0,5: Erlik'in gölgesi |

Kut ≥30 ve Korku ≥34'ün eski «son» etkisi kalktı: oyunun son adı yoktur, Son Sayım kartı yolu tek satırla okur ([K32](/docs/source/design/decisions#k32)). Korku ≥6'nın etkisi de Tanhu 1'in eşiğine benzediği için değişti ([K4](/docs/source/design/decisions#k4)).

**Dört Yol (II. Perde'den).** İki eksen birlikte okunur. Aradaki değerlerde bonus yoktur. Yolun adı Son Sayım kartının «Yol» satırıdır; ozanın şarkısı yolu söylemez. Eski iki ad Tanhu 1'in son adlarına denk düştüğü için değişti, koşul ve etki aynı kaldı (K32).

| Yol | Koşul | Etki |
|---|---|---|
| Tan Yolu | Kut ≥10, Korku <6 | Güven ×1,1; moral +10; Umay Eşiği birliği de toparlar |
| Çetele Yolu | Kut ≥10, Korku ≥10 | Tepki −0,1 sn; düşman moral −10; adlı er ve kişi bağı kazancı ×0,8 |
| Kor Yolu | Kut <6, Korku ≥10 | Düşman moral −15; yeni atlı ×1,5; Düşüş bedeli ×2; sadakat kazancı ×0,7 |
| Toz Yolu | Kut <6, Korku <6 | Görülme ×0,9, takas +%10; ordunun yanında gezen atlı ×0,7 |

Tan Yolu doğan güne eğilen Tanhu'nun yoludur; Çetele Yolu söz de korku da sayılan borcun yoludur. Yol yoldaşın sözünü değiştirir, sayısını değiştirmez: Çetele Yolu'nun ×0,8'i çekirdek yoldaşa işlemez, Toz Yolu'nda parti sınırı 10 kalır ([progression.md §5.4](/docs/source/design/progression#5-4-dort-yol-ii-perde-den)).

## Yoldaşın gelişimi

Yoldaşın seviyesi, XP'si, stat'ı ve beceri ağacı yoktur; seviye yalnız Mete'nindir ([K72](/docs/source/design/decisions#k72), [K74](/docs/source/design/decisions#k74)). Güç perdeyle gelir: Can `50 + 6 × perde`'dir (II 62, III 68, IV 74, V 80, VI 86), savaşmayan ×0,8. Büyüme bağdadır: 1 düğümde kamp sahnesi 1, kişisel görev adımı 1 ve onbaşılık, 2'de yüzbaşılık, 3'te binbaşılık. Rol etkisi beceri gibi okunur, aynı rol üst üste binmez. Kişisel görev XP vermez (K88). Ayrıntı [Yoldaşlar](/docs/gameplay/companions) sayfasındadır.

## Zorluk

Zorluk oluşturucuda bir satırdır ([K13](/docs/source/design/decisions#k13)), kayda yazılır, oyunda kitap sayfasından değişir. XP, stat ve beceri zorlukla değişmez. Tam liste [progression.md §12](/docs/source/design/progression#12-zorluk)'dedir.

| Ayar | Hikâye | Normal | Zor |
|---|---|---|---|
| Alınan hasar | ×0,7 | ×1 | ×1,25 |
| Sıradan düşman canı | ×0,85 | ×1 | ×1,15 |
| Yara sınırı (Mete) | 5 | 3 | 2 |
| Nöbet algısı | ×0,7 | ×1 | ×1,3 |
| Ok çizimi | ×1,3 | ×1 | ×0,85 |
| Tam Vuruş halkası | ×1,3 | ×1 | ×0,8 |
| Stamina dolumu | ×1,15 | ×1 | ×0,9 |
| Tokluk azalması | ×0,7 | ×1 | ×1,15 |
| Kış Hesabı şafak kaybı | −6 | −8 | −10 |
| Düşüş bedeli | Yok | 1 erzak | 2 erzak |
| Düşüşte adlı er ölüm şansı | %0 | %30 | %50 |
| Elmas işaret | Hep | 45 sn sonra | Yok |
| Ay Saati (buz saati) | Yok: 05:45'te bekler | 06:40, Amaga 20:00 | 06:40, Amaga 21:30 |
| Hava işaret süresi | ×1,5 | ×1 | ×0,75 |
| Açıkta Uyku Zarı | Yok | ×1 | ×1,5 |

- **Yoldaş (K88).** Yoldaşın Yara sınırı her zorlukta 3'tür, Düşüş bedeli ona işlemez; alınan hasar çarpanı ona da işler. Çekirdek yoldaş, konuk ve Jiyu Düşüş zarı atmaz; zar yalnız adlı erindir ([K74](/docs/source/design/decisions#k74)).
- **Adillik.** Tehdit kenar oku ve kadraj sözleşmesi her zorlukta açıktır ([K39](/docs/source/design/decisions#k39)). Parti yanındaki Gecelik Kamp'ta nöbeti yoldaşlar tutar, Uyku Zarı atılmaz.

> [!DURUM]
> Godot'da yok: seviye ve XP, statlar ve köken, beceriler ve ustalar, seviye ekranı ve Defter'in Beceriler sayfası, Kut ve Korku, zorluk seçimi, Tokluk ve Yara. Serbest Gez bilerek ilerleme dışıdır: oyuncu Çocuk'tur, XP, stat ve beceri yoktur. Prototipte denendi (saf kod ve sınama, oyuna bağlanmadı): seviye eğrisi ve perde tavanları, türetilen değerler, 93 beceri tablosu, zorluk tablosu ([d3/game-state](/docs/source/design/d3/game-state)).

## Yol haritası

Seviye, statlar ve beceriler I. Perde'nin oyuncu ve dünya çekirdeği fazındadır ([seviye ve beceriler](/roadmap#item-levels-skills)); Güven, Kut ve Korku, Defter ve zorluk hikâye sistemleri fazındadır ([eksenler](/roadmap#item-axes), [Defter](/roadmap#item-ledger), [zorluk](/roadmap#item-difficulty)); II'nin seviye 6–8'i, Yay ve Buyruk dalları II'nin ana zincirindedir.

```ilerleme
act-1-p1
act-2-p4
```

## Kaynaklar

- [progression.md §0](/docs/source/design/progression#0-ozet), [§1](/docs/source/design/progression#1-seviye-ve-xp), [§1.6](/docs/source/design/progression#1-6-yoldasin-seviyesi-k72-k74), [§2](/docs/source/design/progression#2-statlar), [§3](/docs/source/design/progression#3-yara-ve-dusus), [§4](/docs/source/design/progression#4-beceri-sistemi), [§4.3](/docs/source/design/progression#4-3-usta-rolleri-ii-perde-ve-sonrasi), [§5](/docs/source/design/progression#5-kut-ve-korku), [§12](/docs/source/design/progression#12-zorluk), [§15](/docs/source/design/progression#15-perde-gecisi), [§17.2](/docs/source/design/progression#17-2-durum)
- [act1.md §2](/docs/source/design/act1#2-oyun-dongusu-ve-eksenler), [§11](/docs/source/design/act1#11-seviye-stat-beceri-xp), [§13](/docs/source/design/act1#13-zorluk)
- [story.md §10.2](/docs/source/design/story#10-2-perde-basina-sayilar), [§14.1](/docs/source/design/story#14-1-ustalar); [army.md §10](/docs/source/design/army#10-beceri-agaci-buyruk-command)
- [decisions.md](/docs/source/design/decisions): [K4](/docs/source/design/decisions#k4), [K13](/docs/source/design/decisions#k13), [K32](/docs/source/design/decisions#k32), [K35](/docs/source/design/decisions#k35), [K37](/docs/source/design/decisions#k37), [K39](/docs/source/design/decisions#k39), [K43](/docs/source/design/decisions#k43), [K72](/docs/source/design/decisions#k72), [K74](/docs/source/design/decisions#k74), [K79](/docs/source/design/decisions#k79), [K82](/docs/source/design/decisions#k82), [K88](/docs/source/design/decisions#k88)
- [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests), [Yoldaşlar](/docs/gameplay/companions), [Dövüş](/docs/gameplay/combat), [Ordu](/docs/gameplay/army), [Kadro](/docs/story/cast)
