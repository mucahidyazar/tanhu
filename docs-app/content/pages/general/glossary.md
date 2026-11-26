---
title: Sözlük
order: 40
summary: 'Belgelerde geçen oyun terimleri, konuya göre: ölçüler, bölümler, mitoloji, çalgı ve ses, karakter, yoldaşlar, ekonomi, dünya, I. Perde, yerleşim, yurt ve site; her terim anlatıldığı sayfaya bağlı.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/story.md
  - docs/design/act1.md
  - docs/design/economy.md
  - docs/design/settlement.md
  - docs/design/structures.md
  - docs/design/companions.md
  - docs/design/fauna.md
  - docs/design/audio.md
---

Terimi arıyorsan ⌘K daha hızlıdır: bütün belgelerde arar. Buradaki tanımlar kısa tutuldu, sayılar bağlı sayfadadır. Kararlara numarasıyla değinilir: [K50](/docs/source/design/decisions#k50) gibi.

## Ölçüler

| Terim | Anlamı | Sayfa |
|---|---|---|
| Oyun günü | 24 oyun saati, 60 gerçek dakika; 1 oyun saati 2,5 dk, 1 oyun dakikası 2,5 sn. Hız ayarı yoktur ([K67](/docs/source/design/decisions#k67)) | [Zaman ve Takvim](/docs/world/time-calendar) |
| Takvim | Oyunun tek saati: gerçek tarihli, MÖ yılı, ay ve gün olarak yazılır, geri gitmez; gündüz, gece, ay ve mevsim ondan okunur ([K67](/docs/source/design/decisions#k67)) | [Zaman ve Takvim](/docs/world/time-calendar) |
| El | Bir işte çalışan kişi sayısı: «8 el» 8 işçi demektir | [İnşa ve Emek](/docs/buildings/construction-labour) |
| İD, İS, İG | İş dakikası (bir işçinin bir oyun dakikası emeği), iş saati (60 İD), iş günü (1.440 İD) | [İnşa ve Emek](/docs/buildings/construction-labour#emek-yasasi-k21) |
| Yurt eğrisi | `T(n) = taban × 0,75^(n−1)`, n en çok 8 el; Hane Yurdu 60 / 45 / 33,75 … 8,0 dk. İnşaatta, sökümde ve onarımda geçer ([K50](/docs/source/design/decisions#k50)) | [İnşa ve Emek](/docs/buildings/construction-labour) |
| Yük | Oyunun tek ağırlık birimi. Heybe, terki, araba ve ambar hep bununla sınırlanır | [Envanter ve Yük](/docs/economy/inventory-load#yuk) |
| Kıymet | Oyuncunun görmediği fiyat ölçüsü: 1 Aş 4, 1 koyun 48, 1 at 336 | [Para ve Satıcılar](/docs/economy/money-traders#kiymet) |
| Kabuk | Para birimi: 1 kabuk = 4 Kıymet = 1 Aş; eşyanın adı «Tunç Kabuk»; I. Perde'de yoktur, II'den görünür ([K48](/docs/source/design/decisions#k48)) | [Para ve Satıcılar](/docs/economy/money-traders#kabuk) |
| Kese | Hun satıcısının üstü verdiği kabuk, şafakta dolar: Tanhu pazarcısı 52, Takas Yeri gezgini 30, Çiang tuzcusu 26 ([K81](/docs/source/design/decisions#k81)) | [Para ve Satıcılar](/docs/economy/money-traders#saticilar) |
| Aş | İşlenmiş temel yiyecek: 2 darıdan, 1 öğün. Yol bedeli de bununla yazılır | [Malzemeler](/docs/economy/materials) |
| Öğün | Hanenin ve ordunun yiyecek ölçüsü | [Üretim ve Depolama](/docs/settlement/production-storage) |

## Bölümler ve hikâye

| Terim | Anlamı | Sayfa |
|---|---|---|
| Perde | Hikâyenin bölümü, notundaki «Act». Altı Perde, önünde Önsöz ve Çocukluk, sonunda Sonsöz: dokuz bölüm ([K32](/docs/source/design/decisions#k32)) | [Hikâye Omurgası](/docs/story/spine) |
| Önsöz «Kopuz Söyler» | Tamamen sinema, 4 dk 18 sn: geri çekilme, kopuzlu şarkı, sessizlik, parşömen videosunda mit, doğum ([K68](/docs/source/design/decisions#k68), [K93](/docs/source/design/decisions#k93)) | [Önsöz: Kopuz Söyler](/docs/story/prologue) |
| Çocukluk «Koyun Sırtında» | 22 Eylül MÖ 228, Ordos: beş yaşındaki Mete'yle oynanan ≈6 dakika ([K36](/docs/source/design/decisions#k36)) | [Çocukluk: Koyun Sırtında](/docs/story/childhood) |
| Köprü 1, Köprü 2 | Anlatıcının iki geçişi: N1–N5 (222–213 yılları) ve N6–N7 (kapı ve bileğe bağlanan çan) | [Çocukluk: Koyun Sırtında](/docs/story/childhood#kopru-1) |
| Yola Hazırlan, Yola Çıkış | Mete'nin oluşturucusu; 15 Aralık MÖ 213'te yayın beşiğe asıldığı ve rehineliğe yola çıkılan sahne | [Çocukluk: Koyun Sırtında](/docs/story/childhood#yola-cikis) |
| I. Perde «Çan» | 2–7 Aralık MÖ 210, Hexi'deki Yüeçi Kışlağı: rehinelik ([K38](/docs/source/design/decisions#k38)) | [I. Perde: Çan](/docs/story/act-1) |
| II. Perde «Ok Neyi Gösterirse» | 1–15 Haziran MÖ 209: ıslıklı ok, talim, darbe | [II. Perde: Ok Neyi Gösterirse](/docs/story/act-2) |
| III. Perde «Boş Toprak» | 1 Eylül–1 Ekim MÖ 208: Tunghu'nun üç isteği | [III. Perde: Boş Toprak](/docs/story/act-3) |
| IV. Perde «Borç» | 1 Haziran MÖ 205–22 Eylül MÖ 203: borçlar, Yüeçi'nin sürülmesi, Ordos | [IV. Perde: Borç](/docs/story/act-4) |
| V. Perde «Dört Renk» | 20 Kasım–1 Aralık MÖ 201: Baideng kuşatması | [V. Perde: Dört Renk](/docs/story/act-5) |
| VI. Perde «Sayım» | 1 Haziran MÖ 198–9 Eylül MÖ 174: son sayım | [VI. Perde: Sayım](/docs/story/act-6) |
| Sonsöz «Kopuz Susar» | 9 Eylül–8 Ekim MÖ 174: yoğ, Jiyu Tanhu olur, kopuz son dizede susar | [Sonsöz: Kopuz Susar](/docs/story/epilogue) |
| Ev | I. Perde'nin son sahnesi: 11 Nisan MÖ 209, Teoman'ın kampı, ikindi ışığı ([K76](/docs/source/design/decisions#k76)); Tanhu Kampı'nın kendi küçük dünyasında uzak karedir, menü dünyasını yüklemez ([K106](/docs/source/design/decisions#k106)) | [I. Perde: Çan](/docs/story/act-1) |
| Akan Kronik | Perde arasındaki yılların ay ay akışı, 30–90 sn, atlanabilir: II→III 30, III→IV 54, IV→V 89, V→VI 50 sn ([K42](/docs/source/design/decisions#k42)) | [Perde Arası: Akan Kronik](/docs/story/chronicle#akan-kronik) |
| Kronik'e bırak | Perde bitince oyuncunun dilediği an Akan Kronik'i başlatması | [Perde Arası: Akan Kronik](/docs/story/chronicle#serbest-dolasim) |
| Kronik Kararı | Kronik sırasında tek kart, iki seçenek; 10 sn sonra Kâhya seçer, Kronik başına en çok 2 | [Perde Arası: Akan Kronik](/docs/story/chronicle) |
| Son Görev Kapısı | Son görevden önceki kart: «Bu yol perdeyi kapatır. Sonra {y} yıl geçer.»; açık yan görevler listelenir | [Perde Arası: Akan Kronik](/docs/story/chronicle#perde-sonu-son-gorev) |
| Serbest Gez | Menüden açılan yan kip: ana kampta (Göl Obası) Çocuk olarak gezinme; 11 Nisan MÖ 209, 14:46,2'de açılır ([K37](/docs/source/design/decisions#k37), [K76](/docs/source/design/decisions#k76)) | [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests) |
| Serbest Dolaşım | II'den sonra perde bitince açık kalan dünya; Serbest Gez'den ayrıdır | [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests) |
| Dailin | 8. ayın dolunayındaki güz toplantısı ve sayım; üç kez oynanır: 16 Eylül MÖ 208, Ordos'ta 22 Eylül MÖ 203, 9 Eylül MÖ 174 ([K56](/docs/source/design/decisions#k56)) | [Hanlık Merkezi](/docs/settlement/court#toplantilar), [Dailin](/encyclopedia/dailin) |
| Lung-çeng | Beşinci ayın toplantısı: atalara, göğe, yere sunu; IV'te 17 Haziran MÖ 205 ve 25 Haziran MÖ 203, VI'da 2 Haziran MÖ 198 ve 4 Haziran MÖ 176 | [Hanlık Merkezi](/docs/settlement/court#toplantilar), [Lung-çeng](/encyclopedia/longcheng) |
| Kurultay | VI. Perde'nin büyük toplantısı, 3–4 Haziran MÖ 198 | [VI. Perde: Sayım](/docs/story/act-6) |
| Dikey dilim | Gün I'in ilk 15 dakikası ve Tipi: Godot'da ilk oynanan ölçüm; sen onaylamadan sonraki fazlar açılmaz (K11, [K69](/docs/source/design/decisions#k69)) | [Yol Haritası](/roadmap#act-1-p4) |
| Metin kilidi | Satırların süre ve sırayla donması; kilitlenmeyen satır seslendirilmez ([K61](/docs/source/design/decisions#k61)) | [Seslendirme](/docs/presentation/voice-over) |

## Mitoloji

| Terim | Anlamı | Sayfa |
|---|---|---|
| Tengri | Gök; Hun çağı metinlerinde adı geçen tek tanrı (撐犁, Hanshu 94A) | [Mitoloji](/docs/story/mythology), [Tengri](/encyclopedia/tengri) |
| Erlik Han | Altay anlatılarında yeraltı hükümdarı. Oyunda adı anılmaz, pazarlık eder; yüzü ilk kez I. Perde'de Teoman'ın yüzüyle görünür | [Mitoloji](/docs/story/mythology), [Erlik Han](/encyclopedia/erlik) |
| Umay | Doğumun, eşin ve çocuğun koruyucusu; 8. yy yazıtlarındadır | [Mitoloji](/docs/story/mythology), [Umay](/encyclopedia/umay) |
| Kayra Han, Ülgen | Altay yaratılış anlatısının göğü ve altın dağdaki aydınlık; 19. yy derlemeleri | [Kayra Han](/encyclopedia/kayra-han), [Ülgen](/encyclopedia/ulgen) |
| Yer-Sub | Yerin ve suyun kutsal bütünü (8. yy yazıtları); Hun çağında adı yok, yere sunu var | [Yer-Sub](/encyclopedia/yer-sub) |
| Demirkazık | Göğün dönmeyen noktası ve çevresinde dönen iki at; MÖ 209'da kutupta parlak yıldız yoktur | [Demirkazık](/encyclopedia/demirkazik) |
| Toybodım | Erlik'in gözyaşı ırmağı: «doymadım» | [Toybodım](/encyclopedia/toybodim) |
| Al Karısı | Loğusanın düşmanı, ocaktan korkan kadın ruh | [Al Karısı](/encyclopedia/al-karisi) |
| Od Ana, Bayanay | Ocak ateşinin anası; ormanın ve avın sahibi | [Od Ana](/encyclopedia/od-ana), [Bayanay](/encyclopedia/bayanay) |
| Gök ve Yer | Destan Kitabı'nın mit bölümü: en çok 24 girdi; Gök, Yer, Alt, Hayvan, Destan ([K35](/docs/source/design/decisions#k35)) | [Mitoloji](/docs/story/mythology) |
| Çağ rozeti | Her mit girdisinin tanıklık çağı: «Yıllıktan» (Hun çağı Çin yıllıkları), «Taştan» (Göktürk ve Uygur), «Ozan der» (geç derlemeler), «Bizim» (oyunun seçimi) | [Mitoloji](/docs/story/mythology) |
| Keçe pano | Önsöz'ün mit sinemasının yedek görüntüsü: keçe aplike panolar; asıl görüntü parşömen videosudur ([K93](/docs/source/design/decisions#k93)), doğum 3B'dir | [Önsöz: Kopuz Söyler](/docs/story/prologue#mit-sinemasi) |
| Iduk | Kutsal sayılan hayvan: Adak Aygırı ıduktur, sayılmaz, kervana verilmez ([K65](/docs/source/design/decisions#k65)) | [Hayvanlar](/docs/world/animals), [Adak Aygırı](/encyclopedia/offering-stallion) |
| Kopuz Gecesi | Ocağın ozanını akşam ya da gece ≥1 oyun saati dinlemek ertesi gün ilk büyük avda +1 verim verir, günde 1 | [Hayvanlar](/docs/world/animals) |
| Pay Bırak, Yer küstü | Av töresi: yüzdükten sonra bölgeye 1 parça et ya da yağ bırakmak; bir günde stoğun %30'undan fazlası vurulursa 2 şafak boyunca avın geri gelmesi %15'e iner | [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting#stok-pay-ve-yasak-av) |

## Çalgı ve ses

| Terim | Anlamı | Sayfa |
|---|---|---|
| Kopuz | Ozanın çalgısı: üç telli, perdesiz, parmakla çalınan, gövdesinin bir bölümü deri, bağırsak telli uzun saplı lavta; notundaki «saz» ([K60](/docs/source/design/decisions#k60)) | [Ses ve Müzik](/docs/presentation/sound-music) |
| Kıl kobuz | Yaylı çalgı, oyma at başlı; Mete'nin çağında elde görünmez | [Ses ve Müzik](/docs/presentation/sound-music) |
| Ağız kopuzu | Ağızla çalınan çalgı | [Ses ve Müzik](/docs/presentation/sound-music) |
| Dombra | Kazak çalgısının adı; oyunda geçmez, Godot'daki eski model kopuzla değişir ([K34](/docs/source/design/decisions#k34)) | [Ses ve Müzik](/docs/presentation/sound-music) |
| Çekim | Eleven Music'in tek şarkı üretimi; ozanın şarkısında 3104'ü sen seçtin ([K95](/docs/source/design/decisions#k95)) | [Seslendirme](/docs/presentation/voice-over) |
| Dilim (A, B, C, D) | Hangi satırın ses alacağı: A hep (anlatıcı, tanrılar, sinema, ana görev düğümü), B düğüm, C havuz, D yazı ([K61](/docs/source/design/decisions#k61)) | [Seslendirme](/docs/presentation/voice-over) |
| Kısma | Konuşmada müzik ve ortamın inmesi: anlatı −3/−3, gündelik −6/−3, gerilim −6/−6, baskın −9/−6 dB ([K78](/docs/source/design/decisions#k78)) | [Ses ve Müzik](/docs/presentation/sound-music) |
| Tanıtım sesi | Ansiklopedide hoparlöre basınca kişinin iki cümlelik tanıtımı; söz İngilizce, altyazı Türkçe ([K86](/docs/source/design/decisions#k86)) | [Ansiklopedi](/encyclopedia) |

## Karakter

| Terim | Anlamı | Sayfa |
|---|---|---|
| Can | Biterse yara yazılır, Can %50'ye döner. Ölüm yoktur | [Dövüş](/docs/gameplay/combat#yara-ve-dusus) |
| Tokluk | Açlık göstergesi. Yerleşimde aynı adla bir çarpan da vardır | [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting#tokluk) |
| Yara | Stamina, koşu ve Can yenilenmesini düşüren ceza. Sargı, dinlenme ya da uyku kapatır | [Dövüş](/docs/gameplay/combat#yara-ve-dusus) |
| Bilek, Soluk, Ayak, Göz, Söz | Beş stat: yük ve vuruş, stamina, sessizlik ve hız, nişan ve iz, güven ve takas | [Seviye ve Gelişim](/docs/gameplay/progression) |
| Kut | İki bağımsız eksenden biri. Altın güneşle görünür, sayı yok. Merhamet seçeneklerini açar, ant bozulunca düşer | [Seviye ve Gelişim](/docs/gameplay/progression) |
| Korku | Öteki eksen. Kızıl korla görünür, sayı yok. Nöbetçiyi duraksatır, Güven kazancını düşürür | [Seviye ve Gelişim](/docs/gameplay/progression) |
| Düşüş, Umay Eşiği | Yara sınırına varınca (Normal 3) gelen kararma ve altın ışıklı uyanış. Saat ilerler, bedeli vardır | [Dövüş](/docs/gameplay/combat#yara-ve-dusus) |
| Üç Zemin | Patika, Derin Kar, Barınak. Görülme, iz, hız ve stamina dolumu zemine göre değişir | [Dövüş](/docs/gameplay/combat#gizlilik-ve-nobetci-algisi) |

## Yoldaşlar

| Terim | Anlamı | Sayfa |
|---|---|---|
| Yoldaş | Mete'nin yanında gezen adlı kişi; partide en çok 10. Kadro 16: 12 çekirdek, 4 konuk ([K70](/docs/source/design/decisions#k70), [K71](/docs/source/design/decisions#k71)) | [Yoldaşlar](/docs/gameplay/companions) |
| Onluk, Mete'nin Onluğu | Partinin on yuvası; Mete'yle 11 kişi. Ordunun en küçük birliği de onluktur | [Ordu](/docs/gameplay/army#mete-nin-onlugu-yoldaslar-ve-erler) |
| Çekirdek yoldaş, konuk | Çekirdek yoldaşın üç adımlı kişisel görevi ve üç kamp sahnesi vardır; konuk hikâyeye bağlıdır, gönderilemez | [Yoldaşlar](/docs/gameplay/companions) |
| Adlı er | Boş yuvayı dolduran adlı asker (ilk onluk, Islık atlıları); yoldaştan farklı olarak Düşüş'te ölebilir ([K74](/docs/source/design/decisions#k74)) | [Ordu](/docs/gameplay/army) |
| Yoldaş Kartı | Parti kartı: yoldaşın portresinden 56 px yuvarlak kart (Küçük 44, Büyük 72); koyu keçe, altın çift çizgi, can bandı, üç yara baklavası, durum rozeti | [Yoldaşlar](/docs/gameplay/companions) |
| Parti şeridi | Ekranın sol kenarında dikey on kart (F1–F10); hayvanların kartı 40 px | [Yoldaşlar](/docs/gameplay/companions) |
| Ekran kenarı göstergesi | Kadraj dışındaki yoldaşın kartı ekran kenarında, onun yönünde durur; 30 m'de 56 px, 150 m'de 44 px ([K73](/docs/source/design/decisions#k73)) | [Yoldaşlar](/docs/gameplay/companions) |
| Tehdit oku | Kadraj dışındaki tehdidin ekran kenarındaki oku; kadraj dışından ilk vuruş yoktur ([K39](/docs/source/design/decisions#k39)) | [Kamera ve Kontroller](/docs/gameplay/camera-controls#kadraj-sozlesmesi-ve-ekran-kenari) |
| Onay | Yoldaşın Mete'ye bağı, 0–10; Defter'de düğümle görünür, sayı gösterilmez; eşikler 3, 6, 9 ([K72](/docs/source/design/decisions#k72)) | [Yoldaşlar](/docs/gameplay/companions) |
| Kırmızı çizgi | Yoldaşın affetmediği eylem, −3 onay; ikisi ayrılık getirir | [Yoldaşlar](/docs/gameplay/companions) |
| Kim kalsın? | On birinci katılımda açılan kart; ayrılan Ordugâh'a gider, kaybolmaz | [Yoldaşlar](/docs/gameplay/companions) |
| Ku, Karabaş | Ku Mene'nin köpeği, I. Perde'nin ilk takipçisi; Karabaş II'den Mete'nin köpeği | [Hayvanlar](/docs/world/animals), [Ku](/encyclopedia/ku) |

## Envanter ve ekonomi

| Terim | Anlamı | Sayfa |
|---|---|---|
| Heybe | Mete'nin sırtındaki kap. Yük sınırı Bilek'e bağlıdır | [Envanter ve Yük](/docs/economy/inventory-load#heybe) |
| Terki | Bineğin taşıdığı kap | [Envanter ve Yük](/docs/economy/inventory-load#terki) |
| Ham, İşlenmiş, Parça, Mamul, Bohça | Malların tek sınıflaması. Sürü bunların dışında bir sayıdır | [Malzemeler](/docs/economy/materials#tek-taksonomi) |
| Bohça | Parçaların taşıma biçimi, şantiyede açılır: Yurt Yükü, Çadır Yükü | [Malzemeler](/docs/economy/materials#tek-taksonomi) |
| Terazi | Takas ekranı. İki kefe, sayı yok: «Denk», «Eksik», «Fazla». II'den üstü kabukla verilir | [Para ve Satıcılar](/docs/economy/money-traders#terazi) |
| Takas Yeri | Boy Yurdu'nda açılan takas yeri; Hun gezgini III'te 3, IV'te 2, V'te 3 günde bir gelir ([K81](/docs/source/design/decisions#k81)) | [Para ve Satıcılar](/docs/economy/money-traders#saticilar) |
| Tezgâh | Zanaat yapısı. 11 tezgâh, 9 zanaatçı rolü | [Zanaat](/docs/economy/crafting) |
| İnce İş | Teçhizatın üstün kalitesi. Kalite yalnız teçhizatta vardır | [Zanaat](/docs/economy/crafting) |
| Köz Kabı | Babasının ateşinden alınan közü taşıyan kap; II. Perde'nin ilk görevi. Tanhu Kampı'nda Teoman'ın ocağından dolar; ozan onunla gelmez ([K79](/docs/source/design/decisions#k79), [K106](/docs/source/design/decisions#k106)) | [II. Perde: Ok Neyi Gösterirse](/docs/story/act-2) |
| Azıkçı | Ocak'ta kervan yokken onluktan iki günde bir gelip 2 öğün alan atlı ([K54](/docs/source/design/decisions#k54)) | [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans) |
| Gecelik Çadır | Bir kişilik çadır ve döşek: toplam 5 Yük, tek başına 108 sn'de kurulur; II'den açılır ([K46](/docs/source/design/decisions#k46)) | [Tek Gecelik Kamp](/docs/gameplay/overnight-camp) |
| Eski Ocak | İç haritalarda hazır ateş halkası ve çukuru, harita başına 3–5 | [Tek Gecelik Kamp](/docs/gameplay/overnight-camp#eski-ocak-ve-atlas) |
| Uyku Zarı | Açıkta uykunun riski: boş arazide ateş korur, düşman zonunda ateş ele verir ([K45](/docs/source/design/decisions#k45)) | [Tek Gecelik Kamp](/docs/gameplay/overnight-camp#acikta-uyku-uyku-zari) |

## Dünya ve yolculuk

| Terim | Anlamı | Sayfa |
|---|---|---|
| Atlas, harita | M ile açılan 75.000 km²'lik üst dünya. Üstünde yürünmez; yüklü iç haritada yakınlaşınca harita kapanır, oyun sürer ([K40](/docs/source/design/decisions#k40)) | [Harita ve Ölçek](/docs/world/map) |
| İç harita | Oynanan, elle kurulmuş yer: çoğu 1.400×1.050 m | [Harita ve Ölçek](/docs/world/map#ic-haritalar) |
| Ana kamp, Göl Obası | Menünün canlı sahnesi, Serbest Gez'in yeri: Göl Vadisi'nde rastgele bir oba, hikâyenin dışında. Tanhu Kampı ve Teoman'ın ocağı değildir ([K106](/docs/source/design/decisions#k106)) | [Bölgeler](/docs/world/regions#gol-obasi-ana-kamp) |
| Tanhu Kampı | Hikâyenin yeri: Yola Çıkış, Ev ve II'nin sinemaları; atlasta 105,2°D 46,5°K. Mete için sahnesiz konaktır, III'ten «Eski Avlu» ([K41](/docs/source/design/decisions#k41), [K106](/docs/source/design/decisions#k106)) | [Bölgeler](/docs/world/regions#tanhu-kampi) |
| Kışlak | I. Perde'nin Yüeçi vadisi, Mete'nin rehine tutulduğu yer; IV'te «Kışlak, Yaz» | [Bölgeler](/docs/world/regions#kislak-hexi-vadisi) |
| Menzil | İç harita içindeki durak: araba, Yük Bindir, ambar, dinlenme | [Yolculuk](/docs/world/travel) |
| Uzak Yol | İç haritalar arası atlas yolculuğu, 10–30 gerçek sn; II'den ilk geçişte anlatıcı tek cümle söyler ([K84](/docs/source/design/decisions#k84)) | [Yolculuk](/docs/world/travel) |
| Yol Kartı | Yolculuktan önce bedeli ve süreyi gösteren kart | [Yolculuk](/docs/world/travel) |
| Kara Boran | Yalnız Gün VI kovalamacasının hikâye fırtınası | [I. Perde: Gün Gün](/docs/story/act-1-days#gun-vi-kara-boran) |
| Donuk Kamp | Erlik'in göründüğü, kar havada donmuş sahne | [I. Perde: Gün Gün](/docs/story/act-1-days) |

## I. Perde

| Terim | Anlamı | Sayfa |
|---|---|---|
| Güven | Yüeçilerin Mete'ye güveni, 0–100. Çentik çubuğunda görünür, bölge rütbesini açar | [I. Perde: Çan](/docs/story/act-1#eksenler) |
| Kefil | Bir bölgeyi açan kişi. Çeteleyi ikiye böler, Son Gece'de yarısını bırakmazsan ceza ona kesilir | [I. Perde: Çan](/docs/story/act-1#cekirdek-dongu) |
| İş Tahtası | Günlük işlerin alındığı yer. II. Perde'de yerini Kâhya alır | [I. Perde: Çan](/docs/story/act-1#cekirdek-dongu) |
| Hüküm | Gün V'te Amaga'nın hükmü: heybe Ambar'a gider; Çığırtkan, çentik çubuğu, çizmedeki demir bıçak, zula (6 yuva) ve çetele yarımları kalır ([K38](/docs/source/design/decisions#k38)) | [I. Perde: Gün Gün](/docs/story/act-1-days#gun-v-hukum) |
| Çığırtkan | Rehinenin hızlı aracı, I. Perde'de `Q` tuşu; II'den Çubuk'un 6. yuvasına geçer ([K82](/docs/source/design/decisions#k82)) | [Kamera ve Kontroller](/docs/gameplay/camera-controls) |
| Rehine Çanı | Mete'nin sol bileğindeki tunç çan: koşunca gürler, el çanda çömelince susar | [I. Perde: Çan](/docs/story/act-1) |
| Son Gece | Kaçış gecesi. Saat ve yol kilitlidir | [I. Perde: Gün Gün](/docs/story/act-1-days#son-gece) |
| Ay Saati | Son Gece'nin saati: Düğüm'le başlar, buz saatinde biter | [Zaman ve Takvim](/docs/world/time-calendar) |
| Kara Yol | Erlik'in kara buz yolu. Üstünde görünmezsin, her saniye bir ocak söner | [I. Perde: Gün Gün](/docs/story/act-1-days) |
| Kül Borcu | Kara Yol'da söndürülen ocak kadar Erlik'e borç | [I. Perde: Gün Gün](/docs/story/act-1-days) |

## Yerleşim

| Terim | Anlamı | Sayfa |
|---|---|---|
| Tanhu | Oyuncunun unvanı; ülke «Hun Tanhuluğu», merkez «Tanhu Avlusu». «Kağan» ve «hanlık» oyuncu metninde geçmez ([K34](/docs/source/design/decisions#k34)) | [Obadan Hanlığa](/docs/settlement/encampment) |
| Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu | Yerleşimin beş kademesi: 6, 12, 25, 50, 90 hane | [Obadan Hanlığa](/docs/settlement/encampment#bes-kademe) |
| Surlu Avlu, Göçer Avlu | V. Perde'de seçilen iki yol: tarlalı ve kuleli ya da büyük sürülü | [Obadan Hanlığa](/docs/settlement/encampment#surlu-ya-da-gocer-avlu) |
| Hane | Yerleşimin temel birimi: 5 kişi | [Haneler ve Kâhya](/docs/settlement/households#hane) |
| Yüklü Hane, İsteyen Hane | Gelen hanenin iki türü: evini at ve devesinde getirip kendi kuran, barınak isteyen ([K53](/docs/source/design/decisions#k53)) | [Haneler ve Kâhya](/docs/settlement/households#hane-nasil-gelir) |
| Çekim | Günlük küçük hane gelişi, perde başına tavanlı. Hane çoğunlukla olayla gelir | [Haneler ve Kâhya](/docs/settlement/households#cekim) |
| Gönül | Hanenin bağlılığı. Esir yoktur, hanenin ekseni budur | [Haneler ve Kâhya](/docs/settlement/households#gonul) |
| Kâhya | İşleri her oyun saati başında dağıtan görevli; şantiyeyi el tavanına dek doldurur ([K80](/docs/source/design/decisions#k80)). II–IV'te Lan Hatun, 16 Kasım MÖ 203'ten Yimo | [Haneler ve Kâhya](/docs/settlement/households#isler-ve-kahya) |
| Plan Kipi | Yapı yerleştirme görünümü, `P` | [Plan Kipi](/docs/settlement/plan-mode) |
| Araba Yeri | Atölye kategorisindeki tek Araba kartının 6 × 12 m'lik iş yeri, Ağaç Atölyesi'ne ≤30 m ([K57](/docs/source/design/decisions#k57)) | [Plan Kipi](/docs/settlement/plan-mode#araba-karti) |
| Yerleşim Defteri | Yerleşimin kayıt ekranı, Defter'in II'den açılan sekmesi | [Plan Kipi](/docs/settlement/plan-mode#yerlesim-defteri) |
| Ordugâh | Ordu kampı. Yerleşimden ayrıdır, kendi ambarı vardır | [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans) |
| Ordu Payı | Yerleşik atlının öğününün yerleşimden kervanla giden %10'u | [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans#ordu-payi) |
| Akın | Yalnız dolunay penceresinde gelen küçük, seyrek, kolay def edilen baskın; toplantı günü akın yoktur ([K55](/docs/source/design/decisions#k55)) | [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans#gece-akini) |
| İş Kolu | Ordugâhtan yerleşimde çalışmaya gelen erler | [Haneler ve Kâhya](/docs/settlement/households#isler-ve-kahya) |
| Divan, Hazine | Avlunun yönetim yeri; Toy Yeri'nden açılan değerli mal kabı | [Hanlık Merkezi](/docs/settlement/court#divan) |
| Kronik | Perde arasındaki yılları kapalı hesapla işleyen adım; Akan Kronik onun görünen yüzüdür | [Hanlık Merkezi](/docs/settlement/court#kronik) |
| Kış Toplantısı, Avlu Toplantısı | Yıl başı toplantısı oynanan günde sahne açmaz, Kronik'te işlenir ([K42](/docs/source/design/decisions#k42)); Avlu Toplantısı zaferden sonra Toy Alanı'nda oynanır | [Hanlık Merkezi](/docs/settlement/court#toplantilar) |

## Yurt ve çadır

| Terim | Anlamı | Sayfa |
|---|---|---|
| Bosağa, Kerege, Tündük | Kapı çerçevesi (ilk dikilen parça, yurdun yönünü belirler); makaslı çıta duvar; tepedeki taç halkası | [Yurtlar ve Çadırlar](/docs/buildings/yurts#parcalar-ve-kurulum-sirasi) |
| Bakan, Uuk, Çiy | Tündüğü yukarı iten çatal sırık; çatı sırıkları; keregenin dışına sarılan kamış hasır | [Yurtlar ve Çadırlar](/docs/buildings/yurts#parcalar-ve-kurulum-sirasi) |
| Tuurduk, Üzük, Kolan | Duvar keçesi, çatı keçesi ve keçeyi tutan halatlar | [Yurtlar ve Çadırlar](/docs/buildings/yurts#parcalar-ve-kurulum-sirasi) |
| Küçük Yurt | ×0,7, 4 kanat, taban 24 dk, en çok 6 el ([K50](/docs/source/design/decisions#k50), [K51](/docs/source/design/decisions#k51)) | [Yurtlar ve Çadırlar](/docs/buildings/yurts#boylar) |
| Hane Yurdu | ×1, 6 kanat, taban 60 dk, en çok 8 el | [Yurtlar ve Çadırlar](/docs/buildings/yurts#boylar) |
| Otağ | ×1,4, 8 kanat, ak keçe, taban 150 dk; 12 el alır, katsayı 8'de durur. Tanhu Otağı gündüz Divan, toy gecesi Şölen düzenindedir | [Yurtlar ve Çadırlar](/docs/buildings/yurts#boylar) |
| Millet, Düzen | Yurdun dış görünüşü millete göredir (Hun, Yüeçi, Usun, Tunghu, Dingling, Loufan, Baiyang; Çiang ve Han çadırı; Saka araba evi), iç eşyası düzene göre; sayılar yalnız boydan çıkar | [Yurtlar ve Çadırlar](/docs/buildings/yurts#milletler) |
| Çadır (`tent`) | Yurttan ayrı, küçük yapı; notundaki «çadır» yurt diye okundu ([K34](/docs/source/design/decisions#k34)) | [Yurtlar ve Çadırlar](/docs/buildings/yurts#cadir) |
| camp3 | Ana kampta oyuncunun gözü önünde kurulan üçüncü yurt: ilk duman yardımsız 05:48, bütün yardımla 03:43 ([K83](/docs/source/design/decisions#k83)) | [İnşa ve Emek](/docs/buildings/construction-labour#ucuncu-yurt-camp3) |
| Aile bekler | camp3 gecesinde aile 23:00'e dek ateş başındadır; aşama ≥4 ise ilk dumana dek bekler, 05:00'te Ana közü getirir | [İnşa ve Emek](/docs/buildings/construction-labour#ucuncu-yurt-camp3) |

```varlik
yurt_hun_small, yurt, otag_hun, tent_night, kopuz, cowrie
```

## Site ve belgeler

| Terim | Anlamı | Sayfa |
|---|---|---|
| K1–K105 | Kararlar. Çelişkide bunlar kazanır; belge sırası decisions.md > d2/core.md > alan belgeleri > godot.md ([K31](/docs/source/design/decisions#k31)) | [decisions.md](/docs/source/design/decisions) |
| #1–#67, KB 1–13, E1–E6 | Bu turun 67 cevabı, eski Karar Bekleyenler'in 13 maddesi ve ek istekler | [Araştırma ve Tasarım Turu](/docs/general/design-round) |
| Faz, madde | Yol Haritası'nın düzeni Perde > Faz > Madde; faz kimliği `act-1-p4` gibi. g0–g9 godot.md'nin uygulama sırasıdır | [Yol Haritası](/roadmap) |
| Doğrulanacak | Soru olmayan ölçüm ya da sınama işi; Yol Haritası'nda maddedir | [Yol Haritası](/roadmap) |
| Tanhu 1 | Eski Godot oyunu; yalnız ilham, adı ve kadrosu alınmaz ([K30](/docs/source/design/decisions#k30), [K32](/docs/source/design/decisions#k32)) | [Genel Bakış](/docs/general/overview) |
| Prototip | Three.js prototipi: yalnız tasarım ve ölçüm kaynağı; orada denenen şey «prototipte denendi» diye anılır ([K29](/docs/source/design/decisions#k29)) | [Mimari Özeti](/docs/development/architecture) |
| d2, d3 | İkinci ve üçüncü tasarım turu | [d2/core.md](/docs/source/design/d2/core), [Araştırma ve Tasarım Turu](/docs/general/design-round) |
| Econ-sim | Ekonomi denge benzetimi | [Ekonomi Dengesi](/docs/economy/balance) |
| Destan Kitabı | Oyunun kitap arayüzü: Destan, Gök ve Yer, Kişiler, Taşlar; kişi ve tanrı sayfaları ansiklopedi düzenindedir ([K85](/docs/source/design/decisions#k85)) | [Arayüz ve Menüler](/docs/presentation/ui-menus) |
| Ansiklopedi | Mitolojinin ve kişilerin etkileşimli kitabı: 149 kayıt, altı bölüm | [Ansiklopedi](/encyclopedia) |
| Art, profil, T-poz | Ansiklopedideki üç görsel: önce tam boy art, profil ve T-poz art'tan türer; T-poz ileride Meshy'nin girdisi olur | [Ansiklopedi](/encyclopedia) |
| Varlık | Oyunun bir görseli ya da modeli; 21 tür tablosunda, 3B gereği, üretim yolu ve Meshy kredisiyle ([K66](/docs/source/design/decisions#k66)) | [Varlıklar](/assets) |
