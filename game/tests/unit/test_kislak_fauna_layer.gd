extends TestCase
## Kışlak'ın hayvan katmanı (FaunaLayer; data/maps/kislak/fauna.json; Yol Haritası animals): kare çizmeden, sahte bir dünyada (düz zemin,
## Kışlak'ın bölgesi ve ateşleri) kurulur. Bütçe (K65): ajan ≤24 (tavşanlar dahil), T0 ≤8, kuş ≤64; Ak Otlak'ta 60 at ve 200 koyun tek
## çizimli sürülerdir (iskelet yok); kurtlar gece Kurt İnleri'nde, gündüz yok; yaban hayvanı yerleşime girmez; FaunaDirector 4 Hz'de döner
## (oturum varsa 8. adımında). Ses: kurt sürüsü uluması, görünmeyen kaynağın ≥150 m kuralı, tekrar sınırı.

const FAUNA := "res://data/maps/kislak/fauna.json"
const FakeMain := preload("res://tests/support/fauna_fake_main.gd")
const FakeWorld := preload("res://tests/support/fauna_fake_world.gd")

var _trash: Array[Node] = []


func after_each() -> void:
	for n in _trash:
		if is_instance_valid(n):
			n.free()
	_trash.clear()


## Sahte ana düğüm (player, session) ve dünya (ground, spec).
func _world(minute: float = 720.0) -> Array:
	var main: Node3D = FakeMain.new()
	main.name = "FakeMain"
	add_child(main)
	_trash.append(main)
	var world: Node3D = FakeWorld.new()
	world.set("ground", HeightmapShape.new())
	var spec := MapSpec.new()
	spec.id = "kislak"
	spec.regions = [{"id": "winter_camp", "center": [0.0, 0.0], "radius": 134.54}]
	spec.structures = [{"kind": "great_hearth", "id": "great_hearth", "at": [0.0, 0.0]}, {"kind": "watch_fire", "id": "wf1", "at": [48.0, -88.0]}]
	world.set("spec", spec)
	main.add_child(world)
	var player := Node3D.new()
	player.name = "Player"
	main.add_child(player)
	main.set("player", player)
	var layer := FaunaLayer.new()
	layer.setup(world, MapLayers.read(FAUNA))
	world.add_child(layer)
	layer._local_clock = GameClock.new(1041, minute)
	return [main, world, layer, player]


func test_layer_builds_the_winter_set_within_the_budget() -> void:
	var parts := _world()
	var layer: FaunaLayer = parts[2]
	assert_eq(layer.herds.size(), 4, "Dört sürü: at, koyun, deve, sığır")
	var counts := {}
	for h in layer.herds:
		counts[h.kind_id] = h.count()
		assert_eq(h.instance.multimesh.instance_count, h.count(), "%s tek MultiMesh" % h.kind_id)
		assert_eq(h.find_children("*", "Skeleton3D", true, false).size(), 0, "Sürüde iskelet yok")
	assert_eq(counts.get("horse"), 60, "Ak Otlak'ta 60 at")
	assert_eq(counts.get("sheep"), 200, "Ak Otlak'ta 200 koyun")
	for id in ["dog", "wolf", "fox", "gazelle", "ibex", "boar", "deer"]:
		assert_true(layer.crowds.has(id), "%s için T1 kalabalığı" % id)
	assert_true(layer.bird_count() <= FaunaDirector.MAX_BIRDS, "Kuş ≤64 (%d)" % layer.bird_count())
	assert_eq(layer.bird_count(), 19 + 12 + 2, "19 karga, 12 keklik, 2 kartal")
	assert_eq(layer.small_mammals(), 5, "5 tavşan")
	assert_eq(layer.director.agent_cap, 24 - 5, "Tavşanlar ajan bütçesinden düşülür")
	assert_true(layer.director.fires.size() >= 2, "Ateşler haritanın kayıtlarından")
	assert_almost(layer.director.camp_radius, 134.54 + FaunaLayer.CAMP_MARGIN, 0.01, "Yerleşimin yasak dairesi")


func test_director_runs_at_four_hertz_and_keeps_the_caps() -> void:
	var parts := _world(1400.0)
	var layer: FaunaLayer = parts[2]
	var player: Node3D = parts[3]
	await wait_frames(2)
	# Gece, Ak Otlak: kurtlar ve sürüler.
	player.global_position = Vector3(140.0, 0.0, -360.0)
	for _k in 40:
		layer._process(0.1)
		assert_true(layer.director.agent_count() <= layer.director.agent_cap, "Ajan bütçesi")
		assert_true(layer.t0_count() <= FaunaDirector.MAX_T0, "T0 ≤8")
	assert_almost(layer.director.clock, 4.0, 0.26, "4 sn'de ≈16 tik (4 Hz)")
	var wolves := 0
	for i in layer.director.active_agents():
		if layer.director.agent_kind(i) == "wolf":
			wolves += 1
			assert_true(layer.director.pos[i].length() >= layer.director.camp_radius - 0.01, "Kurt yerleşime girmez")
	assert_between(float(wolves), 1.0, 4.0, "Gece Kurt İnleri'nde kurt var (sahnede ≤4)")
	# Gündüz kurt yoktur.
	layer._local_clock = GameClock.new(1042, 720.0)
	for _k in 40:
		layer._process(0.1)
	for i in layer.director.active_agents():
		if layer.director.agent_kind(i) == "wolf":
			assert_true(layer.director.state[i] == FaunaDirector.State.RETURN or layer.director.group_of[i] >= 0, "Kurt gündüz çekilir")


func test_voice_rules_space_repeats_and_push_unseen_voices_away() -> void:
	var rules := FaunaVoiceRules.new(FaunaBank.shared().rules())
	assert_true(rules.can_play("wolf_howl", "wolf", 0.0))
	rules.mark("wolf_howl", "wolf", 0.0)
	assert_false(rules.can_play("wolf_howl", "wolf", 30.0), "Aynı kimlik ≥45 sn")
	assert_false(rules.can_play("wolf_bark", "wolf", 10.0), "Aynı tür ≥20 sn")
	assert_true(rules.can_play("wolf_bark", "wolf", 21.0))
	assert_true(rules.can_play("wolf_howl", "wolf", 45.0))
	var near := FaunaVoiceRules.unseen_point(Vector2.ZERO, Vector2(40.0, 0.0), 150.0)
	assert_almost(near.length(), 150.0, 1e-4, "Görünmeyen ses ≥150 m'den gelir")
	assert_almost(near.normalized().x, 1.0, 1e-4, "Kaynağın yönünde")
	assert_eq(FaunaVoiceRules.unseen_point(Vector2.ZERO, Vector2(400.0, 0.0), 150.0), Vector2(400.0, 0.0), "Uzaktaki yerinde kalır")
	assert_eq(rules.horse_cluster(55.0), "horse_fear", "≤60 m kurt korku")
	assert_eq(rules.horse_cluster(200.0, 800.0), "horse_fear", "≤1 km gök gürültüsü korku")
	assert_eq(rules.horse_cluster(200.0), "horse_calm")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var calls := rules.pack_calls(rng)
	assert_between(float(calls.size()), 3.0, 5.0, "Sürü 3–5 çalış")
	for k in range(1, calls.size()):
		assert_between(calls[k].x - calls[k - 1].x, 2.0, 6.0, "2–6 sn ara")
		assert_between(calls[k].y, 0.85, 1.15, "Perde 0,85–1,15")


func test_voices_play_from_the_bank() -> void:
	var parts := _world(1400.0)
	var layer: FaunaLayer = parts[2]
	var player: Node3D = parts[3]
	await wait_frames(1)
	player.global_position = Vector3(140.0, 0.0, -360.0)
	layer._process(0.1)
	var v := layer.voices
	assert_true(v.play("gazelle", &"alarm", Vector3(300.0, 0.0, -560.0)), "Ceylan maralın tamponunu çalar")
	assert_eq(str(v.played[v.played.size() - 1]["cluster"]), "deer_bark")
	assert_false(v.play("deer", &"alarm", Vector3(600.0, 0.0, 160.0)), "Aynı küme 45 sn dolmadan çalmaz")
	assert_true(v.play("wolf", &"howl", Vector3(60.0, 0.0, -430.0), {"unseen": true}), "Uluma")
	assert_true(v.queued() >= 2, "Sürünün öteki çalışları kuyrukta")
	# Görünmeyen kaynak oyuncuya ≥150 m.
	assert_true(v.play("camel", &"call", Vector3(150.0, 0.0, -350.0), {"unseen": true}))
	var at: Vector3 = v.played[v.played.size() - 1]["at"]
	assert_true(Vector2(at.x, at.z).distance_to(Vector2(140.0, -360.0)) >= 149.9, "Görünmeyen deve ≥150 m'de")


func test_fauna_frame_cost_stays_in_the_interior_share() -> void:
	# fauna.md §10: iç haritada hayvanların GDScript payı ≤0,5 ms (kare başına). Ak Otlak'ın gecesi en ağırıdır: 260 sürü hayvanı, kurtlar,
	# tilki, ceylan; kamera oyuncunun 28 m arkasında, sürüye bakar.
	var parts := _world(1400.0)
	var world: Node3D = parts[1]
	var layer: FaunaLayer = parts[2]
	var player: Node3D = parts[3]
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 36.0
	player.global_position = Vector3(150.0, 0.0, -330.0)
	cam.global_position = player.global_position + Vector3(0.0, 17.2, 22.0)
	cam.look_at(player.global_position + Vector3(0.0, 0.7, 0.0))
	cam.make_current()
	await wait_frames(2)
	var nodes: Array[Node] = []
	for n in layer.get_children():
		nodes.append(n)
	# Isınma: grupları sahneye al, sürülerin ilk tiki.
	for _k in 30:
		_frame(layer, nodes, 1.0 / 60.0)
	var t0 := Time.get_ticks_usec()
	var frames := 240
	for _k in frames:
		_frame(layer, nodes, 1.0 / 60.0)
	var per := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	print("    hayvanların kare payı: %.3f ms (%d ajan, T0 %d, 260 sürü hayvanı)" % [per, layer.director.agent_count(), layer.t0_count()])
	# Paylaşılan makinede gürültü payıyla: hedef 0,5 ms, sınama 1,0 ms'de düşer.
	assert_true(per < 1.0, "Kare payı ≤0,5 ms hedefi (ölçülen %.3f ms)" % per)
	# Gecenin sesleri (kurttan ürken atın kişnemesi) bırakılır; ses sunucusu çalış kayıtlarını bir karışımda boşaltır, koşunun sonunda
	# «resources still in use» kalmaz.
	layer.voices.silence()
	await get_tree().create_timer(0.15).timeout


func _frame(layer: FaunaLayer, nodes: Array[Node], dt: float) -> void:
	layer._process(dt)
	for n in nodes:
		if is_instance_valid(n) and n != layer and n.has_method(&"_process"):
			n.call(&"_process", dt)
	for a in layer.t0_nodes():
		if is_instance_valid(a):
			(a as Node).call(&"_process", dt)
