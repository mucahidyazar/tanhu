class_name PlayerController
extends Node3D
## Oyuncunun yönettiği karakter (üçüncü şahıs, yüksek açılı kamerayla).
##
## - WASD / oklar kameraya göre yürütür: W her zaman ekranda "yukarı" gider.
## - Yürüme 2.2 m/s, Shift ile koşma 4.6 m/s; hızlanma ve yavaşlama yumuşaktır.
## - Karakter (CharacterAvatar, ön yüzü yerel +Z) hareket yönüne yumuşakça döner ve
##   her karede gerçek hızına göre bekle / yürü / koş animasyonu oynar.
## - Zemini TerrainShape.height_at() ile izler; engel dairelerinden (ateş, kaya...) ve kutulardan (otağdaki yatak,
##   sandık) itilir, otağların keçe duvarından geçemez (yalnızca kapıdan girip çıkar), oyun alanı dairesinin
##   içinde kalır (kenara yaklaşınca yumuşakça fren yapıp durur).
## - Fizik motoru kullanılmaz: hareket saf yardımcı fonksiyonlarla hesaplanır
##   (bkz. tests/unit/test_player_controller.gd). Bu düğümün konumu karakterin ayak noktasıdır.
## - Karakter beklerken arada kıpırdanır (CharacterAvatar.auto_fidget, K91); yürüyünce koşunca hemen kesilir.
##
## - Zıplama (Boşluk; «jump» eylemi, yoksa yalnız jump()): yerden olur, koşarken de. Pozu kütüphanenin zıplama klibidir (regular_jump, Meshy 466): saat klibi evrelere
##   böler (çömelme, havada, iniş); kalçanın yükselişi klipte, düğüm yerde kalır (kamera sarsılmaz). Havada yön az değişir (JUMP_AIR_CONTROL), iniş klibin çömelmesiyle
##   yumuşaktır, hareket varsa iniş biter bitmez yürüyüşe karışır. Yerde nişanda, otururken, biniş ve iniş geçişinde zıplanmaz. Çocukta ve yetişkinde aynıdır.
## - Atla sıçrama (Boşluk sırttayken, 2026-11-08; Rideable.leap, Mount.jump_plan): binek binicisiyle sıçrar (koyun sıçramaz: satırında jump yok). Durarak kısa ve
##   alçak (at toplanır, itip fırlar), tırısta ve dörtnalda ileri doğru uzun (hız korunur). Gövdenin yayı bineğin içindedir (Body kalkar), düğüm ve kamera
##   yerde kalır; binici oturma noktasıyla kalkar ve iner. Havada dönüş azalır (satırın air_turn'ü), hız değişmez; koşarak inince hızın land_keep'i kalır.
##   Sıçrarken inilmez (E bir şey yapmaz, kamerayı da döndürmez); nişan sürer (sıçrayış nişanı bırakmaz, havada ok atılır).
## - Binme (Mount, Rideable; «mounts» grubu): E ile erimdeki bineğe biner, yine E ile iner; yetişkin de çocuk da (satırın riders'ı: koyuna yalnız çocuk). Koyunda koşu tuşu
##   dürter (dörtnal; otlayan binek yeni basışla yürür); atta giriş adım yürütür, koşu tuşu önce tırıs, basılı kalınca dörtnal. Ata biniş: yanına yanaşır, çömelir,
##   üzengisiz sıçrayıp sırtına oturur (mount_style «vault»); iniş yandan sıçrayıp yere konmaktır. Pozu RidePose kurar (bineğin satırıyla). Düğüm binekle gider;
##   binici oturma noktasına oturur, bineğin yeri ve yürüyüşü her adımda burada yazılır. İnilen binek olduğu yerde kalır.
##   Bineğin kaydı (2026-11-08, Yol Haritası riding): Bağ, at staminası ve at eşyası MountStable'dadır (mount_stable; kayıt v2 «mounts», bind_mount_stable),
##   terki ride_load'dan (Inventory.mount_mods) gelir; Mount bunlarla hızı, dönüşü ve staminayı hesaplar. Dörtnalda Shift'e yeniden basmak mahmuzdur
##   (+3 m/sn, at staminası gider; mount_stamina, is_spurring). Binilen bineğin toynakları binicinin zeminine basar (Rideable.set_ground).
## Çocuk kipi (use_child; K37, story.md §5, godot.md §9.4): Serbest Gez'in Çocuğu ve Çocukluk'un küçük Mete'si aynı denetleyicidir, farkları görünüştür (ChildLook). Yürüyüş
## çocuğun kendi kliplerinde, hızlar CHILD_*'tır; üstüne koyuna binme, yay ve toplama gelir:
## - Yay (ChildArcher): sağ tuş basılıyken nişan ve germe; sol tuş ya da sağ tuşu bırakmak atar; yerde durulur, binekte binek yürür.
## - Toplama: vurulan hedef düşer (hit), çocuk E ile alır («fallen_game» grubunda, is_down() ve collect() taşıyan düğüm; SmallGame).
## - Oturuş (sit_at): ateş başında oturan Çocuk ilk harekette kalkar (K37; menü karesi değişmez, ateş başındaki kopyası gizlenir).
## E kameranın da tuşudur (godot.md §5.3: iki atama birlikte durur): E'nin bir işi varken kamera o yöne dönmez. Sağ tuş çocuk kipinde nişandır; kamerayı orta tuşla sürükleme döndürür.
## Yük (move_mods, Inventory.move_mods; economy.md §4.1): yürüme ve koşu × speed_k, koşu ve zıplama yükün iznindedir. Dış E işi
## (interaction_source; main.gd): döşekte «Uyu», ateş başında «Dinlen», kapta «Aç».
## Tuşsuz sürüş ve sınama: step(), interact(), jump(), begin_aim(), release_aim(), archer().aim_override.
## Arayüzün sorguları: get_speed(), is_riding(), riding_node(), mount_kind(), mount_gait(), is_jumping(), is_airborne().

## Oyuncu Esc'ye bastı (duraklatma menüsü açılmalı).
signal pause_requested
## O an yapılabileceklerin ipucu değişti: [[tuş, eylem], ...] (PlayerPrompt gösterir).
signal prompt_changed(pairs: Array)
## Bineğe binildi / inildi (geçiş bittiğinde).
signal mounted(mount_node: Node3D)
signal dismounted(mount_node: Node3D)
## Yerdeki hedef alındı (result: collect()'in döndürdüğü; SmallGame {kind, yield}).
signal target_collected(target: Node, result: Variant)
## Zıplandı (yerden ayrılış anı) ve inildi (ayak yere değdi). Binekte sıçrayınca da: bineğin arka toynakları kalkınca ve ön toynakları yere değince.
signal jumped
signal landed

## Denetleyicinin kipi: yerde; oturuyor, kalkıyor; biniyor, sırtta, iniyor; yerden alıyor; zıplıyor.
enum Stance { FOOT, SEATED, RISING, MOUNTING, RIDING, DISMOUNTING, COLLECTING, JUMPING }
## Zıplamanın evresi: yerde çömelme, havada, iniş.
enum JumpPhase { PREP, AIR, LAND }
## Ata biniş ve inişin evresi (vault): yanaşma, çömelme, sıçrayış, oturma; inişte sırttan atılma, düşüş, yere konma. TAKE (sonradan eklendi:
## eski değerler aynı kalsın diye sonda): yanaşmadan sonra başı çıplak atı yeleden tutma (mount_take_seconds; yular ve gem kaldırır).
enum VaultPhase { APPROACH, CROUCH, LIFT, SETTLE, SWING, DROP, LAND, TAKE }

## Bu hızın altında karakter bekleme animasyonuna geçer (m/s).
const MOVE_EPSILON := 0.05
## Oyun alanı kenarındaki fren yavaşlaması (m/s²) ve kenardan durma payı (metre).
const EDGE_BRAKE := 4.0
const EDGE_STOP_MARGIN := 0.1
## Tek adımın en uzun süresi (saniye): kare takılmalarında (yükleme vb.) karakter ışınlanmasın,
## engellerin içinden geçmesin. 4.6 m/s koşuda adım başına en fazla ~0.46 m.
const MAX_STEP := 0.1
## Çocuğun yürüyüşü (m/s; klibin hız sınırını aşmaz: ayak kaymaz. Çocuk 1,5 ve 3,6, küçük Mete'nin kısa bacağı ≈1,39 ve 3,6), çarpışma yarıçapı (m).
const CHILD_WALK_SPEED := 1.5
const CHILD_RUN_SPEED := 3.6
const CHILD_BODY_RADIUS := 0.28
## Yerde nişan duruşu: kütüphanenin yay klibi (bow_aim; yan duruş, kol hizada, döngüde tutulur). Üstüne BowPose elleri kabzaya ve kirişe koyar,
## göğsü ve başı hedefe çevirir; klip yoksa bekleme klibi altta kalır.
const AIM_CLIP := "bow_aim"
const ROLE_AIM := &"bow_aim"
## Binicinin oturuşu: kalça yüksekliğinin ölçüldüğü klip (yerde bağdaş) ve ölçü yoksa kalçanın sırttan yüksekliği (metre; beş yaş).
const RIDE_SIT_KEY := "sit"
const RIDE_HIPS_LIFT := 0.11
## Binme ve inmede küçük sıçrayış (m), otururken kalkışın klibi ve hızı.
const MOUNT_HOP := 0.2
const RISE_CLIP := "stand_up_7"
const RISE_RATE := 1.5
## Zıplama (godot.md §5): kütüphanenin klibi (regular_jump; Meshy 466, anim_batch_12) ve evreleri (klibin saniyesi): durarak çömelmenin başı, koşarak hazırlığın
## sonu, ayakların yerden kalktığı an, yere değdiği an ve doğrulma. Hazırlık durarak JUMP_PREP_S, koşarak JUMP_RUN_PREP_S sürer (klip o oranda hızlanır), havada klip
## kendi hızıyla oynar (≈0,56 sn), iniş JUMP_LAND_RATE ile; hareket varsa JUMP_MOVE_EXIT'te yürüyüşe karışılır.
const JUMP_CLIP := "regular_jump"
const ROLE_JUMP := &"jump"
const JUMP_START := 0.16
const JUMP_RUN_START := 0.44
const JUMP_TAKEOFF := 0.56
const JUMP_TOUCHDOWN := 1.12
const JUMP_MOVE_EXIT := 1.24
const JUMP_SETTLE := 1.72
const JUMP_PREP_S := 0.2
const JUMP_RUN_PREP_S := 0.08
const JUMP_LAND_RATE := 1.35
## Havada denetim (m/s²; yerde hızlanma 11) ve dönüş keskinliğinin oranı; inişte hızın kalanı.
const JUMP_AIR_CONTROL := 2.5
const JUMP_AIR_TURN := 0.3
const JUMP_LAND_KEEP := 0.88
## Klipsiz (chibi yedeği) zıplama: sekme yüksekliği (m) ve havada kalış (sn).
const HOP_HEIGHT := 0.32
const HOP_AIR_S := 0.5
## Ata biniş (vault): binicinin atın yanında durduğu yer (gövdenin yarı genişliğinin ötesi, oturma noktasının biraz önü; m), sıçrayışın evre süreleri (sn), yayın
## yüksekliği (m) ve binme pozuna geçilen oran; yanaşmanın en uzun süresi (sn).
const VAULT_SIDE := 0.62
const VAULT_FORWARD := 0.12
const VAULT_TURN := 0.55
const VAULT_CROUCH_S := 0.16
const VAULT_LIFT_S := 0.44
const VAULT_SETTLE_S := 0.2
const VAULT_ARC := 0.32
const VAULT_POSE_AT := 0.45
const VAULT_DIP := 0.05
const VAULT_APPROACH_MAX_S := 1.2
## Attan iniş: sırttan atılma, düşüş ve yere konma (sn).
const DROP_SWING_S := 0.26
const DROP_FALL_S := 0.26
const DROP_LAND_S := 0.34
## Atla durarak sıçrayışın toplanmasında ve girişsiz toparlanmasında yavaşlama (m/sn²; toynak yerinde durur, ayak kaymasın).
const LEAP_GATHER_DECEL := 12.0
const LEAP_STOP_DECEL := 30.0
## Yerden almanın klibi, hızı ve erimi (m); yerde duran hedeflerin grubu (SmallGame.FALLEN_GROUP).
const COLLECT_CLIP := "collect_object"
const COLLECT_RATE := 2.2
const COLLECT_REACH := 1.15
const FALLEN_GROUP := &"fallen_game"
## Oynatıcıdaki ek roller.
const ROLE_RISE := &"rise"
const ROLE_COLLECT := &"collect"
## Elin kapanma süresi (saniye) ve yayın, binmenin kapanma oranları.
const HAND_SECONDS := 0.15
const GRIP_BOW := 0.85
const GRIP_STRING := 0.7
const GRIP_WOOL := 0.75

@export_group("Hareket")
## Yürüme hızı (m/s). Mete'nin yürüme klibinin doğal hızı ~1,47 m/s'dir; klip bu hıza göre hızlandırılır,
## 1,8 m/s ayakları kaydırmadan sakin ama ağır olmayan bir yürüyüş verir.
@export var walk_speed := 1.8
@export var run_speed := 4.6
## Hızlanma (m/s²): duruştan yürümeye ~0.2 sn, koşuya ~0.4 sn.
@export var acceleration := 11.0
## Yavaşlama (m/s²): tuş bırakılınca karakter kısa bir kaymayla durur.
@export var deceleration := 14.0
## Dönüş keskinliği: büyüdükçe karakter yeni yöne daha çabuk döner.
@export var turn_sharpness := 11.0
## Karakterin çarpışma yarıçapı (metre).
@export var body_radius := 0.35

@export_group("Oyun alanı")
@export var play_area_center := Vector2.ZERO
@export var play_area_radius := 38.0
## Kenara bu kadar kala dışa doğru fren devreye girebilir (metre).
@export var play_area_soft_edge := 3.0
## Oyun alanına eklenen daireler: Vector3(x, z, yarıçap). Boş değilse alan oyun alanı dairesiyle bunların birleşimidir (E21: Önsöz'ün
## günlerinde kamptan Kayın Obası'na yol, geçit ve oba; PrologueWorld.walk_circles). Boşken alan bugünkü tek dairedir.
var play_area_extra: Array[Vector3] = []
## Dışarıdan gelen sürüklenme (m/sn; E21: tipide rüzgârın itişi): yerdeki her adıma eklenir, çarpışma ve alan sınırından geçer.
var external_drift := Vector3.ZERO
## E21 (K110): çocukta yüzme (ChildSwim; Çocukluk'ta main.gd kurar): suda yavaşlık, koşu, binme, yay ve zıplama yok, derinde E dalış.
var swim: ChildSwim

@export_group("Bağlantılar")
## Arazinin ve engellerin alınacağı dünya. Boşsa sahnede (üst düğümlerde ve kardeşlerde) aranır.
@export var world: World
## Hareket yönünün hesaplandığı kamera: FollowCamera ya da herhangi bir Node3D / Camera3D.
## Boşsa ekrandaki etkin kamera kullanılır.
@export var camera: Node3D
## Dünyanın kaydetmediği ek engeller: Vector3(x, z, yarıçap).
@export var extra_obstacles: Array[Vector3] = []
## Açılışta oyuncu kontrolü açık mı? (Menüdeyken kapalı başlatıp set_active(true) çağırın.)
@export var start_active := true

## Zemin yüksekliği kaynağı: height_at(x, z) taşıyan nesne (TerrainShape, OrdosGround; testlerde doğrudan atanabilir).
var terrain_shape: RefCounted
## Çarpışma daireleri: Vector3(x, z, yarıçap) (testlerde doğrudan atanabilir).
var obstacles: Array[Vector3] = []
## Kapılı dairesel duvarlar (otağlar) ve döndürülmüş kutu engeller (testlerde doğrudan atanabilir).
var walls: Array[RingWall] = []
var boxes: Array[ObstacleBox] = []
## Anlık yatay hız (m/s).
var velocity := Vector3.ZERO
## Senaryolu hareket (ara sahneler, deneme kayıtları): sıfırdan farklıyken gerçek giriş yerine
## bu "basılı tuş" kullanılır; oyuncu kontrolü kapalı olsa bile karakter yürür.
var auto_move := Vector2.ZERO
var auto_sprint := false
## İlk atışa dek yayın ipucu («Sağ tık Nişan») gösterilsin mi? Sahne (Çocukluk) nişan adımına dek kapatır.
var bow_prompt := true
## İşin pozu (toplama ve zanaat; GatherLayer): doluyken ve karakter yerinde dururken bekleme yerine bu rol oynar (klibi avatara
## set_role_clip ile verilir); yürüyünce yürüme klibi döner, işi sürücü keser.
var work_role: StringName = &""
## Yükün yürüyüşe etkisi (Inventory.move_mods; economy.md §4.1; HUD verir): speed_k yürüme ve koşu hızını çarpar (çocukta tek kütük ×0,8),
## can_run false ise koşulmaz, can_jump false ise zıplanmaz. Boşsa yük yok. Binme bineğin kendi yüküdür (Mount).
var move_mods: Dictionary = {}
## Dışarıdan verilen E işi (main.gd: döşek, ateş başı, kap, yer yığını): () -> {key, label, run: Callable} ya da boş. Yerde, nişan ve
## çocuğun yerden alması dışında, binekten önce sorulur; ipucunda da görünür.
var interaction_source: Callable
## Taşınan oturuş (araba; TravelLayer, travel.md §3.4): carry(true) kipi SEATED yapar ama avatarın pozuna ve yerine dokunmaz (taşıyan her kare
## yazar); giriş kalkışı açmaz, E bir şey yapmaz, ipucu boştur. carry(false) kipi FOOT'a döndürür (taşıyan spawn_at ile yere koyar).
var carried := false

var _active := false
var _avatar: CharacterAvatar
## Karakterin şu anki ve hedeflenen bakış açısı (radyan; 0 = +Z yönüne bakar).
var _facing_yaw := 0.0
var _target_yaw := 0.0
var _speed := 0.0
## Çocuk kipinin kişisi ("" = profil, yetişkin) ve kipin düğümleri.
var _person := ""
var _stance: Stance = Stance.FOOT
var _archer: ChildArcher
## Kamp dünyası yerine kullanılan harita (OrdosWorld; engeller yalnız onun altından toplanır).
var _map: Node3D
## Binek: düğüm, saf durum, binicinin kalçası (avatar uzayında), hız (m/s).
var _ride: Rideable
var _mount: Mount
## Yolculuğun binekleri (Bağ, at staminası, at eşyası; MountStable, kayıt v2 «mounts»): oturum bind_mount_stable ile kurar, yoksa ilk binişte kurulur.
var mount_stable: MountStable
## Terkinin binişe etkisi (economy.md §4.7): (bineğin anahtarı) -> Inventory.mount_mods (speed_k, can_gallop); boşsa terki boş sayılır.
var ride_load: Callable
## Binilen bineğin kaydının anahtarı (Rideable.mount_key) ve inildiği an (ms; yeniden binişte aradaki dinlenme).
var _ride_key := ""
var _ride_left_ms := {}
## Binme pozunun kurulduğu binek türü ve türlerin kurulmuş pozları (RidePose; bineğin satırıyla).
var _ride_pose_kind := ""
var _ride_poses := {}
## Zıplama: evre, klibin saati (saniye), koşarak mı, hazırlığın oranı, klip var mı, kişideki zemin payı (m).
var _jump_phase: JumpPhase = JumpPhase.PREP
var _jump_t := 0.0
var _jump_running := false
var _jump_rate := 1.0
var _jump_clip := false
var _jump_lift := 0.0
## Ata biniş ve iniş: evre, evrenin saati (sn) ve süresi, binicinin durduğu yer, yüzü, yanı (+1 sol), evrenin başındaki dönüşüm.
var _vault_phase: VaultPhase = VaultPhase.APPROACH
var _vault_t := 0.0
var _vault_s := 0.0
var _vault_spot := Vector3.ZERO
var _vault_yaw := 0.0
var _vault_side := 1.0
var _vault_from := Transform3D.IDENTITY
var _vault_node_from := Vector3.ZERO
var _hips_offset := Vector3.ZERO
## Nişan duruşunun klibi kuruldu mu?
var _aim_clip := false
## Binicinin kalçası sırtın yününden ne kadar yukarıda (metre): kişinin yerde oturuşundaki kalça yüksekliği (ClipLibrary.hips_height_for).
var _hips_lift := RIDE_HIPS_LIFT
var _ride_speed := 0.0
var _sprint_was := false
## Binekle sıçrayışın son görülen evresi (sinyaller için) ve inişte hızın payı uygulandı mı.
var _leap_seen: Rideable.LeapPhase = Rideable.LeapPhase.NONE
var _leap_kept := false
## Binme ve inme geçişi: saat (0..1), süre, düğümün başı ve sonu.
var _ride_t := 0.0
var _ride_s := 0.5
var _ride_from := Vector3.ZERO
var _ride_to := Vector3.ZERO
## Kalkış ve toplama: saat, süre, toplamanın anı ve hedefi, kalkışın zemin payları (baş, son).
var _clip_t := 0.0
var _clip_s := 0.0
var _collect_at := 0.0
var _collect_target: Node
var _rise_ends := Vector2.ZERO
## Ellerin duruşu ("" serbest).
var _hands := ""
## Son gönderilen ipucu; ilk atışa dek yay ipucu görünür.
var _prompt: Array = []
var _shot_once := false
## Yetişkinin hızları (use_child değiştirir, use_profile geri koyar).
var _adult_walk := 0.0
var _adult_run := 0.0
var _adult_radius := 0.0
## Kamp dünyasının oyun alanı (use_map değiştirir, null geri koyar): [merkez, yarıçap, yumuşak kenar].
var _camp_area: Array = []


func _ready() -> void:
	InputSetup.ensure_actions()
	_ensure_avatar()
	_facing_yaw = _avatar.rotation.y
	_target_yaw = _facing_yaw
	if world == null:
		world = find_world(self)
	if terrain_shape == null:
		terrain_shape = world.get_terrain_shape() if world else TerrainShape.new()
	global_position.y = _ground_height(Vector2(global_position.x, global_position.z))
	set_active(start_active)
	if not is_child():
		_prepare_jump_clip()
		ClipVariety.release_sources()
	# Engeller kendi _ready'lerinde gruplarına katılır; hepsi hazır olunca topla.
	refresh_obstacles.call_deferred()


func _process(delta: float) -> void:
	_refresh_camera_keys()
	if auto_move != Vector2.ZERO:
		step(delta, auto_move.limit_length(1.0), auto_sprint, camera_yaw())
		return
	var input := InputSetup.move_vector() if _active else Vector2.ZERO
	var sprint := auto_sprint or (_active and Input.is_action_pressed(&"sprint"))
	step(delta, input, sprint, camera_yaw())


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"pause"):
		pause_requested.emit()
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	# Zıplama eylemi arayüzün tuş kaydındadır (InputSetup); kaydedilmemişse yok sayılır.
	if InputMap.has_action(&"jump") and event.is_action_pressed(&"jump"):
		if jump() and is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"accept"):
		if interact() and is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	if not is_child():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
		if (event as InputEventMouseButton).pressed:
			begin_aim()
		else:
			release_aim()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed and is_aiming():
		# Sol tuş oku bırakır (sağ tuş basılı nişan; sağ tuşu bırakmak da atar).
		release_aim()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


## Oyuncu kontrolünü açar/kapatır. Kapalıyken giriş okunmaz ve karakter hemen bekleme pozuna geçer.
func set_active(active: bool) -> void:
	_active = active
	if not active:
		velocity = Vector3.ZERO
		_speed = 0.0
		_ride_speed = 0.0
		if _archer:
			_archer.cancel()
		if _avatar and _stance == Stance.FOOT:
			_avatar.set_locomotion(0.0)
		_send_prompt([])


func is_active() -> bool:
	return _active


## Oyuncuyu verilen yere koyar (yükseklik zeminden alınır) ve karakteri yaw açısına çevirir. Binekteyse ya da oturuyorsa önce yerine döner.
## yaw: karakterin ön yüzünün (yerel +Z) açısı, radyan. 0 = +Z'ye, PI = -Z'ye (kampa) bakar.
func spawn_at(pos: Vector3, yaw: float) -> void:
	_ensure_avatar()
	velocity = Vector3.ZERO
	_speed = 0.0
	_leave_stance()
	var p := resolve_circles(Vector2(pos.x, pos.z), obstacles, body_radius)
	p = resolve_boxes(p, boxes, body_radius)
	p = resolve_walls(p, p, walls, body_radius)
	p = _clamp_area(p)
	var target := Vector3(p.x, _ground_height(p), p.y)
	if is_inside_tree():
		global_position = target
	else:
		position = target
	_facing_yaw = yaw
	_target_yaw = yaw
	_avatar.rotation.y = yaw
	_avatar.set_locomotion(0.0)


## Oyuncunun karakteri (yoksa oluşturulur).
func get_avatar() -> CharacterAvatar:
	_ensure_avatar()
	return _avatar


## Karakterin baktığı açı (radyan; 0 = +Z).
func get_facing_yaw() -> float:
	return _facing_yaw


## Karakterin baktığı yön (yatay birim).
func forward_vector() -> Vector3:
	return Vector3(sin(_facing_yaw), 0.0, cos(_facing_yaw))


## Son karedeki gerçek yatay hız (m/s); animasyon da bu hızla seçilir.
func get_speed() -> float:
	return _speed


## Dünyadaki engelleri (World.collect_obstacles / collect_walls / collect_boxes) yeniden toplar. Dünya yoksa elle
## atanan engellere dokunmaz (testler için).
func refresh_obstacles() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_map):
		if _map.has_method(&"collect_obstacles"):
			obstacles.assign(_map.call(&"collect_obstacles"))
			obstacles.append_array(extra_obstacles)
			walls.assign(_map.call(&"collect_walls"))
			boxes.assign(_map.call(&"collect_boxes"))
		return
	if world == null:
		return
	var circles := world.collect_obstacles()
	circles.append_array(extra_obstacles)
	obstacles = circles
	walls = world.collect_walls()
	boxes = world.collect_boxes()


## Kamp dünyası yerine bir iç harita (OrdosWorld; aynı yüz: get_terrain_shape, collect_obstacles, collect_walls, collect_boxes, play_area). null kamp dünyasına döner.
func use_map(map: Node3D) -> void:
	if map and _map == null:
		_camp_area = [play_area_center, play_area_radius, play_area_soft_edge, play_area_extra.duplicate()]
	_map = map
	if map:
		if map.has_method(&"get_terrain_shape"):
			terrain_shape = map.call(&"get_terrain_shape")
		if map.has_method(&"play_area"):
			var area: Dictionary = map.call(&"play_area")
			play_area_center = area["center"]
			play_area_radius = area["radius"]
			play_area_soft_edge = area["soft_edge"]
			# E21: haritanın ek daireleri (Ordos: göle ve Ebe Obası'na giden koridorlar, gölün ve obanın daireleri).
			play_area_extra.assign(area.get("extra", []))
	else:
		if world:
			terrain_shape = world.get_terrain_shape()
		if not _camp_area.is_empty():
			play_area_center = _camp_area[0]
			play_area_radius = _camp_area[1]
			play_area_soft_edge = _camp_area[2]
			play_area_extra.assign(_camp_area[3] if _camp_area.size() > 3 else [])
	if _archer:
		_archer.set_ground(_ground_at)
	refresh_obstacles()


# --- Çocuk kipi -------------------------------------------------------------------------------------

## Çocuk denetleyicisi: kişiyi gösterir (ChildLook: child, mete_child), hızlar çocuğundur, yay ve binme açılır. Tekrar çağrı aynı kişide iş yapmaz.
func use_child(person_id: String = ChildLook.PERSON_CHILD) -> void:
	_ensure_avatar()
	if _person == person_id:
		return
	_leave_stance()
	if _person.is_empty():
		_remember_adult()
	_person = person_id
	body_radius = CHILD_BODY_RADIUS
	var look := ChildLook.resolve(person_id)
	var allocator := ClipVariety.Allocator.new()
	allocator.assign(person_id, ClipVariety.GROUND_GROUP, CampNpcs.SEATS["Child"])
	_avatar.pinned_roles = CharacterAvatar.PLAYER_PINNED
	_avatar.variety_person = person_id
	_avatar.variety_allocator = allocator
	_avatar.model_override = look["model"]
	ChildLook.apply(_avatar, look)
	walk_speed = minf(CHILD_WALK_SPEED, _avatar.clip_speed(&"walk") * CharacterAvatar.WALK_RATE_RANGE.y)
	run_speed = minf(CHILD_RUN_SPEED, _avatar.clip_speed(&"run") * CharacterAvatar.RUN_RATE_RANGE.y)
	_avatar.warm_variety([&"idle", &"sit"])
	_prepare_child_clips()
	if _archer == null:
		_archer = ChildArcher.new()
		_archer.name = "Archer"
		_archer.controller = self
		add_child(_archer)
		_archer.set_ground(_ground_at)
		_archer.loosed.connect(_on_loosed)
	_archer.attach_pose(_avatar.get_skeleton(), _avatar.model_scale)
	_archer.stance_clip = _aim_clip
	if camera is FollowCamera:
		(camera as FollowCamera).right_drag = false
		(camera as FollowCamera).set_start_distance(FollowCamera.CHILD_DISTANCE)
	ClipVariety.release_sources()
	_shot_once = false


## Profil (oluşturulan yetişkin): çocuk kipi kapanır, hızlar yerine döner.
func use_profile(profile: CharacterProfile) -> void:
	_ensure_avatar()
	if not _person.is_empty():
		_leave_stance()
		_person = ""
		walk_speed = _adult_walk
		run_speed = _adult_run
		body_radius = _adult_radius
		if is_instance_valid(_archer):
			_archer.cancel()
			if is_instance_valid(_archer.pose):
				_archer.pose.get_parent().remove_child(_archer.pose)
				_archer.pose.queue_free()
			remove_child(_archer)
			_archer.queue_free()
		_archer = null
		_avatar.pinned_roles = []
		_avatar.variety_person = ""
		_avatar.variety_allocator = null
		_avatar.model_scale = 1.0
		_avatar.model_override = ""
		if camera is FollowCamera:
			(camera as FollowCamera).right_drag = true
			(camera as FollowCamera).hold_turn_right = false
			(camera as FollowCamera).set_start_distance(FollowCamera.DEFAULT_DISTANCE)
	_avatar.apply_profile(profile)
	# Yetişkinin klipleri: zıplama; binme pozu ilk binişte bineğin türüyle kurulur (model değişince yeniden).
	_ride_poses.clear()
	_ride_pose_kind = ""
	# Pelerinin iskeleti (RideCape; K58 M5–M8): örtü uyluktan ayrılır, sürüşte sağrıya serilir.
	RideCape.install(_avatar, self)
	_prepare_jump_clip()
	ClipVariety.release_sources()
	_send_prompt([])


## Çocuk kipinde mi?
func is_child() -> bool:
	return not _person.is_empty()


## Çocuk kipinin kişisi ("" = yetişkin).
func person_id() -> String:
	return _person


## Kip (Stance).
func get_stance() -> Stance:
	return _stance


## Yayın yöneticisi (çocuk kipinde).
func archer() -> ChildArcher:
	return _archer


func is_seated() -> bool:
	return _stance == Stance.SEATED or _stance == Stance.RISING


func is_riding() -> bool:
	return _stance == Stance.RIDING


## Binilen düğüm (biniş ve iniş geçişinde de; yoksa null).
func riding_node() -> Rideable:
	return _ride


## Binilen bineğin türü (Mount satırı: sheep, horse; binilmiyorsa "").
func mount_kind() -> String:
	return _ride.mount_kind() if _ride else ""


## Bineğin yürüyüşü (stand, walk, trot, gallop, graze; binilmiyorsa "").
func mount_gait() -> String:
	return _mount.gait_name() if _mount and _stance == Stance.RIDING else ""


## Zıplıyor mu (çömelmeden doğrulmaya dek; binekte bineğin sıçrayışı boyunca)?
func is_jumping() -> bool:
	return _stance == Stance.JUMPING or (_stance == Stance.RIDING and _ride != null and _ride.is_leaping())


## Havada mı (ayaklar yerden kalkık; binekte bineğin dört toynağı)?
func is_airborne() -> bool:
	if _stance == Stance.RIDING and _ride:
		return _ride.is_airborne()
	return _stance == Stance.JUMPING and _jump_phase == JumpPhase.AIR


## Binicinin yerden yüksekliği (m; yay yedeği için).
func rider_height() -> float:
	return _avatar.position.y if _avatar and _stance != Stance.FOOT else 0.0


## Çocuğu oturur: yer ve yön verilir, oturuş klibi (ateş başındakiyle aynı) oynar. İlk harekette kalkar. clip_time: klibin anı (ateş başındaki kopyayla aynı kare için).
func sit_at(at: Transform3D, clip_time: float = -1.0) -> void:
	_ensure_avatar()
	_leave_stance()
	_stance = Stance.SEATED
	velocity = Vector3.ZERO
	_speed = 0.0
	if is_inside_tree():
		global_position = at.origin
	else:
		position = at.origin
	var yaw := at.basis.get_euler().y
	_facing_yaw = yaw
	_target_yaw = yaw
	_avatar.rotation.y = yaw
	_avatar.play_pose(&"sit")
	_avatar.snap_transition()
	var anim := _avatar.get_animation_player()
	if anim and clip_time >= 0.0:
		anim.seek(clip_time, true)


## Taşınan oturuşa girer ya da çıkar (bkz. carried). Girerken yerdeki kipten çıkılır (yay, binek); pozu ve yeri taşıyan kurar (BenchPose).
func carry(on: bool) -> void:
	_ensure_avatar()
	if on:
		if _stance != Stance.FOOT:
			_leave_stance()
		_stance = Stance.SEATED
		carried = true
		velocity = Vector3.ZERO
		_speed = 0.0
		return
	carried = false
	if _stance == Stance.SEATED:
		_stance = Stance.FOOT


## E: yerden alır (çocuk), bineğe biner ya da iner. Bir iş yaptıysa true. Oturuyorsa kalkar.
func interact() -> bool:
	match _stance:
		Stance.RIDING:
			# Binek sıçrarken (toplanma, hava, iniş) inilmez.
			if _ride and _ride.is_leaping():
				return false
			begin_dismount()
			return true
		Stance.SEATED:
			if carried:
				return false
			_begin_rise()
			return true
		Stance.FOOT:
			if is_aiming():
				return false
			# E21: derinde E dalıştır.
			if swim and swim.can_dive():
				return swim.dive()
			if is_child():
				var fallen := pickup_in_reach()
				if fallen:
					_begin_collect(fallen)
					return true
			var extra := external_interaction()
			if not extra.is_empty():
				(extra["run"] as Callable).call()
				return true
			var ride := mount_in_reach()
			if ride:
				begin_mount(ride)
				return true
	return false


## E'nin şu an bir işi var mı (varsa kamera E ile dönmez)?
func has_interaction() -> bool:
	match _stance:
		Stance.RIDING, Stance.SEATED:
			return true
		Stance.FOOT:
			return (is_child() and pickup_in_reach() != null) or not external_interaction().is_empty() or mount_in_reach() != null or (swim != null and swim.can_dive())
	return false


## Dışarıdan verilen E işi (interaction_source; geçerli bir run taşımıyorsa boş).
func external_interaction() -> Dictionary:
	if not interaction_source.is_valid():
		return {}
	var d: Variant = interaction_source.call()
	if not d is Dictionary or not (d as Dictionary).get("run") is Callable or not ((d as Dictionary)["run"] as Callable).is_valid():
		return {}
	return d


## Erimdeki en yakın binek (yoksa null): binilmeyen, görünen (gizli dünyanınki sayılmaz: Çocukluk'ta kamp ağaçta kalır, gizlidir), satırı bu
## biniciye izin veren (koyun yalnız çocuğa). Erim bineğin satırındandır, uzaklık gövdenin yanına (at uzun: başından ya da sağrısından da
## yaklaşılır, ölçü gövde çizgisine en yakın noktadır).
func mount_in_reach() -> Rideable:
	if not is_inside_tree():
		return null
	if swim and swim.blocks_mount():
		return null
	var at := _flat_position()
	var best: Rideable = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(Rideable.GROUP):
		var ride := node as Rideable
		if not _mount_present(ride) or ride.ridden or not ride.get_mount().allows_rider(is_child()):
			continue
		var d := PlayerController.distance_to_body(at, ride)
		if d <= ride.get_mount().value("reach") and d < best_d:
			best = ride
			best_d = d
	return best


## Bineğin gövde çizgisine yatay uzaklık (m; saf): kısa bineklerde merkezine, uzunlarda (half_length) burun-sağrı doğrusuna.
static func distance_to_body(at: Vector2, ride: Rideable) -> float:
	var center := Vector2(ride.global_position.x, ride.global_position.z) if ride.is_inside_tree() else Vector2(ride.position.x, ride.position.z)
	var half := ride.get_mount().value("half_length") if ride.get_mount() else 0.0
	if half <= 0.0:
		return at.distance_to(center)
	var yaw := ride.global_rotation.y if ride.is_inside_tree() else ride.rotation.y
	var fwd := Vector2(sin(yaw), cos(yaw))
	var along := clampf((at - center).dot(fwd), -half, half)
	return at.distance_to(center + fwd * along)


## Erimdeki en yakın yerdeki hedef (düşmüş, collect taşıyan; yoksa null).
func pickup_in_reach() -> Node3D:
	if not is_inside_tree():
		return null
	var at := _flat_position()
	var best: Node3D = null
	var best_d := COLLECT_REACH
	for node in get_tree().get_nodes_in_group(FALLEN_GROUP):
		if not node is Node3D or not node.has_method(&"collect") or not ArrowField.is_target_down(node):
			continue
		var d := at.distance_to(Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z))
		if d <= best_d:
			best = node
			best_d = d
	return best


## Bineğe biner (geçiş). Koyunda (hop) düğüm bineğin yerine kayar, binici küçük bir sıçrayışla oturma noktasına süzülür. Atta (vault) binici bineğin yakın
## yanına yanaşır, çömelir, üzengisiz sıçrayıp sırtına oturur (zıplama klibinin havası binme pozuna karışır).
func begin_mount(ride: Rideable) -> void:
	if _stance != Stance.FOOT or ride == null:
		return
	if _archer:
		_archer.cancel()
	_ride = ride
	_mount = ride.get_mount()
	_mount.start_ride()
	_open_ride_entry(ride)
	_ensure_seat_sync()
	_ride_ground_y = NAN
	ride.set_ridden(true)
	_ride_speed = 0.0
	_stance = Stance.MOUNTING
	_ride_t = 0.0
	_ride_s = maxf(_mount.value("mount_s"), 0.01)
	_ride_from = global_position if is_inside_tree() else position
	_ride_to = ride.global_position
	velocity = Vector3.ZERO
	_speed = 0.0
	_sprint_was = false
	_leap_seen = Rideable.LeapPhase.NONE
	_prepare_ride_pose(_mount)
	if _mount.mount_style() == "vault":
		_begin_vault()
		return
	_set_hands("ride")
	_avatar.play_pose(RidePose.ROLE)
	_refresh_ride_offset()


## İner (geçiş): bineğin sol yanına (kapalıysa sağına, arkasına) iner. Attan sırttan yana atılıp yere konar. Binek sıçrarken inilmez.
func begin_dismount() -> void:
	if _stance != Stance.RIDING or (_ride and _ride.is_leaping()):
		return
	if _archer:
		_archer.cancel()
	_stance = Stance.DISMOUNTING
	_ride_t = 0.0
	_ride_s = maxf(_mount.value("dismount_s"), 0.01)
	_ride_from = global_position
	var spot := Mount.dismount_spot(_flat_position(), _facing_yaw, _mount.value("dismount_side"), _spot_blocked)
	_ride_to = Vector3(spot.x, _ground_height(spot), spot.y)
	_ride_speed = 0.0
	velocity = Vector3.ZERO
	_speed = 0.0
	_mount.end_ride()
	if _mount.mount_style() == "vault":
		_begin_vault_down()
		return
	_set_hands("")
	_avatar.set_locomotion(0.0)


## Germeye başlar (sağ tuş). Yerde ya da binekte; değilse false.
func begin_aim() -> bool:
	if not is_child() or _archer == null or (_stance != Stance.FOOT and _stance != Stance.RIDING) or (swim and swim.blocks_bow()):
		return false
	if not _archer.begin():
		return false
	_avatar.set_process(false)
	if _stance == Stance.FOOT and _aim_clip:
		# Yan duruşa geçer (süren ara hareket de kesilir).
		_avatar.play_pose(ROLE_AIM)
	elif _stance == Stance.FOOT and not _avatar.fidget_key().is_empty():
		# Süren ara hareket kesilir: el yayı tutarken gerinmez.
		_avatar.set_locomotion(1.0)
		_avatar.set_locomotion(0.0)
	return true


## Bırakır (sağ tuş bırakıldı): min_draw dolunca ok çıkar.
func release_aim() -> void:
	if _archer:
		_archer.release()


func is_aiming() -> bool:
	return _archer != null and _archer.is_drawing()


## Yayın ağırlığına göre eller (ChildArcher her adım çağırır).
func apply_bow_hands(amount: float) -> void:
	if amount > 0.4:
		_set_hands("bow")
	elif _hands == "bow":
		_set_hands("ride" if _stance == Stance.RIDING else "")
	# Yay indi: ara hareketler sürer (el yay yukarı çıkmadan bırakılsa da).
	if amount <= 0.0 and _avatar and not _avatar.is_processing():
		_avatar.set_process(true)


## Bir hareket adımı: giriş → hız → konum → çarpışma → alan sınırı → zemin → yön → animasyon.
## Gerçek girişten bağımsızdır; testler doğrudan çağırır.
## input: x = sağ(+)/sol(-), y = ileri(+)/geri(-); camera_yaw: kameranın yatay açısı (radyan).
func step(delta: float, input: Vector2, sprint: bool, p_camera_yaw: float) -> void:
	if delta <= 0.0:
		return
	delta = minf(delta, MAX_STEP)
	_ensure_avatar()
	match _stance:
		Stance.SEATED:
			if input.length_squared() > 0.0001 and not carried:
				_begin_rise()
			_refresh_prompt()
			return
		Stance.JUMPING:
			_jump_step(delta, input, sprint, p_camera_yaw)
			if _archer:
				_archer.tick(delta)
			_refresh_prompt()
			return
		Stance.RISING:
			_tick_rise(delta)
			_refresh_prompt()
			return
		Stance.MOUNTING, Stance.DISMOUNTING:
			_tick_ride_change(delta)
			_refresh_prompt()
			return
		Stance.RIDING:
			_ride_step(delta, input, sprint, p_camera_yaw)
			if _archer:
				_archer.tick(delta)
			_refresh_prompt()
			return
		Stance.COLLECTING:
			_tick_collect(delta)
			_refresh_prompt()
			return
	var aiming := is_aiming()
	if aiming:
		input = Vector2.ZERO
		sprint = false
	if sprint and not bool(move_mods.get("can_run", true)):
		sprint = false
	if swim and swim.blocks_run():
		sprint = false
	var dir := camera_relative_direction(input, p_camera_yaw)
	var target_velocity := dir * (run_speed if sprint else walk_speed) * load_speed_k() * (swim.speed_k() if swim else 1.0)
	var rate := acceleration if target_velocity.length() >= velocity.length() else deceleration
	velocity = approach_velocity(velocity, target_velocity, rate, delta)
	_slide_on_foot(delta)
	if aiming:
		_target_yaw = _archer.body_yaw()
	elif dir.length_squared() > 0.0001:
		_target_yaw = atan2(dir.x, dir.z)
	_facing_yaw = lerp_angle(_facing_yaw, _target_yaw, 1.0 - exp(-turn_sharpness * delta))
	_avatar.rotation.y = _facing_yaw
	if aiming and _aim_clip:
		_avatar.play_pose(ROLE_AIM)
	elif work_role != &"" and _speed <= MOVE_EPSILON:
		_avatar.play_pose(work_role)
	else:
		_avatar.set_locomotion(_speed if _speed > MOVE_EPSILON else 0.0)
	if _archer:
		_archer.tick(delta)
	_refresh_prompt()


## Yükün hız çarpanı (move_mods.speed_k; yük yoksa 1).
func load_speed_k() -> float:
	var k: Variant = move_mods.get("speed_k", 1.0)
	return clampf(float(k), 0.0, 1.0) if k is float or k is int else 1.0


## Yükün koşuya ve zıplamaya izni (move_mods).
func load_allows_run() -> bool:
	return bool(move_mods.get("can_run", true))


func load_allows_jump() -> bool:
	return bool(move_mods.get("can_jump", true))


## Hareketin dayandığı kameranın yatay açısı (radyan; 0 = kamera -Z'ye bakar).
func camera_yaw() -> float:
	if camera is FollowCamera:
		return (camera as FollowCamera).get_yaw()
	var cam: Node3D = camera
	if cam == null and is_inside_tree():
		cam = get_viewport().get_camera_3d()
	if cam == null or not cam.is_inside_tree():
		return 0.0
	return yaw_from_basis(cam.global_basis)


## Yerde bir adım: hız → konum, çarpışma (daireler, binilmeyen binekler, kutular, duvarlar), alan sınırı, zemin. Gerçekte alınan yol hızı belirler.
func _slide_on_foot(delta: float) -> void:
	var from := Vector2(global_position.x, global_position.z) if is_inside_tree() else Vector2(position.x, position.z)
	velocity = _soften_area(velocity, from)
	# Sürüklenme (rüzgâr) de kenarda frenlenir: oyuncu alanın kenarına çivilenmez.
	var drift := _soften_area(external_drift, from) if external_drift != Vector3.ZERO else Vector3.ZERO
	var to := from + Vector2(velocity.x + drift.x, velocity.z + drift.z) * delta
	to = resolve_circles(to, obstacles, body_radius)
	var mounts := _mount_obstacles(null)
	to = resolve_circles(to, mounts[0], body_radius)
	to = resolve_boxes(to, mounts[1], body_radius)
	to = resolve_boxes(to, boxes, body_radius)
	# Duvarlar en son: dairelerin ve kutuların itmesi karakteri duvarın öbür yanına geçiremez.
	to = resolve_walls(from, to, walls, body_radius)
	to = _clamp_area(to)
	# Gerçekte alınan yol hızı belirler: duvara yürürken karakter yerinde koşmaz,
	# engelin yanından kayarken hız teğet yöne döner. Çarpışma hızı yalnızca AZALTABİLİR:
	# engel sonradan eklenip karakter içinde kalırsa (ya da alan daralırsa) dışarı itilme
	# bir kerelik konum düzeltmesidir; hıza dönüşseydi karakter haritanın öbür ucuna fırlardı.
	# Sürüklenme hıza katılmaz (kendi yürüyüşü ölçülür): katılsaydı her karede birikir, yürüyüşü ezerdi.
	var moved := ((to - from) / delta - Vector2(drift.x, drift.z)).limit_length(velocity.length())
	velocity = Vector3(moved.x, 0.0, moved.y)
	_speed = moved.length()
	var ground := Vector3(to.x, _ground_height(to), to.y)
	if is_inside_tree():
		global_position = ground
	else:
		position = ground


# --- Zıplama -----------------------------------------------------------------------------------------

## Zıplar (Boşluk): yerde durup ya da yürüyüp koşarken; yerde nişanda, otururken ve bir geçişteyken (biniş, iniş) olmaz. Sırttayken binek sıçrar
## (_leap; nişan sürer). Zıpladıysa true.
func jump() -> bool:
	if _stance == Stance.RIDING:
		return _leap()
	if _stance != Stance.FOOT or is_aiming() or not load_allows_jump() or (swim and swim.blocks_jump()):
		return false
	_ensure_avatar()
	_jump_running = _speed > (walk_speed + run_speed) * 0.5 * load_speed_k()
	_stance = Stance.JUMPING
	_jump_phase = JumpPhase.PREP
	var anim := _avatar.get_animation_player()
	_jump_clip = anim != null and _avatar.available_roles().has(ROLE_JUMP)
	if _jump_clip:
		_jump_t = JUMP_RUN_START if _jump_running else JUMP_START
		_jump_rate = (JUMP_TAKEOFF - _jump_t) / (JUMP_RUN_PREP_S if _jump_running else JUMP_PREP_S)
		# Hızlı bir karışım: kalkış hazırlıktan hemen sonradır (rolün kendi geçişi 0,25 sn).
		anim.play(_avatar.clip_name(ROLE_JUMP), 0.12)
		_avatar.play_pose(ROLE_JUMP)
		anim.seek(_jump_t, true)
		anim.speed_scale = _jump_rate
	else:
		_jump_t = 0.0
		_jump_rate = 1.0
	if _archer:
		_archer.cancel()
	return true


## Zıplamanın bir adımı: evrenin saati, yatay hız (yerde hazırlıkta durarak söner, havada az denetim), yön, çarpışma, zemin payı.
func _jump_step(delta: float, input: Vector2, sprint: bool, p_camera_yaw: float) -> void:
	var dir := camera_relative_direction(input, p_camera_yaw)
	var moving := dir.length_squared() > 0.0001
	var anim := _avatar.get_animation_player() if _jump_clip else null
	var turn := turn_sharpness
	match _jump_phase:
		JumpPhase.PREP:
			if not _jump_running:
				velocity = approach_velocity(velocity, Vector3.ZERO, deceleration, delta)
			_jump_t += delta * _jump_rate
			var takeoff := JUMP_TAKEOFF if _jump_clip else HOP_AIR_S * 0.12
			if _jump_t >= takeoff:
				_jump_phase = JumpPhase.AIR
				_jump_t = takeoff if _jump_clip else 0.0
				if anim:
					anim.speed_scale = 1.0
					anim.seek(_jump_t, true)
				jumped.emit()
		JumpPhase.AIR:
			# Havada yön az değişir: hız giriş yönüne yavaşça döner, aşamaz.
			var cap := maxf(velocity.length(), walk_speed * 0.6)
			if moving:
				velocity = approach_velocity(velocity, (dir * (run_speed if sprint else walk_speed) * load_speed_k()).limit_length(cap), JUMP_AIR_CONTROL, delta)
			turn = turn_sharpness * JUMP_AIR_TURN
			_jump_t += delta
			if not _jump_clip:
				_avatar.position.y = sin(PI * clampf(_jump_t / HOP_AIR_S, 0.0, 1.0)) * HOP_HEIGHT * _avatar.model_scale
			var touchdown := JUMP_TOUCHDOWN if _jump_clip else HOP_AIR_S
			if _jump_t >= touchdown:
				_jump_phase = JumpPhase.LAND
				_jump_t = touchdown if _jump_clip else 0.0
				velocity *= JUMP_LAND_KEEP
				if anim:
					anim.speed_scale = JUMP_LAND_RATE
					anim.seek(_jump_t, true)
				_avatar.position.y = 0.0
				landed.emit()
		JumpPhase.LAND:
			var target := dir * (run_speed if sprint else walk_speed) * load_speed_k() if moving else Vector3.ZERO
			velocity = approach_velocity(velocity, target, acceleration if target.length() > velocity.length() else deceleration, delta)
			_jump_t += delta * (JUMP_LAND_RATE if _jump_clip else 1.0)
			# İnişin çömelmesinde ayak zemine oturur: klibin ölçülmüş payı (kişiye göre) inişte yumuşakça uygulanır.
			if _jump_clip:
				_avatar.position.y = _jump_lift * sin(PI * clampf((_jump_t - JUMP_TOUCHDOWN) / (JUMP_SETTLE - JUMP_TOUCHDOWN), 0.0, 1.0))
			var done := _jump_t >= (JUMP_SETTLE if _jump_clip else 0.08)
			if moving and (not _jump_clip or _jump_t >= JUMP_MOVE_EXIT):
				done = true
			if done:
				_end_jump()
	_slide_on_foot(delta)
	if moving:
		_target_yaw = atan2(dir.x, dir.z)
	_facing_yaw = lerp_angle(_facing_yaw, _target_yaw, 1.0 - exp(-turn * delta))
	_avatar.rotation.y = _facing_yaw


## Binekle sıçrar: binek sıçrayabiliyorsa (satırın jump'ı: at evet, koyun hayır), sıçramıyorsa ve otlamıyorsa. Nişan bırakılmaz.
func _leap() -> bool:
	if _ride == null or _mount == null or not _ride.can_leap() or _ride.is_leaping() or _mount.is_grazing():
		return false
	if not _ride.leap(_ride_speed):
		return false
	_leap_seen = _ride.leap_phase()
	_leap_kept = false
	return true


## Zıplama biter: yere, yürüyüşe ya da beklemeye karışılır (rolün geçişiyle yumuşak).
func _end_jump() -> void:
	_stance = Stance.FOOT
	_avatar.position.y = 0.0
	_avatar.set_locomotion(_speed if _speed > MOVE_EPSILON else 0.0)


# --- Saf yardımcılar (birim testli) ---------------------------------------------

## Giriş vektörünü kameraya göre dünya yönüne çevirir (XZ düzleminde, uzunluğu en fazla 1).
## input.y = ileri (kameranın baktığı yön), input.x = sağ. camera_yaw = 0 iken ileri = -Z, sağ = +X.
static func camera_relative_direction(input: Vector2, p_camera_yaw: float) -> Vector3:
	var forward := Vector3(-sin(p_camera_yaw), 0.0, -cos(p_camera_yaw))
	var right := Vector3(cos(p_camera_yaw), 0.0, -sin(p_camera_yaw))
	return (right * input.x + forward * input.y).limit_length(1.0)


## Hızı hedefe doğru en fazla accel * delta kadar değiştirir (aşmadan yaklaşır).
static func approach_velocity(current: Vector3, target: Vector3, accel: float, delta: float) -> Vector3:
	return current.move_toward(target, maxf(accel, 0.0) * maxf(delta, 0.0))


## Noktayı dairelerin dışına iter: her daireden en az (yarıçap + body_radius) uzakta kalır.
## Daireler Vector3(x, z, yarıçap). Üst üste binen daireler için birkaç tur dener.
static func resolve_circles(pos: Vector2, circles: Array[Vector3], p_body_radius: float) -> Vector2:
	var p := pos
	for _round in 4:
		var pushed := false
		for c in circles:
			var center := Vector2(c.x, c.y)
			var min_dist := c.z + p_body_radius
			var offset := p - center
			var dist := offset.length()
			if dist >= min_dist:
				continue
			var away := offset / dist if dist > 0.0001 else Vector2.RIGHT
			p = center + away * min_dist
			pushed = true
		if not pushed:
			break
	return p


## Noktayı döndürülmüş kutuların dışına iter (bkz. ObstacleBox.push_out).
static func resolve_boxes(pos: Vector2, p_boxes: Array[ObstacleBox], p_body_radius: float) -> Vector2:
	var p := pos
	for b in p_boxes:
		p = b.push_out(p, p_body_radius)
	return p


## from → to adımını kapılı duvarlara göre düzeltir (bkz. RingWall.resolve): duvardan geçilmez, kapıdan geçilir.
static func resolve_walls(from: Vector2, to: Vector2, p_walls: Array[RingWall], p_body_radius: float) -> Vector2:
	var p := to
	for w in p_walls:
		p = w.resolve(from, p, p_body_radius)
	return p


## Noktayı oyun alanı dairesinin içine çeker.
static func clamp_to_area(pos: Vector2, center: Vector2, radius: float) -> Vector2:
	var offset := pos - center
	if offset.length() <= radius:
		return pos
	return center + offset.normalized() * radius


## Oyun alanının kenarına yaklaşırken hızın DIŞA doğru bileşenini sınırlar: karakter sabit bir
## yavaşlamayla (EDGE_BRAKE) fren yapar ve kenara EDGE_STOP_MARGIN kala durur; görünmez bir duvara
## çarpmaz. Yalnızca son soft metrede devreye girer; içe ve teğet hareket etkilenmez.
## (Varsayılan soft = 3 m ile 4.8 m/s'ye kadar hızlarda fren yumuşak başlar.)
static func soften_at_edge(p_velocity: Vector3, pos: Vector2, center: Vector2, radius: float, soft: float) -> Vector3:
	var offset := pos - center
	var dist := offset.length()
	if soft <= 0.0 or dist < radius - soft or dist < 0.0001:
		return p_velocity
	var outward := Vector3(offset.x, 0.0, offset.y) / dist
	var out_speed := p_velocity.dot(outward)
	var room := maxf(radius - EDGE_STOP_MARGIN - dist, 0.0)
	var limit := sqrt(2.0 * EDGE_BRAKE * room)
	if out_speed <= limit:
		return p_velocity
	return p_velocity - outward * (out_speed - limit)


## Bir dönüşümün "ekranda yukarı" yönünün yatay açısı (eğik ya da tepeden bakan kamera için de çalışır).
static func yaw_from_basis(p_basis: Basis) -> float:
	var up_screen := -p_basis.z + p_basis.y
	if Vector2(up_screen.x, up_screen.z).length_squared() < 0.000001:
		return 0.0
	return atan2(-up_screen.x, -up_screen.z)


## Verilen düğümün üstlerinde ya da onların çocuklarında ilk World düğümünü bulur.
static func find_world(from: Node) -> World:
	var node := from.get_parent() if from else null
	while node:
		if node is World:
			return node
		for child in node.get_children():
			if child is World:
				return child
		node = node.get_parent()
	return null


## Zeminin eğimi (radyan; artı: burun aşağı): at'tan yaw yönünde ön ve arka yüksekliklerden (saf).
static func ground_pitch(shape: RefCounted, at: Vector2, yaw: float, half_length: float) -> float:
	if shape == null:
		return 0.0
	var f := Vector2(sin(yaw), cos(yaw)) * half_length
	var front := float(shape.call(&"height_at", at.x + f.x, at.y + f.y))
	var back := float(shape.call(&"height_at", at.x - f.x, at.y - f.y))
	return atan2(back - front, half_length * 2.0)


# --- İç işler -----------------------------------------------------------------

func _ensure_avatar() -> void:
	if _avatar:
		return
	for child in get_children():
		if child is CharacterAvatar:
			_avatar = child
			break
	if _avatar == null:
		_avatar = CharacterAvatar.new()
		_avatar.name = "Avatar"
		add_child(_avatar)
	# Beklerken ara hareket (K91): hareket edince set_locomotion hemen keser. Çeşit atanmaz, oyuncu kendi kliplerinde kalır.
	_avatar.auto_fidget = true


func _ground_height(p: Vector2) -> float:
	return float(terrain_shape.call(&"height_at", p.x, p.y)) if terrain_shape else 0.0


func _ground_at(x: float, z: float) -> float:
	return _ground_height(Vector2(x, z))


func _flat_position() -> Vector2:
	var p := global_position if is_inside_tree() else position
	return Vector2(p.x, p.z)


func _soften_area(v: Vector3, from: Vector2) -> Vector3:
	if not play_area_extra.is_empty():
		var c := roomiest_circle(from, _area_circles())
		return soften_at_edge(v, from, Vector2(c.x, c.y), c.z, play_area_soft_edge)
	return soften_at_edge(v, from, play_area_center, play_area_radius, play_area_soft_edge)


func _clamp_area(p: Vector2) -> Vector2:
	if not play_area_extra.is_empty():
		return clamp_to_circles(p, _area_circles())
	return clamp_to_area(p, play_area_center, play_area_radius)


## Oyun alanının daireleri (oyun alanı dairesi ve play_area_extra).
func _area_circles() -> Array[Vector3]:
	var out: Array[Vector3] = [Vector3(play_area_center.x, play_area_center.y, play_area_radius)]
	out.append_array(play_area_extra)
	return out


## Noktayı dairelerin birleşimine çeker (saf): içindeyse kendisi, değilse en yakın dairenin kenarı.
static func clamp_to_circles(pos: Vector2, circles: Array[Vector3]) -> Vector2:
	var best := pos
	var best_d := INF
	for c in circles:
		var center := Vector2(c.x, c.y)
		var off := pos - center
		var d := off.length()
		if d <= c.z:
			return pos
		if d - c.z < best_d:
			best_d = d - c.z
			best = center + off / d * c.z if d > 0.0001 else center
	return best


## Noktanın en çok payı olan dairesi (saf; payı: yarıçap − uzaklık): kenar freni o dairenin kenarına göre çalışır.
static func roomiest_circle(pos: Vector2, circles: Array[Vector3]) -> Vector3:
	var best := circles[0] if not circles.is_empty() else Vector3(pos.x, pos.y, 1.0)
	var best_room := -INF
	for c in circles:
		var room := c.z - pos.distance_to(Vector2(c.x, c.y))
		if room > best_room:
			best_room = room
			best = c
	return best


## Binilmeyen bineklerin gövdesi (engel; exclude binilen): [daireler, kutular]. Kısa binek (koyun) daire, uzun binek (at; half_length) yatay kutudur.
## Gizli dünyanın binekleri engel değildir.
func _mount_obstacles(exclude: Rideable) -> Array:
	var circles: Array[Vector3] = []
	var bodies: Array[ObstacleBox] = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(Rideable.GROUP):
			var ride := node as Rideable
			if not _mount_present(ride) or ride == exclude or ride.ridden:
				continue
			if ride.get_mount().value("half_length") > 0.0:
				bodies.append(ride.obstacle_box())
			else:
				var at := ride.global_position
				circles.append(Vector3(at.x, at.z, ride.get_mount().value("radius") * 0.7))
	return [circles, bodies]


## Binek bu dünyada mı: satırı var ve görünüyor (Çocukluk'ta gizlenen kampın atları ağaçta kalır; ne binilir ne engeldir).
static func _mount_present(ride: Rideable) -> bool:
	return ride != null and ride.get_mount() != null and ride.is_visible_in_tree()


## Yerde dururken binilmeyen bineklerin gövde daireleri (eski ad; koyun).
func _mount_circles() -> Array[Vector3]:
	return _mount_obstacles(null)[0]


## İnilen nokta kapalı mı (engel daireleri, kutular, binilmeyen binekler, kapılı duvarlar, alan)?
func _spot_blocked(spot: Vector2) -> bool:
	var margin := body_radius * 0.9
	for c in obstacles:
		if spot.distance_to(Vector2(c.x, c.y)) < c.z + margin:
			return true
	for b in boxes:
		if b.push_out(spot, margin) != spot:
			return true
	var mounts := _mount_obstacles(_ride)
	for c: Vector3 in mounts[0]:
		if spot.distance_to(Vector2(c.x, c.y)) < c.z + margin:
			return true
	for b: ObstacleBox in mounts[1]:
		if b.push_out(spot, margin) != spot:
			return true
	if _ride and not walls.is_empty():
		var center := Vector2(_ride.global_position.x, _ride.global_position.z)
		if resolve_walls(center, spot, walls, margin).distance_to(spot) > 0.01:
			return true
	if not play_area_extra.is_empty():
		return clamp_to_circles(spot, _area_circles()) != spot
	return spot.distance_to(play_area_center) > play_area_radius


func _remember_adult() -> void:
	_adult_walk = walk_speed
	_adult_run = run_speed
	_adult_radius = body_radius


## Çocuğun klipleri: binme (oturuştan türer; koyunun satırıyla), kalkış, yerden alma, zıplama. Parçası eksikse rol atlanır (chibi yedeği).
func _prepare_child_clips() -> void:
	_ride_poses.clear()
	_ride_pose_kind = ""
	var skeleton := _avatar.get_skeleton()
	if skeleton == null:
		return
	var library := ClipVariety.library()
	_prepare_ride_pose(Mount.new("sheep"), false)
	_add_once_clip(ROLE_RISE, RISE_CLIP)
	_add_once_clip(ROLE_COLLECT, COLLECT_CLIP)
	_aim_clip = _add_held_clip(ROLE_AIM, AIM_CLIP)
	_rise_ends = library.ground_offset_ends(_avatar.model_id, RISE_CLIP)
	_prepare_jump_clip()


## Zıplamanın rolü (kütüphanenin klibi, bir kez oynar) ve kişideki zemin payı. Çocukta ve yetişkinde aynı; klip yoksa (chibi) jump() kodla sekiyor.
func _prepare_jump_clip() -> void:
	_jump_lift = 0.0
	if _avatar.get_skeleton() == null or ClipVariety.library().clip(JUMP_CLIP).is_empty():
		return
	_add_once_clip(ROLE_JUMP, JUMP_CLIP)
	_jump_lift = ClipVariety.library().ground_offset_for(_avatar.model_id, JUMP_CLIP) * _avatar.model_scale


## Binme pozu bu bineğin türü için (RidePose; satırın seat'iyle, oturuştan türer): tür değişince kurulur, türün pozu bir kez kurulur.
func _prepare_ride_pose(p_mount: Mount, release: bool = true) -> void:
	if p_mount == null or _ride_pose_kind == p_mount.id:
		return
	var skeleton := _avatar.get_skeleton()
	if skeleton == null:
		return
	var clip: Animation = _ride_poses.get(p_mount.id)
	if clip == null:
		var sit := ClipVariety.library().clip_for(_avatar.model_id, "sit", skeleton)
		clip = RidePose.build(skeleton, sit, p_mount.seat(), _avatar.model_scale)
		if clip == null:
			return
		_ride_poses[p_mount.id] = clip
		if release:
			ClipVariety.release_sources()
	_avatar.set_role_clip(RidePose.ROLE, clip)
	_ride_pose_kind = p_mount.id
	_refresh_ride_offset()


## Bir kez oynayan rol: kütüphanenin klibinin kopyası (ortak kaynak değişmez).
func _add_once_clip(role: StringName, key: String) -> void:
	var skeleton := _avatar.get_skeleton()
	var source := ClipVariety.library().clip_for(_avatar.model_id, key, skeleton) if skeleton else null
	if source == null:
		return
	var anim := source.duplicate() as Animation
	_avatar.set_role_clip(role, anim)
	anim.loop_mode = Animation.LOOP_NONE


## Döngüde tutulan rol (nişan duruşu): kütüphanenin klibinin kopyası. Elle verilen rolün zemin payı avatarda 0'dır: klibin bu kişideki ölçülmüş payı
## (ClipLibrary.ground_offset_for) kalçanın konum izine yazılır, ayak yere değer. Kurulduysa true.
func _add_held_clip(role: StringName, key: String) -> bool:
	var skeleton := _avatar.get_skeleton()
	var library := ClipVariety.library()
	var source := library.clip_for(_avatar.model_id, key, skeleton) if skeleton and not library.clip(key).is_empty() else null
	if source == null:
		return false
	var anim := source.duplicate(true) as Animation
	var lift := library.ground_offset_for(_avatar.model_id, key)
	var track := anim.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(anim)), Animation.TYPE_POSITION_3D)
	if track >= 0 and absf(lift) > 0.0001:
		# Modelin bir metre yukarısı iskelet uzayında (Meshy iskeleti santimetre ölçeklidir).
		var up := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton).basis.inverse() * Vector3.UP
		for k in anim.track_get_key_count(track):
			anim.track_set_key_value(track, k, (anim.track_get_key_value(track, k) as Vector3) + up * lift)
	_avatar.set_role_clip(role, anim)
	anim.loop_mode = Animation.LOOP_LINEAR
	return true


func _refresh_ride_offset() -> void:
	var skeleton := _avatar.get_skeleton()
	_hips_offset = RidePose.hips_in_model(skeleton, _avatar.model_scale) if skeleton else Vector3(0.0, 0.5, 0.0)
	var measured := ClipVariety.library().hips_height_for(_avatar.model_id, RIDE_SIT_KEY) if skeleton else 0.0
	# Ata ata binişin payı (satırın seat.straddle; koyunda yok): bağdaşta kalçanın altı yere, atta uyluğun içi ve etek eyere değer.
	var straddle := float(_mount.seat().get("straddle", 0.0)) if _mount else 0.0
	_hips_lift = ((measured if measured > 0.0 else RIDE_HIPS_LIFT) + straddle) * _avatar.model_scale


## Binicinin kalçasının oturma noktasından yüksekliği (metre).
func hips_lift() -> float:
	return _hips_lift


## Sırtta kalçanın gideceği yer: oturma noktası (sırtın yünü) ve kişinin oturuş yüksekliği; avatarın dönüşümü bundan çıkar.
func _seated_transform() -> Transform3D:
	var seat := _ride.seat_transform()
	return Transform3D(seat.basis, seat.origin + seat.basis.y.normalized() * _hips_lift - seat.basis * _hips_in_avatar())


## Kalçanın avatarın uzayındaki dinlenme yeri: modelin avatardaki kayması (rolün zemin payı; beklemenin 3,7 cm'si binme pozuna da taşınır) dahil
## (M9: kalça eyer noktasında ±1 cm). İskelet yoksa _hips_offset.
func _hips_in_avatar() -> Vector3:
	var skeleton := _avatar.get_skeleton() if _avatar else null
	var hips := skeleton.find_bone("Hips") if skeleton else -1
	if hips < 0:
		return _hips_offset
	return PoseFit.relative_transform(_avatar, skeleton) * skeleton.get_bone_global_rest(hips).origin


## Kipten hemen çıkar: yerde, avatar düğümün kökünde. Binek olduğu yerde kalır.
func _leave_stance() -> void:
	if _archer:
		_archer.cancel()
	if _ride:
		_close_ride_entry()
		_ride.set_ridden(false)
		if _mount:
			_mount.end_ride()
	_ride = null
	_mount = null
	_ride_speed = 0.0
	_leap_seen = Rideable.LeapPhase.NONE
	_collect_target = null
	carried = false
	if _stance != Stance.FOOT and _avatar:
		_avatar.position = Vector3.ZERO
		_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
		_avatar.set_locomotion(0.0)
		_avatar.snap_transition()
	_stance = Stance.FOOT
	_set_hands("")
	if _avatar:
		_avatar.set_process(true)


# --- Oturuş ------------------------------------------------------------------------------------------

func _begin_rise() -> void:
	if _avatar.available_roles().has(ROLE_RISE):
		_stance = Stance.RISING
		_clip_t = 0.0
		_clip_s = _avatar.get_animation_player().get_animation(_avatar.clip_name(ROLE_RISE)).length / RISE_RATE
		_avatar.play_pose(ROLE_RISE)
		_avatar.get_animation_player().speed_scale = RISE_RATE
	else:
		_stance = Stance.FOOT
		_avatar.set_locomotion(0.0)


func _tick_rise(delta: float) -> void:
	_clip_t += delta
	# Geçişin zemin payı başla son arasında kayar (rol payı 0'dır: klibin ucunda ayak ve kalça zemine değer).
	_avatar.position.y = lerpf(_rise_ends.x, _rise_ends.y, clampf(_clip_t / maxf(_clip_s, 0.01), 0.0, 1.0)) * _avatar.model_scale
	if _clip_t >= _clip_s:
		_stance = Stance.FOOT
		_avatar.position.y = 0.0
		_avatar.set_locomotion(0.0)


# --- Binek -------------------------------------------------------------------------------------------

## Yolculuğun binekleri (yoksa kurulur).
func _stable() -> MountStable:
	if mount_stable == null:
		mount_stable = MountStable.new()
	return mount_stable


## Oturumun kayıt bloklarına bağlanır (kayıt v2 «mounts»): yolculuğun bineklerini yeni bir MountStable taşır, kayıttaki blok okunur.
func bind_mount_stable(blocks: SaveBlocks) -> MountStable:
	mount_stable = MountStable.new()
	mount_stable.register_block(blocks)
	return mount_stable


## Binişte bineğin kaydı açılır: ilk binişte köken payıyla (yetişkin: profilin kökeni; Ahır Yamağı Bağ +10), aradaki dinlenme işlenir, at staminası
## ve koşul (Bağ, eyer, gem, terki) Mount'a geçer; toynaklar binicinin zeminine basar (RideableHooves).
func _open_ride_entry(ride: Rideable) -> void:
	_ride_key = ride.mount_key()
	var stable := _stable()
	var entry := stable.entry(_ride_key, ride.mount_kind(), _origin_bond())
	if _ride_left_ms.has(_ride_key):
		stable.rest((Time.get_ticks_msec() - int(_ride_left_ms[_ride_key])) / 1000.0, "")
		_ride_left_ms.erase(_ride_key)
	stable.active = _ride_key
	_mount.stamina = float(entry.get("sta", 1.0))
	_mount.winded = _mount.stamina < _mount.value("spur_min") and _mount.has_spur()
	_refresh_ride_condition()
	if terrain_shape:
		ride.set_ground(terrain_shape)


## İnişte at staminası kayda yazılır, iniş anı tutulur (yeniden binişte aradaki dinlenme).
func _close_ride_entry() -> void:
	if _ride_key.is_empty():
		return
	if _mount:
		_stable().set_stamina(_ride_key, _mount.stamina)
	_ride_left_ms[_ride_key] = Time.get_ticks_msec()
	if _stable().active == _ride_key:
		_stable().active = ""
	_ride_key = ""


## Binişin koşulu: Bağ ve at eşyası kayıttan, terki ride_load'dan (Inventory.mount_mods).
func _refresh_ride_condition() -> void:
	if _mount == null or _ride_key.is_empty():
		return
	var load: Dictionary = {}
	if ride_load.is_valid():
		var got: Variant = ride_load.call(_ride_key)
		if got is Dictionary:
			load = got
	_mount.set_condition(_stable().condition(_ride_key, load))


## Köken payı (yetişkinin profili; çocukta 0).
func _origin_bond() -> float:
	if is_child() or _avatar == null:
		return 0.0
	var profile := _avatar.get_profile()
	return MountStable.origin_bond(profile.origin_id()) if profile else 0.0


## Binilen bineğin kaydının anahtarı ("" binilmiyorsa).
func ride_key() -> String:
	return _ride_key


## Binicinin yeri karenin sonunda yeniden yazılır (M9, eyer noktası ±1 cm): bineğin klibi bu karede uygulandıktan sonra (yardımcının önceliği
## SEAT_SYNC_PRIORITY, oyunun düğümlerinden sonra). Denetleyicinin adımı bineği yürütür, klibi oynatıcı sonra ilerletir: yardımcı olmasa binici
## bineğin bir önceki karesine otururdu (dörtnalda gövde kemiği karede ≈1,4 cm iner kalkar).
const SEAT_SYNC_PRIORITY := 100
var _seat_sync: _SeatSync


func _ensure_seat_sync() -> void:
	if _seat_sync != null and is_instance_valid(_seat_sync):
		return
	_seat_sync = _SeatSync.new()
	_seat_sync.name = "SeatSync"
	_seat_sync.controller = self
	_seat_sync.process_priority = SEAT_SYNC_PRIORITY
	add_child(_seat_sync)


## Sırttaki binicinin yerini yeniden yazar (SeatSync; sınama da çağırır).
func sync_seat() -> void:
	if _stance == Stance.RIDING and _ride and is_instance_valid(_ride) and _avatar:
		_place_rider()


class _SeatSync:
	extends Node
	var controller: PlayerController

	func _process(_delta: float) -> void:
		if is_instance_valid(controller):
			controller.sync_seat()


## Binilen atın staminası (0..1; binilmiyorsa -1), mahmuz, soluk ve Bağ.
func mount_stamina() -> float:
	return _mount.stamina if _mount and not _ride_key.is_empty() else -1.0


func is_spurring() -> bool:
	return _mount != null and _stance == Stance.RIDING and _mount.is_spurring()


func is_mount_winded() -> bool:
	return _mount != null and _mount.is_winded()


func mount_bond() -> float:
	return _mount.bond() if _mount else 0.0


## Binme ve inme: düğüm kayar, binici yerle sırt arasında süzülür (ortada küçük bir sıçrayış). Atta (vault) evreli biniş ve iniş: _tick_vault.
func _tick_ride_change(delta: float) -> void:
	if _mount.mount_style() == "vault":
		_tick_vault(delta)
		return
	_ride_t = minf(_ride_t + delta / _ride_s, 1.0)
	var k := smoothstep(0.0, 1.0, _ride_t)
	var going_up := _stance == Stance.MOUNTING
	var node_at := _ride_from.lerp(_ride_to, k)
	global_position = node_at
	if going_up:
		_facing_yaw = lerp_angle(_facing_yaw, _ride.global_rotation.y, 1.0 - exp(-turn_sharpness * delta))
	_target_yaw = _facing_yaw
	var on_foot := Transform3D(Basis(Vector3.UP, _facing_yaw), node_at)
	var seated := _seated_transform()
	var blend := k if going_up else 1.0 - k
	var xform := on_foot.interpolate_with(seated, blend)
	xform.origin += Vector3.UP * sin(PI * _ride_t) * MOUNT_HOP
	_avatar.global_transform = xform
	_ride.drive(0.0, delta)
	if _ride_t < 1.0:
		return
	if going_up:
		_finish_mount()
	else:
		_finish_dismount()


func _finish_mount() -> void:
	_stance = Stance.RIDING
	_facing_yaw = _ride.global_rotation.y
	_target_yaw = _facing_yaw
	_set_hands("ride")
	_place_rider()
	mounted.emit(_ride)


func _finish_dismount() -> void:
	var left := _ride
	_close_ride_entry()
	_ride.set_ridden(false)
	_ride = null
	_mount = null
	_stance = Stance.FOOT
	_avatar.position = Vector3.ZERO
	_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
	dismounted.emit(left)


## Ata biniş: binicinin duracağı yer bineğin yakın yanıdır (binicinin bulunduğu yan), oturma noktasının biraz önünde; yüzü atın başına, ata doğru dönük.
func _begin_vault() -> void:
	var center := Vector2(_ride.global_position.x, _ride.global_position.z)
	var heading := _ride.global_rotation.y
	var left := Vector2(cos(heading), -sin(heading))
	var fwd := Vector2(sin(heading), cos(heading))
	_vault_side = 1.0 if (_flat_position() - center).dot(left) >= 0.0 else -1.0
	var seat := _ride.get_mount().seat()
	var along := float(_ride.meta.get("saddle_z", seat.get("saddle_z", 0.0))) + VAULT_FORWARD
	var spot := center + left * _vault_side * VAULT_SIDE + fwd * along
	_vault_spot = Vector3(spot.x, _ground_height(spot), spot.y)
	# Yüz: atın başına doğru, ata VAULT_TURN radyan dönük (sol yanda sağa, sağ yanda sola).
	_vault_yaw = heading + _vault_side * VAULT_TURN
	_vault_phase = VaultPhase.APPROACH
	_vault_t = 0.0
	var distance := _flat_position().distance_to(spot)
	_vault_s = clampf(distance / maxf(walk_speed, 0.5), 0.0, VAULT_APPROACH_MAX_S)
	_vault_node_from = global_position
	_avatar.set_locomotion(walk_speed if _vault_s > 0.05 else 0.0)


## Attan iniş: sırttan binicinin yanına (dismount_spot: önce sol) atılır, düşer, çömelerek yere konar.
func _begin_vault_down() -> void:
	_vault_phase = VaultPhase.SWING
	_vault_t = 0.0
	_vault_s = DROP_SWING_S
	_vault_from = _avatar.global_transform
	_vault_node_from = global_position
	_vault_spot = _ride_to
	var heading := _ride.global_rotation.y
	var to := Vector2(_ride_to.x, _ride_to.z) - _flat_position()
	_vault_side = 1.0 if to.dot(Vector2(cos(heading), -sin(heading))) >= 0.0 else -1.0
	_vault_yaw = heading + _vault_side * VAULT_TURN * 0.6
	_set_hands("")
	if _jump_clip_ready():
		_play_jump_from(1.0, 0.18)
		_avatar.get_animation_player().speed_scale = 0.0


func _jump_clip_ready() -> bool:
	return _avatar.get_animation_player() != null and _avatar.available_roles().has(ROLE_JUMP)


## Zıplama klibini verilen anından oynatır (geçişli).
func _play_jump_from(at: float, blend: float) -> void:
	var anim := _avatar.get_animation_player()
	anim.play(_avatar.clip_name(ROLE_JUMP), blend)
	_avatar.play_pose(ROLE_JUMP)
	anim.seek(at, true)


## Ata biniş ve inişin evreleri (bkz. VaultPhase); bineğin kendisi durur.
func _tick_vault(delta: float) -> void:
	_vault_t += delta
	var k := clampf(_vault_t / maxf(_vault_s, 0.0001), 0.0, 1.0)
	_ride.drive(0.0, delta)
	var anim := _avatar.get_animation_player()
	var clip := _jump_clip_ready()
	match _vault_phase:
		VaultPhase.APPROACH:
			# Yürüyerek yanaşır, son adımda ata döner.
			var at := _vault_node_from.lerp(_vault_spot, k)
			global_position = at
			var walk_dir := Vector2(_vault_spot.x - _vault_node_from.x, _vault_spot.z - _vault_node_from.z)
			var aim := atan2(walk_dir.x, walk_dir.y) if walk_dir.length_squared() > 0.0004 and k < 0.75 else _vault_yaw
			_facing_yaw = lerp_angle(_facing_yaw, aim, 1.0 - exp(-turn_sharpness * delta))
			_avatar.position = Vector3.ZERO
			_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
			if k >= 1.0:
				var take := mount_take_seconds()
				if take > 0.0:
					_next_vault(VaultPhase.TAKE, take)
					_avatar.set_locomotion(0.0)
					_set_hands("ride")
				else:
					_begin_crouch(anim, clip)
		VaultPhase.TAKE:
			# Başı çıplak at yeleden tutulur, sakinleşir (mount_take_seconds): binici ata döner, bekler; sonra çömelir.
			_facing_yaw = lerp_angle(_facing_yaw, _vault_yaw, 1.0 - exp(-turn_sharpness * delta))
			_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
			if k >= 1.0:
				_begin_crouch(anim, clip)
		VaultPhase.CROUCH:
			_facing_yaw = lerp_angle(_facing_yaw, _vault_yaw, 1.0 - exp(-turn_sharpness * delta))
			_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
			if k >= 1.0:
				_vault_from = _avatar.global_transform
				_vault_node_from = global_position
				_next_vault(VaultPhase.LIFT, VAULT_LIFT_S)
				if clip:
					anim.speed_scale = 1.0
					anim.seek(JUMP_TAKEOFF, true)
				_set_hands("ride")
		VaultPhase.LIFT:
			# Sıçrayış: yerden sırta bir yay; yüz atın yönüne döner, yolun ortasında binme pozuna karışılır. Düğüm atın yerine kayar (kamera yumuşak izler).
			var e := smoothstep(0.0, 1.0, k)
			global_position = _vault_node_from.lerp(_ride.global_position, e)
			var seated := _seated_transform()
			var xform := _vault_from.interpolate_with(seated, e)
			xform.origin += Vector3.UP * sin(PI * k) * VAULT_ARC
			_avatar.global_transform = xform
			if k >= VAULT_POSE_AT and _avatar.get_current_role() != RidePose.ROLE:
				_avatar.play_pose(RidePose.ROLE)
				if anim:
					anim.speed_scale = 1.0
			if k >= 1.0:
				_next_vault(VaultPhase.SETTLE, VAULT_SETTLE_S)
		VaultPhase.SETTLE:
			# Eyere oturur: küçük bir çöküş, sonra sırtın yeri.
			global_position = _ride.global_position
			var seated := _seated_transform()
			seated.origin -= Vector3.UP * sin(PI * k) * VAULT_DIP
			_avatar.global_transform = seated
			if k >= 1.0:
				_finish_mount()
		VaultPhase.SWING:
			# Sırttan yana atılır: yükselir ve dışa kayar, poz zıplamanın havasına karışır.
			var e := smoothstep(0.0, 1.0, k)
			var side_at := _vault_spot.lerp(_vault_node_from, 0.45)
			var target := Transform3D(Basis(Vector3.UP, _vault_yaw), Vector3(side_at.x, _vault_from.origin.y + 0.08, side_at.z))
			var xform := _vault_from.interpolate_with(target, e)
			_avatar.global_transform = xform
			if k >= 1.0:
				_vault_from = _avatar.global_transform
				_next_vault(VaultPhase.DROP, DROP_FALL_S)
				if clip:
					anim.speed_scale = (JUMP_TOUCHDOWN - 1.0) / DROP_FALL_S
		VaultPhase.DROP:
			# Düşüş: inilen yere, hızlanarak (yerçekimi).
			var e := k * k
			global_position = _vault_node_from.lerp(_vault_spot, smoothstep(0.0, 1.0, k))
			var ground := Transform3D(Basis(Vector3.UP, _vault_yaw), _vault_spot)
			_avatar.global_transform = _vault_from.interpolate_with(ground, e)
			if k >= 1.0:
				global_position = _vault_spot
				_facing_yaw = _vault_yaw
				_target_yaw = _facing_yaw
				_avatar.position = Vector3.ZERO
				_avatar.rotation = Vector3(0.0, _facing_yaw, 0.0)
				_next_vault(VaultPhase.LAND, DROP_LAND_S)
				if clip:
					anim.seek(JUMP_TOUCHDOWN, true)
					anim.speed_scale = JUMP_LAND_RATE
				landed.emit()
		VaultPhase.LAND:
			if clip:
				_avatar.position.y = _jump_lift * sin(PI * k)
			if k >= 1.0:
				_avatar.position = Vector3.ZERO
				_finish_dismount()
				_avatar.set_locomotion(0.0)


func _next_vault(phase: VaultPhase, seconds: float) -> void:
	_vault_phase = phase
	_vault_t = 0.0
	_vault_s = seconds


## Binişin çömelmesi: zıplama klibinin hazırlığı (klip yoksa bekleme).
func _begin_crouch(anim: AnimationPlayer, clip: bool) -> void:
	_next_vault(VaultPhase.CROUCH, VAULT_CROUCH_S)
	if clip:
		_play_jump_from(JUMP_START, 0.12)
		anim.speed_scale = (JUMP_TAKEOFF - JUMP_START) / VAULT_CROUCH_S
	else:
		_avatar.set_locomotion(0.0)


## Atı tutmanın süresi (sn; yanaşmadan sonra, çömelmeden önce): MountStable.take_seconds (başı çıplak atta satırın catch_s'i × (1 − Bağ/100);
## yular ve gem kaldırır; yuların «binme süresi −1 sn»si çıplak başa göredir, progression.md §6.4). Binilmiyorsa 0.
func mount_take_seconds() -> float:
	if _mount == null or _ride_key.is_empty():
		return 0.0
	var stable := _stable()
	return MountStable.take_seconds(_mount.value("catch_s"), stable.bond(_ride_key), stable.gear_of(_ride_key, "bridle"),
		float(stable.gear_effects(_ride_key).get("mount_time", 0.0)))


## Sırtta bir adım: binek hedef hızını Mount verir (otlarken yürümez, yeni basış dürter; atta adım, tırıs, dörtnal), binek yönüne döner (atın dönüşü hızla genişler)
## ve ileri gider (yan gitmez); çarpışma bineğin yarıçapıyla, uzun binekte önde ve arkada iki daireyle. Binek sıçrarken hızı ve dönüşü _leap_speed yönetir.
func _ride_step(delta: float, input: Vector2, sprint: bool, p_camera_yaw: float) -> void:
	var prod := sprint and not _sprint_was
	_sprint_was = sprint
	var dir := camera_relative_direction(input, p_camera_yaw)
	var wants := dir.length_squared() > 0.0001
	# Koşul her adımda tazelenir (terki at üstünde toplanınca dolar; economy.md §3.1); at staminası kayda geçer, öteki binekler dinlenir.
	_refresh_ride_condition()
	var goal := _mount.step(delta, wants, sprint and not is_aiming(), prod) * minf(dir.length(), 1.0)
	_stable().set_stamina(_ride_key, _mount.stamina)
	_stable().rest(delta, _ride_key)
	var phase := _ride.leap_phase()
	var plan := _ride.leap_plan() if phase != Rideable.LeapPhase.NONE else {}
	if wants:
		_target_yaw = atan2(dir.x, dir.z)
	if not _mount.is_grazing():
		var turn := _mount.turn_at(_ride_speed)
		if phase == Rideable.LeapPhase.PREP or phase == Rideable.LeapPhase.AIR:
			# İterken ve havada dönüş azalır.
			turn *= float(plan.get("air_turn", 1.0))
		_facing_yaw = lerp_angle(_facing_yaw, _target_yaw, 1.0 - exp(-turn * delta))
	# Dönerken yavaşlar: arkasına dönerken ileri koşmaz.
	var align := maxf(cos(angle_difference(_facing_yaw, _target_yaw)), 0.0)
	goal *= lerpf(0.3, 1.0, align)
	var rate := _mount.value("accel") if goal >= _ride_speed else _mount.value("decel")
	if phase == Rideable.LeapPhase.NONE:
		_ride_speed = move_toward(_ride_speed, goal, rate * delta)
	else:
		_ride_speed = _leap_speed(phase, plan, goal, rate, delta)
	velocity = Vector3(sin(_facing_yaw), 0.0, cos(_facing_yaw)) * _ride_speed
	var from := _flat_position()
	velocity = _soften_area(velocity, from)
	var to := from + Vector2(velocity.x, velocity.z) * delta
	var radius := _mount.value("radius")
	var half := _mount.value("half_length")
	var circles: Array[Vector3] = obstacles.duplicate()
	var bodies: Array[ObstacleBox] = boxes.duplicate()
	if half > 0.0:
		# Atla öteki binilmeyen hayvanların içinden geçilmez (koyun sürüsünde binek eskisi gibi yalnız engellere çarpar).
		var mounts := _mount_obstacles(_ride)
		circles.append_array(mounts[0])
		bodies.append_array(mounts[1])
	var fwd := Vector2(sin(_facing_yaw), cos(_facing_yaw))
	# Uzun gövde: göğüs ve sağrı ayrı daireler; ikisinin itmesi merkezi taşır (iki tur).
	var offsets: Array[float] = [0.0]
	if half > 0.0:
		offsets = [half, -half, 0.0]
	for _round in (1 if half <= 0.0 else 2):
		for off in offsets:
			var shift := fwd * off
			var p := to + shift
			p = resolve_circles(p, circles, radius)
			p = resolve_boxes(p, bodies, radius)
			p = resolve_walls(from + shift, p, walls, radius)
			to = p - shift
	to = _clamp_area(to)
	var moved := ((to - from) / delta).limit_length(velocity.length())
	velocity = Vector3(moved.x, 0.0, moved.y)
	_speed = moved.length()
	_ride_speed = minf(_ride_speed, _speed + rate * delta)
	var pitch_half := half + radius * 0.5 if half > 0.0 else radius
	var ground := Vector3(to.x, _ride_ground(to, pitch_half, delta), to.y)
	global_position = ground
	_ride.place(ground, _facing_yaw, PlayerController.ground_pitch(terrain_shape, to, _facing_yaw, pitch_half))
	_ride.drive(_speed, delta)
	var after := _ride.leap_phase()
	if after != _leap_seen:
		if after == Rideable.LeapPhase.AIR:
			jumped.emit()
		elif _leap_seen == Rideable.LeapPhase.AIR:
			landed.emit()
		_leap_seen = after
	_place_rider()


## Bineğin oturduğu zemin yüksekliği: uzun bineğin (at) önünün ve arkasının zemininin ortası (eğimi ground_pitch verir), RIDE_GROUND_RATE ile
## yumuşatılmış: basamakta gövde bir karede sıçramaz, toynaklar (RideableHooves) kendi zeminine basar. Kısa binekte (koyun) ortadaki zemin.
const RIDE_GROUND_RATE := 14.0
var _ride_ground_y := NAN


func _ride_ground(at: Vector2, half: float, delta: float) -> float:
	var want := _ground_height(at)
	if _mount and _mount.value("half_length") > 0.0 and terrain_shape:
		var f := Vector2(sin(_facing_yaw), cos(_facing_yaw)) * half
		want = (_ground_height(at + f) + _ground_height(at - f)) * 0.5
	if is_nan(_ride_ground_y):
		_ride_ground_y = _ride.global_position.y if _ride and _ride.is_inside_tree() else want
	if delta <= 0.0:
		_ride_ground_y = want
	else:
		_ride_ground_y = lerpf(_ride_ground_y, want, 1.0 - exp(-RIDE_GROUND_RATE * delta))
	return _ride_ground_y


## Sıçrarken bineğin hızı (m/sn). Koşarak: hız korunur, ön inişte land_keep'i kalır, sonra giriş yönetir. Durarak: toplanırken durur, iterken ve ön
## inişte toynağın klipteki kayma hızıyla gider (leap_ground_speed: ayak yerde kaymaz), havada fırlayış hızını korur; toparlanırken giriş yoksa hemen
## durur (arka toynaklar yerinde), varsa yürür.
func _leap_speed(phase: Rideable.LeapPhase, plan: Dictionary, goal: float, rate: float, delta: float) -> float:
	var running := bool(plan.get("running", false))
	if phase == Rideable.LeapPhase.AIR:
		return _ride_speed
	if running:
		if phase == Rideable.LeapPhase.PREP:
			return _ride_speed
		if not _leap_kept:
			_leap_kept = true
			return _ride_speed * float(plan.get("land_keep", 1.0))
		return move_toward(_ride_speed, goal, rate * delta)
	var ground := _ride.leap_ground_speed()
	if ground > 0.0:
		return ground
	if phase == Rideable.LeapPhase.PREP:
		return move_toward(_ride_speed, 0.0, LEAP_GATHER_DECEL * delta)
	if goal <= 0.0:
		return move_toward(_ride_speed, 0.0, LEAP_STOP_DECEL * delta)
	return move_toward(_ride_speed, goal, rate * delta)


func _place_rider() -> void:
	_avatar.global_transform = _seated_transform()


# --- Toplama -----------------------------------------------------------------------------------------

func _begin_collect(target: Node3D) -> void:
	_collect_target = target
	velocity = Vector3.ZERO
	_speed = 0.0
	if not _avatar.available_roles().has(ROLE_COLLECT):
		_finish_collect()
		return
	_stance = Stance.COLLECTING
	_clip_t = 0.0
	var anim := _avatar.get_animation_player()
	var clip := anim.get_animation(_avatar.clip_name(ROLE_COLLECT))
	_clip_s = clip.length / COLLECT_RATE
	_collect_at = PlayerController.lowest_hips_time(clip) / COLLECT_RATE
	var to := target.global_position - global_position
	if Vector2(to.x, to.z).length_squared() > 0.0001:
		_facing_yaw = atan2(to.x, to.z)
		_target_yaw = _facing_yaw
		_avatar.rotation.y = _facing_yaw
	_avatar.play_pose(ROLE_COLLECT)
	anim.speed_scale = COLLECT_RATE


func _tick_collect(delta: float) -> void:
	var was := _clip_t
	_clip_t += delta
	if was < _collect_at and _clip_t >= _collect_at:
		_finish_collect()
	if _clip_t >= _clip_s:
		_stance = Stance.FOOT
		_avatar.set_locomotion(0.0)


func _finish_collect() -> void:
	var target := _collect_target
	_collect_target = null
	if is_instance_valid(target):
		var result: Variant = target.call(&"collect")
		target_collected.emit(target, result)


## Klipte kalçanın en alçak olduğu an (saniye; saf): yerden alma o anda olur.
static func lowest_hips_time(anim: Animation) -> float:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D or not String(anim.track_get_path(t).get_concatenated_subnames()).contains("Hips"):
			continue
		var best := 0.0
		var lowest := INF
		for k in anim.track_get_key_count(t):
			var y: float = (anim.track_get_key_value(t, k) as Vector3).y
			if y < lowest:
				lowest = y
				best = anim.track_get_key_time(t, k)
		return best
	return anim.length * 0.5


# --- Eller, kamera, ipucu ----------------------------------------------------------------------------

## Ellerin duruşu: "" serbest, "ride" yün, "bow" yay ve kiriş (parmaksız modelde bir şey olmaz).
func _set_hands(kind: String) -> void:
	if _hands == kind or _avatar == null:
		return
	_hands = kind
	match kind:
		"ride":
			_avatar.set_grip(&"Left", GRIP_WOOL, HAND_SECONDS)
			_avatar.set_grip(&"Right", GRIP_WOOL, HAND_SECONDS)
		"bow":
			_avatar.set_grip(&"Left", GRIP_BOW, HAND_SECONDS)
			_avatar.set_grip(&"Right", GRIP_STRING, HAND_SECONDS)
		_:
			_avatar.relax_hand(&"Left", HAND_SECONDS)
			_avatar.relax_hand(&"Right", HAND_SECONDS)


## E bir iş yapacaksa kamera E ile dönmez (godot.md §5.3: iki atama birlikte durur).
func _refresh_camera_keys() -> void:
	if camera is FollowCamera:
		(camera as FollowCamera).hold_turn_right = _active and has_interaction()


func _refresh_prompt() -> void:
	if not _active:
		_send_prompt([])
		return
	_send_prompt(prompt_pairs())


## O an yapılabilecekler: [[tuş, eylem], ...]. Yetişkinin yayı yoktur: ona yalnız binmenin ipucu çıkar.
func prompt_pairs() -> Array:
	match _stance:
		Stance.SEATED:
			return [] if carried else [["WASD", "Kalk"]]
		Stance.RIDING:
			if _mount and _mount.walks_on_input():
				# At: giriş adım, Shift tırıs ve dörtnal; dörtnalda Shift'e yeniden basmak mahmuzdur (soluğu varken).
				var pairs: Array = [["Shift", "Hızlan"]]
				if _mount.gait == Mount.Gait.GALLOP and _mount.can_spur() and not _mount.is_spurring():
					pairs.append(["Shift ×2", "Mahmuz"])
				pairs.append(["E", "İn"])
				if is_child():
					pairs.append(["Sağ tık", "Nişan"])
				return pairs
			if _mount and _mount.is_grazing():
				return [["Shift", "Dürt"], ["E", "İn"]]
			return [["Shift", "Dürt"], ["E", "İn"], ["Sağ tık", "Nişan"]]
		Stance.FOOT:
			if is_aiming():
				return [["Sol tık", "Bırak"]]
			if swim and swim.can_dive():
				return [["E", "Dal"]]
			if is_child() and pickup_in_reach():
				return [["E", "Al"]]
			var extra := external_interaction()
			if not extra.is_empty():
				return [[str(extra.get("key", "E")), str(extra.get("label", ""))]]
			if mount_in_reach():
				return [["E", "Bin"]]
			if is_child() and not _shot_once and bow_prompt:
				return [["Sağ tık", "Nişan"]]
	return []


func _on_loosed(_from: Vector3, _to: Vector3) -> void:
	_shot_once = true


func _send_prompt(pairs: Array) -> void:
	if pairs == _prompt:
		return
	_prompt = pairs
	prompt_changed.emit(pairs)
