# Tanhu 3 menu system: HTML/CSS/JS implementation spec

All paths are relative to `/Users/mucahidyazar/game-development/projects/tanhu/game/`.

**How this was measured**
- Everything below comes from reading the source, except the sizes marked "measured".
- Measured sizes come from running the real UI scripts in a scratch copy, headless at 1920×1080 with the real fonts.
- The real project was not modified. A timestamp scan found no project file changed today.
- Godot needs a window to render, so I ran two Godot sessions outside the sandbox on the scratch copy to get pixels. They left two log files in `/Users/mucahidyazar/Library/Application Support/Godot/app_userdata/TanhuUiProbeScratch`, which you can delete.

**No menu screenshots existed** under `docs/` or `assets/_reference/`, so I rendered reference PNGs from the real UI code. Their background is `menu_camp.png`, not the live camp.
- Folder: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots`
- Full control-tree dump with every rect: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/probe_headless.log`
- Key renders:
  - Save card: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/menu_02_card.png`
  - Hover: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/menu_03_new_hover.png`
  - Disabled buttons: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/x_menu_nosaves.png`
  - Settings: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/book_settings_0.png`
  - Keyboard view: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/book_controls_1.png`
  - Creator: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/creator_full.png`
  - HUD: `/private/tmp/claude-501/-Users-mucahidyazar-Code-tests-tanhu-programatic-test/a5376728-31bc-47ae-842a-d14c04e4bd0d/scratchpad/tanhu_ui_copy/shots/x_hud.png`

## 0. Global rules

**Scaling** (project.godot: 1920×1080, stretch `canvas_items`, aspect `expand`)
```js
S = Math.min(W/1920, H/1080); canvasW = W/S; canvasH = H/S; root.style.transform = `scale(${S})`;
k = uiScale * clamp(1080/(H*devicePixelRatio), 0.4, 1);   // GameSettings.ui_k, game_settings.gd:222,254
```
- All px below are canvas px. Margins in layout math are not multiplied by k unless written `*k`.
- On a HiDPI or 4K window, k shrinks the UI so physical size stays constant, as Godot does.

**Palette** (ui_kit.gd:13-23, menu_style.gd:20-32)

| Token | Value |
|---|---|
| GOLD | #D9B56C |
| GOLD_DIM | #7D6236 |
| PARCHMENT | #EFE2C4 |
| SKY | #7FE3FF |
| SKY_DEEP | #2F8FB8 |
| CRIMSON | #D0343F |
| EMBER | #FF8A3D |
| TEXT | #F1E8D4 |
| TEXT_DIM | #A79D88 |
| INK (ui_kit) | #090C12 |
| FELT | #090B0F/.9 |
| CREAM | #F2EAD8 |
| HOT_GOLD | #FFD180 |
| INK (menu_style) | #0A1026/.8 |
| INK_WARM | #452B12/.86 |
| GLOW | #FFCC75/.62 |
| HOT_TINT | multiplier (1.05, .93, .66) |

**Fonts**
- All are SIL OFL, in `assets/fonts/`. Alegreya and Alegreya-Italic are variable (wght 400-900), Cinzel is variable (wght 400-900), AlegreyaSC-Regular and AlegreyaSC-Bold are static.
- `spacing_glyph` maps to CSS `letter-spacing` in px.
- Cinzel lowercase renders as small caps, so keep mixed-case strings verbatim. Alegreya digits are old-style by default.
- Line height is `ceil(asc*size)+ceil(desc*size)`. Cinzel asc .976, desc .372. Alegreya asc 1.016, desc .345.
  - Cinzel 38→53, 34→47, 32→44, 30→42, 24→33.
  - Alegreya 48→66, 28→39, 25→35, 22→31, 21→30, 20→28.

**Text shadow**
- `UIKit.label` is a stroked shadow: rgba(0,0,0,.65), offset (0,3), outline 6. CSS approximation: `text-shadow: 0 3px 3px rgba(0,0,0,.65)`.
- `UIKit.rich`: rgba(0,0,0,.7), offset y 3, outline 5, line_separation 6.
- KnotButton text, draw_string text and tab text have no shadow.

**Panel style** (`panel_style`, ui_kit.gd:86)
- Every panel has content margins L/R 28, T/B 18. These enlarge real sizes.
- `shadow_size N` maps to CSS `box-shadow: 0 0 {N/2}px {N/2}px color`.
- Use `background-clip: padding-box`.

**Focus layering**
- Godot draws the `focus` stylebox on top of the current state stylebox, then the text.
- Stylebox swaps are instant. Only the values called out as tweens are animated.

**Easing**
- Default tween is linear.
- `TRANS_SINE` alone (in-out): cubic-bezier(.37,0,.63,1)
- Sine out: (.61,1,.88,1)
- Sine in: (.12,0,.39,0)
- Cubic out: (.33,1,.68,1)
- Back out: (.34,1.56,.64,1)

**Z-order** (scenes/main.tscn)
3D → PainterlyOverlay (layer 1) → UI (layer 5: MainMenu, GameHud, CharacterCreator, Fade [black, starts α1], MenuToast, Epigraph) → PauseMenu (layer 120).

**Sounds** (audio_manager.gd:64-80, menu_style.gd:12)

| Event | File | Level and pitch |
|---|---|---|
| hover | audio/sfx/ui_click.wav | pitch 1.5-1.65, -16 dB |
| click | audio/sfx/ui_click.wav (.8 s) | pitch .95-1.05, -5 dB |
| whoosh | audio/sfx/whoosh.wav (1.6 s) | pitch 1, -7 dB |
| page_turn | assets/ui/sfx/page_turn.ogg | open -4, page flip -8, close -6 dB |
| deny | assets/ui/sfx/ui_deny.wav (.87 s) | -6 dB |
| toast | assets/ui/sfx/ui_toast.wav (2.3 s) | -8 dB |
| music | audio/music/menu_theme.mp3 (150 s, loop) | 3 s fade to linear .36 |
| ambience | audio/ambience/night_meadow_loop.wav (30 s, loop) | 4 s fade to linear .16 |

- Buses: Master, Music, Ambience, SFX.
- `audio/_source/ui_hover.mp3` is unused.
- **Audio prompts:** no prompt list is stored. `tools/elevenlabs_audio.sh` takes prompts as arguments (music model `music_v1`, instrumental; sfx `eleven_text_to_sound_v2`, prompt_influence .45). The README has only two examples: "Crackling campfire, close-mic" and "Calm steppe night, dombra and soft strings".

## 1. Boot flow (scripts/main.gd)

States: `MENU, CREATOR, PLAYING, PAUSED, BUSY` (main.gd:28).

**Boot timeline** (main.gd:71-94)

| Time | Event |
|---|---|
| 0 | Fade rect black α1. Music and ambience start and fade in. |
| 0→1.6 | Epigraph α0→1 (sine). Starts after frame delta < .1 s, max 12 frames. |
| 1.6→5.8 | Hold 4.2 s. A press skips the rest of the hold. |
| 5.8→7.0 | Epigraph α→0 (sine), then it is removed. |
| 7.0 | Fade rect α=0 instantly. `menu.play_intro()` starts with its own curtain at α1. |
| 7.0→10.7 | Intro (see section 3). Then the menu becomes interactive. |

In browsers, audio needs a first user gesture. Start it on the first press.

**Transitions**

| Trigger | Steps |
|---|---|
| SERBEST GEZ | BUSY, whoosh, menu α→0 .5 s (sine in), `journey.profile=profile.copy()`, `_enter_play()`. |
| YENİ OYUN | If any save exists, ConfirmDialog(CONFIRM_NEW); on no, refocus quietly and stop. Then BUSY, whoosh, menu fade .5, black fade .35, creator.open(profile.copy()), 3D off, unfade .35, CREATOR. |
| Creator accepted | BUSY, profile.save(), journey.reset(profile) (flags and time cleared), black .3, hide creator, 3D on, unfade .35, `_enter_play()`. |
| Creator cancelled | Black .3, hide, unfade .35, `menu.show_menu(true)`, MENU. |
| DEVAM ET | `_load_from_menu(saves.latest_slot())`. |
| YÜKLE(slot) | `_load_from_menu(slot)`. |
| `_load_from_menu` failure | Toast "Bu kayıt açılamadı." kind warn. |
| `_load_from_menu` success | BUSY, whoosh, menu fade .5, enter play at saved pos/yaw, or spawn if the record has no position. |
| ÇIKIŞ | BUSY, audio fade .9, menu fade .5 (not awaited), black .9, quit. |

**`_enter_play(at, yaw)`** (main.gd:210)
- Applies the profile to the player and hides the camp NPC using the same model.
- Spawns at fire+(2.6,0,3.2) with yaw π.
- Activates the follow camera (1.6 s blend) and the player immediately.
- Sets flag `ilk_gezinti`, then runs `visit()`.
- Shows HUD hints if `show_hints`.
- After 1.6 s it announces unlocks and sets state to PLAYING.
- While PLAYING: `play_time += dt`, flag check every .25 s, toast "Destan Kitabı'na yazıldı: %s" for each new entry.

**Pause** (Esc or pad Start from PLAYING)
1. PAUSED, player inactive, `visit`, HUD hidden instantly.
2. Toast hidden for one frame while a UI-less frame is captured as `pending_thumb`.
3. PauseMenu opens GameMenu `game` mode on `genel`, world paused.

**From the pause book**
- Close → PLAYING.
- ANA MENÜ:
  1. BUSY, `save_auto()`, follow camera off, HUD fade .3.
  2. Menu camera takes the game camera's transform and FOV, whoosh.
  3. `return_to_menu(1.7)` sine in-out.
  4. Hide the player, show the NPC, `menu.show_menu(true)`, MENU.
- MASAÜSTÜNE DÖN: confirm first, then `save_auto`, quit fade as above.
- Load: BUSY, apply record.
  - On failure: toast warn, back to PLAYING.
  - On success: black .35, respawn, camera snap, unfade .45, PLAYING.

## 2. Epigraph (scripts/ui/epigraph.gd)

- Full-screen background #040507. Whole control α fades, over the black Fade rect.
- VBox centered, separation 26, scaled by k around the screen center.
- Measured box 827×125 at (547,478); quote height 66, attribution height 33.
- Quote: `«Yer, devletin temelidir. Onu kimseye vermem.»`. Alegreya-Italic 400, 48px, PARCHMENT, centered.
- Attribution: `Mete, Hunların Tanhusu · MÖ 3. yüzyıl`. Cinzel 600, 24px, GOLD_DIM, letter-spacing 4, centered.
- Timings: 1.6 / 4.2 / 1.2 s.
- Skip events (`is_skip_event`): key press non-echo, mouse L/R/M (not wheel), pad button, touch. F11 is excluded.
- All skip events are consumed for the epigraph's whole life, but only presses during the hold shorten it.

## 3. Main menu (scripts/ui/main_menu.gd)

**Strings**
- Subtitle `BİR BOZKIR DESTANI`
- Column: `YENİ OYUN`, `DEVAM ET`, `YÜKLE`, `DESTAN KİTABI`, `AYARLAR`, `ÇIKIŞ`
- `ÇIKIŞ` is omitted on web and mobile (main_menu.gd:465)
- `SERBEST GEZ`, `Kampta dolaş`, `Kulaklıkla oynaman önerilir`, `v0.1.0`, `SON KAYIT`
- CONFIRM_NEW `Yeni bir yolculuk başlayacak; otomatik kayıt yeni yolculuğa geçer. Emin misin?`
- `Bu kayıt açılamadı.`

**Layout** (main_menu.gd:392-403, verbatim logic)
```js
safeX = max(0,(cw - ch*16/9)/2); menuPx = menuH*k; gap = 40*k;
room = ch - 64 - 70 - menuPx - gap;
lk = clamp(room/max(logoH,1), k*0.7, k);
spare = max(0, room - logoH*lk);
logoPos = round(safeX+120, 64+spare*.35);
centreX = logoPos.x + 380*lk;
menuPos = round(centreX - 260*k, logoPos.y + logoH*lk + gap + spare*.25);
shadeSize = (safeX+1150, ch);
```
Measured `logoH=389`: logo 300 + 6 + ornament 30 + 6 + subtitle 47. `menuH=620` for 6 items, 512 for 5.

Results (cw×ch, k):

| Canvas, k | Items | lk | logoPos | menuPos |
|---|---|---|---|---|
| 1920×1080, 1 | 6 | .7352 | (120,64) | (139,390) |
| 1920×1080, 1 | 5 | 1 | (120,66) | (240,496) |
| 1920×1200, 1 | 6 | 1 | (120,70) | (240,503) |
| 2520×1080, 1 | 6 | .7352 | (420,64) | (439,390) |
| 1920×1080, .75 | 6 | .75 | (120,120) | (210,482) |
| 1920×1080, .6 | 6 | .6 | (120,175) | (192,512) |

**Elements**
- **Shade:** position 0,0, `shadeSize`, opacity .62, `linear-gradient(90deg, rgba(0,3,5,1) 0%, rgba(0,3,5,.6) 45%, rgba(0,3,5,0) 100%)`.
- **Logo holder:** scaled by lk from its top-left, 760 wide, separation 6.
  - Logo box 760×300, STRETCH_KEEP_ASPECT: draws 753×300 at top-left, not centered.
  - Fallback if the file is missing: `TANHU`, CinzelDecorative-Bold 190px, GOLD, letter-spacing 14.
- **Ornament** (760×30, y mid), color GOLD/.85:
  - Lines ±30→±330, width 2.
  - End ticks (±330,y)→(±350,y∓6), width 2.
  - Diamond r13, stroke 2.4.
  - Inner diamond r7, stroke 2, SKY/.9.
- **Subtitle:** Cinzel 600, 34px, PARCHMENT, letter-spacing 9, centered, label shadow.
- **Column:** scaled k, 6 holders 520×80 with gap 28 (pitch 108). The button is top-aligned in its holder and slides on x.
  - Measured real plate size is **520×89**, so visible gaps are 19 px and the last plate overflows its holder by 9.
  - Brush seeds: 1.3, 3.0, 4.7, 6.4, 8.1, 9.8 (`1.3+i*1.7`).
- **Free box:** scaled k, separation 6. KnotButton(font 24), custom 380×62, measured **380×69**, seed 7.7.
  - Hint below: Alegreya-Italic 21px, TEXT_DIM/.9, centered, height 30.
  - Measured box 380×105.
  - Position: `(cw-64-380k, ch-78-105k)`, so (1476,897) at k=1.
- **Footer** (not scaled):
  - Hint right-aligned in box x `cw-840..cw-140`, y `ch-52..ch-22`. Alegreya-Italic 22px, TEXT_DIM, opacity .8.
  - Version in box x `cw-100..cw-20`, y `ch-49..ch-21`. Alegreya 20px, TEXT_DIM, opacity .6, left-aligned.
- **Save card:** shown while DEVAM ET is focused. Scaled k.
  - Position `x = menu.x+(520+44+slide)*k`.
  - `y = clamp(menu.y+(108+40)*k - h*k/2, 40, ch-40-h*k)`.
  - Measured 398×381.
  - Panel bg #080A0F/.9, border GOLD_DIM/.95 width 2, radius 4, shadow black/.55 size 24, margins L/R 22, T 16, B 18, VBox separation 8.
  - Head: `SON KAYIT`, Cinzel 700, 17px, GOLD/.9, letter-spacing 5.
  - Thumb frame: bg black/.6, border GOLD/.55 width 1, padding 1. Thumb 352×198 cover. Empty mark `◇`, Cinzel 54px, GOLD_DIM/.8, centered.
  - Place: `Gece Kampı · <yer>`, Cinzel 600, 21px, GOLD, letter-spacing 1.
  - Title: `Otomatik kayıt` or `Kayıt #N`, Alegreya 24px, PARCHMENT.
  - Meta: `1 sa 10 dk  ·  31.10.2026  19:00`, Alegreya-Italic 20px, TEXT_DIM.
  - Show: opacity→1 .22 s linear, slide -18→0 .26 s cubic-out. Hide: opacity→0 .16 s.

**Intro** (parallel tween, main_menu.gd:64-70, 210)
- Curtain black α1→0: 2.0 s sine.
- Logo α 0→1: delay 1.1, 1.8 s sine.
- Subtitle α: delay 1.9, 1.3 s linear.
- Button i: delay `2.3+.1*i`. α→(1, or .6 if disabled) .55 s linear; x -56→0 .6 s cubic-out.
- Corner delay `2.3+.1*n`: free box α→1 .6 s; hint α→.8 .8 s; version α→.6 .8 s.
- Ends at 3.7 s for 6 items, 3.6 s for 5.
- Shade and ornament are never hidden; they appear from under the curtain.
- Any key, mouse button or pad press finishes instantly and is consumed.
- On finish: interactive, focus default quietly (DEVAM ET if saves exist, otherwise YENİ OYUN).

**Other transitions**
- Return to title: logo α .8 s sine; subtitle .6 s delay .3; buttons delay `.35+.06*i` (same per-button tween); corner delay `.35+.06*n`: free .45 s, hint and version .5 s.
- Hide: whole control α→0 .5 s sine in.
- Re-show while hiding: everything to shown in .35 s.

**KnotButton** (scripts/ui/knot_button.gd)
- Text: Cinzel 600, letter-spacing 2, centered. Sizes 38 (column), 24 (free roam), 30 (dialog, general, back).
- Plate `normal`: bg #0D0F16/.86, border #736142/.8 width 2, radius 3, shadow black/.45 size 10.
- Plate `hot` (hover, focus, pressed): bg #1A120A/.9, border #FFD180/.95 width 2, radius 3, shadow #FFB85C/.22 size 8. Focused composite ≈ #181209/.986, because focus draws over normal.
- Plate `disabled`: bg #0D0E12/.6, border #4C4538/.5, shadow black/.3 size 6. In the title column, also opacity .6.
- Margins 28/18 make real height = line height + 36.
- Text color: `lerp(#F1E8D4, #FDD88C, glow)`. Pressed #FFF2D1. Disabled #8C8578/.55.
- Knots (drawn at glow-lerped color from #9E8557/.9 to #FFD180; disabled #595247/.5), at x=34 and w-34, y=h/2:
  - Polyline square, radius 13, corners at 45°.
  - Polyline diamond, radius 10.66, corners on the axes.
  - Stroke 2.2, center dot r2.6.
  - Thread (same color at α .6, width 2) from 26 to 58 px off the knot, toward the text. Left x 60→92, right w-60→w-92.
  - When glow>.01: circle r `20+4*pulse`, #FFD180 α `.14*glow`, `pulse=.5+.5*sin(ms*.004)`.
- States:
  - Focus and hover are one state. mouse-enter grabs focus; mouse-leave keeps focus.
  - Focus in/out: glow tween .22 s sine-out. Scale to 1.06 (focus in, back-out) or 1 (focus out, sine-out), .28 s.
  - Press: scale .97 in .08 s sine-out. `brush.press=1` instantly.
  - Release: scale to 1.06 or 1 in .18 s. `press→0` in .35 s sine-out.
  - Pivot center.
- Sounds: hover only when focus came from the mouse or a nav key, and not on a quiet grab. Click on activate.

**Brush shader** (shaders/ui/menu_brush.gdshader, noise in shaders/include/noise.gdshaderinc)
- Rect behind the plate: x -28, y -10, size (w+56, h+20).
- Uniforms:
  - `rect_size=(w+56,h+20)`, `padding=10`, `seed=brush_seed`
  - `ink_color=(.04,.062,.15,0)`, `warm_ink_color=(.27,.17,.07,.86)`
  - `rim_color=(.949,.918,.847,0)`, `glow_color=(1,.8,.46,.62)`
  - `fray=1`, `reveal=1`, `highlight=glow`
- It is invisible at idle. On highlight, 18 px of dry bristles poke out each side, the right side more frayed, plus a soft glow in the 10 px padding.
- Only one button is hot at a time, so bake per seed at highlight=1 and fade with opacity, or use one lazy WebGL canvas.

Port verbatim:
```glsl
float hash12(vec2 p){vec3 p3=fract(vec3(p.xyx)*.1031);p3+=dot(p3,p3.yzx+33.33);return fract((p3.x+p3.y)*p3.z);}
float noise2(vec2 p){vec2 i=floor(p),f=fract(p),u=f*f*(3.-2.*f);
 return mix(mix(hash12(i),hash12(i+vec2(1,0)),u.x),mix(hash12(i+vec2(0,1)),hash12(i+vec2(1,1)),u.x),u.y);}
float fbm2(vec2 p,int o){float v=0.,a=.5,n=0.;for(int i=0;i<o;i++){v+=a*noise2(p);n+=a;p=p*2.03+vec2(13.7,7.3);a*=.5;}return v/n;}
float sdRB(vec2 p,vec2 h,float r){vec2 q=abs(p)-h+vec2(r);return length(max(q,vec2(0)))+min(max(q.x,q.y),0.)-r;}
vec4 over(vec4 t,vec4 b){float a=t.a+b.a*(1.-t.a);return vec4((t.rgb*t.a+b.rgb*b.a*(1.-t.a))/max(a,.0001),a);}
// main, UV y-down:
vec2 hr=rect_size*.5,p=UV*rect_size-hr,he=max(hr-vec2(padding),vec2(6.));float sx=seed*17.31+3.7;
float wob=(noise2(vec2(p.x*.008+sx,sx*.5))-.5)*he.y*.16;vec2 q=vec2(p.x,p.y-wob);float nx=clamp(q.x/he.x,-1.5,1.5);
float thick=he.y*(.97-.1*nx*nx);
float br=noise2(vec2(q.y*.42+sx*3.,sx)),brF=noise2(vec2(q.y*1.15-sx,sx*2.+5.));
float endT=smoothstep(.7,1.02,abs(nx))*fray,right=step(0.,nx);
float softD=sdRB(q,vec2(he.x,thick),thick*.85);
float d=softD+(fbm2(p*.05+vec2(sx,-sx),3)-.5)*4.5; d-=endT*(br-.45)*mix(6.,15.,right);
float aa=max(fwidth(d),.0001),body=1.-smoothstep(-aa,aa,d);
float dry=smoothstep(.28,.62,brF*.6+br*.4);body*=mix(1.,dry,endT*mix(.5,.85,right));
float front=mix(-he.x-46.,he.x+46.,reveal);float painted=1.-smoothstep(front-30.,front,q.x+(br-.5)*24.);body*=painted;
float fiber=noise2(vec2(p.x*.016+sx,q.y*.5)),edge=smoothstep(-8.,0.,d);
vec4 ink=mix(ink_color,warm_ink_color,highlight);ink.rgb+=vec3(.07,.06,.035)*press;
float inkA=clamp(ink.a*body*(.82+.18*fiber)*(.9+.2*edge),0.,1.);
float rimL=1.-smoothstep(0.,1.3,abs(d+1.4));vec3 rimC=mix(rim_color.rgb,glow_color.rgb,highlight);
float rimA=rimL*mix(rim_color.a,.7,highlight)*(1.-endT*.9)*painted;
float o=max(softD+2.,0.),sig=max(padding*.42,1.),pulse=.9+.1*sin(TIME*2.2+seed*4.);
float gA=glow_color.a*highlight*pulse*exp(-(o*o)/(2.*sig*sig));gA*=(1.-body)*mix(1.,.55,step(softD,0.));gA*=1.-smoothstep(front-30.,front,q.x);
COLOR=over(vec4(rimC,rimA),over(vec4(ink.rgb,inkA),vec4(glow_color.rgb,gA)));
```

**Keyboard and pad navigation** (main_menu.gd:739-766)
- Up/down wrap over enabled column buttons only.
- Left stays put. Right goes to SERBEST GEZ.
- From SERBEST GEZ: left and up return to the last-focused column button; right and down stay.
- Tab order: column, then free roam, then wrap.
- Enter, Space, NumpadEnter, pad A activate.
- Esc does nothing on the title.
- If focus is lost, a nav key restores the last-focused button.
- Use `event.code`, physical keys, as Godot does.
- Saves absent: DEVAM ET and YÜKLE are disabled and unfocusable.
- Opening YÜKLE, DESTAN KİTABI or AYARLAR hides the column and free box, and refocuses the source button quietly on close. ConfirmDialog leaves the column visible under its dim.

**Toast** (scripts/ui/menu_toast.gd)
- Top right: x `cw-760..cw-36`, y 36. VBox separation 10, items right-aligned. Not scaled by k.
- Each toast: OrnateFrame.wrap(margin 18, no gems, corner 14, tint, fill #06080C/.86), content padding 18 / 14.4.
- Text: Alegreya 500, 26px, TEXT, right-aligned, wraps. Min width `min(680, 14*len)`.
- Tint: info GOLD, save SKY, warn CRIMSON.
- α in .3 s, hold 3.2 s, out .6 s. Toast sound.

**OrnateFrame** (scripts/ui/ornate_frame.gd). Generate as SVG or canvas for any w,h. `r` is the full panel including padding; padding = margin, margin×.8.
1. Shadow: 7 filled rects `r.grow(3+4i)`, black α .055 each.
2. Fill: vertical gradient, top `fill.lightened(.07)`, bottom `fill.darkened(.3)`. Default fill #06080C/.95 gives #18191D→#040608.
3. Outer stroke `r.grow(-1)`, width 2, `tint.darkened(.4)` α .95 (GOLD→#826D41).
4. Inner stroke `r.grow(-7)`, width 1, tint α .45.
5. Each corner: `o=c+(sx,sy)*7`. Lines of length `corner` along x and y, width 2, tint. Diamond at `o+(sx,sy)*min(13,corner*.4)`, `dr=min(7.5,corner*.22)`, stroke 2, tint. Inner diamond `dr*.4`, stroke 1.6, SKY/.85.
6. Gem (top and bottom center, if enabled): lines ±16→±64, width 2, tint/.9. Filled diamond r11 #0D0F16. Stroke r11 2.2 tint. Inner r5 1.8 SKY/.95.

`wrap` content padding: margin L/R, margin×.8 T/B. Default margin 38, corner 34, gem true.

## 4. Book and pages

### GameMenu (scripts/ui/game_menu.gd)

**Modes**
- `title`: AYARLAR, TUŞLAR.
- `book`: DESTAN, KİŞİLER, TAŞLAR. Reads the latest save's flags.
- `game`: GENEL, DESTAN, KİŞİLER, TAŞLAR, TUŞLAR, AYARLAR.

**Backdrop** (assets/ui/menu_backdrop.gdshader)
```glsl
c = textureLod(screen,SCREEN_UV,3.4).rgb; c = mix(c, vec3(.012,.02,.035), .74);
d = length((UV-.5)*vec2(1,.82)); c *= mix(1., 1.-.62, smoothstep(.25,.75,d)); alpha 1
```
CSS approximation: `backdrop-filter: blur(6px)` + `background: rgba(3,5,9,.74)` + a matching radial vignette.

**Frame:** children scaled by k, frame size = canvas/k. Content rect y `118..h-70`.

**Open and close:** α 0→1 .18 s, page_turn -4 dB. Page flip: page_turn -8 dB, page α 0→1 .16 s. Close is instant, page_turn -6 dB.

**Top strip**
- Height 112. Vertical gradient #020306/.94 → #030408/.55.
- Bottom line y=h-1: full width GOLD/.16, 1px.
- Center ±640: GOLD/.55, 1.5px.
- Center diamond d7 filled GOLD, inner d3 filled SKY.
- Foot strip is the same, reversed, height 66, line at y=1.

**Tab row**
- y 8..100, separation 6, centered: Q bumper, tabs, E bumper.
- Tabs 176×92, or 166×92 in game mode.
- Tab draw, c=(w/2,30):
  - Diamond r21.
  - Active: circle r34 GOLD/.1, fill GOLD/.9, stroke 2 GOLD, glyph #0D0D12.
  - Hover: SKY.
  - Idle: fill #080A0F/.9, stroke and glyph TEXT_DIM/.85.
  - Label: Cinzel 700, letter-spacing 2, 19px, baseline 78, centered.
  - Active underline: y 87, text width, GOLD/.8, width 2.
- Tab hover plays hover sound.
- Bumpers are 64×80 hit areas (stretched to 92 by the row). Keycap 34×34 is left-aligned, not centered.

**Keycap**
- Shadow rect +3y, black/.5. Fill #0F121A/.95.
- Border inset 1, 1.6, GOLD_DIM, or SKY on hover.
- Top highlight y+3, white/.08.
- Key text: Cinzel 700, 17px, GOLD, or SKY on hover, centered.
- Width `max(34, textW+20)`.

**Foot row**
- x 28..w-28, y 10.., separation 26.
- Hints:
  - title/book: `Esc Geri`
  - game: `Esc Devam et`, `F5 Kaydet`, `F9 Yükle`
- Label: AlegreyaSC-Regular 21px at x=cap+10, PARCHMENT, or SKY on hover. Disabled α .35.
- Right hint: Alegreya-Italic 20px, TEXT_DIM, right-aligned.

**Page hints**
- genel `Yolculuğu kaydet, yükle ya da bırak`
- destan `Q E: bölüm çevir · yukarı / aşağı: dize seç`
- kisiler `Q E: bölüm çevir · yukarı / aşağı: kişi seç`
- taslar `Q E: bölüm çevir · yukarı / aşağı: taş seç`
- tuslar `Z C: görünüm değiştir (liste · klavye · oyun kolu)`
- ayarlar `Yukarı / aşağı: bölüm seç · sağ: içine gir · Z C: bölüm değiştir`

Save notice replaces the hint in SKY for 2.6 s with toast sound: `Yolculuk kaydedildi · #%d`.

**Input**
- Q/E or LB/RB turn pages, wrapping.
- Esc or Start closes.
- F5/F9 in game mode open slots, or play deny.
- Input is ignored while an overlay is open.

**Glyphs** (game_menu.gd:510-589, port literally). `s`: tab 10, side 11, view 12. Stroke widths are fixed.
- home: arc center (0,.25s) r.95s top half; sides to .85s; floor; door rect (-.22s,.3s,.44s,.55s); chimney (0,-.7s)→(0,-s).
- speech: circle (0,-.1s) r.8s; filled tail (-.35s,.55s),(-.7s,s),(-.05s,.65s).
- people: circles (∓.4s,-.35s) r.32s; top half arcs (∓.4s,.75s) r.6s.
- stone: top arc `(cos a*.55s, -.35s+sin a*.6s)` for a in π..2π; down to (±.62s,s); ring (0,-.2s) r.22s; line (±.3s,.35s).
- keys: rect ±(s,.65s); 3 filled keys at x `-.75s+k*.55s`, y `-.35s`, size (.38s,.3s); line (±.5s,.3s).
- gear: circle r.55s; 8 spokes .62s→s stroke 2; dot r.18s.
- monitor: rect (-s,-.75s,2s,1.3s); stem (0,.55s)→(0,.85s); foot (±.45s,.9s).
- speaker: filled (-.9s,-.3s),(-.45s,-.3s),(0,-.8s),(0,.8s),(-.45s,.3s),(-.9s,.3s); arcs at (.1s,0) r.45s and .85s, ±.9 rad.
- list: 3 rows y=(k-1).6s; dot (-.8s,y) r.13s; line (-.5s,y)→(s,y).
- keyboard: rect ±(1.2s,.7s); 2×5 filled keys at (-.98s+k*.42s, -.48s+r*.42s), size (.28s,.26s); bar (±.6s,.42s).
- pad: closed curve `(cos a*1.25s, sin a*.62s)`, plus `|cos a|*.45s` on y when sin a>0; d-pad lines at (-.65s,-.05s); dots (.55s,-.2s), (.8s,.02s).

### Divider and VRule
- Divider (height 24 or 26): diamond r11 stroke 2.2 GOLD/.8; inner r5 stroke 1.8 SKY/.9; lines from `cx±half` to `cx±22`, width 2, GOLD/.8, `half=min(300,cx-4)`.
- VRule: 1px at center x, y 10..h-10, GOLD/.35; center diamond d6 filled GOLD.

### Settings (scripts/ui/settings_panel.gd, game_settings.gd)

**Geometry** (measured): panel 1408×710.4 at (256,209) in screen px; OrnateFrame margin 34.
- Left column 300 wide, separation 8:
  - Caption `AYARLAR`, Cinzel 700, 22px, GOLD/.8, letter-spacing 6, height 54.
  - SideButtons 300×64. Glyph at (36,h/2), s=11. Label at x=66, baseline h/2+8, Cinzel 700, letter-spacing 3, 22px.
  - Selected: bg #1F170D/.85, 4px GOLD left bar, GOLD text.
  - Focused: outline inset 1, SKY/.8, 1.5. If not selected, bg #12171F/.8 and SKY text.
  - Idle: TEXT_DIM.
- VRule 40 wide.
- Right column 1000 wide, separation 6:
  - Head Cinzel 700, 32px, GOLD, letter-spacing 4 (height 44).
  - Sub Alegreya-Italic 20px, TEXT_DIM (height 28).
  - Divider 26.
  - Page area 1000×540, VBox separation 14.
- Row: label Alegreya 500, 28px, TEXT, width 270; separation 16.
- Choice button: 190×71 measured, Alegreya 600, 25px. Toggle group.
  - normal: bg #0F1217/.9, border #665942/.7 width 1, shadow black/.2 size 4.
  - hover: bg #141A21/.95, border SKY_DEEP 2, shadow SKY/.25 size 8.
  - focus: same bg, border SKY 2, shadow SKY/.35 size 10.
  - pressed: bg #1F170D/.95, border GOLD 2, shadow GOLD/.25 size 8.
  - hover+pressed: same, shadow GOLD/.3 size 10.
  - Pressed text GOLD. Radius 3.
- Slider row: height 40, slider 560 wide, value 0..1 step .05.
  - Track 8px, #1F1F24, radius 3. Fill GOLD_DIM, same radius.
  - Grabber is Godot's default icon: pale grey circle about 14px in the render. Code sets no custom focus style.
- Note text: Alegreya-Italic 20px, TEXT_DIM, wrap width 960.

**Sections and defaults**

| Section (sub) | Control | Values and effect | Default |
|---|---|---|---|
| Oyun (`Kamera, dönüş hızı ve tuş ipuçları`) | `Kamera dönüş hızı` slider | 0..1 → 60..160 deg/s | .5 |
| | `Fare hassasiyeti` slider | 0..1 → .1...5 deg/px | .5 |
| | `Kamera takibi` | `Yumuşak` 3.5, `Normal` 5.5, `Sıkı` 9 | Normal |
| | `Görüş açısı` | `Dar` 37.76°, `Normal` 41.76°, `Geniş` 47.76° | Normal |
| | `Tuş ipuçları` | `Açık` / `Kapalı` | Açık |
| Dil (`Arayüzün dili`) | `Arayüz dili` | `Türkçe` | Türkçe |
| Görüntü (`Pencere ya da tam ekran, çözünürlük, dikey eşitleme ve arayüz ölçeği`) | `Ekran` (not on web) | `Pencere` / `Tam ekran` | Pencere |
| | `Çözünürlük` dropdown (not on web) | `Ekranı kapla`, `1280 × 720   ·   HD`, `1366 × 768`, `1600 × 900   ·   HD+`, `1920 × 1080   ·   Full HD`, `2560 × 1440   ·   2K · QHD`, `3840 × 2160   ·   4K · UHD`. Unfit: `   (ekrana sığmaz)` suffix, disabled. | Ekranı kapla |
| | `Dikey eşitleme` (not on web) | Açık / Kapalı | Açık |
| | `Boyalı görünüm` | Açık / Kapalı | Açık |
| | `Arayüz ölçeği` | `%80`, `%90`, `%100` | %100 |
| Ses (`Ana ses, müzik, efektler ve ortam`) | `Ana ses`, `Müzik`, `Efektler`, `Ortam sesi` sliders | Bus volume; muted at ≤.001; Efektler plays hover on change | 1 |

**Notes** (verbatim)
- Oyun: `Kamera ayarları serbest gezintideki takip kamerasına uygulanır; fare hassasiyeti sağ tıkla sürüklerken geçerlidir.`
- Dil: `Tanhu 3 şimdilik yalnızca Türkçe oynanır; bütün yazılar Türkçedir.`
- Görüntü (below the scale row): `Arayüz ölçeği menüleri ve kartları küçültür.`
- Resolution note, below the dropdown:
  - Fullscreen: `Tam ekranda oyun ekranın tamamını, kendi keskinliğinde kaplar (%d × %d). Çözünürlük arayüzün boyutunu belirler: 2K'da menüler daha küçük ve ince görünür.`
  - Fill: `Pencere ekranın kullanılabilir alanını kaplar. Belli bir boyut seçilirse o boyutta, gerçek pikselle açılır.`
  - Fixed: `Pencere seçilen çözünürlükte, gerçek pikselle açılır. Çözünürlük yükseldikçe arayüz küçülür.`

**Dropdown**
- 520×71, `   ` text prefix.
- Chevron at (w-26,h/2), d7, stroke 2, GOLD, or SKY on focus/hover. Flips when open.
- List panel: bg #080A0F, border GOLD_DIM 2, shadow black/.6 size 16, separation 4, rows 464×46. Alegreya 500, 24px.
- Selected text GOLD. Highlight bg #141A24, border SKY 1, radius 2, left margin 12. Disabled text TEXT_DIM/.45.
- Opens below +4, flips up if it would overflow.
- Outside click or Esc closes. Other keys close it first.

**Navigation**
- Moving focus in the sidebar switches section immediately, with hover sound.
- Right enters the first control of the section. Left from the first column returns to the sidebar.
- Z/C cycles sections with hover sound.
- Last section and last controls view persist for the session.
- Settings save when the page closes.

### Controls page (scripts/ui/controls_page.gd)

**View buttons:** 190×60, separation 14, centered, y 6.
- Glyph at (36,h/2) s12. AlegreyaSC 21px, letter-spacing 1, at x=64.
- Active: bg #1F170D/.9, border GOLD 2.
- Idle: bg #080A0F/.85, border GOLD_DIM/.6 width 1.
- Hover: border and text SKY.
- Labels `Liste`, `Klavye`, `Oyun kolu`. Z/C cycles. Holder starts y=78.

**List view:** 3 cards side by side, separation 28, centered.
- Card 560 wide: bg #06070B/.92, border GOLD_DIM/.8 width 1, shadow black/.4 size 12; inner margin 22/14/16 plus the 28/18 stylebox; VBox separation 8.
- Header: Cinzel 700, 21px, GOLD, letter-spacing 4. Rule 1px GOLD/.25.
- Rows height 36: Alegreya 500, 20px, PARCHMENT.
- Keycaps 32 tall, gap 6.
- Pad pills 32 tall, radius 16, bg #0A121A/.95, border SKY/.7 width 1, Cinzel 700, 15px, SKY, width `max(34, textW+18)`.
- Divider between keys and pads: 1px at x+6, TEXT_DIM/.4; pills start 18 px after keys.

Rows (real values):
- **YÜRÜRKEN**
  - `Yürü`: `W A S D`, `↑ ↓ ← →`
  - `Koş (basılı tut)`: `Shift`
  - `Kamerayı döndür`: `Q`,`E`
  - `Kamerayı sürükle`: `Sağ tık`
  - `Yakınlaş / uzaklaş`: `Tekerlek`
  - `Oyun menüsü`: `Esc` | pad `Start`
- **KARAKTER OLUŞTURMA**
  - `Satır seç`: `W`,`S`,`↑`,`↓`
  - `Değeri değiştir`: `A`,`D`,`←`,`→`
  - `Onayla`: `E`,`Enter`
  - `Geri al`: `Esc`
  - `Karakteri döndür`: `Sürükle`
  - `Yakın plan`: `Tab`,`Tekerlek`
- **MENÜ**
  - `Seç`: `Enter`,`Boşluk` | `A`
  - `Geri / kapat`: `Esc` | `B`
  - `Butonlarda gezin`: `↑ ↓ ← →` | `✣`,`L`
  - `Menüde sayfa çevir`: `Q`,`E` | `LB`,`RB`
  - `Bölüm / görünüm değiştir`: `Z`,`C`
  - `Oyunda kaydet / yükle`: `F5`,`F9`
  - `Tam ekran`: `F11`

**Keyboard view**
- `units=(18.5,6.35)`, `u=floor(min((W-60)/18.5,(H-90)/6.35))`. u=100 on the 1920×814 holder.
- Origin `((W-18.5u)/2, 6)`, gap `.08u`. Row y `ri*u`, plus `.35u` for ri>0.
- Rows in key units:
  - R0: Esc 1, gap 1, F1-F4, gap .5, F5-F8, gap .5, F9-F12
  - R1: `` ` `` 1-0 - = (1 each), ⌫ 2
  - R2: Tab 1.5, Q..P [ ] (1 each), \ 1.5
  - R3: Caps 1.75, A..L ; ' (1 each), Enter 2.25
  - R4: Shift 2.25, Z..M , . / (1 each), Shift 2.75
  - R5: Ctrl 1.25, Alt 1.25, Cmd 1.25, Boşluk 6.25, Cmd 1.25, Alt 1.25, blank 1.25, Ctrl 1.25
  - Arrows block x=15.5+col: ↑ (col 1, row 4); ← ↓ → (cols 0-2, row 5)
- Cap: shadow +3y black/.45.
  - Unused: fill #0A0D12/.92, border GOLD_DIM/.55 at α.5, width 1.
  - Used: fill `groupColor*.16`/.95, border group color/.9, width 1.5.
  - Text: Cinzel 700, `int(.22u)`, at (x+7, y+fs+4), PARCHMENT .95 used, .4 unused.
  - Dots: r3.5 per distinct group, from `end.x-9` stepping -10, y+9.
  - Use lines: Alegreya 500, `int(clamp(.165u,11,15))`, max 3, bottom-anchored `end.y-6`, PARCHMENT/.92.
  - Cap color comes from the first use.
- Group colors: foot #D9B56C, creator #7FE3FF, menu #EFE2C4.
- Uses:
  - A `Sol`, D `Sağ`, W `Yukarı`, S `Aşağı` (foot)
  - Shift `Koş` (foot)
  - C, Z `Bölüm` (menu)
  - Up `Yukarı`+`Gezin`, Down `Aşağı`+`Gezin`, Left `Sol`+`Gezin`, Right `Sağ`+`Gezin`
  - E `Kamera`,`Onayla`,`Sayfa`
  - Q `Kamera`,`Sayfa`
  - Enter `Onayla`,`Seç`
  - Escape `Menü`,`Geri al`,`Geri`
  - F11 `Tam ekran`, F5 `Kaydet`, F9 `Yükle`, Space `Seç`
- Legend at y=origin+6.35u+22: dots r6, labels AlegreyaSC 19px `YÜRÜRKEN`,`KARAKTER OLUŞTURMA`,`MENÜ`. Right note Alegreya-Italic 19px, TEXT_DIM: `Fare: tıkla, sağ tıkla sürükle, tekerlekle yakınlaş`.

**Pad view** (controls_page.gd:459-541)
- `k=min(1,W/1500,H/640)`, `c=(W/2,H/2-10)`.
- Body #13161D, outline GOLD_DIM/.9 width 2, from merging:
  - round-rect (-330,-140,660,250), r90
  - circles (∓230,40) r150
  - circles (∓175,160) r105
- Bumpers: rect (±250-60,-205,120,56) #0F1217 r14; (±250-85,-160,170,44) #12141A r16.
- Sticks: L(-230,-10), R(120,80); well r52 #08090D with rim, cap r34 #1C1F26.
- D-pad at (-120,80): 4 squares 32 at offset 26, r5.
- Face at (230,-10): r24, fill #0D0F14, stroke 2.5, Cinzel 22: Y(0,-46) #C7B25B, A(0,46) #5FAE6B, X(-46,0) #5B8FC7, B(46,0) #C75B5B.
- Back(-60,-60), Start(60,-60): 44×24 r12.
- Callouts: left x=c-430k: LB, LS (`Sol çubuk`), DPAD (`Yön tuşları`). Right x=c+430k: RB, Start, B, A. Row pitch 68, top `c.y-(n-1)*34`.
- Polyline anchor→(anchor.x±30k,y)→(x,y), group color/.55, width 1.5; dot r4.
- Pill height 30, r14, Cinzel 700, 16px. Text Alegreya 500, 20px, PARCHMENT, separated by ` · `.
- Texts: LB,RB `Sayfa`; LS,DPAD `Gezin`; Start `Menü`; B `Geri`; A `Seç`.

### General page (scripts/ui/general_page.gd), game mode only
- HBox separation 64, centered in content; measured 1236×538.
- Column separation 14: KnotButton font 30, 560×78: `DEVAM ET`, `KAYDET`, `YÜKLE`, `AYARLAR`, `ANA MENÜ`, `MASAÜSTÜNE DÖN`. Up/down wrap over enabled buttons; left/right stay.
- Card (measured 612×538): bg #06070B/.93, border GOLD_DIM/.85 width 1, shadow black/.45 size 14, inner margin 28/22/24, separation 8.
  - `YOLCULUK`: AlegreyaSC 18px, GOLD/.85, letter-spacing 3.
  - Place: Cinzel 700, 30px, GOLD, letter-spacing 2.
  - `Gece Kampı  ·  Ay ışığında bir bozkır gecesi`: Alegreya-Italic 20px, SKY.
  - Divider 24.
  - Facts, Alegreya 21px, key in #A79D88, value in TEXT: `Oynanan süre  12 dk`, `Destan  4 / 7`, `Kişiler  7 / 7`, `Taşlar  2 / 5`.
- Quit confirm: `Oyundan çıkıp masaüstüne dönülsün mü? Yolculuğun otomatik kayda yazılır.`

### Save and load (scripts/ui/save_load_panel.gd, scripts/save/*)
- Dim black/.64. OrnateFrame margin 34, VBox separation 12. α→1 .18 s. Scaled k, centered.
- Measured panel: load 1686×978.4, save 1686×854.4.
- Title `Kaydet` or `Yükle`: Cinzel 700, 44px, GOLD, letter-spacing 6, centered (height 60).
- Divider 26.
- Load only: auto card centered.
- Grid 2 columns, h 18, v 10. Slots 1-10, then `GERİ` KnotButton font 30, 340×78, centered.
- SlotCard 800×112, inner margin 10, separation 16:
  - Thumb frame 148×85: bg #050609, border GOLD_DIM 1, padding 2. Empty `◇`, Cinzel 34px, GOLD_DIM/.8.
  - Title: Alegreya 600, 24px, PARCHMENT, ellipsis. Empty: `Boş yuva`, TEXT_DIM.
  - Sub: AlegreyaSC 17px, GOLD, letter-spacing 1.
  - Meta: Alegreya-Italic 16px, TEXT_DIM.
  - Number: `A` or 1-10, Cinzel 700, 30px, GOLD/.8, width 46.
  - normal: bg #0B0E14/.9, border #736142/.75 width 2, shadow black/.4 size 8.
  - hot: bg #0F171F/.97, border SKY 3, shadow SKY/.45 size 18.
  - disabled: bg #0A0B0F/.55, border #4C4538/.45, shadow black/.25 size 4.
- Behavior:
  - Empty slots are disabled in load mode. Mouse enter focuses.
  - Focus plays hover, press plays click.
  - Overwrite: `Bu kaydın üzerine yazılsın mı?`
  - In-game load: `Kaydedilmemiş ilerleme kaybolacak. Yüklensin mi?`
- Data: slot 0 = auto, 1..10 manual. Files `tanhu3_save_N.json`, `tanhu3_thumb_N.png` (320×180, center-cropped 16:9).
- Record fields: `version:1, game:"tanhu3", save_no, saved_at (local ISO), saved_unix, play_time, profile{body_type,skin,hairstyle,hair_color,beard,moustache,eyes,eye_color}, position[x,y,z], yaw, place, flags`.
- `save_no` is max(manual)+1; 0 for auto. Latest slot = max saved_unix. Corrupt file counts as empty.
- Formats:
  - Title `Ocak başı #3` or `Otomatik kayıt · Ocak başı`.
  - Place `Gece Kampı · Ocak başı`.
  - Meta `0 sa 05 dk  ·  26.10.2026  06:53`.
- Places: ocak `Ocak başı` (≤4.8 m from fire), ahir `Ahırın önü`, yamac `Göle bakan yamaç`, kume `Dikili kayalar`, kaya `Yosunlu kayalar`, kamp `Yurtların arası` (≤14 m), cayir `Çayır`.

### Confirm dialog (scripts/ui/confirm_dialog.gd)
- Dim black/.62. OrnateFrame margin 38, separation 26, scaled k, centered, no fade.
- Text: Alegreya 500, 34px, PARCHMENT, centered, wrap 760.
- Buttons `EVET`, `HAYIR`: KnotButton font 30, 280×78 measured, separation 30.
- Focus starts on HAYIR quietly. Left/right toggle; up/down stay. Esc or Start = no.
- Measured 836×261.8 for the two-line question.

### Destan Kitabı (destan_kitabi.gd, destan_kitabi_page.gd, journey_flags.gd)

**Layout** (measured panel about 1408×695, margin 34)
- Left 420 wide, separation 6:
  - Caption Cinzel 700, 22px, GOLD/.8, letter-spacing 6, height 40. Shows `DESTAN KITABI` (dotless I, from `to_upper`).
  - Count Alegreya-Italic 19px, TEXT_DIM: `Destan  ·  4 / 7 açıldı`.
  - List scroll 420×560, separation 4.
  - Group label: uppercase, Cinzel 700, 16px, GOLD/.75, letter-spacing 3, height 34, bottom-aligned.
  - Entry 420×50: Alegreya 600, 25px at x=22, baseline h/2+9. Same selected and focused treatment as SideButton, idle PARCHMENT.
- VRule 40 wide.
- Right 880 wide, separation 6:
  - Title Cinzel 700, 34px, GOLD, letter-spacing 4.
  - Sub Alegreya-Italic 21px, SKY. Hidden if empty. Destan sub is `Ozanın dilinden`.
  - Divider 26.
  - Text scroll 880×520: Alegreya 26px, PARCHMENT, line_separation 10. Destan bodies italic.
- Empty chapter: chapter title plus italic `Bu sayfalar henüz boş. Yolculuk ilerledikçe dolacak.`
- Up/down selects and opens immediately. Mouse enter focuses.

**Flags:** `ilk_gezinti` first roam; `ates_basi` ≤3 m from fire; `ahir_ziyaret` ≤6.5 m from stable; `yosunlu_kaya` boulder of size≥2, radius size/2+.6; `kaya_kumesi` formation, radius 5.5×scale; `gol_yamaci` ≥22 m from camp, bearing -60..+25° from -Z. Conditions support `a`, `!a`, `a || b`, `a && b`. People and stones: `*` always; empty never.

**Destan verses** (id, unlock condition, title, text):

`ocak_basinda`, always, **Ocak Başında**
```
Ay doğdu bozkırın üstüne, gümüş aktı çimenlere;
İki yurt, bir ocak, beş can oturdu ateş önüne.
Yaşlı ozan dombırayı aldı, kor uyandı külünden;
“Dinleyin,” dedi, “bu gece destan akar dilimden.”
```
`ilk_adim`, `ilk_gezinti`, **İlk Adım**
```
Bir yiğit kalktı ocaktan, ayağı toprağa değdi;
Çimen eğildi önünde, patika ona yol verdi.
Ay yukarıdan baktı, rüzgâr kulağına eğildi:
“Kamp senin, gece senin; yürü,” dedi. Yürüdü.
```
`atesin_sozu`, `ates_basi`, **Ateşin Sözü**
```
Ateşin başına vardı, alev yüzünü ısıttı;
Kıvılcımlar göğe ağdı, her biri bir yıldız tuttu.
Ana kazanı karıştırdı, çocuk dizine yaslandı;
Ozan teline dokundu, bütün kamp sese boyandı.
```
`ahirda_iki_at`, `ahir_ziyaret`, **Ahırda İki At**
```
Ahırın önüne vardı, iki at başın kaldırdı;
Doru toprağı eşeledi, Ak At yelesin savurdu.
Saman koktu, eyer koktu, uzak yolların tozu;
Atlar dedi: “Gün doğsun, bekler bizi bozkırın ucu.”
```
`taslarin_dili`, `yosunlu_kaya || kaya_kumesi`, **Taşların Dili**
```
Yosun bağlamış kayaya elini koydu yolcu;
Taş soğuktu, taş sessizdi, taş bilirdi bu yolu.
Kaç kervan geçti önünden, kaç ocak yandı söndü;
Taş susar ama unutmaz: hepsini bağrına gömdü.
```
`gole_bakan_yamac`, `gol_yamaci`, **Göle Bakan Yamaç**
```
Yamacın ucuna vardı, aşağıda göl parladı;
Ay suya indi yıkandı, adacıklar uykuya daldı.
Vadinin dibinde sis vardı, ötede köy ışıkları;
Yolcu dedi: “Dünya geniş; ocağım yine burası.”
```
`gece_biterken`, `ates_basi && ahir_ziyaret && gol_yamaci`, **Gece Biterken**
```
Ocağı gördü, atı gördü, gölü gördü yamaçtan;
Gece döndü kampın üstünde, ağır ağır, yavaştan.
Ozan son telini çekti, kor kızardı, yıldız kaydı;
Destan burada bitmedi: şafakta yine yol açıldı.
```

**Kişiler:** groups `Ocak Halkı`, `Atlar`. First five `*`; horses `ahir_ziyaret`.
- `mete` **Mete**, `Hun okçusu, kampın yiğidi`: Yayı omzundan hiç inmez. Ateşin başında oturur ama gözü hep karanlıktadır; bozkırda bir dal kırılsa ilk o duyar. İlk yayını yedi yaşında eline almış, ilk okunu kendisi yontmuş. Hunlar ona “rüzgârı vuran” der.
- `ana` **Ana**, `Ocağın anası`: Kazan onun elinde kaynar, yurt onun elinde ısınır. Kampın bütün hikâyelerini bilir ama anlatmaz; yalnızca gülümser ve çorbayı karıştırır. Kimse aç uyumaz, kimse üşümez: Ana buna bakar.
- `baba` **Baba**, `Obanın direği`: Kampı kuran, atları güden, yurtların kazığını çakan odur. Az konuşur, çok dinler. Ozan destana başlayınca başını eğer; çünkü o destanlarda kendi babası da vardır.
- `cocuk` **Çocuk**, `Kampın en küçüğü`: Uykusu gelse bile ateşten kalkmaz; ozanın her sözünü ezberlemek ister. Bir gün kendi dombırası olacak, kendi destanını söyleyecek. Şimdilik Ana'nın dizine yaslanıp kıvılcımları sayıyor.
- `ozan` **Yaşlı Ozan**, `Dombıranın sahibi, sözün bekçisi`: Saçı ak, sesi ince ama kesindir. Dombırasının iki teli kırk yılın sözünü taşır. Bu kitabın dizeleri onun dilinden düştü; o söylemese bu gece de öbür geceler gibi unutulurdu.
- `doru` **Doru At**, `Kampın sabırlı yük atı`: Kızıl kahve donlu, alnı akıtmalı. Yurdun keçelerini, kazanı, odunları o taşır. Sabırlıdır; Ak At'ın yanında durunca gölgesi gibi görünür. Saman uzatana başını eğer, karşılığında burnunu omzuna dayar.
- `ak_at` **Ak At**, `Bozkırın rüzgârı`: Gecede bile parlayan ak bir at. Yelesi ay ışığında gümüş gibi dalgalanır. Mete'den başkasını sırtına zor alır; ama Çocuk ona elma uzatınca bütün huysuzluğu geçer.

**Taşlar:** group, unlock, then text. No sub line.
- `ocak_taslari` **Ocak Taşları**, group `Kamp`, unlock `ates_basi`: Ateşin çevresine halka hâlinde dizilmiş dere taşları. Her biri başka bir yolculuktan getirilmiş: biri ırmak yatağından, biri dağ geçidinden, biri eski bir höyüğün dibinden. Taşlar ateşi tutar, ateş de kampı.
- `ahir` **Ahır**, `Kamp`, `ahir_ziyaret`: Kalın direklerle kurulmuş, damı otla örtülü bir barınak. İçinde iki at, bir yemlik ve bir fener var. Rüzgâr kuzeyden esince atlar buraya sığınır; gece fenerin ışığı yurtlardan görünür.
- `yosunlu_kayalar` **Yosunlu Kayalar**, `Çevre`, `yosunlu_kaya`: Kampın çevresine serpilmiş iri, yuvarlak granit kayalar. Kuzey yüzlerini yosun tutmuş; çobanlar yönlerini bu yosunlardan bulur. Yaşlı Ozan onlara “devlerin unuttuğu yumurtalar” der.
- `dikili_kayalar` **Dikili Kayalar**, `Çevre`, `kaya_kumesi`: Çayırdan yükselen, dilim dilim yarılmış kaya kümeleri. Rüzgâr aralarından geçerken ıslık çalar. Eskiler bunları sınır taşı sayardı: ötesi başka bir obanın yurduydu.
- `gol` **Göl**, `Çevre`, `gol_yamaci`: Vadinin dibinde, ormanla çevrili uzun bir göl. Ay doğunca suyun üstünde gümüş bir yol açılır. Adacıklarında ışıklar yanar; kimin yaktığını kimse bilmez. Göle bakan yamaç, kampın en sessiz yeridir.

### HUD (scripts/ui/game_hud.gd, scenes/ui/game_hud.tscn, ui/menu_theme.tres)
- Bottom-left, x 34, y `ch-88`. Measured 814×54. Scaled k around that corner.
- Brush background: padding 4, seed 3.3, ink #0A1026/.82, rim cream α.2, no overscan.
- Panel padding 34/14/38/15. Row separation 14, pair separation 8.
- Pairs: `WASD` `Yürü`; `Shift` `Koş`; `Q/E` `Kamerayı döndür`; `Tekerlek` `Yakınlaş`; `Esc` `Menü`.
- Key chip: Palatino stack, emboldened, 14px, #0F142B; bg #F2EAD8/.92, bottom border 2 #B2A185/.95, radius 5, padding 8/1/8/3.
- Action: 17px, #F2EAD8/.92. Separator `·`: 17px, cream/.35.
- Timing: α in .7 s sine-out, rise 10 px over 1.0 s cubic-out, hold 7 s, out 1.4 s sine-in. Quick hide .3 s.

## 5. Character creator (scripts/ui/character_creator.gd, scenes/ui/character_creator.tscn, ui/creator_theme.tres)

The creator uses a different font theme from the menus.

**Layers**
- Full-screen baked painted background.
- Preview area: left 60% of the width (1152 at 1920), a transparent 3D viewport.
- Title banner (top-left, scaled k).
- Parchment panel (right, scaled k).
- World 3D rendering is disabled while it is open.

**Background** (shaders/ui/creator_background.gdshader, bake once): sage-green fBm wash, diagonal dry-brush teal strokes, meander bands, ram-horn spirals, concentric arcs, a soft light behind the character, grain and vignette.
- Colors: base #668C63, light #809E6E, teal #338075, deep #245C52, olive #999961, ochre #8C6B45.
- `stroke_amount .55`, `ornament_strength .68`, `focus_center (.3,.5)`, `focus_strength .14`, `vignette .42`.

**Banner**
- Node at (0,18)-(900,104). Stroke rect (-40,14)-(900,108).
- Brush shader (shaders/ui/creator_brush.gdshader): color #241C1A/.95, seed 7, thickness .8, open_start 1, tail .24, bristle .7.
- Title `KARAKTERİNİ OLUŞTUR` at x 44: 40px, stack `Cinzel, Trajan Pro, Baskerville, Palatino, Palatino Linotype, Book Antiqua, Georgia, serif`, slight embolden, letter-spacing 6, #F2E8D1, shadow black/.35 at (0,2). Measured width 602.
- Subtitle `Tam boy` or `Yakın plan`: separation 22, margin-top 14, 18px, stack `Avenir, Avenir Next, Segoe UI, Helvetica Neue, Arial, sans-serif`, letter-spacing 3, #DBD4BF. Changing: α→0 .12 s, swap, α→1 .2 s.

**Hint**
- x 44..760, y `ch-60..ch-28`: `Sürükleyerek döndür  ·  Tekerlek ya da Tab ile yakınlaştır`.
- 17px sans, letter-spacing 1, #F2F5E6/.8, shadow black/.22 at (0,1).
- Hidden in close-up, .3 s.

**Parchment** (shaders/ui/creator_parchment.gdshader)
- Panel 680×838, right 42, y `ch/2-355..ch/2+483`, measured (1198,185) at 1080. Paper node ±40 → 760×918, margin 40.
- paper #FAF0CF/#EBD9B2, burn #80592B, shadow #031212/.55 offset (7,14) softness 30.
- tear 5, burn_width 22, burn_strength .6, outline .7, seed 4.

**Rows** (scripts/ui/creator_row.gd): VBox at y 26, width 680, separation 0. Plain rows 58 tall, color rows 108 tall; total 614.
- Columns: marker x 46, label x 68, left arrow x 262, right arrow x 606, value box 282..586 centered, first swatch center x 226, swatch strip y 50.
- Label: 16px sans, letter-spacing 3, #736659; focused lerps to #B84736 (about .2 s).
- Marker: triangle 7×9, #2E4C4F, slides in 6 px.
- Value: 25px, stack `Avenir Next, Segoe UI, Helvetica Neue, Arial, sans-serif`, bold, #362E29.
- Change: value offset ±16→0 .22 s cubic-out, α .25→1 .18 s; arrow nudge 4 px.
- Locked row: α .5, arrows and swatches hidden, value `Modelde çizili`, skipped by focus.
- Arrow: hit 38×42, triangle 12×15, hover grows ×1.2. Colors #268794, hover #33ABB8, pressed #1A6670.
- Swatches: r15, spacing 38, padding 8.
  - Ring gap 4.5, stroke 2.4, #245454; slides with exp rate 16.
  - Hover r+1.5, hover ring #268794/.75.
  - Natural swatch: fill #F7F2E6, rings #66615C at r-1.2 and .56r, stroke 1.6.
  - Bead: `color.darkened(.28)` r; color r-1.6 at (-.6,-.8); white/.13 r*.5 at (-.22r,-.26r); white/.22 r*.22 at (-.3r,-.36r).

**Options** (scripts/character/character_options.gd)

| Label | Values |
|---|---|
| `VÜCUT TİPİ` | `Tip 1`, `Tip 2` |
| `TEN` | `Doğal`, `Süt` #FFE6D4, `Şeftali` #FAD1B2, `Bal` #EDBD99, `Buğday` #D9A37A, `Bronz` #BD8761, `Kestane` #9E6E4C, `Kahve` #7D543B, `Koyu` #5C3D2B, `Ay ışığı` #EBDBCC |
| `SAÇ MODELİ` | Tip 1: `Topuz ve örgü` (model mete). Tip 2: `Örgülü` (model hero_f) |
| `SAÇ RENGİ` | `Doğal`, `Siyah` #141214, `Kahverengi` #45291A, `Kızıl` #802E1F, `Bakır` #CC6B2E, `Sarı` #DBAD61, `Gri` #9E9EA3, `Beyaz` #F0EDE6, `Yeşil` #548552, `Mor` #6B4C9E, `Mavi` #598CD9 |
| `SAKAL` | `Yok`, `Kısa`, `Gür`, `Uzun` (locked on Meshy models) |
| `BIYIK` | `Yok`, `İnce`, `Gür`, `Uzun` (locked) |
| `GÖZLER` | `Doğal`, `Yuvarlak`, `Badem`, `Uykulu` (locked) |
| `GÖZ RENGİ` | `Doğal`, `Koyu kahve` #3D2414, `Kehribar` #9E6B24, `Zeytin` #616B33, `Turkuaz` #1F806B, `Mavi` #336BC7, `Gri` #6B8099, `Mor` #734CA6, `Kırmızı` #B22929 |

**Buttons** (scripts/ui/creator_brush_button.gd)
- Undo at panel (116,668), 220×62: chip `Esc`, `Geri Al`, stroke #2B2421, seed 3.
- Accept at (380,668), 252×62: chip `E`, `Onayla`, stroke #267075, seed 11.
- Brush: thickness .68, tail .3, rect ±10.
- Text: 25px bold sans, letter-spacing 1, #F7F0DE, shadow black/.25 at (0,1).
- Chip: bg #E0DBD1, radius 5, padding 7/1, shadow black/.3 size 2 offset (0,1.5). Text 16px bold, #332E2B. Row separation 12.
- Hover/press: `h` moves at 4.5/s, `p` at 7/s. `scale = 1+.045*ease(h,-1.8)-.06*p`. Shader `hover = ease*.8+p*.2`, where `col=mix(col,col*1.25+.05,hover)`.

**Open animation:** preview α .7 s; banner α .6 s delay .1; panel x 56→0 .6 s delay .08; α .45 s delay .08. All cubic-out.

**Turntable** (scripts/ui/creator_turntable.gd, scenes/ui/creator_turntable.tscn)
- Camera FOV 30, near .05.
- Key light: directional, #FFF0DB, energy .66, shadows.
- Rim light: #9ECCFF, energy .2.
- Ambient: #A3B8D1, energy .24. Contrast 1.03.
- Film grade (`ColorGrade.creator()`, color_grade.gd):
  - Per channel: `lift+c*(gain-lift)`, lift (.187,.163,.141), gain (.967,.943,.921).
  - Then `l=luma, mid=4l(1-l), r+=.006*mid, b-=.012*mid`.
- Ground shadow: plane 1.25×.95 at y .004. Core α .7, r .5. Halo α .34. Color #051A17 (shaders/ui/creator_ground_shadow.gdshader).
- Start yaw 18°. Drag `yaw += dx*.0105/renderScale`, follow rate 9 (`1-exp(-9dt)`). Double-click returns to 18°.
- Wheel up or trackpad up → close. Wheel down → full. Tab toggles. Pinch >1.02 close, <.98 full. Zoom rate 6, smoothstep on position and target.
- Frames:
  - Full: fill .8, center .535, elevation 5°.
  - Close: view height .7 × height/1.75, face `head+(h-head)*.35`, center .46, elevation 3°.
  - Mete: full pos (0,1.3596,4.2291) → target (0,.9896,0); close pos (0,1.6794,1.3566) → target (0,1.6083,0).
  - hero_f: full (0,1.2550,3.9037) → (0,.9135,0); close (0,1.5629,1.2523) → (0,1.4972,0).
- Model swap: pivot scale .93→1, .4 s back-out. Idle clip plays.

**Controls and confirm flow**
- ↑/↓ or W/S move row (wrap, skip locked), hover sound. ←/→ or A/D change value.
- E, Enter or NumpadEnter accept. Esc undo. Tab toggles view. Pad d-pad/stick: one step per push. A accept, B undo.
- Direction keys auto-repeat. Accept, undo and view do not.
- History max 64. Undo restores, focuses the changed row and bumps it, click sound.
- Esc with empty history emits cancel.
- Accept: whoosh and emit a profile copy.
- Hover sounds are rate-limited to one per 60 ms.

## 6. Logo description (redraw only, do not copy assets/title/logo.png)

**Canvas and in-menu size:** 1935×771 RGBA with a transparent background. Drawn at 753×300 before lk, so 553.5×220.6 at lk .7352.

**Silhouette key points** (x,y) measured from the alpha:
- **T:** 8,9 439,10 445,20 398,173 353,139 295,130 297,444 312,489 229,611 140,488 154,457 157,128 114,139 46,180 34,93
- **A:** 693,19 703,25 676,83 675,112 760,482 786,550 609,551 636,496 627,435 523,433 513,495 537,552 355,553 383,494 492,104 465,21. See-through counter triangle 579,206 605,326 552,325.
- **N:** 785,20 909,20 1014,235 1017,97 985,24 1174,22 1142,108 1136,617 1037,517 924,324 924,484 949,549 789,547 805,482 807,94
- **H:** 1382,20 1557,22 1528,98 1528,478 1557,549 1376,550 1408,479 1409,331 1333,330 1330,479 1356,549 1178,550 1208,489 1210,411 1210,94 1183,22 1358,21 1333,87 1332,221 1406,224 1408,93
- **U:** 1561,21 1727,24 1706,96 1707,423 1739,453 1775,430 1780,380 1782,118 1776,71 1752,25 1923,23 1901,93 1904,489 1738,608 1581,487 1587,103

**Letterform:** heavy flared display serif with concave flared terminals. T, N and U end in sharp spear or chevron points below the baseline (y 608-617 versus baseline about 550). T's bar has slanted downward-pointing ends.

**Metal construction**
- Each letter is a raised, hammered-gold frame around a sunken panel.
- Outer chamfer about 28-32 px wide, each face a separate flat facet.
- A thin near-white rim line (2-3 px, #FFF8D4 to #FEF5AD) sits where bevel meets recess.
- Facet tones: top faces brightest (#F9D057 to #FDFDFF highlights); one vertical face mid (#B57727 to #E38512), the other brighter then dark at the outer edge (#FDB130 to #812A00).
- Fine scratch and hammer texture on all gold.
- Overall tone ramp by luminance: #1C0500, #421701, #692C02, #995109, #DD9227, #F9D874, #FCFAD8. Mean #9D6726.
- Recess: granulated dark bronze, #381201 to #773907, peppered with small gold granules.

**Outline and glow:** no outer glow. Only a 2-4 px dark red-brown fringe (#5A1901, about α.8) at the alpha edge.

**Ornament** (Scythian animal style, raised gold on the panels)
- Thick S-curve vines with bead clusters.
- **T:** two bird heads facing a red gem at the bar's center; a vine down the stem; a deer head near the bottom, looking down-right, with long ears.
- **A:** bird heads at top; a deer head along the crossbar facing right.
- **N:** peacock-like bird with beaded crest at top-left; a leaping deer whose head is at about (900,290); a second head diving down the diagonal.
- **H:** birds atop both stems; horse heads facing inward at the crossbar ends.
- **U:** birds atop both stems; two deer heads facing the center at the base.

**Gems** (cabochons, center x,y, diameter). Each has a ring of tiny gold beads and a soft white specular near the top.
- Teal (center #017782, mid #08A7A5, rim #0E391F, specular #BFF7F7):
  - T 207,201,29
  - A 530,154,27 / 584,104,16 / 491,322,28 / 704,479,30
  - N 1064,214,27 / 854,363,26
  - H 1457,139,25 / 1278,378,27 / 1461,386,26
  - U 1645,132,25 / 1849,139,25 / 1652,305,22 / 1842,307,23 / 1635,441,25
- Red (center #900800, rim #290000, specular #F6CDD0):
  - T 222,67,40 / 243,315,31
  - A 576,142,37 / 663,276,33 / 434,487,32
  - N 874,475,31 / 1084,484,36
  - H 1285,181,30 / 1484,217,28 / 1369,275,32 / 1257,480,31 / 1480,481,31
  - U 1660,270,27 / 1831,270,27 / 1860,427,24 / 1744,517,38
  - Spear 947,601,23 / 1004,616,26 / 1065,681,38

**Spear** (below the letters, y 565-745)
- Horizontal gold shaft about y 651-685, bright top edge, dark brown lower side.
- Shaft segments x 407-816 and 1144-1544. Band collars x 366-403 and 1548-1586 (y about 637-703), inner collars x 788-816 and 1118-1144.
- Arrowheads: tips (72,668) and (1863,669), base corners (337,603)/(337,741) and (1610,602)/(1613,740).
- Head has a center ridge with bright upper facet and shaded lower facet, a dark V-shaped cut toward the shaft, and diamond-shaped rear wings.
- Center: recumbent stag facing left, head about (815-900,640), legs folded y 700-745, haunch curling around the big red gem. Its antlers sweep back into 3-4 bird-headed tines rising to y 565, with the two small red gems between them.

## 7. Menu camera (scripts/camera/menu_camera.gd, scenes/main.tscn:19, tools/menu_camera_fit.json)

- Pose:
  - Position (0.2733, 8.3867, 13.8634), yaw 0, pitch -23.3477° (looks along -Z).
  - Fire at the world origin. 16:9 vertical FOV 41.76. Near .05, far 6000.
  - Forward (0,-.39635,-.9181). View center hits the ground at about (0.27,0,-5.56).
  - Fit target `assets/_reference/menu_camp.png` (1672×941). Its painted center `TANHU` wordmark is only reference art.
  - Layout anchors: yurt_left (-6.18,-4.31), yurt_right (6.64,-7.26), stable (13.76,-14.65).
- Aspect: if aspect ≥16:9 keep vertical FOV. If narrower, keep horizontal FOV (`hfov=2*atan(tan(vfov/2)*16/9)`).
- Motion (each frame while drifting), with `weight=smoothstep(0,2.5,t)`:
```js
offset = (sin(t*.18*TAU)*A, sin(t*.18*TAU*.7+1.3)*A*.5, 0)  // A=.06*weight, camera-local
parallax = lerp(parallax, mouseNorm[-1..1], clamp(dt*1.5,0,1))
yaw = -parallax.x*weight*1.2deg; pitch = -parallax.y*weight*.6deg
basis = base * Ry(yaw) * Rx(pitch)
```
- To free roam (scripts/player/follow_camera.gd):
  - `drifting=false`. Follow camera blends over 1.6 s, `w=smoothstep(0,1,b)`, interpolating transform and vertical FOV from the menu camera.
  - Follow pose: focus = player + y .7, pitch 23.35°, distance 27, yaw 0, FOV 41.76, follow sharpness 5.5.
  - Default spawn target camera position is about (2.6,11.40,27.99), so the angle stays the same and the camera slides back.
  - Follow settings: distance 6-40, zoom step 1.8, zoom tilt ±6°, Q/E rotation 110°/s, ground clearance 1.2.
- Back to menu: copy game camera transform, `fly_to(menu,1.7)` sine in-out with vertical FOV lerp, then `t=0` and drifting restarts.

## 8. Mete evaluation

**Look** (concept mete.png 1024×1536, A-pose on grey; style_mete.png 1086×1448, 3/4 pose)
- Young Hun archer, tan skin (`skin_base` #CE9264), dark brown hair (#36231B) in a top-knot with bronze tie, loose strands, two long thin braids over the chest.
- Thin moustache, small goatee, stern brown eyes.
- Oxblood crimson cape wrapped over one shoulder, with shaggy tan fur trim, red meander hem, frayed edge, large round bronze brooch.
- Sand-beige long tunic with crimson Greek-key bands at sleeves and hem.
- Dark steel lamellar cuirass laced in brown and red, plus matching hip tassets.
- Crimson waist sash with a fringed front drop, leather belt with two round bronze plaques.
- Studded dark-leather bracers with fur at the wrist. Baggy charcoal trousers. Tall brown fold-cuff boots.
- style_mete adds a recurve bow, an arrow quiver and a scabbard on a painted teal meander background. Those are not in the model. The camp bow is a separate prop.

**Other concepts**
- child.png: cheerful girl about seven with short dark braids tied in red, cream tunic with red meander bands, fur-trimmed red vest, fringed red sash, dark trousers, tasselled felt boots.
- elder.png: smiling old storyteller, white felt kalpak with feather, long white beard, blue-grey robe with silver fur and woven diamond borders, cream tunic, bronze-plaqued belt, dark trousers, fold-cuff boots. Transparent background.

**assets/characters/mete/mete.glb** (11.6 MB)
- 60,592 tris, 109,337 verts, one doubleSided material (metallic 0, roughness .8), 4096² JPEG (3.03 MB).
- Bounds x ±.857, y 0-1.82, z ±.289. Armature scale .01, so bones are in cm.
- Skin has 24 joints: `Hips, Spine02, Spine01, Spine, neck, Head, head_end, headfront, LeftShoulder, LeftArm, LeftForeArm, LeftHand, RightShoulder, RightArm, RightForeArm, RightHand, LeftUpLeg, LeftLeg, LeftFoot, LeftToeBase, RightUpLeg, RightLeg, RightFoot, RightToeBase`.
- Hierarchy: Hips → Spine02 → Spine01 → Spine → neck → Head → head_end/headfront. Both shoulders hang from Spine. Legs hang from Hips.
- Rest transforms are asymmetric (auto-rig). Clips animate 22 joints, excluding head_end and headfront.
- Sidecars: `mete_walk.res`, `mete_run.res`, `mete_sit.res` are Godot-only animations. `mete_regions.png` (2048²) R hair, G skin, B pupil. `mete_regions2.png` R sclera.

**mete_regions.json:** hair #36231B, skin #CE9264, eye #35231C.
Recolor formula: `shade=clamp(lum(col)/max(lum(base),.04),0,2.2); painted=target*shade`. Eye uses target*.8 and mask*.75. Sclera mixes to skin first.

**mete_fit.json**
- height 1.82, head_height 1.539, shoulder_drop 15.8°.
- clip_speed walk 1.47, run 4.74.
- ground_offset idle +.042, walk -.015, run -.03, sit -.057.
- Run threshold = (walk+run)/2 = 3.105 m/s. Rate clamps walk .6-1.8, run .7-1.5. Blend .25 s.
- Non-sit clips have Hips horizontal drift removed (`make_in_place`).
- ShoulderRelax runs after animation: rotate the clavicle by `-drop` around `dir×up`, and move the arm root with it while keeping the arm's basis (shoulder_relax.gd).

**assets/_meshy_raw/mete/**

| File | Clip | Length, keys | Use |
|---|---|---|---|
| mete.glb (39 MB) | none, unrigged, no skin | n/a | y ±.95, 1.9 m |
| mete_rigged_character.glb | `Armature\|clip0\|baselayer` | 1 key | bind pose |
| mete_animation_243.glb | `Armature\|Idle_3\|baselayer` | 10.0 s, 300 | unused |
| mete_animation_244.glb | `Armature\|Idle_4\|baselayer` | 14.0 s, 420 | same clip name and length as the idle embedded in the game GLB |
| mete_animation_363.glb | `Armature\|Sit_Cross_Legged_on_Floor\|baselayer` | 2.533 s, 76 | sit, looped if first and last pose match |
| mete_walking.glb | `Armature\|walking_man\|baselayer` | 1.067 s, 32 | walk |
| mete_walking_armature.glb (90 KB) | same | same | armature-only, cheapest clip source |
| mete_running.glb | `Armature\|running\|baselayer` | .667 s, 20 | run |
| mete_running_armature.glb (80 KB) | same | same | armature-only |

**Evaluation:** bone names are not Mixamo but are consistent, so Three.js can play these clips directly on `mete.glb`. Budget is fine for one hero. Idle and sit live only inside the heavy GLBs, so strip them into separate clip files. In renders the cape and armor match the concept well, but the close-up face is flatter and the eyes narrower than concept.

## 9. Decisions for you

1. **Browser or desktop parity:** the code removes `ÇIKIŞ` and the `Ekran`, `Çözünürlük` and `Dikey eşitleme` rows on web. That moves the layout to logo scale 1 and column x 240. `MASAÜSTÜNE DÖN` has no web gate, so decide what it does.
2. **Browser limits:**
   - Audio autoplay needs a first gesture.
   - F5 must be `preventDefault`ed.
   - Esc exits browser fullscreen before you can intercept it.
   - F11 needs the Fullscreen API.
3. **Text quirk:** the Destan page caption shows `DESTAN KITABI` while the title button shows `DESTAN KİTABI`. "Exact" means keeping the difference. I recommend fixing it to `KİTABI`.
4. **HiDPI size:** Godot-exact k makes the UI small on Retina (for example k≈.55 at 1964 rows). Keep it for parity, or use CSS pixels instead.
5. **Creator fonts:** the creator uses system font stacks, not bundled fonts, so it will vary by OS. Bundle Cinzel and a sans font if you want it identical everywhere.