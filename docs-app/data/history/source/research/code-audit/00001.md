# Tanhu engineering audit (as of 2026-10-31 19:17 local)

Base path for all pointers: `/Users/mucahidyazar/Code/tests/tanhu-programatic-test/src`

## 0. Snapshot and method

**Concurrent edits happened during this audit.**
- New files: `character/rig.js` (422 lines), `character/mete.js` (246), `character/folk.js` (608).
- `character/ghost.js` gained `addSkinnedGhost`.
- `core/paint-material.js` gained `bindSpace`.
- `character/head.js` gained `headGeometry(nu,nv)` and `paintFace({size})`.
- I read all of these after they changed, except `mete.js`, whose last edit (19:08) I only partly re-read. Line numbers can drift if edits continue.
- `rig.js`, `mete.js` and `folk.js` are not imported by `main.js`, `game.js`, `world.js` or `stage.js`. Gameplay still runs `Hero` (`game.js:27,411,752`, `main.js:13`).

**How I measured.**
- No project file was written. Vite's cache lived in the scratchpad, and the servers and tab are closed.
- GPU was an Apple M1 Pro. Viewport 1600x900 gave a 2149x1209 buffer (pixel ratio 1.344).
- Load average was about 17-20 from other work, so ms values are indicative only. Draw and triangle counts are exact.
- The pane was hidden, so frames ran through `__tanhu.step`.

**Evidence shots** (under `/Users/mucahidyazar/.claude/projects/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/tool-results/`; shots captured through my overlay are horizontally squeezed):
- Bard close-up: `mcp-Claude_Browser-blob-1793462763754-ahfflo.jpg`
- Flat sky: `mcp-Claude_Browser-blob-1793462786039-7tysri.jpg`
- Wide shot without fog override: `mcp-Claude_Browser-blob-1793462794497-cl5nu1.jpg`
- Final crane frame with fog override: `mcp-Claude_Browser-blob-1793462808674-5nmza6.jpg`
- Looking south, fake sea: `mcp-Claude_Browser-blob-1793463390960-ergn1b.jpg`

## a) Child replaces the adult Hero

**Source NPC.** `npc.js:177-187`:
- Colours: skin `#dcb08a`, top `#d9cba8`, robe `#b08a58`, sash `#7a3b26`, boot `#6a4a34`, trim `#7a3b26`, legs `#4a3a2a`, hair `#2a1d16`.
- `hairStyle:'short'`, `seed:9`, `headScale:1.4`, group scale `0.66`.
- Position (-1.98,-0.92), yaw `atan2(1.98,0.92)`=1.136.
- It is a merged static mesh with no joints, so it cannot walk.

**The minimal-duplication route now exists, unwired.**
- `Rig` (`rig.js:50`) holds bones and pose code. `update(dt,speed,jump,ride)` has the same signature as `Hero.update`.
- It adds `sitK/sitWant`, `crouchK`, `gesture`, `strum`, `lookAtPoint`, `stepped`.
- `CHILD` spec (`rig.js:15-22`): K=0.64, `headScale:1.02`, `walkFull:2.6`, `sprintLo/Hi:3.8/5.9`, `strideWalk/Run:1.08/1.6`.
- `Folk extends Rig` (`folk.js:456`) is one skinned draw plus head plus hair. `CHILD_LOOK` is at `folk.js:601-608`.

**Dependencies on Hero dimensions, and what each needs:**

| Dependency | Site | Change |
|---|---|---|
| Root scale | `game.js:27,411`; `stage.js:144` sets 1 | Move to the actor as `actor.rootScale`. CHILD head top is 1.185 m at root 1, 1.35 m at 1.14. Prefer 1.14 for readability at 33 m camera distance. |
| Seat height | `game.js:752` `0.92*hero.opts.height*HERO_SCALE` | `Folk` has no `.opts`, so this crashes. Use `hero.seatHeight*hero.root.scale.y`. Fix `rig.js:411`, which ignores `d.height` applied at `folk.js:467`. |
| Speeds | `game.js:12-15` JOG 4.4, SPRINT 7.6 | Child at 4.4 gives `sprint`≈0.2 from `smooth(3.8,5.9,4.4)`, so a jog leans into a run. Use actor fields, about JOG 3.2, SPRINT 5.6. |
| Jump | `game.js:21-23`, peak 1.05 m; `:682` normalises by JUMP_V | Fence top `-0.95` (`interior.js:678`) needs v≥4.9. Stable rail `-1.1` (`camp.js:534-535`) needs v≥5.34 (via `game.js:510`). About 5.0 clears fences only, so lower the rail or keep 5.4. |
| `WALK_R` | `game.js:25,159,175`, nav built once at `:134` | Safe to keep at 0.36. |
| Ride pose | `rig.js:234-239` thigh z 0.66 | **Clips.** With CHILD at 1.14, the ankle lands at x≈0.25 where horse barrel half-width is about 0.34, roughly 9 cm inside (computed, not rendered). Add spec-level ride angles, starting near thigh z≈1.1, x≈-0.55, shin hanging vertical. |
| Mount arc | `game.js:388,404,785` | Durations and the 0.42 arc still work. Check the arc visually. |
| Camera target | `game.js:437` `pos.y+.85`, `:460-462` `pos.y+1`, `:436-438`, `:89-90` dist 33 | Scale the room target by actor height. Default dist about 26. |
| Door height | `DOOR_H=2.86` (`interior.js:21`), `camp.js:190-193` | No dependency. There is no head-clearance logic. |
| Ghost | `ghost.js:13,58` lift 0.45, order contract `ghost.js:2`, `world.js:139` | Works via `d.ghost`. 0.45 is a third of child height, so consider 0.3 (uniform). |
| Creator | `main.js:78-81,121-127`, `stage.js:168`, `hud.js:19`, `main.js:113,143` | `Folk` has no `applyOptions`. Remove creator, C key and button from Act 1 free roam, or bind the creator to a separate actor. |

**Remove the seated child.** Skip `npc.js:177-187`. Its obstacle (`npc.js:138`) also feeds the contact shadow (`world.js:125`), grass block (`world.js:203`) and nav (`game.js:155`), so drop the whole block rather than hiding the mesh. Spawn at the NPC spot instead of `game.js:92,94`, with `sitWant=1`, then release.

**Remaining duplication to delete:**
- Rig logic: `hero.js:217-242` vs `rig.js:84-109`; `hero.js:822-923` vs `rig.js:116-301`; `hero.js:927-950` vs `rig.js:357-391`.
- Geometry helpers: `folk.js:51-57` vs `hero.js:121-126`; `folk.js:59-77` vs `hero.js:128-149`; `folk.js:145-151` vs `hero.js:334-340`.
- Next step: `Hero extends Rig` with `armMode='bow'`. Keep the tasset lines `hero.js:921-922` in `Hero`.

**Performance bonus.** Hero measured about 68 draws and 59k triangles plus ghosts. `Folk` is 3 draws plus ghosts. `Folk.mesh.frustumCulled=false` (`folk.js:527`) needs a bounding sphere before crowds.

## b) Cinematic system

**Sky and horizon**
- There is no sky dome. Background is a flat colour equal to fog (`world.js:75,254`); `#708eba` at moodT 0.3 (measured). Pixels above the ridge vary only by vignette and grain.
- `cloudReal` (`atlas.js:274-277`) exists only after the atlas is built and shows only in map real mode.
- The gameplay camera has never shown sky. Pitch 28° and vFOV 38° put the top ray 9° below the horizon (`game.js:19,88,452`).

**Extents**

| Element | X | Z | Notes |
|---|---|---|---|
| Near mesh | ±70 | -82..58 | `terrain.js:9` |
| Far mesh | ±1500 | -1690..110 | `terrain.js:393,397` |
| Lake plane | ±1200 | -1300..500 | y=-66, `valley.js:11,69` |
| Grass | ±50 | -56..42 | `grass.js:187` |
| Flowers | ±44 | -46..34 | `grass.js:256,265` |
| Near trees | ±62 | -80..48 | `flora.js:172` |
| Far trees | - | ≥-860, ≤20 | `flora.js:188`; none south of z=48 |
| South skirt | ±1700 | 56..1956 | Atlas real mode only, `atlas.js:352-384` |

- **Looking south shows a fake sea, then flat colour** (verified). Keep yaw in the north hemisphere, or enable lake `uClip` (`valley.js:39-46`) and build a skirt.
- South slope falls to about -94 m at z=110, so it hides the mesh edge from a raised camera.

**Far plane, near plane, fog, shadows**
- Far 4200 (`game.js:88`) is enough. Sky dome radius must stay below it, or use a camera-centred dome with `depthWrite:false`.
- Near 2 blocks close-ups. Near 0.2 worked in test. Depth precision at 1 km: 0.3 m at near 0.2, 0.06 m at near 1, 0.03 m at near 2 (24-bit, `WebGLTextures.js:281`). Animate `near=clamp(dist*0.1,0.15,2)`.
- Fog 77..1355 washes out the ridge (`terrain.js:38-39`). Override [140,3000] gave a clean ridge (verified).
- `applyMood` overwrites fog during mood animation (`world.js:252-253`), and the lake has its own `uFogR` (`valley.js:20,61-62`). Add a fog override layer applied at the end of `applyMood`.
- Shadows cover only ±46 m around the focus (`world.js:67,275-279`). Pass the camp as focus through `world.update`'s third argument.
- Point sizes have no clamp: motes (`ambient.js:42`), embers (`fire.js:165`, about 60 px at 3 m). Clamp them for close-ups.
- Flames are fixed planes (`fire.js:54-57,113-122`, `interior.js:451`) and go thin from the side (seen in the first test shot). Add yaw billboarding.
- Grass tufts read as large paper leaves in close-up (verified). Keep the camera at 1 m or higher, crop, or blur the bottom band.

**Culling.** No distance LOD exists. Tree LOD is fixed by world position (`flora.js:161-201`). Grass has 64 chunks and flowers 55, frustum-culled only.

| Shot | Calls | Triangles |
|---|---|---|
| Gameplay camera | 582 | 3.84M |
| Bard close-up | 330-419 | 2.76-2.90M |
| Wide (-60,30,190) | 686 | 4.85M |

Add distance culling of chunks for wide shots. Atlas already hides grass at `span>.6` (`atlas.js:819-821`).

**Verified framing**
- Close-up: pos (1.15,1.05,-0.25), look (3.12,1,-1.3), fov 32, near 0.2.
- Final: pos (-60,30,190), look (0,46,0), fov 38, near 1, fog [140,3000]. Camp at the bottom, ridge, top third sky.
- At 16:9 the right frustum edge bearing is about 48°, past the far mesh corner at about 40°. Either rotate the look north or extend `X` at `terrain.js:393`.
- The path back should follow the corridor at `layout.js:16`. I did not measure tree clearance along it.

**Post.** `main.js:246-248` overwrites exposure, tilt and focus every game frame. Profiles to reuse: close-up = `CREATOR_POST` (`main.js:25-30`: paint 1.5, wobble 1.2, tilt 0); wide = `POST_DEFAULTS` (`post.js:166-173`) with `tilt:[.5,.5,0]` (same as `atlas.js:1061`). Keyframe paint, wobble, tilt, exposure, vignette.

**Code changes**
- `placeCamera` (`game.js:447-454`) hard-codes +z offset and lookAt, with fov kick at `:491-497`. Use a separate cinematic camera so kick and `focus()` are untouched. Register it in `resize()` (`main.js:89-101`). Lock horizontal FOV for narrow screens.
- Add a branch in `tick` (`main.js:233-257`):
```js
} else if (state === 'cine') {
  cine.update(dt, time);
  game.placeActors(dt, time, false, 0); // same pattern as main.js:236
  world.update(dt, time, cine.shadowFocus);
  cine.applyPost(post.settings, world.mood);
  post.render(world.scene, cine.camera);
}
```
- `commitState` (`main.js:176-203`): `game.leave()`, `hud.show(false)`, reuse the fade via `goTo`. On exit call `game.snapCamera()`.
- Never add or remove lights at runtime. 85 programs depend on light count (measured).

**Bard and singing**
- Strum is an anonymous updater: `f.arm.rotation.x=-0.05+sin(t*7.5)*0.06*(0.6+0.4*sin(t*0.8))`, head roll `sin(t*1.4)*0.05` (`npc.js:219-228`). `folk` is local and `kopuz()` is private (`npc.js:120-130`).
- Bard is at (3.12,-1.3), yaw -1.097, scale 1.02, head world height about 0.95.
- Short term: expose `world.folk.bard={group,head,arm,lute,faceMat}` and multiply by a `perform.strum` value.
- Better: rebuild on `Folk` with `sitWant=1`, `strum=1`, `sitArms=armTargets(...)` (`rig.js:417-422`), `attach('handL',lute)` (`folk.js:568`).
- There is no jaw. The mouth is painted (`head.js:191-206`). Recommended: add a `mouth` parameter to `paintFace`, pre-bake 3 visemes at size 512, swap `faceMat.map`. Measured 2 ms JS per 1024 face. Keeping `map` non-null should avoid a recompile (not tested). A vertex jaw is weaker because hair, beard and hat are merged (`npc.js:100`).
- There is no audio in `src` (no `AudioContext`). Unlock on a gesture (`creator.js:123`). Drive the timeline from the audio clock, because `main.js:217` clamps dt to 0.05 and time drifts below 20 fps.

## c) Second world: winter camp

**Coupling**

| File | Hardcoded or module state | Parameterise |
|---|---|---|
| `world.js` | `:17-28` MOODS, `:63` sunDir, `:65-70` shadow, `:74-75` fog, `:97` smoke at (0.1,1.9,0), `:106` assumes a stable exists (crash without), `:114-115` horses and stalls, `:120` motes, `:155` fire at origin, `:168` field bounds, `:242`, `:275` grid 92/4096 | Spec fields for all |
| `terrain.js` | `:8` LAKE_Y, `:9` NEAR, `:12` LAKE_LINE, `:29-57` valley and hilltop formulas, `:72-83` flatten, `:88,:91` cache init-once, `:121-129` PATHS at import, `:150,:322` fire at origin, `:165,:168` mask init-once, `:174` bounds, `:197-198,:213-214` palettes, `:262-263,:312` stroke palettes, `:393-397` far mesh | `Terrain` class. Keep exported `height()` etc. as dispatchers to an active instance (imported by `grass`, `flora`, `valley`, `camp`, `interior`, `game`, `atlas`, `world`). |
| `layout.js` | `:5` YURT_R, `:7-46` LAYOUT, `:49-54` obstacles | Becomes `spec.layout` |
| `camp.js` | `:103` yurtTex, `:18-101` palette, `:602` exactly 2 yurts, `:634-650` absolute props, `:677-678` rooms[0], rooms[1] | Props as data or function, per-yurt smoke, texture key by palette |
| `interior.js` | `:189-190` caches | Key by palette, reuses `world` otherwise |
| `flora.js` | `:9` palette baked in vertex colours, `:146-154` view corridor, `:166-188` ranges and clearing, `:193` forest field shared with `terrain.js:202`, `:280-289` scatter | Spec fields, snow via material hook |
| `grass.js` | `:135` chunk, `:178` palette, `:187,:193` bounds, `:233-235` flower palette, `:256,:265` | Spec, flowers optional |
| `valley.js` | `:8` third copy of lake line, `:11,:69` plane, `:35` `uShore[9]`, `:58` lake-specific glow, `:77-82` villages | Spec, `uIce`, one shared lake line |
| `ambient.js` | `:10-12,:34-35` bounds, pollen and firefly semantics | Add a snow variant |
| `fire.js` | No layout coupling. `:203` puffTex cache, `:40` shared uniforms | Reuse as is |
| `npc.js` | `:8` shared mats, `:159,:173,:185,:215` positions | Folk list in spec |
| `game.js` | `:92` start, `:143,:147` nav bounds and mask, `:164`, `:436-438` camera offset | `spec.nav`, `spec.camera`, `setWorld` |
| `atlas.js` | `:277,:348,:383` objects added to `world.scene`, `:525-531` labels, `:753-765`, CAMP | `setWorld`, per-world home |
| `main.js` | `:75` const world; closures at `:106,:130,:207,:237,:243` | Current-world reference |

**Shared uniforms.** `U` (`paint-material.js:5-13`) is written by `main.js:68-69,108,220`, `world.js:265`, `game.js:626`. Keep it global, reset on swap.

**Footgun.** `customProgramCacheKey` (`paint-material.js:138`) is only `paint|b/o/w|key`. A snow hook reusing `tree`, `rock`, `yurt` or the empty key can silently reuse the wrong GLSL. Winter hooks need new keys.

**Disposal.** No world disposal exists today; the only `dispose()` calls are hair and maps in `hero.js:732,780,787,797`.
- Detach first (not owned by World): `hero.root`, `game.marker`, `game.dust.group`, `atlas.pinReal`, `ringReal`, `skirt`, `cloudReal`.
- Traverse the scene: geometry, material, `InstancedMesh.dispose()`, `sun.dispose()` (frees the shadow map), and textures not tagged shared.
- Tag as shared: `U.uBrush`, `U.uCloud`, `yurtTex`, `wallTex`, `rugTex`, `puffTex`, `bodyMat`, `hairMat`, `horseMat`, `ghostMat`, folk caches (`folk.js:47-49`).
- Clear `updaters`, terrain `cache`, `mask`, `PATHS`.
- Listeners are never removed (no `removeEventListener` in `src`), so keep one `Game` and `Atlas` and add `setWorld`.
- Dispose before building to avoid a peak: about 480 MB VRAM estimated (textures 236 MB, shadow 67 MB, render targets 180 MB, computed not measured).
- Verify with `renderer.info.memory`. Baseline: 246 geometries, 32 textures, 85 programs, 614 scene objects.

**Build cost, six fresh loads** (ms). The `world.timings` label is the next step's name, an off-by-one at `world.js:52`.

| Actual work | Logged label | Min-max | Work |
|---|---|---|---|
| Terrain cache, mask, lights | Kayalar diziliyor | 114-282 | 78,961 `heightRaw`, about 135k `dirtRaw` |
| Rocks | Çamlar dikiliyor | 85-432 | 105,840 tris |
| Forest | Vadi çiziliyor | 62-1388 | 28,600 attempts, 7 pine geos, 148 instanced meshes (warm about 70) |
| Lake, village | Yurtlar kuruluyor | 1-9 | 364 samples |
| Camp, fire, smoke | Atlar ahıra bağlanıyor | 233-1590 | Canvases 4096x1792, 4096x1280, 1792²x2, 1536², 256x512x2 |
| Folk, horses, motes | Zemin boyanıyor | 68-1406 | 4 faces, 2 horses |
| Ground texture, near, far | Çimler ekiliyor | 371-13752 | 4096² canvas, 490k colour samples, 56k strokes, 66,521 far samples (paintGround warm about 519, far about 175, near about 20) |
| Fields, grass, flowers | Hazır | 115-2930 | 120,660 candidates to 83,202 tufts, 22,701 flowers (warm 160-180 and 26-39) |

Totals ranged 1.4 s to 17 s, usually 4.5-7 s. Other costs:
- Brush texture 247 ms, cloud 31 ms, `new Hero` 42-70 ms, nav 27 ms (warm).
- First frame 143 ms.
- Shader compile not isolated.
- `paintGround` is the highest-variance step, so cache it or move it to an `OffscreenCanvas` worker.

## d) i18n: every user-visible Turkish string

**Logic bound to strings.** `atlas.js:1018-1020` compares crumb text. Switch to ids before translating. Also `creator.js:119` and `hero.js:12` use the fallback name `Alp`.

**Things that must re-render on language change:** atlas item DOM and cached `it.bw/bh` (`atlas.js:495-506,944-947`), `buildLocals`, HUD hint, creator groups, and `document.documentElement.lang` (uppercase CSS at `style.css:97,145,157,264,265,333` depends on it for İ/I).

**Shell and loader**
- `index.html:2` `lang="tr"`; `:6` `Tanhu`
- `main.js:52` `TANHU`, `Kamp kuruluyor`; `:208` `Hazır`
- `world.js`: `:58` `Tepe yükseltiliyor`; `:78` `Kayalar diziliyor`; `:82` `Çamlar dikiliyor`; `:86` `Vadi çiziliyor`; `:93` `Yurtlar kuruluyor`; `:104` `Atlar ahıra bağlanıyor`; `:123` `Zemin boyanıyor`; `:131` `Çimler ekiliyor`; `:141` `Hazır`
- `relief-core.js`: `:357` `Kıyılar çiziliyor`; `:415` `Dağlar yükseliyor`; `:549` `Irmak ağları oluşuyor`, `Vadiler derinleşiyor`, `Yamaçlar işleniyor`; `:578` `Biyomlar ve gölgeler`; `:648` `Hazır`
- `atlas.js`: `:155` `Yeryüzü oluşuyor`; `:164` `Harita boyanıyor`; `:168` `Dağlar ve ormanlar`; `:179` `Yazılar`

**World and game**
- `world.js:114` `Doru`, `Doru'ya bin`; `:115` `Akbulut`, `Akbulut'a bin`
- `layout.js:14` `Ahır`
- `game.js:818` `Attan in`; `:811` joins name and zone with ` · `
- `yurt-designs.js`: `:691` `Bölmeli Yurt`; `:695` `Yatak Odası`; `:696` `Ambar`; `:697` `Mutfak`; `:698` `Ocak Odası`; `:703` `Bey Otağı`; `:709` `Silah Yurdu`; `:715` `Otacı Yurdu`; `:721` `Şölen Yurdu`

**`hud.js`**
- `:9` `TANHU`; `:13` `Can` (also aria); `:14` `Stamina` (also aria); `:18` `Harita`; `:19` `Karakter`; `:22` `Koş`; `:23` `Zıpla`
- `:72` `<b>Dokun</b> yürü · <b>Basılı tut</b> takip et · <b>Ata ya da yurda dokun</b> gir · <b>İki parmak</b> yakınlaştır`
- `:73` `<b>Sol tık</b> yürü · <b>WASD</b> yönlendir · <b>Shift</b> koş · <b>Boşluk</b> zıpla · <b>E</b> ata bin · <b>M</b> harita`
- `:91` `Altın saate dön`, `Alacakaranlığa geç`

**`creator.js`**
- `:6` names: `Alp`, `Börü`, `Mete`, `Kürşad`, `Bilge`, `Tonguç`, `Kaya`, `Aybars`, `Oğuz`, `Toygar`, `Temür`, `Atilla`, `Tarkan`, `Yağmur`, `Ertuğ`
- `:9` `Ten`: `Açık buğday`, `Buğday`, `Bozkır`, `Esmer`, `Yanık`
- `:10` `Saç`: `Topuz ve örgü`, `Uzun örgü`, `Kısa dağınık`
- `:11` `Saç rengi`: `Kuzgun`, `Kestane`, `Bakır`, `Kül`, `Ak`
- `:12` `Sakal`: `Keçi sakalı`, `Pala bıyık`, `Gür sakal`, `Sakalsız`
- `:13` `Göz`: `Kara`, `Ela`, `Yeşil`, `Gök`
- `:14` `Pelerin`: `Bordo`, `Gök kurt`, `Çam`, `Aşı boyası`, `Kömür`
- `:15` `Tunik`: `Keten`, `Ak keçe`, `Deve tüyü`, `Demir gri`
- `:16` `Zırh`: `Demir`, `Tunç`, `Kara`, `Gümüş`
- `:17` `Boy`, ` cm`; `:18` `Yapı`: `İnce`, `İri`, `Dengeli`
- `:85` `TANHU`; `:87` `Bozkırın yeni yiğidini oluştur`; `:89` aria `Karakter seçenekleri`; `:95` `Rastgele`; `:96` `Varsayılan`; `:104` `Döndürmek için sürükle`; `:107` `Adın`; `:110` `Başka ad`; `:113` `Kampa gir`

**`atlas.js` interface**
- `:23-29` `Devletler`, `Hakimiyetler`, `Kabileler`, `Klanlar`, `Şehirler`, `Mete'nin hayatı`, `Coğrafya`
- `:313` `Irmak`, `Göl`, `Deniz`, `Çöl ve bozkır`, `Dağ`
- `:320` `Çin Surları`, `Sınır`, `Ç'in hükümdarı, kuzey krallıklarının eski surlarını Meng Tian eliyle birleştirdi. Mete döneminde bozkırla Çin arasındaki sınırın simgesidir.`
- `:395` aria `Harita düzeyi`; `:405-406` `Dönem`; `:409,:421` `Katmanlar`; `:413` `Mete'nin hayatı`
- `:416` `Harita ${AREA_KM2} km². Coğrafya 1:130 sıkıştırılmıştır; sınırlar temsilîdir.`
- `:423` aria `Kuzeyi yukarı al`, `K`; `:425` `Konumum`; `:426` aria `Yakınlaştır`; `:427` aria `Uzaklaştır`; `:430` `Haritayı kapat`
- `:509` `Buradasın`, `Tanhu Kampı`
- `:526` `Ateş Başı`; `:527` `Göl`; `:528` `Ötüken eteği`; `:529` `Orhun'a inen vadi`; `:530` `Tanhu Kampı`
- `:676` aria `Kapat`; `:682` `Önceki olay`; `:683` `Sonraki olay`
- `:994` `Bozkır Dünyası`; `:1008` `Göl Vadisi`; `:1009` `Tanhu Kampı`; `:1035` ` m`, ` km`

**`geography.js`** (379 strings, 9,853 characters). Line, then fields separated by `|`.

Eras: 18 `MÖ 209 | Mete tahta çıkar`; 19 `MÖ 200 | Baideng Kuşatması`; 20 `MÖ 174 | Mete'nin son yılı`

Lakes: 41 `Baykal | Kuzey Denizi`; 42 `Aral`; 43 `Balkaş`; 44 `Issık Göl`; 45 `Lop Nur`; 46 `Köke Nur | Çinghay Gölü`; 47 `Hövsgöl`; 48 `Uvs`; 49 `Zaysan`; 50 `Hulun`

Ranges: 55 `Altay Dağları`; 56 `Tanrı Dağları`; 57 `Alatav`; 58 `Tarbagatay`; 59 `Pamir`; 60 `Hindukuş`; 61 `Karakurum`; 62 `Himalaya`; 63 `Kunlun Dağları`; 64 `Çilyan Dağları`; 65 `Altun Dağları`; 66 `Hangay`; 68 `Hentey`; 69 `Sayan Dağları`; 70 `Tannu`; 72 `Hingan Dağları`; 73 `Yin Dağları`; 74 `Helan`; 75 `Taihang`; 77 `Çinling`; 81 `Çangbay`; 86 `Hisar`; 90 `Tibet Yaylası`

Deserts: 95 `Gobi`; 96 `Alaşan`; 97 `Taklamakan`; 98 `Ordos`; 99 `Kızılkum`; 100 `Karakum`; 101 `Cungarya`; 102 `Betpak`; 103 `Thar`

Rivers: 136 `Sarı Irmak`; 137 `Yangzi`; 138 `Vey`; 139 `Han Irmağı`; 140 `Selenga`; 141 `Orhun`; 142 `Tula`; 143 `Kerulen`; 144 `Onon`; 145 `Amur`; 146 `Liao`; 147 `Yalu`; 148 `Yenisey`; 149 `İrtiş`; 150 `İli`; 151 `Seyhun | Siriderya`; 152 `Ceyhun | Amuderya`; 153 `Zerefşan`; 154 `Tarım`; 155 `Hey Irmağı`; 156 `İndus`; 157 `Ganj`; 158 `Tsangpo`

Seas: 165 `Sarı Deniz`; 166 `Doğu Denizi`; 167 `Wa Adaları | Yayoi`

Regions: 172 `Ötüken ve Orhun`; 173 `Gobi Bozkırı`; 174 `Yin Dağları ve Ordos`; 175 `Doğu Bozkırı`; 176 `Baykal Ormanları`; 177 `Yenisey ve Sayan`; 178 `Altay Eteği`; 179 `Hexi Koridoru`; 180 `Tarım Havzası`; 181 `Tanrı Dağları ve İli`; 182 `Soğd ve Baktriya`; 183 `Kangju Bozkırı`; 184 `Çin Ovası`; 185 `Güney Çin`; 186 `Tibet Yaylası`; 187 `Liao ve Kore`; 188 `Mançurya Ormanları`; 189 `Hint Ovası`

Polities (name | sub | kind, then note):
- 200 `Hun Tanhuluğu | Devlet`; 202 `Çin kaynaklarında Xiongnu. MÖ 215'te Ç'in generali Meng Tian onları Ordos'tan kuzeye sürdü. Doğuda Tunghu, batıda Yüeçi güçlüyken devlet Teoman'dan Mete'ye geçti.`
- 205 `Hun Tanhuluğu | Devlet`; 207 `Mete, Tunghu'yu yıktı, Yüeçi'yi batıya itti, Ordos'u geri aldı. Bozkırın ilk büyük imparatorluğu Çin'le denk bir güç hâline geldi.`
- 210 `Hun Hakimiyeti | Hakimiyet`; 212 `Kuzey kavimleri ve doğu kabileleri Tanhu'ya vergi verir. Kendi beyleri kalsa da savaşta Hun ordusuna asker yollarlar.`
- 215 `Hun Hakimiyeti | Hakimiyet`; 217 `MÖ 176'daki mektubunda Mete, Sağ Bilge Kral'ın Yüeçi'yi ezdiğini; Loulan, Vusun, Hucie ve çevredeki yirmi altı ülkenin Hunlara katıldığını yazar. Bozkırdan Tarım vahalarına uzanan bir hakimiyet doğmuştur.`
- 221 `Ç'in İmparatorluğu | Devlet`; 223 `Birinci İmparator MÖ 210'da öldü. Meng Tian'ın ölümüyle kuzey sınırı boşaldı, MÖ 209'da ayaklanmalar başladı. Bu kargaşa Mete'ye Ordos'u geri alma fırsatı verdi.`
- 226 `Han Hanedanı | Devlet`; 228 `Liu Bang MÖ 202'de hanedanı kurdu; başkent Çang'an'dır. Baideng yenilgisinden sonra Hunlara prenses, ipek ve tahıl göndermeyi kabul etti. Kuzey sınırı, Ordos'un güneyine çekildi.`
- 232 `Yüeçi | Devlet`; 234 `Hexi koridorunun efendisi. Teoman oğlu Mete'yi burada rehin bıraktı, sonra Yüeçilere saldırdı. Mete en hızlı atlarından birini çalıp kaçtı; yıllar sonra bu toprakları fethetti.`
- 237 `Yüeçi (göçte) | Kabile`; 238 `MÖ 176 yenilgisinden sonra Yüeçilerin büyük bölümü batıya, İli vadisine doğru göçmeye başladı. Bu göç Orta Asya'nın dengesini değiştirecektir.`
- 241 `Vusun | Kabile`; 242 `Çilyan ile Dunhuang arasında anılan göçebe halk. MÖ 176'dan önce Hun egemenliğine girdi; beyleri Hun sarayında yetişti. Daha sonra İli'ye yerleşecektir.`
- 245 `Hucie | Kabile`; 246 `Altay eteklerinin halkı. MÖ 176'da Hun egemenliğine girenler arasında adı geçer.`
- 249 `Sakalar | Kabile`; 250 `İli ve Issık Göl çevresinin atlı göçebeleri. Yüeçi göçü onları güneye, Baktriya ve Hindistan yönüne itecektir.`
- 253 `Çiang Kabileleri | Kabile`; 254 `Tibet Yaylası'nın kuzeydoğusundaki çoban kabileler. Tek bir devletleri yoktur; Hunlarla Çin arasında kimi zaman müttefik, kimi zaman hedef olurlar.`
- 257 `Batı Ülkeleri | Site devletleri`; 258 `Tarım vahalarında yaklaşık otuz altı küçük krallık. Ticaret ve sulu tarımla yaşarlar. MÖ 176'dan sonra Hunlar buralardan vergi toplar.`
- 261 `Kangju | Devlet`; 262 `Seyhun boylarının göçebe krallığı. Çin kaynaklarında bir sonraki yüzyılda ayrıntılı anlatılır.`
- 265 `Davan | Fergana | Devlet`; 267 `Fergana vadisinin şehirli krallığı. "Kan terleyen" atlarıyla ünlüdür.`
- 270 `Greko-Baktriya | Devlet`; 272 `Büyük İskender'in mirasından doğan Yunan krallığı. Euthydemos ve oğlu Demetrios döneminde Orta Asya'nın en zengin ülkelerindendir.`
- 275 `Part Krallığı | Devlet`; 277 `İran yaylasının kuzeydoğusunda yükselen krallık. Harita burada biter; ülkenin büyük bölümü batıdadır.`
- 280 `Yancai | Aorslar | Kabile`; 281 `Aral'ın kuzeyindeki Sarmat göçebeleri.`
- 285 `Tunghu | Devlet`; 287 `Doğunun güçlü kabile birliği. Mete'den önce en değerli atını, sonra bir eşini istediler. Üçüncü olarak toprak isteyince Mete ordusunu topladı ve onları yok etti.`
- 290 `Vuhuan | Kabile`; 291 `Tunghu'nun yıkılışından sonra Vuhuan Dağı'na sığınan kol. Hunlara at, sığır ve koyun derisi vergisi öder.`
- 294 `Sienpi | Kabile`; 295 `Tunghu'dan kurtulup Sienpi Dağı'na çekilen kol. Yüzyıllar sonra Hunların bozkırdaki yerini alacaktır.`
- 298 `Puyo | Devlet`; 299 `Sungari ovasının tarım ve at yetiştiriciliğiyle yaşayan halkı.`
- 302 `Yilou | Kabile`; 303 `Mançurya ormanlarının avcı halkı.`
- 306 `Koçoson | Devlet`; 308 `Kore yarımadasının kuzeyindeki eski krallık.`
- 311 `Viman Çoson | Devlet`; 313 `MÖ 194 dolayında Yan'dan gelen Viman, Koçoson tahtını ele geçirdi.`
- 316 `Koçoson | Devlet`; 318 `Kore yarımadasının kuzeyindeki eski krallık.`
- 321 `Cin | Samhan | Devlet`; 322 `Yarımadanın güneyindeki küçük beylikler topluluğu.`
- 326 `Nanyue | Devlet`; 328 `Ç'in generali Zhao Tuo'nun MÖ 204 dolayında güneyde kurduğu krallık.`
- 331 `Dian | Kabile`; 332 `Yünnan'ın göl çevresindeki bronz ustası krallık.`
- 335 `Maurya İmparatorluğu | Devlet`; 337 `Aşoka'nın mirası; bu yıllarda zayıflamaktadır. MÖ 185'te son hükümdarı devrilecektir.`
- 340 `Şunga Krallığı | Devlet`; 342 `MÖ 185'te Mauryaların yerini alan hanedan.`
- 346 `Dingling | Kabile`; 347 `Baykal ve Selenga ormanlarının halkı. Çin kaynaklarındaki adları Ting-ling; birçok araştırmacı onları sonraki Türk boylarının atalarından sayar. Mete'nin kuzey seferinde Hunlara bağlandılar.`
- 350 `Gekun | Kırgız ataları | Kabile`; 351 `Yukarı Yenisey'in halkı; Kien-kun adıyla da geçer ve Kırgızların atası sayılır. Mete'nin kuzey seferinde boyun eğdi.`
- 354 `Hunyu | Kabile`; 355 `Mete'nin kuzeyde boyun eğdirdiği beş halktan biri. Yeri kesin bilinmiyor.`
- 358 `Çüşe | Kabile`; 359 `Mete'nin kuzeyde boyun eğdirdiği beş halktan biri. Yeri kesin bilinmiyor.`
- 362 `Sinli | Kabile`; 363 `Mete'nin kuzeyde boyun eğdirdiği beş halktan biri. Yeri kesin bilinmiyor.`
- 367 `Loufan | Kabile`; 368 `Ordos'un kuzeydoğusundaki kabile. Mete, Tunghu'dan sonra Loufan'ı topraklarına kattı.`
- 371 `Baiyang | Kabile`; 372 `Ordos'taki "Ak Koyun" kabilesi. Mete'nin güney seferiyle Hun yönetimine girdi.`

Clans and offices:
- 378 `Sol Bilge Kral | Doğu kanadı | Hakimiyet | Tanhu'dan sonra en yüksek makam, genellikle veliaht. Kanadı Shanggu'nun kuzeyinden doğuya, Vuhuan ve Kore sınırına uzanır.`
- 379 `Sağ Bilge Kral | Batı kanadı | Hakimiyet | Hun devletinin batı yarısını yönetir. MÖ 176'daki büyük batı seferini bu kral komuta etti.`
- 380 `Tanhu Ordusu | Merkez | Hakimiyet | Tanhu'nun doğrudan yönettiği merkez yurt. Kaynaklar sarayın Dai ve Yunzhong'un tam kuzeyinde olduğunu söyler.`
- 381 `Luandi | Tanhu soyu | Klan | Çin kaynaklarında Luandi (Xulianti). Teoman ve Mete bu soydandır; tanhular yalnız bu klandan çıkar.`
- 382 `Huyan | Klan | En soylu dört klandan biri. Kaynaklarda sol kanatla anılır.`
- 383 `Lan | Klan | Soylu klanlardan. Kaynaklarda sağ kanatla anılır; tanhular eşlerini bu aileden de alır.`
- 384 `Xubu | Klan | Soylu klanlardan. Kaynaklarda sağ kanatla anılır, adalet işlerinde görev alır.`
- 385 `Qiulin | Klan | Sonraki kaynaklarda dört soylu aile arasında sayılır.`

Places:
- 390 `Lung-çeng | Ejder Şehri | Kutsal yer | Her yılın beşinci ayında Hun beylerinin toplandığı, atalara ve gök tanrıya kurban sunulan yer. Tam yeri tartışmalıdır.`
- 391 `Ötüken | Kutsal orman | Kutsal yer | Hangay'ın kutsal ormanlık dağları. Sonraki yüzyıllarda da bozkırın kalbi sayılacak.`
- 392 `Dailin | Kutsal yer | Sonbaharda atların semizliği ölçülüp nüfusun sayıldığı toplantı yeri. Tam yeri bilinmiyor.`
- 394 `Çang'an | Han başkenti | Başkent | Han Hanedanı'nın başkenti. Liu Bang'ın sarayı burada yükseldi.`
- 395 `Xianyang | Ç'in başkenti | Başkent | Birinci İmparator'un başkenti. MÖ 206'da yakılacak.`
- 396 `Luoyang | Şehir | Sarı Irmak ovasının eski başşehri.`
- 397 `Handan | Şehir | Eski Zhao krallığının başkenti.`
- 398 `Linzi | Şehir | Qi bölgesinin büyük şehri.`
- 399 `Ji | Şehir | Yan bölgesinin merkezi. Hun akınlarının sık hedefi.`
- 400 `Jinyang | Şehir | Liu Bang, Baideng seferine buradan çıktı.`
- 401 `Pingçeng | Şehir | Baideng tepesi bu şehrin yanındadır.`
- 402 `Mayi | Şehir | Han Wang Xin MÖ 201'de burada Hunlara teslim oldu.`
- 403 `Yunzhong | Sınır şehri | Sarı Irmak kıvrımında sınır karakolu.`
- 404 `Longxi | Sınır şehri | Çin'in batı ucunda sınır bölgesi; sur buradan başlar.`
- 405 `Liaodong | Sınır şehri | Surun doğu ucundaki bölge merkezi.`
- 406 `Pengçeng | Şehir | Liu Bang'ın memleket bölgesine yakın büyük şehir.`
- 407 `Çengdu | Şehir | Sichuan ovasının merkezi.`
- 408 `Jiangling | Şehir | Yangzi kıyısında eski Chu bölgesi.`
- 409 `Wu | Şehir | Yangzi ağzının merkezi.`
- 410 `Panyu | Nanyue başkenti | Başkent | Nanyue krallığının başkenti.`
- 412 `Loulan | Vaha krallığı | Lop Nur kıyısında. MÖ 176'da Hunlara boyun eğdiği Mete'nin mektubunda yazar.`
- 413 `Qiemo | Vaha krallığı | Taklamakan'ın güney yolu üstünde küçük krallık.`
- 414 `Hotan | Vaha krallığı | Yeşim taşıyla ünlü vaha.`
- 415 `Yarkent | Vaha krallığı | Pamir yolunun başında.`
- 416 `Kaşgar | Vaha krallığı | Tarım'ın batı kapısı.`
- 417 `Aksu | Vaha krallığı | Tanrı Dağları'nın güney eteğinde.`
- 418 `Kuça | Vaha krallığı | Kuzey yolunun en büyük vahası.`
- 419 `Karaşar | Vaha krallığı | Bağraş Gölü yanında.`
- 420 `Turfan | Gushi | Vaha krallığı | Hunlarla Tarım arasındaki kapı.`
- 421 `Dunhuang | Vaha | Hexi koridorunun batı ucu. Bu dönemde Yüeçi ve Vusun yurdu içinde anılır.`
- 423 `Baktra | Başkent | Greko-Baktriya krallığının başkenti.`
- 424 `Ay Hanum | Şehir | Ceyhun kıyısındaki Yunan şehri.`
- 425 `Marakanda | Semerkant | Şehir | Soğd bölgesinin merkezi.`

Events:
- 430 `MÖ 210'lar | Yüeçi'de rehine | Babası Teoman, küçük oğlunu tahta geçirmek için Mete'yi Yüeçilere rehin verdi, ardından Yüeçilere saldırdı. Mete, ölümden en hızlı atlardan birini çalarak kurtuldu ve Hun yurduna döndü.`
- 431 `MÖ 209 | Islıklı ok | Teoman ona on bin atlı verdi. Mete adamlarını ıslıklı okun gittiği yere ateş etmeye alıştırdı; önce kendi atına, sonra eşine denedi. Bir av sırasında babasını gösterdi ve tahta çıktı.`
- 432 `MÖ 208 | Tunghu'nun yıkılışı | Tunghu önce bin li'lik atı, sonra bir hatunu istedi; Mete verdi. Sıra aradaki boş toprağa gelince "Toprak devletin temelidir" dedi, vermeyi öğütleyenleri cezalandırdı ve hazırlıksız Tunghu'yu yıktı.`
- 433 `MÖ 205 | Ordos geri alındı | Loufan ve Baiyang Hun yönetimine girdi. Meng Tian'ın aldığı topraklar geri alındı, sınır yeniden Sarı Irmak'ın güneyine indi.`
- 434 `MÖ 203 | Kuzey seferi | Hunyu, Çüşe, Dingling, Gekun ve Sinli boyun eğdi. Hun beyleri artık Mete'yi bilge sayıyordu.`
- 435 `MÖ 201 | Mayi'nin teslimi | Mete, Mayi'yi kuşattı. Sınır kralı Han Wang Xin teslim oldu; Hun ordusu Taiyuan'a kadar indi.`
- 436 `MÖ 200 | Baideng Kuşatması | Mete zayıf görünüp Liu Bang'ı öne çekti, seçme birlikleriyle Baideng tepesinde yedi gün kuşattı. İmparator, Mete'nin hatununa rüşvet vererek kurtuldu.`
- 437 `MÖ 198 | Heqin barışı | Han, Tanhu'ya prenses vermeyi, her yıl ipek, şarap ve tahıl göndermeyi kabul etti. Çin ile bozkır arasındaki ilk eşit antlaşmadır.`
- 438 `MÖ 176 | Büyük batı seferi | Sağ Bilge Kral Yüeçi'yi ezdi. Mete, İmparator Wen'e yazdığı mektupta Loulan, Vusun, Hucie ve yirmi altı ülkenin "tek aile" olduğunu bildirdi.`
- 439 `MÖ 174 | Mete'nin ölümü | Otuz beş yıllık saltanatın sonu. Oğlu Jizhu (Laoshi) tahta geçti; geride Baykal'dan Tarım'a uzanan bir imparatorluk kaldı.`

**Scheme.** Only POLITIES have ids. Add stable ids to LAKES, RANGES, PLATEAUS, DESERTS, RIVERS, SEAS, REGIONS, CLANS, CITIES, EVENTS, then use `t('geo.<table>.<id>.name', fallback)`.

## e) Map rescale, 1500 to 75000 km²

**Recommendation: Option A, split display scale from internal units.** This fits the project note that 75,000 km² is an over-world scale and played regions are hand-built and compressed.
```js
const MAP_AREA_UNITS = 1500;                 // MAP_W and MAP_D derive from this
export const AREA_KM2 = 75000;               // display only
export const KM_PER_UNIT = Math.sqrt(AREA_KM2 / MAP_AREA_UNITS); // 7.0711
```
Only these change: `atlas.js:416` text (true ratio becomes about 1:18.5), and `atlas.js:1028-1035` with `pxPerKm=innerWidth/(s*(this.real?1:KM_PER_UNIT))` plus 50 and 100 added to the `nice` list. Also fix the [C] converters below for correctness. The camp scene becomes a 7x exaggerated inset. The map looks identical and no LOD changes.

**Why not just change the constant** (scratch-copy run, only `AREA_KM2` edited):

| Metric | 1500 | 75000 naive |
|---|---|---|
| MAP_W x MAP_D | 50.42 x 29.75 | 356.51 x 210.38 |
| Texel | 32.8 m | 232 m |
| Max height | 0.724 | 0.580 |
| Land above 0.3 km | 9.39% | 3.60% |
| Land above 0.15 km | 24.38% | 11.03% |
| GMAX range used | 0.788 | 0.09 |

Under true km scaling, zoom span ratio goes from 795x to 5600x. At `REAL_SPAN` only 12.5 texels would cross the screen (88 today), and the camp lake drops below one texel. `generateRelief` has no window support (`relief-core.js:24-29`), so a local tile would be new work.

**Full list if you choose true km scaling (Option B), S=7.0711.**
- Legend: [C] broken converter, fix in any case. [F] per-km frequency, ÷S. [L] km length, ×S. [H] km height, ×S if relief scales. [Z] map zoom span, ×S. [R] scene-bound, keep. [P] pixels or resolution, keep or revisit. [D] display. [S] slope threshold, keep if heights scale.

`geography.js`
- `:2` comment, `:5` AREA [D]. `:8-9,:11,:15` derived.
- `:55-86` RANGES `h` 0.14-0.82 [H]. `:90-91` PLATEAUS `h` 0.42, 0.1 [H].
- Degree data, safe after [C] fixes: RANGES `w`, POLITIES `blob` (`:237-371`).
- `:41-50` `LAKES.level` and `:172-189` `REGIONS.r` are unused anywhere: delete.

`relief-core.js`
- `:7` RW 1536 [P]. `:9` HMAX 0.7 [H], GMAX 3 [S]. `:17` VS [H]. `:20` LOCAL_LAKE [R], third copy of `terrain.js:12`, `valley.js:8`.
- `:303` `0.85` [C], should be `(d-1)/(LAT1-LAT0)`.
- `:310-311` freq 0.17, 0.62 [F], amp 1.5, 0.35 [L]. `:314` 2.2 [L]. `:317` `+2` [P].
- `:352-354` K, relax, diffuse keep; slopeMax [S]. Erosion is scale-invariant if heights scale (`:271,:273`).
- `naturalEdge` args: `:362` blur 5 [P], freq 1.5 [F]. `:368` blur 7|2, freq 2.6|5. `:398` 26, 0.62. `:399` 30, 0.52. `:400` 34, 0.8. `:401` 40, 0.42. `:402` blur 26 [P].
- `:379,:382` window -0.62..-0.08, -0.56..0.52 [R]. `:386` /1000 [R]. `:390` 0.09, 0.05 [R].
- `:416` blur 1, `:421` blur 8, `:433` blur 9 [P]. `:425` 0.34, `:427` 0.5 [F].
- `:442` 0.14 [F], amp 1.5 [L]. `:443` 0.2. `:445` 0.34, 0.92. `:446` 0.11. `:449` 0.62. `:450` 1.9. `:453` 0.3, 0.95 [F].
- `:451` 0.012, 0.05, 0.095, 0.036 [H]. `:454-456` via VS. `:471` 0.006+0.0036w [H]. `:484` 0.006 [H]. `:503` 0.03 [H].
- `:511` 0.7 [F]. `:557` f 1.5|3.2 with `:563` x1.4 [F], a 0.05|0.024 [H]. `:564` 0.011 [H].
- `:580-581` blur 2, 22, `:604-605` blur 4, 18 [P]. `:591` 0.004, 0.003 [H]. `:595` 0.9 km [L].
- `:625` 0.15-0.27 [H]. `:626` 0.02, 0.05, 0.03 [H], freq 2.6 [F], slope 1.7, 0.9 [S]. `:628` 0.06, 0.5 [S]. `:629` [H].
- `:630` three `0.85` [C], derive latitude from z. `:633` 4.1 [F], 0.2, 0.12 [H]. `:641` gains 26, 3.2 ÷S. `:663` 0.002, `:668` 0.95, `:673` 0.0055 [H].

`relief.js`
- `:74` 3584, `:144-145` 1600, 3072 [P]; line widths `:86,:198,:200,:215,:218,:222,:225` stay.
- `:171` `0.646`, `0.85` [C], export km-per-degree from `geography.js`.
- `:245-248` 0.0235, 0.071, 0.23, 0.71 [F]. `:277-281` 0.043, 0.27, 1.15, 1.7, 0.62 [F]. `:301` 0.8, 2.1 [F].
- `:309` 0.16, 0.25 [H]. `:311` 0.58, 1.15 [S], 0.035, 0.12 [H]. `:314` 190 ÷S. `:325-328` snow and tundra [H]. `:327` 0.8, 1.7 [S]. `:345` 0.03, 0.09 [H].
- `:333` 2.3, 3.4 [F]. `:375` 1.5, 1.1 [L]. `:380-384` 1.9, 1.31, 0.31, 0.37, 3.1, 2.9 [F]. `:386-387` 1.7, 4.3 [F]. `:414` 0.05 [F]. `:415` 0.05, 2.1, 2.8 [L]. `:468` 80 [L]. `:471` 0.42 [F].
- `:423` 1000x600, `:426` K 2.2 [P]. Vertex spacing at camp goes 25 m to 176 m; K≈4 gives about 52 m.

`atlas.js`
- `:17` 2.9, `:18` 0.085 [R]. `:20` 6 [Z]. `:133-134` 30, `:481` 11, `:698` 21, `:713` 26, `:1023` 13 [Z]. `:1019` 2.2, `:1020` 0.008, 0.2 [R].
- `:138` overwritten by `:868-869` (0.02, `+40`) [Z]. `:139` overwritten by `:859-860` [R].
- Trees: `:195` 42000, `:198` 260000 [P]. `:203` 0.012 [H]. `:204` 0.055-0.095 [L]. `:205` 0.003 [H]. `:842` smooth(26,13) [Z].
- Clouds: `:246` 3.6, -1.6 [L]. `:251` 0.42 [L]. `:268` y 1.15, 1.75 [H], offset 13.7 [L]. `:274-275` 760, 0.0052, 12000 [R]. `:835` smooth(4.5,15), `:838` 11 [Z]. `:840` smooth(0.7,2) [R].
- Wall: `:284` 0.2, `:290` 0.026, 0.04, `:291` 0.07, 0.11, 0.03 [L]. `:287` 0.02 [H].
- Label thresholds [Z]: `:304` 8|4.5|3.6|5, 56|46|34. `:307` 2.6, 15|34. `:309-310` 34|22|14, 2.6. `:312` 2.6. `:313` 2.6, 26. `:320` 4, 60.
- Local labels `:525-531` [R].
- m/km converters `:606,:710,:856,:879,:884` [R].
- `:608` plane y 0.1 [H]. `:631` 2.6 [Z]. `:642` 1.42 [R]. `:774` log 4..50 [Z]. `:789-790` 5.6, 3.1 [R]. `:819` 0.6 [R]. `:832-834` smooth(7,26), smooth(14,4.5) [Z].
- `:885` 0.035, 1.4 [R]. `:895` 0.01 [H]. `:892,:899,:911,:986` fractions of span, keep.
- `:997` 18, `:1004` 12 [Z]. `:1009` 0.6 [R]. `:1046` smooth(0.3,2.4) [R]. `:1055` smooth(6,40) [Z]. `:1029` nice, `:416` [D].

**Generic words.**
- `kind:'Kabile'`: `geography.js:237,241,245,249,253,280,290,294,302,331,346,350,354,358,362,367,371`.
- `kind:'Klan'`: `:381-385`.
- Name: `:253` `Çiang Kabileleri`.
- Notes: `:212,254,287,368,372` (kabile), `:381,382,383,384` (klan).
- UI: `atlas.js:25` `Kabileler`, `:26` `Klanlar`. The kind appears on cards at `atlas.js:677`.
- Comments only, not visible: `geography.js:3,196,365,376`, `relief.js:158`. Internal ids `tribes`, `clans`, `tribe`, `clan`, `.al-clan` are not visible.
- Fix: rename `:253` to `Çiang`, drop these `kind` values (`:677` already tolerates missing), reword the notes, and remove both layer toggles while keeping those layer keys true.

**How layers and eras work now.**
- `atlas.js:131-132`: era defaults to `'200'`, all layers true.
- `relief.js:164` filters polities by era and layer. Toggle at `atlas.js:462-467` repaints unless the layer is nature, cities, events or clans. `setEra` at `:658-664`.
- Labels and icons both use `itemOn` (`:902-906`) with span limits.
- `openEvent` sets era and `layers.events` (`:694-701`) without syncing `aria-pressed` or dirty flags: existing bug.

**Reveal hook.** Add one predicate, `progress.revealed(row)`, from a `unlock` field on each data row:
1. `relief.js:164`, new parameter on `paintOverlay` (call sites `atlas.js:167,465,661`). Guard `core` at `relief.js:167,192`.
2. `atlas.js:903`, inside `itemOn`.
3. Era buttons `:443-453`, and default era from progress. Add an earlier era for Act 1, since `'209'` postdates the hostage years.
4. Life list `:472-477`, card navigation `:681-690`, `openEvent`.
5. Crumbs and region names `:994-1010`.
6. Optional fog of war: low-res mask in `FINAL_HOOK` (`relief.js:411-419`), plus limits in `clampTarget` (`:638-650`).
7. Refresh in `Atlas.open` (`:705`): repaint and set dirty flags.

## f) Input and state

**State.** `main.js:83` holds `creator|game|map`. `goTo` (`:170-174`) fades; `commitState` (`:176-203`) switches. `toggleMap` (`:149-166`) is guarded by `mapBusy` and `pending`.

**Wiring**
- `main.js:135-145` keydown: map M/Esc; game T, C, M. Guard on INPUT.
- `game.js:209-222` pointerdown: left only, walk or mount. `:223-234` move, pinch, hover. `:235-240` up, cancel. `:241-245` wheel zoom. `:246-252` keydown, keyup, blur.
- Polled in `update`: E `:539-541`; WASD and arrows `:548-549`; Shift and `sprintToggle` `:477`; Space `:656`; repath while held `:534-537`.
- `atlas.js:538-572` pan, shift or right-button yaw, pinch, dblclick, contextmenu. `:573-579` keys. Polled `:780-787` WASD, arrows, Q, E. `:489-493` wheel on `.atlas`.
- `stage.js:117-136` rotate drag.
- `hud.js:38-41` buttons, `:43-53` pointerdown jump and run, `:59-61` touch detection.
- `creator.js:119-123,144,163`.
- Separation today is only `active` flags on Game, Atlas, Stage. `#ui` is `pointer-events:none`, with buttons opted in (`style.css:20-21`).

**Bugs found**
- Wheel over the map ground does nothing, because `.atlas` has `pointer-events:none` and the event goes to the canvas (verified). It only works over a label or control. Move the listener to the canvas.
- `atlas.js` has no blur handler, so Alt-Tab while holding W leaves pan stuck.
- `game.js:252` blur does not reset `useHeld` or `jumpHeld`.

**Modal gate design.** `Game.active=false` stops physics and camera (`game.js:532`), and `leave()` (`:419-428`) wipes state, so dialogue needs a new flag `controlsEnabled`.

Must be gated (or fully covered by an overlay with `pointer-events:auto`):
- Game: pointer `:209-234`, wheel `:241`, keydown `:246`, polling above, `interact()` `:361`, `queueJump()` `:356`.
- Main: `:135-145`.
- HUD callbacks `main.js:111-118` (or hide the HUD).
- Atlas: `:538-578`, `:780-787`.

On capture: clear `keys`, `mouseDown`, `pointers`, `path`, `targetHorse`. On release: set `useHeld=keys.has('KeyE')` and `jumpHeld=keys.has('Space')`, or the closing key re-triggers. Keyboard always needs gating because overlays do not stop window listeners. Extend the INPUT guard (`main.js:136`, `game.js:247`) to textareas and add it to atlas. Add an Esc policy: modal, then map, then pause. Cinematics also need skip by hold or tap.

## g) Performance hot spots (2149x1209, M1 Pro under load)

| Scenario | Calls | Triangles |
|---|---|---|
| Game default | 582 (main 371, shadow 195, post 16) | 3.84M (main 2.56M, shadow 1.28M) |
| Map, span≥26 | 31 | 1.24M |
| Map, span<26 | 30-32 | 4.16M |
| Map real mode | 568-672 | 3.5-4.7M |

Inventory: grass 998k tris (83,202x12), cast trees 847k (371 instances), other trees 586k (7,450), flowers 295k (22,701x13), near 157k, far 129k, rocks 106k, hero about 59k.

Frame timing, min/median ms:

| Test | Min | Median |
|---|---|---|
| Full frame, runs before and after the toggles | 25.9, 20.3 | 33.5, 27.9 |
| Post chain with empty scene | 11.4 | 15.5 |
| Post chain, Kuwahara off | 8.3 | 10.4 |
| Full, no grass or flowers | 17.3 | 22.6 |
| Full, shadow frozen | 20.9 | 25.8 |
| Full, tilt off | 23.4 | 28.8 |
| Map frame | about 13-14 | about 14.5 |

**Where the time goes**
1. **Post chain is about half the frame.** RGBA16F 4x MSAA target (`post.js:182`, about 83 MB colour), 13 bloom passes, 26-fetch Kuwahara at full res (`post.js:70-113`, about 3-5 ms). Test samples 2, 4 bloom levels. The MSAA share was not isolated.
2. **Grass and flowers, about 3-5 ms.** Vertex texture fetch per vertex (`grass.js:29`, 1.66M vertices if all drawn), no distance cull.
3. **Shadow pass, up to about 5 ms, noisy.** 4096² re-rendered every frame (`world.js:65`). Options: update every second frame, or 2048².
4. **Lights.** 4 point lights in every paint material. Keep the count fixed, and fake door and lantern lights as the stove does (`interior.js:52-60`).
5. **Smoke.** 34 sprites are 34 materials and draws (`fire.js:215-219`). Batch them.

**CPU**
- `Game.update`, `World.update`, `pick`, labels: at or below the 0.1 ms timer resolution. Not hot.
- A* long path: 53-79 ms, repeated at up to 7 Hz while the button is held (`game.js:534-537`), also blocked retry at `:611-615`. This is the only CPU spike. Causes: `lineFree` steps 5 cm (`nav.js:133`), allocations at `nav.js:151`, repeated line checks at `nav.js:196-198`. Fix: coarser steps, skip repath if the goal cell is unchanged, cap per frame.
- Allocations per frame (minor): `horse.js:221-229` via `game.js:820`; `main.js:247-248`.

**Hitches**
- `resize()` reallocates every render target on dynamic resolution change (`main.js:267-274`).
- `renderer.compile` covers only the world scene (`main.js:207`); use `compileAsync` per scene.

**Low priority.** Atlas trees are unculled (`atlas.js:214`, 2.92M tris) but cost only about 1 ms here. Recheck on weaker GPUs.

## Refactors before feature work, in dependency order

1. **Input router and `controlsEnabled`, including the wheel and blur fixes.**
   Files: `main.js`, `game/game.js`, `map/atlas.js`, `ui/stage.js`, `ui/hud.js`, new `core/input.js`.
2. **State and frame dispatch: state objects, post profiles, separate cinematic camera slot, shared loader screen.** Needs 1.
   Files: `main.js`, `core/post.js`, `game/game.js`, `map/atlas.js`.
3. **Actor interface: `Hero extends Rig`; `seatHeight`, `rootScale`, per-actor speeds, jump, ride pose; remove `HERO_SCALE` and `.opts` use; optional NPC skip list.** Needs 2 for spawn flow.
   Files: `character/rig.js`, `character/hero.js`, `character/folk.js`, `character/npc.js`, `game/game.js`, `ui/stage.js`, `main.js`, `world/world.js`.
4. **i18n kernel and stable ids; remove string-compared logic; remove generic words.** Independent; do early because every later feature adds strings.
   Files: new `i18n/*`, `map/geography.js`, `map/atlas.js`, `map/relief-core.js`, `ui/hud.js`, `ui/creator.js`, `main.js`, `world/world.js`, `world/layout.js`, `world/yurt-designs.js`, `game/game.js`, `index.html`.
5. **Map units: split display from internal units, fix [C] converters, delete dead fields, single lake line.**
   Files: `map/geography.js`, `map/relief-core.js`, `map/relief.js`, `map/atlas.js`, `world/terrain.js`, `world/valley.js`.
6. **Progress store and reveal predicate.** Needs 4.
   Files: new `game/progress.js`, `map/atlas.js`, `map/relief.js`, `map/geography.js`.
7. **Cinematic prerequisites: sky dome, fog override layer, exposed bard handles, flame billboards, point-size clamps, grass chunk distance cull.**
   Files: new `world/sky.js`, `world/world.js`, `world/valley.js`, `world/fire.js`, `world/ambient.js`, `world/grass.js`, `character/npc.js`, `character/head.js`.
8. **Terrain class and `WorldSpec`; move palettes, bounds, folk, horses, nav and camera offsets into data; unique material keys.** Needs 3 for folk.
   Files: `world/terrain.js`, `world/layout.js`, `world/world.js`, `world/flora.js`, `world/grass.js`, `world/valley.js`, `world/camp.js`, `world/interior.js`, `world/ambient.js`, `character/npc.js`, `game/game.js`, `map/atlas.js`, `map/relief-core.js`.
9. **World lifecycle: `World.dispose`, `Game.setWorld`, `Atlas.setWorld`, shared-resource tags, current-world reference in main.** Needs 8.
   Files: `world/world.js`, `world/camp.js`, `world/interior.js`, `world/fire.js`, `character/npc.js`, `character/horse.js`, `character/folk.js`, `game/game.js`, `map/atlas.js`, `main.js`.
10. **Performance pass: post chain, shadow cadence, smoke batching, A* limits, async compile.** Can run in parallel, but do it before wide-shot tuning and before adding Act 1 crowds.
    Files: `core/post.js`, `world/world.js`, `world/fire.js`, `world/grass.js`, `game/nav.js`, `game/game.js`, `main.js`.

**Feature work then builds on these:**
- Child in free roam: 1-3.
- Cinematic: 1, 2, 7.
- Winter camp: 3, 8, 9.
- Map at 75000 and reveal: 4, 5, 6.
- EN language: 4.