extends TestCase
## «Ak Kemik»in kuralları ve çocukların aklı (saf; BoneRules, BoneBrain; K110, story.md §5 «İki yeni gün», K105):
##   - Atış: kemik 25–45 m öteye düşer, her elde başka yere (önceki düşüşlerden ≥12 m), engellerin dışına, alanın içine; oyuncunun atışı E
##     basılı tutuldukça uzar.
##   - Kural: kemiğe 0,8 m'den yaklaşan alır, taşıyana 1 m'den yaklaşan yakalar ve kemiği alır, yakalanan 2 sn durur; direğe varan eli kazanır;
##     kazanan sonraki eli atar; üç elde biter.
##   - Akıl: hiçbir istek oyuncunun koşusunu aşmaz (çocukta 3,6 m/sn; başka sınırda da); kovalanan çocuk 2 sn'de bir duraksar, Mete onu
##     yakalayabilir; Mete kemikle dosdoğru direğe koşarsa kovalayan çocuklar arkadan yetişemez; oyuncu hiç oynamasa da üç el biter (ceza yok).

const POST := Vector2(18.0, 4.0)
const FIELD := Vector2(46.0, 10.0)
const STEP := 1.0 / 30.0
const NPCS: Array[String] = ["yanchi_child", "luhun_child"]


func _rules() -> BoneRules:
	return BoneRules.new(PackedStringArray([BoneRules.PLAYER, "yanchi_child", "luhun_child"]), POST, "luhun_child")


# --- Atış ---------------------------------------------------------------------------------------------------------

func test_landings_fall_25_to_45_m_away_and_elsewhere_each_hand() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2209
	var dir := (FIELD - POST).normalized()
	var obstacles := [Vector3(16.0, 26.0, 8.4), Vector3(0.0, 0.0, 3.4), Vector3(52.0, -2.5, 1.2)]
	var previous := PackedVector2Array()
	for hand in 3:
		var p := BoneRules.pick_landing(rng, POST, dir, deg_to_rad(28.0), BoneRules.THROW_RANGE, previous, obstacles, Vector2(26.0, 10.0), 58.0)
		var d := p.distance_to(POST)
		assert_between(d, 25.0 - 0.01, 45.0 + 0.01, "El %d: 25–45 m öteye (%.1f m)" % [hand + 1, d])
		for q in previous:
			assert_true(p.distance_to(q) >= BoneRules.LANDING_GAP - 0.01, "El %d: önceki düşüşten ≥12 m (%.1f)" % [hand + 1, p.distance_to(q)])
		for o: Vector3 in obstacles:
			assert_true(p.distance_to(Vector2(o.x, o.y)) >= o.z, "Engelin içine düşmez")
		assert_true(p.distance_to(Vector2(26.0, 10.0)) <= 58.0, "Yürünür alanın içinde")
		previous.append(p)
	# Aynı tohum aynı yeri verir (sınama ve kayıt tekrarlanır).
	var a := RandomNumberGenerator.new()
	a.seed = 7
	var b := RandomNumberGenerator.new()
	b.seed = 7
	assert_eq(BoneRules.pick_landing(a, POST, dir, 0.4, BoneRules.THROW_RANGE, PackedVector2Array(), [], Vector2.ZERO, 0.0),
		BoneRules.pick_landing(b, POST, dir, 0.4, BoneRules.THROW_RANGE, PackedVector2Array(), [], Vector2.ZERO, 0.0), "Tohumlu")


func test_player_throw_grows_with_the_hold_and_stays_inside() -> void:
	assert_almost(BoneRules.throw_distance(0.0), 25.0, 1e-6, "Kısa basış: 25 m")
	assert_almost(BoneRules.throw_distance(BoneRules.HOLD_FULL_S), 45.0, 1e-6, "Tam basış: 45 m")
	assert_almost(BoneRules.throw_distance(9.0), 45.0, 1e-6, "Fazlası tamdır")
	var last := 0.0
	for i in 15:
		var d := BoneRules.throw_distance(i * 0.1)
		assert_true(d >= last, "Basılı tuttukça uzar")
		last = d
	# Ağılın içine düşen atış dışına itilir, alanın dışına giden içine çekilir.
	var pen := Vector3(16.0, 26.0, 8.4)
	var into_pen := BoneRules.aimed_landing(Vector2(16.0, 0.0), Vector2(0.0, 1.0), 26.0, [pen], Vector2(26.0, 10.0), 58.0)
	assert_true(into_pen.distance_to(Vector2(16.0, 26.0)) >= 8.4, "Ağılın dışına itilir")
	var out := BoneRules.aimed_landing(POST, Vector2(-1.0, 0.0), 45.0, [], Vector2(26.0, 10.0), 30.0)
	assert_true(out.distance_to(Vector2(26.0, 10.0)) <= 30.0, "Alanın içine çekilir")


# --- Kural --------------------------------------------------------------------------------------------------------

func test_find_tag_freeze_and_win() -> void:
	var r := _rules()
	r.begin_hand()
	assert_eq(r.thrower, "luhun_child", "İlk eli Luhun atar")
	assert_eq(r.phase, BoneRules.Phase.THROW)
	r.land(FIELD)
	var pos := {BoneRules.PLAYER: FIELD + Vector2(0.7, 0.0), "yanchi_child": FIELD + Vector2(3.0, 0.0), "luhun_child": FIELD + Vector2(0.0, 5.0)}
	r.step(STEP, pos)
	var ev := r.take_events()
	assert_eq(str(ev.back()["type"]), "found", "0,8 m'den yaklaşan bulur")
	assert_eq(r.carrier, BoneRules.PLAYER)
	assert_eq(r.finders, PackedStringArray([BoneRules.PLAYER]))
	# Bulanın kısa yakalanmazlığı: hemen yanındaki hemen alamaz.
	pos["yanchi_child"] = pos[BoneRules.PLAYER] + Vector2(0.5, 0.0)
	var steps := 0
	while r.carrier == BoneRules.PLAYER and steps < 200:
		r.step(STEP, pos)
		steps += 1
	assert_true(steps * STEP >= BoneRules.FOUND_IMMUNE_S - 0.05, "Bulan hemen yakalanmaz (%.2f sn)" % (steps * STEP))
	assert_eq(r.carrier, "yanchi_child", "1 m'den yaklaşan yakalar, kemiği alır")
	assert_true(r.is_frozen(BoneRules.PLAYER), "Yakalanan durur")
	var tagged := r.take_events().filter(func(e: Dictionary) -> bool: return e["type"] == "tagged")
	assert_eq(tagged.size(), 1)
	assert_eq(str(tagged[0]["from"]), BoneRules.PLAYER)
	# Duran geri alamaz; 2 sn sonra yine oyunda.
	for i in roundi(1.9 / STEP):
		r.step(STEP, pos)
	assert_eq(r.carrier, "yanchi_child", "Yakalanan 2 sn içinde geri alamaz")
	for i in roundi(0.3 / STEP):
		r.step(STEP, pos)
	assert_false(r.is_frozen(BoneRules.PLAYER), "2 sn sonra yine koşar")
	assert_eq(r.carrier, BoneRules.PLAYER, "Duruş bitince yanındaki yine yakalar")
	assert_true(r.is_frozen("yanchi_child"))
	# Direğe varan kazanır; kazanan sonraki eli atar.
	pos[BoneRules.PLAYER] = POST + Vector2(1.0, 0.0)
	r.step(STEP, pos)
	assert_eq(r.phase, BoneRules.Phase.WON)
	assert_eq(r.winners, PackedStringArray([BoneRules.PLAYER]))
	r.finish_hand()
	assert_eq(r.hand, 1)
	assert_eq(r.thrower, BoneRules.PLAYER, "Kazanan sonraki eli atar (oyuncu: E basılı tutup bırakır)")
	for hand in 2:
		r.land(FIELD + Vector2(0.0, 13.0 * (hand + 1)))
		var by := "luhun_child"
		var p := {BoneRules.PLAYER: POST + Vector2(9.0, 9.0), "yanchi_child": POST + Vector2(9.0, -9.0), by: r.bone}
		r.step(STEP, p)
		p[by] = POST
		r.step(STEP, p)
		assert_eq(r.phase, BoneRules.Phase.WON)
		r.finish_hand()
	assert_true(r.is_done(), "Üç elde biter")
	assert_eq(r.player_wins(), 1)
	assert_eq(r.landings.size(), 3)


# --- Akıl ve hız ---------------------------------------------------------------------------------------------------

## Bir elin benzetimi: çocuklar aklın isteğiyle yürür, oyuncu policy'nin istediği yere 3,6 m/sn (ya da verilen hızla) koşar.
## Döner: {seconds, winner, modes: {id: [kip, ...]}, peak: en yüksek istek hızı, tags}.
func _simulate(r: BoneRules, brain: BoneBrain, pos: Dictionary, policy: Callable, limit_s: float = 120.0, player_speed: float = 3.6) -> Dictionary:
	var t := 0.0
	var peak := 0.0
	var modes := {"yanchi_child": [], "luhun_child": []}
	while t < limit_s and r.phase in [BoneRules.Phase.SEARCH, BoneRules.Phase.CARRY]:
		brain.tick(STEP)
		for id: String in NPCS:
			var w := brain.want(id, r, pos, STEP)
			peak = maxf(peak, float(w["speed"]))
			(modes[id] as Array).append(str(w["mode"]))
			pos[id] = BoneBrain.step_toward(pos[id], w["to"], float(w["speed"]), STEP)
		if not r.is_frozen(BoneRules.PLAYER):
			var goal: Variant = policy.call(r, pos)
			if goal is Vector2:
				pos[BoneRules.PLAYER] = BoneBrain.step_toward(pos[BoneRules.PLAYER], goal, player_speed, STEP)
		r.step(STEP, pos)
		t += STEP
	return {"seconds": t, "winner": r.winners[r.winners.size() - 1] if r.phase == BoneRules.Phase.WON else "", "modes": modes,
		"peak": peak, "tags": r.tags}


func test_three_hands_end_even_if_the_player_stands_still() -> void:
	var r := _rules()
	var brain := BoneBrain.new(PaceLimit.CHILD_RUN)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var total := 0.0
	r.begin_hand()
	for hand in 3:
		var at := BoneRules.pick_landing(rng, POST, (FIELD - POST).normalized(), 0.45, BoneRules.THROW_RANGE, r.landings, [], Vector2(26.0, 10.0), 58.0)
		r.land(at)
		brain.landed(r)
		var pos := {BoneRules.PLAYER: POST + Vector2(-2.0, 0.0), "yanchi_child": POST + Vector2(1.5, 2.0), "luhun_child": POST + Vector2(1.5, -2.0)}
		var out := _simulate(r, brain, pos, func(_r: BoneRules, _p: Dictionary) -> Variant: return null)
		assert_eq(r.phase, BoneRules.Phase.WON, "El %d biter (oyuncu hiç oynamasa da; %.1f sn)" % [hand + 1, out["seconds"]])
		assert_true(float(out["seconds"]) < 60.0, "El bir dakikadan kısa (%.1f sn)" % out["seconds"])
		assert_true(float(out["peak"]) <= PaceLimit.CHILD_RUN + PaceLimit.TOLERANCE, "Çocuk 3,6 m/sn'yi aşmaz (%.2f)" % out["peak"])
		total += float(out["seconds"])
		r.finish_hand()
		if hand < 2:
			assert_ne(r.thrower, BoneRules.PLAYER, "Kazanan çocuk sonraki eli atar")
	assert_true(r.is_done(), "Üç el; ceza yok")
	assert_eq(r.player_wins(), 0)
	assert_true(total < 150.0, "Üç el ≈2,5 dk'yı geçmez (%.0f sn)" % total)


func test_no_wish_exceeds_the_players_run_on_any_cap() -> void:
	for cap: float in [PaceLimit.CHILD_RUN, 2.4]:
		var r := _rules()
		var brain := BoneBrain.new(cap)
		r.begin_hand()
		r.land(FIELD)
		brain.landed(r)
		# Oyuncu kemiğe koşar, alır, direğe koşar: arama, kovalama, taşıma, duraksamanın hepsi geçer.
		var pos := {BoneRules.PLAYER: POST, "yanchi_child": POST + Vector2(2.0, 2.0), "luhun_child": POST + Vector2(2.0, -2.0)}
		var out := _simulate(r, brain, pos, func(rr: BoneRules, _p: Dictionary) -> Variant:
			return rr.bone if rr.phase == BoneRules.Phase.SEARCH else (rr.post if rr.carrier == BoneRules.PLAYER else rr.bone), 120.0, cap)
		assert_true(float(out["peak"]) <= cap + PaceLimit.TOLERANCE, "Sınır %.1f: en hızlı istek %.2f m/sn" % [cap, out["peak"]])


func test_the_player_can_catch_a_fleeing_child() -> void:
	var r := _rules()
	var brain := BoneBrain.new(PaceLimit.CHILD_RUN)
	r.begin_hand()
	var far := POST + (FIELD - POST).normalized() * 32.0
	r.land(far)
	brain.landed(r)
	# Luhun kemiği bulmuş; Mete 5 m arkasında, Yançi uzakta.
	var pos := {BoneRules.PLAYER: far + (far - POST).normalized() * 5.0, "yanchi_child": far + Vector2(0.0, 25.0), "luhun_child": far}
	r.step(STEP, pos)
	assert_eq(r.carrier, "luhun_child")
	var out := _simulate(r, brain, pos, func(rr: BoneRules, p: Dictionary) -> Variant: return p.get(rr.carrier, rr.bone))
	assert_true(int(out["tags"]) >= 1, "Mete kovalanan çocuğu direğe varmadan yakalar")
	var modes: Array = out["modes"]["luhun_child"]
	assert_true(modes.has("pause"), "Kovalanan çocuk duraksar (kolaylık)")


func test_the_chased_child_pauses_about_every_two_seconds() -> void:
	var r := _rules()
	var brain := BoneBrain.new(PaceLimit.CHILD_RUN)
	r.begin_hand()
	r.land(POST + Vector2(60.0, 0.0))
	brain.landed(r)
	var pos := {BoneRules.PLAYER: POST + Vector2(64.0, 0.0), "yanchi_child": POST + Vector2(64.0, 30.0), "luhun_child": POST + Vector2(60.0, 0.0)}
	r.step(STEP, pos)
	var pauses := 0
	var was := false
	var t := 0.0
	# Mete hep 4 m arkada kalır (yakalamaz): duraksamalar sayılır.
	while t < 10.0:
		brain.tick(STEP)
		var w := brain.want("luhun_child", r, pos, STEP)
		var pausing := str(w["mode"]) == "pause"
		if pausing and not was:
			pauses += 1
		was = pausing
		pos["luhun_child"] = BoneBrain.step_toward(pos["luhun_child"], w["to"], float(w["speed"]), STEP)
		var back: Vector2 = ((pos["luhun_child"] as Vector2) - r.post).normalized()
		pos[BoneRules.PLAYER] = pos["luhun_child"] + back * 4.0
		r.immune = 99.0
		r.step(STEP, pos)
		t += STEP
	assert_between(float(pauses), 3.0, 5.0, "10 sn'de 2 sn'de bir duraksar (%d)" % pauses)


func test_the_player_running_straight_to_the_post_is_not_caught_from_behind() -> void:
	var r := _rules()
	var brain := BoneBrain.new(PaceLimit.CHILD_RUN)
	r.begin_hand()
	var at := POST + (FIELD - POST).normalized() * 30.0
	r.land(at)
	brain.landed(r)
	# Mete kemiği alır; çocuklar arkada (çayırın uzak yanında) 4 m'de.
	var away := (at - POST).normalized()
	var pos := {BoneRules.PLAYER: at, "yanchi_child": at + away * 4.0 + Vector2(0.0, 1.0), "luhun_child": at + away * 4.0 - Vector2(0.0, 1.0)}
	r.step(STEP, pos)
	assert_eq(r.carrier, BoneRules.PLAYER)
	var out := _simulate(r, brain, pos, func(rr: BoneRules, _p: Dictionary) -> Variant: return rr.post)
	assert_eq(str(out["winner"]), BoneRules.PLAYER, "Dosdoğru koşan Mete direğe varır (kovalayanlar Mete'nin koşusunun altında)")
	assert_eq(int(out["tags"]), 0)


func test_search_narrows_and_the_two_children_spread() -> void:
	var r := _rules()
	var brain := BoneBrain.new(PaceLimit.CHILD_RUN)
	r.begin_hand()
	r.land(FIELD)
	brain.landed(r)
	assert_almost(BoneBrain.guess_scale(0.0, 20.0), 1.0, 1e-6)
	assert_almost(BoneBrain.guess_scale(20.0, 20.0), 0.0, 1e-6, "Sapma find_s'de kapanır")
	var pos := {BoneRules.PLAYER: POST + Vector2(-30.0, 0.0), "yanchi_child": POST, "luhun_child": POST + Vector2(0.5, 0.0)}
	var min_gap := INF
	for i in roundi(8.0 / STEP):
		brain.tick(STEP)
		for id: String in NPCS:
			var w := brain.want(id, r, pos, STEP)
			pos[id] = BoneBrain.step_toward(pos[id], w["to"], float(w["speed"]), STEP)
		if i > roundi(3.0 / STEP):
			min_gap = minf(min_gap, (pos["yanchi_child"] as Vector2).distance_to(pos["luhun_child"]))
	assert_true(min_gap > 2.0, "İki çocuk aynı yeri aramaz (en yakın %.1f m)" % min_gap)
	var side := Vector2(-(FIELD - POST).normalized().y, (FIELD - POST).normalized().x)
	assert_true(((pos["yanchi_child"] as Vector2) - FIELD).dot(side) < ((pos["luhun_child"] as Vector2) - FIELD).dot(side), "Yançi solda, Luhun sağda arar")


func test_day_binds_each_winner_and_finder_to_a_line() -> void:
	# Verinin söz eşlemesi (day1_bone.json, bone_play): bulan, yakalanan, kazanan; Yançi kazanınca «İlk ben vardım! Ben!», son el değilse
	# ardından «Bir el daha! Bu kez ben atarım.» (BonePlay önce kazananın sözünü, sonra again'i sıraya koyar).
	var d := ChildhoodScene.load_data("res://data/story/childhood_days/day1_bone.json")
	var play: Dictionary = {}
	for s: Dictionary in d.get("steps", []):
		if str(s.get("kind", "")) == "bone_play":
			play = s
	var lines: Dictionary = play.get("lines", {})
	var all: Dictionary = d.get("lines", {})
	for who: String in [BoneRules.PLAYER, "yanchi_child", "luhun_child"]:
		var found := str((lines.get("found", {}) as Dictionary).get(who, ""))
		var won := str((lines.get("won", {}) as Dictionary).get(who, ""))
		assert_true(all.has(found), "%s bulunca söz: %s" % [who, found])
		assert_true(all.has(won), "%s kazanınca söz: %s" % [who, won])
	assert_eq(str(lines["won"]["yanchi_child"]), "yanchi_won")
	assert_eq(str(all["yanchi_won"]["speaker"]), "yanchi_child", "Yançi'nin kendi sesi")
	assert_true(all.has(str(lines.get("again", ""))), "again")
	assert_eq(ChildhoodScene.validate(d), PackedStringArray(), "Günün verisi sorunsuz")
