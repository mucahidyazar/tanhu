---
title: Malzemeler
order: 20
status: tasarim
summary: 'Bütün mallar tek taksonomidedir (Ham, İşlenmiş, Parça, Mamul, Bohça); sürü kaba girmeyen ayrı bir sayıdır, para Tunç Kabuk''tur, mallar perde perde açılır.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/d2/econ-model.json
  - docs/design/economy.md
  - docs/design/fauna.md
  - docs/design/survival.md
  - docs/design/story.md
  - docs/design/d3/oyun-durumu.md
---

Oyuncu odun keser, yün alır, deri yüzer, savaştan hurda toplar. Ham mal tarifle işlenir, parçaya döner, parça yapıya ya da teçhizata girer. Bütün perdelerin malı tek listededir; I. Perde'nin malları da bu listededir ve sayıları değişmedi ([K24](/docs/source/design/decisions#k24)). Ekonomi modelinde 134 eşya ve 87 tarif vardır: 2026-11-04 resmî koşusunda 131 eşya ve 85 tarifti, sonra mavi boya zinciri girdi ([K58](/docs/source/design/decisions#k58)).

> [!NOT]
> «o yüzden oyunda malzeme ve envanter sistemide olması gerekiyor yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak, malzemeler açık dünyada savaşlarla, ağaç kesere, avlanarak eti toplacanak, yine bir para birimi ve bu parayı harcayacak satıcılar etc olacak»

## Tek taksonomi

| Kademe | Ne | Örnek |
|---|---|---|
| Ham | Toplanır, avlanır, sağılır, kırkılır, yağmalanır | Çam Odunu, Ham Deri, Yün, Demir Hurda |
| İşlenmiş | Bir tarifle ham maldan çıkar, kendi başına alınıp satılır | İp, Keçe, Sepi Deri, Kömür, Demir Külçe |
| Parça | Yapıya, araca, teçhizata girer, kendi başına kullanılmaz | Kerege Takımı, Teker Çifti, Demir Temren |
| Mamul | Kullanılır, giyilir, yenir, atılır | Hun Yayı, Demir Temrenli Ok, Hun Kazanı, Köz Kabı, Tunç Kabuk |
| Bohça | Parçaların taşıma biçimidir, şantiyede açılır | Yurt Yükü, Küçük Yurt Yükü, Otağ Yükü, Çadır Yükü |
| Sürü | Sayıdır, kaba girmez | Koyun, At, Deve |

Yol tektir: ham → işlenmiş → parça → mamul ya da yapı. K24 listeye 23 yeni mal ekledi. Üçüncü tur 10 eşya, 4 yapı ve 8 tarif ekledi ([economy.md §2.11](/docs/source/design/economy#2-11-ucuncu-turun-kimlikleri-k46-k48-k49-k51-k58-k65)): Tunç Kabuk ([K48](/docs/source/design/decisions#k48)), Arbalet Oku ([K49](/docs/source/design/decisions#k49)), İri Post ([K65](/docs/source/design/decisions#k65)), Küçük Kerege Takımı, Küçük Uuk Demeti, Küçük Yurt Yükü, Otağ Yükü ([K51](/docs/source/design/decisions#k51)), Çivit Otu, Mavi Boya ve Boyalı Pelerin ([K58](/docs/source/design/decisions#k58)); yapılar Gecelik Çadır, Döşek ([K46](/docs/source/design/decisions#k46)), Küçük Yurt ve Bey Otağı. Kalite yalnız teçhizattadır; malzemede, parçada ve yiyecekte kalite yoktur ([Zanaat](/docs/economy/crafting#ince-is)).

**Ham Deri ve Sepi Deri ayrı maldır.** Ham Deri sapana, keçe eyere, toynak sargısına, deri dilimli zırha doğrudan girer. Yumuşak iş (çizme, kuşak, kolluk, sadak, eyer, koşum) Sepi Deri ister; o da II. Perde'nin Sepi Yeri'nde açılır.

## Etiketler

Tarif bazen tür değil etiket ister. «Odun» yazan yere her odun gider; tür yalnız küçük fark yaratır. Yanlış tür getir götür işi yoktur ([economy.md §14](/docs/source/design/economy#14-kararlar-ve-sapmalar), karar 10).

| Etiket | Mallar | Okuyan |
|---|---|---|
| Odun | Bütün odunlar | Yapı ve tarif «odun»u |
| Hafif odun | Söğüt, Huş, Ilgın, Toğrak | Kerege (odunun yarısı hafifse aşama canı +%10), ok gövdesi, eyer kaşı |
| Sert odun | Karaağaç, Saksavul, Melez | Teker (ikisi de sertse araba canı +%25) |
| Yakacak | Odunlar, Dal, Ardıç Dalı, Tezek, Kömür | Ateş, Yakacak çizgisi |
| Kav | Reçine, Saz, Huş Kabuğu | Ateş kavı |
| Lif | Saz, Yün, Kıl | İp, çiy |
| Kaba yem | Ot, Saman | Yem Bağı, Sundurma |
| Sepi katkısı | Tuz, İç Yağı, Süt | Sepi |
| Tahıl | Darı, Arpa Torbası, Tahıl Çuvalı | Tahıl Ambarı ve Ambar Çukuru kabulü, pay hesabı |
| Değerli | Ham Firuze, Ham Yeşim, Altın Kumu, Eski Altın, Gümüş Parça, Samur Kürkü, İri Post, İpek Top, Tunç Kabuk | Hazine kabulü |

## Başlıca mallar

Kıymet gizli ölçektir, oyuncu görmez. II. Perde'den fiyat kabukla yazılır: 1 kabuk = 4 Kıymet = 1 Aş ([Para ve Satıcılar](/docs/economy/money-traders#kiymet)). «Perde», malın ilk toplanabildiği ya da alınabildiği perdedir.

**Odun, taş, yakacak.**

| Mal | Kademe | Yük | Kıymet | Kaynak | Perde |
|---|---|---|---|---|---|
| Çam Odunu | Ham | 4 | 4 | Odunluk, Çam | I |
| Ardıç Odunu | Ham | 4 | 4 | Ardıç | I |
| Söğüt Odunu | Ham | 3 | 3 | Söğüt | I |
| Huş Odunu | Ham | 3 | 4 | Huş; tündük ve yay gövdesi | II |
| Karaağaç | Ham | 4 | 4 | Karaağaç; araba aşaması canı +%10 | II |
| Ilgın | Ham | 2 | 3 | Ilgın; ok gövdesi | II |
| Saksavul | Ham | 5 | 5 | Saksavul; ağaçsız Gobi'nin yakacağı | II |
| Melez Odunu | Ham | 4 | 4 | Melez; Hangay ve Hentiy ormanı | III |
| Toğrak | Ham | 4 | 4 | Toğrak; Hey Irmağı aşağı kolu | IV |
| Dal | Ham | 0,5 | 1 | Kuru Dal | I |
| Reçine | Ham | 0,2 | 2 | Reçineli Gövde; kav, meşale | I |
| Huş Kabuğu | Ham | 0,1 | 1 | Huş; kav, tündük ve kap; III'ten Takas Yeri gezgini | II |
| Taş Blok | Ham | 5 | 3 | İlk Taşlar, Taşlık, Kaya, Taş Ocağı | I |
| Kil | Ham | 3 | 2 | Kil Yarı | I |
| Tuz | Ham | 0,5 | 8 | Tuz Kabuğu, takas | I |
| Tezek | Ham | 0,5 | 1 | Tezek, sürü | I |
| Kömür | İşlenmiş | 1 | 3 | Kömür Ocağı; II'den Fırın | I |

```varlik
wood_pine, wood_juniper, wood_willow, wood_birch, wood_elm, wood_tamarisk, wood_saxaul, wood_larch, wood_poplar
branch, resin, birch_bark, stone, clay, salt, dung, charcoal
```

**Lif ve hayvan ürünü.**

| Mal | Kademe | Yük | Kıymet | Kaynak | Perde |
|---|---|---|---|---|---|
| Saz | Ham | 0,5 | 1 | Saz Kümesi | I |
| Ot | Ham | 1 | 1 | Ot Yığını, biçim | I |
| Yün | Ham | 0,5 | 2 | I'de Yün Balyası, sonra kırkım | I |
| Kıl | Ham | 0,2 | 1 | Sürü, ganimet atı | II |
| Ham Deri | Ham | 1,5 | 8 | Mutfak Artığı, av, kesim; III'ten Tunghu haracı | I |
| Küçük Post | Ham | 0,5 | 2 | Tavşan, tarbagan | I |
| Tilki Kürkü | Ham | 0,5 | 12 | Tilki | I |
| Kurt Kürkü | Ham | 1 | 16 | Kurt | I |
| İri Post | Ham | 1,5 | 48 | Kaplan (III), kar leoparı (IV); Hazine malı, sıcaklık vermez | III |
| Samur Kürkü | Ham | 0,2 | 40 | Samur, Dingling takası | VI |
| Kemik | Ham | 0,5 | 1 | Çukur, Mutfak Artığı, av | I |
| Boynuz | Ham | 1 | 6 | Yaban keçisi, Mutfak Artığı | I |
| Sinir | Ham | 0,2 | 4 | Av, Mutfak Artığı | I |
| İç Yağı | Ham | 0,5 | 2 | Av | I |
| Tüy | Ham | 0,1 | 1 | Karga, keklik | I |
| İp | İşlenmiş | 0,5 | 3 | 3 Saz ya da 2 Kıl | I |
| Keçe | İşlenmiş | 1 | 5 | 2 Yün | I |
| Ak Keçe | İşlenmiş | 1 | 9 | 3 Yün | II |
| Sepi Deri | İşlenmiş | 1 | 11 | 1 Ham Deri, 1 sepi katkısı | II |
| Tutkal | İşlenmiş | 0,1 | 2 | Kemik ya da balık; III'ten Takas Yeri gezgini | II |
| Kökboya | Ham | 0,1 | 2 | Kökboya düğümü; Hexi vahası | II |
| Çivit Otu | Ham | 0,1 | 2 | Çivit Otu düğümü, bozkırda kendiliğinden yetişir | II |
| Kızıl Boya | İşlenmiş | 0,1 | 5 | 2 Kökboya | II |
| Mavi Boya | İşlenmiş | 0,1 | 5 | 2 Çivit Otu | II |
| Kandil Yağı | İşlenmiş | 0,5 | 3 | I'de Opia ve Kandil Yağı görevi; II'den 1 İç Yağı, Kazan Ocağı; III'ten Takas Yeri gezgini | I |
| Yem Bağı | İşlenmiş | 2 | 4 | 2 Ot ya da 4 Saman | I |

**Boya** ([K58](/docs/source/design/decisions#k58)). Kızıl: 2 Kökboya → 1 Kızıl Boya; Kızıl Pelerin'e, otağ kuşağına, sancağa ve Gök Direği'ne girer. Mavi: 2 Çivit Otu → 1 Mavi Boya → Boyalı Pelerin (2 Keçe + 1 Mavi Boya, Keçe Avlusu). Pelerinin rengi oluşturucunun «Boya» satırından gelir, altı renk tek boyayla olur. Hun çağında mavi boyaya tanık yoktur [kurgu]. Tarifler: [Zanaat](/docs/economy/crafting#boya).

```varlik
reed, hay, wool, hair, hide, hide_small, fur_fox, fur_wolf, fur_big, fur_sable
bone, horn, sinew, fat, feather, rope, felt, felt_white, leather, glue, fodder
madder, dye, woad, dye_blue, lamp_oil
```

**Maden ve değerli mal.**

| Mal | Kademe | Yük | Kıymet | Kaynak | Perde |
|---|---|---|---|---|---|
| Demir Cevheri | Ham | 4 | 4 | Demir Damarı | I |
| Bakır Cevheri | Ham | 4 | 4 | Bakır Damarı | I |
| Kalay Cevheri | Ham | 4 | 8 | Kalay Damarı | IV |
| Demir Hurda | Ham | 0,5 | 3 | Ganimet; 4 hurda 1 külçe | II |
| Tunç Hurda | Ham | 0,5 | 12 | Kurgan, ganimet; V'te 8 arbalet okundan | I |
| Bakır Parça | İşlenmiş | 0,5 | 5 | 1 Bakır Cevheri | I |
| Demir Külçe | İşlenmiş | 2 | 16 | Kujul; II'den Demirci Ocağı, armağan, satıcı | I |
| Tunç Külçe | İşlenmiş | 2 | 20 | Demirci Ocağı | II |
| Kalay Külçe | İşlenmiş | 1 | 40 | I–III yalnız takas; IV'te tarif | I |
| Ham Firuze | Ham | 0,5 | 32 | Takas; IV'te damar | I |
| Gümüş Parça | Ham | 0,1 | 32 | Görev, tartıyla takas; II'den Hun satıcısında 8 kabuk | I |
| Eski Altın | Ham | 0,2 | 96 | Ölünün Altını görevi; II'den Hun satıcısında 24 kabuk | I |
| Altın Kumu | Ham | 0,1 | 24 | Altın Kumu yatağı | IV |
| Ham Yeşim | Ham | 1 | 64 | Hotan yolu, Hexi vahası | IV |

```varlik
ore_iron, ore_copper, ore_tin, iron_scrap, bronze_scrap, copper_bit, iron_bar, bronze_bar, tin_ingot
turquoise_raw, silver_bit, gold_old, gold_dust, jade_raw
```

**Parça ve bohça.** Yurt parçalarının çoğu Ağaç Atölyesi'nde yapılır; atölye Oba'da (2. kademe) açılır, ondan önce tündük Tanhu pazarcısından gelir ([K52](/docs/source/design/decisions#k52)).

| Mal | Kademe | Yük | Kıymet | Kaynak | Perde |
|---|---|---|---|---|---|
| Sırık | Parça | 1,5 | 3 | 1 odun 2 sırık | I |
| Tündük | Parça | 6 | 30 | I'de Nanay, II'den Ağaç Atölyesi ve pazarcı | I |
| Ulu Tündük | Parça | 10 | 62 | Ağaç Atölyesi; otağın tündüğü | III |
| Bosağa | Parça | 8 | 32 | Ağaç Atölyesi; yurdun 1. aşaması | II |
| Kerege Takımı | Parça | 14 | 47 | Ağaç Atölyesi; 2. aşama | II |
| Küçük Kerege Takımı | Parça | 7 | 24 | Ağaç Atölyesi; Küçük Yurt'un dört kanadı | II |
| Uuk Demeti | Parça | 16 | 54 | Ağaç Atölyesi; 4. aşama | II |
| Küçük Uuk Demeti | Parça | 8 | 27 | Ağaç Atölyesi; Küçük Yurt'un çatısı | II |
| Çiy | Parça | 3 | 8 | Keçe Avlusu; 5. aşama | II |
| Teker Çifti | Parça | 6 | 16 | Ağaç Atölyesi; her araba | II |
| Eyer Kaşı | Parça | 1,5 | 13 | Ağaç Atölyesi; ağaç ve savaş eyeri | II |
| Ok Gövdesi | Parça | On adet 0,5 | 0,35 | Hafif odun ya da dal | II |
| Kemik, Tunç, Demir Temren | Parça | On adet 0,5 | 0,35; 1; 1,6 | El ya da Demirci Ocağı | II |
| Çadır Yükü | Bohça | 16 | 42 | Sağlam çadırın sökümü, bohçalama | II |
| Küçük Yurt Yükü | Bohça | 38 | 158 | Söküm, bohçalama | II |
| Yurt Yükü | Bohça | 59 | 240 | Söküm, bohçalama, armağan, ganimet, takas | II |
| Otağ Yükü | Bohça | ≈109 | 516 | Söküm, bohçalama; bey hanesi bununla gelir | III |

**Yurt Yükü** yurdun taşsız ve közsüz bütün parçalarıdır: Bosağa 8, Kerege Takımı 14, Tündük 6, iki Sırık 3, Uuk Demeti 16, Çiy 3, altı Keçe 6, altı İp 3 = 59 Yük. Bir keçe arabaya, bir yük devesine ya da iki yük atına sığar ([K65](/docs/source/design/decisions#k65)). Bohçanın Kıymet'i parçalarının toplamının 1,067 katıdır: bohçalamak küçük bir emek değeri katar.

```varlik
pole, yurt_crown, crown_great, door_frame, kerege_set, kerege_set_s, uuk_set, uuk_set_s, chiy
wheel_pair, saddle_tree, arrow_shaft, arrowhead_bone, arrowhead_bronze, arrowhead_iron
tent_kit, yurt_kit_s, yurt_kit, otag_kit
```

**Mamul, yiyecek, ticaret malı.**

| Mal | Kademe | Yük | Kıymet | Kaynak | Perde |
|---|---|---|---|---|---|
| Kemik, Tunç, Demir Temrenli Ok | Mamul | On adet 0,5 | 1,3; 1,9; 2,5 | El; ordugâh, Okçu Yurdu | I; II; II |
| Arbalet Oku | Mamul | On adet 0,5 | 1,5 | Han ganimeti; Hun yayıyla atılmaz, ok sayılmaz | V |
| Tunç Kabuk | Mamul | Yüz adet 0,1 | 4 (1 kabuk) | Teoman'ın kesesi, satış, görev, ganimet; IV'ten Demirci Ocağı | II |
| Küçük Kazan | Mamul | 2 | 6 | 2 Kil; satıcı | I |
| Hun Kazanı | Mamul | 8 | 90 | Demirci Ocağı; 1 et 5 öğün eder | II |
| Köz Kabı | Mamul | 1 | 15 | 1 Küçük Kazan, 1 Ham Deri | II |
| Boş Tulum | Mamul | 0,5 | 8 | 1 Ham Deri | II |
| Boyalı Pelerin | Mamul (teçhizat) | 1 | Önerilen 17 | 2 Keçe, 1 Mavi Boya; Keçe Avlusu. II'nin pelerini | II |
| Et | Ham | 0,5 | 4 | Av, kesim; çiğ, bozulur | I |
| Darı | Ham | 0,1 | 2 | Sazlık Pazarı, Ambar, pazarcı; VI'dan Surlu tarlası | I |
| Süt | Ham | 0,5 | 2 | Süt Kovası, sağım | I |
| Aş | İşlenmiş | 0,1 | 4 | 2 Darı; 1 öğün | I |
| Kak | İşlenmiş | 0,1 | 4 | Et, Tuz; bozulmaz | I |
| Kurut | İşlenmiş | 0,1 | 2 | Süt, Tuz; bozulmaz | I |
| Arpa Torbası | Ham | 2 | 8 | Takas, tayın, Ambar; 6 öğün | I |
| Tahıl Çuvalı | Ham | 2 | 12 | IV'te Hexi vahası; V–VI'da heqin ve Han ganimeti; 6 öğün | IV |
| İpek Top | Ham | 1 | 48 | Heqin, sınır pazarı; Divan armağanında ×1,5 sayılır | V |
| Şarap Küpü | Ham | 3 | 32 | Heqin, sınır pazarı | V |

```varlik
cowrie, bolt, dyed_cape, silk_bolt, wine_jar, grain_sack, barley_sack, millet, meal, dried_meat, qurt
```

**Sürü** baş sayısıdır, Yük tutmaz. Fiyatı K49'dur: koyun 48 (12 kabuk), keçi 40 (10), sığır 240 (60), at 336 (84), deve 504 (126); yak 240, eşek 144, katır 240, domuz 64 ([K49](/docs/source/design/decisions#k49)). Ayrıntı: [Toplama ve Kaynaklar](/docs/economy/gathering#suru). **Köz Kabı** yanan ocakta 2 sn'de dolar, 48 oyun saati yanar, her Kömür +24 saat verir; sönerse «Köz söndü».

Tam liste: [economy.md §2](/docs/source/design/economy#2-kaynak-taksonomisi), yiyecekler [§5.2](/docs/source/design/economy#5-2-yiyecek-tablosu), teçhizat [progression.md §6.2](/docs/source/design/progression#6-2-giyilen-esya).

## Perdeye göre açılış

Perdeler takvimde başlar. «Oynanan gün» K25'in tasarım ölçüsüdür: oyunda sayaç yoktur, perde son ana görevle biter, takvim akar ([K42](/docs/source/design/decisions#k42)). Aradaki yılları Akan Kronik işler.

| Perde | Başı | Oynanan gün (ölçü) | Yeni mal | Ekonominin yüzü |
|---|---|---|---|---|
| [I «Çan»](/docs/story/act-1) | 2 Aralık MÖ 210, kış | 6 | Çam, ardıç, söğüt; dal, reçine, kömür; taş, kil, tuz; bakır ve demir cevheri, külçe; saz, ip, yün, keçe; ham deri ve av ürünü; tündük, sırık | Kış Hesabı, tayın, zula, Kantu'nun arabası; para yok, Terazi sayısız; sayılar değişmez; yeni olan yalnız at üstünde toplama |
| [II «Ok Neyi Gösterirse»](/docs/story/act-2) | 1 Haziran MÖ 209, yaz | 12 | Huş, huş kabuğu, karaağaç, ılgın, saksavul; kökboya, çivit otu, kıl, demir hurda; ak keçe, sepi deri, tutkal, kızıl ve mavi boya, tunç külçe; Boyalı Pelerin; yurt parçaları (iki boy), teker çifti, eyer kaşı, ok gövdesi, temrenler; Yurt Yükü, Küçük Yurt Yükü, Çadır Yükü; Köz Kabı, Hun Kazanı; Gecelik Çadır ve döşek; Tunç Kabuk; kısrak sütü | Kendi ocağın: Ocak → Oba; Teoman'ın armağanı; kabuk Tanhu pazarcısında görünür; Ağaç Atölyesi ve Demirci Ocağı Oba'da; yük atı ve binek deve; Ocak'ta Azıkçı; savaş ganimeti başlar; akın yok |
| [III «Boş Toprak»](/docs/story/act-3) | 1 Eylül MÖ 208, güz | 12 | Melez, Ulu Tündük, Otağ Yükü; İri Post (kaplan); karaca ve ayı avı | Boy Yurdu: otağ, Gök Direği, Takas Yeri ve Hun gezgini (Kandil Yağı, sinir, tutkal, huş kabuğu, tunç hurda; [K81](/docs/source/design/decisions#k81)); soğum ve ilk yerleşim kışı; Tunghu ganimeti (kürk, at); Tunghu yenilince yılda 20 deri haraç; akın yalnız 15–17 Eylül penceresinde |
| [IV «Borç»](/docs/story/act-4) | 1 Haziran MÖ 205, yaz | 14 | Toğrak; kalay cevheri ve külçesi, firuze damarı, altın kumu, ham yeşim; Tahıl Çuvalı; kar leoparının İri Postu; yak, eşek | Toy Yeri: Hazine, kuyu, Bey Otağı, ordu arabası; Saka ve Hexi vahası satıcısı; Demirci Ocağı'nda tunç kabuk; kereste kervanı; akın iki pencerede |
| [V «Dört Renk»](/docs/story/act-5) | 20 Kasım MÖ 201, kış | 12 | İpek Top, Şarap Küpü, Arbalet Oku; katır, Surlu yolda domuz | Tanhu Avlusu: Surlu ya da Göçer; Han ganimeti (demir hurda, tahıl arabası, sığır, arbalet oku); tarla V'te ürün vermez; perdede akın yok |
| [VI «Sayım»](/docs/story/act-6) | 1 Haziran MÖ 198, yaz | 16 | Samur Kürkü | Yönetim, dağıtım Kut terazisinde; heqin malı, sınır pazarı, Dingling; ilk tarla hasadı; at ve deve yarışı; mektup armağanı (1 deve, 2 binek, 8 koşum atı) |

**II. Perde'nin açılış malı** ([K23](/docs/source/design/decisions#k23), [K48](/docs/source/design/decisions#k48)). [Teoman](/encyclopedia/teoman)'ın armağanı: bir Yurt Yükü, bir keçe araba, ≈30 at eşdeğeri sürü (60 koyun, 10 keçi, 16 at, 4 sığır), sürünün bahar kırkımı olarak 60 Yün, 6 Demir Külçe, ≈15 günlük azık (400 Darı, 30 Kak; ≈217 öğün) ve 24 kabukluk kese. Neden böyle:

- II 1 Haziran'da açılır, kırkım bahar sonunda bitmiştir: perdede yeni yün yoktur. Armağanın 60 yünü ve gelen hanenin getirdiği yün II'nin ≈60 keçesini karşılar.
- Külçe yalnız Demirci Ocağı'nda yapılır; demirci Dutu Oba'yla gelir. Altı külçe Ağaç Atölyesi'ne ve demirci gelmeden kurulan iki yurdun bosağasına yeter ([K52](/docs/source/design/decisions#k52)).
- 24 kabuk Ocak'ın pazardan alacağı iki tündüğe (≈19 kabuk) yeter.

Gelen hane iki türdür ([K53](/docs/source/design/decisions#k53)): Yüklü Hane evini (yurt ya da çadır) kendi atına ve devesine yükleyip 5 günlük azığı ve son kırkımının yarısıyla (yaz başında ≈18 yün) gelir; İsteyen Hane yalnız azığıyla gelir ve barınak ister.

## Tarih kapısı

Vadide her cevher bulunmaz; bulunmayan takas ya da görevle gelir.

| Mal | I. Perde vadisinde | Sonra |
|---|---|---|
| Bakır | Toplanır: Bakır Damarı | Eski damarlar; atlasta Beishan |
| Demir | Toplanır: Galeri Ağzı, Kara Tepeler | II: Terelj çevresi |
| Kalay | Toplanmaz; Nandu'da en çok 1 külçe, kurgan tuncu | IV: Altay eteği (tasarım tercihi), yoksa hep takas |
| Altın | Toplanmaz; yalnız Eski Altın, Altın Levha | IV: Altay eteği, plaser |
| Firuze | Toplanmaz; Nandu'da 2 ham taş | IV: Dunhuang yönü |
| Tuz | Toplanır: Tuz Kabuğu; Yuan ve Nandu'da takas | III'ten Köke Nur |

## Oyunda şu an

> [!DURUM]
> Godot'da: mal listesi, tarif ve tezgâh verisi yok; `game/data` yalnız Destan Kitabı'nın üç dosyasını taşır. Malların görseli varlık kataloğundadır; görseli henüz üretilmemiş mal boş kutuyla görünür.
>
> Prototipte denendi: mal tablosu, etiket eşleme, İnce İş eki, tarif ve tezgâh verisi; veri denetimi ekonomi modeliyle eşitliği geçti. Godot'a taşınmadı.
>
> Godot'daki plan: mal verisi ekonomi modelinden (`d2/econ-model.json`) dışa aktarılır, kimlikler aynı kalır ([godot.md §3](/docs/source/design/godot#3-sistem-haritasi)). II. Perde'nin malları yerleşim ve ekonomi fazında oyuna girer:

```ilerleme
act-2-p2
```

## Kaynaklar

- [d2/core.md §5.1: Taksonomi](/docs/source/design/d2/core#5-1-taksonomi)
- [d2/core.md §5.2: Yeni ve değişen kimlikler](/docs/source/design/d2/core#5-2-yeni-ve-degisen-kimlikler)
- [d2/core.md §5.10: Para ve fiyat](/docs/source/design/d2/core#5-10-para-ve-fiyat-k48-k49)
- [economy.md §2: Kaynak taksonomisi](/docs/source/design/economy#2-kaynak-taksonomisi)
- [economy.md §2.7: Kademe ve etiket](/docs/source/design/economy#2-7-kademe-ve-etiket-tier-and-tag-k24)
- [economy.md §2.11: Üçüncü turun kimlikleri](/docs/source/design/economy#2-11-ucuncu-turun-kimlikleri-k46-k48-k49-k51-k58-k65)
- [economy.md §6.9: İşleme zincirleri](/docs/source/design/economy#6-9-isleme-zincirleri) (boya)
- [economy.md §9.5: II. Perde ve sonrası satıcıları](/docs/source/design/economy#9-5-ii-perde-ve-sonrasi-saticilari) (Takas Yeri gezgini)
- [economy.md §8.3: II. Perde](/docs/source/design/economy#8-3-ii-perde-kendi-ocagin)
- [economy.md §8.6: Perde perde ekonomi](/docs/source/design/economy#8-6-perde-perde-ekonomi)
- [fauna.md §1: Tür kataloğu](/docs/source/design/fauna#1-tur-katalogu) (av ve kesim verimi)
- [story.md §2: Zaman çizelgesi](/docs/source/design/story#2-zaman-cizelgesi-1)
- Kararlar: [K23](/docs/source/design/decisions#k23), [K24](/docs/source/design/decisions#k24), [K42](/docs/source/design/decisions#k42), [K46](/docs/source/design/decisions#k46), [K48](/docs/source/design/decisions#k48), [K49](/docs/source/design/decisions#k49), [K51](/docs/source/design/decisions#k51), [K52](/docs/source/design/decisions#k52), [K53](/docs/source/design/decisions#k53), [K54](/docs/source/design/decisions#k54), [K58](/docs/source/design/decisions#k58), [K65](/docs/source/design/decisions#k65), [K81](/docs/source/design/decisions#k81)
- [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- Önceki: [Envanter ve Yük](/docs/economy/inventory-load). Sonraki: [Toplama ve Kaynaklar](/docs/economy/gathering)
