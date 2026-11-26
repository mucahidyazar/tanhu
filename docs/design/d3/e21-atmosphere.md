# E21'in atmosferi (2026-11-09)

Kullanıcı: «soyledigim gorevleri sirf gorev olsun diye yapma elevenlabs kullanabilirsin atmosfer ve konusmalar istekler anlamli seyler olsun, atmosfere ozellikle dikkat et» (E21, K110). Bu dosya her görevin ışığını, havasını, çevredeki yaşamı ve sesini tarif eder. Sesleri ana oturum ElevenLabs'la üretir (`tools/elevenlabs_audio.sh sfx` ve `music`). Ajanlar kimlikleri bağlar: dosya yoksa yer tutucu çalar (var olan ses ya da kodla basılan), dosya gelince kendiliğinden yerine geçer.

## Yollar ve kurallar
- Döngüler (yatak): `game/audio/ambience/e21/<kimlik>.wav` (22,05 kHz mono, içe aktarmada QOA ve döngü açık); konumlu olanın merkezi ve yarıçapı aşağıda. Tek seferlik sesler: `game/audio/sfx/e21/<kimlik>.wav` (22,05 kHz mono); çeşitli olanlar `_a`, `_b`, `_c` ekiyle, rastgele seçilir, aynısı art arda çalmaz. Müzik: `game/audio/music/e21/<kimlik>.mp3`.
- Kimlik kalıbı: `amb_…` döngü, `sfx_…` tek seferlik, `mus_…` müzik. Ses düzeyi kuralları K78'dir (söz −18 LUFS, söz sürerken müzik ve ortam −3 dB).
- Aynı anda en çok 3 yatak çalar; geçişler 2–4 sn'lik karışmadır. Görünmeyen kaynağın sesi uzakta kısık ve boğuktur (alçak geçiren süzgeç).
- Söz yoktur: yatakların ve kalabalığın içinde anlaşılır söz olmaz (istemlerde «no intelligible words»).

## Önsöz: Göl Obası'nda üç gün (8–10 Nisan MÖ 209)

### Ortak
- **Göl Obası gündüzü.** `amb_camp_spring_day` (Göl Obası'nın merkezi, r 60 m): ilkbahar sabahı vadide uzak tarla kuşu, otta hafif rüzgâr, uzakta at kişnemesi, tezek ateşinin çıtırtısı, ara ara uzak koyun melemesi. Kişiler işindedir: Ana kısrak sağar (at bağında), Baba keçe onarır, Ağabey atları sulamaya götürür, ozan kapıda kopuzunu kurar; duman tündükten yükselir ve rüzgârla eğilir.
- **Göl Obası'nın açık gecesi.** `amb_camp_spring_night` (r 60 m): soğuk açık gece, çok hafif rüzgâr, uzak köpek, ateşin alçak çıtırtısı, uzak bir baykuş, aralarda sessizlik. Yıldızlar parlak, ay yok (K20'nin göğü).
- **Kayın Obası gündüzü.** `amb_birch_camp_day` (Kayın Obası'nın merkezi, r 50 m): derenin yanında küçük oba, uzakta konuşan kadınlar (sözsüz), gülen bir çocuk, ayak vuran at, kayınlarda rüzgâr, bir kez havlayan köpek.
- **Dere.** `amb_stream` (geçit, r 25 m): çakılların üstünden akan küçük berrak dere, yakın şırıltı.
- **Müzik.** Gündüz `mus_prologue_day` (≈60 sn, seyrek tek kopuz, Dorian, uzun sessizlikler; görevler arasında ve yolda, söz sürerken kısılır); gece `mus_prologue_night` (≈45 sn, alçak dron ve seyrek ağız kopuzu). Tipi gecesinde müzik yok: yalnız rüzgâr.

### «Süt»
- Işık: sabah, alçak güneş, vadide yer yer sis, dumanlar dik yükselir; yolda çiğ parlar.
- Yaşam: Kayın Obası'nda saba ahşap çatıda asılı, yanında bir kadın kurut serer; Börü atların arasında oynar; Künay kapıda oturur, eli karnında.
- Ses: yürürken iki tulumdan `sfx_milk_slosh_a/b/c` (adımda bir; koşunca sık ve güçlü), dökülünce `sfx_milk_drip`; geçitte basma taşında `sfx_stream_step_a/b`; sabaya dökerken `sfx_milk_pour`; çalkalarken her vuruşta `sfx_churn_a/b/c`.

### «Tipi»
- Işık: akşam kızıllığı hızla griye döner; tipide görüş ≈25 m, gök ve yer tek renk; tek sıcak ışık köz kabıdır (2,5 m'lik turuncu halka). Kazıkların keçe bayrakları rüzgârda yatay çırpar. Kayın Obası'nın kara yurdu ocak yanınca içten aydınlanır; açık kapıdan sıcak ışık kara düşer.
- Ses: `amb_blizzard_night` (açıkta, her yerde; uluyan ani rüzgârlar, yerde tıslayan kar, derin uğultu); kaya ve yurt ardında `amb_blizzard_lee` (boğuk, tepeden geçen rüzgâr, tıkırdayan kar); köz kabından yakın `amb_ember_pot`; kazığın yanından geçerken `sfx_stake_flap`; uzakta bir kez `sfx_wolf_far`; obaya yaklaşınca `sfx_dog_storm`; ocak tutunca `sfx_fire_rekindle`; yurdun içinde `amb_yurt_storm_inside` (dışarıda boğuk uğultu, çırpan keçe, küçük ateş, sözsüz alçak kadın mırıltıları); kapıda beklerken içeriden `sfx_newborn_cry`; Tonga'nın gelişinde `sfx_horses_storm`.

### «Kuzular»
- Işık: parlak karlı sabah, gölgeler mavi, yurdun keçesinden buhar yükselir, karın kenarları erir; uzak dağlar beyaz.
- Yaşam: Ağabey atları getirir, kır kısrağın yanında yeni tay; karga karda yürür; köpek kuzuları koklar.
- Ses: `amb_snow_morning` (yurttan damlayan eriyen kar, uzak koyun melemesi, karga, hafif esinti); kuzudan `sfx_lamb_bleat_a/b/c` (konumlu, ≈30 m'den duyulur), anadan `sfx_ewe_call_a/b`.

### «Şilde Gecesi» ve «Güreş»
- Işık: açık gök, yıldızlar; Kayın Obası'nda büyük ateş, kıvılcımlar yükselir, oturanların gölgeleri yurtlara düşer; yurt kapıları aydınlık.
- Yaşam: biri davul çalar, biri ağız kopuzu; kadınlar el çırpar; yaşlılar oturur; çocuklar ateşin çevresinde kovalanır; Künay'ın yurdunda beşik ve beşiğe asılı küçük yay; Saruk kımızı sunmadan önce parmaklarıyla göğe, yere ve ocağa serper.
- Ses: `mus_shilde` (≈75 sn: çerçeve davul, ağız kopuzu, el çırpma, sözsüz topluluk ezgisi, açık havada ateş başında; yaklaşınca yükselir); `amb_feast_crowd` (r 30 m: gülüşmeler, sözsüz konuşmalar, çocuk çığlıkları, gürleyen ateş); `sfx_libation` (serpme), `sfx_kumis_sip`; güreşte `sfx_wrestle_scuffle_a/b` (çocukların hırıltısı, otta ayak sürtmesi), `sfx_crowd_cheer`, düşüşte `sfx_child_fall`.

### «Ocak»
- Işık: ikindiden akşama; gün batarken ışık altınlaşır, sonra mavi saat; ilk yıldızlar; ateşin ışığı evre evre genişler (≈2, 4, 7, 10 m), yüzler sırayla ışığa girer.
- Yaşam: Ana kazanı getirir, Baba keçe serer, Ağabey oduna yardım eder; ozan kopuzunu dizine koyar.
- Ses: `amb_dusk_valley` (rüzgâr diner, uzak turnalar, at horlaması, uzakta dere); `sfx_axe_chop_a/b/c`, `sfx_stone_crack`, `sfx_stone_set_a/b`, `sfx_flint_strike_a/b/c`, `sfx_tinder_catch`; ateşin evreleri `amb_fire_small` → `amb_fire_medium` → bugünkü `campfire_loop` (menünün ateşi). Ateş harlanınca müzik yok; sinemanın dronuna geçilir.

## Çocukluk'un iki yeni günü (20–21 Eylül MÖ 228)

### «Çobanlık»
- Işık: sabah çiyi ve serin mavi; öğle parıltısı ve sıcak hava dalgası; ikindi altını ve uzayan gölgeler; gün batımı tepeye değer; akşamüstü dolunay doğuda yükselir (Ç2'nin akşamı).
- Yaşam: sürü yürürken yaşlı koyunun boynundaki küçük tunç çan çalar (çan Mete'nin ileride bileğine bağlanacak çandır: belirgin ama yalnız bir ses); güneye geçen turnalar; gölde ördekler, sazlıktan kalkan kuş, suda halkalar; ufukta Dailin'in dumanları ve uzak atlılar.
- Ses: `amb_ordos_steppe_day` (çekirgeler, yüksekte tarla kuşları, kuru otta sıcak rüzgâr, uzak koyun); `amb_reed_lake` (göl kıyısı, r 60 m: uzun sazlarda rüzgâr, kumlu kıyıya vuran küçük dalgalar, uzak ördekler, kurbağa); `sfx_sheep_bell_a/b` (yaşlı koyun yürürken); suda `sfx_wade_a/b`, yüzerken `amb_child_swim` (yumuşak ritmik şıpırtı), dalışta `sfx_dive_up`; `sfx_kids_laugh_a/b/c`; balçıkta `sfx_mud_pull`; tilkiden `sfx_fox_bark`; turnalardan `sfx_cranes_overhead`; ufuktan `amb_dailin_far` (çok uzak toplanış: soluk davullar, kişneyen atlar, binlerce kişinin uğultusu; ufka doğru konumlu, çok kısık).
- Akşam: `amb_ordos_dusk` (cırcır böcekleri başlar, eve sürülen koyunlar meler, uzak köpek, rüzgâr diner).

### «Ak Kemik»
- Işık: dolunayın gümüşü, uzun ay gölgeleri; obada ocak dumanı ve kapıdan sızan ateş ışığı; ufukta Dailin'in ateşleri.
- Ses: `amb_moon_night` (cırcır böcekleri, hafif esinti, uzak köpek, uzak ateşlerin çıtırtısı); kemik düşünce `sfx_bone_land`; koşarken `sfx_child_pant_a/b`; gülüşmeler `sfx_kids_laugh_*`; direğe varışta `sfx_post_slap`.

### «Ebenin Çetelesi»
- Işık: serin parlak sabah, öğleye doğru ısınan hava.
- Yaşam: Ebe Obası'nda bir kadın kurut serer, bir adam at bağlar, iki çocuk aşık oynar; Hereka'nın yurdunun önünde kuruyan ot demetleri; içeride asılı otlar, keçe, küçük ocak.
- Ses: `amb_ebe_camp` (sabah obası: çalışan kadınlar, kazana vuran tahta kaşık, uzakta oynayan çocuklar, koyun ve keçi, köpek; sözsüz); köpeklerden `sfx_dogs_guard_a/b`, tutulunca `sfx_dog_settle`.

## Üretilenler (2026-11-09)

ElevenLabs'la üretildi ve içe aktarıldı (QOA, döngüler ileri döngülü): `game/audio/ambience/e21/` altında 17 yatak (`amb_feast_crowd`, `amb_reed_lake`, `amb_ordos_steppe_day`, `amb_moon_night`, `amb_camp_spring_day`, `amb_yurt_storm_inside`, `amb_dailin_far`, `amb_snow_morning`, `amb_birch_camp_day`, `amb_ebe_camp`, `amb_ordos_dusk`, `amb_stream`, `amb_dusk_valley`, `amb_child_swim`, `amb_blizzard_night`; ve süzgeçle türetilen `amb_blizzard_lee`, `amb_fire_small`, `amb_fire_medium`), `game/audio/sfx/e21/` altında 42 tek seferlik ses (yukarıdaki kimliklerle; çeşitliler `_a`, `_b`, `_c`), `game/audio/music/e21/` altında `mus_shilde` (75 sn), `mus_prologue_day` (60 sn), `mus_prologue_night` (45 sn), üçü döngülü. Var olandan kullanılanlar: `amb_ember_pot` yerine `audio/ambience/gen/ember_crackle.wav`; `sfx_tinder_catch` yerine `audio/sfx/gen/fire_catch.wav`; `sfx_cranes_overhead` yerine `audio/sfx/gen/crane_call.wav`; `sfx_wolf_far` yerine D'nin hayvan bankasının kurt uluması; `amb_camp_spring_night` yerine `audio/ambience/night_meadow_loop.wav`; ateşin son evresi menünün `audio/ambience/campfire_loop.wav`'ı. Harcama: efektler ve müzik ≈5.300 kredi (defter `tools/vo_ledger.jsonl`).

Sözler: `data/vo_lines.json`'da 163 satır (`scene`: `prologue_days`, `childhood_days`; sayım günününki `childhood`), sesleri okunuyor; dosya gelince `SceneVoice` kendiliğinden çalar. Çocukluk'un Hereka'sının konuşan kimliği `hereka_young`'dır (Önsöz'ün 39 yaşının sesi).
