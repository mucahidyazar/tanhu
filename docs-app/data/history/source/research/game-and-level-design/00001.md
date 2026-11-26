# Oyun ve Seviye Tasarımı Araştırması

Bu belge Tanhu'nun görev yapısını, iç harita seviye tasarımını, haritadan oyuna geçişi, takvim anlatımını, kamerayı ve küçük hayatta kalma kurallarını inceler. Amaç, cevap defterindeki #10, #11, #12, #13, #17, #18, #19, #20, #22, #23, #24, #25, #26, #28 ile Karar Bekleyenler (KB) 4, 7, 8, 9, 11 için uygulanabilir karar önermektir. Etiketler: [kaynak] bağlantılı bilgi, [çıkarım] kaynaktan ya da proje sayılarından çıkarım, [kurgu] oyun için önerilen uydurma. Kadraj hesapları `camera-rig.js` ön ayarları ve `game.js` `turnOffset` ile yapıldı: düz zemin, 16:9, düşey görüş 38°, hedef yüksekliği 0,6 m. Bugünkü değer (28°, 33 m) `act1.md` §4'ün 79 m, 8 m, ±17 m, ±60 m sayılarını verir: hesap doğrulanmış sayılır. Belge bir şüpheci sınamadan geçti; ne değiştiği Belirsizlikler'in son maddesindedir.

## Özet

1. **Görev kalıbı.** II–VI her perde: açılış, üç paralel kol, kapanış, son görev. 12–14 ana görev, perde başına 5 etkin yan görev ailesinde ≈15 yan görev, ≈12 XP'li keşif durağı (III'te ≤8). Sayılar XP bütçesinden ve K25'in ≈420 dakikasından çıkar.
2. **Sayaç yok (#19).** K25'in günü yalnız tasarım ölçüsüdür. Perde son görevle biter. Ana görev zamanla kapanmaz. Açık yan görev sessizce silinmez: son görev kapısında listelenir, Kronik'te sonuçlanır.
3. **I. Perde.** Kısıtlı kalır, sayıları değişmez. Açıklık hissi veriyle gelir: `J` listesi, kaçak ödül, görünür kapalı bölge, kişi yazan kilit.
4. **Kamera (#12, KB7).** Varsayılan 28° ve 33 m kalır. Yatay açı 360°, eğim 22–60°, uzaklık 13–44 m. `/` kısa basış kuzey, basılı tam sıfırlama. K27 genişler.
5. **Kadraj sözleşmesi (#17).** Kadraj yön değil frustumdur. Kadraj dışından ilk vuruş yoktur: tehdit önce kadraja girer ya da kenar oku 1,2 sn yanar. Dinleyici kameradan kahramana iner.
6. **Hesap düzeltmesi.** Çömelme kadrajı kodda 16,4 m değil 10,3 m arkayı gösterir (`CAM.crouch` `fwd` yazmıyor). Sürüşte arka 12 m değil 8,1 m, dörtnalda 5,5 m'dir. `act1.md`'nin 12 m ve ≈200 m sayıları `fwd 2` ile tam tutar: `CAM.ride`'a `fwd: 2` yazmak cümleyi değiştirmekten iyidir (öneri 10).
7. **Çapa.** Bu kamerada yükseklik görüş menzilini artırmaz. Üst ışın ufkun altında kalır. Yön dili üç menzile ayrılır: zemin ≤79 m, eğim ve ses ≤350 m, Bakış ve atlas.
8. **İç harita reçetesi.** 1.400×1.050 m için 14–18 adlı yer, bunların 3–8'i XP'li keşif durağı; 20–30 zemin işareti. Dörtnalda adlı yerler ≈36–41 sn aralık verir. Yürüyüşte duraklar ≈56–66 sn verir; ≈40 sn için hareketli olay gerekir, zemin işareti dikkat sayılmaz.
9. **Harita (#10, KB4) ve Kronik (KB9).** Yüklü iç haritada 0,085 birimde harita kapanır, oyun sürer. Başka yere yakınlaşma 6 birimde durur. Akan Kronik `T = clamp(mevsim × 5 sn, 30, 90)`.
10. **Küçük kurallar.** Yakıt `Y` (#23), çukur 24 oyun saati (#25), sağlam çadır bohçaya döner (#24), uyku zarı ateşe bağlı (#26), at üstünde yalnız elle hafif düğüm (#28). Tanhu Kampı sahnesiz konak olur (#11, #13).

## 1. Örnek oyunlar

| Oyun | Yapı [kaynak] | Tanhu'ya ders [çıkarım] |
|---|---|---|
| Witcher 3 | Ciri araması üç ipucuyla açılır: Velen, Novigrad, Skellige. Yan görev panodan çıkar, kontrat ve hazine ayrı ailedir, haritadaki noktalar küçük görev ve XP verir ([Wikipedia](https://en.wikipedia.org/wiki/The_Witcher_3:_Wild_Hunt)). The Isle of Mists görevine geçerken uyarı çıkar, ana hikâyeye bağlı açık görevler ve birkaç yan görev düşer, kontrat ve hazine düşmez ([GOG forumu](https://www.gog.com/forum/the_witcher_3_wild_hunt/isle_of_mists), 2015, oyuncu sözü); bu son bölge değil, bir hikâye eşiğidir. Başka bir kılavuz beş ana görevi eşik sayar, düşüşün sık sık uyarısız geldiğini yazar ([allthings.how](https://allthings.how/the-witcher-3-every-missable-quest-and-its-point-of-no-return/)) | Üç kol iyi bir ana zincir biçimidir. Düşen görevin listesi önceden verilmeli |
| RDR2 | Altı bölüm ve iki epilog, 110 görev; bölüm başına 6–21 ([GTA BASE](https://www.gtabase.com/red-dead-redemption-2/missions/?lang=en)). Kılavuza göre her bölüm bir kampa bağlıdır ([SegmentNext](https://segmentnext.com/red-dead-redemption-2/quests)); ama V. bölümün Guarma'sı kamp değil, gemi kazası adasıdır ([Wikipedia](https://en.wikipedia.org/wiki/Red_Dead_Redemption_2)) | Ortalama ≈14, aralık geniştir: 12–14 sayısı XP bütçesinden gelir, RDR2 yalnız ölçek sağlamasıdır. Yer değişimi perdeyi imler |
| GTA V | Giriş bölümünden sonra harita kısıtsız gezilir, görevler doğrusal ve hedeflidir ([Wikipedia](https://en.wikipedia.org/wiki/Grand_Theft_Auto_V)) | I. Perde yapı olarak giriş gibi çalışır, süre olarak değil (≈3 sa 40 dk). II. Perde'de dünya açılır, görev yine doğrusal olabilir |
| Ghost of Tsushima | Rüzgâr yön verir, sarı kuşlar ve tilkiler yerlere götürür, üç bölge sırayla açılır ([Wikipedia](https://en.wikipedia.org/wiki/Ghost_of_Tsushima)). GDC özeti: uçuşan yaprak, yol kesen tilki, kurtarılan köylünün haber verdiği ordugâh ([GDC Vault](https://www.gdcvault.com/play/1027399/Exploration-in-Ghost-of-Tsushima)) | Yönlendirme dünyada olur. Söylenti haritayı açar |
| Elden Ring | Harita işi ana boss yerleriyle başladı ([VideoGamer](https://www.videogamer.com/news/elden-ring-setting-was-designed-around-its-bosses/)). Miyazaki rota dayatmak istemediğini söyler ([PlayStation Blog](https://blog.playstation.com/2022/01/28/an-interview-with-fromsoftwares-hidetaka-miyazki/)). Lütuf noktası dönüş ve savaş dışı yolculuk yeridir ([Wikipedia](https://en.wikipedia.org/wiki/Elden_Ring)) | Önce çapalar yerleşir, arazi onlardan türer |
| Diablo IV | Giriş, altı perde, epilog; her perde boss ile biter ([GamePressure](https://www.gamepressure.com/diablo-iv/how-many-acts-are-in-the-game/z210c8f)). Perde 1–3 birlikte açılır, 4'ten sonra sıra zorunludur (Icy Veins ve PCInvasion özetleri, [Icy Veins](https://www.icy-veins.com/d4/guides/quick-reference-campaign-leveling-guide-for-diablo-4/); sayfa sınamada açılmadı, doğrulanamadı). Harita açıktır. Seviye engeli konusunda kaynaklar çelişir: GamePressure birçok yeri «level-locked» yazar, Wikipedia düşmanın oyuncuya göre ölçeklendiğini, bölgelerin her sırayla bitirilebildiğini yazar ([Wikipedia](https://en.wikipedia.org/wiki/Diablo_IV)) | Paralel kol kabul görmüş bir kalıptır. Diablo seviye engeli örneği sayılmaz; kişi kilidinin dayanağı `act1.md` §4'tür |
| Kingdom Come | NPC programı, uyku ve yemek ihtiyacı ([Wikipedia](https://en.wikipedia.org/wiki/Kingdom_Come:_Deliverance)). Bazı görevler gecikince düşer ([Cyberpost](https://cyberpost.co/which-quests-in-kcd-are-time-sensitive/)). KCD2'de kamp sabit yerdir, bedava yatak verir ([GamerGuides](https://gamerguides.com/kingdom-come-deliverance-ii/database/points-of-interest/camps)) | Gizli süre olmasın. Hazır kamp yeri iyi bir duraktır |
| Mount & Blade | Haritada tıklayıp gidilir, karşılaşmada eylem sahneye geçer ([Wikipedia](https://en.wikipedia.org/wiki/Mount_%26_Blade:_Warband)). Bannerlord yılı 84 gündür (oyuncu kaydı, [Steam](https://steamcommunity.com/app/261550/discussions/0/2144217924395139345)) | Atlas ve sahne ayrımı yerleşik bir dildir. Biz takvimi sıkıştırmıyoruz, 365 gün gerçek kalır |
| AC Valhalla | Görevler yerleşimde başlar ve biter, yapılar baskın malzemesiyle kurulur, seçim sonucu yerleşimde görülür ([Wikipedia](https://en.wikipedia.org/wiki/Assassin%27s_Creed_Valhalla)) | `own_seat` dönüş merkezi olur |

## 2. Görev yapısı

### 2.1 Ana zincir

Doğrusal zincir oyuncuya yön verir ama açık dünya hissini azaltır. Paralel kol hissi verir ama hikâye kopar. Witcher 3 ve Diablo IV ikisini birleştirir: tek hedefe giden birkaç açık kol [çıkarım]. «Tek son» denemez: Witcher 3'ün üç sonu vardır ([Wikipedia](https://en.wikipedia.org/wiki/The_Witcher_3:_Wild_Hunt)) [kaynak]. [çıkarım] Tanhu'nun perde başına üç kolu olur. Her kol ayrı bir yerde ya da ayrı bir kişide durur. Kollar bitince kapanış açılır.

Sayı XP bütçesinden çıkar (`progression.md` §1.2). I. Perde'de taban ana görev 112 XP'dir. II–VI için 12–14 görevle taban 177–206 XP olur: görev I. Perde'den ≈%70 büyüktür, süre ≈13 dakikadır [çıkarım].

### 2.2 Yan görev aileleri

Yan XP tabanı II–V'te ≈1.070, VI'da 860'tır. I. Perde'nin görev başına 69 taban XP'siyle bu perde başına 12–16 yan görev eder [çıkarım]. Aile kullanmak üretimi kolaylaştırır: aile bir sisteme bağlıdır, sistem de oyuncuya ödül dilini öğretir. Witcher 3'ün kontrat ve hazine ayrımı bunun örneğidir.

### 2.3 Görev verici ve iğne

Ghost of Tsushima'da haber kişiden gelir, yer sonra işaretlenir. Elden Ring'de hikâye seyrek anlatılır ([Wikipedia](https://en.wikipedia.org/wiki/Elden_Ring)); görev günlüğü sözü o sayfada yoktur, kaynak bulunamadı. KCD'de bazı görevler gecikince düşer. [çıkarım] Tanhu'da `travel.md` §9.3 ve `progression.md` §10.1 zaten `rumoured` durumu taşıyor: iğne bilgiyle gelir, harita baştan ikonla dolmaz.

### 2.4 Keşif ödülü

Formül: `(Keşif XP − atlas_node × yeni zon) / (10 × xpScale)`. Sonuç II 11,7; III 14,9; IV 11,7; V 11,9; VI 8–12. Perde başına ≈12 XP'li durak, yeni iç harita başına 4–8 eder: `progression.md` §10.1'in «3–8» sayısı II, IV, V'te doğru kalır [çıkarım]. III'te tutmaz: tek yeni harita (`donghu_land`) 14,9 durak almaz. III ≤8 durakla kapanır (208 XP); kalan ≈180 XP av ve tarife kalır, `progression.md` §1.2 II+ Keşif sütununa bunları da sayar. VI tek haritada kalırsa aynı sınır işler. Geri kalan duraklar XP vermez. Ödülleri bilgi, mal, ad, Destan dizesidir.

### 2.5 Zaman baskısı olmadan aciliyet

| Araç | Örnek | Tanhu'daki yeri [çıkarım] |
|---|---|---|
| Görünür ve cezalı sayaç | Majora: ekranda saat, 72 saatlik döngü. Eleştirmenlerin çoğu övdü, GameSpot yazarları bunaldı ([Wikipedia](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Majora%27s_Mask)). «Ayrıştırıcı» sözünün kaynağı [Yahoo](https://sg.news.yahoo.com/legend-zelda-majoras-mask-inside-130032809.html) sınamada açılmadı | Yok, #19 |
| Gizli süre | Kingmaker: oyun ani bitebilir, hangi görevin süreli olduğu belli değildir; forum bölünmüştür ([Paizo](https://paizo.com/threads/rzs435mh)). KCD: görev düşer | Yok |
| Yetişememe | Pathologic 2: sonraki günlerde her şeye yetişilmez, bazı olaylar kapanır ([Wikipedia](https://en.wikipedia.org/wiki/Pathologic_2)) | Yalnız Son Gece'de, I. Perde'de |
| Adımla değişen dünya | RDR2'de bölümle kamp değişir | Ana görev adımı yerleşimi ve haritayı değiştirir |
| Sözle baskı | | Son görev açık kaldıkça kişiler sabırsızlanır, bedel yok (öneri 16) |
| Taşınan şey | `settlement.md` §2.1 Köz Kabı 48 saat | Sönerse görev düşmez, satır değişir |
| Mevsim | K24 kış dengesi | Oyalanan güze ve kışa girer, otlak ve ordugâh değişir. Yavaş araçtır: ilk eşik II, IV, VI'da 83., III'te 76., V'te 116. gün, bütçenin 5–10 katı (`time.md` §2) |

### 2.6 Perde kapanışı

Diablo IV'te perde boss ile biter. RDR2'de çoğu bölüm yeni kampa geçişle kapanır [çıkarım]. Witcher 3'te en az bir eşikte uyarı vardır (oyuncu sözü), kaynaklarda düşen görevlerin listesinden söz edilmez. [çıkarım] En iyi kapı listeli olandır: oyuncu neyi bıraktığını görür, kalıp bitirir ya da gider.

## 3. Seviye tasarımı

### 3.1 Bu kamerada çapa

Disneyland kuramında çapa (Clarke-Willson'ın yazımıyla «wienie») uzaktan görünen, ziyaretçiyi çeken yapıdır ([Clarke-Willson](https://www.above-the-garage.com/wienies/)) [kaynak]. Mario Odyssey çözümlemesinde çapalar sıralıdır: biri bitince öteki sahnelenir, ödül yol boyunca büyür ([Game Developer](https://gamedeveloper.com/design/what-mario-learned-from-mickey-mouse---part-3-decision-making-and-weenies)) [kaynak]. Bunun açık hissi koruduğu bizim yorumumuzdur [çıkarım]. Scott Rogers'ın bunu GTA gibi açık dünyalar için önerdiği yazılır ([BoingBoing](https://boingboing.net/2009/03/27/gamedesign-lessons-f.html/amp)); sayfa sınamada açılmadı, doğrulanamadı.

Ama bu kuram ufku gören kamera ister. Tanhu'da 28°'de üst ışın ufkun 9° altındadır. Bir noktanın derinlik açısı `atan((h − y) / D)` olduğundan cismin tabanı kadraja önce girer, yüksek kısmı kadrajın üstünde kalır. **Boy, görüş menzilini artırmaz** [çıkarım]. «Uzun sivri şey» yalnız üst ışın ufku geçtiğinde çalışır: Bakış 16°, yokuş sürüşü 17°, Tengri 14°. `act1.md` §4'ün «yön dili zeminde» kararı bu yüzden doğrudur.

| Menzil | Araç | Sayı [çıkarım] |
|---|---|---|
| Yakın, ≤79 m | Patika, kazık, taş yığını, iz, zemin rengi | Zincir düzde ≤65 m, yokuşta ≤35 m (`act1.md` §4) |
| Orta, ≤350 m | Aşağı eğim, sürüş kadrajı, ses | −3° 117 m, −5° 175 m, −7° 350 m; sürüş ≈204 m; direk 120 m, Boğaz 350 m |
| Uzak | Bakış, sırt, atlas, `J` | 16°, 44 m; gök ve uzak yapı burada görünür |

Gölge sınırlı bir yardımdır. K20'de gölge yüksekliği ≥15° olduğundan gölge boyu en çok 3,7 × H'dir, kuzeye düşer, yaz öğlesinde kısalır. Kuzeye giden oyuncuya yön vermez.

### 3.2 Üçgen kuralı ve çekim

Nintendo'nun CEDEC 2017 anlatımına göre üçgen iki iş görür: aşmak ya da dolaşmak seçimi verir, arkasını gizleyip merak uyandırır. Üç ölçek vardır: büyük yer işareti, orta gizleme, küçük tempo. İlk önlem kule aralarına olay koymaktı: rotalar yayıldı ama oyuncular kendini yönlendirilmiş hissetti; çözüm farklı görünürlük ve önemde yapılarla oyuncuyu farklı yönlere çeken «çekim» oldu ([CEDEC özeti](https://gist.github.com/idbrii/e39fe96279aa1670319bfa521d907399), [Gigazine](https://gigazine.net/gsc_news/en/20171004-breath-of-the-wild-design-secret)) [kaynak]. İki kaynak da konuşmanın metni değil, Japon basın yazılarının özetidir; konuşmacı adı yoktur. Sayı verilmez.

[çıkarım] Eğik kamerada örtme uzunluğu `H / tan θ`'dır. Kadraj tepesinde θ küçük olduğu için alçak sırt çok şey gizler, cisim ekranda aşağı indikçe perde açılır.

| Üçgen | Yükseklik | Kadraj tepesinde gizler (9°) | Kadraj ortasında (28°) | İş |
|---|---|---|---|---|
| Küçük | 1,5–3 m | 9–19 m | 3–6 m | Tempo, at sıçrayışı, saklanma |
| Orta | 8–12 m | 51–76 m | 15–23 m | Bir durağı saklar; dörtnalda ≈8,5 sn, yürüyüşte ≈17 sn'de açılır |
| Büyük | 20–30 m | 126–189 m | 38–56 m | Bakış; ardı ayrı bir alandır |

Sağlama: 8,5 m'lik yurt 28°'de 16 m gizler, `act1.md` §4 ile aynıdır.

### 3.3 Durak yoğunluğu ve aralık

«40 saniye kuralı» CD Projekt'e atfedilir. DTF, «Бартош Вон Охман» adıyla bir söz aktarır: testlerden sonra oyuncunun her 40 saniyede bir dikkatinin dağıtılması gerektiğini anlamışlar. Yazı kişinin görevini, sözün yerini, tarihini ve bağlantısını vermez: özgün söz için kaynak bulunamadı ([DTF](https://dtf.ru/games/70450-chto-takoe-pravilo-40-sekund-v-igrah-s-otkrytym-mirom-i-pochemu-ego-stoit-soblyudat)). Bir tez Witcher 3 için 20–39 sn bulur ve oyun tarzının en güçlü etken olduğunu yazar ([DiVA](https://www.diva-portal.org/smash/get/diva2:1569059/FULLTEXT01.pdf), arama özetinden; sunucu sınamada da bağlantıyı reddetti, doğrulanamadı). İki saatlik tek kişilik ölçümler [kaynak, DTF]; Witcher 3, BotW ve RDR2'yi Luke Stevens, Skyrim ve RDR'yi DTF yazarı ölçmüştür:

| Oyun | Ortalama aralık | Dörtnalda karşılığı [çıkarım] | Yürüyüşte [çıkarım] |
|---|---|---|---|
| Witcher 3 | 32,2 sn | 276 m | 142 m |
| Skyrim | 35,7 sn | 306 m | 157 m |
| Breath of the Wild | 41,8 sn | 359 m | 184 m |
| Red Dead Redemption | 53,1 sn | 456 m | 234 m |
| RDR2 | 87 sn | 746 m | 383 m |

DTF'te 12 ölçüm vardır, burada 5'i seçildi. Aralık 20,2–87 sn, 7'si 40 sn'nin üstündedir; RDR2 ölçümü ana görevleri atlar. Kural ölçüm sonucu değil, tasarımcı hedefidir [çıkarım].

[çıkarım] Altıgen düzende `N = A / (0,866 s²)`, A = 1,47 km²: s 176 m → 55, s 343 m → 14, s 480 m → 7. Yalnız 3–8 keşif durağı dörtnalda RDR2 ritmi verir, yürüyüşte iki dakikaya yakın boşluk bırakır. Çözüm katmandır: 14–18 adlı yer dörtnal ritmini (≈307–348 m) tutar. Yürüyüş ayrı hesaptır: zemin işareti yöndür, dikkat sayılmaz. Adlı yer ve küçük durak 20–28 nokta eder: ≈246–291 m, yürüyüşte ≈56–66 sn. Yürüyüşte ≈40 sn (≈55 dikkat) için kalan ≈27–35'i hareketli olaydır: sürü, yolcu, çevre arabası (`survival.md` §4, `travel.md` §10); DTF'in aktardığı örnek de bir geyik sürüsüdür. Kışlak daha yoğundur (14 bölge, 24 alt ad, 13 XP'li durak) çünkü ≈5 saatlik içeriği tek haritada taşır; sonraki haritalar perdede 140–210 dakika alır.

### 3.4 Bozkırda yön ve ritim

Düz arazi bu kamerada en kör arazidir: 79 m. Eğim görüşü açar ve kapatır (`act1.md` §4 tablosu). [çıkarım] Dalgalı bozkır bir soluk düzenidir: yokuşta görüş 50–59 m'ye iner, sırttan sonra 117–175 m'ye çıkar. ±3–5° eğim 150–250 m boyunda 8–22 m yükselme demektir. Bu, orta üçgenin arazi biçimidir. Çelişki: `settlement.md` §3.3 bütün `whistle_field`'i «düz Gobi ovası» yazar. Dalga orada ancak talim ovası ve ordugâh parselleri dışında olur, belge değişir. `tanhu_ordu`'da Ocak Yeri pedleri (r 60 m ≤3°) düz kalır (§3.2).

Dünya içi yönlendirme Ghost of Tsushima'nın önerisidir. Tanhu'da rüzgâr fiziksel bir `fx`'tir ve Kara Boran'da yön dilidir (`act1.md` §10). Kullanıcının kartal isteği (ek istek 1) burada bir iş bulur: kamera göğü görmediği için kartal yalnız gölgesiyle okunur. Serbest döndürmede yön kaybı gerçek bir risktir: John Nesky «oyuncunun kendini kaybetmesine izin vermek»i kamera hatası sayar ([liste](https://t.me/s/disdoc/798), madde 30).

### 3.5 Yol ve yan yol

Kışlak'ın düzeni iyi bir örnektir: ana yol 4 m, ikinci yollar 2–3 m, keçi yolu 1,5 m (`act1.md` §4). [çıkarım] Kadraj genişliği yoldan görülecek şeyi belirler: 28°'de kahramanın 40 m önünde ±38,7 m, 60 m önünde ±49,5 m. Yoldan ayrılmayı başlatan ilk işaret bu yüzden yola ≤40 m olmalıdır. Sürüşte 40 m önde ±37,7 m ile aynı sayı tutar.

### 3.6 Kısıtlı bölge, kişi ve bilgi kilidi

- BotW'nin Büyük Plato'su yamaç paraşütü olmadan çıkılmayan, oyunun küçük bir örneği olan alandır ([Wikipedia](https://en.wikipedia.org/wiki/Great_Plateau)) [kaynak].
- RDR2'de Blackwater ve New Austin'e girilebilir, ama ödenmeyen «ölü ya da diri» durumu ödül avcıları getirir ([PowerPyx](https://www.powerpyx.com/red-dead-redemption-2-how-to-remove-bounty-in-blackwater-new-austin/)) [kaynak]. Sınır duvar değil, sonuçtur.
- Outer Wilds yetenek yerine bilgi toplatır ([GamesRadar](https://www.gamesradar.com/the-making-of-outer-wilds), arama özetinden). Bağımsız sağlama: döngüde yalnız bilgi taşınır ([Wikipedia](https://en.wikipedia.org/wiki/Outer_Wilds)) [kaynak].
- Clarke-Willson'da Space Mountain meydandan görünür ama oraya doğrudan yol çekici yapılmaz. Sıradan arka kapı «anti-wienie»dir, bilerek sönük tutulur ([Clarke-Willson](https://www.above-the-garage.com/wienies/)) [kaynak]. Yazı «çekmek» ve «itmek» sözlerini kullanmaz.

[çıkarım] Kızıl Kazık ve Kefil bu ailedendir ve RDR2'den daha yumuşaktır: ölüm yok, bedel Güven. Sonraki perdelerde aynı dil sürer: yolu bir kişi açar ya da söylenti açar, seviye açmaz.

## 4. Harita ve sahne geçişi

| Örnek | Davranış [kaynak] |
|---|---|
| Supreme Commander | Yakın plandan tüm haritaya yakınlaşma (iki kaynak da «kesintisiz» demez); uzakta birimler simgeye döner, motor bunun için kuruludur ([Matchstick Eyes](https://www.matchstickeyes.com/tag/rts-zoom/), [Armchair General](https://armchairgeneral.com/review-supreme-commander.htm/2)) |
| Flight Simulator | Kürede sürükle ve tekerlek; havalimanında «ayrıntıya yakınlaş» ile başlangıç noktası seçilir, uçuş seçimden sonra başlar ([SimViation](https://forums.simviation.com/phpBB3/viewtopic.php?p=1318821)) |
| Google Earth | Bina ve görüntü ihtiyaca göre gelir ([Webiano](https://webiano.digital/google-earth-still-lets-you-fly-the-planet-like-a-secret-cockpit/), yapay zekâ destekli ajans yazısı, zayıf) |
| Mount & Blade | Haritada tıkla, karşılaşmada sahneye geç ([Wikipedia](https://en.wikipedia.org/wiki/Mount_%26_Blade:_Warband)) |
| Anno 1800 | Dünya haritası görünümünden seçilen olayla bölgeye sefer başlar ([GamePressure](https://gamepressure.com/anno-1800/whats-new-in-anno-1800/z3b4f7), arama özetinden) |

[çıkarım] Kesintisiz geçiş yalnız aynı veri bellekteyken olur. Tanhu'da bu yalnız yüklü iç haritadır; öteki iç haritanın kurulumu 4,5–7 sn sürer (`travel.md` §9.4). Flight Simulator'ın «yakınlaş, seç, başlat» düzeni başka yerler için doğru örnektir: yakınlaşma karar verdirir, ışınlamaz. Bu yön `travel.md` §0'ın «Işınlanma yok» kuralıyla uyuşur.

## 5. Takvim ve kronik

| Oyun | Zaman [kaynak] |
|---|---|
| Crusader Kings | Sürekli saat, durdur ve hızlandır ([Wikipedia](https://en.wikipedia.org/wiki/Crusader_Kings_(video_game))) |
| Fire Emblem Three Houses | Savaşlar arasında sabit gün, eylem zaman puanı ister; yarıda beş yıl atlanır, dünya savaşa döner ([Wikipedia](https://en.wikipedia.org/wiki/Fire_Emblem:_Three_Houses)). Atlamanın ağırlığı kişilerde ve bilinen yerde hissedilir ([GamesRadar](https://www.gamesradar.com/why-fire-emblem-three-houses-five-year-gap-is-its-smartest-storytelling-decision), arama özetinden) |
| AC Valhalla | Açılışta on yedi yıl atlama ([Wikipedia](https://en.wikipedia.org/wiki/Assassin%27s_Creed_Valhalla)) |
| RDR2 | Epilog 1907'dedir, ana hikâyeden sekiz yıl sonra ([Wikipedia](https://en.wikipedia.org/wiki/Red_Dead_Redemption_2)) |
| Pathologic 2, Majora, Kingmaker | §2.5 |

[çıkarım] İki sonuç çıkar. Birincisi, örnekler «sayaç kötüdür» demez: Majora övgü aldı, Kingmaker forumu bölünmüştür; tepkiyi daha çok belirsiz süre çeker. Sayacı kaldıran kullanıcının kararıdır (#19), bu örnekler değil. İkincisi, atlamayı inandıran şey metin değil, oyuncunun bildiği yerin ve kişinin değişmiş hâlidir. Bu yüzden Akan Kronik tek başına yetmez, III–VI'da perdenin ilk görevi bir «dönüş» görevi olmalıdır.

MÖ 210'dan 174'e 60 dakikalık günle ≈13.000 gerçek saat gerekir (site, KB9). Takvim gerçek kalır, K20 ve K25 bozulmaz; atlama gözle görülür hâle gelir.

## 6. Kamera

### 6.1 Örnekler

| Oyun | Davranış [kaynak] |
|---|---|
| Diablo IV | Yakınlaştırma oyuncuya bırakılmaz; büyük şehir ve güvenli yerde kendiliğinden yaklaşabilir, Kor Valar'a ilk girişte uzaklaşır ([GamePressure](https://www.gamepressure.com/diablo-iv/can-you-zoom-out-the-camera/zd10c90)). Dünya boss'unda uzaklaşma: kaynak bulunamadı. Ekip başka kameraları denemiş, izometrikte kalmıştır ([The Geek](https://thegeek.games/?p=45196), VG247 aktarımı, 2019). Eğim sayısı: kaynak bulunamadı |
| Path of Exile 2 | Dönüş yok, uzaklık sınırlı; kaynaklar zayıf ve kısmen çelişkili ([Mejoress](https://www.mejoress.com/en/path-of-exile-2-how-to-rotate-the-camera/), [PoE forumu](https://www.pathofexile.com/forum/view-thread/3544195)) |
| Baldur's Gate 3 | Orta tuş döndürür, Page Up ve Down ya da tekerlek yakınlaştırır, Home ortalar, O taktik görünüm ([PCGamesN](https://www.pcgamesn.com/baldurs-gate-3/camera-controls)). Klavye dönüşü kaynakta değişir: Delete ve End ([Fextralife](https://baldursgate3.wiki.fextralife.com/Controls)), Q ve E, ikincil Delete ve End ([bg3.wiki](https://bg3.wiki/wiki/Controls)); tuşlar değişir |
| Dragon Age Origins | Home ve End eğim, Page Up geri çekme, tuşlar değişir ([Magic Game World](https://www.magicgameworld.com/?p=127065)); kuş bakışı ayrı önem taşır ([GameStar](https://www.gamestar.de/artikel/dragon-age-2-keine-taktik-ansicht-aus-der-vogelperspektive,2316849.html)) |
| Divinity Original Sin 2 | Kaynaklar çelişkili, doğrulanamadı |

Nesky'nin GDC 2014 konuşmasının 50 hata listesinden konuya değenler ([Telegram'daki liste, ileti 798](https://t.me/s/disdoc/798), [GDC Vault](https://gdcvault.com/play/1020460/50-Camera)) [kaynak, liste ikincil], kendi numaralarıyla: 16 eğim, uzaklık ve görüş açısını birbirinden bağımsız değiştirmek; 22 kamerayı hep oyuncuya bırakmak; 23 koşarken yatay açıyı hiç oynatmamak; 34 denetim verip geri almak; 35 oyuncu çevirir çevirmez ipucu uygulamak; 37 ters eksen vermemek; 38 kazara girdiye tepki; 40 pivotun fazla kayması; 47 sınıra dek aynı hızla eğmek.

[çıkarım] Diablo ve PoE sabit kamerayla adil kadraj kurar, BG3 ve Dragon Age serbest kamerayı tuşlarla ve sıfırlamayla dengeler. Kullanıcı ikisini ister: varsayılan Diablo, istek üzerine serbest. Doğru kalıp «üstüne yazılan pay»dır: ön ayar değişmez, oyuncu payı üstüne eklenir, tek tuşla silinir.

### 6.2 Kadraj hesabı

Kahraman ekranda hep aynı yerde kalsın diye (NDC −0,35) ileri pay eğimle değişir [çıkarım]: `fwd = d·cos p − (d·sin p + 0,6) / tan(p + 6,9°)`. `F` ileri, `B` geri görüş, `G` kahraman hizasında yarı genişlik.

| Eğim, uzaklık | fwd | F | B | G | Üst ışın | Not |
|---|---|---|---|---|---|---|
| 28°, 33 m | 6,1 | 79 | 8,0 | ±17 | −9° | Varsayılan Mete |
| 28°, 26 m | 6,1 | 64 | 4,9 | ±13 | −9° | Çocuk |
| 28°, 13 m | 2,4 | 33 | 2,8 | ±7 | −9° | En yakın |
| 28°, 44 m | 6,1 | 102 | 12,9 | ±24 | −9° | En uzak |
| 22°, 33 m | 7,1 | 224 | 8,6 | ±16 | −3° | Eğim alt sınırı |
| 24°, 44 m | 9,3 | 180 | 11,1 | ±22 | −5° | 44 m'nin alt sınırı |
| 35°, 33 m | 5,3 | 46 | 7,5 | ±18 | −16° | |
| 45°, 33 m | 4,6 | 30 | 7,1 | ±19 | −26° | Oda eğimine yakın |
| 60°, 33 m | 4,0 | 21 | 6,8 | ±19 | −41° | Üst sınır |
| 22°, 30 m | 6,1 | 204 | 8,1 | ±15 | −3° | Sürüş; dörtnalda `lead` 2,6 ile B 5,5 |
| 22°, 30 m, fwd 2 | 2 | 200 | 12,2 | ±17 | −3° | `act1.md`'nin sürüş sayıları; dörtnalda B 9,6 |
| 28°, 38 m, fwd 6,1 | 6,1 | 89 | 10,3 | ±20 | −9° | Çömelme bugünkü kod |
| 28°, 38 m, fwd 0 | 0 | 83 | 16,4 | ±23 | −9° | Çömelme `act1.md` |

Üç sonuç [çıkarım]. Birincisi, geri görüş eğimle düzelmez, 7–9 m'de kalır: arka güvenliği kadrajla değil okla sağlanır. İkincisi, güneye yürüyen oyuncu 8 m görür; I. Perde'de ev kuzeyde olduğu için bu sorun gizlidir, II–VI'da oyuncu her yöne gider. Üçüncüsü, alt sınır bütçeye bağlıdır: üst ışın ufka gelirse gök ve uzak arazi çizilir (`world.sky`, `showBelowPitch` 18). Sürüş kadrajı (≈204 m) ölçülü bütçedir, ona yakın kalınır.

### 6.3 Kadraj dışı tehdit

Xbox rehberi kritik görsel ipucunun ses gibi ikinci bir kanalla, sesin görselle desteklenmesini, rengin tek başına kullanılmamasını ister; yönlü hasar halkası ve konumlu ses örnek gösterilir ([XAG 103](https://learn.microsoft.com/en-gb/gaming/accessibility/xbox-accessibility-guidelines/103)) [kaynak]. PlayMaker belgesi bir kenar oku bileşeni tarif eder: hedef görüşten çıkınca en yakın kenara yapışır, hedefe döner ([Hutong](https://docs.hutonggames.com/guides/ui-widgets/target-managers/offscreen-indicator/); sayfa sınamada açılmadı). Bunun yaygın biçim olduğu bizim yorumumuzdur [çıkarım].

`act1.md` §10'daki «önce yana çıkar» kuralı kuzey kamerasına göre yazıldı. Sürüş kadrajında kahraman hizasında ±15 m, 5 m önde ±17,9 m, 15 m önde ±23,6 m görünür [çıkarım]. `TRAIL`in 30–60 m'si varsayılan yönde kadrajın hep dışındadır: ok sözleşmenin asıl parçasıdır.

### 6.4 Ses yönü

`audio.md` dinleyiciyi kameraya bağlar, HRTF kapalıdır. MDN'ye göre `equalpower` basit ve verimli, `HRTF` daha kaliteli ve ölçülmüş tepkilerle çalışır ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/panningModel)) [kaynak]. Üçüncü şahıs oyunlarda kamera dinleyicisinin uzaklığı karakterden değil kameradan ölçmesi bilinen bir sorundur ([Audiokinetic Q&A](https://www.audiokinetic.com/qa/6112/unity-distance-relative-the-player-panning-relative-camera)) [kaynak, topluluk; sayfa sınamada açılmadı].

[çıkarım] 33 m kamerada kahramanın 30 m arkasındaki takipçi kameranın neredeyse altındadır: dinleyiciye ≈18 m, kahraman ≈28 m uzaktadır. Takipçi kahramandan yakın duyulur, yönü belirsizdir. Eşit güç kaydırma önü ve arkayı da ayıramaz. Kovalamacada «toynak sesinin 3B yönü» bugünkü ayarla söz verdiğini tutmaz.

## 7. Hayatta kalma örnekleri

| Oyun | Kural [kaynak] |
|---|---|
| RDR2 kampı | Etkinlik yerlerinden uzakta hemen her yerde kurulur, uygunsuz yer nedenini yazar. Uyu (sabah, öğle, akşam), pişir, ayrıl; uyanınca dinlen, pişir ya da topla; kamp bırakılıp günlerce avlanılabilir. Malzeme yazmaz ([Shacknews](https://shacknews.com/article/108136/how-to-craft-a-camp-and-campfire-in-red-dead-redemption-2)) |
| Valheim | Ateşe odun eklenir ([GLS](https://www.gameslearningsociety.org/wiki/what-items-count-for-fire-in-valheim/)), kamp ateşi 10 odun alır ([Steam](https://steamcommunity.com/app/892970/discussions/0/3186860850587227859)). Uyku beş koşul ister: vakit, düşman yok, çatı, yakın ateş, kuru olmak ([Gamever](https://gamever.io/knowledge-base/sleeping-in-valheim-the-five-conditions-and-what-the-night-actually-skips)) |
| KCD2 | Kamp sabit duraktır; oyuncunun kurduğu kamp modla gelir ([GamerGuides](https://gamerguides.com/kingdom-come-deliverance-ii/database/points-of-interest/camps), [PC Gamer başlığı](https://www.pcgamer.com/games/rpg/finally-this-kingdom-come-deliverance-2-camping-mod-means-ill-never-have-to-scour-bohemia-for-a-place-to-sleep-again)) |
| Kingmaker, Baldur's Gate | Kamuflaj başarısızsa dinlenirken saldırı olasılığı artar ([GamerGuides](https://www.gamerguides.com/pathfinder-kingmaker/guide/walkthrough/chapter-1-getting-started-in-the-outskirts/first-night-in-the-stolen-lands)). Baldur's Gate 1'de açıkta dinlenme baskın doğurur ([Lilura](https://lilura1.blogspot.com/2019/10/Baldurs-Gate-Retrospective-Review-On-Rest-Ambushes-and-Overworld-Waylays.html)); her dinlenmeye kavga bıktırır ([Obsidian forumu](https://forums.obsidian.net/topic/89905-you-have-been-waylaid-by-enemies-and-must-defend-yourself/page/2); sayfa sınamada açılmadı, doğrulanamadı) |
| At üstü | Ghost of Tsushima: Jin atta yol boyunca kaynağı inmeden alır ([Fextralife](https://ghostoftsushima.wiki.fextralife.com/Mount)). RDR2: yalnız Red Dead Online'da olduğu, tek oyunculuya modla taşındığı görünüyor ([Nexus](https://www.nexusmods.com/reddeadredemption2/mods/4674), arama özetinden); RDR2 örneği zayıftır |
| Gizlilik | Desperados III: koninin düz kısmı her şeyi görür, taralı kısmı çömeleni görmez ([SuperCheats](https://www.supercheats.com/desperados-3-walkthrough-guide/enemy-field-of-view), arama özetinden). Mark of the Ninja: ses yayılan halkayla gösterilir, kural görünürse oyun tepki değil plan olur ([Game Developer](https://gamedeveloper.com/design/reinventing-stealth-in-2d-with-i-mark-of-the-ninja-i-)) |

## Oyuna öneriler

### Kamera

1. **Varsayılan kadraj (#12, KB7).** Mete 28°, 33 m; Çocuk 28°, 26 m; `ride`, `passenger`, `lookout`, `tengri`, oda değişmez. Oturum kuzeye bakarak açılır, menü karesi değişmez (K27 aynen). [çıkarım]
2. **Eğim bandı (#12, KB7). K27'yi genişletir:** «eğim ön ayardan gelir» cümlesi «ön ayar + oyuncu payı» olur. `pitch = clamp(ön ayar + userPitch, pMin, 60°)`; `pMin = vFOV/2 + 3° + max(0, (d − 33) × 0,18)`. Görüş `normal` 22° (44 m'de 24°), `wide` 25° (27°), `narrow` 20° (22°). Ön ayarın kendisi `pMin` altındaysa (Bakış 16°, `rideUp` 17°, `flow` 17°) ön ayar kazanır, oyuncu payı yalnız yukarı ekler. Oda ve sinema payı bekletir. Son 4° hız ×0,3 (Nesky 47). 60° üstünü çarpışma yükseltmesi kullanır (64°). Üst ışın 3° kuralı gök çizimini ve bütçeyi korur. [çıkarım]
3. **Yakınlaştırma (#12).** 13–44 m ve 1,6 m adım kalır (`ZOOM`). Uzaklık eğimden bağımsız değiştirilebilir; bağ yalnız `pMin`'dedir. Eğim-uzaklık eğrisi (Nesky 16) önerilmez: 28° bütün hesapların tabanıdır. [çıkarım]
4. **Yön Payı (#12).** Güneye yürüyen oyuncunun 8 m görmesi için döndürme değil, pay kullanılır: yaya hareket yönüyle bakış arasındaki θ'ya göre `fwd` kayar: θ ≤90°'de `fwd × cos θ`, θ >90°'de `8 × d/33 × cos θ`. 1,5 sn kesintisiz hareketten sonra 1,2 sn'de karışır, durunca 3 sn'de döner. Sonuç 180°'de F 64,5 m, B 22,1 m. Atta (`yawFollow` var), çömelikte, odada ve kamp dünyasında kapalı. Ayar `game.camLead` açık. Yaya için kendiliğinden döndürme yoktur: Diablo hissi korunur. [çıkarım]
5. **Girdi (#12, #18).** K27'nin girdileri aynen kalır, şunlar eklenir. [kurgu]

   | Girdi | İş |
   |---|---|
   | Orta tuş, dikey sürükleme | Eğim, 0,15°/piksel; yatay ve dikey eksen önce baskın olana kilitlenir, 12 px'te açılır (Nesky 38) |
   | Alt + tekerlek | Eğim, adım 2° |
   | `;` ve `'` basılı | Eğim, 40°/sn; tuş adı dizilişten okunur (Türkçe Q'da Ş, İ) |
   | `-` ve `=` | Uzaklık, K27'de klavyeyle yakınlaştırma yoktu |
   | `/` kısa | Kuzey (K27 aynen) |
   | `/` basılı 0,6 sn | Tam sıfırlama: açı kuzey, eğim payı 0, uzaklık ön ayar, 0,5 sn (`G` deseni) |
   | Orta tık | Kuzey (K27); iki orta tık 350 ms içinde tam sıfırlama |
   | Dokunmatik ekran | Yatay iki parmak döndürür, kıstırma uzaklık, dikey iki parmak eğim. Dokunmatik yüzeyde dikey kaydırma K27 gereği uzaklık kalır, eğim `Alt` ile |

6. **Ayarlar (#18).** Yeni anahtarlar: `game.camTurnSpeed` 60–200°/sn, 110; `game.camDragSens` 0,10–0,50°/piksel, 0,25; `game.camInvertX`, `game.camInvertY` kapalı (Nesky 37); `game.camTilt` açık, kapalıyken eğim sabit kalır; `game.camPitchBias` −6..+20°, 0; `game.camRideFollow` `off`, `soft` (±45°), `full` (±75°), `full`; `game.camLead` açık; `game.wheelMap` açık. Mevcut `game.camFollow`, `game.fov` kalır. `architecture.md` §8 karar 19 kalkar: okuyucusu artık vardır. Kalıcı atama: `input.bindings` (`contract-requests.md` 0.1 satırı) `setBinding`'i kaydeder, çakışmada eski eylem boş kalmaz, «Şuna da bağlı: {eylem}» sorar; atama ekranı 12.2'yi beklerse anahtar önce gelir. Yatay açı K27 gereği kaydedilmez; eğim tercihi `camPitchBias` ile kalıcıdır. [çıkarım]
7. **Kadraj sözleşmesi 2 (#12, #17). `act1.md` §10 yerine.** «Sana zarar verebilen her şey kadrajdadır ya da ekran kenarında oku yanar. Kadraj dışından ilk vuruş yoktur.» Kurallar: (a) Tehdit saldırı durumundaki ya da 40 m içinde oyuncuya yönelmiş varlıktır; görünürlük 0,1 sn'de bir frustumla sınanır, %5 pay. (b) Kadraj dışı tehdide kenar oku: ekran kenarının %92'si elipsinde, en çok 3 ok, fazlası en yakın okta sayı. (c) Biçim durumu söyler, renk yalnız ektir (XAG 103): boş üçgen izliyor, dolu üçgen yanaşıyor, dolu ve atan halka ateş edecek, kanca kement. Boy uzaklığı verir. (d) `SHOOT` ancak tehdit kadrajdaysa ya da oku ≥1,2 sn yanıyorsa başlar; zemin çizimi 1,2 sn kalır, çizim kadraj dışındaysa o kenar kızıl çizgi yanar. (e) Sinemada kapalı, her zorlukta açık: adillik kuralıdır, elmas işaretten ayrıdır. [çıkarım]
8. **Kovalamaca kamerası (#17).** Döndürme ve eğim açık kalır: `ride` ön ayarı yaw yazmaz, K27'nin bekleyişi işlemez. `FLANK` hedefi dünya yönünden değil kameradan seçilir: kamera önüne ≥5 m, yana ±10–14 m (±17,9 m kadrajın içi); hedef 1,5 sn'de bir yenilenir, kamerayı çevirerek takipçi oyalanamaz. Elle döndürmeden sonra at izlemesi 2 sn bekler, sonra 1,1 sn gecikmeyle sürer (Nesky 34, 35). İsteğe bağlı **Ardına Bak** `H` basılı: 0,35 sn'de 150° döner, bırakınca döner; `Ardına Atış`ın (`progression.md` §4.8) görsel yüzüdür. Kör rüzgârda (T4) oklar kalır: «pusula yok» yön içindir, tehdit için değil. [kurgu]
9. **Ses yönü (#17). `audio.md` §3B satırını değiştirir.** `play` ve `freeroam`'da dinleyici konumu kahraman + 1,5 m, yönü kameranın yatay açısı; uzaklık kahramandan ölçülür. Ön ve arka önce ucuz süzgeçle ayrılır (`ses-tasarimi.md` §6.4, öneri 16); en yakın 3 tehdide `HRTF` ancak ölçüm yeterse gelir, pahalıysa 3 yerine 1, gerisi `equalpower`. Menü ve sinema eskisi gibi kamerada. [çıkarım]
10. **Düzeltme (#12, #22).** `CAM.crouch`'a `fwd: 0` eklenir: `act1.md` §4'ün 16,4 m'si ve «nöbetçi görüşü 16 m kadrajda» sözü ancak böyle tutar; bugünkü kodda 10,3 m'dir. `act1.md` §10'un «arkayı yalnız 12 m» cümlesi bugünkü kodda 8,1 m (dörtnalda 5,5 m) eder, çünkü `CAM.ride` `fwd` yazmaz, 6,1 miras alır. İki yol vardır: cümle düzelir ya da `CAM.ride`'a `fwd: 2` yazılır (`CAM.squad` gibi). İkincisi önerilir: `act1.md` §4'ün ≈200 m'sini ve §10'un 12 m'sini birlikte tutar (F 200, B 12,2, dörtnalda 9,6). §6.3 ve öneri 8'in genişlikleri `fwd 6,1` iledir; `fwd 2`'de kadraj genişler, öneri 8 yine içinde kalır. [çıkarım]

### Harita

11. **Haritadan oyuna (#10, KB4). `harita.md` önerisi kesinleşir.**
    - Yüklü iç haritada `span` 0,085 birime varınca harita kapanır, kamera 1,6 sn'de oyun kamerasına karışır (`camera-blend`, 46° → ön ayar), saat akar, oyuncu yer değiştirmez; görüş uzaktaysa kamera oyuncuya döner.
    - Tekerlek kilidi: geçişten sonra 0,35 sn ve tekerlek 150 ms susana dek girdi yutulur. Yoksa dokunmatik yüzeyin ataleti oyun kamerasını da yakınlaştırır.
    - Başka yerde yakınlaşma 6 birimde durur. Tık: yol biliniyorsa Yol Kartı o satırı seçili açılır, bedel ve `travel.md` §8 kilitleri aynen; bilinmiyorsa «Bu yol henüz açılmadı.» Işınlanma yok.
    - Ters yön: oyunda 44 m'deyken 0,6 sn içinde 3 çentik daha uzaklaşırsa harita açılır, ekranda 3 küçük çizgi dolar. `combat`, `pursuit`, sinema ve Plan Kipi'nde kapalı. `game.wheelMap` ile kapanır. M kısayol kalır. [kurgu]

### Görev yapısı

12. **I. Perde'nin açık hissi (KB8). Sayılar değişmez, veri eklenir.** (a) `J`'de «Bugün» listesi: serbest saatlerde en az 3 açık iş, uzaklığa göre. (b) Kişi yazan kilit: harita bölgede güven eşiğinden önce kefilin adını yazar. (c) Görünür kapalı yer: 5 Bakış'ın her biri en az 2 kapalı bölge gösterir. (d) **Kaçak Ödül:** her kilitli bölgede Kazık hattının ≤80 m (yürüyerek, 40 sn sayacın dönüşü) ya da ≤125 m (çömelik, 120 sn) içinde 1 küçük durak: çakıl, bilgi, küçük mal; XP yok. (e) `latest`'ten 30 oyun dakikası önce ikinci çağrı: 3 sn'lik götürme habersiz olmasın. (f) 23 yan görevin en az 8'i yol üstünde rastlanarak tetiklensin. Kışlak yapı olarak GTA V'in girişi ve Büyük Plato gibi çalışır, süre olarak değil: vadi oyunun bütün dillerini öğretir. [kurgu]
13. **II–VI kalıbı (#20, KB8).** `story.md` bu kalıba yazar; ad ve olay onun işidir. [çıkarım]

    | Perde | Ana görev (açılış + kollar + kapanış) | Yan | XP'li durak | Yeni iç harita | Taban XP/görev | K25 günü |
    |---|---|---|---|---|---|---|
    | II | 12 (4 + 3×2 + 2) | 15 | ≈12 | 2 | 205 | 12 |
    | III | 13 (2 + 3×3 + 2) | 15 | ≤8; kalan XP av ve tarif | 1 | 192 | 12 |
    | IV | 14 (2 + 3×3 + 3) | 15 | ≈12 | 3 | 178 | 14 |
    | V | 12 (2 + 3×2 + 4) | 15 | ≈12 | 2 | 206 | 12 |
    | VI | 14 (2 + 3×3 + 3) | 12 | 8–12; tek haritada ≤8 | 1–3 | 177 | 16 |

    - II'nin açılışı `settlement.md` §2.1'in dört görevidir; `own_seat` henüz yoktur. III–VI'nın ilk oynanan görevi **Dönüş**tür: `own_seat`'te yürüyüş, değişen 3–5 kişi ve yapı.
    - Kollar aynı anda açılır, sıra serbesttir, biri bitince ötekilerin satırı değişir (yankı kuralı). Her kol en az bir kez yerleşim ya da ordugâh dışına çıkarır.
    - Vakit çağrısı yalnız takvim olaylarında kalır, karartmayla götürmez: kaçırılan olay Kronik'te «sensiz yapıldı» satırı olur.
    - Süre payı, perde 420 dk: ana ≈180, yan ≈105, keşif ve yol ≈45, yerleşim, ordu, av ≈70, kamp ve sinema ≈20.
    - Son görev yeri önerisi: II av alanı, `whistle_field` (Shiji 110: 從其父單于頭曼獵,以鳴鏑射頭曼, [Wikisource](https://zh.wikisource.org/wiki/史記/卷110)); III `donghu_land`; IV `hexi_ash` ya da `ordos` (`hexi_ash` Tanhu 1'in IV. Perde vuruşuna yakındır, Belirsizlikler; `story.md` seçer); V `baideng`; VI son kart.
14. **Yan görev aileleri (#20).** Perde başına 5 etkin aile × 3 görev (VI: 4 × 3). Tabloda 6 aile vardır: II'de Elçi yoktur; III–V'te Elçi gelince öteki beşten biri o perde dinlenir, `story.md` seçer. Her aile bir sisteme bağlıdır. [kurgu]

    | Aile | Sistem | Tetik | Ödül |
    |---|---|---|---|
    | Hane | `settlement` Gönül, Kâhya | Hane isteği, sığınan | Gönül, Çekim, usta |
    | Yol | `travel` §9.6, `job_fare` | Yol olayı, Menzil | Atlas adı, `rumoured` yol, kervan |
    | Av | `survival` §4, `fauna.md` | İz, sürü zararı | Malzeme, ilk av XP, Destan dizesi |
    | Ordu | `army` talim, moral | Onluk sorunu, kaçak | `reflex`, moral, er |
    | Töre | Kut, Korku | Yargı, ant, kurgan | Kut ya da Korku, satır |
    | Elçi | `groups-research` §4 | Elçi Yurdu, III'ten | Grup adı, takas, hediye |

15. **Görev verici ve iğne (#20).** Üç kaynak: kişi, yer, olay. Ana görev `J`'de iç haritayı ve kişiyi yazar, yolu oyuncu seçer. Yan görev önce **söylentidir**: haritada soluk halka, çap 160 m; varınca kesinleşir. Harita baştan ikonla dolmaz. Elmas işaret kuralı aynen (Hikâye hep, Normal 45 sn, Zor yok). Satır her zaman nedeni söyler: «Bu yolu Balamir bilir.» [kurgu]
16. **Perde sonu (#19). K25 değişir.** Gün bütçesi yalnız tasarım ölçüsüdür, oyunda okunmaz.
    - Perde son ana görevle biter; son görev yalnız kollar bitince açılır, gün sayısına bağlı değildir.
    - **Son Görev Kapısı:** kart yazar: «Bu yol perdeyi kapatır. Sonra {y} yıl geçer.» Açık yan görevler listelenir. `Yola Çık` / `Daha Değil`. Saat bu kartta durur.
    - Açık yan görevin üç sonucu vardır, görev verisinde yazılır: `carry` (sonraki perdede sürer), `chronicle` (Kronik'te sonuç satırı), `lost` (kayıp, listede «Kapanır» diye işaretli). Sessiz düşüş yok.
    - Oyalanan için bedel yok, söz var: son görev açıldıktan sonra 3., 6. ve 9. günde kişiler 3 kademede sabırsızlanır. Ölçü gün bütçesi değildir: bütçeyi oyunda okumak gizli sayaç olurdu (#19). Mevsim kendi işini yapar ama geç gelir (§2.5): kışın ordugâh dağılır (K23), ekonomi dar geçer.
    - **Çelişki.** K25 ve `settlement.md` §12.2 «Kış Toplantısı oynanan günlere düşmez» der; sayaç kalkınca bu garanti olmaktan çıkar. `time.md` §2 formülüyle V'te 1. ayın yeni ayı 83. gündedir. Kural: oynanan günde sahne açılmaz, toplantı Kronik'in sonraki koşusunda toplu işlenir. K25 cümlesi buna göre düzelir.
    - **Çelişki.** `mete-tarih.md` görevleri kesin güne bağlar: darbe 14 Haziran 209, Dailin 16 Eylül 208, Lung-çeng 17 Haziran 205, Baideng 25 Kasım–1 Aralık 201. Sayaç yokken oyun takvimi bu günlerden sapar. Kural: kollar erken biterse son görev kapısı saati o güne atlatır (`clock:skip`); oyuncu o günü geçtiyse sahne gün söylemez, yıl ve mevsim söyler; kesin tarih Destan ve Kronik metninde kalır. Ayrıntı `story.md`'nindir.
    - Çekim perde tavanlı olduğu için beklemek hane kazandırmaz (K23). Kronik hedefi `max(K25 tarihi, bugün + 30)`: geçiş en az 445 gündür, pratikte tutmaz, kayıt güvencesidir. [çıkarım]
17. **Akan Kronik (KB9, K25 biçimi).** K25'in hesabı aynen işler (`settlement.md` §16.2), üstüne görünüm gelir. [kurgu]
    - Akış: perde kartı → atlas dönem değişimi → `dayN` ve tarih akar → mevsim nabzı → 2–5 ozan ya da anlatıcı satırı → hane ve sürü sayıları → yeni perde kartı.
    - Süre `T = clamp(mevsim × 5 sn, 30, 90)`: II→III 30, III→IV 54, IV→V 89, V→VI 50 sn. IV ve VI'nın iç atlamaları (`time.md` §2) aynı formülle işler, VI 90 sn'de kesilir. `E` basılı ×4 (`travel.md` §9.4 deseni), ilk izleyişte de atlanır.
    - Atlas yolculuğunun bütçesini kullanır: ≈31 çizim, ≈14,5 ms. Kapalı hesap mevsim başına ≤150 ms'dir (K25, `time.md` §7.4): IV→V ≈2,7 sn eder, tek karede değil, akış boyunca mevsim mevsim işlenir. `settlement.md` §16.2'nin toplam «≤150 ms»si K25'le tutmaz.
    - En çok 2 **Kronik Kararı** (Kış Toplantısı ataması gibi): tek kart, iki seçenek, 10 sn beklerse Kâhya seçer. Saat durmaz, Kronik akar.
    - Oyun içinde tarih de akar: Tan'da 2 sn «8 Haziran MÖ 209 · 1.229. gün». Palak'ın sayımı Mete'nin sayımına döner (`time.md` §2).
    - Perde arasını serbest oynamak önerilmez: son görevin ağırlığını siler, K25'in açılış tabanlarını bozar.

### Seviye

18. **İç harita reçetesi (#20). `progression.md` §10.1'in tanımı daralır.** 1.400×1.050 m için [çıkarım]:

    | Katman | Adet | Aralık | Ödül |
    |---|---|---|---|
    | Çapa (büyük üçgen) | 2–3 | 500–700 m | Yön, Bakış yeri |
    | Kapı | 1–2 | Kenar | Uzak Durak |
    | Görev yeri | 4–6 | ≥250 m | Ana ve yan görev |
    | Keşif durağı (Bakış, Menzil) | 3–8 | ≥300 m | `lookout`, `waystation` XP |
    | Küçük durak | 6–10 | 150–200 m | Bilgi, mal, ad, Destan dizesi; XP yok |
    | Zemin işareti | 20–30 | Zincir ≤65 m | Yön |

    İlk dört satır adlı yerdir; alt uçların toplamı 10, üst uçların 19'dur, harita 14–18'de tutulur: dörtnalda ≈307–348 m, ≈36–41 sn. Küçük durak eklenince 20–28 nokta: yürüyüşte ≈56–66 sn. Zemin işareti yöndür, dikkat sayılmaz. Yürüyüşte ≈40 sn için kalan ≈27–35 dikkat hareketli olaydır (§3.3). Sırası Elden Ring gibidir: önce çapa ve son görev yeri, sonra yollar, sonra katmanlar. Her görev yerine yaklaşmanın son 100–150 m'si −3..−7° iner: yer uzaktan görünür (`whistle_field` düz kalırsa orada yoktur, §3.4). Küçük durak örneği **Eski Ocak**: hazır 6 taşlık halka ve çukur (Gecelik Kamp'ın 30 Yük'lük taş sorununu çözer, öneri 27). Harita başına 3–5. Düğüm kümeleri bu sayıya girmez.
19. **Çapa ve ritim (#20, ek istek 1).** (a) Bozkır dalgası ±3–5°, 150–250 m boy, 8–22 m yükselme; talim ovası düz (`settlement.md` §3.3 için §3.4'teki çelişki). (b) **Sırt Bakışı:** çevresinden ≥6 m yüksek yerde dururken `cam_horizon` (`U`) basılı: `lookout` ayarı 16°, 44 m, en çok 6 sn. Bakış Noktası gibi harita açmaz, XP vermez. Bütçe Bakış ölçüsüne bağlıdır. Ad `whistle_field`'in «Bakış Sırtı» yeriyle karışır: metin yazılırken ayrılır. (c) **Kuş gölgesi:** IV'ten evcil doğan, V'ten kartal (`hayvanlar.md` öneri 10; Hun çağında kartal eğitimi belgeli değildir): uçurulunca gölgesi 8 sn en yakın keşfedilmemiş adlı yere doğru kayar. `cmd_bird`'ün sürü ve birlik lekesine ektir, kişi göstermez. Sahte çıkartma, 1 çizim. Kuşun cismi gök görünen açılarda çizilir. Dönem dayanağı `fauna.md`'nindir. (d) Gök Kavisi'ne ince kuzey çentiği: gündüz ve açık havada; gece ve körde `iron_stake` ister (Tipi'de pusula yok kuralı korunur). [kurgu]
20. **Yol ve sınır (#20).** Her iç harita: 1 ana yol (4 m; iki kapılı haritada kapıdan kapıya ≈1.400–1.600 m, çünkü `settlement.md` §3.2–§3.3 kapıları kuş uçuşu 1.448 ve 1.382 m ayrıdır; tek kapılı haritada kapıdan merkeze), 2–3 yan yol (300–600 m, 2–3 m), 3–5 patika (100–200 m, 1,5 m). Yan yolun ilk işareti ana yola ≤40 m. Seviye kilidi yok. Tehlike eşiği görünürdür: dikili sancak, kemik, yanık. Disney'in «anti-wienie»si bunun tersidir, bilerek sönüktür; burada işaret bakılsın diye vardır. Kapalı yolun nedeni kişi ya da bilgidir (`travel.md` §9.3 `rumoured`). [kurgu]

### Gizlilik

21. **Sonraki perdelerde gizlilik (#22).** Hesap `act1.md` §9.5 ile aynı kalır, oyuncu öğrendiği ölçüyle devam eder. Yakalanma yeniden yükleme değildir: alarm → kaç (≥60 m ve 20 sn görünmez) ya da dövüş; görev sürer, sonuç kademelidir (tam bilgi, yarım, yok) ve sonraki sahnenin zorluğunu ±%20 değiştirir. [kurgu]

    | Algılayan | Koni | Menzil | Not |
    |---|---|---|---|
    | Yaya nöbetçi | 80° | 16 m; fener 20 m | I. Perde değeri |
    | Atlı devriye | 100° | 24 m | Rota 300–500 m |
    | Kule gözcüsü | 50° | 40 m; karanlıkta 24 m | Barınak ×0,4 yerine ×0,7 |
    | Köpekli nöbetçi | 80° | 16 m + koku r 12 m | Rüzgâr altı ×0,5, üstü ×2 (`survival.md` §4); `fauna.md` |
    | Ateş başı | 40° | 6 m | Işık havuzu dışını geç görür |

    At gürültüsü: adım 8, tırıs 14, dörtnal 24 m; `hoof_wraps` ×0,5 (yeni etki: `progression.md` §6.4'te bugünkü işi «Buzda kayma yok»); `weather.fx.hearK` geçerli. Yaya: `dovus.md` «çan yok» sütunu. Sahnede ≤12 tam nöbetçi (`Folk` ≤16), alarmda ≤6 kukla. Koniler `read_watch` ister; ses halkası çömelikte yerde görünür (Mark of the Ninja). Kadraj dışı şüphe kenar okuyla okunur (öneri 7).

    | Perde | Yer | Görev kalıbı | Nöbetçi |
    |---|---|---|---|
    | II | `whistle_field` çevresi | Gece ağıl ya da rakip çadır gözleme, ders düzeyi | ≤6 |
    | III | `donghu_land` | Tunghu ordugâhını say: çadır, at, kapı; sayı savaşa yazılır | ≤10 |
    | IV | `hexi_ash`, `ordos` | Yanık Kışlak'a dönüş; beyle gizli görüşme | ≤8 |
    | V | `mayi` çevresi | **Ters gizlilik:** Han elçisi gelir, güçlü birlik ve semiz sürü saklanır, zayıf olan gösterilir. Elçi ve sürü Shiji 99'dadır: 匈奴匿其壯士肥牛馬,但見老弱及羸畜 · 使者十輩來 ([Wikisource](https://zh.wikisource.org/wiki/史記/卷099)). Shiji 110'daki 冒頓匿其精兵,見其羸弱 sonraki evredir: Han takipteyken. Vadi, yer ve gözcü oynanışı [kurgu]; `mete-tarih.md` öneri 11 yeri `whistle_field` ve otlak yazar, `story.md` seçer | 3 gözcü, koni 60°, 60 m |
    | VI | `hangai` ya da seçmeli harita | Takip ya da ad toplama | ≤8 |

### Küçük kurallar

22. **Yakıt (#23).** `Y` zaten ateş tuşudur. Ateşin ya da çukurun 3 m içinde kısa basış 1 yakıt ekler (0,8 sn, oyun durmaz), basılı tutuş 0,5 sn'de bir ekler. Uzakta `Y` bugünkü gibi yer seçimi. Tür sırası Yük verimine göre: tezek (360 sn/Yük) → dal → odun (60 sn/Yük); tarif çemberindeki **Yakıt** diliminden seçilir, seçim oturumda kalır. 720 sn dolunca «Ateş dolu.»; malzeme gitmez. 6 m içinde ince halka evreyi ve kalan saati gösterir. `E` değişmez (çember, Dinlen). Dokunmatikte Ateş düğmesi. Çocukta malzeme sayılmaz. [çıkarım]
23. **Çadır sökme (#24). `economy.md` §3.13'e satır.** Tek kural: sağlam taşınır yapı bohçasına döner, öteki hâller ham malzemenin yarısını verir. Sağlam `tent` → 1 `tent_kit`, emek 0,35 (≈76 İD). Eksik ya da hasarlı `tent` → ayaktaki adımların ham malzemesinin yarısı. §2.8'in «Söküm» kaynağı böylece doğru olur. Gecelik Çadır: Topla 15,1 İD, 2 keçe ve 1 sırık döner, 1 ip ve 2 dal sarf: kazık yerinde kalır. `econ-sim --strict` sınar. [çıkarım]
24. **Çukur (#25). `survival.md` §2, `time.md` §7.4 ve §10.2 değişir.** `cold_pit` şafakta değil, sönüşten 24 oyun saati sonra kalkar. Uyku en çok 15 saattir: uyanan oyuncu çukuru hep bulur. Kalkma anı oyuncu 30 m içindeyken ertelenir. Çadır yerindeyken çukur çadırla kalır. Yeniden yakma 1 odun ya da 2 tezek, kav istemez. Uzun atlamada (>24 sa) hepsi kalkar. Ateş ve çukur zon başına en çok 6; yenisi en eski çukuru siler. [çıkarım]
25. **Uyku (#26). `time.md` §7.3 daralır.** «Uykuda tehlike yoktur» yalnız güvenli yerler içindir: yurt, yerleşim, ordugâh, Menzil, hikâye döşeği. Açıkta gecede en çok bir kez **Uyku Zarı**: [kurgu]
    - Boş arazide ateş korur: `p = 0,10 × ateşsiz saat / uyku saati`. Olay kurt ya da yaban hayvanı.
    - Düşman zonunda ateş ele verir: `p = 0,25 × ateşli saat / uyku saati`. Olay devriye. Ateşsiz kampta zar yok, yemek de yok.
    - 9 sa 26 dk örneği: boş arazi, 4 sa 48 dk ateş %4,9; taşlı 7 sa 12 dk %2,4. Düşman zonu aynı ateşlerle %12,7 ve %19,1.
    - Hikâye 0, Zor ×1,5. Barınak zemini ×0,5. Köpek yanındaysa (`fauna.md`) uyanış 8 sn erken gelir.
    - Kesinti: uyurken hasar yok, eşya gitmez. Uyanış, tehdit 30 m'de, oto kayıt, oyun akar. ≥4 saat uyuduysan yaralar kapanır. Kaçarsan çadır yerinde kalır (10 gün).
    - Baskın kuralı (K24) bu zara karışmaz. Gerekçe: Valheim «düşman yok» koşulu, Kingmaker kamuflajı, Baldur's Gate bıkkınlığı: bir gecede bir olay, koşulu görünür.
26. **At üstünde toplama (#28). `economy.md` §3.1 değişir.** Tek kural: araç **El**, eylem ≤2 sn ve eğilip alınan düğüm at üstünde toplanır: `node_deadfall`, `node_wormwood`, `node_rosehip`, `node_buckthorn`, `node_herb_sleep`, `node_dung`. Liste kapalıdır. Ötekine tıklamak bugünkü gibi indirir. Kutlu ot inmeden koparılmaz (3 sn, satır korunur). At hızı ≤3 m/sn'ye iner, süre ×1,5; `knee_steer` varsa ≤5,5 m/sn ve ×1. Dörtnalda yok. Erişim 2,1 m kalır. İstem `E Topla`; `E` basılı 0,4 sn iner. Stamina yok. I. Perde sayılarını değiştirmez: düğüm hakkı aynıdır. [çıkarım]
27. **Gecelik Kamp sınaması (KB11).** Öneri `tek-gecelik-kamp.md` kabul edilir, üç değişiklikle. [çıkarım]

    | Sınama | Sonuç |
    |---|---|
    | RDR2 çabuk kurar (süre kaynağı bulunamadı) | Geçer: `T` ile ateş 5, kurma 2,3, Şiş 12, Uyu 3, Topla 2,3 sn; toplam ≈25 sn. **Değişiklik 1:** Topla da `T` ile atlanır |
    | Malzeme | 1 ip, 2 dal, yakıt, kav: 12 günde ≈5 gece, makul. Keçe ve sırık döner |
    | Yük | 5 Yük, koşu açık. 6 taş 30 Yük sığmaz. **Değişiklik 2:** Eski Ocak durağı |
    | K20 | Bozulmaz: döşek çadırda |
    | Ağır hava | 43 dk Zor işaretine (45 dk) sığar; yağmur 56, yoğun kar 62 dk sığmaz: hazırlık oyunu, kabul |
    | Atlas | İnme yok kalır. **Değişiklik 3:** çadır taşıyanın `ev_snowbound` «Kazın» bedeli −2 yerine −1 yiyecek, `ev_storm` «Sığın» +0,5 gün yerine bedelsiz |
    | Öğütme | XP yok, geçer |
    | I. Perde | Kapalı, Plan Kipi ile aynı kapı |

### Tanhu Kampı

28. **Biten yollar (#11, #13). K6 korunur, yol tablosu değişmez.** [kurgu]
    - `tanhu_camp` Mete için **sahnesiz konaktır**: `kind: 'waypost'`, spec yok, yalnız atlas. Ad: II «Tanhu Kampı», III'ten «Eski Avlu / The Old Court» (Avlu göçüyle haneler `tanhu_ordu`'ya gelir, `settlement.md` §2.2).
    - Altı yol zincirlenir: `r_hexi_tanhu`, `r_tanhu_longcheng`, `r_tanhu_hangai`, `r_tanhu_whistle`, `r_tanhu_donghu`, `r_tanhu_north`. Yol Kartı varışı yazar, konağı değil. Bedel ve gün toplanır, toplam `T` ≤30 sn (`travel.md` §9.1).
    - Konakta perde başına en çok 1 olay kartı: eski avludan haber, kalan hane, söylenti. İnilmez, sahne yüklenmez.
    - `gate_tanhu` kalkar. `gate_whistle_w` «Kuzey Kapısı» olur, Yol Kartı çatallanır. Balamir'in hattı (`drv_balamir`) `whistle_field`'e taşınır. `r_tanhu_whistle` II açılışındaki işlevini korur.
    - Hikâye gereği: darbe av alanındadır, Tanhu Kampı'na gerek yoktur. Teoman'ın avlusu II'de yalnız sinema ve Çocuk gözüdür (K7, K23). `story.md` oynanır bir avlu isterse çözüm kamp dünyası değil, ayrı küçük `WorldSpec`tir: menü dünyası hep korunur.
    - Serbest Gez aynen kalır, K9 sürücüsü değişmez. `travel.md` §1.3, §5, §9.3 ve `settlement.md` §3.3 satırları buna göre düzelir.

## Belirsizlikler

- **Arama bütçesi.** Araştırma sırasında oturumun web araması sınırı doldu. Bundan sonrası önceki sonuçlarla ve doğrudan açılan sayfalarla yürüdü. Elden Ring lütuf ışığı, GTA San Andreas'ın kilitli bölgeleri, RDR2 ve GTA V'in harita görev simgeleri, Total War ve Songs of Conquest'in geçişleri, Anno'nun oturum geçişi, Journey'nin dağı ve bozkırda taş yığını: **kaynak bulunamadı**, belgede bilgi olarak kullanılmadı. Şüpheci sınamada da sınır doluydu: yeni arama yapılamadı, sınama belgedeki bağlantılarla ve doğrudan açılan bağımsız sayfalarla yürüdü.
- **Zayıf kaynaklar.** 40 saniye kuralının «Вон Охман» aktarımı ikincildir, özgün söz bulunamadı; DTF ölçümleri tek kişilik iki saatlik oyundur. DiVA tezleri bağlantı reddettiği için yalnız arama özetinden okundu. Icy Veins, PCInvasion, SuperCheats, GameSpot, GameStar, GamesRadar gövdeleri açılamadı ya da kısaldı; PoE2, KCD ve Bannerlord sayıları topluluk ve kılavuz kaynaklıdır. RDR2'nin at üstü toplaması doğrudan doğrulanamadı. Sınamada 403 ya da bağlantı hatası veren sayfalar: Icy Veins, BoingBoing, Yahoo, Nexus, SuperCheats, Obsidian forumu, Cyberpost, Audiokinetic, Hutong, DiVA; bunlara dayanan satırlar yukarıda işaretlidir. `ctext.org` otomatik erişimi kapattığı için Shiji satırları Wikisource'tan okundu, `mete-tarih.md` ile tutuyor. Gamever ve Games Learning Society düşük güvenli sitelerdir.
- **Diablo'nun eğim sayısı.** Diablo IV ve PoE2 için derece kaynağı yok. «Diablo tarzı» sözü burada his olarak okundu; 28° proje kararıdır. Kullanıcı daha dik bir varsayılan isterse `camPitchBias` karşılar, hesaplar değişmez. Tek dolaylı dayanak: oyunlarda yaygın 2:1 izdüşüm 30° kamera eğimine denk gelir, ilk Diablo sabit izometrik bakış sayılır ([Wikipedia](https://en.wikipedia.org/wiki/Isometric_video_game_graphics)); Diablo'nun 2:1 kullandığı orada yazmaz. 28° buna yakındır [çıkarım]. Diablo IV için bu hesap geçmez.
- **Ölçülecek.** (a) 22° ve 24° alt sınırında Kışlak ve yerleşim kare süresi; aşılırsa alt sınır 24°. (b) Sırt Bakışı'nın gök ve uzak arazi maliyeti. (c) 3 `HRTF` kaynağının maliyeti. (d) Yön Payı'nın baş döndürücü olup olmadığı: oyuncu sınaması. (e) Kenar okunun Kara Boran'da kalabalıklaşması. (f) 12–14 görevin ≈13 dakikası ilk tahmindir.
- **Bütçe çakışması.** `progression.md` §1.2 II+ Keşif sütununa av ve tarifi de katar. ≈12 durak hesabı bunları saymaz; tam oyuncuda Keşif XP'si sütunu aşar. Tavan XP silmez, denge kırılmaz, ama sütun yeniden yazılmalıdır.
- **Sahiplik.** Görev adları, son görevlerin içeriği, Dönüş satırları `story.md`'nindir. Kartal ve köpek `fauna.md`'nindir: dönem dayanağı orada sınanır, «evcil kartal» burada [kurgu]'dur. Ters gizlilik görevi Shiji 99 ve 110 satırlarına dayanır, oynanışı [kurgu]'dur.
- **K ve belge değişiklikleri.** K25 (gün bütçesi ölçü, Kış Toplantısı cümlesi), K27 (eğim ve yeni girdi), `time.md` §7.3 ve §7.4, `survival.md` §2, `economy.md` §3.1 ve §3.13, `act1.md` §4 ve §10, `audio.md` 3B satırı, `architecture.md` §8 karar 19, `travel.md` §1.3, §5, §9.3, `settlement.md` §3.3, §12.2, §16.2, `progression.md` §6.4 ve §10.1, kodda `CAM.crouch` ve `CAM.ride`. Bu belge öneridir: bağlayıcı karar `decisions.md`'ye yazılır.
- **Tanhu 1 sınaması.** `docs/research/progression.md` ile karşılaştırıldı: Tanhu 1'in perde adı, kişisi, son adı ve nesnesi (ayna, parça, Motun, Ayaz, Kadfi) belgede yoktur. İki yakınlık kalır. (a) `hexi_ash` ve «Yanık Kışlak'a dönüş»: Tanhu 1'in IV. Perde'si de esirliğin yanan kampına fatih dönüşüdür (`yanik_kamp`). `hexi_ash` bu belgeden önce `travel.md` §1.3'te vardır; son görev yeri olması buradan gelir. Register kural 1 gereği `story.md` bu vuruşu kopyalamadan kurar ya da son görevi `ordos`'a alır. (b) «Ardına Atış / Parting Shot» (öneri 8) `docs/design/progression.md` §4.8'den gelir, Tanhu 1'in `ardina_atis`'iyle aynı addır; Kut ve Korku da Tanhu 1'de vardır (öneri 14). Bunları değiştirmek o belgenin sahibinin işidir.
- **Şüpheci sınama (2026-11-04).** ≈50 dış iddia ve ≈30 proje sayısı sınandı. Düzelenler: Witcher 3 «son bölge» ve «tek son»; Diablo IV seviye engeli ve dünya boss kamerası; Majora'nın «ayrıştırıcı»sı ve §5'in «sayaç tepki çeker» sonucu; 40 saniye kuralının kişi atfı ve seçilmiş ölçümleri; CEDEC «çevirisi»; Disney «itici» terimi; Shiji 99 ile 110'un karışması; Nesky listesinin bağlantısı; BG3 tuşları; III'ün 15 durağı; Dönüş görevinin II'ye yazılması; 6 aile ile 5 aile; gün bütçesinin gizli sayaç olması; Kış Toplantısı garantisi; mevsim uzaklığı; Kronik'in ≤150 ms'si; ana yol uzunluğu; `whistle_field`'in düzlüğü; `CAM.ride`; 24°, 44 m satırı; zemin işaretinin dikkat sayılması; komşu belgelerle kartal perdesi, HRTF sırası ve kesin görev tarihleri. Doğru çıkıp değiştirilmeyenler: kadraj hesaplarının geri kalanı, XP ve durak formülleri, Kronik süreleri, uyku zarı örnekleri, Nesky numaraları, RDR2 görev sayıları, Ghost of Tsushima, Elden Ring, Valhalla, Three Houses, Valheim, RDR2 kampı, XAG 103, MDN, Shiji 110 satırları.

## Kaynaklar

**Seviye ve açık dünya**
- [CEDEC 2017 basın özetleri, Matt Walker derlemesi (gist)](https://gist.github.com/idbrii/e39fe96279aa1670319bfa521d907399)
- [Gigazine: Breath of the Wild tasarım sırrı](https://gigazine.net/gsc_news/en/20171004-breath-of-the-wild-design-secret)
- [Stephen Clarke-Willson: Level Design, Disneyland Style](https://www.above-the-garage.com/wienies/)
- [Game Developer: What Mario Learned from Mickey Mouse, Part 3](https://gamedeveloper.com/design/what-mario-learned-from-mickey-mouse---part-3-decision-making-and-weenies)
- [BoingBoing: Scott Rogers'ın Disneyland ve seviye tasarımı konuşması](https://boingboing.net/2009/03/27/gamedesign-lessons-f.html/amp)
- [DTF: 40 saniye kuralı ve ölçümler](https://dtf.ru/games/70450-chto-takoe-pravilo-40-sekund-v-igrah-s-otkrytym-mirom-i-pochemu-ego-stoit-soblyudat)
- [DiVA: The 40 Seconds Rule and Points of Interest in The Witcher 3](https://www.diva-portal.org/smash/get/diva2:1569059/FULLTEXT01.pdf)
- [GDC Vault: Exploration in Ghost of Tsushima](https://www.gdcvault.com/play/1027399/Exploration-in-Ghost-of-Tsushima)
- [Wikipedia: Great Plateau](https://en.wikipedia.org/wiki/Great_Plateau)
- [GamesRadar: The making of Outer Wilds](https://www.gamesradar.com/the-making-of-outer-wilds)
- [Wikipedia: Outer Wilds](https://en.wikipedia.org/wiki/Outer_Wilds)

**Görev yapısı**
- [Wikipedia: The Witcher 3](https://en.wikipedia.org/wiki/The_Witcher_3:_Wild_Hunt)
- [GOG forumu: Isle of Mists](https://www.gog.com/forum/the_witcher_3_wild_hunt/isle_of_mists)
- [allthings.how: Witcher 3 kaçırılan görevler](https://allthings.how/the-witcher-3-every-missable-quest-and-its-point-of-no-return/)
- [GTA BASE: RDR2 görev listesi](https://www.gtabase.com/red-dead-redemption-2/missions/?lang=en)
- [SegmentNext: RDR2 görevleri](https://segmentnext.com/red-dead-redemption-2/quests)
- [Wikipedia: Red Dead Redemption 2](https://en.wikipedia.org/wiki/Red_Dead_Redemption_2)
- [PowerPyx: Blackwater ve New Austin ödülü](https://www.powerpyx.com/red-dead-redemption-2-how-to-remove-bounty-in-blackwater-new-austin/)
- [Wikipedia: Grand Theft Auto V](https://en.wikipedia.org/wiki/Grand_Theft_Auto_V)
- [Wikipedia: Ghost of Tsushima](https://en.wikipedia.org/wiki/Ghost_of_Tsushima)
- [VideoGamer: Elden Ring boss yerleri](https://www.videogamer.com/news/elden-ring-setting-was-designed-around-its-bosses/)
- [PlayStation Blog: Miyazaki söyleşisi](https://blog.playstation.com/2022/01/28/an-interview-with-fromsoftwares-hidetaka-miyazki/)
- [Wikipedia: Elden Ring](https://en.wikipedia.org/wiki/Elden_Ring)
- [GamePressure: Diablo IV perdeleri](https://www.gamepressure.com/diablo-iv/how-many-acts-are-in-the-game/z210c8f)
- [Wikipedia: Diablo IV](https://en.wikipedia.org/wiki/Diablo_IV)
- [Icy Veins: Diablo IV sefer rehberi](https://www.icy-veins.com/d4/guides/quick-reference-campaign-leveling-guide-for-diablo-4/)
- [Wikipedia: Kingdom Come: Deliverance](https://en.wikipedia.org/wiki/Kingdom_Come:_Deliverance)
- [Cyberpost: KCD süreli görevler](https://cyberpost.co/which-quests-in-kcd-are-time-sensitive/)
- [Wikipedia: Mount & Blade: Warband](https://en.wikipedia.org/wiki/Mount_%26_Blade:_Warband)
- [Wikipedia: Assassin's Creed Valhalla](https://en.wikipedia.org/wiki/Assassin%27s_Creed_Valhalla)

**Takvim ve kronik**
- [Wikipedia: Crusader Kings](https://en.wikipedia.org/wiki/Crusader_Kings_(video_game))
- [Steam: Bannerlord yılı](https://steamcommunity.com/app/261550/discussions/0/2144217924395139345)
- [Wikipedia: Pathologic 2](https://en.wikipedia.org/wiki/Pathologic_2)
- [Yahoo: Majora's Mask'in yapımı](https://sg.news.yahoo.com/legend-zelda-majoras-mask-inside-130032809.html)
- [Wikipedia: The Legend of Zelda: Majora's Mask](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Majora%27s_Mask)
- [Paizo forumu: Kingmaker süre sınırı](https://paizo.com/threads/rzs435mh)
- [Wikipedia: Fire Emblem: Three Houses](https://en.wikipedia.org/wiki/Fire_Emblem:_Three_Houses)
- [GamesRadar: Three Houses beş yıl](https://www.gamesradar.com/why-fire-emblem-three-houses-five-year-gap-is-its-smartest-storytelling-decision)
- [Wikisource: Shiji 110](https://zh.wikisource.org/wiki/史記/卷110)
- [Wikisource: Shiji 99](https://zh.wikisource.org/wiki/史記/卷099)

**Harita geçişi**
- [Matchstick Eyes: Strategic zoom](https://www.matchstickeyes.com/tag/rts-zoom/)
- [Armchair General: Supreme Commander](https://armchairgeneral.com/review-supreme-commander.htm/2)
- [SimViation: Flight Simulator dünya haritası](https://forums.simviation.com/phpBB3/viewtopic.php?p=1318821)
- [Webiano: Google Earth](https://webiano.digital/google-earth-still-lets-you-fly-the-planet-like-a-secret-cockpit/)
- [GamePressure: Anno 1800 yenilikleri](https://gamepressure.com/anno-1800/whats-new-in-anno-1800/z3b4f7)

**Kamera ve ses**
- [John Nesky'nin 50 kamera hatası, Telegram listesi, ileti 798](https://t.me/s/disdoc/798)
- [GDC Vault: 50 Camera Mistakes](https://gdcvault.com/play/1020460/50-Camera)
- [GamePressure: Diablo IV yakınlaştırma](https://www.gamepressure.com/diablo-iv/can-you-zoom-out-the-camera/zd10c90)
- [The Geek: Diablo IV ve serbest kamera](https://thegeek.games/?p=45196)
- [Mejoress: PoE2 kamera](https://www.mejoress.com/en/path-of-exile-2-how-to-rotate-the-camera/)
- [PoE forumu: kamera açısı](https://www.pathofexile.com/forum/view-thread/3544195)
- [PCGamesN: BG3 kamera](https://www.pcgamesn.com/baldurs-gate-3/camera-controls)
- [Fextralife: BG3 tuşları](https://baldursgate3.wiki.fextralife.com/Controls)
- [bg3.wiki: Controls](https://bg3.wiki/wiki/Controls)
- [Wikipedia: Isometric video game graphics](https://en.wikipedia.org/wiki/Isometric_video_game_graphics)
- [Magic Game World: Dragon Age Origins tuşları](https://www.magicgameworld.com/?p=127065)
- [GameStar: Dragon Age taktik görünüm](https://www.gamestar.de/artikel/dragon-age-2-keine-taktik-ansicht-aus-der-vogelperspektive,2316849.html)
- [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-gb/gaming/accessibility/xbox-accessibility-guidelines/103)
- [Hutong Games: Offscreen Indicator](https://docs.hutonggames.com/guides/ui-widgets/target-managers/offscreen-indicator/)
- [MDN: PannerNode.panningModel](https://developer.mozilla.org/en-US/docs/Web/API/PannerNode/panningModel)
- [Audiokinetic Q&A: uzaklık oyuncudan, kaydırma kameradan](https://www.audiokinetic.com/qa/6112/unity-distance-relative-the-player-panning-relative-camera)

**Hayatta kalma ve gizlilik**
- [Shacknews: RDR2 kamp](https://shacknews.com/article/108136/how-to-craft-a-camp-and-campfire-in-red-dead-redemption-2)
- [Gamever: Valheim'da uyku koşulları](https://gamever.io/knowledge-base/sleeping-in-valheim-the-five-conditions-and-what-the-night-actually-skips)
- [Steam: Valheim ateş kapasitesi](https://steamcommunity.com/app/892970/discussions/0/3186860850587227859)
- [Games Learning Society: Valheim ateş](https://www.gameslearningsociety.org/wiki/what-items-count-for-fire-in-valheim/)
- [GamerGuides: KCD2 kampları](https://gamerguides.com/kingdom-come-deliverance-ii/database/points-of-interest/camps)
- [PC Gamer: KCD2 kamp modu](https://www.pcgamer.com/games/rpg/finally-this-kingdom-come-deliverance-2-camping-mod-means-ill-never-have-to-scour-bohemia-for-a-place-to-sleep-again)
- [GamerGuides: Kingmaker ilk gece](https://www.gamerguides.com/pathfinder-kingmaker/guide/walkthrough/chapter-1-getting-started-in-the-outskirts/first-night-in-the-stolen-lands)
- [Lilura: Baldur's Gate dinlenme baskınları](https://lilura1.blogspot.com/2019/10/Baldurs-Gate-Retrospective-Review-On-Rest-Ambushes-and-Overworld-Waylays.html)
- [Obsidian forumu: dinlenme baskınları](https://forums.obsidian.net/topic/89905-you-have-been-waylaid-by-enemies-and-must-defend-yourself/page/2)
- [Fextralife: Ghost of Tsushima at](https://ghostoftsushima.wiki.fextralife.com/Mount)
- [Nexus Mods: RDR2 at üstü toplama modu](https://www.nexusmods.com/reddeadredemption2/mods/4674)
- [SuperCheats: Desperados III görüş alanı](https://www.supercheats.com/desperados-3-walkthrough-guide/enemy-field-of-view)
- [Game Developer: Mark of the Ninja](https://gamedeveloper.com/design/reinventing-stealth-in-2d-with-i-mark-of-the-ninja-i-)

**Proje belgeleri:** `docs/design/d3/register.md`, `decisions.md`, `act1.md`, `travel.md`, `time.md`, `survival.md`, `progression.md`, `settlement.md`, `economy.md`, `architecture.md`, `audio.md`, `src/game/camera-rig.js`, `src/game/game.js`, `docs/research/mete-tarih.md`, `docs/research/hayvanlar.md`, `docs/research/ses-tasarimi.md`, `docs/research/progression.md`; site: `oynanis/acik-dunya-gorevler`, `oynanis/kamera-kontroller`, `oynanis/tek-gecelik-kamp`, `dunya/harita`, `dunya/yolculuk`.
