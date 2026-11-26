class_name FeastWatch
extends Node3D
## Şildenin canlı sahnesi (Önsöz «Şilde Gecesi» ve «Güreş», 9 Nisan gecesi, Kayın Obası; K110; e21-atmosphere.md): yeni doğanın ilk gecelerinde
## ocak sönmez, gülüşme eksik olmaz. Burada kurulan: büyük ateş (Campfire'ın büyüğü: alev ×1,7, ışık 13 m, gölgesiz; oturanların gölgesini
## yurtlara düşüren ay yoktur, ateşin ışığı yeter), şildenin müziği (mus_shilde, ateşin yanından konumlu, yaklaşınca yükselir; feast_walk kurar,
## burada bulunur), kalabalığın uğultusu (amb_feast_crowd, r 30 m), iki çalgıcı (davulcu ve ağız kopuzcu; kalabalık ağı crowd_hun_man,
## yeniden boyalı; davulun teri kodla), tepki sözleri (BARKS: ≥45 sn arayla, oyuncu ateşin 14 m'sindeyken) ve ateşe arada atılan dal
## (bark_2 ile kıvılcım). Kişilerin kendisi (Saruk, Künay, Tonga, Börü, obanın halkı, aile) koşucunundur (PrologueCast); bu düğüm onlara iş verir.
##   var w := FeastWatch.new(); world.add_child(w); w.setup(step, fire_pos, fn_say)
##   w.tick(delta, player_pos)

const MUSIC_NODE := "E21ShildeMusic"
const SHILDE_PLACEHOLDER := "res://audio/ambience/gen/shilde_drum_jaw.wav"
## Şildenin müziğinin duyulduğu en uzak yer (m; Göl Obası ≈350 m) ve düzeyi (dB).
const MUSIC_REACH := 420.0
const MUSIC_DB := 2.0
const CROWD_PLACEHOLDER := "res://audio/ambience/campfire_loop.wav"
## Büyük ateşin ölçüsü.
const FIRE_FLAME := 1.7
const FIRE_RANGE := 13.0
const FIRE_ENERGY := 4.2
## Tepki sözleri: [satır, konuşan]; aynı söz bir kez, aralar ≥45 sn (SceneVoice.COOLDOWN).
const BARKS := [["act0.feast.bark_1", "folk_man"], ["act0.feast.song", "folk_woman"], ["act0.feast.old_man", "folk_man"],
	["act0.feast.bark_2", "folk_woman"]]
const BARK_GAP := 45.0
const BARK_FIRST := 12.0
const BARK_NEAR := 14.0
## Çalgıcılar: [kimlik (Folk tohumu), beden, ateşe göre açı (derece), uzaklık (m), iş (kütüphane klibi)]. Görünüş Folk'tandır (Hun halkı,
## kasabalı rolü: kalabalık ağı ve giysinin boyası; K89), davulcunun kucağında kodla çizilen çerçeve davul.
const PLAYERS := [
	["shilde_drummer", "male", 205.0, 3.4, "sitting_clap"],
	["shilde_jaw", "male", 235.0, 3.5, "sit_and_drink"],
]

var fire_at := Vector3.ZERO
var say_fn: Callable
## Koşucunun sesi (yatakların ortak sınırı: en çok 3; e21-atmosphere.md); yoksa kendi konumlu yatağı.
var sound: PrologueSound
var fire: Campfire
var crowd_bed: AudioStreamPlayer3D
var musicians: Array[CharacterAvatar] = []
## Ateşe atılan dal: söz bark_2 gelince kıvılcım patlaması (yalnız görünüş).
var spark_burst_t := 0.0

var _bark_i := 0
var _bark_left := BARK_FIRST
var _own_fire := false
var _saved_fire := {}


## Şildenin müziği (parent'ın altında adıyla bulunur).
static func music_node(parent: Node) -> AudioStreamPlayer3D:
	return parent.get_node_or_null(NodePath(MUSIC_NODE)) as AudioStreamPlayer3D if parent else null


## Şildenin müziği: Kayın Obası'nın ateşinden konumlu (Music yolu), uzakta kısık ve boğuk, yaklaşınca yükselir; yoksa kurulur ve açılır
## (dosyası yoksa kodla basılan shilde_drum_jaw döngüsü).
static func ensure_music(parent: Node, fire_at: Vector3) -> AudioStreamPlayer3D:
	if parent == null:
		return null
	var m := FeastWatch.music_node(parent)
	if m == null:
		m = E21Sound.bed("mus_shilde", SHILDE_PLACEHOLDER, MUSIC_REACH, MUSIC_DB, &"Music")
		if m == null:
			return null
		m.name = MUSIC_NODE
		m.unit_size = 18.0
		m.attenuation_filter_cutoff_hz = 2400.0
		m.attenuation_filter_db = -24.0
		parent.add_child(m)
		m.global_position = fire_at + Vector3(0.0, 1.2, 0.0)
	if not m.playing or m.volume_db < MUSIC_DB - 1.0:
		E21Sound.fade_in(m, 4.0)
	return m


## Dünyadaki şilde sahnesi (yoksa kurulur): adımlar (feast_walk, feast_roam, wrestle_ring, feast_home) aynı düğümü paylaşır; geliştirmede
## ortadaki bir adımdan açılınca da kurulur. say: satır kimliği → sn (adımın söz çağrısı).
static func ensure(parent: Node, p_fire_at: Vector3, p_say: Callable, p_sound: PrologueSound = null) -> FeastWatch:
	if parent == null:
		return null
	# Yeni doğanın ilk gecelerinde ocak sönmez: obanın açık yurtlarının ocağı yanar (kapılar aydınlık; Künay'ın «kara yurdu» da).
	var places := parent.find_child("PrologueWorld", false, false) as PrologueWorld
	if places:
		for id in ["kunay", "saruk", "birch_3"]:
			places.set_yurt_hearth(id, true)
	FeastWatch.ensure_music(parent, p_fire_at)
	var found := parent.get_node_or_null(^"ShildeWatch") as FeastWatch
	if found:
		found.say_fn = p_say
		return found
	var w := FeastWatch.new()
	w.name = "ShildeWatch"
	w.sound = p_sound
	parent.add_child(w)
	var existing: Campfire = null
	if parent.is_inside_tree():
		for n in parent.get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
			if n is Campfire and (n as Campfire).global_position.distance_to(p_fire_at) < 1.5:
				existing = n
				break
	w.setup(p_fire_at, p_say, existing)
	return w


func _ready() -> void:
	name = "ShildeWatch" if name.is_empty() else name


## Kurulum: ateşin yeri, söz çağrısı (satır kimliği → sn). existing_fire: obanın açık ocağı varsa o büyütülür (sonunda geri yazılır).
func setup(p_fire_at: Vector3, p_say: Callable, existing_fire: Campfire = null) -> void:
	fire_at = p_fire_at
	say_fn = p_say
	_build_fire(existing_fire)
	if sound:
		sound.bed("amb_feast_crowd", true, -2.0, 3.0, fire_at, 30.0)
	else:
		crowd_bed = E21Sound.bed("amb_feast_crowd", CROWD_PLACEHOLDER, 30.0, -2.0)
		if crowd_bed:
			add_child(crowd_bed)
			crowd_bed.global_position = fire_at + Vector3(0.0, 1.0, 0.0)
			E21Sound.fade_in(crowd_bed, 3.0)
	_build_players()


## Çalgıcıların modeli yüklendi mi?
func is_ready() -> bool:
	for a in musicians:
		if a.get_skeleton() == null:
			return false
	return true


func _build_fire(existing: Campfire) -> void:
	if existing:
		fire = existing
		_saved_fire = {"flame_scale": existing.flame_scale, "light_range": existing.light_range, "light_energy": existing.light_energy}
	else:
		fire = Campfire.new()
		fire.name = "ShildeFire"
		_own_fire = true
		add_child(fire)
		fire.global_position = fire_at
	fire.light_range = FIRE_RANGE
	fire.light_energy = FIRE_ENERGY
	fire.flame_scale = FIRE_FLAME


func _build_players() -> void:
	var allocator := ClipVariety.Allocator.new()
	for row: Array in PLAYERS:
		var look := Folk.make("prologue:shilde:" + str(row[0]), {"role": "townsfolk", "people": "hun", "body": str(row[1])})
		look["id"] = str(row[0])
		var av := CharacterAvatar.new()
		av.name = str(row[0]).to_pascal_case()
		av.start_pose = &"sit"
		Folk.prepare(av, look, allocator)
		add_child(av)
		var ang := deg_to_rad(float(row[2]))
		var at := fire_at + Vector3(cos(ang), 0.0, sin(ang)) * float(row[3])
		av.global_position = at
		av.rotation.y = atan2(fire_at.x - at.x, fire_at.z - at.z)
		av.set_meta(&"work", str(row[4]))
		musicians.append(av)
		av.model_changed.connect(func(_id: String) -> void: _start_player(av))
		_start_player.call_deferred(av)


func _start_player(av: CharacterAvatar) -> void:
	if not is_instance_valid(av):
		return
	if av.get_skeleton() == null:
		return
	av.play_job(str(av.get_meta(&"work", "sit")))
	if str(av.name).contains("Drummer") and av.get_node_or_null(^"FrameDrum") == null:
		_add_drum(av)


## Çerçeve davulu (kodla): kucakta yan duran deri daire ve kasnak.
func _add_drum(a: Node3D) -> void:
	var drum := MeshInstance3D.new()
	drum.name = "FrameDrum"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.24
	mesh.bottom_radius = 0.24
	mesh.height = 0.06
	mesh.radial_segments = 20
	drum.mesh = mesh
	drum.material_override = Style.toon(Color(0.78, 0.66, 0.48), {"brush_strength": 0.2})
	a.add_child(drum)
	drum.position = Vector3(0.0, 0.55, 0.32)
	drum.rotation = Vector3(deg_to_rad(70.0), 0.0, 0.0)


func tick(delta: float, player_at: Vector3) -> void:
	spark_burst_t = maxf(spark_burst_t - delta, 0.0)
	if _bark_i >= BARKS.size() or not say_fn.is_valid():
		return
	if Vector2(player_at.x - fire_at.x, player_at.z - fire_at.z).length() > BARK_NEAR:
		return
	_bark_left -= delta
	if _bark_left > 0.0:
		return
	var row: Array = BARKS[_bark_i]
	_bark_i += 1
	_bark_left = BARK_GAP
	say_fn.call(str(row[0]))
	if str(row[0]) == "act0.feast.bark_2":
		_throw_branch()


## «Ocağa bir dal daha!»: ateşe dal atılır, kıvılcım yükselir.
func _throw_branch() -> void:
	spark_burst_t = 1.2
	var p := Fx.embers(30)
	p.one_shot = true
	p.explosiveness = 0.9
	add_child(p)
	p.global_position = fire_at + Vector3(0.0, 0.4, 0.0)
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)


## Söylenen tepki sözü sayısı (sınama).
func barks_said() -> int:
	return _bark_i


## Ateşi eski hâline döndürür (obanın ocağı büyütüldüyse), sesleri söndürür.
func teardown() -> void:
	if not _own_fire and is_instance_valid(fire) and not _saved_fire.is_empty():
		fire.light_range = float(_saved_fire["light_range"])
		fire.light_energy = float(_saved_fire["light_energy"])
		fire.flame_scale = float(_saved_fire["flame_scale"])
	if sound:
		sound.bed("amb_feast_crowd", false, 0.0, 2.0)
	if crowd_bed:
		E21Sound.fade_out(crowd_bed, 2.0)
