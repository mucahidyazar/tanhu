extends TestCase
## Serbest Gez'in kamp günü (CampLife; roam-camp-life; time.md §8.2, §8.3; structures.md §11.6; K50, K52, K83, K106): ustalar Serbest Gez
## açıldıktan 8 oyun dk sonra (14:54) iner; yardımsız ilk duman 05:48 şafakta (aile yatar, satır dawn), bütün yardımla 03:43 gece (aile
## ateş başında bekler, satır night); şantiye kaydı gidip gelir ve aile kuralının kararı yeniden verilmez; görünüm yalnız Serbest Gez'dedir,
## end() kaldırır, çayırı geri koyar; ocak halkı ateş saatlerine uyar; ocak yanana dek sert hava yoktur.

const DAY := GameClock.ROAM_DAY
## Serbest Gez'in açılış dakikası (14:46,2) ve ustaların inişi.
const OPEN := 886.2
const ARRIVE := 894.2


class FakeJourney extends RefCounted:
	var blocks := {}
	var live_blocks: Variant = null
	var pending_blocks := {}


var _cards: Array = []


func before_each() -> void:
	Labour.reset_cache()
	SiteState.reset_cache()
	_cards.clear()


func _abs(day_min: float) -> float:
	return float(DAY) * 1440.0 + day_min


## Sahte kamp: Camp altında kova, odunluk, ateş; Meadow altında yurdun yerinde ve uzakta birer çimen örneği.
func _world() -> Node3D:
	var w := Node3D.new()
	w.name = "FakeWorld"
	var camp := Node3D.new()
	camp.name = "Camp"
	w.add_child(camp)
	for pair: Array in [["Bucket", Vector3(4.89, 0.0, -0.3)], ["WoodPile", Vector3(2.46, 0.0, -10.3)], ["Campfire", Vector3.ZERO]]:
		var n := Node3D.new()
		n.name = str(pair[0])
		n.position = pair[1]
		camp.add_child(n)
	var meadow := Node3D.new()
	meadow.name = "Meadow"
	w.add_child(meadow)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 2
	mm.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(4.5, 0.0, -18.5)))
	mm.set_instance_transform(1, Transform3D(Basis.IDENTITY, Vector3(-10.0, 0.0, 10.0)))
	mmi.multimesh = mm
	meadow.add_child(mmi)
	add_child(w)
	return w


func _life(w: Node3D, clock: GameClock, j: Object = null) -> CampLife:
	var life := CampLife.new()
	add_child(life)
	life.use_clock(clock)
	life.card = func(text: String, _sec: float) -> void: _cards.append(text)
	var p := Node3D.new()
	p.name = "FakePlayer"
	w.add_child(p)
	p.position = Vector3(40.0, 0.0, 40.0)
	life.begin(w, p, j)
	return life


func _go(life: CampLife, clock: GameClock, day_min: float) -> void:
	clock.set_to(_abs(day_min))
	life.session_step(0.0)


func test_arrival_and_unaided_smoke_at_dawn() -> void:
	var clock := GameClock.new(DAY, OPEN)
	var w := _world()
	var life := _life(w, clock)
	assert_null(life.site, "Ustalar daha inmedi")
	assert_almost(float(life.pending["start"]), _abs(ARRIVE), 1e-4, "İniş 20 gerçek sn (8 oyun dk) sonra: 14:54")
	assert_false(life.structure_done("camp3"), "Ocak yanmadı")
	var root := w.get_node_or_null(^"Camp/Camp3")
	assert_not_null(root, "Görünüm Camp/Camp3 altında")
	assert_eq(root.find_children("*", "CharacterAvatar", true, false).size(), 3, "Üç usta")
	assert_eq(str(life.builder_goal("oktar", clock.abs_minute()).get("kind")), "hidden", "İnişten 4 dk öncesine dek ustalar yok")
	_go(life, clock, ARRIVE - 2.0)
	assert_eq(str(life.builder_goal("oktar", clock.abs_minute()).get("kind")), "arrive", "Ustalar usta girişinden iner")
	_go(life, clock, ARRIVE + 1.0)
	assert_not_null(life.site, "Şantiye başladı")
	assert_eq(str(life.builder_goal("erka", clock.abs_minute()).get("kind")), "work", "Erka zeminde")
	assert_eq(str(life.builder_goal("dengiz", clock.abs_minute()).get("kind")), "trip", "Dengiz kovaya gider (Çocuk su getirmedi)")
	_go(life, clock, 1365.0)
	assert_true(life.folk_at_fire("Elder", clock.abs_minute()), "camp3 gecesi Ozan 23:00'e dek ateş başında")
	assert_false(life.folk_at_fire("OlderBrother", clock.abs_minute()), "Ağabey 22:30'da yatar")
	_go(life, clock, 1410.0)
	assert_eq(life.site.opts.get("family_wait"), false, "23:00'te aşama 4'ün altında: aile yatar")
	assert_false(life.folk_at_fire("Mother", clock.abs_minute()), "Ana 23:30'da yatmış")
	_go(life, clock, 1440.0 + 400.0)
	assert_true(life.site.is_done(), "Yurt bitti")
	assert_almost(fposmod(life.site.finished_at, 1440.0), 348.2, 1.01, "Yardımsız ilk duman 05:48, şafakta")
	assert_true(life.structure_done("camp3"), "Ocak yandı: hava açılır")
	assert_eq(SiteRules.family_saw_smoke(life.site), false, "Satır lines.dawn")
	assert_eq(_cards.size(), 1, "Kart bir kez: Yeni yurt kuruldu")
	assert_true(life.told)
	assert_true(life.folk_at_fire("Mother", clock.abs_minute()), "Ana 05:00'ten ateş başında (sabah aşı)")
	life.end(0.0)
	await wait_frames(1)
	w.queue_free()
	life.queue_free()
	await wait_frames(1)


func test_full_help_smokes_at_night_and_family_waits() -> void:
	var clock := GameClock.new(DAY, OPEN)
	var w := _world()
	var life := _life(w, clock)
	var p := w.get_node(^"FakePlayer") as Node3D
	p.position = Vector3(4.6, 0.0, -0.6)
	assert_eq(str(life.interaction().get("label", "")), "Su Getir (0/2)" if life.lang == "tr" else "Bring Water (0/2)", "Kovada E: su (iniş öncesi)")
	life.take_carry("water")
	life.drop_carry()
	life.take_carry("water")
	life.drop_carry()
	life.pending["child"]["logs"] = 4
	life.pending["child"]["ember"] = 1
	_go(life, clock, ARRIVE + 0.5)
	assert_eq(int(life.site.child.get("water", 0)), 2, "İki kova önceden yığında")
	p.position = Vector3(0.8, 0.0, -10.8)
	assert_eq(str(life.interaction().get("label", "")), "Ustalara Katıl (yarım el)" if life.lang == "tr" else "Join the Builders (half a hand)",
		"Yığının yanında E: katıl")
	life.join()
	assert_true(life.joined and bool(life.site.child["joined"]), "Çocuk ustalara katıldı (yarım el)")
	assert_ne(str(life.builder_goal("dengiz", clock.abs_minute()).get("kind")), "trip", "Kova yığında: Dengiz suya gitmez")
	_go(life, clock, 1410.0)
	assert_eq(life.site.opts.get("family_wait"), true, "23:00'te uuk bitmiş: aile ilk dumana dek bekler (K83)")
	assert_true(life.folk_at_fire("Elder", clock.abs_minute()), "Ozan ateş başında bekler")
	assert_false(life.folk_at_fire("OlderBrother", clock.abs_minute()), "Ağabey yine yatar")
	_go(life, clock, 1440.0 + 300.0)
	assert_true(life.site.is_done(), "Yurt bitti")
	assert_almost(fposmod(life.site.finished_at, 1440.0), 223.0, 1.5, "Bütün yardımla ilk duman 03:43, gece")
	assert_eq(SiteRules.family_saw_smoke(life.site), true, "Satır lines.night")
	life.end(0.0)
	await wait_frames(1)
	w.queue_free()
	life.queue_free()
	await wait_frames(1)


func test_save_round_trip_keeps_family_decision() -> void:
	var clock := GameClock.new(DAY, OPEN)
	var w := _world()
	var j := FakeJourney.new()
	j.blocks["sites"] = {"zones": {"other_zone": {"sites": {"x": {"step": 1}}}}}
	var life := _life(w, clock, j)
	_go(life, clock, 1415.0)
	var blk := life.to_block()
	assert_eq(SiteState.validate_save_block(blk), "", "Blok denetimden geçer")
	assert_true(var_to_str(blk).length() < 2048, "camp3 ≤2 KB")
	life.store_into(j)
	var stored: Dictionary = j.blocks["sites"]
	assert_true((stored["zones"] as Dictionary).has("tanhu_camp"), "camp3 zonda")
	var step := life.site.step
	var stage := life.site.stage
	life.end(0.0)
	await wait_frames(1)
	life.queue_free()
	# Yeni oturum: kayıttan.
	var again := _life(w, clock, j)
	assert_not_null(again.site, "Şantiye kayıttan")
	assert_eq(again.site.step, step)
	assert_eq(again.site.stage, stage)
	assert_eq(again.site.opts.get("family_wait"), false, "Aile kuralının kararı kayıttan")
	assert_almost(float(again.site.gates.get("y_ocak", 0.0)), _abs(1440.0 + 300.0), 1e-3, "Ocak 05:00'i bekler")
	_go(again, clock, 1440.0 + 10.0)
	assert_eq(again.site.opts.get("family_wait"), false, "23:00 denetimi yeniden çalışmadı")
	_go(again, clock, 1440.0 + 400.0)
	assert_almost(fposmod(again.site.finished_at, 1440.0), 348.2, 1.01, "Kayıttan sonra da 05:48")
	var out := again.to_block()
	assert_true(((out["zones"] as Dictionary).get("other_zone", {}) as Dictionary).has("sites"), "Öteki zonlar taşınır")
	again.end(0.0)
	await wait_frames(1)
	w.queue_free()
	again.queue_free()
	await wait_frames(1)


func test_view_only_in_roam_and_grass_restored() -> void:
	var clock := GameClock.new(DAY, OPEN)
	var w := _world()
	var mm := (w.get_node(^"Meadow").get_child(0) as MultiMeshInstance3D).multimesh
	var before := mm.get_instance_transform(0)
	assert_null(w.get_node_or_null(^"Camp/Camp3"), "Menüde camp3 yok")
	# Başsız çizicide (dummy) MultiMesh örnek verisini tutmaz: tutamın sınaması yalnız verisi okunabilen çizicide yapılır (pencereli koşuda
	# kare denetimi: docs/media/review/kislak_camp3_*).
	var kept := before.origin.is_equal_approx(Vector3(4.5, 0.0, -18.5))
	var life := _life(w, clock)
	assert_eq(life.hidden_grass_count() > 0, kept, "Yurdun altındaki tutam gizli (veri varsa)")
	if kept:
		assert_true(mm.get_instance_transform(0).basis.get_scale().x < 0.01, "Yurdun altındaki tutam sıfır ölçekte")
		assert_almost(mm.get_instance_transform(1).basis.get_scale().x, 1.0, 1e-6, "Uzaktaki tutam yerinde")
	life.end(0.0)
	await wait_frames(1)
	assert_null(w.get_node_or_null(^"Camp/Camp3"), "end() görünümü kaldırır")
	assert_eq(life.hidden_grass_count(), 0, "Gizlenen tutam kalmadı")
	if kept:
		assert_true(mm.get_instance_transform(0).is_equal_approx(before), "Tutam geri geldi (menü karesi değişmez)")
	assert_false(life.is_running())
	w.queue_free()
	life.queue_free()
	await wait_frames(1)


func test_routes_and_block_check() -> void:
	var clock := GameClock.new(DAY, OPEN)
	var w := _world()
	var life := _life(w, clock)
	life.site = SiteRules.camp3(_abs(ARRIVE), {})
	life.site.ensure_stage(3)
	var inside := life.slot_xz("y_tunduk", 0)
	var outside := life.slot_xz("y_kerege", 1)
	var path := life.route(inside, outside)
	var door := life._polar(0.0, 3.3 - 0.6)
	var through := false
	for p: Vector2 in path:
		if p.distance_to(door) < 0.05:
			through = true
	assert_true(through, "Duvar kalkınca içeriden dışarı kapıdan çıkılır")
	assert_true(CampLife.length_of(path) > inside.distance_to(outside), "Yol duvarın içinden geçmez")
	assert_ne(SiteState.validate_save_block({"zones": 5}), "", "Bozuk zon")
	assert_ne(SiteState.validate_save_block({"zones": {"tanhu_camp": {"sites": {"camp3": {"step": "x"}}}}}), "", "Bozuk adım")
	life.end(0.0)
	await wait_frames(1)
	w.queue_free()
	life.queue_free()
	await wait_frames(1)
