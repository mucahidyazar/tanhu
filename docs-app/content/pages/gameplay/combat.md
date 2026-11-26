---
title: Dövüş
order: 40
status: tasarim
summary: 'Yakın dövüş tık-hedefli, yay sağ tuşla gerilir; dört hasar türü, belirli ganimet, yara ve Düşüş vardır, ölüm yoktur; I. Perde''nin silahı gizliliktir, II''den en çok 10 yoldaş yanında dövüşür, yoldaşın yara sınırı her zorlukta 3''tür (K44, K74, K88).'
sources:
  - docs/design/decisions.md
  - docs/design/progression.md
  - docs/design/act1.md
  - docs/design/companions.md
  - docs/design/army.md
  - docs/design/story.md
  - docs/design/survival.md
  - docs/design/economy.md
  - docs/design/fauna.md
  - docs/design/structures.md
  - docs/design/weather.md
  - docs/design/d3/oyun-durumu.md
---

## Özü

Düşmana tıklarsın, silah ona kilitlenir, Boşluk savuşur. Yay sağ tuşla gerilir, bırakınca atılır; sapan `F`'dedir. Kan görünmez: toz, keçe lifi, kor görünür. Ölüm yoktur: Can bitince yara yazılır, yara sınırı dolunca Umay Eşiği çalışır, son barınakta uyanırsın. İnsan öldürmek hiçbir perdede XP vermez.

I. Perde'de [Mete](/encyclopedia/mete) rehinedir: kılıcı yoktur, asıl aracı gizliliktir. Dövüş kurt, nöbetçi, Toy gecesinin baskını, Kara Boran'ın takipçileri ve Kemik Boğazı'nın tek boss'uyla sınırlıdır. II. Perde'den açık dünya açılır: her dövüş düşman türüne göre belirli ganimet verir, yanında en çok 10 yoldaş dövüşür. Yüzlerce atlının çarpıştığı sahneler [Ordu](/docs/gameplay/army) sayfasındaki toplu savaş kuralıyla oynanır.

## Temel sayılar

- Yumruk 10 hasar. Savuş 0,25 sn, bedeli 15 stamina; Savuş becerisiyle (Palak'ın dersi) 0,35 sn ve 10. Arkadan ilk vuruş ×1,5. Arkadan bayıltma 3,5 sn sürer, 8 m'den duyulur; Uyku Kolu becerisiyle (Uldın'ın dersi) 2,2 sn ve 2 m.
- Sapan 18 m'ye atar, 1,2 sn sersemletir, çakıl sonsuzdur. Ezme ve sapan 0 Can'da bayıltır: 90 sn, Korku yok. Kesme, delme ve ateş öldürür.
- Kışlak'ta, Tipide, kavga dışında öldürmek Korku +2. Savaşta öldürmek Kut ve Korku yazmaz. Bayılmış ya da teslim olmuş kişiyi öldürmek (II'den) Kut −1, Korku +2; teslim olanı öldürmek 40 m içindeki yoldaşların onayından da 1 düşürür ([K72](/docs/source/design/decisions#k72)).
- Tablolardaki hasar Bilek 3 içindir; Bilek'in her puanı yakın dövüşte +%6 ekler.

**Tuşlar.** Sağ tık nişan, `E` kullan, `F` sapan (ateşin 3 m içinde basılı tutuş ateş işidir). `Q` I. Perde'de Çığırtkan'dır: atları ürkütür, firarileri sese çağırır. II'den `Q` hızlı silahtır, yay ile yakın silah arasında geçer; Çığırtkan Çubuk'un 6. yuvasına iner, oyun kolunda RB kalır ([K82](/docs/source/design/decisions#k82)). Bütün tuşlar yeniden atanır ve kaydedilir ([K39](/docs/source/design/decisions#k39)).

![Prototipte denendi: oyuncak yayın nişan halkası](/media/docs/research/p6-shots/aim-ring-steady.png)

## Silahlar

Rastgele ganimet ve aşınma yoktur: silah görevden, zanaattan, takastan ya da sahneden gelir. Balta ve kazma silah olarak da vurur.

| Silah | Tür | Hasar türü | Hasar | Aralık sn | Erim m | Perde | Nereden |
|---|---|---|---|---|---|---|---|
| Yumruk | El | Ezme | 10 | 0,55 | 1,4 | I | Başta |
| Kendi Bıçağın | Bıçak | Kesme | 14 | 0,5 | 1,4 | I | Demir Diş görevi; çizmede saklanır, Korku +1 ile gelir |
| Tunç Balta, Demir Balta | Araç | Kesme | 12, 16 | 1,1 | 1,6 | I | Ardokşa; Kujul (demir, kömür) |
| Tunç Kazma | Araç | Delme | 11 | 1,05 | 1,5 | I | Bahis görevi |
| Kısa Kılıç | Kılıç | Kesme | 18 | 0,7 | 1,7 | I | Son Gece, Boğaz; Uldın'ın Kılıcı aynı sayılarla Demir Diş'ten |
| Akinakes | Kılıç | Kesme | 20 | 0,65 | 1,6 | I | Ölünün Altını görevi |
| Kapı Süngüsü | Süngü | Delme | 17 | 0,9 | 2,4 | I | Boğaz Kapısı rafı |
| Sapan | Atış | Ezme | 6 | 1,6 | 18 | I | 1 deri, 1 yün |
| Meşale | Sarf | Ateş | 4 | 0,8 | 1,5 | I | Dal, reçine; yapıyı yakar |
| Halka Kabzalı Kılıç | Kılıç | Kesme | 24 | 0,7 | 1,8 | II | Demirci Ocağı, usta |
| Kısa Süngü | Süngü | Delme | 22 | 0,85 | 2,6 | II | Demirci Ocağı |
| Tunç Topuz | Topuz | Ezme | 20 | 0,95 | 1,6 | II | Saka takası |
| Demir Kılıç | Kılıç | Kesme | 30 | 0,7 | 1,9 | III | Demirci Ocağı, usta |
| Sagaris | Kazma balta | Delme | 27 | 0,85 | 1,7 | III | Saka ganimeti; zırh delme 0,25 |
| Uzun Kılıç | Kılıç | Kesme | 36 | 0,8 | 2,1 | IV | Demirci Ocağı, usta |
| Demir Topuz | Topuz | Ezme | 32 | 0,95 | 1,7 | IV | Demirci Ocağı, usta |
| Han Kılıcı | Kılıç | Kesme | 40 | 0,75 | 2 | V | Sahnede elle konan ganimet |
| Kıngrak | Ant bıçağı | Kesme | 46 | 0,65 | 1,8 | VI | Akinakes ya da kendi bıçağın, 2 altın, 4 demir; tutulan ant başına +%2, en çok %20 |
| Tahta Kılıç | Çocuk | Ezme | 1 | 0,6 | 1,3 | Serbest Gez | Çocuk |

**Yay.** Çekiş eşiği Bilek ister: «gerebildiğin yay». Eşiğin altında hasar puan başına −%12 (alt sınır ×0,6), çekiş süresi +%20; üstünde hasar puan başına +%2.

| Yay | Hasar | Bilek eşiği | Çekiş sn | Yayılma ° | Menzil m | Perde | Nereden |
|---|---|---|---|---|---|---|---|
| Oyuncak Yay | 1 | 0 | 0,4 | 6 | 14 | Çocukluk, I, Serbest Gez | Mene; Çocuk |
| Ödünç Yay | 14 | 3 | 0,8 | 5 | 30 | I | Av görevi, akşam geri alınır |
| Düşen Atlının Yayı | 18 | 4 | 0,8 | 4,5 | 32 | I | Kapı rafı ya da düşen atlı; II'ye geçer |
| Saka Yayı | 20 | 4 | 0,7 | 4 | 34 | II | Takas |
| Hun Yayı | 26 | 5 | 0,8 | 3,5 | 40 | II | İlki Mete'nin kendi yayı: Yançi gergin getirir; sonra Okçu Yurdu |
| Kemik Sıyahlı Yay | 32 | 6 | 0,85 | 3,2 | 44 | III | Okçu Yurdu, usta |
| Ağır Yay | 38 | 7 | 1 | 3,5 | 48 | III | Okçu Yurdu, usta |
| Boynuz Yay | 44 | 8 | 0,9 | 3 | 50 | IV | Okçu Yurdu, usta |
| Ulu Yay | 50 | 10 | 1,1 | 3 | 56 | V | Okçu Yurdu, usta |
| Han Arbaleti | 60 | 0 | 3,2 | 1,5 | 60 | V | Sahnede elle konan ganimet; yalnız yaya |

**Ok.** Kemik temren ×1; tunç ×1,15 (zırh delme 0,2); demir ×1,3 (0,35); ateşli ×0,7 ve yanık; ıslıklı ×0,4; arbalet oku ×1,1 (0,5; Hun yayıyla atılmaz). Zırh delme değeri, zırhın hasar çarpanını o oranda 1'e yaklaştırır. On ok 0,5 Yük'tür, atılan okun %60'ı toplanır. Sadak: Farnak'ın Sadağı 12 ok (I), Gorytos 24 (II), Savaş Sadağı 40 (IV). Rüzgâr oku sürükler, nişan halkası sapmayı içerir. Yağmurda kiriş ıslanır: bileşik yayda hasar en çok −%15, menzil −%10; Gorytos ıslanmayı yarıya indirir, ateş başında kurur.

```varlik
short_sword, akinakes, sling, ring_sword, iron_sword, han_sword, qingrak, loan_bow, bow, horn_bow, han_crossbow, arrow_bone, arrow_whistle, bolt, gorytos
```

## Hasar türleri

| Tür | Korumasız | Keçe | Deri | Pul | Hayvan |
|---|---|---|---|---|---|
| Kesme | 1,00 | 0,85 | 0,85 | 0,45 | 0,90 |
| Delme | 1,00 | 0,90 | 0,90 | 0,65 | 1,00 |
| Ezme | 0,80 | 0,85 | 1,00 | 1,10 | 0,70 |
| Ateş | 1,00 | 1,30 | 0,80 | 0,40 | 1,20 |

Dört tür, beş canlı sınıfı vardır. Silahı hedefe göre seçmek oynanıştır: pul zırhta kılıç kötü, topuz iyidir; zırh delme değeri olan silah ve ok pulu geçer. **Yapıda** başka tablo işler. Dört kural: ok keçeye az, ipe çok işler; kılıç keçeyi keser; ateş keçeyi çabuk yakar; ezme kafesi kırar. Can bitince aşama geri düşer, aşama 0 yıkılmaz. Hane Yurdu'nu 7. aşamadan 0'a indirmek kısa kılıçla 46, tunç baltayla 23, okla 490 vuruştur ([structures.md §5.3](/docs/source/design/structures#5-3-yurdu-indirmek-icin-vurus-hesaplandi-stat-3)). Kışlak'ta gündüz balta vurursan ilk vuruşta nöbetçi uyarır, sonra Güven −3. Ayrıntı [Hasar ve Onarım](/docs/buildings/damage-repair) sayfasındadır.

## Düşmanlar

| Düşman | Perde | Can | Sınıf | Saldırı | Not |
|---|---|---|---|---|---|
| Kurt | I | 30 | Hayvan | 8 delme, sıçrayış çizimli | Ateşten çekinir; sahnede en çok 4 |
| Yaban Domuzu | I | 44 | Hayvan | 8 ezme | Vurulunca saldırır |
| Yüeçi Nöbetçisi | I | 40 | Deri | 12 kesme | Dövmek yerine yakalar |
| Hun Atlısı | I | 50 | Keçe | Ok 12, zemine 1,2 sn çizim | Yalnız baskında ve kovalamacada |
| Farnak | I | 180 | Deri | Üç faz | Hikâye 120, Zor 240 |
| Hun Muhafızı | II | 70 | Deri | 16 kesme | |
| Tunghu Atlısı, Seçkini | III | 80, 120 | Deri, Pul | 18 delme, 24 kesme | |
| Ayı | III | 90 | Hayvan | 14 kesme | Yakında, yavruyla ya da vurulunca saldırır; Ekim–Mart inde |
| Kaplan | III | 140 | Hayvan | 22 kesme | Olaydır, boss değildir; zon başına perdede en çok 1 |
| Yüeçi Mızraklısı, Saka Okçusu | IV | 110, 70 | Pul, Keçe | 26 delme (çarpışta ×1,5), 24 delme | |
| Kar Leoparı | IV | 50 | Hayvan | 12 kesme | Yalnız sıkışınca saldırır, kovulunca avını bırakır |
| Han Piyadesi, Arbaletçisi | V | 120, 80 | Pul, Deri | 28 kesme, 40 delme (3 sn dolum) | |
| Seçkin Muhafız | VI | 160 | Pul | 34 kesme | |
| Sığın | VI | 110 | Hayvan | 16 ezme | Yavrulu dişi saldırır |

Tasarım hedefi: sıradan düşman 2–6 vuruşta düşer, pul zırhta kılıç belirgin kötüdür. Örnek: II'de Hun Muhafızı Halka Kabzalı Kılıçla 4, Hun Yayı ve kemik okla 3 vuruştur; IV'te Yüeçi Mızraklısı Uzun Kılıçla 6, Demir Topuzla 3 vuruştur ([progression.md §8.2](/docs/source/design/progression#8-2-canli)). Kadraj dışındaki tehlikeli hayvan ekran kenarında okla ve sesin yönüyle okunur.

**Boss yalnız I. Perde'dedir.** II. Perde'den sonra boss yoktur: kaplan bir olaydır, VI'nın Kıl Köprü'sünde dövüş yoktur. Boss canının perde çarpanı (180 × 1; 1,8; 2,7; 3,6; 4,6; 5,6) yalnız ileride adlı bir dövüş yazılırsa kullanılır. **Farnak (Kemik Boğazı, Gün VI şafağı, ≈4 dk).** Faz 1 (%100–60): sekiden ok, zemine 1,0 sn önce çizilir; direkler ve kule ayakları siperdir. Faz 2 (%60–30): sahte kaçış; kovalarsan eyerde döner, atar, iki atlı yandan gelir; 25 m içinde üç Çığırtkan kısrağı ürkütür. Faz 3 (%30–10): yaya, üç kesiş, 1,1 sn çizimli. %10'da diz çöker, sonrası senin seçimindir. Üç yara faz başına döndürür.

```varlik
wolf, boar, crowd_yuezhi_guard, crowd_hun_rider, crowd_tunghu_rider, bear, tiger, crowd_han_crossbow
```

## Ganimet

> [!NOT]
> «malzemeler açık dünyada savaşlarla, ağaç kesere, avlanarak eti toplacanak»

I. Perde düşmanı yeni mal vermez: Mete rehinedir. II'den açık dünyada her dövüş ganimet verir: yoldaki devriye, akıncı, düşman kampı ve def edilen akın aynı tablodan okur ([K49](/docs/source/design/decisions#k49)). Yere düşmüş düşmanda «Ara» 1,5 sn sürer. Ganimet düşman türüne göre bellidir: her türün sabit verimi vardır, kesirli pay sayaçta birikir, 1'i geçince düşer. Rastgele çekiliş yoktur, yeniden yüklemek sonucu değiştirmez. Esir yoktur. Adlı silahlar (Halka Kabzalı Kılıç, Demir Kılıç, Han Kılıcı, Han Arbaleti) tabloda değildir, sahnelere elle konur.

| Düşman | Perde | Düşman başına verim | Beklenen Kıymet (kabuk) |
|---|---|---|---|
| Hun Muhafızı | II | 0,6 deri, 0,6 demir hurda, 0,3 tunç hurda, 0,5 kabuk | 12,2 (3,1) |
| Tunghu Atlısı | III | 6 tunç ok, 0,3 deri, 0,15 tilki kürkü, 0,4 tunç hurda, 0,4 at | 154,8 (38,7) |
| Tunghu Seçkini | III | 6 tunç ok, 2 tunç hurda, 0,6 demir hurda, 0,5 at | 205,2 (51,3) |
| Yüeçi Mızraklısı | IV | 1,5 demir hurda, 0,3 deri, 0,45 at | 158,1 (39,5) |
| Saka Okçusu | IV | 10 tunç ok, 0,3 keçe, 0,4 tunç hurda, 0,3 at | 126,1 (31,5) |
| Han Piyadesi | V | 2,1 demir hurda, 0,2 deri | 7,9 (2,0) |
| Han Arbaletçisi | V | 0,75 demir hurda, 9 arbalet oku | 15,8 (3,9) |
| Han arabası | V | 5 tahıl çuvalı, 2,4 demir hurda, 9 arbalet oku, 0,9 sığır | 296,7 (74,2) |
| Seçkin Muhafız | VI | 2,4 demir hurda, 0,6 deri, 1 kabuk, 0,5 at | 184,0 (46,0) |

- Kabuk yalnız Hun düşmanında düşer: Hun Muhafızı 0,5, Seçkin Muhafız 1. Düşmanın atı kaçar; 60 sn içinde at çağrısıyla yakalanırsa ordugâh sürüsüne geçer. Arbalet oku Hun yayıyla atılmaz: satılır (8 adet 3 kabuk) ya da Demirci Ocağı'nda eritilir (8 ok 1 tunç hurdası). Def edilen akının düşenleri aynı tablodan ×0,6 verir; küçük akında karar sorulmaz, Paylaş sayılır.
- Birlik savaşında havuz düşenlerin veriminin ×0,6'sıdır. Mete karar verir: Paylaş ambara %25 bırakır (Sadakat +8, Moral +6), Alıkoy %75 alır (Sadakat −10, Moral −4, Korku +1). Yoldaşlar bir onluk sayılır: Paylaş onaylarına +0,5, Alıkoy −0,5 yazar; yoldaş kendi payını istemez, yerdeki düşmanı «Ara»yı Mete yapar.
- Yağmalanan kampın ambarı kültürüne göredir: Tunghu kürk ve at; Yüeçi keçe, demir hurda ve firuze; Han arabası tahıl, demir hurda ve arbalet oku. Kaçanın sağlam yurdu «Sök» ile Yurt Yükü olur: ev de alınır, insan alınmaz. Ganimet XP vermez.

## Yara ve Düşüş

Can bitmek bitiş değildir. Can 0'da yara +1 yazılır, Can %50'ye döner, 1 sn dokunulmaz olursun.

| Olay | Sonuç |
|---|---|
| Can 0 | Yara +1, Can %50 |
| Çizimli doğrudan vuruş (ok, boss darbesi, kaçırılan kement) | Yara +1, ayrıca hasar |
| Açık yara başına | Stamina −8, koşu −%3, Can yenilenmesi −%25 |
| Yara sınırı: Mete'de Hikâye 5, Normal 3, Zor 2; yoldaşta her zorlukta 3 ([K88](/docs/source/design/decisions#k88)) | Mete'de Düşüş, yoldaşta düşme |
| Sargı | −1 yara, 4 sn, hareket edilemez |
| Ateş başında ≥2 oyun saati Dinlen, Tokluk ≥25 | −1 yara, 6 oyun saatinde bir |
| Bozkır Çayı | −1 yara |
| Uyku (≥4 oyun saati) ya da Menzil (1 Aş) | Bütün yaralar kapanır; açıkta Uyku Zarı uykuyu 4 oyun saatinden önce keserse kapanmaz ([K45](/docs/source/design/decisions#k45); [Tek Gecelik Kamp](/docs/gameplay/overnight-camp)) |

**Düşüş: [Umay](/encyclopedia/umay) Eşiği ([K1](/docs/source/design/decisions#k1)).** Yalnız Can yoluyla gelir: açlık, hava, yıldırım ve dolu açmaz. Kısa kararma, altın ışık; son onarılmış direkte, barınakta, Menzil'de, ocakta ya da uyunan Gecelik Çadır'da uyanırsın. Saat +2 oyun saati ilerler, takipçi 60 m geridedir. Bedel: Hikâye'de yok, Normal'de 1, Zor'da 2 erzak; Kut ≥5 ya da Geyik Muskası erzak almaz. Eşya ve bayrak geri alınmaz. Hikâye'de 0, öteki zorluklarda 1 yarayla uyanılır. Uyanınca başucunda küçük bir ok ve yay durur; ilk Düşüş kartı tek söz yazar: «Umay.» ([K35](/docs/source/design/decisions#k35)). Boss'ta faz başına döner. **Düşüşte yanındakiler ([K74](/docs/source/design/decisions#k74)).** Adlı erin (firari, onluk eri) ölüm şansı Hikâye %0, Normal %30, Zor %50'dir; Düşeni Taşı becerisi bunu ×0,3 yapar. Zar kaydın tohumundandır, yüklemeyle değişmez; ölen Ad İpi'ne geçer. Çekirdek yoldaş, konuk ve Jiyu zar atmaz: 40 m içindekiler Mete'yi taşır, uyanışta yanındadır, Yara +2 alır (3'e varırsa Ağır Yaralı); 40 m dışındakiler savaştan çekilir, Tan'da gelir.

## Gizlilik ve nöbetçi algısı

I. Perde'nin gecesi bunun üstüne kuruludur. Üç şey ele verir: çan, görüş, iz.

| Hareket | Çan takılı | Keçe tıkaçlı (×0,4) | Çan yok |
|---|---|---|---|
| Dur | 0 m | 0 m | 0 m |
| El çanda çömelik | 2 m | 0,8 m | 1,5 m |
| Yürü | 14 m | 5,6 m | 4 m |
| Koş | 32 m | 12,8 m | 9 m |

**Görüş.** Koni 80°, 16 m; fener havuzunda 20 m. Şüphe saniyede `(0,5 + 1,1 × (1 − uzaklık / menzil)) × çömelik 0,4 × zemin × zorluk` artar: `?` 0,15'te, `!` 0,6'da, yakalanma 1'de. Diyalog sırasında algı durur.

| Zemin | Görülme | İz | Hız | Stamina dolumu |
|---|---|---|---|---|
| Patika | Fener altında ×1,3 | Yok | ×1 | ×1 |
| Derin Kar | Karanlık ×0,6 | 90 sn (Tipide 15) | ×0,7 | ×0,8 |
| Barınak | Karanlık ×0,4, nöbetçi yoklar | Yok | Yok | ×1,5 |

- **Karanlık** güneş −6°'nin altındayken ve oyuncu ışık havuzunda değilken açıktır; saat gizliliğe başka çarpan vermez. **Işık gösterir ama ele verir ([K1](/docs/source/design/decisions#k1)).** Ateş dumanı 60 m'den, ışığı yarıçapının 3 katından fark edilir, nöbetçi yoklamaya gelir. Meşale gece görülmeyi ×1,3 yapar. Küle Yatır ateşin ışığını ve dumanını keser.
- **İz.** Yeni karda iz kalır, nöbetçi izi takip eder. Kar yağarken iz ömrü kısalır. **Gece gürültüsü:** balta 24 m, kazma 28 m.
- **Yasak alan** meşale, kazık ve kırmızı plakayla görünür: görünmez kural yoktur. **I. Perde'de yakalanma.** Eksik Ölçü dersinde yalnız Güven −2. Son Gece'de yurda dönüş, saat +60 dk, o çıkış kapanır, +1 nöbetçi; eşya ve bayrak geri alınmaz. Yükleme yoktur.
- **Beceriler.** I'de Kar Adımı, Kemik Atışı, Nöbet Okuma (18 m içinde koniler yerde görünür). II'den İz Okuma, III'ten Saza Yatış ve Sahte Ocak, IV'ten Yer Kulağı, V'ten Bozkır Hayaleti.

### Sonraki perdelerde gizlilik ([K44](/docs/source/design/decisions#k44))

Hesap I. Perde'ninkiyle aynıdır, oyuncu öğrendiği ölçüyle sürer. **Yakalanma yeniden yükleme değildir:** alarm çalar, ya kaçarsın (≥60 m uzakta ve 20 sn görünmeden) ya dövüşürsün. Görev sürer; sonuç kademelidir (tam bilgi, yarım, yok) ve sonraki sahnenin zorluğunu ±%20 değiştirir. Yaya nöbetçi I. Perde'nin değeriyle kalır, dört algılayan yenidir:

| Algılayan | Koni | Menzil | Not |
|---|---|---|---|
| Yaya nöbetçi | 80° | 16 m; fenerle 20 m | I. Perde'nin değeri |
| Atlı devriye | 100° | 24 m | Rota 300–500 m |
| Kule gözcüsü | 50° | 40 m; karanlıkta 24 m | Barınak ×0,7 |
| Köpekli nöbetçi | 80° | 16 m ve koku 12 m | Rüzgâraltında ×0,5, rüzgârüstünde ×2; atılan kemik köpeği çeker |
| Ateş başı | 40° | 6 m | Işık havuzunun dışını geç görür |

At gürültüsü adımda 8, tırısta 14, dörtnalda 24 m'dir; Toynak Sargısı ×0,5 yapar. Sahnede en çok 12 tam nöbetçi, alarmda en çok 6 kukla olur. Kadraj dışındaki şüphe ekran kenarında okla okunur; çömelince kamera nöbetçinin 16 m'lik görüş çemberini kadraja alacak kadar açılır. Her perdenin en az bir gizlilik görevi vardır; IV'te ve V'te ikişer görev vardır, V'inkiler ters gizliliktir.

| Perde | Görev | Yer | Ne yapılır | Nöbetçi | İzleyen yoldaş |
|---|---|---|---|---|---|
| II | Tanhu'nun Atı (12–13 Haziran 209) | Islık Alanı'nın kuzeyi | Tanhu'nun sürüsü gece gözlenir | ≤6 | En çok 3 |
| III | Tunghu Nöbeti | Tunghu toprağı | Tunghu ordugâhının çadırı, atı ve kapısı sayılır; sayı baskına yazılır | ≤10 | En çok 2 |
| IV | Amaga (14 Haziran 205'e dek) | Gök Dağı yazlığı | Gece gizli çıkış | ≤8 | En çok 1 |
| IV | Ordos (21–23 Ağustos 203) | Ordos | Baiyang beyiyle gizli görüşme | ≤8 | Kozı ve 1 kişi |
| V | Sürüyü Gizle (21–22 Kasım 201) | Mayi çevresi | Ters gizlilik: semiz at ve yiğit vadilere saklanır, yalnız yaşlı ve zayıf gösterilir | 3 gözcü, koni 60°, 60 m | Bütün partiye Gizlen kendiliğinden |
| V | On Elçi (22–23 Kasım 201) | Mayi otlağı | On Han elçisi gösterilen zayıflığı görür, bayrak yazılır | 3 gözcü, koni 60°, 60 m | Han Xin, Zang Yan ve Wang Huang yasak |
| VI | Hüküm (11 Ekim 177) | Tanhu Otağı | Yitu'yu kışkırtan Houyilu beyi Nan izlenir | ≤8 | En çok 2 |

**Yoldaş gizlilikte.** Bölgeye girişte en çok 3 yoldaş izler: seçiliyse seçililer, değilse Berik, Mijia, Kunduz, Loufan okçusu, sonra onay sırası. Kalanlar bölge kenarında, koni dışında bekler. İzleyen yoldaş 1,5 m'lik gizli kolda Mete'nin çömelmesini kopyalar; saldırmadıkça, Mete görülmedikçe ve alarm yokken nöbetçi onu saymaz. Berik partideyken girişte en yakın iki nöbetçinin konisi 20 sn görünür. Gizlen buyruğu bölge dışında pusudur: görülme ×0,5.

Doğrulanacak: II–VI'nın nöbetçi ve düşman değerleri her perdenin görev verisi yazılırken ayarlanır ([Yol Haritası](/roadmap#item-sentries); III [Tunghu Nöbeti](/roadmap#item-tunghu-watch), V [ters gizlilik](/roadmap#item-reverse-stealth)).

## Atlı dövüş

I. Perde'de atlı dövüş yalnız kovalamacadır: fare ya da WASD yön, Shift mahmuz (+3 m/sn), `Q` Çığırtkan, `F` sapan. Dönüş dörtnalda 4,4'ten 2,8 rad/sn'ye iner. At staminası saniyede `(0,27 − 0,09k)` gider, `(0,14 + 0,10k)` dolar (`k` = Bağ / 100). Kovalamacada kamera döndürmesi açıktır; kadraj sözleşmesi kameraya bağlı değildir: sana zarar verebilen her şey ya kadrajdadır ya ekran kenarında oku yanar ([K39](/docs/source/design/decisions#k39)).

| Durum | Kural | Kaynak |
|---|---|---|
| Takipçi ateşi | Atıcı ateşten önce kadraja çıkar ya da kenar oku en az 1,2 sn önce yanar; ok zemine 1,2 sn önce çizilir, 1 yara | [act1.md §10](/docs/source/design/act1#10-kovalamaca-kara-boran-black-blizzard) |
| Kement | ≤6 m; `Q` ya da `F` ile kurtul, olmazsa düşersin | act1.md §10 |
| Çığırtkan | `20 + 0,2 × Alışkanlık` m içindeki atları 8 sn ürkütür | act1.md §10 |
| At göğsü | Yapıya 30; dörtnalda dayanınca at durur | [progression.md §7.1](/docs/source/design/progression#7-1-yakin-ve-arac) |
| Eyerden ok | Dizle Sürme ister; yayılma ×1,6, dörtnalda çekiş ×1,25 | [progression.md §7.2](/docs/source/design/progression#7-2-yaylar) |

**Atlı beceriler** ([progression.md §4.7](/docs/source/design/progression#4-7-eyer-saddle-saddle-13-beceri), [§4.8](/docs/source/design/progression#4-8-yay-bow-bow-12-beceri), [§4.9](/docs/source/design/progression#4-9-bicak-blade-blade-13-beceri)): Göğüsle Vuruş (II, Bağ ≥50) yayaya 25, yapıya 30 vurur, hız düşmez; Dörtnal Atışı (II) eyerde yayılmayı −%40 yapar, dörtnalda çekiş cezasını kaldırır; Omuz Üstü (II) arka yayı 200°'ye açar, hasar ×1,3, hedef 1,5 sn yavaşlar; At Düşüren (III) atlıyı yere indirir, 4 sn kalkamaz, her 3 atta Korku +1; Süngü Hamlesi (II) 4 m atılma, hasar ×1,4, atlıyken ×1,6; Eyerden Kesiş (III) hızla büyür, 12 m/sn'de ×1,5. Gök gürültüsü, yıldırım, dolu ve toz atı ürkütür; Bağ ≥70 at gök gürültüsüne aldırmaz. Binek deve 20 m içindeki düşman atını ürkütür (II'den). Tarih: üzengi yoktur, eyer keçe ve ağaçtır.

## Yoldaşlarla dövüş

Kural [companions.md §6](/docs/source/design/companions#6-dovus)'dadır; kadro [Yoldaşlar](/docs/gameplay/companions) sayfasındadır. Yoldaş partisi Mete'nin onluğudur: II'den en çok 10 kişi yanında dövüşür ([K70](/docs/source/design/decisions#k70)). Her yoldaşın bir rolü vardır; rol etkisi yoldaş partideyken, ayaktayken ve Ağır Yaralı değilken işler, aynı rol üst üste binmez.

| Rol | Kim | Dövüşte | Partiye etkisi |
|---|---|---|---|
| Güreşçi | [Uldın](/encyclopedia/uldin) | Yakın; Uyku Kolu 2,2 sn'de bayıltır | Toy'da moral +4; Mete'nin Uyku Kolu 1,8 sn |
| Keşif eri | [Berik](/encyclopedia/berik) | Sapan, bıçak, pusu | Gizlilik bölgesine girişte en yakın 2 nöbetçinin konisi 20 sn görünür |
| Okçu | [Luhun](/encyclopedia/luhun) | Atlı okçu, art arda iki ok | Islıktan sonra yoldaş oklarının saçılımı −%15 |
| İz sürücü | Mijia | Boynuz yay, kapan | 60 m içindeki izler zemine ve haritaya düşer, yaşı okunur |
| Otacı | [Dangyu](/encyclopedia/dangyu) | Savaşmaz, 10 m geride durur | Sargı 4 → 2 sn; Kaldır 3 → 1,5 sn; ateş başında 3 oyun saatinde bir Yara −1 |
| Keskin nişancı | Loufan okçusu | 2,5 sn'de bir nişanlı ok, hasar ×1,5 | Yoldaş okçularının menzili +%10 (Hun Yayı 40 → 44 m) |
| At terbiyecisi | Kozı | Kement sırığı atlıyı düşürür, kısa mızrak | Parti atlarının yorgunluğu ×0,9; gök gürültüsü ürkmesi ×0,5 |
| Avcı | Kunduz | Avcı yayı, kapan; karda hız cezası yarı | Av izi 80 m'den görünür; av verimi +%15 |
| Veliaht | [Jiyu](/encyclopedia/jiyu) | Atlı okçu | Onluğun moral tabanı +10 |
| Danışman, kâtip, dilmaç | Zang Yan, Zhang Sheng, Tuidang | Han kılıcı (atta yakın dövüş −%20); savaşmaz; atlı okçu ve Han kılıcı | Han elçi ve kurul sahnesinde ek seçenek; mektup ve heyette ek ağız, Han satıcısıyla takas −%5; Han ve Yüeçi ağzında ek seçenek, söylenti +1 |
| Konuklar | Han Xin, Wang Huang | Han kılıcı; arbalet | Han birliklerinin saldırı çizimi 0,2 sn erken; takas −%5, kervan kartında takasa +1 mal |
| Konuklar | Xi Huqian, Bujiu | Hafif yay; mızrak | Atlas yol olayı %25 → %20; Bujiu 4 m içindeyken Mete'nin aldığı yakın dövüş hasarı ×0,9 |

**Hedef seçimi.** Yoldaş şu sırayla hedef seçer: 1) ıslıklı okun gösterdiği (okçu yoldaş ıslık zarını atar); 2) 25 m içinde Mete'yi nişan alan ya da ona yanaşan düşman; 3) düşmüş bir yoldaşa saldıran; 4) rolünün menzilindeki en yakın düşman (okçu 40 m, yakın dövüşçü kendinden 8 m ya da Mete'den 12 m); 5) rolün tercihi: keskin nişancı en çok Can'lı seçkini, avcı hayvanı, koruyucu Mete'ye en yakın düşmanı seçer. Yakın dövüşe hedef başına en çok 3, parti başına en çok 6 yoldaş girer; kalanı ok atar. Hedef saniyede 4 kez yeniden seçilir, değişim en az 1,5 sn arayladır. Yoldaş oku yoldaşa ve Mete'ye değmez. Kaçan düşman 30 m'den öte kovalanmaz; Saldır buyruğu bunu 120 m'ye açar. **Buyruklar.** Saldır `V` (fare noktası ya da 60 m içindeki en yakın düşman), Geri Çekil Shift + `Z` (savaşı bırakır, Mete'nin 25 m gerisine çekilir, moral düşmez), Burayı Tut `X` 0,4 sn basılı, Gizlen `0`, Islık `R`; seçim F1–F10, hepsi `H`, Buyruk Halkası `N`. Düzen `B` II'de açılır ve kipe göre döner: yayada gevşek, kama, kol; atlıda kama, saf, hilal ([K88](/docs/source/design/decisions#k88)). I. Perde'de yalnız Z, X ve G vardır ([Ordu](/docs/gameplay/army)).

**Can, Yara ve Kaldır ([K74](/docs/source/design/decisions#k74), [K88](/docs/source/design/decisions#k88)).** Yoldaşın Can'ı `50 + 6 × perde`'dir: II 62, III 68, IV 74, V 80, VI 86; savaşmayan ×0,8. Can 0'da Yara +1, Can %50. Yara sınırı zorluktan bağımsız 3'tür: kartın saat 6'daki üç yara baklavası her zorlukta aynı okunur, zorluk yoldaşa yalnız alınan hasar çarpanıyla dokunur. Yara 3'te yoldaş düşer. Mete `E` basılı 3 sn ile, otacı 1,5 sn ile kaldırır: yoldaş Can %30 ve Yara 2 ile kalkar; savaş başına yoldaş başına bir kez, ikinci düşüşte savaş bitene dek yatar. Savaş bitince kalkmayan Ağır Yaralı olur: savaşmaz, İzle dışında buyruk almaz; uyku (≥4 oyun saati) ya da 24 oyun saati sonra biter, Otacı Yurdu'nda ya da Dangyu yanındayken 12. Kalıcı yara ve dirilme yoktur: bedel zamandır. **Ölüm ve moral.** Çekirdek yoldaş ve konuk oynanışta ölmez. Hikâyede ölen yalnız dördüdür: Luhun (II, oyuncu ret kararında kestirirse), Han Xin (Kronik, 13 Mart 196), Wang Huang (Kronik, 196) ve Dangyu (Kronik, 186 kışı). El yazımı görev yarıda kalmaz. Moral onluğundur: moral 30'un altındayken yoldaşın tepkisi 0,4 sn gecikir; 15'in altında adlı er dağılır, çekirdek yoldaş dağılmaz, Mete'nin 25 m gerisine çekilir. Kut ≥14'te moral tabanı 40, Korku ≥14'te 30; Jiyu partideyse taban +10.

**Islık ve korunan kişi ([K88](/docs/source/design/decisions#k88)).** Okçu yoldaş ıslıklı okun zarını atar: sadakati `30 + 6 × onay`, disiplini onluğunkidir. Partideki kişi (yoldaş, konuk, Jiyu, adlı er) ıslıkla hedef gösterilirse korumalıdır: oklar 3 m kısa düşer, Korku +1, o yoldaşın onayı −1 ([army.md §6.3](/docs/source/design/army#6-3-islikli-okun-isareti)). Düşeni taşımak onaya +0,5, bırakmak −0,5 yazar.

Doğrulanacak: rol etkilerinin perde başına ganimet ve takas farkı ≤%5 kalır ([Yol Haritası](/roadmap#item-party-tuning)).

```varlik
ui_companion_card, status_badge_combat, status_badge_wounded, status_badge_heavy_wound, status_badge_down, status_wound, status_fallen, bandage, lasso_pole, hunter_bow
```

## Zorluk

Zorluk oluşturucuda seçilir, kayda yazılır, kitaptan değiştirilir. XP, stat ve beceri zorlukla değişmez. Tehdit kenar oku ve kadraj sözleşmesi her zorlukta açıktır ([K39](/docs/source/design/decisions#k39)).

| Ayar | Hikâye | Normal | Zor |
|---|---|---|---|
| Nöbet algısı | ×0,7 | ×1 | ×1,3 |
| Nöbetçi, takipçi | −2 | 0 | +2 |
| Ok çizimi süresi | ×1,3 | ×1 | ×0,85 |
| Mete'nin yara sınırı | 5 | 3 | 2 |
| Yoldaşın yara sınırı ([K88](/docs/source/design/decisions#k88)) | 3 | 3 | 3 |
| Boss canı (Farnak 120 / 180 / 240) | ×0,67 | ×1 | ×1,33 |
| Alınan hasar (yoldaşa da işler) | ×0,7 | ×1 | ×1,25 |
| Sıradan düşman canı | ×0,85 | ×1 | ×1,15 |
| Düşüş bedeli | Yok | 1 erzak | 2 erzak |
| Düşüşte adlı erin ölüm şansı | %0 | %30 | %50 |
| Uyku Zarı, açıkta ([K45](/docs/source/design/decisions#k45)) | Yok | ×1 | ×1,5 |
| Islak kiriş cezası | ×0,5 | ×1 | ×1 |

> [!DURUM]
> Oyunda yok. Godot'da dövüş, silah, düşman, nöbetçi, gizlilik, Yara ve Düşüş, atlı dövüş, ganimet ve yoldaş yoktur ([d3/oyun-durumu.md](/docs/source/design/d3/game-state)). Serbest Gez'de oluşturulan karakter yalnız yürür ve koşar; kamera bugün Q, E ve sağ tuşla döner. Bu atama dövüş fazında kalkar: sağ tık nişan, Q I. Perde'de Çığırtkan (II'den hızlı silah), E kullan olur. Prototipte denendi: oyuncak yayın nişan halkası, ok uçuşu, yurda hasar, aşama düşmesi ve yangın; Godot'a taşınmadı.

## Yol haritası

Dövüş, gizlilik, nöbetçiler, tehdit oku, zorluk ve kovalamaca I. Perde'nin hikâye sistemleri fazındadır; Farnak ve firarilerin kartları günler ve kaçış fazında; yoldaş buyrukları ve rol etkileri II'nin yoldaş partisi fazında. II–VI'nın gizlilik görevleri kendi perdelerinin fazındadır: [Tanhu'nun Atı](/roadmap#item-act2-finale), [Tunghu Nöbeti](/roadmap#item-tunghu-watch), [IV'ün gizli çıkışı](/roadmap#item-act4-oaths), [ters gizlilik](/roadmap#item-reverse-stealth).

```ilerleme
act-1-p3
act-1-p5
act-2-p3
```

## Kaynaklar

- [progression.md §3](/docs/source/design/progression#3-yara-ve-dusus), [§4.12](/docs/source/design/progression#4-12-gizlilik-ii-vi), [§7](/docs/source/design/progression#7-silahlar), [§8](/docs/source/design/progression#8-hasar), [§8.5](/docs/source/design/progression#8-5-dusus), [§12](/docs/source/design/progression#12-zorluk)
- [act1.md §8.9](/docs/source/design/act1#8-9-boss-farnak-kemik-bogazi-gun-vi-safak-06-14-4-dk), [§9.2](/docs/source/design/act1#9-2-erzak-tokluk-uc-zemin), [§9.5](/docs/source/design/act1#9-5-gizlilik), [§9.6](/docs/source/design/act1#9-6-dovus), [§10](/docs/source/design/act1#10-kovalamaca-kara-boran-black-blizzard); [story.md §10.1](/docs/source/design/story#10-1-kalip), [§11.1](/docs/source/design/story#11-1-ii-perde-ok-neyi-gosterirse-where-the-arrow-points)
- [companions.md §5.4](/docs/source/design/companions#5-4-gizlilik-bolgesi), [§6](/docs/source/design/companions#6-dovus); [survival.md §7.5](/docs/source/design/survival#7-5-acikta-uyku-uyku-zari-26); [economy.md §3.12](/docs/source/design/economy#3-12-savas-ganimeti), [structures.md §5.3](/docs/source/design/structures#5-3-yurdu-indirmek-icin-vurus-hesaplandi-stat-3), [fauna.md §6](/docs/source/design/fauna#6-tehlikeli-hayvanlar), [army.md §6.3](/docs/source/design/army#6-3-islikli-okun-isareti), [weather.md §8.8](/docs/source/design/weather#8-8-ok-ve-yay)
- [decisions.md](/docs/source/design/decisions): [K1](/docs/source/design/decisions#k1), [K35](/docs/source/design/decisions#k35), [K39](/docs/source/design/decisions#k39), [K44](/docs/source/design/decisions#k44), [K45](/docs/source/design/decisions#k45), [K49](/docs/source/design/decisions#k49), [K70](/docs/source/design/decisions#k70), [K72](/docs/source/design/decisions#k72), [K74](/docs/source/design/decisions#k74), [K82](/docs/source/design/decisions#k82), [K88](/docs/source/design/decisions#k88)
- [Yoldaşlar](/docs/gameplay/companions), [Ordu](/docs/gameplay/army), [Seviye ve Gelişim](/docs/gameplay/progression), [Kamera ve Kontroller](/docs/gameplay/camera-controls), [Hasar ve Onarım](/docs/buildings/damage-repair), [Hayvanlar](/docs/world/animals)
