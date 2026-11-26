---
title: 'V. Perde: Dört Renk'
order: 54
status: tasarim
summary: "20 Kasım–1 Aralık MÖ 201, kış: Mete güçlüyü saklar, zayıfı gösterir, yalandan kaçar, Han İmparatoru Liu Bang'ı Baideng tepesinde dört renk atla yedi gün çevirir ve halkanın bir köşesini açar; Divan'da avlunun yolu bir kez seçilir: Surlu ya da Göçer."
sources:
  - docs/design/story.md
  - docs/design/decisions.md
  - docs/design/companions.md
  - docs/design/settlement.md
  - docs/design/army.md
  - docs/design/progression.md
  - docs/design/fauna.md
  - docs/design/economy.md
  - docs/design/travel.md
  - docs/design/weather.md
  - docs/design/audio.md
  - docs/design/godot.md
  - docs/design/d3/oyun-durumu.md
  - docs/research/mete-tarih.md
  - docs/research/mitoloji.md
---

## Özet

V. Perde «Dört Renk / Four Colours» 20 Kasım–1 Aralık MÖ 201'de, kışın geçer (`dayN` 4.314–4.325). [Mete](/encyclopedia/mete) 33 yaşındadır. Liu Bang'ın kralı [Han Xin](/encyclopedia/han-xin) (韓王信) Mayi'de teslim olmuş, Hun avlusuna sığınmıştır; [Liu Bang](/encyclopedia/liu-bang) ordusunun başında kuzeye gelir. Mete güçlüyü saklar, zayıfı gösterir, yalandan kaçar, Han'ı Baideng tepesine çeker ve dört renk atla çevirir. Halka yedi gün tutulur, sonra bir köşesi açılır. Aynı perdede yerleşimin son kademesi açılır: Divan'da avlunun yolu bir kez seçilir, Surlu ya da Göçer.

**Ad.** «Dört Renk» [K32](/docs/source/design/decisions#k32)'dir: Baideng'de Han ordusunu dört renk at çevirir (Shiji 110).

**Boyut.** 12 ana görev (ortalama taban 206 XP, `xpScale` 4,4: 10.877 XP), 15 yan görev (4.719 XP), ≈12 XP'li keşif durağı, iki yeni iç harita (Mayi, Baideng); seviye 15–17. Perdenin bütün XP'si 18.000'dir. Oynanan 12 gündür; K25'in 12 günü yalnız tasarım ölçüsüdür, sayaç yoktur ([K42](/docs/source/design/decisions#k42), [K43](/docs/source/design/decisions#k43)).

> [!NOT]
> «Yerleşim yeri sistemimiz olacak, obamızı büyütüp kağanlığımızın hanlığımızın merkezi haline getirebileceğiz»

Tasarım bu yöndedir ([K23](/docs/source/design/decisions#k23), [K34](/docs/source/design/decisions#k34)): yerleşim beş kademede büyür: Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu. Son kademe bu perdede açılır ve oyuncuya «Tanhu Avlusu / The Tanhu's Court» diye yazılır; «kağan» ve «hanlık» oyuncu metninde geçmez, ülke «Hun Tanhuluğu»dur. Avlu bir kez, kalıcı olarak, Surlu ya da Göçer yolunu seçer.

## Perdenin sorusu

- **Soru.** Kuşatan neyi bırakır?
- **Fiil.** Kuşatmak ve bırakmak.
- **Töre.** Mete II'de ve III'te töreyi bozmuştu, burada töreye döner: kuşatma ay dolarken kurulur, ay eksilirken kalkar (月盛壯則攻戰，月虧則退兵).
- **Yankı.** Sürüyü Gizle I'in Gün III'ünün aynasıdır: orada elçi Eskam'a kampı Mete gezdirmişti, burada saklayan odur. Bakış'tan halka bir yurdun keregesine benzer.

## Tarih ve takvim

Mete 33 yaşındadır. Ay 20 Kasım'da %42 büyür, 28 Kasım dolunaydır, 1 Aralık %91 eksilir. Atlas ve Destan «Baideng, Kasım MÖ 201» yazar: kuşatma Gaozu'nun 7. yılının 10. ayına düşer; geleneksel «MÖ 200» Destan notudur ([K33](/docs/source/design/decisions#k33)).

| Tarih (MÖ 201) | `dayN` | Olay |
|---|---|---|
| 30 Ekim | 4.293 | Han Xin Mayi'de teslim olur (IV → V Kroniği) |
| 20 Kasım | 4.314 | Perde açılır: Han Xin Hun avlusuna sığınır |
| 20–21 Kasım | 4.314–4.315 | Divan: Sur mu, Teker mi |
| 21–24 Kasım | 4.315–4.318 | Kollar: sürü gizlenir, on Han elçisi gelir, akın Gouzhu'yu aşar, atlar renge göre ayrılır; 24 Kasım'da yalandan kaçış |
| 25 Kasım | 4.319 | Baideng çevrilir |
| 28 Kasım | 4.322 | Dolunay: dört renk birden görünür |
| 30 Kasım | 4.324 | Chen Ping'in armağanı Yimo'ya gelir |
| 1 Aralık | 4.325 | Bir köşe açılır: son görev |

- **Oynanan günler.** 12: 20 Kasım–1 Aralık. Kollar erken biterse son görevin kapısı saati tablodaki güne atlatır; oyuncu o günü geçtiyse sahne günü değil yılı ve mevsimi söyler.
- **Hava.** Baideng'in kar kilidi 25 Kasım–1 Aralık'ı tutar: yoğun kar, sonra tipi; Han yorgunluğu ×2, Han yayası karda ×0,6. Kaynak «kış geldi, büyük soğuk ve kar»dır (會冬大寒雨雪); yalnız kar oynanır, soğuk ve parmak donması oynanmaz ([K1](/docs/source/design/decisions#k1)). Seçmeli yada taşı: kam taşla kar ister, kilidi 1 saat erkene alır ([weather.md §6.4](/docs/source/design/weather#6-4-sonraki-perde-kancalari)).

## Açılış

- **IV → V Kroniği.** 22 Eylül 203'ten 20 Kasım 201'e 789 gün, ≈43 sn akar: Yan ve Dai'ye akın; Lan Hatun ölür, Yimo Kâhya olur; Han kurulur; kuzeyin beş halkı (Hunyü, Çüşe, Dingling, Gekun, Şinli) boyun eğer; Han Xin Mayi'de teslim olur. Kronik Kararı Lan Hatun'un yoğudur. Yerleşim 45 haneyle açılır ([IV. Perde: Borç](/docs/story/act-4)).
- **Dönüş.** Toy Yeri kışa girmiş, ordugâh dağılmıştır: Gobi'de kış otlağı yoktur, Islık Alanı'nda %10 bekçi kalır ([K23](/docs/source/design/decisions#k23)). [Yimo](/encyclopedia/yimo) Kâhya'dır. Han Xin ve komutanları ([Wang Huang](/encyclopedia/wang-huang), [Zhao Li](/encyclopedia/zhao-li), [Manqiu Chen](/encyclopedia/manqiu-chen)) avluya sığınır. Han Xin: «Han beni kesecekti. Sen kesmeyecek misin?» / «Han would have cut me down. Will you not?»

## Ana görev zinciri

Kalıp 2 + 3 × 2 + 4'tür: iki açılış görevi, aynı anda açılan üç kol ve dört kapanış görevi. Kol A Sürüyü Gizle ve On Elçi'dir; Kol B Gouzhu ve Yalandan Kaçış; Kol C Dört Yel ve Yol Laneti. Görev puanı veren iki görev Yalandan Kaçış ve Yedi Gün'dür.

| # | Görev | Gün | Yer | Ne olur |
|---|---|---|---|---|
| 1 | Dönüş / The Return | 20 Kasım | Tanhu Ordusu | Kışa girmiş Toy Yeri; Han Xin ve komutanları sığınır |
| 2 | Sur mu, Teker mi / Wall or Wheel | 20–21 Kasım | Tanhu Otağı, Divan | Han Xin'in adamı kuyu, sur ve tahıl kulesi önerir; Hun beyi: «Hun suru tutamaz.» / «The Hun cannot hold a wall.» (胡人不能守城). Seçim bir kez yapılır, geri alınmaz |
| 3 | Sürüyü Gizle / Hide the Herd (Kol A) | 21–22 Kasım | Mayi çevresi | Ters gizlilik ([K44](/docs/source/design/decisions#k44)): semiz at ve yiğit vadilere saklanır, yalnız yaşlı ve zayıf gösterilir (匈奴匿其壯士肥牛馬，但見老弱及羸畜) |
| 4 | On Elçi / Ten Envoys | 22–23 Kasım | Mayi otlağı | On Han elçisi geçer, «vurulur» der. [Liu Jing](/encyclopedia/liu-jing) boş otlağa uzun bakar: «Bu kadar zayıf olamazlar.» / «They cannot be this weak.» (此必欲見短，伏奇兵以爭利). Sonuç «zayıf gösterildi» bayrağına yazılır |
| 5 | Gouzhu / Gouzhu (Kol B) | 21–23 Kasım | Atlas, Jinyang önü | Akın Gouzhu'yu aşar, Jinyang önüne iner (南踰句注，攻太原，至晉陽下); kar ve donduran yağmur |
| 6 | Yalandan Kaçış / Feigned Flight | 24 Kasım | Pingcheng yolu | Mete yalandan kaçar, Han kuzeye çekilir (詳敗走，誘漢兵). I'de Farnak'ın dersini gördüyse yere ipucu düşer |
| 7 | Dört Yel / Four Winds (Kol C) | 22–24 Kasım | Sefer ordugâhı | Atlar renge göre ayrılır: batı ak, doğu boz-mavi, kuzey kara, güney al (其西方盡白馬…南方盡騂馬); Seyis [Şulü](/encyclopedia/shulu) sayar |
| 8 | Yol Laneti / The Road Curse | 23–24 Kasım | Han yolunun kuyuları | Kam [Nangçi](/encyclopedia/nangchi) kuyu başlarına koyun gömer; tanığı sonraki çağdandır. Yada taşıyla kar kilidi. Dinle ya da Sustur: perdenin Kamın Alameti; lanet Han'ın moralini 5 düşürür |
| 9 | Baideng / Baideng | 25 Kasım | Baideng | Liu Bang piyadesinden önce Pingcheng'e varır; seçkin atlı salınır, Baideng çevrilir (縱精兵四十萬騎圍高帝於白登) |
| 10 | Yedi Gün / Seven Days | 25 Kasım–1 Aralık | Baideng | Halka tutulur, içerisi ve dışarısı birbirine yardım edemez (中外不得相救餉); 28 Kasım dolunayında dört renk birden görünür |
| 11 | Hatun / The Hatun | 30 Kasım | Yimo'nun yurdu | [Chen Ping](/encyclopedia/chen-ping)'in gizli armağanı Yimo'ya gelir (閒厚遺閼氏; 其計祕，世莫得聞). Yimo: «İki hükümdar birbirini sıkıştırmaz. Han toprağında oturamazsın.» / «Two rulers do not corner each other. You cannot live on Han land.» (兩主不相困). III'te Yimo'nun ocağı yandıysa ikinci cümle «Han kralının da bir ocağı var.» / «The Han king has a hearth too.» olur (且漢王亦有神) |
| 12 | Bir Köşe / One Corner | 1 Aralık | Baideng | Son görev |

## Son görev: Bir Köşe

- **Açılış.** Wang Huang ile Zhao Li sözleştikleri gün gelmez (黃、利兵又不來，疑其與漢有謀); Mete hatunun sözünü de alır (亦取閼氏之言); halkanın bir köşesi açılır (乃解圍之一角). Köşe her dalda açılır: tarih korunur, seçim anlamı ve bedeli değiştirir.
- **Oyuncunun iki seçimi.** Hangi renk çekilir: batı, doğu, kuzey ya da güney; o kanadın başı ganimetini yitirir, sadakati −5. Neden çekilir: Yimo'nun sözü (Kut +1), iki komutanın gelmeyişi (Korku +1) ya da Han'ın tanrısı (eksen değiştirmez).
- **Çıkış.** Çevreleyen dron seçilen yandan açılır, Han o yandan çıkar; erleri yaylarını gerili, oklarını dışa çevirmiş yürür (持滿傅矢外鄉). Mete atlılarını çeker (冒頓遂引兵而去); dört renk karda tek sürü olur. Perde kartı gelir.
- **Beyaz At Antı ([K35](/docs/source/design/decisions#k35)).** V'in iki yerinde görünür: Kardeşlik Antı becerisinin sahnesi (yorgun düşmanla çatışma beyaz at, kılıç ve altın kaşıkla biter; Kut +1) ve V → VI Kroniği'nin barış kartı. Oyuncunun Liu Bang'a verdiği bir ant yoktur.
- **Sonra.** Dünya açık kalır, takvim akar. Serbest Dolaşım'da 26–29 Aralık ay penceresi işler: Baideng'den sonra akın gücü 8'dir, yerleşime en çok 1 akın gelir ([K55](/docs/source/design/decisions#k55)). Berik bu dönemde kendi yurdunu kurar (Yoldaşlar).

## Yan görev aileleri

Beş aile etkindir: Elçi, Ordu, Hane, Töre, Av. Yol ailesi dinlenir, çünkü kış yolları kapalıdır. Konukların görevleri Elçi ailesindedir.

| Aile | Görevler |
|---|---|
| Elçi | Kralın Kuşkusu / The King's Doubt (Han Xin'in kuşkusu); İki Komutan / Two Generals (Wang Huang ve Zhao Li gelme sözü verir); Arbalet / The Crossbow (ele geçen Han arbaleti ve oku, [K49](/docs/source/design/decisions#k49)) |
| Ordu | Yedek Dizisi / The Remount String (atlı başına 0,5 at); Sadak / The Quivers (Silahlık'tan kış kervanı); Dağılanlar / The Scattered (yalandan kaçışta yolunu yitiren onluklar) |
| Hane | Sığınanlar / The Defectors (Han Xin'in haneleri, kerpiç; Surlu yolda Gönül +10); Kış Ambarı / The Winter Store; Avlu Toplantısı / The Court Gathering (Baideng'den sonra, takvimsiz; 8–12 hane; sonraki perdeye sürebilir) |
| Töre | Donanlar / The Frozen (karda kalan Han ölüleri: göm ya da bırak); Han'ın Tanrıları / The Han Gods (ele geçen sunak eşyası: geri gönder ya da Otağ'a koy); Yolda Doğan / Born on the Road (Han Xin'in hanesinde bir oğul doğar, adı yerinden gelir: [Tuidang](/encyclopedia/tuidang); Hun töresi mi, Han töresi mi) |
| Av | Kartal Yuvası / The Eagle's Nest (kartal, Bilek ≥5); Karda Tavşan / Hares in the Snow; Domuz / The Boar (Surlu yolda kerpiç evlerin domuzu, Göçer yolda yaban domuzu) |

## Seçimler ve sonuçları

| Seçim | Nerede | Seçenekler ve sonuç |
|---|---|---|
| Avlunun yolu | Sur mu, Teker mi | Surlu ya da Göçer, geri alınmaz; Sonsöz «Avlusu surluydu.» ya da «Avlusu tekerlekteydi.» diye okur |
| Zayıf görünmek | Sürüyü Gizle, On Elçi | Üç gözcü güçlü birliği ve semiz sürüyü görmezse «zayıf gösterildi» yazılır |
| Kamın Alameti | Yol Laneti | Dinle ya da Sustur; Sustur Korku +1 yazar |
| Köşe ve nedeni | Bir Köşe | Yukarıda |
| Donanlar | Töre | Göm ya da bırak |
| Han'ın tanrıları | Töre | Geri gönder ya da Otağ'a koy |
| Tuidang'ın töresi | Yolda Doğan | Hun töresi ya da Han töresi (Han töresinde Dangyu'nun onayı −0,5, Zang Yan'ınki +0,5) |
| Kim kalsın? | On birinci aday | Biri ordugâhta bekler; konuk ve zorunlu kişi seçilemez |
| Komutanların akın payı | V → VI Kroniği | «Al»: Hazine artar, Korku +1; «Alma»: Kut +1; akın her dalda olur |

**Önceki perdelerin okunuşu.** I'de Eskam'a gösterilenler ve Farnak'ın yalandan kaçışını görmüş olmak burada okunur. II'de Eskam kaldıysa elçiye ne gösterileceğini bilir: «Elçi görmek istediğini görür.» / «An envoy sees what he wants to see.» III'te Yimo'nun ocağının yanıp yanmadığı Hatun'daki cümleyi değiştirir.

## Tanhu Avlusu: Surlu ya da Göçer

Beşinci kademe ≥45 hane, Hazine, ≥1 Kuyu, ortalama Gönül ≥55 ve yol seçimiyle açılır; hane tavanı 90, Çekim tabanı günde 1,2 hanedir. Öneriyi Han Xin'in adamı söyler. Söz Tanhu'ya öğüt veren Wei Lü'nündür (Hanshu 94A, MÖ 85–68), Mete'den bir buçuk kuşak sonradır; V'e konması tasarım tercihidir ([settlement.md §4.3](/docs/source/design/settlement#4-3-v-kademe-yolu)).

| | Surlu Avlu / Walled Court | Göçer Avlu / Moving Court |
|---|---|---|
| Kaynak | 穿井築城，治樓以藏穀; Ivolga kazısı | 毋城郭常處耕田之業; 胡人不能守城 |
| Açar | Sur ve hendek, sur kapısı, yarı gömük ev, darı tarlası, Tahıl Kulesi | Keçe Göç Arabası; ek at hattı ve ağıl |
| Baskın | Akının başarı payı ×0,5; Haziran–Eylül arası başarılı akın güz ürününün %30'unu çiğner | Sürü kaybı ×0,6, ambar kaybı ×1 |
| Kış yiyeceği | Tarla başına mevsimde 500 darı (≈250 öğün); ekim 10–31 Mayıs, biçim 1–20 Eylül, işi Kâhya yapar. Tahıl Kulesi yaz ve güz artığının %50'sini kışa saklar (öteki yerlerde %35). V'in kışı tarlasızdır: ≈%91; VI'dan tarla ve kuleyle ≈%102 ([K54](/docs/source/design/decisions#k54)) | Tarla yoktur, darı pazardan gelir. Sürü tavanı ×1,2: tabanda ≈%90, tavanda ≈%113 |
| Zanaat | Kalıcı atölye ×1,1 | Yok |
| Ordu | Yok | Ordugâh ambarına günlük pay ×1,1 |
| Gönül | Sığınan haneler +10 | Bozkır haneleri +5 |
| Bedel | Yapı emeği 91,1 İG (Göçer'in ≈×1,7'si); odun ≈×1,4: sur parçası 16 odun, 40 parça 640; taş ve kil; fazladan 480 odun kereste kervanıyla gelir ([K52](/docs/source/design/decisions#k52)) | Keçe ≈×1,6, ip ≈×1,5, demir ≈×2; yurt ve araba bakımı |
| Kademe günü (hedef 4–12) | 8,1 | 7,8 |

Seçim kademe adını değiştirmez. İki yolun günü bilerek yakın tutulur: seçim hızla değil malla yapılır.

```varlik
rampart, rampart_gate, pit_house, field, granary_tower, wagon_felt
tent_han, han_mu, han_ev, yurt_dingling, otag_dingling
```

## Açılan sistemler

| Sistem | V'teki yüzü | Sayfa |
|---|---|---|
| Kuşatma | Ordu `nominal` 300.000'i aşar (控弦之士三十餘萬), ıslığa uyan 30.000'dir; Baideng'i çeviren 400.000 atlı (縱精兵四十萬騎) sahnede ≤10.000 kartla gösterilir, her kart 40 atlıdır ([K47](/docs/source/design/decisions#k47)) | [Ordu](/docs/gameplay/army) |
| Ters gizlilik | Han elçileri gelince güçlü birlik ve semiz sürü saklanır; 3 gözcü, koni 60°, 60 m; bütün partiye Gizlen kendiliğinden verilir | [Dövüş](/docs/gameplay/combat) |
| Hane | 45 → ≈80: Han Xin'in sığınanları 6–12, Avlu Toplantısı dalgası 8–12, yenilenlerin seçimi 4–8 (Pingcheng dışında kalan Han erleri ve sınır köylüleri, Han konutuyla, [K51](/docs/source/design/decisions#k51)), Çekim ≤8. Sığınan hane barınak ister: Surlu yolda ona yarı gömük ev kurulabilir ([K53](/docs/source/design/decisions#k53)) | [Haneler ve Kâhya](/docs/settlement/households) |
| Ordugâh | Kışın dağınık: Islık Alanı'nda %10 bekçi; sefer ordusu sefer ordugâhındadır; yerleşik Tümen Ordugâhı 600, toplantıda 3.000–10.000 | [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans) |
| Akın | Han sınır birliği, güç 16; perdenin oynanan günlerinde akın yoktur, 27–29 Kasım penceresi kuşatmaya düşer | [Hanlık Merkezi](/docs/settlement/court) |
| Para ve ganimet | Han sikkesi tartılır, bir dizi 3 kabuktur: «Yaprak gibi.» / «Light as a leaf.» ([K48](/docs/source/design/decisions#k48)). Han ganimeti demir hurda, tahıl arabası, sığır ve arbalet okudur; arbalet oku Hun yayıyla atılmaz, 8 ok eritilince 1 tunç hurda olur | [Para ve Satıcılar](/docs/economy/money-traders) |
| Hayvanlar | Kartal: yuvadan genç bir dişi gelir, Bilek ≥5 ister, 600 m yarıçapta keşfe çıkar, tırısta salınmaz. Binek ve yük katırı (35 Yük); Surlu yolun domuzu. Kuş geldiği perdeden sonra salınabilir: Kut +1 ([K65](/docs/source/design/decisions#k65)) | [Hayvanlar](/docs/world/animals) |
| «Kim kalsın?» | On birinci katılımda kart açılır, ayrılan Ordugâh'a gider | [Yoldaşlar](/docs/gameplay/companions) |
| Beceriler | 11 beceri açılır; stat tavanı 11; perde sonunda birikimli beceri puanı 26 | [Seviye ve Gelişim](/docs/gameplay/progression) |

```varlik
crowd_han_soldier, crowd_han_crossbow, crowd_han_cavalry, crowd_han_envoy, crowd_han_civilian
han_crossbow, bolt, han_sword, mule, pig, eagle, status_badge_guest
skill_great_stores, skill_steppe_ghost, skill_thousand_li, skill_eagle_shooter, skill_last_tooth, skill_champion_ground
skill_brother_oath, skill_land_root, skill_feign_weakness, skill_lead_banner, skill_four_winds
```

## Yoldaşlar

Açık çekirdek en çok 9 ve 2 konuktur: on yuva ilk kez dolar. 11 adaydan biri ordugâhta bekler («Kim kalsın? / Who stays?»); konuk seçilemez. Kartal yuva tutmaz ([K70](/docs/source/design/decisions#k70), [K71](/docs/source/design/decisions#k71)). Kişisel görev adımı onay verir, XP vermez ([K88](/docs/source/design/decisions#k88)). Sistemin bütünü [Yoldaşlar](/docs/gameplay/companions) sayfasındadır.

| Yoldaş | Katılış ya da ayrılış | V'teki adım |
|---|---|---|
| Han Xin, 45, konuk komutan | Dönüş'te konuk olarak gelir; ana zincir boyunca partidedir, gönderilemez; 1 Aralık 201'den sonra kendi ordusuna döner | Kralın Kuşkusu (Elçi ailesi). 13 Mart 196'da ölür (Kronik) |
| Wang Huang, 50, konuk tüccar, arbalet | Dönüş'te konuk; İki Komutan biter bitmez ordusunu getirmeye gider, Bir Köşe'de gelmez | İki Komutan (Elçi ailesi). 196'da adamları onu ödül için diri teslim eder (Kronik) |
| [Zang Yan](/encyclopedia/zang-yan), 27, danışman, Han kılıcı | Sur mu, Teker mi'de katılır (onay 3) | Yan'ın Ölüsü, 1: Han Xin'le çatışma. Han Xin 202'de Liu Bang'ın kralıydı, Zang Yan Liu Bang'ın yendiği Yan kralının oğludur |
| [Kunduz](/encyclopedia/kunduz), 19, Dingling avcısı | Karda Tavşan'da katılır (onay 4); kuzeyin beş halkının armağan kafilesiyle gelmiştir | Uzun Ezgi, 1: Karda Tavşan biter, gece ateşinde uzun ezgiyi söyler; o gece ateş başında dinlenmek dakikada +1 moral daha verir (onay +1) |
| [Dangyu](/encyclopedia/dangyu) | IV'ten | Al Karısı, 2: Yolda Doğan'da Tuidang doğar; Dangyu onu Hun töresiyle karşılar |
| [Loufan okçusu](/encyclopedia/loufan-archer) | IV'ten | Bakış, 3 (son): Yedi Gün'de halkayı tutarken Han sancağını görür; atarsa donması kalkar (+2), atmazsa adım «kaçtı» olur |
| [Kozı](/encyclopedia/kozi) | IV'ten; V sonunda ırmak otlağına döner, partiden çıkar | Meng Tian'ın Kazıkları, 3 (son): Dört Yel'de atları Şulü'yle renge göre ayırır (+2). VI-c'de Ordos'ta yeniden alınabilir |
| [Berik](/encyclopedia/berik) | II ya da IV'ten | Görmediği Ev, 3 (son): V'in Serbest Dolaşım'ında kendi Hane Yurdu'nu kurar (8 elde 8,0 dk, [K50](/docs/source/design/decisions#k50)). Sarva geldiyse hane başı olur, partiden çıkar; gelmediyse baş gözcü kalır |

- **Zorunlu ve yasak.** On Elçi'de Han Xin, Zang Yan ve Wang Huang yasaktır: Han elçisi onları görmemeli, sahnenin başında kendi yurtlarına giderler. Yedi Gün'de Han Xin zorunludur, Wang Huang gitmiştir. Hatun'da bütün parti yasaktır: Yimo'nun yurdunda Mete yalnızdır. Sürüyü Gizle ters gizliliktir.
- **İkililer.** Han Xin – Zang Yan «Kimin Kralı / Whose King» (çatışma); [Mijia](/encyclopedia/mijia) – Kunduz «İlk İz / First Track» (dostça av yarışı, kazanan +0,5); Dangyu – Kunduz (davul ve ezgi, dostluk).

```varlik
portrait_han_xin, portrait_wang_huang, portrait_zang_yan, portrait_kunduz, portrait_dangyu, portrait_loufan_archer, portrait_kozi, portrait_berik
```

## Kişiler

| Kişi | Kim | V'te |
|---|---|---|
| Mete, 33 | Tanhu | Güçlüyü saklar, yalandan kaçar, Han'ı yedi gün çevirir, bir köşeyi açar |
| Yimo | Mete'nin hatunu, Kâhya | Baideng'in hatunu: Chen Ping'in armağanını alır, «İki hükümdar birbirini sıkıştırmaz.» der |
| Han Xin | Teslim olan Han kralı (general Han Xin değil) | Avluya sığınır; yorgun, kuşkulu |
| Wang Huang, Zhao Li, Manqiu Chen | Han Xin'in komutanları | Zhao Li Wang Huang'la sözleşir; ikisi gelmez |
| Liu Bang | Han'ın kurucusu | Baideng'de kuşatılır; kaba, gülen, halk ağzı |
| Chen Ping | Hatuna gizli armağanın sahibi | Yumuşak, hesaplı |
| Liu Jing | Gizlenen sürüyü gören Han beyi | Savaşa karşı çıkar, zincire vurulur; heqin'i önerir |
| Nangçi | Sefer kamı | Yol Laneti; davul altında sert |
| Şulü | Seyis | Dört rengi sayar |
| [Kuzeyin beş halkı](/encyclopedia/northern-peoples) | Hunyü, Çüşe, Dingling, Gekun, Şinli | 15 Haziran 202'de boyun eğdiler; armağan kafilesi Kunduz'u getirir |
| Tuidang | Han Xin'in oğlu | Bu perdede doğar; VI-c'de yoldaştır |
| [Çocuk](/encyclopedia/child), ≈15–16 | Mete'nin ocağının genç ozanı | «Dört renk at bir yurdun keregesi oldu, ortada Han'ın ocağı tütmez oldu.» / «Four colours of horse became the lattice of a yurt, and in its middle the Han hearth gave no smoke.» |

```varlik
liu_bang, chen_ping, liu_jing, zhao_li, manqiu_chen, nangchi, yimo
portrait_liu_bang, portrait_chen_ping, portrait_liu_jing, portrait_zhao_li, portrait_manqiu_chen, portrait_nangchi, portrait_shulu
```

## Mekânlar

| Yer | Ne | Görevler |
|---|---|---|
| Tanhu Ordusu (`tanhu_ordu`) | Kışa girmiş Toy Yeri; Tanhu Otağı ve Divan; Yimo'nun yurdu | 1, 2, 11 |
| Mayi (`mayi`) | Mayi ve çevresi; sefer ordugâhı | 3, 4, 7 |
| Atlas bacağı | Gouzhu geçidi ve Jinyang akını | 5 |
| Pingcheng yolu, Han yolunun kuyuları | Yalandan kaçış ve kamın laneti | 6, 8 |
| Baideng (`baideng`) | Baideng tepesi ve Pingcheng ovası; kuşatmanın dışında bir kamp yeri | 9, 10, 12 |

Uzak Yollar'ın ilk geçişinde anlatıcı tek cümle söyler, Türkçesi altyazıdır ([K84](/docs/source/design/decisions#k84)); satırlar taslaktır:

- Mayi yolu: «South through the Yin passes, to the Han frontier town of Mayi.» / «Yin geçitlerinden güneye, Han sınırının kenti Mayi'ye.»
- Baideng yolu: «From Mayi to Pingcheng, and the hill they call Baideng.» / «Mayi'den Pingçeng'e, Baideng denen tepeye.»

## Mit, ozan ve müzik

- **Mitoloji anı.** «Han kralının da tanrısı var» (且漢王亦有神); Han sunakları ve Göğün Oğlu elçi dilindedir. Dört renk dört yöndür; Bakış'tan halka bir yurdun keregesine benzer. Kut ≥10 iken kam Gök'e Tanhu'dan yakın konuşamaz; kam sahnelerinde kıl kobuz elde görünmez, yalnız sesi duyulur ([K35](/docs/source/design/decisions#k35)).
- **Ocağın ozanı ([K79](/docs/source/design/decisions#k79)).** Mete'nin ocağında Çocuk genç ozan olarak çalar; yukarıdaki dize onundur.
- **Perde rengi ([K59](/docs/source/design/decisions#k59)).** Han çanları ve davulları uzaktadır, Hun tarafı az ses verir. Skor çevreleyen stereo drondur; nabız 44, E Frigyen; motif tek tek notalara dağılır; kopuz ezgisi yoktur. İmza Bir Köşe'dedir: dron bir yandan açılır, o yandan çıkılır (乃解圍之一角). Godot'da iki yanlı dron solda ve sağda ayrı basılmış iki katmandır, bir yanın sesi açılınca o yan açılır ([audio.md §3](/docs/source/design/audio#3-muzik-durumlari)).

## Akan Kronik'e geçiş

| Geçiş | Gün, süre | Olaylar | Anlatıcının satırı | Kronik Kararı |
|---|---|---|---|---|
| V → VI | 1 Aralık 201 → 1 Haziran 198; 912 gün, 50 sn | Liu Jing zincirden çözülür, «vurulur» diyen on elçi kesilir (SJ 99); Han'da Pingcheng türküsü söylenir (平城之下亦誠苦！七日不食，不能彀弩, HS 94A); Han Xin'in komutanları sözü bozup Dai ve Yunzhong'a akar; 197 güzü Chen Xi ayaklanır; 6 Aralık 199 heqin: prenses, her yıl ipek, kumaş, şarap ve tahıl, iki hükümdar kardeş sayılır (約爲昆弟以和親); barış kartı Beyaz At kalıbıyladır; Dulongçi ölür | «Han bir prenses, ipek, şarap ve tahıl gönderdi. İki hükümdar kardeş sayıldı.» / «Han sent a princess, silk, wine and grain. The two rulers were counted as brothers.» | Han Xin'in komutanlarının akın payı (yukarıda); VI 80 haneyle açılır |

Süre `T = clamp(gün / 91,25 × 5 sn, 30, 90)` formülüdür; `E` basılı ×4 hızlandırır, Esc atlar. «Kronik'e bırak» perde kartında, duraklatma kitabında ve Mete'nin her ocağında durur; hedef sonraki perdenin başı ya da bugünden 30 gün sonrasıdır, hangisi daha ilerideyse. Akan Kronik'te parti donar. Kronik'in bütünü [Perde Arası: Akan Kronik](/docs/story/chronicle), sonraki perde [VI. Perde: Sayım](/docs/story/act-6) sayfasındadır.

## Tarih ile kurgu

Oyuncuya her şey kesin tarihle söylenir; ayrım belgede ve Destan notunda kalır ([K33](/docs/source/design/decisions#k33), [K13](/docs/source/design/decisions#k13)).

| | V'te |
|---|---|
| Kaynakta | Han Xin'in Mayi'de teslimi ve sığınması (SJ 93, HS 1); on elçi ve Liu Jing (SJ 99); gizlenen sürü, Gouzhu ve Jinyang akını, kar, yalandan kaçış, Baideng'de yedi gün ve dört renk at (SJ 110); Chen Ping'in gizli armağanı (SJ 56); hatunun sözü; Wang Huang ile Zhao Li'nin gelmeyişi; bir köşenin açılışı ve Han'ın gerili yaylarla çıkışı. Zang Yan, Wang Huang ve Tuidang tarihî kişilerdir (SJ 93) |
| Oyunun seçimi | Yıl ve günler: oyun 201 der, geleneksel «MÖ 200» Destan notudur. Surlu Avlu ve darı tarlası Mete'den sonradır (Hanshu 94A, Ivolga); önerinin Han Xin'in adamına söyletilmesi ve Tuidang'ın bu perdede doğması da tasarım tercihidir |
| Kurgu | Yimo'nun kişiliği (Baideng'in hatunu makam olarak tarihîdir), Nangçi, Şulü, Kunduz; Zang Yan'ın ve Wang Huang'ın yaşı ve Mete'yle bağı; Wang Huang'ın seçilen sonu. Köşenin rengi ve nedeni oyuncunundur |
| Geç tanık | Kamın yol laneti, kuyu başına koyun gömmek, sonraki çağdandır |
| Mitoloji | Beyaz At Antı'nın kalıbı (HS 94B); kurgu listesine girmez |

## Tanhu 1'den fark

Köşe ya da halka seçimi yoktur: köşe her dalda açılır, oyuncu rengini ve nedenini seçer. Sisli yedinci gün ve kuşatma sisi sahnesi yoktur. Oyuncunun Liu Bang'a verdiği bir ant yoktur; barış Kronik'te, Beyaz At kalıbıyla gelir.

## Oyunda şu an

> [!DURUM]
> Oyunda: V. Perde yok. Godot'da bugün menü, gece kampı, karakter oluşturucu, kayıt, ayarlar, Destan Kitabı, Serbest Gez ve takip kamerası var. Perdeler, görev ve diyalog, saat ve takvim (gece sabittir), hava ve kar, yerleşim ve kademeleri, ordu, kalabalık çizimi, gizlilik, atlas ve yoldaş partisi yok; Mayi ve Baideng haritaları da yok. Meshy modeli olan kişi bu perdede yalnız Mete'dir; Han kişileri, konuklar ve yoldaşlar için model yok. Prototipte denendi: saat, hava, emek yasası, atlas ve yapı aşamaları; Godot'a taşınmadı ([oyun-durumu.md](/docs/source/design/d3/game-state)).

## Yol Haritası

Perdenin dört fazı ve 16 maddesi Yol Haritası'ndan canlı gelir. Önkoşul IV'ün son fazıdır (`act-4-p4`); sıra kuşatma ve ters gizlilik, avlunun iki yolu, ana zincir, yoldaşlar ve Kronik'tir.

```ilerleme
act-5
```

## Doğrulanacaklar

- Doğrulanacak: iki yolun kademe günü (Surlu 8,1, Göçer 7,8) econ-sim'den çıkar, Godot ekonomisi toleransta aynı olmalıdır ([Yol Haritası](/roadmap#item-avlu-paths)).
- Doğrulanacak: kuşatmada ≤10.000 kart ve dört renk at kalabalık satırında kalır (20 / 28 ms) ([Yol Haritası](/roadmap#item-siege)).
- Doğrulanacak: ters gizliliğin üç gözcüsü (koni 60°, 60 m) oynanarak ayarlanır ([Yol Haritası](/roadmap#item-reverse-stealth)).
- Doğrulanacak: iki yanlı dronun seçilen yandan açılışı kulakla; ana görev satırları metin kilidinden sonra seslendirilir ([Yol Haritası](/roadmap#item-act5-sound)).
- Doğrulanacak: «Kim kalsın?» kartında konuk ve zorunlu kişinin seçilememesi akış testiyle ([Yol Haritası](/roadmap#item-choose-card)).

Kullanıcının onayını bekleyenler [Karar Bekleyenler](/docs/general/pending-decisions) sayfasındadır: Kunduz'un ezgisinin Eleven Music çekimi (≈450 kredi), V'in yoldaşlarının ve konuklarının sesi ve üretimi, Çocuğun sesi ve genç ozan modeli.

## Kaynaklar

- [story.md §2](/docs/source/design/story#2-zaman-cizelgesi-1), [§11.4](/docs/source/design/story#11-4-v-perde-dort-renk-four-colours), [§13](/docs/source/design/story#13-perde-arasi-akan-kronik), [§14](/docs/source/design/story#14-kisiler-ii-vi-21-38-44), [§8.8](/docs/source/design/story#8-8-c-in-ve-han)
- [settlement.md §2.2](/docs/source/design/settlement#2-2-perde-perde), [§4.1](/docs/source/design/settlement#4-1-tablo), [§4.3](/docs/source/design/settlement#4-3-v-kademe-yolu)
- [army.md §2](/docs/source/design/army#2-olcek); `companions.md` §1.3, §2.2 ve §2.3
- [progression.md §1.2](/docs/source/design/progression#1-2-perde-xp-butcesi), [§5.3](/docs/source/design/progression#5-3-olay-degerleri)
- [fauna.md §5.2](/docs/source/design/fauna#5-2-dogan-ve-kartal), [§9](/docs/source/design/fauna#9-perde-perde-acilis), [economy.md §8.6](/docs/source/design/economy#8-6-perde-perde-ekonomi), [weather.md §6.4](/docs/source/design/weather#6-4-sonraki-perde-kancalari), [audio.md §3](/docs/source/design/audio#3-muzik-durumlari), [travel.md](/docs/source/design/travel)
- [godot.md §9.9](/docs/source/design/godot#9-9-v-perde-dort-renk-act-5)
- [mete-tarih.md](/docs/source/research/mete-history), [mitoloji.md](/docs/source/research/mythology)
- [decisions.md](/docs/source/design/decisions): K1, K13, K23, K25, K32–K35, K42–K44, K47–K55, K59, K65, K70, K71, K79, K84, K88

İlgili sayfalar: [IV. Perde: Borç](/docs/story/act-4), [VI. Perde: Sayım](/docs/story/act-6), [Hikâye Omurgası](/docs/story/spine), [Kadro](/docs/story/cast).
