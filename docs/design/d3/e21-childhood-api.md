# E21 Çocukluk API'si (Ç1, 2026-11-09)

Ç1'in kurduğu genişleme noktası ve yerler. Ç2 («Ak Kemik», «Ebenin Çetelesi») ve ana oturum bunu kullanır. Bu dosya ilk yarım saatte yazıldı; uygulama ilerledikçe aynı adlarla güncellenir, değişen ad olursa en altta «Değişiklikler»e yazılır.

## 1. Günlerin sırası

- `game/data/story/childhood_days.json`: Çocukluk'un günleri sırayla. Her gün bir sahne dosyasıdır (bugünkü `data/story/childhood/scene.json` biçimi: `id, title, date, day_n, clock, flags, music, ambience, player, vo_prefix, speakers, lines, barks, actors, steps`).

```json
{"days": [
  {"id": "day1_flock", "path": "res://data/story/childhood_days/day1_flock.json"},
  {"id": "day1_bone",  "path": "res://data/story/childhood_days/day1_bone.json", "card": false},
  {"id": "day2_tally", "path": "res://data/story/childhood_days/day2_tally.json"},
  {"id": "count",      "path": "res://data/story/childhood/scene.json"}
]}
```

- Gün bitince (son adım biter) sıradaki gün aynı Ordos dünyasında açılır: dünya, sürü ve iki binek koyun yerinde kalır; kişiler (`actors`) yeni günün verisinden yeniden kurulur. `card: false` olan gün (aynı akşam) kısa kararmayla (0,6 sn) açılır, kart yoktur; öteki günler kara perdede kendi `date` kartıyla açılır (TR ve EN: «21 Eylül MÖ 228 · Ordos» / «21 September 228 BC · Ordos»).
- Dosyası olmayan ya da boş gün sessizce atlanır (yer tutucu `day1_bone.json` ve `day2_tally.json` Ç2'nindir; Ç1 yalnız dosya yoksa en küçük yer tutucuyu yazar).
- Takvim: her günün `day_n`'i yolculuğa yazılır (K67, yalnız ileri): 20 Eylül MÖ 228 = −5.602, 21 Eylül = −5.601, 22 Eylül (sayım) = −5.600.
- Kod: `ChildhoodDays` (`scripts/story/childhood_days.gd`, saf): `load_default()`, `ids()`, `path_of(id)`, `next_of(id)`, `day_of_step(step)`, `resolve(day_arg, step_arg) -> {day, step}`.
- Sahne bitişi: `ChildhoodScene.finished(result)`; result'ta `next_day` (sıradaki günün kimliği) varsa main.gd sıradaki günü açar, yoksa bugünkü gibi (son gün: «Beni gördü.», Köprü 1).
- Geliştirme: `--state=newgame --stage=childhood --day=day1_flock --step=flock_lake` (ya da `--step=day1_flock:flock_lake`). Yalnız `--step` verilirse adımı içeren ilk gün açılır (`--step=count` bugünkü gibi sayım günüdür). `--autoplay --autoplay-quit=day` günü bot oynar ve günün süresini yazar («gün … bitti: … sn»). Sınamalarda `main.childhood_day`, `main.childhood_step` ve `main.childhood_days_path` (boş: yalnız sayım günü; `"stage"`: aşamanın `days`'i).
- Günün sesleri gün başınadır: sahne açılınca yalnız kendi sözlerini ister (`AudioManager.request_lines(vo_prefix + anahtar)`), durunca bırakır (`release_lines`); Çobanlık ve Ak Kemik 1. gün, Çetele 2. gün sayılır (`test_vo_budget`, `test_audio_budget`).
- «Çocukluğu geç» üç günü birlikte atlar (Köprü 1; `mq0_sheep` ve `child_skipped` yazılır).

## 2. Adım türleri: kayıt

- Bugünkü dört tür (`reach`, `race`, `hunt`, `count`) `ChildhoodScene`'in içindedir, değişmez.
- Yeni türler ayrı betiktir: `scripts/story/steps/<tür>.gd`, `extends ChildhoodStep`. Kayıt tek satırdır: `scripts/story/steps/childhood_steps.gd` içindeki `KINDS` sözlüğüne `"bone_throw": "res://scripts/story/steps/bone_throw.gd",`. (Adımın verisinde `"script": "res://…"` yazmak da olur; kayıt önce gelir.)
- `ChildhoodStep` (`scripts/story/steps/childhood_step.gd`) yüzü:

| Üye | Ne |
|---|---|
| `scene: ChildhoodScene`, `step: Dictionary`, `phase: String`, `clock: float` | sahne, adımın verisi, evre (`scene.current_phase()` bunu döner), adımın saati (sn) |
| `func start()` | adım başlar (amaç ve ipucu sahne yazar: `objective`, `hint`) |
| `func tick(delta)` | her kare (görüntü donukken çağrılmaz) |
| `func target(from: Vector3) -> Vector3` | HUD'un yönü (yoksa `Vector3.INF`) |
| `func preset()` | geliştirme `--step` bu adımın ötesinden açılırken dünyanın adım sonrası hâli |
| `func cleanup()` | adımın kendi temizliği (bağlantılar, pozlar); `stop()` adım biterken ya da sahne dururken bunu bir kez çağırır |
| `func interaction() -> Dictionary` | adımın E'si: `{key, label, run}` (yoksa boş; oyuncunun E kaynağının önüne geçer) |
| `func autoplay(bot, delta)` | `--autoplay` botu bu adımı oynar (`bot.follow(points, key, run)`, `bot.halt()`, `bot.interact()`, `bot.hold_interact(sn)`) |
| `static func check(step, data) -> PackedStringArray` | verinin eksikleri (`ChildhoodScene.validate` çağırır) |
| `func line_keys() -> Array` | andığı satırlar (doğrulama) |
| Yardımcılar | `done()` (sıradaki adım), `say(key) -> sn`, `at(sn, fn)`, `point(spec)`, `points(list)`, `near(p, r)`, `mover(id)`, `actor(id)`, `pace(hız)`, `set_objective({tr,en})`, `set_hint({tr,en})`, `bark(olay)`, `pose(id, klip)` (kişiye kütüphane klibi; `unpose(id)`), `hold(id, açık)` (kişinin StoryMover'ını sahnenin tikinden çıkarır), `flag(ad)` (bitişte yolculuğa yazılır), `clock_to(hh:mm, sn)` (görünür akış), `fade(alfa, sn)` |

- Söz kancası her türde aynıdır: adımın `say: [{line, at}]`'ı sahnenin saatinde çalar (bugünkü gibi). Sözler sesli ya da altyazılı akar (`SceneVoice`); satır kimliği `vo_prefix + anahtar` (Çobanlık `act0.flock.`, Ak Kemik `act0.bone.`, Çetele `act0.tally.`).
- Satırların metni `docs/design/d3/e21-lines.json`'dan eşitlenir: `python3 tools/sync_e21_lines.py` günün dosyasının `lines` ve `speakers` bölümünü kimlik önekine göre yeniden yazar (metne elle dokunulmaz).

## 3. Uyku ve günün kartı (tür `sleep`, Ç1'in)

```json
{"id": "bone_sleep", "kind": "sleep", "objective": {"tr": "Yurda gir, yat", "en": "Go in and lie down"},
 "hint": {"tr": "Yatağın yanında E.", "en": "Press E by the bed."}, "bed": "lan_bed", "radius": 1.4,
 "say": [{"line": "end", "at": 0.5}], "fade_s": 1.6, "hold_s": 0.8}
```
- Oyuncu yurda girince yurt diorama olur (dış kabuk ve çatı gizlenir, K98: yukarıdan), yatağın yanında E «Uyu»: çocuk yatağa uzanır (`sleep_normally`), perde kararır, adım biter. Kartı main.gd sıradaki günün `date`'iyle kara perdede gösterir. Kişiler `sleepers: [{actor, at, yaw_deg, clip}]` ile kendi yerlerinde yatar.
- Kapı dar olduğundan kapının önünde (duvarın 3,4 m dışına dek, eksenden 2,6 m yana dek) yurda yürüyen oyuncu kapının eksenine yavaşça kayar (1,8 m/sn); bot kapının eksenindeki iki noktadan (dışı, eşiğin içi) girer.
- Yataklar: `lan_bed` (çocuk; güneydeki keçe), `lan_bed_mother` (Lan Hatun; kuzeydeki döşek), `lan_yurt_in` (kapının iç yanı).

## 4. Yerler (işaretler)

Koordinatlar metre: x doğu, z güney (−z kuzey). `world.marker(id)` hepsini verir (zemine oturur). Kaynak `data/maps/childhood_ordos/layout.json` → `childhood.markers`.

| İşaret | x, z | Ne |
|---|---|---|
| `pen_gate`, `pen_inside`, `child_start`, `lan_stand` | bugünkü | ağıl, yurdun önü |
| `lan_bed` | −0,25, 1,35 | Lan Hatun'un yurdunda çocuğun yatağı (güney keçesi) |
| `lan_bed_mother` | −0,3, −1,3 | Lan Hatun'un döşeği |
| `lan_yurt_in` | 1,7, 0,0 | yurdun içi, kapının yanı |
| `bone_post` | 18,0, 4,0 | bağlama direği (Ak Kemik'in direği; kodla kurulur) |
| `bone_field` | 46,0, 10,0 | kemiğin atıldığı karanlık çayırın ortası |
| `lake_center` | 368, 20 | Kamışlı Göl'ün ortası (eski yatak K–G uzanır, ≈130 × 48 m) |
| `lake_view` | 300, 25 | ılgınların ardı: göl buradan görünür |
| `lake_beach` | 338, 30 | batı kıyısı, kumlu kıyı (çocuklar buradan suya girer) |
| `lake_drink` | 344, 34 | sürünün içtiği kıyı (`water_line`) |
| `lake_graze` | 334, 46 | kıyının otlağı (sürü içtikten sonra burada otlar) |
| `lake_shallow` | 349, 28 | sığ (dizden aşağı) |
| `lake_wade` | 354, 27 | belden aşağı (yürünür, yavaş) |
| `lake_swim` | 358,5, 24 | belden derin (yüzülür) |
| `lake_deepest` | 370, 20 | en derin bölge (girilmez: akıntı geri iter) |
| `lake_reeds` | 350, −18 | sazlık (kuzeybatı kıyı) |
| `white_stone` | 356,5, 4 | sazlığın önünde ak taş (yüzme derinliği, dalışla alınır) |
| `stone_shore` | 344, 4 | taşın karşısındaki kıyı (botun suya girdiği yer) |
| `lake_mud` | 343, −32 | sazın dibinde balçık (kuzu burada saplanır) |
| `lake_fox` | 332, −43 | tilkinin beklediği yer |
| `count_stone_a`, `count_stone_b` | 318, 23,6 / 318, 28,4 | iki sayım taşı (aralık 4,8 m, kapı K–G) |
| `count_gate` | 318, 26 | sayım kapısının ortası |
| `count_after` | 300, 26 | sayımdan sonra sürünün durduğu yer (yolun sonu) |
| `noon_rest` | 333, 39 | öğle dinlencesi: kıyıda otlu yamaç |
| `flock_way_1`, `flock_way_2`, `flock_way_3` | 84, 30 / 160, 30 / 240, 27 | ağıldan göle giden yolun durakları |
| `dusk_hill` | −120, 40 | güneşin battığı tepe (batı ufku; işaret yalnız yön içindir) |
| `ebe_center` | 16, −324 | Ebe Obası'nın ortası |
| `hereka_yurt` | 20, −326 | Hereka'nın yurdu (açık yurt, içi kurulur; kapı doğuya) |
| `hereka_door` | 24,2, −326 | Hereka'nın kapısının önü |
| `ebe_yurt_a`, `ebe_yurt_b` | 4, −336 / 32, −342 | obanın öteki iki yurdu |
| `ebe_dogs` | 22, −307 | iki köpeğin yattığı yer (köpekler Ç2'nin) |
| `ebe_call` | 22, −294 | durup «Köpeğinizi tutun!» denen yer |
| `ebe_fire` | 14, −316 | obanın açık ocağı |
| `dry_stream_south`, `dry_stream_north` | 40, −52 / 26, −286 | kuruyan dere yatağının iki ucu (Çetele'nin yolu) |

- Yollar (zemin maskesinde çiğnenmiş iz): ağılın kapısından göle (`paths.lake`), yurtlardan Ebe Obası'na kuruyan dere boyunca (`paths.ebe`). Ilgın çalıları `lake_view`'un önünde bir kuşak; kuruyan dere yatağı kum ve çakıldır, kıyısında karagan ve pelin.
- Yürünür alan ve kamera sınırı büyür: alan artık birleşik bir biçimdir (kampın dairesi + göle ve obaya giden geniş koridorlar + gölün ve obanın daireleri; `ChildhoodSite.in_walk_area(layout, p)`); kamera kutusu `[−60, −396]`–`[460, 128]`.
- Göl ve geniş zemin yalnız Çocukluk'tadır (doğumun bozkırı bugünkü gibidir, sinemanın kurulumu beklemez): gölün tanımı `childhood.lake`, geniş sık ızgara `childhood.ground.dense` (göle ve obaya giden yolda hücre 4 m), geniş yükselti ve maske ızgarası `childhood.ground.area_e21`. `ChildhoodSite.merged_spec` bunları Çocukluk'un yüzüne ekler, `OrdosWorld.birth_spec` doğumunkinden çıkarır. ChildhoodSite geniş ızgarayı kendi bantlarında pişirir, zemini dört parça kurar (`Terrain`, `Terrain1`…; normaller ızgaranın komşularından), suyu ve kıyıyı (`Lake/Water`, sazlık, balçık, taşlar) ve uzak yerleri adım adım kurar. İşler düşük önceliklidir; başsızda eşya ve kalabalık dokuları eşzamanlı yüklenir (`FaunaMesh.background_loads`).
- `world.water_at(x, z) -> {level, depth, inside, inset, deep}`, `world.lake_info()`; doğumda göl yoktur (`level` NAN).
- Dailin sayım günü toplanır: `site.set_dailin_gathered(açık)` kalabalığı ve hattın bayraklarını gösterir; 20–21 Eylül'de (günün verisinde `dailin_gathered` yoksa sayım günü dışındaki her gün) ufukta yalnız Dailin'in dumanları ve gece ateşleri (`Reaches/Fires`) görünür.

## 5. Saat ve ışık

- Her günün kendi saati vardır: `clock.start` (hh:mm), `clock.seconds_per_minute` (2,5; K67). Sahne saati `GameClock`'tur, ışık izler (`OrdosWorld.set_childhood_time(dakika)`).
- Işık örnekleri `data/maps/childhood_ordos/light.json`'da dakikaya göre sıralıdır: şafak çiyi (07:00), sabah (08:40), geç sabah (11:00), öğle (13:30), ikindi altını (16:20), gün batımı (17:50), mavi saat (18:25), ay doğuşu (18:55), ay gecesi (20:30). Renkler komşu iki örnek arasında karışır, güneş ve ay o dakikanın gerçek yerindedir (39°K); akşamdan geceye ana ışık aya döner (`light_from_moon`). Gece: serin gümüş mavi ana ışık, belirgin uzun ay gölgeleri, koyu mavi gölge dolgusu. Sayım günü (08:40–11:00) değişmez.
- Gece kapı ışığı: gün batımından sonra (`ChildhoodReaches.night_of(dakika)`) kampın yurtlarının kapısının önüne turuncu ışık havuzu düşer (`Childhood/DoorPools`, sahte), Lan Hatun'un yurdunun kapısındaki gerçek ışık (`DoorSpill`) yanar; ufukta Dailin'in ateşleri belirir.
- Görünür akış: `step.clock_to("16:20", 6.0)` (ya da sahnede `scene.lapse_to(dakika, sn)`); söz sırası saati durdurur (bugünkü gibi).
- Dolunay 20 Eylül akşamı doğuda doğar (8. ayın dolunayı 21 Eylül; Ç2'nin akşamı için `moon` örneği hazırdır).

## 6. Kayıt noktası

- Ö1'in düzeneği kullanılır (`e21-prologue-api.md`); ikinci düzenek kurulmaz. Ç1 her günün başında `ChildhoodScene.day_started(day_id)` yayar; main.gd bunu `flow_save_point("childhood", day_id)`'ye bağlar, Yeni Oyun kayıtlıysa `flow_resume_day("childhood")` o günün başından açar. Geliştirme koşuları (argümanlı) kayda yazmaz.

## 7. Ses

- `ChildhoodAtmos` (`scripts/story/childhood_atmos.gd`): günün verisindeki `atmos.beds` (döngü: kimlik, merkez işareti, yarıçap, saat aralığı) ve tek seferlik `sfx(kimlik, yer)`. Dosya yolları `docs/design/d3/e21-atmosphere.md`'nin kuralıdır: `audio/ambience/e21/<kimlik>.wav`, `audio/sfx/e21/<kimlik>[_a|_b|_c].wav`. Dosya yoksa yer tutucu çalar (var olan ses), dosya gelince kendiliğinden yerine geçer. Aynı anda en çok 3 yatak.

## 8. Yüzme (çocuk denetleyicisi)

- `ChildSwim` (`scripts/player/child_swim.gd`, oyuncunun çocuğu): suyun yüzü dünyadan (`world.water_at(x, z) -> {level, depth}`, Kamışlı Göl). Bantlar: kuru, sığ (dizden aşağı: yavaş yürüme, sıçrantı), bel (yavaş yürüme), yüzme (belden derin: yavaş, baş üstte, kol vuruşu kodla), en derin (girilmez: akıntı geri iter, `pushed_back` yayılır). Derinde E 1,5 sn'lik dalış (`dived`); yüzerken koşu, binme, yay ve zıplama yok. Çıkınca 25 sn ıslak ton.
- Kişiler (Luhun, Yançi) için de aynı poz: `SwimPose.apply(actor.avatar, açık)`.

## 9. Sürü

- `HerdField` / `HerdSim` yeni evreler `DRIVEN` ve `WATER`: sürü sürücülerden kaçar (yolun ileri yönüne eğilerek), öndekini izler, yolu izler; sapan koyun sürücü önüne geçince döner. Yolun sonunu geçen koyun ileri itilmez (sürü hedefte durur). `herd.drive_along(yol, yarıçap)`, `herd.set_drivers(düğümler, yarıçaplar)`, `herd.set_leader(düğüm)`, `herd.stray(yan, sayı, uzaklık)`, `herd.water(su_çizgisi, otlak, yarıçap)`, `herd.count_through(a, b)` (iki taşın arası; `gate_counted`; kapının önündeki sayılmamış koyun taşların arasına yönelir), `herd.count_gate_one()` (sayımın sonunda geride kalanı sayıcı sayar), `herd.home_to_pen()` (`penned`, `all_in`), `herd.take_out(i)` / `herd.put_back(i, yer)` (kuzu). Engeller ızgaraya dizilir (`OBSTACLE_CELL` 8 m).

## Değişiklikler

- 2026-11-09 (akşam): göl ve geniş zemin doğumun dünyasından Çocukluk'un düğümüne taşındı (`lake` → `childhood.lake`, `ground.dense` → `childhood.ground.dense`, `childhood.ground.area` kampınki, yeni `area_e21`); suyun düğümü `OrdosWorld/Lake` değil `Childhood/Lake/Water`. Nedeni: doğumun dünyası mitin içinde ≈0,9 sn'de hazır olmalı (`test_ordos_world`), geniş ızgara bunu 2,3 sn'ye çıkarıyordu.
- İşaretler değişti: `white_stone` 356,5, 4; `stone_shore` 344, 4 (yeni); `noon_rest` 333, 39; sayım taşları 318'e; `count_after` yeni.
- Adımın temizliği `stop()` değil `cleanup()` (stop onu bir kez çağırır).
