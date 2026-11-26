---
title: Toplama ve Kaynaklar
order: 30
status: tasarim
summary: 'Mal düğümden, avdan, sürüden, savaştan, takastan ve sökümden gelir; Mete saniyelerle, işçi iş saatleriyle toplar; ganimet düşman türüne göre belirlidir, Hun düşmanı kabuk da bırakır, rastgele düşme yoktur.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/economy.md
  - docs/design/fauna.md
  - docs/design/survival.md
  - docs/design/progression.md
  - docs/design/settlement.md
  - docs/design/structures.md
  - docs/design/d3/oyun-durumu.md
---

[Mete](/encyclopedia/mete) ağaca balta vurur, kayaya kazma sallar, sazı elle biçer. Her düğümün sabit verimi vardır. II. Perde'den işçiler de toplar, ama çok daha yavaş: Mete'nin eli saniyedir, işçinin emeği iş saatidir (İS: bir işçinin bir oyun saati). Malzemenin üç ana yolu ağaç kesmek, avlanmak ve savaştır; mal ayrıca sürüden, takastan ve sökümden gelir ([K24](/docs/source/design/decisions#k24), [K49](/docs/source/design/decisions#k49)). Toplamak XP ve Güven vermez; yalnız teslim verir.

> [!NOT]
> «o yüzden oyunda malzeme ve envanter sistemide olması gerekiyor yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak, malzemeler açık dünyada savaşlarla, ağaç kesere, avlanarak eti toplacanak, yine bir para birimi ve bu parayı harcayacak satıcılar etc olacak»

## Düğümler

**Kurallar.**

- **Erişim:** 2,1 m. Tıklanan düğüme yürünür, varınca iş başlar; `E` en yakınını işler.
- **At üstünde** ([K46](/docs/source/design/decisions#k46)): araç El, eylem en çok 2 sn ve eğilip alınan düğüm at üstünde toplanır. Liste kapalıdır: Kuru Dal, Yavşan, Kuşburnu, Topalak, Uyku Otu, Tezek. Öteki düğüme tıklamak önce Mete'yi indirir; Kutlu Ot inmeden koparılmaz. At en çok 3 m/sn'ye iner, eylem ×1,5 sürer (Dizle Sürme becerisiyle 5,5 m/sn ve ×1); dörtnalda toplanmaz, stamina harcanmaz. Düğüm hakları değişmez: at yalnız yürüme süresini kısaltır ([Envanter ve Yük](/docs/economy/inventory-load#terki)).
- **Vuruş:** balta 1,0 sn, kazma 1,1 sn; Bilek puanı başına +%6 hız. `E` basılı kalırsa sürer. Hareket keser, ilerleme şafağa dek düğümde kalır.
- **Tut:** süre çubuğu dolar, bırakınca sıfırlanır, ceza yok, stamina harcamaz.
- **Tam Vuruş:** halka temas anına ortalıdır, pencere 0,18 sn (Tam Vuruş becerisiyle 0,30). Pencerede `E`'ye yeniden basmak gerekir; basılı tutmanın cezası yoktur. Tam vuruş yarım stamina harcar. Hakkın son vuruşu altındır: %50 ile +1 ürün, beceriyle kesin. Zar değil, tek bir an çalışılır.
- **Stamina:** balta 5, kazma 6. Bir ağaç 25 stamina: 4 ağaçta bir nefes. Stamina 0'da iş durmaz, süre ×1,5, halka kapalı.
- **Yük:** ürün önce sırta gider, sığmazsa düğümün dibinde yer yığını olur.
- **Gece gürültüsü:** balta 24 m, kazma 28 m, tut 3 m (Ayak ≥4 ise 0). Yalnız karanlıkta (güneş −6°'nin altında).
- **Sezgi:** Göz'e bağlı yarıçap `6 + 3 × Göz` m. Mantar, Uyku Otu ve gömülü tunç bu yarıçap dışında görünmez.
- **Şafak** Tan evresinin başıdır, yenilenen düğümler o an döner. **Kalıcı** düğüm dönmez: kesilen ağacın kütüğü IV. Perde'de hâlâ orada durur.

**Tablo.** Hak, düğümün şafağa dek kaç kez işlendiğidir. Vuruş sayısı tunç araçladır ([economy.md §3.2](/docs/source/design/economy#3-2-dugum-tablosu), [§3.9](/docs/source/design/economy#3-9-ii-perde-ve-sonrasi-toplama)).

| Düğüm | Araç | Eylem | Verim × hak | Yenilenme | Perde |
|---|---|---|---|---|---|
| Odunluk Kütüğü | Kütük Baltası (yerinde) | 2 vuruş | 1 Çam Odunu × stok 16 | Yok; Gün III sabahı stok 0 | I |
| Çam | Balta | 5 vuruş | 3 Çam Odunu × 1 | Kalıcı | I |
| Ardıç | El, sonra balta | 2 sn, sonra 5 vuruş | 2 Ardıç Dalı × 3, sonra 2 Ardıç Odunu × 1 | Dal şafakta, gövde kalıcı | I |
| Söğüt | El, sonra balta | 2 sn, sonra 3 vuruş | 1 Söğüt Kabuğu × 1, sonra 2 Söğüt Odunu × 1 | Kabuk şafakta, gövde kalıcı | I |
| Kuru Dal | El | 2 sn | 2 Dal × 1 | Şafak | I |
| Reçineli Gövde | El | 2 sn | 1 Reçine × 1 | Şafak | I |
| Ağaç Mantarı | El | 2 sn | 1 Mantar × 1 | Şafak; yalnız sezgide; son 12 saatte ≥1 saat yağmur yağdıysa ×2, yoksa ×0,5 | I |
| Kuşburnu, Topalak | El | 2 sn | 3 yemiş × 1 | Şafak | I |
| Huş | Balta | 5 vuruş | 3 Huş Odunu + 1 Huş Kabuğu × 1 | Kalıcı | II |
| Karaağaç | Balta | 6 vuruş | 3 × 1 | Kalıcı | II |
| Ilgın | Balta ya da bıçak | 3 vuruş | 4 × 1 | Kalıcı | II |
| Saksavul | Balta | 4 vuruş | 2 × 1 | Kalıcı | II |
| Melez | Balta | 6 vuruş | 3 × 1 | Kalıcı | III |
| Toğrak | Balta | Çam kuralı | 2 × 1 | Kalıcı | IV |
| İlk Taşlar | El | 1 sn | 1 Taş × 6 | Yok; yalnız ilk görev | I |
| Taşlık Bloğu | Kama ve Tokmak (yerinde) | 3 vuruş | 1 Taş × 3 | Şafak | I |
| Kaya | Kazma | 3 vuruş | 1 Taş × 4 | Kalıcı | I |
| Taş Ocağı | Kazma | 3 vuruş | 1 Taş × 6 | Şafak | II |
| Demir Damarı, Bakır Damarı | Kazma | 5 vuruş | 1 cevher × 3 | Şafak | I |
| Toprak Altı Tunç | El | 3 sn | 1 Tunç Hurda × 1 | Kalıcı; yalnız sezgide | I |
| Kalay Damarı | Demir Kazma | 4 vuruş | 1 cevher × 3 | Şafak | IV |
| Firuze Damarı | Demir Kazma | 4 vuruş | 1 Ham Firuze × 2 | Şafak | IV |
| Altın Kumu | El | Yıka | 1 Altın Kumu × 2 | Şafak | IV |
| Saz Kümesi | El | 2 sn | 2 Saz × 3 | Şafak | I |
| Ot Yığını, Saman Yığını | El | 2 sn | 2 Ot ya da 2 Saman × 2 | Şafak | I |
| Yün Balyası | El | 2 sn | 2 Yün × 2 | Şafak | I |
| Yavşan | El | 2 sn | 2 Yavşan × 1 | Şafak | I |
| Kutlu Ot | El | 3 sn | 1 Kutlu Ot × 1 | Şafak; Atşo görürse onunla bağ −1 | I |
| Uyku Otu | El | 2 sn | 1 Uyku Otu × 1 | Şafak; yalnız sezgide | I |
| Kökboya | El | 2 sn | 2 Kökboya × 1 | Şafak | II |
| Çivit Otu | El | 2 sn | 2 Çivit Otu × 1 | Şafak; bozkırda kendiliğinden yetişir ([K58](/docs/source/design/decisions#k58)) | II |
| Tezek | El | 2 sn | 1 Tezek × 2 | Şafak; yağmurdan sonraki 6 saat yakıtı ×0,5 | I |
| Kil Yarı | El | 3 sn | 1 Kil × 3 | Şafak | I |
| Tuz Kabuğu | El | 3 sn | 1 Tuz × 2 | Şafak | I |
| Kömür Ocağı | El | 3 sn | 2 Kömür × 3 | Şafak | I |
| Mutfak Artığı | El | 2 sn | Sırayla kemik, deri, sinir, kemik, deri, kemik, deri, boynuz, kemik; 3 hak | Şafak; Gün III'e dek 3 deri kesin | I |
| Buz Deliği | Buz Keskisi (yerinde); ağ | 4 sn; ağla 8 sn | 1 Dolu Tulum × 2; ağla sırayla 1, 2 Balık × 1 | Şafak; delik buz tutar | I |

Çivit Otu mavi boyanın yaprağıdır: 2 Çivit Otu ocakta 1 Mavi Boya olur, boya Boyalı Pelerin'e girer ([Zanaat](/docs/economy/crafting#boya)). Hun çağında mavi boyaya tanık yoktur [kurgu].

```varlik
deadfall, wormwood_tuft, rosehip_bush, buckthorn_bush, sleep_herb, dung_patties
madder_plant, woad, tree_birch, vein_iron, salt_crust, kitchen_scraps
```

**Araçlar** kırılmaz, Yük tutmaz, yalnız hız ve kapı verir.

| Araç | Çam, ardıç, söğüt | Kaya, damar | Nereden |
|---|---|---|---|
| Tunç Balta | 5, 5, 3 vuruş | | Ardokşa, onun çetelesiyle |
| Demir Balta | 4, 4, 2 vuruş | | Demir Diş görevi |
| Tunç Kazma | | 3, 5 vuruş | Palak, Bahis görevi |
| Demir Kazma | | 2, 4 vuruş; kalay ve firuze için şart | II. Perde, Demirci Ocağı |

```varlik
axe_bronze, axe_iron, pick_bronze, pick_iron, site_axe, net
```

I. Perde'de her yön bir iştir: odun kampın doğusunda, taş kuzeyinde, ot kuzeydoğusunda, cevher batısında, tuz uzak kuzeybatıda.

## İki hız

Mete demir araç, Bilek 5, yakın küme ve arabayla bir kütüğü ≈6 gerçek saniyede keser ve taşır. On işçilik Erzak Kolu 6 oyun saatinde (60 İS) 24 kütük getirir: kütük başına 2,5 İS. Oran ≈50'dir. İki hız böyle doğar; ayrı bir kural değildir. İşçi yazın günde ≈15 İS toplar.

| Mal | Mete sn | İşçi İS | | Mal | Mete sn | İşçi İS |
|---|---|---|---|---|---|---|
| Çam Odunu | 6 | 2,5 | | Taş Blok | 10 | 4 |
| Ardıç Odunu | 7 | 2,86 | | Kil | 5 | 2 |
| Söğüt Odunu | 5 | 2,22 | | Tuz | 6 | 2,5 |
| Huş Odunu | 6 | 2,86 | | Saz | 2 | 0,67 |
| Saksavul | 8 | 3,33 | | Kökboya, Çivit Otu | 2 | 1,25 |
| Dal | 1,5 | 0,5 | | Demir, Bakır Cevheri | 15 | 5 |
| Tezek | 3 | 0,5 | | Kalay Cevheri | 18 | 6,67 |
| Ot | 1,5 | 1,5 | | Balık | 6 | 2 |
| Huş Kabuğu | 2 | 0,5 | | Ham Firuze | 30 | 20 |

**Erzak Kolu** (10 kişi, 6 oyun saati): 24 odun, ya da 40 Ot, ya da 12 cevher (ocak varsa), ya da 8 Et, 2 Ham Deri, 1 Boynuz, 4 Kemik, 4 Sinir, 1 İç Yağı, ya da malzemeyle 60 ok.

**Çevre tükenir.** Ağaç ve kaya kalıcıdır, yakın orman açılır, kol uzağa gider. Yerleşim kademesine göre çevre katsayısı (Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu): 1; 1; 0,85; 0,7; 0,6. Bu katsayı işçi toplama hızını ve Mete'nin taşıma süresini çarpar. Yakın kaynağı biten yerleşim kervanla ve takasla beslenir: konum kararı ekonomiktir.

| Biyom | Bol | Az | Yok |
|---|---|---|---|
| Orman bozkırı | Melez, huş, çam; maral, karaca, ayı | Saz | Saksavul |
| Irmak vadisi | Söğüt, karaağaç, toğrak, saz, kil, kökboya, balık, kaz | Taş | |
| Bozkır | Tezek, ot, taş, çivit otu, ceylan, tarbagan, kurt, toy kuşu | Odun | |
| Gobi, Alaşan | Saksavul, ılgın, tuz, kulan, deve | Ot | Saz |
| Dağ | Cevher, taş, ardıç, yaban keçisi, argali | Ot | |

## Av

Vurulan hayvan yere çöker. `E` basılı 2 sn **Yüz**: bıçak ister, yoksa yalnız küçük av yüzülür. Mal Heybe'ye girer, Yük'e sayılır. Tek okta düşerse +1 Ham Deri. Rehineye yay yok: I. Perde'de sapan, tuzak ve Gün III'ün ödünç yayı var. Avın tek döngüsü [fauna.md §4](/docs/source/design/fauna#4-av)'tedir ([K65](/docs/source/design/decisions#k65)).

| Av | Verim | Mete dk | Av kolu İS | Perde |
|---|---|---|---|---|
| Karga | Tüy | 0,4 | 1–2 | I |
| Keklik | 1 Küçük Et, Tüy | 0,4 | 1–2 | I |
| Tavşan | 1 Et, 1 Küçük Post | 0,5 | 3 | I |
| Tarbagan | 1 Et, 1 İç Yağı, 1 Küçük Post; Aralık'ta kış uykusunda | 0,5 | 3 | I |
| Tilki | 1 Tilki Kürkü | 1 | 8 | I |
| Kurt | 1 Kurt Kürkü, 1 Sinir, 1 Kemik | 1,5 | 15 | I |
| Ceylan | 3 Et, 1 Ham Deri, 2 Sinir, 1 Boynuz, 2 Kemik | 2 | 22 | I |
| Domuz | 4 Et, 2 İç Yağı, 1 Ham Deri, 2 Kemik | 2 | 22 | I |
| Yaban Keçisi | 3 Et, 1 Ham Deri, 2 Boynuz, 2 Sinir, 2 Kemik | 2,5 | 26 | I |
| Maral | 4 Et, 1 Ham Deri, 2 Sinir, 1 Geyik Boynuzu, 3 Kemik, 1 İç Yağı | 2,5 | 26 | I |
| Argali, Kulan | Argali 4 Et, 1 Ham Deri, 2 Boynuz, 2 Sinir, 3 Kemik, 1 İç Yağı; kulan 5 Et, 2 Ham Deri, 2 Sinir, 3 Kemik, 1 İç Yağı | 3 | 30 | II |
| Toy Kuşu, Kaz | 1 Et, 4 Tüy; 2 Küçük Et, 4 Tüy | 0,8–1 | 3–6 | II |
| Karaca | 2 Et, 1 Ham Deri, 1 Sinir, 1 Kemik | 1,5 | 10–15 | III |
| Ayı | 6 Et, 2 Ham Deri, 2 Sinir, 4 Kemik, 4 İç Yağı | 4 | 40 | III |
| Samur | 1 Samur Kürkü | 1,5 | 10–15 | VI |

- **Bölge stoğu:** büyük avda bozkır 40, dağ 25, orman 30; küçük av ×3. Her şafakta %30'u geri gelir. Kaplan, sığın ve kar leoparı stok dışıdır: zon başına perdede en çok 1.
- **Pay Bırak:** yüzdükten sonra `E` 2 sn, 1 Küçük Et ya da 1 İç Yağı bırakılır (bölge başına günde 1). O gün hayvan algısı ×0,9, sonraki şafakta geri gelme %35 olur.
- **Kopuz Gecesi:** Mete'nin ocağının ozanını gece ≥1 oyun saati dinlemek ertesi günün ilk büyük avına +1 verim verir. Ozan II ve III'te Göl Obası'nın ozanıdır, IV'ten ocağın Çocuğu çalar ([K79](/docs/source/design/decisions#k79), [K106](/docs/source/design/decisions#k106)).
- **Yer küstü:** bir günde stoğun %30'undan fazlası vurulursa 2 şafak boyunca geri gelme %15'e iner. HUD sayı vermez: kuş sesi yarıya iner, uzakta kurt ulur.
- **Yasak:** doğum penceresinde yavrulu sürüyü kırmak Korku +1 (zon başına bir). Evcil hayvan avlanmaz: et sürüden kesimle gelir.
- **Tuzak:** en çok 4 kurulu; günde dört kez (00:00, 06:00, 12:00, 18:00) tavşan, tarbagan ya da tilki için zar atılır. Burada zar vardır; ganimette yoktur.
- **Sürek avı:** on avcı 6 oyun saatinde Erzak Kolu'nun av verimini getirir. Kışın günde ≈83 öğün eder: yerleşimin kış açığını kapatan asıl kol budur.
- **Kazan:** 1 Et kazanda 5 öğün eder. 1 koyun 30 öğündür. Çiğ et bozulur: [Envanter ve Yük](/docs/economy/inventory-load). Avın oynanışı ve algı: [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting).

## Sürü

Sürü kaba girmez, yerleşimin ve ordunun kaydında sayıdır. Hane sürüsü ≈18 at eşdeğeridir: 35 koyun, 10 keçi, 7 at, 4 sığır, ½ deve.

| Tür | At eşd. | Çoban başına | Doğum / yıl | Kesim / yıl | Tezek / gün | Kış yemi (olağan, derin kar) |
|---|---|---|---|---|---|---|
| Koyun | 0,15 | 120 | %45 | %20 | 0,1 | 0,02; 0,1 |
| Keçi | 0,12 | 120 | %50 | %20 | 0,08 | 0,02; 0,08 |
| At | 1 | 40 | %20 | %4 | 0,6 | 0,05; 0,5 |
| Sığır | 1 | 50 | %25 | %10 | 1 | 0,1; 0,6 |
| Deve | 1,3 | 30 | %12 | %5 | 0,5 | 0,05; 0,3 |

| Tür | Süt / gün (bahar, yaz, güz, kış) | Kırkım, kıl | Kesimde |
|---|---|---|---|
| Koyun | 0,04; 0,08; 0,05; 0 | Bahar 1, güz 0,5 Yün | 6 Et, 1 Ham Deri, 2 Kemik, 1 İç Yağı |
| Keçi | 0,05; 0,1; 0,06; 0 | Yılda 0,5 Kıl | 4 Et, 1 Ham Deri, 2 Kemik |
| At | 0,1; 0,25; 0,15; 0 (Kısrak Sütü) | Yılda 0,5 Kıl | 18 Et, 2 Ham Deri, 6 Kemik, 2 Sinir, 2 Kıl, 1 İç Yağı |
| Sığır | 0,25; 0,5; 0,3; 0 | | 20 Et, 2 Ham Deri, 6 Kemik, 2 Sinir, 2 Boynuz, 2 İç Yağı |
| Deve | 0,15; 0,3; 0,15; 0,05 | Bahar 1 Kıl | 24 Et, 3 Ham Deri, 8 Kemik, 2 Sinir, 3 İç Yağı |

**Ek türler** ([K65](/docs/source/design/decisions#k65)). Hane sürüsünde payları yoktur; ticaret, olay ve Kronik girişiyle gelirler.

| Tür | Perde | At eşd. | Doğum / yıl | Kesimde | Not |
|---|---|---|---|---|---|
| Yak | IV | 1 | %20 | Sığır gibi | Çiang hanesi ve kervanı; süt sığırın ×0,6'sı |
| Eşek | IV | 0,5 | %12 | 3 Et, 1 Ham Deri, 2 Kemik | Vaha ve Loulan yolu; yük eşeği 20 Yük |
| Katır | V | 0,7 | Doğurmaz | 8 Et, 2 Ham Deri, 3 Kemik | Yük katırı 35 Yük; binek katır |
| Domuz | V | 0,2, otlak saymaz | %100 | 8 Et, 3 İç Yağı, 1 Ham Deri, 2 Kemik | Yalnız Surlu yol; yerleşim başına en çok 12 |

| Olay | Ne zaman | Ne olur | Emek |
|---|---|---|---|
| Sağım | Bahar–güz, 06:00 ve 19:00 | Süt ve Kısrak Sütü ambara | 0,2 ve 0,25 İS |
| Kırkım | Bahar sonu ve güz başı | Yün ve deve kılı ambara. Yaz başında açılan perdede (II, IV, VI) yeni kırkım yoktur | Koyun başına 0,5 İS |
| Tarama | Bahar | Keçi ve at kılı | Baş başına 0,5 İS |
| Doğum | Bahar | Sürü yıllık doğum payı kadar büyür | |
| Ot biçimi | 8 Ağustos–15 Kasım | Kış yemi için Ot; biçim, kurutma, istif ve yığının kışlağa çekilişi birlikte | Ot başına 1,5 İS |
| Soğum | Güz sonu | Koyun ve keçinin %10'u, sığırın %8'i, atın %5'i kesilir, et kışa yayılır, %35'i kaybolur | Küçükbaş 2, büyükbaş 6 İS |
| Kesim | Yıl boyu | Yıllık kesim payı | Soğumla aynı |
| Derin kar | Kar örtüsü ≥0,6 olan kış günü; Tanhu Ordusu'nda günlerin %16,0'ı (K49) | Yem ister; yem yoksa o gün beslenmeyen sürünün %2'si yiter, kışta en çok %30 | Yemleme |
| Kar Kabuğu | Derin karın içinde; kış başına 0,62 olay | Otlak ×0,3 | |

- **Çobanlık** gece de sürer: çoban başına günde 24 İS.
- **Kurt kaybı** tek formüldür, çobanlığın kapsamadığı sürü payına günde: `0,01 × (1 + 1,5 × (1 − stok / tamStok)) × (kış ? 1,5 : 1) × (sis ? 1,5 : 1) × (köpek ? 0,4 : 1) × (ağıl ? 0,3 : 1)`. Tam stokta yazın %1; stok %30 iken kışın ≈%3,1, köpekle ≈%1,2. Çevresini boşaltan yerleşimin koyunu kurda gider.
- **Haraç.** III'te Tunghu yenilince Kronik yılda 20 Ham Deri işler (Vuhuan'ın deri haracı, Hou Hanshu 90); IV açılışında ≈60 deri.
- **Yük ve koşum hayvanı.** Gelen hanenin yük atı ve devesi hanenin sürüsüne girer. Arabaya koşulan at ve öküz sürüden ayrılır, kesilmez, sürü defterinde koşum satırında durur.
- **Fiyat** ekonomi modelinindir: [Para ve Satıcılar](/docs/economy/money-traders#kiymet). Teoman'ın armağanı ve gelen hanenin yükü: [Malzemeler](/docs/economy/materials).

```varlik
sheep, goat, horse_brown, cattle, camel, yak, donkey, mule, pig
```

## Savaş ganimeti

Yere düşmüş düşmanda **Ara**, 1,5 sn. Ganimet **düşman türüne göre belirlidir**: her türün sabit verimi vardır, kesirli pay tür başına sayaçta birikir, 1'i geçince düşer. Rastgele çekiliş yoktur, yükleme sonucu değiştirmez. At kaçar, 60 sn içinde yakalanırsa ordugâh sürüsüne geçer. Adlı silahlar (Halka Kabzalı Kılıç, Demir Kılıç, Han Kılıcı, Han Arbaleti) tabloda değildir, sahnelere elle konur. **Esir yoktur** ([K23](/docs/source/design/decisions#k23)).

**Ne zaman** ([K49](/docs/source/design/decisions#k49)). I. Perde düşmanları yeni ganimet vermez, çünkü Mete rehinedir; orada mal avdan, işten ve takastan gelir. II. Perde'den açık dünyada her dövüş ganimet verir: yoldaki devriye, akıncı, düşman kampı ve def edilen akın aynı tablodan okur.

| Düşman | Perde | Düşman başına verim | Beklenen Kıymet (kabuk) |
|---|---|---|---|
| Hun Muhafızı | II | 0,6 Ham Deri, 0,6 Demir Hurda, 0,3 Tunç Hurda, 0,5 kabuk | 12,2 (3,1) |
| Tunghu Atlısı | III | 6 Tunç Ok, 0,3 Ham Deri, 0,15 Tilki Kürkü, 0,4 Tunç Hurda, 0,4 at | 154,8 (38,7) |
| Tunghu Seçkini | III | 6 Tunç Ok, 2 Tunç Hurda, 0,6 Demir Hurda, 0,5 at | 205,2 (51,3) |
| Yüeçi Mızraklısı | IV | 1,5 Demir Hurda, 0,3 Ham Deri, 0,45 at | 158,1 (39,5) |
| Saka Okçusu | IV | 10 Tunç Ok, 0,3 Keçe, 0,4 Tunç Hurda, 0,3 at | 126,1 (31,5) |
| Han Piyadesi | V | 2,1 Demir Hurda, 0,2 Ham Deri | 7,9 (2,0) |
| Han Arbaletçisi | V | 0,75 Demir Hurda, 9 Arbalet Oku | 15,8 (3,9) |
| Han arabası | V | 5 Tahıl Çuvalı, 2,4 Demir Hurda, 9 Arbalet Oku, 0,9 sığır | 296,7 (74,2) |
| Seçkin Muhafız | VI | 2,4 Demir Hurda, 0,6 Ham Deri, 1 kabuk, 0,5 at | 184,0 (46,0) |

```varlik
crowd_tunghu_rider, crowd_han_soldier, crowd_han_crossbow
iron_scrap, bronze_scrap, bolt, grain_sack, cowrie
```

- **Örnek:** on Tunghu Atlısı 60 Tunç Ok, 3 Ham Deri, 1 Tilki Kürkü, 4 Tunç Hurda, 4 at eder; on Hun Muhafızı 5 kabuk.
- **Kabuk** yalnız Hun düşmanında düşer, sayaçla: Hun Muhafızı 0,5, Seçkin Muhafız 1. Yabancı düşmanda (Tunghu, Yüeçi, Saka, Han) kabuk yoktur.
- **Kıymet** at 336, sığır 240, arbalet oku 1,5 ile hesaplanır: Han arabası 175,2'den 296,7'ye, Han Arbaletçisi 2,3'ten 15,8'e çıktı. Ganimet emek değildir, perde dakikasını değiştirmez.
- **Def edilen akın** ([K55](/docs/source/design/decisions#k55)). Düşen akıncılar aynı tablodan toplanan payla (×0,6) verir; küçük akında «Paylaş / Alıkoy» sorulmaz, Paylaş sayılır. Ordugâh akınında düşen atlının ganimeti ordugâhın ambarına girer.
- **Arbalet oku** Hun yayıyla atılmaz: satılır (8 adet 3 kabuk) ya da Demirci Ocağı'nda eritilir (8 ok → 1 Tunç Hurda).
- **Yoldaşlar.** Yoldaşın vurduğu düşmanın ganimeti aynı tablodan, aynı sayaçla düşer; «Ara»yı Mete yapar ([K70](/docs/source/design/decisions#k70)).

**Birim ölçeği.** Akından sonra havuz, yenilenlerin veriminin %60'ıdır. Karar Mete'nindir; yoldaş partisi bir onluk sayılır, karar yoldaşlara da onay yazar:

| Karar | Ambara | Etki |
|---|---|---|
| Paylaş | %25: atlar, oklar, hurda | Sadakat +8, Moral +6; yoldaş onayı +0,5 |
| Alıkoy | %75 | Sadakat −10, Moral −4, Korku +1; yoldaş onayı −0,5 |

Ambar payı ordugâhın Erzak Ambarı'na ve Silahlık'ına girer, yerleşime kervanla gider. **Yağmalanan kamp** kültürüne göre belirli yüktür: Tunghu kürk ve at; Yüeçi keçe, demir hurda ve firuze; Han arabası tahıl, demir hurda ve arbalet oku. Kaçanın bıraktığı sağlam yurt «Sök» ile Yurt Yükü olur: ev de alınır, insan alınmaz.

Doğrulanacak: benzetim ganimette at ve sığırı koddaki sabitle sayar ve Han arabasını 188,7 basar; doğrusu ekonomi modelinin fiyatıyla 296,7'dir ([Yol Haritası](/roadmap#item-econ-sim-run)).

## Söküm

Tek kural ([K46](/docs/source/design/decisions#k46)): sağlam taşınır yapı bohçasına döner; eksik ya da hasarlı hâller ve öteki yapılar ayaktaki adımların ham malının yarısını verir. Söküm emeği kurmanın 0,35'idir ve yurt eğrisiyle işler ([K50](/docs/source/design/decisions#k50)): `T(n) = taban × 0,75^(min(n, 8) − 1) × 0,35`.

| Durum | Dönen | Emek |
|---|---|---|
| Sağlam Hane Yurdu | 1 Yurt Yükü (59 Yük); köz söner | Tek başına 21 gerçek dk, dört elle 8,9 dk |
| Sağlam Küçük Yurt; Otağ, Bey Otağı | 1 Küçük Yurt Yükü (38 Yük); 1 Otağ Yükü (≈109 Yük) | Tek başına 8,4; 52,5 gerçek dk |
| Eksik yurt | Ayaktaki adımların ham malının yarısı; düşmüş ve yanmış birimin malzemesi yoktur | Ayaktaki adımların 0,35'i |
| Sağlam çadır | 1 Çadır Yükü (16 Yük) | ≈76 İD, tek başına ≈3,2 gerçek dk |
| Eksik ya da hasarlı çadır | Ayaktaki adımların ham malının yarısı | Ayaktaki adımların 0,35'i |
| Gecelik Çadır, sabah Topla | 1 Keçe ve 1 Sırık döner, döşek 1 Keçe olarak döner; 1 İp ve 2 Dal gider, kazık ve bağ yerde kalır | 15,1 İD, tek başına 38 gerçek sn; `T` ile atlanır |
| Öteki yapılar | Ayaktaki adımların ham malının yarısı | Ayaktaki adımların 0,35'i |
| Yıkıntı (aşama 0'a inmiş) | Düşen aşamaların ham malının %25'i, yer yığını olarak | Toplama |

Gecelik Kamp'ın kuruluşu: [Tek Gecelik Kamp](/docs/gameplay/overnight-camp).

## Oyunda şu an

> [!DURUM]
> Godot'da: toplama, av, sürü, ganimet ve söküm yok. Gece kampının odun yığını, fıçı ve kova modelleri (Meshy) yalnız süstür; Serbest Gez'de düğüm yoktur.
>
> Prototipte denendi: düğüm deposu, vuruş ve Tam Vuruş halkası, I. Perde düğüm listesi, sürü hesabı, ganimet tablosu ve sayacı (yalnız geliştirici panelinden). Godot'a taşınmadı.
>
> Yol Haritası: toplama ve düğüm hakları ([madde](/roadmap#item-gathering)), oyuncunun çevresinde akan düğüm parçaları ([madde](/roadmap#item-grass-streaming)), sürü ve atlı av ([madde](/roadmap#item-hunt-herds)), kabuk ve ganimet ([madde](/roadmap#item-currency)), çadır sökme ve at üstünde toplama ([madde](/roadmap#item-overnight-camp)).

## Kaynaklar

- [d2/core.md §5.3: Kaynaklar](/docs/source/design/d2/core#5-3-kaynaklar)
- [economy.md §3.1: Etkileşim kuralları](/docs/source/design/economy#3-1-etkilesim-kurallari) (at üstünde toplama), [§3.2: Düğüm tablosu](/docs/source/design/economy#3-2-dugum-tablosu)
- [economy.md §3.6: Av ve tuzak](/docs/source/design/economy#3-6-av-ve-tuzak), [§3.9: II. Perde ve sonrası toplama](/docs/source/design/economy#3-9-ii-perde-ve-sonrasi-toplama), [§3.10: Biyom](/docs/source/design/economy#3-10-biyom)
- [economy.md §3.11: Sürü](/docs/source/design/economy#3-11-suru), [§3.12: Savaş ganimeti](/docs/source/design/economy#3-12-savas-ganimeti), [§3.13: Söküm ve kurtarma](/docs/source/design/economy#3-13-sokum-ve-kurtarma)
- [fauna.md §3: Sürü ekonomisi](/docs/source/design/fauna#3-suru-ekonomisi), [§4: Av](/docs/source/design/fauna#4-av)
- [survival.md §4: Avcılık](/docs/source/design/survival#4-avcilik)
- [progression.md §9: Toplama ve erzak](/docs/source/design/progression#9-toplama-ve-erzak)
- [d2/core.md §7.1: Doğrulama turu](/docs/source/design/d2/core#7-1-dogrulama-turu-2026-11-03-v1-v39) (ot biçimi penceresi)
- [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- Kararlar: [K23](/docs/source/design/decisions#k23), [K24](/docs/source/design/decisions#k24), [K46](/docs/source/design/decisions#k46), [K49](/docs/source/design/decisions#k49), [K50](/docs/source/design/decisions#k50), [K55](/docs/source/design/decisions#k55), [K58](/docs/source/design/decisions#k58), [K65](/docs/source/design/decisions#k65), [K70](/docs/source/design/decisions#k70), [K79](/docs/source/design/decisions#k79)
- İlgili: [Hayvanlar](/docs/world/animals), [Ateş, Yemek ve Av](/docs/gameplay/fire-cooking-hunting), [Ordu](/docs/gameplay/army)
- Önceki: [Malzemeler](/docs/economy/materials). Sonraki: [Zanaat](/docs/economy/crafting)
