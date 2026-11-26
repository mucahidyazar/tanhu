# `structures.md` değişiklikleri: Yerleşim, ordugâh ve hanlık (K23)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `structures.md` yalnız `d2/structures-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/settlement.md` §7, §13, §17. Faz 7 bitince `L` işler. Biçim: **Yer**, **Bul** / **Yerine**, **Sonrasına ekle**. K21 eki (`d2/labour-delta-structures.md`) adımların süresini emeğe (`work` İD, `solo`, `min`, `max`) çevirir; bu dosya yalnız yeni türleri, hazır ayarları, görünümü, canı ve sınıfı ekler. Aşama emek payları K21 taslağının (`labour-model.json` `draft`) `split` alanıdır; † olanlar bu belgenin önerisidir, K21 alanı kesinleştirir.

## SD1. §3.5 Hazır ayarlar, tablonun altı

**Bul:** `` `winter` 24 uuk kullanır: `act1.md` §8.5 "24 sırık". ``
**Sonrasına ekle:**

**Yerleşim yurtları (K23, `settlement.md` §7).** Hepsi `yurt` türüdür; yakında `winter`, uzakta `YurtField` (§13.6). Fark iç tasarım ve son adımdır.

| Kullanım | `kind` | İç (`designFor`) | Adım farkı |
|---|---|---|---|
| Hane yurdu | `yurt` | `otaci` ya da `bolmeli` (tohumla) | Yok |
| Tanhu Otağı | `otag` | `han` (bugün kullanılmayan tasarım, §13.5) | `scale: 1.4`, `hero`; kapı doğuya |
| Ambar Yurdu | `store_yurt` | `bolmeli` + çuval yığını | `y_ocak` yok (`hearth: false`) |
| Elçi Yurdu | `envoy_yurt` | `otag` | Yok |
| Otacı Yurdu | `healer_yurt` | `otaci` | Yok |
| Buyruk Yurdu | `cmd_yurt` | `silah` | Yok |
| Silahlık, Okçu Yurdu | `armoury`, `fletchery` | `silah` + raf | Sonuna `y_raf` Raflar / Racks: aşama 7, `wood`, can 10 |
| Erzak Ambarı | `supply_depot` | `bolmeli` | `y_ocak` yok; sonuna `y_seki` Yük Sekisi / Loading Platform: aşama 7, `wood`, can 20, kapı yanında 6 × 4 m |

**`scale`.** `def.scale` (varsayılan 1) kök ölçeğini, `bounds`'u, nav şekillerini (`navShapes`), oda sınırını (`Room.floorAt`) ve pedi birlikte çarpar; birim canı `scale²` ile çarpılır, yukarı yuvarlanır (Otağ 420 → 824). Program değişmez: ölçek köke uygulanır, köşe etiketleri aynıdır.

## SD2. §4.5 Kısa liste ile §5 arası: yeni bölüm

**Yer:** `## 5. Hasar` başlığının hemen önü (K21'in §4.5 sütun ekinden sonra).
**Ekle:**

### 4.6 Yerleşim ve ordugâh yapıları (K23)

Ad, işlev, kademe, kapasite ve bakım `settlement.md` §7; emek ve el K21; malzeme K24. Bu bölüm adımları, canı, sınıfı ve görünümü verir. Bütün yeni türler `simple()` ile ya da kendi adım listesiyle `STRUCTURE_DEFS`'e girer; görünüm aileleri `core/geo.js` ile kodla kurulur, köşe renklidir, `struct_parts` ve `struct_props` programlarını kullanır (yeni program yok). Hepsi ≤6k üçgen, ≤2 çizim (`act1.md` §9.3 küçük yapı sınırı); çok sayıda olanlar örneklidir. `—` yıkılmaz aşama 0.

**Görünüm aileleri.**

| Aile | Türler | Ağ | Etiket |
|---|---|---|---|
| `yard` | `felt_yard`, `tannery`, `barter_ground`, `training_ground` | Düzlük çıkartması (ped deseni, `PadField`), köşe direkleri (`beam`), alçak çit, tür donanımı | Grup başına donanım, kip 0 (yerden yükselir) |
| `mound` | `grain_pit`, `kiln`, `smithy` ocağı, `pit_house`, `rampart` | Kazı çukuru (`lathe` iç yüz), toprak sırtı (`surf`), kapak ya da çatı | Kip 0; sur parçası örnekli |
| `ring` | `well`, `sky_pole`, `gathering_ground` | Taş halka (`blob` örnekli), direk, oturak ya da çıkrık | Kip 0; direk kip 3 (yükselir) |
| `post` | `banner_pole`, `lantern_post` | Direk, flama ya da fener; fener sahte ışık (`fxGlow`, köşe rengi >1) | Örnekli, zon başına 1 çizim |
| `field` | `field` | Sürülmüş toprak çıkartması + örnekli sap demeti; `uGrow` 0..1 takvimden | 1 çizim, ≤4k |

**Var olan türlerin yeni hazır ayarları.**

| Tür | Hazır ayar | Değişiklik | Kullanan |
|---|---|---|---|
| `shed` | `open` | Duvarsız, saz dam (bugünkü `shed`'in açık hâli) | `shed`, `wood_shop` (+ tezgâh props, aşama 4) |
| `shed` | `walled` | Tahta duvar (aşama 2'ye eklenir), keçe dam, tunç kilit birimi | `treasury` |
| `tower` | `low` | 4 m platform, korkuluksuz | `outpost` |
| `tower` | `gate` | İki direk, iki kanat (`door` birimi açılır ve kapanır), üst geçit | `rampart_gate` |
| `tower` | `granary` | Platformda tahta duvarlı ambar, saz dam, h 9 m | `granary_tower` |
| `fence` | `picket` | 5 m'de bir direk, tek ip; atlar örnekli bağlı | `horse_line` |
| `fence` | `stockade` | 2,5 m sivri kazık, sık | `palisade` |
| `tent` | (var) | `TentField` uzak örneği | Ordugâh |

**Adımlar.**

| `kind` | Aşamalar TR / EN | Can, sınıf | Emek payı (aşama 0'dan) | Not |
|---|---|---|---|---|
| `felt_yard` | Zemin / Ground, Direk ve Çit / Posts and Fence, Germe Çerçevesi / Stretching Frames, Döğme Hasırı ve Çiy / Beating Mats and Reed Screen | —, 20 wood, 15 wood, 10 reed | 0,2 / 0,3 / 0,3 / 0,2 | Çiy rüzgârlık; yağmurda hasır ıslak işaretlenir (K22) |
| `tannery` | Çukur ve Tekne / Pits and Vats, Sergi / Drying Frames, Gölgelik / Awning | —, 15 wood, 10 reed | 0,3 / 0,4 / 0,3 | |
| `smithy` | Ocak Çukuru / Furnace Pit, Kil Ocak / Clay Furnace, Körük / Bellows, Sundurma / Shelter | —, 40 stone, 10 bands, 20 reed | 0,25 / 0,35 / 0,2 / 0,2 | Çalışırken kor parıltısı `fxGlow`; yeri rüzgâraltı kuralıyla (`settlement.md` §13.2) |
| `kiln` | Çukur / Pit, Toprak Kubbe / Earth Dome, Baca ve Ağız / Vent and Mouth | —, 40 stone, 10 stone | 0,3 / 0,5 / 0,2 | Çalışırken duman `fxSmoke` (havuzdan) |
| `grain_pit` | Çukur / Pit, Kapak / Lid | —, 10 wood | 0,7 / 0,3 | Baskında yarı yarıya bulunmaz, yanmaz (K24 `d2/economy.md` §5.1) |
| `well` | Kazı / Dig, Taş Bilezik / Stone Collar, Çıkrık / Windlass | —, 40 stone, 15 wood | 0,6 / 0,3 / 0,1 | Kazı tek ağız: el en çok 3 (K21) |
| `field` | Sürüm / Ploughing, Ekin / Crop | —, 20 reed (olgunken) | 0,6 / 0,4 | Ekin takvimle büyür (bahar ekim, güz biçim); dolu −%30–60; olgun tarla tutuşur |
| `pit_house` | Çukur / Pit, Direk / Posts, Çatı / Roof Frame, Örtü / Cover | —, 40 wood, 40 wood, 30 reed | 0,35 / 0,2 / 0,25 / 0,2 | Çatı iki ellik ×1,5 (K21); `Room` aşama 3'te |
| `rampart` (10 m) | Hendek / Ditch, Toprak Sur / Earth Bank | —, 80 stone | 0,45 / 0,55 | Kütük duvar aşama 1'in son %20'si; örnekli parça ≤1,2k üçgen; ateş işlemez |
| `granary_tower` | Ayak / Base, Direk / Posts, Döşeme / Floor, Duvar / Walls, Dam / Roof | —, 60 wood, 40 wood, 40 wood, 30 reed | 0,15 / 0,25 / 0,25 / 0,2 / 0,15 | Direk ×1,5, döşeme ×1,25 (K21); `tall`: yıldırım adayı |
| `horse_line` (20 m) | Kazık / Stakes, İp / Line | —, 6 bands | 0,6 / 0,4 | İp kesilince atlar dağılır (`breach`) |
| `training_ground` | Açma / Clearing, Hedef Direkleri / Target Posts, At Yolu / Riding Course | —, 12 wood, 8 wood | 0,5 / 0,3 / 0,2 | 6 hedef; ok saplanır (`ARROW_STICK` `wood`) |
| `sky_pole`† | Taş Halka / Stone Ring, Direk / Pole, Flama ve Sunu Taşı / Streamers and Offering Stone | —, 30 wood, 10 felt | 0,5 / 0,35 / 0,15† | Direk 12 m, `tall`; yıldırımda `ignite({ power: 30 })`, aşama 1'e düşer |
| `gathering_ground`† | Düzlük / Levelled Ground, Oturak Halkası / Felt Seats, Sancaklar / Banners | —, 30 felt, 20 wood | 0,4 / 0,4 / 0,2† | Oturaklar örnekli (120), r 18 |
| `barter_ground`† | Düzlük / Ground, Direk / Posts, Gölgelik / Awnings | —, 20 wood, 15 felt | 0,3 / 0,4 / 0,3† | 4 gölgelik, at bağlama |
| `banner_pole`†, `lantern_post`† | Çukur / Hole, Direk / Pole | —, 10 wood | Basılı tutma (≤12 İD, K21) | Örnekli |
| `outpost`† | `tent` + `tower` `low` (ikili yerleşim) | `tent` ve `tower` canları; `tower` `low` 30, 20, 15 wood | Çadır 0,15 + kule 0,25† | Görüş 400 m |
| `rampart_gate`† | Ayak / Base, Direk / Posts, Kanatlar / Gate Leaves, Geçit / Walkway | —, 60 wood, 40 wood, 30 wood | 0,2 / 0,3 / 0,3 / 0,2† | `door` birimi açık ya da kapalı nav damgası |
| `treasury`† | `shed` `walled`: Ayak / Footing, Direk / Posts, Duvar / Walls, Dam / Roof, Kilit / Lock | —, 40 wood, 60 wood, 30 felt, 20 metal | 0,1 / 0,25 / 0,3 / 0,25 / 0,1† | Kilit düşmeden Hazine kabı açılmaz (baskın) |

**Yangın ve hava.** Yeni türler §6'nın malzeme hızlarını kullanır (`stone` yanmaz). Islak keçe ve saz (K22 `wet`) sıçrama olasılığını yarıya indirir (§6.2 `ıslak`). Gök gürültülü fırtınada `tall` türler (`sky_pole`, `watch_tower`, `granary_tower`, kurulan kule) K22'nin yıldırım adayıdır (`weather.md` H12).

**Nav.** `rampart` parçaları ve `rampart_gate` kapalı kanadı yürüme ve at ızgarasına damgalanır; `field` ve `yard` düzlüğü yürünür; `grain_pit` kapaklıyken yürünür, açıkken `circle(r 1,2)` kapalı. Damga §12.3 ile (`rebuild(box)`).

## SD3. §13.5 ile §14 arası: yeni alt bölüm

**Bul:** `` `closed` yurtta iç yok. ``
**Sonrasına ekle:**

### 13.6 Yerleşim ve ordugâh (K23)

| Uzaklık (kamera hedefinden) | Yurt | Öteki | Çizim |
|---|---|---|---|
| ≤40 m, en yakın 4 | `winter` (Otağ `hero`, iç yalnız odadayken) | Tam | Yapı başına (§13.2) |
| 40–220 m | `YurtField`: `closed` ağın (≈3k) örnekleri; `aCut` (0..1 yapım yüksekliği: yarım yurt uzaktan yarım görünür), `aChar` (yanık) | `KitField`: tür başına ≤400 üçgen kaba ağ, örnekli | 1 + 1 (gölge 1 + 1) |
| >220 m | `YurtField` uzak kubbe, 96 üçgen | Yok | Aynı çizimler |

- Aynı anda ≤48 canlı `StagedStructure` (yakın, şantiye, hasarlı); kayıtta ≤160 yapı zon başına.
- Yakına giren yurt `YurtField` yuvasını bırakıp kendi ağını kurar: kurulum yükleyicide hazırdır (havuz 6 `winter` ağı), geçiş 0,25 sn karışım; hasar ve aşama `StructureState`'ten okunur.
- Program: `yurt_field`, `kit_field` ve derinlik eşleri +4; `plot_decal`, `field_stalk`, `plan_ghost` +3: yerleşim dünyası +7 (≤92).
- En kötü kare (Tanhu Avlusu, `settlement.md` §17): yapılar ≈460k ana üçgen, ≈22 çizim.

## SD4. §15 Sonraki perde kancaları, tablonun sonu

**Bul:** `| Ana kamp | \`camp3\` bittikten sonra aynı yolla 4. yapı için \`SITE_*\` eklenir; \`LAYOUT\` dokunulmaz |`
**Sonrasına ekle:**
```
| II. Perde yerleşimi ve ordugâh (K23) | `settlement.md`: yerleşim `tanhu_ordu`, ordugâh `whistle_field`; yapılar K21 şantiyesi (`SiteSystem`), uzak yurt `YurtField`; §4.6 türleri; `CampPlan` çadırları `count`, `seed`, `doneAt` (K21 §8.3) |
| Kalıcı yerleşimin bakımı | Mevsim sonunda bakım malzemesi ödenmezse en üst havuz %25 düşer (`settlement.md` §7.10): yapı geri düşüş kuralıyla (§5.7) yaşlanır |
```

## SD5. §17 Kabul testleri

**Bul:** `10. Program sayısı ≤92, derleme hatası yok.`
**Sonrasına ekle:**
```
11. (K23) §4.6'nın her türü kum havuzunda kurulur, vurulur, geri düşer; ≤6k üçgen, ≤2 çizim; `grain_pit` yangında içeriğini korur.
12. (K23) `otag` `scale 1.4`: kapı → içeri → ateş yolu var, oda sınırı ve ped ölçekli; birim canı ×scale².
13. (K23) `YurtField`: 60 uzak yurt 1 çizim; yakına giren yurt 0,25 sn'de kendi ağına geçer, aşama ve yanık aynı; `aCut` yarım yurdu yarım gösterir.
14. (K23) Yerleşim dünyası programı ≤92; ≤48 canlı yapı sınırında kare §13.6 tablosu içinde.
```
