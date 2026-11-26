# E21 Önsöz API'si (Ö1, 2026-11-09)

Ö1'in kurduğu genişleme noktası, yerler ve çağrılar. Ö2 («Kuzular», «Şilde Gecesi», «Güreş», «Ocak») ve ana oturum bunu kullanır. Adlar sabittir; değişen olursa en altta «Değişiklikler»e yazılır. Çocukluk'un eşi `e21-childhood-api.md`'dir (Ç1); iki koşucunun adım yüzü bilerek aynı kalıptadır.

## 1. Günlerin sırası

- `game/data/story/prologue_days.json`: Önsöz'ün oynanan üç günü, her gün sahne dosyaları sırayla. Her sahne bir görevdir.

```json
{"days": [
  {"id": "day1", "day": 1, "day_n": 1168, "date": {"tr": "8 Nisan MÖ 209 · Göl Obası", "en": "8 April 209 BC · Lake Camp"},
   "scenes": ["res://data/story/prologue_days/day1_milk.json", "res://data/story/prologue_days/day1_storm.json"],
   "lines": ["act0.milk.", "act0.storm."]},
  {"id": "day2", "day": 2, "day_n": 1169, "date": {"tr": "9 Nisan MÖ 209 · Göl Obası", "en": "9 April 209 BC · Lake Camp"},
   "scenes": ["res://data/story/prologue_days/day2_lambs.json", "res://data/story/prologue_days/day2_feast.json"],
   "lines": ["act0.lambs.", "act0.feast.", "act0.wrestle."]},
  {"id": "day3", "day": 3, "day_n": 1170, "date": {"tr": "10 Nisan MÖ 209 · Göl Obası", "en": "10 April 209 BC · Lake Camp"},
   "scenes": ["res://data/story/prologue_days/day3_hearth.json"], "lines": ["act0.hearth."]}
]}
```

- `day1_*` Ö1'in, `day2_*` ve `day3_*` Ö2'nindir. Ö1 yalnız dosya yoksa en küçük yer tutucuyu yazar (bir `say` ve sonda `sleep` ya da `cinema`); Ö2 dosyanın tamamını değiştirir. Dosyası olmayan ya da boş sahne sessizce atlanır.
- Günün başı: kara perdede günün kartı (`date`, TR ve EN, 4,4 sn), kayıt noktası (§7), sonra günün ilk sahnesi. Gün içinde sahneler arası: perde kararır, saat sahnenin `clock.start`'ına atlar (geri gitmez), oyuncu sahnenin `player`'ına konur, perde açılır.
- Ses havuzu gün başınadır (`test_audio_budget`, `test_vo_budget` her günü ayrı sayar): günün `lines`'ı söz kimliklerinin önekleridir; koşucu günün başında yalnız o günün sözlerini yükler (`AudioManager.request_lines`; `PrologueDays.day_line_ids(order, gün, sözler)`) ve gün bitince bırakır (`release_lines`; Önsöz bitince, atlanınca ya da koşucu durunca da). Günün sahnelerinin adımlarda andığı sözler de (`PrologueSteps.line_refs`) her zaman eklenir. Ö2'nin günleri aynı yoldadır: yeni bir görev öneki gelirse günün `lines`'ına eklenir.
- Gün `sleep` adımıyla biter (§3); son günün son sahnesi `cinema` ile biter (§6). `night_end` adımı (tipi gecesi gibi yatağa gidilmeyen gece) karartır ve günü bitirir.
- Kod: `PrologueDays` (`scripts/story/prologue_days.gd`, düğüm). Saf yardımcılar: `PrologueDays.load_order()`, `PrologueDays.scene_ids(order)`, `PrologueDays.resolve(order, day, quest) -> {day_index, scene_index}`.
- Geliştirme: `--state=newgame --stage=prologue --day=2 --quest=lambs` (gün 1–3; görev sahne kimliği ya da dosya adının sonu: `milk`, `storm`, `lambs`, `feast`, `hearth`), `--step=<adım>` o sahnenin o adımından. `--autoplay` görevleri tuşsuz oynar (§9). Sınamada `main.prologue_day`, `main.prologue_quest`, `main.prologue_step`.

## 2. Sahne dosyası

```json
{
  "id": "lambs", "title": {"tr": "Kuzular", "en": "The Lambs"},
  "clock": {"start": "07:20", "seconds_per_minute": 2.5},
  "player": {"at": "gol_family_bed", "pose": "sleep", "yaw_deg": 0},
  "family_yurt": "open",
  "weather": {"type": "clear", "snow": 1.0, "snow_melt": 0.25, "mist": 0.3},
  "music": "mus_prologue_day",
  "beds": [{"id": "amb_snow_morning", "at": "gol_center", "radius": 70}],
  "cast": {"mother": {"at": "gol_family_door", "face": "gol_fire", "work": "stand"}},
  "steps": [{"id": "wake", "kind": "wake", "line": "act0.lambs.ana"}, {"id": "find", "kind": "lambs_find"}]
}
```

- `cast`: kişi kimliği → `{at, face, work, hidden, walk}`. Kişiler `scripts/story/prologue_cast.gd`'nin kalıbıyla kurulur (CineActor + StoryMover). Kimlikler: `mother`, `father`, `older_brother`, `bard`, `oktar`, `erka`, `dengiz` (Göl Obası); `saruk`, `kunay`, `tonga`, `boru`, `birch_woman`, `birch_man`, `birch_elder`, `birch_girl` (Kayın Obası). `work` kişinin işidir (kütüphane klibi anahtarı ya da kısa ad: `milk`, `felt`, `kopuz`, `carve`, `sit`, `stand`, `sweep`, `play`).
- Satırlar `data/story/prologue_days/lines.json`'dadır (`docs/design/d3/e21-lines.json`'un `act0.milk/storm/lambs/feast/wrestle/hearth` satırları; eşitleme `python3 tools/sync_prologue_lines.py`). Adım satırı tam kimlikle anar: `"line": "act0.lambs.ana"`. Metne elle dokunulmaz.
- `weather.type`: `clear`, `cloud`, `overcast`, `fog`, `snow`, `blizzard` (hava tablosunun türleri); `snow` kar örtüsü (0..1), `mist` sabah sisi (0..1).

## 3. Adım türleri: kayıt

- Tür ayrı betiktir: `scripts/story/steps/<tür>.gd`, `extends PrologueStep`. Kayıt tek satırdır: `scripts/story/steps/prologue_steps.gd` içindeki `KINDS` sözlüğüne `"lambs_find": "res://scripts/story/steps/lambs_find.gd",`. (Adımın verisinde `"script": "res://…"` de olur.)
- Ö1'in genel türleri: `say` (söz sırası), `reach` (yere git), `wait` (bekle; sözler ve olaylar saatle), `interact` (yerde `E`; basılı `hold_s`), `fade` (perde), `clock` (saati atlat ya da görünür akıt), `weather` (hava), `cast` (kişiyi yürüt, iş ver, gizle), `wake` (yatakta uyanış), `sleep` (yatağa `E`, kararma, gün biter), `night_end` (karartma, gün biter), `cinema` (sinemaya geçiş, §6). «Süt» ve «Tipi»nin türleri: `milk_*`, `storm_*`.
- `PrologueStep` (`scripts/story/steps/prologue_step.gd`) yüzü (Ç1'in `ChildhoodStep`'iyle aynı kalıp):

| Üye | Ne |
|---|---|
| `days: PrologueDays`, `step: Dictionary`, `phase: String`, `clock: float` | koşucu, adımın verisi, evre, adımın saati (sn) |
| `func start()` | adım başlar (amaç ve ipucu koşucu yazar: `objective`, `hint`) |
| `func tick(delta)` | her kare |
| `func target(from) -> Vector3` | HUD'un yönü (yoksa `Vector3.INF`) |
| `func interaction() -> Dictionary` | oyuncunun `E`'si: `{key: "E", label: "Dök", run: Callable}` ya da boş |
| `func preset()` | geliştirme `--step` bu adımın ötesinden açılırken dünyanın adım sonrası hâli |
| `func cleanup()` | adım biterken ya da koşucu dururken (bir kez) |
| `func autoplay(bot, delta)` | `--autoplay` botu bu adımı oynar (`bot.follow(points, run)`, `bot.go_to(p, run)`, `bot.halt()`, `bot.press_e()`, `bot.hold_e(sn)`) |
| `static func check(step, data) -> PackedStringArray` | verinin eksikleri |
| `func line_keys() -> Array` | andığı satırlar (doğrulama) |
| Yardımcılar | `done()`, `say(id) -> sn`, `say_seq([id, …]) -> sn`, `at(sn, fn)`, `point(spec)`, `near(p, r)`, `actor(id)`, `cast(id)` (`PrologueCast.Person`), `player()`, `world()`, `places()`, `pace(hız)`, `set_objective({tr,en})`, `set_hint({tr,en})`, `set_detail(metin)`, `flag(ad, değer)`, `result(ad, değer)` / `days.results`, `clock_to(hh:mm, sn)`, `jump_clock(hh:mm)`, `fade(alfa, sn)`, `weather(tür, sn, {params})`, `sfx(kimlik, yer)`, `bed(kimlik, açık)`, `music(kimlik)`, `carry(kimlik)` (elde eşya: `ember_pot`, `milk_yoke`, `lamb`, `wood`, `stone`), `walk_mods({speed_k, can_run})` |

- Söz kancası her türde aynıdır: adımın `say: [{line, at}]`'ı adımın saatinde çalar; `on_done: [{line}]` adım biterken.

- İşin süresince oyuncuyu yerinde tutmak için `walk_mods(HOLD_MODS)` (`PrologueStep.HOLD_MODS`: hız çarpanı 0,02; koşu ve zıplama yok). Hız çarpanını 0 yapmayın: HUD'un koşu eşiği yürüme hızıyla çarpılır, sıfırda duran oyuncu «koşuyor» sayılır ve takati tükenir.

## 4. Yerler (işaretler)

Koordinatlar kamp dünyasınındır (metre; x doğu, z güney; menü kamerası kuzeye bakar). `days.point("işaret")` ya da `PrologueWorld.marker(id)` verir (zemine oturur). Kaynak `data/story/prologue_days/places.json`.

| İşaret | x, z | Ne |
|---|---|---|
| `gol_center`, `gol_fire` | 0, 0 | Göl Obası, menünün ateşi (`Camp/Campfire`) |
| `gol_family_yurt` | −6,18, −4,31 | aile yurdu (Önsöz'de açık yurt: içine girilir, çatısız diorama; menüde Meshy yurdu) |
| `gol_family_bed`, `gol_family_bedside` | yurdun içi | Çocuk'un yatağı (aile yatağı) ve yatağın başı (ocağa bakan yanı, 0,8 m; başında diz çöken Ana'nın yeri) |
| `gol_family_in`, `gol_family_door` | kapının içi / önü | yurdun kapısı (ateşe bakar) |
| `gol_milk_pole` | kapının yanı | omuz sırığı ve iki tulum |
| `gol_horse_line`, `gol_milking` | 13,8, −14,6 / 11,4, −11,4 | at bağı (Ana kısrak sağar) |
| `gol_felt`, `gol_bard_door`, `gol_woodpile` | 4,6, −2,6 / 3,2, −5,4 / 2,4, −9,2 | Baba'nın keçesi, ozanın kapısı, odun yığını |
| `gol_road_start` | −3, 14 | yolun başı (obanın güney kıyısı) |
| `lamb_slope`, `lamb_slope_far` | 16, 60 / −6, 84 | kuzuların yamacı (yokuşun dönemeçleri; ikincisi yolun dere tarafı) |
| `forest_edge` | −14, 61 | orman kıyısı, kuru dallar (yolun inişinin başı) |
| `stake_1` … `stake_12` | yol boyunca, 18–40 m arayla | keçe bayraklı kazıklar (ilki yokuşun başında, 12'ncisi geçidin 6 m önünde) |
| `road_descent`, `road_forest`, `road_open` | −6, 52 / −84, 114 / −150, 130 | yolun inişi, ormanın içi, açık vadi |
| `shelter_rock_1` … `shelter_rock_3` | −157, 125 / −186, 142 / −203, 154 | rüzgârın kesildiği kayalar (tipide lee) |
| `ford`, `ford_east`, `ford_west`, `ford_stone_1` … `ford_stone_4` | −212, 168 | derenin sığ geçidi, iki kıyısı ve basma taşları |
| `stream_stones` | −210, 150 | dere taşları (büyük taş ve çakıl; «Ocak»ın taşları) |
| `birch_gate` | −230, 184 | Kayın Obası'nın girişi |
| `birch_center`, `birch_fire` | −250, 197 / −250, 198 | Kayın Obası, obanın açık ocağı |
| `saruk_yurt`, `saruk_door`, `saruk_in`, `saruk_hearth`, `saruk_bed`, `saruk_bedside` | −254, 182 | Saruk'un yurdu |
| `saba`, `saba_stand` | −241, 188 / −242,4, 189,6 | sabanın ahşap çatısı ve deri saba; çalkalayanın yeri |
| `kurut_rack` | −244, 183 | kurut sergisi |
| `kunay_yurt`, `kunay_door`, `kunay_in`, `kunay_hearth`, `kunay_bed`, `kunay_bedside`, `kunay_cradle` | −238, 210 | Künay'ın yurdu (kapısı güneye, takip kamerasına bakar; tipide «kara yurt»: ocağı söner); içinde ocak, döşek, yatağın başı (Saruk'un yeri) ve beşik (beşiğe asılı küçük yay) |
| `birch_3_yurt`, `birch_3_door` | −264, 208 | obanın üçüncü yurdu (kapalı) |
| `horse_tether` | −236, 197 | at bağı (iki direk ve ip) |
| `wrestle_ring` | −251, 211 | çocukların güreş halkası (r 2,6 m) |
| `birch_play` | −238, 199 | çocukların oyun yeri |
| `feast_fire` | −250, 198 | şildenin büyük ateşi (`birch_fire`'ın yeri) |

- Yürünür alan Önsöz'de birleşik bir biçimdir: kampın dairesi + yol boyunca koridor + geçit, Kayın Obası, kuzu yamacı ve orman kıyısı daireleri (`PrologueWorld.walk_circles()`; `PlayerController.play_area_extra`). Menüde ve Serbest Gez'de alan bugünküdür.
- Kayın Obası, yol, dere, kazıklar ve kayalar yalnız Önsöz'ün günlerinde kurulur (`PrologueWorld.build()`, `teardown()`); yolun ve obanın üstündeki çam ve ot örnekleri o sürece gizlenir, sonra geri gelir. Menü karesi değişmez.

## 5. Saat, ışık ve hava

- Saat koşucunundur: `days.clock` (`GameClock`, 8–10 Nisan MÖ 209: `day_n` 1.168–1.170), 2,5 sn = 1 oyun dk (sahnenin `clock.seconds_per_minute`'i). Işığın tek yazıcısı SkyRig'dir: koşucu kampın ışık duraklarından (`LightStops`, `camp`) 4 Hz örnek verir; menünün kimliği alınır, sonunda geri verilir.
- Çağrılar: `days.set_time("18:20")` (anında), `days.lapse_to("21:00", 6.0)` (görünür akış), `days.pause_clock(&"neden", true)`, `days.minute()`.
- Hava: `days.set_weather("blizzard", 8.0, {"vis": 25.0, "wind": 13.0})` (tür, karışım sn, ezilen değerler; aynı türde yalnız değerler değişiyorsa geçiş anahtarlıdır ve karışım saniyesinde yumuşar: «Tipi»nin `ease` adımı, ateş tutunca görüş 25 → 42 m; adımın ön kurulumunda (`--step`) hava anında kurulur), `days.set_snow(1.0, 0.0)` (kar örtüsü, süre), `days.set_mist(0.4)`, `days.wind_at(p) -> Vector2` (m/sn; kayaların ve yurtların ardında kesilir), `days.shelter_at(p) -> 0..1`. Tipi gecesinin görünüşü (görüş ≈25 m, karda iz, yatay çırpan bayraklar) `storm_*` adımlarındadır; kar örtüsü tipinin sonunda kalır, 9 Nisan sabahı karlıdır (`day2_lambs.json`'un `weather.snow` 1'i).

## 6. Sinemaya geçiş

- `await days.to_cinema()` (ya da son sahnenin son adımı: `{"kind": "cinema"}`): HUD söner, oyuncunun denetimi kapanır, ateş başı halkı (`Camp/CampNpcs`: Ozan, Ana, Baba, Ağabey, Çocuk) menüdeki yerinde oturur (koşucunun kişileri gizlenir), aile yurdu menünün yurduna döner, ışık ve hava 1,6 sn'de menünün kimliğine süzülürken kamera takip kadrajından 1,6 sn'de menü kadrajına döner (`MenuCamera.return_to_menu(1.6)`); bitince koşucu `finished({ending: "cinema"})` yayar, main.gd bugünkü sinemayı (`data/cine/prologue.json`, `prologue_camp`) 0'dan oynatır.
- Ozanın, ailenin ve ateşin yeri menüdekiyle aynıdır: «Ocak»ın son adımı kişileri `CampNpcs`'in oturuş yerlerine yürütür (`days.seat_point("Mother")` vb.), ateş `Camp/Campfire`'ın yerindedir. Ateşin görünüşü sinemadan önce menünün ateşine oturmalıdır (Ö2'nin `HearthFire.settle`'ı).

## 7. Kayıt noktası

- Her günün başında (kart kara perdedeyken) main.gd oto kayıt yazar: `main.flow_save_point("prologue", "day2")`. Kaydın işaretleri `yeni_oyun_asama` (aşamanın kimliği) ve `yeni_oyun_gun` (günün kimliği); günler arası taşınan sonuçlar `onsoz_*` işaretleridir (`onsoz_sut`: `full` / `spilt`). Devam Et ve Yükle böyle bir kayıtta Yeni Oyun'un akışını o aşamanın o gününün başından açar.
- Çocukluk aynı çağrıyı kullanır: `main.flow_save_point("childhood", "day2_tally")`; açılışta `main.flow_resume_day("childhood")` günün kimliğini verir.
- Heybe (envanter) de taşınır: kayıt noktası oturumsuz hikâye sahnesinin heybesini (`gameplay_hud.bag.inventory`, `Inventory.to_dict()`) kaydın `flow_bag` bloğuna yazar (oturumun `inventory` bloğu değildir: Serbest Gez ya da I. Perde açılınca çocuğun heybesi başlangıç donanımının yerine geçmesin; akış bitince blok yolculuktan silinir). Devam Et ve Yükle bloğu okur; açılan günün başındaki ilk kayıt noktası (`flow_save_point`) önce heybeyi kayıttaki hâline geri koyar, sonra yazar. Bunun için aşama heybeyi sıfırlayan `gameplay_hud.begin_body()`'yi günün başından (kayıt noktasından) önce çağırır; heybe daha önce gerekirse aşama `main.flow_restore_bag()`'i kendisi çağırır (bir kez çalışır). Sınama: `test_prologue_days.gd` (`test_save_point_carries_the_bag_and_keeps_it_out_of_the_session`, `test_continue_opens_the_saved_day_from_its_start`).
- Önsöz'ün elde taşınanları (omuz sırığı, köz kabı) heybede değil eldedir (`days.carry`); gün içinde biter, günün başında elde bir şey yoktur.
- Argümanlı geliştirme koşuları kayıt yazmaz (SaveSystem yazılmaz).

## 8. Ses

- `PrologueSound` (`scripts/story/prologue_sound.gd`): yataklar (`days.bed("amb_birch_camp_day", true)` ya da sahnenin `beds`'i: kimlik, merkez işareti, yarıçap) ve tek seferlik sesler (`days.sfx("sfx_milk_pour", yer)`). Yollar `e21-atmosphere.md`'nin kuralıdır: `audio/ambience/e21/<kimlik>.wav`, `audio/sfx/e21/<kimlik>[_a|_b|_c].wav`, müzik `audio/music/e21/<kimlik>.mp3`. Dosya yoksa yer tutucu çalar (`PrologueSound.PLACEHOLDERS`: var olan ses), dosya gelince kendiliğinden yerine geçer. Aynı anda en çok 3 yatak; konumlu yatak uzaklıkla söner, uzak tek seferlik ses süzülür.

## 9. Otomatik oynatma

- `scripts/dev/prologue_autoplay.gd`: `--autoplay` ile Yeni Oyun'un Önsöz günlerinde her adımın `autoplay(bot, delta)`'sını çağırır; türün yazmadığı adımda hedefe yürür ve bekler. Bot: `bot.go_to(p, run)`, `bot.follow(points, run)`, `bot.halt()`, `bot.press_e()`, `bot.hold_e(sn)`, `bot.lean(x)`.

## Değişiklikler

- 2026-11-09: günün `lines`'ı (§1): ses havuzu gün başına; koşucu günün sözlerini günün başında yükler, gün bitince bırakır.
- 2026-11-09: `PrologueStep.HOLD_MODS` (§3); aynı türde hava değerlerinin yumuşak geçişi (§5); vadi ladinlerinde kamera örtmesi ve yolun ve obanın çimeni (PrologueGrass) Önsöz'de kurulur.
- 2026-11-09: kayıt noktası heybeyi de taşır (§7, `flow_bag` bloğu; Ç2'nin notu); Çocukluk aynı düzeneği kullanır.
- 2026-11-09: Künay'ın yurdunun kapısı güneye döndü (kapıdaki sahneler kameradan görünür; `kunay_door`, `kunay_in`, `kunay_bed*`, `kunay_cradle` yurtla döner). §4'ün tablosu `places.json`'un bugünkü değerleriyle yenilendi; yatağın başı işaretleri (`gol_family_bedside`, `<yurt>_bedside`) eklendi.
