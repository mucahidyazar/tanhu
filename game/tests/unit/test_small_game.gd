extends TestCase
## Küçük av (SmallGame, SmallGameField, FaunaKind, FaunaMesh; story.md §5, fauna.md §1, §10): katalog, kodla çizilen ağlar, hedef sözleşmesi (targets grubu,
## hit, düşme, collect), kaçış, inler ve boştayken kare başına iş yapmama. Yay ayrı işin: burada hit(point) doğrudan çağrılır.

const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const STEP := 1.0 / 30.0
const SMALL_KINDS: Array[String] = ["lark", "partridge", "crow", "marmot", "gerbil"]

var _trash: Array[Node] = []
var _shape: OrdosGround


func before_each() -> void:
	_shape = OrdosGround.new(OrdosWorld.load_layout(LAYOUT))


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Katalog ----------------------------------------------------------------------------------------

func test_catalog_matches_fauna_md() -> void:
	var sheep := FaunaKind.named("sheep")
	assert_not_null(sheep, "Koyun katalogda")
	if sheep == null:
		return
	assert_eq(sheep.plan, "bovid_s")
	assert_almost(sheep.speed("trot"), 2.5, 0.001, "fauna.md §1: tırıs 2,5")
	assert_almost(sheep.speed("gallop"), 5.5, 0.001, "fauna.md §1: dörtnal 5,5")
	assert_eq(sheep.hp, 16)
	assert_almost(sheep.shoulder, 0.75, 0.001, "fauna.md §10: omuz 0,75")
	assert_almost(sheep.stride("trot"), 1.19, 0.001, "fauna.md §10: adım")
	assert_eq(sheep.max_triangles(), 1800, "army.md §7.1: T1 ≤1.800 üçgen")
	var marmot := FaunaKind.named("marmot")
	assert_almost(marmot.speed("flee"), 4.0, 0.001, "fauna.md §1: tarbagan tepe 4")
	assert_almost(marmot.speed("sustained"), 2.0, 0.001, "fauna.md §1: sürek 2")
	assert_eq(marmot.hp, 10)
	assert_eq(FaunaKind.named("crow").hp, 1)
	assert_eq(FaunaKind.named("partridge").hp, 4)
	assert_eq(int((FaunaKind.named("crow").def["yield"] as Dictionary)["feather"]), 1, "Karganın 1 tüyü")
	for id in SMALL_KINDS:
		var kind := FaunaKind.named(id)
		assert_not_null(kind, "%s katalogda" % id)
		assert_true(float(kind.game_value("hit_radius", 0.0)) > 0.2, "%s vurulabilir boyda" % id)
		assert_true(str(kind.game_value("mode", "")) in ["fly", "burrow"], "%s kaçış biçimi" % id)
		assert_true(kind.def.has("name"), "%s adı" % id)
	assert_eq(FaunaKind.named("sheep").model_path(), "res://assets/animals/sheep/sheep.glb")
	expect_errors(PackedStringArray())


func test_story_targets_exist_in_the_layout() -> void:
	# story.md §5: çayırda iki tarla kuşu ve bir fare; fauna.md: keklik, karga, tarbagan.
	var groups: Array = OrdosWorld.load_layout(LAYOUT)["childhood"]["game"]["groups"]
	var counts := {}
	for g: Dictionary in groups:
		counts[str(g["kind"])] = int(g["count"])
	assert_true(int(counts.get("lark", 0)) >= 2, "En az iki tarla kuşu")
	assert_true(int(counts.get("gerbil", 0)) >= 1, "En az bir fare")
	assert_true(counts.has("partridge") and counts.has("crow") and counts.has("marmot"), "Keklik, karga, tarbagan")
	var total := 0
	for k: String in counts:
		total += int(counts[k])
	assert_true(total <= 24, "İç harita: hayvan ajanı ≤24 (%d)" % total)


# --- Ağlar ------------------------------------------------------------------------------------------

func test_drawn_meshes_fit_their_budgets() -> void:
	# fauna.md §10: küçük memeli ≤1,2k üçgen; kuş programatik; sürünün T1'i ≤1.800.
	for id: String in SMALL_KINDS + ["sheep"]:
		var data := FaunaMesh.arrays(id)
		assert_false(data.is_empty(), "%s çizilir" % id)
		if data.is_empty():
			continue
		var indices: PackedInt32Array = data["indices"]
		var limit := 1800 if id == "sheep" else 1200
		assert_true(indices.size() / 3 <= limit, "%s ≤%d üçgen (%d)" % [id, limit, indices.size() / 3])
		var points: PackedVector3Array = data["vertices"]
		assert_eq((data["colors"] as PackedColorArray).size(), points.size(), "%s köşe rengi" % id)
		assert_eq((data["custom"] as PackedFloat32Array).size(), points.size() * 4, "%s parça bilgisi" % id)
		var box := AABB(points[0], Vector3.ZERO)
		for p in points:
			box = box.expand(p)
		assert_almost(box.position.y, 0.0, 0.06, "%s tabanı yerde (%.3f)" % [id, box.position.y])
		print("    [fauna] %s: %d üçgen, boy %.2f m, yükseklik %.2f m" % [id, indices.size() / 3, box.size.z, box.size.y])
		assert_true(box.end.z > -box.position.z * 0.45, "%s başı +Z'de" % id)
	var sheep := FaunaMesh.arrays("sheep")
	var box := AABB((sheep["vertices"] as PackedVector3Array)[0], Vector3.ZERO)
	for p: Vector3 in sheep["vertices"]:
		box = box.expand(p)
	assert_between(box.size.z, 1.05, 1.25, "Koyunun boyu (%.2f m)" % box.size.z)
	assert_between(box.size.y, 0.9, 1.08, "Koyunun yüksekliği (%.2f m)" % box.size.y)
	assert_eq(FaunaMesh.arrays("yok"), {}, "Bilinmeyen tür boş")


func test_blob_faces_outward() -> void:
	# Godot'da ön yüz dışarıdan saat yönündedir: (c − a) × (b − a) dışa bakar (MeshKit).
	var d := FaunaMesh.Draft.new()
	d.blob(Vector3(1.0, 2.0, 3.0), Vector3(0.5, 0.3, 0.7), Basis(Vector3.UP, 0.7), 1, Color.WHITE, Vector4.ZERO, 0.05, 3)
	for k in range(0, d.indices.size(), 3):
		var a := d.vertices[d.indices[k]]
		var b := d.vertices[d.indices[k + 1]]
		var c := d.vertices[d.indices[k + 2]]
		var mid := (a + b + c) / 3.0 - Vector3(1.0, 2.0, 3.0)
		assert_true((c - a).cross(b - a).dot(mid) > 0.0, "Üçgen %d dışa bakar" % (k / 3))
	var t := FaunaMesh.Draft.new()
	t.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.0, 1.0, 0.0)]), PackedFloat32Array([0.1, 0.1]), 6, Color.WHITE, Vector4.ZERO)
	for k in range(0, t.indices.size(), 3):
		var a := t.vertices[t.indices[k]]
		var b := t.vertices[t.indices[k + 1]]
		var c := t.vertices[t.indices[k + 2]]
		var mid := (a + b + c) / 3.0 - Vector3(0.0, 0.5, 0.0)
		assert_true((c - a).cross(b - a).dot(mid) > 0.0, "Boru üçgeni %d dışa bakar" % (k / 3))


# --- Hedef sözleşmesi --------------------------------------------------------------------------------

func test_targets_group_and_hit_contract() -> void:
	var field := _field()
	var lark: SmallGame = field.of_kind("lark")[0]
	assert_true(lark.is_in_group(&"targets"), "Hedef «targets» grubunda")
	assert_true(lark.is_hittable())
	assert_false(lark.is_down())
	assert_false(lark.collected)
	assert_true(lark.hit_radius > 0.2, "Vuruş yarıçapı")
	assert_almost(lark.hit_center().y, lark.global_position.y + lark.body_height, 0.001, "Vuruş küresi gövdede")
	var fell := watch_signal(lark.fell)
	assert_true(lark.hit(lark.hit_center() + Vector3(0.1, 0.0, 0.0)), "Vuruş sayılır")
	assert_false(lark.is_in_group(&"targets"), "Vurulan gruptan çıkar")
	assert_true(lark.is_in_group(&"fallen_game"), "Düşen hedef «fallen_game»de")
	assert_false(lark.is_hittable(), "Vurulan bir daha vurulamaz")
	assert_false(lark.hit(lark.global_position), "İkinci ok sayılmaz")
	_run(field, 3.0)
	assert_true(fell.fired, "fell yayılır")
	assert_true(lark.is_down(), "Yerde")
	assert_almost(lark.global_position.y, _shape.height_at(lark.global_position.x, lark.global_position.z), 0.02, "Zeminde")
	# Almak.
	var picked := watch_signal(lark.picked_up)
	var result := lark.collect()
	assert_eq(str(result.get("kind", "")), "lark", "collect türü söyler")
	assert_true((result.get("yield", {}) as Dictionary).has("meat_small"), "collect verimi söyler")
	assert_true(lark.collected, "collected")
	assert_true(picked.fired, "picked_up yayılır")
	assert_false(lark.visible, "Alınan görünmez")
	assert_false(lark.is_in_group(&"fallen_game"), "Alınan gruptan çıkar")
	assert_eq(lark.collect(), {}, "İki kez alınmaz")
	assert_eq(field.collected_count("lark"), 1)


func test_collect_refuses_a_living_target() -> void:
	var field := _field()
	var crow: SmallGame = field.of_kind("crow")[0]
	assert_eq(crow.collect(), {}, "Ayaktaki av alınmaz")
	assert_false(crow.collected)


func test_bird_hit_in_flight_falls_to_the_ground() -> void:
	var field := _field()
	var crow: SmallGame = field.of_kind("crow")[0]
	crow.startle(crow.global_position + Vector3(1.0, 0.0, 0.0))
	assert_eq(crow.state, SmallGame.State.FLIGHT, "Karga havalanır")
	_run(field, 0.8)
	var ground := _shape.height_at(crow.global_position.x, crow.global_position.z)
	assert_true(crow.global_position.y > ground + 1.0, "Havada (%.2f m)" % (crow.global_position.y - ground))
	assert_true(crow.is_hittable(), "Uçarken vurulabilir")
	assert_true(crow.hit(crow.hit_center()), "Uçarken vurulur")
	_run(field, 4.0)
	assert_true(crow.is_down(), "Düşer")
	assert_almost(crow.global_position.y, _shape.height_at(crow.global_position.x, crow.global_position.z), 0.02, "Zemine iner")


func test_startle_flies_to_another_patch_and_lands() -> void:
	var field := _field()
	var lark: SmallGame = field.of_kind("lark")[0]
	var alarmed := watch_signal(lark.alarmed)
	lark.startle(lark.global_position)
	assert_true(alarmed.fired, "alarmed yayılır")
	assert_eq(lark.state, SmallGame.State.FLIGHT)
	_run(field, 16.0)
	assert_true(lark.state <= SmallGame.State.WALK, "Konar")
	_assert_in_patches(lark)


func test_flock_rises_together() -> void:
	# fauna.md §1: keklik toplu havalanır.
	var field := _field()
	var flock := field.of_kind("partridge")
	assert_true(flock.size() >= 2)
	for a in flock:
		a.global_position = flock[0].global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	flock[0].startle(flock[0].global_position)
	for a in flock:
		assert_eq(a.state, SmallGame.State.FLIGHT, "Küme birlikte havalanır")


func test_threat_scares_each_kind_at_its_distance() -> void:
	var field := _field()
	var threat := Node3D.new()
	add_child(threat)
	_trash.append(threat)
	field.set_threat(threat)
	var marmot: SmallGame = field.of_kind("marmot")[0]
	var scare := float(marmot.kind.game_value("scare_radius"))
	threat.global_position = marmot.global_position + Vector3(scare + 2.0, 0.0, 0.0)
	_run(field, 0.5)
	assert_true(marmot.state <= SmallGame.State.WALK, "Uzaktaki tehdit ürkütmez")
	threat.global_position = marmot.global_position + Vector3(scare - 1.0, 0.0, 0.0)
	_run(field, 0.5)
	assert_true(marmot.state == SmallGame.State.RUN or marmot.state == SmallGame.State.HIDDEN, "Yakındaki tehdit kaçırır (%d)" % marmot.state)


func test_burrow_hides_and_emerges() -> void:
	var field := _field()
	var marmot: SmallGame = field.of_kind("marmot")[0]
	marmot.startle(marmot.global_position)
	assert_eq(marmot.state, SmallGame.State.RUN, "İne koşar")
	assert_true(marmot.is_hittable(), "Koşarken vurulabilir")
	_run(field, 20.0, func() -> bool: return marmot.state == SmallGame.State.HIDDEN)
	assert_eq(marmot.state, SmallGame.State.HIDDEN, "İne girer")
	assert_false(marmot.visible, "İnde görünmez")
	assert_false(marmot.is_hittable(), "İnde vurulamaz")
	assert_false(marmot.hit(marmot.global_position), "İnde ok değmez")
	var at := Vector2(marmot.global_position.x, marmot.global_position.z)
	var nearest := INF
	for h in marmot.holes:
		nearest = minf(nearest, at.distance_to(h))
	assert_true(nearest < 0.1, "İn ağzında (%.2f m)" % nearest)
	_run(field, 20.0, func() -> bool: return marmot.state != SmallGame.State.HIDDEN)
	assert_true(marmot.visible and marmot.is_hittable(), "Çıkar")


func test_idle_animals_cost_nothing_per_frame() -> void:
	var field := _field()
	await wait_frames(2)
	for a in field.animals():
		assert_false(a.is_processing(), "%s kendi _process'ini koşmaz" % a.name)
	assert_true(field._active.size() <= field.animals().size(), "Etkin liste")
	field.set_process(false)
	field._active.clear()
	var started := Time.get_ticks_usec()
	for i in 600:
		field._clock += STEP
		field._think()
		field._active.clear()
	var ms := float(Time.get_ticks_usec() - started) / 600.0 / 1000.0
	print("    [game] karar turu %.3f ms (22 hayvan, 5 Hz; kareye düşen ≈%.3f ms)" % [ms, ms * THINK_RATIO])
	assert_true(ms * THINK_RATIO <= 0.1, "Kararların kare payı küçük (%.3f ms)" % (ms * THINK_RATIO))


func test_foraging_stays_on_the_patches_and_on_the_ground() -> void:
	var field := _field()
	_run(field, 60.0)
	for a in field.animals():
		if a.state == SmallGame.State.HIDDEN:
			continue
		var at := a.global_position
		if a.state <= SmallGame.State.WALK:
			assert_almost(at.y, _shape.height_at(at.x, at.z), 0.12, "%s yerde" % a.name)
			_assert_in_patches(a)


func test_field_helpers() -> void:
	var field := _field()
	assert_eq(field.animals().size(), 21, "Düzendeki hayvan sayısı")
	assert_eq(field.of_kind("lark").size(), 5)
	var first := field.first_alive("gerbil")
	assert_not_null(first, "first_alive")
	first.hit(first.global_position)
	assert_ne(field.first_alive("gerbil"), first, "Vurulan atlanır")
	_run(field, 3.0)
	assert_eq(field.nearest_fallen(first.global_position, 1.0), first, "nearest_fallen")
	assert_null(field.nearest_fallen(first.global_position + Vector3(50.0, 0.0, 0.0), 1.0), "Uzakta yok")
	var fell := [0]
	field.target_collected.connect(func(_t: SmallGame) -> void: fell[0] += 1)
	first.collect()
	assert_eq(fell[0], 1, "target_collected yayılır")
	assert_eq(field.collected_count(), 1)
	# Iska yakına düştü.
	var lark: SmallGame = field.of_kind("lark")[0]
	field.startle_near(lark.global_position, 2.0)
	assert_eq(lark.state, SmallGame.State.FLIGHT, "startle_near ürkütür")


func test_burrows_are_drawn_once() -> void:
	var field := _field()
	var burrows := field.get_node_or_null(^"Burrows") as MeshInstance3D
	assert_not_null(burrows, "İn tümsekleri tek ağ")
	assert_eq(burrows.mesh.get_surface_count(), 1)


# --- Yardımcılar ------------------------------------------------------------------------------------

## Karar sıklığının kareye oranı (5 Hz, 60 kare).
const THINK_RATIO := 5.0 / 60.0


func _field() -> SmallGameField:
	var field := SmallGameField.new()
	field.setup(OrdosWorld.load_layout(LAYOUT)["childhood"]["game"], _shape)
	add_child(field)
	_trash.append(field)
	field.set_process(false)
	return field


## Sürücüyü elle ilerletir (kare beklemez); until verilirse doğru dönünce durur.
func _run(field: SmallGameField, seconds: float, until: Variant = null) -> void:
	var t := 0.0
	while t < seconds:
		field._process(STEP)
		t += STEP
		if until is Callable and bool((until as Callable).call()):
			return


func _assert_in_patches(a: SmallGame) -> void:
	var at := Vector2(a.global_position.x, a.global_position.z)
	var inside := false
	for c in a.patches:
		if at.distance_to(Vector2(c.x, c.y)) <= c.z + 0.05:
			inside = true
	for h in a.holes:
		if at.distance_to(h) < 1.0:
			inside = true
	assert_true(inside, "%s ev lekesinde (%s)" % [a.name, at])
