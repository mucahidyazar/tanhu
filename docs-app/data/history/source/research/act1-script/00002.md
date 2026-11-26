# TANHU Act 1 ("I. Perde — Rehine") port reference

This comes from reading the files only. Nothing was modified and the game was not run. All numbers come from code or data. The two exceptions are marked as computed or inferred: K5 real duration and px/m scale.

**Absolute paths.** Short names below, such as `kamp.gd:107`, refer to these files.
- Doc: `/Users/mucahidyazar/game-development/projects/tanhu-2d/story/perde1_oynanis.md`
- Dialogue data: `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/dialogue/perde1.json`
- Autoloads, in `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/autoload/`: `dialogue_manager.gd`, `game_state.gd`, `fx.gd`, `cinematic.gd`, `audio_manager.gd`, `settings.gd`
- Act 1 levels, in `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/perde1/`: `kamp.gd`, `kamp_layout.gd`, `rehine_ic.gd`, `aile_ic.gd`, `kacis.gd`
- Shared levels, in `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/levels/common/`: `chase_level.gd`, `chase_boss.gd`, `chase_storm.gd`, `mirror_arm.gd`, `interior_level.gd`
- World scripts, in `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/world/`: `guard.gd`, `player.gd`, `npc.gd`, `actor.gd`, `level.gd`, `kulak_game.gd`, `progress.gd`, `act_end.gd`, `ata_taslari.gd`, `myth_moments.gd`, `fire_ring.gd`
- UI: `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/ui/dialogue_ui.gd`, `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/ui/perde_ozeti.gd`, `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/ui/minigames/asik_game.gd`
- Data, in `/Users/mucahidyazar/game-development/projects/tanhu-2d/game/data/`: `items.json`, `skills.json`, `quests.json`, `codex.json`, `taslar.json`, `izler.json`, `destan.json`, `map.json`, `basarimlar.json`, `kadim_sozluk.json`, `props.json`, `i18n.json`, `songs/sarki_ak_kulun.json`

---

## 1. Dialogue runtime semantics (`dialogue_manager.gd`)

**File shape.** `{"speakers":{id:{name,name_en,color,voice?}},"sessiz":[...],"dialogues":{id:[rows]}}`. All JSON files in the folder are merged at boot, and later keys overwrite earlier ones.

**Row dispatch order per row (`_run`, lines 158–224):**
1. `label`: no-op. Labels never stop flow, so a branch falls through into the next label unless it `goto`s or `end`s. `red_kam` intentionally falls into `red`.
2. `goto` (row without `choice`):
   - If `if` is false, the row is skipped.
   - A local label jumps.
   - `"@id"` is a tail-call to row 0 of that dialogue with no return.
   - A missing target logs a warning and terminates the dialogue.
3. `if` false: skip the row. This applies to speech, cmd, end and choice rows.
4. `end`: terminate.
5. `cmd`: `await _exec`. Commands run strictly in sequence.
6. `choice`:
   - Options are filtered by their own `if`. If none remain, the row is skipped.
   - In ambient mode the first option is taken automatically with no UI.
   - An option's `set` dict is applied.
   - An option's `goto` must be a local label. `@` is not supported there. Without `goto`, flow continues to the next row.
   - Keys 1–9 also pick options.
7. `t` or `en` present: speech (`_say`).
- A guard stops the run after 5000 iterations.

**`start(id)` vs `start_ambient(id)`:**
- Both queue if another dialogue is active (`while active: await finished`).
- `start` calls `Game.lock()`, runs, closes the UI (0.2 s), unlocks, marks `dinlendi_<id>` and emits `finished(id)`.
- `finished` always carries the originally started id, even after `@` jumps (for example `finished("p1_depo")` after `@p1_kadfi_gece`).
- `start_ambient` takes no lock and no heard mark. Lines appear as a slim top subtitle, and choices auto-pick the first option. It is used during the chase.
- `abandon()` is called by scene change and drops the running dialogue.
- `kacis.gd:554` flips `Dialogue.ambient=false` mid-run, so `p1_son` plays with the normal box and real choices after the ambient `p1_tipi_safak` jumps into it.

**Speech row fields:**
- `s`: speaker, default `anlatici`. Motun's speaker id is `mete`.
- `t`, `en`: text.
- `mood`:
  - `mythic`: wave text in the speaker's colour, tinted box border and glow.
  - `whisper`: italic grey.
  - `shout`: bold with shake.
  - `happy` or normal: no decoration.
  - Any mood first tries portrait `assets/portraits/<s>_<mood>.png`, then `<s>.png`.
- `tone`: voice-generation direction only. It has no reference in runtime code.
- `if`: condition.
- `x`, `xl`: ancient-tongue line, shown and spoken only when `voice_lang=="kadim"`. `xl` is `otk` or `txb`.
- `vo:false` and the top-level `sessiz` list are read only by `tools/voice_gen.py`. At runtime a line plays voice if its file exists.

**Advancing (`_say`, lines 259–266):**
- Unvoiced line: wait for the advance key.
- Voiced narrator line: auto-advance 0.45 s after the voice ends, or immediately if skipped.
- Voiced non-narrator line: wait for the voice. Pressing during the voice skips and advances. If not skipped, it still waits for one more press.
- Ambient mode: voice plus 0.3 s, or `1.6 + len(text)/28` s if unvoiced.
- Typewriter speed is 48 chars/s × `Settings.text_speed`.
- Narrator speakers `anlatici` and `narrator` use centred subtitles with no box.
- Audio buses: `umay`, `tengri` and other gods use VoiceMythic. `erlik` uses VoiceDark. Everyone else uses Voice.
- Voice path: `assets/voice/<lang>/<dialogue_id>/<md5("speaker|text")[:10]>.mp3`, where text is `t`, `en` or `x` by language.

**Commands (`_exec`, lines 331–399):**

| cmd | Fields (default) | Behaviour | Blocks dialogue? |
|---|---|---|---|
| `set` | `key`, `value` (true) | `Game.set_flag`. True values on BOND keys add `ayaz_bag`. Achievement sweep runs next frame. | no |
| `add` | `key`, `value` (1) | Float stat. `kut`/`korku` pulse the HUD icon, and the first time shows toast `TUT_KUT`/`TUT_KORKU`. | no |
| `ant` | `id`, `to`, `t`, `en` | `make_ant` (ignored if the id exists; state `given`), hides UI, runs `FX.ant_ceremony`. | yes, about 5.5 s + 0.25 |
| `ant_keep`, `ant_break` | `id` | Change state plus toast. Not used in perde1.json. | no |
| `objective` | `t`, `en` | Sets the HUD objective. | no |
| `item` | `id`, `n` (1), `silent` | `give_item`. Auto-equips into an empty slot. Toast `+ name` (adds "kuşandın · I Heybe" if worn) or `− name`. `silent` suppresses the toast. | no |
| `equip` | `id`, `silent` | Not used in perde1.json. | no |
| `music` | `id`, `time` (2.0) | Crossfade. Same id is a no-op. | no |
| `sfx` | `id`, `volume` (0 dB) | One-shot. | no |
| `ambience` | `id` | Adds a layer and never removes others. Scene load resets layers via `set_ambience`. | no |
| `fade` | `to` black, white or clear (black), `time` (1.0) | `clear`: `await fade_in`. Others: hide UI, then `await fade_out`. | yes |
| `wait` | `time` (1.0) | Timer. | yes |
| `shake` | `power` (0.5), `time` (0.5) | Trauma-style, amplitude `power²×26×0.66` px. | no |
| `flash` | `color` (#ffffff), `time` (0.6) | Not used in perde1.json. | no |
| `vision` | `id` (none), `time` (1.6) | Screen grade plus particles for `erlik`, `tengri`, `umay`, `none`. `erlik` also lowpasses music at 1400 Hz and shakes. Each plays its presence sfx. | no |
| `title` | `t`, `sub`, `en`, `sub_en`, `hold` (3.0) | Hides UI, title card, total about hold+2 s. | yes |
| `event` | `id` | `await` the level handler, else the global handler (Cine `still`, `still_off`, `song`). Unknown ids are ignored. | yes, until the handler returns |
| any other name | | Treated as an event named after the cmd. | yes |

**Conditions (`Game.check`, `game_state.gd:247–287`):**
- `||` splits first (lowest precedence), then `&&`. There are no parentheses.
- Each atom may start with `!`.
- Atoms: `flag` (truthy), `item:id`, `ant:id`, `ant_kept:id`, `ant_broken:id`, `eq:id`.
- Comparisons: `>= <= == != > < =`, with left side a flag, `item:id` (count) or `ant:id` (state string).
- The empty string is true. Missing flags are false or 0.

**Chaining rule.** Scene-changing events are the last row. Level code registers handlers per scene. `after_dialogue(cb)` runs `cb` after the current dialogue ends, and is used by `p1_calm_tutorial`, `p1_yabgu_summon`, `p1_day_to_night` and `p1_ayaz_gece → p1_kacis_baslar`.

---

## 2. perde1.json statistics and inventories

**Totals:**
- 44 dialogues and 577 rows.
- 274 speech lines, 16 choice rows with 41 options, 55 labels, 27 goto rows, 5 end rows, 200 cmd rows.
- Commands: sfx 34, event 39, set 32, objective 18, add 17, item 14, music 12, ambience 9, vision 7, fade 6, ant 5, wait 3, shake 3, title 1.
- Speech characters: TR 14,532, EN 17,122. Choices: 1,074 / 1,172. Objectives: 492 / 578. Ant texts: 233 / 254.
- These counts include mutually exclusive branches.

**Speakers:**

| id | TR name | EN name | colour | lines | TR chars | EN chars |
|---|---|---|---|---|---|---|
| mete | Motun | Motun | #9fd3e6 | 102 | 4617 | 5465 |
| kadfi | Kadfi | Kadfi | #f0c27a | 34 | 1571 | 1874 |
| erlik | Erlik | Erlik | #e04848 | 28 | 1772 | 2081 |
| seyis | Seyis Arslan | Arslan the Groom | #d9b56c | 19 | 1326 | 1583 |
| tokar | Tokar | Tokar | #b04a3a | 17 | 806 | 958 |
| arsak | Arşak | Arshak | #b07850 | 16 | 886 | 925 |
| kam_ece | Kam Ece | Ece the Seer | #9fa8da | 12 | 751 | 883 |
| zerin | Zerin | Zerin | #d98c8c | 10 | 620 | 719 |
| nobetci | Nöbetçi | Guard | #c9a227 | 8 | 322 | 427 |
| anlatici | (none) | (none) | #efe2c4 | 7 | 510 | 613 |
| yabgu | Yabgu Vima | Yabgu Vima | #e0b040 | 7 | 495 | 509 |
| tengri | Tengri | Tengri | #bfe3ff | 4 | 162 | 199 |
| ay_hatun | Ay Hatun | Lady Ay | #e8a0a0 | 3 | 159 | 232 |
| cocuk | Yüeçi Çocuk | Yuezhi Child | #e8c890 | 3 | 244 | 278 |
| haberci | Haberci | Scout | #c0a080 | 1 | 84 | 99 |
| kadin | Yüeçi Kadın | Yuezhi Woman | #c8a2a2 | 1 | 72 | 92 |
| ihtiyar | Arabacı İhtiyar | Old Cartwright | #a8a08a | 1 | 71 | 97 |
| umay | Umay Ana | Mother Umay | #ffd98a | 1 | 64 | 88 |

Moods: mythic 40, shout 28, whisper 22, happy 3. `xl`: otk 142, txb 132.

**Dialogues (L = speech lines):**

| id | L | Trigger (file:line) | Purpose |
|---|---|---|---|
| p1_acilis | 4 | `rehine_ic.gd:58` first entry | Title card and narrator. Gives `rehine_kaftani` silently. Objective: mirror. |
| p1_ayna | 6 | chest interact `rehine_ic.gd:43` (`p1_basladi && !item:tunc_ayna`) | `tunc_ayna`, mother's voice, `ninni`, Kadfi calls from outside. |
| p1_kadfi_sabah | 12 | auto on leaving the yurt, `kamp.gd:280` (`item:tunc_ayna && !p1_kadfi_ok`) | `kemik_islik`. Choice `kadfi_ayat_soz`. Unlocks camp. |
| p1_zerin_sabah | 12 | talk Zerin `kamp.gd:86` | `tuz`, midnight hearth seed, keeper warning, `zerin_yalan`/kut. |
| p1_arsak_agil | 4 | talk Arşak `kamp.gd:87` | Fires `p1_calm_tutorial`. |
| p1_arsak_agil_son | 4 | after mare game `kamp.gd:430` | Cosmetic choice. Objective: Arslan. |
| p1_arslan_gunduz | 20 | talk Arslan `kamp.gd:88` | Reveals Tuman's betrayal, Ayaz, the knife. Oath `ant_arslan` or `arslan_antsiz`. `buz_ipucu`. |
| p1_ayaz_gunduz | 6 | rect trigger `kamp.gd:107` (`p1_seyis_ok && !p1_ayaz_gorundu`) | Lullaby calms Ayaz. Horn summons Motun. |
| p1_yabgu | 13 | `kamp.gd:475` (escort cutscene) | Death sentence at dawn. Choice `yabgu_nobet` or `tokar_kizgin`. Kam Ece's warning. |
| p1_kam_ece | 10 | talk Kam Ece `kamp.gd:94` (optional) | `kartal_tuyu`, `kam_uyari`, warns of the black bird. |
| p1_tokar_meydan | 11 | `kamp.gd:485`, chained after p1_yabgu | Protect Kadfi: kut, or korku + `tokar_kizgin`, or bow. |
| p1_aksam | 4 | entering rehine_ic, `rehine_ic.gd:59–64` (`p1_yabgu_ok && p1_tokar_ok && !p1_gece`) | Plan, narrator, `p1_day_to_night`. |
| p1_gece_baslangic | 2 | `rehine_ic.gd:79` | Night start. Objective: hearth. |
| p1_bark_sinir | 1 | day edge trigger `kamp.gd:109,409` | Floating bark, then 200 px push back. |
| p1_bark_kadin | 1 | 260 px zone `kamp.gd:104` | River ice hint. |
| p1_bark_ihtiyar | 1 | 260 px zone `kamp.gd:105` | Saddle location hint. |
| p1_bark_cocuk | 3 | 240 px zone `kamp.gd:106` (random line, 9 s cooldown) | Taunt and "two black geese" fable. |
| p1_bark_gece | 2 | talk Arslan at night `kamp.gd:139` (full dialogue) | "Uyu, Hun." line, plus Arslan's `yabgu_nobet` note (`vo:false`). |
| p1_yakalandi | 1 | `kamp.gd:515` | Caught line. |
| p1_erlik | 39 | hearth interact `aile_ic.gd:32` | Erlik scene, 5 outcomes (see §5). |
| p1_tengri | 9 | rect trigger `kamp.gd:141,527` (`p1_erlik_bitti && !p1_tengri_ok`) | Tengri's test. For `erlik_eli`: silent sky, then `@p1_ip`. |
| p1_arsak_gece | 8 | rect trigger `kamp.gd:138` (`p1_tengri_ok && !p1_arsak_gece_ok && !erlik_eli`) | Lie, excuse or truth (`arsak_dogru`). |
| p1_kurgan | 3 | interact `kamp.gd:143` (`p1_tengri_ok && !erlik_eli`) | `arslan_bicagi`, then `@p1_ip`. |
| p1_ip | 4 | goto from p1_kurgan or p1_tengri | Rope choice `ip_yabguya` or `ip_bilekte`. |
| p1_ip_otag | 2 | interact `kamp.gd:144` (`ip_yabguya && !p1_ip_asildi`) | Hang rope, kut +2. |
| p1_depo | 2 | interact `kamp.gd:146` (`ip_bilekte || p1_ip_asildi`) | `eyer`, `yular`, then `@p1_kadfi_gece`. |
| p1_kadfi_gece | 20 | goto | Kadfi: ant, tie or hostage. |
| p1_ayaz_gece | 7 | rect trigger `kamp.gd:150` (`item:eyer && !p1_ayaz_serbest`) | Calm game, naming, cut strap. |
| p1_kacis_baslar | 5 | `kamp.gd:310`, after p1_ayaz_gece | Alarm, then `p1_chase_start`. |
| p1_tipi_1 | 3 | K1 section `kacis.gd:75` (ambient) | Barks, ambience, objective. |
| p1_tipi_kadfi_cozuldu | 2 | `kacis.gd:150` if `kadfi_bagli` (ambient) | "Çocuk çözülmüş!" |
| p1_tipi_arsak | 2 | `kacis.gd:152`, 6 s in, if `arsak_dogru` and not `kadfi_bagli` (ambient) | Arşak drops out. |
| p1_rota_nehir / p1_rota_kuzey | 1 / 1 | `kacis.gd:231` at K2 start (ambient) | Route line, sets flag. |
| p1_tipi_2 | 2 | K2 (ambient) | Narrator and archers. |
| p1_tipi_buz | 2 | K3a (ambient) | Ice speaks, `p1_ice_break`. |
| p1_tipi_gecit | 2 | K3b (ambient) | Barrier barks. |
| p1_karakus_omen | 2 | `kacis.gd:494`, 6 s into K3, if Erlik's debtor (ambient) | "Kendi borçlumu avlamam". |
| p1_karakus | 8 | `kacis.gd:416`, first boss entry (normal, locked) | Erlik in the storm, bird released. |
| p1_karakus_son | 2 | `kacis.gd:512` on boss death (ambient) | Sets `p1_karakus`. |
| p1_tipi_kadfi | 6 | `kacis.gd:530`, K4 (normal, locked) | Release Kadfi under the tree. |
| p1_tipi_safak | 7 | `kacis.gd:251`, K5 start (ambient) | Dawn, wolf, Tengri, arrow, end of chase, then `@p1_son`. |
| p1_son | 10 | goto | Mirror catches sun, Umay, `ant_ayaz` or `ayaz_sozsuz`, `islikli_ok`, song. |
| p1_asik_teklif | 8 | talk Kadfi on felt `kamp.gd:329` (optional, after `p1_kadfi_ok`) | Knucklebones. |

**Events (37), all with handlers:**

| Event | In dialogue | Handler | Effect |
|---|---|---|---|
| p1_start | p1_acilis | `rehine_ic.gd:47` | Cutscene end, control on. |
| p1_unlock_camp | p1_kadfi_sabah | `kamp.gd:231` | Sets `p1_kadfi_ok`. |
| p1_calm_tutorial | p1_arsak_agil | `kamp.gd:232,418` | Walk to mare head+(-40,300), Kulak (1 round, diff 1.0, fear 0.7), then p1_arsak_agil_son. |
| p1_ayaz_bakis | p1_ayaz_gunduz | `kamp.gd:233,453` | `p1_ayaz_gorundu`, camera pan 1.2 s, hold 1.2 s. |
| p1_yabgu_summon | p1_ayaz_gunduz | `kamp.gd:234,464` | Escort to otag+(0,420), p1_yabgu, stage meydan, p1_tokar_meydan, checkpoint. |
| p1_day_to_night | p1_aksam | `rehine_ic.gd:48,74` | `p1_gece`, ambient, then p1_gece_baslangic. |
| p1_time_freeze | p1_erlik | `aile_ic.gd:40` | Particles ×0.03, sprites stop, red grade 1.5 s, wait 1 s. |
| p1_erlik_rise | p1_erlik | `aile_ic.gd:44` | Camera pans, Erlik figure height 760 px rises from hearth (2.6 s). |
| p1_knife_walk | p1_erlik | `aile_ic.gd:48,68` | 3 steps at 70 px/s to bed+(-170,110), heartbeat, zoom 1.25. |
| p1_bed_reveal | p1_erlik | `aile_ic.gd:49` | Prop `broken_bed`. |
| p1_erlik_smoke | p1_erlik | `aile_ic.gd:52`; applied `kamp.gd:271–275` | `erlik_smoke_pending` becomes `erlik_smoke_active`, blinds guards. |
| p1_erlik_leave | p1_erlik (2×) | `aile_ic.gd:53` | Figure vanishes 2 s, unfreeze. |
| p1_tracks | p1_erlik (2×) | no-op in `aile_ic.gd:58`; real one at `kamp.gd:277,520` | Footprints when entering camp. |
| p1_tengri_sky | p1_tengri | `kamp.gd:236` | Pillar, 14-star ring (300×120 px, 14 s/turn), wait 2.5 s. |
| p1_gok_sessiz | p1_tengri | `kamp.gd:239` | Heavier snow, blizzard −8 dB, wait 1.5 s. |
| p1_arsak_watch | p1_arsak_gece | `kamp.gd:243` | Arşak faces player. |
| p1_knife_found | p1_kurgan | `kamp.gd:246` | sfx. |
| p1_rope_cut | p1_ip | `kamp.gd:247` | Flag `p1_ip_kesildi`. |
| p1_rope_hang | p1_ip_otag | `kamp.gd:248` | Prop `rope_spear` at (2710,1290), flag `p1_ip_asildi`. |
| p1_kadfi_home | p1_kadfi_gece | `kamp.gd:543` | `p1_kadfi_cozuldu`, runs home, hidden. |
| p1_kadfi_tied | p1_kadfi_gece | `kamp.gd:552` | `p1_kadfi_cozuldu`, moved to (3340,2740). |
| p1_kadfi_follow | p1_kadfi_gece | `kamp.gd:560` | `p1_kadfi_cozuldu`, follows at 90 px, speed 240. Guards within 800 px of pen get `suspicion_rate×0.5`. |
| p1_calm_ayaz | p1_ayaz_gece | `kamp.gd:254,437` | Kulak (3 rounds, diff 1.5, fear 0.66 with salt else 1.0), `p1_ayaz_sakin`, `p1_ayaz_tuz`. |
| p1_ayaz_free | p1_ayaz_gece | `kamp.gd:572` | `p1_ayaz_serbest`, sfx. |
| p1_alarm | p1_kacis_baslar | `kamp.gd:578` | Unblinded guards run to pen. |
| p1_asik_oyna | p1_asik_teklif | `kamp.gd:366` | AsikGame, flags, `asik_kesesi`. |
| p1_chase_start | p1_kacis_baslar | `kamp.gd:588` | `p1_kovalamaca`, `chase_cp=0`, save, load kacis. |
| p1_ice_break | p1_tipi_buz | `kacis.gd:517` | All current riders fall. |
| p1_kadfi_release | p1_tipi_kadfi | `kacis.gd:541` | `dead_tree` fades in, wait 1.2 s. |
| p1_dawn | p1_tipi_safak | `chase_level.gd:754` | `dawn(50)`, not 60. |
| p1_wolf_join | p1_tipi_safak | `chase_level.gd:1492` | Wolf above Motun's line, below for `erlik_eli`. |
| p1_tengri_seal | p1_tipi_safak | `kacis.gd:389` | Last great bolt at (1480,688), storm ends. |
| p1_whistle_arrow | p1_tipi_safak | `chase_level.gd:1573` | Slow motion 0.22. |
| p1_chase_end | p1_tipi_safak | `kacis.gd:551` | Halt 2.5 s, music `umay_goru`, still `p1_son_tepe`. |
| p1_end_song | p1_son | `kacis.gd:562` | Song, then `ActEnd.run`. |
| p1_erlik_storm | p1_karakus | `kacis.gd:436` | Erlik height 980 px at (1480,1140). |
| p1_karakus_release | p1_karakus | `kacis.gd:452` | Slow motion 0.4, bird spawned held, Erlik vanishes. |

- `p1_caught` is registered (`kamp.gd:266`) but not fired from JSON.
- `p1_route_choice` is documented as removed.

**Flags set in JSON (28):** `ninni`, `kadfi_ayat_soz`, `zerin_yalan`, `baba_ofke`, `baba_umut`, `arslan_gel`, `arslan_antsiz`, `buz_ipucu`, `yabgu_nobet`, `tokar_kizgin`, `kam_uyari`, `erlik_red`, `erlik_pazarlik`, `erlik_vazgec`, `erlik_eli`, `arsak_gordu`, `arsak_dogru`, `ip_yabguya`, `ip_bilekte`, `kadfi_ant`, `kadfi_ipucu`, `kadfi_bagli`, `kadfi_rehin`, `ayaz_ad`, `rota_nehir`, `rota_kuzey`, `ayaz_sozsuz`, `p1_karakus`.

**Stats (`add`):** `kut` in zerin, arslan, tokar, erlik, arsak_gece, ip_otag, kadfi. `korku` in yabgu, tokar, erlik, kadfi.

**Flags read by JSON conditions:** `!arslan_gel`, `ninni`, `item:kartal_tuyu`, `yabgu_nobet`, `kam_uyari`, `kadfi_ayat_soz`, `erlik_eli`, `erlik_pazarlik`, `ip_yabguya`, `kadfi_rehin`, `item:tuz`, `item:kara_bicak`, `buz_ipucu`, `erlik_vazgec`, `p1_asik_kazandi`, `item:asik_kesesi`. No Act 1 row or Act 1 level code reads a prologue flag or a kut/korku threshold.

**Flags set by code (the port needs these for flow):**
- `p1_basladi`, `p1_kadfi_ok`, `p1_zerin_ok`, `p1_arsak_ok`, `p1_seyis_ok`, `p1_kam_ok`, `p1_ayaz_gorundu`, `p1_yabgu_ok`, `p1_tokar_ok`, `p1_gece`
- `p1_erlik_bitti`, `p1_izler`, `p1_izler_goruldu`, `p1_tengri_ok`, `p1_arsak_gece_ok`, `p1_ip_kesildi`, `p1_ip_asildi`, `p1_kadfi_cozuldu`
- `p1_ayaz_sakin`, `p1_ayaz_tuz`, `p1_ayaz_serbest`, `p1_asik_ok`, `p1_asik_kazandi`, `kadfi_dost`
- `erlik_smoke_pending`, `erlik_smoke_active`, `p1_kovalamaca`, `chase_cp`, `p1_karakus_seen`
- `seen_flash_tut`, `seen_storm_tut`, `seen_kulak_tut`, `tas_p1_nehir`, `tas_p1_kam`, `tas_p1_geyik`
- `ayaz_bag`, `bag_*`, `goru_parca`, `goru_p1`, `p1_bitti`
- Auto-set: `seen_kut`, `seen_korku`, `dinlendi_<id>`, `sure_ACT_1`, `cp_*`

**Oaths:**
| id | to | TR | EN | In |
|---|---|---|---|---|
| ant_arslan | Seyis Arslan | Bu kamptaki her Hun esirini geri alacağım. | I will bring home every Hun captive in this camp. | p1_arslan_gunduz |
| ant_erlik | Erlik | Bir gün okum bir babanın yüreğine ötecek. O kan Erlik'in. | One day my arrow will sing into a father's heart. That blood is Erlik's. | p1_erlik (pazarlık) |
| ant_erlik | Erlik | Elim evet dedi. Erlik'e bir can borçluyum. | My hand said yes. I owe Erlik a life. | p1_erlik (vur) |
| ant_kadfi | Kadfi | Döndüğüm gün Kadfi'ye ve ocağına hiçbir Hun kılıcı değmeyecek. | The day I return, no Hun blade will touch Kadfi or his hearth. | p1_kadfi_gece |
| ant_ayaz | Ayaz | Seni hiçbir hana vermeyeceğim. | I will never give you to any khan. | p1_son |

**Items:**

| id | TR | EN | Slot | Source | Effect |
|---|---|---|---|---|---|
| rehine_kaftani | Rehine Kaftanı | Hostage's Caftan | govde | p1_acilis, silent | Worn. |
| tunc_ayna | Kırık Tunç Ayna | Cracked Bronze Mirror | kemer | p1_ayna (auto-granted at chase start if missing, `kacis.gd:87`) | F in chase. |
| kemik_islik | Kemik Islık | Bone Whistle | boyun | p1_kadfi_sabah | Q whistle, must be equipped. |
| tuz | Tuz Kayası | Salt Block | none | p1_zerin_sabah | Gentler Kulak, bond +5, one line. Not consumed. |
| kartal_tuyu | Kartal Tüyü | Eagle Feather | bas | p1_kam_ece | Two extra lines only. |
| arslan_bicagi | Arslan'ın Bıçağı | Arslan's Knife | el | p1_kurgan | Line in p1_ayaz_gece. |
| kara_bicak | Kara Demir Diş | Black Iron Tooth | el | p1_erlik kabul (removed in `indir`) | Line in p1_ayaz_gece. |
| erlik_kulu | Erlik'in Külü | Erlik's Ash | none | p1_erlik pazarlik_ant | Throw in a fire: blinds guards within 750 px. Consumed. |
| eyer | Keçe Eyer | Felt Saddle | none | p1_depo | Gates the pen trigger. |
| yular | Yular | Bridle | none | p1_depo | None. |
| tahta_at | Yarık Tahta At | Split Wooden Horse | none | p1_erlik vur | Keepsake. |
| islikli_ok | İlk Islıklı Ok | The First Whistling Arrow | ok | p1_son | Used from Act II. |
| asik_kesesi | Aşık Kesesi | Pouch of Knucklebones | none | after aşık, silent | Keepsake. |

- `items.json` entries not granted in Act 1: `esir_ipi`, `asik_altin` (no grant anywhere), `ayna_parcasi`.
- Unused prop art in Act 1: `eagle_feather`, `erlik_knife`, `knife_bundle`, `salt_pouch`, `erlik_ash`.
- Equip slots: `bas`, `boyun`, `govde`, `kemer`, `el`, `yay`, `ok` (UI labels Baş, Boyun, Gövde, Kuşak, Bıçak, Yay, Sadak).

**Audio ids in JSON:**
- Music: `kamp_gunduz`, `gerilim`, `kamp_gece`, `erlik`, `tengri_sinav`, `kacis`, `umay_goru`.
- SFX: `horse_snort`, `ant_oath`, `horse_neigh`, `alarm_horn`, `body_fall_snow`, `guard_alert`, `erlik_presence`, `chains`, `knife_draw`, `heartbeat`, `ice_crack`, `eagle_cry`, `tengri_presence`, `wolf_howl`, `whistling_arrow`, `umay_presence`.
- Ambience: `wind_winter`, `yurt_inside`, `camp_day`, `night_camp`, `blizzard`.
- Vision: `erlik`, `tengri`, `umay`, `none`.
- `shake` powers: 0.2, 0.4, 0.3. Fades: 6. Waits: 2.5, 2.0, 1.5 s. Title: `{"t":"I. PERDE","sub":"REHİNE","en":"ACT I","sub_en":"THE HOSTAGE"}`.

**Audio used only from code:** `door_flap`, `step_snow`, `step_dirt`, `whistle_bone`, `horse_gallop_loop`, `horse_rear`, `arrow_impact`, `mirror_flash`, `thunder_crack`, `thunder_rumble`, `lightning_fire`, `storm_gust`, `karakus_cry`, `wings_storm`, `sword_hit`, `item_get`, `title_boom`, `bone_flick`, `bone_clack`, `hum_loop`, music `sarki_ak_kulun`.

**Music lengths (seconds):** kamp_gunduz 120, kamp_gece 110, gerilim 80, erlik 90, tengri_sinav 95, kacis 150, umay_goru 85, sarki_ak_kulun 188. Ambience loops are 20–22 s.

**Scene ambience:**
- Day: `camp_day`, `wind_winter`.
- Night: `wind_winter`, `night_camp`.
- Interiors: `yurt_inside`.
- Chase: `blizzard` at −4 dB.

**Objectives in order:**
- Sandıktaki aynayı al. / Take the mirror from the chest.
- Kadfi'yi dışarıda karşıla. / Meet Kadfi outside.
- Zerin'in ocağına git. / Go to Zerin's hearth.
- At ağılında Arşak'a yardım et. / Help Arshak at the horse pen.
- Seyis Arslan'ı bul. / Find Arslan the groom.
- Gümüş aygırı gör: kutlu ağıl. / See the silver stallion at the sacred pen.
- Akşam olmadan otağına dön. / Return to your tent before nightfall.
- Gece yarısı Zerin'in ocağını besle. / At midnight, feed Zerin's hearth.
- Kadfi'nin izlerini takip et. / Follow Kadfi's tracks.
- Kendi yolunu bul: bıçak, eyer, at. / Find your own road: a blade, a saddle, a horse.
- Arslan'ın bıçağını kurgandan al. / Take Arslan's knife from the kurgan.
- İpi yabgunun kapısına as. / Hang the rope on the yabgu's door.
- Depodan eyer ve yular al. / Take a saddle and bridle from the store.
- Kutlu ağıla sız. Aygırı serbest bırak. / Slip into the sacred pen. Free the stallion.
- Kamptan çık: üst taraftan kuzey yolu, alt taraftan nehir. / Break out: keep high for the north road, low for the river. (Set from code, `kacis.gd:145`.)
- Kaç! Şafağa yetiş. / Ride! Outrun the night.

---

## 3. Map (`kamp_layout.gd`, `kamp.gd`)

**Frame and bounds:**
- `SIZE=(5200,3600)` px. Top-down: x east, y south (north is small y).
- Solid walls surround the map.
- River wall: `Rect2(0,3420,4300,180)`.
- Painted river ice band: (0,3330) → (1200,3290) → (2600,3340) → (3900,3300) → (5200,3360), width 300 px.
- Day border triggers (`kamp.gd:109`): `Rect2(0,0,5200,140)`, `(0,0,140,3600)`, `(5060,0,140,3600)`, `(0,3170,5200,120)`. They play the bark and walk the player 200 px toward map centre.

**Scale (inferred, there is no constant):**
- Sprites give about **90 px/m**: Motun's head at 153.8 px (1.71 m), Kadfi 112 px (1.24 m), horse 213 px long (2.37 m), yurt_big 825 px wide with footprint 742 px (8.2 m), rehine yurt footprint 533 px (5.9 m), aile yurt footprint 672 px (7.5 m).
- At 90 px/m:
  - Map: 57.8 × 40 m.
  - Walk 210 px/s = 2.33 m/s. Run 390 = 4.33 m/s. Sneak 120 = 1.33 m/s. Guard patrol 147 = 1.63 m/s.
  - Vision 430 px = 4.8 m. Whistle 560 px = 6.2 m.
- That is cramped for 3D. Positions can be spread independently of prop sizes:

| px per m | Map (m) | Rehine→aile safe path (2291 px) | Vision radius if scaled |
|---|---|---|---|
| 90 | 58×40 | 25 m | 4.8 m |
| 45 | 116×80 | 51 m | 9.6 m |
| 30 | 173×120 | 76 m | 14.3 m |
| 20 | 260×180 | 115 m | 21.5 m |

- Suggested starting point: 30 px/m for positions, real-size props, and all radii in this report divided by the same factor. Conversion: `X=(x-2600)/S`, `Z=(y-1800)/S`.
- Art is foreshortened, with ground circles drawn at ratio 0.40–0.47 (deer ring 170×80, star ring 300×120, campfire footprint 158×63). Code treats x and y as isotropic for movement and vision. Use uniform scale and make rings circular in 3D.

**Named points:**

| Spot | (x,y) | Contents |
|---|---|---|
| meydan | 2600,1820 | Campfire, logs (2410,1850), (2770,1880), cauldron (3020,1700), firewood (2220,1670), packed-snow blob r340 |
| otag | 2600,1130 | `yurt_big` scale 1.45 at (2600,1170), banners (2150,1260), (3050,1260), torches (2390,1260), (2810,1260), weapon rack (2030,1180), drying rack (3190,1170), court blob at (2600,1250) r260 |
| rehine_otagi | 1260,1900 | `yurt_small` scale 1.6 at (1260,1930), door (1260,1957.2), stake (1590,1990), firewood (920,1970), barrel (1620,1920) |
| aile_otagi | 3420,1290 | `yurt` scale 1.6 at (3420,1330), door (3420,1358.8), drying rack (2980,1370), hay (3840,1380) |
| agil | 4060,2020 | fence_h at y 1720 and 2320, x 3730, 3940, 4150, 4360; fence_v at x 3620 and 4500, y 1850, 2015, 2180; gate (3620,2350); horses: mare (3880,1900), black (4220,2060), white (4000,2190); hay (4310,1850) |
| seyis | 3800,2380 | Hay (3680,2420), cart (3960,2400) |
| kutlu_agil | 4560,1420 | fence_h (4450,1250), (4670,1250), (4450,1590), (4670,1590); fence_v (4330,1360), (4790,1360); `horse_legend` Ayaz (4560,1460) |
| kam_cadiri | 1420,2900 | `shaman_tent` scale 1.35 at (1420,2940), torch (1210,3020), drying rack (1740,2970) |
| depo | 3500,2700 | Cart (3380,2700), barrel (3620,2640), crates (3700,2740), firewood (3440,2820). Night: saddles (3660,2810) |
| balballar | 3080,520 | 5 deer stones at (3250,520), (3133,596), (2942,567), (2942,473), (3133,444); #2 glows at night. Trigger x 2800–3360, y 350–690 |
| kurgan | 4560,620 | `kurgan` footprint 462×138, stones (4220,740), (4890,760). Night: `skull_stone` (4560,780), interact (4560,770) r90 |
| kuzey_cikis | 4900,900 | Guards only |
| nehir | 2600,3330 | Ice bank, reeds along y≈3160 every 230 px |

**Derived points:**
- Kadfi's felt `FELT_AT` (3430,1540), size 210×96.
- Arşak's watch fire (4530,880); Arşak at (4390,920). Trigger x 4190–4870, y 600–1160.
- Spawns: `start` (1260,2027), `rehine_otagi` (1260,1969), `aile_otagi` (3420,1371).
- Doors are `DoorZone` 150×44, entered by walking up. The aile door works only if `p1_gece && !p1_erlik_bitti`.
- Other yurts, scale 1.5: (1700,1150), (800,1250), (2150,2650), (3000,2980), (3800,850), (600,2150), (1950,3050).
- Trees: (250,300), (520,520), (180,860), (900,330), (1350,260), (380,1700), (160,2400), (3900,300), (4200,420), (5000,2600), (4950,3000).
- Random scatter (seed 20926): grass 30, rocks 12, bushes 10.

**Path polylines (width px):**
- (1260,1930) → (1700,1880) → (2600,1820) → (3200,1900) → (4060,2020), 150
- meydan → (2600,1450) → (2600,1170), 140
- meydan → (3000,1560) → (3420,1330), 110
- meydan → (2100,2350) → (1420,2940), 110
- agil → (4300,1700) → kutlu_agil, 100
- agil → (4500,1300) → (4800,950) → kuzey_cikis, 90
- meydan → (2900,2400) → depo, 100
- (3420,1230) → (3260,900) → (3140,640), 80
- (3280,560) → (3900,560) → (4360,700), 80

**Kadfi's tracks, 46 px spacing:** (3480,1430), (3270,1170), (3260,900), (3200,660), (3380,640), (3820,1180), (3880,2000), (3420,2680).

**NPC placement, day (`kamp.gd:81–110`):**

| NPC | Position |
|---|---|
| Kadfi | (1430,2070); after p1_kadfi_sabah on felt at (3310,1540); after aşık patrols (3220,1510) ↔ (2760,1700) |
| Zerin | (3580,1510), cauldron (3680,1480) |
| Arşak | (3500,2080); after lesson walks (3500,1800) → (3560,1555) → seat (3510,1485) |
| Arslan | (3760,2380) |
| Vima | (2600,1380), fires (2410,1430), (2790,1430) |
| Tokar | (2300,1490); scene position (2750,1800) |
| Kam Ece | (1600,3050) |
| Guards | (2340,1370), (2860,1370) (these two become the escort), (4260,1540), (4820,960), (4980,1020) |
| Patrol guard | (2900,2020) → (2200,2040) → (3300,2600) |
| Women | (2300,3160) with bark, (2480,3180) |
| Old man | (3240,2760) with bark |
| Child | (2220,2080) ↔ (2480,2200) with bark |
| Stones | `tas_p1_nehir` (1700,3090), `tas_p1_kam` (1000,2720), `tas_p1_geyik` (3410,580) |
| Scene marks | Escort destination (2600,1550); Kadfi (2660,1860); Motun (2460,1910) |

**NPC placement, night (`kamp.gd:113–157`):**

| NPC | Position |
|---|---|
| Static guards, facing meydan with ±0.9 rad sweep | (2360,1390), (2840,1390), (4230,1560), (4360,1180), (4810,970), (4990,1020), (3000,3110) |
| Added if `tokar_kizgin` | (4860,1680) |
| Added if `yabgu_nobet` | (4600,1090) |
| Patrol A | (2800,1980) → (3240,2540) → (3500,2320) |
| Patrol B | (3760,2860) → (3860,2400) → (2400,2120) |
| Tokar patrol | (4060,1420) → (3000,1430) → (2900,1620) |
| Added only if `kadfi_ipucu` at level build | (4360,1180) → (4940,1000), wait 20 s |
| Arslan | (3740,2400), talkable |
| Kam Ece | (1580,3050), not talkable |
| Kadfi | (3440,2660), visible after `p1_erlik_bitti` |

- Patrols walk straight lines at 147 px/s, wait 2.5 s per waypoint, and pause while a dialogue is active.

**Stealth geometry:**
- Allowed (guards ignore the player): `Rect2(1000,1840,2680,560)`, `(3120,1190,600,400)`, `(2180,1580,1540,280)`, plus ±120 px around the polyline (1260,1930), (1700,1880), (2600,1820), (3000,1560), (3420,1330).
- **Everything else is forbidden.** `is_forbidden` returns true by default, so the `_forbidden` rect list has no effect.
- Hide zones, all 220×140 centred: (3380,2700), (3620,2640), (3960,2400), (1030,1960), (3700,1370), (3540,2360), (4140,1680).

**Interiors (image px; world = ×1.25):**

| | rehine_ic | aile_ic |
|---|---|---|
| Image | 1536×1024 | 1536×1024 |
| Floor ellipse | centre (760,523), radii (440,204) | centre (790,570), radii (500,196) |
| Hearth | (770,545) | (780,620) |
| Door | (760,830), half 52 | (768,845), half 55 |
| Blocks | (770,545)/(95,48); (560,390)/(170,62); (925,360)/(92,48); (380,520)/(90,44) | (780,620)/(110,55); (450,400)/(230,80); child bed (1190,420)/(120,60); (1330,510)/(50,35); (320,670)/(130,60); (235,520)/(70,60) |
| Interact | Chest (925,380), r95 | Hearth world +(0,-30), r120 |
| Other | Act start (600,480) | Bed prop at bed+(0,40), scale 1.4 |

**Walking times at original speed:**

| Leg | px | Walk |
|---|---|---|
| Rehine door → Zerin | 2408 | 11.5 s |
| Zerin → Arşak | 576 | 2.7 s |
| Arşak → Arslan | 397 | 1.9 s |
| Arslan → pen trigger | 1012 | 4.8 s |
| Meydan → rehine door | 1207 | 5.7 s |
| Meydan → Kam Ece | 1589 | 7.6 s |
| Aile door → stones | 906 | 4.3 s |
| Stones → kurgan | 1514 | 7.2 s |
| Kurgan → otag rope | 2018 | 9.6 s |
| Otag rope → saddle | 1878 | 8.9 s |
| Kurgan → saddle | 2221 | 10.6 s |
| Saddle → pen trigger | 1452 | 6.9 s |

---

## 4. Numbers

**Player and camera (`player.gd`, `actor.gd`):**
- Walk 210, run 390 (Shift), sneak 120 (toggle C/Ctrl). Velocity lerp 14/s.
- Noise: sneak 0.15, walk 0.55, run 1.0, idle 0.
- Reach area r64, added to each interactable's radius. NPC talk radius 90.
- Keys: E/Enter interact, Q whistle, Space jump, F mirror, C duck, I Heybe, Tab Ant Defteri, G Görev.
- Godot view 1920×1080 at zoom 1. Camera offset (0,-70), look-ahead 70, smoothing 4.5.

**Stealth (`guard.gd`, `level.gd`):**
- `view_distance` 430 px, `view_angle_deg` 62 (full cone), `suspicion_rate` 1.1, `calm_rate` 0.45/s. Line of sight is a ray against collision layer 1.
- Hearing: `dist<170 && noise>0.8` (running only).
- If the player is on allowed ground, suspicion just decays.
- Otherwise, while seen or heard:

  `ds/dt = 1.1 × diff(0.55,1,1.4) × (0.45 + 1.4·(1−d/430)) × (sneaking ? 0.35 : 1) × lerp(0.4,1.3,light) × (seen ? 1 : 0.6)`

- Marks: `?` above 0.12, `!` above 0.55, caught at 1.0.
- `light_at`:
  - Base is ambient luminance. Night ambient is (0.46,0.52,0.74), about 0.523.
  - Inside a hide zone: base×0.25, about 0.131. Hide zones reduce light only, they do not hide.
  - Lights add `energy×(1−d/r)×0.8`. Campfire r≈538 px, energy 1.35, so light clamps to 1 within about 300 px.
- Time to detection at normal difficulty, open night, walking: d=430 about 2.3 s, d=215 about 0.9 s, d=50 about 0.6 s. Sneaking: 6.6 s, 2.6 s, 1.8 s. Sneaking in a hide zone at d=215: about 4.4 s.
- Caught flow: `p1_yakalandi`, `alarm_horn`, red flash, card `CAUGHT`/`CAUGHT_SUB` (YAKALANDIN / Gece henüz bitmedi. Bir daha dene.), then scene reload at the last spawn. **Flags and items are not rolled back.**
- Whistle: noise at player+facing×40, radius 560, 1.6 s cooldown through the skill bar. The Q key path has no cooldown.
- Investigate: 0.6 s delay, walk to 40 px short, 3 random looks of 0.9 s each, walk home.
- Ash: `blind_guards(fire,750)`. Night fires: (2600,1820), (3020,1700), (4530,880).
- Erlik smoke: blinds guards more than 700 px from kutlu_agil at level start. That is the two otag guards, the river guard and patrols A and B. Pen guards, the kuzey_cikis guards (515, 587 px) and Tokar (500 px) stay active, but the zone warning plate is hidden.
- `_calming=true` during the Ayaz game makes the pen allowed ground.

**Kulak (`kulak_game.gd`), the actual calm game. The doc's "korku halkası" text is obsolete:**
- `REACH` 62, `STEP_SPEED` 110, `AWARE` 560.
- `difficulty = diff × Settings.diff(0.7,1,1.3)`.
- Ear cycle forward → warn → pinned:
  - Forward: `rand(2,3.4) × lerp(1.25,0.8,fear) / sqrt(difficulty)`; salt ×1.25; at hand ×1.4.
  - Warn: `max(0.45, 0.75/sqrt(difficulty))`.
  - Pinned: `rand(1,1.6) × lerp(0.8,1.2,fear) × sqrt(difficulty)`; salt ×0.8; at hand ×0.8.
- Moving (speed >25) with pinned ears inside AWARE: spook, push back 110 px, `fear+0.15`, cooldown 1.4 s, ears pinned for time×0.6.
- Running (speed >148.5) within 320 px with ears forward: ears pin.
- More than 900 px away: walked back to 380 px.
- At head with ears not pinned: "hand" phase, hold E.
- Calm rate while holding with ears forward: `1/(3.2·sqrt(difficulty))` per second, salt ×1.25. That is 3.2 s for the mare, 3.92 s for Ayaz, 3.13 s for Ayaz with salt.
- Decay:
  - Forward, not holding: −0.05/s.
  - Pinned, not holding: −0.02/s.
  - Pinned, holding: −0.45/s and fear +0.1/s. Reaching zero loses the round, with ears pinned for time×0.7.
- After each round won: `fear = 1 − round/rounds`.
- There is no hard fail.
- First-time teaching: ears at time scale 0.25, hand at 0.35.
- Mare: head (3730,1950), start stand (3690,2250). Ayaz: head (4410,1510), start stand (4160,1470).

**Ayaz bond:** `p1_ayaz_sakin` +15, `p1_ayaz_tuz` +5, `ayaz_ad` +10, `ant:ant_ayaz` +10. The maximum during the chase is 30, because the oath comes after it. With `k=ayaz_bag/100`:
- Stamina drain `0.32×(1−0.35k)`/s.
- Regen `0.16×(1+0.6k)`/s.
- Spur speed +1.5k m/s.

**Aşık (`asik_game.gd`):**
- Mat 880, ring radius 250, bone r21, shooter r26, centre (960,470). Win at 4.
- 8 bones at r 70–170, angle i/8 ± 0.15.
- Shooter starts at centre+(±120, 390).
- Aim range −π+0.35 to −0.35, turn rate 1.6 rad/s.
- Hold E: `power = 0.5−0.5cos(t×3.4)`. Velocity `420 + power×1200` px/s.
- Friction `sp −= (170 + 1.4 sp)·dt`, stops below 6 px/s.
- Collisions: equal mass, impulse factor 0.92.
- Felt edge at half−16 stops bodies dead.
- Bones past the ring at rest go to the shooter. A scoring shot earns another turn.
- Game ends at 4 or when no bones remain. A tie counts as not won.
- Kadfi skill 0.55 × diff(0.75,1,1.2). AI aim error ±0.12×(1−skill). Power `(dist+left+90)/1150 ± 0.06×(1−skill)`, clamped 0.35–1. Thinks 0.9 s + 0.5 s.
- Result: `p1_asik_ok`, `kadfi_dost`, `p1_asik_kazandi` if won, `asik_kesesi`.

**Chase core (`chase_level.gd`, `kacis.gd`):**
- Fixed camera 1920×1080. `HORSE_X` 560. Field y 700–1060 (360 px deep), middle 880.
- `base_speed` 15 m/s, `spur_speed` 23 m/s, `px_per_m` 60 (scroll only). Obstacles move at 900 px/s at base.
- Spawn x=2150: 1.77 s lead at base, 1.15 s at spur, visible about 1.51 s at base.
- Steering: `FREE_VMAX` 470 px/s, accel 2300, brake 3200.
- Depth scale `1+(y−880)×0.0004`.
- Spur needs stamina>0.05; speed lerp 3/s up, 2/s down.
- Jump 0.75 s, arc 95 px. Duck is held.
- `max_hits = max(2, 3 + diff(2,0,−1)) + goru_parca + chase_assist`. `kadfi_rehin` makes the base 4.
- Hit: `speed×0.72`, invulnerable 2 s. Reaching max reloads at section start.
- `chase_cp` is the section index. Hits reset on reload.
- `chase_assist` a=0–2: `ride_half=20−3a`, spawn interval +25%·a, double spawn chance ×(1−0.35a), volley warning +30%·a, strike telegraph +30%·a, strike gap +45%·a.

**Sections (in order, conditional):**

| Id | Length m | At 15 m/s | Max riders | Volley s (×0.75 if `tokar_kizgin`) | Kinds | Fog | Notes |
|---|---|---|---|---|---|---|---|
| K1 | 600 | 40 s | 2; `kadfi_bagli` 4; `arsak_dogru` −1 (min 1) | 0; `kadfi_bagli` 6 | barrier, cart, rock | 0.05 | Fork at end. If `tokar_kizgin`, Tokar rider spawns at x=−420. |
| K2 | 1300 | 87 s | 4 | 7 | drift, branch, rock, balbal | 0.25 | Route set on entry (y≥880 river). Wing shadow at +9 s. |
| K3a (river) | 700 | 47 s | 4 | 9 | ice, ice, drift | 0.15 | About 3 s in, all riders fall. Bolts on bare ground open ice holes. |
| K3b (north) | 700 | 47 s | 5 | 5 | barrier, branch, rock | 0.18 | Debtor omen at +6 s in either route. |
| BOSS | 90 | 6 s, then capped | 0 | 0 | none | 0.45 | Only if not (`erlik_eli` or `erlik_pazarlik`). Distance capped at end−0.5 until the bird dies. |
| K4 | 80 | 5 s, then halt 2 s | 0 | 0 | none | 0 | Only `kadfi_rehin`. Cinematic. |
| K5 | 1000 | nominal 67 s | 2 | 0 | drift, rock | 0 | Ends when `p1_tipi_safak` reaches `p1_chase_end`. |

- Total without BOSS and K4: 3600 m, 240 s.
- **K5 real duration is about 20–26 s (computed).** It is dialogue-driven: TR voice 4.99+4.05+2.12+4.68+5.25 s, plus 0.3 s gaps, plus about 3.6 s of slow motion. The doc's 60–90 s does not happen.

**Fork (`kacis.gd:162–232`):**
- Burning cart at y=880 arrives at K1's end, spawned at distance ≥573 m. It blocks y 828–932.
- No other spawns during the last 60 m.
- Decor: gate (2150,660), torches (2030,690), (2290,690), ice ellipse 260×34 at (2250,1050), reeds (2350,1066).

**Obstacles (half depth px):**
- Jumpable: drift 26, barrier 22, fire_bush 30, fire_patch 26.
- Duck: branch 30.
- Ride around only: ice 30, rock 32, cart 32, balbal 24, tree 22.
- Harmless until burning: bush 28, reeds 22, decor.
- Hit test: `|dx|<56` and `|dy|<half+ride_half`, unless cleared by air or duck.
- `leaves_gap` guarantees a free line of at least 64 px among obstacles within 330 px in x.

**Spawn timers:**
- Obstacle: first 1.5 s, then `rand(1.5,2.5)×(1+0.25a)×0.85`, 30% chance of a double.
- Rider: first 4 s, then `rand(3.5,6)` if under the limit. At section start with no riders, up to 2 burst in at x=−160, −330.
- Surge: first 5 s, then `rand(5,8)`.
- Volley: first 6 s, then `rand(vol×0.8, vol×1.2)`.

**Riders:**
- Follow target x: `560 − gap + (15−speed)×16 + hits×28`, capped at 230. `gap` is rand 350–520. X lerp 0.9/s.
- Lateral offset rand ±170, re-rolled with p=0.003 per frame. Y lerp 1.3/s.
- Surge: `x += (300 + (15−speed)×30)·dt`, y target moves 55 px/s toward Motun, y lerp 2.4/s.
- Surge hit: `|dx|<70` and `|dy|<26+ride_half`. Past x=790 it returns to follow.

**Volley:** band half 46, 440 px long at x=620, 30% on Motun's y, warning 0.8+0.4+0.4 s × (1+0.3a). Hits within 52 px.

**Mirror (F):**
- Cooldown 0.45 s. Raise 0.1 s, then effect. Lowers 0.24 s later.
- Target: boss if targetable, else nearest rider within 1100 px with surgers first. Skips shied riders and riders at x<−60.
- Rider effect: `_shy`, rears, x−560 over 1.5 s, recovers after 3.5 s with gap 360–520. 30% chance the rider is thrown and removed.
- Boss effect: 1 damage, or a parry during the 0.46 s dive window gives 4 damage.
- First surge teaches the mirror at time scale 0.15, up to 12 s.

**Kara Kuş (`chase_boss.gd`):**
- HP `round(40×diff(0.6,1,1.35))`: story 24, normal 40, hard 54.
- Home (1390,330), hover ±110, ±45. Sprite width 640.
- Entry: from (1480,520) to home in 1.4 s, held until `begin()`, first attack 1.6 s later.
- Phase 2 at HP ≤50%, phase 3 at ≤25%.
- Attack gap `rand(2.4,3.2) − 0.35(phase−1)`.
- Selection: phase≥2 and r<0.4 gives rain(2); else r<0.68 gives dive; else rain(1). Phase 3 has a 50% chance of an extra dive after any attack.
- Dive:
  - 65% on current y.
  - Rise 0.6 s, band half 58 marked `1.25−0.15(phase−1)` s, swoop 0.46 s.
  - Hit within 64 px.
  - Exit 0.5 s, then re-entry 1.2 s (untargetable).
- Parry: thrown back 0.7 s, stunned 0.9 s.
- Rain(1): band half 62, 55% on current y.
- Rain(2): whole field except a gap of half 72. Warning 1.35 s, hit within band+6.
- Boss hits call `chase.hit()` directly, ignoring invulnerability.
- Flash untargetable in `enter` and `return` states.
- Death: `_dawn` rises with damage up to 0.2. Tengri's bolt, `p1_karakus`, black storm lifts, `p1_karakus_son`.
- Retry uses the short version without dialogue (`p1_karakus_seen`).

**Storm (`kacis.gd:260–338`, `chase_storm.gd`):**

| Section | Cover | Intensity | Wall | Heavy snow | Strikes | Flora |
|---|---|---|---|---|---|---|
| K1 | 1 | 0.15→0.25 | 0.45 | 1 | no | none |
| K2 | 1→0.3 | 0.3→0.62 | 0.55→1 | 1→0 | after 10% | bush, bush, tree |
| K3a | 0.3→0.12 | 0.66→0.92 | 1 | 0 | yes | reeds, reeds, bush (ice) |
| K3b | 0.3→0.12 | 0.66→0.92 | 1 | 0 | yes | bush, tree, tree |
| BOSS | 1 (0 after kill) | 1 (0.55) | 1 | 0.4 (0) | no, red flashes | none |
| K4 | 0.05 | 0.3 | 0.8 | 0 | no | none |
| K5 | 0.04 | 0.6→0.4 | 0.9 | 0 | yes until sealed | bush, bush, tree |

- Telegraph `0.8×(1+0.3a)×diff(1.2,1,0.9)`. First strike after 4 s.
- Strike gap `lerp(10,3.4,k)×rand(0.8,1.25)×(1+0.45a)×diff(1.35,1,0.85)`.
- No bolt within 330 px of Motun in x.
- Hunted, already struck and 25% chance: a mark at ±150–250 px off his line, x 1300–1800, which waits for a rider.
- Otherwise tall flora at 90%, trees weighted ×3.
- Burning: bush and reeds become `fire_bush`, tree stays solid, bare ground gets `fire_patch` for 1.8 s.
- Spook: riders within (260,130), max 2. Thrown within (100,60).
- Fire shy: (110,70), once per fire.

**End of act:**
- `Cine.play_song("sarki_ak_kulun")`, 188 s, 36 timed lines from 12.0 s to 181.0 s.
- Stills at 0 `p1_son_tepe` (snow), 64 `goru_1`, 118 `p1_son_dogu`, 150 `p1_son_tepe`.
- `ActEnd.run`: `goru_p1`, `goru_parca+1`, `p1_bitti`, summary card, title card "I. PERDE SONU" / "END OF ACT I", save snapshot, then Act II.

---

## 5. Missing content and branch resolution

**Described in the doc but missing or different in code/data:**
- `p1_bark_gece` is never a bark on the safe path. It only runs when talking to Arslan at night, and its first line is spoken by `nobetci`.
- Thrown-stone distraction is not implemented. The whistle is the only `make_noise` source.
- Kam Ece's night conversation is absent (`talkable:false`, no dialogue).
- "Önce bıçak." does not exist; the prompt is simply hidden. The pen "çit kapısı" is only a rect trigger, and the saddle interact uses `ip_bilekte || p1_ip_asildi` rather than the doc's knife condition.
- The doc's horse-calm ring/breath game was replaced by Kulak. Salt does not skip a round; it softens timing and sets fear 0.66.
- `kadfi_ipucu` is wrong in effect: it **adds** an extra patrol guard (the static guard stays), and only after the night scene is rebuilt.
- Doc says the day border blocks kurgan, the far river and the north exit. Code only blocks map-edge strips, so kurgan and kuzey_cikis are walkable by day.
- G10 is a chained cutscene, not a meydan walk trigger.
- Tokar stands at the otag by day, without two guards at meydan.
- Visuals with no implementation:
  - Rising feather (and `kartal_tuyu` stays in inventory).
  - Wrist rope removal.
  - Kadfi crouching, on the saddle, or under the tree (only the tree appears).
  - Ayaz's chains.
  - Top-down mounted movement.
  - Tokar mounting at alarm.
  - K1 barrels and torches, and `alarm_horn` during K1.
  - K3a crack spread, K3b outpost and "2 more riders" (the cap is just 5).
  - Tokar's volley bark.
  - K5 "only Tokar remains" and Motun grabbing the arrow.
  - The K6 hill is a single still.
- Volley warning is 1.6 s, not 1 s. `tokar_kizgin` raises volley rate 33%, not 25%. Dawn is 50 s, not 60 s.
- No "kutlu ağıl önü" checkpoint exists. Checkpoints are: yurt entries, kamp entry, after yabgu/Tokar, after Erlik, after Tengri (spawn `start`, far west), and per chase section.
- Stealth music `gerilim` is not dynamic. It plays only in the `vur` ending of Erlik's scene and in p1_yabgu.
- Stale docs:
  - Bible says three-lane chase.
  - Bible says `ant_kadfi` is at the pen.
  - §7 Erlik EN VO is 1403; measured 2081.
- `baba_ofke` and `baba_umut` are never read.
- Expected range "Kut 0–6, korku 0–5" understates actual extremes: Act 1 can give kut +10 and korku +7.

**Do not replicate these bugs (from reading, not tested):**
- After being caught, one-shot interacts reset. `p1_kurgan` and `p1_depo` conditions do not check the item, so they can replay and allow both rope flags.
- A Kadfi follower is not rebuilt after reload.
- Guards keep sensing during dialogues.
- `p1_tipi_1` overwrites the K1 objective within seconds.

**Branch resolution.** The act has one ending scene with a variable state. Caught and fallen both retry.

| Decision | Outcome |
|---|---|
| Kadfi promise | `kadfi_ayat_soz` swaps lines in p1_erlik and p1_kadfi_gece, plus an izler entry. |
| Zerin | `zerin_yalan`; or truth kut+1; or silence. |
| Arslan | `ant_arslan`; or `arslan_antsiz` kut+1; "gel" sets `arslan_gel` and loops. |
| Yabgu | Nothing; or `yabgu_nobet` (+1 pen guard); or `tokar_kizgin` korku+1. |
| Kam Ece | `kartal_tuyu`, `kam_uyari` (extra Erlik choice and lines). |
| Meydan | Kaldır kut+1; yakala korku+1 + `tokar_kizgin`; eğil nothing. |
| Erlik: Defol | `erlik_red`, kut+2, bird yes. |
| Erlik: İlk yol (needs `kam_uyari`) | `erlik_red`, kut+3, bird yes. |
| Erlik: pazarlık + ant | `ant_erlik`, `erlik_pazarlik`, korku+1, `erlik_kulu`, no bird, omen, extra kurgan line. |
| Erlik: pazarlık + vazgeç | `erlik_red`, kut+1, bird yes. |
| Erlik: kabul + indir | `erlik_vazgec`, kut+1, korku+1, knife removed, bird yes with its own line. |
| Erlik: kabul + vur | `ant_erlik`, `erlik_eli`, korku+3, keeps `kara_bicak`, `tahta_at`, smoke, no bird, omen. Skips Arşak and kurgan, silent sky, rope choice at stones, wolf below, Tengri's stained line. |
| Arşak | All paths set `arsak_gordu`; truth adds `arsak_dogru`, kut+1, one K1 rider fewer. |
| Rope | `ip_yabguya`: must hang it, kut+2, Kadfi line. `ip_bilekte`: no hang step. |
| Kadfi: ant | `ant_kadfi`, kut+1, `kadfi_ipucu`. |
| Kadfi: bağla | `kadfi_bagli`, korku+1, K1 4 riders and volleys. |
| Kadfi: rehin | `kadfi_rehin`, korku+2, K4, +1 max hit, pen guards ×0.5. |
| Fork | `rota_nehir` or `rota_kuzey` from y at K2 start. |
| Ayaz | `ant_ayaz` (+10 bond), or `ayaz_sozsuz`. |

- Summary stanza uses first-match slots from `destan.json` key "1". `izler.json` key "1" gives oath and choice traces. The end card shows the last stanza.
- Consumers in P2/P3 JSON: `erlik_*`, `ayaz_ad`, `ayaz_sozsuz`, `p1_karakus`, `ant_kadfi`, `ant_erlik`, `ant_ayaz`, `tuz`. Others have no consumers yet.

**Supporting data:**
- `quests.json` Act 1:
  - Main: "Kampta son gün", "Kendi yolun", "Şafağa yetiş".
  - Side: "Kadfi'yle aşık", "Kam Ece'nin çadırı".
  - Discovery: "Kışlağın eski taşları".
- `skills.json` relevant: `sinsi`, `kemik_islik`, `mahmuz`, `sicrayis`, `egilme`, `tunc_ayna`.
- Stones' Motun lines (`taslar.json`):
  - "Eski ellerin avı. Benden önce de birileri buradan kaçmak istemiş."
  - "Taş adam bana bakıyor. Belki o da bir rehineydi."
  - "Geyikler göğe uçuyor. Annem derdi: ölenlerin ruhu geyiğe biner."
- Achievements usable in Act 1: `ilk_ant`, `erlik_red`, `elin_hayir`, `karakus`, `hun_agabey`, `rehine_degil`.
- `map.json`: `yueci` at [430,512], `kacis` at [700,515].
- `i18n.json` keys:
  - Stealth and prompts: `CAUGHT*`, `ZONE_*`, `HINT_WHISTLE`, `PROMPT_{TALK,SEARCH,HANG,FEED,USE,LOOK}`.
  - Mini-games: `KULAK_*`, `TUT_KULAK*`, `CALM_DONE`, `ASIK_*`.
  - Chase and boss: `KACIS_HINT`, `TUT_{MIRROR,PARRY,STORM,FORK}*`, `BOSS_KARAKUS*`.
  - End of act: `ACT_END`.

---

## 6. TR and EN coverage

- **All 274 speech lines have both `t` and `en`. Lines missing EN: 0. Lines missing TR: 0.**
- All 41 choice options, 18 objectives, 5 ant commands and the title also have both.
- All 274 lines also have `x` and `xl`.
- Existing voice files for Act 1 lines:

| Language | Files of 274 | Size | Notes |
|---|---|---|---|
| tr | 262 | 18.4 MB | |
| kadim | 262 | 20.7 MB | |
| en | 40 | 5.5 MB | Only `anlatici`, `umay`, `tengri`, `erlik` |

- TR and kadim both lack the same 12 lines: `p1_asik_teklif` 8, and one each in `p1_arsak_agil`, `p1_depo`, `p1_kadfi_gece`, `p1_bark_gece`.