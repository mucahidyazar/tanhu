# `structures.md` birleşik deltası ve işleme defteri (K20–K26)

> **Yerini aldı (2026-11-03).** Bu defter ve bağladığı altı alan deltası `d2/structures-delta.md` birleşik deltasına indirildi; `L` yalnız onu işler. Bu dosya iz için kalır.

Kaynak: `d2/core.md` §2, §3, §6 (K26). Faz 7 bitince `L` işler; Faz 7 sürerken `structures.md` düzenlenmez. Bu defter önce okunur; §1 sırayı, §2 her alan maddesinin durumunu, §3 birleşik ve yeni metinleri verir. Emek kuralları ve sayıları sonraki adımda `d2/labour.md` ile birlikte yeniden yazılır; bu defter o adımın uyması gereken sayıları da bağlar (`d2/core.md` §2).

## 1. Sıra

1. `d2/labour-delta-structures.md` (D1–D26), §2'deki değişikliklerle. `time-delta-structures.md`'nin bütün maddeleri (S1–S7) labour'ın birleşik maddelerinin içindedir ve **işlenmez**.
2. `d2/weather-delta-structures.md` (1–8), §2'deki değişikliklerle.
3. `d2/settlement-delta-structures.md` (SD1–SD5), §2'deki değişikliklerle.
4. `d2/economy-delta-structures.md` (S1–S4), §2'deki değişikliklerle.
5. Bu dosyanın §3 maddeleri (CS1–CS3).

## 2. Alan maddelerinin durumu

| Dosya, madde | Durum | Değişiklik |
|---|---|---|
| time S1–S7 | Atla | labour D6, D15b, D16, D20, D23, D24, D25 birleşik metinleri (labour dosyasının başındaki eşleme tablosu); S2'nin 22:00 durağı K21'e aykırıdır (`d2/core.md` §2.5) |
| labour D7 (§3.1 yurt tablosu) | Değiştirerek | Adım emekleri `d2/core.md` §2.2: tek el 81, 81, 146, 48, 171, 290, 113, 129, 146, 113, 21, 81, 20 (toplam 1.440); ekip 81, 81, 146, 48, 107, 290, 113, 129, 146, 113, 21, 81, 20 (1.376); tek el çarpanı yalnız `y_tunduk` (en az 2 el); el en çok: `y_site` 8, `y_bosaga` 6, `y_kerege` 8, `y_bag` 8, `y_tunduk` 6, `y_uuk` 8, `y_liner` 8, `y_tuurduk` 8, `y_uzuk` 8, `y_kolan` 8, `y_esik` 4, `y_sirdak` 8, `y_ocak` 1 |
| labour D15b | Değiştirerek | «(yardımsız ilk duman 00:16)» → «(yardımsız ilk duman ≈00:51; 22:30'da yurt aşama ≥5'teyse aile ocak yanana dek ateş başında kalır, en geç 01:30; daha geç biterse `y_ocak` 05:00'te)»; `SHELTER` cümlesi «Hava durağında yalnız `all` durağında ya da ne şimdiki ne sonraki adım ilerleyebiliyorsa `SHELTER` (`d2/core.md` §2.8)» |
| labour D16 | Değiştirerek | Formülden `× K_su` düşer; «`solo`: ekipte adımın en az el sayısından az baş varsa tek el çarpanı» → «`solo`: yalnız `y_tunduk`'ta, tek baş kalınca bakan yöntemi (171 / 107)»; «Katılan Çocuk 0,5 ağırlık ve bir baştır» → «Çocuk adımın fiilini yaptıkça 0,5 ağırlık ve bir baştır» |
| labour D17 | Uygula | |
| labour D20 (§11.6) | Değiştirerek | Tablo `d2/core.md` §2.11'in tablosuyla (00:51 / 00:27 / 23:34 / 23:11; «Gece dinlenilsin» ertesi ≈08:50); «Saatsiz saf emek (öğünsüz): yardımsız 1.423 sn, bütün yardımla 1.187 sn»; katılma paragrafı `d2/core.md` §2.10 (fiil yaptıkça yarım el, kamera serbest, «Kendiliğinden / Auto» isteğe bağlı); `help_water` satırı «Zemin adımı ocak halkasını oturtmak için 2 kova su ister; Çocuk getirmezse Dengiz iki sefer gider (her biri 20 gerçek sn ekipten çıkar)»; «Bitiş» paragrafına «aile bekler» kuralı ve uyanış satırı (`d2/core.md` §2.11) |
| labour D21 | Değiştirerek | Kayıt sıkı: saplı ok ve yanık izi yok, en çok 8 yırtık, `world.sites` bütün zonlarda ≤20 KB |
| labour D23 | Değiştirerek | Yeni Yurt satırına «Ambar yalnız eksiği gönderir, demiri Ardokşa ilk tallyle verir; Gün V yaması Nanay ve iki el 07:00–08:35; `K_tok: 1`» |
| labour D26 | Değiştirerek | Kabul sayıları C11'in (`d2/core-delta-architecture.md`) sayılarıyla |
| öteki labour maddeleri | Uygula | |
| weather 1a, 1b, 2, 3 | Uygula | |
| weather 4 (yeni §6.5) | Atla | CS1 birleşik §6.5 |
| weather 5a | Değiştirerek | «fırtınada bağlanmazsa örtü yıpranır, Bağla / Tie Down (§6.5)» → «fırtınada bağlanmazsa bölüm başına %25 olasılıkla örtü bir aşama düşer; Bağla / Tie Down kalıcıdır (§6.5)» |
| weather 5b | Uygula | |
| weather 6 (`SHELTER` satırı) | Değiştirerek | Satırın tetik hücresi: «Emek tablosunda `hold: all` (dolu, tipi, Kara Boran, toz) ya da ne şimdiki ne sonraki adım ilerleyebiliyorsa: en yakın yurt kapısına ya da ahır çatısının altına 1,9 m/sn; çizelge bekler»; dönüş hücresi: «Adımın hava çarpanı 0,25 sa (37 sn) işe izin verince önceki işe» |
| weather 7 (§16 satırı) | Değiştirerek | «Tuğ Direği korur» → «konut halkasında Sancak Direği korur» |
| weather 8 (kabul 11–14) | Değiştirerek | 12. madde: «12 m Tuğ Direği ≈22 m yarıçapındaki yurtların yerine vurulur» → «10 m Sancak Direği ≈9 m içindeki yurtların yerine vurulur; kurulmakta olan yapı `world.tallThings`'te değildir»; 13. madde sonuna «; bağsız çadır bölüm başına en çok bir aşama düşer» |
| settlement SD2 (`sky_pole` satırı) | Değiştirerek | «yıldırımda `ignite({ power: 30 })`, aşama 1'e düşer» → «yıldırımda flama kuruysa `ignite({ power: 30 })`, ıslaksa yalnız yanık izi; alamet `settlement.md` §12.4» |
| settlement SD2 (`banner_pole`, `lantern_post` satırı) | Değiştirerek | İki satıra ayrılır: `banner_pole` «Çukur / Hole, Direk / Pole, Flama / Streamer» · «—, 20 wood, 5 felt» · «40 İD, iki el (uzun direk)» · «Direk 10 m, `tall`: yıldırım adayı (`weather.md` §8.7)»; `lantern_post` eski satır gibi (basılı tutma) |
| settlement SD3 (program maddesi) | Değiştirerek | «`plot_decal`, `field_stalk`, `plan_ghost` +3: yerleşim dünyası +7» → «`plot_decal`, `field_stalk` +2: yerleşim dünyası +6; `plan_ghost` yok (önizleme K21 `Game.marker`); kışta `_w` +2»; `KitField` satırı «tür başına … örnekli» → «bütün türlerin kaba ağları tek `BatchedMesh`» |
| öteki settlement maddeleri | Uygula | |
| economy S1, S3, S4 | Uygula | |
| economy S2 | Değiştirerek | Son cümle «Kışlak'ta (`preset: 'winter'`) ham teslim kuralı aynen: Nanay'ın eli parçayı yerinde yapar.» → «I. Perde ve ana kampın şantiyeleri (`camp3`, Kışlak Yeni Yurdu, onarımlar, senaryo şantiyeleri) `spec.labour.rawWork: false` taşır: malzeme yontulmuş gelir, `rawWork` eklenmez, yurt 1.440 İD kalır (`d2/core.md` §2.6). K21'in «1 kişi 1 gün» çapası parça biçimli standart yurdun kurulumudur.» |

## 3. Birleşik ve yeni maddeler

### CS1. Yeni §6.5 Hava ve yıldırım (weather 4'ün yerine)

**Yer:** §6.4 «Görünüm ve etki» bölümünden sonra, §7 «Onarım»dan önce.
**Ekle:**
```
### 6.5 Hava ve yıldırım

Kurallar `weather.md` §8.6, §8.7; sayılar buraya özet olarak geçer (`d2/core.md` §3.3, §3.5).

**Dolu.** İri dolu (dolu sağanaklarının %30'u): `reed` birimi −0,5 Can/sn, `tent` örtüsü −0,2 Can/sn; küçük dolu `reed` −0,1 Can/sn. Keçe, ahşap, kafes dolu almaz. Dolu bir yapıyı aşama 1'in altına indirmez ve bir sağanakta en çok bir aşama düşürür.

**Fırtına (`fx.galeDamage`: ortalama rüzgâr ≥16 ya da bora >20 m/sn).** Tetik açık bir hava bölümünde bağsız her `tent` örtüsü bir kez %25 olasılıkla bir birim aşaması düşer; bağsız `rack` içindekinin %20'sini döker. **Bağla / Tie Down** (`E` basılı 3 sn; `tent`, `rack`) kalıcı bir durumdur, **Çöz / Untie** (`E` 1 sn) ya da sökümle kalkar; hane ve ordugâh ekipleri fırtına işareti gelince kendi çadırlarını kendiliğinden bağlar. Yurt (kolan) ve ahır (kiriş) rüzgâr almaz. Taban aynı: aşama 1'in altı yok. Sıçrama yarıçapı `R = 10 + manager.wind` (§6.2) tek kuraldır.

**Yıldırım.** Hedefi hava seçer (en uzun ve en yalnız aday, `weather.md` §8.7 skoru). Adaylar `world.tallThings`'tir: yapı yöneticisi aşama değişince ekler ve siler; kurulmakta olan yapı aday değildir; yurt (`bounds.top` 8,6 m) varsayılan en uzun adaydır. Yurt ve ahır: tepe birimine `blunt` 25 (`STRUCT.blunt.wood` 1) ve `addScorch`; keçe ıslaklığı <0,3 ise (kuru fırtına) `ignite({ power: 30 })`, ≥0,5 ise tutuşmaz. Kule: tepe birimine `blunt` 40. **Sancak Direği / Banner Pole** (`banner_pole`, 10 m): ≈9 m içindeki yurtların yerine yıldırımı alır, `blunt` 25 ve iz, kuru flama tutuşur. **Gök Direği / Sky Pole** (`sky_pole`, 12 m, yalnız Kutlu Tepe): alamet (`settlement.md` §12.4); kuru flama tutuşur (meşale 70), ıslaksa iz. Vurulan yapı 1 oyun günü bekler; bir yerleşimde fırtına başına en çok bir yapı; ana kampın yapılarına yıldırım inmez (Serbest Gez).

**Islak keçe görünümü.** `struct_tex` dış yüzü `U.uWet.y` ile koyulaşır ve dikey akıntı izi alır (`FELT_WET` kancası); iç duvar kuru kalır (dışa bakan normal sınaması ya da yapı başına merkez uniform'u). Kar çatısı Kışlak'ın kar kancasıdır (K2).

**Görünüm bütçesi.** Hava yapıya çizim ya da program eklemez: kanca metni değişir, anahtar ve program sayısı aynıdır.
```

### CS2. §16 İstek ve ilke çatışmaları: K21 satırı

labour D25'in yeni satırı uygulanır; «Uygulanan» hücresi şu metinle yazılır: «K21: standart (parça biçimli) yurt 1 iş günü (tek işçi 60 dk; 2 el 30,6, 4 el 17,3, 8 el 11,2 dk), dünya saatinde; inşaat ışıkta gece de sürer, «Gece dinlenilsin» emriyle üretim penceresi; ham malla `rawWork` (I. Perde ve ana kampta yok)».

### CS3. §17 Kabul testleri: ek

**Yer:** «**Kabul testleri.**» listesinin sonu (labour D26 ve weather 8 eklerinden sonra).
**Ekle:**
```
15. Emek eğrisi: tek işçi 1.440 İD; 2 el ≥30 dk (1.440 / ≥720 oyun dk); el arttıkça süre hep kısalır; tek el çarpanı yalnız tündükte.
16. Ham teslim: II. Perde şantiyesinde ham malla yurt 3.120 İD, kerege ustasız ×0,7; `spec.labour.rawWork: false` ile (camp3, Kışlak) 1.440 İD.
17. camp3: 22:30'da aşama ≥5 ise statik halk ateş başında kalır, ilk dumanda `lookAt` yalnız uyanıklara; 01:30'u aşan bitişte `y_ocak` 05:00'te.
```
