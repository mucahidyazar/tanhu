# `architecture.md` değişiklikleri: Zaman ve Takvim (K20)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `architecture.md` yalnız `d2/architecture-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/time.md`. Faz 7 bitince `L` işler. Her madde bölüm başlığıyla, bulunacak metinle (birebir) ve yeni metinle verilir; satır numarası yoktur, çünkü belge Faz 7'de değişiyor. "Bul" metni bulunamazsa madde atlanmaz, `L`'ye sorulur. Sıra önemsizdir.

## A1. §1 Hedef klasör ağacı, `src/game/`

**Bul:**
```
  calendar.js                      →10.1 Perde, gün, dilim, İş Puanı (saf)
```
**Yerine:**
```
  calendar.js                      →8.9 Perde, hikâye günü, takvim, ay, vakit, uyku kapısı (saf; d2/time.md §12.4)
  world-clock.js                   →8.9 Dünya saati: oyun dakikası, gün, durma, bekleyiş, atlama (saf)
  daylight.js                      →8.9 Güneş ve ay konumu, gün ışığı, evreler, ışık anahtarları (saf)
  clock-system.js                  →8.9 ClockSystem: saati sürer, dünyaya ışığı yazar, Bekle ve uyku
  camp-life.js                     →8.9 Ana kampın halk ve hayvan programı (Serbest Gez)
```

**Bul:** `  schedule.js                      →10.3 Dilim → konum, iş (saf)`
**Yerine:** `  schedule.js                      →10.3 Dakika → konum, iş (saf)`

**Bul:** `  moon-clock.js                    →11.7 Ay Saati, yakalanma`
**Yerine:** `  moon-clock.js                    →11.7 Ay Saati (düğümden buz saatine), yakalanma`

## A2. §1, `src/world/`

**Bul:** `  world.js                       E →1.7 Spec güdümlü kurulum, sis katmanı, dispose`
**Yerine:** `  world.js                       E →1.7 Spec güdümlü kurulum, sis katmanı, dispose; 8.9 altı ışık durağı, setTimeOfDay`

**Bul:** `  sky.js                           →5.1 Kameraya bağlı gök kubbesi`
**Yerine:** `  sky.js                         E →5.1 Kameraya bağlı gök kubbesi; 8.9 gece: yıldız, ay diski`

## A3. §1, `src/ui/`, `src/i18n/strings/`, `src/story/`

**Bul:** `  hud/trust.js, axes.js, clock.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, dilim ve Ay Saati, birlik`
**Yerine:**
```
  hud/trust.js, axes.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, birlik
  hud/clock.js                     →8.9 Gök Kavisi: güneş, ay, evre, bekleyiş düğümü; Ay Saati kipi 11.7
```

**Bul:** `  cook-wheel.js                    →8.5 Tarif çemberi`
**Sonrasına ekle:**
```
  wait-wheel.js                    →8.9 Bekle ve Uyu tekeri
```

**Bul:** `  css/cook-wheel.css               →8.5`
**Sonrasına ekle:**
```
  css/wait.css                     →8.9
```

**Bul:** `  strings/survival.js              →8.5 Ateş, yemek, av`
**Sonrasına ekle:**
```
  strings/time.js                  →8.9 Evre, bekleme, uyku, Gök Kavisi
```

**Bul:** `  act1/schedule.js                 →11.1 NPC programı (act1.md §5)`
**Sonrasına ekle:**
```
  act1/days.js                     →11.1 Hikâye günleri: ana iş, vakitler, kesmeler (d2/time.md §9.2)
```

## A4. §2.2 Durumlar

**Bul:** `| `freeroam` | Serbest Gez | `game.update`, `world.update(dt, t, game.pos)`, HUD | `post.render(world.scene, blend ?? game.camera)` | `game`, üstünde ince `freeroam` (`map`, `mood`); üstüne `cook_wheel` |`
**Yerine (yalnız bu hücre değişir):** `` `game`, üstünde ince `freeroam` (`map`, `wait`); üstüne `cook_wheel`, `wait_wheel` ``

**Bul:** `` `pause.pausesClock` true: Ay Saati, Tokluk, yapım durur (`progression.md` §14.1). `map` açıkken de `game.update` çalışmaz, dolayısıyla aynı sonuç. ``
**Sonrasına ekle:**
```
**Dünya saati (K20, d2/time.md §6).** `ClockSystem` (§3.7, order 15) yalnız `freeroam` ve `play`'de saati akıtır, `home`'da menü ışığına iğneler. `menu`, `newgame`, `creator`'da dünya saati yoktur: kamp menü ışığındadır (`applyMood(0,3)`, sabit güneş) ve `menuDiff` değişmez. `map`, `pause`, gizli sekme ve `freeze` saati durdurur (`game.update` çalışmaz); bloklayan diyalog, sinema, seviye, Terazi, Yol Kartı ve Bekle tekeri `worldClock.pause(reason)` ile durdurur. Atlas yolculuğu (`travel`) varışta gün kadar atlar.
```

## A5. §2.5 Kare döngüsü

**Bul:** `**Saat.** `core/clock.js` iki zaman verir:` ile başlayan paragrafın sonu (`…`cineNow` bağlı bir işlevdir (Timeline `now` olarak saklar).`)
**Sonrasına ekle:**
```
**Dünya saati.** `core/clock.js` oyun saniyesidir ve değişmez. Dünyanın saati ayrı bir saf sınıftır (`game/world-clock.js`, §3.22): 1 oyun dakikası 2,5 sn, gün 3.600 sn. `App.tick` ona dokunmaz; `ClockSystem.update(dt)` `game.update` içinde ilerletir, bu yüzden durma kuralları durumların ve sistem kiplerinin kendisidir. `__tanhu.step` dünya saatini de ilerletir: gizli bölmede gün belirlenimli koşar.
```

## A6. §2.6 `ctx` sözleşmesi

**Bul:** `  inventory, needs, supply, mounts, player, nodes,        // Faz 8`
**Yerine:** `  inventory, needs, supply, mounts, player, nodes, worldClock, calendar,   // Faz 8 (calendar 8.9'a geçti)`

**Bul:** `  calendar, regions, jobs, quests, dialogue, npcs, stealth, travel, squads,   // Faz 10`
**Yerine:** `  regions, jobs, quests, dialogue, npcs, stealth, travel, squads,   // Faz 10`

## A7. §3.1 Olay veri yolu

**Bul:**
```
| `slice:change` | `{day, slice, prev}` | calendar |
| `dawn` | `{day}` | calendar |
```
**Yerine:**
```
| `clock:hour` | `{day, hour, skipping}` | world-clock (150 sn'de bir; atlamada her saat) |
| `clock:phase` | `{day, phase, prev, skipping}` | world-clock |
| `slice:change` | `{day, slice, prev}` | world-clock (eski dört dilim, evrelerden türer) |
| `dawn`, `dusk` | `{day}` | world-clock (Tan başı, Gece başı) |
| `clock:skip:begin`, `clock:skip` | `{from, to, minutes, reason, sleep}` | world-clock |
| `clock:hold` | `{id, on, at}` | world-clock |
| `day:story` | `{storyDay, prev}` | calendar |
| `beat:state` | `{id, state}` | calendar |
```

## A8. §3.2 Girdi yönlendirici

**Bul:** `` `mood` yalnız geliştirme. ``
**Yerine:** `` `wait` (`T`) Bekle tekerini açar, döşekte Uyu'yu da gösterir (K20, d2/time.md §7); eski `mood` eylemi kalktı, geliştirmede ışık `__tanhu.clock` panelinden sürülür. ``

## A9. §3.5 Kayıt

**Bul:** `SlotInfo = { slot, empty, corrupt, saveNo, savedAt, savedUnix, playTime, act, day, slice, level, place: { world, region, labelKey }, thumb, failed? }`
**Yerine:** `SlotInfo = { slot, empty, corrupt, saveNo, savedAt, savedUnix, playTime, act, day, minute, phase, slice, level, place: { world, region, labelKey }, thumb, failed? }   // slice eski kayıtlar için; kart phase'i yazar`

**Bul:**
```
| `world.zone`, `.act`, `.day`, `.slice`, `.workPoints`, `.jobsToday`, `.jobTypesDone`, `.moonClock`, `.dawnPath` | 70 | `game/calendar.js`; `moon-clock` son ikisini yazar | |
```
**Yerine:**
```
| `world.clock` | 69 | `game/clock-system.js` (`WorldClock.toJSON`) | `{ v, dayN, minute, holds }` |
| `world.zone`, `.act`, `.day`, `.calendar`, `.jobsToday`, `.jobTypesDone`, `.moonClock`, `.dawnPath` | 70 | `game/calendar.js`; `moon-clock` son ikisini yazar | `day` hikâye günüdür; `slice`, `workPoints` kalktı, göç d2/time.md §13 |
```

**Bul:** `**Oto kayıt nedenleri.** `slice`, `quest_done`,`
**Yerine:** `**Oto kayıt nedenleri.** `dawn`, `sleep`, `wait` (≥1 oyun saati), `quest_done`,`

**Bul:** `**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime }``
**Yerine:** `**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, clock:{day,minute}, flags, playTime }` (`mood` artık yazılmaz; okunursa saate göç eder: >0,75 akşam 18:38, değilse menü dakikası 14:46,2)`

## A10. §3.7 Aktör, Game ve sistemler (sistem tablosu)

**Bul:** `| 12 | `child` | `game/child.js` | freeroam, home |`
**Sonrasına ekle:** `| 15 | `clock` | `game/clock-system.js` | freeroam, play, home |`

**Bul:** `| 80 | `npcs` | `game/npcs.js` | play |`
**Sonrasına ekle:** `| 81 | `camp_life` | `game/camp-life.js` | freeroam |`

**Bul:** `` `ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures` çalışır. ``
**Yerine:** `` `ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures` ve iğneli `clock` çalışır. ``

## A11. §3.8 WorldSpec, Terrain, World

**Bul:** `  sun: { dir: [-0.66, 0.6, 0.46], shadowSize: 4096, extent: 46, near: 4, far: 220, gridSize: 92, every: 1 },`
**Sonrasına ekle:**
```
  light: { lat: 47.35, dec: 7.4223, menuMinute: 886.18 },   // iğneli bahar, 10 Nisan; sun.dir bu günün 14:46,2'sindeki gerçek güneştir (d2/time.md §5.5)
```

**Bul:** `  moods: { stops: [MOODS.golden, MOODS.dusk], startT: 0.3 },   // kış: morning, noon, evening, night; t 0..3`
**Yerine:** `  moods: { stops: [MOODS.golden, MOODS.dusk], startT: 0.3, cycle: { palettes: MOODS, golden: 820 } },   // menü golden→dusk 0,3; Serbest Gez altı durak (night, dawn, morning, noon, golden, dusk); kış: light { lat: 38.9 }, cycle WINTER_MOODS, golden 840`

**Bul:** `  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır`
**Yerine:**
```
  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır; menü yolu, değişmez
  applyMoodMix(a, b, f);  setTimeOfDay(sample | null);  timeDriven;   // 8.9: saat ışığı; applyMood(t) ≡ applyMoodMix('golden','dusk',t); null menü değerlerini yazar
```

**Bul:** `**Gök, sis katmanı, göl hattı (Faz 4–5).**` ile başlayan paragrafın sonu
**Sonrasına ekle:**
```
**Saat ışığı (8.9, d2/time.md §5).** `MOODS` altı durak taşır: `night`, `dawn`, `morning`, `noon`, `golden`, `dusk`; son ikisi bugünkü değerlerdir. `setTimeOfDay(sample)` 4 Hz'de (bekleme akışında her kare) iki durağı karıştırır, `sunDir`'i (kubbenin `uSunDir`'iyle aynı nesne) ve güneş yoğunluğunu yazar; ayırma yapmaz, `TONES` bütün durakları bir kez çözer. Geceleri aynı `DirectionalLight` ay ya da gök yönündendir; ışık eklenmez, program sayısı değişmez. Menü, Yeni Oyun, oluşturucu ve `home` `applyMood`'u kullanır, saati okumaz. Serbest Gez yeni oturumda menü dakikasında (14:46,2) açılır: o dakikada saat ışığı menü ışığıdır, süzülme yoktur.
```

## A12. §3.14 Bayrak, koşul, etki, görev

**Bul:** `       | 'slice:'name | 'atlas:'id | 'tally:'npc`
**Yerine:** `       | 'slice:'name | 'phase:'name | 'beat:'id'.'state | 'atlas:'id | 'tally:'npc`

**Bul:** `name  := trust | kut | korku | herd_habit | reflex | names_known | hearths_out | bond | act | day | level | rank`
**Yerine:** `name  := trust | kut | korku | herd_habit | reflex | names_known | hearths_out | bond | act | day | hour | dark | moon | level | rank`

**Bul:** `| `work` | `n` | `calendar.addWork` |`
**Yerine:** `| `clock` | `'set', 'hh:mm'` · `'atLeast', çapa` · `'advance', dk` · `'hold', id, 'hh:mm'` · `'release', id` | `worldClock`; yalnız ileri (d2/time.md §6.4, §12.7) |`

## A13. §3.16 Ajanlar, program, gizlilik

**Bul:** `export function resolveSchedule(table, npcId, { day, slice, flags, overrides });`
**Yerine:** `export function resolveSchedule(table, npcId, { day, minute, flags, overrides });   // table: [[from, to, at, job], …] dakikayla (d2/time.md §9.4)`

**Bul:** `  onSlice(day, slice);          // yeni hedefler; >60 m ve kadraj dışında konum sıçraması`
**Yerine:** `  onBlock(day, minute);         // blok değişince yeni hedef; yürüme süresi kadar önce çıkar; >60 m ve kadraj dışında konum sıçraması; clock:skip'te herkes yerine`

## A14. §3.19 Sinema zaman çizelgesi

**Bul:** `` Ozan tutamağı §3.8 `world.folk.bard.perform`; `Folk`'a taşınmaz (§8 karar 3). `` (Kurallar paragrafının sonu)
**Sonrasına ekle:**
```
**Dünya saati.** Sinema dünya saatini varsayılanda durdurur; `clock` izi saati yalnız ileri taşır (`set`, `atLeast`, `advance`) ya da sinema boyunca akıtır (`run: true`), atlanan süre `worldClock.skip` ile işlenir. Atlamada `clock` satırları da uygulanır.
```

## A15. §3.22 Yardımcı oyun servisleri

**Bul:**
```
// game/calendar.js (saf): act1.md §2
export class Calendar {
  act; day; slice; workPoints; jobsToday; jobTypesDone;
  addWork(n);  setSlice(name);  setDay(n);  sleep();  eatDinner();   // slice:change, dawn
  moodIndex();                                                        // spec.moods.stops konumu
  toJSON();  fromJSON(o);
}
```
**Yerine:**
```
// game/world-clock.js (saf): K20. 1 oyun dk = 2,5 sn; gün 1.440 dk
export class WorldClock {
  constructor({ bus, day, minute, info });
  day; minute; abs; hour; info; phase; slice; dark; held; paused; rate;
  advance(dtReal);  pause(reason, on);  hold(id, { at, until, note });  release(id);  holds();
  skip(minutes, { reason, sleep });  setTo(absMinute, { reason });  next(target);
  toJSON();  fromJSON(o);
}
// game/daylight.js (saf): solarDec, dayInfo, sunAt, moonAt, phaseAt, sliceOf, skyKeys, skyAt, lightSource, lightLevel, MENU_MINUTE
// game/calendar.js (saf): K20, act1.md §2
export class Calendar {
  constructor({ bus, clock, cond, effects, story, moonEpoch = 1044.75 });
  act; storyDay; jobsToday; jobTypesDone;
  dayN; count; yearBC; doy; season;  moonAge(abs); moonIllum(abs); lunarMonth(abs);
  beat(id); beats(); mainDone(); canSleep(bedId); sleep(target); wait(target); iceAt();
  toJSON();  fromJSON(o);
}
// game/clock-system.js: GameSystem 'clock' (15); 4 Hz world.setTimeOfDay, bekleyiş koşulları, Bekle ve uyku, __tanhu.clock
```
(Sözleşmenin tamamı `d2/time.md` §12.2–§12.5.)

## A16. §4.3 Sinema veri biçimi

**Bul:** `  subtitles: 'voice',           // voice bloğundan üretilir`
**Önüne ekle:**
```
  clock:  [ { t: 0, set: '10:40' } ],   // isteğe bağlı: set | atLeast: 'civilDawn-30' | advance: dk | run: true (d2/time.md §6.4)
```

## A17. §4.5 Örnek

**Bul:** `` 1. `slice:change` `mq_count` bitmişken koşulu tutturur: ``
**Yerine:** `` 1. `slice:change` (öğle evresi 10:30) `mq_count` bitmişken koşulu tutturur; Gün I'in gerçek vakti `hour>=12`'dir (öğle çanı, d2/time.md §9.2): ``

## A18. §5 Uygulama fazları

**Bul (Faz 8 tablosu):** `| 8.8 | `src/game/player.js`, `src/game/mounts.js`, `src/game/child.js`, ` ile başlayan satır
**Sonrasına ekle:**
```
| 8.9 | `src/game/world-clock.js`, `src/game/daylight.js`, `src/game/calendar.js`, `src/game/clock-system.js`, `src/game/camp-life.js`, `src/world/world.js`, `src/world/sky.js`, `src/app/states/freeroam.js`, `src/core/keymap.js`, `src/game/save.js`, `src/ui/hud/clock.js`, `src/ui/wait-wheel.js`, `src/ui/css/wait.css`, `src/ui/menu/save-panel.js`, `src/i18n/strings/time.js`, `src/i18n/strings/save.js`, `test/world-clock.test.js`, `test/daylight.test.js`, `test/sky-keys.test.js`, `test/calendar.test.js` | K20, `d2/time.md`: dünya saati, gün ışığı, altı ışık durağı, Bekle ve Uyu, ana kamp programı | `menuDiff` 0 (taze, gece oturumu sonrası); yeni oturumun ilk karesi menü ışığında; altı durakta program 57; `lapse(24)` bir şafak |
```

**Bul (Faz 8 `L` satırı):** `` `L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları. ``
**Yerine:** `` `L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları (`clock` 15, `camp_life` 81, `ctx.worldClock`, `ctx.calendar`); `src/ui/hud.js` geliştirme ışık düğmesi kalkar, Gök Kavisi yuvaya takılır; `src/app/sounds.js` ortamı evreye bağlar (d2/time.md §8.5). ``

**Bul (Faz 10):** `| 10.1 | `src/game/quests.js`, `src/game/calendar.js`, `src/game/regions.js`, `src/game/jobs.js`, `test/quests.test.js`, `test/calendar.test.js`, `test/regions.test.js`, `test/jobs.test.js` | §3.14, §4.1; `act1.md` §2 | Rütbe ve İş Puanı tablosu |`
**Yerine:** `| 10.1 | `src/game/quests.js`, `src/game/regions.js`, `src/game/jobs.js`, `test/quests.test.js`, `test/regions.test.js`, `test/jobs.test.js` | §3.14, §4.1; `act1.md` §2 | Rütbe tablosu; vakit ve uyku kapısı `calendar` (8.9) ile |`

**Bul:** `| 10.7 | `src/ui/journal.js`, `src/ui/info-card.js`, `src/ui/css/journal.css`, `src/ui/hud/trust.js`, `src/ui/hud/axes.js`, `src/ui/hud/clock.js`, `src/ui/hud/squad-bar.js`, `src/i18n/strings/quests.js` | Görevler, kural kartı, Çentik, güneş ve kor, dilim |`
**Yerine:** `| 10.7 | `src/ui/journal.js`, `src/ui/info-card.js`, `src/ui/css/journal.css`, `src/ui/hud/trust.js`, `src/ui/hud/axes.js`, `src/ui/hud/squad-bar.js`, `src/i18n/strings/quests.js` | Görevler (vakitler evreyle), kural kartı, Çentik, güneş ve kor |`

**Bul:** `| 11.1 | `src/story/act1/schedule.js`, `src/story/act1/guards.js`, `src/story/act1/regions.js`, `src/story/act1/jobs.js` | `act1.md` §2, §4, §5 | Bütün kişiler her dilimde yerde |`
**Yerine:** `| 11.1 | `src/story/act1/schedule.js`, `src/story/act1/days.js`, `src/story/act1/guards.js`, `src/story/act1/regions.js`, `src/story/act1/jobs.js` | `act1.md` §2, §4, §5; d2/time.md §9.2, §9.4 | Bütün kişiler her saat bloğunda yerde; her günün ana işi gece de yapılabilir |`

**Bul (11.7 satırı, «Bitti» hücresi):** `| Saat biterse `dawn_path` |`
**Yerine:** `| Buz saati Normal 06:40, Zor 05:10, Hikâye 05:45 bekleyişi; saat biterse `dawn_path` |`

## A19. §6.1 `node:test`

**Bul:** `| `calendar`, `regions`, `jobs` | `game/calendar`, `game/regions`, `game/jobs` | `act1.md` §2 |`
**Yerine:**
```
| `world-clock`, `daylight`, `sky-keys`, `calendar` | `game/world-clock`, `game/daylight`, `game/calendar` | d2/time.md §17: gün ışığı altın değerleri, menü vektörü 10 Nisan 14:46,2, bekleyiş, atlama olay sırası, buz saati, dolunay Gün IV |
| `regions`, `jobs` | `game/regions`, `game/jobs` | `act1.md` §2 |
```

**Bul (saf listesi):** `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,jobs,`
**Yerine:** `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,world-clock,daylight,jobs,`

## A20. §6.3 `window.__tanhu`

**Bul:** `  struct, travel, econ, squads, story, stealth, cine, audio, i18n, save,`
**Yerine:** `  struct, travel, econ, squads, story, stealth, cine, audio, i18n, save, clock,`

**Bul:** `| `save` | `write, load, dump, corrupt, usage` | 3.3 |`
**Sonrasına ekle:** `| `clock` | `get, set('hh:mm'), next(phase), skip(min), lapse(h), hold(id, hhmm), release(id), keys, stop` | 8.9 |`

**Bul (faz sonu tablosu):** `| 8 | `econ.give`, toplama, `derive`, `pause` sayfaları |`
**Yerine:** `| 8 | `econ.give`, toplama, `derive`, `pause` sayfaları; `clock.set` altı durak, `clock.lapse(24)`, gece oturumu sonrası `menuDiff` |`

## A21. §7 Performans bütçesi

**Bul:** `` **Dağılım.** JS kare tavanları: `` ile başlayan paragrafta `` `Quests`, `Calendar`, `Regions` ≤0,1; ``
**Yerine:** `` `Quests`, `Calendar`, `Regions` ≤0,1; `ClockSystem` ≤0,02 (4 Hz ışık yazımı ≤0,03 çağrı başına); `CampLife` ≤0,05; atlamanın toplu işi karartma altında ≤50 ms / 12 oyun saati; ``

## A22. §8 Kararlar ve uzlaştırma

Sonraki boş numaralarla (Faz 7 yeni satır eklediyse ardından):

```
| 37 | K20: 1 gün = 60 dk | İş Puanlı dilim sahneyi güvenceye alıyordu; gerçek saatte sahne kaçabilir | Vakit pencereleri ve saat bekleyişleri; günün ana işi uykuyu açar; sinema kesmeleri yalnız ileri | Sahne güvenliği saatte kalır, ışık maliyeti yalnız tekdüzen (d2/time.md §6) |
| 38 | K20: ana kamp tam gün döngüsü / §0 kural 8 menü değişmez | İkisi birden | Menü yolu saati hiç okumaz; ana kampın mevsimi menü güneşinden hesaplandı (47,35°K, 10 Nisan, 14:46,2): o dakikada saat ışığı menü ışığıdır | Yeni oturum sıçramasız, `menuDiff` 0 (d2/time.md §5.5) |
| 39 | K20: gece / §0 kural 7 ışık eklenmez | Ay ışığı yeni ışık ister gibi | Aynı `DirectionalLight` ay ya da gök yönünden; alacakaranlıkta yön döner, yoğunluk çukura iner | Program ve ışık sayısı aynı |
| 40 | §8 karar 25: `T` yalnız geliştirmede ışık değiştirir | K20 bekleme ve uyku tuşu ister | `T` her pakette Bekle; geliştirme ışığı `__tanhu.clock` panelinde | Okuyucusuz tuş kalmaz |
```

**Bul:** `| 25 | §3.2: `mood` yalnız geliştirme |` ile başlayan satırın son hücresi
**Sonuna ekle:** ` K20'de kalktı: §8 karar 40.`
