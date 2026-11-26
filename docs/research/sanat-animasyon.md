# Oyun sanatı ve animasyon araştırması

Bu belge, oyunun kodla üretilen sanatı için dört cevabı (#6 pelerin, #50 Mete modeli, #63 kampın çizim sınırı, #66 üçgen sınırı), ek istekteki hayvanları, #32 yurt çeşitliliğini ve çocukluk sahnesinin küçük Mete modelini tek plana bağlar. Three.js r187, boyalı görünüm ve döner Diablo kamerası (K27, cevap 12) sabit alınmıştır. Sayılar üç yerden gelir: projenin ölçümleri, `public/models/mete.glb` üzerinde bu turda yapılan ölçüm, internet kaynakları. Etiketler: [kaynak] kaynağı olan bilgi (proje belgesi ya da dış bağlantı), [çıkarım] kaynaktan ya da hesaptan çıkan sonuç, [kurgu] oyun için önerilen uydurma. Kod değişmez; iş listesi öneriler bölümündedir.

## Özet

1. **Çizim sınırı aşılmıyor, üçgen sınırı eski.** K27 ölçümü 429 çizim, 4,40M üçgen; eski bütçe 511 ve 4,06M. Dış arazi ve dış orman bütçeden sonra geldi. Yeni kamp bütçesi **≤520 çizim, ≤4,85M üçgen**, kare 33 ms (K3) içinde kalır. Hesap 498 çizimdir, eski 511'in altında; 520 yalnız %4 paydır.
2. **İç harita tavanı ≤360 çizim (küçük akın ≤370), ≤3,10M üçgen**, kare ≤28 ms. Artışın nedeni döner kameranın dış halkası ve hayvanlar.
3. **Kareyi çizim sayısı değil, son işleme ve üçgen sürüyor.** Proje ölçümünden kaba model: `GPU ms ≈ post + 3,5 × ana Müçgen + 1,6 × gölge Müçgen`. 280 ek çizim GPU'da yaklaşık 1 ms tutuyor.
4. **Hayvanlar tek üreticiden çıkar:** `buildQuad(spec, detail)`, sekiz gövde planı, dört kademe (T0 iskeletli, T1 kukla, T2 sürü, T3 kart). T1 ve T2 `army.md` §7.3 sözleşmesidir. VAT gerekmiyor.
5. **Yürüyüş biyolojiden gelir.** Heglund ve Taylor (1988) kütleden hız ve adım sıklığı verir; bugünkü atın adım boyu (2,3 ve 4,6 m) bu tabloyla aynı büyüklüktedir, ama oyun atı gerçek Moğol atının ≈1,35 katıdır. Ayak kaymasını adım kilidi çözer, IK yalnız T0'da.
6. **Kuşlar kamera yüksekliğinin altında uçmak zorunda.** Varsayılan kadrajda gök görünmez: üst ışın ufkun 9° altındadır. Kartal hedefte en çok ≈11 m yükseklikte görünür; daha yüksekte yalnız gölgesi görünür.
7. **Pelerinde üç renk ve iki kod bulgusu var.** Boyama formülü her rengi koyulaştırıyor (`#3e5f6b` ekranda `#273e47`). Önerilen tek kural: renk `capeTint(eşya, boya)`'dan gelir, varsayılan **`#2a6f8c`**, oluşturucu paleti ölçütü geçen altı renktir.
8. **Mete'nin pelerini at sırtından neden geçiyor:** kalça altı arka pelerin köşelerinin ağırlığının %94,8'i uyluk kemiklerinde. Hesapla sürüş pozunda köşelerin %41'i at gövdesinin içine, en çok 32 cm giriyor. Çözüm yeniden ağırlık ve kaldırma; sınama listesi öneri 12'de.
9. **Küçük Mete yeni iskelet istemez:** `CHILD` iskeleti, `rootScale` 1,0 ile ≈1,25 m, yani yaklaşık 7 yaş. Shiji 110'un koyuna binen çocuğu sahnenin hareket özüdür.
10. **Yurt çeşitliliği doku değil parametredir:** üç ölçek, `aShape` ve `aTone` örnek öznitelikleri, kültür başına palet. Zon başına en çok iki gövde biçimi, çizim değişmez. İç eşya ölçeklenmez.

## 1. Bugünkü ölçümler ve doğru okuma

| Ölçüm | Çizim | Üçgen | Süre, not | Yer |
|---|---|---|---|---|
| Taban, Hero, M1 Pro, 2149×1209 | 582 | 3,84M | GPU 26,7 ms, sessiz makine | `architecture.md` §7, `army.md` §7.5 |
| Menü (Faz 7, K27) | 360 | 3,69M | Bütçesi ≤446, ≤3,72M; Faz 2'de 382 çizim | `architecture.md` §7, §9 |
| Kamp, K27, en kötü dönük poz | 429 | 4,40M | Kuzeye en kötü 427, 4,36M | `architecture.md` §7 |
| Serbest Gez bütçesi | 511 | 4,06M | Hesap, K27'den eski | `architecture.md` §7 |
| Smoke hesabı | 514 → 484 | | 446 tavanından başlar | `architecture.md` §7 |
| Boş sahnede post zinciri | 16 | | En az 11,4, ortanca 15,5 ms; Kuwahara'sız 8,3 ve 10,4 | `code-audit.md` §g |
| Çim ve çiçek kapalı | | −1,29M | Ortanca 27,9 → 22,6 ms | `code-audit.md` §g |
| Gölge donuk | | | Ortanca 27,9 → 25,8 ms | `code-audit.md` §g |
| 10 T0 at | +280 | +479k | +0,9–1,0 ms | `army.md` §7.5 |
| 1.000 T2 | +1 | +356k | ≈+1,3 ms | `army.md` §7.5 |

Tablonun hepsi [kaynak]. Bundan çıkanlar:

- **#63 için.** 514 hesabı menünün tavanından (446) başlıyordu. Menünün ölçümü 360. Gerçek başlangıç 360 + Çocuk 9 + dış halka (kalan ≈58) = 427, ölçülen kuzey pozu. Çizim bütçesi hiç aşılmıyor. [çıkarım]
- **#66 için.** 4,06M sınırı K27'nin dış arazisinden (güney uzantısı, 300 orta ve 4.200 uzak çam) önce yazıldı. Ölçüm 4,40M'dir ve «yön bütçeyi aşmaz» cümlesi yöne bakar, tavana değil. Sınır eskidi, oyun bozulmadı. [çıkarım]
- **K27 ölçümünde üçüncü yurt büyük olasılıkla yok.** Fark menüden +0,67–0,71M; dış orman ve Çocuk bunu tek başına açıklıyor. Üçüncü yurdun ≤248k'sı, araba ve gündüz ikizleri üstüne biner. [çıkarım]
- **Kare modeli.** Çimsiz deneme ve T2 ölçümü ana geçişte megaüçgen başına ≈3,5–4 ms, donuk gölge ≈1,6 ms verir. `13 + 3,5 × 2,56 + 1,6 × 1,28 = 24 ms`, ölçülen 26,7 ms'ye yakın. Model kabadır, sıralamayı gösterir. [çıkarım]
- **Çizimin GPU bedeli küçük.** 280 çizim ve 479k üçgen ≈1 ms. CPU tarafı (`renderer.render` içi) ölçülmedi. Gizli bölmedeki 10,8–19,4 ms kaba kabul edilir. [kaynak; yorum çıkarım]

## 2. Tarayıcıda çizim ve üçgen

- MDN'nin WebGL rehberi çizim çağrısı için üst sınır vermez; önerisi çizimleri az ve büyük toplulukta birleştirmek, VAO ve FBO bağlarını gereksiz değiştirmemektir. [kaynak: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices)]
- Masaüstü için sayısal tavan veren birincil kaynak bulamadım. Forum ve sektör sayfaları sayı verse de ölçüm koşulları belirsiz. Bir Three.js forum yazısında çizim 5.500–6.500'den ≈2.000'e iniyor, kare yine tam ekranda 20 fps kalıyor, küçük pencerede 60 fps oluyor: darboğaz doldurma hızı. [kaynak, anekdot: [forum](https://discourse.threejs.org/t/performance-issue-due-to-fill-rate/9019)]
- GPU Gems 3'te 9.547 karakter 8800 GTX'te 34 fps, 59.726 çizim yerine 160 örnekli çizim; o ölçekte de örnek doldurmaya takılır. [kaynak: [Dudash](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-2-animated-crowd-rendering)]
- `InstancedMesh` aynı ağı tek çizimde çeker, örnek rengi `instanceColor`'dır, tek sınır küresi kullanır. `BatchedMesh` farklı ağları tek malzemeyle çoklu çizimde toplar, `perObjectFrustumCulled` varsayılan açıktır, ilk ağın öznitelik düzeni bağlayıcıdır. [kaynak: [InstancedMesh](https://threejs.org/docs/pages/InstancedMesh.html), [BatchedMesh](https://threejs.org/docs/pages/BatchedMesh.html)]
- Örnekli ağda kırpma bütün grup içindir. Bu yüzden sürü ve orman hücreye bölünür (`flora.js` hücreleri). [çıkarım]

**Hedef sınıfları.** «Orta düzey» 2026'da RTX 3060, 4060 ve 5070 çevresidir. Steam, Ekim 2026: RTX 3060 ve 5070 %3,78, 4060 dizüstü %3,60, 4060 %3,51. [kaynak: [Steam](https://store.steampowered.com/hwsurvey/videocard/)] 3DMark Wild Life Extreme'de MacBook Pro 16 M1 Pro 9.709 (Unlimited ≈10.290); sayfa GPU çekirdek sayısını yazmaz. [kaynak: [UL](https://benchmarks.ul.com/hardware/tablet/MacBook+Pro+16%E2%80%9D+(M1+Pro,+2021)+review)] Mobil RTX 3060 ≈16.500, oran ≈1,7; sayı [nanoreview](https://nanoreview.net/ru/gpu-compare/geforce-rtx-3060-mobile-vs-apple-m1-pro-gpu)'den, sayfa bu doğrulamada açılmadı. [kaynak, zayıf] Bu test WebGL doldurma hızını ölçmez, oran kaba bir göstergedir. [çıkarım] Masaüstü 3060 için Wild Life Extreme sayısı bulunamadı; UL'nin 3060 sayfası yalnız Steel Nomad verir.

| Sınıf | Örnek | Beklenen | Etiket |
|---|---|---|---|
| Referans | M1 Pro, 2,6M piksel | Kamp 30–33 ms, iç harita 20–28 ms | [çıkarım] modelden |
| Orta masaüstü | RTX 3060 sınıfı, 1080p | GPU ≈13–16 ms, CPU payı ölçülürse 60 fps | [çıkarım] |
| Zayıf | Tümleşik GPU | `?q=low` + «Önce ne kesilir» 1–6 | [kurgu] ölçülmedi |

**Yöntem karşılaştırması.**

| Yöntem | Çizim | Kare başına JS | Bellek | Poz | Bu oyunda |
|---|---|---|---|---|---|
| `SkinnedMesh` | Hayvan başına 1 + 1 gölge | Kemik hesabı, doku yükleme | İskelet başına doku | Tam, IK olur | T0, ≤8 |
| Parça gölgelendirici (`aPart`, analitik) | Tür başına 1 | Konum, 5 Hz | Örnek özniteliği | Döngü ve birkaç sayı | T1, T2 |
| Kemik dokusu ([GPU Gems](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-2-animated-crowd-rendering)) | Tür başına 1 | 0 | ≈100 KB / tür | Pişmiş klip | Gerekmez |
| VAT | Tür başına 1 | 0 | ≈256 KB / tür | Pişmiş, deforme | Gerekmez |
| Kart atlası | 1 | Küme | 512²–1024² | 8 yön × 4 kare | T3 |

**VAT neden yok.** T2 ağı ≈250 köşe, 64 karelik dört klip: 250 × 64 × 8 B = 128 KB konum, bir o kadar normal. Köşe başına doku okuma ister; projenin çimi (1,66M köşe, 3–5 ms) bunun pahalı olduğunu gösteriyor. T2 analitik gölgelendiricisi dokusuz çalışır, 356k üçgeni ≈1,3 ms'dir. Bu kameradan otlama ve yürüme analitik olarak okunur. VAT ancak uzakta çok parçalı bir poz (uzak kalabalıkta çöken deve) gerekirse düşünülür. [çıkarım] Forumda InstancedMesh ve VAT ile 240 avatar örneği var, tek çizimlik kalabalık örneği de parça kimliğiyle gölgelendiricide çözüyor; ikisi de anekdot. [kaynak: [VAT](https://discourse.threejs.org/t/playback-the-animation-of-many-low-poly-models-as-they-are-moved-around/42205), [tek çizim](https://discourse.threejs.org/t/one-draw-call-massive-crowd-performance-engineering-in-three-js/89928)]

## 3. Dört ayaklı üretimi

**İlke.** `horse.js` zaten kesit listesiyle gövde kuruyor: `tube` kontrol noktaları, eliptik yarıçap, köşe rengi. Her tür bu listenin başka değerleridir. `src/character/animal.js` (`architecture.md` 8.6) tek üretici taşır: `buildQuad(spec, detail)`. `detail` T0, T1, T2'dir; aynı kesitlerden `seg` ve `rad` azaltılır. T3 atlası T2 ağından pişer (`army.md` §7.4). Böylece kademe değişiminde silüet atlamaz. [çıkarım]

**Ortak iskelet (T0, 16 kemik).** `pelvis, chest, neck, head, earL, earR, tail0, tail1` ve dört bacakta `upper, lower`. `Horse` 11 kemiklidir; `MountLike` yüzü (`army.md` §5.1) aynı kalır. T1 ve T2'ye inerken: gövde `aPart` 0, üst bacak 1–4, alt bacak 5–8, boyun ve baş 9, kuyruk 10. [kurgu; `aPart` numaraları `army.md` §7.3]

**Parametreler.** `hipH, shoulderH, length, girth[], neckLen, neckPitch, headLen, headDrop, tailLen, tailCarry, legThick, foot (toynak, pençe, taban), hump[], ears {len, pitch}, horns {kind, len}, coat {back, belly, legs, face, rump}`. Doku yok, köşe rengi var; `paintMaterial` fırçası yüzeyi böler. [kurgu]

**Oyun ölçeği.** `horse.js`'de sırt ≈1,64 × 1,06 = 1,74 m. Moğol atı ≈1,22–1,45 m; DAD-IS ortalaması erkek 1,31, dişi 1,26 m, kütle 300–360 kg. [kaynak: [Cheval mongol](https://fr.wikipedia.org/wiki/Mongol_(cheval)), CAB International ve DAD-IS'e atıfla; [Mongolisches Pferd](https://de.wikipedia.org/wiki/Mongolisches_Pferd) 1,30–1,45] İngilizce Vikipedi'nin 1,42–1,52 m'si (14–15 el) bu kaynaklarla çelişir, kullanılmaz. Hanshu 5'te MÖ 146'da sınırdan çıkışı yasak at 五尺九寸, ≈1,36 m üstüdür. [kaynak: [Hanshu 5](https://zh.wikisource.org/wiki/漢書/卷005); cm çıkarım] Mete 1,82 m. Yani oyun atı gerçeğin **k ≈1,35** katıdır; menü atı değişmediği için (`menuDiff`) böyle kalır. Öteki türler dünya ölçeğiyle k ≈1,15–1,30 alınır, küçükler biraz fazla büyür: kameradan okunmaları gerekir. Bedeli: deve gerçekte attan ≈1,32 kat yüksek, oyunda 1,15 kat. Silüet sınamasında deve küçük kalırsa omuz 2,2 m, hörgüç 2,7 m denenir. [çıkarım]

| Plan | Türler | Gerçek omuz, m | Oyun omuz, m | Okuma özelliği (40 px, 28° yukarıdan) |
|---|---|---|---|---|
| `equid` | At, kulan, katır, eşek | 1,22–1,45 [kaynak] | 1,74 (var) | Uzun boyun, yele, uzun kuyruk |
| `bovid_l` | Sığır, öküz | ≈1,2–1,3 [çıkarım] | 1,45 | Düz sırt, çıkık kalça, kısa alçak boyun, boynuz |
| `bovid_s` | Koyun, keçi, argali, yaban keçisi | ≈0,6–0,8 [çıkarım] | 0,80 | Koyun: `blob` yün, koyu yüz, yağlı kuyruk ([Orta Asya'dan Çin'e kuşak](https://en.wikipedia.org/wiki/Fat-tailed_sheep), bugünkü yayılış; Hun çağı için [çıkarım]). Keçi: dik kuyruk, sakal. Argali: burgu boynuz |
| `cervid` | Maral, karaca, ceylan | Kızıl geyik 0,95–1,30; Altay marali erkeği ≤1,55 [kaynak: [Red deer](https://en.wikipedia.org/wiki/Red_deer), [Altai wapiti](https://en.wikipedia.org/wiki/Altai_wapiti)] | Erkek 1,50; dişi 1,30; ceylan 0,85 | Dallı boynuz, ince bacak, ak sağrı |
| `camelid` | Deve | 1,60–1,80; hörgüç ≈2,13 [kaynak] | 2,0; hörgüç 2,45 | İki hörgüç, S boyun, geniş taban |
| `canid` | Köpek, kurt, tilki | Kurt 0,80–0,85 [kaynak] | Kurt 0,90; köpek 0,68 | Sivri kulak; kurtta sarkık, köpekte kıvrık kuyruk |
| `felid` | Manul, vaşak, kar leoparı | ≈0,25–0,6 [çıkarım] | 0,35–0,7 | Yuvarlak baş, kalın kuyruk, alçak gövde |
| `ursid` | Ayı | ≈1,0–1,2 [çıkarım] | 1,30 | Omuz tümseği, yuvarlak kulak, kuyruksuz |

Küçük av (tavşan, tarbagan, tilki yavrusu gibi) yalnız T0'dır, ≤1,2k, oturuş pozu okunur. Hepsi `survival.md` §4'ün ≤4k, tek çizim kuralındadır. [kaynak]

**Silüet sınaması.** Team Fortress 2'de sınıflar iç gölge olmadan da tanınır biçimde sınanmıştır. [kaynak: [Mitchell, Francke, Eng 2007](https://www.cs.princeton.edu/courses/archive/fall07/cos597B/papers/mitchell-team-fortress.pdf)] Burada her tür düz siyah, 8 yönde, 28° yukarıdan, 40 px yükseklikte çizilir; tür adı söylenemiyorsa ağ düzeltilir. Yan bakışa değil üstten bakışa göre tasarlanır: yün sırtı, boynuz, hörgüç yukarıdan görünür. [çıkarım]

## 4. Yürüyüş

**Veri.** 16 türde ölçülmüş denklemler, `v` m/sn, `f` adım/sn, `M` kg: tercih edilen tırıs `v = 1,09 M^0,222`, `f = 3,35 M^−0,130`; tırıs-dörtnal geçişi `v = 1,54 M^0,216`, `f = 4,19 M^−0,150`; tercih edilen dörtnal `v = 2,78 M^0,176`, `f = 4,44 M^−0,156`; en yüksek sürekli dörtnal `v = 3,71 M^0,176`, `f = 4,70 M^−0,162`; en düşük tırıs `v = 0,593 M^0,249`, `f = 2,42 M^−0,091`. [kaynak: [Heglund ve Taylor 1988, Tablo 2–3](https://www.originalwisdom.com/wp-content/uploads/bsk-pdf-manager/2019/10/Heglund-and-Taylor_1988_Speed-and-stride-frequency-and-energy-cost-per-stride-how-do-they-change-with-body-size-and-gait.pdf)] Özet ölçümü 30 g fareden 200 kg ata dek yazar, Tablo 1'de 680 kg'lik bir at da vardır (1974 verisi). Türler arasında köpek, ceylan, yağlı kuyruklu koyun (23 kg), keçi, zebu (160 kg), midilli, eşek var; deve, ayı ve maral yok. Bu üç satır dış değerdir. [çıkarım]

Hesaplanan tablo; `L = v / f` adım boyu, m. Kütleler yaklaşıktır; maral satırı dişi ve genç içindir, erkek ≤300 kg. At 330 kg, DAD-IS aralığının ortasıdır. [çıkarım]

| Tür, kg | Tırıs v, f, L | Geçiş v, f, L | Dörtnal v, f, L |
|---|---|---|---|
| Köpek 25 | 2,2; 2,20; 1,01 | 3,1; 2,59; 1,19 | 4,9; 2,69; 1,82 |
| Ceylan 28 | 2,3; 2,17; 1,05 | 3,2; 2,54; 1,24 | 5,0; 2,64; 1,89 |
| Koyun 40 | 2,5; 2,07; 1,19 | 3,4; 2,41; 1,42 | 5,3; 2,50; 2,13 |
| Domuz 90 | 3,0; 1,87; 1,59 | 4,1; 2,13; 1,91 | 6,1; 2,20; 2,79 |
| Maral 150 | 3,3; 1,75; 1,90 | 4,5; 1,98; 2,30 | 6,7; 2,03; 3,30 |
| Ayı 200 | 3,5; 1,68; 2,10 | 4,8; 1,89; 2,56 | 7,1; 1,94; 3,64 |
| At 330 | 3,9; 1,58; 2,51 | 5,4; 1,76; 3,07 | 7,7; 1,80; 4,29 |
| Sığır 350 | 4,0; 1,56; 2,56 | 5,5; 1,74; 3,14 | 7,8; 1,78; 4,38 |
| Deve 500 | 4,3; 1,49; 2,90 | 5,9; 1,65; 3,57 | 8,3; 1,68; 4,93 |

**Sağlama.** `horse.js` adım boyunu 2,3'ten 4,6 m'ye taşır; tablo 330 kg'lik gerçek at için tırısta 2,51, dörtnalda 4,29–5,60 verir. Aynı büyüklüktedir, tam sağlama değildir: oyun atı gerçeğin ≈1,35 katıdır ve `k` almaz. `horse.js` değişmez, kayma öneri 8'in sınamasıyla ölçülür. Öteki türlerde `L_oyun = L × k` alınır (k bölüm 3'ün ölçek oranı), `f = v / L_oyun`. Oyun hızı tablodan yüksek olabilir; yalnız adım boyu tablodan okunur. [çıkarım] Allometrik yürüme denklemi makalede yok. At yürüyüşü ≈7 km/sa. [kaynak: [Horse gait](https://en.wikipedia.org/wiki/Horse_gait)] Öteki türlerde yürüme hızı en düşük tırısın %80'i alınır. [kurgu]

**Faz tablosu.** Sayılar döngü payı, sıra sol arka, sol ön, sağ arka, sağ ön.

| Yürüyüş | SA | SÖ | SĞA | SĞÖ | Kim | Etiket |
|---|---|---|---|---|---|---|
| Yürüme | 0 | 0,25 | 0,5 | 0,75 | Hepsi | [kaynak] at sırası; öteki türler [çıkarım] |
| Tırıs | 0 | 0,5 | 0,5 | 0 | At, sığır, koyun, köpek, kurt, geyik | [kaynak] çapraz çift |
| Yan yürüyüş | 0 | 0 | 0,5 | 0,5 | Deve; ayı | [kaynak: [deve](https://en.wikipedia.org/wiki/Bactrian_camel)]; ayı [çıkarım] |
| Dörtnal, çapraz | 0,1 | 0,48 | 0 | 0,38 | At, sığır | `horse.js`; sığır [çıkarım] |
| Dörtnal, dönen | 0 | 0,55 | 0,1 | 0,45 | Köpek, kurt, geyik, ceylan | [çıkarım]; kaynak bulunamadı, [Gait](https://en.wikipedia.org/wiki/Gait) sayfası bu ayrımı yazmaz |
| Sıçrama | 0 | 0 | 0 | 0 | Kuzu, oğlak, oyunda | [kaynak, zayıf: [Stotting](https://en.wikipedia.org/wiki/Stotting)] |

**Ceylan sıçramaz.** Oyunun `gazelle`'i karakuyruk ceylandır (`hayvanlar.md`). Bu tür öteki ceylanların sıçrayan yürüyüşü olmadan, hızlı koşarak kaçar. [kaynak: [Goitered gazelle](https://en.wikipedia.org/wiki/Goitered_gazelle)] Stotting sayfası hayvancılıkta sıçramayı genç hayvana bağlar, tehlikeye bağlamaz. Zeren için sıçrama bilgisi: kaynak bulunamadı.

Basma payı hızla düşer, %50 üstü yürüme sayılır; sayfa bu satırda kaynak göstermez. [kaynak, zayıf: [Gait](https://en.wikipedia.org/wiki/Gait)] T0 için 0,65, 0,45, 0,25. [kurgu] Froude sayısı (`v² / (g h)`) farklı boydaki hayvanları eşler; Alexander ve Jayes (1983) tam metni okunamadı, eşikleri burada kullanılmadı. [kaynak: [özet](https://pmc.ncbi.nlm.nih.gov/articles/PMC3798186/)]

**Ayak kayması.** Kovar ve arkadaşları yere basması gereken ayağın yer değiştirmesini ele alır. [kaynak: [Kovar 2002](https://doi.org/10.1145/545261.545277), tam metin bu doğrulamada açılmadı] 2011 tarihli algı çalışmasında izleyiciler çoğu koşulda 21 mm altını da fark ediyor; insan ve yakın plan içindir. [kaynak, doğrulanamadı: [SCA 2011](https://doi.org/10.2312/SCA/SCA11/287-294), sayfa ve 21 mm sayısı bu doğrulamada açılmadı] Bu kamerada 33 m'de 1 m ≈53 px, 21 mm ≈1 px; boya filtresi bunu siler. 13 m'de 21 mm ≈3 px. [çıkarım]

- **T1, T2.** IK yok. `freq = v / L(v)` düzde kaymayı sıfırlar; `phase0` düzeltmesi hız değişiminde sıçramayı önler (`army.md` §7.3). Kabul ≤6 cm, 33 m'de ≈3 px. [kaynak ve çıkarım]
- **T0.** Basan ayak dünyaya kilitlenir, iki kemikli kapalı çözüm (kosinüs yasası) bacağı kurar, salınımda ayak yay çizer, `pelvis` yüksekliği dört ayağın zemin ortalamasıdır, eğim iki noktadan okunur. Hayvan başına ≤0,02 ms. Kabul ≤2 cm. [kurgu]
- **Az anahtarlı yordamsal yaklaşım** projenin çizgisiyle aynı: az poz, yay ve faz. [kaynak: [Rosen, GDC 2014](https://www.gdcvault.com/play/1020583/Animation-Bootcamp-An-Indie-Approach)]

## 5. Kademe ve uzaklık

`army.md` §7.1 kademeleri pikselledir: `px = 2,75 × H / (2 d tan 19°)`, H 1209'da metre başına `1755 / d`. Hayvanda yükseklik türündür. [kaynak; uyarlama çıkarım] Ordunun eşikleri T0 ≥80, T1 ≥28, T3 <28, T4 <3 px'tir. Aşağıdaki T1 ≥40, T2 ≥14, T3 ≥4 hayvan için yeni eşiktir. `h` omuz değil, kadrajda okunan yüksekliktir (at 1,95, deve hörgüçte 2,45). [kurgu]

| Tür, h | T0 ≥80 px | T1 ≥40 px | T2 ≥14 px | T3 ≥4 px |
|---|---|---|---|---|
| Köpek 0,68 | ≤15 m | ≤30 m | ≤85 m | ≤298 m |
| Koyun 0,80 | ≤18 m | ≤35 m | ≤100 m | ≤351 m |
| Kurt 0,90 | ≤20 m | ≤40 m | ≤113 m | ≤395 m |
| Ayı 1,30 | ≤29 m | ≤57 m | ≤163 m | ≤570 m |
| Sığır 1,45 | ≤32 m | ≤64 m | ≤182 m | ≤636 m |
| Maral 1,50 | ≤33 m | ≤66 m | ≤188 m | ≤658 m |
| At 1,95 | ≤43 m | ≤86 m | ≤244 m | ≤856 m |
| Deve 2,45 | ≤54 m | ≤108 m | ≤307 m | ≤1.075 m |

Uzaklık kameradandır. Varsayılan `foot` 33 m'dir: oyuncunun yanındaki koyun T1 sınırındadır, T0 yalnız yakınlaşınca gelir. T0 dolarsa bir alt kademe; kare başına ≤8 takas, ±%15 gecikme payı (`army.md` §7.1). Boyama geçişi gizler, karışım gerekmez. [çıkarım]

Bu kameranın başka bir sonucu: hayvanların çoğu zaman T1 ve T2'de görünür. Sanat emeği T1 ağına ve renge gider, T0 yalnız binilen, avlanan ve adlı hayvanlardadır. [çıkarım]

## 6. Sürü davranışı

- 100 kadar koyunda iki evre gözlenmiş: yavaş yayılan otlama, sonra her ölçekte hızlı toplanma dalgası; model besin ve korunma arasında gidip gelir. [kaynak: [Ginelli 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4611628)]
- Tehdit altında koyun sürünün ortasına doğru gider. [kaynak: [King 2012](https://discovery.ucl.ac.uk/id/eprint/1366736/)]
- Sürü, baş başına boids değildir. Tek sürü ajanı: merkez, yarıçap, evre. Her baş ofset ve fazdan okunur. 5 Hz, sürü başına tek hesap, `settlement.md` §17'nin ≤0,1 ms'si içinde. [kurgu]
- Sayılar: `Yayıl` evresinde yarıçap 0,03 m/sn büyür, en çok `1,6 √n` m; `Toplan` 6–12 sn sürer, `0,9 √n` m'ye iner, baş 2,5 m/sn koşar. Tetik: 8–20 oyun dakikası, kurt, köpek, gök gürültüsü (K22), `Çığırtkan` (`act1.md` `herd_habit`). [kurgu]
- Köpek sürünün kenarında, hedefin karşı tarafında durur; bu çizgi çoban sezgisine dayanır, Strömbom (2014) burada okunamadı. [kurgu]
- Kervan ve kafile: yol üzerinde sabit aralık, 3,2 m gecikmeli izleme. Çöken deve T0'a geçer. [kurgu]

## 7. Kuş uçuşu

**Kamera sınırı.** `foot`: eğim 28°, uzaklık 33 m, görüş 38°. Kamera hedefin 15,5 m üstünde; hedef y 0,6 olduğundan yerden ≈16,1 m. Üst ışın ufkun 9° altında, alt ışın 47°. Yani gök yoktur; hedef noktada yerden ≈11,5 m üstü kadraj dışıdır, kahraman üstünde ≈12,4 m, kameradan 60 m ötede ≈6,6 m. `ride` (22°) üst ışını 3° altta, `lookout` ve `rideUp` (16–17°) ufku biraz geçer. `oyun-seviye-tasarimi.md` §6'nın eğim bandı (22–60°) kabul edilirse kadraj tepesi hedefte ≈11–20 m arasında oynar, gök yine yalnız o ön ayarlarda görünür. [çıkarım, `camera-rig.js`]

**Sonuç.** Kuşlar üstten görülür. Yükseklik gerçek değil, sabit ≈6–11 m alınır (varsayılan kameranın 0,4–0,7 katı). Kartal gerçek irtifada uçuyorsa kadrajda yalnız yerde kayan gölgesi vardır: 2 üçgenlik leke, güneş yönünden, gece yok. [kurgu]

**Sürü.** Üç kural ayrılma, hizalanma, toplanma. [kaynak: [Boids](https://en.wikipedia.org/wiki/Boids)] Sığırcıklarda etkileşim yakınlık sırasıyla 6–7 komşudur, uzaklıkla değil. [kaynak: [Ballerini 2008](https://pmc.ncbi.nlm.nih.gov/articles/PMC2234121/)] Burada ≤64 kuş, ızgarada 6 komşu, kural 5 Hz, tümleme kare başına, ≤0,05 ms. Three.js'in GPGPU kuş örneği bu sayıda gereksiz. Kaz için V yuvası ve başa geçme. [kurgu]

**Ağ.** Tek `InstancedMesh`, program `flock_bird`, 1 çizim. Kanat iki parça, analitik; karga ≤60 üçgen, kaz ≤80, kartal T0 ≤600 (uç tüyler geometri). [kurgu]

**Kanat çırpma.** `f = 1,08 m^(1/3) g^(1/2) b^−1 S^(−1/4) ρ^(−1/3)`. [kaynak: [Pennycuick 1990](https://journals.biologists.com/jeb/article/150/1/171/5695/Predicting-Wingbeat-Frequency-and-Wavelength-of); sayfada denklem resimdir, değişkenler doğrulandı, katsayı ve üsler metinden okunamadı] Varsayılan ölçülerle kartal ≈2,8 Hz, kaz ≈4,0, karga ≈4,7, keklik ≈9,3; kütle ve kanat varsayımı bunu ±%10 oynatır. [çıkarım] Yazarın 1996 güncellemesi eski denklemin hızlı çırpan türlerde düşük kaldığını söyler: karga ve keklik sayısı alt sınırdır. [kaynak: [Pennycuick 1996](https://journals.biologists.com/jeb/article/199/7/1613/7344/Wingbeat-Frequency-of-Birds-in-Steady-Cruising)] Kartal süzülürken 45–52 km/sa; kanat ve kuyruk tek düzlemde, uç tüyler açık; uçuşta kanat çoğu kez hafif V tutulur. Çırpma 6–8 derin vuruş, 2–3 sn süzülme. Kanat açıklığı 1,8–2,34 m. [kaynak: [Golden eagle](https://en.wikipedia.org/wiki/Golden_eagle)] Dönüş yarıçapı 13,5 m/sn ve 25° yatışta `v² / (g tan φ)` ≈40 m. [çıkarım]

## 8. İkincil hareket ve rüzgâr

Kritik sönümlü yay tek sayıyla (yarı ömür) ayarlanır ve kare hızından bağımsızdır. [kaynak: [Holden](https://theorangeduck.com/page/spring-roll-call)] İkincil harekete uygulamak bu belgenin önerisidir. [çıkarım]

| Parça | T0 | T1, T2 | Yarı ömür | Tetik |
|---|---|---|---|---|
| Kuyruk | `tail0, tail1` yayı | Parça 10, analitik | 0,25 sn | Hız, dönüş, 0,3–1 Hz sinek kovma |
| Kulak | `earL, earR` | Yok | 0,08 sn | Ani oynatma, sn'de 0,1; tehlikeye dönüş |
| Boyun, baş | Otlama 4–12 sn | `aPose.x` | 0,4 sn | Durum |
| Yele | Kemik yok, köşe payı | Yok | 0,18 sn | Hız, rüzgâr |
| Pelerin (Mete) | `uCapeLag` | | 0,2 sn | Hız, rüzgâr, sürüş |

Rüzgâr `weather.md` `fx`'inden tek tekdüze `U.uWind`'e gelir; yele, kuyruk, pelerin, çadır kapağı okur. Program eklemez. [kurgu] Verlet kumaş ucuzdur, Hitman tek gevşetme geçişiyle yetinmiştir. [kaynak: [Jakobsen 2001](http://www.cs.cmu.edu/afs/cs/academic/class/15462-s13/www/lec_slides/Jakobsen.pdf)] Ama köşeyi CPU'ya alır; Mete'de 27.900 boya köşesi var; 33 m'de yaya Mete ≈97 px, atlı ≈146 px, karşılığı yok. Yalnız sancak gibi küçük ağda düşünülür. [çıkarım]

## 9. Boyalı görünüm ve okunurluk

**Filtre sınırı.** Kuwahara yarıçapı 3,1 px, çekirdek ≈7 px. 33 m'de 13 cm, 44 m'de 18 cm, 13 m'de 5 cm altı ayrıntı lekeye karışır. Okunması gereken ayrıntı ≥15 cm olur: koyun kulağı, keçi sakalı, boynuz kalınlığı abartılır. İnce ip ve dizgin çizilebilir ama bilgi taşıyamaz. Bir iki piksellik şeyler filtre sonrası çizilir (yağış gibi, `weather.md`). [çıkarım, sayılar `gorsel-dil.md`]

**Değer hiyerarşisi.** Kaynaklardan dört kural:

- Gölge soğuğa gider, siyaha değil; sınırda doygunluk artar. Kodda bu bant var. [kaynak: Mitchell ve arkadaşları]
- Yaygın renk bastırılmış, doygunluk küçük alanlarda (makalede üs dokuları için). [kaynak: aynı]
- Alt gövde koyu, üst gövde karşıtlıklı, ayrıntı göğse toplanır. [kaynak: [Game Developer](https://www.gamedeveloper.com/art/in-depth-how-valve-makes-art-to-enhance-gameplay)] Dota 2 kılavuzunun üstten bakışta aynı eğimi (ayakta koyu, başta açık) istediği arama özetinden alındı, sayfanın gövdesi açılmadı. [kaynak, doğrulanamadı: [Dota 2 Art Guide](https://help.steampowered.com/faqs/view/0688-7692-4D5A-1935)] Dikkati başa ve omza çıkarmak bu kameraya uyarlamadır. [çıkarım]
- Sınır koyu çizgiyle değil, açık kenar ışığıyla ayrılır. Bu oyunun «çizgi ve ikon yok» kuralıyla aynı. [kaynak; `gorsel-dil.md`]

**Bu oyundaki sıra.** 1 Mete'nin omuz ve pelerin lekesi, 2 ateş ve ışık, 3 adlı kişi, 4 kalabalık, 5 hayvan, 6 zemin. Mete `rim` 0,28 → 0,34, T1 ve T2 0,18. Düz arka pelerin yalnız Mete ve adlı kişilerde; kukla pelerinsizdir. [kurgu]

**Hayvan renkleri.** `instanceColor` türün tablosundan, ±%8 boy, faz rastgele, doygunluk C ≤0,06 (OKLCH). At rengi: bugünkü Moğol çobanı çoğunlukla kula, doru ve karayı yeğler, akı sevmez. [kaynak, modern: [Mongol atı](https://en.wikipedia.org/wiki/Mongolian_horse)] Bu Hun çağına geri yazılmaz: Shiji 110'da Baideng'de ak, boz-mavi, kara ve al at birlikleri vardır (`army.md` §7.4). [kaynak: [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110)] Program: `animal`, `flock_bird` yeni; `crowd_t1`, `crowd_t2`, `card_t3` ordudan. [kaynak ve kurgu]

## 10. Pelerin: bulgular (#6)

**Dört yer dört şey söylüyor.** [kaynak]

| Yer | Söylediği |
|---|---|
| `act1.md` §1, §3; `progression.md` | `#3e5f6b`, «kalabalığın tek soğuk vurgusu» |
| `src/data/gear.js` | `cape_hostage` `#3e5f6b`; `hostage_coat` `preset: METE_HOSTAGE` |
| `src/character/mete.js` | `METE_HOSTAGE.cape` `#5d4a3a`, solgun yün kahvesi |
| `src/ui/creator/rows.js` | Sekiz seçenek; doğal = modelin kızılı; önizleme tam zırhlı |

Kaftan da pelerin de aynı anahtarı boyuyor. Oluşturucu rehine kılığını hiç göstermiyor; ayrıca `tunic` ve `plate` satırları I. Perde'de görünmüyor. [çıkarım]

**Tanhu 1 ile ortak.** «Tek soğuk vurgu» Tanhu 1'in renk rehberinde de var (orada camgöbeği kaftan); `gear.js`'in «Rehine Kaftanı» adı Tanhu 1'in `rehine_kaftani`siyle aynı (`docs/research/progression.md`). Cevap 5 gereği ilke kopya olarak taşınmaz: burada gerekçesi yalnız öneri 4'ün okunurluk ölçümüdür. Ad değişmeli; öneri «Kışlak Kaftanı / Winter Camp Coat», «Kışlak Pelerini / Winter Camp Cape». [kurgu]

**Kod bulgusu.** Boyama satırı `uCapeTo * (lum / lumOf(uCapeTo) * 0,28 + 0,3)`. Modelin kızıl pelerininde ortalama `lum` 0,0457 (10. ve 90. yüzdelik 0,039 ve 0,054; bu turda ölçüldü). Çarpan 0,32–0,81 çıkar: `#3e5f6b` ekranda `#273e47`, ham keçe `#d8cdb8` ekranda `#817a6d`. Yani boncukta görülen renk ekrana gelmiyor. `plate` ve `tunic` satırları oranlı çalışıyor (`lum / 0,06`, `lum / 0,42`), yalnız pelerin farklı. [çıkarım, `mete.js:86`]

**Renk ölçümü.** OKLab üzerinde `act1.md` §3'ün 29 kalabalık rengine karşı en küçük fark. ΔE 0,02 Oklab'da bir görünür fark sayılır. [kaynak: [CSS Color 4](https://www.w3.org/TR/css-color-4/), değişiklik notu] Altı ışık rengiyle çarpıldı (`time.md` §5.4), renk körlüğü Machado deutan ve protan matrisleriyle. Kar `#e2ddd6`, ot `#8fa058`, toprak `#7a6248` yaklaşık alındı. Hepsi düz albedo hesabıdır. [çıkarım; yöntem [Oklab](https://bottosson.github.io/posts/oklab/), [Machado 2009](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html), [WCAG 3:1](https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html)]

| Renk | Hex | Öğle ΔE | En kötü ΔE | Renk körü | Kar oranı | Ot ΔE | Toprak ΔE | Sonuç |
|---|---|---|---|---|---|---|---|---|
| Göl Mavisi | `#2a6f8c` | 0,097 | 0,075 | 0,102 | 4,14 | 0,221 | 0,130 | Geçer |
| Gök | `#3a78a8` | 0,124 | 0,077 | 0,129 | 3,51 | 0,213 | 0,153 | Geçer |
| Çivit | `#34508a` | 0,114 | 0,066 | 0,126 | 5,84 | 0,304 | 0,167 | Geçer |
| Koyu Çivit | `#2b3f66` | 0,084 | 0,056 | 0,078 | 7,75 | 0,345 | 0,187 | Geçer |
| Turkuaz | `#1d7a80` | 0,085 | 0,081 | 0,070 | 3,75 | 0,187 | 0,123 | Geçer |
| Menekşe | `#5f4a96` | 0,133 | 0,062 | 0,137 | 5,35 | 0,301 | 0,165 | Geçer |
| Eski varsayılan | `#3e5f6b` | 0,060 | 0,034 | 0,063 | 5,09 | 0,241 | 0,102 | Geçmez |
| Çam | `#2f5a41` | 0,042 | 0,027 | 0,003 | 5,85 | 0,254 | 0,116 | Geçmez |
| Mor | `#5b2e57` | 0,064 | 0,026 | 0,056 | 7,88 | 0,350 | 0,174 | Geçmez |
| Aşı | `#a57630` | 0,017 | 0,015 | 0,012 | 2,97 | 0,109 | 0,103 | Geçmez |
| Ceviz | `#5a3b26` | 0,030 | 0,016 | 0,004 | 7,44 | 0,306 | 0,131 | Geçmez |
| Kömür | `#2e2b2e` | 0,029 | 0,027 | 0,007 | 10,36 | 0,396 | 0,226 | Geçmez |
| Ham keçe | `#d8cdb8` | 0,043 | 0,034 | 0,045 | 1,17 | 0,192 | 0,339 | Geçmez |
| Doğal kızıl | `#7c2320` | 0,012 | 0,006 | 0,005 | 7,34 | 0,323 | 0,149 | Geçmez |

Kalabalık sıcak bantta (OKLCH h 5–88°), yalnız Vusun tüccarı Nandu yeşilde (≈120°), soğuk bant boş. `#3e5f6b`'nin tonu doğru ama doygunluğu düşük (C 0,043): sıcak gün ışığında griye kayıyor. `#2a6f8c` aynı tonda, C 0,082. [çıkarım]

**Kızıl Pelerin.** `#7c2320` Hun kalabalığında kaybolur (Eskam `#7a2a22`: ham ΔE ≈0,013, en kötü ışıkta ≈0,006). `#a8321f`'e çekip sıradan Hun kalabalığını C ≤0,05'e indirince en kötü ΔE 0,081. [çıkarım]

## 11. Mete ve at: ölçüm (#50)

`mete.glb` bu turda okundu. 60.592 üçgen, 109.337 köşe, 24 kemik, 2048² JPEG, yükseklik 1,82 m, kalça bağlama y 1,007. [kaynak: dosya]

- Boya maskesi (`dye`) 27.900 köşeyi tutar; 13.633 üçgen tümüyle içindedir. Pelerin, kuşak ve şeritler aynı maskededir. [kaynak: dosya]
- Kalça altı, arka pelerin (y <0,95, z <−0,02): 10.249 köşe. Ağırlığın **%94,8'i uyluklarda** (`LeftUpLeg`, `RightUpLeg`). Pelerin otomatik ağırlıkla bacağa yapışmış: yürürken ortadan ayrılır, sürüşte bacakla açılır. [kaynak: dosya]
- Sürüş pozu hesabı (`rig.js` `ride`: uyluk −0,7 ve ±1 rad; at gövdesi `horse.js` kesitleri, elips): kalça altı 11.071 köşenin **%41'i at gövdesinin içinde, en derin 32 cm**. Yaklaşık modeldir. [çıkarım]
- Yalnız kalçaya yeniden ağırlık vermek çözmez: %52, 33 cm. Kaldırma gerekir. `Folk`'un `uRide` sayıları (0,66 ve 0,46) içeri girmeyi sıfırlar ama etek sağrıdan 25 cm havada kalır. **Kaldırma 0,50, geri 0,38:** %2,6, en çok 1,8 cm; etek kalça hizasında, 74 cm geride, sağrının 9 cm üstünde. [çıkarım]
- Üzengi dönem dışıdır. Çift üzengi için güvenilir ilk tasvir MS 322, en eski çift buluntu MS 415; MS 302 figürininde yalnız tek yanlı biniş üzengisi var. [kaynak: [Stirrup](https://en.wikipedia.org/wiki/Stirrup)] Keçe bu sayfada geçmez, eyer bilgisi [Saddle](https://en.wikipedia.org/wiki/Saddle) sayfasındadır: Moğol platosu göçerlerinde ilkel çerçeve, iki deri yastık, keçe örtü (Ukok, MÖ 500–400); Qin pişmiş toprak atlılarında eyer (MÖ 206'ya dek), üzengi yok; keçe kaplı ahşap çerçeve daha geçtir, Moğolistan'da MS 3. yüzyıl. [kaynak, ansiklopedik] Mete'nin eyeri yastıklı ve keçe örtülüdür; `saddle_felt` (K4) ve `progression.md` §16.1 #8 buna uyar. [çıkarım] `horse.js:176-180` üzengi kayışı ve tunç üzengi çiziyor. [kaynak: kod]

## 12. Çocuk ve bebek ölçeği

**Boy.** WHO erkek medyanı: 5:1 yaş 110,3; 6 yaş 116,0; 7 yaş 121,7; 8 yaş 127,3; 10 yaş 137,8; 12 yaş 149,1; 14 yaş 163,2; 19 yaş 176,5 cm. [kaynak: [WHO, erkek yüzdelikleri](https://cdn.who.int/media/docs/default-source/child-growth/growth-reference-5-19-years/height-for-age-%285-19-years%29/hfa-boys-5-19years-per.pdf?sfvrsn=56a734fa_4)] Mete 1,82 m olduğundan ×1,03: 7 yaş ≈125 cm, 10 yaş ≈142 cm. Bugünkü ortancadır, Hun çocuğunun boyu değil: yalnız oyun ölçeğidir. [çıkarım]

**Baş oranı.** Bebek boyun ≈1/4'ü, 2 yaş ≈1/5, 6 yaş ≈1/6, 15 yaş ≈1/7. [kaynak, zayıf: [ders notu](https://www.msnucleus.org/membership/html/k-6/lc/humanbio/2/lchb2_3a.html)] Önceki 1/7,5 bu notta yok; [Applied Sciences 2024](https://doaj.org/article/2799e97f4cdd49a4a39a0c26522def26) bu doğrulamada açılmadı.

**İskelet.** `CHILD` eklemleri ×0,64, baş 1,02 (eklem başı). Baş tepesi ≈1,25 m. Serbest Gez Çocuğu `rootScale` 1,14 ile ≈1,43 m, yani ≈10 yaş. Aynı iskelet `rootScale` 1,0 ile ≈1,25 m, yani ≈7 yaş. Baş oranı ≈5 baş, gerçeğin (≈6) üstünde: bu kamerada çocuk olarak okunmayı sağlar. Ağ ölçülmedi, hesaptır. [çıkarım, `rig.js`, `actor.js`]

**Kaynak sahne.** Shiji 110: 兒能騎羊，引弓射鳥鼠；少長則射狐兔。 Hun çocuğu koyuna biner, kuşa ve fareye ok atar; biraz büyüyünce tilki ve tavşana. [kaynak: [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110)] Tanhu 1'de bu bilgi yalnız bir ipucu satırıdır, sahne yoktur (`docs/research/progression.md`). Bu sahne Shiji'den kurulur, Tanhu 1'den alınmaz. [çıkarım]

**Bebek.** Kundak ağ değil eşyadır: `lathe` gövde, küçük yüz, ≤400 üçgen; `carry('swaddle')` ile yetişkin kucağında. Beşik yurt içi eşyası, ≤900 üçgen, `k.put`. [kurgu]

## 13. Yurt ve çadır

**Kaynak.**

- Shiji 110 Hunların evine 穹廬 der, giysi için 旃 (keçe) geçer. [kaynak: [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110)] Hanshu 96B'de Vusun'a giden prensesin şarkısı 穹廬 ve 旃 sözcüklerini kullanır; Mete'den yaklaşık bir yüzyıl sonradır. [kaynak: [Hanshu 96B](https://zh.wikisource.org/wiki/漢書/卷096下)]
- Stronach: iki tip vardır. Kaburgalı çadırda dikmeler yerden tepe halkasına çıkar; MÖ 600 çevresinde belgelidir. Kafesli (kerege) çadır MS 560'a dek neredeyse kesin vardır, ötesi tartışmalıdır, yazar MÖ 1. binyıl ortasını olası sayar. Tartışmasız en eski kafes kalıntısı Cengiz dönemi mezarındandır. [kaynak: [Stronach](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/On-the-Antiquity-of-the-Yurt.pdf)]
- Pazyryk arabalarından birinde kutu gibi ahşap kabin kısmen kara keçe kaplıdır; Stronach kültürü MÖ 3. yüzyıl çevresine koyar. [kaynak: Stronach] Ansiklopedik sayfalar kültüre MÖ 6–3. yüzyıl, ilk beş kurgana MÖ 4–3. yüzyıl, 5. kurgan dokumasına ≈MÖ 241 der: Mete'nin çağından az önce ya da onunla aynı. [kaynak: [Pazyryk culture](https://en.wikipedia.org/wiki/Pazyryk_culture), [Pazyryk](https://en.wikipedia.org/wiki/Pazyryk_carpet)] Stronach gömülenlerin kimliğini belirsiz sayar, Vikipedi sayfası Saka der. Oyunda Saka yurduna bağlamak çıkarımdır. [çıkarım]
- Çivitle boyanmış keçe yurt MS 833'te Bai Juyi'nin şiirinde var; daha geç bir tanıktır. [kaynak: Stronach]
- Moğol gerinin çatısı basıktır, ≈20–25°. Kırgız yurdunun sırığı büküktür, çatısı dik, bir fotoğrafta ≈45°. Kazak yurdu için bu sayfada sırık ve yükseklik bilgisi yok: kaynak bulunamadı. [kaynak, zayıf: [simplydifferently](https://simplydifferently.org/yurt?page=1)] Bunlar bugünkü etnografyadır, MÖ 3. yüzyıla geri yazılmaz; oyun yalnız silüet ayrımı için kullanır. [çıkarım]
- Oyun yurdu r 7,05 m, tepe 8,6 m: gerçeğin (≈6–7 m çap) yaklaşık iki katı. İç mekân ve kamera buna göre kurulu. Değişmez. [çıkarım, `structures.md`]

**Maliyet merdiveni var.** `hero` 76–129k, `winter` ≤34k, `closed` ≈3k, uzak kubbe 96 üçgen; `YurtField` 1 + 1 çizim, `KitField` tek `BatchedMesh` (`structures.md` §3.5, §13.6). [kaynak] Çeşitlilik bu merdivenin her basamağında aynı parametreyle çalışmalı. [çıkarım]

**Doku yerine parametre.** Yurt dokuları (`yurtTex`, `wallTex`, `rugTex`) kodla boyanır, her biri bellektir. Kültür başına yeni doku yerine köşe renginin paleti ve örnek özniteliği değişir. `closed` ağı tek kalır; gölgelendirici çatıyı `aShape`'e göre uzatır, duvarı katlar. `wallK` 0 kaburgalı kubbedir. Böylece kültür ve boy çizim eklemez. [kurgu]

## Oyuna öneriler

1. **#66, #63: Yeni bütçe tablosu.** `architecture.md` §7'nin satırları böyle olur. Eski 514 → 484 cümlesi ve «Smoke önkoşuldur» kalkar: birleşme kodda (`fire.js`: bütün bulutlar tek çizim), ölçüm içinde. K22 ve K26'daki önkoşul cümlesi karşılanmış sayılır; ikisinin metni `decisions.md`'de güncellenir.

   | Sahne | Eski üçgen, çizim | Ana üçgen | Toplam üçgen | Çizim | Kare |
   |---|---|---|---|---|---|
   | Menü | ≤3,72M, ≤446 | ≤2,50M | ≤3,72M | ≤400 (ölçüm 360) | 33 ms |
   | Serbest Gez, üçüncü yurt tam, dönük | ≤4,06M, ≤511 | ≤3,45M | **≤4,85M** | **≤520** | 33 ms, K3 |
   | Kışlak, gündüz ve gece | ≤2,74M, ≤323 | ≤2,40M | **≤3,10M** | **≤360** | ≤28 ms |
   | Yerleşim, Tanhu Avlusu | ≤2,74M, ≤323 | ≤2,40M | **≤3,10M** | **≤360** | ≤28 ms |
   | Ordugâh, Binlik | ≤2,74M, ≤323 | ≤2,40M | **≤3,10M** | **≤360** | ≤28 ms |
   | Bozkır, Onluk ve Yüzlük | ≈2,5M, ≈240 | ≤2,20M | ≤2,90M | ≤320 | ≤28 ms |
   | Küçük akın (#43) | ≤2,8M, ≤340 | ≤2,40M | ≤3,10M | ≤370 | ≤28 ms |
   | Çocukluk sahnesi (yeni) | | ≤2,00M | ≤2,60M | ≤300 | ≤28 ms |
   | Kara Boran, Yeni Oyun, harita, oluşturucu | Değişmez | | | | |

   **Kamp hesabı.** Çizim: 429 ölçüm + 45 üçüncü yurt + 6 araba + 6 gündüz ikizi + 2 fırtına + 6 yaban hayvanı + 3 koyun sürüsü + 1 kuş = 498, pay %4 → 520. Üçgen: 4,40 + 0,248 + 0,010 + 0,040 + 0,024 + 0,015 + 0,001 = 4,74M, pay → 4,85M. Süre: 13 + 3,5 × 3,45 + 1,6 × 1,40 ≈ 27 ms GPU, K3 içinde.

   **İç harita hesabı.** 2,04M ana + dış halka 0,25M (K27: dünyalar her yönden bitmiş görünür) + hayvan ≤0,11M = ≤2,40M; gölge 0,70M. Yerleşimde en kötü hayvan karesi +0,12M'dir (öneri 5: 250k − 130k), ama hesabı ≈1,92M'dir: 1,92 + 0,25 + 0,12 = 2,29M, tavanın altında. Süre: 11 + 8,4 + 1,1 ≈ 21 ms GPU, JS ≤3 ms.

   **Sitede yazılacak açıklama (#66).** «Üçgen sınırı karede çizilen geometriyi sayar. Dönen kamera için dış arazi eklendi, eski sınır onu saymıyordu. Sınır güncellendi, kare hedefi değişmedi.» [çıkarım]

2. **#63, #66, cevap 12: Ölçüm kuralı.** `tools/check-budget.mjs` (12.4) her nokta için 0°, 90°, 180°, 270° ve en büyük yakınlaştırmada ölçer. `ZOOM.max` 44 m'yi aşarsa bu tablo yeniden sınanır. K27 ölçümü varsayılan eğimdedir; `oyun-seviye-tasarimi.md` §6'nın eğim bandı kabul edilirse ızgaraya alt sınır da girer (33 m'de 22°, 44 m'de 24°): kuzey görüşü 79 m'den ≈224 m'ye çıkar, bu tablo o eğimde ölçülmedi. Tablo aşılırsa %3'e dek uyarı, üstü düşer. Yeni ölçüm: `renderer.render` CPU süresi, kamp ve Kışlak; hedef ≤4 ms. Karar «Önce ne kesilir»den alınır; 9. satıra «dış orman uzak 4.200 → 2.800», 7. satıra «hayvan T0 8 → 4» eklenir. [kurgu]

3. **#6: Pelerinin tek renk kuralı.**
   - **Tek kaynak.** Renk `capeTint(equip.cape, look.cape)`'tan gelir. `gear.js` `paint.cape` sabit renk ya da `'dye'` olur. `METE_HOSTAGE`'dan `cape` kalkar; kaftan pelerini boyamaz.
   - **Boya.** Oluşturucu satırı «Boya / Dye» olur. `look.cape` null ise `#2a6f8c`. Palet altı renktir: Göl Mavisi, Gök, Çivit, Koyu Çivit, Turkuaz, Menekşe. Ötekiler paletten çıkar. Kayıt göçü: `#2b3f66` kalır, çam → Turkuaz, mor → Menekşe, öteki → varsayılan.
   - **Boyananlar.** `cape_hostage` ve yeni `dyed_cape` «Boyalı Pelerin / Dyed Cape» (Keçe Avlusu, 2 keçe, 1 boya, II. Perde). Boyanmayanlar kendi rengindedir: `wolf_pelt`, `palak_fur`, `snow_cloak`, `white_felt`, `war_cape`. `war_cape` `#a8321f` olur.
   - **Boya malı, `economy.md` ile çelişki.** Oradaki tek boya `dye` «Kızıl Boya»dır (kökboya; Pazyryk'te de kökboya kullanıldığı kaydedilir [kaynak: Sci. Rep. 2021]). Kızıl boyayla mavi pelerin olmaz. Yeni kimlik gerekir: ham `woad`, işlenmiş `dye_blue` «Mavi Boya / Blue Dye», K24 taksonomisine ve `contract-requests.md`'ye yazılır. Çivit otu bozkırda doğal yetişir. [kaynak: [Isatis tinctoria](https://en.wikipedia.org/wiki/Isatis_tinctoria)] Hun çağında mavi boyaya doğrudan kanıt: kaynak bulunamadı; en erken tanık bu belgede MS 833'tür. [kurgu]
   - **Önizleme.** Oluşturucu ilk açılışta rehine kılığını gösterir, «Öz kılık» düğmesi zırhlıyı. `tunic` ve `plate` satırları «II. Perde'den» bölümüne taşınır: rehine kaftanı boyanmaz.
   - **Formül.** `mete.js:86` `uCapeTo * clamp(lum / 0,0457, 0,6, 1,4)` olur: boncuk ekrana gelir, kıvrım gölgesi kalır.
   - **Ayrılmış bant.** OKLCH h 190–300°, C ≥0,05 kalabalık giysisinde yasak, adlı kişide izinli. Rengi oyuncunun sancağı ve `banner_pole` da taşır (`army.md` §7.1, `settlement.md` §7.9): dost ordu boyayı sancakta taşır, atlı giysisi `army.md` §7.4'ün Hun kızıl-kahvesinde kalır.
   - **Belgeler.** `act1.md` §1, §3 ve `progression.md`'de `#3e5f6b` yerine «Boya, varsayılan `#2a6f8c`»; `kadro.md`'deki açık soru kalkar. [kurgu]

4. **#6: Okunurluk ölçütü.** Yeni renk ya da kişi eklenince saf bir araç (`tools/check-palette.mjs`) sınar.
   - P1 kalabalık: öğlede ΔE ≥0,08; altı ışık durağında en kötü ≥0,05.
   - P2 renk körlüğü: deutan ve protan ≥0,05.
   - P3 zemin: karda WCAG oranı ≥3:1; ot ve toprakta ΔE ≥0,10.
   - P4 bulanık sınama: Kışlak, 16 `Folk` + 40 kukla, 33 m ve 44 m, altı ışık durağı. Kare 1/8'e iner, pelerin lekesi çevre ortalamasından ΔE ≥0,06. Kareler `docs/research/mete-shots/`.
   - P5 boyut: leke 33 m'de ≥26 × 47 px, 44 m'de ≥20 × 35 px. Üst gövde alt gövdeden açık.

   Geçemeyen renk paletten çıkar. Mete'yi kurtarmak için çizgi, halka, ikon eklenmez (`gorsel-dil.md`). [kurgu]

5. **Ek istek 1, #63: Hayvan sınıfları.** `buildQuad(spec, detail)`, `src/character/animal.js`, `src/data/fauna-kinds.js` (8.6).

   | Kademe | Ağ | Üçgen | Çizim | Sahne sınırı | Gölge |
   |---|---|---|---|---|---|
   | T0 `Horse` | Var | 9,2k | 2 + iz | ≤2 | Evet |
   | T0 `Animal` | `SkinnedMesh`, 16 kemik | ≤4k; yüklü deve ≤4,8k (T0 yük ≤800, öneri 11; `survival.md` §4'ün ≤4k'sını yalnız bu aşar); küçük av ≤1,2k; kartal ≤600 | 1 + 1 | ≤8 | Evet |
   | T1 | `crowd_t1`, parça | ≤600 büyük, ≤360 küçük | Tür başına 1 + 1, ≤3 tür | ≤96 | En yakın 24 |
   | T2 | `crowd_t2`, tek ağ | ≤360 büyük, ≤200 küçük | Tür başına 1, ≤6 tür | ≤360 | Temas lekesi |
   | T3 | `card_t3`, 1024² atlas, 5 tür | 2 | 1 | ≤600 | Yok |
   | Kuş | `flock_bird` | ≤80 | 1 | ≤64 | Kartalda leke |

   En kötü kare ≈250k üçgen (eski satır 130k), ≤32 çizim, `Horse` hariç. `settlement.md` §17 «sürü» satırı buna göre büyür. Yükleme: tür başına ≤40 ms, T3 ≤124 ms (`army.md` ölçümü), hepsi `compileAsync`. Program +2 (≤92). VRAM +5,3 MB. VAT yok. [kurgu]

6. **Ek istek 1, #63, #12: Kademe uzaklıkları.** Bölüm 5 tablosu `fauna-kinds.js`'de `height` alanıyla hesaplanır, sabit metre yazılmaz; `resScale` ve kamera değişince doğru kalır. Kedi ve küçük av T0'dan sonra doğrudan kaybolur (≥14 px). [kurgu]

7. **Ek istek 1, #29, #39, K3 ile çelişki: Sürü sınırları.** K3 «ana kampta hayvan ≤6» iskeletli hayvan içindir. **Öneri: söz «iskeletli hayvan ≤6» olur.** Serbest Gez'de menü kadrajı dışında T2 sürü serbesttir; `campLife.menuPose(true)` gizler, `menuDiff` 0 kalır.

   | Tür | Yerleşim, otlak | Kafile, kervan | Ana kamp |
   |---|---|---|---|
   | Koyun, keçi | ≤300 (keçi ≤60, ayrı ağ) | ≤20 | ≤40 |
   | Sığır | ≤40 | Araba çifti ≤12 | 0 |
   | At | ≤60 | ≤20 | Doru, Akbulut, araba atı |
   | Deve | ≤24 | ≤16 | 0 |
   | Köpek | T0 ≤2, T1 ≤6 | ≤2 | ≤1 |
   | Geyik, ceylan | ≤40 | | Maral ≤2 |
   | Kurt | T0 ≤4, T1 ≤8 | | 0, yalnız `wolf_howl` |
   | Kuş | Karga ≤64, kaz ≤32, kartal ≤2 | | Karga ≤16 |

   Sayılan sürü görünenden büyüktür (K24: hane başına 35 koyun). **Görünen:** `n ≤ 120 ? n : min(300, 120 + (n − 120) × 0,06)`. 3.150 koyun ≈300 görünür. [kurgu]

8. **Ek istek 1, #27: Yürüyüş uygulaması.** `fauna-kinds.js` her tür için kütle ve `k` taşır; `L(v)` bölüm 4 tablosundan parçalı doğrusal okunur. Faz tablosu bölüm 4. T0'da IK, T1 ve T2'de `aGait`. T2'ye `aPose.x` (otlama) eklenir; `army.md` §7.3 tablosu güncellenir. Kabul: düz zeminde T0 ≤2 cm, T1 ≤6 cm kayma; `__tanhu` ile ayak izi ölçümü. [kurgu]

9. **Ek istek 1, #12: Kuşlar.** Yükseklik ≈6–11 m (§7); `kartal` gerçek irtifa kipinde yalnız gölge lekesi ve `eagle_cry`. Kartal halkası r ≈40 m, 13,5 m/sn; karga 12 m/sn; çırpma sıklığı bölüm 7. 150 m'de solar: ≤8 px kuş boya filtresinde kaybolur. Karga ve kaz ürkünce toplu havalanır. Görev ve hikâye bağları `fauna.md`'nindir. [kurgu]

10. **Ek istek 1, #52: Animasyon ve ses kancaları.**

    | Kanca | Üreten | Sınır | Ses (`audio.md`) |
    |---|---|---|---|
    | `anim:footfall` | T0, T1 ≤40 m, faz sınırı | Karede ≤6 | `hoof_walk`, `hoof_trot`, `hoof_gallop`; yeni `paw_step`, `camel_step` |
    | `herd:loop` | Sürü merkezi | Sürü başına 1 `PannerNode`, erim 60 m | `herd_flock`; yeni `cattle_low`, `camel_groan` |
    | `anim:call` | Ürkme, çağrı | 4–9 sn'de bir, ≤2 eşzamanlı | `sheep`, `dog_bark`, `wolf_howl`, `crow`, `eagle_cry`; yeni `goat_bleat`, `deer_bark`, `goose_honk` |
    | `anim:wing` | Havalanış | Sürü başına 1 | Yeni `wing_flap` |

    Durumlar: dur, otla, bak, yürü, tırıs ya da yan yürüyüş, dörtnal, yat (deve üç evrede çöker), düş. Düşüş T0'a geçer; kan yok, toz var (`survival.md` §4). Yeni ses ≈0,6 MB, yalnız o zonda pişer. Sinema için tür başına `perform(state)`. [kurgu]

11. **#39, #48: Yük ve araba.** Gelen hanenin yüklü at ve devesi için tek ağda yük katmanı: `aLoad` köşe özniteliği, örnek başına `aLoadK` 0 ise köşeler çöker, çizim eklemez. T1 yük ≤240, T0 ≤800 üçgen; keçe rulosu ve kerege paketi `G_STOCK` biçimleri. `yurt_kit` 59 Yük, bir keçe araba ya da iki devedir, `pack_camel` 30 Yük (`economy.md` §2.8): görünüşte iki deveye bölünür, biri kerege ve sırık, biri keçe ve ip. Gerçek deve 170–250 kg taşır. [kaynak: [Bactrian camel](https://en.wikipedia.org/wiki/Bactrian_camel)] **Çelişki:** `hayvanlar.md` öneri 6 `pack_camel`'i 60 Yük ister, tek deve tek yurt. Karar verilene dek bu belge K24'ü (`economy.md` E24-7, iki deve) izler; 60 kabul edilirse görünüş tek deveye iner, yük ağı değişmez. Yükü olan yüklü gelir, olmayan ister (cevap 39). Araba çekişi at ya da öküz; T1 boyunduruk +60 üçgen, `travel.md` §3.3 koşumuyla. [kurgu]

12. **#50: Mete sınama listesi.** Önce `tools/prepare-mete.mjs`'e adım: pelerin köşelerine `_CAPE` özniteliği (`dye` maskesi, z <0,09, y <1,0; `cp` 0..1), uyluk ağırlığı kalçaya taşınır. +≈0,1 MB. Sonra 8.8'de:

    | # | Sınama | Geçer |
    |---|---|---|
    | M1 | Yükleme, `renderer.info`, Mete + iz + gölge | 60,6k × 3, 3 çizim |
    | M2 | Kamp ve Kışlak, altı ışık durağı, kare klasörü | Pelerin mavi, yüz okunur, koyu yanma yok |
    | M3 | Boya filtresi, 33 m, 44 m, `eyes` 16 m | Yüz ve omuz lekesi kalır |
    | M4 | `METE_HOSTAGE`, `plate`, `tunic`, kuşak boyası | Maske taşması yok |
    | M5 | Yürüyüş, koşu, geri adım, 6 yön | Etek bacak arasından ayrılmaz |
    | M6 | Sürüş: pelerin ve at gövdesi | Hesapla ≤%3 köşe, ≤2 cm; kare doğrulaması |
    | M7 | `uRide` 0→1, binme ve inme 0,3 sn | Sıçrama yok |
    | M8 | Dörtnal 10,5 m/sn, `uTrail`, 20 fps | Titreme yok; yay yarı ömrü 0,2 sn |
    | M9 | Kalça eyer noktası (`seatHeight` 1,007) | ±1 cm |
    | M10 | Diz ve kaval, at örtüsü | Giriş ≤1 cm |
    | M11 | Yürüme ve koşu ayak kayması (`LeftToeBase`) | 33 m'de ≤6 cm |
    | M12 | Taban ve zemin; Tanhu 3 payları −1,5 ve −3 cm | ≤2 cm |
    | M13 | `armMode: 'bow'`, sadak, sırt silahı yuvaları | Pelerin yayı örtmez |
    | M14 | Çan `LeftFoot`, çetele `Hips` yuvaları (`act1.md` §3) | Yerinde, ölçek ×100 doğru |
    | M15 | `benchK` gerçek araba sırası | Açık satır kapanır (`contract-requests.md` 2.1; satır bu işi 10.5'e verir, 8.8'de koşulmaz) |
    | M16 | İz (`ghost`) atta ve ağaç arkasında | `aCape` izde de var |
    | M17 | Gölge | Fark küçük, kabul; `customDepthMaterial` gerekirse |
    | M18 | Oluşturucu ve oyun aynı renk | Öneri 3, P1–P5 |

    Bu liste Yol Haritası'na taşınır, `gorsel-dil.md` açık sorusu kalkar. [kurgu]

13. **#50: Üzengi.** `Horse({ stirrups })` seçeneği; I. Perde ve sonrası `false`, menü atları `true` kalır (`menuDiff`). Serbest Gez'in atı menüdekiyle aynı ağdır, orada kalır. `progression.md` §16.1 #8 de «üzengi yok» der; menü ağı tek istisnadır. Biniş pozunda ayak zaten sarkar (`rig.js` `ride`), poz değişmez. Kullanıcı isterse üzengi her yerde kalır: küçük bir dönem hatasıdır. [kurgu]

14. **Bebeklik kararı, #2, #12: Küçük Mete.**
    - **Model.** `METE_CHILD_LOOK` (`character/looks.js`): `child: true`, `profile.rootScale` 1,0 (yeni `mete_child` satırı), `hairStyle: 'topknot'` ve tunç bağ, ten, saç, göz oluşturucudan. Topuz Hanshu 54'teki 胡服椎結'den gelir (Li Ling ve Wei Lü'nün Hun kılığı), Tanhu 1'in Kiyük'ünden alınmaz. [kaynak: [Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054); çocuğa uygulamak çıkarım] `coat` ham keçe, `trim` `#7a2a22`, `cape: { color: boya, len: 0,34 }`. ≤18k üçgen, 3 çizim + 3 gölge + 3 iz (`Çocuk` ile aynı, `architecture.md` §7).
    - **Sıra.** Oluşturucu çocukluk sahnesinden önce açılır, yoksa renkler taşınmaz. Hikâye belgesi buna göre yazılır.
    - **Koyun binişi.** `bovid_s` T0 `MountLike` yüzü verir: omuz 0,80, oturma ≈0,86 m, hız ≤1,6 m/sn, tırıs 2,4. `CHILD.ride` at gövdesine göredir; yeni `rideSheep` (uyluk −0,35, ±0,7). Çocuğun ayağı yerden ≈27 cm yukarıda kalır. Hesaptır, sınanacak.
    - **Oynanış.** `toy_bow` ile karga ve tarbagan; nişan öğretilir (`survival.md` §4). Kamera `child` 26 m, yakın çekim `eyes`.
    - **Bebek.** `swaddle` eşyası ≤400, beşik ≤900; annenin `carry('swaddle')` duruşu `gestures/`'a. Yüz `paintChildFace` 128 px; yakın plan kısa tutulur.
    - **Dünya.** Ana kampın dışında, II. Perde otlak arazisinden kesilir; K6, K7 ve menü etkilenmez. Bütçe öneri 1. [kaynak Shiji; kalan kurgu]

15. **#32, #31: Yurt parametreleri.** `structures.md` §3.5 ve `settlement.md` §7.9'a eklenir.

    | Boy | `scale` | Yakın hazır ayar | Üçgen | `kanat`, `uuk` | Uzak | İç |
    |---|---|---|---|---|---|---|
    | Küçük | 0,7 | `winter` | ≤28k | 4, 24 | `closed` × 0,7 | `ev` ≤6k |
    | Hane | 1 | `winter` | ≤34k | 4, 24 | `closed` | `ev`, `bolmeli`, `otaci` ≤12k |
    | Otağ | 1,4 | `hero` | ≤129k | 6, 48 | `closed` × 1,4 | `han`, `otag` |

    **Kurallar.** Kök ölçeği iç eşyayı küçültmez: `k.put` konumu `R`'den gelir, eşya ×1 kalır. Bugün `def.scale` köke uygulanır (`structures.md` §3.5); iç eşya kökün çocuğuysa `1 / scale` ile sarılır. Kapı ölçekle 1,34 × 2,0 m olur, Mete (1,82 m) geçer. `Room.floorAt` ve nav şekli ölçekle çarpılır (§3.5). Hane yurduna sade `ev` içi eklenir: tek oda, ocak, kazan, keçe döşek, sandık (≤6k). `otag` iç tasarımının adı «Huzur Yurdu / Audience Yurt» olur, «Otağ» yalnız yapı adıdır (#31). Örnek özniteliği `aShape` (`rise`, `wallK`, `bulge`, `crownR`) ve `aTone` (palet satırı, is yüksekliği), `yurt_field` programında; program eklemez. Zon başına ≤2 gövde biçimi. Malzeme, emek, can `labour-model.json` ve `economy.md`'de kalır; bu öneri yalnız görünüştür, K21'e dokunmaz. Yurt süresi eğrisi (`register.md` Karar Bekleyenler 1: 60 / 45 / 33,75) ayrı işlenir. [kurgu]

16. **#32: Kültür paleti.** Hepsi bant kuralına uyar. Biçim dış gövdedir, iç tasarım `rug` paletiyle değişir.

    | Kültür | Gövde | `wallK`, `rise` | Keçe | Bant, ip | Etiket |
    |---|---|---|---|---|---|
    | Hun | Kerege; yoksulda kaburgalı | 1, 1,0 (kaburga 0) | `#d9cfba` | `#7a2a22`, `#5a4632` | Kubbe [kaynak: 穹廬], kerege [kurgu, K21], renk [kurgu] |
    | Yüeçi | Kerege, yüksek | 1,1; 1,2 | `#c9b896` | `#6b2130`, `#c9a24f` | Palet `act1.md`, biçim [kurgu] |
    | Saka | Araba kabini + kerege | 0,9; 1,0 | `#4a4038` | `#a88445`, `#3b2a1e` | Kara keçe [çıkarım: Pazyryk, kimlik belirsiz], kalan [kurgu] |
    | Vusun | Kerege, basık | 0,9; 0,85 | `#b8b3a0` | `#4a5240`, `#6a5f52` | Sözcük [kaynak], renk [kurgu] |
    | Çiang | Alçak kara çadır (`TentField`) | Yok | `#2f2a26` | `#8a6a3a` | [kurgu], kaynak bulunamadı |
    | Qin, Han | Dikdörtgen sırt çadırı (`KitField`) | Yok | `#8d8674` | `#2a2320`, `#8f2f22` | Pigmentler [kaynak], biçim [kurgu] |

    Qin heykellerinde yeşil, kızıl (zinober), bordo, pembe, gök mavisi (azurit), ak ve yapay Çin moru izleri var. Mor ile rütbe arasında bağı bu kaynakların hiçbiri kurmaz; yalnız karanın Qin hükümdarlarınca yeğlendiği söylenir. [kaynak: [China Highlights](https://www.chinahighlights.com/xian/terracotta-army/color.htm), [Sixth Tone](https://www.sixthtone.com/news/1004855/the-new-face-of-the-terra-cotta-warriors), [Terracotta Army](https://en.wikipedia.org/wiki/Terracotta_Army)] Ayrılmış bant (öneri 3) Qin'in gök mavisini C <0,05'e indirir: bilerek yapılan bir sapmadır. [kurgu] Pazyryk kırmızısı fermente yünle yapılmış ileri bir boyacılıktır. [kaynak: [Scientific Reports 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC7970846)] Çadırda üç görünüş: `tent_house` açık keçe, `tent_ten` koyu ve sıralı, `tent_qiang`; emek, malzeme ve can aynı. [kurgu]

17. **#15, #16, #49, #51: Işık ve hava sınaması.** P1 ve P4 aynı kare klasörünü kullanır: 8.9 ışık durakları, 9.4 hava. Altı durak × Mete × kar ve ot × iki yakınlaştırma. Ekran yağışı kartları aynı oturumda sınanır. Ölçüm işi Yol Haritası'nda tek satırdır. [kurgu]

18. **#15, #16, #64: Yol Haritası işleri.** 8.6: `animal.js`, `fauna-kinds.js`, T0, üç tür (koyun, köpek, geyik), `check-palette.mjs`. 8.8: Mete adımı, M1–M18, öneri 3. 9.x: T1, T2 üreticisi hayvana açılır, kuş, kuyruk ve rüzgâr. 9.9, 13.x: `aShape`, `aTone`, `ev`, kültür paleti. Çocukluk sahnesi: Faz 11 öncesi dikey dilimden sonra (K11). `contract-requests.md`'ye satır satır yazılır. [kurgu]

## Belirsizlikler

- K27 ölçümünde üçüncü yurdun hangi aşamada olduğu yazılmıyor; hesap «yok» varsayar. Yanlışsa kamp bütçesinde 0,25M pay kalır. Ölçülecek.
- `renderer.render` CPU süresi ölçülmedi. 60 fps iddiası buna bağlıdır. Gizli bölme sayısı kare süresi için güvenilmez.
- Masaüstü RTX 3060 karşılaştırması alınamadı, yalnız mobil sürüm var. Bu turun 200 web arama hakkı doldu; daha fazla doğrulama sonraki turda yapılabilir.
- Renk tablosu düz albedo üstündedir. `paintMaterial`, ton eşleme ve Kuwahara sonucu değiştirir; P4 kesin karardır. Zemin renkleri yarımküre ışığının `ground` değerinden yaklaşıktır.
- Sürüş hesabı yaklaşıktır: gövde elips, kaval ve örtü yok, retarget hizalaması yok. M6 kesin karardır.
- `CHILD` boyu ve baş oranı eklemden hesaplandı, ağ ölçülmedi. `childHeadPoint` ölçüsü sınanacak.
- Hun çadırının iskeleti bilinmiyor: kaburgalı ya da kafesli. Oyun K21 ve `structures.md` gereği kerege kullanır; dönem açısından tartışmalıdır, Destan Kitabı'nda not edilebilir.
- Noin-Ula ve Sampul dokuma renkleri için kaynak bulunamadı; Hun, Saka ve Yüeçi paletleri bu yüzden kurgu ya da oyunun kendi paletidir. Çiang çadırı için kaynak bulunamadı.
- Koyun, sığır, ceylan ve ayı omuz yükseklikleri kaynaksız yaklaşık değerlerdir. `fauna.md` kaynaklı sayı verirse tablo onu izler.
- Alexander ve Jayes (1983), Strömbom (2014), Hecker (Spore, 2008), Reynolds'ın kendi sayfası bu oturumda açılamadı; yalnız ikincil özetler görüldü. Dota 2 kılavuzunun tam metni açılmadı, arama özetinden alındı.
- Üzengi: görünüm ile menü değişmez kuralı çakışır. Serbest Gez atının kaderi kullanıcı kararıdır.
- Cevap 12 yakınlaştırma üst sınırını büyütürse (bugün 44 m) kademe ve bütçe yeniden sınanır.
- Hava ve uzun süreli sürü davranışı sayıları denenmedi, oyun içinde ayarlanır.
- **Şüpheci doğrulaması (2026-11-04).** Arama bütçesi dolu koştu, yalnız doğrudan sayfa açıldı. Açılıp doğrulanan: Heglund Tablo 2–3, Stronach, Mitchell, Jakobsen, WHO, GPU Gems, Ballerini, Raichlen, Sci. Rep. 2021, Shiji 110, Hanshu 5, 54, 96B, Game Developer, Steam, UL, Rosen, Holden, üç forum yazısı, MDN, BatchedMesh. Açılmadı, sayı doğrulanmadı: nanoreview, Applied Sciences 2024, SCA 2011, Kovar 2002, King 2012, Ginelli 2015, Dota 2 kılavuzunun gövdesi. Oklab, Machado, WCAG'a yeniden bakılmadı.
- **Yerel sayılar bağımsız hesapla tuttu.** `mete.glb` 60.592 üçgen, 109.337 köşe, 24 kemik, kalça 1,007; `dye` >0,5 için 27.993 köşe, 13.518 üçgen (27.900 ve 13.633'ten farkı eşik ve örneklemedir), `lum` 0,0459, kalça altı 10.248 köşe, %94,8 uyluk. Renk tablosunun kar, ot, toprak sütunları ile kod bulgusu da aynı çıktı. Sürüş pozu hesabı (%41, 32 cm) yeniden koşulmadı.
- **Tanhu 1 ile ortak kalanlar (cevap 5).** «Tek soğuk vurgu» ve «Rehine Kaftanı» (§10), «dört rüzgâr» (`army.md` `four_winds`; Tanhu 1'de bir Umay satırı), Hun kızıl-kahve ve Yüeçi bordo-hardal çifti, «gündüz kar sıcak, gölge mavi» (`act1.md` §1). Bu belgenin önerileri bunlara dayanmaz; değişiklik o belgelerin sahiplerinindir.
- `hayvanlar.md` §3'ün at satırı aynı 142–152 cm'yi ve ×1,18'i taşır; bu belgenin §3'üyle birlikte düzeltilmelidir.

## Kaynaklar

**Proje.** [decisions.md](../design/decisions.md) (K3, K21, K27); [register.md](../design/d3/register.md); [architecture.md §7](../design/architecture.md); [army.md §5, §7](../design/army.md); [structures.md §3, §13](../design/structures.md); [settlement.md §7.9, §17](../design/settlement.md); [act1.md §1, §3, §15](../design/act1.md); [survival.md §4](../design/survival.md); [time.md §5.4, §8.4](../design/time.md); [code-audit.md §g](code-audit.md); [menu-spec.md §8](menu-spec.md); `src/character/horse.js`, `mete.js`, `folk.js`, `rig.js`, `actor.js`; `src/data/gear.js`; `src/ui/creator/rows.js`; `src/game/camera-rig.js`; `public/models/mete.glb`.

**Birincil metin.**
- [Shiji 110, Wikisource](https://zh.wikisource.org/wiki/史記/卷110)
- [Hanshu 96B, Wikisource](https://zh.wikisource.org/wiki/漢書/卷096下), [Hanshu 5](https://zh.wikisource.org/wiki/漢書/卷005), [Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054)

**Hakemli ve akademik.**
- [Heglund, Taylor 1988, Speed, stride frequency and energy cost per stride, J. Exp. Biol. 138](https://www.originalwisdom.com/wp-content/uploads/bsk-pdf-manager/2019/10/Heglund-and-Taylor_1988_Speed-and-stride-frequency-and-energy-cost-per-stride-how-do-they-change-with-body-size-and-gait.pdf), yayıncı: [DOI](https://doi.org/10.1242/jeb.138.1.301)
- [Raichlen ve ark. 2013, Dynamic Similarity yeniden bakış](https://pmc.ncbi.nlm.nih.gov/articles/PMC3798186/)
- [Ginelli ve ark. 2015, PNAS](https://pmc.ncbi.nlm.nih.gov/articles/PMC4611628)
- [King ve ark. 2012, Current Biology](https://discovery.ucl.ac.uk/id/eprint/1366736/)
- [Ballerini ve ark. 2008, PNAS](https://pmc.ncbi.nlm.nih.gov/articles/PMC2234121/)
- [Pennycuick 1990, J. Exp. Biol. 150](https://journals.biologists.com/jeb/article/150/1/171/5695/Predicting-Wingbeat-Frequency-and-Wavelength-of), [Pennycuick 1996, J. Exp. Biol. 199](https://journals.biologists.com/jeb/article/199/7/1613/7344/Wingbeat-Frequency-of-Birds-in-Steady-Cruising)
- [Kovar, Schreiner, Gleicher 2002, Footskate cleanup](https://doi.org/10.1145/545261.545277)
- [Perceptual evaluation of footskate cleanup, SCA 2011](https://doi.org/10.2312/SCA/SCA11/287-294)
- [Mitchell, Francke, Eng 2007, Illustrative Rendering in Team Fortress 2](https://www.cs.princeton.edu/courses/archive/fall07/cos597B/papers/mitchell-team-fortress.pdf)
- [Machado, Oliveira, Fernandes 2009, CVD Simulation](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)
- [Stronach, On the Antiquity of the Yurt, The Silk Road](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/On-the-Antiquity-of-the-Yurt.pdf)
- [Scientific Reports 11:5141, 2021, X-ray microscopy of Siberian Iron Age textile dyers](https://pmc.ncbi.nlm.nih.gov/articles/PMC7970846)
- [Applied Sciences 2024, baş boy oranı](https://doaj.org/article/2799e97f4cdd49a4a39a0c26522def26), bu doğrulamada açılmadı

**Kurum ve teknik.**
- [WHO boy için yaş, 5–19 yaş](https://www.who.int/tools/growth-reference-data-for-5to19-years/indicators/height-for-age)
- [MDN WebGL best practices](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices)
- [Three.js InstancedMesh](https://threejs.org/docs/pages/InstancedMesh.html), [BatchedMesh](https://threejs.org/docs/pages/BatchedMesh.html)
- [GPU Gems 3, Bölüm 2](https://developer.nvidia.com/gpugems/gpugems3/part-i-geometry/chapter-2-animated-crowd-rendering)
- [Oklab, Ottosson](https://bottosson.github.io/posts/oklab/), [CSS Color 4](https://www.w3.org/TR/css-color-4/)
- [Steam donanım anketi, Ekim 2026](https://store.steampowered.com/hwsurvey/videocard/)
- [WCAG 2.1, Non-text Contrast](https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html)
- [UL, M1 Pro 3DMark](https://benchmarks.ul.com/hardware/tablet/MacBook+Pro+16%E2%80%9D+(M1+Pro,+2021)+review)

**Oyun yapımı.**
- [Rosen, GDC 2014, An Indie Approach to Procedural Animation](https://www.gdcvault.com/play/1020583/Animation-Bootcamp-An-Indie-Approach)
- [Holden, Spring-It-On](https://theorangeduck.com/page/spring-roll-call)
- [Jakobsen 2001, Advanced Character Physics](http://www.cs.cmu.edu/afs/cs/academic/class/15462-s13/www/lec_slides/Jakobsen.pdf)
- [How Valve makes art to enhance gameplay, Game Developer](https://www.gamedeveloper.com/art/in-depth-how-valve-makes-art-to-enhance-gameplay)
- [Dota 2 Workshop Character Art Guide](https://help.steampowered.com/faqs/view/0688-7692-4D5A-1935)
- [Three.js forum, tek çizimlik kalabalık](https://discourse.threejs.org/t/one-draw-call-massive-crowd-performance-engineering-in-three-js/89928), [VAT](https://discourse.threejs.org/t/playback-the-animation-of-many-low-poly-models-as-they-are-moved-around/42205), [doldurma hızı](https://discourse.threejs.org/t/performance-issue-due-to-fill-rate/9019)

**Başlangıç noktası, ansiklopedik.**
- [Mongolian horse](https://en.wikipedia.org/wiki/Mongolian_horse) (boyu çelişkili, yalnız renk için), [Cheval mongol](https://fr.wikipedia.org/wiki/Mongol_(cheval)), [Mongolisches Pferd](https://de.wikipedia.org/wiki/Mongolisches_Pferd), [Bactrian camel](https://en.wikipedia.org/wiki/Bactrian_camel), [Red deer](https://en.wikipedia.org/wiki/Red_deer), [Altai wapiti](https://en.wikipedia.org/wiki/Altai_wapiti), [Wolf](https://en.wikipedia.org/wiki/Wolf), [Golden eagle](https://en.wikipedia.org/wiki/Golden_eagle), [Fat-tailed sheep](https://en.wikipedia.org/wiki/Fat-tailed_sheep), [Goitered gazelle](https://en.wikipedia.org/wiki/Goitered_gazelle), [Stotting](https://en.wikipedia.org/wiki/Stotting), [Horse gait](https://en.wikipedia.org/wiki/Horse_gait), [Gait](https://en.wikipedia.org/wiki/Gait), [Boids](https://en.wikipedia.org/wiki/Boids), [Stirrup](https://en.wikipedia.org/wiki/Stirrup), [Saddle](https://en.wikipedia.org/wiki/Saddle), [Pazyryk culture](https://en.wikipedia.org/wiki/Pazyryk_culture), [Pazyryk](https://en.wikipedia.org/wiki/Pazyryk_carpet), [Terracotta Army](https://en.wikipedia.org/wiki/Terracotta_Army), [Isatis tinctoria](https://en.wikipedia.org/wiki/Isatis_tinctoria)
- [nanoreview](https://nanoreview.net/ru/gpu-compare/geforce-rtx-3060-mobile-vs-apple-m1-pro-gpu), bu doğrulamada açılmadı
- [China Highlights, Terracotta renkleri](https://www.chinahighlights.com/xian/terracotta-army/color.htm), [Sixth Tone](https://www.sixthtone.com/news/1004855/the-new-face-of-the-terra-cotta-warriors), [simplydifferently, yurt](https://simplydifferently.org/yurt?page=1), [ders notu, çocuk oranı](https://www.msnucleus.org/membership/html/k-6/lc/humanbio/2/lchb2_3a.html)
