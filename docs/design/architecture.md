# Kod Mimarisi ve Modül Sözleşmeleri / Code Architecture and Module Contracts

> **Prototip belgesi (K29, K31, K64; 2026-11-04).** Bu belge Three.js prototipinin (`~/Code/tests/tanhu-programatic-test`) mimarisidir. Oyun Godot 4.7 ile `game/`'de yapılır: Godot'nun uygulama planı `godot.md`'dir, işleri sitenin Yol Haritası'ndadır (`/roadmap`, veri `docs-app/content/progress.json`).
>
> **Belge üstünlüğü (#65, K31).** `decisions.md` > `d2/core.md` > alan belgeleri (`act1.md`, `story.md`, `economy.md`, `structures.md`, `settlement.md`, `progression.md`, `travel.md`, `time.md`, `weather.md`, `army.md`, `survival.md`, `audio.md`, `fauna.md`, `companions.md`) > `godot.md`. (2026-11-04, E6.4: liste K31'e göre `companions.md` eklenerek düzeldi.) Bu belge ve `contract-requests.md` yalnız prototip içindir; prototipte de sayı için alan belgesi, arayüz için bu belge kazanır. Bu belgeyi alan belgelerinin üstüne koyan eski okuma (`d2/core.md`'nin eski sırası ve sitenin yazım kuralı) K31 ile kalktı.
>
> **Belge prototipin koduna göre durur.** Bu turda değişen kurallar prototipe ve altın değer fikstürüne girmez (K29): K50'nin inşaat eğrisi `T(n)`, K60'ın kopuzu ve K67'nin tek takvimi burada eski biçimleriyle (`eff(W)`, dombra, `roam.clock`) kalır; geçerli kural alan belgesindedir. Prototipte Faz 0–7 bitti ve doğrulandı (§9); Faz 8'in A dalgası kodda, incelemesi ve tarayıcı dumanı kayda geçmedi; B dalgası ve Faz 9–13 yazılmadı. §5'in fazları Godot'da `godot.md` §9'un g0–g9 sırasına ve Yol Haritası'nın fazlarına döner; Godot'da iş birimi Yol Haritası maddesidir (K29, K69). Açık sözleşme istekleri `contract-requests.md`'de dondu ve A ya da B diye işaretlendi (K64).
>
> **Bu turda düzelen yerler.** §2.7 kampa dönüşün iki süresi (#67, K64); §5 Faz 8 ve §8 karar 58 paket sayısı (#62, K64); §7 bütçe satırları (#63, #66, K63; Godot bütçesi `godot.md` §7'dedir); §3.6, §7 ve §8 karar 31 ses tablosu (K59); §8 karar 19 (K39); §9 açık risk (K63).
>
> **E6'da (2026-11-04, K87) not düşülen yerler.** Prototipin kodu bu turda değişmez; geçerli kural notun gösterdiği belgededir. §3.1 ve §3.23 «aile bekler» (K50, K83: aile 23:00'e dek ateş başında, aşama ≥4 ise ilk dumana dek); §3.6 konuşmada kısma (K78: Godot'da durum türüne göre); §4.4 ve §6.2 seslendirme tavanı (K61: tavan yok); §5 8.9b'nin «≤509 çizim» çıkışı (K63); §9 açık risk (K64: eskidi).

Baş mühendis belgesi. Çok sayıda mühendis bu belgeye bakarak, git olmadan, ayrık dosyalarda paralel çalışır. Kimlikler İngilizce, belge Türkçe, oyun içi metinler her yerde TR / EN. Birim metre ve saniye; x doğu, z güney, kuzey −z; `heading = atan2(dx, dz)`: 0 güney, π/2 doğu, π kuzey (`Horse.root` ile aynı). Oyun kuralları, sayılar ve metinler alan belgelerindedir: `act1.md`, `story.md`, `progression.md`, `structures.md` (K21 emek yasası §2.4, şantiye §2.5), `economy.md`, `survival.md`, `travel.md`, `army.md`, `time.md`, `weather.md`, `settlement.md`, `audio.md`, `fauna.md` (K31), `docs/research/menu-spec.md`, `docs/research/groups-research.md`, `docs/research/code-audit.md` (aşağıda "denetim"). Belgeler çeliştiğinde `decisions.md` kazanır; K20–K26'nın kesişen sayıları `d2/core.md`'dedir ve bu belgeden önce gelir. Bu belge yalnız **kodun nasıl parçalanacağını ve parçaların birbirine nasıl değeceğini** bağlar. Sayı için alan belgesi, arayüz için bu belge kazanır.

## 0. Çalışma kuralları

| # | Kural | Neden |
|---|---|---|
| 1 | Her mühendis yalnız paketinin §5'te yazılı dosyalarına dokunur. Başka dosya gerekiyorsa o dosyayı değiştirmez; dönüşünde `CONTRACT-REQUEST: <dosya>, <ne>` satırı yazar, kararı baş mühendis (`L`) verir | Git yok, birleştirme yok: aynı dosyaya iki el değerse biri kaybolur |
| 2 | `L` işaretli dosyaları yalnız baş mühendis düzenler: `index.html`, `package.json`, `package-lock.json`, `src/main.js`, `src/app/app.js`, `src/app/systems.js`, `src/app/devtools.js`, `src/app/world-swap.js`, `src/ui/style.css`, `src/story/act1/index.js`, `src/story/act2/index.js` (Faz 13), bu belge | Tek entegrasyon noktası |
| 3 | Bir faz bitmeden sonraki başlamaz. Faz başında `L` proje anlık görüntüsü alır: `tar czf "$TMPDIR/tanhu-p<N>.tgz" --exclude node_modules --exclude .env --exclude dist .` | Geri dönüş tek yol budur |
| 4 | Kayıt uzantı noktaları dosya çakışmasını önler: dizgeler `src/i18n/strings/<alan>.js`, CSS `src/ui/css/<alan>.css`, jest `src/character/gestures/<alan>.js`, efekt reçetesi `src/audio/sfx/<alan>.js`, HUD parçası `src/ui/hud/<ad>.js`, oyun sistemi `GameSystem`, kayıt `save.registerBlock`, test paneli `devtools.register`. `game.js`, `rig.js`, `hud.js`, `style.css`, `devtools.js` özellik eklemek için düzenlenmez | Denetimin çok elli dosyaları bunlardır |
| 5 | **Saf modül** (§6.1 listesi) `three`, `document`, `window`, `import.meta.env`, `import.meta.glob`, CSS içe aktarımı kullanmaz; göreli içe aktarım `.js` uzantısıyla yazılır. `node tools/check-pure.mjs` denetler | `node:test` ve `tools/voices.mjs` bunları düz Node'da açar |
| 6 | Yeni npm bağımlılığı yok. Tek istisna `L`'nin Faz 3'te ekleyeceği `@fontsource/alegreya` ve `@fontsource/alegreya-sc`; kurulamazsa `eb-garamond` kalır | `menu-spec.md` yazı tipleri |
| 7 | Çalışma zamanında ışık eklenmez, silinmez (85 program ışık sayısına bağlı). Yeni `paintMaterial` kancası her zaman yeni `key` alır; kışta `world.matKey(base)` kullanılır | Denetim §b, §c |
| 8 | Menü sahnesi değişmez (istek 2). Mevcut kamp kodunda yapılan her değişiklik §6.3 `menuDiff` ile sınanır: ≤32 piksel, ≤16/255; çim dahil ≤%0,1 | `structures.md` §17 |
| 9 | Kod biçimi mevcut koddur: 2 boşluk, noktalı virgül, tek tırnak, yorumlar Türkçe, GLSL `/* glsl */`. Her dosya tek cümlelik Türkçe başlık yorumuyla başlar. Görünür metin koda gömülmez | Tutarlılık, denetim §d |
| 10 | Kare başına ayırma yapılmaz: `Vector3` ve dizi sınıf alanında tutulur. Olay yükü kare başına üretilmez | Bütçe §7 |
| 11 | Görsel kotası açıktır: `tools/imagegen/gen.sh --model gpt-6-sol` yalnız `L` tarafından, sırayla çalıştırılır. Simge ve resim gerekirse paket `CONTRACT-REQUEST: image, <ne>` yazar; o arada kodla çizilmiş yer tutucu kullanır, eksik portrede kutu boş kalır. Tanhu 3 varlığı yine alınmaz, yalnız `public/models/mete.glb`; var olan `public/ui/logo.webp`, `creator_bg.webp`, `portraits/*` kullanılır | `decisions.md` K14; istek 8, 15; kullanıcı hesap değiştirdi |

**Sözlük.** *Sistem*: `Game`'e takılan `GameSystem`. *Durum*: `App`'in `StateId`'si. *Bağlam*: girdi yığınındaki `InputCtx`. *Blok*: kayıttaki yol. Bu dört sözcük başka anlamda kullanılmaz.

## 1. Hedef klasör ağacı

`L` baş mühendis, `E` var olan dosya düzenlenir, işaretsiz yeni dosya. Sağda tek sorumluluk. Sağdaki `→N.M` ilk yazan paket.

```
index.html                         L E  lang başlangıcı, #view, #ui
package.json                       L E  "test": node --test "test/*.test.js" (K18), yazı tipleri
src/main.js                        L E  Yazı tipi ve CSS içe aktarımı, new App().start(); başka iş yok
src/app/
  app.js                           L    Tekil servisleri kurar; kare döngüsü, goTo, resize, dinamik çözünürlük
  systems.js                       L    GameSystem örneklerini kurar ve game.systems'e ekler
  devtools.js                      L    window.__tanhu: step, freeze, shot, menuDiff, panel kaydı
  world-swap.js                    L    dispose → build → compileAsync → setWorld sırası
  sounds.js                        L    SoundSystem: adım, toynak, ahırdaki atlar; app:state ile kamp ortamı ve ön üretim (Faz 3); evre ve hava birleşimi (K20, K22)
  camera-blend.js                  →1.6 İki kamera arasında konum, dönüş ve FOV karışımı
  menu-camera.js                   →3.5 Menü kamerası: taban poz, sürüklenme, paralaks, geri uçuş
  states/
    base.js                        →1.6 AppState taban sınıfı, FADE tablosu
    boot.js                        →1.6 Renderer, doku, ayar; dil varsa epigrafa, yoksa language'a
    language.js                    →3.4 İlk açılış dil seçimi; ilk jest, ses kilidi
    epigraph.js                    →3.4 Mete'nin sözü; dünya kurulumu bunun altında yürür
    menu.js                        →3.5 Ana menü ve canlı kamp çizimi
    freeroam.js                    →1.6 Serbest Gez: Çocuk, kamp, HUD
    newgame.js                     →5.3 Ozan, kamera, anlatıcı sineması
    creator.js                     →1.6 Karakter oluşturucu sahnesi ve ekranı; 5.6'ya dek Hero önizlemesi, ilk girişte dinamik içe aktarır
    play.js                        →8.8 Yolculuk oyunu: bütün sistemler, sinema ve diyalog üst kipleri; 10.8 tamamlar
    map.js                         →1.6 Atlas
    pause.js                       →3.5 Kitap menüsü, Heybe, Defter, Görevler; 0 çizim
    travel.js                      →10.5 Uzak Yol: atlas şeridi, arkada dünya kurulumu
    home.js                        →11.9 Perde sonu: Çocuk, bahar, Mete atla gelir, «II. Perde yakında» kartı
src/core/
  bus.js                           →0.1 Olay veri yolu
  store.js                         →0.1 localStorage sarmalayıcı, bellek yedeği
  clock.js                         →0.1 Oyun saati, elle kare kipi, sinema saati
  settings.js                      →0.1 Ayar deposu
  settings-schema.js               →0.1 Ayar anahtarları, varsayılanlar; 8.9 game.clockShow, 9.8 a11y.flashes
  keymap.js                        →0.2 Eylem → tuş tablosu; 8.9 wait (T), build_mode (P), mood kalkar
  input.js                         →0.2 Girdi yönlendirici, bağlam yığını, DOM dinleyicilerinin tek sahibi
  timeline.js                      →0.4 Saf zaman çizelgesi
  ease.js                          →0.4 Yumuşatma işlevleri
  post-profiles.js                 →1.5 Adlandırılmış son işleme profilleri
  post.js                        E →1.5 applyProfile, MSAA ve bloom kademeleri
  paint-material.js              E →1.5 Program anahtarına kanca karması; 9.4 hava uniform'ları (uWet, uWetFx, uCloudPhase, uFront, uWindK, uWindPhase)
  geo.js                         E →6.1 mergeStaged
  shapes.js                      E →6.2 arc
  math.js, textures.js                  Değişmez
src/i18n/
  index.js                         →0.3 t, L, setLang, addStrings, bindText
  format.js                        →0.3 Sayı, tarih, süre biçimi
  load.js                          →0.3 import.meta.glob ile strings/*.js yükler (saf değil)
  strings/game.js                  →1.1 İstem ve yer adı dizgeleri
  strings/atlas.js                 →1.2 Harita arayüzü
  strings/hud.js                   →1.3 HUD
  strings/shell.js                 →1.4 Yükleyici, onay, kısa bildirim
  strings/world.js                 →1.7 Yükleme adımları, yapı ve at adları
  strings/menu.js                  →3.1 Ana menü
  strings/book.js                  →3.2 Kitap sayfaları, ayarlar, tuşlar
  strings/save.js                  →3.3 Kayıt paneli
  strings/epigraph.js              →3.4 Epigraf, dil seçimi
  strings/geo.js                   →4.1 geography.js satırları
  strings/creator.js               →5.6 Oluşturucu
  strings/cine.js                  →L Sinema atlama ipucu (Faz 5)
  strings/structures.js            →6.5 Yapı adımları, usta sözleri
  strings/skills.js                →8.1 Beceri ad, açıklama, ipucu
  strings/items.js                 →8.2 Eşya adları
  strings/economy.js               →8.3 economy.md §13'ün bütün anahtarları: düğüm, heybe, aktarma paneli, Terazi, tezgâh, sürü, Kış Hesabı
  strings/survival.js              →8.5 Ateş, yemek, av

  strings/time.js                  →8.9 Evre, Bekle, Uyu, Dinlen, Çalış, Gök Kavisi, kayıt kartı
  strings/weather.js               →8.10 Hava türleri, işaretler, kişi satırları, kilit ve ret satırları
  strings/sites.js                 →8.12 Şantiye: yerleşim ve bekleme nedenleri, ekip, bitiş sözcüğü
  strings/settlement.js            →8.13 Yerleşim, ordugâh, Plan Kipi, Defter, kademe kartları
  strings/travel.js                →10.5 Yol Kartı, kilitler, sohbet
  strings/army.js                  →10.6 Buyruk, birlik
  strings/quests.js                →10.7 Görevler ekranı çerçeve metinleri
src/audio/
  engine.js                        →3.6 AudioContext, veri yolları, kilit açma, ducking, dinleyici
  scheduler.js                     →3.6 setInterval(100 ms), 0,4 sn ileri planlama
  phrases.js                       →3.6 Saf ezgi üreteci (tohumlu, nota listesi döndürür)
  music.js                         →3.6 MusicDirector: durum, katman, geçiş
  music-states.js                  →3.6 Müzik durumu tablosu; 8.9 camp_night; 9.9 hold, hold_night, court, muster
  instruments/dombra.js            →3.6 İki telli Karplus-Strong
  instruments/kobuz.js             →3.6 Kobuz, morin huur
  instruments/throat.js            →3.6 Boğaz dronu, kargıra, sıgıt
  instruments/kaval.js             →3.6 Kaval
  instruments/drums.js             →3.6 Çerçeve davul, tüngür
  instruments/jaw.js               →3.6 Ağız kopuzu
  instruments/choir.js             →3.6 Koro
  instruments/bell.js              →3.6 Tunç çan, FM
  sfx.js                           →3.7 Efekt motoru: OfflineAudioContext, önbellek, ses sınırı; sfx/*.js'i glob'lar
  sfx/ui.js, foot.js, weapon.js, structure.js, gather.js, horse.js, world.js, travel.js  →3.7 Reçeteler, alan başına; structure.js 8.11 torch_post
  sfx/time.js                      →8.9 Saat ekleri: meal_call, night_drum, wait_lapse, wake
  sfx/economy.js                   →8.4 Tezgâh, kap, ganimet: felt_roll, bellows, anvil, adze, tan_scrape, shear_snip, milk_pail, store_open, cart_unload, loot_search, craft_done
  sfx/weather.js                   →9.8 Yakın ve uzak gök gürültüsü, uyarı vızıltısı, bora, damla, dolu tıkırtısı, sağırlık
  sfx/settlement.js                →9.9 Plan Kipi, hane, kervan, kademe, Şafak Selamı, alamet, toplantı
  ambience.js                      →3.7 Ortam döngüleri, çapraz geçiş; 9.8 hava ve yerleşim döngüleri
  spatial.js                       →3.7 PannerNode havuzu, equalpower, inverse
  voice.js                         →3.7 ElevenLabs dosyaları (K28), eksikte altyazı süresi, preload
src/story/
  schema.js                        →0.8 Görev, diyalog, sinema doğrulayıcı (saf)
  cast.js                          →5.5 Konuşmacı, voice_id, portre, ses bileşeni
  vo-lines.js                      →5.5 voLines(): bütün vo:true satırları; tools/voices.mjs okur
  act0/index.js                    →5.5 Giriş içeriği dizini
  act0/bard-verse.js               →5.5 Ozanın dörtlüğü
  act0/narrator.js                 →5.5 Anlatıcı giriş satırları
  act0/cine-newgame.js             →5.5 Yeni Oyun sinema verisi
  act1/index.js                    L    day1..side, end dizinlerini içe aktarır
  act1/schedule.js                 →11.1 NPC programı (act1.md §5)

  act1/days.js                     →11.1 Hikâye günleri: ana iş, vakitler, kesmeler (time.md §9.2)
  act1/guards.js                   →11.1 Son Gece nöbeti, fenerler
  act1/regions.js                  →11.1 Bölge, rütbe, Kızıl Kazık hattı
  act1/jobs.js                     →11.1 İş Tahtası
  act1/day1/{index,quests,dialogue,cine}.js   →11.2 Gün I
  act1/day2/{index,quests,dialogue,cine}.js   →11.3 Gün II
  act1/day3/{index,quests,dialogue,cine}.js   →11.4 Gün III
  act1/day4/{index,quests,dialogue,cine}.js   →11.5 Gün IV, Toy, baskın
  act1/day5/{index,quests,dialogue,cine}.js   →11.6 Gün V
  act1/night/{index,quests,dialogue,cine}.js  →11.7 Son Gece
  act1/blizzard/{index,quests,dialogue,cine}.js →11.8 Gün VI
  act1/end/{index,quests,dialogue,cine}.js    →11.9 Ev, perde kartı
  act1/side/{index,quests,dialogue}.js        →11.10 23 yan görev
  proto/{index,day1,blizzard}.js              →10.9 Dikey dilim: Gün I + Tipi prototipi; Faz 11 açılınca silinir

  act2/index.js                    L    II. Perde dizini (Faz 13)
  act2/opening/{index,quests,dialogue,cine}.js →13.3 Pay, Köz Kabı, Ocak Yeri (K23, settlement.md §2.1)
  act2/camp/{index,quests,dialogue}.js   →13.4 Islık Ordugâhı: `mq2_whistle_camp`, Talim Alanı, Yüzlük Kampı
  act2/oba/{index,quests,dialogue}.js    →13.5 İlk aileler ve Oba: `hh_story`, `mq2_oba`, Oba kapısı
src/data/
  damage-tables.js                 →0.6 LIVING, STRUCT, BURN çarpanları
  difficulty.js                    →0.6 Zorluk tablosu (progression.md §12)
  destan.js                        →3.2 Destan Kitabı girdileri; kurgu tercihi yalnız uydurulan kişi ve kurumlara
  weapons.js                       →6.6 Silah, yay, ok tabloları
  skills.js                        →8.1 93 beceri
  mod-readers.js                   →8.1 mods anahtarı → okuyucu modül
  gear.js                          →8.2 Giyilen eşya, binek eşyası
  node-kinds.js                    →8.3 Düğüm türleri (economy.md §3.2)
  craft-recipes.js                 →8.4 Zanaat tarifleri: tezgâh, rol, girdi, çıktı, İS, tutuş, bekleme
  items.js                         →8.2 Malzeme, parça, bohça satırları (economy.md §2, d2/economy.md §2; d2/econ-model.json ile aynı)
  stations.js                      →8.4 11 tezgâh, 9 zanaatçı rolü (d2/economy.md §4.2, §4.3)
  herd-kinds.js                    →8.4 Sürü türleri: mevsim üretimi, kesim, kış yemi
  loot-tables.js                   →8.4 Düşman türüne göre belirli ganimet
  recipes.js                       →8.5 Yemek tarifleri
  fauna-kinds.js                   →8.6 Hayvan tablosu
  enemies.js                       →8.8 Düşman tablosu

  weather-types.js                 →8.10 Hava türü vektörleri, alt olaylar, etki sayıları
  climates.js                      →8.10 İklim payları, gün içi eğriler, hâkim rüzgâr, zon → iklim
  settlement.js                    →8.13 Kademe, yapı satırı, parsel kuralı, hane kaynağı, ordugâh kademesi, baskın (settlement.md, d2/settlement-model.json)
src/game/
  game.js                        E →1.1 Oyuncu hareketi, kamera, oda; girdi yalnız InputHandle'dan
  systems.js                       →1.1 SystemHost: mod, sıra, kancalar
  interact.js                      →1.1 Etkileşim seçimi, tap ve hold sürücüsü (saf)
  camera-rig.js                    →1.1 Kamera istek yığını, CAM ön ayarları (saf)
  mounted.js                       →1.1 placeRider, MountSystem: at istemi ve tıklaması; 8.10 rüzgâr ve gök gürültüsü ürkmesi
  nav.js                         E →5.7 A* sınırı, adım parametresi; yapı katmanı 6.2
  nav-patches.js                   →9.2 NavView: 100 m yamalar, 3×3 bellekte, yol grafı (saf)
  child.js                         →2.5 Çocuk: oturuştan kalkış, silah, küçük döngü
  structure-nav.js                 →6.2 StructureNav: yapı şekillerini ızgaralara damgalar
  builders.js                      →6.5 Usta durum makinesi, iş tablosu, yardım; 8.11 emek yasası, CHILD_HELP, gece meşalesi, SHELTER
  damage.js                        →0.6 hitLiving, hitStructure, makeAttack (saf)
  combat.js                        →6.6 Damageable kaydı, salınım, ışın, olaylar
  projectiles.js                   →6.6 Balistik ok, taş, ıslıklı ok; instanced havuz; 8.10 rüzgâr sapması
  telegraph.js                     →6.6 Zemin çizimi: halka, koni, çizgi
  cond.js                          →0.5 Koşul dili derleyici (saf); 8.14 phase:, beat:
  flags.js                         →0.5 FlagStore (saf)
  effects.js                       →0.5 Etki listesi uygulayıcı (saf); 8.14 clock, weather, ledger yeri
  save.js                          →0.7 SaveManager: yuva, blok, göç, doğrulama (saf); 8.9 meta.minute, phase, İnce İş eki denetimi
  progress.js                      →4.3 XP, seviye, stat, beceri, eksen, ant, reveal (saf)
  derive.js                        →8.1 derive(): türetilen değerler (saf)
  items.js                         →8.2 ITEMS, etiket eşleme, baseId, yığın yükü (saf)
  inventory.js                     →8.2 Heybe, Yük, yuva, depo, el koyma, kap çözücü (saf)
  container.js                     →8.2 Container: bütün kaplar, onda bir Yük, gün anahtarlı bozulma, transfer (saf)
  gather.js                        →8.3 Toplama durum makinesi
  strike-ring.js                   →8.3 Tam Vuruş halkası (3B, tek çizim)
  needs.js                         →8.4 Tokluk, bantlar (saf)
  craft.js                         →8.4 Tarif çözümü; Workshop: tezgâh kuyruğu ve bekleme (saf)
  supply.js                        →8.4 SupplyLedger (soyut ve ambar kipi), LEDGERS, armyShare, rolloverYears (saf)
  barter.js                        →8.4 Terazi (saf)
  herds.js                         →8.4 Sürü günü ve mevsim olayları (saf)
  loot.js                          →8.4 Belirli ganimet, birim ganimeti (saf)
  campfire.js                      →8.5 Oyuncu ateşi
  cooking.js                       →8.5 Tarif, kalite (saf)
  agent.js                         →8.6 Agent taban sınıfı
  agent-move.js                    →8.6 Yuva izleme, kaydırma, mandal (saf)
  fauna.js                         →8.6 Hayvan yöneticisi
  hunting.js                       →8.6 Nişan, kapan, iz, yüzme
  player.js                        →8.8 Mete: derive ↔ Game, Yara, Düşüş ve Umay Eşiği, çan
  mounts.js                        →8.8 Binek kaydı, Bağ
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
  regions.js                       →10.1 Bölge rütbesi, Kızıl Kazık sayacı
  jobs.js                          →10.1 İş Tahtası, teslim (saf)
  quests.js                        →10.1 Görev çalıştırıcı (saf)
  dialogue.js                      →10.2 DialogueRunner (saf çekirdek)
  schedule.js                      →10.3 Dakika bloğu → konum, iş (saf)
  npcs.js                          →10.3 NpcManager: Folk ve kukla kademesi
  stealth-core.js                  →10.4 Algı formülleri (saf)
  stealth.js                       →10.4 StealthSystem: nöbetçi, gürültü, iz
  travel.js                        →10.5 Travel: durak, sefer, atlas yolculuğu
  travel-data.js                   →9.3 ZONES, NODES, EDGES, STATIONS, ROUTES, LANES, FARES, GOSSIP, LOCKS (saf)
  lanes.js                         →10.5 Çevre şeritleri
  journey.js                       →10.8 Yeni oyun kurulumu, pos/yaw bloğu, perde geçişi
  cine.js                          →5.3 CineDirector; 8.14 saat izi, hava satırı
  raid.js                          →11.5 Baskın saati
  moon-clock.js                    →11.7 Ay Saati (Düğümden buz saatine), yakalanma
  frozen-camp.js                   →11.7 Donuk Kamp kipi
  pursuit.js                       →11.8 Kara Boran takipçileri
  boss-farnak.js                   →11.8 Boğaz boss fazları
  squad/index.js                   →10.6 SquadManager
  squad/squad.js                   →10.6 Squad
  squad/follower.js                →10.6 Follower extends Agent
  squad/formation.js               →10.6 Düzen yuvaları (saf)
  squad/army-data.js               →10.6 UnitRec, obey, tReact (saf)
  squad/crowd.js                   →10.6 CrowdRenderer, T0 + sade T1 (9.5 kukla)
  squad/demo.js                    →10.6 ?squad=10, yalnız geliştirme

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
src/character/
  rig.js                         E →2.1 Jest ve taşıma uygulama, carry, benchK, spec.ride, seatHeight
  gestures/index.js                →2.1 Alan dosyalarını açar, kaydı rig.js'e verir
  gestures/base.js                 →2.1 Kayıt tabloları, registerGesture, registerCarry; reach, raise, throw, whistle, bow, wave, nod
  gestures/labour.js               →2.1 Boş; 8.3 doldurur: chop, pick, saw, haul, carry_man, stomp
  gestures/build.js                →2.1 Boş; 6.5 doldurur: hammer, tie, carry_*, reach_up, heave, lay, tamp
  gestures/combat.js               →2.1 Boş; 6.6 doldurur: slash, thrust, draw, loose, twist_loose, parry, grapple, whirl, plant, ear_down, bind, sling
  gestures/story.js                →2.1 Boş; 11 doldurur: sign ve sahne jestleri
  actor.js                         →1.1 ACTOR_PROFILES, GameActor yüzü
  looks.js                         →2.2 Folk görünüş tanımları; 9.7 kadroyu ekler
  folk.js                        E →2.2 attach, profile, sınır küresi, paylaşılan etiketleri
  mete.js                        E →2.2 attach metre → cm, profile
  horse.js                       E →2.4 Tek SkinnedMesh, harness
  npc.js                         E →2.3 world.folk tutamakları, oturan çocuk
  head.js                        E →5.4 mouth parametresi, 3 viseme
  puppet.js                        →9.5 Kukla insan ve at (army.md §7.3 sözleşmesi)
  draft.js                         →9.5 Kukla at, öküz, deve
  animal.js                        →8.6 Dört ayaklı kas iskeleti, görünüşler
  ghost.js                              Değişmez
  hero.js                               Emekli; yalnız states/creator.js dinamik açar (5.6'ya dek); Faz 12 sonunda `L` siler
src/world/
  world.js                       E →1.7 Spec güdümlü kurulum, sis katmanı, dispose; 8.9 altı ışık durağı, lightBase, writeLight, tallThings; 9.4 WeatherView.compose devralır
  terrain.js                     E →4.4 Tek göl hattı; 7.1 Terrain sınıfı, height() dağıtıcıları
  terrain-field.js                 →7.1 heightRaw, dirtRaw: üç'süz alan işlevleri (saf)
  terrain-patches.js               →9.1 100 m parçalı arazi
  paint-ground.worker.js           →12.3 paintGround için OffscreenCanvas işçisi
  lake-line.js                     →4.4 Tek göl hattı
  layout.js                      E →1.7 Adlar; 6.4 SITE_YURT, SITE_STOCK
  camp.js, interior.js           E →6.1 Aşama etiketleri, owner, Room.enabled; camp.js 8.11 G_TORCH, 9.4 bayrak rüzgârı
  grass.js                       E →5.2 Uzaklık kırpması; 6.4 ezik maskesi; 7.3 spec
  flora.js                       E →7.3 Spec; 9.4 kış ormanı, rüzgâr, tallThings (ağaç)
  valley.js, ambient.js, fire.js E →4.4 / 5.1 / 5.2 Tek hat, sis, nokta sınırı, alev, duman
  yurt-designs.js                E →1.7 Adlar {tr,en}
  props.js                              Değişmez
  sky.js                         E →5.1 Kameraya bağlı gök kubbesi; 8.9 gece: yıldız, ay diski; 9.4 hava uniform'ları
  dispose.js                       →7.2 disposeScene, markShared
  site-pad.js                      →6.4 Ped, ezik maskesi, stok; 8.12 genel şantiye pedi; 9.10 PadField
  structure.js                     →6.3 StagedStructure, StructureManager; 8.11 emek, G_TORCH; 9.6 scale, kit kaydı, YurtField devri, tallThings
  structure-logic.js               →6.3 Havuz, birim, LIFO, yanık (saf); 8.11 advance(wm), söküm, parça ve ham teslim
  structure-defs.js                →6.3 STRUCTURE_DEFS; 8.11 emek alanları ve K23 türleri
  structure-shader.js              →6.1 Etiket, GLSL parçaları, partsHooks; 8.11 G_TORCH; 9.6 FELT_WET
  structure-kits.js                →9.10 K23 görünüm aileleri (yard, mound, ring, post, field), shed, tower, fence hazır ayarları, kaba ağlar
  settlement-view.js               →9.9 SettlementView: YurtField, KitField, parsel çıkartması, sürü örnekleri
  tent-field.js                    →13.4 TentField: ordugâhın uzak çadırları (tek örnekli çizim + gölge, program eklemez)
  structure-fx.js                  →6.3 fxPoints, fxChunks, fxSmoke, fxFlames, fxArrows, fxGlow
  node-store.js                    →8.3 NodeStore: SoA, yerleşim, kayıt (saf)
  nodes.js                         →8.3 NodePools, NodeSystem, hot[]
  road.js                          →9.3 Road, Network (saf)
  cart.js                          →9.5 buildCart, Cart
  weather.js                       →9.4 WeatherView: yağış ve sıçrama noktaları, yıldırım şeridi; ışık, sis, kubbe, rüzgâr ve post bileşimi
  weather-hooks.js                 →9.4 Hava GLSL dizgeleri: ekran yağışı, ıslaklık, bulut örtüsü, kubbe (saf, yalnız dizge)
  snow-hooks.js                    →9.1 Kar kabartma zemini, kar kancaları, *_w anahtarları
  track-decals.js                  →10.4 İz çıkartması, ≤64
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
src/map/
  geography.js                   E →4.1 Kimlik, unlock, dönem, AREA_KM2 ayrımı
  atlas.js                       E →1.2 Girdi; 4.2 reveal; 7.6 setWorld; 10.5 pickMode, openLeg
  relief.js, relief-core.js      E →4.2 Dönüştürücüler, reveal parametresi
  relief.worker.js                      Değişmez
  routes.js                        →10.5 Atlas yol şeridi
src/ui/
  style.css                      L      Donmuş; yeni kural css/ altına
  css/tokens.css, shell.css        →1.4 Palet belirteçleri, kabuk
  css/hud.css                      →1.3 HUD yuvaları
  css/menu.css, book.css, save-panel.css, epigraph.css  →3.x
  css/creator.css                  →5.6
  css/cine.css                     →L Atlama ipucu (Faz 5)
  css/cook-wheel.css               →8.5

  css/wait.css                     →8.9
  css/pack.css, ledger.css, transfer.css  →8.7
  css/dialogue.css                 →10.2
  css/roadcard.css                 →10.5
  css/journal.css                  →10.7

  css/weather.css                  →9.8
  css/hold.css                     →9.9 Plan şeridi
  css/hold-ledger.css              →10.10 Yerleşim Defteri sayfası
  fade.js                          →1.4 DOM kararma
  loader.js                        →1.4 Yükleme ekranı
  toast.js                         →1.4 Kısa bildirim (menu-spec.md)
  confirm.js                       →1.4 Onay penceresi
  subtitle.js                      →1.4 Altyazı katmanı
  skip-hint.js                     →L Basılı tut ipucu, cine.skipProgress halkası (Faz 5)
  hud.js                         E →1.3 Yuvalar, widget kaydı, sanal düğmeler
  hud/vitals.js                    →1.3 Can, Stamina
  hud/build-status.js              →6.5 Yeni Yurt aşaması; 8.11 ekip ve «≈N saat» satırı
  hud/needs.js, gain.js, bar.js    →8.7 Tokluk, kazanç yazısı, 1–6 çubuğu
  hud/trust.js, axes.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, birlik
  hud/clock.js                     →8.9 Gök Kavisi: güneş, ay, evre, bekleyiş düğümü; 11.7 Ay Saati kipini ekler (aynı dosya, ayrı faz)
  hud/weather.js                   →9.8 Hava simgesi, işaret satırı, gök okuma
  hud/plan-bar.js                  →9.9 Plan Kipi şeridi
  stage.js                       E →1.6 Girdi; 5.6 Mete ile
  woven.js                         →5.6 installWovenCSS (creator.js'ten taşınır)
  creator.js                            Emekli; yalnız states/creator.js dinamik açar (5.6'ya dek); Faz 12 sonunda `L` siler
  creator/creator-screen.js, rows.js, parchment.js, banner.js, brush-button.js  →5.6 Oluşturucu
  menu/main-menu.js, knot-button.js, brush-canvas.js, ornament.js, logo.js, save-card.js  →3.1
  menu/book.js, ornate-frame.js, book-glyphs.js  →3.2
  menu/pages/general.js, settings.js, controls.js, destan.js, people.js, stones.js  →3.2
  menu/save-panel.js               →3.3
  menu/epigraph.js, language.js    →3.4
  cook-wheel.js                    →8.5 Tarif çemberi

  wait-wheel.js                    →8.9 Bekle, Uyu, Dinlen, Çalış tekeri
  pack.js, ledger.js, barter.js, glyphs.js  →8.7 Heybe (Terki sekmesi), Defter (yapı sayfası), Terazi, SVG simgeler
  transfer.js                      →8.7 İki sütunlu aktarma paneli: bütün kaplar (d2/economy.md §5.2)
  dialogue-ui.js                   →10.2 Diyalog katmanı
  roadcard.js                      →10.5 Yol Kartı
  journal.js                       →10.7 Görevler
  info-card.js                     →10.7 Eksen ve kural kartı (`card` etkisi)
  act-card.js                      →11.9 Perde kartı

  hold-ledger.js                   →10.10 Yerleşim Defteri sayfası (settlement.md §14.2)
  css/act-card.css                 →11.9
tools/
  voices.mjs                            K28: ElevenLabs seslendirme (src/story/vo-lines.js okur; me, voices, cost, gen, --take)
  elevenlabs-api.mjs                    K28: ElevenLabs istekleri (TTS, Scribe v2, Eleven Music, kota); anahtar .env'den, yazdırılmaz
  bard-song.mjs                         K19: ozanın şarkısı Eleven Music'ten (bard-song-plan.js), çekim sınaması, −18 LUFS, bard-song-take.js
  check-pure.mjs                   →0.8 Saf modül yasaklarını tarar
  check-i18n.mjs                   →0.8 Her anahtarda TR ve EN, boş metin yok
  check-data.mjs                   →0.8 Görev, diyalog, sinema, eşya, ses kimliği, mods okuyucusu, koşul derlemesi, kredi bütçesi; 8.14 hava, saat izi, days.js, ekonomi modeliyle eşitlik
  econ-sim.mjs                          K24 denge benzetimi (d2/econ-model.json, settlement-model.json, weather-model.json); yalnız ekonomi alanı yazar, paket değildir
  weather-model.mjs                →8.10 W26 üreteci: `weather-core` sabit tohumla 150 kış koşar, `d2/weather-model.json`'ı yazar (`node --test` dışında)
  check-budget.mjs                 →12.4 Sahne başına perf eşikleri
test/*.test.js                          §6.1
test/index.js                     L     Node 24'te `node --test test/` komutunu aynı sınamalara bağlar
docs/baselines/                  L      Faz 0 menü görüntüsü ve sayaçları
public/audio/vo/                 L      Üretilen sesler ve manifest; yalnız tools/voices.mjs ve tools/bard-song.mjs yazar
```

## 2. App ve durum makinesi

### 2.1 App nesnesi

```js
// src/app/app.js (L). Tek örnek; window.__tanhu.app.
export class App {
  constructor({ canvas, uiRoot, params })
  // Tekil servisler: yalnız App kurar, herkes ctx üzerinden alır (§2.6)
  renderer; post; clock; bus; input; store; settings; save; flags; progress; audio;
  world;            // let: dünya değişince başka örnek. Saklama, her seferinde ctx.world oku
  game; atlas; stage; hud; ui;   // ui: { fade, loader, toast, confirm, subtitle }; stage oluşturucunun ilk girişine dek undefined
  state;            // StateId
  prevState; pending;   // geçiş sürerken hedef StateId, yoksa null
  states;           // Record<StateId, AppState>
  difficulty;       // 'story'|'normal'|'hard'|null: `difficulty` kayıt bloğu App'tedir, journey.js (10.8) gelince ona geçer
  revealMode;       // 'camp' | 'story': atlasın açılma kuralı (§3.18)
  setRevealMode(mode);   // 'story': atlas.setReveal(progress.revealed, () => progress.era); 'camp': atlas.setReveal(). Aynı kip yok sayılır

  async start();
  goTo(next, opts = {}) /* → Promise<void> */;   // §2.4
  replaceWorld(specId, { onStep, yieldGate }) /* → Promise<void> */;   // §2.7
  tick(now);        // §2.5
  step(ms = 16.7, n = 1);   // §2.5
  resize();
  requestRedraw();  // pause durumunda bir kare çizdirir (resize sonrası)
  captureThumb();   // sonraki render sonrası 320×180 JPEG q0,7 data URL üretir; → Promise<string>
  onceRendered(fn); // sonraki render'dan hemen sonra çağrılır: çizim tamponu ancak aynı görevde okunur
  get low();        // ?q=low ya da video.quality: 'low'
  frozen;           // __tanhu.freeze: saat durur, rAF kare ilerletmez, yalnız step ilerletir
}
```

**Durum nesnesi.** Her durum `src/app/states/<id>.js`, `AppState`'ten türer.

```js
export class AppState {
  constructor(app) { this.app = app; this.ctx = app.ctx; }
  enter({ from, payload }) {}   // async olabilir; çözülene dek update ve render çağrılmaz
  leave({ to }) {}              // eş zamanlı; girdi tutamağını kapatır, DOM'u gizler
  update(dt, t) {}              // mantık; çizim yok
  render(dt, t) {}              // en çok bir post.render
  onResize() {}
  get pausesClock() { return false; }   // true ise saat ve U.uTime ilerlemez
}
```

### 2.2 Durumlar

Eski adlar: `creator` aynı kalır, `game` ikiye bölünür (`freeroam`, `play`), `map` aynı. Sinema `newgame`dir; `play` içindeki sinema ve diyalog durum değil üst kiptir (§3.19, §3.15). `travel` görev listesine eklendi (§8 karar 1). `home` perde sonu kipidir (§8 karar 20).

| Durum | Giriş | `update` | `render` | Girdi yığını (alttan üste) | Müzik |
|---|---|---|---|---|---|
| `boot` | Açılış | `enter` bitince bir kez `goTo(route())`: `enter`, `goTo`'nun kendi girişini beklerken kilitlenmez | Yok, kanvas siyah | Boş | Yok |
| `language` | `settings.lang === null` | Yok | Yok | `language` modal | Yok; ilk jestle `audio.unlock()` |
| `epigraph` | Dil belli | Süre, `world.ready` | Yok | `epigraph` modal | `camp` dronu, ses açıksa |
| `menu` | Epigraf bitti, kitaptan dönüş | `menuCam`, `world.update(dt, t, MENU_FOCUS)` | `post.render(world.scene, menuCam.camera)` | `menu`; üstüne `book`, `save_panel`, `confirm` | `camp` |
| `freeroam` | Serbest Gez | `game.update`, `world.update(dt, t, game.pos)`, HUD | `post.render(world.scene, blend ?? game.camera)` | `game`, üstünde ince `freeroam` (`map`, `wait`); üstüne `cook_wheel`, `wait_wheel` | `camp`, Gece evresinde `camp_night`; dombra ozanın konumundan |
| `newgame` | Yeni Oyun | `cine.update`, `world.update(dt, t, cine.shadowFocus)`; sahnede oyuncu yok | `post.render(world.scene, cine.camera)` | `cine` modal | `camp_bard` → `crane` → `narration` |
| `creator` | Sinema bitti, atlandı | `stage.update` | `post.render(stage.scene, stage.camera)` | `creator` modal | `creator` |
| `play` | Oluşturucu kabul, Devam Et, Yükle, `travel` varışı | Sistemler, `game.update`, `world.update` | `post.render(world.scene, cine.active ? cine.camera : game.camera)` | `game`, üstünde ince `plan` (K23, modal değil); üstüne `dialogue`, `cine`, `roadcard`, `levelup`, `wait_wheel`, `transfer` modal | Spec, sahne ve evreden |
| `map` | `M`, HUD düğmesi | `atlas.update`; gerçek modda `game.placeActors`, `world.update` | `post.render(atlas.activeScene, atlas.activeCamera)` | `map` modal | Sürer, −3 dB |
| `pause` | `Esc`, `I`, `J`, `L`, `K`, `F5`, `F9` | Yalnız kitap | Yok, son kare durur; `requestRedraw` bir kare | `book` modal; üstüne `save_panel`, `confirm` | Sürer, −6 dB |
| `travel` | Uzak Yol | `atlas.updateLeg`, dünya kurulumu arkada | `post.render(atlas.scene, atlas.camera)` | `leg` modal | `road_leg` |
| `home` | `mq_home`: `play` → Tanhu Kampı'nın küçük dünyası; `camp` yüklenmez (K106) | `cine.update`, `game.update` (yalnız `mount`, `child`, `structures`, `sites`, iğneli `clock` ve `sound`), `world.update(dt, t, game.pos)` | `post.render(world.scene, cine.active ? cine.camera : game.camera)` | `game`; üstüne `cine`, `act_card` modal | `home` |

`pause.pausesClock` true: Ay Saati, Tokluk, yapım durur (`progression.md` §14.1). `map` açıkken de `game.update` çalışmaz, dolayısıyla aynı sonuç.

**Dünya saati (K20, §3.23).** `ClockSystem` (order 15) saati yalnız `freeroam` ve `play`'de akıtır; `home`'da menü ışığına iğneler. `menu`, `newgame`, `creator`'da dünya saati yoktur: kamp menü ışığındadır (`applyMood(0,3)`, sabit güneş) ve `menuDiff` değişmez. `map`, `pause` ve gizli sekmede `game.update` çalışmaz; `freeze` altında `step` `game.update`'i yine çağırır, bu yüzden `ClockSystem` ve `WeatherSystem` `app.frozen` iken ilerlemez; duvar süresi telafi edilmez. Bloklayan diyalog, sinema (`run` izi yoksa), seviye ekranı, Terazi, Yol Kartı, aktarma paneli, Bekle tekeri ve Donuk Kamp `worldClock.pause(reason, on)` ile durdurur. Atlas yolculuğu (`travel`) varışta yol süresi kadar atlar (`clock:skip { reason: 'travel' }`).

**Açılışta `language` ve `epigraph` (3.4).** `App.start` kare döngüsünü dünyayı `boot.enter`'dan bekleyerek başlatır. Bu yüzden olağan açılışta dil ekranı (`states.language.ask()`, `close()`) ve söz (`states.epigraph.begin()`) döngüden önce `boot.enter` içinde açılır; o süre boyunca `app.state` `boot` kalır, ilk karede `boot.update` → `goTo('epigraph')` ve epigraph durumu açık sözü devralır. Doğrudan giriş (`?state=language`, `goTo('epigraph')`) aynı nesneleri durum girişinde kurar.

**Serbest Gez oturumu.** `freeroam.enter` oturum yoksa `beginSession`: statik çocuk gizlenir, tek `Folk` Çocuk `spec.spawn` yerine oturur. `map` ve `pause`'a geçiş oturumu kapatmaz; başka her çıkış `endSession` ile menü sahnesini geri yazar (statik çocuk, atlar ahırda, odalar, ışık, `U.uPlayer`; K20–K22: `world.setTimeOfDay(null)`, gece tekdüzenleri, zerre `uDusk` 0, `campLife.menuPose(true)` ile statik halk görünür, ikizler ve yaban hayvanı kalkar, hava kimliğe döner; ışık ve hava uçuş boyunca `beginReturn` ile 1,7 sn'de süzülür, `endSession` inişte tam değerleri yazar, §2.4). Oturum `roam.clock` ve `roam.weather`'ı okur ve yazar (§3.5). `pause` → `menu` çağrısını `pause` yapar (3.5).

**Yeni Oyun ve oluşturucu (Faz 5).** `newgame.enter` `cine.play('cine_newgame', { from: menuCam.camera, focus: MENU_FOCUS, release: false })` çağırır, `creator.preload()` ile oluşturucunun modüllerini, `mete.glb`'yi ve fonu sinema sürerken indirir, `FLAME_BILLBOARD.value = 1` yazar (alevler sinema kamerasına döner) ve atlama ipucunu (`ui/skip-hint.js`) kurar. Sinema bitince ya da atlanınca `end.goTo` `creator`'a geçer; `newgame.leave` süren sinemayı `stop`, bitmişi `release` ile kapatır (sis katmanı, ozan pozu), billboard 0, ipucu gizli. `creator` artık `MeteAvatar` ile kurulur (5.6), Hero içe aktarılmaz; ilk girişte `import()` ile gelir. Kabul `{ origin, appearance, difficulty }` verir: geçişin `prepare`'i siyahta `save.newJourney(result)` çağırır (oto yuva 0'a ilk yazım), `play` yokken (`ACT1_READY=false`) hedef `freeroam`'dur. `play` gelmeden DEVAM ET ve YÜKLE kayıt görür ama açamaz («Bu kayıt açılamadı.»).

### 2.3 Geçişler

```
boot ─┬─(lang yok)→ language ─→ epigraph ─→ menu
      └─(lang var)────────────→ epigraph
menu ─→ freeroam ⇄ map, freeroam ⇄ pause
menu ─→ newgame ─→ creator ─→ play          (creator iptal → menu)
menu ─→ play (Devam Et, Yükle)
play ⇄ map, play ⇄ pause, play ⇄ travel
play ─→ home ─→ menu                        (perde sonu, kayıt korunur)
pause ─→ menu, pause ─→ play (Yükle)
```

`?state=<id>` yalnız geliştirmede doğrudan girer, `?zone=<spec>` ile dünya seçer; `?play` (eski adres) `?state=freeroam` demektir. Mevcut `?q=low`, `?density=`, `?yurt1=`, `?yurt2=` korunur; yeni `?yurt3=`, `?squad=`, `?sandbox=site` (K21 kum havuzu: `play` durumunda `sandbox_site` dünyası; `&hold=1` yerleşim kipi `sandbox_hold`, 9.9). Kum havuzu yalnız geliştirmededir, kampa ve menüye dokunmaz.

**`home` kipi (`act1.md` §8.11).** `mq_home`: `play` → Tanhu Kampı'nın kendi küçük dünyası; menü dünyası `camp` yüklenmez (K106). Kare uzaktır (K98); Çocuk oyuncu değildir (K106), mevsim bahardır. Mete atla güney patikasından gelir, kısa sahne. Mete ana kampa (Göl Obası) hiç gelmez (K6, K106). Sonra «II. Perde yakında» / «Act II is coming» kartı (`ui/act-card.js`), oto kayıt `act1_done` ile korunur, `menu`. Devam Et ve Yükle, `act1_done` taşıyan kayıtta dünya kurmadan bu kartı menü üstünde gösterir, kart kapanınca menüde kalınır. `home`'da `Esc` ve `M` yoktur; sahne atlanırsa kart gelir.

**Kurulum yeri.** Dünya `epigraph` girişinde, ilk boya sonrası (60 ms) arkada kurulmaya başlar; bu yüzden tipik 4,5–7 sn'lik kurulum ayrı ekran gerektirmez (§8 karar 2). Epigraf CSS `opacity` ile canlandığından ana iş parçacığı bloklansa da oynar. Epigrafın son adımı `world.ready` bekler: hazır değilse siyah üstünde `ui.loader` çizgisi görünür. «Dünya hazır» epigraph durumuna girilmiş olmaktır: `boot.enter` dünyayı kurar, `App.start` sahneyi Çocukla birlikte `game.camera` ile derler (menü kamerasıyla ikinci derleme yoktur, program kümesi aynıdır), sonra döngü başlar ve `boot` → `epigraph` geçer. `language` ekranı açıkken kurulum başlamaz: tıklama takılmasın. `compileAsync` yalnız sahnedekileri derler (malzemede `visible`'a bakmaz, r187): Çocuk ve üçüncü yurt bu çağrıdan önce sahneye konup sonra ayrılır, Serbest Gez'e girişte takılma olmaz (ilk çizim 475 ms ölçüldü, `structures.md` §9.4).

**Ses kilidi.** İlk jest `Input.onFirstGesture` ile `audio.unlock()` çağırır. Kilit kapalıyken epigraf ve menüde «Ses için tıkla» / «Click for sound» ipucu durur (`audio.md` §1). Kurulum adımları ana iş parçacığını bloklar, `setInterval` sıralayıcısı da durur: `world.ready`'ye dek `camp` yalnız döngülü `AudioBuffer` dronu çalar, sıralayıcı ve dombra menüde başlar. App kurulumda `app:state` `{ from: null, to: 'boot' }` yayar: müzik `boot`, `language`, `epigraph`'ta yalnız dronu çalar, menüye girişte motif ölçü başından girer.

### 2.4 `goTo` ve kararma kuralları

```js
app.goTo(next, {
  fadeOut, fadeIn,     // sn; verilmezse FADE tablosu
  payload,             // new.enter'a gider
  prepare,             // async (app) => {}: siyahta, leave sonrası enter öncesi çalışır
}) // → Promise: enter çözülünce çözülür. pending varken gelen çağrı aynı Promise'i döndürür, yok sayılır.
```

Tablo satırı `ease` de taşıyabilir (`core/ease.js` adı, varsayılan doğrusal); `goTo` seçeneği `ease` onu ezer. `epigraph` → `menu` satırı `sineInOut`'tur (`menu-spec.md`: yalın TRANS_SINE). Kararma tek katmandır: `ui.fade` (`#ui` üstünde tam ekran DOM, z-index 900, `#0d1412`). HUD ve menü de kararmalı, `post.fade` bunu yapamaz. `post.fade` yalnız `atlas.veil` ve sinema içi için kalır. Sıra: `fadeOut` → `leave` → `prepare` → `enter` → `fadeIn`.

Geçiş kare içinde yürür: `goTo` yalnız kaydı yazar ve kararmayı başlatır, `leave` ile `enter` sonraki karelerin `updateFade`'inde çağrılır. Süren `update`'in altında durum değişmez, `goTo(x); step(16.7, 60)` tek çağrıda biter. `enter` Promise dönmezse ve `prepare` yoksa geçiş o karede biter, yeni durum aynı karede `update` ve `render` alır. `fadeOut` 0 iken `fadeIn` > 0 ise perde siyahtan açılır. Tabloda satırı olmayan geçiş 0,294 / 0,588 ile kararır (`states/base.js`). Giriş patlarsa hata yazılır, önceki duruma dönülür: siyah ekranda kalınmaz.

| Geçiş | DOM | `fadeOut` | `fadeIn` | Kamera, ses |
|---|---|---|---|---|
| `boot` → `language`, `epigraph` | Yükleyici 0,8 sn söner | 0 | 0 | |
| `language` → `epigraph` | Seçim 0,2 sn | 0 | 0 | |
| `epigraph` → `menu` | Epigraf kendi süreleri: 1,6 / 4,2 / 1,2 sn | 0 | Menü perdesi 2,0 sn, sine | `menu-spec.md` §1, §3 |
| `menu` → `freeroam` | Menü α→0 0,5 sn, sine in | 0 | 0 | `whoosh`; kamera karışımı 1,6 sn; ışık ve hava 2,4 sn (K20, K22; ikisi kamerayla aynı anda başlar) |
| `menu` → `newgame` | Menü 0,5 sn | 0 | 0 | `whoosh`; kamera karışımı 3,5 sn yakın plana |
| `newgame` → `creator` | | 0,35 | 0,35 | Atlama da aynı yol |
| `creator` → `menu` | | 0,3 | 0,35 | İptal |
| `creator` → `play` | Yükleyici siyahta | 0,3 | 0,35 | `prepare`: `save.newJourney`, `replaceWorld('hexi_winter')` (10.8) |
| `creator` → `freeroam` | | 0,294 | 0,588 | `play` yokken (`ACT1_READY=false`); `prepare`: `save.newJourney` |
| `menu` → `play` | Menü 0,5 sn | 0,35 | 0,45 | Kayıt başka dünyadaysa yükleyici |
| `freeroam`/`play` → `map` | HUD gizli | 0,294 | 0,588 | Mevcut 3,4/sn ve 1,7/sn; atlas ilk açılışta önce kurulur |
| `map` → `freeroam`/`play` | | 0,294 | 0,588 | |
| `freeroam`/`play` → `pause` | Kitap α 0,18 sn | 0 | 0 | `captureThumb()` |
| `pause` → `freeroam`/`play` | Kapanış anlık | 0 | 0 | `page_turn` −6 dB |
| `pause` → `menu` (aynı dünya) | HUD 0,3 sn | 0 | 0 | Oto kayıt; `menuCam.flyFrom(game.camera, 1.7)`, sine in-out; ışık ve hava menü kimliğine 1,7 sn |
| `pause` → `menu` (başka dünya) | Yükleyici | 0,35 | 0,45 | Oto kayıt; `prepare`: `replaceWorld('camp')` |
| `pause` → `play` (Yükle) | | 0,35 | 0,45 | Gerekirse yükleyici |
| `play` → `travel` | | 0,35 | 0,6 | `travel.md` §9.4 |
| `travel` → `play` | | 0,35 | 0,6 | Varış 4–6 sn sahnesi `play` içinde |
| `play` → `home` | Yükleyici siyahta | 0,35 | 0,6 | Oto kayıt; `prepare`: Tanhu Kampı'nın küçük dünyası (K106) |
| `home` → `menu` | Perde kartı kapanınca | 0,35 | 0,45 | Oto kayıt, `act1_done`; `prepare`: `replaceWorld('camp')` (K106) |

### 2.5 Kare döngüsü

```js
tick(now) {
  const dt = clamp((now - this.last) / 1000, 0, 0.05);        // kıstırma kalır
  this.wallDt = clamp((now - this.last) / 1000, 0, 0.25);     // K20: dünya saati kırpılmamış duvar süresiyle ilerler (ClockSystem okur)
  this.last = Math.max(this.last, now);
  if (!this.frozen && !this.states[this.state].pausesClock) { this.clock.advance(dt); U.uTime.value = this.clock.time; }
  this.input.beginFrame();
  this.updateFade(dt);                 // ui.fade.update(dt); kararma tamamsa leave/prepare/enter başlatılır
  const s = this.states[this.state];   // burada okunur: geçiş bu karede bittiyse yeni durum çizilir
  if (!this.entering) {
    this.post.update(dt);              // profil karışımı; game.applyPost gibi kare başı yazarlar son sözü söyler
    s.update(dt, this.clock.time);     // kural: girdi burada okunur
    this.bus.flush();                  // kuyruklu olaylar burada
    s.render(dt, this.clock.time);     // pause render etmez; requestRedraw bayrağı varsa bir kare
    this.afterRender();                // captureThumb bekliyorsa aynı karede oku
  }
  this.audio?.setListener(s.listenerCamera?.() ?? null);
  this.input.endFrame();               // pressed, released sıfırlanır
  this.sampleResolution(dt);           // dinamik çözünürlük yalnız spec.postCuts (Kışlak): >34 ms düşür, 5×2 sn <14,5 ms yükselt
}
```

**`__tanhu.step` korunur.** `step(ms = 16.7, n = 1)`: `clock.manual = true`, `for (i<n) tick(last + ms)`, sonra `manual` önceki değere döner. Gizli sekmede rAF durur, kare yine ilerler. `step(50, n)` 20 fps sınamasıdır (`army.md` §11.1). `step(0, 1)` oyunu ilerletmeden bir kare çizer (`perf`, `shot`). Girdi saati `now: () => clock.time * 1000`: `holdTime` da elle kareyi izler.

**Saat.** `core/clock.js` iki zaman verir: `time` (kıstırılmış `dt` toplamı, oyun zamanı) ve `cineNow()`. `cineNow()` ses açıksa ve `manual` değilse `audio.now` hızıyla, değilse `time` hızıyla akar. Sinema ve müzik buna bağlıdır: 20 fps altında `dt` kıstırması zamanı kaydırır (denetim §b), ses saati kaydırmaz. Elle karede sınama yine belirlenimlidir. **Kaynak değişince sıçramaz (5.3):** `cineNow = kaynak + offset`; kaynak (ses ya da `time`) okumada değişirse eski kaynağın o anki değeri yeni kaynağa offset olarak yazılır, `manual` açıldığından beri geçen oyun zamanı kaybolmaz. Ses kilidi sinema ortasında açılınca, `step` `manual`'ı açıp kapayınca değer kaldığı yerden sürer; `cineNow` bağlı bir işlevdir (Timeline `now` olarak saklar).

**Dünya saati (K20, §3.23).** `core/clock.js` oyun saniyesidir ve değişmez (sinema, `U.uTime`, eylem süreleri). Dünyanın saati ayrı bir saf sınıftır (`game/world-clock.js`): 1 oyun dakikası 2,5 gerçek sn, gün 3.600 sn. `App.tick` yalnız `wallDt`'yi yazar (kırpılmamış duvar süresi, kare başına en çok 0,25 sn); `ClockSystem.update` onu sahne yavaşlatmasıyla (`timeScale`) `worldClock.advance`'a verir, Yol Akışı `k` saatin `rate`'idir. Böylece `dt` 0,05 sn'ye kırpılsa da bir oyun günü 60 gerçek dakikadır (15 fps'de de); takılma ve sekme dönüşü saati sıçratmaz. Durma kuralları durumların ve sistem kiplerinin kendisidir (§2.2). `__tanhu.step(ms, n)` `wallDt`'yi `ms`'ten yazar: gizli bölmede gün belirlenimli koşar.

### 2.6 `ctx` sözleşmesi

`app.ctx` tek bir düz nesnedir; sistemlere, durumlara, arayüze kurucu parametresi olarak geçer. Saf modül `ctx` almaz, gerektiği kadarını parametreyle alır. Alanlar `app/app.js` ve `app/systems.js`'te kurulur:

```js
ctx = {
  app, bus, clock, input, store, settings, save, audio, post, renderer, canvas, uiRoot, ui, hud,
  get world() {}, game, atlas, stage,                     // Faz 1
  flags, progress,                                        // Faz 0, 4
  combat, projectiles, telegraph, cine,                   // Faz 5, 6
  inventory, needs, supply, mounts, player, nodes,        // Faz 8; supply: LEDGERS (§3.26), get(id)
  worldClock, calendar, campLife, weather, sites,         // Faz 8 (K20–K22, K21; calendar 10.1'den 8.9'a geçti)
  settlement,                                             // Faz 9 (9.9, K23)
  regions, jobs, quests, dialogue, npcs, stealth, travel, squads,   // Faz 10
}
```

Henüz kurulmamış alan `undefined`dır; okuyan modül o fazdan sonra yazılır. Yeni alan yalnız `L` ekler. Faz 6: `combat`, `projectiles`, `telegraph` `systems.js`'te, sistem eklenirken yazılır (`ctx.combat = game.systems.add(new Combat())`); okuyan sistemler `ctx[id] ?? game.systems.get(id)` ile arar. Faz 4–5'te gelenler: `progress` (yapıcıda, `registerSave` ve `save.setRules` ile), `cine` (yapıcıda `new CineDirector(ctx)`, `ui`'den sonra), `cond` (getter: `progress.cond`; journey.js tam CondCtx'i ona verir) ve `dev` (`import.meta.env.DEV`): `applyEffects(list, ctx)` bunları okur, `dev: false` bozuk etkiyi yazıp sürer. Kurulum sırası: yapıcıda çekirdek servisler (`progress`, `audio` ve alt motorları dahil, `clock.audio` bağlı), `ui` (`ui.savePanel` dahil), `cine`, durumlar; `boot.enter` ayar, dil, doku ve dünya; `start` onun ardından `post`, `game`, `systems`, Çocuk (`states.freeroam.ensureChild()`, `game.setActor`), `hud`, `atlas`; `stage` oluşturucunun ilk girişinde.

### 2.7 Yükleyici ve dünya değişimi

`ui/loader.js`: `show({ titleKey, labelKey })`, `set(labelKey, p)`, `hide(ms = 800)`. Mevcut `.loader` CSS'i (`main.js:49-52`) kullanır. Etiketler `t('loader.<adım>')`: «Tepe yükseltiliyor» / «Raising the hill» vb. Başlık `spec.loader`: «Kışlak kuruluyor» / «Raising the winter camp». Adım etiketinin bir sonraki adımı göstermesi hatası (`world.js:52`) 1.7'de düzelir.

```js
// src/app/world-swap.js (L). app.replaceWorld(specId, opts) buna gider; → Promise<boolean>, false: istek reddedildi, dünya yerinde.
async function replaceWorld(app, specId, { onStep = null, yieldGate = null, place = null } = {}) {
  if (app.swapping) return false;                        // süren değişim varken ikinci istek reddedilir
  if (!SPECS[specId]) return false;                      // bilinmeyen kimlik: dünya varken ret, ilk kurulumda 'camp'
  const spec = await SPECS[specId]();                    // açılamazsa dünyaya dokunulmaz
  loader?.show({ titleKey: spec.loader });               // yalnız eski dünya varken ve onStep verilmediyse
  bus.emit('world:dispose', { id: app.world?.spec.id }); // sistemler kaydı yazar (camp3, Çocuğun yeri), eskiyi bırakır
  game.leave();                     // aktörü, işaretçi, toz sahneden ayrılır
  atlas.setWorld(null);             // pinReal, ringReal, skirt, cloudReal ayrılır
  app.world?.dispose();             // §3.8; önce boşalt: iki dünya aynı anda ≈480 MB
  await nextFrame(); await nextFrame();                  // rAF ya da 50 ms (gizli sekme)
  const world = new World({ spec, density, onStep, yieldGate, designs });   // designs ?yurt1= ?yurt2= ?yurt3=
  await world.build();              // spec.terrain etkinleşir, height() yeni araziye bakar
  await compileWorld(app, world);   // HDR hedefi bağlı compileAsync, oyuncu sahnede; eski (boş) sahne çizilmeye devam eder
  app.world = world;
  game.setWorld(world, { place });  // arazisi etkin, nav yeniden, systems.onWorld (camp3 kayıttan döner), oyuncu yerinde, işaretçi ve toz geri
  warmWorld(app, world);            // ısınma karesi: güneş oyuncuya, yapılar oyun kipinde bir kare, kip geri
  atlas.setWorld(world);
  bus.emit('world:ready', { id: specId });
  loader?.hide();
}
```

**Faz 7 sözleşmesi.** `compileWorld(app, world)` ve `warmWorld(app, world)` `App.start`'ın da derleme yoludur: açılışta `game` ve `atlas` henüz yoktur, ilk kurulum `boot.enter` → `replaceWorld(SPECS kimliği)` ile kurulur, `App.start` oyunu kurup aynı iki işlevi çağırır. Isınma karesi gölge derinlik programlarını derler (yapıların `customDepthMaterial`'ı, Çocuğun deri bağlı iki yüzlü gövdesi): güneş `world.aimSun(oyuncunun yeri)` ile oyuncuya döner, Serbest Gez'in ilk karesinde program derlenmez (menü 57, Serbest Gez 57). Yükleyici: `onStep` verilmediyse ve eski dünya varsa değişim kendisi açar, başlık `spec.loader`, etiket adımın kendi anahtarı (`loader.hill` … `loader.ready`), sonunda 0,8 sn'de söner; açılış (`boot`, başlığı yine `spec.loader`: `specs/zones.js`'ten `boot.loaderTitle()`) ve atlas yolculuğu `onStep` verir, ekranı kendisi sürer. `place` verilmezse `game.setWorld` seçer: aynı bölgede oyuncu yerinde kalır, başka bölgede `spec.spawn`. Geçişin `prepare`'inde (`pause` → `menu`, Yükle) eski durum çıkmış, yenisi girecektir. Değişim bir durum sürerken gelirse (geliştirmedeki `__tanhu.swap`) o durum kendini taşır: `freeroam` `world:dispose`'da `tanhu.roam`'u yazar ve dombra kaynağını keser, `world:ready`'de oturumu yeni dünyaya bağlar (statik çocuk gizli, ahırdaki atlar, aynı bölgede ışık kaldığı yerden), oyuna yeniden girer ve kabuk bağlamını yine oyunun üstüne koyar; `menu` dünyayı her karede `ctx.world`'den okuduğu için bir şey yapmaz. Kayıt yüklenirken `worldForRecord(app, record)`: `specForZone(record.world.zone)`, zaten o dünyadaysa kurulmaz, kurulamazsa atar (geçiş önceki duruma döner, §2.4); `menu` ve `pause`'un Yükle yolu bunu `save.apply`'dan önce çağırır. `sounds.js` ortam listelerini `spec.audio.ambience`'tan kurar, `world:dispose`'da konumlu döngüleri (ocak) ve konumlu atımları (`sfx.stopPlaced`) söndürür, yeni dünyada süren kipi yeniden yazar: konumsuz döngü (rüzgâr) sürer, ikisi üst üste binmez.

**Faz 7 ölçümü (gerçek App, `__tanhu.step`).** Kamp değişimi 1,5–1,7 sn. Serbest Gez'den `swap('camp')` üç kez: her turda aynı görüntü geçmişiyle (oturan Çocuk 30 kare, `refs.compare`, (3,5; −9,5) 30 kare) 202 geometri, 38 doku, 57 program; ilk dünyada 208 çıkar, fark üçüncü yurdun ocak grubunun 6 ağıdır: açılıştaki ısınma karesi onları ilk güncellemeden önce 16:9 kameradan görür. Açılışın ısınma kamerası doğuş yerindeki ayakta Çocuğu izler (−1,98; −0,92: `Game` kurucusu ilk dünyada oyuncuyu `spec.spawn`'a koyar, `App.start`'ın `setActor`'ü oradan sürer), Faz 7 öncesinin (1,75; 2,35) pozunu değil. Değişimin ısınma kamerası (1,75; 2,35, 16:9) alınınca değişim sonrası da 208 çıktı; bu kadraj açılışınki değildir ama ocak grubunu o da görür (hesap: ocağın merkezi doğuş kadrajında NDC x −0,60, (1,75; 2,35)'te −0,69, (3,5; −9,5)'te −1,00, kadraj kenarı). Değişim sırasında Çocuk doğuş yerindeyken (ısınma kamerası = açılış kamerası) aynı geçmişle değişim sonrası sayım da 208 geometri, 38 doku, 57 programdır, değişim öncesi Serbest Gez değerine eşit (Faz 7 smoke): 202/208 farkı yalnız ısınma kadrajındandır. Program hiç artmaz. Her turda `refs.compare` 7 kare 0 piksel, `menuDiff` 0 piksel; Serbest Gez'de sayım karşılaştırılmaz (§6.3). Menüden değişimde sayım `counts.json` ile aynı, 360 çizim, 3.692.162 üçgen.

Kampa dönüş kurulumu tekrar eder: `replaceWorld` dünyayı her seferinde baştan kurar. **İki süre (#67, K64).** (K64 ile değişti: satır yalnız «4,5–7 sn, en kötü 17 sn» yazıyordu ve yukarıdaki 1,5–1,7 sn ile çelişir görünüyordu.) İki sayı iki ayrı tarayıcı ölçümüdür, çelişmez. «1,5–1,7 sn» Faz 7'nin kamp değişimidir (gerçek App, `__tanhu.step`, gizli bölme; menüden ve Serbest Gez'den üçer `swap('camp')`): kampa dönüşün prototipteki değeri budur. «4,5–7 sn, en kötü 17 sn» denetimin (`docs/research/code-audit.md` §c, 2026-10-31, Faz 0'dan önce) altı taze açılışıdır: soğuk kurulum, yüklü makine, toplam 1,4–17 sn, en oynak adım `paintGround` (0,37–13,75 sn). Bu sayı ilk açılışın en kötü durumudur, epigraf onu gizler (§2.3 «Kurulum yeri»). `paintGround` işçiye taşınınca (12.3) ikisi de azalır. Godot'da bu iki tarayıcı süresi taşınmaz, yerine iki hedef konur (`godot.md` §4.3, §7.2): kampa dönüş karartma altında ≤2 sn; iç harita yüklemesi ≤6 sn ve atlas yolculuğunun altında; ikisi `test_world_swap.gd` ve bütçe sahnesiyle ölçülür. Godot'nun kamp dünyası bugün başsız testte 3–4 sn'de kurulur; ≤2 sn'ye kampın arazisi, çayırı ve ormanı önceden pişirilerek (`tools/bake_map.gd`) ve eski dünya bırakılınca statik önbellekler boşaltılarak varılır (`godot.md` §4.3; K64). Kayıt yüklenirken dünya `specForZone(record.world.zone)` ile bulunur (`world/specs/index.js`): `hexi_winter` → `hexi_winter`, `tanhu_camp` → `camp`; zaten o dünyadaysa `replaceWorld` çağrılmaz.

## 3. Arayüzler

Kod blokları bağlayıcıdır: ad, parametre sırası, dönüş biçimi değişmez. Yorumlar davranışı söyler. `→` dönüş değeridir.

### 3.1 Olay veri yolu (`core/bus.js`, saf)

```js
export class Bus {
  on(name, fn, owner = null)    // → off()
  once(name, fn, owner = null)  // → off()
  offOwner(owner)               // owner'ın bütün dinleyicileri; dünya değişiminde sistem bunu çağırır
  emit(name, payload)           // eş zamanlı, kayıt sırasıyla; dinleyici hatası try/catch ile yutulur, console.error; derinlik >8 ise bırakılır
  queue(name, payload)          // tick içindeki bus.flush() anında teslim
  flush()
  history(n = 50)               // yalnız geliştirmede dolu: [{ t, name, payload }]
}
export const bus = new Bus();   // tekil; testte yeni örnek kurulur
```

**Kural.** Ad `alan:fiil`, küçük harf. Yük düz nesne, kare başına olay yayılmaz. Dinleyen modül yayanı bilmez. `structures.md` §2.2'deki `stage`, `unitFall`, `ignite`, `out`, `stepDone`, `done`, `breach` aşağıdaki `structure:*` adlarıyla veri yoluna yazılır; `army.md` `events.emit('squad:refused', …)` budur.

| Olay | Yük | Yayan |
|---|---|---|
| `app:state` | `{from, to}` | App |
| `i18n:lang` | `{lang}` | i18n |
| `settings:change` | `{key, value, prev}` | settings |
| `save:written`, `save:loaded` | `{slot, auto}`; `save:written` `reason` da taşır | save |
| `save:failed` | `{slot, reason}` | save |
| `world:dispose`, `world:ready` | `{id}` | world-swap |
| `flag:set` | `{key, value, prev}` | flags |
| `axis:change` | `{axis, value, prev, src}` | progress |
| `xp:gain` | `{n, src, total}` | progress |
| `level:up` | `{level}` | progress |
| `stat:spent`, `skill:learned`, `skill:teach` | `{id}` | progress |
| `atlas:reveal` | `{id}` | progress |
| `item:add`, `item:remove` | `{id, n, src}` | inventory |
| `load:change` | `{load, cap}` | inventory |
| `item:move` | `{from, to, id, n}` | inventory, settlement stores (`transfer` sonucu; saf `container.js` olay yaymaz) |
| `item:spoiled` | `{container, id, n}` | inventory, settlement stores (`Container.onDawn` sonucu) |
| `need:band` | `{need, band}` | needs |
| `node:hit`, `node:depleted` | `{index, kind, x, z}` | nodes |
| `gather:yield` | `{item, n, x, z, clean}` | gather |
| `craft:done`, `cook:done` | `{id, quality, n, ws}` (`ws` tezgâh kimliği, el işinde null) | craft, cooking, yerleşim üretimi |
| `fire:lit`, `fire:out` | `{id, x, z}` | campfire |
| `job:done` | `{job, first}` | jobs |
| `ledger:change` | `{line, value, prev}` | supply |
| `interact:done` | `{id, kind}` | interact |
| `dmg:hit` | `{id, kind, dmg, type, tag, fromPlayer}` | combat |
| `dmg:killed` | `{id, kind, by, ko}` | combat |
| `player:wound`, `player:fall` | `{wounds, reason}` | player |
| `structure:stage` | `{id, stage, prev, cause}` | structure |
| `structure:unit_fall` | `{id, unit}` | structure |
| `structure:ignite`, `structure:out` | `{id}` | structure |
| `structure:step_done` | `{id, step}` | structure |
| `structure:done` | `{id, step, first}`: `first` yalnız ilk tamamlanışta true; onarımla yeniden tamamlanış sessizdir (Faz 7) | structure |
| `structure:breach` | `{id, unit}` | structure |
| `noise` | `{x, z, r, src}` | stealth, gather, player |
| `stealth:level` | `{guard, level}` (`none`, `q`, `bang`) | stealth |
| `stealth:caught` | `{guard}` | stealth |
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
| `region:enter`, `region:open` | `{id}` | regions |
| `stake:warn`, `stake:caught` | `{id, secondsLeft}` | regions |
| `lookout:found` | `{id}` | regions |
| `quest:start`, `quest:done`, `quest:fail` | `{id}` | quests |
| `quest:step` | `{id, step}` | quests |
| `dialogue:start`, `dialogue:end` | `{id, result}` | dialogue |
| `dialogue:line` | `{dialogue, node, who}` | dialogue |
| `dialogue:choice` | `{dialogue, choice}` | dialogue |
| `station:state`, `route:state` | `{id, state}` | travel |
| `travel:depart`, `travel:arrive` | `{from, to, mode}` | travel |
| `squad:order` | `{cmd, unit}` | squads |
| `squad:refused` | `{unit, members, markKind}` | squads |
| `arrow:whistle` | `{x, z, h, owner}` | projectiles |
| `cine:start`, `cine:end` | `{id, skipped}` | cine |
| `cine:cue` | `{id, cue}` | cine |
| `audio:music` | `{state}` | audio |
| `voice:start`, `voice:end` | `{line}` | audio |
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
| `camp3:family_wait` | `{until}` (22:30'da; 01:30'da aşama ≥6 ise 03:00'e uzatılınca yeniden). (K50 ve K83 ile değişti: aile o gece 23:00'e dek ateş başında kalır; 23:00'te aşama ≥4 ise `{ check: 23:00, until: 'smoke' }` ile ilk dumana dek bekler, 05:00'e dek duman çıkmazsa Ana közü getirir; `structures.md` §11.6. Prototipin kodu değişmez) | builders (tek sahip; CampLife uyar) |
| `camp3:hearth_dawn` | `{at}` (ocak 05:00'e kaldı) | builders |

### 3.2 Girdi yönlendirici (`core/input.js`, saf; DOM bağı `attach`'te)

DOM dinleyicilerinin **tek** sahibi. `game.js:209-252`, `main.js:135-145`, `atlas.js:489-493,538-579`, `stage.js:117-136`, `hud.js` dinleyicileri kalkar (arayüz düğmeleri kendi `click`ini korur). Açılan DOM katmanı kendi üstüne düşen olayı dinleyebilir: `.atlas` `wheel` dinleyicisini korur (§8 karar 23).

```js
export class Input {
  constructor({ canvas = null, target = null, keymap = DEFAULT_KEYMAP, onFirstGesture = null, onEscapeUnhandled = null, now = performance.now, wall = performance.now })   // now → ms: App oyun saatini verir (holdTime); wall → ms duvar saati: oyun saatinin kare başına kıstırdığı kısa süreler (orta tıkın 300 ms'si, K27)
  attach(); detach();                 // keydown, keyup, blur, visibilitychange, canvas pointer*, wheel, contextmenu (yığın doluyken engellenir)
  push(ctx)                           // InputCtx → InputHandle; yığının tepesine
  top()                               // → InputHandle | null
  setBinding(action, codes);          // yeniden atama, kayda settings yazar
  beginFrame(); endFrame();
  // Düşük düzey: DOM ve test aynı kapıdan besler
  keyDown(code, { repeat = false, editable = false, key }); keyUp(code);
  pointerDown(e); pointerMove(e); pointerUp(e); wheel(e); blur();
  // Sanal: HUD dokunmatik düğmeleri
  virtualDown(action); virtualUp(action); virtualTap(action);
  pointer;                            // { x, y, ndcX, ndcY, type: 'mouse'|'touch'|'pen', down: boolean }
  stack;                              // InputHandle[], alttan üste: __tanhu.state().inputStack
}

InputCtx = {
  id,                  // 'game' | 'map' | 'menu' | 'book' | 'dialogue' | 'cine' | 'roadcard' | 'wait_wheel' | 'transfer' | 'plan' | ...
  modal: false,        // true: alttakiler hiçbir şey almaz, live=false
  actions: null,       // null: tüm eylemler. Dizi: yalnız bunlar bu bağlama yazılır, gerisi alta düşer
  onKey(e) {},         // { code, repeat, key } → true ise tüketilir; key e.key: yerleşime bağlı kısayol (Türkçe Q'da «-» fiziksel Equal)
  onPointer(e) {},     // { phase: 'down'|'move'|'up'|'cancel', id, x, y, button, buttons, type } → true; buttons bit maskesi (1 sol, 2 sağ, 4 orta; bilinmiyorsa −1): farede ikinci tuşun basışı ve bırakışı `move` olarak gelir (K27)
  onWheel(e) {},       // { dy, dx, mode, shift, ctrl } → true; paylaşılan nesne. dx yatay kaydırma (dokunmatik yüzey, Magic Mouse), mode deltaMode (0 piksel, 1 satır, 2 sayfa), ctrl kıstırma ya da Ctrl + tekerlek
  onEscape() {},       // → true ise tüketilir
  onLost() {},         // live true→false: sürükleme, yol, basılı işaretleri sıfırla
  onLive() {},         // live false→true
}

InputHandle = {
  id, live,
  held(action),        // fiziksel basılı, live değilse false
  pressed(action),     // bu karede, bu bağlam live iken gelen yeni basış
  released(action),
  holdTime(action),    // sn; basış bu bağlam live iken başladıysa, yoksa 0
  moveAxis(out),       // [x, z] normalize: move_left/right, move_up/down (kuzey −z)
  pop(),               // yığından çıkar; alttaki onLive alır
}
```

**Davranış.**
1. `keyDown` tepeden aşağı dolaşır: `onKey` true dönen ya da `modal` olan bağlamda durur. Eylem basışı yalnız o andaki live bağlama yazılır.
2. Modal gelince alttaki bağlam `onLost` alır. Çıkınca `onLive` alır. Modal sırasında basılıp hâlâ tutulan tuş `held` true verir, `pressed` ve `holdTime` vermez: diyaloğu `E` ile kapatınca aynı `E` yeniden etkileşmez (denetim §f), `W` tutuluyorsa yürüme sürer.
3. `blur` ve gizlenme: fiziksel durum silinir, bütün bağlamlar `onLost` alır, sonra live olan `onLive`. `atlas.js` ve `game.js:252` hataları böyle kapanır.
4. Odak `input`, `textarea`, `select`, `contenteditable` üstündeyse `editable=true`: yalnız `Escape` geçer ve odağı bırakır.
5. `Escape` tepeden aşağı `onEscape` sorar. Kimse tüketmezse `onEscapeUnhandled` (App: `freeroam`, `play` → `pause`). Yani sıra: modal, harita, duraklatma.
6. `F5`, `F9`, `Tab`, `Space`, ok tuşları ve `Slash` (Firefox'un hızlı bulması; K27 `cam_reset`) live bağlam eylemi ise `preventDefault` (`GUARDED_CODES`). `F11` hiç bağlanmaz.
7. `wheel` canvas üzerinde dinlenir, `passive: false` (denetim hatası). `#ui` `pointer-events: none`; açılan DOM katmanı kendi `pointer-events: auto` ile olayı alır, canvas'a düşmez.

`DEFAULT_KEYMAP` (`core/keymap.js`). Tuş dağılımı `act1.md` §15, `survival.md`, `economy.md`, `progression.md`, `army.md` §6.1 ile aynıdır:

```js
move_up:['KeyW','ArrowUp'], move_down:['KeyS','ArrowDown'], move_left:['KeyA','ArrowLeft'], move_right:['KeyD','ArrowRight'],
sprint:['ShiftLeft','ShiftRight'], jump:['Space'], use:['KeyE'], crouch:['KeyC'], quick:['KeyQ'], sling:['KeyF'],
fire_kit:['KeyY'], drop_load:['KeyG'], douse:['KeyF'], map:['KeyM'], pack:['KeyI'], tasks:['KeyJ'], ledger:['KeyL'], skills:['KeyK'],
bar1:['Digit1'], bar2:['Digit2'], bar3:['Digit3'], bar4:['Digit4'], bar5:['Digit5'], bar6:['Digit6'],
cmd_follow:['KeyZ'], cmd_hold:['KeyX'], cmd_look:['KeyG'], cmd_charge:['KeyV'], cmd_loose:['KeyR'], cmd_form:['KeyB'],
pause:['Escape'], save:['F5'], load:['F9'], wait:['KeyT'], build_mode:['KeyP'],
cam_left:['Comma'], cam_right:['Period'], cam_reset:['Slash'],
ui_up:['ArrowUp','KeyW'], ui_down:['ArrowDown','KeyS'], ui_left:['ArrowLeft','KeyA'], ui_right:['ArrowRight','KeyD'],
ui_ok:['Enter','NumpadEnter','Space'], ui_back:['Escape'], ui_prev:['KeyQ'], ui_next:['KeyE'],
ui_sec_prev:['KeyZ'], ui_sec_next:['KeyC'], ui_tab:['Tab'],
```

`wait` (`T`, K20) her pakette Bekle tekerini açar; döşekte Uyu'yu, ateş başında Dinlen'i, şantiyede Çalış'ı da gösterir (§3.23); eski `mood` eylemi kalktı, geliştirmede ışık `__tanhu.clock` panelinden sürülür (§8 karar 40). `douse` ve `sling` aynı tuşu paylaşır: `survival.md` söndürme `F` basılı 1 sn ateşin yanında, sapan kısa basış; ateş yakınsa `InteractDriver` tüketir. `cmd_look` ve `drop_load` da `G`'yi paylaşır: kısa basış `cmd_look` (Ku yanındaysa), 0,6 sn basılı `drop_load` (`holdTime`).

`build_mode` (`P`, K23) yerleşim ve ordugâh dünyasında Plan Kipi'ni açar (§3.27; başka yerde «Burada yurdun yok.» / «You hold no ground here.»). `plan` bağlamı modal değildir: `actions` listesi `ui_prev`, `ui_next` (Q, E: 15° döndürür; `sprint` (Shift) basılıyken 5°), `sprint`, `ui_tab`, `ui_back`, `quick`, `use`, `cmd_loose` ve `build_mode`'dur (Plan Kipi'nde koşu yoktur); `onKey` `Delete`'i (Sök), `onEscape` `Esc`'i (iptal edilecek yerleştirme varsa iptal eder ve true döner; yoksa false döner, `onEscapeUnhandled` duraklatmayı açar), `onPointer` sol ve sağ tıkı, `onWheel` tekerleği tüketir. Böylece Q (`quick`), E (`use`) ve R (`cmd_loose`) oyuna düşmez; ayrı bir `rotate` eylemi yoktur. `wait_wheel` ve `transfer` modal bağlamlardır: açıkken dünya saati durur (§3.23).

**Kamera döndürme (K27).** `cam_left` (`Comma`) ve `cam_right` (`Period`) basılı tutuldukça 110°/sn döner (0,12 sn hızlanma, bırakınca 0,05 sn duruş); `cam_left` açıyı azaltır (haritanın Q'su gibi). `cam_reset` (`Slash`) 0,5 sn'de kısa yaydan kuzeye hizalar. Oyun bağlamında `onWheel`: `ctrl` her zaman yakınlaştırır; `shift` döndürür (`dx`, `dx` 0 ise `dy`) ve yakınlaştırmaz; ikisi de yoksa baskın eksen kazanır: yatay döndürür (piksel başına +0,25°; satır 16 px, sayfa 100 px), dikey işaretiyle yakınlaştırır (`ZOOM.wheelStep`). Orta tuş (`button` 1) yatay sürüklemeyle piksel başına 0,25° döndürür (sağa sürükleme açıyı azaltır, haritanın sağ sürüklemesi gibi); 4 px ve 300 ms (duvar saati) altındaki sürüklemesiz orta tık kuzeye hizalar. İkinci tuşun basışı ve bırakışı `move`'da `buttons`'tan okunur (`Game.syncButtons`; yalnız basışını Game'in aldığı işaretçide): yürürken orta tuşla dönülür, sürükleme sol tuşla takılı kalmaz. Sağ tık nişandır (`survival.md` §4); Q `quick`, E `use` kalır; haritada ve Plan Kipi'nde Q, E döndürmeye devam eder ve seçilen açıya dokunmaz. Odada, sinemada ve yaw yazan kamera isteği sürerken dönüş girdisi yutulur (§3.7). Tuş adları `ui/menu/book-glyphs.js` `keyLabel(code)`'dan, `navigator.keyboard.getLayoutMap()` varsa dizilişten okunur (Türkçe Q'da `Comma` «Ö», `Period` «Ç», `Slash` «.»); HUD tuş kapakları ve ipucu (`strings/hud.js` yer tutucularıyla), etkileşim istemi (`game/interact.js`), atlas kapatma kapağı ve kitap ipuçları (`capFor`) da bundan geçer; diziliş okunamazsa ABD adları kalır.

### 3.3 Dil (`i18n/index.js`, saf; `i18n/load.js` Vite'a özel)

```js
export function t(key, vars)      // → string. Eksikse TR'ye düşer, ikisi de yoksa geliştirmede ⟦key⟧
export function L(pair, vars)     // pair: { tr, en } → string. Veri tablosu satırları için
export function lang()            // 'tr' | 'en'
export function setLang(l)        // onHtmlLang kancasıyla <html lang> yazar (büyük harf CSS İ/I), i18n:lang yayar; kancayı load.js verir, index.js document bilmez
export function addStrings(table) // { 'menu.new_game': ['YENİ OYUN', 'NEW GAME'], ... }
export function has(key)
export function upper(s)          // toLocaleUpperCase(lang()): "Yükle" → "YÜKLE", en "Load" → "LOAD"
export function bindText(el, key, vars)   // el.textContent yazar, dil değişince yeniler; → unbind
export function missing()         // geliştirme: bulunmayan anahtarlar
export function configure({ bus, onHtmlLang, dev })   // dış bağlar: load.js ve testler verir, verilmeyen alan değişmez
// i18n/load.js (Vite'a özel)
export function loadI18n({ bus, root, dev, modules })  // App kurulurken bir kez, her t'den önce; bus zorunlu
export function loadStrings(modules)                  // strings/*.js, yol sırasıyla
```

- **Dizge dosyası.** `src/i18n/strings/<alan>.js`: `export default { 'alan.anahtar': ['TR', 'EN'] }`. Yer tutucu `{ad}`. `load.js` hepsini `import.meta.glob` ile okur; dosya eklemek için başka dosya düzenlenmez. Testler tabloyu doğrudan `addStrings`'e verir.
- **Hangisi ne zaman.** Çerçeve metni anahtar: `t('hud.map')`. Veri satırı yerinde çift: `name: { tr, en }`, `L(row.name)`. `geography.js` satırları `t('geo.<table>.<id>.name')`, kimlik denetim §d şeması.
- **Dil değişince yenilenenler:** `bindText` kullanan her yer; `i18n:lang` dinleyenler: atlas `it.bw/bh` önbelleği ve `buildLocals`, HUD ipucu, kitap sayfaları, oluşturucu satırları, Yol Kartı.
- **Biçim.** `format.js`: `fmtNumber(n)` (TR virgül), `fmtDuration(s)` («1 sa 10 dk» / «1 h 10 m»), `fmtDate(unix)`.
- **Mantık metne bağlanmaz.** `atlas.js:1018-1020` kırıntı karşılaştırması kimliğe geçer (1.2).

### 3.4 Ayarlar (`core/settings.js`, saf)

```js
export class Settings {
  constructor({ store, bus, schema = SETTINGS_SCHEMA })
  load(); save();          // tanhu.settings, ≤2 KB; kitap kapanınca save
  get(key); set(key, value);   // settings:change
  on(key, fn);             // → off; hemen bir kez çağırmaz
  reset(section);
}
```

| Anahtar | Varsayılan | Değerler | Okuyan |
|---|---|---|---|
| `lang` | `null` | `tr`, `en` | App, i18n |
| `audio.master`, `.music`, `.voice`, `.sfx`, `.ambience` | 1, 0,75, 1, 0,9, 0,8 | 0..1 | audio (`audio.md` §1) |
| `game.camFollow` | `normal` | `soft` 3,5, `normal` 5,5, `tight` 9 | camera-rig |
| `game.fov` | `normal` | `narrow`, `normal`, `wide`: −4°, 0, +6° | game; menü etkilenmez |
| `game.hints` | true | | hud |
| `game.clockShow` | `phase` | `phase`, `hour` | hud/clock.js: Gök Kavisi altında «Evre / Phase» ya da «Evre ve saat / Phase and hour» (K20, `time.md` §11) |
| `game.questMarker`, `.npcMarker` | true, true | | quests, npcs (`act1.md` §13) |
| `game.rideAssist` | `off` | `off`, `some`, `more` | pursuit |
| `game.ringAssist` | `off` | `off`, `wide`, `auto` | gather, cooking (`economy.md` §13) |
| `game.whistleInput` | `hold` | `hold`, `double` | squads (`army.md` §6.1) |
| `video.painterly` | true | | post: `post.painterly`, kapalıyken Kuwahara geçişi atlanır; App bağlar, değişince bir kare çizdirir |
| `video.uiScale` | 1 | 0,8, 0,9, 1 | menü ölçeği `k` |
| `video.quality` | `auto` | `auto`, `low` | `?q=low` ile aynı; değişince App `resize()` |
| `a11y.reduceMotion` | false | | travel Akış, atlas nabzı, kamera sarsıntısı (yakın yıldırım dahil); ekran yağışı 3 → 1 katman; Bekle akışı yerine doğrudan karartma |
| `a11y.flashes` | `full` | `full`, `soft`, `off` | world/weather: şimşek nabzı (`weather.md` §9.6); `soft` ×0,35, tek vuruş, ≤2,5 parlama/sn; `off` pozlama değişmez, şerit ×0,3 |
| `a11y.subtitles` | true | | subtitle |

Zorluk ayar değil kayıt alanıdır (`difficulty`): yolculuğa bağlı, kitap sayfasından değişir.

### 3.5 Kayıt (`game/save.js`, saf; `core/store.js`)

```js
// core/store.js
export class Store {
  constructor(backend = globalThis.localStorage ?? memoryBackend())
  read(key);  write(key, string) /* → boolean */;  remove(key);  usage() /* → bayt */;
}

// game/save.js
export class SaveManager {
  constructor({ store, bus, clock })
  setRules({ xpCurve, levelCaps, statCaps, axisCaps, skills, items, derive, autosaveBlocked });   // tablolar sonraki fazlarda; verilmeyen denetim atlanır; items denetimi İnce İş ekini atar (baseId: 'hun_bow+' geçerlidir, K24)
  registerBlock(path, { order, v = 1, serialize, restore, reset, migrate = {}, maxBytes = null })
  // path noktalı: 'economy.needs', 'world.travelNet'. serialize → düz JSON. restore(obj, record). reset(init): init = { origin, appearance, difficulty }. migrate[n]: n → n+1.
  newJourney({ origin, appearance, difficulty })  // bütün blokların reset(), yuva 0'a ilk yazım
  list();                 // → SlotInfo[11], 0 oto, 1..10 elle
  latest();  hasAny();
  write(slot, { thumb = null, reason = 'manual' });   // → SlotInfo. Oto yuva 0
  autosave(reason, { force = false, thumb = null });  // ≥60 sn sınırı; force: tablo aşağıda
  read(slot);             // → record | null: JSON, schema, migrate, progression.md §13.3 kırpmaları
  apply(record);          // restore çağrıları order artan, sonra derive
  remove(slot);
  exportJson(slot);  importJson(text);    // .tanhu.json
  readRoam();  writeRoam(obj);            // tanhu.roam, yolculuktan bağımsız
}
SlotInfo = { slot, empty, corrupt, saveNo, savedAt, savedUnix, playTime, act, day, minute, phase, slice, level, place: { world, region, labelKey }, thumb, failed? }   // failed: yazılamadı, eski kayıt duruyor; kart evreyi yazar («Gün II, ikindi»), slice eski kayıtlar için
```

Biçim `progression.md` §13.2; zarfa tek ek `blockV` (yalnız sürümü 1'den büyük blok varsa), `meta.place` ve `meta.phase` kayıtlı blok olabilir (`meta.phase`'i `ClockSystem` zonun `DayInfo`'sundan yazar; `meta.minute` `world.clock.minute`'tan, `meta.slice` evreden türer, eski kayıtta `world.slice`'tan). Anahtarlar `tanhu.journey.<slot>`, `tanhu.thumb.<slot>`, `tanhu.roam`, `tanhu.settings`. Boyut ≤96 KB metin, ≤24 KB küçük resim; kota aşılırsa eski oto küçük resim silinir, «Kayıt alanı doldu.» / «Save space is full.».

| Blok yolu | `order` | Sahip | Not |
|---|---|---|---|
| `difficulty`, `pos`, `yaw`, `mounted` | 10 | `game/journey.js` | `difficulty` Faz 5'ten 10.8'e dek App'te (§8 karar 30) |
| `flags` | 20 | `game/flags.js` | Bilinmeyen bayrak korunur |
| `player`, `axes`, `oaths` | 30 | `game/progress.js` | |
| `inventory` | 40 | `game/inventory.js` | `equip`, `arrows`, `bell` |
| `economy.pack`, `.tools`, `.chest`, `.seized`, `.stash`, `.cart`, `.sled`, `.cache`, `.saddlebags`, `.perish` | 41 | `game/inventory.js` | `travel.md` `inventory.stash` yazmaz (§8); blok sürümü 2 (`registerBlock(…, { v: 2 })`, `blockV`; `progression.md` §13.2'nin `economy.v`'si budur; göç 1 → 2 yeni alanları boş açar). Yalnız kişisel kaplar; yerin kapları `settlement`'ta, şantiye yığını `world.sites`'ta, Erzak Ambarı `camps`'ta (K24) |
| `economy.needs` | 42 | `game/needs.js` | |
| `economy.ledger`, `.ledgerToy` | 43 | `game/supply.js` | |
| `economy.nodes`, `.nodesV`, `.stats` | 44 | `world/nodes.js` | |
| `mounts` | 50 | `game/mounts.js` | |
| `carts`, `travel`, `world.travelNet` | 55 | `game/travel.js` | |
| `survival.recipes`, `.fires`, `.fauna`, `.snares` | 60 | cooking, campfire, fauna, hunting | |
| `world.clock` | 69 | `game/clock-system.js` (`WorldClock.toJSON`) | `{ v, dayN, minute, holds }` (K20) |
| `world.zone`, `.act`, `.day`, `.calendar`, `.jobsToday`, `.jobTypesDone`, `.moonClock`, `.dawnPath` | 70 | `game/calendar.js`; `moon-clock` son ikisini yazar | `day` hikâye günüdür; `calendar`: `{ v, beats, mainDone, moonEpoch }`; `slice` ve `workPoints` kalktı, göç: `slice` → dakika (sabah 08:00, öğle 12:00, akşam 17:00, gece 21:00), `workPoints` atılır (`time.md` §13) |
| `world.regions`, `.lookouts`, `.rb` | 71 | `game/regions.js` | |
| `world.atlas_revealed`, `.era` | 72 | `game/progress.js` | |
| `world.structures` | 73 | `world/structure.js` | Dünya kurulduktan sonra okunur |
| `world.npcs` | 74 | `game/npcs.js` | |
| `world.sites` | 76 | `game/sites.js` | K21: zon başına şantiyeler ve sıkı yapı dizisi (saplı ok ve yanık izi yok, can nicemli, ≤8 yırtık); bütün zonlarda ≤20 KB; senaryo yapıları `world.structures`'ta (73), ordugâh çadırları `camps`'ta |
| `settlement` | 77 | `game/settlement/index.js` | K23: hane, ustalar, iş kodu, Çekim, ambar içerikleri (`StorePool`), tezgâh kuyrukları, sürüler, kervan buyrukları ve yoldaki yük, alınan küme, Divan, bayraklar, Kronik; ≤14 KB (`settlement.md` §16) |
| `world.weather` | 78 | `game/weather.js` | K22, ≤1 KB: tohum, plan (≤10 bölüm; sabit çapadan yeniden üretilebilir), ıslaklık, kar örtüsü ve kabuk, kilitler, yıldırım beklemesi (`struck`, site kimliğiyle), söylenmiş işaretler; `world.sites` ve `settlement`'tan sonra okunur |
| `quests` | 80 | `game/quests.js` | |
| `army` | 90 | `game/squad/index.js` | `Follower` yazılmaz |
| `camps` | 92 | `game/settlement/camps.js` | K23: ana ve sefer ordugâhı: kademe, `CampPlan`, konfor, Erzak Ambarı içeriği, kış dağılması; ≤4 KB |

**Oto kayıt nedenleri.** `dawn`, `sleep`, `wait` (≥1 oyun saati), `work` (≥1 oyun saati), `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`, `tier` (yerleşim kademesi), `caravan` (kervan varışı, ≥60 sn), `court_path` (V. kademe yolu). `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`, `court_path`. Sinema, boss fazı içi ve `ride` ortasında yazmaz; `pagehide` yine yazar, yükleme kalkış durağına koyar (`travel.md` §11).

**Yükleme zinciri** `progression.md` §13.3'ün 7 adımıdır; 1–6 `read`, 7 `apply` sonunda. **Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, clock:{day,minute}, flags, playTime, weather }` (`camp3` kendi `v: 2` sürümünü taşır, göç `structures.md` §11.8; `weather` yolculuk bloğuyla aynı biçim; `mood` artık yazılmaz, okunursa saate göç eder: >0,75 ise 18:38, değilse menü dakikası 14:46,2; yolculuk ≈83 KB ≤96 KB, Serbest Gez ek ≈40 B + hava ≤1 KB), `progression.md` §13.4; `freeroam.enter` okur, 30 sn'de bir, `leave`'de ve duraklatmadaki KAYDET'te yazar; dosyadaki öteki alanlar korunur. `flags` Destan Kitabı bayraklarıdır (`data/destan.js` `ROAM_FLAGS`), yolculuk onları okumaz.

### 3.6 Ses motoru (`audio/*`; `phrases.js`, `music-states.js` saf)

```js
export class AudioEngine {
  constructor({ settings, bus, clock })
  get now();  get unlocked();
  unlock();                 // idempotent; ilk jest
  bus(name);                // 'master'|'music'|'ambience'|'sfx'|'voice'|'ui' → GainNode; music ve ambience reverb gönderir
  setListener(camera);      // kare başına; null ise değişmez
  music;  sfx;  ambience;  voice;
}
```

Yol `audio.md` §1: kaynak → veri yolu → master → compressor → çıkış. Voice çalarken music −6 dB, ambience −3 dB, 0,4 sn. (K78: bu prototipin sayısıdır ve iki yönlü 0,4 sn'lik geçişiyle prototipte kalır; Godot'da kısma durum türüne göredir, −6 / −3 tablonun gündelik satırıdır: `audio.md` §1, `godot.md` §3.3.)

```js
// audio/music.js
music.setState(id, { at = 'bar', fade = 3 });   // id: MUSIC_STATES; at: 'bar' | 'now'; audio:music
music.state;
music.setLayer(name, gain, seconds);            // 'drone','pluck','bow','flute','drum','jaw','choir','rain'
music.setAmbientLayer(name, gain, seconds);     // 'pluck' | 'rain'; begin() silmez; yalnız ambient: true durumda; null geri alır (8.9)
music.setProximity(k);                          // chase: 0..1 ek katman
music.setSource(layer, { x, y, z } | null);     // Serbest Gez dombrası ozanın konumundan
music.stop(fade = 2);

// audio/music-states.js
MUSIC_STATES[id] = { id, bpm, meter: '6/8', mode: 'd_dorian'|'e_phrygian'|'major_pent',
  motif: 'A G F D', layers: { drone: {...}, pluck: {...} }, phraseWeights: { A:4, A2:2, B:2, rest:1 } }
// id: camp, camp_bard, crane, narration, creator, winter_day, winter_evening, winter_night, tension,
//     raid, erlik, tengri, chase, dawn, home, road_leg, camp_night (8.9), hold, hold_night, court, muster (9.9)
```

Sıralayıcı `scheduler.js`: `setInterval(100)` ve `ctx.currentTime`, 0,4 sn ileri; `requestAnimationFrame`'e bağlı değildir. `phrases.js` saf: `phrase(stateId, seed, barIndex)` → `[{ t, dur, inst, midi, vel }]`, ±8 ms, ±%12 insanîleştirme, akor yok; `node:test` denetler.

```js
// audio/sfx.js
sfx.play(id, { at: [x, y, z] | null, gain = 1, pitch = 1, bus = 'sfx' });   // → handle | null; sınır dolunca null
sfx.loop(id, { at, gain, rate });                                           // → { setGain, setRate, setPos, stop(fade) }
sfx.has(id);  sfx.warm(ids);   // sahne başına ön üretim, yükleyicide; dilimli, kare başına ≤4 ms, ana iş parçacığını kilitlemez

// audio/sfx/<alan>.js: reçete
export default {
  chop: { variants: 2, pitchVar: 0.06, gainVar: 2, limit: 6, dur: 0.2, render(ctx, rng) { /* OfflineAudioContext düğümleri */ } },
};
```

**Efekt kimlikleri** `audio.md` §4'tür; ek: `post_knock`, `wheel_snow` (`travel.md` §14); `clean_strike`, `load_thud`, `notch`, `cook_sizzle`, `balance_tick` (`economy.md` §3.7); `bone_clack`, `sling_whirl` (`progression.md` §14.2); `whoosh`, `page_turn` (`menu-spec.md`); K20–K24 ekleri tablonun son dört satırı ve `torch_post`'tur (`audio.md` §4). `thunder` (`sfx/world.js`) orta uzaklıktır (0,6–3 km); ≤600 m `thunder_crack`, 3–10 km `thunder_far`, gecikme `d / 343` sn. Alan dosyası eşlemesi:

| Dosya | Kimlikler |
|---|---|
| `sfx/ui.js` | `ui_hover`, `ui_click`, `ui_whoosh`, `whoosh`, `ui_page`, `page_turn`, `ui_deny`, `ui_toast`, `level_up`, `quest_new`, `quest_done`, `item_get`, `skill_learn`, `discover`, `oath`, `notch`, `balance_tick` |
| `sfx/foot.js` | `step_grass`, `step_dirt`, `step_snow`, `step_wood`, `step_felt`, `bell_step`, `jump`, `land`, `cloth_swish`, `pain`, `breath_out` |
| `sfx/weapon.js` | `sword_swing`, `knife_swing`, `bow_draw`, `bow_release`, `arrow_fly`, `arrow_hit_felt`, `arrow_hit_wood`, `arrow_hit_flesh`, `sword_hit_felt`, `sword_hit_wood`, `sword_hit_metal`, `whistling_arrow`, `shrieker`, `bone_clack`, `sling_whirl` |
| `sfx/structure.js` | `hammer_wood`, `tie_rope`, `felt_flap`, `lattice_creak`, `pole_drop`, `collapse_small`, `collapse_big`, `fire_catch`, `fire_burst`, `stage_done`, `structure_fire` (döngü, 3B, yanan yapının tepesinden; Faz 6), `torch_post` (K21: şantiye meşale direği, gece, ≤2 kaynak) |
| `sfx/gather.js` | `chop`, `tree_fall`, `pick_stone`, `pick_ore`, `gather_soft`, `ice_cut`, `splash`, `clean_strike`, `load_thud`, `cook_sizzle` |
| `sfx/horse.js` | `hoof_walk`, `hoof_trot`, `hoof_gallop`, `horse_snort`, `horse_neigh`, `horse_rear` |
| `sfx/world.js` | `wolf_howl`, `eagle_cry`, `crow`, `dog_bark`, `sheep`, `thunder`, `ice_crack`, `heartbeat`, `alarm_horn`, `drum_hit`, `bone_hum`, `mene_hum` |
| `sfx/travel.js` | `cart_loop`, `travel_start`, `travel_arrive`, `post_knock`, `wheel_snow` |
| `sfx/time.js` | `meal_call`, `night_drum`, `wait_lapse`, `wake` (K20) |
| `sfx/economy.js` | `felt_roll`, `bellows`, `anvil`, `adze`, `tan_scrape`, `shear_snip`, `milk_pail`, `store_open`, `cart_unload`, `loot_search`, `craft_done` (K24) |
| `sfx/weather.js` | `thunder_crack`, `thunder_far`, `static_hum`, `gust`, `rain_drip`, `hail_tick`, `tinnitus` (K22; reçetede `sr: 22050`, 22,05 kHz) |
| `sfx/settlement.js` | `plan_place`, `plan_rotate`, `household_arrive`, `caravan_depart`, `tier_up`, `dawn_bow`, `omen_strike`, `assembly_drum` (K23) |

```js
// audio/ambience.js
ambience.set([{ id: 'wind_winter', gain: 1 }, { id: 'camp_day', gain: 0.6, at: [0, 2, 0] }], { fade = 2 });
// satır { id, gain, at?, lp? }: lp (Hz) verilince döngüde kazançla panel arasına alçak geçiren BiquadFilter (9.8; far_rain), nodes() onu 4 sayar
// id: wind_steppe, wind_winter, blizzard, fire_loop, night_meadow, birds_day, camp_day, yurt_inside, ice_groan, water_reed;
//     hava (9.8): rain_light, rain_heavy, rain_felt, hail_bed, wind_gale, dust_storm (planda cephe ≥1 oyun saati önce görününce dilimli pişer, geçtikten 1 sa sonra bırakılır);
//     yerleşim (9.8): hold_day, herd_flock, camp_army, gathering_crowd (yalnız yerleşim ve ordugâh dünyalarında); hepsi 22 kHz mono

// audio/voice.js
voice.play(lineId, { at = null, chain = null, onEnd = null, text = null });   // → { stop(), done: Promise, duration, voiced }
voice.preload(ids);          // → Promise; duration kesinleşir
voice.duration(lineId, text = null);   // → sn; dosya yoksa speechSeconds(text ?? textOf(lineId))
voice.buffer(lineId);        // → çözülmüş AudioBuffer | null: konuşanın ağzı zarfını izler (npc.js perform, Faz 5)
voice.stopAll(fade = 0.2);
export const speechSeconds = (text) => clamp(text.length / 14 + 0.6, 1.6, 12);
```

**Ses satırı.** Dosya `public/audio/vo/en/<id>.mp3`, kimlikte `/` yok. Eksikse hata değil: `done` süre sonunda çözülür, altyazı akar (`audio.md` §5). `chain: 'erlik'` alçak geçiren ve yankı zincirine bağlar. `done` her durumda çözülür; `stop` da çözer.

**Faz 3 ekleri (3.6, 3.7, `L`).**

- **Kurulum.** App yapıcıda: `audio = new AudioEngine({ settings, bus, clock })`, `audio.sfx = new Sfx(audio)`, `audio.ambience = new Ambience(audio)`, `audio.voice = new Voice(audio, { events: bus, textOf })`, `clock.audio = audio`, `ctx.audio`. `textOf` `story/vo-lines.js`'tir (Faz 5): dosyası olmayan satırın süresi söylenen İngilizce metinden, ses etiketleri olmadan.
- **Motor.** `nodes()`, `track(node)`, `release(node)`, `source(buffer, { loop, onEnd })`, `gain(v)`, `makeBuffer(channels, rate)`, `forget(buf)`, `reverbIn()`, `mute(on)`, `dispose()`, `bytes` (müzik ve yankı, ≤16 MiB; K59 ile değişti: prototipin ses tablosu 48 MiB'tır, müzik 16, efekt ve ortam 24 (`BAKE_BUDGET`), satır penceresi 8 (`VOICE_BUDGET`); K12'nin 40 MB'ı kalktı, toplam havuzların toplamıdır; `audio.md` §4), `peak`; 9.8 ekler: `duck(bus, dB, seconds)` (zamanlı veri yolu inişi: `target()` çarpanına girer, `apply()` onu silmez; yakın yıldırım, `audio.md` §4). Müzik veri yolu `app:state` ile `map`'te −3 dB, `pause`'da −6 dB iner (§2.2): durumlar bunu çağırmaz.
- **Müzik.** `phrase(stateId, seed, bar, { bpm, intensity, humanize })`; nota alanları ek olarak `lane`, `variant`, `glide`; `MUSIC_STATES` alanları ek olarak `drone`, `parts`, `motifEvery` ya da `motifAt`, `bpmEnd`, `rampBars`, `proximity`, `ambient` (8.9). `boot`, `language`, `epigraph`'ta yalnız dron; menüye girişte motif ölçü başından. `rain` katmanı (çan damlaları) `setAmbientLayer('rain', g)` çağrılana dek sessizdir; çağıran `ctx.weather`'dır (8.10), yalnız ortam durumlarında (`camp`, `camp_night`, `winter_day`, `winter_evening`, `winter_night`, `hold`, `hold_night`; katmanı yalnız `bell` partisi çalar: 8.9 `music-states.js`'te `camp_night`, `winter_day` ve `winter_evening`'e `{ role: 'bell', p: 0.4, vel: 0.24 }` ekler, 9.9 `hold` ve `hold_night`'a; `home` ve `road_leg`'de hava çalışmaz): çisenti 0,35, yağmur 0,2, sulu kar ve kar 0,15, yoğun kar 0,1, yağmur sonrası 0,45 (0,5 sa'te söner); `begin` her durum değişiminde `setLayer` geçersiz kılmalarını (`override`) sıfırladığından hava ve gündelik müzik seçicisi `setLayer` değil `setAmbientLayer` kullanır: kazanç durum değişiminde kalır, yalnız `ambient: true` durumda uygulanır (`audio.md` §3); yakın gök gürültüsü müziği 2 sn −3 dB indirir; hikâye müziklerine dokunulmaz (`weather.md` §10.3). Gündelik müzik `clock:phase` ve saatle seçilir (seçici `app/sounds.js`, `L`), sahne ve görev durumu önce gelir; atlamada durum varış saatine göre seçilir, geçiş karartma içinde biter (K20).
- **Efekt.** Reçete alanları `db, rate, sr, loop, seam, glide, ref, rolloff, boot, use, norm`, `render(ctx, rng, k, variant)`; `play` seçenekleri ek olarak `delay, variant, range`; `loop` seçenekleri `range, fade`; `sfx.ready(id)`, `stopAll(fade)`, `nodes()`, `table()`, `stats()`, `list()`. `ambience.warm(ids)`, `stop(fade)`, `current()`; 9.8 ekler: `sfx.release(ids)`, `ambience.release(ids)` (cephe geçince bırakma: girişin tamponları çalmıyorsa boşalır, `bytes` düşer; `audio.md` §4 «Bellek»). `voice.has(id)`, `textOf`, `lang`; `done` → `{ line, voiced, stopped }`. Önbellek tavanı efekt ve ortam 16 MiB (`BAKE_BUDGET`), çözülmüş satır 16 MB (Faz 5: Yeni Oyun'un dokuz satırı 48 kHz mono ≈10 MB; 8 MB'ta üçü çalınmadan düşüyordu, bir sinemanın ön yüklediği satırlar birlikte sığmalı). Menü düzeyleri `menu-spec.md`'dir: kitap açılışı `gain` 1,58, kapanışı 1,26; `gather_soft` `variant` 0–1 saz, 2–3 yumuşak.
- **`__tanhu.audio`.** `state, sfx, sfxList, ambience, voices, mute, nodes` ve ek olarak `memory()` (MB: müzik, fırın, satır, toplam), `bake()`; `nodes()` motor, efekt, ortam ve satırı toplar.
- **Oyun sesi (`app/sounds.js`, `L`).** `SoundSystem` (§3.7, `order` 110): `place`'te oyuncu aktörünün `stepped` işaretiyle adım (yurtta `step_felt`, ahırda ve ocağın 2,6 m'sinde `step_dirt`, kalanı `step_grass`; çömelme 0,55, koşu 1,25 kazanç), `jump`, `land`; binilen atın `phase` ve `g`'sinden toynak (yürüyüşte devir başına 4 `hoof_walk`, tırısta 2 `hoof_trot`, dörtnalda 1 `hoof_gallop`); ahırdaki binilmeyen attan 14–34 sn'de bir `horse_snort`, dörtte bir `horse_neigh`, kameradan ≤70 m. Aynı sistem `app:state` dinler: `menu`, `newgame` → `wind_steppe` 0,55 + ocaktan `fire_loop` 0,9 (4 sn); `freeroam` → evrenin listesi (`spec.audio.ambience.{dawn, morning, noon, golden, dusk, night}`, `time.md` §8.5; 8 sn'de süzülür; `moodTarget` eşiği kalktı), `home` → `golden` listesi (saat iğneli); `creator` susturur; listede olmayan durum çalanı bırakır. Kamp dünyası bağlanınca adım, toynak, at ve beş ortam döngüsü (`wind_steppe`, `fire_loop`, `camp_day`, `night_meadow`, `birds_day`) dilimli ön üretilir. Kış zemini ve başka dünyaların ortamı o dünyanın sahibinindir (Faz 9). **Hava (K22).** `SoundSystem` havanın döngü listesini kendisi kurmaz, `ctx.weather.audio`'yu okur: `{ beds, windK, windSwap, quiet, inside }`. Taban listede rüzgâr döngüsü × `windK` (`windSwap` ise `wind_gale`'e geçer), öteki döngüler × `quiet`, sonra `beds` eklenir (9.8'e dek tanımsız döngü atlanır); yurt içinde yağmur `rain_felt`'e döner, rüzgâr ×0,4. `ambience.set` yalnız kimlik listesi değişince ya da bir kazanç 0,05'ten çok oynayınca, en çok 4 Hz çağrılır. Menü, `newgame`, `creator` listesi havasızdır. Kış dünyasının ve yerleşim dünyalarının ses sahibi aynı birleşimi yapar (`weather.md` §10.4).

### 3.7 Aktör, Game ve sistemler

```js
// character/actor.js
export const ACTOR_PROFILES = {
  child: { id: 'child', rootScale: 1.14, walk: 3.2, run: 5.6, crouch: 1.6 /* 2,2 × 3,2 / 4,4 */, jumpV: 5.4, gravity: 15, walkR: 0.36, rideR: 0.72,
           staMax: 80, staDrain: 12, hasHp: false, camera: 'child' },
  mete:  { id: 'mete', rootScale: 1, walk: 4.4, run: 7.6, crouch: 2.2, jumpV: 5.6, gravity: 15, walkR: 0.36, rideR: 0.72,
           staMax: 100, staDrain: 17, hasHp: true, camera: 'foot' },
  folk:  { id: 'folk', /* mete ile aynı sayılar */ },   // Yetişkin Folk; ayrı satır: player.js'in Mete'ye yazdığı hız kalabalığa geçmez
};
// Sonraki aktör: bir satır ve GameActor sağlayan Rig türevi. Game değişmez.

// Rig türevleri (Folk, MeteAvatar) bu yüzü verir. Game başka bir şey bilmez.
GameActor = {
  root,                          // THREE.Group, rotation.order 'YXZ'
  profile,                       // ACTOR_PROFILES satırı; Mete'nin hızlarını player.js derive'dan yazar
  get seatHeight(),              // kök → eyer, ölçek öncesi. Folk: spec.hipY × d.height; Mete: hipsBind.y × opts.height
  update(dt, speed, jump, ride), // Rig.update
  play(name, dur),               // gestures kaydı
  carry(kind | null),            // sürekli poz: 'shoulder','hug','haul','man'; yeni poz eskisi söndükten sonra gelir. Rig.carryKind ve carryK çalan pozu ve karışımını gösterir
  attach(joint, object, { p, r }),  // joint: Rig eklemi, metre. Mete MeteAvatar.socket(joint) yuvasına takar: eksenler eklemle aynı, ×100 yuvada
  lookAtPoint, stepped, sitWant, sitK, crouchWant, benchK, strum, armMode,
  dispose(),
}
```

`rootScale` Game'de uygulanır: `root.scale.setScalar(profile.rootScale)`. Eyer: `root.y = seat.y − actor.seatHeight × rootScale`. `HERO_SCALE`, `.opts.height`, `JOG`, `SPRINT`, `JUMP_V` `game.js`'ten kalkar. Çömelme: `crouch` eylemi aç-kapa, `game.crouching`, `game.setCrouch(on)`, `actor.crouchWant`; hız `profile.crouch`; kamera `crouch` isteği. **Mete tek örnektir:** oluşturucu ve `play` aynı `MeteAvatar`'ı kullanır, `root` sahneler arasında taşınır, `markShared` taşır, dünya değişiminde silinmez. `mete.glb` Yeni Oyun ya da kayıt yüklemede bir kez açılır (`loadMeteAssets`). `Folk` görünüşleri `character/looks.js`'te; `coat.skirt` eteğe ayrı renk verir, yoksa `coat.color` (Çocuk: oturan çocuğun renkleri).

```js
// character/gestures/base.js; rig.js yeniden verir. Tablolar burada: alan dosyası rig.js'e bağlansa, rig.js'in gövdesinden önce çalışıp içe aktarma döngüsüne düşerdi.
registerGesture(name, fn);   // fn(J, k, e, to, rig): jest sürerken her kare. J eklemler, k 0..1, e giriş ve çıkış karışımı
registerCarry(name, fn);     // fn(J, e, to, rig): Rig.carry(name) açıkken her kare, jestten önce
to(joint, x, y, z, w = e);   // eklemi hedef açılara karıştırır. fn nesne ya da kapanış üretmez; kayıtsız ad görünmez, hata vermez

// character/rig.js
spec.ride = { thighX, thighZ, shinX, shinZ, footX, footY, footZ };   // eyerde sol bacak, sağ aynası. Çocuk: uyluk x −0,55, z 1,2; kaval örtüye girmesin diye dikten 0,17 rad dışa. Yetişkin: uyluk x −0,7, z 1; kaval dik
benchK;                      // 0..1: araba sırası, koltuğu süren yazar (travel.md §3.4)
get seatHeight();            // spec.hipY × joints.body.scale.y: Folk boyu d.height body ekleminde; MeteAvatar kendi hipsBind'ini verir
```

```js
export class Game {
  constructor({ ctx, world })
  // Okunur alanlar: squads, stealth, travel, HUD bunları okur
  camera; pos /* Vector3: x,z zemin; y yumuşak taban */; y; heading; speed; vy; grounded;
  wantMove; moving; blocked; sprinting; riding /* Horse|null */; mounting; room; roomK; roomX; roomZ;
  stats /* { hp, hpMax, sta, staMax } */; exhausted; restT /* yazılabilir: vuruşta 0 */; prompt /* aşağıda */; moved; actor; nav; navRide; get activeNav();
  cam /* CameraRig */; systems /* SystemHost */;
  crouching;
  moveMods;  // { speedK:1, canRun:true, canJump:true, jumpCost:8, staDrainK:1, staRegenK:1, turnK:1 } player.js ve child.js yazar; enter kip değişince varsayılana döndürür, haritadan dönüş aynı kiptir

  setActor(actor, { x, z, yaw, sit = false, snap = true });   // x, z, yaw verilmezse yer değişmez
  setWorld(world);                // arazisi etkin (setActiveTerrain), nav spec'ten, işaretçi ve toz sahneye, systems.onWorld
  enter(mode);                    // 'freeroam' | 'play' | 'home': input.push('game'), systems.setMode, aktör sahneye
  leave();                        // tutamak kapanır, aktör ayrılır; yol ve hız sıfır
  update(dt, t);                  // systems.preUpdate → hareket → systems.update → oda → placeActors → systems.place → kamera
  placeActors(dt, t, moving, landed);  // gerçek harita modunda da çağrılır (main.js:236 deseni)
  applyPost(s, mood);             // main.js:246-248 buraya taşınır
  moveTo(x, z, { onArrive });     // programla yürüme: Agent.moveTo ile aynı yol bulma
  stop();  snapCamera();  focus();  setAspect(a);
  queueJump();  setSprintToggle(on);  setCrouch(on);  interact();
  leaderPose(out);                // { x, z, y, h, v, mounted, moving } (army.md §5.1)
  damage(n);                      // hasHp false ise yok sayılır; player.js dinler
  nudge(x, z, speed);             // yapı belirirken itme (structures.md §12.5)
  ram(t);                         // dörtnaldaki atlı yapıya dayandı: öndeki yapıya horse_chest vuruşu, at durur (chestNoSlow: durmaz, Faz 8)
  shake(amp = 0.06, seconds = 0.3);   // kamera sarsıntısı (structures.md §5.5 büyük çöküş); süren daha güçlüsü ezilmez, placeCamera'dan sonra uygulanır
  seat(ride);                     // araba koltuğu: Ride { seatWorld(out), yaw, posture }; null bırakır
}

game.prompt = null | { label, key: 'E', holdK: 0..1, enabled: true, deny: null };   // HUD yalnız bunu çizer
```

**Faz 3 duman satırları (Faz 5'te kapandı).** `blocked`: WASD engele dayalı ve konum değişmedi (oturan kişi, ateş halkası, ahır parmaklığı); `speed` fizikte kalır (duruş yeri ve engel kalkınca adım aynı), ama aktöre ve ata giden yürüyüş hızı 0'dır: `placeActors` `actor.update(dt, 0, …)`, `mounted.js` `DRIVE.speed`, `RIDE.speed` ve toynak tozu 0; yürüyüş döngüsü, adım (`stepped`) ve toynak sesi yerinde çalmaz, yön yine döner. `dt` 0 karesi (`shot`) bunu açmaz. `targetPoint` ileri kayması `fwd × min(1, value.dist / presetDist)`: `presetDist` aktörün `CAM[profile.camera].dist`'idir (`setActor` yazar); ön ayardan yakına inildikçe kayma kısalır, `ZOOM.min` 13'te Çocuk kadrajın içinde kalır (NDC y −0,68; eskisi −1,41, kadraj dışı). Ön ayarın ötesindeki uzaklıklar (sürüş, çömelme, Tengri) değişmez.

```js
// game/systems.js
export class SystemHost {
  constructor(ctx);
  add(system);  get(id);  remove(id);
  setMode(mode);                  // mode içermeyen sistemlerin kancası çağrılmaz
  onWorld(world, nav);
  preUpdate(dt, t);  update(dt, t);  place(dt, t);
  collect(query, out);            // Interaction'ları toplar
  pick(query);                    // → PickResult | null; ilk sonuç kazanır, sistem order sırasıyla
  onRoom(room);  debug();  dispose();
  profile;  ms;                   // __tanhu.perf açar: sistem başına ms
}

GameSystem = {
  id, order, modes: ['freeroam', 'play'],
  attach(ctx),                    // bir kez
  onWorld(world, nav),            // her dünya; önceki dünyaya ait her şeyi bırak
  preUpdate(dt, t),               // oyuncu hareketinden önce: girdi oku, moveMods yaz
  update(dt, t),                  // hareketten sonra, placeActors'tan önce: benzetim
  place(dt, t),                   // placeActors'tan sonra: Rig ve instanced yazımı
  collectInteractions(q, out),    // q: { x, z, riding, grounded, handle }
  onPick(q),                      // q: { ray, ground: [x,z]|null, tapped, riding } → PickResult | null
  onRoom(room),                   // oyuncu odası değişti; null dışarı
  debug(),                        // __tanhu paneli için düz nesne
  dispose(),
}
// Hepsi isteğe bağlı, id ve order dışında.
```

| `order` | `id` | Modül | Mod |
|---|---|---|---|
| 5 | `mount` | `game/mounted.js` | ikisi, home |
| 10 | `player` | `game/player.js` | play |
| 12 | `child` | `game/child.js` | freeroam, home |
| 15 | `clock` | `game/clock-system.js` | freeroam, play, home (iğneli) |
| 20 | `calendar` | `game/calendar.js` (8.9) | play |
| 22 | `weather` | `game/weather.js` | ikisi |
| 30 | `regions` | `game/regions.js` | play |
| 40 | `quests` | `game/quests.js` | play |
| 45 | `dialogue` | `game/dialogue.js` | play |
| 50 | `gather` | `game/gather.js` | ikisi |
| 52 | `campfire` | `game/campfire.js` | ikisi |
| 54 | `cooking` | `game/cooking.js` | ikisi |
| 56 | `hunting` | `game/hunting.js` | ikisi |
| 60 | `structures` | `world/structure.js` | ikisi, home |
| 61 | `sites` | `game/sites.js` | ikisi, home |
| 62 | `builders` | `game/builders.js` | ikisi |
| 64 | `settlement` | `game/settlement/index.js` (9.9) | play |
| 70 | `combat` | `game/combat.js` | ikisi |
| 72 | `projectiles` | `game/projectiles.js` | ikisi |
| 74 | `telegraph` | `game/telegraph.js` | ikisi |
| 80 | `npcs` | `game/npcs.js` | play |
| 81 | `camp_life` | `game/camp-life.js` | freeroam |
| 82 | `fauna` | `game/fauna.js` | ikisi |
| 84 | `stealth` | `game/stealth.js` | play |
| 86 | `pursuit` | `game/pursuit.js` | play |
| 88 | `squads` | `game/squad/index.js` | ikisi (`?squad=10`) |
| 90 | `travel` | `game/travel.js` | play |
| 92 | `lanes` | `game/lanes.js` | play |
| 100 | `nodes` | `world/nodes.js` | ikisi |
| 110 | `sound` | `app/sounds.js` | freeroam, play, home |

`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures`, `sites`, iğneli `clock` ve `sound` çalışır; `weather` `home`'da çalışmaz (hava kimlik).

**Saat, hava, şantiye, yerleşim (K20–K24, `d2/core.md` §6).** `clock` (15) dünya saatini ilerletir, `world.lightBase`'i yazar; Bekle, Uyu, Dinlen, Çalış'ı, vakit çağrısını ve karartmayı yürütür (§3.23). `calendar` (20) vaktin durumunu ve uyku kapısını tutar. `weather` (22) saatten sonra, okuyucularından (`campfire`, `structures`, `sites`, `settlement`, `stealth`, `travel`, `nodes`, `sound`) önce çalışır: hepsi aynı karenin `ctx.weather.fx`'ini okur; `mount`, `player`, `child` (5–12) bir kare önceki `fx`'i okur. `sites` (61) şantiyeleri sürer (§3.25). `settlement` (64) yerleşim ve ordugâh durumunu, hangi dünya yüklü olursa olsun her `clock:hour`'da işler: önce Kâhya ekipleri yazar, sonra K21 `sites` şantiye emeğini, yerleşimin `production`'ı tezgâhları (`Workshop.tick`) ve toplama kolunu, `CampState` ve `CaravanBook`; `dawn`'da tüketim (`SupplyLedger`) ve sürü (`herdDay`), sonra Çekim, katılım, ayrılış, Gönül; `clock:skip`'te ≤3 gün saat saat, uzunu günlük adım; `act:change`'te Kronik (§3.27). K24 ayrı bir `GameSystem` kurmaz: `Container`, `Workshop`, `herdDay`, `transfer`, `armyShare`, `rolloverYears`, `SupplyLedger` saf servislerdir (§3.26). Yüklü dünya `spec.settlement` taşıyorsa görünüm, Plan Kipi ve etkileşimler açılır. `camp_life` (81) yalnız ana kampta, yalnız Serbest Gez'de çalışır. Görünür işçi `NpcManager.budget`'ını (16 tam, 40 kukla) paylaşır; ayrı bütçe yoktur.

**`ChildSystem` (`game/child.js`).** `weapon` (`'toy_bow'` | `'wood_sword'`), `seated`, `setWeapon(id)`: `progression.md` §13.4 `child.weapon` bunları okur ve yazar, bilinmeyen kimlik yok sayılır. `Q` değiştirir, oturan Çocuk ilk harekette (WASD, tıklanan yol, zıplama, çömelme) kalkar; kalkış bitene dek `moveMods` yerinde tutar. Yalnız `profile.id === 'child'` aktöre dokunur. **Faz 6:** sağ düğme silahı kullanır (ince `child_aim` bağlamı, Serbest Gez'den çıkınca kalkar): yayda basılı gerer (nişan halkası `telegraph`), bırakınca atar; kılıçta vurur, hedef erim dışındaysa önce yürür. `stow(on)`: yük taşıyan Çocuğun silahı görünmez, kol serbest, saldırı yok (`builders.js` çağırır); `stowed` okunur.

**Etkileşim (`game/interact.js`, saf).** Alan belgelerindeki `interact()`, `updatePrompt()`, `pick()` ve `issueMove()` eklemeleri (`economy.md` §12, `travel.md` §9.5, `army.md` §8) kod değil bu kayıttır (§8 karar 7).

```js
Interaction = {
  id,                 // 'node:1204', 'horse:yakwe', 'post:way_fold', 'quest:mq_ration.take'
  kind,               // 'quest'|'post'|'cart'|'horse'|'npc'|'fire'|'structure'|'node'|'item'
  priority,           // quest 100 > post 90 > cart 85 > horse 80 > npc 70 > fire 60 > structure 55 > node 50 > item 45
  x, z, reach,        // GATHER_REACH ve MOUNT_REACH 2,1 m; REACH_TAIL 2,6 m
  label,              // çözülmüş metin
  hold,               // 0: dokunma; >0: basılı sn
  enabled, deny,      // false: deny metni, ui_deny
  act(phase, k),      // 'tap' | 'start' | 'progress' | 'complete' | 'cancel'; k 0..1
  approach,           // [x, z] | null: tıklanınca yürünecek yer
  once,               // { flag, item } | null: tek seferlik; flags ve item birlikte denetlenir (act1.md §15)
}
PickResult = { kind, interaction, approach, path?, arrive?, consumed: true }   // path: hazır yol; arrive(x, z) → varıldı mı. tapped false: yalnız üzerine gelindi, sonuç yan etkisizdir, imleç `on-<kind>` olur

export function bestInteraction(list, x, z)     // → Interaction | null: reach içi, önce priority, sonra mesafe
export class InteractDriver {
  update(dt, handle, game)   // pressed('use') → tap ya da hold başlat; holdTime → progress; bırakınca cancel; complete → interact:done
}
```

**Kamera (`game/camera-rig.js`, saf).** Yalnız sayı üretir, `Game.placeCamera` uygular. Oda `roomK` karışımı mevcut koddur, sonuna uygulanır.

```js
export const CAM = {           // derece, metre
  foot:{pitch:28,dist:33,fwd:6.1}, child:{pitch:28,dist:26,fwd:6.1}, crouch:{dist:38,lead:0},
  lookout:{pitch:16,dist:44}, ride:{pitch:22,dist:30,yawFollow:75,yawLag:1.1}, rideUp:{pitch:17},
  squad:{pitch:22,dist:36,fwd:2,lead:0}, tengri:{pitch:14,dist:70,yawTurn:180,yawT:6}, eyes:{pitch:20,dist:16}, crown:{pitch:34,dist:20},
  passenger:{pitch:24,dist:26,yawFollow:45,yawLag:1.1}, flow:{pitch:17,dist:30}, intro:{pitch:24,dist:26},
};
export const ZOOM = { min: 13, max: 44, wheelStep: 1.6, pinchK: 0.045 };
export const TURN = { perPx: 0.25, linePx: 16, pagePx: 100, clickPx: 4, clickMs: 300,       // K27
  keySpeed: 110, keyEase: 0.12, keyStop: 0.05, smooth: 0.08, ahead: 170, face: 0.5, blend: 1.1 };
export function wrapDeg(a);                  // → (-180, 180]
export function turnAxis(axis, yaw, out);    // WASD eksenini seçilen açıyla döndürür: W ekranda ileri
export class CameraRig {
  constructor(base = CAM.foot);
  push(id, params, { priority = 0, blend = 1.1 });  pop(id, { blend = 1.1 });  has(id);
  setBase(base);  snap(zoomDist, heading);   // taban profilden; snap geçişsiz yerleşir, seçilen açıyı korur
  follow;                      // takip hızı: game.camFollow ayarı yazar
  update(dt, zoomDist, heading);   // tekerlek 13–44 m aralığı base dist'e yazılır
  value;                       // { pitch, dist, yaw, fwd, lead, yawFollow, yawLag }: en yüksek priority kazanır, geçiş blend sn; yaw = istek + userYaw + izleme
  // Seçilen açı (K27; derece, kaydedilmez)
  turn(deg);                   // göreli (orta tuş, tekerlek, panel): TURN.smooth yumuşatma, önde en çok TURN.ahead (hep kısa yay); beklerken → false
  steer(dir);                  // klavye: Game her kare −1, 0 ya da 1 yazar
  face(deg, { snap });  reset({ snap });   // TURN.face sn'de kısa yaydan; snap anında oturur (menüye dönüş, panel)
  chosen;                      // girdinin varacağı açı, (-180, 180]
  userYaw;                     // value.yaw içindeki seçilen pay (yumuşatılmış × bekleyiş ağırlığı); WASD bunu okur, izleme payını değil
  waiting;                     // yaw ya da yawTurn yazan istek ya da hold sürüyor: girdi yutulur
  hold;  roomK;                // Game her kare yazar: ctx.cine.active, oda karışımı
}
```

**Seçilen açı (K27).** Yığında `yaw` ya da `yawTurn` yazan istek (kuzeyden kurulmuş çekim; Tengri dönüşü 0 → 180°) ya da `hold` (sinema) varken seçilen pay isteğin blend süresiyle (sinemada 1,1 sn) 0'a karışıp bekler; girdi false döner, istek kalkınca geri gelir. Karışım, isteğin açısına (yawTurn'de dönüşün o anki açısına) en yakın 360° kopyayı seçer: kamera girişte ve çıkışta kısa yaydan döner. Seçilen pay ile atın izleme payı her kare, girdinin varacağı yere göre (-180, 180]'e ortalanır; `value.yaw` sarılmaz (oda çıkışında 180°'yi aşan dönüş sıçramasın). `yawFollow` (atta) seçilen açıya göre işler. Odada `placeCamera` (1 − roomK) ile kuzeye çevirir, Game girdiyi yutar, çıkınca seçilen açıya döner; WASD'nin «odada» sayılması yalnız basış değişince okunur (kapıda dönen kamera oyuncuyu geri itmez). Sıfırlama: `Game.enter` kip değişince, `Game.endSession()` ve `FreeroamState.beginSession` `reset({ snap: true })`: Serbest Gez her oturumda kuzeye bakarak açılır; menü, Yeni Oyun ve oluşturucu açıyı okumaz (menü karesi değişmez). Geliştirme paneli `__tanhu.cam`: `get()` → `{ chosen, applied, yaw, waiting, room, lift, pull, see }`, `yaw(deg, { snap })`, `turn(deg)`, `reset()`.

**Kamera kolu (K27, `Game`).** `targetPoint` takip yumuşatmasını yalnız oyuncunun konumuna uygular; ileri payı ve kamp çekişi (`CAMP_PULL`: yaw 0'da hedef x·0,92 − 0,4) her kare eklenir, çekiş ekranın yatayında işler: oyuncu her açıda ve dönerken ekranda aynı yerde kalır. Çekişin yükseklik payı (y·0,6 + 0,6) |y| ≤ 5 m'de aynıdır, ötesinde hedef oyuncudan en çok 2,6 m yukarıda, 1,4 m aşağıdadır. `solveCamera` engel payını çözer (`COLLIDE`): kamera araziye, yurt ve ahır kabuğuna (2,6 m) ya da büyük kayaya (2 m) girecekse ya da tepe oyuncuyu örtüyorsa önce yükselir (en çok 64°), yetmezse yaklaşır. Kol `placeCamera`'nın kuracağı pozla sınanır (`armOpen`, `roomDist`: oda karışımının eğimi, uzaklığı ve yaw × (1 − roomK)). Ağaç kamerayı oynatmaz: kameraya 3 m'den yakın dal elenir, elek 7,5 m'de söner (`flora.js` `TREE_NEAR`).

**Kapanma (K27).** Yapı parçası (yurt kabuğu ve iskeleti, ahır, çit, stok, oda eşyası) kameradan oyuncunun göğsüne giden çizginin çevresinde ve oyuncudan ≈1 m öndeyse fırça izli bir elekle seyrelir: koni kamerada başlar, oyuncunun uzaklığında 1,5 m'ye dek tam, 3,1 m'de söner, en çok %86'sı elenir (`structure-shader.js` `SEE_COLOR`, `interior.js`; eşik `max(…, 0,001)`: koni dışında piksel elenmez). Tek genel tekdüze `U.uSee` (göğüs xyz, güç w; `paint-material.js` `SEE_PARS`) bunu sürer: `Game.updateSee` oyunda yazar (4/sn, hedefe 1e-3 kala oturur); menüde, Yeni Oyun'da, sinemada ve odada w tam 0'dır, dala girilmez. `Game.leave({ keepSee })` duraklatmada eleği korur (FreeroamState `to === 'pause'`), harita ve dünya değişiminden dönüşte güç yerinde kalır; `Game.endSession()` kuzeye çevirir ve eleği kapatır. Program eklenmez, gölge değişmez. Ağaç elenmez: arkasında kalan oyuncuyu `character/ghost.js` izi gösterir. Alev: `Game.enter` `FLAME_BILLBOARD`'ı 1 yapar (dönen kamerada alev ince çizgiye dönmez), `endSession` 0'a döndürür; `drawMenuFrame` kendi çizimi için 0 yazıp geri koyar.

### 3.8 WorldSpec, Terrain, World

`WorldSpec` veridir ama işlev başvurusu taşır: kamp formülleri bit bit aynı kalmalı (§8 karar 6). Kurulum sırası kamp için bugünkü sıradır, RNG akışı değişmez.

```js
// world/specs/camp.js: değerler bugünkü kod (Faz 7 sonunda dosyadaki hali; alanların anlamı kurucuların varsayılan tablolarında)
export default {
  id: 'camp', zone: 'tanhu_camp', title: ZONES.tanhu_camp.title, loader: ZONES.tanhu_camp.loader,   // specs/zones.js
  matSuffix: '',                                  // kış '_w'
  sun: { dir: [-0.66, 0.6, 0.46], shadowSize: 4096, extent: 46, near: 4, far: 220, gridSize: 92, every: 1 },
  light: { lat: 47.35, dec: 7.4223, menuMinute: 886.18, menuSun: [-0.66, 0.6, 0.46] },   // K20: sapma iğneli (11 Nisan); sun.dir bu günün 14:46,2'sindeki gerçek güneştir
  moods: { stops: [MOODS.golden, MOODS.dusk], startT: 0.3, cycle: { palettes: MOODS, golden: 820 } },   // menü golden→dusk 0,3; Serbest Gez altı durak; kış: light { lat: 38.9 }, cycle WINTER_MOODS, golden 840
  sky: { dome: true, showBelowPitch: 18 },        // oyun kamerasında gizli, menü değişmez
  lights: { points: 4 },                          // yalnız bu kadar, hep var; kapalıyken yoğunluk 0
  postCuts: false,                                // post kesintileri ve çözünürlük düşüşü yalnız Kışlak'ta true
  terrain: {
    kind: 'single', heightRaw, land: landHeight, dirtRaw, farColor, lakeY: LAKE_Y, near: { x0: -70, x1: 70, z0: -82, z1: 58 }, cacheCell: 0.5,
    mask: { size: 560, gate: (x, z) => Math.abs(x) < 48 && z > -40 && z < 48 }, paths: LAYOUT.paths,
    paint: paintCampGround, nearStep: 0.5,
    far: { X: 1500, Z: 1800, NX: 300, NZ: 220, zTop: 110, exp: 1.75,   // K27: south uzak ağın güney uzantısı (buildSouthMesh)
      south: { Z: 1800, N: 48, exp: 1.6, bands: [{ z: 290, x: [-200, 0, 200] }, { z: 800, x: [-350, 350] }, { z: Infinity, x: [0] }] } },
    material: { near: { brush: 0.32, term: 0.22, scale: 0.24 }, far: { brush: 0.5, term: 0.3, scale: 0.028, key: 'far' } },
  },
  lake: { y: LAKE_Y, centerZ: -400, plane: [2400, 1800], fogR: [120, 1400], line: LAKE_LINE },
  village: { seed: 321, clusters: VILLAGE_CLUSTERS },
  layout: LAYOUT,
  forest: {
    seed: 555, heroBounds: [-62, 62, -80, 48], clear: { cx: 2, cz: -7, sx: 1.35, sz: 1.2, r: 16 }, edge: 34, viewCorridor: blocksValley,
    nearTries: 2600, nearCap: 300, heroR: 36, heroCap: 80, farTries: 26000, farCap: 7200,
    outer: { seed: 557, tries: 24000, r0: 60, r1: 850, midCap: 300, farCap: 4200, split: 400, back: { z: 95, x: 110 }, cells: [40, 90, 170, 450] },   // K27 dış orman
    farBand: { z0: 20, depth: 880, half: 160, widen: 520 }, midR: 170, midCap: 700, cells: [22, 26, 60, 170],
  },
  rocks: { seed: 808, scatter: 110, bounds: [-38, 38, -36, 30], clear: { cx: 1, cz: -6, sx: 1, sz: 1.1, r: 7 } },
  grass: { seed: 2024, bounds: [-50, 50, -56, 42], step: 0.285, chunk: 14 },
  flowers: { seed: 77, clusters: 1100, bounds: [-44, 44, -46, 34], extra: 2400, extraBounds: [-40, 40, -40, 30] },   // chunk yoksa grass.chunk
  fields: { origin: [-66, -74], cell: 0.2, size: [680, 680] },
  ambient: { motes: { count: 240, wrap: 64, seed: 66, bounds: [-32, 32, -32, 22], height: [0.3, 5.5] } }, fire: { at: [0, 0], smoke: [0.1, 1.9, 0] },
  build: { camp: buildCamp, folk: buildCampfolk, horses: placeCampHorses },       // buildCamp(world), buildCampfolk(world, height), placeCampHorses(world); kış başka işlev gösterir
  nav: { kind: 'grid', x0: -60, x1: 60, z0: -60, z1: 50, cell: 0.25, walkable: campWalkable, maxSlopeNY: 0.74 },   // walkable yalnız kutu kuralı, eğimi buildNav sınar
  camera: { base: 'child', minDist: 13, maxDist: 44 }, spawn: { x: -1.98, z: -0.92, yaw: 1.136, sit: true },
  structures: [{ id: 'camp3', def: 'yurt', preset: 'hero', mode: 'timed', place: { x, z, rot, y0, seed: 11 }, design, name }],   // layout.js SITE_YURT
  site: { yurt: SITE_YURT, stock: SITE_STOCK },   // yapı alanı olmayan dünyada null
  nodes: [],  roads: null,  stations: [],

  weather: { climate: 'orkhon', season: 'camp_spring', exclude: [], accumulate: { snow: false }, snowFelt: 1, dur: { snow: [1, 3] },
             box: [70, 30, 90], points: 6000, splashes: 192, fogZones: [], shelters: null, menu: 'identity' },   // K22 (§3.24)
  labour: { torchFree: true, rawWork: false },    // K21: ana kampta meşale bedava, malzeme yontulmuş gelir (d2/core.md §2.4, §2.6)
  audio: { music: 'camp', ambience: {             // sounds.js okur; at [x, yerden yükseklik, z]
    menu: [{ id: 'wind_steppe', gain: 0.55 }, { id: 'fire_loop', gain: 0.9, at: [0, 0.5, 0] }],
    dawn: [{ id: 'birds_day', gain: 0.5 }, { id: 'wind_steppe', gain: 0.35 }, { id: 'fire_loop', gain: 0.6, at: [0, 0.5, 0] }],
    morning: [{ id: 'birds_day', gain: 0.35 }, { id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.55 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    noon: [{ id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.7 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    golden: [{ id: 'camp_day', gain: 0.35 }, { id: 'wind_steppe', gain: 0.7 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],
    dusk: [{ id: 'camp_day', gain: 0.2 }, { id: 'night_meadow', gain: 0.3 }, { id: 'wind_steppe', gain: 0.45 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],   // camp_day → night_meadow evre boyunca
    night: [{ id: 'night_meadow', gain: 0.45 }, { id: 'wind_steppe', gain: 0.3 }, { id: 'fire_loop', gain: 1, at: [0, 0.5, 0] }],   // fire_loop 22:30'dan 0,5 (sounds.js saatle)
  } },
};

// world/specs/zones.js (saf): kaydın bölgesi → dünya kimliği, ad ve yükleyici başlığı. specForZone, spec.title, spec.loader ve kayıt
// kartlarının dünya adı (save.world.<bölge>, menu.zone.<bölge>: zoneRows) bu tek satırdan okur.
export const ZONES = { tanhu_camp: { spec: 'camp', title: { tr, en }, loader: { tr, en } }, hexi_winter: { spec: 'hexi_winter', … } };

// world/terrain.js
export class Terrain {
  constructor(spec)                 // spec.terrain
  init();                           // patika örnekleri (samplePaths), önbellek ve maske; ikinci çağrı iş yapmaz
  heightRaw(x, z);  height(x, z);  normalAt(x, z, out);  dirtAt(x, z);  pathPoints();
  paintGround(contacts);            // → CanvasTexture (spec.paint(terrain, contacts))
  buildNearMesh(tex);  buildFarMesh();   // malzeme spec.material.near / far
  update(focus);                    // parçalı arazide parça yükler (kare başına ≤4 ms); tek parçada boş
  dispose();                        // cache, mask, paths bırakılır; etkin araziyse dağıtıcılar yaşayan son araziye, o da yoksa kampın ham alanına döner
}
export function setActiveTerrain(t);   // World.build (kurulumda) ve Game.setWorld (oynanan dünya); bırakılmamış araziler etkinleşme sırasıyla tutulur
export const height = (x, z) => active.height(x, z);       // heightRaw, normalAt, dirtAt, pathPoints da aynı
```

`grass`, `flora`, `valley`, `camp`, `interior`, `game`, `atlas`, `world` bugünkü `import { height }` satırlarını korur (denetim §c). `heightRaw`, `dirtRaw(x, z, paths)` `terrain-field.js`'e iner: `three` kullanmaz, testlenir; `paths` `samplePaths(LAYOUT.paths)` çıktısıdır (three'nin merkezcil CatmullRomCurve3 aralığının saf kopyası, örnekleri three ile aynı). `LAKE_Y` kamp sabitidir, yalnız `terrain-field.js` dışa verir; okuyanlar `spec.terrain.lakeY`'dedir. Atlas `terrain.js`'ten `heightRaw` ve `farColor`, `valley.js`'ten `LAKE_FOG_R` alır: üçü dışa açık kalır.

**Spec'i okuyan kurucular (Faz 7).** Kurucular `{ …, spec }` alır (`buildRocks({ contactOut, spec })`, `buildForest({ isFree, contactOut, density, spec })`, `buildGrass`, `buildFlowers({ …fields, density, spec })`, `buildLake({ spec })`, `buildVillageLights({ spec })`, `buildMotes({ spec })`) ve spec'in vermediği alanda kampın bugünkü değerine düşer (`flora.js` FOREST, ROCKS; `grass.js` GRASS, FLOWERS; `ambient.js` MOTES; `valley.js` LAKE, VILLAGE); kamp spec'i bu değerlerin hepsini yazar. Birleşim sığdır: `clear` gibi iç içe alan bütün yazılır. `farTries` ve `heroCap` yoğunlukla çarpılmaz. Gölün `userData.fogR`'u gölün kendi sis aralığıdır (`spec.lake.fogR`): sis katmanı kalkınca `uFogR` ona döner. `world.aimSun(focus)`: gölge kamerası `{ x, z }` odağına ızgaralı oturur (her karede `update`, ısınma karesinde oyuncuya); odağın arazi yüksekliğini döndürür.

**Dış arazi (K27).** Dönen kamera kampın güneyini ve yanlarını görür. `spec.terrain.land` (`terrain-field.js` `landHeight`) yalnız uzak ağı ve güney uzantısını besler: yakın kutunun 2 m içinde ve vadide `heightRaw`'ı bit bit verir, dışarıda vadi tabanının altına düşen tepeyi tabana oturtur (göl düzleminin altında kara kalmaz, güneyde «deniz» görünmez); `heightRaw`, nav, oyun ve orman RNG'si değişmez (1.000 noktalık fikstür). `terrain.buildSouthMesh(far)` uzak ağı z 110'dan güneye 1.800 m sürdürür (`far.south`; ilk satır uzak ağın son satırıyla bit bit aynı, dikiş normali iki ağda ortalanır); dokuz parçaya bölünür, her parçanın kutusu menü kamerasının arkasındadır (menü karesi çizim ve üçgen saymaz); malzemesi uzak ağınkidir. `flora.buildOuterForest` (`forest.outer`, kendi tohumu, kurulumun en sonunda) aynı çam biçimleri ve malzemesiyle 300 orta, 4.200 uzak çam diker (53 hücre), gölge düşürmez. Program eklenmez. Değişiklik `valley` referans pozunu (sol alt ön plan, 1.787 piksel) ve sahne sayımını değiştirdi: `docs/baselines/refs` 2026-11-03'te yeniden alındı, eskisi `docs/baselines/archive/refs-pre-k27`'dedir (§8 karar 57).

**Kışlak zemini.** `specs/winter.js` `terrain.paint` kullanmaz, 4096² boyanmış zemin yoktur: kar kabartma gölgelendiricisi (`snow-hooks.js`), fırça gürültüsü, düşük çözünürlüklü maske, yol çıkartmaları. Parça başına boyama yok.

**Yeni spec alanları (K20–K24).** Kamp spec'i (8.9) ve Kışlak spec'i (9.1) saat, hava ve emek alanlarını; II. Perde dünyaları (Faz 13) ve kum havuzu (8.12, 9.9) yerleşim alanını taşır. Taşımayan dünyada sistem varsayılanı kullanır: saat ana kampın enlemi, hava `clear` kimliği, emek `{ torchFree: false, rawWork: true }`. `moods.stops` ve `moods.startT` her spec'te zorunludur (`World.useSpec`, Faz 7); kum havuzu spec'leri de yazar.

```js
// specs/winter.js (9.1) ekleri
light: { lat: 38.9 },  moods: { stops: [WINTER_MOODS.golden, WINTER_MOODS.dusk], startT: 0, cycle: { palettes: WINTER_MOODS, golden: 840 } },   // gün takvimden: Gün I = dayN 1.041; stops ve startT kurulumdaki ilk applyMood içindir
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

**Spec'in içe aktardığı adlar ve sahibi (Faz 7, paralel yazım için):** `heightRaw`, `dirtRaw`, `farColor`, `paintCampGround`, `campWalkable` 7.1 (`terrain-field.js`, `terrain.js`, `specs/camp.js`); `MOODS`, `placeCampHorses` 7.2 (`world.js`); `blocksValley` 7.3 (`flora.js`), `VILLAGE_CLUSTERS` 7.3 (`valley.js`); `buildCamp` 7.4 (`camp.js`), `buildCampfolk` 7.4 (`npc.js`); `LAKE_LINE` Faz 4 (`lake-line.js`); `LAYOUT` Faz 6 (`layout.js`).

```js
export class World {
  constructor({ spec, density = 1, onStep = () => {}, yieldGate = null, designs = [] });
  async build();   // her ağır adımdan önce await yieldGate?.(); adım etiketi anahtardır, onStep(key, p)
  spec; scene; terrain; structures; ready; rooms; horses; obstacles; softContacts; solids; updaters; lake; village; sky; weather;
  folk;            // { child, bard, warrior, woman }: camp spec'inde tutamak (§8 karar 3)
  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır; menü yolu, değişmez
  lightBase;  setTimeOfDay(sample | null);  writeLight();  timeDriven;  mixTone(out, key, a, b, t);   // K20 (8.9): saat yalnız lightBase'i yazar; writeLight tek yazıcı (8.9 kimlik, 9.4'ten WeatherView.compose)
  tallThings;      // K22: yıldırım adayları [{ id, x, z, h, kind: 'tree'|'pole'|'tower'|'structure', lone }], ≤256; flora (9.4) ve yapı yöneticisi (9.6) doldurur; weather 9.4'e dek null
  update(dt, t, focus);  groundAt(x, z);  isGroundFree(x, z, margin);
  matKey(base);    // base + spec.matSuffix
  dispose();       // aşağıda
  // Faz 6
  structureViews;  // camp.js görünümleri [yurt_a, yurt_b, stable, fence]: StructureManager benimser
  site;            // world/site-pad.js SitePad: üçüncü yurdun pedi, ezik maskesi, stoğu; bind(camp3), setMode, groundAt, navShapes(), stockOn
}
```

`groundAt` önce `site.groundAt` (ped çiğnenirken yükselen ped, menüde arazi), sonra `structures.groundAt`, sonra `rooms`, sonra `height` sorar (`structures.md` §11.3). `designs` `[yurt1, yurt2, yurt3]`: `?yurt3=` üçüncü yurdun iç tasarımıdır (§11.7, `world-swap.js`). `World.buildStructures` çim adımından sonra `world.structures`'ı kurar (kurulum sırası ve RNG değişmez), `camp3`'ü zaman kipinde doğurur; yöneticinin `setMode`'u örnekte sarılıdır: ped, stok ve çimin maskeli ikizi kiple döner (`grass.js` `setSiteMask(group, on)`: menüde özgün malzeme). Çimin genel alan tekdüzenleri (`grass.js` `SITE_U`) oyun kipine son giren pedindir: kurucu yazmaz, sahip kendi maskesini, dikdörtgenini, ezilmesini ve stoğunu yazar, bırakım yalnız sahipken sıfırlar; oyun kipindeki gösterilen dünyanın pedi güncellemede sahipliği geri alır. Kenar ışığı `U.uRimColor` `applyMood`'u son çağıran dünyanındır; güncellenen dünya sahibi değilse ışık düzenini yeniden uygular. Böylece aynı sayfada elle kurulup bırakılan ikinci dünya canlı dünyanın alanını ve ışığını bozmaz; `height` ve eşleri ise o yaşarken onun arazisine bakar, bırakılınca canlı dünyanınkine döner.

**Gök, sis katmanı, göl hattı (Faz 4–5).** `world/lake-line.js` (saf) `LAKE_LINE`, `LOCAL_LAKE`, `LAKE_SEGMENTS`: arazi, göl yüzeyi ve `relief-core.js` aynı hattı okur. `valley.js` `LAKE_FOG_R = [120, 1400]` göl sisinin kendi aralığıdır (atlas gerçek kipten dönerken de bunu yazar). `world.sky` (`world/sky.js`, `new Sky({ showBelowPitch = 18, horizon, sunDir })`): kameraya bağlı boyalı kubbe, `depthWrite: false`, `renderOrder` 4, yalnız boş pikseller; kamera ufka `showBelowPitch`'ten düz bakınca 2° geçişle açılır, oyun kamerasının 28°'sinde çizim çağrısı bile almaz; renkler `MOODS`'un gök ve bulut anahtarlarından. `world.setFogOverride({ near, far, color? } | null)`: sahne sisi, arka plan, gölün `uFog`/`uFogR` ve kubbenin ufku birlikte; `null` ışık düzeninin sisine ve `LAKE_FOG_R`'ye döner; `color` CSS dizgesi değilse ayırma yapmaz. Alevler `fire.js` `FLAME_BILLBOARD.value` 1 iken kameraya döner (Yeni Oyun sineması ve K27'den beri `Game.enter` … `endSession` arası yazar, varsayılan 0, menü karesi 0 görür; §3.7); kıvılcım ve zerre nokta boyu `uPointMax` ile 16 ve 14 px'e kıstırılır; `Smoke` tek çizimdir ve yalnız saate bağlıdır; çim ve çiçek parçaları kameradan 160 m ötede çizilmez (Tengri kamerasında ≈190 m: uzak parça belirir).

**Işığın tek hattı (K20, K22, K26; `time.md` §5, §12.6; `weather.md` §9.2).** `MOODS` altı durak taşır: `night`, `dawn`, `morning`, `noon`, `golden`, `dusk`; son ikisi bugünkü değerlerdir, bit bit aynı kalır. Menü, Yeni Oyun, oluşturucu ve `home` `applyMood(t)`'yi bugünkü gibi kullanır, saati ve havayı okumaz. `freeroam` ve `play`'de `ClockSystem` 4 Hz'de (bekleme akışında her kare) `setTimeOfDay(sample)` çağırır: iki durak `mixTone` ile karışır, sonuç düz `world.lightBase` kaydına yazılır (renkler, yoğunluklar, sis, kubbe anahtarları, göl, köy, kenar ışığı, pozlama, yön, `k`, ay, gece); three.js nesnesine dokunmaz, ayırma yapmaz (`TONES` altı durağı bir kez çözer). Güneşi, yarımküreyi, sisi, kubbe, göl ve kenar uniform'larını ve pozlamayı yalnız `writeLight()` yazar: 8.9'da kimlik (tabanın kopyası; sayılar bugünkü `applyMood` ile aynı sıra ve değerde), 9.4'ten `WeatherView.compose(base, params, flash)` (hava çarpanı yalnız burada, bir kez). `writeLight` karede en çok bir kez, yalnız taban, hava ya da şimşek değişince çalışır; `setFogOverride` en son kazanır. `timeDriven` iken `applyMood(t)` ışığa yazmaz, yalnız `writeLight()`'ı bir kez zorlar (8.9, `world.js`): bugün Serbest Gez ve oyunda da `applyMood` çağıran `map/atlas.js` `setReal(false)`, `freeroam.onWorldReady` ve `World.update`'in kenar ışığı sahipliği yolu tek yazıcıyı böylece bozmaz. Yön oyun dakikasında bir adım değişir (≤0,25°) ve ışık uzayında gölge ızgarasına oturtulur; gölge düşüren yükseklik ≥15°, `normalBias × max(1, sin 36,7° / sin el)` (≤0,14), güneş 15°'nin altında `kLow = 0,35 + 0,65 × smoothstep(0°, 15°, el)`; gölge haritası donukken (Tipi, Donuk Kamp, `freeze`) yön de donar. Geceleri aynı `DirectionalLight` ay ya da gök yönündendir; ışık eklenmez, saat program eklemez (hava +2, §7). Geriye uyum: `setTimeOfDay` `world.moodT` ve `moodTarget`'ı evreden türeyen 0..1 akşamlık değeriyle yazar (ışık yazmadan; `interior.js` ocak parıltısı okur); `drawMenuFrame` ikisini `MENU_MOOD`'a iğneler (Faz 7). Serbest Gez yeni oturumda menü dakikasında (14:46,2) açılır: o dakikada saat ışığı menü ışığıdır; menüden iniş 2,4 sn, dönüş 1,7 sn süzülür (ışık ve hava birlikte). Zerrelerin `motes` kanalı menü anahtarına dek 0'dır (`s` 4,3), batışta (`s` 5) 1'e çıkar.

**Hava görünümü (K22, 9.4; `weather.md` §9).** `world.weather` `WeatherView`'dur (`world/weather.js`, §3.24): `World.build`'in son adımında kendi tohumuyla kurulur (kamp RNG akışı değişmez); 9.4'e dek `null`dur, çağıranlar `?.` kullanır. İki ağı vardır: yağış ve sıçrama noktaları (`weather_pts`; tek geometri, tek çizim, ≤6000 + 192 nokta) ve yıldırım şeridi (`weather_bolt`, ≤96 üçgen, ≤0,35 sn); yükleyici derlemesinde görünür yapılır, sonra gizlenir (§8 karar 36 deseni). Ekran yağışı FINAL'dedir (§3.21; 0 çizim). Sıra: taban → hava çarpanı (sis rengi; kamera tabanı yakın ≥0,5 × kamera uzaklığı, uzak ≥ kamera uzaklığı + 50 m; bölge sisi `spec.weather.fogZones`) → şimşek nabzı (pozlama × (1 + A·f), yarımküre yoğunluğu ve rengi; ışık eklenmez) → `setFogOverride` kazanır. Hava etkinken göl sis aralığı `LAKE_FOG_R × fogFarK`. Barınak değeri `ctx.weather.shelterAt(x, z)`'tir (oda, yapı, araba koltuğu, orman kıyısı yarım). `world.weather.identity(fade)` menü kimliğine döner (`weather.md` §9.12).

**`world.folk` tutamakları (`character/npc.js`).** `child`, `woman`, `warrior`: `{ group, head, faceMat }`. `bard`: `{ group, head, arm, lute, faceMat, perform }`. `perform` (5.4) çağrılabilir tutamaktır: `perform(opts)` → Promise (ozan oturunca çözülür); `opts`: `strum` 0..1, `mouth` (`'sing'|'rest'|'a'|'o'`), `text` ve `duration` (hece çizelgesi), `level` (`() → 0..1` canlı genlik), `buffer` (AudioBuffer: genlik zarfı), `clock` (`() → sn`), `tail` (söz bitince çalış süresi, `null` oturmaz). Ses kaynağı verilince `mouth: 'sing'`, `strum: 1` varsayılır. `perform.strum` okunur ve yazılır (0,5 üstü dombra kalkar, 0,4 oturan boşta), `perform.setMouth(v)`, `perform.stop()` (hemen oturur), `perform.state()`. İki kol omuz ve dirsekte döner, dinlenmede köşeler aynıdır; `head.js` `paintFace({ mouth })` üç ağız çizer, `paintVisemes` 512² takımı boyar; ağız takası gölgelendirici derlemez, açık ağız dokuları oturunca GPU'dan düşer. Statik çocuk `[x, z, 0,5]` kaydıyla `world.softContacts`'tedir: temas gölgesi ve çim aynı, nav dışı. Serbest Gez `group.visible = false` yapar, −6 çizim, −33k üçgen. **`world.folk.lookAt(point, seconds = 4)`** (Faz 6): ateş başındakilerin başı `{ x, z }` noktasına süzülür (boyun ±1,3 rad), süre bitince boştaki salınıma döner; `null` hemen keser. Bakış yokken baş eskisi gibi salınır, menü karesi değişmez; üçüncü yurt bitince ustalar çağırır, menüye dönüşte keserler (`structures.md` §11.6).

**`World.dispose` (`world/dispose.js`).** `disposeScene(scene)`: sahneyi gezer; geometri, malzeme, `InstancedMesh.dispose()`, `sun.dispose()`, `userData.shared` taşımayan dokular. `markShared(x)` paylaşılanı işaretler: `U.uBrush`, `U.uCloud`, `yurtTex`, `wallTex`, `rugTex`, `puffTex`, `bodyMat`, `hairMat`, `horseMat`, `ghostMat`, folk önbellekleri (`folk.js:47-49`), `Post` hedefleri, Mete varlıkları. Aktör, işaretçi, toz, atlas nesneleri önce ayrılır. `updaters` boşalır. Faz 7'de paylaşılan diye işaretlenenler: `fire.js` ve `structure-fx.js` duman dokuları, kişi gövde ve saç malzemeleri (`npc.js`), `horseMat` ve iz malzemeleri (`horse.js`), folk saç malzemesi ve baş geometrileri (`folk.js`), yurt, iç duvar ve kilim dokuları (`camp.js`, `interior.js`), telegraf ağı, ok havuzu, ustaların kökleri, aletleri ve yardım halkası, Çocuğun silahları; önbellekler `world.matKey(base)` ile palete göre anahtarlanır, ikinci kamp kurulumu ilkinin nesnelerini alır. Sistemler eski dünyayı `world:dispose`'da bırakır (yapılar kaydı yazar, ustalar ve halka iner, oklar ve şekiller silinir), `game.setWorld(null)` gerekmez. **Doğrulama:** üç gidiş dönüşte `renderer.info.memory` tabana döner: Faz 2'de 161 geometri, 33 doku, 81 program (Faz 1'de 246, 32, 85); Faz 6 sonunda taze açılışta 176 geometri, 34 doku, 56 program, menü karesi 360 çizim (231 + 113 + 16), 3.692.162 üçgen (`docs/baselines/menu_counts.json` yeniden yazıldı); tavan ≤92 program. Faz 7 sonunda taze açılışta menüye girişte 162 geometri, 34 doku, 57 program (57'nci Çocuğun gölge programı, ısınma karesinde), `refs.compare` yedi pozu çizdikten sonra 202; değişim ölçümü §2.7. K27'den sonra (2026-11-03) taze kayıtla menüde yine 57 program; camp3'ü ilerlemiş kayıtta dokulu yapı parçası gölge düşürdüğünden `struct_depth_tex` derinlik programı da derlenir (58; kod değil kayıt durumu, ikisi de ≤92).

### 3.9 Hasar ve dövüş

```js
// game/damage.js (saf). Tablolar data/damage-tables.js: LIVING, STRUCT (progression.md §8.2, §8.3), BURN_RATE.
Attack = {
  type,          // 'slash'|'pierce'|'blunt'|'fire'
  base,          // canlıya taban
  sdmg,          // yapıya taban; salvo: 2 * n
  statMul,       // yakın 1+0,06×(Bilek−3), ok 1
  pen,           // zırh delme 0..1
  buffs,         // 1 varsayılan
  tag,           // 'melee'|'arrow'|'toy_arrow'|'fire_arrow'|'torch'|'stone'|'chest'
  structMods,    // (unit) => çarpan; rope_cutter vb.
  owner,         // aktör id; 'player' oyuncu
  fromPlayer, ko /* blunt, sapan: 0 Can'da bayılt */, stun /* sn */, pushback,
};
export function makeAttack(weaponId, { derived, arrowId, owner })    // → Attack; data/weapons.js
export function hitLiving(atk, tgt, diff)   // → sayı, ≥1 (progression.md §8.2); tgt: { class, isPlayer, dr }
export function hitStructure(atk, unit)     // → sayı (structures.md §5.1)
export function setWeaponTables({ WEAPONS, BOWS, ARROWS })   // combat.js yüklenirken: damage.js weapons.js'i içe aktarmaz. WEAPONS {type,dmg,sdmg,pen?}, BOWS {dmg,pull}, ARROWS {mul,pen,sdmg}
export function pullFactor(pull, grip = pull)                // derive.js pullF: çekiş 0 iken 1

// Oyunda canı olan her şey. Agent ve StagedStructure bunu sağlar.
Damageable = {
  id, dmgKind,                      // 'living' | 'structure'
  bounds(),                         // → { x, z, r, top } kaba süzgeç
  hitRay(origin, dir, maxT),        // → { t, point, part } | null; ok ışını
  hit(atk, point, dir),             // → HitResult
};
HitResult = { dmg, killed, ko, mat, stuck, part, pass };   // stuck: ok saplandı; pass: ok delikli katmandan geçti, uçuş sürer (structures.md §5.2)

// game/combat.js: GameSystem, order 70; ctx.combat. Açılırken setWeaponTables({ WEAPONS, BOWS, ARROWS }) çağırır.
export function attackFor(name, { owner, derived });   // PANEL_ATTACKS adı → makeAttack: toy_arrow, wood_sword, arrow, fire_arrow, sword, axe, mace, torch, chest
export class Combat {
  register(d); unregister(d);                      // world.structures.list() saniyede bir kendiliğinden kaydolur, dünya değişince düşer
  swing(atk, { x, z, h, range, arc, ignore, y });  // → HitResult[]; yakın; en çok 6 hedef; y salınımın dünya yüksekliği (yoksa zemin + 1 m)
  raycast(origin, dir, maxT, { ignore, top });     // → { target, t, point, part } | null; önce zemin ışını kısaltır, sonra bounds ve tepe; top dünya yüksekliğinin üstündeki değme sayılmaz. Sonuç nesnesi ve noktası Combat'ındır, sonraki raycast'e dek geçerli (kare içi ayırma yok)
  ground(origin, dir, maxT);                       // ışının world.groundAt'a değdiği t ya da Infinity (oda tabanı ve ped dahil)
  strike(target, atk, point, dir);                 // bütün saldırganların kapısı: target.hit, target.onHit, dmg:hit ve dmg:killed
  nearestHostile(x, z, r, filter);                 // tık-hedef kilidi
}
// data/weapons.js (saf): WEAPONS, BOWS, ARROWS (progression.md §7.1–§7.3) ve PANEL_ATTACKS (ad → { weapon, arrow? }).
// Çocuğun oku arrow_toy, saldırı etiketi toy_arrow.

// game/telegraph.js: GameSystem, order 74; ctx.telegraph. Tek InstancedMesh (mesh), en çok 16 şekil, oyun durumlarından çıkınca silinir.
export class Telegraph {
  ground(shape, seconds = 1, kind = 'danger');     // → kimlik; seconds Infinity: end çağrılana dek; kind 'danger' | 'aim' | 'skill'
  set(id, shape);                                  // süren şeklin yeri ve ölçüsü (nişan halkası), süre sayacı yerinde
  end(id);  clear();  timeScale;                   // end sönerek kalkar; timeScale sinema yavaşlatması
}
```

**Akış.** Saldıran `makeAttack` ile saldırı kurar, `swing` ya da `projectiles.fire` çağırır, `Combat` hedefin `hit`'ini çağırır, `dmg:hit` yayar. Parçacık ve ses hedefin işidir: yapıda `structure-fx`, canlıda `Agent.onHit`. Ölüm: `dmg:killed`; Korku ve XP kuralı yayanda değil, `player.js` dinler (`act1.md` §9.6: öldürmek XP vermez, kamp içinde Korku +2). Telegraf: `telegraph.ground(shape, seconds, kind)`; `shape`: `{ circle:[x,z,r] }`, `{ cone:[x,z,h,arc,r] }`, `{ line:[ax,az,bx,bz,w] }`. En çok 16 eşzamanlı, 1 çizim.

**Çocuk.** `child.js` `toy_bow` ve `wood_sword` ile aynı yolu kullanır; `Q` değiştirir. Yapıya 0,5 ve 1 (`structures.md` §5.3): Serbest Gez sandığı bozulmaz.

### 3.10 Mermiler (`game/projectiles.js`)

```js
export class Projectiles {   // GameSystem. Havuz: InstancedMesh(arrowShaft(0.95)) 36 üçgen, ≤64 uçan, 1 çizim, gölgesiz
  fire({
    from: [x, y, z],
    to: [x, y, z] | null, dir: [x, y, z] | null,  // biri
    speed,                     // ok 38 m/sn, taş 22, kemik 18
    arc,                       // yay yüksekliği katsayısı; ok 0,06×d
    kind,                      // 'arrow'|'stone'|'bone'|'whistle'
    atk,                       // Attack
    ignore,                    // kendi id'si
    telegraph = 0,             // >0: önce zemine çizer, süre sonunda atar (kadraj sözleşmesi)
    onHit = null, onEnd = null,
  });                          // → id
  predict({ from, to = null, dir = null, speed, arc, kind, atk = null }, out);   // → out [x, y, z]: iniş noktası; fire ile aynı yörünge ve yan ivme a = k × rüzgâr (ctx.weather.windAt(from[0], from[2], out)); k türden ve atk'den: ok 0,15, ateşli ok 0,18, ıslıklı 0,2, oyuncak ok (atk.tag 'toy_arrow') 0,25, taş, kemik ve arbalet oku 0,08; fire bu rüzgârı s.wind'e dondurur (telegraph > 0 ise telgraf çizilirken), weather.md §8.8
  clear();                     // dünya değişimi
}
```

Ek dışa aktarımlar: `arrowShaft(len = 0.95)` (36 üçgenlik ok geometrisi; saplı oklar ve Çocuğun gerilen oku da kullanır), `shellInside(room, x, y, z)`, `shellDoor(room, x, y, z)` (yapı Damageable değilse kabuk duvar sayılır, kapı aralığı açık). `group` (ok ve taş havuzu) dünyanın sahnesindedir, oyun durumlarından (`freeroam`, `play`, `map`, `pause`) çıkınca `clear()`; malzeme ağaçlarınkinden ödünçtür, yeni program yoktur. `ctx.projectiles`. Çarpışma: adım başına `combat.raycast` + `height`. Yapıda saplanan ok `structure-fx.stickArrow`, zeminde saplanan aynı havuz, 8 sn solar. `kind: 'whistle'`: `sfx.loop('whistling_arrow')`, kalkışta `arrow:whistle`. `act1.md` §8.10 zaman ×0,25 sahnesi `cine` işidir; `Projectiles` `clock` değil `dt` kullanır, sahne `dt` çarpanı verir (`projectiles.timeScale`). `army.md` `ArrowPool` (≤512, GLSL yay) II. Perde'dedir, ayrı havuzdur; bu API'yi kullanmaz.

### 3.11 Yapı sistemi

Tasarım, adım tabloları, GLSL ve kabul `structures.md`'dir. Kodu bölen sözleşme şudur.

```js
// world/structure-logic.js (saf): üç yok, DOM yok
export class StructureState {
  constructor(def, { mode /* 'timed' | 'script' */, preset, startFull });
  stage; step; stepT; wm; rate; pools; units; burnT; contrib; fell; tears;   // wm: işlenen iş dakikası (İD); rate: İD / oyun dk, yalnız sürücü yazar
  advance(wm);  deliver(item, n, who);  credit(wm);  dismantle();            // K21 (§3.25); sliceTick kalktı; credit çarpansız senaryo armağanı; dismantle tersten, emeğin 0,35'i
  hitUnit(unitId, dmg);          // LIFO, chip, taşma; → { fell: [...], stageChanged, prev }
  ignite({ power, torch });  tickBurn(dt);
  setStage(n, { cause, stagger });  repairStep(wm, who);           // onarım emeği İD (structures.md §7)
  toJSON();  fromJSON(o);        // structures.md §11.8
}

// world/structure.js
export class StagedStructure {   // Damageable. Görünüm, nav, FX; mantık StructureState
  constructor(def, place, world, { mode: 'timed'|'script', preset, startFull });   // K20: 'slice' kalktı; Kışlak Yeni Yurdu da 'timed' (SiteSystem sürer)
  id; kind; state /* StructureState */;
  get stage();  get step();
  hit(atk, point, dir);  ignite(point, { power, torch });  setStage(n, opts);  tear(panel, opts);
  deliver(item, n, who);  credit(wm);  repairStep(wm, who);  dismantle();   // deliver bohçayı açar (yurt_kit → parçalar), parça ya da ham karşılamayı adıma yazar (rawWork, K24)
  groundAt(x, z);  navShapes();  unit(id);  ensureStage(n);  panelFacing(dir);  cutRoof();  beginHeave();
  toJSON();  fromJSON(o);  dispose();
}
export class StructureManager {  // Dünyaya aittir: world.structures, dünya ile silinir
  spawn(kind, opts);  get(id);  list();  update(dt, t);
  setMode(mode);        // 'menu' | 'play' (structures.md §8.5): durum silinmez
  groundAt(x, z);       // null | yükseklik
  rebuildNav(box);      // StructureNav'a iletir
  toJSON();  fromJSON(o);
}
export class StructureSystem {   // GameSystem; host'ta tek örnek, id 'structures'
  onWorld(world, nav);           // world.structures'a bağlanır
  update(dt, t);  collectInteractions(q, out);  onPick(q);   // Onar / Repair, Yama / Patch, yardım yuvaları
}
// world/structure-kits.js (9.10): export const KITS;   // kind → { build(place, world, preset) → view (aşama grupları; StagedStructure._build), look(structure, view) → Look (aşama, hasar, yanık; _look), coarse(preset) → THREE.BufferGeometry (≤400 üçgen; 9.9 KitField'in tek BatchedMesh'ine) }
```

- `STRUCTURE_DEFS` ve `def.steps` biçimi `structures.md` §2.2.
- **Menü kipi:** `menu` ve `newgame`'de `setMode('menu')` (`mq_home` kamp dünyasını yüklemez, K106); `freeroam`, `play`'de `'play'`. `menu.enter` ve `freeroam.enter` çağırır.
- **Olaylar** veri yolunda `structure:*` (§3.1). Yerel olay yayıcı yok.
- **Nav** `game/structure-nav.js`: `rebuild(box)`, `structures.md` §12.3; `nav.js` `sb`, `st`, `clearLayer`, `stampLayer`, `stampLayerTop`, `epoch`, `structures.md` §12.1. `Game.buildNav` `s.owner` taşıyanı atlar.
- **Usta** `game/builders.js` emek çizelgesine bağlıdır: oran `labour.stepRate`'ten, takılan usta inşaatı kilitlemez (`structures.md` §10.2). Saat durunca emek durur, saat atlayınca `labour.simulate` toplu işler (§3.25).
- **Panel** `__tanhu.struct`: `list, get, setStep, hit, ignite, speed, reset, diff, nav, labour` (`structures.md` §17).

**Faz 6 entegrasyonu (L).** Sözleşmeye eklenenler:

- **Kurulum.** `systems.js`: `StructureSystem` (60), `BuilderSystem` (62), `Combat` (70), `Projectiles` (72), `Telegraph` (74); son üçü `ctx.combat`, `ctx.projectiles`, `ctx.telegraph`. `StructureSystem.onWorld(world, nav, navRide)` `StructureNav`'ı kurar, `rebuild()` bir kez; her kare `nav.update(dt)`, `manager.focus = game.pos`, `manager.driven` = ustaların bağlandığı yapı (`builders.structure`, yoksa null). `app.js`: `hud.mount(new BuildStatus(ctx))`.
- **Kip.** `menu.enter`, `newgame.enter`, `creator.enter` `world.structures.setMode('menu')`, `freeroam.enter` Çocuğu yerleştirmeden önce `'play'` çağırır; sistem `app:state` ile aynısını yapar (aynı değer, aynı sonuç). `drawMenuFrame` (`menuDiff`) kareyi menü kipinde çizer, kipi geri yükler; ok havuzu, telegraf, ustalar ve yardım halkası o karede gizlidir.
- **Kayıt.** Serbest Gez kaydı (`tanhu.roam`): `camp3` (yapının `toJSON`'u, `structures.md` §11.8) ve `camp.structures[id]` (yalnız sağlam olmayan A, B, ahır, çit); dosyadaki öteki alanlar korunur. Yazım: adım ve yapı bitince, 30 sn'de bir, `freeroam`/`play`'den her çıkışta (harita, duraklatma, menü). Açılışta `onWorld` okur. Yolculuk bloğu `world.structures` (order 73) yalnız `spec.journey` dünyasında dolar (Faz 10).
- **`StructureManager`.** `attach(ctx)`, `mode`, `focus`, `driven`, `speed` (gizli panel), `hideDebris`, `fx` (`StructureFx`), `cameraShake(x, z)`: büyük çöküşte (aşama 6, 4, 3, 2) `game.shake(0,06 × k, 0,3)`, oyuncu 15 m içinde tam, 40 m'de sıfır. `StagedStructure`: `toLocal`, `toWorld`, `hitRay`, `douse`, `heave`, `holeAt`, `reset({ full })`, `navKey()`, `navBox()` (yeniden damga kutusu: iz + camp3'te stok dikdörtgeni); `StructureState`: `cutUnit(id)` (senaryo kesişi; `cut` yırtık sayısıdır), `helpUse` (ustaların yardım sayaçları, kayıtta `help`); yanarken `structure_fire` döngüsü (ses sınırı dolarsa `fire_catch` çıtırtısı), menü kipinde ve `dispose`'da susar.
- **Usta.** Yardım tablosu tektir: `game/builders.js` `CHILD_HELP` (K21: katılma fiilleri ve ayak işleri; kredi kalktı, `d2/core.md` §2.10). Ekip Oktar, Erka ve Dengiz baştan sonadır; Çocuk adımın fiilini yaptıkça 0,5 ağırlık ve bir baştır; batıştan sonra `G_TORCH` direkleri yanar; hava durağında `SHELTER` (`d2/core.md` §2.8). `BuilderSystem`: `status` (HUD parçasının okuduğu düz nesne, `rev`), `placeLabel(x, z)` → «Yeni Yurt · Kerege 3/6» ya da `null` (inşaat sürerken, 10 m içinde; `freeroam.update` oda adı yoksa `hud.setPlace`'e verir), `speed`, `setVisible(on)`. Çocuk yük alınca `ChildSystem.stow(true)`. Bitişte `world.folk.lookAt(site, 4)`.
- **Panel ekleri.** `hit(id, type, lx, y, lz, { fly })` ve `ignite(id, lx, y, lz, torch)` gerçek saldırı kurar (`attackFor` → `makeAttack`, `data/weapons.js`): ok adları 14 m öteden `projectiles.fire` ile uçar, öteki vuruşlar `combat.strike`; `ignite` meşalenin (ya da ateşli okun) değişini vurur, meşalede 3 sn basılı tutuşu da ekler (70 sn). Ek: `setStage(id, n)`, `repair(id, sec)`, `save()`, `json(id)`, `fx()`. Paneli `StructureSystem` kendi kaydeder (`devtools.register`, yalnız geliştirmede).
- **Programlar.** `app.start` `compileAsync`'i post'un HDR hedefi bağlıyken çağırır: sahne hep o hedefe çizilir, eskiden derlenen tuval sürümü (srgb) hiç kullanılmıyor, program sayısını ikiye katlıyordu. Ardından yapılar oyun kipinde bir kez eşitlenir (dt 0) ve bir kare perde altında çizilir: gölge derinlik programları, `struct_depth_*` dahil, açılışta derlenir. Ölçüldü: menü 56, Serbest Gez 57, hasarlı A ile 58 program (tavan 92).

**K21 emek yasası (§3.25).** Süre saniye değil emektir: adımın `work` alanı ekip emeğidir (İD), `solo` tek el çarpanıdır (yalnız `y_tunduk`, 1,6: bakanla), `min`–`max` el sınırıdır; tanımda `craft` (`home`, `wood`, `earth`) ve `crewMax` vardır; parça ve ham teslim `parts`, `rawWork`, `rawRole` alanlarıdır (`d2/core.md` §2.6; `spec.labour.rawWork: false` dünyasında ham iş eklenmez). Oranı yalnız sürücü yazar: camp3'te `BuilderSystem`, öteki şantiyelerde `SiteSystem`, ana kampın A, B, ahır ve çitinde yapının yedeği (iki elin oranı); `StructureState` yalnız tüketir. Kışlak Yeni Yurdu `mode: 'timed'`'dır: `SiteSystem` saat, ekip, malzeme ve hikâye kapısıyla sürer. Sayılar `d2/core.md` §2 ve `structures.md` §2.4.

**K22 hava (§3.24).** `WeatherSystem` her kare `world.structures.wind`, `.windDir` ve yapıların `spreadEntry.wet`'ini (keçe ıslaklığı) yazar, yanan yapıya `douse(fx.douse × dt)` uygular; sıçrama `R = 10 + manager.wind` tek kuraldır. 9.6 ekler: ateşli okun tutuşma çarpanı `1 − 0,5 × felt`; aşama değişince yapı yöneticisi `world.tallThings`'e aday ekler ve siler (kurulmakta olan yapı aday değildir; yurt `bounds.top` 8,6 m); **Bağla / Tie Down** (`tent`, `rack`; `E` 3 sn, kalıcı) ve **Çöz / Untie** (`E` 1 sn) etkileşimi; `fx.galeDamage`'de bağsız çadır bölüm başına %25 olasılıkla bir aşama düşer, bağsız raf içinin %20'sini döker (`structures.md` §6.5). Islak keçe `FELT_WET` kancasıdır; program eklenmez.

**K23 yerleşim yapıları (`settlement.md` §7, `structures.md` §4.6).** Yeni türler ve hazır ayarlar veri olarak `STRUCTURE_DEFS`'e 8.11'de girer: `yard`, `mound`, `ring`, `post`, `field` aileleri; `shed` `open`/`walled`, `tower` `low`/`gate`/`granary`, `fence` `picket`/`stockade`; `yurt` `scale` ve `hearth: false`; `y_raf`, `y_seki`. Görünüşleri `world/structure-kits.js`'tedir (9.10): `StagedStructure._build` bugün yalnız yurdu kurar (`camp.buildYurt`); ahırın ve çitin görünüşü yalnız kampın hazır görünümü benimsenince (`adopt`) vardır. 9.6 `KITS`'i bağladıktan sonra (9.10) `_build` ve `_look`, benimsenmiş görünümü olmayan her yurt dışı yapıda (`fence` `picket`/`stockade` dahil) `KITS[kind]`'a sorar; karşılığı yoksa yapı görünüşsüz (yalnız mantık) çalışır. `def.scale` (Otağ 1,4) kökü, `bounds`'u, nav şekillerini, oda sınırını ve pedi birlikte çarpar, birim canı `scale²` ile çarpılır (9.6). **Uzak yapı.** 40 m ötesinde ya da en yakın dördün dışında yurt kendi ağını gizler, `YurtField` yuvasına geçer (`closed` örneği, `aCut` yapım yüksekliği, `aChar` yanık; 220 m ötesi 96 üçgenlik kubbe); öteki türler `KitField`'e (bütün türlerin kaba ağları tek `BatchedMesh`, tür başına ≤400 üçgen); yakına giren yapı 0,25 sn'de kendi ağına döner (`settlement-view.js`, 9.9). Aynı anda ≤48 canlı `StagedStructure`. **Yerleşim denetimi** `nav.canPlace(shapes)` (9.2): geçici damga, `labelComponents`, ocak, kapılar ve zon kapıları aynı bileşende mi; sonra geri alır (≤3 ms, tıklamada bir kez).

### 3.12 Kaynak düğümleri

```js
// world/node-store.js (saf)
export class NodeStore {
  constructor(nodeSpec, { seed, heightAt });   // economy.md §3.5, §11.1; SoA, 24 B/düğüm
  count;  x; z; y; yaw; scale; kind; charges; flags; tone;      // tipli diziler
  query(x0, z0, x1, z1, fn);    // 100 m parça dizini
  consume(index, n = 1);        // → kalan; 0 ise depleted biti
  dropPile(x, z, items);  piles;
  onDawn();                     // yenilenir, kalıcı bit kalır; NodeSystem 'dawn' olayında çağırır: ≤24 sa atlamada atlanan her şafakta bir, uzun atlamada bir kez (K20)
  applyTaken(cluster, n);       // K23: yerleşimin uzaktan aldığı n hakkı kümenin düğümlerinde tohumlu sırayla işaretler (kalıcı: perm, yenilenen: day); dünya kurulurken
  toJSON();  fromJSON(o);       // { perm: base64, day: [[i,c]], piles: [] }
}

// world/nodes.js
export class NodePools {        // tür başına InstancedMesh, frustumCulled=false; culling CPU'da
  constructor(store, world);
  update(camera, focus);        // 12 m ya da zum 2 m ya da düğüm değişimi: tek geçiş
  flash(index);  setMode('foot'|'ride'|'gallop'|'blizzard'|'lookout'|'room'|'frozen');
  stats();  dispose();
}
export class NodeSystem {       // GameSystem; ctx.nodes
  store; pools; hot;            // ≤60, ≤22 m, 0,25 sn ya da 1 m'de bir
  collectInteractions(q, out);  onPick(q);  onWorld(world, nav);
}

// data/node-kinds.js
NODE_KINDS.node_pine = { name: {tr,en}, prompt: {tr,en}, tool: 'axe_bronze'|null, action: 'strike'|'hold', hits: 5, holdS: null,
  yield: [{ item: 'wood_pine', n: 3 }], charges: 1, renew: 'perm'|'dawn'|'none', sense: false, r: 0.45, block: true, noise: { axe: 24 } };
// K22: isteğe bağlı weather alanı (node_mushroom: son 12 sa'te ≥1 sa yağmur ×2, değilse ×0,5; node_dung: yağmurdan sonraki 6 sa yakıt ×0,5);
//      açık yığınların flags dizisinde wet biti: yakıt ve yem değeri ×0,5, 2 sa dryK ≥0,6 ya da ateşin 4 m'sinde 30 sn kurur (weather.md §8.14)
// K23: spec.nodes kümeleri id taşır (c_elm_bend …); yerleşim kümeden aldığını settlement.taken[cluster]'a sayar, NodeStore bellekte olmasa da
// K21: node_camp_logs: ana kampın kütük yığını; camp3'ün help_log ayak işi buradan alır
```

```js
// game/gather.js: GameSystem. Durumlar idle, walk, swing, hold (economy.md §12)
gather.begin(index);   gather.cancel();   gather.state;
// Vuruş temas 0,72 T: store.consume, inventory.add; sığmazsa store.dropPile; gather:yield, node:hit.
// Gece: bus.emit('noise', { x, z, r, src: 'gather' }).

// game/strike-ring.js
ring.start({ x, z, T, window, gold, onHit, onMiss });   // 1 çizim, Game.marker deseni; ayar game.ringAssist
```

### 3.13 Eşya, stat, beceri

```js
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

// game/inventory.js (saf): Yük onda bir tamsayı
export class Inventory {
  constructor({ bus, cap /* () => loadMax */, flags });
  add(id, n = 1, { src, allowOver = false });    // → { added, rest }; item:add, load:change
  remove(ref, n = 1);                            // → gerçekten çıkan [{ id, n }]; etiket kabul eder
  count(ref);  has(ref, n = 1);
  load();  loadFrac();  speedK();  canRun();  canJump();
  tab(name);                                     // 'back'|'food'|'craft'|'tools'|'keepsakes' → [{ id, n }]
  equip(slot, id);  unequip(slot);  equipped(slot);  equipBlock();  // gear alanları derive'a
  chest;  stash(way);  cart;  cache;  sled;  saddlebags(mountId);   // hepsi game/container.js Container (§3.26): { add, remove, list, load(), cap }; Terki sınırı binek Yük'ü
  setResolver(fn);  site(id);  store(id);  pool(place);              // K21, K23: kaydı başka blokta olan kaplar: şantiye yığını (world.sites), yerin kapları (settlement); fn(kind, id) → Container | StorePool | null, L bağlar
  deliverTo(c, ref, n);                                             // heybeden bir kaba (transfer); bohça teslimde açılır; item:move yayar
  seize();  restoreSeized();                     // `sentenced` kuralı: progression.md §6.1
  bell;                                          // { on, plug, fate }
}

// game/derive.js (saf). Kare başına çağrılmaz; girdi değişince progress.derived() önbelleği boşaltır.
export function derive({ stats, level, wounds, gear, mods, buff, flags, axes, fullness, load, diff, bond, mount, env }) // → Derived; env: { ground, shelter, blizzard, route }, değişince invalidate
Derived = {
  hpMax, hpRegen, staMax, runDrain, staRegen, jumpCost, exhaustedUntil,
  crouch, walk, run, loadMax, loadFrac, loadMul, slowFrom, canRun, canJump, dodgeT, dodgeCost,
  meleeMul, pullF, drawT, spread, range, slingDmg, slingRange, slingStun, slingReload,
  strikeMul, sense, trustGainK, noiseR, visBase, gallop, spur, horseDrain, horseRegen, turnRate,
  stats /* etkili */, gear, mods,
};  // Formüller progression.md §2.3

// game/progress.js (saf)
export const xpCurve, levelCaps, statCaps, axisCaps, xpScale, origins, STAT_IDS, AXIS_IDS;   // save.setRules aynı tabloları alır
export function dreadEffects(korku);     // → { trustGainK, guardPause }: Korku eşiği (§5.2); derive ve stealth okur
export function scaleXp(base, act);      // perdeye göre XP (§1.3)
export class Progress {
  // tables: verilmeyen bu dosyanınkidir; skills satır dizisi, { id: satır } ya da Map. cond: tam CondCtx (journey.js, 10.8),
  // verilmezse ilerlemenin kendi yolları ve bayraklar; derive: game/derive.js; inputs: () => ilerlemenin bilmediği alanlar
  constructor({ bus, flags, tables: { xpCurve, levelCaps, statCaps, axisCaps, skills, origins }, cond, derive, inputs });
  get(path);  check(expr);  cond;        // CondCtx yolları: eksenler, ties.<kişi>, stat.<id>, skill:<id>, atlas:<id>, level, act; gerisi bayrak
  // XP ve seviye
  addXp(n, src);  level;  xp;  actCap;  actChange(n);   // actChange: tavanlar, respecTokens +2, lost_master temizlenir, era = latestEra()
  // Stat
  stats;  statPoints;  spendStat(id);    // → boolean
  // Beceri
  skillState(id);                        // 'hidden'|'locked'|'teachable'|'ready'|'learned'|'lost_master'
  canLearn(id);  learnBlock(id);  learn(id);  teach(id);  checkTeach();  onSentenced();  mod(key, def);  mods();
  grantPoint(id);                        // görev puanı: aynı kimlik bir kez, skillPoints +1 (`point` etkisi)
  bar;  setBar(slot, id);                // 6 yuva
  // mods biçimi: sayı toplanır, { mul } çarpılır, { set } ezer, dizi birleşir; requires ve teach.when koşul dilidir
  // Eksen
  setAxis(axis, delta, { once = null, src = null });   // Kut, Korku tavan; once tekrar saymaz
  axis(name);                            // 'kut','korku','trust','herd_habit','names_known','hearths_out','reflex'
  addTies(npc, n);  ties(npc);
  oath(id, state);                       // 'given'|'kept'|'broken'
  // Türetilen
  derived();  invalidate();
  // Atlas: §3.18
  revealed(row);  reveal(id);  era;  latestEra();
  // Kayıt (§3.5): player, axes, oaths order 30; world.atlas_revealed, world.era order 72. reset(init) kökeni ve görünüşü alır
  registerSave(save);
}
```

Beceri satırı `progression.md` §4.4, durum makinesi §4.2, puan §1.4. `data/mod-readers.js` okuyucu tablosu `check-data` ile denetlenir (§6.2).

### 3.14 Bayrak, koşul, etki, görev

```js
// game/flags.js (saf)
export class FlagStore {
  constructor({ bus });
  get(key);  has(key);  set(key, value = true);  inc(key, n = 1);  push(key, value);  // push: dizi, tekil
  toJSON();  fromJSON(o);
}

// game/cond.js (saf)
export function compile(expr);    // → (ctx) => boolean; dizgeye göre önbellekli; hatalı dizge throw
export function evalCond(expr, ctx);
CondCtx = { get(path) };          // journey.js kurar
```

Dil `progression.md` §4.1'in genişletilmişi:

```
expr  := and ('||' and)*          and := unary ('&&' unary)*
unary := '!' unary | '(' expr ')' | atom
atom  := name ('>='|'<='|'=='|'!='|'>'|'<') value | name
       | 'skill:'id | 'item:'ref[':'n] | 'quest:'id'.'('active'|'done'|'failed') | 'step:'qid'.'stepId
       | 'slice:'name | 'phase:'name | 'beat:'id'.'state | 'atlas:'id | 'tally:'npc
name  := trust | kut | korku | herd_habit | reflex | names_known | hearths_out | bond | act | day | hour | dark | moon | level | rank
       | ties.<npc> | stat.<id> | ledger.<line> | <bayrak>
```

Bilinmeyen `name` bayrak sayılır: yoksa false, sayıyla kıyasta 0.

K20: `day` hikâye günüdür; `hour` gün saatidir (`hour>=12`); `dark` güneş −6°'nin altındadır; `moon` ayın aydınlığıdır (0..1, takvimden); `'phase:'name` evre (`dawn`, `morning`, `noon`, `golden`, `dusk`, `night`); `'beat:'id'.'state` vaktin durumu (`wait`, `open`, `held`, `done`); `'slice:'name` eski dört dilim olarak çalışmayı sürdürür.

```js
// game/effects.js (saf)
export function applyEffects(list, services, { source });   // list: tuple dizisi; bilinmeyen op geliştirmede throw
```

| `op` | Parametre | Yapılan |
|---|---|---|
| `flag` | `key, value=true` | `flags.set` |
| `push` | `key, value` | `flags.push` |
| `axis` | `axis, n, once?` | `progress.setAxis` |
| `ties` | `npc, n` | `progress.addTies` |
| `xp` | `n, src` | `progress.addXp` |
| `give` | `item, n=1, once?` | `inventory.add`; `once` varsa `flags._given.<once>` ile bir kez |
| `take` | `ref, n=1` | `inventory.remove` |
| `teach` | `skill` | `progress.teach` |
| `point` | `id` | Görev puanı, `pointsGranted` korur |
| `quest` | `id` | `quests.start` |
| `step` | `qid, stepId` | `quests.forceStep` |
| `dialogue` | `id` | `dialogue.start` |
| `bark` | `lineRef` | `dialogue.bark` |
| `reveal` | `atlasId` | `progress.reveal` |
| `station` | `id, state` | `travel.setStation` |
| `route` | `id, state` | `travel.setRoute` |
| `rank` | `n` | `regions.setRank` |
| `region` | `id` | `regions.open` |
| `clock` | `'set', 'hh:mm'` · `'atLeast', çapa` · `'advance', dk` · `'hold', id, 'hh:mm'` · `'release', id` | `worldClock`; yalnız ileri; `hold` yalnız `dawn_line`, `ice_story` (K20; `work` kalktı) |
| `ledger` | `line, n, place = 'winter_camp'` | `supply.get(place).add`: `winter_camp`, `own_seat`, `own_camp`, `field_camp` (§3.26) |
| `music` | `state` | `audio.music.setState` |
| `sfx` | `id` | `audio.sfx.play` |
| `cine` | `id` | `cine.play` |
| `weather` | `do, id?, ...` | `ctx.weather`: `lock`, `release`, `progress`, `pin`, `freeze`, `calm`, `flash`, `strike`, `gap` (`weather.md` §6.1); hava sistemi yoksa yok sayılır |
| `structure` | `id, method, ...args` | Yalnız `setStage, ensureStage, tear, ignite, cutRoof, beginHeave` |
| `oath` | `id, state` | `progress.oath` |
| `card` | `key` | Eksen ve kural kartı, bir kez |
| `toast` | `key` | `ui.toast` |
| `emit` | `name, payload` | `bus.emit` |
| `if` | `cond, then, else?` | Dallanma |

```js
// game/quests.js (saf çekirdek): GameSystem
export class Quests {
  constructor({ bus, cond, effects, defs });
  start(id);  forceStep(id, stepId);  fail(id);
  state(id);       // 'none'|'active'|'done'|'failed'
  active();        // görevler ekranı: [{ id, step, text, marker }]
  markers();       // haritada ve zeminde hedef
  update(dt);      // reach, timer: 0,25 sn'de bir
  toJSON();  fromJSON(o);
}
```

Biçim §4.1. Her adım bir önceki bitince başlar; çalışan görev kaydı `{ state, step }`, `progression.md` §13.2. `quests.update` kare başına ayırmaz.

### 3.15 Diyalog çalıştırıcı (`game/dialogue.js`)

```js
export class DialogueRunner {
  constructor({ bus, cond, effects, defs, voice, ui, input, clock, stealth });
  start(id, { npc = null, at = null, mode = null });  // → Promise<{ result, choice }>; her durumda çözülür
  advance();      // satırı geç: E, Boşluk, tık
  choose(index);  // seçim
  cancel(reason); // sahne değişimi, baskın; promise 'cancelled' çözülür
  bark(lineRef, { at = null, r = 12, who = null }); // bloksuz altyazı, 3B ses; kuyrukta en çok 2
  active;         // { id, node } | null
  update(dt);     // süre, ses bitişi
}
```

| `mode` | Girdi | Oyun | Kullanım |
|---|---|---|---|
| `scene` | `dialogue` modal bağlamı | Dünya karesi akar, oyuncu durur; dünya saati (`worldClock.pause('dialogue')`) ve `stealth` algısı durur (`act1.md` §9.5) | Büyük sahne, seçim |
| `walk` | Bağlam yok | Oyuncu yürür, satır 3B kısılır, seçim yok; saat akar | «Kişiler iş bırakmaz, yürürken konuşur» |
| `flow` | Bağlam yok | Kovalamaca ve sefer: altyazı akar, blok yok | `act1.md` §10, §15 |

Satır süresi: ses varsa `voice.done`, yoksa `speechSeconds(metin)`. Kullanıcı `advance` ile geçer; `flow` kipinde geçilmez. Kural (`act1.md` §15): sahne değişimi diyaloğu kilitlemez; `world:dispose`, `cine:start` `cancel` çağırır. UI: `ui/dialogue-ui.js`: portre (`public/ui/portraits/<id>.webp`, yoksa boş), ad, satır, seçimler; satır dili `lang()`, ses hep İngilizce.

### 3.16 Ajanlar, program, gizlilik

```js
// game/agent.js. Follower, NpcAgent, AnimalAgent, PursuerAgent buradan türer.
export class Agent {            // canlıysa Damageable
  constructor({ id, kind, ctx, x, z, h = 0, nav = null, actor = null, mount = null });
  id; kind; x; y; z; h; v; state; stateT; actor; mount; nav; hidden;
  living;                       // { hp, hpMax, class, stunT, koT, alive } | null
  setState(name, arg);
  moveTo(x, z, { speed, reach = 0.4, token = null });  // → Promise<'arrived'|'cancelled'|'blocked'>; her durumda çözülür; hedef aşılmaz
  stop();  face(x, z);  look(point | null);  say(lineRef);
  simulate(dt, t);              // kademe S0, S1: kare; S2: seyrek
  place(dt, t);                 // Rig.update ve kök; gizliyse yok
  // Damageable
  bounds();  hitRay(o, d, maxT);  hit(atk, point, dir);  onHit(atk, res);
  onWorld(world, nav);  dispose();
}

// game/agent-move.js (saf): army.md §5.3 çekirdeği
export function stepTowards(a, want, dt, tuning, nav);  // kaydırmalı adım
export function pickGoal(a, slot, leaderCrumbs, nav);   // §5.4 merdiveni

// NavView: NavGrid ve NavPatches ikisi de sağlar (army.md §5.1 + structures.md §12.1)
NavView = { blockedAt, dynAt, topAt, rawTop, lineFree(ax, az, bx, bz, step), nearestFree(x, z, group), find(ax, az, bx, bz, { maxSteps }),
            stampDyn, clearLayer, stampLayer, stampLayerTop, labelComponents, epoch,
            canPlace(shapes) };   // K23 (9.2): geçici damga, bileşen denetimi (ocak, kapılar, zon kapıları), geri al; → { ok, reason }, ≤3 ms
```

**NavGrid (5.7).** `find` sıçrama noktası aramasıdır (JPS), hareket kuralı A*'la aynı; düzeltme `segmentFree(ax, az, bx, bz)` ile (doğrunun değdiği her hücre, köşeden geçişte iki yan hücre). `maxSteps` (varsayılan 200.000) **incelenen hücre** sayar: ordunun 4.000'i ≈0,06 ms'dir, ≈60.000 önerilir (`army.md` §5.4). Hedef hücresi, bölge ve `epoch` aynıyken yol önbellekten sürer (basılı tıklama A* koşturmaz); bulunamayan hedef aynı hücreden ızgara değişene dek yeniden aranmaz. Ek alanlar: `cellAt(x, z)` → indis | −1, `nearestCell(x, z, group)`, `steps` (son aramanın incelediği hücre), `epoch` (ızgarayı değiştiren her yazım artırır: `fill`, `stamp`, `stampDyn`, `labelComponents`; 6.2'nin katman yöntemleri de artırmalı). `lineFree(…, step)` varsayılanı 5 cm. Kamp ızgarasında 3.000 rastgele yol: medyan 0,1 ms, bulunan en ağır ≤0,8 ms. **Cep sınaması (Faz 6 duman 2):** bölge etiketi atları (`dyn`) saymaz; atla ya da yapıyla kapanan küçük cepteki hedef etikette açık görünür ve arama `maxSteps`'e dek koşardı (ahırda 2,6–7,2 ms). JPS'den önce hedeften dört komşulu taşma (önceden ayrılmış kuyruk, çağrı başına ayırma yok) `POCKET_MAX` (256) hücrede başlangıca varmazsa yol yoktur, arama koşmaz: ≤0,4 ms, başarısızlık önbelleğe `steps` Infinity ile yazılır, `steps` taşmanın dokunduğu hücre sayısıdır. Daha büyük kapalı cep yine `maxSteps`'te durur. 3 × 3.000 rastgele kamp yolu: medyan 0,1 ms, p99 0,5–0,6 ms, en ağır 0,7–1,1 ms.

```js
// game/schedule.js (saf)
export function resolveSchedule(table, npcId, { day, minute, flags, overrides });   // table: [[from, to, at, job], …] oyun dakikasıyla (time.md §9.4); sev ≥3 havada açık hava yuvası shelter noktasına
// → { at: [x, z], job: 'count'|'tally'|..., pose: 'stand'|'sit'|'work', room: id|null, gesture: name|null, hidden: boolean }

// game/npcs.js: GameSystem, ctx.npcs
export class NpcManager {
  constructor(ctx);
  spawn(def);                   // def: { id, look, schedule, voice, hostile? }
  get(id);  list();             // → NpcAgent
  onBlock(day, minute);         // blok değişince yeni hedef; yürüme süresi kadar önce çıkar; >60 m ve kadraj dışında konum sıçraması; clock:skip'te herkes yerine
  budget;                       // { full: 16, puppets: 40, ghost: 8 }
  setFocus(x, z);               // kademe seçimi 4 Hz, ±%15 gecikme
  crowd(id, { count, spots, look });   // kukla grup: Göz Yolu, pazar
  toJSON();  fromJSON(o);
}
```

**Kademe.** Adlı kişilerin `Folk`'u dünya kurulurken üretilir, `root.visible=false`: 14 ana + 8 ikinci kişi (`act1.md` §3), üçgen ödenmez, yalnız bellek. En yakın ≤16'sı görünür; `act1.md` §15. Kukla `character/puppet.js` `army.md` §7.3 ağ sözleşmesidir: ≤1.200 üçgen, tek `InstancedMesh`.

```js
// game/stealth-core.js (saf): act1.md §9.5, progression.md §2.3
export function visionRate({ d, R, crouched, groundVis, perception, visMul, modsVis, buffVis, erlikMul });  // ds/dt
export function hearRate({ d, noiseR, perception });
export function noiseRadius({ gait, bell, plug, foot, gearNoise, mods });
export function inCone(gx, gz, gh, coneDeg, x, z);
export const THRESH = { q: 0.15, bang: 0.6, caught: 1 };

// game/stealth.js: GameSystem, ctx.stealth
export class Stealth {
  addGuard(agent, { coneDeg = 80, R = 16, lanternR = 20, scanDeg = 0, patrol = null, pauseS = 2.5, speed = 1.6 });
  removeGuard(id);  guards();
  noise(x, z, r, src);          // bus 'noise' de buraya bağlı
  setPaused(reason, on);        // diyalog, sinema, Donuk Kamp
  setGlobalMul(k);              // erlikMul ×0,5, ×0,75
  suspicion(id);                // 0..1
  track(x, z, h);               // track-decals, ≤64
  occluded(x, z, gx, gz);       // LOS: yükseklik + yapı; nöbetçi başına 5 Hz, kademeli
}
```

Hayvan algısı aynı çekirdeği kullanır; rüzgârın yönü ve gücü havadandır (`weather.md` §8.4): ≥1 m/sn rüzgârda altı ×0,5, üstü ×2; fırtınada (≥12 m/sn) ×0,4 ve ×2,5; durgunda yön yok.

**Hava ve saat (K20, K22).** Çarpanlar kullanım anında uygulanır, `derive` değişmez: işitme yarıçapı `noiseR × fx.hearK`; görüş `R_eff = min(R, 0,6 × fx.vis)` ve algı hızı `× fx.fogK(d)`; nöbetçi konisi `coneDeg` × yağmur ve sulu kar 0,85, sağanak ve dolu 0,75, tipi ve toz 0,7 (tarama açısı değişmez). Gizlilik saatten çarpan almaz: `act1.md` §9.2 «Karanlık» koşulu `worldClock.dark` ve oyuncunun ışık havuzunda olmamasıyla açılır, şimşek nabzında (`fx.flashK > 0`) kapanır. I. Perde'nin kilitli gecelerinde `pinFx` kalibre sayıları korur (`mask` 0). `read_watch` konileri yere çizer: `telegraph` değil ayrı halka; 18 m, en çok 8.

### 3.17 Hızlı yolculuk ve birlik

API, veri ve kilit sırası `travel.md` §12, §8; birlik `army.md` §5, §8. Bu belge yalnız bağlantı noktasını sabitler.

```js
// game/travel.js: GameSystem, ctx.travel
export class Travel {
  allowed(kind, to);            // → { ok, reason, args }; ilk eşleşen kilit
  strike(stationId);  board(seat = 'S1');
  depart({ to, mode: 'watch'|'shorten'|'drive'|'erlik', cargo });
  forceReturn(stationId);  scriptedRide(polyline, opts);      // → Promise, Ride.cancel her bekleyeni çözer
  startLeg(routeId, mode);      // app.goTo('travel', { payload: { routeId, mode } })
  setStation(id, state);  setRoute(id, state);                // hidden → rumoured → found → linked; hidden → rumoured → scouted → line
  state;                        // IDLE, CALLED, WAITING, BOARD, CARD, DEPART, CRUISE, SKIP, ARRIVE, ALIGHT, DRIVE
  collectInteractions(q, out);  // direk 90, araba 85
  serialize();  restore(o);
}
// world/road.js (saf)
export class Road { constructor(pts, { width, ground, radius }); length; at(s, out); heading(s); project(x, z); }
export class Network { route(a, b, { gates, time }); edgeOpen(e); }
```

- **Koltuk.** Yolcu `game.seat(ride)` ile bağlanır; `Game` konumu `Ride`'dan okur, hareket girdisi kapalıdır (`travel.md` §9.5 `this.seat` dalı).
- **Atlas yolculuğu.** `travel` durumu `travel.md` §9.4 akışını sürer; `yieldGate` iğne konağa varınca çözülür; `App.replaceWorld` çağrılır.
- **`atlas.openLeg(route)`, `closeLeg()`, `pickMode`** `map/atlas.js`'te, §9.5.

```js
// game/squad/index.js: GameSystem, ctx.squads (army.md §8)
export class SquadManager {
  spawn(unit, { roster, formation = 'wedge', mount = true });  // → Squad; ≤12
  remove(id);  command(cmd, payload = {});
  simulate(dt, t);  place(dt, t);   // GameSystem.update ve place buna köprülenir
  onRoom(room);  onWorld(world, nav, navRide);  camBias();   // { dist, fwd, lead } | null; varsa game.cam.push('squad', …)
  toSave();  fromSave(rec);  stats();
}
LeaderPose = { x, z, y, h, v, mounted, moving };   // game.leaderPose(out)
```

**Act 1 kancası.** Ku ve firariler `Squad` üyesidir (`act1.md` §9.7). `first_ten` ve `fromFirstTen` `act_change(2)` içinde bir kez. `travel.party` `army.md` §8 köprüsü. `?squad=10` demosu Faz 10'dan sonra Serbest Gez'de açılır, menüde görünmez.

**Saat ve hava (K20, K22).** Araba seferinde saat doğal süreyle akar; Yol Akışı `k` (1–4) saatin oranıdır; Yolu Kısalt kalan doğal süreyi `clock:skip { reason: 'travel' }` ile atlar; atlas bacağı varışta yol süresi kadar atlar, 24 saati aşan bacak uzun atlamadır (`long: true`). `LOCKS` 7. sırada `weather` kilidini alır (`fx.cartLock`; kalan süre plandan, yarım saate yuvarlanır); `sev` ≥3 havada çevre şeritleri durur; atlas yol olayları havuzuna `ev_storm`, `ev_dust`, `ev_flood`, `ev_snowbound` girer (`weather.md` §8.10).

**II. Perde kancası (K23).** Yerleşim `tanhu_ordu` (`own_seat`), ana ordugâh `whistle_field` (`own_camp`); ikmal kervanı `r_whistle_ordu` üstünde yerleşimin `CaravanBook` kaydıdır (§3.27), dünya kurmaz: atlasta `travel.md` §10.4 minik arabasıyla görünür (≤12), varışta yük hedefin kabına yazılır. Mete kervanla giderse atlas bacağı kervanındır ve yol olayları ona sorulur; gitmezse «Yol Töresi» kendiliğinden çözer (`settlement.md` §11). `cmd_detail` erleri yerleşimin iş havuzuna «Er / Rider» olarak girer; `cmd_camp` `CampPlan` kurar (§3.27).

### 3.18 Atlas açılma koşulu

```js
// game/progress.js
revealed(row);     // row: geography.js satırı { id, unlock?, eras? } → boolean
reveal(id);        // world.atlas_revealed'a ekler, atlas:reveal, bir sonraki Atlas.open yeniden boyar
```

**Kural.** `unlock` yoksa: fiziki coğrafya, her zaman açık. `unlock: 'start'`: açık. Aksi: koşul dili ifadesi, ör. `'quest:sq_iron_tooth.done'`, ya da `atlas_revealed` içinde `id`. Satır adları yalnız gerçek adlardır; genel grup sözcükleri ve `kind` değerleri kaldırılır (denetim §e, `groups-research.md` §3).

| Okuyan | Yer | Değişiklik |
|---|---|---|
| Boyama | `relief.js:164` `paintOverlay(ov, era, layers, revealed)` | Üç çağrı yeri `atlas.js:167,465,661` |
| Etiket, simge | `atlas.js:903` `itemOn` | `progress.revealed(it)` |
| Dönem düğmesi | `atlas.js:443-453` | Yalnız açılmış dönem; varsayılan `progress.era`. Yeni `210` |
| Yaşam listesi | `atlas.js:472-477`, `681-690`, `openEvent` | Açılmamış olay gizli |
| Kırıntı | `atlas.js:994-1010` | Kimlik, açılmamış bölge adı yok |
| Açılış | `atlas.js:705` | Kirli bayraklar, yeniden boyama |

Atlas ayrıca `progress` değil `revealed` işlevini kurucuda alır: harita Serbest Gez'de de açılır, orada `revealed = campReveal` (başlangıç ve kamp). Ölçek: `AREA_KM2 = 75000`, `KM_PER_UNIT = 7.0711`, `MAP_AREA_UNITS = 1500` (denetim §e Seçenek A).

**Faz 4 sonucu.** Satır alanları (`geography.js` başı): `id` bütün tablolarda tekil; `group` birkaç satırın ortak kimliği, `reveal(group)` hepsini açar; `unlock` yoksa fiziki coğrafya, `'start'` baştan açık, `'camp'` Serbest Gez'de açık ve yolculukta eve dönüşle (`HOME_COND = 'quest:mq_home.done || act>=2'`), başka her değer koşul dili; `rumour: { eras, at }` o dönemlerde yalnız sönük ad (`.al-rumour`), leke, sınır ve simge yok (`relief.js` `drawnIn(p, era)`). Atlanabilen yan görevin açtığı grup en geç `groups-research.md` §4 perdesinde açılır (`'quest:sq_fares.done || act>=6'`). Dönemler `210` (I. Perde), `209`, `200`, `174`; metin `geo.<tablo>.<id>.<alan>`, dönem `geo.eras.<id>.label|title`, olay `geo.events.<id>.year`.

```js
// map/atlas.js
export function campReveal(row);          // Serbest Gez kuralı: unlock yok, 'start' ya da 'camp'
new Atlas({ …, revealed = campReveal, era = null });   // era: dize ya da () => dize
atlas.setReveal(revealed = campReveal, era = null);    // kural değişir; yeni kuralın ilk okuması tabandır, atlas:reveal kimlikleri silinir
// bus 'atlas:reveal' { id }: kimlik satırı ya da grubu açar, bir sonraki açılışta ≈3 sn mürekkeple belirir
```

Her açılış kuralı yeniden okur (kare başına değil); son okumadan beri açılan satır mürekkeple gelir. Varsayılan dönem ilk açık dönemdir, hikâye yeni döneme geçtiyse o. Kural App'tedir (`setRevealMode`, §2.1): `play`'e girişte `story`, `freeroam`'a girişte `camp`; harita gidiş-dönüşü kuralı değiştirmez. `__tanhu.story.reveal(id)` Serbest Gez'de `atlas:reveal` yayar (yolculuğa yazılmaz), yolculukta `progress.reveal(id)`. Kilim bantları (`ui/woven.js` `installWovenCSS`) atlas ilk kurulurken yazılır. Gerçek kipten dönüşte göl sisi `LAKE_FOG_R`.

### 3.19 Sinema zaman çizelgesi

```js
// core/timeline.js (saf)
export class Timeline {
  constructor({ now /* () => sn */ });
  track(name, keys, { ease = 'sine' });   // keys: [{ t, ...değerler }]; sayı ve sayı dizisi karışır
  cue(t, id, fn);
  play();  pause();  seek(t);  stop();
  update();                               // cue'ları sırayla ateşler; atlanan cue'lar seek'te sırayla çalışır
  sample(name, out);                      // → out
  t;  length;  done;
}

// game/cine.js (yarı saf: three yalnız matematik)
export function fitFov(fov, aspect);      // 16:9 tasarım FOV'u; dar ekranda yatay açı korunur
export function resolveCine(def, { duration });   // → { times: { iz: [sn] }, ends: { voice: [sn] }, length }
export class CineDirector {
  constructor(ctx);                       // ctx.cine olarak App kurar (tek örnek); eksik servis atlanır, testte sahte servisle kurulur
  camera;                                 // Ayrı PerspectiveCamera; Game kamerasına dokunmaz; setAspect'i durum çağırır
  active;  shadowFocus;  t;  length;  id; // Vector3; t çizelge saati
  skipProgress;                           // 0..1 basılı tutma doluluğu (ui/skip-hint.js okur)
  defs;  define(defs);                    // kimlikle oynatma (§3.14 `cine` etkisi): def ya da dizi, aynı kimlik sonuncuyla değişir
  lines;  names;                          // (lineId, row) → { who, text: { tr, en }, voText, small } | null (vo-lines.js storyLine); (who) → { tr, en } (cast.js)
  play(defOrId, { onEnd = null, from = null, focus = null, release = true });   // → Promise<{ skipped, stopped? }>; her durumda çözülür
  skip();                                 // basılı tutma skipHold (0,6) sn; Space, Enter, E, Esc ya da işaretçi; skippable false ise yok
  stop();                                 // dışarıdan kesme: her bekleyeni çözer ve geri alır; fx ve end çalışmaz
  release();                              // sahneye bırakılan izleri geri alır: sis katmanı, ozanın pozu (perform.stop)
  seek(t);                                // geliştirici: geçilen cue'lar sessiz kurulur, süren satırın altyazısı gelir
  setAspect(aspect);  info();  pathAt(T, outPos, outLook);   // info → { id, t, length, active, skipProgress }; pathAt clearance içindir
  update(dt, t);                          // timeline, kamera, sis, aktör; tek karede >0,25 sn sıçrama geçilen satırları sessiz kurar
  applyPost(settings, mood);              // post anahtarları: paint, wobble, tilt, exposure, vignette, edge, bloom
}
```

Veri biçimi §4.3. **Kurallar.** `now` `clock.cineNow`: ses saati, kaynak değişince sıçramaz (§2.5). `near = clamp(dist × 0,1, 0,15, 2)`, her kare. Gölge odağı `world.update` üçüncü bağımsız değişkeni. `world.setFogOverride` çıkışta `null`. Post geçişi profil adlarıyla: `closeup` = `CREATOR_POST`, `wide` = `POST_DEFAULTS` + `tilt: [.5, .5, 0]`; aynı satırdaki sayısal `exposure`, `vignette` profilin üstüne kare kare yazılır. `play` içinde kullanılırsa `Game` durmaz, `Input` `cine` modal olduğu için oyuncu girdi almaz. Ozan tutamağı §3.8 `world.folk.bard.perform`; `Folk`'a taşınmaz (§8 karar 3).

**Dünya saati ve hava (K20, K22).** Sinema dünya saatini varsayılanda durdurur (`worldClock.pause('cine')`); `clock` izi saati yalnız ileri taşır (`set`, `atLeast`, `advance`) ya da sinema boyunca akıtır (`run: true`); atlanan süre `worldClock.skip(dk, { reason: 'cine' })` ile işlenir, atlamada `clock` satırları da uygulanır. `weather` satırı (`{ t, weather: { do: 'lock', id, type, blend } }`) hava kilidi açar; `release()` sinemanın açtığı kilitleri de kaldırır. Menü ve Yeni Oyun sinemasında saat ve hava yoktur (kimlik).

**Faz 5 sonucu (5.3).** `play` önce `voice.preload` (en çok 8 sn bekler), süreler kesinleşince çizelgeyi kurar; kurulana dek kalkış kamerasından çizilir. `from`: `'current'` anahtarının kamerası; `focus`: gölge izi yoksa gölge odağı; `release: false`: sis ve ozan pozu bitişte değil `release()`'te geri alınır (durum perde kararınca çağırır). Çapalar ses satırı (`<id>`, `<id>_end` satırın sonu), kimlikli kamera satırı (kendi `t`'si; `_end` sonraki kamera durağı), gölge (sonraki anahtar), sis ve post (`t + blend`), her izde `dur` yazılırsa `t + dur`; `'end'` öteki satırların en geç bitişi. Kamera aradeğerlemesi anahtarı aşmaz: yön değiştiren anahtarda durur, koridorda süzülür. Altyazı `subtitles: 'voice'` ise her ses satırı kendi altyazısıdır, metin ve konuşmacı `L()` ile; `[sings…]` etiketi görünmez ve süreye sayılmaz. Oyuncu satırı (`actors`): `strum` olay izi, `mouth` cue; oyuncuya ait ses satırı başlarken `perform({ text, duration, buffer, clock: cineNow, tail: null })` çağrılır: ses gerçekten çalıyorsa ağzı dosyanın zarfı (`voice.buffer`), yoksa hece çizelgesi sürer. **Atlama:** kalan cue'lar sessiz çalışır, fx ve müzik bitişteki gibi uygulanır; ses, altyazı, profil ve ağız düşer; ön yükleme sürerken atlanırsa çizelge eldeki sürelerle kurulur. `release` oyuncuyu `perform.stop()` ile hemen oturtur. **Atlama ipucu** (`ui/skip-hint.js`, `css/cine.css`, `cine.skip_hold` «Atlamak için basılı tut» / «Hold to skip»): sağ altta yazı ve dolan halka; oyuncu basınca belirir, bırakınca 2,5 sn kalır (Yeni Oyun durumu sürer). Sınandı (Faz 5): sonuna dek oynayış ve 0, 5,5, 9,7 sn ile `seek(44)` sonrası Space, Esc, Enter basılı atlama; her seferinde `creator`, çalan ses 0, altyazı kapalı, sis katmanı kapalı, ozan oturur, billboard 0, `menuDiff` 0.

### 3.20 HUD ve kabuk

```js
export class HUD {
  constructor(root, ctx);
  slot(id);                 // 'tl','tc','tr','bl','bc','br','prompt','gain','bar': HTMLElement
  mount(widget);  unmount(id);
  setMode('freeroam'|'play'|'none');
  update(dt);               // widget.update; DOM'a yalnız değişince yazar
  setPrompt(prompt);  setPlace(label);  setStats(stats, exhausted);
}
HudWidget = { id, slot, modes, el, update(dt), onLang() };
// Faz 6: ui/hud/build-status.js BuildStatus(ctx, { source }): id 'build_status', slot 'tl', modes ['freeroam', 'play'];
// BuilderSystem.status'u okur (rev değişince yazar): yapı adı, adım, «3/6», fırça izi ilerlemesi, adım düğümleri, yardım ipucu. Can çubuğu yok.
// K21: ek satır «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours» (Çocuk ya da Mete ekipteyse «+ sen» / «+ you»); bekleme nedeni varsa sürenin yerine geçer;
//      kaynak camp3'te BuilderSystem.status, öteki şantiyelerde SiteSystem.status(siteId).
// K20: ui/hud/clock.js SkyArc(ctx): id 'sky_arc', slot 'tr', modes ['freeroam', 'play']; Gök Kavisi: güneş ve ay yayı, evre adı (game.clockShow), bekleyiş düğümü,
//      Son Gece'de Ay Saati kipi (11.7), Tipide gizli; DOM'a ≤4 yazım/sn; dokununca Bekle tekeri.
// K22: ui/hud/weather.js WeatherBadge(ctx): id 'weather', slot 'tr', modes ['freeroam', 'play']; Gök Kavisi'nin yanında 10 SVG simge, cephe 1 sa içindeyse ok;
//      üstüne gelince işaret satırı (iron_stake ile gök okuma); yalnız bölüm değişince yazar.
// K23: ui/hud/plan-bar.js PlanBar(ctx): id 'plan_bar', slot 'bc', modes ['play']; yalnız 'plan' bağlamı açıkken: kategori şeridi, yapı kartı
//      (malzeme var / gerek, emek ve bitiş sözcüğü, bakım, kapasite, kilit nedeni).
// K23: ui/hold-ledger.js registerPage({ id: 'hold', tab: 'book.tab.hold', glyph: 'hearth', hint: 'book.hint.hold', modes: { game: 6 }, create }): Yerleşim Defteri (settlement.md §14.2); hearth simgesi ui/menu/book-glyphs.js DRAW'a eklenir (10.10).
// K24: ui/transfer.js TransferPanel(ctx): 'transfer' modal bağlamı, iki sütun (heybe ↔ kap), hızlı düğmeler (d2/economy.md §5.2); açıkken saat durur.

ui.fade   = { to(alpha, seconds, ease) /* → Promise */, alpha /* yazılabilir, anlık */, busy, update(dt) /* App.updateFade: kare saati */ };
ui.loader = { show({ titleKey /* anahtar ya da {tr,en}; yoksa yalnız çizgi */, labelKey }), set(labelKey, p), hide(ms) };
ui.toast  = { show(text, { kind: 'info'|'save'|'warn' }), clear() };   // menu-spec.md
ui.confirm= { ask(text, { yes, no }), cancel(), open };                // → Promise<boolean>; Hayır odaklı
ui.subtitle = { show(who, text, seconds, { small, voiced }), clear() };   // a11y.subtitles kapalıyken yalnız voiced satır gizlenir
ui.savePanel = { show({ mode: 'load'|'save', inGame, thumb }) /* → Promise<{ mode, slot, info | record } | null> */, cancel(), open };   // Faz 3
ui.card   = { show(key) };                                    // Eksen ve kural kartı; bir kez, modal değil; `card` etkisi. Faz 10
```

Dokunmatik düğmeler `input.virtualDown('sprint')`, `input.virtualTap('jump')`; istem `virtualDown` ve `virtualUp('use')` (`holdK` için), klavye tıklaması `virtualTap('use')`. Harita düğmesi ve Gök Kavisi (`virtualTap('wait')`: Bekle tekeri) `virtualTap`'tir: üstteki bağlam okur, modal altında ölüdür. Dokunmatikte `virtualTap('crouch')` ve `virtualTap('quick')` düğmeleri de vardır; silah düğmesi yalnız `freeroam` kipinde: `play`'de `Q` başka iştir. HUD `Karakter` düğmesi ve oluşturucu kısayolu kalktı (2.6), `C` çömelmedir. Levhadaki adı ve `stats.hp`, `hpMax`'ı kipin sahibi yazar (`hud.vitals.setName`): Çocuğun adı yoktur, `hpMax` 0 Can göstergesini gizler. Menü bileşenleri ölçüleri `menu-spec.md` §0–§4: `k`, `S`, KnotButton, OrnateFrame birebir.

**Menü kabuğu (Faz 3).**

- **Ana menü (`ui/menu/main-menu.js`).** `new MainMenu(root, ctx, { onAction, quit })`; `playIntro(entries)`, `show({ intro, entries, animate })`, `hide(s)` → Promise, `close()`, `update(dt)`, `refresh(entries)`, `onKey(e)`, `asking`. Seçim olay olarak yayılır: `menu:new`, `menu:continue` `{ slot }`, `menu:load`, `menu:book`, `menu:settings`, `menu:free`. Tek yol olaylardır: `states/menu.js` `onAction` vermez, menü kendi `menu` bağlamını açar; kitap ya da panel üste gelince sütun ve Serbest Gez gizlenir, kapanınca kaynak düğme sessizce odak alır. Kayıt varken YENİ OYUN onayını menü sorar, `menu:new` ancak Evet'ten sonra gelir. DEVAM ET ve YÜKLE `save.latest()` ile açılır: Serbest Gez kaydı yuva değildir (`journeyState(save).any` ile aynı). YENİ OYUN `states.newgame` yoksa kapalı.
- **Kitap (`ui/menu/book.js`).** `sharedBook(ctx)` tek örnek; `book.open({ mode: 'title'|'book'|'game', page, flags, journey, can: { save, load, menu }, onAction, onClose })` → Promise (kapanınca çözülür), `close()`, `notice(text)`, `turn(dir)`, `show(id)`. Sayfa `registerPage({ id, tab, glyph, hint, modes: { kip: sıra }, create(book) })`, ayar satırı `registerSettingRow(sectionId, row, index)` ile eklenir: Heybe, Görevler, Defter, Beceriler (`pack`, `tasks`, `ledger`, `skills`) sonraki fazlarda buradan gelir. Kapanışta `settings.save()`. `flags` verilmezse `tanhu.roam.flags` okunur.
- **Kayıt paneli (`ui/menu/save-panel.js`).** `ui.savePanel`'i App bir kez kurar; `save:failed` bildirimlerini ve `__tanhu.save` panelini (`write, load, dump, corrupt, usage, list, remove, open, close`) bağlar. Dışa aktarımlar `journeyState(save)` → `{ any, latest }`, `slotTitle`, `slotSub`, `slotMeta`, `cardView`, `failText`. Yükleme `{ slot, record }` döndürür, `save.apply` çağıranın `prepare`'indedir. Kaydetme paneli yalnız `play`'de açılır; Serbest Gez'de KAYDET `tanhu.roam` yazar ve «Serbest Gez kaydedildi» der.
- **Destan (`data/destan.js`, saf).** `ROAM_FLAGS`, `RoamTracker(flags).update(x, z, roomKind)` → ilk kez yazılan bayrak ya da `null`, `placeAt(x, z, roomKind)`, `VERSES`, `PEOPLE`, `STONES`, `CHAPTERS`, `isOpen`, `openEntries`, `chapterCount`. `freeroam.beginSession` izleyiciyi `tanhu.roam.flags`'ten kurar, her kare `game.pos` ve `game.room?.kind` ile günceller, `saveRoam` yazar.
- **Söz ve dil (`ui/menu/epigraph.js`, `ui/menu/language.js`).** `new Epigraph(root, ctx, { onWait })`: `start({ pump })`, `update(dt)`, `setReady(ready)`, `press(gesture)`, `dispose()`, `phase`, `done`; süreler 1,6 / 4,2 / 1,2 sn. `new LanguagePicker(root, ctx, { onChoose })`: `open()` → Promise<'tr'|'en'>, `dispose()`. Dil seçimi `settings.set('lang')` ve `settings.save()` (`states/language.js`).
- **Işık düğmesi kalktı (K20).** Geliştirme ışık düğmesi (`moodBtn`, `setDusk`, `DUSK_ABOVE`) ve `T`'nin ışık işi kalktı; yerinde Gök Kavisi vardır, `T` her pakette Bekle'dir; geliştirmede ışık `__tanhu.clock` panelinden sürülür (§8 karar 40).

**Menü kamerası (`app/menu-camera.js`).** Taban poz canlı kampın bugünkü oyun kadrajıdır: hedef `Game.targetPoint` eski başlangıç konumu (1.75, 0, 2.35) ile, yani ≈(1.21, 0.6, −3.75); kamera hedef + (0, sin 28°·33, cos 28°·33) ≈ (1.21, 16.09, 25.39); FOV 38 (en-boy <1,3 ise 46), near 2, far 4200. `MENU_FOCUS` = (1.75, 0, 2.35): gölge kutusu bugünküyle aynı kalır. Sürüklenme ve paralaks `menu-spec.md` §7. `menu-spec.md`'nin Tanhu 3 pozu bizim yerleşime uymaz, kullanılmaz (§8 karar 5). `U.uPlayer` menüde (0, −100, 0): çim itilmez.

### 3.21 Son işleme profilleri (`core/post-profiles.js`, `core/post.js`)

```js
POST_PROFILES = {
  freeroam: POST_DEFAULTS,  menu: POST_DEFAULTS,                    // exposure kareye world.mood'dan: game.applyPost
  creator: CREATOR_POST,  closeup: { ...CREATOR_POST, cloudShadow: 0.34 },   // main.js:25-30
  wide:   { ...POST_DEFAULTS, tilt: [0.5, 0.5, 0] },
  winter: { ...POST_DEFAULTS, cloudShadow: 0.34 },
  blizzard: { saturation: 0.72, tone: [0.98, 0.98, 1.03], vignette: 0.42 },    // act1.md §10
  erlik:    { saturation: 0.6, brightness: 0.88, tone: [1.05, 0.86, 0.88], vignette: 0.6 },   // act1.md §8.5
};
post.applyProfile(name, { blend = 0 });  // blend sn; blizzard ve erlik kısmîdir, o anki değerin üstüne yazar
post.update(dt);                         // karışım: tick'te durum update'inden önce (§2.5)
post.setQuality({ msaa: 4 | 2 | 0, bloomLevels: 5 | 4 });   // 5.7; hedefleri yalnız sonraki setSize'da kurar
POST_QUALITY = { auto: { msaa: 4, bloomLevels: 5 }, low: { msaa: 2, bloomLevels: 4 } };
```

`App.resize` `setSize`'dan önce `post.setQuality(POST_QUALITY[app.low ? 'low' : 'auto'])` çağırır: `video.quality` low ve `?q=low` oyuncunun seçimidir, her sahnede MSAA 2 ve 4 bloom kademesi verir (2 örnek, 13 post çizimi); auto'ya dönüş `menuDiff` 0. Otomatik kesinti (§7 sıra 1, 2, 3, 10) yine yalnız `spec.postCuts` (Kışlak, 12.1); menü bitişiğinde render hedefi kendiliğinden değişmez.

`cloudShadow` `U.uCloudInfo.value.z`'ye yazılır (`main.js:108`): `creator` 0, diğerleri 0,34. `tone`, `brightness` `FINAL` gölgelendiricisine eklenir, varsayılanı nötrdür: `menuDiff` etkilenmez.

**Hava katmanı (K22, 9.4).** `post.weather = { sat, con, tone: [r, g, b], bright, precip: vec4, precipDir: vec4, precipOff: [vec3 ×3], precipCol }`; `render` FINAL uniform'larına profil × katman yazar (`uSat = s.saturation × w.sat` …), birikmez. Kimlik: çarpanlar 1, `precip` 0. FINAL'e ekran yağışı dalı girer (`world/weather-hooks.js` `PRECIP_FINAL`, `weather.md` §9.3): tilt bulanıklığından sonra, doygunluktan önce; `uPrecip` toplamı 0 iken çalışmaz, menü karesi değişmez. Katman kaymaları CPU'da 256 hücre periyoduyla sarılır. Kadraj dışındaki kuzey yıldırımının ayağı aynı dalda `uBoltEdge` ile çizilir (0 çizim, 0 program). `U.uCloudInfo.z` Serbest Gez ve oyunda her kare `post.settings.cloudShadow × shadowK` olarak `WeatherView` tarafından yazılır; menüde profilin değeri aynen kalır. Kara Boran'ın derecesi hikâyenin `applyProfile('blizzard')` çağrısıdır, hava katmanı orada nötrdür.

### 3.22 Yardımcı oyun servisleri

Görev ve etki katmanının çağırdığı küçük yüzler. Kurallar alan belgelerinde.

```js
// game/calendar.js (saf): K20; sözleşme §3.23 (İş Puanı, dilim, addWork, setSlice, eatDinner, moodIndex kalktı)
// game/regions.js: GameSystem, act1.md §2 rütbe ve Kızıl Kazık
export class Regions {
  rank;  setRank(n);  open(id);  isOpen(id);  regionAt(x, z);  onLookout(id);
  update(dt);                 // sayaç 40 sn, çömelikte 120 sn; stake:warn, stake:caught
  toJSON();  fromJSON(o);
}
// game/jobs.js (saf): İş Tahtası
export class Jobs {
  list();  count(jobId);      // bugünkü sayım
  deliver(item, n, to);       // → { ledger, trust, xp }; hikâye günü başına 3 iş (şafaktan şafağa, K20)
}
// game/supply.js (saf): SupplyLedger (soyut Kış Hesabı ve K24 ambar kipi), LEDGERS (ctx.supply), ledger(id), armyShare, rolloverYears: sözleşme §3.26
// game/needs.js (saf)
export class Needs {
  fullness;  eat(itemId);  update(dtMin, { sleep = false, rest = false });  band(need);  toJSON();  fromJSON(o);   // oyun dakikası: uyanık −5/sa × diff.foodK, uykuda ×0,25, ateş başında ×0,5; Serbest Gez'de Tokluk yok (d2/core.md §5.7)
  // Umay Eşiği burada değil: yalnız Can bitince, PlayerSystem.fall (progression.md §8.5)
}
// game/mounts.js
export class Mounts { active;  spare;  bond(id = 'offering_stallion');  addBond(n, src);  setActive(id);  gear(id);  toJSON();  fromJSON(o); }
// game/player.js: GameSystem, ctx.player
export class PlayerSystem { wound(reason);  fall(reason);  rest();  bellNoise();  equipChanged();  attack(kind); }
// game/campfire.js, game/cooking.js: survival.md §6
campfire.place(x, z, { stones });  campfire.feed(id, fuelS);  campfire.nearest(x, z, r);  campfire.rest(id);   // rest: ClockSystem'in Dinlen tekeri (§3.23)
campfire.onSkip(minutes);   // K20: yakıt dakika × 2,5 sn yer; biten ateş cold_pit, ertesi şafakta kalkar. K22: yakıt, sönme ve yakma fx.fireK, fireOutS, fireRing (weather.md §8.5)
cooking.recipesAt(station, inventory);  cooking.start(id, recipeId);
```

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
  update(dt);                       // GameSystem 'calendar' (20, play): vakit durumu (wait → open → held → done) ve dawn_line koşulu, 4 Hz; çağrıyı (worldClock.summon) ve latest'teki 3 sn karartmayla götürmeyi ClockSystem yapar
  toJSON();  fromJSON(o);           // world.calendar (order 70)
}
StoryDay = { n, mainWork: ['mq_herd_school'], beats: [{ id: 'b_herd', quest: 'mq_herd_school', earliest: '08:00', latest: '12:00' }],
             sleep: { beds: ['hostage_bed'], from: 'dusk' } | false, cuts: [] };   // veri src/story/act1/days.js (11.1)

// game/clock-system.js: GameSystem { id: 'clock', order: 15, modes: ['freeroam', 'play', 'home'] }
export class ClockSystem {
  attach(ctx);                     // ctx.worldClock, ctx.calendar (play); worldClock.moonAge ← calendar; panel 'clock' yalnız geliştirmede
  onWorld(world);                  // spec.light ve spec.moods.cycle → DayInfo ve anahtarlar; Kışlak'ta gün takvimden, ana kampta iğneli
  update(dt, t);                   // durma yoksa worldClock.advance(ctx.app.wallDt × timeScale); 4 Hz world.setTimeOfDay(sample) (bekleme akışında her kare); Calendar'ın açtığı vakti çağırır (worldClock.summon), latest'te 3 sn karartmayla götürür (time.md §12.5);
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
// (K50 ve K83 ile değişti: 23:00'e dek ateş başı; 23:00'te aşama ≥4 ise until: 'smoke', ilk dumana dek; 05:00'te duman yoksa Ana'nın közü. structures.md §11.6)
```

| Kip | Saat | Not |
|---|---|---|
| `freeroam`, `play` | ×1 × `timeScale`; Yol Akışı ×`k` | Kırpılmamış duvar süresi, kare başına ≤0,25 sn (§2.5) |
| Bloklayan diyalog, sinema (`run` izi yoksa), seviye, Terazi, Yol Kartı, aktarma paneli, Bekle tekeri, Donuk Kamp | 0 | `pause(reason)` |
| `map`, `pause`, gizli sekme, `freeze` | 0 | `game.update` çalışmaz; `freeze`'de `app.frozen` denetimi |
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
  zoneAt(zone, hourAbs, out);      // → out { type, sev, deepSnow, crust, cartLock, cartK, galeDamage, hail }: yüklü zonda fx'in aynısı; yüklü olmayan yerleşim ve ordugâh zonunda (tanhu_ordu, whistle_field) sabit çapalı Planner ve WetState; packs[zone] her clock:hour'da, atlamada analitik ilerler
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
weather.audio = { beds: [{ id, gain, at?, lp? }], windK, windSwap, quiet, inside };   // veri; listeyi sounds.js (L) kurar (§3.6)

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

**Yıldırım.** Hedef `world.tallThings`'ten seçilir: Çocuk 25 m içinde hedef olmaz; kurulan yapı hedef olmaz; vurulan yapı 1 oyun günü bekler; yerleşimde fırtına başına ≤1 yapı; Mete Normal ve Zor'da yalnız skoru en büyükse vurulur (Can −%35, taban 1, Yara yok), Hikâye'de hiç; hedef oyuncunun 40 m içindeyse düşüşten 1,5 sn önce `static_hum` ve halka; ıslak keçe tutuşmaz. Ana kampın fırtınasında %60 olasılıkla Çocuktan 30–70 m kuzeyde, kadrajda bir ağaca ya da direğe tasarlanmış düşüş (kamp yapılarına inmez); kadraj dışı kuzey düşüşü ekranın üst kenarında FINAL katmanında görünür.

**Kar örtüsü ve Kar Kabuğu.** Zon durumu `snowpack` (0..1, saatte bir), `deepSnow` (06:00'da ≥0,6) ve `crust` (Kar Kabuğu / Snow Crust, 5–10 gün; derin kar, ardından sulu kar ya da açık öğle, ardından açık gece) sıcaklıksız, havanın sırasından okunur (`d2/core.md` §3.6); paylar `d2/weather-model.json`'dadır.

**Belirlenim ve kayıt.** Zon zinciri sabit çapadan kurulur (`floor(hourAbs / 24) × 24 − 24`'te `clear`, ileri sarılır); bölüm tohumu `(journeySeed, zone, floor(t0 × 4))`; alt olay zamanı hava saati saniyesidir `(hourAbs − t0) × 150` ve saatle durur; varış lütfu zinciri değiştirmez. `world.weather` (78, ≤1 KB): `{ v, seed, zone, climate, season, at, plan: [≤10], wet: [ground, felt, mud, puddle, snow, bow], packs: { [zone]: { snowpack, crust } }, locks, struck: { 'zone:siteId': hourAbs }, said: [≤16] }` (`packs`: yüklü zon ve yüklü olmayan yerleşim ve ordugâh zonları); Serbest Gez `roam.weather` aynı biçimdedir.

**Menü kimliği.** `app:state` → `menu`, `newgame`, `creator`, `home`: hava 1,7 sn'de kimliğe karışır, sonunda değerler tam yazılır; menü listesi havasızdır; `drawMenuFrame` hava durumunu saklar, `identity(0)` çağırır, sonra geri yükler (§6.3). Panel `__tanhu.weather`: `state, set, clear, plan, seed, skip, wind, wet, freeze, calm, flash, thunder, hail, strike, fx, sim, calibrate, budget, identity`.

### 3.25 Emek yasası ve şantiye (K21; `game/labour.js`, `game/site-core.js` saf; `game/sites.js`, `game/builders.js`)

Kurallar ve sayılar `d2/core.md` §2 ve `structures.md` §2.4–§2.5, adım tabloları `structures.md`. **Birim:** İD (iş dakikası) bir işçinin bir oyun dakikalık emeğidir; 60 İD = 1 İS; 1.440 İD = 1 İG = tek işçiyle 60 gerçek dk. **Ekip:** `eff(W) = min(W, 10 · (1 − 0,9^W))`, `W` adımın el sınırına dek en ağır üyelerin ağırlık toplamıdır (usta ve el 1, çırak 0,75, yaşlı 0,5 (kendi zanaatında önder), Çocuk 0,5; adlı büyük usta ≤1,25). Standart (parça biçimli) yurt tek elle 1.440 İD, ekiple 1.376 İD; tek el yöntemi yalnız tündüktedir (bakanla ×1,6). Yurt süresi el sayısıyla: 1 → 60,0, 2 → 30,6, 3 → 21,7, 4 → 17,3, 5 → 14,7, 6 → 13,0, 7 → 11,9, 8 → 11,2 gerçek dk; el arttıkça süre hep kısalır. (K50 ile değişti: `d2/core.md` §2 ve `structures.md` §2.4'te inşaat, söküm ve onarım artık `T(n) = taban × 0,75^(min(n, 8) − 1)` ile işler, Hane Yurdu 60 / 45 / 33,75 … 8 el 8,0 dk; adım el sınırı ve tündüğün ×1,6'sı kalktı, tezgâh `eff` ile kalır. Bu sözleşme prototipin K21 biçimidir; K29 gereği yeni eğri prototipe ve fikstüre girmez.)

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
  waitReason(env);                 // öncelik sırasıyla tek neden: 'fire' | 'threat' | 'storm' | 'weather' | 'material' | 'master' | 'far' | 'crew' | 'dark' | 'rest' | 'story' | null
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
  onSkip(fromMin, toMin);          // clock:skip: yalnız spec.settlement taşımayan zonda labour.simulate; reason 'chronicle' atlanır (Kronik işler, §3.27)
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

**Kayıt.** `world.sites` (76): `{ v: 1, zones: { [zone]: { lastMin, sites: { [id]: tam kayıt | ['yurt', x, z, rot, 'done'] } } } }`; şantiye ≤3 KB, bütün zonlarda ≤20 KB; Kışlak Yeni Yurdu `world.sites.zones.hexi_winter.sites.new_yurt`'tür. Serbest Gez camp3 `v: 2` (`structures.md` §11.8). Panel `__tanhu.labour`: `eff, rate, eta, crew, simulate, weather, night, sandbox`.

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
export const LEDGERS;              // ctx.supply: { get(id), register(ledger), bind(bus, { diff }) }; bind: her 'dawn'da (skipping dahil) soyut defterlere onDawn(diff.ledgerLoss); clock:skip { long: true }'da × dawns
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
| Silahlık | 200 | `gear`, `arrow`, `metal` | `settlement` (77; `StorePool`, yer ordugâh `own_camp`) |
| Erzak Ambarı (ordugâh) | 600 | Hepsi | `camps` (92) |
| Şantiye yığını | Yapının malzeme yükü × 1,25 | O yapının malzemesi | `world.sites` (76) |

Bir yerin kapları yerleşimin `StorePool`'unda tek **Ambar / Store** görünümünde birleşir. Kervan ve Mete'nin heybesi dışında yerler arası taşıma yoktur. Bozulma: çiğ et ve balık edinildiği günden sonraki ikinci şafakta `spoiled` (24–48 sa), kış dünyasında balık donuktur (`spec.perish`).

**İki hız.** Mete toplamada ve el işinde gerçek saniyeyle (odun 6, taş 10, cevher 15 sn; tutuş ≤8 sn) çalışır, NPC İS ile (kütük 2,5, ot 1,5, cevher 5 İS); tezgâh ve usta işi herkes için İS'tir. Zanaat ve inşa tek emek havuzundan ödenir.

**Sürücüler.**

| Sürücü | Ne zaman | Servis |
|---|---|---|
| `Inventory` (8.2) | `dawn` (`skipping` dahil); `clock:skip { long: true }`'da bir kez (yeni günle; gün anahtarı ikinci şafağı geçeni bozar) | Kişisel kapların `onDawn`'ı |
| `barter.js` (8.4) | `dawn`; `clock:skip { long: true }`'da bir kez | Satıcı stoğu |
| `LEDGERS.bind` (8.4) | `dawn` (`skipping` dahil, şafak başına bir); `clock:skip` yalnız `long` ise × `dawns` | Soyut defterlerin şafak kaybı |
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
export const SOURCES;     // hane kaynakları ve perde dalgaları: hh_story, hh_saved, oba_wave, court_move, choose, refugees, gift, loufan_baiyang, defectors, heqin, court_gathering, kurultay, pull (Çekim); Kış Toplantısı (muster_winter) kaynak değildir, Kronik işler (K25)
export const PLACEMENT;   // parseller ve yer kuralları: validatePlacement'in rules girdisi (settlement.md §13)
export const CAMP_TIERS;  // { id, riders, tents, lines, builds }
export const RAIDS;       // perde başına akın gücü R (yerleşim / ordugâh), ay penceresi ve yerleşime tavan (K55 ile değişti: eski «III 8 günde 1, IV 14, V 12» sıklığı kalktı; settlement.md §15.4)

// game/settlement/state.js (saf)
export class SettlementState {
  constructor({ data, econ /* K24 tabloları */, labour /* game/labour.js */, rng });
  zone; tier; path; households; work; pull; lastMin; stores /* StorePool */; herds /* { [place]: { sheep, goat, horse, cattle, camel } } */; taken;
  hour(env);  dawn(env);  seasonEnd(env);          // env: { minute, phase, season, weather, act, kut, korku, threat, present }; weather = ctx.weather.zoneAt(zone, hourAbs) (CampState ve CaravanBook da)
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

**Saat sırası.** `clock:hour`: (1) `SettlementState.hour` (Kâhya ekipleri yazar), (2) K21 `sites` şantiyenin o saatini işler (yüklü dünyada zaten kare kare işledi), (3) `production.hour`, (4) `CampState.hour`, (5) `CaravanBook.hour`. `dawn`: `production.dawn`, sonra `SettlementState.dawn` (Çekim, katılım, ayrılış, Gönül, kademe). `clock:skip`: aynı sıra, ≤3 gün saat saat, uzunu günlük adım; `reason: 'chronicle'` atlamasını yerleşim ve `sites.onSkip` işlemez: o aralığı `act:change`'te Kronik `rolloverYears` ile kapalı işler ve `lastMin`'i perde başına yazar; tarihi `journey` (10.8) atlatır. `act:change`: Kronik: tarih perde başına atlar (`clock:skip { reason: 'chronicle', long: true }`), aradaki yıllar `rolloverYears` ile kapalı işlenir, hane perdenin açılış tabanına çıkar (düşmez), kış stoğu ambar kapasitesiyle sınırlı K24 hedefine dek, yoldaki kervan varmış, şantiye emeği yetiyorsa bitmiş sayılır; perde kartı: «{y} yıl geçti. {h} hane, {s} baş sürü; ambar kışa {p}.» / «{y} years have passed. {h} households, {s} head of stock; the stores stand at {p} for winter.»

**Ordu Payı ve kış.** Ordu Payı yerleşik atlının düz %10'udur (1 / 10 / 20 / 40 / 60 öğün/gün; Göçer ×1,1 = 66); yalnız kuru erzak (Aş, darı, kak, kurut, tahıl) kervanla gider. Kışın ordugâh dağılır: yerleşik atlının %90'ı hanesinin kışlağına çekilir, %10'luk kış bekçisi at hattında ordugâhın güzde biçtiği otu yer (at başına günde 1 Yem Bağı = 2 Yük).

**Baskın, tek kural.** `D = nöbetçi × (1 + 0,5 × kule) + garnizon`; başarı `R / (R + D) × (Surlu ? 0,5 : 1)`; başarılı akında Ambar Yurdu, Tahıl Ambarı, Sundurma %30, Tahıl Kulesi %10, Hazine %30 (30 m içinde Gözcü Kulesi ×0,5), Ambar Çukuru %50 olasılıkla bulunur ve bulunursa %30 (yalnız yiyecek ve tahıl), ot sundurması tutuşursa hepsi; sürü kaybı ≤%10 (Göçer ×0,6). Mete zondaysa baskın oynanır (`raid.js`), değilse toplu çözülür.

**Görünür bütçe.** Zon başına ≤160 yapı kaydı (çizgi yapılar çoklu çizgi ve parça sayısıyla tek kayıt), aynı anda ≤48 canlı `StagedStructure`, ≤4 tam yurt 40 m içinde, gerisi `YurtField` ve `KitField`; görünür işçi `NpcManager.budget`'ını paylaşır. Panel `__tanhu.hold`: `give, households, tier, speed (×1–×240), hour, place, assign, steward, raid, weather, caravan, census, budget, plots, synth(tier, path)`.

## 4. `src/story` veri biçimleri

Hikâye verisi düz JS modülüdür: JSON değil, çünkü `tools/voices.mjs` ve `node:test` doğrudan içe aktarır, yorum taşır. Saf modül kuralına tabidir. Her dosya `export default [...]`. `src/story/schema.js` biçimi doğrular, `tools/check-data.mjs` hepsini gezer.

```
src/story/act1/day1/index.js      export default { quests, dialogue, cine }
src/story/act1/index.js           (L) bütün gün dizinlerini birleştirir: { quests, dialogue, cine, schedule, guards, regions, jobs }
```

### 4.1 Görev

```js
QuestDef = {
  id,                       // 'mq_*' | 'sq_*' | 'job_*' act1.md §6–§7 kimlikleri
  kind,                     // 'main' | 'side' | 'scene'
  act,
  name: { tr, en },  summary: { tr, en },
  start: { when: 'koşul', auto: true },     // auto false: { by: 'npc:hereka' } gibi bir konuşmayla başlar
  spots: [ { id, x, z, reach = 2.1, label: { tr, en }, hold = 0, when = null } ],  // geçici Interaction, priority 100
  steps: [ {
    id, text: { tr, en }, marker: [x, z] | null,
    goal,                   // aşağıda
    onStart: [...], onDone: [...],          // etki listesi §3.14
    camera: 'crown' | null,                 // varsa game.cam.push(CAM[...])
    music: 'tension' | null,
  } ],
  onDone: [...], onFail: [...],
  failWhen: 'koşul' | null,
};
```

| `goal.type` | Parametre | Biter |
|---|---|---|
| `reach` | `at: [x, z], r` | 0,25 sn'lik denetim |
| `flag` | `when: 'koşul'` | `flag:set`, `axis:change`, `item:*`, `quest:*` sonrası yeniden değerlendirme |
| `talk` | `dialogue: id, npc: id?` | `dialogue:end` |
| `interact` | `target: 'spot:x' \| 'node:<kind>' \| 'station:<id>', n = 1` | `interact:done` |
| `have` | `item: ref, n` | `item:add` |
| `deliver` | `item: ref, n, to: 'stores'\|'kitchen'\|'stable'` | `job:done` ya da `ledger:change` |
| `stage` | `structure: id, gte: n` | `structure:stage` |
| `kill` | `kind: 'wolf', n` | `dmg:killed` |
| `event` | `name: 'bus adı', where: { alan: değer }` | Eşleşen olay |
| `timer` | `s` | Süre |
| `all`, `any` | `of: [goal]` | Bileşik |

**Kural (`act1.md` §15).** Tek seferlik etki `give` + `once` kullanır: eşya ve bayrak birlikte denetlenir, yeniden yüklemede çift verilmez. Bir adım koşulu zaten sağlanıyorsa aynı karede geçilir, oyuncu takılmaz. Dallanan yankı bayrakla yazılır, görev kopyalanmaz.

### 4.2 Diyalog

```js
DialogueDef = {
  id, mode: 'scene' | 'walk' | 'flow',
  start: 'düğüm',
  nodes: {
    <düğüm>: {
      who: 'konuşmacı',            // cast.js kimliği
      line: { tr, en, vo: false, voText: null, small: false },  // vo:true ise ses dosyası; voText eleven_v3 ses etiketli metin ([whispers]); small: gerçek söylenen küçük altyazı
      look: 'player' | [x, y, z] | null,  gesture: 'nod' | null,
      fx: [...],                   // satır başında
      next: 'düğüm' | null,        // null: bitti
      end: 'sonuç' | null,         // start() Promise sonucu
    },
    <düğüm>: { choices: [ { id, when: 'koşul' | null, text: { tr, en }, fx: [...], next } ] },   // when false: gizli
    <düğüm>: { branch: [ { when: 'koşul', next } ], else: 'düğüm' },
  },
};
```

Ses satırı kimliği her zaman `<diyalog id>.<düğüm>`: `a1_dlg.sentence.amaga_1`. Satır en çok iki cümle (`act1.md` §3 söz kuralı); `check-data` üç cümleyi uyarır.

### 4.3 Sinema

```js
CineDef = {
  id, skippable: true, skipHold: 0.6, end: { goTo: 'creator' } | null,
  voice:  [ { id: 'song', t: 5, line: 'act0.bard.song', who: 'bard', at: [3.12, 1, -1.3], dur: 24.615, subs: songSubs(), mouth: songTrack() },
            { id: 'n1', after: 'song_end+0.6', line: 'act0.narr.1' } ],   // act0.bard.song (şarkı), act0.narr.1–7
  camera: [ { t: 0, from: 'current' }, { t: 3.5, pos: [...], look: [...], fov: 32 }, { t: 'bard_end+0.5', hold: true }, ... ],
  post:   [ { t: 0, profile: 'closeup', blend: 2 }, { t: 'bard_end+1', profile: 'wide', blend: 8 } ],
  fog:    [ { t: 'bard_end+1', near: 140, far: 3000, blend: 8 } ],
  music:  [ { t: 0, state: 'camp_bard' }, { t: 'bard_end', state: 'crane' }, { t: 'crane_end', state: 'narration' } ],
  shadow: [ { t: 0, at: [3, -1] }, { t: 'bard_end+4', at: [0, 0] } ],
  actors: [ { t: 3.5, id: 'bard', strum: 1, mouth: 'sing' }, { t: 'bard_end', id: 'bard', strum: 0.4, mouth: 'rest' } ],
  clock:   [ { t: 0, set: '10:40' } ],   // K20, isteğe bağlı: set 'hh:mm' | atLeast: 'civilDawn-30' | advance: dk | run: true (time.md §6.4); yalnız ileri
  weather: [ { t: 0, weather: { do: 'lock', id: 'cine_x', type: 'thunderstorm', blend: 3 } } ],   // K22, isteğe bağlı; release() kilidi kaldırır

  subtitles: 'voice',           // voice bloğundan üretilir
  fx: [ { t: 'end', list: [ [...] ] } ],
};
```

`t` sayı ya da `'<id>_end±s'`, `'<id>+s'`. `play` önce `voice.preload` çağırır, süreler kesinleşince zaman çizelgesi kurulur; ses dosyası yoksa satırın `dur`'u, o da yoksa `speechSeconds`.

**Şarkı satırı (K19, karar 32).** Konuşma olmayan dosya (`vo-lines.js` `SONGS`) bir ses satırıdır: `who` söyleyeni (oyuncu bağı), `dur` dosyasız boyu verir. `subs: [{ at, line, end? }]`: altyazı satırın kendisi değil, dosyanın içindeki saniyede açılan dize satırlarıdır (sonrakinin başında ya da `end`'de kapanır; `seek` doğrusunu yeniden gösterir). `mouth`: `npc.js` `mouthTrack` biçiminde hazır ağız çizelgesi (`bard-song.js` `songTrack`, notalardan); verilince `perform` zarfsız çağrılır, dosyadaki dombra ağzı açıp kapatmaz. Manifest satırı `{ hash, speaker, seconds, song: true }`; `voice.duration` dosya çözülmeden `seconds`'ı döndürür.

**Yeni Oyun kamerası (denetim §b; Faz 5'te render edildi, `docs/research/newgame-shots/`).** K19: menüden 3,8 sn'de yüz yakın planına, pos (2.02, 1.07, −0.71), bakış (3.12, 0.97, −1.3), FOV 30 (yüze 1,2 m); bekleyişte 1,15 m'ye sokulur, ozan dombrayı kaldırır. 5. sn'de şarkının ilk dombra vuruşuyla (`pull`) geri çekilme kalkar ve şarkı boyunca sürer: 6 sn'de ozan ve dombra (1.15, 1.12, −0.25), 11 sn'de ateşin kuzeyinden (0.7, 2, 1.9), sonra koridor. Geri çekilme `layout.js:16` koridorundan: (3.6, 3.4, 4.8) → (7.8, 12.4, 15.6) → (9.2, 14, 26) → (10.4, 17, 40). İlk hesabın yükseklikleri (2,2 / 4 / 7 / 12 m) yakın ormanın (6, 16.7), (8.1, 20.5), (9.7, 26.9) ağaçlarının tacından geçiyordu (tepe 7,7–8,7 m, gerçek `buildForest` tohumuyla); yeni yol taç ve zeminden ≥1,6 m uzaktır (ölçülen ağaç payı 2,88 m). Geri çekilmeden sonraki her kamera anahtarı bir anlatıcı satırının sonuna bağlıdır (`cine-newgame.js`): satır süresi 1,6–12 sn arasında değişse de sıra bozulmaz. Son: pos (−60, 30, 190), FOV 38, near 1, sis [140, 3000]. **Bakış (0, 46, 0) değil (−32, 46, 0):** 16:9'da sağ kenar ≈17,5° + 31,5° = 49°, uzak arazi köşesi 39,7°; yönü 8,5°'ye çekince kenar köşenin içinde kalır, kamp kadrajda 9° sağda durur. Menü değişmeyeceği için `terrain.js` `X` büyütülmez. Dar ekranda yatay FOV kilitlenir. Ağaç payı ≥1,5 m ölçülür: `__tanhu.cine.clearance()`.

### 4.4 Ses satırı kaynağı

```js
// src/story/cast.js
CAST.uldin = { name: { tr: 'Uldın', en: 'Uldin' }, portrait: 'uldin', voice: null, settings: null, chain: null };
CAST.narrator = { name: { tr: 'Anlatıcı', en: 'Narrator' }, portrait: null, voice: 'LvmvHEBEmMJBJw9UuhwO', settings: { stability: 0.5, similarity_boost: 0.8 }, chain: null };   // Eldrin (K17); ozan David 'BNgbHR0DNeZixGQVzloa' (K19)
// voice_id tablosu audio.md §5. Mene ses almaz.

// src/story/vo-lines.js: Node'da da açılır
export function voLines();   // → [{ id, speaker, voice, model: 'eleven_v3', provider: 'elevenlabs', settings, text }]
// text = line.voText ?? line.en. Bütün act0 ve act1 içinde vo:true satırlar. Bilinmeyen konuşmacı throw.
export function voBudget();  // → { chars, byAct }; check-data: Act 0 + Act 1 ≤45.000 kredi, toplam ≤133.000
```

(K61 ile değişti: `voBudget`'in «Act 0 + Act 1 ≤45.000, toplam ≤133.000» tavanı kalktı; sayaç perde, konuşmacı ve dilim başına raporlar, toplamda düşmez. Prototipte `tools/check-data.mjs`'in `VO_LIMITS`'inin silinmesi prototipin işidir ve yapılmadı; Godot'da sayaç `test_vo_budget.gd`'dir, `audio.md` §5.)

Üretim yalnız `L`: `node tools/voices.mjs cost`, sonra `gen` (ElevenLabs, K28; ozanın şarkısı `node tools/bard-song.mjs`). Anahtar araçta kalır, yazdırılmaz. Değişmeyen satıra kredi harcanmaz (manifest karması). `storyLine(id)` → `{ id, act, speaker, name, tr, en, vo, small, voText }` (altyazı), `textOf(id)` → etiketsiz İngilizce (`audio.voice.textOf`). **Act 0 üretildi (Faz 5):** 9 satır, 856 kredi; `public/audio/vo/en/act0.*.mp3`, `manifest.json`. Süreler: ozan 3,97 ve 4,28 sn; anlatıcı 5,49 / 6,11 / 10,68 / 7,16 / 5,56 / 6,03 / 4,83 sn (toplam 45,9). Sinema 70,9 sn.

### 4.5 Örnek: `mq_ration` ve `dlg_ration_hollow`

`act1.md` §6 satırı: «Kazan çanı; 2 Aş al, esir sepetini Çukur Kapısı'na taşı», `ration_kept`, 80 XP. Uldın ve Hereka'nın ilk satırları `act1.md` §12'den; diğerleri biçim örneğidir, senaryo yazımında değişebilir.

```js
// src/story/act1/day1/quests.js (parça)
{
  id: 'mq_ration', kind: 'main', act: 1,
  name: { tr: 'Tayın', en: 'The Ration' },
  summary: {
    tr: "Kazan çanı çaldı. Payını al, esirlerin sepetini Çukur Kapısı'na taşı.",
    en: "The cauldron bell has rung. Take your share and carry the captives' basket to the Hollow Gate.",
  },
  start: { when: 'quest:mq_count.done && slice:noon', auto: true },
  spots: [
    { id: 'kitchen_ration', x: 20, z: 14, reach: 2.1, label: { tr: 'Tayını al', en: 'Take the ration' } },
  ],
  steps: [
    {
      id: 'bell', marker: [20, 14],
      text: { tr: "Mutfak Kazanı'na git.", en: 'Go to the Kitchen Cauldron.' },
      goal: { type: 'reach', at: [20, 14], r: 4 },
      onDone: [['sfx', 'drum_hit'], ['card', 'card.fullness']],
    },
    {
      id: 'take', marker: [20, 14],
      text: { tr: 'İki Aş ve esir sepetini al.', en: "Take two meals and the captives' basket." },
      goal: { type: 'interact', target: 'spot:kitchen_ration' },
      onDone: [['give', 'meal', 2, 'mq_ration.meal'], ['flag', 'carry_basket', true]],
    },
    {
      id: 'carry', marker: [60, 125],
      text: { tr: "Sepeti Çukur Kapısı'na taşı.", en: 'Carry the basket to the Hollow Gate.' },
      goal: { type: 'reach', at: [60, 125], r: 4 },
    },
    {
      id: 'hollow', marker: [60, 125],
      text: { tr: 'Hereka ve Uldın kapıda bekliyor.', en: 'Hereka and Uldin are waiting at the gate.' },
      goal: { type: 'talk', dialogue: 'dlg_ration_hollow' },
      onDone: [['flag', 'carry_basket', false]],
    },
  ],
  onDone: [['xp', 80, 'main'], ['quest', 'mq_first_tally']],
}
```

```js
// src/story/act1/day1/dialogue.js (parça)
{
  id: 'dlg_ration_hollow', mode: 'scene', start: 'uldin_1',
  nodes: {
    uldin_1: {
      who: 'uldin', look: 'player', next: 'hereka_1',
      line: { tr: 'Baban bizi burada unuttu. Sen keçede uyuyorsun.', en: 'Your father forgot us here. You sleep on felt.' },
    },
    hereka_1: {
      who: 'hereka', gesture: 'nod', next: 'pick',
      line: { tr: 'Sepet sayıldı. Sana iki kase, bize bir.', en: 'The basket is counted. Two bowls for you, one for us.' },
    },
    pick: {
      choices: [
        {
          id: 'share', when: 'item:meal',
          text: { tr: 'Payımdan bir Aş ver.', en: 'Give one meal from my share.' },
          fx: [['take', 'meal', 1], ['ties', 'hereka', 2], ['axis', 'kut', 1, 'mq_ration.share']],
          next: 'hereka_share',
        },
        {
          id: 'keep',
          text: { tr: 'Kaseme dokunma.', en: 'Leave my bowl alone.' },
          fx: [['flag', 'ration_kept', true]],
          next: 'uldin_keep',
        },
      ],
    },
    hereka_share: {
      who: 'hereka', next: null, end: 'share',
      line: { tr: 'Yemin etme. Say.', en: "Don't swear. Count." },
    },
    uldin_keep: {
      who: 'uldin', next: null, end: 'keep',
      line: { tr: 'Doğru. Keçede uyuyanın karnı da sayılır.', en: 'Fine. A belly that sleeps on felt gets counted too.' },
    },
  },
}
```

**Bu örnekte ne olur.**
1. `slice:change` (öğle evresi 10:30) `mq_count` bitmişken koşulu tutturur; Gün I'in gerçek vakti `hour>=12`'dir (öğle çanı, `time.md` §9.2): `quest:start`, HUD ve Görevler «Mutfak Kazanı'na git.» / «Go to the Kitchen Cauldron.» yazar, (20,14) işaretlenir.
2. `spots` geçici `Interaction` üretir; istem «Tayını al» / «Take the ration». `E`: `interact:done`; `give` `once` bayrağı yazar: yükleme sonrası ikinci kez verilmez.
3. Sona gelince `dlg_ration_hollow` `scene` kipinde açılır. `input.push({ id: 'dialogue', modal: true })`: `game` tutamağı `onLost` alır, yol silinir; `stealth` durur. Satırlar `vo:false`: altyazı, `speechSeconds`.
4. `share` seçilirse `axis` `once` anahtarı `axisOnce` listesine girer (`progression.md` §13.2): Kut iki kez sayılmaz, ilk değişimde `card` açılır. `keep` seçilirse `ration_kept`; `act1.md` §8.7 `first_ten` tavanı −2 bu bayrağı okur.
5. Diyalog biter, bağlam kalkar, `onLive`. Görev `onDone`: `xp:gain` 80, `mq_first_tally` başlar.

## 5. Uygulama fazları

**Okuma.** Bir fazın paketleri paralel yürür ve hiçbir dosyayı paylaşmaz. `L` satırı yalnız baş mühendisindir. Paket başka bir paketin bu fazda yazdığı modüle §3 sözleşmesiyle bağlanır; bağlantıyı `L` faz sonunda sınar. Her paket `node --test "test/*.test.js"` (K18) ve `NPM_CONFIG_CACHE="$TMPDIR/npm-cache" npx vite build` geçmeden bitmiş sayılmaz. Bağımlılık:

```
F0 → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → kapı → F11 → F12 → F13
```

F4, F5, F6 mantıken birbirinden bağımsızdır ama `world.js`, `grass.js`, `valley.js`, `nav.js`, `atlas.js` dosyalarını paylaştıkları için sırayla yürür. Denetim sırası eşlemesi: 1–2 → F1; 3 → F2; 4 → F0, F1, F4; 5–6 → F4; 7 → F5; 8–9 → F7; 10 → F5 ve F12.

### Faz 0: Saf çekirdek

Mevcut dosyaya dokunulmaz, hiçbir şey bağlanmaz. Oyun değişmez.

`L`: `package.json` test betiği; `docs/baselines/menu_1600x900.png`, `docs/baselines/menu_counts.json` (§6.3). Bugünkü kod `?play` ile açılır, `step(16.7, 2)`, `__tanhu.hero.root.visible = false`, `U.uTime.value = 100`, `post.fade = 0`, `post.render`, `toDataURL`. İlk alınan görüntü `post.fade` 0,94 ile çoğu siyahtı, sayaçlar son geçişin sayısıydı: ikisi Faz 1'de yeniden yazıldı, görüntü yine eski koddandır.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 0.1 | `src/core/bus.js`, `src/core/store.js`, `src/core/clock.js`, `src/core/settings.js`, `src/core/settings-schema.js`, `test/bus.test.js`, `test/store.test.js`, `test/settings.test.js` | §3.1, §3.4, §3.5 store, §2.5 saat | Bellek arka ucuyla test; `clock.manual` |
| 0.2 | `src/core/input.js`, `src/core/keymap.js`, `test/input.test.js` | §3.2 | 7 davranış maddesi testte |
| 0.3 | `src/i18n/index.js`, `src/i18n/format.js`, `src/i18n/load.js`, `test/i18n.test.js` | §3.3 | Eksik anahtar düşüşü; `upper` İ/I |
| 0.4 | `src/core/timeline.js`, `src/core/ease.js`, `test/timeline.test.js` | §3.19 | `seek` cue sırası, sahte saat |
| 0.5 | `src/game/cond.js`, `src/game/flags.js`, `src/game/effects.js`, `test/cond.test.js`, `test/flags.test.js`, `test/effects.test.js` | §3.14 | Bütün op'lar sahte servisle |
| 0.6 | `src/game/damage.js`, `src/data/damage-tables.js`, `src/data/difficulty.js`, `test/damage.test.js` | §3.9 saf kısım | `progression.md` §17.1 #8, #9, #10, #13 |
| 0.7 | `src/game/save.js`, `test/save.test.js` | §3.5 | `progression.md` §17.1 #21, #22; blok sırası; göç |
| 0.8 | `tools/check-pure.mjs`, `tools/check-i18n.mjs`, `tools/check-data.mjs`, `src/story/schema.js`, `test/schema.test.js` | §4, §6.2 | Boş projede geçer, bozuk örnekle düşer |

**Çıkış:** 8 paketin testleri geçer; `vite build` değişmez.

### Faz 1: Uygulama çatısı ve girdi

Denetim 1, 2 ve 4'ün dokunduğu dosyalar. Sonuç: oyun bugünkü gibi oynanır (`creator` → `freeroam` ⇄ `map`), altı değişmiştir. Hero hâlâ oyuncudur, `actor.js` bağdaştırır.

`L`: `src/main.js`, `src/app/app.js`, `src/app/devtools.js`, `src/app/systems.js`, `src/app/world-swap.js`, `index.html`, `src/ui/style.css` (`css/*.css` JS'ten içe aktarılır; `.loader` burada kalır).

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 1.1 | `src/game/game.js`, `src/game/systems.js`, `src/game/interact.js`, `src/game/camera-rig.js`, `src/game/mounted.js`, `src/character/actor.js`, `src/i18n/strings/game.js`, `test/interact.test.js`, `test/camera-rig.test.js` | §3.7: dinleyiciler kalkar, `InputHandle`, `SystemHost`, `InteractDriver`, kamera yığını; at istemi `MountSystem`; `placeRider` | Tıkla, WASD, at, oda aynı; `Esc` sızmıyor |
| 1.2 | `src/map/atlas.js`, `src/i18n/strings/atlas.js` | Girdi bağlamı `map`, tekerlek canvas'tan, blur; kırıntı kimlikle; atlas dizgeleri | Zeminde tekerlek çalışır; Alt-Tab kaydırma takılmaz |
| 1.3 | `src/ui/hud.js`, `src/ui/hud/vitals.js`, `src/ui/css/hud.css`, `src/i18n/strings/hud.js` | §3.20: yuva, widget, `input.virtual*`, dizgeler | Görünüm aynı; dokunmatik düğmeler çalışır |
| 1.4 | `src/ui/fade.js`, `src/ui/loader.js`, `src/ui/toast.js`, `src/ui/confirm.js`, `src/ui/subtitle.js`, `src/ui/css/tokens.css`, `src/ui/css/shell.css`, `src/i18n/strings/shell.js` | Kabuk; `menu-spec.md` §0 belirteçleri | Tek başına demo |
| 1.5 | `src/core/post.js`, `src/core/post-profiles.js`, `src/core/paint-material.js` | `applyProfile(name, blend)`; `freeroam`, `menu`, `creator`, `closeup`, `wide`, `winter`, `blizzard`, `erlik`; program anahtarına kanca karması | `menuDiff` ≤32 piksel; program sayısı 85 |
| 1.6 | `src/app/states/base.js`, `src/app/states/boot.js`, `src/app/states/freeroam.js`, `src/app/states/map.js`, `src/app/states/creator.js`, `src/app/camera-blend.js`, `src/ui/stage.js` | §2.1, §2.2 ilk dört durum; stage girdisi | `__tanhu.step` gizli sekmede çalışır |
| 1.7 | `src/world/world.js`, `src/world/layout.js`, `src/world/yurt-designs.js`, `src/i18n/strings/world.js` | Adım etiketleri anahtar, `world.js:52` hatası; yapı ve at adları `{tr,en}` | Yükleyici etiketi doğru adımı gösterir |

**Çıkış:** Bugünkü bütün oynanış; `menuDiff` geçer; `renderer.info` 582 çizim, 3,84M üçgen sapmaz.

### Faz 2: Çocuk aktör

Denetim 3. Hero sahneden kalkar; Serbest Gez'de oyuncu Çocuktur (istek 3). `Hero extends Rig` yapılmaz (§8 karar 4).

`L`: `src/main.js`, `src/app/app.js`, `src/app/systems.js`, `src/app/devtools.js`, `src/app/states/creator.js`: Hero ve eski oluşturucu içe aktarımı kalkar (önizleme 5.6'ya dek dinamik, §8 karar 26), `boot` → `freeroam`.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 2.1 | `src/character/rig.js`, `src/character/gestures/index.js`, `src/character/gestures/base.js`, `src/character/gestures/labour.js`, `src/character/gestures/build.js`, `src/character/gestures/combat.js`, `src/character/gestures/story.js` | `registerGesture(name, fn)`, `registerCarry(name, fn)`; `benchK`; `spec.ride` açıları (çocuk uyluk z 1,2, x −0,55, kaval dikten 0,17 rad dışa; dik kaval örtüye 4,9 cm giriyordu); `seatHeight` `d.height`'ı görür | 7 eski jest aynı; at sırtında bacak gövdeye girmez |
| 2.2 | `src/character/folk.js`, `src/character/mete.js`, `src/character/actor.js`, `src/character/looks.js` | §3.7 `GameActor`; sınır küresi; Mete `attach` metre → cm; `CHILD_LOOK` taşınır | `setActor` iki aktörle de çalışır |
| 2.3 | `src/character/npc.js` | `world.folk`; oturan çocuk `softContacts`'e geçer (§8 karar 3) | `menuDiff`; `game.nav` o noktada açık |
| 2.4 | `src/character/horse.js` | Tek `SkinnedMesh`, `harness`; `army.md` `MountLike`; `dorsal` sırt şeridi seçeneği (Adak Aygırı) | 22 → ≤3 çizim; `menuDiff` |
| 2.5 | `src/game/game.js`, `src/game/mounted.js`, `src/game/child.js` | `HERO_SCALE`, `.opts` kalkar; `profile`; çömelme; `ChildSystem` kalkış ve silah yuvası | Çit 5,4 m/sn ile aşılır; kapı → ateş yürünür |
| 2.6 | `src/app/states/freeroam.js`, `src/app/states/boot.js`, `src/ui/hud.js` | Çocuk (−1,98, −0,92) yaw 1,136'da oturarak doğar, ilk harekette kalkar; statik çocuk gizlenir; `Karakter` düğmesi, `C` kalkar | Çıkınca statik çocuk geri gelir, menü sahnesi aynı |

**Çıkış:** Serbest Gez Faz 1 kadrajında çizim ≈−200, üçgen ≈−125k (ölçüldü, §9; hesap Hero ve Çocuk ≈−127, iki at ayrıca −40); Hero içe aktarılmıyor.

### Faz 3: Menü, dil, epigraf, kayıt yuvaları, kamp sesi

İstek 2, 4. `pause` burada doğar.

`L`: `package.json` yazı tipleri (`@fontsource/alegreya`, `@fontsource/alegreya-sc` 5.3.0 kuruldu), `src/main.js` yazı tipi içe aktarımı, `src/app/app.js` `AudioEngine`, `SaveManager` kurulumu ve dört yeni durum, `src/app/systems.js` ve `src/app/sounds.js` (`SoundSystem`), `src/app/devtools.js` (`menuDiff` menü kamerasıyla, yeni taban).

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 3.1 | `src/ui/menu/main-menu.js`, `src/ui/menu/knot-button.js`, `src/ui/menu/brush-canvas.js`, `src/ui/menu/ornament.js`, `src/ui/menu/logo.js`, `src/ui/menu/save-card.js`, `src/ui/css/menu.css`, `src/i18n/strings/menu.js` | `menu-spec.md` §3; logo `public/ui/logo.webp`, yoksa `TANHU` yedeği | `docs/research/menu-shots` ile ölçü karşılaştırması |
| 3.2 | `src/ui/menu/book.js`, `src/ui/menu/ornate-frame.js`, `src/ui/menu/book-glyphs.js`, `src/ui/menu/pages/general.js`, `src/ui/menu/pages/settings.js`, `src/ui/menu/pages/controls.js`, `src/ui/menu/pages/destan.js`, `src/ui/menu/pages/people.js`, `src/ui/menu/pages/stones.js`, `src/data/destan.js`, `src/ui/css/book.css`, `src/i18n/strings/book.js` | §4 kitap, ayar sayfaları; Destan, Kişiler, Taşlar sayfaları yeni yazılır, Tanhu 3 metni alınmaz; `Dil` seçimi canlı | Dil değişince açık sayfa yenilenir |
| 3.3 | `src/ui/menu/save-panel.js`, `src/ui/css/save-panel.css`, `src/i18n/strings/save.js` | Yuva kartları, üzerine yazma, oto kart | Serbest Gez dışında yolculuk yokken Devam Et kapalı |
| 3.4 | `src/ui/menu/epigraph.js`, `src/ui/menu/language.js`, `src/app/states/language.js`, `src/app/states/epigraph.js`, `src/app/states/boot.js`, `src/ui/css/epigraph.css`, `src/i18n/strings/epigraph.js` | `boot` → `language` ya da `epigraph`; süreler 1,6 / 4,2 / 1,2 sn; söz «Yer, devletin temelidir. Onu kimseye vermem.» / «Land is the foundation of the state. I will give it to no one.»; kurulumu bekler | Basış yalnız bekleyişi kısaltır |
| 3.5 | `src/app/states/menu.js`, `src/app/states/pause.js`, `src/app/menu-camera.js`, `src/app/states/freeroam.js` | §3.20 kamera, §2.4 geçişleri, küçük resim, `I`, `J`, `L`, `K` sayfa yuvaları; `states.newgame` yoksa `YENİ OYUN` / `NEW GAME` kapalı; `pause` → `menu` `states.freeroam.endSession()` çağırır; `tanhu.roam` (`save.readRoam`, `writeRoam`): `freeroam.enter` `child.{pos,yaw,weapon}` okur, 30 sn'de bir ve `leave`'de yazar (§3.5) | `menuDiff` sürüklenme kapalıyken geçer |
| 3.6 | `src/audio/engine.js`, `src/audio/scheduler.js`, `src/audio/phrases.js`, `src/audio/music.js`, `src/audio/music-states.js`, `src/audio/instruments/dombra.js`, `src/audio/instruments/kobuz.js`, `src/audio/instruments/throat.js`, `src/audio/instruments/kaval.js`, `src/audio/instruments/drums.js`, `src/audio/instruments/jaw.js`, `src/audio/instruments/choir.js`, `src/audio/instruments/bell.js`, `test/phrases.test.js` | §3.6, `audio.md` §2–§3; `camp` önce | Gizli sekmede kesilmez; canlı düğüm ≤40 |
| 3.7 | `src/audio/sfx.js`, `src/audio/sfx/ui.js`, `src/audio/sfx/foot.js`, `src/audio/sfx/weapon.js`, `src/audio/sfx/structure.js`, `src/audio/sfx/gather.js`, `src/audio/sfx/horse.js`, `src/audio/sfx/world.js`, `src/audio/sfx/travel.js`, `src/audio/ambience.js`, `src/audio/spatial.js`, `src/audio/voice.js` | §3.6; bütün reçeteler `audio.md` §4; ortam döngüleri 22 kHz mono, sahne başına dilimli ön üretim | `check-data`: başvurulan her kimlik var; hazır ses ≤40 MB; üretimde kare kilitlenmez |

**Çıkış:** Açılış: dil → söz → menü, canlı kamp, müzik ve hafif dombra. Serbest Gez, Ayarlar, Yükle, kitap çalışır; TR ve EN her ekranda.

### Faz 4: Harita 75.000 km² ve açılma

İstek 9. Denetim 4 (geo), 5, 6.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 4.1 | `src/map/geography.js`, `src/i18n/strings/geo.js`, `test/geography.test.js` | Bütün tablolara kimlik; `groups-research.md` §3 düzeltmeleri; `unlock`; `MAP_AREA_UNITS`, `AREA_KM2`, `KM_PER_UNIT`; `ERAS` ve `ALL` 210 eklenir, I. Perde satırlarının `eras` dizileri 210'u içerir; genel grup sözcükleri ve soy iğneleri kalkar; ölü alanlar silinir | Görünür metinde genel grup sözcüğü yok; tek kimlik çakışması yok |
| 4.2 | `src/map/atlas.js`, `src/map/relief.js`, `src/map/relief-core.js`, `src/i18n/strings/atlas.js` | §3.18 altı okuyucu; [C] dönüştürücüleri; ölçek çubuğu 50, 100; not metni; `LOCAL_LAKE` `lake-line.js`'ten; `atlas.js:528` `Ötüken eteği` → `Hangay eteği` (`groups-research.md` §2) | Harita görünümü aynı, ölçek doğru; açılmamış satır görünmez |
| 4.3 | `src/game/progress.js`, `test/progress.test.js` | §3.13, §3.18; `progression.md` §17.1 #1, #3, #15–#20, #24 | Testler |
| 4.4 | `src/world/lake-line.js`, `src/world/terrain.js`, `src/world/valley.js` | Tek göl hattı | `menuDiff` |

**Çıkış:** Serbest Gez haritasında yalnız başlangıç satırları; `__tanhu.story.reveal('wusun')` görünür kılar.

### Faz 5: Sinema, Yeni Oyun, oluşturucu, ilk performans

İstek 5, 8. Denetim 7 ve 10'un ilk yarısı.

`L`: `src/app/app.js` `cine` kaydı; VO üretimi `node tools/voices.mjs gen --only=act0`.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 5.1 | `src/world/sky.js`, `src/world/world.js`, `src/world/valley.js` | Kameraya bağlı kubbe, `depthWrite:false`, `showBelowPitch`; `setFogOverride`; göl `uFogR` birlikte | Oyun kamerasında kubbe çizilmez; `menuDiff` |
| 5.2 | `src/world/fire.js`, `src/world/ambient.js`, `src/world/grass.js` | Alev yaw billboard yalnız `uBillboard=1`; nokta boyu kelepçesi; çim ve çiçek parçası uzaklık kırpması; `Smoke` tek çizim | `menuDiff`; geniş planda −119 çizim |
| 5.3 | `src/game/cine.js`, `src/app/states/newgame.js`, `test/cine.test.js` | §3.19, §4.3 göreli `t`; atlama | Atlama her anda `creator`'a; bekleyen yok |
| 5.4 | `src/character/npc.js`, `src/character/head.js` | `bard.perform`; `paintFace({ mouth })`; 3 viseme 512² | Yüz takası derleme yapmaz |
| 5.5 | `src/story/cast.js`, `src/story/vo-lines.js`, `src/story/act0/index.js`, `src/story/act0/bard-verse.js`, `src/story/act0/narrator.js`, `src/story/act0/cine-newgame.js`, `test/vo-lines.test.js` | Ozan dörtlüğü, anlatıcı girişi yeni yazılır (omurga `act1.md` §1; Tanhu 1 ve Tanhu 3 metni alınmaz); §4.3 kamera | `node tools/voices.mjs cost` çalışır; TR ve EN altyazı tam |
| 5.6 | `src/ui/creator/creator-screen.js`, `src/ui/creator/rows.js`, `src/ui/creator/parchment.js`, `src/ui/creator/banner.js`, `src/ui/creator/brush-button.js`, `src/ui/woven.js`, `src/ui/stage.js`, `src/app/states/creator.js`, `src/ui/css/creator.css`, `src/i18n/strings/creator.js` | `menu-spec.md` §5, `MeteAvatar`; ad sabit, görünüş, köken (`act1.md` §17 #9) ve zorluk satırı (`progression.md` §12); `public/ui/creator_bg.webp`; `mete.glb` yeni oyunda yüklenir | Kabulde `{ origin, appearance, difficulty }` döner |
| 5.7 | `src/core/post.js`, `src/game/nav.js`, `test/nav.test.js` | MSAA 2, bloom 4 seçenekleri; `find(…, {maxSteps})`, `lineFree(…, step)`, hedef hücre değişmedikçe yeniden aramama | A* ≤2 ms hedefi; `menuDiff` |

**Çıkış:** Yeni Oyun: ozan, geri çekilme, gök, anlatıcı, oluşturucu; kabul şimdilik Serbest Gez'e döner (`ACT1_READY=false`).

### Faz 6: Yapı sistemi ve üçüncü yurt

İstek 11. `structures.md` §17 adım 1–5 ve 6'nın ahır ve çit kısmı.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 6.1 | `src/core/geo.js`, `src/world/structure-shader.js`, `src/world/camp.js`, `src/world/interior.js` | `mergeStaged`, etiketler, 4 program; `owner`; `Room.enabled` | `diff()` ≤32 piksel |
| 6.2 | `src/game/nav.js`, `src/core/shapes.js`, `src/game/structure-nav.js`, `src/game/game.js`, `test/nav-layers.test.js` | `sb`, `st`, `epoch`, `arc`; `buildNav` `owner` atlar; `nudge` | `structures.md` §12.3 süreleri |
| 6.3 | `src/world/structure.js`, `src/world/structure-logic.js`, `src/world/structure-defs.js`, `src/world/structure-fx.js`, `test/structure-logic.test.js` | §3.11; `uDmg`, yanık, onarım; `yurt`, `stable`, `fence`, `pen`, kısa liste | `structures.md` §5.3 vuruş tablosu; `progression.md` §17.1 #11–#13 |
| 6.4 | `src/world/layout.js`, `src/world/grass.js`, `src/world/site-pad.js`, `src/world/world.js` | `SITE_YURT`, `SITE_STOCK`, ped, `uSiteMask`, menü kipi; `world.structures` | Menü farkı ≤%0,1 |
| 6.5 | `src/game/builders.js`, `src/character/gestures/build.js`, `src/ui/hud/build-status.js`, `src/i18n/strings/structures.js` | Oktar, Erka, Dengiz; iş tablosu; 8 yardım | 590 sn ±5; yardımla ≥283 sn |
| 6.6 | `src/game/combat.js`, `src/game/projectiles.js`, `src/game/telegraph.js`, `src/game/child.js`, `src/character/gestures/combat.js`, `src/data/weapons.js`, `test/combat.test.js` | §3.9, §3.10; Çocuk yay ve tahta kılıç | Oyuncak ok halata 1,5, keçeye 0,125 |

**Çıkış:** Serbest Gez'de üçüncü yurt kurulur, vurulur, geri düşer; `__tanhu.struct` kılıç, ok, ateş dener; kayıt aşamayı korur.

### Faz 7: WorldSpec ve dünya değişimi

Denetim 8, 9. En riskli faz: kamp çıktısı bit bit aynı kalmalı.

`L`: `src/app/world-swap.js`, `src/app/app.js`, `src/app/devtools.js` (`swap` paneli).

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 7.1 | `src/world/terrain.js`, `src/world/terrain-field.js`, `src/world/specs/index.js`, `src/world/specs/camp.js`, `test/terrain-field.test.js` | §3.8 `Terrain`, dağıtıcılar, bütün spec alanları | 1.000 noktada `heightRaw` bugünküyle aynı |
| 7.2 | `src/world/world.js`, `src/world/dispose.js`, `src/world/layout.js` | Spec güdümlü `build`; `yieldGate`; `dispose`; `moods.stops` | Adım sırası ve RNG aynı |
| 7.3 | `src/world/flora.js`, `src/world/grass.js`, `src/world/ambient.js`, `src/world/valley.js` | Sabitler spec'ten | `menuDiff`; ağaç, tutam sayısı aynı |
| 7.4 | `src/world/camp.js`, `src/world/interior.js`, `src/world/fire.js`, `src/character/npc.js`, `src/character/horse.js`, `src/character/folk.js` | `markShared`; önbellekler palete göre; `matKey` | Çifte `dispose` yok |
| 7.5 | `src/game/game.js` | `setWorld`; `spec.nav`, `spec.camera`, `spec.spawn` | Dünya değişince yol, oda, at temiz |
| 7.6 | `src/map/atlas.js` | `setWorld`, `this.home`; `CAMP` sabiti kalkar | `pinReal` ayrılıp geri gelir |
| 7.7 | `src/world/structure.js`, `src/world/structure-logic.js`, `src/world/structure-fx.js`, `src/game/builders.js`, `src/ui/hud/build-status.js`, `src/ui/css/build-status.css`, `test/structure-logic.test.js`, `test/builders.test.js` | Yapılar ve ustalar dünya değişiminde (`world:dispose`'da kayıt, yeni dünyada geri); Faz 6 artıkları: yardım halkası, yama ve oyuncak tozu, sessiz onarım tamamlanışı, çekiç kıymığı, sıçramada iz boşluğu, `build-status` CSS'i | camp3 kaydı değişimden önce, kayıtta ve sonra bayt bayt aynı |
| 7.8 | `src/game/combat.js`, `src/game/projectiles.js`, `src/game/telegraph.js`, `src/game/child.js`, `src/game/mounted.js`, `src/game/interact.js`, `test/combat.test.js` | Oklar, şekiller, nişan, sağ tık bağlamı ve hedefler dünya değişiminde düşer; ok havuzu, şekil ağı ve silahlar paylaşılan, yeni sahneye taşınır | Yeni dünyada vuruş, binme; ilk karede program derlenmez |

**Çıkış:** `__tanhu.swap('camp')` üç kez: `renderer.info.memory` tabanda (`travel.md` T9); `menuDiff` geçer.

**Faz 7 entegrasyonu (`L`).** `world-swap.js` §2.7 sırasıdır (`compileWorld`, `warmWorld`, `worldForRecord`; ret `false`); `App.start` ilk dünyayı `boot` → `replaceWorld('camp')` (`SPECS.camp`) ile kurar ve aynı iki işlevle derler, `app.swapping` ikinci isteği reddeder; `ctx` alanları aynı. `devtools.js` `swap(specId)` → `{ ms, before, after }` (`renderer.info.memory` ve program sayısı; `after` değişimden sonra çizilen ilk karede), `refs` paneli ve `world:ready`'de menü parçacıklarının yeniden saklanması değişimden sonra da çalışır. `sounds.js` ortamı `spec.audio.ambience`'tan kurar, `world:dispose`'da konumlu sesleri söndürür (`sfx.stopPlaced`), yeni dünyada süren kipi yeniden yazar. `freeroam.js` oturumu değişim boyunca taşır (§2.7). `menu.js` ve `pause.js` Yükle yolu `worldForRecord`'dan geçer; `pause` → `menu` başka dünyadan `replaceWorld('camp')`, yükleyiciyi değişim açar. Kayıt kartlarının dünya adı `specs/zones.js`'ten (`save.world.*`, `menu.zone.*`). `CameraRig.setZoom(min, max)`: `spec.camera` aralığı 13–44 dışına da uygulanır (`Game.setWorld` çağırır). `World.aimSun(focus)`. `style.css`: `.hud-place` TANHU başlığı görünürken onun altında durur. `terrain.js` `LAKE_Y` ve `NEAR`'ı artık dışa vermez. Kamp spec'i kurucuların varsayılanlarının hepsini yazar (§3.8). Ölçüm §2.7 sonunda.

### Faz 8: Oyuncu çekirdeği ve ekonomi

İstek 7, 12; K20–K24. Sistemler Serbest Gez'de küçük döngüyle, `?state=play` deneme sahnesinde ve `?sandbox=site` kum havuzunda tam sınanır. Saat, hava çekirdeği, emek yasası (Faz 6 yeniden işleme), şantiye, yerleşim çekirdeği ve ekonomi servisleri bu fazdadır; hikâye açılışı II. Perde'dedir (K23, Faz 13). Hava görünümü 9.4'e dek kimliktir.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 8.1 | `src/game/derive.js`, `src/data/skills.js`, `src/data/mod-readers.js`, `src/i18n/strings/skills.js`, `test/derive.test.js` | §3.13; 93 beceri; `env.wetBow` (0,25 basamak), `env.blizzard`, binek yükü `mountLoadK` (`d2/economy.md` §5.4); emek becerileri (`quick_raise`, `repair`) `labour.js` için `mods`'ta | `progression.md` §2.4 tablosu; §17.1 #2, #4–#7, #14, #25–#27; `wetBow` 1'de ok hasarı −%15 |
| 8.2 | `src/game/items.js`, `src/data/items.js`, `src/data/gear.js`, `src/game/inventory.js`, `src/game/container.js`, `src/i18n/strings/items.js`, `test/inventory.test.js`, `test/container.test.js` | `economy.md` §2, §4; §3.13, §3.26: taksonomi, 23 yeni kimlik, `baseId`, `Container`, `transfer`, `transferAll`, gün anahtarlı bozulma, kap çözücü (`site`, `store`, `pool`), Terki, `economy` v2 | `speedK` .85, .7; el koyma istisnaları; `economy.md` §12 Sınamalar (K24): `stackLoad10`, `Container.canTake`, kısmi `transfer`, bozulma, `matches`, bohça (`yurt_kit` 8 kimlik, 19 parça, 59 Yük), kayıt v2 gidiş dönüşü ve v1 göçü; I. Perde yurdu 54 birim, 146 Yük |
| 8.3 | `src/world/node-store.js`, `src/world/nodes.js`, `src/data/node-kinds.js`, `src/game/gather.js`, `src/game/strike-ring.js`, `src/character/gestures/labour.js`, `src/i18n/strings/economy.js`, `test/node-store.test.js`, `test/gather.test.js` | §3.12; `applyTaken`; `node_camp_logs`; düğümün `weather` alanı ve yığının `wet` biti; `onDawn` `dawn` olayına, atlamada şafak başına bir; jestler `carry('haul')`, `cover_head` (`weather.md` §8.15); `strings/economy.js` `economy.md` §13 tablosunun bütün anahtarlarını TR ve EN taşır (aktarma paneli dahil: `econ.transfer`, `econ.unload_back`, `econ.store_materials`, `econ.store_food`, `econ.take_all`, `econ.take_missing`, `econ.store_full`, `econ.wont_take`) | 3.270 kayıt; `nodeStats`; `applyTaken` belirlenimli |
| 8.4 | `src/game/needs.js`, `src/game/craft.js`, `src/data/craft-recipes.js`, `src/data/stations.js`, `src/game/supply.js`, `src/game/barter.js`, `src/game/herds.js`, `src/data/herd-kinds.js`, `src/game/loot.js`, `src/data/loot-tables.js`, `src/audio/sfx/economy.js`, `test/needs.test.js`, `test/craft.test.js`, `test/supply.test.js`, `test/herds.test.js`, `test/loot.test.js` | `economy.md` §5–§9; §3.26: tarif, `Workshop`, 11 tezgâh, 9 rol, `SupplyLedger` ambar kipi, `LEDGERS` (`ctx.supply`), `armyShare`, `rolloverYears`, `herdDay`, `loot.of`; Tokluk oyun dakikasıyla; ekonomi reçeteleri | `economy.md` §7 senaryo tablosu (Kış Hesabı teslimleri birebir); `economy.md` §12 Sınamalar (K24: `Workshop.tick` 4 elle `eff` 3,439; `herdDay`; `booty` %25 / %75; `armyShare` düz %10: 10 → 1, 100 → 10, 600 → 60, Göçer 66, kışın ×0,1; `loot.of` belirli); `data/*` önkoşul (2)'nin `d2/econ-model.json`'ıyla aynı sayılar (`test/craft.test.js` modeli okur; adlı silah ganimet verisine girmez, K24); Tokluk Son Gece ×1,2; Kış Hesabı `a1_last_night` açıkken şafakta düşmez |
| 8.5 | `src/game/campfire.js`, `src/game/cooking.js`, `src/data/recipes.js`, `src/ui/cook-wheel.js`, `src/ui/css/cook-wheel.css`, `src/i18n/strings/survival.js`, `test/cooking.test.js` | `survival.md` §2–§3; ateş ve pişirmenin hava tablosu (`fx.fireK`, `fireOutS`, `fireRing`, `dryK`; `weather.md` §8.5); `onSkip`, `cold_pit` ertesi şafakta; Dinlen tekerini `ClockSystem` açar | Tek paylaşılan ışık; ≤6 ateş; yağmurda taşsız ateş ×1,5; fırtınada taşsız ateş 40 sn'de söner |
| 8.6 | `src/game/agent.js`, `src/game/agent-move.js`, `src/game/fauna.js`, `src/game/hunting.js`, `src/character/animal.js`, `src/data/fauna-kinds.js`, `test/agent-move.test.js` | §3.16 taban; `survival.md` §4; evre takımı (`time.md` §9.9; ana kampta `CampLife` ister, K3 ≤6), iz ve koku hava çarpanı (`fx.trackK`, `scentK`, rüzgâr), tuzak zarı 00/06/12/18 | Karga, tavşan Çocukla; mandal testi; kampta hayvan ≤6 her evrede |
| 8.7 | `src/ui/pack.js`, `src/ui/ledger.js`, `src/ui/barter.js`, `src/ui/glyphs.js`, `src/ui/transfer.js`, `src/ui/css/pack.css`, `src/ui/css/ledger.css`, `src/ui/css/transfer.css`, `src/ui/hud/needs.js`, `src/ui/hud/gain.js`, `src/ui/hud/bar.js` | `progression.md` §14.1, `economy.md` §4.2, `d2/economy.md` §5.2: Heybe (Terki sekmesi), aktarma paneli (`transfer` bağlamı), Defter'in yapı sayfası (`ctx.sites.list()`) | `pause` sayfaları dolu; aktarma paneli TR ve EN; «Eksikleri Al» şantiyenin eksiğini alır |
| 8.8 | `src/game/player.js`, `src/game/mounts.js`, `src/game/child.js`, `src/data/enemies.js`, `src/app/states/play.js`, `test/player.test.js` | Yara, Düşüş (uyanış +2 oyun saati), `moveMods`; dolu ve beden (`weather.md` §8.17); Çocuk küçük döngü, ateş ziyareti `CampLife`'tan, hava tepkileri (§8.15); `play` iskeleti, `?state=play` deneme sahnesi; `play.enter` `hud.vitals.setName` ve gerçek `stats.hp`, `hpMax` yazar; Çocuğun nişan halkası `projectiles.predict`'ten (rüzgâr dahil; halka gerçek iniş yeridir, `weather.md` §8.8) | camp3 katılması Çocukla (fiil yaptıkça yarım el); iri dolu Can tabanı %40, Yara yok |
| 8.9 | `src/game/world-clock.js`, `src/game/daylight.js`, `src/game/calendar.js`, `src/game/clock-system.js`, `src/game/camp-life.js`, `src/world/world.js`, `src/world/sky.js`, `src/world/specs/camp.js`, `src/core/keymap.js`, `src/core/settings-schema.js`, `src/game/save.js`, `src/audio/music-states.js`, `src/audio/music.js`, `src/audio/sfx/time.js`, `src/ui/hud/clock.js`, `src/ui/wait-wheel.js`, `src/ui/css/wait.css`, `src/ui/menu/save-panel.js`, `src/i18n/strings/time.js`, `src/i18n/strings/save.js`, `test/world-clock.test.js`, `test/daylight.test.js`, `test/sky-keys.test.js`, `test/calendar.test.js`, `test/input.test.js`, `test/settings.test.js`, `test/phrases.test.js`, `test/save.test.js` | K20, §3.23, `time.md`: dünya saati, gün ışığı, takvim, altı ışık durağı ve ışığın tek hattı (`lightBase`, kimlik `writeLight`, gölge kuralları, gece göğü, geriye uyum için `moodT`), `world.tallThings` alanı; Bekle, Uyu, Dinlen, Çalış tekeri; vakit ve bekleyiş; ana kamp programı (`CampLife`); Gök Kavisi; kayıt kartının evresi (`SlotInfo.minute`, `phase`; `emptyInfo`, `infoOf`); `save.js`: `FORCED_REASONS`'a `court_path`, `meta.phase` blok yolu kabul edilir ve `_compose` onu `meta.place` gibi korur, `setRules` `items` denetimi kimliğin İnce İş ekini (sondaki `+`) atarak bakar (§3.5: `hun_bow+` geçerlidir); kamp spec'inin `light`, `moods.cycle`, evre ortamları, `weather`, `labour` blokları; `wait` (`T`), `build_mode` (`P`); `camp_night`, dört saat reçetesi; `music-states.js`: `camp_night`, `winter_day` ve `winter_evening`'e `{ role: 'bell', p: 0.4, vel: 0.24 }` partisi ve `rain: { gain: 0 }` katmanı (yağmur katmanı yalnız `bell` partisiyle çalar), `ambient: true` (`camp`, `camp_night`, `winter_day`, `winter_evening`, `winter_night`); `music.js`: `setAmbientLayer` (§3.6); `test/input.test.js` `DEFAULT_KEYMAP` kopyası §3.2'ye (`wait: ['KeyT']`, `build_mode: ['KeyP']`; `mood` yok), `test/settings.test.js` tablosu `game.clockShow` ile, `test/phrases.test.js` `IDS` `camp_night` ile (17 durum; test adındaki «16 durum» da), `test/save.test.js` `court_path`, `meta.phase` ve `hun_bow+` ile yenilenir | `time.md` §17 `daylight`, `world-clock`, `calendar`, `sky-keys` sınamaları (`schedule` satırı 10.3'ündür); `menuDiff` 0 (taze, Serbest Gez 03:00'te, gece oturumundan sonra); yeni oturumun ilk karesi menü ışığında; saat taban üstüne 0 program; `clock.lapse(24)` bir şafak; 15 fps'de gün 60 ±1 dk; Serbest Gez en kötü gündüz karesi ≤509 çizim (9.4'ün havasına 2 pay; aşılırsa gündüz ikizi düşüşü 8.9'un `camp-life.js`'indedir, 9.4 o dosyaya dokunmaz); `items` kuralı verilince `hun_bow+` Heybe'de ve `tools`'ta yüklemede düşmez |
| 8.10 | `src/data/weather-types.js`, `src/data/climates.js`, `src/game/weather-core.js`, `src/game/weather.js`, `src/game/projectiles.js`, `src/game/mounted.js`, `src/i18n/strings/weather.js`, `test/weather-core.test.js`, `test/weather-fx.test.js`, `test/weather-strike.test.js`, `tools/weather-model.mjs`, `docs/design/d2/weather-model.json` | K22, §3.24, `weather.md` §3–§8, §12: planlayıcı (sabit çapa, cephe, kilit, `pinFx`), ıslaklık, kar örtüsü ve Kar Kabuğu, `fx`, işaretler, alt olaylar, yıldırım seçimi, `weather.audio`, müziğin `rain` katmanı; ok sapması ve `predict`; atın rüzgârı ve gök gürültüsü ürkmesi | `weather.md` §15 W1–W11 ve W26 (üreteç sabit tohumla 150 kışı koşup `d2/weather-model.json`'ı yazar; sınama kural sırasını, I. Perde satırında kabuk 0'ı ve yalnız iki yerleşim ikliminde mutlak toleransı denetler: `steppe_south` derin kar 0,135 ±0,03, kabuk 0,63 ±0,3 / kış; `gobi` kabuk ≤0,05); dosya ekonomi alanının son `--strict` koşusundan önce yazılır; görünüm 9.4'e dek kimlik |
| 8.11 | `src/game/labour.js`, `src/world/structure-defs.js`, `src/world/structure-logic.js`, `src/world/structure.js`, `src/world/structure-shader.js`, `src/world/camp.js`, `src/game/builders.js`, `src/ui/hud/build-status.js`, `src/audio/sfx/structure.js`, `src/i18n/strings/structures.js`, `test/labour.test.js`, `test/structure-logic.test.js`, `test/builders.test.js` | K21, §3.25: emek yasası (`eff`, el sınırı, tek el yalnız tündükte, gece, hava durağı, tokluk, `dayCapacity`, onarım, taşıma, söküm, toplu benzetim); `STRUCTURE_DEFS` emek alanları, parça ve ham teslim, K23 türlerinin veri satırları; Faz 6 yeniden işleme (aşağıdaki liste): camp3 emek çizelgesi, `CHILD_HELP`, Dengiz baştan sona, öğün sırası, gece meşale direkleri (`G_TORCH`, `torch_post`), `SHELTER`, «aile bekler», HUD ekip satırı, camp3 kaydı `v: 2` | §6.1 `labour` satırı (`d2/core.md` §2.2–§2.3: tek el 1.440 İD, ekip 1.376 İD, çizelge ±0,05 dk; usta + Çocuk 39,8 dk, usta + çırak 34,4 dk; onarım `structures.md` §7 örnekleri 490; 24; 19,5; 1.087; 275; 29 İD); camp3 saatsiz yardımsız 1.434 sn ±10, bütün yardımla 1.188 sn ±10 (Dengiz'in iki su seferi dahil, `d2/core.md` §2.10); 14:54 saatiyle ve öğünle ilk duman 00:55 (1.503 sn) ve 23:11 (1.244 sn) ±15, açık havaya iğneli; «Gece dinlenilsin» ≈08:55; aile ocak yanana dek ateşte (en geç 01:30; aşama ≥6 ise 03:00; `camp3:family_wait`); takılan usta ≤6 sn bekletir; `menuDiff` 0; program ≤92; en kötü kare ≤+250k, ≤+45 çizim |
| 8.12 | `src/game/site-core.js`, `src/game/sites.js`, `src/world/site-pad.js`, `src/world/specs/sandbox.js`, `src/world/specs/index.js`, `src/world/specs/zones.js`, `src/i18n/strings/sites.js`, `test/sites.test.js` | K21, §3.25: genel şantiye: yerleşim denetimi (`validatePlacement`, `rules`), yığın ve teslim, 150 m kendi taşıması, ekip atama, gece emri, bekleme nedenleri, çalışma atlaması, uzak şantiye ve `catchUp`, söküm, `world.sites`; Kışlak Yeni Yurdu'nun `timed` sürücüsü (saat, ekip, malzeme, hikâye kapısı); kum havuzu dünyası `sandbox_site` | `sites` sınamaları; Kışlak benzetimi `d2/core.md` §2.12 yolunu ±2 oyun dk verir; baskın sonrası en kötü kayıt ≤20 KB gidiş dönüş; `?sandbox=site` yurdu görünür kurar, öteki Faz 6 türlerini ve K23 türlerini yalnız mantıkla (`SiteCore` ve `StructureState` bütün adımlardan, görünümsüz) işletir; K23 görünüşleri 9.10'dadır |
| 8.13 | `src/data/settlement.js`, `src/game/settlement/state.js`, `src/game/settlement/households.js`, `src/game/settlement/steward.js`, `src/game/settlement/stores.js`, `src/game/settlement/production.js`, `src/game/settlement/caravans.js`, `src/game/settlement/raids.js`, `src/game/settlement/camps.js`, `src/game/settlement/court.js`, `src/game/settlement/chronicle.js`, `src/i18n/strings/settlement.js`, `test/settlement.test.js`, `test/settlement-ii.test.js` | K23, §3.27, `settlement.md` §5, §6, §9–§12, §15, §16: yerleşim çekirdeği (saf): hane, Çekim, Gönül, Kâhya, `StorePool`, üretim saati, `CaravanBook`, akın, `CampState`, Divan, Kronik; K24 servisleri ve K21 `SiteSystem` sözleşmeyle; `d2/settlement-model.json` v2 ile aynı sayılar | `settlement.md` §21 saf maddeleri: 1–8, 13, 14, 16, 19 ve 15'in `settlement` kısmı `test/settlement.test.js`'te; 9–12, 17, 18 ve 15'in `camps` kısmı `test/settlement-ii.test.js`'te; kum havuzunun istediği `state`, `households`, `steward`, `stores`, `production` çıkışı bağlar; `court`, `chronicle`, `raids`, `caravans`, `camps` ve `test/settlement-ii.test.js` Faz 8 çıkışını ve K11 kapısını bekletmez, bitmezse Faz 13'e kayar (`decisions.md` K26) |
| 8.14 | `src/game/cond.js`, `src/game/effects.js`, `src/game/cine.js`, `src/story/schema.js`, `tools/check-data.mjs`, `test/cond.test.js`, `test/effects.test.js`, `test/cine.test.js`, `test/schema.test.js` | §3.14, §3.19, §4.3: koşul atomları `phase:`, `beat:`, adlar `hour`, `dark`, `moon`; etki `clock` (`work` kalkar), `weather`, `ledger` yeri; sinemanın `clock` izi ve `weather` satırı, `release()` sinema kilitlerini kaldırır; `check-data`: hava kimlikleri, saat izi, `StoryDay` biçimi, eşya ve tarif kimliklerinin `d2/econ-model.json` ile, `data/settlement.js`'in `d2/settlement-model.json` ile eşitliği | Bütün yeni op ve atomlar sahte servisle; `clock` yalnız ileri; hava sistemi yokken `weather` op'u yok sayılır; sinema atlamasında `clock` satırları uygulanır |

`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları: `clock` 15, `calendar` 20, `weather` 22, `sites` 61, `camp_life` 81 (`settlement` 64 9.9'da); `ctx.worldClock`, `ctx.calendar`, `ctx.campLife`, `ctx.weather`, `ctx.sites`, `ctx.supply = LEDGERS` (`LEDGERS.bind(bus, { diff })`); `app.wallDt` (§2.5); `inventory.setResolver`; `save.setRules({ …, items })`; `?sandbox=site` → `play` + `replaceWorld('sandbox_site')`. `src/ui/hud.js`: geliştirme ışık düğmesi kalkar, Gök Kavisi `tr` yuvasına takılır. `src/app/sounds.js`: ortam evreye (`spec.audio.ambience`, `time.md` §8.5) ve havaya (`ctx.weather.audio`, §3.6) bağlanır; gündelik müziği seçer (`audio.md` §3 «Saate bağlı durum»). `src/app/devtools.js`: `drawMenuFrame` saat, CampLife ve hava kimliğini saklar ve geri yazar (§6.3); `freeze` dünya saatini ve hava saatini de durdurur. `src/app/states/freeroam.js`: `T` → Bekle (eski `toggleMood`, `MOOD_*` kalkar); `roam.clock` ve `roam.weather` okuma ve yazma (`clock.toRoam()`, `weather.toRoam()`), `mood` göçü; girişteki `music.setState('camp')` kalkar (seçici `sounds.js`, `audio.md` §3); `endSession` geri yüklemesi (`time.md` §14); menüden iniş 2,4 sn, dönüş 1,7 sn ışık karışımı.

**Paket bağları.** 8.10 saatin yüzünü (§3.23) ve `music.setAmbientLayer`'ı (§3.6) 8.9'dan, 8.11–8.13 8.9 ve 8.10'u, 8.11 `matches` ve `bundleOf`'u (`game/items.js`) 8.2'den, 8.8 `projectiles.predict`'i 8.10'dan, 8.12 `labour.js`'i 8.11'den ve `Container`'ı 8.2'den, 8.13 K24 servislerini (8.2, 8.4) ve `SiteSystem`'i (8.12), 8.7 aktarma paneli ve Heybe dizgelerini (`econ.*`, `economy.md` §13) 8.3'ün `strings/economy.js`'inden, 8.14 `WorldClock` ve `Calendar`'ı (8.9), `ctx.weather`'ı (8.10) ve `LEDGERS`'ı (8.4) §3 sözleşmesiyle alır; dosya paylaşmazlar, bağı `L` faz sonunda sınar. `keymap.js` yalnız 8.9'dadır (`wait`, `build_mode`; ayrı `rotate` eylemi yok); `applyTaken` 8.3'tedir; `freeroam.js` bu fazda `L`'nindir. Ön koşullar: (1) `d2/labour-model.json` v2 `d2/core.md` §2.2–§2.3 sayıları ve bütün tür tablolarıyla yazıldı (2026-11-03); 8.11 onu okur. (2) **8.2 ve 8.4 başlamadan** ekonomi alanı `tools/econ-sim.mjs` ile `d2/econ-model.json`'ı birlikte K24'e getirir ve `--strict` 0 işarete indirir: `dayCapacity`, yeni kademe günleri (T2 2,5–7), hazır yük 1 / 6 / 12 / 22 / 17, yerleşik atlı ve düz %10 Ordu Payı (kışın ×0,1), `preserveLoss` 0,65 ve `sogumLoss` 0,35, düşman türü başına belirli ganimet (adlı silah satırları silinir), `banner_pole` 40 İD, Demirci Ocağı'nın hurda seçeneği, Teoman'ın armağanı ve gelen hanenin azığı ve kırkımı, Kâhya'nın av kolu ve `K_tok`, garnizonlu baskın kaybı, Surlu tarlası ve kulesi, Göçer ×1,2, malın perde ve mevsimde varlık sınaması, `weather-model.json` ve `labour-model.json`'ın okunması (`d2/core.md` §5.9). (3) 8.10 `weather-model.json`'ı ekonominin son `--strict` koşusundan önce yazar; dosya sonra değişirse sim yeniden koşulur.

**İki dalga (2026-11-03, §8 karar 58).** Faz 8 iki dalgada koşar; her dalga kendi `L` bağı, incelemesi ve dumanıyla biter, B A'nın bitmiş kodunun üstüne kurulur. Tablodaki 8.4, 8.9, 8.11 ve 8.13 dosyalarıyla bölünür: 8.4, 8.11 ve 8.13 ikiye, 8.9 üçe; tablonun 14 paketi böylece 19 alt pakettir, A 9 ve B 10 (K64, #62; §8 karar 58); bir dosya bir dalgada tek pakettedir, sonraki dalga onu genişletebilir (`strings/time.js`):

- **A, temeller.** 8.1; 8.2; 8.3; **8.4a** ihtiyaç, zanaat, ambar, takas: `src/game/needs.js`, `src/game/craft.js`, `src/data/craft-recipes.js`, `src/data/stations.js`, `src/game/supply.js`, `src/game/barter.js`, `src/audio/sfx/economy.js`, `test/needs.test.js`, `test/craft.test.js`, `test/supply.test.js` (Bitti: `economy.md` §7 senaryo tablosu, §12 `Workshop.tick` ve `armyShare`); **8.4b** sürü ve ganimet: `src/game/herds.js`, `src/data/herd-kinds.js`, `src/game/loot.js`, `src/data/loot-tables.js`, `test/herds.test.js`, `test/loot.test.js` (Bitti: `herdDay`, `booty` %25 / %75, `loot.of` belirli); **8.9a** saat çekirdeği: `src/game/world-clock.js`, `src/game/daylight.js`, `src/game/calendar.js`, `src/game/clock-system.js`, `src/core/keymap.js`, `src/core/settings-schema.js`, `src/game/save.js`, `src/audio/music-states.js`, `src/audio/music.js`, `src/i18n/strings/time.js`, `test/world-clock.test.js`, `test/daylight.test.js`, `test/calendar.test.js`, `test/input.test.js`, `test/settings.test.js`, `test/phrases.test.js`, `test/save.test.js` (iş: 8.9 satırının saat, takvim, kayıt, tuş, ayar ve müzik maddeleri, `SlotInfo.minute`, `phase`; Bitti: `daylight`, `world-clock`, `calendar` sınamaları, `clock.lapse(24)` bir şafak, 15 fps'de gün 60 ±1 dk, `hun_bow+` kuralı); 8.10; **8.11a** saf emek yasası: `src/game/labour.js`, `test/labour.test.js` (Bitti: §6.1 `labour` satırı); 8.14.
- **B, üstüne kurulanlar.** 8.5; 8.6; 8.7; 8.8; **8.9b** ışık, gök ve kamp yaşamı: `src/game/camp-life.js`, `src/world/world.js`, `src/world/sky.js`, `src/world/specs/camp.js`, `src/audio/sfx/time.js`, `test/sky-keys.test.js` (iş: altı ışık durağı ve ışığın tek hattı, `world.tallThings`, `CampLife`, kamp spec'inin saat, hava ve emek blokları, dört saat reçetesi; Bitti: `sky-keys`, `menuDiff` 0 (taze, Serbest Gez 03:00'te, gece oturumundan sonra), yeni oturumun ilk karesi menü ışığında, saat 0 program, gündüz ≤509 çizim; K63 ile değişti: ≤509 eski 511 satırından türemişti, yeni ≤520 satırına göre pay 518 olurdu; 8.9b yazılmayacağı için değer iz olarak kalır); **8.9c** saat arayüzü: `src/ui/hud/clock.js`, `src/ui/wait-wheel.js`, `src/ui/css/wait.css`, `src/ui/menu/save-panel.js`, `src/i18n/strings/time.js` (genişletir), `src/i18n/strings/save.js` (Bitti: Bekle, Uyu, Dinlen, Çalış tekeri ve Gök Kavisi TR ve EN, kayıt kartının evresi); 8.11 (Faz 6 yeniden işleme; `labour.js`'i 8.11a'dan okur, `structure-shader.js`'in K27 kapanma kancasını korur); 8.12; **8.13a** yerleşim çekirdeği: `src/data/settlement.js`, `src/game/settlement/state.js`, `households.js`, `steward.js`, `stores.js`, `production.js`, `src/i18n/strings/settlement.js`, `test/settlement.test.js`; **8.13b** II–VI parçaları: `src/game/settlement/caravans.js`, `raids.js`, `camps.js`, `court.js`, `chronicle.js`, `test/settlement-ii.test.js` (faz çıkışını bekletmez, §8 karar 55).

**Durum (2026-11-04, K29, K64).** A dalgasının kodu yazıldı; incelemesi ve tarayıcı dumanı kayda geçmedi (§9). B dalgası yazılmadı. Prototip artık hedef olmadığı için dalgalar burada iz olarak kalır; `contract-requests.md`'nin açık satırları bu iki dalgaya göre A ve B diye işaretlendi. Godot'daki karşılıkları Yol Haritası'nın I. Perde fazlarıdır (`/roadmap#act-1-p1`).

**Ara kurallar (dalga A → B, §8 karar 59).** Dalga A'da saat ilerler (`ClockSystem` 15, `ctx.worldClock`, `ctx.calendar`), ışık saate 8.9b'de bağlanır: `ClockSystem` `world.setTimeOfDay?.(sample)` çağırır, yoksa ışığa dokunmaz. `T` (`wait`) dalga B'nin Bekle tekerine dek `L`'nin `freeroam.js`'inde bugünkü geliştirme ışık geçişini sürdürür. Hava görünümü 9.4'e dek kimliktir; Serbest Gez havası `__tanhu.weather.set` zorlamadıkça açıktır (`clear`): planlayıcı koşar, `fx`, işaretler ve ses yazılır, görünüm yazılmaz. Dalga A'nın `L` bağı: `systems.js` (`clock` 15, `calendar` 20, `weather` 22), `app.js` (`ctx.worldClock`, `ctx.calendar`, `ctx.weather`, `ctx.supply = LEDGERS`, `app.wallDt`, `inventory.setResolver`, `save.setRules({ …, items })`), `devtools.js` (`freeze` saati ve havayı da durdurur; `drawMenuFrame` saati ve hava kimliğini saklar ve geri yazar), `sounds.js` (havanın sesi; gündelik müzik seçimi B'de). Dalga B'nin `L` bağı yukarıdaki satırın kalanıdır: `sites` 61, `camp_life` 81, `ctx.campLife`, `ctx.sites`, `?sandbox=site`, `hud.js` (Gök Kavisi), `sounds.js` (evre ortamı, gündelik müzik), `freeroam.js` (`T` → Bekle, `roam.clock`, `roam.weather`, `mood` göçü, giriş ve çıkış ışık karışımı). Faz 8 çıkışının `econ-sim --strict` koşusu dalga B'nin sonundadır.

**8.11 Faz 6 yeniden işleme** (K21; sayılar `d2/core.md` §2, kurallar `structures.md` §2.4, §11.6–§11.8; `d2/labour.md` §12 yalnız iz):

| Dosya | Değişiklik |
|---|---|
| `src/world/structure-defs.js` | `YURT_STEPS`: `dur`, `crew` → `work`, `min`, `max`, `solo` (yalnız `y_tunduk` 1,6), `tall`, `felt`; adım emekleri `d2/core.md` §2.2 (tek el 1.440, ekip 1.376); `YURT` `craft: 'home'`, `crewMax: 8`; `y_bosaga`, `y_kerege`, `y_uuk`, `y_liner` `parts` ve `rawWork` (360, 720, 480, 120 İD; kerege `rawRole: 'cr_carpenter'`); `STABLE`, `FENCE`, `PEN`, `CART` ve `simple()` türlerinin emek tabloları `labour-model.json`'dan (`simple()`'ın `dur: 10 + hp × 0,6` kuralı kalkar); `CREDIT_RATE` silinir, `REPAIR.tearStitch` 4 İD, `rerun` 0,8; K23 türleri ve hazır ayarları (§3.11) |
| `src/world/structure-logic.js` | `advance(wm)`, `wm`, `rate`; `credit(wm)` çarpansız; `sliceTick` silinir (`_buildTo` senaryo için kalır); `repairStep(wm, who)`; `dismantle()`; `_have`, `_spend` `matches(id, ref)` ile (ad öneki kuralı kalkar); `deliver` bohçayı açar; `toJSON` `v: 2` (göç `structures.md` §11.8; süren onarım `rep` İD olarak yazılır) |
| `src/world/structure.js` | `_work` yedeği oyun dakikası ve iki elin oranıyla (`manager.driven` yapıda iş yok, §8 karar 34); camp3 `v: 2` yazımı ve göçü; `G_TORCH` grubu ve gece alevleri (`fxFlames`, `fxGlow` havuzlarından); menü kipinde gizli |
| `src/world/structure-shader.js`, `src/world/camp.js` | `G_TORCH` etiketi ve iki meşale direği (camp3 `frame` ağında, ≈120 üçgen, 0 çizim) |
| `src/game/builders.js` | `workRate` → `labour.stepRate`; `HELP` → `CHILD_HELP` (katılma fiilleri; ayak işleri `help_log` (`node_camp_logs`'tan), `help_ember`, `help_water`); `HelpDesk.credit` kalkar; `DENGIZ_CALL_K` kalkar, Dengiz girişte gelir ve `JOBS`'ta sütun alır; `dur` → `stepSpanS()`; yeni durumlar `SHELTER`, öğün sırası (12:00, 18:30), ilk geliş 06:00–22:00, «Gece dinlenilsin» ile 22:00 çıkış; «aile bekler» kuralının tek sahibi: `camp3:family_wait { until }` (22:30; 01:30'da aşama ≥6 ise 03:00) ve `camp3:hearth_dawn` olaylarını yayar, 05:00 ocağı; `CampLife` (8.9) yalnız uyar; `status` `heads`, `W`, `etaMin`, `wait`, `solo` |
| `src/ui/hud/build-status.js`, `src/audio/sfx/structure.js`, `src/i18n/strings/structures.js` | Ekip ve «≈N saat» ya da bekleme nedeni satırı; `torch_post` reçetesi; `labour.*` anahtarları ve ustaların yeni sözleri |
| `test/structure-logic.test.js`, `test/builders.test.js` | 590 sn ve 283 sn sınamaları emek sayılarına geçer (§6.1) |

**Çıkış:** Deneme sahnesinde toplama, zanaat, ateş, yemek, av, dövüş, seviye ekranı; Serbest Gez'de 60 dakikalık gün, gece, Bekle ve Uyu, hava çekirdeği (görünüm kimlik); camp3 emekle ve saatle kurulur; kum havuzunda yurt görünür, öteki türler mantıkla şantiyeyle kurulur (görünüşleri 9.10); yerleşim çekirdeği `node:test`'te; `L` faz sonunda, 8.10'un `weather-model.json`'ından sonra: `node tools/econ-sim.mjs --strict` 0 işaret (ekonomi alanının son koşusu) ve `node tools/check-data.mjs` (8.14) `data/*` = `d2/econ-model.json`.

### Faz 9: Kışlak dünyası

`act1.md` §4, §15. Canlı kampa dokunulmaz. K22 hava görünümü ve sesi, K23 yerleşim görünümü, Plan Kipi ve yapı görünüşleri bu fazdadır; menü karesi değişmez.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 9.1 | `src/world/specs/winter.js`, `src/world/specs/winter-layout.js`, `src/world/specs/index.js`, `src/world/terrain-patches.js`, `src/world/snow-hooks.js` | 1400×1050 m; 100 m parça, yakın 3×3 1 m; yükseklik §4; `tree_winter`, `node_winter`, `*_w`; kar kabartma zemini (§3.8), parça başına boyama yok; `winter-layout`: `rot`, iç tasarım, `watch_fires[]` (`act1.md` §4), Kışlak Yeni Yurdu şantiyesi (ekip, gönderim tablosu, kapılar); `light`, `WINTER_MOODS`, `weather`, `labour`, `perish` (§3.8); `SNOW_FRESH` kancası (9.4'ten); `specs/index.js` `hexi_winter` ve `sandbox_hold` yükleyicileri | Kurulum ≤8 sn; `swap('hexi_winter')`; Gün I doğuş 07:11, batış 16:49 |
| 9.2 | `src/game/nav-patches.js`, `src/game/nav.js`, `src/game/structure-nav.js`, `test/nav-patches.test.js` | `NavView`; 100 m, 0,5 m hücre, 3×3 bellekte; uzak tıklama yol grafı; `sb`, `st`; `canPlace(shapes)` (K23) iki ızgarada | A* ≤2 ms; ızgara dikişinde takılma yok; `canPlace` ≤3 ms |
| 9.3 | `src/world/road.js`, `src/game/travel-data.js`, `test/road.test.js` | `travel.md` §4, §12; `r_whistle_ordu`; `LOCKS`'ta `weather` (7. sıra); yol olayları `ev_storm`, `ev_dust`, `ev_flood`, `ev_snowbound`, III'ten `ev_raid` | `travel.md` T1 uzunlukları ±%0,5; §4.4 Dijkstra tablosu |
| 9.4 | `src/world/weather.js`, `src/world/weather-hooks.js`, `src/world/world.js`, `src/world/sky.js`, `src/world/flora.js`, `src/world/grass.js`, `src/world/fire.js`, `src/world/camp.js`, `src/world/terrain.js`, `src/core/post.js`, `src/core/paint-material.js` | K22, `weather.md` §9: `WeatherView.compose` (tek ışık yazıcısı), yağış ve sıçrama noktaları (kar 6000), yıldırım şeridi, ekran yağışı (FINAL), şimşek nabzı (ışık eklenmez), bulut örtüsü ve cephe hattı, kubbe, ıslaklık kancaları, rüzgâr (çim, ağaç, duman, bayrak, alev); Tipi ve Kara Boran sisi; kış ormanı; `world.tallThings` ağaçları | §7 bütçesi (hava en kötü +2 çizim, +96 üçgen); `menuDiff` 0; program +2 (≤92); W12–W18, W25 |
| 9.5 | `src/character/puppet.js`, `src/character/draft.js`, `src/world/cart.js` | `army.md` §7.3 sözleşmesi; `felt2w`; duran `camp_stop` arabası (`travel.md` §10.3) | ≤6k üçgen, 2 çizim; kukla ≤1.200; `camp_stop` nav kabulü |
| 9.6 | `src/world/structure-defs.js`, `src/world/structure-shader.js`, `src/world/structure.js` | `winter`, `closed`; 21 kapalı LOD; `rot` ve iç tasarım eşlemesi, iç eşya ≤12k (`structures.md` §13.5); K22: `FELT_WET`, ateşli ok tutuşma çarpanı, `world.tallThings` aday kaydı, Bağla / Çöz, `galeDamage`; K23: `scale` (Otağ ×1,4), görünüm kaydı (`KITS`, 9.10), uzak yurdun `YurtField`'e devri (`closed` örneği, `aCut`, `aChar`), ≤48 canlı yapı | ≤185k, ≤40 çizim; `structures.md` §17 1, 5, 10 değişmez; §17 11–14 (K22), 16 (Otağ) ve 17 (`YurtField` devri) |
| 9.7 | `src/character/looks.js` | `act1.md` §3 kadro `Folk` tanımları, hayvanlar | 22 `Folk` tanımı kurulur, 13,9–24,8k üçgen |
| 9.8 | `src/audio/sfx/weather.js`, `src/audio/ambience.js`, `src/audio/sfx.js`, `src/audio/engine.js`, `src/ui/hud/weather.js`, `src/ui/css/weather.css`, `src/core/settings-schema.js`, `src/ui/menu/pages/settings.js`, `test/settings.test.js` | `weather.md` §10, §11: altı hava döngüsü (cepheyle pişer), yedi efekt, HUD simgesi ve işaret satırı, `a11y.flashes`; yerleşimin dört döngüsü (`hold_day`, `herd_flock`, `camp_army`, `gathering_crowd`); `sfx.release(ids)`, `ambience.release(ids)`, `ambience.set` satırında `lp` (`far_rain`), motorun `duck(bus, dB, seconds)` inişi (`audio.md` §4); `test/settings.test.js` tablosuna `a11y.flashes` | W19–W21; Serbest Gez fırtınasında canlı düğüm ≤37 (tavan 40); kampta fırtınalı akşamda ve 23:00'ten sonra önbellek ≤16 MiB, fırın girişi düşürmeden |
| 9.9 | `src/game/settlement/index.js`, `src/game/settlement/plan.js`, `src/world/settlement-view.js`, `src/world/specs/sandbox.js`, `src/ui/hud/plan-bar.js`, `src/ui/css/hold.css`, `src/audio/sfx/settlement.js`, `src/audio/music-states.js`, `test/phrases.test.js` | K23, §3.27, `settlement.md` §13, §14, §18: `SettlementSystem` (64), Plan Kipi (`plan` bağlamı, `sites.beginPlacement`, parsel ve yer kuralları), `YurtField`, `KitField` (tek `BatchedMesh`), parsel çıkartması, sürü örnekleri; kum havuzunun yerleşim kipi `sandbox_hold`; sekiz yerleşim efekti; `hold`, `hold_night`, `court`, `muster` (efektler ve müzik durumları faz çıkışını ve K11 kapısını bekletmez, bitmezse Faz 13'e kayar); `hold` ve `hold_night` `ambient: true`, `{ role: 'bell', p: 0.4, vel: 0.24 }` partisi ve `rain: { gain: 0 }` katmanıyla; `test/phrases.test.js` `IDS`'e `hold`, `hold_night`, `court`, `muster` (21 durum) | 20 yurt Plan Kipi'yle; 200 rastgele yerleşimde bağlantı kopmaz; ×240 hızla 10 gün (Kâhya; kervan ve baskın 8.13'ün o modülleri hazırsa); `hold.synth(5, 'walled')` ve `synth(5, 'moving')` karesi §7 satırında; yerleşim dünyasında program +6 (≤92); `structures.md` §17 18 |
| 9.10 | `src/world/structure-kits.js`, `src/world/site-pad.js` | K23 yapı görünüşleri (`structures.md` §4.6): `yard`, `mound`, `ring`, `post`, `field` aileleri; `shed` `open`/`walled`, `tower` `low`/`gate`/`granary`, `fence` `picket`/`stockade`; tür başına `KitField` kaba ağı (≤400 üçgen); `PadField` (örnekli hafif ped; camp3'ün tuvali yalnız camp3'te) | `structures.md` §17 15: her tür kum havuzunda kurulur, vurulur, geri düşer; ≤6k üçgen, ≤2 çizim; program eklemez (`struct_parts`, `struct_props`) |

`L`: `src/app/sounds.js` (hava döngü birleşimi; kış ve yerleşim dünyalarının ortamı ve gündelik müziği, `audio.md` §3; `audio.md` §4 «Bellek» bırakmaları: `birds_day` `herd` işaretinde `ambience.release`, cephe geçince Tan'dan önce yeniden pişer; camp3 bitmişse `torch_post` pişmez, bitince `sfx.release`), `src/game/weather.js` (yakın yıldırım inişleri `audio.duck` ile, `audio.md` §4), `src/app/devtools.js` (`drawMenuFrame`'in hava saklaması görünümle sınanır), `src/app/states/freeroam.js` (`roam.weather` görünümle; iniş ve dönüş karışımı havayı da kapsar), `src/app/systems.js` (`SettlementSystem` 64, `ctx.settlement`), `src/app/app.js` (`?sandbox=site&hold=1` → `sandbox_hold`; `WeatherBadge` `tr` yuvasına takılır).

**Paket bağları.** 9.4 8.9'un `writeLight`'ını devralır; 9.1 `SNOW_FRESH`'i 9.4'ten, 9.6 `KITS`'in `build` ve `look`'unu 9.10'dan ve `YurtField` yuvasını 9.9'dan, 9.9 `KITS`'in `coarse`'unu 9.10'dan, `SiteSystem`'i (8.12), yerleşim çekirdeğini (8.13) ve `canPlace`'i (9.2) sözleşmeyle alır.

**Çıkış:** `?state=play&zone=hexi_winter`: boş Kışlak, gündüz ve gece saatle, kar ve hava, §7 bütçesi ölçülür; Serbest Gez'de fırtına, yıldırım ve dolu, menüye dönüş `menuDiff` 0; kum havuzunda yerleşim kipi Plan Kipi'yle kurulur.

### Faz 10: Hikâye sistemleri

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 10.1 | `src/game/quests.js`, `src/game/regions.js`, `src/game/jobs.js`, `test/quests.test.js`, `test/regions.test.js`, `test/jobs.test.js` | §3.14, §4.1; `act1.md` §2; İş Tahtası hikâye günü başına 3 iş | Rütbe tablosu; vakit ve uyku kapısı `calendar` (8.9) ile |
| 10.2 | `src/game/dialogue.js`, `src/ui/dialogue-ui.js`, `src/ui/css/dialogue.css`, `test/dialogue.test.js` | §3.15, §4.2, §4.5 örneği | Örnek görev sahte servisle baştan sona |
| 10.3 | `src/game/schedule.js`, `src/game/npcs.js`, `test/schedule.test.js` | §3.16; `act1.md` §5, `time.md` §9.4: dakika blokları, `onBlock`, hava sığınması (`weather.md` §8.12) | ≤16 tam kişi; kadrajda sıçrama yok; Kışlak'ta 22 kişi her blokta yerde; bölge gece hâli 19:30–06:40 |
| 10.4 | `src/game/stealth-core.js`, `src/game/stealth.js`, `src/world/track-decals.js`, `test/stealth.test.js` | §3.16; `act1.md` §9.5; «Karanlık» `worldClock.dark` ve ışık havuzu, şimşek nabzında kapalı; `fx.vis`, `fogK`, `hearK`, koni çarpanı; iz ömrü `fx.trackK` | `progression.md` §17.1 #5, #6, #16; koni 68°, 60°, 56° (W7) |
| 10.5 | `src/game/travel.js`, `src/game/lanes.js`, `src/game/game.js`, `src/ui/roadcard.js`, `src/ui/css/roadcard.css`, `src/app/states/travel.js`, `src/map/routes.js`, `src/map/atlas.js`, `src/i18n/strings/travel.js`, `src/game/child.js`, `test/travel.test.js` | §3.17; `game.seat`; `travel.md` §16 adım 4–13; `camp_stop` sürücü satırı; saatin doğal süresi ve `k`, atlas bacağında `clock:skip { reason: 'travel' }` (24 saati aşınca uzun atlama), `lock.weather`; kervanın atlas arabası (`ctx.settlement.caravans()`) | T3–T11 |
| 10.6 | `src/game/squad/index.js`, `src/game/squad/squad.js`, `src/game/squad/follower.js`, `src/game/squad/formation.js`, `src/game/squad/army-data.js`, `src/game/squad/crowd.js`, `src/game/squad/demo.js`, `src/i18n/strings/army.js`, `test/formation.test.js`, `test/army-data.test.js` | `army.md` §11.1; `fx.fatigueK` (Han ×2), salvo rüzgârı ve ıslak kiriş, ay olayları `calendar.moonIllum`'dan, öğünler 07:00 ve 18:00 (`weather.md` §8.13, `time.md` §10.7) | `army.md` §11.1 kabul 1–11 |
| 10.7 | `src/ui/journal.js`, `src/ui/info-card.js`, `src/ui/css/journal.css`, `src/ui/hud/trust.js`, `src/ui/hud/axes.js`, `src/ui/hud/squad-bar.js`, `src/i18n/strings/quests.js` | Görevler (vakitler evreyle, «Seni çağırıyorlar.»), kural kartı, Çentik, kor | Kut ve Korku sayı göstermez |
| 10.8 | `src/app/states/play.js`, `src/game/journey.js`, `test/journey.test.js` | Yeni yolculuk, kayıt blokları (sıra 69–78, 92), `act_change` (`act:change` olayı; tarih `ACT_START`'a uzun atlamayla), `ACT1_READY`; `CondCtx`: `hour`, `dark`, `moon`, `phase:`, `beat:`, `ledger.<line>` | Kaydet, yükle, `derive` aynı; perde geçişi ≤150 ms / mevsim |
| 10.9 | `src/story/proto/index.js`, `src/story/proto/day1.js`, `src/story/proto/blizzard.js` | Dikey dilim: Gün I'in ilk 15 dakikası (`act1.md` §12) ve Tipi prototipi (T1–T2, takipçi `TRAIL`, `SHOOT`; `act1.md` §10), taslak veri; `?state=play&zone=hexi_winter&proto=1` | `L` oynar, süre ve kare ölçülür; Gün I saatle (öğle çanı 12:00, `mq_ration` 13:30'da karartmayla götürür) |
| 10.10 | `src/ui/hold-ledger.js`, `src/ui/css/hold-ledger.css`, `src/ui/menu/book-glyphs.js`, `src/game/settlement/index.js` | Yerleşim Defteri bütün bölümleri ve sayfa biçemi (`settlement.md` §14.2); kervan bağı (kum havuzunun iki ucu arasında saatle). K11 kapısını bekletmez; bitmezse Faz 13'e kayar (K26) | Her bölüm dolu; kervan, Kâhya ve baskın ×240 hızla 10 gün; kaydet, yükle aynı |

`L`: `src/app/systems.js` bütün sistemleri kaydeder; `src/app/app.js` `ctx` alanları; `act:change` (10.8) yerleşimin Kronik'ine bağlanır.

**Çıkış:** Boş Kışlak'ta örnek görev, araba, nöbetçi, Ku oynanır; kayıt her durumda açılır.

**Kapı.** Faz 10 sonunda Gün I + Tipi prototipi oynanır, Faz 11 buna göre açılır: `L` tempo, okunurluk ve kare sonuçlarıyla paket kapsamını yazar. `src/story/proto/` Faz 11 açılınca silinir. Kapıda ayrıca saatli Gün I ölçülür: vakit çağrısı ve karartmayla götürme, öğle çanı 12:00, ilk 15 dakikanın Yar Bakışı'na 15:00 ±30 dk'da varışı; Tipi prototipinde `kara_boran` hava kilidi ve `pinFx`. Kapının yeri değişmez (K11).

### Faz 11: I. Perde içeriği

İçerik paketleri yalnız kendi klasörünü yazar. `L`: `src/story/act1/index.js` boş dizinlerle faz başında kurulur; VO `node tools/voices.mjs gen`; `public/audio/vo/`.

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 11.1 | `src/story/act1/schedule.js`, `src/story/act1/days.js`, `src/story/act1/guards.js`, `src/story/act1/regions.js`, `src/story/act1/jobs.js` | `act1.md` §2, §4, §5; `time.md` §9.2, §9.4: hikâye günleri, vakitler, dakika blokları | Bütün kişiler her saat bloğunda yerde; her günün ana işi gece de yapılabilir |
| 11.2 | `src/story/act1/day1/index.js`, `src/story/act1/day1/quests.js`, `src/story/act1/day1/dialogue.js`, `src/story/act1/day1/cine.js` | Gün I, ilk 15 dakika (`act1.md` §12); hava kilidi `a1_road_in` | Dakika tablosu ±%20; saat eşlemesi `time.md` §9.8 |
| 11.3 | `src/story/act1/day2/index.js`, `src/story/act1/day2/quests.js`, `src/story/act1/day2/dialogue.js`, `src/story/act1/day2/cine.js` | Gün II | |
| 11.4 | `src/story/act1/day3/index.js`, `src/story/act1/day3/quests.js`, `src/story/act1/day3/dialogue.js`, `src/story/act1/day3/cine.js` | Gün III, Tündük (Kışlak Yeni Yurdu `crown_raised` kapısı), Elçi, Av | |
| 11.5 | `src/story/act1/day4/index.js`, `src/story/act1/day4/quests.js`, `src/story/act1/day4/dialogue.js`, `src/story/act1/day4/cine.js`, `src/game/raid.js` | Toy, baskın, 6 dk saat; dolunay Gün IV 18:00; `b_feast` `ensureStage(7)` ve `feast_ember` kapısı; hava kilidi `a1_feast_raid` | `act1.md` §15 bütçesi |
| 11.6 | `src/story/act1/day5/index.js`, `src/story/act1/day5/quests.js`, `src/story/act1/day5/dialogue.js`, `src/story/act1/day5/cine.js` | Kül, Göz Yolu, hüküm, Son Aş; Nanay'ın yaması 07:00–08:42 (275 İD); hüküm Göz Yolu'nun sonunda (`run` sinemasından sonra sahne sırayla bağlanır, `time.md` §6.4) | |
| 11.7 | `src/story/act1/night/index.js`, `src/story/act1/night/quests.js`, `src/story/act1/night/dialogue.js`, `src/story/act1/night/cine.js`, `src/game/moon-clock.js`, `src/game/frozen-camp.js`, `src/ui/hud/clock.js` (Gök Kavisi'nin Ay Saati kipi; dosya 8.9'da yazıldı, Faz 11'de yalnız 11.7 dokunur) | Son Gece, Donuk Kamp, Kül Borcu, Gök (Yar Bakışı), Adak Aygırı; jest gerekirse 11.8'e istek | Buz saati her zorlukta 06:40 (Amaga Normal 20:00, Zor 21:30; Hikâye 05:45 bekleyişi); saat biterse `dawn_path` |
| 11.8 | `src/story/act1/blizzard/index.js`, `src/story/act1/blizzard/quests.js`, `src/story/act1/blizzard/dialogue.js`, `src/story/act1/blizzard/cine.js`, `src/game/pursuit.js`, `src/game/boss-farnak.js`, `src/character/gestures/story.js` | Kara Boran (hava kilidi `kara_boran`, `pinFx`), Boğaz, Ses; jestler `sign` vb. | Temiz sürüş ≥3 dk; ≤1,2M üçgen |
| 11.9 | `src/story/act1/end/index.js`, `src/story/act1/end/quests.js`, `src/story/act1/end/dialogue.js`, `src/story/act1/end/cine.js`, `src/ui/act-card.js`, `src/ui/css/act-card.css`, `src/app/states/home.js`, `src/data/destan.js` | Eşik, `home` kipi (§2.3), perde kartı, II. Perde kancaları; Destan Kitabı `kurgu tercihi` girdileri: yalnız uydurulan kişi ve kurumlar, Tengri, Erlik, Umay mitolojidir | `act1.md` §16 bayraklarının hepsi kayıtta |
| 11.10 | `src/story/act1/side/index.js`, `src/story/act1/side/quests.js`, `src/story/act1/side/dialogue.js` | 23 yan görev | XP toplamı 1.580 |

**Çıkış:** `act1.md` §6–§8 oynanır; XP 2.460 + 1.580 + 405 + 130; §13 üç zorluk.

### Faz 12: Performans ve kapanış

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 12.1 | `src/core/post.js`, `src/world/world.js`, `src/world/fire.js` | Gölge kadansı, tam ekran çözünürlük geçişi takılması; `spec.postCuts`: menü bitişiğinde render hedefi sabit; `?q=low`; hava kesintileri (§7 sıra 8), `video.quality` low onları baştan uygular | §7 tablosu |
| 12.2 | `src/core/input.js`, `src/core/keymap.js`, `src/ui/hud.js` | Oyun kolu, Buyruk Halkası, dokunmatik tarama; Bekle tekeri ve Plan Kipi kol eşlemesi | `menu-spec.md` kol tablosu |
| 12.3 | `src/world/terrain.js`, `src/world/paint-ground.worker.js` | `paintGround` `OffscreenCanvas` işçisi; `menuDiff` | Kurulum ≤4 sn tipik |
| 12.4 | `tools/check-budget.mjs` | Sahne başına `perf()` eşikleri; Serbest Gez fırtınası, yerleşim (`synth(5, …)`), Kışlak yoğun kar | Geçer |

`L`: `src/character/hero.js`, `src/ui/creator.js` silinir, son anlık görüntüden sonra.

### Faz 13: II. Perde açılışı, yerleşim ve ordugâh dünyaları (taslak)

K23: hikâye açılışı II. Perde'dir. Faz 12 bitince açılır; paket kapsamını `L` Faz 12 sonunda kesinleştirir. Ayrıntı `settlement.md` §2, §3, §10, §19; `d2/core.md` §4.2, §4.10. II. Perde'nin iki büyüme yayı burada paketlidir: ordugâh (Onluk Ateşi → Yüzlük Kampı, 13.4) ve yerleşim (Ocak → Oba, 13.5). Darbe ve öteki hikâye içerikleri `army.md` II. Perde planıyla ayrıca yazılır. Faz 8–10'da bitmeyen II–VI parçaları (`court`, `chronicle`, `raids`, `caravans`, `camps`, yerleşim müzik durumları ve `sfx/settlement.js`, Yerleşim Defteri) bu fazın başında, kendi dosyalarıyla bitirilir (K26).

| Paket | Dosyalar | İş | Bitti |
|---|---|---|---|
| 13.1 | `src/world/specs/tanhu-ordu.js`, `src/world/specs/tanhu-ordu-layout.js` | `tanhu_ordu` 1400×1050 m: Karasu deresi, Kutlu Tepe, üç Ocak Yeri ve önceden kırpılmış parselleri, düğüm kümeleri (`c_birch_hill` dahil), kapılar; `spec.settlement` (`kind: 'hold'`), `steppe_south`, enlem 43,5° | Kurulum ≤8 sn; `settlement.md` §3.2 uzaklıkları gerçek nav'la ±%5; program ≤92 |
| 13.2 | `src/world/specs/whistle-field.js`, `src/world/specs/whistle-field-layout.js` | `whistle_field`: Pınarlar, talim ovası, ordugâh parselleri, Bakış Sırtı; `spec.settlement` (`kind: 'camp'`), `gobi`, enlem 44,2° | Tümen dizilişi sığar (`army.md` §4.2); program ≤92 |
| 13.3 | `src/story/act2/opening/index.js`, `src/story/act2/opening/quests.js`, `src/story/act2/opening/dialogue.js`, `src/story/act2/opening/cine.js` | `mq2_allotment` sineması (K7 `home` sahnesinin devamı, Tanhu Kampı'nda uzak kare, K106), Köz Kabı, `mq2_own_hearth` (Ocak Yeri seçimi, 48 saat köz, Mete'nin yurdu ilk onlukla), Teoman'ın armağanı (`yurt_kit`, `cart_felt`, ≈30 at eşdeğeri sürü) | Ana kampta Mete oynanmaz (K6); Ocak kademesi açılır; ilk Kronik II'nin açılış tabanını verir; armağan 60 yün, 6 külçe ve ≈217 öğünlük azıkla gelir, ilk şafakta yiyecek çizgisi ≥%50 |
| 13.4 | `src/world/tent-field.js`, `src/story/act2/camp/index.js`, `src/story/act2/camp/quests.js`, `src/story/act2/camp/dialogue.js`, `tools/check-budget.mjs` | Islık Ordugâhı: `CampPlan` çadırları (yerleşik atlının kendi `tent_kit`'leri), Talim Alanı, ilk talim, `mq2_whistle_camp`; Buyruk Yurdu, Erzak Ambarı, Silahlık ve Yüzlük Kampı; `TentField` (`KitField` deseni: tek örnekli çizim + gölge, çadır başına ≤200 üçgen, program eklemez, yerleşim dünyasının `kit_field` programını paylaşır; 40 m ötesi çadırlar) | Onluk Ateşi → Yüzlük Kampı kademe geçişi; Binlik deneme dizilişinde ≤323 çizim, ≤2,74M üçgen; program ≤92; `check-budget` ordugâh (Binlik) eşiği geçer |
| 13.5 | `src/story/act2/oba/index.js`, `src/story/act2/oba/quests.js`, `src/story/act2/oba/dialogue.js` | İlk aileler ve Oba: `hh_story` (dülger hanesi, Ağaç Atölyesi), `mq2_oba` dalgası (demirci dahil dört hane, yurt yükleri, 5 günlük azık, son kırkımın yarısı), Oba kapısı (`settlement.md` §4.1); Tanhu pazarcısının iki günde bir gelişi | Oynanan bir koşuda Oba kademesine II. Perde'nin 12 ±%30 gününde ulaşılır; yün, külçe ve usta yolu kapanmaz (`econ-sim` varlık sınaması) |

`L`: `src/world/specs/index.js`, `src/world/specs/zones.js` (`tanhu_ordu`, `whistle_field` adları ve yükleyicileri), `src/story/act2/index.js`, `src/story/vo-lines.js` (`ACTS`), `src/app/systems.js`.

**Çıkış:** II. Perde açılır: pay, Köz Kabı, Ocak Yeri; yerleşim ve ana ordugâh iki ayrı dünya olarak kurulur, kervan aralarında saatle gider; Ocak → Oba ve Onluk Ateşi → Yüzlük Kampı bir oynanışta perde günü içinde biter.

## 6. Test planı

### 6.1 `node:test` ile saf modüller

Komut: `node --test "test/*.test.js"` (K18; Node 24'te `node --test test/` ancak `test/index.js` sayesinde açılır, aynı sınamaları koşar). DOM yok; yarı saf modüller dışında `three` yok; istisna `rig` ve `child`: gerçek `three` matematiği, GL istemez, `child` `Dust` kurulumu için `document` taklidi verir. Beklenen değerler alan belgelerindeki kabul tablolarıdır; yeni sayı uydurulmaz.

| Test | Modül | Kaynak |
|---|---|---|
| `bus`, `store`, `settings` | `core/bus`, `core/store`, `core/settings`, `core/settings-schema`, `core/clock` | §3.1, §3.4 |
| `input` | `core/input`, `core/keymap` | §3.2'nin 7 maddesi; `E` ile kapanış yeniden tetiklemez |
| `i18n` | `i18n/index`, `i18n/format` | İ/I büyük harf, eksik anahtar |
| `timeline`, `cine` | `core/timeline`, `core/ease`, `game/cine` (çekirdek) | Göreli `t`, cue sırası, atlama; `clock` izi (`set`, `atLeast`, `advance`, `run`) yalnız ileri ve atlamada da uygulanır; `weather` satırı, `release()` kilidi kaldırır |
| `cond`, `flags`, `effects` | `game/cond`, `game/flags`, `game/effects` | `progression.md` §4.1 dili; §3.14 tablosu; `phase:`, `beat:`, `hour`, `dark`, `moon`; `clock` yalnız ileri, `hold` yalnız iki bekleyiş; `weather` op'u (hava yokken yok sayılır); `ledger` yeri (`own_seat` …) |
| `damage`, `combat` | `game/damage`, `data/damage-tables`, `game/combat` (çekirdek) | `progression.md` §17.1 #8–#10, #13 |
| `save`, `journey` | `game/save`, `game/journey` | `progression.md` §17.1 #21–#23, §13.3 |
| `progress` | `game/progress` | `progression.md` §17.1 #1, #3, #15–#20, #24 |
| `derive` | `game/derive`, `data/skills`, `data/gear` | `progression.md` §2.4 tablosu; §17.1 #2, #4–#7, #14, #25–#27 |
| `structure-logic` | `world/structure-logic`, `world/structure-defs` (emek `labour-model.json` ile aynı) | `structures.md` §5.3, §6.1; `progression.md` §17.1 #11, #12; `advance(wm)` 1.376 İD'de biter, 13 adım sırası aynı; `credit(wm)` çarpansız; onarım emekleri İD; parça ve ham teslim (`rawWork`), bohça açma; `v: 2` göçü |
| `builders` | `game/builders` (sahte aktör ve sahte yapı, gerçek `StructureState`), `character/gestures/build`, `i18n/strings/structures` | `structures.md` §10, §11.6: saatsiz yardımsız 1.434 sn ±10 (Dengiz'in iki su ve dört kütük seferiyle), Çocuğun bütün yardımıyla 1.188 sn ±10; 14:54 saatiyle ve öğünle 1.503 ve 1.244 sn ±15, açık havaya iğneli; Dengiz her adımda; aile ocak yanana dek ateşte (en geç 01:30, aşama ≥6 ise 03:00; aşarsa ocak 05:00'te; `camp3:family_wait`, `camp3:hearth_dawn`); «Gece dinlenilsin» ile ertesi sabah ≈08:55; `SHELTER`'da emek durur; takılan usta en çok 6 sn bekletir; dizgeler TR ve EN |
| `labour` | `game/labour` | `d2/core.md` §2: `eff` tablosu; tek el 1.440 İD, ekip 1.376 İD; ekip çizelgesi ±0,05 dk ve kesin azalan; karışık ekipler; önder ve usta kuralı; gece sınıfı çarpanı; hava durakları; onarım; taşıma (146 Yük 50 m: 8 sefer, 224 İD); toplu benzetim eşdeğerliği (600 × 1 dk = 600 dk ±1e−6); söküm 0,35; `dayCapacity`; `etaWords`; `labour-model.json` ile aynı sayılar |
| `sites` | `game/site-core` (saf), `game/sites` (sahte dünya) | Yerleşim nedenleri; yığın tüketimi ve bekleme nedeni; 150 m kendi taşıması; gece emri; çalışma atlaması; yerleşimli zonda atlamanın tek sahibi; kayıt gidiş dönüş (baskın sonrası en kötü durum ≤20 KB); Kışlak benzetimi `d2/core.md` §2.12 yolunu ±2 oyun dk |
| `nav`, `nav-layers`, `nav-patches` | `game/nav`, `game/nav-patches`, `core/shapes` | `structures.md` §12; `army.md` `maxSteps` |
| `interact`, `camera-rig`, `agent-move` | `game/interact`, `game/camera-rig`, `game/agent-move` | Öncelik; `army.md` §5.6 durma testi: dönüş 0 rad |
| `rig` | `character/rig`, `character/gestures/*` | 7 eski jest bit bit aynı; `carry`, `benchK` (`travel.md` §3.4), `spec.ride`, `seatHeight` |
| `child` | `game/child`, `game/game`, `game/mounted` (sahte dünya, gerçek kamp arazisi) | `progression.md` §2.5: çit, korkuluk, zıplama tepesi; §3.7 çömelme, kalkış, silah, `moveMods` |
| `inventory`, `container`, `needs`, `craft`, `supply`, `herds`, `loot`, `gather` | `game/inventory`, `game/container`, `game/items`, `game/needs`, `game/craft`, `game/barter`, `game/supply`, `game/herds`, `game/loot`, `game/gather` (çekirdek) | `economy.md` §4.1, §7 senaryo tablosu, §10; `economy.md` §12 Sınamalar (K24; `armyShare` düz %10; `loot.of` belirli, insan yok); Tokluk oyun dakikasıyla (uyku ×0,25, ateş başı ×0,5, `diff.foodK`) |
| `node-store` | `world/node-store`, `data/node-kinds` | 3.270 kayıt, tohum sabit, `perm` gidiş dönüş; `applyTaken` belirlenimli; atlanan her şafakta bir `onDawn` |
| `cooking` | `game/cooking`, `data/recipes` | `survival.md` §3 |
| `terrain-field` | `world/terrain-field` | 1.000 noktada altın değer: 7.1'den önce bugünkü koddan yazılır |
| `road`, `travel` | `world/road`, `game/travel-data`, `game/travel` (çekirdek) | `travel.md` T1, T6, §4.4 |
| `quests`, `dialogue`, `schema`, `vo-lines` | `game/quests`, `game/dialogue`, `story/*` | §4.5 örneği baştan sona; `voBudget` |
| `world-clock`, `daylight`, `sky-keys`, `calendar` | `game/world-clock`, `game/daylight`, `game/calendar` | `time.md` §17: gün ışığı altın değerleri (Hexi Gün I doğuş 07:11, batış 16:49; kamp 05:22 / 18:38), menü vektörü (sapma +7,4223°, 11 Nisan, 14:46,2; 1e−5), `skyAt(886.18)` 4,3 ve `applyMood(0,3)` ile aynı renkler, `lightLevel` başvuruları ve `nightClass` eşikleri; duvar tavanı 0,25 sn, bekleyiş, atlama olay sırası, uzun atlamada tek `clock:skip`; buz saati her zorlukta 06:40, Zor Düğüm 21:40, Hikâye 05:45 bekleyişi; dolunay Gün IV 18:00; `dayN` 1.041 → MÖ 210; `ACT_START` |
| `weather-core`, `weather-fx`, `weather-strike` | `game/weather-core`, `data/weather-types`, `data/climates`, `i18n/strings/weather` | `weather.md` §15 W1–W11, W26 (kural sırası, I. Perde kabuk 0, yalnız `steppe_south` ve `gobi`'ye mutlak tolerans; dosyayı üreteç yazar, sınama yazmaz); camp3 bitene dek kampta `sev` ≤2; belirlenim, 38 iklim satırında ≤1,5 puan, süre ve cephe, kilit ve `pinFx`, I. Perde sayıları, etki matrisi, ıslaklık, yıldırım adaleti, ses gecikmesi, K1 (oyuncu metninde soğuk ve sıcak yok), kar örtüsü ve Kar Kabuğu payları |
| `settlement`, `settlement-ii` | `data/settlement`, `game/settlement/*` (saf; sahte `SiteSystem`, takvim ve hava) | `settlement.md` §21 1–19: veri bütünlüğü, kademe, Çekim, katılım, Gönül, esir yok, Kâhya, tüketim, kap ve baskın, kervan, ordugâh, toplantı, yer kuralları, atlama eşdeğerliği, kayıt boyutu (90 hane ve 160 yapıyla `settlement` ≤14 KB, `camps` ≤4 KB), küme, ayrı defterler, Kronik, bakım |
| `regions`, `jobs` | `game/regions`, `game/jobs` | `act1.md` §2; İş Tahtası hikâye günü başına 3 iş |
| `player` | `game/player` (çekirdek) | `progression.md` §3 Yara ve Düşüş; §12 yara sınırı |
| `schedule`, `stealth` | `game/schedule`, `game/stealth-core` | `act1.md` §5, §9.5; `progression.md` §17.1 #5, #6, #16; dakika blokları ve `onBlock`, bölge gece hâli 19:30–06:40; koni 68°, 60°, 56°; «Karanlık» `worldClock.dark`, şimşekte kapalı |
| `formation`, `army-data` | `game/squad/formation`, `game/squad/army-data` | `army.md` §4.1; §6.3 `obey` tablosu; `reflex` 3 → `discipline` 34 |
| `phrases` | `audio/phrases`, `audio/music-states` | Motif A G F D, D Dorian, aynı anda ≤2 tel, akor yok, tohum belirlenimli |
| `menu` | `ui/menu/main-menu`, `save-card`, `knot-button`, `ornament` (yalnız saf yardımcıları; `.css` içe aktarımı Node yükleyici kancasıyla boş modül), `i18n/strings/menu` | `menu-spec.md` §3 yerleşim tablosu, `k`, kart konumu, gezinme, açılış süresi, dizgeler, kart metni |
| `book` | `data/destan`, `i18n/strings/book`, `ui/menu/pages/controls` (saf yardımcılar) | Destan, Kişiler, Taşlar açılışı ve yeni metin; `RoamTracker`, `placeAt`; tuş listesi gerçek keymap'i ve yeniden atamayı izler |
| `save-panel` | `ui/menu/save-panel` (saf yardımcılar), `game/save`, `i18n/strings/save` | `menu-spec.md` §4 kartları, bozuk yuva, `journeyState`, `save:failed` metinleri, klavye düzeni, açılış odağı |
| `geography` | `map/geography` | Tekil kimlik, `unlock` derlenir, görünür metinde genel grup sözcüğü yok |

**Saf listesi** (`tools/check-pure.mjs` tarar): `core/{bus,store,clock,settings,settings-schema,keymap,input,timeline,ease,math,shapes}`, `i18n/{index,format}`, `i18n/strings/*`, `audio/{phrases,music-states}`, `data/*`, `story/*`, `map/geography`, `world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line,weather-hooks}`, `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,container,needs,craft,supply,barter,herds,loot,cooking,calendar,world-clock,daylight,weather-core,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches,labour,site-core}`, `game/settlement/{state,households,steward,stores,production,caravans,raids,camps,court,chronicle}`, `game/squad/{formation,army-data}`. `structure-defs` GLSL değil yalnız veri taşır. **Yarı saf:** `gather`, `dialogue`, `combat`, `regions`, `journey`, `cine`, `travel`, `player` yalnız `three` matematik sınıflarını (`Vector3`, `PerspectiveCamera`) içe aktarabilir; DOM ve GL kullanmaz, testte sahte servisle kurulur (`three` Node'da açılır, GL istemez).

### 6.2 Statik denetim

| Komut | Denetler |
|---|---|
| `node tools/check-pure.mjs` | §0 kural 5 |
| `node tools/check-i18n.mjs` | Her anahtarda TR ve EN, boş yok; `{tr,en}` veri satırlarının ikisi de dolu; `Kampa gir` gibi tek dil dizge yok (`src` altında kod dışı Türkçe metin taraması) |
| `node tools/check-data.mjs` | `schema` geçer; `next`, `quest`, `dialogue`, `cine`, `item`, `skill`, `sfx`, `music`, `structure` kimlikleri var; `when` derlenir; `mods` anahtarının okuyucusu var (`progression.md` kural 1); yazılan her bayrağın okuyanı var ya da `act1.md` §16'da; XP toplamları 2.460, 1.580; `voBudget` ≤45.000 (Act 0 + Act 1; K61 ile değişti: tavan kalktı, rapor kalır, yalnız yapı kuralında düşer, §4.4); hava türü kimlikleri (etki, sinema, kilit), sinemanın `clock` izi, `story/act1/days.js` (`StoryDay`, vakit pencereleri sıralı ve zincirli); `data/items.js` ve `data/craft-recipes.js` kimlik ve sayılarının `d2/econ-model.json` ile, `data/settlement.js`'in `d2/settlement-model.json` ile eşitliği; başvurulan efekt kimlikleri (`torch_post`, saat, hava, ekonomi, yerleşim reçeteleri) |
| `node tools/econ-sim.mjs --strict` | K24 denge modeli (`d2/econ-model.json`, `d2/settlement-model.json`, `d2/weather-model.json`): kimlik ve etiket tutarlılığı, bohça ağırlığı, el işi tutuşu; malzeme, yapı, kademe ve perde hedefleri (kademe günü T1 2–5 … T5 4–12); kış payı %75–115; perde başına baskın kaybı ≤%10; tarif Kıymet bandı; I. Perde sözleşmesi (yurt 54 birim, 146 Yük, parça biçiminin ham biçime eşitliği). Betiği yalnız ekonomi alanı yazar |
| `node --test "test/*.test.js"` | §6.1 |
| `NPM_CONFIG_CACHE="$TMPDIR/npm-cache" npx vite build` | Üretim paketi; `demo.js` pakete girmez |

### 6.3 Tarayıcıda: `window.__tanhu`

Gizli panelde rAF durur; kare `__tanhu.step(ms, n)` ile ilerler. Eski adlar korunur (`renderer, world, game, stage, hero, post, ui, THREE, goTo, step, atlas, toggleMap`); `hero` artık `game.actor`; `world` ve `stage` alıcıdır, `stage` oluşturucu açılana dek `undefined`.

```js
__tanhu = {
  app, ctx, renderer, THREE, post, game, atlas, hud, get stage(), get world(), get hero(), ui,
  goTo(state, opts), toggleMap(), step(ms, n),
  state(),               // { state, pending, fade, time, inputStack: [...] }
  freeze(t), unfreeze(), // clock.manual, U.uTime sabit; rAF kare ilerletmez, yalnız step
  shot({ w, h }),        // → Promise: bir kare çizer (step(0, 1)), onun data URL'si
  menuDiff({ image }),   // → Promise { pixels, maxDelta, changed, ok, counts, image }: docs/baselines ile. Görünüm 1600×900, oran 1, uTime 100, menü sürüklenmesi 0
  perf(),                // Bir ölçüm karesi çizer (dt 0): { calls, tris, main: {...}, shadow: {...}, post: {...}, memory: { geometries, textures, programs }, jsMs: { sistem: ms } }
  events(n),             // bus.history
  register(name, panel), // paket kendi panelini ekler: devtools.js düzenlenmez
  swap(specId),          // replaceWorld (§2.7) → Promise { ms, before, after }: renderer.info.memory ve program sayısı; ret { error }
  // Paneller
  struct, travel, econ, squads, story, stealth, cine, audio, i18n, save, clock, weather, labour, hold,
};
```

| Panel | Yöntem | Paket |
|---|---|---|
| `struct` | `list, get, setStep, hit, ignite, speed, reset, diff, nav, labour` (`structures.md` §17; `labour(id)` 8.11); ek `setStage, repair, save, json, fx` | 6.3, 8.11 |
| `travel` | `net, open, linkAll, ride, leg, lock, k, lanes, day, slice, stats` (`travel.md` §16) | 10.5 |
| `econ` | `give, setLedger, setNeeds, dawn, nodeStats, showFootprint, ratio` (`economy.md` §12); `put(id, n, containerId)`, `perish()`, `craft(recipeId, n)`, `loot(enemyKind, n)` (§3.26). Yerleşim ambarı, sürü ve kervan `hold`'dadır | 8.3, 8.4 |
| `squads` | `stats, spawn, clear`; `?squad=10` (`army.md` §11.1) | 10.6 |
| `story` | `reveal` (Faz 4, L: Serbest Gez'de `atlas:reveal`, yolculukta `progress.reveal`), `progress`; `flag, axis, quest, step, dialogue, cine, day, slice, rank, give, level` | L, 10.8 |
| `stealth` | `guards, cones, suspicion, noise, pause` | 10.4 |
| `cine` | `play(id), seek(t), skip(), profile(name, blend), clearance(), info(), state()` (`info` + `app`, `pending`, `billboard`), `director` | 5.3, L |
| `audio` | `state, sfx, sfxList, ambience, voices, mute, nodes` | 3.7 |
| `i18n` | `set, missing` | 1.4 |
| `save` | `write, load, dump, corrupt, usage` | 3.3 |
| `clock` | `get, set('hh:mm'), next(phase), skip(min), lapse(h), hold(id, hhmm), release(id), keys, stop` | 8.9 |
| `weather` | `state, set, clear, plan, seed, skip, wind, wet, freeze, calm, flash, thunder, hail, strike, fx, sim, calibrate, budget, identity` (`weather.md` §12.8) | 8.10, 9.4 |
| `labour` | `eff, rate, eta, crew, simulate, weather, night, sandbox` | 8.11, 8.12 |
| `hold` | `give, households, tier, speed, hour, place, assign, steward, raid, weather, caravan, census, budget, plots, synth` (`settlement.md` §19) | 8.13, 9.9 |

**`menuDiff` kuralı.** `pixels`: en büyük kanal farkı 16/255'i aşan piksel sayısı, `ok` ≤32 (§0 kural 8); `changed` bütün farklı pikseller; sayfa yüklemeleri arasında ≤8/255 gürültü görülür (paket 1.5; sekme önde yüklenince, nedeni bulunmadı), sayılmaz. Taban `docs/baselines/menu_1600x900.png` eski koddan alınmıştır. Kare oyuncunun durumundan bağımsızdır: aktör, işaretçi ve toz gizli, statik çocuk görünür (Serbest Gez gizler), odalar kapalı, ışık `MOODS` 0,3 ve zerrede `uDusk` 0 (kurulumdaki ilk `applyMood` zerrelerden önce gelir), titreşim anı 0,0334. Kıvılcım kareler boyunca birikir: taze kurulumun iki karelik çizim durumu ilk kareden önce saklanır, menü karesi hep ondan çizilir (`devtools.js`); birleşik duman (5.2) yalnız saate bağlıdır, saklanacak durumu yoktur. Faz 3'ten beri kare `MenuCamera`'nın ayrı bir örneğiyle çizilir (sürüklenme kapalı, `setAspect(1600/900)`, `reset()`; canlı menünün kamerasına ve süren uçuşa dokunulmaz), `U.uPlayer` menüdeki gibi (0, −100, 0), `post.painterly` ölçümde açık. Taban Faz 3'te bu kareyle yeniden yazıldı (§8 karar 27). Yürüyen at saklanmaz: at ahırdayken geçerlidir.

**`menuDiff` ve saat, hava (K20, K22).** `menuDiff` Serbest Gez sürerken de çalışır (`struct.diff`, `refs.compare`). `drawMenuFrame` çizmeden önce (Faz 7'nin `moodT`, `moodTarget` iğnesine ek olarak) `world.setTimeOfDay(null)`, `ctx.campLife?.menuPose(true)` (statik Ozan, Ana ve Baba görünür; ikizler ve yaban hayvanı gizli) ve `world.weather?.identity(0)` çağırır; çizdikten sonra son saat örneğini (`ClockSystem.sample`), oturum pozunu ve hava durumunu geri yazar (post ayarlarını sakladığı gibi). `freeze` dünya saatini ve hava saatini de durdurur. Zerre `uDusk` menüde kurulum değeridir (0); saat kanalı menü anahtarına dek 0'dır. Kabul: Serbest Gez'den çıkmadan 03:00'te `menuDiff` 0; gece oturumundan sonra 0; ıslak zemin, dolu, yıldırım şeridi ve fırtınadan sonra menüye dönüşte 0; yeni oturumun ilk karesi (`uDusk` ve halkın görünürlüğü dahil) menüyle aynı (`time.md` §17, `weather.md` §15 W12).

**Faz sonu duman sınaması (`L`, tarayıcı bölmesi).**

| Faz | Sıra |
|---|---|
| 1 | `goTo('freeroam')`, `step(16.7, 60)`, WASD, `toggleMap`, `step`, `Esc`; `perf().calls` 582 ±8 |
| 2 | Çocuk: `game.actor.profile.id === 'child'`, çit atlama, ata binme, `perf()` Faz 1 kadrajında ≈−200 çizim (§9) |
| 3 | `menuDiff`; dil değiş: bütün görünür metin EN; `Yükle`, `Ayarlar`, kitap; `audio.state('camp')`, `audio.nodes() ≤ 40` |
| 4 | `story.reveal`, `atlas` etiket sayısı; ölçek çubuğu km; `menuDiff` |
| 5 | `cine.play('cine_newgame')`, `seek`, atlama, `creator`, kabul; `perf()` geniş plan ≤570 |
| 6 | `struct.setStep`, `struct.hit`, kaydet ve yükle; `structures.md` §17 kabul 1–10 |
| 7 | `swap('camp')` ×3: `memory` taban (aynı görüntü geçmişiyle, §2.7); her turda `refs.compare`; `menuDiff` |
| 8 | `econ.give`, toplama, `derive`, `pause` sayfaları; `clock.set` altı durak, `clock.lapse(24)`, Serbest Gez 03:00'te ve gece oturumundan sonra `menuDiff`; `weather.set('thunderstorm')` (görünüm kimlik) ve `weather.sim('orkhon', 'camp_spring')`; camp3 emekle (`struct.speed(20)`), Çocuk katılır; `?sandbox=site` her tür, `labour.eta` |
| 9 | `swap('hexi_winter')`, `perf()`: ≤2,74M, ≤323; `weather.set('heavy_snow')` +≤1 çizim; Serbest Gez'de `weather.set('thunderstorm')`, `strike('near')`, `hail()`, menüye dönüş `menuDiff` 0; `?sandbox=site&hold=1`: Plan Kipi, `hold.synth(5, 'walled')`, `perf()` ≤323, program ≤92 |
| 10 | §4.5 örneği; araba ve Yol Kartı (`lock.weather`); nöbetçi `?` ve `!`; `?squad=10`; Yerleşim Defteri, kervan ×240; kapı: saatli Gün I + Tipi prototipi |
| 11 | Baştan sona oynayış, her bölümde kaydet ve yükle; `home`, perde kartı, Devam Et kartı |

Görsel kabul `L`'nindir. Kare süresi yalnız görünür bölmede ve yük ortalaması düşükken geçerlidir: gizli bölmede yalnız çizim ve üçgen sayısına güvenilir (denetim §0).

## 7. Performans bütçesi

Taban ölçüm: 3,84M üçgen, 582 çizim, ≈30 fps, M1 Pro, 2,6M piksel; post zinciri karenin yarısı (denetim §g). **Kare hedefi:** Kışlak ≤28 ms (post ≤11, ana + gölge ≤14, JS ≤3); kampta (menü, Serbest Gez, Yeni Oyun) 33 ms kabul; `home` kampta değildir (K106). `MAX_PIXELS = 2,6e6` kalır.

| Sahne | Ana üçgen | Toplam üçgen | Çizim toplam | JS | Kaynak, not |
|---|---|---|---|---|---|
| Bugün, Hero | 2,56M | 3,84M | 582 (371 + 195 + 16) | ≤0,5 ms | Ölçüldü |
| Menü | ≤2,50M | ≤3,72M | ≤400 | ≤1 ms | (K63 ile değişti: çizim ≤446 idi) Ölçüm 360 çizim, 3,69M (Faz 7, K27); eski hesap: Hero ana ve gölge −136 çizim, −118k. Görünen değişmez, yalnız görünmez kesinti. Faz 2 ölçümü 2,47M, 3,69M, 382 |
| Serbest Gez, üçüncü yurt tam, dönük | ≤3,45M | ≤4,85M | ≤520 | ≤3 ms | (K63 ile değişti, #63, #66: ≤2,70M, ≤4,06M, ≤511 idi) Hesap K27 ölçümünden (`sanat-animasyon.md` öneri 1): en kötü dönük poz 429 çizim ve 4,40M; üstüne üçüncü yurt ≤+45 ve ≤+248k (`structures.md` §13; Dengiz baştan sona, meşale direkleri 0 çizim), araba +6 ve +9,6k, K20 gündüz ikizleri +6 ve ≈+40k, K22 fırtına +2 ve +96, yaban hayvanı +6 ve +24k, koyun sürüsü +3 ve +15k, kuş +1 ve +1k: 498 çizim, 4,74M; %4 payla 520 ve 4,85M. GPU ≈27 ms (13 + 3,5 × 3,45 + 1,6 × 1,40); kampta 33 ms kabul (K3). `Smoke` birleşmesi kodda (`fire.js`: bütün bulutlar tek çizim) ve ölçümün içindedir: eski 514 → 484 hesabı ve «önkoşul» kalktı. Eski hesap menünün 446 tavanından başlıyordu, menünün ölçümü 360'tır |
| Yeni Oyun, yakın plan | | ≤2,90M | ≤420 | ≤1 ms | Ölçüldü 2,76–2,90M, 330–419 |
| Yeni Oyun, geniş plan | | ≤3,60M | ≤570 | ≤1 ms | Ölçüldü 4,85M, 686; 5.2 kırpma −1,29M, −119. Gölge kamera kalkınca donar |
| Oluşturucu | ≤0,08M | ≤0,15M | ≤28 | ≤1 ms | Hesap: Mete 60,6k, post 16. Dünya çizilmez |
| Harita, `span`≥26 | | 1,24M | 31 | ≤1 ms | Ölçüldü; +2 şerit |
| Harita, `span`<26 | | 4,16M | 32 | ≤1 ms | Ölçüldü, GPU'ya ≈1 ms |
| Harita, gerçek mod | | ≤4,7M | ≤672 | ≤2 ms | Ölçüldü |
| Kışlak, gündüz | ≤2,40M | ≤3,10M | ≤360 | ≤3 ms | (K63 ile değişti: ≤2,04M, ≤2,74M, ≤323 idi) İç harita satırı: `act1.md` §15'in hesabı (≈2,04M ana, ≈2,74M, ≈323) + döner kameranın dış halkası 0,25M (K27: dünya her yönden bitmiş görünür) + hayvan ≤0,11M; gölge 0,70M; GPU ≈21 ms, kare ≤28 ms (`sanat-animasyon.md` öneri 1). Gölge 2048², iki karede bir; hava: yoğun karda +1 çizim, 6000 nokta (`act1.md` §15 «kar» satırının içinde) |
| Kışlak, gece | ≤2,40M | ≤3,10M | ≤360 | ≤3 ms | (K63 ile değişti: ≤2,04M, ≤2,74M, ≤323 idi) 18+ nöbetçi: tam ≤16, gerisi kukla; gece evresi saatle; hava +≤1 çizim |
| Göz Yolu | ≤1,9M | ≤2,5M | ≤300 | ≤2 ms | 12 `Folk` + 28 kukla |
| Baskın, küçük akın | ≤2,40M | ≤3,10M | ≤370 | ≤3 ms | (K63 ile değişti: ≤2,1M, ≤2,8M, ≤340 idi; `sanat-animasyon.md` öneri 1) 6 tam + 14 kukla atlı, `fxFlames` ≤24, ≤3 tam alevli yapı; II–VI'nın küçük akını (K55) da bu satırdadır. Tahmin |
| Donuk Kamp | ≤2,40M | ≤3,10M | ≤360 | ≤0,5 ms | (K63 ile değişti: Kışlak satırını izler) Gölge donuk, canlandırma 0 |
| Kara Boran | | ≤1,2M | ≤220 | ≤3 ms | `act1.md` §10; gölge donuk, sis ≤140 m; hava +1 çizim (kar noktası), `pinFx` |
| Araba seferi, kamp dışı | ≤1,4M | | ≤230 | ≤1 ms | `travel.md` §13; `k`>1,3: `Folk` ≤8 |
| Atlas yolculuğu | | Harita | Harita + 2 | Kurulum blokları konakta | `travel.md` §9.4 |
| II. Perde, Onluk ve Yüzlük, bozkır | ≤2,20M | ≤2,90M | ≤320 | ≤2 ms | (K63 ile değişti: ≈1,78M, ≈2,5M, ≈240 idi; `sanat-animasyon.md` öneri 1) `army.md` §7.1, kanca |
| II+. Perde, yerleşim, Tanhu Avlusu | ≤2,40M | ≤3,10M | ≤360 (hesap ≈198 + hava 2 ≤213) | ≤3 ms | (K63 ile değişti: ≤2,04M, ≤2,74M, ≤323 idi; en kötü hayvan karesi +0,12M ile hesap 1,92 + 0,25 + 0,12 = 2,29M) `settlement.md` §17: ≤4 tam yurt 40 m içinde, ≤48 canlı yapı, `YurtField` 1 + 1 çizim, `KitField` tek `BatchedMesh`, sürü örnekli ≤300; `spec.postCuts: true` |
| II+. Perde, ordugâh, Binlik | ≤2,40M | ≤3,10M | ≤360 | ≤3 ms | (K63 ile değişti: ≤2,04M, ≤2,74M, ≤323 idi) 40 tam çadır, gerisi `TentField` (`world/tent-field.js`, 13.4; 1 çizim + 1 gölge, program eklemez); ordu `army.md` §7.2 Binlik satırı |
| Kum havuzu (`sandbox_site`, `sandbox_hold`) | ≤2,40M | ≤3,10M | ≤360 | ≤3 ms | (K63 ile değişti: yerleşim satırını izler) Yalnız geliştirme; `hold.synth(5, 'walled' \| 'moving')` yerleşim satırıyla ölçülür |

**Prototip satırları ve Godot bütçesi (K63, #63, #66).** Bu tablonun satırları yalnız prototip içindir. Üçgen sınırı bir karede ekrana çizilen şekil miktarıdır; çizim sınırı ekran kartına verilen ayrı çizim emri sayısıdır. İkisi kare süresinin erken uyarısıdır, asıl hedef kare süresidir. Eski Serbest Gez satırı (4,06M, 511) K27'nin dış arazisinden ve dış ormanından önce yazılmıştı: ölçüm (4,40M, 429) üçgen sınırını aştı, çizim sınırını aşmadı; satır büyüdü, kare hedefi değişmedi. Godot'nun bütçesi ayrı tablodur (`godot.md` §7.2): motorun sayacıyla (`Viewport.get_render_info`) görünür ve gölge geçişi ayrı sayılır; kampta kare hedefi 16,7 ms ve sınırı 33 ms, görünür çizim ≤800, gölge çizimi ≤600, görünür üçgen ≤3,5M, gölge üçgeni ≤2,5M, doku belleği ≤256 MiB; iç harita ve kalabalık satırları oradadır. Prototipin sayıları Godot'ya bire bir taşınmaz. `sanat-animasyon.md` öneri 1'in Çocukluk satırı (≤2,60M, ≤300) prototipte yoktur: sahne yalnız Godot'dadır (K36).

**Dağılım.** JS kare tavanları: A* ≤2 ms ve kare başına ≤1; `NodePools.update` ≤0,5; `StructureManager` ≤0,5; `SiteSystem` ≤0,1 (≤24 uzak şantiye ≤0,05; toplu benzetim bir oyun günü, 24 şantiye ≤0,3 ms); `Squad` ≤2 (Act 1'de ≤0,5); `Stealth` ≤0,5; `Quests`, `Calendar`, `Regions` ≤0,1; `ClockSystem` ≤0,02 (`setTimeOfDay` 4 Hz, çağrı başına ≤0,03; kimlik `writeLight` ≤0,03, yalnız değişince); `CampLife` ≤0,05; `Weather` ≤0,2 (saat sınırında ≤0,3); `SettlementSystem` kare başına ≤0,1, `clock:hour` başına ≤0,5 (90 hane, 300 işçi, 40 tezgâh), 12 saatlik atlama ≤8 ms; `Dialogue` ≤0,1. Ekonomi servisleri kare başına çalışmaz: `Container.onDawn` şafakta ≤0,2 ms, `Workshop.tick` ve `herdDay` yerleşimin saat bütçesindedir. Atlamanın toplu işi karartma altında ≤60 ms / 15 oyun saati; uzun atlama ve Kronik ≤150 ms / mevsim. Gök Kavisi ve hava simgesi DOM'a ≤4 yazım/sn, yalnız değişince. Ana kampta hayvan ≤6 (K65 ile değişti: Godot'da yalnız iskeletli hayvan sayılır, `MultiMesh` sürü ve köşe gölgelendiricili atlar sayılmaz). Program ≤92 (`structures.md`; saat 0 ekler; hava +2: `weather_pts`, `weather_bolt`, menü 57 → 59 (Faz 7 tabanı: Çocuğun gölge programı ısınma karesinde), Serbest Gez 57 → 59, oluşturucudan sonra 72 → 74; yerleşim dünyası +6: `yurt_field`, `kit_field` ve derinlikleri, `plot_decal`, `field_stalk`; `plan_ghost` yok; yerleşim dünyasının tabanı Faz 13 kabulünde ölçülür), kışta `*_w` ile ≤100 (yerleşimde +2); hepsi yükleyicide `compileAsync`, post'un HDR hedefi bağlıyken (Faz 6: eskiden kullanılmayan tuval sürümü de derleniyordu; menü 84 → 56), gölge derinlik programları açılıştaki perde altı karede. Bellek: bir dünya + atlas, VRAM tepesi ≤480 MB; hazır ses ≤48 MiB: müzik 16, efekt ve ortam 24, satır penceresi 8 (K59 ile değişti: K12'nin 40 MB'ı kalktı, toplam havuzların toplamıdır; kodda bugün `BAKE_BUDGET` 16 MiB, `VOICE_BUDGET` 16 MiB; Godot'da dünya başına ≤26 MiB, `audio.md` §4; ortam döngüleri 22 kHz mono, sahne başına dilimli ön üretim; saat ekleri ≤0,5 MB; kampta yerleşik hava döngüleri ≤3,2 MB ve efektleri ≤2,5 MB, cepheyle pişer, fırtınalı akşam ve gecede efekt ve ortam önbelleği bırakma kurallarıyla en kötü ≈16,6 MB, efekt ve ortam havuzunun 24 MiB'ı içinde (K59; eski tavan 16 MiB idi; `audio.md` §4; aşarsa «Önce ne kesilir» ses satırı); `torch_post` tek değişken ≈0,35 MB (`audio.md` §4); yerleşim ve ekonomi ekleri yalnız yerleşim dünyalarında ≈0,9 MB), canlı ses düğümü ≤40 (Serbest Gez fırtınada ≤37); kayıt ≤1,4 MB; `mete.glb` 7,2 MB yalnız Yeni Oyun'da. **Hava parçacıkları ve yıldırım (K22).** Yağış ve sıçrama tek `Points` geometrisinde: ≤6000 nokta (kar 3000, yoğun kar ve tipi 6000, dolu ve sulu kar 1500, toz 600–2000) + 192 sıçrama, 1 çizim, 99 KB VRAM, CPU ≤0,06 ms (karede ≤32 yeni sıçrama); yıldırım şeridi ≤96 üçgen, 1 çizim, ≤0,35 sn görünür; ekran yağışı FINAL'de 0 çizim, GPU ≤0,3 ms; şimşek pozlama ve yarımküre yoğunluğudur, ışık eklenmez; en kötü toplam +2 çizim, +96 üçgen, +2 program, ≈0,1 MB, CPU ≤0,2 ms, GPU ≤0,5 ms. **Yerleşim yapıları (K23).** Zon başına ≤160 yapı kaydı, aynı anda ≤48 canlı `StagedStructure`, ≤4 tam yurt 40 m içinde, `YurtField` 40–220 m örnekli (`closed` ≈3k), ötesi 96 üçgenlik kubbe, `KitField` tür başına ≤400 üçgen; ikisi 1 + 1 çizim, gölgeleriyle 4; yerleşim durumu belleği ≤200 KB. **Kayıt.** Yolculuk ≈83 KB ≤96 KB (`army` ≈20, `world.sites` ≤20, `settlement` ≤14, `camps` ≤4, `world.weather` ≤1, `economy` ≤6, saat ve takvim ≈0,15, öteki ≈18); Serbest Gez +≈40 B saat, hava ≤1 KB.

**Önce ne kesilir.** Sıra tüm sahnelerde budur. Post kesintileri (1, 2, 3, 10) yalnız Kışlak'ta uygulanır; menü bitişiğinde (menü, Serbest Gez, Yeni Oyun, oluşturucu, `home`) render hedefi değiştirilmez. `Menü` sütunu menü bitişiğini yazar: yalnız ✓ satırlar uygulanır.

| Sıra | Kesilen | Kazanç | Bedel | Menü |
|---|---|---|---|---|
| 1 | `resScale` 1 → 0,85 → 0,7 (var) | Post ve doldurma, pikselle orantılı | Yumuşama | Hayır |
| 2 | MSAA 4 → 2 | 83 → 42 MB; süre ölçülecek | Az kenar | Hayır |
| 3 | Bloom 5 → 4 kademe | 13 → 10 geçiş | Çok az | Hayır |
| 4 | Gölge: her kare → 2 → 4 kare; 4096 → 2048 | ≤5 → ≤2,5 ms | Rüzgârda gölge gecikmesi | Yalnız kadans |
| 5 | `Smoke`, çiçek ve çim uzak parça, görünmez kırpma | −30 çizim; geniş planda −1,29M | Yok | ✓ |
| 6 | Çiçek ve çim `density` 1 → 0,55 | ≈−0,6M, 3–5 ms'nin yarısı | Serbest Gez seyrelir | Hayır |
| 7 | `Folk` 16 → 10, kukla 40 → 24, `ghost` 8 → 4 | ≈−110k, −20 çizim | Kalabalık azalır | Yok |
| 8 | Etki: `fxFlames` 24 → 12, saplı ok 64 → 32, kar 6000 → 3000, usta 3 → 2; ekran yağışı 3 → 2 katman, sıçrama 192 → 96, şimşek dönüşü 4 → 1 | ≈−40k; FINAL ≈−0,1 ms | Az etki | Yok |
| 9 | Çam: gölgeli 120 → 60, uzak 3000 → 1800 | ≈−210k | Uzak orman seyrelir | Yok |
| 10 | Kuwahara `paint` 3,1 → 2,4, sonra yarım çözünürlük | 3–5 ms | Boyalı kimlik zayıflar: son çare | Hayır |
| 11 | Ses belleği (kare süresinden bağımsız; kampta fırtınalı akşam ve gecede efekt ve ortam önbelleği havuzu aşarsa, W19; K59 ile değişti: havuz 24 MiB'tır, kodda `BAKE_BUDGET` bugün 16 MiB, 16,78 MB): önce `rain_felt` 6 → 4 sn, sonra `hail_bed` yalnız dolulu cephe planda görününce pişer | ≈−0,25 MB | Az etki | ✓ |

**Kesilmez:** telegraf, kadraj oku, Mete ve Çocuk'un `ghost`u, ateş, altyazı. Bir sahne hedefi aşarsa `tools/check-budget.mjs` (12.4) düşer; karar `L`'nindir. **Hiçbir yerde:** çalışma zamanında ışık ekleme, kare başına ayırma, kare başına DOM yazımı (değişmedikçe).

**Dönen kamera (K27, 2026-11-03, gizli bölme, `perf()`).** Kamp beş noktadan sekiz yöne ve iki uzaklıkla ölçüldü: dış araziyle en kötü dönük poz 429 çizim, 4,40M üçgen; kuzeye bakan en kötü 427, 4,36M (yön bütçeyi aşmaz, güneye bakış daha ucuzdur: ateşte 180°'de 273 çizim). Program her yönde aynı, ışık 6. Dış arazi yüklemeye ≈18 ms ekler. Kare süreleri gizli bölmede 10,8–19,4 ms (kaba). Bütçe denetiminin (12.4) sahne listesi dönük pozları da içerir: her nokta için 0°, 90°, 180°, 270°.

## 8. Kararlar ve uzlaştırma

İstek 10 gereği: istek ya da komşu belge mimariyle çelişince uygulanan seçenek ve nedeni.

| # | Yazan | Çelişki | Uygulanan | Neden |
|---|---|---|---|---|
| 1 | Görev listesi 10 durum | `travel.md` §9.4 atlas yolculuğu ayrı çizim ve girdi ister | `travel` 11. durum | Dünya kurulurken atlas çizilir, `play` çizemez |
| 2 | `menu-spec.md` önce kurulum, sonra söz | 4,5–17 sn yükleme + 7 sn söz: istek 2'nin «oyun açılınca söz» etkisi gecikir | Kurulum epigrafın altında | CSS canlandırması blokta oynar; ayrı bekleme ekranı kalkar |
| 3 | Denetim §a, §b: oturan çocuğu sil, ozanı `Folk`'a taşı | İstek 2: menü sahnesi değişmez | Statik örgüler kalır; çocuk `softContacts`'e geçer (temas ve çim aynı, nav dışı), Serbest Gez'de gizlenir; ozan tutamak ve viseme | Tek piksel korunur, istek 3 de karşılanır |
| 4 | Denetim 3: `Hero extends Rig` | İstek 3 ve 8: Hero ana sahneden kalkar, Mete `mete.glb` | Hero emekli; `armMode='bow'` `Rig`'de kalır | Kullanılmayan kodu taşımamak; −127 çizim |
| 5 | `menu-spec.md` §7 Tanhu 3 kamera pozu | Yerleşim başka; "bizim canlı kamp" isteği | Bugünkü oyun kadrajı + sürüklenme, paralaks | İstek 2 |
| 6 | Denetim §c: `WorldSpec` veri | Kamp formülleri sayıya çevrilirse sapar | Spec işlev başvurusu taşır, RNG sırası korunur | Menü farkı ≤32 piksel |
| 7 | `economy.md` §12, `travel.md` §9.5, `army.md` §8: `game.js` satırlarına ekleme | Git yok, üç paket aynı dosyayı düzenleyemez | `GameSystem` kayıtları; eşleme aşağıda | Çakışmasız paralellik |
| 8 | `progression.md` §13.2, `travel.md` `inventory.stash`, `inventory.cart` | `economy.md` §1.2 kendi bloğunda | `economy.stash`, `economy.cart`; `inventory` yalnız `equip`, `arrows`, `bell` | Alan sahibi kazanır |
| 9 | `main.js` `post.fade` | DOM menü ve HUD kararmaz | `ui.fade`; `post.fade` yalnız `atlas.veil` | Tek kararma katmanı |
| 10 | Ayrı veri dili (JSON, YAML) | `tools/voices.mjs` modül içe aktarır; koşul, yorum | Düz JS modülü, `schema.js` | Sıfır bağımlılık, Node'da açılır |
| 11 | "Menüye dön" hızlı olmalı | İki dünya bir arada ≈480 MB | Kışlak'tan menüye yükleyiciyle dönüş; `paintGround` işçisi 12.3 | Denetim §c |
| 12 | İstek 9, 75.000 km² | Gerçek km ölçeği LOD ve kabartmayı bozar | Denetim Seçenek A; `act1.md` §17 #11 | Harita aynı görünür, ölçek doğru yazar |
| 13 | `progression.md` zorluk "Ayarlar" | Kayıtlar arası sızıntı | Zorluk kayıt alanı; oluşturucuda satır, kitap sayfasından değişir | Kayıt başına tutarlılık |
| 14 | Denetim: son bakış (0, 46, 0) | Sağ kenar uzak araziyi aşar, `X` büyütmek menüyü değiştirir | Bakış (−32, 46, 0) | Hesap §4.3 |
| 15 | Modül adları: `world/winter-spec`, tek `audio/sfx.js` | Tek dosyada çok reçete çakışır | `world/specs/winter.js`; `audio/sfx.js` + `audio/sfx/*.js` | Paralel yazım |
| 16 | `survival.md` §5: Baba ve Ana ateşe gelir | Statik örgü yürümez, menü değişmez | `child.js`, kadraj dışındayken statikleri gizler, iki `Folk` ikiz çıkarır; +≈40k üçgen, +6 çizim, yalnız o an | İki isteği birlikte karşılar |
| 17 | `act1.md` §9.3 ve `structures.md` üçüncü yurt, adım, ağ | Belgeler arası | `structures.md` §0 geçerli | Alan sahibi |
| 18 | Etkileşim önceliği: `economy.md` görev > at > düğüm; `travel.md` direk, araba, at | İkisi tek sıraya | Görev 100, direk 90, araba 85, at 80, kişi 70, ateş 60, yapı 55, düğüm 50, eşya 45 | §3.7 |
| 19 | `menu-spec.md` Ayarlar: `Kamera dönüş hızı`, `Fare hassasiyeti` | Diablo kamerasında oyuncu yaw döndürmez, Q ve E oyun eylemidir | İki satır yok (K27 ve K39 ile değişti: kamera döner; Godot'da `camera_speed` 60–160°/sn ve `mouse_sensitivity` 0,1–0,5°/px ayardır, tuşlar yeniden atanır ve kaydedilir, `godot.md` §5.6) | Okuyucusuz ayar olmaz (`progression.md` kural 1) |
| 20 | `decisions.md` K7: perde sonu | `play` Kışlak'a bağlı, Çocuk ve canlı kamp başka dünya; II. Perde henüz yok | `home` 12. durum: `play` → `home` → `menu`; Devam Et kartı gösterir | Kayıt korunur, çıkmaz sokak yok |
| 21 | `decisions.md` K13: `cmd_look` `G` | `economy.md` `drop_load` de `G` | Kısa basış `cmd_look`, 0,6 sn basılı `drop_load` | `douse`, `sling` ile aynı desen |
| 22 | `decisions.md` K11: dikey dilim | Faz 11 içeriği prototipsiz açılırsa tempo geç sınanır | 10.9 ve Faz 10 sonunda kapı | Gün I + Tipi oynanmadan içerik yazılmaz |
| 23 | §3.2: `atlas.js:489-493` tekerleği kalkar | Adlar ve araçlar canvas'ı örter, tekerlek canvas'a düşmez; kıstırma sayfayı büyütür | `.atlas` katmanında `wheel` kalır, canvas tekerleği Input'tan gelir | §3.2 madde 7 ile uyumlu: DOM katmanı olayını kendi alır |
| 24 | Bugünkü kod her sahnede dinamik çözünürlük | `decisions.md` K3: menü bitişiğinde render hedefi değişmez | `sampleResolution` yalnız `spec.postCuts`; Faz 1'de hiç çalışmaz | K3 kazanır; kampta 33 ms kabul |
| 25 | §3.2: `mood` yalnız geliştirme | 1.3 «görünüm aynı», Faz 1 «bugünkü oynanış» | Faz 1–2'de bütün derlemelerde kaldı. Faz 3 kararı: HUD ışık düğmesi ve `T` yalnız geliştirme paketinde (`import.meta.env.DEV`, `hud.js`, `freeroam.js`); `tanhu.roam.mood` yazılmaya ve okunmaya devam eder | Kitapta ışık ayarı yok, okuyucusuz ayar da yok; sınama aracı oyuncuya sızmaz. K20'de kalktı: §8 karar 40 |
| 26 | §5 Faz 2: `L` `CreatorState`'i bırakır, Hero içe aktarılmaz | Oluşturucu önizlemesi 5.6'ya dek çalışmalı, Hero ister | `CreatorState` kalır; Hero, `ui/creator.js`, `ui/stage.js` ilk girişte `import()` ile gelir, `ctx.stage` orada kurulur | Oyun paketi Hero taşımaz, önizleme kaybolmaz |
| 27 | §0 kural 8: menü sahnesi değişmez, `menuDiff` tabanı eski koddan | §3.20: menüde `U.uPlayer` (0, −100, 0); eski taban görünmez kahramanın ayağındaki çimi iten kareydi, canlı menü onu hiç göstermez | Taban Faz 3'te menü kamerası ve (0, −100, 0) ile yeniden yazıldı. Eski tabanla fark 224 piksel, en çok 139/255, hepsi eski oyuncu noktasının izdüşümü (825, 609) çevresinde (x 731–937, y 554–626); kamera pozu eski kadrajla bit bit aynı, çizim 382, üçgen 3.692.160 aynı | Sınanan kare oyuncunun gördüğü kare olmalı; kamp sahnesinin kendisi değişmedi |
| 28 | §3.21, §7: post kesintisi yalnız Kışlak'ta, menü bitişiğinde render hedefi değişmez | 5.7: `video.quality` low (`?q=low`) MSAA 2 ve 4 bloom kademesi istiyor | `App.resize` her sahnede `POST_QUALITY[low ? 'low' : 'auto']` uygular; otomatik kesinti yine yalnız `spec.postCuts` | Low oyuncunun seçimidir, kendiliğinden kesinti değildir; auto'da hedef değişmez, `menuDiff` 0 |
| 29 | Faz 3 duman: engele dayanınca aktör durmalı | `child.test.js` çit sınaması duruş yerini ≥0,4 m ister; `speed` 0 yapılınca aktör küçük adımlarla 4 cm daha sokuluyordu | `game.blocked`: fizik hızı kalır, aktöre ve ata giden yürüyüş hızı 0 | Duruş yeri kare hızına bağlanmaz, yürüyüş döngüsü ve toynak sesi yerinde çalmaz |
| 30 | §3.5: `difficulty` bloğu `journey.js`'indir (10.8) | Faz 5: kabul kökeni, görünüşü ve zorluğu yolculuk kaydına yazmalı | App `difficulty` bloğunu (order 10) geçici kaydeder; 10.8 alınca App'teki kayıt silinir | Kayıt şimdiden üçünü taşır, biçim değişmez |
| 31 | §3.6: çözülmüş satır önbelleği 8 MB | Yeni Oyun'un dokuz satırı 48 kHz mono ≈10 MB; üçü ön yüklemeden sonra düştü, çalarken yeniden indi | `VOICE_BUDGET` 16 MB | Bir sinemanın ön yüklediği satırlar birlikte sığmalı; motorun öteki sesleriyle ≈27 MB, K12'nin 40 MB'ı içinde. (K59 ile değişti: K12'nin 40 MB'ı kalktı; tablo 48 MiB, satır penceresi 8 MiB («çalan + sıradaki 2 satır», `audio.md` §4); kodda `VOICE_BUDGET` 16 MiB kaldı, satır penceresi kuralı yazılmadan inmez, `ses-tasarimi.md` öneri 1) |
| 32 | `act0-text.md`, K17: ozan `eleven_v3` `[sings]` ile söyler, iki dize iki dosya | Kullanıcı: «şarkı söylemiyor, düz okuyor»; Vibi'de müzik ucu yok, ses dönüştürücü kuyrukta kaldı | Bestelenmiş şarkı tek dosya `act0.bard.song` (ses + dombra, 24,6 sn): `tools/bard-song.mjs` okumayı `bard-song.js` notalarına TD-PSOLA ile oturtur, dombra `instruments/dombra.js`'ten, −18 LUFS. Sinema satırı `subs` (dizeler dosyanın içindeki saniyede), `mouth` (notalardan ağız çizelgesi, zarf yok: dosyada dombra var), `dur` (dosyasız boy); manifest `seconds`; `camp_bard` yalnız dron | Melodi, dombra ve ağız aynı çizelgeden çıkar; Scribe şarkılı sesten 23 sözcüğün hepsini doğru okudu |
| 33 | `structures.md` §5.4: alt aşamanın açıkta kalan birimi çentikte ¼ alır | 6.3: keçe gidince kafese değen yakın vuruş üst havuza hiç inmiyordu; çatı keçesine yakından erişilmez, aşama 6 bitmiyordu | Çentik kalanı (¾) üst katmana gider, alt birim yine ¼ ve %30 tabanı alır; kapı keçesi `h1` yalnız kesilince düşer, yanınca değil (§6.1 süreleri tutar); çitte artan hasar vurulan dilimde kalır (tek balta altı dilimi zincirlemiyordu) | §5.3 vuruş sayıları değişmez; ölçüldü: ateşli ok 7→5 29,2 sn, meşale 7→3 69,2 sn, ikinci meşaleyle bosağa %30'da ayakta |
| 34 | `structures.md` §11.6, §10.2: zaman çizelgesi asıl, usta süs | Yapı kendi `_work`'üyle de ilerliyordu; usta sistemi gelince iki kez ilerleme ve iki onarım olurdu | `BuilderSystem` bağlandığı yapıda (camp3) çizelgeyi, oranı ve onarımı o sürer (`manager.driven === yapı`), yapı ilerlemez; öteki yapılarda (A, B, ahır, çit) ve ustasız dünyada yapının yedeği: 20 sn bekleyiş, vuruştan 30 sn sonra onarım. İkisinde de yangın ya da onarım beklerken çizelge durur | Tek kaynak, sınamada ustasız da kurulur |
| 35 | `structures.md` §6.4: yanan yapı `fire_loop` 3B | `fire_loop` ortam (ambience) döngüsüdür, efekt motorunda yoktur; check-data reddeder | Yeni efekt reçetesi `structure_fire` (döngü, 22 kHz, en çok 3); ses sınırı dolarsa yapı `fire_catch` çıtırtısına düşer | Ortam motoru yapı başına konum taşımaz; efekt döngüsü yapının tepesinden çalar, menüde susar |
| 36 | §2.3, §7: gölgelendiriciler açılışta `compileAsync` ile | `compileAsync` tuvale çizim varsayımıyla (srgb) derliyordu; sahne post'un HDR hedefine (doğrusal) çizilir: 43 program hiç kullanılmadan duruyor, gerçekleri ilk menü karesinde derleniyordu, menü 84, Serbest Gez 94 program (tavan 92) | `app.start` derlemeyi HDR hedefi bağlıyken yapar; yapılar oyun kipinde bir kez eşitlenip perde altında bir kare çizilir, gölge derinlik programları da açılışta derlenir | Ölçüldü: menü 56, Serbest Gez 57, hasarlı A ile 58; ilk Serbest Gez karesinde 1 derinlik programı kalır; `menuDiff` 0 piksel |
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
| 56 | K27 kamera döndürme / §3.2 tuş dağılımı, `survival.md` §4 | Q ve E (`quick`, `use`) ve sağ tık (nişan) alınmış; Türkçe Q'da noktalama tuşlarının adı ABD adından başka | Orta tuşla sürükleme ve orta tık, yatay tekerlek ya da Shift + tekerlek, `cam_left` `,`, `cam_right` `.`, `cam_reset` `/` (yeniden atanabilir, adlar dizilişten); oda ve sinema kuzeye, açı oturumluk | Var olan eylemlere dokunmadan her aygıtta bir yol; menü karesi ve kuzeyden kurulmuş çekimler değişmez |
| 57 | K27 / Faz 7 kuralı: `docs/baselines/refs` yeniden alınmaz | Dönen kamera güneyde göl düzlemini ve uzak ağın kesik kenarını gösteriyordu; dış arazi `valley` pozunu (1.787 piksel, sol alt ön plan) ve sahne sayımını değiştirir | `landHeight`, güney uzantısı, dış orman (§3.8); taban 2026-11-03'te taze açılışta yeniden alındı, eskisi `docs/baselines/archive/refs-pre-k27`; menü karesi 0 piksel | Bilinçli görüntü değişikliği; öbür altı poz 0 piksel, taban yalnız bu kapsamla yenilendi |
| 58 | Faz 8 tek turda (19 alt paket) | 19 alt paketin `L` bağı, üç incelemesi ve dumanı tek turda fazla büyük | İki dalga: A temeller (9: 8.1, 8.2, 8.3, 8.4a, 8.4b, 8.9a, 8.10, 8.11a, 8.14), B üstüne kurulanlar (10: 8.5, 8.6, 8.7, 8.8, 8.9b, 8.9c, 8.11, 8.12, 8.13a, 8.13b); 8.4, 8.9, 8.11, 8.13 dosyalarıyla bölünür (§5 Faz 8). (K64 ile değişti, #62: satır «18 alt paket» yazıyordu; 8.11a ile 8.11 ayrı sayılınca dalgalar 9 + 10 = 19 eder, eksik paket yoktu. Godot'da paket yoktur, iş birimi Yol Haritası maddesidir) | Entegrasyon hatası küçük yüzeyde yakalanır; B A'nın sınanmış kodunu okur |
| 59 | Dalga A'da ışık, hava görünümü ve `T` | 8.9a saati kurar ama ışık hattı (8.9b) ve Bekle tekeri (8.9c) B'dedir; hava görünümü 9.4'tedir | Saat A'da ilerler, ışık B'de bağlanır (`setTimeOfDay?.`); `T` B'ye dek geliştirme ışığını değiştirir; hava görünümü 9.4'e dek kimlik, Serbest Gez havası panel zorlamadıkça açık | Her ara durumda oyun açılır ve menü karesi değişmez |
| 60 | K19, K28 / karar 32 (bestelenmiş şarkı, Vibi okuması notalara) | Kullanıcı: «ozan dombra çalıp şarkı söylemiyordu»; Vibi'de müzik ucu yoktu; Vibi kalkıyor | Şarkıyı Eleven Music (`music_v2_5`) söyler ve çalar: plan, çekim sınaması, sözcük zamanları (`bard-song-plan.js`, `bard-song-take.js`, `tools/bard-song.mjs`); konuşma `tools/voices.mjs` ile doğrudan ElevenLabs'ten | Gerçek şarkı ve dombra; altyazı ve ağız çekimin kendi zamanlarından çıkar |

**Karar 7 eşlemesi.**

| Belgedeki satır | Karşılığı |
|---|---|
| `interact()`, `updatePrompt()`, `game.js:361-369,:814-822` | `collectInteractions`, `bestInteraction`, `game.prompt` |
| `issueMove()`, `pick()` düğüm ve yapı hedefi | `onPick` |
| `update()` `top × speedK`; `updateStamina()` Tokluk çarpanı | `game.moveMods` |
| Vuruş boyunca `restT = 0` | `game.restT` yazılabilir alan |
| `bindInput` `KeyG` | `keymap.drop_load` |
| `placeCamera` `yaw`, sürüş, yolcu, `camBias` | `game.cam.push` |
| `placeActors` `this.seat` | `game.seat(ride)` (10.5 `game.js`'e ekler) |
| `squads.simulate`, `squads.place`, `onRoom` | `GameSystem.update`, `place`, `onRoom` |
| `leaderPose`, `wantMove` | `Game` alanları (1.1) |
| `__tanhu` `squads` | `devtools.register` |

## 9. Doğrulama durumu

- **Okundu:** bütün `docs/design` belgeleri, denetim, `menu-spec.md`, `groups-research.md` ilgili bölümleri; `main.js`, `game.js`, `world.js`, `rig.js`, `mete.js`, `folk.js`, `nav.js`, `terrain.js`, `layout.js`, `hud.js`, `paint-material.js`, `post.js`, `npc.js`, `interior.js` ilgili kısımları.
- **Betikle denetlendi (geçici dizin, projeye yazılmadı; `decisions.md` kararlarından önce, sonra +1 paket 10.9, +4 dosya `states/home.js`, `story/proto/*`, yeniden koşulmadı):** 13 fazda 88 paket, 367 tekil dosya: faz içinde iki pakete düşen dosya yok, `L` dosyası pakette yok, paket dosyalarının hepsi ağaçta, düzenlenen 29 dosya diskte var ve `E` işaretli; her `test/*.test.js` §6.1'de anılıyor; saf liste ve sistem tablosu paketlerle eşleşiyor; §4.5 örneği JS olarak çözümleniyor; `audio.md` §4'ün 73 efekt kimliği §3.6 tablosunda; 33 tablo sütun sayısı tutarlı.
- **Hesap, koşulmadı:** menü kamera pozu, son plan bakışı (−32, 46, 0), §7 tablosundaki hesap satırları, bu belgedeki hiçbir arayüz henüz çalıştırılmadı.
- **Faz 1 çıkışı (gerçek App):** Arka plan sekmesinde, rAF'sız `menuDiff` 0 piksel, 0 fark: eski kodun görüntüsüyle bayt bayt aynı, 300 kare sonra da; önde, rAF ile 0 piksel, en çok 20.304 piksel ≤8/255. `perf()` `?play` başında 583 çizim (372 + 195 + 16), 3,84M üçgen, 246 geometri, 32 doku, 85 program; harita 31 çizim, 1,24M; gerçek harita 576, 3,56M. Tıkla, WASD, at, oda, `M`, `Esc`, HUD düğmeleri, oluşturucu, yeniden boyut, gerçek fare ve klavye olayları, üretim paketi denendi (sekme önde ≈40 fps). Fiziksel dokunmatik cihazda denenmedi.
- **Faz 2 çıkışı (gerçek App, `__tanhu.step`):** `menuDiff` 0 piksel, 12 fark, en çok 1/255: açılışta, oturum sürerken, ata binip oturum kapanınca, oluşturucuda. Menü karesi 382 çizim (257 + 109 + 16), 3.692.160 üçgen. `perf()` 1600×900: doğuşta 345 çizim, 3,44M; Faz 1 kadrajında (1,75; 2,35), 33 m 382 çizim (256 + 110 + 16), 3,72M: Faz 1'in 583 ve 3,84M'sine göre ≈−200, ≈−125k. Çocuk 11 çizim, 56k üçgen (yayla). 81 program, binişte yeni program yok. Açılışta `character/hero.js`, `ui/creator.js`, `ui/stage.js` istenmez, `goTo('creator')` ve `?state=creator` yükler, önizleme çalışır, `Kampa gir` yeni oturum açar. Çit −0,95 ve korkuluk −1,1 gerçek kampta aşılır, zıplamadan geçilmez; iki yurt kapısından ateşe yürünür; ata binilir, kalça eyer noktasında (0 m), dörtnal, atlı sıçrama, inme; `M` gidiş dönüşü oturumu korur; `C`, `Q`, dokunmatik düğmeler fare olayıyla. Fiziksel dokunmatik cihazda denenmedi. Üretim paketinde Hero ayrı parçadır.
- **Faz 3 çıkışı (gerçek App, gizli bölme, `__tanhu.step` ve gerçek tık ve tuşlar):** Boş ayarla açılış: dil ekranı, TÜRKÇE tıkı `{"lang":"tr"}` yazdı ve sesi açtı, söz göründü, dünya altında kuruldu, söz → menü perdesi 2,0 sn sine (0,25'te α 0,85, 0,5'te 0,50), menü açılışı 3,6 sn. İkinci açılış doğrudan söze. Menü: YENİ OYUN (`newgame` yok), DEVAM ET ve YÜKLE (yolculuk yok) kapalı, odak DESTAN KİTABI; dev panelinden yazılan yuvayla ikisi açıldı, YÜKLE paneli yuvayı resmiyle gösterdi, seçim «Bu kayıt açılamadı.» (play yok). Destan Kitabı ve Ayarlar kitabı açıldı; Ayarlar › Dil › English bütün görünür metni (açık sayfa dahil) EN yaptı, kapanış `{"lang":"en"}` yazdı; `video.painterly` ve `video.quality` canlı uygulandı. Serbest Gez: 1,6 sn karışım, Çocuk ateş başında oturur, adım sesi zemine göre (ocak çevresi toprak, çayır ot), zıplama ve iniş, ata binip yürüyüş, tırıs, dörtnal toynakları, ahırdan kişneme; ortam rüzgâr, ateş, kamp uğultusu; Destan bayrakları 3/7 oldu. `Esc` → kitap `game` kipinde, müzik −6 dB, KAYDET `tanhu.roam` yazdı (bayraklarla), ANA MENÜ uçuşu atlı Çocukla bitti, atlar ahırda, statik çocuk yerinde, `menuDiff` 0 piksel, 0 fark (yeni taban; açılışta da 0). Canlı ses düğümü menüde 21–23, Serbest Gez'de ≤25; hazır ses 16,35 MB; `fonts`: Cinzel 700, Alegreya 400 ve italik yüklendi. Konsolda hata yok. Kulakla dinlenmedi; fiziksel dokunmatik cihazda denenmedi. `menuDiff` bellek sayacı oturuma bağlıdır: taze açılışta 158 geometri, 31 doku, 75 program (`menu_counts.json` 161, 33, 81 Faz 2 oturumundan), çizim ve üçgen aynı.
- **Faz 4–5 çıkışı (gerçek App, görünür bölme, rAF ve gerçek tık ve tuşlar; 1280×720 öykünüm):** Serbest Gez haritası yalnız başlangıç satırlarını gösterir (Xiongnu, Yuezhi, rehine olayı, kamp ve fiziki satırlar; dönem yalnız 210, 86 satır gizli); `__tanhu.story.reveal('wusun')` → sonraki açılışta Vusun 210'da sönük ad olarak mürekkeple belirir (`.al-rumour`, α 0,58), leke ve sınır yok. Ölçek: görünüm ortasında ölçülen 10,67 px/birim, varsayılan 10,69; «50 km», not «Harita 75.000 km² … 1:18,5». YENİ OYUN tıkı: ozan dombrayı kaldırır, söyler (ağız `track`), geri çekilme, gök, anlatıcının yedi satırı, oluşturucu; 9 satırın 9'u dosyadan çaldı (sırayla `voice:start`/`voice:end`), sinema 70,9 sn, TR ve EN altyazı tam. Atlama (0, 5,5, 9,7 sn ve `seek(44)` sonrası; Space, Esc, Enter basılı) her seferinde `creator`'a: çalan ses 0, altyazı kapalı, sis katmanı kapalı, ozan oturur, billboard 0, ipucu gizli, müzik `creator`. Kabul (köken `origin_stable`, zorluk `hard`) → Serbest Gez, oto yuva 0: `difficulty: 'hard'`, `player.origin`, `name: 'Mete'`, `foot` 4, `world.era '210'`. Geniş planda `perf()` 341 çizim, 3,35M. `?q=low` yolu: MSAA 2, 4 kademe; auto'ya dönüş. Çocuk `ZOOM.min`'de kadrajda (NDC y −0,68, eskisi −1,41); ateş halkasına WASD: 80 kare `blocked`, adım yok. `menuDiff` 0 piksel (en çok 6/255) açılışta, tam sinema ve dört atlamadan sonra; 358 çizim, 3.692.162 üçgen. Konsolda hata yok. Kulakla dinlenmedi.
- **Faz 6 çıkışı (gerçek App, görünür bölme, rAF ve `__tanhu.step`; 1280×720 öykünüm):** Sistemler kurulu (`structures` 60, `builders` 62, `combat` 70, `projectiles` 72, `telegraph` 74), konsolda hata yok. `menuDiff` 0 piksel (686 fark, en çok 6/255): taze açılışta, A kırık ve B yanarken menüde, Serbest Gez'den (hasar, yangın, ustalar, yerde ok), oluşturucudan dönüşte; menü, Yeni Oyun ve oluşturucuda üçüncü yurt, ped ve stok gizli. Serbest Gez: ustalar 20 sn sonra kuzey yamaçtan iner, ped, bosağa, kerege kanatları kurulur; «Yeni Yurt · Kerege 3/6» yer adı ve inşaat göstergesi 10 m içinde. Kabul (`structures.md` §17): 2) 13 adımın her birinde kapı → içeri → arka → kapı → ateş yolu var, kapı → ateş 19,43 m; 3) beliren kanattan itme 0,32–0,42 sn; 5) ateşli ok 7→6 5,4 sn, 7→5 29,2 sn; meşale 7→3 69,2 sn, ikinci meşaleyle aşama 1'de bosağa %30'da ayakta; 6) kaydet, yeniden yükle: üçüncü yurt, A ve B'nin aşama, birim canı, yırtık, yama, saplı ok, yanık (`burnT` 68), kor aynı (havuz toplamı 0,01 yuvarlama); 8) en kötü kare (hasar, yangın, 2 usta) üçüncü yurtsuz kareye göre +14 çizim, +114k üçgen; 9) A kırık bırakıldı, menüde sağlam, oyuna dönünce kırık; 10) program menüde 56, Serbest Gez 57, hasarlı A ile 58, oluşturucudan sonra 72, derleme hatası yok. Panel: kılıç ve balta keçeyi yırttı, ok saplandı, uçan ok kapıya (2, ahşap) ve keçeye (0,5, saplı), oyuncak ok keçeye 0,125; gerçek sağ tıkla tahta kılıç A'ya yürüyüp 0,25 vurdu (`fromPlayer`). Yanan yapıda `structure_fire` döngüsü çaldı. Sistemlerin kare süresi ≈0,1 ms (`structures`, `builders`). 1 ve 4 (590 ±5 sn, yardımla ≥283) ve 7 (kapalı ağıl) `node:test`'te. Sınamadan sonra A, B, ahır ve çit sağlam hâle, üçüncü yurt aşama 0'a döndürüldü ve `tanhu.roam`'a yazıldı. Kulakla dinlenmedi; dokunmatikte saldırı yok.
- **Faz 7 çıkışı (gerçek App, gizli bölme, `__tanhu.step`; 1280×720 ve 820×640 öykünümde HUD):** Taze açılışta `refs.compare` yedi kare 0 piksel, sayım `counts.json` ile aynı; `menuDiff` 0 piksel (en çok 6/255), 360 çizim, 3.692.162 üçgen; zemin tuvali ve yakın ve uzak arazi dizileri Faz 7 öncesiyle SHA-256 aynı (7.1). Serbest Gez'e girişte program 57'de kalır. `swap('camp')` menüden ve Serbest Gez'den üçer kez: 1,5–1,7 sn, konsolda hata ve THREE uyarısı yok, bellek aynı görüntü geçmişiyle tabanda, program artmaz (§2.7); her turda yedi ref karesi 0 piksel, `menuDiff` 0. Değişimden sonra Serbest Gez: WASD, tıkla-yürü (ahırdan ateşe 7 noktalı yol), `M` gidiş dönüşü, «Doru'ya bin» ve iniş, uçan okun A'ya saplanması; girdi yığını `game, freeroam, child_aim` aynı; statik çocuk gizli, yapılar oyun kipinde. Atlıyken değişim Çocuğu yaya bırakır, atlar serbest. Hasarlı A (yırtık, saplı ok) ve kerege adımındaki camp3 değişimden bayt bayt aynı döner. Yükleyici «Kamp kuruluyor» / «Raising the camp» ve her adımın kendi etiketi; süren değişimde ikinci istek ve bilinmeyen kimlik reddedilir, dünya yerinde kalır. Ortam döngüleri değişimden sonra üç (rüzgâr, kamp uğultusu, ocak), 7 düğüm: çift yok. Kulakla dinlenmedi.
- **K20–K24 deltası (2026-11-03, `d2/architecture-delta.md`):** paket dosyalarının faz içi ayrıklığı betikle denetlendi (Faz 8: 14 paket + `L`, Faz 9: 10 paket + `L`, Faz 10, 11, 12, 13); her «Bul» metni bu belgenin 2026-11-03 sürümünde bir kez bulundu; yeni sözleşmeler (§3.23–§3.27) alan belgelerinin arayüz taslaklarından ve `d2/core.md`'den yazıldı. Hiçbir yeni arayüz koşulmadı; sayıların doğrulaması alan belgelerinin «Doğrulama durumu» bölümlerindedir.
- **K27 ve Faz 8 öncesi (2026-11-03, gerçek App, gizli bölme, `__tanhu.step`, eşzamanlı DOM olayları):** taze açılışta `menuDiff` 0 piksel (686 fark, en çok 6/255), 360 çizim; `refs.compare` yeni tabana karşı yedi kare 0 piksel, sayım eşit. Tekerlek `deltaX` 240 → 60°; Shift + tekerlek `deltaY` 120 → 30°, uzaklık değişmez; dikey tekerlek 26 → 27,6 m, açı değişmez; `,` 1 sn −102,5°, `.` 1 sn geri, `/` 0°; orta tuşla 200 px sürükleme −50°, orta tık kuzey. Açık alanda W 0°, 90°, 180°, −90°, 45° ve −135°'de kameranın ilerisinden 0° sapar; −135°'de S geri, A sol, D sağ. `npm test` 953/953, `check-pure`, `check-i18n`, `check-data` (eski bir uyarı), vite build geçti. `econ-sim --strict` 0 işaret (K24; inşa ve keçe hava çarpanı 8.10'a dek `weather.md` §4.2 yedeğiyle, uyarır). F8 öncesi belge incelemesi: 85 doğrulanmış bulgu işlendi, denetçinin kalan 10 maddesi ve açık 27 satır işlendi; çit ve tablo sütunları betikle denetlendi.
- **Faz 8 ve donma (2026-11-04, K29, K64):** A dalgasının dokuz paketi kodda; incelemesi ve tarayıcı dumanı kayda geçmedi. B dalgası yazılmadı. `contract-requests.md`'nin 57 açık satırı kodla karşılaştırıldı: 8'i A, 11'i A + B, 38'i B. Prototip artık hedef değildir; Godot'nun doğrulaması Yol Haritası maddelerinin kanıt yollarındadır (`/roadmap`).
- **Açık risk:** `Smoke` birleşmesinde çizim sırası (5.2). `menuDiff` ile yakalanır; düşerse değişiklik geri alınır, istek 2 kazanır. (K63 ile değişti: Serbest Gez bütçesi artık bu birleşmeye dayanmaz. Birleşme kodda ve K27 ölçümünün içindedir; satır ≤520 çizim ve ≤4,85M üçgendir, §7. Eski «514 → 484, düşerse gündüz ikizi 1 (511)» hesabı kalktı.) (2026-11-04, E6: risk eskidi (K64): yalnız prototipin kodundadır ve prototip dondu; Godot'da `Smoke` yoktur, menü karesinin sınaması `godot.md` §8.5'tir.) Faz 7'de kamp RNG'si ve kurulum sırası `refs.compare` ile aynı çıktı.

