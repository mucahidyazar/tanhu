extends Node3D
## Oyunun giriş noktası: ekranlar arasındaki akışı yönetir.
##
##   SÖZ (Mete'nin sözü, Tanhu 1'deki gibi; bir tuşla kısalır) ──▶ AÇILIŞ
##   AÇILIŞ ──"Yeni Oyun"──▶ YENİ OYUN AKIŞI (K99; data/story/new_game.json, NewGameFlow) ──▶ AÇILIŞ
##     │   Sıra: ÖNSÖZ (sinema; basılı Esc atlar) → ÇOCUKLUK «Koyun Sırtında» (oynanır; ChildhoodScene) → KÖPRÜ 1 (sinema)
##     │   → KARAKTER OLUŞTUR «Yola Hazırlan» → YOLA ÇIKIŞ (oynanır; DepartScene, depart_yurt) → KÖPRÜ 2 (sinema) → [I. PERDE]
##     │   → SON KART («I. Perde: Çan», «Yapım aşamasında.») → AÇILIŞ. Köşeli parantezdeki aşama henüz yoktur: dosyası ve oynatıcısı
##     │   gelince sıraya kendiliğinden girer (NewGameFlow.PLAYABLE, _play_stage), son kart düşer. Oluşturulan Mete ana kampa inmez
##     │   (K37): Yola Çıkış'ta kendi küçük dünyasında oynar. Akış hiçbir kayıt yazmaz: oyuncunun oto kaydı ve «Devam Et»in kaydı bozulmaz.
##     │   Önsöz: prologue_path'teki dizi (CineHost; godot.md §3.6, K68). Dosya yoksa ya da boşsa, ya da oyuncu onu gördüyse
##     │   (GameSettings.prologue_seen) ve "her yeni oyunda" seçili değilse (prologue_always) atlanır. Sinemada yolculuğun süresi
##     │   işlemez (saat durur). Önsöz'den sonraki ilk aşamada yeni yolculuk başlar (journey.reset); Önsöz bu Yeni Oyun'da oynadı
##     │   ya da atlandıysa yolculuğa CineHost.PROLOGUE_FLAG ("onsoz") yazılır. Çocukluk bitince «mq0_sheep», fareyi vurmayanda
##     │   «child_spared» yazılır; «Beni gördü.»yle donan son kare Köprü 1'in parşömenine çapraz geçer (Köprü 1'in baş perdesi o karenin
##     │   görüntüsüdür: _StillCurtain). Çocukluk'u bir kez bitiren oyuncuya (GameSettings.childhood_done) başında «Çocukluğu geç: Esc basılı
##     │   tut» sunulur: basılı Esc Köprü 1'e atlar (kısa basış duraklatmadır), «mq0_sheep» ve «child_skipped» yazılır. Yola Çıkış bitince
##     │   «mq0_depart». Takvim (K67) NewGameFlow.DAY_FLAG'dir ve yalnız ileri gider (NewGameFlow.advance): Çocukluk −5.600, Köprü 1'den sonra
##     │   −41, Köprü 2'nin çan çekiminde 1, sonunda 1.041 (day_history). Köprü 2 sürerken I. Perde'nin dünyası (Kışlak, scenes/maps/kislak.tscn)
##     │   arka planda yüklenir: dosya yoksa sessizce geçilir (preloaded_worlds). Çocukluk'ta ve Yola Çıkış'ta duraklatma kitabının KAYDET'i
##     │   kapalıdır; "Ana Menü" kayıt yazmadan açılış ekranına döner. Oluşturucuda "Geri Al" akışı bırakır, açılış ekranı gelir.
##     ├──"Devam Et" (son kayıt) / "Yükle" (seçilen yuva)───────▶ OYUN (kaydedildiği yerde)
##     ├──"Serbest Gez"──────────────────────────────────────────▶ OYUN (süren yolculuk; Çocuk ateş başındaki yerinde oturur, ilk harekette kalkar: K37)
##     ├──"Destan Kitabı", "Ayarlar": açılış ekranının kendi sayfaları
##     └──"Çıkış": sesler kısılır, ekran kararır, oyun kapanır
##   OYUN: oyun içi HUD (GameplayHud; scripts/ui/hud/): portre, can ve takat, mini harita, görev kartı ve yönü, yuva şeridi; I Envanter'i
##     açar (oyun durur), M ve J duraklatma kitabını HARİTA ve GÖREVLER sayfasında açar. Yalnız State.PLAYING'de görünür. Oturumla: T Bekle
##     tekeri (WaitWheel; döşekte Uyu, ateş başında Dinlen), E döşekte «Uyu», ateş başında basılı «Dinlen», kapta ve yer yığınında «Aç»;
##     G basılı «Yükü Bırak»; heybe, seviye ve XP oturumun envanteri ve ilerlemesidir, Yük yürüyüşü yavaşlatır. Görev kaynağı Çocukluk'ta ChildhoodScene,
##     Yola Çıkış'ta DepartScene (aynı yüz: hud_quest, hud_target; Görevler'de biten «Koyun Sırtında» da), Serbest Gez'de CampTour («Kampı Dolaş»). Dünyanın
##     haritası bir kez pişer (WorldMap): kampınki menüde, Ordos'unki ve depart_yurt'unki dünya kurulurken (perde kara).
##   OYUN ──Esc──▶ DURAKLATMA (kitap: Devam Et, Kaydet, Yükle, Ayarlar, Ana Menü, Masaüstüne Dön)
##     "Ana Menü": otomatik kayıt (Çocukluk'ta yok), kamera yumuşakça menü kadrajına geri uçar
##     "Masaüstüne Dön": otomatik kayıt (Çocukluk'ta yok), sesler kısılır, oyun kapanır
##     "Yükle": ekran kararır, karakter ve yer kayıttan gelir
##
## Kayıtlar user:// altındadır (SaveSystem); geliştirme ve test çalıştırmaları (komut satırında "--"
## sonrası argüman varsa ya da başsızsa) oyuncunun kayıtlarına ve karakterine yazmaz, açılış sözünü de göstermez.
## Geliştirme için komut satırı (Godot ... -- <argüman>), bkz. _apply_dev_arguments:
##   --state=newgame                      Yeni Oyun'un akışı Önsöz'süz (Çocukluk'tan); --stage=<aşama> o aşamadan (childhood, bridge_1,
##                                        creator, depart, bridge_2, end_card), --step=<adım> Çocukluk ya da Yola Çıkış o adımdan (wake, ride,
##                                        hunt, count; yurt, yard, horse)
##   --autoplay[=mouse]                   (newgame) Çocukluk'u ve Yola Çıkış'ı tuşsuz baştan sona oynar (scripts/dev/childhood_autoplay.gd,
##                                        depart_autoplay.gd; mouse: fareyi de vurur)
##   --skip-offer                         (newgame) «Çocukluğu geç» sunulur (oyuncunun ayarı Çocukluk'u bitirmiş sayılır; dosyaya yazılmaz)
##   --skip-prologue[=SN]                 (prologue) Önsöz SN (4) saniye sonra basılı Esc'le atlanır (bütün akışın pencerede kaydı)
##   --accept-creator[=SN]                (newgame) oluşturucuyu SN (2,5) saniye sonra onaylar: akışın tamamı tuşsuz akar
##   --state=creator | --state=play       oluşturucu (akışın oluşturucu aşamasından); play Serbest Gez'dir (Çocuk), --adult ile oluşturulan yetişkin
##   --state=childhood                    Ordos dünyasında (childhood_ordos) küçük Mete, sahnesiz kum havuzu: yürür, koşar, koyuna biner, yay atar; --at ve --drive ile
##   --state=prologue                     Yeni Oyun'un Önsöz'ü (görülmüş olsa da oynar), sonra akışın kalanı
##   --cine=res://data/cine/<dosya>.json  Önsöz yerine bu diziyi ya da segmenti oynatır (--state=prologue gibi)
##   --cine-at=SN                         sinemayı bu saniyeye sessizce ileri sarar (ekran görüntüsü)
##   --cine-speed=K                       sinema K kat hızlı akar
##   --cine-log                           sinemanın saatini, tutulup tutulmadığını ve süren sahnenin canlandırmasını saniyede bir yazar
##   --open=ayarlar|tuslar|yukle|destan|kisiler|taslar|onay|kart   açılış ekranında bir sayfa
##   --pause[=genel|destan|kisiler|taslar|tuslar|ayarlar|kaydet|yukle]   (--state=play ile) duraklatma kitabı
##   --save-dir=/mutlak/klasör            kayıtlar bu klasörde okunur / yazılır
##   --dev-save=N                         (--state=play ile) oyuncu kampa inince N. yuvaya kaydeder
##   --flags=a,b                          yolculuğa işaret koyar; --at=x,z[,yön_derece] belirme yeri
##   --light=<durak> | --clock=HH:MM [--day=N] [--no-fade]   (--state=play) Serbest Gez'in saati: ışık durağının ölçüm dakikası
##                                        (data/time/light_stops.json probe) ya da verilen saat (RoamTime); --cam-distance=M takip kamerası
##   --drive=yol                          (--state=play, childhood, newgame) çocuğu tuşsuz sürer: bkz. scripts/player/child_drive.gd
##   --hud-screen=bag|map|journal         HUD göründükten --hud-at=SN (2) saniye sonra Envanter'i ya da kitabın HARİTA / GÖREVLER sayfasını açar
##   --state=testmap                      deneme iç haritası (world-swap, mete-playable; data/maps/testmap/map.json): kamp bırakılır (WorldHost), oluşturulan
##                                        Mete profilin görünüşü, Kışlak Kaftanı ve Kışlak Pelerini'yle (boya profilden; --dye=N listenin N. boyası, yazılmaz)
##                                        oynar: yürür, koşar, zıplar, ata biner (Doru, Akbulut). --spawn=start|east_gate|west_gate, --at ve --drive (ChildDrive
##                                        yetişkini de sürer). Kapılar ve duraklatma kitabının «Ana Menü»sü kampa döner (kamp karartma altında yeniden kurulur);
##                                        haritada kayıt yazılır (kayıt v2'nin map bloğu: Devam Et ve Yükle haritaya, kaydedilen yere indirir).
##                                        --swap-probe[=N]: kamp → harita → kamp N kez (2), süreler ve bellek [world_host] satırlarına
##                                        (pencerede; --no-hud-map HUD haritasını pişirmez)
##   --state=kislak                       I. Perde'nin Kışlak'ı (act-1-p2; data/maps/kislak/map.json): --state=testmap'in yolu, oluşturulan Mete Rehine
##                                        Yurdu'nun kapısında (−43, 53); --spawn=start|arrival|great_hearth|lookout_bluff|dev_<bölge>, --at, --drive;
##                                        saat oturumun hikâye saatidir (Gün I, 10:00; --clock=HH:MM ile o dakika), ışık saatle akar (MapSky)
##   --wait-screen=wait|sleep|rest|work   HUD göründükten --wait-at=SN (2) saniye sonra Bekle tekerini o kipte açar; --wait-pick=N (1–6) N.
##                                        satırı seçer; --wait-shot=open|lapse|turn|wake görüntüyü o ana dek bekletir (tekerin kareleri)
## Dünyalar (godot.md §4.1–§4.3): WorldHost (scripts/maps/world_host.gd) bellekte tek dünya tutar; kamp Main/World'dür, iç haritaya girerken bırakılır,
## dönüşte pişmiş parçalarıyla yeniden kurulur (world, player.world ve cine.world o an bağlanır). Hikâyenin küçük dünyaları (Ordos, Yola Çıkış) bugün
## buradaki kendi yollarıyla kurulur, kamp gizlenir (CineHost.release_camp); Köprü 2'nin önyüklediği Kışlak take_preloaded ile WorldHost.enter_map'e verilir.

const CaptureTool := preload("res://scripts/dev/capture.gd")
const ChildhoodAutoplay := preload("res://scripts/dev/childhood_autoplay.gd")
const DepartAutoplay := preload("res://scripts/dev/depart_autoplay.gd")
## Ayarlar autoload'unun betiği: geliştirme koşusu ölçütü (is_dev_run) burada da aynı olsun diye.
const SettingsScript := preload("res://scripts/settings/game_settings.gd")

enum State { MENU, CREATOR, PLAYING, PAUSED, BUSY, CINE }

## Bir aşama bitti (ok) ya da bırakıldı (false); Yeni Oyun'un akışı bunu bekler (her zaman ertelenmiş yayılır).
signal _stage_done(ok: bool)

## Yeni Oyun'un Önsöz dizisi (CineHost; godot.md §3.6).
const PROLOGUE_PATH := "res://data/cine/prologue.json"

## Çocukluk'un dünyası (geliştirici girişi --state=childhood; Yeni Oyun'un Çocukluk aşaması) ve binilen koyunun sahnesi.
const CHILDHOOD_WORLD := "res://scenes/maps/childhood_ordos.tscn"
const RIDEABLE_SHEEP := "res://scenes/fauna/rideable_sheep.tscn"
## Küçük Mete'nin baktığı yön (doğu; belirdiği yer dünyanın child_start işareti) ve binilen koyunların işaretleri.
const CHILDHOOD_YAW := PI * 0.5
const CHILDHOOD_SHEEP: Array[String] = ["old_sheep", "fast_sheep"]
## Çocukluk'un tarih kartı (CineHost.card) ve perde kalkmadan önce en az ne kadar okunur (sn).
const CHILDHOOD_CARD_SECONDS := 4.6
const CHILDHOOD_CARD_MIN := 2.4
## Çocukluk'ta duraklatma kitabının satırları (K99: Çocukluk'ta kayıt yok).
const CHILDHOOD_SAVE_NOTE := "Çocukluk'ta kayıt yok. Ana Menü'ye dönersen sahne bir dahaki Yeni Oyun'da baştan oynar; kayıtların yerinde kalır."
const CHILDHOOD_PLACE := "Ordos · Koyun Sırtında"
## «Çocukluğu geç»: atlanan Çocukluk'un işareti, teklifin ekranda kaldığı süre (sn) ve yazısı (K100'ün dili: basılı Esc).
const CHILDHOOD_SKIPPED_FLAG := "child_skipped"
const SKIP_OFFER_SECONDS := 9.0
const SKIP_OFFER_TEXT := {"tr": "Çocukluğu geç: Esc basılı tut", "en": "Skip the childhood: hold Esc"}
## Yola Çıkış'ın dünyası, tarih kartı (sn; perde kalkmadan en az ne kadar okunur) ve duraklatma kitabının satırı.
const DEPART_WORLD := "res://scenes/maps/depart_yurt.tscn"
const DEPART_CARD_SECONDS := 4.4
const DEPART_CARD_MIN := 2.4
const DEPART_SAVE_NOTE := "Yeni Oyun'un akışında kayıt yok. Ana Menü'ye dönersen Yola Çıkış bir dahaki Yeni Oyun'da baştan oynar; kayıtların yerinde kalır."
## Kapıdan dönüşün bildirimi.
const GATE_TOAST := "%s: kampa dönülüyor"
## Yolculuk Çocuk'la mı (Serbest Gez)? Kayıtta işaret olarak durur: yüklenince aynı beden gelir.
const ROAM_CHILD_FLAG := "cocuk_gezinti"
## Oyuncu ateş başındaki yerinden bu kadar uzaklaşınca yer işaretleri sayılır (m): oturduğu yer «ateşin başına varmak» sayılmaz.
const SEAT_LEAVE := 1.1

## Oyuncunun kamp ateşine göre belirdiği nokta (ateşin sağ önündeki patikanın üstü) ve bakış yönü (π = kampa doğru).
const SPAWN_OFFSET := Vector3(2.6, 0.0, 3.2)
const SPAWN_YAW := PI
## Yer işaretlerinin (ateş başı, ahır, yamaç...) denetlenme aralığı (saniye).
const FLAG_CHECK_INTERVAL := 0.25
## "Yer yok" anlamında (spawn noktası kullanılır).
const NO_POSITION := Vector3.INF

## Açılışta Mete'nin sözü gösterilsin mi (geliştirme ve test çalıştırmalarında hiç gösterilmez)?
@export var show_epigraph := true
## Yeni Oyun'un Önsöz dizisi; boşsa ya da dosya yoksa Önsöz atlanır (testler "" ya da deneme çizelgesi verir).
@export var prologue_path := PROLOGUE_PATH
## Sinemanın hızı (--cine-speed; testler hızlandırır).
var cine_speed := 1.0
## Önsöz ilk oynatmada GameSettings.prologue_seen'e yazılsın mı? Geliştirme ve test çalıştırmalarında yazılmaz
## (_setup_persistence); sınama sahte bir ayar nesnesiyle açabilir.
var remember_prologue := false
## Yeni Oyun'un başlayacağı aşama ("" baştan; --stage, sınama) ve yalnız oynatılacak aşamalar (boş: hepsi; sınama).
var new_game_from := ""
var new_game_only := PackedStringArray()
## Çocukluk'un ve Yola Çıkış'ın başlayacağı adım ("" baştan; --step, sınama).
var childhood_step := ""
## E21: Çocukluk hangi günden açılsın (--day; boşsa ilk gün ya da childhood_step'i içeren gün) ve günlerin sırası.
var childhood_day := ""
## Çocukluk'un günlerinin sırası: "stage" aşamanın days'i (new_game.json), boş: yalnız sayım günü (eski sınamalar), ya da bir yol.
var childhood_days_path := "stage"
var _childhood_days: ChildhoodDays
var _childhood_day_saves := false
var depart_step := ""
## Son kartın bekleme süresi (eksi: new_game.json'daki; sınama kısaltır).
var flow_card_hold := -1.0
## Yeni Oyun'un sırası (boşsa data/story/new_game.json; sınama kendi sırasını verir).
var new_game_data: Dictionary = {}
## Çocukluk ilk bitişte GameSettings.childhood_done'a yazılsın mı? Geliştirme ve test çalıştırmalarında yazılmaz (_setup_persistence).
var remember_childhood := false
## Takvimin bu Yeni Oyun'daki günleri, yazıldıkları sırayla (K67; sınama ileri gittiğini okur).
var day_history: Array[int] = []
## Yola Çıkış'ın kişilerini taşıyan sınama klasörü (boşsa StandIn.ROOT; yer tutucunun sınaması).
var depart_actor_root := ""

@onready var world: World = $World
@onready var menu_camera: MenuCamera = $MenuCamera
@onready var follow_camera: FollowCamera = $FollowCamera
@onready var player: PlayerController = $Player
@onready var overlay: PainterlyOverlay = $PainterlyOverlay
@onready var menu: MainMenu = $UI/MainMenu
@onready var creator: CharacterCreator = $UI/CharacterCreator
@onready var hud: GameHud = $UI/GameHud
@onready var fade: ColorRect = $UI/Fade
@onready var cine: CineHost = $CineHost

var state: State = State.MENU
var profile: CharacterProfile
## Süren yolculuk (karakter, yer, süre, işaretler) ve kayıtlar.
var journey: Journey
## Kayıt klasörü; sahneye eklenmeden önce verilirse (testler) o kullanılır.
var saves: SaveSystem
## Ayarlar (GameSettings autoload'u ya da testlerin verdiği bir örnek).
var settings: Node
## Serbest gezintideki Esc kitabı.
var pause_menu: PauseMenu
## Çıkışta çağrılır; testlerde gerçek çıkış yerine sahte bir işlev verilebilir.
var quit_handler: Callable

var _persist_profile := true
## Bu Yeni Oyun'da Önsöz oynadı, atlandı ya da (görüldüğü için) varsayılanla geçildi mi?
var _prologue_done := false
var _flag_timer := 0.0
## Destan Kitabı'nda açık kayıtların kimlikleri: yeni açılan olunca küçük bir bildirim çıkar.
var _unlocked: Dictionary = {}
var _toast: MenuToast
## O an yapılabileceklerin ipucu (çocuk denetleyicisi).
var _prompt: PlayerPrompt
## Oyun içi HUD (portre, can ve takat, mini harita, görev kartı ve yönü, yuva şeridi, I / J / M; GameplayHud). Yalnız oynanırken
## (State.PLAYING: Çocukluk ve Serbest Gez) görünür; sinemada, menüde, oluşturucuda, duraklatmada ve köprülerde gizlidir.
var gameplay_hud: GameplayHud
## Serbest Gez'in görevi («Kampı Dolaş»; HUD'un görev kartı ve yönü).
var _camp_tour: CampTour
## Serbest Gez'in kamp sözleri (E20/7; CampVoice): ateş başındakiler Çocuğa seslenir.
var _camp_voice: CampVoice
## Oyuncu ateş başındaki yerinden henüz ayrılmadı: yer işaretleri sayılmaz. Değer oturduğu yer.
var _seat_hold := false
var _seat_at := Vector3.ZERO
## Çocukluk'un dünyası ve binilen koyun (--state=childhood, Yeni Oyun'un Çocukluk'u).
var _childhood_world: Node3D
var _childhood_sheep: Array[Node3D] = []
## Yeni Oyun'un akışı (null: akış yok), sayacı (bırakılan akışın geç kalan işleri tanınsın) ve yeni yolculuğun başlayıp başlamadığı.
var _flow: NewGameFlow
var _flow_serial := 0
var _flow_committed := false
## Çocukluk'un sahnesi ve akışın son kartı (süren aşamada).
var _childhood_scene: ChildhoodScene
var _flow_card: FlowCard
## Çocukluk'un kararma perdesi yerine verilen görünmez perde (sahne «Beni gördü.»de görüntüyü dondurur; kararmayı değil çapraz geçişi
## main yapar) ve Köprü 1'in baş perdesi olan donmuş kare (_StillCurtain; açılış bitince bırakılır).
var _childhood_curtain: ColorRect
var _still_curtain: _StillCurtain
var _still_until := 0.0
## «Çocukluğu geç»: teklif (sağ alt), basılı Esc'in sayılıp sayılmadığı ve süresi.
var _skip_offer: _SkipOffer
var _skip_tracking := false
var _skip_hold := 0.0
## Yola Çıkış'ın dünyası, sahnesi ve kişilerinin önceden yüklenen modelleri (yol → kaynak; sahne bitince bırakılır).
var _depart_world: DepartWorld
var _depart_scene: DepartScene
var _depart_models: Dictionary = {}
## Süren sinemanın zamanlı takvim atlamaları ([sn, dayN], sırayla; yazılan çıkar) ve arka planda yüklenen sonraki dünyalar (yol → true).
var _timed_jumps: Array = []
var _preloads: Dictionary = {}
## Geliştirme: Önsöz görülmüş olsa da oynar (--state=prologue), Önsöz yerine bu dizi (--cine) ve oraya ileri sarma (--cine-at).
var _force_prologue := false
var _prologue_override := ""
var _prologue_at := 0.0
## Önsöz'ün oynanan günleri (E21, K110; PrologueDays, scripts/story/prologue_days.gd): sürerken koşucu; geliştirmenin günü (1..3; 0 baştan),
## görevi (sahne kimliği: milk, storm, lambs, feast, hearth) ve adımı (--day, --quest, --step).
var _prologue_days: PrologueDays
## Günlerin sırası ("" günler oynamaz, Önsöz yalnız sinemadır: sinemayı sınayan testler).
var prologue_days_path := PrologueDays.ORDER_PATH
var prologue_day := 0
var prologue_quest := ""
var prologue_step := ""
var _prologue_days_played := false
var _prologue_dev_at := Vector3.INF
var _prologue_dev_yaw := NAN
## Yeni Oyun'un kayıt noktasından açılışı (Devam Et, Yükle; E21): aşama → günün kimliği (flow_resume_day okur).
var _flow_resume: Dictionary = {}
var _flow_resuming := false
## Kayıt noktasının işaretleri (E21): aşamanın kimliği ve günün kimliği (flow_save_point yazar).
const FLOW_STAGE_FLAG := "yeni_oyun_asama"
const FLOW_DAY_FLAG := "yeni_oyun_gun"
## Kayıt noktasının heybesi (E21): oturumsuz hikâye sahnelerinin heybesi (gameplay_hud.bag.inventory; Inventory.to_dict) bu blokta yazılır.
## Oturumun «inventory» bloğu değildir: oturum açılınca (Serbest Gez, I. Perde) çocuğun heybesi yetişkinin başlangıç donanımının yerine geçmesin.
const FLOW_BAG_BLOCK := "flow_bag"
## Kayıttan açılışta geri konacak heybe (_resume_flow okur; ilk kayıt noktası, günün başı, aşamanın begin_body'sinden sonra geri koyar).
var _flow_bag: Dictionary = {}
const PROLOGUE_SKIP_TEXT := {"tr": "Önsözü geç: Esc basılı tut", "en": "Skip the prologue: hold Esc"}
const PROLOGUE_SAVE_NOTE := "Önsöz'de kayıt her günün başında kendiliğinden yazılır; Devam Et o günün başından açar."
## Geliştirme argümanları (Çocukluk aşaması --drive ve --autoplay'i okur; --cine-log sinemanın saatini saniyede bir yazar).
var _dev_args: Dictionary = {}
var _cine_log_left := 0.0
## Tek dünyanın konağı (kamp ya da iç harita; _setup_world_host) ve açık iç harita (yoksa null). Kapı, oyuncu kapının alanından bir kez
## çıktıktan sonra işler (belirme yeri kapıdaysa hemen geri dönülmesin).
var world_host: WorldHost
var _map_world: MapWorld
var _gate_armed := false
## Serbest Gez'in saati ve ışığı (RoamTime; K20, K67, K76): kampta gece menüsünden 2,4 sn süzülmeyle açılış, Tan kartı, menüye dönüşte kimlik.
var _roam_time: RoamTime
## Serbest Gez kampının havası (CampWeather; K22, K67): oyunun saatiyle akar; menüye dönüşte görünüm kimliğe döner.
var _camp_weather: CampWeather
## Serbest Gez'in kamp günü (CampLife; Yol Haritası roam-camp-life): camp3'ün şantiyesi ve ustaları, ocak halkının saat programı.
var _camp_life: CampLife
## Oturum (Session; godot.md §3.1): Serbest Gez'de, deneme haritasında ve kayıttan yüklemede kurulur, menüye dönüşte silinir (yoksa null);
## saati RoamTime da okur, envanteri ve ilerlemesi HUD'dadır.
var session: Session
## Bekle, Uyu, Dinlen ve Çalış tekeri (WaitWheel; time.md §7): T, döşekte E, ateş başında basılı E.
var wait_wheel: WaitWheel


func _ready() -> void:
	InputSetup.ensure_actions()
	MenuStyle.ensure_pad_actions()
	if not quit_handler.is_valid():
		quit_handler = _quit_game
	_setup_persistence()
	profile = CharacterProfile.load_or_default()
	journey = Journey.new(saves, profile)
	journey.landmarks = JourneyFlags.landmarks_from_world(world)
	menu.saves = saves
	menu.settings = settings
	_build_pause_menu()
	_toast = MenuToast.new()
	$UI.add_child(_toast)
	_prompt = PlayerPrompt.new()
	_prompt.name = "PlayerPrompt"
	$UI.add_child(_prompt)
	_build_gameplay_hud()
	_connect_signals()
	_setup_cine()
	_setup_world_host()
	_setup_roam_time()
	_setup_camp_weather()
	_setup_camp_life()
	_setup_wait_wheel()
	_reset_to_menu_state()
	_start_audio()
	_apply_settings()
	# Tanhu 1'deki gibi önce Mete'nin sözü (siyah perdenin üstünde), sonra menünün girişi perdeyi kaldırır.
	if _wants_epigraph():
		await _play_epigraph()
	fade.color.a = 0.0
	menu.play_intro()
	_bake_camp_map_later()
	_apply_dev_arguments()


func _exit_tree() -> void:
	# Çocukluk'un görünmez perdesi ağaçta değildir: sahiplenen yok, burada bırakılır.
	if is_instance_valid(_childhood_curtain) and not _childhood_curtain.is_inside_tree():
		_childhood_curtain.free()
	_childhood_curtain = null


func _process(delta: float) -> void:
	if _dev_args.has("cine-log") and cine.is_playing():
		_cine_log_left -= delta
		if _cine_log_left <= 0.0:
			_cine_log_left = 1.0
			var seg_id := str(cine.timeline().segment_at(cine.time()).get("id", "")) if cine.timeline() else ""
			var line := "[cine] %.2f sn · tutuldu %s · %s" % [cine.time(), cine.runner.held, seg_id]
			var scene := cine.scene_node(seg_id)
			var anim := scene.get(&"player") as AnimationPlayer if scene else null
			if anim:
				line += " · canlandırma %s %s %.2f ×%.2f" % [anim.current_animation, "oynuyor" if anim.is_playing() else "duruyor", anim.current_animation_position if anim.has_animation(anim.current_animation) else -1.0, anim.speed_scale]
			print(line)
	_tick_flow(delta)
	if state != State.PLAYING:
		return
	journey.play_time += delta
	_flag_timer -= delta
	if _flag_timer <= 0.0:
		_flag_timer = FLAG_CHECK_INTERVAL
		var fresh := _visit_journey()
		if not fresh.is_empty():
			_announce_unlocks()
		if _camp_voice:
			_camp_voice.visited(fresh)
		_check_map_gate()


## Akışın kare işleri (Yeni Oyun sürerken): sinemanın zamanlı takvim atlamaları, Köprü 1'in donmuş karesinin bırakılması, «Çocukluğu geç»in
## basılı Esc'i, Çocukluk donunca HUD'un sönmesi.
func _tick_flow(delta: float) -> void:
	if _flow == null:
		return
	if not _timed_jumps.is_empty() and cine.is_playing():
		while not _timed_jumps.is_empty() and cine.time() >= float(_timed_jumps[0][0]):
			_advance_day(int(_timed_jumps.pop_front()[1]))
	if _still_curtain:
		if cine.is_skipping():
			# Atlanan köprü donmuş kareye geri açılmasın: perde karaya döner.
			_still_curtain.black = 1.0
		elif not cine.is_playing() or (cine.time() >= _still_until and _still_curtain.color.a <= 0.001):
			_release_still()
	if _childhood_scene and state == State.PLAYING and _childhood_scene.current_phase() in ["fade", "black"] and gameplay_hud.modulate.a > 0.0:
		# Görüntü dondu: HUD kısa bir solmayla çekilir (donmuş karede arayüz yoktur).
		gameplay_hud.modulate.a = maxf(gameplay_hud.modulate.a - delta / 0.5, 0.0)
	if _skip_tracking:
		_tick_skip_hold(delta)


## Yolculuğa oyuncunun yerini yazar, oradaki yer işaretlerini koyar. Çocuk ateş başındaki yerindeyken ya da hikâyenin küçük dünyalarında (Çocukluk,
## Yola Çıkış) yalnız yer yazılır.
func _visit_journey() -> PackedStringArray:
	if _seat_hold and Vector2(player.global_position.x - _seat_at.x, player.global_position.z - _seat_at.z).length() >= SEAT_LEAVE:
		_seat_hold = false
	if _seat_hold or _story_world() or _prologue_days:
		journey.position = player.global_position
		journey.yaw = player.get_facing_yaw()
		return PackedStringArray()
	return journey.visit(player.global_position, player.get_facing_yaw())


## Oyuncunun belirdiği nokta: Çocuk'sa ateş başındaki yeri, yoksa kamp ateşinin önü (ateş yoksa dünyanın merkezi).
func spawn_point() -> Vector3:
	if player.is_child():
		var seat := _camp_npcs().child_seat() if _camp_npcs() else {}
		if not seat.is_empty():
			return (seat["transform"] as Transform3D).origin
	var fire := world.get_node_or_null(^"Camp/Campfire") as Node3D
	var base := fire.global_position if fire else Vector3.ZERO
	return Vector3(base.x, 0.0, base.z) + SPAWN_OFFSET


# --- Menü olayları -----------------------------------------------------------------

## Yeni Oyun: akış (Önsöz, Çocukluk, Köprü 1, oluşturucu, Köprü 2, son kart).
func _on_start_requested() -> void:
	if state != State.MENU:
		return
	_begin_new_game(new_game_from)


## Yeni Oyun'un oynatılabilir Önsöz dosyası; yol boşsa, dosya yoksa ya da boşsa "".
func prologue_file() -> String:
	var path := prologue_path.strip_edges()
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return path if not FileAccess.get_file_as_string(path).strip_edges().is_empty() else ""


## Oluşturucuyu kara perdenin arkasında açar, perde kalkar.
func _show_creator() -> void:
	creator.visible = true
	creator.open(profile.copy())
	# Oluşturucu ekranı tamamen örttüğü için ana 3B sahneyi çizmeye gerek yok (performans).
	get_viewport().disable_3d = true
	await _fade_to(0.0, 0.35)
	state = State.CREATOR


## Önsöz: menü yazıları sönerken (beklenmez) sinema başlar; bitince ya da basılı Esc'te perde karadır, menü kamerası menü kadrajına
## döner. at > 0 ise sinema oraya ileri sarılır (--cine-at).
func _play_prologue(path: String, at: float = 0.0) -> void:
	state = State.CINE
	if not _prologue_days_played:
		_play_ui(&"whoosh")
	menu.hide_menu(true)
	cine.speed = cine_speed
	await cine.play(path, at)
	_prologue_done = true
	_remember_prologue_seen()
	state = State.BUSY
	if fade.color.a < 0.999:
		await _fade_to(1.0, 0.35)
	_reset_menu_view(false)


## Önsöz görülmüş ve "her yeni oyunda" seçili değil mi (GameSettings; alan yoksa hayır)?
func _prologue_skipped_by_setting() -> bool:
	if settings == null or not (&"prologue_seen" in settings) or not bool(settings.get(&"prologue_seen")):
		return false
	return not (&"prologue_always" in settings and bool(settings.get(&"prologue_always")))


## İlk oynatmada prologue_seen yazılır (geliştirme ve test çalıştırmalarında remember_prologue kapalıdır).
func _remember_prologue_seen() -> void:
	if not remember_prologue or settings == null or not (&"prologue_seen" in settings):
		return
	if bool(settings.get(&"prologue_seen")):
		return
	settings.set(&"prologue_seen", true)
	if settings.has_method(&"save_settings"):
		settings.save_settings()


## Sinemadan sonra menünün görünümü: menü kamerası menü kadrajında ve etkin; music açıksa menü müziği geri gelir
## (sahneler kendi dokunduklarını restore()'da zaten geri yazar; bu son güvencedir).
func _reset_menu_view(music: bool = true) -> void:
	if menu_camera.has_method(&"clear_drift"):
		menu_camera.call(&"clear_drift")
	menu_camera.global_transform = menu_camera.menu_transform
	menu_camera.drifting = true
	menu_camera.design_fov = menu_camera.design_fov
	menu_camera.make_current()
	if music:
		cine.audio.restore_menu_music()


func _on_free_roam_requested() -> void:
	if state != State.MENU:
		return
	state = State.BUSY
	_play_ui(&"whoosh")
	await menu.hide_menu(true)
	journey.profile = profile.copy()
	journey.set_flag(ROAM_CHILD_FLAG)
	_open_session(Session.MODE_ROAM)
	await _enter_play()


func _on_continue_requested() -> void:
	await _load_from_menu(saves.latest_slot())


func _on_load_requested(slot: int) -> void:
	await _load_from_menu(slot)


## Açılış ekranından bir kaydı yükler: karakter, yer, süre ve işaretler kayıttan gelir.
func _load_from_menu(slot: int) -> void:
	if state != State.MENU:
		return
	var record := saves.slot_info(slot)
	if not flow_stage_of(record).is_empty() and journey.apply_record(record):
		# Yeni Oyun'un kayıt noktası (E21): akış o aşamanın o gününün başından açılır.
		state = State.BUSY
		profile = journey.profile.copy()
		_play_ui(&"whoosh")
		await menu.hide_menu(true)
		_resume_flow(record)
		return
	if not journey.apply_record(record) or not _open_session():
		menu.show_toast(MainMenu.LOAD_FAILED, "warn")
		menu.refresh_saves()
		return
	state = State.BUSY
	profile = journey.profile.copy()
	_play_ui(&"whoosh")
	await menu.hide_menu(true)
	# Kayıt v2'nin map bloğu iç haritayı gösteriyorsa (deneme haritası) oraya, kaydedilen yere inilir.
	if await _enter_saved_map():
		return
	if Journey.record_has_position(record):
		await _enter_play(journey.position, journey.yaw)
	else:
		await _enter_play()


func _on_quit_requested() -> void:
	if state == State.BUSY:
		return
	state = State.BUSY
	await _quit_with_fade()


# --- Yeni Oyun'un akışı (K99) ------------------------------------------------------------------

## Akışı başlatır (from: o aşamadan; boşsa baştan) ve sonuna dek sürer: her aşama bitince sıradaki, en sonda açılış ekranı. Aşama
## bırakılırsa (Ana Menü, Yükle) akış sayacı değişir, bu döngü sessizce biter.
func _begin_new_game(from: String = "") -> void:
	_flow_serial += 1
	var serial := _flow_serial
	_prologue_done = false
	_flow_committed = false
	if _flow_resuming:
		# Kayıt noktasından (E21): yolculuk kayıttandır, yeniden kurulmaz.
		_flow_resuming = false
		_flow_committed = true
	else:
		_flow_resume.clear()
		_flow_bag = {}
	day_history.clear()
	_timed_jumps.clear()
	_flow = NewGameFlow.from_data(new_game_data) if not new_game_data.is_empty() else NewGameFlow.load_default()
	_flow.start(from, new_game_only)
	state = State.BUSY
	while serial == _flow_serial:
		var stage := _flow.next()
		if stage.is_empty():
			_flow = null
			# Akış bitti: kayıt noktasının heybesi yolculukta kalmaz (oturum kendi «inventory» bloğunu kurar).
			journey.blocks.erase(FLOW_BAG_BLOCK)
			_release_preloads()
			await _show_title_from_black()
			return
		if str(stage.get("kind", "")) != "prologue":
			_flow_commit()
		if not _dev_args.is_empty():
			print("[yeni oyun] kare %d · aşama %s" % [Engine.get_process_frames(), stage.get("id", "")])
		_play_stage(serial, stage)
		var ok: bool = await _stage_done
		if serial != _flow_serial:
			return
		if not ok:
			# Vazgeçildi (oluşturucuda Geri Al) ya da aşama kurulamadı: akış biter, açılış ekranı gelir.
			_flow = null
			_flow_serial += 1
			_release_preloads()
			await _show_title_from_black()
			return
		_apply_jump(stage)


## Süren Yeni Oyun aşamasının kimliği ("" = akış yok).
func flow_stage_id() -> String:
	return _flow.current_id() if _flow else ""


## Yeni Oyun'un akışı sürüyor mu?
func is_new_game_running() -> bool:
	return _flow != null


## Aşamayı başlatır (beklenmez); aşama bitince _finish_stage çağrılır.
func _play_stage(serial: int, stage: Dictionary) -> void:
	match str(stage.get("kind", "")):
		"prologue":
			_stage_prologue(serial)
		"childhood":
			_stage_childhood(serial, stage)
		"cine":
			_stage_cine(serial, stage)
		"creator":
			_stage_creator(serial)
		"scene":
			_stage_scene(serial, stage)
		"card":
			_stage_card(serial, stage)
		_:
			_finish_stage(serial, true)


## Aşama bitti: akış (aynı akışsa) sıradakine geçer. Yayılma ertelenir: aşama eşzamanlı bitse de akış onu bekliyordur.
func _finish_stage(serial: int, ok: bool) -> void:
	if serial == _flow_serial and _flow != null:
		_stage_done.emit.call_deferred(ok)


## Akışı bırakır (Ana Menü, Yükle): bekleyen döngü uyanır ve biter, geç kalan aşama işleri tanınır.
func _flow_abort() -> void:
	_flow_bag = {}
	if _flow == null:
		return
	_flow = null
	_flow_serial += 1
	_timed_jumps.clear()
	_release_still()
	_hide_skip_offer()
	_release_preloads()
	_stage_done.emit.call_deferred(false)


## Kampın dışındaki dünya (Çocukluk, Yola Çıkış ya da iç harita; yoksa null): oyuncu oradayken kampın yer işaretleri sayılmaz, Serbest
## Gez'in saati ve kamp havası çalışmaz. Kayıt yalnız hikâyenin küçük dünyalarında kapalıdır (_save_allowed).
func _story_world() -> Node3D:
	if _childhood_world:
		return _childhood_world
	if _map_world:
		# İç harita (deneme haritası): kampın yer işaretleri sayılmaz; kayıt v2'nin map bloğuyla kayıt yazılır.
		return _map_world
	return _depart_world


## Kayıt yazılabilir mi? Yeni Oyun'un küçük dünyalarında (Çocukluk, Yola Çıkış; K99) yazılmaz; kampta ve iç haritada yazılır.
func _save_allowed() -> bool:
	return _childhood_world == null and _depart_world == null


## Yeni yolculuk Önsöz'den sonraki ilk aşamada başlar: işaretler ve süre sıfırlanır; Önsöz'ün işareti yazılır. Kayıt yazılmaz.
func _flow_commit() -> void:
	if _flow_committed:
		return
	_flow_committed = true
	journey.reset(profile)
	if _prologue_done:
		journey.set_flag(CineHost.PROLOGUE_FLAG)
	_snapshot_unlocks()


## Aşamanın takvim atlamaları (K67): sinemada zamanlı olup yazılmamış kalanlar (atlanan köprü) ve aşama sonunun atlaması, sırayla.
func _apply_jump(stage: Dictionary) -> void:
	while not _timed_jumps.is_empty():
		_advance_day(int(_timed_jumps.pop_front()[1]))
	for jump in NewGameFlow.jumps(stage):
		if not jump.has("at"):
			_advance_day(int(jump["day_n"]))


## Yolculuğun takvim günü ileri gider (K67: geri gitmez); değiştiyse day_history'ye eklenir.
func _advance_day(day_n: int) -> void:
	var now: Variant = journey.flags.get(NewGameFlow.DAY_FLAG)
	var next := NewGameFlow.advance(now, day_n)
	if now != null and int(now) == next:
		return
	journey.set_flag(NewGameFlow.DAY_FLAG, next)
	day_history.append(next)
	if not _dev_args.is_empty():
		print("[yeni oyun] takvim günü %d" % next)


## Sinemanın zamanlı atlamaları (at: çizelgenin olay kimliği): saati gelince _tick_flow yazar.
func _plan_timed_jumps(stage: Dictionary, path: String) -> void:
	_timed_jumps.clear()
	var timed: Array = []
	for jump in NewGameFlow.jumps(stage):
		if jump.has("at"):
			timed.append(jump)
	if timed.is_empty():
		return
	var timeline := CineTimeline.from_path(path)
	for jump: Dictionary in timed:
		var t := timeline.time_of(str(jump["at"]))
		# Çizelgede olayı yoksa sinemanın başında yazılır (atlama yine aşamanın içindedir).
		_timed_jumps.append([0.0 if is_nan(t) else t, int(jump["day_n"])])
	_timed_jumps.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))


func _stage_prologue(serial: int) -> void:
	var path := _prologue_override if not _prologue_override.is_empty() else prologue_file()
	if path.is_empty():
		_finish_stage(serial, true)
		return
	if _prologue_skipped_by_setting() and not _force_prologue and not _flow_resume.has("prologue"):
		# Oyuncu Önsöz'ü gördü: varsayılan atlanır (story.md §3), mitlerin işareti yine yazılır.
		_prologue_done = true
		_finish_stage(serial, true)
		return
	# E21 (K110): sinemadan önce Göl Obası'nda oynanan üç gün. Sonunda kamera menü kadrajındadır, sinema 0'dan oynar; basılı Esc ikisini atlar.
	_prologue_days_played = false
	if _prologue_override.is_empty() and NewGameFlow.file_ok(prologue_days_path):
		var ending := await _play_prologue_days(serial)
		if serial != _flow_serial or ending == "aborted":
			return
		_prologue_days_played = true
		if ending == "skipped":
			_prologue_done = true
			_remember_prologue_seen()
			journey.set_flag(CineHost.PROLOGUE_FLAG)
			_reset_menu_view(false)
			_finish_stage(serial, true)
			return
	var at := _prologue_at
	_prologue_at = 0.0
	await _play_prologue(path, at)
	if _flow_committed:
		journey.set_flag(CineHost.PROLOGUE_FLAG)
	_finish_stage(serial, true)


## Önsöz'ün oynanan üç günü (E21, K110; PrologueDays): kara perdede açılır, yeni yolculuk günlerin başında kurulur (kayıt noktası bu
## yolculuğu yazar; kayıttan açılışta yolculuk kayıttandır), Çocuk kampta oynar. Döner: "cinema" (kamera menü kadrajında, sinema oynar),
## "skipped" (basılı Esc; perde kara), "end" (sinema adımı yok), "aborted" (akış bırakıldı).
func _play_prologue_days(serial: int) -> String:
	state = State.BUSY
	await _cover_title()
	if serial != _flow_serial:
		return "aborted"
	if _flow_resume.has("prologue"):
		_flow_committed = true
	else:
		_flow_commit()
	var order := PrologueDays.load_order(prologue_days_path)
	var day_index := maxi(prologue_day - 1, 0)
	var resume_day := str(_flow_resume.get("prologue", ""))
	if not resume_day.is_empty():
		day_index = maxi(PrologueDays.day_index_of(order, resume_day), 0)
	var quest := prologue_quest if resume_day.is_empty() else ""
	var step_id := prologue_step if resume_day.is_empty() else ""
	_flow_resume.erase("prologue")
	player.use_child(ChildLook.PERSON_CHILD)
	_seat_hold = false
	player.visible = true
	var days := PrologueDays.new()
	days.name = "PrologueDays"
	days.order = order
	days.setup({"main": self, "world": world, "player": player, "camera": follow_camera, "menu_camera": menu_camera, "ui": $UI, "fade": fade,
		"game_hud": gameplay_hud, "card": cine.card,
		"state": func(on: bool) -> void:
			if serial == _flow_serial and _prologue_days:
				state = State.PLAYING if on else State.BUSY})
	days.dev_at = _prologue_dev_at
	days.dev_yaw = _prologue_dev_yaw
	days.dev_clock = str(_dev_args.get("clock", "")) if str(_dev_args.get("clock", "true")) != "true" else ""
	_prologue_dev_at = Vector3.INF
	add_child(days)
	_prologue_days = days
	days.day_started.connect(_on_prologue_day_started.bind(serial))
	await days.prepare()
	if serial != _flow_serial or not is_instance_valid(days):
		return "aborted"
	gameplay_hud.set_quest_source(days)
	gameplay_hud.finished_quests = []
	gameplay_hud.begin_body()
	follow_camera.target = player
	menu_camera.drifting = false
	follow_camera.set_active(true)
	days.begin(day_index, quest, step_id)
	_offer_prologue_skip()
	_start_prologue_autoplay(_dev_args)
	var result: Dictionary = await days.finished
	if serial != _flow_serial:
		return "aborted"
	var ending := str(result.get("ending", "end"))
	for k: String in (result.get("flags", {}) as Dictionary):
		journey.set_flag(k, result["flags"][k])
	_hide_skip_offer()
	_leave_prologue_days()
	if ending == "end":
		# Sinema adımı yok (yer tutucu son gün): perde karayken menü kadrajı kurulur, sinema oradan açılır.
		_reset_menu_view(false)
	return ending


## Günün başı (kart kara perdedeyken): kayıt noktası (E21).
func _on_prologue_day_started(_day_index: int, day_id: String, serial: int) -> void:
	if serial != _flow_serial:
		return
	flow_save_point("prologue", day_id)


## Yeni Oyun'un kayıt noktası (E21, K110; e21-prologue-api.md §7): oto kayıt (0. yuva) aşamanın ve günün işaretleriyle; Önsöz'ün günler arası
## sonuçları (onsoz_*) da yazılır. Devam Et ve Yükle böyle bir kayıtta akışı o aşamanın o gününden açar. Geliştirme koşuları yazmaz
## (SaveSystem). Döner: yazıldı mı.
func flow_save_point(stage_id: String, day_id: String) -> bool:
	journey.set_flag(FLOW_STAGE_FLAG, stage_id)
	journey.set_flag(FLOW_DAY_FLAG, day_id)
	if _prologue_days:
		for k: String in _prologue_days.flags:
			journey.set_flag(k, _prologue_days.flags[k])
	# Heybe de yazılır (Ç2'nin çetelesi, Önsöz'ün taşıdıkları): kayıttan açılıştaysa önce kayıttaki heybe geri gelir.
	flow_restore_bag()
	var bag := gameplay_hud.bag.inventory if gameplay_hud and gameplay_hud.bag else null
	if bag and session == null:
		journey.blocks[FLOW_BAG_BLOCK] = bag.to_dict()
	journey.pending_thumb = null
	return journey.save_auto(&"day_start")


## Kayıttan açılan akışın heybesini geri koyar (bir kez; yoksa bir şey yapmaz). Aşama heybeyi begin_body ile sıfırladıktan sonra çağrılır:
## günün başındaki kayıt noktası (flow_save_point) kendisi çağırır; heybe daha önce gerekirse aşama da çağırabilir. Döner: geri kondu mu.
func flow_restore_bag() -> bool:
	if _flow_bag.is_empty():
		return false
	var block := _flow_bag
	_flow_bag = {}
	var bag := gameplay_hud.bag.inventory if gameplay_hud and gameplay_hud.bag else null
	return bag != null and bag.from_dict(block)


## Kayıt noktasından açılan aşamanın günü (yoksa ""): Çocukluk da okur (e21-childhood-api.md §6).
func flow_resume_day(stage_id: String) -> String:
	return str(_flow_resume.get(stage_id, ""))


## Kaydın Yeni Oyun aşaması (kayıt noktası değilse "").
static func flow_stage_of(record: Dictionary) -> String:
	var flags: Variant = record.get("flags", {})
	if not flags is Dictionary:
		return ""
	var stage: Variant = (flags as Dictionary).get(FLOW_STAGE_FLAG, "")
	return str(stage) if stage is String else ""


## Kayıt noktasından Yeni Oyun: yolculuk kayıttandır (journey.apply_record yapıldı), akış o aşamanın o gününden açılır.
func _resume_flow(record: Dictionary) -> void:
	var flags: Dictionary = SaveData.parse(record)["flags"]
	var stage := str(flags.get(FLOW_STAGE_FLAG, ""))
	_flow_resume.clear()
	_flow_resume[stage] = str(flags.get(FLOW_DAY_FLAG, ""))
	var bag_block: Variant = journey.blocks.get(FLOW_BAG_BLOCK)
	_flow_bag = (bag_block as Dictionary).duplicate(true) if bag_block is Dictionary else {}
	_flow_resuming = true
	_close_session()
	state = State.MENU
	_begin_new_game(stage)


## Önsöz'ün koşucusu bırakılır (perde karayken): kampın Önsöz düzeni kalkar, oyuncu ve HUD durur.
func _leave_prologue_days() -> void:
	var auto := get_node_or_null(^"PrologueAutoplay")
	if auto:
		auto.queue_free()
	if _prologue_days:
		_prologue_days.stop()
		_prologue_days.queue_free()
	_prologue_days = null
	gameplay_hud.set_quest_source(null)
	pause_menu.save_note = ""
	pause_menu.card_place = ""
	pause_menu.card_note = ""
	player.set_active(false)
	follow_camera.set_active(false)
	hud.hide_hud(false)


## «Önsözü geç: Esc basılı tut»: Önsöz'ü bir kez görmüş oyuncuya (K110) ya da geliştirmede --skip-offer; basılı Esc her durumda atlar (K100).
func _offer_prologue_skip() -> void:
	var seen := settings != null and (&"prologue_seen" in settings) and bool(settings.get(&"prologue_seen"))
	if not seen and not _dev_args.has("skip-offer"):
		return
	if _skip_offer == null:
		_skip_offer = _SkipOffer.new()
		_skip_offer.name = "SkipOffer"
		$UI.add_child(_skip_offer)
	_skip_offer.text = NewGameFlow.text(PROLOGUE_SKIP_TEXT, SubtitleBar.ui_lang())
	_skip_offer.offer(SKIP_OFFER_SECONDS)


## Süren Önsöz koşucusu (sınama; yoksa null).
func prologue_runner() -> PrologueDays:
	return _prologue_days


## --autoplay: Önsöz'ün günlerini tuşsuz oynar (geliştirme; scripts/dev/prologue_autoplay.gd).
func _start_prologue_autoplay(args: Dictionary) -> void:
	if not args.has("autoplay") or _prologue_days == null or get_node_or_null(^"PrologueAutoplay") != null:
		return
	var script: Script = load("res://scripts/dev/prologue_autoplay.gd")
	var auto: Node = script.new()
	auto.name = "PrologueAutoplay"
	auto.call(&"setup", _prologue_days, player, follow_camera)
	add_child(auto)


## Çocukluk «Koyun Sırtında»: kara perdede tarih kartı, Ordos kurulur, sahne kişileriyle hazırlanır, perde kalkar; sahne bitince
## (kara perde) dünya bırakılır, işaretler yazılır.
func _stage_childhood(serial: int, stage: Dictionary) -> void:
	state = State.BUSY
	await _cover_title()
	if serial != _flow_serial:
		return
	# E21 (K110): Çocukluk'un günleri (aşamanın days'i; ChildhoodDays): ilk gün, ya da --day, ya da --step'i içeren gün.
	var days_path := str(stage.get("days", "")) if childhood_days_path == "stage" else childhood_days_path
	_childhood_days = ChildhoodDays.load_default(days_path) if not days_path.is_empty() else null
	# Kayıt noktasından açılan Yeni Oyun o günün başından (Ö1'in düzeneği: flow_resume_day); günün başı kayıt noktasıdır (--step ile ortadan
	# açılan gün yazmaz).
	var resume := flow_resume_day("childhood")
	var start: Dictionary = _childhood_days.resolve(childhood_day if not childhood_day.is_empty() else resume, childhood_step) if _childhood_days else {}
	_childhood_day_saves = childhood_step.is_empty()
	var day_id := str(start.get("day", ""))
	var data := _childhood_days.data_of(day_id) if not day_id.is_empty() else ChildhoodScene.load_data(str(stage.get("scene", ChildhoodScene.SCENE_PATH)))
	var lang := SubtitleBar.ui_lang()
	var date := NewGameFlow.text(data.get("date"), lang)
	var shown := Time.get_ticks_msec()
	if not date.is_empty():
		cine.card(date, CHILDHOOD_CARD_SECONDS)
	_advance_day(int(data.get("day_n", -5600)))
	if not await _enter_childhood({}, true):
		push_warning("[main] Çocukluk'un dünyası kurulamadı (%s)" % CHILDHOOD_WORLD)
		_finish_stage(serial, false)
		return
	if serial != _flow_serial:
		return
	var scene := _make_childhood_scene(serial, data, day_id)
	await scene.prepare()
	if serial != _flow_serial or not is_instance_valid(scene):
		return
	gameplay_hud.set_quest_source(scene)
	gameplay_hud.finished_quests = []
	while (Time.get_ticks_msec() - shown) / 1000.0 < CHILDHOOD_CARD_MIN and not date.is_empty():
		await get_tree().process_frame
	scene.begin(str(start.get("step", childhood_step)) if not day_id.is_empty() else childhood_step)
	# Atlanan adımların avı (geliştirme --step) heybede de olsun: sahnenin sayısıyla aynı.
	for kind: String in scene.catch:
		gameplay_hud.bag.add(kind, int(scene.catch[kind]))
	await _fade_to(0.0, 0.9)
	if serial != _flow_serial:
		return
	state = State.PLAYING
	_offer_childhood_skip()
	_start_drive(_dev_args)
	_start_autoplay(_dev_args)


## E21 (K110): günün sahnesi. Amaç satırını oyun içi HUD'un görev kartı gösterir (StoryHud'un sade bloğu kapalı; altyazı yine onundur).
## Sahnenin kararttığı perde görünmez bir perdedir: «Beni gördü.»de görüntü donar, donmuş kare Köprü 1'in parşömenine çapraz geçer
## (_on_childhood_finished); uykunun kararması görünür perdedir (screen_fade). Sıradaki gün result.next_day'dir.
func _make_childhood_scene(serial: int, data: Dictionary, day_id: String) -> ChildhoodScene:
	var scene := ChildhoodScene.new()
	scene.name = "ChildhoodScene"
	scene.data = data
	scene.day_id = day_id
	scene.next_day = _childhood_days.next_of(day_id) if _childhood_days and not day_id.is_empty() else ""
	scene.screen_fade = fade
	# E21 (Ç2): heybe sahnenindir de (Çetele'nin kurutu ve çetelesi; sayım gününün «Hereka'nın çentikleri. Yedi.»si).
	scene.inventory = gameplay_hud.bag.inventory
	scene.objective_box = false
	scene.setup(_childhood_world, player, follow_camera, _childhood_sheep_map(), $UI, fade, hud, _childhood_fade_proxy())
	add_child(scene)
	_childhood_scene = scene
	scene.finished.connect(_on_childhood_finished.bind(serial))
	scene.day_started.connect(_on_childhood_day_started)
	return scene


## E21: günün başı (kart kara perdedeyken): kayıt noktası (Ö1'in düzeneği, e21-prologue-api.md §7: flow_save_point).
func _on_childhood_day_started(day_id: String) -> void:
	if _childhood_day_saves and not day_id.is_empty():
		flow_save_point("childhood", day_id)


## E21: gün bitti, sıradaki gün aynı dünyada açılır. Uyku perdeyi kararttı (kartlı gün: kara perdede günün kartı); aynı akşamın devamı
## (card false) kısa kararmayla, kartsız açılır. İşaretler yazılır, kişiler yeni günün verisinden kurulur; bot ve sürüş yeniden bağlanır.
func _next_childhood_day(serial: int, result: Dictionary) -> void:
	state = State.BUSY
	for f: String in result.get("flags", PackedStringArray()):
		journey.set_flag(f)
	var next := str(result.get("next_day", ""))
	var data := _childhood_days.data_of(next) if _childhood_days else {}
	var carded := _childhood_days.carded(next) if _childhood_days else true
	if fade.color.a < 0.99:
		await _fade_to(1.0, 1.2 if carded else 0.6)
	if serial != _flow_serial:
		return
	var date := NewGameFlow.text(data.get("date"), SubtitleBar.ui_lang()) if carded else ""
	var shown := Time.get_ticks_msec()
	if not date.is_empty():
		cine.card(date, CHILDHOOD_CARD_SECONDS)
	_advance_day(int(data.get("day_n", -5600)))
	_end_childhood_scene()
	if data.is_empty():
		_finish_stage(serial, true)
		return
	_childhood_day_saves = true
	var scene := _make_childhood_scene(serial, data, next)
	await scene.prepare()
	if serial != _flow_serial or not is_instance_valid(scene):
		return
	gameplay_hud.set_quest_source(scene)
	while (Time.get_ticks_msec() - shown) / 1000.0 < CHILDHOOD_CARD_MIN and not date.is_empty():
		await get_tree().process_frame
	scene.begin("")
	await _fade_to(0.0, 0.9)
	if serial != _flow_serial:
		return
	state = State.PLAYING
	_start_autoplay(_dev_args)


## «Beni gördü.»: sahne görüntüyü dondurdu (görünmez perdeyi kararttı). Donmuş kare arayüzsüz çekilir, Köprü 1'in baş perdesi olur
## (_StillCurtain): köprü açılırken kare parşömene çapraz geçer. Çocukluk ilk bitişte ayara yazılır («Çocukluğu geç»).
func _on_childhood_finished(result: Dictionary, serial: int) -> void:
	if serial != _flow_serial:
		return
	if result.has("next_day"):
		_next_childhood_day(serial, result)
		return
	state = State.BUSY
	_hide_skip_offer()
	for f: String in result.get("flags", PackedStringArray()):
		journey.set_flag(f)
	_remember_childhood_done()
	await _capture_still()
	if serial != _flow_serial:
		_release_still()
		return
	_end_childhood()
	_finish_stage(serial, true)


## Sahnenin kararttığı görünmez perde (ağaçta değil): Çocukluk'un sonu kararmaz, donar.
func _childhood_fade_proxy() -> ColorRect:
	if _childhood_curtain == null:
		_childhood_curtain = ColorRect.new()
		_childhood_curtain.color = Color(0, 0, 0, 0)
	_childhood_curtain.color.a = 0.0
	return _childhood_curtain


## Ekranın donmuş karesini arayüzsüz çeker ve perdenin üstüne serer (opak). Başsızda (sınama) görüntü yoktur: kare karadır.
func _capture_still() -> void:
	_release_still()
	gameplay_hud.hide_now()
	hud.hide_hud(false)
	# İpucunun görünürlüğü kendi elindedir (çifti yoksa gizli): kareden sonra eski hâline döner.
	var prompt_was := _prompt.visible
	_prompt.visible = false
	_toast.visible = false
	var tex: Texture2D = null
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		if img and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_prompt.visible = prompt_was
	_toast.visible = true
	_still_curtain = _StillCurtain.new()
	_still_curtain.name = "StillCurtain"
	_still_curtain.set_still(tex)
	$UI.add_child(_still_curtain)
	$UI.move_child(_still_curtain, fade.get_index() + 1)


## Donmuş kare bırakılır; sinemanın perdesi yine UI/Fade'dir. Kare o an örtüyorsa (atlanan köprünün kararması) perde onun örtüsünü alır.
func _release_still() -> void:
	if is_instance_valid(_still_curtain) and _still_curtain.color.a > fade.color.a:
		fade.color.a = _still_curtain.color.a
	if cine.fade_rect != fade:
		cine.fade_rect = fade
	if is_instance_valid(_still_curtain):
		_still_curtain.queue_free()
	_still_curtain = null


## Çocukluk ilk bitişte GameSettings.childhood_done'a yazılır (geliştirme ve test çalıştırmalarında remember_childhood kapalıdır).
func _remember_childhood_done() -> void:
	if not remember_childhood or settings == null or not (&"childhood_done" in settings) or bool(settings.get(&"childhood_done")):
		return
	settings.set(&"childhood_done", true)
	if settings.has_method(&"save_settings"):
		settings.save_settings()


## «Çocukluğu geç» sunulur mu? Oyuncu Çocukluk'u bir kez bitirdiyse (GameSettings.childhood_done) ya da geliştirmede --skip-offer.
func childhood_skip_offered() -> bool:
	if _dev_args.has("skip-offer"):
		return true
	return settings != null and (&"childhood_done" in settings) and bool(settings.get(&"childhood_done"))


func _offer_childhood_skip() -> void:
	if not childhood_skip_offered():
		return
	if _skip_offer == null:
		_skip_offer = _SkipOffer.new()
		_skip_offer.name = "SkipOffer"
		$UI.add_child(_skip_offer)
	_skip_offer.text = NewGameFlow.text(SKIP_OFFER_TEXT, SubtitleBar.ui_lang())
	_skip_offer.offer(SKIP_OFFER_SECONDS)


func _hide_skip_offer() -> void:
	_skip_tracking = false
	_skip_hold = 0.0
	if _skip_offer:
		_skip_offer.retract()


## Esc basılı tutulurken sayılır: SKIP_HOLD'a varınca Çocukluk atlanır; erken bırakılırsa kısa basıştır, duraklatma kitabı açılır.
func _tick_skip_hold(delta: float) -> void:
	if state != State.PLAYING or (_childhood_scene == null and _prologue_days == null):
		_skip_tracking = false
		return
	if Input.is_action_pressed(&"pause"):
		_skip_hold += delta
		if _skip_offer:
			_skip_offer.show_progress(_skip_hold / CineHost.SKIP_HOLD)
		if _skip_hold >= CineHost.SKIP_HOLD:
			_skip_tracking = false
			if _prologue_days:
				# E21 (K100): basılı Esc Önsöz'ü (günler ve sinema) atlar.
				_hide_skip_offer()
				_prologue_days.skip()
			else:
				_skip_childhood(_flow_serial)
		return
	_skip_tracking = false
	_skip_hold = 0.0
	if _skip_offer:
		_skip_offer.show_progress(0.0)
	_open_pause("genel")


## Çocukluğu geç: perde kararır, sahne ve dünya bırakılır, «mq0_sheep» ve «child_skipped» yazılır; Köprü 1 karadan açılır.
func _skip_childhood(serial: int) -> void:
	if serial != _flow_serial or _childhood_scene == null:
		return
	state = State.BUSY
	_hide_skip_offer()
	player.set_active(false)
	var flags: Dictionary = _childhood_scene.data.get("flags", {})
	journey.set_flag(str(flags.get("done", "mq0_sheep")))
	# E21: «Çocukluğu geç» bütün günleri atlar: sayım gününün işareti de yazılır.
	journey.set_flag(str((ChildhoodScene.load_data().get("flags", {}) as Dictionary).get("done", "mq0_sheep")))
	journey.set_flag(CHILDHOOD_SKIPPED_FLAG)
	# Müzik Köprü 1'in bankasına geçer (çizelgenin ilk olayı); ortam katmanlarını sahnenin stop()'u söndürür.
	await _fade_to(1.0, CineHost.SKIP_FADE)
	if serial != _flow_serial:
		return
	_end_childhood()
	_finish_stage(serial, true)


## Çocukluk'un sahnesini ve dünyasını bırakır (perde karayken): oyuncu gizlenir, kamera menüye döner.
func _end_childhood() -> void:
	_end_childhood_scene()
	player.set_active(false)
	follow_camera.set_active(false)
	hud.hide_hud(false)
	_leave_childhood()
	player.visible = false
	menu_camera.make_current()


func _end_childhood_scene() -> void:
	var drive := get_node_or_null(^"ChildDrive")
	if drive:
		drive.queue_free()
	var auto := get_node_or_null(^"ChildhoodAutoplay")
	if auto:
		auto.queue_free()
	if _childhood_scene:
		_childhood_scene.stop()
		_childhood_scene.queue_free()
		_childhood_scene = null
	gameplay_hud.set_quest_source(null)
	pause_menu.save_note = ""
	pause_menu.card_place = ""
	pause_menu.card_note = ""


## Köprüler (sinema): kendi görünümünde, karadan açılır, karaya kapanır; Esc atlar. Önceki aşama donmuş bir kare bıraktıysa (Çocukluk'un
## «Beni gördü.»sü) köprünün baş perdesi o karedir: açılış kareyi parşömene çapraz geçirir. Zamanlı takvim atlamaları sinemanın olayında
## yazılır; preload'daki aşamanın dünyası köprü sürerken arka planda yüklenir.
func _stage_cine(serial: int, stage: Dictionary) -> void:
	state = State.CINE
	if menu.visible:
		menu.hide_menu(true)
	cine.speed = cine_speed
	var path := str(stage.get("path", ""))
	_plan_timed_jumps(stage, path)
	_preload_for(stage)
	if _still_curtain:
		cine.fade_rect = _still_curtain
		_still_until = _open_end(path)
	await cine.play(path, 0.0)
	_release_still()
	if serial != _flow_serial:
		return
	state = State.BUSY
	if fade.color.a < 0.999:
		await _fade_to(1.0, 0.35)
	_finish_stage(serial, true)


## Sinemanın baş perdesinin açılışının bittiği an (çizelgenin "open" kimlikli perde olayı; yoksa 1 sn).
static func _open_end(path: String) -> float:
	var ev := CineTimeline.from_path(path).find("open")
	if ev.is_empty():
		return 1.0
	return float(ev.get("end", float(ev.get("t", 0.0)) + float(ev.get("dur", 1.0))))


## Bu aşama sürerken sonraki aşamanın dünyası arka planda yüklenir (new_game.json preload: Köprü 2 → I. Perde'nin Kışlak'ı). Dosya yoksa
## sessizce geçilir: dünya gelince kanca kendiliğinden çalışır; aşamanın oynatıcısı take_preloaded ile alır.
func _preload_for(stage: Dictionary) -> void:
	var target_id := str(stage.get("preload", ""))
	if target_id.is_empty() or _flow == null:
		return
	var path := str(_flow.stage(target_id).get("world", ""))
	if path.is_empty() or _preloads.has(path) or not ResourceLoader.exists(path):
		return
	if ResourceLoader.load_threaded_request(path, "", false) == OK:
		_preloads[path] = true
		if not _dev_args.is_empty():
			print("[yeni oyun] %s'in dünyası arka planda yükleniyor: %s" % [target_id, path])


## Arka planda yüklenen dünyalar (yol listesi; sınama ve günlük).
func preloaded_worlds() -> PackedStringArray:
	return PackedStringArray(_preloads.keys())


## Arka planda yüklenen dünya: yüklendiyse kaynak (yükleme kapanır), sürüyorsa ya da hiç istenmediyse null.
func take_preloaded(path: String) -> Resource:
	if not _preloads.has(path) or ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	_preloads.erase(path)
	return ResourceLoader.load_threaded_get(path)


## Kimsenin almadığı arka plan yüklemeleri bitince alınıp bırakılır (yükleyicide öksüz kalmasın: çıkışta ObjectDB sızıntısı).
func _release_preloads() -> void:
	var paths: Array = _preloads.keys()
	_preloads.clear()
	for path: String in paths:
		_drain_load(path)


func _drain_load(path: String) -> void:
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(path)


# --- Yola Çıkış ------------------------------------------------------------------------------------------

## Oynanan küçük sahne (scene): bugün Yola Çıkış (DepartScene). Başka sahne gelirse burada ayrılır.
func _stage_scene(serial: int, stage: Dictionary) -> void:
	_stage_depart(serial, stage)


## Yola Çıkış: kara perdede tarih kartı, depart_yurt kurulur (kişilerin modelleri arka planda), oluşturulan Mete Yançi'nin yurdunda,
## sahne kişileriyle hazırlanır, perde kalkar; sahne bitince (at batıya yürürken kararır) dünya bırakılır, işaret yazılır.
func _stage_depart(serial: int, stage: Dictionary) -> void:
	state = State.BUSY
	await _cover_title()
	if serial != _flow_serial:
		return
	var data := DepartScene.load_data(str(stage.get("path", DepartScene.SCENE_PATH)))
	var lang := SubtitleBar.ui_lang()
	var date := NewGameFlow.text(stage.get("date", data.get("date")), lang)
	var shown := Time.get_ticks_msec()
	if not date.is_empty():
		cine.card(date, DEPART_CARD_SECONDS)
	_advance_day(int(data.get("day_n", -41)))
	if not await _enter_depart(data):
		push_warning("[main] Yola Çıkış'ın dünyası kurulamadı (%s)" % DEPART_WORLD)
		_finish_stage(serial, false)
		return
	if serial != _flow_serial:
		return
	var scene := DepartScene.new()
	scene.name = "DepartScene"
	scene.data = data
	scene.objective_box = false
	if not depart_actor_root.is_empty():
		scene.actor_root = depart_actor_root
	scene.setup(_depart_world, player, follow_camera, $UI, fade, hud, fade)
	add_child(scene)
	_depart_scene = scene
	scene.finished.connect(_on_depart_finished.bind(serial))
	await scene.prepare()
	if serial != _flow_serial or not is_instance_valid(scene):
		return
	# Görev kartı ve Görevler sayfası: Yola Çıkış sürüyor, «Koyun Sırtında» bitti.
	gameplay_hud.set_quest_source(scene)
	gameplay_hud.finished_quests = _finished_story_quests()
	while (Time.get_ticks_msec() - shown) / 1000.0 < DEPART_CARD_MIN and not date.is_empty():
		await get_tree().process_frame
	scene.begin(depart_step)
	await _fade_to(0.0, 0.9)
	if serial != _flow_serial:
		return
	player.set_active(true)
	state = State.PLAYING
	_start_depart_autoplay(_dev_args)


## Görevler sayfasının bitmiş hikâye görevleri (yolculuğun işaretlerinden; en yenisi önce): «Yola Çıkış», «Koyun Sırtında».
func _finished_story_quests() -> Array:
	var out: Array = []
	var lang := SubtitleBar.ui_lang()
	if journey.has_flag("mq0_depart"):
		var d := DepartScene.load_data()
		out.append(DepartScene.quest_of(d, (d.get("steps", []) as Array).size(), lang))
	if journey.has_flag("mq0_sheep"):
		var data := ChildhoodScene.load_data()
		out.append(ChildhoodScene.quest_of(data, (data.get("steps", []) as Array).size(), lang))
	return out


## Yola Çıkış'ın dünyasını kurar, oluşturulan Mete'yi Yançi'nin yurduna koyar (girdisi kapalı; perde kalkınca açılır). Kurulamazsa false.
func _enter_depart(data: Dictionary) -> bool:
	_request_depart_models(data)
	_depart_world = await _load_depart_world()
	if _depart_world == null:
		_depart_models.clear()
		return false
	# Kişilerin modelleri (CineActor) dünyayla birlikte arka planda gelir; kurulum diske gitmez.
	await _collect_depart_models()
	gameplay_hud.set_quest_source(null)
	gameplay_hud.finished_quests = []
	gameplay_hud.set_world_map(await WorldMap.bake(self, _depart_world.map_spec([player])))
	if _depart_world == null:
		return false
	player.use_profile(profile)
	gameplay_hud.begin_body()
	player.use_map(_depart_world)
	follow_camera.terrain_shape = player.terrain_shape
	follow_camera.transform_filter = Callable(_depart_world, &"clamp_camera_transform")
	_seat_hold = false
	_set_hidden_camp_model("")
	player.spawn_at(_depart_world.marker("mete_start"), player.get_facing_yaw())
	player.visible = true
	follow_camera.target = player
	menu_camera.drifting = false
	# Kadraj kuzeye bakar (K98, 28 m): yurdun beşik yanı kameraya dönüktür, avlu ve Teoman'ın otağı karenin üstündedir.
	follow_camera.set_yaw(0.0, true)
	follow_camera.set_active(true)
	follow_camera.snap_to_target()
	player.set_active(false)
	return true


## Kişilerin kendi modelleri (varsa) arka planda istenir: Yola Çıkış'ın dünyası yüklenirken.
func _request_depart_models(data: Dictionary) -> void:
	_depart_models.clear()
	for id: String in (data.get("actors", {}) as Dictionary):
		var path := StandIn.model_path(id)
		if ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path, "", false) == OK:
			_depart_models[path] = null


func _collect_depart_models() -> void:
	for path: String in _depart_models.keys():
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			_depart_models[path] = ResourceLoader.load_threaded_get(path)


## Dünyayı arka planda yükler ve ekler (Çocukluk'unki gibi: kamp bırakılır); kurulum bitene dek bekler.
func _load_depart_world() -> DepartWorld:
	if ResourceLoader.load_threaded_request(DEPART_WORLD, "", false) != OK:
		push_warning("[main] Yola Çıkış'ın dünyası yüklenemedi: %s" % DEPART_WORLD)
		return null
	while ResourceLoader.load_threaded_get_status(DEPART_WORLD) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(DEPART_WORLD) as PackedScene
	if scene == null:
		push_warning("[main] Yola Çıkış'ın dünyası yüklenemedi: %s" % DEPART_WORLD)
		return null
	cine.release_camp()
	var node := scene.instantiate() as DepartWorld
	add_child(node)
	while not node.is_ready():
		await get_tree().process_frame
	return node


func _on_depart_finished(result: Dictionary, serial: int) -> void:
	if serial != _flow_serial:
		return
	state = State.BUSY
	for f: String in result.get("flags", PackedStringArray()):
		journey.set_flag(f)
	_end_depart()
	_finish_stage(serial, true)


## Yola Çıkış'ın sahnesini ve dünyasını bırakır (perde karayken): oyuncu gizlenir, kamera menüye döner.
func _end_depart() -> void:
	_end_depart_scene()
	player.set_active(false)
	follow_camera.set_active(false)
	hud.hide_hud(false)
	_leave_depart()
	player.visible = false
	menu_camera.make_current()


func _end_depart_scene() -> void:
	var auto := get_node_or_null(^"DepartAutoplay")
	if auto:
		auto.queue_free()
	if _depart_scene:
		_depart_scene.stop()
		_depart_scene.queue_free()
		_depart_scene = null
	gameplay_hud.set_quest_source(null)
	gameplay_hud.finished_quests = []
	pause_menu.save_note = ""
	pause_menu.card_place = ""
	pause_menu.card_note = ""


## Yola Çıkış'ın dünyasından çıkar: binekten iner (dünyanın atı silinir), dünya bırakılır, kamp geri gelir, oyuncunun zemini kampın olur.
func _leave_depart() -> void:
	if _depart_world == null:
		return
	if player.is_riding() or player.riding_node() != null:
		# Atın sırtındaki oyuncu atla birlikte gitmesin: yerine konur (spawn_at duruşu bırakır).
		player.spawn_at(player.global_position, player.get_facing_yaw())
	player.auto_move = Vector2.ZERO
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.use_map(null)
	follow_camera.terrain_shape = world.get_terrain_shape()
	follow_camera.transform_filter = Callable()
	follow_camera.target = player
	remove_child(_depart_world)
	_depart_world.queue_free()
	_depart_world = null
	_depart_models.clear()
	cine.restore_camp()


## --autoplay: Yola Çıkış'ı tuşsuz baştan sona oynar (geliştirme ve pencerede kayıt; bkz. DepartAutoplay).
func _start_depart_autoplay(args: Dictionary) -> void:
	if not args.has("autoplay") or _depart_scene == null or get_node_or_null(^"DepartAutoplay") != null:
		return
	var auto := DepartAutoplay.new()
	auto.name = "DepartAutoplay"
	auto.setup(_depart_scene, player, follow_camera)
	add_child(auto)


## Oluşturucu «Yola Hazırlan»: kara perdeden açılır; onay sıradaki aşamaya, Geri Al açılış ekranına götürür.
## Geliştirme: --accept-creator[=SN] oluşturucuyu SN saniye sonra kendisi onaylar (bütün akışın pencerede kaydı).
func _stage_creator(serial: int) -> void:
	state = State.BUSY
	await _cover_title()
	cine.audio.restore_menu_music()
	await _show_creator()
	if _dev_args.has("accept-creator"):
		var wait := str(_dev_args["accept-creator"])
		await get_tree().create_timer(float(wait) if wait.is_valid_float() else 2.5).timeout
		if serial == _flow_serial and state == State.CREATOR:
			creator.accept()


## Son kart: kara ekranda «I. Perde: Çan» ve «Yapım aşamasında.»; bitince açılış ekranı.
func _stage_card(serial: int, stage: Dictionary) -> void:
	state = State.CINE
	await _cover_title()
	if serial != _flow_serial:
		return
	get_viewport().disable_3d = true
	var lang := SubtitleBar.ui_lang()
	var card := FlowCard.new()
	card.title_text = NewGameFlow.text(stage.get("title"), lang)
	card.line_text = NewGameFlow.text(stage.get("line"), lang)
	card.sfx = str(stage.get("sfx", ""))
	card.hold = flow_card_hold if flow_card_hold >= 0.0 else float(stage.get("hold", card.hold))
	$UI.add_child(card)
	_flow_card = card
	await card.play()
	_flow_card = null
	get_viewport().disable_3d = false
	_finish_stage(serial, true)


## Açılış ekranı görünüyorsa söner, perde kararır (aşama kara perdeden açılır).
func _cover_title() -> void:
	if menu.visible:
		_play_ui(&"whoosh")
		await menu.hide_menu(true)
	if fade.color.a < 0.999:
		await _fade_to(1.0, 0.35)


## Kara perdeden açılış ekranına: menü kamerası menü kadrajında, menü müziği, kamp yerinde; perde kalkar.
func _show_title_from_black() -> void:
	state = State.BUSY
	if fade.color.a < 0.999:
		await _fade_to(1.0, 0.35)
	creator.visible = false
	get_viewport().disable_3d = false
	player.set_active(false)
	player.visible = false
	follow_camera.set_active(false)
	hud.hide_hud(false)
	_set_hidden_camp_model("")
	_reset_menu_view()
	menu.show_menu(true)
	await _fade_to(0.0, 0.6)
	state = State.MENU


# --- Karakter oluşturucu olayları ---------------------------------------------------

## Onay: karakter yolculuğa yazılır (kayıt yok), perde karayken akış sıradaki aşamaya geçer. Oluşturulan Mete kampa inmez (K37, K99).
func _on_creator_accepted(new_profile: CharacterProfile) -> void:
	if state != State.CREATOR:
		return
	state = State.BUSY
	profile = new_profile.copy()
	if _persist_profile:
		profile.save()
	journey.profile = profile.copy()
	await _close_creator(true)
	if _flow:
		_finish_stage(_flow_serial, true)
	else:
		await _show_title_from_black()


## Geri Al: akış bırakılır, açılış ekranı gelir.
func _on_creator_cancelled() -> void:
	if state != State.CREATOR:
		return
	state = State.BUSY
	await _close_creator(true)
	if _flow:
		_finish_stage(_flow_serial, false)
	else:
		await _show_title_from_black()


## Oluşturucuyu kapatır; keep_black ise perde kara kalır (sıradaki aşama karadan açılır).
func _close_creator(keep_black: bool = false) -> void:
	await _fade_to(1.0, 0.3)
	creator.visible = false
	get_viewport().disable_3d = false
	if not keep_black:
		await _fade_to(0.0, 0.35)


# --- Oyun (serbest gezinti) ----------------------------------------------------------

## Oyuncuyu kampta (verilen yerde; yoksa Çocuk ateş başındaki yerinde, yetişkin ateşin önünde) belirtir; takip kamerası o an ekrandaki
## kameradan yumuşakça oyuncunun arkasına geçer.
func _enter_play(at: Vector3 = NO_POSITION, yaw: float = SPAWN_YAW) -> void:
	_dress_player()
	_place_player(at, yaw)
	player.visible = true
	follow_camera.target = player
	menu_camera.drifting = false
	# Takip kamerası açılırken o an ekrandaki kameradan (menü kamerası) kendi kadrajına geçiş yapar.
	follow_camera.set_active(true)
	_begin_roam_time(-1.0)
	_begin_camp_weather(false)
	player.set_active(true)
	_snapshot_unlocks()
	journey.set_flag(JourneyFlags.FIRST_ROAM)
	_visit_journey()
	_start_camp_hud()
	gameplay_hud.bag.spawn_piles()
	if _show_hints():
		hud.show_hints(GameHud.CHILD_HINTS if player.is_child() else GameHud.HINTS)
	await get_tree().create_timer(follow_camera.activation_blend).timeout
	_announce_unlocks()
	state = State.PLAYING


## Esc: duraklatma kitabı açılır (dünya durur); M ve J aynı kitabı HARİTA ya da GÖREVLER sayfasında açar (page). Önce ipuçları ve
## bildirimler gizlenir ve ekranın arayüzsüz bir karesi çekilir: bu kare bir sonraki kaydın küçük resmi olur. Çocukluk'un dünyasında
## KAYDET kapalıdır.
func _on_pause_requested(page: String = "genel") -> void:
	if state != State.PLAYING:
		return
	# «Çocukluğu geç» sunulurken Esc'in kısa basışı duraklatma, basılı tutuluşu atlamadır: bırakılınca ya da süre dolunca karar verilir
	# (_tick_skip_hold). M ve J (başka sayfa) ve tuşsuz istek hemen açar.
	if page == "genel" and ((_childhood_scene and childhood_skip_offered()) or _prologue_days) and Input.is_action_pressed(&"pause"):
		if not _skip_tracking:
			_skip_tracking = true
			_skip_hold = 0.0
		return
	_open_pause(page)


func _open_pause(page: String) -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	gameplay_hud.hide_now()
	player.set_active(false)
	_visit_journey()
	_roam_time.store_into(journey)
	_camp_weather.store_into(journey)
	_camp_life.store_into(journey)
	hud.hide_hud(false)
	_toast.visible = false
	if _childhood_world:
		pause_menu.save_note = CHILDHOOD_SAVE_NOTE
		pause_menu.card_place = CHILDHOOD_PLACE
		pause_menu.card_note = _childhood_note()
	elif _prologue_days:
		var p_lang := SubtitleBar.ui_lang()
		pause_menu.save_note = PROLOGUE_SAVE_NOTE
		pause_menu.card_place = PrologueDays.date_text(_prologue_days.order, _prologue_days.day_index(), p_lang)
		pause_menu.card_note = _prologue_days.text_of(_prologue_days.scene.get("title"))
	elif _depart_world:
		var data: Dictionary = _depart_scene.data if _depart_scene else DepartScene.load_data()
		var lang := SubtitleBar.ui_lang()
		pause_menu.save_note = DEPART_SAVE_NOTE
		pause_menu.card_place = NewGameFlow.text(data.get("place"), lang)
		pause_menu.card_note = "%s  ·  %s" % [NewGameFlow.text(data.get("date"), lang), NewGameFlow.text(data.get("title"), lang)]
	elif _map_world:
		var lang := SubtitleBar.ui_lang()
		pause_menu.save_note = ""
		pause_menu.card_place = _map_world.spec.title_text(lang)
		pause_menu.card_note = NewGameFlow.text(_map_world.spec.subtitle, lang)
	else:
		pause_menu.save_note = ""
		pause_menu.card_place = ""
		pause_menu.card_note = ""
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		journey.pending_thumb = get_viewport().get_texture().get_image()
	_toast.visible = true
	if state == State.PAUSED:
		pause_menu.open(page, false)


## Duraklatma kitabının Çocukluk satırı: tarih ve sahnenin adı.
func _childhood_note() -> String:
	var data: Dictionary = _childhood_scene.data if _childhood_scene else ChildhoodScene.load_data()
	var lang := SubtitleBar.ui_lang()
	return "%s  ·  %s" % [NewGameFlow.text(data.get("date"), lang), NewGameFlow.text(data.get("title"), lang)]


func _on_pause_resumed() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		player.set_active(true)


## "Ana Menü": yolculuk otomatik kayda yazılır (Çocukluk'ta ve Yola Çıkış'ta yazılmaz; iç haritada map bloğuyla yazılır), kamera menü
## kadrajına uçar, açılış ekranı gelir.
func _on_pause_main_menu() -> void:
	if state != State.PAUSED:
		return
	state = State.BUSY
	if _save_allowed():
		journey.save_auto()
	await _return_to_title()


## "Masaüstüne Dön": yolculuk otomatik kayda yazılır (Çocukluk'ta ve Yola Çıkış'ta yazılmaz), sonra oyun kapanır.
func _on_pause_quit() -> void:
	if state != State.PAUSED:
		return
	state = State.BUSY
	if _save_allowed():
		journey.save_auto(&"pagehide")
	await _quit_with_fade()


## Duraklatma kitabından bir kayıt yüklenir: ekran kararır, karakter ve yer kayıttan gelir (Çocukluk'tan yüklenirse akış bırakılır).
func _on_pause_load(slot: int) -> void:
	if state != State.PAUSED:
		return
	state = State.BUSY
	var record := saves.slot_info(slot)
	var undo := journey.to_record(0)
	var loaded := journey.apply_record(record)
	if loaded and not _open_session():
		# Kaydın blokları okunamadı (kısmi yükleme yok): yolculuk ve oturum yüklemeden önceki hâline döner.
		loaded = false
		journey.apply_record(undo)
		_open_session()
	if not loaded:
		_toast.show_text(MainMenu.LOAD_FAILED, "warn")
		state = State.PLAYING
		player.set_active(true)
		return
	profile = journey.profile.copy()
	player.set_active(false)
	await _fade_to(1.0, 0.35)
	if _prologue_days:
		_flow_abort()
		_leave_prologue_days()
	if not flow_stage_of(record).is_empty():
		# Kayıt Yeni Oyun'un kayıt noktasıdır (E21): akış o aşamanın o gününden açılır.
		_leave_childhood()
		_leave_depart()
		await _leave_map()
		_resume_flow(record)
		return
	if _childhood_world:
		_flow_abort()
		_end_childhood_scene()
	if _depart_world:
		_flow_abort()
		_end_depart_scene()
	_leave_childhood()
	_leave_depart()
	# Kayıt iç haritadaysa (map bloğu) oraya, kaydedilen yere inilir (harita değişimi karartma altında); değilse kamp yeniden kurulur.
	if await _enter_saved_map(true):
		return
	await _leave_map()
	_dress_player()
	_place_player(journey.position if Journey.record_has_position(record) else NO_POSITION, journey.yaw if Journey.record_has_position(record) else SPAWN_YAW)
	follow_camera.target = player
	follow_camera.set_active(true)
	follow_camera.snap_to_target()
	_begin_roam_time(0.0)
	_begin_camp_weather(true)
	_snapshot_unlocks()
	_start_camp_hud()
	gameplay_hud.bag.spawn_piles()
	await _fade_to(0.0, 0.45)
	player.set_active(true)
	state = State.PLAYING


## Kamera oyun kamerasının yerinden menü kadrajına geri uçar; açılış ekranı yeniden açılır. Çocukluk'tan ya da Yola Çıkış'tan dönülürse
## Yeni Oyun'un akışı bırakılır (kayıt yazılmaz).
func _return_to_title() -> void:
	_close_session()
	player.set_active(false)
	follow_camera.set_active(false)
	hud.hide_hud()
	if _prologue_days:
		# Önsöz'ün günlerinden (E21): akış bırakılır, perde kararır, kampın Önsöz düzeni kalkar, menü karadan gelir.
		_flow_abort()
		await _fade_to(1.0, 0.35)
		_leave_prologue_days()
		player.visible = false
		_set_hidden_camp_model("")
		_reset_menu_view()
		menu.show_menu(true)
		await _fade_to(0.0, 0.35)
		state = State.MENU
		return
	if _story_world():
		# Hikâyenin küçük dünyasından menüye uçulmaz: perde kararır, kamp geri gelir.
		_flow_abort()
		await _fade_to(1.0, 0.35)
		_end_childhood_scene()
		_end_depart_scene()
		_leave_childhood()
		_leave_depart()
		# İç haritadan: harita bırakılır, kamp karartma altında yeniden kurulur (WorldHost, ≤2 sn).
		await _leave_map()
		player.visible = false
		_set_hidden_camp_model("")
		_reset_menu_view()
		menu.show_menu(true)
		await _fade_to(0.0, 0.35)
		state = State.MENU
		return
	var game_cam := follow_camera.camera
	if game_cam:
		menu_camera.global_transform = game_cam.global_transform
		menu_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		menu_camera.fov = game_cam.fov
	menu_camera.make_current()
	_play_ui(&"whoosh")
	_roam_time.end(1.7)
	_camp_weather.end(1.7)
	_camp_life.end(1.7)
	await menu_camera.return_to_menu(1.7)
	player.visible = false
	_set_hidden_camp_model("")
	menu.show_menu(true)
	state = State.MENU


# --- Oturum (Session; godot.md §3.1, §3.4; Yol Haritası session-core, save-v2) --------------------------------------

## Oturumu kurar (Serbest Gez, deneme haritası, kayıttan yükleme; varsa öncekini bırakır): yolculuğun kayıtlı blokları okunur (map, saat,
## ilerleme, envanter), sinema saati durdurur, oto kayıt istekleri 0. yuvaya yazılır. Serbest Gez ana kamptadır (map_id verilmezse).
## HUD oturumun envanterini ve ilerlemesini okur: heybe Session.inventory'dir, seviye ve XP Session.progression'dan. Döner: kuruldu mu
## (kaydın blokları okunamadıysa false, oturum yoktur).
func _open_session(mode: StringName = &"", map_id: String = "") -> bool:
	_close_session()
	if mode != &"":
		# Bir dünyaya yeni iniş (Serbest Gez: kamp; deneme haritası): önceki oturumun yeri (map bloğu) taşınmaz, saat ve öteki bloklar sürer.
		journey.map = map_id if not map_id.is_empty() else SaveData.DEFAULT_MAP
		journey.blocks.erase("map")
	var s := Session.new()
	s.name = "Session"
	if not s.setup(journey, mode).is_empty():
		s.free()
		return false
	s.bind_cine(cine)
	s.autosave_requested.connect(_on_session_autosave)
	s.map_source = _map_block
	add_child(s)
	session = s
	# Yolculuğun binekleri (Bağ, at staminası, at eşyası; kayıt v2 «mounts», Yol Haritası riding).
	player.bind_mount_stable(s.blocks)
	gameplay_hud.bag.set_inventory(s.inventory)
	gameplay_hud.vitals.bind_progression(s.progression)
	if world_host and world_host.spec:
		s.inventory.set_world(Session.world_rules(world_host.spec))
	if wait_wheel:
		wait_wheel.session = s
	return true


## Oturumu bırakır (menüye dönüş, yeniden yükleme): ağaçtan hemen çıkar, blokların son hâli yolculukta kalır. HUD'un heybesi oturumsuz
## yeni bir envantere döner (kayıtsız sahneler kendi bedenini kurar), seviye ve XP bağı çözülür, kamp havası kendi adımına döner.
func _close_session() -> void:
	if wait_wheel:
		wait_wheel.cancel()
		wait_wheel.session = null
	if session and is_instance_valid(session):
		remove_child(session)
		session.queue_free()
	session = null
	if gameplay_hud:
		gameplay_hud.vitals.bind_progression(null)
		gameplay_hud.bag.set_inventory(Inventory.new())
	if _camp_weather:
		_camp_weather.stepped_by_session = false


## Oturumun oto kayıt isteği (d2/core.md §6.2): hikâyenin küçük dünyalarında (Çocukluk, Yola Çıkış) kayıt yoktur; iç haritada vardır.
func _on_session_autosave(reason: StringName) -> void:
	if _save_allowed():
		journey.save_auto(reason)


## Kayıt v2'nin map bloğu (Session.map_source): şu anki dünyanın kimliği, oyuncunun yeri ve yönü.
func _map_block() -> Dictionary:
	var id := world_host.spec.id if world_host and world_host.spec else journey.map
	var p := player.global_position if player.is_inside_tree() else player.position
	return {"id": id, "pos": [p.x, p.y, p.z], "yaw": player.get_facing_yaw()}


## Kaydın map bloğu iç haritayı gösteriyorsa (deneme haritası) perde karayken oraya geçilir, oyuncu kaydedilen yerde belirir; HUD oturumun
## envanteriyle açılır (yer yığınları dünyaya konur). Döner: haritaya inildi mi (inilmediyse çağıran kampa iner). from_game: duraklatmadan
## yükleme (perde zaten kara, çocukluk ve yola çıkış bırakıldı).
func _enter_saved_map(from_game: bool = false) -> bool:
	var place := session.saved_place() if session else {}
	var spec := MapSpec.find(str(place.get("id", ""))) if not place.is_empty() else null
	if spec == null or spec.is_camp() or spec.scene.is_empty():
		return false
	if not from_game:
		await _fade_to(1.0, 0.3)
	# Kamptan haritaya: Serbest Gez'in ışığı ve havası kimliğe döner (kamp birazdan bırakılır).
	if _roam_time.is_running():
		_roam_time.end(0.0)
	if _camp_weather.is_running():
		_camp_weather.end(0.0)
	if _camp_life.is_running():
		_camp_life.end(0.0)
	if not await _enter_map(spec, "start", {}, null, place):
		# Harita kurulamadı (WorldHost kampı geri kurar): kaydın yeri kampta değildir, oyuncu ateşin önüne iner.
		push_warning("[main] kaydın haritası kurulamadı: %s" % spec.id)
		await world_host.return_to_camp()
		session.set_map(SaveData.DEFAULT_MAP)
		journey.position = spawn_point() if is_instance_valid(world) else Vector3.ZERO
		journey.yaw = SPAWN_YAW
		return false
	_snapshot_unlocks()
	await _fade_to(0.0, 0.45)
	player.set_active(true)
	state = State.PLAYING
	return true


# --- Serbest Gez'in saati (RoamTime; Yol Haritası clock-calendar, roam-calendar, sun-light) ------------------------

func _setup_roam_time() -> void:
	_roam_time = RoamTime.new()
	_roam_time.name = "RoamTime"
	add_child(_roam_time)
	_roam_time.date_card.connect(cine.card)


## Serbest Gez kampta başlar (hikâyenin küçük dünyalarında değil): saat kayıttan ya da 11 Nisan MÖ 209 14:46,2'den; oturum (Session)
## kuruluysa onun saati. fade: eksi calendar.json'un 2,4 sn'si, 0 hemen (perde kapalıyken).
func _begin_roam_time(fade: float) -> void:
	if _story_world():
		return
	var session_clock: GameClock = session.clock if session and is_instance_valid(session) else null
	_roam_time.begin(world, RoamTime.saved_block(journey), fade, session_clock)
	# Geliştirme: --cam-distance=40 (ışık duraklarının ölçüm kareleri, K58: 28 ve 40 m, eğim 38°).
	if _dev_args.has("cam-distance") and str(_dev_args["cam-distance"]).is_valid_float():
		follow_camera.set_start_distance(float(str(_dev_args["cam-distance"])))


# --- Serbest Gez kampının havası (CampWeather; Yol Haritası weather) -------------------------------------------------

func _setup_camp_weather() -> void:
	_camp_weather = CampWeather.new()
	add_child(_camp_weather)


## Hava Serbest Gez'in saatiyle kampta başlar (hikâyenin küçük dünyalarında yok). instant: perde kapalıyken (yükleme) karışım beklenmez.
## Oturum kuruluysa hava onun 3. adımıdır (godot.md §3.1) ve weather bloğunu onun kaydı yazar (kayıt v2).
func _begin_camp_weather(instant: bool) -> void:
	if _story_world():
		return
	_camp_weather.begin(world, _roam_time, player, journey, instant)
	_bind_session_weather()
	_begin_camp_life()


## Kamp havası oturuma bağlanır: blok (CampWeather.register_block) ve adım (weather, kimlik camp_weather); oturum yoksa kendi adımını atar.
func _bind_session_weather() -> void:
	if session == null or not is_instance_valid(session):
		_camp_weather.stepped_by_session = false
		return
	_camp_weather.register_block(session.blocks)
	if session.get_system(&"camp_weather") == null:
		session.add_system(&"weather", _camp_weather.session_step, &"camp_weather")
	_camp_weather.stepped_by_session = true
	if _camp_weather.sim and not _camp_weather.sim.changed.is_connected(_on_weather_changed):
		_camp_weather.sim.changed.connect(_on_weather_changed)


# --- Serbest Gez'in kamp günü (CampLife; Yol Haritası roam-camp-life) ------------------------------------------------

func _setup_camp_life() -> void:
	_camp_life = CampLife.new()
	add_child(_camp_life)
	_camp_life.toast = _toast
	_camp_life.card = cine.card


## camp3 ve ocak halkı Serbest Gez'in saatiyle kampta başlar (havadan sonra: ocak yanana dek sert hava yok, weather.md §6.3). Oturum
## kuruluysa şantiye onun 5. adımıdır («sites») ve sites bloğunu onun kaydı yazar.
func _begin_camp_life() -> void:
	if _story_world() or not is_instance_valid(world):
		return
	_camp_life.begin(world, player, journey, $UI, gameplay_hud, _camp_weather, session if session and is_instance_valid(session) else null)


## Hava sertleşince (fırtına başı, şiddet ≥3; K22) görünür bekleme o dakikada kesilir (time.md §7.3).
func _on_weather_changed(info: Dictionary) -> void:
	if wait_wheel and wait_wheel.is_running() and int(info.get("sev", 0)) >= 3:
		wait_wheel.interrupt("Hava sertleşti." if SubtitleBar.ui_lang() != "en" else "The weather turns.")


# --- Bekle tekeri (WaitWheel; Yol Haritası wait-sleep) ---------------------------------------------------------------

## Teker oturumla açılır (Serbest Gez, deneme haritası, kayıttan yükleme); Yeni Oyun'un küçük dünyalarında açılmaz. Açıkken oyuncu durur.
## Oyuncunun E'si (PlayerController.interaction_source): döşekte «Uyu», ateş başında basılı «Dinlen» (teker), kapta ve yer yığınında
## «Aç» (HUD: Envanter'in aktarma sekmesi).
func _setup_wait_wheel() -> void:
	wait_wheel = WaitWheel.new()
	wait_wheel.name = "WaitWheel"
	add_child(wait_wheel)
	wait_wheel.setup(self, gameplay_hud, player, fade, _toast)
	wait_wheel.live_check = func() -> bool: return state == State.PLAYING and session != null and _save_allowed()
	wait_wheel.spots_source = _world_spots
	wait_wheel.opened.connect(func(_mode: StringName) -> void:
		if state == State.PLAYING:
			player.set_active(false))
	wait_wheel.closed.connect(_on_wait_done)
	wait_wheel.finished.connect(func(_info: Dictionary) -> void: _on_wait_done())
	player.interaction_source = _interaction
	gameplay_hud.spots_source = _world_spots


func _on_wait_done() -> void:
	if state == State.PLAYING and not pause_menu.is_open():
		player.set_active(true)


## Oyuncunun E'sinin dış işi: tekerin yerleri önce (döşek, şantiye, ateş), sonra HUD'un kapları (kap, yer yığını). Yoksa boş.
func _interaction() -> Dictionary:
	if state != State.PLAYING:
		return {}
	# camp3'ün şantiyesi önce (Ustalara Katıl, su, kütük, köz; yalnız yerinde): ateş başında köz «Dinlen»den önce sorulur.
	var d := _camp_life.interaction() if _camp_life and _story_world() == null else {}
	if d.is_empty():
		d = wait_wheel.interaction() if wait_wheel else {}
	if d.is_empty():
		d = gameplay_hud.interaction()
	return d


## Şu anki dünyanın bekleme yerleri (WorldSpots): döşekler, ateşler, şantiyeler ve kaplar.
func _world_spots() -> WorldSpots:
	var current := world_host.current_world() if world_host else null
	return WorldSpots.of(world_host.spec if world_host else null, current)


# --- Yardımcılar --------------------------------------------------------------------

## Kayıt klasörü ve yazma izni: geliştirme / test çalıştırmaları oyuncunun dosyalarına yazmaz
## (--save-dir verilmişse o klasöre yazar).
func _setup_persistence() -> void:
	var raw := OS.get_cmdline_user_args()
	var args := CaptureTool.parse_args(raw)
	# Geliştirme ya da test koşusu (başsız, "--" argümanı ya da betik ana döngüsü: godot -s) oyuncunun kayıtlarına
	# ve ayarlarına yazmaz. Ölçüt GameSettings'inkiyle aynıdır; argümansız, pencereli bir -s deneme betiği de sayılır.
	var dev := _is_dev_run(raw)
	if saves == null:
		if args.has("save-dir") and str(args["save-dir"]) != "true":
			saves = SaveSystem.new(str(args["save-dir"]), true)
		else:
			saves = SaveSystem.new("user://", not dev)
	_persist_profile = not dev
	remember_prologue = not dev
	remember_childhood = not dev
	if settings == null:
		settings = UIKit.settings_node()


## Açılış sözü yalnızca oyuncunun gerçek açılışında oynar: başsız (testler) ve geliştirme argümanlı
## çalıştırmalarda (ekran görüntüleri, --state=...) menü hemen gelir.
func _wants_epigraph() -> bool:
	return show_epigraph and not _is_dev_run(OS.get_cmdline_user_args())


## Bu çalıştırma geliştirme ya da test koşusu mu (GameSettings.is_dev_run ile aynı ölçüt)?
func _is_dev_run(user_args: PackedStringArray) -> bool:
	return SettingsScript.is_dev_run(DisplayServer.get_name() == "headless", user_args, get_tree().get_script() != null)


func _play_epigraph() -> void:
	var epigraph := Epigraph.new()
	epigraph.name = "Epigraph"
	$UI.add_child(epigraph)
	await epigraph.play()


## Sinema konağının bağlamı: kamp dünyası, menü kamerası, perde ve ses.
func _setup_cine() -> void:
	cine.main_node = self
	cine.world = world
	cine.menu_camera = menu_camera
	cine.fade_rect = fade
	cine.audio = CineAudio.new(get_node_or_null(^"/root/AudioManager"))


## Tek dünyanın konağı (WorldHost; godot.md §4.1): kamp Main/World'dür. Dünya değişince başvurular bağlanır: kamp bırakılırken world,
## player.world ve cine.world boşalır (iç haritada kamp yoktur), kamp yeniden kurulunca yenisine bağlanır.
func _setup_world_host() -> void:
	world_host = WorldHost.new()
	world_host.name = "WorldHost"
	add_child(world_host)
	world_host.setup(self, world, cine)
	world_host.world_released.connect(_on_world_released)
	world_host.world_changed.connect(_on_world_changed)


func _on_world_released(old: Node3D) -> void:
	if old == world:
		world = null
		player.world = null
		cine.world = null


func _on_world_changed(node: Node3D, spec: MapSpec) -> void:
	if spec and spec.is_camp():
		world = node as World
		player.world = world
		cine.world = world
		journey.landmarks = JourneyFlags.landmarks_from_world(world)
	# Oturum dünyayı bilir: kayıtta map olur, saatin yeri dünyanındır; envanter dünyanın kuralını alır (kışta balık bozulmaz).
	if spec and session and is_instance_valid(session):
		session.set_map(spec.id)
		session.inventory.set_world(Session.world_rules(spec))


## Oyun içi HUD: perdenin (UI/Fade) altında, oynanırken görünür; ipucu (PlayerPrompt) HUD açıkken şeridin üstüne kalkar.
func _build_gameplay_hud() -> void:
	gameplay_hud = GameplayHud.new()
	gameplay_hud.name = "GameplayHud"
	gameplay_hud.live_check = func() -> bool: return state == State.PLAYING
	gameplay_hud.prompt = _prompt
	gameplay_hud.hints = hud
	gameplay_hud.toast = _toast
	$UI.add_child(gameplay_hud)
	$UI.move_child(gameplay_hud, fade.get_index())
	gameplay_hud.bind(player, follow_camera)
	# Binişin terkisi (Inventory.mount_mods; Yol Haritası riding): yük atın hızını keser, dörtnalı kapatır.
	player.ride_load = func(key: String) -> Dictionary: return gameplay_hud.bag.inventory.mount_mods(key) if gameplay_hud.bag.inventory else {}
	# M ve J yolculuğun kitabını HARİTA ve GÖREVLER sayfasında açar (duraklatma; sayfaların verisi HUD'dandır).
	gameplay_hud.book_requested.connect(_on_pause_requested)
	pause_menu.hud = gameplay_hud
	var cached := WorldMap.cached("camp")
	if cached:
		gameplay_hud.set_world_map(cached)


## Kampın haritası menüde bir kez pişer (oyuncu gizli, kamp görünürken; başsızda yedek). Serbest Gez'e inerken hazır değilse orada pişer.
func _bake_camp_map_later() -> void:
	await get_tree().create_timer(0.6).timeout
	if WorldMap.cached("camp") or not is_instance_valid(world) or not world.visible or player.visible:
		return
	if DisplayServer.get_name() == "headless":
		return
	await WorldMap.bake(self, WorldMap.camp_spec(world, player))


## Serbest Gez'in HUD'u: kampın haritası, «Kampı Dolaş» görevi, bedenin can ve takati; Çocukluk bittiyse Görevler'de «Koyun Sırtında».
func _start_camp_hud() -> void:
	_camp_tour = CampTour.new(journey, world.get_terrain_shape(), JourneyFlags.DEFAULT_FIRE)
	gameplay_hud.set_quest_source(_camp_tour)
	# Kamp sözleri yalnız Çocuk kamptayken ve oyun sürerken (CampVoice; E20/7).
	if _camp_voice == null:
		_camp_voice = CampVoice.new()
		_camp_voice.name = "CampVoice"
		add_child(_camp_voice)
	# Altyazı kendi katmanında çizilir (SubtitleBar): düğüm oyun içi HUD'un altına girer, HUD perdenin hemen altında kalır.
	_camp_voice.begin(player, journey, $UI, gameplay_hud, func() -> bool:
		return state == State.PLAYING and _story_world() == null and player.is_child() and world.visible)
	gameplay_hud.finished_quests = _finished_story_quests()
	# Serbest Gez'in Çocuğu kayıtsız bir bedendir (heybe her inişte baştan; progression.md §2.5, §13.4); yetişkinin heybesi oturumundur.
	gameplay_hud.begin_body(session != null and not player.is_child())
	var map := WorldMap.cached("camp")
	if map:
		gameplay_hud.set_world_map(map)
		return
	# Henüz pişmedi (menüde vakit olmadı): şimdi, oyuncu gizlenerek (iki kare).
	gameplay_hud.set_world_map(WorldMap.bake_fallback(WorldMap.camp_spec(world, player)))
	var baked: WorldMap = await WorldMap.bake(self, WorldMap.camp_spec(world, player), [player])
	if _childhood_world == null and gameplay_hud.quest_source == _camp_tour:
		gameplay_hud.set_world_map(baked)


func _build_pause_menu() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.journey = journey
	pause_menu.settings = settings
	add_child(pause_menu)


func _connect_signals() -> void:
	menu.start_requested.connect(_on_start_requested)
	menu.free_roam_requested.connect(_on_free_roam_requested)
	menu.continue_requested.connect(_on_continue_requested)
	menu.load_requested.connect(_on_load_requested)
	menu.quit_requested.connect(_on_quit_requested)
	creator.accepted.connect(_on_creator_accepted)
	creator.cancelled.connect(_on_creator_cancelled)
	player.pause_requested.connect(_on_pause_requested)
	player.prompt_changed.connect(_prompt.show_pairs)
	pause_menu.resumed.connect(_on_pause_resumed)
	pause_menu.main_menu_requested.connect(_on_pause_main_menu)
	pause_menu.quit_requested.connect(_on_pause_quit)
	pause_menu.load_requested.connect(_on_pause_load)
	if settings and settings.has_signal(&"changed"):
		settings.changed.connect(_apply_settings)


func _reset_to_menu_state() -> void:
	state = State.MENU
	creator.visible = false
	player.set_active(false)
	player.visible = false
	follow_camera.set_active(false)
	hud.hide_hud(false)
	menu_camera.make_current()
	_set_hidden_camp_model("")


## Sahnedeki düğümlere bağlı ayarlar: takip kamerası (yalnızca açık özellikleri) ve boyalı görünüm.
func _apply_settings() -> void:
	if settings == null:
		return
	if settings.has_method(&"apply_to_camera"):
		settings.apply_to_camera(follow_camera)
	if &"painterly" in settings:
		overlay.enabled = bool(settings.painterly)


func _show_hints() -> bool:
	return settings == null or not (&"show_hints" in settings) or bool(settings.show_hints)


## Ateş başındaki karakterlerden bu modeli kullananı gizler ("" = herkes görünür). Kamp yoksa bir şey yapmaz.
func _set_hidden_camp_model(model_id: String) -> void:
	var npcs := _camp_npcs()
	if npcs:
		npcs.set_seat_left(player.is_child() and model_id == CampNpcs.avatar_model_id(npcs.get_node(CampNpcs.CHILD)) if npcs.has_node(CampNpcs.CHILD) else false)
		npcs.set_hidden_model(model_id)


func _camp_npcs() -> CampNpcs:
	# Kamp iç haritadayken bellekte değildir (WorldHost).
	return world.get_node_or_null(^"Camp/CampNpcs") as CampNpcs if is_instance_valid(world) else null


## Bedeni yolculuğa göre giydirir: Serbest Gez'in yolculuğunda Çocuk (K37), yoksa oluşturulan karakter. Oyuncunun modeli ateş başında da oturuyorsa
## oradaki kopyası gizlenir: aynı kişi iki kez görünmesin.
func _dress_player() -> void:
	if journey.has_flag(ROAM_CHILD_FLAG):
		player.use_child(ChildLook.PERSON_CHILD)
	else:
		player.use_profile(profile)
	_set_hidden_camp_model(player.get_avatar().model_id)


## Oyuncuyu yerine koyar: yer verilmişse orada ayakta; verilmemişse Çocuk ateş başındaki yerinde oturur (aynı klip, aynı kare), yetişkin ateşin önünde belirir.
func _place_player(at: Vector3, yaw: float) -> void:
	_seat_hold = false
	if at == NO_POSITION and player.is_child() and _camp_npcs():
		var seat := _camp_npcs().child_seat()
		if not seat.is_empty():
			var xform: Transform3D = seat["transform"]
			player.sit_at(xform, float(seat["clip_time"]))
			_seat_hold = true
			_seat_at = xform.origin
			return
	player.spawn_at(spawn_point() if at == NO_POSITION else at, yaw)


## Destan Kitabı'nda şu an açık kayıtları not eder (sonraki bildirimler yalnızca yenileri söyler).
func _snapshot_unlocks() -> void:
	_unlocked = unlocked_ids(journey.flags)


## Yeni açılan Destan Kitabı kayıtları için küçük bir bildirim gösterir.
func _announce_unlocks() -> void:
	var now := unlocked_ids(journey.flags)
	for id in now:
		if not _unlocked.has(id):
			_toast.show_text("Destan Kitabı'na yazıldı: %s" % now[id])
	_unlocked = now


## İşaretlerle açık olan bütün Destan Kitabı kayıtları: {"bölüm/kimlik": başlık} (saf fonksiyon).
static func unlocked_ids(flags: Dictionary) -> Dictionary:
	var out := {}
	for chapter in DestanKitabi.CHAPTERS:
		for e in DestanKitabi.entries(chapter, flags):
			out["%s/%s" % [chapter, e["id"]]] = str(e["title"])
	return out


func _quit_with_fade() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		audio.fade_out_all(0.9)
	menu.hide_menu(true)
	await _fade_to(1.0, 0.9)
	quit_handler.call()


func _fade_to(alpha: float, duration: float) -> Signal:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", alpha, duration).set_trans(Tween.TRANS_SINE)
	return tween.finished


func _start_audio() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		audio.play_music(&"menu")
		audio.play_ambience()


func _play_ui(kind: StringName) -> void:
	MenuStyle.play_ui(self, kind)


func _quit_game() -> void:
	get_tree().quit()


## Ekran görüntüsü aracı ve geliştirme argümanları (bkz. dosyanın başı).
func _apply_dev_arguments() -> void:
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture:
		capture.pose_requested.connect(func(pos: Vector3, yaw: float, pitch: float) -> void:
			var xform := Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)), pos)
			menu_camera.menu_transform = xform
			menu_camera.global_transform = xform)
		capture.fov_requested.connect(func(fov_deg: float) -> void: menu_camera.design_fov = fov_deg)
		capture.hide_ui_requested.connect(func() -> void: $UI.visible = false)
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	_dev_args = args
	if args.has("flags"):
		for key in str(args["flags"]).split(",", false):
			journey.set_flag(key.strip_edges())
	if args.has("cine-speed") and str(args["cine-speed"]).replace(",", ".").is_valid_float():
		cine_speed = maxf(str(args["cine-speed"]).replace(",", ".").to_float(), 0.05)
	var cine_path := str(args["cine"]) if args.has("cine") and str(args["cine"]) != "true" else ""
	var wanted_state := str(args.get("state", ""))
	if wanted_state.is_empty() and not cine_path.is_empty():
		wanted_state = "prologue"
	if args.has("step") and str(args["step"]) != "true":
		# Adımın kimliği sahnesini seçer: Çocukluk'unkiler (wake, ride, hunt, count) ve Yola Çıkış'ınkiler (yurt, yard, horse) ayrıdır.
		childhood_step = str(args["step"])
		depart_step = str(args["step"])
	if args.has("day") and str(args["day"]) != "true":
		childhood_day = str(args["day"])
	if args.has("hud-screen"):
		_dev_hud_screen(args)
	if args.has("wait-screen"):
		_dev_wait_screen(args)
	match wanted_state:
		"newgame":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			var from := str(args.get("stage", "childhood"))
			if from == "prologue":
				# E21: Önsöz'ün günleri (--day=1..3, --quest=milk|storm|lambs|feast|hearth, --step=<adım>); görülmüş olsa da oynar.
				_force_prologue = true
				prologue_day = int(str(args.get("day", "0"))) if str(args.get("day", "")).is_valid_int() else 0
				prologue_quest = str(args.get("quest", "")) if str(args.get("quest", "true")) != "true" else ""
				prologue_step = str(args["step"]) if args.has("step") and str(args["step"]) != "true" else ""
				if args.has("at"):
					var at_p := str(args["at"]).split(",")
					if at_p.size() >= 2:
						_prologue_dev_at = Vector3(float(at_p[0]), 0.0, float(at_p[1]))
						_prologue_dev_yaw = deg_to_rad(float(at_p[2])) if at_p.size() >= 3 else NAN
				# --day ve --step Önsöz'ündür: akışın sonraki aşamaları baştan açılır.
				childhood_day = ""
				childhood_step = ""
				depart_step = ""
			if state == State.MENU:
				_begin_new_game("childhood" if from == "true" else from)
		"creator":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			if state == State.MENU:
				_begin_new_game("creator")
		"prologue":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			if args.has("skip-prologue"):
				_dev_skip_prologue(args)
			await _dev_prologue(cine_path if not cine_path.is_empty() else prologue_path, args)
		"play":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			await _dev_play(args)
			_start_drive(args)
		"childhood":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			await _dev_childhood(args)
			_start_drive(args)
		"testmap":
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			if args.has("swap-probe"):
				await _dev_swap_probe(args)
				return
			await _dev_testmap(args)
			_start_drive(args)
		"kislak":
			# I. Perde'nin dünyası (act-1-p2; data/maps/kislak/map.json): deneme haritası gibi, oluşturulan Mete Rehine Yurdu'nun kapısında.
			await get_tree().create_timer(0.3).timeout
			menu.finish_intro()
			if args.has("swap-probe"):
				args["swap-map"] = MapSpec.KISLAK
				await _dev_swap_probe(args)
				return
			await _dev_testmap(args, MapSpec.KISLAK)
			_start_drive(args)
		_:
			if args.has("open"):
				await get_tree().create_timer(0.3).timeout
				menu.finish_intro()
				await get_tree().process_frame
				menu.open_dev_page(str(args["open"]))


## --hud-screen=bag|map|journal (--hud-at=SN, varsayılan 2): HUD göründükten SN saniye sonra Envanter'i ya da kitabın sayfasını açar.
func _dev_hud_screen(args: Dictionary) -> void:
	var kind := str(args["hud-screen"])
	var at := str(args.get("hud-at", "2")).replace(",", ".")
	var deadline := Time.get_ticks_msec() + 180000
	while not gameplay_hud.is_shown() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await get_tree().create_timer(float(at) if at.is_valid_float() else 2.0).timeout
	if not gameplay_hud.open_page(kind):
		push_warning("[dev] HUD sayfası açılamadı: %s" % kind)


## --wait-screen=wait|sleep|rest|work (--wait-at=SN, varsayılan 2): HUD göründükten SN saniye sonra Bekle tekerini o kipte açar (true: bağlamın
## kipi); --wait-pick=N tekerin N. satırını (1–6) 0,8 sn sonra seçer. --wait-shot=open|lapse|turn|wake görüntüyü (DevCapture) o ana dek
## bekletir: teker açık, görünür akışın ortası, kara perdede dönen kavis, uyanış.
func _dev_wait_screen(args: Dictionary) -> void:
	var kind := str(args["wait-screen"])
	var at := str(args.get("wait-at", "2")).replace(",", ".")
	var shot := str(args.get("wait-shot", ""))
	var capture := get_node_or_null(^"/root/DevCapture")
	var held := not shot.is_empty() and capture != null and capture.has_method(&"hold_capture")
	if held:
		capture.call(&"hold_capture")
	var deadline := Time.get_ticks_msec() + 180000
	while not gameplay_hud.is_shown() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await get_tree().create_timer(float(at) if at.is_valid_float() else 2.0).timeout
	if not wait_wheel.open(StringName("") if kind == "true" else StringName(kind)):
		push_warning("[dev] Bekle tekeri açılamadı: %s" % kind)
		if held:
			capture.call(&"release_capture")
		return
	await get_tree().create_timer(0.8).timeout
	if shot == "open" or not (args.has("wait-pick") and str(args["wait-pick"]).is_valid_int()):
		if held:
			capture.call(&"release_capture")
		return
	wait_wheel.choose(int(str(args["wait-pick"])) - 1)
	match shot:
		"lapse":
			while wait_wheel.is_running() and session and session.clock.lapse_left() > WaitPlan.LAPSE_SECONDS * 0.45:
				await get_tree().process_frame
		"turn":
			await get_tree().create_timer(WaitPlan.FADE_OUT + WaitPlan.ARC_TURN * 0.55).timeout
		_:
			while wait_wheel.is_running():
				await get_tree().process_frame
			await get_tree().create_timer(0.4).timeout
	if held:
		capture.call(&"release_capture")


## --skip-prologue[=SN]: Önsöz SN (4) saniye sonra oyuncunun yoluyla atlanır: Esc basılı tutulur, halka dolar (pencerede bütün akışın kaydı).
func _dev_skip_prologue(args: Dictionary) -> void:
	var v := str(args.get("skip-prologue", "4")).replace(",", ".")
	var at := float(v) if v.is_valid_float() else 4.0
	var deadline := Time.get_ticks_msec() + 120000
	while not cine.is_playing() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	while cine.is_playing() and cine.time() < at:
		await get_tree().process_frame
	if not cine.is_playing():
		return
	print("[yeni oyun] kare %d · Önsöz basılı Esc'le atlanıyor" % Engine.get_process_frames())
	Input.action_press(&"pause")
	while cine.is_playing() and not cine.is_skipping():
		await get_tree().process_frame
	Input.action_release(&"pause")


## --state=prologue / --cine: diziyi (görülmüş olsa da) oynatır, --cine-at ile oraya ileri sarar; sonra Yeni Oyun'un kalanı.
func _dev_prologue(path: String, args: Dictionary) -> void:
	if state != State.MENU:
		return
	if not FileAccess.file_exists(path):
		push_warning("[dev] sinema dosyası yok: %s" % path)
		return
	_prologue_at = 0.0
	if args.has("cine-at") and str(args["cine-at"]).replace(",", ".").is_valid_float():
		_prologue_at = maxf(str(args["cine-at"]).replace(",", ".").to_float(), 0.0)
	_force_prologue = true
	_prologue_override = path
	_begin_new_game("")


## --state=play: --at ile belli bir yerde belirir; --dev-save ve --pause ile kaydeder / kitabı açar.
func _dev_play(args: Dictionary) -> void:
	if state != State.MENU:
		return
	state = State.BUSY
	await menu.hide_menu(false)
	journey.profile = profile.copy()
	if not args.has("adult"):
		journey.set_flag(ROAM_CHILD_FLAG)
	var at := NO_POSITION
	var yaw := SPAWN_YAW
	if args.has("at"):
		var p := str(args["at"]).split(",")
		if p.size() >= 2:
			at = Vector3(float(p[0]), 0.0, float(p[1]))
			if p.size() >= 3:
				yaw = deg_to_rad(float(p[2]))
	_open_session(Session.MODE_ROAM)
	await _enter_play(at, yaw)
	if args.has("dev-save"):
		await get_tree().create_timer(0.8).timeout
		hud.hide_hud(false)
		_toast.visible = false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if DisplayServer.get_name() != "headless":
			journey.pending_thumb = get_viewport().get_texture().get_image()
		_toast.visible = true
		print("[dev] kayıt yuvası %s: %s" % [args["dev-save"], journey.save_manual(int(args["dev-save"]))])
	if args.has("pause"):
		await get_tree().create_timer(0.5).timeout
		var page := str(args["pause"])
		await _on_pause_requested()
		if page in ["kaydet", "yukle"]:
			await get_tree().process_frame
			var book := pause_menu.get_menu()
			if book:
				book.open_slots("save" if page == "kaydet" else "load")
		elif page != "true" and pause_menu.get_menu():
			pause_menu.get_menu().show_page(page)


## --state=childhood: Ordos dünyasında küçük Mete (K37), sahnesiz kum havuzu: kamp bırakılır, dünya arka planda yüklenir, perde kapalıyken kurulur;
## kapı açık, koyun bineğe hazırdır. --at ile başka yerde belirir.
func _dev_childhood(args: Dictionary) -> void:
	if state != State.MENU:
		return
	state = State.BUSY
	await menu.hide_menu(false)
	await _fade_to(1.0, 0.25)
	if not await _enter_childhood(args):
		# Dünya kurulamadı: yarım bir oyun açılmaz (kampta yetişkinle), açılış ekranına dönülür.
		push_error("[main] --state=childhood: Çocukluk'un dünyası kurulamadı (%s)" % CHILDHOOD_WORLD)
		menu.show_menu(true)
		await _fade_to(0.0, 0.25)
		state = State.MENU
		return
	await _fade_to(0.0, 0.45)
	state = State.PLAYING


## Çocukluk'un dünyasını kurar, küçük Mete'yi ve koyunu koyar. Dünya kurulamazsa false. scene: Yeni Oyun'un Çocukluk'u (kapı kapalı,
## sürü ağılda, ipucunu sahne gösterir); değilse geliştirici kum havuzu (kapı açık, çocuk denetleyicisinin ipucu).
func _enter_childhood(args: Dictionary = {}, scene: bool = false) -> bool:
	_childhood_world = await _load_childhood_world()
	if _childhood_world == null:
		return false
	# Ordos'un haritası perde kapalıyken bir kez pişer (sürü ve av gizli; K63: her kare ikinci bir 3B çizim yok).
	gameplay_hud.set_quest_source(null)
	gameplay_hud.finished_quests = []
	gameplay_hud.set_world_map(await WorldMap.bake(self, WorldMap.ordos_spec(_childhood_world), [player]))
	if _childhood_world == null:
		return false
	player.use_child(ChildLook.PERSON_METE)
	gameplay_hud.begin_body()
	for id in CHILDHOOD_SHEEP:
		var spot := _childhood_marker(id, Vector3.INF)
		if spot != Vector3.INF:
			_spawn_childhood_sheep(id, spot)
	var site: Object = _childhood_world.call(&"childhood") if _childhood_world.has_method(&"childhood") else null
	if site:
		# Kapı açılıp kapanınca oyuncunun kutuları yenilenir (OrdosWorld.collect_boxes: kapalı kapının kanadı).
		if site.has_signal(&"gate_changed"):
			site.connect(&"gate_changed", func(_open: bool) -> void:
				if is_instance_valid(player):
					player.refresh_obstacles())
		if not scene:
			# Geliştirici girişi: ağılın kapısı açık (koyuna gidilebilsin).
			site.call(&"set_gate_open", true, true)
		if site.get(&"game"):
			site.get(&"game").call(&"set_threat", player)
		var avoid: Array[Node3D] = [player]
		avoid.append_array(_childhood_sheep)
		if site.get(&"herd"):
			site.get(&"herd").call(&"set_avoid_nodes", avoid)
	player.use_map(_childhood_world)
	# E21 (K110): çocukta yüzme (Kamışlı Göl): suyun yüzü dünyadan (OrdosWorld.water_at).
	if _childhood_world.has_method(&"water_at") and player.swim == null:
		var swim := ChildSwim.new()
		swim.name = "Swim"
		swim.setup(player, Callable(_childhood_world, &"water_at"))
		swim.world = _childhood_world
		player.add_child(swim)
		player.swim = swim
	follow_camera.terrain_shape = player.terrain_shape
	if _childhood_world.has_method(&"clamp_camera_transform"):
		follow_camera.transform_filter = Callable(_childhood_world, &"clamp_camera_transform")
	var at := _childhood_marker("child_start", Vector3.ZERO)
	var yaw := CHILDHOOD_YAW
	if args.has("at"):
		var p := str(args["at"]).split(",")
		if p.size() >= 2:
			at = Vector3(float(p[0]), 0.0, float(p[1]))
			if p.size() >= 3:
				yaw = deg_to_rad(float(p[2]))
	_seat_hold = false
	_set_hidden_camp_model("")
	player.spawn_at(at, yaw)
	player.visible = true
	follow_camera.target = player
	menu_camera.drifting = false
	follow_camera.set_active(true)
	follow_camera.snap_to_target()
	player.set_active(true)
	if _show_hints() and not scene:
		hud.show_hints(GameHud.CHILD_HINTS)
	return true


## Dünyayı arka planda yükler ve ekler (Önsöz'ün CineHost yolu: load_threaded_request, kamp bırakılır); kurulum bitene dek bekler.
## Alt iş parçacıksız istenir: use_sub_threads (4.7.2) alındıktan sonra da yükleyicide bir RefCounted bırakır (çıkışta ObjectDB sızıntısı).
func _load_childhood_world() -> Node3D:
	if ResourceLoader.load_threaded_request(CHILDHOOD_WORLD, "", false) != OK:
		push_warning("[main] Çocukluk'un dünyası yüklenemedi: %s" % CHILDHOOD_WORLD)
		return null
	while ResourceLoader.load_threaded_get_status(CHILDHOOD_WORLD) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(CHILDHOOD_WORLD) as PackedScene
	if scene == null:
		push_warning("[main] Çocukluk'un dünyası yüklenemedi: %s" % CHILDHOOD_WORLD)
		return null
	cine.release_camp()
	var node := scene.instantiate() as Node3D
	add_child(node)
	if node.has_method(&"set_childhood_mode"):
		node.call(&"set_childhood_mode", true)
	while not _childhood_world_ready(node):
		await get_tree().process_frame
	return node


func _childhood_world_ready(node: Node) -> bool:
	if node.has_method(&"is_ready") and not node.call(&"is_ready"):
		return false
	return not node.has_method(&"is_childhood_ready") or node.call(&"is_childhood_ready")


## Dünyanın işareti (yoksa yedek; zemine oturur).
func _childhood_marker(id: String, fallback: Vector3) -> Vector3:
	var at: Variant = _childhood_world.call(&"marker", id) if _childhood_world.has_method(&"marker") else Vector3.INF
	return at if at is Vector3 and at != Vector3.INF else fallback


func _spawn_childhood_sheep(id: String, at: Vector3) -> void:
	var scene := load(RIDEABLE_SHEEP) as PackedScene
	if scene == null:
		return
	var sheep := scene.instantiate() as RideableSheep
	sheep.name = id.to_pascal_case()
	# Yaşlısı sıcak yünlü, koyu yüzlü; hızlısı sarımsı yüzlü (RideableSheep.seed_value, herd_field.gdshader).
	sheep.seed_value = 0.27 if id == CHILDHOOD_SHEEP[0] else 0.2
	_childhood_world.add_child(sheep)
	sheep.place(at, PI * 0.5 + 0.4 * (1.0 if id == CHILDHOOD_SHEEP[0] else -1.0))
	_childhood_sheep.append(sheep)


## Binilen koyunlar işaret kimlikleriyle: {old_sheep: düğüm, fast_sheep: düğüm}.
func _childhood_sheep_map() -> Dictionary:
	var out := {}
	for sheep in _childhood_sheep:
		if not is_instance_valid(sheep):
			continue
		for id in CHILDHOOD_SHEEP:
			if sheep.name == id.to_pascal_case():
				out[id] = sheep
	return out


## Çocukluk'un dünyasından çıkar: dünya bırakılır, kamp geri gelir, oyuncunun zemini kampın olur.
func _leave_childhood() -> void:
	if _childhood_world == null:
		return
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if player.swim:
		player.swim.dry_now()
		player.swim.queue_free()
		player.swim = null
	player.spawn_at(player.global_position, player.get_facing_yaw())
	player.use_map(null)
	follow_camera.terrain_shape = world.get_terrain_shape()
	follow_camera.transform_filter = Callable()
	follow_camera.target = player
	_childhood_sheep.clear()
	remove_child(_childhood_world)
	_childhood_world.queue_free()
	_childhood_world = null
	cine.restore_camp()


## --drive=yol: çocuğu tuşsuz sürer (geliştirme; bkz. ChildDrive).
func _start_drive(args: Dictionary) -> void:
	# Çocuk (Serbest Gez, Çocukluk) ve iç haritadaki yetişkin Mete sürülür (--state=testmap).
	var drivable := player.is_child() or _map_world != null
	if args.has("drive") and str(args["drive"]) != "true" and state == State.PLAYING and drivable and get_node_or_null(^"ChildDrive") == null:
		var drive := ChildDrive.new()
		drive.name = "ChildDrive"
		drive.setup(player, follow_camera, str(args["drive"]))
		add_child(drive)


## --autoplay: Çocukluk'u tuşsuz baştan sona oynar (geliştirme ve pencerede kayıt; bkz. ChildhoodAutoplay).
func _start_autoplay(args: Dictionary) -> void:
	if not args.has("autoplay") or _childhood_scene == null or get_node_or_null(^"ChildhoodAutoplay") != null:
		return
	var auto := ChildhoodAutoplay.new()
	auto.name = "ChildhoodAutoplay"
	auto.setup(_childhood_scene, player, follow_camera, str(args["autoplay"]) == "mouse")
	add_child(auto)


# --- İç harita (WorldHost; Yol Haritası world-swap, mete-playable) -----------------------------------------

## --state=testmap: deneme iç haritası. Perde kararır, kamp bırakılır, harita arka planda yüklenir ve kurulur (WorldHost.enter_map); oluşturulan
## Mete (profilin görünüşü, Kışlak Kaftanı ve Kışlak Pelerini, profilin boyası; --dye=N) belirme yerinde, perde kalkar. Kurulamazsa açılış ekranı.
## map_id: --state=kislak aynı yolla I. Perde'nin Kışlak'ını açar (saat oturumun hikâye saati: Gün I, 1.041; ışık saatle akar, MapSky).
func _dev_testmap(args: Dictionary, map_id: String = MapSpec.TESTMAP) -> void:
	if state != State.MENU:
		return
	state = State.BUSY
	await menu.hide_menu(false)
	await _fade_to(1.0, 0.25)
	# Haritanın yolculuğu oluşturulan Mete'nin I. Perde deneme yolculuğudur (K37: Çocuk yalnız ana kampta): yeni yolculuk (hikâye kipi,
	# I. Perde), saat haritanın açılışında (Session.MAP_START: 11 Nisan MÖ 209 14:46,2); oturum haritada kurulur, kayıt map bloğuyla yazılır.
	journey.reset(profile)
	journey.act = 1
	if args.has("flags"):
		for key in str(args["flags"]).split(",", false):
			journey.set_flag(key.strip_edges())
	_open_session(Session.MODE_STORY, map_id)
	# Geliştirme: --light=<durak> ya da --clock=HH:MM [--day=N] haritanın saatini koyar (K58'in kar kareleri; MapSky.dev_time).
	var dev_time := MapSky.dev_time(MapSpec.find(map_id).light if MapSpec.find(map_id) else "", args)
	if session and dev_time.x >= 0.0:
		session.clock.day_n = int(dev_time.x)
		session.clock.minute = dev_time.y
	if not await _enter_map(MapSpec.find(map_id), str(args.get("spawn", "start")), args):
		push_error("[main] --state=%s: harita kurulamadı" % map_id)
		_close_session()
		await world_host.return_to_camp()
		_reset_menu_view()
		menu.show_menu(true)
		await _fade_to(0.0, 0.25)
		state = State.MENU
		return
	# Geliştirme: --cam-distance=40 (K58'in kar kareleri: 28 ve 40 m).
	if args.has("cam-distance") and str(args["cam-distance"]).is_valid_float():
		follow_camera.set_start_distance(float(str(args["cam-distance"])))
	await _fade_to(0.0, 0.45)
	state = State.PLAYING


## İç haritaya girer (perde karayken; beklenir): WorldHost haritayı kurar, oyuncu oluşturulan Mete olur (K37: Çocuk yalnız ana kampta), haritanın
## yüzüne bağlanır (zemin, engeller, yürünür alan, kamera kutusu), belirme yerinde durur; HUD'un haritası pişer. Kurulamazsa false.
## preloaded: arka planda önceden yüklenmiş sahne (I. Perde: Köprü 2'nin Kışlak'ı, take_preloaded); verilmezse WorldHost ister.
## place: kayıttan gelen yer (Session.saved_place: {pos, yaw}); verilirse belirme yerinin yerine. Oturum kuruluysa heybe oturumunkidir
## (begin_body sıfırlamaz), yer yığınları dünyaya konur.
func _enter_map(spec: MapSpec, spawn_id: String = "start", args: Dictionary = {}, preloaded: PackedScene = null, place: Dictionary = {}) -> bool:
	if spec == null or world_host == null:
		return false
	_set_hidden_camp_model("")
	var map := await world_host.enter_map(spec, preloaded) as MapWorld
	if map == null:
		return false
	_map_world = map
	_gate_armed = false
	player.use_profile(_map_profile(args))
	gameplay_hud.set_quest_source(null)
	gameplay_hud.finished_quests = []
	# HUD'un haritası perde karayken bir kez pişer (--no-hud-map: geliştirme ölçümü, yedek görüntü).
	if args.has("no-hud-map"):
		gameplay_hud.set_world_map(WorldMap.bake_fallback(map.hud_map_spec()))
	else:
		gameplay_hud.set_world_map(await WorldMap.bake(self, map.hud_map_spec([player])))
	if _map_world != map:
		return false
	gameplay_hud.begin_body(session != null)
	# Haritanın ışığı oturumun saatiyle akar (MapWorld.bind_clock → MapSky; light.json'da altı durak varsa, Kışlak).
	if session and is_instance_valid(session):
		map.bind_clock(session.clock)
	player.use_map(map)
	follow_camera.terrain_shape = player.terrain_shape
	follow_camera.transform_filter = Callable(map, &"clamp_camera_transform")
	_seat_hold = false
	var at := map.spawn(spawn_id)
	if at.is_empty():
		at = map.spawn("start")
	var pos: Vector3 = at.get("at", Vector3.ZERO)
	var yaw: float = at.get("yaw", 0.0)
	if args.has("at"):
		var p := str(args["at"]).split(",")
		if p.size() >= 2:
			pos = Vector3(float(p[0]), 0.0, float(p[1]))
			if p.size() >= 3:
				yaw = deg_to_rad(float(p[2]))
	if place.get("pos") is Vector3 and (place["pos"] as Vector3).is_finite():
		pos = place["pos"]
		yaw = float(place.get("yaw", yaw))
	player.spawn_at(pos, yaw)
	player.visible = true
	follow_camera.target = player
	menu_camera.drifting = false
	# Kadraj oyuncunun arkasından bakar (K98: 38°, 36°, 28 m): belirme yeri kuzeye bakıyorsa kamera da kuzeye.
	follow_camera.set_yaw(yaw - PI, true)
	follow_camera.set_active(true)
	follow_camera.snap_to_target()
	player.set_active(true)
	gameplay_hud.bag.spawn_piles()
	if _show_hints():
		hud.show_hints(GameHud.HINTS)
	return true


## İç haritadaki Mete'nin profili: oluşturulan profil (görünüş, Kışlak Kaftanı ve Kışlak Pelerini; boya profildedir). --dye=N yalnız bu
## koşunun kopyasında boyayı değiştirir (kayda ve oyuncunun profiline yazılmaz).
func _map_profile(args: Dictionary) -> CharacterProfile:
	var p := profile.copy()
	if args.has("dye") and str(args["dye"]).is_valid_int():
		p.cape_dye = int(args["dye"])
	return p


## İç haritadan çıkar (perde karayken; beklenir): binekten iner, sürücü durur, harita bırakılır, kamp pişmiş parçalarıyla yeniden kurulur
## (WorldHost.return_to_camp), oyuncunun zemini kampın olur. Haritada değilse bir şey yapmaz.
func _leave_map() -> void:
	if _map_world == null:
		return
	if player.is_riding() or player.riding_node() != null:
		player.spawn_at(player.global_position, player.get_facing_yaw())
	player.auto_move = Vector2.ZERO
	player.auto_sprint = false
	player.set_active(false)
	var drive := get_node_or_null(^"ChildDrive")
	if drive:
		drive.queue_free()
	follow_camera.set_active(false)
	follow_camera.transform_filter = Callable()
	menu_camera.make_current()
	# Haritanın HUD görüntüsü dünyayla gider (WorldMap.forget); HUD kampınkine döner.
	var camp_map := WorldMap.cached("camp")
	gameplay_hud.set_world_map(camp_map if camp_map else WorldMap.bake_fallback(WorldMap.camp_spec(null, player)))
	_map_world = null
	_gate_armed = false
	await world_host.return_to_camp()
	player.use_map(null)
	follow_camera.terrain_shape = world.get_terrain_shape() if is_instance_valid(world) else null
	follow_camera.target = player


## Kapı: oyuncu kapının alanına girince (bir kez dışına çıktıktan sonra) işler. Kampa açılan kapı açılış ekranına döner (K37: oluşturulan Mete
## ana kampa inmez); kamp perdenin arkasında yeniden kurulur.
func _check_map_gate() -> void:
	if _map_world == null or state != State.PLAYING:
		return
	var gate := _map_world.gate_at(player.global_position)
	if gate.is_empty():
		_gate_armed = true
		return
	if not _gate_armed:
		return
	_gate_armed = false
	if str(gate.get("to", "")) == MapSpec.CAMP:
		state = State.BUSY
		_toast.show_text(GATE_TOAST % NewGameFlow.text(gate.get("name", {}), SubtitleBar.ui_lang()))
		# Dünya değişimi zorunlu oto kayıttır (d2/core.md §6.2 «world»): Devam Et kapıya, kapının alanına döndürür (kapı yeniden kurulmadan işlemez).
		if session and is_instance_valid(session):
			_visit_journey()
			session.request_autosave(&"world")
		await _return_to_title()


## --state=testmap --swap-probe[=N]: kamp → deneme haritası → kamp N kez (2), her değişimin süresi ve belleği yazılır (pencerede gerçek
## çizicinin doku belleği: RENDER_TEXTURE_MEM_USED, Metal'de yalnız bilgi; godot.md §7.4). Sonra açılış ekranı.
func _dev_swap_probe(args: Dictionary) -> void:
	if state != State.MENU:
		return
	var rounds := int(args["swap-probe"]) if str(args["swap-probe"]).is_valid_int() else 2
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture and capture.has_method(&"hold_capture"):
		capture.call(&"hold_capture")
	state = State.BUSY
	await menu.hide_menu(false)
	for i in 30:
		await get_tree().process_frame
	var base := _memory_line("taban (menü, kamp)")
	for r in rounds:
		await _fade_to(1.0, 0.25)
		var t0 := Time.get_ticks_msec()
		# --swap-map=kislak: aynı ölçüm I. Perde'nin Kışlak'ıyla (≤6 sn yükleme, ≤2 sn kampa dönüş; act-1-p2).
		var ok := await _enter_map(MapSpec.find(str(args.get("swap-map", MapSpec.TESTMAP))), "start", args)
		var enter_ms := Time.get_ticks_msec() - t0
		await _fade_to(0.0, 0.3)
		state = State.PLAYING
		for i in 90:
			await get_tree().process_frame
		_memory_line("tur %d: deneme haritası (%s, %d ms)" % [r + 1, "kuruldu" if ok else "KURULAMADI", enter_ms])
		state = State.BUSY
		await _fade_to(1.0, 0.25)
		t0 = Time.get_ticks_msec()
		await _leave_map()
		var back_ms := Time.get_ticks_msec() - t0
		player.visible = false
		_reset_menu_view()
		await _fade_to(0.0, 0.3)
		for i in 90:
			await get_tree().process_frame
		_memory_line("tur %d: kamp (dönüş %d ms; WorldHost %s)" % [r + 1, back_ms, JSON.stringify(world_host.last_swap)])
	var after := _memory_line("son (menü, kamp)")
	print("[world_host] fark (son − taban): 3B dokular %.2f MiB, video %.1f MiB, nesne %d, kaynak %d, düğüm %d" % [
		(after["material"] - base["material"]) / 1048576.0, (after["video"] - base["video"]) / 1048576.0, after["objects"] - base["objects"],
		after["resources"] - base["resources"], after["nodes"] - base["nodes"]])
	menu.show_menu(true)
	state = State.MENU
	if capture and capture.has_method(&"release_capture"):
		capture.call(&"release_capture")


func _memory_line(label: String) -> Dictionary:
	# Sahnedeki 3B malzemelerin dokuları (godot.md §7.4 texture_mib; RENDER_TEXTURE_MEM_USED Metal'de güvenilmez): her doku bir kez.
	var textures := {}
	preload("res://scripts/dev/texture_mem_probe.gd").collect_textures(get_tree().root, textures)
	var material_bytes := 0.0
	for row: Dictionary in textures.values():
		material_bytes += float(row["bytes"])
	var m := {
		"material": material_bytes,
		"material_count": textures.size(),
		"texture": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"video": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"buffer": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
	}
	print("[world_host] %s: 3B dokular %.1f MiB (%d), doku sayacı %.1f MiB, video %.1f MiB, tampon %.1f MiB, nesne %d, kaynak %d, düğüm %d, öksüz %d" % [
		label, m["material"] / 1048576.0, m["material_count"], m["texture"] / 1048576.0, m["video"] / 1048576.0, m["buffer"] / 1048576.0,
		m["objects"], m["resources"], m["nodes"], m["orphans"]])
	return m


# --- Akışın küçük arayüzleri ------------------------------------------------------------------------------

## Köprü 1'in baş perdesi: Çocukluk'un «Beni gördü.»yle donan karesi. CineHost'un perdesinin yerine geçer (UI/Fade'in hemen üstünde):
## color.a ile örter, kara yerine o kareyi çizer; köprünün açılışı (open) onu parşömene çapraz geçirir. black 1 iken karadır (atlanan köprü).
class _StillCurtain:
	extends ColorRect

	const SHADER_CODE := "shader_type canvas_item;\nuniform sampler2D still : filter_linear;\nuniform float black = 0.0;\n" \
		+ "void fragment() {\n\tCOLOR = vec4(mix(texture(still, UV).rgb, vec3(0.0), black), COLOR.a);\n}\n"

	static var _shader: Shader

	var black := 0.0:
		set(value):
			black = clampf(value, 0.0, 1.0)
			if material:
				(material as ShaderMaterial).set_shader_parameter(&"black", black)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		color = Color(0, 0, 0, 1)
		UIKit.full_rect(self)

	## Kare (yoksa kara: başsız çalıştırma).
	func set_still(tex: Texture2D) -> void:
		if _shader == null:
			_shader = Shader.new()
			_shader.code = SHADER_CODE
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		var still := tex
		if still == null:
			var img := Image.create(1, 1, false, Image.FORMAT_RGB8)
			img.fill(Color.BLACK)
			still = ImageTexture.create_from_image(img)
		mat.set_shader_parameter(&"still", still)
		mat.set_shader_parameter(&"black", black)
		material = mat

	func still_texture() -> Texture2D:
		return (material as ShaderMaterial).get_shader_parameter(&"still") if material else null


## «Çocukluğu geç: Esc basılı tut» (K100'ün dili; sağ altta, HUD'un düğmelerinin üstünde): Çocukluk başında birkaç saniye görünür,
## söner; Esc basılıyken yeniden belirir, halka dolar. Fareyi engellemez.
class _SkipOffer:
	extends Control

	const FADE := 0.4
	const SIZE := Vector2(520.0, 56.0)
	const RING_RADIUS := 20.0
	## Sağ alt köşeden pay (1080 satır): HUD'un I, J, M düğmelerinin üstünde.
	const MARGIN := Vector2(56.0, 150.0)

	var text := "":
		set(value):
			text = value
			if _label:
				_label.text = value
	var progress := 0.0

	var _label: Label
	var _tween: Tween
	var _left := 0.0
	var _shown := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchor_left = 1.0
		anchor_right = 1.0
		anchor_top = 1.0
		anchor_bottom = 1.0
		offset_left = -MARGIN.x - SIZE.x
		offset_right = -MARGIN.x
		offset_top = -MARGIN.y - SIZE.y
		offset_bottom = -MARGIN.y
		_label = UIKit.label(text, 22, "Alegreya", 500, UIKit.PARCHMENT)
		_label.name = "Text"
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.anchor_right = 1.0
		_label.anchor_bottom = 1.0
		_label.offset_right = -(RING_RADIUS * 2.0 + 18.0)
		add_child(_label)
		modulate.a = 0.0
		visible = false
		UIKit.on_ui_scale_changed(self, _layout)
		_layout()

	func _layout() -> void:
		UIKit.scale_at_anchor(self, UIKit.ui_k())

	## Teklif seconds saniye görünür.
	func offer(seconds: float) -> void:
		_left = seconds
		_show(true)

	## Basılı Esc'in doluluğu (0..1): görünürken halka dolar; 0 ise teklifin kalan süresi işler.
	func show_progress(p: float) -> void:
		progress = clampf(p, 0.0, 1.0)
		queue_redraw()
		if progress > 0.0:
			_left = maxf(_left, 1.0)
			_show(true)

	## Geri çekilir (Çocukluk bitti, atlandı ya da bırakıldı): hemen gizlenir.
	func retract() -> void:
		_left = 0.0
		progress = 0.0
		_shown = false
		if _tween and _tween.is_valid():
			_tween.kill()
		modulate.a = 0.0
		visible = false

	func is_offering() -> bool:
		return _shown

	func _process(delta: float) -> void:
		if _left > 0.0:
			_left -= delta
			if _left <= 0.0 and progress <= 0.0:
				_show(false)

	func _show(on: bool) -> void:
		if on == _shown:
			return
		_shown = on
		if _tween and _tween.is_valid():
			_tween.kill()
		visible = true
		_tween = create_tween()
		_tween.tween_property(self, ^"modulate:a", 1.0 if on else 0.0, FADE)
		if not on:
			_tween.tween_callback(func() -> void: visible = _shown)

	func _draw() -> void:
		var center := Vector2(size.x - RING_RADIUS - 2.0, size.y * 0.5)
		draw_arc(center, RING_RADIUS, 0.0, TAU, 48, Color(UIKit.PARCHMENT, 0.3), 3.0, true)
		if progress > 0.0:
			draw_arc(center, RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, UIKit.GOLD, 4.0, true)
