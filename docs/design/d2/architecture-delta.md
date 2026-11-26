# `architecture.md` deltası: saat, hava, emek, ekonomi, yerleşim (K20–K26)

Baş mühendis (`L`) için birleştirme talimatı ve uygulama planı, 2026-11-03. Kaynak: `decisions.md` K20–K26; `d2/core.md` (kesişen sayılar, dikişlerin tek sahibi); alan belgeleri `time.md`, `weather.md`, `settlement.md` (son biçim); taslaklar `d2/labour.md` ve `d2/economy.md` (`d2/core.md` §2 ve §5 ile okunur); `d2/time-delta-architecture.md`, `d2/weather-delta-architecture.md`, `d2/labour-delta-architecture.md`, `d2/settlement-delta-architecture.md`, `d2/economy-delta-architecture.md` ve defter `d2/core-delta-architecture.md`. Bağlayan sıra `decisions.md` > `d2/core.md` > `architecture.md` > alan belgeleri; arayüz için `architecture.md`, sayı için alan belgesi kazanır. Bu dosyadaki sayılar `d2/core.md`'den alındı; çelişki görülürse `d2/core.md` kazanır ve bu dosya düzeltilir.

**Bu dosyanın yeri.** K26 (2026-11-03): `architecture.md`'nin tek işleme defteri bu dosyadır. Eski `d2/core-delta-architecture.md` defterinin **uygulanmış ve tamamlanmış** biçimidir: sıra korundu (C1–C14, saat, hava, emek, yerleşim, ekonomi), «Atla» maddeleri düştü, «Değiştirerek» maddeleri değişik hâliyle girdi, kaynak deltaların eskimiş sayıları `d2/core.md`'ye göre düzeltildi (örnek: Zor zorlukta buz saati 06:40, 11 Nisan, yurt ekip emeği 1.376 İD, camp3 1.434 / 1.188 sn (Dengiz'in su seferleriyle), Gün V yaması 07:00–08:42, Ordu Payı düz %10, `world.weather` sırası 78, `hs_terrace` (−80, −100)). Kaynak deltalarda olmayanlar da buradadır: yeni §3.23–§3.27 sözleşmeleri, paket ayrıklığı düzeltmeleri, Faz 8–13 satırları, sınama, bütçe ve karar satırları. Faz 7 bitince `L` `architecture.md`'yi **yalnız bu dosyayla** işler; altı kaynak delta «Yerini aldı» bandıyla iz olarak kalır, ayrıca işlenmez. `structures.md` ve `audio.md` de yalnız kendi birleşik defterleriyle işlenir: `d2/structures-delta.md` ve `d2/audio-delta.md`; `d2/core-delta-structures.md`, `d2/core-delta-audio.md` ve alan deltaları iz olarak kalır (`decisions.md` K26, `d2/core.md` §6.7).

**Biçim.** Her madde (M1…) bölümü, birebir bulunacak metni (**Bul**) ve işlemi verir: **Yerine**, **Sonrasına ekle**, **Önüne ekle** ya da iki çapa arasındaki metnin tamamını değiştiren **Aralık**. Bulunacak ve yeni metin `~~~` çitleri arasındadır; yeni metnin içindeki kod blokları üç ters tırnaklıdır ve aynen kopyalanır. Faz 7 `architecture.md`'yi değiştirdiği için bir «Bul» tutmazsa madde atlanmaz: anlam korunarak en yakın yere işlenir ve `L` bunu kaydeder. §8 karar numaraları «sıradaki»dir (bugün 37'den başlar); Faz 7 satır eklerse hepsi kaydırılır ve metin içindeki «§8 karar 40» gibi başvurular aynı kaydırmayla yazılır. Paket numaraları K26'nındır; 8.14, 9.10 ve Faz 13 bu dosyanın eklediği paket ve fazdır (§8 karar 46, 52).

## 0. Özet

| Alan | Yeni sözleşme | Değişen sözleşme | Paket |
|---|---|---|---|
| Saat (K20) | §3.23 `WorldClock`, `daylight`, `Calendar`, `ClockSystem` (15), `CampLife` (81) | §2.2, §2.4, §2.5 (`wallDt`), §2.6, §3.1, §3.2 (`T` Bekle), §3.4, §3.5 (`world.clock` 69), §3.7, §3.8 (ışığın tek hattı), §3.14, §3.15, §3.16, §3.19, §3.20, §3.22 | 8.9, 8.14 |
| Hava (K22) | §3.24 `Planner`, `WeatherSystem` (22), `WeatherFx`, `weather.audio`, `WeatherView` | §3.4 (`a11y.flashes`), §3.5 (`world.weather` 78), §3.6, §3.8, §3.11, §3.12, §3.14, §3.16, §3.17, §3.19, §3.21 | 8.10, 9.4, 9.6, 9.8 |
| Emek (K21) | §3.25 `labour.js`, `SiteCore`, `SiteSystem` (61), `ConstructionSite` | §3.5 (`world.sites` 76), §3.11 (`advance(wm)`, `dismantle`, emek alanları), §3.13 (kap çözücü), §3.20 | 8.11, 8.12 |
| Ekonomi (K24) | §3.26 `Container`, `transfer`, `Workshop`, tezgâh ve rol tabloları, `herdDay`, `loot.of`, `SupplyLedger` ambar kipi, `LEDGERS`, `armyShare`, `rolloverYears` | §3.5 (`economy` v2), §3.13 (`ITEMS`, `baseId`, Terki), §3.14 (`ledger` yeri), §3.22 | 8.2, 8.4, 8.7 |
| Yerleşim (K23) | §3.27 `SettlementState`, `StorePool`, `CaravanBook`, `CampState`, `CampPlan`, `SettlementSystem` (64), Plan Kipi, `SettlementView` (`YurtField`, `KitField`), `spec.settlement` | §3.1, §3.2 (`plan` bağlamı, `P`), §3.5 (`settlement` 77, `camps` 92), §3.8, §3.11 (K23 türleri, `scale`), §3.12 (`applyTaken`), §3.16 (`canPlace`), §3.17, §3.20 | 8.13, 9.9, 9.10, 10.10, 13 |

Faz satırları §6'da, sınamalar §7'de, bütçe §8'de, karar satırları §9'da, `contract-requests.md` satırları §11'dedir.

## 1. Giriş ve §0

### M1. Giriş paragrafı: alan belgeleri

**Bul:**
~~~
`act1.md`, `progression.md`, `structures.md`, `economy.md`, `survival.md`, `travel.md`, `army.md`, `audio.md`, `docs/research/menu-spec.md`
~~~
**Yerine:**
~~~
`act1.md`, `progression.md`, `structures.md`, `labour.md` (K21; birleşene dek `d2/labour.md`), `economy.md`, `survival.md`, `travel.md`, `army.md`, `time.md`, `weather.md`, `settlement.md`, `audio.md`, `docs/research/menu-spec.md`
~~~

**Bul:**
~~~
Belgeler çeliştiğinde `decisions.md` kazanır. Bu belge yalnız
~~~
**Yerine:**
~~~
Belgeler çeliştiğinde `decisions.md` kazanır; K20–K26'nın kesişen sayıları `d2/core.md`'dedir ve bu belgeden önce gelir. Bu belge yalnız
~~~

### M2. §0 kural 2: `L` dosyaları

**Bul:**
~~~
`src/ui/style.css`, `src/story/act1/index.js`, bu belge
~~~
**Yerine:**
~~~
`src/ui/style.css`, `src/story/act1/index.js`, `src/story/act2/index.js` (Faz 13), bu belge
~~~

## 2. §1 Hedef klasör ağacı

Ağaç satırlarında ters tırnak kullanılmaz (kod bloğunun içindedir). Sıra, satırın girdiği alt ağacın sırasıdır.

### M3. `src/app/`, `src/core/`

**Bul:**
~~~
  sounds.js                        L    SoundSystem: adım, toynak, ahırdaki atlar; app:state ile kamp ortamı ve ön üretim (Faz 3)
~~~
**Yerine:**
~~~
  sounds.js                        L    SoundSystem: adım, toynak, ahırdaki atlar; app:state ile kamp ortamı ve ön üretim (Faz 3); evre ve hava birleşimi (K20, K22)
~~~

**Bul:**
~~~
  settings-schema.js               →0.1 Ayar anahtarları, varsayılanlar
~~~
**Yerine:**
~~~
  settings-schema.js               →0.1 Ayar anahtarları, varsayılanlar; 8.9 game.clockShow, 9.8 a11y.flashes
~~~

**Bul:**
~~~
  keymap.js                        →0.2 Eylem → tuş tablosu
~~~
**Yerine:**
~~~
  keymap.js                        →0.2 Eylem → tuş tablosu; 8.9 wait (T), build_mode (P), mood kalkar
~~~

**Bul:**
~~~
  paint-material.js              E →1.5 Program anahtarına kanca karması
~~~
**Yerine:**
~~~
  paint-material.js              E →1.5 Program anahtarına kanca karması; 9.4 hava uniform'ları (uWet, uWetFx, uCloudPhase, uFront, uWindK, uWindPhase)
~~~

### M4. `src/i18n/strings/`

**Bul:**
~~~
  strings/survival.js              →8.5 Ateş, yemek, av
~~~
**Sonrasına ekle:**
~~~
  strings/time.js                  →8.9 Evre, Bekle, Uyu, Dinlen, Çalış, Gök Kavisi, kayıt kartı
  strings/weather.js               →8.10 Hava türleri, işaretler, kişi satırları, kilit ve ret satırları
  strings/sites.js                 →8.12 Şantiye: yerleşim ve bekleme nedenleri, ekip, bitiş sözcüğü
  strings/settlement.js            →8.13 Yerleşim, ordugâh, Plan Kipi, Defter, kademe kartları
~~~

### M5. `src/audio/`

**Bul:**
~~~
  music-states.js                  →3.6 Müzik durumu tablosu
~~~
**Yerine:**
~~~
  music-states.js                  →3.6 Müzik durumu tablosu; 8.9 camp_night; 9.9 hold, hold_night, court, muster
~~~

**Bul:**
~~~
  sfx/ui.js, foot.js, weapon.js, structure.js, gather.js, horse.js, world.js, travel.js  →3.7 Reçeteler, alan başına
~~~
**Yerine:**
~~~
  sfx/ui.js, foot.js, weapon.js, structure.js, gather.js, horse.js, world.js, travel.js  →3.7 Reçeteler, alan başına; structure.js 8.11 torch_post
  sfx/time.js                      →8.9 Saat ekleri: meal_call, night_drum, wait_lapse, wake
  sfx/economy.js                   →8.4 Tezgâh, kap, ganimet: felt_roll, bellows, anvil, adze, tan_scrape, shear_snip, milk_pail, store_open, cart_unload, loot_search, craft_done
  sfx/weather.js                   →9.8 Yakın ve uzak gök gürültüsü, uyarı vızıltısı, bora, damla, dolu tıkırtısı, sağırlık
  sfx/settlement.js                →9.9 Plan Kipi, hane, kervan, kademe, Şafak Selamı, alamet, toplantı
~~~

**Bul:**
~~~
  ambience.js                      →3.7 Ortam döngüleri, çapraz geçiş
~~~
**Yerine:**
~~~
  ambience.js                      →3.7 Ortam döngüleri, çapraz geçiş; 9.8 hava ve yerleşim döngüleri
~~~

### M6. `src/story/`

**Bul:**
~~~
  act1/schedule.js                 →11.1 NPC programı (act1.md §5)
~~~
**Sonrasına ekle:**
~~~
  act1/days.js                     →11.1 Hikâye günleri: ana iş, vakitler, kesmeler (time.md §9.2)
~~~

**Bul:**
~~~
  proto/{index,day1,blizzard}.js              →10.9 Dikey dilim: Gün I + Tipi prototipi; Faz 11 açılınca silinir
~~~
**Sonrasına ekle:**
~~~
  act2/index.js                    L    II. Perde dizini (Faz 13)
  act2/opening/{index,quests,dialogue,cine}.js →13.3 Pay, Köz Kabı, Ocak Yeri (K23, settlement.md §2.1)
~~~

### M7. `src/data/`

**Bul:**
~~~
  craft-recipes.js                 →8.4 Zanaat tarifleri
~~~
**Yerine:**
~~~
  craft-recipes.js                 →8.4 Zanaat tarifleri: tezgâh, rol, girdi, çıktı, İS, tutuş, bekleme
  items.js                         →8.2 Malzeme, parça, bohça satırları (economy.md §2, d2/economy.md §2; d2/econ-model.json ile aynı)
  stations.js                      →8.4 11 tezgâh, 9 zanaatçı rolü (d2/economy.md §4.2, §4.3)
  herd-kinds.js                    →8.4 Sürü türleri: mevsim üretimi, kesim, kış yemi
  loot-tables.js                   →8.4 Düşman türüne göre belirli ganimet
~~~

**Bul:**
~~~
  enemies.js                       →8.8 Düşman tablosu
~~~
**Sonrasına ekle:**
~~~
  weather-types.js                 →8.10 Hava türü vektörleri, alt olaylar, etki sayıları
  climates.js                      →8.10 İklim payları, gün içi eğriler, hâkim rüzgâr, zon → iklim
  settlement.js                    →8.13 Kademe, yapı satırı, parsel kuralı, hane kaynağı, ordugâh kademesi, baskın (settlement.md, d2/settlement-model.json)
~~~

### M8. `src/game/`

**Bul:**
~~~
  save.js                          →0.7 SaveManager: yuva, blok, göç, doğrulama (saf)
~~~
**Yerine:**
~~~
  save.js                          →0.7 SaveManager: yuva, blok, göç, doğrulama (saf); 8.9 meta.minute, phase, İnce İş eki denetimi
~~~

**Bul:**
~~~
  items.js                         →8.2 ITEMS, etiket eşleme (saf)
  inventory.js                     →8.2 Heybe, Yük, yuva, depo, el koyma (saf)
~~~
**Yerine:**
~~~
  items.js                         →8.2 ITEMS, etiket eşleme, baseId, yığın yükü (saf)
  inventory.js                     →8.2 Heybe, Yük, yuva, depo, el koyma, kap çözücü (saf)
  container.js                     →8.2 Container: bütün kaplar, onda bir Yük, gün anahtarlı bozulma, transfer (saf)
~~~

**Bul:**
~~~
  craft.js                         →8.4 Tarif çözümü (saf)
  supply.js                        →8.4 SupplyLedger (saf)
  barter.js                        →8.4 Terazi (saf)
~~~
**Yerine:**
~~~
  craft.js                         →8.4 Tarif çözümü; Workshop: tezgâh kuyruğu ve bekleme (saf)
  supply.js                        →8.4 SupplyLedger (soyut ve ambar kipi), LEDGERS, armyShare, rolloverYears (saf)
  barter.js                        →8.4 Terazi (saf)
  herds.js                         →8.4 Sürü günü ve mevsim olayları (saf)
  loot.js                          →8.4 Belirli ganimet, birim ganimeti (saf)
~~~

**Bul:**
~~~
  calendar.js                      →10.1 Perde, gün, dilim, İş Puanı (saf)
~~~
**Yerine:**
~~~
  world-clock.js                   →8.9 Dünya saati: oyun dakikası, gün, durma, bekleyiş, atlama, olaylar (saf)
  daylight.js                      →8.9 Güneş ve ay, gün ışığı, evreler, ışık anahtarları, gece sınıfı (saf)
  calendar.js                      →8.9 Perde, hikâye günü, takvim, ay, vakit, uyku kapısı (saf)
  clock-system.js                  →8.9 ClockSystem: saati sürer, ışık tabanını yazar, Bekle, Uyu, Dinlen, Çalış
  camp-life.js                     →8.9 CampLife: ana kampın halk ve hayvan programı (Serbest Gez)
  weather-core.js                  →8.10 Planlayıcı, ayar, ıslaklık, kar örtüsü, fx, yıldırım seçimi, işaret (saf)
  weather.js                       →8.10 WeatherSystem: saat, kilit, işaret, alt olay, fx, ses verisi
  labour.js                        →8.11 Emek yasası: ekip verimi, oran, gece, hava, taşıma, söküm, toplu benzetim, günlük emek (saf)
  site-core.js                     →8.12 Şantiye çekirdeği: yerleşim denetimi, yığın, bekleme nedeni (saf)
  sites.js                         →8.12 SiteSystem: genel şantiye, ekip, gece emri, atlama, söküm, world.sites
~~~

**Bul:**
~~~
  schedule.js                      →10.3 Dilim → konum, iş (saf)
~~~
**Yerine:**
~~~
  schedule.js                      →10.3 Dakika bloğu → konum, iş (saf)
~~~

**Bul:**
~~~
  moon-clock.js                    →11.7 Ay Saati, yakalanma
~~~
**Yerine:**
~~~
  moon-clock.js                    →11.7 Ay Saati (Düğümden buz saatine), yakalanma
~~~

**Bul:**
~~~
  builders.js                      →6.5 Usta durum makinesi, iş tablosu, yardım
~~~
**Yerine:**
~~~
  builders.js                      →6.5 Usta durum makinesi, iş tablosu, yardım; 8.11 emek yasası, CHILD_HELP, gece meşalesi, SHELTER
~~~

**Bul:**
~~~
  projectiles.js                   →6.6 Balistik ok, taş, ıslıklı ok; instanced havuz
~~~
**Yerine:**
~~~
  projectiles.js                   →6.6 Balistik ok, taş, ıslıklı ok; instanced havuz; 8.10 rüzgâr sapması
~~~

**Bul:**
~~~
  mounted.js                       →1.1 placeRider, MountSystem: at istemi ve tıklaması
~~~
**Yerine:**
~~~
  mounted.js                       →1.1 placeRider, MountSystem: at istemi ve tıklaması; 8.10 rüzgâr ve gök gürültüsü ürkmesi
~~~

**Bul:**
~~~
  cond.js                          →0.5 Koşul dili derleyici (saf)
~~~
**Yerine:**
~~~
  cond.js                          →0.5 Koşul dili derleyici (saf); 8.14 phase:, beat:
~~~

**Bul:**
~~~
  effects.js                       →0.5 Etki listesi uygulayıcı (saf)
~~~
**Yerine:**
~~~
  effects.js                       →0.5 Etki listesi uygulayıcı (saf); 8.14 clock, weather, ledger yeri
~~~

**Bul:**
~~~
  cine.js                          →5.3 CineDirector
~~~
**Yerine:**
~~~
  cine.js                          →5.3 CineDirector; 8.14 saat izi, hava satırı
~~~

**Bul:**
~~~
  squad/demo.js                    →10.6 ?squad=10, yalnız geliştirme
~~~
**Sonrasına ekle:**
~~~
  settlement/state.js              →8.13 SettlementState: hane, kişi kaydı, iş kodu, Çekim, Gönül, kademe, yol, saat adımı (saf)
  settlement/households.js         →8.13 Katılım, ayrılış, seferberlik, yenilenlerin seçimi (saf)
  settlement/steward.js            →8.13 Kâhya: ekip listeleri (şantiye, tezgâh, sürü, toplama kolu, nöbet, sürücü) (saf)
  settlement/stores.js             →8.13 StorePool: yerin kapları, ofPlace, kabul, ambar içeriği (saf)
  settlement/production.js         →8.13 Tezgâh saati, toplama kolu, sürü günü, mevsim olayları (saf)
  settlement/caravans.js           →8.13 CaravanBook: buyruk, koruma, yol töresi, akın, yoldaki yük (saf)
  settlement/raids.js              →8.13 Yerleşim akını: tehdit, savunma, tek kayıp kuralı (saf)
  settlement/camps.js              →8.13 CampState, CampPlan: ordugâh kademesi, konfor, talim, kış dağılması (saf)
  settlement/court.js              →8.13 Divan, toplantılar, alamet, Hazine (saf)
  settlement/chronicle.js          →8.13 Kronik: perdeler arası yıllar, açılış tabanı, kış stoğu (saf)
  settlement/index.js              →9.9 SettlementSystem (GameSystem 'settlement', 64); 10.10 Defter ve kervan bağı
  settlement/plan.js               →9.9 Plan Kipi: 'plan' bağlamı, önizleme, sites.beginPlacement
~~~

### M9. `src/world/`

**Bul:**
~~~
  world.js                       E →1.7 Spec güdümlü kurulum, sis katmanı, dispose
~~~
**Yerine:**
~~~
  world.js                       E →1.7 Spec güdümlü kurulum, sis katmanı, dispose; 8.9 altı ışık durağı, lightBase, writeLight, tallThings; 9.4 WeatherView.compose devralır
~~~

**Bul:**
~~~
  camp.js, interior.js           E →6.1 Aşama etiketleri, owner, Room.enabled
~~~
**Yerine:**
~~~
  camp.js, interior.js           E →6.1 Aşama etiketleri, owner, Room.enabled; camp.js 8.11 G_TORCH, 9.4 bayrak rüzgârı
~~~

**Bul:**
~~~
  flora.js                       E →7.3 Spec; 9.4 kış ormanı
~~~
**Yerine:**
~~~
  flora.js                       E →7.3 Spec; 9.4 kış ormanı, rüzgâr, tallThings (ağaç)
~~~

**Bul:**
~~~
  sky.js                           →5.1 Kameraya bağlı gök kubbesi
~~~
**Yerine:**
~~~
  sky.js                         E →5.1 Kameraya bağlı gök kubbesi; 8.9 gece: yıldız, ay diski; 9.4 hava uniform'ları
~~~

**Bul:**
~~~
  site-pad.js                      →6.4 Ped, ezik maskesi, stok
  structure.js                     →6.3 StagedStructure, StructureManager
  structure-logic.js               →6.3 Havuz, birim, LIFO, yanık (saf)
  structure-defs.js                →6.3 STRUCTURE_DEFS
  structure-shader.js              →6.1 Etiket, GLSL parçaları, partsHooks
~~~
**Yerine:**
~~~
  site-pad.js                      →6.4 Ped, ezik maskesi, stok; 8.12 genel şantiye pedi; 9.10 PadField
  structure.js                     →6.3 StagedStructure, StructureManager; 8.11 emek, G_TORCH; 9.6 scale, kit kaydı, YurtField devri, tallThings
  structure-logic.js               →6.3 Havuz, birim, LIFO, yanık (saf); 8.11 advance(wm), söküm, parça ve ham teslim
  structure-defs.js                →6.3 STRUCTURE_DEFS; 8.11 emek alanları ve K23 türleri
  structure-shader.js              →6.1 Etiket, GLSL parçaları, partsHooks; 8.11 G_TORCH; 9.6 FELT_WET
  structure-kits.js                →9.10 K23 görünüm aileleri (yard, mound, ring, post, field), shed, tower, fence hazır ayarları, kaba ağlar
  settlement-view.js               →9.9 SettlementView: YurtField, KitField, parsel çıkartması, sürü örnekleri
  tent-field.js                    →13.4 TentField: ordugâhın uzak çadırları (tek örnekli çizim + gölge, program eklemez)
~~~

**Bul:**
~~~
  weather.js                       →9.4 Kar noktaları, Tipi sisi
~~~
**Yerine:**
~~~
  weather.js                       →9.4 WeatherView: yağış ve sıçrama noktaları, yıldırım şeridi; ışık, sis, kubbe, rüzgâr ve post bileşimi
  weather-hooks.js                 →9.4 Hava GLSL dizgeleri: ekran yağışı, ıslaklık, bulut örtüsü, kubbe (saf, yalnız dizge)
~~~

**Bul:**
~~~
  specs/index.js                   →7.1 SPECS: id → spec, kış dinamik import
  specs/camp.js                    →7.1 Canlı kamp spec'i
  specs/winter.js                  →9.1 Kışlak spec'i
  specs/winter-layout.js           →9.1 act1.md §4 yerleşim verisi
~~~
**Yerine:**
~~~
  specs/index.js                   →7.1 SPECS: id → spec, kış dinamik import; 8.12 sandbox_site; 9.1 hexi_winter, sandbox_hold
  specs/camp.js                    →7.1 Canlı kamp spec'i; 8.9 light, moods.cycle, evre ortamları, weather, labour
  specs/winter.js                  →9.1 Kışlak spec'i: light, WINTER_MOODS, weather, labour, sites, perish
  specs/winter-layout.js           →9.1 act1.md §4 yerleşim verisi; Kışlak Yeni Yurdu şantiyesi
  specs/zones.js                   →7 Bölge → dünya kimliği, ad, yükleyici başlığı (saf); 8.12 sandbox_site; 13 L tanhu_ordu, whistle_field
  specs/sandbox.js                 →8.12 K21 kum havuzu (sandbox_site); 9.9 yerleşim kipi (sandbox_hold)
  specs/tanhu-ordu.js              →13.1 II. Perde yerleşim dünyası (settlement.md §3.2)
  specs/tanhu-ordu-layout.js       →13.1 Karasu, Kutlu Tepe, Ocak Yerleri, parseller, düğüm kümeleri
  specs/whistle-field.js           →13.2 II. Perde ana ordugâh dünyası (settlement.md §3.3)
  specs/whistle-field-layout.js    →13.2 Pınarlar, talim ovası, ordugâh parselleri
~~~

### M10. `src/ui/`

**Bul:**
~~~
  hud/build-status.js              →6.5 Yeni Yurt aşaması
~~~
**Yerine:**
~~~
  hud/build-status.js              →6.5 Yeni Yurt aşaması; 8.11 ekip ve «≈N saat» satırı
~~~

**Bul:**
~~~
  hud/trust.js, axes.js, clock.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, dilim ve Ay Saati, birlik
~~~
**Yerine:**
~~~
  hud/trust.js, axes.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, birlik
  hud/clock.js                     →8.9 Gök Kavisi: güneş, ay, evre, bekleyiş düğümü; 11.7 Ay Saati kipini ekler (aynı dosya, ayrı faz)
  hud/weather.js                   →9.8 Hava simgesi, işaret satırı, gök okuma
  hud/plan-bar.js                  →9.9 Plan Kipi şeridi
~~~

**Bul:**
~~~
  cook-wheel.js                    →8.5 Tarif çemberi
~~~
**Sonrasına ekle:**
~~~
  wait-wheel.js                    →8.9 Bekle, Uyu, Dinlen, Çalış tekeri
~~~

**Bul:**
~~~
  pack.js, ledger.js, barter.js, glyphs.js  →8.7 Heybe, Defter, Terazi, SVG simgeler
~~~
**Yerine:**
~~~
  pack.js, ledger.js, barter.js, glyphs.js  →8.7 Heybe (Terki sekmesi), Defter (yapı sayfası), Terazi, SVG simgeler
  transfer.js                      →8.7 İki sütunlu aktarma paneli: bütün kaplar (d2/economy.md §5.2)
~~~

**Bul:**
~~~
  act-card.js                      →11.9 Perde kartı
~~~
**Sonrasına ekle:**
~~~
  hold-ledger.js                   →10.10 Yerleşim Defteri sayfası (settlement.md §14.2)
~~~

**Bul:**
~~~
  css/cook-wheel.css               →8.5
~~~
**Sonrasına ekle:**
~~~
  css/wait.css                     →8.9
~~~

**Bul:**
~~~
  css/pack.css, ledger.css         →8.7
~~~
**Yerine:**
~~~
  css/pack.css, ledger.css, transfer.css  →8.7
~~~

**Bul:**
~~~
  css/journal.css                  →10.7
~~~
**Sonrasına ekle:**
~~~
  css/weather.css                  →9.8
  css/hold.css                     →9.9 Plan şeridi
  css/hold-ledger.css              →10.10 Yerleşim Defteri sayfası
~~~

### M11. `tools/`

**Bul:**
~~~
  check-data.mjs                   →0.8 Görev, diyalog, sinema, eşya, ses kimliği, mods okuyucusu, koşul derlemesi, kredi bütçesi
~~~
**Yerine:**
~~~
  check-data.mjs                   →0.8 Görev, diyalog, sinema, eşya, ses kimliği, mods okuyucusu, koşul derlemesi, kredi bütçesi; 8.14 hava, saat izi, days.js, ekonomi modeliyle eşitlik
  econ-sim.mjs                          K24 denge benzetimi (d2/econ-model.json, settlement-model.json, weather-model.json); yalnız ekonomi alanı yazar, paket değildir
~~~

## 3. §2 App ve durum makinesi

### M12. §2.2 Durumlar: tablo satırları

**Bul:**
~~~
| `freeroam` | Serbest Gez | `game.update`, `world.update(dt, t, game.pos)`, HUD | `post.render(world.scene, blend ?? game.camera)` | `game`, üstünde ince `freeroam` (`map`, `mood`); üstüne `cook_wheel` | `camp`, dombra ozanın konumundan |
~~~
**Yerine:**
~~~
| `freeroam` | Serbest Gez | `game.update`, `world.update(dt, t, game.pos)`, HUD | `post.render(world.scene, blend ?? game.camera)` | `game`, üstünde ince `freeroam` (`map`, `wait`); üstüne `cook_wheel`, `wait_wheel` | `camp`, Gece evresinde `camp_night`; dombra ozanın konumundan |
~~~

**Bul:**
~~~
| `play` | Oluşturucu kabul, Devam Et, Yükle, `travel` varışı | Sistemler, `game.update`, `world.update` | `post.render(world.scene, cine.active ? cine.camera : game.camera)` | `game`; üstüne `dialogue`, `cine`, `roadcard`, `levelup` modal | Spec ve sahneden |
~~~
**Yerine:**
~~~
| `play` | Oluşturucu kabul, Devam Et, Yükle, `travel` varışı | Sistemler, `game.update`, `world.update` | `post.render(world.scene, cine.active ? cine.camera : game.camera)` | `game`, üstünde ince `plan` (K23, modal değil); üstüne `dialogue`, `cine`, `roadcard`, `levelup`, `wait_wheel`, `transfer` modal | Spec, sahne ve evreden |
~~~

**Bul:**
~~~
| `home` | `mq_home`: `play` → `replaceWorld('camp')` | `cine.update`, `game.update` (yalnız `mount`, `child`, `structures`), `world.update(dt, t, game.pos)` |
~~~
**Yerine:**
~~~
| `home` | `mq_home`: `play` → `replaceWorld('camp')` | `cine.update`, `game.update` (yalnız `mount`, `child`, `structures`, `sites` ve iğneli `clock`), `world.update(dt, t, game.pos)` |
~~~

### M13. §2.2: dünya saati paragrafı

**Bul:**
~~~
`pause.pausesClock` true: Ay Saati, Tokluk, yapım durur (`progression.md` §14.1). `map` açıkken de `game.update` çalışmaz, dolayısıyla aynı sonuç.
~~~
**Sonrasına ekle:**
~~~

**Dünya saati (K20, §3.23).** `ClockSystem` (order 15) saati yalnız `freeroam` ve `play`'de akıtır; `home`'da menü ışığına iğneler. `menu`, `newgame`, `creator`'da dünya saati yoktur: kamp menü ışığındadır (`applyMood(0,3)`, sabit güneş) ve `menuDiff` değişmez. `map`, `pause`, gizli sekme ve `freeze` saati durdurur (`game.update` çalışmaz; duvar süresi telafi edilmez). Bloklayan diyalog, sinema (`run` izi yoksa), seviye ekranı, Terazi, Yol Kartı, aktarma paneli, Bekle tekeri ve Donuk Kamp `worldClock.pause(reason, on)` ile durdurur. Atlas yolculuğu (`travel`) varışta yol süresi kadar atlar (`clock:skip { reason: 'travel' }`).
~~~

### M14. §2.2: Serbest Gez oturumu

**Bul:**
~~~
başka her çıkış `endSession` ile menü sahnesini geri yazar (statik çocuk, atlar ahırda, odalar, ışık, `U.uPlayer`).
~~~
**Yerine:**
~~~
başka her çıkış `endSession` ile menü sahnesini geri yazar (statik çocuk, atlar ahırda, odalar, ışık, `U.uPlayer`; K20–K22: `world.setTimeOfDay(null)`, gece tekdüzenleri, zerre `uDusk` 0, `campLife.menuPose(true)` ile statik halk görünür, ikizler ve yaban hayvanı kalkar, hava kimliğe döner; ışık ve hava 1,7 sn'de süzülür, §2.4). Oturum `roam.clock` ve `roam.weather`'ı okur ve yazar (§3.5).
~~~

### M15. §2.3 Geçişler: kum havuzu adresi

**Bul:**
~~~
Mevcut `?q=low`, `?density=`, `?yurt1=`, `?yurt2=` korunur; yeni `?yurt3=`, `?squad=`.
~~~
**Yerine:**
~~~
Mevcut `?q=low`, `?density=`, `?yurt1=`, `?yurt2=` korunur; yeni `?yurt3=`, `?squad=`, `?sandbox=site` (K21 kum havuzu: `play` durumunda `sandbox_site` dünyası; `&hold=1` yerleşim kipi `sandbox_hold`, 9.9). Kum havuzu yalnız geliştirmededir, kampa ve menüye dokunmaz.
~~~

### M16. §2.4 Kararma: ışık ve hava geçişi

**Bul:**
~~~
| `menu` → `freeroam` | Menü α→0 0,5 sn, sine in | 0 | 0 | `whoosh`; kamera karışımı 1,6 sn |
~~~
**Yerine:**
~~~
| `menu` → `freeroam` | Menü α→0 0,5 sn, sine in | 0 | 0 | `whoosh`; kamera karışımı 1,6 sn; ışık ve hava 2,4 sn (K20, K22; ikisi kamerayla aynı anda başlar) |
~~~

**Bul:**
~~~
| `pause` → `menu` (aynı dünya) | HUD 0,3 sn | 0 | 0 | Oto kayıt; `menuCam.flyFrom(game.camera, 1.7)`, sine in-out |
~~~
**Yerine:**
~~~
| `pause` → `menu` (aynı dünya) | HUD 0,3 sn | 0 | 0 | Oto kayıt; `menuCam.flyFrom(game.camera, 1.7)`, sine in-out; ışık ve hava menü kimliğine 1,7 sn |
~~~

### M17. §2.5 Kare döngüsü: duvar saati

**Bul:**
~~~
  const dt = clamp((now - this.last) / 1000, 0, 0.05);        // kıstırma kalır
~~~
**Yerine:**
~~~
  const dt = clamp((now - this.last) / 1000, 0, 0.05);        // kıstırma kalır
  this.wallDt = clamp((now - this.last) / 1000, 0, 0.25);     // K20: dünya saati kırpılmamış duvar süresiyle ilerler (ClockSystem okur)
~~~

**Bul:**
~~~
`cineNow` bağlı bir işlevdir (Timeline `now` olarak saklar).
~~~
**Sonrasına ekle:**
~~~

**Dünya saati (K20, §3.23).** `core/clock.js` oyun saniyesidir ve değişmez (sinema, `U.uTime`, eylem süreleri). Dünyanın saati ayrı bir saf sınıftır (`game/world-clock.js`): 1 oyun dakikası 2,5 gerçek sn, gün 3.600 sn. `App.tick` yalnız `wallDt`'yi yazar (kırpılmamış duvar süresi, kare başına en çok 0,25 sn); `ClockSystem.update` onu sahne yavaşlatmasıyla (`timeScale`) `worldClock.advance`'a verir, Yol Akışı `k` saatin `rate`'idir. Böylece `dt` 0,05 sn'ye kırpılsa da bir oyun günü 60 gerçek dakikadır (15 fps'de de); takılma ve sekme dönüşü saati sıçratmaz. Durma kuralları durumların ve sistem kiplerinin kendisidir (§2.2). `__tanhu.step(ms, n)` `wallDt`'yi `ms`'ten yazar: gizli bölmede gün belirlenimli koşar.
~~~

### M18. §2.6 `ctx`

**Bul:**
~~~
  inventory, needs, supply, mounts, player, nodes,        // Faz 8
  calendar, regions, jobs, quests, dialogue, npcs, stealth, travel, squads,   // Faz 10
~~~
**Yerine:**
~~~
  inventory, needs, supply, mounts, player, nodes,        // Faz 8; supply: LEDGERS (§3.26), get(id)
  worldClock, calendar, campLife, weather, sites,         // Faz 8 (K20–K22, K21; calendar 10.1'den 8.9'a geçti)
  settlement,                                             // Faz 9 (9.9, K23)
  regions, jobs, quests, dialogue, npcs, stealth, travel, squads,   // Faz 10
~~~

## 4. §3 Var olan sözleşmelerde değişiklikler

### M19. §3.1 Olay veri yolu: saat olayları

**Bul:**
~~~
| `slice:change` | `{day, slice, prev}` | calendar |
| `dawn` | `{day}` | calendar |
~~~
**Yerine:**
~~~
| `clock:hour` | `{day, hour, abs, skipping}` | world-clock (150 sn'de bir; ≤24 sa atlamada her saat `skipping: true`) |
| `clock:phase` | `{day, phase, prev, skipping}` | world-clock |
| `slice:change` | `{day, slice, prev}` | world-clock (eski dört dilim, evrelerden türer; bugünkü dinleyiciler için) |
| `dawn`, `dusk` | `{day, abs, skipping}` | world-clock (Tan başı: sivil şafak − 30 dk; Gece başı) |
| `clock:summon` | `{beat, at}` | world-clock (vakit çağrısı; bekletmez) |
| `clock:skip:begin` | `{from, to, reason}` | world-clock |
| `clock:skip` | `{from, to, minutes, reason, sleep, long, days, dawns}` | world-clock; `reason`: `sleep`, `wait`, `rest`, `work`, `travel`, `cine`, `chronicle`, `dev`; `long` (>1.440 dk) ise önce sınır olayı yayılmaz |
| `clock:hold` | `{id, on, at}` | world-clock |
| `day:story` | `{storyDay, prev}` | calendar |
| `beat:state` | `{id, state}` | calendar |
| `act:change` | `{act, prev}` | journey (10.8); yerleşimin Kronik'i dinler |
~~~

### M20. §3.1: eşya ve zanaat olayları

**Bul:**
~~~
| `load:change` | `{load, cap}` | inventory |
~~~
**Sonrasına ekle:**
~~~
| `item:move` | `{from, to, id, n}` | inventory, settlement stores (`transfer` sonucu; saf `container.js` olay yaymaz) |
| `item:spoiled` | `{container, id, n}` | inventory, settlement stores (`Container.onDawn` sonucu) |
~~~

**Bul:**
~~~
| `craft:done`, `cook:done` | `{id, quality}` | craft, cooking |
~~~
**Yerine:**
~~~
| `craft:done`, `cook:done` | `{id, quality, n, ws}` (`ws` tezgâh kimliği, el işinde null) | craft, cooking, yerleşim üretimi |
~~~

### M21. §3.1: hava, şantiye, yerleşim olayları

**Bul:**
~~~
| `voice:start`, `voice:end` | `{line}` | audio |
~~~
**Sonrasına ekle:**
~~~
| `weather:change` | `{from, to, sev}` | weather |
| `weather:front` | `{type, inH}` | weather |
| `weather:strike` | `{x, z, target}` | weather |
| `weather:hail` | `{size, minutes, x, z}` | weather |
| `weather:thunder` | `{d}` | weather |
| `weather:crust` | `{zone, on}` | weather (Kar Kabuğu) |
| `site:placed`, `site:done`, `site:dismantled` | `{id, kind, zone}` | sites |
| `site:wait` | `{id, reason}` (değişince) | sites |
| `site:crew` | `{id, heads, W}` | sites |
| `settlement:tier` | `{zone, tier, prev}` | settlement |
| `settlement:join`, `settlement:leave` | `{src, n}`, `{id, reason}` | settlement |
| `settlement:raid` | `{zone, success, losses}` | settlement |
| `caravan:depart`, `caravan:arrive` | `{id, from, to, raided}` | settlement (caravans) |
| `store:full` | `{place, container}` | settlement (stores) |
| `court:path` | `{path}` (`walled` \| `moving`) | settlement (court) |
| `chronicle:done` | `{years, households, herd, storesPct}` | settlement (chronicle) |
| `camp3:family_wait` | `{until}` (22:30'da; 01:30'da aşama ≥6 ise 03:00'e uzatılınca yeniden) | builders (tek sahip; CampLife uyar) |
| `camp3:hearth_dawn` | `{at}` (ocak 05:00'e kaldı) | builders |
~~~

### M22. §3.2 Girdi: bağlamlar ve tuşlar

**Bul:**
~~~
  id,                  // 'game' | 'map' | 'menu' | 'book' | 'dialogue' | 'cine' | 'roadcard' | ...
~~~
**Yerine:**
~~~
  id,                  // 'game' | 'map' | 'menu' | 'book' | 'dialogue' | 'cine' | 'roadcard' | 'wait_wheel' | 'transfer' | 'plan' | ...
~~~

**Bul:**
~~~
pause:['Escape'], save:['F5'], load:['F9'], mood:['KeyT'],
~~~
**Yerine:**
~~~
pause:['Escape'], save:['F5'], load:['F9'], wait:['KeyT'], build_mode:['KeyP'],
~~~

**Bul:**
~~~
`mood` yalnız geliştirme. `douse` ve `sling` aynı tuşu paylaşır:
~~~
**Yerine:**
~~~
`wait` (`T`, K20) her pakette Bekle tekerini açar; döşekte Uyu'yu, ateş başında Dinlen'i, şantiyede Çalış'ı da gösterir (§3.23); eski `mood` eylemi kalktı, geliştirmede ışık `__tanhu.clock` panelinden sürülür (§8 karar 40). `douse` ve `sling` aynı tuşu paylaşır:
~~~

**Bul:**
~~~
kısa basış `cmd_look` (Ku yanındaysa), 0,6 sn basılı `drop_load` (`holdTime`).
~~~
**Sonrasına ekle:**
~~~

`build_mode` (`P`, K23) yerleşim ve ordugâh dünyasında Plan Kipi'ni açar (§3.27; başka yerde «Burada yurdun yok.» / «You hold no ground here.»). `plan` bağlamı modal değildir: `actions` listesi `ui_prev`, `ui_next` (Q, E: 15° döndürür, Shift ile 5°), `ui_tab`, `ui_back`, `quick`, `use`, `cmd_loose` ve `build_mode`'dur; `onKey` `Delete`'i (Sök), `onPointer` sol ve sağ tıkı, `onWheel` tekerleği tüketir. Böylece Q (`quick`), E (`use`) ve R (`cmd_loose`) oyuna düşmez; ayrı bir `rotate` eylemi yoktur. `wait_wheel` ve `transfer` modal bağlamlardır: açıkken dünya saati durur (§3.23).
~~~

### M23. §3.4 Ayarlar

**Bul:**
~~~
| `game.hints` | true | | hud |
~~~
**Sonrasına ekle:**
~~~
| `game.clockShow` | `phase` | `phase`, `hour` | hud/clock.js: Gök Kavisi altında «Evre / Phase» ya da «Evre ve saat / Phase and hour» (K20, `time.md` §11) |
~~~

**Bul:**
~~~
| `a11y.reduceMotion` | false | | travel Akış, atlas nabzı, kamera sarsıntısı |
~~~
**Yerine:**
~~~
| `a11y.reduceMotion` | false | | travel Akış, atlas nabzı, kamera sarsıntısı (yakın yıldırım dahil); ekran yağışı 3 → 1 katman; Bekle akışı yerine doğrudan karartma |
| `a11y.flashes` | `full` | `full`, `soft`, `off` | world/weather: şimşek nabzı (`weather.md` §9.6); `soft` ×0,35, tek vuruş, ≤2,5 parlama/sn; `off` pozlama değişmez, şerit ×0,3 |
~~~

### M24. §3.5 Kayıt: kurallar ve kart

**Bul:**
~~~
  setRules({ xpCurve, levelCaps, statCaps, axisCaps, skills, items, derive, autosaveBlocked });   // tablolar sonraki fazlarda; verilmeyen denetim atlanır
~~~
**Yerine:**
~~~
  setRules({ xpCurve, levelCaps, statCaps, axisCaps, skills, items, derive, autosaveBlocked });   // tablolar sonraki fazlarda; verilmeyen denetim atlanır; items denetimi İnce İş ekini atar (baseId: 'hun_bow+' geçerlidir, K24)
~~~

**Bul:**
~~~
SlotInfo = { slot, empty, corrupt, saveNo, savedAt, savedUnix, playTime, act, day, slice, level, place: { world, region, labelKey }, thumb, failed? }   // failed: yazılamadı, eski kayıt duruyor
~~~
**Yerine:**
~~~
SlotInfo = { slot, empty, corrupt, saveNo, savedAt, savedUnix, playTime, act, day, minute, phase, slice, level, place: { world, region, labelKey }, thumb, failed? }   // failed: yazılamadı, eski kayıt duruyor; kart evreyi yazar («Gün II, ikindi»), slice eski kayıtlar için
~~~

### M25. §3.5: blok tablosu

**Bul:**
~~~
| `economy.pack`, `.tools`, `.chest`, `.seized`, `.stash`, `.cart`, `.sled`, `.cache` | 41 | `game/inventory.js` | `travel.md` `inventory.stash` yazmaz (§8) |
~~~
**Yerine:**
~~~
| `economy.pack`, `.tools`, `.chest`, `.seized`, `.stash`, `.cart`, `.sled`, `.cache`, `.saddlebags`, `.perish` | 41 | `game/inventory.js` | `travel.md` `inventory.stash` yazmaz (§8); blok sürümü 2 (`registerBlock(…, { v: 2 })`, `blockV`; `progression.md` §13.2'nin `economy.v`'si budur; göç 1 → 2 yeni alanları boş açar). Yalnız kişisel kaplar; yerin kapları `settlement`'ta, şantiye yığını `world.sites`'ta, Erzak Ambarı `camps`'ta (K24) |
~~~

**Bul:**
~~~
| `world.zone`, `.act`, `.day`, `.slice`, `.workPoints`, `.jobsToday`, `.jobTypesDone`, `.moonClock`, `.dawnPath` | 70 | `game/calendar.js`; `moon-clock` son ikisini yazar | |
~~~
**Yerine:**
~~~
| `world.clock` | 69 | `game/clock-system.js` (`WorldClock.toJSON`) | `{ v, dayN, minute, holds }` (K20) |
| `world.zone`, `.act`, `.day`, `.calendar`, `.jobsToday`, `.jobTypesDone`, `.moonClock`, `.dawnPath` | 70 | `game/calendar.js`; `moon-clock` son ikisini yazar | `day` hikâye günüdür; `calendar`: `{ v, beats, mainDone, moonEpoch }`; `slice` ve `workPoints` kalktı, göç: `slice` → dakika (sabah 08:00, öğle 12:00, akşam 17:00, gece 21:00), `workPoints` atılır (`time.md` §13) |
~~~

**Bul:**
~~~
| `world.npcs` | 74 | `game/npcs.js` | |
~~~
**Sonrasına ekle:**
~~~
| `world.sites` | 76 | `game/sites.js` | K21: zon başına şantiyeler ve sıkı yapı dizisi (saplı ok ve yanık izi yok, can nicemli, ≤8 yırtık); bütün zonlarda ≤20 KB; senaryo yapıları `world.structures`'ta (73), ordugâh çadırları `camps`'ta |
| `settlement` | 77 | `game/settlement/index.js` | K23: hane, ustalar, iş kodu, Çekim, ambar içerikleri (`StorePool`), tezgâh kuyrukları, sürüler, kervan buyrukları ve yoldaki yük, alınan küme, Divan, bayraklar, Kronik; ≤14 KB (`settlement.md` §16) |
| `world.weather` | 78 | `game/weather.js` | K22, ≤1 KB: tohum, plan (≤10 bölüm; sabit çapadan yeniden üretilebilir), ıslaklık, kar örtüsü ve kabuk, kilitler, yıldırım beklemesi (`struck`, site kimliğiyle), söylenmiş işaretler; `world.sites` ve `settlement`'tan sonra okunur |
~~~

**Bul:**
~~~
| `army` | 90 | `game/squad/index.js` | `Follower` yazılmaz |
~~~
**Sonrasına ekle:**
~~~
| `camps` | 92 | `game/settlement/camps.js` | K23: ana ve sefer ordugâhı: kademe, `CampPlan`, konfor, Erzak Ambarı içeriği, kış dağılması; ≤4 KB |
~~~

### M26. §3.5: oto kayıt ve Serbest Gez bloğu

**Bul:**
~~~
**Oto kayıt nedenleri.** `slice`, `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`. `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`.
~~~
**Yerine:**
~~~
**Oto kayıt nedenleri.** `dawn`, `sleep`, `wait` (≥1 oyun saati), `work` (≥1 oyun saati), `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`, `tier` (yerleşim kademesi), `caravan` (kervan varışı, ≥60 sn), `court_path` (V. kademe yolu). `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`, `court_path`.
~~~

**Bul:**
~~~
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime }`
~~~
**Yerine:**
~~~
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, clock:{day,minute}, flags, playTime, weather }` (`camp3` kendi `v: 2` sürümünü taşır, göç `labour.md` §14; `weather` yolculuk bloğuyla aynı biçim; `mood` artık yazılmaz, okunursa saate göç eder: >0,75 ise 18:38, değilse menü dakikası 14:46,2; yolculuk ≈83 KB ≤96 KB, Serbest Gez ek ≈40 B + hava ≤1 KB)
~~~

### M27. §3.6 Ses motoru

**Bul:**
~~~
//     raid, erlik, tengri, chase, dawn, home, road_leg
~~~
**Yerine:**
~~~
//     raid, erlik, tengri, chase, dawn, home, road_leg, camp_night (8.9), hold, hold_night, court, muster (9.9)
~~~

**Bul:**
~~~
`whoosh`, `page_turn` (`menu-spec.md`). Alan dosyası eşlemesi:
~~~
**Yerine:**
~~~
`whoosh`, `page_turn` (`menu-spec.md`); K20–K24 ekleri tablonun son dört satırı ve `torch_post`'tur (`audio.md` §4). `thunder` (`sfx/world.js`) orta uzaklıktır (0,6–3 km); ≤600 m `thunder_crack`, 3–10 km `thunder_far`, gecikme `d / 343` sn. Alan dosyası eşlemesi:
~~~

**Bul:**
~~~
`structure_fire` (döngü, 3B, yanan yapının tepesinden; Faz 6) |
~~~
**Yerine:**
~~~
`structure_fire` (döngü, 3B, yanan yapının tepesinden; Faz 6), `torch_post` (K21: şantiye meşale direği, gece, ≤2 kaynak) |
~~~

**Bul:**
~~~
| `sfx/travel.js` | `cart_loop`, `travel_start`, `travel_arrive`, `post_knock`, `wheel_snow` |
~~~
**Sonrasına ekle:**
~~~
| `sfx/time.js` | `meal_call`, `night_drum`, `wait_lapse`, `wake` (K20) |
| `sfx/economy.js` | `felt_roll`, `bellows`, `anvil`, `adze`, `tan_scrape`, `shear_snip`, `milk_pail`, `store_open`, `cart_unload`, `loot_search`, `craft_done` (K24) |
| `sfx/weather.js` | `thunder_crack`, `thunder_far`, `static_hum`, `gust`, `rain_drip`, `hail_tick`, `tinnitus` (K22; reçetede `sr: AMB_RATE`, 22,05 kHz) |
| `sfx/settlement.js` | `plan_place`, `plan_rotate`, `household_arrive`, `caravan_depart`, `tier_up`, `dawn_bow`, `omen_strike`, `assembly_drum` (K23) |
~~~

**Bul:**
~~~
// id: wind_steppe, wind_winter, blizzard, fire_loop, night_meadow, birds_day, camp_day, yurt_inside, ice_groan, water_reed; hepsi 22 kHz mono
~~~
**Yerine:**
~~~
// id: wind_steppe, wind_winter, blizzard, fire_loop, night_meadow, birds_day, camp_day, yurt_inside, ice_groan, water_reed;
//     hava (9.8): rain_light, rain_heavy, rain_felt, hail_bed, wind_gale, dust_storm (planda cephe ≥1 oyun saati önce görününce dilimli pişer, geçtikten 1 sa sonra bırakılır);
//     yerleşim (9.8): hold_day, herd_flock, camp_army, gathering_crowd (yalnız yerleşim ve ordugâh dünyalarında); hepsi 22 kHz mono
~~~

**Bul:**
~~~
`rain` katmanı `setLayer('rain', g)` çağrılana dek sessizdir.
~~~
**Yerine:**
~~~
`rain` katmanı (çan damlaları) `setLayer('rain', g)` çağrılana dek sessizdir; çağıran `ctx.weather`'dır (8.10), yalnız ortam durumlarında (`camp`, `camp_night`, `winter_day`, `winter_evening`, `winter_night`, `home`, `road_leg`, `hold`, `hold_night`): çisenti 0,35, yağmur 0,2, sulu kar ve kar 0,15, yoğun kar 0,1, yağmur sonrası 0,45 (0,5 sa'te söner); yakın gök gürültüsü müziği 2 sn −3 dB indirir; hikâye müziklerine dokunulmaz (`weather.md` §10.3). Gündelik müzik `clock:phase` ve saatle seçilir, sahne ve görev durumu önce gelir; atlamada durum varış saatine göre seçilir, geçiş karartma içinde biter (K20).
~~~

**Bul:**
~~~
`freeroam`, `home` → `wind_steppe` 0,6 + `fire_loop` 1 + `camp_day` 0,35, alacakaranlıkta (`moodTarget` > 0,75) `camp_day` yerine `night_meadow` 0,45;
~~~
**Yerine:**
~~~
`freeroam` → evrenin listesi (`spec.audio.ambience.{dawn, morning, noon, golden, dusk, night}`, `time.md` §8.5; 8 sn'de süzülür; `moodTarget` eşiği kalktı), `home` → `golden` listesi (saat iğneli);
~~~

**Bul:**
~~~
Kış zemini ve başka dünyaların ortamı o dünyanın sahibinindir (Faz 9).
~~~
**Yerine:**
~~~
Kış zemini ve başka dünyaların ortamı o dünyanın sahibinindir (Faz 9). **Hava (K22).** `SoundSystem` havanın döngü listesini kendisi kurmaz, `ctx.weather.audio`'yu okur: `{ beds, windK, windSwap, quiet, inside }`. Taban listede rüzgâr döngüsü × `windK` (`windSwap` ise `wind_gale`'e geçer), öteki döngüler × `quiet`, sonra `beds` eklenir (9.8'e dek tanımsız döngü atlanır); yurt içinde yağmur `rain_felt`'e döner, rüzgâr ×0,4. `ambience.set` yalnız kimlik listesi değişince ya da bir kazanç 0,05'ten çok oynayınca, en çok 4 Hz çağrılır. Menü, `newgame`, `creator` listesi havasızdır. Kış dünyasının ve yerleşim dünyalarının ses sahibi aynı birleşimi yapar (`weather.md` §10.4).
~~~

### M28. §3.7 Sistemler: tablo

**Bul:**
~~~
| 12 | `child` | `game/child.js` | freeroam, home |
~~~
**Sonrasına ekle:**
~~~
| 15 | `clock` | `game/clock-system.js` | freeroam, play, home (iğneli) |
~~~

**Bul:**
~~~
| 20 | `calendar` | `game/calendar.js` | play |
~~~
**Yerine:**
~~~
| 20 | `calendar` | `game/calendar.js` (8.9) | play |
| 22 | `weather` | `game/weather.js` | ikisi |
~~~

**Bul:**
~~~
| 60 | `structures` | `world/structure.js` | ikisi |
~~~
**Sonrasına ekle:**
~~~
| 61 | `sites` | `game/sites.js` | ikisi, home |
~~~

**Bul:**
~~~
| 62 | `builders` | `game/builders.js` | ikisi |
~~~
**Sonrasına ekle:**
~~~
| 64 | `settlement` | `game/settlement/index.js` (9.9) | play |
~~~

**Bul:**
~~~
| 80 | `npcs` | `game/npcs.js` | play |
~~~
**Sonrasına ekle:**
~~~
| 81 | `camp_life` | `game/camp-life.js` | freeroam |
~~~

### M29. §3.7: `home` cümlesi ve sistem paragrafı

**Bul:**
~~~
`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures` çalışır.
~~~
**Yerine:**
~~~
`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures`, `sites` ve iğneli `clock` çalışır; `weather` `home`'da çalışmaz (hava kimlik).

**Saat, hava, şantiye, yerleşim (K20–K24, `d2/core.md` §6).** `clock` (15) dünya saatini ilerletir, `world.lightBase`'i yazar; Bekle, Uyu, Dinlen, Çalış ve vakit çağrısını yürütür (§3.23). `calendar` (20) vakit ve uyku kapısını sürer. `weather` (22) saatten sonra, okuyucularından (`campfire`, `structures`, `sites`, `settlement`, `stealth`, `travel`, `nodes`, `sound`) önce çalışır: hepsi aynı karenin `ctx.weather.fx`'ini okur; `mount`, `player`, `child` (5–12) bir kare önceki `fx`'i okur. `sites` (61) şantiyeleri sürer (§3.25). `settlement` (64) yerleşim ve ordugâh durumunu, hangi dünya yüklü olursa olsun her `clock:hour`'da işler: önce Kâhya ekipleri yazar, sonra K21 `sites` şantiye emeğini, yerleşimin `production`'ı tezgâhları (`Workshop.tick`) ve toplama kolunu, `CampState` ve `CaravanBook`; `dawn`'da tüketim (`SupplyLedger`) ve sürü (`herdDay`), sonra Çekim, katılım, ayrılış, Gönül; `clock:skip`'te ≤3 gün saat saat, uzunu günlük adım; `act:change`'te Kronik (§3.27). K24 ayrı bir `GameSystem` kurmaz: `Container`, `Workshop`, `herdDay`, `transfer`, `armyShare`, `rolloverYears`, `SupplyLedger` saf servislerdir (§3.26). Yüklü dünya `spec.settlement` taşıyorsa görünüm, Plan Kipi ve etkileşimler açılır. `camp_life` (81) yalnız ana kampta, yalnız Serbest Gez'de çalışır. Görünür işçi `NpcManager.budget`'ını (16 tam, 40 kukla) paylaşır; ayrı bütçe yoktur.
~~~

### M30. §3.8 WorldSpec: kamp örneği

**Bul:**
~~~
  moods: { stops: [MOODS.golden, MOODS.dusk], startT: 0.3 },   // kış: morning, noon, evening, night; t 0..3
~~~
**Yerine:**
~~~
  light: { lat: 47.35, dec: 7.4223, menuMinute: 886.18, menuSun: [-0.66, 0.6, 0.46] },   // K20: sapma iğneli (11 Nisan); sun.dir bu günün 14:46,2'sindeki gerçek güneştir
  moods: { stops: [MOODS.golden, MOODS.dusk], startT: 0.3, cycle: { palettes: MOODS, golden: 820 } },   // menü golden→dusk 0,3; Serbest Gez altı durak; kış: light { lat: 38.9 }, cycle WINTER_MOODS, golden 840
~~~

**Bul:**
~~~
  nodes: [],  roads: null,  stations: [],
~~~
**Sonrasına ekle:**
~~~
  weather: { climate: 'orkhon', season: 'camp_spring', exclude: [], accumulate: { snow: false }, snowFelt: 1, dur: { snow: [1, 3] },
             box: [70, 30, 90], points: 6000, splashes: 192, fogZones: [], shelters: null, menu: 'identity' },   // K22 (§3.24)
  labour: { torchFree: true, rawWork: false },    // K21: ana kampta meşale bedava, malzeme yontulmuş gelir (d2/core.md §2.4, §2.6)
~~~

Kamp örneğindeki `audio.ambience` alanı (Faz 7: `{ menu, day, dusk }`) K20 ile evre listelerine geçer: `{ menu, dawn, morning, noon, golden, dusk, night }` (`time.md` §8.5; `menu` aynen kalır); 8.9 kamp spec'ini, `L` `sounds.js`'i buna göre yazar.

**Bul:**
~~~
    day: [{ id: 'wind_steppe', gain: 0.6 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }, { id: 'camp_day', gain: 0.35 }],
    dusk: [{ id: 'wind_steppe', gain: 0.5 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }, { id: 'night_meadow', gain: 0.45 }],
~~~
**Yerine:**
~~~
    dawn: [{ id: 'birds_day', gain: 0.5 }, { id: 'wind_steppe', gain: 0.35 }, { id: 'fire_loop', gain: 0.6, at: [0, 0.5, 0] }],
    morning: [{ id: 'birds_day', gain: 0.35 }, { id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.55 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    noon: [{ id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.7 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    golden: [{ id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.7 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    dusk: [{ id: 'camp_day', gain: 0.2 }, { id: 'night_meadow', gain: 0.3 }, { id: 'wind_steppe', gain: 0.45 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],   // camp_day → night_meadow evre boyunca
    night: [{ id: 'night_meadow', gain: 0.45 }, { id: 'wind_steppe', gain: 0.3 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],   // fire_loop 22:30'dan 0,5 (sounds.js saatle)
~~~
`fire_loop` ocak yandıkça her evrede çalar; `time.md` §8.5 tablosu yalnız değişen kazançları yazar. Kazançlar evre değişince 8 sn'de süzülür.

### M31. §3.8 World: ışığın tek hattı

**Bul:**
~~~
  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır
~~~
**Yerine:**
~~~
  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır; menü yolu, değişmez
  lightBase;  setTimeOfDay(sample | null);  writeLight();  timeDriven;  mixTone(out, key, a, b, t);   // K20 (8.9): saat yalnız lightBase'i yazar; writeLight tek yazıcı (8.9 kimlik, 9.4'ten WeatherView.compose)
  tallThings;      // K22: yıldırım adayları [{ id, x, z, h, kind: 'tree'|'pole'|'tower'|'structure', lone }], ≤256; flora (9.4) ve yapı yöneticisi (9.6) doldurur; weather 9.4'e dek null
~~~

**Bul:**
~~~
(Tengri kamerasında ≈190 m: uzak parça belirir).
~~~
**Sonrasına ekle:**
~~~

**Işığın tek hattı (K20, K22, K26; `time.md` §5, §12.6; `weather.md` §9.2).** `MOODS` altı durak taşır: `night`, `dawn`, `morning`, `noon`, `golden`, `dusk`; son ikisi bugünkü değerlerdir, bit bit aynı kalır. Menü, Yeni Oyun, oluşturucu ve `home` `applyMood(t)`'yi bugünkü gibi kullanır, saati ve havayı okumaz. `freeroam` ve `play`'de `ClockSystem` 4 Hz'de (bekleme akışında her kare) `setTimeOfDay(sample)` çağırır: iki durak `mixTone` ile karışır, sonuç düz `world.lightBase` kaydına yazılır (renkler, yoğunluklar, sis, kubbe anahtarları, göl, köy, kenar ışığı, pozlama, yön, `k`, ay, gece); three.js nesnesine dokunmaz, ayırma yapmaz (`TONES` altı durağı bir kez çözer). Güneşi, yarımküreyi, sisi, kubbe, göl ve kenar uniform'larını ve pozlamayı yalnız `writeLight()` yazar: 8.9'da kimlik (tabanın kopyası; sayılar bugünkü `applyMood` ile aynı sıra ve değerde), 9.4'ten `WeatherView.compose(base, params, flash)` (hava çarpanı yalnız burada, bir kez). `writeLight` karede en çok bir kez, yalnız taban, hava ya da şimşek değişince çalışır; `setFogOverride` en son kazanır. Yön oyun dakikasında bir adım değişir (≤0,25°) ve ışık uzayında gölge ızgarasına oturtulur; gölge düşüren yükseklik ≥15°, `normalBias × max(1, sin 36,7° / sin el)` (≤0,14), güneş 15°'nin altında `kLow = 0,35 + 0,65 × smoothstep(0°, 15°, el)`; gölge haritası donukken (Tipi, Donuk Kamp, `freeze`) yön de donar. Geceleri aynı `DirectionalLight` ay ya da gök yönündendir; ışık eklenmez, saat program eklemez (hava +2, §7). Geriye uyum: `setTimeOfDay` `world.moodT` ve `moodTarget`'ı evreden türeyen 0..1 akşamlık değeriyle yazar (ışık yazmadan; `interior.js` ocak parıltısı okur); `drawMenuFrame` ikisini `MENU_MOOD`'a iğneler (Faz 7). Serbest Gez yeni oturumda menü dakikasında (14:46,2) açılır: o dakikada saat ışığı menü ışığıdır; menüden iniş 2,4 sn, dönüş 1,7 sn süzülür (ışık ve hava birlikte). Zerrelerin `motes` kanalı menü anahtarına dek 0'dır (`s` 4,3), batışta (`s` 5) 1'e çıkar.

**Hava görünümü (K22, 9.4; `weather.md` §9).** `world.weather` `WeatherView`'dur (`world/weather.js`, §3.24): `World.build`'in son adımında kendi tohumuyla kurulur (kamp RNG akışı değişmez); 9.4'e dek `null`dur, çağıranlar `?.` kullanır. Üç ağı vardır: yağış ve sıçrama noktaları (`weather_pts`; tek geometri, tek çizim, ≤6000 + 192 nokta) ve yıldırım şeridi (`weather_bolt`, ≤96 üçgen, ≤0,35 sn); yükleyici derlemesinde görünür yapılır, sonra gizlenir (§8 karar 36 deseni). Ekran yağışı FINAL'dedir (§3.21; 0 çizim). Sıra: taban → hava çarpanı (sis rengi; kamera tabanı yakın ≥0,5 × kamera uzaklığı, uzak ≥ kamera uzaklığı + 50 m; bölge sisi `spec.weather.fogZones`) → şimşek nabzı (pozlama × (1 + A·f), yarımküre yoğunluğu ve rengi; ışık eklenmez) → `setFogOverride` kazanır. Hava etkinken göl sis aralığı `LAKE_FOG_R × fogFarK`. Barınak değeri `ctx.weather.shelterAt(x, z)`'tir (oda, yapı, araba koltuğu, orman kıyısı yarım). `world.weather.identity(fade)` menü kimliğine döner (`weather.md` §9.12).
~~~

### M32. §3.8: yeni spec alanları

**Bul** (`**Kışlak zemini.**` paragrafının sonu):
~~~
düşük çözünürlüklü maske, yol çıkartmaları. Parça başına boyama yok.
~~~
**Sonrasına ekle:**
~~~

**Yeni spec alanları (K20–K24).** Kamp spec'i (8.9) ve Kışlak spec'i (9.1) saat, hava ve emek alanlarını; II. Perde dünyaları (Faz 13) ve kum havuzu (8.12, 9.9) yerleşim alanını taşır. Taşımayan dünyada sistem varsayılanı kullanır: saat ana kampın enlemi, hava `clear` kimliği, emek `{ torchFree: false, rawWork: true }`.

```js
// specs/winter.js (9.1) ekleri
light: { lat: 38.9 },  moods: { cycle: { palettes: WINTER_MOODS, golden: 840 } },   // gün takvimden: Gün I = dayN 1.041
weather: { climate: 'hexi', season: 'calendar', exclude: ['heavy_snow', 'blizzard'], accumulate: { snow: true }, snowFelt: 0.5,
           fogZones: [/* Buz Kolu 120 m, Kara Boran Ak Otlak */] },
labour: { torchFree: true, rawWork: false, deliveries: 'kislak_new_yurt' },   perish: { fish: false },   // kışın balık donuktur (soğuk mekaniği değil)
sites: [{ id: 'new_yurt', kind: 'yurt', preset: 'winter', x, z, rot, y0, mode: 'timed', crew: ['nanay', 'yz_hand1', 'yz_hand2'],
          schedule: 'kislak_new_yurt', stock: {}, orders: { night: 'rest' }, gates: { y_tunduk: 'crown_raised', y_ocak: 'feast_ember' } }],

// specs/tanhu-ordu.js (13.1); whistle-field.js (13.2) aynı alanı kind: 'camp' ile yazar
settlement: {
  kind: 'hold',                                   // 'hold' | 'camp'
  hearthSites: [{ id: 'hs_terrace', at: [-80, -100], name: { tr: 'Seki', en: 'The Terrace' }, traits: { water: 38, flood: 0, wind: 1 } } /* hs_bend (170, 10), hs_lee (−330, −380) */],
  plots: { /* hearthSite → önceden kırpılmış parsel çokgenleri: core, dwell, work, pen, field, sacred, wall, edge */ },
  sacred: { id: 'sacred_hill', at: [-420, -470], r: 6 },
  water: [{ kind: 'brook', pts: [[-700, -300], [-80, -150], [160, 60], [700, 150]], flood: 25 }],
  wind: { dir: [0.71, 0.71], ms: 4 },             // hâkim rüzgâr; yalnız rüzgâraltı kuralı için
  clusters: ['c_elm_bend', 'c_willow_brook', 'c_reed_bend', 'c_hay_meadow', 'c_dung_steppe', 'c_saxaul', 'c_quarry', 'c_clay', 'c_salt', 'c_iron', 'c_birch_hill'],
  gates: ['gate_ordu_w', 'gate_ordu_e'],  dailin: { at: [380, 300], r: 160 },  limits: { records: 160, live: 48 },
},
campSites: [],                                    // sefer iç haritaları: [{ id, x, z, r, water, grazeKm2 }] (settlement.md §3.4)
weather: { climate: 'steppe_south', season: 'calendar' },  light: { lat: 43.5 },  labour: { torchFree: false, rawWork: true },
```

Parsel çokgenleri yükleyicide hesaplanmaz, veriye yazılır; kuralları `data/settlement.js` `PLACEMENT`'tır ve `validatePlacement(def, place, { …, rules })` okur (§3.25). Kum havuzu dünyaları `sandbox_site` (8.12: düz zemin, her yapı türü, ekip ve hava düğmeleri) ve `sandbox_hold` (9.9: aynı zemin, 3 Ocak Yeri, düğüm kümeleri, 10 hane, dolu ambar) kampa ve menüye dokunmaz.
~~~

### M33. §3.11 Yapı sistemi: `StructureState`, `StagedStructure`

**Bul:**
~~~
  constructor(def, { mode, preset, startFull });
  stage; step; stepT; pools; units; burnT; contrib; fell; tears;
  advance(dtWork);  sliceTick();  deliver(item, n, who);  credit(seconds);
~~~
**Yerine:**
~~~
  constructor(def, { mode /* 'timed' | 'script' */, preset, startFull });
  stage; step; stepT; wm; rate; pools; units; burnT; contrib; fell; tears;   // wm: işlenen iş dakikası (İD); rate: İD / oyun dk, yalnız sürücü yazar
  advance(wm);  deliver(item, n, who);  credit(wm);  dismantle();            // K21 (§3.25); sliceTick kalktı; credit çarpansız senaryo armağanı; dismantle tersten, emeğin 0,35'i
~~~

**Bul:**
~~~
  setStage(n, { cause, stagger });  repairStep(dtWork, who);
~~~
**Yerine:**
~~~
  setStage(n, { cause, stagger });  repairStep(wm, who);           // onarım emeği İD (labour.md §7)
~~~

**Bul:**
~~~
  constructor(def, place, world, { mode: 'timed'|'slice', preset, startFull });
~~~
**Yerine:**
~~~
  constructor(def, place, world, { mode: 'timed'|'script', preset, startFull });   // K20: 'slice' kalktı; Kışlak Yeni Yurdu da 'timed' (SiteSystem sürer)
~~~

**Bul:**
~~~
  deliver(item, n, who);  credit(seconds);  repairStep(dtWork, who);  sliceTick();
~~~
**Yerine:**
~~~
  deliver(item, n, who);  credit(wm);  repairStep(wm, who);  dismantle();   // deliver bohçayı açar (yurt_kit → parçalar), parça ya da ham karşılamayı adıma yazar (rawWork, K24)
~~~

### M34. §3.11: usta maddeleri

**Bul:**
~~~
- **Usta** `game/builders.js` zaman çizelgesine bağlıdır: takılan usta inşaatı kilitlemez (`structures.md` §10.2).
~~~
**Yerine:**
~~~
- **Usta** `game/builders.js` emek çizelgesine bağlıdır: oran `labour.stepRate`'ten, takılan usta inşaatı kilitlemez (`structures.md` §10.2). Saat durunca emek durur, saat atlayınca `labour.simulate` toplu işler (§3.25).
~~~

**Bul:**
~~~
- **Usta.** Yardım tablosu tektir: `game/builders.js` `HELP` (`structure-defs.js`'teki kopya kalktı).
~~~
**Yerine:**
~~~
- **Usta.** Yardım tablosu tektir: `game/builders.js` `CHILD_HELP` (K21: katılma fiilleri ve ayak işleri; kredi kalktı, `d2/core.md` §2.10). Ekip Oktar, Erka ve Dengiz baştan sonadır; Çocuk adımın fiilini yaptıkça 0,5 ağırlık ve bir baştır; batıştan sonra `G_TORCH` direkleri yanar; hava durağında `SHELTER` (`d2/core.md` §2.8).
~~~

### M35. §3.11: K21, K22, K23 paragrafları

**Bul:**
~~~
Ölçüldü: menü 56, Serbest Gez 57, hasarlı A ile 58 program (tavan 92).
~~~
**Sonrasına ekle:**
~~~

**K21 emek yasası (§3.25).** Süre saniye değil emektir: adımın `work` alanı ekip emeğidir (İD), `solo` tek el çarpanıdır (yalnız `y_tunduk`, 1,6: bakanla), `min`–`max` el sınırıdır; tanımda `craft` (`home`, `wood`, `earth`) ve `crewMax` vardır; parça ve ham teslim `parts`, `rawWork`, `rawRole` alanlarıdır (`d2/core.md` §2.6; `spec.labour.rawWork: false` dünyasında ham iş eklenmez). Oranı yalnız sürücü yazar: camp3'te `BuilderSystem`, öteki şantiyelerde `SiteSystem`, ana kampın A, B, ahır ve çitinde yapının yedeği (iki elin oranı); `StructureState` yalnız tüketir. Kışlak Yeni Yurdu `mode: 'timed'`'dır: `SiteSystem` saat, ekip, malzeme ve hikâye kapısıyla sürer. Sayılar `d2/core.md` §2 ve `labour.md`.

**K22 hava (§3.24).** `WeatherSystem` her kare `world.structures.wind`, `.windDir` ve yapıların `spreadEntry.wet`'ini (keçe ıslaklığı) yazar, yanan yapıya `douse(fx.douse × dt)` uygular; sıçrama `R = 10 + manager.wind` tek kuraldır. 9.6 ekler: ateşli okun tutuşma çarpanı `1 − 0,5 × felt`; aşama değişince yapı yöneticisi `world.tallThings`'e aday ekler ve siler (kurulmakta olan yapı aday değildir; yurt `bounds.top` 8,6 m); **Bağla / Tie Down** (`tent`, `rack`; `E` 3 sn, kalıcı) ve **Çöz / Untie** (`E` 1 sn) etkileşimi; `fx.galeDamage`'de bağsız çadır bölüm başına %25 olasılıkla bir aşama düşer, bağsız raf içinin %20'sini döker (`structures.md` §6.5). Islak keçe `FELT_WET` kancasıdır; program eklenmez.

**K23 yerleşim yapıları (`settlement.md` §7, `structures.md` §4.6).** Yeni türler ve hazır ayarlar veri olarak `STRUCTURE_DEFS`'e 8.11'de girer: `yard`, `mound`, `ring`, `post`, `field` aileleri; `shed` `open`/`walled`, `tower` `low`/`gate`/`granary`, `fence` `picket`/`stockade`; `yurt` `scale` ve `hearth: false`; `y_raf`, `y_seki`. Görünüşleri `world/structure-kits.js`'tedir (9.10): `StagedStructure._build` ve `_look` yurt, ahır ve çit dışında `KITS[kind]`'a sorar; karşılığı yoksa yapı görünüşsüz (yalnız mantık) çalışır. `def.scale` (Otağ 1,4) kökü, `bounds`'u, nav şekillerini, oda sınırını ve pedi birlikte çarpar, birim canı `scale²` ile çarpılır (9.6). **Uzak yapı.** 40 m ötesinde ya da en yakın dördün dışında yurt kendi ağını gizler, `YurtField` yuvasına geçer (`closed` örneği, `aCut` yapım yüksekliği, `aChar` yanık; 220 m ötesi 96 üçgenlik kubbe); öteki türler `KitField`'e (bütün türlerin kaba ağları tek `BatchedMesh`, tür başına ≤400 üçgen); yakına giren yapı 0,25 sn'de kendi ağına döner (`settlement-view.js`, 9.9). Aynı anda ≤48 canlı `StagedStructure`. **Yerleşim denetimi** `nav.canPlace(shapes)` (9.2): geçici damga, `labelComponents`, ocak, kapılar ve zon kapıları aynı bileşende mi; sonra geri alır (≤3 ms, tıklamada bir kez).
~~~

### M36. §3.12 Kaynak düğümleri

**Bul:**
~~~
  onDawn();                     // yenilenir, kalıcı bit kalır
~~~
**Yerine:**
~~~
  onDawn();                     // yenilenir, kalıcı bit kalır; NodeSystem 'dawn' olayında çağırır: ≤24 sa atlamada atlanan her şafakta bir, uzun atlamada bir kez (K20)
  applyTaken(cluster, n);       // K23: yerleşimin uzaktan aldığı n hakkı kümenin düğümlerinde tohumlu sırayla işaretler (kalıcı: perm, yenilenen: day); dünya kurulurken
~~~

**Bul:**
~~~
  yield: [{ item: 'wood_pine', n: 3 }], charges: 1, renew: 'perm'|'dawn'|'none', sense: false, r: 0.45, block: true, noise: { axe: 24 } };
~~~
**Yerine:**
~~~
  yield: [{ item: 'wood_pine', n: 3 }], charges: 1, renew: 'perm'|'dawn'|'none', sense: false, r: 0.45, block: true, noise: { axe: 24 } };
// K22: isteğe bağlı weather alanı (node_mushroom: son 12 sa'te ≥1 sa yağmur ×2, değilse ×0,5; node_dung: yağmurdan sonraki 6 sa yakıt ×0,5);
//      açık yığınların flags dizisinde wet biti: yakıt ve yem değeri ×0,5, 2 sa dryK ≥0,6 ya da ateşin 4 m'sinde 30 sn kurur (weather.md §8.14)
// K23: spec.nodes kümeleri id taşır (c_elm_bend …); yerleşim kümeden aldığını settlement.taken[cluster]'a sayar, NodeStore bellekte olmasa da
// K21: node_camp_logs: ana kampın kütük yığını; camp3'ün help_log ayak işi buradan alır
~~~

### M37. §3.13 Eşya: `ITEMS`

**Bul:**
~~~
// game/items.js (saf)
ITEMS[id] = { tr, en, w10, stack, worth, tags: ['bulk','wood'], food: { fullness, buff }|null, tool: {...}|null, slot: 'feet'|null };
// Dolduran: economy.md §2 satırları + data/gear.js + data/weapons.js birleşimi
export function matches(id, ref);          // ref: 'wood_pine' | 'tag:wood'
export function itemName(id);              // L({tr,en})
~~~
**Yerine:**
~~~
// game/items.js (saf)
ITEMS[id] = { tr, en, tier: 'raw'|'proc'|'part'|'fin'|'bundle', w10, per: 1, stack, worth, tags: ['bulk','wood'], act,
  ration: 0, fuel: 0, bundle: null, source: null, food: { fullness, buff }|null, tool: {...}|null, slot: 'feet'|null, fine: false };
// Dolduran: data/items.js (economy.md §2, d2/economy.md §2; 23 yeni kimlik, hide «Ham Deri / Rawhide») + data/gear.js + data/weapons.js birleşimi.
// per: w10 bu kadar adedin ağırlığıdır (ok, temren, gövde 10). bundle: { id: n } teslimde açılır. source 'trade': kaynak değil takas. Sürü kaba girmez (sayıdır).
export function matches(id, ref);          // ref: 'wood_pine' | 'tag:wood'; etiket ITEMS[id].tags'ten (ad öneki değil); 'x+' baseId ile
export function itemName(id);              // L({tr,en}); İnce İş: «… · İnce İş» / «… · Fine Work»
export function baseId(id);  export function isFine(id);   // 'hun_bow+' → 'hun_bow', true; kalite yalnız teçhizatta
export function stackLoad10(id, n);        // ceil(n × w10 / per), onda bir Yük
export function rationOf(id);  export function fuelOf(id);  export function bundleOf(id);   // pay (öğün), yakıt, bohça içeriği
~~~

### M38. §3.13: `Inventory` kapları

**Bul:**
~~~
  chest;  stash(way);  cart;  cache;             // { add, remove, list, load, cap }
~~~
**Yerine:**
~~~
  chest;  stash(way);  cart;  cache;  sled;  saddlebags(mountId);   // hepsi game/container.js Container (§3.26): { add, remove, list, load(), cap }; Terki sınırı binek Yük'ü
  setResolver(fn);  site(id);  store(id);  pool(place);              // K21, K23: kaydı başka blokta olan kaplar: şantiye yığını (world.sites), yerin kapları (settlement); fn(kind, id) → Container | StorePool | null, L bağlar
  deliverTo(c, ref, n);                                             // heybeden bir kaba (transfer); bohça teslimde açılır; item:move yayar
~~~

### M39. §3.14 Koşul ve etki

**Bul:**
~~~
       | 'slice:'name | 'atlas:'id | 'tally:'npc
~~~
**Yerine:**
~~~
       | 'slice:'name | 'phase:'name | 'beat:'id'.'state | 'atlas:'id | 'tally:'npc
~~~

**Bul:**
~~~
name  := trust | kut | korku | herd_habit | reflex | names_known | hearths_out | bond | act | day | level | rank
~~~
**Yerine:**
~~~
name  := trust | kut | korku | herd_habit | reflex | names_known | hearths_out | bond | act | day | hour | dark | moon | level | rank
~~~

**Bul:**
~~~
Bilinmeyen `name` bayrak sayılır: yoksa false, sayıyla kıyasta 0.
~~~
**Sonrasına ekle:**
~~~

K20: `day` hikâye günüdür; `hour` gün saatidir (`hour>=12`); `dark` güneş −6°'nin altındadır; `moon` ayın aydınlığıdır (0..1, takvimden); `'phase:'name` evre (`dawn`, `morning`, `noon`, `golden`, `dusk`, `night`); `'beat:'id'.'state` vaktin durumu (`wait`, `open`, `held`, `done`); `'slice:'name` eski dört dilim olarak çalışmayı sürdürür.
~~~

**Bul:**
~~~
| `work` | `n` | `calendar.addWork` |
~~~
**Yerine:**
~~~
| `clock` | `'set', 'hh:mm'` · `'atLeast', çapa` · `'advance', dk` · `'hold', id, 'hh:mm'` · `'release', id` | `worldClock`; yalnız ileri; `hold` yalnız `dawn_line`, `ice_story` (K20; `work` kalktı) |
~~~

**Bul:**
~~~
| `ledger` | `line, n` | `supply.get('winter_camp').add` |
~~~
**Yerine:**
~~~
| `ledger` | `line, n, place = 'winter_camp'` | `supply.get(place).add`: `winter_camp`, `own_seat`, `own_camp`, `field_camp` (§3.26) |
~~~

**Bul:**
~~~
| `cine` | `id` | `cine.play` |
~~~
**Sonrasına ekle:**
~~~
| `weather` | `do, id?, ...` | `ctx.weather`: `lock`, `release`, `progress`, `pin`, `freeze`, `calm`, `flash`, `strike`, `gap` (`weather.md` §6.1); hava sistemi yoksa yok sayılır |
~~~

### M40. §3.15 Diyalog: saat

**Bul:**
~~~
| `scene` | `dialogue` modal bağlamı | Dünya akar, oyuncu durur; `stealth` algısı durur (`act1.md` §9.5) | Büyük sahne, seçim |
~~~
**Yerine:**
~~~
| `scene` | `dialogue` modal bağlamı | Dünya karesi akar, oyuncu durur; dünya saati (`worldClock.pause('dialogue')`) ve `stealth` algısı durur (`act1.md` §9.5) | Büyük sahne, seçim |
~~~

**Bul:**
~~~
| `walk` | Bağlam yok | Oyuncu yürür, satır 3B kısılır, seçim yok | «Kişiler iş bırakmaz, yürürken konuşur» |
~~~
**Yerine:**
~~~
| `walk` | Bağlam yok | Oyuncu yürür, satır 3B kısılır, seçim yok; saat akar | «Kişiler iş bırakmaz, yürürken konuşur» |
~~~

### M41. §3.16 Program, nav, gizlilik

**Bul:**
~~~
export function resolveSchedule(table, npcId, { day, slice, flags, overrides });
~~~
**Yerine:**
~~~
export function resolveSchedule(table, npcId, { day, minute, flags, overrides });   // table: [[from, to, at, job], …] oyun dakikasıyla (time.md §9.4); sev ≥3 havada açık hava yuvası shelter noktasına
~~~

**Bul:**
~~~
  onSlice(day, slice);          // yeni hedefler; >60 m ve kadraj dışında konum sıçraması
~~~
**Yerine:**
~~~
  onBlock(day, minute);         // blok değişince yeni hedef; yürüme süresi kadar önce çıkar; >60 m ve kadraj dışında konum sıçraması; clock:skip'te herkes yerine
~~~

**Bul:**
~~~
            stampDyn, clearLayer, stampLayer, stampLayerTop, labelComponents, epoch };
~~~
**Yerine:**
~~~
            stampDyn, clearLayer, stampLayer, stampLayerTop, labelComponents, epoch,
            canPlace(shapes) };   // K23 (9.2): geçici damga, bileşen denetimi (ocak, kapılar, zon kapıları), geri al; → { ok, reason }, ≤3 ms
~~~

**Bul:**
~~~
Hayvan algısı aynı çekirdeği kullanır, rüzgâr çarpanı `survival.md` §4: rüzgâr altı ×0,5, üstü ×2.
~~~
**Yerine:**
~~~
Hayvan algısı aynı çekirdeği kullanır; rüzgârın yönü ve gücü havadandır (`weather.md` §8.4): ≥1 m/sn rüzgârda altı ×0,5, üstü ×2; fırtınada (≥12 m/sn) ×0,4 ve ×2,5; durgunda yön yok.

**Hava ve saat (K20, K22).** Çarpanlar kullanım anında uygulanır, `derive` değişmez: işitme yarıçapı `noiseR × fx.hearK`; görüş `R_eff = min(R, 0,6 × fx.vis)` ve algı hızı `× fx.fogK(d)`; nöbetçi konisi `coneDeg` × yağmur ve sulu kar 0,85, sağanak ve dolu 0,75, tipi ve toz 0,7 (tarama açısı değişmez). Gizlilik saatten çarpan almaz: `act1.md` §9.2 «Karanlık» koşulu `clock.dark` ve oyuncunun ışık havuzunda olmamasıyla açılır, şimşek nabzında (`fx.flashK > 0`) kapanır. I. Perde'nin kilitli gecelerinde `pinFx` kalibre sayıları korur (`mask` 0).
~~~

### M42. §3.17 Yolculuk ve II. Perde kancası

**Bul:**
~~~
`?squad=10` demosu Faz 10'dan sonra Serbest Gez'de açılır, menüde görünmez.
~~~
**Sonrasına ekle:**
~~~

**Saat ve hava (K20, K22).** Araba seferinde saat doğal süreyle akar; Yol Akışı `k` (1–4) saatin oranıdır; Yolu Kısalt kalan doğal süreyi `clock:skip { reason: 'travel' }` ile atlar; atlas bacağı varışta yol süresi kadar atlar, 24 saati aşan bacak uzun atlamadır (`long: true`). `LOCKS` 7. sırada `weather` kilidini alır (`fx.cartLock`; kalan süre plandan, yarım saate yuvarlanır); `sev` ≥3 havada çevre şeritleri durur; atlas yol olayları havuzuna `ev_storm`, `ev_dust`, `ev_flood`, `ev_snowbound` girer (`weather.md` §8.10).

**II. Perde kancası (K23).** Yerleşim `tanhu_ordu` (`own_seat`), ana ordugâh `whistle_field` (`own_camp`); ikmal kervanı `r_whistle_ordu` üstünde yerleşimin `CaravanBook` kaydıdır (§3.27), dünya kurmaz: atlasta `travel.md` §10.4 minik arabasıyla görünür (≤12), varışta yük hedefin kabına yazılır. Mete kervanla giderse atlas bacağı kervanındır ve yol olayları ona sorulur; gitmezse «Yol Töresi» kendiliğinden çözer (`settlement.md` §11). `cmd_detail` erleri yerleşimin iş havuzuna «Er / Rider» olarak girer; `cmd_camp` `CampPlan` kurar (§3.27).
~~~

### M43. §3.19 Sinema: saat ve hava

**Bul:**
~~~
Ozan tutamağı §3.8 `world.folk.bard.perform`; `Folk`'a taşınmaz (§8 karar 3).
~~~
**Sonrasına ekle:**
~~~

**Dünya saati ve hava (K20, K22).** Sinema dünya saatini varsayılanda durdurur (`worldClock.pause('cine')`); `clock` izi saati yalnız ileri taşır (`set`, `atLeast`, `advance`) ya da sinema boyunca akıtır (`run: true`); atlanan süre `worldClock.skip(dk, { reason: 'cine' })` ile işlenir, atlamada `clock` satırları da uygulanır. `weather` satırı (`{ t, weather: { do: 'lock', id, type, blend } }`) hava kilidi açar; `release()` sinemanın açtığı kilitleri de kaldırır. Menü ve Yeni Oyun sinemasında saat ve hava yoktur (kimlik).
~~~

### M44. §3.20 HUD ve kabuk

**Bul:**
~~~
// BuilderSystem.status'u okur (rev değişince yazar): yapı adı, adım, «3/6», fırça izi ilerlemesi, adım düğümleri, yardım ipucu. Can çubuğu yok.
~~~
**Yerine:**
~~~
// BuilderSystem.status'u okur (rev değişince yazar): yapı adı, adım, «3/6», fırça izi ilerlemesi, adım düğümleri, yardım ipucu. Can çubuğu yok.
// K21: ek satır «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours» (Çocuk ya da Mete ekipteyse «+ sen» / «+ you»); bekleme nedeni varsa sürenin yerine geçer;
//      kaynak camp3'te BuilderSystem.status, öteki şantiyelerde SiteSystem.status(siteId).
// K20: ui/hud/clock.js SkyArc(ctx): id 'sky_arc', slot 'tr', modes ['freeroam', 'play']; Gök Kavisi: güneş ve ay yayı, evre adı (game.clockShow), bekleyiş düğümü,
//      Son Gece'de Ay Saati kipi (11.7), Tipide gizli; DOM'a ≤4 yazım/sn; dokununca Bekle tekeri.
// K22: ui/hud/weather.js WeatherBadge(ctx): id 'weather', slot 'tr', modes ['freeroam', 'play']; Gök Kavisi'nin yanında 10 SVG simge, cephe 1 sa içindeyse ok;
//      üstüne gelince işaret satırı (iron_stake ile gök okuma); yalnız bölüm değişince yazar.
// K23: ui/hud/plan-bar.js PlanBar(ctx): id 'plan_bar', slot 'bc', modes ['play']; yalnız 'plan' bağlamı açıkken: kategori şeridi, yapı kartı
//      (malzeme var / gerek, emek ve bitiş sözcüğü, bakım, kapasite, kilit nedeni).
// K23: ui/hold-ledger.js registerPage({ id: 'hold', tab: 'ledger', glyph: 'hearth', modes: { game: 6 } }): Yerleşim Defteri (settlement.md §14.2).
// K24: ui/transfer.js TransferPanel(ctx): 'transfer' modal bağlamı, iki sütun (heybe ↔ kap), hızlı düğmeler (d2/economy.md §5.2); açıkken saat durur.
~~~

**Bul:**
~~~
Harita ve ışık düğmeleri `virtualTap`: üstteki bağlam okur, modal altında ölüdür.
~~~
**Yerine:**
~~~
Harita düğmesi ve Gök Kavisi (`virtualTap('wait')`: Bekle tekeri) `virtualTap`'tir: üstteki bağlam okur, modal altında ölüdür.
~~~

**Bul:**
~~~
- **Işık düğmesi.** HUD ışık düğmesi ve `T` yalnız geliştirme paketindedir (§8 karar 25).
~~~
**Yerine:**
~~~
- **Işık düğmesi kalktı (K20).** Geliştirme ışık düğmesi (`moodBtn`, `setDusk`, `DUSK_ABOVE`) ve `T`'nin ışık işi kalktı; yerinde Gök Kavisi vardır, `T` her pakette Bekle'dir; geliştirmede ışık `__tanhu.clock` panelinden sürülür (§8 karar 40).
~~~

### M45. §3.21 Son işleme: hava katmanı

**Bul:**
~~~
`cloudShadow` `U.uCloudInfo.value.z`'ye yazılır (`main.js:108`): `creator` 0, diğerleri 0,34. `tone`, `brightness` `FINAL` gölgelendiricisine eklenir, varsayılanı nötrdür: `menuDiff` etkilenmez.
~~~
**Sonrasına ekle:**
~~~

**Hava katmanı (K22, 9.4).** `post.weather = { sat, con, tone: [r, g, b], bright, precip: vec4, precipDir: vec4, precipOff: [vec3 ×3], precipCol }`; `render` FINAL uniform'larına profil × katman yazar (`uSat = s.saturation × w.sat` …), birikmez. Kimlik: çarpanlar 1, `precip` 0. FINAL'e ekran yağışı dalı girer (`world/weather-hooks.js` `PRECIP_FINAL`, `weather.md` §9.3): tilt bulanıklığından sonra, doygunluktan önce; `uPrecip` toplamı 0 iken çalışmaz, menü karesi değişmez. Katman kaymaları CPU'da 256 hücre periyoduyla sarılır. Kadraj dışındaki kuzey yıldırımının ayağı aynı dalda `uBoltEdge` ile çizilir (0 çizim, 0 program). `U.uCloudInfo.z` Serbest Gez ve oyunda her kare `post.settings.cloudShadow × shadowK` olarak `WeatherView` tarafından yazılır; menüde profilin değeri aynen kalır. Kara Boran'ın derecesi hikâyenin `applyProfile('blizzard')` çağrısıdır, hava katmanı orada nötrdür.
~~~

### M46. §3.22 Yardımcı servisler

**Bul:**
~~~
// game/calendar.js (saf): act1.md §2
export class Calendar {
  act; day; slice; workPoints; jobsToday; jobTypesDone;
  addWork(n);  setSlice(name);  setDay(n);  sleep();  eatDinner();   // slice:change, dawn
  moodIndex();                                                        // spec.moods.stops konumu
  toJSON();  fromJSON(o);
}
~~~
**Yerine:**
~~~
// game/calendar.js (saf): K20; sözleşme §3.23 (İş Puanı, dilim, addWork, setSlice, eatDinner, moodIndex kalktı)
~~~

**Bul:**
~~~
  deliver(item, n, to);       // → { ledger, trust, xp }; günde 3 iş kuralı
~~~
**Yerine:**
~~~
  deliver(item, n, to);       // → { ledger, trust, xp }; hikâye günü başına 3 iş (şafaktan şafağa, K20)
~~~

**Bul:**
~~~
// game/supply.js (saf): economy.md §7
export class SupplyLedger {
  constructor(id, { fuel, food, fodder });
  value(line);  add(line, n);  onDawn(loss);  freezeToy();  toJSON();  fromJSON(o);
}
export function ledger(id);   // kayıtlı defter: 'winter_camp'
~~~
**Yerine:**
~~~
// game/supply.js (saf): SupplyLedger (soyut Kış Hesabı ve K24 ambar kipi), LEDGERS (ctx.supply), ledger(id), armyShare, rolloverYears: sözleşme §3.26
~~~

**Bul:**
~~~
  fullness;  eat(itemId);  update(dt);  band(need);  toJSON();  fromJSON(o);
~~~
**Yerine:**
~~~
  fullness;  eat(itemId);  update(dtMin, { sleep = false, rest = false });  band(need);  toJSON();  fromJSON(o);   // oyun dakikası: uyanık −5/sa × diff.foodK, uykuda ×0,25, ateş başında ×0,5; Serbest Gez'de Tokluk yok (d2/core.md §5.7)
~~~

**Bul:**
~~~
campfire.place(x, z, { stones });  campfire.feed(id, fuelS);  campfire.nearest(x, z, r);  campfire.rest(id);
~~~
**Yerine:**
~~~
campfire.place(x, z, { stones });  campfire.feed(id, fuelS);  campfire.nearest(x, z, r);  campfire.rest(id);   // rest: ClockSystem'in Dinlen tekeri (§3.23)
campfire.onSkip(minutes);   // K20: yakıt dakika × 2,5 sn yer; biten ateş cold_pit, ertesi şafakta kalkar. K22: yakıt, sönme ve yakma fx.fireK, fireOutS, fireRing (weather.md §8.5)
~~~

### M47. §4.3 Sinema veri biçimi

**Bul:**
~~~
  subtitles: 'voice',           // voice bloğundan üretilir
~~~
**Önüne ekle:**
~~~
  clock:   [ { t: 0, set: '10:40' } ],   // K20, isteğe bağlı: set 'hh:mm' | atLeast: 'civilDawn-30' | advance: dk | run: true (time.md §6.4); yalnız ileri
  weather: [ { t: 0, weather: { do: 'lock', id: 'cine_x', type: 'thunderstorm', blend: 3 } } ],   // K22, isteğe bağlı; release() kilidi kaldırır
~~~

### M48. §4.5 Örnek

**Bul:**
~~~
1. `slice:change` `mq_count` bitmişken koşulu tutturur:
~~~
**Yerine:**
~~~
1. `slice:change` (öğle evresi 10:30) `mq_count` bitmişken koşulu tutturur; Gün I'in gerçek vakti `hour>=12`'dir (öğle çanı, `time.md` §9.2):
~~~

## 5. Yeni §3 sözleşmeleri

### M49. §3.23–§3.27: yeni alt bölümler

**Bul:**
~~~
## 4. `src/story` veri biçimleri
~~~
**Önüne ekle** (§3.22'nin kod bloğundan sonra, aşağıdaki metnin tamamı):
~~~
### 3.23 Dünya saati ve takvim (K20; `game/world-clock.js`, `game/daylight.js`, `game/calendar.js` saf; `game/clock-system.js`, `game/camp-life.js`)

Kurallar ve sayılar `time.md`, kesişenler `d2/core.md` §1. **İki zaman:** `core/clock.js` oyun saniyesidir (sinema, `U.uTime`, eylem süreleri) ve değişmez; dünya saati oyun dakikasıdır (güneş, yakıt, kuruma, bozulma, emek, program, hava). 1 oyun günü = 24 oyun saati = 1.440 oyun dk = 3.600 gerçek sn; 1 oyun dk = 2,5 gerçek sn; hız ayarı yok. Eylem dünyayı durdurmaz: 15 sn'lik kazan pişirmesi saati 6 oyun dk ilerletir. Takvim günü gece yarısı, hikâye günü ve `dawn` Tan başında (sivil şafak − 30 dk) artar.

```js
// game/world-clock.js (saf)
export const DAY_MIN = 1440;  export const SEC_PER_MIN = 2.5;  export const MIN_PER_SEC = 0.4;  export const MAX_FRAME_S = 0.25;
export const SKIP_REASONS = ['sleep', 'wait', 'rest', 'work', 'travel', 'cine', 'chronicle', 'dev'];
export class WorldClock {
  constructor({ bus = null, day = 0, minute = 0, info /* (dayN) → DayInfo */ });
  day;  minute;                    // takvim günü (dayN) ve [0, 1440); ikisi tek kaynaktan: abs
  get abs();  get hourAbs();  get hour();       // abs = day × 1440 + minute (double)
  get info();  get phase();  get slice();       // bugünün DayInfo'su (gün değişince yeniden), evre, eski dilim
  get belowHorizon();  get dark();              // güneş −0,833° ve −6° altı
  get held();  get paused();  rate;             // rate 1; Yol Akışı k (1–4) yazar
  moonAge;                         // (abs) → gün; ClockSystem Calendar.moonAge'i bağlar
  advance(dtWall);                 // → ilerleyen oyun dk; dtWall ≤ MAX_FRAME_S (ClockSystem timeScale ile verir); bekleyişte at'ta durur; sınırları sırayla yayar
  pause(reason, on);               // biri açıkken oran 0: 'dialogue' (dialogue.js, scene kipi), 'cine' (cine.js), 'modal' (ClockSystem), 'frozen' (Donuk Kamp), 'lapse' (bekleme akışı)
  hold(id, { at, until = null, note = null });  // yalnız 'dawn_line', 'ice_story', 'home_golden'
  release(id);  holds();           // → [{ id, at, note }]
  summon(beatId, at);              // 'clock:summon'; bekletmez
  skip(minutes, { reason, sleep = false });     // → { from, to, minutes, dawns, hours, long }; ilk bekleyişte durur; >1.440 dk long
  setTo(absMinute, { reason });    // yalnız ileri; geri yazım geliştirmede throw, üretimde yok sayılır
  next(target);                    // 'dawn'|'morning'|'noon'|'golden'|'dusk'|'night'|'hh:mm'|çapa → abs dk
  nightClassAt(abs, fx, lit);      // d2/core.md §1.7 yüzü: info(day) + moonAge + fx.cloud → lightLevel → nightClass
  toJSON();  fromJSON(o);          // world.clock: { v, dayN, minute, holds }
}

// game/daylight.js (saf): derece ve oyun dakikası; yerel güneş saati, öğle 12:00
export function solarDec(doy);                        // −23,44 · cos(2π(doy + 10) / 365)
export function dayInfo({ lat, dec });                // → { lat, dec, sunrise, sunset, civilDawn, civilDusk, nauticalDawn, nauticalDusk, phases: [[id, from, to] ×6], dawnAt, duskAt }
export function sunAt(lat, dec, minute, out);         // → out { el, az, x, y, z }: x doğu, y yukarı, z güney, birim
export function moonAt(lat, dec, minute, age, out);   // → out { el, az, x, y, z, illum }
export function phaseAt(info, minute);  export function sliceOf(phase);
export function skyKeys(info, { golden, menu = null });   // → [{ m, s }] sıralı (time.md §5.2)
export function skyAt(keys, minute);                  // → s ∈ [0, 6)
export function lightSource(info, minute, sun, moon, out);   // → out { x, y, z, k }
export function lightLevel(sunEl, moonEl, illum, cloud = 0);  // → 0..1 (d2/core.md §1.8); bulut güneş terimini kesmez
export function nightClass(level, lit = false);       // → 'lit' | 'day' (≥0,5) | 'dim' (≥0,25) | 'dark'
export const MENU_MINUTE = 886.18;                    // ana kamp: sapma +7,4223° iğneli (11 Nisan, doy 100), 47,35°K; 14:46,2

// game/calendar.js (saf): hikâye günü, takvim, ay, vakit, uyku kapısı
export const SYNODIC = 29.530588;  export const DAY1 = { yearBC: 212, doy: 25 };   // dayN 1 = 26 Ocak MÖ 212
export const SEASONS = [['winter', 319, 73], ['spring', 74, 133], ['summer', 134, 233], ['autumn', 234, 318]];
export const ACT_START = { 1: 1041, 2: 1222, 3: 1679, 4: 2682, 5: 4314, 6: 5237 };   // K25; home 1171 (11 Nisan MÖ 209)
export class Calendar {
  constructor({ bus, clock, cond, effects, story /* { days: { [n]: StoryDay } } */, diff = () => 'normal', moonEpoch = 1044.75 });
  act;  storyDay;                   // I. Perde 1..6; 0: hikâye günü yok (Serbest Gez)
  get dayN();  get count();  get yearBC();  get doy();  get season();
  moonAge(abs);  moonIllum(abs);  lunarMonth(abs);   // dolunay Gün IV 18:00; bulut ay olaylarını değiştirmez
  beat(id);  beats();               // 'wait' | 'open' | 'held' | 'done'
  mainDone();  canSleep(bedId);     // → { ok, reason, task }
  sleep(target);  wait(target);     // ClockSystem'e atlama ister
  iceAt();  knotAt();               // Son Gece: buz saati her zorlukta 06:40 (Hikâye null: 05:45 bekleyişi); Düğüm Normal 20:10, Zor 21:40
  actStart(n);                      // → dayN
  update(dt);                       // GameSystem 'calendar' (20, play): vakit çağrısı, latest'te karartmayla götürme, dawn_line, 4 Hz
  toJSON();  fromJSON(o);           // world.calendar (order 70)
}
StoryDay = { n, mainWork: ['mq_herd_school'], beats: [{ id: 'b_herd', quest: 'mq_herd_school', earliest: '08:00', latest: '12:00' }],
             sleep: { beds: ['hostage_bed'], from: 'dusk' } | false, cuts: [] };   // veri src/story/act1/days.js (11.1)

// game/clock-system.js: GameSystem { id: 'clock', order: 15, modes: ['freeroam', 'play', 'home'] }
export class ClockSystem {
  attach(ctx);                     // ctx.worldClock, ctx.calendar (play); worldClock.moonAge ← calendar; panel 'clock' yalnız geliştirmede
  onWorld(world);                  // spec.light ve spec.moods.cycle → DayInfo ve anahtarlar; Kışlak'ta gün takvimden, ana kampta iğneli
  update(dt, t);                   // durma yoksa worldClock.advance(ctx.app.wallDt × timeScale); 4 Hz world.setTimeOfDay(sample) (bekleme akışında her kare); bekleyiş ve vakit 4 Hz;
                                   // girdi yığınının tepesi levelup, Terazi, roadcard, transfer ya da wait_wheel ise pause('modal', true): modüller saati çağırmaz
  timeScale;                       // 1; sahne yavaşlatması yazar (ıslıklı ok ×0,25, öğretim ×0,5, baskın ×0,6)
  openWheel(kind, { bed, fire, site } = {});   // kind 'wait' | 'sleep' | 'rest' | 'work'; teker açıkken saat durur → Promise<{ minutes, target } | null>
  lapse(minutes, { reason });      // görünüm (≤3 sa hızlı akış, >3 sa karartma) → worldClock.skip → oto kayıt → Promise<SkipResult>
  sample;                          // { a, b, f, dir, k, moon, night }: son taban örneği (drawMenuFrame geri yazar)
  toRoam();  fromRoam(o);          // Serbest Gez { day, minute }; o yoksa: mood > 0,75 ise 18:38, değilse MENU_MINUTE
  debug();                         // { day, minute, phase, s, held, holds, paused }
}
// home: setTimeOfDay(null) (menü ışığı), saat akmaz. Serbest Gez yeni oturumda MENU_MINUTE'ta açılır: o dakikada saat ışığı menü ışığıdır.

// game/camp-life.js: GameSystem { id: 'camp_life', order: 81, modes: ['freeroam'] }; ctx.campLife (time.md §8)
export class CampLife {
  onWorld(world);                  // yalnız spec.id 'camp': ≤2 Folk ikizi gizli kurulur; Ozan, Ana, Baba programı; hayvan takımı (K3: Doru, Akbulut, camp_stop'un kukla atı ve ≤3 yaban: ≤6)
  update(dt, t);                   // 4 Hz: blok değişimi; statik ↔ ikiz takası yalnız kadraj dışında ya da karartma altında (koni ≤8 nesne)
  menuPose(on);                    // true: statik Ozan, Ana, Baba görünür, ikizler ve yaban hayvanı gizli (drawMenuFrame, endSession)
  fireVisit(fire | null);          // Çocuğun ateşi (§8 karar 16): ateş saatlerinde Ana ve Baba gelir, ikiz sayısına girer (≤2)
  debug();
}
// «Aile bekler» (d2/core.md §2.11): kuralın tek sahibi BuilderSystem'dir (8.11). CampLife yalnız uyar: camp3:family_wait { until } gelince statikler
// until'e dek (01:30; 01:30'da aşama ≥6 ise 03:00) ya da structure:done'a dek ateşte; camp3:hearth_dawn gelince yatar, 05:00'te Ana ocağı yakar. world.folk.lookAt yalnız uyanıklara.
```

| Kip | Saat | Not |
|---|---|---|
| `freeroam`, `play` | ×1 × `timeScale`; Yol Akışı ×`k` | Kırpılmamış duvar süresi, kare başına ≤0,25 sn (§2.5) |
| Bloklayan diyalog, sinema (`run` izi yoksa), seviye, Terazi, Yol Kartı, aktarma paneli, Bekle tekeri, Donuk Kamp | 0 | `pause(reason)` |
| `map`, `pause`, gizli sekme, `freeze` | 0 | `game.update` çalışmaz |
| Uyku, Bekle, Dinlen, Çalış, Yolu Kısalt, atlas bacağı | Atlama | `clock:skip` |
| `menu`, `newgame`, `creator` | Saat yok | Sabit menü ışığı; `menuDiff` değişmez |
| `home` | İğneli | Menü ışığı |

**Atlama.** ≤24 oyun saati: `clock:skip:begin`, sonra atlanan her sınır sırayla (`clock:hour`, `dawn`, `dusk`, `clock:phase`; `skipping: true`), en son tek `clock:skip`; pahalı işi olan sistem `skipping`'deki olayları yok sayar, toplu işini `clock:skip`'te yapar. >24 oyun saati (`long: true`): sınır olayı yayılmaz; düğümler bir kez yenilenir, defter kaybı × `dawns`, hava zinciri olaysız ileri sarılır, şantiye ve yerleşim günlük adımla tümler. Toplu iş karartma altında ≤60 ms / 15 oyun saati, uzun atlama ≤150 ms / mevsim.

| Kip | Nerede | En çok | Tokluk | Not |
|---|---|---|---|---|
| Bekle / Wait (`T`) | Her yer; yasak: 30 m'de düşman ya da avcı hayvan, nöbetçi şüphesi, yürüyen at, su ve buz, Ay Saati, baskın, Kara Boran, boss, vakit içi | 12 sa; «Tan ağarana dek» 15 | −5 / sa × `diff.foodK` | Teker açıkken saat durur |
| Uyu / Sleep | Yalnız döşek (`bed`, öncelik 58), Akşam ve Gece; I. Perde'de günün ana işi bitince | 15 sa | ×0,25 | «Tanla uyan», «Güneşle uyan» |
| Dinlen / Rest | Ateş başı (`E` 3 sn) | 12 sa | ×0,5 | Stamina dolar; ≥2 sa ve Tokluk ≥25 ise 6 sa'te bir Yara −1 |
| Çalış / Work | Mete şantiyede (`T` ya da `E` 1 sn) | 12 sa | Uyanık oranı | `etaMinutes`'ten «Bitene dek»; Tokluk <25 ise kapalı; Çocuğun «Bir saat yardım et» satırı aynı yoldur |

Kesintiler: vaktin `earliest`'i, 20 m'de düşman ya da avcı hayvan, nöbetçi şüphesi, `weather:change` (`sev` ≥3), görev olayı; uyku yalnız vakit ve bekleyişle kesilir. `diff.foodK` Hikâye 0,7, Normal 1, Zor 1,15; I. Perde Kış Hesabı şafak kaybı `diff.ledgerLoss` −6 / −8 / −10.

**Vakit ve bekleyiş.** Vakit `{ id, quest, earliest, latest }`: `earliest`'te çağırır (çan, kişi, «Seni çağırıyorlar.» / «They are calling for you.»), `latest`'te başlamadıysa 3 sn karartmayla oyuncuyu vaktin yerine götürür («Vakit geldi: {task}» / «It is time: {task}»); çatışma, şüphe ya da sürüşteyse karartma durum geçince olur, saat durmaz. Pencereler zincirlidir. Bekleyiş yalnız iki tanedir: `dawn_line` (günün ana işi bitmeden Tan başında saat bekler) ve `ice_story` (Hikâye zorluğunda Son Gece 05:45); `home` iğnelidir; Serbest Gez'de saat hiç beklemez.

**Işık tabanı.** `ClockSystem` örneği `{ a, b, f, dir, k, moon, night }` üretir, `world.setTimeOfDay(sample)` yalnız `world.lightBase`'i yazar; three.js nesnelerini yalnız `world.writeLight()` yazar (§3.8 «Işığın tek hattı»). Gece sınıfı `lit` · `day` · `dim` · `dark`'ı emek, hava, ordu ve hayvan okur; gizlilik okumaz (§3.16).

**Kayıt ve panel.** `world.clock` (69) ve `world.calendar` (70) yolculuk bloklarıdır; Serbest Gez `clock: { day, minute }`'ı `freeroam` (`L`) `toRoam()` ile yazar. `__tanhu.clock`: `get()`, `set('hh:mm')`, `next(phase)`, `skip(min)`, `lapse(h)`, `hold(id, hhmm)`, `release(id)`, `keys()`, `stop(on)`.

### 3.24 Hava (K22; `data/weather-types.js`, `data/climates.js`, `game/weather-core.js` saf; `game/weather.js`, `world/weather.js`, `world/weather-hooks.js`)

Türler, iklimler, planlayıcı, etkiler, çizim ve ses `weather.md`; kesişen sayılar ve tepki sahipleri `d2/core.md` §3. 17 tür (`clear`, `cloud`, `overcast`, `fog`, `drizzle`, `rain`, `downpour`, `thunderstorm`, `dry_storm`, `hail`, `wind`, `gale`, `sleet`, `snow`, `heavy_snow`, `blizzard`, `dust_storm`) ve hikâyenin `kara_boran`'ı; alt olaylar `flash`, `strike`, `thunder` (`d / 343` sn), `gust`, `gust_front`, `hail_burst`, `squall`, `whiteout`. Durum oyun saatiyle, devinim gerçek saniyeyle akar. Hava yalnız fiziksel `fx` yayar, tepki tablosu tutmaz; sıcaklık ve soğuk modellenmez (K1).

```js
// data/weather-types.js (saf): TYPES[id] = { tr, en, sev, dur: [minH, maxH], wet, group, params: WeatherParams }; SUB[id] = alt olay satırı
WeatherParams = { cloud, cover, coverSky, shadowK, cloudSpeedK, dark, sunK, hemiK, expK, fogNearK, fogFarK, fogTint, fogMix,
                  sat, con, tone, rain, snow, hail, dust, points, splashes, wind, gust, vis, mask, wetGround, wetFelt, snowRate, storm };
// data/climates.js (saf): CLIMATES[climate][season] = { share: { [type]: % }, curves, wind: { dir, ms }, pHail, showery }; ZONE_CLIMATE[zone]

// game/weather-core.js (saf)
export class Planner {
  constructor({ climate, season, exclude = [], seed, zone, types, climates });
  plan;                            // Segment[]: plan[0] şimdiki bölüm, ≥12 sa ileri
  advance(hourAbs);  lock(id, opts);  release(id);  locks;
  at(hourAbs, out);                // → { a, b, k }: karışan iki bölüm ve oran
  toJSON();  fromJSON(o);
}
Segment = { type, t0, t1, src: 'sim' | 'build' | 'clear' | 'story', front: null | { kind, to }, seed };   // t0, t1: hourAbs
export function calibrate(target, opts);          // ayarlı ağırlık; climate:season:exclude anahtarıyla önbellekli (≈45 ms, dünya kurulurken bir kez)
export function blend(pa, pb, k, out);            // WeatherParams karışımı, ayırmasız
export class WetState { step(dtH, p, opts);  skip(hours, p);  toJSON();  fromJSON(o); }   // ıslaklık, çamur, kar örtüsü, Kar Kabuğu; atlamada analitik
export function fxFor(p, wet, opts, out);         // WeatherFx'i yazar
export function strikePick(cands, point, rules);  // → aday | null: en büyük h_eff − 0,15 × uzaklık, adalet kuralları
export function thunderDelay(d);                  // d / 343
export function signsFor(plan, nowH, opts, out);  // bekleyen işaretler

// game/weather.js: GameSystem { id: 'weather', order: 22, modes: ['freeroam', 'play'] }; ctx.weather
export class WeatherSystem {
  attach(ctx);                     // bus 'app:state' (kimlik), 'clock:hour', 'clock:skip' (long dahil), 'dawn'; world.weather bloğu (78)
  onWorld(world);                  // spec.weather, iklim ayarı, plan (kayıttan ya da sabit çapadan), world.tallThings
  update(dt, t);                   // saat → planlayıcı, karışım, alt olaylar (hava saati saniyesi), ıslaklık, fx, audio; world.weather?.apply(...); müziğin rain katmanı
  place(dt, t);                    // sıçrama konumu (aktörler yerleştikten sonra)
  fx;  audio;                      // aşağıda; her kare yerinde yazılır, ayırma yok
  lock(id, { type, params = null, keys = null, blend = 6, until = null, pinFx = null, signs = false, after = 'resume' });
  release(id, { blend = 6 });  progress(id, k);  pin(params, seconds);  freeze(on);  calm(on);
  flash(power, dirXZ);  strike(target, { telegraph = true });  gap(dirXZ, radius, seconds);
  shelterAt(x, z);                 // 0..1: oda, yapı, araba koltuğu, orman kıyısı yarım; spec.weather.shelters ek
  windAt(x, z, out);               // m/sn; kuytu ve calm uygulanmış
  next(hours);                     // → [{ type, at, sev }]: HUD, gök okuma
  toJSON();  fromJSON(o);  toRoam();  fromRoam(o);  debug();
}
WeatherFx = { type, sev, front, wind, gust, dirX, dirZ, cloud, vis, fogK, mask, thunderMask, hearK, flashK, trackK, trackAbs, scentK, calm,
              fireK, fireOutS, fireRing, douse, dryK, wetGround, wetFelt, mud, puddle, snowFresh, wetBow, cartK, roughK, cartLock,
              snowpack, deepSnow, crust, galeDamage, hail /* { size, minutes } | null */, strikeRisk, moonSeen, blizzard, fatigueK, pin };
weather.audio = { beds: [{ id, gain, at? }], windK, windSwap, quiet, inside };   // veri; listeyi sounds.js (L) kurar (§3.6)

// world/weather.js (9.4): world.weather
export class WeatherView {
  constructor(world, spec);        // World.build'in son adımı, kendi tohumuyla
  meshes;                          // [points (yağış + 192 sıçrama, tek geometri), bolt]
  compose(base, p, flash);         // world.writeLight'ın 9.4 hâli: tek ışık yazıcısı; kimlikte tabanın kopyası (hızlı yol)
  apply(p, fx, ev, cam, dt);       // uniform, sis, kubbe, rüzgâr, kutu, katman kayması (256 hücrede sarılı); ayırma yok
  flash(power, dirXZ);  bolt(from, to, seed);  splashAt(x, y, z, kind);
  identity(fade = 0);              // menü kimliği; fade sn'de karışır, sonunda değerler tam yazılır
  update(dt);  dispose();
}
// world/weather-hooks.js (saf, yalnız GLSL dizgesi): PRECIP_FINAL, WET_GROUND, PUDDLE, MUD, FELT_WET, SNOW_FRESH, HAIL_WHITE, kubbe ve bulut satırları
```

**Tepkilerin sahibi** (`d2/core.md` §3.3; hava değeri verir, sahip tepkisini yazar):

| Tepki | Sahip | Okuduğu |
|---|---|---|
| Kamp ateşi, pişirme, kurutma çarpanı | `campfire`, `cooking` (8.5) | `fireK`, `fireOutS`, `fireRing`, `dryK` |
| Yanan yapıya yağış, ıslak keçe, ateşli ok, fırtına hasarı, yıldırım | `structures` (§3.11, `structures.md` §6.5) | `douse`, `wetFelt`, `galeDamage`, `weather:strike` |
| Şantiye hızı ve durak | Emek (§3.25) | `type` → `weatherK` |
| Sürü, tarla, kervan, ordugâh | Yerleşim (§3.27, `settlement.md` §15.3) | `crust`, `deepSnow`, `hail`, `cartLock`, `cartK`, `galeDamage` |
| Kurutulan yiyeceğin bozulması | Ekonomi (§3.26) | `dryK`, `hail` |
| Gizlilik | `stealth-core` (§3.16) | `vis`, `fogK`, `hearK`, `flashK`, koni çarpanı |
| Ok sapması, ıslak kiriş, at ürkmesi | Hava (`projectiles`, `derive`, `mounted`) | rüzgâr, `wetBow`, `weather:thunder` |
| Ordu yorgunluğu, salvo; ay olayları | `army.md` (10.6) | `fatigueK`; ay takvimden (`calendar.moonIllum`) |

**İşaret kuralı.** `sev` ≥3 her bölüm ≥1 oyun saati önce en az üç kanaldan okunur (biri zemin ya da ışık, biri ses, biri HUD); ıslak türden gelse de her `sev` ≥3 bölümünden önce 0,75–1 sa hazırlık bölümü girer. Varışta ilk 1 oyun saatinde (Hikâye 1,5) `sev` ≥3 başlamaz. Zorluk: Hikâye ×1,5, Zor ×0,75.

**Yıldırım.** Hedef `world.tallThings`'ten seçilir: Çocuk 25 m içinde hedef olmaz; kurulan yapı hedef olmaz; vurulan yapı 1 oyun günü bekler; yerleşimde fırtına başına ≤1 yapı; Mete Normal ve Zor'da yalnız skoru en büyükse vurulur (Can −%35, taban 1, Yara yok), Hikâye'de hiç; yakın düşüşten 1,5 sn önce `static_hum` ve halka; ıslak keçe tutuşmaz. Ana kampın fırtınasında %60 olasılıkla Çocuktan 30–70 m kuzeyde, kadrajda bir ağaca ya da direğe tasarlanmış düşüş (kamp yapılarına inmez); kadraj dışı kuzey düşüşü ekranın üst kenarında FINAL katmanında görünür.

**Kar örtüsü ve Kar Kabuğu.** Zon durumu `snowpack` (0..1, saatte bir), `deepSnow` (06:00'da ≥0,6) ve `crust` (Kar Kabuğu / Snow Crust, 5–10 gün; derin kar, ardından sulu kar ya da açık öğle, ardından açık gece) sıcaklıksız, havanın sırasından okunur (`d2/core.md` §3.6); paylar `d2/weather-model.json`'dadır.

**Belirlenim ve kayıt.** Zon zinciri sabit çapadan kurulur (`floor(hourAbs / 24) × 24 − 24`'te `clear`, ileri sarılır); bölüm tohumu `(journeySeed, zone, floor(t0 × 4))`; alt olay zamanı hava saati saniyesidir `(hourAbs − t0) × 150` ve saatle durur; varış lütfu zinciri değiştirmez. `world.weather` (78, ≤1 KB): `{ v, seed, zone, climate, season, at, plan: [≤10], wet: [ground, felt, mud, puddle, snow, bow], pack: { snowpack, crust }, locks, struck: { 'zone:siteId': hourAbs }, said: [≤16] }`; Serbest Gez `roam.weather` aynı biçimdedir.

**Menü kimliği.** `app:state` → `menu`, `newgame`, `creator`, `home`: hava 1,7 sn'de kimliğe karışır, sonunda değerler tam yazılır; menü listesi havasızdır; `drawMenuFrame` hava durumunu saklar, `identity(0)` çağırır, sonra geri yükler (§6.3). Panel `__tanhu.weather`: `state, set, clear, plan, seed, skip, wind, wet, freeze, calm, flash, thunder, hail, strike, fx, sim, calibrate, budget, identity`.

### 3.25 Emek yasası ve şantiye (K21; `game/labour.js`, `game/site-core.js` saf; `game/sites.js`, `game/builders.js`)

Kurallar ve sayılar `d2/core.md` §2 (birleşene dek `d2/labour.md`), adım tabloları `structures.md`. **Birim:** İD (iş dakikası) bir işçinin bir oyun dakikalık emeğidir; 60 İD = 1 İS; 1.440 İD = 1 İG = tek işçiyle 60 gerçek dk. **Ekip:** `eff(W) = min(W, 10 · (1 − 0,9^W))`, `W` adımın el sınırına dek en ağır üyelerin ağırlık toplamıdır (usta ve el 1, çırak 0,75, yaşlı 0,5 (kendi zanaatında önder), Çocuk 0,5; adlı büyük usta ≤1,25). Standart (parça biçimli) yurt tek elle 1.440 İD, ekiple 1.376 İD; tek el yöntemi yalnız tündüktedir (bakanla ×1,6). Yurt süresi el sayısıyla: 1 → 60,0, 2 → 30,6, 3 → 21,7, 4 → 17,3, 5 → 14,7, 6 → 13,0, 7 → 11,9, 8 → 11,2 gerçek dk; el arttıkça süre hep kısalır.

```js
// game/labour.js (saf): sayılar d2/labour-model.json ile aynı (sınama karşılaştırır)
export const LABOUR = Object.freeze({
  DAY: 1440, REAL_S_PER_MIN: 2.5, B: 0.9, SITE_MAX: 8, NO_USTA: 0.7, LEAD_W: 0.75,
  ROLE_W: { usta: 1, hand: 1, apprentice: 0.75, elder: 0.5, child: 0.5 }, MASTER_W_MAX: 1.25,
  NIGHT: { lit: 1, day: 1, dim: 0.7, dark: 0.4, torchDarkHours: 4, fireLightPad: 4 },
  FED: { ok: 1, low: 0.85, hungry: 0.7, lowBelow: 35, hungryBelow: 15 },
  REPAIR: { raise: 0.8, patch: 0.6, burnt: 1.25, rerun: 0.8, tearStitch: 4 },  DISMANTLE: 0.35,
  HAUL: { vLoaded: 1.4, vEmpty: 1.9, handleS: 8, cap: { adult: 20, apprentice: 14, child: 6 }, selfR: 150 },
  QUICK_RAISE: 1 / 0.7,
});
export function eff(W);                                   // min(W, 10 · (1 − 0,9^W))
export function crewOn(step, members, out);               // adımın max'ına dek en ağır üyeler → out { heads, W, lead, usta, mete }
export function stepRate(step, crew, env);                // → İD / oyun dk = eff(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × hız / solo
export function weatherK(step, typeId);                   // → { k, hold: null | 'felt' | 'tall' | 'all', reason } (d2/core.md §2.8)
export function nightK(cls);                              // daylight.nightClass: 'lit' | 'day' 1, 'dim' 0,7, 'dark' 0,4
export function remaining(state);  export function etaMinutes(state, members, envAt);   // → oyun dk
export function simulate(state, minutes, { membersAt, envAt, stockAt });   // saat dilimli toplu benzetim → { wm, events }
export function haulTrip(d, carrier);  export function haulWork(load, d, carrier);       // gerçek sn; İD = sefer × sefer_sn / 2,5
export function dayCapacity(job, dayInfo, lit, nightOrder);   // → İS / işçi / gün; job 'build' (ışıkta 24) | 'produce' (16 saatlik pencere, ışığa göre) | 'herd' (24)
export function etaWords(nowMin, etaMin);                 // → { dayKey, timeKey }: «Yarın öğlende biter» / «Done tomorrow at midday»

// game/site-core.js (saf)
export function validatePlacement(def, place, { nav, height, normalAt, nodes, structures, roads, rules = null });   // → { ok, reasons: [≤3] }; rules: settlement PLACEMENT
export class SiteCore {
  constructor(def, place, { zone, stock /* Container (§3.26), cap = malzeme yükü × 1,25 */, orders });
  stock;  crew;  orders;  wait;  contrib;  lastMin;
  deliver(item, n, who);  needFor(step);  consume(step);   // adım başlarken cost yığından adıma geçer; eksikse wait 'material'
  waitReason(env);                 // öncelik sırasıyla tek neden: 'fire' | 'threat' | 'storm' | 'weather' | 'material' | 'far' | 'crew' | 'dark' | 'rest' | 'story' | null
  toJSON();  fromJSON(o);
}

// game/sites.js: GameSystem { id: 'sites', order: 61, modes: ['freeroam', 'play', 'home'] }; ctx.sites
export class SiteSystem {
  attach(ctx);  onWorld(world, nav);   // spec.sites (senaryo şantiyeleri), spec.labour; world.sites bloğundan bu zonun şantiyeleri
  beginPlacement(kind, { preset, onDone });  place(kind, opts);   // → ConstructionSite; iz önizlemesi Game.marker programıyla (yeni program yok)
  get(id);  list({ zone } = {});  status(id);   // status → { name, step, units, heads, W, etaMin, wait, solo, rev }
  assign(siteId, workerIds);  release(workerId);  order(siteId, { night /* 'work' | 'rest' */, priority /* 0–3 */, dismantle });
  deliver(siteId, item, n, who);
  update(dt, t);                   // görünen ve uzak şantiyelerde emek; oran ≤4 Hz yenilenir; ekip görünümü 40 m içinde ≤8 Folk / şantiye
  onSkip(fromMin, toMin);          // clock:skip: yalnız spec.settlement taşımayan zonda labour.simulate
  simulate(siteId, minutes, env);  // yerleşimin catchUp'ı çağırır (yerleşimli zonda atlamanın tek sahibi yerleşimdir)
  catchUp(minutes);                // dünyaya dönüş
  collectInteractions(q, out);     // Teslim Et / Deliver, Çalış / Work, Ekip / Crew, Sök / Dismantle
  toJSON();  fromJSON(o);          // world.sites (76)
}
ConstructionSite = { id, kind, preset, zone, place: [x, z, rot, y0], structure /* StagedStructure | null (uzakta) */, core /* SiteCore */ };
// BuilderSystem (camp3) status ek alanları: heads, W, etaMin, wait, solo; CHILD_HELP, SHELTER, öğün sırası, «aile bekler» (§3.11)
```

**Çarpanlar.** `K_usta`: yapının zanaatından (`home`, `wood`, `earth`) usta yoksa ×0,7; her yetişkin `home` ustasıdır; ekipte ağırlığı ≥0,75 ya da usta sayılan biri yoksa iş ilerlemez. `K_gece`: `nightClass` (meşale direği karanlığın 4 saatinde 1 `torch` yakar; ana kampta ve senaryo şantiyesinde `spec.labour.torchFree`). `K_tok`: bağlı defterin `food` çizgisi ≥35 → 1, <35 → 0,85, <15 → 0,7 (Kışlak'ta 1'e iğneli). `K_beceri`: Mete'nin `quick_raise` (×1/0,7 ve +1 el), `repair` (onarım emeği ×0,5, malzeme ¼).

**Gece ve günlük emek.** İnşaatın varsayılanı «Gece de çalışılsın» / «Work through the night»dır: ekip ışıkta bitene dek sürer, bedeli meşaledir, Gönül bedeli yoktur. «Gece dinlenilsin» / «Rest at night» ekibi üretim penceresine çeker (ana kamp 06:00–22:00, Kışlak 07:00–23:00, yerleşim ve ordugâh yazın 05:30–21:30, kışın 07:00–23:00). Üretim ve ev işi 16 saatlik penceredir, ışığa göre sayılır; çobanlık 24 saattir; hane ≈44 İS/gün. Tek işlev `dayCapacity`'dir.

**Hava durağı** (`d2/core.md` §2.8): genel çarpan açık 1, yağmur 0,85, sağanak ve gök gürültülü fırtına 0,5, yoğun kar 0,7; keçe adımı yağmurda 0,7, sağanakta 0. Durak `felt` ya da `tall`: ekip yerinde kalır, o adım bekler, sonraki adımın yığınını hazırlar (`tall`'da bakandan 6 m çekilir); `all` (dolu, tipi, Kara Boran, toz) ya da hiçbir adım ilerleyemiyorsa `SHELTER`; adımın çarpanı 0,25 oyun saati işe izin verince döner. Ustalar `weather.md` §8.12'nin genel NPC sığınmasına değil bu tabloya uyar.

**Oyuncu.** Mete şantiyede «Çalış / Work» ile 1 ağırlıkla ve emek becerileriyle girer (atlama: Çalış tekeri, §3.23). Çocuk «Ustalara Katıl (yarım el)» / «Join the Builders (half a hand)» ile adımın fiilini yaptıkça 0,5 ağırlık ve bir baştır; «Kendiliğinden / Auto» isteğe bağlıdır; ayak işleri `help_log`, `help_ember`, `help_water`; `y_esik` ve `y_ocak`'ta yuva açılmaz.

**Parça ve ham teslim.** Standart yurt parça biçimlidir (89 Yük); şantiyeye ham mal gelirse parçanın zanaat emeği adıma eklenir (`rawWork`: bosağa 360, kerege 720 (`rawRole: 'cr_carpenter'`: usta yoksa ham pay işlemez, adım «Usta gerek» bekler), uuk 480, çiy 120 İD; toplam 28 İS; ham yurt tek işçiyle 3.120 İD). I. Perde ve ana kamp şantiyeleri `spec.labour.rawWork: false` taşır (yurt 1.440 İD). Tündük her biçimde parçadır.

**Taşıma ve söküm.** `sefer_sn = d/1,9 + d/1,4 + 8`, `sefer = ceil(yük / tavan)`; ustalar 150 m'ye dek bağlı ambardan kendi taşır, ötesi «Malzeme uzakta» / «The materials are far away». Söküm adımları tersten, kurmanın 0,35'i; yurt yurt yüküne döner.

**Kayıt.** `world.sites` (76): `{ v: 1, zones: { [zone]: { lastMin, sites: { [id]: tam kayıt | ['yurt', x, z, rot, 'done'] } } } }`; şantiye ≤3 KB, bütün zonlarda ≤20 KB; Kışlak Yeni Yurdu `world.sites.zones.hexi_winter.sites.new_yurt`'tür. Serbest Gez camp3 `v: 2` (`labour.md` §14). Panel `__tanhu.labour`: `eff, rate, eta, crew, simulate, weather, night, sandbox`.

### 3.26 Eşya, kaplar, zanaat ve tezgâh (K24; `game/container.js`, `game/craft.js`, `game/herds.js`, `game/loot.js`, `game/supply.js`, `data/*` saf)

Kurallar ve sayılar `d2/core.md` §5 (birleşene dek `d2/economy.md`). Ekonomi yalnız saf servis verir; onları süren sistemler başka alanlarınındır (yerleşim, şantiye, saat). K24 `EconomySystem`, `Stores`, `Herd`, `Caravan` sınıfı yoktur. **Taksonomi:** `raw` Ham, `proc` İşlenmiş, `part` Parça, `fin` Mamul, `bundle` Bohça (`yurt_kit` 59 Yük, `tent_kit`); sürü kaba girmeyen sayıdır. Kalite yalnız teçhizattadır: İnce İş `id+` (emek ×1,5, +1 asıl malzeme, ana değer ×1,1, Kıymet ×1,5).

```js
// game/container.js (saf): bütün kaplar; §3.13 kap yüzü { add, remove, list, load(), cap } (Yük); içeride onda bir tamsayı
export class Container {
  constructor({ id, kind, cap10, slots = 0, accept = null /* (id) → boolean */, owner = null, hidden = false });
  id;  kind;  owner;  hidden;  cap10;  get cap();
  load();  load10();  free10();  count(ref);  has(ref, n = 1);  list();      // list → [{ id, n }]
  canTake(id, n);                  // → alınabilir en çok adet: Yük, yuva (yalnız Heybe), kabul süzgeci
  add(id, n, { day, allowOver = false });   // → { added, rest }; çiğ et ve balıkta hikâye günü anahtarı
  remove(ref, n);                  // → [{ id, n }]; etiket kabul eder; önce eski gün
  onDawn(day, { perishFish = true });       // → [{ id, n }] bozulan: edinildiği günden sonraki ikinci şafakta çiğ et (ve kış dünyası dışında balık) spoiled
  toJSON();  fromJSON(o);
}
export function transfer(from, to, ref, n);                         // → { moved, rest }; olay yaymaz (çağıran item:move yayar)
export function transferAll(from, to, list = null, { filter = null } = {});   // → { moved: [{ id, n }], rest: [{ id, n }] }

// game/craft.js (saf): tarif çözümü ve tezgâh; Workshop'ları yerleşimin production.js'i sürer
export function canCraft(recipe, { inv, station, role, skills });   // → { ok, missing: [{ id, n } | { role } | { station }] }
export function craftHand(recipe, inv);                             // el işi, tutuş bitince (≤8 sn) → { out, xp }
export class Workshop {
  constructor({ id, station, slots, crewMax });
  queue;  cures;  crew;            // crew { W, roles } (Kâhya yazar)
  order(recipeId, n, { fine = false, night = false });  cancel(i);   // night: üretim gece vardiyası (hane Gönül'ü gece başına −0,2, meşale)
  tick(gameMin, { crewW, lit, weather, pool, day });   // labour.eff(W); İS akar; açık bekleme yuvası yağışta durur; çıktı pool'da kabul eden en yakın kaba
  toJSON();  fromJSON(o);
}
// data/stations.js (saf): STATIONS[id] = { tr, en, structure: kind | null, crewMax, cureSlots, open }; 11 tezgâh: hand, hearth, felt_yard,
//   tannery, wood_shop, smithy, kiln, fletchery, kitchen (kazanlı yurt ocağı, yapı değil), stable, drying_rack
// ROLES[id] = { tr, en, station, craft: 'home' | 'wood' | 'earth' }; 9 rol: cr_felter, cr_tanner, cr_carpenter, cr_cartwright, cr_smith,
//   cr_bowyer, cr_saddler, cr_cook, cr_earth. Ustası olmayan usta tarifi işlemez (parçada kalite yok)
// data/craft-recipes.js (saf): RECIPES[id] = { station, role: id | null, in: { [ref]: n }, out: { [id]: n }, wh /* İS */, holdS, cureH, act, fine }

// game/herds.js (saf): data/herd-kinds.js; sayılar SettlementState'tedir, hesap buradadır
export function herdDay(counts, season, { deepSnow, crust, fodder, pasture });   // → { yields, labourIS, fodderUse, losses }
export function herdEvent(counts, name, season);   // 'shear' | 'comb' | 'births' | 'sogum' → { yields, counts }

// game/loot.js (saf): data/loot-tables.js; ganimet düşman türüne göre belirlidir, rastgele çekiliş yok
export function of(enemyKind, counters);           // → [{ id, n } | { herd, n }]; kesirli pay counters[enemyKind]'da birikir; insan yok (K23)
export function booty(defeated, { recovery = 0.6, share /* 'share' %25 | 'keep' %75 */, counters });   // birim ganimeti; adlı silah sahnelere elle konur

// game/supply.js (saf): economy.md §7; d2/economy.md §7
export class SupplyLedger {
  constructor(id, { mode = 'abstract', fuel, food, fodder, pool = null, need = null });
  // abstract: Kış Hesabı aynen (yüzde, şafak kaybı). store: çizgi = min(100, gün ÷ hedef × 100); hedef yiyecek 30, yakacak 30, yem kışın 100 gün; pool: StorePool
  value(line);  add(line, n);  onDawn(loss);  freezeToy();
  consume(day, season);            // store: hane payı, Ordu Payı, yakacak, kış yemi; önce bozulacak et kazana
  toJSON();  fromJSON(o);
}
export const LEDGERS;              // ctx.supply: { get(id), register(ledger), bind(bus, { diff }) }; bind: 'dawn' ve clock:skip'te soyut defterlere onDawn(diff.ledgerLoss) × dawns
export function ledger(id);        // LEDGERS.get: 'winter_camp', 'own_seat' (yerleşim), 'own_camp' (ana ordugâh), 'field_camp' (sefer)
export function armyShare(residentRiders, { movingK = 1, winter = false } = {});   // öğün/gün = yerleşik atlı × 0,1 (Göçer ×1,1; kış dağılması ×0,1)
export function rolloverYears(state, years, { capacity, targets });   // Kronik'in kapalı yıl adımı: sürü, bozulma, saklananın sınırı, bakım (K25)
```

**Kaplar** (`d2/core.md` §5.6; sınır Yük):

| Kap | Sınır | Kabul | Kaydın sahibi |
|---|---|---|---|
| Heybe, Terki, Yük Kızağı, sandık, Menzil Ambarı, Zula | `loadMax`; binek Yük'ü (Yakve 40, Adak Aygırı 50, yedek at 30, `hun_pony` 40); +12; 60; 40; 6 × 6 | Hepsi (kızak `tag:bulk`) | `economy` (41) |
| Araba | 40 / 60 / 80 / 140; `wagon_felt` 120, öküz arabası 60, yük devesi 30 | Hepsi | `economy` ya da kervan (`settlement`) |
| Ambar Yurdu, Sundurma, Tahıl Ambarı / Kulesi, Ambar Çukuru, Hazine | 400; 500; 600 / 800; 120; 120 | Hepsi; `bulk`, `forage`, `fodder`; `food`, `grain`; `food`, `grain`; `valuable` | `settlement` (77) |
| Silahlık, Erzak Ambarı (ordugâh) | 200; 600 | `gear`, `arrow`, `metal`; hepsi | `camps` (92) |
| Şantiye yığını | Yapının malzeme yükü × 1,25 | O yapının malzemesi | `world.sites` (76) |

Bir yerin kapları yerleşimin `StorePool`'unda tek **Ambar / Store** görünümünde birleşir. Kervan ve Mete'nin heybesi dışında yerler arası taşıma yoktur. Bozulma: çiğ et ve balık edinildiği günden sonraki ikinci şafakta `spoiled` (24–48 sa), kış dünyasında balık donuktur (`spec.perish`).

**İki hız.** Mete toplamada ve el işinde gerçek saniyeyle (odun 6, taş 10, cevher 15 sn; tutuş ≤8 sn) çalışır, NPC İS ile (kütük 2,5, ot 1,5, cevher 5 İS); tezgâh ve usta işi herkes için İS'tir. Zanaat ve inşa tek emek havuzundan ödenir.

**Sürücüler.**

| Sürücü | Ne zaman | Servis |
|---|---|---|
| `Inventory` (8.2) | `dawn` | Kişisel kapların `onDawn`'ı |
| `barter.js` (8.4) | `dawn` | Satıcı stoğu |
| `LEDGERS.bind` (8.4) | `dawn`, `clock:skip` | Soyut defterlerin şafak kaybı |
| `SettlementSystem` (§3.27) | `clock:hour`, `dawn`, `clock:skip`, `act:change` | `Workshop.tick`, `herdDay`, `herdEvent`, `SupplyLedger.consume`, `StorePool` kaplarının `onDawn`'ı, `rolloverYears` |
| `CaravanBook` (§3.27) | Kalkış, varış | `transferAll`, `armyShare`, `rationOf` |
| `SiteSystem` (§3.25) | Teslim | Şantiye yığını (`Container`), bohça açma, `matches` |
| Savaş (`combat`, `army`) | Düşman düşünce, akından sonra | `loot.of`, `booty` |

**Panel.** `__tanhu.econ` ekleri: `put(id, n, containerId)`, `perish()`, `craft(recipeId, n)`, `loot(enemyKind, n)`; yerleşim ambarı, sürü ve kervan `__tanhu.hold`'dadır.

### 3.27 Yerleşim ve ordugâh (K23; `data/settlement.js`, `game/settlement/*` saf; `game/settlement/index.js`, `game/settlement/plan.js`, `world/settlement-view.js`)

Kurallar ve sayılar `settlement.md`, kesişenler `d2/core.md` §4. Açılış II. Perde'dir (K23: `mq2_allotment` sineması K7 `home` sahnesinin devamıdır; Mete'nin denetimi atlas bacağında başlar; ana kampta Mete oynanmaz, K6). I. Perde altyapıyı ve kum havuzunu kurar. Yerleşim sürücüdür: K24'ün saf servislerini saatle sürer.

| Yer | Defter ve kimlik | Zon | TR / EN |
|---|---|---|---|
| Yerleşim | `own_seat` | `tanhu_ordu` (112,8; 43,5) | Yurt / Hold («Yurdun / Your Hold») |
| Ana ordugâh | `own_camp` | `whistle_field` (106,6; 44,2) | Ana Ordugâh / Home Encampment |
| Sefer ordugâhı | `field_camp` | Sefer iç haritasının `campSites`'ı | Sefer Ordugâhı / Field Camp |
| I. Perde kışlağı | `winter_camp` | `hexi_winter` | Kış Hesabı (soyut defter) |

Kademeler `ocak` (II, tavan 6), `oba` (II, 12), `boy_yurdu` (III, 25), `toy_yeri` (IV, 50), `tanhu_avlusu` (V–VI, 90; V'te Surlu ya da Göçer Avlu); kademe düşmez. Ordugâh kademeleri `camp_onluk`, `camp_yuzluk`, `camp_binlik`, `camp_tumen`; yerleşik atlı 10 / 100 / 200–400 / 600.

```js
// data/settlement.js (saf): d2/settlement-model.json v2 ile aynı sayılar
export const PLACES;      // own_seat, own_camp, field_camp (+ winter_camp): { zone, kind, ledger }
export const TIERS;       // { id, n, act, cap, pullBase, needs, opens }
export const BUILDINGS;   // kind → { preset, tier, plot, store: { cap, accept } | null, station, upkeep, bom, labour /* İG, labour-model.json */ }
export const SOURCES;     // hane kaynakları ve perde dalgaları: hh_story, hh_saved, oba_wave, court_move, choose, refugees, gift, loufan_baiyang, defectors, heqin, muster_winter, kurultay
export const PLACEMENT;   // parseller ve yer kuralları: validatePlacement'in rules girdisi (settlement.md §13)
export const CAMP_TIERS;  // { id, riders, tents, lines, builds }
export const RAIDS;       // perde başına tehdit (II —, III 8 günde 1, IV 14, V 12, VI —) ve güç R

// game/settlement/state.js (saf)
export class SettlementState {
  constructor({ data, econ /* K24 tabloları */, labour /* game/labour.js */, rng });
  zone; tier; path; households; work; pull; lastMin; stores /* StorePool */; herds /* { [place]: { sheep, goat, horse, cattle, camel } } */; taken;
  hour(env);  dawn(env);  seasonEnd(env);          // env: { minute, phase, season, weather, act, kut, korku, threat, present }
  catchUp(toMin, envAt, sites);    // ≤3 gün saat saat, uzunu günlük adım; her şantiye için sites.simulate(siteId, dk, env)
  chronicle(fromDayN, toDayN, k24);   // Kronik (chronicle.js)
  tierCheck(act, built);           // → { tier, missing }
  join(src, n, opts);  leave(id, reason);  levy(householdId, unitId);  returnLevy(unitId);
  workers();                       // → [{ id, role, w, crafts, job }]
  assign(job, target, n);  lock(job, min, max);  setAuto(on);
  toJSON();  fromJSON(o);          // settlement (77), ≤14 KB
}
// households.js (saf): pullDawn(state, env): Çekim yalnız önceki gün Mete yerleşimde ya da ordugâhta ≥1 oyun saati uyanıksa, perde tavanıyla;
//   wave(state, src); chooseDefeated(state, battle): yenilenlerin seçimi; esir yoktur, join ganimet yolundan çağrılamaz
// steward.js (saf): assign(state, env) → { sites: [[siteId, ids]], workshops: [[wsId, W]], herd, gather: [[cluster, n]], guard, haul };
//   sıra: sürü > nöbet > yiyecek > yem > yakacak > inşa > zanaat > sürücü; oyuncunun kilidi önce gelir; yaşlı sürüye ve nöbete atanmaz
// stores.js (saf)
export class StorePool {
  add(container, { place, at });  remove(id);  get(id);  ofPlace(place);
  accept(id, n, { place, near });  // → kabul eden en yakın boş kap | null
  put(id, n, { place, day });      // → { added, rest }
  take(ref, n, { place });  count(ref, { place });  days(line, need, { place });
  toJSON();  fromJSON(o);          // settlement.stores: kap başına içerik
}
// production.js (saf): hour(state, env, k24): Workshop.tick, toplama kolu (applyTaken sayacı); dawn(state, env, k24): SupplyLedger.consume,
//   herdDay, kapların onDawn'ı; season(state, env): kırkım, doğum, soğum, bakım (10 günde bir orantılı)
// caravans.js (saf)
export class CaravanBook {
  order(o);  cancel(id);           // o: { id, from, to, every, send, back, escort, road } (settlement.md §11.2)
  hour(env);                       // Tan'da kalkış; fx.cartLock'ta ≤6 sa bekler, sonra ertesi Tan; yol günü ÷ ortalama fx.cartK; III'ten akın
  trips();  inTransit;             // [{ id, dep, arr, load }]
  toJSON();  fromJSON(o);
}
// raids.js (saf): threat(act, zone); resolve(state, env, rng) → { success, losses }; tek kural (aşağıda)
// camps.js (saf)
export class CampState {
  place; tier; residents; plan /* CampPlan */; depot /* Container: Erzak Ambarı */; winter; comfort;
  hour(env);  dawn(env);           // tayın, ateş, barınak payı, Baş Talimi, kış dağılması
  toJSON();  fromJSON(o);          // camps (92), ≤4 KB
}
CampPlan = { site, units, tents, seed, fires, lines, depot: 'carts' | id, palisade, doneAt };   // army.md cmd_camp; çadırlar tek tek yazılmaz
// court.js (saf): Court { council(action, args); assemblies(calendar); omen(strike, axes); treasury; toJSON(); fromJSON(o) }
// chronicle.js (saf): chronicle(state, fromDayN, toDayN, k24) → { years, households, herd, storesPct, card }   // ≤150 ms / mevsim

// game/settlement/index.js: GameSystem { id: 'settlement', order: 64, modes: ['play'] }; ctx.settlement (9.9)
export class SettlementSystem {
  attach(ctx);                     // bus: clock:hour, dawn, clock:skip, act:change, structure:done, site:done, site:dismantled; bloklar settlement (77), camps (92)
  onWorld(world, nav);             // spec.settlement varsa görünüm, Plan Kipi ve etkileşimler; yoksa yalnız saat işi
  update(dt, t);                   // görünür işçi ve sürü konumu (sürü y 5 Hz); Plan Kipi
  collectInteractions(q, out);     // Ambara Koy / Store, Ambardan Al / Take, Divan / Council, Güne Selam / Greet the Sun, Toy Ver / Hold a Feast
  openPlan();  closePlan();
  hold;  camps;  caravans();       // SettlementState (own_seat); { own_camp, field_camp } CampState; CaravanBook.inTransit
  debug();
}
// game/settlement/plan.js: PlanMode: 'plan' bağlamı (modal değil, §3.2); kamera game.cam.push('plan', { pitch: 50, dist: 64 }) (40–120);
//   önizleme sites.beginPlacement (Game.marker + KitField örneğinde renk uniform'u: plan_ghost programı yok); validatePlacement(…, { rules: PLACEMENT });
//   çizgiler (ağıl, çit, at hattı, sur) sürükleyerek, parça yakalama; yerleşince sites.place; Sök sites.order(id, { dismantle: true })
// world/settlement-view.js: SettlementView { constructor(world, spec); yurtField; kitField; plots; herds; update(cam, dt); ghost(kind, state); dispose() }
//   YurtField: closed ağın örnekleri (aCut, aChar), >220 m kubbe; KitField: tek BatchedMesh; 1 + 1 çizim, gölgeleriyle 4; sürü örnekli ≤300
```

**Saat sırası.** `clock:hour`: (1) `SettlementState.hour` (Kâhya ekipleri yazar), (2) K21 `sites` şantiyenin o saatini işler (yüklü dünyada zaten kare kare işledi), (3) `production.hour`, (4) `CampState.hour`, (5) `CaravanBook.hour`. `dawn`: `production.dawn`, sonra `SettlementState.dawn` (Çekim, katılım, ayrılış, Gönül, kademe). `clock:skip`: aynı sıra, ≤3 gün saat saat, uzunu günlük adım. `act:change`: Kronik: tarih perde başına atlar (`clock:skip { reason: 'chronicle', long: true }`), aradaki yıllar `rolloverYears` ile kapalı işlenir, hane perdenin açılış tabanına çıkar (düşmez), kış stoğu ambar kapasitesiyle sınırlı K24 hedefine dek, yoldaki kervan varmış, şantiye emeği yetiyorsa bitmiş sayılır; perde kartı: «{y} yıl geçti. {h} hane, {s} baş sürü; ambar kışa {p}.» / «{y} years have passed. {h} households, {s} head of stock; the stores stand at {p} for winter.»

**Ordu Payı ve kış.** Ordu Payı yerleşik atlının düz %10'udur (1 / 10 / 20 / 40 / 60 öğün/gün; Göçer ×1,1 = 66); yalnız kuru erzak (Aş, darı, kak, kurut, tahıl) kervanla gider. Kışın ordugâh dağılır: yerleşik atlının %90'ı hanesinin kışlağına çekilir, %10'luk kış bekçisi at hattında ordugâhın güzde biçtiği otu yer (at başına günde 1 Yem Bağı = 2 Yük).

**Baskın, tek kural.** `D = nöbetçi × (1 + 0,5 × kule) + garnizon`; başarı `R / (R + D) × (Surlu ? 0,5 : 1)`; başarılı akında Ambar Yurdu, Tahıl Ambarı, Sundurma %30, Tahıl Kulesi %10, Hazine %30 (30 m içinde Gözcü Kulesi ×0,5), Ambar Çukuru %50 olasılıkla bulunur ve bulunursa %30 (yalnız yiyecek ve tahıl), ot sundurması tutuşursa hepsi; sürü kaybı ≤%10 (Göçer ×0,6). Mete zondaysa baskın oynanır (`raid.js`), değilse toplu çözülür.

**Görünür bütçe.** Zon başına ≤160 yapı kaydı (çizgi yapılar çoklu çizgi ve parça sayısıyla tek kayıt), aynı anda ≤48 canlı `StagedStructure`, ≤4 tam yurt 40 m içinde, gerisi `YurtField` ve `KitField`; görünür işçi `NpcManager.budget`'ını paylaşır. Panel `__tanhu.hold`: `give, households, tier, speed (×1–×240), hour, place, assign, steward, raid, weather, caravan, census, budget, plots, synth(tier, path)`.
~~~

## 6. §5 Uygulama fazları

Faz 7 aynen kalır. Faz 8 ve Faz 9 tablosu bütünüyle yenilenir (paket ayrıklığı aşağıda denetlendi), Faz 10–12 satır satır değişir, Faz 13 eklenir. K11 kapısı yerindedir: Faz 10 sonu.

### M50. «Okuma»: bağımlılık

**Bul:**
~~~
F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → kapı → F11 → F12
~~~
**Yerine:**
~~~
F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → kapı → F11 → F12 → F13
~~~

### M51. Faz 8

**Aralık:** aşağıdaki başlığın altındaki ilk dolu satırdan sonraki çapa satırına dek (o satır dahil) metnin tamamı.

**Aralık başı:**
~~~
### Faz 8: Oyuncu çekirdeği ve ekonomi
~~~
**Aralık sonu (dahil):**
~~~
**Çıkış:** Deneme sahnesinde toplama, zanaat, ateş, yemek, av, dövüş, seviye ekranı.
~~~
**Yerine:**
~~~
İstek 7, 12; K20–K24. Sistemler Serbest Gez'de küçük döngüyle, `?state=play` deneme sahnesinde ve `?sandbox=site` kum havuzunda tam sınanır. Saat, hava çekirdeği, emek yasası (Faz 6 yeniden işleme), şantiye, yerleşim çekirdeği ve ekonomi servisleri bu fazdadır; hikâye açılışı II. Perde'dedir (K23, Faz 13). Hava görünümü 9.4'e dek kimliktir.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 8.1 | `src/game/derive.js`, `src/data/skills.js`, `src/data/mod-readers.js`, `src/i18n/strings/skills.js`, `test/derive.test.js` | §3.13; 93 beceri; `env.wetBow` (0,25 basamak), `env.blizzard`, binek yükü `mountLoadK` (`d2/economy.md` §5.4); emek becerileri (`quick_raise`, `repair`) `labour.js` için `mods`'ta | `progression.md` §2.4 tablosu; §17.1 #2, #4–#7, #14, #25–#27; `wetBow` 1'de ok hasarı −%15 |
| 8.2 | `src/game/items.js`, `src/data/items.js`, `src/data/gear.js`, `src/game/inventory.js`, `src/game/container.js`, `src/i18n/strings/items.js`, `test/inventory.test.js`, `test/container.test.js` | `economy.md` §2, §4; §3.13, §3.26: taksonomi, 23 yeni kimlik, `baseId`, `Container`, `transfer`, `transferAll`, gün anahtarlı bozulma, kap çözücü (`site`, `store`, `pool`), Terki, `economy` v2 | `speedK` .85, .7; el koyma istisnaları; `d2/economy.md` §17 #1–#7; I. Perde yurdu 54 birim, 146 Yük |
| 8.3 | `src/world/node-store.js`, `src/world/nodes.js`, `src/data/node-kinds.js`, `src/game/gather.js`, `src/game/strike-ring.js`, `src/character/gestures/labour.js`, `src/i18n/strings/economy.js`, `test/node-store.test.js`, `test/gather.test.js` | §3.12; `applyTaken`; `node_camp_logs`; düğümün `weather` alanı ve yığının `wet` biti; `onDawn` `dawn` olayına, atlamada şafak başına bir; jestler `carry('haul')`, `cover_head` (`weather.md` §8.15) | 3.270 kayıt; `nodeStats`; `applyTaken` belirlenimli |
| 8.4 | `src/game/needs.js`, `src/game/craft.js`, `src/data/craft-recipes.js`, `src/data/stations.js`, `src/game/supply.js`, `src/game/barter.js`, `src/game/herds.js`, `src/data/herd-kinds.js`, `src/game/loot.js`, `src/data/loot-tables.js`, `src/audio/sfx/economy.js`, `test/needs.test.js`, `test/craft.test.js`, `test/supply.test.js`, `test/herds.test.js`, `test/loot.test.js` | `economy.md` §5–§9; §3.26: tarif, `Workshop`, 11 tezgâh, 9 rol, `SupplyLedger` ambar kipi, `LEDGERS` (`ctx.supply`), `armyShare`, `rolloverYears`, `herdDay`, `loot.of`; Tokluk oyun dakikasıyla; ekonomi reçeteleri | `economy.md` §7 senaryo tablosu (Kış Hesabı teslimleri birebir); `d2/economy.md` §17 #8–#14 (`armyShare` düz %10: 10 → 1, 100 → 10, 600 → 60, Göçer 66, kışın ×0,1; `loot.of` belirli); ekonomi alanının K24 resmî koşusundan sonra (aşağıdaki önkoşul) `node tools/econ-sim.mjs --strict` 0 işaret; repodaki bugünkü 0 işaret K24 öncesi hedeflere göredir ve sayılmaz; `data/*` ile K24 `d2/econ-model.json` aynı sayılar (`check-data`, 8.14; adlı silah ganimet verisine girmez, K24); Tokluk Son Gece ×1,2; Kış Hesabı `a1_last_night` açıkken şafakta düşmez |
| 8.5 | `src/game/campfire.js`, `src/game/cooking.js`, `src/data/recipes.js`, `src/ui/cook-wheel.js`, `src/ui/css/cook-wheel.css`, `src/i18n/strings/survival.js`, `test/cooking.test.js` | `survival.md` §2–§3; ateş ve pişirmenin hava tablosu (`fx.fireK`, `fireOutS`, `fireRing`, `dryK`; `weather.md` §8.5); `onSkip`, `cold_pit` ertesi şafakta; Dinlen tekerini `ClockSystem` açar | Tek paylaşılan ışık; ≤6 ateş; yağmurda taşsız ateş ×1,5; fırtınada taşsız ateş 40 sn'de söner |
| 8.6 | `src/game/agent.js`, `src/game/agent-move.js`, `src/game/fauna.js`, `src/game/hunting.js`, `src/character/animal.js`, `src/data/fauna-kinds.js`, `test/agent-move.test.js` | §3.16 taban; `survival.md` §4; evre takımı (`time.md` §9.9; ana kampta `CampLife` ister, K3 ≤6), iz ve koku hava çarpanı (`fx.trackK`, `scentK`, rüzgâr), tuzak zarı 00/06/12/18 | Karga, tavşan Çocukla; mandal testi; kampta hayvan ≤6 her evrede |
| 8.7 | `src/ui/pack.js`, `src/ui/ledger.js`, `src/ui/barter.js`, `src/ui/glyphs.js`, `src/ui/transfer.js`, `src/ui/css/pack.css`, `src/ui/css/ledger.css`, `src/ui/css/transfer.css`, `src/ui/hud/needs.js`, `src/ui/hud/gain.js`, `src/ui/hud/bar.js` | `progression.md` §14.1, `economy.md` §4.2, `d2/economy.md` §5.2: Heybe (Terki sekmesi), aktarma paneli (`transfer` bağlamı), Defter'in yapı sayfası (`ctx.sites.list()`) | `pause` sayfaları dolu; aktarma paneli TR ve EN; «Eksikleri Al» şantiyenin eksiğini alır |
| 8.8 | `src/game/player.js`, `src/game/mounts.js`, `src/game/child.js`, `src/data/enemies.js`, `src/app/states/play.js`, `test/player.test.js` | Yara, Düşüş (uyanış +2 oyun saati), `moveMods`; dolu ve beden (`weather.md` §8.17); Çocuk küçük döngü, ateş ziyareti `CampLife`'tan, hava tepkileri (§8.15); `play` iskeleti, `?state=play` deneme sahnesi; `play.enter` `hud.vitals.setName` ve gerçek `stats.hp`, `hpMax` yazar | camp3 katılması Çocukla (fiil yaptıkça yarım el); iri dolu Can tabanı %40, Yara yok |
| 8.9 | `src/game/world-clock.js`, `src/game/daylight.js`, `src/game/calendar.js`, `src/game/clock-system.js`, `src/game/camp-life.js`, `src/world/world.js`, `src/world/sky.js`, `src/world/specs/camp.js`, `src/core/keymap.js`, `src/core/settings-schema.js`, `src/game/save.js`, `src/audio/music-states.js`, `src/audio/sfx/time.js`, `src/ui/hud/clock.js`, `src/ui/wait-wheel.js`, `src/ui/css/wait.css`, `src/ui/menu/save-panel.js`, `src/i18n/strings/time.js`, `src/i18n/strings/save.js`, `test/world-clock.test.js`, `test/daylight.test.js`, `test/sky-keys.test.js`, `test/calendar.test.js` | K20, §3.23, `time.md`: dünya saati, gün ışığı, takvim, altı ışık durağı ve ışığın tek hattı (`lightBase`, kimlik `writeLight`, gölge kuralları, gece göğü, geriye uyum için `moodT`), `world.tallThings` alanı; Bekle, Uyu, Dinlen, Çalış tekeri; vakit ve bekleyiş; ana kamp programı (`CampLife`); Gök Kavisi; kayıt kartının evresi; kamp spec'inin `light`, `moods.cycle`, evre ortamları, `weather`, `labour` blokları; `wait` (`T`), `build_mode` (`P`); `camp_night`, dört saat reçetesi | `time.md` §17 node sınamaları; `menuDiff` 0 (taze, Serbest Gez 03:00'te, gece oturumundan sonra); yeni oturumun ilk karesi menü ışığında; saat taban üstüne 0 program; `clock.lapse(24)` bir şafak; 15 fps'de gün 60 ±1 dk; Serbest Gez en kötü gündüz karesi ≤509 çizim (9.4'ün havasına 2 pay; aşılırsa gündüz ikizi düşüşü 8.9'un `camp-life.js`'indedir, 9.4 o dosyaya dokunmaz) |
| 8.10 | `src/data/weather-types.js`, `src/data/climates.js`, `src/game/weather-core.js`, `src/game/weather.js`, `src/game/projectiles.js`, `src/game/mounted.js`, `src/i18n/strings/weather.js`, `test/weather-core.test.js`, `test/weather-fx.test.js`, `test/weather-strike.test.js` | K22, §3.24, `weather.md` §3–§8, §12: planlayıcı (sabit çapa, cephe, kilit, `pinFx`), ıslaklık, kar örtüsü ve Kar Kabuğu, `fx`, işaretler, alt olaylar, yıldırım seçimi, `weather.audio`, müziğin `rain` katmanı; ok sapması ve `predict`; atın rüzgârı ve gök gürültüsü ürkmesi | `weather.md` §15 W1–W11 ve W26 (üreteç sabit tohumla 150 kışı koşup `d2/weather-model.json`'ı yazar; sınama kural sırasını, I. Perde satırında kabuk 0'ı ve yalnız iki yerleşim ikliminde mutlak toleransı denetler: `steppe_south` derin kar 0,135 ±0,03, kabuk 0,63 ±0,3 / kış; `gobi` kabuk ≤0,05); dosya ekonomi alanının son `--strict` koşusundan önce yazılır; görünüm 9.4'e dek kimlik |
| 8.11 | `src/game/labour.js`, `src/world/structure-defs.js`, `src/world/structure-logic.js`, `src/world/structure.js`, `src/world/structure-shader.js`, `src/world/camp.js`, `src/game/builders.js`, `src/ui/hud/build-status.js`, `src/audio/sfx/structure.js`, `src/i18n/strings/structures.js`, `test/labour.test.js`, `test/structure-logic.test.js`, `test/builders.test.js` | K21, §3.25: emek yasası (`eff`, el sınırı, tek el yalnız tündükte, gece, hava durağı, tokluk, `dayCapacity`, onarım, taşıma, söküm, toplu benzetim); `STRUCTURE_DEFS` emek alanları, parça ve ham teslim, K23 türlerinin veri satırları; Faz 6 yeniden işleme (aşağıdaki liste): camp3 emek çizelgesi, `CHILD_HELP`, Dengiz baştan sona, öğün sırası, gece meşale direkleri (`G_TORCH`, `torch_post`), `SHELTER`, «aile bekler», HUD ekip satırı, camp3 kaydı `v: 2` | `labour` 1–15 (`d2/core.md` §2.2–§2.3: tek el 1.440 İD, ekip 1.376 İD, çizelge ±0,05 dk); camp3 saatsiz yardımsız 1.434 sn ±10, bütün yardımla 1.188 sn ±10 (Dengiz'in iki su seferi dahil, `d2/core.md` §2.10); 14:54 saatiyle ve öğünle ilk duman 00:55 (1.503 sn) ve 23:11 (1.244 sn) ±15, açık havaya iğneli; «Gece dinlenilsin» ≈08:55; aile ocak yanana dek ateşte (en geç 01:30; aşama ≥6 ise 03:00; `camp3:family_wait`); takılan usta ≤6 sn bekletir; `menuDiff` 0; program ≤92; en kötü kare ≤+250k, ≤+45 çizim |
| 8.12 | `src/game/site-core.js`, `src/game/sites.js`, `src/world/site-pad.js`, `src/world/specs/sandbox.js`, `src/world/specs/index.js`, `src/world/specs/zones.js`, `src/i18n/strings/sites.js`, `test/sites.test.js` | K21, §3.25: genel şantiye: yerleşim denetimi (`validatePlacement`, `rules`), yığın ve teslim, 150 m kendi taşıması, ekip atama, gece emri, bekleme nedenleri, çalışma atlaması, uzak şantiye ve `catchUp`, söküm, `world.sites`; Kışlak Yeni Yurdu'nun `timed` sürücüsü (saat, ekip, malzeme, hikâye kapısı); kum havuzu dünyası `sandbox_site` | `sites` sınamaları; Kışlak benzetimi `d2/core.md` §2.12 yolunu ±2 oyun dk verir; baskın sonrası en kötü kayıt ≤20 KB gidiş dönüş; `?sandbox=site` Faz 6 türlerini görünür kurar, K23 türlerini yalnız mantıkla (`SiteCore` ve `StructureState` bütün adımlardan, görünümsüz) işletir; K23 görünüşleri 9.10'dadır |
| 8.13 | `src/data/settlement.js`, `src/game/settlement/state.js`, `src/game/settlement/households.js`, `src/game/settlement/steward.js`, `src/game/settlement/stores.js`, `src/game/settlement/production.js`, `src/game/settlement/caravans.js`, `src/game/settlement/raids.js`, `src/game/settlement/camps.js`, `src/game/settlement/court.js`, `src/game/settlement/chronicle.js`, `src/i18n/strings/settlement.js`, `test/settlement.test.js` | K23, §3.27, `settlement.md` §5, §6, §9–§12, §15, §16: yerleşim çekirdeği (saf): hane, Çekim, Gönül, Kâhya, `StorePool`, üretim saati, `CaravanBook`, akın, `CampState`, Divan, Kronik; K24 servisleri ve K21 `SiteSystem` sözleşmeyle; `d2/settlement-model.json` v2 ile aynı sayılar | `settlement.md` §21 saf maddeleri 1–19; kum havuzunun istediği `state`, `households`, `steward`, `stores`, `production` çıkışı bağlar; `court`, `chronicle`, `raids`, `caravans`, `camps` Faz 8 çıkışını ve K11 kapısını bekletmez, bitmezse Faz 13'e kayar (`decisions.md` K26) |
| 8.14 | `src/game/cond.js`, `src/game/effects.js`, `src/game/cine.js`, `src/story/schema.js`, `tools/check-data.mjs`, `test/cond.test.js`, `test/effects.test.js`, `test/cine.test.js`, `test/schema.test.js` | §3.14, §3.19, §4.3: koşul atomları `phase:`, `beat:`, adlar `hour`, `dark`, `moon`; etki `clock` (`work` kalkar), `weather`, `ledger` yeri; sinemanın `clock` izi ve `weather` satırı, `release()` sinema kilitlerini kaldırır; `check-data`: hava kimlikleri, saat izi, `StoryDay` biçimi, eşya ve tarif kimliklerinin `d2/econ-model.json` ile, `data/settlement.js`'in `d2/settlement-model.json` ile eşitliği | Bütün yeni op ve atomlar sahte servisle; `clock` yalnız ileri; hava sistemi yokken `weather` op'u yok sayılır; sinema atlamasında `clock` satırları uygulanır |

`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları: `clock` 15, `weather` 22, `sites` 61, `camp_life` 81 (`settlement` 64 9.9'da); `ctx.worldClock`, `ctx.calendar`, `ctx.campLife`, `ctx.weather`, `ctx.sites`, `ctx.supply = LEDGERS` (`LEDGERS.bind(bus, { diff })`); `app.wallDt` (§2.5); `inventory.setResolver`; `save.setRules({ …, items })`; `?sandbox=site` → `play` + `replaceWorld('sandbox_site')`. `src/ui/hud.js`: geliştirme ışık düğmesi kalkar, Gök Kavisi `tr` yuvasına takılır. `src/app/sounds.js`: ortam evreye (`spec.audio.ambience`, `time.md` §8.5) ve havaya (`ctx.weather.audio`, §3.6) bağlanır. `src/app/devtools.js`: `drawMenuFrame` saat, CampLife ve hava kimliğini saklar ve geri yazar (§6.3); `freeze` dünya saatini ve hava saatini de durdurur. `src/app/states/freeroam.js`: `T` → Bekle (eski `toggleMood`, `MOOD_*` kalkar); `roam.clock` ve `roam.weather` okuma ve yazma (`clock.toRoam()`, `weather.toRoam()`), `mood` göçü; `endSession` geri yüklemesi (`time.md` §14); menüden iniş 2,4 sn, dönüş 1,7 sn ışık karışımı.

**Paket bağları.** 8.10 saatin yüzünü (§3.23) 8.9'dan, 8.11–8.13 8.9 ve 8.10'u, 8.12 `labour.js`'i 8.11'den ve `Container`'ı 8.2'den, 8.13 K24 servislerini (8.2, 8.4) ve `SiteSystem`'i (8.12), 8.14 `WorldClock` ve `Calendar`'ı (8.9), `ctx.weather`'ı (8.10) ve `LEDGERS`'ı (8.4) §3 sözleşmesiyle alır; dosya paylaşmazlar, bağı `L` faz sonunda sınar. `keymap.js` yalnız 8.9'dadır (`wait`, `build_mode`; ayrı `rotate` eylemi yok); `applyTaken` 8.3'tedir; `freeroam.js` bu fazda `L`'nindir. Ön koşullar: (1) `d2/labour-model.json` v2 `d2/core.md` §2.2–§2.3 sayıları ve bütün tür tablolarıyla yazıldı (2026-11-03); 8.11 onu okur. (2) **8.2 ve 8.4 başlamadan** ekonomi alanı `tools/econ-sim.mjs` ile `d2/econ-model.json`'ı birlikte K24'e getirir ve `--strict` 0 işarete indirir: `dayCapacity`, yeni kademe günleri (T2 2,5–7), hazır yük 1 / 6 / 12 / 22 / 17, yerleşik atlı ve düz %10 Ordu Payı (kışın ×0,1), `preserveLoss` 0,65 ve `sogumLoss` 0,35, düşman türü başına belirli ganimet (adlı silah satırları silinir), `banner_pole` 40 İD, Demirci Ocağı'nın hurda seçeneği, Teoman'ın armağanı ve gelen hanenin azığı ve kırkımı, Kâhya'nın av kolu ve `K_tok`, garnizonlu baskın kaybı, Surlu tarlası ve kulesi, Göçer ×1,2, malın perde ve mevsimde varlık sınaması, `weather-model.json` ve `labour-model.json`'ın okunması (`d2/core.md` §5.9). (3) 8.10 `weather-model.json`'ı ekonominin son `--strict` koşusundan önce yazar; dosya sonra değişirse sim yeniden koşulur.

**8.11 Faz 6 yeniden işleme** (K21; `d2/labour.md` §12, sayılar `d2/core.md` §2):

| Dosya | Değişiklik |
|---|---|
| `src/world/structure-defs.js` | `YURT_STEPS`: `dur`, `crew` → `work`, `min`, `max`, `solo` (yalnız `y_tunduk` 1,6), `tall`, `felt`; adım emekleri `d2/core.md` §2.2 (tek el 1.440, ekip 1.376); `YURT` `craft: 'home'`, `crewMax: 8`; `y_bosaga`, `y_kerege`, `y_uuk`, `y_liner` `parts` ve `rawWork` (360, 720, 480, 120 İD; kerege `rawRole: 'cr_carpenter'`); `STABLE`, `FENCE`, `PEN`, `CART` ve `simple()` türlerinin emek tabloları `labour-model.json`'dan (`simple()`'ın `dur: 10 + hp × 0,6` kuralı kalkar); `CREDIT_RATE` silinir, `REPAIR.tearStitch` 4 İD, `rerun` 0,8; K23 türleri ve hazır ayarları (§3.11) |
| `src/world/structure-logic.js` | `advance(wm)`, `wm`, `rate`; `credit(wm)` çarpansız; `sliceTick` silinir (`_buildTo` senaryo için kalır); `repairStep(wm, who)`; `dismantle()`; `_have`, `_spend` `matches(id, ref)` ile (ad öneki kuralı kalkar); `deliver` bohçayı açar; `toJSON` `v: 2` (göç `labour.md` §14; süren onarım `rep` İD olarak yazılır) |
| `src/world/structure.js` | `_work` yedeği oyun dakikası ve iki elin oranıyla (`manager.driven` yapıda iş yok, §8 karar 34); camp3 `v: 2` yazımı ve göçü; `G_TORCH` grubu ve gece alevleri (`fxFlames`, `fxGlow` havuzlarından); menü kipinde gizli |
| `src/world/structure-shader.js`, `src/world/camp.js` | `G_TORCH` etiketi ve iki meşale direği (camp3 `frame` ağında, ≈120 üçgen, 0 çizim) |
| `src/game/builders.js` | `workRate` → `labour.stepRate`; `HELP` → `CHILD_HELP` (katılma fiilleri; ayak işleri `help_log` (`node_camp_logs`'tan), `help_ember`, `help_water`); `HelpDesk.credit` kalkar; `DENGIZ_CALL_K` kalkar, Dengiz girişte gelir ve `JOBS`'ta sütun alır; `dur` → `stepSpanS()`; yeni durumlar `SHELTER`, öğün sırası (12:00, 18:30), ilk geliş 06:00–22:00, «Gece dinlenilsin» ile 22:00 çıkış; «aile bekler» kuralının tek sahibi: `camp3:family_wait { until }` (22:30; 01:30'da aşama ≥6 ise 03:00) ve `camp3:hearth_dawn` olaylarını yayar, 05:00 ocağı; `CampLife` (8.9) yalnız uyar; `status` `heads`, `W`, `etaMin`, `wait`, `solo` |
| `src/ui/hud/build-status.js`, `src/audio/sfx/structure.js`, `src/i18n/strings/structures.js` | Ekip ve «≈N saat» ya da bekleme nedeni satırı; `torch_post` reçetesi; `labour.*` anahtarları ve ustaların yeni sözleri |
| `test/structure-logic.test.js`, `test/builders.test.js` | 590 sn ve 283 sn sınamaları emek sayılarına geçer (§6.1) |

**Çıkış:** Deneme sahnesinde toplama, zanaat, ateş, yemek, av, dövüş, seviye ekranı; Serbest Gez'de 60 dakikalık gün, gece, Bekle ve Uyu, hava çekirdeği (görünüm kimlik); camp3 emekle ve saatle kurulur; kum havuzunda Faz 6 türleri görünür, K23 türleri mantıkla şantiyeyle kurulur (görünüşleri 9.10); yerleşim çekirdeği `node:test`'te.
~~~

### M52. Faz 9

**Aralık:** aşağıdaki başlığın altındaki ilk dolu satırdan sonraki çapa satırına dek (o satır dahil).

**Aralık başı:**
~~~
### Faz 9: Kışlak dünyası
~~~
**Aralık sonu (dahil):**
~~~
**Çıkış:** `?state=play&zone=hexi_winter`: boş Kışlak, gündüz ve gece, §7 bütçesi ölçülür.
~~~
**Yerine:**
~~~
`act1.md` §4, §15. Canlı kampa dokunulmaz. K22 hava görünümü ve sesi, K23 yerleşim görünümü, Plan Kipi ve yapı görünüşleri bu fazdadır; menü karesi değişmez.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 9.1 | `src/world/specs/winter.js`, `src/world/specs/winter-layout.js`, `src/world/specs/index.js`, `src/world/terrain-patches.js`, `src/world/snow-hooks.js` | 1400×1050 m; 100 m parça, yakın 3×3 1 m; yükseklik §4; `tree_winter`, `node_winter`, `*_w`; kar kabartma zemini (§3.8), parça başına boyama yok; `winter-layout`: `rot`, iç tasarım, `watch_fires[]` (`act1.md` §4), Kışlak Yeni Yurdu şantiyesi (ekip, gönderim tablosu, kapılar); `light`, `WINTER_MOODS`, `weather`, `labour`, `perish` (§3.8); `SNOW_FRESH` kancası (9.4'ten); `specs/index.js` `hexi_winter` ve `sandbox_hold` yükleyicileri | Kurulum ≤8 sn; `swap('hexi_winter')`; Gün I doğuş 07:11, batış 16:49 |
| 9.2 | `src/game/nav-patches.js`, `src/game/nav.js`, `src/game/structure-nav.js`, `test/nav-patches.test.js` | `NavView`; 100 m, 0,5 m hücre, 3×3 bellekte; uzak tıklama yol grafı; `sb`, `st`; `canPlace(shapes)` (K23) iki ızgarada | A* ≤2 ms; ızgara dikişinde takılma yok; `canPlace` ≤3 ms |
| 9.3 | `src/world/road.js`, `src/game/travel-data.js`, `test/road.test.js` | `travel.md` §4, §12; `r_whistle_ordu`; `LOCKS`'ta `weather` (7. sıra); yol olayları `ev_storm`, `ev_dust`, `ev_flood`, `ev_snowbound`, III'ten `ev_raid` | `travel.md` T1 uzunlukları ±%0,5; §4.4 Dijkstra tablosu |
| 9.4 | `src/world/weather.js`, `src/world/weather-hooks.js`, `src/world/world.js`, `src/world/sky.js`, `src/world/flora.js`, `src/world/grass.js`, `src/world/fire.js`, `src/world/camp.js`, `src/world/terrain.js`, `src/core/post.js`, `src/core/paint-material.js` | K22, `weather.md` §9: `WeatherView.compose` (tek ışık yazıcısı), yağış ve sıçrama noktaları (kar 6000), yıldırım şeridi, ekran yağışı (FINAL), şimşek nabzı (ışık eklenmez), bulut örtüsü ve cephe hattı, kubbe, ıslaklık kancaları, rüzgâr (çim, ağaç, duman, bayrak, alev); Tipi ve Kara Boran sisi; kış ormanı; `world.tallThings` ağaçları | §8 bütçesi; `menuDiff` 0; program +2 (≤92); W12–W18, W25 |
| 9.5 | `src/character/puppet.js`, `src/character/draft.js`, `src/world/cart.js` | `army.md` §7.3 sözleşmesi; `felt2w`; duran `camp_stop` arabası (`travel.md` §10.3) | ≤6k üçgen, 2 çizim; kukla ≤1.200; `camp_stop` nav kabulü |
| 9.6 | `src/world/structure-defs.js`, `src/world/structure-shader.js`, `src/world/structure.js` | `winter`, `closed`; 21 kapalı LOD; `rot` ve iç tasarım eşlemesi, iç eşya ≤12k (`structures.md` §13.5); K22: `FELT_WET`, ateşli ok tutuşma çarpanı, `world.tallThings` aday kaydı, Bağla / Çöz, `galeDamage`; K23: `scale` (Otağ ×1,4), görünüm kaydı (`KITS`, 9.10), uzak yurdun `YurtField`'e devri (`closed` örneği, `aCut`, `aChar`), ≤48 canlı yapı | ≤185k, ≤40 çizim; `structures.md` §17 1, 5, 10 değişmez; §17 12 (Otağ) ve 13 (`YurtField` devri) |
| 9.7 | `src/character/looks.js` | `act1.md` §3 kadro `Folk` tanımları, hayvanlar | 22 `Folk` tanımı kurulur, 13,9–24,8k üçgen |
| 9.8 | `src/audio/sfx/weather.js`, `src/audio/ambience.js`, `src/ui/hud/weather.js`, `src/ui/css/weather.css`, `src/core/settings-schema.js`, `src/ui/menu/pages/settings.js` | `weather.md` §10, §11: altı hava döngüsü (cepheyle pişer), yedi efekt, HUD simgesi ve işaret satırı, `a11y.flashes`; yerleşimin dört döngüsü (`hold_day`, `herd_flock`, `camp_army`, `gathering_crowd`) | W19–W21; Serbest Gez fırtınasında canlı düğüm ≤35 (tavan 40); kampta fırtınalı akşam önbelleği ≤16 MB |
| 9.9 | `src/game/settlement/index.js`, `src/game/settlement/plan.js`, `src/world/settlement-view.js`, `src/world/specs/sandbox.js`, `src/ui/hud/plan-bar.js`, `src/ui/css/hold.css`, `src/audio/sfx/settlement.js`, `src/audio/music-states.js` | K23, §3.27, `settlement.md` §13, §14, §18: `SettlementSystem` (64), Plan Kipi (`plan` bağlamı, `sites.beginPlacement`, parsel ve yer kuralları), `YurtField`, `KitField` (tek `BatchedMesh`), parsel çıkartması, sürü örnekleri; kum havuzunun yerleşim kipi `sandbox_hold`; sekiz yerleşim efekti; `hold`, `hold_night`, `court`, `muster` (efektler ve müzik durumları faz çıkışını ve K11 kapısını bekletmez, bitmezse Faz 13'e kayar) | 20 yurt Plan Kipi'yle; 200 rastgele yerleşimde bağlantı kopmaz; ×240 hızla 10 gün (Kâhya; kervan ve baskın 8.13'ün o modülleri hazırsa); `hold.synth(5, 'walled')` ve `synth(5, 'moving')` karesi §7 satırında; yerleşim dünyasında program +6 (≤92); `structures.md` §17 14 |
| 9.10 | `src/world/structure-kits.js`, `src/world/site-pad.js` | K23 yapı görünüşleri (`structures.md` §4.6): `yard`, `mound`, `ring`, `post`, `field` aileleri; `shed` `open`/`walled`, `tower` `low`/`gate`/`granary`, `fence` `picket`/`stockade`; tür başına `KitField` kaba ağı (≤400 üçgen); `PadField` (örnekli hafif ped; camp3'ün tuvali yalnız camp3'te) | `structures.md` §17 11: her tür kum havuzunda kurulur, vurulur, geri düşer; ≤6k üçgen, ≤2 çizim; program eklemez (`struct_parts`, `struct_props`) |

`L`: `src/app/sounds.js` (hava döngü birleşimi; kış ve yerleşim dünyalarının ortamı), `src/app/devtools.js` (`drawMenuFrame`'in hava saklaması görünümle sınanır), `src/app/states/freeroam.js` (`roam.weather` görünümle; iniş ve dönüş karışımı havayı da kapsar), `src/app/systems.js` (`SettlementSystem` 64, `ctx.settlement`), `src/app/app.js` (`?sandbox=site&hold=1` → `sandbox_hold`; `WeatherBadge` `tr` yuvasına takılır).

**Paket bağları.** 9.4 8.9'un `writeLight`'ını devralır; 9.1 `SNOW_FRESH`'i 9.4'ten, 9.6 `KITS`'i 9.10'dan ve `YurtField` yuvasını 9.9'dan, 9.9 `SiteSystem`'i (8.12), yerleşim çekirdeğini (8.13) ve `canPlace`'i (9.2) sözleşmeyle alır.

**Çıkış:** `?state=play&zone=hexi_winter`: boş Kışlak, gündüz ve gece saatle, kar ve hava, §7 bütçesi ölçülür; Serbest Gez'de fırtına, yıldırım ve dolu, menüye dönüş `menuDiff` 0; kum havuzunda yerleşim kipi Plan Kipi'yle kurulur.
~~~

### M53. Faz 10: paket satırları

**Bul:**
~~~
| 10.1 | `src/game/quests.js`, `src/game/calendar.js`, `src/game/regions.js`, `src/game/jobs.js`, `test/quests.test.js`, `test/calendar.test.js`, `test/regions.test.js`, `test/jobs.test.js` | §3.14, §4.1; `act1.md` §2 | Rütbe ve İş Puanı tablosu |
~~~
**Yerine:**
~~~
| 10.1 | `src/game/quests.js`, `src/game/regions.js`, `src/game/jobs.js`, `test/quests.test.js`, `test/regions.test.js`, `test/jobs.test.js` | §3.14, §4.1; `act1.md` §2; İş Tahtası hikâye günü başına 3 iş | Rütbe tablosu; vakit ve uyku kapısı `calendar` (8.9) ile |
~~~

**Bul:**
~~~
| 10.3 | `src/game/schedule.js`, `src/game/npcs.js`, `test/schedule.test.js` | §3.16; `act1.md` §5 | ≤16 tam kişi; kadrajda sıçrama yok |
~~~
**Yerine:**
~~~
| 10.3 | `src/game/schedule.js`, `src/game/npcs.js`, `test/schedule.test.js` | §3.16; `act1.md` §5, `time.md` §9.4: dakika blokları, `onBlock`, hava sığınması (`weather.md` §8.12) | ≤16 tam kişi; kadrajda sıçrama yok; Kışlak'ta 22 kişi her blokta yerde; bölge gece hâli 19:30–06:40 |
~~~

**Bul:**
~~~
| 10.4 | `src/game/stealth-core.js`, `src/game/stealth.js`, `src/world/track-decals.js`, `test/stealth.test.js` | §3.16; `act1.md` §9.5 | `progression.md` §17.1 #5, #6, #16 |
~~~
**Yerine:**
~~~
| 10.4 | `src/game/stealth-core.js`, `src/game/stealth.js`, `src/world/track-decals.js`, `test/stealth.test.js` | §3.16; `act1.md` §9.5; «Karanlık» `clock.dark` ve ışık havuzu, şimşek nabzında kapalı; `fx.vis`, `fogK`, `hearK`, koni çarpanı; iz ömrü `fx.trackK` | `progression.md` §17.1 #5, #6, #16; koni 68°, 60°, 56° (W7) |
~~~

**Bul:**
~~~
§3.17; `game.seat`; `travel.md` §16 adım 4–13; `camp_stop` sürücü satırı
~~~
**Yerine:**
~~~
§3.17; `game.seat`; `travel.md` §16 adım 4–13; `camp_stop` sürücü satırı; saatin doğal süresi ve `k`, atlas bacağında `clock:skip { reason: 'travel' }` (24 saati aşınca uzun atlama), `lock.weather`; kervanın atlas arabası (`ctx.settlement.caravans()`)
~~~

**Bul:**
~~~
| 10.6 | `src/game/squad/index.js`, `src/game/squad/squad.js`, `src/game/squad/follower.js`, `src/game/squad/formation.js`, `src/game/squad/army-data.js`, `src/game/squad/crowd.js`, `src/game/squad/demo.js`, `src/i18n/strings/army.js`, `test/formation.test.js`, `test/army-data.test.js` | `army.md` §11.1 | `army.md` §11.1 kabul 1–11 |
~~~
**Yerine:**
~~~
| 10.6 | `src/game/squad/index.js`, `src/game/squad/squad.js`, `src/game/squad/follower.js`, `src/game/squad/formation.js`, `src/game/squad/army-data.js`, `src/game/squad/crowd.js`, `src/game/squad/demo.js`, `src/i18n/strings/army.js`, `test/formation.test.js`, `test/army-data.test.js` | `army.md` §11.1; `fx.fatigueK` (Han ×2), salvo rüzgârı ve ıslak kiriş, ay olayları `calendar.moonIllum`'dan, öğünler 07:00 ve 18:00 (`weather.md` §8.13, `time.md` §10.7) | `army.md` §11.1 kabul 1–11 |
~~~

**Bul:**
~~~
| 10.7 | `src/ui/journal.js`, `src/ui/info-card.js`, `src/ui/css/journal.css`, `src/ui/hud/trust.js`, `src/ui/hud/axes.js`, `src/ui/hud/clock.js`, `src/ui/hud/squad-bar.js`, `src/i18n/strings/quests.js` | Görevler, kural kartı, Çentik, güneş ve kor, dilim | Kut ve Korku sayı göstermez |
~~~
**Yerine:**
~~~
| 10.7 | `src/ui/journal.js`, `src/ui/info-card.js`, `src/ui/css/journal.css`, `src/ui/hud/trust.js`, `src/ui/hud/axes.js`, `src/ui/hud/squad-bar.js`, `src/i18n/strings/quests.js` | Görevler (vakitler evreyle, «Seni çağırıyorlar.»), kural kartı, Çentik, kor | Kut ve Korku sayı göstermez |
~~~

**Bul:**
~~~
| 10.8 | `src/app/states/play.js`, `src/game/journey.js`, `test/journey.test.js` | Yeni yolculuk, kayıt blokları, `act_change`, `ACT1_READY` | Kaydet, yükle, `derive` aynı |
~~~
**Yerine:**
~~~
| 10.8 | `src/app/states/play.js`, `src/game/journey.js`, `test/journey.test.js` | Yeni yolculuk, kayıt blokları (sıra 69–78, 92), `act_change` (`act:change` olayı; tarih `ACT_START`'a uzun atlamayla), `ACT1_READY`; `CondCtx`: `hour`, `dark`, `moon`, `phase:`, `beat:`, `ledger.<line>` | Kaydet, yükle, `derive` aynı; perde geçişi ≤150 ms / mevsim |
~~~

**Bul** (10.9 satırının sonu):
~~~
| `L` oynar, süre ve kare ölçülür |
~~~
**Yerine:**
~~~
| `L` oynar, süre ve kare ölçülür; Gün I saatle (öğle çanı 12:00, `mq_ration` 13:30'da karartmayla götürür) |
| 10.10 | `src/ui/hold-ledger.js`, `src/ui/css/hold-ledger.css`, `src/game/settlement/index.js` | Yerleşim Defteri bütün bölümleri ve sayfa biçemi (`settlement.md` §14.2); kervan bağı (kum havuzunun iki ucu arasında saatle). K11 kapısını bekletmez; bitmezse Faz 13'e kayar (K26) | Her bölüm dolu; kervan, Kâhya ve baskın ×240 hızla 10 gün; kaydet, yükle aynı |
~~~

**Bul:**
~~~
`L`: `src/app/systems.js` bütün sistemleri kaydeder; `src/app/app.js` `ctx` alanları.
~~~
**Yerine:**
~~~
`L`: `src/app/systems.js` bütün sistemleri kaydeder; `src/app/app.js` `ctx` alanları; `act:change` (10.8) yerleşimin Kronik'ine bağlanır.
~~~

### M54. Faz 10: kapı

**Bul:**
~~~
`src/story/proto/` Faz 11 açılınca silinir.
~~~
**Yerine:**
~~~
`src/story/proto/` Faz 11 açılınca silinir. Kapıda ayrıca saatli Gün I ölçülür: vakit çağrısı ve karartmayla götürme, öğle çanı 12:00, ilk 15 dakikanın Yar Bakışı'na 15:00 ±30 dk'da varışı; Tipi prototipinde `kara_boran` hava kilidi ve `pinFx`. Kapının yeri değişmez (K11).
~~~

### M55. Faz 11: satırlar

**Bul:**
~~~
| 11.1 | `src/story/act1/schedule.js`, `src/story/act1/guards.js`, `src/story/act1/regions.js`, `src/story/act1/jobs.js` | `act1.md` §2, §4, §5 | Bütün kişiler her dilimde yerde |
~~~
**Yerine:**
~~~
| 11.1 | `src/story/act1/schedule.js`, `src/story/act1/days.js`, `src/story/act1/guards.js`, `src/story/act1/regions.js`, `src/story/act1/jobs.js` | `act1.md` §2, §4, §5; `time.md` §9.2, §9.4: hikâye günleri, vakitler, dakika blokları | Bütün kişiler her saat bloğunda yerde; her günün ana işi gece de yapılabilir |
~~~

**Bul:**
~~~
| Gün I, ilk 15 dakika (`act1.md` §12) | Dakika tablosu ±%20 |
~~~
**Yerine:**
~~~
| Gün I, ilk 15 dakika (`act1.md` §12); hava kilidi `a1_road_in` | Dakika tablosu ±%20; saat eşlemesi `time.md` §9.8 |
~~~

**Bul:**
~~~
| Gün III, Tündük, Elçi, Av |
~~~
**Yerine:**
~~~
| Gün III, Tündük (Kışlak Yeni Yurdu `crown_raised` kapısı), Elçi, Av |
~~~

**Bul:**
~~~
| Toy, baskın, 6 dk saat |
~~~
**Yerine:**
~~~
| Toy, baskın, 6 dk saat; dolunay Gün IV 18:00; `b_feast` `ensureStage(7)` ve `feast_ember` kapısı; hava kilidi `a1_feast_raid` |
~~~

**Bul:**
~~~
| Kül, Göz Yolu, hüküm, Son Aş |
~~~
**Yerine:**
~~~
| Kül, Göz Yolu, hüküm, Son Aş; Nanay'ın yaması 07:00–08:42 (275 İD); hüküm Göz Yolu'nun sonunda (`run` sinemasından sonra sahne sırayla bağlanır, `time.md` §6.4) |
~~~

**Bul:**
~~~
| Saat biterse `dawn_path` |
~~~
**Yerine:**
~~~
| Buz saati her zorlukta 06:40 (Amaga Normal 20:00, Zor 21:30; Hikâye 05:45 bekleyişi); saat biterse `dawn_path` |
~~~

**Bul** (11.7 satırının dosya hücresinin sonu):
~~~
`src/game/moon-clock.js`, `src/game/frozen-camp.js` |
~~~
**Yerine:**
~~~
`src/game/moon-clock.js`, `src/game/frozen-camp.js`, `src/ui/hud/clock.js` (Gök Kavisi'nin Ay Saati kipi; dosya 8.9'da yazıldı, Faz 11'de yalnız 11.7 dokunur) |
~~~

**Bul:**
~~~
| Kara Boran, Boğaz, Ses; jestler `sign` vb. |
~~~
**Yerine:**
~~~
| Kara Boran (hava kilidi `kara_boran`, `pinFx`), Boğaz, Ses; jestler `sign` vb. |
~~~

### M56. Faz 12: satırlar ve Faz 13

**Bul:**
~~~
| 12.1 | `src/core/post.js`, `src/world/world.js`, `src/world/fire.js` | Gölge kadansı, tam ekran çözünürlük geçişi takılması; `spec.postCuts`: menü bitişiğinde render hedefi sabit; `?q=low` | §7 tablosu |
~~~
**Yerine:**
~~~
| 12.1 | `src/core/post.js`, `src/world/world.js`, `src/world/fire.js` | Gölge kadansı, tam ekran çözünürlük geçişi takılması; `spec.postCuts`: menü bitişiğinde render hedefi sabit; `?q=low`; hava kesintileri (§7 sıra 8), `video.quality` low onları baştan uygular | §7 tablosu |
~~~

**Bul:**
~~~
| 12.2 | `src/core/input.js`, `src/core/keymap.js`, `src/ui/hud.js` | Oyun kolu, Buyruk Halkası, dokunmatik tarama | `menu-spec.md` kol tablosu |
~~~
**Yerine:**
~~~
| 12.2 | `src/core/input.js`, `src/core/keymap.js`, `src/ui/hud.js` | Oyun kolu, Buyruk Halkası, dokunmatik tarama; Bekle tekeri ve Plan Kipi kol eşlemesi | `menu-spec.md` kol tablosu |
~~~

**Bul:**
~~~
| 12.4 | `tools/check-budget.mjs` | Sahne başına `perf()` eşikleri | Geçer |
~~~
**Yerine:**
~~~
| 12.4 | `tools/check-budget.mjs` | Sahne başına `perf()` eşikleri; Serbest Gez fırtınası, yerleşim (`synth(5, …)`), ordugâh, Kışlak yoğun kar | Geçer |
~~~

**Bul:**
~~~
`L`: `src/character/hero.js`, `src/ui/creator.js` silinir, son anlık görüntüden sonra.
~~~
**Sonrasına ekle:**
~~~

### Faz 13: II. Perde açılışı, yerleşim ve ordugâh dünyaları (taslak)

K23: hikâye açılışı II. Perde'dir. Faz 12 bitince açılır; paket kapsamını `L` Faz 12 sonunda kesinleştirir. Ayrıntı `settlement.md` §2, §3, §10, §19; `d2/core.md` §4.2, §4.10. II. Perde'nin iki büyüme yayı burada paketlidir: ordugâh (Onluk Ateşi → Yüzlük Kampı, 13.4) ve yerleşim (Ocak → Oba, 13.5). Darbe ve öteki hikâye içerikleri `army.md` II. Perde planıyla ayrıca yazılır. Faz 8–10'da bitmeyen II–VI parçaları (`court`, `chronicle`, `raids`, `caravans`, `camps`, yerleşim müzik durumları ve `sfx/settlement.js`, Yerleşim Defteri) bu fazın başında, kendi dosyalarıyla bitirilir (K26).

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 13.1 | `src/world/specs/tanhu-ordu.js`, `src/world/specs/tanhu-ordu-layout.js` | `tanhu_ordu` 1400×1050 m: Karasu deresi, Kutlu Tepe, üç Ocak Yeri ve önceden kırpılmış parselleri, düğüm kümeleri (`c_birch_hill` dahil), kapılar; `spec.settlement` (`kind: 'hold'`), `steppe_south`, enlem 43,5° | Kurulum ≤8 sn; `settlement.md` §3.2 uzaklıkları gerçek nav'la ±%5; program ≤92 |
| 13.2 | `src/world/specs/whistle-field.js`, `src/world/specs/whistle-field-layout.js` | `whistle_field`: Pınarlar, talim ovası, ordugâh parselleri, Bakış Sırtı; `spec.settlement` (`kind: 'camp'`), `gobi`, enlem 44,2° | Tümen dizilişi sığar (`army.md` §4.2); program ≤92 |
| 13.3 | `src/story/act2/opening/index.js`, `src/story/act2/opening/quests.js`, `src/story/act2/opening/dialogue.js`, `src/story/act2/opening/cine.js` | `mq2_allotment` sineması (K7 `home` sahnesinin devamı, Tanhu Kampı'nda uzak kare, K106), Köz Kabı, `mq2_own_hearth` (Ocak Yeri seçimi, 48 saat köz, Mete'nin yurdu ilk onlukla), Teoman'ın armağanı (`yurt_kit`, `cart_felt`, ≈30 at eşdeğeri sürü) | Ana kampta Mete oynanmaz (K6); Ocak kademesi açılır; ilk Kronik II'nin açılış tabanını verir; armağan 60 yün, 6 külçe ve ≈217 öğünlük azıkla gelir, ilk şafakta yiyecek çizgisi ≥%50 |
| 13.4 | `src/world/tent-field.js`, `src/story/act2/camp/index.js`, `src/story/act2/camp/quests.js`, `src/story/act2/camp/dialogue.js` | Islık Ordugâhı: `CampPlan` çadırları (yerleşik atlının kendi `tent_kit`'leri), Talim Alanı, ilk talim, `mq2_whistle_camp`; Buyruk Yurdu, Erzak Ambarı, Silahlık ve Yüzlük Kampı; `TentField` (`KitField` deseni: tek örnekli çizim + gölge, çadır başına ≤200 üçgen, program eklemez, yerleşim dünyasının `kit_field` programını paylaşır; 40 m ötesi çadırlar) | Onluk Ateşi → Yüzlük Kampı kademe geçişi; Binlik deneme dizilişinde ≤323 çizim, ≤2,74M üçgen; program ≤92 |
| 13.5 | `src/story/act2/oba/index.js`, `src/story/act2/oba/quests.js`, `src/story/act2/oba/dialogue.js` | İlk aileler ve Oba: `hh_story` (dülger hanesi, Ağaç Atölyesi), `mq2_oba` dalgası (demirci dahil dört hane, yurt yükleri, 5 günlük azık, son kırkımın yarısı), Oba kapısı (`settlement.md` §4.1); Tanhu pazarcısının iki günde bir gelişi | Oynanan bir koşuda Oba kademesine II. Perde'nin 12 ±%30 gününde ulaşılır; yün, külçe ve usta yolu kapanmaz (`econ-sim` varlık sınaması) |

`L`: `src/world/specs/index.js`, `src/world/specs/zones.js` (`tanhu_ordu`, `whistle_field` adları ve yükleyicileri), `src/story/act2/index.js`, `src/story/vo-lines.js` (`ACTS`), `src/app/systems.js`.

**Çıkış:** II. Perde açılır: pay, Köz Kabı, Ocak Yeri; yerleşim ve ana ordugâh iki ayrı dünya olarak kurulur, kervan aralarında saatle gider; Ocak → Oba ve Onluk Ateşi → Yüzlük Kampı bir oynanışta perde günü içinde biter.
~~~

## 7. §6 Test planı

### M57. §6.1 `node:test` tablosu

**Bul:**
~~~
| `timeline`, `cine` | `core/timeline`, `core/ease`, `game/cine` (çekirdek) | Göreli `t`, cue sırası, atlama |
~~~
**Yerine:**
~~~
| `timeline`, `cine` | `core/timeline`, `core/ease`, `game/cine` (çekirdek) | Göreli `t`, cue sırası, atlama; `clock` izi (`set`, `atLeast`, `advance`, `run`) yalnız ileri ve atlamada da uygulanır; `weather` satırı, `release()` kilidi kaldırır |
~~~

**Bul:**
~~~
| `cond`, `flags`, `effects` | `game/cond`, `game/flags`, `game/effects` | `progression.md` §4.1 dili; §3.14 tablosu |
~~~
**Yerine:**
~~~
| `cond`, `flags`, `effects` | `game/cond`, `game/flags`, `game/effects` | `progression.md` §4.1 dili; §3.14 tablosu; `phase:`, `beat:`, `hour`, `dark`, `moon`; `clock` yalnız ileri, `hold` yalnız iki bekleyiş; `weather` op'u (hava yokken yok sayılır); `ledger` yeri (`own_seat` …) |
~~~

**Bul:**
~~~
| `structure-logic` | `world/structure-logic`, `world/structure-defs` (yardım toplamı `game/builders` `HELP`'ten) | `structures.md` §5.3, §6.1; `progression.md` §17.1 #11, #12 |
| `builders` | `game/builders` (sahte aktör ve sahte yapı, gerçek `StructureState`), `character/gestures/build`, `i18n/strings/structures` | `structures.md` §10, §11.6: yardımsız 590 sn ±5, bütün yardımlarla ≥283 sn, takılan usta en çok 6 sn bekletir; dizgeler TR ve EN |
~~~
**Yerine:**
~~~
| `structure-logic` | `world/structure-logic`, `world/structure-defs` (emek `labour-model.json` ile aynı) | `structures.md` §5.3, §6.1; `progression.md` §17.1 #11, #12; `advance(wm)` 1.376 İD'de biter, 13 adım sırası aynı; `credit(wm)` çarpansız; onarım emekleri İD; parça ve ham teslim (`rawWork`), bohça açma; `v: 2` göçü |
| `builders` | `game/builders` (sahte aktör ve sahte yapı, gerçek `StructureState`), `character/gestures/build`, `i18n/strings/structures` | `structures.md` §10, §11.6: saatsiz yardımsız 1.434 sn ±10 (Dengiz'in iki su ve dört kütük seferiyle), Çocuğun bütün yardımıyla 1.188 sn ±10; 14:54 saatiyle ve öğünle 1.503 ve 1.244 sn ±15, açık havaya iğneli; Dengiz her adımda; aile ocak yanana dek ateşte (en geç 01:30, aşama ≥6 ise 03:00; aşarsa ocak 05:00'te; `camp3:family_wait`, `camp3:hearth_dawn`); «Gece dinlenilsin» ile ertesi sabah ≈08:55; `SHELTER`'da emek durur; takılan usta en çok 6 sn bekletir; dizgeler TR ve EN |
| `labour` | `game/labour` | `d2/core.md` §2: `eff` tablosu; tek el 1.440 İD, ekip 1.376 İD; ekip çizelgesi ±0,05 dk ve kesin azalan; karışık ekipler; önder ve usta kuralı; gece sınıfı çarpanı; hava durakları; onarım; taşıma (146 Yük 50 m: 8 sefer, 224 İD); toplu benzetim eşdeğerliği (600 × 1 dk = 600 dk ±1e−6); söküm 0,35; `dayCapacity`; `etaWords`; `labour-model.json` ile aynı sayılar |
| `sites` | `game/site-core` (saf), `game/sites` (sahte dünya) | Yerleşim nedenleri; yığın tüketimi ve bekleme nedeni; 150 m kendi taşıması; gece emri; çalışma atlaması; yerleşimli zonda atlamanın tek sahibi; kayıt gidiş dönüş (baskın sonrası en kötü durum ≤20 KB); Kışlak benzetimi `d2/core.md` §2.12 yolunu ±2 oyun dk |
~~~

**Bul:**
~~~
| `inventory`, `needs`, `craft`, `supply`, `gather` | `game/inventory`, `game/items`, `game/needs`, `game/craft`, `game/barter`, `game/supply`, `game/gather` (çekirdek) | `economy.md` §4.1, §7 senaryo tablosu, §10 |
~~~
**Yerine:**
~~~
| `inventory`, `container`, `needs`, `craft`, `supply`, `herds`, `loot`, `gather` | `game/inventory`, `game/container`, `game/items`, `game/needs`, `game/craft`, `game/barter`, `game/supply`, `game/herds`, `game/loot`, `game/gather` (çekirdek) | `economy.md` §4.1, §7 senaryo tablosu, §10; `d2/economy.md` §17 (`armyShare` düz %10; `loot.of` belirli, insan yok); Tokluk oyun dakikasıyla (uyku ×0,25, ateş başı ×0,5, `diff.foodK`) |
~~~

**Bul:**
~~~
| `node-store` | `world/node-store`, `data/node-kinds` | 3.270 kayıt, tohum sabit, `perm` gidiş dönüş |
~~~
**Yerine:**
~~~
| `node-store` | `world/node-store`, `data/node-kinds` | 3.270 kayıt, tohum sabit, `perm` gidiş dönüş; `applyTaken` belirlenimli; atlanan her şafakta bir `onDawn` |
~~~

**Bul:**
~~~
| `calendar`, `regions`, `jobs` | `game/calendar`, `game/regions`, `game/jobs` | `act1.md` §2 |
~~~
**Yerine:**
~~~
| `world-clock`, `daylight`, `sky-keys`, `calendar` | `game/world-clock`, `game/daylight`, `game/calendar` | `time.md` §17: gün ışığı altın değerleri (Hexi Gün I doğuş 07:11, batış 16:49; kamp 05:22 / 18:38), menü vektörü (sapma +7,4223°, 11 Nisan, 14:46,2; 1e−5), `skyAt(886.18)` 4,3 ve `applyMood(0,3)` ile aynı renkler, `lightLevel` başvuruları ve `nightClass` eşikleri; duvar tavanı 0,25 sn, bekleyiş, atlama olay sırası, uzun atlamada tek `clock:skip`; buz saati her zorlukta 06:40, Zor Düğüm 21:40, Hikâye 05:45 bekleyişi; dolunay Gün IV 18:00; `dayN` 1.041 → MÖ 210; `ACT_START` |
| `weather-core`, `weather-fx`, `weather-strike` | `game/weather-core`, `data/weather-types`, `data/climates`, `i18n/strings/weather` | `weather.md` §15 W1–W11, W26 (kural sırası, I. Perde kabuk 0, yalnız `steppe_south` ve `gobi`'ye mutlak tolerans; dosyayı üreteç yazar, sınama yazmaz); camp3 bitene dek kampta `sev` ≤2; belirlenim, 38 iklim satırında ≤1,5 puan, süre ve cephe, kilit ve `pinFx`, I. Perde sayıları, etki matrisi, ıslaklık, yıldırım adaleti, ses gecikmesi, K1 (oyuncu metninde soğuk ve sıcak yok), kar örtüsü ve Kar Kabuğu payları |
| `settlement` | `data/settlement`, `game/settlement/*` (saf; sahte `SiteSystem`, takvim ve hava) | `settlement.md` §21 1–19: veri bütünlüğü, kademe, Çekim, katılım, Gönül, esir yok, Kâhya, tüketim, kap ve baskın, kervan, ordugâh, toplantı, yer kuralları, atlama eşdeğerliği, kayıt boyutu (90 hane ve 160 yapıyla `settlement` ≤14 KB, `camps` ≤4 KB), küme, ayrı defterler, Kronik, bakım |
| `regions`, `jobs` | `game/regions`, `game/jobs` | `act1.md` §2; İş Tahtası hikâye günü başına 3 iş |
~~~

**Bul:**
~~~
| `schedule`, `stealth` | `game/schedule`, `game/stealth-core` | `act1.md` §5, §9.5; `progression.md` §17.1 #5, #6, #16 |
~~~
**Yerine:**
~~~
| `schedule`, `stealth` | `game/schedule`, `game/stealth-core` | `act1.md` §5, §9.5; `progression.md` §17.1 #5, #6, #16; dakika blokları ve `onBlock`, bölge gece hâli 19:30–06:40; koni 68°, 60°, 56°; «Karanlık» `clock.dark`, şimşekte kapalı |
~~~

### M58. §6.1 Saf listesi

**Bul:**
~~~
world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line}
~~~
**Yerine:**
~~~
world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line,weather-hooks}
~~~

**Bul:**
~~~
game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches}
~~~
**Yerine:**
~~~
game/{cond,flags,effects,damage,save,progress,derive,items,inventory,container,needs,craft,supply,barter,herds,loot,cooking,calendar,world-clock,daylight,weather-core,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches,labour,site-core}`, `game/settlement/{state,households,steward,stores,production,caravans,raids,camps,court,chronicle}
~~~

### M59. §6.2 Statik denetim

**Bul:**
~~~
`voBudget` ≤45.000 (Act 0 + Act 1) |
~~~
**Yerine:**
~~~
`voBudget` ≤45.000 (Act 0 + Act 1); hava türü kimlikleri (etki, sinema, kilit), sinemanın `clock` izi, `story/act1/days.js` (`StoryDay`, vakit pencereleri sıralı ve zincirli); `data/items.js` ve `data/craft-recipes.js` kimlik ve sayılarının `d2/econ-model.json` ile, `data/settlement.js`'in `d2/settlement-model.json` ile eşitliği; başvurulan efekt kimlikleri (`torch_post`, saat, hava, ekonomi, yerleşim reçeteleri) |
| `node tools/econ-sim.mjs --strict` | K24 denge modeli (`d2/econ-model.json`, `d2/settlement-model.json`, `d2/weather-model.json`): kimlik ve etiket tutarlılığı, bohça ağırlığı, el işi tutuşu; malzeme, yapı, kademe ve perde hedefleri (kademe günü T1 2–5 … T5 4–12); kış payı %75–115; perde başına baskın kaybı ≤%10; tarif Kıymet bandı; I. Perde sözleşmesi (yurt 54 birim, 146 Yük, parça biçiminin ham biçime eşitliği). Betiği yalnız ekonomi alanı yazar |
~~~

### M60. §6.3 `window.__tanhu`

**Bul:**
~~~
  struct, travel, econ, squads, story, stealth, cine, audio, i18n, save,
~~~
**Yerine:**
~~~
  struct, travel, econ, squads, story, stealth, cine, audio, i18n, save, clock, weather, labour, hold,
~~~

**Bul:**
~~~
| `econ` | `give, setLedger, setNeeds, dawn, nodeStats, showFootprint, ratio` (`economy.md` §12) | 8.3 |
~~~
**Yerine:**
~~~
| `econ` | `give, setLedger, setNeeds, dawn, nodeStats, showFootprint, ratio` (`economy.md` §12); `put(id, n, containerId)`, `perish()`, `craft(recipeId, n)`, `loot(enemyKind, n)` (§3.26). Yerleşim ambarı, sürü ve kervan `hold`'dadır | 8.3, 8.4 |
~~~

**Bul:**
~~~
| `save` | `write, load, dump, corrupt, usage` | 3.3 |
~~~
**Sonrasına ekle:**
~~~
| `clock` | `get, set('hh:mm'), next(phase), skip(min), lapse(h), hold(id, hhmm), release(id), keys, stop` | 8.9 |
| `weather` | `state, set, clear, plan, seed, skip, wind, wet, freeze, calm, flash, thunder, hail, strike, fx, sim, calibrate, budget, identity` (`weather.md` §12.8) | 8.10, 9.4 |
| `labour` | `eff, rate, eta, crew, simulate, weather, night, sandbox` | 8.11, 8.12 |
| `hold` | `give, households, tier, speed, hour, place, assign, steward, raid, weather, caravan, census, budget, plots, synth` (`settlement.md` §19) | 8.13, 9.9 |
~~~

**Bul:**
~~~
Yürüyen at saklanmaz: at ahırdayken geçerlidir.
~~~
**Sonrasına ekle:**
~~~

**`menuDiff` ve saat, hava (K20, K22).** `menuDiff` Serbest Gez sürerken de çalışır (`struct.diff`, `refs.compare`). `drawMenuFrame` çizmeden önce (Faz 7'nin `moodT`, `moodTarget` iğnesine ek olarak) `world.setTimeOfDay(null)`, `ctx.campLife?.menuPose(true)` (statik Ozan, Ana ve Baba görünür; ikizler ve yaban hayvanı gizli) ve `world.weather?.identity(0)` çağırır; çizdikten sonra son saat örneğini (`ClockSystem.sample`), oturum pozunu ve hava durumunu geri yazar (post ayarlarını sakladığı gibi). `freeze` dünya saatini ve hava saatini de durdurur. Zerre `uDusk` menüde kurulum değeridir (0); saat kanalı menü anahtarına dek 0'dır. Kabul: Serbest Gez'den çıkmadan 03:00'te `menuDiff` 0; gece oturumundan sonra 0; ıslak zemin, dolu, yıldırım şeridi ve fırtınadan sonra menüye dönüşte 0; yeni oturumun ilk karesi (`uDusk` ve halkın görünürlüğü dahil) menüyle aynı (`time.md` §17, `weather.md` §15 W12).
~~~

**Bul:**
~~~
| 8 | `econ.give`, toplama, `derive`, `pause` sayfaları |
~~~
**Yerine:**
~~~
| 8 | `econ.give`, toplama, `derive`, `pause` sayfaları; `clock.set` altı durak, `clock.lapse(24)`, Serbest Gez 03:00'te ve gece oturumundan sonra `menuDiff`; `weather.set('thunderstorm')` (görünüm kimlik) ve `weather.sim('orkhon', 'camp_spring')`; camp3 emekle (`struct.speed(20)`), Çocuk katılır; `?sandbox=site` her tür, `labour.eta` |
~~~

**Bul:**
~~~
| 9 | `swap('hexi_winter')`, `perf()`: ≤2,74M, ≤323 |
~~~
**Yerine:**
~~~
| 9 | `swap('hexi_winter')`, `perf()`: ≤2,74M, ≤323; `weather.set('heavy_snow')` +≤1 çizim; Serbest Gez'de `weather.set('thunderstorm')`, `strike('near')`, `hail()`, menüye dönüş `menuDiff` 0; `?sandbox=site&hold=1`: Plan Kipi, `hold.synth(5, 'walled')`, `perf()` ≤323, program ≤92 |
~~~

**Bul:**
~~~
| 10 | §4.5 örneği; araba ve Yol Kartı; nöbetçi `?` ve `!`; `?squad=10`; kapı: Gün I + Tipi prototipi |
~~~
**Yerine:**
~~~
| 10 | §4.5 örneği; araba ve Yol Kartı (`lock.weather`); nöbetçi `?` ve `!`; `?squad=10`; Yerleşim Defteri, kervan ×240; kapı: saatli Gün I + Tipi prototipi |
~~~

## 8. §7 Performans bütçesi

### M61. §7 Sahne tablosu

**Bul:**
~~~
| Serbest Gez, üçüncü yurt tam | ≤2,70M | ≤4,06M | ≤511; `Smoke` birleşince ≤481 | ≤3 ms | Hesap: Çocuk +9 çizim, üçüncü yurt ≤+45 ve ≤+248k (`structures.md` §13), araba +6, +9,6k. Bugünü aşan tek sahne; kampta 33 ms kabul |
~~~
**Yerine:**
~~~
| Serbest Gez, üçüncü yurt tam | ≤2,70M | ≤4,06M | ≤511 | ≤3 ms | Hesap: Çocuk +9 çizim, üçüncü yurt ≤+45 ve ≤+248k (`structures.md` §13; K21: Dengiz baştan sona +6 çizim ve +28k, meşale direkleri 0 çizim; en kötü kare +245k, +41), araba +6, +9,6k; K20 gündüz ikizleri ≤+6 (≈+40k), gece içeride uyuyan üç statik −9; K22 fırtına +2 çizim, +96 üçgen. 446 + 9 + 45 + 6 + 6 + 2 = 514 > 511: **`Smoke` birleşmesi (5.2, −30) önkoşuldur** → 484 (kodda `fire.js` `Smoke` bütün bulutları tek çizimde çizer; 8.9 ölçer); düşerse gündüz ikizi 1 (511). Bugünü aşan tek sahne; kampta 33 ms kabul |
~~~

**Bul:**
~~~
| Kışlak, gündüz | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | `act1.md` §15; gölge 2048², iki karede bir |
| Kışlak, gece | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | 18+ nöbetçi: tam ≤16, gerisi kukla |
~~~
**Yerine:**
~~~
| Kışlak, gündüz | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | `act1.md` §15; gölge 2048², iki karede bir; hava: yoğun karda +1 çizim, 6000 nokta (`act1.md` §15 «kar» satırının içinde) |
| Kışlak, gece | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | 18+ nöbetçi: tam ≤16, gerisi kukla; gece evresi saatle; hava +≤1 çizim |
~~~

**Bul:**
~~~
| Kara Boran | | ≤1,2M | ≤220 | ≤3 ms | `act1.md` §10; gölge donuk, sis ≤140 m |
~~~
**Yerine:**
~~~
| Kara Boran | | ≤1,2M | ≤220 | ≤3 ms | `act1.md` §10; gölge donuk, sis ≤140 m; hava +1 çizim (kar noktası), `pinFx` |
~~~

**Bul:**
~~~
| II. Perde, Onluk, bozkır | ≈1,78M | ≈2,5M | ≈240 | ≤2 ms | `army.md` §7.1, kanca |
~~~
**Sonrasına ekle:**
~~~
| II+. Perde, yerleşim, Tanhu Avlusu | ≤2,04M | ≤2,74M | ≤323 (hesap ≈198 + hava 2 ≤213) | ≤3 ms | `settlement.md` §17: ≤4 tam yurt 40 m içinde, ≤48 canlı yapı, `YurtField` 1 + 1 çizim, `KitField` tek `BatchedMesh`, sürü örnekli ≤300; hesap ≈1,92M; `spec.postCuts: true` |
| II+. Perde, ordugâh, Binlik | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | 40 tam çadır, gerisi `TentField` (`world/tent-field.js`, 13.4; 1 çizim + 1 gölge, program eklemez); ordu `army.md` §7.2 Binlik satırı |
| Kum havuzu (`sandbox_site`, `sandbox_hold`) | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | Yalnız geliştirme; `hold.synth(5, 'walled' \| 'moving')` yerleşim satırıyla ölçülür |
~~~

### M62. §7 «Dağılım»

**Bul:**
~~~
JS kare tavanları: A* ≤2 ms ve kare başına ≤1; `NodePools.update` ≤0,5; `StructureManager` ≤0,5; `Squad` ≤2 (Act 1'de ≤0,5); `Stealth` ≤0,5; `Quests`, `Calendar`, `Regions` ≤0,1; `Dialogue` ≤0,1.
~~~
**Yerine:**
~~~
JS kare tavanları: A* ≤2 ms ve kare başına ≤1; `NodePools.update` ≤0,5; `StructureManager` ≤0,5; `SiteSystem` ≤0,1 (≤24 uzak şantiye ≤0,05; toplu benzetim bir oyun günü, 24 şantiye ≤0,3 ms); `Squad` ≤2 (Act 1'de ≤0,5); `Stealth` ≤0,5; `Quests`, `Calendar`, `Regions` ≤0,1; `ClockSystem` ≤0,02 (`setTimeOfDay` 4 Hz, çağrı başına ≤0,03; kimlik `writeLight` ≤0,03, yalnız değişince); `CampLife` ≤0,05; `Weather` ≤0,2 (saat sınırında ≤0,3); `SettlementSystem` kare başına ≤0,1, `clock:hour` başına ≤0,5 (90 hane, 300 işçi, 40 tezgâh), 12 saatlik atlama ≤8 ms; `Dialogue` ≤0,1. Ekonomi servisleri kare başına çalışmaz: `Container.onDawn` şafakta ≤0,2 ms, `Workshop.tick` ve `herdDay` yerleşimin saat bütçesindedir. Atlamanın toplu işi karartma altında ≤60 ms / 15 oyun saati; uzun atlama ve Kronik ≤150 ms / mevsim. Gök Kavisi ve hava simgesi DOM'a ≤4 yazım/sn, yalnız değişince.
~~~

**Bul:**
~~~
Program ≤92 (`structures.md`), kışta `*_w` ile ≤100;
~~~
**Yerine:**
~~~
Program ≤92 (`structures.md`; saat 0 ekler; hava +2: `weather_pts`, `weather_bolt`, menü 56 → 58, Serbest Gez 57 → 59, oluşturucudan sonra 72 → 74; yerleşim dünyası +6: `yurt_field`, `kit_field` ve derinlikleri, `plot_decal`, `field_stalk`; `plan_ghost` yok; yerleşim dünyasının tabanı Faz 13 kabulünde ölçülür), kışta `*_w` ile ≤100 (yerleşimde +2);
~~~

**Bul:**
~~~
hazır ses ≤40 MB (ortam döngüleri 22 kHz mono, sahne başına dilimli ön üretim), canlı ses düğümü ≤40;
~~~
**Yerine:**
~~~
hazır ses ≤40 MB (ortam döngüleri 22 kHz mono, sahne başına dilimli ön üretim; saat ekleri ≤0,5 MB; kampta yerleşik hava döngüleri ≤3,2 MB ve efektleri ≤2,5 MB, cepheyle pişer, fırtınalı akşamda efekt ve ortam önbelleği ≈15,6 MB ≤16 MB (aşarsa «Önce ne kesilir» ses satırı); `torch_post` tek değişken ≈0,35 MB (`d2/audio-delta.md`); yerleşim ve ekonomi ekleri yalnız yerleşim dünyalarında ≈0,9 MB), canlı ses düğümü ≤40 (Serbest Gez fırtınada ≤35);
~~~

**Bul:**
~~~
`mete.glb` 7,2 MB yalnız Yeni Oyun'da.
~~~
**Yerine:**
~~~
`mete.glb` 7,2 MB yalnız Yeni Oyun'da. **Hava parçacıkları ve yıldırım (K22).** Yağış ve sıçrama tek `Points` geometrisinde: ≤6000 nokta (kar 3000, yoğun kar ve tipi 6000, dolu ve sulu kar 1500, toz 600–2000) + 192 sıçrama, 1 çizim, 99 KB VRAM, CPU ≤0,06 ms (karede ≤32 yeni sıçrama); yıldırım şeridi ≤96 üçgen, 1 çizim, ≤0,35 sn görünür; ekran yağışı FINAL'de 0 çizim, GPU ≤0,3 ms; şimşek pozlama ve yarımküre yoğunluğudur, ışık eklenmez; en kötü toplam +2 çizim, +96 üçgen, +2 program, ≈0,1 MB, CPU ≤0,2 ms, GPU ≤0,5 ms. **Yerleşim yapıları (K23).** Zon başına ≤160 yapı kaydı, aynı anda ≤48 canlı `StagedStructure`, ≤4 tam yurt 40 m içinde, `YurtField` 40–220 m örnekli (`closed` ≈3k), ötesi 96 üçgenlik kubbe, `KitField` tür başına ≤400 üçgen; ikisi 1 + 1 çizim, gölgeleriyle 4; yerleşim durumu belleği ≤200 KB. **Kayıt.** Yolculuk ≈83 KB ≤96 KB (`army` ≈20, `world.sites` ≤20, `settlement` ≤14, `camps` ≤4, `world.weather` ≤1, `economy` ≤6, saat ve takvim ≈0,15, öteki ≈18); Serbest Gez +≈40 B saat, hava ≤1 KB.
~~~

### M63. §7 «Önce ne kesilir»

**Bul:**
~~~
| 8 | Etki: `fxFlames` 24 → 12, saplı ok 64 → 32, kar 6000 → 3000, usta 3 → 2 | ≈−40k | Az etki | Yok |
~~~
**Yerine:**
~~~
| 8 | Etki: `fxFlames` 24 → 12, saplı ok 64 → 32, kar 6000 → 3000, usta 3 → 2; ekran yağışı 3 → 2 katman, sıçrama 192 → 96, şimşek dönüşü 4 → 1 | ≈−40k; FINAL ≈−0,1 ms | Az etki | Yok |
~~~

**Bul:**
~~~
| 10 | Kuwahara `paint` 3,1 → 2,4, sonra yarım çözünürlük | 3–5 ms | Boyalı kimlik zayıflar: son çare | Hayır |
~~~
**Sonrasına ekle:**
~~~
| 11 | Ses belleği (kare süresinden bağımsız; kampta fırtınalı akşam önbelleği 16 MB'yi aşarsa, W19): önce `rain_felt` 6 → 4 sn, sonra `hail_bed` yalnız dolulu cephe planda görününce pişer | ≈−0,25 MB | Az etki | ✓ |
~~~

## 9. §8 Kararlar ve uzlaştırma

### M64. Yeni satırlar

**Yer:** §8 tablosunun son satırının altı (bugün 36. satır, «… `menuDiff` 0 piksel |» ile biter; Faz 7 satır eklediyse onların altı). Numaralar sıradaki boş numaradan başlar; aşağıda bugünkü numaralar yazılıdır.

**Bul:**
~~~
Ölçüldü: menü 56, Serbest Gez 57, hasarlı A ile 58; ilk Serbest Gez karesinde 1 derinlik programı kalır; `menuDiff` 0 piksel |
~~~
**Sonrasına ekle:**
~~~
| 37 | K20: 1 gün = 60 dk | İş Puanlı dilim sahneyi güvenceye alıyordu; gerçek saatte sahne kaçabilir | Vakit pencereleri (`earliest`'te çağrı, `latest`'te karartmayla götürme), yalnız iki bekleyiş (`dawn_line`, `ice_story`); günün ana işi uykuyu açar; sinema kesmeleri yalnız ileri | Sahne güvenliği saatte kalır, güneş durmaz (`time.md` §6.3) |
| 38 | K20: ana kamp tam gün döngüsü / §0 kural 8 menü değişmez | İkisi birden | Menü yolu saati hiç okumaz; ana kampın mevsimi menü güneşinden hesaplandı: sapma +7,4223° iğneli (11 Nisan), 47,35°K, 14:46,2; o dakikada saat ışığı menü ışığıdır | Yeni oturum sıçramasız; `menuDiff` 0; `drawMenuFrame` saat, CampLife ve hava kimliği (`time.md` §5.5) |
| 39 | K20: gece / §0 kural 7 ışık eklenmez | Ay ışığı yeni ışık ister gibi | Aynı `DirectionalLight` ay ya da gök yönünden; alacakaranlıkta yön döner, yoğunluk çukura iner; gece göğü kubbede | Program ve ışık sayısı aynı |
| 40 | §8 karar 25: `T` yalnız geliştirmede ışık değiştirir | K20 bekleme ve uyku tuşu ister | `T` her pakette Bekle; geliştirme ışığı `__tanhu.clock` panelinde; HUD ışık düğmesinin yerinde Gök Kavisi | Okuyucusuz tuş kalmaz |
| 41 | K20 ve K22: iki `applyMood` yeniden yazımı (saat ve hava) | Işığın iki sahibi çift çarpım ve menü riski doğurur | Tek hat: saat yalnız `world.lightBase`'i yazar (`setTimeOfDay`), three.js nesnelerini yalnız `world.writeLight()` yazar (8.9 kimlik, 9.4 `WeatherView.compose`); menü yolu `applyMood` değişmez; `applyMoodMix` yok | Hava çarpanı bir kez; menü yolu aynı (`d2/core.md` §1.9) |
| 42 | K22 hava görünümü | Görünüm ışık ve program bütçesine girmeli, menü değişmemeli; Kuwahara boyası ince yağmur çizgisini siler | Ekran yağışı FINAL'de (0 çizim); kar ve dolu tek nokta çizimi; şimşek pozlama ve yarımküre yoğunluğu; ıslaklık paylaşılan uniform; menü, Yeni Oyun, oluşturucu ve `home`'da kimlik | +2 çizim, +2 program; §0 kural 7 ve 8; ölçüm W12–W16 |
| 43 | K21, `structures.md` §10.3, §11.6 | Faz 6 süreyi saniye ve krediyle sayıyordu (camp3 590 sn, yardımla 283 sn; kredi kalan süreyi 3 kat eritiyordu) | Emek yasası `game/labour.js`: adımın `work`'ü İD, oran ekipten (`eff(W) = min(W, 10 · (1 − 0,9^W))`, el sınırı, tek el yalnız tündükte); `StructureState.advance(wm)`; kredi kalkar, Çocuk adımın fiilini yaptıkça yarım el sayılır; Kışlak dilim kipi kalkar; inşaat ışıkta gece de sürer | Kurulum, onarım, taşıma ve söküm tek birimle; yerleşim ve ordu aynı yasayla sayılır (`d2/core.md` §2) |
| 44 | K23 ve K24: ekonominin `EconomySystem`, `Stores`, `Herd`, `Caravan` taslağı / yerleşimin sürücülüğü | Aynı ambar, sürü ve kervanı iki alan sürecek, kaydı iki blok tutacaktı | Ekonomi saf servis verir (`Container`, `Workshop`, `herdDay`, `transfer`, `armyShare`, `rolloverYears`, `SupplyLedger` ambar kipi); yerleşim sürer (`StorePool`, `production`, `CaravanBook`, Kronik). Kişisel kaplar `economy`'de (41), yerin kapları, tezgâh, sürü ve kervan `settlement`'ta (77), Erzak Ambarı `camps`'ta (92), şantiye yığını `world.sites`'ta (76) | Tek sürücü, tek kayıt sahibi; yeni `GameSystem` yok (`d2/core.md` §6.1) |
| 45 | K26: beş d2 alanı aynı dikişlere dokunur | Işık hattı, kayıt satırları, paket numaraları, kimlikler iki ya da üç taslakta farklı yazıldı | Her dikişin tek sahibi `d2/core.md` §6'dadır; `architecture.md` değişikliği defterin uygulanmış biçimi olan `d2/architecture-delta.md` ile tek seferde işlenir | Birleşmede kayıp ve çift sayı yok |
| 46 | §0 kural 1: paket dosyaları ayrık / K26 paket listesi | Saat, hava ve ekonomi aynı fazda `cond.js`, `effects.js`, `cine.js`, `schema.js`, `check-data.mjs`'e; settlement ve weather `keymap.js`, `node-store.js`, `nav.js`'e; yapı görünüşü ve Kışlak yapısı `structure.js`'e dokunuyordu | 8.14 (koşul, etki, sinema, doğrulama) ve 9.10 (K23 yapı görünüşleri, `structure-kits.js`, `site-pad.js`) eklendi; `keymap.js` yalnız 8.9'da (`wait`, `build_mode`; `rotate` yok, Plan Kipi Q/E), `applyTaken` 8.3'te, `canPlace` 9.2'de, `mounted.js` 8.10'da, kamp spec'i 8.9'da; `freeroam.js` Faz 8 ve 9'da `L`'nin | Faz içinde iki pakete düşen dosya yok; `CONTRACT-REQUEST` gerekmez |
| 47 | `d2/time-delta-architecture.md` 11.7 satırı: Zor'da buz saati 05:10 | K20: buz saati her zorlukta 06:40 | Buz saati 06:40; Zor Amaga 21:30, Düğüm 21:40; Hikâye 05:45 bekleyişi | «Şafakta buza» doğru kalır; `decisions.md` kazanır |
| 48 | `d2/core.md` §1.7: `daylight.nightClass(abs, fx, lit)` / §0 kural 5 saf modül | `abs` tek başına enlem ve ay yaşı taşımaz | Saf `daylight.nightClass(level, lit)` ve `lightLevel(...)`; çekirdeğin yüzü `worldClock.nightClassAt(abs, fx, lit)` (DayInfo ve `moonAge` ile) | Sayı ve eşik aynı; saf modül sınanabilir |
| 49 | K24 kap yüzü: `transfer(from, to, ref, n)` ile `transfer(from, to, items, { filter })`; `inventory.site(id)` | İki imza, kaydı başka blokta olan kap | `transfer` tek eşya, `transferAll` liste ve süzgeç; `inventory.setResolver` şantiye yığınını ve yerin kaplarını çözer, kaydetmez | Tek `Container`, tek kayıt sahibi |
| 50 | K21, K23 kum havuzu / §0 kural 8, K3, K6 | Kum havuzu her türü ve yerleşimi gösterir; ana kampa dokunulmamalı | Kum havuzu ayrı dünya spec'idir: `sandbox_site` (8.12), `sandbox_hold` (9.9); `?sandbox=site` | Kamp, menü ve Serbest Gez aynı kalır |
| 51 | K20 bloklayan diyalogda saat durur / §3.15 «`scene`: dünya akar» | İkisi birden | Dünya karesi akar (kişiler kıpırdar, ışık ve hava devinir), dünya saati durur (`pause('dialogue')`); `walk` ve `flow` kiplerinde saat akar | Konuşma zaman yemez; sahne canlı kalır |
| 52 | K23: hikâye açılışı II. Perde / §5'te II. Perde fazı yok | Altyapı I. Perde fazlarında (8.11–8.13, 9.9, 9.10, 10.10), dünyalar ve açılış hiçbir fazda değildi | Faz 13 (taslak): `tanhu_ordu`, `whistle_field` dünyaları ve II. Perde açılışı; kapsamı `L` Faz 12 sonunda kesinleştirir | I. Perde planı ve K11 kapısı değişmez |
| 53 | K26: birleştirme defterleri (doğrulama V11, V26) | K26'nın eski metni, eski defterlerin bantları ve bu dosya üç ayrı işleme sırası veriyordu | `architecture.md`, `structures.md`, `audio.md` yalnız `d2/architecture-delta.md`, `d2/structures-delta.md`, `d2/audio-delta.md` ile işlenir; eski defterler ve on beş alan deltası «Yerini aldı» bandıyla iz | İkinci geçiş yok; her «Bul» bir kez tutar |
| 54 | K21 «aile bekler» / §0 kural 1 dikiş başına tek sahip (V33) | `CampLife` (8.9) ve `BuilderSystem` (8.11) kuralı ayrı ayrı uyguluyordu | Sahip `BuilderSystem`: `camp3:family_wait { until }`, `camp3:hearth_dawn`; `CampLife` yalnız uyar | Olayla bağ, dosya paylaşımı yok |
| 55 | K23 kum havuzu / K11 kapısı (V31) | II–VI'ya özgü `court`, `chronicle`, `raids`, `caravans`, `camps`, yerleşim müziği ve Yerleşim Defteri kapının önündeydi | Faz 8–10'da yazılabilir ama faz çıkışını ve kapıyı bekletmez; bitmezse Faz 13'te bitirilir | Dikey dilim önce sınanır |
~~~

### M65. §8 karar 25: K20 notu

**Bul:**
~~~
Kitapta ışık ayarı yok, okuyucusuz ayar da yok; sınama aracı oyuncuya sızmaz |
~~~
**Yerine:**
~~~
Kitapta ışık ayarı yok, okuyucusuz ayar da yok; sınama aracı oyuncuya sızmaz. K20'de kalktı: §8 karar 40 |
~~~

## 10. §9 Doğrulama durumu

### M66. Yeni madde ve açık risk

**Bul:**
~~~
- **Açık risk:** `Smoke` birleşmesinde çizim sırası (5.2).
~~~
**Önüne ekle:**
~~~
- **K20–K24 deltası (2026-11-03, `d2/architecture-delta.md`):** paket dosyalarının faz içi ayrıklığı betikle denetlendi (Faz 8: 14 paket + `L`, Faz 9: 10 paket + `L`, Faz 10, 11, 12, 13); her «Bul» metni bu belgenin 2026-11-03 sürümünde bir kez bulundu; yeni sözleşmeler (§3.23–§3.27) alan belgelerinin arayüz taslaklarından ve `d2/core.md`'den yazıldı. Hiçbir yeni arayüz koşulmadı; sayıların doğrulaması alan belgelerinin «Doğrulama durumu» bölümlerindedir.
~~~

**Bul:**
~~~
`menuDiff` ile yakalanır; düşerse değişiklik geri alınır, istek 2 kazanır.
~~~
**Yerine:**
~~~
`menuDiff` ile yakalanır; düşerse değişiklik geri alınır, istek 2 kazanır. K20–K22 Serbest Gez bütçesi (514 → 484) bu birleşmeye dayanır; düşerse gündüz ikizi 1'e iner (511).
~~~

## 11. `contract-requests.md`: kapanan ve eklenen satırlar

`contract-requests.md` Faz 7 boyunca düzenlenmez; `L` birleştirmede aşağıdakileri işler. Satırlar başlarındaki metinle anılır.

**Kapananlar** (bu plan sahibini ve yerini verir; ilgili paket bitince `[x]`):

| Satır | Kapatan |
|---|---|
| (pkg 0.5) «src/game/supply.js, provide `ctx.supply.get(id)`» | 8.4 `LEDGERS` (`get`, `register`, `bind`); `L` `ctx.supply = LEDGERS`; `ledger` op'u yer alır (8.14, M39) |
| (pkg 0.7) «the §3.5 block table has no owner for `economy.sled` and `economy.v`» | M25: `.sled` sıra 41, `game/inventory.js`; `economy.v` blok sürümüdür (`registerBlock(…, { v: 2 })`, `blockV`) |
| (pkg 3.6) «the `rain` layer stays silent until `setLayer('rain', g)`; the weather owner (Faz 9) calls it» | 8.10 `WeatherSystem` (Faz 8'e çekildi; M27, `weather.md` §10.3) |
| (pkg 6.5, 8.x) «`node_camp_logs`: the log pick-up at the woodpile…» | 8.3 `node_camp_logs` türü; 8.11 `CHILD_HELP.help_log` ona taşınır |
| (L, 9.1) «src/world/specs/index.js has no `hexi_winter` loader yet» | 9.1 `specs/index.js`'in sahibidir (`hexi_winter`, `sandbox_hold`) |
| (smoke, structures) «`StructureState.rep` (the repair in progress) is not in `toJSON`» | 8.11: `StructureState.toJSON` `v: 2` süren onarımı `rep` (İD) olarak yazar; değişim ve yükleme onarımı kaldığı yerden sürdürür |

**Kapsamı değişenler** (açık kalır, metne not düşülür):

| Satır | Not |
|---|---|
| (pkg 6.3, 10.8) «the journey block `world.structures` (order 73) fills only in `spec.journey` worlds» | Kışlak Yeni Yurdu `world.sites`'tadır (76; 8.12, 9.1); `world.structures` yalnız senaryo yapılarını tutar (10.8) |
| (L) «src/app/sounds.js, Faz 9 adds the winter surface…» | Faz 8'de evre ortamı ve hava verisi, Faz 9'da hava döngüleri, kış ve yerleşim ortamı `L`'nindir (M27, M51, M52) |
| (pkg 6.5, 8.3) «`carry('haul')`» | 8.3'te kalır; 8.11 ustaları ve 8.12 şantiye işçileri kullanır |
| (pkg 0.5) «src/game/journey.js, `CondCtx.get` must follow the path table» | 10.8; yeni yollar `hour`, `dark`, `moon`, `phase:`, `beat:` (M39, M53) |

**Eklenenler** (birleştirmede yazılır):

- [ ] (L, 8) src/app/app.js: `app.wallDt` (kırpılmamış, ≤0,25 sn); `ctx.worldClock`, `ctx.calendar`, `ctx.campLife`, `ctx.weather`, `ctx.sites`, `ctx.supply = LEDGERS` ve `LEDGERS.bind(bus, { diff })`; `inventory.setResolver`; `?sandbox=site` (M17, M18, M51).
- [ ] (L, 8) src/app/systems.js: `clock` 15, `weather` 22, `sites` 61, `camp_life` 81; Faz 9'da `settlement` 64 (M28).
- [ ] (L, 8) src/app/devtools.js: `drawMenuFrame` `world.setTimeOfDay(null)`, `ctx.campLife?.menuPose(true)`, `world.weather?.identity(0)` ve geri yazım; `freeze` dünya saatini ve havayı durdurur; paneller kendi kaydını yapar (M60).
- [ ] (L, 8) src/app/states/freeroam.js: `T` → Bekle; `toggleMood`, `MOOD_*` kalkar; `roam.clock`, `roam.weather`, `mood` göçü; `endSession` geri yüklemesi; 2,4 / 1,7 sn karışım (M14, M51).
- [ ] (L, 8) src/ui/hud.js: geliştirme ışık düğmesi (`moodBtn`, `setDusk`, `DUSK_ABOVE`) kalkar; Gök Kavisi `tr` yuvasına (M44).
- [ ] (L, 8, 9) src/app/sounds.js: evre ortamı (`spec.audio.ambience` evre listeleri), `ctx.weather.audio` birleşimi, kış ve yerleşim dünyalarının ortamı (M27).
- [x] (baş tasarımcı, 2026-11-03; 8.11 okur) d2/labour-model.json v2: `d2/core.md` §1.8, §2.2–§2.3 adım emekleri (tek el 1.440, ekip 1.376), tek el yalnız `y_tunduk`, el sınırları, gece sınıfı (`dayLevel` 0,5, `dimLevel` 0,25, `moonSeen` yok), `rawWork`, bütün tür tabloları (`d2/structures-delta.md` §4.6), `dayCapacity`, `scenarios` (camp3, Kışlak yaması).
- [ ] (ekonomi alanı, **8.2 ve 8.4 başlamadan**) tools/econ-sim.mjs ve d2/econ-model.json birlikte K24'e: `dayCapacity`, yeni kademe günleri (T2 2,5–7), hazır yük 1 / 6 / 12 / 22 / 17, yerleşik atlı ve düz %10 Ordu Payı (kışın ×0,1), `preserveLoss` 0,65, `sogumLoss` 0,35, belirli ganimet (adlı silah satırları silinir), `banner_pole` 40 İD, Demirci Ocağı hurda seçeneği, armağan ve gelen hanenin azığı ve kırkımı, Kâhya'nın av kolu ve `K_tok`, garnizonlu baskın kaybı, Surlu tarlası ve kulesi, Göçer ×1,2, mal varlık sınaması (perde ve mevsim), `weather-model.json` ve `labour-model.json` okuma, perde günleri ve Kronik stoğu; `--strict` 0 işaret (`d2/core.md` §5.9). Bugünkü 0 işaret K24 öncesidir.
- [ ] (hava alanı, 8.10 ile) d2/weather-model.json: W26 üreteci sabit tohumla dosyayı yazar, sınama mutlak toleransla yalnız `steppe_south` ve `gobi`'yi denetler; dosya ekonominin son `--strict` koşusundan önce yazılır (`weather.md` §15 W26).
- [ ] (L, 12.4) tools/check-budget.mjs: Serbest Gez fırtınası, yerleşim, ordugâh, Kışlak yoğun kar eşikleri (M56, M61).
- [ ] (L, 13) src/world/specs/index.js, src/world/specs/zones.js, src/story/act2/index.js, src/story/vo-lines.js `ACTS`: II. Perde dünyaları ve dizini (M56).
- [ ] (13.4) src/world/tent-field.js: `TentField` sahibi 13.4'tür (Faz 13); `KitField` deseni, tek örnekli çizim + gölge, çadır başına ≤200 üçgen, program eklemez (yerleşim dünyasının `kit_field` programını paylaşır); Binlik ordugâhı ≤323 çizim (§7 satırı). `army.md` §7 T3 kartı ve `settlement.md` §10.1 bunu okur.
- [ ] (L, 8.9 ve 8.11) camp3 «aile bekler»: `BuilderSystem` `camp3:family_wait { until }` ve `camp3:hearth_dawn` yayar (§3.1), `CampLife` yalnız uyar; olay §3.1 tablosuna 8.11'le girer.

## 12. Bu dosyanın doğrulaması

- **Okundu:** `decisions.md` (K1–K26); `d2/core.md` tamamı; `time.md` §0, §1, §6, §7, §8, §12–§17; `weather.md` §3, §5, §6, §8–§12, §15; `settlement.md` §3, §4, §6, §9–§21; `d2/labour.md` §6, §11–§15; `d2/economy.md` §1, §4, §5, §13–§17; altı `d2/*-delta-architecture.md` ve `d2/core-delta-structures.md`, `d2/core-delta-audio.md`, `d2/*-delta-audio.md`, `d2/settlement-delta-structures.md`; `architecture.md` §0–§3, §4.3, §4.5, §5–§9; `contract-requests.md` açık satırları; kodda `src/game/cond.js`, `src/game/effects.js` (`ledger`, `work` op'ları), `src/world/structure.js` (`_build`, `_look`), `src/world/fire.js` (`Smoke` tek çizim), `test/index.js`.
- **Betikle denetlendi (oturumun geçici dizininde):** bu dosyadaki her «Bul» metni `architecture.md`'nin 2026-11-03 sürümünde tam bir kez geçiyor (Aralık çapaları dahil); Faz 8, 9, 10, 11, 12, 13 tablolarında bir dosya aynı fazda iki pakete düşmüyor, `L` satırının dosyaları o fazın paketlerinde yok.
- **Doğrulama turu (2026-11-03, `d2/core.md` §7.1):** M51 (8.4, 8.9 ≤509, 8.10 W26, 8.11 sayıları ve «aile bekler» olayları, 8.12, 8.13, paket önkoşulları), M52 (9.9), M53 (10.10 `hold-ledger.css`), M55 (11.6 yaması 07:00–08:42, 11.7 `hud/clock.js`), M56 (13.4, 13.5), M57, M61–M64 ve §11 güncellendi; yeni «Bul» metinleri dahil 184 «Bul» bloğu `architecture.md`'nin 2026-11-03 sürümünde tam bir kez geçiyor (betikle); Faz 13'te dosya ayrıklığı korunur (13.4 `world/tent-field.js` ve `story/act2/camp/`, 13.5 `story/act2/oba/`).
- **Yapılmadı:** kod; `architecture.md`, `structures.md`, `audio.md`, `contract-requests.md` düzenlenmedi (Faz 7 sürüyor); tarayıcı ölçümü; sayıların yeniden hesabı (hepsi `d2/core.md` ve alan belgelerinden).
