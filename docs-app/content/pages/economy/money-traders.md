---
title: Para ve Satıcılar
order: 50
status: tasarim
summary: 'I. Perde''de para yoktur, rehine Mete Terazi''de sayısız takas eder; II. Perde''den Kabuk görünür: 1 kabuk = 4 Kıymet = 1 Aş, Hun satıcısı keseden üstü verir, yabancı satıcı kabuğu ×0,6 alır.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/d2/econ-model.json
  - docs/design/economy.md
  - docs/design/settlement.md
  - docs/design/travel.md
  - docs/design/progression.md
  - docs/research/bozkir-ekonomi.md
  - docs/design/d3/oyun-durumu.md
---

Oyuncu satıcıyla iki kefeli bir Terazi'de alışveriş eder: malı kefeye koyar, kiriş eğilir. Arkadaki ölçü gizli **Kıymet**'tir; bu söz oyuncuya hiç çıkmaz. I. Perde'de para yoktur: [Mete](/encyclopedia/mete) rehinedir, mal malla tartılır, sayı görünmez. II. Perde'den para birimi **Kabuk / Cowrie** görünür: 1 kabuk = 4 Kıymet = 1 Aş ([K48](/docs/source/design/decisions#k48)). Fiyat kabukla yazılır, Hun satıcısı keseden üstü verir, yabancı satıcı mal ister. Satıcılar: I. Perde'de 7, II. Perde'den sonra 7.

> [!NOT]
> «o yüzden oyunda malzeme ve envanter sistemide olması gerekiyor yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak, malzemeler açık dünyada savaşlarla, ağaç kesere, avlanarak eti toplacanak, yine bir para birimi ve bu parayı harcayacak satıcılar etc olacak»

Kabuk ve onu harcatan satıcılar bu isteğin karşılığıdır ([K48](/docs/source/design/decisions#k48)). İlke tek cümledir: rehine tartar, Tanhu sayar. Rehinelikten çıkışın ilk sesi pazarcının «Burada sayarız.» sözüdür.

## Takas kuralı

Terazi iki kefeyi karşılaştırır. Formül tektir; kabuk II'den oyuncunun kefesine girer ([economy.md §9.1](/docs/source/design/economy#9-1-kural)).

| Terim | Kural |
|---|---|
| Satıcının malı | Kıymet toplamı × `buyK` |
| Oyuncunun malı | Kıymet toplamı × `sellK` + kabuk × 4 × `cowrieK` (II'den) |
| `buyK` | 1,25 − 0,03 × (Söz − 3) − 0,02 × satıcıyla bağ; en az 0,9, en çok 1,25. Opia'da +0,25 |
| `sellK` | Satıcı istiyorsa 1, nötrse 0,6, almıyorsa 0 |
| `cowrieK` | Hun satıcısı 1, yabancı satıcı 0,6; I. Perde'de kabuk yok |
| Kabul | Oyuncunun kefesi ≥ satıcının kefesi |
| Üstü | I. Perde'de verilmez. II'den keseli Hun satıcısı verir: (oyuncu − satıcı) ÷ 4, aşağı yuvarlanır, en çok kesedeki kadar kabuk |
| Yuvarlama | Satıcının kefesi yukarı, oyuncunun kefesi aşağı; satır değil toplam yuvarlanır |

**Örnek, I. Perde (hesap).** Söz 3, bağ 0 iken `buyK` 1,25'tir. [Nandu](/encyclopedia/nandu)'nun 1 Tuz'u 8 × 1,25 = 10 eder. Nandu Ham Deri (8) ve Küçük Post (2) ister: ikisi birlikte tam 10, kefe denk. Söz 7, bağ 5 iken aynı Tuz 8,24 eder.

**Örnek, II. Perde (hesap).** Aynı Söz ve bağla Tanhu pazarcısının iki Tündüğü 60 × 1,25 = 75 Kıymet eder. 19 kabuk (76 Kıymet) kefeyi denkler, üstü 0'dır; 18 kabuk «Eksik» kalır. [Teoman](/encyclopedia/teoman)'ın kesesi 24 kabuktur, iki tündük ondan 19'unu alır. Yabancı satıcıda bir kabuk 4 × 0,6 = 2,4 Kıymet eder.

- Stok ve satıcı kesesi şafakta yenilenir. Satıcı 06:00–20:00 açıktır ([K20](/docs/source/design/decisions#k20)).
- Satıcı istediğini satmaz: aynı satıcıda döngü kurulmaz. Satıcılar arası kâr en çok %11'dir (1 ÷ 0,9) ve stokla, keseyle sınırlıdır.
- Hatıra sekmesindeki mal satılmaz. Satıcı İnce İş satmaz.
- Rehine at ve silah satın alamaz. Nandu: «Rehineye ok satmam. Başım gider.»
- **Tartılan maden.** I. Perde'de gümüş ve tunç tartılır, sayılmaz. II'den Hun satıcısı Gümüş Parça'yı 8, Eski Altın'ı 24 kabuk sayar. Han sikkesi V. Perde'de tartılır: bir dizi 3 kabuktur, «Yaprak gibi.» / «Light as a leaf.»
- **Yoldaşın takas etkisi.** [Wang Huang](/encyclopedia/wang-huang) her takasta, [Zhang Sheng](/encyclopedia/zhang-sheng) Han satıcısıyla fiyatı ×0,95 yapar; etkiler birikmez ve satıcı kesesini değiştirmez ([economy.md §4.8](/docs/source/design/economy#4-8-yoldasin-yuku-payi-bakimi-k70)).

## Kabuk

Birim Kabuk / Cowrie'dir, eşyanın adı «Tunç Kabuk / Bronze Cowrie» ([K48](/docs/source/design/decisions#k48), [economy.md §9.6](/docs/source/design/economy#9-6-kabuk-cowrie-k48)).

| Alan | Kural |
|---|---|
| Oran | 1 kabuk = 4 Kıymet = 1 Aş; 100 kabuk 0,1 Yük. Kıymet ölçeği değişmez |
| I. Perde | Kabuk yoktur: Mete rehinedir, Terazi sayısız takastır |
| İlk görünüş | II. Perde, Tanhu pazarcısı: «Burada sayarız. Bir Aş, bir kabuk.» / «Here we count. One meal, one cowrie.» |
| Hun satıcısı | Tanhu pazarcısı, Takas Yeri gezgini, Çiang tuzcusu: kabuğu tam alır, üstü verir; kesesi şafakta dolar: 52, 30, 26 kabuk |
| Yabancı satıcı | Saka tüccarı, Hexi vahası, sınır pazarı, Dingling kürkçüsü: kabuğu ×0,6 alır, üstü vermez, kesesi yoktur, mal ister |
| Kese neden var | Parayla oyuncu her şeyi satabilirdi; kese takasın sınırını geri getirir. Büyük mal takasla döner: bir at 84 kabuktur, en dolu Hun kesesini (52) aşar. Kese yetmezse «Kesem yetmez.» / «My purse won't cover it.» |
| Kaynak | Teoman'ın kesesi 24 kabuk (armağana ek); satış; görev; ganimet (Hun Muhafızı 0,5, Seçkin Muhafız 1, sayaçla); IV'ten Demirci Ocağı'nda 1 Tunç Hurda → 3 kabuk (usta, 1 İS) |
| Harcama | Pazar; yol bedeli (Aş ya da kabuk, 1:1); Divan'da kefaret; Toy'da saçı: hane başına 1 kabuk, toyun Gönül'ü +6 yerine +8 |
| Sınır | Hiçbir kademe kapısı kabuk istemez; benzetim kabuksuz da her kademeyi bitirir. Kâhya kabuk harcamaz, Kronik kabuğa dokunmaz |
| Akın | Hazine'deki kabuğun %30'u gider (30 m içinde Gözcü Kulesi varsa ×0,5); Mete'nin kesesi güvendedir |
| Arayüz | Heybe'nin üst satırında «Kese {n}»; HUD'a eklenmez. Hazine terazisinin yanında «≈{n} kabuk» |
| Neden kabuk | Kabuk ve tunç taklidi Hun kemerlerinde yaygındır; Ivolga'da kabuğun para olarak kullanıldığı varsayılır ([bozkir-ekonomi.md §1.6](/docs/source/research/steppe-economy#1-6-kabuk)). Gümüşten bir birim («Kümüş») seçilmedi: gümüş Ç'in ve Han'da para değildi, Gümüş Parça ile karışır, İngilizcede okunmaz. Hun'un kabuk sayması tasarım tercihidir; Destan Kitabı bunu yazar |

Kabuk döngü kurmaz: 3 kabuk 12 Kıymet'tir, bir Tunç Hurda'nın Kıymeti kadar (tarifin oranı 0,94); yabancı satıcı kabuğu ×0,6 alır. Mete'nin kesesi: [Envanter ve Yük](/docs/economy/inventory-load#heybe).

```varlik
cowrie, bronze_scrap, silver_bit, gold_old
```

## Kıymet

Kıymet oyuncunun görmediği tek ölçüdür; II'den fiyat kabukla yazılır, kabuk Kıymet ÷ 4'tür. Ölçek kabaca emek saniyesi ÷ 5'tir. Fiyatın tek sahibi ekonomi modelidir (`d2/econ-model.json`): takas, ganimet ve benzetim oradan okur ([K49](/docs/source/design/decisions#k49)). Yeni mallarda Kıymet girdi + 0,75 × İS (iş saati) ile önerilir; tarif oranı 0,85–1,6 bandında kalır ya da gerekçe ister ([economy.md §6.11](/docs/source/design/economy#6-11-kiymet-dengesi)). Kak, Kurut ve Kömür bilerek kayıplıdır: satıcının onları girdisinden ucuza alması döngü kurmayı önler.

| Mal | Kıymet | Kabuk | Perde ve not |
|---|---|---|---|
| Kurut, Balık, Yün | 2 | 0,5 | I |
| Aş, Kak, Çam Odunu, Yem Bağı | 4 | 1 | I |
| Arpa Torbası | 8 | 2 | I; takas, tayın; 6 öğün |
| Ham Deri, Tuz | 8 | 2 | I |
| Tahıl Çuvalı | 12 | 3 | IV, Hexi vahası satar; V ve VI'da heqin ve Han ganimeti; 6 öğün |
| Tunç Hurda | 12 | 3 | I; kurgan, ganimet |
| Demir Külçe | 16 | 4 | I |
| Gümüş Parça | 32 | 8 | I; II'den Hun satıcısı tam alır |
| Şarap Küpü | 32 | 8 | V, heqin |
| İpek Top | 48 | 12 | V, heqin; Hun satıcısı az öder (`sellK` 0,6), Tarım vahası tam alır; Divan armağanında ×1,5 sayılır |
| İri Post | 48 | 12 | III, kaplan; IV, kar leoparı |
| Ham Yeşim | 64 | 16 | IV, Hotan yolu |
| Eski Altın | 96 | 24 | I; II'den Hun satıcısı tam alır |
| Çadır Yükü, Küçük Yurt Yükü | 42; 158 | 10,5; 39,5 | II |
| Yurt Yükü, Otağ Yükü | 240; 516 | 60; 129 | II; III. Yurt Yükü'nü pazarcı haftada bir getirir |
| Arbalet Oku | 1,5 | 8 adet 3 | V, Han ganimeti; Hun yayıyla atılmaz, ok sayılmaz; 8'i 1 Tunç Hurda eder |

**Sürü** heybeye girmez, baş sayısıdır ([K49](/docs/source/design/decisions#k49), [K65](/docs/source/design/decisions#k65)).

| Tür | Kıymet | Kabuk | Kesim Kıymeti | Canlı × 0,9 | Perde |
|---|---|---|---|---|---|
| Koyun | 48 | 12 | 36 | 43,2 | II |
| Keçi | 40 | 10 | 26 | 36,0 | II |
| At | 336 | 84 | 106 | 302,4 | II |
| Sığır | 240 | 60 | 126 | 216,0 | II |
| Deve | 504 | 126 | 142 | 453,6 | II |
| Yak | 240 | 60 | 126 | 216,0 | IV |
| Eşek | 144 | 36 | 22 | 129,6 | IV |
| Katır | 240 | 60 | 51 | 216,0 | V |
| Domuz | 64 | 16 | 48 | 57,6 | V |

- **Kural.** Yeni tür koyun oranıyla yazılır. Her türde canlı × 0,9 kesim Kıymeti'nden büyük olmalıdır, yoksa al, kes, sat döngüsü doğar. Kesim Kıymeti: et 4, deri 8, kemik 1, sinir 4, boynuz 6, yağ 2, kıl 1.
- **Dayanak.** Atın sığıra oranı (1,4) «at pahalı, sığır ucuz» kaydına dayanır (馬貴而牛賤, Şerhli Shiji 129). Devenin 1,5 at oluşu, eşek, katır ve domuzun fiyatı [kurgu]dur.
- **Yol bedeli** II'den Aş ya da kabukla, 1:1 ödenir: iç harita seferi mesafe ÷ 400, yukarı yuvarlanır. Kabuk yolda her sürücüde 1:1 sayılır; pazarın ×0,6 kuralı yola uygulanmaz ([travel.md §7.2](/docs/source/design/travel#7-2-ii-perde-ve-sonrasi)).
- Söz'ün «takas oranı −%3» etkisi Kıymet'in üstünden işler.

```varlik
sheep, goat, horse_brown, cattle, camel
yak, donkey, mule, pig
```

## Terazi

Terazi açıkken oyun durur, nöbet algısı işlemez. İki kefe vardır, mal sürüklenir ya da tıklanır. Kiriş (oyuncu − satıcı) ÷ (oyuncu + satıcı) ile en çok ±18° eğilir. Etiketler: «Denk / Even», «Eksik / Short», «Fazla / Over». İstenen mal kefede hafifçe parlar, denkte tunç kefe tıklar. Tek sahne iki kipte çalışır ([economy.md §9.2](/docs/source/design/economy#9-2-terazi-balance)):

| Kip | Ne görünür |
|---|---|
| I. Perde | Sayı yoktur: yalnız kiriş ve üç etiket |
| II. Perde'den | Kiriş ve etiketler kalır. Her kefenin altında «Eder {n}», üstte «Kese {n}», «Fazla»da «Üstü {n} kabuk» / «{n} cowries back» yazar. Kefedeki mal satır satır kabuk yazar, küçük mal deste yazılır: 10 tunç ok ≈5 kabuk. Söz'ün ve bağın etkisi fiyatta görünür |
| Kese yetmezse | «Kesem yetmez.»: kesenin dışındaki fazlalık gider; oyuncu bunu kabulden önce görür |

## Satıcılar

**I. Perde.** [Ardokşa](/encyclopedia/ardoksha) satıcı değildir: Ambar yalnız emekle konuşur.

| Satıcı | Nerede, ne zaman | Stok (şafakta) | İster (`sellK` 1) |
|---|---|---|---|
| Nandu | Gün II–IV öğle Kışlak'ta, başka zaman Sazlık Pazarı | Tuz ×4, Arpa Torbası ×2, İp ×6, Kalay Külçe ×1, Ham Firuze ×2 | Ham Deri, Küçük Post, Boynuz, Sinir, Keçe, Yün, Tilki ve Kurt Kürkü, Tunç Hurda, Eski Altın |
| Sazlık Pazarı | Sazlık Yanıyor görevinde kapanır, sonra kül | Darı ×6, Balık ×4, Kil ×4, Saz ×12, Kurut ×6, Küçük Kazan ×2 | Her odun, Kömür, Ham Deri, İp |
| [Yuan](/encyclopedia/yuan) | Çiang çadırı, akşam; Demir Diş görevinden sonra | Tuz ×6, Bakır Cevheri ×2, Uyku Otu ×1 | Aş, Kak, Kurut, Keçe, İp |
| [Hereka](/encyclopedia/hereka) | Çukur; bağ ≥1 | Yavşan ×4, Sargı ×2 | Aş, Darı, Kak, Kurut, Korda Balık |
| [Opia](/encyclopedia/opia) | Sabah ve akşam iki yerde; yalnız Eksik Ölçü görevinde açığı emekle kapatıldıysa; `buyK` +0,25 | Darı ×2, Tuz ×1, Kandil Yağı ×1 | Ham Deri, Yün, Keçe |
| [Kantu](/encyclopedia/kantu) | Menzil. Sefer ücreti ayrıdır: 1 Aş ya da 1 odun | Yük Kızağı ×1, İp ×4, Yular ×1, Çakmak Taşı ×1 | Aş, her odun |
| [Kujul](/encyclopedia/kujul) | Körük; tarifler de onda | Kömür ×3 | Demir ve Bakır Cevheri, Aş, Kak |

```varlik
nandu, yuan, hereka, opia, kantu, kujul
```

**II. Perde ve sonrası** ([economy.md §9.5](/docs/source/design/economy#9-5-ii-perde-ve-sonrasi-saticilari)).

| Satıcı | Perde | Nerede, ne zaman | Stok (şafakta) | İster | Kabuk, kese |
|---|---|---|---|---|---|
| Tanhu pazarcısı | II–VI | II'de iki günde bir (ilk 2. gün) Mete'nin Payı'na, Ocak Yeri'nin yanına gelir; III'ten pazar Tanhu Ordusu'ndadır, her gün açık | Darı ×10, Tuz ×4, İp ×8, Keçe ×6, Demir Külçe ×2, Kalay Külçe ×1, Tündük ×1; haftada bir Yurt Yükü | Yün, Kıl, Ham Deri, kürkler, Boynuz, Sinir, at, sığır | Tam alır; kese 52; üstü verir |
| Çiang tuzcusu | II–IV | Yuan'ın kervanı | Tuz ×10, Bakır Cevheri ×4, Uyku Otu ×1 | Keçe, Aş, Kak, Kurut | Tam alır; kese 26; üstü verir |
| Takas Yeri gezgini | III–V | Takas Yeri kurulunca; III'te 3, IV'te 2, V'te 3 günde bir | Tuz ×4, Kandil Yağı ×6, Sinir ×6, Tutkal ×6, Huş Kabuğu ×10, Tunç Hurda ×2 | Keçe, Yün, Ham Deri, Boynuz, Kurut, Kak, kürkler | Tam alır; kese 30; üstü verir |
| Saka tüccarı | IV | | Kalay Külçe ×3, Tunç Külçe ×4, Ham Firuze ×2, Saka Yayı ×1, Gorytos ×1 | At, Ak Keçe, Tilki Kürkü, Sepi Deri | ×0,6; kese yok |
| Hexi vahası | IV | | Tahıl Çuvalı ×6, Ham Yeşim ×1, Kızıl Boya ×4, Kökboya ×6 | Keçe, Ham Deri, at, koyun | ×0,6; kese yok |
| Sınır pazarı | VI | Heqin sonrası | Tahıl Çuvalı ×12, İpek Top ×4, Şarap Küpü ×2, Demir Külçe ×4 | At, sığır, koyun, kürkler, Ham Deri, Keçe | ×0,6; kese yok |
| Dingling kürkçüsü | VI | | Samur Kürkü ×4, Melez Odunu ×8 | Demir Külçe, Tunç Külçe, Darı | ×0,6; kese yok |

- **Kese kuralı.** Hun satıcısının şafak kesesi şafak stoğunun Kıymet'inin dörtte biridir: pazarcı 208 ÷ 4 = 52, tuzcu 104 ÷ 4 = 26, gezgin 120 ÷ 4 = 30 kabuk.
- **Takas Yeri gezgini** ([K81](/docs/source/design/decisions#k81)). Boy Yurdu'nda kurulan Takas Yeri'ne gelen Hun gezginidir. Stoğu III–V'te gereken ve pazarcıda bulunmayan küçük maldır: fener ve kandil için Kandil Yağı, yay için sinir ve tutkal, tündük ve kap için huş kabuğu, temren ve kabuk için tunç hurda. Tuz her Hun gezgininin yükündedir ve pazarcıyla ortak tek maldır. Stoğun Kıymet'i 32 + 18 + 24 + 12 + 10 + 24 = 120'dir. Pazarcının stoğunu yinelemek gezgini gereksiz kılardı; at ya da İpek Top gibi büyük mal keseyi şişirirdi, büyük mal zaten takasla döner.
- Tanhu pazarının Tündüğü ve haftalık Yurt Yükü, dülger gelmeden ilk yurtların ve huşu tükenen yerleşimin yoludur. Değerli mal Hazine'ye gider; İnce İş satılmaz.

```varlik
barter_ground, crowd_saka_trader, lamp_oil, birch_bark
```

## Hazine

| Soru | Kural |
|---|---|
| Açılış | Toy Yeri'nden (IV. Perde). 8 Taş, 16 odun, 4 İp, 2 Keçe, 2 Kil, 1 Tunç Külçe |
| Sınır | 120 Yük, yalnız değerli mal: Ham Firuze, Ham Yeşim, Altın Kumu, Eski Altın, Gümüş Parça, Samur Kürkü, İri Post, İpek Top, Tunç Kabuk |
| Ölçü | Mal Kıymet'le sayılır; Defter'de terazi ve yanında «≈{n} kabuk» görünür. Kıymet sözü oyuncuya çıkmaz |
| Girer | Heqin malı, ganimetin Tanhu payı, takas kârı, Yargı'nın el koyması ve kefareti, kabuk |
| Çıkar | Armağan, ganimet paylaşımı, Lung-çeng kervanı, Kurultay dağıtımı, Toy'da saçı (hane başına 1 kabuk) |
| Akın | İlk hedeftir: başarılı akında %30 gider, kabuk dahil; 30 m içinde Gözcü Kulesi varsa ×0,5. Mete'nin kesesi Hazine değildir, akında güvendedir |

Hazine'nin yerleşimdeki yeri ve törenleri: [Hanlık Merkezi](/docs/settlement/court) ve [settlement.md §12.5](/docs/source/design/settlement#12-5-hazine).

```varlik
treasury
```

## Oyunda şu an

> [!DURUM]
> Godot'da: satıcı, Terazi, kabuk ve Hazine yok; para birimi hiçbir yerde yok. Gece kampında satıcı kişisi yoktur.
>
> Prototipte denendi: takas kuralı, 13 satıcının stok ve istek tablosu, şafakta yenilenen stok, haftalık Yurt Yükü ve Hazine kabının sınırı. Kabuk ve kese K48'den sonradır, prototipe girmedi. Godot'a taşınmadı.
>
> Godot'daki plan: takas saf bir hesap sınıfıdır, Terazi tek sahne iki kiptir, kayıt Mete'nin kesesini ve satıcı keselerini tutar ([godot.md §3](/docs/source/design/godot#3-sistem-haritasi)). İşler Yol Haritası'ndadır: kabuk, satıcılar ve ganimet ([madde](/roadmap#item-currency)), Demirci Ocağı'nda kabuk ([madde](/roadmap#item-timber-caravan)), Hazine ([madde](/roadmap#item-court)).

## Kaynaklar

- [economy.md §9: Takas](/docs/source/design/economy#9-takas)
- [economy.md §9.1: Kural](/docs/source/design/economy#9-1-kural), [§9.2: Terazi](/docs/source/design/economy#9-2-terazi-balance)
- [economy.md §9.3: I. Perde satıcıları](/docs/source/design/economy#9-3-i-perde-saticilari)
- [economy.md §9.4: Sonraki ticaret malları](/docs/source/design/economy#9-4-sonraki-ticaret-mallari) (sürü fiyatı)
- [economy.md §9.5: II. Perde ve sonrası satıcıları](/docs/source/design/economy#9-5-ii-perde-ve-sonrasi-saticilari)
- [economy.md §9.6: Kabuk](/docs/source/design/economy#9-6-kabuk-cowrie-k48)
- [economy.md §6.11: Kıymet dengesi](/docs/source/design/economy#6-11-kiymet-dengesi)
- [d2/core.md §5.10: Para ve fiyat](/docs/source/design/d2/core#5-10-para-ve-fiyat-k48-k49)
- [settlement.md §12.5: Hazine](/docs/source/design/settlement#12-5-hazine), [§7.6: Avlu ve savunma](/docs/source/design/settlement#7-6-avlu-ve-savunma) (Takas Yeri)
- [travel.md §7.2: Yol bedeli](/docs/source/design/travel#7-2-ii-perde-ve-sonrasi)
- [progression.md §16.1: İstek ve tasarım çelişkileri](/docs/source/design/progression#16-1-istek-ve-tasarim-celiskileri) (karar 6, K48 ile değişti)
- [bozkir-ekonomi.md §1: Hun döneminde para ve takas](/docs/source/research/steppe-economy#1-hun-doneminde-para-ve-takas), [öneri 1: Kabuk](/docs/source/research/steppe-economy#1-para-birimi-kabuk-karar-2)
- [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- Kararlar: [K20](/docs/source/design/decisions#k20), [K24](/docs/source/design/decisions#k24), [K48](/docs/source/design/decisions#k48), [K49](/docs/source/design/decisions#k49), [K65](/docs/source/design/decisions#k65), [K81](/docs/source/design/decisions#k81)
- İlgili: [Hanlık Merkezi](/docs/settlement/court), [Toplama ve Kaynaklar](/docs/economy/gathering#savas-ganimeti), [Yolculuk](/docs/world/travel), [Arayüz ve Menüler](/docs/presentation/ui-menus)
- Önceki: [Zanaat](/docs/economy/crafting). Sonraki: [Ekonomi Dengesi](/docs/economy/balance)
