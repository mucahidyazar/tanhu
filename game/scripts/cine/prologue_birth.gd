class_name PrologueBirth
extends CineScene
## Önsöz'ün üçüncü sahnesi «Doğum» ve Çocukluk'a geçiş (Yol Haritası birth-scene; K68; story.md §3 satır 7a–8, §4;
## audio.md §3 «Yeni Oyun ve Önsöz»; godot.md §3.6): scenes/cine/prologue_birth.tscn'in kökü. childhood_ordos dünyasında
## (OrdosWorld; G1) 3B oynar; mit keçede, tarih dünyadadır. Çizelgesi data/cine/prologue_birth.json'dadır (segment birth).
##
## Kadraj kuralı (K98, kullanıcının sözü; referans docs/media/review/kadraj_referans.webp): bütün çekimler uzaktan ve
## yukarıdandır, Diablo gibi: eğim 35–50°, dikey görüş 30–40°, ayakta kişi kare yüksekliğinin ≈%6–15'i, çevre kareyi taşır,
## alçak güneşin uzun gölgesi okunur. Yakın plan, omuz üstü ve yüz çekimi yoktur; söz altyazıdadır. Her kamera anahtarı
## konusundan en az MIN_SUBJECT_DISTANCE uzaktır; ufku gerektiren ay karesi dışında eğim en az MIN_PITCH_DEG'dir (camera_plan).
##
## Çekimler (AnimationPlayer'ın aynı adlı canlandırmaları; setup'ta çizelgeden kurulur: 12. satır gerçek dosyasıyla
## uzayınca 7b de uzar, sonraki çekimler kayar):
##   7a      yurdun içi, 05:50, diorama gibi yukarıdan: dış kabuk (Places/LanYurt/YurtModel), çatı astarı ve tündüğün dumanı
##           gizlidir, duvar astarının dış yüzü çizilmez (set_diorama): taban, döşek, ocak ve kişiler görünür, çevrede şafak öncesi
##           loş bozkır. İçerinin ılık dolgusu (InteriorFill; gölgesiz, menzili yurdun içinde biter) ve tündüğün soğuk ışığı kişileri
##           tabandan ayırır; kapının dışındaki beşik doğumdan önce görünmez (yalnız zemini aydınlatan ışıkta kara bir leke olurdu).
##           Tek yavaş çekim, kesme yok (16 → 18,5 m): keçe közden gerçek köze (CineHost'un 1,5 sn'lik çakışması; köz ilk
##           karede videodaki yerdedir, 960, 640), Lan Hatun döşekte, kolu keregede (reach); Hereka ve Lan soyundan iki kadın.
##           Kapının dışındaki ışık yalnız kapıdan girer (DoorMask: yalnız gölge veren halka); önündeki kesik biçimli kart
##           (Al Karısı'nın biçimi, door_shadow_outline; yalnız gölge verir) eşikten gölge düşürür, gölgenin ucu ocağın eşik
##           taşında durur (shadow_tip). Tündükten süzülen gölgesiz ışık (CrownLight) yalnız içerideki kişileri aydınlatır.
##   7b      dışarıda şafak, 06:03: Teoman otağından yürüyerek çıkar, doğan güne eğilir (CineBow); kamera 31 m'de, 37°: alçak
##           güneşin uzun gölgesi batıya düşer. Satırın ikinci yarısında ay karesi (K98'in ufuk istisnası): Teoman'ın 44 m
##           doğusundan dolunaya bakar, eğim 9°, ufuk görünür, yurtlar küçük, Teoman uzakta hâlâ eğiliktir.
##   7c      Lan yurdu ve sayım hattı aynı uzak karede (kapıya ve sayıcıya ≈40 m), kımıltı yok, kamera durur: Önsöz'ün tek
##           kara sessizliği (2,5 sn; konak uygular).
##   7d      aynı kare, kamera yavaşça kayar: ilk ağlama; Hereka kapıdan çıkar, sayım hattına seslenir («One more.»); sayıcı
##           çubuğa çentik atar (gesture); kart «27 Eylül MÖ 234 · Ordos» (konak); uzakta turnalar (CraneFlock, hareketli ses
##           kaynağı; duyulur).
##   7e      Hereka eşi yurdun yanına gömer (diz çöker, toprak tümseği belirir; 25 m, güneydoğudan); kesmeyle beşiğin başındadır
##           (26 m, güneyden; beşiğin ardında kameraya bakar), orada da diz çökmüştür ve küçük ok-yayı elleriyle kemerin altına
##           asar; turnaların V'si yukarıdan, kadrajın içinden güneye geçer, gölge izleri zeminde (alçak güneş: batıya ≈11 m,
##           kapının ve beşiğin üstünden) seçilir. Kişi kesmede yer değiştirir, çekim boyunca kaymaz (_actor_cut).
##   panel_8 beşiğin yayı Çocukluk'a döner: yakınlaşma yok, kamera beşiğin uzak karesinde durur (beşik ortada), görüntü
##           0,4–1,9 sn'de belirir. childhood.ogv oynatılabiliyorsa
##           (K93; CineVideo, katman 2: boyalı süzgecin üstü) parşömen videosu sinema saatini izler, altyazı koyu banttadır; yoksa
##           keçe yedeği: FeltPanel (data/cine/birth_panel.json; F'nin takımı) kendi dünyası olan bir SubViewport'ta (katman 0,
##           boyalı süzgecin altında) yaydan açılır, koyuna binen çocuk belirir.
## Işık saatten değil sabit örnekten gelir: SkyRig.set_fixed_sample (data/cine/birth_light.json; içeride 05:50, dışarıda
## 06:03); restore sabit örneği bırakır. Sahnenin olayları: bed {bed, db, dur} ortam döngüsü, cue {sfx, db, pitch, at?}
## efekt (at verilirse 3B), cranes (turnaların sesi açılır), door_shadow, mound, hang_bow (görüntü canlandırmadadır).
## İleri sarmada ses çalınmaz, durum kurulur.
##
## Kişiler CineActor'dür (Actors/<Id>): kimlik ve düğüm yolu sabit, model StandIn'den (K89: var olan modellerden yer
## tutucu, Meshy modeli gelince yalnız assets/characters/<id>/<id>.glb eklenir). Ağır kurulum karelere bölünür: Lan Hatun
## setup'ta, öteki kişiler ve bekleme klipleri sonraki karelerde (is_ready beklemez; 7b 10 sn sonradır).
## Dokunulan her şey restore'da geri yazılır: kamera, ışığın sabit örneği, ocağın taşları (ücretsiz taşlar onların yerine
## konur), bozkırın kaya ve çalısının gölgesi (7a'da kapalı), ortam döngüleri (dizi bitiyorsa).
##
## Meshy modelleri (E7.6; assets/props/<kimlik>/<kimlik>.glb): beşik cradle (uzun ekseni doğu–batı, CRADLE_SIZE'a sığar),
## kemerinden asılı yay, sadak ve ipler cradle_bow (beşiğin ağından ayrıldı, tools/glb_split_region.py; asılı yeri özgün
## yeridir), kundak swaddled_baby (beşikte yatık). Model yoksa (ya da MeshyProp.models_enabled kapalıyken) kodla çizilirler.
##
## Ücretsiz varlıklar (K89, E7.5; assets/_free, usage.jsonl): ocak stone_fire_pit ve moon_rock_02, kap kacak
## wooden_bowl_01/02, carved_wooden_plate, wooden_spoon, tümsek dirt, sayıcının çubuğu rough_wood, turnaların sesi
## crane_call_2/1. Kodla çizim yedeğinin dokuları: beşik wood_table_worn, curly_teddy_natural, leather007, kundak fabric044,
## beşik yayı composite_bow (FREE_ASSETS.json: fallbackIn). Her düğüm free_asset meta verisini taşır.

const SEGMENT_PATH := "res://data/cine/prologue_birth.json"
const LIGHT_PATH := "res://data/cine/birth_light.json"
const PANEL_PATH := "res://data/cine/birth_panel.json"
const SEGMENT_ID := "birth"
## Çocukluk'a geçişin videosu (K93; 10 sn + 1 sn). Gerçek dosyayı ana oturum motion-studio'dan kopyalar.
const VIDEO_PATH := "res://assets/cine/video/childhood.ogv"
const SHOTS: Array[String] = ["7a", "7b", "7c", "7d", "7e", "panel_8"]
const INSIDE_SHOTS: Array[String] = ["7a"]
const SAMPLE_INSIDE := "inside"
const SAMPLE_OUTSIDE := "outside"
## Kişiler: düğüm adı → kimlik (kurulum sırası: FIRST_ACTORS setup'ta, ötekiler sonraki karelerde).
const ACTORS := {"LanHatun": "lan_hatun", "Hereka": "hereka_young", "LanWomanA": "lan_woman_a", "LanWomanB": "lan_woman_b",
	"Teoman": "teoman", "Counter": "counter"}
const INSIDE_ACTORS: Array[String] = ["LanHatun", "Hereka", "LanWomanA", "LanWomanB"]
## Sahnenin elle seçtiği oturuşlar (CineActor.seat_key): ikinci Lan kadını tek dizini diker.
const SEAT_PICKS := {"LanWomanB": "ground_one_knee"}
## Setup'ta kurulan kişi; ötekiler sonraki karelerde birer birer kurulur (çakışma daha yeni başlar, kamera közün üstündedir):
## modeller sahneyle arka planda gelir (preloaded), kişi başına 10-35 ms klip aktarımıdır, pano ≈13 ms: her biri kendi karesinde
## (ölçüm 2026-11-06, başsız: üç kişi aynı karede ≈80 ms sürüyordu).
const FIRST_ACTORS: Array[String] = ["LanHatun"]
## Ayakta oynayacak kliplerin aktarımı kesmelerde yapılır: takılma kesmede görünmez. Çekim → o çekimde ayakta duracak kişiler;
## yürüyüş yalnız yürüyecek kişilerde ısıtılır (WALKERS): Sayıcı hiç yürümez, kliple birlikte kesme uzardı.
const IDLE_AT := {"7b": ["Teoman"], "7c": ["Hereka", "Counter"]}
const WALKERS: Array[String] = ["Teoman", "Hereka"]
const STANDING_ROLES: Array[StringName] = [&"idle"]
## Restore'da (dizi bitiyorsa) susturulan ortam döngüleri.
const BEDS: Array[String] = ["yurt_inside", "ember_crackle", "wind_steppe"]
const SILENT_DB := -80.0
const BED_OUT := 0.5
## Ücretsiz varlıklar: kimlik → dosya.
const FREE_TEXTURES := {
	"wood_table_worn": "res://assets/_free/texture/wood_table_worn/wood_table_worn_diff_1k.jpg",
	"curly_teddy_natural": "res://assets/_free/texture/curly_teddy_natural/curly_teddy_natural_diff_1k.jpg",
	"leather007": "res://assets/_free/texture/leather007/Leather007_1K-JPG_Color.jpg",
	"fabric044": "res://assets/_free/texture/fabric044/Fabric044_1K-JPG_Color.jpg",
	"rough_wood": "res://assets/_free/texture/rough_wood/rough_wood_diff_1k.jpg",
	"dirt": "res://assets/_free/texture/dirt/dirt_diff_1k.jpg",
}
const FREE_MODELS := {
	"stone_fire_pit": "res://assets/_free/model/stone_fire_pit/stone_fire_pit_1k.gltf",
	"moon_rock_02": "res://assets/_free/model/moon_rock_02/moon_rock_02_1k.gltf",
	"wooden_bowl_01": "res://assets/_free/model/wooden_bowl_01/wooden_bowl_01_1k.gltf",
	"wooden_bowl_02": "res://assets/_free/model/wooden_bowl_02/wooden_bowl_02_1k.gltf",
	"carved_wooden_plate": "res://assets/_free/model/carved_wooden_plate/carved_wooden_plate_1k.gltf",
	"wooden_spoon": "res://assets/_free/model/wooden_spoon/wooden_spoon_1k.gltf",
	"composite_bow": "res://assets/_free/model/composite_bow/composite_bow.obj",
}
## Ocağın eşik taşının merkeze uzaklığı (HearthEmbers.stone_ring'in varsayılanı; dünya yokken) ve ücretsiz taşın boyu (m).
const DOOR_STONE_RING := 0.36
const ROCK_SIZE := Vector3(0.2465, 0.2019, 0.2513)
## Ocağın taşları (HearthEmbers.STONE_NAMES) ve ücretsiz ocağın ölçeği (1,45 m → ≈1,2 m: taş halkası kül yatağının
## kenarında, üç taş içeride kalır) ve gömülmesi.
const FIRE_PIT_SCALE := 0.85
const FIRE_PIT_SINK := 0.1
## Kapı ışığı ve kartın boyu: ışık kapının 3,0 m dışında, 4,0 m yükseklikte; kart (Al Karısı'nın biçimi, door_shadow_outline) 1,65 m.
## 7a yukarıdan bakar (K98): ışık yüksek olunca gölge az uzar (≈1,5 kat), kartın neredeyse bütünü kapıdan girer, biçimi (baş, boyun,
## omuz, saç telleri, etek) tabanda okunur; alçak ışıkta (2,3 m) içeriye yalnız başın ucu düşüyor, 5,8 kat uzayıp ince bir şeride
## dönüyordu. Kartın eteği kapının aralığının ≈%65'i, omuzları ışık bandının ≈%50'sidir: biçimin iki yanında ışık kalır.
const DOOR_LIGHT_OUT := 3.0
const DOOR_LIGHT_UP := 4.0
const CARD_HEIGHT := 1.65
## Kapı ışığının maskesi (7a): dış kabuk gizliyken ışık yalnız kapıdan girsin diye astarın hemen dışında yalnız gölge veren halka
## duvar; kapı aralığı astarınkiyle aynı (assets/structures/yurt/yurt_fit.json).
const DOOR_MASK_GAP := 0.06
const DOOR_MASK_HEIGHT := 2.6
## Maskenin kapı aralığının üst kenarı (m; yurdun kapısının boyu): ışık lentonun altından girer, bandı ocak taşının hemen ötesinde biter.
const DOOR_MASK_TOP := 1.9
## Tündükten süzülen şafak öncesi ışık (7a; diorama): yurdun tepesinden aşağı, gölgesiz, soğuk, yalnız içerideki kişilere (ACTOR_LIGHT_LAYER):
## kişiler uzaktan okunur, taban karanlık kalır. 6'da kahverengi giysiler kahverengi tabanda seçilmiyordu (2026-11-07): başlar ve omuzlar
## soğuk ışıkla tabandan ayrılsın diye 16.
const CROWN_LIGHT_UP := 3.8
const CROWN_LIGHT_ENERGY := 16.0
## İçerinin ılık dolgusu (7a; diorama): ocağın yansıması gibi, yurdun ortasında, gölgesiz; menzili yurdun içinde biter (tabanın kenarına dek):
## keçeler, döşek, kişiler ve kerege seçilir, dışarının şafak öncesi karanlığı ve kapının bandının karşıtlığı kalır.
const FILL_LIGHT_UP := 2.2
const FILL_LIGHT_RANGE := 3.2
const FILL_LIGHT_ENERGY := 0.9
const FILL_LIGHT_COLOR := Color(1.0, 0.7, 0.5)
## Kartın yolu (7a): gölgenin ucu kapının dışından eşik taşına yürür.
const SHADOW_FROM := 5.6
const SHADOW_TO := 9.0
const SHADOW_START_BACK := 2.0
## Döşeğin doğu yanına katlanmış keçe (yurdun yerel uzayında, ortası ve boyu; m): döşek FeltBed 0,95 m geniştir, Lan Hatun'un bacağı ve
## eteği kenarı ≈27 cm aşar, 7a'nın kamerası orayı görür; keçe olmasa bacak yerden 14 cm yukarıda kalırdı.
const BED_FOLD_AT := Vector3(1.92, 0.07, -0.1425)
const BED_FOLD_SIZE := Vector3(0.29, 0.14, 1.335)
## Zeminin ek görüntü katmanı (katman 20): içeride yönlü ışık yalnız bunu aydınlatır, kapının ardındaki yer karanlıkta kalmaz.
const GROUND_LAYER := 1 << 19
## İçerideki kişilerin ek görüntü katmanı (katman 19): tündük ışığı (CrownLight) yalnız onları aydınlatır, taban karanlıkta kalır, kapı
## ışığının bandı ve içindeki gölge seçilir.
const ACTOR_LIGHT_LAYER := 1 << 18
## Köz ışığının dışarıdaki menzili (m): gölgesiz ışık keçeden sızmaz, yurdun içi kapıdan yine görünür (yurdun yarıçapı 3,1).
const EMBER_OUTSIDE_RANGE := 2.9
## Beşik (beşiğin uzun ekseni doğu–batı) ve yayın ölçüleri (m). Model bu boy ve derinliğe sığar (≈0,87 × 0,79 × 0,42 m);
## öteki ölçüler kodla çizimindir.
const CRADLE_SIZE := Vector3(0.9, 0.28, 0.42)
const CRADLE_LIFT := 0.12
const ARCH_RISE := 0.62
const BOW_LENGTH := 0.46
## Meshy modelleri: assets/props/<kimlik>/<kimlik>.glb.
const PROP_FOLDER := "props"
const CRADLE_MODEL := "cradle"
const BOW_MODEL := "cradle_bow"
const SWADDLE_MODEL := "swaddled_baby"
## Yay parçasının ortası cradle.glb'nin model uzayında (cradle_bow/split.json; parça da bu uzaydadır, ortası GLB'den ölçülür:
## sabit, parçanın dosyası yokken kodla çizilen yayın modelli beşikteki yeridir).
const BOW_SPOT := Vector3(-0.056149, 0.411913, -0.005944)
## Modelli yay kemerin içinden geçmesin diye önce kemerin kuzeyine iner, oradan kemerin altına girer: asılı yerine göre
## uğrak noktası (m).
const BOW_APPROACH := Vector3(0.0, -0.02, -0.26)
## Kundağın boyu (m), yatışı ve ortasının yeri cradle.glb'nin model uzayında: başı yastıkta (batıda), döşeğe ≈1 cm gömülü,
## sadağın altından geçer (üç ağın ölçümüyle: kundakla yay parçası değmez).
const SWADDLE_LENGTH := 0.48
const SWADDLE_TILT_DEG := 5.0
const SWADDLE_SPOT := Vector3(-0.19758, 0.06322, 0.02513)
## Turnaların hızı (m/sn), 7e'de beşiğin karesinin ortasından geçtikleri an (7e'nin başından, sn) ve V'nin başının o anki yeri (beşiğe
## göre, m): beşiğin 9 m doğusundan, zeminden alçak geçerler; kamera yukarıdan bakar, V ve gölgesi (alçak güneş, 15°: batıya ≈11 m,
## kapının ve beşiğin üstünden) aynı karededir; gölge yurdun kendi gölgesine düşmez. Sürü 7d'nin başından 7e'nin sonuna düz bir
## çizgide yürür (≈150 m); 7d'de uzaktadır, yalnız duyulur.
const CRANE_SPEED := 8.0
const CRANE_PASS := 5.9
const CRANE_OFFSET := Vector3(9.2, 3.0, 1.9)
## Turnanın çağrısı en çok bu düzeydedir (dB): eski yolda sürü dinleyiciye en çok ≈120 m yaklaşıyordu (2 dB − 6 dB); yeni yol
## kameranın altından geçer, çağrı yine o düzeyi aşmaz (ses değişmez). Yeni yol dinleyiciye yarı uzaklıktan başlar (≈165 m; eskisi
## ≈330 m): kısılmanın birim uzaklığı da yarıya iner, 7d'nin uzak çağrıları eski düzeyindedir (≈−13 dB).
const CRANE_PEAK_DB := -4.0
const CRANE_UNIT_SIZE := 30.0

## Kadraj kuralı (K98): her kamera anahtarı konusundan en az bu kadar uzaktır (m); ufuk istisnası dışında eğim en az bu kadardır.
const MIN_SUBJECT_DISTANCE := 12.0
const MIN_PITCH_DEG := 30.0
## Kadrajlar: Vector3(yön, eğim, uzaklık). Yön derecedir, konudan kameraya, kuzeyden saat yönünde (90 doğu, 180 güney); eğim aşağı
## doğru derece; uzaklık konunun bakılan noktasına metre.
## 7a: diorama, közden açılır (16 → 18,5 m). Yön burada kapıya göredir (kapı doğudaysa 125° → 215°, güneybatı): kapı ve gölgenin yolu
## sağ üstte, Lan Hatun'un uzandığı kuzey duvarı karşıda; bakış çekim boyunca kapıya doğru kayar (yurdun yerel uzayında, m).
const INSIDE_OPEN := Vector3(125.0, 44.0, 16.0)
const INSIDE_END := Vector3(132.0, 41.0, 18.5)
const INSIDE_DRIFT := Vector3(0.25, 0.15, 0.7)
const INSIDE_FOV := 33.0
## 7b, güneş: bakış Teoman'ın batısında, uzun gölgesinin üstündedir (m); kamera Teoman'ı izleyerek az kayar.
const SUN_OPEN := Vector3(166.0, 37.0, 31.5)
const SUN_END := Vector3(171.0, 37.0, 30.5)
const SUN_LOOK_WEST := Vector2(4.7, 3.5)
const SUN_FOV := 34.0
## 7b, ay (ufuk istisnası): Teoman'ın doğusundan (m) ve güneyinden, yüksekten dolunaya bakar; eğim 9°.
const MOON_BACK := 41.5
const MOON_SIDE := 7.0
const MOON_HEIGHT := 13.5
const MOON_DRIFT := 1.2
const MOON_PITCH_DEG := 9.0
const MOON_FOV := 34.0
## 7b'de ay karesine kesme satırın bu payında: «in the west the full moon» sözünde (Teoman güneş karesinde ≈1 sn eğik durur, ay karesinde
## uzakta hâlâ eğiktir).
const MOON_CUT_SHARE := 0.68
## 7c ve 7d: Lan yurdu (bütünüyle) ile sayıcı aynı karede, kapıya ve sayıcıya ≈40 m (bakış ikisinin ortası); 7c'de kamera durur, 7d'de kayar.
const LINE_FRAME := Vector3(135.0, 36.0, 37.0)
const LINE_END := Vector3(137.0, 36.0, 37.5)
const LINE_FOV := 36.0
## 7e: gömü (güneydoğudan) ve beşik (güneyden; Hereka beşiğin ardında kameraya bakar); panel_8 beşiğin karesinde durur. Beşiğin karesinde
## bakış beşiğin doğusundadır (m): turnaların yolu ve gölgesi karede kalır, beşik ortaya yakındır.
const BURIAL_FRAME := Vector3(140.0, 40.0, 25.0)
const BURIAL_END := Vector3(143.0, 40.0, 25.0)
const CRADLE_FRAME := Vector3(178.0, 40.0, 26.0)
const CRADLE_END := Vector3(181.0, 40.0, 26.0)
const CRADLE_LOOK_EAST := 2.0
const OUTSIDE_FOV := 34.0
## Kamera canlandırmasının anahtar aralığı (sn).
const KEY_STEP := 0.2
## Kesmenin iki anahtarı arasındaki süre (sn): ara değer görünmez. Kamera ve kişi aynı anda sıçrar.
const CUT_EPS := 0.0005
## 7a'da gizlenen yurt düğümleri (Places/LanYurt'a göre), duvar astarı ve dış yüzünü gizleyen tekdüzen (kerege.gdshader). Tündüğün dumanı
## (Yurt'un Smoke'u) da gizlenir: çatı yokken kaynağı havada kalır, yurdun üstünde asılı bir bulut gibi durur.
const DIORAMA_HIDDEN: Array[NodePath] = [^"YurtModel", ^"Lining/Roof", ^"Smoke"]
const LINING_WALL := ^"Lining/Wall"
const HIDE_BACK_PARAM := &"hide_back"
## 7e'de yayın zamanı, beşiğin kesmesinden sonra (sn): Hereka yayı kaldırır, kemerin kuzeyine getirir, asar. Eller HANDS_DOWN_AT'te
## inmeye başlar, HANDS_REST_AT'te dizlerdedir: yay asılıyken havada kalmaz, asılmadan bırakmaz. Hereka sonra beşiğin başında diz
## çökmüş kalır (panel_8'e dek; kamera uzaktadır, kesme yoktur).
const BOW_LIFT_AT := 0.2
const BOW_APPROACH_AT := 1.0
const BOW_HUNG_AT := 1.7
const HANDS_DOWN_AT := 2.2
const HANDS_REST_AT := 2.8
## 7e'de Hereka'nın kol jesti ve eğilişi: gömüde eğik; beşiğin başında kollar önce taşıma yüksekliğinde, yay asılırken tam
## kalkar ve gövde öne eğilir (diz çökmüşken el kemikleri asılı yerin ≈0,25 m kuzeyinde kalır, parmaklar yaya değer).
const BURIAL_LEAN := 0.25
const CRADLE_LEAN := 0.3
const CARRY_GESTURE := 0.7
## 7d'de Hereka sayım hattına seslenirken ellerini öne açar (gesture_turns'ün payı).
const CALL_GESTURE := 0.4
## Yayın ilk yeri: Hereka'nın önünde (diz çökmüş kişinin ellerinin arasında, ölçüldü).
const BOW_CARRY_FORWARD := 0.35
const BOW_CARRY_UP := 0.5
## panel_8: görüntü PANEL_FADE_IN'den PANEL_OPAQUE_AT'e dek belirir (sn). Video opak olunca altındaki 3B çizilmez.
const PANEL_FADE_IN := 0.4
const PANEL_OPAQUE_AT := 1.9
## Teoman otağın kapısından doğan güne kaç metre yürür, ne kadar sürede (sn); Hereka'nın kapıdan çıkışı. Uzaktan bakılır (K98):
## Teoman kapıdan 3,8 m açılır, uzun gölgesi (≈6,5 m, batıya) otağın kapısının eşiğine dek zemindedir; yürüyüş klibin hızına yetişir
## (CharacterAvatar.WALK_RATE_RANGE).
const TEOMAN_WALK := 3.8
const TEOMAN_WALK_S := 3.3
const HEREKA_WALK_S := 1.0

## Oynatılacak video (sınama fixture verir).
static var video_path := VIDEO_PATH

## Sahneyle birlikte (arka planda) yüklenen kaynaklar: kişilerin ve eşyaların modelleri, ücretsiz modeller ve dokular. Kodla çizim
## yedeğinin dokuları ve composite_bow listede değildir (model varken yüklenmezler).
@export var preloaded: Array[Resource] = []

@onready var camera: Camera3D = $Camera
@onready var player: AnimationPlayer = $AnimationPlayer
@onready var actors_root: Node3D = $Actors
@onready var props: Node3D = $Props
@onready var cranes: CraneFlock = $Cranes

## Dünya (OrdosWorld; yoksa null: yerler düzen dosyasından hesaplanır).
var world: Node3D
var rig: SkyRig
var layout: Dictionary = {}
var ground: OrdosGround
## Çekimlerin segment içi başı ve süresi (sn) ve 12. satırın bitişi.
var shot_starts := {}
var shot_lengths := {}
var line_end := 0.0
## Uygulanan ışık örneği ("inside" / "outside").
var sample_name := ""
## Sahnenin kendi çaldığı sesler (ileri sarmada boş kalır; sınama okur): [tür, kimlik, seçenekler].
var sounds: Array = []
## Sahneye gelen kendi olayları (sınama okur).
var events_seen: Array[String] = []
## Geçişin katmanı; içinde video (K93) ya da keçe yedeği pano 8 (FeltPanel) ve kamerası.
var panel_layer: CanvasLayer
var video: CineVideo
var panel: FeltPanel
var panel_camera: Camera3D
## Yerler: ad → dünya noktası (yurt, kişiler, beşik, tümsek, ışık).
var spots: Dictionary = {}

var _samples: Dictionary = {}
## Beşiğin modeli (yoksa null: kodla çizildi) ve yay parçasının ortası (model uzayında).
var _cradle_model: MeshyProp
var _bow_center := BOW_SPOT
var _prev_camera: Camera3D
var _hidden: Array = []
## Köz ışığının sahneden önceki ayarları (restore geri yazar).
var _ember_saved: Dictionary = {}
var _ground_marked := false
var _queue: Array[Callable] = []
var _built := false
var _restored := false
var _touched_beds: Dictionary = {}
## Videonun sinema saatindeki başı (panel_8 çekimi; oynamıyorken NAN).
var _video_t0 := NAN
## Video opak: altındaki 3B kapatıldı mı (CineHost.cover_main_3d)?
var _video_covers := false
## Çekim → kamera anahtarları (sınama okur; _camera yazar): [{t, pos, look, fov, subject, horizon}, ...]. subject çekimin konusu
## (kuralın uzaklığı ona ölçülür), horizon ufku gerektiren istisna kare (ay).
var camera_plan := {}
var _plan_shot := ""
## 7a'nın dioraması açık mı ve gizlenen düğümlerin önceki görünürlüğü ([düğüm, görünür]).
var diorama := false
var _diorama_saved: Array = []
## Bozkırın kaya ve çalısının gölge ayarı sahneden önce (düğüm → cast_shadow; restore geri yazar).
var _steppe_shadow: Dictionary = {}


func _ready() -> void:
	layout = OrdosWorld.load_layout(OrdosWorld.LAYOUT_PATH)
	ground = OrdosGround.new(layout)
	_samples = SkyRig.load_samples(LIGHT_PATH)
	# Eşyalar önce kurulur: yayın asılı yeri beşiğin modelinden hesaplanır.
	_build_props()
	_compute_spots()
	_place_props()
	cranes.visible = false
	# V yukarıdan görünür, gölgesi zeminde seçilir (7e; gölge izi dışarının ışığından); kameranın altından geçse de çağrı eski yolun en
	# yüksek düzeyini aşmaz.
	cranes.shadow_dir = -_sample_dir(SAMPLE_OUTSIDE, "light_dir", Vector3(0.97, 0.26, 0.04))
	cranes.ground_shadows = true
	cranes.call_peak_db = CRANE_PEAK_DB
	cranes.call_unit_size = CRANE_UNIT_SIZE


## Segment başlarken: dünya, ışık, ocak, kişiler, zamanlama ve canlandırmalar; kamera 7a'nın ilk karesinde.
func setup(p_ctx: Dictionary) -> void:
	super.setup(p_ctx)
	world = p_ctx.get("world") as Node3D
	rig = world.call(&"get_sky_rig") as SkyRig if world and world.has_method(&"get_sky_rig") else null
	if world:
		_compute_spots()
		_place_props()
	_prev_camera = get_viewport().get_camera_3d() if is_inside_tree() else null
	_swap_hearth()
	for node_name: String in SEAT_PICKS:
		actor(node_name).seat_key = SEAT_PICKS[node_name]
	for node_name: String in FIRST_ACTORS:
		_build_actor(node_name)
	_build_panel()
	for node_name: String in INSIDE_ACTORS:
		if not FIRST_ACTORS.has(node_name):
			_queue.append(_build_actor.bind(node_name))
	_queue.append(_fill_panel)
	for node_name: String in ACTORS:
		if not INSIDE_ACTORS.has(node_name):
			_queue.append(_build_actor.bind(node_name))
	_queue.append(_attach_tally)
	build_timing()
	var h := host()
	if h:
		player.speed_scale = maxf(h.speed, 0.001)
	camera.make_current()
	apply_sample(SAMPLE_INSIDE)
	_place_shot("7a", 0.0)
	set_process(true)


func is_ready() -> bool:
	return true


func on_shot(shot_name: String, ev: Dictionary) -> void:
	if not SHOTS.has(shot_name):
		return
	if not _built:
		build_timing()
	# 7b ve sonrası ayaktaki kişileri ister: bekleyen kurulum kalmasın (ileri sarmada da); bekleme klipleri kesmede.
	if shot_name != "7a":
		flush()
		_ensure_idles(shot_name)
	apply_sample(SAMPLE_INSIDE if INSIDE_SHOTS.has(shot_name) else SAMPLE_OUTSIDE)
	if shot_name == "panel_8" and panel_layer:
		panel_layer.visible = true
		_start_video(ev)
	player.play(shot_name)
	player.seek(elapsed(ev), true)
	# Çekimin başı kesmedir: kişi yeni pozundadır, ekranda oturup kalkmaz.
	for a in actors():
		a.snap_pose()


func on_event(ev: Dictionary) -> void:
	var type := str(ev.get("type", ""))
	match type:
		"bed":
			var bed := str(ev.get("bed", ""))
			_touched_beds[bed] = true
			_audio(&"set_ambience_layer", [bed, float(ev.get("db", SILENT_DB)), 0.0 if seeking else float(ev.get("dur", 0.0))])
		"cue":
			if not seeking:
				var opts := {"db": float(ev.get("db", 0.0)), "pitch": float(ev.get("pitch", 1.0))}
				var at: Variant = ev.get("at")
				if at is Array and (at as Array).size() == 3:
					opts["at"] = Vector3(float(at[0]), float(at[1]), float(at[2]))
				sounds.append(["sfx", str(ev.get("sfx", "")), opts])
				_audio(&"play_sfx", [str(ev.get("sfx", "")), opts])
		"cranes":
			cranes.set_sounding(true, not seeking)
			events_seen.append(type)
		"door_shadow", "mound", "hang_bow":
			events_seen.append(type)


func _process(_delta: float) -> void:
	if not _queue.is_empty():
		var job: Callable = _queue.pop_front()
		job.call()
	_follow_video()


## Bekleyen kurulum işlerini hemen bitirir (ileri sarma, sınama).
func flush() -> void:
	while not _queue.is_empty():
		var job: Callable = _queue.pop_front()
		job.call()


## Segment bitince ya da atlanınca (bir kez): kamera, ışığın sabit örneği, ocağın taşları, ses, pano.
func restore() -> void:
	if _restored:
		return
	_restored = true
	set_process(false)
	_queue.clear()
	if is_instance_valid(player):
		player.stop()
	if is_instance_valid(cranes):
		cranes.set_sounding(false)
	if rig and is_instance_valid(rig):
		rig.clear_fixed_sample()
	sample_name = ""
	if rig and is_instance_valid(rig) and rig.sun_light() and _ember_saved.has("cull"):
		rig.sun_light().light_cull_mask = _ember_saved["cull"]
	var hearth := _hearth()
	if hearth and hearth.ember_light() and _ember_saved.has("mode"):
		var ember := hearth.ember_light()
		ember.omni_shadow_mode = _ember_saved["mode"]
		ember.omni_range = _ember_saved["range"]
		ember.shadow_enabled = _ember_saved["shadow"]
		ember.rotation.x = _ember_saved["pitch"]
	_ember_saved = {}
	for gi: Variant in _steppe_shadow:
		if is_instance_valid(gi):
			(gi as GeometryInstance3D).cast_shadow = int(_steppe_shadow[gi]) as GeometryInstance3D.ShadowCastingSetting
	_steppe_shadow.clear()
	set_diorama(false)
	for pair: Array in _hidden:
		if is_instance_valid(pair[0]):
			(pair[0] as Node3D).visible = pair[1]
	_hidden.clear()
	for actor in actors():
		actor.reset_pose()
	if is_instance_valid(camera) and camera.is_current():
		camera.clear_current(false)
	if is_instance_valid(_prev_camera) and _prev_camera.is_inside_tree():
		_prev_camera.make_current()
	if panel_layer and is_instance_valid(panel_layer):
		panel_layer.visible = false
	_stop_video()
	if _sequence_ends():
		for bed: String in BEDS:
			if _touched_beds.has(bed):
				_audio(&"set_ambience_layer", [bed, SILENT_DB, BED_OUT])
	CineActor.clear_cache()


# --- Yüz ------------------------------------------------------------------------------------------

## Sahnenin kişileri (Actors altındaki CineActor'ler, sahnedeki sırayla).
func actors() -> Array[CineActor]:
	var out: Array[CineActor] = []
	if actors_root:
		for child in actors_root.get_children():
			if child is CineActor:
				out.append(child)
	return out


func actor(node_name: String) -> CineActor:
	return actors_root.get_node_or_null(NodePath(node_name)) as CineActor if actors_root else null


## Işığın sabit örneğini uygular (SkyRig varsa); örnek adı sample_name'e yazılır.
func apply_sample(sample_id: String) -> void:
	if sample_name == sample_id:
		return
	sample_name = sample_id
	if rig and _samples.has(sample_id):
		rig.set_fixed_sample(_samples[sample_id])
	if is_instance_valid(props):
		for light_name: String in ["DoorLight", "CrownLight", "InteriorFill"]:
			var light := props.get_node_or_null(NodePath(light_name)) as Light3D
			if light:
				light.visible = sample_id == SAMPLE_INSIDE
	_apply_shadow_cost(sample_id == SAMPLE_INSIDE)
	set_diorama(sample_id == SAMPLE_INSIDE)


## 7a'nın dioraması (K98): Lan Hatun'un yurdunun dış kabuğu (YurtModel) ve çatı astarı (Lining/Roof) gizlenir, duvar astarının dış
## yüzü çizilmez (kerege.gdshader hide_back): kameraya bakan yakın duvar kadrajı kapatmaz, içerisi yukarıdan görünür. Kapanınca
## (7b ve sonrası, restore) hepsi önceki hâline döner. Dünya yoksa yalnız bayrak değişir.
func set_diorama(on: bool) -> void:
	if on == diorama:
		return
	diorama = on
	var yurt := _lan_yurt()
	if on:
		_diorama_saved.clear()
		if yurt:
			for path: NodePath in DIORAMA_HIDDEN:
				var node := yurt.get_node_or_null(path) as Node3D
				if node:
					_diorama_saved.append([node, node.visible])
					node.visible = false
	else:
		for pair: Array in _diorama_saved:
			if is_instance_valid(pair[0]):
				(pair[0] as Node3D).visible = pair[1]
		_diorama_saved.clear()
	var wall := yurt.get_node_or_null(LINING_WALL) as GeometryInstance3D if yurt else null
	var mat := wall.material_override as ShaderMaterial if wall else null
	if mat:
		mat.set_shader_parameter(HIDE_BACK_PARAM, on)


## Lan Hatun'un yurdu (dünyada; yoksa null).
func _lan_yurt() -> Node3D:
	if world == null or not is_instance_valid(world) or not world.has_method(&"place"):
		return null
	return world.call(&"place", "lan_yurt") as Node3D


## Gölgenin bedeli çekime göre (K63; ölçüm 2026-11-07: 7a'da 4,22M, 7e'de 3,38M gölge üçgeni, sınır 1,5M). İçeride köz gölgesi küp haritanın
## altı yüzü yerine iki yarım küreyle çizilir, dikişi köz yüksekliğinde yatay kalır. İçeride yönlü ışık gölgesizdir ve yalnız zemini aydınlatır
## (birth_light.json; GROUND_LAYER): yurdun içine işlemez, gölge basamakları boşa çizilmez, kapının ardındaki yer görünür. Dışarıda köz
## gölgesizdir ve yurdun içinde kalır; içerideki kişilerin ve eşyaların gölgesi kapanır: keçenin içindeler, dört basamağa da boşa çizilirlerdi.
func _apply_shadow_cost(inside: bool) -> void:
	_mark_ground()
	var sun: DirectionalLight3D = rig.sun_light() if rig else null
	if sun:
		if not _ember_saved.has("cull"):
			_ember_saved["cull"] = sun.light_cull_mask
		sun.light_cull_mask = GROUND_LAYER if inside else int(_ember_saved["cull"])
	var hearth := _hearth()
	var light := hearth.ember_light() if hearth else null
	if light:
		if not _ember_saved.has("mode"):
			_ember_saved.merge({"mode": light.omni_shadow_mode, "range": light.omni_range, "shadow": light.shadow_enabled, "pitch": light.rotation.x})
		light.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
		light.rotation.x = -PI * 0.5
		light.shadow_enabled = inside and bool(_ember_saved["shadow"])
		light.omni_range = float(_ember_saved["range"]) if inside else minf(float(_ember_saved["range"]), EMBER_OUTSIDE_RANGE)
	var casters: Array[Node] = [props.get_node_or_null(^"Kitchen"), props.get_node_or_null(^"Hearth")]
	for node_name: String in ["LanHatun", "LanWomanA", "LanWomanB"]:
		casters.append(actor(node_name))
	for root: Node in casters:
		if root:
			for mesh: Node in root.find_children("*", "MeshInstance3D", true, false):
				(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if inside else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Bozkırın kaya ve çalısı (dünyanın MultiMesh'leri bütün haritayı kapsar): içeride köz ve kapı ışığının gölge geçişlerine bütünüyle girerdi,
	# menzillerinin dışında da (ölçüm 2026-11-07: 7a'da 1,29M → 2,01M gölge üçgeni). İçeride yönlü gölge yoktur: gölge vermezler.
	for gi in _steppe_casters():
		if not _steppe_shadow.has(gi):
			_steppe_shadow[gi] = gi.cast_shadow
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if inside else int(_steppe_shadow[gi]) as GeometryInstance3D.ShadowCastingSetting


## Dünyanın bozkırındaki kaya ve çalı düğümleri (Ground/Rocks, Ground/Shrubs; dünya yoksa boş).
func _steppe_casters() -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if world == null or not is_instance_valid(world):
		return out
	for path: NodePath in [^"Ground/Rocks", ^"Ground/Shrubs"]:
		var node := world.get_node_or_null(path)
		if node:
			for gi: Node in node.find_children("*", "GeometryInstance3D", true, false):
				out.append(gi as GeometryInstance3D)
	return out


## Dünyanın zemini (arazi, ot, ırmak) bir kez GROUND_LAYER'a da girer.
func _mark_ground() -> void:
	if world == null or _ground_marked:
		return
	_ground_marked = true
	for node_name: String in ["Ground", "River"]:
		var root := world.get_node_or_null(NodePath(node_name))
		if root:
			for visual: Node in root.find_children("*", "VisualInstance3D", true, false):
				(visual as VisualInstance3D).layers |= GROUND_LAYER


## Işık örnekleri (çözülmüş; birth_light.json).
func samples() -> Dictionary:
	return _samples


## Gölgenin ucu (saf): ışıktan kartın tepesine uzanan ışının y = floor_y zeminiyle kesiştiği nokta; ışın zemine inmiyorsa
## Vector3.INF.
static func shadow_tip(light: Vector3, top: Vector3, floor_y: float) -> Vector3:
	var d := top - light
	if d.y >= -1e-6:
		return Vector3.INF
	return light + d * ((floor_y - light.y) / d.y)


## Kartın tepesinin, gölgenin ucu target'e düşsün diye bulunması gereken nokta (saf): ışıktan hedefe giden doğrunun
## y = top_y yüksekliğindeki noktası.
static func card_top_for(light: Vector3, target: Vector3, top_y: float) -> Vector3:
	var d := target - light
	if absf(d.y) < 1e-6:
		return target
	return light + d * ((top_y - light.y) / d.y)


## Kartın tepesi (dünya) ve gölgenin ucu şu an.
func shadow_card_top() -> Vector3:
	var card := props.get_node_or_null(^"ShadowCard") as Node3D
	return card.global_position + Vector3(0.0, CARD_HEIGHT, 0.0) if card else Vector3.INF


func current_shadow_tip() -> Vector3:
	var light := props.get_node_or_null(^"DoorLight") as Node3D
	if light == null:
		return Vector3.INF
	return shadow_tip(light.global_position, shadow_card_top(), spots.get("floor_y", 0.0))


## Ocağın eşik taşı (gölgenin durduğu yer; dünyada HearthEmbers.door_stone_position, yoksa düzenden).
func door_stone() -> Vector3:
	var hearth := _hearth()
	if hearth:
		return hearth.door_stone_position()
	return spots.get("door_stone", Vector3.ZERO)


# --- Zaman ve canlandırma ---------------------------------------------------------------------------

## Çekimlerin zamanı konağın çizelgesinden (yoksa segment dosyasından, gerçek sürelerle); canlandırmalar kurulur.
func build_timing() -> void:
	var timeline := _real_timeline()
	var seg_id := _segment_id()
	var seg := timeline.segment(seg_id) if timeline else {}
	if seg.is_empty() and timeline and timeline.ok():
		seg = timeline.segments[0]
		seg_id = str(seg["id"])
	var start := float(seg.get("start", 0.0))
	var total := float(seg.get("length", 56.5))
	for i in SHOTS.size():
		var at := timeline.time_of("%s:%s" % [seg_id, SHOTS[i]]) if timeline else NAN
		shot_starts[SHOTS[i]] = at - start if not is_nan(at) else 0.0
	for i in SHOTS.size():
		var next := float(shot_starts[SHOTS[i + 1]]) if i + 1 < SHOTS.size() else total
		shot_lengths[SHOTS[i]] = maxf(next - float(shot_starts[SHOTS[i]]), 0.1)
	var le := timeline.time_of("%s:act0.birth.12_end" % seg_id) if timeline else NAN
	line_end = le - start if not is_nan(le) else float(shot_starts["7c"]) - 5.0
	_set_crane_path()
	_build_animations()
	_built = true


## Turnaların yolu: 7d'nin başından 7e'nin sonuna kuzeyden güneye (+z), CRANE_SPEED ile; 7e'nin CRANE_PASS'ında V'nin başı
## crane_pass'tadır (beşiğin karesinin içi; V ve gölgesi aynı karede).
func _set_crane_path() -> void:
	var t0 := float(shot_starts["7d"])
	var t1 := float(shot_starts["7e"]) + float(shot_lengths["7e"])
	var t_pass := float(shot_starts["7e"]) + minf(CRANE_PASS, float(shot_lengths["7e"]))
	var center: Vector3 = spots.get("crane_pass", CRANE_OFFSET)
	cranes.start_point = center - Vector3.BACK * CRANE_SPEED * (t_pass - t0)
	cranes.end_point = center + Vector3.BACK * CRANE_SPEED * (t1 - t_pass)


func _build_animations() -> void:
	if player.has_animation_library(&""):
		player.remove_animation_library(&"")
	var lib := AnimationLibrary.new()
	camera_plan.clear()
	for shot: String in SHOTS:
		var anim := Animation.new()
		anim.length = float(shot_lengths.get(shot, 1.0))
		_plan_shot = shot
		camera_plan[shot] = []
		_state_tracks(anim, shot)
		match shot:
			"7a":
				_anim_7a(anim)
			"7b":
				_anim_7b(anim)
			"7c":
				_anim_7c(anim)
			"7d":
				_anim_7d(anim)
			"7e":
				_anim_7e(anim)
			"panel_8":
				_anim_panel(anim)
		lib.add_animation(StringName(shot), anim)
	player.add_animation_library(&"", lib)


## Bir çekimin ilk karesini kurar ve durdurur (setup: 7a'nın ilk karesi çakışmanın altında görünür).
func _place_shot(shot: String, t: float) -> void:
	if player.has_animation(StringName(shot)):
		player.play(StringName(shot))
		player.seek(t, true)
		player.pause()


## Her çekimin başında herkesin ve her şeyin durumu (ileri sarmada da doğru kurulur).
func _state_tracks(anim: Animation, shot: String) -> void:
	var inside := ["LanHatun", "Hereka", "LanWomanA", "LanWomanB"]
	for node_name: String in inside:
		var spot: Dictionary = spots[node_name]
		if node_name == "Hereka" and shot not in ["7a", "7b", "7c"]:
			if shot == "panel_8":
				# Kamera beşiğin uzak karesinde durur: Hereka 7e'nin sonundaki gibi beşiğin başında diz çökmüştür, elleri dizlerinde.
				var at: Dictionary = spots["HerekaCradle"]
				_actor_key(anim, "Hereka", 0.0, at["pos"], at["yaw"], &"sit")
				_value(anim, "Actors/Hereka:gesture_amount", [[0.0, 0.0]])
				_value(anim, "Actors/Hereka:bow_amount", [[0.0, 0.0]])
			continue
		_actor_key(anim, node_name, 0.0, spot["pos"], spot["yaw"], &"sit")
		_value(anim, "Actors/%s:reach_amount" % node_name, [[0.0, 1.0 if node_name == "LanHatun" and shot == "7a" else 0.0]])
		_value(anim, "Actors/%s:gesture_amount" % node_name, [[0.0, 0.0]])
		_value(anim, "Actors/%s:bow_amount" % node_name, [[0.0, 0.0]])
	var teoman: Dictionary = spots["TeomanEnd"]
	if shot != "7b":
		var at_door := shot == "7a"
		_actor_key(anim, "Teoman", 0.0, spots["TeomanStart"]["pos"] if at_door else teoman["pos"],
				spots["TeomanStart"]["yaw"] if at_door else teoman["sun_yaw"], &"idle")
		_value(anim, "Actors/Teoman:bow_amount", [[0.0, 0.0]])
	var counter: Dictionary = spots["Counter"]
	if shot != "7d":
		_actor_key(anim, "Counter", 0.0, counter["pos"], counter["yaw"], &"idle")
		_value(anim, "Actors/Counter:gesture_amount", [[0.0, 0.0]])
	var after_7d := SHOTS.find(shot) > SHOTS.find("7d")
	# Beşik 7a'da kapının dışında, yalnız zemini aydınlatan şafak öncesi ışıkta kara bir leke olurdu: doğumdan önce görünmez (7b'den sonra
	# kapının yanında hazırdır).
	_discrete(anim, "Props/Cradle:visible", [[0.0, shot != "7a"]])
	_discrete(anim, "Props/Swaddle:visible", [[0.0, after_7d]])
	_discrete(anim, "Props/CradleBow:visible", [[0.0, shot == "panel_8"]])
	_discrete(anim, "Props/ShadowCard:visible", [[0.0, shot == "7a"]])
	_discrete(anim, "Props/DoorMask:visible", [[0.0, shot == "7a"]])
	_discrete(anim, "Props/Mound:visible", [[0.0, after_7d]])
	_discrete(anim, "Cranes:visible", [[0.0, shot in ["7d", "7e"]]])
	if shot == "panel_8":
		_value(anim, "Props/Mound:scale", [[0.0, Vector3.ONE]])
		var bow: Dictionary = spots["BowHung"]
		_value(anim, "Props/CradleBow:position", [[0.0, bow["pos"]]])


## 7a: yurdun içi diorama gibi yukarıdan (K98), tek yavaş çekim, kesme yok: kamera közün üstünden açılır (köz ilk karede videodaki
## yerde), 16 m'den 18,5 m'ye çekilir, bakış kapıya doğru kayar; Lan Hatun'un keregeyi tutan kolu karşı duvarda, kapıdan giren ışık ve
## gölgenin yolu sağ üstte. Gölge kartı SHADOW_FROM–SHADOW_TO arasında eşik taşına yürür.
func _anim_7a(anim: Animation) -> void:
	var length := anim.length
	var ember: Vector3 = spots["ember"]
	var open_cam: Vector3 = spots["inside_cam"]
	_camera(anim, [
		[0.0, open_cam, _opening_look(open_cam, ember + Vector3(0.0, 0.04, 0.0), INSIDE_FOV), INSIDE_FOV, ember],
		[length, spots["inside_end_cam"], spots["inside_look"], INSIDE_FOV, ember],
	])
	var card_from: Vector3 = spots["card_start"]
	var card_to: Vector3 = spots["card_end"]
	_value(anim, "Props/ShadowCard:position", [[0.0, card_from], [minf(SHADOW_FROM, length), card_from],
			[minf(SHADOW_TO, length), card_to], [length, card_to]], true)


## 7b: Teoman otağından yürür, doğan güne eğilir (31 m, 37°; uzun gölgesi batıya); satırın «in the west» sözünde ay karesine
## kesilir (ufuk istisnası: 42 m doğudan, 9°): dolunay ufukta, yurtlar küçük, Teoman uzakta hâlâ eğiliktir.
func _anim_7b(anim: Animation) -> void:
	var length := anim.length
	var start: Dictionary = spots["TeomanStart"]
	var stop: Dictionary = spots["TeomanEnd"]
	var walk_end := minf(TEOMAN_WALK_S, length * 0.23)
	var line_start := 1.0
	var line_len := maxf(line_end - float(shot_starts["7b"]) - line_start, 1.0)
	var moon_cut := minf(line_start + line_len * MOON_CUT_SHARE, length - 0.5)
	_actor_key(anim, "Teoman", 0.0, start["pos"], start["yaw"], &"walk")
	_value(anim, "Actors/Teoman:position", [[0.0, start["pos"]], [walk_end, stop["pos"]]], true)
	_value(anim, "Actors/Teoman:rotation:y", [[0.0, float(start["yaw"])], [walk_end, float(start["yaw"])],
			[walk_end + 0.5, PrologueBirth.near_angle(float(stop["sun_yaw"]), float(start["yaw"]))]], true)
	_discrete(anim, "Actors/Teoman:pose", [[0.0, &"walk"], [walk_end, &"idle"]])
	# Eğiliş: dönüşten sonra 1,6 sn'de eğilir, 2,4 sn durur, 1,4 sn'de doğrulur.
	var bow_in := walk_end + 0.7
	_value(anim, "Actors/Teoman:bow_amount", [[0.0, 0.0], [bow_in, 0.0], [bow_in + 1.6, 1.0], [bow_in + 4.0, 1.0],
			[bow_in + 5.4, 0.0]], true)
	var teoman: Vector3 = stop["pos"]
	_camera(anim, [
		[0.0, spots["sun_cam"], spots["sun_look"], SUN_FOV, teoman],
		[moon_cut, spots["sun_end_cam"], spots["sun_end_look"], SUN_FOV, teoman],
		[moon_cut, spots["moon_cam"], spots["moon_look"], MOON_FOV, teoman, true],
		[length, spots["moon_end_cam"], spots["moon_end_look"], MOON_FOV, teoman, true],
	])


## 7c: Lan yurdu ve sayım hattı aynı uzak karede, kımıltı yok, kamera durur (kara sessizlik konağındır).
func _anim_7c(anim: Animation) -> void:
	_camera(anim, [
		[0.0, spots["line_cam"], spots["line_look"], LINE_FOV, spots["line_subject"]],
		[anim.length, spots["line_cam"], spots["line_look"], LINE_FOV, spots["line_subject"]],
	])


## 7d: aynı uzak kare, kamera yavaşça kayar: ağlama; Hereka kapıdan çıkar ve seslenir; sayıcının çentiği; kart; uzakta turnalar.
func _anim_7d(anim: Animation) -> void:
	var length := anim.length
	var inside: Dictionary = spots["HerekaDoorIn"]
	var out: Dictionary = spots["HerekaDoorOut"]
	# Hereka ağlamadan sonra kapıdan çıkar (0,55–1,55 sn), sayım hattına döner, 1,7'de seslenir.
	var out_at := 0.55 + HEREKA_WALK_S
	_actor_key(anim, "Hereka", 0.0, inside["pos"], inside["yaw"], &"idle")
	_value(anim, "Actors/Hereka:position", [[0.0, inside["pos"]], [0.55, inside["pos"]], [out_at, out["pos"]]], true)
	_value(anim, "Actors/Hereka:rotation:y", [[0.0, float(inside["yaw"])], [out_at - 0.2, float(inside["yaw"])],
			[out_at + 0.15, PrologueBirth.near_angle(float(out["yaw"]), float(inside["yaw"]))]], true)
	_discrete(anim, "Actors/Hereka:pose", [[0.0, &"idle"], [0.55, &"walk"], [out_at, &"idle"]])
	_value(anim, "Actors/Hereka:bow_amount", [[0.0, 0.0], [1.6, 0.0], [1.9, 0.18], [2.6, 0.18], [3.0, 0.0]], true)
	# Seslenirken elleri öne açılır: uzaktan okunur (K98).
	_value(anim, "Actors/Hereka:gesture_amount", [[0.0, 0.0], [1.55, 0.0], [1.85, CALL_GESTURE], [2.6, CALL_GESTURE], [3.0, 0.0]], true)
	var counter: Dictionary = spots["Counter"]
	_actor_key(anim, "Counter", 0.0, counter["pos"], counter["yaw"], &"idle")
	_value(anim, "Actors/Counter:gesture_amount", [[0.0, 0.0], [3.45, 0.0], [3.62, 1.0], [3.78, 0.15], [3.95, 0.8],
			[4.2, 0.0]], true)
	_camera(anim, [
		[0.0, spots["line_cam"], spots["line_look"], LINE_FOV, spots["line_subject"]],
		[length, spots["line_end_cam"], spots["line_look"], LINE_FOV, spots["line_subject"]],
	])
	_crane_track(anim, float(shot_starts["7d"]))


## 7e: Hereka eşi gömer (diz çöker, tümsek belirir; 25 m, güneydoğudan); kesmede beşiğin başındadır (26 m, güneyden), yayı elleriyle
## kemerin altına asar, sonra elleri dizlerinde diz çökmüş kalır; turnaların V'si kadrajın içinden güneye geçer, gölgeleri zeminde.
## Yay ellerle gider: görününce ellerin arasında, asılınca bileklerin ≈0,25 m önünde.
func _anim_7e(anim: Animation) -> void:
	var length := anim.length
	var burial: Dictionary = spots["HerekaBurial"]
	var cradle: Dictionary = spots["HerekaCradle"]
	var cut := minf(3.4, length * 0.42)
	var lift := cut + BOW_LIFT_AT
	var hung_at := cut + BOW_HUNG_AT
	var down := minf(cut + HANDS_DOWN_AT, length)
	var rest := minf(cut + HANDS_REST_AT, length)
	_actor_key(anim, "Hereka", 0.0, burial["pos"], burial["yaw"], &"sit")
	_actor_cut(anim, "Hereka", cut, burial, cradle, &"sit")
	_value(anim, "Actors/Hereka:bow_amount", [[0.0, BURIAL_LEAN], [lift, BURIAL_LEAN], [hung_at, CRADLE_LEAN], [down, CRADLE_LEAN],
			[rest, 0.0], [length, 0.0]], true)
	_value(anim, "Actors/Hereka:gesture_amount", [[0.0, 0.0], [cut, 0.0], [cut + CUT_EPS, CARRY_GESTURE], [lift, CARRY_GESTURE],
			[hung_at, 1.0], [down, 1.0], [rest, 0.0], [length, 0.0]], true)
	_value(anim, "Props/Mound:scale", [[0.0, Vector3.ONE * 0.01], [0.6, Vector3.ONE * 0.01],
			[3.0, Vector3.ONE]], true)
	var hands: Vector3 = spots["BowHands"]["pos"]
	var hung: Vector3 = spots["BowHung"]["pos"]
	_discrete(anim, "Props/CradleBow:visible", [[0.0, false], [cut + CUT_EPS, true]])
	var bow_path: Array = [[0.0, hands], [lift, hands]]
	if spots.has("BowApproach"):
		bow_path.append([cut + BOW_APPROACH_AT, spots["BowApproach"]["pos"]])
	bow_path.append_array([[hung_at, hung], [length, hung]])
	_value(anim, "Props/CradleBow:position", bow_path, true)
	_camera(anim, [
		[0.0, spots["burial_cam"], spots["burial_look"], OUTSIDE_FOV, spots["burial_subject"]],
		[cut, spots["burial_end_cam"], spots["burial_look"], OUTSIDE_FOV, spots["burial_subject"]],
		[cut, spots["cradle_cam"], spots["cradle_look"], OUTSIDE_FOV, spots["Cradle"]],
		[length, spots["cradle_end_cam"], spots["cradle_look"], OUTSIDE_FOV, spots["Cradle"]],
	])
	_crane_track(anim, float(shot_starts["7e"]))


## panel_8: yakınlaşma yok (K98): kamera beşiğin uzak karesinde durur (beşik karenin ortasında), görüntü (video ya da keçe pano)
## 0,4–1,9 sn'de belirir; keçe pano kendi saatiyle açılır.
func _anim_panel(anim: Animation) -> void:
	var length := anim.length
	var cam: Vector3 = spots["cradle_end_cam"]
	_camera(anim, [
		[0.0, cam, spots["cradle_look"], OUTSIDE_FOV, spots["Cradle"]],
		[length, cam, spots["cradle_look"], OUTSIDE_FOV, spots["Cradle"]],
	])
	_value(anim, "PanelLayer/View:modulate", [[0.0, Color(1, 1, 1, 0)], [PANEL_FADE_IN, Color(1, 1, 1, 0)],
			[minf(PANEL_OPAQUE_AT, length), Color.WHITE], [length, Color.WHITE]], true)
	if panel == null:
		return
	_value(anim, "PanelLayer/View/Viewport/Stage/Panel8:anim_time", [[0.0, 0.0], [length, length]], true)
	var keys: Array = (PrologueBirth.panel_def().get("camera", {}) as Dictionary).get("keys", [])
	if not keys.is_empty():
		var path: Array = []
		for k: Variant in keys:
			var a: Array = k
			path.append([minf(float(a[0]), length), Vector3(float(a[1]), float(a[2]), float(a[3]))])
		var track := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, NodePath("PanelLayer/View/Viewport/Stage/PanelCamera:position"))
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
		PrologueBirth.insert_eased(anim, track, path)


## Turnaların ilerlemesi: 7d'nin başından 7e'nin sonuna doğrusal.
func _crane_track(anim: Animation, shot_start: float) -> void:
	var t0 := float(shot_starts["7d"])
	var t1 := float(shot_starts["7e"]) + float(shot_lengths["7e"])
	var span := maxf(t1 - t0, 0.1)
	_value(anim, "Cranes:progress", [[0.0, (shot_start - t0) / span], [anim.length, (shot_start + anim.length - t0) / span]], true)


# --- Canlandırma yardımcıları -----------------------------------------------------------------------

## Kişinin konumu, yönü ve pozu (t anında; konum ve yön doğrusal izler, poz kesikli).
func _actor_key(anim: Animation, node_name: String, t: float, pos: Vector3, yaw: float, pose: StringName) -> void:
	_add_key(anim, "Actors/%s:position" % node_name, t, pos, false)
	_add_key(anim, "Actors/%s:rotation:y" % node_name, t, yaw, false)
	_add_key(anim, "Actors/%s:pose" % node_name, t, pose, true)


## Kişinin kesmesi: t'ye dek from'da durur (izler doğrusaldır, tutma anahtarı olmasa kayardı), kamerayla aynı anda to'ya sıçrar.
func _actor_cut(anim: Animation, node_name: String, t: float, from: Dictionary, to: Dictionary, pose: StringName) -> void:
	_add_key(anim, "Actors/%s:position" % node_name, t, from["pos"], false)
	_add_key(anim, "Actors/%s:rotation:y" % node_name, t, from["yaw"], false)
	_actor_key(anim, node_name, t + CUT_EPS, to["pos"], to["yaw"], pose)


func _value(anim: Animation, path: String, keys: Array, linear: bool = false) -> void:
	for k: Array in keys:
		_add_key(anim, path, float(k[0]), k[1], not linear)


func _discrete(anim: Animation, path: String, keys: Array) -> void:
	for k: Array in keys:
		_add_key(anim, path, float(k[0]), k[1], true)


func _add_key(anim: Animation, path: String, t: float, value: Variant, discrete: bool) -> void:
	var np := NodePath(path)
	var track := anim.find_track(np, Animation.TYPE_VALUE)
	if track == -1:
		track = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, np)
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
		anim.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
	elif not discrete:
		# Aynı ize önce durum (tek anahtar), sonra yürüyen anahtarlar yazılabilir: iz sürekli olur.
		anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	anim.track_insert_key(track, clampf(t, 0.0, anim.length), value)


## Kamera yolu: [[t, konum, bakılan nokta, görüş açısı, konu, ufuk?], ...]. Aynı t'deki iki anahtar kesmedir (ara değer yok);
## öbür aralıklar yumuşak (smoothstep), KEY_STEP'te bir anahtar. Konu (yoksa bakılan nokta) ve ufuk istisnası camera_plan'a yazılır:
## K98'in uzaklık ve eğim kuralı onlarla sınanır.
func _camera(anim: Animation, keys: Array) -> void:
	var plan: Array = camera_plan.get(_plan_shot, [])
	for k: Array in keys:
		plan.append({"t": float(k[0]), "pos": k[1], "look": k[2], "fov": float(k[3]),
			"subject": k[4] if k.size() > 4 else k[2], "horizon": k.size() > 5 and bool(k[5])})
	camera_plan[_plan_shot] = plan
	var pos_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pos_track, ^"Camera:position")
	anim.track_set_interpolation_type(pos_track, Animation.INTERPOLATION_LINEAR)
	var rot_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rot_track, ^"Camera:quaternion")
	anim.track_set_interpolation_type(rot_track, Animation.INTERPOLATION_LINEAR)
	var fov_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fov_track, ^"Camera:fov")
	anim.track_set_interpolation_type(fov_track, Animation.INTERPOLATION_LINEAR)
	for i in keys.size():
		var a: Array = keys[i]
		var t := clampf(float(a[0]), 0.0, anim.length)
		var cut := i > 0 and absf(float((keys[i - 1] as Array)[0]) - float(a[0])) < 0.0001
		if cut:
			t = minf(t + CUT_EPS, anim.length)
		anim.track_insert_key(pos_track, t, a[1])
		anim.track_insert_key(rot_track, t, PrologueBirth.look_quat(a[1], a[2]))
		anim.track_insert_key(fov_track, t, float(a[3]))
		if i + 1 >= keys.size():
			continue
		var b: Array = keys[i + 1]
		var span := float(b[0]) - float(a[0])
		if span < 0.0001:
			continue
		var steps := int(ceil(span / KEY_STEP))
		for k in range(1, steps):
			var u := float(k) / float(steps)
			var w := u * u * (3.0 - 2.0 * u)
			var tk := t + span * u
			var p: Vector3 = (a[1] as Vector3).lerp(b[1], w)
			var look: Vector3 = (a[2] as Vector3).lerp(b[2], w)
			anim.track_insert_key(pos_track, tk, p)
			anim.track_insert_key(rot_track, tk, PrologueBirth.look_quat(p, look))
			anim.track_insert_key(fov_track, tk, lerpf(float(a[3]), float(b[3]), w))


## Bakış yönünün dönüşü (saf): konumdan noktaya bakan kameranın quaternion'u.
static func look_quat(from: Vector3, to: Vector3) -> Quaternion:
	var d := to - from
	if d.length_squared() < 1e-8:
		return Quaternion.IDENTITY
	var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.999 else Vector3.FORWARD
	return Basis.looking_at(d, up).get_rotation_quaternion()


## Yol noktaları ([[t, Vector3], ...]) arasında yumuşak geçiş: her aralığa KEY_STEP'te bir anahtar.
static func insert_eased(anim: Animation, track: int, path: Array) -> void:
	for j in path.size():
		var a: Array = path[j]
		anim.track_insert_key(track, float(a[0]), a[1])
		if j + 1 >= path.size():
			continue
		var b: Array = path[j + 1]
		var span := float(b[0]) - float(a[0])
		var steps := int(ceil(span / KEY_STEP))
		for k in range(1, steps):
			var u := float(k) / float(steps)
			var w := u * u * (3.0 - 2.0 * u)
			anim.track_insert_key(track, float(a[0]) + span * u, (a[1] as Vector3).lerp(b[1], w))


## Açıyı başvuru açısına en yakın eşdeğerine taşır (saf; yön ara değeri kısa yoldan dönsün).
static func near_angle(angle: float, reference: float) -> float:
	return reference + wrapf(angle - reference, -PI, PI)


# --- Yerler -----------------------------------------------------------------------------------------

## Lan Hatun'un yurdunun dönüşümü (dünyadan; yoksa düzen dosyasından: kapı door_az'a bakar).
func _yurt_transform() -> Transform3D:
	var yurt := world.call(&"place", "lan_yurt") as Node3D if world and world.has_method(&"place") else null
	if yurt:
		return yurt.global_transform
	var def: Dictionary = (layout.get("places", {}) as Dictionary).get("lan_yurt", {})
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	return Transform3D(OrdosWorld.door_basis(float(def.get("door_az", 90.0))), Vector3(at.x, _ground_y(at.x, at.y), at.y))


## Yurdun yerel noktası dünyada (yerel +Z kapı, +X kadınların yanı).
func _yurt(local: Vector3) -> Vector3:
	return _yurt_transform() * local


func _ground_y(x: float, z: float) -> float:
	if world and world.has_method(&"get_terrain_shape"):
		var shape: Variant = world.call(&"get_terrain_shape")
		if shape is OrdosGround:
			return (shape as OrdosGround).height_at(x, z)
	return ground.height_at(x, z) if ground else 0.0


func _marker(id: String) -> Vector3:
	var at := OrdosGround._vec2((layout.get("markers", {}) as Dictionary).get(id, [0.0, 0.0]))
	return Vector3(at.x, _ground_y(at.x, at.y), at.y)


## Bütün yerleri hesaplar (dünya ya da düzen dosyası; ışık örneklerinin güneş ve ay yönü).
func _compute_spots() -> void:
	var yt := _yurt_transform()
	var floor_y := yt.origin.y
	spots["floor_y"] = floor_y
	spots["ember"] = yt * Vector3(0.0, 0.05, 0.0)
	spots["door_stone"] = yt * Vector3(0.0, 0.0, DOOR_STONE_RING)
	# Lan Hatun döşeğin kuzey kenarında, yüzü tör'e (batıya): sağ yanı kerege duvarına yakın, sağ eli keregeyi tutar. Kolu uzanıktır, kapanan
	# el (K92) parmak köküne dek gelir: kişinin yeri elin astara değdiği yerdir (2026-11-07: 4 cm yaklaştı, el astara 0,5 cm). Hereka
	# döşeğin ayakucunda ona bakar, birinci kadın döşeğin köşesinde köze bakar (ellerini ısıtır): oturuşların köşeleri döşeğe,
	# ocağa ve astara girmesin diye (çeşitleriyle ölçüldü). İkinci kadın döşeğin üstünde, yanı başındadır: tek dizini diker, öndeki ayağı düğümden
	# 0,8 m uzanır, Lan Hatun'un sırtına ≈4 cm kalır; bacakları döşekten taşmaz (2026-11-07).
	var lan := yt * Vector3(1.72, 0.14, -0.25)
	_spot("LanHatun", lan, yt * Vector3(1.72, 0.14, -2.0))
	_spot("Hereka", yt * Vector3(1.1, 0.0, -1.7), lan)
	# Bedeni zemine iner (ClipLibrary.fit_legs): uyluğu döşekten alçakta kalır, döşeğin köşesinden 13 cm geride oturur.
	_spot("LanWomanA", yt * Vector3(0.72, 0.0, -1.2), yt * Vector3.ZERO)
	_spot("LanWomanB", yt * Vector3(1.2, 0.14, 0.6), lan)
	# Kapı ışığı ve kart (7a): ışık kapının dışında, eşik taşına bakar; kart ışıkla taşın arasında durur.
	var door_dir := (yt.basis * Vector3.BACK).normalized()
	var door := yt * Vector3(0.0, 0.0, 2.88)
	var light := door + door_dir * DOOR_LIGHT_OUT + Vector3(0.0, DOOR_LIGHT_UP, 0.0)
	spots["door_light"] = light
	var stone: Vector3 = spots["door_stone"]
	var top_end := card_top_for(light, stone, floor_y + CARD_HEIGHT)
	var end := Vector3(top_end.x, floor_y, top_end.z)
	spots["card_end"] = end
	spots["card_start"] = end + door_dir * SHADOW_START_BACK
	# 7a'nın dioraması (K98): kamera yurdun güneybatısından, yüksekten közden açılır; bakış çekim boyunca kapıya doğru kayar.
	var ember: Vector3 = spots["ember"]
	var door_az := rad_to_deg(atan2(door_dir.x, -door_dir.z))
	spots["inside_cam"] = PrologueBirth.orbit(ember, door_az + INSIDE_OPEN.x, INSIDE_OPEN.y, INSIDE_OPEN.z)
	var inside_look: Vector3 = yt * INSIDE_DRIFT
	spots["inside_look"] = inside_look
	spots["inside_end_cam"] = PrologueBirth.orbit(inside_look, door_az + INSIDE_END.x, INSIDE_END.y, INSIDE_END.z)
	# Teoman: otağın kapısından doğan güne.
	var sun := _sample_dir("outside", "sun_dir", Vector3(1.0, 0.0, 0.05))
	var moon := _sample_dir("outside", "moon_dir", Vector3(-1.0, 0.04, 0.0))
	var sun_h := Vector3(sun.x, 0.0, sun.z).normalized()
	var moon_h := Vector3(moon.x, 0.0, moon.z).normalized()
	var otag: Dictionary = (layout.get("places", {}) as Dictionary).get("teoman_otag", {})
	var otag_at := OrdosGround._vec2(otag.get("at", [-10.0, -22.0]))
	var otag_r := float(otag.get("radius", 4.4))
	var otag_door := Vector3(otag_at.x + otag_r * 0.93, 0.0, otag_at.y)
	var t_start := otag_door + Vector3(-0.7, 0.0, 0.0)
	t_start.y = _ground_y(t_start.x, t_start.z)
	var t_end := otag_door + sun_h * TEOMAN_WALK
	t_end.y = _ground_y(t_end.x, t_end.z)
	_spot("TeomanStart", t_start, t_end)
	_spot("TeomanEnd", t_end, t_end + sun_h * 10.0)
	spots["TeomanEnd"]["sun_yaw"] = CampNpcs.facing_yaw(t_end, t_end + sun_h * 10.0)
	spots["teoman_walk"] = t_start.distance_to(t_end)
	# Doğan güne eğiliş (K98): kamera güneyden, yüksekten bakar; bakış Teoman'ın batısında, alçak güneşin düşürdüğü uzun gölgenin
	# üstündedir. Ay karesi (ufuk istisnası): Teoman'ın doğusundan ve güneyinden, yüksekten dolunaya (batıya) bakar, eğim 9°.
	var west := -sun_h
	spots["sun_look"] = t_end + west * SUN_LOOK_WEST.x + Vector3(0.0, 0.6, 0.0)
	spots["sun_end_look"] = t_end + west * SUN_LOOK_WEST.y + Vector3(0.0, 0.6, 0.0)
	spots["sun_cam"] = PrologueBirth.orbit(spots["sun_look"], SUN_OPEN.x, SUN_OPEN.y, SUN_OPEN.z)
	spots["sun_end_cam"] = PrologueBirth.orbit(spots["sun_end_look"], SUN_END.x, SUN_END.y, SUN_END.z)
	var side := Vector3(-moon_h.z, 0.0, moon_h.x)
	var moon_cam := t_end - moon_h * MOON_BACK - side * MOON_SIDE
	moon_cam.y = t_end.y + MOON_HEIGHT
	var moon_view := (moon_h * cos(deg_to_rad(MOON_PITCH_DEG)) + Vector3.DOWN * sin(deg_to_rad(MOON_PITCH_DEG))) * 100.0
	spots["moon_cam"] = moon_cam
	spots["moon_look"] = moon_cam + moon_view
	spots["moon_end_cam"] = moon_cam - side * MOON_DRIFT
	spots["moon_end_look"] = spots["moon_end_cam"] + moon_view
	var lan_in := yt * Vector3(0.0, 0.0, 2.15)
	var lan_out := yt * Vector3(0.12, 0.0, 3.55)
	var line_mid := _line_middle()
	_spot("HerekaDoorIn", lan_in, lan_out)
	_spot("HerekaDoorOut", lan_out, line_mid)
	var counter := _marker("counter")
	_spot("Counter", counter, counter + Vector3(-1.2, 0.0, 3.0))
	# 7c ve 7d (K98): kapı ile sayıcı aynı uzak karede; kamera güneydoğudan ikisine ≈40 m'den bakar, 7d'de yavaşça kayar.
	var line_subject := (lan_out + counter) * 0.5
	spots["line_subject"] = line_subject
	spots["line_look"] = line_subject + Vector3(0.0, 0.5, 0.0)
	spots["line_cam"] = PrologueBirth.orbit(spots["line_look"], LINE_FRAME.x, LINE_FRAME.y, LINE_FRAME.z)
	spots["line_end_cam"] = PrologueBirth.orbit(spots["line_look"], LINE_END.x, LINE_END.y, LINE_END.z)
	# Gömü ve beşik (7e).
	var burial := _marker("burial")
	var mound := burial + Vector3(0.55, 0.0, -0.2)
	mound.y = _ground_y(mound.x, mound.z)
	spots["Mound"] = mound
	_spot("HerekaBurial", burial + Vector3(-0.1, 0.0, 0.1), mound)
	var cradle := _marker("cradle")
	spots["Cradle"] = cradle
	# Beşiğin başında diz çöker: dizler beşiğin kuzey yüzünde durur (giysi en çok 4 cm girer, beşiğin ardında kalır), eller kemerin
	# altına yetişir.
	var stand := cradle + Vector3(-0.15, 0.0, -0.64)
	stand.y = _ground_y(stand.x, stand.z)
	_spot("HerekaCradle", stand, cradle)
	spots["ArchTop"] = cradle + Vector3(0.0, arch_top_height(), 0.0)
	var hung := cradle + bow_hung_offset()
	spots["BowHung"] = {"pos": hung}
	if _cradle_model:
		spots["BowApproach"] = {"pos": hung + BOW_APPROACH}
	var face := Vector3(cradle.x - stand.x, 0.0, cradle.z - stand.z).normalized()
	spots["BowHands"] = {"pos": stand + face * BOW_CARRY_FORWARD + Vector3(0.0, BOW_CARRY_UP, 0.0)}
	# 7e (K98): gömü güneydoğudan, beşik güneyden, ikisi de uzak ve yüksek; panel_8 beşiğin karesinde durur (beşik ortaya yakın).
	var burial_subject := (burial + mound) * 0.5
	spots["burial_subject"] = burial_subject
	spots["burial_look"] = burial_subject + Vector3(0.0, 0.4, 0.0)
	spots["burial_cam"] = PrologueBirth.orbit(spots["burial_look"], BURIAL_FRAME.x, BURIAL_FRAME.y, BURIAL_FRAME.z)
	spots["burial_end_cam"] = PrologueBirth.orbit(spots["burial_look"], BURIAL_END.x, BURIAL_END.y, BURIAL_END.z)
	spots["cradle_look"] = cradle + Vector3(CRADLE_LOOK_EAST, 0.35, 0.0)
	spots["cradle_cam"] = PrologueBirth.orbit(spots["cradle_look"], CRADLE_FRAME.x, CRADLE_FRAME.y, CRADLE_FRAME.z)
	spots["cradle_end_cam"] = PrologueBirth.orbit(spots["cradle_look"], CRADLE_END.x, CRADLE_END.y, CRADLE_END.z)
	# Turnalar: 7e'nin CRANE_PASS'ında V'nin başı beşiğin doğusunda, zeminden alçaktadır (beşiğin karesinin içi), güneye (+z).
	var crane_pass := cradle + CRANE_OFFSET
	crane_pass.y = _ground_y(crane_pass.x, crane_pass.z) + CRANE_OFFSET.y
	spots["crane_pass"] = crane_pass


## Kemerin tepesinin beşiğin düğümüne göre yüksekliği: modelli beşikte modelden ölçülür, kodla çizimde ölçülerden gelir.
func arch_top_height() -> float:
	if _cradle_model:
		return _cradle_model.get_model_aabb().end.y
	return CRADLE_LIFT + CRADLE_SIZE.y + ARCH_RISE


## Yayın asılı yeri beşiğin düğümüne göre: modelli beşikte parçanın özgün yeri (ortası), kodla çizimde kemerin 0,2 m altı.
func bow_hung_offset() -> Vector3:
	if _cradle_model:
		return _cradle_model.model_to_local(_bow_center)
	return Vector3(0.0, CRADLE_LIFT + CRADLE_SIZE.y + ARCH_RISE - 0.2, 0.0)


## Kundağın ortası beşiğin düğümüne göre.
func swaddle_offset() -> Vector3:
	if _cradle_model:
		return _cradle_model.model_to_local(SWADDLE_SPOT)
	return Vector3(0.05, CRADLE_LIFT + 0.17, 0.0)


## Konuya yukarıdan bakan kameranın yeri (saf): yön az (derece; konudan kameraya, kuzeyden saat yönünde: 90 doğu, 180 güney),
## eğim (derece, aşağı) ve uzaklık (m). Kamera konuya bakınca eğimi pitch_deg'dir.
static func orbit(target: Vector3, az_deg: float, pitch_deg: float, dist: float) -> Vector3:
	var a := deg_to_rad(az_deg)
	var p := deg_to_rad(pitch_deg)
	return target + Vector3(sin(a) * cos(p), sin(p), -cos(a) * cos(p)) * dist


func _spot(spot_name: String, pos: Vector3, look: Vector3) -> void:
	var yaw := CampNpcs.facing_yaw(pos, look)
	spots[spot_name] = {"pos": pos, "yaw": 0.0 if is_nan(yaw) else yaw}


func _line_middle() -> Vector3:
	var line: Dictionary = layout.get("counting_line", {})
	var a := OrdosGround._vec2(line.get("from", [30.0, -16.0]))
	var b := OrdosGround._vec2(line.get("to", [30.0, 14.0]))
	var m := (a + b) * 0.5
	return Vector3(m.x, _ground_y(m.x, m.y), m.y)


func _sample_dir(sample_id: String, key: String, fallback: Vector3) -> Vector3:
	var s: Dictionary = _samples.get(sample_id, {})
	var v: Variant = s.get(key)
	return (v as Vector3).normalized() if v is Vector3 and (v as Vector3).length_squared() > 1e-8 else fallback.normalized()


# --- Kişiler ------------------------------------------------------------------------------------------

func _build_actor(node_name: String) -> void:
	var a := actor(node_name)
	if a == null or a.is_built():
		return
	match node_name:
		"LanHatun":
			# Sağ kol yana ve yukarı, kerege astarına değer (el köşeleri astara ≤2 cm; CineBow dönüşleri; göz onayı bekler).
			a.reach_turns = [["RightArm", "up", 50.0], ["RightArm", "forward", -110.0], ["RightForeArm", "forward", -35.0]]
			a.reach_grips = {&"Right": 0.85}
		"Counter":
			# Çentik: sağ kol öne kalkar, ön kol iner (uzaktan okunsun diye kol da kalkar; K98).
			a.gesture_turns = [["RightArm", "lateral", -35.0], ["RightForeArm", "lateral", -55.0]]
		"Hereka":
			# Beşiğe yay asış (diz çökmüşken): iki kol öne ve yukarı. Kapıdan çıkışın yürüme hızı.
			a.gesture_turns = [["LeftArm", "lateral", -70.0], ["RightArm", "lateral", -70.0]]
			a.gesture_grips = {&"Left": 0.9, &"Right": 0.9}
			a.walk_speed = float(spots["HerekaDoorIn"]["pos"].distance_to(spots["HerekaDoorOut"]["pos"])) / HEREKA_WALK_S
		"Teoman":
			a.walk_speed = float(spots.get("teoman_walk", TEOMAN_WALK)) / TEOMAN_WALK_S
	a.build()
	if INSIDE_ACTORS.has(node_name):
		for mesh: Node in a.find_children("*", "VisualInstance3D", true, false):
			(mesh as VisualInstance3D).layers |= ACTOR_LIGHT_LAYER


func _ensure_idle(node_name: String) -> void:
	var a := actor(node_name)
	if a == null:
		return
	if not a.is_built():
		_build_actor(node_name)
	a.ensure_idle(CineActor.WARM_ROLES if WALKERS.has(node_name) else STANDING_ROLES)


## Sayıcının çentik çubuğu sağ eline bağlanır (RemoteTransform3D: çubuk Props altında kalır).
func _attach_tally() -> void:
	var counter := actor("Counter")
	var stick := props.get_node_or_null(^"TallyStick") as Node3D
	if counter == null or stick == null or counter.avatar == null:
		return
	var skeleton := counter.avatar.get_skeleton()
	if skeleton == null or skeleton.find_bone("RightHand") < 0 or skeleton.has_node(^"TallyHand"):
		return
	var attach := BoneAttachment3D.new()
	attach.name = "TallyHand"
	attach.bone_name = "RightHand"
	skeleton.add_child(attach)
	var remote := RemoteTransform3D.new()
	remote.name = "Remote"
	remote.update_scale = false
	attach.add_child(remote)
	remote.remote_path = remote.get_path_to(stick)


## Birden çok karede kurulumun hepsi ve bütün bekleme klipleri (sınama).
func build_all() -> void:
	flush()
	_ensure_idles(SHOTS[SHOTS.size() - 1])


## Çekime dek ayakta duracak kişilerin bekleme klipleri (IDLE_AT; aktarılmışsa bir şey yapmaz).
func _ensure_idles(shot: String) -> void:
	var index := SHOTS.find(shot)
	for at: String in IDLE_AT:
		if SHOTS.find(at) <= index:
			for node_name: String in IDLE_AT[at]:
				_ensure_idle(node_name)


# --- Ocak -------------------------------------------------------------------------------------------

func _hearth() -> HearthEmbers:
	return world.call(&"hearth") as HearthEmbers if world and world.has_method(&"hearth") else null


## Ocağın kodla çizilen üç taşı gizlenir, yerlerine ücretsiz taşlar (moon_rock_02) ve taş halkalı ocak çukuru
## (stone_fire_pit) konur. Restore taşları geri getirir.
func _swap_hearth() -> void:
	var hearth := _hearth()
	var stones := props.get_node_or_null(^"Hearth") as Node3D
	if stones == null:
		return
	if hearth == null:
		stones.visible = false
		return
	stones.visible = true
	stones.global_transform = hearth.global_transform
	for i in HearthEmbers.STONE_NAMES.size():
		var code := hearth.get_node_or_null(NodePath(HearthEmbers.STONE_NAMES[i])) as MeshInstance3D
		var free := stones.get_node_or_null(NodePath("Stone%d" % i)) as Node3D
		if code == null or free == null:
			continue
		_hidden.append([code, code.visible])
		code.visible = false
		# Ücretsiz taş kodla taşın yerine, yönüne ve boyuna oturur (kodla taş ölçekli birim kayadır).
		var scale := code.transform.basis.get_scale()
		free.transform = Transform3D(code.transform.basis.orthonormalized(), code.transform.origin)
		var model := free.get_node_or_null(^"Model") as Node3D
		if model and code.mesh:
			var box := code.mesh.get_aabb()
			var dims := box.size * scale
			model.scale = Vector3(dims.x / ROCK_SIZE.x, dims.y / ROCK_SIZE.y, dims.z / ROCK_SIZE.z)
			model.position = Vector3(0.0, box.position.y * scale.y, 0.0)


# --- Eşyalar ----------------------------------------------------------------------------------------

func _build_props() -> void:
	_build_hearth_props()
	_build_kitchen()
	_build_cradle()
	_build_cradle_bow()
	_build_mound()
	_build_door_light()
	_build_tally()


## Eşyaların yerleri (dünya gelince yeniden).
func _place_props() -> void:
	var yt := _yurt_transform()
	var kitchen := props.get_node_or_null(^"Kitchen") as Node3D
	if kitchen:
		kitchen.global_transform = yt
	var cradle := props.get_node_or_null(^"Cradle") as Node3D
	if cradle:
		cradle.global_position = spots["Cradle"]
	var swaddle := props.get_node_or_null(^"Swaddle") as Node3D
	if swaddle:
		swaddle.global_position = spots["Cradle"] + swaddle_offset()
	var mound := props.get_node_or_null(^"Mound") as Node3D
	if mound:
		mound.global_position = spots["Mound"]
	var bow := props.get_node_or_null(^"CradleBow") as Node3D
	if bow:
		bow.global_position = spots["BowHung"]["pos"]
	var light := props.get_node_or_null(^"DoorLight") as SpotLight3D
	if light:
		light.global_transform = Transform3D(Basis.looking_at(spots["door_stone"] - spots["door_light"], Vector3.UP), spots["door_light"])
	var card := props.get_node_or_null(^"ShadowCard") as Node3D
	if card:
		card.global_position = spots["card_start"]
		var door_dir: Vector3 = (spots["card_start"] - spots["card_end"])
		door_dir.y = 0.0
		if door_dir.length_squared() > 1e-6:
			# Kartın yüzü ışığa bakar (gölgesi en geniş düşsün).
			card.global_basis = Basis(Vector3.UP, atan2(door_dir.x, door_dir.z))
	var hearth := props.get_node_or_null(^"Hearth") as Node3D
	if hearth:
		hearth.global_transform = yt
	var mask := props.get_node_or_null(^"DoorMask") as Node3D
	if mask:
		mask.global_transform = yt
	var crown := props.get_node_or_null(^"CrownLight") as Node3D
	if crown:
		crown.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), yt * Vector3(0.0, CROWN_LIGHT_UP, 0.0))
	var fill := props.get_node_or_null(^"InteriorFill") as Node3D
	if fill:
		fill.global_position = yt * Vector3(0.0, FILL_LIGHT_UP, 0.0)
	# Turnaların gölge izi beşiğin karesinin zemininde.
	if is_instance_valid(cranes):
		cranes.ground_y = float((spots.get("Cradle", Vector3.ZERO) as Vector3).y)


func _build_hearth_props() -> void:
	var node := Node3D.new()
	node.name = "Hearth"
	props.add_child(node)
	var pit := _model_instance("stone_fire_pit", "FirePit", node)
	if pit:
		pit.scale = Vector3.ONE * FIRE_PIT_SCALE
		pit.position = Vector3(0.0, -FIRE_PIT_SINK, 0.0)
	for i in 3:
		var holder := Node3D.new()
		holder.name = "Stone%d" % i
		node.add_child(holder)
		var rock := _model_instance("moon_rock_02", "Model", holder, Color(0.62, 0.58, 0.54))
		if rock:
			rock.set_meta(&"free_asset", "moon_rock_02")
		holder.set_meta(&"free_asset", "moon_rock_02")


## Kap kacak: ocağın güneyinde ve doğusunda (yurdun yerel uzayında), döşeğin yanına katlanmış keçe.
func _build_kitchen() -> void:
	var node := Node3D.new()
	node.name = "Kitchen"
	props.add_child(node)
	var items := [["wooden_bowl_01", "BowlLarge", Vector3(-0.95, 0.008, 0.62), 20.0],
		["carved_wooden_plate", "Plate", Vector3(-0.82, 0.008, -0.55), -10.0],
		["wooden_bowl_02", "BowlSmall", Vector3(-0.6, 0.008, -0.86), 0.0],
		["wooden_spoon", "Spoon", Vector3(-0.8, 0.03, -0.52), 64.0]]
	for item: Array in items:
		var m := _model_instance(str(item[0]), str(item[1]), node)
		if m:
			m.position = item[2]
			m.rotation.y = deg_to_rad(float(item[3]))
	_box(node, "BedFold", BED_FOLD_SIZE, BED_FOLD_AT, Style.toon(Style.FELT.darkened(0.08), {"brush_strength": 0.2}))


## Beşik ve kundak: modelleri varsa onlar, yoksa kodla çizim. Beşiğin modeli uzun ekseni doğu–batı (model X) ve yüzü güneye
## (model +Z) bakar; CRADLE_SIZE'ın boy ve derinliğine sığar, tabanı düğümün yerinde (zeminde) durur.
func _build_cradle() -> void:
	var cradle := Node3D.new()
	cradle.name = "Cradle"
	props.add_child(cradle)
	_cradle_model = _add_model(cradle, CRADLE_MODEL, Vector3(CRADLE_SIZE.x, 0.0, CRADLE_SIZE.z))
	if _cradle_model == null:
		_draw_cradle(cradle)
	var swaddle := Node3D.new()
	swaddle.name = "Swaddle"
	props.add_child(swaddle)
	var baby := _add_model(swaddle, SWADDLE_MODEL, Vector3.ZERO, SWADDLE_LENGTH)
	if baby:
		baby.transform = PrologueBirth.swaddle_lay(SWADDLE_LENGTH)
		# Malzemenin zemin koyulaşması modelin tabanını zemin sayar: yatık kundakta ayak ucu koyulaşırdı.
		baby.set_shader_parameter(&"base_shade_strength", 0.0)
	else:
		_draw_swaddle(swaddle)


## Meshy modelinin düğümü parent altında («Model»: gerçek boyuna ölçekli, tabanı düğümün yerinde, AtW dokulu malzemeyle).
## fit verilirse o kutuya, verilmezse size boyuna sığar. Model yoksa null (çağıran kodla çizer).
func _add_model(parent: Node3D, id: String, fit: Vector3 = Vector3.ZERO, size: float = 1.0) -> MeshyProp:
	if not MeshyProp.exists(PROP_FOLDER, id):
		return null
	var prop := MeshyProp.new()
	prop.name = "Model"
	prop.model_id = id
	prop.folder = PROP_FOLDER
	prop.fit_box = fit
	prop.target_size = size
	parent.add_child(prop)
	if prop.has_model():
		return prop
	parent.remove_child(prop)
	prop.free()
	return null


## Ayakta duran kundak modelini (baş +Y, yüz +Z, taban düğümün yerinde) yatıran dönüşüm (saf): baş batıya (beşiğin yastığı),
## yüz yukarı, baş SWADDLE_TILT_DEG yüksekte; kundağın ortası ebeveynin yerine gelir.
static func swaddle_lay(length: float) -> Transform3D:
	var lying := Basis(Vector3.FORWARD, Vector3.LEFT, Vector3.UP)
	var tilted := Basis(Vector3.BACK, -deg_to_rad(SWADDLE_TILT_DEG)) * lying
	return Transform3D(tilted, -(tilted * Vector3(0.0, length * 0.5, 0.0)))


## Modelin kendi (ölçeksiz) sınır kutusu: sahne örneklenir, ölçülür, bırakılır (saf).
static func model_bounds(path: String) -> AABB:
	var scene := load(path) as PackedScene
	var root := scene.instantiate() as Node3D if scene else null
	if root == null:
		return AABB()
	var box := Kopuz.visual_bounds(root)
	root.free()
	return box


## Kodla beşik (yedek; konsepti assets/_concepts/cradle.png): iki yan, iki baş tahtası ve kemer (wood_table_worn), iki salıncak
## ayağı, koyun postu döşek (curly_teddy_natural), deri kayışlar (leather007).
func _draw_cradle(cradle: Node3D) -> void:
	var wood := PrologueBirth.textured(FREE_TEXTURES["wood_table_worn"], Color(1.0, 0.92, 0.84))
	var frame := Node3D.new()
	frame.name = "Frame"
	frame.set_meta(&"free_asset", "wood_table_worn")
	cradle.add_child(frame)
	var s := CRADLE_SIZE
	var base_y := CRADLE_LIFT
	var board := 0.035
	_box(frame, "SideN", Vector3(s.x, s.y, board), Vector3(0.0, base_y + s.y * 0.5, -s.z * 0.5), wood)
	_box(frame, "SideS", Vector3(s.x, s.y, board), Vector3(0.0, base_y + s.y * 0.5, s.z * 0.5), wood)
	_box(frame, "Head", Vector3(board, s.y + 0.08, s.z), Vector3(-s.x * 0.5, base_y + (s.y + 0.08) * 0.5, 0.0), wood)
	_box(frame, "Foot", Vector3(board, s.y + 0.08, s.z), Vector3(s.x * 0.5, base_y + (s.y + 0.08) * 0.5, 0.0), wood)
	_box(frame, "Floor", Vector3(s.x, board, s.z), Vector3(0.0, base_y + board * 0.5, 0.0), wood)
	for side in [-1.0, 1.0]:
		var rocker := MeshInstance3D.new()
		rocker.name = "Rocker%s" % ("N" if side < 0.0 else "S")
		rocker.mesh = PrologueBirth.arc_bar(s.x * 0.62, 0.12, 0.045, 0.03, 12, true)
		rocker.material_override = wood
		rocker.position = Vector3(0.0, 0.0, side * s.z * 0.36)
		rocker.set_meta(&"free_asset", "wood_table_worn")
		frame.add_child(rocker)
	var arch := MeshInstance3D.new()
	arch.name = "Arch"
	arch.mesh = PrologueBirth.arc_bar(s.x * 0.5, ARCH_RISE + 0.04, 0.04, 0.035, 18, false)
	arch.material_override = wood
	arch.position = Vector3(0.0, base_y + s.y, 0.0)
	arch.set_meta(&"free_asset", "wood_table_worn")
	frame.add_child(arch)
	for child in frame.get_children():
		child.set_meta(&"free_asset", "wood_table_worn")
	var fleece := _box(cradle, "Bedding", Vector3(s.x - 0.08, 0.07, s.z - 0.08), Vector3(0.0, base_y + 0.08, 0.0),
			PrologueBirth.textured(FREE_TEXTURES["curly_teddy_natural"], Color(1.0, 0.97, 0.9)))
	fleece.set_meta(&"free_asset", "curly_teddy_natural")
	var leather := PrologueBirth.textured(FREE_TEXTURES["leather007"], Color(0.9, 0.7, 0.55))
	var straps := Node3D.new()
	straps.name = "Straps"
	straps.set_meta(&"free_asset", "leather007")
	cradle.add_child(straps)
	for i in 3:
		var x := (float(i) - 1.0) * s.x * 0.3
		var strap := _box(straps, "Strap%d" % i, Vector3(0.05, 0.012, s.z + 0.05), Vector3(x, base_y + s.y + 0.006, 0.0), leather)
		strap.set_meta(&"free_asset", "leather007")


## Kodla kundak (yedek): krem keçe sargı (fabric044), kızıl dokuma bant (beşikte; 7e'den sonra görünür).
func _draw_swaddle(swaddle: Node3D) -> void:
	swaddle.set_meta(&"free_asset", "fabric044")
	var wrap := MeshInstance3D.new()
	wrap.name = "Wrap"
	wrap.mesh = Procedural3D.capsule(0.09, 0.32)
	wrap.material_override = PrologueBirth.textured(FREE_TEXTURES["fabric044"], Color(1.0, 0.95, 0.86))
	wrap.rotation = Vector3(0.0, 0.0, PI * 0.5)
	wrap.set_meta(&"free_asset", "fabric044")
	swaddle.add_child(wrap)
	var band := MeshInstance3D.new()
	band.name = "Band"
	band.mesh = Procedural3D.cylinder(0.095, 0.095, 0.05, 16)
	band.material_override = Style.toon(Color(0.62, 0.14, 0.1))
	band.rotation = Vector3(0.0, 0.0, PI * 0.5)
	swaddle.add_child(band)
	var face := MeshInstance3D.new()
	face.name = "Face"
	face.mesh = Procedural3D.sphere(0.045, 0.9)
	face.material_override = Style.toon(Style.SKIN_WARM)
	face.position = Vector3(-0.2, 0.03, 0.0)
	swaddle.add_child(face)


## Beşiğin küçük ok-yayı. Düğümün yeri görüntünün ortasıdır: 7e'de ellerden asılı yerine yürür. Modeli yoksa kodla çizilir.
func _build_cradle_bow() -> void:
	var node := Node3D.new()
	node.name = "CradleBow"
	props.add_child(node)
	if not _build_bow_model(node):
		_draw_cradle_bow(node)


## Beşiğin ağından ayrılan yay, sadak ve ipler (cradle_bow.glb): köşeleri cradle.glb ile aynı model uzayındadır, gövdenin
## ölçeğiyle gösterilir ve ortası düğümün yerine gelir; böylece asılı yerinde (bow_hung_offset) özgün yerine oturur. Yeri ve
## ölçeği gövdeden geldiği için yalnız modelli beşikle kurulur.
func _build_bow_model(node: Node3D) -> bool:
	if _cradle_model == null or not MeshyProp.exists(PROP_FOLDER, BOW_MODEL):
		return false
	var box := PrologueBirth.model_bounds(MeshyProp.model_path(PROP_FOLDER, BOW_MODEL))
	var height := box.size.y * _cradle_model.get_model_scale()
	var prop := _add_model(node, BOW_MODEL, Vector3.ZERO, height)
	if prop == null:
		return false
	prop.position = Vector3(0.0, -height * 0.5, 0.0)
	# Havada asılı: sadağın dibi zemin sayılıp aynı dokudaki gövdeden koyu görünmesin.
	prop.set_shader_parameter(&"base_shade_strength", 0.0)
	_bow_center = box.get_center()
	return true


## Kodla ok-yay (yedek): ücretsiz bileşik yay (composite_bow; 37 yüzey tek malzemeye göre ikiye birleşir), açık ahşap ve krem
## kiriş, kabzada kızıl düğüm; yanında kodla küçük ok. Beşiğin kemerinden iki iple asılır.
func _draw_cradle_bow(node: Node3D) -> void:
	var src := _resource(FREE_MODELS["composite_bow"]) as Mesh
	var bow := MeshInstance3D.new()
	bow.name = "Bow"
	bow.set_meta(&"free_asset", "composite_bow")
	if src:
		var merged := PrologueBirth.merge_by_material(src)
		bow.mesh = merged
		var k := BOW_LENGTH / maxf(src.get_aabb().size.y, 0.001)
		# Yay yatay asılır: modelin boyu (y) beşiğin ekseni (x) olur, sırtı aşağı.
		bow.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3.ONE * k), Vector3.ZERO)
		for i in merged.get_surface_count():
			var surface := merged.surface_get_name(i)
			bow.set_surface_override_material(i, Style.toon(Color(0.93, 0.86, 0.7) if surface == "string" else Color(0.62, 0.42, 0.22),
					{"brush_strength": 0.12}))
	node.add_child(bow)
	var knot := MeshInstance3D.new()
	knot.name = "Knot"
	knot.mesh = Procedural3D.torus(0.008, 0.02)
	knot.material_override = Style.toon(Color(0.68, 0.14, 0.1))
	knot.position = Vector3(0.0, -0.045, 0.0)
	knot.rotation = Vector3(0.0, 0.0, PI * 0.5)
	node.add_child(knot)
	var arrow := Node3D.new()
	arrow.name = "Arrow"
	arrow.position = Vector3(0.0, -0.06, 0.03)
	node.add_child(arrow)
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	shaft.mesh = Procedural3D.cylinder(0.004, 0.004, 0.4, 6)
	shaft.material_override = Style.toon(Color(0.78, 0.62, 0.4))
	shaft.rotation = Vector3(0.0, 0.0, PI * 0.5)
	arrow.add_child(shaft)
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = Procedural3D.cylinder(0.0, 0.012, 0.035, 4)
	head.material_override = Style.toon(Color(0.6, 0.58, 0.54))
	head.position = Vector3(0.215, 0.0, 0.0)
	head.rotation = Vector3(0.0, 0.0, -PI * 0.5)
	arrow.add_child(head)
	for side in [-1.0, 1.0]:
		var vane := MeshInstance3D.new()
		vane.name = "Fletch%s" % ("A" if side < 0.0 else "B")
		vane.mesh = Procedural3D.box(Vector3(0.06, 0.018, 0.002))
		vane.material_override = Style.toon(Color(0.86, 0.8, 0.72))
		vane.position = Vector3(-0.17, side * 0.006, 0.0)
		vane.rotation = Vector3(side * 0.5, 0.0, 0.0)
		arrow.add_child(vane)
	for side in [-1.0, 1.0]:
		var cord := MeshInstance3D.new()
		cord.name = "Cord%s" % ("W" if side < 0.0 else "E")
		cord.mesh = Procedural3D.cylinder(0.003, 0.003, 0.2, 4)
		cord.material_override = Style.toon(Color(0.68, 0.14, 0.1))
		cord.position = Vector3(side * 0.12, 0.1, 0.0)
		node.add_child(cord)


## Eşin gömüldüğü toprak tümseği (dirt): yarım küre, 7e'de büyür.
func _build_mound() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.34
	mesh.height = 0.22
	mesh.is_hemisphere = true
	mesh.radial_segments = 20
	mesh.rings = 6
	var mound := MeshInstance3D.new()
	mound.name = "Mound"
	mound.mesh = mesh
	# Doku koyudur, şafakta tümseğin kameraya bakan yüzü de gölgede kalır: renk açık tutulur, kara bir leke gibi durmaz.
	mound.material_override = PrologueBirth.textured(FREE_TEXTURES["dirt"], Color(1.35, 1.1, 0.88))
	mound.scale = Vector3.ONE * 0.01
	mound.set_meta(&"free_asset", "dirt")
	props.add_child(mound)


## Kapı ışığı ve kesik biçimli kart (7a): şafağın soluk ışığı kapıdan girer; kart yalnız gölge verir.
func _build_door_light() -> void:
	var light := SpotLight3D.new()
	light.name = "DoorLight"
	light.light_color = Color(0.74, 0.78, 0.96)
	# Köz tabanı aydınlatırken gölge ancak ışık havuzu görünürse seçilir (3,2'de havuz da gölge de kayboluyordu; 2026-11-07). Yukarıdan
	# (K98) ışık kapıdan lentonun altından girer, bant dardır: 14'te tabanın koyu toprağında beyaz bir tahta gibi parlıyordu, 8'de içindeki
	# gölge sönüktü; 11'de bant soluk şafak ışığıdır, gölge keskin kenarlı (bulanıklık 0,6) ve içinde seçilir. İçerinin ılık dolgusu
	# (InteriorFill) gölgenin içini de aydınlatır: bant 13'le yine ondan ayrılır.
	light.light_energy = 13.0
	light.spot_range = 9.5
	light.spot_angle = 15.0
	light.spot_angle_attenuation = 1.4
	light.shadow_enabled = true
	light.shadow_blur = 0.6
	props.add_child(light)
	var outline: Array[PackedVector2Array] = [PrologueBirth.door_shadow_outline()]
	var card := MeshInstance3D.new()
	card.name = "ShadowCard"
	card.mesh = PrologueBirth.card_mesh(outline)
	card.material_override = Style.toon_double(Color(0.05, 0.04, 0.05))
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	props.add_child(card)
	# Dış kabuk 7a'da gizlidir: ışık kapıdan girsin diye astarın hemen dışında yalnız gölge veren halka (kapı aralığı açık).
	var mask := MeshInstance3D.new()
	mask.name = "DoorMask"
	mask.mesh = PrologueBirth.door_mask_mesh(PrologueBirth.lining_door())
	var mask_mat := StandardMaterial3D.new()
	mask_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mask.material_override = mask_mat
	mask.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	mask.visible = false
	props.add_child(mask)
	var crown := SpotLight3D.new()
	crown.name = "CrownLight"
	crown.light_color = Color(0.66, 0.72, 0.95)
	crown.light_energy = CROWN_LIGHT_ENERGY
	crown.spot_range = 6.0
	crown.spot_angle = 50.0
	crown.spot_angle_attenuation = 0.8
	crown.light_cull_mask = ACTOR_LIGHT_LAYER
	crown.visible = false
	props.add_child(crown)
	var fill := OmniLight3D.new()
	fill.name = "InteriorFill"
	fill.light_color = FILL_LIGHT_COLOR
	fill.light_energy = FILL_LIGHT_ENERGY
	fill.omni_range = FILL_LIGHT_RANGE
	fill.shadow_enabled = false
	fill.visible = false
	props.add_child(fill)


## Kapıdan giren gölgenin kartı (saf; m, taban y = 0, tepe CARD_HEIGHT): uzun saçlı, ince boyunlu, eteği yere değen kadın biçimi
## (Al Karısı; mit sinemasının 6. çekimindeki yüzsüz biçimin gölgesi). Baş boyundan, omuzlar başın iki katından geniştir; saçın
## uçları omuzların altında dişli bir kenar çizer: gölge tabanda ≈1,5 kat uzasa da biçim okunur. Gölge eşik taşında ≈1,7 kat genişler:
## etek kapının aralığının, omuzlar ışık bandının yarısını geçmez.
static func door_shadow_outline() -> PackedVector2Array:
	var right := [Vector2(0.12, 0.03), Vector2(0.26, 0.0), Vector2(0.22, 0.35), Vector2(0.17, 0.75), Vector2(0.15, 0.98),
		Vector2(0.21, 1.04), Vector2(0.17, 1.08), Vector2(0.22, 1.14), Vector2(0.18, 1.2), Vector2(0.2, 1.28), Vector2(0.15, 1.34),
		Vector2(0.06, 1.38), Vector2(0.055, 1.42)]
	var body := PackedVector2Array([Vector2(0.0, 0.0)])
	for p: Vector2 in right:
		body.append(p)
	for i in range(right.size() - 1, -1, -1):
		body.append(Vector2(-(right[i] as Vector2).x, (right[i] as Vector2).y))
	var head := FeltShapes.ellipse(Vector2(0.0, CARD_HEIGHT - 0.125), 0.105, 0.125, 20)
	return FeltShapes.union([body, head])


## Astarın kapı aralığı (saf; assets/structures/yurt/yurt_fit.json, OrdosWorld.BirthYurt._build_lining'in hesabı): yurdun yerel
## uzayında duvarın merkezi, yarıçapı (m), kapının açısı ve yarı açısı (radyan; yön (cos a, 0, sin a)).
static func lining_door(radius: float = 3.1) -> Dictionary:
	var fit: Dictionary = {}
	if FileAccess.file_exists(OrdosWorld.BirthYurt.FIT_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OrdosWorld.BirthYurt.FIT_PATH))
		if parsed is Dictionary:
			fit = parsed
	var circle: Dictionary = fit.get("circle", {})
	var door: Dictionary = fit.get("door", {})
	var ratio := OrdosWorld.BirthYurt.LINING_RATIO
	var half := asin(clampf(sin(deg_to_rad(float(door.get("half_width_deg", 7.6)))) * float(circle.get("r", 0.88)) / ratio, 0.0, 0.95)) \
			+ deg_to_rad(1.5)
	return {"center": Vector3(float(circle.get("x", 0.0)) * radius, 0.0, float(circle.get("z", 0.0)) * radius),
		"radius": radius * ratio, "angle": PI * 0.5 - deg_to_rad(float(door.get("center_deg", 0.0))), "half": half}


## Kapı maskesinin ağı (saf): astarın DOOR_MASK_GAP dışında, DOOR_MASK_HEIGHT boyunda halka; kapı aralığı astarınkiyle aynı genişlikte,
## DOOR_MASK_TOP'ın üstünde lento.
static func door_mask_mesh(door: Dictionary) -> ArrayMesh:
	var r := float(door["radius"]) + DOOR_MASK_GAP
	var half := asin(clampf(sin(float(door["half"])) * float(door["radius"]) / r, 0.0, 0.95))
	var a := float(door["angle"])
	var center: Vector3 = door["center"]
	var wall := OrdosWorld.BirthYurt.lining_wall(r, DOOR_MASK_HEIGHT, a + half, a - half + TAU, 48)
	var lintel := OrdosWorld.BirthYurt.lining_wall(r, DOOR_MASK_HEIGHT - DOOR_MASK_TOP, a - half, a + half, 4)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(wall, 0, Transform3D(Basis.IDENTITY, center))
	st.append_from(lintel, 0, Transform3D(Basis.IDENTITY, center + Vector3(0.0, DOOR_MASK_TOP, 0.0)))
	return st.commit()


## Sayıcının çentik çubuğu (rough_wood): elinde (RemoteTransform3D) tutulur.
func _build_tally() -> void:
	var stick := MeshInstance3D.new()
	stick.name = "TallyStick"
	stick.mesh = Procedural3D.box(Vector3(0.03, 0.32, 0.03))
	stick.material_override = PrologueBirth.textured(FREE_TEXTURES["rough_wood"], Color(0.95, 0.85, 0.7))
	stick.set_meta(&"free_asset", "rough_wood")
	props.add_child(stick)


# --- Çakışma ve geçişin videosu ------------------------------------------------------------------------

## 7a'nın ilk karesinde bakılan nokta: çakışmanın altında gerçek köz görünür. Mit videosu oynuyorsa köz videodakiyle aynı yere
## oturur (PrologueMyth.MYTH_EMBER_SCREEN, bantlar hesaba katılır); keçe yedeğinde ekranın ortasındadır.
func _opening_look(cam: Vector3, ember_at: Vector3, fov_deg: float) -> Vector3:
	if not CineVideo.usable(PrologueMyth.video_path):
		return ember_at
	var view := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(16.0, 9.0)
	return PrologueBirth.look_for_screen_y(cam, ember_at, fov_deg, CineVideo.screen_point(PrologueMyth.MYTH_EMBER_SCREEN, view).y)


## Kameranın bakacağı nokta (saf): target, dikey görüş açısı fov_deg olan kamerada ortada ve yukarıdan screen_y payında görünür.
static func look_for_screen_y(cam: Vector3, target: Vector3, fov_deg: float, screen_y: float) -> Vector3:
	var to := target - cam
	var flat := Vector2(to.x, to.z).length()
	if flat < 1e-6:
		return target
	var pitch := atan2(to.y, flat) - atan((1.0 - 2.0 * screen_y) * tan(deg_to_rad(fov_deg) * 0.5))
	return cam + (Vector3(to.x, 0.0, to.z) / flat * cos(pitch) + Vector3.UP * sin(pitch)) * to.length()


## Video kipinde geçişin katmanı: PanelLayer (katman 2) > View (CineVideo): canlandırma aynı «PanelLayer/View:modulate» izini
## sürer. Dosya açılamazsa false: keçe yedeği kurulur.
func _build_video_panel() -> bool:
	if not CineVideo.usable(video_path):
		return false
	var made := CineVideo.new()
	made.name = "View"
	if not made.open(video_path):
		made.free()
		return false
	made.modulate = Color(1, 1, 1, 0)
	video = made
	panel_layer = CanvasLayer.new()
	panel_layer.name = "PanelLayer"
	panel_layer.layer = CineVideo.LAYER
	panel_layer.visible = false
	panel_layer.add_child(video)
	add_child(panel_layer)
	return true


## panel_8'in başı: video sinema saatine bağlanır, altyazı koyu banda iner.
func _start_video(ev: Dictionary) -> void:
	if video == null:
		return
	_video_t0 = float(ev.get("t", 0.0))
	_set_subtitle_band(true)


func _follow_video() -> void:
	var h := host()
	if video == null or is_nan(_video_t0) or h == null or h.is_skipping():
		return
	video.speed = h.speed
	video.follow(h.time() - _video_t0)
	if not _video_covers and h.time() - _video_t0 >= PANEL_OPAQUE_AT:
		_video_covers = true
		h.cover_main_3d(true)


func _stop_video() -> void:
	if video == null or not is_instance_valid(video):
		return
	video.stop()
	_video_t0 = NAN
	_set_subtitle_band(false)
	if _video_covers:
		_video_covers = false
		var h := host()
		if h:
			h.cover_main_3d(false)


func _set_subtitle_band(on: bool) -> void:
	var h := host()
	if h and h.subtitles:
		h.subtitles.video_band = on


# --- Pano 8 -----------------------------------------------------------------------------------------

## Geçişin katmanı: video kipi (_build_video_panel) ya da keçe yedeği pano 8: kendi dünyası olan SubViewport (katman 0, boyalı
## süzgecin altında), keçe ortamı ve iki ışık; FeltPanel birth_panel.json'un panel sözlüğünden kurulur. Gizli kurulur, panel_8'de
## görünür.
func _build_panel() -> void:
	if panel_layer or _build_video_panel():
		return
	panel_layer = CanvasLayer.new()
	panel_layer.name = "PanelLayer"
	panel_layer.layer = CineHost.VIEW_LAYER
	panel_layer.visible = false
	var view := SubViewportContainer.new()
	view.name = "View"
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(view)
	view.modulate = Color(1, 1, 1, 0)
	panel_layer.add_child(view)
	var vp := SubViewport.new()
	vp.name = "Viewport"
	vp.own_world_3d = true
	vp.handle_input_locally = false
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	view.add_child(vp)
	var stage := Node3D.new()
	stage.name = "Stage"
	vp.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.05, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.66, 0.56, 0.46)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	stage.add_child(we)
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_color = Color(1.0, 0.88, 0.7)
	key.light_energy = 1.15
	key.shadow_enabled = true
	key.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-38.0), deg_to_rad(-30.0), 0.0)), Vector3.ZERO)
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.62, 0.7, 0.92)
	fill.light_energy = 0.3
	fill.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-18.0), deg_to_rad(40.0), 0.0)), Vector3.ZERO)
	stage.add_child(fill)
	panel_camera = Camera3D.new()
	panel_camera.name = "PanelCamera"
	panel_camera.current = true
	panel_camera.near = 0.05
	panel_camera.far = 40.0
	stage.add_child(panel_camera)
	# Pano boş kurulur (panel_index 0: veriden pano okunmaz); katmanları _fill_panel kendi karesinde kurar.
	panel = FeltPanel.new()
	panel.name = "Panel8"
	panel.panel_index = 0
	stage.add_child(panel)
	var cam: Dictionary = PrologueBirth.panel_def().get("camera", {})
	panel_camera.fov = float(cam.get("fov", 30.0))
	var keys: Array = cam.get("keys", [])
	if not keys.is_empty():
		var k0: Array = keys[0]
		panel_camera.position = Vector3(float(k0[1]), float(k0[2]), float(k0[3]))
	add_child(panel_layer)


## Pano 8'in keçe parçaları (birth_panel.json; FeltPanel üçgenler, dikiş şeridini kurar).
func _fill_panel() -> void:
	if panel == null or not panel.panel.is_empty():
		return
	panel.panel = PrologueBirth.panel_def()
	panel.rebuild()
	if FeltPanel.uses_free_texture():
		panel.set_meta(&"free_asset", FeltPanel.FREE_ASSET)


## Pano 8'in tanımı (data/cine/birth_panel.json'un panel'i; okunamazsa boş).
static func panel_def() -> Dictionary:
	if not FileAccess.file_exists(PANEL_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PANEL_PATH))
	if parsed is Dictionary and (parsed as Dictionary).get("panel") is Dictionary:
		return parsed["panel"]
	return {}


# --- Ağ ve malzeme yardımcıları --------------------------------------------------------------------

## Ücretsiz dokuyla boyalı malzeme (atw_textured; MeshyProp'un gölgelendiricisi).
static func textured(path: String, tint: Color = Color.WHITE) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = MeshyProp.SHADER
	mat.set_shader_parameter("albedo_texture", load(path) if ResourceLoader.exists(path) else null)
	mat.set_shader_parameter("albedo_tint", tint)
	mat.set_shader_parameter("ink_strength", 0.2)
	mat.set_shader_parameter("brush_strength", 0.05)
	return mat


## Yüzeyleri malzemelerine göre birleştirir (saf; OBJ'nin tekrar eden usemtl blokları tek çizime iner). Yüzey adı
## malzemenin adıdır.
static func merge_by_material(src: Mesh) -> ArrayMesh:
	var groups := {}
	var order: Array[String] = []
	for i in src.get_surface_count():
		var mat := src.surface_get_material(i)
		var key := mat.resource_name if mat and not mat.resource_name.is_empty() else "surface_%d" % i
		if not groups.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = st
			order.append(key)
		(groups[key] as SurfaceTool).append_from(src, i, Transform3D.IDENTITY)
	var out := ArrayMesh.new()
	for key in order:
		var st: SurfaceTool = groups[key]
		out = st.commit(out)
		out.surface_set_name(out.get_surface_count() - 1, key)
	return out


## Kemer ya da salıncak ayağı (saf): yarım genişliği half, yüksekliği rise olan yay (dışbükey yukarı; rocker ise aşağı
## sarkan), kare kesitli kalın şerit (t × d), x ekseni boyunca. UV x yay boyunca.
static func arc_bar(half: float, rise: float, t: float, d: float, segments: int, rocker: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := PackedVector3Array()
	for i in segments + 1:
		var u := float(i) / float(segments) * 2.0 - 1.0
		var x := u * half
		var y := rise * (1.0 - u * u) if not rocker else rise * u * u
		pts.append(Vector3(x, y, 0.0))
	var length := 0.0
	for i in segments:
		var a := pts[i]
		var b := pts[i + 1]
		var dir := (b - a).normalized()
		var nrm := Vector3(-dir.y, dir.x, 0.0)
		var corners := [nrm * t * 0.5 + Vector3(0, 0, d * 0.5), nrm * t * 0.5 - Vector3(0, 0, d * 0.5),
			-nrm * t * 0.5 - Vector3(0, 0, d * 0.5), -nrm * t * 0.5 + Vector3(0, 0, d * 0.5)]
		var seg_len := a.distance_to(b)
		for c in 4:
			var c0: Vector3 = corners[c]
			var c1: Vector3 = corners[(c + 1) % 4]
			var n := (c0 + c1).normalized()
			var quad := [[a + c0, Vector2(length, 0.0)], [b + c0, Vector2(length + seg_len, 0.0)],
				[a + c1, Vector2(length, 1.0)], [b + c1, Vector2(length + seg_len, 1.0)]]
			for idx in [0, 1, 2, 2, 1, 3]:
				st.set_normal(n)
				st.set_uv(quad[idx][1])
				st.add_vertex(quad[idx][0])
		length += seg_len
	return st.commit()


## Kesik biçimli kart (saf): FeltShapes dış hatları dikey bir düzlemde (x, y), iki yüzlü üçgenlenmiş.
static func card_mesh(outlines: Array[PackedVector2Array]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for outline in outlines:
		var tris := Geometry2D.triangulate_polygon(outline)
		for k in range(0, tris.size(), 3):
			for idx in [tris[k], tris[k + 2], tris[k + 1]]:
				st.set_normal(Vector3.BACK)
				st.add_vertex(Vector3(outline[idx].x, outline[idx].y, 0.0))
	return st.commit()


func _box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = Procedural3D.box(size)
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Ücretsiz modelin örneği: glTF sahnesi (ya da OBJ ağı) boyalı malzemeyle (atw_textured; dokusu korunur). Düğüm
## free_asset meta verisini taşır.
func _model_instance(asset_id: String, node_name: String, parent: Node, tint: Color = Color.WHITE) -> Node3D:
	var res := _resource(FREE_MODELS.get(asset_id, ""))
	var node: Node3D = null
	if res is PackedScene:
		node = (res as PackedScene).instantiate() as Node3D
	if node == null:
		return null
	node.name = node_name
	node.set_meta(&"free_asset", asset_id)
	parent.add_child(node)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var tex: Texture2D = (src as BaseMaterial3D).albedo_texture if src is BaseMaterial3D else null
			var mat := ShaderMaterial.new()
			mat.shader = MeshyProp.SHADER
			mat.set_shader_parameter("albedo_texture", tex)
			mat.set_shader_parameter("albedo_tint", tint)
			mat.set_shader_parameter("ink_strength", 0.2)
			mat.set_shader_parameter("brush_strength", 0.05)
			mi.set_surface_override_material(i, mat)
	return node


## Önceden yüklenen kaynak (sahneyle birlikte arka planda gelir), yoksa ResourceLoader.
func _resource(path: String) -> Resource:
	for res in preloaded:
		if res and res.resource_path == path:
			return res
	return load(path) if not path.is_empty() and ResourceLoader.exists(path) else null


# --- Bağlam ------------------------------------------------------------------------------------------

## Konağın çizelgesi (yoksa segment dosyası gerçek sürelerle).
func _real_timeline() -> CineTimeline:
	var h := host()
	if h and h.timeline():
		return h.timeline()
	return CineTimeline.from_path(_segment_file())


func _segment_id() -> String:
	var seg: Variant = ctx.get("segment")
	return str((seg as Dictionary).get("id", SEGMENT_ID)) if seg is Dictionary else SEGMENT_ID


func _segment_file() -> String:
	var seg: Variant = ctx.get("segment")
	var file := str((seg as Dictionary).get("file", "")) if seg is Dictionary else ""
	return file if not file.is_empty() else SEGMENT_PATH


func _audio(method: StringName, args: Array) -> void:
	var audio: Variant = ctx.get("audio")
	if audio is CineAudio:
		(audio as CineAudio).call_target(method, args)


## Dizi bu segmentle bitiyor mu (atlama, durdurma ya da son segment)?
func _sequence_ends() -> bool:
	var h := host()
	if h == null or h.is_skipping() or not h.is_playing() or h.runner == null or h.runner.done:
		return true
	var timeline := h.timeline()
	var seg: Dictionary = ctx.get("segment", {})
	if timeline == null or seg.is_empty():
		return true
	return int(seg.get("index", 0)) >= timeline.segments.size() - 1
