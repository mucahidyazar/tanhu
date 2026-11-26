---
title: Kamera ve Kontroller
order: 10
status: kismen
summary: 'Varsayılan kadraj Diablo tarzıdır, uzak ve yüksektir (eğim 38°, görüş 36°, 28 m, kuzey); yakın plan yoktur; oyuncu 360° döndürür, eğimi 15–60° bandında değiştirir, 14–40 m yakınlaştırır, / ile varsayılana döner; kadraj dışındaki tehdit okla, yoldaş kartla ekran kenarında okunur.'
sources:
  - docs/design/decisions.md
  - docs/design/godot.md
  - docs/design/act1.md
  - docs/design/story.md
  - docs/design/companions.md
  - docs/design/army.md
  - docs/design/travel.md
  - docs/design/settlement.md
  - docs/design/d3/oyun-durumu.md
  - docs/design/d3/register.md
  - docs/research/oyun-seviye-tasarimi.md
  - game/scripts/player/follow_camera.gd
  - game/scripts/settings/game_settings.gd
---

## Özü

Kamera oyuncuya uzaktan ve yukarıdan bakar: Diablo kadrajı. Varsayılan eğim 38°, uzaklık 28 m, dikey görüş açısı 36°; Çocukluk'ta ve Serbest Gez'in Çocuğunda uzaklık 22 m'dir. Kamera kuzeye bakar, oyuncu ekranın ortasındadır. Oyuncu kamerayı 360° döndürür, eğimi bir bantta değiştirir, 14–40 m arasında yakınlaştırır; yakın plan ve omuz üstü kadraj yoktur. `/` tuşu üçünü de 0,5 sn'de varsayılana geri getirir. Sana zarar verebilen her şey ya kadrajdadır ya ekran kenarında oku yanar; kadraj dışında kalan yoldaşın yuvarlak kartı ekran kenarında, onun yönünde durur.

> [!NOT]
> «Tanhu - Diablo tarzı kamera bakış açısı olacak ve kamerayı döndürebileceğim istediğim açılara»

> [!NOT]
> «kamerayi istedigimiz gibi donderebilelim, uzaklik icinde yakinlasabilelim ama genel default diablo tarzi olacak»

> [!NOT]
> «ve sunuda unutma gorev cekımlerı etc yakın cekım olmayacak uzak cekım olacak dıablo gıbı ornek resım ekledım sahnelerı buna gore duzenle ana menudeki sahnede dahil sinematografik oyun içi sahneler de dahil»

Karar [K98](/docs/source/design/decisions#k98): menü sahnesi, görev sahnesi, oyun içi sinema ve oynanış aynı aileden çekilir: eğim 35–50°, görüş 30–40°, ufuk görünmez, kişi kare yüksekliğinin ≈%6–15'i. Yakın plan, omuz üstü ve yüz çekimi yoktur; söz altyazıda ve portrede durur. Yüz yalnız oluşturucuda ve Destan Kitabı'nda yakından görünür. Yurt içinde çatı kalkar, içerisi yukarıdan görünür; kamera kapalı alana girmez. Ufku isteyen kare (Önsöz'ün geniş karesi, güneş, ay) eğimi düşürür, uzaklığı ≥40 m tutar. Parşömen videoları bu kuralın dışındadır. Gönderdiğin görsel kadraj ve mesafe referansıdır, görsel kaynağı değildir.

![Kadraj referansı (K98): açı ve mesafe için](/media/docs/media/review/kadraj_referans.webp)

Karar [K39](/docs/source/design/decisions#k39): varsayılan Diablo kadrajıdır; açı, eğim ve uzaklık oyuncuya açıktır; tek tuş varsayılana döndürür. Kovalamacada da döndürme açık kalır (#17). Dönüş hızı ve fare hassasiyeti ayardır, tuşlar yeniden atanır ve kaydedilir (#18). [K27](/docs/source/design/decisions#k27)'nin girdileri genişler. Kalıp «üstüne yazılan pay»dır: ön ayar değişmez, oyuncunun payı üstüne eklenir ve tek tuşla silinir. Diablo sabit kamerayla adil kadraj kurar, Baldur's Gate 3 ve Dragon Age serbest kamerayı tuşla ve sıfırlamayla dengeler; kullanıcı ikisini birden istedi ([oyun-seviye-tasarimi.md §6.1](/docs/source/research/game-and-level-design#6-1-ornekler)).

![Godot: Serbest Gez'in açılışı, altta tuş ipuçları](/media/docs/research/menu-shots/x_hud.jpg)

## Varsayılan kadraj

Ölçü Godot takip kamerasının bugünkü açısıdır ([K98](/docs/source/design/decisions#k98)). Menü kamerası da aynı eğim ve görüş açısıyla, ateşe 26,4 m'den bakar: menüden oyuna geçişte kare sıçramaz.

| Büyüklük | Değer |
|---|---|
| Eğim (ufka göre aşağı bakış) | 38°; varsayılandan öteye uzaklaşınca en uzakta 44° |
| Uzaklık | 28 m; bant 14–40 m; Çocukluk'ta 22 m |
| Dikey görüş açısı | 36°; ayarda Dar 32°, Geniş 40° ([K103](/docs/source/design/decisions#k103)) |
| Bakılan nokta | Ayağın 0,7 m üstü; ileri pay yok, oyuncu ekranın ortasında |
| Açılış yönü | Kuzey |
| Düz zeminde görüş | Kuzeye ≈27 m, güneye 10 m; en uzakta (40 m) kuzeye ≈30 m, güneye ≈14 m |
| Yana görüş | Kahraman hizasında ±16,4 m, kadraj tepesinde ±28,8 m |
| Üst ışın | Ufkun 20° altında: gök görünmez; eğim 18°'nin altına inince görünür |
| Kişinin boyu | 1,8 m'lik kişi 1080p'de ≈84 piksel, karenin %8'i; 1,1 m'lik çocuk 22 m'de ≈65 piksel |

K98'den önce varsayılan 23,35°, 27 m ve 41,76°'ydi: kuzeye ≈240 m, güneye 13 m, kahraman hizasında ±18,5 m görünüyordu.

**Neden kuzey.** I. Perde'de ev kuzeyde, Adak Ağılı güneydedir: kaçış varsayılan kadrajda bütün vadiyi bakılan yönde sürer. Oyuncu döndürürse yön dünyadan okunur: uzun gölgeler, Kızıl Kazık, direk uğultusu, gece Demirkazık ([act1.md §4](/docs/source/design/act1#4-dunya), [story.md §7.5](/docs/source/design/story#7-5-kamera-12-17-18)). K98 kadrajında kuzey görüşü ≈27 m'dir, vadiyi taşımaz: düzen kalır, gerekçesi yeniden kurulur ([Yol Haritası](/roadmap#item-k98-recalc)).

| Kuzeye doğru zemin eğimi | −7° | −3° | 0° | +3° | +6,6° | +10° |
|---|---|---|---|---|---|---|
| Kuzey görüşü (K98) | 41,1 m | 31,8 m | 27,2 m | 23,8 m | 20,7 m | 18,3 m |
| K98'den önce | Sis | Sis | 240 m | 108 m | 65 m | 47 m |

Eski kadrajda inen yamaçta üst ışın zemine değmiyordu, görüşü sis ve yamacın sonu kesiyordu; K98 kadrajında −7°'de de değer.

**Seviye kuralları.** Yer işareti zinciri düzde ≤65 m, yokuşta ≤35 m; K98 kadrajında 65 m kadrajın dışında kalır, zincir yeniden kurulur ([Yol Haritası](/roadmap#item-k98-recalc)). 8,5 m'lik yurt ekran ortasında ardındaki ≈14 m'yi gizler (eskiden ≈18 m): doğu-batı sokakları yurtların güneyinden geçer, kuzey-güney sokakları en az 9 m geniştir. Döndürülen kamerada araya giren yapı, dal ve kaya saydamlaşır.

## Döndürme, eğim ve yakınlaştırma

Üç eksen birbirinden bağımsızdır; biri ötekini değiştirmez.

- **Açı.** 360° serbest. Klavyede 110°/sn (ayar 60–160°/sn), farede 0,3°/px (ayar 0,1–0,5°/px). W her açıda ekranda ileridir; tıkla yürü değişmez.
- **Eğim.** `eğim = uzaklığın eğimi + ayar payı + oturum payı`, 15° ile 60° arasında. Uzaklığın eğimi bugünkü koddadır: yakınlaşınca eğim düşmez (omuz üstü kadraj yoktur), başlangıç uzaklığının ötesinde en uzağa dek 6° dikleşir. Oturum payı −8° ile +36°, ayar payı −8° ile +20° arasıdır. Sınırın son 4°'sinde hız ×0,3'e düşer: kamera sınıra çarpmaz, yavaşlar. 60°'nin üstüne yalnız zemine gömülmeme kuralı çıkar (kamera yerden en az 1,2 m yukarıda). 15°'de karenin üst ≈%9'u göktür; bütçe bandın iki ucunda da ölçülür. K98'in oynanış ailesi 35–50°'dir ve ufuk görünmez: bandın K98'e uyması yeniden ele alınır ([Yol Haritası](/roadmap#item-k98-recalc)).
- **Uzaklık.** 14–40 m, tekerlek adımı 1,8 m; kıstırma da yakınlaştırır. Nişan almak kamerayı yaklaştırmaz.
- **Varsayılana dönüş.** `/` (Türkçe Q'da nokta) kısa basışta açıyı kuzeye, oturum eğimini 0'a, uzaklığı 28 m'ye (çocukta 22 m) 0,5 sn'de döndürür. Ayarın eğim payı kalır: oyuncunun seçtiği varsayılan odur. Orta tık (sürüklemesiz) yalnız kuzeye hizalar.
- **Kayıt.** Açı ve oturum eğimi kaydedilmez, menüye dönüşte sıfırlanır; Serbest Gez her oturumda kuzeye bakarak açılır. Menü, Yeni Oyun ve oluşturucu bu açıyı okumaz: menü karesi değişmez.

| Girdi | İş | Not |
|---|---|---|
| Orta tuş, yatay sürükleme | Döndürür | 12 px'te baskın eksene kilitlenir |
| Orta tuş, dikey sürükleme | Eğim, 0,15°/px | Yeni (K39) |
| Orta tık, sürüklemesiz | Kuzeye hizalar | K27 |
| Shift + tekerlek; iz dörtgeninde yatay kaydırma | Döndürür | K27 |
| Alt + tekerlek | Eğim, çentik başına 2° | Yeni |
| Tekerlek, kıstırma | Uzaklık 14–40 m | Adım 1,8 m |
| `,` ve `.` basılı | Sola, sağa döndürür | Türkçe Q'da Ö ve Ç |
| `;` ve `'` basılı | Eğim, 40°/sn | Yeni; Türkçe Q'da Ş ve İ |
| `-` ve `=` | Yaklaştırır, uzaklaştırır | Yeni |
| `/` kısa | Varsayılana döner | Türkçe Q'da nokta |

Tuş adları klavye dizilişinden okunur; kayıt fiziksel tuşu tutar, dizilişten bağımsızdır.

Doğrulanacak: eğim bandının iki ucunda (15° ve 60°) kadraj ve kare bütçesi ölçülür; ses dinleyicisi için kabul, kamera 14 m'den 40 m'ye giderken oyuncunun yanındaki ateşin ±1,5 dB içinde kalmasıdır ([Yol Haritası](/roadmap#item-camera-pitch)).

**Geçiş dönemi.** Godot'da bugün Q/E basılıyken ve sağ tuşla sürüklerken kamera döner. Hikâye sistemleri fazına ([act-1-p3](/roadmap#act-1-p3)) dek iki atama birlikte durur. O fazda dövüş ve etkileşim gelince Q/E ve sağ sürükleme varsayılandan çıkar: sağ tık nişan, E kullan olur; Q I. Perde'de Çığırtkan, II'den hızlı silahtır ([K82](/docs/source/design/decisions#k82)). Oyuncu isterse eski atamayı yeniden bağlar.

## Ön ayarlar

Duruma göre bir ön ayar devreye girer, geçiş 1,1 sn'de karışır. Sayılar Godot tabanından hesaplandı ve K98 kadrajıyla yeniden hesaplandı ([act1.md §4](/docs/source/design/act1#4-dunya)); oyuncu payı sıfırken geçerlidir, oyuncunun eğim payı üstüne eklenir. Çömelme ve Sürüş K98'e göre yeniden kurulur ([Yol Haritası](/roadmap#item-k98-recalc)).

| Durum | Eğim | Uzaklık | Ne görünür |
|---|---|---|---|
| Yürüyüş (varsayılan) | 38° | 28 m; çocukta 22 m | Kuzeye ≈27 m, güneye 10 m |
| Çömelme | Yeniden kurulur | | Kural: nöbetçinin 16 m'lik görüş çemberi kadrajdadır, seni görebilen her şey kadrajdadır. K98 kadrajında 40 m'de bile güneye 13,6 m görünür (eskiden en az 36 m ve 27,5°) |
| Sürüş | Yeniden kurulur | 30 m | Eski düzde 23,9° ve yokuşta 18,9° K98'in 35–50° ailesinin dışında kalır |
| Bakış Noktası | 15° | 44 m, 4 sn | Üst ışın ufkun 3° üstünde: gök ve vadi birlikte, harita levhası açılır; K98'in ufuk istisnası |
| Tengri, Yar Bakışı | 13° | 70 m, 6 sn | 6 sn'de 180° döner; bütün vadinin fenerleri ve gök, kar bir an durur; K98'in ufuk istisnası |
| Oda (yurt, ahır içi) | | | K98: kamera kapalı alana girmez; çatı kalkar, içerisi yukarıdan görünür (eskiden 46°'lik kesit); çıkınca seçilen açıya geri gelir |
| Plan Kipi | 50° | 64 m (40–120 m) | İmleci yumuşak izler ([settlement.md §14.1](/docs/source/design/settlement#14-1-plan-kipi-plan-mode)) |

- **Atta.** «Kamera takibi» açıksa yaw ata 1,1 sn gecikmeyle döner, en çok ±75°; elle döndürmeden sonra 2 sn bekler. Kapalıysa oyuncunun açısı kalır.
- **Sahne çekimleri.** Bakış, Tengri, oda ve büyük sahnelerin çekimleri (Tündük 34°, Toy 28°, Göz Yolu 20°) kamerayı geçici alır, oyuncunun payını bekletir; bitince oyuncunun açısı geri gelir. Tündük, Toy ve Göz Yolu'nun sayıları prototipin 38°'lik görüş açısıyla yazıldı; Godot'da K98'in uzak kadrajıyla kurulur. Açılıştaki araba çekimi (24°, 26 m) K98'in ailesinin dışındadır, uzak kareyle yeniden kurulur. Yolcu da kamerayı döndürür ve yakınlaştırır ([travel.md §6.3](/docs/source/design/travel#6-3-yolcu-kamerasi)).
- **Çocuk.** Serbest Gez'in Çocuğu ve Çocukluk'un küçük Mete'si yürüyüş ön ayarını 22 m'den kullanır. Çocukta sağ tuş nişandır, kamerayı orta tuşla sürükleme döndürür; E'nin işi varken (bin, al) kamera E ile dönmez.
- Godot'da bugün yalnız yürüyüş ön ayarı vardır; ötekiler ön ayar kaydı olarak eklenir ([godot.md §5.7](/docs/source/design/godot#5-7-on-ayarlar)).

Doğrulanacak: Tündük, Toy ve Göz Yolu çekimlerinin Godot karesi sabit pozla kurulur ve göz onayından geçer ([Yol Haritası](/roadmap#item-camera-pitch)).

## Parti ve birlik

Kamera parti ve birlik için uzaklaşmaz: varsayılan 28 m kalır, ileri pay yoktur ([K70](/docs/source/design/decisions#k70)). Godot hesabıyla kama düzeni 16,8 m derin, 9,6 m geniştir; Mete düzenin ortasındayken on atlının hepsi varsayılan kadrajdadır, dörtnalda düzen açılınca arkadaki sancak kadrajın alt kenarına dayanır; Mete tepedeyken K98 kadrajında atlıların yarısı dışarıda kalır ([army.md §4.3](/docs/source/design/army#4-3-kadraj-olcumu)). Varsayılan kamerada 10 m'den çok geride ya da 16 m'den çok yanda kalan yoldaş ekrandan çıkar; onu ekran kenarındaki kartı gösterir. Oyuncu isterse 40 m'ye kendi açar. Prototipin +6 m'lik birlik payı Godot'da uygulanmaz.

## Kadraj sözleşmesi ve ekran kenarı

Kural kameradan bağımsızdır: sana zarar verebilen her şey ya kadrajdadır ya ekran kenarında oku yanar; kadraj dışından ilk vuruş yoktur. Dönen kamerada da adillik böyle korunur ([act1.md §10](/docs/source/design/act1#10-kovalamaca-kara-boran-black-blizzard), [godot.md §5.4](/docs/source/design/godot#5-4-kadraj-disi-tehdit-ve-yoldas-gostergesi-17-k73)).

**Tehdit oku.**
- Ok vuruştan en az 1,2 sn önce yanar; zemin çizimi de 1,2 sn önce çizilir.
- Sınama 0,1 sn'de bir, kameranın görüş hacmiyle ve %5 payladır. Kadraj dışındaki tehdit ekranın %92'lik elipsine konur. En çok 3 ok; fazlası en yakın okta sayı olur.
- Biçim durumu söyler, renk yalnız ektir: boş üçgen izliyor, dolu üçgen yanaşıyor, halka ateş edecek, kanca kement atacak. Boy uzaklığı verir.
- Yön ekran merkezindendir. Önde izdüşüm, kameranın arkasında zemin düzlemindeki yön kullanılır: ileri ekranda yukarı, geri aşağıdır.
- Sinemada kapalı, her zorlukta açıktır: adillik kuralıdır, elmas işaretten ayrıdır.

**Yoldaş kartı** ([K73](/docs/source/design/decisions#k73)). Kadraj dışındaki yoldaşın kendi portresinden yuvarlak kartı ekran kenarında, onun yönünde durur; kartın baklavası yoldaşı gösterir. Ok ve kart tek ailedir: aynı yön hesabı, aynı güvenli alan, HUD'un aynı yasak bölgeleri. Yerleri ayrıdır: ok elipste, kart yuvarlatılmış iç dikdörtgende (yanlardan 64, üstten ve alttan 60 px). Ok her zaman öndedir ve portresizdir; kart üçgen kullanmaz, durumu rozetle söyler. Oka 64 px'ten yakın kart kenar boyunca en çok 80 px kaçar, kaçamazsa %50 saydamlaşır. Karta sol tık kamerayı yoldaşa çevirir: yalnız açı, en kısa yönden, 0,6 sn; yoldaş yine kadraj dışındaysa uzaklık 40 m'ye dek açılır. Sinemada ve kovalamacanın betikli anlarında çevirme kapalıdır. Bütün kurallar: [Yoldaşlar](/docs/gameplay/companions).

```varlik
ui_threat_edge, ui_offscreen_indicator
```

**Kovalamaca** (#17). Döndürme ve eğim açıktır. At izlemesi elle döndürmeden sonra 2 sn bekler. Varsayılan kadraj arkayı 10 m gösterir (K98; eskiden 13 m). Bu yüzden takipçi ateş etmeden önce ya kadraja yandan çıkar (kahramanın ±12–16 m yanına; nokta kameranın o anki sağından ya da solundan seçilir, kamera dönerse yeniden seçilir) ya da oku en az 1,2 sn yanar.

**Ses yönü.** Dinleyici oyuncunun 1,5 m üstündedir, yönü kameranın yatay açısıdır: arkadaki toynak arkada duyulur; ön ve arka ucuz bir süzgeçle ayrılır. Menüde, sinemada ve oluşturucuda dinleyici kameradadır. Gerekçe: 28 m'lik kamerada dinleyici kameraya bağlı kalsaydı kahramanın 30 m arkasındaki takipçi kameranın altında, yönsüz duyulurdu ([oyun-seviye-tasarimi.md §6](/docs/source/research/game-and-level-design#6-kamera)).

**Çömelme ve gizlilik.** Çömelince kamera nöbetçinin 16 m'lik görüş çemberini kadraja alacak kadar açılır; K98 kadrajında bu kural yeniden kurulur ([Yol Haritası](/roadmap#item-k98-recalc)). Kadraj dışındaki şüphe de kenar okuyla okunur ([K44](/docs/source/design/decisions#k44)).

Doğrulanacak: tehdit oku ve ses yönü I. Perde'nin hikâye sistemleri fazında kovalamaca senaryosuyla sınanır ([tehdit oku](/roadmap#item-threat-edge), [kovalamaca](/roadmap#item-chase)); yoldaş kartının sayıları ekranda ayarlanır ([Ku ve kenar göstergesi](/roadmap#item-ku-card-edge)).

## Harita ve kamera

Harita yürünmez; haritadan oyuna ve oyundan haritaya tekerlekle geçilir ([K40](/docs/source/design/decisions#k40)).

- **Haritadan oyuna.** Yüklü iç haritada en yakın düzeye (görüş genişliği 0,085 birim) varınca harita kapanır, kamera 1,6 sn'de oyun kamerasına karışır, saat akar, oyuncu yer değiştirmez. Tekerlek 0,35 sn ve 150 ms sessizlik dolana dek yutulur: dokunmatik yüzeyin ataleti oyun kamerasını da yakınlaştırmasın. M'ye basmak gerekmez.
- **Oyundan haritaya.** Kamera en uzaktayken (40 m) 0,6 sn içinde 3 çentik daha harita açar. Kovalamacada, dövüşte, sinemada ve Plan Kipi'nde kapalıdır; «Tekerlekle harita» ayarıyla kapanır. M kısayol kalır.
- Başka yere yakınlaşma 6 birimde durur; tık Yol Kartı'nı açar. Işınlanma yoktur ([Harita ve Ölçek](/docs/world/map)).

## Yeni Oyun'da geri çekilme

> [!NOT]
> «yeni oyun dedigimizde kamera ozana zoom yapmayacak hafif uzaklasacak belki 2-3 kat ve kamp gokyuzu daglar ayni akrede gozukecek …»

Karar [K68](/docs/source/design/decisions#k68): Yeni Oyun'a basınca menü yazıları 0,5 sn'de söner. Kamera ozana yaklaşmaz, menü kadrajından 6 sn'de geri çekilir; giriş ve çıkış yumuşaktır, yön (kuzey) değişmez, görüş 36°'den 41,76°'ye açılır.

| An | Ateşe uzaklık | Eğim | Ufuk ve ateş (yukarıdan) |
|---|---|---|---|
| Menü kadrajı, 0 sn | 26,4 m | 38° | Ufuk karede yok; ateş %60 |
| Yolun ortası, 3 sn | 32,7 m | 23,5° | Ufuk karede yok (4 sn'de %10); ateş %66 |
| Geniş plan, 6 sn | 40,0 m | 9° | Ufuk %29; ateş %80 |

- 40 m ateşe menü kadrajının 1,52 katıdır. K98'den önce menü kadrajı ateşe 16,2 m'deydi ve geri çekilme 2,47 kattı, kullanıcının «2-3 kat»ı; K98 menü karesini uzaklaştırdı, onaylanan geniş kare yerinde kaldı ([K95](/docs/source/design/decisions#k95)). Kamera yine ozana hiç yaklaşmaz. Bu uzaklık takip kamerasının en uzak yakınlaştırmasıdır ve varsayılanın (28 m) 1,43 katıdır.
- Son karede dağ zirveleri yukarıdan %10'a dek çıkar, üstte gök kalır; vadi ve göl ortada, kamp alt üçte birdedir. Yol ve son kare çam tacına ve kayaya en az 1,6 m pay bırakır.
- Işık menünündür, saat okunmaz. Gök kubbesi ilk kez görünür: yıldızlar 4,0–6,0 sn arasında %35'e açılır, ay yoktur.
- Kamera geniş planda menünün salınımıyla (0,06 m, 0,18 Hz) nefes alır. Ozan 4,2 sn'de kopuzu kaldırır; kamera durunca, 6,0 sn'de şarkı başlar. Şarkı geniş planda söylenir: yüz yakın planı ve ağız eşlemesi yoktur.
- Şarkıdan sonra 3 sn alçak sessizlik, 2 sn kararma, 1 sn kara ekran; ardından mit sineması açılır. Menüye dönüş karesi değişmez. Sahnenin bütünü: [Önsöz](/docs/story/prologue).
- Menü, Yeni Oyun ve Önsöz Godot'nun gece menüsünün ışığında kalır. Serbest Gez ise 11 Nisan MÖ 209, 14:46,2'de açılır: gece menüsünden bu ikindi ışığına 2,4 sn süzülerek geçilir, süzülme menüden gelen 1,6 sn'lik kamera karışımıyla aynı anda başlar ([K76](/docs/source/design/decisions#k76)).

Geniş kare kamp satırını tutar (2026-11-07: 14,67 ms, hedef 16,7 ms, sınır 33 ms); kamera yolu 0, 3 ve 6 sn'de çam tacına ve kayaya payını korur; kareyi onayladın ([Yol Haritası](/roadmap#item-prologue-pullback)).

## Tuş tablosu

Tablo tasarımın klavye tuşlarıdır; bütün tuşlar yeniden atanır. Bir tuş kısa basış ve basılı tutuşla iki iş görebilir.

| Tuş | Eylem | Godot'da bugün |
|---|---|---|
| W A S D, oklar | Yürü; W her açıda ekranda ileri | Var |
| Shift | Koş; atta mahmuz (+3 m/sn, stamina) | Koşu var; Çocukluk'ta koyunu dürter |
| Sol tık | Yere yürü (yol bulunur); basılı tutunca imleci izler; etkileşimli şeye yürür, iş orada başlar; WASD yolu keser | Yok |
| Sağ tık | Nişan: yay basılı gerilir, bırakınca atılır | Bugün kamerayı sürükler; çocukta oyuncak yayla nişandır, sol tık bırakır |
| E | Kullan, ata bin; bazı işler basılı | Bugün kamerayı döndürür; çocukta koyuna bindirir, indirir, düşeni alır, o an kamerayı döndürmez |
| Q | I. Perde'de Çığırtkan; II'den hızlı silah, yay ile yakın silah arasında ([K82](/docs/source/design/decisions#k82)) | Bugün kamerayı döndürür |
| Boşluk | Zıpla; hedef kilitliyken savuş; atta sıçra | Yok |
| C | Çömel, aç-kapa; atta eğil | Yok |
| F | Kısa: sapan; ateşte 1 sn basılı söndürür; kor evresinde 2 sn Küle Yatır | Yok |
| Y | Ateş: 3 m içinde yakıt ekler, uzakta yer seçer ([K45](/docs/source/design/decisions#k45)) | Yok |
| T | Bekle tekeri: döşekte Uyu, ateş başında Dinlen, şantiyede Çalış | Yok |
| G | Kısa: Ku'ya Bak; 0,6 sn basılı: Yükü Bırak | Yok |
| 1–6 | Çubuk: etkin beceri ve sarf eşyası; II'den Çığırtkan 6. yuvada | Yok |
| Z, X | İzle, Dur; X 0,4 sn basılı Burayı Tut; Shift + Z Geri Çekil | Yok |
| V, R, B | Saldır (fare noktasına); Islık (basılı tut, bırak); Düzen | Yok |
| 7, 8, 9, 0 | Topla, Avla, İz Sür, Gizlen | Yok |
| F1–F10, H | Yoldaş seç, Shift ile ekle; H hepsi | Yok |
| N, Tab basılı | Buyruk Halkası; kartlarda ad ve uzaklık | Yok |
| I, J, L, K | Heybe, Görevler, Defter, Beceriler | Yok |
| P | Defter > Yoldaşlar ([K70](/docs/source/design/decisions#k70)) | Yok |
| M | Harita | Yok |
| Esc | Geri; oyunda duraklatma kitabı | Var |
| F5, F9, F11 | Kaydet, yükle, tam ekran | Var |

- **Menülerde** oklar ya da WASD gezinir, Enter ve Boşluk seçer, Esc geri döner, Q ve E sayfa çevirir, Z ve C bölüm değiştirir. Oyun kolunda A seçer, B geri, LB ve RB sayfa çevirir. Bunlar Godot'da vardır.
- **Plan Kipi'nde** Q ve E yapıyı 15° döndürür (Shift ile 5°), tekerlek yakınlaşır, haritayı açmaz. `P` [K70](/docs/source/design/decisions#k70) ile Defter > Yoldaşlar'ın kısayoludur; `settlement.md` §14.1 Plan Kipi'nin açılışına da `P` yazar. Belge üstünlüğüyle (K31) `P` Defter'indir; Plan Kipi'nin tuşu o belgede yeniden atanır.
- **Oyun kolunda** buyruklar D-pad'dedir, düzen LB, ıslık RT, Buyruk Halkası View basılı ([army.md §6.1](/docs/source/design/army#6-1-tablo)). Oyun içi kol ataması Yol Haritası'ndadır ([release-p2](/roadmap#release-p2)).
- **macOS.** Çoğu Mac klavyesinde F1–F10 ortam tuşudur; oyun bunları fn olmadan alamaz. Parti ilk kurulduğunda tek seferlik ipucu çıkar, şerit kartına tıklamak her zaman seçer ([godot.md §5.3](/docs/source/design/godot#5-3-girdi)).

## Ayarlar

![Godot: Ayarlar > Oyun](/media/docs/research/menu-shots/book_settings_0.jpg)

| Ayar | Değerler | Varsayılan | Godot'da bugün |
|---|---|---|---|
| Kamera dönüş hızı | 60–160°/sn | 110°/sn | Var |
| Fare hassasiyeti | 0,1–0,5°/px | 0,3°/px | Var |
| Kamera takibi | Yumuşak, Normal, Sıkı | Normal | Var |
| Görüş açısı | Dar 32°, Normal 36°, Geniş 40° | Normal (36°) | Var |
| Eğim payı | −3° ile +12° | 0 | Var |
| Oyunda eğim | Açık, kapalı | Açık | Var |
| Ters yatay, ters dikey | Açık, kapalı | Kapalı | Var (ters sürükleme) |
| Tekerlekle harita | Açık, kapalı | Açık | Kayıtta var; harita geçişi gelince sayfada |
| TV güvenli alanı | %0–5 | %0 | Yok |
| Yüksek karşıtlık | Açık, kapalı | Kapalı | Yok |

Yoldaş kartının ayarları (kenar kartı, kart boyu, uzaklık yazısı, adlar, şeridin yeri) [Yoldaşlar](/docs/gameplay/companions#ayarlar) sayfasındadır.

**Tuş atama.** Kontroller satırına «Değiştir» gelir: sonraki tuşu dinler. Tuş aynı bağlamda başka eyleme bağlıysa sorar: «Şuna da bağlı: {eylem}»; eski eylem boş kalmaz. «Varsayılana dön» bütün atamayı siler. Atama ayar dosyasının `[input]` bölümüne yazılır; bilinmeyen eylem ya da bozuk satır sessizce atlanır ([godot.md §5.6](/docs/source/design/godot#5-6-ayarlar-ve-tus-atamasinin-kaydi-18)).

![Godot: Tuşlar sayfasının atama görünümü](/media/docs/media/review/tuslar_atama.jpg)

> [!DURUM]
> Oyunda (Godot, 2026-11-08): takip kamerası K98'in uzak kadrajında; eğim 38°, görüş açısı 36°, başta 28 m, Çocukluk'ta 22 m. Q/E ve sağ tuşla sürükleme 360° döndürür (çocukta sağ tuş nişandır); orta tuşla sürükleme 12 px'te eksene kilitlenir (yatay döndürür, dikey eğer), sürüklemesiz orta tık kuzeye hizalar, Alt + tekerlek ve `;` `'` eğer; eğim bandı 15–60°, sınırın son 4°'sinde yavaşlar; `/` 0,5 sn'de kuzeye, oturum eğimi 0'a, 28 m'ye döner. Tekerlekle ya da MacBook'un dokunmatik yüzeyinde iki parmakla (kaydırma ve kıstırma; Alt'la eğer, yana kaydırma döndürür) 14–40 m; Godot jesti iki kopya verir, ikincisi yok sayılır. Ön ayarlar `CameraPreset` (yürüyüş, Sürüş, Çömelme, Oda, Bakış, Tengri), ata binince Sürüş; atta kamera atın yönünü 1,1 sn gecikmeyle izler (±75°, 135°'de bırakır, elle döndürünce 2 sn bekler), Ayarlar'da «Kapalı» seçilebilir. Ses dinleyicisi oyuncunun 1,5 m üstündedir: ateş 14–40 m'de 0,00 dB oynar. Ayarlar › Oyun: eğim payı (−3..+12°), oyunda eğim, ters sürükleme. Tuş atama: Tuşlar › Atama, `settings.cfg`'nin `[input]` bölümü. Bandın iki ucunun bütçesi ölçüldü (2026-11-08, kampın 202 pozu): 15°'de en kötü kare 16,5 ms, 60°'de 16,1 ms; sınır 33 ms, hedef 16,7 ms ([K103](/docs/source/design/decisions#k103)).

## Yol haritası

Takip kamerası temel fazında bitti; eğim bandı ve tuş ataması oyuncu ve dünya çekirdeği fazındadır ([eğim bandı](/roadmap#item-camera-pitch), [tuş atama](/roadmap#item-key-rebinding)). Tehdit oku ve kovalamaca hikâye sistemleri fazında ([tehdit oku](/roadmap#item-threat-edge), [kovalamaca](/roadmap#item-chase)), Ku'nun kartıyla ekran kenarı göstergesi aynı fazda ([Ku ve kenar göstergesi](/roadmap#item-ku-card-edge)), harita geçişi II. Perde'nin harita fazında ([harita geçişi](/roadmap#item-map-zoom)), Yeni Oyun'un geri çekilmesi Önsöz'ün ikinci fazındadır ([geri çekilme](/roadmap#item-prologue-pullback)).

```ilerleme
foundation-p4
act-1-p1
```

## Kaynaklar

- [decisions.md](/docs/source/design/decisions): [K27](/docs/source/design/decisions#k27), [K39](/docs/source/design/decisions#k39), [K40](/docs/source/design/decisions#k40), [K44](/docs/source/design/decisions#k44), [K45](/docs/source/design/decisions#k45), [K68](/docs/source/design/decisions#k68), [K70](/docs/source/design/decisions#k70), [K73](/docs/source/design/decisions#k73), [K82](/docs/source/design/decisions#k82)
- [godot.md §5](/docs/source/design/godot#5-kamera-12-17-18), [§3.6](/docs/source/design/godot#3-6-onsoz-sinemasi-k68), [§4.8](/docs/source/design/godot#4-8-atlas-ve-yakinlasinca-oyuna-gecis-10)
- [act1.md §4](/docs/source/design/act1#4-dunya), [§10](/docs/source/design/act1#10-kovalamaca-kara-boran-black-blizzard), [§15](/docs/source/design/act1#15-butce-ve-teknik-onkosullar)
- [story.md §7.5](/docs/source/design/story#7-5-kamera-12-17-18), `companions.md` §7.3, [army.md §4.3](/docs/source/design/army#4-3-kadraj-olcumu), [travel.md §6.3](/docs/source/design/travel#6-3-yolcu-kamerasi)
- [oyun-seviye-tasarimi.md §6](/docs/source/research/game-and-level-design#6-kamera), [d3/register.md](/docs/source/design/d3/register), [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- [Yoldaşlar](/docs/gameplay/companions), [Dövüş](/docs/gameplay/combat), [Ordu](/docs/gameplay/army), [Harita ve Ölçek](/docs/world/map), [Önsöz](/docs/story/prologue), [Arayüz ve Menüler](/docs/presentation/ui-menus), [Plan Kipi](/docs/settlement/plan-mode)
