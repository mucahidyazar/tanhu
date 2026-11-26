# Tanhu source brief

**Sources (absolute paths; later pointers use the basename and line).** Root is `/Users/mucahidyazar/game-development/projects/tanhu-2d/`.
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/skills.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/world/progress.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/world/act_end.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/world/level.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/ui/skills.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/autoload/game_state.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/autoload/scene_manager.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/autoload/settings.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/autoload/fx.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/common/archery_level.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/common/chase_level.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/perde1/kamp.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/perde1/rehine_ic.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/perde1/aile_ic.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/scenes/boot.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/scenes/main_menu.gd`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/i18n.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/items.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/codex.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/destan.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/basarimlar.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/dialogue/prolog.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/dialogue/perde1.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/songs/ninni.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/songs/sarki_ak_kulun.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/tools/music_spec.json`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/tools/voice_gen.py`
- `/Users/mucahidyazar/game-development/projects/tanhu-2d/story/` (`00_hikaye_incili.md`, `yan_oyunlar_ve_gelisim.md`, `tasarim_degerlendirmesi.md`, `yol_haritasi.md`, `muzik_ipuclari.md`, `sarkilar.md`, `renk_isik_rehberi.md`, `kadim_diller.md`, `perde1_oynanis.md`, `faz4_plan.md`, `perde2.md` to `perde6.md`, `epilog.md`)

**Read this first.**
- The hero's canonical name is **Motun** in all player-facing text (`tasarim_degerlendirmesi.md` §5: "Kahramanın adı her yerde **Motun**"). "Mete" survives only in the speaker id `mete`, `portraits/mete.png`, voice key `tasarim_mete` and `faz4_plan.md`.
- Only the Prolog and Acts I–III are playable. Acts IV–VI and the Epilog exist only as documents.
- I read beyond your list where exact text lived elsewhere. No `.env` or credentials were read, and nothing was changed.

---

## 1. Progression model

**Core rule (`yan_oyunlar_ve_gelisim.md` §1):** "Klasik güç/can puanı yok. Motun dünyanın içinden gelişir: gerebildiği yay, atıyla bağı, görünün parçaları, Kut ve Korku."
Source line: "Yay gerebilen her erkek zırhlı atlı olur" (士力能彎弓，盡為甲騎, Hanshu 94A). All state lives in `Game.flags`, so saves carry it.

### Counters

| Counter | Range | Gains | Effect |
|---|---|---|---|
| `yay_ustalik` | no cap, starts in Act II | Own hits only (progress.gd:12): straw 1, deer 2, wolf 2, archer 3, tilki 2, tavsan 2, atli 3. Çentik game +2…+4. "Islık ve onluğun okları saymaz." | At >= 30 (`HEAVY_BOW_AT`) sets `boke_agir_hazir`, shows `TOAST_BOW_READY`; Böke then gives the heavy bow |
| `ayaz_bag` | 0–100 | Act I, each once (progress.gd:77): `p1_ayaz_sakin` 15, `p1_ayaz_tuz` 5, `ayaz_ad` 10, `ant:ant_ayaz` 10. Act II Fırça +4…+8 per time slot, salt +5 once. Act III ninni +4…+8 | Spur stamina and speed on Ayaz |
| `goru_parca` | +1 per act end (act_end.gd:9-11, guard flag `goru_p<act>`), UI "n/7" | | +1 life per shard |
| `onluk_sadakat` | small int | Aşık with the ten +1, pelt to the ten +1, kökbörü win +1 | Lowers hesitation. Act III desertion: 0 means two tens leave, 1 means one ten (`p3_kacak`); none if the "geride kalanın başı gider" order was given |
| `kut`, `korku` | doc 0–20, independent; code does not clamp (game_state.gd:96) | See deltas below | Thresholds below. Doc: no number shown; Kut is a gold sun disc, Korku a red ember, both slowly glow or fade |

### Formulas (progress.gd, chase_level.gd, archery_level.gd)

```
bow_tier     = 3 if equipped boynuz_yay; 2 if equipped boke_agir_yay; 1 if hun_yayi equipped or carried; else 0
shot_cd      = [0.4, 0.4, 0.3, 0.26][tier] s
arrow_speed  = [1.0, 1.0, 1.2, 1.3][tier]
back_reach   = [760, 760, 900, 1000][tier] px
whistle_cd   = max(3.0, 4.5 - 0.6*onde_atar - 0.7*islik_hazir)
k            = clamp(ayaz_bag/100, 0, 1)
stamina_drain= 0.32*(1 - 0.35k) on Ayaz, else 0.32 per s (stamina 0..1, spur needs > 0.05)
stamina_regen= 0.16*(1 + 0.6k) on Ayaz, else 0.16
spur_bonus   = 1.5k m/s on Ayaz, else 0 (added to spur_speed 23.0)
lives_bonus  = goru_parca + chase_assist (0|1|2)
max_hits     = max(2, 3 + diff(story +2, normal 0, hard -1)) + lives_bonus   (chase_level.gd:164)
               kadfi_rehin +1 in the Act I chase (perde1_oynanis.md §3.5)
hesitation   = 0 if tumen_kural, else max(0, base - 0.1*onluk_sadakat); base 0.45 sinav_bos, 0.2 sinav_yarim, else 0
cooldowns    = gok_ok 25 s, kurt_kapani 20 s, yagmur 9 s (archery_level.gd:34-39)
```

Difficulty also affects boss health, guard detection speed and the Kulak game (×0.7 / 1.0 / 1.3, kulak_game.gd:108).

**Bows:**
- `hun_yayi`: from Böke, Act II day 2.
- `boke_agir_yay`: mastery 30. Takes effect only when equipped.
- `boynuz_yay`: Act III spoils.
- Böke's lines: "Ellerini göster... Nasır bağlamış. Yay sana hafif gelmeye başladı, değil mi?" / "Show me your hands... Calluses. The bow has started to feel light to you, hasn't it?" and "Al bunu: ağır yay. Germeye gücün yetiyorsa, artık zırhlı atlısın." / "Take this: the heavy bow. If you have the strength to draw it, you ride as armoured cavalry now."

### Skill tree (skills.json)

**Unlock rules:**
- `Skills.learned(id)` reads only `learn`: `"*"` or `Game.check(learn)` (skills.gd:43-48). `requires` is not enforced there.
- States: `ready`, `cooldown`, `unready`, `elsewhere`, `locked`. Contexts: `foot`, `chase`, `archery`.
- Hidden until `p1_basladi`: "none in the prologue".
- Bar: 6 slots, keys 1–6. `default_bar`: `ok, islikli_ok, ardina_atis, mahmuz, tunc_ayna, kemik_islik`. A `{skill_id}` tag in text becomes the slot key or "F".

**Condition grammar (game_state.gd:247-287):** `flag`, `!flag`, `kut>=2`, `item:id`, `eq:id`, `ant:id`, `ant_kept:id`, `ant_broken:id`, `&&`, `||`. `||` binds loosest and there are no parentheses.

**Branches:**
- `yay` (glyph bow): "YAY" / "THE BOW", "Okun ve ıslığın yolu" / "The way of the arrow and the whistle".
- `at` (glyph horse): "AT" / "THE HORSE", "Eyerin ve dörtnalın yolu" / "The way of the saddle and the gallop".
- `bozkir` (glyph wolf): "BOZKIR" / "THE STEPPE", "Gecenin, sesin ve ışığın yolu" / "The way of the night, the sound and the light".

**Skills:**
- `ok` (yay 0, archery, `item:hun_yayi`): Ok / Arrow. "Şeridindeki ilk hedefe bir ok. Atın üstünde, dörtnalda." / "An arrow at the first target in your lane, from the saddle, at a gallop." How: "Böke'nin yaptığı Hun yayıyla öğrenilir." / "Learned with the Hun bow Böke makes."
- `ardina_atis` (yay 1, requires ok, archery, `item:hun_yayi`): Ardına Atış / Parting Shot. "Eyerde geriye dönüp peşindekine atarsın. Bozkırın en eski hilesi." / "Turn in the saddle and shoot whoever is at your heels. The oldest trick of the steppe." How: "Yayla birlikte gelir." / "Comes with the bow."
- `islikli_ok` (yay 2, requires ok, archery, `item:islikli_ok`): Islıklı Ok / Whistling Arrow. "Öterek uçar ve en iyi hedefi işaretler; ardındaki atlılar oklarını ıslığın gittiği yere bırakır." / "It sings as it flies and marks the best target; the riders behind you loose where the whistle went." How: "Kadfi'nin ıslığından doğdu; Böke ilk ıslıklı okları yonttu. Onluk arkanda at sürünce işe yarar." / "Born of Kadfi's whistle; Böke carved the first whistling arrows. It works once your ten ride behind you."
- `yagmur` (yay 3, requires islikli_ok, archery, `eq:boke_agir_yay || eq:boynuz_yay`): Ok Yağmuru / Rain of Arrows. "Ağır yayla üç oku birden bırakırsın: her şeride bir ok." / "With the heavy bow you loose three arrows at once, one down each lane." How: "Böke'nin ağır yayı kuşanılınca açılır. Yay gücü, gerebildiğin yayla ölçülür." / "Opens when Böke's heavy bow is in your hand. A rider's strength is the bow he can draw." Need: "Böke'nin ağır yayını (ya da daha güçlü bir yayı) kuşan" / "Wear Böke's heavy bow (or a stronger one)".
- `mahmuz` (at 0, chase + archery, `*`, hold): Mahmuz / Spur. "Basılı tuttukça at hızlanır; dayanıklılık biterse yavaşlar." / "Hold it and the horse speeds up, until its stamina runs out." How: "Hun çocukları ata binmeden önce koyuna biner, kuşa ve fareye ok atar." / "Hun children ride sheep before they ride horses, and shoot at birds and rats."
- `sicrayis` (at 1, requires mahmuz, chase + archery, `*`, not on bar, key `jump`): Sıçrayış / Leap. "Kar yığınlarının ve çitlerin üstünden atlar." / "Over drifts and fences." How: "Atın kendi bildiği iş." / "The horse knows this one."
- `egilme` (at 1, requires mahmuz, chase + archery, `*`, not on bar, key `hide`): Yele Kapanma / Hug the Mane. "Atın boynuna kapanıp alçak dalların ve iplerin altından geçer." / "Flatten against the horse's neck to pass under low branches and ropes." Same how as `sicrayis`.
- `kurt_kapani` (at 2, requires mahmuz, archery, `korku>=6 && item:hun_yayi`, needs allies): Kurt Kapanı / Wolf Trap. "Dizgini çekip yenilmiş gibi geri düşersin; peşindekiler önüne geçer ve onluğunun halkasına girer. Tek yaylım hepsini biçer. Onluk arkanda olmalı." / "Rein back as if beaten: whatever hunts you rides past into your ten's ring, and one volley cuts it down. Your ten must ride behind you." How: "Korku 6 olunca açılır. Bozkırın en eski tuzağı: sahte kaçış." / "Opens at Fear 6. The steppe's oldest trap: the feigned retreat."
- `sinsi` (bozkir 0, foot, `*`, toggle): Sinsi Yürüyüş / Soft Step. "Sessizce yürürsün; nöbetçiler seni geç fark eder. Bir daha basınca normal yürüyüşe dönersin." / "Walk softly; the guards notice you late. Press again to stop." How: "Rehinelik öğretti." / "Being a hostage taught it."
- `kemik_islik` (bozkir 1, requires sinsi, foot, `item:kemik_islik`, must be worn): Kemik Islık / Bone Whistle. "Islık çalarsın: yakındaki nöbetçi sese doğru yürür, yolun açılır. Islık boynunda takılı olmalı." / "Whistle: the nearest guard walks toward the sound and your way opens. It must hang at your neck." How: "Kadfi'nin koyun incik kemiğinden oyduğu ıslık." / "The whistle Kadfi carved from a sheep's shinbone."
- `tunc_ayna` (bozkir 2, requires kemik_islik, chase, `item:tunc_ayna`): Tunç Ayna / Bronze Mirror. "Kırık aynayı kaldırıp ışığı peşindekilerin gözüne yansıtırsın. Karanlıktan gelenler ışıktan korkar." / "Raise the cracked mirror and throw the light into your pursuers' eyes. What comes from the dark fears the light." How: "Ay Hatun'un aynası; bir parçası hâlâ onda." / "Lady Ay's mirror; she still keeps one shard."
- `gok_ok` (bozkir 3, requires tunc_ayna, archery, `kut>=8 && item:hun_yayi`): Gök Ok / Sky Arrow. "Tengri'nin kartalı çığlık atıp iner: en tehlikeli iki hedefi düşürür, sırttaki okçuları gösterir." / "Tengri's eagle cries and stoops: it brings down the two most dangerous marks and shows the archers on the ridge." How: "Kut 8 olunca açılır. Kartal Tengri'nin işaretidir." / "Opens at Kut 8. The eagle is Tengri's sign."

Locked branches show their condition: "Kut 8 ile açılır", "Korku 6 ile açılır".

**Act I availability:** Motun has no bow in Act I.
- On foot: `sinsi`, `kemik_islik`.
- Riding: `mahmuz`, `sicrayis`, `egilme`, `tunc_ayna`.

### Equipment

- Slots (game_state.gd:15): `bas, boyun, govde, kemer, el, yay, ok`. UI names: Baş, Boyun, Gövde, Kuşak, Bıçak, Yay, Sadak.
- `give_item` auto-equips into an empty slot.
- bas: `kartal_tuyu`, `tilki_borku`
- boyun: `kemik_islik`
- govde: `rehine_kaftani`
- kemer: `tunc_ayna`
- el: `arslan_bicagi`, `kara_bicak`
- yay: `hun_yayi`, `boke_agir_yay`, `boynuz_yay`
- ok: `islikli_ok`, `sadak`

### Kut and Korku

- Kut: "Tengri'nin rızası ve halkın güveni. Ant tutmak, amaçlı merhamet, dürüstlük ve başkası için risk almak artırır. Ant bozmak ve amaçsız zulüm düşürür."
- Korku: "Zorla itaat. İdam, tehdit ve Erlik pazarlıkları artırır, nadiren düşer."
- UI: `LEDGER_KUT_DESC` "Göğün lütfu: tutulan sözler, sadakat, töre" / "Heaven's grace: oaths kept, loyalty, law". `LEDGER_KORKU_DESC` "Erlik'in gölgesi: zor, tehdit, kan" / "Erlik's shadow: force, threat, blood". `TUT_KUT` and `TUT_KORKU` explain each on its first change.
- **Thresholds:**
  - Korku >= 6: Erlik whispers at the screen edge, and `kurt_kapani` opens.
  - Kut >= 6: the spirit wolf helps in the hunt.
  - Kut >= 8: `gok_ok`, and the judgement-night persuade option (`beyler_ikna`).
  - Korku >= 8: the intimidate option (`alkim_boyu_sindi`).
  - Selenge volunteers at kut >= 4 with `kizkuu_birakti`, otherwise 6, or 8 with `selenge_soguk`.
- **Expected Act I end range:** Kut 0–6, Korku 0–5.
- **Deltas, Prolog and Act I (dialogue id, label):**
  - `prolog_dua`: guc korku+1, soz kut+1, don none
  - `p1_zerin_sabah` dogru kut+1
  - `p1_arslan_gunduz` durust kut+1
  - `p1_yabgu` meydan korku+1
  - `p1_tokar_meydan`: kaldir kut+1, yakala korku+1
  - `p1_erlik`: red kut+2, red_kam kut+1, pazarlik_ant korku+1, pazarlik_red kut+1, indir kut+1 and korku+1, vur korku+3
  - `p1_arsak_gece` dogru kut+1
  - `p1_ip_otag` kut+2
  - `p1_kadfi_gece`: ant kut+1, bagla korku+1, rehin korku+2

### Side activities and rewards

- **Aşık:** flick a shooter bone out of a felt ring, ← → to aim, hold and release E for power; a scoring shot grants another; four bones wins. Playing at all gives `kadfi_dost` ("Kadfi kazanırsa sevinir, kaybederse 'bir daha' der"). With the ten: `onluk_sadakat` +1.
- **Fire ring (`world/fire_ring.gd`):** 7–8 people sit (`sit_icme`, `sit_bagdas`) or stand, then clap and cheer (`sit_alkis`, `sit_tezahurat`). In Act I they gather at Kadfi's felt, with Zerin, a small relative, and Arşak on his log.
- **Güreş:** balance needle, left/right resist, best of three, `toygar_dost`.
- **Çentik:** blade over three notch marks, E; perfect 1, good 0.7. Sets `islik_hazir` and `yay_ustalik` +2…+4.
- **Fırça yönü:** brush with the grain, 2 rounds of 5 patches.
- **Kulak (calming):** walk when ears are forward, stop when they flick, freeze when pinned, then hold E at the head. Ayaz three rounds, the mare one; salt softens everything.
- **Tilki/tavşan avı, pelt sharing:** Ay Hatun (`ana_post`, kut+1), Tansu (`tansu_yakin`+1), the ten (`onluk_sadakat`+1), self (`tilki_borku`).
- **Act III ganimet:** five shares into three bowls: self (horn bow and korku), the ten (loyalty), the beaten (Kut).
- **Atalar taşları:** `tas_p1_nehir`, `tas_p1_kam`, `tas_p1_geyik`, plus four in Act II.
- **Act end card:** oaths, traces, Kut/Korku change, shard, time, bard's quatrain.

### Open-world riding pilot (`faz4_plan.md`)

- Turn rate falls with speed (5 to 2.4 rad/s), and a hard turn slows first. Walk 250, trot 430, gallop 660 px/s (Shift, stamina).
- The ten hold a wedge of 10 slots, match the leader's speed, no collision.
- Archery cone ±45°, 980 px. Tap F shoots the nearest target. Hold and release whistles at the largest cluster; the ten volley 0.25 s later.

---

## 2. Story bible, distilled

**One line:** "Esir bir prens kendi ipini kendi eliyle keser. Kaçarken verdiği her ant, yıllar sonra bir hükümdarın boynuna geçen bir ip olur."
**Theme:** "Ant, hükümdarın asıl tahtıdır." Second theme: the cycle of father and son.
**Tone:** "Destan ağırlığı, sade ve şiirsel dil." "Mitoloji gerçektir ama az konuşur. Tanrılar uzun nutuk atmaz, tek cümleyle gelir."
**Principles:**
- "Her ant bir yüktür."
- "Tarih değişmez, anlamı değişir."
- "Kötülüğü insan yap. Yüeçiler canavar değildir."
- "**Asla çocuk ölümü ya da kan gösterilmez.**" (`perde1_oynanis.md` §3.4)

### Life timeline

| Year | Age | Event |
|---|---|---|
| ~MÖ 227, summer night | 0 | Birth, wolves howl twice, Umay's vision, mirror cracks, named Motun |
| ~MÖ 213 | 14 | Given to the Yuezhi as hostage; mother gives him the mirror and keeps the shard |
| ~MÖ 210, winter | 17 | Act I: third winter, Tuman raids, death set for dawn, escape |
| MÖ 209, winter | 17 (codex) | Act II: return, ten thousand riders, tests, Tuman falls, white felt, Tanhu |
| MÖ 208, spring | ~19 | Act III: Eastern Hu destroyed |
| MÖ 206, summer to autumn | ~21 | Act IV: decimal law, Yuezhi driven west |
| MÖ 201 autumn to MÖ 200 winter | ~27 | Act V: Mayi, Ak Dağ, treaty |
| MÖ 198, winter | 29 | Act VI: mother dies, vision completes |
| MÖ 192; 177–176; 174 | | Letter to Empress Lü; Yuezhi crisis; Kiyük (Jizhu) succeeds. "Otuz beş yıl" reign |

### Acts

- **Prolog, UMAY'IN GÖRÜSÜ / UMAY'S VISION** (12–15 min, you play pregnant Ay Hatun, slow walk). She seeks a white cloth for Umay's birch. Labour starts, wolves howl, and Umay's golden bird leads her past five vision stones. The sixth breaks before the youth's face turns.
- **I, REHİNE / THE HOSTAGE** (60–75 min). Third winter in the Yuezhi camp. Tuman's riders raid, so the yabgu sets Motun's death for dawn. In one night Erlik offers a road for Kadfi's life, Tengri says "cut your own rope", and Motun takes a knife, a saddle and the silver stallion into the blizzard. At dawn an enemy arrow passes through Kadfi's bone whistle and sings.
- **II, ISLIKLI OK / THE WHISTLING ARROW** (70–80 min). He returns; the vision seems fulfilled, but his mother sees the door is wrong. Tuman gives him a tümen. Motun forges it through loyalty tests: his horse, the woman he loves, the Tanhu's horse. Tuman falls in every branch; the player chooses whose hand. Ends on the white felt at dawn.
- **III, BİN Lİ AT / THE THOUSAND-LI HORSE** (65–75 min). Kara Buğa demands the horse, a queen, the empty land, and each demand strikes an earlier oath. Dokuz Başlı, night raid or open battle, then the land below the river returns.
- **IV, BATI RÜZGÂRI** (70–80 min). Decimal law at Longcheng, then west. He returns as conqueror to the burning camp of his captivity, with too little time for both doors: the captives or Kadfi's family. Yuezhi are driven out, not destroyed. No boss: "Esir döndü. Bekçisi oldu."
- **V, AK DAĞ** (70–80 min). Feigned weakness lures Liu Bang onto the mountain; seven days inside four colours of horse. In the seventh day's fog he opens a corner or closes the ring. Liu Bang survives either way; the choice is what the peace is born from.
- **VI, EKSİK GÖRÜ** (45–60 min). Liu Jing's "torun tanhu" plan threatens Kiyük. Ay Hatun's deathbed gives the shard and the mirror plays to the end. Umay's realm, Tamag, the scale of oaths, final boss Yer Beyi, last decision at the kurultay. The great secret: "Sana yurda dönen bir oğul gösterdim. Kimin oğlu olduğunu söylemedim."
- **Epilog, OZANIN SESİ** (8–10 min). A blind bard tells the epic to children by a summer fire.
- **Endings, checked in order:**
  - Oğuz: `kut>=14 && korku<=5` and `ant_ana`, `ant_kadfi`, `ant_arslan`, `ant_yueci` kept.
  - Kara: `korku>=12 && kut<=6 || ant_kept:ant_erlik && korku>=10`.
  - Gök: `kut>=11 && korku<=7 && ant_kept:ant_ana`.
  - Demir: default.

The IV–VI English titles do not exist in the data yet.

### Characters

Voice notes come from `tools/voice_gen.py` cast comments and the `voice` fields in `prolog.json` and `perde1.json`. Looks come from bible §3.

| Name (EN) | Age | Role | Voice | Look |
|---|---|---|---|---|
| Motun | 17→29 | Hero. Hunnic to self, horse, gods, Huns; Yüeçice with Yuezhi | "young but deep, resonant baritone" | Cyan kaftan is the crowd's only cold accent; `rehine_kaftani` with thinned wolf collar; rope on left wrist |
| Ay Hatun (Lady Ay) | 20, 38 | First wife, carries the vision | "theatrical actress, true intonation" | Black braids with silver and turquoise, tall conical red felt cap with gold plaques, short white veil, red silk kaftan, bronze mirror at the sash |
| Tuman Tanhu | 35, 52 | Father. Fears losing his kut, loves his young wife | "a weighty steppe king near fifty" | Big, grizzled, old scar on nose, wolf-fur cap with gold eagle, red kaftan, Ordos gold belt plaques |
| Kam Bögü (Bögü the Shaman) | 43, 60 | Tuman's shaman | "old, deep, muffled" | Owl-feather cap, sky-painted tüngür, iron rattles, fringed robe |
| Alkım Hatun | 28 | Favourite, schemes for her son | "bold palace voice" | Red silk, golden bird crown, cold beauty |
| Kutluk Tegin | 10 | Half-brother | "young, joyful" | Ornate small kaftan, gold belt, large frightened eyes |
| Toygar | 19 | Childhood friend, first leader of ten | "21, friendly, powerful" | Broad, smiling, flat felt cap, bear-tooth necklace |
| Selenge | 18 | Loufan archer, later wife, Kiyük's mother | "young, dynamic, confident" | Black hair braided with red, fox-trim white felt cap, blue kaftan, scale vest, crescent brand on the wrist |
| Tansu | 16 | Alkım's niece, spy bride, loved | "young, airy, soft" | Faded copy of Alkım's red silk, bird-shaped gold clasps |
| Böke (the Bowyer) | n/a | Bowyer, burnt hand | "mature, soft" | |
| Kiyük Tegin | 6 (P6) | Son, the cycle's mirror | n/a | Small copy of Motun, top-knot, blue-green kaftan |
| Kadfi | 8 (P1), 13 (P4) | Yuezhi boy, "Motun ağa" | "young, joyful (the boys)" | Round face, red cheeks, oversized mustard felt Saka cap, baggy burgundy quilted kaftan, bone whistle on a string |
| Zerin | 30 | His mother, feeds the hostage | "warm storyteller woman" | Burgundy-ochre felt, gold-spangled white headscarf, bone pin, warm eyes |
| Arşak (Arshak) | 42 | Horse master, keeper; hangs if Motun flees | "deep, intense" | Braided beard, leather scale vest, two fingers missing on the left hand, stern and tired |
| Seyis Arslan (Arslan the Groom) | 61 | Hun captive for 20 years, hamstrung | "old man, calm" | Grey braids, white left eye, Yuezhi brand on the cheek, sheepskin, staff |
| Yabgu Vima | 50 | Yuezhi lord, fears Huns | "mature, soft" | Tall pointed crown of gold plaques, gold torque, burgundy kaftan with gold animal plaques, big and shrewd |
| Tokar | 30 | Guard captain, the hunter | "intense, crisp" | Mustard cap, burgundy kaftan, scale armour, gorytos, hook-shaped lip scar |
| Kam Ece (Ece the Seer) | 70 | Blind Yuezhi shaman, the oracle | "the oracle" | White eyes, antlered cap, bone and bronze amulets, smoking bronze cauldron |

**Others:**
- Kara Buğa Han (45, "epic, powerful, historical"), Sırga, Liu Bang (56), Liu Jing, Hán Kralı Xin.
- Ozan: blind, white-bearded, kopuz. "Ozan bir anlatıcı değil, bir insandır." His lines are subtitles.
- Horses:
  - Ayaz: silver stallion, "Ay-at" / Moon-horse to the Yuezhi; dam was a Hun mare taken in a raid.
  - Kaşka / Kashka: colt born the same night.
  - Boz Kısrak.
  - Karabörü: Tuman's horse.

**Voice prompts, verbatim:**
- Anlatıcı: "Deep, weathered male storyteller in his sixties; a Central Asian epic bard beside a night fire. Slow, warm, intimate, a faint rasp. Never theatrical; every pause is weighted."
- Umay: "Ageless female voice, warm and luminous, unhurried. Gentle but vast, with a soft airy echo, as if a mother were speaking from inside sunlight."
- Erlik: "Immense, ancient male voice, low and velvety; amused, intimate, patient. A merchant of souls who never needs to shout. A faint crackle of embers in the breath; savours every word."
- Tengri: "Vast, calm, ageless voice like wind across an empty sky; very slow, with a faint distant choir beneath it. No emotion, only absolute weight." At most two sentences.
- Ruh kurdu never speaks.

**VO policy:** Turkish and Kadim cover the full cast; English covers narrator and gods only. New VO only for cinematic scenes; other lines are silent (`sessiz`, `"vo": false`).

### Oaths

Mechanics: `{"cmd":"ant","id":...}`, shown as a persistent knot; kept unties with gold light (`ant_oath`), broken snaps (`ant_broken`); all weighed in P6.

| id | To, given → returns | Oath | Kept / broken |
|---|---|---|---|
| `ant_arslan` | Arslan, P1 → P4 | "Bu kamptaki her Hun esirini geri alacağım." / "I will bring home every Hun captive in this camp." | Kut +2 / −2 |
| `ant_kadfi` | Kadfi, P1 → P4 | "Döndüğüm gün Kadfi'ye ve ocağına hiçbir Hun kılıcı değmeyecek." / "The day I return, no Hun blade will touch Kadfi or his hearth." | Kut +2 / −2, korku +1 |
| `ant_ayaz` | Ayaz, P1 dawn → P3 | "Seni hiçbir hana vermeyeceğim." / "I will never give you to any khan." | Kut +2 / −1 |
| `ant_erlik` | Erlik, P1 → P2, P6 | "Bir gün okum bir babanın yüreğine ötecek. O kan Erlik'in." or "Elim evet dedi. Erlik'e bir can borçluyum." | Korku +2 / korku +1, kut −1 |
| `ant_ana` | Ay Hatun, P2 → P6 | "Oğluma, babamın bana yaptığını yapmayacağım." | Kut +3 / −3 |
| `ant_tumen` | Riders, P2 → P2, P5 | "Islığım asla kendi kanımıza ötmeyecek." | Kut +2 / korku +2 |
| `ant_selenge` | Selenge, P2 → P3 | "Seni hiçbir hana at gibi vermeyeceğim." | Scene outcomes |
| `ant_toprak` | Kurultay, P3 → P5 | "Atalarımızın toprağından bir karış vermeyeceğim." | Kut +1 / −2 |
| `ant_kurultay` | 24 beys, P4 → P6 | "Hiçbir beyin kanı kurultaysız dökülmeyecek." | Korku +2 if broken |
| `ant_yueci` | Vima, P4 → Epilog | "Çekilenin ardından ok atılmayacak." | Kut +2 / korku +3 |
| `ant_han` | Liu Bang, P5 → P6 | "Kardeşlik antı bozulmadıkça seddi aşmayacağım." | Kut +1 / korku +2 |

### Exact existing narrator text

**`prolog_acilis`** (prolog.json:17, 19; mood `mythic`, music `prolog_dogum`, ambience `summer_night`):
- TR "Bozkırın henüz bir adı yoktu. Yalnızca rüzgârı, atları ve bir yaz gecesi vardı."
  EN "The steppe had no name yet. Only wind, horses, and one summer night."
  Hunca "Yazınıŋ neŋ atı yok erti. Yalŋuz yeli, atları, bir yay tüni bar erti."
- TR "O gece Tanhu'nun hatunu uyuyamıyordu. Karnındaki çocuk gökten önce uyanmıştı."
  EN "That night the Tanhu's wife could not sleep. The child inside her had woken before the sky."
  Hunca "Ol tün tanhunuŋ katunı udıyu umaz erti. Karnıntakı oğul teŋriden öŋre odunmış erti."

**`p1_acilis`** (perde1.json:27-31; title "I. PERDE / REHİNE", "ACT I / THE HOSTAGE"; ambience `wind_winter`, then `yurt_inside`, music `kamp_gunduz`):
- TR "On yedi kış sonra görüdeki çocuk, yabancı bir otağda uyandı."
  EN "Seventeen winters later, the boy from the vision woke in a stranger's tent."
  Hunca "On yeti kış kėdin tüldeki oğlan yat bir ebde odundı."
- TR "Babası onu Yüeçilere rehin vermişti: hiçbir Hunun batıya at sürmeyeceğine dair canlı bir söz."
  EN "His father had given him to the Yuezhi as a hostage: a living promise that no Hun would ride west."
  Hunca "Kaŋı anı Yüeçike tutuğ bermiş erti: neŋ Hun kėdinke at sürmegey tėp tirig bir sab."
- TR "Bozkırda bir söz, onu tutan el kadar sağlamdır."
  EN "On the steppe, a promise is only as strong as the hand that holds it."
  Hunca "Yazıda sab, anı tutmış elig neçe erser ança katıg."

**Existing clips:** `game/assets/voice/<en|tr|kadim>/<dialogue_id>/<md5("speaker|text")[:10]>.mp3`. The English narrator clips run 7.1 and 6.8 s for `prolog_acilis`, and 4.6, 7.4 and 5.4 s for `p1_acilis`.

### Beats before Act 1 (what a New Game narrator intro must carry, in order)

1. **Summer night, the Tanhu's wife cannot sleep** (lines above).
2. **The birth rope:** "Her Hun bir ip tutarak doğar. İpin öbür ucunu annesi tutar." / "Every Hun is born holding a rope. His mother holds the other end."
3. **Wolves howl twice, Kam Bögü:** "Kurt bir doğuma iki kez ulursa, gelen ya halkına duvar olur..." / "When the wolf howls twice at a birth, the one who comes will be a wall around his people..." then "...ya da babasının otağına ateş." / "...or a fire in his father's tent." Tuman: "Bunu bir daha yüksek sesle söyleme." / "Never say that aloud again."
4. **Umay opens the door:** "Ve her beşiği gözeten Umay, altın kapısını açtı." / "And Umay, who watches over every cradle, opened her golden door."
5. **The vision, with Umay's lines:**
   - Silver horse and blue wolf: "Yurduna dönen bir oğul." / "A son, coming home."
   - One singing arrow, then a thousand: "Onun gösterdiği yere. Dua et de iyi göstersin." / "Where he points. Pray he points well."
   - Horse and a woman in red led east: "Bazı armağanlar yavaş uçan oklardır." / "Some gifts are arrows that fly slowly."
   - White mountain, four herds (white west, grey east, black north, red south): "Dört rüzgâr ona dört renkte diz çökecek." / "Four winds will kneel to him in four colors."
   - White felt: "Çok el kaldırır. Az el tutar." / "Many hands raise a man. Few hold him up."
6. **The mother's prayer** (a player choice): "Güçlü ol." (`ana_dua_guc`, korku+1), "Sözünü tut." (`ana_dua_soz`, kut+1), "Eve dön." (`ana_dua_don`). It returns in Act II.
7. **The broken end:** youth at a tent door in snow. "Daha değil. Sonu göstermek bana düşmez." / "Not yet. The end is not mine to show." Then "Ona şarkı söyle. Benim varamadığım yerde sesin onu bulur." / "Sing to him. Your voice will find him where I cannot."
8. **Birth:** mirror cracked, a piece left in her palm, the lullaby sung, colt Kaşka foaled. "Küçük adı Motun olsun. Büyük adını kendi işleri koysun." / "His small name is Motun. Let his deeds give him the great one." "Duvar mı olacaksın, küçük... yoksa ateş mi?" / "Will you be a wall, little one... or a fire?"
9. **Optional broken promise:** "Söz ver: ne olursa olsun, onu yanından ayırmayacaksın." / "Promise me: whatever comes, you will never send him from your side." "...Söz. Bir Tanhu'nun sözü kılıcından ağırdır." / "...I promise. A Tanhu's word weighs more than his sword." (`tuman_soz`)
10. **Closer:** "Görünün bir sonu yoktu. On yedi kış sonra o çocuk, atını o görünün içine sürecekti." / "The vision had no ending. Seventeen winters later, the boy would ride into it."
11. **Age 14** (no narrator text exists, only the bible and Act I memory lines): the mother hands over the mirror. "Parçası bende kalsın, oğul. Dön ki tamamlayalım." / "I'll keep the missing piece, my son. Come back, so we can make it whole." "Güneş de bir aynadır, oğul. Karanlıkta kalırsan aynayı ışığa tut." / "The sun is a mirror too, my son. If you're ever caught in the dark, hold the mirror to the light."
12. **Three winters, then `p1_acilis`:** Zerin feeds him, Kadfi calls him brother, he carves Kadfi a wooden horse, the rope stays on his wrist.

**Intro traps:**
- Lines 10 and `p1_acilis` both say "Seventeen winters"; keep one.
- Do not name the stallion Ayaz: he is Ay-at until Motun names him on the Act I night.
- Do not reveal Erlik, the whistling arrow's birth, the door's bronze wolf head (Act II), or Umay's final line (Act VI).
- Dropping the Prolog also drops state that later acts read: `ana_dua_*`, `tuman_soz`, `kaska`, `pr_kisrak`. These need defaults or an in-intro choice.

---

## 3. Music and sound

**Common rules (`muzik_ipuclari.md`):**
- Organic instruments only: morin khuur, kopuz/dombra, frame drums, tüngür, temir komuz, kargı düdük, karnay-like long horn, khöömei/kargyraa, male and female choir. No synth, EDM or pop drums.
- Tonal centre D Dorian; dark scenes E Phrygian.
- Leitmotif: the lullaby's "dört notalık inen ezgisi" returns in a new guise each act. No pitches are notated anywhere.
- Prompt suffix: `Organic instruments only, no synths, no modern drums. Ancient Turkic/Mongolic steppe atmosphere, cinematic game score. Seamless loop.`

**Anti-western lesson (the `hun_ordasi` rewrite):**
- "major mode", "march", "dombra riffs / strummed", "horse-bell jingles" and "heroic" together produced a western.
- Ask for joy through major pentatonic over drones, with no chord walking.
- Write "plucked", never "strummed".
- Negative styles: american country, western, americana, bluegrass, hoedown, banjo, acoustic guitar, sleigh bells, western major chord progression, hollywood orchestral, celtic, irish jig, polka, cartoon.
- Do not ban "major key". Delete "(ha!)" and "(ho!)" shouts.

| id | Scene | Instruments | BPM doc / shipped | Mode | Mood |
|---|---|---|---|---|---|
| `menu` | Main menu, epigraph | Solo morin khuur, khöömei drone, war drum every four bars, wind (shipped adds two-string dombra gallop ostinato) | 70 / 72, 165 s | D Dorian / pentatonic minor | Noble, sorrowful, vast |
| `prolog_dogum` | Prologue camp, birth | Dombra arpeggios, jaw harp, heartbeat frame drum, fiddle hint of lullaby | 66 / 60 | Shared / pentatonic | Tender, expectant |
| `umay_goru` | Umay's realm, P1 mirror, P6 | Female choir, glass bells, fiddle harmonics, drone, solo voice lullaby | Free ~60 | Shared | Wonder, melancholy |
| `kamp_gunduz` | P1 day | Doc: plucked kopuz ostinato, light frame drum, sparse fiddle. Shipped: plucked dombra, breathy kaval, hand drums, rattles | 84 / 84, 120 s | "folk modal" | Curious, uneasy, homesick |
| `kamp_gece` | P1 night, P6 | Low drone, sparse plucks, breathy flute, wolf-like fiddle glissando | 60 / 66, 110 s | Shared | Quiet, tense, "room for footsteps" |
| `gerilim` | Stealth, yabgu, kurultay | Muted plucks, ticking jaw harp, low drone, fiddle stabs | 90 / 92 | Shared | "suspense without melody" |
| `erlik` | Family yurt, P2 hunt, P4, P5 fog, P6 Tamag | Sub kargyraa, scraping strings, slow tüngür, chains, inverted lullaby in low register | 50 / 54 | E Phrygian | Seductive dread |
| `tengri_sinav` | Deer stones, P2, P5 | Male choir chord, overtone whistles, eagle-like fiddle cry, frame drums | 64 / 80 rising | Open-fifth pentatonic | Awe, solemn test |
| `kacis` | P1 chase, P3 stampede | Driving 6/8 frame drums and tüngür, fast dombra, morin khuur lead, chants, dawn horn and choir quoting lullaby | 140 / 138 | Shared | Full gallop |
| `hun_ordasi` | Tuman's horde | Morin khuur gallop with neigh slides, limbe, tovshuur, frame drums, khöömei calls | 108 | Major pentatonic | Naadam joy |
| `islik_talim` | Training | Unison drums in tens, overtone accents, plucks | 100 | Shared | Disciplined, menace |
| `av` | Hunt, father's fall | Horns and gallop stripped to heartbeat, held choir, cold fiddle | 110→50 | Shared | Inevitability |
| `ak_kece` | Coronation | Male choir, war drums, long horns, fiddle, lullaby once in minor at the end | 76 | Shared | Triumph, shadowed |
| `elci`, `veda_ayaz`, `baskin` | P3 | Reed flute vs fiddle; solo fiddle lullaby; drone into war drums | 70; 58; 80→150 | Shared | Tension; heartbreak; ferocity |
| `onlu_yasa`, `kadfi_tema`, `yanik_kamp` | P4 | Drums in tens and number chant; bone flute with dombra; slowed `kamp_gece` with female wail | 72; 72; 56 | Shared | Solemn; bittersweet; guilt |
| `dort_renk`, `sis`, `kardeslik` | P5 | Four timbres locking (fiddle west, horn north, flutes east, drums south); fog with hummed lullaby; fiddle and guqin-like zither | 96; free; 68 | Shared | Encircling; crossroads; cautious hope |
| `ana_son`, `terazi`, `zincir_kopru` | P6 | Male hum with old woman's voice; chains, bell for kept, thud for broken; `kacis` in E Phrygian | 60; 54; 150 | E Phrygian on the bridge | Devastating; judgement; desperate |
| `ozan` | Epilog | Solo kopuz, gentle storytelling rhythm, throat drone, crickets, sparks | 76 | Shared | Nostalgic, wise |

**Shipped files:** `ak_kece, av, bahar_orda, baskin, dokuz_basli, erlik, gerilim, hun_ordasi, islik_talim, kacis, kamp_gece, kamp_gunduz, kiz_kuu, menu, ninni, prolog_dogum, sarki_ak_kulun, tengri_sinav, umay_goru`. Not produced: `ozan`, `sarki_ant` and the other P3–P6 ids in the table. For a winter camp bard, reuse the `ozan` brief without the crickets.

**Scene map:**
- `prolog_acilis` → `prolog_dogum`
- `prolog_umay_giris`…`prolog_tas_son` → `umay_goru`
- `prolog_dogum_son` → `prolog_dogum` plus ninni
- Title → `menu`
- `p1_acilis`…`p1_ayaz_gunduz` → `kamp_gunduz`
- `p1_yabgu` → `gerilim`, then `kamp_gunduz`
- `p1_gece_baslangic` → `kamp_gece`
- `p1_erlik` → `erlik`
- `p1_tengri` → `tengri_sinav`
- Stealth → `gerilim`
- Chase → `kacis`
- `p1_son` → `umay_goru`
- `p1_end_song` → `sarki_ak_kulun`

**Ambience:** prologue `summer_night`; Umay `spirit_realm`; camp day `camp_day` + `wind_winter`; camp night `night_camp` + `wind_winter`; interior `yurt_inside`; chase `blizzard` + `horse_gallop_loop`.

**SFX inventory:** `alarm_horn, ant_broken, ant_oath, arrow_impact, baby_cry, body_fall_snow, bone_clack, bone_flick, bow_draw, bow_release, brush_loop, chains, crowd_cheer, door_flap, drum_hit, eagle_cry, erlik_presence, erlik_whisper, fire_loop, guard_alert, heartbeat, horse_gallop_loop, horse_neigh, horse_rear, horse_snort, hum_loop, ice_crack, item_get, karakus_cry, knife_carve, knife_draw, lightning_fire, mirror_flash, step_dirt, step_grass, step_snow, storm_gust, straw_hit, sword_hit, tengri_presence, thunder_crack, thunder_rumble, title_boom, umay_presence, whip_crack, whip_swish, whip_windup, whistle_bone, whistling_arrow, wings_storm, wolf_howl`.

### Lyrics

**Ninni (`ninni`, 30 s, lines at 0, 7.5, 15, 22.5 s).** A cappella, solo young female voice, very close, rocking 6/8 at 60 BPM, D Dorian, felt-yurt hearth crackle, low drone hum on the second pass. Seven syllables per line, rhyme abab.

> Kulun kulun, ak kulun,
> Ayaz yemiş yelesin;
> Uzak düşse de yolun,
> Anan bilir gelesin.

> Little foal, my white foal,
> the frost has bitten your mane;
> though your road may fall far,
> your mother knows you'll come again.

Hunca, assembled from two dialogue lines (`p1_ayna`, `p2_tansu_itiraf`): "Kulun kulun, ak kulun, / Ayaz yėmiş yeliŋ; / Irak tüşser yoluŋ, / ögüŋ bilir kelgüŋ."

**"AK KULUN" (`sarki_ak_kulun`, 188 s, D Dorian, 6/8, 70→92 BPM).**
Structure with subtitle times: Intro (wind, lone fiddle, one whistling arrow), V1 12 s, Chorus 34 s, V2 58 s, Chorus 78 s (female voice joins), V3 102 s, Bridge 122 s (8 syllables, half-time, kopuz and throat voice only), Final Chorus 144 s (full gallop, riders' choir), Outro 174 s (woman alone, wind, distant wolf).
Verses: "intimate warm male baritone folk singer, dombra/kopuz plucking, soft frame drum heartbeat, low khöömei throat-singing drone".
Chorus: a female alto doubles the melody like a mother's lullaby; male riders shout "Ayaz, Ayaz!".

- **V1:** "Yad ilinde kış yattım, / Kıl ipimi taşıdım, / Yarım aynaya baktım, / Anam yüzün aradım."
  "I lay through winter in a stranger's land, / I carried my horsehair rope; / I looked into half a mirror, / searching for my mother's face."
- **Chorus:** the ninni, plus "Ayaz, Ayaz, yurda var! / Ok ötüyor, yol açar!"
  "Ayaz, Ayaz, ride for home! / The arrow sings, the road lies open!"
- **V2:** "Közden biri ses verdi, / Bir can için yol dedi; / Gök sustu, kurt bekledi, / İpimi kendim kestim."
  "A voice spoke out of the embers, / it offered me a road for a life; / the sky was silent, the wolf waited, / I cut my own rope with my own hand."
- **V3:** "Gümüş aygır kar yardı, / Tipi gözüm bağladı; / Bir çocuğun düdüğü / Düşman okta ağladı."
  "The silver stallion split the snow, / the blizzard bound my eyes; / a child's little whistle / wept upon an enemy's arrow."
- **Bridge:** "Anam düşte bir yol gördü, / Ucu karda yarım kaldı; / Her ant boynuma bağlandı, / Bin li atım doğu baktı."
  "My mother saw a road in a dream; / its end was left half-told in the snow. / Every oath was knotted at my throat; / my thousand-li horse turned to face the east."
- **Outro:** "Yurda var, yurda var... / Anan bilir gelesin."
  "Ride for home, ride for home... / your mother knows you'll come again."

**"ANT" (`sarki_ant`, 4/4, 72→96 BPM, E minor; structure Intro, V1, Pre-Chorus, Chorus, V2, Chorus, Bridge, Final Chorus, Outro).**
Usable single verse after Act II, the chorus: "Ant içtim, gök tanık, / Yer tanık, kurt tanık; / Sözüm ipim, ipim yolum, / Yolum yurda varacak!"
"I swore an oath, the sky is witness, / the earth is witness, the wolf is witness; / my word is my rope, my rope is my road, / and my road will reach home!"

**Which verse a camp bard can sing in Act I:**
- **Safe:** the ninni quatrain. My pick for a single verse.
- **Safe but first-person Motun:** V1. It fits Seyis Arslan singing of captivity.
- **Spoilers until after Act I:** chorus tag, V2, V3 and bridge. They narrate Erlik and the escape, and foreshadow Act III.
- **Canon friction:**
  - The lullaby is Hun. The Yuezhi speak Yüeçice, no Yüeçice lyrics exist, and Motun and Arslan use Hunnic in secret ("Yüeçi kulağı bizim dilimizi anlamaz").
  - Tansu knows its last two lines, so it is a Hun folk lullaby. The natural Act I singer is Arslan or Motun, not a Yuezhi bard.
  - Motun explains why it calms Ayaz: "Atlar ninniyi tanır. Hele annelerinin dilinde söyleneni." / "Horses know a lullaby. Especially one sung in their mother's tongue."

**Bard verses that react to choices (`destan.json`).** Four-line quatrains: slot 1 of 4 variants keyed on the Erlik choice, slot 2 of 2 keyed on Kara Kuş, then 3 slots each in Acts II and III. Example, `erlik_red`: "Ocaktan kor yükseldi, kara bir ses konuştu; / Rehine oğlan "defol" dedi, kor yine küle döndü. / Gök yarıldı geyik taşında, yıldızlar halka oldu; / Kendi ipini kendi kesti, kendi yolunu buldu." / "Embers rose from the hearth and a black voice spoke; / The hostage boy said "begone", and the ember fell to ash. / The sky split over the deer stones, the stars became a ring; / He cut his own rope himself, and found his own road."
Bard's opening: "Çinliler ona Modu dedi. Yüeçiler 'ıslığı olan' dedi. Bizim nenelerimiz başka bir ad verdi." / "The Han called him Modu. The Yuezhi called him 'the one with the whistle'. Our grandmothers gave him another name."

**Dombra and kopuz notes:**
- **No tuning is documented anywhere** in `story/`, `tools/music_spec.json`, `README.md` or `game/data`.
- Playing notes that do exist:
  - Plucked, not strummed.
  - Melody stays over the drone, with no chord progression.
  - "two-string dombra" with a "hypnotic galloping ostinato" (`menu`).
  - "plucked two-string lute" (`kiz_kuu`, `bahar_orda`).
  - "muted plucked dombra figures" (`gerilim`).
  - "solo kopuz with gentle storytelling rhythm" (`ozan`).
- The canonical bard instrument is the **kopuz**.
- Shipped `kacis` still says "strummed", which predates the rule.
- Outside the project, not canon: Kazakh dombras are commonly tuned a fourth or a fifth apart, which suits a low D drone.

---

## 4. Winter day and night in the Yuezhi camp

| Context | Tone | Sat | Bright | Tint | Vignette |
|---|---|---|---|---|---|
| Kış gündüz | "Açık, hafif sıcak" | 0.95–1.02 | 1.04–1.08 | (1.03, 1.01, 0.97) | 0.26–0.3 |
| Kış akşam/şafak | Pink-gold | 1.0–1.08 | 1.0 | (1.06, 0.96, 0.92) | 0.32–0.4 |
| Kış gece | "Mavi, ama yüzler okunur" | 0.8–0.9 | 0.95 | (0.92, 0.98, 1.1) | 0.42 |
| Tipi gecesi | Blue-violet, low saturation | 0.72 | 1.03 | (0.98, 0.98, 1.03) | 0.42 |
| İç mekân | "Ocak sıcağı" | 1.0 | 1.0 | (1.05, 0.98, 0.92) | 0.35 |
| Mitik Umay | Gold-cyan | 1.1–1.15 | 1.05 | (1.06, 1.02, 0.95) | 0.3 |
| Mitik Erlik | Red ember, heavy | 0.55–0.7 | 0.88 | (1.05, 0.86, 0.88) | 0.6 |

**Rules (`renk_isik_rehberi.md` §2):**
- "**Gündüz mavi değildir.** Kar gündüz beyaz ve hafif sıcak, gölgeler mavidir. Mavi baskın ton yalnız gece ve tipidir."
- "Sinematik kareler altın saate kilitlenmez."
- Sprites read through a dark outline. The hero's cyan kaftan stays "tek soğuk vurgu" in the crowd's red-brown palette.
- Sides by colour: Hunlar kızıl-kahve ve altın; **Yüeçiler bordo-hardal ve okra**; Doğu Hu kurt grisi ve samur kahvesi; Han siyah cila ve koyu kızıl.
- Light sources (fire, torch, hearth) are warm; moonlight and blizzard are cold. Mythic light keeps its own colour: Umay altın, Tengri beyaz-mavi, Erlik kızıl kor.
- Props are lit from the top left, with shadows falling bottom right.
- Prompt wording example: "bright winter noon, warm white snow, blue shadows".

**Values in code (kamp.gd:36-52, 65; level.gd:169-175):**
- Day ambient `Color(1.0, 1.0, 1.02)`, grade tint (1.0, 1.0, 1.03), vignette 0.3, saturation 1.02, snow 0.55.
- Night ambient `Color(0.46, 0.52, 0.74)`, grade tint (0.92, 0.98, 1.1), vignette 0.42, snow 0.9.
- Night player light: energy 0.45, colour (0.95, 0.9, 0.82), scale 3.2.
- `rehine_ic`: day (1.05, 0.97, 0.92), vignette 0.38, sat 0.95; night (0.96, 0.96, 1.05), vignette 0.5, sat 0.9.
- `aile_ic`: (1.0, 0.95, 0.95), vignette 0.48, sat 0.92.
- Note: the day tint in code is cooler than the guide. Follow the guide.

**Evaluation requirements that touch this:**
- Smoke rises from tündüks and helps wayfinding.
- A daylight shaft falls from the tündük indoors.
- Erlik needs rim light and glowing eyes so he does not become a silhouette.
- Trodden-snow paths link the landmarks: yabgu otağı, meydan ateşi, ağıllar, kam çadırı, geyik taşları (north, between the family yurt and the kurgan), nehir, depo, kutlu ağıl.
- Night: a crimson plate warns of forbidden ground. Proposed but not done: torches and fences marking zones, and patrol routes readable by tracks and lantern light.

---

## 5. Epigraph, boot, menu and settings strings

**Epigraph:**
- `EPIGRAPH` TR: «Yer, devletin temelidir. Onu kimseye vermem.»
- `EPIGRAPH` EN: «Land is the foundation of the state. I will give it to no one.»
- `EPIGRAPH_BY` TR: Motun, Hunların Tanhusu · MÖ 3. yüzyıl
- `EPIGRAPH_BY` EN: Motun, Tanhu of the Huns · 3rd century BC
- Source: 地者，國之本也，柰何予之 (Shiji 110). Other lines render it "Toprak devletin köküdür" / "Land Is the Root".

**Presentation (boot.gd:119-138):** background `Color(0.015, 0.018, 0.026)`; quote 48 px Alegreya-Italic in PARCHMENT; attribution 24 px Cinzel 600 in GOLD_DIM, spacing 4; music `menu` with a 4 s fade; fade in 1.6 s; holds 4.2 s, skippable.
**Flow:** first launch goes language ("Dilini seç  ·  Choose your language", TÜRKÇE / ENGLISH), voice, epigraph, then main menu. New Game calls `Game.reset()` and loads `prolog_kamp` (scene_manager.gd:52-55).

**Menu, in order (main_menu.gd:364-374):**
- `MENU_NEW` YENİ OYUN / NEW GAME
- `MENU_CONTINUE` DEVAM ET / CONTINUE
- `MENU_LOAD_BIG` YÜKLE / LOAD
- `MENU_ACTS` PERDELER / ACTS
- `MENU_SETTINGS` AYARLAR / SETTINGS
- `MENU_QUIT` ÇIKIŞ / QUIT

Also: `MENU_SUBTITLE` BİR BOZKIR DESTANI / AN EPIC OF THE STEPPE; `MENU_HINT` Kulaklıkla oynaman önerilir / Best experienced with headphones; `CONFIRM_NEW` Kayıtlı yolculuğun silinecek. Emin misin? / Your saved journey will be lost. Are you sure?; `MENU_CARD_LAST` SON KAYIT / LAST SAVE; `MENU_BACK_BIG` GERİ / BACK.

**Settings tabs and rows:**
- **Oyun / Game** ("Zorluk, karakter adları, görev işareti ve yazı hızı" / "Difficulty, names, the objective marker and text speed"):
  - Zorluk / Difficulty: Hikâye / Story, Normal, Zor / Hard
  - Karakter adları / Character names
  - Görev işareti / Objective marker
  - Kişi işaretleri / People markers
  - Yazı hızı / Text speed
  - Kovalamaca yardımı / Riding assist: Kapalı / Off, Az / Some, Çok / More
  - Islıklı ok / Whistling arrow: Basılı tut / Hold, İki kez bas / Double tap
  - Açık parkurlar (deneme) / Open courses (trial)
- **Dil / Language** ("Arayüz, altyazı, seslendirme ve kadim metin" / "Interface, subtitles, voice-over and the ancient text"):
  - Arayüz dili / Interface language
  - Altyazı / Subtitles: Türkçe, English, Türkçe + English
  - Seslendirme / Voice-over: Türkçe / Turkish, English, Kadim Diller / Ancient Tongues
  - Kadim metin / Ancient text
- **Görüntü / Display** ("Pencere ya da tam ekran, çözünürlük ve arayüz ölçeği" / "Window or full screen, resolution and interface scale"):
  - Ekran / Display: Pencere / Windowed, Tam ekran / Fullscreen
  - Çözünürlük / Resolution
  - Arayüz ölçeği / Interface scale: 80, 90, 100%; "Menüleri ve konuşma kutusunu küçültür." / "Shrinks the menus and the dialogue box."
- **Ses / Sound** ("Müzik, ses, efekt ve ortam" / "Music, voice, effects and ambience"): Müzik / Music, Seslendirme / Voice-over, Efektler / Effects, Ortam sesi / Ambience. Defaults 0.75, 1.0, 0.9, 0.8.
- `OPT_ON` Açık / On, `OPT_OFF` Kapalı / Off, `SET_BACK` GERİ / BACK.

**Voice notes:**
- `VOICE_NOTE_TR`: "Bütün karakterler Türkçe konuşur." / "Every character speaks Turkish."
- `VOICE_NOTE_EN`: "İngilizce seslendirme şimdilik anlatıcı ve tanrılarla sınırlı; öbür satırlar altyazıyla akar." / "English voice-over currently covers the narrator and the gods; the other lines run as subtitles."
- `VOICE_NOTE_KADIM_SHORT`: "Hunlar Hunca, Yüeçiler Yüeçice konuşur; altyazılar seçtiğin dilde akar. Dönemin dillerinden yeniden kurulmuştur." / "The Huns speak Hunnic, the Yuezhi speak Yuezhi; subtitles follow your language. Rebuilt from the tongues of the period."
- `BOOT_VOICE_NOTE`: "Seslendirme dilini ve altyazıyı ayarlardaki Dil sekmesinden istediğin zaman değiştirebilirsin." / "You can change the voice-over and subtitles at any time in Settings, under Language."

**Shared UI frame language:** "çift altın çizgi, düğümlü köşeler, mavi taş". Logo: Ordos animal style, crouching stag on the arrow.

---

## 6. Design criticisms a new version must not repeat (`tasarim_degerlendirmesi.md`)

**Game design**
- Kut and Korku unexplained in play. Explain each at its first change.
- Counters that nothing reads: they "artıyor ve arayüzde görünüyordu ama ne bir seçeneği ne bir sahneyi ne de oynanışı değiştiriyordu". Every axis must change options, scenes or play, and the player must see the consequence.
- One difficulty only. Offer Hikâye / Normal / Zor.
- No place to see collected items.

**Gameplay**
- Vague directions: "Zerin'in ocağına git — Zerin kim, nerede?". Use an objective diamond with an edge arrow and name labels, both toggleable.
- Invisible capture rules at night. Warn in forbidden zones and make the safe path visible.
- Chases that are too hard and restart from the very beginning. Base is 3 lives with section-start restarts.
- Long chains of "X'e git" with nothing to do between beats. Add short repeatable camp work.
- Pressing E to enter yurts: walk through instead. The "Gir" prompt and the "Yolculuk kaydedildi" toast at every door were also removed (now at most once a minute).

**Level design**
- Yurts too small for the character and out of proportion with interiors.
- Tiled ground with blocks and checker stains. Textures must be seamless.
- Interior floors that do not reach the door; a map edge right beside Kam Ece.
- Route chosen by menu. Choosing by the side of a burning cart you pass is the fix.
- Zigzag night route that had the player crossing the camp; it was cut to about half.
- Chase shorter than designed. Measure act times.

**Systems**
- Skills and items as decoration. Every item must do a job or be an explicit keepsake.
- Skills unlocked by story alone, unconnected to choices.
- Bugs to design against:
  - A scene change locking dialogue.
  - Scripted walks that stall.
  - Fast or low-framerate walks overshooting and orbiting the target.
  - Interrupted walks leaving an awaiter hanging and locks open.
- Requested and not yet done: key rebinding.

**Narrative**
- 16 choice flags set and never read in the same act, and three documented consequences missing from code (`yabgu_nobet`, `kadfi_bagli`, `sinav_bos`). Every choice needs an echo in the same act.
- Late lines sliding over the end song. Sequence them explicitly.
- Blocking dialogue during chases. Use non-blocking subtitles.
- Weapon contradiction: "eyerden ıslıklı ok" before the whistling arrow exists. In Act I the only weapon is the mirror (F).
- Teach a mechanic before it matters, in a safe moment (time slows, then a card).
- Bosses must be set up in story first. Kara Kuş only comes for those who refused Erlik, because "Erlik borçlusunu avlamaz".
- History must hold:
  - Tuman falls in every branch.
  - Liu Bang survives Ak Dağ.
  - Han does not ask for a hostage.
  - The Yuezhi withdraw rather than migrate in MÖ 206.
- No boss in Acts II, IV, V. No monsters in Yuezhi land.

**Art**
- Plain box UI outside the main menu.
- Oversaturated blue chase palette, and daytime strips that read as night.
- Interiors too dark by day.
- Generic Yuezhi art standing in for Tokar and Hun extras.
- Four art languages that did not read as one game. Use shared grading.
- Anachronism: balbals are MS 6.–8. yy, so use Bronze Age geyik taşları.
- A logo that read as a Celtic knot.
- Eagles belong to Tengri; Kara Kuş is a long-necked, bone-headed goose-form bird.
- Continuity: Ayaz stands in Tuman's pen but carries only Motun.
- Kız kuu and kökbörü have no period source. Mark them "kurgu tercihi".

**Scope rule (`yol_haritasi.md`)**
- "Bir perdeye en fazla iki yeni 'mekanik' girer; geri kalanı mevcutların yeni dozudur." The "no new engine" clause was deliberately relaxed in `faz4_plan.md` for mounted free roam.

---

## Conflicts in the sources

1. Lane wording ("şerit", "lane") remains in `ok`, `yagmur` and the bow tutorials. Lanes were removed from the Act I `kacis` chase only, so an open-world version must rewrite these strings.
2. `perde1_oynanis.md` §3.3 still describes the removed "korku halkası" calming game. Kulak is current (`faz4_plan.md` item 10).
3. Korku has three English names: "Fear" (skills), "DREAD" (ledger), "Korku" (tutorial).
4. Kadfi is 8 in ~MÖ 210 and 13 in MÖ 206, which is one year too many. The codex also keeps ages identical across P1 and P2.
5. The docs list no `atli` mastery value and only `boke_agir_yay` for `yagmur`; code has `atli` 3 and also `boynuz_yay`. Treat code as truth.
6. Docs say 20 achievements; `basarimlar.json` has 29.
7. `sarkilar.md` says about 3:30 and a double final chorus; the shipped file is 188 s and its subtitles show one pass. It also claims aaba/aaab rhyme, while the ninni is abab.
8. The lullaby's English varies: `p2_tansu_itiraf` "However far your road may fall, your mother knows you'll come." and `p3_baskin_agil` "Little foal, white foal...". Use `ninni.json`.