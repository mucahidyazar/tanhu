---
title: Plan Kipi
order: 60
status: tasarim
summary: 'Oyuncu P ile yukarıdan bakar, yapıyı yere koyar; kurallar yeri süzer, malzeme ve emek şantiyede ödenir, Kâhya şantiyeyi el tavanına dek doldurur, arabalar Atölye''deki tek kartla kurulur, Yerleşim Defteri sonucu gösterir.'
sources:
  - docs/design/decisions.md
  - docs/design/settlement.md
  - docs/design/d2/settlement-model.json
  - docs/design/d2/labour-model.json
  - docs/design/structures.md
  - docs/design/economy.md
  - docs/design/godot.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Oyuncu yerleşimi yukarıdan planlar. `P`'ye basar, kamera yukarı çıkar, alt şeritten bir yapı seçer ve yere koyar. Yer uygunsa iz yeşil yanar, değilse nedenini yazar. Yapı konunca şantiye doğar: malzeme ambardan gelir, Kâhya ekibi yollar. Sonucu Yerleşim Defteri gösterir.

> [!NOT]
> «yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak»

> [!NOT]
> «Tabi yerleşim yeri veya askeri kamp kurmadan önce act 1 deki tutsaklık perdesini bitirmemiz gerekecek yani act 1 den önce bazı şeylerin kısıtlı olması lazım»

Tasarım iki notla da aynı yöndedir: yapılar malzeme (K24) ve emekle (K21) kurulur; Plan Kipi II. Perde'nin ikinci görevi bitmeden açılmaz ([K23](/docs/source/design/decisions#k23)).

## Ne zaman açılır

- Kendi Ocağın görevi bitmiş olmalı.
- Mete yerleşimin ya da ordugâhın iç haritasında olmalı.
- Görev sahnesinde, sinemada, boss dövüşünde ve yolculukta açılmaz.

Kesilirse: «Burada yurdun yok.» / «You hold no ground here.» I. Perde'de ve ana kampta hiç açılmaz. Gecelik Kamp'ın kapısı da budur ([K46](/docs/source/design/decisions#k46)).

## Nasıl çalışır

| Girdi | Ne yapar |
|---|---|
| `P` | Plan Kipi'ni açar |
| `Q` / `E` | Yapıyı 15° döndürür, Shift ile 5° |
| Tekerlek | Yakınlaşır; Plan Kipi'nde haritayı açmaz |
| Sol tık | Yerleştirir |
| Sürükle | Ağıl, çit, at hattı, sur: parçalara yakalar (2 m, 2,2 m, 10 m, 20 m), maliyet canlı yazar |
| Sağ tık ya da `Esc` | İptal |
| `Tab` | Kategori |
| `Delete` | Söker: sağlam yurt Yurt Yükü'ne, sağlam çadır Çadır Yükü'ne döner (emek ×0,35); eksik ya da hasarlı yapı ayaktaki adımların ham malının yarısını verir |

Bu bağlamda tuşlar yutulur: `Q` II'den hızlı silahtır (Çığırtkan Çubuk'un 6. yuvasına geçer, [K82](/docs/source/design/decisions#k82)), `R` buyruktur; Plan Kipi'nde ikisi de çakışmaz. Kamera eğimi 50°, uzaklığı 64 m (40–120), imleci yumuşak izler. Saat Plan Kipi'nde akar; durdurmak için `Esc` kitabı açılır.

**Alt şerit.** Yedi kategori: Konut, Sürü, Ambar, Atölye, Avlu, Savunma, Ordugâh. Sekizinci kategori yoktur: arabalar Atölye'deki tek kartta seçilir ([Araba kartı](#araba-karti), K57). Kartta ad, işlev, malzeme (var ve gerek, renkli), emek, bakım ve kapasite yazar. Emek satırı Kâhya'nın vereceği eli ve süreyi söyler: «1 iş günü · 8 elle ≈3 saat» / «1 work-day · ≈3 hours with 8 hands»; Hane Yurdu 8 elde 8,0 gerçek dakika, yani ≈3,2 oyun saati sürer ([K80](/docs/source/design/decisions#k80)). Kilitliyse nedeni yazar. Kademe kilidi kartı gizlemez: Ağaç Atölyesi'nin kartı Ocak'ta «Oba'da açılır.» / «Opens with the Clan Camp.» yazar ([K52](/docs/source/design/decisions#k52)). Konut kartında boy seçilir: Küçük Yurt ya da Hane Yurdu; Bey Otağı yalnız bey hanesinindir ([K51](/docs/source/design/decisions#k51)).

**Önizleme.** Yerleştirilen yapının kaba ağı yeşil, sarı ya da kızıl görünür, parsel katmanı yere serilir. En çok 3 neden yazılır: «Yer düz değil», «Suya uzak», «Taşkın yatağı», «Ateş payı dar», «Duman yurtlara gider», «Yolu kesiyor», «Burası {parsel} değil».

**Yerleşince** şantiye doğar. Kâhya şantiyeyi yapının el tavanına dek doldurur, artan eli sıradaki şantiyeye verir (K80); oyuncu şantiye başına eli + / − ile sınırlar. Şantiye 150 m içindeki ambardan kendi taşır. Kural: [Haneler ve Kâhya](/docs/settlement/households#isler-ve-kahya).

```varlik
ui_plan_cards
```

## Ocak Yeri

Yerleşimin merkezi Kendi Ocağın görevinde seçilir, geri alınmaz. Oyuncunun ilk kalıcı kararıdır. Parseller seçilen merkezden türer.

| Yer | Kazanç | Bedel |
|---|---|---|
| Seki / The Terrace | Düz (60 m içinde ≤3°), suya 38 m, taşkın kuşağının dışında; batı kapısına 631 m, doğu kapısına 819 m | Açık bozkır: sert rüzgârda tutuşma sıçraması tam; Kutlu Tepe 502 m |
| Dirsek / The Bend | Ot ve söğüt 100 m içinde (yem, odun bol), suya 44 m; doğu kapısına 547 m | Konut halkasının %20'si taşkın kuşağında; çamurda araba ×1,2; batı kapısına 901 m |
| Kuytu / The Lee | Kuzey rüzgârından korunur (sıçrama rüzgârı −4 m/sn), taş ve huş ≈100 m, Kutlu Tepe 127 m, batı kapısına 379 m, kule görüşü +%30 | Suya 165 m: kuyu gelene dek konutta Gönül −0,3/gün; doğu kapısına 1.164 m |

Batı kapısı ordugâha, doğu kapısı Ordos, Mayi ve Tunghu'ya açılır. Kuyu normalde Toy Yeri'nde açılır, Kuytu'da Oba'da. «Üç Ocak Yeri» adı Anohin'in Altay derlemesindeki (1924) üç ocak taşına dayanır; Destan Kitabı bunu yazar ([K57](/docs/source/design/decisions#k57)).

Doğrulanacak: uzaklıklar derenin çizgisinden ve kapı noktalarından betikle hesaplandı; Godot'da `tanhu_ordu` iç haritası pişirilirken gerçek yol ağıyla ölçülür, sapma tabloya yazılır, ölçüt Seki, Dirsek ve Kuytu'nun kazanç ve bedel sırasının korunmasıdır (K57) ([Yol Haritası](/roadmap#item-settlement-measure)).

## Yerleşim kuralları

Genel kural K21'indir ve taban kalır: kapalı hücre yok, başka yapının duvarına ≥4 m, yola ≥3 m, izdeki ağaç ve kaya önce kesilir. Yerleşim üstüne şunları ekler. Eğim ve su kuralı iki ayrı listedir (K57): eğim kuralı pedli yapıya, su ve taşkın kuralı içinde hane yatan yapıya işler.

| Kural | Değer | Neden |
|---|---|---|
| Eğim, pedli yapılar: bütün yurt gövdeleri ve yarı gömük ev (Küçük Yurt, Hane Yurdu, Tanhu Otağı, Bey Otağı, Elçi Yurdu, Otacı Yurdu, Ambar Yurdu, Buyruk Yurdu, Okçu Yurdu, Silahlık, Erzak Ambarı, Yarı Gömük Ev); yerleşimde ayrıca çadır ve kamış kulübe | ≤6° | Ped 0,175 m ve kenar eğimi r 7 m'de ≈0,73 m farkı örter; ped boyla büyür, sınır üç boyda da 6°'dir (Otağ'da ≈1,04 m, Küçük Yurt'ta ≈0,51 m) |
| Eğim, ahşap ve avlu | ≤9° | Direk çukuru toleransı |
| Eğim, çizgiler (ağıl, çit, at hattı, sur, çit halkası) | Parça başına ≤15° | |
| Kara çadır (Çiang) | Plan Kipi'nde yoktur; yazarın koyduğu yerde ≤12°, yokuş yeğlenir | Çiang çadırının yeri |
| Su | İçinde hane yatan yapı (Küçük Yurt, Hane Yurdu, Tanhu Otağı, Bey Otağı, çadır, kulübe, yarı gömük ev; Göçer Avlu'da Keçe Göç Arabası) suya ≤150 m: dere, pınar, kuyu | Aşılırsa izin var, Gönül −0,3/gün. Silahlık ve Okçu Yurdu susuz diye Gönül düşürmez |
| Taşkın kuşağı | İçinde hane yatan yapıda uyarı; sağanakta aşama 0–1 yapı zarar görür | K22 sağanak |
| Ateş payı | Duvardan duvara ≥4 m sert, <8 m uyarı | Yangın sıçraması: r 7 yurtlar 22 m merkezde ancak sert rüzgârda (≥12 m/sn) tutuşur |
| Rüzgâraltı | Demirci Ocağı, Fırın, Sepi Yeri: konuta ≥40 m ve hâkim rüzgârın altında ±60° | Değilse uyarı ve Gönül −0,2/gün: duman ve koku |
| Kapı | Yurt 120° ±45° (güneydoğu); Tanhu Otağı ve Tunghu kubbesi 90° ±10° (doğu) | Gelenek; doğan güneş |
| Yol | Ana yol (4 m) ve kapı yolları korunur | |
| Bağlantı | Ocak, her kapı ve iki zon kapısı tek bileşende kalmalı | Kendini hapseden yerleşim olmaz: «Yolu kesiyor» |
| Sayı | Zon başına en çok 160 yapı kaydı; çizgi tek kayıttır (Surlu avlunun 40 sur parçası ≈4 kayıt); aynı anda en çok 48 canlı aşamalı yapı | Tanhu Avlusu ≈150 kayıt |

### Parseller

| Parsel | Merkezden | Yapılar |
|---|---|---|
| Çekirdek | ≤40 m | Tanhu Otağı, Elçi Yurdu, Toy Alanı, Hazine, Sancak ve Fener Direği, Mete'nin yurdu |
| Konut | 40–200 m | Küçük Yurt, Hane Yurdu, Bey Otağı (en çok 3), çadır, kulübe, Ambar Yurdu, Ambar Çukuru, Kurutma Sırığı, Kuyu, Otacı Yurdu, Yarı Gömük Ev, Sancak ve Fener Direği |
| İş | 100–280 m, rüzgâraltı ±60° | Keçe Avlusu, Sepi Yeri, Ağaç Atölyesi, Demirci Ocağı, Fırın, Okçu Yurdu, Sundurma, Tahıl Ambarı, Tahıl Kulesi, Takas Yeri; Araba Yeri (Ağaç Atölyesi'ne ≤30 m, 6 × 12 m ped, yapı değil) |
| Ağıl | 150–400 m, suya ≤250 m | Ağıl, Çit, Ahır, At Hattı, Sundurma, Kuşhane |
| Tarla | Taşkın kuşağı ve dere düzlüğü | Darı Tarlası, Sundurma |
| Kutlu | Kutlu Tepe | Gök Direği |
| Sur | Surlu yol: 110 × 90 m, çevre 400 m | Sur ve Hendek, Sur Kapısı, Gözcü Kulesi |
| Kenar | Zon kenarına ≤60 m | Gözcü Kulesi, Gözcü Konağı |
| Ordugâh | Ordugâh dünyaları | Ordugâh yapıları; Talim Alanı yalnız talim ovasında |

## Araba kartı

Arabanın hangi kartta seçileceğine cevabın (#48):

> [!NOT]
> «uygun olan ibelirle araba olacak»

Plan Kipi'nde sekizinci kategori açılmaz: Atölye kategorisinde tek kart **Araba / Cart** vardır (K57). Tür kartın içinde ◂ ▸ ile seçilir; Q / E nesneyi döndürmeye kalır.

| Tür | Açıldığı kademe | Yük | Çeken |
|---|---|---|---|
| Keçe Araba | Oba | 60 | 1 at |
| Yüksek Teker | Boy Yurdu | 80 | 2 at |
| Ordu Arabası | Toy Yeri | 140 | 4 at |
| Keçe Göç Arabası | Göçer Avlu | 120 | 4 öküz |

- Kart yükü, çekeni, yol ve kar hızını, malzemeyi (var ve gerek), emeği ve «Boşta {n} · Kervanda {m}» / «Idle {n} · With the caravan {m}» satırını yazar. Emek iki satırdır: Araba Yeri'nin kurulumu inşaat eğrisiyle (K50) yürür, teker çifti Ağaç Atölyesi'nin tezgâh işidir (10 İS, usta).
- Araba **Araba Yeri / Cart Yard**'da kurulur: iş parselinde, Ağaç Atölyesi'ne ≤30 m, 6 × 12 m'lik ped. Yapı değildir, kart her kuruluşta açar.
- Kilit satırları: «Önce Ağaç Atölyesi.» / «Build a Woodshop first.»; «Dülger yok.» / «You have no carpenter.»
- Biten araba yerleşimin araba listesine girer ve Araba Yeri'nde durur; çeken at ya da öküz sürüden ayrılır, sürüde yoksa kart uyarır.
- Yolda akına uğrayıp kırılan araba aynı kartta «Onar / Repair» ile onarılır; söküm ham malın yarısını verir.
- [Teoman](/encyclopedia/teoman)'ın Keçe Arabası listede başlar: Ocak'ta kart kilitlidir, araba vardır. Tenteli Araba kartta yoktur: V'te armağandır, yapılmaz.

```varlik
cart_felt, cart_high, cart_war, wagon_felt, wheel_pair
```

## Ne kurulur, neye mal olur

| Kademe | Açtığı yapılar |
|---|---|
| Ocak | Küçük Yurt, Hane Yurdu, çadır, Kamış Kulübe, Ağıl, Çit, At Hattı, Kurutma Sırığı, Ambar Çukuru, Keçe Avlusu, Sancak Direği, Fener Direği. Ağaç Atölyesi'nin kartı kilitli görünür: Oba'da açılır. Araba kartı kilitlidir, Teoman'ın Keçe Arabası listededir |
| Oba | Ağaç Atölyesi, Ahır, Ambar Yurdu, Sundurma, Sepi Yeri, Demirci Ocağı, Fırın; Araba kartında Keçe Araba |
| Boy Yurdu | Tanhu Otağı, Elçi Yurdu, Gök Direği, Toy Alanı, Tahıl Ambarı, Okçu Yurdu, Gözcü Kulesi, Takas Yeri, Gözcü Konağı; IV'ten Kuşhane; Araba kartında Yüksek Teker |
| Toy Yeri | Hazine, Kuyu, Otacı Yurdu, Bey Otağı; Araba kartında Ordu Arabası |
| Tanhu Avlusu | Surlu: Sur ve Hendek, Sur Kapısı, Yarı Gömük Ev, Darı Tarlası, Tahıl Kulesi. Göçer: Araba kartında Keçe Göç Arabası, ek At Hattı ve Ağıl |
| Ordugâh | Onluk Ateşi'nde Onluk Çadırı, At Hattı, Talim Alanı, Sancak Direği; Yüzlük'te Buyruk Yurdu, Erzak Ambarı, Silahlık; Binlik'te Okçu Yurdu, Otacı Yurdu, Gözcü Kulesi ve Konağı, sefer için Çit Halkası |

Örnekler. Emek İG'dir (iş günü: 1.440 İD; İD, bir işçinin bir oyun dakikası; bir İG tek işçiyle 60 gerçek dakika). 40 yapı türünün tamamı: [Yapı Kataloğu](/docs/buildings/catalog).

| Yapı | Emek | Malzeme |
|---|---|---|
| Küçük Yurt | 0,4 | 4 taş, kapı, küçük kerege takımı, 3 ip, tündük, sırık, küçük uuk takımı, çiy, 3 keçe, köz |
| Hane Yurdu | 1 | 6 taş, kapı, kerege takımı, 6 ip, tündük, 2 sırık, uuk demeti, çiy, 6 keçe, köz |
| Tanhu Otağı | 2,5 | 10 taş, kapı, 2 kerege takımı, 2 uuk demeti, ulu tündük, 4 sırık, 2 çiy, 12 ak keçe, 14 ip, 2 boya, köz |
| Çadır | 0,15 | 2 odun, 2 sırık, 4 ip, 3 keçe |
| Kamış Kulübe | 0,5 | 2 taş, 4 odun, 4 ip, 18 saz |
| Ağıl (40 m) | 0,32 | 10 odun, 72 dal, 1 ip |
| At Hattı (20 m) | 0,08 | 6 odun, 4 ip |
| Ahır | 1,5 | 4 taş, 18 odun, 4 ip, 10 saz, 3 keçe |
| Ambar Çukuru | 0,3 | 2 taş, 2 odun, 2 keçe, 1 deri, 2 kil |
| Ambar Yurdu | 1 | Yurdun malzemesi, köz yok |
| Keçe Avlusu | 0,5 | 1 çiy, 4 odun, 4 ip, 2 keçe |
| Ağaç Atölyesi | 0,8 | 2 taş, 12 odun, 4 ip, 1 külçe, 8 saz |
| Demirci Ocağı | 1,5 | 8 taş, 6 kil, 2 sepi deri, 6 odun, 6 saz, 1 külçe ya da 4 demir hurda (ilk ocak külçesiz kurulur) |
| Toy Alanı | 0,4 | 8 taş, 12 odun, 4 keçe, 2 boya |
| Gözcü Kulesi | 1,5 | 4 taş, 20 odun, 4 ip, 2 deri |
| Sur ve Hendek (10 m) | 0,5 | 2 taş, 16 odun, 10 dal |
| Keçe Göç Arabası | 1,2 | 2 teker çifti, 24 odun, 10 keçe, 4 külçe, 6 ip |

**Gerçek süre yurt eğrisidir** ([K50](/docs/source/design/decisions#k50)): `T(n) = taban × 0,75^(min(n, 8) − 1)` gerçek dakika. Hane Yurdu tabanı 60 dakikadır: 1–8 elle 60 / 45 / 33,75 / 25,3 / 19,0 / 14,2 / 10,7 / 8,0. Küçük Yurt'un tabanı 24 dakikadır, en çok 6 el alır (5,7 dk); Otağ'ın tabanı 150 dakikadır, 12 el alır ama katsayı 8'de durur (20,0 dk), fazla eller malı taşır. Karışık ekipte el sayısı ağırlıkların toplamıdır: usta ve el 1, çırak 0,75, Çocuk 0,5. Eğri inşaat, söküm ve onarımdadır; öteki yapılar İG'leri oranında aynı eğriyle kurulur, el tavanı yapınındır. Tezgâhlar eski katsayıyla kalır.

**El tavanları.** Yurt gövdeli yapılar, Toy Alanı, 40 m'lik ağıl ve 10 m'lik sur parçası 8; Otağ ve Bey Otağı 12 (katsayı 8'de); Ahır, Ağaç Atölyesi, Demirci Ocağı, Keçe Avlusu, Tahıl Ambarı, Tahıl Kulesi, yarı gömük ev, tarla, Hazine, Sur Kapısı, Takas Yeri, Gök Direği, Ordu Arabası ve Keçe Göç Arabası 6; çadır, Sepi Yeri, Fırın, Ambar Çukuru, Sundurma, At Hattı, Gözcü Kulesi, Gözcü Konağı, Keçe Araba ve Yüksek Teker 4; Kuyu 3; Kurutma Sırığı ve Fener Direği 1. Yerleşim belgesinin eklediği yapıların (Elçi Yurdu, Otacı Yurdu, Hazine, Takas Yeri, Gök Direği, Gözcü Konağı, Sur Kapısı, Keçe Göç Arabası, Sancak ve Fener Direği) emeği ve malzemesi artık emek ve ekonomi modellerindedir; eski «sahibi gelene dek geçerlidir» sözü kalktı. Ayrıntı: [İnşa ve Emek](/docs/buildings/construction-labour), [Üretim ve Depolama](/docs/settlement/production-storage).

## Yerleşim Defteri

`L` Defter'in II'den açılan «Yerleşim» sekmesidir ([K62](/docs/source/design/decisions#k62)); Defter'in sekmeleri Künye, Beceriler, Yoldaşlar, Çeteleler, Adlar, Kış Hesabı ve Zula, Yerleşim'dir. Ordugâhta aynı sayfa ordugâhı gösterir; üstte yer seçici: «Yurdun» · «Ordugâh». Kervan sayfası bu sekmenin içindedir. Açıkken oyun durur.

| Bölüm | İçerik |
|---|---|
| Özet | Ad ve kademe; hane (yurtta, çadırda), can; yiyecek, yem, yakacak günü; Gönül ipi; Çekim işareti; «Yolda bir hane var» |
| Halk | Kökene göre hane; yurtlu, çadırlı ve barınak bekleyen; ustalar adlarıyla; seferberlikte olanlar |
| İş | Altı iş: sayı, artı ve eksi, kilit; Kâhya aç ve kapa; işin günlük çıktısı |
| Ambar | Kategori çubukları ve eşya ızgarası; kap doluluğu |
| Sürü | Baş, at eşdeğeri, çoban kapsamı, otlak günü |
| Yapılar | Şantiye ve yapı listesi, öncelik, gece emri, bakım borcu |
| Kervan | Buyruklar, yoldaki arabalar, son kartlar; Ocak'ta tek satır: «Onluğun azığını bir atlı alır.» ([K54](/docs/source/design/decisions#k54)) |
| Kademe | Sonraki kademenin koşulları, işaretli |

Sayı kuralı: Kut ve Korku sayı göstermez; Gönül düğümdür, Çekim dört kademelidir; hane ve gün sayıdır. Hazine terazi ve yanında «≈{n} kabuk» gösterir ([K48](/docs/source/design/decisions#k48)).

Defter dışında: yer adı satırı («Tanhu Ordusu · Oba»), atlasta yerleşim ve ordugâh simgesi, minik kervan arabası, kısa bildirimler (en çok 30 saniyede bir): «Yeni bir hane geldi.», «{n} hane barınak istiyor.», «Kervan Islık Alanı'na vardı.», «Ay doluyor. Atları içeri alın.», «Akıncılar sürüye dadandı.», «Ambar doldu: {kap}.»

```varlik
ui_ledger_book
```

## Kum havuzu

I. Perde hikâyede yerleşim vermez, ama altyapı onunla sınanır (K23). Kum havuzu yalnız geliştirme içindir, oyuncu görmez: üç Ocak Yeri, düğüm kümeleri, 10 hane, dolu ambar. Prototipte bunun bir adresi ve ölçütü vardı (Plan Kipi ile 20 yurt, saat ×60, kaydet ve yükle aynı; 200 rastgele yerleşimde yol bağlantısı kopmaz; yapay V. kademe karesi bütçe içinde). Godot'da işin bitiş ölçütü II'nin «Yerleşim, ordugâh ve ekonomi» fazının çıkışıdır ([godot.md](/docs/source/design/godot)): Ocak ve Oba kurulur (3 → 10 hane); Plan Kipi yapıyı yere koyar ve yalnız değen navmesh karolarını yeniden pişirir; iki tür hane gelir ve İsteyen Hane kartı çalışır; Azıkçı Ocak'ta, kervan Oba'da işler; Kâhya şantiyeye el tavanına dek el verir; Godot ekonomisi `econ-sim`'in resmî koşusuyla toleransta aynıdır; Üç Ocak Yeri'nin uzaklıkları yol ağıyla ölçülmüştür.

## Oyunda şu an

> [!DURUM]
> Godot'da yok: Plan Kipi, `P` eylemi, yer kuralları, parseller, alt şerit ve önizleme, Araba kartı, şantiye ve aşamalı kurulum, Yerleşim Defteri, kum havuzu. Godot'nun tuş haritasında bugün yalnız yürüme, koşma, kamera, onay ve geri al, menü ve tam ekran eylemleri vardır; menü kampının yurtları ve ahırı kurulmaz ([d3/game-state](/docs/source/design/d3/game-state)). Prototipte denendi (saf kod ve sınama, oyuna bağlanmadı): emek yasası ve yapı adımları, Yurt Yükü, şantiye yığını kabı; prototipte `P` tuşu tuş haritasına yazılmıştı ama bir şey açmıyordu.

## Yol haritası

Plan Kipi ve Yerleşim Defteri II. Perde'nin «Yerleşim, ordugâh ve ekonomi» fazındadır ([madde](/roadmap#item-plan-mode)); Üç Ocak Yeri'nin ölçümü aynı fazın ölçüm maddesindedir ([madde](/roadmap#item-settlement-measure)); yerleşimin iç haritası ondan önceki dünya fazındadır ([madde](/roadmap#item-tanhu-ordu-map)).

```ilerleme
act-2-p2
```

## Kaynaklar

- [decisions.md: K23, K46, K50, K51, K52, K57, K62, K80, K82](/docs/source/design/decisions#k57)
- [settlement.md §2.3: kapılar](/docs/source/design/settlement#2-3-kapilar), [§3.2: Ocak Yeri](/docs/source/design/settlement#3-2-tanhu-ordu-ic-haritasi-taslak), [§4.1: kademe tablosu](/docs/source/design/settlement#4-1-tablo), [§4.2: el tavanları](/docs/source/design/settlement#4-2-tam-bilesim)
- [settlement.md §7: yapı kataloğu](/docs/source/design/settlement#7-yapi-katalogu), [§7.8: taşıtlar ve Araba kartı](/docs/source/design/settlement#7-8-tasitlar), [§13: yerleşim kuralları](/docs/source/design/settlement#13-yerlesim-kurallari), [§14: arayüz](/docs/source/design/settlement#14-arayuz)
- [structures.md §2.4: emek yasası](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21), [economy.md §10.5: yapı başına sonuçlar](/docs/source/design/economy#10-5-yapi-basina-sonuclar-model)
- [godot.md: fazların çıkış ölçütü](/docs/source/design/godot), [d3/register.md: cevap 46, 47, 48](/docs/source/design/d3/register), [d3/game-state](/docs/source/design/d3/game-state)
- `docs/design/d2/settlement-model.json`: `placement`, `plan`, `buildings`; `docs/design/d2/labour-model.json`: `law.build`, `crew`
