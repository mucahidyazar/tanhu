---
title: Obadan Hanlığa
order: 10
status: tasarim
summary: 'Mete II. Perde''de babasının közüyle kendi ocağını yakar; yerleşim beş kademede Tanhu Avlusu''na büyür, V''te Surlu ya da Göçer yola ayrılır, ordu bir gün ötedeki ayrı bir ovada yaşar.'
sources:
  - docs/design/decisions.md
  - docs/design/settlement.md
  - docs/design/d2/settlement-model.json
  - docs/design/d2/core.md
  - docs/design/economy.md
  - docs/design/story.md
  - docs/design/time.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Oyuncu II. Perde'de Mete olarak güneyin payına gider ve babasının ateşinden Köz Kabı'yla taşıdığı közle ilk ocağını yakar. O ocak beş kademede büyür: Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu. Büyüyen hep aynı yerdir: yerleşim göçmez, yalnız sürü mevsimle otlak değiştirir. V. Perde'de avlu bir kez, geri alınmadan, Surlu ya da Göçer yola ayrılır. Ordu yerleşimin içinde değil, bir günlük yol ötedeki Islık Alanı'nda yaşar. Kural [K23](/docs/source/design/decisions#k23)'tür, ayrıntısı [settlement.md](/docs/source/design/settlement)'dedir.

> [!NOT]
> «Yerleşim yeri sistemimiz olacak, obamızı büyütüp kağanlığımızın hanlığımızın merkezi haline getirebileceğiz»

> [!NOT]
> «Tabi yerleşim yeri veya askeri kamp kurmadan önce act 1 deki tutsaklık perdesini bitirmemiz gerekecek yani act 1 den önce bazı şeylerin kısıtlı olması lazım»

Tasarım iki notla da aynı yöndedir: I. Perde'de yerleşim ve ordugâh kurulmaz, büyüme II'den VI'ya dek perdelere yayılır (K23). Notundaki «kağanlık» ve «hanlık» için cevabın şuydu:

> [!NOT]
> «Tanhu diyelim»

Oyuncuya unvan «Tanhu», ülke «Hun Tanhuluğu», merkez «Tanhu Avlusu» denir; «kağan» ve «hanlık» oyuncu metninde geçmez ([K34](/docs/source/design/decisions#k34)). Destan Kitabı bir kez 撐犁孤塗 «Göğün Oğlu» unvanını yazar. Bu sayfanın adındaki «hanlık» yalnız belgelerin alan adıdır.

## Ne zaman açılır

I. Perde hikâyede yerleşim vermez; yerleşimin altyapısı yalnız geliştiricinin kum havuzunda sınanır (K23). Kışlak Yeni Yurdu tek bir şantiyedir. Ana kampın (Göl Obası) Serbest Gez'i değişmez: orada oyuncu Çocuktur (K6).

II. Perde «Ok Neyi Gösterirse» 1–15 Haziran MÖ 209'dur. Açılış I. Perde sonu sahnesinin (K7) devamıdır: pay ve Köz Kabı Tanhu Kampı'nda, uzak karedeki sinemada verilir ([K106](/docs/source/design/decisions#k106)); Mete ana kampta hiç oynanmaz. Denetim atlas yolunda başlar. Görevlerin metni, günleri ve kişileri [story.md §11.1](/docs/source/design/story#11-1-ii-perde-ok-neyi-gosterirse-where-the-arrow-points)'dedir; bu tablo yalnız yerleşime etkilerini verir.

| Sıra | Görev | Nerede | Yerleşime etkisi |
|---|---|---|---|
| 1 | Pay / The Allotment | Sinema: Tanhu Kampı, uzak kare, 1 Haziran 209 | [Teoman](/encyclopedia/teoman) Mete'ye güneyin payını ve tümeni verir. Takvim 11 Nisan'dan 1 Haziran'a Akan Kronik'le akar. Payın yeri atlasta belirir. |
| 2 | Kendi Ocağın / Your Own Hearth | Sinemanın sonu, sonra atlas yolu | Mete Köz Kabı'na babasının ateşinden köz alır, atına biner: denetim burada başlar. Ocak Yeri seçilir. Mete'nin yurdu ilk onlukla 8 elde 8,0 gerçek dakikada kurulur ([K50](/docs/source/design/decisions#k50)); hızlı kurma becerisi bu ilk yurtta henüz yoktur. Ocak közle yanar: **Ocak** kademesi. Göl Obası'nın [ozanı](/encyclopedia/bard) II'de gelir, III sonuna dek Mete'nin ocağında çalar ([K79](/docs/source/design/decisions#k79)); Köz Kabı'yla gelmez, yolu II'de yazılır (K106). |
| 3 | Islık Ordugâhı / The Whistle Camp | Islık Alanı, 2–3 Haziran | Onluğun iki çadırı, Talim Alanı, ilk talim: **Onluk Ateşi**. Eski Binbaşı [Dulongçi](/encyclopedia/dulongchi) on bini getirir. |
| 4 | Oba / The Clan Camp | Yerleşim, 4 Haziran'dan | Dört hane yurt yükleri, 5 günlük azıkları ve bahar kırkımlarının yarısıyla gelir; biri demirci [Dutu](/encyclopedia/dutu). [Lan Hatun](/encyclopedia/lan-hatun) Kâhya olur, kervan açılır: **Oba** kademesi. |
| 5 | Serbest Dolaşım | Her yer | Plan Kipi (`P`), Yerleşim Defteri, iş ataması, kervan. |

**Köz Kabı.** 48 oyun saati yanar, her kömür 24 saat uzatır, kapla 1 kömür verilir. Yol 2 gündür: oyalanan, közü yolda besler. Köz sönerse görev başarısız olmaz, ocak yerleşimin kendi ateşinden yakılır. Hangi ateşin yandığı bir bayrakta kalır (babanın közü ya da yerleşimin ateşi). II. Perde sonundaki darbe ve Sonsöz'ün Son Sayım kartı onu bir söz satırıyla okur; bedeli ve ödülü yoktur. Neden köz: yurt bir yapıdır, ocak bir soydur. Babasının ateşini taşıyan oğul perdenin sonunda o ateşin sahibini vurur; oyuncu bu çizgiyi kendi eliyle taşımış olur.

**Teoman'ın armağanı** (K23, [K48](/docs/source/design/decisions#k48)): Mete'nin yurt yükü, bir keçe araba, ≈30 at eşdeğeri sürü (60 koyun, 10 keçi, 16 at, 4 sığır), sürünün bahar kırkımı (60 yün), 6 demir külçe, ≈15 günlük azık (400 darı ve 30 kak, ≈217 öğün) ve Mete'nin kesesine 24 kabuk. Yurt yükü keçe arabadadır (60 Yük'lük arabada 59 Yük); yün, demir ve azık (85 Yük) sürünün üç Yük Atı'ndadır.

Neden bu kadar: kırkım 14 Mayıs'ta bitmiştir, Haziran'daki perdede yeni yün çıkmaz; Ocak ve Oba'nın ≈60 keçesi armağanın yününden, Oba hanelerinin getirdiği kırkımdan ve pazarcıdan gelir. Külçe yalnız Demirci Ocağı'nda yapılır, demirci de Oba'yla gelir: altı külçe Ağaç Atölyesi'ne ve demirciden önce kurulan iki yurdun bosağasına yeter. Yiyecek kuralları ambardaki günü okur (Çekim ≥5 gün, Oba kapısı ≥10 gün): azıksız bir açılış kıtlıkla başlardı.

```varlik
teoman, ember_pot, yurt_kit, cart_felt
```

**İlk aileler** üç hanedir: onluk eri [Şiuşun](/encyclopedia/shiushun)'un ailesi, dülger [Ruodi](/encyclopedia/ruodi)'nin hanesi ve Mete'nin anası Lan Hatun'un hanesi ([K37](/docs/source/design/decisions#k37)). Üçü de yüksüz gelir ve İsteyen Hane kartını öğretir: [Haneler ve Kâhya](/docs/settlement/households#hane-nasil-gelir).

**Ocak Yeri** oyuncunun ilk kalıcı kararıdır: Seki, Dirsek ya da Kuytu ([Plan Kipi](/docs/settlement/plan-mode#ocak-yeri)). Payın burası oluşu tasarım tercihidir: Shiji 110 payın yerini yazmaz, avlunun yerini yazar (Dai ve Yunzhong'a bakar); büyüme aynı yerde olur.

## Beş kademe

Hane sütunu kademenin sonunda beklenen hane ve hane tavanıdır. Kademe günü K24'ün hedefidir (oyun günü; 1 oyun günü 60 gerçek dakika, [K67](/docs/source/design/decisions#k67)); yanında 2026-11-04 resmî koşusunun sonucu durur (`econ-sim --strict`, 0 işaret; [K49](/docs/source/design/decisions#k49), [economy.md §10.6](/docs/source/design/economy#10-6-kademeler)).

| Kademe | Perde | Hane (son / tavan) | Çıkış koşulu | Açtığı yapılar | Kademe günü (hedef / koşu) |
|---|---|---|---|---|---|
| **Ocak** / Hearth | II | 3 / 6 | Mete'nin yurdu bitti (aşama 7), ocak yanıyor | Küçük Yurt, Hane Yurdu, çadır, Kamış Kulübe, Ağıl, Çit, At Hattı, Kurutma Sırığı, Ambar Çukuru, Keçe Avlusu, Sancak ve Fener Direği | 2–5 / 2,2 |
| **Oba** / Clan Camp | II | 10 / 12 | Konutta ≥5 hane, ≥3'ü yurtta (Küçük Yurt yurt sayılır); Keçe Avlusu, Ağıl, At Hattı, Ambar Çukuru; yiyecek ≥10 gün | Ağaç Atölyesi, Ahır, Ambar Yurdu, Sundurma, Sepi Yeri, Demirci Ocağı, Fırın, Keçe Araba | 2,5–7 / 3,0 |
| **Boy Yurdu** / Lineage Seat | III | 22 / 25 | III. Perde; ≥10 hane; Ahır, Ambar Yurdu, Demirci Ocağı, Ağaç Atölyesi, Sundurma | Tanhu Otağı, Elçi Yurdu, Gök Direği, Toy Alanı, Tahıl Ambarı, Okçu Yurdu, Gözcü Kulesi, Takas Yeri, Gözcü Konağı, Yüksek Teker; IV'ten Kuşhane | 3–8 / 7,2 |
| **Toy Yeri** / Gathering Seat | IV | 45 / 50 | IV. Perde; ≥22 hane; Tanhu Otağı, Elçi Yurdu, Gök Direği, Toy Alanı, Tahıl Ambarı, ≥1 Gözcü Kulesi; ortalama Gönül ≥50 | Hazine, Kuyu, Otacı Yurdu, Bey Otağı, Ordu Arabası | 4–9 / 4,6 |
| **Tanhu Avlusu** / The Tanhu's Court | V–VI | 80 / 90 | V. Perde; ≥45 hane; Hazine; ≥1 Kuyu; ortalama Gönül ≥55; yol seçildi | Seçilen yola göre, aşağıda | 4–12 / Surlu 8,1, Göçer 7,8 |

Bütün günler hedefin içindedir. Ocak'ın tavanı 6'dır: yüksüz gelen hikâye haneleri yeni geleni kilitlemesin diye. Resmî koşu kurmayı K21'in eski katsayısıyla ve sabit 4 elle sayar; [K50](/docs/source/design/decisions#k50)'nin yurt eğrisiyle günler 0,1–0,6 uzar (Boy Yurdu 7,8: üst uca 0,2 gün), hepsi hedefte kalır. Doğrulanacak: Kâhya'nın şantiye kuralıyla ([K80](/docs/source/design/decisions#k80)) ve şantiyenin günde `k(W) × 24` iş saatiyle yapılacak resmî koşu bu günleri ve aşağıdaki tabloyu yeniden basar ([Yol Haritası](/roadmap#item-econ-sim-run)).

**Neden bu adlar.** Ocak hem ateş hem soydur. Oba birkaç hanenin göçebe obasıdır. Boy Yurdu Mete'nin soyunun (Luandi) oturduğu yerdir: darbeden sonra avlu buraya gelir. Toy Yeri beylerin yıl başı toplandığı yerdir (Shiji 110: 小會單于庭). Tanhu Avlusu Shiji 110'un 單于庭'sidir. Taslaktaki «Ordu» ordugâhla, «Han Ordası» oyunun unvanıyla karışırdı ([K15](/docs/source/design/decisions#k15), K34); «hanlık» da oyuncu metninde geçmez. Adlar oyunun dilidir, dönemin sözcüğü değildir; Destan Kitabı bunu tasarım tercihi diye yazar.

**Ağaç Atölyesi Oba'da açılır** ([K52](/docs/source/design/decisions#k52)). Ocak'ta atölye yoktur, tündük Tanhu pazarcısından iki günde bir gelir. Dülger Ruodi ilk ailelerle gelir, atölyeyi Oba açılınca kurar. Plan Kipi'nde atölyenin kartı Ocak'ta kademe kilidiyle görünür: «Oba'da açılır.» / «Opens with the Clan Camp.»

Kademe yalnız yapı açmaz, iş de açar. Oyuncu payı, malzemenin Mete'nin kendi topladığı kısmıdır ve kademe büyüdükçe küçülür: Ocak'ta oyuncunun eli asıl motordur, Tanhu Avlusu'nda oyuncu karar verir, halk kurar.

| Kademe | Açtığı iş | Yapı emeği | Tek şantiye eşdeğeri | El-gün | Hazır yurt yükü | Oyuncu payı | Mete'nin dakikası (koşu / hedef) |
|---|---|---|---|---|---|---|---|
| Ocak | İş ataması: sürü, toplama, inşa, nöbet; onluğun azığını Azıkçı alır | 4,5 İG | 0,9 gün | 5,4 | 1 | %80 | 25,5 / ≤35 |
| Oba | Zanaat ataması, kervan, seferberlik; Kâhya'nın çadır yükü emri | 14,1 İG | 2,9 gün | 17,7 | 6 | %45 | 28,4 / ≤60 |
| Boy Yurdu | Divan | 26,1 İG | 5,3 gün | 33,6 | 12 | %25 | 35,8 / ≤60 |
| Toy Yeri | Toy Alanı'nda Avlu Toplantısı, armağan, Hazine | 42,0 İG | 8,6 gün | 51,7 | 22 | %12 | 26,6 / ≤50 |
| Tanhu Avlusu, Surlu | Yola göre yapılar; avluda Dailin Sayımı, VI'da Kurultay | 91,1 İG | 18,8 gün | 116,0 | 17 | %5 | 27,0 / ≤45 |
| Tanhu Avlusu, Göçer | Aynı | 54,9 İG | 10,6 gün | 66,4 | 17 | %5 | 24,9 / ≤45 |

İG iş günüdür: 1.440 İD; İD bir işçinin bir oyun dakikasıdır, bir İG tek işçiyle 60 gerçek dakika eder. **Tek şantiye eşdeğeri**, kademenin yapıları arka arkaya, her biri Kâhya'nın vereceği el tavanıyla kurulsa kaç gün süreceğidir: bir şantiye günde `k(W) × 24` İS işler, `k(W) = (4/3)^(min(W, 8) − 1)`; el-gün bunun emek bedelidir. El tavanı yurtta 8, Otağ'da 12'dir (katsayı 8'de durur). Eski sütun K21'in sabit 4 eliyle 1,3 / 4,1 / 7,6 / 12,2 / 26,5 / 16,0 gündü; K50'nin eğrisiyle sabit 4 el 1,9 / 6,0 / 11,0 / 17,7 / 38,4 / 23,2 gün ve 7,6 / 23,8 / 44,1 / 70,9 / 153,7 / 92,6 el-gün eder: sabit 4 el yurtta en pahalı ekiptir. Kâhya kuralının el başına verimi kademe ortalamasında 0,78–0,83'tür: yurtta 0,94, el tavanı 4–6 olan küçük yapıda 0,59–0,70. Kuralın kendisi: [Haneler ve Kâhya](/docs/settlement/households#isler-ve-kahya).

**Gerçek süre bu sütun değildir.** Şantiyeler paralel yürür, halk büyür: Oba'nın 14,1 İG'si 6 hane ve 15 erin elinde ≈1,5 günde biter. Asıl sınır malzeme zinciri (yurt başına ≈10 İG toplama ve zanaat) ve gelen hanedir. Boy Yurdu en sıkışık kademedir: güzde ot biçimi hane emeğinin ≈%30'unu alır, Otağ, Gök Direği, Takas Yeri ve 12 yurt aynı perdededir. Hangi yapının neye mal olduğu: [Plan Kipi](/docs/settlement/plan-mode). Bütün denge tabloları: [Ekonomi Dengesi](/docs/economy/balance).

### Kademe kuralları

- Boy Yurdu III'ten, Toy Yeri IV'ten, Tanhu Avlusu V'ten önce olmaz. Mevsim atlaması kademe atlatmaz.
- Kademe düşmez. Hane ya da yapı kaybı kademe adını almaz; ama kademenin verdiği iş yapının ayakta olmasına bağlıdır: yanmış Otağ'da Avlu Toplantısı yapılmaz, kademe yine Toy Yeri'dir.
- Perde arasında Kronik haneyi perdenin açılış tabanına çıkarır (III 10, IV 22, V 45, VI 80), üstündekini düşürmez: zayıf bir II. Perde III'ü kilitlemez ([Kronik](/docs/settlement/court#kronik)).
- Yer adı kademeyle yazılır: II'de «Mete'nin Payı», III'ten «Tanhu Ordusu», yanında kademe: «Tanhu Ordusu · Boy Yurdu».

| Kademe | Kademe kartı | EN |
|---|---|---|
| Ocak | «Ocak yandı. Burası artık senin.» | «The hearth is lit. This ground is yours now.» |
| Oba | «On ocak, bir oba.» | «Ten hearths make a clan camp.» |
| Boy Yurdu | «Soyun burada oturur.» | «Your lineage sits here.» |
| Toy Yeri | «Beyler bu yere gelir.» | «The lords come to this ground.» |
| Tanhu Avlusu | «Avlu kuruldu. Bozkır buraya bakar.» | «The court stands. The steppe looks here.» |

## Perde perde

Perde son ana görevle biter, sayaç yoktur ([K42](/docs/source/design/decisions#k42)): K25'in gün sayıları (II 12, III 12, IV 14, V 12, VI 16) yalnız tasarım ölçüsüdür. Son görevden sonra Serbest Dolaşım açık kalır, takvim akar; aradaki yılları Akan Kronik geçirir. Görevler ve kişiler [story.md §11](/docs/source/design/story#11-ii-vi-perdeler)'dedir; perdelerin kendi sayfaları: [II](/docs/story/act-2), [III](/docs/story/act-3), [IV](/docs/story/act-4), [V](/docs/story/act-5), [VI](/docs/story/act-6).

| Perde | Tarih | Yerleşim ve ordugâh için olanlar | Yerleşim | Ordugâh | Hane |
|---|---|---|---|---|---|
| II «Ok Neyi Gösterirse» | 1–15 Haziran MÖ 209 | Pay, Köz Kabı ve ocak; Göl Obası'nın ozanı Mete'nin ocağına gelir; ilk aileler (Şiuşun, Ruodi, Lan Hatun); Oba ve demirci Dutu; ıslık sınamaları; son görev av ve darbe (14–15 Haziran) | Ocak → Oba | Onluk Ateşi → Yüzlük Kampı (100 yerleşik atlı) | 3 → 10 |
| III «Boş Toprak» | 1 Eylül–1 Ekim MÖ 208 | Dönüş; avlu göçü (+8 hane, yurtlarıyla); [Tunghu](/encyclopedia/donghu) elçileri Elçi Yurdu'nda (at, hatun, boş toprak); 16 Eylül'de [Dailin](/encyclopedia/dailin) Sayımı, perdenin doruğu ([K56](/docs/source/design/decisions#k56)); akın penceresi 15–17 Eylül; savaş; son görev yenilenlerin seçimi (1 Ekim); Gözcü Konakları | Boy Yurdu | Binlik Ordugâhı (200 yerleşik, Dailin'de 1.000); sefer Tunghu Yurdu | 10 → 22 |
| IV «Borç» | 1 Haziran MÖ 205–22 Eylül MÖ 203 | Önce Kışlak'a dönüş (Hexi, 1–17 Haziran 205); 17 Haziran 205 dolunayında [Yüeçi](/encyclopedia/yuezhi) batıya sürülür, Gök Dağı eteğinde Beşinci Ay Sunusu (Mete Hexi'dedir); iç Kronik; 25 Haziran 203'te [Lung-çeng](/encyclopedia/longcheng)'de toplantı ve armağan kervanı, [Loufan](/encyclopedia/loufan) ve [Baiyang](/encyclopedia/baiyang) katılır; Ordos'a giriş 21–23 Ağustos 203; kereste yolu; ocağın ozanı artık [Çocuk](/encyclopedia/child) olur (K79); son görev Ordos'ta Dailin, 22 Eylül 203 | Toy Yeri | Binlik (400 yerleşik); sefer Ordos ve yazın Kışlak | 22 → 45 |
| V «Dört Renk» | 20 Kasım–1 Aralık MÖ 201 | Dönüş; [Han Xin](/encyclopedia/han-xin)'in beyleri ve haneleri sığınır; Divan'da Surlu ya da Göçer Avlu (20–21 Kasım); son görev Baideng kuşatması (25 Kasım–1 Aralık) | Tanhu Avlusu (seçim) | Kışın dağınık; Tümen Ordugâhı (600 yerleşik, toplantıda 3.000–10.000); sefer Mayi ve Baideng | 45 → 80 |
| VI «Sayım» | 1 Haziran MÖ 198–9 Eylül MÖ 174 | Dönüş; heqin malı Hazine'de; Lung-çeng 2 Haziran 198; Kurultay 3–4 Haziran 198; Lung-çeng 4 Haziran 176: 176 mektubu ve [Kunmo](/encyclopedia/kunmo); son görev son Dailin, 9 Eylül 174: Mete sayım sürerken ölür | Tanhu Avlusu tam | Tümen | 80 → en çok 90 |

Ocağın ozanı II–III'te Göl Obası'nın ozanıdır (K106); III→IV Kroniği'nde ölür, kopuzu Çocuğa kalır ve IV–VI'da Mete'nin ocağında Çocuk çalar (K79). Toplantıların günleri ve sayım: [Hanlık Merkezi](/docs/settlement/court#toplantilar).

## Surlu ya da Göçer Avlu

V. Perde'de, Han Xin'in sığınan haneleri geldikten sonra, Divan'da bir kez sorulur (20–21 Kasım 201). Geri alınmaz. Wei Lü'nün sözünü Han Xin'in adamı söyler: kuyu, sur ve tahıl kulesi. İtirazı bir Hun beyi söyler: «Hun suru tutamaz.» / «The Hun cannot hold a wall.» Tarihte bu tartışma Hanshu 94A'dadır: Wei Lü Huyandi Tanhu'ya kuyu, sur ve tahıl kulesi öğütler, «Hu suru tutamaz» itirazıyla vazgeçilir. Olay Mete'den bir buçuk kuşak sonradır; Surlu Avlu ve darı tarlası Destan Kitabı'nda tasarım tercihi diye işaretlenir.

| | Surlu Avlu / Walled Court | Göçer Avlu / Moving Court |
|---|---|---|
| Dayanak | Wei Lü'nün önerisi (穿井築城，治樓以藏穀); Ivolga kazısı: sur, hendek, yarı gömük evler, darı | Shiji 110: suru ve tarla işi yoktur (毋城郭常處耕田之業); «Hu suru tutamaz» (胡人不能守城) |
| Açar | Sur ve Hendek, Sur Kapısı, Yarı Gömük Ev, Darı Tarlası, Tahıl Kulesi | Keçe Göç Arabası, ek At Hattı ve Ağıl |
| Kurulan yapılar | 23 yurt, 12 yarı gömük ev, 400 m sur (40 parça), 2 sur kapısı, 6 tarla, 3 Tahıl Kulesi, 2 Ambar Yurdu, Demirci Ocağı, Fırın, 4 Gözcü Kulesi, 2 Kuyu | 35 yurt, 6 Keçe Göç Arabası, 4 At Hattı, 4 Ağıl, 2 Sundurma, Tahıl Ambarı, 2 Ambar Yurdu, Demirci Ocağı, Fırın, 2 Gözcü Kulesi, 2 Kuyu |
| Baskın | Akının başarı payı ×0,5 (sur aşılmalı); Haziran–Eylül arası başarılı akın güz ürününün %30'unu çiğner (K54) | Sürü kaybı ×0,6 (sürü dağılıp kaçar), ambar kaybı ×1 |
| Kış yiyeceği | Tarla başına mevsimde 500 darı (≈250 öğün); ekim 10–31 Mayıs, biçim 1–20 Eylül, tarla başına 0,5 + 0,5 İG; işi Kâhya yapar, kart çıkmaz ([K54](/docs/source/design/decisions#k54)). Tahıl Kulesi yaz ve güz artığının %50'sini kışa geçirir (öteki yerlerde %35). Surlu 20 Kasım 201'den sonra seçildiği için V'in kışı tarlasızdır: kış + saklanan %91. Tarla ve kuleyle %102, VI'dan | Tarla yoktur, darı pazardan gelir. Sürü tavanı ×1,2: kış + saklanan tabanda %90, tavanda %113 |
| Zanaat | Kalıcı atölye ×1,1 | Yok |
| Ordu | Yok | Ordugâh ambarına günlük pay ×1,1 (sürü orduyla yürür) |
| Gönül | Sığınan haneler +10 | Bozkır haneleri +5 |
| Bedel | Yapı emeği 91,1 İG (Göçer'in ≈×1,7'si); odun ≈×1,4 (sur parçası 16 odun, 40 parça 640 odun), taş ve kil; ham Yük ≈%19 çok (8.053 ve 6.771); fazladan 480 odun kereste kervanıyla gelir | Yapı emeği 54,9 İG; keçe ≈×1,6, ip ≈×1,5, demir ≈×2; yurt ve araba bakımı; odun az |
| Kademe günü (hedef 4–12) | 8,1 | 7,8 |

İki yolun günü bilerek yakın tutulur (K52): seçim hızla değil malla yapılır. Surlu odun, taş, kil ve emek ister; Göçer keçe, ip ve demir ister. Sur parçasının odunu 4'ten 16'ya çıktı: Ivolga'nın kalın kütük duvarına ve Hanshu'nun «binlerce ağaç kesildi» sözüne (伐材數千) uyar. Zondaki kalıcı odun IV'te tükendiği için Surlu'nun fazladan 480 odunu Hangay kereste kervanıyla gelir (≈14 Ordu Arabası seferi).

Seçim kademe adını değiştirmez. Sonsöz'ün Son Sayım kartı onu «Avlu» satırında okur: «Avlusu surluydu.» / «His court stood behind walls.» ya da «Avlusu tekerlekteydi.» / «His court rode on wheels.» ([K60](/docs/source/design/decisions#k60); ozanın Sonsöz'deki iki dizesi seçimi okumaz).

```varlik
rampart, rampart_gate, pit_house, field, granary_tower, wagon_felt
```

## Yerleşim ve ordugâh ayrıdır

Senin isteğin (K23; «yerleşim yeri ve ordu kampı ayrı olacak»): iki ayrı iç harita.

| | Yerleşim | Ana ordugâh | Sefer ordugâhı |
|---|---|---|---|
| Ad | Yurt / Hold; Defter'de «Yurdun» | Ana Ordugâh / Home Encampment | Sefer Ordugâhı / Field Camp |
| Yer | II'de Mete'nin Payı, III'ten Tanhu Ordusu (112,8; 43,5) | Islık Alanı (106,6; 44,2) | Sefer haritasının kamp yerlerinden biri |
| Arazi | 1.400 × 1.050 m, Karasu deresinin vadisi, güney bozkırı | 1.400 × 1.050 m, düz Gobi ovası | Yerine göre |
| Ömür | II–VI, kalıcı | II–VI, kalıcı | Seferle kurulur; dönüşte sökülür ya da bırakılır |
| Ambar | Yerleşim Hesabı | Ordugâh Hesabı | Ordugâh Hesabı; ambar araba halkasıdır |
| Akın | Ay penceresinde küçük akın ([K55](/docs/source/design/decisions#k55)) | Yalnız III ve IV'te küçük Gece Akını | Akın kuralının dışında, yalnız hikâye sahnesi |

İki yer arası atla 1 gün, arabayla 1 gün, öküzle 2 gündür (30 km gösterim). Atlas bacağı 16 gerçek saniye sürer, saat 1 gün atlar. Ambarlar ayrıdır: aralarında yalnız kervan ve Mete'nin heybesi taşır. Yerleşim Mete yokken de üretir ve kurar; ama yeni hane çeken günlük Çekim yalnız Mete oradayken işler.

**Neden iki dünya.** Sen ayrılık istedin; tümen ordugâhı 448 × 588 m'lik kafes kamayı ve 800 × 168 m'lik bloğu sığdıran düz bir ova ister, yerleşim dere vadisi ister; iki dünyanın çizim bütçesi ayrı kalır, en kötü kare yalnız biri olur; aradaki gün kervana anlam verir.

**Yerleşimin iç haritası** (taslak): ortasından Karasu deresi geçer (söğüt, karaağaç, saz, ot çayırı; taşkın kuşağı ±25 m). Kuzey tepelerinde taş, az demir ve huş, Kutlu Tepe'de Gök Direği'nin tek yeri vardır; güney ve doğu ovası otlak, tezek ve ot çayırıdır; güneybatıda saksavul çalısı, güneydoğuda tuz kabuğu durur. Batı kapısı ordugâha, doğu kapısı Ordos, Mayi ve Tunghu'ya açılır. Kalıcı odun ≈1.100 kütük ve ≈120 huştur: [Üretim ve Depolama](/docs/settlement/production-storage). Ordugâhın kendisi: [Ordugâh ve Kervan](/docs/settlement/war-camp-caravans).

## Oyunda şu an

> [!DURUM]
> Godot'da yok: yerleşim, kademeler, Ocak Yeri, Köz Kabı, Teoman'ın armağanı, yerleşimin ve Islık Alanı'nın iç haritaları, II. Perde'nin görevleri, Surlu ve Göçer yolu. Godot'da bugün tek dünya vardır: menünün ve Serbest Gez'in gece kampı. Oradaki iki keçe yurt, ahır, iki at ve ateş sahnenin parçasıdır, kurulmaz ve büyümez; saat ve takvim de yoktur, gece sabittir ([d3/game-state](/docs/source/design/d3/game-state)). Prototipte denendi (saf kod ve sınama, oyuna bağlanmadı): Köz Kabı ve Yurt Yükü eşyaları, Ordu Payı hesabı, Kronik'in yıllık adımı. Yerleşimin kendisi prototipte de yazılmadı.

## Yol haritası

Ocak ve Oba, Plan Kipi, haneler, ordugâh ve kervan II. Perde'nin «Yerleşim, ordugâh ve ekonomi» fazındadır; iki iç harita ondan önceki dünya fazındadır ([yerleşim](/roadmap#item-tanhu-ordu-map), [Islık Alanı](/roadmap#item-whistle-field-map)). Boy Yurdu [act-3-p2](/roadmap#act-3-p2), Toy Yeri [act-4-p1](/roadmap#act-4-p1), Surlu ya da Göçer Avlu [act-5-p2](/roadmap#act-5-p2), tam avlu ve Kurultay [act-6-p1](/roadmap#act-6-p1) fazındadır.

```ilerleme
act-2-p2
```

## Kaynaklar

- [decisions.md: K23, K34, K42, K49, K50, K52, K54, K56, K60, K79, K80](/docs/source/design/decisions#k23)
- [settlement.md §2: açılış ve büyüme yayı](/docs/source/design/settlement#2-acilis-ve-buyume-yayi), [§2.1: II. Perde açılışı](/docs/source/design/settlement#2-1-ii-perde-acilisi), [§2.2: perde perde](/docs/source/design/settlement#2-2-perde-perde)
- [settlement.md §3: yerler](/docs/source/design/settlement#3-yerler), [§3.2: yerleşimin iç haritası](/docs/source/design/settlement#3-2-tanhu-ordu-ic-haritasi-taslak)
- [settlement.md §4.1: kademe tablosu](/docs/source/design/settlement#4-1-tablo), [§4.2: tam bileşim ve Kâhya sütunu](/docs/source/design/settlement#4-2-tam-bilesim), [§4.3: V. kademe yolu](/docs/source/design/settlement#4-3-v-kademe-yolu), [§14.4: kademe kartları](/docs/source/design/settlement#14-4-kademe-kartlari)
- [economy.md §10.6: kademeler ve resmî koşu](/docs/source/design/economy#10-6-kademeler), [§7.1: kış hesabı](/docs/source/design/economy#7-1-yerlesimin-ve-ordugahin-kis-hesabi-k23-k24)
- [story.md §2: zaman çizelgesi](/docs/source/design/story#2-zaman-cizelgesi-1), [§11: perdelerin görevleri ve kişileri](/docs/source/design/story#11-ii-vi-perdeler)
- [d2/core.md §4.2: açılış](/docs/source/design/d2/core#4-2-acilis), [§4.3: kademeler](/docs/source/design/d2/core#4-3-kademeler), [§5.8: denge hedefleri](/docs/source/design/d2/core#5-8-denge-hedefleri)
- [d3/register.md: cevap 35](/docs/source/design/d3/register), [d3/game-state](/docs/source/design/d3/game-state)
- `docs/design/d2/settlement-model.json`: kademe bileşimi, armağan, yol etkileri
